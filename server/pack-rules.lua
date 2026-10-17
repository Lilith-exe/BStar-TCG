-- Pure reward selection, independent of inventory, network and NUI.
BStarPackRules = {}
local rarities = { 'COMMON', 'RARE', 'SUPER', 'ULTRA', 'SECRET', 'GHOST' }
local function weighted(weights, random)
    local total = 0
    for _, rarity in ipairs(rarities) do
        local weight = weights[rarity] or 0
        assert(weight >= 0 and weight % 1 == 0, 'Invalid pack weight')
        total = total + weight
    end
    assert(total == 10000, 'Pack slot weights must total 10,000')
    local roll, accumulated = random(1, total), 0
    for _, rarity in ipairs(rarities) do
        accumulated = accumulated + (weights[rarity] or 0)
        if roll <= accumulated then return rarity end
    end
end
function BStarPackRules.roll(definition, catalogue, random)
    random = random or math.random
    local god = random(1, definition.godTotal) <= definition.godChance
    local slots, pools, rewards = god and definition.god or definition.normal, {}, {}
    assert(#slots == 6, 'A pack must contain six slots')
    local whitelist
    if definition.cardIds then
        whitelist = {}
        for _, id in ipairs(definition.cardIds) do whitelist[id] = true end
    end
    for id, card in pairs(catalogue) do
        if card.inventoryImage and card.inventoryImage ~= '' and
            (not definition.setPrefix or (card.setCode or ''):sub(1, #definition.setPrefix) == definition.setPrefix) and
            (not whitelist or whitelist[id]) then
            pools[card.rarity] = pools[card.rarity] or {}
            pools[card.rarity][#pools[card.rarity] + 1] = id
        end
    end
    for _, pool in pairs(pools) do table.sort(pool) end
    local ghosts = 0
    for slot = 1, 6 do
        local weights = not god and slot == 6 and rewards[5].rarity == 'ULTRA' and definition.ultraGuarantee or slots[slot]
        local rarity = weighted(weights, random)
        local pool = pools[rarity]
        if not pool or #pool == 0 then return nil, 'No eligible ' .. rarity .. ' cards; pack not consumed.' end
        -- Uniform selection inside the rarity, without an undocumented duplicate-card restriction.
        rewards[slot] = { cardId = pool[random(1, #pool)], rarity = rarity, slot = slot }
        if rarity == 'GHOST' then ghosts = ghosts + 1 end
    end
    assert(ghosts <= 1, 'Pack configuration permits more than one Ghost')
    return { god = god, rewards = rewards }
end
