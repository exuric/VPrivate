--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
local larp = shared.larp
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and larp then
		larp:CreateNotification('Larp', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local LARPWATER = '--LARP:'..(pcall(readfile, 'LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'main')..'\n'
local LARPCOMMIT = (pcall(readfile, 'LarpV4/profiles/commit.txt') and readfile('LarpV4/profiles/commit.txt') or 'main'):gsub('%s+', '')
local function downloadFile(path, func)
	if not isfile(path) or (path:find('.lua') and #readfile(path) < 100) or readfile(path):sub(1, #LARPWATER) ~= LARPWATER then
		local suc, res = pcall(function()
			return game:HttpGet((getgenv().LarpReadRoot or 'https://raw.githubusercontent.com/exuric/VPrivate/')..LARPCOMMIT..'/'..select(1, path:gsub('LarpV4/', ''))..'?v='..LARPCOMMIT, true)
		end)
		if not suc or res == '404: Not Found' or (#res < 100 and path:find('.lua')) then
			error(res)
		end
		if path:find('.lua') then
			res = LARPWATER..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

larp.Place = 77790193039862

local run = function(func)
	func()
end
local cloneref = cloneref or function(ref) return ref end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local lighting = cloneref(game:GetService('Lighting'))
local lplr = playersService.LocalPlayer
local gameCamera = workspace.CurrentCamera
local getcustomasset = larp.Libraries.getcustomasset

local remotes = replicatedStorage:WaitForChild('Remotes')
local hitRequest = remotes:WaitForChild('HitRequest')
local beginBlock = remotes:WaitForChild('BeginBlocking')
local endBlock = remotes:WaitForChild('EndBlocking')
local placeBlock = remotes:WaitForChild('PlaceBlockRequest')
local setSlot = remotes:WaitForChild('SetSelectedSlot')

local NONBLOCK = {
	sword_weak = true, sword = true, bow = true, pickaxe = true,
	golden_apple = true, arrow = true, ['0'] = true
}

local function playerConfig()
	local ok, cfg = pcall(function() return require(replicatedStorage.Modules.PlayerConfig) end)
	return ok and cfg or nil
end

local function inventory()
	local ok, inv = pcall(function() return require(lplr.PlayerScripts.CharacterController.Inventory) end)
	return ok and inv or nil
end

local function localChar()
	return workspace:FindFirstChild('LocalCharacter_'..lplr.Name)
end

local function eyeOf(model)
	if not model then return nil end
	return model:FindFirstChild('PlayerEyeLevel') or model:FindFirstChild('Head') or model:FindFirstChild('Torso') or model.PrimaryPart
end

local function hitboxOf(model)
	if not model then return nil end
	return model:FindFirstChild('PlayerHitbox') or model:FindFirstChild('Torso') or model:FindFirstChild('HeadTorso') or eyeOf(model)
end

local function baseName(n)
	return (n:gsub('_FakeCharacter$', ''))
end

local function otherChars()
	return workspace:FindFirstChild('OtherCharacters')
end

local function alive(model)
	local hum = model:FindFirstChildOfClass('Humanoid')
	if hum then return hum.Health > 0 end
	return true
end

local function eachTarget(wantPlayers, wantBots, fn)
	local oc = otherChars()
	if not oc then return end
	local mine = lplr.Name..'_FakeCharacter'
	for _, model in oc:GetChildren() do
		if model.Name ~= mine and model:IsA('Model') then
			local plr = playersService:FindFirstChild(baseName(model.Name))
			local isBot = plr == nil
			if (isBot and wantBots) or (not isBot and wantPlayers) then
				fn(model, plr, isBot)
			end
		end
	end
end

run(function()
	local KillAura, Players, Bots, Range, FOV, Rate, Multi, Swing
	local lastHit = 0

	KillAura = larp.Categories.Combat:CreateModule({
		Name = 'KillAura',
		Function = function(callback)
			if not callback then return end
			task.spawn(function()
				while KillAura.Enabled do
					runService.Heartbeat:Wait()
					pcall(function()
						local now = tick()
						if now - lastHit < 1 / Rate.Value then return end
						local me = localChar()
						local eye = eyeOf(me)
						if not eye then return end
						local eyePos = eye.Position
						local camPos = gameCamera.CFrame.Position
						local center = gameCamera.ViewportSize * 0.5
						local picks = {}
						eachTarget(Players.Enabled, Bots.Enabled, function(model)
							if not alive(model) then return end
							local part = hitboxOf(model)
							if not part then return end
							local dist = (part.Position - eyePos).Magnitude
							if dist > Range.Value then return end
							local sp, vis = gameCamera:WorldToViewportPoint(part.Position)
							if not vis then return end
							local fovDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
							if fovDist > FOV.Value then return end
							picks[#picks + 1] = { model = model, part = part, dist = dist, fov = fovDist }
						end)
						if #picks == 0 then return end
						table.sort(picks, function(a, b) return a.dist < b.dist end)
						local function swing(p)
							local dir = (p.part.Position - eyePos)
							if dir.Magnitude > 0 then dir = dir.Unit else dir = gameCamera.CFrame.LookVector end
							local plr = playersService:FindFirstChild(baseName(p.model.Name))
							hitRequest:FireServer(eyePos, dir, p.model, plr)
						end
						if Multi.Enabled then
							for _, p in picks do swing(p) end
						else
							swing(picks[1])
						end
						lastHit = now
					end)
				end
			end)
		end,
		Tooltip = 'Automatically hits nearby targets'
	})
	Players = KillAura:CreateToggle({ Name = 'Players', Default = true })
	Bots = KillAura:CreateToggle({ Name = 'Bots', Default = true })
	Range = KillAura:CreateSlider({ Name = 'Range', Min = 10, Max = 60, Default = 20, Decimal = 10, Suffix = 'studs' })
	FOV = KillAura:CreateSlider({ Name = 'FOV', Min = 40, Max = 1000, Default = 400, Suffix = 'px' })
	Rate = KillAura:CreateSlider({ Name = 'Hits per second', Min = 4, Max = 20, Default = 12 })
	Multi = KillAura:CreateToggle({ Name = 'Hit all in range', Default = false })
	Swing = KillAura:CreateToggle({ Name = 'Swing animation', Default = true })
end)

run(function()
	local TriggerBot, TPlayers, TBots, TReach, TRate
	local lastHit = 0

	TriggerBot = larp.Categories.Combat:CreateModule({
		Name = 'TriggerBot',
		Function = function(callback)
			if not callback then return end
			task.spawn(function()
				while TriggerBot.Enabled do
					runService.Heartbeat:Wait()
					pcall(function()
						local now = tick()
						if now - lastHit < 1 / TRate.Value then return end
						local me = localChar()
						local eye = eyeOf(me)
						local oc = otherChars()
						if not eye or not oc then return end
						local params = RaycastParams.new()
						params.FilterType = Enum.RaycastFilterType.Exclude
						params.FilterDescendantsInstances = { me }
						local look = gameCamera.CFrame.LookVector
						local result = workspace:Raycast(eye.Position, look * TReach.Value, params)
						if not result then return end
						local model = result.Instance and result.Instance.Parent
						if not model or model.Parent ~= oc then return end
						if model.Name == lplr.Name..'_FakeCharacter' then return end
						local plr = playersService:FindFirstChild(baseName(model.Name))
						local isBot = plr == nil
						if (isBot and not TBots.Enabled) or (not isBot and not TPlayers.Enabled) then return end
						if not alive(model) then return end
						hitRequest:FireServer(eye.Position, look.Unit, model, plr)
						lastHit = now
					end)
				end
			end)
		end,
		Tooltip = 'Hits whatever your crosshair is over'
	})
	TPlayers = TriggerBot:CreateToggle({ Name = 'Players', Default = true })
	TBots = TriggerBot:CreateToggle({ Name = 'Bots', Default = true })
	TReach = TriggerBot:CreateSlider({ Name = 'Reach', Min = 10, Max = 40, Default = 16, Decimal = 10, Suffix = 'studs' })
	TRate = TriggerBot:CreateSlider({ Name = 'Hits per second', Min = 4, Max = 20, Default = 12 })
end)

run(function()
	local AutoBlock, blocking

	AutoBlock = larp.Categories.Combat:CreateModule({
		Name = 'AutoBlock',
		Function = function(callback)
			if callback then
				blocking = true
				pcall(function() beginBlock:FireServer() end)
			else
				if blocking then
					blocking = false
					pcall(function() endBlock:FireServer() end)
				end
			end
		end,
		Tooltip = 'Holds a sword block'
	})
end)

run(function()
	local ESP, EPlayers, EBots, Box, Name, Health, Distance, Tracer, BoxColor, TracerColor, TextColor
	local gui, tags

	local function newTag()
		local box = Instance.new('Frame')
		box.BackgroundTransparency = 1
		box.BorderSizePixel = 0
		box.Parent = gui
		local outline = Instance.new('UIStroke')
		outline.Thickness = 1
		outline.Color = Color3.new()
		outline.Parent = box
		local fill = Instance.new('Frame')
		fill.BackgroundTransparency = 1
		fill.BorderSizePixel = 0
		fill.Size = UDim2.fromScale(1, 1)
		fill.Parent = box
		local fillStroke = Instance.new('UIStroke')
		fillStroke.Thickness = 1
		fillStroke.Parent = fill

		local nameL = Instance.new('TextLabel')
		nameL.AutomaticSize = Enum.AutomaticSize.X
		nameL.AnchorPoint = Vector2.new(0.5, 1)
		nameL.BackgroundTransparency = 1
		nameL.Font = Enum.Font.Gotham
		nameL.TextSize = 13
		nameL.TextStrokeTransparency = 0.5
		nameL.Parent = gui

		local distL = Instance.new('TextLabel')
		distL.AutomaticSize = Enum.AutomaticSize.X
		distL.AnchorPoint = Vector2.new(0.5, 0)
		distL.BackgroundTransparency = 1
		distL.Font = Enum.Font.Gotham
		distL.TextSize = 12
		distL.TextStrokeTransparency = 0.5
		distL.Parent = gui

		local healthBG = Instance.new('Frame')
		healthBG.BackgroundColor3 = Color3.new()
		healthBG.BackgroundTransparency = 0.3
		healthBG.BorderSizePixel = 0
		healthBG.AnchorPoint = Vector2.new(1, 1)
		healthBG.Parent = gui
		local healthBar = Instance.new('Frame')
		healthBar.BorderSizePixel = 0
		healthBar.AnchorPoint = Vector2.new(0, 1)
		healthBar.Position = UDim2.fromScale(0, 1)
		healthBar.Parent = healthBG

		local tracerL = Instance.new('Frame')
		tracerL.BorderSizePixel = 0
		tracerL.AnchorPoint = Vector2.new(0.5, 1)
		tracerL.Parent = gui

		return { box = box, outline = outline, fillStroke = fillStroke, name = nameL, dist = distL, healthBG = healthBG, healthBar = healthBar, tracer = tracerL }
	end

	local function corners(part)
		local cf, sz = part.CFrame, part.Size * 0.5
		local pts = {}
		for _, mx in {-1, 1} do
			for _, my in {-1, 1} do
				for _, mz in {-1, 1} do
					local wp = cf:PointToWorldSpace(Vector3.new(sz.X * mx, sz.Y * my, sz.Z * mz))
					pts[#pts + 1] = wp
				end
			end
		end
		return pts
	end

	ESP = larp.Categories.Render:CreateModule({
		Name = 'ESP',
		Function = function(callback)
			if callback then
				gui = Instance.new('ScreenGui')
				gui.Name = 'ArenaESP'
				gui.ResetOnSpawn = false
				gui.IgnoreGuiInset = true
				gui.DisplayOrder = 10
				gui.Parent = gethui and gethui() or cloneref(game:GetService('CoreGui'))
				tags = {}
				task.spawn(function()
					while ESP.Enabled do
						runService.RenderStepped:Wait()
						pcall(function()
							local me = localChar()
							local origin = eyeOf(me)
							local originPos = origin and origin.Position or gameCamera.CFrame.Position
							local seen = {}
							local vp = gameCamera.ViewportSize
							eachTarget(EPlayers.Enabled, EBots.Enabled, function(model, plr)
								local part = hitboxOf(model)
								if not part or not alive(model) then return end
								seen[model] = true
								local tag = tags[model]
								if not tag then tag = newTag(); tags[model] = tag end
								local pts = corners(part)
								local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
								local onScreen = false
								for _, wp in pts do
									local sp, vis = gameCamera:WorldToViewportPoint(wp)
									if vis then onScreen = true end
									if sp.X < minX then minX = sp.X end
									if sp.Y < minY then minY = sp.Y end
									if sp.X > maxX then maxX = sp.X end
									if sp.Y > maxY then maxY = sp.Y end
								end
								if not onScreen then
									tag.box.Visible = false
									tag.name.Visible = false
									tag.dist.Visible = false
									tag.healthBG.Visible = false
									tag.tracer.Visible = false
									return
								end
								local w, h = maxX - minX, maxY - minY
								tag.box.Visible = Box.Enabled
								tag.box.Position = UDim2.fromOffset(minX, minY)
								tag.box.Size = UDim2.fromOffset(w, h)
								tag.outline.Color = BoxColor.Value
								tag.fillStroke.Color = Color3.new()

								tag.name.Visible = Name.Enabled
								tag.name.Text = plr and plr.Name or baseName(model.Name)
								tag.name.TextColor3 = TextColor.Value
								tag.name.Position = UDim2.fromOffset((minX + maxX) * 0.5, minY - 2)

								tag.dist.Visible = Distance.Enabled
								tag.dist.Text = math.floor((part.Position - originPos).Magnitude)..'m'
								tag.dist.TextColor3 = TextColor.Value
								tag.dist.Position = UDim2.fromOffset((minX + maxX) * 0.5, maxY + 2)

								local hum = model:FindFirstChildOfClass('Humanoid')
								tag.healthBG.Visible = Health.Enabled and hum ~= nil
								if hum then
									local ratio = math.clamp(hum.Health / (hum.MaxHealth > 0 and hum.MaxHealth or 100), 0, 1)
									tag.healthBG.Position = UDim2.fromOffset(minX - 4, maxY)
									tag.healthBG.Size = UDim2.fromOffset(3, h)
									tag.healthBar.Size = UDim2.fromScale(1, ratio)
									tag.healthBar.BackgroundColor3 = Color3.fromRGB(255 - math.floor(ratio * 255), math.floor(ratio * 255), 40)
								end

								tag.tracer.Visible = Tracer.Enabled
								tag.tracer.BackgroundColor3 = TracerColor.Value
								local tx, ty = (minX + maxX) * 0.5, maxY
								local ox, oy = vp.X * 0.5, vp.Y
								local dx, dy = tx - ox, ty - oy
								local len = math.sqrt(dx * dx + dy * dy)
								tag.tracer.Position = UDim2.fromOffset(ox, oy)
								tag.tracer.Size = UDim2.fromOffset(2, len)
								tag.tracer.Rotation = math.deg(math.atan2(dy, dx)) - 90
							end)
							for model, tag in tags do
								if not seen[model] then
									tag.box:Destroy(); tag.name:Destroy(); tag.dist:Destroy(); tag.healthBG:Destroy(); tag.tracer:Destroy()
									tags[model] = nil
								end
							end
						end)
					end
					for _, tag in tags do
						pcall(function() tag.box:Destroy(); tag.name:Destroy(); tag.dist:Destroy(); tag.healthBG:Destroy(); tag.tracer:Destroy() end)
					end
					table.clear(tags)
					if gui then gui:Destroy() end
				end)
			end
		end,
		Tooltip = 'Shows players and bots through walls'
	})
	EPlayers = ESP:CreateToggle({ Name = 'Players', Default = true })
	EBots = ESP:CreateToggle({ Name = 'Bots', Default = true })
	Box = ESP:CreateToggle({ Name = 'Box', Default = true })
	Name = ESP:CreateToggle({ Name = 'Name', Default = true })
	Health = ESP:CreateToggle({ Name = 'Health', Default = true })
	Distance = ESP:CreateToggle({ Name = 'Distance', Default = true })
	Tracer = ESP:CreateToggle({ Name = 'Tracers', Default = false })
	BoxColor = ESP:CreateColorSlider({ Name = 'Box color', Default = Color3.fromRGB(255, 255, 255) })
	TracerColor = ESP:CreateColorSlider({ Name = 'Tracer color', Default = Color3.fromRGB(128, 205, 150) })
	TextColor = ESP:CreateColorSlider({ Name = 'Text color', Default = Color3.fromRGB(255, 255, 255) })
end)

run(function()
	local Chams, CPlayers, CBots, ChamColor, WallColor, Fill
	local highlights

	Chams = larp.Categories.Render:CreateModule({
		Name = 'Chams',
		Function = function(callback)
			if callback then
				highlights = {}
				task.spawn(function()
					while Chams.Enabled do
						runService.RenderStepped:Wait()
						pcall(function()
							local seen = {}
							eachTarget(CPlayers.Enabled, CBots.Enabled, function(model)
								if not alive(model) then return end
								seen[model] = true
								local hl = highlights[model]
								if not hl then
									hl = Instance.new('Highlight')
									hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
									hl.Parent = model
									highlights[model] = hl
								end
								hl.Adornee = model
								hl.FillColor = ChamColor.Value
								hl.OutlineColor = WallColor.Value
								hl.FillTransparency = Fill.Value
							end)
							for model, hl in highlights do
								if not seen[model] then hl:Destroy(); highlights[model] = nil end
							end
						end)
					end
					for _, hl in highlights do pcall(function() hl:Destroy() end) end
					table.clear(highlights)
				end)
			end
		end,
		Tooltip = 'Fills targets with a solid color through walls'
	})
	CPlayers = Chams:CreateToggle({ Name = 'Players', Default = true })
	CBots = Chams:CreateToggle({ Name = 'Bots', Default = true })
	ChamColor = Chams:CreateColorSlider({ Name = 'Fill color', Default = Color3.fromRGB(128, 205, 150) })
	WallColor = Chams:CreateColorSlider({ Name = 'Outline color', Default = Color3.fromRGB(255, 255, 255) })
	Fill = Chams:CreateSlider({ Name = 'Fill transparency', Min = 0, Max = 1, Default = 0.5, Decimal = 100 })
end)

run(function()
	local Fullbright, Brightness
	local saved

	Fullbright = larp.Categories.Render:CreateModule({
		Name = 'Fullbright',
		Function = function(callback)
			if callback then
				saved = { b = lighting.Brightness, a = lighting.Ambient, o = lighting.OutdoorAmbient, f = lighting.FogEnd, cs = lighting.ClockTime }
				task.spawn(function()
					while Fullbright.Enabled do
						lighting.Brightness = Brightness.Value
						lighting.Ambient = Color3.fromRGB(178, 178, 178)
						lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
						lighting.FogEnd = 1e6
						runService.RenderStepped:Wait()
					end
				end)
			elseif saved then
				lighting.Brightness = saved.b
				lighting.Ambient = saved.a
				lighting.OutdoorAmbient = saved.o
				lighting.FogEnd = saved.f
			end
		end,
		Tooltip = 'Removes darkness and fog'
	})
	Brightness = Fullbright:CreateSlider({ Name = 'Brightness', Min = 1, Max = 5, Default = 2, Decimal = 10 })
end)

run(function()
	local function blockSlot()
		local inv = inventory()
		if not inv then return nil end
		for i, it in pairs(inv.Inventory) do
			local id = type(it) == 'table' and it.id or it
			if type(id) == 'string' and not NONBLOCK[id] then
				return i, id
			end
		end
		return nil
	end

	local function placeAt(cell, normal, id, slot)
		local inv = inventory()
		if inv and inv.SelectedSlot ~= slot then
			inv.SelectedSlot = slot
			pcall(function() setSlot:FireServer(slot) end)
		end
		return placeBlock:InvokeServer(cell, normal, id)
	end

	local function snap(v)
		return Vector3.new(math.round(v.X / 4) * 4, math.round(v.Y / 4) * 4, math.round(v.Z / 4) * 4)
	end

	local function placeBelow(me)
		local root = hitboxOf(me)
		if not root then return end
		local slot, id = blockSlot()
		if not slot then return end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { me, otherChars() }
		local result = workspace:Raycast(root.Position, Vector3.new(0, -14, 0), params)
		if not result then return end
		local cell = snap(result.Position + result.Normal * 2)
		pcall(placeAt, cell, result.Normal, id, slot)
	end

	local Scaffold
	Scaffold = larp.Categories.World:CreateModule({
		Name = 'Scaffold',
		Function = function(callback)
			if not callback then return end
			task.spawn(function()
				while Scaffold.Enabled do
					runService.Heartbeat:Wait()
					pcall(function()
						local me = localChar()
						if me then placeBelow(me) end
					end)
				end
			end)
		end,
		Tooltip = 'Places blocks under you as you walk'
	})

	local Clutch, FallSpeed, GroundGap
	local lastPos, lastT
	Clutch = larp.Categories.World:CreateModule({
		Name = 'Clutch',
		Function = function(callback)
			if not callback then return end
			lastPos, lastT = nil, nil
			task.spawn(function()
				while Clutch.Enabled do
					runService.Heartbeat:Wait()
					pcall(function()
						local me = localChar()
						local root = hitboxOf(me)
						if not root then return end
						local now = tick()
						local vy = 0
						if lastPos and lastT and now > lastT then
							vy = (root.Position.Y - lastPos.Y) / (now - lastT)
						end
						lastPos, lastT = root.Position, now
						if vy > -FallSpeed.Value then return end
						local params = RaycastParams.new()
						params.FilterType = Enum.RaycastFilterType.Exclude
						params.FilterDescendantsInstances = { me, otherChars() }
						local result = workspace:Raycast(root.Position, Vector3.new(0, -GroundGap.Value, 0), params)
						if result then return end
						placeBelow(me)
					end)
				end
			end)
		end,
		Tooltip = 'Places a block under you when falling over a gap'
	})
	FallSpeed = Clutch:CreateSlider({ Name = 'Trigger fall speed', Min = 5, Max = 60, Default = 20 })
	GroundGap = Clutch:CreateSlider({ Name = 'Ground scan', Min = 8, Max = 60, Default = 24, Suffix = 'studs' })
end)
