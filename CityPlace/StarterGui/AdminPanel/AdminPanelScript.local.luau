local Player = game:GetService("Players").LocalPlayer :: Player
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local ServerGiveItemEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("GiveItemEvent")
local testSpecialEvent = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("TestSpecialEvent")

-- อ้างอิงไปยังตำแหน่งของ UI ต่างๆ
local adminPanel = script.Parent
local mainFrame = adminPanel:WaitForChild("Frame")
local questPage = mainFrame:WaitForChild("QuestEventTest")

-- ตั้งค่า Admin
local player_id = tostring(Player.UserId)
local ADMIN_USER_ID = "7597767503"
local ADMIN_COMMAND = "/admin" -- สามารถเปลี่ยนคำสั่งได้ที่นี่

-- ปิดหน้าต่างไว้เป็นค่าเริ่มต้นตอนเข้าเกม
mainFrame.Visible = false

-- [[ เพิ่มระบบตรวจรับการพิมพ์แชท ]]
Player.Chatted:Connect(function(message)
	-- ตรวจสอบว่าเป็น Admin หรือไม่
	if player_id == ADMIN_USER_ID then
		-- ตรวจสอบข้อความ (แปลงเป็นพิมพ์เล็กเพื่อป้องกันปัญหาตัวพิมพ์เล็ก-ใหญ่)
		if message:lower() == ADMIN_COMMAND then
			mainFrame.Visible = not mainFrame.Visible -- สลับสถานะเปิด/ปิด
			print(mainFrame.Visible and "[DevPanel] เปิดใช้งาน" or "[DevPanel] ปิดใช้งาน")
		end
	end
end)
-- ===================================

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

--[[
	SPECIALEVENT TRIGGER TEST
]]

local specialEventTestPage = mainFrame:WaitForChild("SpecialEventTest")
local specialEventId = specialEventTestPage:WaitForChild("EventId")
local specialEventPosition = specialEventTestPage:WaitForChild("Position")
local specialEventTestBtn = specialEventTestPage:WaitForChild("TextButton")

specialEventTestBtn.MouseButton1Click:Connect(function()
	local eventId = specialEventId.Text
	local eventPosition = specialEventPosition.Text
	if eventId == "" then
		warn("[DevPanel] กรุณากรอกข้อมูลให้ครบถ้วน")
	end

	local invoke_res, check_res, invoke_data = pcall(function()
		return testSpecialEvent:InvokeServer(eventId, eventPosition)
	end)

	if invoke_res and check_res then
		print("[PLOT_CONTROLLER] ".. tostring(invoke_data))
	else
		warn("[PLOT_CONTROLLER] ".. tostring(invoke_data))
	end
end)