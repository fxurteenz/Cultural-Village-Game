local SpecialEventManager = {};
function SpecialEventManager.CRANE_VISIT(position, animationName, questId)
	print("--------------------------------------------------");
	print("[EventHandler] กำลังรันเหตุการณ์: นกกระเรียนลงนา");
	local ModelDir = (game:GetService("ServerStorage")):WaitForChild("CraneModel");
	local craneModel = (ModelDir:FindFirstChild("Sarus")):Clone();
	if craneModel then
		craneModel:SetPrimaryPartCFrame(CFrame.new(position));
		craneModel:SetAttribute("animTrack", animationName or "idle");
		craneModel.Parent = workspace;
    else
        return false,"ผิดพลาด หาโมเดลนกไม่พบ";
	end;
	print("[EventHandler] จบการทำงานเหตุการณ์นกกระเรียนลงนา");
	print("--------------------------------------------------");
	return true,"สำเร็จ! จัดการนกกระเรียนเรียบร้อยแล้ว";
end;
function SpecialEventManager.SUMMER_FESTIVAL()
	print("[EventHandler] เริ่มเทศกาลฤดูร้อน!");
	return "สำเร็จ! โหลดงานเทศกาลฤดูร้อนแล้ว";
end;
return SpecialEventManager;
