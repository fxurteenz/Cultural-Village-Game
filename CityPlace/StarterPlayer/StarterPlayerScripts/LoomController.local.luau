local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local GiveItemEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("GiveItemEvent")
local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")

local Module = ReplicatedStorage:WaitForChild("Module")
local DialogModule = require(Module:WaitForChild("DialogModule"))

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local loom = workspace:WaitForChild("Loom")
local heddle1 = loom:WaitForChild("Heddle1")
local heddle1_key = heddle1:WaitForChild("KeyBind")
local heddle2 = loom:WaitForChild("Heddle2")
local heddle2_key = heddle2:WaitForChild("KeyBind")
local reed = loom:WaitForChild("Reed")
local reed_key = reed:WaitForChild("KeyBind")
local exit_key = loom:WaitForChild("KeyBind")
heddle1_key.Enabled = false
heddle2_key.Enabled = false
reed_key.Enabled = false
exit_key.Enabled = false
local seat = loom:WaitForChild("Seat")
local camPart = loom:WaitForChild("CamPart")
local paddleBar = loom:WaitForChild("HeddlePaddleBar")
local paddle1Hinge = paddleBar:WaitForChild("Paddle1Hinge")
local paddle2Hinge = paddleBar:WaitForChild("Paddle2Hinge")
local shuttle = loom:WaitForChild("Shuttle")
local threadBeam = loom:WaitForChild("WeftThreadStart"):WaitForChild("Beam")
local startPosPart = loom:WaitForChild("ShuttleStartPos") 
local endPosPart = loom:WaitForChild("ShuttleEndPos")

local npcStartPart = loom:WaitForChild("NpcStartPart") 
local npcEndPart = loom:WaitForChild("NpcEndPart")     
local npcTemplate = ReplicatedStorage:WaitForChild("NpcTemplate"):WaitForChild("Mali")

if not heddle1.PrimaryPart then heddle1.PrimaryPart = heddle1:FindFirstChild("Top") or heddle1:FindFirstChildWhichIsA("BasePart") end
if not heddle2.PrimaryPart then heddle2.PrimaryPart = heddle2:FindFirstChild("Top") or heddle2:FindFirstChildWhichIsA("BasePart") end
if not shuttle.PrimaryPart then shuttle.PrimaryPart = shuttle:FindFirstChildWhichIsA("BasePart") end

local h1StartCFrame = heddle1.PrimaryPart.CFrame
local h2StartCFrame = heddle2.PrimaryPart.CFrame
local shuttleInitialRot = shuttle.PrimaryPart.CFrame.Rotation
local reedStartCFrame = reed.CFrame

---------------------------------------------------------
-- ⚙️ ตัวแปรตั้งค่า
---------------------------------------------------------
local moveOffset = 0.25      
local pedalDownAngle = 5       
local pedalUpAngle = 5         
local reedBeatOffset = Vector3.new(0, 0, -1.5) 

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local shuttleInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local reedInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local isPlaying = false 

local currentHeddleState = "Left"
local currentSide = "Left"
local isDraggingShuttle = false
local draggingConnection
local shuttleAtStart = true

local TARGET_ROUNDS = 5          -- จำนวนรอบที่ต้องการให้ทอจนจบ
local QUEST_ID = "Q003_3"  -- ID ของเควสที่ต้องการส่งเมื่อเล่นจบ (เปลี่ยนตามของคุณ)
local REWARD_ITEM = "TraditionalFabric" -- ชื่อไอเทมที่จะได้รับ (เปลี่ยนตามของคุณ)
local REWARD_AMOUNT = 1

local currentRounds = 0          -- ตัวนับรอบปัจจุบัน
local isShuttlePassed = false    -- เช็คว่าดึงกระสวยแล้วหรือยัง (กันผู้เล่นกด Spacebar รัวๆ)
-- ตัวแปรเควส
local hasTutorialQuest = true 
local isTutorialPlaying = false
---------------------------------------------------------
-- ระบบ Highlight ไกด์นำทางสำหรับเด็ก
---------------------------------------------------------
local guideHighlight = Instance.new("Highlight")
guideHighlight.FillTransparency = 1  -- ปิดสีพื้นทึบ
guideHighlight.OutlineColor = Color3.fromRGB(255, 255, 0) -- สีเหลืองสดใสให้สังเกตง่าย
guideHighlight.OutlineTransparency = 0
guideHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- ทะลุกำแพงได้

