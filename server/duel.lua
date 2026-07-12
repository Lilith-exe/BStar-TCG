local QBCore = exports['qb-core']:GetCoreObject()

Duel = Duel or {}
Duel.Active = Duel.Active or {}

local duelCounter = 0
local getEffectApi
local moveFieldCardToGraveyard
local queueEffectPrompt
local queueDeckSearch

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
        if card and card.uid == uid then
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

local function getCardDefinition(cardId)
    return Cards and Cards[cardId] or nil
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

local function isCardActivatable(card)
    local def = card and getCardDefinition(card.cardId) or nil
    return DuelEffects and DuelEffects.HasTrigger and DuelEffects.HasTrigger(def, 'activated') or false
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

local function buildCardPayload(cardInstance)
    local def = getCardDefinition(cardInstance.cardId)

    return {
        uid = cardInstance.uid,
        cardId = cardInstance.cardId,
        owner = cardInstance.owner,
        controller = cardInstance.controller,
        zone = cardInstance.zone,
        hasAttacked = cardInstance.hasAttacked or false,

        name = def and def.name or cardInstance.cardId,
        inventoryImage = def and def.inventoryImage or nil,
        rarity = def and def.rarity or nil,
        type = def and def.type or nil,
        job = def and def.job or nil,
        level = def and def.level or nil,
        attack = def and (def.attack or def.atk) or nil,
        defense = def and (def.defense or def.def) or nil,
        hp = cardInstance.currentHp,
        maxHp = cardInstance.maxHp,
        health = getCardHealthText(def),
        speed = def and (def.speed or def.spd) or nil,
        effectTitle = def and def.effectTitle or nil,
        effectText = def and def.effectText or nil,
        effectTags = DuelEffects and DuelEffects.GetTags(def) or {},
        continuous = def and (def.continuous == true or def.isContinuous == true) or false,
        activatableEffect = isCardActivatable(cardInstance),
        setCode = def and def.setCode or nil,
        edition = def and def.edition or nil
    }
end

