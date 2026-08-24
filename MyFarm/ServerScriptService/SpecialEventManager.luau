local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpecialEventDatabase = require(ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("SpecialEventDatabase"))

local SpecialEventManager = {}

function SpecialEventManager.CRANE_VISIT(position, animationName, questId)
	print("--------------------------------------------------")
	print("[EventHandler] กำลังรันเหตุการณ์: นกกระเรียนลงนา")
	local ModelDir = (game:GetService("ServerStorage")):WaitForChild("CraneModel")
	local craneModel = (ModelDir:FindFirstChild("Sarus")):Clone()
	if craneModel then
		craneModel:PivotTo(CFrame.new(position))
		craneModel:SetAttribute("animTrack", animationName or "idle")
		craneModel.Parent = workspace
    else
        return false,"ผิดพลาด หาโมเดลนกไม่พบ"
	end
	print("[EventHandler] จบการทำงานเหตุการณ์นกกระเรียนลงนา")
	print("--------------------------------------------------")
	return true,"สำเร็จ! จัดการนกกระเรียนเรียบร้อยแล้ว"
end

function SpecialEventManager.SUMMER_FESTIVAL()
	print("[EventHandler] เริ่มเทศกาลฤดูร้อน!")
	return "สำเร็จ! โหลดงานเทศกาลฤดูร้อนแล้ว"
end

function SpecialEventManager.checkSpecialEvent(eventId)
    if SpecialEventDatabase[eventId] then
        return true, SpecialEventDatabase[eventId]
    else
        return false, "ไม่พบ อีเวนท์พิเศษจาก", eventId
    end
end

return SpecialEventManager
