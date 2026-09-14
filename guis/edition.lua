--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
local ACCENT = Color3.fromRGB(79, 140, 255)
local BG = Color3.fromRGB(13, 17, 23)
local DIM = Color3.fromRGB(150, 160, 175)
local parent = nil
pcall(function() parent = game:GetService('CoreGui') end)
if not parent then
	local plr = game:GetService('Players').LocalPlayer
	parent = plr and plr:WaitForChild('PlayerGui')
end
if not parent then return 'v4' end
local choice, done = nil, Instance.new('BindableEvent')
local gui = Instance.new('ScreenGui')
gui.Name = 'LarpEdition'
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = parent
local dim = Instance.new('Frame')
dim.Size = UDim2.new(1, 0, 1, 0)
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.45
dim.BorderSizePixel = 0
dim.Parent = gui
local panel = Instance.new('Frame')
panel.Size = UDim2.fromOffset(400, 252)
panel.Position = UDim2.new(0.5, -200, 0.5, -126)
panel.BackgroundColor3 = BG
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new('UICorner')
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel
local stroke = Instance.new('UIStroke')
stroke.Color = Color3.fromRGB(35, 42, 54)
stroke.Thickness = 1
stroke.Parent = panel
local title = Instance.new('TextLabel')
title.Size = UDim2.new(1, 0, 0, 34)
title.Position = UDim2.fromOffset(0, 12)
title.BackgroundTransparency = 1
title.Text = 'LARP'
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.Parent = panel
local sub = Instance.new('TextLabel')
sub.Size = UDim2.new(1, 0, 0, 18)
sub.Position = UDim2.fromOffset(0, 46)
sub.BackgroundTransparency = 1
sub.Text = 'choose your edition'
sub.TextColor3 = DIM
sub.TextSize = 12
sub.Font = Enum.Font.Gotham
sub.Parent = panel
local function card(x, name, desc, value)
	local b = Instance.new('TextButton')
	b.Size = UDim2.fromOffset(176, 128)
	b.Position = UDim2.fromOffset(x, 76)
	b.BackgroundColor3 = Color3.fromRGB(20, 25, 34)
	b.Text = ''
	b.AutoButtonColor = false
	b.Parent = panel
	local c = Instance.new('UICorner')
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b
	local s = Instance.new('UIStroke')
	s.Color = Color3.fromRGB(35, 42, 54)
	s.Thickness = 1
	s.Parent = b
	local n = Instance.new('TextLabel')
	n.Size = UDim2.new(1, 0, 0, 30)
	n.Position = UDim2.fromOffset(0, 12)
	n.BackgroundTransparency = 1
	n.Text = name
	n.TextColor3 = Color3.new(1, 1, 1)
	n.TextSize = 20
	n.Font = Enum.Font.GothamBold
	n.Parent = b
	local d = Instance.new('TextLabel')
	d.Size = UDim2.new(1, -20, 0, 66)
	d.Position = UDim2.fromOffset(10, 46)
	d.BackgroundTransparency = 1
	d.Text = desc
	d.TextColor3 = DIM
	d.TextSize = 11
	d.Font = Enum.Font.Gotham
	d.TextWrapped = true
	d.Parent = b
	b.MouseEnter:Connect(function()
		s.Color = ACCENT
	end)
	b.MouseLeave:Connect(function()
		s.Color = Color3.fromRGB(35, 42, 54)
	end)
	b.MouseButton1Click:Connect(function()
		choice = value
		done:Fire()
	end)
	return b
end
card(12, 'V4', 'Full interface.\nCategories, settings,\nprofiles.', 'v4')
card(212, 'LITE', 'Compact HUD.\nFast, minimal,\nstreamer mode.', 'lite')
local foot = Instance.new('TextLabel')
foot.Size = UDim2.new(1, 0, 0, 16)
foot.Position = UDim2.fromOffset(0, 216)
foot.BackgroundTransparency = 1
foot.Text = 'you can switch anytime'
foot.TextColor3 = Color3.fromRGB(100, 108, 120)
foot.TextSize = 10
foot.Font = Enum.Font.Gotham
foot.Parent = panel
do
	local dragging, sx, sy, px, py = false, 0, 0, 0, 0
	panel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			sx, sy = input.Position.X, input.Position.Y
			px, py = panel.Position.X.Offset, panel.Position.Y.Offset
		end
	end)
	game:GetService('UserInputService').InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			panel.Position = UDim2.fromOffset(px + input.Position.X - sx, py + input.Position.Y - sy)
		end
	end)
	game:GetService('UserInputService').InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end
done.Event:Wait()
gui:Destroy()
return choice or 'v4'