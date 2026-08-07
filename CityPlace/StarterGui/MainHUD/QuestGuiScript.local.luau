local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestList = script.Parent.QuestFrame.QuestList
local Template = QuestList:WaitForChild("Template")
local QuestFrame = script.Parent.QuestFrame
local CloseButton  = QuestFrame.ToggleBtn

local QuestData = require(ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("QuestData"))

local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")

local function RefreshUI(questData)

    -- 🌟 1. เปลี่ยนเป็นตัวพิมพ์เล็ก ให้ตรงกับ DataManager
    if type(questData) ~= "table" then 
        questData = { active = {}, completed = {} }
    end

    -- 🌟 2. ดึงจากคีย์ตัวพิมพ์เล็ก
    local myActiveQuests = questData.active or {}
    local activeIds = {}
    local count = 0

    -- 1. อัปเดตข้อมูลเควสที่ยังมีอยู่
    for questId, data in pairs(myActiveQuests) do
        count += 1
        activeIds[questId] = true 

        local staticInfo = QuestData[questId]
        if staticInfo then
            local existingUI = QuestList:FindFirstChild(questId)
            local targetUI

            if not existingUI then
                targetUI = Template:Clone()
                targetUI.Name = questId
                targetUI.Visible = true
                targetUI.Parent = QuestList
            else
                targetUI = existingUI
            end

            targetUI.QuestDescription.Text = staticInfo.Name

            if data.IsCompleted then
                targetUI.QuestDescription.Text = staticInfo.ReadyToSubmitMessage or staticInfo.Description
                targetUI.QuestProgress.Text = "OK!"
                targetUI.QuestProgress.TextColor3 = Color3.fromRGB(85, 255, 127)
            else
                local progressValue = data.currentProgress or 0 
                local targetValue = staticInfo.TargetAmount or 0
                targetUI.QuestProgress.Text = progressValue .. "/" .. targetValue
                targetUI.QuestProgress.TextColor3 = Color3.fromRGB(255, 255, 255) 
            end
        end
    end

    -- 2. ลบ UI ของเควสที่ทำเสร็จแล้ว (ไม่มีในระบบแล้ว)
    for _, child in pairs(QuestList:GetChildren()) do
        if child:IsA("ImageButton") and child ~= Template then
            if not activeIds[child.Name] then
                child:Destroy()
            end
        end
    end

end

-- ดึงข้อมูลครั้งแรกเมื่อเปิดเกม
task.spawn(function()
    local success, initialQuests = pcall(function() return GetQuestDataRF:InvokeServer() end)
    if success and initialQuests then
        RefreshUI(initialQuests)
    end
end)

-- รอรับสัญญาณรีเฟรชจาก Server
QuestEvent.OnClientEvent:Connect(function(signal)
    local success, latestQuests = pcall(function() 
        return GetQuestDataRF:InvokeServer() 
    end)

    if success and latestQuests then
        RefreshUI(latestQuests)
    end

end)

CloseButton.Activated:Connect(function()
    QuestFrame.Visible = false
end)