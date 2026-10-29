local qb=exports['qb-core']:GetCoreObject()
local cfg=Config.Collectibles
local opened=false
local epoch=0
local bench
local function close()
    epoch=epoch+1
    if opened then SetNuiFocus(false,false);SetNuiFocusKeepInput(false) end
    opened=false;SendNUIMessage({action='collectorClosed'})
end
for _,name in ipairs({'binderPage','binderMove','gradingPage','gradeCard','collectorLibrary','deckCopies'}) do
    RegisterNUICallback(name,function(data,cb)
        qb.Functions.TriggerCallback('bstar_cards:server:'..name,function(result) cb(result or {ok=false,error='No response. Reopen to recover before retrying.'}) end,data)
    end)
end
RegisterNUICallback('collectorClose',function(_,cb) close();cb({ok=true}) end)
RegisterNetEvent('bstar_cards:client:openBinder',function(result)
    if not result or not result.ok then return end
    epoch=epoch+1;opened=true;SetNuiFocus(true,true);SetNuiFocusKeepInput(false)
    SendNUIMessage({action='openBinder',result=result})
end)
local function openGrading()
    epoch=epoch+1;local stamp=epoch
    qb.Functions.TriggerCallback('bstar_cards:server:gradingPage',function(result)
        if stamp~=epoch then return end
        if not result or not result.ok then qb.Functions.Notify(result and result.error or 'Grading unavailable','error');return end
        opened=true;SetNuiFocus(true,true);SetNuiFocusKeepInput(false);SendNUIMessage({action='openGrading',result=result})
    end,{})
end
RegisterCommand('bstargrade',openGrading,false) -- Server still enforces bench proximity.
CreateThread(function()
    if not cfg.grading.enabled or not cfg.grading.testStation then return end
    local station=cfg.grading.station;local model=joaat(station.model)
    if not IsModelInCdimage(model) or not IsModelValid(model) then print('[BStar grading] Invalid bench model');return end
    RequestModel(model);local deadline=GetGameTimer()+10000
    while not HasModelLoaded(model) and GetGameTimer()<deadline do Wait(50) end
    if not HasModelLoaded(model) then print('[BStar grading] Bench model timed out; /bstargrade still works near the configured bench');return end
    local p=station.coords;bench=CreateObject(model,p.x,p.y,p.z-1.0,false,false,false)
    SetEntityHeading(bench,station.heading);PlaceObjectOnGroundProperly(bench);FreezeEntityPosition(bench,true);SetEntityInvincible(bench,true);SetModelAsNoLongerNeeded(model)
    while GetResourceState('qb-target')~='started' do Wait(1000) end
    exports['qb-target']:AddTargetEntity(bench,{options={{icon='fas fa-certificate',label='Hardcore test grading',action=openGrading}},distance=2.0})
end)
AddEventHandler('onResourceStop',function(name)
    if name~=GetCurrentResourceName() then return end
    close();if bench and DoesEntityExist(bench) then
        if GetResourceState('qb-target')=='started' then exports['qb-target']:RemoveTargetEntity(bench) end
        DeleteEntity(bench)
    end
end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload',close)
RegisterNetEvent('qb-inventory:client:openInventory',close)
RegisterNetEvent('bstar_cards:client:ForceCloseAll',close)
