local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local activeFarmsMap = MemoryStoreService:GetSortedMap("ActiveFarms")

Players.PlayerRemoving:Connect(function(player)
	pcall(function()
		activeFarmsMap:RemoveAsync(tostring(player.UserId))
	end)
end)

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		pcall(function()
			activeFarmsMap:RemoveAsync(tostring(player.UserId))
		end)
	end
end)

