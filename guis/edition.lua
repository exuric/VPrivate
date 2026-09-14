--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
local TEAL = Color3.fromRGB(15, 118, 110)
local TEALLIGHT = Color3.fromRGB(32, 148, 139)
local BG = Color3.fromRGB(10, 10, 12)
local PILL = Color3.fromRGB(40, 40, 44)
local DIM = Color3.fromRGB(140, 140, 140)
local parent = nil
pcall(function() parent = game:GetService('CoreGui') end)
if not parent then
	local plr = game:GetService('Players').LocalPlayer
	parent = plr and plr:WaitForChild('PlayerGui')
end
if not parent then return 'v4' end
local logo, logov4 = nil, nil
pcall(function()
	if getcustomasset then
		logo = getcustomasset('LarpV4/assets/larp/Larp.png')
		logov4 = getcustomasset('LarpV4/assets/larp/Textv4.png')
	end
end)
if type(logo) ~= 'string' or logo == '' then logo = nil end
if type(logov4) ~= 'string' or logov4 == '' then logov4 = nil end
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
panel.Size = UDim2.fromOffset(360, 252)
panel.Position = UDim2.new(0.5, -180, 0.5, -126)
panel.BackgroundColor3 = BG
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new('UICorner')
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel
if logo then
	local img = Instance.new('ImageLabel')
	img.Size = UDim2.fromOffset(62, 18)
	img.Position = UDim2.fromOffset(14, 12)
	img.BackgroundTransparency = 1
	img.Image = logo
	img.ImageColor3 = Color3.new(1, 1, 1)
	img.Parent = panel
	if logov4 then
		local v4 = Instance.new('ImageLabel')
		v4.Size = UDim2.fromOffset(28, 16)
		v4.Position = UDim2.new(1, 1, 0, 1)
		v4.BackgroundTransparency = 1
		v4.Image = logov4
		v4.Parent = img
	end
else
	local title = Instance.new('TextLabel')
	title.Size = UDim2.fromOffset(200, 30)
	title.Position = UDim2.fromOffset(14, 6)
	title.BackgroundTransparency = 1
	title.Text = 'LARP'
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel
end
local sub = Instance.new('TextLabel')
sub.Size = UDim2.fromOffset(300, 16)
sub.Position = UDim2.fromOffset(14, 40)
sub.BackgroundTransparency = 1
sub.Text = 'choose your edition'
sub.TextColor3 = DIM
sub.TextSize = 11
sub.Font = Enum.Font.Gotham
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = panel
local function option(y, name, desc, pill, value)
	local b = Instance.new('TextButton')
	b.Size = UDim2.fromOffset(332, 64)
	b.Position = UDim2.fromOffset(14, y)
	b.BackgroundColor3 = BG
	b.BackgroundTransparency = 1
	b.Text = ''
	b.AutoButtonColor = false
	b.Parent = panel
	local c = Instance.new('UICorner')
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b
	local n = Instance.new('TextLabel')
	n.Size = UDim2.fromOffset(220, 22)
	n.Position = UDim2.fromOffset(16, 10)
	n.BackgroundTransparency = 1
	n.Text = name
	n.TextColor3 = Color3.new(1, 1, 1)
	n.TextSize = 15
	n.Font = Enum.Font.GothamBold
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.Parent = b
	local d = Instance.new('TextLabel')
	d.Size = UDim2.fromOffset(220, 16)
	d.Position = UDim2.fromOffset(16, 34)
	d.BackgroundTransparency = 1
	d.Text = desc
	d.TextColor3 = DIM
	d.TextSize = 11
	d.Font = Enum.Font.Gotham
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.Parent = b
	local p = Instance.new('TextLabel')
	p.Size = UDim2.fromOffset(40, 32)
	p.Position = UDim2.new(1, -52, 0.5, -16)
	p.BackgroundColor3 = PILL
	p.Text = pill
	p.TextColor3 = Color3.new(1, 1, 1)
	p.TextSize = 13
	p.Font = Enum.Font.GothamBold
	p.Parent = b
	local pc = Instance.new('UICorner')
	pc.CornerRadius = UDim.new(0, 6)
	pc.Parent = p
	b.MouseEnter:Connect(function()
		b.BackgroundTransparency = 0
		b.BackgroundColor3 = TEAL
		p.BackgroundColor3 = TEALLIGHT
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundTransparency = 1
		p.BackgroundColor3 = PILL
	end)
	b.MouseButton1Click:Connect(function()
		choice = value
		done:Fire()
	end)
	return b
end
option(66, 'Larp V4', 'Full interface, settings, profiles', 'V4', 'v4')
option(138, 'Larp Lite', 'Compact HUD, streamer mode', 'LT', 'lite')
local foot = Instance.new('TextLabel')
foot.Size = UDim2.new(1, 0, 0, 16)
foot.Position = UDim2.fromOffset(14, 218)
foot.BackgroundTransparency = 1
foot.Text = 'you can switch anytime'
foot.TextColor3 = Color3.fromRGB(100, 100, 100)
foot.TextSize = 10
foot.Font = Enum.Font.Gotham
foot.TextXAlignment = Enum.TextXAlignment.Left
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