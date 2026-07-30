local QBCore = exports['qb-core']:GetCoreObject()

Duel = Duel or {}
Duel.Active = Duel.Active or {}

local duelCounter = 0
local getEffectApi
local moveFieldCardToGraveyard
local queueEffectPrompt
local activateNextQueuedEffectPrompt
local startResponseWindow
local startResponseWindowOrRunContinuation
local triggerSummonResponseWindow
local triggerActionResponseWindow
local continuePendingBattle
local continuePendingDuelAction
local queueDeckSearch
local getCardStat
local getFighterBattleAttackLimit
local getEquipmentSlotKey
local isEquipmentBundle
local getEquipmentCardAt
local setEquipmentCardAt
local eachEquipmentCard
local moveEquipmentAtToGraveyard
local moveCardByUidToGraveyard
local banishCardByUid
local removeCardByUid
local applyLifePointLoss
local refreshContinuousModifiers
local scheduleDelayedTask
local queueCardSelection
local fireSentToCemeteryTrigger
local addSpecialSummonDrawWatcher
local processSpecialSummonDrawWatchers
local addPlayedTypeDrawWatcher
local processPlayedTypeDrawWatchers
local rebuildEquipmentModifiers

local function makeDuelId()
    duelCounter = duelCounter + 1
    return ("DUEL_%s_%s"):format(os.time(), duelCounter)
end

local function shallowCopy(tbl)
    local newTbl = {}
    for k, v in pairs(tbl or {}) do
        newTbl[k] = v
    end
    return newTbl
end

local CardLookupAliases = nil

local function normalizeCardLookupKey(value)
    value = tostring(value or ''):upper()
    value = value:gsub('[^A-Z0-9]+', '_')
    value = value:gsub('_+', '_')
    value = value:gsub('^_', ''):gsub('_$', '')
    return value
end

local function addCardLookupAlias(aliases, alias, card)
    alias = normalizeCardLookupKey(alias)
    if alias ~= '' and not aliases[alias] then
        aliases[alias] = card
    end
end

local function buildCardLookupAliases()
    local aliases = {}
    local nameCounts = {}
    local cardsByName = {}

    for cardId, card in pairs(Cards or {}) do
        addCardLookupAlias(aliases, cardId, card)
        addCardLookupAlias(aliases, card and card.id, card)
        addCardLookupAlias(aliases, card and card.setCode, card)

        local setCode = card and card.setCode or nil
        local name = card and card.name or nil
        if setCode and name then
            addCardLookupAlias(aliases, ("%s_%s"):format(setCode, name), card)
        end

        local nameKey = normalizeCardLookupKey(name)
        if nameKey ~= '' then
            nameCounts[nameKey] = (nameCounts[nameKey] or 0) + 1
            cardsByName[nameKey] = card
        end
    end

    for nameKey, count in pairs(nameCounts) do
        if count == 1 then
            aliases[nameKey] = cardsByName[nameKey]
        end
    end

    return aliases
end

local function resolveCardDefinition(cardId)
    if Cards and Cards[cardId] then
        return Cards[cardId]
    end

    CardLookupAliases = CardLookupAliases or buildCardLookupAliases()
    local card = CardLookupAliases[normalizeCardLookupKey(cardId)]
    if card then return card end

    local normalized = normalizeCardLookupKey(cardId)
    local nameSuffix = normalized:match('^[A-Z]+%d*_EN%d%d%d_(.+)$')
    if nameSuffix then
        card = CardLookupAliases[nameSuffix]
        if card then return card end
    end

    local setPrefix = normalized:match('^([A-Z]+%d*_EN%d%d%d)')
    if setPrefix then
        return CardLookupAliases[setPrefix]
    end

    return nil
end

local function normalizeDeckData(deckData)
    if type(deckData) ~= 'table' then
        return { cards = {} }
    end

    if type(deckData.cards) ~= 'table' then
        deckData.cards = {}
    end

    return deckData
end

local function buildDeckInstancesFromDeckData(deckData, ownerIndex)
    local instances = {}
    local uidCounter = 0

    deckData = normalizeDeckData(deckData)

    for cardId, amount in pairs(deckData.cards) do
        local count = tonumber(amount) or 0

        for i = 1, count do
            uidCounter = uidCounter + 1

            instances[#instances + 1] = {
                uid = ("%s_%s_%s"):format(ownerIndex, cardId, uidCounter),
                cardId = cardId,
                owner = ownerIndex,
                controller = ownerIndex,
                zone = "deck",
                hasAttacked = false
            }
        end
    end

    return instances
end

local function shuffleList(list)
    for i = #list, 2, -1 do
        local j = math.random(1, i)
        list[i], list[j] = list[j], list[i]
    end
end

