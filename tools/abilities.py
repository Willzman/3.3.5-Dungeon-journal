"""Build DungeonJournal/Data/Abilities.lua: the spells each boss uses on 3.3.5a.

Sources (static parsing only):
  * DBM boss mods for 3.3.5a (TrinityCore wow_335a_addons): the abilities DBM warns about,
    and the creature IDs of each encounter (council fights list every member).
  * AzerothCore (3.3.5a server): spells creatures cast through SmartAI (smart_scripts) and
    through C++ boss scripts (DoCast*/CastSpell in the creature's AI).
The addon reads names, icons and descriptions from the game client's own spell data.

    python3 tools/abilities.py <tc checkout> <azerothcore checkout> DungeonJournal/Data/Instances.lua DungeonJournal/Data/Abilities.lua
"""
import collections, glob, os, re, sys

tc, ac, instances_lua, out_path = sys.argv[1:5]

# ---------------------------------------------------------------- journal bosses
src = open(instances_lua, encoding='utf-8').read()
bosses = []  # (instance key, boss index, name, npc)
for inst in re.finditer(r'\{ key = "((?:[^"\\]|\\.)*)".*?bosses = \{(.*?)\}, (?:maps|modes) = ', src):
    key = inst.group(1).replace("\\'", "'")
    for i, b in enumerate(re.finditer(r'\{ name = "((?:[^"\\]|\\.)*)"[^{]*?(?:factionName = \{[^}]*\}, )?([^{]*?)loot = ', inst.group(2)), 1):
        npc = re.search(r'npc = (\d+)', b.group(0))
        extra = re.search(r'extra = true', b.group(0))
        bosses.append((key, i, b.group(1).replace("\\'", "'"), int(npc.group(1)) if npc else None, bool(extra)))

# ---------------------------------------------------------------- DBM
TIMER_SPELL_ARG2 = re.compile(r'^New\w*Timer$')
dbm = []  # (creature ids, [spell ids])
for path in glob.glob(os.path.join(tc, 'DBM', 'DBM-*', '**', '*.lua'), recursive=True):
    if 'DBM-Core' in path or 'DBM-GUI' in path or 'localization' in path.lower():
        continue
    text = open(path, encoding='utf-8', errors='replace').read()
    m = re.search(r'mod:SetCreatureID\(([^)]*)\)', text)
    if not m:
        continue
    cids = [int(x) for x in re.findall(r'\d+', m.group(1))]
    spells = []
    for c in re.finditer(r'mod:(New\w+)\(([^)]*)\)', text):
        ctor, args = c.group(1), [a.strip() for a in c.group(2).split(',')]
        if ctor in ('NewBerserkTimer', 'NewCombatTimer', 'NewTimer', 'NewAnnounce', 'NewSpecialWarning',
                    'NewPhaseAnnounce', 'NewPhaseTimer', 'NewMod', 'NewSound'):
            continue
        arg = args[1] if TIMER_SPELL_ARG2.match(ctor) and len(args) > 1 else args[0]
        if re.fullmatch(r'\d{3,6}', arg or '') and int(arg) not in spells:
            spells.append(int(arg))
    dbm.append((cids, spells))

def norm(s):
    return re.sub(r'[^a-z0-9]', '', s.lower())


# ---------------------------------------------------------------- AzerothCore: SQL helpers
def sql_rows(path, table):
    """Yield value tuples from INSERT INTO `table` VALUES (...),(...) dumps."""
    text = open(path, encoding='utf-8', errors='replace').read()
    for ins in re.finditer(r'INSERT INTO `%s` VALUES\s*(.*?);\n' % table, text, re.S):
        body = ins.group(1)
        i, n = 0, len(body)
        while i < n:
            if body[i] != '(':
                i += 1
                continue
            vals, cur, j, inq = [], '', i + 1, False
            while j < n:
                ch = body[j]
                if inq:
                    if ch == '\\':
                        cur += body[j + 1]; j += 2; continue
                    if ch == "'":
                        inq = False
                    else:
                        cur += ch
                elif ch == "'":
                    inq = True
                elif ch == ',':
                    vals.append(cur); cur = ''
                elif ch == ')':
                    vals.append(cur); break
                else:
                    cur += ch
                j += 1
            yield vals
            i = j + 1


db = os.path.join(ac, 'data', 'sql', 'base', 'db_world')
smart = collections.defaultdict(list)
label = {}  # spell ID -> name as written in the server scripts (only used for filtering)
for v in sql_rows(os.path.join(db, 'smart_scripts.sql'), 'smart_scripts'):
    entry, source, action, p1 = int(v[0]), int(v[1]), int(v[14]), int(v[15])
    if action in (11, 85, 86) and p1:
        m = re.search(r'Cast (.+)$', v[-1])
        if m:
            label.setdefault(p1, m.group(1))
    if entry > 0 and source == 0 and action in (11, 85, 86) and p1 and p1 not in smart[entry]:
        smart[entry].append(p1)

