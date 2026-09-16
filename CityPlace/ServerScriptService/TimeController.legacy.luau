local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local DataManager = require(ServerScriptService:WaitForChild("DataManagerModule"))

local GameTimeData = ReplicatedStorage:WaitForChild("GameTimeData")
local ClockTime = GameTimeData:WaitForChild("ClockTime")
local DayValue = GameTimeData:WaitForChild("Day")
local SeasonValue = GameTimeData:WaitForChild("Season")
local YearValue = GameTimeData:WaitForChild("Year")

local SleepEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("SleepEvent")
local SpecialEventTrigger = ServerStorage:WaitForChild("BindableFunction"):WaitForChild("SpecialEventFunction")
local BindableQuestEvent = ServerStorage:WaitForChild("BindableFunction"):WaitForChild("QuestFunction")

local FARM_PLACE_ID = 106832184588439 
local TeleportFunction = ServerStorage:WaitForChild("BindableFunction"):WaitForChild("TeleportFunction")

-- ==========================================
-- ข้อมูล Event Calendar
-- ==========================================
local SeasonKeys = {
	[1] = "RN",
	[2] = "WT",
	[3] = "SM"
}

local EventCalendar = {
	RN = {},
	WT = {},
	SM = {},
}

-- ==========================================
-- ข้อมูลเวลา
-- ==========================================
local saveTimeData = nil
local currentMinute = 0
local currentHour = 7
local currentDay = 1
local currentSeason = 1
local currentYear = 1

local isTimePaused = false
local TimeTask = nil

local REAL_SECONDS_PER_GAME_MINUTE = 5
local PASS_OUT_HOUR = 2
local MAX_DAYS_PER_SEASON = 30
local MAX_SEASONS = 3

local HOME_SPAWN_LOCATION = CFrame.new(333, 16.308, -150.398) -- จุดตำแหน่งเตียงนอนในแมพฟาร์ม

local function checkSpecialEvent(seasonNum, dayNum)
	local seasonKey = SeasonKeys[seasonNum]
	if not seasonKey then return end

	local todayEvent = EventCalendar[seasonKey][dayNum]
	if todayEvent then
		print(string.format("[EventSystem] วันนี้มีเหตุการณ์พิเศษ: %s (EventID: %s)", todayEvent.eventName, todayEvent.eventId))

		if todayEvent.eventId == "CRANE_VISIT" then
			local riceFieldPosition = Vector3.new(364.141, 63, 251.512) 
			local animationToPlay = "idle"

			local success, response = pcall(function()
				return SpecialEventTrigger:Invoke(todayEvent.eventId, riceFieldPosition, animationToPlay, todayEvent.questId)
			end)

			if success then
				print("[EventSystem] แจ้งระบบนกกระเรียนสำเร็จ:", response)
			else
				warn("[EventSystem] ไม่สามารถแจ้งระบบนกกระเรียนได้:", response)
			end
		end
	end
end

local function sleepQuestsControl(player)
	local activeQuest = DataManager.PlayersData[player.UserId].quests.active
	local completedQuest = DataManager.PlayersData[player.UserId].quests.completed

	if activeQuest then
		if activeQuest["QT001"] then
			local result = BindableQuestEvent:Invoke(player, "QT001", 1, "submit")
			if result then
				BindableQuestEvent:Invoke(player, "QT002", 1, "accept")
			end
		end
	end
end

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

		if currentSeason > MAX_SEASONS then
			currentSeason = 1
			currentYear += 1
			YearValue.Value = currentYear
		end
		SeasonValue.Value = currentSeason
	end

	DayValue.Value = currentDay

	saveTimeData.clock_time = currentHour
	saveTimeData.day = currentDay
	saveTimeData.season = currentSeason
	saveTimeData.year = currentYear

	checkSpecialEvent(currentSeason, currentDay)
end

-- ==========================================
-- ฟังก์ชันจัดการตอนผู้เล่นสลบ (Exhausted)
-- ==========================================
local function handlePlayerPassOut()
	isTimePaused = true

	for _, p in ipairs(Players:GetPlayers()) do
		SleepEvent:FireClient(p, true, "คุณหมดสติเนื่องจากเหนื่อยล้าเกินไป...")
	end

	task.wait(2)
	startNewDay()

	if game.PlaceId ~= FARM_PLACE_ID then
		for _, p in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				TeleportFunction:Invoke(p, FARM_PLACE_ID,"Exhausted")
			end)
		end
	else
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				character:PivotTo(HOME_SPAWN_LOCATION)
				warn(player.Name .. " passed out and woke up at home!")
			end
		end

		ClockTime.Value = "07:00"
		Lighting.ClockTime = 7
		local a, c = getLightingColors(7)
		Lighting.OutdoorAmbient = a
		Lighting.ColorShift_Top = c

		isTimePaused = false
		task.wait(3)

		-- ปิดจอดำ
		for _, p in ipairs(Players:GetPlayers()) do
			SleepEvent:FireClient(p, false)
		end
	end
end

local function startTimeTask()
	TimeTask = task.spawn(function()
		DayValue.Value = currentDay
		SeasonValue.Value = currentSeason
		YearValue.Value = currentYear
		ClockTime.Value = string.format("%02d:%02d", currentHour, currentMinute)

		Lighting.ClockTime = currentHour
		local initAmbient, initColorShift = getLightingColors(currentHour)
		Lighting.OutdoorAmbient = initAmbient
		Lighting.ColorShift_Top = initColorShift

		checkSpecialEvent(currentSeason, currentDay)

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

				-- ตรวจสอบเวลาสลบ
				if currentHour == PASS_OUT_HOUR and currentMinute == 0 then
					handlePlayerPassOut()
				end
			end
		end
	end)    
end

-- ==========================================
-- ลูปการทำงานหลัก (Main Time Loop)
-- ==========================================
DataManager.WorldTimeSync.OnInvoke = function()
	saveTimeData = DataManager.WorldData.time
	currentHour = saveTimeData.clock_time
	currentDay = saveTimeData.day
	currentSeason = saveTimeData.season
	currentYear = saveTimeData.year

	startTimeTask()

	return true, "time synced start time"
end

SleepEvent.OnServerEvent:Connect(function(player)
	if isTimePaused then return end
	isTimePaused = true
	SleepEvent:FireClient(player, true, "กำลังเข้านอน...")

	startNewDay()

	ClockTime.Value = string.format("%02d:%02d", currentHour, currentMinute)
	Lighting.ClockTime = 7
	local ambient, colorshift = getLightingColors(7)
	Lighting.OutdoorAmbient = ambient
	Lighting.ColorShift_Top = colorshift

	task.wait(3)
	SleepEvent:FireClient(player, false)
	sleepQuestsControl(player)
	isTimePaused = false

	print(player.Name .. " went to sleep safely and woke up at 7:00 AM.")
end)

if DataManager.WorldData then
	saveTimeData = DataManager.WorldData.time
	currentHour = saveTimeData.clock_time
	currentDay = saveTimeData.day
	currentSeason = saveTimeData.season
	currentYear = saveTimeData.year

	if not TimeTask then
		startTimeTask()
	end
end