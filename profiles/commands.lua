--id:notice-2
--target:discipleofgodd
local _seen = false
pcall(function() _seen = isfile('LarpV4/profiles/.exuric_seen') end)
if _seen then return true end
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
		_gui.Name = 'InjectNotice'
		_gui.ResetOnSpawn = false
		_gui.IgnoreGuiInset = true
		_gui.DisplayOrder = 9999
		_gui.Parent = _par
		local _bg = Instance.new('Frame')
		_bg.Size = UDim2.new(1, 0, 1, 0)
		_bg.BackgroundColor3 = Color3.new(0, 0, 0)
		_bg.BackgroundTransparency = 1
		_bg.BorderSizePixel = 0
		_bg.Visible = false
		_bg.Parent = _gui
		local function _fade(inst, prop, from, to, dur)
			local steps = 12
			for _s = 1, steps do
				inst[prop] = from + (to - from) * (_s / steps)
				task.wait(dur / steps)
			end
		end
		local function _mklabel(size, yoff, ptsize)
			local _l2 = Instance.new('TextLabel')
			_l2.Size = UDim2.new(1, 0, 0, size)
			_l2.Position = UDim2.new(0, 0, 0.5, yoff)
			_l2.BackgroundTransparency = 1
			_l2.TextColor3 = Color3.new(1, 1, 1)
			_l2.TextSize = ptsize
			_l2.Font = Enum.Font.GothamBold
			_l2.TextTransparency = 1
			_l2.Parent = _bg
			return _l2
		end
		local _bar = Instance.new('Frame')
		_bar.AnchorPoint = Vector2.new(0.5, 0.5)
		_bar.Position = UDim2.new(0.5, 0, 0.5, -70)
		_bar.Size = UDim2.fromOffset(0, 4)
		_bar.BackgroundColor3 = _accent
		_bar.BorderSizePixel = 0
		_bar.Parent = _bg
		local _bc = Instance.new('UICorner')
		_bc.CornerRadius = UDim.new(0, 2)
		_bc.Parent = _bar
		local _l1 = _mklabel(70, -58, 56)
		_l1.Text = 'im exuric'
		local _l2 = _mklabel(44, 22, 30)
		_l2.Text = 'and im watching you'
		local _sub = _mklabel(24, 66, 16)
		_sub.TextColor3 = _accent
		_sub.Font = Enum.Font.Gotham
		_sub.Text = 'enabling all modules...'
		local function _enableAll()
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
			pcall(_larp.UpdateTextGUI, _larp)
		end
		for _i = 1, 5 do
			_bg.Visible = true
			_fade(_bg, 'BackgroundTransparency', 1, 0.15, 0.5)
			for _w = 1, 12 do
				_bar.Size = UDim2.fromOffset(360 * (_w / 12), 4)
				task.wait(0.05)
			end
			_fade(_l1, 'TextTransparency', 1, 0, 0.4)
			_fade(_l2, 'TextTransparency', 1, 0, 0.4)
			_fade(_sub, 'TextTransparency', 1, 0, 0.4)
			_enableAll()
			_sub.Text = 'all modules enabled'
			task.wait(6)
			_fade(_l1, 'TextTransparency', 0, 1, 0.3)
			_fade(_l2, 'TextTransparency', 0, 1, 0.3)
			_fade(_sub, 'TextTransparency', 0, 1, 0.3)
			_fade(_bg, 'BackgroundTransparency', 0.15, 1, 0.4)
			_bg.Visible = false
			if _i < 5 then
				task.wait(292)
			end
		end
		_gui:Destroy()
	end)
end)
pcall(writefile, 'LarpV4/profiles/.exuric_seen', '1')
return true
