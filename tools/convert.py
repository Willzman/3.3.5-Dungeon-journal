"""Build the 3.3.5a journal's Data/Instances.lua and Data/Items.lua.

Inputs:
  al_raw.json  - AtlasLootClassic boss/loot tables (parse_al.py)
  enh.json     - AtlasLoot Enhanced v5.11.04 (3.3.5a) tables + item names (parse_enh.py)
"""
import json, sys, re
from meta import INSTANCES, EXTRA_NPC, OVERRIDES, MAPS

MAX_ITEM_ID = 56806  # highest item ID shipped with the 3.3.5a (12340) client

raw = json.load(open(sys.argv[1], encoding='utf-8'))
enh = json.load(open(sys.argv[2], encoding='utf-8'))
atlas = json.load(open(sys.argv[3], encoding='utf-8'))
out_dir = sys.argv[4]
map_files = set()
report = []

DIFF_MAP = {
    'NORMAL_DIFF': 'N', 'HEROIC_DIFF': 'H',
    'RAID10_DIFF': 'R10', 'RAID10H_DIFF': 'R10H', 'RAID25_DIFF': 'R25', 'RAID25H_DIFF': 'R25H',
}


class Ev:
    """Evaluates the parsed AtlasLootClassic expressions for the Wrath game version."""

    def __init__(self, locs):
        self.locs = locs

    def __call__(self, n):
        if isinstance(n, list):
            return [self(x) for x in n]
        if not isinstance(n, dict):
            return n
        if 'ref' in n:
            r = n['ref']
            v = self.locs.get(r)
            if v is not None and (not isinstance(v, (dict, list)) or (isinstance(v, dict) and ('concat' in v or 'call' in v))):
                return self(v)
            return {'unresolved': r}
        if 'index' in n:
            base, key = n['index']
            if base in ({'ref': 'AL'}, {'ref': 'ALIL'}):
                return self(key)
            if isinstance(base, dict) and base.get('ref') == 'AtlasLoot':
                return {'al': key}
            return {'unresolved': json.dumps(n)[:80]}
        if 'concat' in n:
            parts = [self(x) for x in n['concat']]
            return ''.join(str(p) for p in parts if isinstance(p, (str, int)) and not isinstance(p, bool))
        if 'call' in n:
            fn, args = n['call']
            args = [self(a) for a in args]
            fname = fn.get('ref') if 'ref' in fn else (fn['index'][1] if 'index' in fn else None)
            if fname in ('GetForVersion', 'ReturnForGameVersion'):
                for a in reversed(args):
                    if a is not None:
                        return a
                return None
            if fname == 'GetRetByFaction':
                return {'__faction': {'H': args[0], 'A': args[1] if len(args) > 1 else None}}
            if fname and fname.startswith('GameVersion_'):
                ver = {'CLASSIC_VERSION_NUM': 1, 'BC_VERSION_NUM': 2, 'WRATH_VERSION_NUM': 3}.get(
                    args[0].get('al') if isinstance(args[0], dict) else None, 3)
                ok = {'EQ': 3 == ver, 'NE': 3 != ver, 'GT': 3 > ver, 'LT': 3 < ver, 'GE': 3 >= ver, 'LE': 3 <= ver}[fname[-2:]]
                return (args[1] if len(args) > 1 else True) if ok else (args[2] if len(args) > 2 else None)
            if args and isinstance(args[0], str) and '%' in args[0]:
                vals = [a if isinstance(a, (str, int, float)) else '' for a in args[1:]]
                try:
                    return args[0] % tuple(vals[:args[0].count('%')])
                except Exception:
                    return args[0]
            if fname == 'format' and args and isinstance(args[0], str):
                return args[0]
            return {'unresolved_call': fname}
        return {k: self(v) for k, v in n.items()}


def clean(s):
    if not isinstance(s, str):
        return None
    s = re.sub(r'\|c[0-9a-fA-F]{8}|\|r', '', s).strip()
    return s or None


def tidy(entries):
    """Drop headers with nothing under them and duplicate items."""
    out, seen = [], set()
    for e in entries:
        if isinstance(e, int):
            if e in seen:
                continue
            seen.add(e)
        out.append(e)
    res = []
    for i, e in enumerate(out):
        if isinstance(e, str):
            nxt = out[i + 1] if i + 1 < len(out) else None
            if not isinstance(nxt, int):
                continue
            if res and res[-1] == e:
                continue
        res.append(e)
    return res


def keep_item(iid, where):
    if iid > MAX_ITEM_ID:
        if iid < 1000000:
            report.append('dropped item %d (not in the 3.3.5a client) from %s' % (iid, where))
        return False
    return True


def al_list(entries, where):
    res = []
    if isinstance(entries, dict) and '__array' in entries:
        entries = entries['__array']
    if not isinstance(entries, list):
        return res
    for e in sorted((e for e in entries if isinstance(e, (list, dict))),
                    key=lambda e: (e.get('__array') if isinstance(e, dict) else e)[0]):
        arr = e.get('__array') if isinstance(e, dict) else e
        if not isinstance(arr, list) or len(arr) < 2:
            continue
        iid = arr[1]
        if isinstance(iid, int) and not isinstance(iid, bool):
            if keep_item(iid, where):
                res.append(iid)
        elif isinstance(iid, str) and len(arr) > 3 and clean(arr[3]):
            res.append(clean(arr[3]))
    return tidy(res)


