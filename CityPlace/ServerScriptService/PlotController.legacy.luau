local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local QuestManager = require(ReplicatedStorage:WaitForChild("Module"):WaitForChild("QuestModule"))
local DataManager = require(script.Parent:WaitForChild("DataManagerModule"))

local QuestNotiEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestNotiEvent")
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local ConsumeItemEvent = ServerStorage:WaitForChild("BindableEvent"):WaitForChild("ConsumeItemEvent")
local GiveItemBindable = ServerStorage:WaitForChild("BindableEvent"):WaitForChild("GiveItemBindable")
local SpecialEventTrigger = game:GetService("ServerStorage"):WaitForChild("BindableFunction"):WaitForChild("SpecialEventFunction")

local GameTimeData = ReplicatedStorage:WaitForChild("GameTimeData")
local DayValue = GameTimeData:WaitForChild("Day")

local CropDatabase = require(ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("CropDatabase"))

local CropsModelFolder = ServerStorage:WaitForChild("CropsModel")

local isPlotLoaded = false

-- ==========================================
-- ฟังก์ชันอัปเดตโมเดลของแปลง (Update Visuals)
-- ==========================================

local function UpdatePlotVisual(oldPlot)
	local cropName = oldPlot:GetAttribute("CropName")
	local daysGrown = oldPlot:GetAttribute("DaysGrown")
	local state = oldPlot:GetAttribute("State")
	local newPlotTemplate = nil

	if cropName == nil or cropName == "" then
		-- (โค้ดดึงโมเดลแปลงว่างเหมือนเดิม)
		local plotTypeFolder = nil
		if CollectionService:HasTag(oldPlot, "FieldPlot") then
			plotTypeFolder = "FieldPlot"
		elseif CollectionService:HasTag(oldPlot, "NormalPlot") then
			plotTypeFolder = "NormalPlot"
		end

		if plotTypeFolder then
			local folder = CropsModelFolder:FindFirstChild(plotTypeFolder)
			if folder then
				newPlotTemplate = folder:FindFirstChild(plotTypeFolder)
			end
		end
	else
		local cropInfo = CropDatabase.GetCropInfo(cropName)

		if cropInfo then
			if daysGrown >= cropInfo.MaxDays then
				daysGrown = cropInfo.MaxDays
			end
			
			local stateIndex = tonumber(daysGrown)

			local stageData = cropInfo.Stages[stateIndex]
			if stageData then
				local plotFolder = CropsModelFolder:FindFirstChild(cropInfo.PlotTypeFolder)
				if plotFolder then
					local cropFolder = plotFolder:FindFirstChild(cropInfo.CropFolder)
					if cropFolder then
						newPlotTemplate = cropFolder:FindFirstChild(stageData.ModelName)
						oldPlot:SetAttribute("State", stageData.State)
					end
				end
			end

			local specialEventData = cropInfo.SpecialEvent
			if specialEventData then
				local eventId = specialEventData.eventId 
				if specialEventData.atStage == stateIndex then
					local invoke_res, invoke_data = pcall(function()
						return SpecialEventTrigger:Invoke(eventId)
					end)

					if invoke_res then
						print("[PLOT_CONTROLLER] ".. tostring(invoke_data))
					else
						warn("[PLOT_CONTROLLER] ".. tostring(invoke_data))
					end
				end
			end
		end
	end

	-- ==========================================
	-- กระบวนการสลับโมเดล (ทำงานเมื่อเจอ Template ที่ถูกต้อง)
	-- ==========================================
	if newPlotTemplate then
		local newPlot = newPlotTemplate:Clone()
        print(newPlot.Name)
		newPlot:PivotTo(oldPlot:GetPivot())
		newPlot.Parent = oldPlot.Parent

		for attrName, attrValue in pairs(oldPlot:GetAttributes()) do
			newPlot:SetAttribute(attrName, attrValue)
		end

		for _, tag in ipairs(CollectionService:GetTags(oldPlot)) do
			CollectionService:AddTag(newPlot, tag)
		end

		oldPlot:Destroy()
        --print("[PLOTCONTROLLER] : updated plot visual ".. cropName.. " -> ".. newPlot:GetAttribute("CropName"))
	else
		warn("❌ ไม่พบโมเดลต้นแบบสำหรับสลับ (Crop: " .. tostring(cropName) .. ", State: " .. tostring(state) .. ")")
	end
end

-- ==========================================
-- ฟังก์ชัน setup ProximityPrompt
-- ==========================================

