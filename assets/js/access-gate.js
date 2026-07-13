(function (window) {
  "use strict";

  var saltHex = "881d9b0da4e5128a4e89cd266c21a8fd";
  var iterations = 210000;
  var pwd = "90d5e727d2454362002e2bb6887a1bf0210c6599b9c1399322661741798c1b4c";

  function hexToBytes(hex) {
    var bytes = new Uint8Array(hex.length / 2);
    for (var index = 0; index < bytes.length; index += 1) {
      bytes[index] = parseInt(hex.slice(index * 2, index * 2 + 2), 16);
    }
    return bytes;
  }

  function bytesToHex(buffer) {
    return Array.from(new Uint8Array(buffer), function (byte) {
      return byte.toString(16).padStart(2, "0");
    }).join("");
  }

  async function hashAccessCode(accessCode) {
    var key = await window.crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(accessCode),
      "PBKDF2",
      false,
      ["deriveBits"]
    );
    var digest = await window.crypto.subtle.deriveBits(
      {
        name: "PBKDF2",
        hash: "SHA-256",
        salt: hexToBytes(saltHex),
        iterations: iterations
      },
      key,
      256
    );
    return bytesToHex(digest);
  }

  async function verifyAccessCode(accessCode) {
    if (typeof accessCode !== "string" || !window.crypto || !window.crypto.subtle) {
      return false;
    }

    var actual = await hashAccessCode(accessCode);
    var mismatch = actual.length ^ pwd.length;
    for (var index = 0; index < actual.length && index < pwd.length; index += 1) {
      mismatch |= actual.charCodeAt(index) ^ pwd.charCodeAt(index);
    }
    return mismatch === 0;
  }

  function requestAccess(options) {
    var settings = options || {};

    return new Promise(function (resolve) {
      var overlay = document.createElement("div");
      var dialog = document.createElement("section");
      var form = document.createElement("form");
      var heading = document.createElement("h2");
      var label = document.createElement("label");
      var input = document.createElement("input");
      var error = document.createElement("p");
      var actions = document.createElement("div");
      var cancel = document.createElement("button");
      var submit = document.createElement("button");

      overlay.className = "site-access-overlay";
      dialog.className = "site-access-dialog";
      dialog.setAttribute("role", "dialog");
      dialog.setAttribute("aria-modal", "true");
      dialog.setAttribute("aria-labelledby", "site-access-title");
      form.autocomplete = "off";
      heading.id = "site-access-title";
      heading.textContent = "Access verification";
      label.textContent = "Access code";
      input.type = "password";
      input.name = "access-code";
      input.autocomplete = "off";
      input.required = true;
      error.className = "site-access-error";
      error.setAttribute("aria-live", "polite");
      actions.className = "site-access-actions";
      cancel.type = "button";
      cancel.textContent = settings.cancelLabel || "Cancel";
      submit.type = "submit";
      submit.textContent = "Verify";

      function finish(granted) {
        overlay.remove();
        resolve(granted);
      }

      cancel.addEventListener("click", function () {
        finish(false);
      });

      form.addEventListener("submit", async function (event) {
        event.preventDefault();
        submit.disabled = true;
        error.textContent = "";

        try {
          if (await verifyAccessCode(input.value)) {
            finish(true);
            return;
          }
        } catch (verificationError) {
          error.textContent = "Unable to verify access code.";
          submit.disabled = false;
          return;
        }

        error.textContent = "Incorrect code.";
        input.select();

        if (settings.singleAttempt) {
          window.setTimeout(function () {
            finish(false);
          }, 700);
          return;
        }

        submit.disabled = false;
      });

      label.appendChild(input);
      actions.appendChild(cancel);
      actions.appendChild(submit);
      form.appendChild(heading);
      form.appendChild(label);
      form.appendChild(error);
      form.appendChild(actions);
      dialog.appendChild(form);
      overlay.appendChild(dialog);
      document.body.appendChild(overlay);
      input.focus();
    });
  }

  window.siteAccess = Object.freeze({
    request: requestAccess,
    verify: verifyAccessCode
  });
}(window));
