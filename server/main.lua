local QBCore = exports['qb-core']:GetCoreObject()

print('[BStar] server/main.lua loading')

DeckBox = {}

local MIN_DECK_CARDS = 30
local MAX_DECK_CARDS = 50
local MAX_COPIES_PER_CARD = 3
local PendingTableDuels = {}
local CardLookupAliases = nil

local function normalizeCardLookupKey(value)
    value = tostring(value or ''):upper()
    value = value:gsub('[^A-Z0-9]+', '_')
    value = value:gsub('_+', '_')
    value = value:gsub('^_', ''):gsub('_$', '')
    return value
end

local function addCardLookupAlias(aliases, alias, card)
    alias = normalizeCardLookupKey(alias)
    if alias ~= '' and not aliases[alias] then
        aliases[alias] = card
    end
end

local function buildCardLookupAliases()
    local aliases = {}
    local nameCounts = {}
    local cardsByName = {}

    for cardId, card in pairs(Cards or {}) do
        addCardLookupAlias(aliases, cardId, card)
        addCardLookupAlias(aliases, card and card.id, card)
        addCardLookupAlias(aliases, card and card.setCode, card)

        local setCode = card and card.setCode or nil
        local name = card and card.name or nil
        if setCode and name then
            addCardLookupAlias(aliases, ("%s_%s"):format(setCode, name), card)
        end

        local nameKey = normalizeCardLookupKey(name)
        if nameKey ~= '' then
            nameCounts[nameKey] = (nameCounts[nameKey] or 0) + 1
            cardsByName[nameKey] = card
        end
    end

    for nameKey, count in pairs(nameCounts) do
        if count == 1 then
            aliases[nameKey] = cardsByName[nameKey]
        end
    end

    return aliases
end

local function ResolveCardDefinition(cardId)
    if Cards and Cards[cardId] then
        return Cards[cardId], cardId
    end

    CardLookupAliases = CardLookupAliases or buildCardLookupAliases()
    local card = CardLookupAliases[normalizeCardLookupKey(cardId)]
    if card then
        return card, card.id or cardId
    end

    local normalized = normalizeCardLookupKey(cardId)
    local nameSuffix = normalized:match('^[A-Z]+%d*_EN%d%d%d_(.+)$')
    if nameSuffix then
        card = CardLookupAliases[nameSuffix]
        if card then
            return card, card.id or cardId
        end
    end

    local setPrefix = normalized:match('^([A-Z]+%d*_EN%d%d%d)')
    if setPrefix then
        card = CardLookupAliases[setPrefix]
        if card then
            return card, card.id or cardId
        end
    end

    return nil, cardId
end

local function getResolvedCardIdentity(cardId)
    local card, resolvedCardId = ResolveCardDefinition(cardId)
    if not card then return nil end
    return card.id or resolvedCardId or cardId
end

local function getCurrentCardId(cardId)
    local resolvedId = getResolvedCardIdentity(cardId)
    if resolvedId and Cards and Cards[resolvedId] then
        return resolvedId
    end
    return nil
end

local function getStoredAmountForCard(storedCards, cardId)
    if not storedCards then return 0 end

    if storedCards[cardId] then
        return tonumber(storedCards[cardId].amount) or 0
    end

    local wantedId = getResolvedCardIdentity(cardId)
    if not wantedId then return 0 end

    local amount = 0
    for storedCardId, storedCard in pairs(storedCards or {}) do
        if getResolvedCardIdentity(storedCardId) == wantedId then
            amount = amount + (tonumber(storedCard and storedCard.amount) or 0)
        end
    end

    return amount
end