local function setupPlot(plot)
	local prompt = plot:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then return end

	prompt.Triggered:Connect(function(player)
		local character = player.Character
		if not character then return end

		local equippedTool = character:FindFirstChildOfClass("Tool")
		if not equippedTool then
			print("ต้องถืออุปกรณ์ก่อน!")
			return
		end

		-- ดึงประเภทของ Tool
		local toolType = equippedTool:GetAttribute("ToolType")
		if not toolType then return end
		-- ==========================================
		-- กรณีที่ 1: ถืออุปกรณ์เก็บเกี่ยว (เช่น เคียว)
		-- ==========================================
		if toolType == "Harvest" then
			if plot:GetAttribute("State") == "ReadyToHarvest" then
				local cropName = plot:GetAttribute("CropName")

				-- 1. ดึงข้อมูลพืชจาก Database
				local cropInfo = CropDatabase.GetCropInfo(cropName)

				if cropInfo and cropInfo.HarvestItem then
					local itemToGive = cropInfo.HarvestItem
					local amountToGive = cropInfo.HarvestAmount or 1 -- ถ้าไม่ได้ตั้งค่าไว้ ให้ default เป็น 1

					-- 2. มอบผลผลิตเข้ากระเป๋าผู้เล่นตามข้อมูลใน Database
					GiveItemBindable:Fire(player, itemToGive, amountToGive)
					print(player.Name .. " เกี่ยวข้าว ได้รับ " .. itemToGive .. " จำนวน " .. amountToGive .. " ชิ้น!")
				else
					warn("❌ ไม่พบข้อมูล HarvestItem สำหรับพืช: " .. tostring(cropName))
				end

				-- 3. รีเซ็ตข้อมูลแปลงกลับเป็นแปลงว่าง
				plot:SetAttribute("CropName", "")
				plot:SetAttribute("State", "Empty")
				plot:SetAttribute("DaysGrown", 0)

				-- 4. เปิด Prompt ให้พร้อมปลูกใหม่
				prompt.Enabled = true

				-- 5. สลับโมเดลกลับเป็นแปลงดินเปล่า
				UpdatePlotVisual(plot)
			else
				print("พืชยังไม่พร้อมเก็บเกี่ยว!")
			end
		elseif toolType == "Crop" then
			-- ==========================================
			-- กรณีที่ 2: ถืออุปกรณ์ปลูก (เมล็ดพันธุ์/ต้นกล้า)
			-- ==========================================
			local cropName = equippedTool:GetAttribute("CropName")
			local requiredPlot = equippedTool:GetAttribute("RequiredPlot")
			local questGoal = equippedTool:GetAttribute("QuestGoal")
			local fromQuest = equippedTool:GetAttribute("QuestId")

			if not cropName or not requiredPlot then
				print("ไอเทมที่คุณถือไม่ใช่เมล็ดพันธุ์ หรือตั้งค่าไม่ครบ!")
				return
			end

			if CollectionService:HasTag(plot, requiredPlot) and plot:GetAttribute("State") == "Empty" then
                local cropInfo = CropDatabase.Crops[cropName]
                if not cropInfo then
                    warn("[PLOTCONTROLLER] : invalid crop name ",cropName)
                    print(cropInfo)
                    return
                end

				plot:SetAttribute("CropName", cropName)
				plot:SetAttribute("DaysGrown", 0)
                plot:SetAttribute("State",cropInfo.Stages[0].State)
				prompt.Enabled = false 

				if equippedTool:GetAttribute("IsConsumable") == true then
					ConsumeItemEvent:Fire(player, equippedTool.Name, 1)
				end

				UpdatePlotVisual(plot)
				print(player.Name .. " ปลูก " .. cropName .. " สำเร็จ!")
				
				if questGoal == "CropThis" then
					if not fromQuest  then
						warn("[Plot Handler] : found `QuestGoal` atrr (%s), but undefined `FromQuest` attr.",questGoal)
						return	
					end
					
					local updateResult, updateMessage = QuestManager.AddProgress(player, fromQuest, 1)

					if updateResult then
						local questInfo = QuestManager.GetQuestInfo(fromQuest)
						QuestEvent:FireClient(player)
						if updateMessage == "ReadyToSubmit" then
							QuestNotiEvent:FireClient(player,questInfo.ReadyToSubmitMessage)
						elseif updateMessage == "Updated" then
							QuestNotiEvent:FireClient(player,questInfo.UpdatedMessage)
						end

						print("อัปเดตเควสปลูกพืชสำเร็จ!")
					end
				end
				
			elseif plot:GetAttribute("State") ~= "Empty" then
				print("แปลงนี้มีพืชปลูกอยู่แล้ว!")
			else
				print("พืชชนิดนี้ปลูกในแปลงประเภทนี้ไม่ได้!")
			end
		else
			print("ชนิดเครื่องมือไม่ตรงกับเงื่อนไข")
		end
	end)
end

