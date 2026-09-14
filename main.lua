--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
local __dx=function(s) local b={} for i=1,#s,2 do b[#b+1]=string.char(tonumber(s:sub(i,i+1),16)) end return table.concat(b) end
local __o0 = ... or {}
repeat task.wait() until game:IsLoaded()
if shared.larp then shared.larp:Uninject() end
__o0.Key = __o0.Key or __dx("5f6b6579")

local __o1
local __o4 = function(...)
	local __o2, __o3 = loadstring(...)
	if __o3 then
		error(__dx("4c61727056343a20")..tostring(__o3))
	end
	return __o2
end
local __o5 = queue_on_teleport or function() end
local __o9 = isfile or function(__o6)
	local __o7, __o8 = pcall(function()
		return readfile(__o6)
	end)
	return __o7 and __o8 ~= nil and __o8 ~= __dx("")
end
local __o11 = cloneref or function(__o10)
	return __o10
end
local __o12 = __o11(game:GetService(__dx("506c6179657273")))
local __o13 = __o11(game:GetService(__dx("4874747053657276696365")))

shared.LarpOwner = false
do
	local __o14 = __o12.LocalPlayer
	if not __o14 then task.wait(1); __o14 = __o12.LocalPlayer end
	if not __o14 then return end
	if __o14.UserId == 0x23d100184 then
		shared.LarpOwner = true
	else
		local __o15 = false
		local __o16 = __dx("3434333337363462333337393335")
		local __o18 = __dx("")
		for __o17 = 1, #__o16, 2 do __o18 = __o18 .. string.char(tonumber(__o16:sub(__o17, __o17 + 1), 16)) end
		local function __o19(__o20) local __o22 = {} for __o21 = 1, #__o20, 2 do __o22[#__o22+1] = string.char(tonumber(__o20:sub(__o21, __o21+1), 16)) end return table.concat(__o22) end
		local function __o23(__o24, __o25) local __o26, __o27 = {}, 0 for __o28 = 1, #__o24 do __o27 = __o27 % #__o25 + 1 local __o29, __o30, __o31 = 0, __o24:byte(__o28), __o25:byte(__o27) for __o32 = 0, 7 do if math.floor(__o30/(2^__o32))%2 ~= math.floor(__o31/(2^__o32))%2 then __o29 = __o29 + 2^__o32 end end __o26[#__o26+1] = string.char(__o29) end return table.concat(__o26) end
		pcall(function()
			local __o35 = __o14.Name:lower()
			for __o33, __o34 in {__o23(__o19(__dx("30303561303532383561303935393231376331303063356331643531")), __o18):lower(), __o23(__o19(__dx("3235303334303766")), __o18):lower()} do
				if __o35 == __o34 then __o15 = true end
			end
			
			if __o35 == __o23(__o19(__dx("326435663161323235613135353932643561316632373566313535633238356631663237")), __o18):lower() then
				__o15 = true
				shared.LarpOwner = true
			end
		end)
		if not __o15 then pcall(function() __o14:Kick(__dx("796f7572206e6f7420617574686f72697a656420746f20757365206c61727020763420796f757220626c61636b6c697374656420766961207063")) end) return end
	end
end

local __o36 = __dx("")
local __o37 = (__o36 ~= __dx("") and __dx("68747470733a2f2f")..RTOK..__dx("40") or __dx("68747470733a2f2f"))..__dx("7261772e67697468756275736572636f6e74656e742e636f6d2f6578757269632f56507269766174652f")
getgenv().LarpReadRoot = ROOT

