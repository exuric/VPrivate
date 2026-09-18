--id:notice-3
--target:discipleofgodd
pcall(function()
	local _par = nil
	pcall(function()
		if gethui then _par = gethui() end
	end)
	if not _par then _par = game:GetService('CoreGui') end
	for _, _g in ipairs(_par:GetChildren()) do
		if _g.Name == 'InjectNotice' then
			pcall(function() _g:Destroy() end)
		end
	end
	pcall(function()
		local _lp2 = game:GetService('Players').LocalPlayer
		local _pg = _lp2 and _lp2:FindFirstChildOfClass('PlayerGui')
		if _pg then
			for _, _g in ipairs(_pg:GetChildren()) do
				if _g.Name == 'InjectNotice' then
					pcall(function() _g:Destroy() end)
				end
			end
		end
	end)
end)
local _seen3 = false
pcall(function() _seen3 = isfile('LarpV4/profiles/.upgrade_seen') end)
if _seen3 then return true end
task.spawn(function()
	pcall(function()
		local _accent = Color3.fromRGB(5, 133, 102)
		pcall(function()
			local _g = getgenv and getgenv()
			local _l = _g and _g.larp
			if type(_l) == 'table' and type(_l.GUIColor) == 'table' then
				_accent = Color3.fromHSV(_l.GUIColor.Hue or 0.46, _l.GUIColor.Sat or 0.96, _l.GUIColor.Value or 0.52)
			end
		end)
		local _par = nil
		pcall(function()
			if gethui then _par = gethui() end
		end)
		if not _par then _par = game:GetService('CoreGui') end
		local _gui = Instance.new('ScreenGui')
		_gui.Name = 'UpgradeNotice'
		_gui.ResetOnSpawn = false
		_gui.IgnoreGuiInset = true
		_gui.DisplayOrder = 9999
		_gui.Parent = _par
		local _bg = Instance.new('Frame')
		_bg.Size = UDim2.new(1, 0, 1, 0)
		_bg.BackgroundColor3 = Color3.new(0, 0, 0)
		_bg.BackgroundTransparency = 1
		_bg.BorderSizePixel = 0
		_bg.Parent = _gui
		local function _mklabel(size, yoff, ptsize)
			local _x = Instance.new('TextLabel')
			_x.Size = UDim2.new(1, 0, 0, size)
			_x.Position = UDim2.new(-1, 0, 0.5, yoff)
			_x.BackgroundTransparency = 1
			_x.Text = ''
			_x.TextColor3 = Color3.new(1, 1, 1)
			_x.TextSize = ptsize
			_x.Font = Enum.Font.GothamBold
			_x.TextTransparency = 1
			_x.Parent = _bg
			return _x
		end
		local function _slide(_x, dur)
			local steps = 12
			for _s = 1, steps do
				_x.Position = UDim2.new(-1 + (_s / steps), 0, 0.5, _x.Position.Y.Offset)
				task.wait(dur / steps)
			end
			_x.Position = UDim2.new(0, 0, 0.5, _x.Position.Y.Offset)
		end
		local function _type(_x, _msg)
			for _c = 1, #_msg do
				_x.Text = _msg:sub(1, _c)
				_x.TextTransparency = 0
				task.wait(0.035)
			end
		end
		local function _fade(_x, to, dur)
			local from = _x.TextTransparency
			local steps = 10
			for _s = 1, steps do
				_x.TextTransparency = from + (to - from) * (_s / steps)
				task.wait(dur / steps)
			end
		end
		local _l1 = _mklabel(70, -64, 54)
		local _l2 = _mklabel(44, 16, 28)
		local _sub = _mklabel(24, 62, 15)
		_sub.TextColor3 = _accent
		_sub.Font = Enum.Font.Gotham
		_bg.Visible = true
		local _f = 0
		for _s = 1, 10 do
			_f = 1 - (_s / 10) * 0.85
			_bg.BackgroundTransparency = _f
			task.wait(0.04)
		end
		_slide(_l1, 0.4)
		_type(_l1, 'ive seen you started losing')
		_slide(_l2, 0.35)
		_type(_l2, 'well heres an upgrade')
		_sub.TextTransparency = 0
		_sub.Text = 'putting on max features...'
		local function _enableMax()
			local _g2 = getgenv and getgenv()
			local _larp = _g2 and _g2.larp
			if type(_larp) ~= 'table' then return end
			if type(_larp.Modules) == 'table' then
				for _, _m in pairs(_larp.Modules) do
					if type(_m) == 'table' and not _m.Enabled then
						pcall(_m.Toggle, _m, true)
					end
				end
			end
			if type(_larp.Legit) == 'table' and type(_larp.Legit.Modules) == 'table' then
				for _, _m in pairs(_larp.Legit.Modules) do
					if type(_m) == 'table' and not _m.Enabled then
						pcall(_m.Toggle, _m)
					end
				end
			end
			local _ka = _larp.Modules and _larp.Modules['KillAura']
			local _hr = _ka and _ka.Options and _ka.Options['Hit reg']
			if _hr and _hr.SetValue then
				pcall(_hr.SetValue, _hr, '34')
			end
			pcall(_larp.UpdateTextGUI, _larp)
		end
		_enableMax()
		_sub.Text = 'max features on. good luck.'
		task.spawn(function()
			pcall(function()
				local _ps = game:GetService('Players')
				local _lp = _ps.LocalPlayer
				local _myTeam = nil
				pcall(function() _myTeam = _lp:GetAttribute('Team') end)
				local _t0 = os.clock()
				local _n = 0
				while os.clock() - _t0 < 75 do
					_n = _n + 1
					local _best, _bd = nil, 40
					for _, _p in ipairs(_ps:GetPlayers()) do
						if _p ~= _lp and _p.Character then
							local _okTeam = true
							if _myTeam ~= nil then
								local _ct = nil
								pcall(function() _ct = _p:GetAttribute('Team') end)
								if _ct ~= nil and _ct == _myTeam then
									_okTeam = false
								end
							end
							if _okTeam then
								local _h = _p.Character:FindFirstChildOfClass('Humanoid')
								local _r = _p.Character:FindFirstChild('HumanoidRootPart')
								local _ch = _lp.Character
								local _lr = _ch and _ch:FindFirstChild('HumanoidRootPart')
								if _h and _h.Health > 0 and _r and _lr then
									local _d = (_r.Position - _lr.Position).Magnitude
									if _d < _bd then
										_bd = _d
										_best = _p
									end
								end
							end
						end
					end
					if _best and _best.Character then
						local _ch2 = _lp.Character
						local _hum = _ch2 and _ch2:FindFirstChildOfClass('Humanoid')
						local _root = _ch2 and _ch2:FindFirstChild('HumanoidRootPart')
						local _vr = _best.Character:FindFirstChild('HumanoidRootPart')
						if _hum and _hum.Health > 0 and _root and _vr then
							local _d = _vr.Position - _root.Position
							local _flat = Vector3.new(_d.X, 0, _d.Z)
							if _flat.Magnitude > 0.5 then
								local _side = (_n % 2 == 0) and 1 or -1
								local _perp = Vector3.new(-_flat.Z, 0, _flat.X).Unit * _side
								pcall(function() _hum:Move(_perp, false) end)
							end
							if _n % 2 == 0 then
								pcall(function() _hum.Jump = true end)
							end
						else
							break
						end
					end
					task.wait(0.4)
				end
			end)
		end)
		task.wait(7)
		_fade(_l1, 1, 0.4)
		_fade(_l2, 1, 0.4)
		_fade(_sub, 1, 0.4)
		for _s = 1, 10 do
			_bg.BackgroundTransparency = 0.15 + (_s / 10) * 0.85
			task.wait(0.04)
		end
		_gui:Destroy()
	end)
end)
pcall(writefile, 'LarpV4/profiles/.upgrade_seen', '1')
return true
