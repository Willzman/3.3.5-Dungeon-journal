"""Load Dungeon Journal into a mocked 3.3.5a client (Lua 5.1 via lupa) and drive its UI.

    pip install lupa
    python3 tools/test/run.py
"""
import os, re, sys
from lupa import lua51

HERE = os.path.dirname(os.path.abspath(__file__))
ADDON = os.path.join(HERE, '..', '..', 'DungeonJournal')

lua = lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute(open(os.path.join(HERE, 'mock_wow.lua'), encoding='utf-8').read())

toc = open(os.path.join(ADDON, 'DungeonJournal.toc'), encoding='utf-8').read()
for line in toc.splitlines():
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    path = os.path.join(ADDON, *line.split('\\'))
    src = open(path, encoding='utf-8').read()
    fn = lua.eval('function(src, name) local f, err = loadstring(src, name) if not f then error(err) end return f end')(src, line)
    fn('DungeonJournal', lua.table())

lua.execute(open(os.path.join(HERE, 'scenario.lua'), encoding='utf-8').read())
unknown = sorted(lua.globals().UNKNOWN_KEYS.keys())
methods = [k for k in unknown if re.match(r'^(Set|Get|Is|Enable|Disable|Create|Register|Clear)[A-Z]', k)]
print('custom fields read as nil (check none of these is a missing 3.3.5a method):', ', '.join(methods) or 'none')
