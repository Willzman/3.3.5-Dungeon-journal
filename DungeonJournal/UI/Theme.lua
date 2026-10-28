-- Colour themes and cover art.
local DJ = DungeonJournal

local function Theme(frame, content, border, title, text, muted)
    return {
        frame = { frame[1], frame[2], frame[3], 0.98 },
        content = { content[1], content[2], content[3], 0.92 },
        border = { border[1], border[2], border[3], 1 },
        header = { content[1] * 1.1, content[2] * 1.1, content[3] * 1.1, 0.95 },
        left = { content[1] * 0.75, content[2] * 0.75, content[3] * 0.75, 0.94 },
        right = { content[1] * 0.85, content[2] * 0.85, content[3] * 0.85, 0.94 },
        row = { content[1] * 0.6, content[2] * 0.6, content[3] * 0.6, 0.92 },
        rowSelected = { border[1] * 0.6, border[2] * 0.6, border[3] * 0.6, 0.95 },
        lootRow = { content[1] * 0.7, content[2] * 0.7, content[3] * 0.7, 0.94 },
        title = title, text = text, muted = muted,
    }
end

DJ.THEMES = {
    -- Expansion defaults: parchment-brown classic, fel-green Outland, frost-blue Northrend.
    [0] = Theme({ 0.030, 0.024, 0.018 }, { 0.22, 0.16, 0.09 }, { 0.55, 0.40, 0.18 }, { 1.00, 0.82, 0.30 }, { 0.93, 0.86, 0.70 }, { 0.78, 0.70, 0.56 }),
    [1] = Theme({ 0.020, 0.028, 0.018 }, { 0.12, 0.19, 0.09 }, { 0.40, 0.62, 0.22 }, { 0.72, 1.00, 0.40 }, { 0.85, 0.93, 0.76 }, { 0.66, 0.76, 0.58 }),
    [2] = Theme({ 0.016, 0.022, 0.034 }, { 0.10, 0.15, 0.24 }, { 0.40, 0.60, 0.85 }, { 0.70, 0.88, 1.00 }, { 0.84, 0.90, 0.97 }, { 0.62, 0.70, 0.80 }),
    home = Theme({ 0.022, 0.020, 0.024 }, { 0.15, 0.13, 0.15 }, { 0.55, 0.45, 0.25 }, { 1.00, 0.82, 0.30 }, { 0.90, 0.88, 0.86 }, { 0.70, 0.68, 0.66 }),
}

local fire = Theme({ 0.032, 0.021, 0.016 }, { 0.24, 0.12, 0.055 }, { 0.55, 0.30, 0.10 }, { 1.00, 0.72, 0.24 }, { 0.95, 0.82, 0.64 }, { 0.82, 0.67, 0.52 })
local plague = Theme({ 0.018, 0.024, 0.018 }, { 0.12, 0.17, 0.11 }, { 0.42, 0.58, 0.30 }, { 0.74, 1.00, 0.52 }, { 0.84, 0.94, 0.80 }, { 0.64, 0.76, 0.62 })
local shadow = Theme({ 0.022, 0.020, 0.028 }, { 0.16, 0.13, 0.18 }, { 0.40, 0.31, 0.48 }, { 0.88, 0.78, 0.96 }, { 0.90, 0.86, 0.93 }, { 0.72, 0.67, 0.76 })
local arcane = Theme({ 0.024, 0.016, 0.040 }, { 0.17, 0.10, 0.27 }, { 0.58, 0.40, 0.86 }, { 0.90, 0.78, 1.00 }, { 0.91, 0.87, 0.97 }, { 0.74, 0.67, 0.84 })
local stone = Theme({ 0.018, 0.018, 0.020 }, { 0.13, 0.13, 0.14 }, { 0.42, 0.42, 0.44 }, { 0.92, 0.92, 0.94 }, { 0.86, 0.86, 0.88 }, { 0.66, 0.66, 0.69 })
local blood = Theme({ 0.030, 0.014, 0.014 }, { 0.22, 0.07, 0.07 }, { 0.62, 0.20, 0.18 }, { 1.00, 0.55, 0.45 }, { 0.95, 0.82, 0.80 }, { 0.80, 0.62, 0.60 })
local titan = Theme({ 0.020, 0.024, 0.030 }, { 0.14, 0.17, 0.21 }, { 0.70, 0.62, 0.36 }, { 1.00, 0.88, 0.50 }, { 0.88, 0.90, 0.92 }, { 0.68, 0.72, 0.76 })
local jungle = Theme({ 0.018, 0.026, 0.020 }, { 0.10, 0.18, 0.13 }, { 0.34, 0.56, 0.36 }, { 0.70, 0.96, 0.62 }, { 0.84, 0.92, 0.82 }, { 0.62, 0.74, 0.62 })
local sand = Theme({ 0.032, 0.026, 0.016 }, { 0.26, 0.20, 0.10 }, { 0.68, 0.54, 0.26 }, { 1.00, 0.86, 0.46 }, { 0.95, 0.88, 0.72 }, { 0.80, 0.72, 0.56 })
local sea = Theme({ 0.014, 0.024, 0.030 }, { 0.07, 0.17, 0.21 }, { 0.26, 0.58, 0.66 }, { 0.56, 0.92, 1.00 }, { 0.82, 0.92, 0.95 }, { 0.60, 0.72, 0.76 })

