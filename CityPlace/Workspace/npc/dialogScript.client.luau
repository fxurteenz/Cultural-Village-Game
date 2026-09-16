local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Module = ReplicatedStorage:WaitForChild("Module")
local DialogModule = require(Module:WaitForChild("DialogModule"))

local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")
local GiveItemEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("GiveItemEvent")
local SeedShopBindable = ReplicatedStorage:WaitForChild("BindableEvent"):WaitForChild("SeedShop") :: BindableEvent

local player = game.Players.LocalPlayer
local npc = script.Parent
local prompt = npc:WaitForChild("ProximityPrompt")
local dialogObject = DialogModule.new("Mali", npc, prompt)

-- ==========================================
-- NPC Setting
-- ==========================================
local NPC_CONFIG = {
	FallbackDialogId = 40,
	Quests = {
		{
			QuestID = "Q003_2",
			EnableAutoTrigger = false,
			SkipMenu = true, 
			AcceptDialogId = 0,    
			InProgressDialogId = 1,
			SubmitDialogId = 0
		},
        {
			QuestID = "Q003_3",
			EnableAutoTrigger = false,
			SkipMenu = true,
			AcceptDialogId = 0,     
			InProgressDialogId = 10,
			SubmitDialogId = 0
		}
	}
}

-- ==========================================
-- Dialog Tree
-- ==========================================
local dialogTree = {
	[1]  = { text = "สวัสดีหนูน้อย!", next = 2 },
	[2]  = { text = "พี่ชื่อพี่มะลิ ดูแลศูนย์ฝึกวิชาชีพ", next = 3 },
	[3]  = { text = "พี่มีหน้าที่ให้ความรู้เรื่องการทอผ้า", next = 4 },
	[4]  = { text = "ที่นี่มีผ้าเก่าแก่ของชุมชนชื่อว่าผ้าก่วย", next = 5 },
	[5]  = { text = "เป็นผ้าทอมือ ลายริ้วขวาง มีสีทั้งหมด 5 สี", next = 6 },
	[6]  = { text = "ใช้ตัดชุดสวมในงานประเพณีต่างๆในชุมชนน่ะ", next = 7 },
	[7]  = { text = "งั้นเดี๋ยว ไปลองทอผ้าก่วยที่เครื่องทอดูนะจ้ะ",
		responses ={
			{
				text="ได้ครับ/ค่ะ",
				actions = {
					{type="submitQuest", questId = "Q003_2"},
					{type="acceptQuest", questId = "Q003_3"},
				}
			}
		}
		
	},

	-- In-Progress dialog (id=10) — แสดงตอนที่ Q003_2 กำลัง active
	[10] = { text = "ยังทอผ้าไม่เสร็จเหรอ? ไปลองที่กี่ทอได้เลยนะ!" },

	[20] = { text = "ว้าว! ฝีมือดีนะเนี่ย",next=21 },
	[21] = { text = "ทีนี้หนูก็สามารถเอาผ้าไปแปรรูปที่จักรเย็บผ้าได้",next=22 },
	[22] = { text = "ชาวบ้านที่นี่หลายๆคนมีอาชีพเสริมเป็นการทำผลิตภัณฑ์จากผ้าก่วยจ้ะ",next=23 },
	[23] = { text = "จะได้มีรายได้ช่วงที่ว่างจากการทำนาด้วย ดีใช่ไหมล่ะ",next=24 },
	[24] = { text = "เอาล่ะ พี่ว่าเดี๋ยวหนูกลับไปหาผู้ใหญ่บ้านก่อน",next=25, action="acceptQuest", questId="Q004_1" },
	[25] = { text = "ยังมีคนที่หนูต้องไปรู้จักอีกนะ",next=26 },
	[26] = { text = "แล้วเดี๋ยวค่อยกลับมาลองทำผลิตภัณฑ์จากผ้าก่วยนะ" },
	-- Fallback dialog (id=40) — แสดงตอนไม่มีเควสเกี่ยวข้อง
	[40] = { text = "สวัสดีจ้ะ! มีอะไรให้พี่ช่วยไหม?",
    responses = {
        {text="พูดคุย", action="talkToNPC"},
        {text="เอาไว้ก่อน", action="cancleDialog"},
        } 
    },
}

