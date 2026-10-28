"""Write DungeonJournal/Data/DungeonMaps.lua: retail-style dungeon maps from a client patch.

The 3.3.5a world map draws a dungeon floor from 12 tiles,
Interface\\WorldMap\\<folder>\\<base><floor>_<1..12> (or <base><1..12> for single maps).
Input is the patch MPQ's (listfile); instances map to WorldMap folders below.

    python3 tools/dungeonmaps.py patch-M-listfile.txt DungeonJournal/Data/DungeonMaps.lua
"""
import collections, re, sys

# instance key -> (WorldMap folder, floor shown first); Ulduar also uses the Ulduar77 folder.
FOLDERS = {
    'Ragefire': ('Ragefire', 1), 'WailingCaverns': ('WailingCaverns', 1), 'TheDeadmines': ('TheDeadmines', 1),
    'ShadowfangKeep': ('ShadowfangKeep', 1), 'BlackfathomDeeps': ('BlackFathomDeeps', 1), 'TheStockade': ('TheStockade', 1),
    'Gnomeregan': ('Gnomeregan', 1), 'RazorfenKraul': ('RazorfenKraul', 1),
    'ScarletMonasteryGraveyard': ('ScarletMonastery', 1), 'ScarletMonasteryLibrary': ('ScarletMonastery', 2),
    'ScarletMonasteryArmory': ('ScarletMonastery', 3), 'ScarletMonasteryCathedral': ('ScarletMonastery', 4),
    'RazorfenDowns': ('RazorfenDowns', 1), 'Uldaman': ('Uldaman', 1), "Zul'Farrak": ('ZulFarrak', 1),
    'Maraudon': ('Maraudon', 1), "TheTempleOfAtal'Hakkar": ('TheTempleOfAtalHakkar', 1),
    'BlackrockDepths': ('BlackrockDepths', 1), 'LowerBlackrockSpire': ('BlackrockSpire', 1),
    'UpperBlackrockSpire': ('BlackrockSpire', 1), 'DireMaulEast': ('DireMaul', 1), 'DireMaulWest': ('DireMaul', 1),
    'DireMaulNorth': ('DireMaul', 1), 'Scholomance': ('Scholomance', 1), 'Stratholme': ('Stratholme', 1),
    'MoltenCore': ('MoltenCore', 1), 'BlackwingLair': ('BlackwingLair', 1), "Zul'Gurub": ('ZulGurub', 1),
    'TheRuinsofAhnQiraj': ('RuinsofAhnQiraj', 1), 'TheTempleofAhnQiraj': ('AhnQiraj', 1),
    'HellfireRamparts': ('HellfireRamparts', 1), 'TheBloodFurnace': ('TheBloodFurnace', 1),
    'TheShatteredHalls': ('TheShatteredHalls', 1), 'TheSlavePens': ('TheSlavePens', 1), 'TheUnderbog': ('TheUnderbog', 1),
    'TheSteamvault': ('TheSteamvault', 1), 'Mana-Tombs': ('ManaTombs', 1), 'AuchenaiCrypts': ('AuchenaiCrypts', 1),
    'SethekkHalls': ('SethekkHalls', 1), 'ShadowLabyrinth': ('ShadowLabyrinth', 1),
    'OldHillsbradFoothills': ('CoTHillsbradFoothills', 1), 'TheBlackMorass': ('CoTTheBlackMorass', 1),
    'TheMechanar': ('TheMechanar', 1), 'TheBotanica': ('TheBotanica', 1), 'TheArcatraz': ('TheArcatraz', 1),
    'MagistersTerrace': ('MagistersTerrace', 1), 'Karazhan': ('Karazhan', 1), 'ZulAman': ('ZulAman', 1),
    'GruulsLair': ('GruulsLair', 1), 'MagtheridonsLair': ('Magtheridonslair', 1),
    'SerpentshrineCavern': ('CoilfangReservoir', 1), 'TempestKeep': ('TempestKeep', 1), 'HyjalSummit': ('CoTMountHyjal', 1),
    'BlackTemple': ('BlackTemple', 1), 'SunwellPlateau': ('SunwellPlateau', 1),
    'UtgardeKeep': ('UtgardeKeep', 1), 'TheNexus': ('TheNexus', 1), 'AzjolNerub': ('AzjolNerub', 1),
    'AhnKahet': ('AhnKahet', 1), 'DrakTharonKeep': ('DrakTharonKeep', 1), 'VioletHold': ('VioletHold', 1),
    'Gundrak': ('GunDrak', 1), 'HallsofStone': ('HallsofStone', 1), 'HallsofLightning': ('HallsofLightning', 1),
    'TheOculus': ('TheOculus', 1), 'UtgardePinnacle': ('UtgardePinnacle', 1),
    'TheCullingOfStratholme': ('TheCullingofStratholme', 1), 'TrialoftheChampion': ('TheArgentColiseum', 1),
    'TrialoftheCrusader': ('TheArgentColiseum', 1), 'ForgeOfSouls': ('TheForgeofSouls', 1),
    'PitOfSaron': ('PitofSaron', 1), 'HallsOfReflection': ('HallsofReflection', 1), 'NaxxramasWrath': ('Naxxramas', 1),
    'ObsidianSanctum': ('TheObsidianSanctum', 1), 'TheEyeOfEternity': ('TheEyeOfEternity', 1),
    'VaultofArchavon': ('VaultofArchavon', 1), 'Ulduar': ('Ulduar', 1), 'WrathOnyxiasLair': ('OnyxiasLair', 1),
    'IcecrownCitadel': ('IcecrownCitadel', 1), 'RubySanctum': ('TheRubySanctum', 1),
}
EXTRA = {'Ulduar': ['Ulduar77']}