script_of = {}
heroic_of = collections.defaultdict(list)
name_of = {}
ids_by_name = collections.defaultdict(list)
for v in sql_rows(os.path.join(db, 'creature_template.sql'), 'creature_template'):
    entry = int(v[0])
    name_of[entry] = v[6]
    ids_by_name[norm(v[6])].append(entry)
    if v[-2]:
        script_of[entry] = v[-2]
    for d in v[1:4]:
        if int(d):
            heroic_of[entry].append(int(d))

# ---------------------------------------------------------------- AzerothCore: C++ boss scripts
CAST = re.compile(r'(?:DoCast\w*|CastSpell|AddAura)\s*\(([^;]*?)\)\s*;')
cpp_spells = {}
for path in glob.glob(os.path.join(ac, 'src', 'server', 'scripts', '**', '*.cpp'), recursive=True):
    text = open(path, encoding='utf-8', errors='replace').read()
    consts = {k: int(v) for k, v in re.findall(r'\b(SPELL_\w+)\s*=\s*(\d+)', text)}
    for k, v in consts.items():
        label.setdefault(v, k[6:].replace('_', ' ').title())
    for m in re.finditer(r'(?:struct|class)\s+(\w+?)(?:AI|_AI)?\s*(?::|\{)', text):
        name = m.group(1)
        start = m.end()
        nxt = re.search(r'\n(?:struct|class)\s+\w+', text[start:])
        seg = text[start:start + nxt.start()] if nxt else text[start:]
        spells = []
        for c in CAST.finditer(seg):
            for s in re.findall(r'\bSPELL_\w+', c.group(1)):
                if s in consts and consts[s] not in spells:
                    spells.append(consts[s])
        if spells:
            cpp_spells.setdefault(name.lower(), spells)


# Internal helper spells the server casts (passives, visuals, script triggers), by label.
INTERNAL = re.compile(r'(?i)\b(dual wield|clear all|emote|transform|visual|dummy|trigger|selector|periodic|'
                      r'channel|mount|marker|demonic circle|dummy|spawn|despawn|death|hit chance|kill credit|credit|cosmetic|invisib|'
                      r'stealth detect|immun|achievement|stun self|root self|self stun|force cast|script|'
                      r'aura$|bot\b|dnd|teleport (?:visual|effect)|evade|reset|cleanup|remove|'
                      r'ride|vehicle|player|camera|sound|kneel|sit|dance|ghost|feign)')


def keep(spell):
    name = label.get(spell)
    return not (name and INTERNAL.search(name))


def server_spells(npc):
    out = []
    for e in [npc] + heroic_of.get(npc, []):
        for s in smart.get(e, []):
            if s not in out:
                out.append(s)
    script = script_of.get(npc)
    if script and script != 'SmartAI':
        for key in (script.lower(), script.lower() + 'ai', script.lower() + '_ai'):
            for s in cpp_spells.get(key, []):
                if s not in out:
                    out.append(s)
    return out


# ---------------------------------------------------------------- combine
lines = ['-- Generated by tools/abilities.py from DBM (3.3.5a boss mods) and AzerothCore',
         '-- (3.3.5a server scripts): spell IDs each boss uses, most important first.',
         '-- Names, icons and descriptions come from the client at run time.',
         'local DJ = DungeonJournal', 'DJ.Abilities = {']
covered, total, from_dbm = 0, 0, 0
for key, idx, name, npc, extra in bosses:
    if extra or not npc:
        continue
    total += 1
    # Creature IDs of this boss: its own, plus creatures with its name (or each name of a
    # "A / B" or "A & B" page), which also catches DBM mods keyed on another creature.
    names = [name] + re.split(r' / | & | and ', name)
    ids = {npc}
    for n in names:
        if len(ids_by_name.get(norm(n), [])) <= 3:
            ids.update(ids_by_name.get(norm(n), []))
    mods = [m for m in dbm if ids & set(m[0])]
    spells = []
    cids = set(ids)
    for cids_m, sp in mods:
        cids.update(cids_m)
        spells += [s for s in sp if s not in spells]
    if spells:
        from_dbm += 1
    for c in sorted(cids, key=lambda c: c != npc):
        spells += [s for s in server_spells(c) if s not in spells and keep(s)]
    if not spells:
        continue
    covered += 1
    lines.append('    ["%s#%d"] = { %s },' % (key.replace("'", "\\'"), idx, ', '.join(map(str, spells[:24]))))
lines.append('}')
open(out_path, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
print('%d of %d bosses have abilities (%d with DBM)' % (covered, total, from_dbm))
missing = [n for k, i, n, npc, e in bosses if not e and npc and not any('"%s#%d"' % (k.replace("'", "\\'"), i) in l for l in lines)]
print('none for:', '; '.join(missing))
