--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
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

local RTOK = ''
local ROOT = (RTOK ~= '' and 'https://'..RTOK..'@' or 'https://')..'raw.githubusercontent.com/exuric/VPrivate/'
local SELFCOMMIT = '15d6f08619c5b6db6bc3f858306bd3d9f8c277f7'
local LARPWATER = '--LARP:'..SELFCOMMIT..'\n'

local function downloadFile(path, func)
	if not isfile(path) or readfile(path):sub(1, #LARPWATER) ~= LARPWATER then
		if not license.Closet then
			downloader.Text = 'Downloading '.. select(1, path:gsub('LarpV4/', ''))
		end
		local suc, res = pcall(function()
			return game:HttpGet(ROOT..readfile('LarpV4/profiles/commit.txt')..'/'..select(1, path:gsub('LarpV4/', ''))..'?v='..tick(), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = LARPWATER..res
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


for _, folder in {'LarpV4', 'LarpV4/games', 'LarpV4/profiles', 'LarpV4/assets', 'LarpV4/libraries', 'LarpV4/guis'} do
	if not isfolder(folder) then
		downloader.Text = 'Downloading '.. (folder:gsub('^LarpV4/', 'LarpV4/'))
		makefolder(folder)
	end
end

if not shared.LarpDeveloper then
	local stored = isfile('LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or ''
	if stored ~= SELFCOMMIT then
		if stored ~= '' then
			shared.updated = stored
		end
		writefile('LarpV4/profiles/commit.txt', SELFCOMMIT)
		pcall(delfile, 'LarpV4/main.lua')
		pcall(delfile, 'LarpV4/guis/larp.lua')
		pcall(delfile, 'LarpV4/guis/larp2.lua')
		wipeFolder('LarpV4/games')
		wipeFolder('LarpV4/guis')
		wipeFolder('LarpV4/libraries')
		wipeFolder('LarpV4/assets')
		for _, file in {'LarpV4/assets/larp/Larp.png', 'LarpV4/assets/larp/Textv4.png'} do
			if isfile(file) then
				pcall(delfile, file)
			end
		end
	end
	writefile('LarpV4/.version', '122')
	if #listfiles('LarpV4/profiles') < 4 then
		shared.LarpPresetInstall = function()
			local headers = {}
			if RTOK ~= '' then headers.Authorization = 'token '..RTOK end
			local suc, req = pcall(request, {
				Url = 'https://api.github.com/repos/exuric/VPrivate/contents/profiles',
				Method = 'GET',
				Headers = headers
			})
			if not suc or req.StatusCode ~= 200 then return false end
			local body = cloneref(game:GetService('HttpService')):JSONDecode(req.Body)
			if not body or typeof(body) ~= 'table' then return false end
			local installed = false
			for _, v in body do
				if v.type == 'file' and pcall(downloadFile, 'LarpV4/'.. ({v.path:gsub(' ', '%%20')})[1]) then
					installed = true
				end
			end
			return installed
		end
	end
end

downloader.Text = ''
local _larpchunk, _larperr = loadstring(downloadFile('LarpV4/main.lua'), 'main')
if not _larpchunk then
	error('LarpV4/main.lua failed to compile: '..tostring(_larperr))
end
local _larpok, _larpres = pcall(_larpchunk, license)
if not _larpok then
	error('LarpV4/main.lua: '..tostring(_larpres))
end
return _larpres
