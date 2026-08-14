local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("ItemDatabase"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- อ้างอิง RemoteEvent สำหรับสวมใส่ไอเทม (ต้องสร้าง EquipItemEvent ไว้ใน ReplicatedStorage)
local BindableEvent = ReplicatedStorage:WaitForChild("BindableEvent")
local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local equipEvent = RemoteEvent:WaitForChild("EquipItemEvent")
local SyncItemEvent = RemoteEvent:WaitForChild("SyncItemEvent")
local getDataFunction = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetPlayerData")

local toggleInventoryEvent = BindableEvent:WaitForChild("ToggleInventory")
local equipHotbarEvent = BindableEvent:WaitForChild("EquipHotbar")

-- อ้างอิง UI
local gui = script.Parent
local hotbarFrame = gui:WaitForChild("HotbarFrame")
local inventoryFrame = gui:WaitForChild("InventoryFrame")
local scrollFrame = inventoryFrame:WaitForChild("ScrollingFrame")
local inventoryCloseBtn = inventoryFrame:WaitForChild("CloseBtn")
-- จัดการ Template ของ Inventory
local itemTemplate = scrollFrame:WaitForChild("ItemTemplate")
itemTemplate.Visible = false -- ซ่อนตัวต้นแบบไว้ เพื่อใช้ Clone เท่านั้น

-- โครงสร้างข้อมูล (Data)
local MAX_HOTBAR_SLOTS = 5
local inventoryData = {}
local hotbarData = {nil, nil, nil, nil, nil}
local currentEquippedSlot = nil

local draggingItemName = nil
local draggingItemIndex = nil
local draggingFromHotbar = nil
local dragGhost = nil


-- ==========================================
-- ฟังก์ชันหลัก: อัปเดตหน้าจอ (UI)
-- ==========================================
local function UpdateUI()
	-- 1. อัปเดต Hotbar
	for i = 1, MAX_HOTBAR_SLOTS do
		local slotUI = hotbarFrame:FindFirstChild("Slot" .. i)
		if slotUI then
			local nameLabel = slotUI:FindFirstChild("ItemName")
			local amountLabel = slotUI:FindFirstChild("ItemAmout")
			local imageLabel = slotUI:FindFirstChild("ItemImage")

			local itemName = hotbarData[i]
			
			if itemName ~= nil then
				-- ดึงจำนวนไอเทมจาก Dictionary โดยใช้ชื่อเป็น Key
				local amount = inventoryData[itemName] or 0 
				local itemInfo = ItemDatabase[itemName]

				if nameLabel then nameLabel.Text = (itemInfo and itemInfo.ItemName) or itemName  end
				if amountLabel then amountLabel.Text = "x" .. tostring(amount) end
				if imageLabel then 
					if itemInfo and itemInfo.Icon then
						imageLabel.Image = itemInfo.Icon
					else
						if imageLabel then 
							imageLabel.Image = ""
							imageLabel.ImageTransparency = 1 
						end
					end
					imageLabel.ImageTransparency = 0	
				else
					print("not found image obj")
				end
			else
				-- ถ้าไม่มีไอเทมในช่องนี้, ให้ค่าว่าง
				if nameLabel then nameLabel.Text = "" end
				if amountLabel then amountLabel.Text = "" end
				if imageLabel then imageLabel.ImageTransparency = 1 end
			end

			if i == currentEquippedSlot then
				local uiStroke = slotUI:FindFirstChild("ItemImage"):FindFirstChildWhichIsA("UIStroke")
				if uiStroke then
					uiStroke.Enabled = true
				end
			else
				local uiStroke = slotUI:FindFirstChild("ItemImage"):FindFirstChildWhichIsA("UIStroke")
				if uiStroke then
					uiStroke.Enabled = false
				end
			end
		end
	end

	-- 2. อัปเดต Inventory
	-- ล้างของเก่าออกก่อน (ยกเว้น UIListLayout, UIPadding, และ ItemTemplate)
	for _, child in pairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "ItemTemplate" then
			child:Destroy()
		end
	end

	-- สร้างช่องไอเทมใหม่ตามข้อมูล
	local index = 1
	for itemName, amount in pairs(inventoryData) do
		-- *** เช็คว่าไอเทมนี้อยู่ใน Hotbar แล้วหรือยัง ***
		local inHotbar = false
		for i = 1, MAX_HOTBAR_SLOTS do
			if hotbarData[i] == itemName then
				inHotbar = true
				break
			end
		end

		-- ถ้าไอเทมนี้ "ไม่ได้" อยู่ใน Hotbar ถึงจะให้แสดงในหน้ากระเป๋า
		if not inHotbar then
			local newSlot = itemTemplate:Clone()
			newSlot.Name = "InvSlot_" .. index
			newSlot.Visible = true
			newSlot.Parent = scrollFrame

			local nameLabel = newSlot:FindFirstChild("ItemName")
			local amountLabel = newSlot:FindFirstChild("ItemAmout") 
			local imageLabel = newSlot:FindFirstChild("ItemImage")
			local itemDescriptionBG = newSlot:FindFirstChild("ItemDescriptionBG")
			local itemDescription = itemDescriptionBG:FindFirstChild("ItemDescription")
			local itemInfo = ItemDatabase[itemName]
			
			if nameLabel then 
				nameLabel.Text = (itemInfo and itemInfo.ItemName) or itemName 
			end
			if amountLabel then amountLabel.Text = "x" .. tostring(amount) end 
			if itemDescriptionBG then
				-- ดึงคำอธิบายจาก Module
				if itemInfo and itemInfo.Description then
					itemDescription.Text = itemInfo.Description
				else
					itemDescription.Text = "ไม่มีคำอธิบาย"
				end

				-- เมื่อเอาเมาส์ชี้ที่กรอบไอเทม (Hover In)
				newSlot.MouseEnter:Connect(function()
					itemDescriptionBG.Visible = true
				end)

				-- เมื่อเอาเมาส์ออก (Hover Out)
				newSlot.MouseLeave:Connect(function()
					itemDescriptionBG.Visible = false
				end)
			end
			if imageLabel then 
				if itemInfo and itemInfo.Icon then
					print(itemInfo.Icon)
					imageLabel.Image = itemInfo.Icon
				else
					imageLabel.Image = ""
				end
				imageLabel.ImageTransparency = 0
			else
				print("not found image obj in inv")
			end

			SetupDragAndDrop(newSlot, itemName, index)
			index = index + 1
		end
	end
end

-- ==========================================
-- ฟังก์ชันหลัก: โหลดข้อมูล (UI)
-- ==========================================
local function Initialize()
	print("กำลังโหลดข้อมูล...")
	local data = getDataFunction:InvokeServer()

	-- ** เจาะจงดึงข้อมูลเฉพาะส่วนที่เป็น inventory **
	local inventoryToLoad = data.inventory or {}

	-- นำข้อมูลที่ได้มาใส่ในระบบ (วนลูปจาก inventoryToLoad แทน)
	local slot = 1
	for itemName, amount in pairs(inventoryToLoad) do
		if slot <= 5 then
			hotbarData[slot] = itemName
			slot = slot + 1
		end
		inventoryData[itemName] = amount
	end
	UpdateUI()
end
-- ==========================================
-- ระบบสวมใส่ (Equip)
-- ==========================================
local function ToggleEquip(slotIndex)
	local itemName = hotbarData[slotIndex]

	if itemName == nil then return end -- ช่องว่าง ไม่ต้องทำอะไร

	if currentEquippedSlot == slotIndex then
		currentEquippedSlot = nil
		equipEvent:FireServer(nil) -- เก็บของ
	else
		currentEquippedSlot = slotIndex
		equipEvent:FireServer(itemName) -- ถือของใหม่
	end

	UpdateUI()
end

-- ==========================================
-- ระบบ Drag & Drop
-- ==========================================
function SetupDragAndDrop(uiElement, itemName, invIndex)
	uiElement.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingItemName = itemName
			draggingItemIndex = invIndex

			-- สร้างภาพจำลอง (Ghost) โดยใช้ Template ของคุณเลย จะได้สวยงาม
			dragGhost = itemTemplate:Clone()
			dragGhost.Name = "DragGhost"
			dragGhost.Size = UDim2.new(0, uiElement.AbsoluteSize.X, 0, uiElement.AbsoluteSize.Y)
			dragGhost.Visible = true
			dragGhost.ZIndex = 100 -- ให้อยู่บนสุด

			local gName = dragGhost:FindFirstChild("ItemName")
			local gAmount = dragGhost:FindFirstChild("ItemAmout")
			
			local itemInfo = ItemDatabase[itemName] -- ต้องดึงข้อมูล Module มาด้วย

			if gName then 
				gName.Text = (itemInfo and itemInfo.ItemName) or itemName 
			end
			
			if gAmount then gAmount.Text = "x1" end

			-- เอา Constraint ออกชั่วคราวเพื่อให้อิสระตอนลาก
			local ratio = dragGhost:FindFirstChildWhichIsA("UIAspectRatioConstraint")
			if ratio then ratio:Destroy() end

			dragGhost.Parent = gui
		end
	end)
