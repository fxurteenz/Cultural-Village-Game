local QuestData = {
	QT001 = {
		Name = "กลับไปนอนพักที่ไร่",
		Description = "นอนพักที่ไร่",
		location = Vector3.new(521.1, 76.5, 16.851),
		TargetAmount = 1,
		Rewards = {
			Coins = 0,
			Exp = 50
		}
	},
	QT002 = {
		Name = "คุยกับผู้ใหญ่บ้าน",
		Description = "คุยกับผู้ใหญ่บ้านที่ศาลารอรถประจำทาง",
		location = Vector3.new(-33.4, 67.003, 54.4),
		TargetAmount = 1,
		Rewards = {
			Coins = 0,
			Exp = 50
		}
	},
	QT003 = {
		Name = "ไปหาป้าสมพรที่แปลงปลูกข้าวอินทรีย์",
		Description = "คุยกับป้าสมพรที่แปลงปลูกข้าวอินทรีย์",
		location = Vector3.new(255.5, 66.003, 157.9),
		TargetAmount = 1,
		Rewards = {
			Coins = 0,
			Exp = 50
		}
	},
	Q001 = {
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
	Q002 = {
		Name = "เก็บเกี่ยวข้าว",
		Description = "เก็บเกี่ยวข้าวที่ได้จากป้าสมพร",
		location = Vector3.new(273.317, 63.224, 234.072),
		TargetAmount = 1,
		ReadyToSubmitMessage = "กลับไปหาป้าสมพร",
		Rewards = {
			Coins = 100,
			Exp = 50
		}
	},
	Q003_1 = {
		Name = "กลับไปหาผู้ใหญ่บ้าน",
		Description = "กลับไปคุยกับผู้ใหญ่บ้าน",
		location = Vector3.new(-33.4, 67.003, 54.42),
		TargetAmount = 1,
		-- ReadyToSubmitMessage = "กลับไปหาป้าสมพร",
		Rewards = {
			Coins = 0,
			Exp = 50
		}
	},
    -- NOT TEST
    Q003_2 = {
		Name = "คุยกับพี่มะลิที่ศูนย์ฝึกวิชาชีพ",
		Description = "คุยกับพี่มะลิที่ศูนย์ฝึกวิชาชีพ",
		location = Vector3.new(-24.519, 69.605, 193.053),
		TargetAmount = 1,
		-- ReadyToSubmitMessage = "กลับไปหาป้าสมพร",
		Rewards = {
			Coins = 0,
			Exp = 50
		}
	},

    Q003_3 = {
		Name = "ทดลองทอผ้าที่กี่ทอผ้า",
		Description = "ทดลองทอผ้าที่กี่ทอผ้า",
		location = Vector3.new(-13.73, 67, 204.316),
		TargetAmount = 1,
		ReadyToSubmitMessage = "เอาผ้าที่ได้ไปให้พี่มะลิ",
		Rewards = {
			Coins = 200,
			Exp = 50
		}
	},

    Q004_1 = {
		Name = "กลับไปคุยกับผู้ใหญ่บ้าน",
		Description = "กลับไปคุยกับผู้ใหญ่บ้าน",
		location = Vector3.new(-33.4, 67.003, 54.42),
		TargetAmount = 1,
		ReadyToSubmitMessage = "เอาผ้าที่ได้ไปให้พี่มะลิ",
		Rewards = {
			Coins = 200,
			Exp = 50
		}
	},

	QC001 = {
		Name = "ตรวจสอบแปลงข้าวของป้าสมพร",
		Description = "ไปดูที่แปลงปลูกข้าวอินทรีย์",
		location = Vector3.new(273.317, 63.224, 234.072),
		TargetAmount = 1,
		ReadyToSubmitMessage = "กลับไปหาป้าสมพร",
		Rewards = {
			Coins = 100,
			Exp = 50
		}
	},
	QC002 = {
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
	T001 = {
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
};
return QuestData;