local expectedGuideAction = nil -- ค่าจะเป็น "Heddle", "Shuttle", หรือ "Reed"
local guideCyclesLeft = 0

local function setHighlight(targetObject)
	if targetObject then
		guideHighlight.Parent = targetObject
	else
		guideHighlight.Parent = nil
	end
end

local function nextTutorialStep(completedAction)
	if guideCyclesLeft <= 0 then return end

	if completedAction == "Start" or completedAction == "Reed" then
		if completedAction == "Reed" then
			guideCyclesLeft -= 1
			if guideCyclesLeft <= 0 then
				expectedGuideAction = nil
				setHighlight(nil)
				print("✅ จบระบบไกด์นำทาง 2 รอบ ผู้เล่นเล่นเองได้เลย!")
				return
			end
		end
		expectedGuideAction = "Heddle"
		setHighlight(heddle1) -- ไฮไลท์ที่คันเร่งเหยียบ
		setHighlight(heddle2) -- ไฮไลท์ที่คันเร่งเหยียบ
        heddle1_key.Enabled = true
	elseif completedAction == "Heddle" then
		expectedGuideAction = "Shuttle"
		setHighlight(shuttle) -- ไฮไลท์กระสวย
        heddle2_key.Enabled = true

	elseif completedAction == "Shuttle" then
		expectedGuideAction = "Reed"
		setHighlight(reed) -- ไฮไลท์ฟืม
        reed_key.Enabled = true
	end
end

---------------------------------------------------------
-- ระบบควบคุม NPC และ Dialog สอนทอผ้า
---------------------------------------------------------
local function walkNPC(npc, targetPosition)
	local humanoid = npc:WaitForChild("Humanoid")
	local rootPart = npc:WaitForChild("HumanoidRootPart")
	local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentWalkableClimbMargin = 2})
	local success, errorMessage = pcall(function() path:ComputeAsync(rootPart.Position, targetPosition) end)
	if success and path.Status == Enum.PathStatus.Success then
		for _, waypoint in pairs(path:GetWaypoints()) do
			if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
			humanoid:MoveTo(waypoint.Position)
			humanoid.MoveToFinished:Wait()
		end
	end
end

local function startTutorialSequence()
	if isTutorialPlaying then return end
	isTutorialPlaying = true
	hasTutorialQuest = false 

	local tutorialNPC = npcTemplate:Clone()
	tutorialNPC:PivotTo(npcStartPart.CFrame)
	tutorialNPC.Parent = workspace

	local fakePrompt = Instance.new("ProximityPrompt")
	fakePrompt.Enabled = false
	fakePrompt.Parent = tutorialNPC

	local dialogObject = DialogModule.new("พี่มะลิ", tutorialNPC, fakePrompt)
	local tutorialDialogTree = {
		[1] = { text = "เอาล่ะ เดี๋ยวพี่มะลิจะสอนวิธีทอผ้าให้นะจ๊ะ", next = 2 },
		[2] = { text = "เริ่มจากการให้หนูกดปุ่ม Q หรือ E เพื่อสลับตะกอ", next = 3,delay=1.5 },
		[3] = { text = "พอสลับตะกอแล้ว", next = 4 },
		[4] = { text = "ให้ใช้เมาส์คลิกลาก 'กระสวย' สอดด้ายไปอีกฝั่ง", next = 5 ,delay=1.5},
		[5] = { text = "สุดท้าย พอด้ายสอดไปแล้ว", next = 6 },
		[6] = { text = "กดปุ่ม Spacebar เพื่อดึง 'ฟืม' กระทบให้ด้ายแน่นจ้ะ", next = 7 , delay=1.5},
		[7] = { text = "เดี๋ยวลองทำตามกรอบสีเหลืองดูสัก 3-4 รอบนะจ๊ะ!", action = "endTutorial" ,delay = 1.5}
	}

	for id, data in pairs(tutorialDialogTree) do dialogObject:addDialog(id, data) end

	local dialogFinished = Instance.new("BindableEvent")
	local responseConn
	responseConn = dialogObject.responded:Connect(function(choiceIndex, currentDialogId, responseData)
		local nextId = (responseData and responseData.next) or tutorialDialogTree[currentDialogId].next
		if nextId then
            if tutorialDialogTree[currentDialogId].delay then
                task.wait(tutorialDialogTree[currentDialogId].delay)    
            end
			task.wait(0.3)
			dialogObject:triggerDialog(player, nextId)
		else
			task.wait(0.5)
			dialogObject:hideGui()
			dialogFinished:Fire()
		end
	end)

	local actionConn
	actionConn = dialogObject.nodeAction:Connect(function(dialogId, dialogData)
		if dialogData.action == "endTutorial" then
			task.wait(0.5)
			dialogObject:hideGui()
			dialogFinished:Fire()
		end
	end)

	walkNPC(tutorialNPC, npcEndPart.Position)
	tutorialNPC:PivotTo(CFrame.lookAt(tutorialNPC:GetPivot().Position, seat.Position))
	dialogObject:triggerDialog(player, 1)

	dialogFinished.Event:Wait()

	responseConn:Disconnect()
	actionConn:Disconnect()
	dialogFinished:Destroy()
	
	if isPlaying then 
		task.wait(1)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = camPart.CFrame
	end

	walkNPC(tutorialNPC, npcStartPart.Position)
	tutorialNPC:Destroy()
	isTutorialPlaying = false

	guideCyclesLeft = 4
	nextTutorialStep("Start")
