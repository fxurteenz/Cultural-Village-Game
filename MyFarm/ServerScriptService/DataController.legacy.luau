local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local TeleportEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("TeleportEvent")

local FarmDataManager = require(script.Parent:WaitForChild("FarmDataManager"))

local activeSessions = MemoryStoreService:GetSortedMap("ActiveCoopSessions")

-- ==========================================
-- 1. ฟังก์ชันสำหรับการวาร์ปผู้เล่นข้าม Place (แบบเดี่ยว)
-- ==========================================
local function TeleportPlayerToPlace(player, targetPlaceId)
    if not FarmDataManager.HostId then return end

    print(player.Name .. " กำลังจะวาร์ปออกจากฟาร์มไปที่ Place: " .. targetPlaceId)

    -- เซฟข้อมูลเฉพาะผู้เล่นคนที่จะวาร์ปออกก่อน
    FarmDataManager.SaveSinglePlayer(player)

    local hostId = FarmDataManager.HostId
    local saveSlot = FarmDataManager.SaveSlot
    local sessionId = tostring(hostId) .. "_" .. saveSlot
    local placeKey = "PlaceCode_" .. tostring(targetPlaceId)

    local success, sessionData = pcall(function()
        return activeSessions:GetAsync(sessionId)
    end)

    local accessCode = nil

    if success and sessionData then
        accessCode = sessionData[placeKey]

        if not accessCode then
            -- 🌟 แก้จาก ReserveServerAsync เป็น ReserveServer ให้ถูกต้องตาม Roblox API
            accessCode = TeleportService:ReserveServer(targetPlaceId)
            sessionData[placeKey] = accessCode
            activeSessions:SetAsync(sessionId, sessionData, 86400)
            print("สร้าง ReserveServer ใหม่สำหรับ Placeเป้าหมาย: " .. targetPlaceId)
        else
            print("พบ ReserveServer เดิม กำลังส่งผู้เล่นไปเข้าร่วม...")
        end
    else
        warn("ไม่พบข้อมูล Session กำลังสร้างใหม่...")
        -- 🌟 แก้จาก ReserveServerAsync เป็น ReserveServer ให้ถูกต้องตาม Roblox API
        accessCode = TeleportService:ReserveServer(targetPlaceId)
        local newData = { HostId = hostId, [placeKey] = accessCode }
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
-- 2. ระบบรับผู้เล่นเข้าเซิร์ฟเวอร์ฟาร์ม
-- ==========================================
Players.PlayerAdded:Connect(function(player)
    local joinData = player:GetJoinData()
    local teleportData = joinData.TeleportData

    -- ==========================================
    -- FOR TEST IN STUDIO
    -- ==========================================
    if RunService:IsStudio() and not teleportData then
        print("🔧 [TESTING] จำลอง TeleportData สำหรับแมพฟาร์ม...")
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

        if not FarmDataManager.WorldData then
            FarmDataManager.LoadWorldData(hostId, saveSlot)
        end

        -- 🎒 โหลดกระเป๋าผู้เล่นคนนั้นๆ
        FarmDataManager.LoadPlayerData(player)
        print("🎒 โหลดข้อมูลผู้เล่น " .. player.Name .. " เข้าสู่ฟาร์มพร้อมเล่น!")

    else
        warn(player.Name .. " ไม่พบ TeleportData สำหรับการโหลดเซฟ")
    end
end)

-- ==========================================
-- 3. ระบบเซฟเมื่อผู้เล่นออก / เซิร์ฟเวอร์ปิด
-- ==========================================

-- เมื่อมีผู้เล่นกดออกเกม (Leave) ให้เซฟเฉพาะข้อมูลคนนั้น
Players.PlayerRemoving:Connect(function(player)
    if FarmDataManager.HostId then
        FarmDataManager.SaveSinglePlayer(player)
    end
end)

-- บันทึกข้อมูลเมื่อเซิร์ฟเวอร์ฟาร์มกำลังจะปิด
game:BindToClose(function()
    if FarmDataManager.HostId then
        FarmDataManager.SaveAllData()
        task.wait(2)
    end
end)