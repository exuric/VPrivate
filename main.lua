--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
local license = ... or {}
repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end
license.Key = license.Key or '_key'

local vape
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
	[0] = 'replaced_username1',
}

do
	local player = playersService.LocalPlayer
	if player and not allowedUsers[player.UserId] then
		player:Kick('LarpV4 is locked: account '..player.Name..' ('..player.UserId..') is not authorized. Contact replaced_username1 (exuric) for access.')
		return
	end
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/exuric/VPrivate/'..readfile('LarpV4/profiles/commit.txt')..'/'..select(1, path:gsub('LarpV4/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
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
	content = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..content
	writefile(base, content)
	return content
end

local function finishLoading()
	vape.Init = nil
	vape:Load()

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then
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
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not shared.vapereload then
			vape:CreateNotification('Finished Loading', (vape.VapeButton and 'Press the button in the top right' or 'Press '..table.concat(vape.Keybind, ' + '):upper())..' to open GUI', 5)
			task.delay(1, function()
				vape:CreateNotification('LarpV4 Initialized With replaced_username1', 'Larp V4 is now loaded', 5, 'info')
			end)
			task.delay(0.05 + cloneref(game:GetService('RunService')).PostSimulation:Wait(), function()
				if shared.updated then
					local commit = isfile('LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'unknown'
					vape:CreateNotification('Larp V4', `Script has updated from {shared.updated} to {commit}`, 10, 'info')
				end
			end)
		end	
	end
end

if not isfile('LarpV4/profiles/gui.txt') then
	writefile('LarpV4/profiles/gui.txt', 'new')
end
local gui = 'new'--readfile('LarpV4/profiles/gui.txt')

if not isfolder('LarpV4/assets/'..gui) then
	makefolder('LarpV4/assets/'..gui)
end
vape = loadstring(downloadSplit('LarpV4/guis/'..gui..'.lua'), 'gui')(license)
shared.vape = vape
_G.vape = vape
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

if not shared.VapeIndependent then
	loadstring(downloadFile('LarpV4/games/universal.lua'), 'universal')(license)
	if isfile('LarpV4/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('LarpV4/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
	else
		if not shared.VapeDeveloper then
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
	vape.Init = finishLoading
	return vape
end