local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Module = ReplicatedStorage:WaitForChild("Module")
local DialogModule = require(Module:WaitForChild("DialogModule"))
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")
local player = game.Players.LocalPlayer
local npc = script.Parent
local prompt = npc:WaitForChild("ProximityPrompt")

local dialogObject = DialogModule.new("ตาอิน", npc, prompt)

-- ==========================================
-- NPC Setting
-- ==========================================
local NPC_CONFIG = {
	DefaultCompletedDialogId = 1, -- บทสนทนาเริ่มต้นหากทำเสร็จทุกเควสแล้ว

	Quests = {
		--{
		--	QuestID = "Q003",
		--	EnableAutoTrigger = false,
		--	AcceptDialogId = 1, -- ถ้ายังไม่ทำเควส
		--	InProgressDialogId = 1, -- ถ้ากำลังทำเควส 
		--	SubmitDialogId = 1, -- ถ้าเควสเสร็จพร้อมรับรางวัล 
		--},
	}
}

local dialogTree = {
	
	[1] = {
		text = "สวัสดีเจ้าหนูน้อย...",
		next = 2,
	},
	
	[2] = {
		text = "ข้ามีชื่อว่าอิน",
		next = 3,
	},
	
	[3] = {
		text = "แล้วเอ็งชื่ออะไร?",
		next = 4,
	},
	
	[4] ={
		text = "หนูชื่อว่า" .. player.DisplayName,
		next = 5,
	},
	
	[5] = {
		text = "แล้วเจ้าพึ่งย้ายมาอยู่ที่นี้ใช่ไหม? ",
		next = 6,
	}, 
	
	[6] = {
		text = " ใช่ครับ/ใช่ต่ะ ",
		next = 7,
	},
	
	
	
	
	
	
	
	
	
	
	
	[200] = {
		text = "",
		responses = {
			{text="option1",next=1000},
			{text="option2",next=300}
		}
	},
	
	[1300] = {
		text = "quest dialog",
		action = "acceptQuest",
		questId = "T001",
		next = 400
	},
	[1400] = {
		text ="",
		action="submitQuest",
		questId="T001"
	},
	[2000] = {
		text ="ไปทำเควส",
	},
	
	[3000] = {
		text ="เก่งมาก",
		next=3100
	},
	[31] = {
		text ="เก่งมาก2",
		next=3200
	},
	[3300] = {
		text ="ส่งเควส",
		action="submitQuest",
		questId="T001",
		next=3400
	},
	
	[4000] ={
		text="มีอะไรให้ช่วยมั้ยหนู",
		responses = {
			{text="option1"},
			{text="option2"}
		}
	}
	
	--[2] = {
	--	text = "รู้ไหมว่าหมู่บ้านนี้มีประวัติมายาวนานกี่ปีแล้ว?",
	--	action = "acceptQuest", -- รับเควสเมื่อถึงบทสนทนานี้
	--	questId = "Q006",
	--	responses = {
	--		{ text = "ไม่ทราบเลยค่ะ/ครับ" , next = 3}
	--	}
	--} ,
	--[3] = {
	--	text = "มากกว่า 100 ปีแล้วล่ะ",
	--	next  = 4
	--},
	--[4] = {
	--	text = "คนที่นี่อยู่กับธรรมชาติ ช่วยกันดูแลชุมชน",
	--	responses = {
	--		{ text = "คุณตาเล่าเรื่องสมัยก่อนให้ฟังได้ไหมคะ/ครับ" ,next = 5},
	--		{ text = "สมัยก่อนต่างกับตอนนี้ยังไงหรอคะ/ครับ" ,next = 20}
	--	}
	--},
	
	--[5] = {
	--	text = "ได้สิ..",
	--	next = 6
	--},
	--[6] = {
	--	text = "หมู่บ้านนี้ก่อตั้งขึ้นเมื่อปี พ.ศ.2462" ,
	--	next = 7
	--},
	--[7]={
	--	text = "โดยมีผู้คนอพยพมาตั้งรกราก ลงหลักปักฐานกันอย่างหลากหลาย",
	--	next = 8
	--},
	--[8] = {
	--	text = "ทั้งกลุ่มชาติพันธ์ไทย/ลาว และกลุ่มชาติพันธุ์เขมร",
	--	next = 9 
	--},
	--[9] = {
	--	text = "เนื่องจากแถวๆนี้เนี่ย อุดมสมบูรณ์มาก มีแหล่งน้ำขนาดใหญ่",
	--	next = 10
	--},
	--[10] = {
	--	text = "แล้วบริเวณนี้ยังมีต้นมะม่วง ที่ออกผลมาจะมีผลเป็นสีขาว",
	--	next = 11
	--},
	--[11] = {
	--	text = "ภาษาถิ่นเขมรจะเรียกว่า “สะวายซอ”",
	--	next = 12
	--},
	--[12] = {
	--	text = "“สะวาย“ หมายถึง มะม่วง ",
	--	next = 13
	--},
	--[13] = {
	--	text = " “ซอ“ หรือ “สอ“ หมายถึง ขาว",
	--	next = 14
	--},
	--[14] = {
	--	text = "คำว่า “สวายสอ” จึงหมายถึง มะม่วงขาว",
	--	next = 15
	--},
	--[15] = {
	--	text = "และเป็นที่มาของชื่อหมู่บ้านนี้มาจนปัจจุบันนี่แหละหลานเอ้ย",
	--	responses ={
	--		{
	--			text = "ว้าว สุดยอดมากเลยค่ะ/ครับคุณปู่", 
	--		 	action = "submitQuest", -- ส่งเควสเมื่อจบบทสนทนา
	--			questId = "Q006"
	--		}
	--	}
	--},
	
	--[20] = {
	--	text = "ยังไม่มีบทพูด..."
	--},
	--[21] = {
	--	text = "",
	--	responses = {
	--		{text = "ยังไม่มีอะไรให้พูดค่ะ/ครับ",next=30},
	--		{text = "asd",next=22}
	--	}
	--},
	--[22] = {
	--	text = "asdf"
	--},
	
	--[30] = {
	--	text = "ยังไม่มีบทพูด..."
	--},
	
	
}

