# BStar Cards Changelog

## Latest
- Added Alpha Pack standard six-card pack opening with configured rarity odds, God Packs, sequential reveals, card inspection, journal-backed recovery and branded pack artwork/inventory icon.
- Added tearable pack annimation.
- Added bulk card pile which new opened cards go into to not overfill pockets.

## v0.7.3
- Updated discord dev stats on the update logs

## v0.7.2
- Discord update announcements now include per-update file/line changes and tracked source-file/line totals.
- Drastically optimised shader loading and efficiency.
- Compressed 10 masks per card into 1 grayscale mask with encoded instructions to decode. (optimised the required mask images from 1500 down to 300)
- Added selective masks to rarity shaders so certain sections are foil, others not.
- Updated cards to align with changes made to the master cards list.
- Added updated foil shaders for rare, super rare, ultra (damascus rare), secret rare and ghost rare.

## v0.7.1
- Introduced first pass rarity effects for cards. (lots of refinement needed)

## v0.7.0
- Added a large pass of effect-engine plumbing across the ALPH1 set, including many previously deferred fighter, item, vehicle, weapon, location, and promo-card effects.
- Expanded the reusable effect engine with deck/cemetery/banish movement, selected targets, multi-select prompts, costs, counters, statuses, delayed actions, LP changes, dice rolls, equipment modifiers, and card-tag based search filters.
- Added first-pass response-chain support so summons, promotions, attacks, card plays, activated effects, and effect actions can pause for opponent responses and then continue resolving.
- Added protection/replacement hooks for destruction, targeting, LP loss/gain, burn/status prevention, and one-use shield effects.
- Added delayed-task and duration support for multi-turn effects, temporary statuses, crash effects, extra attacks, and start/end phase triggers.
- Added battle hooks for attack declaration, direct attacks, battle damage, dodges, battle destruction, and battle-related cemetery sends.
- Added visible status/counter payloads and table badges, plus proper banished-card inspection beside cemetery browsing.
- Added stronger pending-action guards so players cannot continue normal duel actions while prompts, selections, or chains are unresolved.
- Added broader equipment support, including same-name multi-equip handling, cross-field equipment movement, equipped-fighter stat modifiers, and battle-aware equipment bonuses.
- Added CSV/card-data resilience for regenerated card IDs, including alias lookups, merged deck-box stacks, diagnostic commands, and `bstarnormalizeids` dry-run/apply cleanup.
- Fixed solo test duel flow so shared-client coin toss and response prompts no longer leave the table waiting on a missing opponent.
- Fixed Clyde Riley Sr.'s generated image filename lookup and several shifted-ID/deck-box display issues after CSV regeneration.
- Updated Bob's Bush to work as a continuous item-zone trap with optional attack response wording.
- Updated Layla Hart EN014 so the discard is player-chosen instead of automatic/random.
- Updated Xena Miranova EN023 to use Healing counters, auto-gain counters from Item plays without a prompt, and only glow/activate her heal once 3 counters are available.
- Added gitignored local review/errata notes for unclear card text, engine blockers, and card wording changes.

## v0.6.8
- Updated cards.lua to be in line with the master list.
- Added 115 new card artworks.
- Pushed better effect wording for some cards.
- Balanced EN001 Layla Hart from 300LP to 200LP cost. 
- Rewrote CSV to LUA script for better failsafes and more functionality.
- Rewrote batch thumb generator for better efficiency.
- Added first pass effects engine support for EN011 to EN020.
- Added some more tags and effects into the effects engine.

## v0.6.7
- Added support for 16:9 aspect ratio. (dynamic scaling coming soon)
- Added 2 player support 
- Fixed how item cards work. (item cards now place on the field first and only go to cemetery once the effect has resolved)

## v0.6.6
- Added default card backs 
- Boosted stats now show green and decreased stats show red in the preview panel
- Opponents card stat panel moved below the card from above

## v0.6.5
- Added new game mechanic: Tribute Promotion
    - Tribute promotion allows a player to summon a level 2 fighter without the correct named level 1 fighter, instead sacraficing 2 generic level 1 fighters and their equipment to summon the level 2 instead.
    - True promotion still exists and is the more efficient route.

## v0.6.4
- Added general annimation engine for card movement throughout field
- Adjusted equipped card placement
- Added deselect logic to clicking outside of a card
- Added gamewide glow colour language (yellow for activatable effects, blue for normal summonable fighters, green for promotion, purple for anything else)

## v0.6.3
- Started card-by-card effect plumbing for ALPH1-EN001 through ALPH1-EN010
- Added reusable effect actions for stat modifiers, filtered hand discard, graveyard revival, deck equipment and deck swapping
- Added reusable effect conditions and once-per-turn / once-per-game guards
- Added reusable prompted effect forms for pay/choose effects, then wired Layla Hart's Moving Funds effect into it
- Equipped Vehicle and Weapon cards now apply their printed ATK/SPD modifiers to the fighter in the same equipment slot
- Balanced Layla Hart's Moving Funds as once per card copy per duel and highlighted selected effect choices
- Limited field effect glow to just cards on the field
- Normalized stat values in cards.lua and the master CSV so ATK/DEF/HP/SPD labels do not live inside stat columns
- Split fighter equipment into Vehicle and Weapon sub-slots so one of each can be attached to the same fighter
- Changed Brock Lee to search a Vehicle from deck, then let the player choose which available fighter equips it
- Removed activated-effect glow after once-per-turn or once-per-duel effects have been spent
- Restored equipped cards to the larger behind-fighter top-right visual treatment
- Kept equipped cards attached when a fighter is promoted, transferring their bonuses to the promoted fighter
- Offset the second equipped card farther outward while preserving the single-equipped-card look
- Made Brock Lee's on-summon Vehicle search/equip effect optional
- Issued errata on EN005 Xena Miranova 
- Issued errata on EN008 Alex Ortiz
- Added glow UI elements to activatable effects in the cemetary and hand