end

-- ให้ Ghost วิ่งตามเมาส์
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragGhost then
		dragGhost.Position = UDim2.new(0, mouse.X - (dragGhost.AbsoluteSize.X/2), 0, mouse.Y - (dragGhost.AbsoluteSize.Y/2))
	end
end)

-- ปล่อยเมาส์
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and dragGhost then
		local playerGui = player:WaitForChild("PlayerGui")
		local guisAtPosition = playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)

		local droppedOnHotbar = false
		local targetSlot = nil

		for _, hitGui in ipairs(guisAtPosition) do
			if hitGui.Name:match("^Slot(%d+)$") then
				targetSlot = tonumber(hitGui.Name:match("%d+"))
				droppedOnHotbar = true
				break
			end
		end

		if droppedOnHotbar then
			-- *** กรณีที่ 1: ลากมาปล่อยลงใน Hotbar ***
			if draggingFromHotbar then
				-- 1.1 ลากจาก Hotbar ไป Hotbar 
				if targetSlot == draggingFromHotbar then
					-- ปล่อยลงช่องเดิม = ถือว่าผู้เล่นตั้งใจกด Equip
					ToggleEquip(targetSlot)
				else
					-- ปล่อยลงช่องอื่น = สลับที่ไอเทม
					local temp = hotbarData[targetSlot]
					hotbarData[targetSlot] = draggingItemName
					hotbarData[draggingFromHotbar] = temp

					-- ถ้าย้ายช่องที่กำลังถืออยู่ ให้เก็บของก่อน
					if currentEquippedSlot == targetSlot or currentEquippedSlot == draggingFromHotbar then
						currentEquippedSlot = nil
						equipEvent:FireServer(nil)
					end
				end
			else
				-- 1.2 ลากจากกระเป๋ามา Hotbar (ดึงโค้ดเดิมมาใช้)
				local oldSlotIndex = nil
				for i = 1, MAX_HOTBAR_SLOTS do
					if hotbarData[i] == draggingItemName then oldSlotIndex = i break end
				end

				local currentHotbarItem = hotbarData[targetSlot]
				if oldSlotIndex then hotbarData[oldSlotIndex] = currentHotbarItem end
				hotbarData[targetSlot] = draggingItemName

				if currentEquippedSlot == targetSlot or currentEquippedSlot == oldSlotIndex then
					currentEquippedSlot = nil
					equipEvent:FireServer(nil)
				end
			end
		else
			-- *** กรณีที่ 2: ลากไปปล่อยที่อื่น (นอก Hotbar) ***
			if draggingFromHotbar then
				-- ถอดไอเทมออกจาก Hotbar กลับเข้ากระเป๋า
				hotbarData[draggingFromHotbar] = nil
				if currentEquippedSlot == draggingFromHotbar then
					currentEquippedSlot = nil
					equipEvent:FireServer(nil)
				end
			end
		end

		UpdateUI()

		-- ล้างค่าตัวแปรลากวางทั้งหมด
		dragGhost:Destroy()
		dragGhost = nil
		draggingItemName = nil
		draggingItemIndex = nil
		draggingFromHotbar = nil
	end
