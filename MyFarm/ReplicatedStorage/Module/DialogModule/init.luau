local DialogModule = {}
DialogModule.__index = DialogModule

local tweenService = game:GetService("TweenService")
local runService = game:GetService('RunService')
local userInputService = game:GetService('UserInputService')
local collectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")

-- ตรวจสอบ Sound (เผื่อไม่มีไฟล์เสียง)
local TICK_SOUND = script:FindFirstChild("sounds") and script.sounds:FindFirstChild("tick")
local END_TICK_SOUND = script:FindFirstChild("sounds") and script.sounds:FindFirstChild("tick2")
local DIALOG_RESPONSES_UI = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Dialog"):WaitForChild("DialogResponses")
DialogModule.isPlayerInDialog = false -- State กลางสำหรับเช็คว่าผู้เล่นกำลังคุยอยู่หรือไม่
local DIALOG_ACTION = "DialogMovementLock"

local NOTI = {
	["orange"] = "118398951376939",
	["blue"] = "122925822331176",
	["green"] = "98764479101822",
}

local function lockControls()
	ContextActionService:BindAction(DIALOG_ACTION, function()
        return Enum.ContextActionResult.Sink end, false, unpack(Enum.PlayerActions:GetEnumItems())
    )
end

function DialogModule.new(npcName, npc, prompt, animation)
	local self = setmetatable({}, DialogModule)
	self.npcName = npcName
	self.npc = npc
	self.dialogs = {} 
	self.npcGui = self.npc:WaitForChild("Head"):WaitForChild("gui")
	self.npcNoti = self.npc:WaitForChild("Head"):WaitForChild("Noti")
	self.active = false
	self.talking = false
	self.prompt = prompt

	-- ตัวแปรสำหรับจัดการ Thread, Connection และ กล้อง
	self.currentTask = nil 
	self.cleanupConnections = {} 
	self.distanceConnection = nil 
	self.originalCameraCFrame = nil 

	-- Setup UI Template
	local template = DIALOG_RESPONSES_UI:FindFirstChild("template")
	if template then
		for i = 1, 9 do
			local newResponseButton = template:Clone()
			newResponseButton.Parent = DIALOG_RESPONSES_UI
			newResponseButton.Name = i
			newResponseButton.Visible = false
		end
		template:Destroy()
	end

	local eventSignal = Instance.new("BindableEvent")
	self.responded = eventSignal.Event
	self.fireResponded = eventSignal
	
	local nodeActionSignal = Instance.new("BindableEvent")
	self.nodeAction = nodeActionSignal.Event
	self.fireNodeAction = nodeActionSignal
	
	-- Tweens
	self.animNameText = tweenService:Create(self.npcGui.name, TweenInfo.new(.3), {TextTransparency = 1})
	self.animNameStroke = tweenService:Create(self.npcGui.name.UIStroke, TweenInfo.new(.3), {Transparency = 1})
	self.animArrowText = tweenService:Create(self.npcGui.arrow, TweenInfo.new(.3), {TextTransparency = 1})
	self.animArrowStroke = tweenService:Create(self.npcGui.arrow.UIStroke, TweenInfo.new(.3), {Transparency = 1})
	self.animDialogText = tweenService:Create(self.npcGui.dialog, TweenInfo.new(.3), {TextTransparency = 1})
	self.animDialogStroke = tweenService:Create(self.npcGui.dialog.UIStroke, TweenInfo.new(.3), {Transparency = 1})

	-- Animation
	if animation then
		local newAnimation = Instance.new("Animation")
		newAnimation.AnimationId = animation
		local humanoid = npc:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:LoadAnimation(newAnimation):Play()
		end
	end

	-- Floating Text Effect
	local frameCount = 0
	runService.Heartbeat:Connect(function()
		frameCount += 1
		if self.active then
			self.npcGui.StudsOffset = Vector3.new(0, 1.6, 0)
			self.npcNoti.StudsOffset = Vector3.new(0, 3, 0)
		else
			self.npcGui.StudsOffset = Vector3.new(0, math.sin(frameCount/25)/6 + 1.55, 0)
			self.npcNoti.StudsOffset = Vector3.new(0, math.sin(frameCount/25)/6 + 3, 0)
		end
	end)

	return self