end

-------------------------------------------------
--  ระบบเข้า-ออก มินิเกม
-------------------------------------------------
local function exitMiniGame()
    local myHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if myHumanoid then 
        myHumanoid.Sit = false
        myHumanoid.JumpPower = 50 
    end
    
    isPlaying = false
    camera.CameraType = Enum.CameraType.Custom
    setHighlight(nil)

    -- รีเซ็ตค่าการเล่น
    currentRounds = 0
    isShuttlePassed = false

    reed_key.Enabled = false
    heddle1_key.Enabled = false
    heddle2_key.Enabled = false
    exit_key.Enabled = false
end

---------------------------------------------------------
-- ฟังก์ชันควบคุมกลไกต่างๆ 
---------------------------------------------------------
local function stepLeft()
	print("เหยียบซ้าย!")
	TweenService:Create(heddle1.PrimaryPart, tweenInfo, {CFrame = h1StartCFrame * CFrame.new(0, -moveOffset, 0)}):Play()
	TweenService:Create(heddle2.PrimaryPart, tweenInfo, {CFrame = h2StartCFrame * CFrame.new(0, moveOffset, 0)}):Play()
	paddle1Hinge.TargetAngle = pedalDownAngle
	paddle2Hinge.TargetAngle = pedalUpAngle
end

local function stepRight()
	print("เหยียบขวา!")
	TweenService:Create(heddle1.PrimaryPart, tweenInfo, {CFrame = h1StartCFrame * CFrame.new(0, moveOffset, 0)}):Play()
	TweenService:Create(heddle2.PrimaryPart, tweenInfo, {CFrame = h2StartCFrame * CFrame.new(0, -moveOffset, 0)}):Play()
	paddle1Hinge.TargetAngle = pedalUpAngle
	paddle2Hinge.TargetAngle = pedalDownAngle
end

local function beatReed()
	print("ตึ้ง! กระทบฟืม")
	local beatTween = TweenService:Create(reed, reedInfo, {CFrame = reedStartCFrame * CFrame.new(reedBeatOffset)})
	local returnTween = TweenService:Create(reed, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {CFrame = reedStartCFrame})
	beatTween:Play()
	beatTween.Completed:Wait()
	returnTween:Play()

    if expectedGuideAction == nil and isShuttlePassed then
		isShuttlePassed = false
		currentRounds += 1
		print("ผ้าทอคืบหน้า: " .. currentRounds .. "/" .. TARGET_ROUNDS .. " รอบ")

		if currentRounds >= TARGET_ROUNDS then
			print("🎉 ทอผ้าเสร็จสมบูรณ์!")
			
			-- 1. ให้ไอเทมรางวัล
			GiveItemEvent:FireServer(REWARD_ITEM, REWARD_AMOUNT)
			
			-- 2. ตรวจสอบสถานะเควสและส่งเควสถ้ามี
			local success, questData = pcall(function() return GetQuestDataRF:InvokeServer() end)
			if success and questData then
				-- เช็คว่ามีเควสนี้กำลัง InProgress อยู่หรือไม่
				if questData.active and questData.active[QUEST_ID] then
					QuestEvent:FireServer(QUEST_ID, 0, "submit")
					print("✅ ส่งเควสทอผ้าเรียบร้อย")
				end
			end
			
			-- 3. รีเซ็ตและออกจากมินิเกม
			currentRounds = 0
			exitMiniGame()
		end
	end
