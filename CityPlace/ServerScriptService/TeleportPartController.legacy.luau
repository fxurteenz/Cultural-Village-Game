local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TeleportFunction = (ServerStorage:WaitForChild("BindableFunction")):WaitForChild("TeleportFunction")
local TELEPORT_PART_TAG = "TeleportPart"
local DEBOUNCE_SECONDS = 15
local playerDebounces = {}

local function onPartTouched(part, hit)
	local character = hit.Parent
	if not character then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	if playerDebounces[player] then
		return
	end

	local targetPlaceId = part:GetAttribute("TargetPlaceId")
	if not targetPlaceId then
		warn("Teleport part '" .. part:GetFullName() .. "' ไม่มี Attribute 'targetPlace'")
		return
	end

	playerDebounces[player] = true

	local success, result = pcall(function()
		return TeleportFunction:Invoke(player, targetPlaceId)
	end)
    print(success,result)
	if not success or (not result) then
		warn("%s ไม่สามารถวาร์ปไป %s ได้", player.Name, targetPlaceId)
		playerDebounces[player] = nil
		return
	end

	task.delay(DEBOUNCE_SECONDS, function()
		playerDebounces[player] = nil
	end)
end

local function setupTeleportPart(part)
	part.Touched:Connect(function(hit)
		onPartTouched(part, hit)
	end)
end

for _, part in ipairs(CollectionService:GetTagged(TELEPORT_PART_TAG)) do
	setupTeleportPart(part)
end

(CollectionService:GetInstanceAddedSignal(TELEPORT_PART_TAG)):Connect(setupTeleportPart)
