DuelEffects = DuelEffects or {}

local TEXT_TAG_PATTERNS = {
    { tag = 'on_summon', patterns = { 'on summon', 'when this card is summoned', 'when this card is summon' } },
    { tag = 'on_draw', patterns = { 'if you draw', 'when you draw', 'opponent draws this card' } },
    { tag = 'on_play', patterns = { 'when you activate', 'upon activation', 'when this card is used' } },
    { tag = 'on_attack_declared', patterns = { 'declares an attack', 'when an opponent', 'when an opponents fighter delcares an attack' } },
    { tag = 'on_destroyed_by_battle', patterns = { 'destroyed by battle', 'killed in battle', 'destroyed in battle' } },
    { tag = 'on_sent_to_cemetery', patterns = { 'sent to the cemetery', 'sent to the cemetary' } },
    { tag = 'on_dodge', patterns = { 'dodges an attack', 'dodge an attack' } },
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

local function shallowCopy(tbl)
    local copy = {}
    for key, value in pairs(tbl or {}) do
        copy[key] = value
    end
    return copy
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

local function getEffectList(cardDef, triggerName, sourceCard)
    local list = {}
    triggerName = normalizeTag(triggerName)

    for index, effect in ipairs(cardDef and cardDef.effects or {}) do
        if normalizeTag(effect.trigger) == triggerName then
            list[#list + 1] = {
                index = index,
                effect = effect
            }
        end
    end

    for index, effect in ipairs(sourceCard and sourceCard.copiedEffects or {}) do
        if normalizeTag(effect.trigger) == triggerName then
            list[#list + 1] = {
                index = 1000 + index,
                effect = effect
            }
        end
    end

    return list
end

local function getEffectByIndex(cardDef, effectIndex, sourceCard)
    effectIndex = tonumber(effectIndex)
    if not effectIndex then
        return nil
    end

    if effectIndex >= 1000 then
        return sourceCard and sourceCard.copiedEffects and sourceCard.copiedEffects[effectIndex - 1000] or nil
    end

    return cardDef and cardDef.effects and cardDef.effects[effectIndex] or nil
end

local function isOptionalEffect(cardDef, effect)
    if not effect then return false end

    if effect.optional == false or effect.prompt == false or effect.mandatory == true then
        return false
    end

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

local function responseZoneAllowed(effect, sourceCard)
    local zone = tostring(sourceCard and sourceCard.zone or '')
    local zones = effect and effect.responseZones or effect and effect.activationZones or nil

    if type(zones) ~= 'table' then
        return zone == 'hand'
            or zone == 'fighterZone'
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

local function cardHasTag(def, wantedTag)
    local wanted = string.lower(tostring(wantedTag or ''))
    if wanted == '' then return false end

    for _, tag in ipairs(def and def.cardTags or {}) do
        if string.lower(tostring(tag)) == wanted then
            return true
        end
    end

    return false
end

local function cardTagsMatch(def, filter)
    if filter.cardTag and not cardHasTag(def, filter.cardTag) then
        return false
    end

    if type(filter.cardTagsAny) == 'table' then
        local found = false
        for _, wantedTag in ipairs(filter.cardTagsAny) do
            if cardHasTag(def, wantedTag) then
                found = true
                break
            end
        end
        if not found then return false end
    end

    return true
end

local RARITY_RANKS = {
    common = 1,
    uncommon = 2,
    rare = 3,
    super = 4,
    ['super rare'] = 4,
    ultra = 5,
    ['ultra rare'] = 5,
    secret = 6,
    ['secret rare'] = 6,
    ghost = 7,
    ['ghost rare'] = 7,
    mythic = 8,
    ['mythic rare'] = 8,
    unique = 9
}

local function getRarityRank(rarity)
    local key = string.lower(tostring(rarity or '')):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    return RARITY_RANKS[key] or 0
end

local function findDeckCardIndex(playerState, filter, api)
    filter = filter or {}

    for i, card in ipairs(playerState.deck or {}) do
        local def = api.getCardDefinition(card.cardId)
        local typeText = string.upper(tostring(def and def.type or ''))
        local typeOk = not filter.type or typeText == string.upper(tostring(filter.type))
        if typeOk and type(filter.typesAny) == 'table' then
            typeOk = false
            for _, value in ipairs(filter.typesAny) do
                if typeText == string.upper(tostring(value)) then
                    typeOk = true
                    break
                end
            end
        end
        local cardIdOk = not filter.notCardId or tostring(card.cardId) ~= tostring(filter.notCardId)
        local nameText = string.lower(tostring(def and def.name or ''))
        local jobText = string.lower(tostring(def and def.job or ''))
        local nameOk = not filter.nameContains or nameText:find(string.lower(tostring(filter.nameContains)), 1, true) ~= nil
        local jobOk = not filter.jobContains or jobText:find(string.lower(tostring(filter.jobContains)), 1, true) ~= nil

        if nameOk and type(filter.nameContainsAny) == 'table' then
            nameOk = false
            for _, value in ipairs(filter.nameContainsAny) do
                if nameText:find(string.lower(tostring(value)), 1, true) ~= nil then
                    nameOk = true
                    break
                end
            end
        end

        if jobOk and type(filter.jobContainsAny) == 'table' then
            jobOk = false
            for _, value in ipairs(filter.jobContainsAny) do
                if jobText:find(string.lower(tostring(value)), 1, true) ~= nil then
                    jobOk = true
                    break
                end
            end
        end

        local levelOk = true

        if filter.levelMin or filter.levelMax or filter.level then
            local level = api.getCardLevelValue(def)
            if filter.level then levelOk = level == tonumber(filter.level) end
            if filter.levelMin then levelOk = levelOk and level >= tonumber(filter.levelMin) end
            if filter.levelMax then levelOk = levelOk and level <= tonumber(filter.levelMax) end
        end

        local tagsOk = cardTagsMatch(def, filter)

        if typeOk and cardIdOk and nameOk and jobOk and levelOk and tagsOk then
            return i, card
        end
    end

    return nil, nil
end

local function cardMatchesFilter(card, filter, api)
    local def = card and api.getCardDefinition(card.cardId)
    filter = filter or {}

    if not def then return false end

    if filter.notUid and tostring(card.uid or '') == tostring(filter.notUid) then
        return false
    end

    local typeText = string.upper(tostring(def.type or ''))
    local typeOk = not filter.type or typeText == string.upper(tostring(filter.type))
    if typeOk and type(filter.typesAny) == 'table' then
        typeOk = false
        for _, value in ipairs(filter.typesAny) do
            if typeText == string.upper(tostring(value)) then
                typeOk = true
                break
            end
        end
    end
    local cardIdOk = not filter.notCardId or tostring(card.cardId) ~= tostring(filter.notCardId)
    local nameText = string.lower(tostring(def.name or ''))
    local jobText = string.lower(tostring(def.job or ''))
    local nameOk = not filter.nameContains or nameText:find(string.lower(tostring(filter.nameContains)), 1, true) ~= nil
    local jobOk = not filter.jobContains or jobText:find(string.lower(tostring(filter.jobContains)), 1, true) ~= nil

    if nameOk and type(filter.nameContainsAny) == 'table' then
        nameOk = false
        for _, value in ipairs(filter.nameContainsAny) do
            if nameText:find(string.lower(tostring(value)), 1, true) ~= nil then
                nameOk = true
                break
            end
        end
    end

    if jobOk and type(filter.jobContainsAny) == 'table' then
        jobOk = false
        for _, value in ipairs(filter.jobContainsAny) do
            if jobText:find(string.lower(tostring(value)), 1, true) ~= nil then
                jobOk = true
                break
            end
        end
    end

    local levelOk = true

    if filter.levelMin or filter.levelMax or filter.level then
        local level = api.getCardLevelValue(def)
        if filter.level then levelOk = level == tonumber(filter.level) end
        if filter.levelMin then levelOk = levelOk and level >= tonumber(filter.levelMin) end
        if filter.levelMax then levelOk = levelOk and level <= tonumber(filter.levelMax) end
    end

    local tagsOk = cardTagsMatch(def, filter)

    return typeOk and cardIdOk and nameOk and jobOk and levelOk and tagsOk
end

local function findOpenFighterZone(playerState)
    for i = 1, 3 do
        if not playerState.fighterZones[i] then
            return i
        end
    end
    return nil
end

local function findHandCardIndex(playerState, filter, api)
    filter = filter or {}

    for i, card in ipairs(playerState.hand or {}) do
        if cardMatchesFilter(card, filter, api) then
            return i, card
        end
    end

    return nil, nil
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

function ACTIONS.draw_until_hand_size(duel, sourcePlayerIndex, sourceCard, action, api)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local player = duel.players[playerIndex]
    if not player then return end

    local targetSize = math.max(0, tonumber(action.handSize or action.size or action.amount) or 4)
    local amount = math.max(0, targetSize - #(player.hand or {}))
    if amount > 0 then
        ACTIONS.draw(duel, sourcePlayerIndex, sourceCard, { target = playerIndex, amount = amount }, api, {})
    end
end

function ACTIONS.gain_lp(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local amount = math.max(0, resolveAmount(action, context))
    local player = duel.players[playerIndex]
    if not player or amount <= 0 then return end

    if DuelEffects and DuelEffects.RunReplacement then
        local event = {
            reason = action.reason or 'effect',
            amount = amount,
            targetPlayerIndex = playerIndex,
            gainingPlayer = playerIndex,
            sourceUid = sourceCard and sourceCard.uid or nil,
            sourceCardId = sourceCard and sourceCard.cardId or nil
        }
        DuelEffects.RunReplacement(duel, 'would_gain_lp', playerIndex, event, api)
        if event.lpGainReplaced == true or event.replacementPrevented == true then
            return
        end
        amount = math.max(0, tonumber(event.amount) or amount)
    end

    player.lifePoints = (tonumber(player.lifePoints) or 0) + amount
    appendLog(duel, ('Player %s gained %s LP.'):format(playerIndex, amount))
end

function ACTIONS.gain_lp_per_matching_card(duel, sourcePlayerIndex, sourceCard, action, api)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local player = duel.players[playerIndex]
    if not player then return end

    local zones = action.zones or { 'hand', 'graveyard', 'field' }
    local filter = action.filter or {}
    local count = 0

    local function countIfMatch(card)
        if card and cardMatchesFilter(card, filter, api) then
            count = count + 1
        end
    end

    for _, zone in ipairs(zones) do
        zone = tostring(zone)
        if zone == 'hand' then
            for _, card in ipairs(player.hand or {}) do countIfMatch(card) end
        elseif zone == 'graveyard' or zone == 'cemetery' then
            for _, card in ipairs(player.graveyard or {}) do countIfMatch(card) end
        elseif zone == 'field' then
            for i = 1, 3 do countIfMatch(player.fighterZones and player.fighterZones[i] or nil) end
            for i = 1, 4 do countIfMatch(player.itemZones and player.itemZones[i] or nil) end
            countIfMatch(player.locationZone)
            for _, slot in pairs(player.equipmentZones or {}) do
                if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                    for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                        countIfMatch(slot[key])
                    end
                else
                    countIfMatch(slot)
                end
            end
        elseif zone == 'locationZone' then
            countIfMatch(player.locationZone)
        end
    end

    local amount = count * (tonumber(action.amountPerCard or action.amount or 0) or 0)
    if amount <= 0 then return end

    player.lifePoints = (tonumber(player.lifePoints) or 0) + amount
    appendLog(duel, ('Player %s gained %s LP from %s matching card(s).'):format(playerIndex, amount, count))
end

function ACTIONS.lose_lp(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local amount = math.max(0, resolveAmount(action, context))
    local player = duel.players[playerIndex]
    if not player or amount <= 0 then return end

    if DuelEffects and DuelEffects.RunReplacement then
        local event = {
            reason = action.reason or 'effect',
            amount = amount,
            targetPlayerIndex = playerIndex,
            losingPlayer = playerIndex,
            sourceUid = sourceCard and sourceCard.uid or nil,
            sourceCardId = sourceCard and sourceCard.cardId or nil
        }
        DuelEffects.RunReplacement(duel, 'would_lose_lp', playerIndex, event, api)
        if event.lpLossReplaced == true or event.replacementPrevented == true then
            return
        end
        amount = math.max(0, tonumber(event.amount) or amount)
    end

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

function ACTIONS.halve_lp_loss(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not context or not context.event then return end
    local amount = math.max(0, tonumber(context.event.amount) or 0)
    context.event.amount = math.floor(amount / 2)
    appendLog(duel, ('%s halved LP damage.'):format(sourceCard and sourceCard.cardId or 'An effect'))
end

function ACTIONS.roll_lucky_wheel(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local paid = tonumber(context and context.event and context.event.response and context.event.response.amount) or tonumber(action.amount) or 0
    local roll = math.random(1, tonumber(action.sides) or 6)
    appendLog(duel, ('%s rolled %s on Casino Lucky Wheel.'):format(sourceCard and sourceCard.cardId or 'An effect', roll))

    if roll >= 5 then
        ACTIONS.gain_lp(duel, sourcePlayerIndex, sourceCard, { target = 'self', amount = paid * 2 }, api, context)
    elseif roll >= 3 then
        ACTIONS.gain_lp(duel, sourcePlayerIndex, sourceCard, { target = 'self', amount = paid }, api, context)
    end
end

function ACTIONS.roll_gain_lp(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local sides = tonumber(action.sides) or 100
    local threshold = tonumber(action.threshold) or sides
    local amount = tonumber(action.gain or action.amount) or 0
    local roll = math.random(1, sides)
    appendLog(duel, ('%s rolled %s.'):format(sourceCard and sourceCard.cardId or 'An effect', roll))

    if roll >= threshold and amount > 0 then
        ACTIONS.gain_lp(duel, sourcePlayerIndex, sourceCard, { target = action.target or 'self', amount = amount }, api, context)
    end
end

function ACTIONS.pay_half_lp(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local player = duel.players[playerIndex]
    if not player then return end
    local amount = math.floor((tonumber(player.lifePoints) or 0) / 2)
    if amount > 0 then
        ACTIONS.lose_lp(duel, sourcePlayerIndex, sourceCard, { target = action.target or 'self', amount = amount }, api, context)
    end
end

function ACTIONS.switch_self_attack_hp(duel, sourcePlayerIndex, sourceCard, action, api)
    if not sourceCard or not api.ensureFighterHp then return end

    api.ensureFighterHp(sourceCard)
    local attack = api.getCardStat and api.getCardStat(sourceCard, 'attack') or 0
    local hp = tonumber(sourceCard.maxHp) or 0

    sourceCard.statModifiers = sourceCard.statModifiers or {}
    sourceCard.statModifiers.attack = (tonumber(sourceCard.statModifiers.attack) or 0) + (hp - attack)
    sourceCard.statModifiers.hp = (tonumber(sourceCard.statModifiers.hp) or 0) + (attack - hp)
    sourceCard.maxHp = math.max(0, attack)
    sourceCard.currentHp = math.min(sourceCard.currentHp or sourceCard.maxHp, sourceCard.maxHp)
end

function ACTIONS.damage_opponent_equal_attacker_attack(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local attackerUid = context and context.event and context.event.attackerUid
    local attackerCard = attackerUid and api.findCardByUid and api.findCardByUid(duel, attackerUid) or nil
    local amount = attackerCard and api.getCardStat and api.getCardStat(attackerCard, 'attack') or 0
    if amount > 0 then
        ACTIONS.damage_opponent_lp(duel, sourcePlayerIndex, sourceCard, { amount = amount }, api, context)
    end
end

function ACTIONS.set_attack_to_half_lp_difference(duel, sourcePlayerIndex, sourceCard, action, api)
    if not sourceCard or not api.getCardStat then return end
    local player = duel.players[sourcePlayerIndex]
    local opponent = duel.players[api.getOpponentIndex(sourcePlayerIndex)]
    if not player or not opponent then return end

    local difference = (tonumber(opponent.lifePoints) or 0) - (tonumber(player.lifePoints) or 0)
    if difference <= 0 then return end

    local desiredAttack = math.ceil(difference / 2)
    local currentAttack = api.getCardStat(sourceCard, 'attack')
    applyStatModifier(sourceCard, 'attack', desiredAttack - currentAttack, action.duration or 'turn')
    appendLog(duel, ('%s attack became %s from LP difference.'):format(sourceCard.cardId, desiredAttack))
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
    if api.triggerSummonResponseWindow then
        api.triggerSummonResponseWindow(duel, sourcePlayerIndex, card, {
            zoneIndex = zoneIndex,
            summonType = 'special',
            summoningPlayer = sourcePlayerIndex
        })
    end
end

function ACTIONS.special_summon_from_hand_or_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player then return end

    local zoneIndex = findOpenFighterZone(player)
    if not zoneIndex then return end

    local card = nil
    local handIndex = nil
    local deckIndex = nil

    handIndex, card = findHandCardIndex(player, action.filter, api)
    if handIndex and card then
        table.remove(player.hand, handIndex)
    else
        deckIndex, card = findDeckCardIndex(player, action.filter, api)
        if deckIndex and card then
            table.remove(player.deck, deckIndex)
        end
    end

    if not card then return end

    card.zone = 'fighterZone'
    card.controller = sourcePlayerIndex
    card.hasAttacked = false
    api.resetFighterHp(card)
    player.fighterZones[zoneIndex] = card
    appendLog(duel, ('Player %s special summoned %s.'):format(sourcePlayerIndex, card.cardId))
    if api.triggerSummonResponseWindow then
        api.triggerSummonResponseWindow(duel, sourcePlayerIndex, card, {
            zoneIndex = zoneIndex,
            summonType = 'special',
            summoningPlayer = sourcePlayerIndex
        })
    end
end

function ACTIONS.special_summon_from_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player then return end

    local zoneIndex = findOpenFighterZone(player)
    if not zoneIndex then return end

    local handIndex, card = findHandCardIndex(player, action.filter, api)
    if not handIndex or not card then return end

    table.remove(player.hand, handIndex)
    card.zone = 'fighterZone'
    card.controller = sourcePlayerIndex
    card.hasAttacked = false
    api.resetFighterHp(card)
    player.fighterZones[zoneIndex] = card
    appendLog(duel, ('Player %s special summoned %s from hand.'):format(sourcePlayerIndex, card.cardId))
    if api.triggerSummonResponseWindow then
        api.triggerSummonResponseWindow(duel, sourcePlayerIndex, card, {
            zoneIndex = zoneIndex,
            summonType = 'special',
            summoningPlayer = sourcePlayerIndex
        })
    end
end

function ACTIONS.special_summon_self_from_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player or not sourceCard then return end

    local zoneIndex = findOpenFighterZone(player)
    if not zoneIndex then return end

    for i = #(player.hand or {}), 1, -1 do
        if player.hand[i] == sourceCard then
            table.remove(player.hand, i)
            sourceCard.zone = 'fighterZone'
            sourceCard.controller = sourcePlayerIndex
            sourceCard.hasAttacked = false
            api.resetFighterHp(sourceCard)
            player.fighterZones[zoneIndex] = sourceCard
            appendLog(duel, ('Player %s special summoned %s from hand.'):format(sourcePlayerIndex, sourceCard.cardId))
            if api.triggerSummonResponseWindow then
                api.triggerSummonResponseWindow(duel, sourcePlayerIndex, sourceCard, {
                    zoneIndex = zoneIndex,
                    summonType = 'special',
                    summoningPlayer = sourcePlayerIndex
                })
            end
            return
        end
    end
end

function ACTIONS.special_summon_self_from_graveyard(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player or not sourceCard then return end

    local zoneIndex = findOpenFighterZone(player)
    if not zoneIndex then return end

    for i = #(player.graveyard or {}), 1, -1 do
        if player.graveyard[i] == sourceCard or tostring(player.graveyard[i].uid or '') == tostring(sourceCard.uid or '') then
            table.remove(player.graveyard, i)
            sourceCard.zone = 'fighterZone'
            sourceCard.controller = sourcePlayerIndex
            sourceCard.hasAttacked = false
            sourceCard.attacksThisTurn = 0
            api.resetFighterHp(sourceCard)
            player.fighterZones[zoneIndex] = sourceCard
            appendLog(duel, ('Player %s special summoned %s from the cemetery.'):format(sourcePlayerIndex, sourceCard.cardId))
            if api.triggerSummonResponseWindow then
                api.triggerSummonResponseWindow(duel, sourcePlayerIndex, sourceCard, {
                    zoneIndex = zoneIndex,
                    summonType = 'special',
                    specialSummon = true,
                    summoningPlayer = sourcePlayerIndex
                })
            end
            return
        end
    end
end

function ACTIONS.discard_named_hand_cards_and_special_summon_self(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player or not sourceCard then return end

    local zoneIndex = findOpenFighterZone(player)
    if not zoneIndex then
        appendLog(duel, ('Player %s has no open fighter zone for %s.'):format(sourcePlayerIndex, sourceCard.cardId))
        return
    end

    local requiredNames = action.requiredNames or {}
    local matchedIndexes = {}
    local usedIndexes = {}

    for _, requiredName in ipairs(requiredNames) do
        local wanted = string.lower(tostring(requiredName or ''))
        local foundIndex = nil
        for index, card in ipairs(player.hand or {}) do
            if not usedIndexes[index] and card ~= sourceCard then
                local def = api.getCardDefinition(card.cardId)
                local nameText = string.lower(tostring(def and def.name or ''))
                if nameText == wanted then
                    foundIndex = index
                    break
                end
            end
        end

        if not foundIndex then
            appendLog(duel, ('%s cannot summon: missing %s.'):format(sourceCard.cardId, requiredName))
            return
        end

        usedIndexes[foundIndex] = true
        matchedIndexes[#matchedIndexes + 1] = foundIndex
    end

    table.sort(matchedIndexes, function(a, b) return a > b end)
    for _, handIndex in ipairs(matchedIndexes) do
        api.moveHandCardToGraveyard(player, handIndex, duel, {
            reason = 'summon_cost',
            sourceUid = sourceCard.uid,
            sourceCardId = sourceCard.cardId
        })
    end

    for index = #(player.hand or {}), 1, -1 do
        if player.hand[index] == sourceCard or tostring(player.hand[index].uid or '') == tostring(sourceCard.uid or '') then
            table.remove(player.hand, index)
            sourceCard.zone = 'fighterZone'
            sourceCard.controller = sourcePlayerIndex
            sourceCard.hasAttacked = false
            sourceCard.attacksThisTurn = 0
            api.resetFighterHp(sourceCard)
            player.fighterZones[zoneIndex] = sourceCard
            appendLog(duel, ('Player %s special summoned %s with named hand costs.'):format(sourcePlayerIndex, sourceCard.cardId))
            if api.triggerSummonResponseWindow then
                api.triggerSummonResponseWindow(duel, sourcePlayerIndex, sourceCard, {
                    zoneIndex = zoneIndex,
                    summonType = 'special',
                    specialSummon = true,
                    summoningPlayer = sourcePlayerIndex
                })
            end
            return
        end
    end
end

function ACTIONS.tribute_opponent_fighters_for_bunny_and_special_summon_self(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    local opponentIndex = api.getOpponentIndex(sourcePlayerIndex)
    local opponent = duel.players[opponentIndex]
    if not player or not opponent or not sourceCard then return end

    for zoneIndex = 1, 3 do
        if opponent.fighterZones and opponent.fighterZones[zoneIndex] then
            api.moveFieldCardToGraveyard(opponent, zoneIndex, {
                duel = duel,
                reason = 'tribute',
                skipReplacement = true,
                sourceUid = sourceCard.uid,
                sourceCardId = sourceCard.cardId
            })
        end
    end

    duel.tokenCounter = (duel.tokenCounter or 0) + 1
    local token = {
        uid = ('%s_TOKEN_BUNNY_%s'):format(opponentIndex, duel.tokenCounter),
        cardId = action.tokenCardId or 'TOKEN_BUNNY',
        owner = opponentIndex,
        controller = opponentIndex,
        zone = 'fighterZone',
        token = true,
        hasAttacked = false,
        attacksThisTurn = 0
    }
    api.resetFighterHp(token)
    opponent.fighterZones[1] = token

    local zoneIndex = findOpenFighterZone(player)
    if not zoneIndex then
        appendLog(duel, ('Kenchie resolved but player %s had no open fighter zone.'):format(sourcePlayerIndex))
        return
    end

    for handIndex = #(player.hand or {}), 1, -1 do
        if player.hand[handIndex] == sourceCard or tostring(player.hand[handIndex].uid or '') == tostring(sourceCard.uid or '') then
            table.remove(player.hand, handIndex)
            sourceCard.zone = 'fighterZone'
            sourceCard.controller = sourcePlayerIndex
            sourceCard.hasAttacked = false
            sourceCard.attacksThisTurn = 0
            api.resetFighterHp(sourceCard)
            player.fighterZones[zoneIndex] = sourceCard
            appendLog(duel, ('Player %s summoned Kenchie after replacing opponent fighters with a Bunny Token.'):format(sourcePlayerIndex))
            if api.triggerSummonResponseWindow then
                api.triggerSummonResponseWindow(duel, sourcePlayerIndex, sourceCard, {
                    zoneIndex = zoneIndex,
                    summonType = 'special',
                    specialSummon = true,
                    summoningPlayer = sourcePlayerIndex
                })
            end
            return
        end
    end
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
    if api.triggerSummonResponseWindow then
        api.triggerSummonResponseWindow(duel, sourcePlayerIndex, card, {
            zoneIndex = zoneIndex,
            summonType = 'special',
            summoningPlayer = sourcePlayerIndex
        })
    end
end

function ACTIONS.promote_self_from_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player or not sourceCard then return end

    local zoneIndex = getFighterZoneIndex(player, sourceCard)
    if not zoneIndex then return end

    local filter = action.filter or {}
    local deckIndex, promotionCard = findDeckCardIndex(player, filter, api)
    if not deckIndex or not promotionCard then return end

    table.remove(player.deck, deckIndex)

    player.fighterZones[zoneIndex] = nil
    sourceCard.zone = 'graveyard'
    sourceCard.hasAttacked = false
    sourceCard.continuousStatModifiers = nil
    sourceCard.equipmentStatModifiers = nil
    player.graveyard[#player.graveyard + 1] = sourceCard

    promotionCard.zone = 'fighterZone'
    promotionCard.controller = sourcePlayerIndex
    promotionCard.hasAttacked = false
    api.resetFighterHp(promotionCard)
    player.fighterZones[zoneIndex] = promotionCard

    if api.rebuildEquipmentModifiers then
        api.rebuildEquipmentModifiers(player, zoneIndex)
    end

    appendLog(duel, ('Player %s promoted %s into %s from deck.'):format(sourcePlayerIndex, sourceCard.cardId, promotionCard.cardId))
    if api.triggerSummonResponseWindow then
        api.triggerSummonResponseWindow(duel, sourcePlayerIndex, promotionCard, {
            zoneIndex = zoneIndex,
            summonType = 'promotion',
            summoningPlayer = sourcePlayerIndex
        })
    end
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
            if api.triggerSummonResponseWindow then
                api.triggerSummonResponseWindow(duel, sourcePlayerIndex, card, {
                    zoneIndex = zoneIndex,
                    summonType = 'special',
                    summoningPlayer = sourcePlayerIndex
                })
            end
            return
        end
    end
end

function ACTIONS.select_destroy_field_card(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.target or 'opponent',
        zone = action.zone or 'field',
        mode = 'destroy_selected_field_card',
        filter = action.filter or {},
        title = action.title or 'Choose Card',
        text = action.promptText or 'Choose 1 card to send to the cemetery.',
        emptyMessage = action.emptyMessage or 'No valid cards can be destroyed.'
    })
end

function ACTIONS.select_revive_from_graveyard(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = 'self',
        zone = 'graveyard',
        mode = 'revive_selected_graveyard_fighter',
        filter = action.filter or { type = 'Fighter' },
        title = action.title or 'Choose Fighter',
        text = action.promptText or 'Choose 1 fighter from your cemetery to revive.',
        emptyMessage = action.emptyMessage or 'No valid fighters in your cemetery.'
    })
end

function ACTIONS.select_graveyard_to_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = 'self',
        zone = 'graveyard',
        mode = 'move_selected_graveyard_to_deck',
        filter = action.filter or {},
        minChoices = action.minChoices or action.min or 0,
        maxChoices = action.maxChoices or action.max or 1,
        payload = {
            thenDraw = action.thenDraw or action.draw or 0,
            shuffle = action.shuffle ~= false
        },
        title = action.title or 'Choose Cemetery Cards',
        text = action.promptText or 'Choose cards from your cemetery.',
        emptyMessage = action.emptyMessage or 'No valid cards in your cemetery.'
    })
end

function ACTIONS.select_graveyard_to_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = 'graveyard',
        mode = 'move_selected_graveyard_to_hand',
        filter = action.filter or {},
        minChoices = action.minChoices or action.min or 1,
        maxChoices = action.maxChoices or action.max or 1,
        title = action.title or 'Choose Cemetery Card',
        text = action.promptText or 'Choose a card from the cemetery to add to hand.',
        emptyMessage = action.emptyMessage or 'No valid cards in the cemetery.'
    })
end

function ACTIONS.select_copy_graveyard_fighter_effects(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or 'self',
        zone = 'graveyard',
        mode = 'copy_selected_graveyard_effects',
        filter = action.filter or { type = 'Fighter' },
        title = action.title or 'Choose Fighter',
        text = action.promptText or 'Choose 1 fighter from your cemetery to copy its effects this turn.',
        emptyMessage = action.emptyMessage or 'No valid fighters in your cemetery.'
    })
end

function ACTIONS.select_graveyard_split_deck_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = 'self',
        zone = 'graveyard',
        mode = 'split_selected_graveyard_to_deck_and_hand',
        filter = action.filter or {},
        minChoices = action.minChoices or action.min or 2,
        maxChoices = action.maxChoices or action.max or 2,
        payload = {
            shuffle = action.shuffle ~= false
        },
        title = action.title or 'Choose Cemetery Cards',
        text = action.promptText or 'Choose 2 cards. The first selected is shuffled into the deck; the second is added to your hand.',
        emptyMessage = action.emptyMessage or 'No valid cards in your cemetery.'
    })
end

function ACTIONS.select_apply_status(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.target or 'opponent',
        zone = action.zone or 'fighterZones',
        mode = 'apply_status_to_selected_card',
        filter = action.filter or { type = 'Fighter' },
        payload = {
            statuses = action.statuses or {
                {
                    id = action.status or action.statusId or action.name or 'status',
                    name = action.name or action.status or action.statusId or 'Status',
                    turns = action.turns,
                    timing = action.timing or 'end_turn',
                    amount = action.amount
                }
            }
        },
        title = action.title or 'Choose Card',
        text = action.promptText or 'Choose 1 card.',
        emptyMessage = action.emptyMessage or 'No valid targets found.'
    })
end

function ACTIONS.select_modify_stats(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    local filter = action.filter or { type = 'Fighter' }
    if filter.notSourceUid == true and sourceCard and sourceCard.uid then
        local expandedFilter = {}
        for key, value in pairs(filter) do
            expandedFilter[key] = value
        end
        expandedFilter.notSourceUid = nil
        expandedFilter.notUid = sourceCard.uid
        filter = expandedFilter
    end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = action.zone or 'fighterZones',
        mode = 'modify_selected_card_stats',
        filter = filter,
        payload = {
            stats = action.stats or {},
            duration = action.duration or 'permanent',
            durationTurns = action.durationTurns,
            durationTiming = action.durationTiming,
            durationLabel = action.durationLabel
        },
        title = action.title or 'Choose Fighter',
        text = action.promptText or 'Choose 1 fighter.',
        emptyMessage = action.emptyMessage or 'No valid fighters found.'
    })
end

function ACTIONS.select_set_stats(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = action.zone or 'fighterZones',
        mode = 'set_selected_card_stats',
        filter = action.filter or { type = 'Fighter' },
        payload = {
            stats = action.stats or {},
            duration = action.duration or 'permanent'
        },
        title = action.title or 'Choose Fighter',
        text = action.promptText or 'Choose 1 fighter.',
        emptyMessage = action.emptyMessage or 'No valid fighters found.'
    })
end

function ACTIONS.select_attach_self_to_fighter(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end
    if sourceCard and action.forceEquipmentSlot then
        sourceCard.forcedEquipmentSlot = action.forceEquipmentSlot
    end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = action.zone or 'fighterZones',
        mode = 'attach_source_to_selected_fighter',
        filter = action.filter or { type = 'Fighter' },
        payload = {
            sourceUid = sourceCard and sourceCard.uid or nil,
            triggerOnPlay = action.triggerOnPlay == true,
            equippedByEffect = action.equippedByEffect ~= false,
            forcedEquipmentSlot = action.forceEquipmentSlot
        },
        title = action.title or 'Choose Fighter',
        text = action.promptText or 'Choose 1 fighter to equip this card to.',
        emptyMessage = action.emptyMessage or 'No valid fighters found.'
    })
end

function ACTIONS.select_take_control_equipment(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'opponent',
        zone = action.zone or 'field',
        mode = 'take_control_selected_equipment',
        filter = action.filter or { type = 'Vehicle' },
        payload = {
            sourceUid = sourceCard and sourceCard.uid or nil,
            allowReclaim = action.allowReclaim ~= false,
            chooseFighterTitle = action.chooseFighterTitle or 'Choose Fighter',
            chooseFighterText = action.chooseFighterText or 'Choose a fighter to equip the stolen equipment to.'
        },
        title = action.title or 'Choose Equipment',
        text = action.promptText or 'Choose 1 equipment card to take control of.',
        emptyMessage = action.emptyMessage or 'No valid equipment found.'
    })
