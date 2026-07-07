# Shiwen Liu Personal Website

This repository contains a static GitHub Pages personal website. It does not require Jekyll, Ruby, Node.js, or a build step.

## Structure

- `index.html`: homepage.
- `research/`, `publications/`, `footsteps/`, `panorama/`, `cv/`: static page directories.
- `404.html`: custom not-found page.
- `assets/css/main.css`: site stylesheet.
- `images/`: profile photo and favicon files.
- `files/`: downloadable PDFs, including the CV.
- `assets/research/projects/`: unlinked internal prototype demos kept out of the public navigation.
- `.nojekyll`: tells GitHub Pages to serve the files directly without Jekyll processing.

## Local Preview

```bash
python3 -m http.server 4000
```

The site will be available at `http://localhost:4000`.
