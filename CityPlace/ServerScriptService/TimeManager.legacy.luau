local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local DataManager = require(ServerScriptService:WaitForChild("CityDataManager"))

local GameTimeData = ReplicatedStorage:WaitForChild("GameTimeData")
local ClockTime = GameTimeData:WaitForChild("ClockTime")
local DayValue = GameTimeData:WaitForChild("Day")
local SeasonValue = GameTimeData:WaitForChild("Season")
local YearValue = GameTimeData:WaitForChild("Year")
local SleepEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("SleepEvent")

-- ==========================================
-- รอข้อมูล WorldData จาก DataManager
-- ==========================================
print("[TimeSystem] กำลังรอข้อมูล WorldData จาก DataManager...")
while not DataManager.WorldData do
    task.wait(0.5)
end
print("[TimeSystem] ได้รับข้อมูล WorldData แล้ว! เริ่มระบบเวลา...")

local saveTimeData = DataManager.WorldData.time

local currentMinute = 0
local currentHour = saveTimeData.clock_time or 7
local currentDay = saveTimeData.day or 1
local currentSeason = saveTimeData.season or 1
local currentYear = saveTimeData.year or 1

local isTimePaused = false

local REAL_SECONDS_PER_GAME_MINUTE = 2
local PASS_OUT_HOUR = 2
local MAX_DAYS_PER_SEASON = 30

local HOME_SPAWN_LOCATION = CFrame.new(0, 5, 0) 

-- ==========================================
-- ฟังก์ชันจัดการแสงและเวลา
-- ==========================================
local function getLightingColors(timeDecimal)
    if timeDecimal >= 5.5 and timeDecimal < 8 then
        return Color3.fromRGB(236, 250, 247), Color3.fromRGB(216, 240, 252)
    elseif timeDecimal >= 8 and timeDecimal < 15.5 then
        return Color3.fromRGB(180, 180, 180), Color3.fromRGB(255, 255, 255)
    elseif timeDecimal >= 15.5 and timeDecimal < 18 then
        return Color3.fromRGB(255, 160, 100), Color3.fromRGB(255, 180, 80)
    elseif timeDecimal >= 18 and timeDecimal < 19.5 then
        return Color3.fromRGB(100, 90, 130), Color3.fromRGB(80, 80, 120)
    else
        return Color3.fromRGB(30, 30, 50), Color3.fromRGB(20, 20, 40)
    end
end

local function startNewDay()
    currentHour = 7
    currentMinute = 0
    currentDay += 1

    if currentDay > MAX_DAYS_PER_SEASON then
        currentDay = 1
        currentSeason += 1

        if currentSeason > 4 then
            currentSeason = 1
            currentYear += 1
            YearValue.Value = currentYear
        end
        SeasonValue.Value = currentSeason
    end

    DayValue.Value = currentDay

    -- [อัปเดตลงเซฟ] เมื่อเริ่มวันใหม่
    saveTimeData.clock_time = currentHour
    saveTimeData.day = currentDay
    saveTimeData.season = currentSeason
    saveTimeData.year = currentYear
end

local function passOutPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = HOME_SPAWN_LOCATION
            print(player.Name .. " passed out from exhaustion!")
        end
    end
end

-- ==========================================
-- ลูปการทำงานหลัก (Main Time Loop)
-- ==========================================
task.spawn(function()
    -- ตั้งค่า Value เริ่มต้นให้ Client เห็นตรงกับเซฟ
    DayValue.Value = currentDay
    SeasonValue.Value = currentSeason
    YearValue.Value = currentYear
    ClockTime.Value = string.format("%02d:%02d", currentHour, currentMinute)

    -- ปรับแสงของแมพครั้งแรกตอนโหลดเซฟเสร็จ
    Lighting.ClockTime = currentHour
    local initAmbient, initColorShift = getLightingColors(currentHour)
    Lighting.OutdoorAmbient = initAmbient
    Lighting.ColorShift_Top = initColorShift

    while true do
        task.wait(REAL_SECONDS_PER_GAME_MINUTE)

        if not isTimePaused then
            currentMinute += 10 

            if currentMinute >= 60 then
                currentMinute = 0
                currentHour += 1

                if currentHour >= 24 then
                    currentHour = 0
                end

                -- [อัปเดตลงเซฟ] ทุกครั้งที่ชั่วโมงเปลี่ยน
                saveTimeData.clock_time = currentHour
            end

            ClockTime.Value = string.format("%02d:%02d", currentHour, currentMinute)

            local targetDecimalTime = currentHour + (currentMinute / 60)
            if targetDecimalTime == 0 then
                targetDecimalTime = 24
            end

            local targetAmbient, targetColorShift = getLightingColors(targetDecimalTime)
            local tweenInfo = TweenInfo.new(REAL_SECONDS_PER_GAME_MINUTE, Enum.EasingStyle.Linear)
            local timeTween = TweenService:Create(Lighting, tweenInfo, {
                ClockTime = targetDecimalTime,
                OutdoorAmbient = targetAmbient,
                ColorShift_Top = targetColorShift
            })
            timeTween:Play()

            if currentHour == PASS_OUT_HOUR and currentMinute == 0 then
                passOutPlayers()
                isTimePaused = true

                for _, p in ipairs(Players:GetPlayers()) do
                    SleepEvent:FireClient(p, true)
                end

                task.wait(3)
                startNewDay()

                ClockTime.Value = "07:00"
                Lighting.ClockTime = 7
                local a, c = getLightingColors(7)
                Lighting.OutdoorAmbient = a
                Lighting.ColorShift_Top = c

                isTimePaused = false
                for _, p in ipairs(Players:GetPlayers()) do
                    SleepEvent:FireClient(p, false)
                end
            end
        end
    end
end)

-- ==========================================
-- Event การนอนหลับ (Sleep Event)
-- ==========================================
SleepEvent.OnServerEvent:Connect(function(player)
    if isTimePaused then return end

    isTimePaused = true
    SleepEvent:FireClient(player, true)

    task.wait(3)

    startNewDay()

    ClockTime.Value = string.format("%02d:%02d", currentHour, currentMinute)
    Lighting.ClockTime = 7
    local ambient, colorshift = getLightingColors(7)
    Lighting.OutdoorAmbient = ambient
    Lighting.ColorShift_Top = colorshift

    isTimePaused = false
    SleepEvent:FireClient(player, false)

    print(player.Name .. " went to sleep safely and woke up at 7:00 AM.")
end)