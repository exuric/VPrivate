#!/usr/bin/env python3
# Conservative deterministic Luau obfuscator for small gate files.
# Usage: python tools/obfuscate.py tools/src/main.lua main.lua
# Transforms (all semantics-preserving by construction):
#   1. strip comments (keeps line 1 verbatim + any --! directive lines)
#   2. rename declared locals per precise block scopes (an identifier is only
#      renamed when it resolves to a recorded declaration; field access after
#      '.' / ':', table-constructor keys and globals are never touched)
#   3. hex-encode every string literal behind a tiny runtime stub
# Name mapping is deterministic (counter order), so re-running on unchanged
# source yields identical output.
import re, sys

KEYWORDS = set('''and break do else elseif end false for function goto if in
local nil not or repeat return then true until while'''.split())
BLOCKKW = {'function', 'then', 'else', 'do', 'end', 'until', 'repeat',
           'if', 'for', 'while', 'elseif'}
MARKERS = {'if', 'loop', 'func', 'repeat'}

TOKEN = re.compile(r'''
    (?P<ws>\s+)
  | (?P<num>0[xX][0-9a-fA-F]+|\d[\d_.]*([eE][+-]?\d+)?)
  | (?P<ident>[A-Za-z_]\w*)
  | (?P<str>"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')
  | (?P<op>\.\.\.|==|~=|<=|>=|::|[+\-*/%^#<>=(){}\[\];:,.\|&~])
''', re.X)


def tokenize(src):
    toks = []
    i, n = 0, len(src)
    while i < n:
        if src.startswith('--', i):
            m = re.match(r'--\[(=*)\[', src[i:])
            if m:
                eq = m.group(1)
                j = src.find(']' + eq + ']', i + m.end())
                j = n if j < 0 else j + len(eq) + 2
                toks.append(('comment', src[i:j]))
                i = j
            else:
                j = src.find('\n', i)
                j = n if j < 0 else j
                toks.append(('comment', src[i:j]))
                i = j
        else:
            lm = re.match(r'\[(=*)\[', src[i:])
            if lm:
                closer = ']' + lm.group(1) + ']'
                j = src.find(closer, i + lm.end())
                if j >= 0:
                    toks.append(('long', src[i:j + len(closer)]))
                    i = j + len(closer)
                    continue
            m = TOKEN.match(src, i)
            if not m:
                toks.append(('other', src[i]))
                i += 1
                continue
            kind = None
            for kk, vv in m.groupdict().items():
                if vv is not None:
                    kind = kk
                    break
            toks.append((kind or 'other', m.group(0)))
            i = m.end()
    return toks


def decode_str(raw):
    if raw.startswith('['):
        m = re.match(r'\[(=*)\[(.|\n)*\]\1\]$', raw, re.S)
        return m.group(2)
    q = raw[0]
    body = raw[1:-1]
    out = []
    i = 0
    esc = {'n': '\n', 't': '\t', 'r': '\r', 'a': '\a', 'b': '\b',
           'f': '\f', 'v': '\v', '\\': '\\', '"': '"', "'": "'"}
    while i < len(body):
        c = body[i]
        if c != '\\':
            out.append(c)
            i += 1
            continue
        i += 1
        if i < len(body) and body[i] == 'x' and re.match(r'[0-9a-fA-F]{2}', body[i + 1:i + 3] or ''):
            out.append(chr(int(body[i + 1:i + 3], 16)))
            i += 3
        elif i < len(body) and body[i].isdigit():
            m = re.match(r'\d{1,3}', body[i:])
            out.append(chr(int(m.group(0)) % 256))
            i += len(m.group(0))
        elif i < len(body) and body[i] in esc:
            out.append(esc[body[i]])
            i += 1
        else:
            out.append(body[i] if i < len(body) else '')
            i += 1
    return ''.join(out)


def sig(toks, i):
    for j in range(i, len(toks)):
        if toks[j][0] not in ('ws', 'comment'):
            return toks[j]
    return ('eof', '')


def prev_sig(toks, i):
    for j in range(i - 1, -1, -1):
        if toks[j][0] not in ('ws', 'comment'):
            return toks[j]
    return ('bof', '')


