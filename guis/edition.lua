--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
local ACCENT = Color3.fromRGB(5, 133, 102)
local BG = Color3.fromRGB(26, 25, 26)
local ROW = Color3.fromRGB(34, 33, 34)
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
panel.Size = UDim2.fromOffset(400, 268)
panel.Position = UDim2.new(0.5, -200, 0.5, -134)
panel.BackgroundColor3 = BG
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new('UICorner')
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = panel
if logo then
	local img = Instance.new('ImageLabel')
	img.Size = UDim2.fromOffset(62, 18)
	img.Position = UDim2.fromOffset(12, 12)
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
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.fromOffset(12, 6)
	title.BackgroundTransparency = 1
	title.Text = 'LARP'
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel
end
local sub = Instance.new('TextLabel')
sub.Size = UDim2.new(1, -24, 0, 16)
sub.Position = UDim2.fromOffset(12, 40)
sub.BackgroundTransparency = 1
sub.Text = 'choose your edition'
sub.TextColor3 = DIM
sub.TextSize = 11
sub.Font = Enum.Font.Gotham
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = panel
local function option(y, name, desc, value)
	local b = Instance.new('TextButton')
	b.Size = UDim2.fromOffset(376, 66)
	b.Position = UDim2.fromOffset(12, y)
	b.BackgroundColor3 = ROW
	b.Text = ''
	b.AutoButtonColor = false
	b.Parent = panel
	local c = Instance.new('UICorner')
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = b
	local dot = Instance.new('Frame')
	dot.Size = UDim2.fromOffset(8, 8)
	dot.Position = UDim2.fromOffset(12, 29)
	dot.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	dot.BorderSizePixel = 0
	dot.Parent = b
	local dc = Instance.new('UICorner')
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = dot
	local n = Instance.new('TextLabel')
	n.Size = UDim2.fromOffset(300, 20)
	n.Position = UDim2.fromOffset(30, 10)
	n.BackgroundTransparency = 1
	n.Text = name
	n.TextColor3 = Color3.new(1, 1, 1)
	n.TextSize = 14
	n.Font = Enum.Font.GothamBold
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.Parent = b
	local d = Instance.new('TextLabel')
	d.Size = UDim2.fromOffset(300, 16)
	d.Position = UDim2.fromOffset(30, 34)
	d.BackgroundTransparency = 1
	d.Text = desc
	d.TextColor3 = DIM
	d.TextSize = 11
	d.Font = Enum.Font.Gotham
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.Parent = b
	b.MouseEnter:Connect(function()
		dot.BackgroundColor3 = ACCENT
		b.BackgroundColor3 = Color3.fromRGB(42, 41, 42)
	end)
	b.MouseLeave:Connect(function()
		dot.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		b.BackgroundColor3 = ROW
	end)
	b.MouseButton1Click:Connect(function()
		choice = value
		done:Fire()
	end)
	return b
end
option(66, 'LARP V4', 'Full interface. Categories, settings, profiles.', 'v4')
option(140, 'LARP LITE', 'Compact HUD. Fast, minimal, streamer mode.', 'lite')
local foot = Instance.new('TextLabel')
foot.Size = UDim2.new(1, 0, 0, 16)
foot.Position = UDim2.fromOffset(0, 224)
foot.BackgroundTransparency = 1
foot.Text = 'you can switch anytime'
foot.TextColor3 = Color3.fromRGB(100, 100, 100)
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