local function buildCardPayloadList(cardList)
    local payload = {}

    for i = 1, #(cardList or {}) do
        payload[#payload + 1] = buildCardPayload(cardList[i])
    end

    return payload
end

local function buildZonePayload(zone)
    local payload = {}

    for i = 1, #(zone or {}) do
        if zone[i] then
            payload[i] = buildCardPayload(zone[i])
        else
            payload[i] = nil
        end
    end

    return payload
end

local function buildFixedZonePayload(zone, count)
    local payload = {}

    for i = 1, count do
        if zone and zone[i] then
            payload[i] = buildCardPayload(zone[i])
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
    return cardType == 'ITEM'
end

local function isEquipmentZoneCardType(cardType)
    return cardType == 'VEHICLE' or cardType == 'WEAPON' or cardType == 'EQUIPMENT'
end

local function cardDefHasTag(cardDef, targetTag)
    targetTag = tostring(targetTag or ''):lower()

    for _, tag in ipairs(cardDef and cardDef.effectTags or {}) do
        if tostring(tag or ''):lower() == targetTag then
            return true
        end
    end

    return false
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

local function drawCards(duel, playerIndex, amount)
    local player = duel.players[playerIndex]
    if not player then return 0 end
    if duel.status == "finished" then return 0 end

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

        if DuelEffects and getEffectApi then
            DuelEffects.RunFieldTrigger(duel, 'on_draw', playerIndex, {
                drawnCard = card
            }, getEffectApi())
        end
    end

    return drawn
end

local function moveHandCardToGraveyard(playerState, handIndex)
    local card = table.remove(playerState.hand, handIndex)
    if not card then return nil end

    card.zone = "graveyard"
    playerState.graveyard[#playerState.graveyard + 1] = card
    return card
end

local function resetTurnFlags(playerState)
    playerState.hasSummonedThisTurn = false

    for _, zoneCard in pairs(playerState.fighterZones) do
        if zoneCard then
            zoneCard.hasAttacked = false
        end
    end
end

local function resetBattleFlags(playerState)
    for _, zoneCard in pairs(playerState.fighterZones) do
        if zoneCard then
            zoneCard.hasAttacked = false
        end
    end
end

local function buildPrivateStateForPlayer(duel, viewerIndex)
    local selfState = duel.players[viewerIndex]
    local oppIndex = getOpponentIndex(viewerIndex)
    local oppState = duel.players[oppIndex]

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
        pendingEffect = duel.pendingEffect and duel.pendingEffect.playerIndex == viewerIndex and {
            id = duel.pendingEffect.id,
            sourceUid = duel.pendingEffect.sourceUid,
            cardName = duel.pendingEffect.cardName,
            title = duel.pendingEffect.title,
            text = duel.pendingEffect.text,
            effectText = duel.pendingEffect.effectText
        } or nil,
        pendingSelection = duel.pendingSelection and duel.pendingSelection.playerIndex == viewerIndex and {
            id = duel.pendingSelection.id,
            title = duel.pendingSelection.title,
            text = duel.pendingSelection.text,
            choices = duel.pendingSelection.choices
        } or nil,

        selfPlayer = {
            source = selfState.source,
            deckCount = #selfState.deck,
            hand = buildCardPayloadList(selfState.hand),
            graveyardCount = #selfState.graveyard,
            fighterZones = buildFixedZonePayload(selfState.fighterZones, 3),
            itemZones = buildFixedZonePayload(selfState.itemZones, 4),
            equipmentZones = buildFixedZonePayload(selfState.equipmentZones, 3),
            locationZone = selfState.locationZone and buildCardPayload(selfState.locationZone) or nil,
            hasSummonedThisTurn = selfState.hasSummonedThisTurn,
            lifePoints = selfState.lifePoints,
            graveyard = buildCardPayloadList(selfState.graveyard)
        },

        opponentPlayer = {
            source = oppState.source,
            deckCount = #oppState.deck,
            handCount = #oppState.hand,
            graveyardCount = #oppState.graveyard,
            fighterZones = buildFixedZonePayload(oppState.fighterZones, 3),
            itemZones = buildFixedZonePayload(oppState.itemZones, 4),
            equipmentZones = buildFixedZonePayload(oppState.equipmentZones, 3),
            locationZone = oppState.locationZone and buildCardPayload(oppState.locationZone) or nil,
            hasSummonedThisTurn = oppState.hasSummonedThisTurn,
            lifePoints = oppState.lifePoints,
            graveyard = buildCardPayloadList(oppState.graveyard)
        }
    }
end

local function sendDuelStateToPlayers(duel)
    local sentToSource = {}

    for playerIndex, playerState in pairs(duel.players) do
        local src = playerState.source

        if not sentToSource[src] then
            local payloadIndex = playerIndex

            -- Solo/self-test duel: same player controls both sides.
            -- Show the current turn player's perspective so one client can fully test both decks.
            if duel.players[1].source == duel.players[2].source then
                payloadIndex = duel.turnPlayer
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
        lifePoints = 1000
    }
end

local function getCardStat(card, statName)
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
    value = value + (tonumber(modifiers[statName]) or 0)

    if statName == 'hp' or statName == 'health' or statName == 'defense' then
        value = value + (tonumber(modifiers.hp) or 0)
    end

    return value
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
        drawCards = drawCards,
        moveHandCardToGraveyard = moveHandCardToGraveyard,
        moveFieldCardToGraveyard = moveFieldCardToGraveyard,
        resetFighterHp = resetFighterHp,
        ensureFighterHp = ensureFighterHp,
        queueEffectPrompt = queueEffectPrompt,
        queueDeckSearch = queueDeckSearch
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

local function getOccupiedFighterCount(playerState)
    local count = 0
    for i = 1, 3 do
        if playerState.fighterZones[i] then
            count = count + 1
        end
    end
    return count
end

