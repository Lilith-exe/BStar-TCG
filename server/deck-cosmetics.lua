-- Permanent character unlocks, separate from consumable physical protection.
-- Starter designs are free. Future rewards/shops must call grant server-side.
BStarDeckCosmetics = {}
local C = BStarDeckCosmetics
local function key(cid) return 'bstar:deck-designs:'..cid end
function C.unlocked(cid, id)
    local design = BStarSleeveConfig.designs[id]
    if not design then return false end
    if design.starter then return true end
    local ok, saved = pcall(json.decode, GetResourceKvpString(key(cid)) or '{}')
    return ok and type(saved)=='table' and saved[id]==true
end
function C.grant(cid, id)
    assert(type(cid)=='string' and #cid>0 and BStarSleeveConfig.designs[id], 'Unknown character or design')
    local ok, saved = pcall(json.decode, GetResourceKvpString(key(cid)) or '{}')
    assert(ok and type(saved)=='table', 'Design unlock record needs review')
    saved[id]=true
    local encoded=json.encode(saved);SetResourceKvp(key(cid),encoded)
    assert(GetResourceKvpString(key(cid))==encoded,'Design unlock could not be verified')
    return true
end
function C.resolve(cid, id)
    return type(id)=='string' and C.unlocked(cid,id) and id or 'default'
end
function C.catalog(cid)
    local result={}
    for id,design in pairs(BStarSleeveConfig.designs) do
        result[id]={id=id,label=design.label,back=design.back,unlocked=C.unlocked(cid,id)}
    end
    return result
end
-- Operator tooling only: no network event can grant a permanent unlock.
RegisterCommand('bstarunlockdesign',function(src,args)
    if src~=0 then return end
    local target=tonumber(args[1])
    local player=target and exports['qb-core']:GetCoreObject().Functions.GetPlayer(target)
    if not player or not BStarSleeveConfig.designs[args[2]] then
        print('[BStar] Usage: bstarunlockdesign <online player ID> <configured design ID>');return
    end
    local ok,err=pcall(C.grant,player.PlayerData.citizenid,args[2])
    print(ok and '[BStar] Permanent deck design unlocked.' or '[BStar] '..tostring(err))
end,true)
