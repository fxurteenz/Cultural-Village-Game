local PathfindingService = game:GetService("PathfindingService")
local NpcDirectory = workspace:WaitForChild("Npc")

local Mali = NpcDirectory:WaitForChild("Mali")

local humanoid = Mali:WaitForChild("Humanoid")
local rootPart = Mali:WaitForChild("HumanoidRootPart")

-- กำหนดจุดหมาย (เปลี่ยนเป็นตำแหน่งที่คุณต้องการ)
local targetPart = workspace:WaitForChild("Npc"):WaitForChild("WalkTarget"):WaitForChild("toLoom")

local function walkTo(targetLocation)
	-- 1. สร้าง Path
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentWalkableClimbMargin = 2
	})

	-- 2. คำนวณเส้นทาง
	local success, errorMessage = pcall(function()
		path:ComputeAsync(rootPart.Position, targetLocation)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		-- 3. รับจุด Waypoints (จุดย่อยๆ ระหว่างทาง)
		local waypoints = path:GetWaypoints()

		for _, waypoint in pairs(waypoints) do
			-- ถ้าต้องกระโดด ให้ NPC กระโดด
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end

			-- สั่งให้เดินไปยังจุด Waypoint นั้นๆ
			humanoid:MoveTo(waypoint.Position)

			-- รอจนกว่าจะถึงจุดย่อยนั้น (Time out 2 วินาทีกันค้าง)
			humanoid.MoveToFinished:Wait()
		end
	else
		warn("ไม่สามารถคำนวณเส้นทางได้: " .. tostring(errorMessage))
	end
end


-- เรียกใช้งานฟังก์ชัน
wait(5)
walkTo(targetPart.Position)
