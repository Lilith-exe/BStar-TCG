-- Server-only probabilities: integer weights out of 10,000 (one basis point).
BStarPackConfig = {
    standardItem = 'bstar_card_pack',
    itemImage = 'bstar_card_pack.png', -- Matching icon installed in qb-inventory/html/images.
    registerItem = true, -- QBCore runtime registration; never edits qb-core/shared/items.lua.
    sets = {
        standard = {
            label = 'Alpha Pack', setPrefix = 'ALPH1-',
            -- Optional cardIds whitelist for future sets. Catalogue rarity stays authoritative.
            godChance = 5, godTotal = 10000,
            normal = {
                { COMMON = 10000 }, { COMMON = 10000 }, { COMMON = 10000 },
                { COMMON = 6500, RARE = 3500 },
                { RARE = 7200, SUPER = 2600, ULTRA = 200 },
                { SUPER = 7200, ULTRA = 2300, SECRET = 475, GHOST = 25 }
            },
            ultraGuarantee = { ULTRA = 9500, SECRET = 475, GHOST = 25 },
            god = {
                { SUPER = 9000, ULTRA = 990, SECRET = 10 },
                { SUPER = 9000, ULTRA = 990, SECRET = 10 },
                { SUPER = 9000, ULTRA = 990, SECRET = 10 },
                { SUPER = 6500, ULTRA = 3300, SECRET = 200 },
                { SUPER = 6500, ULTRA = 3300, SECRET = 200 },
                { ULTRA = 9500, SECRET = 475, GHOST = 25 }
            }
        }
    }
}
