UPLOAD THESE FILES AS-IS (same paths) to a PUBLIC GitHub repo:
  init.lua            <- loader; change the 3 "YOURUSERNAME/YOURREPO" strings to your user/repo
  main.lua            <- loader entry (URLs already swapped to YOURUSERNAME/YOURREPO)
  games/  libraries/  guis/  profiles/

1. Create repo "LarpV4" (Public).
2. Upload all folders as shown (preserve paths).
3. Replace YOURUSERNAME/YOURREPO inside init.lua + main.lua with your actual user/repo (find-replace).
4. profiles/commit.txt stays "main" so it pins to your branch.

Test loadstring for YOU and anyone:
  loadstring(game:HttpGet('https://raw.githubusercontent.com/YOURUSERNAME/YOURREPO/main/init.lua', true))()

Notes:
- Raw URLs require a PUBLIC repo (private raw needs tokens) -> that's the loadstring.
- "Same code" = all files are your exact modified builds; only the download base changed.
