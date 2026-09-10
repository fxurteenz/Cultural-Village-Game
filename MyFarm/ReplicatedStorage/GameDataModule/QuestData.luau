-- ReplicatedStorage/QuestData
local QuestData = {
    ["QT001"] = {
        Name = "กลับไปนอนพักที่บ้าน",
        Description = "นอนพักที่เตียงนอน",
        location = Vector3.new(337.188, 16.519, -151.057),
        TargetAmount = 1,
        Rewards = {
            Coins = 0,
            Exp = 50
        }
    },
    ["QT002"] = {
        Name = "คุยกับผู้ใหญ่บ้าน",
        Description = "คุยกับผู้ใหญ่บ้านที่ศาลารอรถประจำทาง",
        location = Vector3.new(405.709, 10.819, -358.904),
        TargetAmount = 1,
        Rewards = {
            Coins = 0,
            Exp = 50
        }
    },
    ["QT003"] = {
        Name = "ไปหาป้าสมพรที่แปลงปลูกข้าวอินทรีย์",
        Description = "คุยกับป้าสมพรที่แปลงปลูกข้าวอินทรีย์",
        location = "แปลงปลูกข้าวอินทรีย์",
        TargetAmount = 1,
        Rewards = {
            Coins = 0,
            Exp = 50
        }
    },

    ["Q001"] = {
        Name = "ทดลองปลูกข้าว",
        Description = "ปลูกข้าวที่แปลงปลูกข้าวอินทรีย์",
        location = "แปลงปลูกข้าวอินทรีย์",
        TargetAmount = 1,
        ReadyToSubmitMessage = "กลับไปหาป้าสมพร",
        Rewards = {
            Coins = 100,
            Exp = 50
        }
	},


	-- NOT TESTED
	["Q002"] = {
		Name = "เก็บเกี่ยวข้าว",
		Description = "เก็บเกี่ยวข้าวที่ได้จากป้าสมพร",
		location = "แปลงปลูกข้าวอินทรีย์",
		TargetAmount = 1,
		-- ReadyToSubmitMessage = "กลับไปหาป้าสมพร",
		Rewards = {
			Coins = 100,
			Exp = 50
		}
	},

    ["QC001"] = {
        Name = "ไปดูที่แปลงสาธิต",
        Description = "ไปดูที่แปลงปลูกข้าวอินทรีย์",
        location = "แปลงปลูกข้าวอินทรีย์",
        TargetAmount = 1,
        ReadyToSubmitMessage = "กลับไปหาป้าสมพร",
        Rewards = {
            Coins = 100,
            Exp = 50
        }
	},

	["QC002"] = {
		Name = "ไปที่แปลงสาธิตของป้าสมพร",
		Description = "ไปดูที่แปลงปลูกข้าวอินทรีย์",
		location = "แปลงปลูกข้าวอินทรีย์",
		TargetAmount = 1,
		ReadyToSubmitMessage = "กลับไปหาป้าสมพร",
		Rewards = {
			Coins = 100,
			Exp = 50
		}
	},

    --["Q005"] = {
    --    Name = "ไปนั่งกี่ทอผ้า",
    --    Description = "ทดลองทอผ้า",
    --    location = "บ้านหัตถกรรม",
    --    TargetAmount = 1,
    --    ReadyToSubmitMessage = "เอาผ้าที่ทอไปอวดพี่มะลิ",
    --    Rewards = {
    --        Coins = 100,
    --        Exp = 50
    --    }
    --},

    ["T001"] = {
        Name = "พูดคุยกับชาวบ้าน",
        Description = "สำรวจและพูดคุยกับชาวบ้านตามสถานที่ต่างๆในหมู่บ้าน",
        location = "หมู่บ้าน",
        TargetAmount = 5,
        Target = {
            AuntySomporn = false,
            Mali = false
			
        },
        Rewards = {
            Coins = 100,
            Exp = 50
        }
    }
}

return QuestData
