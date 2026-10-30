-- Development-only, independently callable callbacks. Server owners control
-- tooling access through their existing systems; no permission adapter is provided.
local qb=exports['qb-core']:GetCoreObject()
local Dev=BStarDev
local function items()
    local definitions=exports['qb-core']:GetCoreObject().Shared.Items
    local result={}
    local function add(name,category,kind)
        local def=type(name)=='string' and definitions[name]
        if not def or def.type~='item' then return end
        if kind=='stack' and (def.unique or name=='bstar_card' or name==BStarBulk.item or name=='deck_box' or name==Config.Collectibles.binder.item) then return end
        result[name]={id=name,label=def.label or name,category=category,kind=kind,quantities=kind=='stack' and {1,5,10} or {1}}
    end
    add('deck_box','Storage','box')
    add(Config.Collectibles.binder.item,'Storage','binder')
    add(BStarPackConfig.standardItem,'Card packs','stack')
    for _,t in pairs(BStarSleeveConfig.types) do
        add(t.item,'Protective sleeves','stack')
        if t.pack then add(t.pack.item,'Sleeve packs','stack') end
    end
    -- Physical pile tokens need pack/delivery custody. They are not raw items.
    return result
end
local function data(src)
    local player=qb.Functions.GetPlayer(src)
    assert(player,'Player unavailable')
    local choices,boxes,cards={}, {}, {}
    for _,item in pairs(items()) do choices[#choices+1]=item end
    table.sort(choices,function(a,b)return a.label<b.label end)
    local seen={}
    for _,item in pairs(player.PlayerData.items or {}) do
        if item.name=='deck_box' and item.amount==1 and type(item.info)=='table' and type(item.info.id)=='string' and not seen[item.info.id] then
            seen[item.info.id]=true;boxes[#boxes+1]={id=item.info.id,label='Deck Box '..item.info.id}
        end
    end
    table.sort(boxes,function(a,b)return a.id<b.id end)
    local ids,skipped=Dev.catalogue()
    for _,id in ipairs(ids) do
        local c=Cards[id]
        cards[#cards+1]={id=id,name=c.name,rarity=c.rarity,type=c.type,image=c.inventoryImage}
    end
    return {ok=true,items=choices,boxes=boxes,cards=cards,fillCount=#ids*3,skipped=skipped*3,
        designs=BStarDeckCosmetics.catalog(player.PlayerData.citizenid),binderItem=Config.Collectibles.binder.item}
end
local function action(src,request)
    assert(type(request)=='table' and type(request.action)=='string','Invalid development action')
    local player=assert(qb.Functions.GetPlayer(src),'Player unavailable')
    if request.action=='item' then
        local item=items()[request.item]
        assert(item,'Choose a configured BStar inventory item')
        local q=request.quantity
        assert(q==1 or (item.kind=='stack' and (q==5 or q==10)),'Invalid quantity')
        if item.kind=='box' then return Dev.grantDeckBox(src) end
        if item.kind=='binder' then return Dev.grantBinder(src) end
        return BStarBulk.storage.run(src,function()
            assert(exports['qb-inventory']:AddItem(src,item.id,q,false,{},'bstar-dev-console'),'Inventory rejected the item grant')
            return {ok=true,message=('Granted %d x %s'):format(q,item.label)}
        end)
    elseif request.action=='fill' then
        local ids=Dev.catalogue()
        assert(request.confirm==true and request.expected==#ids*3,'Confirm the current catalogue size before filling')
        return Dev.fillDeckBox(src,request.box)
    elseif request.action=='cards' then
        return Dev.createBoxCopies(src,request.box,request.cardId,request.quantity)
    elseif request.action=='design' then
        assert(type(request.design)=='string' and BStarSleeveConfig.designs[request.design],'Unknown cosmetic deck design')
        BStarDeckCosmetics.grant(player.PlayerData.citizenid,request.design)
        return {ok=true,message='Permanent deck cosmetic unlocked; select and save it in the deck editor.'}
    elseif request.action=='fighter' then
        assert((request.side==1 or request.side==2) and (request.zone==1 or request.zone==2 or request.zone==3),'Choose side 1/2 and zone 1-3')
        assert(type(request.cardId)=='string' and Cards[request.cardId] and Cards[request.cardId].type=='Fighter','Choose a fighter card')
        local duel=type(request.duelId)=='string' and Duel.Active[request.duelId]
        local member=false
        for _,p in pairs(duel and duel.players or {}) do
            if p.source==src and p.citizenid==player.PlayerData.citizenid and p.license==player.PlayerData.license then member=true end
        end
        assert(member,'Join a duel before using the fighter test')
        local ok,err=Duel.DebugSpawnFighter(request.duelId,request.side,request.cardId,request.zone)
        return {ok=ok==true,error=err,message=ok and 'Debug fighter spawned.' or nil}
    end
    error('Unknown development action')
end
local function guarded(fn,src,arg)
    local ok,result=pcall(fn,src,arg)
    if not ok then return {ok=false,error=tostring(result):gsub('^.-:%d+: ','')} end
    return result or {ok=false,error='No development result returned'}
end
qb.Functions.CreateCallback('bstar_cards:server:DEV_consoleData',function(src,cb) cb(guarded(data,src)) end)
-- Short-lived result receipts prevent the same console request being dispatched
-- twice. They are not a durable inventory journal or a permission mechanism.
local receipts,active={},{}
local fields={'action','item','quantity','box','cardId','design','side','zone','duelId','confirm','expected'}
local function fingerprint(request)
    local values={}
    for _,key in ipairs(fields) do values[#values+1]=type(request[key])..':'..tostring(request[key]) end
    return table.concat(values,'\0')
end
local function dispatch(src,request)
    assert(type(request)=='table','Invalid development request')
    local id=request.requestId
    assert(type(id)=='string' and #id>0 and #id<=80 and id:match('^[%w_:%-]+$'),'Refresh the developer console before sending an action')
    local player=assert(qb.Functions.GetPlayer(src),'Player unavailable')
    local cid=player.PlayerData.citizenid
    local now=GetGameTimer()
    for owner,bucket in pairs(receipts) do
        for key,entry in pairs(bucket) do if not entry.pending and now>=entry.expires then bucket[key]=nil end end
        if not next(bucket) then receipts[owner]=nil end
    end
    receipts[cid]=receipts[cid] or {}
    local bucket,signature=receipts[cid],fingerprint(request)
    local previous=bucket[id]
    if previous then
        assert(previous.signature==signature,'Request ID reused for a different action')
        if previous.pending then return {ok=false,requestId=id,unconfirmed=true,error='This request is still running; do not submit it again'} end
        local saved=BStarBulk.storage.copy(previous.result);saved.cached=true;return saved
    end
    if active[cid] then return {ok=false,requestId=id,started=false,code='console_busy',error='A developer action is already awaiting its result; no additional action started'} end
    local count,oldestKey,oldest=0,nil,math.huge
    for key,entry in pairs(bucket) do
        count=count+1
        if not entry.pending and entry.expires<oldest then oldestKey=key;oldest=entry.expires end
    end
    if count>=32 and oldestKey then bucket[oldestKey]=nil end
    local receipt={pending=true,signature=signature}
    bucket[id]=receipt;active[cid]=id
    local result=guarded(action,src,request)
    result.requestId=id
    receipt.result=BStarBulk.storage.copy(result);receipt.expires=GetGameTimer()+120000;receipt.pending=false
    active[cid]=nil
    return result
end
qb.Functions.CreateCallback('bstar_cards:server:DEV_consoleAction',function(src,cb,request)
    local result=guarded(dispatch,src,request)
    if type(request)=='table' and type(request.requestId)=='string' then result.requestId=request.requestId end
    print(('[BStar dev console] source=%s request=%s action=%s ok=%s started=%s binder=%s'):format(src,
        type(request)=='table' and tostring(request.requestId) or 'invalid',type(request)=='table' and tostring(request.action) or 'invalid',
        tostring(result.ok),tostring(result.started),result.ok and tostring(result.id or '') or ''))
    cb(result)
end)
