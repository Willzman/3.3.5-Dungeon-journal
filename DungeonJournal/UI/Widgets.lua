-- Shared widgets: flat themed panels and buttons, a virtual scroll list and item rows.
local DJ = DungeonJournal
local L = DJ.L

local WHITE = "Interface\\Buttons\\WHITE8X8"

DJ.themedRegions = {}

-- Flat panel with a 1px border; colours are re-applied whenever the theme changes.
function DJ.Panel(parent, bgKey, borderKey)
    local f = CreateFrame("Frame", nil, parent)
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    f.bgKey, f.borderKey = bgKey or "content", borderKey or "border"
    table.insert(DJ.themedRegions, f)
    return f
end

function DJ.ApplyTheme(theme)
    DJ.theme = theme
    for _, f in ipairs(DJ.themedRegions) do
        if f.bgKey then
            local bg = theme[f.bgKey]
            f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
            local b = theme[f.borderKey]
            if f.borderKey == "none" or not b then
                f:SetBackdropBorderColor(0, 0, 0, 0)
            else
                f:SetBackdropBorderColor(b[1], b[2], b[3], f.borderAlpha or 0.8)
            end
        end
        if f.OnTheme then f:OnTheme(theme) end
    end
end

function DJ.Text(parent, template, size, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    if size then
        local font, _, flags = fs:GetFont()
        fs:SetFont(font, size, flags)
    end
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

-- Flat text button. `selected` state draws it in the selected-row colour.
function DJ.Button(parent, text, width, height, onClick)
    local b = CreateFrame("Button", nil, parent)
    DJ.Size(b, width, height or 24)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    b.label = DJ.Text(b, "GameFontNormal", 12, "CENTER")
    b.label:SetPoint("LEFT", 6, 0)
    b.label:SetPoint("RIGHT", -6, 0)
    b.label:SetText(text)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture(WHITE)
    hl:SetPoint("TOPLEFT", 1, -1)
    hl:SetPoint("BOTTOMRIGHT", -1, 1)
    hl:SetVertexColor(1, 1, 1, 0.08)
    b:SetScript("OnClick", onClick)
    b.SetSelected = function(self, sel)
        self.selected = sel
        DJ.StyleButton(self)
    end
    b.OnTheme = DJ.StyleButton
    table.insert(DJ.themedRegions, b)
    if DJ.theme then DJ.StyleButton(b) end
    return b
end

function DJ.StyleButton(b)
    local t = DJ.theme
    if not t then return end
    local bg = b.selected and t.rowSelected or t.row
    b:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    b:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], b.selected and 1 or 0.55)
    local c = b.selected and t.title or t.text
    if b:IsEnabled() == 1 or b:IsEnabled() == true then
        b.label:SetTextColor(c[1], c[2], c[3])
    else
        b.label:SetTextColor(0.45, 0.45, 0.45)
    end
end

function DJ.IconButton(parent, icon, size, tooltip, onClick)
    local b = CreateFrame("Button", nil, parent)
    DJ.Size(b, size, size)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexture(icon)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnClick", onClick)
    if tooltip then
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, 1, 1, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
    end
    return b
end

