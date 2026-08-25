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

shared.LarpOwner = playersService.LocalPlayer and playersService.LocalPlayer.UserId == 0x23d100184 or false

local RTOK = ''
local ROOT = (RTOK ~= '' and 'https://'..RTOK..'@' or 'https://')..'raw.githubusercontent.com/exuric/VPrivate/'
getgenv().LarpReadRoot = ROOT

local LARPCOMMIT = (pcall(readfile, 'LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'main')
local LARPWATER = '--LARP:'..LARPCOMMIT..'\n'
local function downloadFile(path, func)
	local content
	if isfile(path) then
		content = readfile(path)
	end
	if not content or (not (shared.LarpDeveloper and shared.LarpOwner) and content:sub(1, #LARPWATER) ~= LARPWATER) then
		local suc, res = pcall(function()
			return game:HttpGet(ROOT..LARPCOMMIT..'/'..select(1, path:gsub('LarpV4/', '')), true)
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
	local function downloadSplit(base)
	if isfile(base) then return readfile(base) end
	local data = {}
	for i = 0, 1 do
		local ok, res = pcall(function()
			return game:HttpGet(ROOT..LARPCOMMIT..'/'..select(1, base:gsub('^LarpV4/', ''))..'.'..i, true)
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
					loadstring(game:HttpGet(']]..ROOT..LARPCOMMIT..[['/init.lua', true), 'init')(_scriptconfig)
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

task.spawn(function()
	task.wait()
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

	task.spawn(function()
		task.wait()
		if not shared.LarpIndependent then
			loadstring(downloadFile('LarpV4/games/universal.lua'), 'universal')(license)
			if isfile('LarpV4/games/'..game.PlaceId..'.lua') then
				loadstring(readfile('LarpV4/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
			else
				if not (shared.LarpDeveloper and shared.LarpOwner) then
					local suc, res = pcall(function()
						return game:HttpGet(ROOT..LARPCOMMIT..'/games/'..game.PlaceId..'.lua', true)
					end)
					if suc and res ~= '404: Not Found' then
						loadstring(downloadFile('LarpV4/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
					end
				end
			end
			finishLoading()
		else
			larp.Init = finishLoading
		end
	end)
end)

if shared.LarpIndependent then
	return larp
end