local QuestManager = {}
local QuestData = require(game.ReplicatedSstorage:WaitForChild("GameDataModule"):WaitForChild("QuestData"))

local ActiveQuests = {}
local CompletedQuests = {} 

function QuestManager.AcceptQuest(player, questId)
	local questInfo = QuestData[questId]
	if not questInfo then return false, "ไม่พบข้อมูลเควสนี้" end

	if not ActiveQuests[player] then ActiveQuests[player] = {} end
	if not CompletedQuests[player] then CompletedQuests[player] = {} end

	if CompletedQuests[player][questId] then
		return false, "คุณเคยทำเควสนี้เสร็จไปแล้ว"
	end

	if ActiveQuests[player][questId] then
		return false, "คุณกำลังทำเควสนี้อยู่"
	end

	local playerTargets = nil
	if questInfo.Target then
		playerTargets = {}
		for targetName, status in pairs(questInfo.Target) do
			playerTargets[targetName] = status
		end
	end

	ActiveQuests[player][questId] = {
		currentProgress = 0,
		IsCompleted = false,
		TargetsStatus = playerTargets
	}
	return true, "รับเควสสำเร็จ"
end

function QuestManager.AddProgress(player, questId, amount, targetName)
	local playerQuests = ActiveQuests[player]

	if playerQuests and playerQuests[questId] and not playerQuests[questId].IsCompleted then
		local questInfo = QuestData[questId]
		local activeQuest = playerQuests[questId]

		if activeQuest.TargetsStatus then
			if not targetName then
				warn("Error: เควส " .. questId .. " ต้องการ targetName แต่ไม่มีการส่งมา!")
				return false, "ข้อมูลเป้าหมายไม่ครบถ้วน"
			end

			if activeQuest.TargetsStatus[targetName] == nil then
				warn("Error: เป้าหมาย " .. targetName .. " ไม่มีในเควส " .. questId)
				return false, "เป้าหมายนี้ไม่เกี่ยวข้องกับเควส"
			end

			if activeQuest.TargetsStatus[targetName] == true then
				return false, "คุณทำเป้าหมายนี้ไปแล้ว" -- ดักการนับซ้ำตรงนี้
			end

			activeQuest.TargetsStatus[targetName] = true
		end

		local targetValue = questInfo.TargetAmount
		activeQuest.currentProgress += amount

		if activeQuest.currentProgress >= targetValue then
			activeQuest.currentProgress = targetValue
			activeQuest.IsCompleted = true
			return true, "ReadyToSubmit"
		end

		return true, "Updated"
	end

	return false, "ไม่พบเควส หรือเควสนี้รอส่ง/เสร็จสิ้นไปแล้ว"
end

function QuestManager.SubmitQuest(player, questId)
	local playerQuests = ActiveQuests[player]

	if playerQuests and playerQuests[questId] then
		if playerQuests[questId].IsCompleted then
			local questInfo = QuestData[questId]
			local rewards = questInfo.Rewards

			if rewards then
				print(player.Name .. " ส่งเควส " .. questInfo.Name .. " สำเร็จ! ได้รับ: " .. tostring(rewards.Coins))
			end

			ActiveQuests[player][questId] = nil

			if not CompletedQuests[player] then CompletedQuests[player] = {} end
			CompletedQuests[player][questId] = true

			return true, "เควส" .. questInfo.Name .. "สำเร็จ"
		else
			return false, "เควสนี้ยังทำเป้าหมายไม่ครบ"
		end
	end

	return false, "ไม่พบเควสนี้ในระบบ (อาจจะส่งไปแล้ว)"
end

function QuestManager.GetPlayerQuests(player)
	return ActiveQuests[player] or {}
end

function QuestManager.GetCompletedQuests(player)
	return CompletedQuests[player] or {}
end

function QuestManager.GetAllQuestData(player)
	return {
		Active = ActiveQuests[player] or {},
		Completed = CompletedQuests[player] or {}
	}
end

function QuestManager.GetQuestInfo(questId)
	return QuestData[questId]
end

-- 5. คืนค่าหน่วยความจำเมื่อผู้เล่นออก
game.Players.PlayerRemoving:Connect(function(player)
	ActiveQuests[player] = nil
	CompletedQuests[player] = nil 
end)

return QuestManager