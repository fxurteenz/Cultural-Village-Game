local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EconomyService = {}

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local currencyChangedEvent
local getBalanceFunction

if RunService:IsServer() then
    currencyChangedEvent = remoteFolder:FindFirstChild("CurrencyChangedEvent") or Instance.new("RemoteEvent")
    currencyChangedEvent.Name = "CurrencyChangedEvent"
    currencyChangedEvent.Parent = remoteFolder

    getBalanceFunction = remoteFolder:FindFirstChild("GetBalanceFunction") or Instance.new("RemoteFunction")
    getBalanceFunction.Name = "GetBalanceFunction"
    getBalanceFunction.Parent = remoteFolder
else
    currencyChangedEvent = remoteFolder:WaitForChild("CurrencyChangedEvent")
    getBalanceFunction = remoteFolder:WaitForChild("GetBalanceFunction")
end

local dataManager = nil

-- Function to get the correct data manager based on the current place
local function getDataManager()
    if dataManager then
        return dataManager
    end

    -- Check which place we are in and require the corresponding manager
    -- This makes the EconomyService work in both CityPlace and MyFarm
	if game.PlaceId == 75581316239066 then -- Replace with your CityPlace PlaceId
		dataManager = require(ServerScriptService.CityDataManager)
	elseif game.PlaceId == 106832184588439 then -- Replace with your MyFarm PlaceId
        dataManager = require(ServerScriptService.FarmDataManager)
    else
        pcall(function() dataManager = require(ServerScriptService.CityDataManager) end)
        if not dataManager then
            pcall(function() dataManager = require(ServerScriptService.FarmDataManager) end)
        end
    end
    
    if not dataManager then
        warn("EconomyService: Could not find a valid DataManager for this place.")
    end

    return dataManager
end

-- ##################################################################
-- SERVER-SIDE FUNCTIONS
-- ##################################################################

if RunService:IsServer() then
    -- Set up the RemoteFunction handler
    -- This function will now wait until the player's data is loaded before returning a value.
    getBalanceFunction.OnServerInvoke = function(player)
        local manager = getDataManager()
        if not manager then return 0 end

        -- Check if data is already loaded
        if manager.PlayersData and manager.PlayersData[player.UserId] then
            return manager.PlayersData[player.UserId].coins or 0
        end

        -- If not loaded, wait for the PlayerLoaded signal from the DataManager
        manager.PlayerLoaded.Event:Wait()
        return EconomyService:GetBalance(player) -- Now the data should be available
    end

    -- Get player's data from the loaded data manager cache
    local function getPlayerData(player)
        local manager = getDataManager()
        if not manager or not manager.PlayersData then
            return nil
        end
        return manager.PlayersData[player.UserId]
    end
    
    -- Function to get the current balance of a player
    function EconomyService:GetBalance(player)
        local playerData = getPlayerData(player)
		if playerData then
            return playerData.coins or 0
        end
        return 0
    end

    -- Function to add balance to a player
    function EconomyService:AddBalance(player, amount)
        if amount <= 0 then return end
        
        local playerData = getPlayerData(player)
        if playerData then
            playerData.coins = (playerData.coins or 0) + amount
            EconomyService:UpdateCurrency(player, playerData.coins)
            print(("[Economy] Added %d coins to %s. New balance: %d"):format(amount, player.Name, playerData.coins))
        end
    end

    -- Function to send a currency update to a specific client
    function EconomyService:UpdateCurrency(player, newBalance)
        if not player or not player:IsA("Player") then return end
        currencyChangedEvent:FireClient(player, newBalance)
        print(("[Economy] Sent balance update to %s. New balance: %d"):format(player.Name, newBalance))
    end

    -- Function to remove balance from a player
    -- Returns true if the transaction was successful, false otherwise
    function EconomyService:RemoveBalance(player, amount)
        if amount <= 0 then return true end

        local playerData = getPlayerData(player)
        if playerData and (playerData.coins or 0) >= amount then
            playerData.coins = playerData.coins - amount
            EconomyService:UpdateCurrency(player, playerData.coins)
            print(("[Economy] Removed %d coins from %s. New balance: %d"):format(amount, player.Name, playerData.coins))
            return true
        else
            print(("[Economy] Failed to remove %d coins from %s. Insufficient funds."):format(amount, player.Name))
            return false
        end
    end
    
end

-- ##################################################################
-- CLIENT-SIDE FUNCTIONS
-- ##################################################################

if RunService:IsClient() then
    -- Function for the client to request its own current balance from the server
    function EconomyService:RequestInitialBalance()
        print("[Economy] Requesting initial balance from server...")
        return getBalanceFunction:InvokeServer()
    end

    -- Function to listen for currency changes and update a UI element
    function EconomyService:ListenForCurrencyChanges(callback)
        if not (type(callback) == "function") then
            warn("EconomyService:ListenForCurrencyChanges requires a function as an argument.")
            return
        end
        
        -- Connect the callback to the remote event
        currencyChangedEvent.OnClientEvent:Connect(callback)
    end

end

return EconomyService
