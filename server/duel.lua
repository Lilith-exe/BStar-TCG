local QBCore = exports['qb-core']:GetCoreObject()

Duel = Duel or {}
Duel.Active = Duel.Active or {}

local duelCounter = 0

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

local function getCardDefinition(cardId)
    return Cards and Cards[cardId] or nil
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
        speed = def and (def.speed or def.spd) or nil,
        effectTitle = def and def.effectTitle or nil,
        effectText = def and def.effectText or nil,
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
    end

    return drawn
end
local function resetTurnFlags(playerState)
    playerState.hasSummonedThisTurn = false

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

        selfPlayer = {
            source = selfState.source,
            deckCount = #selfState.deck,
            hand = buildCardPayloadList(selfState.hand),
            graveyardCount = #selfState.graveyard,
            fighterZones = buildZonePayload(selfState.fighterZones),
            itemZones = buildZonePayload(selfState.itemZones),
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
            fighterZones = buildZonePayload(oppState.fighterZones),
            itemZones = buildZonePayload(oppState.itemZones),
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
        itemZones = { nil, nil, nil },
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
        if statName == 'speed' then raw = def.spd end
    end

    if type(raw) == 'number' then
        return raw
    end

    if type(raw) == 'string' then
        local match = string.match(raw, "-?%d+")
        return match and tonumber(match) or 0
    end

    return 0
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

local function moveFieldCardToGraveyard(playerState, zoneIndex)
    local card = playerState.fighterZones[zoneIndex]
    if not card then return nil end

    playerState.fighterZones[zoneIndex] = nil
    card.zone = "graveyard"
    playerState.graveyard[#playerState.graveyard + 1] = card

    return card
end

local function calculateDodgeChance(attackerCard, defenderCard)
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

    playerState.fighterZones[zoneIndex] = card

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
        attackerDestroyed = false,
        defenderDestroyed = false,
        dodged = false,
        damageToDefenderPlayer = 0,
        damageToAttackerPlayer = 0
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

    local dodgeChance = calculateDodgeChance(attackerCard, defenderCard)
    local dodged = rollSuccess(dodgeChance)

    attackerCard.hasAttacked = true
    battleResult.targetZoneIndex = targetZoneIndex
    battleResult.dodged = dodged

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

    local defenderDEF = getCardStat(defenderCard, 'defense')
    local difference = math.abs(attackerATK - defenderDEF)

    if attackerATK > defenderDEF then
        moveFieldCardToGraveyard(defenderState, targetZoneIndex)
        battleResult.defenderDestroyed = true

        if difference > 0 then
            defenderState.lifePoints = math.max(0, defenderState.lifePoints - difference)
            battleResult.damageToDefenderPlayer = difference
        end
    elseif attackerATK == defenderDEF then
        moveFieldCardToGraveyard(defenderState, targetZoneIndex)
        moveFieldCardToGraveyard(attackerState, attackerZoneIndex)
        battleResult.defenderDestroyed = true
        battleResult.attackerDestroyed = true
    else
        moveFieldCardToGraveyard(attackerState, attackerZoneIndex)
        battleResult.attackerDestroyed = true

        if difference > 0 then
            attackerState.lifePoints = math.max(0, attackerState.lifePoints - difference)
            battleResult.damageToAttackerPlayer = difference
        end
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
        status = "active",
        players = {
            [1] = playerA,
            [2] = playerB
        },
        turnPlayer = 1,
        turnNumber = 1,
        phase = "draw",
        log = {}
    }

    Duel.Active[duelId] = duel
    return duel
end

function Duel.Start(duelId)
    local duel = Duel.Active[duelId]
    if not duel then
        return false, 'Duel not found'
    end

    drawCards(duel, 1, 4)
    drawCards(duel, 2, 4)

    resetTurnFlags(duel.players[1])
    resetTurnFlags(duel.players[2])

    duel.phase = "draw"
    duel.turnPlayer = 1
    duel.turnNumber = 1

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
        duel.phase = "main"
    elseif duel.phase == "main" then
        duel.phase = "battle"
    elseif duel.phase == "battle" then
        duel.phase = "end"
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

    duel.turnPlayer = getOpponentIndex(duel.turnPlayer)
    duel.turnNumber = duel.turnNumber + 1
    duel.phase = "draw"

    local turnPlayerState = duel.players[duel.turnPlayer]
    resetTurnFlags(turnPlayerState)
    drawCards(duel, duel.turnPlayer, 1)
    checkWinCondition(duel)

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

    if duel.phase ~= "main" then
        return false, 'You can only summon in Main Phase'
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

    table.remove(playerState.hand, handIndex)
    card.zone = "fighterZone"
    playerState.fighterZones[zoneIndex] = card
    playerState.hasSummonedThisTurn = true

    sendDuelStateToPlayers(duel)
    return true
end

function Duel.GetById(duelId)
    return Duel.Active[duelId]
end
