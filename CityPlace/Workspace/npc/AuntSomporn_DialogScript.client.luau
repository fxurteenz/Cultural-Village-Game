local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("TeleportEvent")
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

local dialogObject = DialogModule.new("ป้าสมพร", npc, prompt)

-- ==========================================
-- NPC Setting
-- ==========================================
local NPC_CONFIG = {
	DefaultCompletedDialogId = 40, -- บทสนทนาเริ่มต้นหากทำเสร็จทุกเควสแล้ว
	Quests = {
		{
			QuestID = "Q001",
			EnableAutoTrigger = false,
			AcceptDialogId = 1,
			InProgressDialogId = 10,
			SubmitDialogId = 30
		},
	}
}

local dialogTree = {
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
        next=4,
        action="submitQuest",
        questId="QT003",
        delay=1.5
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
            {text="ไม่เคยครับ/ค่ะคุณป้า", next=8},
            -- {text="เคยครับ/ค่ะคุณป้า", next=8},
        }
	},
	[8] = {
		text = "ที่นี่มีแปลงสาธิตอยู่ หนูอยากลองดำนาดูมั้ยล่ะ?",
        responses = {
            {text="อยากครับ/ค่ะคุณป้า", next=9, action="acceptQuest", questId="Q003"},
        }
	},
    [9] = {
		text = "ดีเลย! รับต้นกล้าไปสิ",
		action = "giveItem",
        itemName = "RiceSprout(quest)",
        amount = 1,
        delay = 1.5,
        next = 10
	},
    [10] = {
		text = "เอาต้นกล้าไปดำนาแล้วกลับมาหาป้านะ", delay=1.6
	},

	[30] = {
		text = "เป็นไงบ้าง เรียบร้อยแล้วใช่ไหม",
		responses = {
			{
				text = "ใช่ครับ/ค่ะ",
				action = "submitQuest",
				questId = "Q003",
				next = 31,
			}
		},
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
		text = "เอาล่ะ.. รับเคียวของป้าไปสิ", next = 35
	},
	[35] = {
		text = "เอาไว้ใช้เก็บเกี่ยวผลผลิตของหนูนะ",
        responses = {
			{
				text = "ขอบคุณครับ/ค่ะ",
				action = "giveItem",
				itemName = "Sickle",
				amount = 1,
				next = 36,
			}
		}
	},
    [36] = {
        text ="แล้วก็เกือบลืมแหนะ...", delay=1.5
	},
    [37] = {
        text ="ถ้าอยากได้ต้นกล้าหรือเมล็ดพันธุ์ มาหาป้าได้เลยนะ", delay=1.5
	},

	[40] = {
        text ="วันนี้ให้ช่วยอะไรดีล่ะเจ้าหนู",
        responses = {
            {text="คุยกับป้าสมพร",next = 50},
            {text="ซื้อต้นกล้า/เมล็ดพันธุ์", action="openSeedShop"}
        }
	}
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

	-- Special handling for Q001 and Q002 if needed
	if questData.active["Q001"] and questData.active["Q001"].TargetsStatus and questData.active["Q001"].TargetsStatus["AuntySomporn"] == false then
		QuestEvent:FireServer("Q001", 1, "update", "AuntySomporn")
	end
	if questData.active["Q002"] then
		QuestEvent:FireServer("Q002", 1, "submit")
	end

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
	elseif responseData.action == "submitQuest" then
		QuestEvent:FireServer(responseData.questId, 0, "submit")
	elseif responseData.action == "giveItem" then
		GiveItemEvent:FireServer(responseData.itemName, responseData.amount)
    elseif responseData.action == "openSeedShop" then
		SeedShopBindable:Fire()
		dialogObject:hideGui()
    end
end)

dialogObject.nodeAction:Connect(function(dialogId, dialogData)
	if dialogData.action == "acceptQuest" then
		QuestEvent:FireServer(dialogData.questId, 0, "accept")
	elseif dialogData.action == "giveItem" then
		GiveItemEvent:FireServer(dialogData.itemName, dialogData.amount)
	end
end)

task.spawn(UpdateQuestState)