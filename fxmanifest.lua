fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'bstar_cards'
author 'Lilith + Lola'
description 'Prototype BStar card system for QBCore'
version '0.6.11'

shared_scripts {
    'config.lua',
    'shared/collectibles-config.lua',
    'shared/cards.lua'
}

client_scripts {
    'client/main.lua',
    'client/packs.lua',
    'client/bulk-piles.lua',
    'client/sleeves.lua',
    'client/collectibles.lua',
    'client/duel.lua',
    'client/tables.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/condition-config.lua',
    'server/condition-rules.lua',
    'server/sleeve-config.lua',
    'server/card-presentation.lua',
    'server/deck-cosmetics.lua',
    'server/effects.lua',
    'server/duel.lua',
    'server/main.lua',
    'server/pack-config.lua',
    'server/pack-rules.lua',
    'server/bulk-piles.lua',
    'server/packs.lua',
    'server/sleeves.lua',
    'server/condition.lua',
    'server/collectibles.lua',
    'server/legacy-conversion.lua',
    'server/sleeve-duel.lua'
}

ui_page 'html/index.html'

files {
    'html/images/cards/*.png',
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/collectibles.js',
    'html/collectibles.css',
    'html/images/assets/bstar_binder.svg',
    'html/images/slabs/*.svg',
    'html/builder-copies.js',
    'html/builder-copies.css',
    'html/deck-designs.js',
    'html/packs.js',
    'html/packs.css',
    'html/bulk-piles.js',
    'html/sleeves.js',
    'html/sleeves.css',
    'html/sleeve-visuals.js',
    'html/sleeve-visuals.css',
    'html/images/sleeves/*',
    'html/foil.css',
    'html/foil.js',
    'html/foil-regions.css',
    'html/foil-registry.js',
    'html/foil-regions.js',
    'html/foil-regions-worker.js',
    'html/foil-materials.js',
    'html/foil-rarities.js',
    'html/foil-renderer.js',
    'html/foil-presets/*.json',
    'html/images/foil-index/*.png',
    'html/foil-mask.js',
    'html/foil-edge.js',
    'html/foil-samples.js',
    'html/images/foil/*.png',
    'html/images/assets/card_back_default.png',
    'html/images/assets/*.png',
    'html/images/thumbs/*.png'
}

dependency 'qb-core'
dependency 'qb-inventory'
dependency 'oxmysql'
