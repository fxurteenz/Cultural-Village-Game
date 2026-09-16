local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- อ้างอิง BindableEvent
local BindableEvent = ReplicatedStorage:WaitForChild("BindableEvent")
local toggleInventoryEvent = BindableEvent:WaitForChild("ToggleInventory")
local equipHotbarEvent = BindableEvent:WaitForChild("EquipHotbar")
local toggleQuestEvent = BindableEvent:WaitForChild("ToggleQuest")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- ป้องกันตอนพิมพ์แชท

	-- จัดการกระเป๋า
	if input.KeyCode == Enum.KeyCode.Tab then
		toggleInventoryEvent:Fire()
	end
	
	if input.KeyCode == Enum.KeyCode.Y then 
		toggleQuestEvent:Fire()
	end

	-- จัดการ Hotbar (1-5)
	if input.KeyCode == Enum.KeyCode.One then
		equipHotbarEvent:Fire(1)
	elseif input.KeyCode == Enum.KeyCode.Two then
		equipHotbarEvent:Fire(2)
	elseif input.KeyCode == Enum.KeyCode.Three then
		equipHotbarEvent:Fire(3)
	elseif input.KeyCode == Enum.KeyCode.Four then
		equipHotbarEvent:Fire(4)
	elseif input.KeyCode == Enum.KeyCode.Five then
		equipHotbarEvent:Fire(5)
	end
	
	

	-- ในอนาคตถ้ามีระบบอื่น เช่น พุ่งตัว, เปิดแผนที่ ก็เอามาใส่รวมที่ไฟล์นี้ได้เลย!
end)