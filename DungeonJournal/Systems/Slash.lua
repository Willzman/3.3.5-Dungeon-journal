-- /dj and /dungeonjournal
local DJ = DungeonJournal
local L = DJ.L

SLASH_DUNGEONJOURNAL1 = "/dj"
SLASH_DUNGEONJOURNAL2 = "/dungeonjournal"

SlashCmdList["DUNGEONJOURNAL"] = function(msg)
    msg = strtrim(msg or "")
    local cmd, rest = string.match(msg, "^(%S+)%s*(.-)$")
    cmd = cmd and string.lower(cmd) or ""
    if cmd == "" then
        DJ.Toggle()
    elseif cmd == "help" or cmd == "?" then
        for line in string.gmatch(L.HELP, "[^\n]+") do DJ.Print(line) end
    elseif cmd == "options" or cmd == "config" then
        DJ.OpenOptions()
    elseif cmd == "reset" then
        DJ.ResetPosition()
    elseif cmd == "fav" or cmd == "favourites" or cmd == "favorites" then
        DJ.ToggleFavourites()
    elseif cmd == "home" then
        DJ.ShowHome()
    elseif cmd == "modeltest" then
        DJ.ModelTest(tonumber(rest))
    elseif cmd == "search" then
        if rest ~= "" then DJ.ShowSearch(rest) end
    else
        local inst = DJ.FindInstance(msg)
        if inst then
            DJ.OpenInstance(inst)
        else
            DJ.ShowSearch(msg)
        end
    end
end

-- /dj modeltest [npcID]: reports how this client loads creature models (for bug reports).
function DJ.ModelTest(npc)
    npc = npc or 11520 -- Taragaman the Hungerer
    local m = DJ.modelTestFrame
    if not m then
        m = CreateFrame("PlayerModel", nil, UIParent)
        DJ.Size(m, 120, 120)
        m:SetPoint("CENTER")
        DJ.modelTestFrame = m
    end
    m:Show()
    m:ClearModel()
    DJ.Print("SetDisplayInfo available: " .. tostring(m.SetDisplayInfo ~= nil))
    local ok, err = pcall(m.SetCreature, m, npc)
    DJ.Print("SetCreature(" .. npc .. "): " .. (ok and "ok" or tostring(err)) .. ", GetModel now: " .. tostring(m:GetModel()))
    for _, delay in ipairs({ 1, 3 }) do
        DJ.After(delay, function()
            DJ.Print(delay .. "s: GetModel = " .. tostring(m:GetModel()))
            pcall(m.SetCreature, m, npc)
            DJ.Print(delay .. "s after re-SetCreature: GetModel = " .. tostring(m:GetModel()))
            if delay == 3 then
                if m.SetDisplayInfo then
                    m:ClearModel()
                    local ok2, err2 = pcall(m.SetDisplayInfo, m, 7970)
                    DJ.Print("SetDisplayInfo(7970): " .. (ok2 and "ok" or tostring(err2)) .. ", GetModel: " .. tostring(m:GetModel()))
                end
                DJ.After(3, function() m:Hide() end)
            end
        end)
    end
end
