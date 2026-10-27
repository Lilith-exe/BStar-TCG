local QBCore = exports['qb-core']:GetCoreObject()
local config, locks, sessions, epochs = BStarPackConfig, BStarStorageLocks, {}, {}
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end
local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function compact(items)
    local list = {}
    for _, item in pairs(items or {}) do
        list[#list + 1] = { name = item.name, amount = item.amount, info = copy(item.info or {}), type = item.type, slot = item.slot }
    end
    table.sort(list, function(a, b) return a.slot < b.slot end)
    return list
end
local function getPlayer(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    return { PlayerData = player.PlayerData, Functions = player.Functions, _bstarPackEpoch = epochs[src] or 0 }
end
local function live(player)
    local latest = getPlayer(player.PlayerData.source)
    -- Export/function-reference returns are snapshots, not stable Lua table identities.
    if latest and latest.PlayerData.citizenid == player.PlayerData.citizenid and
        latest.PlayerData.license == player.PlayerData.license and latest._bstarPackEpoch == player._bstarPackEpoch then
        return latest
    end
end
local function current(player) return live(player) ~= nil end
local function items(player)
    local latest = live(player)
    assert(latest, 'Player disconnected or changed character')
    return latest.PlayerData.items or {}
end
local function packAt(player, slot)
    for _, item in pairs(items(player)) do if item.slot == slot then return item end end
end
local function remaining(player, row)
    local item = packAt(player, tonumber(row.pack_slot))
    return item and item.name == row.pack_item and equal(item.info or {}, json.decode(row.pack_info)) and item.amount or 0
end
local function void(row)
    assert(MySQL.update.await("UPDATE bstar_pack_openings SET status='void', previous_id=NULL WHERE id=? AND status='prepared'", { row.id }) == 1, 'Could not void prepared opening')
end
local function persist(player, row, inventory)
    -- Same SQL transaction records both inventory and completion. qb-inventory SaveInventory is fire-and-forget.
    local queries = BStarBulk.packQueries(row)
    queries[#queries+1] = { query = 'UPDATE players SET inventory=? WHERE citizenid=?', values = { json.encode(inventory), row.citizenid } }
    queries[#queries+1] = { query = "UPDATE bstar_pack_openings SET status='complete' WHERE id=? AND citizenid=? AND status='prepared'", values = { row.id, row.citizenid } }
    local saved = MySQL.transaction.await(queries)
    -- Other resources do not share our mutex. Never overwrite their in-memory changes or retry grants blindly.
    if saved and current(player) and not equal(inventory, compact(items(player))) then
        MySQL.update.await("UPDATE bstar_pack_openings SET status='review', review_inventory=? WHERE id=?", { json.encode(compact(items(player))), row.id })
        return false
    end
    return saved
end
local function payload(player, row)
    local roll, cards = json.decode(row.rewards), {}
    for i, reward in ipairs(roll.rewards) do
        local card = Cards[reward.cardId]
        if not card then error('A recorded reward is missing from the catalogue: ' .. reward.cardId) end
        cards[i] = { id = reward.cardId, cardId = reward.cardId, name = card.name, rarity = card.rarity,
            type = card.type, attack = card.attack, defense = card.defense, speed = card.speed,
            effectText = card.effectText, inventoryImage = card.inventoryImage, slot = i,
            copyId = roll.storage and roll.storage.mode=='physical' and (row.id..':'..i) or nil,
            sleeveContext = roll.storage and roll.storage.mode=='physical' and {location='pile',id=roll.storage.id} or nil }
        if BStarCardPresentation and cards[i].copyId then
            local copy=MySQL.single.await("SELECT * FROM bstar_card_copies WHERE id=?",{cards[i].copyId})
            if copy and copy.location=='pile' and copy.container_id==roll.storage.id then BStarCardPresentation.apply(cards[i],json.decode(copy.info)) end
        end
    end
    row.source = player.PlayerData.source
    sessions[row.citizenid] = row
    return { ok = true, id = row.id, cards = cards, god = roll.god, remaining = remaining(player, row),
        label = (config.sets[row.pack_set] or {}).label or 'BStar Card Pack', recovered = row.recovered == true,
        pileId = roll.storage and roll.storage.id, pilePending = roll.storage and roll.storage.pending==true }
end
local function recover(player)
    local rows = MySQL.query.await("SELECT * FROM bstar_pack_openings WHERE citizenid=? AND status IN ('prepared','review') ORDER BY created_at, id", { player.PlayerData.citizenid })
    for _, row in ipairs(rows) do
        if not current(player) then error('Player disconnected') end
        if row.status == 'review' then return nil, 'A pack opening needs recovery review: ' .. row.id end
        local inventory, receipts = compact(items(player)), {}
        for _, item in pairs(items(player)) do
            local info = type(item.info) == 'table' and item.info or {}
            if item.name == 'bstar_card' and info.packOpeningId == row.id then receipts[info.packPull] = info.cardId end
        end
        local roll, all = json.decode(row.rewards), true
        for i, reward in ipairs(roll.rewards) do if receipts[i] ~= reward.cardId then all = false end end
        if equal(inventory, json.decode(row.after_inventory)) or all then
            if not persist(player, row, inventory) then error('Recovery persistence failed') end
        elseif equal(inventory, json.decode(row.before_inventory)) then
            local database = MySQL.single.await('SELECT inventory FROM players WHERE citizenid=?', { row.citizenid })
            if not current(player) then error('Player disconnected') end
            local stored = database and json.decode(database.inventory or '[]')
            if equal(inventory, compact(items(player))) and
                (equal(stored, json.decode(row.before_inventory)) or equal(stored, json.decode(row.db_before_inventory))) then
                -- Neither live nor saved inventory contains the grant: no consumption survived.
                void(row)
            else
                MySQL.update.await("UPDATE bstar_pack_openings SET status='review' WHERE id=? AND status='prepared'", { row.id })
                return nil, 'Pack recovery is preserved for review: ' .. row.id
            end
        else
            MySQL.update.await("UPDATE bstar_pack_openings SET status='review' WHERE id=? AND status='prepared'", { row.id })
            return nil, 'Pack recovery is preserved for review: ' .. row.id
        end
    end
    local row = MySQL.single.await("SELECT * FROM bstar_pack_openings WHERE citizenid=? AND status='complete' AND viewed=0 ORDER BY created_at DESC, id DESC LIMIT 1", { player.PlayerData.citizenid })
    if row then row.recovered = true end
    return row
end
local function createOpening(player, slot, previous)
    local src, citizenid = player.PlayerData.source, player.PlayerData.citizenid
    local item, definition = packAt(player, slot), config.sets.standard
    if not item or item.name ~= config.standardItem or item.amount < 1 then return { ok = false, error = 'No pack remains in that stack.' } end
    if previous and (slot ~= tonumber(previous.pack_slot) or not equal(item.info or {}, json.decode(previous.pack_info))) then
        return { ok = false, error = 'The pack stack has moved or changed. Use it from inventory again.' }
    end
    if not BStarBulk.ready then return {ok=false,code='storage_unavailable',error=BStarBulk.error} end
    local usedSlots, free = exports['qb-inventory']:GetSlots(src)
    local before, original = compact(items(player)), copy(items(player))
    local roll, failure = BStarPackRules.roll(definition, Cards)
    if not roll then return { ok = false, error = failure } end
    local database = MySQL.single.await('SELECT UUID() AS id, inventory FROM players WHERE citizenid=?', { citizenid })
    if not database or not current(player) then error('Player persistence unavailable') end
    if not equal(before, compact(items(player))) then return { ok = false, error = 'Inventory changed; please try again.' } end
    local planned = copy(items(player))
    for key, value in pairs(planned) do
        if value.slot == slot then value.amount = value.amount - 1; if value.amount == 0 then planned[key] = nil end; break end
    end
    roll.storage = BStarBulk.plan(player, database.id, planned, usedSlots + free)
    local now = os.time()
    for i, reward in ipairs(roll.rewards) do
        reward.info = DeckBox.BuildCardItemInfo(reward.cardId)
        if BStarSleeves then BStarSleeves.initialInfo(reward.info) end
        reward.info.copyId = database.id .. ':' .. i
        reward.info.packOpeningId, reward.info.packPull = database.id, i
        reward.info.acquiredAt, reward.info.pileEnteredAt = now, now
        reward.info.pileGraceUntil = now + (BStarConditionConfig and BStarConditionConfig.bulk.graceSeconds or 3*60*60)
        if BStarConditionRules then BStarConditionRules.initialise(reward.info,now);BStarConditionRules.mark(reward.info,'pile',now) end
    end
    if not equal(before, compact(items(player))) then return {ok=false,error='Inventory changed; pack not consumed.'} end
    local row = { id = database.id, citizenid = citizenid, pack_item = item.name, pack_slot = slot,
        pack_info = json.encode(item.info or {}), pack_set = 'standard', rewards = json.encode(roll),
        before_inventory = json.encode(before), after_inventory = json.encode(compact(planned)) }
    -- Durable write-ahead record BEFORE consuming anything, including all six ordered rewards and receipts.
    local inserted = MySQL.insert.await([[INSERT INTO bstar_pack_openings
        (id,citizenid,previous_id,pack_item,pack_slot,pack_info,pack_set,rewards,before_inventory,after_inventory,db_before_inventory)
        VALUES (?,?,NULLIF(?,''),?,?,?,?,?,?,?,?)]], { row.id, citizenid, previous and previous.id or '', row.pack_item,
        slot, row.pack_info, row.pack_set, row.rewards, row.before_inventory, row.after_inventory, database.inventory or '[]' })
    assert(inserted ~= nil and inserted ~= false, 'Journal insert failed; pack not consumed')
    if not current(player) then error('Player disconnected; opening is recoverable') end
    if not equal(before, compact(items(player))) then void(row); return { ok = false, error = 'Inventory changed; pack not consumed.' } end
    -- Inspected inventory APIs do not yield: mutation/rollback stays within one Lua turn.
    local ok, changed = pcall(function()
        assert(exports['qb-inventory']:RemoveItem(src, item.name, 1, slot, 'bstar-pack:' .. row.id), 'Pack removal failed')
        if roll.storage.slot then
            local slot, pile = roll.storage.slot, roll.storage
            local existing = packAt(player, slot)
            if existing then
                assert(existing.name == BStarBulk.item and existing.info.id == pile.id, 'Pile changed')
                local inventory = copy(items(player))
                for _, value in pairs(inventory) do if value.slot == slot then value.info = BStarBulk.pileInfo(pile.id, planned[slot].info.count) end end
                player.Functions.SetPlayerData('items', inventory)
            else
                assert(exports['qb-inventory']:AddItem(src, BStarBulk.item, 1, slot, planned[slot].info, 'bstar-pack:' .. row.id), 'Pile delivery failed')
            end
        end
        return compact(items(player))
    end)
    if not ok then
        player.Functions.SetPlayerData('items', original)
        void(row)
        return { ok = false, error = 'Inventory rejected the opening. Your pack was preserved.' }
    end
    assert(equal(changed, json.decode(row.after_inventory)), 'Unexpected inventory grant result; journal preserved')
    if not persist(player, row, changed) then error('Inventory save failed; opening journal preserved') end
    if not current(player) then return { ok = false, error = 'Opening saved. Resume it after reconnecting.' } end
    row.status = 'complete'
    return payload(player, row)
end
local function locked(src, fn)
    if not BStarBulk.ready then return {ok=false,code='storage_unavailable',error=BStarBulk.error} end
    local player = getPlayer(src)
    if not player then return { ok = false, error = 'Player unavailable.' } end
    local cid = player.PlayerData.citizenid
    if locks[cid] then return { ok = false, error = 'A pack request is already being processed.' } end
    locks[cid] = true
    local ok, result = pcall(function()
        if BStarBulk.ready then BStarBulk.recoverMoves(player) end
        return fn(player)
    end)
    BStarBulk.releasePiles(cid)
    locks[cid] = nil
    if not current(player) then return { ok = false, error = 'Player disconnected. Any completed opening remains saved.' } end
    if not ok then
        print('[BStar packs] Recoverable opening error for ' .. cid .. ': ' .. tostring(result))
        return { ok = false, error = 'Pack processing interrupted. Use /bstarpacks to recover before opening another pack.' }
    end
    return result
end

if config.registerItem then
    local existing = QBCore.Shared.Items[config.standardItem]
    if not existing then
        QBCore.Functions.AddItem(config.standardItem, { name = config.standardItem, label = config.sets.standard.label,
            weight = 0, type = 'item', image = config.itemImage, unique = false, useable = true, shouldClose = true,
            description = 'Six BStar cards. Right-click and Use to open one pack.' })
    elseif existing.image ~= config.itemImage or existing.label ~= config.sets.standard.label then
        local updated = copy(existing)
        updated.image = config.itemImage
        updated.label = config.sets.standard.label
        QBCore.Functions.UpdateItem(config.standardItem, updated)
    end
end
QBCore.Functions.CreateUseableItem(config.standardItem, function(src, item)
    local player = getPlayer(src)
    if not player then return end
    for _, duel in pairs(Duel and Duel.Active or {}) do
        if duel.status ~= 'finished' then
            for _, participant in pairs(duel.players or {}) do
                if participant.source == src then
                    TriggerClientEvent('QBCore:Notify', src, 'Finish your duel before opening packs.', 'error'); return
                end
            end
        end
    end
    if locks[player.PlayerData.citizenid] or sessions[player.PlayerData.citizenid] then
        TriggerClientEvent('QBCore:Notify', src, 'Finish or exit the current pack opening first.', 'error'); return
    end
    if not BStarBulk.ready then
        TriggerClientEvent('QBCore:Notify',src,BStarBulk.error,'error');return
    end
    exports['qb-inventory']:CloseInventory(src)
    TriggerClientEvent('bstar_cards:client:packPending', src)
    local result = locked(src, function(p)
        local row, problem = recover(p)
        if problem then return { ok = false, error = problem } end
        if not current(p) then error('Player disconnected') end
        return row and payload(p, row) or createOpening(p, tonumber(item.slot))
    end)
    if current(player) then TriggerClientEvent('bstar_cards:client:packResult', src, result) end
end)
QBCore.Functions.CreateCallback('bstar_cards:server:packNext', function(src, cb, id)
    cb(locked(src, function(player)
        local previous = sessions[player.PlayerData.citizenid]
        if not previous or previous.id ~= id or previous.viewed ~= 1 then return { ok = false, error = 'This pack session cannot open another pack.' } end
        local pending, problem = recover(player)
        if problem then return { ok = false, error = problem } end
        if pending then return payload(player, pending) end
        if not current(player) then error('Player disconnected') end
        return createOpening(player, tonumber(previous.pack_slot), previous)
    end))
end)
QBCore.Functions.CreateCallback('bstar_cards:server:packViewed', function(src, cb, id)
    cb(locked(src, function(player)
        local row = sessions[player.PlayerData.citizenid]
        if not row or row.id ~= id then return { ok = false, error = 'Pack session closed.' } end
        MySQL.update.await("UPDATE bstar_pack_openings SET viewed=1 WHERE id=? AND citizenid=? AND status='complete'", { id, row.citizenid })
        row.viewed = 1
        return { ok = true, remaining = remaining(player, row) }
    end))
end)
QBCore.Functions.CreateCallback('bstar_cards:server:packResume', function(src, cb)
    cb(locked(src, function(player)
        local row, problem = recover(player)
        if problem then return { ok = false, error = problem } end
        if not current(player) then error('Player disconnected') end
        return row and payload(player, row) or { ok = false, error = 'No unfinished pack presentation to resume.' }
    end))
end)
RegisterNetEvent('bstar_cards:server:packClose', function(id)
    local player = getPlayer(source)
    if not player then return end
    local row = sessions[player.PlayerData.citizenid]
    if row and row.id == id then sessions[row.citizenid] = nil end
end)
local function clearSessions(src)
    epochs[src] = (epochs[src] or 0) + 1
    for cid, row in pairs(sessions) do
        if row.source == src then sessions[cid] = nil end
    end
end
AddEventHandler('playerDropped', function() clearSessions(source) end)
AddEventHandler('QBCore:Server:OnPlayerUnload', clearSessions)
