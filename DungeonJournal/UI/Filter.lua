-- Loot Filter popup: class usability, armor types, recipes and non-equippable items.
local DJ = DungeonJournal
local L = DJ.L

local pop = CreateFrame("Frame", "DungeonJournalFilter", UIParent)
DJ.Size(pop, 260, 238)
pop:SetFrameStrata("DIALOG")
pop:SetToplevel(true)
pop:EnableMouse(true)
pop:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
pop:Hide()
table.insert(UISpecialFrames, "DungeonJournalFilter")
pop.OnTheme = function(self, t)
    self:SetBackdropColor(t.frame[1], t.frame[2], t.frame[3], 0.98)
    self:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], 1)
end
table.insert(DJ.themedRegions, pop)

local title = DJ.Text(pop, "GameFontNormal", 13)
title:SetPoint("TOPLEFT", 12, -10)
title:SetText(L.LOOT_FILTER)
local close = CreateFrame("Button", nil, pop, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 0, 0)

local checks = {}
local function Changed()
    DJ.Fire("FILTER_CHANGED")
end

local function Check(label, y, x, get, set)
    local cb = CreateFrame("CheckButton", nil, pop, "UICheckButtonTemplate")
    DJ.Size(cb, 24, 24)
    cb:SetPoint("TOPLEFT", x or 10, y)
    cb.text = DJ.Text(cb, "GameFontHighlight", 11)
    cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 1)
    cb.text:SetText(label)
    cb:SetHitRectInsets(0, -cb.text:GetStringWidth() - 4, 0, 0)
    cb.get = get
    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
        Changed()
    end)
    checks[#checks + 1] = cb
    return cb
end

local f = function() return DJ.db.filter end
Check(L.FILTER_CLASS, -34, nil, function() return f().classOnly end, function(v) f().classOnly = v end)
Check(L.FILTER_RECIPES, -58, nil, function() return f().hideRecipes end, function(v) f().hideRecipes = v end)
Check(L.FILTER_NONEQUIP, -82, nil, function() return f().hideNonEquip end, function(v) f().hideNonEquip = v end)

local armorTitle = DJ.Text(pop, "GameFontNormal", 12)
armorTitle:SetPoint("TOPLEFT", 14, -114)
armorTitle:SetText(L.FILTER_ARMOR)
local armor = { { "Cloth", L.CLOTH }, { "Leather", L.LEATHER }, { "Mail", L.MAIL }, { "Plate", L.PLATE } }
for i, a in ipairs(armor) do
    local key = a[1]
    local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
    Check(a[2], -132 - line * 24, 10 + col * 120, function() return f().armor[key] end, function(v) f().armor[key] = v or nil end)
end

local reset = DJ.Button(pop, L.FILTER_RESET, 110, 22, function()
    local flt = DJ.db.filter
    flt.classOnly, flt.hideRecipes, flt.hideNonEquip = false, false, false
    wipe(flt.armor)
    pop:Sync()
    Changed()
end)
reset:SetPoint("BOTTOM", 0, 12)

function pop:Sync()
    for _, cb in ipairs(checks) do cb:SetChecked(cb.get() and true or false) end
end

pop:SetScript("OnShow", function(self)
    self:Sync()
    local t = DJ.theme
    if t then title:SetTextColor(t.title[1], t.title[2], t.title[3]) end
end)

function DJ.ToggleFilter(anchor)
    if pop:IsShown() then
        pop:Hide()
        return
    end
    pop:ClearAllPoints()
    pop:SetScale(DJ.frame:GetScale())
    if anchor then
        pop:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 4)
    else
        pop:SetPoint("CENTER")
    end
    pop:Show()
end

DJ.On("FRAME_HIDDEN", function() pop:Hide() end)