end

function ACTIONS.select_take_control_field_cards(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = 'opponent',
        zone = 'field',
        mode = 'take_control_selected_cards',
        filter = action.filter or { typesAny = { 'Item', 'Weapon', 'Vehicle' } },
        minChoices = action.minChoices or 1,
        maxChoices = action.maxChoices or action.amount or 2,
        title = action.title or 'Choose Cards',
        text = action.promptText or 'Choose up to 2 opponent Item, Weapon, or Vehicle cards to take control of.',
        emptyMessage = action.emptyMessage or 'No valid opponent cards found.'
    })
end

function ACTIONS.select_move_equipment_to_fighter(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = action.zone or 'field',
        mode = 'move_equipment_select_equipment',
        filter = action.filter or { typesAny = { 'Vehicle', 'Weapon', 'Equipment' } },
        payload = {
            fighterOwner = action.fighterOwner or 'self',
            triggerOnPlay = action.triggerOnPlay == true
        },
        title = action.title or 'Choose Equipment',
        text = action.promptText or 'Choose 1 equipment card to move.',
        emptyMessage = action.emptyMessage or 'No valid equipment found.'
    })
end

function ACTIONS.select_heal_fighter(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = action.zone or 'fighterZones',
        mode = 'heal_selected_fighter',
        filter = action.filter or { type = 'Fighter' },
        payload = {
            amount = action.amount or 0,
            toBase = action.toBase == true,
            removeStatus = action.removeStatus,
            removeStatusOnCoin = action.removeStatusOnCoin,
            removeStatusCoinResult = action.removeStatusCoinResult or 'tails'
        },
        title = action.title or 'Choose Fighter',
        text = action.promptText or 'Choose 1 fighter to heal.',
        emptyMessage = action.emptyMessage or 'No valid fighters found.'
    })
