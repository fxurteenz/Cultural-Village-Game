local Player = game:GetService("Players").LocalPlayer :: Player
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local ServerGiveItemEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("GiveItemEvent")

-- อ้างอิงไปยังตำแหน่งของ UI ต่างๆ
local adminPanel = script.Parent
local mainFrame = adminPanel:WaitForChild("Frame")
local questPage = mainFrame:WaitForChild("QuestEventTest")

local player_id = tostring(Player.UserId)
if player_id ~= "7597767503" then
	adminPanel:Destroy()
else
	mainFrame.Visible = true
end
--[[
	QUEST EVENT TESTER
]]
local questIdBox = questPage:WaitForChild("QuestId")
local questAmountBox = questPage:WaitForChild("Amount")
local questEventBox = questPage:WaitForChild("Event")
local targetNameBox = questPage:WaitForChild("TargetName")
local sendQuestEventButton = questPage:WaitForChild("TextButton")

sendQuestEventButton.MouseButton1Click:Connect(function()
	local questId = questIdBox.Text
	local eventType = questEventBox.Text
	local amount = tonumber(questAmountBox.Text) or 0
	local targetName = targetNameBox.Text 

    if questId == "" or eventType == "" then
		warn("[DevPanel] กรุณากรอก QuestId และ Event ให้ครบถ้วน")
		return
	elseif eventType == "update" and (amount == 0 or targetName == "")then
		warn("[DevPanel] กรุณากรอก QuestAmount และ TargetName เพื่อ add progress")
        return
	end

	print(string.format("[DevPanel] กำลังส่ง Event: %s | Quest: %s | Amount: %d", eventType, questId, amount))
	QuestEvent:FireServer(questId, amount, eventType,targetName)

	questIdBox.Text = ""
	questAmountBox.Text = ""
	questEventBox.Text = ""
	targetNameBox.Text = ""
end)

--[[
	SERVER GIVE ITEM EVENT TESTER
]]

local serverGiveItemPage = mainFrame:WaitForChild("ServerItemEventTest")

local serverItemNameBox = serverGiveItemPage:WaitForChild("ItemName")
local serverItemAmountBox = serverGiveItemPage:WaitForChild("Amount")
local sendServerItemEventButton = serverGiveItemPage:WaitForChild("TextButton")

sendServerItemEventButton.MouseButton1Click:Connect(function()
	local serverItemName = serverItemNameBox.Text
	local amount = tonumber(serverItemAmountBox.Text) or 0
	if serverItemName == "" or amount == "" then
		warn("[DevPanel] กรุณากรอก ItemName และ Amount ให้ครบถ้วน")
		return
	end

	print(string.format("[DevPanel] กำลังส่ง Event: GiveItem(server) | ItemName: %s | Amount: %d", serverItemName, amount))
	ServerGiveItemEvent:FireServer(serverItemName, amount)

	serverItemNameBox.Text = ""
	serverItemAmountBox.Text = ""
end)
