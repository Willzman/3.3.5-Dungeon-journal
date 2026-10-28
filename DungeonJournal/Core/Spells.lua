-- Boss abilities: spell IDs from Data/Abilities.lua, with names, icons and descriptions
-- taken from the client's own spell data (GetSpellInfo and the spell tooltip).
local DJ = DungeonJournal

local cache = {}
local descCache = {}

local function TipLine(i)
    return _G["DungeonJournalScanTooltipTextLeft" .. i]
end

-- The description is the gold text at the bottom of a spell tooltip; the lines above
-- it are range, cast time and cooldown (white).
function DJ.SpellDescription(id)
    if descCache[id] ~= nil then return descCache[id] or nil end
    local tip = DungeonJournalScanTooltip
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:SetHyperlink("spell:" .. id)
    local desc
    for i = tip:NumLines(), 2, -1 do
        local line = TipLine(i)
        local text = line and line:GetText()
        if text and text ~= "" then
            local r, g, b = line:GetTextColor()
            if r and r > 0.9 and g > 0.7 and g < 0.9 and b < 0.15 then
                desc = desc and (text .. " " .. desc) or text
            elseif desc then
                break
            end
        end
    end
    tip:Hide()
    descCache[id] = desc or false
    return desc
end

-- { { id, name, icon }, ... } for a boss, duplicates by name removed.
function DJ.BossAbilities(boss)
    local key = boss.instance.key .. "#" .. boss.index
    if cache[key] then return cache[key] end
    local list, seen = {}, {}
    for _, id in ipairs(DJ.Abilities[key] or {}) do
        local name, _, icon = GetSpellInfo(id)
        if name and name ~= "" and not seen[name] then
            seen[name] = true
            list[#list + 1] = { id = id, name = name, icon = icon }
        end
    end
    cache[key] = list
    return list
end
