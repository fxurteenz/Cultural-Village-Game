local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local TeleportEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("TeleportEvent")
local TeleportFunction = ServerStorage:WaitForChild("BindableFunction"):WaitForChild("TeleportFunction")
local LoadingEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("LoadingEvent") :: RemoteEvent

local DataManager = require(script.Parent:WaitForChild("DataManagerModule"))
local EconomyService = require(ReplicatedStorage.Module.EconomyService)

local activeSessions = MemoryStoreService:GetSortedMap("ActiveCoopSessions")

-- กำหนดพิกัดเตียงนอนสำหรับแมพฟาร์ม (ปรับ CFrame ให้ตรงกับเตียงของคุณ)
local HOME_SPAWN_LOCATION = CFrame.new(336.433, 16.426, -146.774) 

-- TELEPORT CONTROL --
-- เพิ่มพารามิเตอร์ spawnReason (ถ้าไม่ส่งมาจะให้เป็น "Normal")
local function TeleportPlayerToPlace(player, targetPlaceId, spawnReason)
	spawnReason = spawnReason or "Normal"

	if not DataManager.HostId then
		return
	end

	LoadingEvent:FireClient(player, true, "กำลังเตรียมข้อมูล.")
	print(player.Name .. " กำลังจะวาร์ปไปที่ Place: " .. targetPlaceId .. " เหตุผล: " .. spawnReason)

	task.wait(0.2)

	LoadingEvent:FireClient(player, true, "กำลังเตรียมข้อมูล..")
	local saveSuccess = DataManager.SaveSinglePlayer(player)
	print("[save single player result] : ", saveSuccess)

	while not saveSuccess do
		task.wait(1)
		saveSuccess = DataManager.SaveSinglePlayer(player)
		LoadingEvent:FireClient(player, true, "กำลังเตรียมข้อมูล...")
	end

	LoadingEvent:FireClient(player, true, "กำลังเตรียมข้อมูล.")

	local syncRes, syncMsg = pcall(function() return DataManager.WorldSaving:Invoke() end)
	print("[DataController] วาร์ปข้ามแมพ - ซิงค์ข้อมูลแปลง: ", syncRes, syncMsg)

	DataManager.SaveWorldData()
	LoadingEvent:FireClient(player, true, "กำลังค้นหาเซิฟเวอร์ปลายทาง...")

	local hostId = DataManager.HostId
	local saveSlot = DataManager.SaveSlot
	local sessionId = tostring(hostId) .. "_" .. saveSlot
	local placeKey = "PlaceCode_" .. tostring(targetPlaceId)

	local success, sessionData = pcall(function()
		return activeSessions:GetAsync(sessionId)
	end)

	local accessCode = nil
	local createServerSuccess = false

	if success and sessionData then
		accessCode = sessionData[placeKey]
		if not accessCode then
			LoadingEvent:FireClient(player, true, "กำลังเตรียมเซิฟเวอร์ใหม่...")

			createServerSuccess, accessCode = pcall(function()
				return TeleportService:ReserveServerAsync(targetPlaceId)
			end)

			if not createServerSuccess then
				warn("ReserveServer failed: " .. tostring(accessCode))
				LoadingEvent:FireClient(player, false)
				return false, "ไม่สามารถสร้างเซิฟเวอร์สำรองได้"
			end

			sessionData[placeKey] = accessCode
			activeSessions:SetAsync(sessionId, sessionData, 86400)
			print("สร้าง ReserveServer ใหม่สำหรับ Placeเป้าหมาย: " .. targetPlaceId)
		else
			LoadingEvent:FireClient(player, true, "กำลังเตรียมเซิฟเวอร์ปลายทาง...")
			print("พบ ReserveServer เดิม กำลังส่งผู้เล่นไปเข้าร่วม...")
		end
	else
		warn("ไม่พบข้อมูล Session กำลังสร้างใหม่...")
		LoadingEvent:FireClient(player, true, "กำลังเตรียมเซิฟเวอร์ใหม่...")

		createServerSuccess, accessCode = pcall(function()
			return TeleportService:ReserveServerAsync(targetPlaceId)
		end)

		if not createServerSuccess then
			warn("ReserveServer failed: " .. tostring(accessCode))
			LoadingEvent:FireClient(player, true, "ไม่สามารถสร้างเซิฟเวอร์")
			task.wait(1.5)
			LoadingEvent:FireClient(player, false)
			return false, "ไม่สามารถสร้างเซิฟเวอร์สำรองได้"
		end

		local newData = {
			HostId = hostId,
			[placeKey] = accessCode
		}
		activeSessions:SetAsync(sessionId, newData, 86400)
	end

	LoadingEvent:FireClient(player, true, "กำลังย้ายผู้เล่น...")

	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ReservedServerAccessCode = accessCode
	teleportOptions:SetTeleportData({
		HostId = hostId,
		SaveSlot = saveSlot,
		SessionId = sessionId,
		SpawnReason = spawnReason -- ส่งสถานะต่อไปยังเซิฟเวอร์ปลายทาง
	})

	local teleportSuccess, err = pcall(function()
		TeleportService:TeleportAsync(targetPlaceId, {player}, teleportOptions)
	end)

	if not teleportSuccess then
		warn("TeleportAsync failed for " .. player.Name .. ": " .. tostring(err))
		LoadingEvent:FireClient(player, true, "ไม่สามารถย้ายผู้เล่นได้ ลองใหม่อีกทีนะ !")
		task.wait(1)
		LoadingEvent:FireClient(player, false)
		return false, "ไม่สามารถ teleport ผู้เล่นได้"
	end

	task.wait(1)
	return true
