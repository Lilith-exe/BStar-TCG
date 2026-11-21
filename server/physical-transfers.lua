-- Physical-copy pocket deposits. Existing move/sleeve journal owns every handoff.
local qb=exports['qb-core']:GetCoreObject()
local store=BStarBulk.storage
local T={}
BStarPhysicalTransfers=T
local purpose='physicalDeposit'
local function uuid(id)
    return type(id)=='string' and #id==36 and id:match('^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$')
end
local function validRequest(r)
    assert(type(r)=='table' and uuid(r.operationId),'Invalid operation ID; refresh pocket controls')
    assert(type(r.copyId)=='string' and #r.copyId>0 and #r.copyId<=80,'Choose an identified physical copy')
    assert(type(r.box)=='string' and #r.box>0 and #r.box<=100,'Choose a Deck Box')
end
local function receipt(id)
    return MySQL.single.await('SELECT * FROM bstar_card_moves WHERE id=?',{id})
end
local function result(row,cid,r,license)
    if not row then return nil end
    local op=json.decode(row.operation)
    if row.citizenid~=cid or op.ownerLicense~=license or op.purpose~=purpose or op.copyId~=r.copyId or op.box~=r.box then
        return {ok=false,state='rejected',operationId=r.operationId,error='Operation ID does not match this transfer'}
    end
    local state=({complete='complete',void='rejected',prepared='pending',review='review'})[row.status] or 'review'
    return {ok=state=='complete',state=state,operationId=row.id,copyId=op.copyId,box=op.box,
        error=state=='rejected' and 'Inventory removal did not complete; the card remains in pockets' or
            (state=='pending' and 'Transfer is retained for recovery. Check its outcome; do not submit again') or
            (state=='review' and 'Transfer requires inspection; its evidence is retained') or nil}
end
local function box(player,id,offline)
    local cid=player.PlayerData.citizenid
    assert(store.carried(player,'deck_box',id),'Carry the destination Deck Box')
    local count=0
    for _,p in pairs(qb.Functions.GetQBPlayers()) do
        for _,item in pairs(p.PlayerData.items or {}) do
            if item.name=='deck_box' and type(item.info)=='table' and item.info.id==id then
                assert(item.amount==1,'Stacked Deck Box identity needs inspection');count=count+1
            end
        end
    end
    assert(count==1,'Duplicate Deck Box identity; no card moved')
    if offline then
        local online={};for _,p in pairs(qb.Functions.GetQBPlayers()) do online[p.PlayerData.citizenid]=true end
        for _,row in ipairs(MySQL.query.await('SELECT citizenid,inventory FROM players WHERE inventory LIKE ? AND citizenid<>?',{'%'..id..'%',cid})) do
            if not online[row.citizenid] then
                for _,item in pairs(json.decode(row.inventory or '[]')) do
                    assert(not(item.name=='deck_box' and type(item.info)=='table' and item.info.id==id),'Duplicate offline Deck Box identity')
                end
            end
        end
    end
    assert(store.carried(player,'deck_box',id),'Deck Box moved; refresh pocket controls')
end
function BStarBulk.validateDepositCommit(player,row,op)
    assert(player and row.citizenid==player.PlayerData.citizenid and op.ownerLicense==player.PlayerData.license,'Deposit character changed')
    assert(#op.changes==1 and not op.changes[1].row.new,'Invalid physical deposit reservation')
    local change=op.changes[1]
    assert(change.row.id==op.copyId and change.row.location=='pocket' and change.row.citizenid==row.citizenid,'Invalid deposit source')
    assert(change.destination.location=='box' and change.destination.container_id==op.box and change.destination.citizenid==row.citizenid,'Invalid deposit destination')
    box(player,op.box,true)
    local reserved=MySQL.single.await('SELECT * FROM bstar_card_copies WHERE id=?',{op.copyId})
    assert(reserved and reserved.location=='sleeving' and reserved.info==change.row.info and
        reserved.citizenid==change.row.citizenid and reserved.container_id==change.row.container_id,'Deposit reservation needs inspection')
    assert(store.carried(player,'deck_box',op.box),'Destination moved during deposit confirmation')
end
local function exactPocket(player,id)
    local token
    for _,item in pairs(store.items(player)) do
        if item.name=='bstar_card' and type(item.info)=='table' and item.info.copyId==id then
            assert(not token and item.amount==1,'Duplicate or stacked physical card identity');token=item
        end
    end
    assert(token,'The physical card is no longer in your pockets')
    local row=BStarSleeves.selectCopy(player,{location='pocket',id=''},{slot=token.slot,copyId=id})
    assert(not row.new and row.location=='pocket' and row.citizenid==player.PlayerData.citizenid,'Card custody is unavailable or belongs elsewhere')
    local info=json.decode(row.info)
    assert(info.copyId==id and info.cardId==row.card_id and token.info.cardId==row.card_id,'Physical card identity mismatch')
    return row,info
end
function T.deposit(src,r)
    local player=qb.Functions.GetPlayer(src)
    if not player then return {ok=false,state='rejected',error='Player unavailable'} end
    local ok,problem=pcall(validRequest,r)
    if not ok then return {ok=false,state='rejected',error=tostring(problem)} end
    -- Read completed receipts before custody: replay remains valid after the card/box moves again.
    local readOK,saved=pcall(receipt,r.operationId)
    if not readOK then return {ok=false,state='uncertain',operationId=r.operationId,error='Cannot confirm transfer ledger. Check outcome before retrying'} end
    local known=result(saved,player.PlayerData.citizenid,r,player.PlayerData.license)
    if known and known.state~='pending' then return known end
    local attempted=false
    local response=store.run(src,function(p,lock)
        assert(p.PlayerData.citizenid==player.PlayerData.citizenid and p.PlayerData.license==player.PlayerData.license,'Character changed before transfer')
        local old=result(receipt(r.operationId),p.PlayerData.citizenid,r,p.PlayerData.license)
        if old then return old end
        assert(BStarSleeves.ready and BStarCardPresentation,'Physical card services unavailable')
        box(p,r.box,true);lock('box:'..p.PlayerData.citizenid..':'..r.box)
        local row,info=exactPocket(p,r.copyId)
        local before=store.compact(store.items(p));local planned=store.copy(store.items(p))
        local item=planned[row.key];assert(item and item.slot==row.slot and item.info.copyId==r.copyId,'Pocket slot changed')
        planned[row.key]=nil
        local now=os.time();if BStarCondition then BStarCondition.settle(info,row,now) end
        BStarConditionRules.mark(info,'box',now)
        local op={kind='sleeve',purpose=purpose,requestId=r.operationId,copyId=r.copyId,box=r.box,ownerLicense=p.PlayerData.license,
            changes={{row=row,info=json.encode(info),destination={location='box',container_id=r.box,citizenid=p.PlayerData.citizenid}}}}
        box(p,r.box,false)
        assert(store.equal(before,store.compact(store.items(p))),'Inventory changed before preparation')
        attempted=true
        store.execute(p,op,function()
            BStarBulk.validateDepositCommit(p,{citizenid=p.PlayerData.citizenid},op)
            assert(store.equal(before,store.compact(store.items(p))),'Inventory changed; deposit retained')
            local actual=store.items(p)[row.key]
            assert(actual and actual.slot==row.slot and actual.amount==1 and actual.info.copyId==r.copyId,'Card slot changed')
            assert(exports['qb-inventory']:RemoveItem(src,'bstar_card',1,row.slot,'bstar-physical-deposit'),'Inventory removal rejected')
        end,planned)
        local confirmed=result(receipt(r.operationId),p.PlayerData.citizenid,r,p.PlayerData.license)
        assert(confirmed and confirmed.state=='complete','Durable deposit confirmation unavailable')
        return confirmed
    end,true,{physicalOnly=true})
    -- A failed SQL acknowledgement can still have committed. Inspect the durable receipt, never regrant.
    local foundOK,found=pcall(receipt,r.operationId)
    if foundOK and found then
        local durable=result(found,player.PlayerData.citizenid,r,player.PlayerData.license)
        if durable then return durable end
    end
    if response.ok or response.state then return response end
    local busy=BStarStorageLocks[player.PlayerData.citizenid]
    return {ok=false,state=busy and 'pending' or (foundOK and not attempted and 'rejected' or 'uncertain'),operationId=r.operationId,error=response.error or 'Transfer outcome unavailable'}
end
function T.status(src,r)
    local p=qb.Functions.GetPlayer(src)
    if not p then return {ok=false,state='uncertain',error='Player unavailable'} end
    local ok,res=pcall(function()
        validRequest(r)
        -- Recovery obeys all existing locks/gates and cannot allocate historical identities.
        store.run(src,function()return {ok=true}end,true,{physicalOnly=true})
        return result(receipt(r.operationId),p.PlayerData.citizenid,r,p.PlayerData.license) or
            {ok=false,state='unknown',operationId=r.operationId,error='No durable receipt yet. Do not repeat an unconfirmed request'}
    end)
    return ok and res or {ok=false,state='uncertain',error=tostring(res),operationId=type(r)=='table' and r.operationId or nil}
end
local function card(row,info,slot)
    local def=assert(DeckBox.ResolveCardDefinition(row.card_id),'Unknown card definition')
    local c={cardId=row.card_id,copyId=row.id,slot=slot,sleeveContext={location=row.location,id=row.container_id}}
    for _,key in ipairs({'name','rarity','type','job','level','attack','defense','health','speed','effectTitle','effectText','setCode','edition','inventoryImage'}) do c[key]=def[key] end
    c.health=DeckBox.GetCardHealthText(def);BStarCardPresentation.apply(c,info);return c
end
function T.list(src,r)
    return store.run(src,function(p)
        assert(BStarSleeves.ready,'Physical sleeve services unavailable')
        assert(type(r)=='table' and type(r.box)=='string' and #r.box>0 and #r.box<=100,'Choose an open Deck Box');box(p,r.box,true)
        local cards,ids,counts={},{},{}
        local excluded=0
        local inventory=store.copy(store.items(p));local before=store.compact(inventory)
        for _,item in pairs(inventory) do
            local id=item.name=='bstar_card' and type(item.info)=='table' and item.info.copyId
            if type(id)=='string' and #id>0 and #id<=80 then
                counts[id]=(counts[id] or 0)+1
                if counts[id]==1 then ids[#ids+1]=id end
            end
        end
        assert(#ids<=1000,'Too many inventory tokens to list safely')
        local rows={}
        if #ids>0 then
            local marks={};for _ in ipairs(ids) do marks[#marks+1]='?' end
            for _,row in ipairs(MySQL.query.await('SELECT * FROM bstar_card_copies WHERE id IN ('..table.concat(marks,',')..')',ids)) do rows[row.id]=row end
        end
        for _,item in pairs(inventory) do
            if item.name=='bstar_card' then
                local id=type(item.info)=='table' and item.info.copyId;local row=id and rows[id]
                local ok,value=pcall(function()
                    assert(item.amount==1 and counts[id]==1 and row and row.location=='pocket' and row.citizenid==p.PlayerData.citizenid,'Unavailable copy')
                    local info=json.decode(row.info)
                    assert(info.copyId==id and info.cardId==row.card_id and item.info.cardId==row.card_id,'Mismatched copy')
                    assert(BStarCardPresentation.matchesInventory(info,item.info,store.equal),'Token needs recovery')
                    return card(row,info,item.slot)
                end)
                if ok then cards[#cards+1]=value else excluded=excluded+1 end
            end
        end
        assert(store.equal(before,store.compact(store.items(p))),'Pocket inventory changed; refresh the list')
        table.sort(cards,function(a,b)return a.copyId<b.copyId end)
        box(p,r.box,false)
        return {ok=true,cards=cards,excluded=excluded,box=r.box}
    end,true,{physicalOnly=true})
end
function T.stock(src,r)
    return store.run(src,function(p)
        assert(type(r)=='table' and type(r.box)=='string' and #r.box>0 and #r.box<=100,'Choose a Deck Box');box(p,r.box,true)
        local owned,boxed={},{}
        local function add(target,id,info,copyId)
            local def,key=DeckBox.ResolveCardDefinition(id);if not def then return end;key=def.id or key
            local entry=target[key] or card({id=copyId,card_id=key,location='box',container_id=r.box},info)
            entry.copyId=nil;entry.slot=nil;entry.amount=(entry.amount or 0)+1;target[key]=entry
            BStarCardPresentation.addVariant(entry,info,1,copyId)
        end
        for _,row in ipairs(MySQL.query.await("SELECT * FROM bstar_card_copies WHERE location='box' AND container_id=? AND citizenid=? ORDER BY id",{r.box,p.PlayerData.citizenid})) do
            local info=json.decode(row.info);add(owned,row.card_id,info,row.id);add(boxed,row.card_id,info,row.id)
        end
        if BStarCollectibles then for _,row in ipairs(BStarCollectibles.binderDeckRows(p)) do add(owned,row.card_id,json.decode(row.info),row.id) end end
        -- Preserve older read-only totals behind the overlay; no legacy item enters its pocket list or transfer.
        for _,row in ipairs(MySQL.query.await('SELECT card_id,amount FROM bstar_deckbox_cards WHERE citizenid=? AND deck_box_id=? AND amount>0',{p.PlayerData.citizenid,r.box})) do
            local amount=tonumber(row.amount) or 0
            for _,target in ipairs({owned,boxed}) do
                local def,key=DeckBox.ResolveCardDefinition(row.card_id)
                key=def and (def.id or key) or row.card_id
                local entry=target[key] or (def and card({card_id=key,location='box',container_id=r.box},{}) or {cardId=key,name=key})
                entry.copyId=nil;entry.amount=(entry.amount or 0)+amount;target[key]=entry;BStarCardPresentation.addVariant(entry,{},amount)
            end
        end
        box(p,r.box,false);return {ok=true,box=r.box,storedCards=owned,boxCards=boxed}
    end,true,{physicalOnly=true})
end
local function publicError(problem)
    local message=tostring(problem)
    local explanations={
        {'Operation ID','Transfer request does not match its recorded operation. Refresh pocket controls.'},
        {'Carry the destination','Carry the destination Deck Box before depositing.'},
        {'Duplicate','Duplicate identity detected. No new transfer can proceed until inspected.'},
        {'Stacked','Stacked identity needs inspection.'},
        {'no longer in your pockets','That physical copy is no longer in your pockets.'},
        {'custody','Card custody is unavailable. Recover the pending operation first.'},
        {'Inventory changed','Inventory changed. Refresh; check any recorded transfer before retrying.'},
        {'Finish your duel','Finish your duel before moving cards.'},
        {'transaction is already running','A card operation is already running. Check its outcome.'},
        {'pending pack','Recover your pending pack before moving cards.'},
        {'inspection','Transfer evidence is retained for inspection. Do not submit again.'},
        {'recovery','Transfer is retained for recovery. Check its outcome; do not submit again.'},
        {'No durable receipt','No durable receipt yet. Wait and check again; do not repeat the transfer.'},
        {'did not complete','Inventory removal did not complete. No card was stored.'},
        {'service','Physical card services are unavailable. Check any pending operation before retrying.'}
    }
    for _,entry in ipairs(explanations) do if message:find(entry[1],1,true) then return entry[2] end end
    return 'Physical card request could not be confirmed. Refresh reads or check the recorded transfer outcome.'
end
for name,fn in pairs({pocketCards=T.list,physicalDeposit=T.deposit,physicalDepositStatus=T.status,physicalBoxStock=T.stock}) do
    qb.Functions.CreateCallback('bstar_cards:server:'..name,function(src,cb,r)
        local ok,res=pcall(fn,src,r)
        if not ok then res={ok=false,state='uncertain',error='Physical card service interrupted; check operation outcome'} end
        if res.error then res.error=publicError(res.error) end
        cb(res)
    end)
end
