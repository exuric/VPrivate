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
local function downloadFile(path, func)
	if not isfile(path) or readfile(path):sub(1, #LARPWATER) ~= LARPWATER then
		local suc, res = pcall(function()
			return game:HttpGet((getgenv().LarpReadRoot or 'https://raw.githubusercontent.com/exuric/VPrivate/')..readfile('LarpV4/profiles/commit.txt')..'/'..select(1, path:gsub('LarpV4/', ''))..'?v=117', true)
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
if isfile('LarpV4/games/'..larp.Place..'.lua') then
	loadstring(readfile('LarpV4/games/'..larp.Place..'.lua'), 'bedwars')()
else
	if not shared.LarpDeveloper then
		local suc, res = pcall(function()
			return game:HttpGet((getgenv().LarpReadRoot or 'https://raw.githubusercontent.com/exuric/VPrivate/')..readfile('LarpV4/profiles/commit.txt')..'/games/'..larp.Place..'.lua?v=117', true)
		end)
		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile('LarpV4/games/'..larp.Place..'.lua'), 'bedwars')()
		end
	end
end