end

TeleportEvent.OnServerEvent:Connect(function(player, targetPlaceId, spawnReason)
	TeleportPlayerToPlace(player, targetPlaceId, spawnReason)
end)

TeleportFunction.OnInvoke = function(player, targetPlaceId, spawnReason)
	return TeleportPlayerToPlace(player, targetPlaceId, spawnReason)
end
-- END TELEPORT CONTROL --


Players.PlayerAdded:Connect(function(player)
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData

	if RunService:IsStudio() and not teleportData then
		print("🔧 [TESTING] จำลอง TeleportData")
		teleportData = {
			HostId = player.UserId,
			SaveSlot = "save_slot1",
			SessionId = tostring(player.UserId) .. "_save_slot1",
			--SpawnReason = "Exhausted" -- สำหรับทดสอบใน Studio
		}
	end

	-- ดักจับการเกิดของตัวละคร (ถ้าสลบมา ให้บังคับเกิดที่เตียง)
	player.CharacterAdded:Connect(function(character)
		if teleportData and teleportData.SpawnReason == "Exhausted" then
			local hrp = character:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				-- รอ physics โหลดเสร็จเล็กน้อยแล้วย้ายพิกัด
				task.wait(0.1)
				character:PivotTo(HOME_SPAWN_LOCATION)
				print(player.Name .. " ตื่นนอนที่บ้านเพราะสลบมาจากแมพอื่น")
			end
		end
	end)

	if teleportData and teleportData.HostId and teleportData.SaveSlot then
		local hostId = teleportData.HostId
		local saveSlot = teleportData.SaveSlot

		if not DataManager.WorldData then
			DataManager.LoadWorldData(hostId, saveSlot)
		end

		DataManager.LoadPlayerData(player, hostId, saveSlot)
		print("[DataController] Player data Loaded : " .. player.Name)
	else
		warn("[DataController] : Can't find TeleportData for " .. player.Name)
	end

	task.wait(0.5)
	LoadingEvent:FireClient(player, false)
end)

Players.PlayerRemoving:Connect(function(player)
	if DataManager.HostId then
		DataManager.SaveSinglePlayer(player)
	end
end)

game:BindToClose(function()
	if DataManager.HostId then
		local res, msg = pcall(function() return DataManager.WorldSaving:Invoke() end)

		while not res do
			task.wait(1)
			res, msg = pcall(function() return DataManager.WorldSaving:Invoke() end)
		end

		DataManager.SaveWorldData()
		DataManager.UpdateMenuInfo()

		for _, player in ipairs(Players:GetPlayers()) do
			DataManager.SaveSinglePlayer(player)
		end

		task.wait(2)
	end
end)