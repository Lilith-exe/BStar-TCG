local QBCore = exports['qb-core']:GetCoreObject()
BStarStorageLocks = {}
BStarBulk = { item='bstar_bulk_pile', ready=false, status='starting', stage='waiting for database connection',
    error='Card storage is starting. Please try again shortly; no pack has been consumed.' }
local Bulk, containerLocks, epochs = BStarBulk, {}, {}
-- Private validation sidecar: never serialize precise condition or derived copy counts.
Bulk.playableAmounts=setmetatable({}, {__mode='k'})
local function copy(v)
    if type(v) ~= 'table' then return v end
    local result = {}; for k, x in pairs(v) do result[k] = copy(x) end; return result
end
local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function playerItems(player)
    local latest = QBCore.Functions.GetPlayer(player.PlayerData.source)
    assert(latest and latest.PlayerData.citizenid == player.PlayerData.citizenid and
        latest.PlayerData.license == player.PlayerData.license and
        (epochs[player.PlayerData.source] or 0) == player._bulkEpoch, 'Player disconnected')
    return latest.PlayerData.items or {}
end
local function compact(items)
    local result = {}
    for _, item in pairs(items) do result[#result+1] = { name=item.name, amount=item.amount, slot=item.slot, type=item.type, info=copy(item.info or {}) } end
    table.sort(result, function(a,b) return a.slot < b.slot end); return result
end
local function carried(player, name, id)
    for _, item in pairs(playerItems(player)) do
        if item.name == name and type(item.info) == 'table' and item.info.id == id and item.amount == 1 then return item end
    end
end
local heldPiles = {}
local function holdPile(cid,id)
    assert(not containerLocks[id] or containerLocks[id]==cid,'This pile is busy; try again')
    containerLocks[id]=cid; heldPiles[cid]=heldPiles[cid] or {};heldPiles[cid][id]=true
end
function Bulk.releasePiles(cid)
    for id in pairs(heldPiles[cid] or {}) do containerLocks[id]=nil end
    heldPiles[cid]=nil
end
local function validatePile(player,id)
    assert(type(id)=='string' and #id==36 and id:match('^[%x%-]+$') and carried(player,Bulk.item,id),'Carry this pile to access its cards')
    holdPile(player.PlayerData.citizenid,id)
    local counts,online={},{}
    for _,p in pairs(QBCore.Functions.GetQBPlayers()) do
        online[p.PlayerData.citizenid]=true
        for _,item in pairs(p.PlayerData.items or {}) do
            if item.name==Bulk.item and type(item.info)=='table' and item.info.id==id then
                assert(item.amount==1,'Invalid stacked pile token; cards retained for review')
                counts[#counts+1]=p.PlayerData.citizenid
            end
        end
    end
    assert(#counts==1 and counts[1]==player.PlayerData.citizenid,'Duplicate pile ID detected; cards retained for review')
    -- Ignore stale saved snapshots of connected players; their server inventory
    -- is authoritative. Offline duplicates block access instead of guessing an owner.
    for _,row in ipairs(MySQL.query.await('SELECT citizenid,inventory FROM players WHERE inventory LIKE ?',{'%'..id..'%'})) do
        if not online[row.citizenid] then
            for _,item in pairs(json.decode(row.inventory or '[]')) do
                if item.name==Bulk.item and type(item.info)=='table' and item.info.id==id then error('Duplicate offline pile ID; cards retained for review') end
            end
        end
    end
    assert(MySQL.scalar.await('SELECT id FROM bstar_bulk_piles WHERE id=? AND pending_owner IS NULL',{id}),'Pile not delivered or unknown')
    assert(not MySQL.scalar.await("SELECT id FROM bstar_card_copies WHERE location='sleeving' AND container_id=? LIMIT 1",{id}),'A sleeve transaction for this pile needs recovery; cards retained')
    assert(carried(player,Bulk.item,id),'Pile moved; reopen it from inventory')
end
local function cardData(id, info)
    local card, result = Cards[id] or {name=id}, {id=id,cardId=id}
    for _, key in ipairs({'name','rarity','type','job','level','speed','attack','defense','effectTitle','effectText','setCode','edition','inventoryImage','effectTags','continuous'}) do result[key]=copy(card[key]) end
    if BStarCardPresentation then BStarCardPresentation.apply(result,info) end
    result.health=card.health or card.hp or card.defense or card.def
    return result
end
function Bulk.pileInfo(id, count)
    return { id=id, count=count, display=false, image='nui://bstar_cards/html/images/assets/bstar_bulk_pile.png',
        description=('Contains %s cards'):format(tostring(count):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,','')) }
end
local function countPile(id)
    return tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM bstar_card_copies WHERE location IN ('pile','sleeving') AND container_id=?", {id})) or 0
end
function Bulk.refresh(player)
    local counts = {}
    for _, item in pairs(playerItems(player)) do
        if item.name == Bulk.item and type(item.info) == 'table' and item.info.id then counts[item.info.id] = countPile(item.info.id) end
    end
    local inventory = copy(playerItems(player))
    for _, item in pairs(inventory) do
        if item.name == Bulk.item and type(item.info) == 'table' and counts[item.info.id] then
            item.info = Bulk.pileInfo(item.info.id, counts[item.info.id])
        end
    end
    player.Functions.SetPlayerData('items', inventory)
    return inventory
end

-- Called under the pack mutex. Pending piles remain claimable if every pocket
-- slot is occupied by a stack; no six-item capacity requirement is needed.
function Bulk.plan(player, openingId, planned, maxSlots)
    player={PlayerData=player.PlayerData,Functions=player.Functions,_bulkEpoch=epochs[player.PlayerData.source] or 0}
    local pile
    for _, item in pairs(planned) do
        if item.name == Bulk.item and type(item.info) == 'table' and item.info.id and item.amount == 1 then
            if countPile(item.info.id)>0 and MySQL.scalar.await('SELECT id FROM bstar_bulk_piles WHERE id=? AND pending_owner IS NULL', {item.info.id}) then validatePile(player,item.info.id);pile=item; break end
        end
    end
    local pending
    if not pile then pending = MySQL.scalar.await('SELECT id FROM bstar_bulk_piles WHERE pending_owner=? ORDER BY created_at,id LIMIT 1', {player.PlayerData.citizenid}) end
    local id = pile and pile.info.id or pending or openingId
    local count = (pile or pending) and countPile(id) or 0
    local slot = pile and pile.slot
    if not slot then
        local used = {}; for _, item in pairs(planned) do used[item.slot]=true end
        for candidate=1,maxSlots do if not used[candidate] then slot=candidate; break end end
    end
    if slot then planned[slot] = { name=Bulk.item, type='item', amount=1, slot=slot, info=Bulk.pileInfo(id,count+6) } end
    return { mode='physical', id=id, new=not pile and not pending, pending=slot == nil, delivery=pending ~= nil and slot ~= nil, slot=slot }
end
function Bulk.packQueries(row)
    local roll = json.decode(row.rewards)
    if not roll.storage then return {} end -- Legacy pocket-grant recovery stays intact.
    assert(roll.storage.mode~='personal','Personal rewards require an approved migration; no copies were changed')
    local storage, queries = roll.storage, {}
    if storage.new then
        queries[#queries+1] = {query='INSERT IGNORE INTO bstar_bulk_piles (id,pending_owner) VALUES (?,NULLIF(?,\'\'))',
            values={storage.id, storage.pending and row.citizenid or ''}}
    elseif storage.delivery then
        queries[#queries+1] = {query='UPDATE bstar_bulk_piles SET pending_owner=NULL WHERE id=? AND pending_owner=?', values={storage.id,row.citizenid}}
    end
    for i, reward in ipairs(roll.rewards) do
        queries[#queries+1] = {query=[[INSERT IGNORE INTO bstar_card_copies (id,card_id,info,location,container_id,citizenid,entered_at)
            VALUES (?,?,?,'pile',?,'',?)]], values={row.id..':'..i,reward.cardId,json.encode(reward.info),storage.id,reward.info.pileEnteredAt}}
    end
    return queries
end

local function moveQueries(row)
    local op, queries = json.decode(row.operation), {}
    if op.kind=='sleeve' then return BStarSleeves.commitQueries(row,op) end
    if op.kind == 'retire' then
        holdPile(row.citizenid,op.pile)
        assert(countPile(op.pile)==0,'Cleanup receipt needs review: pile contains cards')
    end
    if op.kind == 'delivery' then
        queries[1] = {query='UPDATE bstar_bulk_piles SET pending_owner=NULL WHERE id=? AND pending_owner=?', values={op.pile,row.citizenid}}
    elseif op.kind ~= 'retire' and op.kind ~= 'sleevePack' then
        queries[1] = {query=[[INSERT INTO bstar_card_copies (id,card_id,info,location,container_id,citizenid,entered_at)
            VALUES (?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE info=VALUES(info),location=VALUES(location),container_id=VALUES(container_id),citizenid=VALUES(citizenid),entered_at=VALUES(entered_at)]],
            values={op.copyId,op.cardId,json.encode(op.info),op.kind == 'store' and 'box' or 'pocket',op.box,
                row.citizenid,os.time()}}
    end
    queries[#queries+1] = {query='UPDATE players SET inventory=? WHERE citizenid=?',values={row.after_inventory,row.citizenid}}
    queries[#queries+1] = {query="UPDATE bstar_card_moves SET status='complete' WHERE id=? AND status='prepared'",values={row.id}}
    return queries
end
local function voidMove(row)
    local op, queries=json.decode(row.operation),{}
    if op.kind=='sleeve' then queries=BStarSleeves.rollbackQueries(op) end
    if op.kind=='withdraw' then
        queries[#queries+1]={query="UPDATE bstar_card_copies SET location='box' WHERE id=? AND location='reserved'",values={op.copyId}}
    end
    queries[#queries+1]={query="UPDATE bstar_card_moves SET status='void' WHERE id=? AND status='prepared'",values={row.id}}
    assert(MySQL.transaction.await(queries),'Could not release prepared transfer')
end
local function recoverMoves(player)
    local cid = player.PlayerData.citizenid
    for _, row in ipairs(MySQL.query.await("SELECT * FROM bstar_card_moves WHERE citizenid=? AND status IN ('prepared','review') ORDER BY created_at,id",{cid})) do
        assert(row.status ~= 'review', 'A card transfer requires recovery review: '..row.id)
        local inventory = compact(playerItems(player))
        if equal(inventory,json.decode(row.after_inventory)) then
            local queries=moveQueries(row)
            assert(equal(inventory,compact(playerItems(player))),'Inventory changed during recovery; journal retained')
            assert(MySQL.transaction.await(queries), 'Transfer recovery failed')
        elseif equal(inventory,json.decode(row.before_inventory)) then
            local saved = MySQL.scalar.await('SELECT inventory FROM players WHERE citizenid=?',{cid})
            assert(equal(inventory,compact(playerItems(player))) and
                (equal(json.decode(saved or '[]'),json.decode(row.db_before_inventory)) or equal(json.decode(saved or '[]'),inventory)), 'Transfer inventory needs review')
            voidMove(row)
        else
            MySQL.update.await("UPDATE bstar_card_moves SET status='review' WHERE id=?",{row.id})
            error('Card transfer retained for review: '..row.id)
        end
    end
end
function Bulk.recoverMoves(player)
    recoverMoves({PlayerData=player.PlayerData,Functions=player.Functions,_bulkEpoch=epochs[player.PlayerData.source] or 0})
end
local reconcileEmpty
local function run(src, fn, quiet)
    if not Bulk.ready then return {ok=false,error=Bulk.error} end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return {ok=false,error='Player unavailable.'} end
    player={PlayerData=player.PlayerData,Functions=player.Functions,_bulkEpoch=epochs[src] or 0}
    local cid = player.PlayerData.citizenid
    if BStarStorageLocks[cid] then return {ok=false,error='A card transaction is already running.'} end
    BStarStorageLocks[cid] = true
    local held = {}
    local function lock(id)
        if id:sub(1,5)=='pile:' then holdPile(cid,id:sub(6));return end
        assert(not containerLocks[id], 'This container is busy; try again')
        containerLocks[id]=true; held[#held+1]=id
    end
    local ok, result = pcall(function()
        for _, duel in pairs(Duel and Duel.Active or {}) do
            if duel.status ~= 'finished' then for _, member in pairs(duel.players or {}) do assert(member.citizenid ~= cid, 'Finish your duel before moving cards') end end
        end
        recoverMoves(player)
        if BStarCondition then assert(not BStarCondition.pending(cid),'Completed duel condition is waiting to save; try again after recovery') end
        assert(not MySQL.scalar.await("SELECT id FROM bstar_pack_openings WHERE citizenid=? AND status IN ('prepared','review') LIMIT 1",{cid}), 'Recover your pending pack with /bstarpacks first')
        if BStarSleeves and BStarSleeves.reconcilePocketPrivacy then BStarSleeves.reconcilePocketPrivacy(player) end
        if BStarCondition then BStarCondition.refresh(player) end
        if reconcileEmpty(player) then
            recoverMoves(player) -- settle a cleanup receipt before any further mutation
        end
        return fn(player,lock)
    end)
    for _, id in ipairs(held) do containerLocks[id]=nil end
    Bulk.releasePiles(cid)
    BStarStorageLocks[cid]=nil
    if not ok then
        if not quiet then print('[BStar bulk] '..cid..': '..tostring(result)) end
        return {ok=false,error=tostring(result):gsub('^.-:%d+: ','')}
    end
    return result
end
local function executeMove(player, op, mutate, planned)
    local before, original = compact(playerItems(player)), copy(playerItems(player))
    local db = MySQL.single.await('SELECT UUID() AS id, inventory FROM players WHERE citizenid=?',{player.PlayerData.citizenid})
    assert(db and equal(before,compact(playerItems(player))), 'Inventory changed; try again')
    local row={id=db.id,citizenid=player.PlayerData.citizenid,operation=json.encode(op),before_inventory=json.encode(before),
        after_inventory=json.encode(compact(planned)),db_before_inventory=db.inventory or '[]'}
    local preparation={{query=[[INSERT INTO bstar_card_moves (id,citizenid,operation,before_inventory,after_inventory,db_before_inventory)
        VALUES (?,?,?,?,?,?)]],values={row.id,row.citizenid,row.operation,row.before_inventory,row.after_inventory,row.db_before_inventory}}}
    if op.kind=='withdraw' then
        -- A prepared withdrawal must no longer count as a playable box copy.
        preparation[#preparation+1]={query="UPDATE bstar_card_copies SET location='reserved' WHERE id=? AND location='box'",values={op.copyId}}
    end
    if op.kind=='sleeve' then
        for _,query in ipairs(BStarSleeves.prepareQueries(op)) do preparation[#preparation+1]=query end
    end
    assert(MySQL.transaction.await(preparation),'Could not prepare transfer')
    if not equal(before,compact(playerItems(player))) then
        voidMove(row); error('Inventory changed; try again')
    end
    local ok=pcall(mutate)
    if not ok then
        if op.kind=='retire' or op.kind=='sleeve' or op.kind=='sleevePack' then
            -- Do not restore a whole snapshot over an external slot move. An
            -- unchanged rejection can be voided; anything ambiguous stays journalled.
            if equal(before,compact(playerItems(player))) then voidMove(row) end
            error((op.kind=='sleeve' or op.kind=='sleevePack') and 'Sleeve operation interrupted; reopen sleeve controls to recover before retrying' or 'Empty pile removal deferred; inventory evidence retained')
        end
        player.Functions.SetPlayerData('items',original)
        voidMove(row); error('Inventory rejected transfer; original inventory restored')
    end
    assert(equal(compact(playerItems(player)),compact(planned)), 'Unexpected inventory change; transfer journal retained')
    local queries=moveQueries(row)
    assert(equal(compact(playerItems(player)),compact(planned)),'Inventory changed during commit checks; transfer journal retained')
    assert(MySQL.transaction.await(queries), 'Transfer interrupted; retry to recover before moving more cards')
    if not equal(compact(playerItems(player)),compact(planned)) then
        MySQL.update.await("UPDATE bstar_card_moves SET status='review' WHERE id=?",{row.id})
        error('Concurrent inventory change; transfer retained for review')
    end
    return {ok=true}
end


-- Empty database rows are durable reconciliation evidence, not reusable tokens.
-- Never edit offline inventories or search a stash/drop by item name. Once its
-- exact UUID is carried again, the same checks and journal handle it here.
reconcileEmpty = function(player)
    local ids = {}
    for _, item in pairs(playerItems(player)) do
        if item.name==Bulk.item and type(item.info)=='table' and type(item.info.id)=='string' then ids[item.info.id]=true end
    end
    local pending = false
    for id in pairs(ids) do
        if countPile(id)==0 then
            local ok, err = pcall(function()
                validatePile(player,id) -- locks UUID; unknown/pending/duplicate tokens fail closed
                -- A prepared pack can still persist cards into this UUID. Do not
                -- retire its token while any owner's opening remains unresolved.
                for _, row in ipairs(MySQL.query.await("SELECT rewards FROM bstar_pack_openings WHERE status IN ('prepared','review') AND rewards LIKE ?", {'%'..id..'%'})) do
                    local storage=json.decode(row.rewards).storage
                    assert(not storage or storage.id~=id,'Pile has an unresolved pack opening')
                end
                assert(countPile(id)==0,'Pile contains cards')
                local actual=assert(carried(player,Bulk.item,id),'Pile moved')
                local slot, planned=actual.slot,copy(playerItems(player))
                for key,item in pairs(planned) do if item.slot==slot then planned[key]=nil end end
                executeMove(player,{kind='retire',pile=id},function()
                    -- executeMove yields while preparing its durable receipt.
                    -- Check the live slot and cards again immediately before removal.
                    assert(countPile(id)==0,'Pile contains cards')
                    local current=assert(carried(player,Bulk.item,id),'Pile moved')
                    assert(current.slot==slot and equal(current.info,actual.info),'Pile slot changed')
                    assert(exports['qb-inventory']:RemoveItem(player.PlayerData.source,Bulk.item,1,slot,'bstar-empty-pile'), 'Empty pile removal rejected')
                end,planned)
                TriggerClientEvent('bstar_cards:client:bulkRemoved',player.PlayerData.source,id)
            end)
            if not ok then
                pending=true
                -- Keep evidence and retry through the move journal next time;
                -- never undo an already committed card transfer or grant a token.
                print('[BStar bulk] Empty pile cleanup deferred '..id..': '..tostring(err))
                break -- recover any prepared receipt before another inventory change
            end
        end
    end
    if not pending then
        local inventory,changed=copy(playerItems(player)),false
        for _,item in pairs(inventory) do
            if item.name==Bulk.item and type(item.info)=='table' and item.info.image~='nui://bstar_cards/html/images/assets/bstar_bulk_pile.png' then
                item.info.image='nui://bstar_cards/html/images/assets/bstar_bulk_pile.png';changed=true
            end
        end
        if changed then player.Functions.SetPlayerData('items',inventory) end
    end
    return pending
end

-- Includes reconnects, restored saved tokens and stash/drop pickups. Only online
-- carried inventories are accessible here; inaccessible custody is left intact.
CreateThread(function()
    while true do
        Wait(30000)
        if Bulk.ready then
            for src,player in pairs(QBCore.Functions.GetQBPlayers()) do
                if not BStarStorageLocks[player.PlayerData.citizenid] then
                    for _,item in pairs(player.PlayerData.items or {}) do
                        if item.name==Bulk.item then
                            run(tonumber(src) or player.PlayerData.source,function() return {ok=true} end,true)
                            break
                        end
                    end
                end
            end
        end
    end
end)

Bulk.storage={run=run,items=playerItems,copy=copy,equal=equal,compact=compact,carried=carried,validatePile=validatePile,execute=executeMove,holdPile=holdPile}

local oldStored, oldWithdraw, oldStore = DeckBox.GetStoredCards, DeckBox.WithdrawCard, DeckBox.StoreCard
DeckBox.GetStoredCards = function(src, box, cb)
    oldStored(src,box,function(cards)
        if not Bulk.ready then cb(cards); return end
        local player=QBCore.Functions.GetPlayer(src); if not player then cb({}); return end
        MySQL.query("SELECT card_id,info FROM bstar_card_copies WHERE location='box' AND citizenid=? AND container_id=? ORDER BY id",{player.PlayerData.citizenid,box},function(rows)
            for _,entry in pairs(cards) do
                Bulk.playableAmounts[entry]=tonumber(entry.amount) or 0
                if BStarCardPresentation then BStarCardPresentation.addVariant(entry,{},entry.amount or 0) end
            end
            for _, row in ipairs(rows or {}) do
                local entry=cards[row.card_id] or cardData(row.card_id)
                local info=json.decode(row.info)
                local playable=Bulk.playableAmounts[entry] or (entry.amount or 0)
                if not BStarConditionRules or BStarConditionRules.playable(info) then playable=playable+1 end
                Bulk.playableAmounts[entry]=playable
                entry.amount=(entry.amount or 0)+1; cards[row.card_id]=entry
                if BStarCardPresentation then BStarCardPresentation.addVariant(entry,info,1,row.id) end
                entry.sleeveContext={location='box',id=box}
            end
            cb(cards)
        end)
    end)
end
DeckBox.WithdrawCard = function(src, box, cardId, cb,selection)
    if not Bulk.ready then
        -- The established path can access only legacy aggregate rows, never overlay copies.
        oldWithdraw(src,box,cardId,cb); return
    end
    local result=run(src,function(player,lock)
        assert(type(box)=='string' and carried(player,'deck_box',box), 'Carry the selected Deck Box first')
        assert(type(cardId)=='string' and Cards[cardId], 'Unknown card')
        lock('box:'..player.PlayerData.citizenid..':'..box)
        if selection=='legacy' then return {legacy=true} end
        assert(selection==nil or (type(selection)=='string' and #selection<=80),'Invalid card selection')
        local query="SELECT * FROM bstar_card_copies WHERE location='box' AND citizenid=? AND container_id=? AND card_id=?"
        local args={player.PlayerData.citizenid,box,cardId}
        if selection then query=query..' AND id=?';args[#args+1]=selection end
        local row=MySQL.single.await(query..' ORDER BY id LIMIT 1',args)
        assert(not selection or row,'Selected card moved; refresh the box')
        if not row then return {legacy=true} end
        local info=json.decode(row.info); info.copyId=row.id
        if BStarCondition then BStarCondition.settle(info,row);BStarConditionRules.mark(info,'pocket',os.time()) end
        assert(BStarCardPresentation,'Card presentation is unavailable; no withdrawal performed')
        local pocketInfo=BStarCardPresentation.inventory(info)
        local planned=copy(playerItems(player)); local used,free=exports['qb-inventory']:GetSlots(src)
        local slot; for i=1,used+free do if not planned[i] then slot=i; break end end
        assert(slot,'Inventory full')
        planned[slot]={name='bstar_card',type='item',amount=1,slot=slot,info=pocketInfo}
        return executeMove(player,{kind='withdraw',copyId=row.id,cardId=cardId,info=info,box=box},function()
            assert(exports['qb-inventory']:AddItem(src,'bstar_card',1,slot,pocketInfo,'bstar-bulk-withdraw'))
        end,planned)
    end)
    if result.legacy then oldWithdraw(src,box,cardId,cb) else cb(result.ok,result.error) end
end
DeckBox.StoreCard = function(src,box,cardId,cb)
    -- Legacy cards without per-copy metadata retain their established path.
    local player=QBCore.Functions.GetPlayer(src); local target
    for _,item in pairs(player and player.PlayerData.items or {}) do
        if item.name=='bstar_card' and type(item.info)=='table' then
            local def=DeckBox.ResolveCardDefinition and DeckBox.ResolveCardDefinition(item.info.cardId)
            if item.info.cardId==cardId or (def and def.id==cardId) then target=item;break end
        end
    end
    if not target or not target.info.copyId then oldStore(src,box,cardId,cb); return end
    local result=run(src,function(p,lock)
        assert(type(box)=='string' and carried(p,'deck_box',box), 'Carry the selected Deck Box first')
        lock('box:'..p.PlayerData.citizenid..':'..box)
        local row=MySQL.single.await("SELECT * FROM bstar_card_copies WHERE id=? AND location='pocket'",{target.info.copyId})
        assert(row,'This card copy is not available in pockets')
        local privateInfo=json.decode(row.info)
        assert(not BStarCardPresentation or BStarCardPresentation.matchesInventory(privateInfo,target.info,equal),'Card metadata needs recovery')
        if BStarCondition then BStarCondition.settle(privateInfo,row);BStarConditionRules.mark(privateInfo,'box',os.time()) end
        local planned=copy(playerItems(p)); local actual=planned[target.slot]
        assert(actual and equal(actual.info,target.info) and actual.name=='bstar_card' and actual.amount==1,'Card moved')
        planned[target.slot]=nil
        return executeMove(p,{kind='store',copyId=target.info.copyId,cardId=cardId,info=privateInfo,box=box},function()
            assert(exports['qb-inventory']:RemoveItem(src,'bstar_card',1,target.slot,'bstar-bulk-store'))
        end,planned)
    end)
    cb(result.ok,result.error)
end

QBCore.Functions.CreateCallback('bstar_cards:server:bulkPage',function(src,cb,data)
    cb(run(src,function(player)
        assert(type(data)=='table','Invalid pile request')
        validatePile(player,data.id)
        local ids={}; local search=tostring(data.search or ''):lower():sub(1,80)
        for id,card in pairs(Cards) do
            if (data.rarity==nil or data.rarity=='' or card.rarity==data.rarity) and
                (search=='' or card.name:lower():find(search,1,true) or id:lower():find(search,1,true)) then ids[#ids+1]=id end
        end
        local total=countPile(data.id)
        if #ids==0 then return {ok=true,cards={},total=total,matched=0,page=1,pages=1} end
        table.sort(ids,function(a,b)
            if data.sort=='rarity' and Cards[a].rarity~=Cards[b].rarity then return Cards[a].rarity<Cards[b].rarity end
            return Cards[a].name==Cards[b].name and a<b or Cards[a].name<Cards[b].name
        end)
        local marks={}; local args={data.id}; for _,id in ipairs(ids) do marks[#marks+1]='?';args[#args+1]=id end
        local where="location='pile' AND container_id=? AND card_id IN ("..table.concat(marks,',')..')'
        local matched=tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM bstar_card_copies WHERE '..where,args)) or 0
        local pages=math.max(1,math.ceil(matched/48)); local page=math.max(1,math.min(pages,math.floor(tonumber(data.page) or 1)))
        local ordered=copy(args); for _,id in ipairs(ids) do ordered[#ordered+1]=id end
        local rows=MySQL.query.await('SELECT * FROM bstar_card_copies WHERE '..where..' ORDER BY FIELD(card_id,'..table.concat(marks,',')..'),id LIMIT 48 OFFSET '..((page-1)*48),ordered)
        assert(carried(player,Bulk.item,data.id),'Pile moved; reopen it from inventory')
        local cards={}; for _,row in ipairs(rows) do local card=cardData(row.card_id,json.decode(row.info));card.copyId=row.id;card.sleeveContext={location='pile',id=data.id};cards[#cards+1]=card end
        return {ok=true,cards=cards,total=total,matched=matched,page=page,pages=pages}
    end))
end)
QBCore.Functions.CreateCallback('bstar_cards:server:bulkToBox',function(src,cb,box)
    cb(run(src,function(player,lock)
        assert(type(box)=='string' and carried(player,'deck_box',box),'Carry the selected Deck Box first')
        lock('box:'..player.PlayerData.citizenid..':'..box)
        local ids,seen={},{}
        for _,item in pairs(playerItems(player)) do
            if item.name==Bulk.item and type(item.info)=='table' and item.info.id and not seen[item.info.id] then
                validatePile(player,item.info.id); seen[item.info.id]=true; ids[#ids+1]=item.info.id
            end
        end
        if #ids==0 then return {ok=true,count=0} end
        local marks={}; for _ in ipairs(ids) do marks[#marks+1]='?' end
        local countArgs=copy(ids)
        local count=tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM bstar_card_copies WHERE location='pile' AND container_id IN ("..table.concat(marks,',')..')',countArgs)) or 0
        for _,id in ipairs(ids) do assert(carried(player,Bulk.item,id),'A pile moved; retry') end
        assert(carried(player,'deck_box',box),'Deck Box moved; retry')
        if BStarCondition then
            for _,id in ipairs(ids) do
                local rows=MySQL.query.await("SELECT id FROM bstar_card_copies WHERE location='pile' AND container_id=? ORDER BY id",{id})
                for offset=1,#rows,BStarConditionConfig.maxBatch do
                    local batch={};for i=offset,math.min(#rows,offset+BStarConditionConfig.maxBatch-1) do batch[#batch+1]={copyId=rows[i].id} end
                    BStarSleeves.updateMetadata(player,{location='pile',id=id},batch,function(info,row)
                        BStarCondition.settle(info,row);return true
                    end)
                end
            end
        end
        local args={box,player.PlayerData.citizenid,os.time()};for _,id in ipairs(ids) do args[#args+1]=id end
        -- One atomic UPDATE moves identities, never copies/deletes their metadata.
        assert(MySQL.transaction.await({{query="UPDATE bstar_card_copies SET location='box',container_id=?,citizenid=?,entered_at=? WHERE location='pile' AND container_id IN ("..table.concat(marks,',')..')',values=args}}),'Transfer failed; piles remain unchanged')
        local cleanupPending=reconcileEmpty(player)
        return {ok=true,count=count,cleanupPending=cleanupPending}
    end))
end)
QBCore.Functions.CreateCallback('bstar_cards:server:bulkCheck',function(src,cb,id)
    local player=QBCore.Functions.GetPlayer(src)
    if not player or type(id)~='string' then cb({ok=false});return end
    local count=0
    for _,item in pairs(player.PlayerData.items or {}) do
        if item.name==Bulk.item and type(item.info)=='table' and item.info.id==id and item.amount==1 then count=count+1 end
    end
    cb({ok=count==1})
end)
QBCore.Functions.CreateCallback('bstar_cards:server:bulkList',function(src,cb)
    cb(run(src,function(player)
        local piles={}
        for _,item in pairs(playerItems(player)) do
            if item.name==Bulk.item and type(item.info)=='table' and item.info.id then
                validatePile(player,item.info.id)
                piles[#piles+1]={id=item.info.id,count=countPile(item.info.id)}
            end
        end
        return {ok=true,piles=piles}
    end))
end)
QBCore.Functions.CreateCallback('bstar_cards:server:bulkOpen',function(src,cb,id)
    local result=run(src,function(player)
        if not id then
            for _,item in pairs(playerItems(player)) do if item.name==Bulk.item and type(item.info)=='table' then id=item.info.id;break end end
        end
        assert(id,'No pile carried. Use /bstarpiles to recover a pending delivery.')
        validatePile(player,id);Bulk.refresh(player)
        return {ok=true,id=id}
    end)
    if result.ok then exports['qb-inventory']:CloseInventory(src);TriggerClientEvent('bstar_cards:client:bulkOpen',src,result.id) end
    cb(result)
end)
QBCore.Functions.CreateCallback('bstar_cards:server:bulkClaim',function(src,cb)
    local result=run(src,function(player,lock)
        local cid=player.PlayerData.citizenid
        local id=MySQL.scalar.await('SELECT id FROM bstar_bulk_piles WHERE pending_owner=? ORDER BY created_at,id LIMIT 1',{cid})
        assert(id,'No undelivered pile is waiting')
        lock('pile:'..id)
        local planned=copy(playerItems(player)); local used,free=exports['qb-inventory']:GetSlots(src)
        assert(free>0,'Free one inventory slot, then use /bstarpiles again')
        local slot;for i=1,used+free do if not planned[i] then slot=i;break end end
        local info=Bulk.pileInfo(id,countPile(id))
        planned[slot]={name=Bulk.item,type='item',amount=1,slot=slot,info=info}
        local result=executeMove(player,{kind='delivery',pile=id},function()
            assert(exports['qb-inventory']:AddItem(src,Bulk.item,1,slot,info,'bstar-pile-delivery'))
        end,planned)
        result.id=id; return result
    end)
    if result.ok then
        exports['qb-inventory']:CloseInventory(src)
        TriggerClientEvent('bstar_cards:client:bulkOpen',src,result.id)
    end
    cb(result)
end)
QBCore.Functions.CreateUseableItem(Bulk.item,function(src,item)
    local result=run(src,function(player)
        assert(type(item.info)=='table','Pile unavailable')
        validatePile(player,item.info.id)
        Bulk.refresh(player)
        return {ok=true,id=item.info.id}
    end)
    if result.ok then
        exports['qb-inventory']:CloseInventory(src)
        TriggerClientEvent('bstar_cards:client:bulkOpen',src,result.id)
    else TriggerClientEvent('QBCore:Notify',src,result.error,'error') end
end)
local function registerPileItem()
    -- GetCoreObject returns a snapshot across the resource boundary. AddItem
    -- updates qb-core, not this snapshot: never reread it after registering.
    local existing=QBCore.Shared.Items[Bulk.item]
    if not existing then
        local added,reason=QBCore.Functions.AddItem(Bulk.item,{name=Bulk.item,label='Bulk Card Pile',weight=0,type='item',image='bstar_bulk_pile.png',
            unique=true,useable=true,shouldClose=true,description='A collection of individual trading cards. Use to inspect.'})
        assert(added,'Could not register pile item: '..tostring(reason))
    elseif existing.image~='bstar_bulk_pile.png' then
        local definition=copy(existing)
        definition.image='bstar_bulk_pile.png'
        local updated,reason=QBCore.Functions.UpdateItem(Bulk.item,definition)
        assert(updated,'Could not update pile icon: '..tostring(reason))
    end
end
local function startupStage(label)
    Bulk.stage=label
    Bulk.error='Card storage is starting ('..label..'). Please try again shortly; no pack has been consumed.'
end
-- Observe slow connections/queries without cancelling or racing initialisation.
CreateThread(function()
    Wait(30000)
    if Bulk.status=='starting' then
        print('[BStar bulk] Startup still pending after 30 seconds: '..Bulk.stage..'. Storage remains locked; no safety checks bypassed.')
    end
end)
RegisterCommand('bstarstorage',function(src)
    if src~=0 then return end
    print(('[BStar bulk] status=%s ready=%s stage=%s%s'):format(Bulk.status,tostring(Bulk.ready),Bulk.stage,
        Bulk.failure and (' error='..Bulk.failure) or ''))
end,true)
local function ensureSchemaFile(path)
    local text=assert(LoadResourceFile(GetCurrentResourceName(),path),'Missing schema file: '..path)
    text=text:gsub('%-%-[^\r\n]*','')
    for statement in text:gmatch('[^;]+') do
        statement=statement:match('^%s*(.-)%s*$')
        if statement~='' then
            local name=assert(statement:match('^CREATE%s+TABLE%s+IF%s+NOT%s+EXISTS%s+(bstar_[%w_]+)'), 'Expected only idempotent table creation in '..path)
            -- Existing tables do not require CREATE permission or get altered.
            startupStage('checking table '..name)
            local exists=MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=?',{name})
            if tonumber(exists)==0 then startupStage('creating missing table '..name);MySQL.query.await(statement) end
        end
    end
end
MySQL.ready(function()
    Bulk.ready=false
    local ok,err=pcall(function()
        startupStage('validating inventory adapter')
        -- No new character-bound rewards, and no silently guessed ownership migration.
        local loaded,version=pcall(function() return exports['qb-inventory']:BStarPileAdapterVersion() end)
        assert(loaded and version==2,'Reload patched qb-inventory before starting BStar; the running inventory adapter is not ready')
        local inventory=LoadResourceFile('qb-inventory','server/main.lua') or ''
        for _,marker in ipairs({'bstar-pile-give-rollback','bstar-pile-drop-rollback','bstar-pile-move-rollback','and not pileMove then','bstar-pile-access-guard'}) do
            assert(inventory:find(marker,1,true),'Required approved inventory pile safety patch is not installed')
        end
        startupStage('registering pile item');registerPileItem()
        ensureSchemaFile('sql/pack-openings.sql');ensureSchemaFile('sql/bulk-piles.sql')
        startupStage('validating storage engines')
        local rows=MySQL.query.await("SELECT TABLE_NAME,ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('players','bstar_pack_openings','bstar_bulk_piles','bstar_card_copies','bstar_card_moves','bstar_deckbox_cards')")
        assert(#rows==6,'Required storage tables missing')
        for _,row in ipairs(rows) do assert(row.ENGINE=='InnoDB',row.TABLE_NAME..' must use InnoDB') end
        startupStage('validating storage columns')
        MySQL.query.await('SELECT id,pending_owner FROM bstar_bulk_piles LIMIT 0')
        MySQL.query.await('SELECT id,card_id,info,location,container_id,citizenid,entered_at FROM bstar_card_copies LIMIT 0')
        MySQL.query.await('SELECT id,citizenid,status,operation,before_inventory,after_inventory,db_before_inventory FROM bstar_card_moves LIMIT 0')
        startupStage('checking personal migration and unresolved openings')
        local personal=tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM bstar_card_copies WHERE location='bulk'"))
        assert(personal and personal==0,'Personal pile cards preserved: back up the database and approve sql/personal-to-physical.sql before enabling physical piles')
        for _,row in ipairs(MySQL.query.await("SELECT id,rewards FROM bstar_pack_openings WHERE status IN ('prepared','review')")) do
            local storage=json.decode(row.rewards).storage
            assert(not storage or storage.mode~='personal','Resolve personal pack journal '..row.id..' before migration; no rewards reassigned')
        end
    end)
    if ok then
        Bulk.ready=true;Bulk.error=nil;Bulk.status='ready';Bulk.stage='complete';Bulk.failure=nil
        print('[BStar bulk] Physical pile storage ready. Inventory tokens identify independent collections.')
    else
        Bulk.status='failed';Bulk.failure=tostring(err)
        Bulk.error='Physical pile storage unavailable. See the BStar server setup error; no new pack has been consumed.'
        print('[BStar bulk] SETUP FAILED at '..Bulk.stage..': '..tostring(err)..' | Existing personal/card records remain preserved; no automatic personal migration is performed.')
    end
end)

local function clearEpoch(src) epochs[src]=(epochs[src] or 0)+1 end
AddEventHandler('playerDropped',function() clearEpoch(source) end)
AddEventHandler('QBCore:Server:OnPlayerUnload',clearEpoch)
