local ServerScriptService = game:GetService("ServerScriptService")

local EventHandlers = require(ServerScriptService:WaitForChild("SpecialEventManager"))
local SpecialEventTrigger = game:GetService("ServerStorage"):WaitForChild("BindableFunction"):WaitForChild("SpecialEventFunction")

SpecialEventTrigger.OnInvoke = function(eventId, ...)
    if EventHandlers[eventId] then
        
        local success, result = pcall(EventHandlers[eventId], ...)
        
        if success then
            return result
        else
            warn(string.format("[EventManager] เกิดข้อผิดพลาดระหว่างรัน Event '%s': %s", tostring(eventId), tostring(result)))
            return "ล้มเหลว: โค้ดใน Event Handler มีปัญหา"
        end
        
    else
        warn(string.format("[EventManager] ไม่พบฟังก์ชันสำหรับจัดการ EventId: '%s'", tostring(eventId)))
        return "ล้มเหลว: ไม่พบ EventId นี้ในระบบ"
    end
end