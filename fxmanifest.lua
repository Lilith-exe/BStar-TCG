fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'bstar_cards'
author 'Lilith + Lola'
description 'Prototype BStar card system for QBCore'
version '0.6.11'

shared_scripts {
    'config.lua',
    'shared/cards.lua'
}

client_scripts {
    'client/main.lua',
    'client/duel.lua',
    'client/tables.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/effects.lua',
    'server/duel.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/images/cards/*.png',
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/foil.css',
    'html/foil.js',
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
