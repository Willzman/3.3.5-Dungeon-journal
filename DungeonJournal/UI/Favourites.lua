-- Favourites window: items added with right-click, grouped by instance.
local DJ = DungeonJournal
local L = DJ.L

local win = CreateFrame("Frame", "DungeonJournalFavourites", UIParent)
DJ.Size(win, 340, 480)
win:SetFrameStrata("HIGH")
win:SetToplevel(true)
win:EnableMouse(true)
win:SetMovable(true)
win:SetClampedToScreen(true)
win:RegisterForDrag("LeftButton")
win:SetScript("OnDragStart", win.StartMoving)
win:SetScript("OnDragStop", win.StopMovingOrSizing)
win:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
win:Hide()
table.insert(UISpecialFrames, "DungeonJournalFavourites")
win.OnTheme = function(self, t)
    self:SetBackdropColor(t.frame[1], t.frame[2], t.frame[3], t.frame[4])
    self:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], 1)
end
table.insert(DJ.themedRegions, win)

local title = DJ.Text(win, "GameFontNormalLarge", 15)
title:SetPoint("TOPLEFT", 12, -12)
title:SetText(L.FAVOURITES)
local hint = DJ.Text(win, "GameFontDisableSmall", 10)
hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
hint:SetText(L.FAV_HINT)
local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 0, 0)

local empty = DJ.Text(win, "GameFontDisable", 12, "CENTER")
empty:SetPoint("LEFT", 20, 0)
empty:SetPoint("RIGHT", -20, 0)
empty:SetText(L.FAV_EMPTY)

local function OpenFavourite(row)
    local fav = DJ.db.favourites[row.itemID]
    local inst = fav and fav.inst and DJ.GetInstance(fav.inst)
    if inst then
        DJ.OpenInstance(inst, fav.boss, fav.mode)
        return
    end
    local sources = DJ.ItemSources(row.itemID)
    if sources and sources[1] then
        DJ.OpenInstance(sources[1].boss.instance, sources[1].boss.index, sources[1].mode)
    end
end

local list = DJ.ScrollList(win, { rowHeight = 40, spacing = 3, createRow = DJ.CreateItemRow,
    updateRow = function(row, entry)
        if type(entry) == "number" then
            local fav = DJ.db.favourites[entry]
            local inst = fav and fav.inst and DJ.GetInstance(fav.inst)
            local boss = inst and fav.boss and inst.bosses[fav.boss]
            DJ.SetItemRow(row, entry, boss, fav and fav.mode)
            if boss then
                local text = DJ.BossName(boss)
                if fav.mode and #inst.modes > 1 then text = text .. " (" .. DJ.ModeLabel(inst, fav.mode) .. ")" end
                row.meta:SetText(text)
            end
            row.onClick = OpenFavourite
        else
            DJ.SetItemRow(row, entry)
        end
    end })
list:SetPoint("TOPLEFT", 10, -48)
list:SetPoint("BOTTOMRIGHT", -8, 10)

function win:Refresh()
    local groups, order = {}, {}
    for id, fav in pairs(DJ.db.favourites) do
        local inst = fav.inst and DJ.GetInstance(fav.inst)
        local key = inst and inst.index or 9999
        if not groups[key] then
            groups[key] = { name = inst and inst.name or "?", items = {} }
            order[#order + 1] = key
        end
        table.insert(groups[key].items, id)
    end
    table.sort(order)
    local data = {}
    for _, key in ipairs(order) do
        data[#data + 1] = groups[key].name
        table.sort(groups[key].items)
        for _, id in ipairs(groups[key].items) do data[#data + 1] = id end
    end
    list:SetData(data, true)
    if #data == 0 then empty:Show() else empty:Hide() end
end

function DJ.ToggleFavourites()
    if win:IsShown() then
        win:Hide()
        return
    end
    win:ClearAllPoints()
    if DJ.frame:IsShown() then
        win:SetScale(DJ.frame:GetScale())
        win:SetPoint("TOPLEFT", DJ.frame, "TOPRIGHT", 4, 0)
    else
        win:SetPoint("CENTER")
    end
    win:Show()
    win:Refresh()
end

-- Right-clicking a row in the Favourites window removes the item; ItemRow's
-- right-click already toggles, so only the list needs refreshing.
DJ.On("FAVOURITES_CHANGED", function() if win:IsShown() then win:Refresh() end end)
DJ.On("ITEMS_UPDATED", function() if win:IsShown() then list:Refresh() end end)
DJ.On("SCALE_CHANGED", function(scale) win:SetScale(scale) end)
