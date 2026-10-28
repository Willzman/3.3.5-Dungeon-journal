-- Instance page: header, boss list, loot (per mode) and the Atlas map tab.
local DJ = DungeonJournal
local L = DJ.L

local page = CreateFrame("Frame")
DJ.RegisterPage("instance", page)

local LEFT_W = 262

------------------------------------------------------------------------
-- Boss models. Bosses with a known creature display use SetDisplayInfo;
-- the others use SetCreature, which needs the creature in the client cache.
------------------------------------------------------------------------
function DJ.SetBossModel(model, boss, portrait)
    model.boss = boss
    model:ClearModel()
    if model.fallback then model.fallback:Hide() end
    local ok = false
    if boss.display and model.SetDisplayInfo then
        ok = pcall(model.SetDisplayInfo, model, boss.display)
    end
    if not ok and boss.npc then
        ok = pcall(model.SetCreature, model, boss.npc)
    end
    if portrait and model.SetCamera then pcall(model.SetCamera, model, 0) end
    if not ok then
        if model.fallback then model.fallback:Show() end
        return
    end
    -- Show the fallback icon if nothing loaded (creature not cached yet).
    DJ.After(0.4, function()
        if model.boss ~= boss or not model.fallback then return end
        local m = model:GetModel()
        if type(m) ~= "string" or m == "" then model.fallback:Show() end
    end)
end

local function BossIcon(boss)
    if boss.trash then return "Interface\\Icons\\INV_Misc_Bag_09" end
    if boss.extra then return "Interface\\Icons\\INV_Box_01" end
    return "Interface\\Icons\\INV_Misc_Bone_HumanSkull_02"
end

------------------------------------------------------------------------
-- Header
------------------------------------------------------------------------
local header = DJ.Panel(page, "header", "border")
header:SetPoint("TOPLEFT")
header:SetPoint("TOPRIGHT")
header:SetHeight(78)

local art = header:CreateTexture(nil, "ARTWORK")
DJ.Size(art, 150, 70)
art:SetPoint("LEFT", 4, 0)
local artIcon = header:CreateTexture(nil, "ARTWORK")
DJ.Size(artIcon, 54, 54)
artIcon:SetPoint("CENTER", art, "CENTER")
artIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local nameText = DJ.Text(header, "GameFontNormalLarge", 18)
nameText:SetPoint("TOPLEFT", art, "TOPRIGHT", 12, -4)
local infoText = DJ.Text(header, "GameFontHighlight", 11)
infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
local descText = DJ.Text(header, "GameFontHighlightSmall", 11)
descText:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -4)
descText:SetPoint("RIGHT", -210, 0)
descText:SetHeight(26)
descText:SetJustifyV("TOP")

local mapTab = DJ.Button(header, L.MAP, 90, 26, function() page:SetTab("map") end)
mapTab:SetPoint("BOTTOMRIGHT", -8, 8)
local lootTab = DJ.Button(header, L.BOSSES, 90, 26, function() page:SetTab("loot") end)
lootTab:SetPoint("RIGHT", mapTab, "LEFT", -4, 0)

local mapIcon = mapTab:CreateTexture(nil, "OVERLAY")
DJ.Size(mapIcon, 18, 18)
mapIcon:SetPoint("LEFT", 6, 0)
mapIcon:SetTexture("Interface\\Icons\\INV_Scroll_03")
mapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local lootIcon = lootTab:CreateTexture(nil, "OVERLAY")
DJ.Size(lootIcon, 18, 18)
lootIcon:SetPoint("LEFT", 6, 0)
lootIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_11")
lootIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

header.OnTheme = function(_, t)
    nameText:SetTextColor(t.title[1], t.title[2], t.title[3])
    infoText:SetTextColor(t.text[1], t.text[2], t.text[3])
    descText:SetTextColor(t.muted[1], t.muted[2], t.muted[3])
end

------------------------------------------------------------------------
-- Left column: boss list (loot tab) or map key (map tab)
------------------------------------------------------------------------
local left = DJ.Panel(page, "left", "border")
left:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
left:SetPoint("BOTTOMLEFT")
left:SetWidth(LEFT_W)

local function BossRow_OnClick(self)
    if self.boss then page:SelectBoss(self.boss.index) end
end

