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
local MANIFEST = {}

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
local SELFCOMMIT = 'dba3a3ef9baf14dac5e2c8bc5d64f0edd5d46d2c'

local function fetchCommit()
	local ok, res = pcall(function()
		return game:HttpGet(ROOT..'profiles/commit.txt?v='..tick(), true)
	end)
	if ok and res then
		local commit = res:gsub('%s+$', ''):gsub('^%s+', '')
		if #commit > 20 then
			return commit
		end
	end
	return SELFCOMMIT
end

local COMMIT = fetchCommit()
local LARPWATER = '--LARP:'..COMMIT..'\n'

local OID = 0x17340ba40
local ISOWNER = false
pcall(function()
	local p = cloneref(game:GetService('Players')).LocalPlayer
	ISOWNER = p and p.UserId == OID or false
end)
shared.LarpOwner = ISOWNER

local function downloadFile(path, func)
	local outdated = not isfile(path)
	if not outdated and path:find('.lua') then
		outdated = readfile(path):sub(1, #LARPWATER) ~= LARPWATER
	end
	if outdated then
		if not license.Closet then
			downloader.Text = 'Downloading '.. select(1, path:gsub('LarpV4/', ''))
		end
local key = select(1, path:gsub('LarpV4/', ''))
		local data = {}
		if MANIFEST[key..'.0'] then
			for i = 0, 99 do
				local part = key..'.'..i
				if not MANIFEST[part] then break end
				local suc, res = pcall(function()
					return game:HttpGet(ROOT..COMMIT..'/'..part..'?v='..tick(), true)
				end)
				if not suc or res == '404: Not Found' then
					error(res)
				end
				data[#data + 1] = res
				pcall(writefile, path..'.'..i, res)
			end
		else
			local suc, res = pcall(function()
				return game:HttpGet(ROOT..COMMIT..'/'..key..'?v='..tick(), true)
			end)
			if not suc or res == '404: Not Found' then
				error(res)
			end
			data[1] = res
		end
		local res = table.concat(data)
		if path:find('.lua') then
			res = LARPWATER..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local hash
local VERIFY_FILES = {
	'main.lua',
	'guis/larp2.lua',
	'libraries/entity.lua',
	'libraries/hash.lua',
	'libraries/prediction.lua',
	'games/universal.lua',
	'games/6872274481.lua',
	'games/8444591321.lua',
}

do
	local ok, res = pcall(function()
		return game:HttpGet(ROOT..COMMIT..'/profiles/manifest.txt?v='..tick(), true)
	end)
	if ok and res then
		for line in (res..'\n'):gmatch('(.-)\r?\n') do
			local path, hex = line:match('^(%S+)%s+(%x+)$')
			if path and hex then
				MANIFEST[path] = hex
			end
		end
	end
end

local function fileDigest(path)
	local content = readfile(path)
	local i = content:find('\n')
	if i then
		content = content:sub(i + 1)
	end
	return hash.sha512(content)
end

local function verifyFiles()
	pcall(delfile, 'LarpV4/libraries/hash.lua')
	hash = loadstring(downloadFile('LarpV4/libraries/hash.lua'), 'hash')()
	for _, path in VERIFY_FILES do
		local full = 'LarpV4/'..path
		local expected = MANIFEST[path]
		if expected and (not isfile(full) or not pcall(function()
			return fileDigest(full) == expected
		end)) then
			local verified = false
			for attempt = 1, 3 do
				pcall(delfile, full)
				pcall(function()
					downloadFile(full, function(c) return c end)
				end)
				if pcall(function()
					return fileDigest(full) == expected
				end) then
					verified = true
					break
				end
				task.wait(1)
			end
			if not verified then
				error('LarpV4: integrity check failed for '..path)
			end
		end
	end
end

if not (shared.LarpDeveloper and ISOWNER) then
	verifyFiles()
end

downloader.Text = ''

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

if not (shared.LarpDeveloper and ISOWNER) then
	local stored = isfile('LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or ''
	if stored ~= COMMIT then
		if stored ~= '' then
			shared.updated = stored
		end
		writefile('LarpV4/profiles/commit.txt', COMMIT)
		pcall(delfile, 'LarpV4/main.lua')
		pcall(delfile, 'LarpV4/guis/larp.lua')
		pcall(delfile, 'LarpV4/guis/larp2.lua')
		for _, file in {'LarpV4/6872274481.lua', 'LarpV4/8444591321.lua', 'LarpV4/universal.lua', 'LarpV4/entity.lua', 'LarpV4/prediction.lua', 'LarpV4/hash.lua', 'LarpV4/larp2.lua', 'LarpV4/larp.lua'} do
			if isfile(file) then
				pcall(delfile, file)
			end
		end
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
