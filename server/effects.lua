DuelEffects = DuelEffects or {}

local TEXT_TAG_PATTERNS = {
    { tag = 'on_summon', patterns = { 'on summon', 'when this card is summoned', 'when this card is summon' } },
    { tag = 'on_draw', patterns = { 'if you draw', 'when you draw', 'opponent draws this card' } },
    { tag = 'on_play', patterns = { 'when you activate', 'upon activation', 'when this card is used' } },
    { tag = 'end_phase', patterns = { 'end phase', 'during the end phase', 'each turn during the end phase' } },
    { tag = 'draw', patterns = { 'draw %d', 'draw a card', 'draw 1 card', 'draw 2 cards', 'draw 3 cards' } },
    { tag = 'search_deck', patterns = { 'from your deck', 'search your deck', 'add 1', 'add one' } },
    { tag = 'special_summon', patterns = { 'special summon', 'sp summon' } },
    { tag = 'heal', patterns = { 'heal', 'restore', 'gain %+?%d+ hp' } },
    { tag = 'gain_lp', patterns = { 'gain %+?%d+ lp', 'increase your lp' } },
    { tag = 'lose_lp', patterns = { 'lose %-?%d+ lp', 'pay %d+ lp', 'reduce your lp' } },
    { tag = 'damage_lp', patterns = { 'opponent loses', 'steal %d+ lp', 'damage to your opponent' } },
    { tag = 'destroy', patterns = { 'destroy', 'sent to the cemetery', 'send it to the cemetary', 'send it to the cemetery' } },
    { tag = 'discard', patterns = { 'discard' } },
    { tag = 'revive', patterns = { 'revive', 'from your cemetery' } },
    { tag = 'equip', patterns = { 'equip' } },
    { tag = 'stat_modifier', patterns = { 'gains %+?%d+', 'lose %d+ spd', 'loses %d+ spd' } },
    { tag = 'coin_flip', patterns = { 'flip a coin', 'if heads', 'if tails' } },
    { tag = 'dice_roll', patterns = { 'roll a', 'roll %d', 'sided dice', 'sided die' } },
    { tag = 'once_per_turn', patterns = { 'once per turn' } },
    { tag = 'once_per_game', patterns = { 'once per game' } }
}