end

local function passShuttle(side)
	local goalCFrame
	if side == "ToRight" then goalCFrame = endPosPart.CFrame; currentSide = "Right"
	else goalCFrame = startPosPart.CFrame; currentSide = "Left" end
	threadBeam.Enabled = true 
	local shuttleTween = TweenService:Create(shuttle.PrimaryPart, shuttleInfo, {CFrame = goalCFrame})
	shuttleTween:Play()
end

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	local occupantHumanoid = seat.Occupant
	if occupantHumanoid and occupantHumanoid.Parent == player.Character then
		isPlaying = true
        exit_key.Enabled = true


		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = camPart.CFrame 
		occupantHumanoid.UseJumpPower = true
		occupantHumanoid.JumpPower = 0
		if hasTutorialQuest then task.spawn(startTutorialSequence) end
	elseif not occupantHumanoid and isPlaying then
		exitMiniGame()
	end
end)

---------------------------------------------------------
-- ระบบรับค่าปุ่มกด และคลิกเมาส์
---------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isPlaying then return end
	if isTutorialPlaying then return end -- ห้ามกดตอน NPC พูด

	if expectedGuideAction then

		if expectedGuideAction == "Heddle" then
            heddle1_key.Enabled = true
			if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
				if input.KeyCode == Enum.KeyCode.Q then stepLeft() else stepRight() end
				nextTutorialStep("Heddle")
			end
			return

		elseif expectedGuideAction == "Reed" then
            reed_key.Enabled = true
			if input.KeyCode == Enum.KeyCode.Space then
				beatReed()
				nextTutorialStep("Reed")
			end
			return

		elseif expectedGuideAction == "Shuttle" then
            reed_key.Enabled = true
			if input.UserInputType == Enum.UserInputType.Keyboard then
				return 
			end
		end

	else

		if input.KeyCode == Enum.KeyCode.Q then stepLeft()
		elseif input.KeyCode == Enum.KeyCode.E then stepRight()
		elseif input.KeyCode == Enum.KeyCode.Space then beatReed()
		elseif input.KeyCode == Enum.KeyCode.X then exitMiniGame() end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if mouse.Target and (mouse.Target:IsDescendantOf(shuttle) or mouse.Target == shuttle.PrimaryPart) then
			isDraggingShuttle = true
			shuttle.PrimaryPart.CanCollide = false
			draggingConnection = RunService.RenderStepped:Connect(function()
				if isDraggingShuttle and shuttleAtStart then
					local startPos = startPosPart.Position
					local endPos = endPosPart.Position
					local lineDir = (endPos - startPos).Unit
					local clampedProj = math.clamp((mouse.Hit.Position - startPos):Dot(lineDir), 0, (endPos - startPos).Magnitude)
					shuttle.PrimaryPart.CFrame = CFrame.new(startPos + (lineDir * clampedProj)) * shuttleInitialRot
				end
			end)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if isDraggingShuttle then
			isDraggingShuttle = false
			if draggingConnection then draggingConnection:Disconnect() end 

			local distToStart = (shuttle.PrimaryPart.Position - startPosPart.Position).Magnitude
			local distToEnd = (shuttle.PrimaryPart.Position - endPosPart.Position).Magnitude

			local passedSuccessfully = false

			if currentSide == "Left" then
				if distToEnd < 2 then passShuttle("ToRight"); passedSuccessfully = true 
				else TweenService:Create(shuttle.PrimaryPart, TweenInfo.new(0.2), {CFrame = startPosPart.CFrame}):Play() end
			elseif currentSide == "Right" then
				if distToStart < 2 then passShuttle("ToLeft"); passedSuccessfully = true 
				else TweenService:Create(shuttle.PrimaryPart, TweenInfo.new(0.2), {CFrame = endPosPart.CFrame}):Play() end
			end

			-- เมื่อลากกระสวยสำเร็จ ให้อนุญาตให้สเต็ปการดึงฟืมนับเป็นการนับรอบ
			if passedSuccessfully then
				isShuttlePassed = true
				if expectedGuideAction == "Shuttle" then
					nextTutorialStep("Shuttle")
				end
			end
		end
	end
end)

