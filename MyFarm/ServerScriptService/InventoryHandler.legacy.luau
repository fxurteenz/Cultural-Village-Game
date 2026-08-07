local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ItemsStore = ServerStorage:WaitForChild("Items")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("ItemDatabase"))

local GameDataManager = require(ServerScriptService:WaitForChild("FarmDataManager"))

local equipEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("EquipItemEvent")
local GiveItemEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("GiveItemEvent")
local SyncItemEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("SyncItemEvent")
local SideNotiEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("SideNotiEvent")

local getDataFunction = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetPlayerData")

local ConsumeItemBindable = ServerStorage:WaitForChild("BindableEvent"):WaitForChild("ConsumeItemEvent")
local GiveItemBindable = ServerStorage:WaitForChild("BindableEvent"):WaitForChild("GiveItemBindable")

-- ==========================================
-- เมื่อ Client ขอข้อมูลตอนเข้าเกม (โหลด UI กระเป๋า)
-- ==========================================
getDataFunction.OnServerInvoke = function(player)
    local pData = GameDataManager.PlayersData[player.UserId]
    while not pData do
        task.wait(0.5)
        pData = GameDataManager.PlayersData[player.UserId]
    end
    return {
        inventory = pData.player_items
    }
end

-- ==========================================
-- ระบบสวมใส่ไอเทม (Equip)
-- ==========================================
equipEvent.OnServerEvent:Connect(function(player, itemName)
    local character = player.Character
    if not character or not itemName then 
        for _, v in pairs(character:GetChildren()) do
            if v:IsA("Tool") then v:Destroy() end
        end
        return 
    end

    -- 🌟 ดึงข้อมูลกระเป๋าจาก DataManager
    local pData = GameDataManager.PlayersData[player.UserId]

    if pData and pData.player_items and pData.player_items[itemName] and pData.player_items[itemName] > 0 then
        local toolTemplate = ItemsStore:FindFirstChild(itemName)
        if toolTemplate then
            for _, v in pairs(character:GetChildren()) do
                if v:IsA("Tool") then v:Destroy() end
            end
            toolTemplate:Clone().Parent = character
        else
            warn("ไม่พบ tool Template")
        end
    else
        warn("ผู้เล่น " .. player.Name .. " พยายามสวมใส่ " .. itemName .. " แต่ไม่มีไอเทมนี้ในกระเป๋า!")
    end
end)

-- ==========================================
-- ระบบ NPC แจกไอเทม
-- ==========================================
GiveItemEvent.OnServerEvent:Connect(function(player, itemName, amount)
    local pData = GameDataManager.PlayersData[player.UserId]
    if not pData then return end

    local itemInfo = ItemDatabase[itemName]
    if not itemInfo then
        warn("ไม่พบข้อมูลของ " .. itemName .. " ใน ItemDatabase")
        return
    end

    -- 🌟 เพิ่มไอเทมเข้า player_items
    local currentAmount = pData.player_items[itemName] or 0
    pData.player_items[itemName] = currentAmount + amount

    print("NPC แจก " .. itemInfo.ItemName .. " ให้กับ " .. player.Name .. " จำนวน " .. amount .. " ชิ้น")

    SyncItemEvent:FireClient(player, itemName, amount)
    SideNotiEvent:FireClient(player, itemInfo.ItemName, amount)
end)

-- ==========================================
-- ระบบใช้งานไอเทม (Consume) เช่น กินอาหาร หรือ ปลูกเมล็ด
-- ==========================================
ConsumeItemBindable.Event:Connect(function(player, itemName, amountToConsume)
    local pData = GameDataManager.PlayersData[player.UserId]

    if pData and pData.player_items and pData.player_items[itemName] then
        local currentAmount = pData.player_items[itemName]

        if currentAmount >= amountToConsume then
            -- 1. 🌟 หักจำนวนใน DataManager
            pData.player_items[itemName] = currentAmount - amountToConsume

            -- 2. อัปเดตไปยัง UI ของผู้เล่น
            SyncItemEvent:FireClient(player, itemName, -amountToConsume)

            -- 3. ตรวจสอบว่าของหมดกระเป๋าหรือยัง
            if pData.player_items[itemName] <= 0 then
                pData.player_items[itemName] = nil -- ลบออกจากฐานข้อมูล

                local character = player.Character
                if character then
                    local tool = character:FindFirstChild(itemName)
                    if tool then tool:Destroy() end
                end
            end

            print("หักไอเทม " .. itemName .. " จำนวน " .. amountToConsume .. " จาก " .. player.Name)
        end
    end
end)

-- ==========================================
-- ระบบได้รับไอเทม (จากการฟาร์ม/เก็บเกี่ยว)
-- ==========================================
GiveItemBindable.Event:Connect(function(player, itemName, amount)
    local pData = GameDataManager.PlayersData[player.UserId]
    if not pData then return end

    local itemInfo = ItemDatabase[itemName]
    if not itemInfo then
        warn("ไม่พบข้อมูลของ " .. itemName .. " ใน ItemDatabase")
        return
    end

    -- 🌟 เพิ่มไอเทมเข้า player_items
    local currentAmount = pData.player_items[itemName] or 0
    pData.player_items[itemName] = currentAmount + amount

    print("ระบบฟาร์มให้ " .. itemInfo.ItemName .. " กับ " .. player.Name .. " จำนวน " .. amount .. " ชิ้น")

    SyncItemEvent:FireClient(player, itemName, amount)
    SideNotiEvent:FireClient(player, itemInfo.ItemName, amount)
end)