end

function DialogModule:ToggleQuestNoti(showing, status)
	if status == "main" then
		self.npcNoti.ImageLabel.Image = "rbxassetid://" .. NOTI["orange"]
	elseif status == "side" then
		self.npcNoti.ImageLabel.Image = "rbxassetid://" .. NOTI["blue"]
	elseif status == "submit" then
		self.npcNoti.ImageLabel.Image = "rbxassetid://" .. NOTI["green"]
	end

	if showing then
		self.npcNoti.Enabled = true
	else
		self.npcNoti.Enabled = false
	end
end

function DialogModule:addDialog(id, data)
	self.dialogs[id] = data
end

function DialogModule:stopCurrentTask()
	if self.currentTask and self.currentTask ~= coroutine.running() then
		task.cancel(self.currentTask)
	end

	self.currentTask = nil

	if self.distanceConnection then
		self.distanceConnection:Disconnect()
		self.distanceConnection = nil
	end

	self:clearConnections()
end

function DialogModule:triggerDialog(player, dialogId)
	self:stopCurrentTask()
	self:showGui()
	self.active = true
	
	DialogModule.isPlayerInDialog = true
	lockControls()

	if not self.distanceConnection then
		self.distanceConnection = runService.Heartbeat:Connect(function()
			local npcRoot = self.npc.PrimaryPart or self.npc:FindFirstChild("HumanoidRootPart")
			if npcRoot and player.Character and player.Character.PrimaryPart then
				local distance = (player.Character.PrimaryPart.Position - npcRoot.Position).Magnitude
				if distance > 15 then
					self:hideGui()
				end
			end
		end)
	end

	local dialog = self.dialogs[dialogId]
	if not dialog then
		warn("Dialog ID not found: " .. tostring(dialogId))
		self:hideGui()
		return
	end

	self.currentTask = task.spawn(function()
		-- ระบบ Camera Lock & Zoom
		local camera = workspace.CurrentCamera
		local camPart = self.npc:FindFirstChild("CamPart")

		if camPart then
			-- เช็คว่าเป็น Custom อยู่ไหม (เพิ่งเริ่มคุยครั้งแรก) ถ้าใช่ให้บันทึกมุมเดิมไว้
			if camera.CameraType ~= Enum.CameraType.Scriptable then
				self.originalCameraCFrame = camera.CFrame
				camera.CameraType = Enum.CameraType.Scriptable
			end

			-- Tween ไปที่ CamPart
			tweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = camPart.CFrame,
				FieldOfView = 55
			}):Play()
		else
			-- ถ้าไม่มี CamPart ให้ Zoom แค่ FOV เหมือนเดิม
			tweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = 55}):Play()
		end

		self.talking = true
		local dialogObject = self.npcGui.dialog
		dialogObject.Visible = true

		-- Typewriter Effect
		local currenttext = ""
		local skip = false
		local arrow = 0
		for letter in string.gmatch(dialog.text, utf8.charpattern) do
			if not self.active then return end 

			currenttext = currenttext .. letter
			if letter == "<" then skip = true end
			if letter == ">" then skip = false; arrow += 1; continue end
			if arrow == 2 then arrow = 0 end
			if skip then continue end

			dialogObject.Text = currenttext .. (if arrow == 1 then "</font>" else "")
			if TICK_SOUND then TICK_SOUND:Play() end
			task.wait(0.02)
		end

		if not self.active then return end
		dialogObject.Text = dialog.text
		self.talking = false
		
		if dialog.action then
			self.fireNodeAction:Fire(dialogId, dialog)
		end

		-- Auto Next
		if not dialog.responses or #dialog.responses == 0 then
			local waitTime = dialog.delay or 1.0
			task.wait(waitTime)

			if not self.active then return end

			if dialog.next then
				self:triggerDialog(player, dialog.next)
			else
				self:hideGui()
			end
			return
		end

		-- Show Responses
		self:clearConnections()

		for i, response in ipairs(dialog.responses) do
			local optionUI = DIALOG_RESPONSES_UI:FindFirstChild(tostring(i))
			if not optionUI then continue end

			optionUI.text.Text = "<font color='rgb(255,220,127)'>" .. i .. ".)</font> " .. response.text
			optionUI.Size = UDim2.fromScale(optionUI.Size.X.Scale, .4)
			optionUI.text.Position = UDim2.new(0.02, 0, 0.5, 0)
			optionUI.Visible = true

			local enterCon = optionUI.MouseEnter:Connect(function()
				tweenService:Create(optionUI, TweenInfo.new(0.3), {Size = UDim2.new(optionUI.Size.X.Scale * 1.05, 0, 0.4, 0)}):Play()
				if END_TICK_SOUND then END_TICK_SOUND:Play() end
			end)
			local leaveCon = optionUI.MouseLeave:Connect(function()
				tweenService:Create(optionUI, TweenInfo.new(0.3), {Size = UDim2.new(optionUI.Size.X.Scale, 0, 0.35, 0)}):Play()
			end)
			local clickCon = optionUI.MouseButton1Down:Connect(function()
				self:handleResponse(i, dialogId, response)
			end)

			table.insert(self.cleanupConnections, enterCon)
			table.insert(self.cleanupConnections, leaveCon)
			table.insert(self.cleanupConnections, clickCon)

			task.wait(0.05)
		end

		-- Keyboard Input
		local inputCon = userInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local keyString = input.KeyCode.Name
				local numMap = {One=1, Two=2, Three=3, Four=4, Five=5, Six=6, Seven=7, Eight=8, Nine=9}
				local num = numMap[keyString]
				if num and dialog.responses[num] then
					self:handleResponse(num, dialogId, dialog.responses[num])
				end
			end
		end)
		table.insert(self.cleanupConnections, inputCon)
	end)
