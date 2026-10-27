-- Console-only, explicit maintenance conversion; never runs at startup.
local busy = false
local batchSize = 100
local prefix = '[BStar legacy] '
local function say(message) print(prefix..message) end
local function emptyServer()
    assert(#GetPlayers()==0, 'Apply requires an empty server. Disconnect players first.')
    assert(not next(BStarStorageLocks or {}), 'A card operation is still running; wait and retry.')
end

-- Keep players out for the duration of an explicit apply. Preview never blocks joins.
AddEventHandler('playerConnecting', function(_, _, deferrals)
    if not busy then return end
    deferrals.defer()
    Wait(0)
    deferrals.done('BStar card maintenance is running. Please reconnect shortly.')
    CancelEvent()
end)

local function plan()
    assert(BStarBulk and BStarBulk.ready, 'Card storage must be ready; check /bstarstorage.')
    assert(BStarConditionRules and DeckBox and DeckBox.ResolveCardDefinition and DeckBox.BuildCardItemInfo, 'Card rules unavailable.')
    local rows = MySQL.query.await([[SELECT id,citizenid,deck_box_id,card_id,amount
        FROM bstar_deckbox_cards ORDER BY id]])
    local result = {rows={},copies=0,owners={},boxes={},blockers={},skipped={},skippedCopies=0}
    for _, row in ipairs(rows) do
        local amount = tonumber(row.amount)
        local card, canonical = DeckBox.ResolveCardDefinition(row.card_id)
        local reason
        if not amount or amount<0 or amount%1~=0 then reason='invalid quantity'
        elseif type(row.citizenid)~='string' or row.citizenid=='' or #row.citizenid>50 then reason='invalid owner'
        elseif type(row.deck_box_id)~='string' or row.deck_box_id=='' or #row.deck_box_id>100 then reason='invalid box'
        elseif amount>0 and (not card or not Cards[canonical]) then reason='unknown card ID' end
        if reason=='unknown card ID' then
            -- Historical promo rows can outlive the current catalogue. Preserve
            -- their exact IDs/counts in legacy storage; never guess a replacement.
            row.amount=amount
            result.skipped[#result.skipped+1]=row
            result.skippedCopies=result.skippedCopies+amount
        elseif reason then
            result.blockers[#result.blockers+1]=('row %s: %s (%s)'):format(tostring(row.id),reason,tostring(row.card_id))
        elseif amount>0 then
            row.amount=amount;row.canonical=canonical
            result.rows[#result.rows+1]=row;result.copies=result.copies+amount
            result.owners[row.citizenid]=true
            result.boxes[row.citizenid..':'..row.deck_box_id]=true
        end
    end
    return result
end
local function countKeys(map) local count=0;for _ in pairs(map) do count=count+1 end;return count end
local function report(result)
    say(('%d quantity rows / %d copies / %d owners / %d boxes; destination: same box and owner, unsleeved, 100%%.'):format(
        #result.rows,result.copies,countKeys(result.owners),countKeys(result.boxes)))
    for index, reason in ipairs(result.blockers) do if index<=20 then say('BLOCKED '..reason) end end
    if #result.blockers>20 then say(('... %d further invalid rows.'):format(#result.blockers-20)) end
    for index,row in ipairs(result.skipped) do
        if index<=20 then say(('SKIPPED row %s: unknown card ID %s (%d copies retained unchanged)'):format(tostring(row.id),tostring(row.card_id),row.amount)) end
    end
    if #result.skipped>20 then say(('... %d further unknown-ID rows retained.'):format(#result.skipped-20)) end
    if #result.skipped>0 then say(('%d unknown-ID rows / %d copies will stay in legacy storage; recognised cards can still convert.'):format(#result.skipped,result.skippedCopies)) end
    say('Existing physical copies, sleeve stock, grading and saved decks are not modified. Zero-quantity rows are left alone.')
end
local function ensureMaintenance(result)
    emptyServer()
    assert(not MySQL.scalar.await("SELECT id FROM bstar_card_moves WHERE status IN ('prepared','review') LIMIT 1"),
        'Unresolved card move/sleeve journal; recover it before conversion.')
    assert(not MySQL.scalar.await("SELECT id FROM bstar_pack_openings WHERE status IN ('prepared','review') LIMIT 1"),
        'Unresolved pack journal; recover it before conversion.')
    assert(not MySQL.scalar.await("SELECT id FROM bstar_card_copies WHERE location IN ('reserved','sleeving') LIMIT 1"),
        'Reserved card copies need recovery before conversion.')
    if BStarCondition then
        for cid in pairs(result.owners) do assert(not BStarCondition.pending(cid), 'Pending completed-duel wear for '..cid) end
    end
end

local function convert(row, amount, expected)
    local uuid=MySQL.scalar.await('SELECT UUID()')
    assert(type(uuid)=='string' and #uuid==36, 'Could not allocate conversion identities.')
    local now=os.time()
    -- Row lock + matching amount guard on every statement. The copy insertions
    -- and legacy decrement commit together; failure rolls the whole batch back.
    local where='id=? AND citizenid=? AND deck_box_id=? AND card_id=? AND amount=?'
    local identity={row.id,row.citizenid,row.deck_box_id,row.card_id,expected}
    local queries={{query='SELECT id FROM bstar_deckbox_cards WHERE '..where..' FOR UPDATE',values=identity}}
    local ids={}
    for index=1,amount do
        local id='legacy:'..uuid..':'..index
        ids[#ids+1]=id
        local info=DeckBox.BuildCardItemInfo(row.canonical)
        info.cardId=row.canonical;info.copyId=id;info.condition=100;info.sleeve=nil
        info.legacyConversion={version=1,at=now,sourceCardId=row.card_id}
        BStarConditionRules.initialise(info,now)
        BStarConditionRules.mark(info,'box',now)
        local values={id,row.canonical,json.encode(info),row.deck_box_id,row.citizenid,now}
        for _, value in ipairs(identity) do values[#values+1]=value end
        queries[#queries+1]={query=[[INSERT INTO bstar_card_copies
            (id,card_id,info,location,container_id,citizenid,entered_at)
            SELECT ?,?,?,'box',?,?,? FROM bstar_deckbox_cards WHERE ]]..where,values=values}
    end
    local values={amount};for _,value in ipairs(identity) do values[#values+1]=value end
    queries[#queries+1]={query='UPDATE bstar_deckbox_cards SET amount=amount-? WHERE '..where,values=values}
    queries[#queries+1]={query='DELETE FROM bstar_deckbox_cards WHERE id=? AND citizenid=? AND deck_box_id=? AND card_id=? AND amount=0',
        values={row.id,row.citizenid,row.deck_box_id,row.card_id}}
    assert(MySQL.transaction.await(queries), 'Batch transaction failed; committed earlier batches are safe to resume.')
    -- A changed source amount makes all guarded statements no-ops. Stop instead
    -- of reporting success or blindly retrying a stale snapshot.
    local marks={};for _ in ipairs(ids) do marks[#marks+1]='?' end
    local inserted=tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM bstar_card_copies WHERE id IN ('..table.concat(marks,',')..')',ids))
    assert(inserted==amount, 'Source changed during conversion; stopped. Re-run preview before resuming.')
end

RegisterCommand('bstarconvertlegacy', function(src,args)
    if src~=0 then return end
    local mode=args[1] or 'preview'
    if (mode~='preview' and mode~='apply') or #args>1 then
        say('Usage: bstarconvertlegacy preview | bstarconvertlegacy apply');return
    end
    if busy then say('Conversion already running.');return end
    -- Set before yielding so a second command cannot start concurrently.
    busy=mode=='apply'
    local converted=0
    local ok,err=pcall(function()
        if mode=='apply' then emptyServer() end
        local result=plan();report(result)
        assert(#result.blockers==0, 'Resolve invalid legacy rows first; no conversion started.')
        if mode=='preview' then say('Preview only. Back up the database, empty the server, then run: bstarconvertlegacy apply');return end
        ensureMaintenance(result)
        for _,row in ipairs(result.rows) do
            local remaining=row.amount
            while remaining>0 do
                emptyServer()
                local amount=math.min(batchSize,remaining)
                convert(row,amount,remaining)
                remaining=remaining-amount;converted=converted+amount
                if converted%1000==0 then say(('Converted %d / %d copies.'):format(converted,result.copies)) end
                Wait(0)
            end
        end
        say(('Complete: %d copies converted. Repeating apply converts only remaining quantity rows.'):format(converted))
    end)
    busy=false
    if not ok then say(('STOPPED after %d confirmed copies: %s'):format(converted,tostring(err))) end
end,true)
