-- Item information on the 3.3.5a client: GetItemInfo only answers for cached items and
-- there is no GET_ITEM_INFO_RECEIVED event, so uncached items are requested through a
-- hidden tooltip and polled until the server has answered. Until then the journal
-- shows the bundled English name, quality and slot text from Data/Items.lua.
local DJ = DungeonJournal
local L = DJ.L

local GetItemInfo, GetItemIcon = GetItemInfo, GetItemIcon

local scanTip = CreateFrame("GameTooltip", "DungeonJournalScanTooltip", UIParent, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

local queue, queued, pending = {}, {}, {}
local worker = CreateFrame("Frame")
worker:Hide()
local sinceRequest, sincePoll = 0, 0

worker:SetScript("OnUpdate", function(self, elapsed)
    sinceRequest = sinceRequest + elapsed
    sincePoll = sincePoll + elapsed
    if sinceRequest > 0.15 and #queue > 0 then
        sinceRequest = 0
        for _ = 1, 6 do
            local id = table.remove(queue, 1)
            if not id then break end
            queued[id] = nil
            if not GetItemInfo(id) then
                scanTip:SetOwner(UIParent, "ANCHOR_NONE")
                scanTip:SetHyperlink("item:" .. id .. ":0:0:0:0:0:0:0")
                scanTip:Hide()
                pending[id] = GetTime()
            end
        end
    end
    if sincePoll > 0.5 then
        sincePoll = 0
        local arrived, waiting = false, false
        local now = GetTime()
        for id, at in pairs(pending) do
            if GetItemInfo(id) then
                pending[id] = nil
                arrived = true
            elseif now - at > 20 then
                pending[id] = nil -- the server never answered; stop asking
            else
                waiting = true
            end
        end
        if arrived then DJ.Fire("ITEMS_UPDATED") end
        if not waiting and #queue == 0 then self:Hide() end
    end
end)

function DJ.RequestItem(id)
    if GetItemInfo(id) or queued[id] or pending[id] then return end
    queued[id] = true
    queue[#queue + 1] = id
    worker:Show()
end

function DJ.IsPending(id)
    return (queued[id] or pending[id]) and true or false
end

local function SlotTextFromInfo(itemType, subType, equipLoc)
    local slot = equipLoc and equipLoc ~= "" and _G[equipLoc] or nil
    if slot and subType and subType ~= "" and itemType ~= nil then
        local misc = (subType == (select(1, GetAuctionItemSubClasses(2))) or subType == (select(12, GetAuctionItemSubClasses(1))))
        if equipLoc == "INVTYPE_CLOAK" or equipLoc == "INVTYPE_FINGER" or equipLoc == "INVTYPE_NECK"
            or equipLoc == "INVTYPE_TRINKET" or misc then
            return slot
        end
        return slot .. ", " .. subType
    end
    if slot then return slot end
    if subType and subType ~= "" and subType ~= itemType then
        return itemType .. ", " .. subType
    end
    return itemType or ""
end

-- name, quality, icon, slotText, link, cached
function DJ.ItemData(id)
    local name, link, quality, _, _, itemType, subType, _, equipLoc, icon = GetItemInfo(id)
    if name then
        return name, quality, icon, SlotTextFromInfo(itemType, subType, equipLoc), link, true
    end
    local info = DJ.ItemInfo[id]
    icon = GetItemIcon and GetItemIcon(id) or nil
    if info then
        return info[1], info[2], icon, info[3], nil, false
    end
    return string.format("item #%d", id), 1, icon, "", nil, false
end

function DJ.ItemName(id)
    return (DJ.ItemData(id))
end

function DJ.QualityColor(q)
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q or 1]
    if c then return c.r, c.g, c.b, c.hex end
    return 1, 1, 1, "|cffffffff"
end

-- A real chat link is only available once the item is cached.
function DJ.ItemLink(id)
    local _, link = GetItemInfo(id)
    return link
end

------------------------------------------------------------------------
-- Class usability and loot filter
------------------------------------------------------------------------

-- Weapon and armor kinds, keyed by English name. Localised names from the
-- client's auction categories map onto these keys (category order is fixed).
local WEAPON_KEYS = { "1H Axe", "2H Axe", "Bow", "Gun", "1H Mace", "2H Mace", "Polearm", "1H Sword", "2H Sword",
    "Staff", "Fist", "MiscWeapon", "Dagger", "Thrown", "Crossbow", "Wand", "Fishing Pole" }
local ARMOR_KEYS = { "MiscArmor", "Cloth", "Leather", "Mail", "Plate", "Shield", "Libram", "Idol", "Totem", "Sigil" }

local localKinds
local function BuildLocalKinds()
    localKinds = {}
    local w = { GetAuctionItemSubClasses(1) }
    for i, n in ipairs(w) do if WEAPON_KEYS[i] then localKinds["W:" .. n] = WEAPON_KEYS[i] end end
    local a = { GetAuctionItemSubClasses(2) }
    for i, n in ipairs(a) do if ARMOR_KEYS[i] then localKinds["A:" .. n] = ARMOR_KEYS[i] end end
end

local ALL_ARMOR = { Cloth = true, Leather = true, Mail = true, Plate = true }
local CLASS_KINDS = {
    WARRIOR = { "Cloth", "Leather", "Mail", "Plate", "Shield", "1H Axe", "2H Axe", "Bow", "Gun", "1H Mace", "2H Mace", "Polearm", "1H Sword", "2H Sword", "Staff", "Fist", "Dagger", "Thrown", "Crossbow" },
    PALADIN = { "Cloth", "Leather", "Mail", "Plate", "Shield", "Libram", "1H Axe", "2H Axe", "1H Mace", "2H Mace", "Polearm", "1H Sword", "2H Sword" },
    HUNTER = { "Cloth", "Leather", "Mail", "1H Axe", "2H Axe", "Bow", "Gun", "Polearm", "1H Sword", "2H Sword", "Staff", "Fist", "Dagger", "Thrown", "Crossbow" },
    ROGUE = { "Cloth", "Leather", "1H Axe", "Bow", "Gun", "1H Mace", "1H Sword", "Fist", "Dagger", "Thrown", "Crossbow" },
    PRIEST = { "Cloth", "1H Mace", "Staff", "Dagger", "Wand" },
    DEATHKNIGHT = { "Cloth", "Leather", "Mail", "Plate", "Sigil", "1H Axe", "2H Axe", "1H Mace", "2H Mace", "Polearm", "1H Sword", "2H Sword" },
    SHAMAN = { "Cloth", "Leather", "Mail", "Shield", "Totem", "1H Axe", "2H Axe", "1H Mace", "2H Mace", "Staff", "Fist", "Dagger" },
    MAGE = { "Cloth", "1H Sword", "Staff", "Dagger", "Wand" },
    WARLOCK = { "Cloth", "1H Sword", "Staff", "Dagger", "Wand" },
    DRUID = { "Cloth", "Leather", "Idol", "1H Mace", "2H Mace", "Polearm", "Staff", "Fist", "Dagger" },
}
local classKinds
local function PlayerKinds()
    if not classKinds then
        classKinds = {}
        local _, class = UnitClass("player")
        for _, k in ipairs(CLASS_KINDS[class] or {}) do classKinds[k] = true end
        classKinds.MiscArmor, classKinds.MiscWeapon, classKinds["Fishing Pole"] = true, true, true
    end
    return classKinds
end

-- Kind of an uncached item from the bundled English slot text ("Two-Hand, Axe").
local TEXT_KINDS = {
    Cloth = "Cloth", Leather = "Leather", Mail = "Mail", Plate = "Plate", Shield = "Shield",
    Bow = "Bow", Gun = "Gun", Crossbow = "Crossbow", Wand = "Wand", Thrown = "Thrown", Staff = "Staff",
    Polearm = "Polearm", Dagger = "Dagger", ["Fist Weapon"] = "Fist", Idol = "Idol", Totem = "Totem",
    Libram = "Libram", Sigil = "Sigil",
}
local function KindFromText(text)
    if not text or text == "" then return nil end
    if string.find(text, "^Back") or string.find(text, "^Neck") or string.find(text, "^Ring")
        or string.find(text, "^Trinket") or string.find(text, "^Held In Off") then
        return nil
    end
    local twoHand = string.find(text, "Two%-Hand") ~= nil
    for word in string.gmatch(text, "[^,]+") do
        word = strtrim(word)
        if TEXT_KINDS[word] then return TEXT_KINDS[word] end
        if word == "Axe" or word == "Mace" or word == "Sword" then
            return (twoHand and "2H " or "1H ") .. word
        end
    end
    return nil
end

local function KindOf(id)
    local name, _, _, _, _, itemType, subType, _, equipLoc = GetItemInfo(id)
    if name then
        if equipLoc == "INVTYPE_CLOAK" then return nil end
        if not localKinds then BuildLocalKinds() end
        return localKinds["W:" .. (subType or "")] or localKinds["A:" .. (subType or "")]
    end
    local info = DJ.ItemInfo[id]
    return KindFromText(info and info[3])
end

local ALLOWED_PATTERN = ITEM_CLASSES_ALLOWED and string.gsub(ITEM_CLASSES_ALLOWED, "%%s", "(.+)")
local classAllowedCache = {}
-- false when the tooltip names classes and ours is not among them (tier tokens, etc.)
local function ClassAllowed(id)
    if classAllowedCache[id] ~= nil then return classAllowedCache[id] end
    if not GetItemInfo(id) or not ALLOWED_PATTERN then return true end
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetHyperlink("item:" .. id .. ":0:0:0:0:0:0:0")
    local result = true
    local className = UnitClass("player")
    for i = 2, scanTip:NumLines() do
        local line = _G["DungeonJournalScanTooltipTextLeft" .. i]
        local text = line and line:GetText()
        local list = text and string.match(text, ALLOWED_PATTERN)
        if list then
            result = string.find(list, className, 1, true) ~= nil
            break
        end
    end
    scanTip:Hide()
    classAllowedCache[id] = result
    return result
end

local RECIPE_PREFIXES = { "Pattern:", "Plans:", "Recipe:", "Formula:", "Schematic:", "Design:", "Manual:" }
local function IsRecipe(id)
    local name, _, _, _, _, itemType = GetItemInfo(id)
    if name then
        local recipeClass = select(9, GetAuctionItemClasses())
        if recipeClass and itemType == recipeClass then return true end
    end
    local info = DJ.ItemInfo[id]
    local n = info and info[1] or name or ""
    for _, p in ipairs(RECIPE_PREFIXES) do
        if string.sub(n, 1, #p) == p then return true end
    end
    return false
end

function DJ.FilterActive()
    local f = DJ.db.filter
    if f.classOnly or f.hideRecipes or f.hideNonEquip then return true end
    for _, v in pairs(f.armor) do if v then return true end end
    return false
end

-- True when the item should be shown under the current Loot Filter.
function DJ.PassesFilter(id)
    local f = DJ.db.filter
    if f.hideRecipes and IsRecipe(id) then return false end
    local name, _, _, _, _, _, _, _, equipLoc = GetItemInfo(id)
    if f.hideNonEquip and name and (not equipLoc or equipLoc == "") then return false end
    local kind = KindOf(id)
    if f.classOnly then
        if kind and not PlayerKinds()[kind] then return false end
        if not ClassAllowed(id) then return false end
    end
    local anyArmor = false
    for _, v in pairs(f.armor) do if v then anyArmor = true end end
    if anyArmor and kind and ALL_ARMOR[kind] and not f.armor[kind] then return false end
    return true
end

function DJ.FilterResetCaches()
    classKinds = nil
end
