local QBCore = exports['qb-core']:GetCoreObject()

local cardOpen = false

local CurrentDeckBox = nil

CurrentDeckBoxId = CurrentDeckBoxId or nil

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    cardOpen = false
    CurrentDeckBox = nil
    CurrentDeckBoxId = nil
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'forceCloseAll' })

    CreateThread(function()
        Wait(1500)
        QBCore.Functions.Notify('BStar client reloaded. Use your deck box.', 'primary')
    end)
end)


RegisterNetEvent('bstar_cards:client:showCard', function(card)
    if not card then return end

    cardOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'showCard',
        card = card
    })
end)

-- Read-only development catalog for the temporary ghost artwork selector.
RegisterNUICallback('ghostPreviewCatalog', function(_, cb)
    if not Config.Debug then cb({ enabled = false, cards = {} }) return end
    local cards = {}
    for id, card in pairs(Cards) do
        if card.inventoryImage and id ~= 'ALPH1_EN144_LUCIAN_LIGHTBRINGER' then
            cards[#cards + 1] = { id = id, name = card.name, inventoryImage = card.inventoryImage }
        end
    end
    cb({ enabled = true, cards = cards })
end)

RegisterNUICallback('closeCard', function(_, cb)
    cardOpen = false
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'hideCard'
    })

    cb({})
end)

RegisterNUICallback('storeCard', function(data, cb)
    TriggerServerEvent('bstar_cards:server:StoreCardInDeckBox', data.deckBoxId, data.cardId)
    cb('ok')
end)

RegisterNUICallback('withdrawCard', function(data, cb)
    TriggerServerEvent('bstar_cards:server:WithdrawCardFromDeckBox', data.deckBoxId, data.cardId, data.copyId or (data.legacy and 'legacy'))
    cb('ok')
end)

RegisterNUICallback('refreshDeckBox', function(data, cb)
    QBCore.Functions.TriggerCallback('bstar_cards:server:GetDeckBoxData', function(result)
        cb(result)
    end, data.deckBoxId)
end)

RegisterNUICallback('closeDeckBox', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('refreshDeckBuilder', function(data, cb)
    QBCore.Functions.TriggerCallback('bstar_cards:server:GetDeckBuilderData', function(result)
        cb(result)
    end, data.deckBoxId)
end)

RegisterNUICallback('createDeck', function(data, cb)
    TriggerServerEvent('bstar_cards:server:CreateDeck', data.deckBoxId, data.deckName)
    cb('ok')
end)

RegisterNUICallback('saveDeck', function(data, cb)
    TriggerServerEvent('bstar_cards:server:SaveDeck', data.deckBoxId, data.deckId, data.deckName, data.deckData)
    cb('ok')
end)

RegisterNUICallback('deleteDeck', function(data, cb)
    TriggerServerEvent('bstar_cards:server:DeleteDeck', data.deckBoxId, data.deckId)
    cb('ok')
end)

RegisterNUICallback('closeDeckBuilder', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNetEvent('bstar_cards:client:UseDeckBox', function(item)
    if not item or not item.info or not item.info.id then
        QBCore.Functions.Notify('This deck box is missing its ID.', 'error')
        return
    end

    local deckBoxId = item.info.id
    CurrentDeckBoxId = deckBoxId

    QBCore.Functions.TriggerCallback('bstar_cards:server:GetDeckBuilderData', function(result)
        SetNuiFocus(true, true)

        SendNUIMessage({
            action = 'openDeckBuilder',
            deckBoxId = deckBoxId,
            storedCards = result.storedCards or {},
            decks = result.decks or {},
            cardCatalog = result.cardCatalog or {}
        })
    end, deckBoxId)
end)

RegisterNetEvent('bstar_cards:client:OpenDeckBoxStash', function(data)
    local deckBoxId = data.deckBoxId
    if not deckBoxId then return end

    QBCore.Functions.TriggerCallback('bstar_cards:server:GetDeckBoxData', function(result)
        SetNuiFocus(true, true)

        SendNUIMessage({
            action = "openDeckBox",
            deckBoxId = deckBoxId,
            playerCards = result.playerCards or {},
            storedCards = result.storedCards or {}
        })
    end, deckBoxId)
end)

RegisterNetEvent('qb-inventory:client:closeInventory', function()
    if not CurrentDeckBox then return end

    print('[BStar] Saving deck box:', CurrentDeckBox)

    TriggerServerEvent('bstar_cards:server:SaveDeckBox', CurrentDeckBox, PlayerInventory)
end)

RegisterNetEvent('bstar_cards:client:OpenDeckBuilder', function(data)
    local deckBoxId = data.deckBoxId
    if not deckBoxId then return end

    QBCore.Functions.TriggerCallback('bstar_cards:server:GetDeckBuilderData', function(result)
        SetNuiFocus(true, true)

        SendNUIMessage({
            action = 'openDeckBuilder',
            deckBoxId = deckBoxId,
            storedCards = result.storedCards or {},
            decks = result.decks or {},
            cardCatalog = result.cardCatalog or {}
        })
    end, deckBoxId)
end)




RegisterCommand('bstarfilldeckbox', function(_, args)
    local deckBoxId = args[1] or CurrentDeckBoxId

    if not deckBoxId then
        QBCore.Functions.Notify('Use a deck box first, or pass a deck box id.', 'error')
        return
    end

    TriggerServerEvent('bstar_cards:server:DevFillDeckBox', deckBoxId)
end, false)
