local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local player = game.Players.LocalPlayer
local Controls
-- อ้างอิงถึง Event และเตียง
local SleepEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("SleepEvent")
local PlayerBed = Workspace:WaitForChild("Bed")
local BedPrompt = PlayerBed:WaitForChild("ProximityPrompt")
local ContextActionService = game:GetService("ContextActionService")
local FREEZE_ACTION = "FreezeLoadingInput"

local COOLDOWN_TIME = 5 
local isCooldown = false
local function disableControls()
	ContextActionService:BindActionAtPriority(
		FREEZE_ACTION,
		function()
			return Enum.ContextActionResult.Sink -- กลืน Input การขยับทั้งหมดทิ้ง
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.PlayerActions.CharacterForward,
		Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft,
		Enum.PlayerActions.CharacterRight,
		Enum.PlayerActions.CharacterJump
	)
end

local function enableControls()
	ContextActionService:UnbindAction(FREEZE_ACTION)
end

-- เมื่อผู้เล่นกดปุ่ม E ที่เตียงสำเร็จ
BedPrompt.Triggered:Connect(function()
	if isCooldown then return end
	disableControls()

	isCooldown = true
	BedPrompt.Enabled = false

	SleepEvent:FireServer()

	task.wait(COOLDOWN_TIME)

	isCooldown = false
	enableControls()
	BedPrompt.Enabled = true
end)