local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("TeleportEvent")
local RunService = game:GetService("RunService")

local Module = ReplicatedStorage:WaitForChild("Module")
local DialogModule = require(Module:WaitForChild("DialogModule"))
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")
local GiveItemEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("GiveItemEvent")

local player = game.Players.LocalPlayer
local npc = script.Parent
local prompt = npc:WaitForChild("ProximityPrompt")

local dialogObject = DialogModule.new("ผู้ใหญ่บ้าน", npc, prompt)

-- ==========================================
-- NPC Setting
-- ==========================================
local NPC_CONFIG = {
    DefaultCompletedDialogId = 30, -- บทสนทนาหลักเมื่อกด E (ถ้าเปลี่ยนเป็นเมนูทางเลือก ให้แก้ตรงนี้)
    FallbackDialogId = 30,         -- บทสนทนาเมื่อผู้เล่นกด "คุย" แต่ไม่มีเควส (ใช้ 30 เหมือนกันไปก่อนจนกว่าจะมีเมนู)
    Quests = {
        {
            QuestID = "QT001",
            EnableAutoTrigger = true,
            SkipMenu = true,
            AcceptDialogId = 1,
            InProgressDialogId = 30,
            SubmitDialogId = 20
        },
        {
            QuestID = "QT002",
            EnableAutoTrigger = false,
            SkipMenu = true,
            AcceptDialogId = 0,   
            InProgressDialogId = 11,
            SubmitDialogId = 20
        },
        {
           QuestID = "QT003",
           EnableAutoTrigger = false,
           SkipMenu = true,
           AcceptDialogId = 0,
           InProgressDialogId = 111,
           SubmitDialogId = 20
        },
    }
}

local dialogTree = {
    [1] = { text = "อ้าว! สวัสดี",next = 2 },
    [2] = {
        text = string.format("หนู %s ใช่มั้ย?", player.Name), 
        responses={
            { text="สวัสดีครับ/ค่ะ, ใช่ครับ/ค่ะ", next=3 }
        }
    },
    [3] = {
        text = "มีคนบอกผู้ใหญ่ไว้ว่าหนูจะย้ายมาอยู่ที่นี่น่ะ",
        next=4,
        delay=1.5
    },
    [4] = {
        text = "ยินดีต้อนรับสู่หมู่บ้านของเรานะ!",
        next = 5
    },
    [5] = { 
        text = "เอาล่ะๆ เดินทางมาน่าจะเหนื่อยใช่ไหม", 
        next=6
    },
    [6] = { 
        text = "วันนี้หนูกลับไปพักผ่อนก่อนก็แล้วกัน", 
        next=7 ,
        action="acceptQuest",
        questId="QT001"
    },
    [7] = { 
        text = "แล้วเดี๋ยววันพรุ่งนี้ ผ้ใหญ่จะแนะนำสถานที่ต่างๆในหมู่บ้านให้รู้จัก", 
        next=8, 
        delay=2 
    },
    [8] = { 
        text = "เอ้า! เอาตะเกียงนี่ไปด้วย แถวนั้นมันมืดน่ะ", 
        action="giveItem", 
        itemName="Lantern", 
        amount=1, 
        next=9, 
        delay=1.5
    },
    [9] = {
        text = "บ้านของหนูจะอยู่ถนนเส้นนี้แหละ",
        next = 10
    },
    [10] = {
        text = "เดินเลยวัดไปหน่อยนึงก็ถึงแล้ว พักผ่อนให้เต็มที่นะ !",
        responses={
            { text="ขอบคุณครับ/ค่ะ", action="teleportPlayer", target="Farm"}
        },
    },

    [11] = { 
        text = string.format("สวัสดี ".. player.Name),
        responses={
            { text="สวัสดีครับ/ค่ะผู้ใหญ่บ้าน =)", action="submitQuest", questId="QT002", next=12 }
        },
    },
    [12] = {text="ตื่นเช้าแบบนี้รู้สึกสดชื่นมากเลย",next=13},
    [13] = {text="เหมาะกับการลงท้องไร่ท้องนานะ", next=14, delay=1.5},
    [14] = {
        text="ดีเลย! ถ้างั้นวันนี้ไปลองเจอป้าสมพรดูนะ", 
        responses={
            { text="จะเจอป้าสมพรได้ที่ไหน?", action="acceptQuest", questId="QT003", next=15 }
        },
        delay=1.5
    },
    [15] = {text="ป้าสมพรเป็นคนให้ความรู้เรื่องข้าวน่ะ", next=16, delay=1.5},
    [16] = {text="ลองไปดูที่ “แปลงปลูกข้าวอินทรีย์” ดูก็แล้วกันนะ", next=17, delay=1.5},
    [17] = {
        text="ไหนๆก็จะมาทำไร่ที่นี่ใช่มั้ย งั้นก็ควรทำความรู้จักกับป้าสมพรไว้นะ",
        responses={
                   { text="ได้เลยครับ/ค่ะ" }
        },
    },

    [20] = {
        text = "ไปสำรวจหมู่บ้านจนทั่วแล้วใช่ไหม",
        responses = {
            { text = "ใช่ครับ/ค่ะ", next = 21 }
        }
    },
    [21] = { text = "เก่งมากเลย !", next = 22 },
    [22] = { text = "ทีนี้หนูก็น่าจะพร้อมสำหรับหมู่บ้านสวายสอแล้ว", next = 23 },
    [23] = { text = "ขอให้สนุกกับวิถีชีวิตในหมู่บ้านของเรานะ !" },

    [30] = { text = "สวัสดี วันนี้อากาศดีว่ามั้ย !" },

    [111] = { text = "ยังไม่ไปหาป้าสมพรที่แปลงข้าวอินทรีย์หรอ..", next=112 },
    [112] = { text = "รีบไปก่อนที่จะสายแล้วอากาศร้อนดีกว่านะ!", delay=1.5}
}

