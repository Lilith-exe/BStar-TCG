# BStar Cards — Duel System Bootstrap Context

Use this file as the starting context for continuing development in VS Code/Codex.

## User / project context

The project is **BStar Cards**, a custom trading-card/dueling system for a FiveM QBCore GTA V server called BStar. The user is Lilith/Lil/Lily, and the in-city character name for the card/comic/RP context is **Layla Hart**. The assistant is usually called **Lola**. The tone the user likes is collaborative, casual, energetic, and practical: suggest options, explain where to paste code, avoid overly dry responses, and be honest when something is uncertain.

The user is building this as both:

1. a playable in-world FiveM card game system, and
2. an RP/city collectible card ecosystem tied to Hardcore Comics.

The user is newer to coding but has been successfully implementing patches step-by-step. They prefer precise code locations and full replacement functions when possible. Avoid dumping vague instructions without saying exactly where code should go.

## Current overall stack

Resource name: `bstar_cards`

Likely key files:

- `fxmanifest.lua`
- `config.lua`
- `shared/cards.lua` or equivalent card definitions
- `server/main.lua`
- `server/duel.lua`
- `client/main.lua`
- `client/duel.lua`
- `client/tables.lua`
- `html/index.html`
- `html/app.js`
- `html/style.css`
- card images: `html/images/cards/`
- card thumbs: `html/images/cards/thumbs/`

The project uses QBCore on the test server. The real BStar server likely uses a custom version of `ox_inventory`, while the test server has been using qb-inventory/qb-target-style flows. Design new duel logic to be inventory-agnostic where possible. Inventory is mostly relevant for deck box usage/storage, not for the duel engine once deck data is loaded.

## Important inventory/card item conventions

Card item name: `bstar_card`

Deck box item name: `deck_box`

Cards are usually identified by `cardId` and loaded from card definitions. Images are referenced like:

```lua
'nui://bstar_cards/html/images/cards/' .. card.inventoryImage
```

Inventory metadata has included fields like:

```lua
{
  cardId = card.id,
  label = card.name .. " (" .. card.rarity .. ")",
  rarity = card.rarity,
  inventoryImage = card.inventoryImage,
  description = card.setCode .. " - " .. card.edition .. "\n\n" ..
                card.type .. " | " .. card.job .. " | Lv." .. card.level .. "\n\n" ..
                card.speed .. " • " .. card.attack .. " • " .. card.defense,
  display = false
}
```

Deck boxes have a unique ID stored in item info, usually `item.info.id`, e.g. `DB-...`.

## Deck builder status

The deck builder currently exists and mostly works. It has:

- deck hub screen
- deck create/save/delete
- deck builder screen
- owned card pool
- selected deck cards
- card preview panel
- card info/effect preview
- filters/search
- rarity/type/stat filtering
- deck validity count `30–50`
- max copies logic currently 3 per card

Important current user preference:

- The deck builder UI should look like Master Duel: left preview panel, central deck area, right card pool/search/filtering.
- Card stats preview should be stylized, not plain text.
- Effect title should be bold with divider below, effect text large/readable.
- Avoid duplicate labels like `ATK ATK: 30`; just show `ATK: 30` or visually clear stat boxes.
- The add/remove collection/deckbox window should share the same visual style as deck builder, but drag/drop may eventually be removed in favour of click interactions.

## Duel rules currently chosen

The user decided:

- no defense position system
- no per-card HP
- Life Points exist for players
- current test LP value is around `1000`, final could be `500–2000`
- Battle phase only allows attacks
- each fighter can attack once per turn unless an effect says otherwise
- a fighter can attack an enemy fighter in one of 3 fighter zones
- direct attacks are allowed only if opponent has no fighters, unless future card effects allow otherwise
- combat resolution:
  - if `ATK > DEF`: defender destroyed, difference inflicted as LP damage to defender
  - if `ATK == DEF`: both cards destroyed, no LP damage
  - if `ATK < DEF`: attacker destroyed, difference inflicted as rebound LP damage to attacker
- SPD should become an evasion/dodge mechanic with thresholds/caps. A basic dodge system exists or was started (`calculateDodgeChance`, `rollSuccess`).
- Response cards/exceptions during opponent’s turn are planned later, but not now.

## Duel engine status

The duel engine has working/prototyped:

- creating test duel using player deck as both sides for solo testing
- phases: draw, main, battle, end
- advancing phases
- ending turn
- turn ownership lockout
- solo debug tools to act as opponent / spawn opponent / spawn me / advance opponent turn were added during testing
- hand draw
- summon fighter into one of 3 fighter zones
- attack targets
- direct attack
- ATK vs DEF combat
- LP damage
- battle result events to NUI
- attack feedback, including attack line, damage popups, destroyed flash
- cards destroyed in fighter zones move to graveyard
- graveyard count included in state
- plan to expose full graveyard list to NUI
- deck-out loss was planned/partially patched by replacing `drawCards` with deck-out logic

