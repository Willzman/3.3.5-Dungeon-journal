-- Lookups over the generated instance data (Data/Instances.lua).
local DJ = DungeonJournal
local L = DJ.L

DJ.EXPANSIONS = { [0] = L.CLASSIC, [1] = L.TBC, [2] = L.WRATH }
DJ.MODE_ORDER = { "N", "H", "R10", "R25", "R10H", "R25H" }

local byKey = {}
for index, inst in ipairs(DJ.Instances) do
    inst.index = index
    byKey[inst.key] = inst
    for bi, boss in ipairs(inst.bosses) do
        boss.index = bi
        boss.instance = inst
    end
end

function DJ.GetInstance(key)
    return byKey[key]
end

function DJ.PlayerFaction()
    local f = UnitFactionGroup("player")
    if f == "Horde" then return "H" end
    return "A"
end

function DJ.ModeLabel(inst, mode)
    if mode == "N" and inst and inst.kind == "raid" then
        return string.format(L.PLAYERS, inst.size)
    end
    return L["MODE_" .. mode] or mode
end

function DJ.BossName(boss)
    if boss.factionName then
        return boss.factionName[DJ.PlayerFaction()] or boss.name
    end
    return boss.name
end

-- Loot list for one boss and mode: item IDs (numbers) and section headers (strings).
function DJ.GetLoot(boss, mode)
    local loot = boss.loot[mode]
    if not loot then return nil end
    if loot.A or loot.H then
        return loot[DJ.PlayerFaction()] or loot.A or loot.H
    end
    return loot
end

function DJ.DefaultMode(inst)
    return inst.modes[1]
end