local function addUnique(list, seen, value)
    if not value or value == '' or seen[value] then return end
    seen[value] = true
    list[#list + 1] = value
end

local function normalizeTag(tag)
    return tostring(tag or ''):lower():gsub('%s+', '_'):gsub('[^%w_]', '')
end

local function copyTags(tags, list, seen)
    if type(tags) ~= 'table' then return end

    for _, tag in ipairs(tags) do
        addUnique(list, seen, normalizeTag(tag))
    end
end

function DuelEffects.GetTags(cardDef)
    local tags = {}
    local seen = {}

    if not cardDef then return tags end

    copyTags(cardDef.effectTags, tags, seen)
    copyTags(cardDef.effectKeywords, tags, seen)

    for _, effect in ipairs(cardDef.effects or {}) do
        addUnique(tags, seen, normalizeTag(effect.trigger))
        copyTags(effect.tags, tags, seen)

        for _, action in ipairs(effect.actions or {}) do
            addUnique(tags, seen, normalizeTag(action.action or action.type))
        end

        for _, option in ipairs(effect.options or {}) do
            for _, action in ipairs(option.actions or {}) do
                addUnique(tags, seen, normalizeTag(action.action or action.type))
            end
        end
    end

    local text = tostring(cardDef.effectText or ''):lower()
    for _, descriptor in ipairs(TEXT_TAG_PATTERNS) do
        for _, pattern in ipairs(descriptor.patterns) do
            if text:find(pattern) then
                addUnique(tags, seen, descriptor.tag)
                break
            end
        end
    end

    table.sort(tags)
    return tags
end

local function getEffectList(cardDef, triggerName)
    local list = {}
    triggerName = normalizeTag(triggerName)

    if not cardDef or type(cardDef.effects) ~= 'table' then
        return list
    end

    for index, effect in ipairs(cardDef.effects) do
        if normalizeTag(effect.trigger) == triggerName then
            list[#list + 1] = {
                index = index,
                effect = effect
            }
        end
    end

    return list
end

local function getEffectByIndex(cardDef, effectIndex)
    effectIndex = tonumber(effectIndex)
    if not cardDef or type(cardDef.effects) ~= 'table' or not effectIndex then
        return nil
    end

    return cardDef.effects[effectIndex]
end

local function isOptionalEffect(cardDef, effect)
    if not effect then return false end

    if effect.optional == true or effect.prompt == true or effect.canActivate == true or effect.form or effect.options then
        return true
    end

    local text = tostring(effect.text or cardDef and cardDef.effectText or ''):lower()
    return text:find('you can', 1, true) ~= nil
end

local function getEffectPrompt(cardDef, effect)
    if effect and effect.promptText then
        return effect.promptText
    end

    local cardName = cardDef and cardDef.name or 'Card'
    local effectName = cardDef and (cardDef.effectTitle or cardDef.name) or 'this effect'
    local label = ('%s : %s'):format(tostring(cardName), tostring(effectName))
    return ('Do you want to activate %s?'):format(tostring(label))
end

local function activationZoneAllowed(effect, sourceCard)
    local zone = tostring(sourceCard and sourceCard.zone or '')
    local zones = effect and effect.activationZones or nil

    if type(zones) ~= 'table' then
        return zone == 'fighterZone'
            or zone == 'itemZone'
            or zone == 'equipmentZone'
            or zone == 'locationZone'
    end

    for _, allowedZone in ipairs(zones) do
        if tostring(allowedZone) == zone then
            return true
        end
    end

    return false
end

local function getPlayerIndex(action, sourcePlayerIndex, api)
    local target = tostring(action.target or action.player or 'self'):lower()
    if target == 'opponent' then
        return api.getOpponentIndex(sourcePlayerIndex)
    end
    return sourcePlayerIndex
end

local function findDeckCardIndex(playerState, filter, api)
    filter = filter or {}

    for i, card in ipairs(playerState.deck or {}) do
        local def = api.getCardDefinition(card.cardId)
        local typeOk = not filter.type or string.upper(tostring(def and def.type or '')) == string.upper(tostring(filter.type))
        local cardIdOk = not filter.notCardId or tostring(card.cardId) ~= tostring(filter.notCardId)
        local nameText = string.lower(tostring(def and def.name or ''))
        local jobText = string.lower(tostring(def and def.job or ''))
        local nameOk = not filter.nameContains or nameText:find(string.lower(tostring(filter.nameContains)), 1, true) ~= nil
        local jobOk = not filter.jobContains or jobText:find(string.lower(tostring(filter.jobContains)), 1, true) ~= nil
        local levelOk = true

        if filter.levelMin or filter.levelMax or filter.level then
            local level = api.getCardLevelValue(def)
            if filter.level then levelOk = level == tonumber(filter.level) end
            if filter.levelMin then levelOk = levelOk and level >= tonumber(filter.levelMin) end
            if filter.levelMax then levelOk = levelOk and level <= tonumber(filter.levelMax) end
        end

        if typeOk and cardIdOk and nameOk and jobOk and levelOk then
            return i, card
        end
    end

    return nil, nil
end

local function cardMatchesFilter(card, filter, api)
    local def = card and api.getCardDefinition(card.cardId)
    filter = filter or {}

    if not def then return false end

    local typeOk = not filter.type or string.upper(tostring(def.type or '')) == string.upper(tostring(filter.type))
    local cardIdOk = not filter.notCardId or tostring(card.cardId) ~= tostring(filter.notCardId)
    local nameText = string.lower(tostring(def.name or ''))
    local jobText = string.lower(tostring(def.job or ''))
    local nameOk = not filter.nameContains or nameText:find(string.lower(tostring(filter.nameContains)), 1, true) ~= nil
    local jobOk = not filter.jobContains or jobText:find(string.lower(tostring(filter.jobContains)), 1, true) ~= nil
    local levelOk = true

    if filter.levelMin or filter.levelMax or filter.level then
        local level = api.getCardLevelValue(def)
        if filter.level then levelOk = level == tonumber(filter.level) end
        if filter.levelMin then levelOk = levelOk and level >= tonumber(filter.levelMin) end
        if filter.levelMax then levelOk = levelOk and level <= tonumber(filter.levelMax) end
    end

    return typeOk and cardIdOk and nameOk and jobOk and levelOk
end

local function findOpenFighterZone(playerState)
    for i = 1, 3 do
        if not playerState.fighterZones[i] then
            return i
        end
    end
    return nil
end

local function appendLog(duel, message)
    duel.log = duel.log or {}
    duel.log[#duel.log + 1] = {
        turn = duel.turnNumber,
        phase = duel.phase,
        message = message
    }
end

local function getFighterZoneIndex(playerState, sourceCard)
    for i = 1, 3 do
        if playerState.fighterZones and playerState.fighterZones[i] == sourceCard then
            return i
        end
    end

    return nil
end

local function eachFighter(playerState, callback)
    for i = 1, 3 do
        local card = playerState.fighterZones and playerState.fighterZones[i] or nil
        if card then
            callback(card, i)
        end
    end
end

local function applyStatModifier(card, stat, amount, duration)
    if not card or not stat then return end

    local key = stat
    if stat == 'defense' or stat == 'health' then
        key = 'hp'
    end

    local bucketName = duration == 'turn' and 'turnStatModifiers' or 'statModifiers'
    card[bucketName] = card[bucketName] or {}
    card[bucketName][key] = (tonumber(card[bucketName][key]) or 0) + (tonumber(amount) or 0)

    if key == 'hp' then
        local value = tonumber(amount) or 0
        card.maxHp = math.max(0, (tonumber(card.maxHp) or 0) + value)
        if value > 0 then
            card.currentHp = (tonumber(card.currentHp) or 0) + value
        elseif (tonumber(card.currentHp) or 0) > (tonumber(card.maxHp) or 0) then
            card.currentHp = card.maxHp
        end
    end
end

local function resolveResponseAmount(spec, context)
    local response = context and context.event and context.event.response or {}
    local value = tonumber(response[spec.fromResponse or spec.responseKey or spec.key]) or tonumber(spec.default) or 0

    if spec.min ~= nil then
        value = math.max(tonumber(spec.min) or value, value)
    end

    if spec.max ~= nil then
        value = math.min(tonumber(spec.max) or value, value)
    end

    if spec.multiplier ~= nil then
        value = value * (tonumber(spec.multiplier) or 1)
    end

    if spec.divisor ~= nil then
        local divisor = tonumber(spec.divisor) or 1
        if divisor ~= 0 then
            value = value / divisor
        end
    end

    if spec.round == 'ceil' then
        value = math.ceil(value)
    elseif spec.round == 'round' then
        value = math.floor(value + 0.5)
    elseif spec.round == 'floor' or spec.round == nil then
        value = math.floor(value)
    end

    return value
end

local function resolveAmount(action, context)
    if type(action.amount) == 'table' and action.amount.fromResponse then
        return resolveResponseAmount(action.amount, context)
    end

    if action.amountFromResponse then
        return resolveResponseAmount({
            fromResponse = action.amountFromResponse,
            min = action.min,
            max = action.max,
            multiplier = action.multiplier,
            divisor = action.divisor,
            round = action.round
        }, context)
    end

    if type(action.amount) == 'number' then
        return action.amount
    end

    if action.amount == 'coin' then
        return math.random(1, 2) == 1 and (tonumber(action.heads) or 1) or (tonumber(action.tails) or 0)
    end

    if action.amount == 'dice' then
        local sides = tonumber(action.sides) or 6
        local multiplier = tonumber(action.multiplier) or 1
        local roll = math.random(1, sides)
        context.lastRoll = roll
        return roll * multiplier
    end

    return tonumber(action.amount) or 0
end

local ACTIONS = {}

function ACTIONS.draw(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local amount = math.max(0, resolveAmount(action, context))
    if amount <= 0 then return end

    local drawn = api.drawCards(duel, playerIndex, amount)
    appendLog(duel, ('%s drew %s card(s) from %s.'):format(playerIndex, drawn, sourceCard and sourceCard.cardId or 'an effect'))
end

function ACTIONS.gain_lp(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local amount = math.max(0, resolveAmount(action, context))
    local player = duel.players[playerIndex]
    if not player or amount <= 0 then return end

    player.lifePoints = (tonumber(player.lifePoints) or 0) + amount
    appendLog(duel, ('Player %s gained %s LP.'):format(playerIndex, amount))
end

function ACTIONS.lose_lp(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local amount = math.max(0, resolveAmount(action, context))
    local player = duel.players[playerIndex]
    if not player or amount <= 0 then return end

    player.lifePoints = math.max(0, (tonumber(player.lifePoints) or 0) - amount)
    appendLog(duel, ('Player %s lost %s LP.'):format(playerIndex, amount))
end

function ACTIONS.damage_opponent_lp(duel, sourcePlayerIndex, sourceCard, action, api, context)
    action.target = 'opponent'
    ACTIONS.lose_lp(duel, sourcePlayerIndex, sourceCard, action, api, context)
end

function ACTIONS.steal_lp(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local amount = math.max(0, resolveAmount(action, context))
    if amount <= 0 then return end

    ACTIONS.lose_lp(duel, sourcePlayerIndex, sourceCard, { target = 'opponent', amount = amount }, api, context)
    ACTIONS.gain_lp(duel, sourcePlayerIndex, sourceCard, { target = 'self', amount = amount }, api, context)
end

function ACTIONS.search_deck_to_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player then return end

    if action.choose == true and api.queueDeckSearch then
        api.queueDeckSearch(duel, sourcePlayerIndex, sourceCard, action.filter, {
            title = action.title or 'Search Deck',
            text = action.promptText or 'Choose 1 card to add to your hand.'
        })
        return
    end

    local deckIndex, card = findDeckCardIndex(player, action.filter, api)
    if not deckIndex or not card then return end

    table.remove(player.deck, deckIndex)
    card.zone = 'hand'
    player.hand[#player.hand + 1] = card
    appendLog(duel, ('Player %s added %s to hand.'):format(sourcePlayerIndex, card.cardId))
end

function ACTIONS.special_summon_from_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player then return end

    local zoneIndex = findOpenFighterZone(player)
    if not zoneIndex then return end

    local deckIndex, card = findDeckCardIndex(player, action.filter, api)
    if not deckIndex or not card then return end

    table.remove(player.deck, deckIndex)
    card.zone = 'fighterZone'
    card.controller = sourcePlayerIndex
    card.hasAttacked = false
    api.resetFighterHp(card)
    player.fighterZones[zoneIndex] = card
    appendLog(duel, ('Player %s special summoned %s.'):format(sourcePlayerIndex, card.cardId))
end

function ACTIONS.special_summon_from_deck_or_graveyard(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player then return end

    local zoneIndex = findOpenFighterZone(player)
    if not zoneIndex then return end

    local card = nil
    local deckIndex = nil

    deckIndex, card = findDeckCardIndex(player, action.filter, api)
    if deckIndex and card then
        table.remove(player.deck, deckIndex)
    else
        for i, graveCard in ipairs(player.graveyard or {}) do
            local def = api.getCardDefinition(graveCard.cardId)
            local filter = action.filter or {}
            local typeOk = not filter.type or string.upper(tostring(def and def.type or '')) == string.upper(tostring(filter.type))
            local nameText = string.lower(tostring(def and def.name or ''))
            local nameOk = not filter.nameContains or nameText:find(string.lower(tostring(filter.nameContains)), 1, true) ~= nil

            if typeOk and nameOk then
                card = table.remove(player.graveyard, i)
                break
            end
        end
    end

    if not card then return end

    card.zone = 'fighterZone'
    card.controller = sourcePlayerIndex
    card.hasAttacked = false
    api.resetFighterHp(card)
    player.fighterZones[zoneIndex] = card
    appendLog(duel, ('Player %s special summoned %s.'):format(sourcePlayerIndex, card.cardId))
end

function ACTIONS.revive_from_graveyard(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player then return end

    local zoneIndex = findOpenFighterZone(player)
    if not zoneIndex then return end

    for i, graveCard in ipairs(player.graveyard or {}) do
        if cardMatchesFilter(graveCard, action.filter or { type = 'Fighter' }, api) then
            local card = table.remove(player.graveyard, i)
            card.zone = 'fighterZone'
            card.controller = sourcePlayerIndex
            card.hasAttacked = false
            api.resetFighterHp(card)
            player.fighterZones[zoneIndex] = card
            appendLog(duel, ('Player %s revived %s.'):format(sourcePlayerIndex, card.cardId))
            return
        end
    end
end

function ACTIONS.return_self_to_hand_and_special_summon_from_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player or not sourceCard then return end

    local zoneIndex = getFighterZoneIndex(player, sourceCard)
    if not zoneIndex then return end

    local deckIndex, deckCard = findDeckCardIndex(player, action.filter, api)
    if not deckIndex or not deckCard then return end

    if api.moveEquipmentAtToGraveyard then
        api.moveEquipmentAtToGraveyard(player, zoneIndex)
    end

    player.fighterZones[zoneIndex] = nil
    sourceCard.zone = 'hand'
    sourceCard.hasAttacked = false
    sourceCard.equipmentStatModifiers = nil
    player.hand[#player.hand + 1] = sourceCard

    table.remove(player.deck, deckIndex)
    deckCard.zone = 'fighterZone'
    deckCard.controller = sourcePlayerIndex
    deckCard.hasAttacked = false
    api.resetFighterHp(deckCard)
    player.fighterZones[zoneIndex] = deckCard

    appendLog(duel, ('Player %s returned %s to hand and special summoned %s.'):format(sourcePlayerIndex, sourceCard.cardId, deckCard.cardId))
end

function ACTIONS.tribute_matching_fighter_and_special_summon_self(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player or not sourceCard then return end

    local tributeZoneIndex = nil
    for i = 1, 3 do
        local fighter = player.fighterZones and player.fighterZones[i] or nil
        if fighter and fighter ~= sourceCard and cardMatchesFilter(fighter, action.tributeFilter or {}, api) then
            tributeZoneIndex = i
            break
        end
    end

    if not tributeZoneIndex then return end

    local removed = false
    for i = #(player.hand or {}), 1, -1 do
        if player.hand[i] == sourceCard then
            table.remove(player.hand, i)
            removed = true
            break
        end
    end

    if not removed then
        for i = #(player.graveyard or {}), 1, -1 do
            if player.graveyard[i] == sourceCard then
                table.remove(player.graveyard, i)
                removed = true
                break
            end
        end
    end

    if not removed then return end

    api.moveFieldCardToGraveyard(player, tributeZoneIndex)
    sourceCard.zone = 'fighterZone'
    sourceCard.controller = sourcePlayerIndex
    sourceCard.hasAttacked = false
    api.resetFighterHp(sourceCard)
    player.fighterZones[tributeZoneIndex] = sourceCard
    appendLog(duel, ('Player %s tributed a fighter to special summon %s.'):format(sourcePlayerIndex, sourceCard.cardId))
end

function ACTIONS.equip_from_deck(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local player = duel.players[sourcePlayerIndex]
    if not player then return end

    if action.choose == true and api.queueDeckSearch then
        api.queueDeckSearch(duel, sourcePlayerIndex, sourceCard, action.filter, {
            mode = 'equip_from_deck',
            title = action.title or 'Search Deck',
            text = action.promptText or 'Choose 1 equipment card from your deck.'
        })
        return
    end

    local zoneIndex = tonumber(action.zoneIndex)
        or tonumber(context and context.event and context.event.zoneIndex)
        or getFighterZoneIndex(player, sourceCard)

    if not zoneIndex or not player.fighterZones[zoneIndex] then
        return
    end

    local deckIndex, card = findDeckCardIndex(player, action.filter, api)
    if not deckIndex or not card then return end

    local slotKey = api.getEquipmentSlotKey and api.getEquipmentSlotKey(card) or nil
    if not slotKey or (api.getEquipmentCardAt and api.getEquipmentCardAt(player, zoneIndex, slotKey)) then
        return
    end

    table.remove(player.deck, deckIndex)
    card.zone = 'equipmentZone'
    if api.setEquipmentCardAt then
        api.setEquipmentCardAt(player, zoneIndex, slotKey, card)
    else
        player.equipmentZones[zoneIndex] = card
    end
    if api.rebuildEquipmentModifiers then
        api.rebuildEquipmentModifiers(player, zoneIndex)
    end
    appendLog(duel, ('Player %s equipped %s from deck.'):format(sourcePlayerIndex, card.cardId))
end

function ACTIONS.swap_self_with_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player or not sourceCard then return end

    local zoneIndex = getFighterZoneIndex(player, sourceCard)
    if not zoneIndex then return end

    local deckIndex, deckCard = findDeckCardIndex(player, action.filter, api)
    if not deckIndex or not deckCard then return end

    table.remove(player.deck, deckIndex)
    player.fighterZones[zoneIndex] = deckCard
    deckCard.zone = 'fighterZone'
    deckCard.controller = sourcePlayerIndex
    deckCard.hasAttacked = false
    api.resetFighterHp(deckCard)

    sourceCard.zone = 'deck'
    sourceCard.controller = sourceCard.owner
    sourceCard.hasAttacked = false
    player.deck[#player.deck + 1] = sourceCard
    sourceCard.equipmentStatModifiers = nil
    if api.rebuildEquipmentModifiers then
        api.rebuildEquipmentModifiers(player, zoneIndex)
    end
    appendLog(duel, ('Player %s swapped %s for %s from deck.'):format(sourcePlayerIndex, sourceCard.cardId, deckCard.cardId))
end

function ACTIONS.modify_stats(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local statMods = action.stats or {}
    local duration = action.duration or 'permanent'

    if action.target == 'all_opponent_fighters' then
        local opponent = duel.players[api.getOpponentIndex(sourcePlayerIndex)]
        if not opponent then return end

        eachFighter(opponent, function(card)
            for stat, amount in pairs(statMods) do
                if type(amount) == 'table' then
                    amount = resolveAmount({ amount = amount }, context)
                end
                applyStatModifier(card, stat, amount, duration)
            end
        end)
        return
    end

    if action.target == 'all_self_fighters' then
        local player = duel.players[sourcePlayerIndex]
        if not player then return end

        eachFighter(player, function(card)
            for stat, amount in pairs(statMods) do
                if type(amount) == 'table' then
                    amount = resolveAmount({ amount = amount }, context)
                end
                applyStatModifier(card, stat, amount, duration)
            end
        end)
        return
    end

    for stat, amount in pairs(statMods) do
        if type(amount) == 'table' then
            amount = resolveAmount({ amount = amount }, context)
        end
        applyStatModifier(sourceCard, stat, amount, duration)
    end
end

function ACTIONS.discard_matching_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local player = duel.players[playerIndex]
    if not player then return end

    local discarded = 0
    local i = #(player.hand or {})
    while i >= 1 do
        local card = player.hand[i]
        if cardMatchesFilter(card, action.filter or {}, api) then
            api.moveHandCardToGraveyard(player, i)
            discarded = discarded + 1
        end
        i = i - 1
    end

    if discarded > 0 then
        appendLog(duel, ('Player %s discarded %s matching card(s).'):format(playerIndex, discarded))
    end
end

function ACTIONS.heal_all_fighters(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local amount = math.max(0, resolveAmount(action, context))
    local player = duel.players[playerIndex]
    if not player or amount <= 0 then return end

    for _, card in pairs(player.fighterZones or {}) do
        if card then
            api.ensureFighterHp(card)
            card.currentHp = math.min(card.maxHp or card.currentHp or 0, (card.currentHp or 0) + amount)
        end
    end
end

function ACTIONS.discard_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local player = duel.players[playerIndex]
    if not player or #(player.hand or {}) == 0 then return end

    local amount = math.min(#player.hand, tonumber(action.amount) or 1)
    for _ = 1, amount do
        local index = action.random and math.random(1, #player.hand) or 1
        api.moveHandCardToGraveyard(player, index)
    end
end

function ACTIONS.destroy_all_fighters(duel, sourcePlayerIndex, sourceCard, action, api)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local player = duel.players[playerIndex]
    if not player then return end

    for i = 1, 3 do
        if player.fighterZones[i] then
            api.moveFieldCardToGraveyard(player, i)
        end
    end
end

local function passesCondition(duel, sourcePlayerIndex, sourceCard, effect, event, api)
    local condition = effect.condition
    if type(condition) ~= 'table' then return true end

    if condition.drawnType and event and event.drawnCard then
        local def = api.getCardDefinition(event.drawnCard.cardId)
        if string.upper(tostring(def and def.type or '')) ~= string.upper(tostring(condition.drawnType)) then
            return false
        end
    end

    if condition.phase and tostring(duel.phase) ~= tostring(condition.phase) then
        return false
    end

    if condition.ownFighterCount then
        local player = duel.players[sourcePlayerIndex]
        local count = 0
        eachFighter(player or {}, function()
            count = count + 1
        end)

        if count ~= tonumber(condition.ownFighterCount) then
            return false
        end
    end

    if condition.ownFighterCountMin then
        local player = duel.players[sourcePlayerIndex]
        local count = 0
        eachFighter(player or {}, function()
            count = count + 1
        end)

        if count < tonumber(condition.ownFighterCountMin) then
            return false
        end
    end

    if condition.ownEquipmentCountMin then
        local player = duel.players[sourcePlayerIndex]
        local count = 0
        for i = 1, 3 do
            local slot = player and player.equipmentZones and player.equipmentZones[i] or nil
            if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                    if slot[key] then count = count + 1 end
                end
            elseif slot then
                count = count + 1
            end
        end

        if count < tonumber(condition.ownEquipmentCountMin) then
            return false
        end
    end

    if condition.ownControlsNameContains then
        local player = duel.players[sourcePlayerIndex]
        local found = false
        local needle = string.lower(tostring(condition.ownControlsNameContains))

        eachFighter(player or {}, function(card)
            local def = api.getCardDefinition(card.cardId)
            local nameText = string.lower(tostring(def and def.name or ''))
            local cardIdOk = not condition.ownControlsNotCardId or tostring(card.cardId) ~= tostring(condition.ownControlsNotCardId)
            if cardIdOk and nameText:find(needle, 1, true) ~= nil then
                found = true
            end
        end)

        if not found then
            return false
        end
    end

    return true
end

local function hasUsedEffect(sourceCard, effectIndex)
    if not sourceCard or not effectIndex then return false end
    return sourceCard.usedEffects and sourceCard.usedEffects[tostring(effectIndex)] == true
end

local function hasUsedEffectThisTurn(sourceCard, effectIndex, duel)
    if not sourceCard or not effectIndex or not duel then return false end
    return sourceCard.usedEffectTurns and sourceCard.usedEffectTurns[tostring(effectIndex)] == duel.turnNumber
end

local function markUsedEffect(sourceCard, effectIndex)
    if not sourceCard or not effectIndex then return end
    sourceCard.usedEffects = sourceCard.usedEffects or {}
    sourceCard.usedEffects[tostring(effectIndex)] = true
end

local function markUsedEffectThisTurn(sourceCard, effectIndex, duel)
    if not sourceCard or not effectIndex or not duel then return end
    sourceCard.usedEffectTurns = sourceCard.usedEffectTurns or {}
    sourceCard.usedEffectTurns[tostring(effectIndex)] = duel.turnNumber
end

local function runEffectActions(duel, sourcePlayerIndex, sourceCard, effect, event, api)
    local context = { event = event or {} }
    local actions = effect.actions or {}

    if type(effect.options) == 'table' then
        local selectedOption = tostring(context.event.response and context.event.response.option or '')
        actions = {}

        for _, option in ipairs(effect.options) do
            if tostring(option.id or option.value or option.key or option.label or '') == selectedOption then
                actions = option.actions or {}
                break
            end
        end
    end

    for _, action in ipairs(actions) do
        local actionName = normalizeTag(action.action or action.type)
        local handler = ACTIONS[actionName]

        if handler then
            handler(duel, sourcePlayerIndex, sourceCard, action, api, context)
        else
            appendLog(duel, ('Unhandled effect action "%s" on %s.'):format(actionName, sourceCard.cardId))
        end
    end
end

function DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, sourceCard, event, api, options)
    if not duel or not sourceCard or not api then return 0 end

    local def = api.getCardDefinition(sourceCard.cardId)
    local effects = getEffectList(def, triggerName)
    local activated = 0
    options = options or {}

    for _, entry in ipairs(effects) do
        local effect = entry.effect
        local turnKey = effect.oncePerTurnKey or entry.index
        if normalizeTag(triggerName) == 'activated' and not activationZoneAllowed(effect, sourceCard) then
            -- This activated mode belongs to another zone.
        elseif effect.oncePerGame == true and hasUsedEffect(sourceCard, entry.index) then
            appendLog(duel, ('Effect %s on %s has already been used.'):format(entry.index, sourceCard.cardId))
        elseif effect.oncePerTurn == true and hasUsedEffectThisTurn(sourceCard, turnKey, duel) then
            appendLog(duel, ('Effect %s on %s has already been used this turn.'):format(entry.index, sourceCard.cardId))
        elseif passesCondition(duel, sourcePlayerIndex, sourceCard, effect, event, api) then
            if isOptionalEffect(def, effect) and not options.force then
                if api.queueEffectPrompt then
                    local queued = api.queueEffectPrompt(duel, sourcePlayerIndex, sourceCard, triggerName, entry.index, {
                        title = def and (def.effectTitle or def.name) or 'Effect',
                        text = getEffectPrompt(def, effect),
                        effectText = def and def.effectText or nil,
                        form = effect.form
                    })
                    if queued then
                        activated = activated + 1
                    end
                end
            else
                runEffectActions(duel, sourcePlayerIndex, sourceCard, effect, event, api)
                if effect.oncePerGame == true then
                    markUsedEffect(sourceCard, entry.index)
                end
                if effect.oncePerTurn == true then
                    markUsedEffectThisTurn(sourceCard, turnKey, duel)
                end
                activated = activated + 1
            end
        end
    end

    return activated
end

function DuelEffects.RunEffectByIndex(duel, sourcePlayerIndex, sourceCard, effectIndex, event, api)
    if not duel or not sourceCard or not api then return false, 'Invalid effect source' end

    local def = api.getCardDefinition(sourceCard.cardId)
    local effect = getEffectByIndex(def, effectIndex)
    if not effect then
        return false, 'Effect not found'
    end

    if not passesCondition(duel, sourcePlayerIndex, sourceCard, effect, event, api) then
        return false, 'Effect condition not met'
    end

    if normalizeTag(effect.trigger) == 'activated' and not activationZoneAllowed(effect, sourceCard) then
        return false, 'Effect cannot be activated from this zone'
    end

    if effect.oncePerGame == true and hasUsedEffect(sourceCard, effectIndex) then
        return false, 'Effect already used'
    end

    local turnKey = effect.oncePerTurnKey or effectIndex
    if effect.oncePerTurn == true and hasUsedEffectThisTurn(sourceCard, turnKey, duel) then
        return false, 'Effect already used this turn'
    end

    runEffectActions(duel, sourcePlayerIndex, sourceCard, effect, event, api)
    if effect.oncePerGame == true then
        markUsedEffect(sourceCard, effectIndex)
    end
    if effect.oncePerTurn == true then
        markUsedEffectThisTurn(sourceCard, turnKey, duel)
    end
    return true
end

function DuelEffects.HasTrigger(cardDef, triggerName)
    return #getEffectList(cardDef, triggerName) > 0
end

function DuelEffects.RunFieldTrigger(duel, triggerName, sourcePlayerIndex, event, api)
    if not duel or not api then return 0 end

    local activated = 0
    local player = duel.players[sourcePlayerIndex]
    if not player then return 0 end

    for _, zone in ipairs({ player.fighterZones, player.itemZones }) do
        for _, card in pairs(zone or {}) do
            if card then
                activated = activated + DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, card, event, api)
            end
        end
    end

    for _, slot in pairs(player.equipmentZones or {}) do
        if slot and (slot.vehicle or slot.weapon or slot.equipment) then
            for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                local card = slot[key]
                if card then
                    activated = activated + DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, card, event, api)
                end
            end
        elseif slot then
            activated = activated + DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, slot, event, api)
        end
    end

    if player.locationZone then
        activated = activated + DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, player.locationZone, event, api)
    end

    return activated
end
