-- Acknowledged adapters; overlay borrows the already-open Deck Box NUI focus.
local qb=exports['qb-core']:GetCoreObject()
local inFlight={}
for _,name in ipairs({'pocketCards','physicalDeposit','physicalDepositStatus','physicalBoxStock'}) do
    RegisterNUICallback(name,function(data,cb)
        if inFlight[name] then cb({ok=false,state='pending',error='Previous request is still awaiting its response'});return end
        inFlight[name]=true
        qb.Functions.TriggerCallback('bstar_cards:server:'..name,function(result)
            inFlight[name]=nil
            cb(result or {ok=false,state='uncertain',error='No transfer response. Check outcome before retrying'})
        end,data)
    end)
end