------------------------------------------------------------------------
-- Virtual scroll list: a fixed pool of rows over a data array, laid out in
-- `cols` columns. Mouse wheel and a thin scroll bar move it one line at a time.
------------------------------------------------------------------------
function DJ.ScrollList(parent, opts)
    local list = CreateFrame("Frame", nil, parent)
    list.rowHeight = opts.rowHeight
    list.cols = opts.cols or 1
    list.spacing = opts.spacing or 2
    list.createRow = opts.createRow
    list.updateRow = opts.updateRow
    list.rows = {}
    list.data = {}
    list.offset = 0
    list:EnableMouseWheel(true)

    local bar = CreateFrame("Slider", nil, list)
    bar:SetOrientation("VERTICAL")
    bar:SetWidth(8)
    bar:SetPoint("TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", 0, 0)
    bar:SetBackdrop({ bgFile = WHITE })
    bar:SetBackdropColor(0, 0, 0, 0.35)
    bar:SetThumbTexture(WHITE)
    local thumb = bar:GetThumbTexture()
    DJ.Size(thumb, 8, 30)
    bar:SetValueStep(1)
    bar:SetMinMaxValues(0, 0)
    bar:SetValue(0)
    bar:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v + 0.5)
        if v ~= list.offset then
            list.offset = v
            list:Refresh()
        end
    end)
    list.bar = bar
    list.thumb = thumb
    list.OnTheme = function(self, t)
        self.thumb:SetVertexColor(t.border[1], t.border[2], t.border[3], 0.9)
    end
    table.insert(DJ.themedRegions, list)

    list:SetScript("OnMouseWheel", function(self, delta)
        local _, max = self.bar:GetMinMaxValues()
        local v = math.max(0, math.min(max, self.offset - delta))
        self.bar:SetValue(v)
    end)
    list:SetScript("OnSizeChanged", function(self) self:Layout() end)

    function list:VisibleLines()
        return math.max(1, math.floor((self:GetHeight() + self.spacing) / (self.rowHeight + self.spacing)))
    end

    function list:Layout()
        local lines = self:VisibleLines()
        local width = self:GetWidth() - 12
        local colWidth = (width - (self.cols - 1) * 6) / self.cols
        local n = lines * self.cols
        for i = 1, n do
            local row = self.rows[i]
            if not row then
                row = self.createRow(self)
                self.rows[i] = row
            end
            local line = math.floor((i - 1) / self.cols)
            local col = (i - 1) % self.cols
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self, "TOPLEFT", col * (colWidth + 6), -line * (self.rowHeight + self.spacing))
            DJ.Size(row, colWidth, self.rowHeight)
        end
        for i = n + 1, #self.rows do self.rows[i]:Hide() end
        self.numVisible = n
        self:Refresh()
    end

    function list:SetData(data, keepOffset)
        self.data = data or {}
        if not keepOffset then self.offset = 0 end
        self:Refresh()
    end

    function list:Refresh()
        if not self.numVisible then return self:Layout() end
        local lines = self:VisibleLines()
        local totalLines = math.ceil(#self.data / self.cols)
        local maxOffset = math.max(0, totalLines - lines)
        if self.offset > maxOffset then self.offset = maxOffset end
        self.bar:SetMinMaxValues(0, maxOffset)
        self.bar:SetValue(self.offset)
        if maxOffset > 0 then
            self.bar:Show()
            local h = self.bar:GetHeight()
            DJ.Size(self.thumb, 8, math.max(24, h * lines / totalLines))
        else
            self.bar:Hide()
        end
        for i = 1, self.numVisible do
            local row = self.rows[i]
            local item = self.data[self.offset * self.cols + i]
            if item ~= nil then
                self.updateRow(row, item, self.offset * self.cols + i)
                row:Show()
            else
                row:Hide()
            end
        end
    end

    function list:ScrollTo(index)
        local line = math.floor((index - 1) / self.cols)
        local lines = self:VisibleLines()
        if line < self.offset or line >= self.offset + lines then
            self.offset = math.max(0, line - math.floor(lines / 2))
            self:Refresh()
        end
    end

    return list
end

------------------------------------------------------------------------
-- Item rows (loot pages, search results, favourites)
------------------------------------------------------------------------
local function ItemRow_OnEnter(self)
    if not self.itemID then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("item:" .. self.itemID .. ":0:0:0:0:0:0:0")
    if self.sourceText and not DJ.db.tooltipSource then
        GameTooltip:AddLine(self.sourceText, 0.6, 0.8, 1)
    end
    GameTooltip:AddLine(L.ITEM_HINT, 0.5, 0.5, 0.5)
    GameTooltip:Show()
    if IsShiftKeyDown() then GameTooltip_ShowCompareItem(GameTooltip) end
    self.hasTooltip = true
end

local function ItemRow_OnLeave(self)
    self.hasTooltip = nil
    GameTooltip:Hide()
end

local function ItemRow_OnClick(self, button)
    if not self.itemID then
        if self.onClick and button == "LeftButton" then self.onClick(self) end
        return
    end
    if button == "RightButton" then
        DJ.ToggleFavourite(self.itemID, self.boss, self.mode)
        return
    end
    if self.onClick and not IsModifiedClick() then
        self.onClick(self)
        return
    end
    local link = DJ.ItemLink(self.itemID)
    if link then
        HandleModifiedItemClick(link)
    end
end

function DJ.CreateItemRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    row.icon = row:CreateTexture(nil, "ARTWORK")
    DJ.Size(row.icon, 30, 30)
    row.icon:SetPoint("LEFT", 5, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.iconBorder = row:CreateTexture(nil, "OVERLAY")
    row.iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    row.iconBorder:SetBlendMode("ADD")
    DJ.Size(row.iconBorder, 56, 56)
    row.iconBorder:SetPoint("CENTER", row.icon, "CENTER")
    row.name = DJ.Text(row, "GameFontNormal", 12)
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 7, -1)
    row.name:SetPoint("RIGHT", -22, 0)
    row.name:SetHeight(14)
    row.meta = DJ.Text(row, "GameFontHighlightSmall", 10)
    row.meta:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 7, 1)
    row.meta:SetPoint("RIGHT", -22, 0)
    row.meta:SetHeight(12)
    row.star = row:CreateTexture(nil, "OVERLAY")
    row.star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    DJ.Size(row.star, 13, 13)
    row.star:SetPoint("TOPRIGHT", -4, -4)
    row.owned = row:CreateTexture(nil, "OVERLAY")
    row.owned:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
    DJ.Size(row.owned, 14, 14)
    row.owned:SetPoint("BOTTOMRIGHT", -4, 4)
    row.header = DJ.Text(row, "GameFontNormal", 12)
    row.header:SetPoint("LEFT", 6, -2)
    row.header:SetPoint("RIGHT", -6, -2)
    row.headerLine = row:CreateTexture(nil, "ARTWORK")
    row.headerLine:SetTexture(WHITE)
    row.headerLine:SetHeight(1)
    row.headerLine:SetPoint("BOTTOMLEFT", 4, 3)
    row.headerLine:SetPoint("BOTTOMRIGHT", -4, 3)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture(WHITE)
    hl:SetPoint("TOPLEFT", 1, -1)
    hl:SetPoint("BOTTOMRIGHT", -1, 1)
    hl:SetVertexColor(1, 1, 1, 0.07)
    row.hl = hl
    row:SetScript("OnEnter", ItemRow_OnEnter)
    row:SetScript("OnLeave", ItemRow_OnLeave)
    row:SetScript("OnClick", ItemRow_OnClick)
    row:SetScript("OnUpdate", function(self)
        -- Show or hide the comparison tooltip as Shift goes down or up.
        if self.hasTooltip and GameTooltip:IsOwned(self) then
            local shift = IsShiftKeyDown() and true or false
            if shift ~= self.lastShift then
                self.lastShift = shift
                ItemRow_OnEnter(self)
                if not shift then
                    ShoppingTooltip1:Hide()
                    ShoppingTooltip2:Hide()
                end
            end
        end
    end)
    return row
