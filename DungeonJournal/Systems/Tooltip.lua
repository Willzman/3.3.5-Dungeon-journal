-- Adds "Dungeon Journal: Boss - Instance" to tooltips of items that drop in a journal instance.
local DJ = DungeonJournal
local L = DJ.L

local MAX_LINES = 3

local function AddSource(tooltip)
    if not DJ.db or not DJ.db.tooltipSource then return end
    local _, link = tooltip:GetItem()
    local id = link and tonumber(string.match(link, "item:(%d+)"))
    local sources = id and DJ.ItemSources(id)
    if not sources then return end
    -- Group modes of the same boss into one line: "Sartharion - The Obsidian Sanctum (10 Player, 25 Player)".
    local lines, byBoss = {}, {}
    for _, src in ipairs(sources) do
        local entry = byBoss[src.boss]
        if not entry then
            entry = { boss = src.boss, modes = {} }
            byBoss[src.boss] = entry
            lines[#lines + 1] = entry
        end
        entry.modes[#entry.modes + 1] = src.mode
    end
    tooltip:AddLine(L.SOURCE_LINE, 1, 0.82, 0)
    for i, entry in ipairs(lines) do
        if i > MAX_LINES then
            tooltip:AddLine("  " .. string.format(L.AND_MORE, #lines - MAX_LINES), 0.6, 0.6, 0.6)
            break
        end
        local inst = entry.boss.instance
        local text = "  " .. DJ.BossName(entry.boss) .. " - " .. inst.name
        if #inst.modes > 1 then
            local labels = {}
            for _, m in ipairs(entry.modes) do labels[#labels + 1] = DJ.ModeLabel(inst, m) end
            text = text .. " (" .. table.concat(labels, ", ") .. ")"
        end
        tooltip:AddLine(text, 0.6, 0.8, 1)
    end
    tooltip:Show()
end

GameTooltip:HookScript("OnTooltipSetItem", AddSource)
ItemRefTooltip:HookScript("OnTooltipSetItem", AddSource)
