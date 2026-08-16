local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Module = ReplicatedStorage:WaitForChild("Module")
local DialogModule = require(Module:WaitForChild("DialogModule"))

local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")
local GiveItemEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("GiveItemEvent")
local SeedShopBindable = ReplicatedStorage:WaitForChild("BindableEvent"):WaitForChild("SeedShop") :: BindableEvent

local player = game.Players.LocalPlayer
local npc = script.Parent
local prompt = npc:WaitForChild("ProximityPrompt")

local dialogObject = DialogModule.new("ป้าสมพร", npc, prompt)

-- ==========================================
-- NPC Setting
-- ==========================================
local NPC_CONFIG = {
    DefaultCompletedDialogId = 40, -- บทสนทนาเมนูทางเลือก (คุย/ร้านค้า)
    Quests = {
        {
           QuestID = "QT003",
           EnableAutoTrigger = false,
           SkipMenu = true,
           AcceptDialogId = 0,
           InProgressDialogId = 1,
           SubmitDialogId = 0
        },
        {
            QuestID = "Q001",
            EnableAutoTrigger = false, -- เดินเข้าไปใกล้แล้วคุยอัตโนมัติไหม?
            SkipMenu = false,          -- ถ้าเดินมากด E เอง จะให้เข้าเควสเลย(true) หรือแวะหน้าเมนูก่อน(false)?
            AcceptDialogId = 1,
            InProgressDialogId = 10,
            SubmitDialogId = 30
        },
        
    }
}