local function getPlayerIndexesBySource(duel, src)
    local indexes = {}

    for index, player in pairs(duel.players or {}) do
        if player.source == src then
            indexes[#indexes + 1] = index
        end
    end

    return indexes
end

local function getControllingPlayerIndex(duel, src)
    local indexes = getPlayerIndexesBySource(duel, src)

    if #indexes == 0 then
        return nil
    end

    -- solo/self-test duel: same player controls both sides
    if #indexes > 1 then
        return duel.turnPlayer
    end

    return indexes[1]
end

local function getOpponentIndex(playerIndex)
    return playerIndex == 1 and 2 or 1
end

local function findCardInZoneByUid(playerState, zoneName, uid)
    local zone = playerState[zoneName]
    if type(zone) ~= 'table' then return nil, nil end

    for i = 1, #zone do
        if zone[i] and zone[i].uid == uid then
            return zone[i], i
        end
    end

    return nil, nil
end

local function findFieldCardByUid(playerState, uid)
    for zoneIndex, card in pairs(playerState.fighterZones or {}) do
        if card and card.uid == uid then
            return card, 'fighterZones', zoneIndex
        end
    end

    for zoneIndex, card in pairs(playerState.itemZones or {}) do
        if card and card.uid == uid then
            return card, 'itemZones', zoneIndex
        end
    end

    for zoneIndex, card in pairs(playerState.equipmentZones or {}) do
        if isEquipmentBundle(card) then
            for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                if card[key] and card[key].uid == uid then
                    return card[key], 'equipmentZones', zoneIndex
                end
            end
        elseif card and card.uid == uid then
            return card, 'equipmentZones', zoneIndex
        end
    end

    if playerState.locationZone and playerState.locationZone.uid == uid then
        return playerState.locationZone, 'locationZone', 1
    end

    return nil, nil, nil
end

local function findPlayerCardByUid(playerState, uid)
    local card, zoneName, zoneIndex = findFieldCardByUid(playerState, uid)
    if card then return card, zoneName, zoneIndex end

    for _, listZoneName in ipairs({ 'hand', 'graveyard', 'banished', 'deck' }) do
        card, zoneIndex = findCardInZoneByUid(playerState, listZoneName, uid)
        if card then
            return card, listZoneName, zoneIndex
        end
    end

    return nil, nil, nil
end

local function findCardByUid(duel, uid)
    for playerIndex, playerState in pairs(duel and duel.players or {}) do
        local card, zoneName, zoneIndex = findPlayerCardByUid(playerState, uid)
        if card then
            return card, playerState, playerIndex, zoneName, zoneIndex
        end
    end

    return nil, nil, nil, nil, nil
end

local function getPlayerIndexForState(duel, playerState)
    for playerIndex, currentPlayerState in pairs(duel and duel.players or {}) do
        if currentPlayerState == playerState then
            return playerIndex
        end
    end

    return nil
end

local function getCardDefinition(cardId)
    return resolveCardDefinition(cardId)
end

local function cardHasStatus(card, statusId)
    local wanted = string.lower(tostring(statusId or ''))
    if wanted == '' then return false end

    for _, status in ipairs(card and card.statuses or {}) do
        local id = string.lower(tostring(status.id or status.name or ''))
        if id == wanted then
            return true
        end
    end

    return false
end

local function consumeCardStatus(card, statusId)
    local wanted = string.lower(tostring(statusId or ''))
    if wanted == '' or type(card and card.statuses) ~= 'table' then return false end

    for index, status in ipairs(card.statuses) do
        local id = string.lower(tostring(status.id or status.name or ''))
        if id == wanted then
            table.remove(card.statuses, index)
            return true
        end
    end

    return false
end

local function parseStatValue(raw)
    if type(raw) == 'number' then
        return raw
    end

    if type(raw) == 'string' then
        local match = string.match(raw, "-?%d+")
        return match and tonumber(match) or 0
    end

    return 0
end

local function getCardBaseHp(card)
    local def = card and getCardDefinition(card.cardId) or nil
    if not def then return 0 end

    return parseStatValue(def.health or def.hp or def.defense or def.def)
end

local function getCardHealthText(def)
    local raw = def and (def.health or def.hp or def.defense or def.def) or nil
    if not raw then return nil end

    return tostring(raw):gsub('^DEF', 'HP')
end

local function cardActivationZoneAllowed(effect, card)
    local zone = tostring(card and card.zone or '')
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

local function cardActivationConditionMet(duel, playerIndex, card, effect)
    local condition = effect and effect.condition or nil
    if type(condition) ~= 'table' then return true end

    if condition.ownLpLowerThanOpponent == true then
        local player = duel and duel.players and duel.players[playerIndex] or nil
        local opponent = duel and duel.players and duel.players[getOpponentIndex(playerIndex)] or nil
        if not player or not opponent or (tonumber(player.lifePoints) or 0) >= (tonumber(opponent.lifePoints) or 0) then
            return false
        end
    end

    if condition.sourceCounterMin then
        local counterReq = condition.sourceCounterMin
        local counter = tostring(counterReq.counter or counterReq.counterId or counterReq.name or '')
        local required = math.max(1, tonumber(counterReq.amount or counterReq.count or counterReq.min) or 1)
        if counter == '' or not card or type(card.counters) ~= 'table' or (tonumber(card.counters[counter]) or 0) < required then
            return false
        end
    end

    if condition.ownControlsNameContains then
        local player = duel and duel.players and duel.players[playerIndex] or nil
        local needle = string.lower(tostring(condition.ownControlsNameContains))
        local found = false

        for i = 1, 3 do
            local fighter = player and player.fighterZones and player.fighterZones[i] or nil
            local def = fighter and getCardDefinition(fighter.cardId) or nil
            local nameText = string.lower(tostring(def and def.name or ''))
            local cardIdOk = not condition.ownControlsNotCardId or tostring(fighter and fighter.cardId) ~= tostring(condition.ownControlsNotCardId)
            if cardIdOk and nameText:find(needle, 1, true) ~= nil then
                found = true
                break
            end
        end

        if not found then return false end
    end

    return true
end

local function hasAvailableActivatedEffect(card, duel, playerIndex)
    local def = card and getCardDefinition(card.cardId) or nil
    if not def or type(def.effects) ~= 'table' then
        return false
    end

    for index, effect in ipairs(def.effects) do
        if tostring(effect.trigger or ''):lower() == 'activated' and cardActivationZoneAllowed(effect, card) then
            local effectKey = tostring(effect.oncePerTurnKey or index)
            local usedPerGame = effect.oncePerGame == true
                and card.usedEffects
                and card.usedEffects[tostring(index)] == true
            local usedThisTurn = effect.oncePerTurn == true
                and duel
                and card.usedEffectTurns
                and card.usedEffectTurns[effectKey] == duel.turnNumber

            if not usedPerGame and not usedThisTurn and cardActivationConditionMet(duel, playerIndex, card, effect) then
                return true
            end
        end
    end

    return false
end

local function isCardActivatable(card, duel, playerIndex)
    local def = card and getCardDefinition(card.cardId) or nil
    if playerIndex and card and card.owner ~= playerIndex and card.controller ~= playerIndex then
        return false
    end
    return def and hasAvailableActivatedEffect(card, duel, playerIndex) or false
end

local function ensureFighterHp(card)
    if not card then return end

    local baseHp = getCardBaseHp(card)
    if baseHp <= 0 then return end

    card.maxHp = tonumber(card.maxHp) or baseHp
    card.currentHp = tonumber(card.currentHp) or card.maxHp

    if card.currentHp > card.maxHp then
        card.currentHp = card.maxHp
    end
end

local function resetFighterHp(card)
    if not card then return end

    local baseHp = getCardBaseHp(card)
    card.maxHp = baseHp
    card.currentHp = baseHp
end

local function buildCardPayload(cardInstance, duel, viewerIndex)
    local def = getCardDefinition(cardInstance.cardId)
    local cardType = string.upper(tostring(def and def.type or ''))
    local attackText = def and (def.attack or def.atk) or nil
    local speedText = def and (def.speed or def.spd) or nil
    local baseAttack = parseStatValue(def and (def.attack or def.atk) or nil)
    local baseHp = def and getCardBaseHp(cardInstance) or 0
    local baseSpeed = parseStatValue(def and (def.speed or def.spd) or nil)

    if cardType == 'FIGHTER' and getCardStat then
        attackText = ('ATK: %s'):format(getCardStat(cardInstance, 'attack'))
        speedText = ('SPD: %s'):format(getCardStat(cardInstance, 'speed'))
    end

    return {
        uid = cardInstance.uid,
        cardId = cardInstance.cardId,
        owner = cardInstance.owner,
        controller = cardInstance.controller,
        zone = cardInstance.zone,
        hasAttacked = cardInstance.hasAttacked or false,
        attacksThisTurn = tonumber(cardInstance.attacksThisTurn) or 0,
        maxAttacksThisTurn = getFighterBattleAttackLimit and getFighterBattleAttackLimit(duel and duel.players and duel.players[cardInstance.controller or cardInstance.owner], cardInstance) or 1,

        name = def and def.name or cardInstance.cardId,
        inventoryImage = def and def.inventoryImage or nil,
        rarity = def and def.rarity or nil,
        type = def and def.type or nil,
        job = def and def.job or nil,
        level = def and def.level or nil,
        attack = attackText,
        baseAttack = baseAttack,
        defense = def and (def.defense or def.def) or nil,
        hp = cardInstance.currentHp,
        maxHp = cardInstance.maxHp,
        baseHp = baseHp,
        health = getCardHealthText(def),
        speed = speedText,
        baseSpeed = baseSpeed,
        effectTitle = def and def.effectTitle or nil,
        effectText = def and def.effectText or nil,
        effectTags = DuelEffects and DuelEffects.GetTags(def) or {},
        statuses = cardInstance.statuses or {},
        counters = cardInstance.counters or {},
        continuous = def and (def.continuous == true or def.isContinuous == true) or false,
        activatableEffect = isCardActivatable(cardInstance, duel, viewerIndex),
        setCode = def and def.setCode or nil,
        edition = def and def.edition or nil
    }
end

local function buildCardPayloadList(cardList, duel, viewerIndex)
    local payload = {}

    for i = 1, #(cardList or {}) do
        payload[#payload + 1] = buildCardPayload(cardList[i], duel, viewerIndex)
    end

    return payload
end

local function buildZonePayload(zone, duel, viewerIndex)
    local payload = {}

    for i = 1, #(zone or {}) do
        if zone[i] then
            payload[i] = buildCardPayload(zone[i], duel, viewerIndex)
        else
            payload[i] = nil
        end
    end

    return payload
end

local function buildFixedZonePayload(zone, count, duel, viewerIndex)
    local payload = {}

    for i = 1, count do
        if zone and zone[i] then
            payload[i] = buildCardPayload(zone[i], duel, viewerIndex)
        else
            payload[i] = nil
        end
    end

    return payload
end

local function buildEquipmentZonePayload(zone, count, duel, viewerIndex)
    local payload = {}

    for i = 1, count do
        local slot = zone and zone[i] or nil
        if isEquipmentBundle(slot) then
            local entry = { cards = {} }

            for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                if slot[key] then
                    entry[key] = buildCardPayload(slot[key], duel, viewerIndex)
                    entry.cards[#entry.cards + 1] = entry[key]
                end
            end

            payload[i] = #entry.cards > 0 and entry or nil
        elseif slot then
            payload[i] = buildCardPayload(slot, duel, viewerIndex)
        else
            payload[i] = nil
        end
    end

    return payload
end

local function getCardTypeValue(card)
    local def = card and getCardDefinition(card.cardId) or nil
    return string.upper(tostring(def and def.type or ''))
end

local function isItemZoneCardType(cardType)
    return cardType == 'ITEM' or cardType == 'CONTINUOUS EVENT'
end

local function isEquipmentZoneCardType(cardType)
    return cardType == 'VEHICLE' or cardType == 'WEAPON' or cardType == 'EQUIPMENT'
end

getEquipmentSlotKey = function(cardOrType)
    if type(cardOrType) == 'table' and cardOrType.forcedEquipmentSlot then
        return tostring(cardOrType.forcedEquipmentSlot)
    end
    local cardType = type(cardOrType) == 'table' and getCardTypeValue(cardOrType) or string.upper(tostring(cardOrType or ''))
    if cardType == 'VEHICLE' then return 'vehicle' end
    if cardType == 'WEAPON' then return 'weapon' end
    if cardType == 'EQUIPMENT' then return 'equipment' end
    return nil
end

isEquipmentBundle = function(value)
    return type(value) == 'table' and (value.vehicle ~= nil or value.weapon ~= nil or value.equipment ~= nil)
end

getEquipmentCardAt = function(playerState, zoneIndex, slotKey)
    local slot = playerState and playerState.equipmentZones and playerState.equipmentZones[zoneIndex] or nil
    if not slot then return nil end

    if isEquipmentBundle(slot) then
        return slot[slotKey]
    end

    if getEquipmentSlotKey(slot) == slotKey then
        return slot
    end

    return nil
end

setEquipmentCardAt = function(playerState, zoneIndex, slotKey, card)
    if not playerState or not playerState.equipmentZones or not zoneIndex or not slotKey then return end

    local slot = playerState.equipmentZones[zoneIndex]
    if slot and not isEquipmentBundle(slot) then
        local oldKey = getEquipmentSlotKey(slot)
        slot = oldKey and { [oldKey] = slot } or {}
    elseif not slot then
        slot = {}
    end

    slot[slotKey] = card
    if slot.vehicle or slot.weapon or slot.equipment then
        playerState.equipmentZones[zoneIndex] = slot
    else
        playerState.equipmentZones[zoneIndex] = nil
    end
end

eachEquipmentCard = function(playerState, callback)
    for zoneIndex, slot in pairs(playerState and playerState.equipmentZones or {}) do
        if isEquipmentBundle(slot) then
            for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                if slot[key] then
                    callback(slot[key], zoneIndex, key)
                end
            end
        elseif slot then
            callback(slot, zoneIndex, getEquipmentSlotKey(slot))
        end
    end
end

local function cardDefHasTag(cardDef, targetTag)
    targetTag = tostring(targetTag or ''):lower()

    for _, tag in ipairs(cardDef and cardDef.cardTags or {}) do
        if tostring(tag or ''):lower() == targetTag then
            return true
        end
    end

    for _, tag in ipairs(cardDef and cardDef.effectTags or {}) do
        if tostring(tag or ''):lower() == targetTag then
            return true
        end
    end

    return false
end

local function equipmentTargetMatches(cardDef, filter)
    if type(filter) ~= 'table' then return true end

    local nameText = string.lower(tostring(cardDef and cardDef.name or ''))
    local jobText = string.lower(tostring(cardDef and cardDef.job or ''))

    if filter.nameContains and nameText:find(string.lower(tostring(filter.nameContains)), 1, true) == nil then
        return false
    end

    if filter.jobContains and jobText:find(string.lower(tostring(filter.jobContains)), 1, true) == nil then
        return false
    end

    if type(filter.jobContainsAny) == 'table' then
        local found = false
        for _, value in ipairs(filter.jobContainsAny) do
            if jobText:find(string.lower(tostring(value)), 1, true) ~= nil then
                found = true
                break
            end
        end
        if not found then return false end
    end

    if filter.cardTag and not cardDefHasTag(cardDef, filter.cardTag) then
        return false
    end

    if type(filter.cardTagsAny) == 'table' then
        local found = false
        for _, value in ipairs(filter.cardTagsAny) do
            if cardDefHasTag(cardDef, value) then
                found = true
                break
            end
        end
        if not found then return false end
    end

    return true
end

local function isContinuousItemCard(card)
    local def = card and getCardDefinition(card.cardId) or nil
    if not def then return false end
    local text = tostring(def.effectText or ''):lower()

    return def.continuous == true
        or def.isContinuous == true
        or cardDefHasTag(def, 'continuous')
        or cardDefHasTag(def, 'continuous_item')
        or text:find('once per turn', 1, true) ~= nil
        or text:find('while this card is on the field', 1, true) ~= nil
        or text:find('each turn', 1, true) ~= nil
end

local function loseByDeckOut(duel, playerIndex)
    duel.status = "finished"
    duel.winner = getOpponentIndex(playerIndex)
    duel.winReason = "deck_out"
end

local function drawCards(duel, playerIndex, amount, options)
    local player = duel.players[playerIndex]
    if not player then return 0 end
    if duel.status == "finished" then return 0 end

    options = options or {}
    local drawn = 0

    for i = 1, amount do
        if #player.deck == 0 then
            loseByDeckOut(duel, playerIndex)
            break
        end

        local card = table.remove(player.deck, 1)
        card.zone = "hand"
        player.hand[#player.hand + 1] = card
        drawn = drawn + 1

        local skipNormalDrawTriggers = false
        if card.plantedWadeTrap == true then
            table.remove(player.hand, #player.hand)
            local ownerIndex = tonumber(card.owner) or tonumber(card.plantedOwnerIndex)
            local ownerState = ownerIndex and duel.players[ownerIndex] or nil
            applyLifePointLoss(duel, playerIndex, tonumber(card.plantedLpLoss) or 80, {
                reason = 'wade_trap',
                sourceUid = card.uid,
                sourceCardId = card.cardId,
                targetPlayerIndex = playerIndex
            })
            if ownerState then
                drawCards(duel, ownerIndex, tonumber(card.plantedOwnerDraw) or 1, { suppressDrawnTypeWatchers = true })
                card.zone = 'graveyard'
                card.controller = ownerIndex
                card.plantedWadeTrap = nil
                ownerState.graveyard[#ownerState.graveyard + 1] = card
            end
            skipNormalDrawTriggers = true
        end

        if not skipNormalDrawTriggers and not options.suppressDrawnTypeWatchers and type(player.drawnTypeWatchers) == 'table' then
            local def = getCardDefinition(card.cardId)
            local drawnType = string.upper(tostring(def and def.type or ''))
            local remainingWatchers = {}
            for _, watcher in ipairs(player.drawnTypeWatchers) do
                local expired = tonumber(duel.turnNumber) > tonumber(watcher.expiresTurnNumber)
                if not expired then
                    remainingWatchers[#remainingWatchers + 1] = watcher
                    if drawnType ~= '' and drawnType == string.upper(tostring(watcher.cardType or '')) then
                        drawCards(duel, playerIndex, tonumber(watcher.amount) or 1, { suppressDrawnTypeWatchers = true })
                        duel.log = duel.log or {}
                        duel.log[#duel.log + 1] = {
                            turn = duel.turnNumber,
                            phase = duel.phase,
                            message = ('Player %s drew %s extra card(s) from a drawn-type watcher.'):format(playerIndex, watcher.amount or 1)
                        }
                    end
                end
            end
            player.drawnTypeWatchers = remainingWatchers
        end

        if not skipNormalDrawTriggers and DuelEffects and getEffectApi then
            DuelEffects.RunFieldTrigger(duel, 'on_draw', playerIndex, {
                drawnCard = card
            }, getEffectApi())
        end
    end

    return drawn
end

local function moveHandCardToGraveyard(playerState, handIndex, duel, options)
    local card = table.remove(playerState.hand, handIndex)
    if not card then return nil end

    card.zone = "graveyard"
    playerState.graveyard[#playerState.graveyard + 1] = card
    fireSentToCemeteryTrigger(duel, playerState, card, options)
    return card
end

local function resetTurnFlags(playerState)
    playerState.hasSummonedThisTurn = false
    playerState.summonsThisTurn = 0

    for _, zoneCard in pairs(playerState.fighterZones) do
        if zoneCard then
            zoneCard.hasAttacked = false
            zoneCard.attacksThisTurn = 0
            zoneCard.copiedEffects = nil
            zoneCard.copiedEffectSourceCardId = nil
            if zoneCard.turnStatModifiers and zoneCard.turnStatModifiers.hp then
                local hpMod = tonumber(zoneCard.turnStatModifiers.hp) or 0
                zoneCard.maxHp = math.max(0, (tonumber(zoneCard.maxHp) or 0) - hpMod)
                if (tonumber(zoneCard.currentHp) or 0) > (tonumber(zoneCard.maxHp) or 0) then
                    zoneCard.currentHp = zoneCard.maxHp
                end
            end
            zoneCard.turnStatModifiers = nil
            ensureFighterHp(zoneCard)
        end
    end

    for zoneIndex, slot in pairs(playerState.equipmentZones or {}) do
        local changed = false
        if type(slot) == 'table' then
            for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                local equipmentCard = slot[key]
                if equipmentCard and equipmentCard.turnStatModifiers then
                    equipmentCard.turnStatModifiers = nil
                    changed = true
                end
            end

            if slot.uid and slot.turnStatModifiers then
                slot.turnStatModifiers = nil
                changed = true
            end
        end

        if changed and rebuildEquipmentModifiers then
            rebuildEquipmentModifiers(playerState, zoneIndex)
        end
    end
end

local function resetBattleFlags(playerState)
    for _, zoneCard in pairs(playerState.fighterZones) do
        if zoneCard then
            zoneCard.hasAttacked = false
            zoneCard.attacksThisTurn = 0
        end
    end
end

local function buildPrivateStateForPlayer(duel, viewerIndex)
    local selfState = duel.players[viewerIndex]
    local oppIndex = getOpponentIndex(viewerIndex)
    local oppState = duel.players[oppIndex]
    local waitingEffect = nil
    if duel.pendingEffect and duel.pendingEffect.playerIndex ~= viewerIndex then
        waitingEffect = {
            playerIndex = duel.pendingEffect.playerIndex,
            title = duel.pendingEffect.title or 'Pending Response',
            text = duel.pendingEffect.responseWindow == true
                and 'Waiting for your opponent to choose a response.'
                or 'Waiting for your opponent to resolve an effect.',
            responseWindow = duel.pendingEffect.responseWindow == true
        }
    end

    return {
        duelId = duel.id,
        tableId = duel.tableId,
        tableMode = duel.tableId ~= nil,    
        status = duel.status,
        phase = duel.phase,
        turnPlayer = duel.turnPlayer,
        turnNumber = duel.turnNumber,
        viewerIndex = viewerIndex,
        winner = duel.winner,
        winReason = duel.winReason,
        hasDrawnThisTurn = duel.hasDrawnThisTurn == true,
        firstTurnPlayer = duel.firstTurnPlayer,
        waitingEffect = waitingEffect,
        pendingEffect = duel.pendingEffect and duel.pendingEffect.playerIndex == viewerIndex and {
            id = duel.pendingEffect.id,
            sourceUid = duel.pendingEffect.sourceUid,
            cardName = duel.pendingEffect.cardName,
            title = duel.pendingEffect.title,
            text = duel.pendingEffect.text,
            effectText = duel.pendingEffect.effectText,
            form = duel.pendingEffect.form,
            confirmText = duel.pendingEffect.confirmText,
            cancelText = duel.pendingEffect.cancelText
        } or nil,
        pendingSelection = duel.pendingSelection and duel.pendingSelection.playerIndex == viewerIndex and {
            id = duel.pendingSelection.id,
            title = duel.pendingSelection.title,
            text = duel.pendingSelection.text,
            minChoices = duel.pendingSelection.minChoices,
            maxChoices = duel.pendingSelection.maxChoices,
            choices = duel.pendingSelection.choices
        } or nil,

        selfPlayer = {
            source = selfState.source,
            deckCount = #selfState.deck,
            hand = buildCardPayloadList(selfState.hand, duel, viewerIndex),
            graveyardCount = #selfState.graveyard,
            banishedCount = #(selfState.banished or {}),
            fighterZones = buildFixedZonePayload(selfState.fighterZones, 3, duel, viewerIndex),
            itemZones = buildFixedZonePayload(selfState.itemZones, 4, duel, viewerIndex),
            equipmentZones = buildEquipmentZonePayload(selfState.equipmentZones, 3, duel, viewerIndex),
            locationZone = selfState.locationZone and buildCardPayload(selfState.locationZone, duel, viewerIndex) or nil,
            hasSummonedThisTurn = selfState.hasSummonedThisTurn,
            lifePoints = selfState.lifePoints,
            statuses = selfState.statuses or {},
            graveyard = buildCardPayloadList(selfState.graveyard, duel, viewerIndex),
            banished = buildCardPayloadList(selfState.banished, duel, viewerIndex)
        },

        opponentPlayer = {
            source = oppState.source,
            deckCount = #oppState.deck,
            handCount = #oppState.hand,
            graveyardCount = #oppState.graveyard,
            banishedCount = #(oppState.banished or {}),
            fighterZones = buildFixedZonePayload(oppState.fighterZones, 3, duel, viewerIndex),
            itemZones = buildFixedZonePayload(oppState.itemZones, 4, duel, viewerIndex),
            equipmentZones = buildEquipmentZonePayload(oppState.equipmentZones, 3, duel, viewerIndex),
            locationZone = oppState.locationZone and buildCardPayload(oppState.locationZone, duel, viewerIndex) or nil,
            hasSummonedThisTurn = oppState.hasSummonedThisTurn,
            lifePoints = oppState.lifePoints,
            statuses = oppState.statuses or {},
            graveyard = buildCardPayloadList(oppState.graveyard, duel, viewerIndex),
            banished = buildCardPayloadList(oppState.banished, duel, viewerIndex)
        }
    }
end

local function sendDuelStateToPlayers(duel)
    local sentToSource = {}
    if DuelEffects and DuelEffects.ResumePendingActions and getEffectApi and not duel.effectChain and not duel.pendingEffect and not duel.pendingSelection then
        DuelEffects.ResumePendingActions(duel, getEffectApi())
    end

    if activateNextQueuedEffectPrompt and not duel.pendingActionQueue and not duel.effectChain and not duel.pendingEffect and not duel.pendingSelection then
        activateNextQueuedEffectPrompt(duel)
    end

    if refreshContinuousModifiers then
        refreshContinuousModifiers(duel)
    end

    for playerIndex, playerState in pairs(duel.players) do
        local src = playerState.source

        if not sentToSource[src] then
            local payloadIndex = playerIndex

            -- Solo/self-test duel: same player controls both sides.
            -- Show the current turn player's perspective so one client can fully test both decks.
            if duel.players[1].source == duel.players[2].source then
                if duel.pendingEffect and duel.pendingEffect.playerIndex then
                    payloadIndex = duel.pendingEffect.playerIndex
                elseif duel.pendingSelection and duel.pendingSelection.playerIndex then
                    payloadIndex = duel.pendingSelection.playerIndex
                else
                    payloadIndex = duel.turnPlayer
                end
            end

            TriggerClientEvent('bstar_cards:client:OpenDuelUi', src, buildPrivateStateForPlayer(duel, payloadIndex))
            sentToSource[src] = true
        end
    end
end

local function createPlayerState(src, ownerIndex, deckId, deckName, deckData)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        return nil, 'Player not found'
    end

    local deckInstances = buildDeckInstancesFromDeckData(deckData, ownerIndex)
    shuffleList(deckInstances)

    return {
        source = src,
        citizenid = Player.PlayerData.citizenid,
        deckId = deckId,
        deckName = deckName or ('Deck ' .. tostring(deckId)),
        deck = deckInstances,
        hand = {},
        graveyard = {},
        banished = {},
        fighterZones = { nil, nil, nil },
        itemZones = { nil, nil, nil, nil },
        equipmentZones = { nil, nil, nil },
        locationZone = nil,
        hasSummonedThisTurn = false,
        summonsThisTurn = 0,
        statuses = {},
        lifePoints = 1000
    }
end

getCardStat = function(card, statName)
    local def = getCardDefinition(card.cardId)
    if not def then return 0 end

    local raw = def[statName]
    if raw == nil then
        if statName == 'attack' then raw = def.atk end
        if statName == 'defense' then raw = def.def end
        if statName == 'hp' or statName == 'health' then raw = def.health or def.hp or def.defense or def.def end
        if statName == 'speed' then raw = def.spd end
    end

    local value = parseStatValue(raw)
    local modifiers = card.statModifiers or {}
    local turnModifiers = card.turnStatModifiers or {}
    local equipmentModifiers = card.equipmentStatModifiers or {}
    local continuousModifiers = card.continuousStatModifiers or {}
    value = value + (tonumber(modifiers[statName]) or 0)
    value = value + (tonumber(turnModifiers[statName]) or 0)
    value = value + (tonumber(equipmentModifiers[statName]) or 0)
    value = value + (tonumber(continuousModifiers[statName]) or 0)

    if statName == 'hp' or statName == 'health' or statName == 'defense' then
        value = value + (tonumber(modifiers.hp) or 0)
        value = value + (tonumber(turnModifiers.hp) or 0)
        value = value + (tonumber(equipmentModifiers.hp) or 0)
        value = value + (tonumber(continuousModifiers.hp) or 0)
    end

    return value
end

local function getEquipmentStatModifier(card, statName)
    local def = card and getCardDefinition(card.cardId) or nil
    if not def then return 0 end

    local raw = statName == 'attack' and (def.attack or def.atk) or (def.speed or def.spd)
    local match = tostring(raw or ''):match('([%+%-]%s*%d+)')
    local value = match and tonumber((match:gsub('%s+', ''))) or 0

    local key = statName == 'attack' and 'attack' or 'speed'
    value = value + (tonumber(card.statModifiers and card.statModifiers[key]) or 0)
    value = value + (tonumber(card.turnStatModifiers and card.turnStatModifiers[key]) or 0)
    value = value + (tonumber(card.continuousStatModifiers and card.continuousStatModifiers[key]) or 0)
    value = value + math.floor(value * (tonumber(card.continuousStatMultipliers and card.continuousStatMultipliers[key]) or 0))

    return value
end

local function modifyEquipmentBonus(duel, equipmentCard, statName, options)
    if not duel or not equipmentCard then return false end

    options = options or {}
    local card, playerState, _, zoneName, zoneIndex = findCardByUid(duel, equipmentCard.uid)
    if not card or zoneName ~= 'equipmentZones' then return false end

    local key = statName == 'attack' and 'attack' or 'speed'
    local duration = options.duration == 'turn' and 'turnStatModifiers' or 'statModifiers'
    local current = getEquipmentStatModifier(card, key)
    local delta = tonumber(options.amount) or 0

    if options.setTo ~= nil then
        delta = (tonumber(options.setTo) or 0) - current
    elseif options.multiplier ~= nil then
        delta = math.ceil(current * (tonumber(options.multiplier) or 0))
    end

    if options.minValue ~= nil and current + delta < tonumber(options.minValue) then
        delta = (tonumber(options.minValue) or 0) - current
    end

    if delta == 0 then return false end

    card[duration] = card[duration] or {}
    card[duration][key] = (tonumber(card[duration][key]) or 0) + delta
    rebuildEquipmentModifiers(playerState, zoneIndex)
    return true
end

rebuildEquipmentModifiers = function(playerState, zoneIndex)
    if not playerState or not zoneIndex then return end

    local fighter = playerState.fighterZones and playerState.fighterZones[zoneIndex] or nil
    if not fighter then return end

    fighter.equipmentStatModifiers = nil

    local attackMod = 0
    local speedMod = 0
    local slot = playerState.equipmentZones and playerState.equipmentZones[zoneIndex] or nil

    local function addEquipmentStats(equipment)
        attackMod = attackMod + getEquipmentStatModifier(equipment, 'attack')
        speedMod = speedMod + getEquipmentStatModifier(equipment, 'speed')
        equipment.equippedToZoneIndex = zoneIndex
    end

    if isEquipmentBundle(slot) then
        for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
            if slot[key] then
                addEquipmentStats(slot[key])
            end
        end
    elseif slot then
        addEquipmentStats(slot)
    end

    if attackMod ~= 0 or speedMod ~= 0 then
        fighter.equipmentStatModifiers = {}
        if attackMod ~= 0 then fighter.equipmentStatModifiers.attack = attackMod end
        if speedMod ~= 0 then fighter.equipmentStatModifiers.speed = speedMod end
    end
end

local function eachEquipmentCardAt(playerState, zoneIndex, callback)
    local slot = playerState and playerState.equipmentZones and playerState.equipmentZones[zoneIndex] or nil
    if not slot then return end

    if isEquipmentBundle(slot) then
        for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
            if slot[key] then
                callback(slot[key], key)
            end
        end
    else
        callback(slot, getEquipmentSlotKey(slot))
    end
end

local function fighterBattleLimitConditionMet(playerState, zoneIndex, condition)
    if type(condition) ~= 'table' then return true end

    if type(condition.equippedNameContainsAny) == 'table' then
        local matched = false
        eachEquipmentCardAt(playerState, zoneIndex, function(equipment)
            local def = equipment and getCardDefinition(equipment.cardId)
            local nameText = string.lower(tostring(def and def.name or ''))
            for _, value in ipairs(condition.equippedNameContainsAny) do
                if nameText:find(string.lower(tostring(value)), 1, true) then
                    matched = true
                    break
                end
            end
        end)
        if not matched then return false end
    end

    if type(condition.equippedCardTagsAny) == 'table' then
        local matched = false
        eachEquipmentCardAt(playerState, zoneIndex, function(equipment)
            local def = equipment and getCardDefinition(equipment.cardId)
            for _, wantedTag in ipairs(condition.equippedCardTagsAny) do
                if cardDefHasTag(def, wantedTag) then
                    matched = true
                    break
                end
            end
        end)
        if not matched then return false end
    end

    return true
end

local function getFighterZoneIndex(playerState, fighterCard)
    if not playerState or not fighterCard then return nil end

    for zoneIndex = 1, 3 do
        if playerState.fighterZones and playerState.fighterZones[zoneIndex] == fighterCard then
            return zoneIndex
        end
    end

    return tonumber(fighterCard.equippedToZoneIndex)
end

getFighterBattleAttackLimit = function(playerState, fighterCard)
    if not playerState or not fighterCard then return 1 end

    local zoneIndex = getFighterZoneIndex(playerState, fighterCard)
    local limit = 1

    local function applyLimitEffectsFrom(card)
        local def = card and getCardDefinition(card.cardId) or nil
        for _, effect in ipairs((def and def.effects) or {}) do
            if effect.continuous == true and fighterBattleLimitConditionMet(playerState, zoneIndex, effect.condition) then
                for _, action in ipairs(effect.actions or {}) do
                    if tostring(action.action or '') == 'grant_extra_attacks' then
                        limit = limit + math.max(0, tonumber(action.amount) or 1)
                    end
                end
            end
        end
    end

    applyLimitEffectsFrom(fighterCard)
    eachEquipmentCardAt(playerState, zoneIndex, applyLimitEffectsFrom)

    for _, status in ipairs(fighterCard.statuses or {}) do
        local id = tostring(status.id or status.name or ''):lower()
        if id == 'extra_attacks' then
            limit = limit + math.max(0, tonumber(status.amount) or 1)
        end
    end

    return math.max(1, limit)
end

local function hasRemainingBattleAttacks(playerState, fighterCard)
    if not fighterCard then return false end
    return (tonumber(fighterCard.attacksThisTurn) or 0) < getFighterBattleAttackLimit(playerState, fighterCard)
end

local function markBattleAttackUsed(playerState, fighterCard)
    if not fighterCard then return end
    fighterCard.attacksThisTurn = (tonumber(fighterCard.attacksThisTurn) or 0) + 1
    fighterCard.hasAttacked = not hasRemainingBattleAttacks(playerState, fighterCard)
end

local function getBattleAttackStat(playerState, zoneIndex, attackerCard, defenderCard)
    local attack = getCardStat(attackerCard, 'attack')
    local defenderDef = defenderCard and getCardDefinition(defenderCard.cardId) or nil
    local defenderIsAnimal = cardDefHasTag(defenderDef, 'Animal')

    eachEquipmentCardAt(playerState, zoneIndex, function(equipment)
        local def = equipment and getCardDefinition(equipment.cardId)
        if def and tostring(def.name or ''):lower():find('hunting rifle', 1, true) and not defenderIsAnimal then
            attack = attack - getEquipmentStatModifier(equipment, 'attack')
        end
    end)

    return math.max(0, attack)
end

local function canEquipCardToFighter(playerState, equipmentCard, zoneIndex)
    if not playerState or not equipmentCard then return false end
    if not zoneIndex or zoneIndex < 1 or zoneIndex > 3 then return false end
    local fighterCard = playerState.fighterZones and playerState.fighterZones[zoneIndex] or nil
    if not fighterCard then return false end

    local slotKey = getEquipmentSlotKey(equipmentCard)
    if not slotKey then return false end

    local equipmentDef = getCardDefinition(equipmentCard.cardId)
    local fighterDef = getCardDefinition(fighterCard.cardId)
    if not equipmentTargetMatches(fighterDef, equipmentDef and equipmentDef.equipTargetFilter) then
        return false
    end

    if equipmentDef and (equipmentDef.uniqueOnField == true or equipmentDef.uniqueOnControllerField == true) then
        for existingZoneIndex, existingSlot in pairs(playerState.equipmentZones or {}) do
            local function sameCard(existingCard)
                return existingCard
                    and tostring(existingCard.cardId or '') == tostring(equipmentCard.cardId or '')
                    and tonumber(existingZoneIndex) ~= tonumber(zoneIndex)
            end

            if isEquipmentBundle(existingSlot) then
                if sameCard(existingSlot.vehicle) or sameCard(existingSlot.weapon) or sameCard(existingSlot.equipment) then
                    return false
                end
            elseif sameCard(existingSlot) then
                return false
            end
        end
    end

    if equipmentDef and tonumber(equipmentDef.maxCopiesPerFighter) and tonumber(equipmentDef.maxCopiesPerFighter) > 1 then
        local count = 0
        local slot = playerState.equipmentZones and playerState.equipmentZones[zoneIndex] or nil
        if isEquipmentBundle(slot) then
            for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                local existingCard = slot[key]
                if existingCard and tostring(existingCard.cardId or '') == tostring(equipmentCard.cardId or '') then
                    count = count + 1
                end
            end
        elseif slot and tostring(slot.cardId or '') == tostring(equipmentCard.cardId or '') then
            count = count + 1
        end

        if count > 0 and count < tonumber(equipmentDef.maxCopiesPerFighter) and getEquipmentCardAt(playerState, zoneIndex, 'equipment') == nil then
            return true
        end
    end

    return getEquipmentCardAt(playerState, zoneIndex, slotKey) == nil
end

local function playerHasStatus(playerState, statusId)
    local wanted = string.lower(tostring(statusId or ''))
    if wanted == '' then return false end

    for _, status in ipairs(playerState and playerState.statuses or {}) do
        local id = string.lower(tostring(status.id or status.name or ''))
        if id == wanted then
            return true, status
        end
    end

    return false, nil
end

local function consumePlayerStatus(playerState, statusId)
    local wanted = string.lower(tostring(statusId or ''))
    if wanted == '' or type(playerState and playerState.statuses) ~= 'table' then return false end

    for index, status in ipairs(playerState.statuses) do
        local id = string.lower(tostring(status.id or status.name or ''))
        if id == wanted then
            table.remove(playerState.statuses, index)
            return true
        end
    end

    return false
end

local function playerHasCardTypeLock(playerState, cardType)
    local wanted = string.upper(tostring(cardType or ''))
    if wanted == '' then return false end

    for _, status in ipairs(playerState and playerState.statuses or {}) do
        local id = string.lower(tostring(status.id or status.name or ''))
        local lockedType = string.upper(tostring(status.cardType or status.blockedType or status.type or ''))
        if id == 'card_type_lock' and lockedType == wanted then
            return true
        end
    end

    return false
end

local function playerControlsCardNamed(playerState, nameNeedle)
    local needle = string.lower(tostring(nameNeedle or ''))
    if needle == '' then return false end

    local function matches(card)
        local def = getCardDefinition(card and card.cardId)
        local name = string.lower(tostring(def and def.name or ''))
        return name:find(needle, 1, true) ~= nil
    end

    for _, card in pairs(playerState and playerState.fighterZones or {}) do if matches(card) then return true end end
    for _, card in pairs(playerState and playerState.itemZones or {}) do if matches(card) then return true end end
    if matches(playerState and playerState.locationZone) then return true end
    for _, slot in pairs(playerState and playerState.equipmentZones or {}) do
        if isEquipmentBundle(slot) then
            for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                if matches(slot[key]) then return true end
            end
        elseif matches(slot) then
            return true
        end
    end

    return false
end

local function fighterHasVehicleEquipped(playerState, zoneIndex)
    return getEquipmentCardAt(playerState, zoneIndex, 'vehicle') ~= nil
end

local function getCardLevelValue(cardDef)
    if not cardDef then return 0 end

    if type(cardDef.level) == 'number' then
        return cardDef.level
    end

    local match = string.match(tostring(cardDef.level or ''), "%d+")
    return match and tonumber(match) or 0
end

getEffectApi = function()
    return {
        getOpponentIndex = getOpponentIndex,
        getCardDefinition = getCardDefinition,
        getCardLevelValue = getCardLevelValue,
        getCardStat = getCardStat,
        findCardByUid = findCardByUid,
        drawCards = drawCards,
        moveHandCardToGraveyard = moveHandCardToGraveyard,
        moveFieldCardToGraveyard = function(playerState, zoneIndex, options)
            return moveFieldCardToGraveyard(playerState, zoneIndex, options and options.duel or nil, options)
        end,
        moveEquipmentAtToGraveyard = moveEquipmentAtToGraveyard,
        moveCardByUidToGraveyard = moveCardByUidToGraveyard,
        removeCardByUid = removeCardByUid,
        banishCardByUid = banishCardByUid,
        resetFighterHp = resetFighterHp,
        ensureFighterHp = ensureFighterHp,
        rebuildEquipmentModifiers = rebuildEquipmentModifiers,
        getEquipmentSlotKey = getEquipmentSlotKey,
        getEquipmentCardAt = getEquipmentCardAt,
        setEquipmentCardAt = setEquipmentCardAt,
        canEquipCardToFighter = canEquipCardToFighter,
        modifyEquipmentBonus = modifyEquipmentBonus,
        queueEffectPrompt = queueEffectPrompt,
        queueDeckSearch = queueDeckSearch,
        queueCardSelection = queueCardSelection,
        triggerSummonResponseWindow = triggerSummonResponseWindow,
        triggerActionResponseWindow = triggerActionResponseWindow,
        scheduleDelayedTask = scheduleDelayedTask,
        addSpecialSummonDrawWatcher = addSpecialSummonDrawWatcher,
        addPlayedTypeDrawWatcher = addPlayedTypeDrawWatcher
    }
end

local function normalizePromotionName(cardDef)
    return string.lower(tostring(cardDef and cardDef.name or '')):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function canPromoteFromTo(tributeDef, promotionDef)
    if not tributeDef or not promotionDef then return false end
    if string.upper(tributeDef.type or '') ~= 'FIGHTER' then return false end
    if string.upper(promotionDef.type or '') ~= 'FIGHTER' then return false end

    local tributeLevel = getCardLevelValue(tributeDef)
    local promotionLevel = getCardLevelValue(promotionDef)

    return tributeLevel > 0
        and promotionLevel == tributeLevel + 1
        and normalizePromotionName(tributeDef) == normalizePromotionName(promotionDef)
end

local function canGenericPromoteFromPair(firstDef, secondDef, promotionDef)
    if not firstDef or not secondDef or not promotionDef then return false end
    if string.upper(firstDef.type or '') ~= 'FIGHTER' then return false end
    if string.upper(secondDef.type or '') ~= 'FIGHTER' then return false end
    if string.upper(promotionDef.type or '') ~= 'FIGHTER' then return false end

    local firstLevel = getCardLevelValue(firstDef)
    local secondLevel = getCardLevelValue(secondDef)
    local promotionLevel = getCardLevelValue(promotionDef)

    return (firstLevel == 1 or firstLevel == 2)
        and secondLevel == firstLevel
        and promotionLevel == firstLevel + 1
end

local function normalizeTributeZoneIndexes(input)
    local indexes = {}
    local seen = {}

    local function add(value)
        local index = tonumber(value)
        if index and index >= 1 and index <= 3 and not seen[index] then
            indexes[#indexes + 1] = index
            seen[index] = true
        end
    end

    if type(input) == 'table' then
        for _, value in ipairs(input) do
            add(value)
        end
    else
        add(input)
    end

    return indexes
end

local function getOccupiedFighterCount(playerState)
    local count = 0
    for i = 1, 3 do
        if playerState.fighterZones[i] then
            count = count + 1
        end
    end
    return count
end

local function continuousConditionMet(playerState, condition)
    if type(condition) ~= 'table' then return true end

    if condition.ownFighterCount and getOccupiedFighterCount(playerState) ~= tonumber(condition.ownFighterCount) then
        return false
    end

    if condition.ownFighterCountMin and getOccupiedFighterCount(playerState) < tonumber(condition.ownFighterCountMin) then
        return false
    end

    return true
end

local function clearContinuousModifier(card)
    if not card or (not card.continuousStatModifiers and not card.continuousStatMultipliers) then return end

    local hpMod = tonumber(card.continuousStatModifiers and card.continuousStatModifiers.hp) or 0
    if hpMod ~= 0 then
        card.maxHp = math.max(0, (tonumber(card.maxHp) or getCardBaseHp(card)) - hpMod)
        card.currentHp = math.max(0, (tonumber(card.currentHp) or 0) - hpMod)
        if (tonumber(card.currentHp) or 0) > card.maxHp then
            card.currentHp = card.maxHp
        end
    end

    card.continuousStatModifiers = nil
    card.continuousStatMultipliers = nil
end

local function applyContinuousStatModifier(card, stat, amount)
    if not card or not stat then return end

    local key = stat
    if stat == 'defense' or stat == 'health' then
        key = 'hp'
    end

    local value = tonumber(amount) or 0
    if value == 0 then return end

    card.continuousStatModifiers = card.continuousStatModifiers or {}
    card.continuousStatModifiers[key] = (tonumber(card.continuousStatModifiers[key]) or 0) + value

    if key == 'hp' then
        card.maxHp = math.max(0, (tonumber(card.maxHp) or getCardBaseHp(card)) + value)
        if value > 0 then
            card.currentHp = (tonumber(card.currentHp) or 0) + value
        elseif (tonumber(card.currentHp) or 0) > card.maxHp then
            card.currentHp = card.maxHp
        end
    end
end

local function continuousTargetMatches(card, filter)
    if type(filter) ~= 'table' then return true end

    local def = card and getCardDefinition(card.cardId) or nil
    if not def then return false end

    local typeText = string.upper(tostring(def.type or ''))
    if filter.type and typeText ~= string.upper(tostring(filter.type)) then
        return false
    end

    if type(filter.typesAny) == 'table' then
        local matched = false
        for _, value in ipairs(filter.typesAny) do
            if typeText == string.upper(tostring(value)) then
                matched = true
                break
            end
        end
        if not matched then return false end
    end

    local nameText = string.lower(tostring(def.name or ''))
    local jobText = string.lower(tostring(def.job or ''))

    if filter.nameContains and not nameText:find(string.lower(tostring(filter.nameContains)), 1, true) then
        return false
    end

    if filter.jobContains and not jobText:find(string.lower(tostring(filter.jobContains)), 1, true) then
        return false
    end

    if filter.cardTag then
        local wanted = string.lower(tostring(filter.cardTag))
        local found = false
        for _, tag in ipairs(def.cardTags or {}) do
            if string.lower(tostring(tag)) == wanted then
                found = true
                break
            end
        end
        if not found then return false end
    end

    if type(filter.cardTagsAny) == 'table' then
        local found = false
        for _, wantedTag in ipairs(filter.cardTagsAny) do
            local wanted = string.lower(tostring(wantedTag))
            for _, tag in ipairs(def.cardTags or {}) do
                if string.lower(tostring(tag)) == wanted then
                    found = true
                    break
                end
            end
            if found then break end
        end
        if not found then return false end
    end

    return true
end

refreshContinuousModifiers = function(duel)
    if not duel or not duel.players then return end

    for _, playerState in pairs(duel.players) do
        for i = 1, 3 do
            clearContinuousModifier(playerState.fighterZones and playerState.fighterZones[i] or nil)
        end
        for _, slot in pairs(playerState.equipmentZones or {}) do
            if isEquipmentBundle(slot) then
                for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                    clearContinuousModifier(slot[key])
                end
            else
                clearContinuousModifier(slot)
            end
        end
    end

    for _, playerState in pairs(duel.players) do
        local continuousSources = {}
        local function addContinuousSource(card, zoneIndex)
            if card then
                continuousSources[#continuousSources + 1] = {
                    card = card,
                    zoneIndex = zoneIndex
                }
            end
        end

        for i = 1, 3 do
            addContinuousSource(playerState.fighterZones and playerState.fighterZones[i] or nil)
        end
        for i = 1, 4 do
            addContinuousSource(playerState.itemZones and playerState.itemZones[i] or nil)
        end
        addContinuousSource(playerState.locationZone)

        for zoneIndex, slot in pairs(playerState.equipmentZones or {}) do
            if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                    addContinuousSource(slot[key], zoneIndex)
                end
            else
                addContinuousSource(slot, zoneIndex)
            end
        end

        for _, source in ipairs(continuousSources) do
            local card = source.card
            local def = card and getCardDefinition(card.cardId) or nil

            for _, effect in ipairs((def and def.effects) or {}) do
                if effect.continuous == true and continuousConditionMet(playerState, effect.condition) then
                    for _, action in ipairs(effect.actions or {}) do
                        if tostring(action.action or '') == 'modify_stats' and tostring(action.target or 'self') == 'self' then
                            for stat, amount in pairs(action.stats or {}) do
                                applyContinuousStatModifier(card, stat, amount)
                            end
                        elseif tostring(action.action or '') == 'modify_stats' and tostring(action.target or '') == 'all_self_fighters' then
                            for targetZoneIndex = 1, 3 do
                                local targetCard = playerState.fighterZones and playerState.fighterZones[targetZoneIndex] or nil
                                local excludedEquipped = action.excludeEquippedFighter == true and source.zoneIndex and tonumber(source.zoneIndex) == tonumber(targetZoneIndex)
                                if targetCard and not excludedEquipped and continuousTargetMatches(targetCard, action.filter) then
                                    for stat, amount in pairs(action.stats or {}) do
                                        applyContinuousStatModifier(targetCard, stat, amount)
                                    end
                                end
                            end
                        elseif tostring(action.action or '') == 'modify_stats' and tostring(action.target or '') == 'equipped_fighter' then
                            local targetCard = source.zoneIndex and playerState.fighterZones and playerState.fighterZones[source.zoneIndex] or nil
                            if targetCard and continuousTargetMatches(targetCard, action.filter) then
                                for stat, amount in pairs(action.stats or {}) do
                                    applyContinuousStatModifier(targetCard, stat, amount)
                                end
                            end
                        elseif tostring(action.action or '') == 'modify_stats' and tostring(action.target or '') == 'opponent_equipment' then
                            local opponentState = duel.players[getOpponentIndex(getPlayerIndexForState(duel, playerState) or 1)]
                            for _, slot in pairs(opponentState and opponentState.equipmentZones or {}) do
                                local function applyToEquipment(equipmentCard)
                                    if equipmentCard and continuousTargetMatches(equipmentCard, action.filter) then
                                        equipmentCard.continuousStatMultipliers = equipmentCard.continuousStatMultipliers or {}
                                        for stat, amount in pairs(action.statMultipliers or {}) do
                                            local key = stat == 'spd' and 'speed' or stat
                                            equipmentCard.continuousStatMultipliers[key] = (tonumber(equipmentCard.continuousStatMultipliers[key]) or 0) + (tonumber(amount) or 0)
                                        end
                                    end
                                end
                                if isEquipmentBundle(slot) then
                                    for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                                        applyToEquipment(slot[key])
                                    end
                                else
                                    applyToEquipment(slot)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function runPhaseStartEffects(duel, playerIndex, phase)
    if not duel or not DuelEffects or not getEffectApi then return end
    if phase == 'main' or phase == 'main2' then
        DuelEffects.RunFieldTrigger(duel, 'main_phase_start', playerIndex, {
            phase = phase,
            turnPlayer = playerIndex
        }, getEffectApi())
    end
end

moveEquipmentAtToGraveyard = function(playerState, zoneIndex, duel, options)
    local equipmentSlot = playerState and playerState.equipmentZones and playerState.equipmentZones[zoneIndex] or nil
    if not equipmentSlot then return end

    local sentCards = {}

    if isEquipmentBundle(equipmentSlot) then
        for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
            local equipment = equipmentSlot[key]
            if equipment then
                equipment.zone = "graveyard"
                equipment.equippedToZoneIndex = nil
                playerState.graveyard[#playerState.graveyard + 1] = equipment
                sentCards[#sentCards + 1] = equipment
            end
        end
    else
        equipmentSlot.zone = "graveyard"
        equipmentSlot.equippedToZoneIndex = nil
        playerState.graveyard[#playerState.graveyard + 1] = equipmentSlot
        sentCards[#sentCards + 1] = equipmentSlot
    end

    playerState.equipmentZones[zoneIndex] = nil
    rebuildEquipmentModifiers(playerState, zoneIndex)

    if duel then
        for _, card in ipairs(sentCards) do
            fireSentToCemeteryTrigger(duel, playerState, card, options)
        end
    end
end

fireSentToCemeteryTrigger = function(duel, playerState, card, options)
    if not duel or not playerState or not card or options and options.suppressSentTrigger == true then return end
    if not DuelEffects or not getEffectApi then return end

    local playerIndex = getPlayerIndexForState(duel, playerState)
    if not playerIndex then return end

    DuelEffects.RunTrigger(duel, 'on_sent_to_cemetery', playerIndex, card, {
        reason = options and options.reason or 'sent_to_cemetery',
        sentUid = card.uid,
        targetUid = card.uid,
        targetCard = card,
        targetCardId = card.cardId,
        targetPlayerIndex = playerIndex,
        sourceUid = options and options.sourceUid or nil,
        sourceCardId = options and options.sourceCardId or nil
    }, getEffectApi())
end

local function isDestructionPrevented(duel, playerState, card, zoneName, zoneIndex, options)
    if not duel or not card then
        return false
    end

    options = options or {}
    if options.skipReplacement == true then
        return false
    end

    if tostring(options.reason or 'card_effect') == 'card_effect'
        and consumeCardStatus(card, 'first_destruction_shield') then
        duel.log = duel.log or {}
        duel.log[#duel.log + 1] = {
            turn = duel.turnNumber,
            phase = duel.phase,
            message = ('%s survived its first card-effect destruction.'):format(card.cardId)
        }
        return true
    end

    if not DuelEffects or not DuelEffects.RunReplacement then
        return false
    end

    local playerIndex = tonumber(options.targetPlayerIndex) or getPlayerIndexForState(duel, playerState)
    if not playerIndex then return false end

    local event = {
        reason = options.reason or 'card_effect',
        sourceUid = options.sourceUid,
        sourceCardId = options.sourceCardId,
        targetUid = card.uid,
        targetCard = card,
        targetCardId = card.cardId,
        targetPlayerIndex = playerIndex,
        targetZoneName = zoneName,
        targetZoneIndex = zoneIndex
    }

    local result = DuelEffects.RunReplacement(duel, 'would_be_destroyed', playerIndex, event, getEffectApi())
    return result and result.prevented == true
end

moveFieldCardToGraveyard = function(playerState, zoneIndex, duel, options)
    local card = playerState.fighterZones[zoneIndex]
    if not card then return nil end

    if isDestructionPrevented(duel, playerState, card, 'fighterZones', zoneIndex, options) then
        return nil, 'prevented'
    end

    moveEquipmentAtToGraveyard(playerState, zoneIndex, duel, options)

    playerState.fighterZones[zoneIndex] = nil
    card.zone = "graveyard"
    card.continuousStatModifiers = nil
    playerState.graveyard[#playerState.graveyard + 1] = card
    fireSentToCemeteryTrigger(duel, playerState, card, options)

    return card
end

local function removeEquipmentCardByUid(playerState, zoneIndex, uid)
    local slot = playerState and playerState.equipmentZones and playerState.equipmentZones[zoneIndex] or nil
    if not slot then return nil end

    if isEquipmentBundle(slot) then
        for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
            local card = slot[key]
            if card and card.uid == uid then
                slot[key] = nil
                if not slot.vehicle and not slot.weapon and not slot.equipment then
                    playerState.equipmentZones[zoneIndex] = nil
                end
                rebuildEquipmentModifiers(playerState, zoneIndex)
                return card
            end
        end
    elseif slot.uid == uid then
        playerState.equipmentZones[zoneIndex] = nil
        rebuildEquipmentModifiers(playerState, zoneIndex)
        return slot
    end

    return nil
end

removeCardByUid = function(duel, uid, options)
    local card, playerState, playerIndex, zoneName, zoneIndex = findCardByUid(duel, uid)
    if not card then return nil end

    if zoneName == 'fighterZones' then
        local removeOptions = shallowCopy(options or {})
        removeOptions.suppressSentTrigger = true
        card = moveFieldCardToGraveyard(playerState, zoneIndex, duel, removeOptions)
        if card then
            table.remove(playerState.graveyard, #playerState.graveyard)
end
    elseif zoneName == 'itemZones' then
        playerState.itemZones[zoneIndex] = nil
        card.temporaryItemZoneIndex = nil
    elseif zoneName == 'equipmentZones' then
        card = removeEquipmentCardByUid(playerState, zoneIndex, uid)
    elseif zoneName == 'locationZone' then
        playerState.locationZone = nil
    elseif zoneName == 'hand' or zoneName == 'graveyard' or zoneName == 'banished' or zoneName == 'deck' then
        table.remove(playerState[zoneName], zoneIndex)
    end

    if card then
        card.zone = nil
    end

    return card, playerState, playerIndex
end

moveCardByUidToGraveyard = function(duel, uid, options)
    local card, playerState, playerIndex, zoneName, zoneIndex = findCardByUid(duel, uid)
    if card and isDestructionPrevented(duel, playerState, card, zoneName, zoneIndex, options) then
        return nil, 'prevented'
    end

    card, playerState = removeCardByUid(duel, uid, {
        skipReplacement = true
    })
    if not card or not playerState then return nil end

    card.zone = 'graveyard'
    playerState.graveyard[#playerState.graveyard + 1] = card
    fireSentToCemeteryTrigger(duel, playerState, card, options)
    return card
end

banishCardByUid = function(duel, uid)
    local card, playerState = removeCardByUid(duel, uid)
    if not card or not playerState then return nil end

    card.zone = 'banished'
    playerState.banished = playerState.banished or {}
    playerState.banished[#playerState.banished + 1] = card
    return card
end

local function moveItemZoneCardToGraveyard(playerState, zoneIndex, duel, options)
    zoneIndex = tonumber(zoneIndex)
    local card = playerState and playerState.itemZones and playerState.itemZones[zoneIndex] or nil
    if not card then return nil end

    if isDestructionPrevented(duel, playerState, card, 'itemZones', zoneIndex, options) then
        return nil, 'prevented'
    end

    playerState.itemZones[zoneIndex] = nil
    card.zone = "graveyard"
    card.temporaryItemZoneIndex = nil
    playerState.graveyard[#playerState.graveyard + 1] = card
    fireSentToCemeteryTrigger(duel, playerState, card, options)

    return card
end

local function calculateDodgeChance(attackerCard, defenderCard)
    -- Temporary dodge test override. Uncomment with DEBUG_DODGE_TEST in shared/cards.lua when needed.
    -- if defenderCard and defenderCard.cardId == 'DEBUG_DODGE_TEST' then
    --     return 95
    -- end

    local attackerSPD = getCardStat(attackerCard, 'speed')
    local defenderSPD = getCardStat(defenderCard, 'speed')
    local diff = defenderSPD - attackerSPD

    if diff < 2 then
        return 0
    elseif diff < 4 then
        return 10
    elseif diff < 6 then
        return 20
    else
        return 30
    end
end

local function rollSuccess(percent)
    if percent <= 0 then return false end
    return math.random(1, 100) <= percent
end

local function checkWinCondition(duel)
    if duel.status == "finished" then
        return true
    end

    local p1 = duel.players[1]
    local p2 = duel.players[2]

    if p1.lifePoints <= 0 and p2.lifePoints <= 0 then
        duel.status = "finished"
        duel.winner = 0
        duel.winReason = "draw"
        return true
    elseif p1.lifePoints <= 0 then
        duel.status = "finished"
        duel.winner = 2
        duel.winReason = "life_points"
        return true
    elseif p2.lifePoints <= 0 then
        duel.status = "finished"
        duel.winner = 1
        duel.winReason = "life_points"
        return true
    end

    return false
end

applyLifePointLoss = function(duel, playerIndex, amount, event)
    local playerState = duel and duel.players and duel.players[playerIndex] or nil
    amount = math.max(0, tonumber(amount) or 0)
    if not playerState or amount <= 0 then return 0 end

    if playerHasStatus(playerState, 'prevent_lp_loss') then
        return 0
    end

    event = event or {}
    event.reason = event.reason or 'effect'
    event.amount = amount
    event.targetPlayerIndex = playerIndex
    event.losingPlayer = playerIndex

    if DuelEffects and DuelEffects.RunReplacement and getEffectApi then
        DuelEffects.RunReplacement(duel, 'would_lose_lp', playerIndex, event, getEffectApi())
        if event.lpLossReplaced == true or event.replacementPrevented == true then
            return 0
        end
        amount = math.max(0, tonumber(event.amount) or amount)
    end

    playerState.lifePoints = math.max(0, (tonumber(playerState.lifePoints) or 0) - amount)
    return amount
end

local function isMainPhase(phase)
    return phase == "main" or phase == "main2"
end

local function buildEffectPromptPayload(duel, playerIndex, sourceCard, triggerName, effectIndex, prompt)
    if not duel or not sourceCard then return nil end

    duel.effectPromptCounter = (duel.effectPromptCounter or 0) + 1
    return {
        id = tostring(duel.effectPromptCounter),
        playerIndex = playerIndex,
        sourcePlayerIndex = prompt and prompt.sourcePlayerIndex or playerIndex,
        sourceUid = sourceCard.uid,
        sourceCardId = sourceCard.cardId,
        trigger = triggerName,
        effectIndex = effectIndex,
        cardName = (prompt and prompt.cardName) or (getCardDefinition(sourceCard.cardId) and getCardDefinition(sourceCard.cardId).name) or sourceCard.cardId,
        title = prompt and prompt.title or 'Effect',
        text = prompt and prompt.text or 'Do you want to activate this effect?',
        effectText = prompt and prompt.effectText or nil,
        form = prompt and prompt.form or nil,
        confirmText = prompt and prompt.confirmText or nil,
        cancelText = prompt and prompt.cancelText or nil,
        responseWindow = prompt and prompt.responseWindow == true,
        chainId = prompt and prompt.chainId or nil,
        runCancelActions = prompt and prompt.runCancelActions == true
    }
end

local function buildResponsePromptPayload(duel, playerIndex, chain, choices)
    duel.effectPromptCounter = (duel.effectPromptCounter or 0) + 1

    local options = {}
    for _, choice in ipairs(choices or {}) do
        options[#options + 1] = {
            id = choice.id,
            label = choice.label,
            description = choice.description
        }
    end

    return {
        id = tostring(duel.effectPromptCounter),
        playerIndex = playerIndex,
        sourceUid = nil,
        sourceCardId = nil,
        trigger = 'response_window',
        effectIndex = nil,
        cardName = 'Response Window',
        title = 'Response Window',
        text = chain and chain.promptText or 'Do you want to chain a response?',
        effectText = chain and chain.effectText or nil,
        form = {
            options = options
        },
        confirmText = 'Chain',
        cancelText = 'Pass',
        responseWindow = true,
        chainId = chain and chain.id or nil
    }
end

activateNextQueuedEffectPrompt = function(duel)
    if not duel or duel.pendingEffect then return false end
    local queue = duel.pendingEffectQueue
    if type(queue) ~= 'table' or #queue == 0 then return false end

    duel.pendingEffect = table.remove(queue, 1)
    return true
end

queueEffectPrompt = function(duel, playerIndex, sourceCard, triggerName, effectIndex, prompt)
    local payload = buildEffectPromptPayload(duel, playerIndex, sourceCard, triggerName, effectIndex, prompt)
    if not payload then return false end

    if duel.pendingEffect then
        duel.pendingEffectQueue = duel.pendingEffectQueue or {}
        duel.pendingEffectQueue[#duel.pendingEffectQueue + 1] = payload
    else
        duel.pendingEffect = payload
    end

    return true
end

local function getResponseChoicesForPlayer(duel, playerIndex, chain)
    if not DuelEffects or not DuelEffects.GetResponseChoices or not getEffectApi then
        return {}
    end

    local choices = DuelEffects.GetResponseChoices(duel, playerIndex, chain and chain.event or {}, getEffectApi()) or {}
    local used = {}
    for _, frame in ipairs(chain and chain.stack or {}) do
        used[('%s:%s'):format(tostring(frame.sourceUid or ''), tostring(frame.effectIndex or ''))] = true
    end

    local remaining = {}
    for _, choice in ipairs(choices) do
        local key = ('%s:%s'):format(tostring(choice.sourceUid or ''), tostring(choice.effectIndex or ''))
        if not used[key] then
            remaining[#remaining + 1] = choice
        end
    end

    return remaining
end

local function finishEffectChain(duel, chain)
    if not duel or not chain then return end

    while #chain.stack > 0 do
        local frame = table.remove(chain.stack)
        if DuelEffects and DuelEffects.ResolveResponseFrame and getEffectApi then
            local ok, err = DuelEffects.ResolveResponseFrame(duel, frame, getEffectApi())
            if not ok then
                duel.log = duel.log or {}
                duel.log[#duel.log + 1] = {
                    turn = duel.turnNumber,
                    phase = duel.phase,
                    message = err or 'A response failed to resolve.'
                }
            end
        end
    end

    duel.effectChain = nil

    if chain.continuation == 'battle' and continuePendingBattle then
        continuePendingBattle(duel)
    elseif continuePendingDuelAction then
        continuePendingDuelAction(duel)
    end
end

local function openResponsePromptForPlayer(duel, playerIndex, chain)
    local choices = getResponseChoicesForPlayer(duel, playerIndex, chain)
    if #choices == 0 then
        return false
    end

    duel.pendingEffect = buildResponsePromptPayload(duel, playerIndex, chain, choices)
    chain.currentPlayerIndex = playerIndex
    return true
end

local function advanceEffectChain(duel, passedPlayerIndex)
    local chain = duel and duel.effectChain or nil
    if not chain then return false end

    local playerIndex = tonumber(passedPlayerIndex) or chain.currentPlayerIndex
    chain.passed = chain.passed or {}
    if playerIndex then
        chain.passed[playerIndex] = true
    end

    local opponentIndex = playerIndex and getOpponentIndex(playerIndex) or chain.startPlayerIndex
    if opponentIndex and not chain.passed[opponentIndex] then
        if openResponsePromptForPlayer(duel, opponentIndex, chain) then
            return true
        end
        chain.passed[opponentIndex] = true
    end

    if chain.passed[1] and chain.passed[2] then
        finishEffectChain(duel, chain)
        return true
    end

    for _, nextPlayerIndex in ipairs({ 1, 2 }) do
        if not chain.passed[nextPlayerIndex] and openResponsePromptForPlayer(duel, nextPlayerIndex, chain) then
            return true
        end
        chain.passed[nextPlayerIndex] = true
    end

    finishEffectChain(duel, chain)
    return true
end

startResponseWindow = function(duel, startPlayerIndex, event, options)
    if not duel or duel.effectChain or duel.pendingEffect or duel.pendingSelection then return false end

    options = options or {}
    local chain = {
        id = tostring((duel.effectChainCounter or 0) + 1),
        startPlayerIndex = startPlayerIndex,
        currentPlayerIndex = startPlayerIndex,
        event = event or {},
        stack = {},
        passed = {},
        continuation = options.continuation,
        promptText = options.promptText or 'Do you want to chain a response?',
        effectText = options.effectText
    }
    duel.effectChainCounter = tonumber(chain.id) or ((duel.effectChainCounter or 0) + 1)
    duel.effectChain = chain

    if openResponsePromptForPlayer(duel, startPlayerIndex, chain) then
        return true
    end

    chain.passed[startPlayerIndex] = true
    local opponentIndex = getOpponentIndex(startPlayerIndex)
    if openResponsePromptForPlayer(duel, opponentIndex, chain) then
        return true
    end

    duel.effectChain = nil
    return false
end

local function runTriggeredContinuation(duel, continuation)
    if not duel or not continuation or not DuelEffects or not getEffectApi then return false end

    local playerIndex = tonumber(continuation.playerIndex)
    local card = continuation.sourceUid and findCardByUid(duel, continuation.sourceUid) or nil
    if not playerIndex or not card then return false end

    local event = continuation.event or {}
    DuelEffects.RunTrigger(duel, continuation.trigger, playerIndex, card, event, getEffectApi())
    checkWinCondition(duel)
    return true
end

local function fireOnPlayFieldTriggers(duel, playerIndex, card, event)
    if not DuelEffects or not DuelEffects.RunFieldTrigger or not getEffectApi then return end
    if not duel or not playerIndex or not card then return end

    event = event or {}
    if processPlayedTypeDrawWatchers then
        processPlayedTypeDrawWatchers(duel, event)
    end
    event.skipSourceUid = card.uid
    DuelEffects.RunFieldTrigger(duel, 'on_play', playerIndex, event, getEffectApi())
    DuelEffects.RunFieldTrigger(duel, 'on_play', getOpponentIndex(playerIndex), event, getEffectApi())
    event.skipSourceUid = nil
end

local function runActivatedContinuation(duel, continuation)
    if not duel or not continuation or not DuelEffects or not getEffectApi then return false end

    local playerIndex = tonumber(continuation.playerIndex)
    local card = continuation.sourceUid and findCardByUid(duel, continuation.sourceUid) or nil
    if not playerIndex or not card then return false end

    local activated = DuelEffects.RunTrigger(duel, 'activated', playerIndex, card, continuation.event or {}, getEffectApi())
    checkWinCondition(duel)
    return activated > 0
end

local function cleanupTemporaryItemZones(duel, playerIndex)
    local playerState = duel and duel.players and duel.players[playerIndex] or nil
    if not playerState or duel.pendingEffect or duel.pendingSelection or duel.effectChain then return end

    for zoneIndex, card in pairs(playerState.itemZones or {}) do
        if card and card.temporaryItemZoneIndex then
            moveItemZoneCardToGraveyard(playerState, zoneIndex)
        end
    end
end

continuePendingDuelAction = function(duel)
    local continuation = duel and duel.pendingContinuation or nil
    if not continuation then return false end

    duel.pendingContinuation = nil

    if continuation.kind == 'trigger' then
        runTriggeredContinuation(duel, continuation)
    elseif continuation.kind == 'activated_effect' then
        runActivatedContinuation(duel, continuation)
    elseif continuation.kind == 'pending_actions' and DuelEffects and DuelEffects.ResumePendingActions and getEffectApi then
        DuelEffects.ResumePendingActions(duel, getEffectApi())
    end

    if continuation.cleanupTemporaryItemsFor then
        cleanupTemporaryItemZones(duel, continuation.cleanupTemporaryItemsFor)
    end

    sendDuelStateToPlayers(duel)
    return true
end

startResponseWindowOrRunContinuation = function(duel, respondingPlayerIndex, continuation, responseEvent, promptText)
    if not duel or not continuation then return false end

    duel.pendingContinuation = continuation

    if startResponseWindow and startResponseWindow(duel, respondingPlayerIndex, responseEvent or {}, {
        continuation = continuation.kind,
        promptText = promptText
    }) then
        return true
    end

    duel.pendingContinuation = nil
    local resolved = false
    if continuation.kind == 'trigger' then
        resolved = runTriggeredContinuation(duel, continuation)
    elseif continuation.kind == 'activated_effect' then
        resolved = runActivatedContinuation(duel, continuation)
    elseif continuation.kind == 'pending_actions' and DuelEffects and DuelEffects.ResumePendingActions and getEffectApi then
        resolved = DuelEffects.ResumePendingActions(duel, getEffectApi())
    end
    if continuation.cleanupTemporaryItemsFor then
        cleanupTemporaryItemZones(duel, continuation.cleanupTemporaryItemsFor)
    end
    return resolved
end

triggerSummonResponseWindow = function(duel, playerIndex, card, event)
    if not duel or not playerIndex or not card then return false end

    event = event or {}
    event.responseEvent = event.responseEvent or 'summon'
    event.trigger = event.trigger or 'summon'
    event.summonType = event.summonType or 'special'
    event.summonedUid = event.summonedUid or card.uid
    event.summonedCard = event.summonedCard or card
    event.summoningPlayer = event.summoningPlayer or playerIndex

    local playerState = duel.players[playerIndex]
    if playerState then
        playerState.summonsThisTurn = (tonumber(playerState.summonsThisTurn) or 0) + 1
    end

    processSpecialSummonDrawWatchers(duel, event)

    return startResponseWindowOrRunContinuation(duel, getOpponentIndex(playerIndex), {
        kind = 'trigger',
        playerIndex = playerIndex,
        sourceUid = card.uid,
        trigger = 'on_summon',
        event = event
    }, event, ('Your opponent summoned %s. Chain a response?'):format((getCardDefinition(card.cardId) or {}).name or card.cardId))
end

triggerActionResponseWindow = function(duel, playerIndex, sourceCard, event, promptText)
    if not duel or not playerIndex or not sourceCard or type(event) ~= 'table' then return false end

    event.trigger = event.trigger or event.responseEvent or 'effect_action'
    event.sourceUid = event.sourceUid or sourceCard.uid
    event.sourceCardId = event.sourceCardId or sourceCard.cardId
    event.sourcePlayerIndex = event.sourcePlayerIndex or playerIndex
    event.actingPlayer = event.actingPlayer or playerIndex

    duel.pendingContinuation = {
        kind = 'pending_actions'
    }

    if startResponseWindow and startResponseWindow(duel, getOpponentIndex(playerIndex), event, {
        continuation = 'pending_actions',
        promptText = promptText or 'Your opponent is resolving an effect. Chain a response?'
    }) then
        return true
    end

    duel.pendingContinuation = nil
    return false
end

local function cardMatchesSearchFilter(card, filter)
    local def = card and getCardDefinition(card.cardId) or nil
    filter = filter or {}

    if not def then return false end

    if filter.notUid and tostring(card.uid or '') == tostring(filter.notUid) then
        return false
    end

    if filter.type and string.upper(tostring(def.type or '')) ~= string.upper(tostring(filter.type)) then
        return false
    end

    if type(filter.typesAny) == 'table' then
        local typeText = string.upper(tostring(def.type or ''))
        local matched = false
        for _, value in ipairs(filter.typesAny) do
            if typeText == string.upper(tostring(value)) then
                matched = true
                break
            end
        end
        if not matched then return false end
    end

    if filter.nameContains then
        local nameText = string.lower(tostring(def.name or ''))
        if not nameText:find(string.lower(tostring(filter.nameContains)), 1, true) then
            return false
        end
    end

    if type(filter.nameContainsAny) == 'table' then
        local nameText = string.lower(tostring(def.name or ''))
        local matched = false
        for _, value in ipairs(filter.nameContainsAny) do
            if nameText:find(string.lower(tostring(value)), 1, true) then
                matched = true
                break
            end
        end
        if not matched then return false end
    end

    if filter.jobContains then
        local jobText = string.lower(tostring(def.job or ''))
        if not jobText:find(string.lower(tostring(filter.jobContains)), 1, true) then
            return false
        end
    end

    if type(filter.jobContainsAny) == 'table' then
        local jobText = string.lower(tostring(def.job or ''))
        local matched = false
        for _, value in ipairs(filter.jobContainsAny) do
            if jobText:find(string.lower(tostring(value)), 1, true) then
                matched = true
                break
            end
        end
        if not matched then return false end
    end

    local level = getCardLevelValue(def)
    if filter.level and level ~= tonumber(filter.level) then return false end
    if filter.levelMin and level < tonumber(filter.levelMin) then return false end
    if filter.levelMax and level > tonumber(filter.levelMax) then return false end

    if filter.attackMax and getCardStat(card, 'attack') > tonumber(filter.attackMax) then return false end
    if filter.attackMin and getCardStat(card, 'attack') < tonumber(filter.attackMin) then return false end

    if filter.cardTag then
        local wanted = string.lower(tostring(filter.cardTag))
        local found = false
        for _, tag in ipairs(def.cardTags or {}) do
            if string.lower(tostring(tag)) == wanted then
                found = true
                break
            end
        end
        if not found then return false end
    end

    if type(filter.cardTagsAny) == 'table' then
        local found = false
        for _, wantedTag in ipairs(filter.cardTagsAny) do
            local wanted = string.lower(tostring(wantedTag))
            for _, tag in ipairs(def.cardTags or {}) do
                if string.lower(tostring(tag)) == wanted then
                    found = true
                    break
                end
            end
            if found then break end
        end
        if not found then return false end
    end

    return true
end

local function isTargetProtectedFromPlayer(duel, targetingPlayerIndex, targetPlayerIndex, targetCard, reason)
    if not DuelEffects or not DuelEffects.IsTargetProtected or not getEffectApi then return false end
    if not targetCard then return false end

    local _, _, _, zoneName, zoneIndex = findCardByUid(duel, targetCard.uid)
    return DuelEffects.IsTargetProtected(duel, targetingPlayerIndex, targetPlayerIndex, targetCard, {
        reason = reason or 'card_effect',
        targetZone = zoneName,
        targetZoneIndex = zoneIndex
    }, getEffectApi()) == true
end

local function collectSelectionChoices(duel, playerIndex, zoneName, filter, targetingPlayerIndex, reason)
    local choices = {}
    local player = duel.players[playerIndex]
    if not player then return choices end

    local function addIfMatch(card)
        if card
            and cardMatchesSearchFilter(card, filter or {})
            and not isTargetProtectedFromPlayer(duel, targetingPlayerIndex, playerIndex, card, reason) then
            choices[#choices + 1] = buildCardPayload(card)
        end
    end

    if zoneName == 'hand' then
        for _, card in ipairs(player.hand or {}) do
            addIfMatch(card)
        end
    elseif zoneName == 'deck_top' then
        local count = tonumber(filter and filter.count) or 3
        for index = 1, math.min(count, #(player.deck or {})) do
            addIfMatch(player.deck[index])
        end
    elseif zoneName == 'graveyard' then
        for _, card in ipairs(player.graveyard or {}) do
            addIfMatch(card)
        end
    elseif zoneName == 'hand_and_field' then
        for _, card in ipairs(player.hand or {}) do
            addIfMatch(card)
        end
        for i = 1, 3 do
            addIfMatch(player.fighterZones and player.fighterZones[i] or nil)
        end
        for i = 1, 4 do
            addIfMatch(player.itemZones and player.itemZones[i] or nil)
        end
        if player.locationZone then addIfMatch(player.locationZone) end
        for _, slot in pairs(player.equipmentZones or {}) do
            if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                    addIfMatch(slot[key])
                end
            else
                addIfMatch(slot)
            end
        end
    elseif zoneName == 'field' or zoneName == 'fighterZones' then
        for i = 1, 3 do
            addIfMatch(player.fighterZones and player.fighterZones[i] or nil)
        end

        if zoneName == 'field' then
            for i = 1, 4 do
                addIfMatch(player.itemZones and player.itemZones[i] or nil)
            end
            if player.locationZone then addIfMatch(player.locationZone) end
            for _, slot in pairs(player.equipmentZones or {}) do
                if slot and (slot.vehicle or slot.weapon or slot.equipment) then
                    for _, key in ipairs({ 'vehicle', 'weapon', 'equipment' }) do
                        addIfMatch(slot[key])
                    end
                else
                    addIfMatch(slot)
                end
            end
        end
    end

    return choices
end

queueCardSelection = function(duel, playerIndex, sourceCard, options)
    if not duel or duel.pendingSelection then return false end

    options = options or {}
    local selectionOwner = tostring(options.owner or 'self'):lower()
    local targetPlayerIndex = selectionOwner == 'opponent' and getOpponentIndex(playerIndex) or playerIndex
    local choices = {}
    if selectionOwner == 'any' or selectionOwner == 'both' then
        targetPlayerIndex = nil
        for _, candidatePlayerIndex in ipairs({ playerIndex, getOpponentIndex(playerIndex) }) do
            local candidateChoices = collectSelectionChoices(duel, candidatePlayerIndex, options.zone or 'field', options.filter, playerIndex, options.reason or 'card_effect')
            for _, choice in ipairs(candidateChoices) do
                choices[#choices + 1] = choice
            end
        end
    else
        choices = collectSelectionChoices(duel, targetPlayerIndex, options.zone or 'field', options.filter, playerIndex, options.reason or 'card_effect')
    end

    local selectionMode = tostring(options.mode or '')
    if (selectionMode == 'attach_source_to_selected_fighter' or selectionMode == 'hayes_choose_control_fighter') and sourceCard then
        local equipChoices = {}
        for _, choice in ipairs(choices) do
            local _, targetPlayerState, _, targetZoneName, targetZoneIndex = findCardByUid(duel, choice.uid)
            if targetZoneName == 'fighterZones' and canEquipCardToFighter(targetPlayerState, sourceCard, targetZoneIndex) then
                equipChoices[#equipChoices + 1] = choice
            end
        end
        choices = equipChoices
    end

    if selectionMode == 'take_control_selected_equipment' then
        local controllableChoices = {}
        local selectingPlayerState = duel.players[playerIndex]
        for _, choice in ipairs(choices) do
            local equipmentCard, _, _, targetZoneName = findCardByUid(duel, choice.uid)
            if equipmentCard and targetZoneName == 'equipmentZones' then
                for fighterZoneIndex = 1, 3 do
                    if canEquipCardToFighter(selectingPlayerState, equipmentCard, fighterZoneIndex) then
                        controllableChoices[#controllableChoices + 1] = choice
                        break
                    end
                end
            end
        end
        choices = controllableChoices
    end

    local playerState = duel.players[playerIndex]
    if not playerState then return false end

    if #choices == 0 then
        duel.log = duel.log or {}
        duel.log[#duel.log + 1] = {
            turn = duel.turnNumber,
            phase = duel.phase,
            message = options.emptyMessage or 'No valid targets found for effect.'
        }
        TriggerClientEvent('QBCore:Notify', playerState.source, options.emptyMessage or 'No valid targets found.', 'error')
        return false
    end

    duel.selectionCounter = (duel.selectionCounter or 0) + 1
    duel.pendingSelection = {
        id = tostring(duel.selectionCounter),
        playerIndex = playerIndex,
        sourceUid = sourceCard and sourceCard.uid or nil,
        targetPlayerIndex = targetPlayerIndex,
        zone = options.zone or 'field',
        filter = options.filter or {},
        mode = options.mode or 'effect_select',
        payload = options.payload or {},
        title = options.title or 'Choose Card',
        text = options.text or 'Choose 1 card.',
        minChoices = math.max(0, tonumber(options.minChoices) or 1),
        maxChoices = math.max(1, tonumber(options.maxChoices) or 1),
        choices = choices
    }

    TriggerClientEvent('bstar_cards:client:PendingCardSelection', playerState.source, {
        duelId = duel.id,
        selection = {
            id = duel.pendingSelection.id,
            title = duel.pendingSelection.title,
            text = duel.pendingSelection.text,
            minChoices = duel.pendingSelection.minChoices,
            maxChoices = duel.pendingSelection.maxChoices,
            choices = duel.pendingSelection.choices
        }
    })
    return true
end

queueDeckSearch = function(duel, playerIndex, sourceCard, filter, prompt)
    if not duel or duel.pendingSelection then return false end

    local playerState = duel.players[playerIndex]
    if not playerState then return false end

    local sourceDef = sourceCard and getCardDefinition(sourceCard.cardId) or nil

    local choices = {}
    local maxChoices = tonumber(prompt and prompt.maxChoices) or 30
    local mode = prompt and prompt.mode or 'add_to_hand'

    for _, card in ipairs(playerState.deck or {}) do
        if cardMatchesSearchFilter(card, filter) then
            local hasValidTarget = true

            if mode == 'equip_from_deck' then
                hasValidTarget = false
                for i = 1, 3 do
                    if canEquipCardToFighter(playerState, card, i) then
                        hasValidTarget = true
                        break
                    end
                end
            end

            if hasValidTarget then
                choices[#choices + 1] = buildCardPayload(card)
                if #choices >= maxChoices then break end
            end
        end
    end

    if #choices == 0 then
        duel.log = duel.log or {}
        duel.log[#duel.log + 1] = {
            turn = duel.turnNumber,
            phase = duel.phase,
            message = 'No matching cards found for deck search.'
        }
        TriggerClientEvent('QBCore:Notify', playerState.source, ('No matching cards found in deck for %s.'):format(sourceDef and sourceDef.name or 'this effect'), 'error')
        return false
    end

    duel.selectionCounter = (duel.selectionCounter or 0) + 1
    duel.pendingSelection = {
        id = tostring(duel.selectionCounter),
        playerIndex = playerIndex,
        sourceUid = sourceCard and sourceCard.uid or nil,
        zone = 'deck',
        filter = filter or {},
        mode = mode,
        action = prompt and prompt.action or nil,
        title = prompt and prompt.title or 'Search Deck',
        text = prompt and prompt.text or 'Choose 1 card to add to your hand.',
        minChoices = math.max(0, tonumber(prompt and prompt.minChoices) or 1),
        maxChoices = math.max(1, tonumber(prompt and prompt.maxChoices) or 1),
        choices = choices
    }

    TriggerClientEvent('QBCore:Notify', playerState.source, ('Choose from %s matching card(s).'):format(#choices), 'primary')
    TriggerClientEvent('bstar_cards:client:PendingCardSelection', playerState.source, {
        duelId = duel.id,
        selection = {
            id = duel.pendingSelection.id,
            title = duel.pendingSelection.title,
            text = duel.pendingSelection.text,
            minChoices = duel.pendingSelection.minChoices,
            maxChoices = duel.pendingSelection.maxChoices,
            choices = duel.pendingSelection.choices
        }
    })
    return true
end

scheduleDelayedTask = function(duel, task)
    if not duel or type(task) ~= 'table' then return false end

    duel.delayedTaskCounter = (duel.delayedTaskCounter or 0) + 1
    duel.delayedTasks = duel.delayedTasks or {}

    local targetUids = {}
    if type(task.targetUids) == 'table' then
        for _, uid in ipairs(task.targetUids) do
            targetUids[#targetUids + 1] = uid
        end
    elseif task.targetUids then
        targetUids[#targetUids + 1] = task.targetUids
    end

    local id = tostring(task.id or duel.delayedTaskCounter)
    local delayedTask = {
        id = id,
        label = task.label,
        sourcePlayerIndex = tonumber(task.sourcePlayerIndex) or duel.turnPlayer,
        sourceUid = task.sourceUid,
        sourceCardId = task.sourceCardId,
        zoneIndex = task.zoneIndex,
        tickPlayerIndex = tonumber(task.tickPlayerIndex) or tonumber(task.sourcePlayerIndex) or duel.turnPlayer,
        timing = tostring(task.timing or 'end_turn'),
        remaining = math.max(0, tonumber(task.remaining) or 1),
        targetUids = targetUids,
        actions = task.actions or {},
        requireSourceZone = task.requireSourceZone
    }

    duel.delayedTasks[#duel.delayedTasks + 1] = delayedTask
    duel.log = duel.log or {}
    duel.log[#duel.log + 1] = {
        turn = duel.turnNumber,
        phase = duel.phase,
        message = ('Scheduled delayed task %s for player %s.'):format(id, delayedTask.tickPlayerIndex)
    }

    return true
end

local function processDelayedTasks(duel, playerIndex, timing)
    if not duel or type(duel.delayedTasks) ~= 'table' then return end
    if not DuelEffects or not DuelEffects.RunActions or not getEffectApi then return end

    local remainingTasks = {}
    local api = getEffectApi()

    for _, task in ipairs(duel.delayedTasks) do
        local shouldTick = tonumber(task.tickPlayerIndex) == tonumber(playerIndex)
            and tostring(task.timing or 'end_turn') == tostring(timing)

        if shouldTick then
            task.remaining = math.max(0, (tonumber(task.remaining) or 0) - 1)
        end

        if shouldTick and task.remaining <= 0 then
            local sourceCard, sourceZoneName = nil, nil
            if task.sourceUid then
                local foundCard, _, _, foundZoneName = findCardByUid(duel, task.sourceUid)
                sourceCard = foundCard
                sourceZoneName = foundZoneName
            end
            if task.requireSourceZone and tostring(sourceZoneName or '') ~= tostring(task.requireSourceZone) then
                duel.log = duel.log or {}
                duel.log[#duel.log + 1] = {
                    turn = duel.turnNumber,
                    phase = duel.phase,
                    message = ('Delayed task %s fizzled because its source left %s.'):format(task.id or 'effect', task.requireSourceZone)
                }
                sourceCard = nil
            end
            if not sourceCard and task.sourceCardId then
                if task.requireSourceZone then
                    -- Source was required to remain in play, so do not resolve from a synthetic source.
                else
                    sourceCard = {
                        uid = task.sourceUid,
                        cardId = task.sourceCardId,
                        owner = task.sourcePlayerIndex,
                        controller = task.sourcePlayerIndex,
                        zone = 'delayed'
                    }
                end
            end

            if sourceCard or not task.requireSourceZone then
                local targetUid = task.targetUids and task.targetUids[1] or nil
                DuelEffects.RunActions(duel, tonumber(task.sourcePlayerIndex) or playerIndex, sourceCard, task.actions or {}, {
                    delayedTask = task,
                    zoneIndex = task.zoneIndex,
                    targetUid = targetUid,
                    targetUids = task.targetUids or {}
                }, api)
                checkWinCondition(duel)
            end
        else
            remainingTasks[#remainingTasks + 1] = task
        end
    end

    duel.delayedTasks = remainingTasks
end

addSpecialSummonDrawWatcher = function(duel, playerIndex, options)
    if not duel or not playerIndex then return false end
    options = options or {}

    duel.specialSummonDrawWatchers = duel.specialSummonDrawWatchers or {}
    duel.specialSummonDrawWatchers[#duel.specialSummonDrawWatchers + 1] = {
        playerIndex = playerIndex,
        watchedPlayerIndex = tonumber(options.watchedPlayerIndex) or getOpponentIndex(playerIndex),
        amount = math.max(1, tonumber(options.amount) or 1),
        expiresTurnNumber = duel.turnNumber,
        expiresPlayerIndex = duel.turnPlayer
    }

    duel.log = duel.log or {}
    duel.log[#duel.log + 1] = {
        turn = duel.turnNumber,
        phase = duel.phase,
        message = ('Player %s is watching opponent special summons this turn.'):format(playerIndex)
    }

    return true
end

processSpecialSummonDrawWatchers = function(duel, event)
    if not duel or type(duel.specialSummonDrawWatchers) ~= 'table' or type(event) ~= 'table' then return end
    if tostring(event.summonType or '') == 'normal' then return end

    local summoningPlayer = tonumber(event.summoningPlayer)
    if not summoningPlayer then return end

    local remainingWatchers = {}
    for _, watcher in ipairs(duel.specialSummonDrawWatchers) do
        local expired = tonumber(watcher.expiresTurnNumber) ~= tonumber(duel.turnNumber)
        if not expired then
            remainingWatchers[#remainingWatchers + 1] = watcher
            if tonumber(watcher.watchedPlayerIndex) == summoningPlayer then
                drawCards(duel, tonumber(watcher.playerIndex), tonumber(watcher.amount) or 1)
                duel.log = duel.log or {}
                duel.log[#duel.log + 1] = {
                    turn = duel.turnNumber,
                    phase = duel.phase,
                    message = ('Player %s drew %s from Toll Booth.'):format(watcher.playerIndex, watcher.amount or 1)
                }
            end
        end
    end

    duel.specialSummonDrawWatchers = remainingWatchers
end

addPlayedTypeDrawWatcher = function(duel, playerIndex, options)
    if not duel or not duel.players[playerIndex] then return false end

    options = options or {}
    duel.playedTypeDrawWatchers = duel.playedTypeDrawWatchers or {}
    duel.playedTypeDrawWatchers[#duel.playedTypeDrawWatchers + 1] = {
        playerIndex = playerIndex,
        watchedPlayerIndex = tonumber(options.watchedPlayerIndex) or getOpponentIndex(playerIndex),
        cardType = string.upper(tostring(options.cardType or '')),
        amount = math.max(1, tonumber(options.amount) or 1),
        expiresTurnNumber = duel.turnNumber + math.max(0, (tonumber(options.turns) or 1) - 1)
    }

    duel.log = duel.log or {}
    duel.log[#duel.log + 1] = {
        turn = duel.turnNumber,
        phase = duel.phase,
        message = ('Player %s is watching played card types this turn.'):format(playerIndex)
    }

    return true
end

processPlayedTypeDrawWatchers = function(duel, event)
    if not duel or type(duel.playedTypeDrawWatchers) ~= 'table' or type(event) ~= 'table' then return end

    local playingPlayer = tonumber(event.playingPlayer)
    local playedType = string.upper(tostring(event.playedCardType or ''))
    if not playingPlayer or playedType == '' then return end

    local remainingWatchers = {}
    for _, watcher in ipairs(duel.playedTypeDrawWatchers) do
        local expired = tonumber(duel.turnNumber) > tonumber(watcher.expiresTurnNumber)
        if not expired then
            remainingWatchers[#remainingWatchers + 1] = watcher
            if tonumber(watcher.watchedPlayerIndex) == playingPlayer and string.upper(tostring(watcher.cardType or '')) == playedType then
                drawCards(duel, tonumber(watcher.playerIndex), tonumber(watcher.amount) or 1)
                duel.log = duel.log or {}
                duel.log[#duel.log + 1] = {
                    turn = duel.turnNumber,
                    phase = duel.phase,
                    message = ('Player %s drew %s from a played-card watcher.'):format(watcher.playerIndex, watcher.amount or 1)
                }
            end
        end
    end

    duel.playedTypeDrawWatchers = remainingWatchers
end

local function runEndPhaseEffects(duel, playerIndex)
    local key = tostring(playerIndex) .. ':' .. tostring(duel.turnNumber)
    if duel.endPhaseEffectsResolvedForTurn == key then
        return
    end

    duel.endPhaseEffectsResolvedForTurn = key

    if DuelEffects and getEffectApi then
        DuelEffects.RunFieldTrigger(duel, 'end_phase', playerIndex, {
            playerIndex = playerIndex
        }, getEffectApi())
        checkWinCondition(duel)
    end

    if type(duel.specialSummonDrawWatchers) == 'table' then
        local remainingWatchers = {}
        for _, watcher in ipairs(duel.specialSummonDrawWatchers) do
            local expiresNow = tonumber(watcher.expiresTurnNumber) == tonumber(duel.turnNumber)
                and tonumber(watcher.expiresPlayerIndex) == tonumber(playerIndex)
            if not expiresNow then
                remainingWatchers[#remainingWatchers + 1] = watcher
            end
        end
        duel.specialSummonDrawWatchers = remainingWatchers
    end
end

local function processCardStatuses(duel, playerIndex, timing)
    local playerState = duel and duel.players and duel.players[playerIndex] or nil
    if not playerState then return end

    if type(playerState.statuses) == 'table' then
        local remainingPlayerStatuses = {}

        for _, status in ipairs(playerState.statuses) do
            local statusTiming = tostring(status.timing or 'end_turn')
            local id = tostring(status.id or status.name or ''):lower()

            if statusTiming == tostring(timing) then
                if id == 'burn' then
                    local amount = tonumber(status.amount or status.damage or 5) or 5
                    local dealt = applyLifePointLoss(duel, playerIndex, amount, {
                        reason = 'status',
                        statusId = id,
                        sourceUid = status.sourceUid,
                        sourceCardId = status.sourceCardId
                    })
                    if dealt > 0 then
                        duel.log = duel.log or {}
                        duel.log[#duel.log + 1] = {
                            turn = duel.turnNumber,
                            phase = duel.phase,
                            message = ('Player %s took %s burn LP damage.'):format(playerIndex, dealt)
                        }
                    end
                end

                if status.remaining ~= nil then
                    status.remaining = math.max(0, (tonumber(status.remaining) or 0) - 1)
                end
            end

            if status.remaining == nil or tonumber(status.remaining) > 0 then
                remainingPlayerStatuses[#remainingPlayerStatuses + 1] = status
            end
        end

        playerState.statuses = remainingPlayerStatuses
    end

    for zoneIndex, card in pairs(playerState.fighterZones or {}) do
        if card and type(card.statuses) == 'table' then
            local remainingStatuses = {}

            for _, status in ipairs(card.statuses) do
                local statusTiming = tostring(status.timing or 'end_turn')
                local id = tostring(status.id or status.name or ''):lower()

                if statusTiming == tostring(timing) then
                    if id == 'burn' then
                        local prevented = false
                        if DuelEffects and DuelEffects.RunReplacement and getEffectApi then
                            local result = DuelEffects.RunReplacement(duel, 'would_take_status_damage', playerIndex, {
                                statusId = id,
                                targetUid = card.uid,
                                targetCard = card,
                                targetCardId = card.cardId,
                                targetPlayerIndex = playerIndex,
                                targetZoneName = 'fighterZones',
                                targetZoneIndex = zoneIndex
                            }, getEffectApi())
                            prevented = result and result.prevented == true
                        end

                        if not prevented then
                            ensureFighterHp(card)
                            local amount = tonumber(status.amount or status.damage or 5) or 5
                            card.currentHp = math.max(0, (tonumber(card.currentHp) or 0) - amount)
                            duel.log = duel.log or {}
                            duel.log[#duel.log + 1] = {
                                turn = duel.turnNumber,
                                phase = duel.phase,
                                message = ('%s took %s burn damage.'):format(card.cardId, amount)
                            }
                        end
                    end

                    if status.remaining ~= nil then
                        status.remaining = math.max(0, (tonumber(status.remaining) or 0) - 1)
                    end
                end

                if status.remaining == nil or tonumber(status.remaining) > 0 then
                    remainingStatuses[#remainingStatuses + 1] = status
                end
            end

            card.statuses = remainingStatuses

            if (tonumber(card.currentHp) or 0) <= 0 then
                moveFieldCardToGraveyard(playerState, zoneIndex, duel, {
                    reason = 'status',
                    sourceCardId = id
                })
            end
        end
    end

    checkWinCondition(duel)
end

local function completeEndTurn(duel, playerIndex)
    resetBattleFlags(duel.players[playerIndex])

    duel.turnPlayer = getOpponentIndex(duel.turnPlayer)
    duel.turnNumber = duel.turnNumber + 1
    duel.phase = "draw"
    duel.hasDrawnThisTurn = false
    duel.endPhaseEffectsResolvedForTurn = nil

    resetTurnFlags(duel.players[duel.turnPlayer])
    processDelayedTasks(duel, duel.turnPlayer, 'start_turn')
end

function Duel.Surrender(src, duelId)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    if duel.status == "finished" then
        return true
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if not playerIndex then
        return false, 'Player not in duel'
    end

    duel.status = "finished"
    duel.winner = getOpponentIndex(playerIndex)
    duel.winReason = "surrender"

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.DebugSpawnFighter(duelId, playerIndex, cardId, zoneIndex)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    local playerState = duel.players[playerIndex]
    if not playerState then
        return false, 'Invalid player index'
    end

    zoneIndex = tonumber(zoneIndex)
    if not zoneIndex or zoneIndex < 1 or zoneIndex > 3 then
        return false, 'Invalid zone index'
    end

    if playerState.fighterZones[zoneIndex] then
        return false, 'Zone already occupied'
    end

    local def = getCardDefinition(cardId)
    if not def then
        return false, 'Card definition not found'
    end

    local card = {
        uid = ("debug_%s_%s_%s"):format(playerIndex, cardId, math.random(100000, 999999)),
        cardId = cardId,
        owner = playerIndex,
        controller = playerIndex,
        zone = "fighterZone",
        hasAttacked = false
    }

    resetFighterHp(card)
    playerState.fighterZones[zoneIndex] = card

    if DuelEffects and getEffectApi then
        DuelEffects.RunTrigger(duel, 'on_summon', playerIndex, card, {
            zoneIndex = zoneIndex,
            summonType = 'debug'
        }, getEffectApi())
        checkWinCondition(duel)
    end

    sendDuelStateToPlayers(duel)
    return true
end

local function sendBattleEventToPlayers(duel, battleResult)
    local sentToSource = {}
    for _, playerState in pairs(duel.players or {}) do
        local targetSrc = playerState.source
        if targetSrc and not sentToSource[targetSrc] then
            TriggerClientEvent('bstar_cards:client:BattleEvent', targetSrc, battleResult)
            sentToSource[targetSrc] = true
        end
    end
end

local function resolveBattleAfterResponses(duel, battle)
    if not duel or not battle then return false end

    if refreshContinuousModifiers then
        refreshContinuousModifiers(duel)
    end

    local playerIndex = tonumber(battle.attackingPlayer)
    local defenderIndex = tonumber(battle.defendingPlayer)
    local attackerZoneIndex = tonumber(battle.attackerZoneIndex)
    local targetZoneIndex = tonumber(battle.targetZoneIndex) or 0
    local targetType = battle.targetType
    local attackerState = duel.players[playerIndex]
    local defenderState = duel.players[defenderIndex]
    local attackerCard = attackerState and attackerState.fighterZones and attackerState.fighterZones[attackerZoneIndex] or nil
    local effectApi = DuelEffects and getEffectApi and getEffectApi() or nil

    if not attackerCard or attackerCard.uid ~= battle.attackerUid then
        sendDuelStateToPlayers(duel)
        return false
    end

    ensureFighterHp(attackerCard)

    local attackerATK = getBattleAttackStat(attackerState, attackerZoneIndex, attackerCard, nil)
    local battleResult = {
        attackerZoneIndex = attackerZoneIndex,
        targetType = targetType,
        targetZoneIndex = targetZoneIndex,
        attackingPlayer = playerIndex,
        defendingPlayer = defenderIndex,
        attackerUid = attackerCard.uid,
        defenderUid = battle.defenderUid,
        attackerCard = buildCardPayload(attackerCard),
        defenderCard = nil,
        attackerDestroyed = false,
        defenderDestroyed = false,
        dodged = false,
        dodgeChance = 0,
        damageToDefenderPlayer = 0,
        damageToAttackerPlayer = 0,
        damageToDefenderFighter = 0,
        damageToAttackerFighter = 0,
        defenderHpBefore = nil,
        defenderHpAfter = nil,
        attackerHpBefore = attackerCard.currentHp,
        attackerHpAfter = attackerCard.currentHp
    }

    if targetType == 'direct' then
        markBattleAttackUsed(attackerState, attackerCard)

        if getOccupiedFighterCount(defenderState) <= 0 then
            battleResult.damageToDefenderPlayer = applyLifePointLoss(duel, defenderIndex, attackerATK, {
                reason = 'direct_attack',
                sourceUid = attackerCard.uid,
                sourceCardId = attackerCard.cardId,
                attackingPlayer = playerIndex,
                defendingPlayer = defenderIndex
            })

            if DuelEffects and effectApi then
                DuelEffects.RunFieldTrigger(duel, 'on_direct_attack_declared', playerIndex, {
                    attackerUid = attackerCard.uid,
                    damage = attackerATK,
                    attackingPlayer = playerIndex,
                    defendingPlayer = defenderIndex
                }, effectApi)
            end
        else
            duel.log = duel.log or {}
            duel.log[#duel.log + 1] = {
                turn = duel.turnNumber,
                phase = duel.phase,
                message = 'Direct attack no longer has a clear path after responses.'
            }
        end

        if DuelEffects and effectApi then
            DuelEffects.RunFieldTrigger(duel, 'on_battle_damage', playerIndex, battleResult, effectApi)
            DuelEffects.RunFieldTrigger(duel, 'on_battle_damage', defenderIndex, battleResult, effectApi)
        end

        checkWinCondition(duel)
        sendDuelStateToPlayers(duel)
        sendBattleEventToPlayers(duel, battleResult)
        return true
    end

    if targetType ~= 'fighter' then
        sendDuelStateToPlayers(duel)
        return false
    end

    local defenderCard = defenderState and defenderState.fighterZones and defenderState.fighterZones[targetZoneIndex] or nil
    if not defenderCard or defenderCard.uid ~= battle.defenderUid then
        markBattleAttackUsed(attackerState, attackerCard)
        duel.log = duel.log or {}
        duel.log[#duel.log + 1] = {
            turn = duel.turnNumber,
            phase = duel.phase,
            message = 'Attack target no longer exists after responses.'
        }
        sendDuelStateToPlayers(duel)
        sendBattleEventToPlayers(duel, battleResult)
        return true
    end

    ensureFighterHp(defenderCard)
    battleResult.defenderCard = buildCardPayload(defenderCard)
    attackerATK = getBattleAttackStat(attackerState, attackerZoneIndex, attackerCard, defenderCard)

    local dodgeChance = calculateDodgeChance(attackerCard, defenderCard)
    local dodged = rollSuccess(dodgeChance)

    markBattleAttackUsed(attackerState, attackerCard)
    battleResult.dodged = dodged
    battleResult.dodgeChance = dodgeChance

    if dodged then
        if DuelEffects and effectApi then
            DuelEffects.RunFieldTrigger(duel, 'on_dodge', defenderIndex, {
                attackerUid = attackerCard.uid,
                defenderUid = defenderCard.uid,
                attackerZoneIndex = attackerZoneIndex,
                defenderZoneIndex = targetZoneIndex,
                attackingPlayer = playerIndex,
                defendingPlayer = defenderIndex
            }, effectApi)
        end

        sendDuelStateToPlayers(duel)
        sendBattleEventToPlayers(duel, battleResult)
        return true
    end

    local defenderHpBefore = defenderCard.currentHp or getCardBaseHp(defenderCard)
    if DuelEffects and effectApi then
        local damageEvent = {
            reason = 'battle_damage',
            amount = attackerATK,
            targetPlayerIndex = defenderIndex,
            targetUid = defenderCard.uid,
            targetCard = defenderCard,
            sourceUid = attackerCard.uid,
            sourceCardId = attackerCard.cardId,
            attackerUid = attackerCard.uid,
            defenderUid = defenderCard.uid,
            attackingPlayer = playerIndex,
            defendingPlayer = defenderIndex
        }
        DuelEffects.RunReplacement(duel, 'would_take_battle_damage', defenderIndex, damageEvent, effectApi)
        attackerATK = damageEvent.replacementPrevented == true and 0 or math.max(0, tonumber(damageEvent.amount) or attackerATK)
    end
    local defenderHpAfter = math.max(0, defenderHpBefore - attackerATK)

    defenderCard.currentHp = defenderHpAfter
    battleResult.damageToDefenderFighter = math.max(0, defenderHpBefore - defenderHpAfter)
    battleResult.defenderHpBefore = defenderHpBefore
    battleResult.defenderHpAfter = defenderHpAfter
    battleResult.defenderCard = buildCardPayload(defenderCard)

    if defenderHpAfter <= 0 then
        local overflowDamage = math.max(0, attackerATK - defenderHpBefore)

        if overflowDamage > 0 then
            battleResult.damageToDefenderPlayer = applyLifePointLoss(duel, defenderIndex, overflowDamage, {
                reason = 'battle_overflow',
                sourceUid = attackerCard.uid,
                sourceCardId = attackerCard.cardId,
                attackingPlayer = playerIndex,
                defendingPlayer = defenderIndex
            })
        end

        local destroyedCard = moveFieldCardToGraveyard(defenderState, targetZoneIndex, duel, {
            reason = 'battle',
            sourceUid = attackerCard.uid,
            sourceCardId = attackerCard.cardId,
            targetPlayerIndex = defenderIndex
        })
        battleResult.defenderDestroyed = destroyedCard ~= nil

        if DuelEffects and effectApi and destroyedCard then
            local destroyedEvent = {
                attackerUid = attackerCard.uid,
                destroyedUid = destroyedCard.uid,
                destroyedCard = destroyedCard,
                attackerZoneIndex = attackerZoneIndex,
                defenderZoneIndex = targetZoneIndex,
                attackingPlayer = playerIndex,
                defendingPlayer = defenderIndex
            }
            DuelEffects.RunTrigger(duel, 'on_destroyed_by_battle', defenderIndex, destroyedCard, {
                attackerUid = attackerCard.uid,
                destroyedUid = destroyedCard.uid,
                destroyedCard = destroyedCard,
                attackerZoneIndex = attackerZoneIndex,
                defenderZoneIndex = targetZoneIndex,
                attackingPlayer = playerIndex,
                defendingPlayer = defenderIndex
            }, effectApi)
            DuelEffects.RunFieldTrigger(duel, 'on_friendly_destroyed_by_battle', defenderIndex, destroyedEvent, effectApi)
        end
    end

    battleResult.attackerHpAfter = attackerCard.currentHp

    if DuelEffects and effectApi then
        DuelEffects.RunFieldTrigger(duel, 'on_battle_damage', playerIndex, battleResult, effectApi)
        DuelEffects.RunFieldTrigger(duel, 'on_battle_damage', defenderIndex, battleResult, effectApi)
    end

    checkWinCondition(duel)
    sendDuelStateToPlayers(duel)
    sendBattleEventToPlayers(duel, battleResult)
    return true
end

continuePendingBattle = function(duel)
    local battle = duel and duel.pendingBattle or nil
    if not battle then return false end

    duel.pendingBattle = nil
    return resolveBattleAfterResponses(duel, battle)
end

function Duel.Attack(src, duelId, attackerZoneIndex, targetType, targetZoneIndex)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    if duel.status ~= "active" then
        return false, 'Duel is not active'
    end

    if duel.pendingEffect or duel.pendingSelection or duel.effectChain then
        return false, 'Resolve the pending effect first'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if not playerIndex then
        return false, 'Player not in duel'
    end

    if duel.turnPlayer ~= playerIndex then
        return false, 'Not your turn'
    end

    if duel.phase ~= "battle" then
        return false, 'You can only attack in Battle Phase'
    end

    if refreshContinuousModifiers then
        refreshContinuousModifiers(duel)
    end

    if duel.turnNumber == 1 and duel.firstTurnPlayer == playerIndex then
        return false, 'The player who goes first cannot attack on their first turn'
    end

    local attackerState = duel.players[playerIndex]
    local defenderIndex = getOpponentIndex(playerIndex)
    local defenderState = duel.players[defenderIndex]

    attackerZoneIndex = tonumber(attackerZoneIndex)
    if not attackerZoneIndex or attackerZoneIndex < 1 or attackerZoneIndex > 3 then
        return false, 'Invalid attacker zone'
    end

    local attackerCard = attackerState.fighterZones[attackerZoneIndex]
    if not attackerCard then
        return false, 'No attacker in that zone'
    end

    ensureFighterHp(attackerCard)

    if not hasRemainingBattleAttacks(attackerState, attackerCard) then
        return false, 'This fighter already attacked this turn'
    end

    if cardHasStatus(attackerCard, 'cannot_attack') then
        return false, 'This fighter cannot attack'
    end

    local attackerATK = getBattleAttackStat(attackerState, attackerZoneIndex, attackerCard, nil)
    local effectApi = DuelEffects and getEffectApi and getEffectApi() or nil

    local battleResult = {
        attackerZoneIndex = attackerZoneIndex,
        targetType = targetType,
        targetZoneIndex = tonumber(targetZoneIndex) or 0,
        attackingPlayer = playerIndex,
        defendingPlayer = defenderIndex,
        attackerUid = attackerCard.uid,
        defenderUid = nil,
        attackerCard = buildCardPayload(attackerCard),
        defenderCard = nil,
        attackerDestroyed = false,
        defenderDestroyed = false,
        dodged = false,
        dodgeChance = 0,
        damageToDefenderPlayer = 0,
        damageToAttackerPlayer = 0,
        damageToDefenderFighter = 0,
        damageToAttackerFighter = 0,
        defenderHpBefore = nil,
        defenderHpAfter = nil,
        attackerHpBefore = attackerCard.currentHp,
        attackerHpAfter = attackerCard.currentHp
    }

    local declaredDefenderZoneIndex = tonumber(targetZoneIndex) or 0
    local declaredDefenderCard = nil
    if targetType == 'fighter' and declaredDefenderZoneIndex >= 1 and declaredDefenderZoneIndex <= 3 then
        declaredDefenderCard = defenderState and defenderState.fighterZones and defenderState.fighterZones[declaredDefenderZoneIndex] or nil
    end

    if DuelEffects and effectApi then
        DuelEffects.RunFieldTrigger(duel, 'on_attack_declared', playerIndex, {
            attackerUid = attackerCard.uid,
            attackerCard = attackerCard,
            defenderUid = declaredDefenderCard and declaredDefenderCard.uid or nil,
            defenderCard = declaredDefenderCard,
            attackerZoneIndex = attackerZoneIndex,
            targetType = targetType,
            targetZoneIndex = declaredDefenderZoneIndex,
            defenderZoneIndex = declaredDefenderZoneIndex,
            attackingPlayer = playerIndex,
            defendingPlayer = defenderIndex
        }, effectApi)
        DuelEffects.RunFieldTrigger(duel, 'on_attack_declared', defenderIndex, {
            attackerUid = attackerCard.uid,
            attackerCard = attackerCard,
            defenderUid = declaredDefenderCard and declaredDefenderCard.uid or nil,
            defenderCard = declaredDefenderCard,
            attackerZoneIndex = attackerZoneIndex,
            targetType = targetType,
            targetZoneIndex = declaredDefenderZoneIndex,
            defenderZoneIndex = declaredDefenderZoneIndex,
            attackingPlayer = playerIndex,
            defendingPlayer = defenderIndex
        }, effectApi)
    end

    -- Direct attack
    if targetType == 'direct' then
        if getOccupiedFighterCount(defenderState) > 0 then
            return false, 'Cannot direct attack while opponent controls fighters'
        end

        duel.pendingBattle = {
            attackingPlayer = playerIndex,
            defendingPlayer = defenderIndex,
            attackerZoneIndex = attackerZoneIndex,
            attackerUid = attackerCard.uid,
            targetType = targetType,
            targetZoneIndex = 0
        }

        if startResponseWindow and startResponseWindow(duel, defenderIndex, {
            responseEvent = 'attack_declared',
            trigger = 'attack_declared',
            attackerUid = attackerCard.uid,
            attackerCard = attackerCard,
            attackerZoneIndex = attackerZoneIndex,
            targetType = targetType,
            targetZoneIndex = 0,
            attackingPlayer = playerIndex,
            defendingPlayer = defenderIndex
        }, {
            continuation = 'battle',
            promptText = 'Your opponent declared a direct attack. Chain a response?'
        }) then
            sendDuelStateToPlayers(duel)
            return true
        end

        duel.pendingBattle = nil

        local dealtDamage = applyLifePointLoss(duel, defenderIndex, attackerATK, {
            reason = 'direct_attack',
            sourceUid = attackerCard.uid,
            sourceCardId = attackerCard.cardId,
            attackingPlayer = playerIndex,
            defendingPlayer = defenderIndex
        })
        markBattleAttackUsed(attackerState, attackerCard)
        battleResult.damageToDefenderPlayer = dealtDamage

        if DuelEffects and effectApi then
            DuelEffects.RunFieldTrigger(duel, 'on_direct_attack_declared', playerIndex, {
                attackerUid = attackerCard.uid,
                damage = attackerATK,
                attackingPlayer = playerIndex,
                defendingPlayer = defenderIndex
            }, effectApi)
            DuelEffects.RunFieldTrigger(duel, 'on_battle_damage', playerIndex, battleResult, effectApi)
            DuelEffects.RunFieldTrigger(duel, 'on_battle_damage', defenderIndex, battleResult, effectApi)
        end

        checkWinCondition(duel)
        sendDuelStateToPlayers(duel)

        local sentToSource = {}
        for _, playerState in pairs(duel.players) do
            local targetSrc = playerState.source
            if not sentToSource[targetSrc] then
                TriggerClientEvent('bstar_cards:client:BattleEvent', targetSrc, battleResult)
                sentToSource[targetSrc] = true
            end
        end

        return true
    end

    -- Fighter attack
    if targetType ~= 'fighter' then
        return false, 'Invalid target type'
    end

    targetZoneIndex = tonumber(targetZoneIndex)
    if not targetZoneIndex or targetZoneIndex < 1 or targetZoneIndex > 3 then
        return false, 'Invalid defender zone'
    end

    local defenderCard = defenderState.fighterZones[targetZoneIndex]
    if not defenderCard then
        return false, 'No defender in that zone'
    end

    if fighterHasVehicleEquipped(defenderState, targetZoneIndex) and playerControlsCardNamed(defenderState, 'Vehicle Armour') then
        return false, 'That fighter cannot be attacked while protected by Vehicle Armour'
    end

    ensureFighterHp(defenderCard)
    battleResult.defenderUid = defenderCard.uid
    battleResult.defenderCard = buildCardPayload(defenderCard)
    attackerATK = getBattleAttackStat(attackerState, attackerZoneIndex, attackerCard, defenderCard)

    duel.pendingBattle = {
        attackingPlayer = playerIndex,
        defendingPlayer = defenderIndex,
        attackerZoneIndex = attackerZoneIndex,
        attackerUid = attackerCard.uid,
        targetType = targetType,
        targetZoneIndex = targetZoneIndex,
        defenderUid = defenderCard.uid
    }

    if startResponseWindow and startResponseWindow(duel, defenderIndex, {
        responseEvent = 'attack_declared',
        trigger = 'attack_declared',
        attackerUid = attackerCard.uid,
        attackerCard = attackerCard,
        defenderUid = defenderCard.uid,
        defenderCard = defenderCard,
        attackerZoneIndex = attackerZoneIndex,
        defenderZoneIndex = targetZoneIndex,
        targetType = targetType,
        targetZoneIndex = targetZoneIndex,
        attackingPlayer = playerIndex,
        defendingPlayer = defenderIndex
    }, {
        continuation = 'battle',
        promptText = 'Your opponent declared an attack. Chain a response?'
    }) then
        sendDuelStateToPlayers(duel)
        return true
    end

    duel.pendingBattle = nil

    local dodgeChance = calculateDodgeChance(attackerCard, defenderCard)
    local dodged = rollSuccess(dodgeChance)

    markBattleAttackUsed(attackerState, attackerCard)
    battleResult.targetZoneIndex = targetZoneIndex
    battleResult.dodged = dodged
    battleResult.dodgeChance = dodgeChance

    if dodged then
        if DuelEffects and effectApi then
            DuelEffects.RunFieldTrigger(duel, 'on_dodge', defenderIndex, {
                attackerUid = attackerCard.uid,
                defenderUid = defenderCard.uid,
                attackerZoneIndex = attackerZoneIndex,
                defenderZoneIndex = targetZoneIndex,
                attackingPlayer = playerIndex,
                defendingPlayer = defenderIndex
            }, effectApi)
        end

        sendDuelStateToPlayers(duel)

        local sentToSource = {}
        for _, playerState in pairs(duel.players) do
            local targetSrc = playerState.source
            if not sentToSource[targetSrc] then
                TriggerClientEvent('bstar_cards:client:BattleEvent', targetSrc, battleResult)
                sentToSource[targetSrc] = true
            end
        end

        return true
    end

    local defenderHpBefore = defenderCard.currentHp or getCardBaseHp(defenderCard)
    if DuelEffects and effectApi then
        local damageEvent = {
            reason = 'battle_damage',
            amount = attackerATK,
            targetPlayerIndex = defenderIndex,
            targetUid = defenderCard.uid,
            targetCard = defenderCard,
            sourceUid = attackerCard.uid,
            sourceCardId = attackerCard.cardId,
            attackerUid = attackerCard.uid,
            defenderUid = defenderCard.uid,
            attackingPlayer = playerIndex,
            defendingPlayer = defenderIndex
        }
        DuelEffects.RunReplacement(duel, 'would_take_battle_damage', defenderIndex, damageEvent, effectApi)
        attackerATK = damageEvent.replacementPrevented == true and 0 or math.max(0, tonumber(damageEvent.amount) or attackerATK)
    end
    local defenderHpAfter = math.max(0, defenderHpBefore - attackerATK)

    defenderCard.currentHp = defenderHpAfter
    battleResult.damageToDefenderFighter = math.max(0, defenderHpBefore - defenderHpAfter)
    battleResult.defenderHpBefore = defenderHpBefore
    battleResult.defenderHpAfter = defenderHpAfter
    battleResult.defenderCard = buildCardPayload(defenderCard)

    if defenderHpAfter <= 0 then
        local overflowDamage = math.max(0, attackerATK - defenderHpBefore)

        if overflowDamage > 0 then
            battleResult.damageToDefenderPlayer = applyLifePointLoss(duel, defenderIndex, overflowDamage, {
                reason = 'battle_overflow',
                sourceUid = attackerCard.uid,
                sourceCardId = attackerCard.cardId,
                attackingPlayer = playerIndex,
                defendingPlayer = defenderIndex
            })
        end

        local destroyedCard = moveFieldCardToGraveyard(defenderState, targetZoneIndex, duel, {
            reason = 'battle',
            sourceUid = attackerCard.uid,
            sourceCardId = attackerCard.cardId,
            targetPlayerIndex = defenderIndex
        })
        battleResult.defenderDestroyed = destroyedCard ~= nil

        if DuelEffects and effectApi and destroyedCard then
            local destroyedEvent = {
                attackerUid = attackerCard.uid,
                destroyedUid = destroyedCard.uid,
                destroyedCard = destroyedCard,
                attackerZoneIndex = attackerZoneIndex,
                defenderZoneIndex = targetZoneIndex,
                attackingPlayer = playerIndex,
                defendingPlayer = defenderIndex
            }
            DuelEffects.RunTrigger(duel, 'on_destroyed_by_battle', defenderIndex, destroyedCard, {
                attackerUid = attackerCard.uid,
                destroyedUid = destroyedCard.uid,
                destroyedCard = destroyedCard,
                attackerZoneIndex = attackerZoneIndex,
                defenderZoneIndex = targetZoneIndex,
                attackingPlayer = playerIndex,
                defendingPlayer = defenderIndex
            }, effectApi)
            DuelEffects.RunFieldTrigger(duel, 'on_friendly_destroyed_by_battle', defenderIndex, destroyedEvent, effectApi)
        end
    end

    battleResult.attackerHpAfter = attackerCard.currentHp

    if DuelEffects and effectApi then
        DuelEffects.RunFieldTrigger(duel, 'on_battle_damage', playerIndex, battleResult, effectApi)
        DuelEffects.RunFieldTrigger(duel, 'on_battle_damage', defenderIndex, battleResult, effectApi)
    end

    checkWinCondition(duel)
    sendDuelStateToPlayers(duel)

    local sentToSource = {}
    for _, playerState in pairs(duel.players) do
        local targetSrc = playerState.source
        if not sentToSource[targetSrc] then
            TriggerClientEvent('bstar_cards:client:BattleEvent', targetSrc, battleResult)
            sentToSource[targetSrc] = true
        end
    end

    return true
end

function Duel.Create(srcA, srcB, deckA, deckB)
    local duelId = makeDuelId()

    local playerA, errA = createPlayerState(srcA, 1, deckA.id, deckA.name, deckA.deck_data)
    if not playerA then
        return nil, errA
    end

    local playerB, errB = createPlayerState(srcB, 2, deckB.id, deckB.name, deckB.deck_data)
    if not playerB then
        return nil, errB
    end

    local duel = {
        id = duelId,
        status = "setup",
        players = {
            [1] = playerA,
            [2] = playerB
        },
        turnPlayer = 1,
        firstTurnPlayer = 1,
        turnNumber = 1,
        phase = "draw",
        hasDrawnThisTurn = false,
        delayedTasks = {},
        pendingEffectQueue = {},
        log = {},
        soloMode = srcA == srcB
    }

    Duel.Active[duelId] = duel
    return duel
end

function Duel.Start(duelId, firstPlayer)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    if duel.started then
        return false, 'Duel already started'
    end

    firstPlayer = tonumber(firstPlayer) or 1
    if firstPlayer ~= 1 and firstPlayer ~= 2 then
        firstPlayer = 1
    end

    duel.status = "active"
    duel.started = true

    drawCards(duel, 1, 4)
    drawCards(duel, 2, 4)

    resetTurnFlags(duel.players[1])
    resetTurnFlags(duel.players[2])

    duel.phase = "draw"
    duel.turnPlayer = firstPlayer
    duel.firstTurnPlayer = firstPlayer
    duel.turnNumber = 1
    duel.hasDrawnThisTurn = false

    checkWinCondition(duel)

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.AdvancePhase(src, duelId)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if not playerIndex then
        return false, 'Player not in duel'
    end

    if duel.turnPlayer ~= playerIndex then
        return false, 'Not your turn'
    end

    if duel.phase == "draw" then
        if not duel.hasDrawnThisTurn then
            return false, 'Draw a card first'
        end
        duel.phase = "main"
        runPhaseStartEffects(duel, playerIndex, duel.phase)
    elseif duel.phase == "main" then
        duel.phase = "battle"
    elseif duel.phase == "battle" then
        duel.phase = "main2"
        resetBattleFlags(duel.players[playerIndex])
        runPhaseStartEffects(duel, playerIndex, duel.phase)
    elseif duel.phase == "main2" then
        duel.phase = "end"
        runEndPhaseEffects(duel, playerIndex)
    elseif duel.phase == "discard" then
        return false, 'Discard down to 9 cards before ending your turn'
    else
        return false, 'No further phase to advance'
    end

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.EndTurn(src, duelId)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if not playerIndex then
        return false, 'Player not in duel'
    end

    if duel.pendingEffect or duel.pendingSelection or duel.effectChain then
        return false, 'Resolve the pending effect first'
    end

    if duel.turnPlayer ~= playerIndex then
        return false, 'Not your turn'
    end

    local playerState = duel.players[playerIndex]
    if #playerState.hand > 9 then
        duel.phase = "discard"
        sendDuelStateToPlayers(duel)
        return true
    end

    runEndPhaseEffects(duel, playerIndex)
    processCardStatuses(duel, playerIndex, 'end_turn')
    processDelayedTasks(duel, playerIndex, 'end_turn')

    completeEndTurn(duel, playerIndex)

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.DiscardFromHand(src, duelId, handUid)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if not playerIndex then
        return false, 'Player not in duel'
    end

    if duel.pendingEffect or duel.pendingSelection or duel.effectChain then
        return false, 'Resolve the pending effect first'
    end

    if duel.turnPlayer ~= playerIndex then
        return false, 'Not your turn'
    end

    if duel.phase ~= "discard" then
        return false, 'You can only discard during discard cleanup'
    end

    local playerState = duel.players[playerIndex]
    if #playerState.hand <= 9 then
        return false, 'Your hand is already at 9 cards'
    end

    local _, handIndex = findCardInZoneByUid(playerState, "hand", handUid)
    if not handIndex then
        return false, 'Card not found in hand'
    end

    moveHandCardToGraveyard(playerState, handIndex, duel, { reason = 'discard_cleanup' })

    if #playerState.hand <= 9 then
        runEndPhaseEffects(duel, playerIndex)
        processCardStatuses(duel, playerIndex, 'end_turn')
        processDelayedTasks(duel, playerIndex, 'end_turn')
        completeEndTurn(duel, playerIndex)
    end

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.DrawForTurn(src, duelId)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if not playerIndex then
        return false, 'Player not in duel'
    end

    if duel.pendingEffect or duel.pendingSelection or duel.effectChain then
        return false, 'Resolve the pending effect first'
    end

    if duel.turnPlayer ~= playerIndex then
        return false, 'Not your turn'
    end

    if duel.phase ~= "draw" then
        return false, 'You can only draw in Draw Phase'
    end

    if duel.hasDrawnThisTurn then
        return false, 'You already drew this turn'
    end

    local playerState = duel.players[playerIndex]
    if not playerState then
        return false, 'Player state not found'
    end

    if (tonumber(playerState.skipDrawPhases) or 0) > 0 then
        playerState.skipDrawPhases = math.max(0, (tonumber(playerState.skipDrawPhases) or 0) - 1)
        duel.hasDrawnThisTurn = true
        duel.phase = "main"
        duel.log = duel.log or {}
        duel.log[#duel.log + 1] = {
            turn = duel.turnNumber,
            phase = 'draw',
            message = ('Player %s skipped their draw phase.'):format(playerIndex)
        }
        sendDuelStateToPlayers(duel)
        return true
    end

    if #playerState.deck == 0 then
        loseByDeckOut(duel, playerIndex)
        duel.hasDrawnThisTurn = true
        sendDuelStateToPlayers(duel)
        return true
    end

    drawCards(duel, playerIndex, 1)
    duel.hasDrawnThisTurn = true

    if not checkWinCondition(duel) then
        duel.phase = "main"
    end

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.SummonFighter(src, duelId, handUid, zoneIndex)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if not playerIndex then
        return false, 'Player not in duel'
    end

    if duel.pendingEffect or duel.pendingSelection or duel.effectChain then
        return false, 'Resolve the pending effect first'
    end

    if duel.turnPlayer ~= playerIndex then
        return false, 'Not your turn'
    end

    if not isMainPhase(duel.phase) then
        return false, 'You can only summon in a Main Phase'
    end

    local playerState = duel.players[playerIndex]

    if playerState.hasSummonedThisTurn then
        return false, 'You already summoned this turn'
    end

    zoneIndex = tonumber(zoneIndex)
    if not zoneIndex or zoneIndex < 1 or zoneIndex > 3 then
        return false, 'Invalid fighter zone'
    end

    if playerState.fighterZones[zoneIndex] ~= nil then
        return false, 'That zone is occupied'
    end

    local card, handIndex = findCardInZoneByUid(playerState, "hand", handUid)
    if not card then
        return false, 'Card not found in hand'
    end

    local def = getCardDefinition(card.cardId)
    if not def or string.upper(def.type or '') ~= 'FIGHTER' then
        return false, 'Only fighters can be summoned right now'
    end

    if playerHasCardTypeLock(playerState, 'FIGHTER') then
        return false, 'You cannot use Fighter cards right now'
    end

    if getCardLevelValue(def) ~= 1 then
        return false, 'Only stage 1 fighters can be normal summoned'
    end

    table.remove(playerState.hand, handIndex)
    card.zone = "fighterZone"
    resetFighterHp(card)
    playerState.fighterZones[zoneIndex] = card
    playerState.hasSummonedThisTurn = true
    playerState.summonsThisTurn = (tonumber(playerState.summonsThisTurn) or 0) + 1

    local event = {
        responseEvent = 'summon',
        trigger = 'summon',
        summonType = 'normal',
        summonedUid = card.uid,
        summonedCard = card,
        zoneIndex = zoneIndex,
        summoningPlayer = playerIndex
    }
    processSpecialSummonDrawWatchers(duel, event)
    startResponseWindowOrRunContinuation(duel, getOpponentIndex(playerIndex), {
        kind = 'trigger',
        playerIndex = playerIndex,
        sourceUid = card.uid,
        trigger = 'on_summon',
        event = event
    }, event, ('Your opponent summoned %s. Chain a response?'):format(def and def.name or card.cardId))

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.PromoteFighter(src, duelId, handUid, tributeZoneIndex)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if not playerIndex then
        return false, 'Player not in duel'
    end

    if duel.pendingEffect or duel.pendingSelection or duel.effectChain then
        return false, 'Resolve the pending effect first'
    end

    if duel.turnPlayer ~= playerIndex then
        return false, 'Not your turn'
    end

    if not isMainPhase(duel.phase) then
        return false, 'You can only promote in a Main Phase'
    end

    local playerState = duel.players[playerIndex]
    local usingSameTurnPromotionBypass = false

    if playerState.hasSummonedThisTurn then
        if playerHasStatus(playerState, 'allow_same_turn_promotion') then
            usingSameTurnPromotionBypass = true
        else
            return false, 'You already summoned this turn'
        end
    end

    local tributeZoneIndexes = normalizeTributeZoneIndexes(tributeZoneIndex)
    if #tributeZoneIndexes == 0 then
        return false, 'Invalid tribute zone'
    end

    local primaryTributeZoneIndex = tributeZoneIndexes[1]
    local tributeCard = playerState.fighterZones[primaryTributeZoneIndex]
    if not tributeCard then
        return false, 'No fighter to promote from in that zone'
    end

    if cardHasStatus(tributeCard, 'cannot_promote') then
        return false, 'That fighter cannot be promoted'
    end

    local promotionCard, handIndex = findCardInZoneByUid(playerState, "hand", handUid)
    if not promotionCard then
        return false, 'Promotion card not found in hand'
    end

    local tributeDef = getCardDefinition(tributeCard.cardId)
    local promotionDef = getCardDefinition(promotionCard.cardId)
    if playerHasCardTypeLock(playerState, 'FIGHTER') then
        return false, 'You cannot use Fighter cards right now'
    end
    local promotionType = nil
    local extraTributeZoneIndex = nil

    if #tributeZoneIndexes == 1 and canPromoteFromTo(tributeDef, promotionDef) then
        promotionType = 'named'
    elseif #tributeZoneIndexes >= 2 then
        extraTributeZoneIndex = tributeZoneIndexes[2]
        local extraTributeCard = playerState.fighterZones[extraTributeZoneIndex]
        local extraTributeDef = extraTributeCard and getCardDefinition(extraTributeCard.cardId) or nil

        if extraTributeCard and canGenericPromoteFromPair(tributeDef, extraTributeDef, promotionDef) then
            promotionType = 'generic'
        end
    end

    if not promotionType then
        return false, 'That card cannot promote this fighter'
    end

    table.remove(playerState.hand, handIndex)

    if promotionType == 'generic' and extraTributeZoneIndex then
        moveFieldCardToGraveyard(playerState, extraTributeZoneIndex, duel, {
            reason = 'tribute',
            skipReplacement = true
        })
        moveEquipmentAtToGraveyard(playerState, primaryTributeZoneIndex)
    end

    playerState.fighterZones[primaryTributeZoneIndex] = nil
    tributeCard.zone = "graveyard"
    tributeCard.equipmentStatModifiers = nil
    tributeCard.continuousStatModifiers = nil
    playerState.graveyard[#playerState.graveyard + 1] = tributeCard

    promotionCard.zone = "fighterZone"
    promotionCard.hasAttacked = false
    resetFighterHp(promotionCard)
    playerState.fighterZones[primaryTributeZoneIndex] = promotionCard
    rebuildEquipmentModifiers(playerState, primaryTributeZoneIndex)
    if usingSameTurnPromotionBypass then
        consumePlayerStatus(playerState, 'allow_same_turn_promotion')
    end
    playerState.hasSummonedThisTurn = true
    playerState.summonsThisTurn = (tonumber(playerState.summonsThisTurn) or 0) + 1

    local event = {
        responseEvent = 'summon',
        trigger = 'summon',
        summonType = promotionType == 'generic' and 'generic_promotion' or 'promotion',
        summonedUid = promotionCard.uid,
        summonedCard = promotionCard,
        zoneIndex = primaryTributeZoneIndex,
        summoningPlayer = playerIndex
    }
    processSpecialSummonDrawWatchers(duel, event)
    startResponseWindowOrRunContinuation(duel, getOpponentIndex(playerIndex), {
        kind = 'trigger',
        playerIndex = playerIndex,
        sourceUid = promotionCard.uid,
        trigger = 'on_summon',
        event = event
    }, event, ('Your opponent summoned %s. Chain a response?'):format(promotionDef and promotionDef.name or promotionCard.cardId))

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.PlayNonFighter(src, duelId, handUid, targetKind, zoneIndex)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if not playerIndex then
        return false, 'Player not in duel'
    end

    if duel.pendingEffect or duel.pendingSelection or duel.effectChain then
        return false, 'Resolve the pending effect first'
    end

    if duel.turnPlayer ~= playerIndex then
        return false, 'Not your turn'
    end

    if not isMainPhase(duel.phase) then
        return false, 'You can only play non-fighter cards in a Main Phase'
    end

    local playerState = duel.players[playerIndex]
    local card, handIndex = findCardInZoneByUid(playerState, "hand", handUid)
    if not card then
        return false, 'Card not found in hand'
    end

    local cardType = getCardTypeValue(card)
    if playerHasCardTypeLock(playerState, cardType) then
        return false, ('You cannot use %s cards right now'):format(cardType:lower())
    end
    if cardType == 'FIGHTER' then
        return false, 'Use the fighter summon action for fighter cards'
    end

    targetKind = tostring(targetKind or ''):lower()

    if cardType == 'LOCATION' then
        local replacedLocation = playerState.locationZone

        table.remove(playerState.hand, handIndex)

        if replacedLocation then
            replacedLocation.zone = "graveyard"
            playerState.graveyard[#playerState.graveyard + 1] = replacedLocation
        end

        card.zone = "locationZone"
        playerState.locationZone = card

        local event = {
            responseEvent = 'card_played',
            trigger = 'card_played',
            playedUid = card.uid,
            playedCard = card,
            playedCardType = cardType,
            playingPlayer = playerIndex,
            zone = 'locationZone',
            replacedCard = replacedLocation
        }
        fireOnPlayFieldTriggers(duel, playerIndex, card, event)
        startResponseWindowOrRunContinuation(duel, getOpponentIndex(playerIndex), {
            kind = 'trigger',
            playerIndex = playerIndex,
            sourceUid = card.uid,
            trigger = 'on_play',
            event = event
        }, event, ('Your opponent played %s. Chain a response?'):format((getCardDefinition(card.cardId) or {}).name or card.cardId))

        sendDuelStateToPlayers(duel)
        return true
    end

    if cardType == 'EVENT' then
        local def = getCardDefinition(card.cardId)
        if def and def.requiresEffectPlay == true then
            return false, ('%s can only be played by a card effect'):format(def.name or card.cardId)
        end

        moveHandCardToGraveyard(playerState, handIndex)

        local event = {
            responseEvent = 'card_played',
            trigger = 'card_played',
            playedUid = card.uid,
            playedCard = card,
            playedCardType = cardType,
            playingPlayer = playerIndex,
            zone = 'graveyard'
        }
        fireOnPlayFieldTriggers(duel, playerIndex, card, event)
        startResponseWindowOrRunContinuation(duel, getOpponentIndex(playerIndex), {
            kind = 'trigger',
            playerIndex = playerIndex,
            sourceUid = card.uid,
            trigger = 'on_play',
            event = event
        }, event, ('Your opponent played %s. Chain a response?'):format((getCardDefinition(card.cardId) or {}).name or card.cardId))

        sendDuelStateToPlayers(duel)
        return true
    end

    if isItemZoneCardType(cardType) then
        local isContinuous = isContinuousItemCard(card)

        zoneIndex = tonumber(zoneIndex)
        if not zoneIndex or zoneIndex < 1 or zoneIndex > 4 then
            return false, 'Invalid item zone'
        end

        if playerState.itemZones[zoneIndex] ~= nil then
            return false, 'That item zone is occupied'
        end

        table.remove(playerState.hand, handIndex)
        card.zone = "itemZone"
        card.temporaryItemZoneIndex = isContinuous and nil or zoneIndex
        playerState.itemZones[zoneIndex] = card

        if not isContinuous then
            sendDuelStateToPlayers(duel)
        end

        local event = {
            responseEvent = 'card_played',
            trigger = 'card_played',
            playedUid = card.uid,
            playedCard = card,
            playedCardType = cardType,
            playingPlayer = playerIndex,
            zone = 'itemZone',
            zoneIndex = zoneIndex,
            continuous = isContinuous
        }
        fireOnPlayFieldTriggers(duel, playerIndex, card, event)
        startResponseWindowOrRunContinuation(duel, getOpponentIndex(playerIndex), {
            kind = 'trigger',
            playerIndex = playerIndex,
            sourceUid = card.uid,
            trigger = 'on_play',
            event = event,
            cleanupTemporaryItemsFor = isContinuous and nil or playerIndex
        }, event, ('Your opponent played %s. Chain a response?'):format((getCardDefinition(card.cardId) or {}).name or card.cardId))

        sendDuelStateToPlayers(duel)
        return true
    end

    if isEquipmentZoneCardType(cardType) then
        zoneIndex = tonumber(zoneIndex)
        if not zoneIndex or zoneIndex < 1 or zoneIndex > 3 then
            return false, 'Invalid equipment zone'
        end
        local slotKey = getEquipmentSlotKey(cardType)
        if not slotKey then
            return false, 'Invalid equipment card'
        end
        local def = getCardDefinition(card.cardId)

        if playerState.fighterZones[zoneIndex] == nil then
            return false, 'Choose a fighter to equip this card to'
        end

        if def and tonumber(def.maxCopiesPerFighter) and tonumber(def.maxCopiesPerFighter) > 1 then
            local existingSlot = playerState.equipmentZones and playerState.equipmentZones[zoneIndex] or nil
            local existingSame = existingSlot and existingSlot.weapon and tostring(existingSlot.weapon.cardId or '') == tostring(card.cardId or '')
            if existingSame and getEquipmentCardAt(playerState, zoneIndex, 'equipment') == nil then
                slotKey = 'equipment'
                card.forcedEquipmentSlot = 'equipment'
            end
        end

        if getEquipmentCardAt(playerState, zoneIndex, slotKey) ~= nil then
            return false, ('That fighter already has a %s card'):format(cardType:lower())
        end

        table.remove(playerState.hand, handIndex)
        card.zone = "equipmentZone"
        setEquipmentCardAt(playerState, zoneIndex, slotKey, card)
        rebuildEquipmentModifiers(playerState, zoneIndex)

        local event = {
            responseEvent = 'card_played',
            trigger = 'card_played',
            playedUid = card.uid,
            playedCard = card,
            playedCardType = cardType,
            playingPlayer = playerIndex,
            zone = 'equipmentZone',
            zoneIndex = zoneIndex
        }
        fireOnPlayFieldTriggers(duel, playerIndex, card, event)
        startResponseWindowOrRunContinuation(duel, getOpponentIndex(playerIndex), {
            kind = 'trigger',
            playerIndex = playerIndex,
            sourceUid = card.uid,
            trigger = 'on_play',
            event = event
        }, event, ('Your opponent played %s. Chain a response?'):format((getCardDefinition(card.cardId) or {}).name or card.cardId))

        sendDuelStateToPlayers(duel)
        return true
    end

    return false, 'This card type is not playable yet'
end

function Duel.ResolvePendingEffect(src, duelId, promptId, accepted, response)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    local pending = duel.pendingEffect
    if not pending or tostring(pending.id) ~= tostring(promptId) then
        return false, 'Effect prompt not found'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if playerIndex ~= pending.playerIndex then
        return false, 'That effect prompt is not yours'
    end

    duel.pendingEffect = nil

    if pending.responseWindow == true then
        local chain = duel.effectChain
        if not chain or tostring(chain.id) ~= tostring(pending.chainId) then
            sendDuelStateToPlayers(duel)
            return true
        end

        response = type(response) == 'table' and response or {}

        if accepted == true and response.option then
            local selectedOption = tostring(response.option)
            local choices = getResponseChoicesForPlayer(duel, playerIndex, chain)
            local selectedChoice = nil
            for _, choice in ipairs(choices) do
                if tostring(choice.id) == selectedOption then
                    selectedChoice = choice
                    break
                end
            end

            if not selectedChoice then
                return false, 'That response is no longer available'
            end

            chain.stack[#chain.stack + 1] = {
                playerIndex = playerIndex,
                sourceUid = selectedChoice.sourceUid,
                effectIndex = selectedChoice.effectIndex,
                event = shallowCopy(chain.event)
            }
            chain.passed = {}
            chain.lastResponder = playerIndex

            duel.log = duel.log or {}
            duel.log[#duel.log + 1] = {
                turn = duel.turnNumber,
                phase = duel.phase,
                message = ('Player %s chained %s.'):format(playerIndex, selectedChoice.cardName or 'a response')
            }

            local nextPlayerIndex = getOpponentIndex(playerIndex)
            if not openResponsePromptForPlayer(duel, nextPlayerIndex, chain) then
                chain.passed[nextPlayerIndex] = true
                advanceEffectChain(duel, nextPlayerIndex)
            end
        else
            advanceEffectChain(duel, playerIndex)
        end

        checkWinCondition(duel)
        sendDuelStateToPlayers(duel)
        return true
    end

    if accepted == true or pending.runCancelActions == true then
        response = type(response) == 'table' and response or {}

        if accepted == true and pending.form and pending.form.number then
            local numberForm = pending.form.number
            local key = tostring(numberForm.key or 'amount')
            local value = tonumber(response[key]) or tonumber(numberForm.default) or 0
            if numberForm.min ~= nil then value = math.max(tonumber(numberForm.min) or value, value) end
            if numberForm.max ~= nil then value = math.min(tonumber(numberForm.max) or value, value) end
            if numberForm.maxLifePoints == true then
                local player = duel.players[playerIndex]
                value = math.min(tonumber(player and player.lifePoints) or value, value)
            end
            response[key] = value
        end

        local sourcePlayerIndex = tonumber(pending.sourcePlayerIndex) or playerIndex
        local playerState = duel.players[sourcePlayerIndex]
        local card = findPlayerCardByUid(playerState, pending.sourceUid)
        if card then
            local ok, err = DuelEffects.RunEffectByIndex(duel, sourcePlayerIndex, card, pending.effectIndex, {
                trigger = pending.trigger,
                prompted = true,
                cancelled = accepted ~= true,
                response = response
            }, getEffectApi())

            if not ok then
                return false, err
            end

            checkWinCondition(duel)
        end
    end

    if not duel.pendingActionQueue and not duel.pendingSelection then
        activateNextQueuedEffectPrompt(duel)
    end

    local cleanupPlayerIndex = tonumber(pending.sourcePlayerIndex) or playerIndex
    local playerState = duel.players[cleanupPlayerIndex]
    if playerState and not duel.pendingActionQueue and not duel.pendingEffect and not duel.pendingSelection then
        for zoneIndex, card in pairs(playerState.itemZones or {}) do
            if card and card.temporaryItemZoneIndex then
                moveItemZoneCardToGraveyard(playerState, zoneIndex)
            end
        end
    end

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.ResolvePendingSelection(src, duelId, selectionId, selectedUid, selectedUids)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    local pending = duel.pendingSelection
    if not pending or tostring(pending.id) ~= tostring(selectionId) then
        return false, 'Selection prompt not found'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if playerIndex ~= pending.playerIndex then
        return false, 'That selection prompt is not yours'
    end

    local chosenUids = {}
    local seenChosenUids = {}

    local function addChosenUid(uid)
        uid = tostring(uid or '')
        if uid ~= '' and not seenChosenUids[uid] then
            chosenUids[#chosenUids + 1] = uid
            seenChosenUids[uid] = true
        end
    end

    if type(selectedUids) == 'table' then
        for _, uid in ipairs(selectedUids) do
            addChosenUid(uid)
        end
    else
        addChosenUid(selectedUid)
    end

    local minChoices = math.max(0, tonumber(pending.minChoices) or 1)
    local maxChoices = math.max(1, tonumber(pending.maxChoices) or 1)
    if #chosenUids < minChoices or #chosenUids > maxChoices then
        return false, ('Choose between %s and %s card(s)'):format(minChoices, maxChoices)
    end

    selectedUid = chosenUids[1]
    duel.pendingSelection = nil

    local playerState = duel.players[playerIndex]

    if pending.mode == 'move_selected_graveyard_to_deck' then
        for _, uid in ipairs(chosenUids) do
            local card = findCardInZoneByUid(playerState, 'graveyard', uid)
            if not card then
                return false, 'Selected card is no longer in your cemetery'
            end

            if not cardMatchesSearchFilter(card, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end
        end

        for _, uid in ipairs(chosenUids) do
            local card, graveIndex = findCardInZoneByUid(playerState, 'graveyard', uid)
            if card and graveIndex then
                table.remove(playerState.graveyard, graveIndex)
                card.zone = 'deck'
                playerState.deck[#playerState.deck + 1] = card
            end
        end

        if pending.payload and pending.payload.shuffle ~= false then
            shuffleList(playerState.deck)
        end

        local thenDraw = tonumber(pending.payload and pending.payload.thenDraw) or 0
        if thenDraw > 0 then
            drawCards(duel, playerIndex, thenDraw)
        end

        for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
            if itemCard and itemCard.temporaryItemZoneIndex then
                moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
            end
        end
        sendDuelStateToPlayers(duel)
        return true
    end

    if pending.mode == 'move_selected_graveyard_to_hand' then
        local targetPlayerState = duel.players[pending.targetPlayerIndex] or playerState
        for _, uid in ipairs(chosenUids) do
            local card = findCardInZoneByUid(targetPlayerState, 'graveyard', uid)
            if not card then
                return false, 'Selected card is no longer in the cemetery'
            end

            if not cardMatchesSearchFilter(card, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end
        end

        for _, uid in ipairs(chosenUids) do
            local card, graveIndex = findCardInZoneByUid(targetPlayerState, 'graveyard', uid)
            if card and graveIndex then
                table.remove(targetPlayerState.graveyard, graveIndex)
                card.zone = 'hand'
                card.controller = pending.targetPlayerIndex or playerIndex
                targetPlayerState.hand = targetPlayerState.hand or {}
                targetPlayerState.hand[#targetPlayerState.hand + 1] = card
            end
        end

        for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
            if itemCard and itemCard.temporaryItemZoneIndex then
                moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
            end
        end
        sendDuelStateToPlayers(duel)
        return true
    end

    if pending.mode == 'move_selected_hand_to_deck' then
        for _, uid in ipairs(chosenUids) do
            local card = findCardInZoneByUid(playerState, 'hand', uid)
            if not card then
                return false, 'Selected card is no longer in your hand'
            end

            if not cardMatchesSearchFilter(card, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end
        end

        local movedCount = 0
        for _, uid in ipairs(chosenUids) do
            local card, handIndex = findCardInZoneByUid(playerState, 'hand', uid)
            if card and handIndex then
                table.remove(playerState.hand, handIndex)
                card.zone = 'deck'
                card.controller = playerIndex
                playerState.deck[#playerState.deck + 1] = card
                movedCount = movedCount + 1
            end
        end

        if pending.payload and pending.payload.shuffle ~= false then
            shuffleList(playerState.deck)
        end

        local drawAmount = pending.payload and pending.payload.thenDrawPerCard and movedCount * (tonumber(pending.payload.thenDrawPerCard) or 1) or 0
        if drawAmount > 0 then
            drawCards(duel, playerIndex, drawAmount)
        end

        for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
            if itemCard and itemCard.temporaryItemZoneIndex then
                moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
            end
        end
        sendDuelStateToPlayers(duel)
        return true
    end

    if pending.mode == 'take_control_selected_cards' then
        local targetPlayerState = duel.players[pending.targetPlayerIndex]
        if not targetPlayerState then return false, 'Target player not found' end

        for _, uid in ipairs(chosenUids) do
            local card = findCardByUid(duel, uid)
            if not card then
                return false, 'Selected card is no longer available'
            end
            if not cardMatchesSearchFilter(card, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end
        end

        for _, uid in ipairs(chosenUids) do
            local card, oldState, oldPlayerIndex, oldZoneName = findCardByUid(duel, uid)
            if card then
                local removedCard = removeCardByUid(duel, uid, { suppressSentTrigger = true })
                if removedCard then
                    local def = getCardDefinition(removedCard.cardId)
                    local typeText = string.upper(tostring(def and def.type or ''))
                    local placed = false
                    removedCard.controller = playerIndex
                    if typeText == 'ITEM' or typeText == 'CONTINUOUS EVENT' then
                        for zoneIndex = 1, 4 do
                            if not playerState.itemZones[zoneIndex] then
                                removedCard.zone = 'itemZone'
                                removedCard.temporaryItemZoneIndex = nil
                                playerState.itemZones[zoneIndex] = removedCard
                                placed = true
                                break
                            end
                        end
                    elseif typeText == 'WEAPON' or typeText == 'VEHICLE' or typeText == 'EQUIPMENT' then
                        for zoneIndex = 1, 3 do
                            if playerState.fighterZones[zoneIndex] and canEquipCardToFighter(playerState, removedCard, zoneIndex) then
                                local slotKey = getEquipmentSlotKey(removedCard)
                                setEquipmentCardAt(playerState, zoneIndex, slotKey, removedCard)
                                removedCard.zone = 'equipmentZone'
                                removedCard.equippedToZoneIndex = zoneIndex
                                rebuildEquipmentModifiers(playerState, zoneIndex)
                                placed = true
                                break
                            end
                        end
                    end

                    if not placed and oldState then
                        removedCard.controller = oldPlayerIndex
                        removedCard.zone = 'graveyard'
                        oldState.graveyard = oldState.graveyard or {}
                        oldState.graveyard[#oldState.graveyard + 1] = removedCard
                    end
                end
            end
        end

        for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
            if itemCard and itemCard.temporaryItemZoneIndex then
                moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
            end
        end
        sendDuelStateToPlayers(duel)
        return true
    end

    if pending.mode == 'reorder_top_deck_then_draw' then
        local count = math.min(tonumber(pending.payload and pending.payload.count) or 3, #(playerState.deck or {}))
        if #chosenUids ~= count then
            return false, ('Choose exactly %s cards'):format(count)
        end

        local topCardsByUid = {}
        for index = 1, count do
            local card = playerState.deck[index]
            if card then topCardsByUid[tostring(card.uid)] = card end
        end

        local reordered = {}
        for _, uid in ipairs(chosenUids) do
            local card = topCardsByUid[tostring(uid)]
            if not card then return false, 'Selected card is no longer in the inspected cards' end
            reordered[#reordered + 1] = card
        end

        for index = 1, count do
            playerState.deck[index] = reordered[index]
        end

        local thenDraw = tonumber(pending.payload and pending.payload.thenDraw) or 1
        if thenDraw > 0 then
            drawCards(duel, playerIndex, thenDraw)
        end

        for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
            if itemCard and itemCard.temporaryItemZoneIndex then
                moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
            end
        end
        sendDuelStateToPlayers(duel)
        return true
    end

    if pending.mode == 'split_selected_graveyard_to_deck_and_hand' then
        if #chosenUids ~= 2 then
            return false, 'Choose exactly 2 cards'
        end

        for _, uid in ipairs(chosenUids) do
            local card = findCardInZoneByUid(playerState, 'graveyard', uid)
            if not card then
                return false, 'Selected card is no longer in your cemetery'
            end

            if not cardMatchesSearchFilter(card, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end
        end

        local deckCard, deckGraveIndex = findCardInZoneByUid(playerState, 'graveyard', chosenUids[1])
        if deckCard and deckGraveIndex then
            table.remove(playerState.graveyard, deckGraveIndex)
            deckCard.zone = 'deck'
            playerState.deck[#playerState.deck + 1] = deckCard
        end

        local handCard, handGraveIndex = findCardInZoneByUid(playerState, 'graveyard', chosenUids[2])
        if handCard and handGraveIndex then
            table.remove(playerState.graveyard, handGraveIndex)
            handCard.zone = 'hand'
            playerState.hand[#playerState.hand + 1] = handCard
        end

        if pending.payload and pending.payload.shuffle ~= false then
            shuffleList(playerState.deck)
        end

        for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
            if itemCard and itemCard.temporaryItemZoneIndex then
                moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
            end
        end
        sendDuelStateToPlayers(duel)
        return true
    end

    if pending.mode == 'hayes_reclaim_vehicle' and (not selectedUid or selectedUid == '') then
        sendDuelStateToPlayers(duel)
        return true
    end

    if pending.mode == 'copy_selected_graveyard_effects' then
        if not selectedUid or selectedUid == '' then
            return false, 'Choose a fighter to copy'
        end

        local targetPlayerState = duel.players[pending.targetPlayerIndex] or playerState
        local selectedCard = findCardInZoneByUid(targetPlayerState, 'graveyard', selectedUid)
        if not selectedCard then
            return false, 'Selected card is no longer in the cemetery'
        end

        if not cardMatchesSearchFilter(selectedCard, pending.filter) then
            return false, 'Selected card is not valid for this effect'
        end

        local sourceCard = pending.sourceUid and findCardByUid(duel, pending.sourceUid) or nil
        local selectedDef = getCardDefinition(selectedCard.cardId)
        if sourceCard and selectedDef and type(selectedDef.effects) == 'table' then
            sourceCard.copiedEffects = {}
            for index, effect in ipairs(selectedDef.effects) do
                sourceCard.copiedEffects[index] = shallowCopy(effect)
            end
            sourceCard.copiedEffectSourceCardId = selectedCard.cardId
        end

        for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
            if itemCard and itemCard.temporaryItemZoneIndex then
                moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
            end
        end
        sendDuelStateToPlayers(duel)
        return true
    end

    if selectedUid and selectedUid ~= '' then
        if pending.mode == 'discard_hand_branch' then
            local card, handIndex = findCardInZoneByUid(playerState, 'hand', selectedUid)
            if not card or not handIndex then
                return false, 'Selected card is no longer in your hand'
            end

            if not cardMatchesSearchFilter(card, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            local discardedDef = getCardDefinition(card.cardId)
            local discardedType = string.upper(tostring(discardedDef and discardedDef.type or ''))
            moveHandCardToGraveyard(playerState, handIndex, duel, {
                reason = 'discard',
                sourceUid = pending.sourceUid,
                sourceCardId = pending.sourceCardId
            })

            local payload = pending.payload or {}
            local branches = payload.branches or {}
            local actions = branches[discardedType] or branches[string.lower(discardedType)] or payload.defaultActions or {}
            if DuelEffects and DuelEffects.RunActions and getEffectApi and #actions > 0 then
                local sourceCard = pending.sourceUid and findCardByUid(duel, pending.sourceUid) or nil
                if sourceCard then
                    DuelEffects.RunActions(duel, playerIndex, sourceCard, actions, {
                        discardedUid = selectedUid,
                        discardedCardId = card.cardId,
                        discardedType = discardedType
                    }, getEffectApi())
                end
            end

            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end

            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'send_selected_to_graveyard' then
            for _, uid in ipairs(chosenUids) do
                local targetCard, _, targetPlayerIndex = findCardByUid(duel, uid)
                if not targetCard or targetPlayerIndex ~= playerIndex then
                    return false, 'Selected card is no longer under your control'
                end

                if not cardMatchesSearchFilter(targetCard, pending.filter) then
                    return false, 'Selected card is not valid for this effect'
                end
            end

            local sentCount = 0
            for _, uid in ipairs(chosenUids) do
                local targetCard, _, _, targetZoneName, targetZoneIndex = findCardByUid(duel, uid)
                if targetCard then
                    if targetZoneName == 'hand' then
                        local _, handIndex = findCardInZoneByUid(playerState, 'hand', uid)
                        if handIndex then
                            moveHandCardToGraveyard(playerState, handIndex, duel, {
                                reason = pending.payload and pending.payload.reason or 'card_effect',
                                sourceUid = pending.sourceUid,
                                sourceCardId = pending.sourceCardId
                            })
                            sentCount = sentCount + 1
                        end
                    elseif targetZoneName == 'fighterZones' then
                        if moveFieldCardToGraveyard(playerState, targetZoneIndex, duel, {
                            reason = 'card_effect',
                            sourceUid = pending.sourceUid,
                            sourceCardId = pending.sourceCardId
                        }) then
                            sentCount = sentCount + 1
                        end
                    elseif targetZoneName == 'itemZones' then
                        moveItemZoneCardToGraveyard(playerState, targetZoneIndex, duel, {
                            reason = 'card_effect',
                            sourceUid = pending.sourceUid,
                            sourceCardId = pending.sourceCardId
                        })
                        sentCount = sentCount + 1
                    elseif targetZoneName == 'equipmentZones' or targetZoneName == 'locationZone' then
                        if moveCardByUidToGraveyard(duel, uid, {
                            reason = 'card_effect',
                            sourceUid = pending.sourceUid,
                            sourceCardId = pending.sourceCardId
                        }) then
                            sentCount = sentCount + 1
                        end
                    else
                        return false, 'Selected card cannot be sent from that zone'
                    end
                end
            end

            local payload = pending.payload or {}
            local drawAmount = tonumber(payload.thenDraw) or 0
            if payload.thenDrawPerCard then
                drawAmount = drawAmount + sentCount * (tonumber(payload.thenDrawPerCard) or 1)
            end
            if drawAmount > 0 then
                drawCards(duel, playerIndex, drawAmount)
            end

            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'return_selected_field_to_hand' then
            for _, uid in ipairs(chosenUids) do
                local targetCard, _, targetPlayerIndex, targetZoneName = findCardByUid(duel, uid)
                if not targetCard or targetPlayerIndex ~= pending.targetPlayerIndex or targetZoneName == 'hand' or targetZoneName == 'graveyard' then
                    return false, 'Selected card is no longer on the field'
                end

                if not cardMatchesSearchFilter(targetCard, pending.filter) then
                    return false, 'Selected card is not valid for this effect'
                end
            end

            for _, uid in ipairs(chosenUids) do
                local targetCard, targetPlayerState, targetPlayerIndex = findCardByUid(duel, uid)
                local removedCard = targetCard and removeCardByUid(duel, uid, { suppressSentTrigger = true }) or nil
                if removedCard and targetPlayerState then
                    removedCard.zone = 'hand'
                    removedCard.controller = targetPlayerIndex
                    removedCard.equippedToZoneIndex = nil
                    removedCard.hasAttacked = false
                    targetPlayerState.hand = targetPlayerState.hand or {}
                    targetPlayerState.hand[#targetPlayerState.hand + 1] = removedCard
                end
            end

            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end

            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'swap_selected_fighter_same_name_from_deck' then
            local selectedFighter, _, targetPlayerIndex, targetZoneName, targetZoneIndex = findCardByUid(duel, selectedUid)
            if not selectedFighter or targetPlayerIndex ~= playerIndex or targetZoneName ~= 'fighterZones' then
                return false, 'Selected fighter is no longer on your field'
            end

            if not cardMatchesSearchFilter(selectedFighter, pending.filter) then
                return false, 'Selected fighter is not valid for this effect'
            end

            local selectedDef = getCardDefinition(selectedFighter.cardId)
            local selectedName = string.lower(tostring(selectedDef and selectedDef.name or ''))
            local deckIndex = nil
            local deckCard = nil
            for index, candidate in ipairs(playerState.deck or {}) do
                local candidateDef = getCardDefinition(candidate.cardId)
                if string.lower(tostring(candidateDef and candidateDef.name or '')) == selectedName
                    and cardMatchesSearchFilter(candidate, { type = 'Fighter' }) then
                    deckIndex = index
                    deckCard = candidate
                    break
                end
            end

            if not deckIndex or not deckCard then
                return false, 'No same-name fighter found in your deck'
            end

            moveEquipmentAtToGraveyard(playerState, targetZoneIndex, duel, {
                reason = 'returned_to_hand',
                sourceUid = pending.sourceUid,
                sourceCardId = pending.sourceCardId
            })

            playerState.fighterZones[targetZoneIndex] = nil
            selectedFighter.zone = 'hand'
            selectedFighter.controller = playerIndex
            selectedFighter.hasAttacked = false
            selectedFighter.equipmentStatModifiers = nil
            selectedFighter.continuousStatModifiers = nil
            playerState.hand[#playerState.hand + 1] = selectedFighter

            table.remove(playerState.deck, deckIndex)
            deckCard.zone = 'fighterZone'
            deckCard.controller = playerIndex
            deckCard.hasAttacked = false
            resetFighterHp(deckCard)
            playerState.fighterZones[targetZoneIndex] = deckCard

            triggerSummonResponseWindow(duel, playerIndex, deckCard, {
                zoneIndex = targetZoneIndex,
                summonType = 'special',
                summoningPlayer = playerIndex
            })

            checkWinCondition(duel)
            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end
            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'special_summon_same_name_from_deck' then
            local selectedFighter, _, targetPlayerIndex, targetZoneName = findCardByUid(duel, selectedUid)
            if not selectedFighter or targetPlayerIndex ~= playerIndex or targetZoneName ~= 'fighterZones' then
                return false, 'Selected fighter is no longer on your field'
            end

            if not cardMatchesSearchFilter(selectedFighter, pending.filter) then
                return false, 'Selected fighter is not valid for this effect'
            end

            local zoneIndex = nil
            for i = 1, 3 do
                if not playerState.fighterZones[i] then
                    zoneIndex = i
                    break
                end
            end
            if not zoneIndex then
                return false, 'No open fighter zone'
            end

            local selectedDef = getCardDefinition(selectedFighter.cardId)
            local selectedName = string.lower(tostring(selectedDef and selectedDef.name or ''))
            local deckIndex = nil
            local deckCard = nil
            for index, candidate in ipairs(playerState.deck or {}) do
                local candidateDef = getCardDefinition(candidate.cardId)
                if string.lower(tostring(candidateDef and candidateDef.name or '')) == selectedName
                    and cardMatchesSearchFilter(candidate, { type = 'Fighter' }) then
                    deckIndex = index
                    deckCard = candidate
                    break
                end
            end

            if not deckIndex or not deckCard then
                return false, 'No same-name fighter found in your deck'
            end

            table.remove(playerState.deck, deckIndex)
            deckCard.zone = 'fighterZone'
            deckCard.controller = playerIndex
            deckCard.hasAttacked = false
            resetFighterHp(deckCard)
            playerState.fighterZones[zoneIndex] = deckCard

            triggerSummonResponseWindow(duel, playerIndex, deckCard, {
                zoneIndex = zoneIndex,
                summonType = 'special',
                summoningPlayer = playerIndex
            })

            checkWinCondition(duel)
            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end
            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'modify_selected_equipment_bonus' then
            local equipmentCard, targetPlayerState, _, targetZoneName = findCardByUid(duel, selectedUid)
            if not equipmentCard or targetZoneName ~= 'equipmentZones' then
                return false, 'Selected card is no longer equipped'
            end

            if not cardMatchesSearchFilter(equipmentCard, pending.filter) then
                return false, 'Selected equipment is not valid for this effect'
            end

            if isTargetProtectedFromPlayer(duel, playerIndex, pending.targetPlayerIndex, equipmentCard, pending.reason or 'card_effect') then
                return false, 'That card cannot be targeted by this effect'
            end

            local payload = pending.payload or {}
            modifyEquipmentBonus(duel, equipmentCard, payload.stat or 'speed', {
                amount = payload.amount,
                multiplier = payload.multiplier,
                setTo = payload.setTo,
                minValue = payload.minValue,
                duration = payload.duration
            })

            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end
            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'equip_target' then
            local equipmentCard, deckIndex = findCardInZoneByUid(playerState, 'deck', pending.equipmentUid)
            if not equipmentCard or not deckIndex then
                return false, 'Selected equipment card is no longer in your deck'
            end

            local targetCard, zoneName, zoneIndex = findFieldCardByUid(playerState, selectedUid)
            if not targetCard or zoneName ~= 'fighterZones' then
                return false, 'Selected fighter is no longer on your field'
            end

            if not canEquipCardToFighter(playerState, equipmentCard, zoneIndex) then
                return false, 'That fighter cannot equip this card'
            end

            local slotKey = getEquipmentSlotKey(equipmentCard)
            table.remove(playerState.deck, deckIndex)
            equipmentCard.zone = 'equipmentZone'
            setEquipmentCardAt(playerState, zoneIndex, slotKey, equipmentCard)
            rebuildEquipmentModifiers(playerState, zoneIndex)

            if DuelEffects and getEffectApi then
                DuelEffects.RunTrigger(duel, 'on_play', playerIndex, equipmentCard, {
                    zone = 'equipmentZone',
                    zoneIndex = zoneIndex,
                    equippedByEffect = true
                }, getEffectApi())
                checkWinCondition(duel)
            end

            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end

            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'attach_source_to_selected_fighter' then
            local payload = pending.payload or {}
            local sourceUid = payload.sourceUid or pending.sourceUid
            local equipmentCard, equipmentPlayerState, equipmentPlayerIndex, equipmentZoneName, equipmentZoneIndex = findCardByUid(duel, sourceUid)
            if not equipmentCard then
                return false, 'Equipment card is no longer available'
            end
            if payload.forcedEquipmentSlot then
                equipmentCard.forcedEquipmentSlot = payload.forcedEquipmentSlot
            end

            local targetCard, targetPlayerState, targetPlayerIndex, targetZoneName, targetZoneIndex = findCardByUid(duel, selectedUid)
            if not targetCard or targetZoneName ~= 'fighterZones' then
                return false, 'Selected fighter is no longer on the field'
            end

            if not cardMatchesSearchFilter(targetCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            if isTargetProtectedFromPlayer(duel, playerIndex, targetPlayerIndex, targetCard, pending.reason or 'card_effect') then
                return false, 'That card cannot be targeted by this effect'
            end

            if not canEquipCardToFighter(targetPlayerState, equipmentCard, targetZoneIndex) then
                return false, 'That fighter cannot equip this card'
            end

            local oldPlayerState = equipmentPlayerState
            local oldZoneIndex = equipmentZoneName == 'equipmentZones' and equipmentZoneIndex or nil
            local removedCard = removeCardByUid(duel, sourceUid, { suppressSentTrigger = true })
            if not removedCard then
                return false, 'Equipment card could not be moved'
            end

            local slotKey = getEquipmentSlotKey(removedCard)
            if not slotKey then
                return false, 'Selected card is not an equipment card'
            end

            removedCard.zone = 'equipmentZone'
            removedCard.controller = targetPlayerIndex
            removedCard.equippedToZoneIndex = targetZoneIndex
            setEquipmentCardAt(targetPlayerState, targetZoneIndex, slotKey, removedCard)

            if oldPlayerState and oldZoneIndex then
                rebuildEquipmentModifiers(oldPlayerState, oldZoneIndex)
            end
            rebuildEquipmentModifiers(targetPlayerState, targetZoneIndex)

            if payload.triggerOnPlay and DuelEffects and getEffectApi then
                DuelEffects.RunTrigger(duel, 'on_play', playerIndex, removedCard, {
                    zone = 'equipmentZone',
                    zoneIndex = targetZoneIndex,
                    equippedByEffect = payload.equippedByEffect ~= false
                }, getEffectApi())
                checkWinCondition(duel)
            end

            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end

            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'move_equipment_select_equipment' then
            local targetCard, targetPlayerState, targetPlayerIndex, targetZoneName = findCardByUid(duel, selectedUid)
            if not targetCard or targetZoneName ~= 'equipmentZones' then
                return false, 'Selected card is no longer equipped'
            end

            if not cardMatchesSearchFilter(targetCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            if isTargetProtectedFromPlayer(duel, playerIndex, targetPlayerIndex, targetCard, pending.reason or 'card_effect') then
                return false, 'That card cannot be targeted by this effect'
            end

            local payload = pending.payload or {}
            queueCardSelection(duel, playerIndex, targetCard, {
                owner = payload.fighterOwner or 'self',
                zone = 'fighterZones',
                mode = 'attach_source_to_selected_fighter',
                filter = { type = 'Fighter' },
                payload = {
                    sourceUid = targetCard.uid,
                    triggerOnPlay = payload.triggerOnPlay == true,
                    equippedByEffect = true
                },
                title = 'Choose Fighter',
                text = 'Choose a fighter to move the equipment to.',
                emptyMessage = 'No valid fighters found.'
            })

            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'take_control_selected_equipment' then
            local targetCard, targetPlayerState, targetPlayerIndex, targetZoneName, targetZoneIndex = findCardByUid(duel, selectedUid)
            if not targetCard or targetZoneName ~= 'equipmentZones' then
                return false, 'Selected card is no longer equipped'
            end

            if not cardMatchesSearchFilter(targetCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            if isTargetProtectedFromPlayer(duel, playerIndex, targetPlayerIndex, targetCard, pending.reason or 'card_effect') then
                return false, 'That card cannot be targeted by this effect'
            end

            queueCardSelection(duel, playerIndex, targetCard, {
                owner = 'self',
                zone = 'fighterZones',
                mode = 'hayes_choose_control_fighter',
                filter = { type = 'Fighter' },
                minChoices = 1,
                maxChoices = 1,
                payload = {
                    vehicleUid = targetCard.uid,
                    originalPlayerIndex = targetPlayerIndex,
                    allowReclaim = pending.payload and pending.payload.allowReclaim ~= false
                },
                title = pending.payload and pending.payload.chooseFighterTitle or 'Choose Fighter',
                text = pending.payload and pending.payload.chooseFighterText or 'Choose a fighter to equip the stolen equipment to.',
                emptyMessage = 'No available fighter can control that vehicle.'
            })

            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'hayes_choose_control_fighter' then
            local payload = pending.payload or {}
            local vehicleUid = payload.vehicleUid
            local vehicleCard, vehiclePlayerState, vehiclePlayerIndex, vehicleZoneName, vehicleZoneIndex = findCardByUid(duel, vehicleUid)
            if not vehicleCard or vehicleZoneName ~= 'equipmentZones' then
                return false, 'Selected vehicle is no longer equipped'
            end

            local fighterCard, fighterPlayerState, fighterPlayerIndex, fighterZoneName, fighterZoneIndex = findCardByUid(duel, selectedUid)
            if not fighterCard or fighterPlayerIndex ~= playerIndex or fighterZoneName ~= 'fighterZones' then
                return false, 'Selected fighter is no longer under your control'
            end

            if not cardMatchesSearchFilter(fighterCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            if not canEquipCardToFighter(playerState, vehicleCard, fighterZoneIndex) then
                return false, 'That fighter cannot equip this vehicle'
            end

            local removedCard = removeCardByUid(duel, vehicleUid, { suppressSentTrigger = true })
            if not removedCard then
                return false, 'Selected vehicle could not be moved'
            end

            local slotKey = getEquipmentSlotKey(removedCard)
            if not slotKey then
                return false, 'Selected card is not an equipment card'
            end

            removedCard.zone = 'equipmentZone'
            removedCard.controller = playerIndex
            removedCard.previousController = payload.originalPlayerIndex or vehiclePlayerIndex
            removedCard.equippedToZoneIndex = fighterZoneIndex
            setEquipmentCardAt(playerState, fighterZoneIndex, slotKey, removedCard)

            rebuildEquipmentModifiers(vehiclePlayerState, vehicleZoneIndex)
            rebuildEquipmentModifiers(playerState, fighterZoneIndex)

            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end

            if payload.allowReclaim ~= false then
                queueCardSelection(duel, removedCard.previousController, removedCard, {
                    owner = 'self',
                    zone = 'field',
                    mode = 'hayes_reclaim_vehicle',
                    filter = {},
                    minChoices = 0,
                    maxChoices = 1,
                    payload = {
                        vehicleUid = removedCard.uid
                    },
                    title = 'Hayes Towing',
                    text = 'You can sacrifice 1 card you control to send your vehicle back to your hand.',
                    emptyMessage = 'No cards available to sacrifice for Hayes Towing.'
                })
            end

            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'hayes_reclaim_vehicle' then
            local payload = pending.payload or {}
            local vehicleUid = payload.vehicleUid
            local vehicleCard, vehiclePlayerState, vehiclePlayerIndex, vehicleZoneName, vehicleZoneIndex = findCardByUid(duel, vehicleUid)
            if not vehicleCard or vehicleZoneName ~= 'equipmentZones' then
                return false, 'Vehicle is no longer controlled by Hayes Towing'
            end

            local sacrificeCard, sacrificePlayerState, sacrificePlayerIndex = findCardByUid(duel, selectedUid)
            if not sacrificeCard or sacrificePlayerIndex ~= playerIndex then
                return false, 'Selected sacrifice is no longer under your control'
            end

            if not cardMatchesSearchFilter(sacrificeCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            moveCardByUidToGraveyard(duel, selectedUid, {
                reason = 'sacrifice',
                sourceUid = pending.sourceUid,
                sourceCardId = pending.sourceCardId,
                skipReplacement = true
            })

            local removedVehicle = removeCardByUid(duel, vehicleUid, { suppressSentTrigger = true })
            if not removedVehicle then
                return false, 'Vehicle could not be reclaimed'
            end

            removedVehicle.zone = 'hand'
            removedVehicle.controller = playerIndex
            removedVehicle.previousController = nil
            removedVehicle.equippedToZoneIndex = nil
            playerState.hand = playerState.hand or {}
            playerState.hand[#playerState.hand + 1] = removedVehicle

            rebuildEquipmentModifiers(vehiclePlayerState, vehicleZoneIndex)

            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'destroy_selected_field_card' then
            local targetPlayerState = duel.players[pending.targetPlayerIndex]
            local targetCard, zoneName, zoneIndex = findFieldCardByUid(targetPlayerState or {}, selectedUid)
            if not targetCard then
                return false, 'Selected card is no longer on the field'
            end

            if not cardMatchesSearchFilter(targetCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            if isTargetProtectedFromPlayer(duel, playerIndex, pending.targetPlayerIndex, targetCard, pending.reason or 'card_effect') then
                return false, 'That card cannot be targeted by this effect'
            end

            if zoneName == 'fighterZones' then
                moveFieldCardToGraveyard(targetPlayerState, zoneIndex, duel, {
                    reason = 'card_effect',
                    sourceUid = pending.sourceUid,
                    sourceCardId = pending.sourceCardId,
                    targetPlayerIndex = pending.targetPlayerIndex
                })
            elseif zoneName == 'itemZones' then
                moveItemZoneCardToGraveyard(targetPlayerState, zoneIndex, duel, {
                    reason = 'card_effect',
                    sourceUid = pending.sourceUid,
                    sourceCardId = pending.sourceCardId,
                    targetPlayerIndex = pending.targetPlayerIndex
                })
            elseif zoneName == 'equipmentZones' then
                moveCardByUidToGraveyard(duel, selectedUid, {
                    reason = 'card_effect',
                    sourceUid = pending.sourceUid,
                    sourceCardId = pending.sourceCardId,
                    targetPlayerIndex = pending.targetPlayerIndex
                })
            elseif zoneName == 'locationZone' then
                moveCardByUidToGraveyard(duel, selectedUid, {
                    reason = 'card_effect',
                    sourceUid = pending.sourceUid,
                    sourceCardId = pending.sourceCardId,
                    targetPlayerIndex = pending.targetPlayerIndex
                })
            end

            checkWinCondition(duel)
            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end
            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'banish_selected_field_card' then
            local targetPlayerState = duel.players[pending.targetPlayerIndex]
            local targetCard, zoneName = findFieldCardByUid(targetPlayerState or {}, selectedUid)
            if not targetCard then
                return false, 'Selected card is no longer on the field'
            end

            if not cardMatchesSearchFilter(targetCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            if isTargetProtectedFromPlayer(duel, playerIndex, pending.targetPlayerIndex, targetCard, pending.reason or 'card_effect') then
                return false, 'That card cannot be targeted by this effect'
            end

            banishCardByUid(duel, selectedUid)
            checkWinCondition(duel)
            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end
            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'revive_selected_graveyard_fighter' then
            local card, graveIndex = findCardInZoneByUid(playerState, 'graveyard', selectedUid)
            if not card or not graveIndex then
                return false, 'Selected card is no longer in your cemetery'
            end

            if not cardMatchesSearchFilter(card, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            local zoneIndex = nil
            for i = 1, 3 do
                if not playerState.fighterZones[i] then
                    zoneIndex = i
                    break
                end
            end

            if not zoneIndex then
                return false, 'No open fighter zone'
            end

            table.remove(playerState.graveyard, graveIndex)
            card.zone = 'fighterZone'
            card.controller = playerIndex
            card.hasAttacked = false
            resetFighterHp(card)
            playerState.fighterZones[zoneIndex] = card
            triggerSummonResponseWindow(duel, playerIndex, card, {
                zoneIndex = zoneIndex,
                summonType = 'special',
                summoningPlayer = playerIndex
            })
            checkWinCondition(duel)
            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end
            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'apply_status_to_selected_card' then
            local targetPlayerState = duel.players[pending.targetPlayerIndex]
            local targetCard = findFieldCardByUid(targetPlayerState or {}, selectedUid)
            if not targetCard then
                return false, 'Selected card is no longer on the field'
            end

            if not cardMatchesSearchFilter(targetCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            if isTargetProtectedFromPlayer(duel, playerIndex, pending.targetPlayerIndex, targetCard, pending.reason or 'card_effect') then
                return false, 'That card cannot be targeted by this effect'
            end

            targetCard.statuses = targetCard.statuses or {}
            for _, status in ipairs((pending.payload and pending.payload.statuses) or {}) do
                targetCard.statuses[#targetCard.statuses + 1] = {
                    id = status.id or status.status or status.name or 'status',
                    name = status.name or status.id or status.status or 'Status',
                    amount = tonumber(status.amount or status.damage),
                    timing = status.timing or 'end_turn',
                    remaining = status.turns and tonumber(status.turns) or nil
                }
            end

            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end
            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'modify_selected_card_stats' then
            local targetPlayerState = duel.players[pending.targetPlayerIndex]
            local targetCard = findFieldCardByUid(targetPlayerState or {}, selectedUid)
            if not targetCard then
                return false, 'Selected card is no longer on the field'
            end

            if not cardMatchesSearchFilter(targetCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            if isTargetProtectedFromPlayer(duel, playerIndex, pending.targetPlayerIndex, targetCard, pending.reason or 'card_effect') then
                return false, 'That card cannot be targeted by this effect'
            end

            local payload = pending.payload or {}
            local duration = payload.duration or 'permanent'
            local bucketName = duration == 'turn' and 'turnStatModifiers' or 'statModifiers'
            targetCard[bucketName] = targetCard[bucketName] or {}

            for stat, amount in pairs(payload.stats or {}) do
                local key = stat
                if stat == 'defense' or stat == 'health' then
                    key = 'hp'
                end
                local value = tonumber(amount) or 0
                targetCard[bucketName][key] = (tonumber(targetCard[bucketName][key]) or 0) + value
                if key == 'hp' then
                    ensureFighterHp(targetCard)
                    targetCard.maxHp = math.max(0, (tonumber(targetCard.maxHp) or 0) + value)
                    if value > 0 then
                        targetCard.currentHp = (tonumber(targetCard.currentHp) or 0) + value
                    elseif (tonumber(targetCard.currentHp) or 0) > (tonumber(targetCard.maxHp) or 0) then
                        targetCard.currentHp = targetCard.maxHp
                    end
                end
            end

            if payload.durationTurns and DuelEffects and DuelEffects.RunActions and scheduleDelayedTask then
                local reverseStats = {}
                for stat, amount in pairs(payload.stats or {}) do
                    reverseStats[stat] = -(tonumber(amount) or 0)
                end
                scheduleDelayedTask(duel, {
                    sourcePlayerIndex = playerIndex,
                    sourceUid = pending.sourceUid,
                    tickPlayerIndex = pending.targetPlayerIndex,
                    timing = payload.durationTiming or 'end_turn',
                    remaining = tonumber(payload.durationTurns) or 1,
                    targetUids = { selectedUid },
                    actions = {
                        {
                            action = 'modify_stats',
                            target = 'event_target',
                            stats = reverseStats
                        }
                    },
                    label = payload.durationLabel or 'Temporary stat modifier expires'
                })
            end

            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end
            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'set_selected_card_stats' then
            local targetPlayerState = duel.players[pending.targetPlayerIndex]
            local targetCard, _, targetPlayerIndex = nil, nil, pending.targetPlayerIndex
            if targetPlayerState then
                targetCard = findFieldCardByUid(targetPlayerState, selectedUid)
            else
                targetCard, targetPlayerState, targetPlayerIndex = findCardByUid(duel, selectedUid)
            end
            if not targetCard then
                return false, 'Selected card is no longer on the field'
            end

            if not cardMatchesSearchFilter(targetCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            if isTargetProtectedFromPlayer(duel, playerIndex, targetPlayerIndex, targetCard, pending.reason or 'card_effect') then
                return false, 'That card cannot be targeted by this effect'
            end

            local payload = pending.payload or {}
            local duration = payload.duration or 'permanent'
            local bucketName = duration == 'turn' and 'turnStatModifiers' or 'statModifiers'
            targetCard[bucketName] = targetCard[bucketName] or {}

            for stat, desiredValue in pairs(payload.stats or {}) do
                local key = stat
                if stat == 'defense' or stat == 'health' then
                    key = 'hp'
                end
                local desired = tonumber(desiredValue)
                if desired then
                    local current = getCardStat(targetCard, key)
                    local delta = desired - current
                    targetCard[bucketName][key] = (tonumber(targetCard[bucketName][key]) or 0) + delta
                    if key == 'hp' then
                        ensureFighterHp(targetCard)
                        targetCard.maxHp = math.max(0, (tonumber(targetCard.maxHp) or 0) + delta)
                        if (tonumber(targetCard.currentHp) or 0) > (tonumber(targetCard.maxHp) or 0) then
                            targetCard.currentHp = targetCard.maxHp
                        end
                    end
                end
            end

            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end
            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'heal_selected_fighter' then
            local targetPlayerState = duel.players[pending.targetPlayerIndex]
            local targetCard = findFieldCardByUid(targetPlayerState or {}, selectedUid)
            if not targetCard then
                return false, 'Selected card is no longer on the field'
            end

            if not cardMatchesSearchFilter(targetCard, pending.filter) then
                return false, 'Selected card is not valid for this effect'
            end

            if isTargetProtectedFromPlayer(duel, playerIndex, pending.targetPlayerIndex, targetCard, pending.reason or 'card_effect') then
                return false, 'That card cannot be targeted by this effect'
            end

            local payload = pending.payload or {}
            ensureFighterHp(targetCard)
            local amount = tonumber(payload.amount) or 0
            if payload.toBase == true then
                targetCard.currentHp = tonumber(targetCard.maxHp) or targetCard.currentHp or 0
            elseif amount > 0 then
                targetCard.currentHp = math.min(tonumber(targetCard.maxHp) or 0, (tonumber(targetCard.currentHp) or 0) + amount)
            end

            local removeStatus = payload.removeStatus
            if removeStatus and type(targetCard.statuses) == 'table' then
                local shouldRemove = true
                if payload.removeStatusOnCoin == true then
                    local result = math.random(1, 2) == 1 and 'heads' or 'tails'
                    duel.log = duel.log or {}
                    duel.log[#duel.log + 1] = {
                        turn = duel.turnNumber,
                        phase = duel.phase,
                        message = ('Coin flip for %s was %s.'):format(removeStatus, result)
                    }
                    shouldRemove = result == tostring(payload.removeStatusCoinResult or 'tails'):lower()
                end

                if shouldRemove then
                    for index = #targetCard.statuses, 1, -1 do
                        local status = targetCard.statuses[index]
                        local id = string.lower(tostring(status.id or status.name or ''))
                        if id == string.lower(tostring(removeStatus)) then
                            table.remove(targetCard.statuses, index)
                        end
                    end
                end
            end

            for itemZoneIndex, itemCard in pairs(playerState.itemZones or {}) do
                if itemCard and itemCard.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, itemZoneIndex)
                end
            end
            sendDuelStateToPlayers(duel)
            return true
        end

        if pending.mode == 'add_to_hand' and maxChoices > 1 then
            for _, uid in ipairs(chosenUids) do
                local card, deckIndex = findCardInZoneByUid(playerState, 'deck', uid)
                if not card or not deckIndex then
                    return false, 'Selected card is no longer in your deck'
                end

                if not cardMatchesSearchFilter(card, pending.filter) then
                    return false, 'Selected card is not valid for this effect'
                end
            end

            for _, uid in ipairs(chosenUids) do
                local card, deckIndex = findCardInZoneByUid(playerState, 'deck', uid)
                if card and deckIndex then
                    table.remove(playerState.deck, deckIndex)
                    card.zone = 'hand'
                    playerState.hand[#playerState.hand + 1] = card
                end
            end

            if not duel.pendingActionQueue and not duel.pendingSelection then
                for zoneIndex, zoneCard in pairs(playerState.itemZones or {}) do
                    if zoneCard and zoneCard.temporaryItemZoneIndex then
                        moveItemZoneCardToGraveyard(playerState, zoneIndex)
                    end
                end
            end

            sendDuelStateToPlayers(duel)
            return true
        end

        local card, deckIndex = findCardInZoneByUid(playerState, 'deck', selectedUid)
        if not card or not deckIndex then
            return false, 'Selected card is no longer in your deck'
        end

        if not cardMatchesSearchFilter(card, pending.filter) then
            return false, 'Selected card is not valid for this effect'
        end

        if pending.mode == 'equip_from_deck' then
            local choices = {}
            for i = 1, 3 do
                local fighter = playerState.fighterZones and playerState.fighterZones[i] or nil
                if fighter and canEquipCardToFighter(playerState, card, i) then
                    choices[#choices + 1] = buildCardPayload(fighter)
                end
            end

            if #choices == 0 then
                return false, 'No available fighter can equip that card'
            end

            duel.selectionCounter = (duel.selectionCounter or 0) + 1
            local cardDef = getCardDefinition(card.cardId)
            duel.pendingSelection = {
                id = tostring(duel.selectionCounter),
                playerIndex = playerIndex,
                sourceUid = pending.sourceUid,
                zone = 'fighterZones',
                mode = 'equip_target',
                equipmentUid = card.uid,
                title = 'Choose Fighter',
                text = ('Choose a fighter to equip %s to.'):format(cardDef and cardDef.name or card.cardId),
                minChoices = 1,
                maxChoices = 1,
                choices = choices
            }

            sendDuelStateToPlayers(duel)
            return true
        end

        table.remove(playerState.deck, deckIndex)
        card.zone = 'hand'
        playerState.hand[#playerState.hand + 1] = card
    end

    if not duel.pendingActionQueue and not duel.pendingSelection then
        local playerState = duel.players[playerIndex]
        if playerState then
            for zoneIndex, card in pairs(playerState.itemZones or {}) do
                if card and card.temporaryItemZoneIndex then
                    moveItemZoneCardToGraveyard(playerState, zoneIndex)
                end
            end
        end
    end

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.ActivateEffect(src, duelId, sourceUid)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    if duel.status ~= "active" then
        return false, 'Duel is not active'
    end

    if duel.pendingEffect or duel.pendingSelection or duel.effectChain then
        return false, 'Resolve the pending effect first'
    end

    local playerIndex = getControllingPlayerIndex(duel, src)
    if not playerIndex then
        return false, 'Player not in duel'
    end

    if duel.turnPlayer ~= playerIndex then
        return false, 'Not your turn'
    end

    if not isMainPhase(duel.phase) then
        return false, 'You can only activate effects in a Main Phase'
    end

    local playerState = duel.players[playerIndex]
    local card = findPlayerCardByUid(playerState, sourceUid)
    if not card then
        return false, 'Card not found'
    end

    if cardHasStatus(card, 'cannot_activate') then
        return false, 'That card cannot activate effects'
    end

    if not isCardActivatable(card, duel, playerIndex) then
        return false, 'That card has no activatable effect'
    end

    local event = {
        responseEvent = 'effect_activated',
        trigger = 'effect_activated',
        manual = true,
        activatedUid = card.uid,
        activatedCard = card,
        activatingPlayer = playerIndex
    }
    local responseStarted = startResponseWindowOrRunContinuation(duel, getOpponentIndex(playerIndex), {
        kind = 'activated_effect',
        playerIndex = playerIndex,
        sourceUid = card.uid,
        event = event
    }, event, ('Your opponent activated %s. Chain a response?'):format((getCardDefinition(card.cardId) or {}).name or card.cardId))

    if not responseStarted and not duel.pendingEffect and not duel.pendingSelection then
        return false, 'No effect activated'
    end

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.GetById(duelId)
    return Duel.Active[duelId]
end
