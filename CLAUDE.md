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

## Automation & Maintainability

1. Claude Code should perform as much routine WordPress, Elementor, WooCommerce, and website development work on the user's behalf as technically and safely possible.
2. The normal workflow is: User requests change → Claude implements → Claude verifies → User visually reviews.
3. Prefer WordPress APIs and WP-CLI for programmatic WordPress operations instead of raw SQL whenever practical.
4. Prefer native Elementor containers and widgets for important page structures when practical.
5. Avoid unnecessary dependency on Alukas proprietary Elementor widgets.
6. Never modify the Alukas parent theme.
7. Theme-specific customizations belong in alukas-child.
8. Business functionality that should survive a future theme change should eventually live in a dedicated Platinum Ice custom plugin rather than being buried in the child theme.
9. Keep WooCommerce product, order, customer, coupon, taxonomy, and commerce data in standard WooCommerce structures wherever practical.
10. Build reusable components and patterns rather than one-off hard-coded layouts.
11. Important website elements should remain programmatically accessible to Claude for future maintenance whenever technically practical.
12. Avoid plugins that lock important content or business functionality into proprietary formats unless there is a documented reason for using them.
13. Before significant automated WordPress/database changes, create an appropriate backup/checkpoint.
14. Database-only changes do not require Git commits.
15. All source-code changes must remain Git tracked.
16. Never store credentials, API keys, payment secrets, passwords, licenses, purchase codes, or other secrets in Git.
17. Only require manual user interaction when genuinely necessary for:
   - authentication
   - license activation
   - payment or secret credentials
   - unavoidable third-party UI actions
   - subjective visual approval
18. Before changing Elementor _elementor_data programmatically:
   - validate the JSON first
   - use controls supported by the installed Elementor version
   - create a database checkpoint for significant changes
   - render/validate the resulting page after writing
   - verify that unrelated pages and homepage assignments remain unchanged
19. WP-CLI note for this Local WordPress environment:
   When writing Elementor JSON through wp post meta update using STDIN,
   do NOT pass "-" as the value argument. Omitting the value argument is required for STDIN.
   Passing "-" stores the literal string "-".
20. Platinum Ice pages should remain easy for both Claude Code and a human administrator to update after launch.

### Surgical Elementor content updates

