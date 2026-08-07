local FarmDataManager = {}
local DataStoreService = game:GetService("DataStoreService")

local GameSaveDS = DataStoreService:GetDataStore("FarmingGame_Data_V2")

FarmDataManager.HostId = nil
FarmDataManager.SaveSlot = nil

FarmDataManager.WorldData = nil
FarmDataManager.PlayersData = {}
-- ==========================================
-- โครงสร้างข้อมูลเริ่มต้น (เมื่อเริ่มเกมใหม่)
-- ==========================================
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
        },
        ["saruses"] = {}, -- นกกระเรียน
        ["farm_plots"] = {} -- แปลงผัก
    }
end

local function getDefaultPlayerData(playerName)
    return {
        ["player_name"] = playerName,
        ["coins"] = 500,
        ["player_items"] = {}, -- เก็บไอเทม (แทน inventory เดิม)
        ["quests"] = {
            ["active"] = {},
            ["completed"] = {}
        },
        ["playtime"] = 0
    }
end

-- ==========================================
-- 1. โหลดข้อมูลโลก (World Data) - เรียกครั้งเดียวตอนสร้างเซิร์ฟเวอร์ฟาร์ม
-- ==========================================
function FarmDataManager.LoadWorldData(hostId, saveSlot)
    FarmDataManager.HostId = tostring(hostId)
    FarmDataManager.SaveSlot = saveSlot

    local worldKey = tostring(hostId) .. "_" .. saveSlot .. "_World"
    print("🌍 กำลังโหลดข้อมูล World ฟาร์ม: " .. worldKey)

    local success, data = pcall(function()
        return GameSaveDS:GetAsync(worldKey)
    end)

    if success and data then
        FarmDataManager.WorldData = data
        print("✅ โหลดข้อมูล World ฟาร์มสำเร็จ!")
    else
        FarmDataManager.WorldData = getDefaultWorldData()
        print("✨ สร้างข้อมูล World ฟาร์มเริ่มต้นใหม่!")
    end
end

-- ==========================================
-- 2. โหลดข้อมูลผู้เล่น (Player Data) - เรียกทุกครั้งที่มีคนวาร์ปเข้าฟาร์ม
-- ==========================================
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
end

-- ==========================================
-- 3. บันทึกข้อมูลทั้งหมด (เรียกตอน Auto-Save หรือปิดเซิร์ฟเวอร์ฟาร์ม)
-- ==========================================
function FarmDataManager.SaveAllData()
    if not FarmDataManager.WorldData or not FarmDataManager.HostId then
        return
    end

    -- 3.1 บันทึก World Data (แปลงผัก)
    local worldKey = FarmDataManager.HostId .. "_" .. FarmDataManager.SaveSlot .. "_World"
    -- pcall(function() GameSaveDS:SetAsync(worldKey, FarmDataManager.WorldData) end)
    FarmDataManager.SaveWorldData()

    -- 3.2 บันทึก Player Data ของทุกคนที่ยืนอยู่ในฟาร์มตอนนี้
    for userId, pData in pairs(FarmDataManager.PlayersData) do
        local playerKey = FarmDataManager.HostId .. "_" .. FarmDataManager.SaveSlot .. "_" .. tostring(userId)
        pcall(function()
            GameSaveDS:SetAsync(playerKey, pData)
        end)
    end

    -- 3.3 อัปเดตหน้าปกเซฟ (เพื่อให้ Main Menu รู้ว่าโฮสต์อยู่ฟาร์ม)
    local menuInfoKey = FarmDataManager.HostId .. "_MenuInfo"
    pcall(function()
        GameSaveDS:UpdateAsync(menuInfoKey, function(oldData)
            local saves = oldData or {}
            if saves[FarmDataManager.SaveSlot] then
                saves[FarmDataManager.SaveSlot].last_place_id = game.PlaceId
            end
            return saves
        end)
    end)

    print("💾 เซฟข้อมูลฟาร์มทั้งหมดสำเร็จ!")
end

-- ==========================================
-- 4. บันทึกเฉพาะผู้เล่นคนเดียว (เรียกตอนคนนั้นกดออกเกม หรือวาร์ปไปเมือง)
-- ==========================================
function FarmDataManager.SaveSinglePlayer(player)
    local pData = FarmDataManager.PlayersData[player.UserId]
    if not pData then
        return true
    end -- ถ้าไม่มีข้อมูลในแรม ถือว่าผ่าน

    local playerKey = FarmDataManager.HostId .. "_" .. FarmDataManager.SaveSlot .. "_" .. tostring(player.UserId)

    -- ใช้ pcall ครอบ และรอจนกว่าจะเสร็จ (SetAsync จะ Yield รอให้อัตโนมัติ)
    local success, err = pcall(function()
        GameSaveDS:SetAsync(playerKey, pData)
    end)

    if success then
        print("💾 บันทึกข้อมูลของ " .. player.Name ..
                  " สำเร็จ 100% ก่อนวาร์ป")
        FarmDataManager.PlayersData[player.UserId] = nil -- เคลียร์แรม
        return true
    else
        warn("❌ บันทึกข้อมูลไม่สำเร็จ: " .. tostring(err))
        return false
    end
end

function FarmDataManager.SaveWorldData()
    if not FarmDataManager.WorldData or not FarmDataManager.HostId then
        return
    end

    local worldKey = FarmDataManager.HostId .. "_" .. FarmDataManager.SaveSlot .. "_World"

    -- ใช้ UpdateAsync แทน SetAsync เพื่อความปลอดภัย 100%
    local success, err = pcall(function()
        GameSaveDS:UpdateAsync(worldKey, function(oldData)
            -- 1. ถ้าไม่มีข้อมูลเก่า ก็ใช้ค่าปัจจุบันใน RAM ไปเลย
            if not oldData then
                return FarmDataManager.WorldData
            end
            -- 2. ถ้ามีข้อมูลเก่า ให้เราอัปเดตเฉพาะส่วนที่เราดูแล
            -- ตัวอย่าง: อัปเดตเฉพาะเวลา (time)
            local newData = oldData
            newData.time = FarmDataManager.WorldData.time

            -- (ถ้าแมพฟาร์มมีแปลงผัก ก็เพิ่ม: newData.farm_plots = FarmDataManager.WorldData.farm_plots)

            return newData -- ส่งค่าที่รวมร่างแล้วกลับไปเซฟ
        end)
    end)

    if success then
        print("💾 [Sync] บันทึกและ Merge WorldData สำเร็จ!")
    else
        warn("❌ [Sync] บันทึก WorldData ไม่สำเร็จ: " .. tostring(err))
    end
end
-- ==========================================

return FarmDataManager
