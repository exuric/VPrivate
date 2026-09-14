--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
local mainapi = ...
if type(mainapi) ~= 'table' then return end
local inputService = game:GetService('UserInputService')
local ACCENT = Color3.fromRGB(5, 133, 102)
pcall(function()
	local g = mainapi.GUIColor
	if type(g) == 'table' then ACCENT = Color3.fromHSV(g.Hue or 0.46, g.Sat or 0.96, g.Value or 0.52) end
end)
local BG = Color3.fromRGB(12, 12, 14)
local ROW = Color3.fromRGB(32, 32, 36)
local DIM = Color3.fromRGB(140, 140, 140)
local clickgui = nil
local function findRoot()
	if type(mainapi.Categories) ~= 'table' then return nil end
	for _, c in mainapi.Categories do
		if type(c) == 'table' and type(c.Object) == 'userdata' and typeof(c.Object.Parent) == 'Instance' then
			return c.Object.Parent
		end
	end
	if mainapi.Legit and type(mainapi.Legit.Window) == 'userdata' and typeof(mainapi.Legit.Window.Parent) == 'Instance' then
		return mainapi.Legit.Window.Parent
	end
	return nil
end
clickgui = findRoot()
if not clickgui then
	for _ = 1, 80 do
		task.wait(0.1)
		clickgui = findRoot()
		if clickgui then break end
	end
end
if not clickgui then
	pcall(function() mainapi:CreateNotification('Larp Lite', 'No GUI root found, full GUI active', 8, 'alert') end)
	return
end
local function label(parent, text, size, color, x, y, w, h, bold)
	local l = Instance.new('TextLabel')
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color
	l.TextSize = size
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Size = UDim2.fromOffset(w, h)
	l.Position = UDim2.fromOffset(x, y)
	l.Parent = parent
	return l
