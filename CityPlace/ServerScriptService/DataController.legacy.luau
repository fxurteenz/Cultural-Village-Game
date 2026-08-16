local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local TeleportEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("TeleportEvent")
local TeleportFunction = ServerStorage:WaitForChild("BindableFunction"):WaitForChild("TeleportFunction")
local LoadingEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("LoadingEvent") :: RemoteEvent

local CityDataManager = require(script.Parent:WaitForChild("CityDataManager"))
local EconomyService = require(ReplicatedStorage.Module.EconomyService)

local activeSessions = MemoryStoreService:GetSortedMap("ActiveCoopSessions")

local function TeleportPlayerToPlace(player, targetPlaceId)
    if not CityDataManager.HostId then
        return
    end

    LoadingEvent:FireClient(player,true,"กำลังไปที่ไร่...")
    print(player.Name .. " กำลังจะวาร์ปออกจากเมืองไปที่ Place: " .. targetPlaceId)

    task.wait(0.2)

    LoadingEvent:FireClient(player, true,"กำลังเตรียมข้อมูล.")
    local saveSuccess = CityDataManager.SaveSinglePlayer(player)

    while not saveSuccess do

        task.wait(1)

        saveSuccess = CityDataManager.SaveSinglePlayer(player)
		LoadingEvent:FireClient(player, true,"กำลังเตรียมข้อมูล..")
    end

	LoadingEvent:FireClient(player, true,"กำลังเตรียมข้อมูล...")
    CityDataManager.SaveWorldData()
	LoadingEvent:FireClient(player, true,"กำลังค้นหาเซิฟเวอร์ปลายทาง...")

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
			LoadingEvent:FireClient(player, true,"กำลังเตรียมเซิฟเวอร์ใหม่...")

            accessCode = TeleportService:ReserveServerAsync(targetPlaceId)
            sessionData[placeKey] = accessCode

            activeSessions:SetAsync(sessionId, sessionData, 86400)
            print("สร้าง ReserveServer ใหม่สำหรับ Placeเป้าหมาย: " .. targetPlaceId)
        else
			LoadingEvent:FireClient(player, true,"กำลังเตรียมเซิฟเวอร์ปลายทาง...")
            print("พบ ReserveServer เดิม กำลังส่งผู้เล่นไปเข้าร่วม...")
        end
    else
        warn("ไม่พบข้อมูล Session กำลังสร้างใหม่...")
		LoadingEvent:FireClient(player, true,"กำลังเตรียมเซิฟเวอร์ใหม่...")
        accessCode = TeleportService:ReserveServerAsync(targetPlaceId)
        local newData = {
            HostId = hostId,
            [placeKey] = accessCode
        }
        activeSessions:SetAsync(sessionId, newData, 86400)
    end
	LoadingEvent:FireClient(player, true,"กำลังย้ายผู้เล่น...")
    -- เตรียมข้อมูลแพ็คใส่กระเป๋าผู้เล่น
    local teleportOptions = Instance.new("TeleportOptions")
    teleportOptions.ReservedServerAccessCode = accessCode
    teleportOptions:SetTeleportData({
        HostId = hostId,
        SaveSlot = saveSlot,
        SessionId = sessionId
    })

    -- สั่งวาร์ป!
    local success, err = pcall(function()
        TeleportService:TeleportAsync(targetPlaceId, {player}, teleportOptions)
    end)
    if not success then
        warn("TeleportAsync failed for " .. player.Name .. ": " .. tostring(err))
        LoadingEvent:FireClient(player, true, "การวาร์ปล้มเหลว กรุณาลองใหม่อีกครั้ง")
        task.wait(1)
        LoadingEvent:FireClient(player, false)
        return false
    end
    task.wait(3)
    LoadingEvent:FireClient(player, false)
    return true
end

TeleportEvent.OnServerEvent:Connect(function(player, targetPlaceId)
    TeleportPlayerToPlace(player, targetPlaceId)
end)

TeleportFunction.OnInvoke = function(player, targetPlaceId)
   return TeleportPlayerToPlace(player, targetPlaceId)
end

Players.PlayerAdded:Connect(function(player)
    local joinData = player:GetJoinData()
    local teleportData = joinData.TeleportData

    if RunService:IsStudio() and not teleportData then
        print("🔧 [TESTING] จำลอง TeleportData")
        teleportData = {
            HostId = player.UserId,
            SaveSlot = "save_slot1",
            SessionId = tostring(player.UserId) .. "_save_slot1"
        }
    end

    if teleportData and teleportData.HostId and teleportData.SaveSlot then
        local hostId = teleportData.HostId
        local saveSlot = teleportData.SaveSlot

        if not CityDataManager.WorldData then
            CityDataManager.LoadWorldData(hostId, saveSlot)
        end

        CityDataManager.LoadPlayerData(player, hostId, saveSlot)
        print("[DataController] Player data Loaded : " .. player.Name .. "")

    else
        warn("[DataController] : Can't find TeleportData for " ..  player.Name)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if CityDataManager.HostId then
        CityDataManager.SaveSinglePlayer(player)
    end
end)

game:BindToClose(function()
    if CityDataManager.HostId then
        CityDataManager.UpdateMenuInfo()
        CityDataManager.SaveWorldData()

        for _, player in ipairs(Players:GetPlayers()) do
            CityDataManager.SaveSinglePlayer(player)
        end

        task.wait(2)
    end
end)
