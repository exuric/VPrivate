import re, sys
path = sys.argv[1]
src = open(path, encoding='utf-8').read()
src = re.sub(r'--\[\[.*?\]\]', '', src, flags=re.S)
stack = []
errs = []
for n, ln in enumerate(src.split('\n'), 1):
    code = re.sub(r'--(?!\[).*$', '', ln)
    code = re.sub(r'"(?:[^"\\]|\\.)*"', '""', code)
    code = re.sub(r"'(?:[^'\\]|\\.)*'", "''", code)
    toks = re.findall(r'\b(function|if|for|while|repeat|do|end|until|else|elseif)\b', code)
    has_for_while = any(t in ('for', 'while') for t in toks)
    for t in toks:
        if t == 'function':
            stack.append((n, 'function'))
        elif t == 'if':
            stack.append((n, 'if'))
        elif t in ('for', 'while'):
            stack.append((n, t))
        elif t == 'do':
            if not has_for_while:
                stack.append((n, 'do'))
        elif t == 'repeat':
            stack.append((n, 'repeat'))
        elif t == 'until':
            if stack and stack[-1][1] == 'repeat':
                stack.pop()
            else:
                errs.append((n, 'until without repeat, stack top: %s' % (stack[-1] if stack else None)))
        elif t == 'end':
            if stack and stack[-1][1] in ('function', 'if', 'for', 'while', 'do'):
                stack.pop()
            else:
                errs.append((n, 'stray end, stack top: %s' % (stack[-1] if stack else None)))
print(path, 'unclosed:', [(l, t) for l, t in stack[:20]], '... total', len(stack))
print('errors:', errs[:20] if errs else 'none')