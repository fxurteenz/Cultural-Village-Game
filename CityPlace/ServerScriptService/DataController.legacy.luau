local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local TeleportEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("TeleportEvent")

local CityDataManager = require(script.Parent:WaitForChild("CityDataManager"))
local EconomyService = require(ReplicatedStorage.Module.EconomyService)

local activeSessions = MemoryStoreService:GetSortedMap("ActiveCoopSessions")

-- ==========================================
-- 1. ฟังก์ชันสำหรับการวาร์ปผู้เล่นข้าม Place (แบบเดี่ยว)
-- ==========================================
local function TeleportPlayerToPlace(player, targetPlaceId)
    if not CityDataManager.HostId then
        return
    end

    print(player.Name .. " กำลังจะวาร์ปออกจากเมืองไปที่ Place: " .. targetPlaceId)

    local saveSuccess = CityDataManager.SaveSinglePlayer(player)
    while not saveSuccess do
        task.wait(1) -- เผื่อเวลาให้ระบบลองใหม่ชั่วคราว
        saveSuccess = CityDataManager.SaveSinglePlayer(player)
    end
    CityDataManager.SaveWorldData()

    local hostId = CityDataManager.HostId
    local saveSlot = CityDataManager.SaveSlot
    local sessionId = tostring(hostId) .. "_" .. saveSlot
    local placeKey = "PlaceCode_" .. tostring(targetPlaceId)

    local success, sessionData = pcall(function()
        return activeSessions:GetAsync(sessionId)
    end)

    local accessCode = nil

    if success and sessionData then
        accessCode = sessionData[placeKey]

        if not accessCode then
            accessCode = TeleportService:ReserveServerAsync(targetPlaceId)
            sessionData[placeKey] = accessCode
            activeSessions:SetAsync(sessionId, sessionData, 86400)
            print("สร้าง ReserveServer ใหม่สำหรับ Placeเป้าหมาย: " ..
                      targetPlaceId)
        else
            print(
                "พบ ReserveServer เดิม กำลังส่งผู้เล่นไปเข้าร่วม...")
        end
    else
        warn("ไม่พบข้อมูล Session กำลังสร้างใหม่...")
        accessCode = TeleportService:ReserveServerAsync(targetPlaceId)
        local newData = {
            HostId = hostId,
            [placeKey] = accessCode
        }
        activeSessions:SetAsync(sessionId, newData, 86400)
    end

    -- เตรียมข้อมูลแพ็คใส่กระเป๋าผู้เล่น
    local teleportOptions = Instance.new("TeleportOptions")
    teleportOptions.ReservedServerAccessCode = accessCode
    teleportOptions:SetTeleportData({
        HostId = hostId,
        SaveSlot = saveSlot,
        SessionId = sessionId
    })

    -- สั่งวาร์ป!
    TeleportService:TeleportAsync(targetPlaceId, {player}, teleportOptions)
end

-- รับ Event จาก Client เพื่อสั่งวาร์ป
TeleportEvent.OnServerEvent:Connect(function(player, targetPlaceId)
    TeleportPlayerToPlace(player, targetPlaceId)
end)

-- ==========================================
-- 2. ระบบรับผู้เล่นเข้าเซิร์ฟเวอร์เมือง
-- ==========================================
Players.PlayerAdded:Connect(function(player)
    local joinData = player:GetJoinData()
    local teleportData = joinData.TeleportData

    -- ==========================================
    -- FOR TEST IN STUDIO
    -- ==========================================
    if RunService:IsStudio() and not teleportData then
        print("🔧 [TESTING] จำลอง TeleportData สำหรับแมพเมือง...")
        teleportData = {
            HostId = player.UserId,
            SaveSlot = "save_slot1",
            SessionId = tostring(player.UserId) .. "_save_slot1"
        }
    end
    -- ==========================================

    if teleportData and teleportData.HostId and teleportData.SaveSlot then
        local hostId = teleportData.HostId
        local saveSlot = teleportData.SaveSlot

        if not CityDataManager.WorldData then
            CityDataManager.LoadWorldData(hostId, saveSlot)
        end

        CityDataManager.LoadPlayerData(player, hostId, saveSlot)
        print("🎒 โหลดกระเป๋าผู้เล่น " .. player.Name .. " เข้าสู่เมืองพร้อมเล่น!")

    else
        warn(player.Name .. " ไม่พบ TeleportData สำหรับการโหลดเซฟ")
    end
end)

-- ==========================================
-- 3. ระบบเซฟเมื่อผู้เล่นออก / เซิร์ฟเวอร์ปิด
-- ==========================================

-- เมื่อมีผู้เล่นกดออกเกม (Leave) ให้เซฟเฉพาะข้อมูลคนนั้น
Players.PlayerRemoving:Connect(function(player)
    if CityDataManager.HostId then
        CityDataManager.SaveSinglePlayer(player)
    end
end)

-- บันทึกข้อมูลเมื่อเซิร์ฟเวอร์เมืองกำลังจะปิด
game:BindToClose(function()
    if CityDataManager.HostId then
        -- 1. อัปเดตแมพล่าสุดลงหน้าปกเซฟ เพื่อให้หน้า Main Menu รู้ว่าเซฟไว้ที่เมือง
        CityDataManager.UpdateMenuInfo()
        CityDataManager.SaveWorldData()
        -- 2. วนลูปเซฟข้อมูลผู้เล่นทุกคนที่ยังติดอยู่ในแมพเมือง
        for _, player in ipairs(Players:GetPlayers()) do
            CityDataManager.SaveSinglePlayer(player)
        end

        task.wait(2)
    end
end)
