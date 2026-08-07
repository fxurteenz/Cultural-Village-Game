local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

-- ดึงค่ามาจาก ReplicatedStorage
local GameTimeData = ReplicatedStorage:WaitForChild("GameTimeData")
local ClockTime = GameTimeData:WaitForChild("ClockTime")
local DayValue = GameTimeData:WaitForChild("Day")
local SeasonValue = GameTimeData:WaitForChild("Season")
local YearValue = GameTimeData:WaitForChild("Year")
local SleepEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("SleepEvent")

-- ตั้งค่าเริ่มต้น
local currentMinute = 0
local currentHour = 7
local currentDay = 1
local currentSeason = 1 
local currentYear = 1

local isTimePaused = false

-- ตั้งค่าความเร็วของเวลา
local REAL_SECONDS_PER_GAME_MINUTE = 2
local PASS_OUT_HOUR = 2
local MAX_DAYS_PER_SEASON = 30

local HOME_SPAWN_LOCATION = CFrame.new(337.6, 19.208, -137.873) 

local function startNewDay()
	currentHour = 7
	currentMinute = 0
	currentDay += 1

	if currentDay > MAX_DAYS_PER_SEASON then
		currentDay = 1
		currentSeason += 1

		if currentSeason > 3 then
			currentSeason = 1
			currentYear += 1
			YearValue.Value = currentYear
		end
		SeasonValue.Value = currentSeason
	end

	DayValue.Value = currentDay
end

local function passOutPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			-- วาร์ปผู้เล่นกลับบ้าน
			character.HumanoidRootPart.CFrame = HOME_SPAWN_LOCATION

			-- ตรงนี้สามารถใส่โค้ดลดพลังงาน หรือหักเงินค่ารักษาได้ในอนาคต
			print(player.Name .. " passed out from exhaustion!")
		end
	end
end

local function getLightingColors(timeDecimal)
	if timeDecimal >= 5.5 and timeDecimal < 8 then
		-- ช่วงเช้าตรู่ (รุ่งอรุณ): แสงโทนส้มอมชมพูอ่อนๆ ดูสดชื่น
		return Color3.fromRGB(236, 250, 247), Color3.fromRGB(216, 240, 252)

	elseif timeDecimal >= 8 and timeDecimal < 15.5 then
		-- กลางวัน: แสงสว่างสดใส ธรรมชาติ
		return Color3.fromRGB(180, 180, 180), Color3.fromRGB(255, 255, 255)

	elseif timeDecimal >= 15.5 and timeDecimal < 18 then
		-- ช่วงเย็น (Golden Hour): แสงสีส้มทองอบอุ่น เหมาะกับบรรยากาศทุ่งนา
		return Color3.fromRGB(255, 160, 100), Color3.fromRGB(255, 180, 80)

	elseif timeDecimal >= 18 and timeDecimal < 19.5 then
		-- พลบค่ำ (Twilight): โทนม่วงอมน้ำเงิน
		return Color3.fromRGB(100, 90, 130), Color3.fromRGB(80, 80, 120)

	else
		-- กลางคืน: มืด โทนน้ำเงินเข้ม
		return Color3.fromRGB(30, 30, 50), Color3.fromRGB(20, 20, 40)
	end
end

-- ตารางเก็บสถานะจำลอง (ของจริงควรโหลด/เซฟด้วย DataStore)
local PlayerData = {}

local isSleepingTransition = false

Players.PlayerAdded:Connect(function(player)
	--TODO: load data from datastore
	
	-- จำลองว่าทุกคนที่เข้ามาคือเพิ่งมาครั้งแรก
	local hasCompletedFirstNight = false 
	PlayerData[player.UserId] = {
		HasCompletedFirstNight = hasCompletedFirstNight
	}

	-- ถ้ายังไม่เคยผ่านคืนแรก บังคับเวลาให้มืดทันที
	if not hasCompletedFirstNight then
		currentHour = 20
		currentMinute = 0
		ClockTime.Value = "20:00"
		Lighting.ClockTime = 20

		local ambient, colorshift = getLightingColors(20)
		Lighting.OutdoorAmbient = ambient
		Lighting.ColorShift_Top = colorshift

		isTimePaused = true 
	end
end)

