# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A WordPress **child theme** for [Bricks Builder](https://bricksbuilder.io/) (parent theme lives at `../bricks`, a sibling directory, not inside this repo). There is no build system, package manager, or test suite — this is plain PHP/CSS loaded directly by WordPress. There are no build/lint/test commands to run; changes are verified by loading the site in a browser (via Local by Flywheel, given the `Local Sites` path) and checking the Bricks builder/frontend.

Since there's no parent-theme source in this repo, when you need to understand inherited behavior (template files, WooCommerce overrides, global functions), read the corresponding file in `../bricks` rather than guessing.

## Architecture

- **`style.css`** — theme stylesheet header (declares `Template: bricks`, which is what makes this a child theme) plus any custom CSS. Enqueued on the frontend only, not in the Bricks builder canvas, via `functions.php`.
- **`functions.php`** — the only PHP entry point. Three concerns live here:
  1. Enqueues `style.css`, guarded by `bricks_is_builder_main()` so child-theme CSS doesn't leak into the builder UI itself.
  2. Registers custom Bricks elements by listing their file paths in `$element_files` and calling `\Bricks\Elements::register_element()` on `init` (priority 11, i.e. after Bricks' own elements register).
  3. Adds the `custom` element category label to the builder via the `bricks/builder/i18n` filter.
- **`elements/`** — one file per custom Bricks element, each defining a class extending `\Bricks\Element`. `elements/title.php` (`Element_Custom_Title`) is the reference implementation.

### Adding a new custom Bricks element

Follow the pattern in `elements/title.php`:
1. Create `elements/{name}.php` with a class extending `\Bricks\Element`, guarded by `if ( ! defined( 'ABSPATH' ) ) exit;`.
2. Set `$category`, `$name` (unique slug), `$icon` (FontAwesome 5 class), `$css_selector`.
3. Implement `get_label()`, `set_control_groups()` / `set_controls()` (defines the builder's settings panel), and `render()` (frontend + default builder output, reading from `$this->settings`).
4. Optionally implement a static `render_builder()` using an `x-template` script + Vue component syntax (`contenteditable`, `:settings`) for a faster, JS-only builder preview instead of relying on PHP re-renders over AJAX.
5. Register the new file's path in the `$element_files` array in `functions.php`.

Reference: https://academy.bricksbuilder.io/article/create-your-own-elements

## Conventions

- Text domain is `'bricks'` (not `'bricks-child'`) — match this in all `esc_html__()` / `__()` calls, matching the parent theme's domain.
- Escape all output (`esc_html__`, etc.) per existing element code.
- Element control/setting keys and CSS class names follow BEM-ish, lowerCamelCase JS-facing keys (e.g. `titleTypography`) mapped to CSS selectors like `.title`.

## Project: Platinum Ice

**Brand:** Platinum Ice — "Clear Luxury" — premium clear ice company (platinumice.co). Serves luxury restaurants, cocktail bars, hotels, lounges, weddings, private/corporate events, brand activations, and direct-to-consumer customers. Products: signature clear cubes, spheres, Collins spears, rocks, blocks, custom logo/monogram/branded ice, custom shapes, botanical/specialty ice.

**Production architecture:** Self-hosted WordPress + Bricks Builder + this Bricks child theme. WooCommerce will be added later for ecommerce. Version control via Git/GitHub. Production will eventually run on the company's own hosting server.

### Development rules

1. Never modify WordPress core files.
2. Never modify the Bricks parent theme.
3. All custom PHP, CSS, JavaScript, components, and development changes must remain in this Bricks child theme unless explicitly approved otherwise.
4. Do not install plugins, libraries, frameworks, or dependencies without explicit approval.
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
