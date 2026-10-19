# larp auth proxy — deploy

The lock is this proxy. The repo stays **private**. The loader no longer pulls from
`raw.githubusercontent.com` / jsdelivr directly (those 404 on a private repo and would
leak a token if embedded). Instead every user hits the Worker with their **own key**;
the Worker holds the GitHub token and the key list server-side and decides each user's tier.

Revoke a key → that user gets no updates, no auth, and the loader unloads them. The copy
the leaker already has becomes a frozen husk with no server access.

## 1. GitHub token (least privilege)

GitHub → Settings → Developer settings → **Fine-grained tokens** → Generate new:
- **Resource owner:** exuric
- **Repository access:** Only select repositories → **exuric/VPrivate**
- **Permissions:** Repository permissions → **Contents: Read-only** (nothing else)
- **Expiration:** 90 days (rotate on a reminder)

Copy the token (starts `github_pat_...`). It is never put in the repo or the loader.

## 2. Create the Worker

Cloudflare dashboard → Workers & Pages → **Create** → Worker → name it e.g. `larp-auth`.
Edit code → paste the contents of `worker.js` → **Deploy**.
Your URL will be `https://larp-auth.<your-subdomain>.workers.dev`. Send me that URL —
I wire it into the loader (one placeholder swap) and rotate the key.

## 3. Bind the secret + KV

In the Worker → **Settings** → **Variables**:
- **Secrets** → Add → name `GH_TOKEN`, value = the token from step 1. (Encrypt.)

Workers & Pages → **KV** → Create namespace `larp-keys`.
Back in the Worker → Settings → Variables → **KV Namespace Bindings** → Add:
- Variable name `KEYS`, namespace `larp-keys`.

## 4. Add keys

In the `larp-keys` KV namespace, each user is one entry:
- **Key:** `k:<the user's key string>`  (e.g. `k:9f3a...` — generate random, 24+ chars)
- **Value:** JSON, one line:

```json
{"tier":"owner","userId":YOUR_ROBLOX_USERID,"revoked":false,"label":"dj"}
```

- `tier`: `"owner"`, `"dev"`, or `"user"`.
- `userId`: bind the key to one Roblox account (recommended). Use `null` to leave unbound.
- `revoked`: set `true` to instantly cut a user off (no redeploy needed).

Make yourself an `owner` key bound to your UserId. Make normal users `user` keys.

## 5. Test (browser or curl)

- `https://larp-auth.<sub>.workers.dev/auth?key=<yourkey>&uid=<youruid>` → `{"ok":true,"tier":"owner"}`
- Wrong key → 403 `{"ok":false,"reason":"invalid"}`
- `.../f/main.lua?key=<yourkey>&uid=<youruid>&c=main` → the loader source.

Once that works, send me the URL and your UserId + owner username(s) and I rotate
`_key`, set the real owner, and switch the loader to pull through the Worker.

## Reality check

This stops **distribution and server features** for the leaker. It cannot un-leak the
source they already copied, and a user running the client in their own executor can still
flip a local flag — which is why anything that must be trusted (owner actions, profile
writes, kill-switch) is validated **here**, server-side, on every request, not by a client
flag. Obfuscating the shipped Lua on top is friction worth adding before launch, not a lock.
