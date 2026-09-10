local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local QuestList = script.Parent.QuestFrame.QuestList
local Template = QuestList:WaitForChild("Template")
local QuestFrame = script.Parent.QuestFrame
local CloseButton  = QuestFrame.ToggleBtn

local QuestData = require(ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("QuestData"))

local GetQuestDataRF = ReplicatedStorage:WaitForChild("RemoteFunction"):WaitForChild("GetQuestData")
local QuestEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("QuestEvent")

local activePathParts = {}
local trackingQuestId = nil
local trackingConnection = nil


local function StopNavigation()
    if trackingConnection then
        trackingConnection:Disconnect()
        trackingConnection = nil
    end
    for _, part in pairs(activePathParts) do
        if part then part:Destroy() end
    end
    table.clear(activePathParts)
    trackingQuestId = nil
end

local function DrawNavigationPath(questId, targetPosition)
    if trackingQuestId == questId then
        StopNavigation()
        return
    end

    StopNavigation()
    trackingQuestId = questId

    local character = Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    if typeof(targetPosition) ~= "Vector3" then
        warn("พิกัดนำทางไม่ถูกต้อง ต้องเป็น Vector3")
        StopNavigation()
        return
    end
    
    -- ฟังก์ชันย่อยสำหรับวาดลูกศร
    local function GeneratePath()
        for _, part in pairs(activePathParts) do
            if part then part:Destroy() end
        end
        table.clear(activePathParts)

        local currentPos = character.HumanoidRootPart.Position
        local path = PathfindingService:CreatePath({
            AgentRadius = 1,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentJumpHeight = 7, 
            AgentMaxSlope = 80,
            WaypointSpacing = 2
        })

        path:ComputeAsync(currentPos, targetPosition)

        if path.Status == Enum.PathStatus.Success or path.Status == Enum.PathStatus.ClosestNoPath then
            local waypoints = path:GetWaypoints()
            
            for i = 1, #waypoints - 1 do
                local currentWP = waypoints[i]
                local nextWP = waypoints[i + 1]

                local pathNode = Instance.new("Part")
                pathNode.Size = Vector3.new(0, 0, 0)
                pathNode.Anchored = true
                pathNode.CanCollide = false
                pathNode.Transparency = 1
                
                local lookAtPosition = Vector3.new(nextWP.Position.X, currentWP.Position.Y, nextWP.Position.Z)
                local targetCFrame = CFrame.lookAt(currentWP.Position, lookAtPosition)
                
                pathNode.CFrame = targetCFrame
                
                local arrowDecal = Instance.new("Decal")
                arrowDecal.Face = Enum.NormalId.Top
                arrowDecal.Texture = "rbxassetid://6031091004"
                arrowDecal.Color3 = Color3.fromRGB(85, 255, 127)
                arrowDecal.Transparency = 1
                arrowDecal.Parent = pathNode
                
                pathNode.Parent = workspace
                table.insert(activePathParts, pathNode)

                -- เอฟเฟกต์ Pop-up และ เฟดสีลูกศร
                local appearTween = TweenService:Create(pathNode, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = Vector3.new(3, 0.1, 3),
                    CFrame = targetCFrame + Vector3.new(0, 0.2, 0)
                })
                appearTween:Play()

                TweenService:Create(arrowDecal, TweenInfo.new(0.4), {Transparency = 0}):Play()
                
                -- เอฟเฟกต์ลูกศรลอยขึ้นลง
                local floatTween = TweenService:Create(pathNode, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                    CFrame = targetCFrame + Vector3.new(0, 0.4, 0)
                })
                
                task.delay(1, function()
                    if pathNode and pathNode.Parent then
                        floatTween:Play()
                    end
                end)
            end
            
            -- มาร์คเกอร์ปลายทาง
            local lastWP = waypoints[#waypoints]
            if lastWP then
                local targetMarker = Instance.new("Part")
                targetMarker.Shape = Enum.PartType.Cylinder
                targetMarker.Size = Vector3.new(0.2, 3, 3)
                targetMarker.Anchored = true
                targetMarker.CanCollide = false
                targetMarker.Material = Enum.Material.Neon
                targetMarker.Color = Color3.fromRGB(85, 255, 127)
                targetMarker.Transparency = 1
                
                targetMarker.CFrame = CFrame.new(lastWP.Position + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
                targetMarker.Parent = workspace
                table.insert(activePathParts, targetMarker)

                TweenService:Create(targetMarker, TweenInfo.new(0.5), {Transparency = 0.3}):Play()
                TweenService:Create(targetMarker, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
                    CFrame = targetMarker.CFrame * CFrame.Angles(math.rad(180), 0, 0)
                }):Play()
            end
        else
            warn("ไม่สามารถคำนวณเส้นทางไปยังพิกัดเป้าหมายได้")
        end
    end

    -- วาดเส้นทางครั้งแรก
    GeneratePath()
    local lastCalcPos = character.HumanoidRootPart.Position
    
    trackingConnection = RunService.Heartbeat:Connect(function()
        local char = Players.LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local pos = char.HumanoidRootPart.Position

        -- ก. ตรวจสอบว่าถึงปลายทางหรือยัง (ระยะห่าง < 3 Studs) *ตัดแกน Y ออกเพื่อความแม่นยำ
        local distToTarget = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(targetPosition.X, 0, targetPosition.Z)).Magnitude
        if distToTarget <= 3 then
            StopNavigation() -- ถึงปลายทางแล้ว ปิดการนำทางอัตโนมัติ
            return
        end

        -- ข. เอฟเฟกต์เฝดลูกศรเมื่อผู้เล่นเดินผ่าน 
        for i = #activePathParts, 1, -1 do
            local part = activePathParts[i]
            if part and part.Parent then
                -- ปรับแก้: ตัดแกน Y (ความสูง) ออกจากการคำนวณ เพื่อให้ตรวจสอบการเดินเหยียบลูกศรได้แม่นยำขึ้น
                local distToArrow = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(part.Position.X, 0, part.Position.Z)).Magnitude
                if distToArrow < 6 then
                    -- เอาออกจากตารางและสั่งเล่น Tween เฟดให้โปร่งใส
                    table.remove(activePathParts, i)
                    local fadePart = TweenService:Create(part, TweenInfo.new(0.2), {Transparency = 1})
                    local decal = part:FindFirstChildOfClass("Decal")
                    if decal then
                        TweenService:Create(decal, TweenInfo.new(0.2), {Transparency = 1}):Play()
                    end
                    fadePart:Play()
                    
                    -- ทำลาย Part ทิ้งหลังจากเฝดเสร็จ
                    task.delay(0.2, function() part:Destroy() end)
                end
            end
        end

        -- ค. คำนวณเส้นทางใหม่หากผู้เล่นเดินออกนอกเส้นทาง (ห่างจากจุดคำนวณเดิมเกิน 3 Studs)
        if (lastCalcPos - pos).Magnitude > 8 then
            lastCalcPos = pos
            GeneratePath()
        end
    end)
