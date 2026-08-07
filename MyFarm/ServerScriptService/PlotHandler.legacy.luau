local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local QuestManager = require(ReplicatedStorage:WaitForChild("Module"):WaitForChild("QuestModule"))

local QuestNotiEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestNotiEvent")
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")
local ConsumeItemEvent = ServerStorage:WaitForChild("BindableEvent"):WaitForChild("ConsumeItemEvent")
local GiveItemBindable = ServerStorage:WaitForChild("BindableEvent"):WaitForChild("GiveItemBindable")

local GameTimeData = ReplicatedStorage:WaitForChild("GameTimeData")
local DayValue = GameTimeData:WaitForChild("Day")

local CropDatabase = require(ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("CropDatabase"))

local CropsModelFolder = ServerStorage:WaitForChild("CropsModel")

-- ==========================================
-- ฟังก์ชันอัปเดตโมเดลของแปลง (Update Visuals)
-- ==========================================

local function UpdatePlotVisual(oldPlot)
	local cropName = oldPlot:GetAttribute("Crop")
	local daysGrown = oldPlot:GetAttribute("DaysGrown")
	local state = oldPlot:GetAttribute("State")
	local newPlotTemplate = nil

	-- ==========================================
	-- เช็คว่าแปลงว่างไหม
	-- ==========================================
	if cropName == nil or cropName == "" then
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
		-- กรณีมีพืชปลูกอยู่ (cropName ไม่เป็นค่าว่าง)
		local cropInfo = CropDatabase.GetCropInfo(cropName)

		if cropInfo then
			if daysGrown >= cropInfo.MaxDays then
				daysGrown = cropInfo.MaxDays
			end

			local stageData = cropInfo.Stages[daysGrown]

			if stageData then
				local plotFolder = CropsModelFolder:FindFirstChild(cropInfo.PlotTypeFolder)
				if plotFolder then
					local cropFolder = plotFolder:FindFirstChild(cropInfo.CropFolder)
					if cropFolder then
						newPlotTemplate = cropFolder:FindFirstChild(stageData.ModelName)

						-- อัปเดต State ให้เป็นสถานะของพืชในระยะนั้นๆ (เช่น Seedling)
						oldPlot:SetAttribute("State", stageData.State)
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

		-- 1. ย้ายตำแหน่งร่างใหม่ (ใช้ PivotTo ตามที่เราคุยกันเพื่อลาก Model มาทั้งยวง)
		newPlot:PivotTo(oldPlot:GetPivot())
		newPlot.Parent = oldPlot.Parent

		-- 2. คัดลอกข้อมูล (Attributes) ทั้งหมดจากของเก่ามาใส่ของใหม่
		for attrName, attrValue in pairs(oldPlot:GetAttributes()) do
			newPlot:SetAttribute(attrName, attrValue)
		end

		-- 3. คัดลอก Tags เพื่อให้ CollectionService ทำงานต่อเนื่อง
		for _, tag in ipairs(CollectionService:GetTags(oldPlot)) do
			CollectionService:AddTag(newPlot, tag)
		end

		-- 4. ลบก้อน Plot อันเก่าทิ้ง
		oldPlot:Destroy()
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
				local cropName = plot:GetAttribute("Crop")

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
				plot:SetAttribute("Crop", "")
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
				plot:SetAttribute("Crop", cropName)
				plot:SetAttribute("DaysGrown", 0)

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

-- ==========================================
-- วนลูป setup แปลงที่มีอยู่
-- ==========================================

for _, plot in pairs(CollectionService:GetTagged("FieldPlot")) do
	print(plot)
	setupPlot(plot)
end

for _, plot in pairs(CollectionService:GetTagged("NormalPlot")) do
	setupPlot(plot)
end

-- ระบบตรวจจับการเพิ่มแปลงใหม่
CollectionService:GetInstanceAddedSignal("FieldPlot"):Connect(setupPlot)
CollectionService:GetInstanceAddedSignal("NormalPlot"):Connect(setupPlot)

-- ตรวจจับวันใหม่
DayValue.Changed:Connect(function(newDay)
	print("เข้าสู่วันที่ " .. newDay .. " อัปเดตการเติบโตของพืช!")

	-- ดึงแปลงทุกประเภทมารวมกัน
	local allPlots = {}
	for _, plot in pairs(CollectionService:GetTagged("FieldPlot")) do
		table.insert(allPlots, plot)
	end
	for _, plot in pairs(CollectionService:GetTagged("NormalPlot")) do
		table.insert(allPlots, plot)
	end

	for _, plot in pairs(allPlots) do
		local state = plot:GetAttribute("State")
		local cropName = plot:GetAttribute("Crop")

		-- ถ้าแปลงมีการปลูกพืชอยู่ และยังไม่ถึงระยะพร้อมเก็บเกี่ยว
		if cropName and cropName ~= "" and state ~= "Empty" and state ~= "ReadyToHarvest" then

			-- เพิ่มจำนวนวันที่ปลูก +1
			local currentDays = plot:GetAttribute("DaysGrown") or 0
			plot:SetAttribute("DaysGrown", currentDays + 1)

			-- อัปเดตโมเดล
			UpdatePlotVisual(plot)
		end
	end
end)