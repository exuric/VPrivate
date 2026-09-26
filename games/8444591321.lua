--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
local larp = shared.larp
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and larp then
		larp:CreateNotification('Larp', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local LARPWATER = '--LARP:'..(pcall(readfile, 'LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'main')..'\n'
local LARPCOMMIT = (pcall(readfile, 'LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'main'):gsub('%s+', '')
local function downloadFile(path, func)
	if not isfile(path) or (path:find('.lua') and #readfile(path) < 100) or readfile(path):sub(1, #LARPWATER) ~= LARPWATER then
		local suc, res = pcall(function()
			return game:HttpGet((getgenv().LarpReadRoot or 'https://raw.githubusercontent.com/exuric/VPrivate/')..LARPCOMMIT..'/'..select(1, path:gsub('LarpV4/', ''))..'?v='..LARPCOMMIT, true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = LARPWATER..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

larp.Place = 6872274481
do
	local gamePath = 'LarpV4/games/'..larp.Place..'.lua'
	if isfile(gamePath) then
		local okRead, cached = pcall(readfile, gamePath)
		if not okRead or not cached or #cached < 100 or cached:sub(1, #LARPWATER) ~= LARPWATER then
			pcall(delfile, gamePath)
		end
	end
	local ok = false
	if isfile(gamePath) then
		ok = pcall(function()
			loadstring(readfile(gamePath), 'bedwars')()
		end)
		if not ok then
			pcall(delfile, gamePath)
		end
	end
	if not ok and not shared.LarpDeveloper then
		local suc, res = pcall(function()
			return game:HttpGet((getgenv().LarpReadRoot or 'https://raw.githubusercontent.com/exuric/VPrivate/')..LARPCOMMIT..'/games/'..larp.Place..'.lua?v='..LARPCOMMIT, true)
		end)
		if suc and res ~= '404: Not Found' then
			pcall(writefile, gamePath, LARPWATER..res)
			pcall(function()
				loadstring(LARPWATER..res, 'bedwars')()
			end)
		end
	end
end
