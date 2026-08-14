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
	DefaultCompletedDialogId = 30, -- บทสนทนาเริ่มต้นหากทำเสร็จทุกเควสแล้ว
	Quests = {
		{
			QuestID = "QT001",
			EnableAutoTrigger = true,
			AcceptDialogId = 1,
			InProgressDialogId = 30,
			SubmitDialogId = 20
		},
        {
            QuestID = "QT002",
            EnableAutoTrigger = false,
            AcceptDialogId = 0,
            InProgressDialogId = 11,
            SubmitDialogId = 20
        },
        {
           QuestID = "QT003",
           EnableAutoTrigger = false,
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
	[3] = {text = "มีคนบอกผู้ใหญ่ไว้ว่าหนูจะย้ายมาอยู่ที่นี่น่ะ", next=4, delay=1.5},
	[4] = { text = "ยินดีต้อนรับสู่หมู่บ้านของเรานะ!", next = 5},
	[5] = { text = "เอาล่ะๆ เดินทางมาน่าจะเหนื่อยใช่ไหม", next=6 },
	[6] = { text = "วันนี้หนูกลับไปพักผ่อนก่อนก็แล้วกัน",next=7 ,action="acceptQuest", questId="QT001"},
	[7] = { text = "แล้วเดี๋ยววันพรุ่งนี้ ผ้ใหญ่จะแนะนำสถานที่ต่างๆในหมู่บ้านให้รู้จัก", next=8, delay=2 },
	[8] = { text = "เอ้า! เอาตะเกียงนี่ไปด้วย แถวนั้นมันมืดน่ะ", action="giveItem", itemName="Lantern", amount=1, next=9, delay=1.5},
	[9] = { text = "บ้านของหนูจะอยู่ถนนเส้นนี้แหละ", next = 10 },
	[10] = { text = "เดินเลยวัดไปหน่อยนึงก็ถึงแล้ว พักผ่อนให้เต็มที่นะ !",
		responses={
			{ text="ขอบคุณครับ/ค่ะ", action="teleportPlayer", target="Farm"}
		},
	},

    [11] = { 
        text = string.format("สวัสดี".. player.Name),
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
	StopAutoTrigger() -- เคลียร์ของเก่าก่อนเริ่มใหม่

	autoTriggerConnection = RunService.Heartbeat:Connect(function()
		if isDialogOnCooldown then return end
	
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart

		if rootPart and npcRoot then
			local distance = (rootPart.Position - npcRoot.Position).Magnitude

			-- ถ้าผู้เล่นเดินเข้ามาใกล้ และยังไม่ได้เปิดหน้าต่างคุย
			if distance <= AUTO_TRIGGER_DISTANCE and not dialogObject.active then
				StopAutoTrigger() -- หยุดเช็คระยะทันทีที่เงื่อนไขเป็นจริง

				-- dialogObject:ToggleQuestNoti(false) -- ซ่อนไอคอนบนหัว
				dialogObject:triggerDialog(player, dialogId) -- เริ่มบทสนทนาอัตโนมัติ
			end
		end
	end)
end


-- ==========================================
-- Quest State icon & Quest autotrigger initial
-- ==========================================
local function UpdateQuestState()
	local success, questData = pcall(function()
		return GetQuestDataRF:InvokeServer()
	end)

	if not success then return end

	questData = questData or {}
	questData.active = questData.active or {}
	questData.completed = questData.completed or {}

	local isHandled = false

	for _, questConfig in ipairs(NPC_CONFIG.Quests) do
		local qId = questConfig.QuestID

		if not questData.completed[qId] then
			isHandled = true

			if not questData.active[qId] then
				-- ยังไม่ได้รับเควส
				dialogObject:ToggleQuestNoti(true, "main")
				if questConfig.EnableAutoTrigger then
					StartAutoTrigger(questConfig.AcceptDialogId)
				else
					StopAutoTrigger()
				end

			elseif not questData.active[qId].IsCompleted then
				-- กำลังทำเควส
				dialogObject:ToggleQuestNoti(false)
				StopAutoTrigger()

			else
				-- พร้อมส่งเควส
				dialogObject:ToggleQuestNoti(true, "submit")
				StopAutoTrigger()
			end

			break 
		end
	end

	if not isHandled then
		dialogObject:ToggleQuestNoti(false)
		StopAutoTrigger()
	end
end

task.spawn(UpdateQuestState)

-- ==========================================
-- Trigger สนทนา (เผื่อผู้เล่นกดปุ่ม E เร็วกว่าที่ NPC จะทัก)
-- ==========================================
prompt.Triggered:Connect(function(player)
	StopAutoTrigger() 
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
				QuestEvent:FireServer(qId, 0, "submit")
			end

			break 
		end
	end

	if not isHandled then
		dialogObject:triggerDialog(player, NPC_CONFIG.DefaultCompletedDialogId)
	end
end)

-- ==========================================
-- Handle Response & บทสนทนาจบลง
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