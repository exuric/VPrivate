#!/usr/bin/env python3
# Estimate of peak live locals per scope chain, used to guard the Luau
# compiler's ~200-live-local limit. Run: python tools/regcount.py <file.lua>
# The main guis/larp2.lua chunk has a hard ceiling; large features must be
# wrapped in do...end or exposed as mainapi:/module methods.
import re, sys
path = sys.argv[1]
src = open(path, encoding='utf-8').read()
src = re.sub(r'--\[\[.*?\]\]', '', src, flags=re.S)
scopes = [set()]
peak = 0
peakline = 0
pending_loop = False
for n, ln in enumerate(src.split('\n'), 1):
    code = re.sub(r'--(?!\[).*$', '', ln)
    code = re.sub(r'"(?:[^"\\]|\\.)*"', '""', code)
    code = re.sub(r"'(?:[^'\\]|\\.)*'", "''", code)
    toks = re.findall(r'\b(local|function|if|for|while|repeat|do|end|until|else|elseif)\b', code)
    i = 0
    while i < len(toks):
        t = toks[i]
        if t == 'local':
            if i + 1 < len(toks) and toks[i + 1] == 'function':
                m = re.search(r'local\s+function\s+([A-Za-z_]\w*)', code)
                if m:
                    scopes[-1].add(m.group(1))
                i += 2
                continue
            else:
                m = re.search(r'local\s+([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)', code)
                if m:
                    for nm in m.group(1).split(','):
                        scopes[-1].add(nm.strip())
            i += 1
        elif t == 'function':
            scopes.append(set())
            m = re.search(r'function\s*(?:[A-Za-z_][\w.:]*)?\s*\(([^)]*)\)', code)
            if m:
                for p in m.group(1).split(','):
                    p = p.strip()
                    if re.match(r'^[A-Za-z_]\w*$', p):
                        scopes[-1].add(p)
            i += 1
        elif t in ('if', 'repeat'):
            scopes.append(set())
            i += 1
        elif t in ('for', 'while'):
            scopes.append(set())
            m = re.match(r'.*?\bfor\s+([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*(in|=)', code)
            if m:
                for nm in m.group(1).split(','):
                    scopes[-1].add(nm.strip())
            if not re.search(r'\bdo\b', code):
                pending_loop = True
            i += 1
        elif t == 'do':
            if pending_loop:
                pending_loop = False
            else:
                scopes.append(set())
            i += 1
        elif t in ('else', 'elseif'):
            i += 1
        elif t in ('end', 'until'):
            if len(scopes) > 1:
                scopes.pop()
            i += 1
        else:
            i += 1
    live = sum(len(s) for s in scopes)
    if live > peak:
        peak, peakline = live, n
print(path, 'peak live locals:', peak, 'at line', peakline)