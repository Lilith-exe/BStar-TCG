local QBCore = exports['qb-core']:GetCoreObject()

print('[BStar] server/deckbox.lua loading')

DeckBox = {}

local function getPlayerCardCounts(Player)
    local results = {}

    if not Player or not Player.PlayerData or not Player.PlayerData.items then
        return results
    end

    for _, item in pairs(Player.PlayerData.items) do
        if item and item.name == 'bstar_card' and item.info and item.info.cardId then
            local cardId = item.info.cardId
            local amount = item.amount or 1

            if not results[cardId] then
                results[cardId] = {
                    cardId = cardId,
                    amount = 0,
                    inventoryImage = item.info.inventoryImage or nil
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
            cards[row.card_id] = {
                cardId = row.card_id,
                amount = row.amount,
                inventoryImage = nil
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
    local foundItem = nil

    for slot, item in pairs(items) do
        if item and item.name == 'bstar_card' and item.info and item.info.cardId == cardId then
            foundSlot = slot
            foundItem = item
            break
        end
    end

    if not foundSlot or not foundItem then
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

        local success = Player.Functions.AddItem('bstar_card', 1, false, {
            cardId = cardId
        })

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

print('[BStar] DeckBox table created')