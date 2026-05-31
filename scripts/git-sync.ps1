<#
GitHub sync helper.

Authentication:
  $env:GH_TOKEN = "your fine-grained personal access token"
  # or
  $env:GITHUB_TOKEN = "your fine-grained personal access token"

Examples:
  .\scripts\git-sync.ps1 -Mode status
  .\scripts\git-sync.ps1 -Mode pull
  .\scripts\git-sync.ps1 -Mode push -Message "update website" -All
  .\scripts\git-sync.ps1 -Mode sync -Message "update website" -All
#>

param(
  [ValidateSet("status", "pull", "push", "sync")]
  [string]$Mode = "sync",

  [string]$Message = "",

  [switch]$All,

  [string]$Remote = "origin",

  [string]$Branch = ""
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GitArgs
  )

  & git @GitArgs
  if ($LASTEXITCODE -ne 0) {
    throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE."
  }
}

function Get-RepoRoot {
  $root = git rev-parse --show-toplevel 2>$null
  if (-not $root) {
    throw "This script must be run inside a git repository."
  }
  return $root.Trim()
}

function Get-CurrentBranch {
  $name = git branch --show-current
  if (-not $name) {
    throw "Unable to determine the current branch."
  }
  return $name.Trim()
}

function Test-HttpsRemote {
  param([string]$RemoteName)
  $url = git remote get-url $RemoteName
  return $url -match "^https://github\.com/"
}

function New-GitAskPass {
  $token = $env:GH_TOKEN
  if (-not $token) {
    $token = $env:GITHUB_TOKEN
  }

  if (-not $token) {
    throw "Missing GH_TOKEN or GITHUB_TOKEN environment variable."
  }

  $basePath = Join-Path $env:TEMP ("github-askpass-{0}" -f [guid]::NewGuid())
  $scriptPath = "$basePath.ps1"
  $cmdPath = "$basePath.cmd"
  @'
param([string]$Prompt)

if ($Prompt -match "Username") {
  if ($env:GITHUB_USERNAME) {
    Write-Output $env:GITHUB_USERNAME
  } else {
    Write-Output "x-access-token"
  }
  exit 0
}

if ($Prompt -match "Password") {
  if ($env:GH_TOKEN) {
    Write-Output $env:GH_TOKEN
  } else {
    Write-Output $env:GITHUB_TOKEN
  }
  exit 0
}

exit 1
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

  "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" %*" |
    Set-Content -LiteralPath $cmdPath -Encoding ASCII

  return $cmdPath
}

function Invoke-WithGitAuth {
  param(
    [scriptblock]$Action,
    [bool]$NeedsHttpsAuth
  )

  $oldAskPass = $env:GIT_ASKPASS
  $oldTerminalPrompt = $env:GIT_TERMINAL_PROMPT
  $askPass = $null

  try {
    if ($NeedsHttpsAuth) {
      $askPass = New-GitAskPass
      $env:GIT_ASKPASS = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$askPass`""
      $env:GIT_TERMINAL_PROMPT = "0"
    }

    & $Action
  } finally {
    if ($null -eq $oldAskPass) {
      Remove-Item Env:\GIT_ASKPASS -ErrorAction SilentlyContinue
    } else {
      $env:GIT_ASKPASS = $oldAskPass
    }

    if ($null -eq $oldTerminalPrompt) {
      Remove-Item Env:\GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
    } else {
      $env:GIT_TERMINAL_PROMPT = $oldTerminalPrompt
    }

    if ($askPass -and (Test-Path -LiteralPath $askPass)) {
      Remove-Item -LiteralPath $askPass -Force
    }
    $askPassScript = [System.IO.Path]::ChangeExtension($askPass, ".ps1")
    if ($askPassScript -and (Test-Path -LiteralPath $askPassScript)) {
      Remove-Item -LiteralPath $askPassScript -Force
    }
  }
}

function Test-DirtyWorktree {
  $changes = git status --porcelain
  return [bool]$changes
}

$repoRoot = Get-RepoRoot
Set-Location $repoRoot

if (-not $Branch) {
  $Branch = Get-CurrentBranch
}

$needsAuth = ($Mode -in @("pull", "push", "sync")) -and (Test-HttpsRemote -RemoteName $Remote)

Invoke-WithGitAuth -NeedsHttpsAuth $needsAuth -Action {
  switch ($Mode) {
    "status" {
      Invoke-Git status --short --branch
    }

    "pull" {
      Invoke-Git fetch $Remote
      Invoke-Git pull --ff-only $Remote $Branch
    }

    "push" {
      if ((Test-DirtyWorktree) -and $Message) {
        if ($All) {
          Invoke-Git add -A
        }
        Invoke-Git commit -m $Message
      } elseif ((Test-DirtyWorktree) -and -not $Message) {
        throw "Worktree has uncommitted changes. Pass -Message, or commit manually before pushing."
      }

      Invoke-Git fetch $Remote
      Invoke-Git pull --rebase --autostash $Remote $Branch
      Invoke-Git push $Remote $Branch
    }

    "sync" {
      Invoke-Git fetch $Remote
      Invoke-Git pull --rebase --autostash $Remote $Branch

      if ((Test-DirtyWorktree) -and $Message) {
        if ($All) {
          Invoke-Git add -A
        }
        Invoke-Git commit -m $Message
        Invoke-Git push $Remote $Branch
      } elseif (-not (Test-DirtyWorktree)) {
        Invoke-Git status --short --branch
      } else {
        Write-Output "Local changes remain uncommitted. Use -Mode push -Message `"your message`" -All to commit and upload them."
      }
    }
  }
}