end

local function RefreshUI(questData)
    if type(questData) ~= "table" then 
        questData = { active = {}, completed = {} }
    end

    local myActiveQuests = questData.active or {}
    local activeIds = {}

    -- 1. อัปเดตข้อมูลเควสที่ยังมีอยู่
    for questId, data in pairs(myActiveQuests) do
        activeIds[questId] = true 

        local staticInfo = QuestData[questId]
        if staticInfo then
            local existingUI = QuestList:FindFirstChild(questId)
            local targetUI

            if not existingUI then
                targetUI = Template:Clone()
                targetUI.Name = questId
                targetUI.Visible = true
                targetUI.Parent = QuestList
                
                -- ส่ง questId เพื่อใช้ในการตรวจสอบปุ่มที่กด
                targetUI.Activated:Connect(function()
                    if staticInfo.location then
                        DrawNavigationPath(questId, staticInfo.location)
                    end
                end)
            else
                targetUI = existingUI
            end

            targetUI.QuestDescription.Text = staticInfo.Name

            if data.IsCompleted then
                targetUI.QuestDescription.Text = staticInfo.ReadyToSubmitMessage or staticInfo.Description
                targetUI.QuestProgress.Text = "OK!"
                targetUI.QuestProgress.TextColor3 = Color3.fromRGB(85, 255, 127)
            else
                local progressValue = data.currentProgress or 0 
                local targetValue = staticInfo.TargetAmount or 0
                targetUI.QuestProgress.Text = progressValue .. "/" .. targetValue
                targetUI.QuestProgress.TextColor3 = Color3.fromRGB(255, 255, 255) 
            end
        end
    end

    -- 2. ลบ UI ของเควสที่ทำเสร็จแล้ว
    for _, child in pairs(QuestList:GetChildren()) do
        if child:IsA("ImageButton") and child ~= Template then
            if not activeIds[child.Name] then
                -- ถ้าระบบกำลังนำทางเควสที่ถูกลบอยู่ ให้ยกเลิกการนำทางด้วย
                if trackingQuestId == child.Name then
                    StopNavigation()
                end
                child:Destroy()
            end
        end
    end
end

-- ดึงข้อมูลครั้งแรกเมื่อเปิดเกม
task.spawn(function()
    local success, initialQuests = pcall(function() return GetQuestDataRF:InvokeServer() end)
    if success and initialQuests then
        RefreshUI(initialQuests)
    end
end)

-- รอรับสัญญาณรีเฟรชจาก Server
QuestEvent.OnClientEvent:Connect(function(signal)
    local success, latestQuests = pcall(function() 
        return GetQuestDataRF:InvokeServer() 
    end)
    if success and latestQuests then
        RefreshUI(latestQuests)
    end
end)

CloseButton.Activated:Connect(function()
    QuestFrame.Visible = false
end)