local qb=exports['qb-core']:GetCoreObject()
local opened,epoch,restoreFocus=false,0,false
local inFlight=nil
local function close(force,keepFocus)
    if not opened then return end
    opened=false;epoch=epoch+1
    if not keepFocus then
        SetNuiFocus(not force and restoreFocus or false,not force and restoreFocus or false)
        SetNuiFocusKeepInput(false)
    end
    SendNUIMessage({action='DEV_consoleClose'})
end
RegisterCommand('bstardev',function()
    if opened then close(false);return end
    restoreFocus=IsNuiFocused();opened=true;epoch=epoch+1;local stamp=epoch
    SetNuiFocus(true,true);SetNuiFocusKeepInput(false)
    SendNUIMessage({action='DEV_consoleOpen'})
    qb.Functions.TriggerCallback('bstar_cards:server:DEV_consoleData',function(result)
        if opened and stamp==epoch then SendNUIMessage({action='DEV_consoleData',result=result}) end
    end)
end,false)
RegisterNUICallback('DEV_consoleClose',function(_,cb) close(false);cb({ok=true}) end)
RegisterNUICallback('DEV_consoleData',function(_,cb)
    if not opened then cb({ok=false,error='Developer console closed'});return end
    qb.Functions.TriggerCallback('bstar_cards:server:DEV_consoleData',function(result) cb(result or {ok=false,error='No server response'}) end)
end)
RegisterNUICallback('DEV_consoleAction',function(request,cb)
    if not opened or type(request)~='table' then cb({ok=false,error='Developer console closed'});return end
    if inFlight then cb({ok=false,unconfirmed=true,error='An action is still awaiting confirmation; no additional request sent'});return end
    if type(request.requestId)~='string' then cb({ok=false,started=false,error='Refresh the developer console before sending an action'});return end
    if request.action=='fighter' then request.duelId=BStarDevDuelId() end
    local id=request.requestId;inFlight=id
    -- Keep the shared action callback single-flight across close/unload so a
    -- late response cannot be confused with a later action.
    qb.Functions.TriggerCallback('bstar_cards:server:DEV_consoleAction',function(result)
        if result and result.requestId~=id then
            cb({ok=false,unconfirmed=true,error='Action response did not match; inspect the outcome before retrying'})
            return
        end
        inFlight=nil
        cb(result or {ok=false,requestId=id,unconfirmed=true,error='No server response; inspect the outcome before retrying'})
    end,request)
end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload',function() close(true) end)
RegisterNetEvent('qb-inventory:client:openInventory',function() close(true,true) end)
AddEventHandler('onClientResourceStop',function(name) if name==GetCurrentResourceName() then close(true) end end)