When asked to change a single piece of homepage content (a heading, a CTA label, an image, one section's copy), do NOT regenerate or overwrite the entire `_elementor_data` document. Instead:

1. Read the current value: `wp post meta get <page_id> _elementor_data` (WP-CLI), redirected to a scratch file.
2. `json_decode` it, locate the target element by its Elementor element `id` or (preferably, since it's stable and descriptive) its `settings.css_classes` value — see `docs/HOMEPAGE-CONTENT-MAP.md` for the current page 841 element ID/class inventory.
3. Mutate only the specific setting key needed (e.g. `title`, `editor`, `text`, `background_image`) on that one element — leave every other element/setting untouched.
4. Re-`json_encode` the full array (still the whole document, but only one field actually changed) and validate it decodes cleanly before writing.
5. Write back via `wp post meta update <page_id> _elementor_data` reading from STDIN (value argument omitted — see the STDIN note below).
6. `wp elementor flush_css`, then render-check via `Elementor\Plugin::$instance->frontend->get_builder_content_for_display()` to confirm the change applied and nothing else broke.
7. Verify unrelated pages (especially page 52) and `page_on_front` are unchanged.

This keeps changes reviewable/diffable in intent even though the underlying storage is one large JSON blob, and avoids the risk of accidentally reintroducing stale settings from a regenerated document.

**CSS Classes control key differs by element type.** Containers/Sections/Columns use `css_classes` (no leading underscore). Every other WIDGET (heading, text-editor, button, image, etc.) uses `_css_classes` (leading underscore) — this is a separate control registered in a different base class, not just a naming variant. Setting `css_classes` on a widget is silently accepted into the JSON but never renders as an actual HTML class — always verify a newly-set class actually appears in the rendered output (`get_builder_content_for_display()`) rather than assuming the JSON key was correct.

### WP-CLI meta-storage gotchas for this project

- **`_elementor_data`** is stored as a **raw JSON string** (Elementor encodes/decodes it itself) — write it with `wp post meta update <id> _elementor_data` piping JSON text via STDIN (value argument omitted). Never pass literal `-` as the value argument — WP-CLI only reads STDIN when the value argument is *omitted entirely*; passing `-` stores the literal string `"-"`.
- **`_elementor_page_settings`** (used for the Elementor kit's global colors/typography, and for any document's page-level settings) is, unlike `_elementor_data`, a **normal WordPress array meta value** — it must be auto-serialized by WordPress, not stored as a JSON string. Write it with `wp post meta update <id> _elementor_page_settings --format=json`, piping JSON via STDIN, so WP-CLI decodes the JSON into a PHP array before calling `update_post_meta()`. Writing it as a plain JSON string (like `_elementor_data`) silently fails — Elementor's `get_settings_for_display()` reads back a string instead of an array and the settings are ignored with no error.

### Platinum Ice Asset Inbox

- **Asset root convention:** a local folder tree at `<Pictures folder>\PlatinumIce\` — `00-INBOX\<Category>\` holds files awaiting import; `Originals\` holds user-retained master files that are never auto-scanned or imported. Categories: `Hero`, `Signature`, `Custom`, `Hospitality`, `Events`, `Shop`, `Craft`, `Logos`.
- **Sync command:** `powershell -File dev-tools\sync-assets.ps1` — add `-DryRun` to preview without importing anything, `-Category <Name>` to scope to one folder.
- **Deduplication:** every supported file is hashed with SHA-256 before import. A file already recorded as imported — by content hash, regardless of filename or which folder it's currently in — is never re-imported, even across separate runs.
- **Manifest:** `dev-tools/asset-sync.local.json` records `originalFilename` / `sourcePath` / `seoFilename` / `namingSource` / `needsReview` / `category` / `attachmentId` / `url` / `mediaTitle` / `altText` / `altTextGuidance` / `sha256` / `importedAt` / `status` per asset. It is machine-local and gitignored — never commit it. The sync script itself (`dev-tools/sync-assets.ps1`) is Git-tracked.
- **Section-folder mapping** (also see `docs/HOMEPAGE-CONTENT-MAP.md` / `docs/HOMEPAGE-ASSET-MAP.md`): `Hero` → the `platinum-hero` container's background image/video (the one section that's intentionally a decorative cinematic background layer, not a semantic `<img>`); `Signature` → the native Elementor Image widget `platinum-signature-image` (inside the `platinum-signature-media` container); `Custom` → `platinum-custom-image`; `Hospitality` → `platinum-hospitality-image`; `Events` → `platinum-events-image`; `Craft` → `platinum-craft-image`; `Shop` → the `platinum-shop-slot-media` product slots (not yet converted to real `<img>` elements). `Logos` is handled separately since Alukas logo settings are global theme options, not an Elementor element. `Unsorted` (and any file dropped directly in `00-INBOX` with no category subfolder) is a supported, officially recognized category — synced/deduplicated/SEO-renamed normally, but never auto-assigned to any section; it's explicitly flagged as needing manual classification.
- **Import vs. assignment are separate steps.** The sync script only imports files into the Media Library and records them in the manifest — it never assigns an asset to an Elementor element. Assigning a specific imported asset to a specific section is always a distinct, explicit follow-up action (for the 5 Image-widget sections above, that means surgically setting that widget's `image` setting — see "Surgical Elementor content updates"). When more than one candidate asset exists for a section, never auto-pick one — report the candidates (filename + attachment ID) and wait for an explicit choice.
- **SEO-friendly filenames.** Real assets should not enter WordPress under generic filenames (`IMG_1234.jpg`, `imagegen.png`, `ChatGPT Image ....png`, etc). The sync script normalizes to `platinum-ice-<subject>-<context>-<variant>.<ext>` (lowercase, hyphens, no underscores/spaces/dates) automatically on import, importing from a temporary copy under that name — **the user's original file in the inbox is never renamed, moved, or modified.** The normalized name is derived only from words already present in the original filename (camera/download/AI-tool-name/timestamp junk tokens like `img`, `dsc`, `screenshot`, `final`, `edit`, `v2`, `chatgpt`, `midjourney`, month abbreviations, `am`/`pm` are stripped); it never invents a subject. If nothing usable survives that cleanup, the fallback is `platinum-ice-<category>-<short-hash>.<ext>` and the manifest entry is flagged `needsReview: true` rather than guessing a description.
- **Alt text is never auto-generated from a filename.** The manifest always imports with `altText: null`. Real alt text must be based on what's actually visible in the image, never keyword-stuffed — e.g. `"Clear square ice cube in a whiskey glass"`, not `"Best luxury premium clear ice cube Platinum Ice Los Angeles"`. It should only be written once the actual visual content is known — either the user supplies it, or Claude visually inspects the actual image file and proposes specific text for review; do not invent it just because a section "needs" alt text. Each asset also carries an `altTextGuidance` hint: `decorative-background` (Hero only — a real CSS/Elementor background image, no alt attribute applies, and it should never be forced); `content-image` (Signature/Custom/Hospitality/Events/Craft — real `<img>` elements once converted, meaningful content that eventually needs real, specific alt text); `product-content` (Shop — real product photography); `logo-specific` (Logos — alt text tied to the brand/site name, handled with the logo work, not this pipeline); `unassigned` (Unsorted, or anything with no category folder — no guidance until it's classified into a section).

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
