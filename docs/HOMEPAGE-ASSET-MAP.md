# Homepage Asset Map — Page 841 (Platinum Ice Home, draft)

Specification of every image/video asset the approved homepage structure needs. No imagery has been created, generated, downloaded, or invented — this is a technical brief for sourcing/producing real Platinum Ice photography and video. All dimensions/ratios below are standard production recommendations, not invented product specifications.

Once real files exist, hand them to Claude and the "Media Library Automation" workflow (see chat report / future sessions) takes them from local file → attached, responsive, and assigned to the correct element.

## 1. Hero

- **Section / element class:** Hero — `platinum-hero` (currently solid Obsidian #0A0A0A background)
- **Intended visual:** cinematic premium clear ice and/or cocktail imagery, or video loop
- **Orientation:** landscape / full-bleed
- **Recommended aspect ratio:** ~16:9 to 21:9 (wide cinematic crop tolerates the tall 90vh desktop hero without excessive cropping)
- **Recommended source resolution:** at least 2560×1440 (image) if a still; if video, at least 1920×1080 source, ideally 4K master for future-proofing
- **Desktop use:** full-bleed background fill, content anchored bottom-left over it
- **Mobile crop consideration:** center-weighted crop; the subject should read at a roughly 4:5–3:4 mobile viewport crop without losing focal subject (ice/glass)
- **Image or video:** either; video should be silent/looping, short (10–20s), heavily compressed
- **File format:** `.jpg` (still) or `.mp4`/`.webm` (video); avoid `.png` for photography (unnecessary file size)
- **Performance notes:** hero asset is the largest LCP risk on the page — must be served responsively (see workflow) and video should have a poster-frame still fallback for slow connections/reduced-motion users
- **Proposed filename:** `hero-clear-ice.jpg` or `hero-clear-ice.mp4`

## 2. Signature Ice

- **Section / element class:** `platinum-signature-media`
- **Intended visual:** clear premium ice product photography (signature cubes/spheres/Collins spears)
- **Orientation:** portrait or square-ish (section is a 50/50 split, media occupies roughly half the viewport width)
- **Recommended aspect ratio:** 4:5 or 1:1
- **Recommended source resolution:** at least 2000×2500 (4:5) or 2000×2000 (1:1)
- **Desktop use:** fills the left half of the split section, full height
- **Mobile crop consideration:** stacks full-width above the copy; a square or slightly-portrait crop reads cleanly at mobile width without letterboxing
- **Image or video:** image (product-still photography)
- **File format:** `.jpg`
- **Performance notes:** should be sharp/high-detail (this is the "hero product shot" of the ice itself) — do not over-compress
- **Proposed filename:** `signature-ice-product.jpg`

## 3. Custom Ice

- **Section / element class:** `platinum-custom-media`
- **Intended visual:** logo/monogram/custom-shape ice
- **Orientation:** portrait or square-ish
- **Recommended aspect ratio:** 4:5 or 1:1
- **Recommended source resolution:** at least 2000×2500 (4:5) or 2000×2000 (1:1)
- **Desktop use:** fills the right half of the split section (reversed layout vs. Signature Ice)
- **Mobile crop consideration:** same as Signature Ice — square/portrait crop tolerant
- **Image or video:** image
- **File format:** `.jpg`
- **Performance notes:** logo/monogram detail must remain legible at both desktop and mobile crop — avoid extreme close-crops that cut off the engraved detail
- **Proposed filename:** `custom-ice-monogram.jpg`

## 4. Hospitality

- **Section / element class:** `platinum-hospitality-media`
- **Intended visual:** premium bar/restaurant cocktail environment (ice in situ, not a product-only shot)
- **Orientation:** landscape (this section is a 60/40 split with media as the wider 60% side)
- **Recommended aspect ratio:** 3:2 or 4:3
- **Recommended source resolution:** at least 2400×1600
- **Desktop use:** fills the left 60% of the section, full height
- **Mobile crop consideration:** stacks full-width; center-weighted crop on the glass/ice subject since sides will crop first on narrow viewports
- **Image or video:** image, or short ambient video loop if available
- **File format:** `.jpg` or `.mp4`
- **Performance notes:** should read as "environment/lifestyle," distinct in tone from the product-still shots (Signature/Custom) — avoid it looking like another product photo
- **Proposed filename:** `hospitality-bar-environment.jpg`

## 5. Events

- **Section / element class:** `platinum-events-media`
- **Intended visual:** wedding/private/corporate luxury event usage of ice
- **Orientation:** portrait or square-ish
- **Recommended aspect ratio:** 4:5 or 1:1
- **Recommended source resolution:** at least 2000×2500 (4:5) or 2000×2000 (1:1)
- **Desktop use:** fills the left half of a 50/50 split (light-toned section)
- **Mobile crop consideration:** square/portrait crop tolerant, same pattern as Signature/Custom
- **Image or video:** image
- **File format:** `.jpg`
- **Performance notes:** should read editorially (event/lifestyle), not as a generic stock wedding photo — must not include invented client names/branding
- **Proposed filename:** `events-luxury-occasion.jpg`

## 6. Shop Preview (×3 product slots)

- **Section / element class:** `platinum-shop-slot-media` (×3, one per slot)
- **Intended visual:** individual premium product imagery — one distinct real product photo per slot once real products exist
- **Orientation:** portrait or square (merchandising-style, not landscape "billboard")
- **Recommended aspect ratio:** 4:5 or 1:1 (consistent across all 3 slots for visual rhythm)
- **Recommended source resolution:** at least 1600×2000 (4:5) or 1600×1600 (1:1) per product
- **Desktop use:** 3-across grid, each slot roughly equal width
- **Mobile crop consideration:** slots stack to 1-across full width; consistent aspect ratio across all 3 avoids uneven card heights
- **Image or video:** image
- **File format:** `.jpg`
- **Performance notes:** should be shot on a consistent neutral backdrop across all products for a cohesive merchandising grid; lazy-load candidates since this section is below the fold
- **Proposed filenames:** `shop-product-01.jpg`, `shop-product-02.jpg`, `shop-product-03.jpg` (placeholders — real filenames should reflect actual product names once assigned)

## 7. The Craft

- **Section / element class:** `platinum-craft-media`
- **Intended visual:** clear-ice production / craft / process visual (e.g., directional-freezing equipment, block-cutting, the making-of process)
- **Orientation:** landscape (this section is a 40/60 split with media as the wider 60% side)
- **Recommended aspect ratio:** 3:2 or 16:9
- **Recommended source resolution:** at least 2400×1600 (still) or 1920×1080 source (video)
- **Desktop use:** fills the right 60% of the section, full height
- **Mobile crop consideration:** stacks full-width below the copy; center-weighted crop on the process subject
- **Image or video:** video preferred if available (process/craft storytelling benefits from motion), image acceptable
- **File format:** `.jpg` or `.mp4`
- **Performance notes:** if video, keep it short/looping/silent with a still poster-frame fallback, same as the hero
- **Proposed filename:** `the-craft-process.jpg` or `the-craft-process.mp4`

## Not asset-mapped this round

- Final CTA and Temporary Footer sections are intentionally text-only (no imagery), per the approved design.
- Site logo assets are a separate deliverable — see the Header/Logo Audit findings in the chat report for exact format/dimension requirements (not duplicated here since it's a site-wide asset, not a homepage-section asset).

## General technical notes (apply to all assets above)

- **Color grading:** all photography/video should read within the approved palette's tonal range (Obsidian/Charcoal/Platinum Silver/Ice White/Warm White/Soft Gray) for visual cohesion with the surrounding sections — this is a styling note for the photographer/editor, not a constraint on file format.
- **No embedded text/logos in photography** unless it's the product's own actual engraved/branded ice — avoid stock-photo watermarks or placeholder text baked into image files.
- **Responsive delivery:** once real files are imported, WordPress's native responsive `srcset`/`sizes` (or the Media Library Automation workflow's explicit size handling) should be used rather than serving one oversized file to all breakpoints.