local function CreateBossRow(list)
    local row = CreateFrame("Button", nil, list)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    row.portraitBg = row:CreateTexture(nil, "BACKGROUND")
    row.portraitBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    row.portraitBg:SetVertexColor(0, 0, 0, 0.6)
    DJ.Size(row.portraitBg, 38, 38)
    row.portraitBg:SetPoint("LEFT", 4, 0)
    row.model = CreateFrame("PlayerModel", nil, row)
    row.model:SetAllPoints(row.portraitBg)
    row.model.fallback = row:CreateTexture(nil, "ARTWORK")
    row.model.fallback:SetAllPoints(row.portraitBg)
    row.model.fallback:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetAllPoints(row.portraitBg)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.name = DJ.Text(row, "GameFontNormal", 12)
    row.name:SetPoint("TOPLEFT", row.portraitBg, "TOPRIGHT", 8, -3)
    row.name:SetPoint("RIGHT", -18, 0)
    row.name:SetHeight(15)
    row.sub = DJ.Text(row, "GameFontHighlightSmall", 10)
    row.sub:SetPoint("BOTTOMLEFT", row.portraitBg, "BOTTOMRIGHT", 8, 3)
    row.sub:SetPoint("RIGHT", -18, 0)
    row.arrow = row:CreateTexture(nil, "OVERLAY")
    DJ.Size(row.arrow, 14, 14)
    row.arrow:SetPoint("RIGHT", -4, 0)
    row.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Buttons\\WHITE8X8")
    hl:SetPoint("TOPLEFT", 1, -1)
    hl:SetPoint("BOTTOMRIGHT", -1, 1)
    hl:SetVertexColor(1, 1, 1, 0.07)
    row:SetScript("OnClick", BossRow_OnClick)
    return row
end

local function UpdateBossRow(row, boss)
    local t = DJ.theme
    row.boss = boss
    local selected = page.boss == boss
    local bg = selected and t.rowSelected or t.row
    row:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    row:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], selected and 1 or 0.35)
    row.name:SetText(DJ.BossName(boss))
    local c = selected and t.title or t.text
    row.name:SetTextColor(c[1], c[2], c[3])
    local sub
    if boss.trash then
        sub = ""
    elseif boss.extra then
        sub = ""
    elseif boss.level == -1 then
        sub = L.BOSS_LEVEL_SKULL
    elseif boss.level then
        sub = string.format(L.BOSS_LEVEL, boss.level)
    else
        sub = ""
    end
    if boss.rare then sub = sub .. "  |cffc0c0ff" .. L.RARE .. "|r" end
    local modes = {}
    for _, m in ipairs(page.inst.modes) do
        if boss.loot[m] and #page.inst.modes > 1 and m ~= page.mode then modes[#modes + 1] = m end
    end
    if not boss.loot[page.mode] then sub = sub .. "  |cff808080(" .. L.NO_LOOT .. ")|r" end
    row.sub:SetText(sub)
    row.sub:SetTextColor(t.muted[1], t.muted[2], t.muted[3])
    if boss.npc or boss.display then
        row.icon:Hide()
        row.model.fallback:SetTexture(BossIcon(boss))
        row.model:Show()
        if row.model.boss ~= boss then DJ.SetBossModel(row.model, boss, true) end
    else
        row.model:Hide()
        row.model.fallback:Hide()
        row.icon:SetTexture(BossIcon(boss))
        row.icon:Show()
    end
    if selected then row.arrow:Show() else row.arrow:Hide() end
end

local bossList = DJ.ScrollList(left, { rowHeight = 46, spacing = 3, createRow = CreateBossRow, updateRow = UpdateBossRow })
bossList:SetPoint("TOPLEFT", 6, -6)
bossList:SetPoint("BOTTOMRIGHT", -4, 6)

-- Map key lines
local function CreateLegendRow(list)
    local row = CreateFrame("Frame", nil, list)
    row.text = DJ.Text(row, "GameFontHighlightSmall", 11)
    row.text:SetAllPoints()
    return row
end
local function UpdateLegendRow(row, line)
    row.text:SetText(line)
end
local legendList = DJ.ScrollList(left, { rowHeight = 15, spacing = 1, createRow = CreateLegendRow, updateRow = UpdateLegendRow })
legendList:SetPoint("TOPLEFT", 8, -30)
legendList:SetPoint("BOTTOMRIGHT", -4, 6)
local legendTitle = DJ.Text(left, "GameFontNormal", 13)
legendTitle:SetPoint("TOPLEFT", 8, -8)
legendTitle:SetText(L.MAP_LEGEND)
left.OnTheme = function(_, t) legendTitle:SetTextColor(t.title[1], t.title[2], t.title[3]) end

