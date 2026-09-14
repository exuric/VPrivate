# Larp V4 (exuric/VPrivate) — working guide for Claude Code

Roblox Luau executor ("Larp V4") + per-game module packs + loader + public-profile
system. Repo is PUBLIC on GitHub, served raw via CDN with ~5 min cache. Users inject
`init.lua`; it verifies/watermarks files from
`https://raw.githubusercontent.com/exuric/VPrivate/<commit>/LarpV4/...`, then runs the
loader, which loads the GUI, libraries, and `games/<PlaceId>.lua`.

## Hard rules (do not violate)

1. **Do not touch the obfuscated blocks** in `main.lua` (~lines 28-55) and `init.lua`
   owner checks. Owner UserId constant + whitelisted usernames are intentionally
   XOR-obfuscated. Never attempt to "unobfuscate", "clean", or rewrite them. They are
   only edited with an exact verified replacement (encrypt with the same key), under
   explicit user instruction.
2. **Keep the exact first line of every folder `.lua` file** as its watermark
   (`--This watermark is used to delete the file if its cached, remove it to make the
   file persist after larp updates.`). The downloader prepends
   `--LARP:<commit>\n` to fetched `.lua` files; a cached file whose watermark doesn't
   match the current `profiles/commit.txt` is re-downloaded. That is the update
   mechanism, not a bug. Never strip or alter `--LARP:` prefixes.
3. **Commits**: one logical change, short lowercase message, git identity
   `opencode` (`git -c user.name=opencode -c user.email=opencode@localhost commit`).
   Push to `main`. Never amend/force-push. Only commit when asked or when the task
   specifies updating the repo.
4. **File encoding**: write/rewrite `.lua`/`.json` ONLY with your edit/write tools or
   Python `open(path, 'w', encoding='utf-8', newline='')`. NEVER use PowerShell
   `Set-Content`/`Out-File` — they corrupt UTF-8 (mojibake). If a file is already
   mojibake'd, don't "fix" it wholesale without user sign-off.
5. **Luau register ceiling**: ~200 live locals per scope in the main listener chunk of
   `guis/larp2.lua`. New features must be wrapped in `do...end` or exposed as
   `mainapi:` methods via `tools/regcount.py` verification. Symptom:
   `Out of local registers ... exceeded limit 200`.
6. **No invented comments** unless the user asks for documentation. Preserve existing
   comment style and the U+200A hair-space padding in TextGUI rows (12 per side).
7. **Do not re-add removed features**: search tag-filter/highlight/NEW green pill,
   loader loading UI, edit-mode popup panel. No random module feature-creep; the user
   deletes extras.
8. **No demo/hardcoded data** in public profiles beyond the seeded registry.

## Repo layout

- `init.lua` — inject entry. Owner branch loads `games/<PlaceId>.lua` before the GUI.
- `main.lua` — LocalPlayer whitelist gateway (DO NOT TOUCH), watermark commit read,
  `downloadFile`, `finishLoading`, OnTeleport AutoExecute gate.
- `guis/larp2.lua` — the entire GUI (~11k lines): categories, TextGUI label cache,
  Public Profiles subsystem (inside a big `do...end`), panic, edit mode. Watch the
  register ceiling.
- `libraries/prediction.lua` — clean ballistic solver with section banners and a
  top-of-file API index. Already deobfuscated; keep it that way.
- `libraries/entity.lua` — `entitylib`: `targetCheck` (teams via `Player.Team`),
  `isVulnerable` (health + ForceField only, no teams), `Targetable`.
- `games/8560631822.lua`, `games/6872274481.lua` — game modules incl. ProjectileAimbot.
  MUST stay in sync: any edit to one is mirrored to the other.
- `profiles/registry.json` + `reg_*.json` — seeded public-profile registry (3 real
  modules, no invented data).
- `profiles/manifest.txt`, `profiles/commit.txt` — integrity/update pipeline. Never
  edit by hand.
- `tools/make-manifest.ps1` — regenerates `manifest.txt`. `tools/balcheck2.py` and
  `tools/regcount.py` — verification helpers.

## ProjectileAimbot contract (games/*.lua)

