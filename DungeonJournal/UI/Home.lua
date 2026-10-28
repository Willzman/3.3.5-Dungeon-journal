-- Home page: instance cards by expansion and type, plus Favourites / Loot Filter.
local DJ = DungeonJournal
local L = DJ.L

local page = CreateFrame("Frame")
DJ.RegisterPage("home", page)

local filterBar = DJ.Panel(page, "left", "border")
filterBar:SetPoint("TOPLEFT")
filterBar:SetPoint("TOPRIGHT")
filterBar:SetHeight(34)

local expButtons, kindButtons = {}, {}
local function Refresh() page:Refresh() end

local prev
for exp = 0, 2 do
    local b = DJ.Button(filterBar, DJ.EXPANSIONS[exp], exp == 2 and 170 or (exp == 1 and 150 or 90), 24, function()
        DJ.db.lastExpansion = exp
        Refresh()
    end)
    if prev then b:SetPoint("LEFT", prev, "RIGHT", 4, 0) else b:SetPoint("LEFT", 6, 0) end
    prev = b
    expButtons[exp] = b
end

local raids = DJ.Button(filterBar, L.RAIDS, 90, 24, function() DJ.db.lastKind = "raid"; Refresh() end)
raids:SetPoint("RIGHT", -6, 0)
local dungeons = DJ.Button(filterBar, L.DUNGEONS, 90, 24, function() DJ.db.lastKind = "dungeon"; Refresh() end)
dungeons:SetPoint("RIGHT", raids, "LEFT", -4, 0)
kindButtons.raid, kindButtons.dungeon = raids, dungeons

-- Bottom bar
local bottom = DJ.Panel(page, "left", "border")
bottom:SetPoint("BOTTOMLEFT")
bottom:SetPoint("BOTTOMRIGHT")
bottom:SetHeight(34)

local favButton = DJ.Button(bottom, L.FAVOURITES, 110, 24, function() DJ.ToggleFavourites() end)
favButton:SetPoint("LEFT", 6, 0)
local filterButton = DJ.Button(bottom, L.LOOT_FILTER, 110, 24, function(self) DJ.ToggleFilter(self) end)
filterButton:SetPoint("LEFT", favButton, "RIGHT", 4, 0)
page.filterButton = filterButton
local currentButton = DJ.Button(bottom, L.CURRENT, 130, 24, function()
    local inst, mode = DJ.CurrentInstance()
    if inst then DJ.OpenInstance(inst, nil, mode) else DJ.Print(L.NOT_IN_INSTANCE) end
end)
currentButton:SetPoint("LEFT", filterButton, "RIGHT", 4, 0)

local countText = DJ.Text(bottom, "GameFontHighlightSmall", 11, "RIGHT")
countText:SetPoint("RIGHT", -10, 0)
bottom.OnTheme = function(_, t) countText:SetTextColor(t.muted[1], t.muted[2], t.muted[3]) end

-- Cards ------------------------------------------------------------------
local function Card_OnClick(self)
    if self.inst then DJ.OpenInstance(self.inst) end
end

