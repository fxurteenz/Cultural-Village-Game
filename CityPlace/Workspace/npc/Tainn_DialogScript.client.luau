local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Module = ReplicatedStorage:WaitForChild("Module")
local DialogModule = require(Module:WaitForChild("DialogModule"))
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")

local player = game.Players.LocalPlayer
local npc = script.Parent
local prompt = npc:WaitForChild("ProximityPrompt")
local highlightFx = npc:WaitForChild("Highlight")

local dialogObject = DialogModule.new("ตาอิน", npc, prompt)

-- ==========================================
-- NPC Setting
-- ==========================================
local NPC_CONFIG = {
	DefaultCompletedDialogId = 1,
	Quests = {
		{
			QuestID = "QC002",
			RequireEventId = "E001",    -- เงื่อนไข: ต้องอยู่ใน Event E001 เท่านั้น
			EnableAutoTrigger = true,   -- เปิดใช้งาน Auto-Trigger (เหมือนป้าสมพร)
			SkipMenu = true,
			AcceptDialogId = 100,
			InProgressDialogId = 105,
			SubmitDialogId = 110
		},
	}
}

local dialogTree = {
	[1] = { text = "สวัสดีเจ้าหนูน้อย...", next = 2 },
	[2] = { text = "ข้าชื่อว่าอิน", next = 3 },
	[3] = { text = "แล้วเอ็งชื่ออะไร?", next = 4 },
	[4] = { text = "หนูชื่อว่า " .. player.DisplayName, next = 5 }, -- เพิ่มเว้นวรรค
	[5] = { text = "แล้วเจ้าพึ่งย้ายมาอยู่ที่นี้ใช่ไหม?", next = 6 }, 
	[6] = { text = "ใช่ครับ/ใช่ค่ะ", next = 7 },
	[7] = { text = "ว่างๆ ก็แวะมาคุยกับตาได้นะ" },

	-- บทสนทนาเควส
	[100] = {
		text = "ดูนกกระเรียนตัวนั้นสิเจ้าหนู", next=101
	},
    [101] = {
		text = "พวกอีกากำลังพยายามจะกินไข่ของมัน", next=102
	},
    [102] = {
		text = "เอ้าเอา หนังสติ๊กไป ", 
        action="giveItem", 
		itemName ="SlingShot",
		amount = 1,
        next=103
	},
	[103] = {
		text = "ไปไล่มันเร็วเข้าเจ้าหนู", 
		action="acceptQuest", 
		questId ="QC002",
	},

	[105] = { text = "ไล่นกกระเรียนไปถึงไหนแล้วล่ะหลาน?" },
	
	[110] = {
		text = "ขอบใจมากนะที่ช่วยตาไล่นกกระเรียน!",
		action = "submitQuest",
		questId = "QC001"
	}
}

for id, data in pairs(dialogTree) do
	dialogObject:addDialog(id, data)
end

-- ==========================================
-- Helper Function
-- ==========================================
local function checkEventCondition(questConfig)
	if questConfig.RequireEventId then
		local currentEvent = npc:GetAttribute("ActiveSpecialEvent")
		if currentEvent ~= questConfig.RequireEventId then
			return false
		end
	end
	return true
end

local function GetQuestTargetDialog(questData)
	for _, questConfig in ipairs(NPC_CONFIG.Quests) do
		if not checkEventCondition(questConfig) then continue end

		local qId = questConfig.QuestID
		local isCompleted = false

		if questData.completed[qId] or (type(questData.completed) == "table" and table.find(questData.completed, qId)) then
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
-- Auto-Trigger Function (แก้ไขให้ปลอดภัยและเบาเครื่องขึ้น)
-- ==========================================
local AUTO_TRIGGER_DISTANCE = 12 
local autoTriggerThread = nil
local isDialogOnCooldown = false

local function StopAutoTrigger()
	if autoTriggerThread then
		task.cancel(autoTriggerThread) -- ยกเลิก thread เดิม
		autoTriggerThread = nil
	end
end

local function StartAutoTrigger(dialogId)
	StopAutoTrigger()

	autoTriggerThread = task.spawn(function()
		while true do
			task.wait(0.5) -- เช็คทุกๆ 0.5 วินาที (เปลี่ยนจาก Heartbeat)

			if isDialogOnCooldown then continue end

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
		end
	end)
end

-- ==========================================
-- Update Quest State
-- ==========================================
local function UpdateQuestState()
	local success, questData = pcall(function() return GetQuestDataRF:InvokeServer() end)
	if not success then return end
	questData = questData or { active = {}, completed = {} }

	local targetDialogId, questConfig, state = GetQuestTargetDialog(questData)

	if questConfig then
		if state == "accept" then
			dialogObject:ToggleQuestNoti(true, "main")
			highlightFx.Enabled = true
		elseif state == "in_progress" then
			dialogObject:ToggleQuestNoti(false)
			highlightFx.Enabled = false
		elseif state == "submit" then
			dialogObject:ToggleQuestNoti(true, "submit")
			highlightFx.Enabled = false
		end

		if questConfig.EnableAutoTrigger then
			StartAutoTrigger(targetDialogId)
		else
			StopAutoTrigger()
		end
	else
		dialogObject:ToggleQuestNoti(false)
		StopAutoTrigger()
	end
end

-- ==========================================
-- จับสัญญาณเมื่อเริ่มอีเวนต์
-- ==========================================
npc:GetAttributeChangedSignal("ActiveSpecialEvent"):Connect(function()
	print("[TaInn Npc] : ActiveSpecialEvent active auto trigger")
	task.wait(0.5)
	UpdateQuestState()
end)

-- ==========================================
-- Player Interacts (กด E)
-- ==========================================
prompt.Triggered:Connect(function(playerWhoclicked)
	StopAutoTrigger() 
	dialogObject:ToggleQuestNoti(false) 

	local success, questData = pcall(function() return GetQuestDataRF:InvokeServer() end)
	if not success then return end
	questData = questData or { active = {}, completed = {} }

	local targetDialogId, questConfig, state = GetQuestTargetDialog(questData)

	if questConfig then
		dialogObject:triggerDialog(playerWhoclicked, targetDialogId)
	else
		dialogObject:triggerDialog(playerWhoclicked, NPC_CONFIG.DefaultCompletedDialogId)
	end
end)

-- ==========================================
-- Handle Responses
-- ==========================================
dialogObject.responded:Connect(function(choiceIndex, currentDialogId, responseData)
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
	-- elseif responseData.action == "giveItem" then
	-- 	GiveItemEvent:FireServer(responseData.itemName, responseData.amount)
	-- else
		
	end
end)

dialogObject.nodeAction:Connect(function(dialogId, dialogData)
	if dialogData.action == "acceptQuest" then
		QuestEvent:FireServer(dialogData.questId, 0, "accept")
	elseif dialogData.action == "submitQuest" then
		QuestEvent:FireServer(dialogData.questId, 0, "submit")
	end
end)

task.spawn(UpdateQuestState)