def obfuscate(src):
    lines = src.split('\n')
    first = lines[0] if lines else ''
    toks = tokenize(src)
    existing = set(v for k, v in toks if k == 'ident')
    counter = [0]

    def fresh():
        while True:
            name = '__o%d' % counter[0]
            counter[0] += 1
            if name not in existing:
                existing.add(name)
                return name

    stub_name = '__dx'
    k = 0
    while stub_name in existing:
        stub_name = '__dx%d' % k
        k += 1
    existing.add(stub_name)

    scopes = [{}]
    stack = []
    renamed = {}
    pending = []
    bdepth = [0]
    out = list(toks)
    n = len(toks)

    def declare(name):
        if name in scopes[-1]:
            return scopes[-1][name]
        nn = fresh()
        scopes[-1][name] = nn
        return nn

    def lookup(name, pos):
        for s in reversed(scopes):
            drop = False
            for p in pending:
                if p['scope'] is s and p['name'] == name and pos <= p['wend']:
                    drop = True
                    break
            if drop:
                continue
            if name in s:
                return s[name]
        return None

    def flush_pending(pos):
        for p in pending[:]:
            alive = False
            for s in scopes:
                if p['scope'] is s:
                    alive = True
                    break
            if pos > p['wend'] or not alive:
                if p['name'] not in p['scope']:
                    nn = fresh()
                    p['scope'][p['name']] = nn
                renamed[p['idx']] = p['scope'][p['name']]
                pending.remove(p)

    def find_init_end(m):
        j = m + 1
        depth = 0
        func = 0
        while j < n:
            kj, vj = toks[j]
            if kj in ('ws', 'comment', 'num', 'str', 'long', 'other'):
                j += 1
                continue
            if kj == 'op':
                if vj in ('(', '[', '{'):
                    depth += 1
                elif vj in (')', ']', '}'):
                    if depth > 0:
                        depth -= 1
                    elif func == 0:
                        return j
                elif (vj == ',' or vj == ';') and depth == 0 and func == 0:
                    return j
                j += 1
                continue
            pk, pv = prev_sig(toks, j)
            dotted = (pk, pv) == ('op', '.') or (pk, pv) == ('op', ':')
            if vj == 'function' and not dotted:
                func += 1
            elif (vj == 'end' or vj == 'until') and not dotted:
                nk, nv = sig(toks, j + 1)
                if (nv == '=' and pk == 'op' and pv in ('{', ',')):
                    j += 1
                    continue
                if func > 0:
                    func -= 1
                else:
                    return j
            elif vj in ('else', 'elseif', 'then', 'do', 'in', 'for', 'while',
                        'if', 'repeat', 'local', 'return', 'break') and not dotted:
                nk, nv = sig(toks, j + 1)
                if nv == '=' and pk == 'op' and pv in ('{', ','):
                    j += 1
                    continue
                if func == 0:
                    return j
            j += 1
        return n

    def push_block():
        scopes.append({})

    def pop_block():
        if len(scopes) > 1:
            scopes.pop()

    def parse_fn_header(i):
        n = len(toks)
        j = i + 1
        while j < n and toks[j][0] in ('ws', 'comment'):
            j += 1
        if j < n and toks[j] == ('op', ':'):
            j += 1
            while j < n and toks[j][0] in ('ws', 'comment'):
                j += 1
            j += 1
        k = j
        depth = 0
        while k < n:
            kk, vv = toks[k]
            if kk == 'op' and vv == '(' and depth == 0:
                depth = 1
                k += 1
                break
            if kk == 'op' and vv in ('.', ':'):
                k += 1
                while k < n and toks[k][0] in ('ws', 'comment'):
                    k += 1
                k += 1
                continue
            k += 1
        while k < n and depth > 0:
            kk, vv = toks[k]
            if kk == 'op' and vv == '(':
                depth += 1
            elif kk == 'op' and vv == ')':
                depth -= 1
                if depth == 0:
                    break
            elif kk == 'ident' and vv not in KEYWORDS and vv != 'self':
                renamed[k] = declare(vv)
            k += 1

    i, n = 0, len(toks)
    while i < n:
        flush_pending(i)
        kind, val = toks[i]
        if kind in ('ws', 'comment', 'other', 'num', 'str', 'long'):
            i += 1
            continue
        if kind == 'op':
            if val == '{':
                bdepth[0] += 1
            elif val == '}':
                bdepth[0] = max(0, bdepth[0] - 1)
            i += 1
            continue
        if val == 'local':
            j = i + 1
            while j < n and toks[j][0] in ('ws', 'comment'):
                j += 1
            if j < n and toks[j] == ('ident', 'function'):
                k = j + 1
                while k < n and toks[k][0] in ('ws', 'comment'):
                    k += 1
                if k < n and toks[k][0] == 'ident':
                    renamed[k] = declare(toks[k][1])
                i += 1
                continue
            names = []
            k = j
            while k < n:
                kk, vv = toks[k]
                if kk in ('ws', 'comment'):
                    k += 1
                    continue
                if kk == 'ident' and vv not in KEYWORDS:
                    names.append(k)
                    k += 1
                    continue
                if kk == 'op' and vv == ',':
                    k += 1
                    continue
                break
            m = k
            while m < n and toks[m][0] in ('ws', 'comment'):
                m += 1
            if names and m < n and toks[m] == ('op', '='):
                wend = find_init_end(m)
                for idx in names:
                    pending.append({'idx': idx, 'name': toks[idx][1],
                                    'scope': scopes[-1], 'wend': wend})
            else:
                for idx in names:
                    renamed[idx] = declare(toks[idx][1])
            i += 1
            continue
        if val in KEYWORDS and val not in BLOCKKW:
            i += 1
            continue
        if val in BLOCKKW:
            pk, pv = prev_sig(toks, i)
            if (pk, pv) == ('op', '.') or (pk, pv) == ('op', ':'):
                i += 1
                continue
            if val == 'function':
                stack.append('func')
                push_block()
                parse_fn_header(i)
            elif val == 'if':
                stack.append('if')
            elif val == 'for' or val == 'while':
                stack.append('loop')
                if val == 'for':
                    push_block()
                    j = i + 1
                    while j < n:
                        kj, vj = toks[j]
                        if kj in ('ws', 'comment'):
                            j += 1
                            continue
                        if kj == 'ident' and vj not in KEYWORDS:
                            renamed[j] = declare(vj)
                            j += 1
                            continue
                        if kj == 'op' and vj == ',':
                            j += 1
                            continue
                        break
            elif val == 'repeat':
                stack.append('repeat')
                push_block()
            elif val in ('then', 'else', 'do'):
                if val == 'else':
                    pop_block()
                push_block()
            elif val == 'elseif':
                pop_block()
            elif val == 'end':
                pop_block()
                if stack and stack[-1] in ('if', 'loop', 'func'):
                    stack.pop()
            elif val == 'until':
                pop_block()
                if stack and stack[-1] == 'repeat':
                    stack.pop()
            i += 1
            continue
        pk, pv = prev_sig(toks, i)
        if (pk, pv) == ('op', '.') or (pk, pv) == ('op', ':'):
            i += 1
            continue
        nk, nv = sig(toks, i + 1)
        if nv == '=' and bdepth[0] > 0 and pk == 'op' and pv in ('{', ','):
            i += 1
            continue
        hit = lookup(val, i)
        if hit:
            renamed[i] = hit
        i += 1

    for idx, nn in renamed.items():
        out[idx] = ('ident', nn)

    stub = ('local ' + stub_name + '=function(s) local b={} '
            'for i=1,#s,2 do b[#b+1]=string.char(tonumber(s:sub(i,i+1),16)) end '
            'return table.concat(b) end')
    parts = []
    kept_first = False
    for idx, (kind, val) in enumerate(out):
        if kind == 'comment':
            if not kept_first:
                parts.append(first)
                kept_first = True
                continue
            if val.startswith('--!'):
                parts.append(val)
            continue
        if kind in ('str', 'long'):
            enc = decode_str(val).encode('utf-8').hex()
            parts.append(stub_name + '("' + enc + '")')
            continue
        parts.append(val)
    body = ''.join(parts)
    if not kept_first:
        body = first + body
    head, sep, rest = body.partition('\n')
    out = head + '\n' + stub + '\n' + rest if sep else head
    return out, renamed, stub_name


def main():
    src_path, dst_path = sys.argv[1], sys.argv[2]
    src = open(src_path, encoding='utf-8').read()
    out, _, _ = obfuscate(src)
    open(dst_path, 'w', encoding='utf-8', newline='').write(out)
    print('wrote', dst_path, len(out), 'bytes')


if __name__ == '__main__':
    main()