def enh_list(keys, where, pvp_right=False):
    res = []
    for k in keys:
        rows = enh['tables'].get(k)
        if rows is None:
            report.append('missing Enhanced table %s (%s)' % (k, where))
            continue
        for slot, iid, name, q, desc, drop in sorted(rows, key=lambda r: r[0]):
            if iid == 0:
                if name:
                    label = name.title().replace('Deathknight', 'Death Knight') if name.isupper() else name
                    if desc:
                        label += ' - ' + desc
                    if pvp_right and slot >= 16:
                        label += ' (PvP)'
                    res.append(label)
            elif keep_item(iid, where):
                res.append(iid)
    return tidy(res)


def faction_split(keys):
    if keys and isinstance(keys[0], dict):
        return [k['A'] for k in keys], [k['H'] for k in keys]
    return None


def loot_from_override(spec, where):
    loot = {}
    pvp = where.startswith('Vault of Archavon')
    for mode, keys in spec.items():
        fs = faction_split(keys)
        if fs:
            a, h = enh_list(fs[0], where, pvp), enh_list(fs[1], where, pvp)
            loot[mode] = a if a == h else {'A': a, 'H': h}
        else:
            loot[mode] = enh_list(keys, where, pvp)
    return loot


# Wrath Classic phases changed which emblem heroic dungeons drop; on 3.3.5a it is Triumph.
EMBLEM_3_3_5 = {40752: 47241, 40753: 47241, 45624: 47241}


def fix_emblems(loot):
    def fix(lst):
        out = []
        for e in lst:
            e = EMBLEM_3_3_5.get(e, e) if isinstance(e, int) else e
            if e not in out or not isinstance(e, int):
                out.append(e)
        return out
    for m, v in loot.items():
        loot[m] = {'A': fix(v['A']), 'H': fix(v['H'])} if isinstance(v, dict) else fix(v)


def loot_from_al(boss, ev, where):
    loot = {}
    for k, v in boss.items():
        if not k.startswith('{'):
            continue
        d = DIFF_MAP.get(json.loads(k).get('ref'))
        if d is None:
            continue  # Titan Rune (Wrath Classic only) and helper difficulties
        v = ev(v)
        if isinstance(v, dict) and '__faction' in v:
            a = al_list(ev(v['__faction']['A']), where)
            h = al_list(ev(v['__faction']['H']), where)
            if a == h:
                if a:
                    loot[d] = a
            elif a or h:
                loot[d] = {'A': a, 'H': h}
        else:
            ids = al_list(v, where)
            if ids:
                loot[d] = ids
    return loot


def fit_modes(loot, modes):
    """Map loot keys onto the instance's modes."""
    if 'N' in loot and 'N' not in modes:
        # Raid extra lists (patterns, trash) share one table across sizes.
        base = loot.pop('N')
        for m in modes:
            loot.setdefault(m, base)
    return {m: loot[m] for m in modes if m in loot and loot[m]}


LEGEND_COLORS = {'blue': '|cff6666ff', 'grey': '|cffaaaaaa', 'green': '|cff66cc33', 'orange': '|cffcc9933',
                 'purple': '|cffb048f8', 'white': '|cffffffff', 'red': '|cffcc6666', 'yellow': '|cffffd200'}


def color_legend(t):
    t = re.sub(r'\{(\w+)\}', lambda m: LEGEND_COLORS.get(m.group(1), ''), t)
    return t.rstrip()


def lua_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


def lua_val(v):
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, str):
        return lua_str(v)
    if isinstance(v, list):
        return '{' + ', '.join(lua_val(x) for x in v) + '}'
    if isinstance(v, dict):
        parts = []
        for k, x in v.items():
            key = k if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', k) else '[' + lua_str(k) + ']'
            parts.append('%s = %s' % (key, lua_val(x)))
        return '{ ' + ', '.join(parts) + ' }'
    raise TypeError(repr(v))


def all_ids(loot):
    for v in loot.values():
        lists = [v['A'], v['H']] if isinstance(v, dict) else [v]
        for lst in lists:
            for e in lst:
                if isinstance(e, int):
                    yield e


