local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SeedShopEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("SeedShopEvent")

-- ==========================================
-- 1. การตั้งค่าระบบจำลองเงินและอ้างอิง GUI
-- ==========================================
local simulatedPlayerMoney = 500 -- จำลองเงินเริ่มต้นของผู้เล่น

-- อ้างอิงไปยังตำแหน่งต่างๆ ของ GUI อิงตามภาพโครงสร้าง
local gui = script.Parent
local frame = gui:WaitForChild("Frame")
local scrollingFrame = frame:WaitForChild("ScrollingFrame")
local itemTemplate = scrollingFrame:WaitForChild("ItemTemplate")
local closeBtn = frame:WaitForChild("CloseBtn")

-- ซ่อน Template ต้นฉบับไว้ เพื่อไม่ให้แสดงเป็นช่องว่างๆ ในร้านค้า
itemTemplate.Visible = false

-- ==========================================
-- 2. สร้าง Table รายการไอเทม
-- ==========================================
local shopItems = {
	{
		Id = "sword_001",
		Name = "ดาบไม้เริ่มต้น",
		Price = 50,
		ImageId = "rbxassetid://0" -- เปลี่ยนเลข 0 เป็น Asset ID รูปภาพของคุณ
	},
	{
		Id = "potion_001",
		Name = "น้ำยาฟื้นฟู (เล็ก)",
		Price = 20,
		ImageId = "rbxassetid://0" 
	},
	{
		Id = "shield_001",
		Name = "โล่ไม้โอ๊ค",
		Price = 100,
		ImageId = "rbxassetid://0" 
	},
	{
		Id = "shield_001",
		Name = "โล่ไม้โอ๊ค",
		Price = 100,
		ImageId = "rbxassetid://0" 
	}
}

-- ==========================================
-- 3. ฟังก์ชันสำหรับสร้างร้านค้า
-- ==========================================
local function generateShop()
	-- วนลูปตามจำนวนไอเทมที่มีใน Table
	for index, itemData in ipairs(shopItems) do
		
		-- โคลน Template เพื่อสร้างช่องไอเทมใหม่
		local newItemFrame = itemTemplate:Clone()
		newItemFrame.Name = itemData.Id
		newItemFrame.Visible = true
		newItemFrame.Parent = scrollingFrame
		
		-- ตั้งค่าข้อมูลให้แสดงผลตรงกับ UI
		newItemFrame:WaitForChild("ItemName").Text = itemData.Name
		newItemFrame:WaitForChild("ItemPrice").Text = tostring(itemData.Price) .. " Coins"
		newItemFrame:WaitForChild("ItemImage").Image = itemData.ImageId
		
		-- ฟังก์ชันย่อยสำหรับจัดการการซื้อและคำนวณเงิน
		local function buyItem(amount)
			local totalCost = itemData.Price * amount
			
			print("-----------------------------------")
			print("กำลังตรวจสอบการซื้อ: " .. itemData.Name .. " จำนวน " .. amount .. " ชิ้น")
			
			if simulatedPlayerMoney >= totalCost then
				-- หักเงินจำลอง
				simulatedPlayerMoney = simulatedPlayerMoney - totalCost
				print("✅ ซื้อสำเร็จ! คุณจ่ายไป " .. totalCost .. " Coins")
				print("💰 เงินจำลองคงเหลือ: " .. simulatedPlayerMoney .. " Coins")
			else
				print("❌ ซื้อไม่สำเร็จ! เงินไม่พอ (ต้องการ " .. totalCost .. " Coins แต่คุณมีแค่ " .. simulatedPlayerMoney .. " Coins)")
			end
			print("-----------------------------------")
		end
		
		-- ผูกปุ่มเข้ากับฟังก์ชันย่อยข้างต้น
		newItemFrame:WaitForChild("Buy_1").MouseButton1Click:Connect(function()
			buyItem(1)
		end)
		
		newItemFrame:WaitForChild("Buy_2").MouseButton1Click:Connect(function()
			buyItem(2)
		end)
		
		newItemFrame:WaitForChild("Buy_4").MouseButton1Click:Connect(function()
			buyItem(4)
		end)
	end
end

-- ==========================================
-- 4. เรียกใช้งานฟังก์ชันเมื่อ Script เริ่มทำงาน
-- ==========================================
task.spawn(generateShop)

SeedShopEvent.OnClientEvent:Connect(function()
    generateShop()
    frame.Visible = true
end)

closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
end)