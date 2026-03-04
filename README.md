# Airshuttle

A Badminton website/app concept created using Flutter SDK. Features match history, individual player profiles, school display, ranking system, and App/web functionality. 

## Deploying to GitHub Pages

- This repo now includes an automatic deploy workflow: `.github/workflows/deploy_pages.yml`
- Every push to `main` builds Flutter web and deploys to GitHub Pages.
- It automatically sets the correct `--base-href` for project pages and adds SPA fallback (`404.html`) for deep links.

### One-time setup

1. Go to **Settings → Pages** in GitHub.
2. Under **Build and deployment**, set **Source** to **GitHub Actions**.
3. Push to `main` (or run the workflow manually from **Actions**).

Your site URL will be:

- `https://<username>.github.io/<repo>/` for project pages
- `https://<username>.github.io/` for user/org pages (`<username>.github.io` repo)
