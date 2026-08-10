--!nocheck
local license = ... or {}
license.Key = script_key or license.Key

local cloneref = cloneref or function(ref) return ref end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local downloader = Instance.new('TextLabel')
downloader.Size = UDim2.new(1, 0, 0, 40)
downloader.BackgroundTransparency = 1
downloader.TextStrokeTransparency = 0
downloader.TextSize = 20
downloader.TextColor3 = Color3.new(1, 1, 1)
downloader.Font = Enum.Font.Arial
downloader.Text = ''
downloader.Parent = Instance.new('ScreenGui', gethui and gethui() or cloneref(game:GetService('CoreGui')))

local function downloadFile(path, func)
	if not isfile(path) then
		if not license.Closet then
			downloader.Text = 'Downloading '.. (path:gsub('^VapePrivate/', 'Vape Private/'))
		end
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/exuric/VPrivate/'..readfile('VapePrivate/profiles/commit.txt')..'/'..select(1, path:gsub('VapePrivate/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
		downloader.Text = ''
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('init') then continue end
		if file:find('profile') then continue end
		if file:find('assets') then continue end
		if isfile(file) then
			delfile(file)
		elseif isfolder(file) then
			wipeFolder(file)
		end
	end
end


for _, folder in {'VapePrivate', 'VapePrivate/games', 'VapePrivate/profiles', 'VapePrivate/assets', 'VapePrivate/libraries', 'VapePrivate/guis'} do
	if not isfolder(folder) then
		downloader.Text = 'Downloading '.. (folder:gsub('^VapePrivate/', 'Vape Private/'))
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local commit = 'main'
	local stored = isfile('VapePrivate/profiles/commit.txt') and readfile('VapePrivate/profiles/commit.txt') or ''
	local version = isfile('VapePrivate/.version') and readfile('VapePrivate/.version') or ''
	if commit ~= stored or version ~= '31' then
		if stored ~= '' and stored ~= commit then
			shared.updated = stored
		end
		pcall(delfile, 'VapePrivate/main.lua')
		pcall(delfile, 'VapePrivate/guis/new.lua')
		wipeFolder('VapePrivate')
		wipeFolder('VapePrivate/games')
		wipeFolder('VapePrivate/guis')
		wipeFolder('VapePrivate/libraries')
		for _, file in {'VapePrivate/assets/new/VapePriv.png', 'VapePrivate/assets/new/Textv4.png', 'VapePrivate/profiles/default6872274481.txt'} do
			if isfile(file) then
				pcall(delfile, file)
			end
		end
	end
	writefile('VapePrivate/.version', '31')
	writefile('VapePrivate/profiles/commit.txt', commit)
	if #listfiles('VapePrivate/profiles') < 4 then
		shared.VapePresetInstall = function()
			local suc, req = pcall(request, {
				Url = 'https://api.github.com/repos/exuric/VPrivate/contents/profiles',
				Method = 'GET'
			})
			if not suc or req.StatusCode ~= 200 then return false end
			local body = cloneref(game:GetService('HttpService')):JSONDecode(req.Body)
			if not body or typeof(body) ~= 'table' then return false end
			local installed = false
			for _, v in body do
				if v.type == 'file' and pcall(downloadFile, 'VapePrivate/'.. ({v.path:gsub(' ', '%%20')})[1]) then
					installed = true
				end
			end
			return installed
		end
	end
end

downloader.Text = ''
local _vapechunk, _vapeerr = loadstring(downloadFile('VapePrivate/main.lua'), 'main')
if not _vapechunk then
	error('VapePrivate/main.lua failed to compile: '..tostring(_vapeerr))
end
local _vapeok, _vaperes = pcall(_vapechunk, license)
if not _vapeok then
	error('VapePrivate/main.lua: '..tostring(_vaperes))
end
return _vaperes
