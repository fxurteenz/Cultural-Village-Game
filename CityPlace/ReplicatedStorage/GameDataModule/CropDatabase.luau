local CropDatabase = {}

-- ฐานข้อมูลการเจริญเติบโตของพืช
CropDatabase.Crops = {
	["RiceSprout"] = {
		PlotTypeFolder = "FieldPlot",   -- อยู่ในโฟลเดอร์ประเภทไหน
		CropFolder = "RicePlot",        -- ชื่อโฟลเดอร์ของพืช
		MaxDays = 5,                    -- จำนวนวันที่ใช้โตเต็มที่
		HarvestItem = "HarvestedRice",           -- ชื่อไอเทมที่จะดึงเข้า Inventory เมื่อเกี่ยวสำเร็จ
		HarvestAmount = 2,              -- จำนวนที่จะได้รับ (ปรับแต่งได้ตามต้องการ)
		Stages = {
			[0] = { State = "Seedling", ModelName = "Rice_0" },
			[1] = { State = "Growing",  ModelName = "Rice_1" },
			[2] = { State = "Growing",  ModelName = "Rice_2" },
			[3] = { State = "Growing",  ModelName = "Rice_3" },
			[4] = { State = "Fruiting", ModelName = "Rice_4" },
			[5] = { State = "ReadyToHarvest", ModelName = "Rice_5" }
		}
	},

	["RiceSproutQuest"] = {
		PlotTypeFolder = "FieldPlot",   -- อยู่ในโฟลเดอร์ประเภทไหน
		CropFolder = "RicePlot",        -- ชื่อโฟลเดอร์ของพืช
		MaxDays = 5,                    -- จำนวนวันที่ใช้โตเต็มที่
		HarvestItem = "HarvestedRice",           -- ชื่อไอเทมที่จะดึงเข้า Inventory เมื่อเกี่ยวสำเร็จ
		HarvestAmount = 2,              -- จำนวนที่จะได้รับ (ปรับแต่งได้ตามต้องการ)
		Stages = {
			[0] = { State = "Seedling", ModelName = "Rice_0" },
			[1] = { State = "Growing",  ModelName = "Rice_1" },
			[2] = { State = "Growing",  ModelName = "Rice_2" },
			[3] = { State = "Growing",  ModelName = "Rice_3" },
			[4] = { State = "Fruiting", ModelName = "Rice_4" },
			[5] = { State = "ReadyToHarvest", ModelName = "Rice_5" }
		},
		SpecialEvent = {
			atStage = 5,
			eventId = "E001",
		},
		Quest = {
			{
				on = "Crop",
				action = "add_progress",
				questId = "Q001"
			},
			{
				on = "Harvest",
				action = "add_progress&submit",
				questId = "Q002"
			}
		}
	},

	--["Corn"] = {
	--	PlotTypeFolder = "NormalPlot",
	--	CropFolder = "CornPlot",
	--	MaxDays = 2,
	--	Stages = {
	--		[0] = { State = "Seedling", ModelName = "Corn_0" },
	--		[1] = { State = "Growing",  ModelName = "Corn_1" },
	--		[2] = { State = "ReadyToHarvest", ModelName = "Corn_2" }
	--	}
	--}
}

-- ฟังก์ชันเสริม (Optional) สำหรับดึงข้อมูลพืชแบบปลอดภัย
function CropDatabase.GetCropInfo(cropName)
	return CropDatabase.Crops[cropName]
end

return table.freeze(CropDatabase)