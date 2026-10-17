# Alpha Pack artwork

Mode: built-in imagegen edit of `html/images/assets/bstar_standard_pack.png`.
Saved wrapper: `html/images/assets/bstar_alpha_pack.png` (1024 × 1536 RGBA).
Prepared inventory icon: `html/images/assets/bstar_card_pack.png` (256 × 256 RGBA).
Follow-up approval received: the matching PNG is installed at `qb-inventory/html/images/bstar_card_pack.png`. It byte-matches the local prepared icon. Inventory code is untouched. Existing packaged server/client caches may still show the former art until normal user-controlled resource loading; no cache files were edited.

Prompt:

> Use case: text-localization. Edit this exact BStar booster-wrapper asset. Change ONLY the printed words "STANDARD PACK" on the lower pink brushstroke to "ALPHA PACK", using the same white distressed brush lettering with its black shadow/outline, same baseline and appropriate centered spacing. Preserve the full wrapper silhouette, upright front view, original aspect ratio, shiny pink crimped top and bottom seals, black/hot-pink/yellow BStar and Hardcore Comics graphics, all existing logos, 6 CARDS text, material folds, highlights and image quality. Keep everything else visually identical. Fully transparent background outside the wrapper, no halo or backdrop. Do not add props, new labels, borders or change the design. This will be used directly as a game UI wrapper with masked tearing layers.

The existing raster wrapper has no editable text layers in this resource. The replacement uses an image edit rather than a text overlay. Physical tearing uses registered clipped copies of the edited image, so print and foil detail stay on each separated piece. No video or extra shader context.
