local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestManager = require(ReplicatedStorage:WaitForChild("Module"):WaitForChild("QuestModule"))
local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local QuestNotiEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestNotiEvent")

GetQuestDataRF.OnServerInvoke = function(player)
	return QuestManager.GetAllQuestData(player)
end

QuestEvent.OnServerEvent:Connect(function(player,questID,amount,event,targetName)
	if event == "accept" then

		local acceptResult, acceptMessage = QuestManager.AcceptQuest(player, questID)
		print("Accept :",questID , acceptResult, "ข้อความ:", acceptMessage)

		if acceptResult then
			local questData = QuestManager.GetQuestInfo(questID)

			if questData then
				local message = string.format("ภารกิจใหม่ : %s", questData.Description)
				QuestEvent:FireClient(player, "refresh")
				QuestNotiEvent:FireClient(player, message,"accept") 
			end
		end

	elseif event == "submit" then

		local questInfo = QuestManager.GetQuestInfo(questID)
		if questInfo and questInfo.TargetAmount == 1 then
			QuestManager.AddProgress(player, questID, 1, targetName)
		end

		local submitResult, submitMessage = QuestManager.SubmitQuest(player, questID)
		print("Submit:",questID, submitResult, "ข้อความ:", submitMessage)

		if submitResult then
			QuestEvent:FireClient(player, "refresh")
		end
		
		QuestNotiEvent:FireClient(player, submitMessage) 
	elseif event == "update" then
		local updateResult,updateMessage = QuestManager.AddProgress(player,questID,amount,targetName)
		if updateResult then
			QuestEvent:FireClient(player, "refresh")
		end
	end	
end)