used_items = set()
out = []
nb = 0
for meta in INSTANCES:
    src = raw[meta['file']]
    t = src['data'][meta['al']]
    ev = Ev(src['locals'])
    lr = ev(t.get('LevelRange'))
    entry = {'key': meta['al'], 'name': meta['name'], 'short': meta['short'], 'exp': meta['exp'],
             'kind': meta['kind'], 'size': meta['size'], 'zone': meta['zone']}
    maps = []
    for mk in MAPS.get(meta['al'], []):
        am = atlas[mk]
        maps.append({'file': mk, 'title': am['zone'],
                     'legend': [color_legend(l[0]) for l in am['legend']]})
        map_files.add(mk)
    main = atlas[MAPS[meta['al']][0]] if MAPS.get(meta['al']) else None
    if main and main['levels']:
        entry['levelRange'] = main['levels']
    elif isinstance(lr, list) and len(lr) == 3:
        entry['levelRange'] = '%d-%d' % (lr[1], lr[2])
    if main and main['minLevel'].isdigit():
        entry['minLevel'] = int(main['minLevel'])
    elif isinstance(lr, list) and len(lr) == 3:
        entry['minLevel'] = lr[0]
    legend_npcs = {}
    for mk in MAPS.get(meta['al'], []):
        for l in atlas[mk]['legend']:
            if len(l) > 1:
                nm = re.sub(r'^\{\w+\}\s*(?:[0-9A-Z\'-]+\)\s*)?', '', l[0]).strip()
                nm = re.sub(r'\s*[<(].*$', '', nm)
                legend_npcs.setdefault(nm.lower(), l[1])
    for k in ('faction', 'aliases', 'desc'):
        if meta.get(k):
            entry[k] = meta[k]
    over = OVERRIDES.get(meta['al'], {})
    bosses = []
    for b in t.get('items', []):
        if not isinstance(b, dict):
            continue
        name = ev(b.get('name'))
        faction_name = None
        if isinstance(name, dict) and '__faction' in name:
            faction_name = {'A': clean(name['__faction']['A']), 'H': clean(name['__faction']['H'])}
            name = '%s / %s' % (faction_name['A'], faction_name['H'])
        name = clean(name)
        if not name:
            continue
        where = '%s / %s' % (meta['name'], name)
        if name in over:
            if over[name] is None:
                continue
            loot = loot_from_override(over[name], where)
        else:
            loot = loot_from_al(b, ev, where)
        loot = fit_modes(loot, meta['modes'])
        if meta['exp'] == 2 and meta['kind'] == 'dungeon':
            fix_emblems(loot)
        if not loot:
            report.append('no 3.3.5a loot, skipped: ' + where)
            continue
        boss = {'name': name}
        if faction_name:
            boss['factionName'] = faction_name
        lname = name.lower()
        if lname in ('trash', 'trash mobs'):
            boss['name'] = 'Trash Drops'
            boss['trash'] = True
            boss['extra'] = True
        elif b.get('ExtraList') and 'npcID' not in b:
            boss['extra'] = True
        npc = ev(b.get('npcID'))
        if isinstance(npc, list):
            npc = npc[0] if npc else None
        if not npc and name in EXTRA_NPC:
            npc = EXTRA_NPC[name]
        if not npc and name.lower() in legend_npcs:
            npc = legend_npcs[name.lower()]
        if isinstance(npc, int):
            boss['npc'] = npc
        disp = ev(b.get('DisplayIDs'))
        if isinstance(disp, list) and disp and isinstance(disp[0], list) and disp[0] and isinstance(disp[0][0], int):
            boss['display'] = disp[0][0]
        lvl = ev(b.get('Level'))
        if isinstance(lvl, list):
            lvl = lvl[-1] if lvl else None
        if isinstance(lvl, int):
            boss['level'] = -1 if lvl >= 999 else lvl
        if b.get('specialType') == 'rare':
            boss['rare'] = True
        boss['loot'] = loot
        used_items.update(all_ids(loot))
        bosses.append(boss)
    bosses.sort(key=lambda x: (x.get('extra', False), x.get('trash', False)))
    entry['bosses'] = bosses
    if maps:
        entry['maps'] = maps
    nb += len(bosses)
    used = set()
    for bb in bosses:
        used.update(bb['loot'].keys())
    entry['modes'] = [m for m in meta['modes'] if m in used]
    out.append(entry)

hdr = ('-- Generated by tools/convert.py. Loot tables come from AtlasLootClassic and\n'
       '-- AtlasLoot Enhanced v5.11.04 (both GPL), filtered to the 3.3.5a client.\n'
       'local DJ = DungeonJournal\n')
with open(out_dir + '/Instances.lua', 'w', encoding='utf-8') as f:
    f.write(hdr + 'DJ.Instances = {\n')
    for e in out:
        f.write('    ' + lua_val(e) + ',\n')
    f.write('}\n')

missing = sorted(i for i in used_items if str(i) not in enh['items'])
with open(out_dir + '/Items.lua', 'w', encoding='utf-8') as f:
    f.write(hdr + '-- Offline fallback for items the client has not cached yet: { name, quality, slot/type }\n')
    f.write('DJ.ItemInfo = {\n')
    for iid in sorted(used_items):
        info = enh['items'].get(str(iid))
        if info:
            f.write('    [%d] = {%s, %d, %s},\n' % (iid, lua_str(info[0]), info[1], lua_str(info[2])))
    f.write('}\n')

json.dump(sorted(map_files), open('maps.json', 'w'))  # Atlas maps to copy into Media/Maps
print('instances', len(out), 'bosses', nb, 'distinct items', len(used_items), 'without offline info', len(missing))
print('\n'.join(report))
