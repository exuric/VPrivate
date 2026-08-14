import json
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WM = b'--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.\n'


def jhash(data):
    h = 0

    def bx(x):
        return x & 0xFFFFFFFF

    for b in data:
        h = bx(h + b)
        h = bx(h ^ (h << 10))
        h = bx(h ^ (h >> 6))
    h = bx(h ^ (h << 3))
    h = bx(h ^ (h >> 11))
    h = bx(h ^ (h << 15))
    return h


def main():
    manifest = {}

    def add(path, data):
        manifest[path] = jhash(data)

    with open(os.path.join(REPO, 'main.lua'), 'rb') as f:
        add('LarpV4/main.lua', WM + f.read())

    with open(os.path.join(REPO, 'guis', 'larp.lua.0'), 'rb') as f0, open(os.path.join(REPO, 'guis', 'larp.lua.1'), 'rb') as f1:
        add('LarpV4/guis/larp.lua', WM + f0.read() + f1.read())

    for folder in ('games', 'libraries'):
        for name in sorted(os.listdir(os.path.join(REPO, folder))):
            path = os.path.join(REPO, folder, name)
            if os.path.isfile(path):
                with open(path, 'rb') as f:
                    add('LarpV4/%s/%s' % (folder, name), WM + f.read())

    for root, _, names in os.walk(os.path.join(REPO, 'assets')):
        for name in names:
            path = os.path.join(root, name)
            rel = 'LarpV4/assets/' + os.path.relpath(path, os.path.join(REPO, 'assets')).replace('\\', '/')
            with open(path, 'rb') as f:
                add(rel, f.read())

    out = os.path.join(REPO, 'updates.json')
    with open(out, 'w') as f:
        json.dump(manifest, f, separators=(',', ':'))
    print('wrote updates.json with %d files' % len(manifest))


if __name__ == '__main__':
    main()