files = collections.defaultdict(list)
for line in open(sys.argv[1], encoding='latin-1'):
    p = line.strip().split('\\')
    if len(p) == 4 and p[0].lower() == 'interface' and p[1].lower() == 'worldmap':
        files[p[2].lower()].append(p[3])


def floors_of(folder):
    """[(base, floor or None)] for a WorldMap folder; floors need all 12 tiles."""
    floored = collections.defaultdict(lambda: collections.defaultdict(set))
    names, plain = {}, collections.defaultdict(set)
    for f in files[folder.lower()]:
        m = re.match(r'(?i)(.+?)(\d+)_(\d+)\.blp$', f)
        if m:
            floored[m.group(1).lower()][int(m.group(2))].add(int(m.group(3)))
            names[m.group(1).lower()] = m.group(1)
            continue
        m = re.match(r'(?i)([a-z]+?)(\d+)\.blp$', f)
        if m:
            plain[m.group(1).lower()].add(int(m.group(2)))
            names.setdefault(m.group(1).lower(), m.group(1))
    if floored:
        base = max(floored, key=lambda b: len(floored[b]))
        return [(names[base], n) for n in sorted(floored[base]) if floored[base][n] == set(range(1, 13))]
    base = max(plain, key=lambda b: len(plain[b]))
    return [(names[base], None)] if plain[base] >= set(range(1, 13)) else []


out = ['-- Generated by tools/dungeonmaps.py from the retail-style map patch (patch-M.mpq).',
       '-- Each floor: { WorldMap folder, file base, floor number or false for single-floor maps }.',
       'local DJ = DungeonJournal', 'DJ.DungeonMaps = {']
for key, (folder, start) in FOLDERS.items():
    floors = [(folder, b, n) for b, n in floors_of(folder)]
    for extra in EXTRA.get(key, []):
        floors += [(extra, b, n) for b, n in floors_of(extra)]
    if not floors:
        print('no map for', key)
        continue
    parts = ', '.join('{ "%s", "%s", %s }' % (f, b, n if n is not None else 'false') for f, b, n in floors)
    key_lua = key if re.match(r'^[A-Za-z_]\w*$', key) else '["%s"]' % key.replace("'", "\\'")
    out.append('    %s = { start = %d, %s },' % (key_lua, start, parts))
out.append('}')
open(sys.argv[2], 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print(len(out) - 5, 'instances with dungeon maps')
