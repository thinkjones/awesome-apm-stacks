# Design System — awesome-apm-stacks site

The landing site at <https://awesome-apm-stacks.foursignals.dev> follows
**Four Signals 2.1 "The Light Architect"**, ported from the private
`thinkjones/fs-website` repo. This document captures only the parts this
site actually uses — refer to the fs-website `DESIGN.md` for the full
canonical spec (stats bar, dispatches, consulting-page variants, etc.).

> **Source of truth for values.** Design *tokens* live in
> `tailwind.config.mjs` and `src/styles/global.css`. If those two files
> disagree with this document, the code is right — fix this doc.

---

## 1. Creative direction

**Light mode primary. Dark mode opt-in** via `[data-theme="dark"]`.
Authority comes from whitespace, typographic hierarchy, and sculptural
card elevation — not from darkness, glass, or decoration. The Tesseract
motif from earlier FS iterations is reduced to a subtle 40 px grid
overlay at 5% opacity.

---

## 2. Colour

### 2.1 Brand triad (mode-invariant, Stitch seeds)

| Token | Hex | CSS variable | Role |
|---|---|---|---|
| Primary Orange | `#e85d26` | `--brand-orange` | Brand identity, links, accents (max 1–2 uses per view) |
| Orange Light | `#ffb59c` | `--brand-orange-light` | Link hover, tints |
| Orange Soft | `#e85d2620` | `--brand-orange-soft` | Subtle backgrounds (12.5% α) |
| Secondary Cyan | `#54C8CE` | `--brand-cyan` | Secondary accents, data highlights |
| Tertiary Rose | `#EB5570` | `--brand-rose` | Emphasis, error-adjacent |

### 2.2 Surfaces — light mode (primary)

| Token | Hex | CSS variable | Role |
|---|---|---|---|
| Background | `#f8fafc` | `--bg-primary` | Page background |
| Card | `#ffffff` | `--bg-card` | Sculptural panels |
| Card hover | transparent | `--bg-card-hover` | Border drops, shadow rises on hover |
| On-surface | `#0f172a` | `--text-primary` | Headlines, body |
| On-surface-variant | `#475569` | `--text-secondary` | Descriptions, secondary copy |
| Muted | `#94a3b8` | `--text-muted` | Tertiary text, captions |
| Border | `#e2e8f0` | `--border` | Card borders |
| CTA primary | `#1e293b` | `--cta-primary` | Dark button fill |

### 2.3 Surfaces — dark mode (Stitch tonal layering)

| Token | Hex | CSS variable |
|---|---|---|
| Background | `#131317` | `--bg-primary` |
| Section | `#1b1b1f` | `--bg-secondary` |
| Card | `#2a2a2e` | `--bg-card` |
| Card hover | `#353439` | `--bg-card-hover` |
| On-surface | `#e4e1e7` | `--text-primary` |
| On-surface-variant | `#e1bfb4` | `--text-secondary` |
| Outline | `#a88a80` | `--text-muted` |
| Border | `#594139` | `--border` |
| CTA primary | `#f2642d` | `--cta-primary` |

### 2.4 Signal accents (content taxonomy)

Used on the landing page to colour-code package categories
(`Packages.astro`). Also available for any other categorical data.

| Signal | Light | Dark | CSS variable |
|---|---|---|---|
| People | `#00ff88` | `#E06C75` | `--signal-people` |
| Process | `#00f5ff` | `#56B6C2` | `--signal-process` |
| Architecture | `#d000ff` | `#C678DD` | `--signal-architecture` |
| Measure | `#ffb800` | `#98C379` | `--signal-measure` |

Soft variants (`--signal-*-soft`) are the same hex with a `18` α-suffix
(≈ 10% opacity) for background fills.

---

## 3. Typography

### Stack

| Role | Font | Weights | Usage |
|---|---|---|---|
| Headlines | **Source Serif 4** | 600, 700 | Hero, section titles |
| Body | **Inter** | 400, 500, 600 | Descriptions, nav links |
| Labels, mono, code | **JetBrains Mono** | 400, 500, 600, 700 | Section labels, code blocks, stats, tags |

Loaded from Google Fonts via `@import` at the top of `global.css`.

### Scale (from `tailwind.config.mjs`)

| Token | Size | Line-height | Tracking | Font |
|---|---|---|---|---|
| `text-display-xl` | 4.5 rem | 1.08 | −0.075em | Source Serif 4 700 |
| `text-display-lg` | 3.75 rem | 1.1 | −0.05em | Source Serif 4 700 |
| `text-display-md` | 3 rem | 1.15 | −0.05em | Source Serif 4 600 |
| `text-headline-lg` | 2.25 rem | 1.2 | −0.05em | Source Serif 4 600 |
| `text-headline-md` | 1.875 rem | 1.25 | −0.03em | Source Serif 4 600 |
| `text-headline-sm` | 1.5 rem | 1.3 | −0.02em | Source Serif 4 600 |
| `text-body-lg` | 1.125 rem | 1.625 | — | Inter 400 |
| `text-body-md` | 1 rem | 1.625 | — | Inter 400 |
| `text-body-sm` | 0.875 rem | 1.6 | — | Inter 400 |
| `text-label-lg` | 0.875 rem | 1.4 | 0.02em | JBM 500 |
| `text-label-md` | 0.75 rem | 1.4 | 0.04em | JBM 400 |
| `text-label-sm` | 0.6875 rem | 1.4 | 0.2em | JBM 400 |
| `text-stat-number` | 3 rem | 1.1 | −0.05em | Source Serif 4 700 |

