-- Drives the journal through every instance, boss, mode and map in the mocked client.
local DJ = DungeonJournal
local function check(cond, msg) if not cond then error("CHECK FAILED: " .. msg, 2) end end

FireEvent("ADDON_LOADED", "DungeonJournal")
FireEvent("PLAYER_LOGIN")
check(DJ.db and DJ.cdb, "saved variables initialised")

-- Open / home page, every expansion and kind
SlashCmdList.DUNGEONJOURNAL("")
check(DungeonJournalFrame:IsShown(), "journal opens")
check(DJ.CurrentPage() == "home", "home page first")
for exp = 0, 2 do
    for _, kind in ipairs({ "dungeon", "raid" }) do
        DJ.db.lastExpansion, DJ.db.lastKind = exp, kind
        DJ.pages.home:Refresh()
        AdvanceTime(0.2)
    end
end

-- Every instance, boss, mode and map
local bosses, pages = 0, 0
for _, inst in ipairs(DJ.Instances) do
    DJ.OpenInstance(inst)
    local page = DJ.pages.instance
    check(page.inst == inst, "instance page shows " .. inst.name)
    for _, mode in ipairs(inst.modes) do
        page:SetMode(mode)
        for _, boss in ipairs(page.bosses) do
            page:SelectBoss(boss.index)
            bosses = bosses + 1
            pages = pages + 1
            AdvanceTime(0.5)
        end
    end
    page:SetTab("map")
    check(page.mapKind == "retail", "dungeon map shown first for " .. inst.name)
    local floors = DJ.DungeonMaps[inst.key]
    for f = 1, #floors do page:ShowFloor(f) end
    check(page.floor == #floors, "floors for " .. inst.name)
    if inst.maps then
        for i = 1, #inst.maps do page:ShowMap(i) end
        check(page.mapKind == "atlas", "atlas map for " .. inst.name)
        page:ShowMap("retail")
    end
    page:SetTab("loot")
end
print(string.format("visited %d instances, %d boss pages", #DJ.Instances, pages))

-- Abilities view
local withAbilities = 0
for _, inst in ipairs(DJ.Instances) do
    DJ.OpenInstance(inst)
    local page = DJ.pages.instance
    for _, boss in ipairs(page.bosses) do
        page:SelectBoss(boss.index)
        page:SetView("abilities")
        if page.view == "abilities" then withAbilities = withAbilities + 1 end
    end
end
print("boss pages with an Abilities view:", withAbilities)
check(withAbilities > 400, "abilities shown for most bosses")
DJ.OpenInstance("Ragefire", 1)
check(DJ.pages.instance.view == "abilities", "abilities view is remembered")
local rows = 0
for _, f in ipairs(AllFrames()) do if rawget(f, "spell") and f:IsVisible() then rows = rows + 1 end end
check(rows >= 2, "Taragaman ability rows shown (" .. rows .. ")")
DJ.pages.instance:SetView("loot")

-- Item requests resolve and refresh
for i = 1, 200 do AdvanceTime(0.2) end

-- Back button and history
DJ.ShowHome()
DJ.OpenInstance("IcecrownCitadel", 11, "R25H")
check(DJ.pages.instance.mode == "R25H", "ICC opens on 25 heroic")
local rendered, models = 0, 0
for _, f in ipairs(AllFrames()) do
    if rawget(f, "itemID") and f:IsVisible() then rendered = rendered + 1 end
    local t = rawget(f, "texture")
    if type(t) == "string" and t:find("Bosses") and f:IsVisible() then models = models + 1 end
end
print("visible item rows on ICC Sindragosa 25H:", rendered, "boss portraits:", models)
check(rendered >= 10, "loot rows rendered")
check(models >= 5, "boss portraits rendered")
DJ.GoBack()
check(DJ.CurrentPage() == "home", "back returns home")

-- Faction-specific loot (Horde in the mock)
local toc = DJ.GetInstance("TrialoftheCrusader")
local beasts = toc.bosses[1]
check(beasts.loot.R10.A and beasts.loot.R10.H, "ToC loot is split by faction")
check(DJ.GetLoot(beasts, "R10") == beasts.loot.R10.H, "Horde sees Horde loot")

-- Search
DJ.ShowSearch("item 3")
check(DJ.CurrentPage() == "search", "search page")
local results = DJ.Search("icecrown")
check(#results > 0, "search finds Icecrown")
check(results[1].kind == "instance", "instance result first")
local r = DJ.Search("Marrowgar")
check(r[1] and r[1].kind == "boss", "boss search")
SlashCmdList.DUNGEONJOURNAL("icc")
check(DJ.pages.instance.inst.key == "IcecrownCitadel", "/dj icc")
SlashCmdList.DUNGEONJOURNAL("brd")
check(DJ.pages.instance.inst.key == "BlackrockDepths", "/dj brd")
SlashCmdList.DUNGEONJOURNAL("search sword")
SlashCmdList.DUNGEONJOURNAL("help")

-- Favourites
local item = DJ.GetLoot(DJ.GetInstance("Ragefire").bosses[1], "N")[1]
DJ.ToggleFavourite(item, DJ.GetInstance("Ragefire").bosses[1], "N")
check(DJ.IsFavourite(item), "favourite added")
DJ.ToggleFavourites()
check(DungeonJournalFavourites:IsShown(), "favourites window")
DJ.ToggleFavourite(item)
check(not DJ.IsFavourite(item), "favourite removed")

-- Loot filter
DJ.db.filter.classOnly = true
DJ.db.filter.hideRecipes = true
DJ.db.filter.armor.Cloth = true
DJ.Fire("FILTER_CHANGED")
DJ.OpenInstance("NaxxramasWrath", 1, "R25")
local shown = 0
for _, id in ipairs(DJ.GetLoot(DJ.GetInstance("NaxxramasWrath").bosses[1], "R25")) do
    if type(id) == "number" and DJ.PassesFilter(id) then shown = shown + 1 end
end
print("Naxx 25 Anub'Rekhan items passing a priest/cloth filter:", shown)
DJ.ToggleFilter()
DJ.db.filter.classOnly, DJ.db.filter.hideRecipes = false, false
wipe(DJ.db.filter.armor)
DJ.Fire("FILTER_CHANGED")

-- Tooltip source line
GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
GameTooltip:SetHyperlink("item:50274:0:0:0:0:0:0:0")
GameTooltip.scripts.OnTooltipSetItem = GameTooltip.scripts.OnTooltipSetItem
local _, link = GameTooltip:GetItem()
check(link, "tooltip has an item")
local srcs = DJ.ItemSources(50274)
check(srcs and #srcs > 0, "Shadowfrost Shard has sources")

-- Current instance detection
INSTANCE = { "Icecrown Citadel", "raid", 4 }
local inst, mode = DJ.CurrentInstance()
check(inst and inst.key == "IcecrownCitadel" and mode == "R25H", "current instance ICC 25H")
INSTANCE = { "Scarlet Monastery", "party", 1, "Athenaeum" }
inst = DJ.CurrentInstance()
check(inst and inst.key == "ScarletMonasteryLibrary", "SM library by subzone")
INSTANCE = { "Utgarde Keep", "party", 2 }
inst, mode = DJ.CurrentInstance()
check(inst and inst.key == "UtgardeKeep" and mode == "H", "UK heroic")
INSTANCE = { "The Temple of Atal'Hakkar", "party", 1 }
check(DJ.CurrentInstance().key == "TheTempleOfAtal'Hakkar", "sunken temple by client name")
INSTANCE = nil

-- Options, minimap, scale, close
DJ.OpenOptions()
OPTIONS_PANEL.refresh()
DJ.SetScale(1.2)
DJ.ResetPosition()
Click(DungeonJournalMinimapButton, "LeftButton")
Click(DungeonJournalMinimapButton, "LeftButton")
DungeonJournal_Toggle()
DungeonJournal_Toggle()

-- Instances that should have every expected mode
local function modes(key) return table.concat(DJ.GetInstance(key).modes, ",") end
check(modes("IcecrownCitadel") == "R10,R25,R10H,R25H", "ICC modes " .. modes("IcecrownCitadel"))
check(modes("NaxxramasWrath") == "R10,R25", "Naxx modes " .. modes("NaxxramasWrath"))
check(modes("VaultofArchavon") == "R10,R25", "VoA modes")
check(modes("UtgardeKeep") == "N,H", "UK modes")
check(modes("HellfireRamparts") == "N,H", "Ramparts modes")
check(modes("MoltenCore") == "N", "MC modes")
print("art:", DJ.SetCoverArt(CreateFrame("Frame"):CreateTexture(), DJ.GetInstance("UtgardeKeep")),
    DJ.SetCoverArt(CreateFrame("Frame"):CreateTexture(), DJ.GetInstance("IcecrownCitadel")))
print("ALL CHECKS PASSED")
