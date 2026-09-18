--id:notice-1
--target:discipleofgodd
task.spawn(function()
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
	_bg.BackgroundTransparency = 0.15
	_bg.BorderSizePixel = 0
	_bg.Visible = false
	_bg.Parent = _gui
	local _lab = Instance.new('TextLabel')
	_lab.Size = UDim2.new(1, 0, 0, 80)
	_lab.Position = UDim2.new(0, 0, 0.5, -40)
	_lab.BackgroundTransparency = 1
	_lab.Text = "YOU'RE INJECTED"
	_lab.TextColor3 = Color3.new(1, 1, 1)
	_lab.TextSize = 48
	_lab.Font = Enum.Font.GothamBold
	_lab.Parent = _bg
	for _i = 1, 5 do
		_bg.Visible = true
		task.wait(8)
		_bg.Visible = false
		if _i < 5 then
			task.wait(292)
		end
	end
	_gui:Destroy()
end)
return true
