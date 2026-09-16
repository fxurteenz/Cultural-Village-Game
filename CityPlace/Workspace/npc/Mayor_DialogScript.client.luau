local HttpService = game:GetService("HttpService")
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
local highlightFx = npc:WaitForChild("Highlight")
local dialogObject = DialogModule.new("ผู้ใหญ่บ้าน", npc, prompt)

-- ==========================================
-- NPC Setting
-- ==========================================
local NPC_CONFIG = {
	FallbackDialogId = 30,
	Quests = {
		{
			QuestID = "QT001",
			EnableAutoTrigger = true,
			AcceptDialogId = 1,
			InProgressDialogId = 30,
			SubmitDialogId = 20,
            SkipMenu = true
		},
		{
			QuestID = "QT002",
			EnableAutoTrigger = false,
			AcceptDialogId = 0, 
			InProgressDialogId = 11,
			SubmitDialogId = 20,
            SkipMenu = true
		},
		{
			QuestID = "QT003",
			EnableAutoTrigger = false,
			AcceptDialogId = 0,
			InProgressDialogId = 111,
			SubmitDialogId = 20,
            SkipMenu = true
		},
        {
			QuestID = "Q003_1",
			EnableAutoTrigger = false,
			AcceptDialogId = 0,
			InProgressDialogId = 40,
			SubmitDialogId = 0,
            SkipMenu = true
		},
	}
}

