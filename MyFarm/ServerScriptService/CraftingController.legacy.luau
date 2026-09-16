local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- อ้างอิง Module จากระบบเดิม
local CraftingRecipes = require(ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("CraftingRecipes"))
local DataManager = require(ServerScriptService:WaitForChild("DataManagerModule")) -- ดึง DataManager มาใช้[cite: 3]
local ItemDatabase = require(ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("ItemDatabase")) --[cite: 3]

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local CraftItemEvent = RemoteEvent:WaitForChild("CraftItemEvent")
local SyncItemEvent = RemoteEvent:WaitForChild("SyncItemEvent") --[cite: 3]
local SideNotiEvent = RemoteEvent:WaitForChild("SideNotiEvent") --[cite: 3]

CraftItemEvent.OnServerEvent:Connect(function(player, recipeKey)
	local recipe = CraftingRecipes[recipeKey]
	if not recipe then return end 

	-- 🌟 ดึงข้อมูลกระเป๋าจาก DataManager[cite: 3]
	local pData = DataManager.PlayersData[player.UserId]
	if not pData or not pData.player_items then return end

	local playerInventory = pData.player_items

	-- 1. เช็คว่ามีของครบจริงๆ ใช่ไหม (ตรวจสอบบน Server เพื่อความปลอดภัย)
	local canCraft = true
	for _, ingredient in pairs(recipe.Ingredients) do
		local reqAmount = ingredient.Amount
		local playerHasAmount = playerInventory[ingredient.Name] or 0

		if playerHasAmount < reqAmount then
			canCraft = false
			break
		end
	end

	-- 2. ถ้ามีของครบ ดำเนินการหักของและให้ของ
	if canCraft then
		-- หักวัตถุดิบ
		for _, ingredient in pairs(recipe.Ingredients) do
			local currentAmount = playerInventory[ingredient.Name]

			-- 🌟 หักจำนวนใน DataManager[cite: 3]
			playerInventory[ingredient.Name] = currentAmount - ingredient.Amount

			-- ตรวจสอบว่าของหมดกระเป๋าหรือยัง[cite: 3]
			if playerInventory[ingredient.Name] <= 0 then
				playerInventory[ingredient.Name] = nil -- ลบออกจากฐานข้อมูล[cite: 3]

				-- ถอด Tool ออกจากมือถ้าถือของที่เพิ่งหมดไป (อิงจากระบบ ConsumeItem)[cite: 3]
				local character = player.Character
				if character then
					local tool = character:FindFirstChild(ingredient.Name)
					if tool then tool:Destroy() end
				end
			end

			-- อัปเดตไปยัง UI ของผู้เล่น[cite: 3]
			SyncItemEvent:FireClient(player, ingredient.Name, -ingredient.Amount)
		end

		-- ให้ของที่คราฟต์สำเร็จ
		local resultItem = recipe.ResultItem
		local resultInfo = ItemDatabase[resultItem]

		-- 🌟 เพิ่มไอเทมเข้า player_items[cite: 3]
		playerInventory[resultItem] = (playerInventory[resultItem] or 0) + 1

		-- แจ้ง Client ให้เพิ่มของและขึ้นแจ้งเตือน[cite: 3]
		SyncItemEvent:FireClient(player, resultItem, 1)

		if resultInfo then
			SideNotiEvent:FireClient(player, resultInfo.ItemName, 1) -- แสดงแจ้งเตือนด้านข้างจอ[cite: 3]
			print(player.Name .. " คราฟต์ " .. resultInfo.ItemName .. " สำเร็จ!")
		end
	else
		warn(player.Name .. " พยายามคราฟต์ของแต่ไอเทมไม่ครบ!")
	end
end)