local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local TeleportEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("TeleportEvent")
local JoinEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("JoinEvent")

local FARM_PLACE_ID = 106110521945291 

local activeFarmsMap = MemoryStoreService:GetSortedMap("ActiveFarms")

TeleportEvent.OnServerEvent:Connect(function(player, targetPlace)
	if targetPlace == "Farm" then
		print("กำลังสร้างฟาร์มส่วนตัวให้:", player.Name)

		-- 1. จองห้องเซิร์ฟเวอร์แบบส่วนตัว (จะไม่มีใครเข้ามาได้นอกจากเราเชิญ)
		local reservedCode, reserveId = pcall(function()
			return TeleportService:ReserveServerAsync(FARM_PLACE_ID)
		end)

		if reservedCode then
			local saveSuccess, saveErr = pcall(function()
				activeFarmsMap:SetAsync(tostring(player.UserId), reservedCode, 86400)
			end)
			if saveSuccess then
				local teleportSuccess, errorMessage = pcall(function()
					TeleportService:TeleportToPrivateServer(FARM_PLACE_ID, reserveId, {player})
				end)

				if not teleportSuccess then
					warn("Teleport ล้มเหลว: " .. tostring(errorMessage))
				end
			else
				warn("บันทึกreserveCode ล้มเหลว: " .. tostring(saveErr))
			end
		else
			warn("ไม่สามารถ Reserve Server ได้")
		end
	end
end)

JoinEvent.OnServerEvent:Connect(function(player, targetFriendUserId)

	-- 1. ไปค้นหากุญแจห้องฟาร์มของเพื่อนจาก MemoryStore
	local success, accessCode = pcall(function()
		return activeFarmsMap:GetAsync(tostring(targetFriendUserId))
	end)

	if success and accessCode then
		-- 2. ถ้าเจอกุญแจ แปลว่าเพื่อนอยู่ในฟาร์ม ให้วาปตามไปเลย
		print("กำลังส่ง " .. player.Name .. " ไปยังฟาร์มของเพื่อน")
		TeleportService:TeleportToPrivateServer(FARM_PLACE_ID, accessCode, {player})
	else
		-- 3. ถ้าไม่เจอ แปลว่าฟาร์มปิดอยู่ หรือเพื่อนไม่ได้อยู่ในฟาร์ม
		print("ฟาร์มของเพื่อนปิดอยู่ หรือเกิดข้อผิดพลาด")
		-- คุณอาจจะ FireClient กลับไปบอก UI ผู้เล่นว่า "เพื่อนไม่ได้อยู่ในฟาร์ม"
	end
end)