### Rules

- **Headlines:** `font-serif` + `tracking-tighter` (−0.05em) or `tracking-tightest` (−0.075em) for display sizes.
- **Section labels:** `font-mono text-label-sm uppercase tracking-widest` (0.2em), brand-orange colour.
- **Mix serif + mono** in the same component intentionally (`// section label` prefix pattern).
- **No all-caps headlines.** Case is preserved; emphasis comes from size and weight.

---

## 4. Spacing

12-column grid, generous breathing room.

| Use | Class | Value |
|---|---|---|
| Hero vertical padding | `py-32` | 128 px |
| Major section separation | `py-24` | 96 px |
| Between card rows | `gap-8` | 32 px |
| Card inner padding | `p-6` (or `.sculptural-panel`) | 24 px |
| List items | `space-y-4` | 16 px |

Containers:

- `.container` → `max-w-5xl` (1024 px) + 24 px padding — prose-width
- `.container-wide` → `max-w-7xl` (1280 px) + 24 px padding — hero and grids

**No 1 px divider lines between sections** — separation is whitespace only.

---

## 5. Border radius

**Maximum radius: 4 px.** Hard rule, no exceptions except avatars
(`rounded-full`). Tailwind's `rounded`, `rounded-md`, and `rounded-lg`
all map to 4 px in `tailwind.config.mjs`.

Everything else is square. This is what "sculptural" feels like.

---

## 6. Component patterns

### Sculptural panel (the workhorse card)

```css
.sculptural-panel {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: 24px;
  transition: all 500ms ease;
}
.sculptural-panel:hover {
  transform: translateY(-8px);
  border-color: transparent;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
}
```

Used for: package cards, feature cards (HowItWorks, Why), hero's
apm.yml terminal panel. Always on a non-white page background
so the white card reads.

### Glass navigation (`.glass-nav`)

**Only place** backdrop-blur is allowed in light mode. 80% white alpha,
12 px blur, 1 px border-bottom. Fixed position, top 16 px tall.

### Grid overlay (`.grid-overlay`)

Dual-axis `linear-gradient` at 40 px, 5% black opacity. Use behind hero
and workflow sections for a subtle engineered-feel backdrop.

### Buttons

Four variants, all in `global.css` component layer:

| Variant | Class | Fill | Border |
|---|---|---|---|
| Primary | `.btn-primary` | `--cta-primary` (dark slate / dark-mode orange) | none |
| Outline | `.btn-outline` | transparent | `--border` → `--text-primary` on hover |
| Tertiary | `.btn-tertiary` | transparent | none; mono text with `> ` cursor prefix |
| Ghost | raw Tailwind | transparent | none; `text-secondary` → `text-primary` hover |

**Never put gradients on buttons.**

### Section template

Every major `<section>` follows the same anatomy:

```astro
<section class="py-24">
  <div class="container-wide">
    <span class="section-label">// Section Label</span>
    <h2 class="section-title">Section headline</h2>
    <div class="section-divider"></div>   <!-- 64×1 brand-orange rule -->
    <p class="section-desc">Supporting copy.</p>
    <div><!-- content --></div>
  </div>
</section>
```

---

## 7. Do's and don'ts

### Do

- Light mode as default, dark as opt-in
- Sculptural card panels with hover elevation
- Generous whitespace (`py-24` between sections)
- Mix serif + mono in the same component
- Signal accents for categorical content
- Terminal cursor prefix (`>`) on tertiary actions
- Left-align almost everything (text, grids, hero content)

### Don't

- No rounded corners beyond 4 px
- No gradients on buttons
- No glassmorphism except the nav
- No 1 px divider lines between sections
- No stock icons / blobby illustrations
- No centre-aligned layouts (the stats bar is the only exception)
- No dark mode as default

---

## 8. Where things live

| What | File |
|---|---|
| Colour tokens (CSS custom properties) | `src/styles/global.css` |
| Colour aliases, font stack, type scale, radius | `tailwind.config.mjs` |
| Component classes (`.sculptural-panel`, `.glass-nav`, `.btn-*`, `.section-*`) | `src/styles/global.css` |
| Layout (head, meta, fonts preload) | `src/layouts/Layout.astro` |
| Section components | `src/components/*.astro` |
| OG image | `public/og-image.png` (1280×640, see `docs/tmp/og-image-prompt.md`) |

## 9. Lineage

- **Four Signals 2.1 "The Light Architect"** — canonical design system
  maintained in `thinkjones/fs-website` (private). That repo's
  `DESIGN.md` is the authoritative spec for Stitch tokens, dark-mode
  colour behaviour, and the full component set.
- This file is a trimmed port covering only what the awesome-apm-stacks
  site actually uses. When fs-website's DESIGN.md updates, reconcile
  shared rules here.