## v0.6.2
- Restored Discord update embed layout so Branch appears above Changes

## v0.6.1
- Improved prompt minimise/restore animations and strengthened the restore button glow
- Kept duel prompt backdrop clear while making the prompt panel subtly purple and transparent
- Softened duel prompt backdrop and added click-outside minimising with a glowing restore button

## v0.6.0
- Added the first server-side keyword/tag effect engine
- Wired effect triggers into summon, play, draw and end-phase duel actions
- Added executable effect metadata to starter cards for draw, search, heal, special summon and LP steal effects
- Added optional effect prompts and field-activated effect support
- Added yellow table glow and preview activation button for cards with activatable effects
- Added a second Main Phase after Battle Phase
- Allowed Location cards to replace the currently active Location, sending the old one to the cemetery
- Changed one-shot Item cards to resolve to the cemetery instead of staying in item zones
- Moved equipped cards to the cemetery when their equipped fighter leaves the field
- Hid legacy table EQP support rows and cleared attack targeting highlights immediately after attacks
- Fixed Wyatt Rayne searching `Rileys Performance` instead of `Riley's Performance`
- Fixed stale attack target highlights persisting into later phases or new turns
- Fixed optional `you can` effect prompts not queuing because of Lua helper scoping
- Updated Kiri Riley to prompt before special summoning Terrance Redfield Riley from deck or cemetery
- Added deck-search card selection UI and changed Nikolas Haaja Level 2 to choose a Location card instead of auto-picking
- Sent deck-search pickers directly from server to client so Wyatt Rayne and Nikolas Haaja searches open immediately
- Raised deck-search modal above the table UI and added search result notifications for troubleshooting
- Fixed pending duel interaction sync recursion that prevented search pickers from opening
- Changed Wyatt Rayne to use the deck-search picker for Riley's Performance
- Enlarged deck-search picker with horizontal card browsing, preview-on-click and confirm selection

## v0.5.3
- Fixed Clyde Riley Sr card
- Fixed thumbnails for deck editor

## v0.5.2
- Fixed Clyde Riley Jr card

## v0.5.1
- Fixed visual bug in deck editor

## v0.5.0
- Removed test cards
- Reverted .gitignore
+ Added all 151 base set cards
+ Optimised card images 
+ Added dev 'give all cards' command for testing

## v0.4.1
- Updated gitignore

## v0.4.0
- Rewrote fighter system to use a HP system instead of the legacy ATK/DEF system
- Direct attacks still damage player LP, while fighter attacks now damage the targeted fighter HP
- Fighter attacks now pierce excess damage through to the defending player's LP when the defender is destroyed
- Updated duel/table/deck-builder stat displays and filters to show HP instead of DEF
- Kept old `defense` card data as a temporary HP fallback until card definitions/art are regenerated

## v0.3.3
- Final ATK/DEF version before redesign

## v0.3.2
- Updated README

## v0.3.1
- Fixed YAML

## v0.3.0
- Added first-pass non-fighter zone plumbing for item, event, location and vehicle/equipment cards
- Added temporary non-fighter debug cards for testing zone movement
- Adjusted support-zone layout and changed event cards to use an Activate pill before resolving
- Changed equipment cards (weapons and vehicles) to attach to fighter zones and render tucked behind the equipped fighter

## v0.2.19
- Changed coin flip animation (placeholder, will be replaced with 3d modeled animation later)
- Routed close button to same surrender prompt as esc button
- Added a dodge callout when SPD evasion successfully avoids an attack
- Restyled dodge callout as larger bold red floating text

## v0.2.18
- Refined and optimised annimations
- Switched to using thumbnails for hand and annimations (optimisation)

## v0.2.17
- Relabeled opponents deck and cemetary to better distinguish from your own
- Added annimations for summoning, destroying and promoting
- Adjusted deck and cemetery location

## v0.2.16
- Increased glow around selected attackers and potential promotion targets
- Added 'Attacker' and 'Tribute' pills above targets
- Added deckout lose condition
- Fixed opponents hand not showing the correct amount of cards

## v0.2.15
- Fixed Discord changelog automation
- Fixedautomatic version bumping
- Fixed changelog archival system

## v0.2.14
- Added Discord changelog automation
- Added automatic version bumping
- Added changelog archival system

## v0.2.13
- Changed LP to HP to be inline with card text
- Added red glow when HP below 200
- Fixed normal summon glow still showing when all fighter slots were full

## v0.2.12
- Updated discord webhook logo
- Adjusted webhook layout

## v0.2.11
- Added version number and CHANGELOG.md