local function LoadPlotsIntoWorkspace()
    local place_plots = ""
    if game.PlaceId == 75581316239066 then
        place_plots = "city"
    elseif game.PlaceId == 106832184588439 then
        place_plots = "farm"
    else
        warn("[DATAMANAGER] : syncPlotsData() unknow placeId")
        return
    end
    if not DataManager.WorldData.plots then 
        print("[PlotController] ไม่พบตาราง plots ในข้อมูลเซฟ")
        return 
    end

    local savedPlots = DataManager.WorldData.plots[place_plots]
    if not savedPlots then return end

    local allPlots = {}
    for _, plot in pairs(CollectionService:GetTagged("FieldPlot")) do 
        table.insert(allPlots, plot)
    end
    for _, plot in pairs(CollectionService:GetTagged("NormalPlot")) do 
        table.insert(allPlots, plot) 
    end

    for _, plot in pairs(allPlots) do
        local plotId = plot:GetAttribute("PlotID")
        
        if plotId and savedPlots[plotId] then
            local data = savedPlots[plotId] 

            for attrName, attrValue in pairs(data) do
                plot:SetAttribute(attrName, attrValue)
            end

            UpdatePlotVisual(plot)
        else

            setupPlot(plot)
        end
    end
    print("[PlotController] โหลดข้อมูลแปลงเพาะปลูกเสร็จสิ้น")
end

local function SyncPlotsData()
    if not DataManager.WorldData then return end
    
    if type(DataManager.WorldData.plots) ~= "table" then
        DataManager.WorldData.plots = {}
    end

    local place_plots = ""
    if game.PlaceId == 75581316239066 then
        DataManager.WorldData.plots.city = {}
        place_plots = "city"
    elseif game.PlaceId == 106832184588439 then
        DataManager.WorldData.plots.farm = {}
        place_plots = "farm"
    else
        warn("[DATAMANAGER] : syncPlotsData() unknow placeId")
        return
    end

    -- ดึงแปลงทุกประเภทมารวมกัน
    local allPlots = {}
    for _, plot in pairs(CollectionService:GetTagged("FieldPlot")) do
        table.insert(allPlots, plot)
    end
    for _, plot in pairs(CollectionService:GetTagged("NormalPlot")) do
        table.insert(allPlots, plot)
    end

    -- เก็บข้อมูล Attribute ปัจจุบันของแต่ละแปลง
    for _, plot in pairs(allPlots) do
        local plotId = plot:GetAttribute("PlotID")
        if plotId then
            DataManager.WorldData.plots[place_plots][plotId] = plot:GetAttributes()
            --print("[PLOTCONTROLLER] :".. HttpService:JSONEncode(DataManager.WorldData.plots[place_plots][plotId]))
        else
            warn("[PLOTCONTROLLER] : syncPlotsData() ไม่พบ PlotID ของแปลง")
        end
    end
    print("[PlotController] ซิงค์ข้อมูลแปลงเพาะปลูกเข้า WorldData ("..place_plots..") แล้ว")
    return true,"success"
end

-- ระบบตรวจจับการเพิ่มแปลงใหม่
CollectionService:GetInstanceAddedSignal("FieldPlot"):Connect(setupPlot)
CollectionService:GetInstanceAddedSignal("NormalPlot"):Connect(setupPlot)

-- ตรวจจับวันใหม่
DayValue.Changed:Connect(function(newDay)
	if not isPlotLoaded then return end

	print("เข้าสู่วันที่ " .. newDay .. " อัปเดตการเติบโตของพืชทั่วโลก!")

	SyncPlotsData()

	if DataManager.WorldData and DataManager.WorldData.plots then
		for placeName, placePlots in pairs(DataManager.WorldData.plots) do
			for plotId, plotData in pairs(placePlots) do
				local state = plotData.State
				local cropName = plotData.CropName

				if cropName and cropName ~= "" and state ~= "Empty" then
					local cropInfo = CropDatabase.GetCropInfo(cropName)

					if cropInfo then
						local currentDays = plotData.DaysGrown or 0

						if currentDays < cropInfo.MaxDays then
							plotData.DaysGrown = currentDays + 1
							local newState = cropInfo.Stages[plotData.DaysGrown].State
							if newState then
								plotData.State = newState
							end
						end
					end
				end
			end
		end
	end

	LoadPlotsIntoWorkspace()
end)

DataManager.WorldLoaded.Event:Connect(function()
    print("[PLOTCONTROLLER] : get World loaded event")
    LoadPlotsIntoWorkspace()
    isPlotLoaded = true
end)

DataManager.WorldSaving.OnInvoke = function()
    print("[PLOTCONTROLLER] : get World saving request event")
    return SyncPlotsData()
end

if DataManager.WorldData ~= nil then
	LoadPlotsIntoWorkspace()
	isPlotLoaded = true
end