local QBCore = exports['qb-core']:GetCoreObject()
local active, opening, request, awaiting = false, nil, 0, false
local heartbeat = 0
local function close(keepFocus)
    request = request + 1
    active = false
    awaiting = false
    if opening then TriggerServerEvent('bstar_cards:server:packClose', opening) end
    opening = nil
    if not keepFocus then SetNuiFocus(false, false); SetNuiFocusKeepInput(false) end
    SendNUIMessage({ action = 'packClosed' })
end
local function pending()
    request = request + 1
    active = true
    awaiting = true
    heartbeat = GetGameTimer()
    SetNuiFocusKeepInput(false)
    -- Inventory close has its own focus callback; take pack focus after that handoff.
    CreateThread(function()
        local generation = request
        Wait(100)
        if active and generation == request then SetNuiFocus(true, true) end
        Wait(14900)
        if active and generation == request and awaiting then
            awaiting = false
            SendNUIMessage({ action = 'packResult', result = { ok = false,
                error = 'The server has not confirmed this opening. Exit and choose Resume interrupted pack at a duel table; do not open another pack to retry.' } })
        end
    end)
    SendNUIMessage({ action = 'packPending' })
end
local function result(data, generation)
    if not active or (generation and generation ~= request) then
        if data and data.id then TriggerServerEvent('bstar_cards:server:packClose', data.id) end
        return
    end
    if data and data.code=='storage_unavailable' then
        close()
        QBCore.Functions.Notify(data.error or 'Card storage is unavailable. No pack has been consumed.', 'error')
        return
    end
    if data and data.ok then opening = data.id end
    awaiting = false
    SendNUIMessage({ action = 'packResult', result = data })
end
-- Explicit table interaction; reuse the same pending/result lifecycle as pack use.
BStarRecovery = BStarRecovery or {}
function BStarRecovery.isPackBusy() return active end
function BStarRecovery.resumePack()
    if active or (BStarRecovery.isPileBusy and BStarRecovery.isPileBusy()) or IsNuiFocused() or CurrentDuelTableId then
        QBCore.Functions.Notify('Close your current interface and finish your duel before resuming a pack.', 'error')
        return
    end
    pending()
    local generation = request
    QBCore.Functions.TriggerCallback('bstar_cards:server:packResume', function(data)
        result(data or {ok=false,error='No recovery response received.'}, generation)
    end)
end

RegisterNetEvent('bstar_cards:client:packPending', pending)
RegisterNetEvent('bstar_cards:client:packResult', function(data) result(data) end)
RegisterNUICallback('packClose', function(data, cb) close(data.keepFocus == true); cb({ ok = true }) end)
RegisterNUICallback('packNotify', function(data, cb)
    if active and type(data)=='table' and type(data.message)=='string' then QBCore.Functions.Notify(data.message:sub(1,500), 'error') end
    cb({ ok = true })
end)
RegisterNUICallback('packHeartbeat', function(_, cb) if active then heartbeat = GetGameTimer() end; cb({ ok = true }) end)
RegisterNUICallback('packNext', function(data, cb)
    if not active or not opening or data.id ~= opening then cb({ ok = false, error = 'Pack session closed.' }); return end
    local generation = request
    QBCore.Functions.TriggerCallback('bstar_cards:server:packNext', function(response)
        if active and request == generation and response and response.ok then opening = response.id
        elseif response and response.id then TriggerServerEvent('bstar_cards:server:packClose', response.id) end
        if active and request==generation and response and response.code=='storage_unavailable' then
            close()
            QBCore.Functions.Notify(response.error or 'Card storage is unavailable. No pack has been consumed.', 'error')
        end
        cb(response or { ok = false, error = 'No server response.' })
    end, opening)
end)
RegisterNUICallback('packViewed', function(data, cb)
    if not active or data.id ~= opening then cb({ ok = false, error = 'Pack session closed.' }); return end
    QBCore.Functions.TriggerCallback('bstar_cards:server:packViewed', cb, opening)
end)
AddEventHandler('onClientResourceStop', function(name) if name == GetCurrentResourceName() and active then close() end end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function() close() end)
-- If another inventory is opened while the presentation is active, release our UI.
RegisterNetEvent('qb-inventory:client:openInventory', function() if active then close(true) end end)
RegisterNetEvent('qb-inventory:client:closeInv', function() if active then close() end end)
RegisterNetEvent('qb-inventory:client:closeInventory', function() if active then close() end end)
CreateThread(function()
    while true do
        if active then
            if GetGameTimer() - heartbeat > 12000 then
                close()
                QBCore.Functions.Notify('Pack interface stopped responding. Choose Resume interrupted pack at a duel table to recover.', 'error')
            end
            DisableControlAction(0, 37, true) -- Do not open weapon wheel / inventory behind the pack.
            DisablePlayerFiring(PlayerId(), true)
            Wait(0)
        else Wait(300) end
    end
end)
