-- ReplicatedStorage/GameDataModule/CraftingRecipes
local CraftingRecipes = {
	["IronSword"] = {
		ResultItem = "IronSword",
		Station = "Anvil", -- ระบุโต๊ะ/สถานที่ ที่คราฟต์ได้
		Ingredients = {
			{Name = "Wood", Amount = 2},
			{Name = "IronOre", Amount = 5}
		}
	},
	["WoodenPickaxe"] = {
		ResultItem = "WoodenPickaxe",
		Station = "Workbench", -- ระบุโต๊ะ/สถานที่ ที่คราฟต์ได้
		Ingredients = {
			{Name = "Wood", Amount = 3}
		}
	},
	["HealthPotion"] = {
		ResultItem = "HealthPotion",
		Station = "AlchemyTable",
		Ingredients = {
			{Name = "Herb", Amount = 3},
			{Name = "WaterFlask", Amount = 1}
		}
	}
}

return CraftingRecipes


