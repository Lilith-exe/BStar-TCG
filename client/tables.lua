local QBCore = exports['qb-core']:GetCoreObject()

print('[BStar Tables] Config exists?', Config ~= nil)
print('[BStar Tables] Config.DuelTables exists?', Config and Config.DuelTables ~= nil)

print('[BStar Tables] client/tables.lua loaded')

CurrentDuelTableId = nil
local DuelCam = nil

local function FindDuelTable(tableId)
    if not Config or not Config.DuelTables then
        print('[BStar Tables] Config.DuelTables missing')
        return nil
    end

    for _, duelTable in pairs(Config.DuelTables) do
        if duelTable.id == tableId then
            return duelTable
        end
    end

    return nil
end

local function UseDuelTable(tableId)
    print('[BStar Tables] UseDuelTable fired with tableId:', tableId)
    print('[BStar Tables] CurrentDeckBoxId:', CurrentDeckBoxId)

    if not CurrentDeckBoxId then
        QBCore.Functions.Notify('Use your deck box first so a duel deck can be loaded.', 'error')
        return
    end

    QBCore.Functions.TriggerCallback('bstar_cards:server:GetDecksForTestDuel', function(decks)
        print('[BStar Tables] GetDecksForTestDuel callback, deck count:', decks and #decks or 0)

        if not decks or #decks < 1 then
            QBCore.Functions.Notify('No saved decks found in this deck box.', 'error')
            return
        end

        local myDeck = decks[1]
        TriggerServerEvent('bstar_cards:server:StartTableTestDuel', tableId, CurrentDeckBoxId, myDeck.id)
    end, CurrentDeckBoxId)
end

local function StopDuelCamera()
    local ped = PlayerPedId()

    if DuelCam and DoesCamExist(DuelCam) then
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(DuelCam, false)
        DuelCam = nil
    end

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, true, false)
    SetPlayerControl(PlayerId(), true, 0)

    EnableAllControlActions(0)

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    CurrentDuelTableId = nil
end

local function StartDuelCamera(tableId)
    print('[BStar Tables] StartDuelCamera called for tableId:', tableId)

    local tbl = FindDuelTable(tableId)
    if not tbl then return end

    StopDuelCamera()

    CurrentDuelTableId = tableId -- IMPORTANT: set this AFTER StopDuelCamera()

    local ped = PlayerPedId()

    if tbl.seat then
        SetEntityCoords(ped, tbl.seat.coords.x, tbl.seat.coords.y, tbl.seat.coords.z, false, false, false, true)
        SetEntityHeading(ped, tbl.seat.heading or 0.0)
    end

    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)

    DuelCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(DuelCam, tbl.camera.pos.x, tbl.camera.pos.y, tbl.camera.pos.z)
    PointCamAtCoord(DuelCam, tbl.camera.point.x, tbl.camera.point.y, tbl.camera.point.z)
    SetCamFov(DuelCam, tbl.camera.fov or 42.0)

    RenderScriptCams(true, true, 350, true, true)
end

RegisterNetEvent('bstar_cards:client:EnterDuelTableView', function(tableId)
    print('[BStar Tables] EnterDuelTableView event received:', tableId)
    StartDuelCamera(tableId)
end)

RegisterNetEvent('bstar_cards:client:ExitDuelTableView', function()
    StopDuelCamera()
end)

CreateThread(function()
    for _, duelTable in pairs(Config.DuelTables or {}) do
        local tableId = duelTable.id
        local coords = duelTable.coords
        local heading = duelTable.heading
        local target = duelTable.target

        exports['qb-target']:AddBoxZone(tableId, coords, target.length, target.width, {
            name = tableId,
            heading = heading,
            debugPoly = false,
            minZ = target.minZ,
            maxZ = target.maxZ
        }, {
            options = {
                {
                icon = "fas fa-chess-board",
                label = "Start Test Duel",
                action = function()
                    print('[BStar Tables] qb-target action fired for table:', tableId)
                    UseDuelTable(tableId)
                end
                }
            },
            distance = 2.0
        })
    end
end)
