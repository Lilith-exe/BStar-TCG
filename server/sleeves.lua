local QBCore = exports['qb-core']:GetCoreObject()
local store, config = BStarBulk.storage, BStarSleeveConfig
local copy, equal, items = store.copy, store.equal, store.items
BStarSleeves = { ready=false, error='Sleeve items are starting.' }
local Sleeves = BStarSleeves
local definitions = {}

local function registeredItems()
    local ok,problem=pcall(function()
        assert(type(config.maxBatch)=='number' and config.maxBatch>=1 and config.maxBatch<=200 and config.maxBatch%1==0,'Sleeve maxBatch must be 1-200')
        assert(type(config.pageSize)=='number' and config.pageSize>=1 and config.pageSize<=100 and config.pageSize%1==0,'Sleeve pageSize must be 1-100')
        assert(type(config.condition)=='table' and type(config.condition.goodMin)=='number' and type(config.condition.playedMin)=='number' and config.condition.goodMin>config.condition.playedMin,'Condition thresholds must be numeric and ordered')
        local core=exports['qb-core']:GetCoreObject()
        local names={}
        for id,t in pairs(config.types) do
            assert(type(id)=='string' and type(t.item)=='string' and not names[t.item],'Sleeve item names must be distinct')
            assert(type(t.label)=='string' and type(t.reusable)=='boolean','Sleeve types need a label and reusable flag')
            assert(t.item:match('^[a-z0-9_]+$'),'Sleeve item names must use lowercase letters, digits and underscores')
            names[t.item]=true
            local definition=core.Shared.Items[t.item]
            if not definition then
                definition={name=t.item,label=t.label,weight=0,type='item',image=t.image or 'bank_card.png',
                    unique=false,useable=false,shouldClose=false,description='Apply to an individual BStar card through its sleeve controls.'}
                local added,reason=QBCore.Functions.AddItem(t.item,definition)
                assert(added,'Sleeve registration failed: '..tostring(reason))
            end
            assert(definition.type=='item' and definition.unique==false and tonumber(definition.weight)==0,
                'Phase 1 sleeve definitions must be weightless, stackable items: '..t.item)
            definitions[id]=copy(definition)
            if t.pack then
                assert(type(t.pack.quantity)=='number' and t.pack.quantity%1==0 and (t.pack.quantity==60 or t.pack.quantity==100),'Sleeve pack quantity must be 60 or 100')
                local name=t.pack.item
                assert(type(name)=='string' and name:match('^[a-z0-9_]+$') and not names[name],'Sleeve pack item names must be distinct')
                names[name]=true
                local packDefinition=core.Shared.Items[name]
                if not packDefinition then
                    packDefinition={name=name,label=t.label..' Pack',weight=0,type='item',image=t.image or 'bank_card.png',unique=false,useable=true,shouldClose=true,description='Contains '..t.pack.quantity..' '..t.label..'s.'}
                    assert(QBCore.Functions.AddItem(name,packDefinition),'Sleeve pack item registration failed')
                end
                assert(packDefinition.type=='item' and packDefinition.unique==false and tonumber(packDefinition.weight)==0 and packDefinition.useable==true,'Sleeve packs must be usable, weightless stackable items')
            end
        end
    end)
    Sleeves.ready=ok;Sleeves.error=ok and nil or tostring(problem)
    if not ok then print('[BStar sleeves] SETUP FAILED: '..tostring(problem)) end
end
registeredItems()

function Sleeves.initialInfo(info)
    if info.sleeve==nil then info.sleeve={version=1,type=false,protectedSeconds=0,applications=0} end
    return info
end

local function requireReady()
    assert(Sleeves.ready,Sleeves.error)
    assert(BStarCardPresentation,'Card presentation is unavailable; no sleeve operation performed')
