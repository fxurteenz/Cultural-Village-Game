local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpecialEventDatabase = require(ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("SpecialEventDatabase"))

local SpecialEventManager = {}
SpecialEventManager.ActiveEvents = {}

local function getObjectFromPath(path)
	local parts = string.split(path, "/")
	local current = game
	for i, part in ipairs(parts) do
		if i == 1 then
			current = game:GetService(part)
		else
			current = current:WaitForChild(part, 3) 
		end
		if not current then return nil end
	end
	return current
end


function SpecialEventManager.CRANE_VISIT(eventData)
	print("--------------------------------------------------")
	print("[EventHandler] กำลังรันเหตุการณ์: ".. eventData.eventName)

	if eventData and eventData.eventWorldObject then
		for _, objInfo in ipairs(eventData.eventWorldObject) do
			local originalModel = getObjectFromPath(objInfo.path)

			if originalModel then
				local pos = objInfo.placePos
				local targetCFrame = CFrame.new(pos.x, pos.y, pos.z)
				local targetModel : Model

				if originalModel:IsDescendantOf(workspace) then
					targetModel = originalModel
				else
					local existingModel = workspace:FindFirstChild(objInfo.name)

					if existingModel then
						targetModel = existingModel
					else
						targetModel = originalModel:Clone()
						targetModel.Name = objInfo.name
						targetModel.Parent = workspace
					end
				end
				
				targetModel:SetAttribute("ActiveSpecialEvent",eventData.eventId)
				targetModel:PivotTo(targetCFrame)

				--if objInfo.name == "Sarus" then
				--	targetModel:SetAttribute("animTrack", "idle")
				--end
				if objInfo.attribute then
					for _, attr in ipairs(objInfo.attribute) do
						targetModel:SetAttribute(attr[1],attr[2])
					end
				end
			else
				warn("[EventHandler] ผิดพลาด! หาโมเดลไม่พบที่ Path: " .. tostring(objInfo.path))
			end
		end
	else
		return false, "ไม่พบข้อมูล eventWorldObject ในฐานข้อมูล"
	end

	print("[EventHandler] จบการทำงานเหตุการณ์นกกระเรียนลงนา")
	print("--------------------------------------------------")
	return true, "สำเร็จ! จัดการวางโมเดลทั้งหมดเรียบร้อยแล้ว"
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