task.spawn(function()
	DayValue.Value = currentDay
	SeasonValue.Value = currentSeason
	YearValue.Value = currentYear

	while true do
		task.wait(REAL_SECONDS_PER_GAME_MINUTE)

		-- ถ้าเวลาไม่ได้ถูกหยุดไว้ (ผู้เล่นไม่ได้นอน) ค่อยให้เวลาเดินปกติ
		if not isTimePaused then
			currentMinute += 10 

			if currentMinute >= 60 then
				currentMinute = 0
				currentHour += 1
			end

			if currentHour >= 24 then
				currentHour = 0
			end

			ClockTime.Value = string.format("%02d:%02d", currentHour, currentMinute)

			local targetDecimalTime = currentHour + (currentMinute / 60)
			if targetDecimalTime == 0 then
				targetDecimalTime = 24
			end

			-- 1. เรียกฟังก์ชันเพื่อขอค่าสี Ambient และ แสงตกกระทบ ตามเวลาเป้าหมาย
			local targetAmbient, targetColorShift = getLightingColors(targetDecimalTime)

			-- 2. เพิ่ม OutdoorAmbient และ ColorShift_Top เข้าไปในเป้าหมายของ Tween
			local tweenInfo = TweenInfo.new(REAL_SECONDS_PER_GAME_MINUTE, Enum.EasingStyle.Linear)
			local timeTween = TweenService:Create(Lighting, tweenInfo, {
				ClockTime = targetDecimalTime,
				OutdoorAmbient = targetAmbient,
				ColorShift_Top = targetColorShift
			})

			timeTween:Play()

			if currentHour == PASS_OUT_HOUR and currentMinute == 0 then
				passOutPlayers()

				-- กรณีสลบ ให้ขึ้นจอดำและข้ามวันเหมือนกัน
				isTimePaused = true
				-- สั่งให้ Client ทุกคนโชว์จอดำ
				for _, p in ipairs(Players:GetPlayers()) do
					SleepEvent:FireClient(p, true)
				end
				task.wait(3) -- ค้างไว้ 3 วินาทีตอนสลบ
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


SleepEvent.OnServerEvent:Connect(function(player)
	-- ป้องกันคนกดรัวๆ ระหว่างที่จอกำลังมืด
	if isSleepingTransition then return end
	isSleepingTransition = true

	-- หยุดเวลาของเกมชั่วคราวระหว่างเปลี่ยนวัน
	isTimePaused = true

	-- 1. สั่งเปิด HUD การนอนที่ Client
	SleepEvent:FireClient(player, true)
	task.wait(3)

	-- 2. เปลี่ยนวันและรีเซ็ตเวลาเป็น 7:00
	startNewDay()

	-- 3. อัปเดตเวลาและท้องฟ้าใน Server ทันที
	ClockTime.Value = string.format("%02d:%02d", currentHour, currentMinute)
	Lighting.ClockTime = 7
	local ambient, colorshift = getLightingColors(7)
	Lighting.OutdoorAmbient = ambient
	Lighting.ColorShift_Top = colorshift

	-- 4. ให้เวลาของเกมกลับมาเดินปกติ
	isTimePaused = false

	-- 5. สั่งปิด HUD ที่ Client
	SleepEvent:FireClient(player, false)

	print(player.Name .. " went to sleep safely and woke up at 7:00 AM.")

	-- ==========================================
	-- ตรวจสอบเหตุการณ์ "เช้าวันแรก"
	-- ==========================================
	local pData = PlayerData[player.UserId]
	if pData and pData.HasCompletedFirstNight == false then

		-- อัปเดตสถานะว่าผ่านคืนแรกแล้ว
		pData.HasCompletedFirstNight = true

		-- [อย่าลืมเขียนโค้ดบันทึก pData.HasCompletedFirstNight ลง DataStore ตรงนี้นะครับ]

		print("เช้าวันแรกเริ่มต้นขึ้น! ผู้ใหญ่บ้านกำลังมาที่ฟาร์ม")

		-- สั่ง Spawn โมเดล NPC ผู้ใหญ่บ้าน (ที่คุณเตรียมไว้) มาไว้ที่หน้าบ้าน
		-- หรือ FireClient ไปบอกให้ LocalScript เป็นคนดึง NPC มาแสดงผล
		-- ตัวอย่าง: TutorialEvent:FireClient(player, "SpawnVillageHeadman")

	end

	isSleepingTransition = false
end)