local function buildPlaceholders(count)
    local placeholders = {}
    for i = 1, count do
        placeholders[#placeholders + 1] = '?'
    end
    return table.concat(placeholders, ', ')
end

local function normalizeDeckCardMap(cardMap)
    local normalized = {}
    local changed = false
    local removed = 0
    local moved = 0

    for cardId, rawAmount in pairs(cardMap or {}) do
        local amount = tonumber(rawAmount) or 0
        if amount > 0 then
            local currentId = getCurrentCardId(cardId)
            if currentId then
                normalized[currentId] = (normalized[currentId] or 0) + amount
                if tostring(currentId) ~= tostring(cardId) then
                    changed = true
                    moved = moved + 1
                end
            else
                changed = true
                removed = removed + 1
            end
        else
            changed = true
            removed = removed + 1
        end
    end

    for cardId, amount in pairs(normalized) do
        if tonumber(cardMap and cardMap[cardId]) ~= tonumber(amount) then
            changed = true
        end
    end

    return normalized, changed, moved, removed
end

local function GetCardHealthText(card)
    local raw = card and (card.health or card.hp or card.defense or card.def) or nil
    if not raw then return nil end

    return tostring(raw):gsub('^DEF', 'HP')
end

CreateThread(function()
    Wait(0)
    local count = 0
    for _ in pairs(Cards or {}) do
        count = count + 1
    end
    local sample = ResolveCardDefinition('ALPH1_EN001_LAYLA_HART')
    print(('[BStar] Card definitions loaded: %s | Layla sample: %s'):format(count, sample and tostring(sample.name) or 'NOT FOUND'))
end)

local function BuildCardItemInfo(cardId)
    local card, resolvedCardId = ResolveCardDefinition(cardId)

    if not card then
        return {
            cardId = cardId
        }
    end

    return {
        cardId = resolvedCardId or cardId,
        inventoryImage = card.inventoryImage,
        label = card.name,
        rarity = card.rarity,
        type = card.type,
        effectTags = DuelEffects and DuelEffects.GetTags(card) or {},
        continuous = card.continuous == true or card.isContinuous == true,
        setCode = card.setCode,
        edition = card.edition
    }
end

local function getPlayerCardCounts(Player)
    local results = {}

    if not Player or not Player.PlayerData or not Player.PlayerData.items then
        return results
    end

    for _, item in pairs(Player.PlayerData.items) do
        if item and item.name == 'bstar_card' and item.info and item.info.cardId then
            local rawCardId = item.info.cardId
            local amount = item.amount or 1
            local card, resolvedCardId = ResolveCardDefinition(rawCardId)
            local cardId = (card and (card.id or resolvedCardId)) or rawCardId

            if not results[cardId] then
                results[cardId] = {
                    cardId = cardId,
                    amount = 0,
                    inventoryImage = (card and card.inventoryImage) or item.info.inventoryImage or nil,
                    name = (card and card.name) or cardId,

                    rarity = card and card.rarity or nil,
                    type = card and card.type or nil,
                    level = card and card.level or nil,
                    attack = card and (card.attack or card.atk) or nil,
                    defense = card and (card.defense or card.def) or nil,
                    health = GetCardHealthText(card),
                    speed = card and (card.speed or card.spd) or nil,
                    effectTitle = card and card.effectTitle or nil,
                    effectText = card and card.effectText or nil,
                    effectTags = DuelEffects and DuelEffects.GetTags(card) or {},
                    continuous = card and (card.continuous == true or card.isContinuous == true) or false,
                    job = card and card.job or nil,
                    setCode = card and card.setCode or nil,
                    edition = card and card.edition or nil
                }
            end

            results[cardId].amount = results[cardId].amount + amount

            if not results[cardId].inventoryImage and item.info.inventoryImage then
                results[cardId].inventoryImage = item.info.inventoryImage
            end
        end
    end

    return results
end

local function BuildCardCatalog()
    local catalog = {}

    for cardId, card in pairs(Cards or {}) do
        local payload = {
            cardId = cardId,
            id = card.id or cardId,
            name = card.name,
            rarity = card.rarity,
            type = card.type,
            job = card.job,
            level = card.level,
            speed = card.speed or card.spd,
            attack = card.attack or card.atk,
            defense = card.defense or card.def,
            health = GetCardHealthText(card),
            effectTitle = card.effectTitle,
            effectText = card.effectText,
            effectTags = DuelEffects and DuelEffects.GetTags(card) or {},
            continuous = card.continuous == true or card.isContinuous == true,
            setCode = card.setCode,
            edition = card.edition,
            inventoryImage = card.inventoryImage
        }

        catalog[cardId] = payload

        local aliases = {
            card.id,
            card.setCode,
            card.setCode and card.name and ("%s_%s"):format(card.setCode, card.name) or nil
        }

        for _, alias in ipairs(aliases) do
            alias = normalizeCardLookupKey(alias)
            if alias ~= '' and not catalog[alias] then
                catalog[alias] = payload
            end
        end
    end

    return catalog
end

local function validateDeckDataForPlay(deckData, storedCards)
    local issues = {}

    if type(deckData) ~= 'table' then
        return false, 'No deck data', { 'No deck data' }
    end

    if type(deckData.cards) ~= 'table' then
        deckData.cards = {}
    end

    local totalCards = 0

    for cardId, rawAmount in pairs(deckData.cards) do
        local amount = tonumber(rawAmount) or 0

        if amount > 0 then
            totalCards = totalCards + amount

            if not ResolveCardDefinition(cardId) then
                issues[#issues + 1] = 'Unknown card'
            end

            if amount > MAX_COPIES_PER_CARD then
                issues[#issues + 1] = 'Too many copies'
            end

            local storedAmount = getStoredAmountForCard(storedCards, cardId)

            if amount > storedAmount then
                issues[#issues + 1] = 'Missing cards'
            end
        end
    end

    if totalCards < MIN_DECK_CARDS then
        issues[#issues + 1] = 'Too small'
    end

    if totalCards > MAX_DECK_CARDS then
        issues[#issues + 1] = 'Too large'
    end

    local uniqueIssues = {}
    local seen = {}

    for _, issue in ipairs(issues) do
        if not seen[issue] then
            seen[issue] = true
            uniqueIssues[#uniqueIssues + 1] = issue
        end
    end

    if #uniqueIssues > 0 then
        return false, table.concat(uniqueIssues, ', '), uniqueIssues
    end

    return true, 'Legal', {}
end

local function addDeckValidationForPlay(decks, storedCards)
    decks = decks or {}

    for i = 1, #decks do
        local valid, message, issues = validateDeckDataForPlay(decks[i].deck_data, storedCards)
        decks[i].isValid = valid
        decks[i].validationMessage = message
        decks[i].validationIssues = issues
    end

    return decks
end

function DeckBox.GetPlayerCards(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end

    cb(getPlayerCardCounts(Player))
end

function DeckBox.GetStoredCards(source, deckBoxId, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end

    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:query([[
        SELECT card_id, amount
        FROM bstar_deckbox_cards
        WHERE citizenid = ? AND deck_box_id = ?
    ]], { citizenid, deckBoxId }, function(result)
        local cards = {}

        for _, row in pairs(result or {}) do
            local card, resolvedCardId = ResolveCardDefinition(row.card_id)
            local cardId = (card and (card.id or resolvedCardId)) or row.card_id

            if not cards[cardId] then
                cards[cardId] = {
                    cardId = cardId,
                    amount = 0,
                    inventoryImage = card and card.inventoryImage or nil,
                    name = (card and card.name) or row.card_id,

                    rarity = card and card.rarity or nil,
                    type = card and card.type or nil,
                    level = card and card.level or nil,
                    attack = card and (card.attack or card.atk) or nil,
                    defense = card and (card.defense or card.def) or nil,
                    health = GetCardHealthText(card),
                    speed = card and (card.speed or card.spd) or nil,
                    effectTitle = card and card.effectTitle or nil,
                    effectText = card and card.effectText or nil,
                    effectTags = DuelEffects and DuelEffects.GetTags(card) or {},
                    continuous = card and (card.continuous == true or card.isContinuous == true) or false,
                    job = card and card.job or nil,
                    setCode = card and card.setCode or nil,
                    edition = card and card.edition or nil
                }
            end

            cards[cardId].amount = cards[cardId].amount + (tonumber(row.amount) or 0)
        end

        cb(cards)
    end)
end

function DeckBox.StoreCard(source, deckBoxId, cardId, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Player not found')
        return
    end

    local citizenid = Player.PlayerData.citizenid
    local items = Player.PlayerData.items or {}
    local currentCardId = getCurrentCardId(cardId) or cardId

    local foundSlot = nil

    for slot, item in pairs(items) do
        if item
            and item.name == 'bstar_card'
            and item.info
            and getCurrentCardId(item.info.cardId) == currentCardId then
            foundSlot = slot
            break
        end
    end

    if not foundSlot then
        cb(false, 'Card not found in player inventory')
        return
    end

    local removed = Player.Functions.RemoveItem('bstar_card', 1, foundSlot)
    if not removed then
        cb(false, 'Failed to remove card from player inventory')
        return
    end

    exports.oxmysql:query([[
        SELECT id, amount
        FROM bstar_deckbox_cards
        WHERE citizenid = ? AND deck_box_id = ? AND card_id = ?
        LIMIT 1
    ]], { citizenid, deckBoxId, currentCardId }, function(result)
        if result and result[1] then
            exports.oxmysql:update([[
                UPDATE bstar_deckbox_cards
                SET amount = amount + 1
                WHERE id = ?
            ]], { result[1].id }, function()
                cb(true)
            end)
        else
            exports.oxmysql:insert([[
                INSERT INTO bstar_deckbox_cards (citizenid, deck_box_id, card_id, amount)
                VALUES (?, ?, ?, 1)
            ]], { citizenid, deckBoxId, currentCardId }, function()
                cb(true)
            end)
        end
    end)
end

function DeckBox.WithdrawCard(source, deckBoxId, cardId, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Player not found')
        return
    end

    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:query([[
        SELECT id, amount
        FROM bstar_deckbox_cards
        WHERE citizenid = ? AND deck_box_id = ? AND card_id = ?
        LIMIT 1
    ]], { citizenid, deckBoxId, cardId }, function(result)
        if not result or not result[1] then
            cb(false, 'Card not found in deck box')
            return
        end

        local row = result[1]

        local success = Player.Functions.AddItem('bstar_card', 1, false, BuildCardItemInfo(cardId))

        if not success then
            cb(false, 'Failed to add card back to player inventory')
            return
        end

        if row.amount > 1 then
            exports.oxmysql:update([[
                UPDATE bstar_deckbox_cards
                SET amount = amount - 1
                WHERE id = ?
            ]], { row.id }, function()
                cb(true)
            end)
        else
            exports.oxmysql:update([[
                DELETE FROM bstar_deckbox_cards
                WHERE id = ?
            ]], { row.id }, function()
                cb(true)
            end)
        end
    end)
end

local function GetDecksForBox(source, deckBoxId, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end

    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:query([[
        SELECT id, name, deck_data
        FROM bstar_decks
        WHERE citizenid = ? AND deck_box_id = ?
        ORDER BY id ASC
    ]], { citizenid, deckBoxId }, function(result)
        local decks = result or {}

        for i = 1, #decks do
            local raw = decks[i].deck_data
            local decoded = nil

            if raw and raw ~= '' then
                local ok, parsed = pcall(function()
                    return json.decode(raw)
                end)

                if ok and type(parsed) == 'table' then
                    decoded = parsed
                end
            end

            if not decoded or type(decoded) ~= 'table' then
                decoded = {}
            end

            if type(decoded.cards) ~= 'table' then
                decoded.cards = {}
            end

            decks[i].deck_data = decoded
        end

        cb(decks)
    end)
end

local function CreateDeckForBox(source, deckBoxId, deckName, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false)
        return
    end

    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:insert([[
        INSERT INTO bstar_decks (citizenid, deck_box_id, name, deck_data)
        VALUES (?, ?, ?, ?)
    ]], {
        citizenid,
        deckBoxId,
        deckName,
        json.encode({ cards = {} })
    }, function(insertId)
        cb(insertId or false)
    end)
end

local function SaveDeckForBox(source, deckBoxId, deckId, deckName, deckData, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false)
        return
    end

    local citizenid = Player.PlayerData.citizenid

    if not deckData or type(deckData) ~= 'table' then
        deckData = { cards = {} }
    end

    if not deckData.cards or type(deckData.cards) ~= 'table' then
        deckData.cards = {}
    end

    exports.oxmysql:update([[
        UPDATE bstar_decks
        SET name = ?, deck_data = ?
        WHERE id = ? AND citizenid = ? AND deck_box_id = ?
    ]], {
        deckName,
        json.encode(deckData),
        deckId,
        citizenid,
        deckBoxId
    }, function(affectedRows)
        print('[BStar] SaveDeck affectedRows:', affectedRows)
        cb((affectedRows or 0) > 0)
    end)
end

local function DeleteDeckForBox(source, deckBoxId, deckId, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false)
        return
    end

    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:update([[
        DELETE FROM bstar_decks
        WHERE id = ? AND citizenid = ? AND deck_box_id = ?
    ]], {
        deckId,
        citizenid,
        deckBoxId
    }, function(affectedRows)
        cb((affectedRows or 0) > 0)
    end)
end

QBCore.Functions.CreateUseableItem('bstar_card', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if not item or not item.info or not item.info.cardId then
        TriggerClientEvent('QBCore:Notify', source, 'This card has no cardId data.', 'error')
        return
    end

    local cardId = item.info.cardId
    local card = ResolveCardDefinition(cardId)

    if not card then
        TriggerClientEvent('QBCore:Notify', source, 'Card data not found: ' .. tostring(cardId), 'error')
        return
    end

    TriggerClientEvent('bstar_cards:client:showCard', source, {
        id = card.id,
        name = card.name,
        rarity = card.rarity,
        image = 'nui://bstar_cards/html/images/cards/' .. card.inventoryImage
    })
end)

QBCore.Functions.CreateCallback('bstar_cards:server:GetDeckBoxData', function(source, cb, deckBoxId)
    if not DeckBox then
        print('[BStar] ERROR: DeckBox is nil in GetDeckBoxData')
        cb({
            playerCards = {},
            storedCards = {}
        })
        return
    end

    DeckBox.GetPlayerCards(source, function(playerCards)
        DeckBox.GetStoredCards(source, deckBoxId, function(storedCards)
            cb({
                playerCards = playerCards,
                storedCards = storedCards
            })
        end)
    end)
end)

QBCore.Functions.CreateCallback('bstar_cards:server:GetDeckBuilderData', function(source, cb, deckBoxId)
    DeckBox.GetStoredCards(source, deckBoxId, function(storedCards)
        GetDecksForBox(source, deckBoxId, function(decks)
            decks = addDeckValidationForPlay(decks, storedCards)

            cb({
                storedCards = storedCards,
                decks = decks,
                cardCatalog = BuildCardCatalog()
            })
        end)
    end)
end)

QBCore.Functions.CreateCallback('bstar_cards:server:GetDecksForTestDuel', function(source, cb, deckBoxId)
    print('[BStar Duel] GetDecksForTestDuel called')
    print('[BStar Duel] source:', source)
    print('[BStar Duel] deckBoxId:', deckBoxId)

    DeckBox.GetStoredCards(source, deckBoxId, function(storedCards)
        GetDecksForBox(source, deckBoxId, function(decks)
            decks = addDeckValidationForPlay(decks, storedCards)

            print('[BStar Duel] decks found:', #decks)
            cb(decks)
        end)
    end)
end)

RegisterNetEvent('bstar_cards:server:StoreCardInDeckBox', function(deckBoxId, cardId)
    local src = source

    DeckBox.StoreCard(src, deckBoxId, cardId, function(success, err)
        if success then
            TriggerClientEvent('QBCore:Notify', src, 'Card stored in deck box.', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, err or 'Failed to store card.', 'error')
        end
    end)
end)

RegisterNetEvent('bstar_cards:server:WithdrawCardFromDeckBox', function(deckBoxId, cardId)
    local src = source

    DeckBox.WithdrawCard(src, deckBoxId, cardId, function(success, err)
        if success then
            TriggerClientEvent('QBCore:Notify', src, 'Card withdrawn from deck box.', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, err or 'Failed to withdraw card.', 'error')
        end
    end)
end)

RegisterNetEvent('bstar_cards:server:DevFillDeckBox', function(deckBoxId)
    local src = source

    if Config and Config.Debug ~= true then
        TriggerClientEvent('QBCore:Notify', src, 'BStar dev commands are disabled.', 'error')
        return
    end

    deckBoxId = tostring(deckBoxId or '')
    if deckBoxId == '' then
        TriggerClientEvent('QBCore:Notify', src, 'Missing deck box id.', 'error')
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local cardIds = {}

    for cardId in pairs(Cards or {}) do
        cardIds[#cardIds + 1] = cardId
    end

    table.sort(cardIds)

    if #cardIds == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'No BStar card definitions found.', 'error')
        return
    end

    exports.oxmysql:update([[
        DELETE FROM bstar_deckbox_cards
        WHERE citizenid = ? AND deck_box_id = ?
    ]], { citizenid, deckBoxId }, function()
        local placeholders = {}
        local params = {}

        for _, cardId in ipairs(cardIds) do
            placeholders[#placeholders + 1] = '(?, ?, ?, ?)'
            params[#params + 1] = citizenid
            params[#params + 1] = deckBoxId
            params[#params + 1] = cardId
            params[#params + 1] = 3
        end

        exports.oxmysql:insert(([[
            INSERT INTO bstar_deckbox_cards (citizenid, deck_box_id, card_id, amount)
            VALUES %s
        ]]):format(table.concat(placeholders, ', ')), params, function()
            TriggerClientEvent('QBCore:Notify', src, ('Deck box filled with 3 copies of %s cards.'):format(#cardIds), 'success')
        end)
    end)
end)

RegisterNetEvent('bstar_cards:server:CreateDeck', function(deckBoxId, deckName)
    local src = source

    CreateDeckForBox(src, deckBoxId, deckName, function(success)
        if success then
            TriggerClientEvent('QBCore:Notify', src, 'Deck created.', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Failed to create deck.', 'error')
        end
    end)
end)

RegisterNetEvent('bstar_cards:server:SaveDeck', function(deckBoxId, deckId, deckName, deckData)
    local src = source

    print('[BStar] SaveDeck called')
    print('[BStar] deckBoxId:', deckBoxId)
    print('[BStar] deckId:', deckId)
    print('[BStar] deckName:', deckName)
    print('[BStar] deckData:', json.encode(deckData))

    SaveDeckForBox(src, deckBoxId, deckId, deckName, deckData, function(success)
        print('[BStar] SaveDeck success:', success)

        if success then
            TriggerClientEvent('QBCore:Notify', src, 'Deck saved.', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Failed to save deck.', 'error')
        end
    end)
end)

RegisterNetEvent('bstar_cards:server:DeleteDeck', function(deckBoxId, deckId)
    local src = source

    DeleteDeckForBox(src, deckBoxId, deckId, function(success)
        if success then
            TriggerClientEvent('QBCore:Notify', src, 'Deck deleted.', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Failed to delete deck.', 'error')
        end
    end)
end)


RegisterCommand('givedeckbox', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    -- generate unique ID
    local uniqueId = "DB-" .. os.time() .. "-" .. math.random(1000, 9999)

    local success = Player.Functions.AddItem('deck_box', 1, false, {
        id = uniqueId
    })

    if success then
        TriggerClientEvent('QBCore:Notify', src, 'Deck box received!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Inventory full!', 'error')
    end
end, false)

local function FindFirstDeckBoxItem(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end

    for _, item in pairs(Player.PlayerData.items or {}) do
        if item and item.name == 'deck_box' and item.info and item.info.id then
            return item
        end
    end

    return nil
end

RegisterCommand('bstaropenbox', function(source)
    local src = source
    local item = FindFirstDeckBoxItem(src)

    if not item then
        TriggerClientEvent('QBCore:Notify', src, 'No deck box found in your inventory.', 'error')
        return
    end

    TriggerClientEvent('bstar_cards:client:UseDeckBox', src, item)
end, false)

RegisterNetEvent('bstar_cards:server:SaveDeckBox', function(stashId, items)
    if not stashId or not items then return end

    exports.oxmysql:update([[
        UPDATE inventories
        SET items = ?
        WHERE identifier = ?
    ]], {
        json.encode(items),
        stashId
    })
end)

RegisterNetEvent('bstar_cards:server:OpenDeckBoxStash', function(deckBoxId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not deckBoxId then return end

    local stashId = "deckbox_" .. deckBoxId

    exports.oxmysql:query('SELECT items FROM inventories WHERE identifier = ?', { stashId }, function(result)
        local stashItems = {}

        if result and result[1] and result[1].items then
            stashItems = json.decode(result[1].items) or {}
        end

        local formattedInventory = {
            name = stashId,
            label = "Deck Box",
            maxweight = 150000,
            slots = 120,
            inventory = stashItems
        }

        TriggerClientEvent('qb-inventory:client:openInventory', src, Player.PlayerData.items, formattedInventory)
    end)
end)

QBCore.Functions.CreateUseableItem('deck_box', function(source, item)
    print('[BStar] deck_box used by source:', source)
    print('[BStar] item info:', json.encode(item))

    TriggerClientEvent('bstar_cards:client:UseDeckBox', source, item)
end)

print('[BStar] deck_box usable item registered')

local function GetDeckByIdForPlayer(source, deckBoxId, deckId, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil)
        return
    end

    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:query([[
        SELECT id, name, deck_data
        FROM bstar_decks
        WHERE id = ? AND citizenid = ? AND deck_box_id = ?
        LIMIT 1
    ]], { deckId, citizenid, deckBoxId }, function(result)
        local row = result and result[1]
        if not row then
            cb(nil)
            return
        end

        local decoded = {}
        if row.deck_data and row.deck_data ~= '' then
            local ok, parsed = pcall(function()
                return json.decode(row.deck_data)
            end)
            if ok and type(parsed) == 'table' then
                decoded = parsed
            end
        end

        if type(decoded.cards) ~= 'table' then
            decoded.cards = {}
        end

        cb({
            id = row.id,
            name = row.name,
            deck_data = decoded
        })
    end)
end

local function notifyDuelPlayers(duel, message, notifyType)
    local sentToSource = {}

    for _, playerState in pairs(duel and duel.players or {}) do
        local targetSrc = playerState.source
        if targetSrc and not sentToSource[targetSrc] then
            TriggerClientEvent('QBCore:Notify', targetSrc, message, notifyType or 'primary')
            sentToSource[targetSrc] = true
        end
    end
end

local function sendTableViewToDuelPlayers(duel)
    if not duel or not duel.tableId then return end

    local sentToSource = {}
    for _, playerState in pairs(duel.players or {}) do
        local targetSrc = playerState.source
        if targetSrc and not sentToSource[targetSrc] then
            TriggerClientEvent('bstar_cards:client:EnterDuelTableView', targetSrc, duel.tableId)
            sentToSource[targetSrc] = true
        end
    end
end

local function clearPendingTableDuelForSource(src)
    for tableId, pending in pairs(PendingTableDuels) do
        if pending.source == src then
            PendingTableDuels[tableId] = nil
        end
    end
end

local function startDuelAfterCoin(duelId, firstPlayer, src, successMessage)
    local ok, startErr = Duel.Start(duelId, firstPlayer)
    print('[BStar Duel] Duel.Start after coin result:', ok, startErr)

    if not ok then
        TriggerClientEvent('QBCore:Notify', src, startErr or 'Failed to start duel.', 'error')
        return false
    end

    local duel = Duel.GetById(duelId)
    notifyDuelPlayers(duel, successMessage or 'Duel started.', 'success')
    return true
end

local function openCoinFlipForDuel(src, duel, tableMode)
    duel.coinFlip = {
        chooser = 1,
        starterSource = src
    }

    local sentToSource = {}
    TriggerClientEvent('bstar_cards:client:OpenCoinFlip', src, {
        duelId = duel.id,
        tableMode = tableMode == true,
        tableId = duel.tableId,
        canChooseCoin = true,
        soloMode = duel.soloMode == true
    })
    sentToSource[src] = true

    for _, playerState in pairs(duel.players or {}) do
        local targetSrc = playerState.source
        if targetSrc and not sentToSource[targetSrc] then
            TriggerClientEvent('bstar_cards:client:OpenCoinFlip', targetSrc, {
                duelId = duel.id,
                tableMode = tableMode == true,
                tableId = duel.tableId,
                canChooseCoin = false,
                soloMode = duel.soloMode == true
            })
            sentToSource[targetSrc] = true
        end
    end

    notifyDuelPlayers(duel, 'Duel matched. Player 1 is calling the coin toss.', 'primary')
end

RegisterNetEvent('bstar_cards:server:DuelChooseCoin', function(duelId, choice)
    local src = source
    local duel = Duel.GetById(duelId)
    if not duel then
        TriggerClientEvent('QBCore:Notify', src, 'Duel not found.', 'error')
        return
    end

    if duel.started then
        return
    end

    local chooserIndex = duel.coinFlip and duel.coinFlip.chooser or 1
    if not duel.players[chooserIndex] or duel.players[chooserIndex].source ~= src then
        TriggerClientEvent('QBCore:Notify', src, 'Waiting for the coin toss caller.', 'error')
        return
    end

    choice = tostring(choice or ''):lower()
    if choice ~= 'heads' and choice ~= 'tails' then
        TriggerClientEvent('QBCore:Notify', src, 'Pick heads or tails.', 'error')
        return
    end

    local result = math.random(1, 2) == 1 and 'heads' or 'tails'
    local playerWon = result == choice

    duel.coinFlip = duel.coinFlip or {}
    duel.coinFlip.choice = choice
    duel.coinFlip.result = result
    duel.coinFlip.playerWon = playerWon

    TriggerClientEvent('bstar_cards:client:CoinFlipResult', src, {
        choice = choice,
        result = result,
        playerWon = playerWon,
        canChooseTurnOrder = playerWon,
        soloMode = duel.soloMode == true
    })

    if not playerWon then
        local message = duel.soloMode == true
            and 'Solo opponent won the toss and chose to go first.'
            or 'Opponent won the toss and chose to go first.'

        CreateThread(function()
            Wait(1800)
            if duel and not duel.started then
                startDuelAfterCoin(duel.id, 2, src, message)
            end
        end)
    end
end)

RegisterNetEvent('bstar_cards:server:DuelChooseTurnOrder', function(duelId, choice)
    local src = source
    local duel = Duel.GetById(duelId)
    if not duel then
        TriggerClientEvent('QBCore:Notify', src, 'Duel not found.', 'error')
        return
    end

    if duel.started then
        return
    end

    local chooserIndex = duel.coinFlip and duel.coinFlip.chooser or 1
    if not duel.players[chooserIndex] or duel.players[chooserIndex].source ~= src then
        TriggerClientEvent('QBCore:Notify', src, 'Waiting for the coin toss caller.', 'error')
        return
    end

    if not duel.coinFlip or duel.coinFlip.playerWon ~= true then
        TriggerClientEvent('QBCore:Notify', src, 'You did not win the coin toss.', 'error')
        return
    end

    choice = tostring(choice or ''):lower()
    local firstPlayer = choice == 'second' and 2 or 1
    startDuelAfterCoin(duel.id, firstPlayer, src, firstPlayer == 1 and 'You chose to go first.' or 'You chose to go second.')
end)

RegisterNetEvent('bstar_cards:server:StartTestDuel', function(deckBoxId, myDeckId, opponentDeckId)
    local src = source

    print('[BStar Duel] StartTestDuel called')
    print('[BStar Duel] src:', src)
    print('[BStar Duel] deckBoxId:', deckBoxId)
    print('[BStar Duel] myDeckId:', myDeckId)
    print('[BStar Duel] opponentDeckId:', opponentDeckId)

    GetDeckByIdForPlayer(src, deckBoxId, myDeckId, function(deckA)
        if not deckA then
            print('[BStar Duel] Failed to load deckA')
            TriggerClientEvent('QBCore:Notify', src, 'Could not load your deck.', 'error')
            return
        end

        DeckBox.GetStoredCards(src, deckBoxId, function(storedCards)
            local valid, message = validateDeckDataForPlay(deckA.deck_data, storedCards)
            if not valid then
                TriggerClientEvent('QBCore:Notify', src, 'Deck is invalid: ' .. tostring(message), 'error')
                return
            end

            -- TEMP SOLO TEST: same deck on both sides
            local deckB = deckA

            local duel, err = Duel.Create(src, src, deckA, deckB)
            if not duel then
                print('[BStar Duel] Duel.Create failed:', err)
                TriggerClientEvent('QBCore:Notify', src, err or 'Failed to create duel.', 'error')
                return
            end

            print('[BStar Duel] Duel created:', duel.id)

            openCoinFlipForDuel(src, duel, false)
        end)
    end)
end)

RegisterNetEvent('bstar_cards:server:StartTableTestDuel', function(tableId, deckBoxId, myDeckId)
    local src = source

    print('[BStar Table Duel] StartTableTestDuel fired')
    print('[BStar Table Duel] src:', src)
    print('[BStar Table Duel] tableId:', tableId)
    print('[BStar Table Duel] deckBoxId:', deckBoxId)
    print('[BStar Table Duel] myDeckId:', myDeckId)

    GetDeckByIdForPlayer(src, deckBoxId, myDeckId, function(deckA)
        print('[BStar Table Duel] GetDeckByIdForPlayer callback, deckA exists:', deckA ~= nil)

        if not deckA then
            TriggerClientEvent('QBCore:Notify', src, 'Could not load your deck.', 'error')
            return
        end

        DeckBox.GetStoredCards(src, deckBoxId, function(storedCards)
            local valid, message = validateDeckDataForPlay(deckA.deck_data, storedCards)
            if not valid then
                TriggerClientEvent('QBCore:Notify', src, 'Deck is invalid: ' .. tostring(message), 'error')
                return
            end

            local pending = PendingTableDuels[tableId]
            if pending and pending.source == src then
                TriggerClientEvent('QBCore:Notify', src, 'You are already waiting at this duel table.', 'primary')
                return
            end

            clearPendingTableDuelForSource(src)

            if pending then
                PendingTableDuels[tableId] = nil

                local duel, err = Duel.Create(pending.source, src, pending.deck, deckA)
                print('[BStar Table Duel] Duel.Create result:', duel and duel.id or nil, err)

                if not duel then
                    TriggerClientEvent('QBCore:Notify', src, err or 'Failed to create duel.', 'error')
                    TriggerClientEvent('QBCore:Notify', pending.source, err or 'Failed to create duel.', 'error')
                    return
                end

                duel.tableId = tableId

                print('[BStar Table Duel] Matched players:', pending.source, src, 'table:', tableId)
                sendTableViewToDuelPlayers(duel)
                openCoinFlipForDuel(pending.source, duel, true)
                return
            end

            PendingTableDuels[tableId] = {
                tableId = tableId,
                source = src,
                deckBoxId = deckBoxId,
                deckId = myDeckId,
                deck = deckA,
                createdAt = os.time()
            }

            print('[BStar Table Duel] Player waiting at table:', src, tableId)
            TriggerClientEvent('QBCore:Notify', src, 'Waiting for another player to join this duel table.', 'primary')
        end)
    end)
end)

RegisterNetEvent('bstar_cards:server:StartTableSoloTestDuel', function(tableId, deckBoxId, myDeckId)
    local src = source

    print('[BStar Table Solo Duel] StartTableSoloTestDuel fired')
    print('[BStar Table Solo Duel] src:', src)
    print('[BStar Table Solo Duel] tableId:', tableId)
    print('[BStar Table Solo Duel] deckBoxId:', deckBoxId)
    print('[BStar Table Solo Duel] myDeckId:', myDeckId)

    GetDeckByIdForPlayer(src, deckBoxId, myDeckId, function(deckA)
        print('[BStar Table Solo Duel] GetDeckByIdForPlayer callback, deckA exists:', deckA ~= nil)

        if not deckA then
            TriggerClientEvent('QBCore:Notify', src, 'Could not load your deck.', 'error')
            return
        end

        DeckBox.GetStoredCards(src, deckBoxId, function(storedCards)
            local valid, message = validateDeckDataForPlay(deckA.deck_data, storedCards)
            if not valid then
                TriggerClientEvent('QBCore:Notify', src, 'Deck is invalid: ' .. tostring(message), 'error')
                return
            end

            clearPendingTableDuelForSource(src)

            local duel, err = Duel.Create(src, src, deckA, deckA)
            print('[BStar Table Solo Duel] Duel.Create result:', duel and duel.id or nil, err)

            if not duel then
                TriggerClientEvent('QBCore:Notify', src, err or 'Failed to create duel.', 'error')
                return
            end

            duel.tableId = tableId

            TriggerClientEvent('bstar_cards:client:EnterDuelTableView', src, tableId)
            openCoinFlipForDuel(src, duel, true)
        end)
    end)
end)

AddEventHandler('playerDropped', function()
    clearPendingTableDuelForSource(source)
end)

RegisterNetEvent('bstar_cards:server:DuelAdvancePhase', function(duelId)
    local src = source
    local ok, err = Duel.AdvancePhase(src, duelId)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelEndTurn', function(duelId)
    local src = source
    local ok, err = Duel.EndTurn(src, duelId)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelDiscardCard', function(duelId, handUid)
    local src = source
    local ok, err = Duel.DiscardFromHand(src, duelId, handUid)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelSurrender', function(duelId)
    local src = source
    local ok, err = Duel.Surrender(src, duelId)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelDrawCard', function(duelId)
    local src = source
    local ok, err = Duel.DrawForTurn(src, duelId)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelSummonFighter', function(duelId, handUid, zoneIndex)
    local src = source
    local ok, err = Duel.SummonFighter(src, duelId, handUid, zoneIndex)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelPromoteFighter', function(duelId, handUid, tributeZoneIndex)
    local src = source
    local ok, err = Duel.PromoteFighter(src, duelId, handUid, tributeZoneIndex)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelPlayNonFighter', function(duelId, handUid, targetKind, zoneIndex)
    local src = source
    local ok, err = Duel.PlayNonFighter(src, duelId, handUid, targetKind, zoneIndex)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelResolvePendingEffect', function(duelId, promptId, accepted, response)
    local src = source
    local ok, err = Duel.ResolvePendingEffect(src, duelId, promptId, accepted == true, response)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelResolvePendingSelection', function(duelId, selectionId, selectedUid, selectedUids)
    local src = source
    local ok, err = Duel.ResolvePendingSelection(src, duelId, selectionId, selectedUid, selectedUids)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelActivateEffect', function(duelId, sourceUid)
    local src = source
    local ok, err = Duel.ActivateEffect(src, duelId, sourceUid)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelAttack', function(duelId, attackerZoneIndex, targetType, targetZoneIndex)
    local src = source
    local ok, err = Duel.Attack(src, duelId, attackerZoneIndex, targetType, targetZoneIndex)

    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    end
end)

RegisterNetEvent('bstar_cards:server:DuelDebugSpawnFighter', function(duelId, playerIndex, cardId, zoneIndex)
    local src = source

    local ok, err = Duel.DebugSpawnFighter(duelId, playerIndex, cardId, zoneIndex)
    if not ok and err then
        TriggerClientEvent('QBCore:Notify', src, err, 'error')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Debug fighter spawned.', 'success')
    end
end)

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

RegisterCommand('bstarcarddiag', function(source, args)
    local src = source
    local wantedId = args[1] or 'ALPH1_EN001_LAYLA_HART'
    local count = 0

    for _ in pairs(Cards or {}) do
        count = count + 1
    end

    local card = ResolveCardDefinition(wantedId)
    local message = ('BStar Cards loaded: %s | %s => %s'):format(
        count,
        wantedId,
        card and ((card.name or card.id or 'matched') .. ' / ' .. tostring(card.inventoryImage or 'no image')) or 'NOT FOUND'
    )

    print('[BStar] ' .. message)
    if src and src > 0 then
        TriggerClientEvent('QBCore:Notify', src, message, card and 'success' or 'error')
    end
end, false)

RegisterCommand('bstarnormalizeids', function(source, args)
    local src = source
    local applyChanges = tostring(args[1] or ''):lower() == 'apply'

    exports.oxmysql:query([[
        SELECT id, citizenid, deck_box_id, card_id, amount
        FROM bstar_deckbox_cards
    ]], {}, function(deckBoxRows)
        local deleteIds = {}
        local insertRows = {}
        local grouped = {}
        local rowCount = 0
        local unresolvedRows = 0
        local movedRows = 0

        for _, row in ipairs(deckBoxRows or {}) do
            rowCount = rowCount + 1
            deleteIds[#deleteIds + 1] = row.id

            local currentId = getCurrentCardId(row.card_id)
            if currentId then
                local key = ("%s|%s|%s"):format(row.citizenid or '', row.deck_box_id or '', currentId)
                if not grouped[key] then
                    grouped[key] = {
                        citizenid = row.citizenid,
                        deckBoxId = row.deck_box_id,
                        cardId = currentId,
                        amount = 0
                    }
                    insertRows[#insertRows + 1] = grouped[key]
                end

                grouped[key].amount = grouped[key].amount + (tonumber(row.amount) or 0)
                if tostring(currentId) ~= tostring(row.card_id) then
                    movedRows = movedRows + 1
                end
            else
                unresolvedRows = unresolvedRows + 1
            end
        end

        exports.oxmysql:query([[
            SELECT id, deck_data
            FROM bstar_decks
        ]], {}, function(deckRows)
            local deckUpdates = {}
            local deckMoved = 0
            local deckRemoved = 0

            for _, deck in ipairs(deckRows or {}) do
                local decoded = nil
                if deck.deck_data and deck.deck_data ~= '' then
                    local ok, parsed = pcall(function()
                        return json.decode(deck.deck_data)
                    end)
                    if ok and type(parsed) == 'table' then
                        decoded = parsed
                    end
                end

                decoded = decoded or {}
                decoded.cards = type(decoded.cards) == 'table' and decoded.cards or {}

                local normalizedCards, changed, moved, removed = normalizeDeckCardMap(decoded.cards)
                if changed then
                    decoded.cards = normalizedCards
                    deckUpdates[#deckUpdates + 1] = {
                        id = deck.id,
                        deckData = decoded
                    }
                    deckMoved = deckMoved + moved
                    deckRemoved = deckRemoved + removed
                end
            end

            local summary = ('BStar ID normalize %s: deckbox rows=%s, moved=%s, removed=%s, canonical stacks=%s, deck updates=%s, deck moved=%s, deck removed=%s'):format(
                applyChanges and 'APPLY' or 'DRY-RUN',
                rowCount,
                movedRows,
                unresolvedRows,
                #insertRows,
                #deckUpdates,
                deckMoved,
                deckRemoved
            )

            local function finish()
                print('[BStar] ' .. summary)
                if src and src > 0 then
                    TriggerClientEvent('QBCore:Notify', src, summary, applyChanges and 'success' or 'primary')
                end
            end

            if not applyChanges then
                finish()
                return
            end

            local function updateDecks()
                local remaining = #deckUpdates
                if remaining == 0 then
                    finish()
                    return
                end

                for _, update in ipairs(deckUpdates) do
                    exports.oxmysql:update([[
                        UPDATE bstar_decks
                        SET deck_data = ?
                        WHERE id = ?
                    ]], { json.encode(update.deckData), update.id }, function()
                        remaining = remaining - 1
                        if remaining <= 0 then
                            finish()
                        end
                    end)
                end
            end

            local function insertDeckBoxRows()
                if #insertRows == 0 then
                    updateDecks()
                    return
                end

                local placeholders = {}
                local params = {}
                for _, row in ipairs(insertRows) do
                    placeholders[#placeholders + 1] = '(?, ?, ?, ?)'
                    params[#params + 1] = row.citizenid
                    params[#params + 1] = row.deckBoxId
                    params[#params + 1] = row.cardId
                    params[#params + 1] = row.amount
                end

                exports.oxmysql:insert(([[
                    INSERT INTO bstar_deckbox_cards (citizenid, deck_box_id, card_id, amount)
                    VALUES %s
                ]]):format(table.concat(placeholders, ', ')), params, function()
                    updateDecks()
                end)
            end

            if #deleteIds == 0 then
                insertDeckBoxRows()
                return
            end

            exports.oxmysql:update(([[
                DELETE FROM bstar_deckbox_cards
                WHERE id IN (%s)
            ]]):format(buildPlaceholders(#deleteIds)), deleteIds, function()
                insertDeckBoxRows()
            end)
        end)
    end)
end, false)
