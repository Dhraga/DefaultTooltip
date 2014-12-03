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
local dragFrame = addon:GetModule("DragFrame")

local TARGET = TARGET
local THE_TARGET_FORMAT = "|cfffed100" .. TARGET .. ":|r %s"
local PLAYER_FORMAT = "|cffffffff<You>|r"
local UNIT_NAME_FORMAT = "|cff%2x%2x%2x%s|r"
local OTHER_UNIT_NAME_FORMAT = "|cffffffff%s|r"
local PLAYER_BUSY_FORMAT = " |cff00cc00%s|r"
local ITEM_FORMAT = "Item ID: |cffffffff" 

TOOLTIP_DEBUG = false

local function setPoint(self)
	local scale = self:GetEffectiveScale()
	local x, y = GetCursorPosition()
	self:ClearAllPoints()
	self:SetPoint("BOTTOMLEFT", UIParent, x / scale + 16, (y / scale - self:GetHeight() - 16))
	if TOOLTIP_DEBUG then
		print(format("setPoint:\n self: %s\n scale: %s\n x: %s\n y: %s", self:GetName(), scale, x, y))
	end
end

local function getColoredUnitName(color, unit)
	return UNIT_NAME_FORMAT:format(color.r * 255, color.g * 255, color.b * 255, UnitName(unit))
end

local function getTargetName(unit)
	if UnitIsUnit(unit, "player") then
		return PLAYER_FORMAT
	elseif UnitIsPlayer(unit) then
		local class = select(2, UnitClass(unit))
		if class then
			local color = RAID_CLASS_COLORS[class]
			return getColoredUnitName(color, unit)
		end
	elseif UnitReaction(unit, "player") then
		local color = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
		return getColoredUnitName(color, unit)
	else
		return OTHER_UNIT_NAME_FORMAT:format(UnitName(unit))
	end
end

local numOfTargets
GameTooltip:HookScript("OnUpdate", function(self, elapsed)
	local name, unit = self:GetUnit()
	if unit then
		local lines = self:NumLines()
		-- Displays target of target
		for i = 1, lines do
			local line = _G["GameTooltipTextLeft"..i]
			local text = line:GetText()
			local unit = unit.."target"
			if text and text:find(THE_TARGET_FORMAT:format(".+")) then
				if UnitExists(unit) then
					line:SetText(THE_TARGET_FORMAT:format(getTargetName(unit)))
				else
					self:SetUnit("mouseover")
				end
				break
			elseif i == lines and UnitExists(unit) then
				self:AddLine(THE_TARGET_FORMAT:format(getTargetName(unit)))
				self:Show()
			end
		end
	end
	-- Updates the mouse position
	if TOOLTIP_DEBUG then
		print(format("OnUpdate:\n GetMouseFocus(): %s\n GetAnchorType(): %s", GetMouseFocus():GetName(), self:GetAnchorType()))
	end
	if GetMouseFocus() == WorldFrame and self:GetAnchorType() == "ANCHOR_CURSOR" then
		setPoint(self)
	end
end)

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local name, unit = self:GetUnit()
    if unit then
        local ricon = GetRaidTargetIndex(unit)
        if ricon then
            local text = GameTooltipTextLeft1:GetText()
            GameTooltipTextLeft1:SetText(("%s %s"):format(ICON_LIST[ricon].."18|t", text))
        end

        if UnitIsPlayer(unit) then
            self:AppendText(PLAYER_BUSY_FORMAT:format(UnitIsAFK(unit) and CHAT_FLAG_AFK or UnitIsDND(unit) and CHAT_FLAG_DND or not UnitIsConnected(unit) and "<DC>" or ""))
        end
    end
end)

GameTooltip:HookScript("OnTooltipSetItem", function(self)
	if self.GPInfo then return end
	
	local _, link = self:GetItem()
	if IsControlKeyDown() and link then
		local id = link:match("item:(%d+)")
		if id then
			self:AddLine(ITEM_FORMAT .. id)
		end
		self.GPInfo = true
	end
end)

GameTooltip:HookScript("OnTooltipCleared", function(self)
	self.GPInfo = nil
end)

