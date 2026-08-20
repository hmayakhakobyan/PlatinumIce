# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A WordPress **child theme** for the [Alukas](https://alukas.presslayouts.com/) theme (parent theme lives at `../alukas`, a sibling directory, not inside this repo), built to be used with **Elementor**. There is no build system, package manager, or test suite — this is plain PHP/CSS loaded directly by WordPress. There are no build/lint/test commands to run; changes are verified by loading the site in a browser (via Local by Flywheel, given the `Local Sites` path) and checking the WordPress frontend / Elementor editor.

Since there's no parent-theme source in this repo, when you need to understand inherited behavior (template files, WooCommerce overrides, global functions), read the corresponding file in `../alukas` rather than guessing.

## Architecture

- **`style.css`** — theme stylesheet header (declares `Template: alukas`, which is what makes this a child theme; `Text Domain: pls-theme-child`) plus any custom CSS.
- **`functions.php`** — enqueues `style.css` on the frontend via `wp_enqueue_scripts` (priority 101, after the parent theme's own enqueue).

This is currently a minimal foundation. There is no custom PHP logic, no custom Elementor widgets, and no plugin dependencies yet — those will be added incrementally as the project needs them, with approval.

### Adding custom Elementor widgets (future)

Elementor Pro is **not required** to build custom widgets — they can be developed against Elementor Core (free). Elementor Pro is only needed later for Pro-specific functionality: Theme Builder, Pro WooCommerce features, dynamic content/tags, forms, and popups. No custom widget pattern has been established in this repo yet; when the first one is built, document the pattern here.

## Conventions

- Text domain is `'pls-theme-child'` (matching the existing Alukas Child theme's `style.css` declaration) — use this in all `esc_html__()` / `__()` calls for custom child-theme code.
- Escape all output (`esc_html__`, etc.).
- Prefer Elementor-native functionality (native widgets, native controls, native theme features) over custom code when a native solution meets the need.
- Avoid unnecessary dependency on Alukas proprietary widgets/features where a maintainable Elementor-native or plain WordPress solution exists — keeps the site portable if the parent theme ever changes.

## Project: Platinum Ice

**Brand:** Platinum Ice — "Clear Luxury" — premium clear ice company (platinumice.co). Serves luxury restaurants, cocktail bars, hotels, lounges, weddings, private/corporate events, brand activations, and direct-to-consumer customers. Products: signature clear cubes, spheres, Collins spears, rocks, blocks, custom logo/monogram/branded ice, custom shapes, botanical/specialty ice.

**Production architecture:** Self-hosted WordPress + Alukas parent theme + Alukas Child theme (this repo) + Elementor + WooCommerce (added later for ecommerce). Version control via Git/GitHub. Development via Claude Code. Production will eventually run on the company's own hosting server.

**Migration note:** This project was previously built on Bricks Builder (`bricks-child` theme, same repository history). The stack was switched to Alukas + Elementor. Bricks-specific code (custom Bricks elements, Bricks-only functions) was intentionally left behind and must not be ported over — Elementor widgets, if/when needed, should be built fresh against the Elementor architecture.

### Development rules

1. Never modify WordPress core files.
2. Never modify the Alukas parent theme.
3. All custom PHP, CSS, JavaScript, components, and development changes must remain in this Alukas child theme unless explicitly approved otherwise.
4. Do not install plugins, libraries, frameworks, or dependencies (including Elementor and WooCommerce themselves) without explicit approval.
5. Do not invent business information — pricing, product specifications, delivery areas, testimonials, customer names, statistics, certifications, addresses, phone numbers, or policies. Ask for clarification whenever required business information is missing.
6. Do not make major architecture changes without approval.
7. Before making significant changes, explain what files will be changed and why.
8. Keep changes modular and maintainable.
9. Never delete or overwrite approved work without explicit approval.
10. Do not commit or push changes unless explicitly instructed.
11. Never place credentials, API keys, passwords, payment secrets, or private information in source code or Git.

### Design direction

High-end luxury brand feel — closer to luxury spirits, premium hospitality, jewelry, and editorial fashion brands than a delivery service or generic template.

Principles: restrained luxury, strong typography, generous whitespace, cinematic photography/video, a palette of premium black/platinum-silver/warm white/subtle ice tones, sophisticated motion, minimal decoration, excellent mobile experience, product-first visual storytelling.

Avoid: excessive gradients, glassmorphism, random animations, generic icon grids, excessive rounded cards, generic AI/SaaS layouts, unnecessary visual effects, excessive text on luxury landing sections. Must not read as a generic ice-delivery company, WordPress template, AI-generated startup site, SaaS product, or cheap ecommerce template.

### Technical quality bar

Every feature must consider: responsive desktop/tablet/mobile layouts, accessibility, semantic HTML, performance, image/video optimization, Core Web Vitals, maintainability, browser compatibility, security, and SEO.

### SEO

SEO is part of the architecture from the start, not bolted on later. Planned site structure: Home, Ice, Custom Ice, Hospitality, Events, The Craft, Shop, About, Request a Quote, Experiences/Gallery, Journal. Do not create SEO location pages or keyword pages until keyword/service-area research has been approved.

### Ecommerce (future)

WooCommerce will be added later, supporting two sales paths:
1. Standard: product → quantity → delivery → checkout → payment.
2. Custom/B2B: ice type → customization/logo upload → quantity → event date → delivery information → request quote.

Do not implement WooCommerce, payments, shipping, or delivery functionality until explicitly instructed.

### Current development phase

Establishing the technical foundation only. Do NOT build the homepage or any customer-facing design/pages yet.
