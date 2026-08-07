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
		["time"] = { ["clock_time"] = 7, ["day"] = 1, ["season"] = 1, ["year"] = 1 },
		["world_stats"] = { ["environment"] = 50, ["social"] = 50 },
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
    local success, data = pcall(function() return GameSaveDS:GetAsync(playerKey) end)

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
	if not FarmDataManager.WorldData or not FarmDataManager.HostId then return end

	-- 3.1 บันทึก World Data (แปลงผัก)
	local worldKey = FarmDataManager.HostId .. "_" .. FarmDataManager.SaveSlot .. "_World"
	pcall(function() GameSaveDS:SetAsync(worldKey, FarmDataManager.WorldData) end)

	-- 3.2 บันทึก Player Data ของทุกคนที่ยืนอยู่ในฟาร์มตอนนี้
	for userId, pData in pairs(FarmDataManager.PlayersData) do
		local playerKey = FarmDataManager.HostId .. "_" .. FarmDataManager.SaveSlot .. "_" .. tostring(userId)
		pcall(function() GameSaveDS:SetAsync(playerKey, pData) end)
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
	
	if pData then
		local playerKey = FarmDataManager.HostId .. "_" .. FarmDataManager.SaveSlot .. "_" .. tostring(player.UserId)
		pcall(function() GameSaveDS:SetAsync(playerKey, pData) end)
		
		-- เคลียร์ของออกจากแรมเซิร์ฟเวอร์เมื่อวาร์ปออกไปแล้ว
		FarmDataManager.PlayersData[player.UserId] = nil 
		print("💾 บันทึกข้อมูลส่วนตัวของ " .. player.Name .. " ก่อนวาร์ปสำเร็จ!")
	end
end

return FarmDataManager