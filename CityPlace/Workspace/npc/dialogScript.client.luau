local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Module = ReplicatedStorage:WaitForChild("Module")
local DialogModule = require(Module:WaitForChild("DialogModule"))
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")

local player = game.Players.LocalPlayer

local npc = script.Parent
local prompt = npc:WaitForChild("ProximityPrompt")

local dialogTree = {
	[1] = {
		text = "สวัสดีหนูน้อย!",
		next = 2
	},
	[2] = {
		text = "สนใจทอผ้าไหม ? ผืนนี้ใช้เวลาทอหลายวันเลยนะ",
		responses  = {
			{
				text = "สวยมากเลยค่ะ/ครับ ทำยากไหมคะ/ครับ",
				next = 3
			}
		}
	},
	[3] = {
		text = "ไม่ยากเลย ! แค่ต้องใช้ความอดทนและความละเอียด",
		next = 4
	},
	[4] = {
		text = "ลวดลายแต่ละแบบมีความหมายของมันด้วยนะ",
		responses = {
			{
				text = "งั้นหนู/ผมขอลองทอผ้าดูได้ไหมคะ/ครับ",
				next = 10
			},
			{
				text = "ว้าว! แต่ละลวดลายมีความหมายว่ายังไงหรอคะ/ครับ",
				next = 20
			}
		}
	},
	
	[10] = {
		text  = "ได้สิ! ไปที่กี่ทอผ้าได้เลย เดี่ยวพี่อธิบายวิธีทอผ้าให้ฟังนะ",
		action = "acceptQuest",
		questId = "Q005",
	},
	
	[20]={
		text = "ก็อย่างเช่น..."
	}
	
}

local dialogObject = DialogModule.new("พี่มะลิ", npc, prompt)

-- Add Dialogs เข้า Module
for id, data in pairs(dialogTree) do
	dialogObject:addDialog(id, data)
end

-- Trigger เริ่มต้น
prompt.Triggered:Connect(function(player)
	local success, questData = pcall(function()
		return GetQuestDataRF:InvokeServer()
	end)

	if not success then return end
	questData = questData or { Active = {}, Completed = {} }

	if questData.Active["Q001"] and questData.Active["Q001"].TargetsStatus then
		if questData.Active["Q001"].TargetsStatus["Mali"] == false then
			QuestEvent:FireServer("Q001", 1, "update", "Mali")
		end
	end 
	
	dialogObject:triggerDialog(player, 1)
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
	end
end)

dialogObject.nodeAction:Connect(function(dialogId, dialogData)
	if dialogData.action == "acceptQuest" then
		QuestEvent:FireServer(dialogData.questId, 0, "accept")
	end
end)