------------------------------------------------------------------------
-- Right column: loot tab
------------------------------------------------------------------------
local right = DJ.Panel(page, "right", "border")
right:SetPoint("TOPLEFT", left, "TOPRIGHT", 6, 0)
right:SetPoint("BOTTOMRIGHT")

local lootPane = CreateFrame("Frame", nil, right)
lootPane:SetAllPoints()

local bossHeader = DJ.Panel(lootPane, "header", "border")
bossHeader:SetPoint("TOPLEFT", 6, -6)
bossHeader:SetPoint("TOPRIGHT", -6, -6)
bossHeader:SetHeight(92)

local bigModelBg = bossHeader:CreateTexture(nil, "BACKGROUND")
bigModelBg:SetTexture("Interface\\Buttons\\WHITE8X8")
bigModelBg:SetVertexColor(0, 0, 0, 0.45)
DJ.Size(bigModelBg, 84, 84)
bigModelBg:SetPoint("LEFT", 4, 0)
local bigModel = CreateFrame("PlayerModel", nil, bossHeader)
bigModel:SetAllPoints(bigModelBg)
bigModel.fallback = bossHeader:CreateTexture(nil, "ARTWORK")
DJ.Size(bigModel.fallback, 56, 56)
bigModel.fallback:SetPoint("CENTER", bigModelBg, "CENTER")
bigModel.fallback:SetTexCoord(0.08, 0.92, 0.08, 0.92)
bigModel:EnableMouse(true)
bigModel:SetScript("OnMouseDown", function(self) self.dragX = GetCursorPosition() end)
bigModel:SetScript("OnMouseUp", function(self) self.dragX = nil end)
bigModel:SetScript("OnUpdate", function(self)
    if self.dragX then
        local x = GetCursorPosition()
        self:SetFacing(self:GetFacing() + (x - self.dragX) / 60)
        self.dragX = x
    end
end)

local bossName = DJ.Text(bossHeader, "GameFontNormalLarge", 17)
bossName:SetPoint("TOPLEFT", bigModelBg, "TOPRIGHT", 12, -4)
bossName:SetPoint("RIGHT", -10, 0)
local bossInfo = DJ.Text(bossHeader, "GameFontHighlight", 11)
bossInfo:SetPoint("TOPLEFT", bossName, "BOTTOMLEFT", 0, -4)
bossInfo:SetPoint("RIGHT", -10, 0)
bossHeader.OnTheme = function(_, t)
    bossName:SetTextColor(t.title[1], t.title[2], t.title[3])
    bossInfo:SetTextColor(t.muted[1], t.muted[2], t.muted[3])
end

local modeButtons = {}
for i, m in ipairs(DJ.MODE_ORDER) do
    modeButtons[m] = DJ.Button(bossHeader, m, 84, 22, function() page:SetMode(m) end)
end

local lootList = DJ.ScrollList(lootPane, { rowHeight = 40, cols = 2, spacing = 4, createRow = DJ.CreateItemRow,
    updateRow = function(row, entry) DJ.SetItemRow(row, entry, page.boss, page.mode) end })
lootList:SetPoint("TOPLEFT", bossHeader, "BOTTOMLEFT", 0, -6)
lootList:SetPoint("BOTTOMRIGHT", -4, 6)

local emptyText = DJ.Text(lootPane, "GameFontDisable", 13, "CENTER")
emptyText:SetPoint("CENTER", lootList, "CENTER", 0, 30)

local filterNote = DJ.Text(bossHeader, "GameFontNormalSmall", 10, "RIGHT")
filterNote:SetPoint("TOPRIGHT", -8, -6)
filterNote:SetText("|cffff8040" .. L.FILTER_ACTIVE .. "|r")

------------------------------------------------------------------------
-- Right column: map tab
------------------------------------------------------------------------
local mapPane = CreateFrame("Frame", nil, right)
mapPane:SetAllPoints()
local mapButtons = {}
local mapTexture = mapPane:CreateTexture(nil, "ARTWORK")
local mapEmpty = DJ.Text(mapPane, "GameFontDisable", 13, "CENTER")
mapEmpty:SetPoint("CENTER")
mapEmpty:SetText(L.MAP_NONE)