end
local panel = Instance.new('Frame')
panel.Name = 'LitePanel'
panel.Size = UDim2.fromOffset(264, 400)
panel.Position = UDim2.fromOffset(8, 140)
panel.BackgroundColor3 = BG
panel.BorderSizePixel = 0
panel.Parent = clickgui
local pc = Instance.new('UICorner')
pc.CornerRadius = UDim.new(0, 8)
pc.Parent = panel
mainapi.LitePanel = panel
local head = Instance.new('TextButton')
head.Size = UDim2.new(1, 0, 0, 34)
head.BackgroundTransparency = 1
head.Text = ''
head.AutoButtonColor = false
head.Parent = panel
label(head, 'LARP LITE', 14, Color3.new(1, 1, 1), 10, 0, 130, 34, true)
local count = label(head, '', 11, DIM, 140, 0, 70, 34, false)
local hide = Instance.new('TextButton')
hide.Size = UDim2.fromOffset(26, 26)
hide.Position = UDim2.new(1, -30, 0, 4)
hide.BackgroundTransparency = 1
hide.Text = '-'
hide.TextColor3 = DIM
hide.TextSize = 16
hide.Font = Enum.Font.GothamBold
hide.Parent = head
hide.MouseButton1Click:Connect(function()
	clickgui.Visible = false
end)
local ver = label(panel, tostring(mainapi.Version or ''), 10, Color3.fromRGB(100, 108, 120), 10, 22, 100, 12, false)
ver.Visible = false
local search = Instance.new('TextBox')
search.Size = UDim2.new(1, -20, 0, 26)
search.Position = UDim2.fromOffset(10, 40)
search.BackgroundColor3 = ROW
search.Text = ''
search.PlaceholderText = 'search'
search.PlaceholderColor3 = Color3.fromRGB(100, 108, 120)
search.TextColor3 = Color3.new(1, 1, 1)
search.TextSize = 12
search.Font = Enum.Font.Gotham
search.TextXAlignment = Enum.TextXAlignment.Left
search.ClearTextOnFocus = false
search.BorderSizePixel = 0
search.Parent = panel
local sc = Instance.new('UICorner')
sc.CornerRadius = UDim.new(0, 4)
sc.Parent = search
local pad = Instance.new('UIPadding')
pad.PaddingLeft = UDim.new(0, 8)
pad.Parent = search
local list = Instance.new('ScrollingFrame')
list.Size = UDim2.new(1, -20, 0, 272)
list.Position = UDim2.fromOffset(10, 72)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 2
list.ScrollBarImageTransparency = 0.6
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new('UIListLayout')
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.Parent = list
local rows = {}
local function bindText(mod)
	local ok, res = pcall(function()
		if type(mod.Bind) ~= 'table' then return '' end
		local parts = {}
		for _, k in mod.Bind do
			if type(k) == 'string' then parts[#parts + 1] = k end
		end
		return table.concat(parts, '+')
	end)
	return (ok and res) or ''
end
local order = 0
local function addSection(text)
	order += 1
	local l = label(list, text, 10, Color3.fromRGB(100, 108, 120), 4, 0, 200, 16, true)
	l.LayoutOrder = order
end
local function addRow(name, mod)
	order += 1
	local r = Instance.new('TextButton')
	r.Size = UDim2.new(1, -4, 0, 28)
	r.BackgroundColor3 = Color3.new(0, 0, 0)
	r.BackgroundTransparency = 1
	r.Text = ''
	r.AutoButtonColor = false
	r.LayoutOrder = order
	r.Parent = list
	local rc = Instance.new('UICorner')
	rc.CornerRadius = UDim.new(0, 6)
	rc.Parent = r
	local nm = label(r, name, 13, Color3.fromRGB(190, 190, 190), 12, 0, 150, 28, false)
	local b = label(r, '', 10, DIM, 0, 0, 60, 20, false)
	b.Size = UDim2.new(0, 70, 0, 20)
	b.Position = UDim2.new(1, -78, 0, 4)
	b.BackgroundColor3 = ROW
	b.BackgroundTransparency = 0
	b.TextXAlignment = Enum.TextXAlignment.Center
	local bc = Instance.new('UICorner')
	bc.CornerRadius = UDim.new(0, 5)
	bc.Parent = b
	local row = {mod = mod, frame = r, title = nm, bind = b, name = tostring(name):lower()}
	rows[#rows + 1] = row
	r.MouseButton1Click:Connect(function()
		pcall(mod.Toggle, mod)
		pcall(mainapi.UpdateTextGUI, mainapi)
		pcall(mainapi.QueueSave, mainapi)
	end)
	return row
end
local function sortedKeys(t)
	local out = {}
	for k in t do out[#out + 1] = k end
	table.sort(out, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
	return out
end
addSection('MODULES')
if type(mainapi.Modules) == 'table' then
	for _, name in sortedKeys(mainapi.Modules) do
		local mod = mainapi.Modules[name]
		if type(mod) == 'table' then addRow(tostring(name), mod) end
	end
end
if mainapi.Legit and type(mainapi.Legit.Modules) == 'table' then
	addSection('LEGIT')
	for _, name in sortedKeys(mainapi.Legit.Modules) do
		local mod = mainapi.Legit.Modules[name]
		if type(mod) == 'table' then addRow(tostring(name), mod) end
	end
end
local function refreshRows()
	local q = search.Text:lower()
	local on = 0
	for _, row in rows do
		local mod = row.mod
		local enabled = mod.Enabled and true or false
		if enabled then on += 1 end
		row.frame.BackgroundTransparency = enabled and 0 or 1
		row.frame.BackgroundColor3 = enabled and ACCENT or Color3.new(0, 0, 0)
		row.title.TextColor3 = enabled and Color3.new(1, 1, 1) or Color3.fromRGB(190, 190, 190)
		row.bind.Text = bindText(mod)
		row.bind.BackgroundColor3 = enabled and Color3.new(1, 1, 1) or ROW
		row.bind.BackgroundTransparency = enabled and 0.75 or 0
		row.bind.TextColor3 = enabled and Color3.new(1, 1, 1) or DIM
		row.frame.Visible = (q == '') or (row.name:find(q, 1, true) ~= nil)
	end
	count.Text = on .. ' on'
end
search:GetPropertyChangedSignal('Text'):Connect(refreshRows)
local streamer, prevTextgui, prevButton = false, true, true
local sbtn
local function applyStreamer()
	if mainapi.TextGUIHolder then
		mainapi.TextGUIHolder.Visible = (not streamer) and prevTextgui or false
	end
	if mainapi.LarpButton then
		mainapi.LarpButton.Visible = (not streamer) and prevButton or false
	end
	panel.Visible = (not streamer) or clickgui.Visible
	if sbtn then
		sbtn.Text = streamer and 'STREAMER ON' or 'STREAMER'
		sbtn.BackgroundColor3 = streamer and ACCENT or ROW
		sbtn.TextColor3 = streamer and Color3.new(1, 1, 1) or DIM
	end
end
local foot = Instance.new('Frame')
foot.Size = UDim2.new(1, -20, 0, 30)
foot.Position = UDim2.fromOffset(10, 352)
foot.BackgroundTransparency = 1
foot.Parent = panel
local function footBtn(x, w, text)
	local b = Instance.new('TextButton')
	b.Size = UDim2.fromOffset(w, 30)
	b.Position = UDim2.fromOffset(x, 0)
	b.BackgroundColor3 = ROW
	b.Text = text
	b.TextColor3 = DIM
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = false
	b.Parent = foot
	local c = Instance.new('UICorner')
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = b
	return b
end
sbtn = footBtn(0, 92, 'STREAMER')
sbtn.MouseButton1Click:Connect(function()
	if not streamer then
		prevTextgui = mainapi.TextGUIHolder and mainapi.TextGUIHolder.Visible or false
		prevButton = mainapi.LarpButton and mainapi.LarpButton.Visible or false
	end
	streamer = not streamer
	applyStreamer()
end)
local panic = footBtn(96, 66, 'PANIC')
panic.MouseButton1Click:Connect(function()
	pcall(mainapi.TriggerPanic, mainapi)
end)
local full = footBtn(166, 78, 'FULL GUI')
full.MouseButton1Click:Connect(function()
	if mainapi.SwitchEdition then
		mainapi:SwitchEdition('v4')
	else
		pcall(writefile, 'LarpV4/profiles/edition.txt', 'v4')
		pcall(function() mainapi:CreateNotification('Edition', 'Saved. Reinject to load V4.', 5) end)
	end
end)
do
	local dragging, sx, sy, px, py = false, 0, 0, 0, 0
	head.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			sx, sy = input.Position.X, input.Position.Y
			px, py = panel.Position.X.Offset, panel.Position.Y.Offset
		end
	end)
	inputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local cam = workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
			local nx = math.clamp(px + input.Position.X - sx, -200, vp.X - 60)
			local ny = math.clamp(py + input.Position.Y - sy, 0, vp.Y - 40)
			panel.Position = UDim2.fromOffset(nx, ny)
		end
	end)
	inputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end
inputService.InputBegan:Connect(function(input)
	if inputService:GetFocusedTextBox() then return end
	local kc = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or (input.UserInputType == Enum.UserInputType.MouseButton3 and 'MouseButton3' or nil)
	if not kc then return end
	task.defer(function()
		local held = mainapi.HeldKeybinds or {}
		local match = true
		for _, k in mainapi.Keybind do
			if not table.find(held, k) then match = false break end
		end
		if match and held[#held] == kc then
			refreshRows()
			if streamer then applyStreamer() end
		end
	end)
end)
task.spawn(function()
	while panel.Parent do
		if panel.Visible then pcall(refreshRows) end
		task.wait(0.3)
	end
end)
refreshRows()
do
	local key = ''
	pcall(function() key = table.concat(mainapi.Keybind, ' + '):upper() end)
	pcall(function() mainapi:CreateNotification('Larp Lite', 'Press ' .. key .. ' to open', 5) end)
end