#!/usr/bin/env python3
# Verifies obfuscator output fidelity: every string literal in the source
# must survive byte-identical inside the encrypted output, and no comments
# (except line 1 + --! directives) or raw long-strings may remain.
# Usage: python tools/verify_obf.py tools/src/main.lua main.lua
import re, sys

sys.path.insert(0, 'tools')
from obfuscate import tokenize, decode_str, obfuscate


def main():
    src = open(sys.argv[1], encoding='utf-8').read()
    out = open(sys.argv[2], encoding='utf-8').read()

    want = sorted(decode_str(v) for k, v in tokenize(src) if k in ('str', 'long'))
    got = sorted(bytes.fromhex(h).decode('utf-8')
                 for h in re.findall(r'__dx\w*\("([0-9a-f]*)"\)', out))
    print('src strings:', len(want), '| decrypted in output:', len(got))
    if want != got:
        from collections import Counter
        dw, dg = Counter(want), Counter(got)
        print('MISSING:', [(s, dw[s] - dg.get(s, 0)) for s in dw if dw[s] > dg.get(s, 0)][:5])
        print('EXTRA:', [(s, dg[s] - dw.get(s, 0)) for s in dg if dg[s] > dw.get(s, 0)][:5])
        sys.exit(1)
    print('FIDELITY OK')

    first = src.split('\n')[0]
    assert out.split('\n')[0] == first, 'first line changed!'
    bad = [v for k, v in tokenize(out)
           if (k == 'comment' and v != first and not v.startswith('--!'))
           or k == 'long']
    assert not bad, 'leftover comments/long-strings: %r' % (bad[:2],)
    print('STRUCTURE OK')

    regen, renamed, stub_name = obfuscate(src)
    assert regen == out, 'nondeterministic output!'
    print('DETERMINISM OK')

    stoks = [(i, k, v) for i, (k, v) in enumerate(tokenize(src))
             if k not in ('ws', 'comment')]
    olines = out.split('\n')
    otoks = [(k, v) for k, v in tokenize('\n'.join([olines[0]] + olines[2:]))
             if k not in ('ws', 'comment')]
    oi = 0
    for si, k, v in stoks:
        if k in ('str', 'long'):
            assert oi + 3 < len(otoks), 'output ended inside string at src tok %d' % si
            assert otoks[oi] == ('ident', stub_name), 'string not encrypted at src tok %d' % si
            assert otoks[oi + 1] == ('op', '('), 'bad crypt call at src tok %d' % si
            assert otoks[oi + 2][0] == 'str', 'bad crypt arg at src tok %d' % si
            assert bytes.fromhex(otoks[oi + 2][1][1:-1]).decode('utf-8') == decode_str(v), \
                'crypt value wrong at src tok %d' % si
            assert otoks[oi + 3] == ('op', ')'), 'bad crypt close at src tok %d' % si
            oi += 4
            continue
        assert oi < len(otoks), 'output shorter than source at src tok %d (%r)' % (si, v)
        exp = renamed.get(si, v)
        assert otoks[oi] == (k, exp), \
            'token mismatch at src tok %d: want %r got %r' % (si, (k, exp), otoks[oi])
        oi += 1
    assert oi == len(otoks), 'output has %d extra tokens' % (len(otoks) - oi)
    print('BINDING OK (%d tokens aligned)' % oi)


if __name__ == '__main__':
    main()