local function LayoutMap()
    local top = (#page.inst.maps > 1) and 34 or 8
    local w, h = mapPane:GetWidth() - 16, mapPane:GetHeight() - top - 8
    local size = math.max(100, math.min(w, h))
    DJ.Size(mapTexture, size, size)
    mapTexture:ClearAllPoints()
    mapTexture:SetPoint("TOP", mapPane, "TOP", 0, -top)
end

local function ShortMapTitle(title, file)
    local tag = string.match(title, "%[(%a)%]")
    local paren = string.match(title, "%(([^)]+)%)%s*$")
    if string.find(file, "Ent$") then return "Entrance" end
    if tag and paren then return tag .. ": " .. paren end
    return paren or string.match(title, ":%s*(.+)$") or title
end

------------------------------------------------------------------------
-- Page logic
------------------------------------------------------------------------
function page:SetTab(tab)
    self.tab = tab
    lootTab:SetSelected(tab == "loot")
    mapTab:SetSelected(tab == "map")
    if tab == "map" and self.inst.maps then
        lootPane:Hide(); bossList:Hide()
        mapPane:Show(); legendList:Show(); legendTitle:Show()
        self:ShowMap(DJ.cdb.lastMap[self.inst.key] or 1)
    else
        mapPane:Hide(); legendList:Hide(); legendTitle:Hide()
        lootPane:Show(); bossList:Show()
        if tab == "map" then -- no maps: show a note instead
            lootPane:Hide(); mapPane:Show()
            mapTexture:Hide(); mapEmpty:Show()
        end
    end
end

function page:ShowMap(index)
    local maps = self.inst.maps
    if not maps or not maps[index] then index = 1 end
    DJ.cdb.lastMap[self.inst.key] = index
    local m = maps[index]
    mapEmpty:Hide()
    mapTexture:Show()
    mapTexture:SetTexture(DJ.MEDIA .. "Maps\\" .. m.file)
    for i, b in ipairs(mapButtons) do b:Hide() end
    if #maps > 1 then
        local prevButton
        for i, mp in ipairs(maps) do
            local b = mapButtons[i]
            if not b then
                b = DJ.Button(mapPane, "", 100, 22, function(self) page:ShowMap(self.index) end)
                mapButtons[i] = b
            end
            b.index = i
            b.label:SetText(ShortMapTitle(mp.title, mp.file))
            b:SetWidth(math.min(150, b.label:GetStringWidth() + 20))
            b:ClearAllPoints()
            if prevButton then b:SetPoint("LEFT", prevButton, "RIGHT", 4, 0) else b:SetPoint("TOPLEFT", 8, -6) end
            prevButton = b
            b:SetSelected(i == index)
            b:Show()
        end
    end
    LayoutMap()
    legendTitle:SetText(m.title)
    legendList:SetData(m.legend)
end

function page:SetMode(mode)
    self.mode = mode
    DJ.cdb.lastMode[self.inst.key] = mode
    for m, b in pairs(modeButtons) do b:SetSelected(m == mode) end
    bossList:Refresh()
    self:RefreshLoot()
end

function page:SelectBoss(index)
    local boss = self.inst.bosses[index] or self.bosses[1]
    self.boss = boss
    DJ.cdb.lastBoss[self.inst.key] = boss.index
    -- Jump to a mode this boss has loot for when the current one is empty.
    if not boss.loot[self.mode] then
        for _, m in ipairs(self.inst.modes) do
            if boss.loot[m] then self.mode = m; break end
        end
        for m, b in pairs(modeButtons) do b:SetSelected(m == self.mode) end
    end
    bossName:SetText(DJ.BossName(boss))
    local info = {}
    if boss.level == -1 then info[#info + 1] = L.BOSS_LEVEL_SKULL
    elseif boss.level then info[#info + 1] = string.format(L.BOSS_LEVEL, boss.level) end
    if boss.rare then info[#info + 1] = L.RARE end
    info[#info + 1] = self.inst.name
    bossInfo:SetText(table.concat(info, "  -  "))
    if boss.npc or boss.display then
        bigModel:Show()
        bigModel.fallback:SetTexture(BossIcon(boss))
        DJ.SetBossModel(bigModel, boss, false)
        bigModel:SetFacing(0.35)
    else
        bigModel:Hide()
        bigModel.fallback:SetTexture(BossIcon(boss))
        bigModel.fallback:Show()
    end
    bossList:Refresh()
    if self.tab ~= "loot" then self:SetTab("loot") end
    self:RefreshLoot()
end

function page:RefreshLoot(keepOffset)
    local boss = self.boss
    if not boss then return end
    local loot = DJ.GetLoot(boss, self.mode) or {}
    local data, filtering = {}, DJ.FilterActive()
    local pendingHeader
    for _, e in ipairs(loot) do
        if type(e) == "string" then
            pendingHeader = e
        elseif not filtering or DJ.PassesFilter(e) then
            if pendingHeader then
                -- Headers take a full line in the two-column grid.
                if #data % 2 == 1 then data[#data + 1] = false end
                data[#data + 1] = pendingHeader
                data[#data + 1] = false
                pendingHeader = nil
            end
            data[#data + 1] = e
        end
    end
    -- `false` entries are blank cells; turn them into empty strings the row hides.
    for i = 1, #data do if data[i] == false then data[i] = "" end end
    lootList:SetData(data, keepOffset)
    if #loot == 0 then
        emptyText:SetText(L.NO_LOOT)
        emptyText:Show()
    elseif #data == 0 then
        emptyText:SetText(L.FILTERED_ALL)
        emptyText:Show()
    else
        emptyText:Hide()
    end
    if filtering then filterNote:Show() else filterNote:Hide() end
end

function page:Open(state)
    local inst = state.inst
    self.inst = inst
    DJ.ApplyTheme(DJ.GetTheme(inst))
    self.bosses = DJ.VisibleBosses(inst)

    if DJ.SetCoverArt(art, inst) then
        art:Show(); artIcon:Hide()
    else
        art:Hide()
        artIcon:SetTexture(DJ.KIND_ICONS[inst.kind])
        artIcon:Show()
    end
    nameText:SetText(inst.name)
    local info = { inst.zone }
    if inst.kind == "dungeon" then
        info[#info + 1] = string.format(L.LEVELS, inst.levelRange or "?")
        if inst.minLevel then info[#info + 1] = string.format(L.MIN_LEVEL, inst.minLevel) end
    end
    info[#info + 1] = DJ.EXPANSIONS[inst.exp]
    if inst.faction then info[#info + 1] = inst.faction end
    infoText:SetText(table.concat(info, "   |cff808080-|r   "))
    descText:SetText(inst.desc or "")
    if inst.maps then mapTab:Enable() else mapTab:Disable() end

    -- Mode buttons, right-aligned under the boss name.
    local prevButton
    for _, m in ipairs(DJ.MODE_ORDER) do modeButtons[m]:Hide() end
    for i = #inst.modes, 1, -1 do
        local m = inst.modes[i]
        local b = modeButtons[m]
        b.label:SetText(DJ.ModeLabel(inst, m))
        b:ClearAllPoints()
        if prevButton then b:SetPoint("RIGHT", prevButton, "LEFT", -4, 0) else b:SetPoint("BOTTOMRIGHT", -8, 8) end
        prevButton = b
        if #inst.modes > 1 then b:Show() end
    end

    local mode = state.mode or DJ.cdb.lastMode[inst.key]
    local valid = false
    for _, m in ipairs(inst.modes) do if m == mode then valid = true end end
    self.mode = valid and mode or DJ.DefaultMode(inst)
    for m, b in pairs(modeButtons) do b:SetSelected(m == self.mode) end

    bossList:SetData(self.bosses)
    self.boss = nil
    local bossIndex = state.boss or DJ.cdb.lastBoss[inst.key] or 1
    local boss = inst.bosses[bossIndex]
    if not boss or (boss.extra and not DJ.db.showTrash) then bossIndex = self.bosses[1].index end
    self:SelectBoss(bossIndex)
    for i, b in ipairs(self.bosses) do
        if b == self.boss then bossList:ScrollTo(i) end
    end
    self:SetTab(state.tab or "loot")
end

page:SetScript("OnSizeChanged", function()
    if page.inst and page.tab == "map" and page.inst.maps then LayoutMap() end
end)

DJ.On("ITEMS_UPDATED", function()
    if page:IsShown() and page.tab == "loot" then page:RefreshLoot(true) end
end)
DJ.On("FAVOURITES_CHANGED", function()
    if page:IsShown() then lootList:Refresh() end
end)
DJ.On("FILTER_CHANGED", function()
    if page:IsShown() then page:RefreshLoot() end
end)