moveFieldCardToGraveyard = function(playerState, zoneIndex)
    local card = playerState.fighterZones[zoneIndex]
    if not card then return nil end

    local equipment = playerState.equipmentZones and playerState.equipmentZones[zoneIndex] or nil
    if equipment then
        playerState.equipmentZones[zoneIndex] = nil
        equipment.zone = "graveyard"
        playerState.graveyard[#playerState.graveyard + 1] = equipment
    end

    playerState.fighterZones[zoneIndex] = nil
    card.zone = "graveyard"
    playerState.graveyard[#playerState.graveyard + 1] = card

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

local function isMainPhase(phase)
    return phase == "main" or phase == "main2"
end

queueEffectPrompt = function(duel, playerIndex, sourceCard, triggerName, effectIndex, prompt)
    if not duel or duel.pendingEffect or not sourceCard then return false end

    duel.effectPromptCounter = (duel.effectPromptCounter or 0) + 1
    duel.pendingEffect = {
        id = tostring(duel.effectPromptCounter),
        playerIndex = playerIndex,
        sourceUid = sourceCard.uid,
        sourceCardId = sourceCard.cardId,
        trigger = triggerName,
        effectIndex = effectIndex,
        cardName = (prompt and prompt.cardName) or (getCardDefinition(sourceCard.cardId) and getCardDefinition(sourceCard.cardId).name) or sourceCard.cardId,
        title = prompt and prompt.title or 'Effect',
        text = prompt and prompt.text or 'Do you want to activate this effect?',
        effectText = prompt and prompt.effectText or nil
    }

    return true
end

local function cardMatchesSearchFilter(card, filter)
    local def = card and getCardDefinition(card.cardId) or nil
    filter = filter or {}

    if not def then return false end

    if filter.type and string.upper(tostring(def.type or '')) ~= string.upper(tostring(filter.type)) then
        return false
    end

    if filter.nameContains then
        local nameText = string.lower(tostring(def.name or ''))
        if not nameText:find(string.lower(tostring(filter.nameContains)), 1, true) then
            return false
        end
    end

    if filter.jobContains then
        local jobText = string.lower(tostring(def.job or ''))
        if not jobText:find(string.lower(tostring(filter.jobContains)), 1, true) then
            return false
        end
    end

    local level = getCardLevelValue(def)
    if filter.level and level ~= tonumber(filter.level) then return false end
    if filter.levelMin and level < tonumber(filter.levelMin) then return false end
    if filter.levelMax and level > tonumber(filter.levelMax) then return false end

    return true
end

queueDeckSearch = function(duel, playerIndex, sourceCard, filter, prompt)
    if not duel or duel.pendingSelection then return false end

    local playerState = duel.players[playerIndex]
    if not playerState then return false end

    local sourceDef = sourceCard and getCardDefinition(sourceCard.cardId) or nil

    local choices = {}
    local maxChoices = tonumber(prompt and prompt.maxChoices) or 30

    for _, card in ipairs(playerState.deck or {}) do
        if cardMatchesSearchFilter(card, filter) then
            choices[#choices + 1] = buildCardPayload(card)
            if #choices >= maxChoices then break end
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
        title = prompt and prompt.title or 'Search Deck',
        text = prompt and prompt.text or 'Choose 1 card to add to your hand.',
        choices = choices
    }

    TriggerClientEvent('QBCore:Notify', playerState.source, ('Choose from %s matching card(s).'):format(#choices), 'primary')
    TriggerClientEvent('bstar_cards:client:PendingCardSelection', playerState.source, {
        duelId = duel.id,
        selection = {
            id = duel.pendingSelection.id,
            title = duel.pendingSelection.title,
            text = duel.pendingSelection.text,
            choices = duel.pendingSelection.choices
        }
    })
    return true
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
end

local function completeEndTurn(duel, playerIndex)
    resetBattleFlags(duel.players[playerIndex])

    duel.turnPlayer = getOpponentIndex(duel.turnPlayer)
    duel.turnNumber = duel.turnNumber + 1
    duel.phase = "draw"
    duel.hasDrawnThisTurn = false
    duel.endPhaseEffectsResolvedForTurn = nil

    resetTurnFlags(duel.players[duel.turnPlayer])
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

function Duel.Attack(src, duelId, attackerZoneIndex, targetType, targetZoneIndex)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    if duel.status ~= "active" then
        return false, 'Duel is not active'
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

    if attackerCard.hasAttacked then
        return false, 'This fighter already attacked this turn'
    end

    local attackerATK = getCardStat(attackerCard, 'attack')

    local battleResult = {
        attackerZoneIndex = attackerZoneIndex,
        targetType = targetType,
        targetZoneIndex = tonumber(targetZoneIndex) or 0,
        attackingPlayer = playerIndex,
        defendingPlayer = defenderIndex,
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

    -- Direct attack
    if targetType == 'direct' then
        if getOccupiedFighterCount(defenderState) > 0 then
            return false, 'Cannot direct attack while opponent controls fighters'
        end

        defenderState.lifePoints = math.max(0, defenderState.lifePoints - attackerATK)
        attackerCard.hasAttacked = true
        battleResult.damageToDefenderPlayer = attackerATK

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
    ensureFighterHp(defenderCard)
    battleResult.defenderCard = buildCardPayload(defenderCard)

    local dodgeChance = calculateDodgeChance(attackerCard, defenderCard)
    local dodged = rollSuccess(dodgeChance)

    attackerCard.hasAttacked = true
    battleResult.targetZoneIndex = targetZoneIndex
    battleResult.dodged = dodged
    battleResult.dodgeChance = dodgeChance

    if dodged then
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
    local defenderHpAfter = math.max(0, defenderHpBefore - attackerATK)

    defenderCard.currentHp = defenderHpAfter
    battleResult.damageToDefenderFighter = math.max(0, defenderHpBefore - defenderHpAfter)
    battleResult.defenderHpBefore = defenderHpBefore
    battleResult.defenderHpAfter = defenderHpAfter
    battleResult.defenderCard = buildCardPayload(defenderCard)

    if defenderHpAfter <= 0 then
        local overflowDamage = math.max(0, attackerATK - defenderHpBefore)

        if overflowDamage > 0 then
            defenderState.lifePoints = math.max(0, defenderState.lifePoints - overflowDamage)
            battleResult.damageToDefenderPlayer = overflowDamage
        end

        moveFieldCardToGraveyard(defenderState, targetZoneIndex)
        battleResult.defenderDestroyed = true
    end

    battleResult.attackerHpAfter = attackerCard.currentHp

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
        log = {}
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
    elseif duel.phase == "main" then
        duel.phase = "battle"
    elseif duel.phase == "battle" then
        duel.phase = "main2"
        resetBattleFlags(duel.players[playerIndex])
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

    moveHandCardToGraveyard(playerState, handIndex)

    if #playerState.hand <= 9 then
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
    if not playerState or #playerState.deck == 0 then
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

    if getCardLevelValue(def) ~= 1 then
        return false, 'Only stage 1 fighters can be normal summoned'
    end

    table.remove(playerState.hand, handIndex)
    card.zone = "fighterZone"
    resetFighterHp(card)
    playerState.fighterZones[zoneIndex] = card
    playerState.hasSummonedThisTurn = true

    if DuelEffects and getEffectApi then
        DuelEffects.RunTrigger(duel, 'on_summon', playerIndex, card, {
            zoneIndex = zoneIndex,
            summonType = 'normal'
        }, getEffectApi())
        checkWinCondition(duel)
    end

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

    if duel.turnPlayer ~= playerIndex then
        return false, 'Not your turn'
    end

    if not isMainPhase(duel.phase) then
        return false, 'You can only promote in a Main Phase'
    end

    local playerState = duel.players[playerIndex]

    if playerState.hasSummonedThisTurn then
        return false, 'You already summoned this turn'
    end

    tributeZoneIndex = tonumber(tributeZoneIndex)
    if not tributeZoneIndex or tributeZoneIndex < 1 or tributeZoneIndex > 3 then
        return false, 'Invalid tribute zone'
    end

    local tributeCard = playerState.fighterZones[tributeZoneIndex]
    if not tributeCard then
        return false, 'No fighter to promote from in that zone'
    end

    local promotionCard, handIndex = findCardInZoneByUid(playerState, "hand", handUid)
    if not promotionCard then
        return false, 'Promotion card not found in hand'
    end

    local tributeDef = getCardDefinition(tributeCard.cardId)
    local promotionDef = getCardDefinition(promotionCard.cardId)

    if not canPromoteFromTo(tributeDef, promotionDef) then
        return false, 'That card cannot promote this fighter'
    end

    moveFieldCardToGraveyard(playerState, tributeZoneIndex)
    table.remove(playerState.hand, handIndex)

    promotionCard.zone = "fighterZone"
    promotionCard.hasAttacked = false
    resetFighterHp(promotionCard)
    playerState.fighterZones[tributeZoneIndex] = promotionCard
    playerState.hasSummonedThisTurn = true

    if DuelEffects and getEffectApi then
        DuelEffects.RunTrigger(duel, 'on_summon', playerIndex, promotionCard, {
            zoneIndex = tributeZoneIndex,
            summonType = 'promotion'
        }, getEffectApi())
        checkWinCondition(duel)
    end

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

        if DuelEffects and getEffectApi then
            DuelEffects.RunTrigger(duel, 'on_play', playerIndex, card, {
                zone = 'locationZone',
                replacedCard = replacedLocation
            }, getEffectApi())
            checkWinCondition(duel)
        end

        sendDuelStateToPlayers(duel)
        return true
    end

    if cardType == 'EVENT' then
        moveHandCardToGraveyard(playerState, handIndex)

        if DuelEffects and getEffectApi then
            DuelEffects.RunTrigger(duel, 'on_play', playerIndex, card, {
                zone = 'graveyard'
            }, getEffectApi())
            checkWinCondition(duel)
        end

        sendDuelStateToPlayers(duel)
        return true
    end

    if isItemZoneCardType(cardType) then
        local isContinuous = isContinuousItemCard(card)

        if isContinuous then
            zoneIndex = tonumber(zoneIndex)
            if not zoneIndex or zoneIndex < 1 or zoneIndex > 4 then
                return false, 'Invalid item zone'
            end

            if playerState.itemZones[zoneIndex] ~= nil then
                return false, 'That item zone is occupied'
            end

            table.remove(playerState.hand, handIndex)
            card.zone = "itemZone"
            playerState.itemZones[zoneIndex] = card
        else
            moveHandCardToGraveyard(playerState, handIndex)
            zoneIndex = 0
        end

        if DuelEffects and getEffectApi then
            DuelEffects.RunTrigger(duel, 'on_play', playerIndex, card, {
                zone = isContinuous and 'itemZone' or 'graveyard',
                zoneIndex = zoneIndex,
                continuous = isContinuous
            }, getEffectApi())
            checkWinCondition(duel)
        end

        sendDuelStateToPlayers(duel)
        return true
    end

    if isEquipmentZoneCardType(cardType) then
        zoneIndex = tonumber(zoneIndex)
        if not zoneIndex or zoneIndex < 1 or zoneIndex > 3 then
            return false, 'Invalid equipment zone'
        end

        if playerState.fighterZones[zoneIndex] == nil then
            return false, 'Choose a fighter to equip this card to'
        end

        if playerState.equipmentZones[zoneIndex] ~= nil then
            return false, 'That fighter already has an equipment card'
        end

        table.remove(playerState.hand, handIndex)
        card.zone = "equipmentZone"
        playerState.equipmentZones[zoneIndex] = card

        if DuelEffects and getEffectApi then
            DuelEffects.RunTrigger(duel, 'on_play', playerIndex, card, {
                zone = 'equipmentZone',
                zoneIndex = zoneIndex
            }, getEffectApi())
            checkWinCondition(duel)
        end

        sendDuelStateToPlayers(duel)
        return true
    end

    return false, 'This card type is not playable yet'
end

function Duel.ResolvePendingEffect(src, duelId, promptId, accepted)
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

    if accepted == true then
        local playerState = duel.players[playerIndex]
        local card = findPlayerCardByUid(playerState, pending.sourceUid)
        if card then
            local ok, err = DuelEffects.RunEffectByIndex(duel, playerIndex, card, pending.effectIndex, {
                trigger = pending.trigger,
                prompted = true
            }, getEffectApi())

            if not ok then
                return false, err
            end

            checkWinCondition(duel)
        end
    end

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.ResolvePendingSelection(src, duelId, selectionId, selectedUid)
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

    duel.pendingSelection = nil

    if selectedUid and selectedUid ~= '' then
        local playerState = duel.players[playerIndex]
        local card, deckIndex = findCardInZoneByUid(playerState, 'deck', selectedUid)
        if not card or not deckIndex then
            return false, 'Selected card is no longer in your deck'
        end

        if not cardMatchesSearchFilter(card, pending.filter) then
            return false, 'Selected card is not valid for this effect'
        end

        table.remove(playerState.deck, deckIndex)
        card.zone = 'hand'
        playerState.hand[#playerState.hand + 1] = card
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

    if duel.pendingEffect then
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
    local card = findFieldCardByUid(playerState, sourceUid)
    if not card then
        return false, 'Card not found on your field'
    end

    if not isCardActivatable(card) then
        return false, 'That card has no activatable effect'
    end

    local activated = DuelEffects.RunTrigger(duel, 'activated', playerIndex, card, {
        manual = true
    }, getEffectApi(), {
        force = true
    })

    if activated <= 0 then
        return false, 'No effect activated'
    end

    checkWinCondition(duel)
    sendDuelStateToPlayers(duel)
    return true
end

function Duel.GetById(duelId)
    return Duel.Active[duelId]
end
