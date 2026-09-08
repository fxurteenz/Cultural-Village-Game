local SpecialEventDatabase = {
	E001 = {
		eventName = "CRANE_VISIT",
		eventWorldObject = {
			{ name = "Sarus", 
				path="ServerStorage/CraneModel/Sarus", 
				placePos = {x=285.77,y=65.218,z=240.739},
				attribute = {{"animTrack","idle"}}	
			},
			{name="TaInn",path="Workspace/Npc/TaInn", placePos = {x=302.1,y=66.003,z=194.8}},
			{
				name="Scarecrow",
				path="ReplicatedStorage/EventAsset/Scarecrow", 
				placePos = {x=364.6,y=101.3,z=253.3},
				attribute = {{"status","flying"},{"is_playing",true},{"highlight",true}}
			},
		},
		eventQuest = {
			questId = "QC001",
			questAction = "accept"
		}
	}
}


return SpecialEventDatabase
