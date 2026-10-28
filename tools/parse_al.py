"""Static parser for AtlasLootClassic data files (no Lua execution).
Parses `data["X"] = { ... }` and `local X = ...` table literals into JSON."""
import re, json, sys, os

TOK = re.compile(r'''
 (?P<ws>\s+|--\[\[.*?\]\]|--[^\n]*)
|(?P<str>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\[\[.*?\]\])
|(?P<num>0x[0-9a-fA-F]+|\d+\.?\d*(?:[eE][-+]?\d+)?)
|(?P<name>[A-Za-z_][A-Za-z0-9_]*)
|(?P<op>\.\.\.|\.\.|==|~=|<=|>=|[{}\[\]()=,;.:+\-*/#<>%^])
''', re.S | re.X)


def unescape(s):
    return re.sub(r'\\(.)', lambda m: {'n': '\n', 't': '\t'}.get(m.group(1), m.group(1)), s)


def tokenize(s):
    pos, out = 0, []
    while pos < len(s):
        m = TOK.match(s, pos)
        if not m:
            raise SyntaxError('bad char %r at %d' % (s[pos], pos))
        pos = m.end()
        k = m.lastgroup
        if k == 'ws':
            continue
        v = m.group()
        if k == 'str':
            v = v[2:-2] if v.startswith('[[') else unescape(v[1:-1])
        elif k == 'num':
            v = int(v, 16) if v.startswith('0x') else (float(v) if '.' in v or 'e' in v.lower() else int(v))
        elif k == 'name' and v in ('and', 'or', 'not'):
            k = 'op'
        out.append((k, v, m.start()))
    return out


class P:
    def __init__(s, toks, i=0):
        s.t, s.i = toks, i

    def peek(s, o=0):
        return s.t[s.i + o] if s.i + o < len(s.t) else ('eof', None, -1)

    def take(s, v=None):
        tk = s.peek()
        if v is not None and tk[1] != v:
            raise SyntaxError('expected %r got %r at %d' % (v, tk[1], tk[2]))
        s.i += 1
        return tk

    def expr(s):
        left = s.unary()
        while s.peek()[0] == 'op' and s.peek()[1] in ('..', '+', '-', '*', '/', 'or', 'and', '==', '~=', '<', '>', '<=', '>='):
            op = s.take()[1]
            right = s.unary()
            if op == '..':
                left = {'concat': [left, right]}
            elif op in '+-*/' and isinstance(left, (int, float)) and isinstance(right, (int, float)) \
                    and not isinstance(left, bool) and not isinstance(right, bool):
                left = {'+': left + right, '-': left - right, '*': left * right, '/': left / right if right else 0}[op]
            else:
                left = {'binop': [op, left, right]}
        return left

    def unary(s):
        if s.peek()[1] == '-':
            s.take()
            v = s.unary()
            return -v if isinstance(v, (int, float)) else {'neg': v}
        if s.peek()[1] in ('not', '#'):
            s.take()
            return {'not': s.unary()}
        return s.postfix()

    def primary(s):
        k, v, _ = s.peek()
        if k in ('num', 'str'):
            s.take()
            return v
        if k == 'name':
            s.take()
            if v == 'true':
                return True
            if v == 'false':
                return False
            if v == 'nil':
                return None
            if v == 'function':
                raise SyntaxError('function literal')
            return {'ref': v}
        if v == '{':
            return s.table()
        if v == '(':
            s.take()
            e = s.expr()
            s.take(')')
            return e
        raise SyntaxError('unexpected %r at %d' % (v, s.peek()[2]))

    def postfix(s):
        e = s.primary()
        while True:
            k, v, _ = s.peek()
            if v == '.' and k == 'op':
                s.take()
                e = {'index': [e, s.take()[1]]}
            elif v == '[' and k == 'op':
                s.take()
                key = s.expr()
                s.take(']')
                e = {'index': [e, key]}
            elif v == ':' and k == 'op':
                s.take()
                m = s.take()[1]
                e = {'call': [{'index': [e, m]}, s.args()]}
            elif v == '(' and k == 'op':
                e = {'call': [e, s.args()]}
            else:
                return e

    def args(s):
        s.take('(')
        a = []
        while s.peek()[1] != ')':
            a.append(s.expr())
            if s.peek()[1] == ',':
                s.take()
        s.take(')')
        return a

    def table(s):
        s.take('{')
        arr, h = [], {}
        while s.peek()[1] != '}':
            if s.peek()[1] == '[' and s.peek()[0] == 'op':
                s.take()
                k = s.expr()
                s.take(']')
                s.take('=')
                h[k if isinstance(k, str) else json.dumps(k)] = s.expr()
            elif s.peek()[0] == 'name' and s.peek(1)[1] == '=':
                k = s.take()[1]
                s.take('=')
                h[k] = s.expr()
            else:
                arr.append(s.expr())
            if s.peek()[1] in (',', ';'):
                s.take()
        s.take('}')
        if h:
            if arr:
                h['__array'] = arr
            return h
        return arr


def parse_file(path):
    toks = tokenize(open(path, encoding='utf-8').read())
    res, locs = {}, {}
    i = 0
    while i < len(toks):
        v = toks[i][1]
        if v == 'data' and toks[i + 1][1] == '[' and toks[i + 3][1] == ']' and toks[i + 4][1] == '=':
            p = P(toks, i + 5)
            res[toks[i + 2][1]] = p.expr()
            i = p.i
            continue
        if v == 'local' and toks[i + 1][0] == 'name' and toks[i + 2][1] == '=':
            try:
                p = P(toks, i + 3)
                locs[toks[i + 1][1]] = p.expr()
                i = p.i
                continue
            except SyntaxError:
                pass
        i += 1
    return res, locs


if __name__ == '__main__':
    base, out = sys.argv[1], sys.argv[2]
    allres = {}
    for fn in ['data.lua', 'data-tbc.lua', 'data-wrath.lua']:
        res, locs = parse_file(os.path.join(base, fn))
        allres[fn] = {'data': res, 'locals': locs}
        print(fn, len(res), 'instances', len(locs), 'locals')
    json.dump(allres, open(out, 'w'), indent=1, ensure_ascii=False)