local function Card_OnEnter(self)
    self.glow:Show()
    local inst = self.inst
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(inst.name, 1, 0.82, 0)
    GameTooltip:AddLine(string.format(L.LOCATION, inst.zone), 1, 1, 1)
    if inst.desc then GameTooltip:AddLine(inst.desc, 0.8, 0.8, 0.8, true) end
    local modes = {}
    for _, m in ipairs(inst.modes) do modes[#modes + 1] = DJ.ModeLabel(inst, m) end
    GameTooltip:AddLine(table.concat(modes, ", "), 0.6, 0.8, 1)
    GameTooltip:Show()
end

local function Card_OnLeave(self)
    self.glow:Hide()
    GameTooltip:Hide()
end

local function CreateCard(list)
    local c = CreateFrame("Button", nil, list)
    c:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    c.art = c:CreateTexture(nil, "BACKGROUND", nil)
    c.art:SetPoint("TOPLEFT", 1, -1)
    c.art:SetPoint("BOTTOMRIGHT", -1, 1)
    c.fallbackIcon = c:CreateTexture(nil, "ARTWORK")
    DJ.Size(c.fallbackIcon, 40, 40)
    c.fallbackIcon:SetPoint("TOPRIGHT", -8, -8)
    c.fallbackIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    c.shade = c:CreateTexture(nil, "BORDER")
    c.shade:SetTexture("Interface\\Buttons\\WHITE8X8")
    c.shade:SetPoint("BOTTOMLEFT", 1, 1)
    c.shade:SetPoint("BOTTOMRIGHT", -1, 1)
    c.shade:SetHeight(40)
    c.shade:SetVertexColor(0, 0, 0, 0.72)
    c.name = DJ.Text(c, "GameFontNormal", 13)
    c.name:SetPoint("BOTTOMLEFT", 8, 20)
    c.name:SetPoint("RIGHT", -8, 0)
    c.name:SetHeight(16)
    c.sub = DJ.Text(c, "GameFontHighlightSmall", 10)
    c.sub:SetPoint("BOTTOMLEFT", 8, 6)
    c.sub:SetPoint("RIGHT", -8, 0)
    c.faction = c:CreateTexture(nil, "OVERLAY")
    DJ.Size(c.faction, 22, 22)
    c.faction:SetPoint("TOPLEFT", 4, -4)
    c.glow = c:CreateTexture(nil, "HIGHLIGHT")
    c.glow:SetTexture("Interface\\Buttons\\WHITE8X8")
    c.glow:SetPoint("TOPLEFT", 1, -1)
    c.glow:SetPoint("BOTTOMRIGHT", -1, 1)
    c.glow:SetVertexColor(1, 1, 1, 0.08)
    c:SetScript("OnClick", Card_OnClick)
    c:SetScript("OnEnter", Card_OnEnter)
    c:SetScript("OnLeave", Card_OnLeave)
    return c
end

local function UpdateCard(c, inst)
    c.inst = inst
    local t = DJ.GetTheme(inst)
    c:SetBackdropColor(t.content[1], t.content[2], t.content[3], 1)
    c:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], 0.9)
    if DJ.SetCoverArt(c.art, inst) then
        c.art:SetVertexColor(1, 1, 1)
        c.fallbackIcon:Hide()
    else
        c.art:SetTexture("Interface\\Buttons\\WHITE8X8")
        c.art:SetTexCoord(0, 1, 0, 1)
        c.art:SetVertexColor(t.content[1] * 1.4, t.content[2] * 1.4, t.content[3] * 1.4)
        if c.art.SetGradientAlpha then
            c.art:SetGradientAlpha("VERTICAL", t.left[1], t.left[2], t.left[3], 1, t.border[1] * 0.7, t.border[2] * 0.7, t.border[3] * 0.7, 1)
        end
        c.fallbackIcon:SetTexture(DJ.KIND_ICONS[inst.kind])
        c.fallbackIcon:Show()
    end
    c.name:SetText(inst.name)
    c.name:SetTextColor(t.title[1], t.title[2], t.title[3])
    local sub
    if inst.kind == "raid" then
        local sizes = {}
        for _, m in ipairs(inst.modes) do
            if m == "R10" then sizes[#sizes + 1] = "10" elseif m == "R25" then sizes[#sizes + 1] = "25" end
        end
        sub = (#sizes > 0 and table.concat(sizes, "/") or tostring(inst.size)) .. " players"
    else
        sub = string.format(L.LEVELS, inst.levelRange or "?")
        for _, m in ipairs(inst.modes) do
            if m == "H" then sub = sub .. "  |cffff7f3f" .. L.MODE_H .. "|r" end
        end
    end
    c.sub:SetText(sub .. "  |cff999999" .. inst.zone .. "|r")
    c.sub:SetTextColor(t.text[1], t.text[2], t.text[3])
    if inst.faction == "Alliance" then
        c.faction:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
        c.faction:SetTexCoord(0, 0.65, 0, 0.65)
        c.faction:Show()
    elseif inst.faction == "Horde" then
        c.faction:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
        c.faction:SetTexCoord(0, 0.65, 0, 0.65)
        c.faction:Show()
    else
        c.faction:Hide()
    end
end

local grid = DJ.ScrollList(page, { rowHeight = 104, cols = 4, spacing = 6, createRow = CreateCard, updateRow = UpdateCard })
grid:SetPoint("TOPLEFT", filterBar, "BOTTOMLEFT", 6, -8)
grid:SetPoint("BOTTOMRIGHT", bottom, "TOPRIGHT", -4, 8)

function page:Refresh()
    local exp, kind = DJ.db.lastExpansion, DJ.db.lastKind
    for e, b in pairs(expButtons) do b:SetSelected(e == exp) end
    for k, b in pairs(kindButtons) do b:SetSelected(k == kind) end
    local data = {}
    for _, inst in ipairs(DJ.Instances) do
        if inst.exp == exp and inst.kind == kind then data[#data + 1] = inst end
    end
    if kind == "dungeon" then
        table.sort(data, function(a, b)
            local la = tonumber(string.match(a.levelRange or "", "^(%d+)")) or a.minLevel or 0
            local lb = tonumber(string.match(b.levelRange or "", "^(%d+)")) or b.minLevel or 0
            if la ~= lb then return la < lb end
            return a.index < b.index
        end)
    end
    grid:SetData(data)
    countText:SetText(#data .. " " .. (kind == "raid" and L.RAIDS or L.DUNGEONS))
    filterButton:SetSelected(DJ.FilterActive())
end

function page:Open()
    DJ.ApplyTheme(DJ.THEMES.home)
    self:Refresh()
end

DJ.On("FILTER_CHANGED", function() if page:IsShown() then filterButton:SetSelected(DJ.FilterActive()) end end)
