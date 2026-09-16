local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==========================================
-- ควบคุมการ Freeze / Unfreeze ผู้เล่นด้วย ContextActionService
-- ==========================================
local FREEZE_ACTION = "FreezeLoadingInput"

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

-- ปิดการควบคุมทันทีตั้งแต่เริ่มสคริปต์
disableControls()

local loadingGui = script.Parent :: ScreenGui
loadingGui.Parent = playerGui
local background = loadingGui:WaitForChild("Background")
local statusText = background:WaitForChild("StatusText")

local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ==========================================
-- ฟังก์ชันปิด Loading Screen
-- ==========================================
local function closeLoadingScreen()
	TweenService:Create(background, tweenInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(statusText, tweenInfo, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	task.wait(1)
	loadingGui.Enabled = false
	-- Reset ค่าไว้สำหรับครั้งถัดไป (กรณีเปิดใหม่ตอน teleport)
	statusText.Text = ""
	background.BackgroundTransparency = 0
	statusText.TextTransparency = 0
	statusText.TextStrokeTransparency = 0
	player:SetAttribute("IsLoadingScreenClosed", true)

	-- คืนค่าการควบคุมให้ผู้เล่น
	enableControls()
end

-- ==========================================
-- Phase 1: Preload Assets (ลบตัวซ้ำออกแล้ว)
-- ==========================================
local assetsToLoad = {
	"rbxassetid://70859009130418",
	"rbxassetid://134095755209371",
	"rbxassetid://86774676134437",
	"rbxassetid://124864684237629",
	"rbxassetid://76728068891723",
	"rbxassetid://138077377865544",
	"rbxassetid://98956859708483",
	"rbxassetid://115197449851818",
	"rbxassetid://131388907328048",
	"rbxassetid://73606663896755",
	"rbxassetid://110458413922712",
	"rbxassetid://103967264691587",
	"rbxassetid://81220915909768",
	"rbxassetid://124175739862696",
	"rbxassetid://107463451362143",
	"rbxassetid://107065403679953",
	"rbxassetid://128278838587318",
	"rbxassetid://99651931693988",
	"rbxassetid://115419424118521",
	"rbxassetid://108601657790274",
	"rbxassetid://112599052775939",
	"rbxassetid://108635479285971",
}

local function addInstances(instance)
	table.insert(assetsToLoad, instance)
	for _, desc in ipairs(instance:GetDescendants()) do
		table.insert(assetsToLoad, desc)
	end
end

addInstances(playerGui)

local totalAssets = #assetsToLoad
local loadedAssets = 0

local LoadingEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("LoadingEvent")
local eventQueue = {}
local isProcessing = false
local isPreloadFinished = false

local function processQueue()
	if isProcessing or #eventQueue == 0 then return end
	isProcessing = true

	local status, message = table.unpack(table.remove(eventQueue, 1))

	if status then
		disableControls() -- ล็อกการควบคุมอีกครั้งหากมีการเปิดหน้าจอใหม่
		loadingGui.Enabled = true
		background.BackgroundTransparency = 0
		statusText.TextTransparency = 0
		statusText.TextStrokeTransparency = 0
		statusText.Text = message or "กำลังโหลดข้อมูล..."
	else
		while not isPreloadFinished do
			task.wait(0.1)
		end

		task.wait(0.3)
		if #eventQueue == 0 then
			closeLoadingScreen()
		end
	end

	isProcessing = false
	task.defer(processQueue)
end

LoadingEvent.OnClientEvent:Connect(function(...)
	table.insert(eventQueue, {...})
	task.defer(processQueue)
end)

-- ==========================================
-- Preload Assets Loop
-- ==========================================
statusText.Text = "กำลังเตรียมการโหลด..."

for i, asset in ipairs(assetsToLoad) do
	ContentProvider:PreloadAsync({asset})
	loadedAssets = loadedAssets + 1
	local percent = math.floor((loadedAssets / totalAssets) * 100)
	statusText.Text = "กำลังโหลดข้อมูล... " .. percent .. "%"
	if i % 50 == 0 then
		task.wait()
	end
end

isPreloadFinished = true
statusText.Text = "กำลังเตรียมข้อมูล..."