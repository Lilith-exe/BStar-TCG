local QBCore = exports['qb-core']:GetCoreObject()

print('[BStar] server/main.lua loading')

DeckBox = {}

local MIN_DECK_CARDS = 30
local MAX_DECK_CARDS = 50
local MAX_COPIES_PER_CARD = 3

local function BuildCardItemInfo(cardId)
    local card = Cards and Cards[cardId]

    if not card then
        return {
            cardId = cardId
        }
    end

    return {
        cardId = cardId,
        inventoryImage = card.inventoryImage,
        label = card.name,
        rarity = card.rarity,
        type = card.type,
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
            local cardId = item.info.cardId
            local amount = item.amount or 1
            local card = Cards and Cards[cardId]

            if not results[cardId] then
                results[cardId] = {
                    cardId = cardId,
                    amount = 0,
                    inventoryImage = item.info.inventoryImage or (card and card.inventoryImage) or nil,
                    name = (card and card.name) or cardId,

                    rarity = card and card.rarity or nil,
                    type = card and card.type or nil,
                    level = card and card.level or nil,
                    attack = card and (card.attack or card.atk) or nil,
                    defense = card and (card.defense or card.def) or nil,
                    speed = card and (card.speed or card.spd) or nil,
                    effectTitle = card and card.effectTitle or nil,
                    effectText = card and card.effectText or nil,
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
        catalog[cardId] = {
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
            effectTitle = card.effectTitle,
            effectText = card.effectText,
            setCode = card.setCode,
            edition = card.edition,
            inventoryImage = card.inventoryImage
        }
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

            if not Cards or not Cards[cardId] then
                issues[#issues + 1] = 'Unknown card'
            end

            if amount > MAX_COPIES_PER_CARD then
                issues[#issues + 1] = 'Too many copies'
            end

            local storedAmount = 0
            if storedCards and storedCards[cardId] then
                storedAmount = tonumber(storedCards[cardId].amount) or 0
            end

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
            local card = Cards and Cards[row.card_id]

            cards[row.card_id] = {
                cardId = row.card_id,
                amount = row.amount,
                inventoryImage = card and card.inventoryImage or nil,
                name = (card and card.name) or row.card_id,

                rarity = card and card.rarity or nil,
                type = card and card.type or nil,
                level = card and card.level or nil,
                attack = card and (card.attack or card.atk) or nil,
                defense = card and (card.defense or card.def) or nil,
                speed = card and (card.speed or card.spd) or nil,
                effectTitle = card and card.effectTitle or nil,
                effectText = card and card.effectText or nil,
                job = card and card.job or nil,
                setCode = card and card.setCode or nil,
                edition = card and card.edition or nil
            }
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

    local foundSlot = nil

    for slot, item in pairs(items) do
        if item and item.name == 'bstar_card' and item.info and item.info.cardId == cardId then
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
    ]], { citizenid, deckBoxId, cardId }, function(result)
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
            ]], { citizenid, deckBoxId, cardId }, function()
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

CreateThread(function()
    Wait(1000)

    QBCore.Functions.CreateUseableItem('deck_box', function(source, item)
        print('[BStar] deck_box used by source:', source)
        TriggerClientEvent('bstar_cards:client:UseDeckBox', source, item)
    end)

    print('[BStar] deck_box usable item registered')
end)

QBCore.Functions.CreateUseableItem('bstar_card', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if not item or not item.info or not item.info.cardId then
        TriggerClientEvent('QBCore:Notify', source, 'This card has no cardId data.', 'error')
        return
    end

    local cardId = item.info.cardId
    local card = Cards[cardId]

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

local function startDuelAfterCoin(duelId, firstPlayer, src, successMessage)
    local ok, startErr = Duel.Start(duelId, firstPlayer)
    print('[BStar Duel] Duel.Start after coin result:', ok, startErr)

    if not ok then
        TriggerClientEvent('QBCore:Notify', src, startErr or 'Failed to start duel.', 'error')
        return false
    end

    TriggerClientEvent('QBCore:Notify', src, successMessage or 'Duel started.', 'success')
    return true
end

local function openCoinFlipForDuel(src, duel, tableMode)
    duel.coinFlip = {
        chooser = 1,
        starterSource = src
    }

    TriggerClientEvent('bstar_cards:client:OpenCoinFlip', src, {
        duelId = duel.id,
        tableMode = tableMode == true,
        tableId = duel.tableId
    })
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
        canChooseTurnOrder = playerWon
    })

    if not playerWon then
        CreateThread(function()
            Wait(1800)
            if duel and not duel.started then
                startDuelAfterCoin(duel.id, 2, src, 'Opponent won the toss and chose to go first.')
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

            local deckB = deckA

            local duel, err = Duel.Create(src, src, deckA, deckB)
            print('[BStar Table Duel] Duel.Create result:', duel and duel.id or nil, err)

            if not duel then
                TriggerClientEvent('QBCore:Notify', src, err or 'Failed to create duel.', 'error')
                return
            end

            duel.tableId = tableId

            print('[BStar Table Duel] Sending camera event:', tableId)
            TriggerClientEvent('bstar_cards:client:EnterDuelTableView', src, tableId)

            openCoinFlipForDuel(src, duel, true)
        end)
    end)
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
    local card = Cards[cardId]

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
            card.speed .. " • " .. card.attack .. " • " .. card.defense,
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
