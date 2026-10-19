// larp auth proxy — Cloudflare Worker
// The ONLY lock that matters: the GitHub token and the key list live here,
// server-side, never in the distributed loader.
//
// Bindings required (set in the Cloudflare dashboard, see DEPLOY.md):
//   Secret  GH_TOKEN  — fine-grained PAT, read-only Contents on exuric/VPrivate ONLY
//   KV      KEYS      — namespace; one entry per user:  key "k:<userkey>"  value JSON
//                        {"tier":"owner"|"dev"|"user","userId":<number|null>,"revoked":false,"label":"..."}
//
// Endpoints the loader calls:
//   GET /auth?key=K&uid=U      -> {"ok":true,"tier":"owner"} or 403 {"ok":false,"reason":"..."}
//   GET /f/<repo-path>?key=K&uid=U&c=<commit>  -> raw file bytes (private repo), or 403

const REPO = 'exuric/VPrivate';

// Only these paths may ever be served. No traversal, no .git, no workflow files.
const ALLOW = [
  /^main\.lua$/,
  /^init\.lua$/,
  /^guis\/[A-Za-z0-9._/-]+$/,
  /^games\/[A-Za-z0-9._/-]+$/,
  /^libraries\/[A-Za-z0-9._/-]+$/,
  /^profiles\/[A-Za-z0-9._%/-]+$/,
  /^assets\/[A-Za-z0-9._/-]+$/,
];

function h(extra) {
  const hd = new Headers(extra || {});
  hd.set('Access-Control-Allow-Origin', '*');
  hd.set('Cache-Control', 'no-store');
  return hd;
}
function txt(body, status) {
  return new Response(body, { status: status || 200, headers: h({ 'content-type': 'text/plain' }) });
}

async function getKey(env, key) {
  if (!key || key.length < 8 || key.length > 128) return null;
  let raw;
  try { raw = await env.KEYS.get('k:' + key); } catch (e) { return null; }
  if (!raw) return null;
  try {
    const o = JSON.parse(raw);
    return o.revoked ? null : o;
  } catch (e) { return null; }
}

// A key is valid for this user if it is not bound, or bound to this exact UserId.
function userOk(k, uid) {
  if (k.userId === null || k.userId === undefined || k.userId === '') return true;
  return String(k.userId) === String(uid);
}

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    const key = url.searchParams.get('key') || '';
    const uid = url.searchParams.get('uid') || '';

    if (url.pathname === '/auth') {
      const k = await getKey(env, key);
      if (!k) return txt(JSON.stringify({ ok: false, reason: 'invalid' }), 403);
      if (!userOk(k, uid)) return txt(JSON.stringify({ ok: false, reason: 'bound' }), 403);
      return txt(JSON.stringify({ ok: true, tier: k.tier || 'user' }));
    }

    if (url.pathname.startsWith('/f/')) {
      let path;
      try { path = decodeURIComponent(url.pathname.slice(3)); } catch (e) { return txt('-- bad path', 400); }
      if (path.includes('..') || !ALLOW.some((r) => r.test(path))) return txt('-- forbidden path', 400);

      const k = await getKey(env, key);
      if (!k) return txt('-- unauthorized', 403);
      if (!userOk(k, uid)) return txt('-- key bound to another account', 403);

      const ref = (url.searchParams.get('c') || 'main').replace(/[^A-Za-z0-9._/-]/g, '');
      const ghUrl = 'https://raw.githubusercontent.com/' + REPO + '/' + ref + '/' + path;
      const gh = await fetch(ghUrl, {
        headers: { Authorization: 'token ' + env.GH_TOKEN, 'User-Agent': 'larp-proxy', Accept: 'application/vnd.github.raw' },
      });
      if (!gh.ok) return txt('-- fetch failed ' + gh.status, 502);
      const buf = await gh.arrayBuffer();
      return new Response(buf, { status: 200, headers: h({ 'content-type': 'application/octet-stream' }) });
    }

    return txt('larp', 200);
  },
};