-- Visible bosses for an instance (extra pages can be hidden in the options).
function DJ.VisibleBosses(inst)
    local list = {}
    for _, boss in ipairs(inst.bosses) do
        if not boss.extra or DJ.db.showTrash then
            list[#list + 1] = boss
        end
    end
    return list
end

local function normalize(s)
    s = string.lower(s or "")
    s = string.gsub(s, "[%p%s]", "")
    return s
end
DJ.Normalize = normalize

-- Finds an instance by short code ("icc"), alias, or (part of) its name.
function DJ.FindInstance(query)
    local q = normalize(query)
    if q == "" then return nil end
    for _, inst in ipairs(DJ.Instances) do
        if inst.short == q then return inst end
        if inst.aliases then
            for _, a in ipairs(inst.aliases) do
                if a == q then return inst end
            end
        end
    end
    for _, inst in ipairs(DJ.Instances) do
        if normalize(inst.name) == q then return inst end
    end
    for _, inst in ipairs(DJ.Instances) do
        if string.find(normalize(inst.name), q, 1, true) then return inst end
    end
    return nil
end

-- Name lookups used to recognise the instance the player is standing in.
-- Atlas map titles and a few client spellings are accepted besides our own names.
local zoneNames
local function BuildZoneNames()
    zoneNames = {}
    for _, inst in ipairs(DJ.Instances) do
        zoneNames[normalize(inst.name)] = inst
        if inst.maps then
            for _, m in ipairs(inst.maps) do
                local title = string.gsub(m.title, "%s*%b[]", "")
                title = string.gsub(title, "%s*%b()", "")
                local last = string.match(title, ":%s*(.+)$")
                if not string.find(m.file, "Ent$") then
                    zoneNames[normalize(title)] = zoneNames[normalize(title)] or inst
                    if last and inst.kind == "dungeon" then
                        zoneNames[normalize(last)] = zoneNames[normalize(last)] or inst
                    end
                end
            end
        end
    end
    local extra = {
        ["The Temple of Atal'Hakkar"] = "TheTempleOfAtal'Hakkar",
        ["Hellfire Citadel"] = "HellfireRamparts",
        ["Coilfang: Serpentshrine Cavern"] = "SerpentshrineCavern",
        ["Tempest Keep"] = "TempestKeep",
        ["The Battle for Mount Hyjal"] = "HyjalSummit",
        ["Ahn'Qiraj"] = "TheTempleofAhnQiraj",
        ["Ruins of Ahn'Qiraj"] = "TheRuinsofAhnQiraj",
        ["The Nexus"] = "TheNexus",
        ["Naxxramas"] = "NaxxramasWrath",
        ["Onyxia's Lair"] = "WrathOnyxiasLair",
        ["Blackrock Spire"] = "LowerBlackrockSpire",
        ["Dire Maul"] = "DireMaulNorth",
        ["Scarlet Monastery"] = "ScarletMonasteryGraveyard",
        ["Opening of the Dark Portal"] = "TheBlackMorass",
        ["Old Hillsbrad Foothills"] = "OldHillsbradFoothills",
        ["Stormwind Stockade"] = "TheStockade",
        ["Magtheridon's Lair"] = "MagtheridonsLair",
    }
    for name, key in pairs(extra) do
        zoneNames[normalize(name)] = byKey[key]
    end
end

local WING_SUBZONES = {}
for wing, names in pairs({
    ScarletMonasteryGraveyard = { "Chamber of Atonement", "Forlorn Cloister", "Honor's Tomb" },
    ScarletMonasteryLibrary = { "Huntsman's Cloister", "Gallery of Treasures", "Athenaeum" },
    ScarletMonasteryArmory = { "Training Grounds", "Footman's Armory", "Crusader's Armory", "Hall of Champions" },
    ScarletMonasteryCathedral = { "Chapel Gardens", "Crusader's Chapel" },
    DireMaulEast = { "Warpwood Quarter", "The Hidden Reach", "The Conservatory", "The Shrine of Eldretharr" },
    DireMaulWest = { "Capital Gardens", "Court of the Highborne", "Prison of Immol'thar" },
    DireMaulNorth = { "Gordok Commons", "Halls of Destruction" },
}) do
    for _, n in ipairs(names) do WING_SUBZONES[normalize(n)] = wing end
end

-- Instance the player is currently in, plus the journal mode matching its difficulty.
function DJ.CurrentInstance()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid") then return nil end
    if not zoneNames then BuildZoneNames() end
    -- 3.3.5a: name, type, difficulty (1-4: 10/25/10H/25H in raids, 1-2 in dungeons), ...
    local name, _, diff = GetInstanceInfo()
    local inst = zoneNames[normalize(name)] or zoneNames[normalize(GetRealZoneText())]
    if not inst then return nil end
    diff = diff or 1
    local mode
    if inst.kind == "raid" and inst.exp == 2 then
        mode = ({ "R10", "R25", "R10H", "R25H" })[diff]
    elseif inst.kind == "dungeon" and diff == 2 then
        mode = "H"
    end
    -- Scarlet Monastery and Dire Maul wings share one zone name: pick the wing by
    -- subzone, else the wing of that group the journal showed last.
    local prefix = string.match(inst.key, "^(ScarletMonastery)") or string.match(inst.key, "^(DireMaul)")
    if prefix then
        local wing = WING_SUBZONES[normalize(GetSubZoneText() or "")]
        local last = DJ.cdb.lastInstance
        if wing and byKey[wing] then
            inst = byKey[wing]
        elseif last and string.sub(last, 1, #prefix) == prefix and byKey[last] then
            inst = byKey[last]
        end
    end
    if mode then
        local ok = false
        for _, m in ipairs(inst.modes) do if m == mode then ok = true end end
        if not ok then mode = nil end
    end
    return inst, mode
end

-- Reverse index: item ID -> list of { boss, mode }. Built on first use.
local sources
function DJ.ItemSources(itemID)
    if not sources then
        sources = {}
        for _, inst in ipairs(DJ.Instances) do
            for _, boss in ipairs(inst.bosses) do
                for _, mode in ipairs(DJ.MODE_ORDER) do
                    local loot = boss.loot[mode]
                    if loot then
                        local lists = (loot.A or loot.H) and { loot.A or {}, loot.H or {} } or { loot }
                        for _, list in ipairs(lists) do
                            for _, id in ipairs(list) do
                                if type(id) == "number" then
                                    local s = sources[id]
                                    if not s then s = {}; sources[id] = s end
                                    local dup = false
                                    for _, e in ipairs(s) do
                                        if e.boss == boss and e.mode == mode then dup = true end
                                    end
                                    if not dup then s[#s + 1] = { boss = boss, mode = mode } end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return sources[itemID]
end

-- Favourites: account-wide, keyed by item ID, remembering where the item was added from.
function DJ.IsFavourite(itemID)
    return DJ.db.favourites[itemID] ~= nil
end

function DJ.ToggleFavourite(itemID, boss, mode)
    local favs = DJ.db.favourites
    local name = DJ.ItemName(itemID)
    if favs[itemID] then
        favs[itemID] = nil
        DJ.Print(string.format(L.FAV_REMOVED, name))
    else
        favs[itemID] = { inst = boss and boss.instance.key, boss = boss and boss.index, mode = mode, added = time() }
        DJ.Print(string.format(L.FAV_ADDED, name))
    end
    DJ.Fire("FAVOURITES_CHANGED")
end
