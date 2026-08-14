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
    -- อัปเดตข้อมูลแยกแต่ละ Label ตามที่คุณออกแบบ UI ไว้
    DayText.Text = tostring(Day.Value)        -- เติมคำว่า Day หรือจะปล่อยเป็นตัวเลขเดี่ยวๆ ก็ได้ครับ
    TimeText.Text = tostring(ClockTime.Value)
    SeasonText.Text = seasonName
    -- (เผื่ออยากใช้แบบข้อความยาวบรรทัดเดียวรวมกันทั้งหมด สามารถเปิดใช้บรรทัดนี้แทนได้ครับ)
    -- timeLabel.Text = string.format("ปีที่ %d | %s | วันที่ %d\nเวลา: %s", Year.Value, seasonName, Day.Value, ClockTime.Value)
end

-- สั่งให้ UI อัปเดตอัตโนมัติเมื่อ Server มีการเปลี่ยนค่าเวลา (เพิ่ม Year เข้าไปครบถ้วน)
ClockTime:GetPropertyChangedSignal("Value"):Connect(updateDisplay)
Day:GetPropertyChangedSignal("Value"):Connect(updateDisplay)
Season:GetPropertyChangedSignal("Value"):Connect(updateDisplay)
Year:GetPropertyChangedSignal("Value"):Connect(updateDisplay) -- 🌟 เพิ่มตัวดักฟังค่าปี

-- แสดงผลครั้งแรกตอนผู้เล่นโหลดเข้าเกม
updateDisplay()