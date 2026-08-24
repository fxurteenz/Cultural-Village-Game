local DataManager = {}
local DataStoreService = game:GetService("DataStoreService")

local GameSaveDS = DataStoreService:GetDataStore("FarmingGame_Data_V2")

DataManager.HostId = nil
DataManager.SaveSlot = nil
DataManager.WorldData = nil
DataManager.PlayersData = {}
DataManager.PlayerLoaded = Instance.new("BindableEvent")
local function getDefaultWorldData()
    return {
        ["time"] = {
            ["clock_time"] = 7,
            ["day"] = 1,
            ["season"] = 1,
            ["year"] = 1
        },
        ["world_stats"] = {
            ["environment"] = 50,
            ["social"] = 50
        }
    }
end

local function getDefaultPlayerData(playerName)
    return {
        ["player_name"] = playerName,
        ["coins"] = 500,
        ["player_items"] = {},
        ["quests"] = {
            ["active"] = {},
            ["completed"] = {}
        },
        ["playtime"] = 0
    }
end

function DataManager.LoadWorldData(hostId, saveSlot)
    DataManager.HostId = tostring(hostId)
    DataManager.SaveSlot = saveSlot

    local worldKey = tostring(hostId) .. "_" .. saveSlot .. "_World"
    print(" [DataManager] : กำลังโหลดข้อมูล World : " .. worldKey)

    local success, data = pcall(function()
        return GameSaveDS:GetAsync(worldKey)
    end)

    if success and data then
        DataManager.WorldData = data
        print("[DataManager] : โหลด World Data สำเร็จ")
    else
        DataManager.WorldData = getDefaultWorldData()
		print("[DataManager] : สร้าง World Data ต้นใหม่")
    end
end

function DataManager.LoadPlayerData(player, hostId, saveSlot)
    if not DataManager.HostId then
        DataManager.HostId = tostring(hostId)
        DataManager.SaveSlot = saveSlot
    end

    local playerKey = tostring(hostId) .. "_" .. saveSlot .. "_" .. tostring(player.UserId)
    local success, data = pcall(function()
        return GameSaveDS:GetAsync(playerKey)
    end)

    if success and data then
        data.quests = data.quests or {}
        data.quests.active = data.quests.active or {}
        data.quests.completed = data.quests.completed or {}
        data.player_items = data.player_items or {}
        data.coins = data.coins or 500

        DataManager.PlayersData[player.UserId] = data
    else
        DataManager.PlayersData[player.UserId] = getDefaultPlayerData(player.Name)
    end

    DataManager.PlayerLoaded:Fire(player)
end

function DataManager.SaveSinglePlayer(player)
    local pData = DataManager.PlayersData[player.UserId]
    if not pData then return true end -- ถ้าไม่มีข้อมูลในแรม ถือว่าผ่าน
    
    local playerKey = DataManager.HostId .. "_" .. DataManager.SaveSlot .. "_" .. tostring(player.UserId)
    -- ใช้ pcall ครอบ และรอจนกว่าจะเสร็จ (SetAsync จะ Yield รอให้อัตโนมัติ)
    local success, err = pcall(function()
        GameSaveDS:SetAsync(playerKey, pData)
    end)
    if success then
		print("[DataManager] : บันทึกข้อมูลของ " .. player.Name .. " สำเร็จ")
        DataManager.PlayersData[player.UserId] = nil --เคลียร์แรม
        return true
    else
		warn("[DataManager] : บันทึกข้อมูลไม่สำเร็จ: " .. tostring(err))
        return false
    end
end

function DataManager.SaveWorldData()
    if not DataManager.WorldData or not DataManager.HostId then
        return
    end

    local worldKey = DataManager.HostId .. "_" .. DataManager.SaveSlot .. "_World"
    local success, err = pcall(function()
        GameSaveDS:UpdateAsync(worldKey, function(oldData)
            if not oldData then
                return DataManager.WorldData
            end
            local newData = oldData
            newData.time = DataManager.WorldData.time
            return newData
        end)
    end)

    if success then
        print("[DataManager] บันทึก WorldData สำเร็จ!")
    else
		warn("[DataManager] บันทึก WorldData ไม่สำเร็จ: " .. tostring(err))
    end
end

-- อัปเดตหน้าปกเซฟπ
function DataManager.UpdateMenuInfo()
    if not DataManager.HostId or not DataManager.SaveSlot then
        return
    end

    local menuInfoKey = DataManager.HostId .. "_MenuInfo"
    pcall(function()
        GameSaveDS:UpdateAsync(menuInfoKey, function(oldData)
            local saves = oldData or {}
            if saves[DataManager.SaveSlot] then
                saves[DataManager.SaveSlot].last_place_id = game.PlaceId
                saves[DataManager.SaveSlot].day = DataManager.WorldData.time.day
                saves[DataManager.SaveSlot].season = DataManager.WorldData.time.season
                saves[DataManager.SaveSlot].year = DataManager.WorldData.time.year
            end
            return saves
        end)
    end)
end

return DataManager
