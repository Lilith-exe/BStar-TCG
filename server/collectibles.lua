-- Physical binder custody and temporary, server-authorised grading. All card
-- changes reuse the existing per-copy reservations and move journal.
local qb=exports['qb-core']:GetCoreObject()
local store=BStarBulk.storage
local cfg=Config.Collectibles
BStarCollectibles={ready=false}
local C=BStarCollectibles
local function ready() assert(C.ready,'Collector items are unavailable');assert(BStarBulk.ready,BStarBulk.error) end
local function binder(player,id)
    assert(type(id)=='string' and #id==36 and id:match('^[%x%-]+$'),'Invalid binder')
    local token=store.carried(player,cfg.binder.item,id)
    assert(token and token.info.owner==player.PlayerData.citizenid,'Carry your personal binder')
    local count,online=0,{}
    for _,p in pairs(qb.Functions.GetQBPlayers()) do
        online[p.PlayerData.citizenid]=true
        for _,item in pairs(p.PlayerData.items or {}) do
            if item.name==cfg.binder.item and type(item.info)=='table' and item.info.id==id then count=count+1;assert(item.amount==1,'Stacked binder identity needs review') end
        end
    end
    assert(count==1,'Duplicate binder identity; cards retained')
    for _,row in ipairs(MySQL.query.await('SELECT citizenid,inventory FROM players WHERE inventory LIKE ?',{'%'..id..'%'})) do
        if not online[row.citizenid] then
            for _,item in pairs(json.decode(row.inventory or '[]')) do assert(not(item.name==cfg.binder.item and type(item.info)=='table' and item.info.id==id),'Duplicate offline binder identity; cards retained') end
        end
    end
    assert(store.carried(player,cfg.binder.item,id),'Binder moved; reopen it')
    return token
end
local function sources(player)
    local result={{location='pocket',id='',label='Pocket cards'}}
    for _,item in pairs(store.items(player)) do
        if item.amount==1 and type(item.info)=='table' then
            if item.name=='deck_box' and type(item.info.id)=='string' then result[#result+1]={location='box',id=item.info.id,label='Deck Box '..item.info.id:sub(-6)} end
            if item.name==BStarBulk.item and type(item.info.id)=='string' then result[#result+1]={location='pile',id=item.info.id,label='Bulk Pile '..item.info.id:sub(-6)} end
        end
    end
    return result
end
local function present(row,info)
    local def=DeckBox.ResolveCardDefinition(row.card_id)
    local result={copyId=row.id,cardId=def and def.id or row.card_id,name=def and def.name or row.card_id,
        rarity=def and def.rarity,inventoryImage=def and def.inventoryImage,setCode=def and def.setCode,edition=def and def.edition,amount=1}
    BStarCardPresentation.apply(result,info)
    return result
end
local function rows(player,id)
    local result,occupied={},{}
    for _,row in ipairs(MySQL.query.await("SELECT * FROM bstar_card_copies WHERE location='binder' AND container_id=? AND citizenid=? ORDER BY id",{id,player.PlayerData.citizenid})) do
        local info=json.decode(row.info);local slot=tonumber(info.binderSlot)
        assert(slot and slot%1==0 and slot>=1 and slot<=cfg.binder.pages*cfg.binder.pocketsPerPage and not occupied[slot],'Binder pocket metadata needs review; cards retained')
        occupied[slot]=row;result[#result+1]={row=row,info=info,slot=slot}
    end
    return result,occupied
end
local function station(player)
    assert(cfg.grading.enabled and cfg.grading.testStation,'Test grading is disabled')
    local ped=GetPlayerPed(player.PlayerData.source)
    assert(ped and ped~=0,'Player unavailable')
    local pos=GetEntityCoords(ped);local target=cfg.grading.station.coords
    local distance=(pos.x-target.x)^2+(pos.y-target.y)^2+(pos.z-target.z)^2
    assert(distance<=cfg.grading.station.distance^2,'Stand at the grading bench')
    assert(GetPlayerRoutingBucket(player.PlayerData.source)==0,'The test bench is only in the main world')
end
function C.binderPage(src,request)
    return store.run(src,function(player,lock)
        ready();assert(type(request)=='table','Choose a binder');binder(player,request.id)
        lock('binder:'..request.id)
        BStarCondition.refreshContext(player,{location='binder',id=request.id},false)
        local all=rows(player,request.id);local cards={}
        for _,entry in ipairs(all) do local card=present(entry.row,entry.info);card.binderSlot=entry.slot;cards[#cards+1]=card end
        binder(player,request.id)
        return {ok=true,id=request.id,cards=cards,pages=cfg.binder.pages,pocketsPerPage=cfg.binder.pocketsPerPage,sources=sources(player)}
    end)
end
local function addToPocket(player,planned,row,info)
    local used,free=exports['qb-inventory']:GetSlots(player.PlayerData.source)
    local slot
    for i=1,used+free do if not planned[i] then slot=i;break end end
    assert(slot,'Free an inventory slot before withdrawing this card')
    local definition=assert(qb.Shared.Items.bstar_card,'Card item missing')
    planned[slot]={name='bstar_card',amount=1,slot=slot,type=definition.type,info=BStarCardPresentation.inventory(info)}
end
function C.binderMove(src,request)
    return store.run(src,function(player,lock)
        ready();assert(type(request)=='table' and type(request.source)=='table','Choose an individual card')
        binder(player,request.id);lock('binder:'..request.id)
        local cid=player.PlayerData.citizenid
        local context=BStarSleeves.context(player,request.source)
        local depositing=context.location~='binder' or not request.destination
        assert(context.location~='binder' or context.id==request.id,'Choose this binder')
        assert(context.location=='binder' or context.location=='pocket' or context.location=='box' or context.location=='pile','Unsupported card source')
        if context.location=='box' then lock('box:'..cid..':'..context.id) end
        local row=BStarSleeves.selectCopy(player,context,{copyId=request.copyId,slot=request.sourceSlot})
        local before=store.compact(store.items(player));local planned=store.copy(store.items(player))
        local info=json.decode(row.info);info.copyId=row.id
        BStarCondition.settle(info,row)
        local destination
        local changes={}
        if depositing then
            local pocket=tonumber(request.pocket)
            assert(pocket and pocket%1==0 and pocket>=1 and pocket<=cfg.binder.pages*cfg.binder.pocketsPerPage,'Choose a numbered binder pocket')
            local _,occupied=rows(player,request.id)
            local other=occupied[pocket]
            if other and other.id~=row.id then
                assert(context.location=='binder','That pocket already contains a card')
                local old=assert(tonumber(info.binderSlot),'Missing source pocket')
                local otherInfo=json.decode(other.info);BStarCondition.settle(otherInfo,other);otherInfo.binderSlot=old
                changes[#changes+1]={row=other,info=json.encode(otherInfo)}
            end
            info.binderSlot=pocket;destination={location='binder',container_id=request.id,citizenid=cid}
            if context.location=='pocket' then planned[row.key]=nil end
        else
            assert(request.destination=='pocket' or request.destination=='box','Choose pockets or a Deck Box')
            if request.destination=='box' then
                assert(type(request.box)=='string' and store.carried(player,'deck_box',request.box),'Carry the destination Deck Box')
                lock('box:'..cid..':'..request.box)
            end
            info.binderSlot=nil
            destination={location=request.destination,container_id=request.destination=='box' and request.box or '',citizenid=cid}
            if request.destination=='pocket' then addToPocket(player,planned,row,info) end
        end
        BStarConditionRules.mark(info,destination.location,os.time())
        changes[#changes+1]={row=row,info=json.encode(info),destination=destination}
        binder(player,request.id);BStarSleeves.context(player,context)
        assert(store.equal(before,store.compact(store.items(player))),'Inventory changed; no move prepared')
        local result=store.execute(player,{kind='sleeve',changes=changes},function()
            assert(store.carried(player,cfg.binder.item,request.id),'Binder moved; recover its transfer first')
            if destination.location=='box' then assert(store.carried(player,'deck_box',destination.container_id),'Deck Box moved; recover its transfer first') end
            assert(store.equal(before,store.compact(store.items(player))),'Inventory changed; transfer retained')
            player.Functions.SetPlayerData('items',planned)
        end,planned)
        return result
    end)
end
function C.gradingPage(src)
    return store.run(src,function(player)
        ready();station(player)
        return {ok=true,sources=sources(player),brand=cfg.grading.brand,subtitle=cfg.grading.subtitle,test=true}
    end)
end
function C.grade(src,request)
    return store.run(src,function(player)
        ready();station(player);assert(type(request)=='table','Choose an individual card')
        local ctx=BStarSleeves.context(player,request.context)
        assert(ctx.location=='pocket' or ctx.location=='box','Withdraw this card to pockets or a Deck Box before grading')
        local certificate=assert(MySQL.scalar.await('SELECT UUID()'),'Certificate unavailable')
        local result=BStarSleeves.updateMetadata(player,ctx,{{copyId=request.copyId,slot=request.slot}},function(info,row)
            station(player);assert(not BStarConditionRules.graded(info),'This card is already graded or slabbed')
            BStarCondition.settle(info,row)
            local grade,label=BStarConditionRules.grade(assert(info.condition,'Condition unavailable'))
            info.graded=true;info.slabbed=true;info.grade=grade
            info.slab={version=1,certificate=certificate,grade=grade,label=label,brand=cfg.grading.brand,at=os.time()}
            info.grading={grade=grade,label=label,certificate=certificate,at=os.time(),station=cfg.grading.station.id,condition=info.condition}
            BStarConditionRules.mark(info,row.location,os.time())
            return true
        end,function(p,c)
            station(p);BStarSleeves.context(p,c);return true
        end)
        if result.ok then result.certificate=certificate;result.message='Graded and sealed in a Hardcore slab. Test grading is free.' end
        return result
    end)
end
-- Search/filter the full owned source, before pagination; never sort by exact
-- private condition. Existing sleeve listing retains custody and copy checks.
function C.library(src,request)
    request=type(request)=='table' and request or {}
    local search=tostring(request.search or ''):lower():sub(1,80)
    local wanted,types,rarities,seenTypes,seenRarities={},{},{},{},{}
    local wantedType=tostring(request.cardType or 'all')
    local wantedRarity=tostring(request.rarity or 'all')
    for id,card in pairs(Cards) do
        local kind=tostring(card.type or '');local rarity=tostring(card.rarity or '')
        if kind~='' and not seenTypes[kind] then types[#types+1]=kind;seenTypes[kind]=true end
        if rarity~='' and not seenRarities[rarity] then rarities[#rarities+1]=rarity;seenRarities[rarity]=true end
        local text=(tostring(card.name or '')..' '..id..' '..tostring(card.setCode or '')):lower()
        if (wantedType=='all' or wantedType==kind) and (wantedRarity=='all' or wantedRarity==rarity) and (search=='' or text:find(search,1,true)) then wanted[#wanted+1]=id end
    end
    local rank={TOKEN=0,COMMON=1,RARE=2,SUPER=3,ULTRA=4,SECRET=5,GHOST=6}
    table.sort(wanted,function(a,b)
        local ca,cb=Cards[a],Cards[b]
        if request.sort=='rarity' then local first,second=rank[ca.rarity] or -1,rank[cb.rarity] or -1;if first~=second then return first>second end end
        if request.sort=='number' then return tostring(ca.setCode or a)..a<tostring(cb.setCode or b)..b end
        local first,second=tostring(ca.name or a):lower(),tostring(cb.name or b):lower()
        if first==second then return a<b end
        return request.sort=='name-desc' and first>second or request.sort~='name-desc' and first<second
    end)
    table.sort(types);table.sort(rarities)
    if #wanted==0 then
        return store.run(src,function(player)
            ready();BStarSleeves.context(player,request.context)
            return {ok=true,cards={},page=1,pages=1,total=0,cardTypes=types,rarities=rarities}
        end)
    end
    local result=BStarSleeves.list(src,{context=request.context,cardIds=wanted,sleeveStatus=request.sleeveStatus or 'all',page=request.page,orderByCards=true})
    result.cardTypes=types;result.rarities=rarities
    return result
end
-- Deck eligibility is a read view over carried custody; cards stay in their
-- binder and never appear in the Deck Box's physical withdrawal list.
function C.binderDeckRows(player,lock)
    local rows,seen={},{}
    for _,item in pairs(store.items(player)) do
        if item.name==cfg.binder.item and type(item.info)=='table' and item.info.owner==player.PlayerData.citizenid then
            local id=item.info.id;assert(not seen[id],'Duplicate binder identity');seen[id]=true;binder(player,id)
            if lock then lock('binder:'..id) end
            for _,row in ipairs(MySQL.query.await("SELECT * FROM bstar_card_copies WHERE location='binder' AND container_id=? AND citizenid=? ORDER BY id",{id,player.PlayerData.citizenid})) do rows[#rows+1]=row end
        end
    end
    return rows
end
function DeckBox.GetDeckCards(src,box,cb)
    DeckBox.GetStoredCards(src,box,function(cards)
        local result=store.run(src,function(player)
            ready();assert(store.carried(player,'deck_box',box),'Carry the selected Deck Box')
            for _,row in ipairs(C.binderDeckRows(player)) do
                local def,key=DeckBox.ResolveCardDefinition(row.card_id);assert(def,'Unknown binder card')
                key=def.id or key or row.card_id
                local entry=cards[key]
                if not entry then
                    entry={cardId=key,id=key,amount=0}
                    for _,field in ipairs({'name','rarity','type','job','level','speed','attack','defense','effectTitle','effectText','setCode','edition','inventoryImage','effectTags','continuous'}) do entry[field]=store.copy(def[field]) end
                    entry.health=def.health or def.hp or def.defense or def.def
                end
                local info=json.decode(row.info);local playable=BStarBulk.playableAmounts[entry] or entry.amount or 0
                if BStarConditionRules.playable(info) then playable=playable+1 end
                BStarBulk.playableAmounts[entry]=playable;entry.amount=entry.amount+1
                BStarCardPresentation.addVariant(entry,info,1,row.id);cards[key]=entry
            end
            return {ok=true,cards=cards}
        end,true)
        if not result.ok then TriggerClientEvent('QBCore:Notify',src,result.error,'error') end
        cb(result.ok and result.cards or {})
    end)
end
function C.deckCopies(src,request)
    return store.run(src,function(player)
        ready();assert(type(request)=='table' and type(request.context)=='table' and request.context.location=='box','Choose a Deck Box')
        local box=request.context.id;assert(store.carried(player,'deck_box',box),'Carry the selected Deck Box')
        assert(type(request.cardIds)=='table' and #request.cardIds==1,'Choose one card')
        local def,key=DeckBox.ResolveCardDefinition(request.cardIds[1]);assert(def,'Unknown card');key=def.id or key
        local rows=C.binderDeckRows(player)
        for _,row in ipairs(MySQL.query.await("SELECT id,card_id,info FROM bstar_card_copies WHERE location='box' AND citizenid=? AND container_id=? ORDER BY id",{player.PlayerData.citizenid,box})) do row.location='box';row.container_id=box;rows[#rows+1]=row end
        local cards={};for _,row in ipairs(rows) do
            local cardDef,canonical=DeckBox.ResolveCardDefinition(row.card_id);canonical=cardDef and cardDef.id or canonical
            local info=json.decode(row.info);local protected=BStarCardPresentation.sleeveId(info)~=nil
            if canonical==key and (not request.copyId or request.copyId==row.id) and (request.sleeveStatus==nil or request.sleeveStatus=='all' or (request.sleeveStatus=='sleeved')==protected) then
                local card=present(row,info);card.sleeveContext={location=row.location,id=row.container_id};cards[#cards+1]=card
            end
        end
        table.sort(cards,function(a,b)return a.copyId<b.copyId end)
        local size=BStarSleeveConfig.pageSize;local pages=math.max(1,math.ceil(#cards/size));local page=math.min(pages,math.max(1,math.floor(tonumber(request.page) or 1)));local out={}
        for i=(page-1)*size+1,math.min(#cards,page*size) do out[#out+1]=cards[i] end
        local types={};for id,kind in pairs(BStarSleeveConfig.types) do
            local count=0;for _,item in pairs(store.items(player)) do if item.name==kind.item then count=count+item.amount end end
            types[#types+1]={id=id,label=kind.label,reusable=kind.reusable,count=count}
        end
        table.sort(types,function(a,b)return a.id<b.id end)
        return {ok=true,cards=out,total=#cards,page=page,pages=pages,types=types,maxBatch=1}
    end)
end
for name,fn in pairs({binderPage=C.binderPage,binderMove=C.binderMove,gradingPage=C.gradingPage,gradeCard=C.grade,collectorLibrary=C.library,deckCopies=C.deckCopies}) do
    qb.Functions.CreateCallback('bstar_cards:server:'..name,function(src,cb,data) cb(fn(src,data)) end)
end
local ok,err=pcall(function()
    assert(type(cfg.binder.pages)=='number' and cfg.binder.pages%2==0 and cfg.binder.pages>=2 and cfg.binder.pages<=40 and cfg.binder.pocketsPerPage==9,'Binders require 2-40 even pages with nine pockets each')
    local definition=qb.Shared.Items[cfg.binder.item]
    if not definition then
        assert(qb.Functions.AddItem(cfg.binder.item,{name=cfg.binder.item,label=cfg.binder.label,weight=500,type='item',image='book.png',unique=true,useable=true,shouldClose=true,description='A personal collector binder with individually numbered pockets.'}),'Binder registration failed')
    else assert(definition.unique and definition.useable and definition.type=='item','Binder must be a unique usable item') end
    qb.Functions.CreateUseableItem(cfg.binder.item,function(src,item)
        local result=C.binderPage(src,{id=item.info and item.info.id})
        if result.ok then exports['qb-inventory']:CloseInventory(src);TriggerClientEvent('bstar_cards:client:openBinder',src,result)
        else TriggerClientEvent('QBCore:Notify',src,result.error,'error') end
    end)
end)
C.ready=ok
if not ok then print('[BStar collectibles] SETUP FAILED: '..tostring(err)) end
RegisterCommand('bstargivebinder',function(src,args)
    if src~=0 then return end
    local target=tonumber(args[1]);local player=target and qb.Functions.GetPlayer(target)
    if not player or #args~=1 then print('Usage: bstargivebinder <online player ID>');return end
    local result=store.run(target,function(p)
        ready();local id=assert(MySQL.scalar.await('SELECT UUID()'),'Binder identity unavailable')
        assert(exports['qb-inventory']:AddItem(target,cfg.binder.item,1,false,{id=id,owner=p.PlayerData.citizenid,display=false,image='nui://bstar_cards/html/images/assets/bstar_binder.svg',description=('Personal collector binder • %s pockets'):format(cfg.binder.pages*cfg.binder.pocketsPerPage)},'bstar-test-binder'),'Inventory rejected binder')
        return {ok=true}
    end)
    print('[BStar collectibles] '..(result.ok and 'Test binder granted.' or tostring(result.error)))
end,true)