end)
-- ==========================================
-- ควบคุมการกดปุ่ม (Input)
-- ==========================================

-- ผูกการคลิกซ้ายที่ช่อง Hotbar ให้ทำงานเหมือนกดเลข 1-5
for i = 1, MAX_HOTBAR_SLOTS do
	local slotUI = hotbarFrame:WaitForChild("Slot" .. i):WaitForChild("ItemImage")

	slotUI.InputBegan:Connect(function(input)
		local itemName = hotbarData[i]

		-- 1. คลิกขวา (ถอดไอเทมกลับเข้ากระเป๋า)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			if itemName ~= nil then
				hotbarData[i] = nil -- ลบชื่อออกจาก Hotbar

				-- ถ้ากำลังถือไอเทมช่องนี้อยู่ ให้เก็บของด้วย
				if currentEquippedSlot == i then
					currentEquippedSlot = nil
					equipEvent:FireServer(nil)
				end
				UpdateUI()
			end
		end

		-- 2. คลิกซ้ายค้าง (เตรียมลากไอเทมจาก Hotbar)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and itemName ~= nil then
			draggingItemName = itemName
			draggingFromHotbar = i -- บันทึกไว้ว่าดึงมาจากช่องไหน

			-- สร้างภาพจำลอง (Ghost)
			dragGhost = itemTemplate:Clone()
			dragGhost.Name = "DragGhost"
			dragGhost.Size = UDim2.new(0, slotUI.AbsoluteSize.X, 0, slotUI.AbsoluteSize.Y)
			dragGhost.Visible = true
			dragGhost.ZIndex = 100

			local gName = dragGhost:FindFirstChild("ItemName")
			local gAmount = dragGhost:FindFirstChild("ItemAmout")
			if gName then gName.Text = itemName end
			if gAmount then gAmount.Text = "x" .. tostring(inventoryData[itemName] or 1) end

			local ratio = dragGhost:FindFirstChildWhichIsA("UIAspectRatioConstraint")
			if ratio then ratio:Destroy() end

			dragGhost.Parent = gui
		end
	end)