DJ.INSTANCE_THEMES = {
    Ragefire = fire, BlackrockDepths = fire, LowerBlackrockSpire = fire, UpperBlackrockSpire = fire,
    MoltenCore = fire, BlackwingLair = blood, HellfireRamparts = fire, TheBloodFurnace = blood,
    TheShatteredHalls = blood, MagtheridonsLair = fire, RubySanctum = blood, ObsidianSanctum = shadow,
    WailingCaverns = jungle, Maraudon = jungle, ["Zul'Gurub"] = jungle, ZulAman = jungle, Gundrak = jungle,
    DrakTharonKeep = plague, ["TheTempleOfAtal'Hakkar"] = jungle, TheBotanica = jungle, TheUnderbog = jungle,
    ShadowfangKeep = shadow, ShadowLabyrinth = shadow, AuchenaiCrypts = shadow, BlackTemple = shadow,
    Karazhan = arcane, MagistersTerrace = arcane, SunwellPlateau = arcane, TheEyeOfEternity = arcane,
    TheNexus = arcane, TheOculus = arcane, VioletHold = arcane, ["Mana-Tombs"] = arcane, TheArcatraz = arcane,
    TheStockade = stone, Uldaman = titan, HallsofStone = titan, HallsofLightning = titan, Ulduar = titan,
    VaultofArchavon = stone, ["Zul'Farrak"] = sand, TheRuinsofAhnQiraj = sand, TheTempleofAhnQiraj = sand,
    OldHillsbradFoothills = sand, TheBlackMorass = sand, HyjalSummit = jungle, TheCullingOfStratholme = sand,
    BlackfathomDeeps = sea, TheSlavePens = sea, TheSteamvault = sea, SerpentshrineCavern = sea,
    Gnomeregan = plague, Scholomance = plague, Stratholme = plague, NaxxramasWrath = plague, RazorfenDowns = plague,
    RazorfenKraul = sand, ScarletMonasteryGraveyard = stone, ScarletMonasteryLibrary = blood,
    ScarletMonasteryArmory = blood, ScarletMonasteryCathedral = blood,
}

function DJ.GetTheme(inst)
    if not inst then return DJ.THEMES.home end
    return DJ.INSTANCE_THEMES[inst.key] or DJ.THEMES[inst.exp] or DJ.THEMES.home
end