end

function ACTIONS.select_banish_field_card(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'opponent',
        zone = action.zone or 'field',
        mode = 'banish_selected_field_card',
        filter = action.filter or {},
        title = action.title or 'Choose Card',
        text = action.promptText or 'Choose 1 card to remove from play.',
        emptyMessage = action.emptyMessage or 'No valid cards found.'
    })
end

function ACTIONS.select_discard_hand_branch(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = 'self',
        zone = 'hand',
        mode = 'discard_hand_branch',
        filter = action.filter or {},
        payload = {
            branches = action.branches or {},
            defaultActions = action.defaultActions or {}
        },
        title = action.title or 'Choose Discard',
        text = action.promptText or 'Choose 1 card to discard.',
        emptyMessage = action.emptyMessage or 'No cards available to discard.'
    })
end

function ACTIONS.select_send_matching_to_graveyard(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = action.zone or 'hand_and_field',
        mode = 'send_selected_to_graveyard',
        filter = action.filter or {},
        minChoices = action.minChoices or action.min or 1,
        maxChoices = action.maxChoices or action.max or 1,
        payload = {
            thenDrawPerCard = action.thenDrawPerCard,
            thenDraw = action.thenDraw or action.draw,
            reason = action.reason
        },
        title = action.title or 'Choose Card',
        text = action.promptText or 'Choose 1 card to send to the cemetery.',
        emptyMessage = action.emptyMessage or 'No valid cards found.'
    })
end

function ACTIONS.select_return_field_to_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = action.zone or 'field',
        mode = 'return_selected_field_to_hand',
        filter = action.filter or {},
        minChoices = action.minChoices or action.min or 1,
        maxChoices = action.maxChoices or action.max or 1,
        payload = {
            thenActions = action.thenActions
        },
        title = action.title or 'Choose Card',
        text = action.promptText or 'Choose 1 card to return to hand.',
        emptyMessage = action.emptyMessage or 'No valid cards found.'
    })
end

function ACTIONS.select_hand_to_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = 'self',
        zone = 'hand',
        mode = 'move_selected_hand_to_deck',
        filter = action.filter or {},
        minChoices = action.minChoices or action.min or 1,
        maxChoices = action.maxChoices or action.max or 99,
        payload = {
            thenDrawPerCard = action.thenDrawPerCard,
            shuffle = action.shuffle ~= false,
            reason = action.reason
        },
        title = action.title or 'Choose Hand Cards',
        text = action.promptText or 'Choose cards from your hand to shuffle into the deck.',
        emptyMessage = action.emptyMessage or 'No valid cards in hand.'
    })
end

function ACTIONS.select_reorder_top_deck_then_draw(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = 'self',
        zone = 'deck_top',
        mode = 'reorder_top_deck_then_draw',
        filter = { count = action.count or 3 },
        minChoices = action.count or 3,
        maxChoices = action.count or 3,
        payload = {
            count = action.count or 3,
            thenDraw = action.thenDraw or 1
        },
        title = action.title or 'Expedition Map',
        text = action.promptText or 'Select the top 3 cards in the order you want them placed back, then draw 1.',
        emptyMessage = action.emptyMessage or 'Your deck has no cards to inspect.'
    })
end

function ACTIONS.select_swap_fighter_same_name_from_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = 'fighterZones',
        mode = 'swap_selected_fighter_same_name_from_deck',
        filter = action.filter or { type = 'Fighter' },
        title = action.title or 'Choose Fighter',
        text = action.promptText or 'Choose 1 fighter to return to hand and replace from deck.',
        emptyMessage = action.emptyMessage or 'No valid fighters found.'
    })
end

function ACTIONS.select_special_summon_same_name_from_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = 'fighterZones',
        mode = 'special_summon_same_name_from_deck',
        filter = action.filter or { type = 'Fighter' },
        title = action.title or 'Choose Fighter',
        text = action.promptText or 'Choose 1 fighter to copy from deck.',
        emptyMessage = action.emptyMessage or 'No valid fighters found.'
    })
end

