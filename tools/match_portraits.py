"""Match journal boss names to Encounter Journal portraits in a Gethe/wow-ui-textures checkout.

    python3 tools/match_portraits.py <wow-ui-textures checkout> DungeonJournal/Data/Instances.lua portraits.json
"""
import re, json, subprocess, sys
def norm(s): return re.sub(r'[^a-z0-9]', '', s.lower())
files = subprocess.check_output(['git', '-C', sys.argv[1], 'ls-tree', '-r', '--name-only', 'HEAD'], text=True).splitlines()
ej = {}
for f in files:
    m = re.match(r'(?i)ENCOUNTERJOURNAL/UI-EJ-BOSS-(.*)\.PNG$', f)
    if m: ej.setdefault(norm(m.group(1)), f)
ALIAS = {
    "Shadowpriest Sezz'ziz": ['shadowpriest sezzizz'], 'Emperor Dagran Thaurissan': ['emperor thaurissan'],
    'Baron Rivendare': ['lord aurius rivendare'], 'Cannon Master Willey': ['willey hopebreaker'],
    'Malor the Zealous': ['commander malor'], 'The Illidari Council': ['illidari council'],
    'The Tribunal of Ages': ['tribunal of the ages'], 'Wrath of the Lich King': ['the lich king', 'lich king'],
    'The Four Horsemen': ['four horseman', 'four horsemen'], 'The Beasts of Northrend': ['northrend beasts'],
    "The Twin Val'kyr": ['twin valkyr'], 'Reliquary of the Lost': ['reliquary of souls'],
    'The Iron Council': ['assembly of iron'], 'Bug Trio': ['silithid royalty'],
    'The Wizard of Oz': ['opera hall wikket', 'opera'], 'The Big Bad Wolf': ['opera'], 'Romulo and Julianne': ['opera'],
}
FACTION = {'Grand Champions': ('grand champions-alliance', 'grand champions-horde'),
           'Icecrown Gunship Battle': ('gunship alliance', 'gunship horde'),
           'Chess Event': ('chess alliance', 'chess horde')}
src = open(sys.argv[2], encoding='utf-8').read()
names = set()
for m in re.finditer(r'\{ name = "((?:[^"\\]|\\.)*)"(, factionName = \{[^}]*\})?((?:, (?:extra|trash|rare) = true)*)', src):
    if 'extra' not in m.group(3): names.add(m.group(1).replace("\\'", "'"))
out, miss = {}, []
for b in sorted(names):
    if b in FACTION:
        a, h = (ej.get(norm(x)) for x in FACTION[b])
        if a and h: out[b] = {'A': a, 'H': h}; continue
    cands = ALIAS.get(b, []) + [b] + re.split(r' / | & | and ', b)
    hit = next((ej[norm(c)] for c in cands if norm(c) in ej), None)
    if hit: out[b] = hit
    else: miss.append(b)
print(len(names), 'bosses,', len(out), 'with portraits')
print('no portrait:', '; '.join(miss))
json.dump(out, open(sys.argv[3], 'w'), indent=1)