------------------------------------------------------------------------
-- Cover art. The 3.3.5a client ships Looking For Group art for its dungeons and
-- raids; the texture name comes from the client's LFG data, matched by name.
-- SetTexture returns nil for a missing file, so every candidate is tried in turn.
------------------------------------------------------------------------
local LFG_ALIASES = {
    DireMaulEast = { "diremaulwarpwoodquarter", "diremaul" },
    DireMaulWest = { "diremaulcapitalgardens", "diremaul" },
    DireMaulNorth = { "diremaulgordokcommons", "diremaul" },
    ["TheTempleOfAtal'Hakkar"] = { "sunkentemple", "templeofatalhakkar", "thetempleofatalhakkar" },
    OldHillsbradFoothills = { "oldhillsbradfoothills", "escapefromdurnholde" },
    TheBlackMorass = { "theblackmorass", "openingofthedarkportal" },
    TempestKeep = { "tempestkeep", "theeye" },
    NaxxramasWrath = { "naxxramas" },
    WrathOnyxiasLair = { "onyxiaslair" },
    AhnKahet = { "ahnkahettheoldkingdom", "ahnkahet" },
    TheStockade = { "thestockade", "stormwindstockade" },
    BlackrockDepths = { "blackrockdepths", "blackrockdepthsprison", "blackrockdepthsuppercity" },
    Stratholme = { "stratholme", "stratholmemaingate", "stratholmeserviceentrance" },
    Maraudon = { "maraudon", "maraudonpurpledrop", "maraudonorangeside" },
    TheRuinsofAhnQiraj = { "ruinsofahnqiraj" },
    TheTempleofAhnQiraj = { "templeofahnqiraj", "ahnqirajtemple" },
}

local lfgTextures
local function BuildLFGTextures()
    lfgTextures = {}
    -- GetLFGDungeonInfo(id): name, typeID, min, max, rec, minRec, maxRec, expansion, groupID, texture, ...
    if not GetLFGDungeonInfo then return end
    for id = 1, 500 do
        local ok, name, _, _, _, _, _, _, _, _, texture = pcall(GetLFGDungeonInfo, id)
        if ok and name and texture and texture ~= "" then
            local n = DJ.Normalize(name)
            if not lfgTextures[n] then lfgTextures[n] = texture end
        end
    end
end

local function LFGTextureFor(inst)
    if not lfgTextures then BuildLFGTextures() end
    local names = LFG_ALIASES[inst.key] or {}
    local mine = DJ.Normalize(inst.name)
    for _, n in ipairs(names) do
        if lfgTextures[n] then return lfgTextures[n] end
    end
    if lfgTextures[mine] then return lfgTextures[mine] end
    for n, tex in pairs(lfgTextures) do
        if string.find(n, mine, 1, true) == 1 or string.find(mine, n, 1, true) == 1 then
            return tex
        end
    end
    return nil
end

