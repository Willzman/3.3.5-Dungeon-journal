-- Search page: instances, bosses and loot by name.
local DJ = DungeonJournal
local L = DJ.L

local MAX_ITEMS = 400

local page = CreateFrame("Frame")
DJ.RegisterPage("search", page)

local bar = DJ.Panel(page, "left", "border")
bar:SetPoint("TOPLEFT")
bar:SetPoint("TOPRIGHT")
bar:SetHeight(30)
local summary = DJ.Text(bar, "GameFontNormal", 12)
summary:SetPoint("LEFT", 10, 0)
bar.OnTheme = function(_, t) summary:SetTextColor(t.title[1], t.title[2], t.title[3]) end

local function SourceText(src)
    local boss = src.boss
    local inst = boss.instance
    local text = DJ.BossName(boss) .. " - " .. inst.name
    if #inst.modes > 1 then text = text .. " (" .. DJ.ModeLabel(inst, src.mode) .. ")" end
    return text
end
DJ.SourceText = SourceText

local function OpenResult(row)
    local r = row.result
    if r.kind == "instance" then
        DJ.OpenInstance(r.inst)
    elseif r.kind == "boss" then
        DJ.OpenInstance(r.boss.instance, r.boss.index)
    elseif r.src then
        DJ.OpenInstance(r.src.boss.instance, r.src.boss.index, r.src.mode)
    end
end

local function UpdateRow(row, r)
    row.result = r
    row.onClick = OpenResult
    if r.kind == "item" then
        DJ.SetItemRow(row, r.id, r.src.boss, r.src.mode, SourceText(r.src))
        local n = #r.sources
        row.meta:SetText(SourceText(r.src) .. (n > 1 and ("  |cff808080+" .. (n - 1) .. "|r") or ""))
        return
    end
    -- Instance and boss results reuse the item row look.
    if r.kind == "instance" then
        DJ.SetPlainRow(row, DJ.KIND_ICONS[r.inst.kind], r.inst.name, L.RESULT_INSTANCE .. " - " .. r.inst.zone)
    else
        DJ.SetPlainRow(row, "Interface\\Icons\\INV_Misc_Bone_HumanSkull_02", DJ.BossName(r.boss),
            L.RESULT_BOSS .. " - " .. r.boss.instance.name)
    end
end

local list = DJ.ScrollList(page, { rowHeight = 40, cols = 2, spacing = 4, createRow = DJ.CreateItemRow, updateRow = UpdateRow })
list:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 6, -8)
list:SetPoint("BOTTOMRIGHT", -4, 6)

local empty = DJ.Text(page, "GameFontDisable", 13, "CENTER")
empty:SetPoint("CENTER")
empty:SetText(L.NO_RESULTS)

-- All loot item IDs, in instance order (built once).
local allItems
local function AllItems()
    if allItems then return allItems end
    allItems = {}
    local seen = {}
    for _, inst in ipairs(DJ.Instances) do
        for _, boss in ipairs(inst.bosses) do
            for _, mode in ipairs(DJ.MODE_ORDER) do
                local loot = boss.loot[mode]
                if loot then
                    local lists = (loot.A or loot.H) and { loot.A or {}, loot.H or {} } or { loot }
                    for _, l in ipairs(lists) do
                        for _, id in ipairs(l) do
                            if type(id) == "number" and not seen[id] then
                                seen[id] = true
                                allItems[#allItems + 1] = id
                            end
                        end
                    end
                end
            end
        end
    end
    return allItems
end

function DJ.Search(text)
    local q = string.lower(strtrim(text or ""))
    local results = {}
    if q == "" then return results end
    local nq = DJ.Normalize(q)
    for _, inst in ipairs(DJ.Instances) do
        local hit = string.find(string.lower(inst.name), q, 1, true) or inst.short == nq
        if not hit and inst.aliases then
            for _, a in ipairs(inst.aliases) do if a == nq then hit = true end end
        end
        if hit then results[#results + 1] = { kind = "instance", inst = inst } end
    end
    for _, inst in ipairs(DJ.Instances) do
        for _, boss in ipairs(inst.bosses) do
            if not boss.extra and string.find(string.lower(DJ.BossName(boss)), q, 1, true) then
                results[#results + 1] = { kind = "boss", boss = boss }
            end
        end
    end
    local count = 0
    local filtering = DJ.FilterActive()
    for _, id in ipairs(AllItems()) do
        local name = GetItemInfo(id)
        local info = DJ.ItemInfo[id]
        local match = (name and string.find(string.lower(name), q, 1, true))
            or (info and string.find(string.lower(info[1]), q, 1, true))
        if match and (not filtering or DJ.PassesFilter(id)) then
            local sources = DJ.ItemSources(id)
            if sources and sources[1] then
                results[#results + 1] = { kind = "item", id = id, src = sources[1], sources = sources }
                count = count + 1
                if count >= MAX_ITEMS then break end
            end
        end
    end
    return results
end

function page:Open(state)
    DJ.ApplyTheme(DJ.THEMES.home)
    self.text = state.text
    local results = DJ.Search(state.text)
    summary:SetText(string.format('%s: "%s"  -  ' .. L.RESULTS, L.SEARCH, state.text, #results))
    list:SetData(results)
    if #results == 0 then empty:Show() else empty:Hide() end
end

DJ.On("ITEMS_UPDATED", function() if page:IsShown() then list:Refresh() end end)
DJ.On("FAVOURITES_CHANGED", function() if page:IsShown() then list:Refresh() end end)
DJ.On("FILTER_CHANGED", function() if page:IsShown() and page.text then page:Open({ text = page.text }) end end)
