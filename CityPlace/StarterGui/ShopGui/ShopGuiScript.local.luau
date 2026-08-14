local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("ShopEvent")
local SeedShopBindable = ReplicatedStorage:WaitForChild("BindableEvent"):WaitForChild("SeedShop")
local EconomyService = require(ReplicatedStorage.Module.EconomyService)

-- ==========================================
-- 1. การตั้งค่าระบบจำลองเงินและอ้างอิง GUI
-- ==========================================
local currentPlayerMoney = 0 -- จะถูกอัปเดตจาก EconomyService

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
		Id = "RiceSprout",
		Name = "ต้นกล้าข้าว",
		Price = 5,
		ImageId = "rbxassetid://0" 
	},

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
		
		-- ฟังก์ชันสำหรับส่งคำขอซื้อไปยังเซิร์ฟเวอร์
		local function requestPurchase(itemId, amount)
			print("🛒 ส่งคำขอซื้อ: " .. itemId .. " จำนวน " .. amount .. " ชิ้น")
			ShopEvent:FireServer("PurchaseItem", itemId, amount)
		end
		
		-- ผูกปุ่มเข้ากับฟังก์ชันย่อยข้างต้น
		newItemFrame:WaitForChild("Buy_1").MouseButton1Click:Connect(function() requestPurchase(itemData.Id, 1) end)
		
		newItemFrame:WaitForChild("Buy_2").MouseButton1Click:Connect(function() requestPurchase(itemData.Id, 2) end)
		
		newItemFrame:WaitForChild("Buy_4").MouseButton1Click:Connect(function() requestPurchase(itemData.Id, 4) end)
	end
end

-- ==========================================
-- 4. เรียกใช้งานฟังก์ชันเมื่อ Script เริ่มทำงาน
-- ==========================================
task.spawn(generateShop)

SeedShopBindable.Event:Connect(function(action)
    frame.Visible = true
end)

-- รับการอัปเดตเงินจาก EconomyService
EconomyService:ListenForCurrencyChanges(function(newBalance)
    currentPlayerMoney = newBalance
end)

closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
end)