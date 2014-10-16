--[[
	Copyright (c) 2014 Eyal Shilony <Lynxium>

	Permission is hereby granted, free of charge, to any person obtaining
	a copy of this software and associated documentation files (the
	"Software"), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

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