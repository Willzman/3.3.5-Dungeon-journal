-- Dungeon Journal for Wrath of the Lich King 3.3.5a.
-- Shared namespace, saved variables and small helpers used by every other file.

DungeonJournal = DungeonJournal or {}
local DJ = DungeonJournal

DJ.VERSION = "1.0.0"
DJ.ADDON_NAME = "DungeonJournal"
DJ.MEDIA = "Interface\\AddOns\\DungeonJournal\\Media\\"

local DEFAULTS = {
    minimap = { show = true, angle = 205 },
    tooltipSource = true,
    showTrash = true,
    scale = 1,
    point = nil,
    favourites = {},
    filter = { classOnly = false, armor = {}, hideRecipes = false, hideNonEquip = false },
    lastExpansion = 2,
    lastKind = "dungeon",
    autoOpenCurrent = true,
}

local CHAR_DEFAULTS = {
    lastInstance = nil,
    lastBoss = {},
    lastMode = {},
    lastMap = {},
}

local function ApplyDefaults(db, defaults)
    for k, v in pairs(defaults) do
        if db[k] == nil then
            if type(v) == "table" then
                db[k] = {}
                ApplyDefaults(db[k], v)
            else
                db[k] = v
            end
        elseif type(v) == "table" and type(db[k]) == "table" then
            ApplyDefaults(db[k], v)
        end
    end
end

-- 3.3.5a regions have no SetSize on every widget type, so size through this helper.
function DJ.Size(region, w, h)
    region:SetWidth(w)
    region:SetHeight(h or w)
end

function DJ.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd200Dungeon Journal:|r " .. tostring(msg))
end

-- Minimal timer: DJ.After(seconds, func). The 3.3.5a client has no C_Timer.
local timerFrame = CreateFrame("Frame")
local timers = {}
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    for i = #timers, 1, -1 do
        local t = timers[i]
        if now >= t.at then
            table.remove(timers, i)
            t.func()
        end
    end
    if #timers == 0 then self:Hide() end
end)

function DJ.After(seconds, func)
    timers[#timers + 1] = { at = GetTime() + seconds, func = func }
    timerFrame:Show()
end

-- Simple callback registry for module events (e.g. "ITEMS_UPDATED").
local callbacks = {}
function DJ.On(event, func)
    callbacks[event] = callbacks[event] or {}
    table.insert(callbacks[event], func)
end

function DJ.Fire(event, ...)
    local list = callbacks[event]
    if not list then return end
    for i = 1, #list do list[i](...) end
end

local eventFrame = CreateFrame("Frame")
DJ.eventFrame = eventFrame
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == DJ.ADDON_NAME then
        DungeonJournalDB = DungeonJournalDB or {}
        DungeonJournalCharDB = DungeonJournalCharDB or {}
        ApplyDefaults(DungeonJournalDB, DEFAULTS)
        ApplyDefaults(DungeonJournalCharDB, CHAR_DEFAULTS)
        DJ.db = DungeonJournalDB
        DJ.cdb = DungeonJournalCharDB
        DJ.Fire("DB_READY")
    elseif event == "PLAYER_LOGIN" then
        DJ.Fire("LOGIN")
    end
end)

BINDING_HEADER_DUNGEONJOURNAL = "Dungeon Journal"
BINDING_NAME_DUNGEONJOURNAL_TOGGLE = "Open/Close Dungeon Journal"
