local QuestManager = {}
local QuestData = require(game.ReplicatedStorage:WaitForChild("GameDataModule"):WaitForChild("QuestData"))

local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService:WaitForChild("FarmDataManager"))

-- ==========================================
-- 1. ฟังก์ชันรับเควส
-- ==========================================
function QuestManager.AcceptQuest(player, questId)
    local questInfo = QuestData[questId]
    if not questInfo then return false, "ไม่พบข้อมูลเควสนี้" end

    -- 🌟 2. ดึงกระเป๋าข้อมูลผู้เล่นมาจาก DataManager
    local pData = DataManager.PlayersData[player.UserId]
    if not pData then return false, "ระบบยังโหลดข้อมูลผู้เล่นไม่เสร็จ" end

    -- เช็คว่าเคยทำเสร็จแล้วหรือยัง
    if pData.quests.completed[questId] then
        return false, "คุณเคยทำเควสนี้เสร็จไปแล้ว"
    end

    -- เช็คว่ากำลังทำอยู่หรือไม่
    if pData.quests.active[questId] then
        return false, "คุณกำลังทำเควสนี้อยู่"
    end

    local playerTargets = nil
    if questInfo.Target then
        playerTargets = {}
        for targetName, status in pairs(questInfo.Target) do
            playerTargets[targetName] = status
        end
    end

    -- 🌟 3. บันทึกเควสลง DataManager
    pData.quests.active[questId] = {
        ["currentProgress"] = 0,
        ["IsCompleted"] = false,
        ["TargetsStatus"] = playerTargets
    }

    print("✅ ผู้เล่น " .. player.Name .. " รับเควส " .. questId .. " แล้ว (บันทึกลง DataStore)")
    return true, "รับเควสสำเร็จ"
end

-- ==========================================
-- 2. ฟังก์ชันอัปเดตความคืบหน้า
-- ==========================================
function QuestManager.AddProgress(player, questId, amount, targetName)
    local pData = DataManager.PlayersData[player.UserId]
    if not pData then return false, "ไม่มีข้อมูลผู้เล่น" end

    local activeQuest = pData.quests.active[questId]

    if activeQuest and not activeQuest.IsCompleted then
        local questInfo = QuestData[questId]

        if activeQuest.TargetsStatus then
            if not targetName then return false, "ข้อมูลเป้าหมายไม่ครบถ้วน" end
            if activeQuest.TargetsStatus[targetName] == nil then return false, "เป้าหมายนี้ไม่เกี่ยวข้องกับเควส" end
            if activeQuest.TargetsStatus[targetName] == true then return false, "คุณทำเป้าหมายนี้ไปแล้ว" end

            activeQuest.TargetsStatus[targetName] = true
        end

        local targetValue = questInfo.TargetAmount
        activeQuest.currentProgress += amount

        if activeQuest.currentProgress >= targetValue then
            activeQuest.currentProgress = targetValue
            activeQuest.IsCompleted = true
            return true, "ReadyToSubmit"
        end

        return true, "Updated"
    end

    return false, "ไม่พบเควส หรือเควสนี้รอส่ง/เสร็จสิ้นไปแล้ว"
end

-- ==========================================
-- 3. ฟังก์ชันส่งเควส
-- ==========================================
function QuestManager.SubmitQuest(player, questId)
    local pData = DataManager.PlayersData[player.UserId]
    if not pData then return false, "ไม่มีข้อมูลผู้เล่น" end

    local activeQuest = pData.quests.active[questId]

    if activeQuest then
        if activeQuest.IsCompleted then
            local questInfo = QuestData[questId]
            local rewards = questInfo.Rewards

            if rewards then
                print(player.Name .. " ส่งเควส " .. questInfo.Name .. " สำเร็จ!")

                -- 🌟 ระบบแจกเงินอัตโนมัติ (เข้า DataManager)
                if rewards.Coins then
                    pData.coins = (pData.coins or 0) + rewards.Coins
                    print("ได้รับเงิน: " .. rewards.Coins)
                end

                -- 🌟 ระบบแจกไอเทมอัตโนมัติ (เข้า DataManager)
                if rewards.Items then
                    pData.player_items = pData.player_items or {}
                    for itemName, amt in pairs(rewards.Items) do
                        pData.player_items[itemName] = (pData.player_items[itemName] or 0) + amt
                        print("ได้รับไอเทม: " .. itemName .. " x" .. amt)
                    end
                end
            end

            -- 🌟 ย้ายจาก active ไป completed
            pData.quests.active[questId] = nil
            pData.quests.completed[questId] = true

            return true, "เควส " .. questInfo.Name .. " สำเร็จ"
        else
            return false, "เควสนี้ยังทำเป้าหมายไม่ครบ"
        end
    end

    return false, "ไม่พบเควสนี้ในระบบ (อาจจะส่งไปแล้ว)"
end

-- ==========================================
-- 4. ฟังก์ชัน Get ข้อมูลสำหรับ UI และ Dialog (Client)
-- ==========================================
function QuestManager.GetPlayerQuests(player)
    local pData = DataManager.PlayersData[player.UserId]
    return (pData and pData.quests.active) or {}
end

function QuestManager.GetCompletedQuests(player)
    local pData = DataManager.PlayersData[player.UserId]
    return (pData and pData.quests.completed) or {}
end

function QuestManager.GetAllQuestData(player)
    local pData = DataManager.PlayersData[player.UserId]

    -- 🌟 คืนค่าเป็นตัวพิมพ์เล็ก (active, completed) เพื่อให้ DialogScript ใช้งานได้ทันที
    if pData and pData.quests then
        return {
            active = pData.quests.active or {},
            completed = pData.quests.completed or {}
        }
    end

    return { active = {}, completed = {} }
end

function QuestManager.GetQuestInfo(questId)
    return QuestData[questId]
end

return QuestManager