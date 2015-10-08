local addonName, addon = ...
local options = addon:NewModule("Options")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

LibStub("Libra"):EmbedWidgets(options)

function options:OnInitialize()
	local options = self:CreateOptionsFrame(addon.name)
	options:SetDescription(GetAddOnMetadata(addonName, "Notes"))
	
	local profiles = options:AddSubCategory(L["Profiles"])
    profiles:SetDescription(L["You can change the active database profile, so you can have different settings for every character."])

    local frame = LibStub("Libra"):CreateAceDBControls(addon.db, profiles)
    
    frame:SetPoint("TOP", -100, -100);

	options:SetupControls()
end