function ACTIONS.select_modify_equipment_bonus(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.queueCardSelection then return end

    api.queueCardSelection(duel, sourcePlayerIndex, sourceCard, {
        owner = action.owner or action.targetOwner or action.target or 'self',
        zone = action.zone or 'field',
        mode = 'modify_selected_equipment_bonus',
        filter = action.filter or { typesAny = { 'Vehicle', 'Weapon', 'Equipment' } },
        payload = {
            stat = action.stat or 'speed',
            amount = action.amount,
            multiplier = action.multiplier,
            setTo = action.setTo,
            minValue = action.minValue,
            duration = action.duration
        },
        title = action.title or 'Choose Equipment',
        text = action.promptText or 'Choose 1 equipment card.',
        emptyMessage = action.emptyMessage or 'No valid equipment found.'
    })
end

function ACTIONS.modify_equipment_bonus(duel, sourcePlayerIndex, sourceCard, action, api)
    if not sourceCard or not api.modifyEquipmentBonus then return end
    api.modifyEquipmentBonus(duel, sourceCard, action.stat or 'speed', {
        amount = action.amount,
        multiplier = action.multiplier,
        setTo = action.setTo,
        minValue = action.minValue,
        duration = action.duration
    })
end

function ACTIONS.heal_equipped_fighter(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    local zoneIndex = tonumber(sourceCard and sourceCard.equippedToZoneIndex)
    local fighter = zoneIndex and player and player.fighterZones and player.fighterZones[zoneIndex] or nil
    if not fighter then return end

    api.ensureFighterHp(fighter)
    local amount = math.max(0, tonumber(action.amount) or 0)
    fighter.currentHp = math.min(tonumber(fighter.maxHp) or fighter.currentHp or 0, (tonumber(fighter.currentHp) or 0) + amount)
end

function ACTIONS.roll_destroy_self_damage_equipped(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local roll = math.random(1, tonumber(action.sides) or 6)
    context.lastRoll = roll
    local hits = action.hitValues or { 1, 6 }
    local hit = false
    for _, value in ipairs(hits) do
        if roll == tonumber(value) then
            hit = true
            break
        end
    end
    appendLog(duel, ('%s rolled %s.'):format(sourceCard and sourceCard.cardId or 'An effect', roll))
    if not hit then return end

    local player = duel.players[sourcePlayerIndex]
    local zoneIndex = tonumber(sourceCard and sourceCard.equippedToZoneIndex)
    local fighter = zoneIndex and player and player.fighterZones and player.fighterZones[zoneIndex] or nil
    if fighter then
        api.ensureFighterHp(fighter)
        fighter.currentHp = math.max(0, (tonumber(fighter.currentHp) or 0) - (tonumber(action.damage) or 20))
    end
    if sourceCard and api.moveCardByUidToGraveyard then
        api.moveCardByUidToGraveyard(duel, sourceCard.uid, {
            reason = action.reason or 'card_effect',
            sourceUid = sourceCard.uid,
            sourceCardId = sourceCard.cardId
        })
    end
end

function ACTIONS.reveal_random_opponent_hand_card(duel, sourcePlayerIndex, sourceCard, action, api)
    local opponentIndex = api.getOpponentIndex(sourcePlayerIndex)
    local opponent = duel.players[opponentIndex]
    local player = duel.players[sourcePlayerIndex]
    if not opponent or not player or #(opponent.hand or {}) == 0 then return end

    local card = opponent.hand[math.random(1, #opponent.hand)]
    local def = card and api.getCardDefinition(card.cardId)
    local message = ('Revealed %s from your opponent hand.'):format(def and def.name or card.cardId)
    TriggerClientEvent('bstar_cards:client:DuelMessageModal', player.source, {
        title = action.title or 'Revealed Card',
        text = message,
        confirmText = 'Okay'
    })
    appendLog(duel, message)
end

function ACTIONS.reveal_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local player = duel.players[playerIndex]
    if not player then return end

    local names = {}
    for _, card in ipairs(player.hand or {}) do
        local def = api.getCardDefinition(card.cardId)
        names[#names + 1] = def and def.name or card.cardId
    end

    local message = ('Player %s revealed hand: %s'):format(playerIndex, #names > 0 and table.concat(names, ', ') or '(empty)')
    appendLog(duel, message)
    local viewer = duel.players[sourcePlayerIndex]
    if viewer and viewer.source then
        TriggerClientEvent('bstar_cards:client:DuelMessageModal', viewer.source, {
            title = action.title or 'Revealed Hand',
            text = message,
            confirmText = 'Okay'
        })
    end
end

function ACTIONS.move_random_opponent_hand_to_deck_bottom(duel, sourcePlayerIndex, sourceCard, action, api)
    local opponentIndex = api.getOpponentIndex(sourcePlayerIndex)
    local opponent = duel.players[opponentIndex]
    if not opponent or #(opponent.hand or {}) == 0 then return end

    local index = math.random(1, #opponent.hand)
    local card = table.remove(opponent.hand, index)
    if not card then return end

    card.zone = 'deck'
    card.controller = opponentIndex
    opponent.deck[#opponent.deck + 1] = card
    appendLog(duel, ('%s placed a random opponent hand card on the bottom of the deck.'):format(sourceCard and sourceCard.cardId or 'An effect'))
end

function ACTIONS.plant_self_in_opponent_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    if not sourceCard or not api.removeCardByUid then return end

    local opponentIndex = api.getOpponentIndex(sourcePlayerIndex)
    local opponent = duel.players[opponentIndex]
    if not opponent then return end

    local removedCard = api.removeCardByUid(duel, sourceCard.uid, { suppressSentTrigger = true })
    if not removedCard then return end

    removedCard.zone = 'deck'
    removedCard.controller = opponentIndex
    removedCard.plantedWadeTrap = true
    removedCard.plantedOwnerIndex = sourcePlayerIndex
    removedCard.plantedLpLoss = tonumber(action.lpLoss) or 80
    removedCard.plantedOwnerDraw = tonumber(action.ownerDraw) or 1

    local insertIndex = math.random(1, #(opponent.deck or {}) + 1)
    table.insert(opponent.deck, insertIndex, removedCard)
    appendLog(duel, ('Player %s shuffled %s into opponent deck.'):format(sourcePlayerIndex, removedCard.cardId))
end

function ACTIONS.roll_select_destroy_field_card(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local sides = tonumber(action.sides) or 6
    local roll = math.random(1, sides)
    context.lastRoll = roll

    local highThreshold = tonumber(action.highThreshold) or tonumber(action.threshold) or sides
    local lowThreshold = tonumber(action.lowThreshold) or 0

    if roll >= highThreshold then
        ACTIONS.select_destroy_field_card(duel, sourcePlayerIndex, sourceCard, {
            target = action.highTarget or 'opponent',
            zone = action.zone or 'field',
            promptText = action.highPromptText or ('Rolled %s. Choose 1 opponent card to destroy.'):format(roll),
            filter = action.highFilter or action.filter or {}
        }, api, context)
        appendLog(duel, ('%s rolled %s and can destroy an opponent card.'):format(sourceCard.cardId, roll))
    elseif lowThreshold > 0 and roll <= lowThreshold then
        ACTIONS.select_destroy_field_card(duel, sourcePlayerIndex, sourceCard, {
            target = action.lowTarget or 'self',
            zone = action.zone or 'field',
            promptText = action.lowPromptText or ('Rolled %s. Choose 1 of your cards to destroy.'):format(roll),
            filter = action.lowFilter or action.filter or {}
        }, api, context)
        appendLog(duel, ('%s rolled %s and must destroy one of its controller cards.'):format(sourceCard.cardId, roll))
    else
        appendLog(duel, ('%s rolled %s with no effect.'):format(sourceCard.cardId, roll))
    end
end

function ACTIONS.roll_destroy_attacker(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not api.moveCardByUidToGraveyard then return end

    local sides = tonumber(action.sides) or 6
    local roll = math.random(1, sides)
    local threshold = tonumber(action.threshold or action.highThreshold) or 4
    appendLog(duel, ('%s rolled %s for attacker destruction.'):format(sourceCard and sourceCard.cardId or 'An effect', roll))

    if roll >= threshold then
        local attackerUid = context and context.event and context.event.attackerUid
        if attackerUid then
            api.moveCardByUidToGraveyard(duel, attackerUid, {
                reason = action.reason or 'card_effect',
                sourceUid = sourceCard and sourceCard.uid or nil,
                sourceCardId = sourceCard and sourceCard.cardId or nil
            })
        end
    end
end

function ACTIONS.coin_flip_draw(duel, sourcePlayerIndex, sourceCard, action, api)
    local heads = math.random(1, 2) == 1
    local target = heads and (action.headsTarget or 'self') or (action.tailsTarget or 'opponent')
    local amount = heads and (action.headsAmount or action.amount or 1) or (action.tailsAmount or action.amount or 1)
    ACTIONS.draw(duel, sourcePlayerIndex, sourceCard, { target = target, amount = amount }, api, {})
    appendLog(duel, ('%s flipped %s.'):format(sourceCard and sourceCard.cardId or 'An effect', heads and 'heads' or 'tails'))
end

function ACTIONS.show_duel_modal(duel, sourcePlayerIndex, sourceCard, action, api)
    local target = tostring(action.target or 'self'):lower()
    local playerIndexes = {}

    if target == 'both' or target == 'all' or target == 'all_players' then
        playerIndexes = { sourcePlayerIndex, api.getOpponentIndex(sourcePlayerIndex) }
    else
        playerIndexes = { getPlayerIndex(action, sourcePlayerIndex, api) }
    end

    for _, playerIndex in ipairs(playerIndexes) do
        local player = duel.players[playerIndex]
        if player and player.source then
            TriggerClientEvent('bstar_cards:client:DuelMessageModal', player.source, {
                title = action.title or 'Effect',
                text = action.text or action.message or '',
                confirmText = action.confirmText or 'Okay'
            })
        end
    end

    if action.log ~= false then
        appendLog(duel, action.logMessage or (action.text or action.message or 'Effect message shown.'))
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

function ACTIONS.return_event_defender_to_hand(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local defenderUid = context and context.event and context.event.defenderUid
    if not defenderUid or not api.findCardByUid then return end

    local card, playerState, playerIndex, zoneName, zoneIndex = api.findCardByUid(duel, defenderUid)
    if not card or zoneName ~= 'fighterZones' then return end

    if api.moveEquipmentAtToGraveyard then
        api.moveEquipmentAtToGraveyard(playerState, zoneIndex, duel, {
            reason = action.reason or 'returned_to_hand',
            sourceUid = sourceCard and sourceCard.uid or nil,
            sourceCardId = sourceCard and sourceCard.cardId or nil
        })
    end

    playerState.fighterZones[zoneIndex] = nil
    card.zone = 'hand'
    card.controller = playerIndex
    card.hasAttacked = false
    card.equipmentStatModifiers = nil
    card.continuousStatModifiers = nil
    playerState.hand = playerState.hand or {}
    playerState.hand[#playerState.hand + 1] = card

    appendLog(duel, ('Player %s returned an attacked fighter to hand.'):format(playerIndex))
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

    api.moveFieldCardToGraveyard(player, tributeZoneIndex, {
        duel = duel,
        reason = 'tribute',
        skipReplacement = true,
        sourceUid = sourceCard and sourceCard.uid or nil,
        sourceCardId = sourceCard and sourceCard.cardId or nil
    })
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

    if action.target == 'equipped_fighter' then
        local player = duel.players[sourcePlayerIndex]
        local zoneIndex = tonumber(sourceCard and sourceCard.equippedToZoneIndex)
            or tonumber(context and context.event and context.event.zoneIndex)
        local targetCard = zoneIndex and player and player.fighterZones and player.fighterZones[zoneIndex] or nil
        if not targetCard then return end

        for stat, amount in pairs(statMods) do
            if type(amount) == 'table' then
                amount = resolveAmount({ amount = amount }, context)
            end
            applyStatModifier(targetCard, stat, amount, duration)
        end
        return
    end

    if action.target == 'event_target' then
        local targetCard = api.findCardByUid and api.findCardByUid(duel, context and context.event and context.event.targetUid) or nil
        if not targetCard then return end

        for stat, amount in pairs(statMods) do
            if type(amount) == 'table' then
                amount = resolveAmount({ amount = amount }, context)
            end
            applyStatModifier(targetCard, stat, amount, duration)
        end
        return
    end

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
            api.moveHandCardToGraveyard(player, i, duel, {
                reason = action.reason or 'discard',
                sourceUid = sourceCard and sourceCard.uid or nil,
                sourceCardId = sourceCard and sourceCard.cardId or nil
            })
            discarded = discarded + 1
        end
        i = i - 1
    end

    if discarded > 0 then
        appendLog(duel, ('Player %s discarded %s matching card(s).'):format(playerIndex, discarded))
    end
end

function ACTIONS.discard_named_hand_card_then_watch_drawn_type(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player then return end

    local handIndex, card = findHandCardIndex(player, action.discardFilter or action.filter or {}, api)
    if not handIndex or not card then
        appendLog(duel, ('%s could not find the required discard.'):format(sourceCard and sourceCard.cardId or 'Effect'))
        return
    end

    api.moveHandCardToGraveyard(player, handIndex, duel, {
        reason = 'discard',
        sourceUid = sourceCard and sourceCard.uid or nil,
        sourceCardId = sourceCard and sourceCard.cardId or nil
    })

    local playerState = duel.players[sourcePlayerIndex]
    if playerState then
        playerState.drawnTypeWatchers = playerState.drawnTypeWatchers or {}
        playerState.drawnTypeWatchers[#playerState.drawnTypeWatchers + 1] = {
            cardType = string.upper(tostring(action.cardType or 'Vehicle')),
            amount = tonumber(action.amount) or 1,
            expiresTurnNumber = duel.turnNumber + math.max(0, (tonumber(action.turns) or 3) - 1),
            sourceUid = sourceCard and sourceCard.uid or nil,
            sourceCardId = sourceCard and sourceCard.cardId or nil
        }
    end
end

function ACTIONS.banish_self_from_graveyard(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player or not sourceCard then return end

    for i = #(player.graveyard or {}), 1, -1 do
        if player.graveyard[i] == sourceCard then
            local card = table.remove(player.graveyard, i)
            card.zone = 'banished'
            player.banished = player.banished or {}
            player.banished[#player.banished + 1] = card
            appendLog(duel, ('Player %s banished %s from cemetery.'):format(sourcePlayerIndex, card.cardId))
            return
        end
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
        api.moveHandCardToGraveyard(player, index, duel, {
            reason = action.reason or 'discard',
            sourceUid = sourceCard and sourceCard.uid or nil,
            sourceCardId = sourceCard and sourceCard.cardId or nil
        })
    end
end

function ACTIONS.discard_self_from_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player or not sourceCard then return end

    for handIndex = #(player.hand or {}), 1, -1 do
        if player.hand[handIndex] == sourceCard or tostring(player.hand[handIndex].uid or '') == tostring(sourceCard.uid or '') then
            api.moveHandCardToGraveyard(player, handIndex, duel, {
                reason = action.reason or 'discard',
                sourceUid = sourceCard.uid,
                sourceCardId = sourceCard.cardId
            })
            return
        end
    end
end

function ACTIONS.cancel_pending_battle(duel)
    if duel then
        duel.pendingBattle = nil
        appendLog(duel, 'The attack was negated and the battle ended.')
    end
end

function ACTIONS.lethal_battle_damage_survive_1_then_cemetery(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local event = context and context.event
    local targetCard = event and event.targetUid and api.findCardByUid and api.findCardByUid(duel, event.targetUid) or event and event.targetCard
    if not event or not targetCard then return end

    local currentHp = tonumber(targetCard.currentHp) or tonumber(targetCard.maxHp) or 0
    local incoming = tonumber(event.amount) or 0
    if incoming < currentHp then return end

    event.amount = math.max(0, currentHp - 1)
    event.replacementPrevented = false
    if api.scheduleDelayedTask then
        api.scheduleDelayedTask(duel, {
            sourcePlayerIndex = sourcePlayerIndex,
            sourceUid = sourceCard and sourceCard.uid or nil,
            sourceCardId = sourceCard and sourceCard.cardId or nil,
            tickPlayerIndex = sourcePlayerIndex,
            timing = 'end_turn',
            remaining = 1,
            targetUids = { targetCard.uid },
            actions = {
                { action = 'destroy_card', target = 'event_target', reason = 'oxy_crash' }
            },
            label = 'Oxycodone crash'
        })
    end
end

function ACTIONS.skip_draw_phases(duel, sourcePlayerIndex, sourceCard, action, api)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local player = duel.players[playerIndex]
    local amount = math.max(0, resolveAmount(action, { event = {} }))
    if not player or amount <= 0 then return end

    player.skipDrawPhases = (tonumber(player.skipDrawPhases) or 0) + amount
    appendLog(duel, ('Player %s will skip their next %s draw phase(s).'):format(playerIndex, amount))
end

function ACTIONS.schedule_delayed_actions(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not api.scheduleDelayedTask or not sourceCard then return end

    local tickPlayerIndex = sourcePlayerIndex
    local tickPlayer = tostring(action.tickPlayer or action.tickTarget or 'source'):lower()
    if tickPlayer == 'opponent' then
        tickPlayerIndex = api.getOpponentIndex(sourcePlayerIndex)
    elseif tickPlayer == 'target' then
        tickPlayerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    end

    api.scheduleDelayedTask(duel, {
        sourcePlayerIndex = sourcePlayerIndex,
        sourceUid = sourceCard.uid,
        sourceCardId = sourceCard.cardId,
        zoneIndex = context and context.event and context.event.zoneIndex or sourceCard.equippedToZoneIndex,
        tickPlayerIndex = tickPlayerIndex,
        timing = action.timing or action.tickTiming or 'end_turn',
        remaining = tonumber(action.turns or action.remaining or action.amount) or 1,
        targetUids = action.targetUids or (context and context.event and context.event.targetUids) or { sourceCard.uid },
        actions = action.actions or action.resolveActions or {},
        requireSourceZone = action.requireSourceZone,
        label = action.label
    })
end

function ACTIONS.add_special_summon_draw_watcher(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.addSpecialSummonDrawWatcher then return end

    local watchedPlayerIndex = getPlayerIndex({ target = action.watchTarget or action.target or 'opponent' }, sourcePlayerIndex, api)
    api.addSpecialSummonDrawWatcher(duel, sourcePlayerIndex, {
        watchedPlayerIndex = watchedPlayerIndex,
        amount = action.amount or 1
    })
end

function ACTIONS.add_played_type_draw_watcher(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.addPlayedTypeDrawWatcher then return end

    local watchedPlayerIndex = getPlayerIndex({ target = action.watchTarget or action.target or 'opponent' }, sourcePlayerIndex, api)
    api.addPlayedTypeDrawWatcher(duel, sourcePlayerIndex, {
        watchedPlayerIndex = watchedPlayerIndex,
        cardType = action.cardType or action.typeFilter or action.playedCardType,
        amount = action.amount or 1,
        turns = action.turns
    })
end

function ACTIONS.banish_card(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not api.banishCardByUid then return end
    local uid = action.uid
        or action.targetUid
        or (tostring(action.target or '') == 'event_target' and context and context.event and context.event.targetUid)
        or (sourceCard and sourceCard.uid)
    if not uid then return end

    api.banishCardByUid(duel, uid)
end

function ACTIONS.destroy_all_equipment(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.moveCardByUidToGraveyard then return end

    local target = tostring(action.target or action.player or 'both'):lower()
    local filter = action.filter or {}
    local playerIndexes = {}
    if target == 'both' or target == 'all' or target == 'all_players' then
        playerIndexes = { sourcePlayerIndex, api.getOpponentIndex(sourcePlayerIndex) }
    else
        playerIndexes = { getPlayerIndex(action, sourcePlayerIndex, api) }
    end

    for _, playerIndex in ipairs(playerIndexes) do
        local player = duel.players[playerIndex]
        if player then
            local uids = {}
            for _, slot in pairs(player.equipmentZones or {}) do
                if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                    for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                        if cardMatchesFilter(slot[key], filter, api) then
                            uids[#uids + 1] = slot[key].uid
                        end
                    end
                elseif cardMatchesFilter(slot, filter, api) then
                    uids[#uids + 1] = slot.uid
                end
            end

            for _, uid in ipairs(uids) do
                api.moveCardByUidToGraveyard(duel, uid, {
                    reason = action.reason or 'card_effect',
                    sourceUid = sourceCard and sourceCard.uid or nil,
                    sourceCardId = sourceCard and sourceCard.cardId or nil
                })
            end
        end
    end
end

function ACTIONS.destroy_card(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not api.moveCardByUidToGraveyard then return end
    local uid = action.uid
        or action.targetUid
        or (tostring(action.target or '') == 'event_target' and context and context.event and context.event.targetUid)
        or (sourceCard and sourceCard.uid)
    if not uid then return end

    api.moveCardByUidToGraveyard(duel, uid, {
        reason = action.reason or 'card_effect',
        sourceUid = sourceCard and sourceCard.uid or nil,
        sourceCardId = sourceCard and sourceCard.cardId or nil,
        skipReplacement = action.skipReplacement == true
    })
end

function ACTIONS.prevent_destruction(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not context or not context.event then return end
    context.event.replacementPrevented = true
    context.event.replacementSourceUid = sourceCard and sourceCard.uid or nil
    context.event.replacementSourceCardId = sourceCard and sourceCard.cardId or nil
    appendLog(duel, ('%s prevented %s from being destroyed.'):format(
        sourceCard and sourceCard.cardId or 'An effect',
        context.event.targetCard and context.event.targetCard.cardId or 'a card'
    ))
end

function ACTIONS.prevent_status_effect(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not context or not context.event then return end
    context.event.replacementPrevented = true
    context.event.replacementSourceUid = sourceCard and sourceCard.uid or nil
    context.event.replacementSourceCardId = sourceCard and sourceCard.cardId or nil
    appendLog(duel, ('%s prevented %s on %s.'):format(
        sourceCard and sourceCard.cardId or 'An effect',
        context.event.statusId or 'a status effect',
        context.event.targetCard and context.event.targetCard.cardId or 'a card'
    ))
end

function ACTIONS.prevent_targeting(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not context or not context.event then return end
    context.event.targetingPrevented = true
    context.event.targetingPreventedByUid = sourceCard and sourceCard.uid or nil
    context.event.targetingPreventedByCardId = sourceCard and sourceCard.cardId or nil
end

function ACTIONS.invert_lp_gain(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not context or not context.event then return end

    local targetPlayerIndex = tonumber(context.event.targetPlayerIndex or context.event.gainingPlayer)
    local amount = math.max(0, tonumber(context.event.amount) or 0)
    local targetPlayer = targetPlayerIndex and duel.players[targetPlayerIndex] or nil
    if not targetPlayer or amount <= 0 then return end

    targetPlayer.lifePoints = math.max(0, (tonumber(targetPlayer.lifePoints) or 0) - amount)
    context.event.lpGainReplaced = true
    context.event.replacementPrevented = true

    local selfGain = math.floor(amount * (tonumber(action.selfGainMultiplier) or 0))
    if selfGain > 0 then
        local sourcePlayer = duel.players[sourcePlayerIndex]
        if sourcePlayer then
            sourcePlayer.lifePoints = (tonumber(sourcePlayer.lifePoints) or 0) + selfGain
        end
    end

    appendLog(duel, ('%s inverted Player %s LP gain into %s LP loss.'):format(
        sourceCard and sourceCard.cardId or 'An effect',
        targetPlayerIndex,
        amount
    ))
end

function ACTIONS.prevent_lp_loss(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not context or not context.event then return end
    context.event.lpLossReplaced = true
    context.event.replacementPrevented = true
    context.event.replacementSourceUid = sourceCard and sourceCard.uid or nil
    context.event.replacementSourceCardId = sourceCard and sourceCard.cardId or nil
    appendLog(duel, ('%s prevented LP loss.'):format(sourceCard and sourceCard.cardId or 'An effect'))
end

function ACTIONS.prevent_battle_damage(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not context or not context.event then return end
    context.event.replacementPrevented = true
    context.event.replacementSourceUid = sourceCard and sourceCard.uid or nil
    context.event.replacementSourceCardId = sourceCard and sourceCard.cardId or nil
    appendLog(duel, ('%s prevented battle damage.'):format(sourceCard and sourceCard.cardId or 'An effect'))
end

function ACTIONS.coin_flip_prevent_destruction(duel, sourcePlayerIndex, sourceCard, action, api, context)
    if not context or not context.event then return end
    local headsPrevents = action.headsPrevents ~= false
    local heads = math.random(1, 2) == 1
    context.event.lastCoinFlip = heads and 'heads' or 'tails'

    appendLog(duel, ('%s flipped %s for destruction prevention.'):format(
        sourceCard and sourceCard.cardId or 'An effect',
        context.event.lastCoinFlip
    ))

    if (heads and headsPrevents) or ((not heads) and not headsPrevents) then
        ACTIONS.prevent_destruction(duel, sourcePlayerIndex, sourceCard, action, api, context)
    end
end

function ACTIONS.set_hp(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local card = sourceCard
    if tostring(action.target or '') == 'event_target' and api.findCardByUid then
        card = api.findCardByUid(duel, context and context.event and context.event.targetUid)
    elseif tostring(action.target or '') == 'equipped_fighter' then
        local player = duel.players[sourcePlayerIndex]
        local zoneIndex = tonumber(sourceCard and sourceCard.equippedToZoneIndex)
            or tonumber(context and context.event and context.event.zoneIndex)
        card = zoneIndex and player and player.fighterZones and player.fighterZones[zoneIndex] or nil
    end

    local amount = math.max(0, resolveAmount(action, context))
    if not card then return end

    api.ensureFighterHp(card)
    card.currentHp = math.min(tonumber(card.maxHp) or amount, amount)
end

local function getSingleActionTargetCard(duel, sourceCard, action, api, context)
    local target = tostring(action.target or 'self')
    if target == 'event_target' and api.findCardByUid then
        return api.findCardByUid(duel, context and context.event and context.event.targetUid)
    end
    if target == 'event_defender' and api.findCardByUid then
        local event = context and context.event or {}
        local defenderUid = event.defenderUid or event.defenderCard and event.defenderCard.uid
        return api.findCardByUid(duel, defenderUid)
    end
    if target == 'event_attacker' and api.findCardByUid then
        local event = context and context.event or {}
        local attackerUid = event.attackerUid or event.attackerCard and event.attackerCard.uid
        return api.findCardByUid(duel, attackerUid)
    end
    if target == 'source' or target == 'self' then
        return sourceCard
    end
    if action.targetUid and api.findCardByUid then
        return api.findCardByUid(duel, action.targetUid)
    end
    return sourceCard
end

function ACTIONS.add_status(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local card = getSingleActionTargetCard(duel, sourceCard, action, api, context)
    if not card then return end

    card.statuses = card.statuses or {}
    card.statuses[#card.statuses + 1] = {
        id = action.status or action.statusId or action.name or 'status',
        name = action.name or action.status or action.statusId or 'Status',
        amount = tonumber(action.amount or action.damage),
        cardType = action.cardType or action.blockedType,
        timing = action.timing or 'end_turn',
        remaining = action.turns and tonumber(action.turns) or nil,
        sourceUid = sourceCard and sourceCard.uid or nil,
        sourceCardId = sourceCard and sourceCard.cardId or nil
    }
end

function ACTIONS.add_player_status(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    if tostring(action.target or '') == 'event_defender_player' then
        playerIndex = tonumber(context and context.event and context.event.defendingPlayer) or playerIndex
    elseif tostring(action.target or '') == 'event_attacker_player' then
        playerIndex = tonumber(context and context.event and context.event.attackingPlayer) or playerIndex
    end

    local player = duel.players[playerIndex]
    if not player then return end

    player.statuses = player.statuses or {}
    player.statuses[#player.statuses + 1] = {
        id = action.status or action.statusId or action.name or 'status',
        name = action.name or action.status or action.statusId or 'Status',
        amount = tonumber(action.amount or action.damage),
        cardType = action.cardType or action.blockedType,
        timing = action.timing or 'end_turn',
        remaining = action.turns and tonumber(action.turns) or nil,
        sourceUid = sourceCard and sourceCard.uid or nil,
        sourceCardId = sourceCard and sourceCard.cardId or nil
    }
end

function ACTIONS.remove_status(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local card = getSingleActionTargetCard(duel, sourceCard, action, api, context)
    if not card or type(card.statuses) ~= 'table' then return end

    local wanted = string.lower(tostring(action.status or action.statusId or action.name or ''))
    local remaining = {}
    for _, status in ipairs(card.statuses) do
        local id = string.lower(tostring(status.id or status.name or ''))
        if wanted == '' or id ~= wanted then
            remaining[#remaining + 1] = status
        end
    end
    card.statuses = remaining
end

function ACTIONS.add_counter(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local card = getSingleActionTargetCard(duel, sourceCard, action, api, context)
    if not card then return end

    local counter = tostring(action.counter or action.counterId or action.name or 'counter')
    local amount = tonumber(action.amount) or 1
    card.counters = card.counters or {}
    card.counters[counter] = (tonumber(card.counters[counter]) or 0) + amount
end

function ACTIONS.remove_counter(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local card = getSingleActionTargetCard(duel, sourceCard, action, api, context)
    if not card or type(card.counters) ~= 'table' then return end

    local counter = tostring(action.counter or action.counterId or action.name or '')
    if counter == '' then return end

    local amount = tonumber(action.amount) or card.counters[counter] or 0
    card.counters[counter] = math.max(0, (tonumber(card.counters[counter]) or 0) - amount)
    if card.counters[counter] <= 0 then
        card.counters[counter] = nil
    end
end

function ACTIONS.add_counter_to_opponent_fighters(duel, sourcePlayerIndex, sourceCard, action, api)
    local opponent = duel.players[api.getOpponentIndex(sourcePlayerIndex)]
    if not opponent then return end

    local counter = action.counter or action.counterId or 'counter'
    local amount = tonumber(action.amount) or 1
    for _, card in pairs(opponent.fighterZones or {}) do
        if card then
            card.counters = card.counters or {}
            card.counters[counter] = (tonumber(card.counters[counter]) or 0) + amount
        end
    end
    if sourceCard then
        sourceCard.stickyBombPlacedTurn = duel.turnNumber
    end
end

function ACTIONS.detonate_sticky_bomb_counters(duel, sourcePlayerIndex, sourceCard, action, api)
    if sourceCard and tonumber(sourceCard.stickyBombPlacedTurn) == tonumber(duel.turnNumber) then
        appendLog(duel, 'Sticky Bomb counters cannot be detonated the turn they are placed.')
        return
    end

    local counter = action.counter or action.counterId or 'Sticky Bomb'
    local damagePerCounter = tonumber(action.damagePerCounter or action.damage) or 30

    for _, playerIndex in ipairs({ sourcePlayerIndex, api.getOpponentIndex(sourcePlayerIndex) }) do
        local player = duel.players[playerIndex]
        for zoneIndex, card in pairs(player and player.fighterZones or {}) do
            local counters = tonumber(card and card.counters and card.counters[counter]) or 0
            if counters > 0 then
                card.counters[counter] = nil
                card.currentHp = math.max(0, (tonumber(card.currentHp) or 0) - counters * damagePerCounter)
                if card.currentHp <= 0 then
                    api.moveFieldCardToGraveyard(player, zoneIndex, {
                        duel = duel,
                        reason = 'card_effect',
                        sourceUid = sourceCard and sourceCard.uid or nil,
                        sourceCardId = sourceCard and sourceCard.cardId or nil,
                        targetPlayerIndex = playerIndex
                    })
                end
            end
        end
    end
end

function ACTIONS.grant_extra_attacks()
    -- Read by the battle attack-limit helper as a continuous effect descriptor.
end

function ACTIONS.destroy_all_fighters(duel, sourcePlayerIndex, sourceCard, action, api)
    local target = tostring(action.target or action.player or 'self'):lower()
    local playerIndexes = {}

    if target == 'both' or target == 'all' or target == 'all_players' then
        playerIndexes = { sourcePlayerIndex, api.getOpponentIndex(sourcePlayerIndex) }
    else
        playerIndexes = { getPlayerIndex(action, sourcePlayerIndex, api) }
    end

    for _, playerIndex in ipairs(playerIndexes) do
        local player = duel.players[playerIndex]
        if player then
            for i = 1, 3 do
                if player.fighterZones[i] then
                    api.moveFieldCardToGraveyard(player, i, {
                        duel = duel,
                        reason = action.reason or 'card_effect',
                        sourceUid = sourceCard and sourceCard.uid or nil,
                        sourceCardId = sourceCard and sourceCard.cardId or nil
                    })
                end
            end
        end
    end
end

function ACTIONS.destroy_first_fighter(duel, sourcePlayerIndex, sourceCard, action, api)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local player = duel.players[playerIndex]
    if not player then return end

    for i = 1, 3 do
        if player.fighterZones[i] then
            api.moveFieldCardToGraveyard(player, i, {
                duel = duel,
                reason = action.reason or 'card_effect',
                sourceUid = sourceCard and sourceCard.uid or nil,
                sourceCardId = sourceCard and sourceCard.cardId or nil
            })
            return
        end
    end
end

function ACTIONS.roll_destroy_first_fighter(duel, sourcePlayerIndex, sourceCard, action, api, context)
    local sides = tonumber(action.sides) or 6
    local roll = math.random(1, sides)
    context.lastRoll = roll

    local highThreshold = tonumber(action.highThreshold) or tonumber(action.threshold) or sides
    local lowThreshold = tonumber(action.lowThreshold) or 0

    if roll >= highThreshold then
        ACTIONS.destroy_first_fighter(duel, sourcePlayerIndex, sourceCard, { target = action.highTarget or 'opponent' }, api, context)
        appendLog(duel, ('%s rolled %s and destroyed an opponent fighter.'):format(sourceCard.cardId, roll))
    elseif lowThreshold > 0 and roll <= lowThreshold then
        ACTIONS.destroy_first_fighter(duel, sourcePlayerIndex, sourceCard, { target = action.lowTarget or 'self' }, api, context)
        appendLog(duel, ('%s rolled %s and destroyed one of its controller fighters.'):format(sourceCard.cardId, roll))
    else
        appendLog(duel, ('%s rolled %s with no effect.'):format(sourceCard.cardId, roll))
    end
end

function ACTIONS.shuffle_all_to_deck_and_redraw(duel, sourcePlayerIndex, sourceCard, action, api)
    local redraw = tonumber(action.redraw or action.amount) or 4

    for playerIndex, player in pairs(duel.players or {}) do
        local combined = {}

        local function collect(card)
            if not card then return end
            card.zone = 'deck'
            card.controller = card.owner or playerIndex
            card.hasAttacked = false
            card.statModifiers = nil
            card.turnStatModifiers = nil
            card.equipmentStatModifiers = nil
            card.continuousStatModifiers = nil
            combined[#combined + 1] = card
        end

        for _, card in ipairs(player.hand or {}) do collect(card) end
        for _, card in ipairs(player.graveyard or {}) do collect(card) end
        for _, card in ipairs(player.banished or {}) do collect(card) end
        for _, card in ipairs(player.deck or {}) do collect(card) end
        for i = 1, 3 do collect(player.fighterZones and player.fighterZones[i] or nil) end
        for i = 1, 4 do collect(player.itemZones and player.itemZones[i] or nil) end
        collect(player.locationZone)

        for _, slot in pairs(player.equipmentZones or {}) do
            if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                    collect(slot[key])
                end
            else
                collect(slot)
            end
        end

        for i = #combined, 2, -1 do
            local j = math.random(i)
            combined[i], combined[j] = combined[j], combined[i]
        end

        player.deck = combined
        player.hand = {}
        player.graveyard = {}
        player.banished = {}
        player.fighterZones = {}
        player.itemZones = {}
        player.equipmentZones = {}
        player.locationZone = nil

        api.drawCards(duel, playerIndex, redraw)
    end
end

function ACTIONS.play_event_from_deck(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player then return end

    local deckIndex, card = findDeckCardIndex(player, action.filter or {}, api)
    if not deckIndex or not card then
        appendLog(duel, ('Player %s could not find an event to play from deck.'):format(sourcePlayerIndex))
        return
    end

    table.remove(player.deck, deckIndex)
    card.zone = 'graveyard'
    player.graveyard[#player.graveyard + 1] = card

    appendLog(duel, ('Player %s played %s from deck by effect.'):format(sourcePlayerIndex, card.cardId))
    DuelEffects.RunTrigger(duel, 'on_play', sourcePlayerIndex, card, {
        responseEvent = 'card_played',
        trigger = 'card_played',
        playedByEffect = true,
        playedUid = card.uid,
        playedCard = card,
        playedCardType = 'EVENT',
        playingPlayer = sourcePlayerIndex,
        zone = 'graveyard'
    }, api, { force = true })
end

function ACTIONS.complete_equipment_combo_to_hand(duel, sourcePlayerIndex, sourceCard, action, api)
    local player = duel.players[sourcePlayerIndex]
    if not player then return end

    local required = action.requiredNames or {}
    local matched = {}

    for _, wantedName in ipairs(required) do
        local wanted = string.lower(tostring(wantedName or ''))
        local found = nil
        if wanted ~= '' then
            for i = 1, 3 do
                local slot = player.equipmentZones and player.equipmentZones[i] or nil
                local function check(card)
                    if found or not card then return end
                    local def = api.getCardDefinition(card.cardId)
                    local nameText = string.lower(tostring(def and def.name or ''))
                    if nameText == wanted then
                        found = card
                    end
                end
                if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                    check(slot.vehicle)
                    check(slot.weapon)
                    check(slot.equipment)
                else
                    check(slot)
                end
            end
        end

        if not found then
            appendLog(duel, ('Equipment combo missing %s.'):format(wantedName))
            return
        end
        matched[#matched + 1] = found
    end

    for _, card in ipairs(matched) do
        if api.moveCardByUidToGraveyard then
            api.moveCardByUidToGraveyard(duel, card.uid, {
                reason = 'combo_material',
                sourceUid = sourceCard and sourceCard.uid or nil,
                sourceCardId = sourceCard and sourceCard.cardId or nil
            })
        end
    end

    local searchFilter = action.searchFilter or {}
    local deckIndex, reward = findDeckCardIndex(player, searchFilter, api)
    if deckIndex and reward then
        table.remove(player.deck, deckIndex)
        reward.zone = 'hand'
        player.hand[#player.hand + 1] = reward
        appendLog(duel, ('Player %s added %s to hand from an equipment combo.'):format(sourcePlayerIndex, reward.cardId))
    else
        appendLog(duel, ('Player %s completed an equipment combo, but no reward was found.'):format(sourcePlayerIndex))
    end
end

function ACTIONS.banish_lowest_speed_vehicle_and_equipped_fighter(duel, sourcePlayerIndex, sourceCard, action, api)
    if not api.banishCardByUid then return end

    local lowest = nil
    local function vehicleSpeed(card)
        local def = card and api.getCardDefinition(card.cardId)
        local raw = tostring(def and (def.speed or def.spd) or '')
        local match = raw:match('([%+%-]?%s*%d+)')
        return tonumber(match and match:gsub('%s+', '') or '') or 0
    end

    for playerIndex, player in pairs(duel.players or {}) do
        for zoneIndex, slot in pairs(player.equipmentZones or {}) do
            local vehicle = slot and slot.vehicle or nil
            if not vehicle and slot then
                local def = api.getCardDefinition(slot.cardId)
                if def and string.upper(tostring(def.type or '')) == 'VEHICLE' then
                    vehicle = slot
                end
            end

            if vehicle then
                local speed = vehicleSpeed(vehicle)
                if not lowest or speed < lowest.speed then
                    lowest = {
                        speed = speed,
                        vehicle = vehicle,
                        fighter = player.fighterZones and player.fighterZones[zoneIndex] or nil,
                        playerIndex = playerIndex
                    }
                end
            end
        end
    end

    if not lowest or not lowest.vehicle then
        appendLog(duel, 'Police Chase found no Vehicle to banish.')
        return
    end

    api.banishCardByUid(duel, lowest.vehicle.uid)
    if lowest.fighter then
        api.banishCardByUid(duel, lowest.fighter.uid)
    end
    appendLog(duel, ('Police Chase banished the lowest-SPD Vehicle%s.'):format(lowest.fighter and ' and its equipped fighter' or ''))
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

    if condition.playedCardType then
        local playedType = tostring(event and event.playedCardType or ''):upper()
        if playedType ~= tostring(condition.playedCardType):upper() then
            return false
        end
    end

    if condition.phase and tostring(duel.phase) ~= tostring(condition.phase) then
        return false
    end

    if condition.playedByEffect ~= nil then
        local playedByEffect = event and event.playedByEffect == true
        if playedByEffect ~= (condition.playedByEffect == true) then
            return false
        end
    end

    if condition.sourceCounterMin then
        local counterReq = condition.sourceCounterMin
        local counter = tostring(counterReq.counter or counterReq.counterId or counterReq.name or '')
        local required = math.max(1, tonumber(counterReq.amount or counterReq.count or counterReq.min) or 1)
        if counter == '' or not sourceCard or type(sourceCard.counters) ~= 'table' or (tonumber(sourceCard.counters[counter]) or 0) < required then
            return false
        end
    end

    if condition.sentReason then
        local reason = tostring(event and event.reason or ''):lower()
        if reason ~= tostring(condition.sentReason):lower() then
            return false
        end
    end

    if condition.playedRarityAtLeast then
        local playedCard = event and event.playedCard
        local playedDef = playedCard and api.getCardDefinition(playedCard.cardId)
            or event and event.playedCardId and api.getCardDefinition(event.playedCardId)
            or nil
        if getRarityRank(playedDef and playedDef.rarity) < getRarityRank(condition.playedRarityAtLeast) then
            return false
        end
    end

    if condition.ownLpLowerThanOpponent == true then
        local player = duel.players[sourcePlayerIndex]
        local opponent = duel.players[api.getOpponentIndex(sourcePlayerIndex)]
        if not player or not opponent or (tonumber(player.lifePoints) or 0) >= (tonumber(opponent.lifePoints) or 0) then
            return false
        end
    end

    if condition.opponentSummonsThisTurnMin then
        local opponent = duel.players[api.getOpponentIndex(sourcePlayerIndex)]
        if (tonumber(opponent and opponent.summonsThisTurn) or 0) < tonumber(condition.opponentSummonsThisTurnMin) then
            return false
        end
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

    if condition.ownEquipmentCountMax then
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

        if count > tonumber(condition.ownEquipmentCountMax) then
            return false
        end
    end

    if condition.ownEquipmentTypeCountMin then
        local player = duel.players[sourcePlayerIndex]
        local wantedType = string.upper(tostring(condition.equipmentType or condition.ownEquipmentType or ''))
        local count = 0
        for i = 1, 3 do
            local slot = player and player.equipmentZones and player.equipmentZones[i] or nil
            local function countIfWanted(card)
                local def = card and api.getCardDefinition(card.cardId)
                if def and string.upper(tostring(def.type or '')) == wantedType then
                    count = count + 1
                end
            end
            if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                    countIfWanted(slot[key])
                end
            else
                countIfWanted(slot)
            end
        end

        if count < tonumber(condition.ownEquipmentTypeCountMin) then
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

    if condition.anyFieldCardMatches or condition.ownFieldCardMatches or condition.opponentFieldCardMatches then
        local filter = condition.anyFieldCardMatches or condition.ownFieldCardMatches or condition.opponentFieldCardMatches
        local playerIndexes = {}
        if condition.ownFieldCardMatches then
            playerIndexes = { sourcePlayerIndex }
        elseif condition.opponentFieldCardMatches then
            playerIndexes = { api.getOpponentIndex(sourcePlayerIndex) }
        else
            playerIndexes = { sourcePlayerIndex, api.getOpponentIndex(sourcePlayerIndex) }
        end

        local found = false
        local function check(card)
            if not found and cardMatchesFilter(card, filter, api) then
                found = true
            end
        end

        for _, playerIndex in ipairs(playerIndexes) do
            local player = duel.players[playerIndex]
            for i = 1, 3 do check(player and player.fighterZones and player.fighterZones[i] or nil) end
            for i = 1, 4 do check(player and player.itemZones and player.itemZones[i] or nil) end
            check(player and player.locationZone or nil)
            for i = 1, 3 do
                local slot = player and player.equipmentZones and player.equipmentZones[i] or nil
                if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                    check(slot.vehicle)
                    check(slot.weapon)
                    check(slot.equipment)
                else
                    check(slot)
                end
            end
        end

        if not found then
            return false
        end
    end

    if condition.destroyReason then
        local reason = tostring(event and event.reason or '')
        if reason ~= tostring(condition.destroyReason) then
            return false
        end
    end

    if condition.destroyReasonNot then
        local reason = tostring(event and event.reason or '')
        if reason == tostring(condition.destroyReasonNot) then
            return false
        end
    end

    if condition.statusId then
        local statusId = tostring(event and (event.statusId or event.status) or ''):lower()
        if statusId ~= tostring(condition.statusId):lower() then
            return false
        end
    end

    if condition.responseEvent then
        local responseEvent = tostring(event and event.responseEvent or event and event.trigger or ''):lower()
        if responseEvent ~= tostring(condition.responseEvent):lower() then
            return false
        end
    end

    if type(condition.responseEventsAny) == 'table' then
        local responseEvent = tostring(event and event.responseEvent or event and event.trigger or ''):lower()
        local matched = false
        for _, value in ipairs(condition.responseEventsAny) do
            if responseEvent == tostring(value):lower() then
                matched = true
                break
            end
        end
        if not matched then
            return false
        end
    end

    if condition.battleTargetType then
        local targetType = tostring(event and event.targetType or ''):lower()
        if targetType ~= tostring(condition.battleTargetType):lower() then
            return false
        end
    end

    if condition.battleDamageToDefenderMin and (tonumber(event and event.damageToDefenderFighter) or 0) < tonumber(condition.battleDamageToDefenderMin) then
        return false
    end

    if condition.lethalBattleDamage == true then
        local targetCard = event and event.targetCard or event and event.targetUid and api.findCardByUid and api.findCardByUid(duel, event.targetUid) or nil
        local incoming = tonumber(event and event.amount) or 0
        local currentHp = tonumber(targetCard and targetCard.currentHp) or tonumber(targetCard and targetCard.maxHp) or 0
        if incoming < currentHp then
            return false
        end
    end

    if condition.battleDamageToPlayerMin and (tonumber(event and event.damageToDefenderPlayer) or 0) < tonumber(condition.battleDamageToPlayerMin) then
        return false
    end

    if condition.equippedFighterIsAttacker == true then
        local zoneIndex = tonumber(sourceCard and sourceCard.equippedToZoneIndex)
        local player = duel.players[sourcePlayerIndex]
        local equippedFighter = zoneIndex and player and player.fighterZones and player.fighterZones[zoneIndex] or nil
        if not equippedFighter or not event or event.attackerUid ~= equippedFighter.uid then
            return false
        end
    end

    if condition.defenderFilter then
        local defenderCard = event and (event.defenderRawCard or event.defenderCard)
        if not cardMatchesFilter(defenderCard, condition.defenderFilter, api) then
            return false
        end
    end

    if condition.eventDefenderIsSource == true and (not event or not sourceCard or event.defenderUid ~= sourceCard.uid) then
        return false
    end

    if condition.eventAttackerNameContains then
        local attackerCard = event and event.attackerUid and api.findCardByUid and api.findCardByUid(duel, event.attackerUid) or event and event.attackerCard
        local attackerDef = attackerCard and api.getCardDefinition(attackerCard.cardId)
        local nameText = string.lower(tostring(attackerDef and attackerDef.name or ''))
        if nameText:find(string.lower(tostring(condition.eventAttackerNameContains)), 1, true) == nil then
            return false
        end
    end

    if condition.eventDestroyedNameContains then
        local destroyedCard = event and event.destroyedUid and api.findCardByUid and api.findCardByUid(duel, event.destroyedUid) or event and event.destroyedCard
        local destroyedDef = destroyedCard and api.getCardDefinition(destroyedCard.cardId)
        local nameText = string.lower(tostring(destroyedDef and destroyedDef.name or ''))
        if nameText:find(string.lower(tostring(condition.eventDestroyedNameContains)), 1, true) == nil then
            return false
        end
    end

    if condition.sourceSurvivedBattleDamage == true then
        if not sourceCard or not event or event.defenderUid ~= sourceCard.uid then
            return false
        end
        if (tonumber(event.damageToDefenderFighter) or 0) <= 0 then
            return false
        end
        if (tonumber(event.defenderHpAfter) or 0) <= 0 then
            return false
        end
    end

    if condition.responseAction then
        local actionName = tostring(event and event.actionName or ''):lower()
        if actionName ~= tostring(condition.responseAction):lower() then
            return false
        end
    end

    if type(condition.responseActionsAny) == 'table' then
        local actionName = tostring(event and event.actionName or ''):lower()
        local matched = false
        for _, allowedAction in ipairs(condition.responseActionsAny) do
            if actionName == tostring(allowedAction):lower() then
                matched = true
                break
            end
        end
        if not matched then
            return false
        end
    end

    if condition.sourceType then
        local sourceDef = event and event.sourceCardId and api.getCardDefinition(event.sourceCardId) or nil
        if string.upper(tostring(sourceDef and sourceDef.type or '')) ~= string.upper(tostring(condition.sourceType)) then
            return false
        end
    end

    if condition.sourceTag then
        local sourceDef = event and event.sourceCardId and api.getCardDefinition(event.sourceCardId) or nil
        if not cardHasTag(sourceDef, condition.sourceTag) then
            return false
        end
    end

    if type(condition.sourceTagsAny) == 'table' then
        local sourceDef = event and event.sourceCardId and api.getCardDefinition(event.sourceCardId) or nil
        local matched = false
        for _, wantedTag in ipairs(condition.sourceTagsAny) do
            if cardHasTag(sourceDef, wantedTag) then
                matched = true
                break
            end
        end
        if not matched then
            return false
        end
    end

    if condition.sourceEffectTextContains then
        local sourceDef = event and event.sourceCardId and api.getCardDefinition(event.sourceCardId) or nil
        local text = string.lower(tostring(sourceDef and sourceDef.effectText or ''))
        if text:find(string.lower(tostring(condition.sourceEffectTextContains)), 1, true) == nil then
            return false
        end
    end

    if condition.amountMin and (tonumber(event and event.amount) or 0) < tonumber(condition.amountMin) then
        return false
    end

    if condition.amountMax and (tonumber(event and event.amount) or 0) > tonumber(condition.amountMax) then
        return false
    end

    if condition.actingPlayer then
        local actingPlayer = tonumber(event and event.actingPlayer)
        local wanted = tostring(condition.actingPlayer):lower()
        if wanted == 'self' and actingPlayer ~= sourcePlayerIndex then
            return false
        elseif wanted == 'opponent' and actingPlayer == sourcePlayerIndex then
            return false
        end
    end

    if condition.attackingPlayer then
        local attackingPlayer = tonumber(event and event.attackingPlayer)
        local wanted = tostring(condition.attackingPlayer):lower()
        if wanted == 'self' and attackingPlayer ~= sourcePlayerIndex then
            return false
        elseif wanted == 'opponent' and attackingPlayer == sourcePlayerIndex then
            return false
        end
    end

    if condition.defendingPlayer then
        local defendingPlayer = tonumber(event and event.defendingPlayer)
        local wanted = tostring(condition.defendingPlayer):lower()
        if wanted == 'self' and defendingPlayer ~= sourcePlayerIndex then
            return false
        elseif wanted == 'opponent' and defendingPlayer == sourcePlayerIndex then
            return false
        end
    end

    if condition.summoningPlayer then
        local summoningPlayer = tonumber(event and event.summoningPlayer)
        local wanted = tostring(condition.summoningPlayer):lower()
        if wanted == 'self' and summoningPlayer ~= sourcePlayerIndex then
            return false
        elseif wanted == 'opponent' and summoningPlayer == sourcePlayerIndex then
            return false
        end
    end

    if condition.targetingPlayer then
        local targetingPlayer = tonumber(event and event.targetingPlayer)
        local wanted = tostring(condition.targetingPlayer):lower()
        if wanted == 'self' and targetingPlayer ~= sourcePlayerIndex then
            return false
        elseif wanted == 'opponent' and targetingPlayer == sourcePlayerIndex then
            return false
        end
    end

    if condition.targetReason then
        local reason = tostring(event and event.reason or '')
        if reason ~= tostring(condition.targetReason) then
            return false
        end
    end

    if type(condition.targetZoneAny) == 'table' then
        local targetZone = tostring(event and event.targetZone or '')
        local matched = false
        for _, zone in ipairs(condition.targetZoneAny) do
            if targetZone == tostring(zone) then
                matched = true
                break
            end
        end
        if not matched then return false end
    end

    if condition.targetController then
        local targetPlayerIndex = tonumber(event and event.targetPlayerIndex)
        local wanted = tostring(condition.targetController):lower()
        if wanted == 'self' and targetPlayerIndex ~= sourcePlayerIndex then
            return false
        elseif wanted == 'opponent' and targetPlayerIndex == sourcePlayerIndex then
            return false
        end
    end

    if condition.targetNotSource == true and event and event.targetUid and sourceCard and event.targetUid == sourceCard.uid then
        return false
    end

    if condition.targetIsSource == true and (not event or not sourceCard or event.targetUid ~= sourceCard.uid) then
        return false
    end

    if condition.targetFilter and not cardMatchesFilter(event and event.targetCard, condition.targetFilter, api) then
        return false
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

local function canPayCostAction(duel, sourcePlayerIndex, sourceCard, action, api, event)
    local actionName = normalizeTag(action.action or action.type)
    local playerIndex = getPlayerIndex(action, sourcePlayerIndex, api)
    local player = duel.players[playerIndex]
    if not player then
        return false, 'Cost player not found'
    end

    if actionName == 'lose_lp' or actionName == 'damage_opponent_lp' or actionName == 'pay_lp' or actionName == 'pay_half_lp' then
        local amount = math.max(0, resolveAmount(action, { event = event or {} }))
        if actionName == 'pay_half_lp' then
            amount = math.floor((tonumber(player.lifePoints) or 0) / 2)
        end
        if amount > 0 and (tonumber(player.lifePoints) or 0) < amount then
            return false, 'Not enough LP to pay the cost'
        end
    elseif actionName == 'discard_hand' then
        local amount = math.max(0, resolveAmount(action, { event = event or {} }))
        if #(player.hand or {}) < amount then
            return false, 'Not enough cards in hand to discard'
        end
    elseif actionName == 'discard_matching_hand' then
        local count = 0
        for _, card in ipairs(player.hand or {}) do
            if cardMatchesFilter(card, action.filter or {}, api) then
                count = count + 1
            end
        end
        local required = math.max(1, tonumber(action.amount) or 1)
        if count < required then
            return false, 'Required discard card not found'
        end
    elseif actionName == 'remove_counter' then
        local counter = tostring(action.counter or action.counterId or action.name or '')
        local required = math.max(1, tonumber(action.amount) or 1)
        if counter == '' or not sourceCard or type(sourceCard.counters) ~= 'table' or (tonumber(sourceCard.counters[counter]) or 0) < required then
            return false, 'Not enough counters'
        end
    elseif actionName == 'destroy_card' or actionName == 'banish_card' then
        local uid = action.uid
            or action.targetUid
            or (tostring(action.target or '') == 'event_target' and event and event.targetUid)
            or (sourceCard and sourceCard.uid)
        if not uid or not api.findCardByUid or not api.findCardByUid(duel, uid) then
            return false, 'Required cost card not found'
        end
    end

    return true
end

local function canPayCosts(duel, sourcePlayerIndex, sourceCard, effect, event, api)
    local costs = effect.costs or effect.costActions or {}
    if type(costs) ~= 'table' or #costs == 0 then return true end

    for _, cost in ipairs(costs) do
        local ok, err = canPayCostAction(duel, sourcePlayerIndex, sourceCard, cost, api, event)
        if not ok then
            return false, err
        end
    end

    return true
end

local ACTION_RESPONSE_EVENTS = {
    draw = 'draw',
    draw_until_hand_size = 'draw',
    search_deck_to_hand = 'move_card',
    return_self_to_hand_and_special_summon_from_deck = 'move_card',
    special_summon_from_hand = 'summon',
    special_summon_self_from_graveyard = 'summon',
    discard_named_hand_cards_and_special_summon_self = 'summon',
    tribute_opponent_fighters_for_bunny_and_special_summon_self = 'summon',
    equip_from_deck = 'equip',
    swap_self_with_deck = 'move_card',
    discard_matching_hand = 'discard',
    discard_named_hand_card_then_watch_drawn_type = 'discard',
    discard_hand = 'discard',
    discard_self_from_hand = 'discard',
    cancel_pending_battle = 'battle',
    lethal_battle_damage_survive_1_then_cemetery = 'prevent_damage',
    banish_self_from_graveyard = 'banish',
    banish_card = 'banish',
    destroy_card = 'destroy',
    destroy_all_equipment = 'destroy',
    destroy_all_fighters = 'destroy',
    destroy_first_fighter = 'destroy',
    roll_destroy_first_fighter = 'destroy',
    roll_destroy_attacker = 'destroy',
    select_banish_field_card = 'banish',
    select_discard_hand_branch = 'discard',
    select_graveyard_to_hand = 'move_card',
    select_send_matching_to_graveyard = 'move_card',
    select_hand_to_deck = 'move_card',
    select_return_field_to_hand = 'move_card',
    select_swap_fighter_same_name_from_deck = 'move_card',
    select_special_summon_same_name_from_deck = 'summon',
    select_modify_equipment_bonus = 'stat_change',
    select_move_equipment_to_fighter = 'equip',
    select_take_control_field_cards = 'move_card',
    select_copy_graveyard_fighter_effects = 'copy_effect',
    select_reorder_top_deck_then_draw = 'move_card',
    add_played_type_draw_watcher = 'draw',
    add_counter_to_opponent_fighters = 'status',
    detonate_sticky_bomb_counters = 'destroy',
    shuffle_all_to_deck_and_redraw = 'move_card',
    play_event_from_deck = 'card_played',
    complete_equipment_combo_to_hand = 'move_card',
    banish_lowest_speed_vehicle_and_equipped_fighter = 'banish',
    gain_lp = 'gain_lp',
    gain_lp_per_matching_card = 'gain_lp',
    reveal_hand = 'reveal',
    reveal_random_opponent_hand_card = 'reveal',
    move_random_opponent_hand_to_deck_bottom = 'move_card',
    plant_self_in_opponent_deck = 'move_card',
    modify_equipment_bonus = 'stat_change',
    heal_equipped_fighter = 'heal',
    roll_destroy_self_damage_equipped = 'destroy',
    lose_lp = 'lose_lp',
    pay_half_lp = 'lose_lp',
    damage_opponent_lp = 'lose_lp',
    steal_lp = 'lp_change'
}

local function getActionTargetPlayerIndex(action, sourcePlayerIndex, api)
    local ok, playerIndex = pcall(getPlayerIndex, action or {}, sourcePlayerIndex, api)
    if ok then return playerIndex end
    return sourcePlayerIndex
end

local function buildActionResponseEvent(duel, sourcePlayerIndex, sourceCard, actionName, action, api, context)
    if not action or action.suppressResponseWindow == true or action.noResponseWindow == true then return nil end
    if context and context.event and context.event.suppressActionResponseWindows == true then return nil end

    local responseEvent = normalizeTag(action.responseEvent or ACTION_RESPONSE_EVENTS[actionName])
    if responseEvent == '' or responseEvent == 'summon' then return nil end

    local targetPlayerIndex = getActionTargetPlayerIndex(action, sourcePlayerIndex, api)
    local event = {
        responseEvent = responseEvent,
        trigger = responseEvent,
        actionName = actionName,
        sourceUid = sourceCard and sourceCard.uid or nil,
        sourceCardId = sourceCard and sourceCard.cardId or nil,
        sourcePlayerIndex = sourcePlayerIndex,
        actingPlayer = sourcePlayerIndex,
        targetPlayerIndex = targetPlayerIndex,
        reason = action.reason or 'effect',
        amount = action.amount or action.amountPerCard or action.draw or action.redraw,
        targetUid = action.uid or action.targetUid or (tostring(action.target or '') == 'event_target' and context and context.event and context.event.targetUid) or nil
    }

    if event.targetUid and api and api.findCardByUid then
        local targetCard, _, ownerIndex, zoneName, zoneIndex = api.findCardByUid(duel, event.targetUid)
        event.targetCard = targetCard
        event.targetCardId = targetCard and targetCard.cardId or nil
        event.targetPlayerIndex = ownerIndex or event.targetPlayerIndex
        event.targetZone = zoneName
        event.targetZoneIndex = zoneIndex
    end

    return event
end

local function getActionResponsePrompt(sourceCard, actionName, event)
    local cardName = sourceCard and sourceCard.cardId or 'a card effect'
    local responseEvent = tostring(event and event.responseEvent or actionName or 'effect'):gsub('_', ' ')
    return ('Your opponent is about to resolve %s from %s. Chain a response?'):format(responseEvent, cardName)
end

local function queueRemainingActions(duel, sourcePlayerIndex, sourceCard, actions, event, nextIndex, skipResponseIndex)
    if not duel or not sourceCard or not actions or nextIndex > #actions then return end

    duel.pendingActionQueue = {
        sourcePlayerIndex = sourcePlayerIndex,
        sourceUid = sourceCard.uid,
        sourceCardId = sourceCard.cardId,
        actions = actions,
        event = event or {},
        nextIndex = nextIndex,
        skipResponseIndex = skipResponseIndex
    }
end

local function runActionList(duel, sourcePlayerIndex, sourceCard, actions, event, api, startIndex, skipResponseIndex)
    local context = { event = event or {} }
    startIndex = tonumber(startIndex) or 1
    skipResponseIndex = tonumber(skipResponseIndex)

    for index = startIndex, #actions do
        local action = actions[index]
        local actionName = normalizeTag(action.action or action.type)
        local handler = ACTIONS[actionName]

        if handler then
            if index ~= skipResponseIndex and api and api.triggerActionResponseWindow then
                local responseEvent = buildActionResponseEvent(duel, sourcePlayerIndex, sourceCard, actionName, action, api, context)
                if responseEvent then
                    queueRemainingActions(duel, sourcePlayerIndex, sourceCard, actions, context.event, index, index)
                    if api.triggerActionResponseWindow(duel, sourcePlayerIndex, sourceCard, responseEvent, getActionResponsePrompt(sourceCard, actionName, responseEvent)) then
                        return
                    end
                    duel.pendingActionQueue = nil
                end
            end

            handler(duel, sourcePlayerIndex, sourceCard, action, api, context)
            if duel and (duel.pendingSelection or duel.pendingEffect) then
                queueRemainingActions(duel, sourcePlayerIndex, sourceCard, actions, context.event, index + 1)
                return
            end
        else
            appendLog(duel, ('Unhandled effect action "%s" on %s.'):format(actionName, sourceCard and sourceCard.cardId or 'unknown source'))
        end
    end
end

local function runCostActions(duel, sourcePlayerIndex, sourceCard, effect, event, api)
    local costs = effect.costs or effect.costActions or {}
    if type(costs) ~= 'table' or #costs == 0 then return end

    local costEvent = shallowCopy(event or {})
    costEvent.suppressActionResponseWindows = true
    runActionList(duel, sourcePlayerIndex, sourceCard, costs, costEvent, api, 1)
end

local function runEffectActions(duel, sourcePlayerIndex, sourceCard, effect, event, api)
    local contextEvent = event or {}
    local actions = effect.actions or {}

    if contextEvent.cancelled == true and type(effect.cancelActions) == 'table' then
        actions = effect.cancelActions
    end

    if contextEvent.cancelled ~= true and type(effect.options) == 'table' then
        local selectedOption = tostring(contextEvent.response and contextEvent.response.option or '')
        actions = {}

        for _, option in ipairs(effect.options) do
            if tostring(option.id or option.value or option.key or option.label or '') == selectedOption then
                actions = option.actions or {}
                break
            end
        end
    end

    runActionList(duel, sourcePlayerIndex, sourceCard, actions, contextEvent, api, 1)
end

function DuelEffects.RunActions(duel, sourcePlayerIndex, sourceCard, actions, event, api)
    runEffectActions(duel, sourcePlayerIndex, sourceCard, {
        actions = actions or {}
    }, event or {}, api)
end

function DuelEffects.ResumePendingActions(duel, api)
    if not duel or duel.pendingSelection or duel.pendingEffect or duel.effectChain then return false end

    local pending = duel.pendingActionQueue
    if not pending then return false end

    duel.pendingActionQueue = nil

    local sourceCard = nil
    if api and api.findCardByUid then
        sourceCard = api.findCardByUid(duel, pending.sourceUid)
    end

    if not sourceCard then
        appendLog(duel, ('Could not resume remaining actions for %s.'):format(pending.sourceCardId or 'unknown source'))
        return false
    end

    runActionList(
        duel,
        tonumber(pending.sourcePlayerIndex) or 1,
        sourceCard,
        pending.actions or {},
        pending.event or {},
        api,
        tonumber(pending.nextIndex) or 1,
        tonumber(pending.skipResponseIndex)
    )
    return true
end

function DuelEffects.RunReplacement(duel, triggerName, targetPlayerIndex, event, api)
    if not duel or not api then return { prevented = false } end
    event = event or {}
    event.targetPlayerIndex = tonumber(event.targetPlayerIndex) or targetPlayerIndex

    local function runForCard(playerIndex, card)
        if not card or event.replacementPrevented == true then return end

        local def = api.getCardDefinition(card.cardId)
        for _, entry in ipairs(getEffectList(def, triggerName, card)) do
            local effect = entry.effect
            if passesCondition(duel, playerIndex, card, effect, event, api) then
                local costOk = canPayCosts(duel, playerIndex, card, effect, event, api)
                if not costOk then return end
                runCostActions(duel, playerIndex, card, effect, event, api)
                if not duel.pendingSelection and not duel.pendingEffect then
                    runEffectActions(duel, playerIndex, card, effect, event, api)
                end
                if event.replacementPrevented == true then
                    return
                end
            end
        end
    end

    for _, playerIndex in ipairs({ targetPlayerIndex, api.getOpponentIndex(targetPlayerIndex) }) do
        local player = duel.players[playerIndex]
        if player then
            for _, card in ipairs(player.hand or {}) do
                runForCard(playerIndex, card)
            end

            for _, zone in ipairs({ player.fighterZones, player.itemZones }) do
                for _, card in pairs(zone or {}) do
                    runForCard(playerIndex, card)
                end
            end

            for _, slot in pairs(player.equipmentZones or {}) do
                if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                    for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                        runForCard(playerIndex, slot[key])
                    end
                else
                    runForCard(playerIndex, slot)
                end
            end

            runForCard(playerIndex, player.locationZone)
        end
    end

    return {
        prevented = event.replacementPrevented == true,
        sourceUid = event.replacementSourceUid,
        sourceCardId = event.replacementSourceCardId
    }
end

function DuelEffects.IsTargetProtected(duel, targetingPlayerIndex, targetPlayerIndex, targetCard, event, api)
    if not duel or not targetCard or not api then return false end

    event = event or {}
    event.targetingPlayer = tonumber(targetingPlayerIndex)
    event.targetPlayerIndex = tonumber(targetPlayerIndex)
    event.targetUid = targetCard.uid
    event.targetCard = targetCard
    event.targetCardId = targetCard.cardId
    event.reason = event.reason or 'card_effect'

    if (not event.targetZone or event.targetZone == '') and api.findCardByUid then
        local _, _, _, zoneName, zoneIndex = api.findCardByUid(duel, targetCard.uid)
        event.targetZone = zoneName
        event.targetZoneIndex = zoneIndex
    end

    local function runForCard(playerIndex, card)
        if not card or event.targetingPrevented == true then return end

        local def = api.getCardDefinition(card.cardId)
        for _, entry in ipairs(getEffectList(def, 'would_be_targeted', card)) do
            local effect = entry.effect
            if passesCondition(duel, playerIndex, card, effect, event, api) then
                runEffectActions(duel, playerIndex, card, effect, event, api)
                if event.targetingPrevented == true then
                    return
                end
            end
        end
    end

    for _, playerIndex in ipairs({ targetPlayerIndex, api.getOpponentIndex(targetPlayerIndex) }) do
        local player = duel.players[playerIndex]
        if player then
            for _, zone in ipairs({ player.fighterZones, player.itemZones }) do
                for _, card in pairs(zone or {}) do runForCard(playerIndex, card) end
            end
            for _, slot in pairs(player.equipmentZones or {}) do
                if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                    for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                        runForCard(playerIndex, slot[key])
                    end
                else
                    runForCard(playerIndex, slot)
                end
            end
            runForCard(playerIndex, player.locationZone)
        end
    end

    return event.targetingPrevented == true
end

function DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, sourceCard, event, api, options)
    if not duel or not sourceCard or not api then return 0 end

    local def = api.getCardDefinition(sourceCard.cardId)
    local effects = getEffectList(def, triggerName, sourceCard)
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
            local costOk, costErr = canPayCosts(duel, sourcePlayerIndex, sourceCard, effect, event, api)
            if not costOk then
                appendLog(duel, ('Effect %s on %s cannot pay cost: %s.'):format(entry.index, sourceCard.cardId, costErr or 'cost failed'))
            elseif isOptionalEffect(def, effect) and not options.force then
                if api.queueEffectPrompt then
                    local queued = api.queueEffectPrompt(duel, sourcePlayerIndex, sourceCard, triggerName, entry.index, {
                        title = def and (def.effectTitle or def.name) or 'Effect',
                        text = getEffectPrompt(def, effect),
                        effectText = def and def.effectText or nil,
                        form = effect.form,
                        confirmText = effect.confirmText,
                        cancelText = effect.cancelText,
                        runCancelActions = type(effect.cancelActions) == 'table'
                    })
                    if queued then
                        activated = activated + 1
                    end
                end
            else
                runCostActions(duel, sourcePlayerIndex, sourceCard, effect, event, api)
                if duel.pendingSelection or duel.pendingEffect then
                    activated = activated + 1
                    return activated
                end
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
    local effect = getEffectByIndex(def, effectIndex, sourceCard)
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

    if effect.promptPlayer and not (event and event.prompted == true) then
        local promptPlayerIndex = sourcePlayerIndex
        if tostring(effect.promptPlayer):lower() == 'opponent' then
            promptPlayerIndex = api.getOpponentIndex(sourcePlayerIndex)
        end

        if api.queueEffectPrompt then
            api.queueEffectPrompt(duel, promptPlayerIndex, sourceCard, effect.trigger or 'activated', effectIndex, {
                title = effect.promptTitle or 'Choose Effect',
                text = effect.promptText or 'Choose how this effect resolves.',
                effectText = def and def.effectText or nil,
                form = effect.form,
                confirmText = effect.confirmText,
                cancelText = effect.cancelText,
                sourcePlayerIndex = sourcePlayerIndex
            })
            return true
        end
    end

    local costOk, costErr = canPayCosts(duel, sourcePlayerIndex, sourceCard, effect, event, api)
    if not costOk then
        return false, costErr or 'Cost could not be paid'
    end

    runCostActions(duel, sourcePlayerIndex, sourceCard, effect, event, api)
    if duel.pendingSelection or duel.pendingEffect then
        return true
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

function DuelEffects.GetResponseChoices(duel, playerIndex, event, api)
    local choices = {}
    if not duel or not api then return choices end

    local player = duel.players[playerIndex]
    if not player then return choices end

    local function addCardChoices(card)
        if not card then return end
        local def = api.getCardDefinition(card.cardId)
        for _, entry in ipairs(getEffectList(def, 'response', card)) do
            local effect = entry.effect
            if responseZoneAllowed(effect, card) and passesCondition(duel, playerIndex, card, effect, event, api) then
                local cardName = def and def.name or card.cardId
                local effectName = def and (def.effectTitle or def.name) or 'Effect'
                choices[#choices + 1] = {
                    id = ('%s:%s'):format(card.uid, entry.index),
                    label = ('%s - %s'):format(cardName, effectName),
                    description = effect.promptText or def and def.effectText or 'Activate this response.',
                    sourceUid = card.uid,
                    effectIndex = entry.index,
                    cardName = cardName
                }
            end
        end
    end

    for _, card in ipairs(player.hand or {}) do addCardChoices(card) end
    for _, card in ipairs(player.graveyard or {}) do addCardChoices(card) end
    for _, card in ipairs(player.banished or {}) do addCardChoices(card) end
    for _, zone in ipairs({ player.fighterZones, player.itemZones }) do
        for _, card in pairs(zone or {}) do addCardChoices(card) end
    end
    for _, slot in pairs(player.equipmentZones or {}) do
        if slot and (slot.vehicle or slot.weapon or slot.equipment) then
            for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                addCardChoices(slot[key])
            end
        else
            addCardChoices(slot)
        end
    end
    addCardChoices(player.locationZone)

    return choices
end

function DuelEffects.ResolveResponseFrame(duel, frame, api)
    if not duel or not frame or not api then return false, 'Invalid response frame' end

    local sourcePlayerIndex = tonumber(frame.playerIndex)
    local sourceCard = api.findCardByUid and api.findCardByUid(duel, frame.sourceUid) or nil
    if not sourcePlayerIndex or not sourceCard then
        return false, 'Response source no longer exists'
    end

    return DuelEffects.RunEffectByIndex(duel, sourcePlayerIndex, sourceCard, frame.effectIndex, frame.event or {}, api)
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
            if card and (not event or not event.skipSourceUid or card.uid ~= event.skipSourceUid) then
                activated = activated + DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, card, event, api)
            end
        end
    end

    for _, slot in pairs(player.equipmentZones or {}) do
        if slot and (slot.vehicle or slot.weapon or slot.equipment) then
            for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                local card = slot[key]
                if card and (not event or not event.skipSourceUid or card.uid ~= event.skipSourceUid) then
                    activated = activated + DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, card, event, api)
                end
            end
        elseif slot and (not event or not event.skipSourceUid or slot.uid ~= event.skipSourceUid) then
            activated = activated + DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, slot, event, api)
        end
    end

    if player.locationZone and (not event or not event.skipSourceUid or player.locationZone.uid ~= event.skipSourceUid) then
        activated = activated + DuelEffects.RunTrigger(duel, triggerName, sourcePlayerIndex, player.locationZone, event, api)
    end

    return activated
end