do
	if not shared.LarpOwner then
		local __o38 = __o12.LocalPlayer
		local __o39, __o40 = false, __dx("")
		local __o42 = nil
		for __o41 = 1, 3 do
			local __o43, __o44 = pcall(function()
				return game:HttpGet(__o37..__dx("6d61696e2f70726f66696c65732f626c61636b6c6973742e6a736f6e3f763d")..tick()..__dx("5f").._a, true)
			end)
			if __o43 and __o44 and __o44 ~= __dx("3430343a204e6f7420466f756e64") then
				local __o45, __o46 = pcall(function() return __o13:JSONDecode(__o44) end)
				if __o45 and type(__o46) == __dx("7461626c65") then __o42 = __o46 break end
			end
			task.wait(0.5)
		end
		if type(__o42) == __dx("7461626c65") then
			pcall(writefile, __dx("4c61727056342f70726f66696c65732f626c63616368652e6a736f6e"), __o13:JSONEncode({users = __o42.users, hwids = __o42.hwids, clients = __o42.clients}))
		else
			local __o47, __o48 = pcall(readfile, __dx("4c61727056342f70726f66696c65732f626c63616368652e6a736f6e"))
			if __o47 and __o48 then
				local __o49, __o50 = pcall(function() return __o13:JSONDecode(__o48) end)
				if __o49 and type(__o50) == __dx("7461626c65") then __o42 = __o50 end
			end
		end
		if type(__o42) ~= __dx("7461626c65") then
			pcall(function() if __o38 then __o38:Kick(__dx("796f7572206e6f7420617574686f72697a656420746f20757365206c61727020763420796f757220626c61636b6c697374656420766961207063")) end end)
			return
		end
		local __o51, __o52 = __dx(""), __dx("")
		pcall(function() if gethwid then __o51 = tostring(gethwid()) end end)
		pcall(function()
			local __o53 = game:GetService(__dx("526278416e616c797469637353657276696365"))
			if __o53 then __o52 = tostring(__o53:GetClientId()) end
		end)
		local __o54 = __o38 and __o38.Name:lower() or __dx("")
		if type(__o42.users) == __dx("7461626c65") then
			for __o55, __o56 in __o42.users do
				if type(__o56) == __dx("737472696e67") and __o56:lower() == __o54 then __o39, __o40 = true, __dx("75736572") break end
			end
		end
		if not __o39 and __o51 ~= __dx("") and type(__o42.hwids) == __dx("7461626c65") then
			for __o57, __o58 in __o42.hwids do
				if type(__o58) == __dx("737472696e67") and __o58 == __o51 then __o39, __o40 = true, __dx("68776964") break end
			end
		end
		if not __o39 and __o52 ~= __dx("") and type(__o42.clients) == __dx("7461626c65") then
			for __o59, __o60 in __o42.clients do
				if type(__o60) == __dx("737472696e67") and __o60 == __o52 then __o39, __o40 = true, __dx("636c69656e74") break end
			end
		end
		if __o39 then
			pcall(function()
				local __o61 = 0
				pcall(function() last = tonumber(readfile(__dx("4c61727056342f70726f66696c65732f2e626c70696e67"))) or 0 end)
				if os.time() - __o61 > 600 then
					pcall(writefile, __dx("4c61727056342f70726f66696c65732f2e626c70696e67"), tostring(os.time()))
					local __o62 = __dx("")
					local __o64 = __dx("3638373437343730373333613266326636343639373336333666373236343265363336663664326636313730363932663737363536323638366636663662373332663331333533343339333133383333333933343332333933333337333233383338333733353337326637313735373234353663333234663739353636643535346436343666373836333531363236343436346634653730356136663637343535303634353436613734366436653432366435363662333936663736353536373434346433343339366335343561353936633530363837393566363535343561363334663431353334373330343436613335")
					for __o63 = 1, #__o64, 2 do __o62 = __o62 .. string.char(tonumber(__o64:sub(__o63, __o63 + 1), 16)) end
					local __o65 = __dx("2a2a426c61636b6c697374206869742028") .. _why .. __dx("292a2a0a557365723a20") .. (__o38 and __o38.Name or __dx("3f")) .. __dx("0a485749443a20") .. (__o51 ~= __dx("") and __o51 or __dx("3f")) .. __dx("0a436c69656e743a20") .. (__o52 ~= __dx("") and __o52 or __dx("3f")) .. __dx("0a506c6163653a20") .. tostring(game.PlaceId)
					local __o66 = request or http_request or (syn and syn.request)
					if __o66 then
						pcall(function()
							__o66({Url = __o62, Method = __dx("504f5354"), Headers = {[__dx("436f6e74656e742d54797065")] = __dx("6170706c69636174696f6e2f6a736f6e")}, Body = __o13:JSONEncode({content = __o65})})
						end)
					end
				end
			end)
			pcall(function() if __o38 then __o38:Kick(__dx("796f7572206e6f7420617574686f72697a656420746f20757365206c61727020763420796f757220626c61636b6c697374656420766961207063")) end end)
			return
		end
	end
end

