local QBCore = exports['qb-core']:GetCoreObject()

local duelUiOpen = false
local currentDuelId = nil
local latestDuelState = nil

local function ForceDuelFocus()
    CreateThread(function()
        for i = 1, 3 do
            Wait(0)
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(false)
        end
    end)
end

local function OpenDuelUi(duelState)
    if not duelState or not duelState.duelId then return end

    currentDuelId = duelState.duelId
    latestDuelState = duelState
    duelUiOpen = true

    SendNUIMessage({
        action = 'openDuelUi',
        duel = duelState,
        tableMode = duelState.tableMode == true
    })

    ForceDuelFocus()
end

local function UpdateDuelUi(duelState)
    if not duelState or not duelState.duelId then
        return
    end

    currentDuelId = duelState.duelId
    latestDuelState = duelState

    if not duelUiOpen then
        OpenDuelUi(duelState)
        return
    end

    print('[BStar Duel] UpdateDuelUi called, CurrentDuelTableId =', CurrentDuelTableId)

    SendNUIMessage({
        action = 'updateDuelUi',
        duel = duelState,
        tableMode = duelState.tableMode == true
    })

end

local function CloseDuelUi()
    duelUiOpen = false
    currentDuelId = nil
    latestDuelState = nil

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    TriggerEvent('bstar_cards:client:ExitDuelTableView')

    SendNUIMessage({
        action = 'closeDuelUi'
    })
end
RegisterNetEvent('bstar_cards:client:OpenDuelUi', function(duelState)
    if duelUiOpen and currentDuelId == duelState.duelId then
        UpdateDuelUi(duelState)
    else
        OpenDuelUi(duelState)
    end
end)

RegisterNetEvent('bstar_cards:client:CloseDuelUi', function()
    CloseDuelUi()
end)

RegisterNetEvent('bstar_cards:client:BattleEvent', function(data)
    SendNUIMessage({
        action = 'battleEvent',
        data = data
    })
end)

RegisterNUICallback('duelAdvancePhase', function(data, cb)
    if currentDuelId then
        TriggerServerEvent('bstar_cards:server:DuelAdvancePhase', currentDuelId)
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelEndTurn', function(data, cb)
    if currentDuelId then
        TriggerServerEvent('bstar_cards:server:DuelEndTurn', currentDuelId)
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelSummonFighter', function(data, cb)
    if currentDuelId and data and data.handUid and data.zoneIndex then
        TriggerServerEvent('bstar_cards:server:DuelSummonFighter', currentDuelId, data.handUid, data.zoneIndex)
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelCloseUi', function(_, cb)
    CloseDuelUi()
    cb({ ok = true })
end)

RegisterNUICallback('duelAttack', function(data, cb)
    if currentDuelId and data and data.attackerZoneIndex and data.targetType then
        TriggerServerEvent(
            'bstar_cards:server:DuelAttack',
            currentDuelId,
            data.attackerZoneIndex,
            data.targetType,
            data.targetZoneIndex
        )
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelDebugSpawnFighter', function(data, cb)
    if currentDuelId and data and data.playerIndex and data.cardId and data.zoneIndex then
        TriggerServerEvent(
            'bstar_cards:server:DuelDebugSpawnFighter',
            currentDuelId,
            data.playerIndex,
            data.cardId,
            data.zoneIndex
        )
    end
    cb({ ok = true })
end)

RegisterCommand('fixduelcam', function()
    TriggerEvent('bstar_cards:client:ExitDuelTableView')
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end, false)

RegisterCommand('closeduelui', function()
    CloseDuelUi()
end, false)

RegisterCommand('duelspawnopp', function(_, args)
    if not currentDuelId then
        QBCore.Functions.Notify('No active duel.', 'error')
        return
    end

    local cardId = args[1] or 'ALPH_LAYLA_HART'
    local zoneIndex = tonumber(args[2]) or 1

    TriggerServerEvent('bstar_cards:server:DuelDebugSpawnFighter', currentDuelId, 2, cardId, zoneIndex)
end, false)

RegisterCommand('duelspawnme', function(_, args)
    if not currentDuelId then
        QBCore.Functions.Notify('No active duel.', 'error')
        return
    end

    local cardId = args[1] or 'ALPH_LAYLA_HART'
    local zoneIndex = tonumber(args[2]) or 1

    TriggerServerEvent('bstar_cards:server:DuelDebugSpawnFighter', currentDuelId, 1, cardId, zoneIndex)
end, false)

CreateThread(function()
    while true do
        Wait(0)

        if duelUiOpen then
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 68, true)
            DisableControlAction(0, 69, true)
            DisableControlAction(0, 70, true)
            DisableControlAction(0, 91, true)
            DisableControlAction(0, 92, true)
            DisableControlAction(0, 106, true)

            if IsControlJustReleased(0, 322) then -- ESC
                CloseDuelUi()
            end
        else
            Wait(250)
        end
    end
end)

RegisterCommand('testduel', function()
    local deckBoxId = CurrentDeckBoxId

    print('[BStar Duel] /testduel fired')
    print('[BStar Duel] CurrentDeckBoxId:', deckBoxId)

    if not deckBoxId then
        QBCore.Functions.Notify('Use a deck box first so I know which one to use.', 'error')
        return
    end

    QBCore.Functions.Notify('Fetching decks for test duel...', 'primary')

    QBCore.Functions.TriggerCallback('bstar_cards:server:GetDecksForTestDuel', function(decks)
        print('[BStar Duel] Callback returned')
        print('[BStar Duel] decks:', json.encode(decks))

        if not decks or #decks < 2 then
            QBCore.Functions.Notify('You need at least 2 saved decks in this deck box for test duel.', 'error')
            return
        end

        local myDeck = decks[1]
        local oppDeck = decks[2]

        print('[BStar Duel] Starting test duel with decks:', myDeck.id, oppDeck.id)
        QBCore.Functions.Notify('Starting test duel...', 'success')

        TriggerServerEvent('bstar_cards:server:StartTestDuel', deckBoxId, myDeck.id, oppDeck.id)
    end, deckBoxId)
end, false)
