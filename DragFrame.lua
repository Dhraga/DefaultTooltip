local _, addon = ...
local dragFrame = addon:NewModule("DragFrame")

dragFrame.frame = DefaultTooltip_DragFrame

local function setPosition()
	local position = addon.db.profile.position
	if position then
		local point, relpoint, x, y = unpack(position)
		dragFrame.frame:ClearAllPoints()
		dragFrame.frame:SetPoint(point, UIParent, relpoint, x, y)
	end
end

function dragFrame:OnInitialize()
	addon.db.RegisterCallback(addon, "OnProfileChanged", setPosition)
	addon.db.RegisterCallback(addon, "OnProfileCopied", setPosition)
	addon.db.RegisterCallback(addon, "OnProfileReset", setPosition)
	
	setPosition()

	SLASH_DEFAULTTOOLTIP1 = "/dtt"
	SlashCmdList["DEFAULTTOOLTIP"] = function(input)
		if dragFrame.frame:IsVisible() then
			dragFrame.frame:Hide()
		else
			dragFrame.frame:Show()
		end
	end
end

dragFrame.frame:RegisterForDrag("LeftButton") 
dragFrame.frame:SetScript("OnDragStart", function(self, button)
	if button == "LeftButton" then
		self:StartMoving()
	end
end)

dragFrame.frame:SetScript("OnDragStop", function(self)
	if not addon.db.profile.position then
		addon.db.profile.position = { }
	end
	local point, _, relpoint, x, y = self:GetPoint()
	addon.db.profile.position = { point, relpoint, x, y }
	self:StopMovingOrSizing()
end)