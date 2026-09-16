local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- อ้างอิงถึง Event และเตียง
local SleepEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("SleepEvent")
local PlayerBed = Workspace:WaitForChild("Bed")
local BedPrompt = PlayerBed:WaitForChild("ProximityPrompt")

-- เมื่อผู้เล่นกดปุ่ม E ที่เตียงสำเร็จ
BedPrompt.Triggered:Connect(function()
	SleepEvent:FireServer()
end)
