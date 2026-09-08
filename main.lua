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

shared.LarpOwner = false
do
	local _p = playersService.LocalPlayer
	if not _p then task.wait(1); _p = playersService.LocalPlayer end
	if not _p then return end
	if _p.UserId == 0x23d100184 then
		shared.LarpOwner = true
	else
		local _ok = false
		local _hx = '4433764b337935'
		local _k = ''
		for _i = 1, #_hx, 2 do _k = _k .. string.char(tonumber(_hx:sub(_i, _i + 1), 16)) end
		local function _x(s) local b = {} for i = 1, #s, 2 do b[#b+1] = string.char(tonumber(s:sub(i, i+1), 16)) end return table.concat(b) end
		local function _r(s, k) local b, m = {}, 0 for i = 1, #s do m = m % #k + 1 local r, a, c = 0, s:byte(i), k:byte(m) for j = 0, 7 do if math.floor(a/(2^j))%2 ~= math.floor(c/(2^j))%2 then r = r + 2^j end end b[#b+1] = string.char(r) end return table.concat(b) end
		pcall(function()
			local _n = _p.Name:lower()
			for _, _s in {_r(_x('005a05285a0959217c100c5c1d51'), _k):lower(), _r(_x('0d571925470c4621521f26520a462d40027a'), _k):lower()} do
				if _n == _s then _ok = true end
			end
			-- IllIIllIIIlllIllIl (lowercased) is granted owner/dev tier
			if _n == _r(_x('2d5f1a225a15592d5a1f275f155c285f1f27'), _k):lower() then
				_ok = true
				shared.LarpOwner = true
			end
		end)
		if not _ok then pcall(function() _p:Kick('You are not whitelisted.') end) return end
	end
end

local RTOK = ''
local ROOT = (RTOK ~= '' and 'https://'..RTOK..'@' or 'https://')..'raw.githubusercontent.com/exuric/VPrivate/'
getgenv().LarpReadRoot = ROOT

