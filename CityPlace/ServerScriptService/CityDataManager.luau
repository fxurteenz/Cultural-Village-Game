local CityDataManager = {}
local DataStoreService = game:GetService("DataStoreService")

local GameSaveDS = DataStoreService:GetDataStore("FarmingGame_Data_V2")

CityDataManager.HostId = nil
CityDataManager.SaveSlot = nil
CityDataManager.WorldData = nil
CityDataManager.PlayersData = {}

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

function CityDataManager.LoadWorldData(hostId, saveSlot)
    CityDataManager.HostId = tostring(hostId)
    CityDataManager.SaveSlot = saveSlot

    local worldKey = tostring(hostId) .. "_" .. saveSlot .. "_World"
    print("🌍 [City] กำลังโหลดข้อมูล World ในเมือง: " .. worldKey)

    local success, data = pcall(function()
        return GameSaveDS:GetAsync(worldKey)
    end)

    if success and data then
        CityDataManager.WorldData = data
        print("✅ [City] โหลด World Data สำเร็จ!")
    else
        CityDataManager.WorldData = getDefaultWorldData()
        print("✨ [City] สร้าง World Data เริ่มต้นใหม่ในเมือง!")
    end
end

function CityDataManager.LoadPlayerData(player, hostId, saveSlot)
    if not CityDataManager.HostId then
        CityDataManager.HostId = tostring(hostId)
        CityDataManager.SaveSlot = saveSlot
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

        CityDataManager.PlayersData[player.UserId] = data
    else
        CityDataManager.PlayersData[player.UserId] = getDefaultPlayerData(player.Name)
    end
end

function CityDataManager.SaveSinglePlayer(player)
    local pData = CityDataManager.PlayersData[player.UserId]
    if not pData then return true end -- ถ้าไม่มีข้อมูลในแรม ถือว่าผ่าน
    
    local playerKey = CityDataManager.HostId .. "_" .. CityDataManager.SaveSlot .. "_" .. tostring(player.UserId)
    -- ใช้ pcall ครอบ และรอจนกว่าจะเสร็จ (SetAsync จะ Yield รอให้อัตโนมัติ)
    local success, err = pcall(function()
        GameSaveDS:SetAsync(playerKey, pData)
    end)
    if success then
        print("💾 บันทึกข้อมูลของ " .. player.Name .. " สำเร็จ 100% ก่อนวาร์ป")
        CityDataManager.PlayersData[player.UserId] = nil --เคลียร์แรม
        return true
    else
        warn("❌ บันทึกข้อมูลไม่สำเร็จ: " .. tostring(err))
        return false
    end
end

function CityDataManager.SaveWorldData()
    if not CityDataManager.WorldData or not CityDataManager.HostId then
        return
    end

    local worldKey = CityDataManager.HostId .. "_" .. CityDataManager.SaveSlot .. "_World"
    local success, err = pcall(function()
        GameSaveDS:UpdateAsync(worldKey, function(oldData)
            if not oldData then
                return CityDataManager.WorldData
            end
            local newData = oldData
            newData.time = CityDataManager.WorldData.time
            return newData
        end)
    end)

    if success then
        print(
            "💾 [City] บันทึก WorldData (เวลา/ฤดูกาล) ลง DataStore สำเร็จ!")
    else
        warn("❌ [City] บันทึก WorldData ไม่สำเร็จ: " .. tostring(err))
    end
end

-- อัปเดตหน้าปกเซฟπ
function CityDataManager.UpdateMenuInfo()
    if not CityDataManager.HostId or not CityDataManager.SaveSlot then
        return
    end

    local menuInfoKey = CityDataManager.HostId .. "_MenuInfo"
    pcall(function()
        GameSaveDS:UpdateAsync(menuInfoKey, function(oldData)
            local saves = oldData or {}
            if saves[CityDataManager.SaveSlot] then
                saves[CityDataManager.SaveSlot].last_place_id = game.PlaceId
                saves[CityDataManager.SaveSlot].day = CityDataManager.WorldData.time.day
                saves[CityDataManager.SaveSlot].season = CityDataManager.WorldData.time.season
                saves[CityDataManager.SaveSlot].year = CityDataManager.WorldData.time.year
            end
            return saves
        end)
    end)
end

return CityDataManager
