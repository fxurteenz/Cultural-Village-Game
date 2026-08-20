local FarmDataManager = {}
local DataStoreService = game:GetService("DataStoreService")

local GameSaveDS = DataStoreService:GetDataStore("FarmingGame_Data_V2")

FarmDataManager.HostId = nil
FarmDataManager.SaveSlot = nil
FarmDataManager.WorldData = nil
FarmDataManager.PlayersData = {}
FarmDataManager.PlayerLoaded = Instance.new("BindableEvent")
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

function FarmDataManager.LoadWorldData(hostId, saveSlot)
    FarmDataManager.HostId = tostring(hostId)
    FarmDataManager.SaveSlot = saveSlot

    local worldKey = tostring(hostId) .. "_" .. saveSlot .. "_World"
    print(" [DataManager] : กำลังโหลดข้อมูล World : " .. worldKey)

    local success, data = pcall(function()
        return GameSaveDS:GetAsync(worldKey)
    end)

    if success and data then
        FarmDataManager.WorldData = data
        print("[DataManager] : โหลด World Data สำเร็จ")
    else
        FarmDataManager.WorldData = getDefaultWorldData()
		print("[DataManager] : สร้าง World Data ต้นใหม่")
    end
end

function FarmDataManager.LoadPlayerData(player, hostId, saveSlot)
    if not FarmDataManager.HostId then
        FarmDataManager.HostId = tostring(hostId)
        FarmDataManager.SaveSlot = saveSlot
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

        FarmDataManager.PlayersData[player.UserId] = data
    else
        FarmDataManager.PlayersData[player.UserId] = getDefaultPlayerData(player.Name)
    end

    FarmDataManager.PlayerLoaded:Fire(player)
end

function FarmDataManager.SaveSinglePlayer(player)
    local pData = FarmDataManager.PlayersData[player.UserId]
    if not pData then return true end -- ถ้าไม่มีข้อมูลในแรม ถือว่าผ่าน
    
    local playerKey = FarmDataManager.HostId .. "_" .. FarmDataManager.SaveSlot .. "_" .. tostring(player.UserId)
    -- ใช้ pcall ครอบ และรอจนกว่าจะเสร็จ (SetAsync จะ Yield รอให้อัตโนมัติ)
    local success, err = pcall(function()
        GameSaveDS:SetAsync(playerKey, pData)
    end)
    if success then
		print("[DataManager] : บันทึกข้อมูลของ " .. player.Name .. " สำเร็จ")
        FarmDataManager.PlayersData[player.UserId] = nil --เคลียร์แรม
        return true
    else
		warn("[DataManager] : บันทึกข้อมูลไม่สำเร็จ: " .. tostring(err))
        return false
    end
end

function FarmDataManager.SaveWorldData()
    if not FarmDataManager.WorldData or not FarmDataManager.HostId then
        return
    end

    local worldKey = FarmDataManager.HostId .. "_" .. FarmDataManager.SaveSlot .. "_World"
    local success, err = pcall(function()
        GameSaveDS:UpdateAsync(worldKey, function(oldData)
            if not oldData then
                return FarmDataManager.WorldData
            end
            local newData = oldData
            newData.time = FarmDataManager.WorldData.time
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
function FarmDataManager.UpdateMenuInfo()
    if not FarmDataManager.HostId or not FarmDataManager.SaveSlot then
        return
    end

    local menuInfoKey = FarmDataManager.HostId .. "_MenuInfo"
    pcall(function()
        GameSaveDS:UpdateAsync(menuInfoKey, function(oldData)
            local saves = oldData or {}
            if saves[FarmDataManager.SaveSlot] then
                saves[FarmDataManager.SaveSlot].last_place_id = game.PlaceId
                saves[FarmDataManager.SaveSlot].day = FarmDataManager.WorldData.time.day
                saves[FarmDataManager.SaveSlot].season = FarmDataManager.WorldData.time.season
                saves[FarmDataManager.SaveSlot].year = FarmDataManager.WorldData.time.year
            end
            return saves
        end)
    end)
end

return FarmDataManager
