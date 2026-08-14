local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local TeleportFunction = ServerStorage:WaitForChild("BindableFunction"):WaitForChild("TeleportFunction")

local TELEPORT_PART_TAG = "TeleportPart"
local DEBOUNCE_SECONDS = 15
local playerDebounces = {}

-- ฟังก์ชันที่จะทำงานเมื่อผู้เล่นสัมผัส Part
local function onPartTouched(part, hit)
    local character = hit.Parent
    if not character then
        return
    end

    local player = Players:GetPlayerFromCharacter(character)
    if not player then
        return
    end

    -- ตรวจสอบ Debounce ของผู้เล่นคนนั้นๆ
    if playerDebounces[player] then
        return
    end

    local targetPlaceId = part:GetAttribute("TargetPlaceId")
    if not targetPlaceId then
        warn("Teleport part '" .. part:GetFullName() .. "' ไม่มี Attribute 'targetPlace'")
        return
    end

    -- เริ่ม Debounce
    playerDebounces[player] = true

    print(player.Name .. " กำลังวาร์ปไปยัง PlaceID: " .. targetPlaceId)
    TeleportFunction:Invoke(player, targetPlaceId)

    -- รอสักครู่แล้วลบ Debounce ออก
    task.delay(DEBOUNCE_SECONDS, function()
        playerDebounces[player] = nil
    end)
end

-- ฟังก์ชันสำหรับเชื่อมต่อ Event ให้กับ Part ที่มี Tag
local function setupTeleportPart(part)
    part.Touched:Connect(function(hit)
        onPartTouched(part, hit)
    end)
end

-- ค้นหา Part ที่มี Tag อยู่แล้วทั้งหมดในตอนเริ่ม
for _, part in ipairs(CollectionService:GetTagged(TELEPORT_PART_TAG)) do
    setupTeleportPart(part)
end

-- รอเชื่อมต่อ Event ให้กับ Part ใหม่ๆ ที่ถูก Tag ในอนาคต
CollectionService:GetInstanceAddedSignal(TELEPORT_PART_TAG):Connect(setupTeleportPart)