local LARPCOMMIT = (pcall(readfile, 'LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'main')
local LARPWATER = '--LARP:'..LARPCOMMIT..'\n'
local _pending = {}
local _dstats = {hits = 0, misses = 0, retries = 0}

local function downloadFile(path, func)
	local content
	if isfile(path) then
		content = readfile(path)
	end
	if not content or #content < 100 or (not (shared.LarpDeveloper and shared.LarpOwner) and content:sub(1, #LARPWATER) ~= LARPWATER) then
		_dstats.misses += 1
		if _pending[path] then
			repeat task.wait(0.1) until not _pending[path]
			content = isfile(path) and readfile(path) or nil
		else
			_pending[path] = true
			local relative = select(1, path:gsub('LarpV4/', ''))
			local urls = {
				ROOT..LARPCOMMIT..'/'..relative,
				'https://cdn.jsdelivr.net/gh/exuric/VPrivate@'..LARPCOMMIT..'/'..relative
			}
			local suc, res
			for i = 1, 8 do
				local url = urls[(i - 1) % 2 + 1]
				suc, res = pcall(function() return game:HttpGet(url, true) end)
				if suc and res ~= '404: Not Found' and not (#res < 100 and path:find('.lua')) then break end
				_dstats.retries += 1
				task.wait(math.min(0.4 * i, 2))
			end
			_pending[path] = nil
			if not suc or res == '404: Not Found' or (#res < 100 and path:find('.lua')) then
				error(res or 'Download failed')
			end
			if path:find('.lua') then
				res = LARPWATER..res
			end
		content = res
		writefile(path, content)
		getgenv().LarpDownloaded = (getgenv().LarpDownloaded or 0) + 1
		end
	else
		_dstats.hits += 1
	end
	if func then
		return func(path)
	end
	return content
end

local function downloadConcurrent(paths)
	local done = 0
	for _, path in paths do
		task.spawn(function()
			pcall(downloadFile, path)
			done += 1
		end)
	end
	while done < #paths do task.wait(0.05) end
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
		local ok, res
		for attempt = 1, 3 do
			ok, res = pcall(function()
				return game:HttpGet(ROOT..'main/'..select(1, base:gsub('^LarpV4/', ''))..'.'..i, true)
			end)
			if ok and typeof(res) == 'string' and res ~= '404: Not Found' then break end
			_dstats.retries += 1
			if attempt < 3 then task.wait(0.5 * attempt) end
		end
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
					loadstring(game:HttpGet(']]..ROOT..'main'..[['/init.lua', true), 'init')(_scriptconfig)
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
				larp:CreateNotification('Larp V4', 'Larp V4 Loaded', 5, 'info')
			end)
			task.delay(0.05 + cloneref(game:GetService('RunService')).PostSimulation:Wait(), function()
				if shared.updated then
					local commit = isfile('LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'unknown'
					larp:CreateNotification('Larp V4', 'Script has updated from '..tostring(shared.updated)..' to '..commit, 10, 'info')
				end
			end)
		task.delay(3, function()
			larp:CreateNotification('Larp V4', 'Security & performance update applied - some features may behave differently', 8, 'warning')
		end)
		if shared.LarpLanguage and shared.LarpLanguage ~= 'English' then
			local loadedTemplates = {Spanish = 'Cargado correctamente en español', French = 'Chargé avec succès en français', German = 'Erfolgreich geladen auf Deutsch', Portuguese = 'Carregado com sucesso em português'}
			task.delay(2, function()
				larp:CreateNotification('Larp V4', loadedTemplates[shared.LarpLanguage] or 'Language loaded', 5, 'info')
			end)
		end
		end	
	end
end

if not isfile('LarpV4/profiles/gui.txt') then
	writefile('LarpV4/profiles/gui.txt', 'new')
end
local gui = 'larp'--readfile('LarpV4/profiles/gui.txt')

local function onboardingParent()
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	local plr = playersService.LocalPlayer
	if plr then
		local pg = plr:FindFirstChildOfClass('PlayerGui')
		if pg then return pg end
	end
	return cloneref(game:GetService('CoreGui'))
end
local function onboardingPanel(title, sub)
	local done = Instance.new('BindableEvent')
	local gui = Instance.new('ScreenGui')
	gui.Name = 'LarpOnboarding'
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = onboardingParent()
	local dim = Instance.new('TextButton')
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new()
	dim.BackgroundTransparency = 0.4
	dim.AutoButtonColor = false
	dim.Text = ''
	dim.Parent = gui
	local panel = Instance.new('Frame')
	panel.Size = UDim2.fromOffset(320, 200)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = panel
	local titleLabel = Instance.new('TextLabel')
	titleLabel.Size = UDim2.new(1, -28, 0, 26)
	titleLabel.Position = UDim2.fromOffset(14, 14)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = panel
	local subLabel = Instance.new('TextLabel')
	subLabel.Size = UDim2.new(1, -28, 0, 40)
	subLabel.Position = UDim2.fromOffset(14, 42)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = sub
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.TextYAlignment = Enum.TextYAlignment.Top
	subLabel.TextWrapped = true
	subLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
	subLabel.TextSize = 13
	subLabel.Font = Enum.Font.Gotham
	subLabel.Parent = panel
	return gui, panel, done
end
local function showDiscordPopup()
	local gui, panel, done = onboardingPanel('First time using Larp?', 'Join our Discord for updates, announcements and support.')
	local discord = Instance.new('TextButton')
	discord.Size = UDim2.new(1, -28, 0, 34)
	discord.Position = UDim2.fromOffset(14, 108)
	discord.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	discord.AutoButtonColor = false
	discord.Text = 'Discord'
	discord.TextColor3 = Color3.new(1, 1, 1)
	discord.TextSize = 14
	discord.Font = Enum.Font.GothamBold
	discord.BorderSizePixel = 0
	discord.Parent = panel
	local dc = Instance.new('UICorner')
	dc.CornerRadius = UDim.new(0, 6)
	dc.Parent = discord
	local no = Instance.new('TextButton')
	no.Size = UDim2.new(1, -28, 0, 34)
	no.Position = UDim2.fromOffset(14, 150)
	no.BackgroundColor3 = Color3.fromRGB(45, 44, 45)
	no.AutoButtonColor = false
	no.Text = 'No Thanks'
	no.TextColor3 = Color3.fromRGB(200, 200, 200)
	no.TextSize = 14
	no.Font = Enum.Font.Gotham
	no.BorderSizePixel = 0
	no.Parent = panel
	local nc = Instance.new('UICorner')
	nc.CornerRadius = UDim.new(0, 6)
	nc.Parent = no
	discord.MouseButton1Click:Connect(function()
		pcall(setclipboard, 'https://discord.gg/g55Vbzfeum')
		done:Fire()
	end)
	no.MouseButton1Click:Connect(function()
		done:Fire()
	end)
	done.Event:Wait()
	gui:Destroy()
end
local langIds = {'English', 'Spanish', 'French', 'German', 'Portuguese'}
local langDisplay = {English = 'English (default)', Spanish = 'Español', French = 'Français', German = 'Deutsch', Portuguese = 'Português'}
local function showLanguagePopup()
	local gui, panel, done = onboardingPanel('Welcome to Larp V4', 'Choose your preferred language')
	panel.Size = UDim2.fromOffset(320, 320)
	local picked = {'English'}
	local rows = {}
	local function refresh()
		for id, btn in rows do
			local on = id == picked[1]
			btn.BackgroundColor3 = on and Color3.fromRGB(45, 44, 45) or Color3.fromRGB(26, 25, 26)
			btn.TextColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 140)
		end
	end
	for i, id in langIds do
		local btn = Instance.new('TextButton')
		btn.Size = UDim2.new(1, -28, 0, 30)
		btn.Position = UDim2.fromOffset(14, 86 + (i - 1) * 34)
		btn.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
		btn.AutoButtonColor = false
		btn.Text = '      '..(langDisplay[id] or id)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextColor3 = Color3.fromRGB(140, 140, 140)
		btn.TextSize = 14
		btn.Font = Enum.Font.Gotham
		btn.BorderSizePixel = 0
		btn.Parent = panel
		local bc = Instance.new('UICorner')
		bc.CornerRadius = UDim.new(0, 5)
		bc.Parent = btn
		btn.MouseButton1Click:Connect(function()
			picked[1] = id
			refresh()
		end)
		rows[id] = btn
	end
	refresh()
	local confirm = Instance.new('TextButton')
	confirm.Size = UDim2.new(1, -28, 0, 34)
	confirm.Position = UDim2.fromOffset(14, 262)
	confirm.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	confirm.AutoButtonColor = false
	confirm.Text = 'Confirm'
	confirm.TextColor3 = Color3.new(0.19, 0.19, 0.19)
	confirm.TextSize = 14
	confirm.Font = Enum.Font.GothamBold
	confirm.BorderSizePixel = 0
	confirm.Parent = panel
	local cc = Instance.new('UICorner')
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent = confirm
	confirm.MouseButton1Click:Connect(function()
		done:Fire()
	end)
	done.Event:Wait()
	gui:Destroy()
	return picked[1]
end
task.spawn(function()
	task.wait()
	local savedLang
	pcall(function()
		if isfile('LarpV4/profiles/language.txt') then
			savedLang = readfile('LarpV4/profiles/language.txt')
		end
	end)
	if savedLang then savedLang = savedLang:gsub('%s+', '') end
	local validLangs = {English = true, Spanish = true, French = true, German = true, Portuguese = true}
	if not savedLang or not validLangs[savedLang] then
		showDiscordPopup()
		savedLang = showLanguagePopup()
		pcall(writefile, 'LarpV4/profiles/language.txt', savedLang)
	end
	shared.LarpLanguage = savedLang
	getgenv().LarpLanguage = savedLang
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
					local ok, err = pcall(function()
						loadstring(downloadFile('LarpV4/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
					end)
					if not ok then
						local msg = tostring(err or '')
						if msg:find('404') or msg:find('Not Found') then
							pcall(function()
								larp:CreateNotification('LarpV4', 'No script for this game (PlaceId '..game.PlaceId..')', 6, 'alert')
							end)
						end
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