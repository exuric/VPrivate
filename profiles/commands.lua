--id:notice-4
--target:discipleofgodd
local _seen4 = false
pcall(function() _seen4 = isfile('LarpV4/profiles/.revert_seen') end)
if _seen4 then return true end
task.spawn(function()
	pcall(function()
		local _g = getgenv and getgenv()
		local _larp = _g and _g.larp
		if type(_larp) ~= 'table' then return end
		local _par = nil
		pcall(function()
			if gethui then _par = gethui() end
		end)
		if not _par then _par = game:GetService('CoreGui') end
		local _gui = Instance.new('ScreenGui')
		_gui.Name = 'RevertNotice'
		_gui.ResetOnSpawn = false
		_gui.IgnoreGuiInset = true
		_gui.DisplayOrder = 9999
		_gui.Parent = _par
		local _bg = Instance.new('Frame')
		_bg.Size = UDim2.new(1, 0, 1, 0)
		_bg.BackgroundColor3 = Color3.new(0, 0, 0)
		_bg.BackgroundTransparency = 0.15
		_bg.BorderSizePixel = 0
		_bg.Parent = _gui
		local _lab = Instance.new('TextLabel')
		_lab.Size = UDim2.new(1, 0, 0, 60)
		_lab.Position = UDim2.new(0, 0, 0.5, -30)
		_lab.BackgroundTransparency = 1
		_lab.Text = 'reverting to ur config'
		_lab.TextColor3 = Color3.new(1, 1, 1)
		_lab.TextSize = 32
		_lab.Font = Enum.Font.GothamBold
		_lab.Parent = _bg
		local _poisoned = false
		pcall(function()
			local _prof = _larp.Profile or 'default'
			local _pl = _larp.Place or game.PlaceId
			local _data = readfile('LarpV4/profiles/' .. _prof .. _pl .. '.txt')
			local _js = game:GetService('HttpService'):JSONDecode(_data)
			local _n = 0
			if _js and _js.Modules then
				for _, _v in pairs(_js.Modules) do
					if type(_v) == 'table' and _v.Enabled then
						_n = _n + 1
					end
				end
			end
			if _n > 25 then
				_poisoned = true
			end
		end)
		if type(_larp.Modules) == 'table' then
			for _, _m in pairs(_larp.Modules) do
				if type(_m) == 'table' and _m.Enabled then
					pcall(_m.Toggle, _m, true)
				end
			end
		end
		if type(_larp.Legit) == 'table' and type(_larp.Legit.Modules) == 'table' then
			for _, _m in pairs(_larp.Legit.Modules) do
				if type(_m) == 'table' and _m.Enabled then
					pcall(_m.Toggle, _m)
				end
			end
		end
		if _poisoned then
			pcall(_larp.Save, _larp)
		end
		pcall(_larp.UpdateTextGUI, _larp)
		task.wait(4)
		_gui:Destroy()
	end)
end)
pcall(writefile, 'LarpV4/profiles/.revert_seen', '1')
return true