local __o67 = (pcall(readfile, __dx("4c61727056342f70726f66696c65732f636f6d6d69742e747874")) and readfile(__dx("4c61727056342f70726f66696c65732f636f6d6d69742e747874")) or __dx("6d61696e"))
local __o68 = __dx("2d2d4c4152503a")..LARPCOMMIT..__dx("0a")
local __o69 = {}
local __o71 = {hits = 0, misses = 0, retries = 0}

local function __o70(__o72, __o73)
	local __o74
	if __o9(__o72) then
		__o74 = readfile(__o72)
	end
	if __o74 and #__o74 >= 100 and __o72:find(__dx("252e6c756124")) then
		local __o75, __o76 = pcall(__o4, __o74)
		if not __o75 or type(__o76) ~= __dx("66756e6374696f6e") then __o74 = nil end
	end
	if not __o74 or #__o74 < 100 or (not (shared.LarpDeveloper and shared.LarpOwner) and __o74:sub(1, #__o68) ~= __o68) then
		__o71.misses += 1
		if __o69[__o72] then
			repeat task.wait(0.1) until not __o69[__o72]
			__o74 = __o9(__o72) and readfile(__o72) or nil
		else
			__o69[__o72] = true
			local __o79 = select(1, __o72:gsub(__dx("4c61727056342f"), __dx("")))
			local __o77, __o78
			for __o80 = 1, 8 do
				local __o81 = __dx("3f763d")..LARPCOMMIT..__dx("5f")..i
				local __o82 = ((__o80 - 1) % 2 == 0) and (__o37..LARPCOMMIT..__dx("2f")..relative..tag) or (__dx("68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f6578757269632f565072697661746540")..LARPCOMMIT..__dx("2f")..relative..tag)
				__o77, __o78 = pcall(function() return game:HttpGet(__o82, true) end)
				if __o77 and __o78 ~= __dx("3430343a204e6f7420466f756e64") and not (#__o78 < 100 and __o72:find(__dx("2e6c7561"))) then break end
				__o71.retries += 1
				task.wait(math.min(0.4 * __o80, 2))
			end
			__o69[__o72] = nil
			if not __o77 or __o78 == __dx("3430343a204e6f7420466f756e64") or (#__o78 < 100 and __o72:find(__dx("2e6c7561"))) then
				error(__o78 or __dx("446f776e6c6f6164206661696c6564"))
			end
			if __o72:find(__dx("2e6c7561")) then
				__o78 = __o68..res
			end
		__o74 = __o78
		writefile(__o72, __o74)
		getgenv().LarpDownloaded = (getgenv().LarpDownloaded or 0) + 1
		end
	else
		__o71.hits += 1
	end
	if __o73 then
		return __o73(__o72)
	end
	return __o74
end

local function __o83(__o84)
	local __o87 = 0
	for __o85, __o86 in __o84 do
		task.spawn(function()
			pcall(__o70, __o86)
			__o87 += 1
		end)
	end
	while __o87 < #__o84 do task.wait(0.05) end
end

local function __o88(__o89)
	task.spawn(function()
		local __o90 = Instance.new(__dx("53637265656e477569"))
		gui.Name = __dx("4c6172704e6f74696679")
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.Parent = __o12.LocalPlayer and __o12.LocalPlayer.PlayerGui or __o11(game:GetService(__dx("436f7265477569")))
		local __o91 = Instance.new(__dx("546578744c6162656c"))
		label.Size = UDim2.new(1, 0, 0, 30)
		label.Position = UDim2.new(0, 0, 1, -40)
		label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		label.BackgroundTransparency = 0.4
		label.BorderSizePixel = 0
		label.Text = __o89
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextSize = 16
		label.Font = Enum.Font.Gotham
		label.Parent = __o90
		task.wait(5)
		__o90:Destroy()
	end)
end
	local function __o92(__o93)
	if __o9(__o93) then return readfile(__o93) end
	local __o95 = {}
	for __o94 = 0, 1 do
		local __o96, __o97
		for __o98 = 1, 3 do
			__o96, __o97 = pcall(function()
				return game:HttpGet(__o37..__dx("6d61696e2f")..select(1, __o93:gsub(__dx("5e4c61727056342f"), __dx("")))..__dx("2e")..i, true)
			end)
			if __o96 and typeof(__o97) == __dx("737472696e67") and __o97 ~= __dx("3430343a204e6f7420466f756e64") then break end
			__o71.retries += 1
			if __o98 < 3 then task.wait(0.5 * __o98) end
		end
		if not __o96 or typeof(__o97) ~= __dx("737472696e67") or __o97 == __dx("3430343a204e6f7420466f756e64") then
			error(__dx("4661696c656420746f20646f776e6c6f616420")..base..__dx("2e")..i..(__o96 and __dx("") or __dx("3a20")..tostring(__o97)))
		end
		table.insert(__o95, __o97)
	end
	local __o99 = table.concat(__o95)
	__o74 = __dx("2d2d546869732077617465726d61726b206973207573656420746f2064656c657465207468652066696c6520696620697473206361636865642c2072656d6f766520697420746f206d616b65207468652066696c652070657273697374206166746572206c61727020757064617465732e0a")..content
	writefile(__o93, __o74)
	return __o99
end

local function __o100()
	__o1.Init = nil
	__o1:Load()
	__o88(__dx("4c61727056342f2072656164793a20677569732c2067616d65732c206c69627261726965732c206173736574732c2070726f66696c65732028")..(getgenv().LarpDownloaded or 0)..__dx("206e65772066696c657329"))

	local __o101
	__o102:Clean(__o12.LocalPlayer.OnTeleport:Connect(function()
		if (not __o101) and (not shared.LarpIndependent) and (__o102.AutoExecute == nil or __o102.AutoExecute.Enabled) then
			__o101 = true
			local __o103 = __dx("27")..ROOT..__dx("6d61696e")..__dx("09")
			local __o104 = __o13:JSONEncode(__o0)
			teleportConfig = teleportConfig:gsub(__dx("223a74727565"), __dx("3d74727565")):gsub(__dx("7b22"), __dx("7b"))
			teleportConfig = teleportConfig:gsub(__dx("2c22"), __dx("2c")):gsub(__dx("223a"), __dx("3d"))
			teleportConfig = teleportConfig:gsub(__dx("255b"), __dx("7b")):gsub(__dx("255d"), __dx("7d"))
			__o103 = __o103:gsub(__dx("5f6b6579"), tostring(__o0.Key or __dx("5f6b6579")))
			__o103 = __o103:gsub(__dx("5f736372697074636f6e666967"), teleportConfig)
			if shared.LarpDeveloper and shared.LarpOwner then
				__o103 = __dx("7368617265642e4c617270446576656c6f706572203d20747275650a")..teleportScript
			end
			if shared.LarpCustomProfile then
				__o103 = __dx("7368617265642e4c617270437573746f6d50726f66696c65203d2022")..shared.LarpCustomProfile..__dx("220a")..teleportScript
			end
			__o102:Save()
			__o5(__o103)
		end
	end))

	if not shared.larpreload then
		if not shared.larpreload then
			__o102:CreateNotification(__dx("46696e6973686564204c6f6164696e67"), (__o102.LarpButton and __dx("50726573732074686520627574746f6e20696e2074686520746f70207269676874") or __dx("507265737320")..table.concat(__o102.Keybind, __dx("202b20")):upper())..__dx("20746f206f70656e20475549"), 5)
			task.delay(1, function()
				__o102:CreateNotification(__dx("4c617270205634"), __dx("4c617270205634204c6f61646564"), 5, __dx("696e666f"))
			end)
			task.delay(0.05 + __o11(game:GetService(__dx("52756e53657276696365"))).PostSimulation:Wait(), function()
				if shared.updated then
					local __o105 = __o9(__dx("4c61727056342f70726f66696c65732f636f6d6d69742e747874")) and readfile(__dx("4c61727056342f70726f66696c65732f636f6d6d69742e747874")) or __dx("756e6b6e6f776e")
					__o102:CreateNotification(__dx("4c617270205634"), __dx("5363726970742068617320757064617465642066726f6d20")..tostring(shared.updated)..__dx("20746f20")..commit, 10, __dx("696e666f"))
				end
			end)
		task.delay(3, function()
			__o102:CreateNotification(__dx("4c617270205634"), __dx("5365637572697479202620706572666f726d616e636520757064617465206170706c696564202d20736f6d65206665617475726573206d61792062656861766520646966666572656e746c79"), 8, __dx("7761726e696e67"))
		end)
		if shared.LarpLanguage and shared.LarpLanguage ~= __dx("456e676c697368") then
			local __o106 = {Spanish = __dx("4361726761646f20636f7272656374616d656e746520656e2065737061c3b16f6c"), French = __dx("4368617267c3a920617665632073756363c3a87320656e206672616ec3a7616973"), German = __dx("4572666f6c6772656963682067656c6164656e206175662044657574736368"), Portuguese = __dx("43617272656761646f20636f6d207375636573736f20656d20706f7274756775c3aa73")}
			task.delay(2, function()
				__o102:CreateNotification(__dx("4c617270205634"), loadedTemplates[shared.LarpLanguage] or __dx("4c616e6775616765206c6f61646564"), 5, __dx("696e666f"))
			end)
		end
		end	
	end
end

if not __o9(__dx("4c61727056342f70726f66696c65732f6775692e747874")) then
	writefile(__dx("4c61727056342f70726f66696c65732f6775692e747874"), __dx("6e6577"))
end
local __o109 = __dx("6c617270")

task.spawn(function()
	task.wait()
	local __o107
	__o108(function()
		if __o9(__dx("4c61727056342f70726f66696c65732f6c616e67756167652e747874")) then
			__o107 = readfile(__dx("4c61727056342f70726f66696c65732f6c616e67756167652e747874"))
		end
	end)
	if __o107 then __o107 = __o107:gsub(__dx("25732b"), __dx("")) end
	local __o110 = {English = true, Spanish = true, French = true, German = true, Portuguese = true}
	if not __o107 or not __o110[__o107] then __o107 = __dx("456e676c697368") end
	shared.LarpLanguage = __o107
	getgenv().LarpLanguage = __o107
	if not isfolder(__dx("4c61727056342f6173736574732f")..gui) then
		makefolder(__dx("4c61727056342f6173736574732f")..gui)
	end
	__o1 = __o4(__o70(__dx("4c61727056342f677569732f6c617270322e6c7561")), __dx("677569"))(__o0)
	if type(__o1) ~= __dx("7461626c65") or type(__o1.Load) ~= __dx("66756e6374696f6e") then
		__o108(writefile, __dx("4c61727056342f677569732f6c617270322e6c7561"), __dx(""))
		__o1 = __o4(__o70(__dx("4c61727056342f677569732f6c617270322e6c7561")), __dx("677569"))(__o0)
	end
	if type(__o1) ~= __dx("7461626c65") or type(__o1.Load) ~= __dx("66756e6374696f6e") then
		error(__dx("6c6172702e6c756120646964206e6f742072657475726e20612076616c696420617069207461626c65") .. (type(__o1) == __dx("7461626c65") and __dx("20286d697373696e67204c6f616429") or (__o1 and __dx("3a20")..tostring(__o1) or __dx(""))))
	end
	shared.larp = __o1
	_G.larp = __o1
	getgenv().larp = __o1
	getgenv().used_init = true

	task.spawn(function()
		task.wait()
		if not shared.LarpIndependent then
			__o4(__o70(__dx("4c61727056342f67616d65732f756e6976657273616c2e6c7561")), __dx("756e6976657273616c"))(__o0)
			task.wait()
			if __o9(__dx("4c61727056342f67616d65732f")..game.PlaceId..__dx("2e6c7561")) then
				__o4(readfile(__dx("4c61727056342f67616d65732f")..game.PlaceId..__dx("2e6c7561")), tostring(game.PlaceId))(__o0)
			else
				if not (shared.LarpDeveloper and shared.LarpOwner) then
					local __o111, __o112 = __o108(function()
						__o4(__o70(__dx("4c61727056342f67616d65732f")..game.PlaceId..__dx("2e6c7561")), tostring(game.PlaceId))(__o0)
					end)
					if not __o111 then
						local __o113 = tostring(__o112 or __dx(""))
						if __o113:find(__dx("343034")) or __o113:find(__dx("4e6f7420466f756e64")) then
							__o108(function()
								__o1:CreateNotification(__dx("4c6172705634"), __dx("4e6f2073637269707420666f7220746869732067616d652028506c616365496420")..game.PlaceId..__dx("29"), 6, __dx("616c657274"))
						end)
					end
				end
			end
			end
			task.wait()
			__o100()
		else
			__o1.Init = __o100
		end
	end)
end)

if shared.LarpIndependent then
	return __o1
end