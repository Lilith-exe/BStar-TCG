-- Condition is private copy metadata. Reuse sleeve reservations/receipts for
-- atomic updates; never edit an offline inventory or invent custody.
BStarCondition = {}
local C,R,config,store=BStarCondition,BStarConditionRules,BStarConditionConfig,BStarBulk.storage
local qb=exports['qb-core']:GetCoreObject()
local session=tostring(os.time())..':'..tostring({})
local presence,cursors,settling,checked={},{},{},{}
local completions,durable={},{}
local recoveryError
local function saveCompletions()
    local encoded=json.encode(completions)
    SetResourceKvp(config.recoveryKey,encoded)
    assert(GetResourceKvpString(config.recoveryKey)==encoded,'Completed duel recovery record could not be verified')
end
local loaded,problem=pcall(function()
    local raw=GetResourceKvpString(config.recoveryKey)
    if not raw then return end
    local records=json.decode(raw)
    assert(type(records)=='table','Invalid completed-duel recovery record')
    for receipt,record in pairs(records) do
        assert(type(receipt)=='string' and type(record)=='table' and record.conditionReceipt==receipt and
            type(record.players)=='table' and type(record.conditionCopies)=='table','Completed-duel recovery needs review')
        for _,member in pairs(record.players) do
            assert(type(member.citizenid)=='string' and type(member.license)=='string','Completed-duel character identity needs review')
        end
        for _,groups in pairs(record.conditionCopies) do for _,group in ipairs(groups) do
            assert(type(group.box)=='string' and (group.location==nil or group.location=='box' or group.location=='binder') and type(group.copies)=='table','Completed-duel allocation needs review')
            for _,copy in ipairs(group.copies) do assert(type(copy.copyId)=='string','Invalid completed-duel copy') end
        end end
        record.status='finished';record.started=true;record.conditionSettling=nil;record.conditionSettled=nil
        completions[receipt]=record;durable[receipt]=true
    end
end)
if not loaded then recoveryError=tostring(problem);print('[BStar condition] Recovery held: '..recoveryError) end
function C.observe(now)
    local carried,counts={},{}
    for _,player in pairs(qb.Functions.GetQBPlayers()) do
        for _,item in pairs(player.PlayerData.items or {}) do
            if item.name==BStarBulk.item and item.amount==1 and type(item.info)=='table' and type(item.info.id)=='string' then
                local id=item.info.id
                counts[id]=(counts[id] or 0)+1
                carried[id]=player.PlayerData.citizenid
            end
        end
    end
    for id,state in pairs(presence) do
        local holder=counts[id]==1 and carried[id] or nil
        if holder and holder==state.holder and now-state.at<=config.sweepSeconds*2 then
            local before=state.total
            state.total=state.total+math.max(0,now-state.at)
            local last=state.intervals[#state.intervals]
            if last and last.to==state.at then last.to=now;last.last=state.total
            else state.intervals[#state.intervals+1]={from=state.at,to=now,first=before,last=state.total} end
        end
        state.holder=holder;state.at=now
    end
    for id,holder in pairs(carried) do
        if counts[id]==1 and holder and not presence[id] then presence[id]={holder=holder,at=now,total=0,intervals={}} end
    end
end
function C.settle(info,row,now)
    if not config.enabled then return end
    now=now or os.time()
    -- Existing copies without a clock start now; no retroactive invented history.
    if not info.pileEnteredAt and row.location=='pile' then
        info.pileEnteredAt=tonumber(row.entered_at) or now
        info.pileGraceUntil=info.pileEnteredAt+config.bulk.graceSeconds
    end
    local clock=info.conditionWear
    local state=row.location=='pile' and presence[row.container_id]
    local online=0
    if clock and state and clock.bulkSession==session and clock.bulkContainer==row.container_id then
        local counter=tonumber(clock.bulkCounter) or state.total
        local grace=tonumber(info.pileGraceUntil) or now
        -- Intersect proven online intervals with the grace deadline. A long
        -- offline gap must never turn pre-grace time into eligible wear.
        for _,interval in ipairs(state.intervals) do
            if interval.last>counter then
                local from=interval.from+math.max(0,counter-interval.first)
                online=online+math.max(0,interval.to-math.max(from,grace))
            end
        end
    end
    R.settle(info,row.location,now,online)
    info.conditionWear.bulkSession=session
    info.conditionWear.bulkContainer=row.location=='pile' and row.container_id or nil
    info.conditionWear.bulkCounter=state and state.total or nil
end
function C.selections(player,ctx,selections,force,duelId,permit)
    if not config.enabled or #selections==0 then return {ok=true} end
    local processed={}
    local result=BStarSleeves.updateMetadata(player,ctx,selections,function(info,row)
        local now=os.time();local clock=info.conditionWear
        processed[row.id]=clock and tonumber(clock.at) or now
        local due=not clock or now-(tonumber(clock.at) or 0)>=config.checkpointSeconds
        if not force and not due then return false end
        C.settle(info,row,now)
        if duelId then R.duel(info,duelId) end
        processed[row.id]=now
        return true
    end,permit)
    if result.ok then for id,at in pairs(processed) do checked[id]=at end end
    return result
end
function C.refreshContext(player,ctx,force)
    if not config.enabled then return end
    local selections={}
    local cursorKey,nextCursor
    if ctx.location=='pocket' then
        for _,item in pairs(store.items(player)) do
            if item.name=='bstar_card' and item.amount==1 and type(item.info)=='table' then
                local last=checked[item.info.copyId]
                if force or not last or os.time()-last>=config.checkpointSeconds then
                    selections[#selections+1]={copyId=item.info.copyId,slot=item.slot}
                end
            end
        end
    else
        local key=player.PlayerData.citizenid..':'..ctx.location..':'..ctx.id
        local where='location=? AND container_id=?';local args={ctx.location,ctx.id}
        if ctx.location~='pile' then where=where..' AND citizenid=?';args[#args+1]=player.PlayerData.citizenid end
        where=where..' AND id>?';args[#args+1]=cursors[key] or ''
        local rows=MySQL.query.await('SELECT id,info FROM bstar_card_copies WHERE '..where..' ORDER BY id LIMIT '..config.maxBatch,args)
        for _,row in ipairs(rows) do
            local info=json.decode(row.info);local clock=info.conditionWear
            if force or not clock or os.time()-(tonumber(clock.at) or 0)>=config.checkpointSeconds then
                selections[#selections+1]={copyId=row.id}
            end
        end
        cursorKey=key;nextCursor=#rows==config.maxBatch and rows[#rows].id or nil
    end
    -- Pocket counts are limited by inventory capacity; container scans are paged.
    for offset=1,#selections,config.maxBatch do
        local batch={};for i=offset,math.min(#selections,offset+config.maxBatch-1) do batch[#batch+1]=selections[i] end
        C.selections(player,ctx,batch,force)
    end
    if cursorKey then cursors[cursorKey]=nextCursor end
end
function C.refresh(player)
    if not config.enabled then return end
    C.refreshContext(player,{location='pocket',id=''})
    local contexts={}
    for _,item in pairs(store.items(player)) do
        if item.amount==1 and type(item.info)=='table' and type(item.info.id)=='string' then
            local location=item.name==BStarBulk.item and 'pile' or item.name=='deck_box' and 'box' or
                item.name==BStarSleeveConfig.containers.binder and 'binder'
            if location then contexts[location..':'..item.info.id]={location=location,id=item.info.id} end
        end
    end
    for _,ctx in pairs(contexts) do
        -- updateMetadata revalidates carried custody and exact private row state.
        C.refreshContext(player,ctx)
    end
end
function C.touchPocket(src,item)
    return store.run(src,function(player)
        local actual
        for _,entry in pairs(store.items(player)) do if entry.slot==item.slot then actual=entry;break end end
        assert(actual and actual.name=='bstar_card' and actual.amount==1 and type(actual.info)=='table' and
            actual.info.cardId==item.info.cardId and (not item.info.copyId or actual.info.copyId==item.info.copyId),'Card moved')
        C.selections(player,{location='pocket',id=''},{ {copyId=actual.info.copyId,slot=actual.slot} },true)
        for _,entry in pairs(store.items(player)) do if entry.slot==item.slot then return {ok=true,item=entry} end end
        error('Card moved')
    end)
end
function C.pending(cid)
    if not config.enabled then return false end
    assert(not recoveryError,'Completed duel condition recovery needs review: '..tostring(recoveryError))
    if settling[cid] then return false end
    for _,record in pairs(completions) do
        for _,member in pairs(record.players) do if member.citizenid==cid then return true end end
    end
    for _,duel in pairs(Duel.Active or {}) do
        if duel.started and duel.status=='finished' and not duel.conditionSettled and duel.conditionCopies then
            for _,member in pairs(duel.players) do if member.citizenid==cid then return true end end
        end
    end
    return false
end
function C.finished(duel)
    if recoveryError then return end
    if not config.enabled or duel.status~='finished' or not duel.started or duel.conditionSettling or duel.conditionSettled then return end
    if not duel.conditionReceipt or not duel.conditionCopies then duel.conditionSettled=true;return end
    local receipt=duel.conditionReceipt
    if not completions[receipt] then
        completions[receipt]={id=duel.id,status='finished',started=true,conditionReceipt=receipt,
            players={},conditionCopies=store.copy(duel.conditionCopies)}
        -- Recovery needs character/account + exact allocation, never private hands,
        -- card definitions, condition values or the live battle/effect state.
        for index,member in ipairs(duel.players) do
            completions[receipt].players[index]={source=member.source,citizenid=member.citizenid,license=member.license}
        end
    end
    if not durable[receipt] then
        local ok,err=pcall(saveCompletions)
        if not ok then print('[BStar condition] Completion retained before wear: '..tostring(err));return end
        durable[receipt]=true
    end
    duel.conditionSettling=true
    local all=true
    local handled={}
    for index,member in ipairs(duel.players) do
        local live=qb.Functions.GetPlayer(member.source)
        if not live or live.PlayerData.citizenid~=member.citizenid or live.PlayerData.license~=member.license then
            live=nil
            for _,candidate in pairs(qb.Functions.GetQBPlayers()) do
                if candidate.PlayerData.citizenid==member.citizenid and candidate.PlayerData.license==member.license then
                    live=candidate;member.source=candidate.PlayerData.source;break
                end
            end
        end
        local expected=duel.conditionCopies and duel.conditionCopies[index]
        if expected and not handled[member.citizenid] then
            handled[member.citizenid]=true
            if not live or live.PlayerData.citizenid~=member.citizenid or live.PlayerData.license~=member.license then all=false
            else
                settling[member.citizenid]=true
                local result=store.run(member.source,function(player)
                    for _,group in ipairs(expected) do
                        C.selections(player,{location=group.location or 'box',id=group.box},group.copies,true,duel.conditionReceipt,function(p,ctx,list)
                            return duel.conditionSettling and duel.status=='finished' and p.PlayerData.citizenid==member.citizenid and
                                ctx.location==(group.location or 'box') and ctx.id==group.box and list==group.copies
                        end)
                    end
                    return {ok=true}
                end,true)
                settling[member.citizenid]=nil
                if not result.ok then all=false;print('[BStar condition] Completed duel wear pending: '..tostring(result.error)) end
            end
        end
    end
    duel.conditionSettling=false
    if all then
        local record=completions[receipt];completions[receipt]=nil
        local ok,err=pcall(saveCompletions)
        if not ok then
            completions[receipt]=record
            print('[BStar condition] Wear saved; completion acknowledgement retained: '..tostring(err))
            return
        end
        durable[receipt]=nil;duel.conditionSettled=true
        for _,active in pairs(Duel.Active or {}) do if active.conditionReceipt==receipt then active.conditionSettled=true end end
    end
end
function C.retryPending()
    if recoveryError then return end
    -- Copy references before a successful completion removes its queue entry.
    local list={};for _,record in pairs(completions) do list[#list+1]=record end
    for _,record in ipairs(list) do C.finished(record) end
end
-- Existing callers get fresh public categories; no exact-condition endpoint exists.
local getStored=DeckBox.GetStoredCards
DeckBox.GetStoredCards=function(src,box,cb)
    if config.enabled and BStarBulk.ready then
        local result=store.run(src,function(player)
            assert(store.carried(player,'deck_box',box),'Carry the selected Deck Box')
            C.refreshContext(player,{location='box',id=box},false);return {ok=true}
        end,true)
        if not result.ok then TriggerClientEvent('QBCore:Notify',src,result.error,'error');cb({});return end
    end
    getStored(src,box,cb)
end
CreateThread(function()
    while true do
        Wait(config.sweepSeconds*1000)
        if config.enabled and BStarBulk.ready and BStarSleeves.ready then
            C.observe(os.time())
            for _,player in pairs(qb.Functions.GetQBPlayers()) do
                store.run(player.PlayerData.source,function() return {ok=true} end,true)
            end
            for _,duel in pairs(Duel.Active or {}) do C.finished(duel) end
            C.retryPending()
        end
    end
end)

-- Read-only operator diagnostics. No copy metadata, custody changes, SQL or KVP
-- writes; this reports the running resource rather than a possibly edited file.
function C.status()
    local receipts,pending,unpersisted={},0,0
    for receipt in pairs(completions) do receipts[receipt]=true end
    for _,duel in pairs(Duel and Duel.Active or {}) do
        if duel.started and duel.status=='finished' and not duel.conditionSettled and duel.conditionReceipt and duel.conditionCopies then
            receipts[duel.conditionReceipt]=true
        end
    end
    for receipt in pairs(receipts) do
        pending=pending+1
        if not durable[receipt] then unpersisted=unpersisted+1 end
    end
    local observed=0;for _ in pairs(presence) do observed=observed+1 end
    return {enabled=config.enabled==true,storageReady=BStarBulk.ready==true,
        sleevesReady=BStarSleeves and BStarSleeves.ready==true or false,
        recoveryHeld=recoveryError~=nil,pendingCompletions=pending,unpersistedCompletions=unpersisted,
        observedPiles=observed,sweepSeconds=config.sweepSeconds,checkpointSeconds=config.checkpointSeconds,maxBatch=config.maxBatch}
end
RegisterCommand('bstarcondition',function(src,args)
    if src~=0 then return end
    args=args or {};local mode=args[1] or 'status'
    local function report(message) print('[BStar condition] '..message) end
    if #args>1 or (mode~='status' and mode~='rates') then report('Usage: bstarcondition [status|rates]');return end
    if mode=='status' then
        local health=C.status()
        report(('Enabled: %s | Storage ready: %s | Sleeves ready: %s'):format(tostring(health.enabled),tostring(health.storageReady),tostring(health.sleevesReady)))
        report(('Recovery held: %s | Pending completed duels: %d | Not durably saved yet: %d'):format(tostring(health.recoveryHeld),health.pendingCompletions,health.unpersistedCompletions))
        report(('Sweep: %ss | Checkpoint: %ss | Batch: %d | Observed pile tokens this session: %d'):format(health.sweepSeconds,health.checkpointSeconds,health.maxBatch,health.observedPiles))
        report('Read-only runtime status; no card data changed. Counts do not replace transfer/pack journal review. Use bstarcondition rates for active settings.')
        return
    end
    report(('Active settings | Enabled: %s | Losses are percentage points | Day: %ss | Hour: %ss'):format(tostring(config.enabled),config.daySeconds,config.hourSeconds))
    local starting={}
    for _,range in ipairs(config.starting) do starting[#starting+1]=('%s%% at %s-%s condition'):format(range.weight,range.min,range.max) end
    report('New cards: '..table.concat(starting,'; '))
    report(('Unsleeved completed duel: -%s | Sleeved/graded/slabbed: no duel wear'):format(config.duelWear))
    for _,location in ipairs({'box','binder'}) do
        local rate=config.daily[location]
        report(('%s daily: -%s with %s%% chance; no wear %s%%'):format(location,rate.loss,100-rate.noWearChance,rate.noWearChance))
    end
    local loose={}
    for _,rate in ipairs(config.daily.loose) do loose[#loose+1]=('-%s with %s%% chance'):format(rate.loss,rate.weight) end
    report('Loose/pocket daily: '..table.concat(loose,'; '))
    report(('Protective sleeve, every location: daily -%s with %s%% chance; no bulk hourly wear'):format(config.daily.protected.loss,config.daily.protected.wearChance))
    report(('Unsleeved bulk: %ss grace, then -%s to -%s per eligible carried-online hour; no offline hourly loss'):format(config.bulk.graceSeconds,config.bulk.minLoss,config.bulk.maxLoss))
    report(('Public categories: Good %s-100; Played %s-%s; Damaged 0-%s'):format(config.public.goodMin,config.public.playedMin,config.public.goodMin-1,config.public.playedMin-1))
    report('Daily wear includes offline time. Graded/slabbed cards never degrade. Cosmetic deck backs do not protect cards. At 0, cards stay owned but cannot play.')
end,true)
