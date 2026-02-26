# Project: kendraffe.github.io

## Intent
- Personal author site for Kendra Fortmeyer (fiction + posts + a few static pages).
- Keep it content-first, readable, and lightweight. Avoid heavy frameworks or redesigns unless explicitly requested.

## Structure (SSOT)
- `_config.yml`: Jekyll site metadata (title, description, url, etc.)
- `_layouts/`: page templates
  - `_layouts/default.html`: outer shell, includes header/footer and renders `{{ content }}`
- `_includes/`: shared partials
  - `_includes/head.html`: meta tags, CSS + fonts, analytics snippets
  - `_includes/header.html`: top nav (currently embedded in `head.html`)
  - `_includes/footer.html`: footer content (currently embedded in `head.html`)
- `_posts/`: dated posts (news feed)
- `css/main.scss`: main stylesheet entrypoint
- `_sass/`: SCSS partials imported by `css/main.scss`
- `assets/`: static assets

## Style notes (do not drift without intent)
- Typography: headings in `Playfair Display` (serif), body in `Muli` (sans).
- Palette baseline (see `css/main.scss`):
  - Background: `#fdfdfd`
  - Text: `#111` / black
  - Accent/brand: `#2a7ae2`
  - Muted paragraph: `#959595`
  - Greys: `#D8D8D8` family
- Layout: editorial, centered content, simple nav; Bootstrap 3 CSS is included in the head.

## Tooling (mandatory)

### Jekyll version
- Local + CI builds are pinned via Bundler to Jekyll `4.4.1`.
- Do not rely on GitHub Pages' built-in Jekyll stack (it is pinned and older); deployment uses GitHub Actions.
- Production is `https://rblakemesser.github.io/` (deployed via `rblakemesser/rblakemesser.github.io` workflow `kendraffe.yml`).

### Screenshot-first page inspection
When asked about the structure/content on any page:
1. Take a headless screenshot for reference (Playwright).
2. Then read the relevant templates/content files.

Use:
- `make shot PAGE=/some/page/`

### Ship every change (EXTREMELY IMPORTANT)
For every requested change, automatically:
1. Build the site
2. Commit changes
3. Push to `origin/master`
4. Trigger the production deploy workflow
5. Watch the resulting GitHub Actions deploy run until it finishes
6. Post the GitHub Actions run link and the production site link

Use:
- `make ship MSG="describe the change"`

This policy is intentional: changes should not be left unbuilt or unpushed.

## Content workflow (posts + images)

### Add a new post
1. Scaffold a post file:
   - `make new-post TITLE="My Post Title" CATEGORIES=interviews`
   - Optional: `SLUG=... DATE="YYYY-MM-DD HH:MM:SS -0500" IMAGE=/assets/foo.webp LINK=https://...`
2. Edit the created file in `_posts/YYYY-MM-DD-slug.markdown`.
3. Ship:
   - `make ship MSG="post: My Post Title"`

### Add a new image (optimized + cropped)
1. One-time install of image tooling (local):
   - `make img-tools`
2. Import/convert/crop:
   - Post header / general: `make img SRC=/path/to/input.jpg NAME=my-image PRESET=long`
   - Fiction card / square: `make img SRC=/path/to/input.jpg NAME=my-image PRESET=square`
3. Use the printed snippet:
   - Post header front matter: `image: "/assets/my-image.webp"`
   - Inline markdown: `![](/assets/my-image.webp)`
4. Ship:
   - `make ship MSG="assets: add my-image"`

## Make targets (canonical workflow)
- `make doctor`: sanity-check toolchain + git branch.
- `make install`: install Ruby gems (Bundler) + Node deps + Playwright Chromium.
- `make build`: build to `_site/` (set `COPY_CNAME=1` to include `CNAME` as `_site/CNAME`).
- `make serve`: run local dev server at `http://127.0.0.1:4000`.
- `make open`: open the local server URL in your browser.
- `make shot PAGE=/`: take a screenshot of a path using a temporary server.
- `make img-tools`: install ImageMagick via Homebrew (required for `make img`).
- `make img SRC=...`: import an image into `assets/` as a web-friendly format (default: WebP).
- `make new-post TITLE="..."`: scaffold a new post in `_posts/`.
- `make watch SHA=...`: wait for the production Pages deploy run for a commit SHA; prints run + production URLs.
- `make ship MSG="..."`: build + commit + push to `origin/master` (supports `DRY_RUN=1`).
