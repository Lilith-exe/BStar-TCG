# BStar Cards Changelog

## Latest
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
