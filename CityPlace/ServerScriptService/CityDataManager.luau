local CityDataManager = {}
local DataStoreService = game:GetService("DataStoreService")

-- ⚠️ ใช้ชื่อ DataStore ตัวใหม่ให้ตรงกับหน้า Main Menu และแมพฟาร์ม
local GameSaveDS = DataStoreService:GetDataStore("FarmingGame_Data_V2")

CityDataManager.HostId = nil
CityDataManager.SaveSlot = nil
CityDataManager.PlayersData = {} 

-- ==========================================
-- ฟังก์ชันจำลองข้อมูลกระเป๋าเริ่มต้น (ถ้ายังไม่เคยเล่น)
-- ==========================================
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

-- ==========================================
-- 1. โหลดข้อมูลกระเป๋าผู้เล่น (เรียกเมื่อมีคนวาร์ปเข้าเมือง)
-- ==========================================
function CityDataManager.LoadPlayerData(player, hostId, saveSlot)
	-- บันทึก Session ของโฮสต์ไว้ใช้อ้างอิง
	if not CityDataManager.HostId then
		CityDataManager.HostId = tostring(hostId)
		CityDataManager.SaveSlot = saveSlot
	end

	-- คีย์กระเป๋าจะผูกกับ HostId + SaveSlot เพื่อป้องกันการเอาของข้ามเซฟ
	local playerKey = tostring(hostId) .. "_" .. saveSlot .. "_" .. tostring(player.UserId)
	print("กำลังโหลด PlayerData ในเมือง: " .. playerKey)

	local success, data = pcall(function() 
		return GameSaveDS:GetAsync(playerKey) 
	end)

	if success and data then
		CityDataManager.PlayersData[player.UserId] = data
		print("🎒 โหลดข้อมูลกระเป๋าของ " .. player.Name .. " สำเร็จ!")
	else
		CityDataManager.PlayersData[player.UserId] = getDefaultPlayerData(player.Name)
		print("✨ สร้างกระเป๋าเริ่มต้นใหม่ให้ " .. player.Name)
	end
end

-- ==========================================
-- 2. บันทึกข้อมูลกระเป๋าเฉพาะบุคคล (เรียกเมื่อคนนั้นกดออกเกม หรือวาร์ปไปฟาร์ม)
-- ==========================================
function CityDataManager.SaveSinglePlayer(player)
	local pData = CityDataManager.PlayersData[player.UserId]

	if pData then
		local playerKey = CityDataManager.HostId .. "_" .. CityDataManager.SaveSlot .. "_" .. tostring(player.UserId)

		local success, errorMessage = pcall(function() 
			GameSaveDS:SetAsync(playerKey, pData) 
		end)

		if success then
			print("💾 บันทึกข้อมูลของ " .. player.Name .. " ลง DataStore สำเร็จ!")
		else
			warn("❌ บันทึกข้อมูลของ " .. player.Name .. " ไม่สำเร็จ: " .. tostring(errorMessage))
		end

		-- ลบข้อมูลออกจาก Memory ของเซิร์ฟเวอร์เพื่อคืนพื้นที่
		CityDataManager.PlayersData[player.UserId] = nil
	end
end

-- ==========================================
-- 3. อัปเดตหน้าปกเซฟ (เรียกเมื่อเซิร์ฟเวอร์จะปิด หรือโฮสต์ออกจากเมือง)
-- ==========================================
function CityDataManager.UpdateMenuInfo()
	if not CityDataManager.HostId or not CityDataManager.SaveSlot then return end

	local menuInfoKey = CityDataManager.HostId .. "_MenuInfo"

	local success, err = pcall(function()
		GameSaveDS:UpdateAsync(menuInfoKey, function(oldData)
			local saves = oldData or {}

			if saves[CityDataManager.SaveSlot] then
				-- บันทึกว่าตำแหน่งล่าสุดของเซฟนี้คือ "เมือง"
				saves[CityDataManager.SaveSlot].last_place_id = game.PlaceId
			end

			return saves
		end)
	end)

	if success then
		print("🗺️ อัปเดตหน้าปกเซฟ: แมพล่าสุดคือ City (ID: " .. game.PlaceId .. ")")
	else
		warn("❌ อัปเดตหน้าปกเซฟไม่สำเร็จ: " .. tostring(err))
	end
end

return CityDataManager