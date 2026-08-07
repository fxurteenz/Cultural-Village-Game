-- ReplicatedStorage/QuestData
local QuestData = {
    ["QT001"] = {
        Name = "กลับไปนอนพักที่บ้าน",
        Description = "นอนพักที่เตียงนอน",
        location = "บ้านของผู้เล่น",
        TargetAmount = 1,
        Rewards = {
            Coins = 0,
            Exp = 50
        }
    },
    ["QT002"] = {
        Name = "คุยกับผู้ใหญ่บ้าน",
        Description = "คุยกับผู้ใหญ่บ้านที่ศาลารอรถประจำทาง",
        location = "หมู่บ้าน",
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
        Name = "พูดคุยกับชาวบ้าน",
        Description = "สำรวจและพูดคุยกับชาวบ้านตามที่ต่างๆในหมู่บ้าน",
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
    },
    ["Q002"] = {
        Name = "ไปที่แปลงปลูกข้าวอินทรีย์",
        Description = "คุยกับน้าสมพรที่แปลงปลุกข้าวอินทรีย์",
        location = "แปลงปลูกข้าวอินทรีย์",
        TargetAmount = 1,
        Rewards = {
            Coins = 100,
            Exp = 50
        }
    },
    ["Q003"] = {
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
    ["Q004"] = {
        Name = "เก็บเกี่ยวข้าว",
        Description = "เก็บเกี่ยวผลผลิตจากข้าว",
        location = "แปลงปลูกข้าวอินทรีย์",
        TargetAmount = 1,
        ReadyToSubmitMessage = "รับรางวัลกับป้าสมพร",
        Rewards = {
            Coins = 100,
            Exp = 50
        }
    },
    ["Q005"] = {
        Name = "ไปนั่งกี่ทอผ้า",
        Description = "ทดลองทอผ้า",
        location = "บ้านหัตถกรรม",
        TargetAmount = 1,
        ReadyToSubmitMessage = "เอาผ้าที่ทอไปอวดพี่มะลิ",
        Rewards = {
            Coins = 100,
            Exp = 50
        }
    },
    ["Q006"] = {
        -- ยังไม่รู้ว่าจะรับเควสนี้ที่ไหนตอนไหน
        Name = "ฟังประวัติหมู่บ้าน",
        Description = "ไปฟังประวัติหมู่บ้านกับตาอิน",
        location = "ศาลาหมู่บ้าน",
        TargetAmount = 1,
        ReadyToSubmitMessage = "...",
        Rewards = {
            Coins = 100,
            Exp = 50
        }
    },
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