end

-- entry: item ID (number) or section header (string)
function DJ.SetItemRow(row, entry, boss, mode, sourceText)
    local t = DJ.theme
    row.boss, row.mode, row.sourceText = boss, mode, sourceText
    if type(entry) == "string" then
        row.itemID = nil
        row:SetBackdropColor(0, 0, 0, 0)
        row:SetBackdropBorderColor(0, 0, 0, 0)
        row.icon:Hide(); row.iconBorder:Hide(); row.name:Hide(); row.meta:Hide()
        row.star:Hide(); row.owned:Hide(); row.hl:Hide()
        row:EnableMouse(false)
        if entry == "" then -- blank cell next to a header
            row.header:Hide(); row.headerLine:Hide()
            return
        end
        row.header:SetText(entry)
        row.header:SetTextColor(t.title[1], t.title[2], t.title[3])
        row.header:Show()
        row.headerLine:SetVertexColor(t.border[1], t.border[2], t.border[3], 0.6)
        row.headerLine:Show()
        row:EnableMouse(false)
        return
    end
    row:EnableMouse(true)
    row.itemID = entry
    row.header:Hide(); row.headerLine:Hide()
    row.icon:Show(); row.name:Show(); row.meta:Show(); row.hl:Show()
    local name, quality, icon, slotText, _, cached = DJ.ItemData(entry)
    if not cached then DJ.RequestItem(entry) end
    row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    local r, g, b = DJ.QualityColor(quality)
    row.name:SetText(name)
    row.name:SetTextColor(r, g, b)
    if quality and quality >= 2 then
        row.iconBorder:SetVertexColor(r, g, b, 0.9)
        row.iconBorder:Show()
    else
        row.iconBorder:Hide()
    end
    row.meta:SetText(slotText or "")
    row.meta:SetTextColor(t.muted[1], t.muted[2], t.muted[3])
    row:SetBackdropColor(t.lootRow[1], t.lootRow[2], t.lootRow[3], t.lootRow[4])
    row:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], 0.35)
    if DJ.IsFavourite(entry) then row.star:Show() else row.star:Hide() end
    if GetItemCount(entry, true) > 0 then row.owned:Show() else row.owned:Hide() end
end

-- Item-row look for a non-item entry (search results for instances and bosses).
function DJ.SetPlainRow(row, icon, name, meta)
    local t = DJ.theme
    row.itemID, row.boss, row.mode, row.sourceText = nil, nil, nil, nil
    row:EnableMouse(true)
    row.header:Hide(); row.headerLine:Hide()
    row.star:Hide(); row.owned:Hide(); row.iconBorder:Hide()
    row.icon:Show(); row.name:Show(); row.meta:Show(); row.hl:Show()
    row.icon:SetTexture(icon)
    row.name:SetText(name)
    row.name:SetTextColor(t.title[1], t.title[2], t.title[3])
    row.meta:SetText(meta)
    row.meta:SetTextColor(t.muted[1], t.muted[2], t.muted[3])
    row:SetBackdropColor(t.lootRow[1], t.lootRow[2], t.lootRow[3], t.lootRow[4])
    row:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], 0.35)
end
