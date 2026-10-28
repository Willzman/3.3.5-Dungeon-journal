"""Static parser for AtlasLoot Enhanced v5.11.04 (3.3.5a) loot tables (no Lua execution).
Output: {"tables": {key: [[slot, itemID, name, quality, desc, drop], ...]}, "items": {id: [name, q, desc]}}"""
import re, json, sys, os
from parse_al import tokenize, P

base, out = sys.argv[1], sys.argv[2]

# Token -> English text, from Core/TextParsing.lua
tokens = {}
CLASSES = {'DEATHKNIGHT': 'Death Knight'}
for line in open(os.path.join(base, 'AtlasLoot/Core/TextParsing.lua'), encoding='utf-8'):
    m = re.search(r'gsub\(text, "(#[^"]+#)", (.*?)\);\s*(?:--\s*(.*))?$', line)
    if not m:
        continue
    tok, expr, comment = m.groups()
    s = re.search(r'\["([^"]*)"\]', expr)
    if 'GetSpellInfo' in expr and comment:
        tokens[tok] = comment.strip()
    elif 'LOCALIZED_CLASS_NAMES' in expr and s:
        tokens[tok] = CLASSES.get(s.group(1), s.group(1).title())
    elif s:
        tokens[tok] = s.group(1)
    elif expr.startswith('"'):
        tokens[tok] = expr.strip('"')


def detok(t):
    t = re.sub(r'#[a-zA-Z0-9_]+#', lambda m: tokens.get(m.group(), ''), t)
    t = re.sub(r'=q\d=|=ds=|=ec\d=|\|c[0-9a-fA-F]{8}|\|r', '', t)
    return re.sub(r'\s+', ' ', t).strip(' ,')


def text(v):
    if isinstance(v, str):
        return v
    if isinstance(v, dict):
        if 'index' in v:
            k = v['index'][1]
            return k if isinstance(k, str) else ''
        if 'concat' in v:
            return ''.join(text(x) for x in v['concat'])
    if isinstance(v, (int, float)):
        return str(v)
    return ''


tables, items = {}, {}
files = ['AtlasLoot_OriginalWoW/originalwow.lua', 'AtlasLoot_BurningCrusade/burningcrusade.lua',
         'AtlasLoot_WrathoftheLichKing/wrathofthelichking.lua', 'AtlasLoot_WorldEvents/worldevents.lua',
         'AtlasLoot_Crafting/crafting.lua']
for fn in files:
    toks = tokenize(open(os.path.join(base, fn), encoding='utf-8-sig').read())
    i = 0
    while i < len(toks):
        if toks[i][1] == 'AtlasLoot_Data' and toks[i + 1][1] == '[' and toks[i + 3][1] == ']' and toks[i + 4][1] == '=':
            key = toks[i + 2][1]
            p = P(toks, i + 5)
            t = p.expr()
            i = p.i
            arr = t.get('__array', []) if isinstance(t, dict) else t
            rows = []
            for e in arr:
                if not isinstance(e, list) or len(e) < 4:
                    continue
                slot, iid = e[0], e[1]
                raw_name = text(e[3])
                q = re.match(r'=q(\d)=', raw_name)
                q = int(q.group(1)) if q else None
                name = detok(raw_name)
                desc = detok(text(e[4])) if len(e) > 4 else ''
                drop = text(e[6]) if len(e) > 6 else ''
                if isinstance(iid, str) and iid.startswith('s'):
                    continue  # crafting spell entries
                if not isinstance(iid, int):
                    continue
                rows.append([slot, iid, name, q, desc, drop])
                if iid > 0 and q is not None and name and fn.find('Crafting') < 0:
                    items.setdefault(iid, [name, q, desc])
            tables[key] = rows
            continue
        i += 1
    print(fn, len(tables))
json.dump({'tables': tables, 'items': items}, open(out, 'w'), ensure_ascii=False)
print('items', len(items))
