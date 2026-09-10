-- ReplicatedStorage/QuestData
local QuestData = {
    ["QT001"] = {
        Name = "กลับไปนอนพักที่บ้าน",
        Description = "นอนพักที่เตียงนอน",
        location = Vector3.new(521.1, 76.5, 16.851),
        TargetAmount = 1,
        Rewards = {
            Coins = 0,
            Exp = 50
        }
    },
    ["QT002"] = {
        Name = "คุยกับผู้ใหญ่บ้าน",
        Description = "คุยกับผู้ใหญ่บ้านที่ศาลารอรถประจำทาง",
        location = Vector3.new(-33.4, 67.003, 54.4),
        TargetAmount = 1,
        Rewards = {
            Coins = 0,
            Exp = 50
        }
    },
    ["QT003"] = {
        Name = "ไปหาป้าสมพรที่แปลงปลูกข้าวอินทรีย์",
        Description = "คุยกับป้าสมพรที่แปลงปลูกข้าวอินทรีย์",
        location = Vector3.new(255.5, 66.003, 157.9),
        TargetAmount = 1,
        Rewards = {
            Coins = 0,
            Exp = 50
        }
    },

    ["Q001"] = {
        Name = "ทดลองปลูกข้าว",
        Description = "ปลูกข้าวที่แปลงปลูกข้าวอินทรีย์",
        location = Vector3.new(273.317, 63.224, 234.072),
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
		location = Vector3.new(273.317, 63.224, 234.072),
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
        location = Vector3.new(273.317, 63.224, 234.072),
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
