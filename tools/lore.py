"""Write DungeonJournal/Data/Lore.lua: the retail Adventure Guide lore for instances and bosses.

Input: JournalInstance / JournalEncounter / JournalEncounterCreature CSV exports of the retail
client (e.g. maxdekrieger/wow-csv-from-db2s, build 10.1.7.51485), matched by name.

    python3 tools/lore.py <csv folder> DungeonJournal/Data/Instances.lua DungeonJournal/Data/Lore.lua
"""
import csv, os, re, sys

csv_dir, instances_lua, out_path = sys.argv[1:4]


def norm(s):
    return re.sub(r'[^a-z0-9]', '', s.lower())


def rows(name):
    return list(csv.DictReader(open(os.path.join(csv_dir, name), encoding='utf-8')))


journal_instances = rows('journalinstance.csv')
encounters = rows('journalencounter.csv')
creatures = rows('journalencountercreature.csv')

# Our instance key -> retail Adventure Guide instance name, where the names differ.
INSTANCE_NAMES = {
    'TheDeadmines': 'Deadmines', 'ScarletMonasteryGraveyard': 'Scarlet Monastery',
    'ScarletMonasteryCathedral': 'Scarlet Monastery', 'ScarletMonasteryLibrary': 'Scarlet Halls',
    'ScarletMonasteryArmory': 'Scarlet Halls', 'DireMaulEast': 'Dire Maul', 'DireMaulWest': 'Dire Maul',
    'DireMaulNorth': 'Dire Maul', "TheTempleOfAtal'Hakkar": "The Temple of Atal'hakkar",
    'HyjalSummit': 'The Battle for Mount Hyjal', 'TempestKeep': 'The Eye', 'NaxxramasWrath': 'Naxxramas',
    'WrathOnyxiasLair': "Onyxia's Lair", 'VioletHold': 'The Violet Hold', 'TheRuinsofAhnQiraj': "Ruins of Ahn'Qiraj",
    'TheTempleofAhnQiraj': "Temple of Ahn'Qiraj",
}
# Rebuilt in Cataclysm or Mists of Pandaria: the retail lore describes the later version of
# these instances and their bosses, so it is left out.
SKIP_INSTANCE_LORE = {"Zul'Gurub", 'ZulAman', 'Ragefire', 'TheDeadmines', 'ShadowfangKeep', 'Scholomance',
                      'ScarletMonasteryGraveyard', 'ScarletMonasteryLibrary', 'ScarletMonasteryArmory',
                      'ScarletMonasteryCathedral'}

# Boss names that changed in the retail guide.
BOSS_NAMES = {
    "Shadowpriest Sezz'ziz": 'Shadowpriest Sezzziz', 'Emperor Dagran Thaurissan': 'Emperor Dagran Thaurissan',
    'The Four Horsemen': 'The Four Horsemen', 'The Beasts of Northrend': 'The Northrend Beasts',
    'The Tribunal of Ages': 'Tribunal of Ages', 'Wrath of the Lich King': 'Escape from Arthas',
    'Grand Champions': 'Grand Champions', 'Icecrown Gunship Battle': 'Icecrown Gunship Battle',
    'The Iron Council': 'The Assembly of Iron', 'Bug Trio': 'Silithid Royalty', 'Reliquary of the Lost': 'Reliquary of Souls',
    'Baron Rivendare': 'Lord Aurius Rivendare', 'Cannon Master Willey': 'Willey Hopebreaker',
    'Malor the Zealous': 'Commander Malor', "The Twin Val'kyr": "Twin Val'kyr", 'Romulo and Julianne': 'Opera Hall',
    'The Wizard of Oz': 'Opera Hall', 'The Big Bad Wolf': 'Opera Hall', 'Chess Event': 'Chess Event',
}


def clean(text):
    text = (text or '').replace('\r', '').strip()
    text = re.sub(r'\$b|\$B', '\n', text)
    text = re.sub(r'\|c[0-9a-fA-F]{8}|\|r', '', text)
    return text


ji_by_name = {}
for r in journal_instances:
    # Prefer the row with text when a name appears twice; raids keep their (blank) row so
    # their encounters can still be matched.
    if r['Description_lang'].strip() or norm(r['Name_lang']) not in ji_by_name:
        ji_by_name[norm(r['Name_lang'])] = r

enc_by_instance = {}
for e in encounters:
    enc_by_instance.setdefault(e['JournalInstanceID'], []).append(e)
names_of_encounter = {}
for c in creatures:
    names_of_encounter.setdefault(c['JournalEncounterID'], set()).add(norm(c['Name_lang']))
enc_by_name = {}
for e in encounters:
    if e['Description_lang'].strip():
        for n in {norm(e['Name_lang'])} | names_of_encounter.get(e['ID'], set()):
            enc_by_name.setdefault(n, []).append(e)

# ---------------------------------------------------------------- our data
src = open(instances_lua, encoding='utf-8').read()
ours = []
for inst in re.finditer(r'\{ key = "((?:[^"\\]|\\.)*)", name = "((?:[^"\\]|\\.)*)".*?bosses = \{(.*?)\}, (?:maps|modes) = ', src):
    key, name = inst.group(1).replace("\\'", "'"), inst.group(2).replace("\\'", "'")
    bosses = []
    for b in re.finditer(r'\{ name = "((?:[^"\\]|\\.)*)"([^{]*?(?:factionName = \{[^}]*\}, )?[^{]*?)loot = ', inst.group(3)):
        bosses.append((b.group(1).replace("\\'", "'").replace('\\"', '"'), 'extra = true' in b.group(2)))
    ours.append((key, name, bosses))


def lua_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


inst_lore, boss_lore, missing_inst, missing_boss = {}, {}, [], []
for key, name, bosses in ours:
    ji = ji_by_name.get(norm(INSTANCE_NAMES.get(key, name)))
    if ji and ji['Description_lang'].strip() and key not in SKIP_INSTANCE_LORE:
        inst_lore[key] = clean(ji['Description_lang'])
    elif key not in SKIP_INSTANCE_LORE:
        missing_inst.append(name)
    local = enc_by_instance.get(ji['ID'], []) if ji else []
    for idx, (boss, extra) in enumerate(bosses, 1):
        if extra or key in SKIP_INSTANCE_LORE:
            continue
        wanted = [BOSS_NAMES.get(boss, boss)] + re.split(r' / | & | and ', boss)
        hit = None
        for w in wanted:
            n = norm(w)
            hit = next((e for e in local if e['Description_lang'].strip()
                        and (norm(e['Name_lang']) == n or n in names_of_encounter.get(e['ID'], ()))), None)
            if hit:
                break
        if hit:
            boss_lore['%s#%d' % (key, idx)] = clean(hit['Description_lang'])
        else:
            missing_boss.append(boss)

lines = ['-- Generated by tools/lore.py from the retail Adventure Guide (build 10.1.7.51485).',
         'local DJ = DungeonJournal', 'DJ.Lore = {', '    instances = {']
for k in sorted(inst_lore):
    lines.append('        [%s] = %s,' % (lua_str(k), lua_str(inst_lore[k])))
lines += ['    },', '    bosses = {']
for k in sorted(boss_lore):
    lines.append('        [%s] = %s,' % (lua_str(k), lua_str(boss_lore[k])))
lines += ['    },', '}']
open(out_path, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
print('instances with lore: %d of %d; bosses with lore: %d' % (len(inst_lore), len(ours), len(boss_lore)))
print('no instance lore:', missing_inst)
print('no boss lore (%d):' % len(missing_boss), '; '.join(missing_boss))
