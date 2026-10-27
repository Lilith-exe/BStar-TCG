-- Sleeve types are server-authoritative. Phase 1 sleeve items are weightless.
BStarSleeveConfig = {
    -- Cosmetics never consume protective sleeves and never affect condition.
    designs = {
        default = { label='BStar Classic', back='images/assets/card_back_default.png', starter=true },
        midnight = { label='Midnight', back='images/sleeves/midnight_back.svg', starter=true },
        violet = { label='Violet Orbit', back='images/sleeves/violet_back.svg', starter=true },
        ember = { label='Ember', back='images/sleeves/ember_back.svg', starter=true }
    },
    maxBatch = 100,
    condition = BStarConditionConfig and BStarConditionConfig.public or { goodMin=70, playedMin=40 }, -- Compatibility for isolated sleeve fixtures.
    pageSize = 48,
    containers = { box = 'deck_box', binder = 'bstar_binder' },
    types = {
        clear = { label = 'Clear Sleeve', item = 'bstar_sleeve_clear', reusable = true, image = 'bank_card.png', frontColour = '#cbd5e1', frontStyle = 'clear', back = 'images/assets/card_back_default.png',
            pack = { item = 'bstar_sleeve_clear_pack', quantity = 60 } },
        basic = { label = 'Basic Sleeve', item = 'bstar_sleeve_basic', reusable = false, image = 'bank_card.png', frontColour = '#334155', frontStyle = 'matte', back = 'images/sleeves/basic_back.svg',
            pack = { item = 'bstar_sleeve_basic_pack', quantity = 100 } }
    }
}