end
local function context(player, value)
    assert(type(value)=='table','Choose a card location')
    if value.location=='pocket' then return {location='pocket',id=''} end
    assert(type(value.id)=='string' and #value.id<=100,'Invalid container')
    if value.location=='pile' then store.validatePile(player,value.id)
    else
        local item=config.containers[value.location]
        assert(item and store.carried(player,item,value.id),'Carry the selected card container')
    end
    return {location=value.location,id=value.id}
end
local function duplicatePocket(player, id)
    local found,online=0,{}
    for _,p in pairs(QBCore.Functions.GetQBPlayers()) do
        online[p.PlayerData.citizenid]=true
        for _,item in pairs(p.PlayerData.items or {}) do
            if item.name=='bstar_card' and type(item.info)=='table' and item.info.copyId==id then
                assert(item.amount==1,'Stacked card identity needs review');found=found+1
            end
        end
    end
    assert(found==1,'Duplicate card identity; no sleeve changed')
    for _,row in ipairs(MySQL.query.await('SELECT citizenid,inventory FROM players WHERE inventory LIKE ?',{'%'..id..'%'})) do
        if not online[row.citizenid] then
            for _,item in pairs(json.decode(row.inventory or '[]')) do
                assert(not(item.name=='bstar_card' and type(item.info)=='table' and item.info.copyId==id),'Duplicate offline card identity; no sleeve changed')
            end
        end
    end
    assert(items(player),'Player unavailable')
end
local function pocketAt(player,slot)
    for key,item in pairs(items(player)) do
        if item.slot==slot and item.name=='bstar_card' and item.amount==1 and type(item.info)=='table' then return item,key end
    end
    error('Carry this individual card first')
end
local function selectedCopy(player,ctx,selection)
    assert(type(selection)=='table','Invalid card selection')
    if ctx.location=='pocket' then
        local item,key=pocketAt(player,tonumber(selection.slot))
        local id=item.info.copyId
        assert(selection.copyId==id,'Pocket card changed; refresh the list')
        if not id then
            local canonical=item.info.cardId
            if DeckBox.ResolveCardDefinition then
                local definition,resolved=DeckBox.ResolveCardDefinition(canonical)
                assert(definition,'Unknown legacy card');canonical=resolved or canonical
            else assert(Cards[canonical],'Unknown legacy card') end
            id=assert(MySQL.scalar.await('SELECT UUID()'),'Could not create card identity')
            return {id=id,card_id=canonical,info=json.encode(item.info),location='pocket',container_id='',citizenid=player.PlayerData.citizenid,entered_at=os.time(),new=true,key=key,slot=item.slot}
        end
        duplicatePocket(player,id)
        local row=MySQL.single.await('SELECT * FROM bstar_card_copies WHERE id=?',{id})
        assert(row and row.location=='pocket' and (BStarCardPresentation and BStarCardPresentation.matchesInventory(json.decode(row.info),item.info,equal) or (not BStarCardPresentation and equal(json.decode(row.info),item.info))),'Pocket metadata needs recovery; no sleeve changed')
        row.key=key;row.slot=item.slot;return row
    end
    assert(type(selection.copyId)=='string' and #selection.copyId<=80,'Invalid card identity')
    local row=MySQL.single.await('SELECT * FROM bstar_card_copies WHERE id=?',{selection.copyId})
    assert(row and row.location==ctx.location and row.container_id==ctx.id,'Card moved; refresh the list')
    if ctx.location~='pile' then assert(row.citizenid==player.PlayerData.citizenid,'This card belongs to another player') end
    return row
end

-- Existing transfer journal owns item consumption AND per-copy metadata commits.
function Sleeves.prepareQueries(op)
    local queries={}
    for _,change in ipairs(op.changes) do
        local r=change.row
        if r.new then
            queries[#queries+1]={query=[[INSERT INTO bstar_card_copies (id,card_id,info,location,container_id,citizenid,entered_at)
                VALUES (?,?,?,'sleeving',?,?,?)]],values={r.id,r.card_id,r.info,r.container_id,r.citizenid,r.entered_at}}
        else
            queries[#queries+1]={query="UPDATE bstar_card_copies SET location='sleeving' WHERE id=? AND location=? AND info=?",values={r.id,r.location,r.info}}
        end
    end
    return queries
end
function Sleeves.rollbackQueries(op)
    local queries={}
    for _,change in ipairs(op.changes) do
        local r=change.row
        if r.new then queries[#queries+1]={query="DELETE FROM bstar_card_copies WHERE id=? AND location='sleeving'",values={r.id}}
        else queries[#queries+1]={query="UPDATE bstar_card_copies SET location=? WHERE id=? AND location='sleeving'",values={r.location,r.id}} end
    end
    return queries
end
function Sleeves.commitQueries(receipt,op)
    local queries={}
    for _,change in ipairs(op.changes) do
        local r=change.row
        if r.location=='pile' then store.holdPile(receipt.citizenid,r.container_id) end
        local reserved=MySQL.single.await('SELECT * FROM bstar_card_copies WHERE id=?',{r.id})
        assert(reserved and reserved.location=='sleeving' and reserved.card_id==r.card_id and reserved.info==r.info,
            'Sleeve reservation needs recovery review')
        queries[#queries+1]={query="UPDATE bstar_card_copies SET info=?,location=? WHERE id=? AND location='sleeving' AND info=?",
            values={change.info,r.location,r.id,r.info}}
    end
    queries[#queries+1]={query='UPDATE players SET inventory=? WHERE citizenid=?',values={receipt.after_inventory,receipt.citizenid}}
    queries[#queries+1]={query="UPDATE bstar_card_moves SET status='complete' WHERE id=? AND status='prepared'",values={receipt.id}}
    return queries
end

local function consume(planned,name,amount)
    local slots={};for key,item in pairs(planned) do if item.name==name then slots[#slots+1]={key=key,slot=item.slot} end end
    table.sort(slots,function(a,b)return a.slot<b.slot end)
    for _,entry in ipairs(slots) do
        local item=planned[entry.key];local used=math.min(amount,item.amount)
        item.amount=item.amount-used;amount=amount-used
        if item.amount==0 then planned[entry.key]=nil end
        if amount==0 then return end
    end
    error('Not enough sleeves; nothing changed')
end
local function returnItems(player,planned,returns)
    local used,free=exports['qb-inventory']:GetSlots(player.PlayerData.source)
    for typeId,amount in pairs(returns) do
        local t=config.types[typeId];local target
        for _,item in pairs(planned) do if item.name==t.item and equal(item.info or {},{}) then target=item;break end end
        if target then target.amount=target.amount+amount
        else
            local occupied={};for _,item in pairs(planned) do occupied[item.slot]=true end
            local slot;for i=1,used+free do if not occupied[i] then slot=i;break end end
            assert(slot,'Free an inventory slot for the returned sleeves; nothing changed')
            local definition=copy(definitions[typeId]);definition.slot=slot;definition.amount=amount;definition.info={}
            planned[slot]=definition
        end
    end
end
function Sleeves.change(src,request)
    return store.run(src,function(player)
        requireReady()
        assert(type(request)=='table' and (request.action=='apply' or request.action=='replace' or request.action=='remove'),'Invalid sleeve operation')
        assert(type(request.cards)=='table' and #request.cards>0 and #request.cards<=config.maxBatch,'Select 1 to '..config.maxBatch..' individual copies')
        local before=store.compact(items(player))
        local ctx=context(player,request.context)
        local chosen=request.action~='remove' and config.types[request.sleeveType]
        assert(request.action=='remove' or chosen,'Choose a sleeve type')
        local planned,op,seen,returns=copy(items(player)),{kind='sleeve',changes={}}, {},{}
        local now=os.time();local skipped=0
        for _,selection in ipairs(request.cards) do
            local row=selectedCopy(player,ctx,selection)
            local token=ctx.location=='pocket' and ('slot:'..row.slot) or row.id
            assert(not seen[token],'The same copy was selected twice');seen[token]=true
            local info=json.decode(row.info)
            if BStarCondition then BStarCondition.settle(info,row,now) end
            local prior=info.sleeve
            local protected=type(prior)=='table' and tonumber(prior.protectedSeconds) or 0
            protected=protected or 0
            if request.action~='remove' then
                local unsleeved=prior==nil or prior==false or (type(prior)=='table' and prior.version==1 and prior.type==false)
                if not unsleeved then
                    assert(request.action=='replace','This copy already has a sleeve; choose Change Sleeve')
                    assert(type(prior)=='table' and prior.version==1 and type(prior.type)=='string','Unrecognised sleeve; existing metadata retained')
                    local oldType=assert(config.types[prior.type],'Sleeve type no longer configured; metadata retained')
                    assert(type(prior.appliedAt)=='number','Sleeve timestamp needs review')
                    if prior.type==request.sleeveType then skipped=skipped+1;goto selectedDone end
                    protected=protected+math.max(0,now-prior.appliedAt)
                    if oldType.reusable then returns[prior.type]=(returns[prior.type] or 0)+1 end
                end
                info.sleeve={version=1,type=request.sleeveType,appliedAt=now,changedAt=now,protectedSeconds=protected,
                    applications=(type(prior)=='table' and tonumber(prior.applications) or 0)+1}
            else
                assert(type(prior)=='table' and prior.version==1 and type(prior.type)=='string','No recognised sleeve on this copy; existing metadata retained')
                local t=assert(config.types[prior.type],'Sleeve type no longer configured; metadata retained')
                assert(type(prior.appliedAt)=='number','Sleeve timestamp needs review')
                if t.reusable then returns[prior.type]=(returns[prior.type] or 0)+1 end
                info.sleeve={version=1,type=false,changedAt=now,lastRemovedAt=now,
                    protectedSeconds=protected+math.max(0,now-prior.appliedAt),applications=prior.applications or 1}
            end
            info.copyId=row.id
            if BStarConditionRules then BStarConditionRules.mark(info,row.location,now) end
            if ctx.location=='pocket' then planned[row.key].info=BStarCardPresentation and BStarCardPresentation.inventory(info) or copy(info) end
            op.changes[#op.changes+1]={row=row,info=json.encode(info)}
            ::selectedDone::
        end
        assert(#op.changes>0,'Selected cards already use that sleeve; nothing changed')
        if chosen then consume(planned,chosen.item,#op.changes) end
        returnItems(player,planned,returns)
        -- Revalidate carried custody after every database yield, before journalling.
        context(player,ctx)
        assert(equal(before,store.compact(items(player))),'Inventory changed; refresh and retry')
        local result=store.execute(player,op,function()
            for _,change in ipairs(op.changes) do
                local reserved=MySQL.single.await('SELECT * FROM bstar_card_copies WHERE id=?',{change.row.id})
                assert(reserved and reserved.location=='sleeving' and reserved.info==change.row.info,'Card reservation changed')
            end
            assert(equal(before,store.compact(items(player))),'Inventory changed; sleeve receipt retained')
            player.Functions.SetPlayerData('items',planned)
        end,planned)
        result.count=#op.changes;result.skipped=skipped;result.cards={}
        for _,change in ipairs(op.changes) do
            local card={copyId=change.row.id,slot=change.row.slot,cardId=change.row.card_id}
            BStarCardPresentation.apply(card,json.decode(change.info));result.cards[#result.cards+1]=card
        end
        return result
    end)
end
function Sleeves.updateMetadata(player,ctx,selections,transform,duelPermit)
    requireReady()
    local function requireContext()
        -- The only bypass is a server closure proving an already-completed duel's
        -- exact allocation; never accepted from a NUI/network request.
        if duelPermit then assert(type(duelPermit)=='function' and duelPermit(player,ctx,selections),'Invalid duel condition allocation')
        else ctx=context(player,ctx) end
    end
    requireContext()
    local before=store.compact(items(player));local planned=copy(items(player));local op={kind='sleeve',changes={}}
    local seen={}
    for _,selection in ipairs(selections) do
        local row=selectedCopy(player,ctx,selection)
        assert(not seen[row.id],'Duplicate metadata selection');seen[row.id]=true
        local info=json.decode(row.info);info.copyId=row.id
        if transform(info,row) then
            op.changes[#op.changes+1]={row=row,info=json.encode(info)}
            if ctx.location=='pocket' then planned[row.key].info=BStarCardPresentation.inventory(info) end
        end
    end
    if #op.changes==0 then return {ok=true,count=0} end
    requireContext()
    assert(equal(before,store.compact(items(player))),'Inventory changed; metadata retained')
    return store.execute(player,op,function()
        -- Own rows are now reserved at sleeving; validatePile would reject that
        -- intentional reservation. Recheck carried custody without releasing it.
        if duelPermit then requireContext() end
        if ctx.location~='pocket' and not duelPermit then
            assert(store.carried(player,ctx.location=='pile' and BStarBulk.item or config.containers[ctx.location],ctx.id),'Container moved; metadata receipt retained')
        end
        for _,change in ipairs(op.changes) do
            local row=MySQL.single.await('SELECT * FROM bstar_card_copies WHERE id=?',{change.row.id})
            assert(row and row.location=='sleeving' and row.info==change.row.info,'Metadata reservation needs recovery')
        end
        assert(equal(before,store.compact(items(player))),'Inventory changed; metadata receipt retained')
        player.Functions.SetPlayerData('items',planned)
    end,planned)
end

function Sleeves.reconcilePocketPrivacy(player)
    if not BStarCardPresentation then return end
    requireReady()
    local initial=store.compact(items(player));local planned=copy(items(player));local op={kind='sleeve',changes={}}
    for _,item in pairs(items(player)) do
        if item.name=='bstar_card' and item.amount==1 and type(item.info)=='table' and BStarCardPresentation.needsProjection(item.info) then
            local row=selectedCopy(player,{location='pocket',id=''},{slot=item.slot,copyId=item.info.copyId})
            local info=json.decode(row.info);info.copyId=row.id
            planned[row.key].info=BStarCardPresentation.inventory(info)
            op.changes[#op.changes+1]={row=row,info=json.encode(info)}
        end
    end
    if #op.changes>0 then
        assert(equal(initial,store.compact(items(player))),'Inventory changed; refresh before protecting pocket metadata')
        local before=initial
        store.execute(player,op,function()
            assert(equal(before,store.compact(items(player))),'Inventory changed; privacy receipt retained')
            player.Functions.SetPlayerData('items',planned)
        end,planned)
    end
end
QBCore.Functions.CreateCallback('bstar_cards:server:sleeveChange',function(src,cb,request) cb(Sleeves.change(src,request)) end)

QBCore.Functions.CreateCallback('bstar_cards:server:sleeveList',function(src,cb,request)
    cb(store.run(src,function(player)
        requireReady();request=type(request)=='table' and request or {}
        local contexts={{location='pocket',id='',label='Pocket cards'}}
        for _,item in pairs(items(player)) do
            if item.amount==1 and type(item.info)=='table' and type(item.info.id)=='string' then
                if item.name==BStarBulk.item then contexts[#contexts+1]={location='pile',id=item.info.id,label='Pile '..item.info.id:sub(-8)} end
                for location,name in pairs(config.containers) do
                    if item.name==name then contexts[#contexts+1]={location=location,id=item.info.id,label=location..' '..item.info.id:sub(-8)} end
                end
            end
        end
        local ctx=context(player,request.context or contexts[1]);local cards={}
        local page=math.max(1,math.floor(tonumber(request.page) or 1));local total=0
        local wanted
        if request.cardIds then
            assert(type(request.cardIds)=='table' and #request.cardIds>0 and #request.cardIds<=1000,'Invalid browser filter')
            wanted={};for _,id in ipairs(request.cardIds) do assert(type(id)=='string' and Cards[id],'Unknown browser card');wanted[id]=true end
        end
        if request.copyId then assert(type(request.copyId)=='string' and #request.copyId<=80,'Invalid copy selection') end
        local function matches(info)
            local id=BStarCardPresentation.sleeveId(info)
            return not request.sleeveStatus or request.sleeveStatus=='all' or (request.sleeveStatus=='sleeved' and id~=nil) or (request.sleeveStatus=='unsleeved' and id==nil)
        end
        local function pocketIdentity(item)
            local raw=item.info.cardId
            local definition,resolved=DeckBox.ResolveCardDefinition(raw)
            return definition and definition.id or resolved or raw
        end
        if ctx.location=='pocket' then
            local pockets={};for _,item in pairs(items(player)) do if item.name=='bstar_card' and item.amount==1 and type(item.info)=='table' and (not wanted or wanted[pocketIdentity(item)]) and (not request.copyId or item.info.copyId==request.copyId) then
                local info=BStarCardPresentation.pocketInfo(item);if matches(info) then pockets[#pockets+1]=item end
            end end
            table.sort(pockets,function(a,b)return a.slot<b.slot end);total=#pockets
            page=math.min(page,math.max(1,math.ceil(total/config.pageSize)))
            for i=(page-1)*config.pageSize+1,math.min(total,page*config.pageSize) do
                local item=pockets[i];cards[#cards+1]={copyId=item.info.copyId,slot=item.slot,cardId=item.info.cardId,info=BStarCardPresentation and BStarCardPresentation.pocketInfo(item) or copy(item.info)}
            end
        else
            local where='location=? AND container_id=?';local args={ctx.location,ctx.id}
            if ctx.location~='pile' then where=where..' AND citizenid=?';args[#args+1]=player.PlayerData.citizenid end
            if request.copyId then where=where..' AND id=?';args[#args+1]=request.copyId end
            if wanted then
                local marks={};for _,id in ipairs(request.cardIds) do marks[#marks+1]='?';args[#args+1]=id end
                where=where..' AND card_id IN ('..table.concat(marks,',')..')'
            end
            if request.sleeveStatus and request.sleeveStatus~='all' then
                assert(request.sleeveStatus=='sleeved' or request.sleeveStatus=='unsleeved','Invalid sleeve filter')
                local marks={};for id in pairs(config.types) do marks[#marks+1]='?';args[#args+1]=id end
                local active="(COALESCE(JSON_EXTRACT(info,'$.sleeve.version')=1,FALSE) AND COALESCE(JSON_UNQUOTE(JSON_EXTRACT(info,'$.sleeve.type')) IN ("..(#marks>0 and table.concat(marks,',') or "NULL").."),FALSE))"
                where=where..' AND '..(request.sleeveStatus=='unsleeved' and 'NOT ' or '')..active
            end
            total=tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM bstar_card_copies WHERE '..where,args)) or 0
            page=math.min(page,math.max(1,math.ceil(total/config.pageSize)))
            local orderedArgs=copy(args);local ordering='id'
            if wanted then
                local marks={};for _,id in ipairs(request.cardIds) do marks[#marks+1]='?';orderedArgs[#orderedArgs+1]=id end
                ordering='FIELD(card_id,'..table.concat(marks,',')..'),id'
            end
            for _,row in ipairs(MySQL.query.await('SELECT id,card_id,info FROM bstar_card_copies WHERE '..where..' ORDER BY '..ordering..' LIMIT '..config.pageSize..' OFFSET '..((page-1)*config.pageSize),orderedArgs)) do
                cards[#cards+1]={copyId=row.id,cardId=row.card_id,info=json.decode(row.info)}
            end
        end
        context(player,ctx)
        local types={}
        for id,t in pairs(config.types) do
            local count=0;for _,item in pairs(items(player)) do if item.name==t.item then count=count+item.amount end end
            types[#types+1]={id=id,label=t.label,reusable=t.reusable,count=count}
        end
        table.sort(types,function(a,b)return a.id<b.id end)
        for _,card in ipairs(cards) do
            local definition,resolved=DeckBox.ResolveCardDefinition(card.cardId)
            definition=definition or Cards[card.cardId] or {}
            card.cardId=definition.id or resolved or card.cardId
            card.name=definition.name or card.cardId;card.rarity=definition.rarity;card.inventoryImage=definition.inventoryImage
            if BStarCardPresentation then
                BStarCardPresentation.apply(card,card.info)
                card.sleeve=card.sleeveId and {version=1,type=card.sleeveId} or (card.info.sleeve and card.info.sleeve.version~=1 and {legacy=true} or nil)
                card.info=nil
            else card.sleeve=nil;card.info=nil end
        end
        return {ok=true,contexts=contexts,context=ctx,cards=cards,types=types,page=page,pages=math.max(1,math.ceil(total/config.pageSize)),total=total,maxBatch=config.maxBatch}
    end))
end)

-- Pending receipts survive reconnects/restarts. Reconcile online owners only;
-- ambiguous external inventory changes remain review-held, never replay grants.
CreateThread(function()
    while true do
        Wait(30000)
        if BStarBulk.ready and Sleeves.ready then
            local ok,rows=pcall(MySQL.query.await,[[SELECT DISTINCT citizenid FROM bstar_card_moves
                WHERE status='prepared' AND JSON_UNQUOTE(JSON_EXTRACT(operation,'$.kind')) IN ('sleeve','sleevePack')]])
            if not ok then print('[BStar sleeves] Receipt recovery scan failed: '..tostring(rows)) end
            if ok then
                local pending={};for _,row in ipairs(rows) do pending[row.citizenid]=true end
                for _,player in pairs(QBCore.Functions.GetQBPlayers()) do
                    for _,item in pairs(player.PlayerData.items or {}) do
                        if item.name=='bstar_card' and type(item.info)=='table' and BStarCardPresentation.needsProjection(item.info) then pending[player.PlayerData.citizenid]=true;break end
                    end
                    if pending[player.PlayerData.citizenid] then store.run(player.PlayerData.source,function()return {ok=true}end,true) end
                end
            end
        end
    end
end)

QBCore.Functions.CreateCallback('bstar_cards:server:sleeveCatalog',function(src,cb)
    local player=QBCore.Functions.GetPlayer(src)
    cb({ok=Sleeves.ready,types=BStarCardPresentation.catalog(),designs=player and BStarDeckCosmetics.catalog(player.PlayerData.citizenid) or {}})
end)
function Sleeves.redeemPack(src,typeId,slot)
    return store.run(src,function(player)
        requireReady()
        local t=assert(config.types[typeId],'Unknown sleeve type');local pack=assert(t.pack,'No pack configured')
        local before=store.compact(items(player));local planned=copy(items(player));local found
        for key,item in pairs(planned) do
            if item.slot==slot and item.name==pack.item and item.amount>=1 then found=item;found.amount=found.amount-1;if found.amount==0 then planned[key]=nil end;break end
        end
        assert(found,'Sleeve pack moved; nothing changed')
        returnItems(player,planned,{[typeId]=pack.quantity})
        assert(equal(before,store.compact(items(player))),'Inventory changed; retry')
        return store.execute(player,{kind='sleevePack',sleeveType=typeId,quantity=pack.quantity},function()
            assert(equal(before,store.compact(items(player))),'Inventory changed; receipt retained')
            player.Functions.SetPlayerData('items',planned)
        end,planned)
    end)
end
for id,t in pairs(config.types) do
    if t.pack then QBCore.Functions.CreateUseableItem(t.pack.item,function(src,item)
        local result=Sleeves.redeemPack(src,id,item and item.slot)
        TriggerClientEvent('QBCore:Notify',src,result.ok and ('Received '..t.pack.quantity..' '..t.label..'s.') or result.error,result.ok and 'success' or 'error')
    end) end
end