local dialogTree = {
    -- [บทสนทนาเควสละไว้เหมือนเดิม เพื่อความกระชับ]
    [1] = { 
        text = "....",
        responses = {
            {text="สวัสดีครับ/ค่ะคุณป้า", next=2}
        }
    },
    [2] = {
        text = "หนูไม่ใช่คนแถวนี้นี่ มีอะไรให้ป้าช่วยหรือเปล่าจ๊ะ",
        responses = {
            {text="ผม/หนูเพิ่งมาอยู่ใหม่ จะย้ายมาทำไร่ที่นี่ครับ/ค่ะคุณป้า", next=3}
        }
    },
    [3] = { 
        text = "ว้าว! ยินดีต้อนรับนะหนู",
        action="submitQuest",
        questId="QT003",
        delay=1.5,
        next=4
    },
    [4] = {
        text = "น่าดีใจนะ ที่มีคนรุ่นใหม่สนใจการทำเกษตรกรรม",
        next = 5,
        delay = 1.5
    },
    [5] = { 
        text = "ที่นี่เราทำเกษตรอินทรีย์เป็นหลัก", 
        next = 6 
    },
    [6] = { 
        text = "เพราะเราอยากมีไร่ที่มีดินดีๆ แหล่งน้ำสะอาดๆไว้ทำไร่นานๆน่ะ", 
        next = 7,
        delay = 1.5
    },
    [7] = { 
        text = "หนูเคยทำนามาก่อนไหมจ๊ะ", 
        responses = { 
            {text="ไม่เคยครับ/ค่ะคุณป้า", next=8} 
        }
    },
    [8] = {
        text = "ที่นี่มีแปลงสาธิตอยู่ หนูอยากลองดำนาดูมั้ยล่ะ?",
        responses = {
            {text="อยากครับ/ค่ะคุณป้า", next=9, action="acceptQuest", questId="Q003"}
        }
    },
    [9] = {
        text = "ดีเลย! นี่ รับต้นกล้าไปสิ",
        action = "giveItem",
        itemName = "RiceSprout(quest)",
        amount = 1,
        delay = 1.5,
        next = 10
    },
    [10] = {
        text = "เอาต้นกล้าไปดำนาแล้วกลับมาหาป้านะ",
        delay=1.6
    },

    [30] = { 
        text = "เป็นไงบ้าง เรียบร้อยแล้วใช่ไหม",
        responses = {
            { text = "ใช่ครับ/ค่ะ", action = "submitQuest", questId = "Q001", next = 31 }
        }
    },
    [31] = { 
        text = "เก่งมาก!",
         next = 32
        },
    [32] = { 
        text = "หลังจากดำนาแล้ว เราก็จะคอยดูแลต้นข้าว",
        next = 33
    },
    [33] = { 
        text = "เมื่อข้าวเป็นสีเหลืองทอง ก็จะถึงเวลาเก็บเกี่ยว",
        next = 34
    },
    [34] = { 
        text = "เอาล่ะ.. รับเคียวของป้าไปสิ",
        next = 35
    },
    [35] = {
        text = "เอาไว้ใช้เก็บเกี่ยวผลผลิตของหนูนะ",
        responses = { 
            { text = "ขอบคุณครับ/ค่ะ", action = "giveItem", itemName = "Sickle", amount = 1, next = 36 }
        }
    },
    [36] = { 
        text ="แล้วก็เกือบลืมแหนะ...",
        delay=1.5
     },
    [37] = {
        text ="ถ้าอยากได้ต้นกล้าหรือเมล็ดพันธุ์ มาหาป้าได้เลยนะ",
        delay=1.5
    },


    [40] = {
        text ="วันนี้ให้ช่วยอะไรดีล่ะเจ้าหนู",
        responses = {
            {text="พูดคุย", action="talkToNPC"},
            {text="ซื้อต้นกล้า/เมล็ดพันธุ์", action="openSeedShop"},
            {text="เอาไว้ก่อน", action="cancleDialog"},
        }
    },

    [50] = {
        text ="ตอนนี้ป้ากำลังยุ่งนิดหน่อย ไว้มาคุยกันใหม่นะจ๊ะ แวะซื้อของได้ตลอดเลยนะ",
        delay = 2
    }
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
        local isCompleted = false
        if questData.completed[qId] then
            isCompleted = true
        elseif table.find(questData.completed, qId) then
            isCompleted = true
        end

        if not isCompleted then
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
    local success, questData = pcall(function() return GetQuestDataRF:InvokeServer() end)
    if not success then return end
    questData = questData or { active = {}, completed = {} }

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

        -- จัดการ Auto Trigger (ถ้าตั้งค่าไว้ และอยู่ในช่วงรับเควส)
        -- *ปรับแต่งได้: ถ้าอยากให้ AutoTrigger ตอนส่งเควสด้วย ให้เอาเงื่อนไข state == "accept" ออก
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

-- ==========================================
-- Player Interacts (กด E)
-- ==========================================
prompt.Triggered:Connect(function(player)
    StopAutoTrigger() 
    dialogObject:ToggleQuestNoti(false) 

    local success, questData = pcall(function() return GetQuestDataRF:InvokeServer() end)
    if not success then return end
    questData = questData or { active = {}, completed = {} }

    -- Special handling
    -- if questData.active["Q001"] and questData.active["Q001"].TargetsStatus and questData.active["Q001"].TargetsStatus["AuntySomporn"] == false then
    --     QuestEvent:FireServer("Q001", 1, "update", "AuntySomporn")
    -- end
    -- if questData.active["Q002"] then
    --     QuestEvent:FireServer("Q002", 1, "submit")
    -- end

    local targetDialogId, questConfig, state = GetQuestTargetDialog(questData)

    if questConfig then
        if questConfig.SkipMenu then
            -- ถ้าตั้งค่าให้ข้ามเมนู (เหมาะกับเควสสำคัญ) ให้คุยเควสเลย
            dialogObject:triggerDialog(player, targetDialogId)
            if state == "submit" then
                QuestEvent:FireServer(questConfig.QuestID, 0, "submit")
            end
        else
            -- ถ้าไม่ให้ข้ามเมนู ให้โยนไปหน้าเลือก คุย/ซื้อของ ก่อน
            dialogObject:triggerDialog(player, NPC_CONFIG.DefaultCompletedDialogId)
        end
    else
        -- ถ้าไม่มีเควส ก็ไปหน้าเลือก คุย/ซื้อของ
        dialogObject:triggerDialog(player, NPC_CONFIG.DefaultCompletedDialogId)
    end
end)

-- ==========================================
-- Handle Responses
-- ==========================================
dialogObject.responded:Connect(function(choiceIndex, currentDialogId, responseData)

    if responseData.action == "cancleDialog" then
        dialogObject:hideGui()
        task.spawn(UpdateQuestState)
        return
    end

    -- จัดการเมื่อผู้เล่นเลือกช้อยส์ "คุยกับป้าสมพร" จากหน้าเมนู
    if responseData.action == "talkToNPC" then
        task.wait(0.3)
        local success, questData = pcall(function() return GetQuestDataRF:InvokeServer() end)
        if success then
            questData = questData or { active = {}, completed = {} }
            print("--- Data จาก Server ---")
            print("Completed:", HttpService:JSONEncode(questData.completed))
            print("Active:",HttpService:JSONEncode(questData.active))

            local targetDialogId, questConfig, state = GetQuestTargetDialog(questData)

            if questConfig then
                dialogObject:triggerDialog(player, targetDialogId)
                if state == "submit" then
                    QuestEvent:FireServer(questConfig.QuestID, 0, "submit")
                end
            else
                dialogObject:triggerDialog(player, 50) -- ไม่มีเควสให้ทำแล้ว
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
    elseif responseData.action == "openSeedShop" then
        SeedShopBindable:Fire()
        dialogObject:hideGui()
        task.spawn(UpdateQuestState) -- ให้ไอคอนกลับมาแสดงถ้ามีเควส
    elseif responseData.action == "" or responseData.action == nil or not responseData.action then
        warn("[NPC_DIALOG_SCRIPT] invalid action")
    end
end)

dialogObject.nodeAction:Connect(function(dialogId, dialogData)
    if dialogData.action == "acceptQuest" then
        QuestEvent:FireServer(dialogData.questId, 0, "accept")
     elseif dialogData.action == "submitQuest" then
        QuestEvent:FireServer(dialogData.questId, 0, "submit")
    elseif dialogData.action == "giveItem" then
        GiveItemEvent:FireServer(dialogData.itemName, dialogData.amount)
    elseif dialogData.action == "" or dialogData.action == nil or not dialogData.action then
        warn("[NPC_DIALOG_SCRIPT] invalid action")
    end
end)

task.spawn(UpdateQuestState)