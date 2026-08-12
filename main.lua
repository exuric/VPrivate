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

local allowedHashes = {}

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

local RTOK = ''
local ROOT = (RTOK ~= '' and 'https://'..RTOK..'@' or 'https://')..'raw.githubusercontent.com/exuric/VPrivate/'
getgenv().LarpReadRoot = ROOT

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet(ROOT..readfile('LarpV4/profiles/commit.txt')..'/'..select(1, path:gsub('LarpV4/', '')), true)
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

local hash
local wlset = {}
local wlapplied = false
local function wlseed()
	local k2 = uhex('4433764b337935')
	return {
		{xr(uhex('365617276c0a50295819'), k2), 5},
		{xr(uhex('005a05285a0959217c100c5c1d51'), k2), 1}
	}
end

local function wlapply(list)
	table.clear(wlset)
	for _, v in list do
		if type(v) == 'table' then
			if type(v.name) == 'string' then wlset[v.name:lower()] = v.level end
			if type(v.hash) == 'string' then allowedHashes[v.hash] = true end
		end
	end
end

local function wlfetch()
	local k1 = uhex('517a397854326d4e38764b')
	local url = xr(uhex('390e4d08270842615c1f3832154b1c7a51022317173b38554e1d365a0221530564604f0a4e6106557c0d407b634d0c49620b5e7617170a0519142d0c763a0a0b3f011c186827035a371d5d26721328403735001e18420c7920176d1907780a2749342f154c733735630228670c1c0457760817461c164d1d3a7e175c0b27530a2b4b49273817500c69035d7e'), k1)
	local ok, res = pcall(function()
		return game:HttpGet(url, true)
	end)
	if not ok or typeof(res) ~= 'string' then
		local ok2, res2 = pcall(function()
			local req = request and request({Url = url, Method = 'GET', Headers = {['User-Agent'] = 'Mozilla/5.0'}}) or http_request and http_request({Url = url, Method = 'GET'})
			return req and (req.Body or req.body)
		end)
		if not ok2 or typeof(res2) ~= 'string' or res2 == '' then return nil end
		res = res2
	end
	local ok3, msgs = pcall(function()
		return httpService:JSONDecode(res)
	end)
	if not ok3 or type(msgs) ~= 'table' or not msgs[1] and next(msgs) then return nil end
	if next(msgs) then
		pcall(table.sort, msgs, function(a, b)
			return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
		end)
	end
	return msgs
end

local function wlsync()
	local msgs = wlfetch()
	if not msgs then
		local list = {}
		for _, s in wlseed() do
			table.insert(list, {name = s[1], level = s[2]})
		end
		pcall(function()
			local raw = readfile('LarpV4/profiles/whitelist.json')
			local d = httpService:JSONDecode(raw)
			if type(d) == 'table' and type(d.users) == 'table' and hash and hash.hmac and hash.hmac(hash.sha512, WK, httpService:JSONEncode({users = d.users})) == d.sig then
				for _, v in d.users do
					table.insert(list, v)
				end
			end
		end)
		wlapply(list)
		return
	end
	local k3 = uhex('43306433')
	local function dec(s)
		return xr(uhex(s), k3)
	end
	local adds = {}
	for _, m in msgs do
		if type(m) == 'table' and type(m.content) == 'string' then
			for line in (m.content..'\n'):gmatch('(.-)\r?\n') do
				local c = line:match('^%s*(%S+)')
				local a1 = line:match('^%s*%S+%s+(%S+)')
				local a2 = line:match('^%s*%S+%s+%S+%s+(%S+)')
				if c then
					if c:lower() == dec('225400') and a1 and a2 then
						local lvl = a2:lower() == dec('2c470a5631') and 5 or 1
						adds[a1:lower()] = {name = a1, level = lvl}
					elseif c:lower() == dec('275508') and a1 then
						if adds[a1:lower()] then adds[a1:lower()] = nil end
					elseif c:lower() == dec('3155175637') then
						table.clear(adds)
					end
				end
			end
		end
	end
	for _, s in wlseed() do
		if not adds[s[1]:lower()] then
			adds[s[1]:lower()] = {name = s[1], level = s[2]}
		end
	end
	local list = {}
	for _, v in adds do
		table.insert(list, v)
	end
	wlapply(list)
	pcall(function()
		if hash and hash.hmac then
			local sig = hash.hmac(hash.sha512, WK, httpService:JSONEncode({users = list}))
			writefile('LarpV4/profiles/whitelist.json', httpService:JSONEncode({users = list, sig = sig}))
		end
	end)
