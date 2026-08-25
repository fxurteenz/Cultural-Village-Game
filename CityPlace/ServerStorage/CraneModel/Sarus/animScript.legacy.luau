local model = script.Parent
local humanoid = model:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local animFolder = model:WaitForChild("anim")

local currentTrack = nil -- เก็บแอนิเมชันที่กำลังเล่นอยู่

-- ฟังก์ชันสำหรับเปลี่ยนและเล่นแอนิเมชัน
local function playAnimation(animName)
    if not animName then return end

    -- ถ้ามีแอนิเมชันเดิมเล่นอยู่ ให้หยุดก่อน
    if currentTrack and currentTrack.IsPlaying then
        currentTrack:Stop()
    end

    local animObj = animFolder:FindFirstChild(animName)
    if animObj then
        currentTrack = animator:LoadAnimation(animObj)
        currentTrack:Play()
    else
        warn("ไม่พบแอนิเมชันชื่อ: " .. tostring(animName))
    end
end

-- =======================================
-- 1. ทำงานทันทีเมื่อโมเดลเกิด (อ่านค่าเริ่มต้น)
-- =======================================
local initialAnim = model:GetAttribute("animTrack")
if not initialAnim then
    -- เผื่อกรณีลืมตั้งค่า Attribute ให้ใช้ idle เป็นค่าเริ่มต้น
    model:SetAttribute("animTrack", "idle") 
    initialAnim = "idle"
end
playAnimation(initialAnim)

-- =======================================
-- 2. ดักจับเมื่อ Attribute ถูกเปลี่ยน
-- =======================================
model:GetAttributeChangedSignal("animTrack"):Connect(function()
    local newAnim = model:GetAttribute("animTrack")
    playAnimation(newAnim)
end)

-- =======================================
-- 3. ควบคุมท่าเดิน/ยืนปกติ 
-- =======================================
humanoid.Running:Connect(function(speed)
    local currentAnim = model:GetAttribute("animTrack")

    -- อนุญาตให้เปลี่ยนท่าเดิน/ยืนได้เฉพาะตอนที่นกอยู่ในสถานะปกติ (idle หรือ walk)
    -- เพื่อไม่ให้ไปกวนแอนิเมชันพิเศษ (เช่น Pecking)
    if currentAnim == "idle" or currentAnim == "walk" then
        if speed > 0.1 then
            if currentAnim ~= "walk" then
                model:SetAttribute("animTrack", "walk")
            end
        else
            if currentAnim ~= "idle" then
                model:SetAttribute("animTrack", "idle")
            end
        end
    end
end)