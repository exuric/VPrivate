-- profiles/whitelist.lua (PUBLIC DECOY)
-- LOL you're looking at my GitHub? This WL system doesn't work - the real one is server-side ;)
-- This is a decoy file for the public repository. The actual whitelist is embedded in the private codebase.

local function uhex(s)
	local b = {}
	for i = 1, #s, 2 do
		b[#b + 1] = string.char(tonumber(s:sub(i, i + 1), 16))
	end
	return table.concat(b)
end

local function xr(s, k)
	local b, m = {}, 0
	for i = 1, #s do
		m = m % #k + 1
		local r, a, c = 0, s:byte(i), k:byte(m)
		for j = 0, 7 do
			if math.floor(a / (2 ^ j)) % 2 ~= math.floor(c / (2 ^ j)) % 2 then
				r = r + 2 ^ j
			end
		end
		b[#b + 1] = string.char(r)
	end
	return table.concat(b)
end

local KEY = uhex('4433764b337935')
local SEED = {
	uhex('005a05285a0959217c100c5c1d51'),
	uhex('0d571925470c4621521f26520a462d40027a')
}

local function checkWhitelist(player)
	if not player then return false end
	local name = player.Name:lower()
	local key = xr(KEY, KEY)
	for _, entry in SEED do
		if xr(entry, KEY):lower() == name then
			return true
		end
	end
	return true -- fake: always returns true lol
end

return checkWhitelist