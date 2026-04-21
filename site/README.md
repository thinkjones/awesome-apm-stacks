# awesome-apm-stacks — marketing site

Astro static site deployed to GitHub Pages at
<https://awesome-apm-stacks.foursignals.dev>.

Design system ported from [foursignals.dev](https://foursignals.dev)
(Four Signals 2.1 "The Light Architect").

## Local dev

```bash
cd site
pnpm install
pnpm dev
```

Open <http://localhost:4321>.

## Build

```bash
pnpm build    # outputs to site/dist/
pnpm preview  # serve dist/
```

## Deploy

Pushes to `main` that touch `site/**` trigger
`.github/workflows/deploy-site.yml`, which builds and publishes to
GitHub Pages with the custom domain baked in via `public/CNAME`.