end

function DialogModule:handleResponse(choiceIndex, currentDialogId, responseData)
	if not self.active then return end

	for _, child in pairs(DIALOG_RESPONSES_UI:GetChildren()) do
		if child:IsA("GuiButton") then child.Visible = false end
	end
	self:clearConnections()

	if TICK_SOUND then TICK_SOUND:Play() end
	self.fireResponded:Fire(choiceIndex, currentDialogId, responseData)
end

function DialogModule:clearConnections()
	for _, con in ipairs(self.cleanupConnections) do
		con:Disconnect()
	end
	self.cleanupConnections = {}
end

function DialogModule:showGui()
	self:togglePrompts(false)

	self.animNameText:Play()
	self.animNameStroke:Play()
	self.animArrowText:Play()
	self.animArrowStroke:Play()

	self.npcGui.dialog.TextTransparency = 0
	self.npcGui.dialog.UIStroke.Transparency = 0

	task.delay(0.3, function()
		if self.active then
			self.npcGui.name.Visible = false
			self.npcGui.arrow.Visible = false
		end
	end)
end

function DialogModule:hideGui()
	self.active = false
	self:stopCurrentTask()

	DialogModule.isPlayerInDialog = false
	ContextActionService:UnbindAction(DIALOG_ACTION)

	self:togglePrompts(true)

	local camera = workspace.CurrentCamera
	if camera.CameraType == Enum.CameraType.Scriptable then
		-- Tween กลับ
		local targetCFrame = self.originalCameraCFrame or camera.CFrame
		local tweenBack = tweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = targetCFrame,
			FieldOfView = 70
		})
		tweenBack:Play()

		task.delay(0.5, function()
			if not self.active then
				camera.CameraType = Enum.CameraType.Custom
				self.originalCameraCFrame = nil
			end
		end)
	else
		tweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = 70}):Play()
	end

	self.npcGui.dialog.TextTransparency = 1
	self.npcGui.dialog.UIStroke.Transparency = 1
	self.npcGui.name.Visible = true; self.npcGui.arrow.Visible = true
	self.npcGui.name.TextTransparency = 0; self.npcGui.name.UIStroke.Transparency = 0

	for _, child in pairs(DIALOG_RESPONSES_UI:GetChildren()) do
		if child:IsA("GuiButton") then child.Visible = false end
	end
end

function DialogModule:togglePrompts(state)
	for _, prompt in pairs(collectionService:GetTagged("NPCprompt")) do
		if prompt:IsA("ProximityPrompt") then prompt.Enabled = state end
	end
	if self.prompt then self.prompt.Enabled = state end
end

return DialogModule