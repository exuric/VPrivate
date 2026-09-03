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
local BRANCH = 'main'
local ROOT = (RTOK ~= '' and 'https://'..RTOK..'@' or 'https://')..'raw.githubusercontent.com/exuric/VPrivate/'
local SELFCOMMIT = '8907ad22f3d65f326f389e73bd88ce53a62877de'

local function fetchCommit()
	local ok, res = pcall(function()
		return game:HttpGet(ROOT..BRANCH..'/profiles/commit.txt', true)
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

local OID = 0x23d100184
local ISOWNER = false
pcall(function()
	local p = cloneref(game:GetService('Players')).LocalPlayer
	ISOWNER = p and p.UserId == OID or false
end)
shared.LarpOwner = ISOWNER

local function downloadFile(path, func)
	local outdated = not isfile(path)
	if not outdated and path:find('.lua') then
		local cached = readfile(path)
		outdated = #cached < 100 or cached:sub(1, #LARPWATER) ~= LARPWATER
	end
	if outdated then
		if not license.Closet then
			downloader.Text = 'Downloading '.. select(1, path:gsub('LarpV4/', ''))
		end
		local relative = select(1, path:gsub('LarpV4/', ''))
		local urls = {
			ROOT..BRANCH..'/'..relative,
			'https://cdn.jsdelivr.net/gh/exuric/VPrivate@'..BRANCH..'/'..relative
		}
		local suc, res
		for i = 1, 8 do
			local url = urls[(i - 1) % 2 + 1]
			suc, res = pcall(function()
				return game:HttpGet(url, true)
			end)
			if suc and res ~= '404: Not Found' and not (#res < 100 and path:find('.lua')) then break end
			task.wait(math.min(0.4 * i, 2))
		end
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if #res < 100 and path:find('.lua') then
			error('LarpV4: empty download for '..path)
		end
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
	'games/100702124803290.lua',
}

local MANIFEST = {}

local function fetchManifest()
	table.clear(MANIFEST)
	local ok, res = pcall(function()
		return game:HttpGet(ROOT..BRANCH..'/profiles/manifest.txt', true)
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

local bit32_band, bit32_bxor = bit32.band, bit32.bxor
local bit32_lshift, bit32_rshift = bit32.lshift, bit32.rshift
local bit32_lrotate, bit32_rrotate = bit32.lrotate, bit32.rrotate
local TWO56_POW_7 = 256 ^ 7
local common_W = {}
local sha2_K_lo = {3609767458,602891725,3964484399,2173295548,4081628472,3053834265,2937671579,3664609560,2734883394,1164996542,1323610764,3590304994,4068182383,991336113,633803317,3479774868,2666613458,944711139,2341262773,2007800933,1495990901,1856431235,3175218132,2198950837,3999719339,766784016,2566594879,3203337956,1034457026,2466948901,3758326383,168717936,1188179964,1546045734,1522805485,2643833823,2343527390,1014477480,1206759142,344077627,1290863460,3158454273,3505952657,106217008,3606008344,1432725776,1467031594,851169720,3100823752,1363258195,3750685593,3785050280,3318307427,3812723403,2003034995,3602036899,1575990012,1125592928,2716904306,442776044,593698344,3733110249,2999351573,3815920427,3928383900,566280711,3454069534,4000239992,1914138554,2731055270,3203993006,320620315,587496836,1086792851,365543100,2618297676,3409855158,4234509866,987167468,1246189591}
local sha2_K_hi = {1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748,2870763221,3624381080,310598401,607225278,1426881987,1925078388,2162078206,2614888103,3248222580,3835390401,4022224774,264347078,604807628,770255983,1249150122,1555081692,1996064986,2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,113926993,338241895,666307205,773529912,1294757372,1396182291,1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,3259730800,3345764771,3516065817,3600352804,4094571909,275423344,430227734,506948616,659060556,883997877,958139571,1322822218,1537002063,1747873779,1955562222,2024104815,2227730452,2361852424,2428436474,2756734187,3204031479,3329325298,3391569614,3515267271,3940187606,4118630271,116418474,174292421,289380356,460393269,685471733,852142971,1017036298,1126000580,1288033470,1501505948,1607167915,1816402316}
local sha2_H_lo = {4089235720,2227873595,4271175723,1595750129,2917565137,725511199,4215389547,327033209}
local sha2_H_hi = {1779033703,3144134277,1013904242,2773480762,1359893119,2600822924,528734635,1541459225}
local function sha512_feed_128(H_lo, H_hi, str, offs, size)
	local W, K_lo, K_hi = common_W, sha2_K_lo, sha2_K_hi
	local h1_lo, h2_lo, h3_lo, h4_lo, h5_lo, h6_lo, h7_lo, h8_lo = H_lo[1], H_lo[2], H_lo[3], H_lo[4], H_lo[5], H_lo[6], H_lo[7], H_lo[8]
	local h1_hi, h2_hi, h3_hi, h4_hi, h5_hi, h6_hi, h7_hi, h8_hi = H_hi[1], H_hi[2], H_hi[3], H_hi[4], H_hi[5], H_hi[6], H_hi[7], H_hi[8]
	for pos = offs, offs + size - 1, 128 do
		for j = 1, 16 * 2 do
			pos = pos + 4
			local a, b, c, d = string.byte(str, pos - 3, pos)
			W[j] = ((a * 256 + b) * 256 + c) * 256 + d
		end
		for jj = 34, 160, 2 do
			local a_lo, a_hi, b_lo, b_hi = W[jj - 30], W[jj - 31], W[jj - 4], W[jj - 5]
			local tmp1 = bit32_bxor(bit32_rshift(a_lo, 1) + bit32_lshift(a_hi, 31), bit32_rshift(a_lo, 8) + bit32_lshift(a_hi, 24), bit32_rshift(a_lo, 7) + bit32_lshift(a_hi, 25)) % 4294967296 +
				bit32_bxor(bit32_rshift(b_lo, 19) + bit32_lshift(b_hi, 13), bit32_lshift(b_lo, 3) + bit32_rshift(b_hi, 29), bit32_rshift(b_lo, 6) + bit32_lshift(b_hi, 26)) % 4294967296 +
				W[jj - 14] + W[jj - 32]
			local tmp2 = tmp1 % 4294967296
			W[jj - 1] = bit32_bxor(bit32_rshift(a_hi, 1) + bit32_lshift(a_lo, 31), bit32_rshift(a_hi, 8) + bit32_lshift(a_lo, 24), bit32_rshift(a_hi, 7)) +
				bit32_bxor(bit32_rshift(b_hi, 19) + bit32_lshift(b_lo, 13), bit32_lshift(b_hi, 3) + bit32_rshift(b_lo, 29), bit32_rshift(b_hi, 6)) +
				W[jj - 15] + W[jj - 33] + (tmp1 - tmp2) / 4294967296
			W[jj] = tmp2
		end
		local a_lo, b_lo, c_lo, d_lo, e_lo, f_lo, g_lo, h_lo = h1_lo, h2_lo, h3_lo, h4_lo, h5_lo, h6_lo, h7_lo, h8_lo
		local a_hi, b_hi, c_hi, d_hi, e_hi, f_hi, g_hi, h_hi = h1_hi, h2_hi, h3_hi, h4_hi, h5_hi, h6_hi, h7_hi, h8_hi
		for j = 1, 80 do
			local jj = 2 * j
			local tmp1 = bit32_bxor(bit32_rshift(e_lo, 14) + bit32_lshift(e_hi, 18), bit32_rshift(e_lo, 18) + bit32_lshift(e_hi, 14), bit32_lshift(e_lo, 23) + bit32_rshift(e_hi, 9)) % 4294967296 +
				(bit32_band(e_lo, f_lo) + bit32_band(-1 - e_lo, g_lo)) % 4294967296 +
				h_lo + K_lo[j] + W[jj]
			local z_lo = tmp1 % 4294967296
			local z_hi = bit32_bxor(bit32_rshift(e_hi, 14) + bit32_lshift(e_lo, 18), bit32_rshift(e_hi, 18) + bit32_lshift(e_lo, 14), bit32_lshift(e_hi, 23) + bit32_rshift(e_lo, 9)) +
				bit32_band(e_hi, f_hi) + bit32_band(-1 - e_hi, g_hi) +
				h_hi + K_hi[j] + W[jj - 1] +
				(tmp1 - z_lo) / 4294967296
			h_lo = g_lo
			h_hi = g_hi
			g_lo = f_lo
			g_hi = f_hi
			f_lo = e_lo
			f_hi = e_hi
			tmp1 = z_lo + d_lo
			e_lo = tmp1 % 4294967296
			e_hi = z_hi + d_hi + (tmp1 - e_lo) / 4294967296
			d_lo = c_lo
			d_hi = c_hi
			c_lo = b_lo
			c_hi = b_hi
			b_lo = a_lo
			b_hi = a_hi
			tmp1 = z_lo + (bit32_band(d_lo, c_lo) + bit32_band(b_lo, bit32_bxor(d_lo, c_lo))) % 4294967296 + bit32_bxor(bit32_rshift(b_lo, 28) + bit32_lshift(b_hi, 4), bit32_lshift(b_lo, 30) + bit32_rshift(b_hi, 2), bit32_lshift(b_lo, 25) + bit32_rshift(b_hi, 7)) % 4294967296
			a_lo = tmp1 % 4294967296
			a_hi = z_hi + (bit32_band(d_hi, c_hi) + bit32_band(b_hi, bit32_bxor(d_hi, c_hi))) + bit32_bxor(bit32_rshift(b_hi, 28) + bit32_lshift(b_lo, 4), bit32_lshift(b_hi, 30) + bit32_rshift(b_lo, 2), bit32_lshift(b_hi, 25) + bit32_rshift(b_lo, 7)) + (tmp1 - a_lo) / 4294967296
		end
		a_lo = h1_lo + a_lo
		h1_lo = a_lo % 4294967296
		h1_hi = (h1_hi + a_hi + (a_lo - h1_lo) / 4294967296) % 4294967296
		a_lo = h2_lo + b_lo
		h2_lo = a_lo % 4294967296
		h2_hi = (h2_hi + b_hi + (a_lo - h2_lo) / 4294967296) % 4294967296
		a_lo = h3_lo + c_lo
		h3_lo = a_lo % 4294967296
		h3_hi = (h3_hi + c_hi + (a_lo - h3_lo) / 4294967296) % 4294967296
		a_lo = h4_lo + d_lo
		h4_lo = a_lo % 4294967296
		h4_hi = (h4_hi + d_hi + (a_lo - h4_lo) / 4294967296) % 4294967296
		a_lo = h5_lo + e_lo
		h5_lo = a_lo % 4294967296
		h5_hi = (h5_hi + e_hi + (a_lo - h5_lo) / 4294967296) % 4294967296
		a_lo = h6_lo + f_lo
		h6_lo = a_lo % 4294967296
		h6_hi = (h6_hi + f_hi + (a_lo - h6_lo) / 4294967296) % 4294967296
		a_lo = h7_lo + g_lo
		h7_lo = a_lo % 4294967296
		h7_hi = (h7_hi + g_hi + (a_lo - h7_lo) / 4294967296) % 4294967296
		a_lo = h8_lo + h_lo
		h8_lo = a_lo % 4294967296
		h8_hi = (h8_hi + h_hi + (a_lo - h8_lo) / 4294967296) % 4294967296
	end
	H_lo[1], H_lo[2], H_lo[3], H_lo[4], H_lo[5], H_lo[6], H_lo[7], H_lo[8] = h1_lo, h2_lo, h3_lo, h4_lo, h5_lo, h6_lo, h7_lo, h8_lo
	H_hi[1], H_hi[2], H_hi[3], H_hi[4], H_hi[5], H_hi[6], H_hi[7], H_hi[8] = h1_hi, h2_hi, h3_hi, h4_hi, h5_hi, h6_hi, h7_hi, h8_hi
end
local function inlineSha512(message)
	local length, tail = 0, ''
	local H_lo, H_hi = {}, {}
	for j = 1, 8 do H_lo[j] = sha2_H_lo[j]; H_hi[j] = sha2_H_hi[j] end
	local partLength = #message
	length = length + partLength
	local size = partLength
	local size_tail = size % 128
	sha512_feed_128(H_lo, H_hi, message, 0, size - size_tail)
	tail = tail .. string.sub(message, partLength + 1 - size_tail)
	local final_blocks = {tail, '\128', string.rep('\0', (-17 - length) % 128 + 9)}
	tail = nil
	length = length * (8 / TWO56_POW_7)
	for j = 4, 10 do
		length = length % 1 * 256
		final_blocks[j] = string.char(math.floor(length))
	end
	final_blocks = table.concat(final_blocks)
	sha512_feed_128(H_lo, H_hi, final_blocks, 0, #final_blocks)
	local out = {}
	for j = 1, 8 do
		out[j] = string.format('%08x', H_hi[j] % 4294967296) .. string.format('%08x', H_lo[j] % 4294967296)
	end
	return table.concat(out)
end

local function fileDigest(path)
	local content = readfile(path)
	local i = content:find('\n')
	if i then
		content = content:sub(i + 1)
	end
	local partial = hash.sha512()
	for j = 1, #content, 32768 do
		partial(content:sub(j, j + 32767))
		if j % 262144 == 0 then
			task.wait()
		end
	end
	return partial()
end

local function verifyFiles()
	if getgenv().LarpVerifiedCommit == COMMIT then
		return
	end
	fetchManifest()
	local ok, good = pcall(function()
		local content = readfile('LarpV4/libraries/hash.lua')
		local i = content:find('\n')
		if i then
			content = content:sub(i + 1)
		end
		return inlineSha512(content) == MANIFEST['libraries/hash.lua']
	end)
	if not ok or not good then
		pcall(delfile, 'LarpV4/libraries/hash.lua')
	end
	hash = loadstring(downloadFile('LarpV4/libraries/hash.lua'), 'hash')()
	local todo = {}
	for _, path in VERIFY_FILES do
		local full = 'LarpV4/'..path
		if isfile(full) then
			local content = readfile(full)
			if content:sub(1, #LARPWATER) ~= LARPWATER then
				todo[#todo + 1] = path
			end
		else
			todo[#todo + 1] = path
		end
	end
	if #todo > 0 then
		downloader.Text = 'Downloading '..#todo..' files...'
		local remaining = #todo
		for _, path in todo do
			task.spawn(function()
				pcall(downloadFile, 'LarpV4/'..path)
				remaining = remaining - 1
			end)
		end
		while remaining > 0 do
			task.wait()
		end
	end
	--[[ Only hash files that were actually (re)downloaded this load. A file whose
		watermark matches the current commit is already the right version, so hashing
		every file on every inject just burns CPU on ~1.5MB of SHA-512. ]]
	local fresh = {}
	for _, path in todo do
		local full = 'LarpV4/'..path
		local expected = MANIFEST[path]
		if expected and pcall(function()
			return fileDigest(full) == expected
		end) then
			fresh[path] = true
		end
	end
	for _, path in VERIFY_FILES do
		if fresh[path] then continue end
		local full = 'LarpV4/'..path
		local expected = MANIFEST[path]
		if expected and isfile(full) and readfile(full):sub(1, #LARPWATER) == LARPWATER then
			continue
		end
		if expected and (not isfile(full) or not pcall(function()
			return fileDigest(full) == expected
		end)) then
			pcall(delfile, full)
			downloadFile(full, function(c) return c end)
			if fileDigest(full) ~= expected then
				error('LarpV4: integrity check failed for '..path)
			end
		end
	end
	getgenv().LarpVerifiedCommit = COMMIT
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
		for _, file in {'LarpV4/6872274481.lua', 'LarpV4/8444591321.lua', 'LarpV4/100702124803290.lua', 'LarpV4/universal.lua', 'LarpV4/entity.lua', 'LarpV4/prediction.lua', 'LarpV4/hash.lua', 'LarpV4/larp2.lua', 'LarpV4/larp.lua'} do
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
downloader.Visible = false
if not _larpok then
	error('LarpV4/main.lua: '..tostring(_larpres))
end
return _larpres
