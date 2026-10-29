local store=BStarBulk.storage
local create=Duel.Create
local function resolve(player,lock,deck)
    assert(type(deck.boxId)=='string' and store.carried(player,'deck_box',deck.boxId),'Carry the selected Deck Box')
    local cid=player.PlayerData.citizenid
    local design=BStarDeckCosmetics.resolve(cid,deck.deck_data.sleeveDesign)
    lock('box:'..cid..':'..deck.boxId)
    local rows=MySQL.query.await("SELECT id,card_id,info FROM bstar_card_copies WHERE location='box' AND citizenid=? AND container_id=? ORDER BY id",{cid,deck.boxId})
    local function withBinders(list)
        for _,row in ipairs(list) do row.location='box';row.container_id=deck.boxId end
        if BStarCollectibles then for _,row in ipairs(BStarCollectibles.binderDeckRows(player)) do list[#list+1]=row end end
        return list
    end
    rows=withBinders(rows)
    local legacy=MySQL.query.await('SELECT card_id,amount FROM bstar_deckbox_cards WHERE citizenid=? AND deck_box_id=?',{cid,deck.boxId})
    if BStarCondition and BStarConditionConfig.enabled then
        -- Only this deck's card types need a forced checkpoint before allocation.
        local wanted,candidates={},{}
        for id in pairs(deck.deck_data.cards or {}) do
            local def,key=DeckBox.ResolveCardDefinition(id);wanted[def and def.id or key or id]=true
        end
        for _,row in ipairs(rows) do
            local def,key=DeckBox.ResolveCardDefinition(row.card_id)
            if wanted[def and def.id or key or row.card_id] then candidates[#candidates+1]=row end
        end
        for offset=1,#candidates,BStarConditionConfig.maxBatch do
            local batches={}
            for i=offset,math.min(#candidates,offset+BStarConditionConfig.maxBatch-1) do local row=candidates[i];local groupKey=row.location..':'..row.container_id
                local group=batches[groupKey] or {context={location=row.location,id=row.container_id},copies={}};batches[groupKey]=group;group.copies[#group.copies+1]={copyId=row.id}
            end
            for _,group in pairs(batches) do BStarCondition.selections(player,group.context,group.copies,true) end
        end
        rows=withBinders(MySQL.query.await("SELECT id,card_id,info FROM bstar_card_copies WHERE location='box' AND citizenid=? AND container_id=? ORDER BY id",{cid,deck.boxId}))
    end
    local copies,old,used={},{},{}
    for _,row in ipairs(rows) do
        local def,key=DeckBox.ResolveCardDefinition(row.card_id);key=def and def.id or key or row.card_id
        local info=json.decode(row.info)
        if not BStarConditionRules or BStarConditionRules.playable(info) then
            copies[key]=copies[key] or {};copies[key][#copies[key]+1]={privateCopyId=row.id,privateContext={location=row.location,id=row.container_id},presentation=BStarCardPresentation.public(info)}
        end
    end
    for _,row in ipairs(legacy) do
        local def,key=DeckBox.ResolveCardDefinition(row.card_id);key=def and def.id or key or row.card_id
        old[key]=(old[key] or 0)+(tonumber(row.amount) or 0)
    end
    local result=store.copy(deck);result.deck_data.sleeveDesign=design;result.deck_data.__copies={}
    for id,count in pairs(result.deck_data.cards or {}) do
        local def,key=DeckBox.ResolveCardDefinition(id);key=def and def.id or key or id
        assert(def and type(count)=='number' and count%1==0 and count>=0 and count<=3,'Invalid deck card count')
        local offset=used[key] or 0;local available=copies[key] or {}
        assert(offset+count<=3,'Too many copies of the same card in this deck')
        assert(#available+(old[key] or 0)>=offset+count,'Deck needs more playable copies. Moved or destroyed cards cannot fill this deck.')
        used[key]=offset+count
        result.deck_data.__copies[id]={}
        for i=1,count do
            local instance=available[offset+i] or {presentation={}}
            instance.presentation.deckSleeveId=design
            result.deck_data.__copies[id][i]=instance
        end
    end
    assert(store.carried(player,'deck_box',deck.boxId),'Deck Box moved')
    return result
end
local function attachCondition(duel,a,b,receipt)
    if not duel or not BStarCondition or not BStarConditionConfig.enabled then return end
    duel.conditionReceipt=receipt
    duel.conditionCopies={}
    local seen={}
    for index,deck in ipairs({a,b}) do
        local groups={};duel.conditionCopies[index]={}
        for _,list in pairs(deck.deck_data.__copies or {}) do for _,card in ipairs(list) do
            if card.privateCopyId and not seen[card.privateCopyId] then
                seen[card.privateCopyId]=true;local ctx=card.privateContext or {location='box',id=deck.boxId};local key=ctx.location..':'..ctx.id
                local group=groups[key];if not group then group={box=ctx.id,location=ctx.location,copies={}};groups[key]=group;duel.conditionCopies[index][#duel.conditionCopies[index]+1]=group end
                group.copies[#group.copies+1]={copyId=card.privateCopyId}
            end
        end end
    end
    if duel.soloMode then
        for _,group in ipairs(duel.conditionCopies[2]) do table.insert(duel.conditionCopies[1],group) end
        duel.conditionCopies[2]={}
    end
end
function Duel.Create(srcA,srcB,deckA,deckB)
    local result=store.run(srcA,function(a,lockA)
        local resolvedA=resolve(a,lockA,deckA)
        if srcA==srcB then
            -- Solo practice reuses the same collection virtually, as before.
            local resolvedB=resolve(a,function(key) if deckB.boxId~=deckA.boxId then lockA(key) end end,deckB)
            local receipt=BStarCondition and BStarConditionConfig.enabled and assert(MySQL.scalar.await('SELECT UUID()'),'Condition receipt unavailable')
            local duel,err=create(srcA,srcB,resolvedA,resolvedB);assert(duel,err);attachCondition(duel,resolvedA,resolvedB,receipt);return {ok=true,duel=duel}
        end
        return store.run(srcB,function(b,lockB)
            local resolvedB=resolve(b,lockB,deckB)
            assert(store.carried(a,'deck_box',deckA.boxId) and store.carried(b,'deck_box',deckB.boxId),'Deck Box moved')
            local receipt=BStarCondition and BStarConditionConfig.enabled and assert(MySQL.scalar.await('SELECT UUID()'),'Condition receipt unavailable')
            local duel,err=create(srcA,srcB,resolvedA,resolvedB);assert(duel,err);attachCondition(duel,resolvedA,resolvedB,receipt);return {ok=true,duel=duel}
        end)
    end)
    return result.duel,result.error
end
local refreshed={}
RegisterNetEvent('bstar_cards:server:refreshSleevedDuel',function()
    local src=source;local now=os.time();if refreshed[src] and now-refreshed[src]<2 then return end
    refreshed[src]=now;Duel.Refresh(src)
end)
AddEventHandler('playerDropped',function() refreshed[source]=nil end)
