local QBCore = exports['qb-core']:GetCoreObject()
for _,name in ipairs({'sleeveList','sleeveChange','sleeveCatalog'}) do
    RegisterNUICallback(name,function(data,cb)
        QBCore.Functions.TriggerCallback('bstar_cards:server:'..name,function(result)
            cb(result or {ok=false,error='No response. Reopen sleeve controls to reconcile before retrying.'})
        end,data)
    end)
end

local function closeSleeves() SendNUIMessage({action='sleeveClosed'}) end
RegisterNetEvent('QBCore:Client:OnPlayerUnload',closeSleeves)
RegisterNetEvent('qb-inventory:client:openInventory',closeSleeves)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded',function() TriggerServerEvent('bstar_cards:server:refreshSleevedDuel') end)
AddEventHandler('onClientResourceStart',function(name)
    if name==GetCurrentResourceName() then TriggerServerEvent('bstar_cards:server:refreshSleevedDuel') end
end)
