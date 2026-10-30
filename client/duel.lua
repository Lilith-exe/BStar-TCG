local QBCore = exports['qb-core']:GetCoreObject()

local duelUiOpen = false
local currentDuelId = nil
-- Server validates participation; console reads only this client duel context.
BStarDevDuelId = function() return currentDuelId end
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

local function restoreTableView(state)
    if state.tableMode==true and state.tableId and CurrentDuelTableId~=state.tableId then
        TriggerEvent('bstar_cards:client:EnterDuelTableView',state.tableId)
    end
end
local function OpenDuelUi(duelState)
    if not duelState or not duelState.duelId then return end

    restoreTableView(duelState)
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

RegisterNetEvent('bstar_cards:client:OpenCoinFlip', function(data)
    if not data or not data.duelId then return end
    restoreTableView(data)

    currentDuelId = data.duelId
    duelUiOpen = false

    SendNUIMessage({
        action = 'openCoinFlip',
        duelId = data.duelId,
        tableMode = data.tableMode == true,
        tableId = data.tableId,
        canChooseCoin = data.canChooseCoin ~= false,
        soloMode = data.soloMode == true
    })

    ForceDuelFocus()
end)

RegisterNetEvent('bstar_cards:client:CoinFlipResult', function(data)
    SendNUIMessage({
        action = 'coinFlipResult',
        result = data
    })
end)

RegisterNetEvent('bstar_cards:client:BattleEvent', function(data)
    SendNUIMessage({
        action = 'battleEvent',
        data = data
    })
end)

RegisterNetEvent('bstar_cards:client:PendingCardSelection', function(data)
    if data and data.duelId then
        currentDuelId = data.duelId
    end

    SendNUIMessage({
        action = 'pendingCardSelection',
        selection = data and data.selection or nil
    })

    ForceDuelFocus()
end)

RegisterNetEvent('bstar_cards:client:DuelMessageModal', function(data)
    SendNUIMessage({
        action = 'duelMessageModal',
        title = data and data.title or 'Effect',
        text = data and data.text or '',
        confirmText = data and data.confirmText or 'Okay'
    })

    ForceDuelFocus()
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

RegisterNUICallback('duelDiscardCard', function(data, cb)
    if currentDuelId and data and data.handUid then
        TriggerServerEvent('bstar_cards:server:DuelDiscardCard', currentDuelId, data.handUid)
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelSurrender', function(data, cb)
    if currentDuelId then
        TriggerServerEvent('bstar_cards:server:DuelSurrender', currentDuelId)
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelChooseCoin', function(data, cb)
    if currentDuelId and data and data.choice then
        TriggerServerEvent('bstar_cards:server:DuelChooseCoin', currentDuelId, data.choice)
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelChooseTurnOrder', function(data, cb)
    if currentDuelId and data and data.choice then
        TriggerServerEvent('bstar_cards:server:DuelChooseTurnOrder', currentDuelId, data.choice)
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelDrawCard', function(data, cb)
    if currentDuelId then
        TriggerServerEvent('bstar_cards:server:DuelDrawCard', currentDuelId)
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelSummonFighter', function(data, cb)
    if currentDuelId and data and data.handUid and data.zoneIndex then
        TriggerServerEvent('bstar_cards:server:DuelSummonFighter', currentDuelId, data.handUid, data.zoneIndex)
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelPromoteFighter', function(data, cb)
    if currentDuelId and data and data.handUid and (data.tributeZoneIndex or data.tributeZoneIndexes) then
        TriggerServerEvent(
            'bstar_cards:server:DuelPromoteFighter',
            currentDuelId,
            data.handUid,
            data.tributeZoneIndexes or data.tributeZoneIndex
        )
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelPlayNonFighter', function(data, cb)
    if currentDuelId and data and data.handUid then
        TriggerServerEvent(
            'bstar_cards:server:DuelPlayNonFighter',
            currentDuelId,
            data.handUid,
            data.targetKind,
            data.zoneIndex
        )
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelResolvePendingEffect', function(data, cb)
    if currentDuelId and data and data.promptId then
        TriggerServerEvent('bstar_cards:server:DuelResolvePendingEffect', currentDuelId, data.promptId, data.accepted == true, data.response or {})
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelResolvePendingSelection', function(data, cb)
    if currentDuelId and data and data.selectionId then
        TriggerServerEvent('bstar_cards:server:DuelResolvePendingSelection', currentDuelId, data.selectionId, data.selectedUid, data.selectedUids)
    end
    cb({ ok = true })
end)

RegisterNUICallback('duelActivateEffect', function(data, cb)
    if currentDuelId and data and data.sourceUid then
        TriggerServerEvent('bstar_cards:server:DuelActivateEffect', currentDuelId, data.sourceUid)
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
                SendNUIMessage({
                    action = 'requestDuelSurrender'
                })
                ForceDuelFocus()
            end
        else
            Wait(250)
        end
    end
end)
