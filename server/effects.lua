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

    if effect.optional == true or effect.prompt == true or effect.canActivate == true then
        return true
    end

    local text = tostring(effect.text or cardDef and cardDef.effectText or ''):lower()
    return text:find('you can', 1, true) ~= nil
end

local function getEffectPrompt(cardDef, effect)
    if effect and effect.promptText then
        return effect.promptText
    end

    local label = cardDef and (cardDef.effectTitle or cardDef.name) or 'this effect'
    return ('Do you want to activate %s?'):format(tostring(label))
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

        if typeOk and nameOk and jobOk and levelOk then
            return i, card
        end
    end

    return nil, nil
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

local function resolveAmount(action, context)
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

    return true
end

local function runEffectActions(duel, sourcePlayerIndex, sourceCard, effect, event, api)
    local context = { event = event or {} }

    for _, action in ipairs(effect.actions or {}) do
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
        if passesCondition(duel, sourcePlayerIndex, sourceCard, effect, event, api) then
            if isOptionalEffect(def, effect) and not options.force then
                if api.queueEffectPrompt then
                    api.queueEffectPrompt(duel, sourcePlayerIndex, sourceCard, triggerName, entry.index, {
                        title = def and (def.effectTitle or def.name) or 'Effect',
                        text = getEffectPrompt(def, effect),
                        effectText = def and def.effectText or nil
                    })
                end
            else
                runEffectActions(duel, sourcePlayerIndex, sourceCard, effect, event, api)
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

    runEffectActions(duel, sourcePlayerIndex, sourceCard, effect, event, api)
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

    for _, zone in ipairs({ player.fighterZones, player.itemZones, player.equipmentZones }) do
        for _, card in pairs(zone or {}) do
            if card then
                activated = activated + DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, card, event, api)
            end
        end
    end

    if player.locationZone then
        activated = activated + DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, player.locationZone, event, api)
    end

    return activated
end
