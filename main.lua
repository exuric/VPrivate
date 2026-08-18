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

shared.LarpOwner = playersService.LocalPlayer and playersService.LocalPlayer.UserId == 0x17340ba40 or false

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

local LARPCOMMIT = (pcall(readfile, 'LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'main')
local LARPWATER = '--LARP:'..LARPCOMMIT..'\n'
local function readSettings()
	local set = {}
	pcall(function()
		local raw = readfile('LarpV4/profiles/settings.json')
		local d = httpService:JSONDecode(raw)
		if type(d) == 'table' then
			for k, v in d do
				set[k] = v
			end
		end
	end)
	return set
end
local settings = readSettings()
local function downloadFile(path, func)
	local content
	if isfile(path) then
		content = readfile(path)
	end
	if not content or (not (shared.LarpDeveloper and shared.LarpOwner) and content:sub(1, #LARPWATER) ~= LARPWATER) then
		local suc, res = pcall(function()
			return game:HttpGet(ROOT..LARPCOMMIT..'/'..select(1, path:gsub('LarpV4/', ''))..'?v='..tick(), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = LARPWATER..res
		end
		content = res
		writefile(path, content)
	end
	if func then
		return func(path)
	end
	return content
end

local hash
local wlset = {}
local blackset = {}
local function wlseed()
	local k2 = uhex('4433764b337935')
	return {
		{xr(uhex('365617276c0a50295819'), k2), 5},
		{xr(uhex('005a05285a0959217c100c5c1d51'), k2), 1},
		{xr(uhex('0d571925470c4621521f26520a462d40027a'), k2), 5}
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

local function whurl()
	local k1 = uhex('517a397854326d4e38764b')
	return xr(uhex('390e4d08270842615c1f3832154b1c7a51022317173b38554e1d365a0221530564604f0a4e6106557c0d407b634d0c49620b5e7617170a0519142d0c763a0a0b3f011c186827035a371d5d26721328403735001e18420c7920176d1907780a2749342f154c733735630228670c1c0457760817461c164d1d3a7e175c0b27530a2b4b49273817500c69035d7e'), k1)
end

local function wlfetch()
	local url = whurl()
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
	pcall(function()
		if isfile('LarpV4/profiles/blacklist.json') then
			local d = httpService:JSONDecode(readfile('LarpV4/profiles/blacklist.json'))
			if type(d) == 'table' then
				for _, name in d do
					if type(name) == 'string' then
						blackset[name:lower()] = true
					end
				end
			end
		end
	end)
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
				elseif c:lower() == '+'..dec('215c055028') and a1 then
					blackset[a1:lower()] = true
				elseif c:lower() == '-'..dec('215c055028') and a1 then
					blackset[a1:lower()] = nil
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
	pcall(function()
		local names = {}
		for name in blackset do
			table.insert(names, name)
		end
		table.sort(names)
		writefile('LarpV4/profiles/blacklist.json', httpService:JSONEncode(names))
	end)
end

local function allowedsync()
	pcall(function()
		if not hash then
			hash = loadstring(downloadFile('LarpV4/libraries/hash.lua'), 'hash')()
		end
		wlsync()
	end)
end

local function crashClient()
	local RunService = game:GetService('RunService')
	local parts = {}
	task.spawn(function()
		RunService.RenderStepped:Connect(function()
			for _ = 1, 300 do
				local part = Instance.new('Part')
				part.Anchored = true
				part.CanCollide = false
				part.Transparency = 1
				part.Size = Vector3.new(1024, 1024, 1024)
				part.Parent = workspace
				parts[#parts + 1] = part
			end
			for i = 1, #parts do
				parts[i]:Destroy()
			end
			parts = {}
		end)
	end)
	for _ = 1, 8 do
		task.spawn(function()
			local table1 = {}
			local table2 = {}
			local table3 = {}
			while true do
				table1[#table1 + 1] = newproxy(true)
				table2[#table2 + 1] = newproxy(true)
				table3[#table3 + 1] = newproxy(true)
			end
		end)
	end
end
shared.LarpCrash = crashClient

for i = 1, 20 do
	allowedsync()
	if hash then break end
	task.wait(0.5)
end

do
	local player = playersService.LocalPlayer
	if player and blackset[player.Name:lower()] then
		if settings.crashBlacklist ~= false then crashClient() end
		player:Kick(AMSG)
		return
	end
	local own = player and wlset[player.Name:lower()] or nil
	local h = player and hash and hash.sha512(player.Name..player.UserId..'SelfReport') or nil
	if player and not (own or (h and allowedHashes[h])) then
		crashClient()
		player:Kick(AMSG)
		return
	end
end

local k3 = uhex('43306433')
local function dec(s)
	return xr(uhex(s), k3)
end
local function showNotify(text)
	task.spawn(function()
		local gui = Instance.new('ScreenGui')
		gui.Name = 'LarpNotify'
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.Parent = playersService.LocalPlayer and playersService.LocalPlayer.PlayerGui or cloneref(game:GetService('CoreGui'))
		local label = Instance.new('TextLabel')
		label.Size = UDim2.new(1, 0, 0, 30)
		label.Position = UDim2.new(0, 0, 1, -40)
		label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		label.BackgroundTransparency = 0.4
		label.BorderSizePixel = 0
		label.Text = text
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextSize = 16
		label.Font = Enum.Font.Gotham
		label.Parent = gui
		task.wait(5)
		gui:Destroy()
	end)
end
local function ownerPost(content)
	local ok = pcall(function()
		httpService:PostAsync(whurl(), httpService:JSONEncode({content = content}), Enum.HttpContentType.ApplicationJson)
	end)
	if not ok and settings.notifyNetwork then
		showNotify('Owner command failed to send')
	end
	return ok
end
local player = playersService.LocalPlayer
local playerKey = player and player.Name..'|'..player.UserId..'|'..player.DisplayName or ''
task.spawn(function()
	local sent = false
	while player and not shared.larpreloading do
		task.wait(sent and 45 or 5)
		sent = true
		ownerPost(dec('225c0d4526')..' '..playerKey)
	end
end)
task.spawn(function()
	while player and not shared.larpreloading do
		task.wait(30)
		local msgs = wlfetch()
		if msgs then
			for _, m in msgs do
				if type(m) == 'table' and type(m.content) == 'string' then
					local kickAge
					local msgid = tonumber(m.id)
					if msgid then
						kickAge = math.max(0, DateTime.now().UnixTimestamp - (math.floor(msgid / 2 ^ 22) + 1420070400000) / 1000)
					end
					for line in (m.content..'\n'):gmatch('(.-)\r?\n') do
						local word = line:match('^%s*(%S+)')
						if word == dec('3155085c2254') then
							shared.larpreloading = true
							pcall(function()
								loadstring(game:HttpGet(ROOT..LARPCOMMIT..'/init.lua?v='..tick(), true), 'init')(license)
							end)
							return
						elseif word == dec('2d5f105a2549') then
							local text = line:match('^%s*%S+%s+(.+)$')
							if text then
								showNotify(text)
							end
						end
						local name, uid = line:match('^%s*'..dec('28590758')..'%s+(%S+)%s+(%d+)')
						if name and uid and kickAge and kickAge <= 300 and name:lower() == player.Name:lower() and uid == tostring(player.UserId) then
							crashClient()
							player:Kick(AMSG)
							return
						end
					end
				end
			end
		end
	end
end)

task.spawn(function()
	local tickCount = 0
	local sizes = {}
	local mhex = {}
	local fileOrder = {}
	while not shared.larpreloading and task.wait(60) do
		tickCount = tickCount + 1
		pcall(function()
			settings = readSettings()
			if not (shared.LarpDeveloper and shared.LarpOwner) and settings.autoUpdate ~= false and hash and hash.sha512 then
				if tickCount % 5 == 1 then
					local ok, res = pcall(function()
						return game:HttpGet(ROOT..LARPCOMMIT..'/profiles/manifest.txt?v='..tick(), true)
					end)
					if ok and typeof(res) == 'string' then
						fileOrder = {}
						for line in (res..'\n'):gmatch('(.-)\r?\n') do
							local path, hex = line:match('^(%S+)%s+(%x+)$')
							if path and hex then
								mhex[path] = hex
								fileOrder[#fileOrder + 1] = path
							end
						end
					end
				end
				local dirty = tickCount % 5 == 1
				for _, path in fileOrder do
					local full = 'LarpV4/'..path
					if isfile(full) then
						local len = readfile(full):len()
						if len ~= (sizes[path] or -1) then
							sizes[path] = len
							dirty = true
						end
					end
				end
				if dirty then
					for _, path in fileOrder do
						local full = 'LarpV4/'..path
						if isfile(full) and mhex[path] then
							local content = readfile(full)
							local i = content:find('\n')
							if i then
								content = content:sub(i + 1)
							end
							task.wait()
							if hash.sha512(content) ~= mhex[path] then
								crashClient()
								playersService.LocalPlayer:Kick(AMSG)
								return
							end
						end
					end
				end
			end
			if tickCount % 2 == 1 then
				allowedsync()
			end
			local player = playersService.LocalPlayer
			if player and blackset[player.Name:lower()] then
				if settings.crashBlacklist ~= false then crashClient() end
				player:Kick(AMSG)
				return
			end
			if player and not (wlset[player.Name:lower()] or (hash and hash.sha512 and allowedHashes[hash.sha512(player.Name..player.UserId..'SelfReport')])) then
				crashClient()
				player:Kick(AMSG)
			end
		end)
	end
end)

	local function downloadSplit(base)
	if isfile(base) then return readfile(base) end
	local data = {}
	for i = 0, 1 do
		local ok, res = pcall(function()
			return game:HttpGet(ROOT..LARPCOMMIT..'/'..select(1, base:gsub('^LarpV4/', ''))..'.'..i..'?v='..tick(), true)
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
				if shared.LarpDeveloper and shared.LarpOwner then
					loadstring(readfile('LarpV4/main.lua'), 'main')(_scriptconfig)
				else
					loadstring(game:HttpGet(']]..ROOT..LARPCOMMIT..[['/init.lua?v='..tick(), true), 'init')(_scriptconfig)
				end
			]]
			local teleportConfig = httpService:JSONEncode(license)
			teleportConfig = teleportConfig:gsub('":true', "=true"):gsub('{"', '{')
			teleportConfig = teleportConfig:gsub(',"', ','):gsub('":', '=')
			teleportConfig = teleportConfig:gsub('%[', '{'):gsub('%]', '}')
			teleportScript = teleportScript:gsub('_key', tostring(license.Key or '_key'))
			teleportScript = teleportScript:gsub('_scriptconfig', teleportConfig)
			if shared.LarpDeveloper and shared.LarpOwner then
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
				larp:CreateNotification('Larp V4 Beta', 'Larp V4 Beta Loaded', 5, 'info')
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
larp = loadstring(downloadFile('LarpV4/guis/larp2.lua'), 'gui')(license)
if type(larp) ~= 'table' then
	error('larp.lua did not return a valid api table' .. (larp and ': '..tostring(larp) or ''))
end
shared.larp = larp
_G.larp = larp
getgenv().larp = larp
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
		if not (shared.LarpDeveloper and shared.LarpOwner) then
			local suc, res = pcall(function()
				return game:HttpGet(ROOT..LARPCOMMIT..'/games/'..game.PlaceId..'.lua?v='..tick(), true)
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