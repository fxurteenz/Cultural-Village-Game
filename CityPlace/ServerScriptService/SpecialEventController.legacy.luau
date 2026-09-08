local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local EventManager = require(ServerScriptService:WaitForChild("SpecialEventManager"))
local SpecialEventTrigger = game:GetService("ServerStorage"):WaitForChild("BindableFunction"):WaitForChild("SpecialEventFunction")
local BindableQuestFunction = ServerStorage:WaitForChild("BindableFunction"):WaitForChild("QuestFunction")
local TestSpecialEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunction"):WaitForChild("TestSpecialEvent")

local function checkEvent (eventId)
	if eventId then
		local check_res, isSuccess, check_data = pcall(function()
			return EventManager.checkSpecialEvent(eventId)
		end)
		if not check_res or not isSuccess then 
			return false, check_data 
		end
		check_data.eventId = eventId
		
		print("[SPECIAL_EVENT_CONTROLLER] : get ",eventId," event data ", HttpService:JSONEncode(check_data))
		local event_quest = check_data.eventQuest or nil
		if event_quest then
			print("[SPECIAL_EVENT_CONTROLLER] : detect event quest data")

			task.spawn(function()
				local questId = check_data.eventQuest.questId
				local questAction = check_data.eventQuest.questAction

				local maxRetries = 2 -- พยายามสูงสุด 30 ครั้ง (ประมาณ 1 นาที)
				local retryCount = 0
				local isSuccess = false

				-- วนลูปจนกว่าจะแจกเควสสำเร็จ หรือเกินโควต้าจำนวนครั้ง
				while not isSuccess and retryCount < maxRetries do
					retryCount += 1

					-- รับค่า pcall_success (สถานะรันโค้ด), invoke_result (ผลลัพธ์จากระบบเควส)
					local pcall_success, invoke_result, invoke_msg = pcall(function()
						return BindableQuestFunction:Invoke("all_player", questId, 1, questAction)
					end)

					-- ตรวจสอบว่าโค้ดรันผ่าน และผลลัพธ์จาก QuestController ไม่ใช่ false
					if pcall_success and invoke_result ~= false then
						isSuccess = true
						print("[SPECIAL_EVENT_CONTROLLER] : SUCCESSFULLY sent request to " .. tostring(questId))
					else
						-- กรณีที่ข้อมูลผู้เล่นยังโหลดไม่เสร็จ
						warn(string.format("[SPECIAL_EVENT_CONTROLLER] : FAIL to send request to %s | Retrying in 2 seconds... (%d/%d)", tostring(questId), retryCount, maxRetries))
						task.wait(2) -- รอ 2 วินาทีก่อนพยายามใหม่
					end
				end

				if not isSuccess then
					warn("[SPECIAL_EVENT_CONTROLLER] : หมดเวลา! ไม่สามารถแจกเควส " .. tostring(questId) .. " ได้สำเร็จ")
				end
			end)
		end

		if check_data.eventName == "CRANE_VISIT" then
			return EventManager.CRANE_VISIT(check_data)
		end
	end
end

SpecialEventTrigger.OnInvoke = function(eventId,eventPosition, ...)
	return checkEvent(eventId)
end

TestSpecialEvent.OnServerInvoke = function(eventId, eventPosition, ...)
	return checkEvent(eventId)
end