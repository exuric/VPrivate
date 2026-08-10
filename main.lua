--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
local license = ... or {}
repeat task.wait() until game:IsLoaded()
if shared.larp then shared.larp:Uninject() end
license.Key = license.Key or '_key'

local larp
local loadstring = function(...)
	local res, err = loadstring(...)
	if err then
		error('LarpV4: '..tostring(err))
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))
local httpService = cloneref(game:GetService("HttpService"))

local allowedUsers = {
	[0x17340ba40] = 'replaced_username1',
	[0x0] = 'replaced_username2',
	[0x0] = 'replaced_username3',
}

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

local WK = xr(uhex('a62d63876c044b9a74407d6e2cd20c6422d42f7fd8207ff3'), 'L4rp')
local AMSG = uhex('4e6f7420417574686f72697a65642d20546f20676574204c61727020563420446d204a78347220416e64204a6f696e2074686520446973636f72642e')

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/exuric/VPrivate/'..readfile('LarpV4/profiles/commit.txt')..'/'..select(1, path:gsub('LarpV4/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function allowedsync()
	pcall(function()
		local hash = loadstring(downloadFile('LarpV4/libraries/hash.lua'), 'hash')()
		local raw = game:HttpGet('https://raw.githubusercontent.com/exuric/VPrivate/main/whitelist.json', true)
		local d = httpService:JSONDecode(raw)
		if
			type(d) == 'table'
			and type(d.WhitelistedUsers) == 'table'
			and type(hash.hmac) == 'function'
			and d.sig == hash.hmac(hash.sha512, WK, httpService:JSONEncode({WhitelistedUsers = d.WhitelistedUsers}))
		then
for _, v in d.WhitelistedUsers do
			if v.id then
				local uid = tonumber(v.id)
				if uid then
					allowedUsers[uid] = v.name or true
				end
			end
		end
		end
	end)
end

allowedsync()

do
	local player = playersService.LocalPlayer
	local pid = player and tonumber(player.UserId)
	if player and pid and not allowedUsers[pid] then
		player:Kick(AMSG)
		return
	end
end

local function downloadSplit(base)
	if isfile(base) then return readfile(base) end
	local data = {}
	for i = 0, 1 do
		local ok, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/exuric/VPrivate/'..readfile('LarpV4/profiles/commit.txt')..'/'..select(1, base:gsub('^LarpV4/', ''))..'.'..i, true)
		end)
		if not ok or typeof(res) ~= 'string' or res == '404: Not Found' then
			error('Failed to download '..base..'.'..i..(ok and '' or ': '..tostring(res)))
		end
		table.insert(data, res)
	end
	local content = table.concat(data)
	content = '--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.\n'..content
	writefile(base, content)
	return content
end

local function finishLoading()
	larp.Init = nil
	larp:Load()

	local teleportedServers
	larp:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.LarpIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.larpreload = true
				if shared.LarpDeveloper then
					loadstring(readfile('LarpV4/main.lua'), 'main')(_scriptconfig)
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/exuric/VPrivate/'..readfile('LarpV4/profiles/commit.txt')..'/init.lua', true), 'init')(_scriptconfig)
				end
			]]
			local teleportConfig = httpService:JSONEncode(license)
			teleportConfig = teleportConfig:gsub('":true', "=true"):gsub('{"', '{')
			teleportConfig = teleportConfig:gsub(',"', ','):gsub('":', '=')
			teleportConfig = teleportConfig:gsub('%[', '{'):gsub('%]', '}')
			teleportScript = teleportScript:gsub('_key', tostring(license.Key or '_key'))
			teleportScript = teleportScript:gsub('_scriptconfig', teleportConfig)
			if shared.LarpDeveloper then
				teleportScript = 'shared.LarpDeveloper = true\n'..teleportScript
			end
			if shared.LarpCustomProfile then
				teleportScript = 'shared.LarpCustomProfile = "'..shared.LarpCustomProfile..'"\n'..teleportScript
			end
			larp:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.larpreload then
		if not shared.larpreload then
			larp:CreateNotification('Finished Loading', (larp.LarpButton and 'Press the button in the top right' or 'Press '..table.concat(larp.Keybind, ' + '):upper())..' to open GUI', 5)
			task.delay(1, function()
				larp:CreateNotification('LarpV4 Initialized With replaced_username1', 'Larp V4 is now loaded', 5, 'info')
			end)
			task.delay(0.05 + cloneref(game:GetService('RunService')).PostSimulation:Wait(), function()
				if shared.updated then
					local commit = isfile('LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'unknown'
					larp:CreateNotification('Larp V4', `Script has updated from {shared.updated} to {commit}`, 10, 'info')
				end
			end)
		end	
	end
end

if not isfile('LarpV4/profiles/gui.txt') then
	writefile('LarpV4/profiles/gui.txt', 'new')
end
local gui = 'larp'--readfile('LarpV4/profiles/gui.txt')

if not isfolder('LarpV4/assets/'..gui) then
	makefolder('LarpV4/assets/'..gui)
end
larp = loadstring(downloadSplit('LarpV4/guis/'..gui..'.lua'), 'gui')(license)
shared.larp = larp
_G.larp = larp
getgenv().used_init = true

if hookmetamethod then
	pcall(function()
		local old; old = hookmetamethod(game, '__namecall', function(self, Remote, ...)
			if not checkcaller() and getnamecallmethod() == 'FireServer' then
				if typeof(Remote) == "Instance" and Remote.Name == 'TabFreezeAnticheat_ClientToServerReport' then
					return
				end
			end
			return old(self, Remote, ...)
		end)
	end)
end

if not shared.LarpIndependent then
	loadstring(downloadFile('LarpV4/games/universal.lua'), 'universal')(license)
	if isfile('LarpV4/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('LarpV4/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
	else
		if not shared.LarpDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/exuric/VPrivate/'..readfile('LarpV4/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('LarpV4/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
			end
		end
	end
	finishLoading()
else
	larp.Init = finishLoading
	return larp
end