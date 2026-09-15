# Push the current work to GitHub

Review first: run `git status --short` and `git diff --stat`. If anything
looks unintended, stop and ask before continuing.

When the tree is correct, ship it exactly like this:

1. Stage everything: `git add -A`
2. Regenerate the integrity file:
   `powershell -NoProfile -ExecutionPolicy Bypass -File tools/make-manifest.ps1`
3. Stage it: `git add profiles/manifest.txt`
4. Commit with message `update`, identity opencode:
   `git -c user.name=opencode -c user.email=opencode@localhost commit -m 'update'`
5. Write the new HEAD sha into profiles/commit.txt (ASCII, no trailing
   newline), stage it, and commit that as `update` too:
   `git rev-parse HEAD | Set-Content -Path 'profiles\commit.txt' -Encoding ASCII -NoNewline`
   `git add profiles/commit.txt`
   `git -c user.name=opencode -c user.email=opencode@localhost commit -m 'update'`
6. `git push origin main`, then show `git log --oneline -2` as proof.

Rules: every commit message is `update`. Never amend, never force-push.
If the push is rejected, fetch first and report — do not reset or
overwrite remote history.