-- Art names shipped in Interface\LFGFrame of the 3.3.5a client (UI-LFG-BACKGROUND-<name>),
-- per instance. The LFG lookup above is only a fallback for anything missing here.
local ART = {
    Ragefire = "RAGEFIRECHASM", WailingCaverns = "WAILINGCAVERNS", TheDeadmines = "DEADMINES",
    ShadowfangKeep = "SHADOWFANGKEEP", BlackfathomDeeps = "BLACKFATHOMDEEPS", TheStockade = "STORMWINDSTOCKADES",
    Gnomeregan = "GNOMEREGAN", RazorfenKraul = "RAZORFENKRAUL", ScarletMonasteryGraveyard = "SCARLETMONASTERY",
    ScarletMonasteryLibrary = "SCARLETMONASTERY", ScarletMonasteryArmory = "SCARLETMONASTERY",
    ScarletMonasteryCathedral = "SCARLETMONASTERY", RazorfenDowns = "RAZORFENDOWNS", Uldaman = "ULDAMAN",
    ["Zul'Farrak"] = "ZULFARAK", Maraudon = "MARAUDON", ["TheTempleOfAtal'Hakkar"] = "SUNKENTEMPLE",
    BlackrockDepths = "BLACKROCKDEPTHS", LowerBlackrockSpire = "BLACKROCKSPIRE", UpperBlackrockSpire = "BLACKROCKSPIRE",
    DireMaulEast = "DIREMAUL", DireMaulWest = "DIREMAUL", DireMaulNorth = "DIREMAUL", Scholomance = "SCHOLOMANCE",
    Stratholme = "STRATHOLME", MoltenCore = "MOLTENCORE", BlackwingLair = "BLACKWINGLAIR", ["Zul'Gurub"] = "ZULGURUB",
    TheRuinsofAhnQiraj = "AQRUINS", TheTempleofAhnQiraj = "AQTEMPLE",
    HellfireRamparts = "HELLFIRECITADEL", TheBloodFurnace = "HELLFIRECITADEL", TheShatteredHalls = "HELLFIRECITADEL",
    TheSlavePens = "COILFANG", TheUnderbog = "COILFANG", TheSteamvault = "COILFANG",
    ["Mana-Tombs"] = "AUCHINDOUN", AuchenaiCrypts = "AUCHINDOUN", SethekkHalls = "AUCHINDOUN", ShadowLabyrinth = "AUCHINDOUN",
    OldHillsbradFoothills = "CAVERNSOFTIME", TheBlackMorass = "CAVERNSOFTIME",
    TheMechanar = "TEMPESTKEEP", TheBotanica = "TEMPESTKEEP", TheArcatraz = "TEMPESTKEEP",
    MagistersTerrace = "MAGISTERSTERRACE", Karazhan = "KARAZHAN", ZulAman = "ZULAMAN", GruulsLair = "GRUULSLAIR",
    MagtheridonsLair = "HELLFIRECITADELRAID", SerpentshrineCavern = "COILFANG", TempestKeep = "TEMPESTKEEP",
    HyjalSummit = "HYJALPAST", BlackTemple = "BLACKTEMPLE", SunwellPlateau = "SUNWELL",
    UtgardeKeep = "UTGARDE", TheNexus = "THENEXUS", AzjolNerub = "AZJOLNERUB", AhnKahet = "AHNKALET",
    DrakTharonKeep = "DRAKTHARON", VioletHold = "THEVIOLETHOLD", Gundrak = "GUNDRAK", HallsofStone = "HALLSOFSTONE",
    HallsofLightning = "HALLSOFLIGHTNING", TheOculus = "THEOCULUS", UtgardePinnacle = "UTGARDEPINNACLE",
    TheCullingOfStratholme = "CAVERNSOFTIME", TrialoftheChampion = "ARGENTDUNGEON", ForgeOfSouls = "THEFORGEOFSOULS",
    PitOfSaron = "PITOFSARON", HallsOfReflection = "HALLSOFREFLECTION", NaxxramasWrath = "NAXXRAMAS",
    ObsidianSanctum = "CHAMBEROFASPECTS", TheEyeOfEternity = "MALYGOS", VaultofArchavon = "VAULTOFARCHAVON",
    Ulduar = "ULDUAR", TrialoftheCrusader = "ARGENTRAID", WrathOnyxiasLair = "ONYXIAENCOUNTER",
    IcecrownCitadel = "ICECROWNCITADEL", RubySanctum = "CHAMBEROFASPECTS",
}

local artCache = {}
-- Sets the cover art of `inst` on `texture`; returns true when art was found.
function DJ.SetCoverArt(texture, inst)
    local cached = artCache[inst.key]
    if cached == false then return false end
    if cached then
        texture:SetTexture(cached[1])
        texture:SetTexCoord(unpack(cached[2]))
        return true
    end
    local candidates = {}
    for _, tex in ipairs({ ART[inst.key], LFGTextureFor(inst) }) do
        candidates[#candidates + 1] = { "Interface\\LFGFrame\\UI-LFG-BACKGROUND-" .. tex, { 0, 1, 0.04, 0.92 } }
    end
    for _, tex in ipairs({ ART[inst.key], LFGTextureFor(inst) }) do
        candidates[#candidates + 1] = { "Interface\\LFGFrame\\LFGIcon-" .. tex, { 0.08, 0.92, 0.08, 0.92 } }
    end
    for _, c in ipairs(candidates) do
        if texture:SetTexture(c[1]) then
            texture:SetTexCoord(unpack(c[2]))
            artCache[inst.key] = c
            return true
        end
    end
    artCache[inst.key] = false
    return false
end

-- Representative icons used when no cover art is available.
DJ.KIND_ICONS = {
    dungeon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_02",
    raid = "Interface\\Icons\\INV_Misc_MonsterHead_02",
}
