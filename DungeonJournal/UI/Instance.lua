-- Instance page: header, boss list, loot (per mode) and the Atlas map tab.
local DJ = DungeonJournal
local L = DJ.L

local page = CreateFrame("Frame")
DJ.RegisterPage("instance", page)

local LEFT_W = 262

------------------------------------------------------------------------
-- Boss portraits: Encounter Journal art bundled in Media/Bosses (2:1 images).
-- The 3.3.5a client cannot draw creature models it has not cached, so there
-- are no 3D models. Bosses without a portrait show the retail placeholder.
------------------------------------------------------------------------
local function ExtraIcon(boss)
    if boss.trash then return "Interface\\Icons\\INV_Misc_Bag_09" end
    if boss.extra then return "Interface\\Icons\\INV_Box_01" end
end

-- Fills `portrait` (2:1) or, for trash and extra pages, the square `icon`.
function DJ.SetBossPortrait(portrait, icon, boss)
    local extra = ExtraIcon(boss)
    if extra then
        portrait:Hide()
        icon:SetTexture(extra)
        icon:Show()
        return
    end
    icon:Hide()
    portrait:Show()
    local p = DJ.Portraits[boss.name]
    if type(p) == "table" then p = p[DJ.PlayerFaction()] end
    -- No portrait: retail's placeholder silhouette, as in the retail journal.
    portrait:SetTexture(DJ.MEDIA .. "Bosses\\" .. (p or "default"))
    portrait:SetTexCoord(0, 1, 0, 1)
    portrait:SetVertexColor(1, 1, 1)
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
descText:SetPoint("RIGHT", -304, 0)
descText:SetHeight(26)
descText:SetJustifyV("TOP")

local mapTab = DJ.Button(header, L.MAP, 90, 26, function() page:SetTab("map") end)
mapTab:SetPoint("BOTTOMRIGHT", -8, 8)
local lootTab = DJ.Button(header, L.BOSSES, 90, 26, function() page:SetTab("loot") end)
lootTab:SetPoint("RIGHT", mapTab, "LEFT", -4, 0)
local overviewTab = DJ.Button(header, L.OVERVIEW, 90, 26, function() page:SetTab("overview") end)
overviewTab:SetPoint("RIGHT", lootTab, "LEFT", -4, 0)

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
    row.portraitBg:SetVertexColor(0, 0, 0, 0.45)
    DJ.Size(row.portraitBg, 76, 38)
    row.portraitBg:SetPoint("LEFT", 4, 0)
    row.portrait = row:CreateTexture(nil, "ARTWORK")
    row.portrait:SetAllPoints(row.portraitBg)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    DJ.Size(row.icon, 34, 34)
    row.icon:SetPoint("CENTER", row.portraitBg, "CENTER")
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
    DJ.SetBossPortrait(row.portrait, row.icon, boss)
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
bossHeader:SetHeight(116)

local bigPortraitBg = bossHeader:CreateTexture(nil, "BACKGROUND")
bigPortraitBg:SetTexture("Interface\\Buttons\\WHITE8X8")
bigPortraitBg:SetVertexColor(0, 0, 0, 0.45)
DJ.Size(bigPortraitBg, 168, 84)
bigPortraitBg:SetPoint("TOPLEFT", 4, -4)
local bigPortrait = bossHeader:CreateTexture(nil, "ARTWORK")
bigPortrait:SetAllPoints(bigPortraitBg)
local bigIcon = bossHeader:CreateTexture(nil, "ARTWORK")
DJ.Size(bigIcon, 56, 56)
bigIcon:SetPoint("CENTER", bigPortraitBg, "CENTER")
bigIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local bossName = DJ.Text(bossHeader, "GameFontNormalLarge", 17)
bossName:SetPoint("TOPLEFT", bigPortraitBg, "TOPRIGHT", 12, -4)
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

