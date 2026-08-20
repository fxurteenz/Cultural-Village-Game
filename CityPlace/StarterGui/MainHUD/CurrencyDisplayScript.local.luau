-- CurrencyDisplayScript.local.luau
-- Location: StarterGui/MainHUD/CurrencyDisplayScript.local.luau
-- Author: Gemini
-- Description: Updates the player's currency display on the UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ##################################################################
-- CONFIGURATION
-- ##################################################################
local playerFrame = playerGui:WaitForChild("MainHUD"):WaitForChild("DateTimeFrame"):WaitForChild("PlayerStat")
local currencyLabel = playerFrame:WaitForChild("Money")
local playerNameLabel = playerFrame:WaitForChild("PlayerName")

-- ##################################################################

-- Get the EconomyService module
local EconomyService = require(ReplicatedStorage.Module.EconomyService)

-- Function to format the number with commas (e.g., 1000 -> 1,000)
local function formatCurrency(amount)
    local s = tostring(math.floor(amount))
    local len = #s
    while len > 3 do
        s = s:sub(1, len - 3) .. "," .. s:sub(len - 2)
        len = len - 3
    end
    return s
end

-- ฟังก์ชันที่จะถูกเรียกใช้ทุกครั้งที่ค่าเงินมีการเปลี่ยนแปลง
local function onCurrencyChanged(newBalance)
    if currencyLabel then
        currencyLabel.Text = formatCurrency(newBalance) .. " G"
    end
end

playerNameLabel.Text = player.DisplayName

-- 1. Listen for future currency changes from the server (push updates)
EconomyService:ListenForCurrencyChanges(onCurrencyChanged)

-- 2. Request the initial balance from the server (pull initial state)
task.spawn(function()
    local initialBalance = EconomyService:RequestInitialBalance()
    if initialBalance ~= nil then
        onCurrencyChanged(initialBalance)
    end
end)