end

local function wlkick()
	local player = playersService.LocalPlayer
	local own = player and wlset[player.Name:lower()] or nil
	local h = player and hash and hash.sha512(player.Name..player.UserId..'SelfReport') or nil
	if player and not (own or (h and allowedHashes[h])) then
		player:Kick(AMSG)
		return true
	end
	return false
end

local function allowedsync()
	pcall(function()
		hash = hash or loadstring(downloadFile('LarpV4/libraries/hash.lua'), 'hash')()
		if not hash then return end
		if not wlapplied then
			local ok, cached = pcall(function()
				local raw = readfile('LarpV4/profiles/whitelist.json')
				local d = httpService:JSONDecode(raw)
				if type(d) == 'table' and type(d.users) == 'table' and hash.hmac and hash.hmac(hash.sha512, WK, httpService:JSONEncode({users = d.users})) == d.sig then
					return d.users
				end
			end)
			if ok and type(cached) == 'table' and #cached > 0 then
				local list = {}
				for _, s in wlseed() do
					table.insert(list, {name = s[1], level = s[2]})
				end
				for _, v in cached do
					table.insert(list, v)
				end
				wlapply(list)
				wlapplied = true
				task.spawn(function()
					pcall(wlsync)
					wlkick()
				end)
				return
			end
			wlsync()
			wlapplied = true
		end
	end)
end

for i = 1, 20 do
	allowedsync()
	if wlapplied then break end
	task.wait(0.5)
end

if wlkick() then return end

local function downloadSplit(base)
	if isfile(base) then return readfile(base) end
	local data = {}
	local remaining = 2
	local failed = false
	for i = 0, 1 do
		task.spawn(function()
			local ok, res = pcall(function()
				return game:HttpGet(ROOT..readfile('LarpV4/profiles/commit.txt')..'/'..select(1, base:gsub('^LarpV4/', ''))..'.'..i, true)
			end)
			if not ok or typeof(res) ~= 'string' or res == '404: Not Found' then
				failed = true
			else
				data[i] = res
			end
			remaining = remaining - 1
		end)
	end
	repeat task.wait() until remaining == 0
	if failed then
		error('Failed to download '..base)
	end
	local content = table.concat({data[0], data[1]})
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
					loadstring(game:HttpGet(']]..ROOT..[['..readfile('LarpV4/profiles/commit.txt')..'/init.lua', true), 'init')(_scriptconfig)
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
				larp:CreateNotification('Larp V4 Beta Loaded', 'Larp V4 is now loaded', 5, 'warning')
			end)
			task.delay(0.05 + cloneref(game:GetService('RunService')).PostSimulation:Wait(), function()
				if shared.updated then
					local commit = isfile('LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'unknown'
					larp:CreateNotification('Larp V4', 'Script has updated from '..tostring(shared.updated)..' to '..commit, 10, 'info')
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
	local gamepath = 'LarpV4/games/'..game.PlaceId..'.lua'
	if isfile(gamepath) then
		loadstring(readfile(gamepath), tostring(game.PlaceId))(license)
	elseif not shared.LarpDeveloper and not isfile('LarpV4/games/.missing.'..game.PlaceId) then
		local suc, res = pcall(function()
			return game:HttpGet(ROOT..readfile('LarpV4/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
		end)
		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile(gamepath), tostring(game.PlaceId))(license)
		else
			writefile('LarpV4/games/.missing.'..game.PlaceId, '1')
		end
	end
	finishLoading()
else
	larp.Init = finishLoading
	return larp
end