GameTooltip:RegisterEvent("MODIFIER_STATE_CHANGED")
GameTooltip:SetScript("OnEvent", function(self, event, key, state)
	local owner = self:GetOwner()
	if owner and owner.UpdateTooltip then
		if state == 1 then
			self.RB = nil
		end
		owner:UpdateTooltip()
	end
end)

hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
	if TOOLTIP_DEBUG then
		print(format("GameTooltip_SetDefaultAnchor:\n GetMouseFocus(): %s\n tooltip: %s\n parent: %s", GetMouseFocus():GetName(), tooltip:GetName(), parent:GetName()))
	end
	if GetMouseFocus() == WorldFrame then	
		tooltip:SetOwner(parent, "ANCHOR_CURSOR")
		setPoint(tooltip)
		return
	end
	tooltip:SetOwner(parent, "ANCHOR_NONE")
	-- Anchors the tooltip to the drag frame
	local anchor = addon.db.profile.anchor
	if anchor then
		local point, relpoint, x, y = unpack(anchor)
		tooltip:SetPoint(point, dragFrame.frame, relpoint, x, y)
	end
end)

GameTooltipStatusBar.capNumericDisplay = true
GameTooltipStatusBar.forceShow = true
GameTooltipStatusBar.lockShow = 0
GameTooltipStatusBar:HookScript("OnValueChanged", function(self, value)
	self:SetStatusBarColor(0, 1, 0)
	
	if not value then
		return
	end
	
	local min, max = self:GetMinMaxValues()
	if (value < min) or (value > max) then
		return
	end
	
	-- Shows percentage on structures
	self.showPercentage = not GameTooltip:GetUnit() and max == 1
	TextStatusBar_OnValueChanged(self)
	if value == 0 then
		self.TextString:Hide()
	end
	
	value = (value - min) / (max - min)

	local r, g, b = 0, 1, 0
	if value > 0.5 then
		r, g = (1.0 - value) * 2, 1.0
	else
		r, g= 1.0, value * 2
	end

	self:SetStatusBarColor(r, g, b)
end)

local text = GameTooltipStatusBar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
text:SetPoint("CENTER")
GameTooltipStatusBar.TextString = text

do	-- "skin" tooltips with a gradient background and make the border black
	local function skinTooltip(self)
		self:SetBackdropColor(0.05, 0.05, 0.05, 0.7)
		self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	end

	local tooltips = {
		GameTooltip,
		ItemRefTooltip,
		WorldMapTooltip,
		WorldMapCompareTooltip1,
		WorldMapCompareTooltip2,
		ShoppingTooltip1,
		ShoppingTooltip2,
		ShoppingTooltip3,
		ItemRefShoppingTooltip1,
		ItemRefShoppingTooltip2,
		ItemRefShoppingTooltip3,
		FriendsTooltip,
		PartyMemberBuffTooltip,
		BoCTooltip,
		TomTomTooltip,
	}

	for i, tooltip in pairs(tooltips) do
		tooltip:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			--tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = {left = 3, right = 3, top = 3, bottom = 3}
		})
		
		tooltip:HookScript("OnShow", skinTooltip)
	end
end

do	-- Fix tooltip line padding
	local fixedTooltips = {
		"GameTooltip",
		"ItemRefTooltip",
	}
	
	local fixedScripts = {
		"OnTooltipSetItem",
		"OnTooltipSetQuest",
		"OnTooltipSetAchievement",
	}
	
	for index, tooltip in ipairs(fixedTooltips) do
		local tooltipObject = _G[tooltip]
		local lineText = tooltip.."TextLeft"
			tooltipObject:HookScript("OnShow", function(self)
				local numLines = self:NumLines()
				for line = 2, numLines do
					_G[lineText..line]:SetPoint("TOPLEFT", _G[lineText..(line - 1)], "BOTTOMLEFT", select(4, _G[lineText..line]:GetPoint(1)), -2)
				end
				local lastLine = _G[lineText..numLines]
				if not ((lastLine:GetText() and lastLine:GetText():match("%S")) or self.shownMoneyFrames) then
					lastLine:SetText()
					self:Show()
				end
			end)
	end
end