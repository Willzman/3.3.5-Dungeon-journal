-- Interface > AddOns > Dungeon Journal options page.
local DJ = DungeonJournal
local L = DJ.L

local panel = CreateFrame("Frame", "DungeonJournalOptions", UIParent)
panel.name = L.TITLE
panel:Hide()

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(L.TITLE .. "  |cff808080" .. DJ.VERSION .. "|r")
local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
sub:SetPoint("RIGHT", -16, 0)
sub:SetJustifyH("LEFT")
sub:SetText(L.HELP)

local checks = {}
local function Check(label, y, get, set)
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, y)
    local text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    text:SetText(label)
    cb.get = get
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    checks[#checks + 1] = cb
end

Check(L.OPTIONS_MINIMAP, -130, function() return DJ.db.minimap.show end, function(v)
    DJ.db.minimap.show = v
    DJ.UpdateMinimapButton()
end)
Check(L.OPTIONS_TOOLTIP, -160, function() return DJ.db.tooltipSource end, function(v) DJ.db.tooltipSource = v end)
Check(L.OPTIONS_TRASH, -190, function() return DJ.db.showTrash end, function(v) DJ.db.showTrash = v end)
Check(L.OPTIONS_AUTOOPEN, -220, function() return DJ.db.autoOpenCurrent end, function(v) DJ.db.autoOpenCurrent = v end)

local slider = CreateFrame("Slider", "DungeonJournalScaleSlider", panel, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", 24, -275)
slider:SetWidth(220)
slider:SetMinMaxValues(0.6, 1.5)
slider:SetValueStep(0.05)
_G[slider:GetName() .. "Text"]:SetText(L.OPTIONS_SCALE)
_G[slider:GetName() .. "Low"]:SetText("60%")
_G[slider:GetName() .. "High"]:SetText("150%")
slider:SetScript("OnValueChanged", function(self, v)
    if self.syncing then return end
    DJ.SetScale(v)
end)

local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
DJ.Size(reset, 180, 22)
reset:SetPoint("TOPLEFT", 20, -315)
reset:SetText(L.OPTIONS_RESET)
reset:SetScript("OnClick", function()
    DJ.ResetPosition()
    panel.refresh()
end)

local open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
DJ.Size(open, 180, 22)
open:SetPoint("LEFT", reset, "RIGHT", 10, 0)
open:SetText(L.OPTIONS_OPEN)
open:SetScript("OnClick", function()
    InterfaceOptionsFrame:Hide()
    DJ.Open()
end)

local credits = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
credits:SetPoint("BOTTOMLEFT", 16, 16)
credits:SetPoint("RIGHT", -16, 0)
credits:SetJustifyH("LEFT")
credits:SetText("Based on DungeonJournal by Exehn. Loot tables from AtlasLoot (Enhanced 5.11.04 and Classic), maps and map keys from Atlas 1.17 (GPL).")

panel.refresh = function()
    for _, cb in ipairs(checks) do cb:SetChecked(cb.get() and true or false) end
    slider.syncing = true
    slider:SetValue(DJ.db.scale or 1)
    slider.syncing = nil
end
panel:SetScript("OnShow", panel.refresh)

InterfaceOptions_AddCategory(panel)

function DJ.OpenOptions()
    -- Called twice: the first call only opens the frame on 3.3.5a.
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
end