### Important server functions from `server/duel.lua`

These exist or should exist:

- `drawCards(duel, playerIndex, amount)`
- `Duel.Start(duelId)`
- `Duel.AdvancePhase(src, duelId)`
- `Duel.EndTurn(src, duelId)`
- `Duel.Attack(src, duelId, attackerZoneIndex, targetType, targetZoneIndex)`
- `buildPrivateStateForPlayer(duel, viewerIndex)`
- `moveFieldCardToGraveyard(playerState, zoneIndex)`
- `checkWinCondition(duel)`
- `sendDuelStateToPlayers(duel)`
- `getControllingPlayerIndex(duel, src)`
- `getOpponentIndex(playerIndex)`
- `getCardStat(card, statName)`
- `getOccupiedFighterCount(playerState)`
- `calculateDodgeChance(attackerCard, defenderCard)`
- `rollSuccess(chance)`

### Current/desired `buildPrivateStateForPlayer` additions

For table mode, the private state should include:

```lua
tableId = duel.tableId,
tableMode = duel.tableId ~= nil,
```

near the top of returned state. This was added/needed because relying on global `CurrentDuelTableId` in `client/duel.lua` was brittle and often nil by the time NUI opened.

For graveyards, return both count and full payload list:

```lua
graveyardCount = #selfState.graveyard,
graveyard = buildCardPayloadList(selfState.graveyard),
```

and similarly for opponent:

```lua
graveyardCount = #oppState.graveyard,
graveyard = buildCardPayloadList(oppState.graveyard),
```

### Deck-out logic desired

`drawCards` should set duel as finished if a player attempts to draw from an empty deck:

```lua
local function loseByDeckOut(duel, playerIndex)
    duel.status = "finished"
    duel.winner = getOpponentIndex(playerIndex)
    duel.winReason = "deck_out"
end
```

Then in `drawCards`, if `#player.deck == 0`, call `loseByDeckOut(duel, playerIndex)` and break.

`checkWinCondition` should early return true if `duel.status == "finished"`.

## World/table duel mode status

The old full-screen duel UI/harness worked but is now considered only a debug fallback. The goal is now a **real in-world table duel mode**.

The table system was started using:

- `client/tables.lua`
- `Config.DuelTables` in `config.lua`
- `qb-target` `AddBoxZone`
- a temporary outdoor table at roughly:
  - x: `-1267.44`
  - y: `-1457.14`
  - z: `4.18`
  - heading: around `126.25`

The camera angle was eventually tuned by the user and should not be assumed from old suggested values. Ask/check current `config.lua` for exact current camera.

Current intended behaviour:

1. Player uses deck box first so a current deck box ID/deck context exists.
2. Player third-eyes the configured duel table.
3. Client calls `GetDecksForTestDuel`, chooses first deck for solo test.
4. Client triggers server event `bstar_cards:server:StartTableTestDuel`.
5. Server creates duel with `duel.tableId = tableId`.
6. Server triggers `bstar_cards:client:EnterDuelTableView` before/around starting duel.
7. Client starts a scripted camera.
8. NUI opens in table mode, not old debug mode.

### Current target/client table flow

`client/tables.lua` has/debugged these prints:

- `[BStar Tables] client/tables.lua loaded`
- `[BStar Tables] qb-target action fired for table: beach_table_1`
- `[BStar Tables] UseDuelTable fired with tableId: beach_table_1`
- `[BStar Tables] CurrentDeckBoxId: DB-...`
- `[BStar Tables] GetDecksForTestDuel callback, deck count: ...`
- `[BStar Tables] EnterDuelTableView event received: beach_table_1`
- `[BStar Tables] StartDuelCamera called for tableId: beach_table_1`

A previous `qb-target` issue was fixed by avoiding a fragile `TriggerEvent` bounce and calling `UseDuelTable(tableId)` directly inside the target action. Closure values should be copied into locals before registering target actions.

### Important bug/fix history

- `Config` was nil because `config.lua` had a missing comma and failed to parse. Fix was adding comma between `seat = {...},` and `camera = {...}` or similar.
- `Config` must be global style:

```lua
Config = Config or {}
Config.DuelTables = { ... }
```

not `local Config = {}`.

- `CurrentDuelTableId` was often nil in `client/duel.lua`, causing `tableMode = false` and old UI to open. Better fix: include `tableMode`/`tableId` in the duel state from server and use `duelState.tableMode == true` for NUI.
- If still relying on `CurrentDuelTableId`, make sure `StartDuelCamera` sets `CurrentDuelTableId = tableId` **after** calling `StopDuelCamera()`, because `StopDuelCamera()` clears it.

