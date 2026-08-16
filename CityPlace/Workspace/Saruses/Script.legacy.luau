local model = script.Parent
local humanoid = model:WaitForChild("Humanoid")

-- ค้นหา Animator หรือสร้างใหม่ถ้ายังไม่มี
local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
	animator = Instance.new("Animator")
	animator.Parent = humanoid
end

-- อ้างอิงโฟลเดอร์และแอนิเมชัน
local animFolder = model:WaitForChild("anim")
print("กำลังค้นหาในโฟลเดอร์ anim... สิ่งที่เจอคือ:")
for _, child in pairs(animFolder:GetChildren()) do
	print("- " .. child.Name .. " (ประเภท: " .. child.ClassName .. ")")
end
local idleAnim = animFolder:WaitForChild("idle")
--local walkAnim = animFolder:WaitForChild("walk") -- เพิ่มท่าเดินเข้ามา

local idleTrack = animator:LoadAnimation(idleAnim)
--local walkTrack = animator:LoadAnimation(walkAnim)

idleTrack.Looped = true
--walkTrack.Looped = true

idleTrack:Play()

humanoid.Running:Connect(function(speed)
	if speed > 0.1 then
		--if not walkTrack.IsPlaying then
		--	idleTrack:Stop()
		--	walkTrack:Play()
		--end
	else
		if not idleTrack.IsPlaying then
			--walkTrack:Stop()
			idleTrack:Play()
		end
	end
end)

print("ระบบแอนิเมชันสัตว์ (Humanoid) พร้อมทำงาน!")

---------------------------------------------------------

--task.spawn(function()
--	while task.wait(3) do
--		-- สุ่มตำแหน่งรอบๆ ตัวมันเพื่อเดินไป
--		local randomOffset = Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
--		local targetPosition = model.PrimaryPart.Position + randomOffset

--		-- สั่งให้ Humanoid เดินไปยังจุดที่กำหนด
--		humanoid:MoveTo(targetPosition)
--		humanoid.MoveToFinished:Wait() -- รอจนกว่าจะเดินถึง
--		task.wait(2) -- ยืนพัก 2 วินาทีก่อนเดินใหม่
--	end
--end)

-----------------------------------------------------------