- Hook: `bedwars.ProjectileController.calculateImportantLaunchValues(self, projmeta,
  worldmeta, origin, shootpos)` must return
  `{initialVelocity, positionFrom, deltaT, gravitationalAcceleration, drawDurationSeconds}`.
  Beam detour when `worldmeta == true`. Whole body wrapped in `pcall`; any failure
  returns `old(...)` (original function), which means the shot uses the player's raw aim.
  `old` holds the pre-hook function; `realOld` the unmodified original.
- Projectile meta: `lifetime = (isBeam and meta.predictionLifetimeSec) or meta.lifetimeSec or 3`;
  `timeout = math.max(lifetime * 1.5, 1.25)` used as the solve horizon.
- `gravity = (meta.gravitationalAcceleration or 196.2) * (projmeta.gravityMultiplier or 1)`;
  `charge = AutoCharge.Enabled and 1 or (projmeta.velocityMultiplier or 1)`;
  `speed = (meta.launchVelocity or 100) * charge`.
- **Prediction slider must stay at 1.0** — `prediction.lua` handles latency internally
  (full RTT). Don't double-compensate.
- Team rule: skip targets whose `GetAttribute('Team')` equals the local player's
  (`plr:GetAttribute('Team')`, or `Character:GetAttribute('Team')` for NPCs).
- `pickTarget`: Target Lock sticky, Priority (Cursor/Closest/Lowest HP), Distance,
  FOV, viewport cull, invisibility, walls/LOS. `smoothVel` EMA plus dead-stop snap
  (horizontal < 3 -> zero lead). Never aim telepearls; Blacklist by projectile name.
- Diagnostics: `getgenv().projAimStats = {calls, shots, fallback}` and
  `getgenv().projShotLog` rows `{p,d,t,s,g,m,plr,fb,chg}`.

## Saving / loading (the GUI)

- `mainapi:Save` writes `profiles/<PlaceId>.gui.txt` (GUI layout, categories, Position),
  `profiles/<Profile><Place>.txt` (module states/binds/options via BuildSaveData), and
  `<Profile>.last.txt` fallback. `mainapi:Load` restores; the overlay loop must keep the
  `if v.Position then` guard (saved overlays carry no Position).
- Public Profiles persist under `LarpV4/profiles/` (private JSON): `public/index.json`,
  item files, `likes.json`, `downloads.json`. Share codes POST to paste.rs and store
  `LARP-<code>`.

## Verification before commit (every .lua change)

1. `python tools/balcheck2.py guis/larp2.lua games/8560631822.lua games/6872274481.lua
   libraries/prediction.lua`. Expect the KNOWN pre-existing scanner false positive
   "unclosed function" at line ~12584 in both game files; everything else must be clean.
2. If you added locals to a big function, `python tools/regcount.py <file>`.
3. `powershell -NoProfile -ExecutionPolicy Bypass -File tools/make-manifest.ps1`
   (rewrites `profiles/manifest.txt`).
4. Commit changes, then commit the bump:
   `git rev-parse HEAD | Set-Content -Path profiles/commit.txt -Encoding ASCII -NoNewline`
   (40 hex chars, no trailing newline), stage it, commit `bump commit`, push.
5. Verify `https://raw.githubusercontent.com/exuric/VPrivate/main/profiles/commit.txt`
   eventually returns the new SHA (CDN lags ~5 min; retry after waiting).

## Workflow notes

- Cache-busting is mandatory on every `game:HttpGet` of repo content: commit-pinned
  URLs carry `?v=<COMMIT>_<attempt>`, mutable control files (`commit.txt`,
  `manifest.txt`, `registry.json`, reload `init.lua`) carry `?v='..tick()`. Never
  fetch repo content from a bare URL — the CDN caches 5 min and serves stale/mixed
  builds. `paste.rs` share-code fetches stay bare (content-addressed).
- After every push: tell the user to wait ~5 minutes then inject once (or the CDN
  serves a stale/mixed file set, which reproduces the "not working" reports).
- The owner confirms each roundtrip; never assume a fix worked without that one fresh
  inject. Prefer surgical, verifiable changes over wide rewrites.
- `guis/larp2.lua` and both `games/*.lua` are the highest-risk files. The projectile aim
  is computed silently (no visuals) — debug via `projAimStats`/`projShotLog`, not by
  eyeballing shots.