## Current table UI state

The table UI is now rendering physically over the table and is no longer the giant modal when `tableMode` works.

Current result seen:

- camera points down at the temporary table
- phase/LP widgets visible
- 3 opponent fighter zones and 3 self fighter zones visible in centre
- hand cards are visible but too close/overlapping field
- hand should be moved away from field, likely toward bottom edge / player side
- UI is still too squashed/tiny and needs to spread out like Master Duel
- zones should look etched/projected onto the table surface, not like black boxes floating above it
- the user wants the zones to match the table perspective visually
- CSS 3D `rotateX` experiments were bad/cursed: cards turned into razor-blade stacks or disappeared. Avoid rotating entire board/cards for now.
- Better approach: use the real camera perspective and place flat NUI elements carefully; use subtle skew/clip-path only for zone outlines later, not card images.

### Current table UI preference

The user wants:

- a wider, more Master Duel-like table field
- bigger cards/zones with nice spacing
- hand out of the way of the fighter field
- zones appearing projected/etched into the wood
- subtle holographic/glowy outlines, not giant debug rectangles
- card hover elevation/glow
- summon animation from hand to zone later
- attack lines streaking across the table
- spectators eventually able to walk up and watch

### Important table UI separation

The hand row should likely be outside the table board overlay or at least separately positioned so it does not inherit any perspective transforms and does not cover the fighter zones.

Desired structure concept:

```html
<div id="tableDuelWrap" class="table-duel-wrap hidden">
  <div id="tableBoard" class="table-board">
    <!-- phase/LP maybe, fighter zones, item/equipment zones later -->
  </div>

  <div id="tableHandRow" class="table-hand-row"></div>

  <div class="table-debug-actions">
    <button id="tableNextPhaseBtn">Next Phase</button>
    <button id="tableEndTurnBtn">End Turn</button>
    <button id="tableCloseBtn">Close</button>
  </div>
</div>
```

Debug buttons currently exist or are intended:

- Next Phase
- End Turn
- Close
- Spawn Opp
- Spawn Me maybe still present

The user reported not being able to use the mouse at one point. It had previously been fixed, but if it happens again, check:

```lua
SetNuiFocus(true, true)
SetNuiFocusKeepInput(false)
```

when opening duel UI, and reset with:

```lua
SetNuiFocus(false, false)
SetNuiFocusKeepInput(false)
```

on close.

## Current stuck-on-exit bug

There is a known nonfatal bug: when exiting duel/table view, the player can become visible but stuck/unable to move. The user decided to defer this to bug-fixing phase.

Still, the likely fix is ensuring the close path calls table exit cleanup exactly once.

Safe reset function concept in `client/tables.lua`:

```lua
local function StopDuelCamera()
    local ped = PlayerPedId()

    if DuelCam and DoesCamExist(DuelCam) then
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(DuelCam, false)
        DuelCam = nil
    end

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, true, false)
    SetPlayerControl(PlayerId(), true, 0)

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    CurrentDuelTableId = nil
end
```

Emergency test command helpful:

```lua
RegisterCommand('fixduelcam', function()
    TriggerEvent('bstar_cards:client:ExitDuelTableView')
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end, false)
```

If using a control-disable loop while table mode active, ensure its condition stops when exiting.

## Current `app.js` routing requirements

The table mode routing should be explicit.

There should be only one `openDuelUi` and one `renderDuelUi` function. Duplicates caused regressions before.

Message handler should do:

```js
if (data.action === 'openDuelUi') {
  openDuelUi(data.duel, !!data.tableMode);
}

if (data.action === 'updateDuelUi') {
  updateDuelUi(data.duel, !!data.tableMode);
}
```

`openDuelUi` should set:

```js
duelTableMode = tableMode;
```

and show/hide:

```js
if (duelTableMode) {
  tableDuelWrap.classList.remove('hidden');
  duelWrap.classList.add('hidden');
} else {
  duelWrap.classList.remove('hidden');
  tableDuelWrap.classList.add('hidden');
}
```

`renderDuelUi()` must start with:

```js
if (duelTableMode) {
  renderTableDuelUi();
  return;
}
```

Useful debug logs:

```js
console.log('[BStar NUI] openDuelUi tableMode:', tableMode);
console.log('[BStar NUI] renderDuelUi duelTableMode:', duelTableMode);
```

## Current table render JS concept

`renderTableDuelUi()` currently/should:

- set phase badge text
- set self/opponent LP
- render opponent fighter zones
- render self fighter zones
- render hand cards
- click hand card to select in main phase
- click empty self zone to summon selected fighter
- click self fighter in battle phase to select attacker
- click opponent fighter to attack
- if opponent has no fighters and attacker selected, show/direct target

