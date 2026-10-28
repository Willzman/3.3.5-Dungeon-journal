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