local dialogTree = {
	-- ... (ส่วน dialogTree ของคุณเขียนมาดีแล้ว คงไว้ตามเดิมได้เลย) ...
	[1] = { text = "อ้าว! สวัสดี",next = 2 },
	[2] = {
		text = string.format("หนู %s ใช่มั้ย?", player.Name), 
		responses={
			{ text="สวัสดีครับ/ค่ะ, ใช่ครับ/ค่ะ", next=3 }
		}
	},
	[3] = {text = "มีคนบอกผู้ใหญ่ไว้ว่าหนูจะย้ายมาอยู่ที่นี่น่ะ", next=4, delay=1.5},
	[4] = { text = "ยินดีต้อนรับสู่หมู่บ้านของเรานะ!", next = 5},
	[5] = { text = "เอาล่ะๆ เดินทางมาน่าจะเหนื่อยใช่ไหม", next=6 },
	[6] = { text = "วันนี้หนูกลับไปพักผ่อนก่อนก็แล้วกัน",next=7 ,action="acceptQuest", questId="QT001"},
	[7] = { text = "แล้วเดี๋ยววันพรุ่งนี้ ผู้ใหญ่จะแนะนำสถานที่ต่างๆในหมู่บ้านให้รู้จัก", next=8, delay=2 },
	[8] = { text = "เอ้า! เอาตะเกียงนี่ไปด้วย แถวนั้นมันมืดน่ะ", action="giveItem", itemName="Lantern", amount=1, next=9, delay=1.5},
	[9] = { text = "บ้านของหนูจะอยู่ถนนเส้นนี้แหละ", next = 10 },
	[10] = { text = "เดินเลยวัดไปหน่อยนึงก็ถึงแล้ว พักผ่อนให้เต็มที่นะ !",
		responses={
			{ text="ขอบคุณครับ/ค่ะ", action="teleportPlayer", target="Farm"}
		},
	},

	[11] = { 
		text = string.format("สวัสดี %s", player.Name),
		responses={
			{ text="สวัสดีครับ/ค่ะผู้ใหญ่บ้าน", action="submitQuest", questId="QT002", next=12 }
		},
	},
	[12] = {text="ตื่นเช้าแบบนี้รู้สึกสดชื่นมากเลย",next=13},
	[13] = {text="เหมาะกับการลงท้องไร่ท้องนา.. ว่ามั้ย?", next=14},
	[14] = {
		text="ดีเลย! ถ้างั้นวันนี้ไปลองเจอป้าสมพรดูนะ", 
		responses={
			{ text="ป้าสมพรคือใคร?", action="acceptQuest", questId="QT003", next=15 }
		},
	},
	[15] = {text="ป้าสมพรเป็นคนให้ความรู้เรื่องการปลูกข้าว", next=16},
	[16] = {text="ลองไปดูที่ “แปลงปลูกข้าวอินทรีย์” ดูแล้วกันนะ"},

	[30] = { text = "สวัสดี วันนี้อากาศดีว่ามั้ย !" },
    
    [40] = {text="เป็นยังไงบ้างเจ้าหนู ไม่ยากเลยใช่ไหมล่ะ",delay=1.5, next =41, action="submitQuest", questId="Q003_1"},
    [41] = {text="ต่อไปผมีสถานที่นึงที่ผู้ใหญ่คิดว่าหนูต้องไป", next =42},
    [42] = {text="นั่นก็คือ.. ศูนย์ฝึกวิชาชีพ", next =43},
    [43] = {text="พี่มะลิจะดูแลที่นั่นอยู่ เข้าไปหาพี่มะลิได้เลยนะ", action="acceptQuest", questId="Q003_2"},

	[111] = { text = "ยังไม่ไปหาป้าสมพรที่แปลงข้าวอินทรีย์หรอ..", next=112 },
	[112] = { text = "รีบไปก่อนที่จะสายแล้วอากาศร้อนดีกว่านะ!"}
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
		--print("🔍 Checking:", qId)
		--print("   completed?", questData.completed[qId])
		--print("   active?", questData.active[qId])

        local isCompleted = questData.completed[qId] == true
            or table.find(questData.completed, qId) ~= nil

        if isCompleted then
            continue  
        end

        local activeData = questData.active[qId]
        if activeData then
            print("   IsCompleted?", activeData.IsCompleted)
            print("   type:", type(activeData.IsCompleted))
        end
        if not activeData then
            -- ยังไม่ได้รับเควสนี้เลย
            if questConfig.AcceptDialogId == 0 then
                continue  -- รับจากที่อื่น ข้ามไป
            end
            return questConfig.AcceptDialogId, questConfig, "accept"

		elseif not activeData.IsCompleted then
			if questConfig.InProgressDialogId == 0 then continue end
            -- กำลัง inprogress อยู่
            return questConfig.InProgressDialogId, questConfig, "in_progress"

		else
			if questConfig.SubmitDialogId == 0 then continue end
            -- ทำครบแล้ว รอ submit
            return questConfig.SubmitDialogId, questConfig, "submit"
        end
    end

    -- ไม่มีเควสที่ต้องจัดการ → fallback
    return NPC_CONFIG.FallbackDialogId, nil, "none"
end

-- ==========================================
-- Auto-Trigger Function
-- ==========================================
local AUTO_TRIGGER_DISTANCE = 16 
local autoTriggerConnection = nil -- เปลี่ยนชื่อตัวแปรให้ตรงกับการใช้งานจริง (Thread)
local isDialogOnCooldown = false

local function StopAutoTrigger()
	if autoTriggerConnection then
		autoTriggerConnection:Disconnect()
		autoTriggerConnection = nil
	end
end

local function StartAutoTrigger(dialogId)
	StopAutoTrigger()
	
	local timeSinceLastCheck = 0
	autoTriggerConnection = RunService.Heartbeat:Connect(function(dt)
		timeSinceLastCheck += dt
		if timeSinceLastCheck < 0.5 then return end
		timeSinceLastCheck = 0
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
	end)
end


-- ==========================================
-- Quest State icon & Quest autotrigger initial
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
-- Trigger สนทนา
-- ==========================================
prompt.Triggered:Connect(function(player)
	StopAutoTrigger() 
	dialogObject:ToggleQuestNoti(false) 

	local success, questData = pcall(function() return GetQuestDataRF:InvokeServer() end)
	if not success then return end
	questData = questData or { active = {}, completed = {} }

	local isHandled = false

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
            dialogObject:triggerDialog(player, NPC_CONFIG.FallbackDialogId)
        end
    else
        -- ถ้าไม่มีเควส ก็ไปหน้าเลือก คุย/ซื้อของ
        dialogObject:triggerDialog(player, NPC_CONFIG.FallbackDialogId)
    end
end)

-- ==========================================
-- Handle Response & บทสนทนาจบลง
-- ==========================================
dialogObject.responded:Connect(function(choiceIndex, currentDialogId, responseData)
	if responseData.action == "cancleDialog" then
		dialogObject:hideGui()
		task.spawn(UpdateQuestState)
		return
	end

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

	local nextId = responseData.next
	if nextId then
		task.wait(0.3)
		dialogObject:triggerDialog(player, nextId)
	else
		task.wait(0.5)
		dialogObject:hideGui()
	end

	isDialogOnCooldown = true          -- ← ขึ้นมาก่อน
	task.spawn(function()
		task.wait(2)                   -- ← รอก่อน แล้วค่อย UpdateQuestState
		UpdateQuestState()
		isDialogOnCooldown = false
	end)
end)

-- ==========================================
-- Handle Node Action
-- ==========================================
dialogObject.nodeAction:Connect(function(dialogId, dialogData)
    if dialogData.action == "acceptQuest" then
        QuestEvent:FireServer(dialogData.questId, 0, "accept")
     elseif dialogData.action == "submitQuest" then
        QuestEvent:FireServer(dialogData.questId, 0, "submit")
    elseif dialogData.action == "giveItem" then
        GiveItemEvent:FireServer(dialogData.itemName, dialogData.amount)
    elseif dialogData.action == "" or dialogData.action == nil or not dialogData.action then
        --warn("[NPC_DIALOG_SCRIPT] invalid action")
    end
end)

dialogObject.dialogClosed:Connect(function()
	task.spawn(UpdateQuestState)
end)

task.spawn(UpdateQuestState)