for id, data in pairs(dialogTree) do
    dialogObject:addDialog(id, data)
end

-- ==========================================
-- Helper Function: หา Dialog เป้าหมาย
-- ==========================================
local function GetQuestTargetDialog(questData)
    for _, questConfig in ipairs(NPC_CONFIG.Quests) do
        local qId = questConfig.QuestID

        if not questData.completed[qId] then
            if not questData.active[qId] then
                if questConfig.AcceptDialogId ~= 0 then return questConfig.AcceptDialogId, questConfig, "accept" end
            elseif not questData.active[qId].IsCompleted then
                return questConfig.InProgressDialogId, questConfig, "in_progress"
            else
                return questConfig.SubmitDialogId, questConfig, "submit"
            end
        end

    end

    return NPC_CONFIG.DefaultCompletedDialogId, nil, "none"
end

-- ==========================================
-- Auto-Trigger Function
-- ==========================================
local AUTO_TRIGGER_DISTANCE = 12 
local autoTriggerConnection = nil
local isDialogOnCooldown = false

local function StopAutoTrigger()
    if autoTriggerConnection then
        autoTriggerConnection:Disconnect()
        autoTriggerConnection = nil
    end
end

local function StartAutoTrigger(dialogId)
    StopAutoTrigger() 

    autoTriggerConnection = RunService.Heartbeat:Connect(function()
        if isDialogOnCooldown then return end
    
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart

        if rootPart and npcRoot then
            local distance = (rootPart.Position - npcRoot.Position).Magnitude

            if distance <= AUTO_TRIGGER_DISTANCE and not dialogObject.active then
                StopAutoTrigger() 
                dialogObject:triggerDialog(player, dialogId) 
            end
        end
        
        task.wait(1)
    end)
end

