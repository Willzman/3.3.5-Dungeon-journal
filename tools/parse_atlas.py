"""Static parser for Atlas (3.3.5a) AtlasMaps.lua: map keys, zone info and legend lines."""
import json, sys, re
from parse_al import tokenize, P

src = open(sys.argv[1], encoding='utf-8-sig').read()
toks = tokenize(src)
COLORS = {}
res = {}
i = 0
while i < len(toks):
    if toks[i][1] == 'AtlasMaps' and toks[i + 1][1] == '=' and toks[i + 2][1] == '{':
        p = P(toks, i + 2)
        res = p.expr()
        break
    i += 1


def text(v):
    if isinstance(v, str):
        return v
    if isinstance(v, (int, float)) and not isinstance(v, bool):
        return str(v)
    if isinstance(v, dict):
        if 'index' in v:
            k = v['index'][1]
            return k if isinstance(k, str) else ''
        if 'concat' in v:
            return ''.join(text(x) for x in v['concat'])
        if 'ref' in v:
            return {'INDENT': '    ', 'BLUE': '{blue}', 'GREY': '{grey}', 'ORNG': '{orange}', 'GREN': '{green}',
                    'PURP': '{purple}', 'WHIT': '{white}', 'RED': '{red}', 'YELLOW': '{yellow}'}.get(v['ref'], '')
    return ''


out = {}
for key, m in res.items():
    if not isinstance(m, dict):
        continue
    zn = m.get('ZoneName')
    loc = m.get('Location')
    legend = []
    for row in m.get('__array', []):
        if isinstance(row, list) and row:
            t = text(row[0])
            npc = row[2] if len(row) > 2 and isinstance(row[2], int) else None
            legend.append([t, npc] if npc else [t])
    out[key] = {
        'zone': text(zn[0]) if isinstance(zn, list) else text(zn),
        'location': text(loc[0]) if isinstance(loc, list) and loc else None,
        'levels': text(m.get('LevelRange')), 'minLevel': text(m.get('MinLevel')),
        'players': text(m.get('PlayerLimit')), 'legend': legend,
    }
json.dump(out, open(sys.argv[2], 'w'), indent=1, ensure_ascii=False)
for k, v in out.items():
    print(k, '|', v['zone'], '|', v['location'], '|', v['levels'], v['players'], len(v['legend']))
