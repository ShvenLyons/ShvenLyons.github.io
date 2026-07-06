# Shiwen Liu Personal Website

This repository contains a lightweight Jekyll source for a GitHub Pages personal website.

## Structure

- `_pages/`: website pages, including home, research, publications, CV, footsteps, panorama, and 404.
- `_layouts/`: minimal page wrappers for standard and archive-style pages.
- `_includes/`: small reusable fragments for the head, navigation, profile sidebar, and footer.
- `assets/css/main.scss`: the complete custom site stylesheet.
- `images/`: profile photo and favicon files.
- `files/`: downloadable PDFs, including the CV.
- `assets/research/projects/`: unlinked internal prototype demos kept out of the public navigation.

## Local Preview

```bash
bundle install
bundle exec jekyll serve -l -H localhost
```

The site will be available at `http://localhost:4000`.