for id, data in pairs(dialogTree) do
	dialogObject:addDialog(id, data)
end

-- ==========================================
-- Helper: หา Dialog เป้าหมาย
-- ==========================================
local function GetQuestTargetDialog(questData)
	for _, questConfig in ipairs(NPC_CONFIG.Quests) do
		local qId = questConfig.QuestID

		local isCompleted = questData.completed[qId] == true
			or table.find(questData.completed, qId) ~= nil

		if isCompleted then continue end

		local activeData = questData.active[qId]

		if not activeData then
			if questConfig.AcceptDialogId == 0 then continue end
			return questConfig.AcceptDialogId, questConfig, "accept"
		elseif not activeData.IsCompleted then
			return questConfig.InProgressDialogId, questConfig, "in_progress"
		else
			if questConfig.SubmitDialogId == 0 then continue end  -- ✅ ส่งจากที่อื่น ข้ามไป
			return questConfig.SubmitDialogId, questConfig, "submit"
		end
	end

	return NPC_CONFIG.FallbackDialogId, nil, "none"
end

-- ==========================================
-- Auto-Trigger
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
		dialogObject:ToggleQuestNoti(false)
		StopAutoTrigger()
	end
end

-- ==========================================
-- Player Interacts (กด E)
-- ==========================================
prompt.Triggered:Connect(function(player)
	StopAutoTrigger()

	local success, questData = pcall(function() return GetQuestDataRF:InvokeServer() end)
	if not success then return end
	questData = questData or { active = {}, completed = {} }

	local targetDialogId, questConfig, state = GetQuestTargetDialog(questData)

	if questConfig and questConfig.SkipMenu then
		-- ✅ มีเควสและตั้ง SkipMenu → เล่น quest dialog ตรงๆ
		dialogObject:triggerDialog(player, targetDialogId)
	else
		-- ไม่มีเควส หรือ SkipMenu = false → เล่น fallback
		dialogObject:triggerDialog(player, NPC_CONFIG.FallbackDialogId)
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

	-- Actions (single)
	if responseData.action then
		if responseData.action == "acceptQuest" then
			QuestEvent:FireServer(responseData.questId, 0, "accept")
		elseif responseData.action == "submitQuest" then
			QuestEvent:FireServer(responseData.questId, 0, "submit")
		elseif responseData.action == "giveItem" then
			GiveItemEvent:FireServer(responseData.itemName, responseData.amount)
        end
	end

	-- Actions (multi)
	if responseData.actions then
		for _, action in ipairs(responseData.actions) do
			if action.type == "acceptQuest" then
				QuestEvent:FireServer(action.questId, 0, "accept")
			elseif action.type == "submitQuest" then
				QuestEvent:FireServer(action.questId, 0, "submit")
			elseif action.type == "giveItem" then
				GiveItemEvent:FireServer(action.itemName, action.amount)
			end
			task.wait(1)
		end
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
end)

-- ==========================================
-- Handle Node Actions
-- ==========================================
dialogObject.nodeAction:Connect(function(dialogId, dialogData)
	if dialogData.actions then
		print("found actions : ")
		for _, action in ipairs(dialogData.actions) do
			if action.type == "acceptQuest" then
				print("try to send accept",action.questId)
				QuestEvent:FireServer(action.questId, 0, "accept")
			elseif action.type == "submitQuest" then
				print("try to send submit",action.questId)
				QuestEvent:FireServer(action.questId, 0, "submit")
			elseif action.type == "giveItem" then
				GiveItemEvent:FireServer(action.itemName, action.amount)
			end
			task.wait(1)
		end
	end
	if dialogData.action then
		if dialogData.action == "acceptQuest" then
			QuestEvent:FireServer(dialogData.questId, 0, "accept")
		elseif dialogData.action == "submitQuest" then
			QuestEvent:FireServer(dialogData.questId, 0, "submit")
		elseif dialogData.action == "giveItem" then
			GiveItemEvent:FireServer(dialogData.itemName, dialogData.amount)
		end
	end
end)

task.spawn(UpdateQuestState)