Important functions:

- `renderTableZone(card, side, zoneIndex)`
- `renderTableDuelUi()`
- `getCardImagePathFromPayload(card)`
- `setDuelPreviewCard(card)` placeholder currently just logs, but should become left-side preview later

## Next visual work to do

The user explicitly wants to do these soon:

1. spread table UI out more, Master Duel style
2. move hand out of the field area
3. make zone outlines look etched/projected onto the table
4. add hover/selected glow on cards and target zones
5. summon animation hand-to-zone
6. attack line on table surface
7. card preview panel when clicking any card
8. clickable graveyard popup on right side
9. eventually item/event slots and equipment slots
10. eventually spectator support

The user specifically likes the field layout where:

- fighters are central, facing each other
- each fighter has equipped weapon/vehicle cards below or associated beneath/near it
- 4 item/event slots exist as their own row
- location card has its own slot
- deck and cemetery/graveyard slots exist at sides
- left side can show card preview/effect like deck builder
- right side can show scrollable graveyard popup when a cemetery is clicked

The user disagreed with moving fighters away from centre; keep fighters in centre of battle.

## Card/comic/RP context from recent event

Not directly coding-related but relevant to BStar cards/comics/art:

The user recently attended an RP winery summit in city. It became a violent incident now nicknamed “The Winery Massacre”. They may want comics/cards around it.

Important character/location details:

- User’s city name is **Layla**, not Lilith.
- Tazentine hosted the event.
- The meeting was at a winery with a huge formal table, security, fancy summit vibes.
- First there was a gunshot; attendees were told it had been dealt with and not to worry.
- Later, FIB/federal agents and/or conflict involving triads/security caused gunfire around civilians.
- A bald Agent-47-looking FIB agent was present; he did not exactly personally spray the crowd, but FIB automatic fire caused collateral damage / huge public scrutiny.
- Kenzie was the femme fatale who pulled a pistol from her leg strap and returned fire from the winery windows.
- Xena Mironova = Chief of EMS.
- Clyde Sr = Director of SAMS and is a man.
- Max Turner Riley = EMS command.
- Layla and Kin Rodin hid together behind the bar; Kin is Layla’s Hardcore Comics employee and friend.
- Survivors may seek compensation/PTSD class action against FIB.
- Birdy is the city Twitter equivalent.

A generated comic page mistakenly called Layla “Lilith” and Clyde Sr looked female; correct these if generating future versions.

## Tone/style preferences for code help

The user likes:

- direct “put this here” guidance
- full replacement functions
- quick sanity checks
- debugging in F8/server console
- casual encouragement but not empty fluff
- warning when a patch is risky
- not over-polishing temporary layouts if they will be replaced

The user often says “where tf do I put X?” so prefer:

- “Put this under your refs”
- “Replace this whole function”
- “Add this inside message handler”
- “Restart resource/full restart needed”

Avoid assuming the user wants a generated image when asking for code/UI. There was a previous accidental issue where image generation fired during code/design discussion; don’t do that unless explicitly requested.

## Immediate next likely task

Continue building table duel UI. Current likely tasks:

- fix/move `tableHandRow` so it is not over the field
- enlarge/spread fighter zones
- refine CSS so zones look on-table rather than black boxes
- ensure mouse interactions work in table mode
- allow phase advance/debug controls in table mode
- later build graveyard viewer

Recommended next implementation order:

1. inspect current `index.html` table wrapper and current `style.css` table classes
2. move `tableHandRow` outside `tableBoard` if not already
3. set hand to `position: fixed`/bottom HUD style, or place it near bottom table edge but below fighter zones
4. adjust `.table-board` width/height and fighter row positions
5. create “holographic zone” style using transparent border/glow, not black filled boxes
6. test summon/phase interactions
7. then add GY viewer and win overlay

## Latest Codex pass

The table duel UI has now been pushed further toward the intended in-world layout:

- `tableHandRow` was moved outside `tableBoard` so hand cards no longer inherit/compete with board layout.
- Fighter zones were widened/spread out and restyled as lighter projected/etched zones instead of heavy black boxes.
- Hand cards now sit in a fixed bottom HUD strip with hover/selected lift.
- A left table card preview panel was added; clicking hand/field/graveyard cards updates it.
- A right graveyard panel was added with self/opponent GY buttons and a clickable card list.
- Duel card payloads now include `job` for richer preview metadata.
- NUI focus keep-input was set to `false` in `client/duel.lua` to reduce table-mode control/mouse weirdness.

Verified:

- `node --check html/app.js` passes.
- No Lua parser (`luac`) is available in this workspace, so Lua still needs in-server restart/F8 validation.