-- Loot / Abilities switch under the boss name.
local viewButtons = {}
viewButtons.loot = DJ.Button(bossHeader, L.VIEW_LOOT, 80, 22, function() page:SetView("loot") end)
-- Own row under the boss name; the difficulty buttons get the row below (raids have four).
viewButtons.loot:SetPoint("TOPLEFT", bossInfo, "BOTTOMLEFT", 0, -8)
viewButtons.abilities = DJ.Button(bossHeader, L.VIEW_ABILITIES, 80, 22, function() page:SetView("abilities") end)
viewButtons.abilities:SetPoint("LEFT", viewButtons.loot, "RIGHT", 4, 0)
viewButtons.lore = DJ.Button(bossHeader, L.VIEW_LORE, 80, 22, function() page:SetView("lore") end)
viewButtons.lore:SetPoint("LEFT", viewButtons.abilities, "RIGHT", 4, 0)

local function Ability_OnEnter(self)
    if not self.spell then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("spell:" .. self.spell.id)
    GameTooltip:Show()
end

local function Ability_OnClick(self)
    if self.spell and IsModifiedClick("CHATLINK") then
        ChatEdit_InsertLink(GetSpellLink(self.spell.id))
    end
end

local function CreateAbilityRow(list)
    local row = CreateFrame("Button", nil, list)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    row.icon = row:CreateTexture(nil, "ARTWORK")
    DJ.Size(row.icon, 36, 36)
    row.icon:SetPoint("TOPLEFT", 6, -7)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.name = DJ.Text(row, "GameFontNormal", 13)
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 9, 0)
    row.name:SetPoint("RIGHT", -8, 0)
    row.name:SetHeight(15)
    row.desc = DJ.Text(row, "GameFontHighlightSmall", 11)
    row.desc:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    row.desc:SetPoint("BOTTOMRIGHT", -8, 5)
    row.desc:SetJustifyV("TOP")
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Buttons\\WHITE8X8")
    hl:SetPoint("TOPLEFT", 1, -1)
    hl:SetPoint("BOTTOMRIGHT", -1, 1)
    hl:SetVertexColor(1, 1, 1, 0.07)
    row:SetScript("OnEnter", Ability_OnEnter)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", Ability_OnClick)
    return row
end

