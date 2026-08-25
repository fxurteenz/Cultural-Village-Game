local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
 local HttpService = game:GetService("HttpService")
local EventManager = require(ServerScriptService:WaitForChild("SpecialEventManager"))
local SpecialEventTrigger = game:GetService("ServerStorage"):WaitForChild("BindableFunction"):WaitForChild("SpecialEventFunction")
local BindableQuestFunction = ServerStorage:WaitForChild("BindableFunction"):WaitForChild("QuestFunction")

SpecialEventTrigger.OnInvoke = function(eventId, ...)

    if eventId then
        local check_res, check_data = pcall(function()
            return EventManager.checkSpecialEvent(eventId)
        end)
        if not check_res then return check_res,check_data end

        print("[SPECIAL_EVENT_CONTROLLER] : get ",eventId," event data ", HttpService:JSONDecode(check_data))
        if check_data.eventQuest then
            task.spawn(function()
                local questId = check_data.eventQuest.questId
                local questAction = check_data.eventQuest.questAction
                local quest_action_res, quest_action_data = pcall(function()
                    return BindableQuestFunction:Invoke("all_player", questId,1, questAction)
                end)
                if quest_action_res then
                    print("[SPECIAL_EVENT_CONTROLLER] : send "..quest_action_data .." request to "..questId)
                else
                    warn("[SPECIAL_EVENT_CONTROLLER] : FAIL to send "..quest_action_data .." request to "..questId)
                end
            end)
        end

        if check_data.eventName == "CRANE_VISIT" then
            return EventManager.CRANE_VISIT()
        end
    end
    -- if EventHandlers[eventId] then
        
    --     local success, result = pcall(EventHandlers[eventId], ...)
        
    --     if success then
    --         return result
    --     else
    --         warn(string.format("[EventManager] เกิดข้อผิดพลาดระหว่างรัน Event '%s': %s", tostring(eventId), tostring(result)))
    --         return "ล้มเหลว: โค้ดใน Event Handler มีปัญหา"
    --     end
        
    -- else
    --     warn(string.format("[EventManager] ไม่พบฟังก์ชันสำหรับจัดการ EventId: '%s'", tostring(eventId)))
    --     return "ล้มเหลว: ไม่พบ EventId นี้ในระบบ"
    -- end
end