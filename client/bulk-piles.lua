local QBCore = exports['qb-core']:GetCoreObject()
local active, generation, heartbeat, currentPile = false, 0, 0, nil
local function close(keepFocus)
    active=false; currentPile=nil; generation=generation+1
    if not keepFocus then SetNuiFocus(false,false); SetNuiFocusKeepInput(false) end
    SendNUIMessage({action='bulkClosed'})
end
RegisterNetEvent('bstar_cards:client:bulkRemoved',function(id)
    if active and currentPile==id then close() end
end)
RegisterNetEvent('bstar_cards:client:bulkOpen',function(id)
    if type(id)~='string' then return end
    currentPile=id
    SendNUIMessage({action='forceCloseAll'})
    generation=generation+1; local stamp=generation; active=true; heartbeat=GetGameTimer()
    CreateThread(function() Wait(100); if active and generation==stamp then SetNuiFocus(true,true);SetNuiFocusKeepInput(false) end end)
    SendNUIMessage({action='bulkOpen',id=id,token=stamp})
end)
RegisterNUICallback('bulkPage',function(data,cb)
    if not active then cb({ok=false,error='Pile closed'});return end
    local stamp=generation
    QBCore.Functions.TriggerCallback('bstar_cards:server:bulkPage',function(result)
        if active and generation==stamp and result and result.ok then currentPile=data.id end
        cb(result)
    end,data)
end)
RegisterNUICallback('bulkToBox',function(data,cb)
    QBCore.Functions.TriggerCallback('bstar_cards:server:bulkToBox',cb,data.deckBoxId)
end)
RegisterNUICallback('bulkClose',function(data,cb)
    if active and data.token==generation then close(data.keepFocus==true) end
    cb({ok=true})
end)
RegisterNUICallback('bulkHeartbeat',function(_,cb)
    if not active then cb({ok=false});return end
    heartbeat=GetGameTimer()
    local stamp,id=generation,currentPile
    QBCore.Functions.TriggerCallback('bstar_cards:server:bulkCheck',function(result)
        if active and generation==stamp and currentPile==id and (not result or not result.ok) then close() end
        cb(result or {ok=false})
    end,id)
end)
RegisterNUICallback('bulkCheck',function(data,cb)
    if not active then cb({ok=false});return end
    QBCore.Functions.TriggerCallback('bstar_cards:server:bulkCheck',cb,data.id)
end)
RegisterNUICallback('bulkList',function(_,cb)
    if not active then cb({ok=false});return end
    QBCore.Functions.TriggerCallback('bstar_cards:server:bulkList',cb)
end)
local function openCarriedPile(cb,id)
    QBCore.Functions.TriggerCallback('bstar_cards:server:bulkOpen',function(result)
        result=result or {ok=false,error='No server response'}
        if not result.ok then QBCore.Functions.Notify(result.error,'error') end
        if cb then cb(result) end
    end,id)
end
-- Pending delivery has no inventory token to use. The existing table target
-- offers an explicit claim without changing carried-pile inventory use.
BStarRecovery = BStarRecovery or {}
local claiming, claimRequest = false, 0
function BStarRecovery.isPileBusy() return active or claiming end
function BStarRecovery.claimPendingPile()
    if active or claiming or (BStarRecovery.isPackBusy and BStarRecovery.isPackBusy()) or IsNuiFocused() or CurrentDuelTableId then
        QBCore.Functions.Notify('Close your current interface and finish your duel before collecting a pile.', 'error')
        return
    end
    claiming=true;claimRequest=claimRequest+1;local stamp=claimRequest
    QBCore.Functions.TriggerCallback('bstar_cards:server:bulkClaim',function(response)
        if stamp~=claimRequest then return end
        claiming=false
        if not response or not response.ok then
            QBCore.Functions.Notify(response and response.error or 'No delivery response received.', 'error')
        end
        -- Successful claims already open bulk UI through the server's bulkOpen event.
    end)
    CreateThread(function()
        Wait(15000)
        if claiming and stamp==claimRequest then
            claiming=false;claimRequest=claimRequest+1
            QBCore.Functions.Notify('Delivery is not yet confirmed. Check your inventory before retrying recovery.', 'error')
        end
    end)
end

RegisterNUICallback('bulkOpen',function(data,cb) openCarriedPile(cb,data.id) end)
AddEventHandler('onClientResourceStop',function(name) if name==GetCurrentResourceName() and active then close() end end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload',function()
    claiming=false;claimRequest=claimRequest+1
    if active then close() end
end)
RegisterNetEvent('qb-inventory:client:openInventory',function() if active then close(true) end end)
CreateThread(function()
    while true do
        if active then
            if GetGameTimer()-heartbeat>12000 then close() end
            DisableControlAction(0,37,true);DisablePlayerFiring(PlayerId(),true);Wait(0)
        else Wait(300) end
    end
end)
