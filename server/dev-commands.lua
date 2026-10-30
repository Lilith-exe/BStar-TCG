-- Development command registrations and their server-side debug entry point.
-- Access behaviour is preserved; relocation does not restrict these commands or
-- the independently callable debug events. Server owners manage
-- developer access through their own server permission systems.
local QBCore = exports['qb-core']:GetCoreObject()
local ResolveCardDefinition = DeckBox.ResolveCardDefinition
local GetCardHealthText = DeckBox.GetCardHealthText
local qb = QBCore
local store = BStarBulk.storage
local cfg = Config.Collectibles
BStarDev = BStarDev or {}
local Dev = BStarDev

function Dev.grantDeckBox(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local uniqueId = "DB-" .. os.time() .. "-" .. math.random(1000, 9999)
    local success = Player.Functions.AddItem('deck_box', 1, false, {id=uniqueId})
    return {ok=not not success,error=not success and 'Inventory full!' or nil,id=success and uniqueId or nil}
end
RegisterCommand('givedeckbox', function(source)
    local result=Dev.grantDeckBox(source)
    if not result then return end
    TriggerClientEvent('QBCore:Notify',source,result.ok and 'Deck box received!' or result.error,result.ok and 'success' or 'error')
end, false)

RegisterCommand('givecardtest', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local cardId = args[1] or 'ALPH_LAYLA_HART'
    local card = ResolveCardDefinition(cardId)

    if not card then
        TriggerClientEvent('QBCore:Notify', src, 'Card not found: ' .. tostring(cardId), 'error')
        return
    end

    local info = {
        cardId = card.id,
        label = card.name .. " (" .. card.rarity .. ")",
        rarity = card.rarity,
        inventoryImage = card.inventoryImage,
        description =
            card.setCode .. " - " .. card.edition .. "\n\n" ..
            card.type .. " | " .. card.job .. " | Lv." .. card.level .. "\n\n" ..
            card.speed .. " • " .. card.attack .. " • " .. (GetCardHealthText(card) or ''),
        display = false
    }

    Player.Functions.AddItem('bstar_card', 1, false, info)

    local notifItem = {
        name = 'bstar_card',
        label = info.label,
        image = QBCore.Shared.Items['bstar_card'].image,
        inventoryImage = card.inventoryImage,
        info = info,
        amount = 1,
        type = 'item',
        unique = QBCore.Shared.Items['bstar_card'].unique or true,
        useable = QBCore.Shared.Items['bstar_card'].useable or true,
        weight = QBCore.Shared.Items['bstar_card'].weight or 0
    }

    TriggerClientEvent('inventory:client:ItemBox', src, notifItem, 'add', 1)
    TriggerClientEvent('QBCore:Notify', src, 'Given card: ' .. card.name, 'success')
end, false)


function Dev.grantBinder(target)
    local initial=qb.Functions.GetPlayer(target)
    if not initial then return {ok=false,started=false,error='Player unavailable'} end
    local cid,license=initial.PlayerData.citizenid,initial.PlayerData.license
    local deadline=GetGameTimer()+10000
    local function samePlayer()
        local current=qb.Functions.GetPlayer(target)
        return current and current.PlayerData.citizenid==cid and current.PlayerData.license==license
    end
    -- Wait only BEFORE the one grant attempt. Never retry a mutation or clear
    -- another operation's lock; store.run remains the authoritative lock owner.
    while BStarStorageLocks[cid] do
        if not samePlayer() then return {ok=false,started=false,error='Character changed; no binder grant started'} end
        if GetGameTimer()>=deadline then return {ok=false,code='storage_busy',started=false,error='Card storage is still busy; no binder grant started'} end
        Wait(50)
    end
    if not samePlayer() then return {ok=false,started=false,error='Character changed; no binder grant started'} end
    local attempted,responded=false,false
    local result=store.run(target,function(p)
        assert(BStarCollectibles.ready,'Collector items are unavailable');assert(BStarBulk.ready,BStarBulk.error)
        local id=MySQL.scalar.await('SELECT UUID()')
        assert(type(id)=='string' and #id==36 and id:match('^[%x%-]+$'),'Binder identity unavailable')
        store.items(p) -- Revalidate the character/epoch after UUID allocation.
        attempted=true
        local accepted=exports['qb-inventory']:AddItem(target,cfg.binder.item,1,false,{id=id,owner=p.PlayerData.citizenid,display=false,image='nui://bstar_cards/html/images/assets/bstar_binder.svg',description=('Personal collector binder • %s pockets'):format(cfg.binder.pages*cfg.binder.pocketsPerPage)},'bstar-test-binder')
        responded=true
        assert(accepted,'Inventory rejected binder')
        return {ok=true,id=id,message='Personal test binder granted.'}
    end)
    result.started=attempted
    if attempted and not responded then
        result.unconfirmed=true
        result.error='Binder grant outcome unconfirmed. Inspect inventory before another request. '..tostring(result.error or '')
    end
    return result
end
RegisterCommand('bstargivebinder',function(src,args)
    if src~=0 then return end
    local target=tonumber(args[1]);local player=target and qb.Functions.GetPlayer(target)
    if not player or #args~=1 then print('Usage: bstargivebinder <online player ID>');return end
    local result=Dev.grantBinder(target)
    print('[BStar collectibles] '..(result.ok and 'Test binder granted.' or tostring(result.error)))
end,true)

RegisterNetEvent('bstar_cards:server:DuelDebugSpawnFighter', function(duelId, playerIndex, cardId, zoneIndex)
    local src = source

    local ok, err = Duel.DebugSpawnFighter(duelId, playerIndex, cardId, zoneIndex)
    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Debug fighter spawned.', 'success')
    end
end)

-- Server-only development service; no generic item/SQL/command dispatch.
function Dev.catalogue()
    local ids, skipped = {}, 0
    for id, card in pairs(Cards or {}) do
        -- Pack eligibility uses printable inventory artwork. Tokens without art
        -- remain duel-only; iterate canonical entries, not the alias catalogue.
        if type(id)=='string' and #id<=100 and type(card)=='table' and
            card.id==id and type(card.inventoryImage)=='string' and card.inventoryImage~='' and
            ResolveCardDefinition(id)==card then
            ids[#ids+1]=id
        else skipped=skipped+1 end
    end
    table.sort(ids)
    return ids, skipped
end

local function populateBox(src, box, ids, skipped, quantity, kind)
    local report={generated=0,skipped=skipped*quantity,failed=0,unconfirmed=0,planned=#ids*quantity,box=box,quantity=quantity,cardId=#ids==1 and ids[1] or nil}
    -- Preserve the old event's existing Debug behaviour; this is not permission handling.
    if Config and Config.Debug~=true then
        report.ok=false;report.error='BStar dev commands are disabled.';return report
    end
    local attempted, completed = false, false
    local result=store.run(src,function(player,lock)
        assert(type(box)=='string' and #box>0 and #box<=100,'Choose a valid Deck Box ID')
        local cid=player.PlayerData.citizenid
        assert(store.carried(player,'deck_box',box),'Carry the selected Deck Box first')
        lock('box:'..cid..':'..box)
        assert(BStarSleeves and BStarSleeves.ready,'Sleeve metadata services are unavailable')
        assert(BStarConditionRules,'Condition rules are unavailable')
        assert(#ids>0,'No eligible printable cards found')
        -- Six placeholders per copy; fail before any writes at the SQL bind limit.
        -- Physical Deck Boxes currently have no configured card-count capacity.
        assert(report.planned*6<60000,'Catalogue is too large for one atomic fill')
        local function emptyBox()
            assert(not MySQL.scalar.await([[SELECT id FROM bstar_card_copies
                WHERE citizenid=? AND container_id=? AND location IN ('box','reserved','sleeving') LIMIT 1]],{cid,box}),
                'Deck Box is populated or has reserved copies; no cards generated')
            assert(not MySQL.scalar.await([[SELECT id FROM bstar_deckbox_cards
                WHERE citizenid=? AND deck_box_id=? AND amount<>0 LIMIT 1]],{cid,box}),
                'Deck Box contains legacy quantities; no cards generated')
        end
        emptyBox()
        local uuid=MySQL.scalar.await('SELECT UUID()')
        assert(type(uuid)=='string' and #uuid==36 and uuid:match('^[%x%-]+$'),'Copy identities unavailable')
        report.batchId=uuid
        local now, rows, values, identities = os.time(), {}, {}, {}
        for _,id in ipairs(ids) do
            for _=1,quantity do
                local copyId='dev:'..uuid..':'..(#rows+1)
                assert(not identities[copyId] and #copyId<=80,'Invalid generated copy identity')
                identities[copyId]=true
                local info=DeckBox.BuildCardItemInfo(id)
                info.cardId=id;info.copyId=copyId;info.acquiredAt=now
                BStarSleeves.initialInfo(info)
                BStarConditionRules.initialise(info,now)
                BStarConditionRules.mark(info,'box',now)
                info.developmentGrant={version=1,batch=uuid,kind=kind}
                rows[#rows+1]="(?,?,?,'box',?,?,?)"
                for _,value in ipairs({copyId,id,json.encode(info),box,cid,now}) do values[#values+1]=value end
            end
        end
        -- Recheck after all yielding preflight work and immediately before commit.
        emptyBox()
        assert(store.carried(player,'deck_box',box),'Deck Box moved; no cards generated')
        attempted=true
        local saved=MySQL.transaction.await({{query=[[INSERT INTO bstar_card_copies
            (id,card_id,info,location,container_id,citizenid,entered_at) VALUES ]]..table.concat(rows,','),values=values}})
        completed=true
        assert(saved,'Atomic fill failed; no copies committed')
        report.generated=#rows
        return {ok=true}
    end)
    report.ok=result.ok==true;report.error=result.error
    if not report.ok then
        if attempted and not completed then
            -- A transport error can hide a committed transaction. Never retry or
            -- claim zero grants: batch IDs are retained in every copy for review.
            report.unconfirmed=report.planned
            report.error=(report.error or 'Fill interrupted')..'; outcome unconfirmed: inspect the box/batch before retrying'
        else report.failed=report.planned end
    end
    return report
end

function Dev.fillDeckBox(src, box)
    local ids, skipped=Dev.catalogue()
    return populateBox(src,box,ids,skipped,3,'catalogue-fill')
end

function Dev.createBoxCopies(src, box, cardId, quantity)
    if quantity~=1 and quantity~=5 and quantity~=10 then return {ok=false,error='Choose 1, 5 or 10 copies'} end
    local eligible=false
    for _,id in ipairs(Dev.catalogue()) do if id==cardId then eligible=true;break end end
    if not eligible then return {ok=false,error='Choose a printable catalogue card'} end
    return populateBox(src,box,{cardId},0,quantity,'selected-cards')
end

RegisterNetEvent('bstar_cards:server:DevFillDeckBox',function(box)
    local src=source
    local result=Dev.fillDeckBox(src,box)
    local message=('Deck Box fill: %d generated, %d skipped, %d failed, %d unconfirmed.'):format(
        result.generated,result.skipped,result.failed,result.unconfirmed)
    if result.error then message=message..' '..result.error end
    if result.batchId then message=message..' Batch: '..result.batchId end
    print('[BStar dev] '..tostring(src)..' '..message)
    TriggerClientEvent('QBCore:Notify',src,message,result.ok and 'success' or 'error',12000)
end)
