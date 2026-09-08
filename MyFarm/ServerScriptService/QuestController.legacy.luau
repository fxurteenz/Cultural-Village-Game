local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")


local QuestManager = require(ReplicatedStorage:WaitForChild("Module"):WaitForChild("QuestModule"))
local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local QuestNotiEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestNotiEvent")
local BindableQuestFunction = ServerStorage:WaitForChild("BindableFunction"):WaitForChild("QuestFunction")
local GameManager = require(ServerScriptService:WaitForChild("DataManagerModule"))

GetQuestDataRF.OnServerInvoke = function(player)
    return QuestManager.GetAllQuestData(player)
end

local function ProcessQuestAction(targetPlayer, questID, amount, action, targetName)
    if action == "submit" then
        local questInfo = QuestManager.GetQuestInfo(questID)
        if questInfo and questInfo.TargetAmount == 1 then
            QuestManager.AddProgress(targetPlayer, questID, 1, targetName)
        end

        local submitResult, submitMessage = QuestManager.SubmitQuest(targetPlayer, questID)
        print("Submit:", questID, submitResult, "ข้อความ:", submitMessage)

        if submitResult then
            QuestEvent:FireClient(targetPlayer, "refresh")
        else
            warn("cannot submit quest")
        end

        QuestNotiEvent:FireClient(targetPlayer, submitMessage)
        return submitResult, submitMessage

    elseif action == "accept" then
        local acceptResult, acceptMessage = QuestManager.AcceptQuest(targetPlayer, questID)
        print("Accept :", questID, acceptResult, "ข้อความ:", acceptMessage)

        if acceptResult then
            local questData = QuestManager.GetQuestInfo(questID)

            if questData then
                local message = string.format("ภารกิจใหม่ : %s", questData.Description)
                QuestEvent:FireClient(targetPlayer, "refresh")
                QuestNotiEvent:FireClient(targetPlayer, message, "accept")
            end
        end

        return acceptResult, acceptMessage
    end
end

QuestEvent.OnServerEvent:Connect(function(player, questID, amount, action, targetName)
    ProcessQuestAction(player, questID, amount, action, targetName)
end)

BindableQuestFunction.OnInvoke = function(player, questID, amount, action, targetName)
	if player == "all_player" then
		local playersList = Players:GetPlayers()

		if #playersList == 0 then
			return false, "ยังไม่มีผู้เล่นในเซิร์ฟเวอร์"
		end

		local isAllSuccess = true
		local lastMessage = "ดำเนินการกับผู้เล่นทุกคนสำเร็จ"

		for _, p in ipairs(playersList) do
			local success, msg = ProcessQuestAction(p, questID, amount, action, targetName)
			if not success then
				isAllSuccess = false
				lastMessage = msg -- เก็บข้อความ Error ของคนที่แจกไม่สำเร็จไว้
			end
		end

		return isAllSuccess, lastMessage
	else
		return ProcessQuestAction(player, questID, amount, action, targetName)
	end
end

GameManager.PlayerLoaded.Event:Connect(function(player)
    QuestEvent:FireClient(player, "refresh")
end)