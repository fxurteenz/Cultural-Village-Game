local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- อ้างอิงถึง UI ของเรา
local DateTimeFrame = script.Parent:WaitForChild("DateTimeFrame")
local TimeFrame = DateTimeFrame:WaitForChild("TimeFrame")
local TimeText = TimeFrame:WaitForChild("Time")
local DayText = TimeFrame:WaitForChild("Day")
local SeasonText = TimeFrame:WaitForChild("Season")

-- ดึงข้อมูลโฟลเดอร์ที่เราสร้างไว้ใน Server
local GameTimeData = ReplicatedStorage:WaitForChild("GameTimeData")
local ClockTime = GameTimeData:WaitForChild("ClockTime")
local Day = GameTimeData:WaitForChild("Day")
local Season = GameTimeData:WaitForChild("Season")
local Year = GameTimeData:WaitForChild("Year")

-- ฟังก์ชันแปลงตัวเลขฤดูเป็นข้อความ
local function getSeasonName(seasonNumber)
    local seasons = {"RN", "SU", "WT"}
    return seasons[seasonNumber] or "NN"
end

-- ฟังก์ชันอัปเดตข้อความบนหน้าจอ
local function updateDisplay()
    local seasonName = getSeasonName(Season.Value)
    DayText.Text = tostring(Day.Value)
    TimeText.Text = tostring(ClockTime.Value)
    SeasonText.Text = seasonName
end

ClockTime:GetPropertyChangedSignal("Value"):Connect(updateDisplay)
Day:GetPropertyChangedSignal("Value"):Connect(updateDisplay)
Season:GetPropertyChangedSignal("Value"):Connect(updateDisplay)
Year:GetPropertyChangedSignal("Value"):Connect(updateDisplay)

updateDisplay()