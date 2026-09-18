--id:notice-5
--target:discipleofgodd
local _seen5 = false
pcall(function() _seen5 = isfile('LarpV4/profiles/.survey_seen') end)
if _seen5 then return true end
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
		local function _light(_c, _a)
			local _h, _s, _v = _c:ToHSV()
			return Color3.fromHSV(_h, _s, math.clamp(_v + _a, 0, 1))
		end
		local _par = nil
		pcall(function()
			if gethui then _par = gethui() end
		end)
		if not _par then _par = game:GetService('CoreGui') end
		local _gui = Instance.new('ScreenGui')
		_gui.Name = 'SurveyNotice'
		_gui.ResetOnSpawn = false
		_gui.IgnoreGuiInset = true
		_gui.DisplayOrder = 9999
		_gui.Parent = _par
		local _panel = Instance.new('Frame')
		_panel.AnchorPoint = Vector2.new(0.5, 0.5)
		_panel.Position = UDim2.new(0.5, 0, 0.5, 12)
		_panel.Size = UDim2.fromOffset(420, 170)
		_panel.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
		_panel.BackgroundTransparency = 1
		_panel.BorderSizePixel = 0
		_panel.Parent = _gui
		local _pc = Instance.new('UICorner')
		_pc.CornerRadius = UDim.new(0, 8)
		_pc.Parent = _panel
		local _bar = Instance.new('Frame')
		_bar.Size = UDim2.new(1, 0, 0, 4)
		_bar.BackgroundColor3 = _accent
		_bar.BorderSizePixel = 0
		_bar.BackgroundTransparency = 1
		_bar.Parent = _panel
		local _bc = Instance.new('UICorner')
		_bc.CornerRadius = UDim.new(0, 8)
		_bc.Parent = _bar
		local function _mkbtn(x, text, accent)
			local _b = Instance.new('TextButton')
			_b.Size = UDim2.fromOffset(150, 40)
			_b.Position = UDim2.fromOffset(x, 108)
			_b.BackgroundColor3 = accent and _accent or Color3.fromRGB(45, 45, 45)
			_b.BackgroundTransparency = 1
			_b.Text = ''
			_b.AutoButtonColor = false
			_b.Parent = _panel
			local _cc = Instance.new('UICorner')
			_cc.CornerRadius = UDim.new(0, 6)
			_cc.Parent = _b
			local _t = Instance.new('TextLabel')
			_t.Size = UDim2.new(1, 0, 1, 0)
			_t.BackgroundTransparency = 1
			_t.Text = text
			_t.TextColor3 = Color3.new(1, 1, 1)
			_t.TextSize = 15
			_t.Font = Enum.Font.GothamBold
			_t.TextTransparency = 1
			_t.Parent = _b
			_b.MouseEnter:Connect(function()
				_b.BackgroundColor3 = accent and _light(_accent, 0.12) or Color3.fromRGB(62, 62, 62)
			end)
			_b.MouseLeave:Connect(function()
				_b.BackgroundColor3 = accent and _accent or Color3.fromRGB(45, 45, 45)
			end)
			return _b, _t
		end
		local _q = Instance.new('TextLabel')
		_q.Size = UDim2.new(1, -40, 0, 30)
		_q.Position = UDim2.fromOffset(20, 26)
		_q.BackgroundTransparency = 1
		_q.Text = 'did the revert config fix?'
		_q.TextColor3 = Color3.new(1, 1, 1)
		_q.TextSize = 17
		_q.Font = Enum.Font.GothamBold
		_q.TextTransparency = 1
		_q.Parent = _panel
		local _yes = _mkbtn(40, 'YES', true)
		local _no = _mkbtn(230, 'NO', false)
		local _res = Instance.new('TextLabel')
		_res.Size = UDim2.new(1, -40, 0, 40)
		_res.Position = UDim2.fromOffset(20, 96)
		_res.BackgroundTransparency = 1
		_res.Text = ''
		_res.TextColor3 = _accent
		_res.TextSize = 20
		_res.Font = Enum.Font.GothamBold
		_res.TextTransparency = 1
		_res.Visible = false
		_res.Parent = _panel
		local function _fadeBg(to, dur)
			local from = _panel.BackgroundTransparency
			local steps = 10
			for _s = 1, steps do
				_panel.BackgroundTransparency = from + (to - from) * (_s / steps)
				task.wait(dur / steps)
			end
		end
		local function _fadeTxt(inst, to, dur)
			local from = inst.TextTransparency
			local steps = 8
			for _s = 1, steps do
				inst.TextTransparency = from + (to - from) * (_s / steps)
				task.wait(dur / steps)
			end
		end
		local _done = Instance.new('BindableEvent')
		local _answered, _choice = false, nil
		_yes.MouseButton1Click:Connect(function()
			if _answered then return end
			_answered, _choice = true, 'yes'
			_done:Fire()
		end)
		_no.MouseButton1Click:Connect(function()
			if _answered then return end
			_answered, _choice = true, 'no'
			_done:Fire()
		end)
		local _py = 12
		for _s = 1, 10 do
			_panel.Position = UDim2.new(0.5, 0, 0.5, _py - (_s / 10) * 12)
			task.wait(0.025)
		end
		_panel.Position = UDim2.new(0.5, 0, 0.5, 0)
		_fadeBg(0.05, 0.35)
		_bar.BackgroundTransparency = 0
		_fadeTxt(_q, 0, 0.3)
		for _, _pair in ipairs({{select(1, _yes)}, {select(1, _no)}}) do
			local _b = _pair[1]
			_b.BackgroundTransparency = 0
			for _, _ch in ipairs(_b:GetChildren()) do
				if _ch:IsA('TextLabel') then
					_fadeTxt(_ch, 0, 0.25)
				end
			end
		end
		task.delay(30, function()
			if not _answered then
				_answered, _choice = true, 'timeout'
				pcall(function() _done:Fire() end)
			end
		end)
		_done.Event:Wait()
		if _choice == 'yes' or _choice == 'no' then
			_q.Visible = false
			local _yb = select(1, _yes)
			local _nb = select(1, _no)
			_yb.Visible = false
			_nb.Visible = false
			if _choice == 'yes' then
				_res.Text = "you're welcome"
			else
				_res.Text = 'contact exuric'
			end
			_res.Visible = true
			_fadeTxt(_res, 0, 0.3)
			task.wait(_choice == 'yes' and 2.5 or 4)
			_fadeTxt(_res, 1, 0.3)
		end
		_fadeBg(1, 0.35)
		_gui:Destroy()
	end)
end)
pcall(writefile, 'LarpV4/profiles/.survey_seen', '1')
return true
