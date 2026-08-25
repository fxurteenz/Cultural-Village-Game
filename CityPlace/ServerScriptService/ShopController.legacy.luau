local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local DataManager = require(ServerScriptService:WaitForChild("DataManagerModule"))

local ShopEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("ShopEvent")
local GiveItemBindable = ServerStorage:WaitForChild("BindableEvent"):WaitForChild("GiveItemBindable")

-- ==========================================
-- 2. สร้าง Table รายการไอเทม (ฝั่ง Server)
-- ควรมีข้อมูลอยู่ที่นี่เพื่อป้องกันการ exploit จากฝั่ง client
-- ==========================================
local shopItems = {
	["RiceSprout"] = {
		Name = "ต้นกล้าข้าว",
		Price = 5,
	},
	-- สามารถเพิ่มไอเทมอื่นๆ ที่นี่ได้
}

-- ==========================================
-- 3. ฟังก์ชันสำหรับจัดการการซื้อ
-- ==========================================
local function onPurchaseRequest(player, action, itemId, amount)
	if action ~= "PurchaseItem" then return end

	local pData = DataManager.PlayersData[player.UserId]
	if not pData then
		warn("ไม่สามารถทำรายการซื้อได้เนื่องจากข้อมูลผู้เล่น " .. player.Name .. " ยังไม่ถูกโหลด")
		return
	end

	local itemData = shopItems[itemId]
	if not itemData then
		warn(player.Name .. " พยายามซื้อไอเทมที่ไม่มีในร้านค้า: " .. tostring(itemId))
		return
	end

	local totalPrice = itemData.Price * amount

	if pData.coins >= totalPrice then
		-- 1. หักเงินผู้เล่น
		pData.coins = pData.coins - totalPrice
		print("✅ ผู้เล่น " .. player.Name .. " ซื้อ " .. itemId .. " จำนวน " .. amount .. " ชิ้น | คงเหลือ " .. pData.coins .. " Coins")

		-- 2. มอบไอเทมให้ผู้เล่นผ่าน BindableEvent
		GiveItemBindable:Fire(player, itemId, amount)
	else
		print("❌ ผู้เล่น " .. player.Name .. " มีเงินไม่พอที่จะซื้อ " .. itemId)
		-- อาจจะส่ง Event กลับไปบอก Client ว่าเงินไม่พอ
	end
end

-- เชื่อมต่อ Event จาก Client
ShopEvent.OnServerEvent:Connect(onPurchaseRequest)