-- ==========================================
-- Update Quest State & Init Auto-Trigger
-- ==========================================
local function UpdateQuestState()
    local success, questData = pcall(function()
        return GetQuestDataRF:InvokeServer()
    end)
    if not success then return end
    
    questData = questData or {}
    questData.active = questData.active or {}
    questData.completed = questData.completed or {}

    local targetDialogId, questConfig, state = GetQuestTargetDialog(questData)

    if questConfig then
        -- จัดการไอคอนบนหัว
        if state == "accept" then
            dialogObject:ToggleQuestNoti(true, "main")
        elseif state == "in_progress" then
            dialogObject:ToggleQuestNoti(false)
        elseif state == "submit" then
            dialogObject:ToggleQuestNoti(true, "submit")
        end

        -- จัดการ Auto Trigger
        if questConfig.EnableAutoTrigger and state == "accept" then
            StartAutoTrigger(targetDialogId)
        else
            StopAutoTrigger()
        end
    else
        -- ไม่มีเควส
        dialogObject:ToggleQuestNoti(false)
        StopAutoTrigger()
    end
end

task.spawn(UpdateQuestState)

-- ==========================================
-- Player Interacts (กด E)
-- ==========================================
prompt.Triggered:Connect(function(player)
    StopAutoTrigger()
    dialogObject:ToggleQuestNoti(false)

    local success, questData = pcall(function() return GetQuestDataRF:InvokeServer() end)
    if not success then return end

    questData = questData or {}
    questData.active = questData.active or {}
    questData.completed = questData.completed or {}

    local targetDialogId, questConfig, state = GetQuestTargetDialog(questData)

    if questConfig then
        if questConfig.SkipMenu then
            dialogObject:triggerDialog(player, targetDialogId)
            -- ส่งเควสทันทีถ้าอยู่ในสถานะ Submit และไม่ได้กำหนด action Submit ไว้ใน Dialog
            if state == "submit" then
                QuestEvent:FireServer(questConfig.QuestID, 0, "submit")
            end
        else
            dialogObject:triggerDialog(player, NPC_CONFIG.DefaultCompletedDialogId)
        end
    else
        dialogObject:triggerDialog(player, NPC_CONFIG.DefaultCompletedDialogId)
    end
end)

-- ==========================================
-- Handle Response & บทสนทนาจบลง
-- ==========================================
dialogObject.responded:Connect(function(choiceIndex, currentDialogId, responseData)
    
    -- รองรับกรณีอนาคตผู้ใหญ่บ้านมีหน้าเมนูเหมือนป้าสมพร
    if responseData.action == "talkToNPC" then
        task.wait(0.3)
        local success, questData = pcall(function() return GetQuestDataRF:InvokeServer() end)
        if success then
            questData = questData or { active = {}, completed = {} }
            local targetDialogId, questConfig, state = GetQuestTargetDialog(questData)
            
            if questConfig then
                dialogObject:triggerDialog(player, targetDialogId)
                if state == "submit" then
                    QuestEvent:FireServer(questConfig.QuestID, 0, "submit")
                end
            else
                dialogObject:triggerDialog(player, NPC_CONFIG.FallbackDialogId) 
            end
        end
        return 
    end

    local nextId = responseData.next

    if nextId then
        task.wait(0.3)
        dialogObject:triggerDialog(player, nextId)
    else
        task.wait(0.5)
        dialogObject:hideGui()
        task.spawn(UpdateQuestState)
    end

    isDialogOnCooldown = true
    task.spawn(function()
        task.wait(0.5)
        UpdateQuestState()
        task.wait(2)
        isDialogOnCooldown = false
    end)

    if responseData.action == "acceptQuest" then
        QuestEvent:FireServer(responseData.questId, 0, "accept")
    elseif responseData.action == "submitQuest" then
        QuestEvent:FireServer(responseData.questId, 0, "submit")
    elseif responseData.action == "giveItem" then
        GiveItemEvent:FireServer(responseData.itemName, responseData.amount)
    elseif responseData.action == "teleportPlayer" and responseData.target == "Farm" then
        StopAutoTrigger()
        TeleportEvent:FireServer(106832184588439)
    end
end)

-- ==========================================
-- Handle Node Action (แอคชั่นที่เกิดระหว่างบทสนทนา)
-- ==========================================
dialogObject.nodeAction:Connect(function(dialogId, dialogData)
    if dialogData.action == "acceptQuest" then 
        QuestEvent:FireServer(dialogData.questId, 0, "accept")
    end
    if dialogData.action == "giveItem" then
        GiveItemEvent:FireServer(dialogData.itemName, dialogData.amount)
    end
end)