local function UpdateAbilityRow(row, spell)
    local t = DJ.theme
    row.spell = spell
    row:SetBackdropColor(t.lootRow[1], t.lootRow[2], t.lootRow[3], t.lootRow[4])
    row:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], 0.35)
    row.icon:SetTexture(spell.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.name:SetText(spell.name)
    row.name:SetTextColor(t.title[1], t.title[2], t.title[3])
    row.desc:SetText(DJ.SpellDescription(spell.id) or "")
    row.desc:SetTextColor(t.text[1], t.text[2], t.text[3])
end

local abilityList = DJ.ScrollList(lootPane, { rowHeight = 62, spacing = 4, createRow = CreateAbilityRow, updateRow = UpdateAbilityRow })
abilityList:SetPoint("TOPLEFT", bossHeader, "BOTTOMLEFT", 0, -6)
abilityList:SetPoint("BOTTOMRIGHT", -4, 6)

------------------------------------------------------------------------
-- Right column: map tab. Two kinds of map:
--  * retail-style dungeon maps from the client's map patch, drawn like the
--    3.3.5a world map: 4x3 tiles of 256px showing a 1002x668 area per floor;
--  * the bundled Atlas maps (512x512, with the numbered map key).
------------------------------------------------------------------------
local mapPane = CreateFrame("Frame", nil, right)
mapPane:SetAllPoints()
local mapButtons = {}
local mapTexture = mapPane:CreateTexture(nil, "ARTWORK")
local mapEmpty = DJ.Text(mapPane, "GameFontDisable", 13, "CENTER")
mapEmpty:SetPoint("CENTER")
mapEmpty:SetText(L.MAP_NONE)

local MAP_W, MAP_H, TILE = 1002, 668, 256
local tiles = {}
for i = 1, 12 do
    tiles[i] = mapPane:CreateTexture(nil, "ARTWORK")
    local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
    -- The last column and row only partly show, as on the world map.
    tiles[i].u = col == 3 and (MAP_W - 3 * TILE) / TILE or 1
    tiles[i].v = row == 2 and (MAP_H - 2 * TILE) / TILE or 1
    tiles[i].col, tiles[i].row = col, row
    tiles[i]:SetTexCoord(0, tiles[i].u, 0, tiles[i].v)
end

local floorText = DJ.Text(mapPane, "GameFontNormal", 12, "CENTER")
local floorPrev = DJ.Button(mapPane, "<", 24, 22, function() page:ShowFloor(page.floor - 1) end)
local floorNext = DJ.Button(mapPane, ">", 24, 22, function() page:ShowFloor(page.floor + 1) end)
floorNext:SetPoint("TOPRIGHT", -8, -6)
floorText:SetPoint("RIGHT", floorNext, "LEFT", -6, 0)
floorText:SetWidth(80)
floorPrev:SetPoint("RIGHT", floorText, "LEFT", -6, 0)
mapPane.OnTheme = function(_, t) floorText:SetTextColor(t.title[1], t.title[2], t.title[3]) end
table.insert(DJ.themedRegions, mapPane)

local function TilePath(floor, i)
    local folder, base, n = floor[1], floor[2], floor[3]
    if n then return "Interface\\WorldMap\\" .. folder .. "\\" .. base .. n .. "_" .. i end
    return "Interface\\WorldMap\\" .. folder .. "\\" .. base .. i
end

-- Retail-style floors present in this client (cached per instance), or nil.
local retailCache = {}
local function RetailFloors(inst)
    local cached = retailCache[inst.key]
    if cached ~= nil then return cached or nil end
    local def = DJ.DungeonMaps and DJ.DungeonMaps[inst.key]
    local found = false
    if def then
        local list = {}
        for _, floor in ipairs(def) do
            if tiles[1]:SetTexture(TilePath(floor, 1)) then list[#list + 1] = floor end
        end
        if #list > 0 then
            found = list
            list.start = math.min(def.start or 1, #list)
        end
    end
    retailCache[inst.key] = found
    return found or nil
end

local function HideMapContent()
    mapTexture:Hide()
    for i = 1, 12 do tiles[i]:Hide() end
    floorPrev:Hide(); floorNext:Hide(); floorText:Hide()
    mapEmpty:Hide()
end

local function TopOffset()
    return (#mapButtons > 0 and mapButtons[1]:IsShown() or floorText:IsShown()) and 34 or 8
end

local function LayoutMap()
    local top = TopOffset()
    local w, h = mapPane:GetWidth() - 16, mapPane:GetHeight() - top - 8
    if page.mapKind == "retail" then
        local scale = math.min(w / MAP_W, h / MAP_H)
        local left = (mapPane:GetWidth() - MAP_W * scale) / 2
        for i = 1, 12 do
            local t = tiles[i]
            DJ.Size(t, TILE * t.u * scale, TILE * t.v * scale)
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", mapPane, "TOPLEFT", left + t.col * TILE * scale, -top - t.row * TILE * scale)
        end
    else
        local size = math.max(100, math.min(w, h))
        DJ.Size(mapTexture, size, size)
        mapTexture:ClearAllPoints()
        mapTexture:SetPoint("TOP", mapPane, "TOP", 0, -top)
    end
end

local function ShortMapTitle(title, file)
    local tag = string.match(title, "%[(%a)%]")
    local paren = string.match(title, "%(([^)]+)%)%s*$")
    if string.find(file, "Ent$") then return "Entrance" end
    if tag and paren then return tag .. ": " .. paren end
    return paren or string.match(title, ":%s*(.+)$") or title
end

------------------------------------------------------------------------
-- Right column: overview tab (instance lore from the retail Adventure Guide)
------------------------------------------------------------------------
local overviewPane = CreateFrame("Frame", nil, right)
overviewPane:SetAllPoints()
local overviewArt = overviewPane:CreateTexture(nil, "ARTWORK")
DJ.Size(overviewArt, 300, 140)
overviewArt:SetPoint("TOP", 0, -16)
local overviewTitle = DJ.Text(overviewPane, "GameFontNormalLarge", 20, "CENTER")
overviewTitle:SetPoint("TOP", overviewArt, "BOTTOM", 0, -12)
overviewTitle:SetPoint("LEFT", 20, 0)
overviewTitle:SetPoint("RIGHT", -20, 0)
local overviewInfo = DJ.Text(overviewPane, "GameFontHighlight", 12, "CENTER")
overviewInfo:SetPoint("TOP", overviewTitle, "BOTTOM", 0, -6)
overviewInfo:SetPoint("LEFT", 20, 0)
overviewInfo:SetPoint("RIGHT", -20, 0)
local overviewText = DJ.Text(overviewPane, "GameFontHighlight", 13)
overviewText:SetPoint("TOPLEFT", overviewInfo, "BOTTOMLEFT", 10, -16)
overviewText:SetPoint("BOTTOMRIGHT", -30, 16)
overviewText:SetJustifyV("TOP")
overviewPane.OnTheme = function(_, t)
    overviewTitle:SetTextColor(t.title[1], t.title[2], t.title[3])
    overviewInfo:SetTextColor(t.muted[1], t.muted[2], t.muted[3])
    overviewText:SetTextColor(t.text[1], t.text[2], t.text[3])
end
table.insert(DJ.themedRegions, overviewPane)

local function ShowOverview(inst)
    if DJ.SetCoverArt(overviewArt, inst) then overviewArt:Show() else overviewArt:Hide() end
    overviewTitle:SetText(inst.name)
    local info = { inst.zone }
    if inst.kind == "dungeon" then info[#info + 1] = string.format(L.LEVELS, inst.levelRange or "?") end
    for _, m in ipairs(inst.modes) do info[#info + 1] = DJ.ModeLabel(inst, m) end
    overviewInfo:SetText(table.concat(info, "   |cff808080-|r   "))
    overviewText:SetText(DJ.Lore.instances[inst.key] or inst.desc or "")
end

-- Boss lore (shown by the boss header's Lore button)
local bossLoreText = DJ.Text(lootPane, "GameFontHighlight", 13)
bossLoreText:SetPoint("TOPLEFT", bossHeader, "BOTTOMLEFT", 12, -16)
bossLoreText:SetPoint("BOTTOMRIGHT", -20, 16)
bossLoreText:SetJustifyV("TOP")
bossLoreText:Hide()

------------------------------------------------------------------------
-- Page logic
------------------------------------------------------------------------
function page:SetTab(tab)
    self.tab = tab
    overviewTab:SetSelected(tab == "overview")
    lootTab:SetSelected(tab == "loot")
    mapTab:SetSelected(tab == "map")
    if tab == "overview" then
        lootPane:Hide(); mapPane:Hide(); legendList:Hide(); legendTitle:Hide()
        bossList:Show()
        overviewPane:Show()
        ShowOverview(self.inst)
        return
    end
    overviewPane:Hide()
    if tab == "map" and (self.inst.maps or RetailFloors(self.inst)) then
        lootPane:Hide(); bossList:Hide()
        mapPane:Show(); legendList:Show(); legendTitle:Show()
        self:ShowMap(DJ.cdb.mapView[self.inst.key] or (RetailFloors(self.inst) and "retail") or 1)
    else
        mapPane:Hide(); legendList:Hide(); legendTitle:Hide()
        lootPane:Show(); bossList:Show()
        if tab == "map" then -- no maps: show a note instead
            lootPane:Hide(); mapPane:Show()
            HideMapContent(); mapEmpty:Show()
        end
    end
end

-- Map buttons: "Dungeon Map" (retail floors, when the patch has them), then each Atlas map.
local function UpdateMapButtons(inst, selected)
    for _, b in ipairs(mapButtons) do b:Hide() end
    local entries = {}
    if RetailFloors(inst) then entries[#entries + 1] = { "retail", L.MAP_DUNGEON } end
    for i, mp in ipairs(inst.maps or {}) do
        local label = ShortMapTitle(mp.title, mp.file)
        if #inst.maps == 1 then label = L.MAP_ATLAS end
        entries[#entries + 1] = { i, label }
    end
    if #entries < 2 then return end
    local prevButton
    for i, e in ipairs(entries) do
        local b = mapButtons[i]
        if not b then
            b = DJ.Button(mapPane, "", 100, 22, function(self) page:ShowMap(self.mapId) end)
            mapButtons[i] = b
        end
        b.mapId = e[1]
        b.label:SetText(e[2])
        b:SetWidth(math.min(120, b.label:GetStringWidth() + 16))
        b:ClearAllPoints()
        if prevButton then b:SetPoint("LEFT", prevButton, "RIGHT", 3, 0) else b:SetPoint("TOPLEFT", 8, -6) end
        prevButton = b
        b:SetSelected(e[1] == selected)
        b:Show()
    end
end

-- id: "retail" or the index of an Atlas map.
function page:ShowMap(id)
    local inst = self.inst
    local floors = RetailFloors(inst)
    if id == "retail" and not floors then id = 1 end
    if id ~= "retail" and not (inst.maps and inst.maps[id]) then id = floors and "retail" or 1 end
    DJ.cdb.mapView[inst.key] = id
    HideMapContent()
    UpdateMapButtons(inst, id)
    local legendMap = inst.maps and inst.maps[id ~= "retail" and id or 1]
    if id == "retail" then
        self.mapKind = "retail"
        self:ShowFloor(DJ.cdb.lastFloor and DJ.cdb.lastFloor[inst.key] or floors.start)
    elseif legendMap then
        self.mapKind = "atlas"
        mapTexture:SetTexture(DJ.MEDIA .. "Maps\\" .. legendMap.file)
        mapTexture:Show()
        LayoutMap()
    else
        mapEmpty:Show()
    end
    if legendMap then
        legendTitle:SetText(id == "retail" and (L.MAP_LEGEND .. " (Atlas)") or legendMap.title)
        legendList:SetData(legendMap.legend)
    else
        legendTitle:SetText(L.MAP_LEGEND)
        legendList:SetData({})
    end
end

function page:ShowFloor(n)
    local floors = RetailFloors(self.inst)
    if not floors then return end
    n = math.max(1, math.min(#floors, n or 1))
    self.floor = n
    DJ.cdb.lastFloor = DJ.cdb.lastFloor or {}
    DJ.cdb.lastFloor[self.inst.key] = n
    for i = 1, 12 do
        tiles[i]:SetTexture(TilePath(floors[n], i))
        tiles[i]:Show()
    end
    if #floors > 1 then
        floorText:SetText(string.format(L.MAP_FLOOR, n, #floors))
        floorText:Show(); floorPrev:Show(); floorNext:Show()
        if n > 1 then floorPrev:Enable() else floorPrev:Disable() end
        if n < #floors then floorNext:Enable() else floorNext:Disable() end
        DJ.StyleButton(floorPrev); DJ.StyleButton(floorNext)
    end
    LayoutMap()
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
    DJ.SetBossPortrait(bigPortrait, bigIcon, boss)
    bossList:Refresh()
    if self.tab ~= "loot" then self:SetTab("loot") end
    self:SetView(DJ.db.bossView or "loot")
end

-- "loot" or "abilities" for the selected boss.
function page:SetView(view)
    local boss = self.boss
    local abilities = boss and DJ.BossAbilities(boss) or {}
    local lore = boss and DJ.Lore.bosses[boss.instance.key .. "#" .. boss.index]
    local hasAbilities = boss and not boss.extra and #abilities > 0
    if hasAbilities then viewButtons.abilities:Enable() else viewButtons.abilities:Disable() end
    if lore then viewButtons.lore:Enable() else viewButtons.lore:Disable() end
    if (view == "abilities" and not hasAbilities) or (view == "lore" and not lore) then
        view = "loot"
    else
        DJ.db.bossView = view
    end
    self.view = view
    for v, b in pairs(viewButtons) do b:SetSelected(v == view) end
    lootList:Hide(); abilityList:Hide(); bossLoreText:Hide(); filterNote:Hide(); emptyText:Hide()
    if view == "abilities" then
        abilityList:Show()
        abilityList:SetData(abilities)
    elseif view == "lore" then
        bossLoreText:SetText(lore)
        local t = DJ.theme
        bossLoreText:SetTextColor(t.text[1], t.text[2], t.text[3])
        bossLoreText:Show()
    else
        lootList:Show()
        self:RefreshLoot()
    end
end

function page:RefreshLoot(keepOffset)
    local boss = self.boss
    if not boss or (self.view and self.view ~= "loot") then return end
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
    if inst.maps or RetailFloors(inst) then mapTab:Enable() else mapTab:Disable() end

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
    if page.inst and page.tab == "map" then LayoutMap() end
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