end

-- ==========================================
-- รอรับคำสั่งจาก InputManager
-- ==========================================
toggleInventoryEvent.Event:Connect(function()
	inventoryFrame.Visible = not inventoryFrame.Visible
end)

equipHotbarEvent.Event:Connect(function(slotIndex)
	ToggleEquip(slotIndex)
end)

-- ==========================================
-- ควบคุมเปิดปิดที่ปุ่ม
-- ==========================================

inventoryCloseBtn.Activated:Connect(function()
	inventoryFrame.Visible = false
end)

-- ==========================================
-- ระบบรับไอเทม unit test
-- ==========================================
local function GiveItem(itemName)
	-- ถ้ามีไอเทมนี้อยู่แล้ว ให้เพิ่มจำนวน
	if inventoryData[itemName] then
		inventoryData[itemName] = inventoryData[itemName] + 1
	else
		-- ถ้ายังไม่มี ให้ตั้งค่าเป็น 1
		inventoryData[itemName] = 1
		-- ลองหาที่ว่างใน Hotbar เพื่อเอาชื่อไปใส่
		for i = 1, MAX_HOTBAR_SLOTS do
			if hotbarData[i] == nil then
				hotbarData[i] = itemName
				break
			end
		end
	end
	UpdateUI()
end

task.spawn(Initialize)

SyncItemEvent.OnClientEvent:Connect(function(itemName, amount)
	-- ถ้ามีไอเทมนี้อยู่แล้ว ให้บวก (หรือลบ) จำนวน
	if inventoryData[itemName] then
		inventoryData[itemName] = inventoryData[itemName] + amount
	else
		-- ถ้ายังไม่มี ให้กำหนดจำนวนตามที่ได้มา
		inventoryData[itemName] = amount

		-- ลองหาที่ว่างใน Hotbar เพื่อเอาชื่อไปใส่ก่อน (เฉพาะเวลาได้รับของใหม่)
		if amount > 0 then
			for i = 1, MAX_HOTBAR_SLOTS do
				if hotbarData[i] == nil then
					hotbarData[i] = itemName
					break
				end
			end
		end
	end

	if inventoryData[itemName] <= 0 then
		inventoryData[itemName] = nil -- ลบออกจาก Dictionary กระเป๋า

		-- ค้นหาและถอดออกจาก Hotbar
		for i = 1, MAX_HOTBAR_SLOTS do
			if hotbarData[i] == itemName then
				hotbarData[i] = nil

				-- ถ้ากำลังถือช่องที่ของเพิ่งหมดไป ให้ยกเลิกการถือ (Unequip)
				if currentEquippedSlot == i then
					currentEquippedSlot = nil
					equipEvent:FireServer(nil)
				end
				break
			end
		end
	end

	-- อัปเดต UI เพื่อให้รูปไอเทมและตัวเลขเปลี่ยนทันที
	UpdateUI()
end)