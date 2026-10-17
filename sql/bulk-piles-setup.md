# Physical Bulk Card Piles

Each unique `bstar_bulk_pile` item holds `info.id`, a persistent UUID. The card records live in `bstar_card_copies` at `location=pile`, with that UUID as `container_id`. An undelivered pile has a server-recorded `pending_owner`; delivered piles are accessed through actual server-side inventory possession. No slot number, client-supplied owner, or original opener grants access.

Use the item to open that exact pile. The browser also offers a selector for carried piles. Give/drop/pickup moves the real token and its collection; the previous carrier cannot request its pages or inspect it after losing possession. Duplicated IDs in connected inventories or offline saved player inventories block access for review. Inventory splits cannot split an individual pile. Empty piles are removed after durable card transfers; each nonempty pile has its own count tooltip.

## Approved inventory adapter

Only `qb-inventory/server/main.lua` was modified with explicit approval. The reviewable patches are `integration/qb-inventory-pile-safety.patch` and `integration/qb-inventory-pile-access.patch`. They apply to pile transfers only: authoritative Give/Drop metadata, no pile merging, rollback on rejected destination adds, own-inventory/nearby-open-drop/authorised-stash access checks, and a runtime capability export. Unrelated items keep their original paths. QBCore item registration and the pile icon metadata are handled inside BStar.

Valid player-to-player transfers use the inventory's normal Give action, preserving its distance and player-state checks. Direct `otherplayer-*` drag requests are denied for piles: this installed inventory does not bind that panel to an authorised viewer, so a client-provided player ID is insufficient permission. Supporting a police/robbery viewer would require an explicit server-authorised viewer binding; none is invented here. Authorised stashes use the installed `Inventories[id].isOpen == source` contract; nearby open drops use the installed distance check.

The loaded inventory must advertise adapter version 2 before BStar enables physical rewards. Merely editing its file is insufficient. No resource was restarted by this task.

## Existing personal records: separate approval required

No live database reads/writes or migrations were run in this pass. Personal rows (`location=bulk`) are preserved and block physical startup until migration is reviewed and approved. `sql/personal-to-physical.sql` is a non-destructive, review-only migration: create a stable per-character-to-pile mapping, insert an owner-bound pending delivery, and move existing copy identities into it. It does not recreate cards or change their IDs, metadata or timestamps. Prepared/review pack/move journals and inconsistent owners prevent card movement. Before execution, back up participating tables and inventory, inspect preflight counts, and compare copy counts/content hashes after migration. Ambiguous journal recovery must not be guessed or replayed blindly.

After approved migration, `/bstarpiles` delivers one pending pile when a slot is free, otherwise opens a carried pile. Packs prefer an existing nonempty carried pile; full inventories keep all six rewards in recoverable pending storage. Completed pack presentations do not grant again. Add All Bulk Piles transfers every copy from every carried pile into the selected carried Deck Box, without trimming duplicates or imposing deck limits. Existing per-copy pocket transfers and timestamps remain.

## World-drop limitation

The installed inventory's ground drops are memory-only and its normal cleanup/restart can remove a ground token. BStar never deletes the corresponding card records, but automatic durable world-drop restoration is not implemented. A vanished ground token requires verified operator recovery; do not assume the original opener is still its owner. This is a remaining limitation for full restart-safe physical world custody, not a guarantee that ground drops persist. Do not approve a broad rollout on the basis of the local transfer checks alone.

## Focused city checks after approved setup/loading

Test A dropping a known pile and B picking it up, A losing access, Give, multiple-pile swaps, authorised stash deposit/retrieval, full target rollback, duplicate-ID rejection, accurate per-pile counts, pending delivery, all-pile Deck Box transfer, reconnect, and resource lifecycle. Confirm opaque underneath foil, smooth unclipped swipes, rapid input and close during dismissal. Sleeving/degradation remain deferred; metadata and the three-hour grace timestamp are preserved.

## Empty pile reconciliation

The card transfer commits before token cleanup begins. Empty tokens use the existing move journal for removal/persistence recovery. Exact UUID/slot checks, empty database counts, pending-pack checks and pile locks prevent deleting another pile or one containing cards. A rejected removal retries on subsequent pile actions or the 30-second online inventory sweep. Inaccessible offline/stash/drop tokens stay intact until carried again. Unknown or duplicate IDs and ambiguous journal evidence fail closed for review. Empty database pile rows are intentionally retained as reconciliation evidence; card rows and migration protections are unchanged. A new UUID is created for later rewards when no suitable nonempty carried pile exists.

Local checks from the resource root: `lua tools/test-bulk-piles.lua` and `lua tools/test-bulk-piles-client.lua`. These use mocks and do not access the live database or restart resources.

## Startup diagnostics

Run `bstarstorage` in the server console after loading BStar to report starting/ready/failed state and the current initialisation phase. A 30-second warning identifies slow connection/query setup without enabling storage early or racing another initialisation. Setup exceptions report their phase and retain all existing safety locks. Storage rejection sends a notification instead of an empty pack presentation. The item-registration path handles detached QBCore snapshots during cold starts. Local regression: `lua tools/test-bulk-startup.lua` and `lua tools/test-packs-client.lua`.