local function UpdateQuestState()
	local success, questData = pcall(function()
		return GetQuestDataRF:InvokeServer()
	end)
	if not success then return end
	questData = questData or { active = {}, completed = {} }

	local isHandled = false
	for _, questConfig in ipairs(NPC_CONFIG.Quests) do
		local qId = questConfig.QuestID
		if not questData.completed[qId] then
			isHandled = true
			if not questData.active[qId] then
				dialogObject:ToggleQuestNoti(true, "main") -- ยังไม่ได้รับเควส
			elseif not questData.active[qId].IsCompleted then
				dialogObject:ToggleQuestNoti(false) -- กำลังทำเควส
			else
				dialogObject:ToggleQuestNoti(true, "submit") -- พร้อมส่งเควส
			end
			break 
		end
	end
	if not isHandled then
		dialogObject:ToggleQuestNoti(false)
	end
end

-- Add Dialogs เข้า Module
for id, data in pairs(dialogTree) do
	dialogObject:addDialog(id, data)
end

prompt.Triggered:Connect(function(player)
	dialogObject:ToggleQuestNoti(false) 

	local success, questData = pcall(function()
		return GetQuestDataRF:InvokeServer()
	end)

	if not success then return end
	questData = questData or { active = {}, completed = {} }

	local isHandled = false
	for _, questConfig in ipairs(NPC_CONFIG.Quests) do
		local qId = questConfig.QuestID

		if not questData.completed[qId] then
			isHandled = true
			if not questData.active[qId] then
				dialogObject:triggerDialog(player, questConfig.AcceptDialogId)
			elseif not questData.active[qId].IsCompleted then
				dialogObject:triggerDialog(player, questConfig.InProgressDialogId)
			else
				dialogObject:triggerDialog(player, questConfig.SubmitDialogId)
			end
			break 
		end
	end

	if not isHandled then
		dialogObject:triggerDialog(player, NPC_CONFIG.DefaultCompletedDialogId)
	end
end)

-- Handle Response
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
	if responseData.action == "acceptQuest" then
		QuestEvent:FireServer(responseData.questId, 0, "accept")
	end
	if responseData.action == "submitQuest" then
		QuestEvent:FireServer(responseData.questId, 0, "submit")
	end
end)

dialogObject.nodeAction:Connect(function(dialogId, dialogData)
	if dialogData.action == "acceptQuest" then
		QuestEvent:FireServer(dialogData.questId, 0, "accept")
	end
	if dialogData.action == "submitQuest" then
		QuestEvent:FireServer(dialogData.questId, 0, "submit")
	end
end)

task.spawn(UpdateQuestState)