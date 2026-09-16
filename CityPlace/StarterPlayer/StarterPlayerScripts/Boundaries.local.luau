local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local boundariesModel = workspace:WaitForChild("Boundaries")

-- === ตั้งค่าตามที่คุณต้องการ ===
local FADE_DISTANCE = 20 -- ระยะที่จะเริ่มเห็นกำแพง (Studs)
local MIN_TRANSPARENCY = 0.2 -- ความโปร่งใสเมื่อเอาตัวถูชิดกำแพง
local MAX_TRANSPARENCY = 0.95 -- ความโปร่งใสปกติ (มองไม่เห็น)

-- 1. ตั้งค่ากำแพงทั้งหมดตอนเริ่มเกมให้พร้อมใช้งานและกินสเปคน้อยที่สุด
for _, boundary in pairs(boundariesModel:GetChildren()) do
	if boundary:IsA("BasePart") then
		boundary.Transparency = MAX_TRANSPARENCY
		boundary.Material = Enum.Material.Glass
		boundary.Color = Color3.fromRGB(150, 200, 255) -- สีฟ้าอ่อนๆ คล้ายกระจก
		boundary.CanCollide = true
		boundary.Anchored = true
		boundary.CastShadow = false -- **สำคัญมาก** ปิดเงาเพื่อลดการใช้ทรัพยากรเครื่อง
	end
end

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = {boundariesModel}

-- ฟังก์ชันคณิตศาสตร์: คำนวณหาระยะห่างที่ "แม่นยำที่สุด" จากตัวผู้เล่นถึง "พื้นผิว" ของ Part
local function getDistanceToSurface(part, position)
	local localPos = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size / 2
	local closestLocalPos = Vector3.new(
		math.clamp(localPos.X, -halfSize.X, halfSize.X),
		math.clamp(localPos.Y, -halfSize.Y, halfSize.Y),
		math.clamp(localPos.Z, -halfSize.Z, halfSize.Z)
	)
	local closestWorldPos = part.CFrame:PointToWorldSpace(closestLocalPos)
	return (position - closestWorldPos).Magnitude
end

local activeParts = {} -- ตัวแปรจำว่ามีกำแพงชิ้นไหนบ้างที่กำลังแสดงผลอยู่

-- 2. ทำงานทุกๆ เฟรมของหน้าจอ
RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local playerPos = rootPart.Position

	-- ค้นหากำแพงเฉพาะในรัศมีที่กำหนด (ไม่ต้องไปเช็คทั้ง 496 ชิ้น ทำให้ไม่แลค)
	-- บวกเพิ่ม 2 Studs เผื่อเวลาผู้เล่นวิ่งเร็วๆ จะได้คำนวณทัน
	local partsNearby = workspace:GetPartBoundsInRadius(playerPos, FADE_DISTANCE + 2, overlapParams)

	local currentNearby = {}

	-- วนลูปคำนวณความโปร่งใสเฉพาะกำแพงที่อยู่ใกล้
	for _, part in ipairs(partsNearby) do
		currentNearby[part] = true
		activeParts[part] = true

		local distance = getDistanceToSurface(part, playerPos)

		if distance <= FADE_DISTANCE then
			-- คำนวณเป็นเปอร์เซ็นต์ (0 = ชน, 1 = ห่าง 10 Studs)
			local percent = math.clamp(distance / FADE_DISTANCE, 0, 1)

			-- แปลงเปอร์เซ็นต์ให้เป็นค่า Transparency (ระหว่าง 0.2 ถึง 1.0)
			local targetTrans = MIN_TRANSPARENCY + ((MAX_TRANSPARENCY - MIN_TRANSPARENCY) * percent)
			part.Transparency = targetTrans
		else
			part.Transparency = MAX_TRANSPARENCY
		end
	end

	-- 3. เคลียร์ค่ากำแพงที่ผู้เล่นเดินห่างออกมาแล้วให้กลับไปล่องหนเหมือนเดิม
	for part, _ in pairs(activeParts) do
		if not currentNearby[part] then
			part.Transparency = MAX_TRANSPARENCY
			activeParts[part] = nil
		end
	end
end)