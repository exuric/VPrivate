--id:notice-6
--target:discipleofgodd
pcall(function()
	local _par = nil
	pcall(function()
		if gethui then _par = gethui() end
	end)
	if not _par then _par = game:GetService('CoreGui') end
	for _, _g in ipairs(_par:GetChildren()) do
		if _g.Name == 'SurveyNotice' then
			pcall(function() _g:Destroy() end)
		end
	end
end)
local _seen6 = false
pcall(function() _seen6 = isfile('LarpV4/profiles/.rate_seen') end)
if _seen6 then return true end
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
		local _star = ''
		pcall(function()
			if getcustomasset then
				_star = getcustomasset('LarpV4/assets/larp/favourite.png')
			end
		end)
		if type(_star) ~= 'string' then _star = '' end
		if _star == '' then
			pcall(function()
				if getcustomasset then
					_star = getcustomasset('LarpV4/assets/larp/star.png')
				end
			end)
		end
		if type(_star) ~= 'string' then _star = '' end
		local _logo = nil
		pcall(function()
			if getcustomasset then
				_logo = getcustomasset('LarpV4/assets/larp/Larp.png')
			end
		end)
		if type(_logo) ~= 'string' or _logo == '' then _logo = nil end
		local _par = nil
		pcall(function()
			if gethui then _par = gethui() end
		end)
		if not _par then _par = game:GetService('CoreGui') end
		local _gui = Instance.new('ScreenGui')
		_gui.Name = 'RateNotice'
		_gui.ResetOnSpawn = false
		_gui.IgnoreGuiInset = true
		_gui.DisplayOrder = 9999
		_gui.Parent = _par
		local _panel = Instance.new('Frame')
		_panel.AnchorPoint = Vector2.new(0.5, 0.5)
		_panel.Position = UDim2.new(0.5, 0, 0.5, 12)
		_panel.Size = UDim2.fromOffset(380, 220)
		_panel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
		_panel.BackgroundTransparency = 1
		_panel.BorderSizePixel = 0
		_panel.Parent = _gui
		local _pc = Instance.new('UICorner')
		_pc.CornerRadius = UDim.new(0, 10)
		_pc.Parent = _panel
		if _logo then
			local _img = Instance.new('ImageLabel')
			_img.Size = UDim2.fromOffset(62, 18)
			_img.Position = UDim2.new(0.5, -31, 0, 14)
			_img.BackgroundTransparency = 1
			_img.Image = _logo
			_img.ImageColor3 = Color3.new(1, 1, 1)
			_img.ImageTransparency = 1
			_img.Parent = _panel
			task.spawn(function()
				for _s = 1, 8 do
					pcall(function() _img.ImageTransparency = 1 - (_s / 8) end)
					task.wait(0.04)
				end
			end)
		end
		local _q = Instance.new('TextLabel')
		_q.Size = UDim2.new(1, -40, 0, 24)
		_q.Position = UDim2.fromOffset(20, 44)
		_q.BackgroundTransparency = 1
		_q.Text = 'hows the larp v4 experience?'
		_q.TextColor3 = Color3.new(1, 1, 1)
		_q.TextSize = 16
		_q.Font = Enum.Font.GothamBold
		_q.TextTransparency = 1
		_q.Parent = _panel
		local _stars = {}
		local _rated, _hover, _answered = 0, 0, false
		local function _paint()
			for _i, _s in ipairs(_stars) do
				local _lit = _i <= ((_hover > 0 and _hover) or _rated)
				local _art = _s:FindFirstChild('Art')
				if _art then
					_art.ImageColor3 = _lit and Color3.fromRGB(255, 184, 31) or Color3.fromRGB(70, 70, 70)
				else
					_s.TextColor3 = _lit and Color3.fromRGB(255, 184, 31) or Color3.fromRGB(70, 70, 70)
				end
			end
		end
		for _i = 1, 5 do
			local _b = Instance.new('TextButton')
			_b.Size = UDim2.fromOffset(36, 36)
			_b.Position = UDim2.fromOffset(86 + (_i - 1) * 42, 84)
			_b.BackgroundTransparency = 1
			_b.Text = ''
			_b.AutoButtonColor = false
			_b.Parent = _panel
			if _star ~= '' then
				local _a = Instance.new('ImageLabel')
				_a.Name = 'Art'
				_a.Size = UDim2.fromOffset(30, 30)
				_a.Position = UDim2.fromOffset(3, 3)
				_a.BackgroundTransparency = 1
				_a.Image = _star
				_a.ImageColor3 = Color3.fromRGB(70, 70, 70)
				_a.ImageTransparency = 1
				_a.Parent = _b
			else
				_b.Text = tostring(_i)
				_b.TextColor3 = Color3.fromRGB(70, 70, 70)
				_b.TextSize = 20
				_b.Font = Enum.Font.GothamBold
			end
			local _idx = _i
			_b.MouseEnter:Connect(function()
				if _answered then return end
				_hover = _idx
				_paint()
			end)
			_b.MouseLeave:Connect(function()
				if _answered then return end
				_hover = 0
				_paint()
			end)
			_stars[_i] = _b
		end
		local _hint = Instance.new('TextLabel')
		_hint.Size = UDim2.new(1, -40, 0, 16)
		_hint.Position = UDim2.fromOffset(20, 130)
		_hint.BackgroundTransparency = 1
		_hint.Text = 'tap a star to rate'
		_hint.TextColor3 = Color3.fromRGB(140, 140, 140)
		_hint.TextSize = 11
		_hint.Font = Enum.Font.Gotham
		_hint.TextTransparency = 1
		_hint.Parent = _panel
		local _thanks = Instance.new('TextLabel')
		_thanks.Size = UDim2.new(1, -40, 0, 30)
		_thanks.Position = UDim2.fromOffset(20, 150)
		_thanks.BackgroundTransparency = 1
		_thanks.Text = 'thank you for your feedback'
		_thanks.TextColor3 = _accent
		_thanks.TextSize = 18
		_thanks.Font = Enum.Font.GothamBold
		_thanks.TextTransparency = 1
		_thanks.Visible = false
		_thanks.Parent = _panel
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
		for _i, _b in ipairs(_stars) do
			local _idx = _i
			_b.MouseButton1Click:Connect(function()
				if _answered then return end
				_answered = true
				_rated = _idx
				_hover = 0
				_paint()
				pcall(writefile, 'LarpV4/profiles/.rate_seen', tostring(_idx))
				_done:Fire()
			end)
		end
		local _py = 12
		for _s = 1, 10 do
			_panel.Position = UDim2.new(0.5, 0, 0.5, _py - (_s / 10) * 12)
			task.wait(0.025)
		end
		_panel.Position = UDim2.new(0.5, 0, 0.5, 0)
		_fadeBg(0, 0.35)
		_fadeTxt(_q, 0, 0.3)
		_fadeTxt(_hint, 0, 0.3)
		for _k, _b in ipairs(_stars) do
			local _art = _b:FindFirstChild('Art')
			if _art then
				_art.ImageTransparency = 0
			else
				_fadeTxt(_b, 0, 0.2)
			end
			task.wait(0.05)
		end
		task.delay(30, function()
			if not _answered then
				_answered = true
			end
			pcall(function() _done:Fire() end)
		end)
		_done.Event:Wait()
		if _rated > 0 then
			_q.Visible = false
			_hint.Visible = false
			for _, _b in ipairs(_stars) do
				_b.Visible = false
			end
			_thanks.Visible = true
			_fadeTxt(_thanks, 0, 0.35)
			task.wait(3)
			_fadeTxt(_thanks, 1, 0.3)
		end
		_fadeBg(1, 0.35)
		_gui:Destroy()
	end)
end)
return true
