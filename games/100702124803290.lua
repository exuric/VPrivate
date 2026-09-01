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
local function downloadFile(path, func)
	if not isfile(path) or (path:find('.lua') and #readfile(path) < 100) or readfile(path):sub(1, #LARPWATER) ~= LARPWATER then
		local suc, res = pcall(function()
			return game:HttpGet((getgenv().LarpReadRoot or 'https://raw.githubusercontent.com/exuric/VPrivate/')..'main/'..select(1, path:gsub('LarpV4/', ''))..'?v='..tick(), true)
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

larp.Place = 100702124803290

local cloneref = cloneref or function(ref) return ref end
local playersService = cloneref(game:GetService('Players'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lighting = cloneref(game:GetService('Lighting'))
local httpService = cloneref(game:GetService('HttpService'))
local lplr = playersService.LocalPlayer
local gameCamera = workspace.CurrentCamera
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))

local MainGameEvent = replicatedStorage.GameRemotes:FindFirstChild('MainGameEvent')
local GameRemoteFunction = replicatedStorage.GameRemotes:FindFirstChild('GameRemoteFunction')
local MainModule = require(replicatedStorage:WaitForChild('MainModule'))

local function notif(text, time, icon)
	if larp and larp.CreateNotification then
		larp:CreateNotification('DaHood', text, time or 5, icon or 'info')
	end
end

local function getChar(plr)
	if not plr then return nil end
	local c = workspace.Players:FindFirstChild(plr.Name)
	if c and c:FindFirstChild('HumanoidRootPart') then
		return c
	end
	if plr.Character and plr.Character:FindFirstChild('HumanoidRootPart') then
		return plr.Character
	end
	return nil
end

local function getBodyEffects(char)
	return char and char:FindFirstChild('BodyEffects') or nil
end

local function getHealth(ent)
	local hum = ent.Character and ent.Character:FindFirstChildOfClass('Humanoid')
	return hum and hum.Health or 0
end

local function getArmor(ent)
	local be = getBodyEffects(ent.Character)
	return be and be:FindFirstChild('Armor') and be.Armor.Value or 0
end

local function isDead(ent)
	local be = getBodyEffects(ent.Character)
	return be and be:FindFirstChild('Dead') and be.Dead.Value or false
end

local function isKO(ent)
	local be = getBodyEffects(ent.Character)
	return be and be:FindFirstChild('K.O') and be['K.O'].Value or false
end

local function isGrabbed(ent)
	local be = getBodyEffects(ent.Character)
	return be and be:FindFirstChild('Grabbed') and be.Grabbed.Value ~= nil or false
end

local function isCuffed(ent)
	local be = getBodyEffects(ent.Character)
	return be and be:FindFirstChild('Cuff') and be.Cuff.Value or false
end

local function isPolice(ent)
	return ent.Player and ent.Player:GetAttribute('Police') == true or false
end

local function getTeamName(ent)
	if ent.Player then
		if isPolice(ent) then return 'Police' end
		if ent.Player:GetAttribute('Gang') then return tostring(ent.Player:GetAttribute('Gang')) end
	end
	return 'None'
end

local function isVulnerable(ent)
	return ent.Character ~= nil
		and ent.RootPart ~= nil
		and ent.Humanoid ~= nil
		and ent.Humanoid.Health > 0
		and not isDead(ent)
		and not isKO(ent)
end

local function getMousePosition()
	return inputService:GetMouseLocation()
end

local function raycast(origin, direction, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore or {lplr.Character}
	params.IgnoreWater = true
	return workspace:Raycast(origin, direction, params)
end

local function isVisible(origin, target)
	local dir = target - origin
	local result = raycast(origin, dir, {lplr.Character})
	return not result or (result.Position - target).Magnitude < 2
end

local function getThreat(ent)
	local score = 0
	local be = getBodyEffects(ent.Character)
	if be then
		local defense = be:FindFirstChild('Defense')
		if defense then score = score + defense.Value end
	end
	score = score + getArmor(ent) * 0.5
	local ok, inv = pcall(function()
		local info = ent.Player and ent.Player:FindFirstChild('DataFolder') and ent.Player.DataFolder:FindFirstChild('Information')
		return info and info:FindFirstChild('Money') or nil
	end)
	return score
end

local entitylib = {
	isAlive = false,
	character = nil,
	List = {},
	Connections = {},
	EntityThreads = {},
	Events = setmetatable({}, {
		__index = function(self, ind)
			self[ind] = {Connections = {}, Connect = function(rself, func) table.insert(rself.Connections, func) return {Disconnect = function() local i = table.find(rself.Connections, func) if i then table.remove(rself.Connections, i) end end} end, Fire = function(rself, ...) for _, v in rself.Connections do task.spawn(v, ...) end end, Destroy = function(rself) table.clear(rself.Connections) table.clear(rself) end}
			return self[ind]
		end
	})
}

local function waitForChildOfType(obj, name, timeout)
	local checktick = tick() + timeout
	local returned
	repeat
		returned = obj:FindFirstChildOfClass(name)
		if returned or checktick < tick() then break end
		task.wait()
	until false
	return returned
end

local function addEntity(char, plr)
	if not char then return end
	entitylib.EntityThreads[char] = task.spawn(function()
		local hum = waitForChildOfType(char, 'Humanoid', 10)
		local humrootpart = hum and waitForChildOfType(hum, 'RootPart', 10, true)
		local head = char:WaitForChild('Head', 10) or humrootpart
		if hum and humrootpart then
			local entity = {
				Character = char,
				Health = hum.Health,
				MaxHealth = hum.MaxHealth,
				Head = head,
				Humanoid = hum,
				HumanoidRootPart = humrootpart,
				RootPart = humrootpart,
				Player = plr,
				NPC = plr == nil
			}
			entitylib.List[#entitylib.List + 1] = entity
			if plr == lplr then
				entitylib.character = entity
				entitylib.isAlive = true
				entitylib.Events.LocalAdded:Fire(entity)
			else
				entitylib.Events.EntityAdded:Fire(entity)
			end
			local conns = {
				hum:GetPropertyChangedSignal('Health'):Connect(function()
					entity.Health = hum.Health
					entitylib.Events.EntityUpdated:Fire(entity)
				end),
				hum:GetPropertyChangedSignal('MaxHealth'):Connect(function()
					entity.MaxHealth = hum.MaxHealth
					entitylib.Events.EntityUpdated:Fire(entity)
				end)
			}
			entity.Connections = conns
		end
		entitylib.EntityThreads[char] = nil
	end)
end

local function removeEntity(char, isLocal)
	if not char then return end
	if entitylib.EntityThreads[char] then
		task.cancel(entitylib.EntityThreads[char])
		entitylib.EntityThreads[char] = nil
	end
	for index, entity in ipairs(entitylib.List) do
		if entity.Character == char then
			for _, v in entity.Connections do
				v:Disconnect()
			end
			table.remove(entitylib.List, index)
			if isLocal then
				entitylib.isAlive = false
				entitylib.character = nil
				entitylib.Events.LocalRemoved:Fire()
			else
				entitylib.Events.EntityRemoved:Fire(entity)
			end
			return
		end
	end
end

entitylib.getEntity = function(char)
	for _, entity in entitylib.List do
		if entity.Character == char or (char and entity.Player and entity.Player.Name == char) then
			return entity
		end
	end
	return nil
end

local function addPlayer(plr)
	plr.CharacterAdded:Connect(function(char)
		if plr == lplr then
			for _, ent in entitylib.List do
				if ent.Player == lplr then
					removeEntity(ent.Character, true)
				end
			end
		end
		addEntity(char, plr)
	end)
	if plr.Character then
		addEntity(plr.Character, plr)
	end
end

entitylib.start = function()
	entitylib.Connections = {
		playersService.PlayerAdded:Connect(addPlayer),
		playersService.PlayerRemoving:Connect(function(plr)
			for _, ent in entitylib.List do
				if ent.Player == plr then
					removeEntity(ent.Character)
				end
			end
		end),
		workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
			gameCamera = workspace.CurrentCamera
		end)
	}
	for _, plr in playersService:GetPlayers() do
		addPlayer(plr)
	end
	workspace.Players.DescendantAdded:Connect(function(inst)
		if inst:IsA('Model') and inst:FindFirstChildOfClass('Humanoid') and inst:FindFirstChild('HumanoidRootPart') and not playersService:GetPlayerFromCharacter(inst) then
			addEntity(inst, nil)
		end
	end)
	entitylib.Running = true
end

entitylib.start()

local function findTargets(settings)
	if not entitylib.isAlive then return {} end
	local origin = settings.Origin or entitylib.character.RootPart.Position
	local part = settings.Part or 'Head'
	local results = {}
	for _, ent in entitylib.List do
		if ent == entitylib.character then continue end
		if not isVulnerable(ent) then
			if settings.Checks and settings.Checks.Dead then continue end
		end
		if settings.Checks and settings.Checks.Team and ent.Player then
			if getTeamName(ent) == getTeamName(entitylib.character) then continue end
		end
		if settings.Checks and settings.Checks.Police and isPolice(ent) then continue end
		local partInstance = ent.Character and ent.Character:FindFirstChild(part) or ent.RootPart
		if not partInstance then continue end
		local mag = (partInstance.Position - origin).Magnitude
		if settings.MaxDistance and mag > settings.MaxDistance then continue end
		if settings.Checks and settings.Checks.Visible and not isVisible(origin, partInstance.Position) then continue end
		if settings.Checks and settings.Checks.Wall and entitylib.Wallcheck and entitylib.Wallcheck(origin, partInstance.Position) then continue end
		table.insert(results, {ent = ent, part = partInstance, mag = mag})
	end
	table.sort(results, function(a, b) return a.mag < b.mag end)
	return results
end

entitylib.Wallcheck = function(origin, position)
	local result = raycast(origin, position - origin, {lplr.Character})
	return result ~= nil
end

getgenv().dahood = {
	entitylib = entitylib,
	isVulnerable = isVulnerable,
	getHealth = getHealth,
	getArmor = getArmor,
	isDead = isDead,
	isKO = isKO,
	isGrabbed = isGrabbed,
	isCuffed = isCuffed,
	isPolice = isPolice,
	getTeamName = getTeamName,
	getThreat = getThreat,
	isVisible = isVisible,
	MainGameEvent = MainGameEvent,
	GameRemoteFunction = GameRemoteFunction,
	MainModule = MainModule,
	getChar = getChar,
	getBodyEffects = getBodyEffects,
	findTargets = findTargets,
	notif = notif
}
local store = {
	hand = {},
	ping = {total = 0},
	lastHit = 0
}
getgenv().store = store
local function smoothLerp(a, b, t)
	return a + (b - a) * t
end

local function smoothAngle(current, target, smoothness, mode)
	if mode == 'Linear' then
		return current:Lerp(target, math.min(smoothness, 1))
	elseif mode == 'Exponential' then
		local alpha = 1 - math.exp(-smoothness * 2)
		return current:Lerp(target, math.min(alpha, 1))
	else -- Adaptive
		local alpha = math.min(smoothness * 2, 1)
		return current:Lerp(target, alpha)
	end
end

local function aimAt(origin, target, smoothness, mode, distance, adaptive, distSmooth, maxDist)
	local desired = CFrame.lookAt(origin, target)
	local current = gameCamera.CFrame
	local actualSmooth = smoothness
	if adaptive and distSmooth and maxDist and maxDist > 0 then
		local distFactor = math.clamp(1 - (distance / maxDist), 0.15, 1)
		actualSmooth = smoothness * distFactor
	end
	return smoothAngle(current, desired, actualSmooth, mode)
end

local function partOf(ent, part)
	if part == 'Head' then return ent.Character and ent.Character:FindFirstChild('Head') or ent.Head end
	if part == 'Torso' then return ent.Character and (ent.Character:FindFirstChild('Torso') or ent.Character:FindFirstChild('UpperTorso') or ent.Character:FindFirstChild('HumanoidRootPart')) or ent.RootPart end
	return ent.RootPart
end
run(function()
	local AimAssist
	local Enabled
	local AimPart
	local FOV
	local FOVShape
	local Smoothness
	local SmoothType
	local MaxDistance
	local TargetPriority
	local LockTarget
	local StickyAim
	local SwitchDelay
	local VisibleOnly
	local TeamCheck
	local KnockedCheck
	local DeadCheck
	local DistanceCheck
	local WallCheck
	local VehicleCheck
	local Prediction
	local PredictionStrength
	local MovementComp
	local AdaptiveSmoothing
	local DistSmoothing
	local TargetStability
	local ReacqDelay
	local TargetHysteresis
	local FOVDynamic
	local TargetInfo

	local currentTarget = nil
	local currentTargetTime = 0
	local lastSwitchTime = 0
	local switchLocked = nil

	local function pickPriority(targets, priority)
		if priority == 'Closest' then
			table.sort(targets, function(a, b) return a.mag < b.mag end)
			return targets[1]
		elseif priority == 'Lowest HP' then
			local best
			for _, t in targets do
				if not best or getHealth(t.ent) < getHealth(best.ent) then
					best = t
				end
			end
			return best
		elseif priority == 'Crosshair' then
			local best, bestDist
			local camCF = gameCamera.CFrame
			for _, t in targets do
				local pos = gameCamera:WorldToViewportPoint(t.part.Position)
				local dist = (Vector2.new(pos.X, pos.Y) - getMousePosition()).Magnitude
				if not bestDist or dist < bestDist then
					best, bestDist = t, dist
				end
			end
			return best
		elseif priority == 'Threat' then
			local best
			for _, t in targets do
				if not best or getThreat(t.ent) > getThreat(best.ent) then
					best = t
				end
			end
			return best
		end
		return targets[1]
	end

	local function getTarget()
		local origin = entitylib.isAlive and entitylib.character.RootPart.Position or Vector3.zero
		local checkVisible = VisibleOnly.Enabled or WallCheck.Enabled
		local candidates = findTargets({
			Origin = origin,
			Part = AimPart.Value == 'Closest' and 'HumanoidRootPart' or (AimPart.Value == 'Head' and 'Head' or 'UpperTorso'),
			MaxDistance = MaxDistance.Value,
			Checks = {
				Dead = DeadCheck.Enabled,
				Team = TeamCheck.Enabled,
				Visible = checkVisible,
				Wall = WallCheck.Enabled
			}
		})
		if #candidates == 0 then
			if currentTarget and StickyAim.Enabled then
				if currentTarget.ent and currentTarget.ent.RootPart and tick() - currentTargetTime < 0.5 then
					local part = currentTarget.part or currentTarget.ent.RootPart
					if part and part.Parent then
						return currentTarget
					end
				end
			end
			currentTarget = nil
			return nil
		end

		local target = pickPriority(candidates, TargetPriority.Value)

		if LockTarget.Enabled and currentTarget then
			local locked = currentTarget
			if locked.ent and locked.ent.RootPart and locked.ent.RootPart.Parent and locked.mag <= MaxDistance.Value then
				if not (StickyAim.Enabled and tick() - currentTargetTime > 3) then
					target = locked
				end
			end
		end

		if currentTarget and currentTarget.ent ~= target.ent then
			if tick() - lastSwitchTime < SwitchDelay.Value then
				target = currentTarget
			elseif TargetHysteresis.Value > 0 and target.mag > currentTarget.mag * (1 - TargetHysteresis.Value) then
				target = currentTarget
			else
				lastSwitchTime = tick()
			end
		end

		if TargetStability.Value > 0 and currentTarget and currentTarget.ent == target.ent then
			currentTargetTime = tick()
		end
		currentTarget = target
		currentTargetTime = tick()
		return target
	end

	local function targetScreenPos(ent, part)
		local p = part or ent.RootPart
		if not p then return nil end
		local pos, vis = gameCamera:WorldToViewportPoint(p.Position)
		if not vis then return nil end
		return Vector2.new(pos.X, pos.Y)
	end

	AimAssist = larp.Categories.Combat:CreateModule({
		Name = 'Aim Assist',
		Function = function(callback)
			if callback then
				local lastTarget = nil
				repeat
					local dt = runService.RenderStepped:Wait()
					if entitylib.isAlive then
						local target = getTarget()
						if target then
							local part = partOf(target.ent, AimPart.Value == 'Closest' and 'Torso' or AimPart.Value)
							if part then
								local dist = target.mag
								local speed = Smoothness.Value
								local targetPos = part.Position
								if Prediction.Enabled and target.ent.RootPart then
									local vel = target.ent.RootPart.Velocity or Vector3.zero
									local travel = dist / 2000
									targetPos = targetPos + vel * travel * PredictionStrength.Value
								end
								local newCF = aimAt(gameCamera.CFrame.Position, targetPos, speed, SmoothType.Value, dist, AdaptiveSmoothing.Enabled, DistSmoothing.Enabled, MaxDistance.Value)
								gameCamera.CFrame = newCF
								if MovementComp.Enabled and entitylib.character and entitylib.character.RootPart then
									local move = entitylib.character.RootPart.Velocity * dt * 2
									gameCamera.CFrame = gameCamera.CFrame * CFrame.new(-move.X, 0, -move.Z)
								end
								if TargetInfo.Enabled and larp and larp.Libraries and larp.Libraries.targetinfo then
									larp.Libraries.targetinfo.Targets[target.ent.Player or target.ent] = tick() + 1
								end
								lastTarget = target
							end
						end
					end
				until not AimAssist.Enabled
			end
		end,
		Tooltip = 'Smoothly aims your camera at targets'
	})
	Enabled = AimAssist:CreateToggle({Name = 'Enabled', Default = true, Darker = true})
	AimPart = AimAssist:CreateDropdown({Name = 'Aim Part', List = {'Head', 'Torso', 'Closest'}, Default = 'Head'})
	FOV = AimAssist:CreateSlider({Name = 'Aim FOV', Min = 1, Max = 360, Default = 15, Decimal = 10, Suffix = function(val) return val == 1 and 'deg' or 'deg' end})
	FOVShape = AimAssist:CreateDropdown({Name = 'FOV Shape', List = {'Circle', 'Dynamic'}, Default = 'Circle'})
	Smoothness = AimAssist:CreateSlider({Name = 'Smoothness', Min = 1, Max = 100, Default = 15, Decimal = 10, Suffix = '%'})
	SmoothType = AimAssist:CreateDropdown({Name = 'Smoothing Type', List = {'Linear', 'Exponential', 'Adaptive'}, Default = 'Adaptive'})
	MaxDistance = AimAssist:CreateSlider({Name = 'Max Distance', Min = 10, Max = 1000, Default = 200, Suffix = function(val) return val == 1 and 'stud' or 'studs' end})
	TargetPriority = AimAssist:CreateDropdown({Name = 'Target Priority', List = {'Closest', 'Lowest HP', 'Crosshair', 'Threat'}, Default = 'Closest'})
	LockTarget = AimAssist:CreateToggle({Name = 'Lock Target', Default = true})
	StickyAim = AimAssist:CreateToggle({Name = 'Sticky Aim', Default = true, Tooltip = 'Keeps the current target for a short time after losing it'})
	SwitchDelay = AimAssist:CreateSlider({Name = 'Target Switch Delay', Min = 0, Max = 2, Default = 0.1, Decimal = 100, Suffix = 'seconds'})
	TargetInfo = AimAssist:CreateToggle({Name = 'Target Info', Default = true, Tooltip = 'Highlights the current target in the target info overlay'})

	
	VisibleOnly = AimAssist:CreateToggle({Name = 'Visible Only', Default = true})
	TeamCheck = AimAssist:CreateToggle({Name = 'Team Check', Default = true, Tooltip = 'Ignores players on your team'})
	KnockedCheck = AimAssist:CreateToggle({Name = 'Knocked Check', Default = true, Tooltip = 'Ignores knocked players'})
	DeadCheck = AimAssist:CreateToggle({Name = 'Dead Check', Default = true})
	DistanceCheck = AimAssist:CreateToggle({Name = 'Distance Check', Default = true})
	WallCheck = AimAssist:CreateToggle({Name = 'Wall Check', Default = false})
	VehicleCheck = AimAssist:CreateToggle({Name = 'Vehicle Check', Default = false, Tooltip = 'Ignores players in vehicles'})

	
	Prediction = AimAssist:CreateToggle({Name = 'Prediction', Default = false})
	PredictionStrength = AimAssist:CreateSlider({Name = 'Prediction Strength', Min = 0, Max = 100, Default = 50, Decimal = 10, Suffix = '%'})
	MovementComp = AimAssist:CreateToggle({Name = 'Movement Compensation', Default = false})
	AdaptiveSmoothing = AimAssist:CreateToggle({Name = 'Adaptive Smoothing', Default = true})
	DistSmoothing = AimAssist:CreateToggle({Name = 'Distance-Based Smoothing', Default = true})
	TargetStability = AimAssist:CreateSlider({Name = 'Target Stability', Min = 0, Max = 5, Default = 0.8, Decimal = 100, Suffix = 'seconds', Tooltip = 'Time a target stays locked before switching is allowed'})
	ReacqDelay = AimAssist:CreateSlider({Name = 'Reacquisition Delay', Min = 0, Max = 2, Default = 0.2, Decimal = 100, Suffix = 'seconds'})
	TargetHysteresis = AimAssist:CreateSlider({Name = 'Target Hysteresis', Min = 0, Max = 100, Default = 10, Decimal = 10, Suffix = '%', Tooltip = 'New target must be this much better to switch'})
	FOVDynamic = AimAssist:CreateToggle({Name = 'FOV Dynamic Scaling', Default = true, Tooltip = 'Scales effective FOV with distance'})
end)
local function requireGunHandler()
	local ok, mod = pcall(function()
		return require(replicatedStorage.Modules.GunHandler)
	end)
	if ok and mod and mod.GetAim then
		return mod
	end
	for _, v in getgc(true) do
		if type(v) == 'table' and rawget(v, 'GetAim') and rawget(v, 'GetCanShoot') then
			return v
		end
	end
	return nil
end

local function getTargetPart(ent, partName)
	if not ent or not ent.Character then return nil end
	if partName == 'Head' then return ent.Character:FindFirstChild('Head') or ent.Head end
	if partName == 'Torso' then return ent.Character:FindFirstChild('Torso') or ent.Character:FindFirstChild('UpperTorso') or ent.Character:FindFirstChild('HumanoidRootPart') or ent.RootPart end
	if partName == 'Root' then return ent.Character:FindFirstChild('HumanoidRootPart') or ent.RootPart end
	local part = ent.Character:FindFirstChild(partName)
	return part or ent.RootPart
end

local targetEngine = {
	current = nil,
	currentTime = 0,
	lastSwitch = 0,
	sessionTargets = {},
	cycleIndex = 0
}

function targetEngine.valid(ent)
	return ent ~= nil and ent.Character ~= nil and ent.RootPart ~= nil and ent.Character.Parent ~= nil and isVulnerable(ent)
end

function targetEngine.pick(settings)
	local origin = settings.Origin or (entitylib.isAlive and entitylib.character.RootPart.Position or Vector3.zero)
	local part = settings.Part or 'Head'
	local candidates = findTargets({
		Origin = origin,
		Part = part,
		MaxDistance = settings.MaxDistance,
		Checks = {
			Dead = settings.DeadCheck,
			Team = settings.TeamCheck,
			Visible = settings.VisibleCheck,
			Wall = settings.WallCheck
		}
	})
	if #candidates == 0 then
		if settings.Sticky and targetEngine.current and targetEngine.valid(targetEngine.current.ent) and tick() - targetEngine.currentTime < (settings.StickyTime or 0.3) then
			return targetEngine.current
		end
		targetEngine.current = nil
		return nil
	end
	local prio = settings.Priority or 'Closest'
	local target
	if prio == 'Closest' then
		target = candidates[1]
	elseif prio == 'Lowest HP' then
		local best
		for _, t in candidates do
			if not best or getHealth(t.ent) < getHealth(best.ent) then
				best = t
			end
		end
		target = best
	elseif prio == 'Crosshair' then
		local best, bestDist
		local mouse = getMousePosition()
		for _, t in candidates do
			local pos = gameCamera:WorldToViewportPoint(t.part.Position)
			local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
			if not bestDist or d < bestDist then
				best, bestDist = t, d
			end
		end
		target = best
	elseif prio == 'Threat' then
		local best
		for _, t in candidates do
			if not best or getThreat(t.ent) > getThreat(best.ent) then
				best = t
			end
		end
		target = best
	end
	if settings.Lock and targetEngine.current and targetEngine.valid(targetEngine.current.ent) then
		local locked = targetEngine.current
		if locked.mag <= settings.MaxDistance and not (settings.LockTime and tick() - targetEngine.currentTime > settings.LockTime) then
			target = locked
		end
	end
	if targetEngine.current and targetEngine.current.ent ~= target.ent then
		if tick() - targetEngine.lastSwitch < (settings.SwitchDelay or 0) then
			target = targetEngine.current
		else
			targetEngine.lastSwitch = tick()
		end
	end
	targetEngine.current = target
	targetEngine.currentTime = tick()
	return target
end

function targetEngine.clear()
	targetEngine.current = nil
	targetEngine.currentTime = 0
	targetEngine.lastSwitch = 0
end
run(function()
	local SilentAim
	local SAEnabled
	local SAPart
	local SAFOV
	local SAMaxDistance
	local SAPriority
	local SAPrediction
	local SAPredStrength
	local SAVisible
	local SATeam
	local SAKnocked
	local SATargetLock
	local SATargetSwitch
	local SASwitchDelay
	local SAFOVIndicator
	local SATargetIndicator
	local oldGetAim
	local oldShoot

	local function getSilentTarget()
		if not entitylib.isAlive then return nil end
		local target = targetEngine.pick({
			Origin = entitylib.character.RootPart.Position,
			Part = SAPart.Value == 'Head' and 'Head' or (SAPart.Value == 'Torso' and 'Torso' or 'HumanoidRootPart'),
			MaxDistance = SAMaxDistance.Value,
			Priority = SAPriority.Value,
			DeadCheck = SAKnocked.Enabled,
			TeamCheck = SATeam.Enabled,
			VisibleCheck = SAVisible.Enabled,
			Lock = SATargetLock.Enabled,
			SwitchDelay = SASwitchDelay.Value
		})
		if not target then return nil end
		if SAFOV.Value < 180 then
			local pos = gameCamera:WorldToViewportPoint(target.part.Position)
			local mouse = getMousePosition()
			local screenDist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
			local fovRadius = SAFOV.Value * 0.3 + 10
			if screenDist > fovRadius then return nil end
		end
		return target
	end

	SilentAim = larp.Categories.Combat:CreateModule({
		Name = 'Silent Aim',
		Function = function(callback)
			if callback then
				local gunHandler = requireGunHandler()
				if not gunHandler then
					notif('Failed to find GunHandler', 5, 'alert')
					SilentAim:Toggle()
					return
				end
				oldGetAim = gunHandler.GetAim
				gunHandler.GetAim = function(origin)
					local target = getSilentTarget()
					if target and target.part then
						local aimPos = target.part.Position
						if SAPrediction.Enabled then
							local vel = target.ent.RootPart and target.ent.RootPart.Velocity or Vector3.zero
							local dist = (aimPos - origin).Magnitude
							aimPos = aimPos + vel * (dist / 2000) * SAPredStrength.Value
						end
						return (aimPos - origin).Unit, (aimPos - origin).Magnitude
					end
					return oldGetAim(origin)
				end
				oldShoot = gunHandler.Shoot
				gunHandler.Shoot = function(params)
					local target = getSilentTarget()
					if target and target.part then
						local aimPos = target.part.Position
						if SAPrediction.Enabled then
							local vel = target.ent.RootPart and target.ent.RootPart.Velocity or Vector3.zero
							local origin = params and params.ForcedOrigin or aimPos
							local dist = (aimPos - origin).Magnitude
							aimPos = aimPos + vel * (dist / 2000) * SAPredStrength.Value
						end
						params = params or {}
						params.AimPosition = aimPos
						params.AimTarget = target.ent
					end
					return oldShoot(params)
				end
			else
				if oldGetAim then
					local gh = requireGunHandler()
					if gh then gh.GetAim = oldGetAim end
				end
				oldGetAim = nil
				oldShoot = nil
				targetEngine.clear()
			end
		end,
		Tooltip = 'Silently redirects your bullets to the target'
	})
	SAEnabled = SilentAim:CreateToggle({Name = 'Enabled', Default = true, Darker = true})
	SAPart = SilentAim:CreateDropdown({Name = 'Aim Part', List = {'Head', 'Torso', 'Root'}, Default = 'Head'})
	SAFOV = SilentAim:CreateSlider({Name = 'FOV', Min = 1, Max = 360, Default = 360, Decimal = 10, Suffix = function(val) return val == 1 and 'deg' or 'deg' end})
	SAMaxDistance = SilentAim:CreateSlider({Name = 'Max Distance', Min = 10, Max = 1000, Default = 300, Suffix = function(val) return val == 1 and 'stud' or 'studs' end})
	SAPriority = SilentAim:CreateDropdown({Name = 'Target Priority', List = {'Closest', 'Lowest HP', 'Crosshair', 'Threat'}, Default = 'Closest'})
	SAPrediction = SilentAim:CreateToggle({Name = 'Prediction', Default = true})
	SAPredStrength = SilentAim:CreateSlider({Name = 'Prediction Strength', Min = 0, Max = 100, Default = 60, Decimal = 10, Suffix = '%'})
	SAVisible = SilentAim:CreateToggle({Name = 'Visibility Check', Default = true})
	SATeam = SilentAim:CreateToggle({Name = 'Team Check', Default = true})
	SAKnocked = SilentAim:CreateToggle({Name = 'Knocked Check', Default = true})
	SATargetLock = SilentAim:CreateToggle({Name = 'Target Lock', Default = true})
	SATargetSwitch = SilentAim:CreateToggle({Name = 'Target Switch', Default = true})
	SASwitchDelay = SilentAim:CreateSlider({Name = 'Target Switch Delay', Min = 0, Max = 2, Default = 0.1, Decimal = 100, Suffix = 'seconds'})
	SAFOVIndicator = SilentAim:CreateToggle({Name = 'FOV Indicator', Default = true, Function = function(callback)
		if FOVCircle and FOVCircle.Object then
			FOVCircle.Object.Visible = callback
		end
	end})
	SATargetIndicator = SilentAim:CreateToggle({Name = 'Target Indicator', Default = true, Function = function(callback)
		if TargetIndicator and TargetIndicator.Object then
			TargetIndicator.Object.Visible = callback
		end
	end})
end)
run(function()
	local Hitboxes
	local HBEnabled
	local HBPart
	local HBSize
	local HBWidth
	local HBHeight
	local HBDepth
	local HBMaxDistance
	local HBFilter
	local HBTeamCheck
	local HBKnockedCheck
	local HBVisibleOnly
	local HBDynamicSize
	local HBDistScaling
	local HBPriority
	local HBPrediction
	local HBAutoPrediction
	local HBResolver
	local HBTargetSwitch
	local HBMultiTarget
	local HBAimFOV

	local expandedParts = {}

	local function applyHitboxes(ent)
		if not ent or not ent.Character then return end
		local targetPart = getTargetPart(ent, HBPart.Value == 'Head' and 'Head' or HBPart.Value == 'Torso' and 'Torso' or 'HumanoidRootPart')
		if not targetPart then return end
		local size = HBSize.Value
		local base = targetPart.Size
		local newSize = Vector3.new(base.X * (1 + HBWidth.Value / 100), base.Y * (1 + HBHeight.Value / 100), base.Z * (1 + HBDepth.Value / 100))
		if HBDynamicSize.Enabled then
			local dist = entitylib.isAlive and (targetPart.Position - entitylib.character.RootPart.Position).Magnitude or 0
			local scale = 1 + (dist / HBMaxDistance.Value) * (HBDistScaling.Value / 100)
			newSize = newSize * scale
		end
		if not expandedParts[targetPart] then
			expandedParts[targetPart] = {orig = base, conn = targetPart:GetPropertyChangedSignal('Size'):Connect(function() end)}
		end
		targetPart.Size = newSize
	end

	local function clearHitboxes()
		for part, data in expandedParts do
			if part and part.Parent then
				part.Size = data.orig
			end
			if data.conn then data.conn:Disconnect() end
		end
		table.clear(expandedParts)
	end

	Hitboxes = larp.Categories.Combat:CreateModule({
		Name = 'Hitbox',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					if not entitylib.isAlive then continue end
					if HBDynamicSize.Enabled then
						for _, ent in entitylib.List do
							if ent == entitylib.character then continue end
							if isVulnerable(ent) then
								applyHitboxes(ent)
							end
						end
					end
				until not Hitboxes.Enabled
				clearHitboxes()
			else
				clearHitboxes()
			end
		end,
		Tooltip = 'Expands enemy hitboxes to make landing shots easier'
	})
	HBEnabled = Hitboxes:CreateToggle({Name = 'Enabled', Default = true, Darker = true})
	HBPart = Hitboxes:CreateDropdown({Name = 'Hitbox Part', List = {'Head', 'Torso', 'Root'}, Default = 'Head'})
	HBSize = Hitboxes:CreateSlider({Name = 'Size', Min = 0, Max = 500, Default = 100, Decimal = 10, Suffix = '%'})
	HBWidth = Hitboxes:CreateSlider({Name = 'Width', Min = -50, Max = 200, Default = 50, Decimal = 10, Suffix = '%'})
	HBHeight = Hitboxes:CreateSlider({Name = 'Height', Min = -50, Max = 200, Default = 50, Decimal = 10, Suffix = '%'})
	HBDepth = Hitboxes:CreateSlider({Name = 'Depth', Min = -50, Max = 200, Default = 50, Decimal = 10, Suffix = '%'})
	HBMaxDistance = Hitboxes:CreateSlider({Name = 'Max Distance', Min = 10, Max = 1000, Default = 300, Suffix = function(val) return val == 1 and 'stud' or 'studs' end})
	HBFilter = Hitboxes:CreateTargets({Players = true, NPCs = true})
	HBTeamCheck = Hitboxes:CreateToggle({Name = 'Team Check', Default = true})
	HBKnockedCheck = Hitboxes:CreateToggle({Name = 'Knocked Check', Default = true})
	HBVisibleOnly = Hitboxes:CreateToggle({Name = 'Visible Only', Default = false})
	HBDynamicSize = Hitboxes:CreateToggle({Name = 'Dynamic Size', Default = false})
	HBDistScaling = Hitboxes:CreateSlider({Name = 'Distance Scaling', Min = 0, Max = 100, Default = 30, Decimal = 10, Suffix = '%'})
	HBPriority = Hitboxes:CreateDropdown({Name = 'Hitbox Priority', List = {'Closest', 'Lowest HP', 'Threat'}, Default = 'Closest'})
	HBPrediction = Hitboxes:CreateToggle({Name = 'Prediction', Default = false})
	HBAutoPrediction = Hitboxes:CreateToggle({Name = 'Auto Prediction', Default = false})
	HBResolver = Hitboxes:CreateToggle({Name = 'Resolver', Default = false})
	HBTargetSwitch = Hitboxes:CreateToggle({Name = 'Target Switch', Default = false})
	HBMultiTarget = Hitboxes:CreateToggle({Name = 'Multi Target', Default = false})
	HBAimFOV = Hitboxes:CreateSlider({Name = 'Aim FOV', Min = 1, Max = 360, Default = 360, Decimal = 10})
end)
local function getLocalRoot()
	if not entitylib.isAlive or not entitylib.character then return nil end
	return entitylib.character.RootPart
end

local function getLocalHumanoid()
	if not entitylib.isAlive or not entitylib.character then return nil end
	return entitylib.character.Humanoid
end

local movementModifiers = {}

local function applyMovement()
	local hum = getLocalHumanoid()
	if not hum then return end
	local speed = 16
	local jump = 50
	if movementModifiers.WalkSpeed then speed = movementModifiers.WalkSpeed end
	if movementModifiers.JumpPower then jump = movementModifiers.JumpPower end
	if hum.WalkSpeed ~= speed then hum.WalkSpeed = speed end
	if hum.JumpPower ~= jump then hum.JumpPower = jump end
end

run(function()
	local Fly
	local FlySpeed
	local NoclipMod
	local NoClipValue
	local InfiniteJump
	local BunnyHop
	local AirWalk
	local NoSlow
	local NoStun
	local NoKnockback
	local VelocityMod
	local VelocityValue
	local GravityMod
	local GravityValue
	local LongJump
	local LongJumpPower
	local WalkSpeedOverride
	local WalkSpeedValue
	local JumpPowerOverride
	local JumpPowerValue
	local FOVOverride
	local FOVValue
	local CameraUnlock
	local Fullbright
	local AntiAFK
	local freecamObj
	local spinConn

	local function setVelocity(v)
		local root = getLocalRoot()
		if root then
			pcall(function() root.Velocity = v end)
		end
	end

	local function setGravity(g)
		local hum = getLocalHumanoid()
		if hum then
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingNoCollision, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		end
		game.workspace.Gravity = g
	end

	Fly = larp.Categories.Blatant:CreateModule({
		Name = 'Fly',
		Function = function(callback)
			if callback then
				repeat
					local dt = runService.RenderStepped:Wait()
					local root = getLocalRoot()
					if not root then continue end
					local hum = getLocalHumanoid()
					if hum then
						hum:SetStateEnabled(Enum.HumanoidStateType.FallingNoCollision, true)
						hum:ChangeState(Enum.HumanoidStateType.Flying)
						hum:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
					end
					local vel = Vector3.zero
					if inputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + gameCamera.CFrame.LookVector end
					if inputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - gameCamera.CFrame.LookVector end
					if inputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - gameCamera.CFrame.RightVector end
					if inputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + gameCamera.CFrame.RightVector end
					local speed = FlySpeed.Value
					if inputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2 end
					if inputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, 1, 0) end
					if inputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0, 1, 0) end
					if vel.Magnitude > 0 then
						vel = vel.Unit * speed
					end
					setVelocity(vel)
				until not Fly.Enabled
			end
		end,
		Tooltip = 'Fly around the map'
	})
	FlySpeed = Fly:CreateSlider({Name = 'Speed', Min = 1, Max = 200, Default = 50, Decimal = 10})

	NoclipMod = larp.Categories.Blatant:CreateModule({
		Name = 'Noclip',
		Function = function(callback)
			if callback then
				repeat
					runService.Stepped:Wait()
					local char = entitylib.isAlive and entitylib.character.Character or nil
					if char then
						for _, part in char:GetDescendants() do
							if part:IsA('BasePart') then
								part.CanCollide = false
							end
						end
					end
				until not NoclipMod.Enabled
			end
		end,
		Tooltip = 'Walk through walls'
	})
	NoClipValue = NoclipMod:CreateSlider({Name = 'Mode', Min = 1, Max = 2, Default = 1, Suffix = function(val) return val == 1 and 'Walk' or 'Fly' end})

	InfiniteJump = larp.Categories.Blatant:CreateModule({
		Name = 'Infinite Jump',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					local hum = getLocalHumanoid()
					if hum then
						hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
					end
					if inputService:IsKeyDown(Enum.KeyCode.Space) then
						local root = getLocalRoot()
						if root and root.Velocity.Y < 0.5 then
							pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
						end
					end
				until not InfiniteJump.Enabled
			end
		end,
		Tooltip = 'Jump infinitely by holding space'
	})

	BunnyHop = larp.Categories.Blatant:CreateModule({
		Name = 'Bunny Hop',
		Function = function(callback)
			if callback then
				repeat
					runService.Heartbeat:Wait()
					local hum = getLocalHumanoid()
					if hum and hum:GetState() == Enum.HumanoidStateType.Running and inputService:IsKeyDown(Enum.KeyCode.Space) then
						pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
					end
				until not BunnyHop.Enabled
			end
		end,
		Tooltip = 'Auto-jump while running'
	})

	AirWalk = larp.Categories.Blatant:CreateModule({
		Name = 'Air Walk',
		Function = function(callback)
			if callback then
				repeat
					runService.Heartbeat:Wait()
					local root = getLocalRoot()
					local hum = getLocalHumanoid()
					if root and hum and hum:GetState() == Enum.HumanoidStateType.Falling then
						root.Anchored = true
						root.Anchored = false
					end
				until not AirWalk.Enabled
			end
		end,
		Tooltip = 'Walk on air'
	})

	NoSlow = larp.Categories.Blatant:CreateModule({
		Name = 'No Slow',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.2)
					local root = getLocalRoot()
					if root then
						root.AssemblyLinearVelocity = root.AssemblyLinearVelocity
					end
				until not NoSlow.Enabled
			end
		end,
		Tooltip = 'Removes slowdown effects'
	})

	NoStun = larp.Categories.Blatant:CreateModule({
		Name = 'No Stun',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					local root = getLocalRoot()
					if root and root.Velocity.Magnitude < 1 then
						local hum = getLocalHumanoid()
						if hum then
							pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
						end
					end
				until not NoStun.Enabled
			end
		end,
		Tooltip = 'Recover from stuns instantly'
	})

	NoKnockback = larp.Categories.Blatant:CreateModule({
		Name = 'No Knockback',
		Function = function(callback)
			if callback then
				repeat
					runService.Heartbeat:Wait()
					local root = getLocalRoot()
					local hum = getLocalHumanoid()
					if root and hum then
						pcall(function()
							hum:ChangeState(Enum.HumanoidStateType.GettingUp)
							root.AssemblyLinearVelocity = root.AssemblyLinearVelocity
						end)
					end
				until not NoKnockback.Enabled
			end
		end,
		Tooltip = 'Ignore knockback'
	})

	VelocityMod = larp.Categories.Blatant:CreateModule({
		Name = 'Velocity',
		Function = function(callback)
			if callback then
				repeat
					runService.Heartbeat:Wait()
					local root = getLocalRoot()
					if root then
						root.Velocity = root.Velocity * VelocityValue.Value
					end
				until not VelocityMod.Enabled
			end
		end,
		Tooltip = 'Multiply your velocity'
	})
	VelocityValue = VelocityMod:CreateSlider({Name = 'Velocity', Min = -10, Max = 10, Default = 1, Decimal = 10})

	GravityMod = larp.Categories.Blatant:CreateModule({
		Name = 'Gravity',
		Function = function(callback)
			if callback then
				originalGravity = originalGravity or workspace.Gravity
				repeat
					task.wait()
					setGravity(GravityValue.Value)
				until not GravityMod.Enabled
			else
				workspace.Gravity = originalGravity or 196.2
			end
		end,
		Tooltip = 'Override gravity'
	})
	GravityValue = GravityMod:CreateSlider({Name = 'Gravity', Min = -500, Max = 500, Default = 196.2, Decimal = 10})
	local originalGravity = 196.2

	LongJump = larp.Categories.Blatant:CreateModule({
		Name = 'Long Jump',
		Function = function(callback)
			if callback then
				local jumped = false
				local oldSpace
				inputService.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					if input.KeyCode == Enum.KeyCode.Space then
						jumped = true
					end
				end)
				repeat
					runService.Heartbeat:Wait()
					if jumped then
						jumped = false
						local root = getLocalRoot()
						local hum = getLocalHumanoid()
						if root and hum then
							local forward = gameCamera.CFrame.LookVector * Vector3.new(1, 0, 1)
							pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
							root.Velocity = root.Velocity + forward * LongJumpPower.Value
						end
					end
				until not LongJump.Enabled
			end
		end,
		Tooltip = 'Jump further'
	})
	LongJumpPower = LongJump:CreateSlider({Name = 'Power', Min = 0, Max = 200, Default = 80, Decimal = 10})
end)
run(function()
	local AutoKill
	local AKRange
	local AutoStomp
	local AutoGrab
	local AutoShoot
	local AutoBlock
	local AutoDodge
	local AutoParry
	local RageMode
	local TargetTeleport
	local TeleportBehind
	local TeleportBack
	local AutoTarget
	local AutoEquip
	local EmergencyTP
	local PanicMode
	local ServerHop
	local AntiAFKMod
	local Freecam
	local AntiAim
	local SpinBot
	local NoFall
	local PositionSave
	local PositionLoad
	local savedPosition

	local function closestTarget(range)
		if not entitylib.isAlive then return nil end
		local origin = entitylib.character.RootPart.Position
		local targets = findTargets({
			Origin = origin,
			Part = 'HumanoidRootPart',
			MaxDistance = range,
			Checks = {Dead = true, Team = true}
		})
		return targets[1]
	end

	local function activate()
		if entitylib.isAlive and entitylib.character.Character then
			pcall(function()
				local be = entitylib.character.Character:FindFirstChild('BodyEffects')
				if be then MainModule.Activate(be) end
			end)
		end
	end

	AutoKill = larp.Categories.Blatant:CreateModule({
		Name = 'Auto Kill',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.05)
					local target = closestTarget(AKRange.Value)
					if target then
						activate()
						entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position, target.part.Position) * CFrame.new(0, 0, math.min(target.mag - 3, 0))
					end
				until not AutoKill.Enabled
			end
		end,
		Tooltip = 'Automatically punch enemies in range'
	})
	AKRange = AutoKill:CreateSlider({Name = 'Range', Min = 3, Max = 30, Default = 8, Suffix = function(val) return val == 1 and 'stud' or 'studs' end})

	AutoStomp = larp.Categories.Blatant:CreateModule({
		Name = 'Auto Stomp',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						for _, ent in entitylib.List do
							if ent == entitylib.character then continue end
							if isKO(ent) and ent.RootPart then
								if (ent.RootPart.Position - root.Position).Magnitude < 12 then
									pcall(function()
										GameRemoteFunction:InvokeServer('Stomp', ent.Character)
									end)
								end
							end
						end
					end
				until not AutoStomp.Enabled
			end
		end,
		Tooltip = 'Auto stomp knocked players'
	})

	AutoGrab = larp.Categories.Blatant:CreateModule({
		Name = 'Auto Grab',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						local be = getBodyEffects(entitylib.character.Character)
						local grabbed = be and be:FindFirstChild('Grabbed') and be.Grabbed.Value
						if not grabbed then
							for _, ent in entitylib.List do
								if ent == entitylib.character then continue end
								if isKO(ent) and ent.RootPart and (ent.RootPart.Position - root.Position).Magnitude < 10 then
									pcall(function()
										GameRemoteFunction:InvokeServer('Grab', ent.Character)
									end)
									break
								end
							end
						end
					end
				until not AutoGrab.Enabled
			end
		end,
		Tooltip = 'Auto grab knocked players'
	})

	AutoShoot = larp.Categories.Blatant:CreateModule({
		Name = 'Auto Shoot',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.05)
					if entitylib.isAlive then
						local tool = entitylib.character.Character:FindFirstChildOfClass('Tool')
						if tool and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
							pcall(function() tool:Activate() end)
						end
					end
				until not AutoShoot.Enabled
			end
		end,
		Tooltip = 'Holds the trigger on your gun'
	})

	AutoBlock = larp.Categories.Blatant:CreateModule({
		Name = 'Auto Block',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.05)
					if entitylib.isAlive then
						local target = closestTarget(15)
						if target then
							pcall(function() MainModule.Block(entitylib.character.Character:FindFirstChild('BodyEffects'), true) end)
						else
							pcall(function() MainModule.Block(entitylib.character.Character:FindFirstChild('BodyEffects'), false) end)
						end
					end
				until not AutoBlock.Enabled
			end
		end,
		Tooltip = 'Auto block when enemies are near'
	})

	AutoDodge = larp.Categories.Blatant:CreateModule({
		Name = 'Auto Dodge',
		Function = function(callback)
			if callback then
				repeat
					runService.Heartbeat:Wait()
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						local be = getBodyEffects(entitylib.character.Character)
						local attacking = be and be:FindFirstChild('Attacking') and be.Attacking.Value
						if attacking and root then
							root.Velocity = Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
						end
					end
				until not AutoDodge.Enabled
			end
		end,
		Tooltip = 'Dodge when being attacked'
	})

	AutoParry = larp.Categories.Blatant:CreateModule({
		Name = 'Auto Parry',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.05)
					if entitylib.isAlive then
						local target = closestTarget(8)
						if target then
							activate()
						end
					end
				until not AutoParry.Enabled
			end
		end,
		Tooltip = 'Punch enemies approaching you'
	})

	RageMode = larp.Categories.Blatant:CreateModule({
		Name = 'Rage Mode',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.05)
					if entitylib.isAlive then
						local target = closestTarget(30)
						if target then
							activate()
							local root = entitylib.character.RootPart
							root.CFrame = CFrame.lookAt(root.Position, target.part.Position)
						end
					end
				until not RageMode.Enabled
			end
		end,
		Tooltip = 'Aggressive auto-punch everything'
	})

	TargetTeleport = larp.Categories.Blatant:CreateModule({
		Name = 'Target Teleport',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					if entitylib.isAlive and inputService:IsKeyDown(Enum.KeyCode.X) then
						local target = closestTarget(1000)
						if target then
							local root = entitylib.character.RootPart
							local offset = TeleportBehind.Enabled and Vector3.new(0, 0, 8) or Vector3.zero
							root.CFrame = target.part.CFrame * CFrame.new(offset) * CFrame.Angles(0, math.rad(180), 0)
						end
					end
				until not TargetTeleport.Enabled
			end
		end,
		Tooltip = 'Hold X to teleport to the nearest target'
	})
	TeleportBehind = TargetTeleport:CreateToggle({Name = 'Teleport Behind Target', Default = true})
	TeleportBack = TargetTeleport:CreateToggle({Name = 'Teleport Back', Default = false})

	AutoTarget = larp.Categories.Blatant:CreateModule({
		Name = 'Auto Target',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					if entitylib.isAlive then
						local target = closestTarget(1000)
						if target then
							local root = entitylib.character.RootPart
							root.CFrame = CFrame.lookAt(root.Position, target.part.Position)
						end
					end
				until not AutoTarget.Enabled
			end
		end,
		Tooltip = 'Face the nearest target'
	})

	AutoEquip = larp.Categories.Blatant:CreateModule({
		Name = 'Auto Equip',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.2)
					if entitylib.isAlive and entitylib.character.Character then
						local backpack = lplr.Backpack
						local tool = backpack:FindFirstChildOfClass('Tool')
						if tool and not entitylib.character.Character:FindFirstChildOfClass('Tool') then
							pcall(function() tool.Parent = entitylib.character.Character end)
						end
					end
				until not AutoEquip.Enabled
			end
		end,
		Tooltip = 'Auto equip a tool from your backpack'
	})

	EmergencyTP = larp.Categories.Blatant:CreateModule({
		Name = 'Emergency Teleport',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						local hum = entitylib.character.Humanoid
						if hum.Health < 20 then
							root.CFrame = CFrame.new(0, 200, 0) + Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
							hum.Health = hum.MaxHealth
						end
					end
				until not EmergencyTP.Enabled
			end
		end,
		Tooltip = 'Teleports you away and heals you when low'
	})

	PanicMode = larp.Categories.Blatant:CreateModule({
		Name = 'Panic Mode',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.05)
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						root.Velocity = Vector3.new(0, 80, 0)
						pcall(function()
							entitylib.character.Humanoid.Health = entitylib.character.Humanoid.MaxHealth
						end)
					end
				until not PanicMode.Enabled
			end
		end,
		Tooltip = 'Desperate flight + heal'
	})

	ServerHop = larp.Categories.Blatant:CreateModule({
		Name = 'Server Hop',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						local hum = entitylib.character.Humanoid
						if hum.Health < 15 then
							pcall(function()
								game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, game.JobId)
							end)
						end
					end
				until not ServerHop.Enabled
			end
		end,
		Tooltip = 'Rejoins when low health'
	})

	AntiAFKMod = larp.Categories.Blatant:CreateModule({
		Name = 'Anti-AFK',
		Function = function(callback)
			if callback then
				repeat
					task.wait(60)
					if entitylib.isAlive and entitylib.character.RootPart then
						entitylib.character.RootPart.AssemblyLinearVelocity = entitylib.character.RootPart.AssemblyLinearVelocity + Vector3.new(0.01, 0, 0)
					end
				until not AntiAFKMod.Enabled
			end
		end,
		Tooltip = 'Prevents AFK kick'
	})

	Freecam = larp.Categories.Blatant:CreateModule({
		Name = 'Freecam',
		Function = function(callback)
			if callback then
				local cam = gameCamera
				local oldCF = cam.CFrame
				local speed = 50
				local pos = cam.CFrame.Position
				repeat
					local dt = runService.RenderStepped:Wait()
					local move = Vector3.zero
					if inputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
					if inputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
					if inputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
					if inputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
					if inputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
					if inputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
					if inputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = 100 else speed = 50 end
					pos = pos + move * speed * dt
					local x = -inputService:GetMouseDelta().Y * 0.003
					local y = -inputService:GetMouseDelta().X * 0.003
					local cf = CFrame.new(pos) * CFrame.Angles(x, y, 0)
					cam.CFrame = cf
					if lplr.Character and lplr.Character:FindFirstChild('Humanoid') then
						lplr.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
					end
				until not Freecam.Enabled
				cam.CFrame = oldCF
				if lplr.Character and lplr.Character:FindFirstChild('Humanoid') then
					lplr.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
				end
			end
		end,
		Tooltip = 'Free camera movement'
	})

	AntiAim = larp.Categories.Blatant:CreateModule({
		Name = 'Anti-Aim',
		Function = function(callback)
			if callback then
				repeat
					runService.RenderStepped:Wait()
					if entitylib.isAlive and entitylib.character.RootPart then
						local root = entitylib.character.RootPart
						root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(180), 0)
					end
				until not AntiAim.Enabled
			end
		end,
		Tooltip = 'Faces away from attackers'
	})

	SpinBot = larp.Categories.Blatant:CreateModule({
		Name = 'Spin Bot',
		Function = function(callback)
			if callback then
				local yaw = 0
				repeat
					runService.RenderStepped:Wait()
					if entitylib.isAlive and entitylib.character.RootPart then
						yaw = yaw + 10
						entitylib.character.RootPart.CFrame = entitylib.character.RootPart.CFrame * CFrame.Angles(0, math.rad(yaw), 0)
					end
				until not SpinBot.Enabled
			end
		end,
		Tooltip = 'Continuously spins your character'
	})

	NoFall = larp.Categories.Blatant:CreateModule({
		Name = 'No Fall',
		Function = function(callback)
			if callback then
				repeat
					runService.Heartbeat:Wait()
					local hum = getLocalHumanoid()
					if hum then
						pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingNoCollision, false) end)
					end
				until not NoFall.Enabled
			end
		end,
		Tooltip = 'No fall damage'
	})

	PositionSave = larp.Categories.Blatant:CreateModule({
		Name = 'Position Save',
		Function = function(callback)
			if callback then
				savedPosition = entitylib.isAlive and entitylib.character.RootPart.Position or nil
				notif('Position saved'..(savedPosition and '' or ' (not alive)'), 3, 'info')
			end
		end,
		Tooltip = 'Saves your current position'
	})
	PositionLoad = larp.Categories.Blatant:CreateButton({
		Name = 'Position Load',
		Function = function()
			if savedPosition and entitylib.isAlive and entitylib.character.RootPart then
				entitylib.character.RootPart.CFrame = CFrame.new(savedPosition)
				notif('Position loaded', 3, 'info')
			else
				notif('No saved position', 3, 'alert')
			end
		end,
		Tooltip = 'Teleports you to the saved position'
	})
end)
run(function()
	local WalkSpeedOverride
	local WalkSpeedValue
	local JumpPowerOverride
	local JumpPowerValue
	local FOVOverride
	local FOVValue
	local CameraUnlock
	local Fullbright
	local Desync
	local MovementModifier
	local MovementSpeed

	WalkSpeedOverride = larp.Categories.Blatant:CreateModule({
		Name = 'WalkSpeed Override',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					local hum = getLocalHumanoid()
					if hum then
						hum.WalkSpeed = WalkSpeedValue.Value
					end
				until not WalkSpeedOverride.Enabled
			end
		end,
		Tooltip = 'Override walkspeed'
	})
	WalkSpeedValue = WalkSpeedOverride:CreateSlider({Name = 'WalkSpeed', Min = 1, Max = 500, Default = 16, Decimal = 10})

	JumpPowerOverride = larp.Categories.Blatant:CreateModule({
		Name = 'JumpPower Override',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					local hum = getLocalHumanoid()
					if hum then
						hum.JumpPower = JumpPowerValue.Value
					end
				until not JumpPowerOverride.Enabled
			end
		end,
		Tooltip = 'Override jump power'
	})
	JumpPowerValue = JumpPowerOverride:CreateSlider({Name = 'JumpPower', Min = 0, Max = 500, Default = 50, Decimal = 10})

	FOVOverride = larp.Categories.Blatant:CreateModule({
		Name = 'FOV Override',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					if gameCamera then
						gameCamera.FieldOfView = FOVValue.Value
					end
				until not FOVOverride.Enabled
			else
				if gameCamera then
					gameCamera.FieldOfView = 70
				end
			end
		end,
		Tooltip = 'Override camera FOV'
	})
	FOVValue = FOVOverride:CreateSlider({Name = 'FOV', Min = 10, Max = 160, Default = 90, Decimal = 10, Suffix = function(val) return val == 1 and 'deg' or 'deg' end})

	CameraUnlock = larp.Categories.Blatant:CreateModule({
		Name = 'Camera Unlock',
		Function = function(callback)
			if callback then
				repeat
					runService.RenderStepped:Wait()
					if gameCamera then
						gameCamera.CameraType = Enum.CameraType.Scriptable
					end
				until not CameraUnlock.Enabled
			else
				if gameCamera then
					gameCamera.CameraType = Enum.CameraType.Custom
				end
			end
		end,
		Tooltip = 'Unlocks the camera'
	})

	Fullbright = larp.Categories.Blatant:CreateModule({
		Name = 'Fullbright',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					lighting.Brightness = 2
					lighting.ClockTime = 14
					lighting.FogEnd = 99999
				until not Fullbright.Enabled
			else
				lighting.Brightness = 1
				lighting.FogEnd = 500
			end
		end,
		Tooltip = 'Brighten the whole map'
	})

	Desync = larp.Categories.Blatant:CreateModule({
		Name = 'Desync',
		Function = function(callback)
			if callback then
				repeat
					runService.Stepped:Wait()
					local root = getLocalRoot()
					if root then
						root.CFrame = root.CFrame
						root.AssemblyLinearVelocity = root.AssemblyLinearVelocity
					end
				until not Desync.Enabled
			end
		end,
		Tooltip = 'Client desync'
	})

	MovementModifier = larp.Categories.Blatant:CreateModule({
		Name = 'Movement Modifier',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					local root = getLocalRoot()
					if root then
						root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * MovementSpeed.Value
					end
				until not MovementModifier.Enabled
			end
		end,
		Tooltip = 'Modify movement speed'
	})
	MovementSpeed = MovementModifier:CreateSlider({Name = 'Speed', Min = 0, Max = 10, Default = 1, Decimal = 10})
end)
run(function()
	local ShaderPresets
	local ShaderPreset
	local CustomSky
	local SkyColor
	local TimeChanger
	local TimeValue
	local FOVChanger
	local FOVValue
	local SpinCharacter
	local SpinSpeed
	local Ragdoll
	local FakeRagdoll
	local TinyCharacter
	local TinyScale
	local BigHead
	local HeadScale
	local CharacterTrails
	local ParticleAura
	local RainbowCharacter
	local LowGravity
	local MoonJump
	local NoFog
	local CustomLighting
	local LightBrightness

	local function setSkyColor(color)
		local sky = lighting:FindFirstChildOfClass('Sky') or Instance.new('Sky')
		sky.Parent = lighting
		sky.SkyboxUp = 'rbxassetid://0'
		sky.SkyboxDown = 'rbxassetid://0'
		sky.SkyboxLeft = 'rbxassetid://0'
		sky.SkyboxRight = 'rbxassetid://0'
		sky.SkyboxBack = 'rbxassetid://0'
		sky.SkyboxFront = 'rbxassetid://0'
	end

	ShaderPresets = larp.Categories.Utility:CreateModule({
		Name = 'Shader Presets',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.2)
					if ShaderPreset.Value == 'Vibrant' then
						lighting.Brightness = 1.5
						lighting.Contrast = 0.5
						lighting.Saturation = 1.5
					elseif ShaderPreset.Value == 'Soft' then
						lighting.Brightness = 1
						lighting.Contrast = 0.2
						lighting.Saturation = 0.8
					elseif ShaderPreset.Value == 'Dark' then
						lighting.Brightness = 0.4
						lighting.Contrast = 0.3
						lighting.Saturation = 0.6
					end
				until not ShaderPresets.Enabled
			end
		end,
		Tooltip = 'Apply a visual shader preset'
	})
	ShaderPreset = ShaderPresets:CreateDropdown({Name = 'Preset', List = {'Vibrant', 'Soft', 'Dark'}, Default = 'Vibrant'})

	CustomSky = larp.Categories.Utility:CreateModule({
		Name = 'Custom Sky',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					setSkyColor(SkyColor)
				until not CustomSky.Enabled
			end
		end,
		Tooltip = 'Custom sky color'
	})
	SkyColor = CustomSky:CreateColorSlider({Name = 'Sky Color', Default = Color3.fromRGB(100, 180, 255)})

	TimeChanger = larp.Categories.Utility:CreateModule({
		Name = 'Time Changer',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					lighting.ClockTime = TimeValue.Value
				until not TimeChanger.Enabled
			end
		end,
		Tooltip = 'Change the time of day'
	})
	TimeValue = TimeChanger:CreateSlider({Name = 'Time', Min = 0, Max = 24, Default = 14, Decimal = 10, Suffix = function(val) return val == 1 and 'hour' or 'hours' end})

	FOVChanger = larp.Categories.Utility:CreateModule({
		Name = 'FOV Changer',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					if gameCamera then
						gameCamera.FieldOfView = FOVValue.Value
					end
				until not FOVChanger.Enabled
			else
				if gameCamera then
					gameCamera.FieldOfView = 70
				end
			end
		end,
		Tooltip = 'Change camera FOV'
	})
	FOVValue = FOVChanger:CreateSlider({Name = 'FOV', Min = 10, Max = 160, Default = 70, Decimal = 10})

	SpinCharacter = larp.Categories.Utility:CreateModule({
		Name = 'Spin Character',
		Function = function(callback)
			if callback then
				local yaw = 0
				repeat
					runService.RenderStepped:Wait()
					if entitylib.isAlive and entitylib.character.RootPart then
						yaw = yaw + SpinSpeed.Value
						entitylib.character.RootPart.CFrame = entitylib.character.RootPart.CFrame * CFrame.Angles(0, math.rad(yaw), 0)
					end
				until not SpinCharacter.Enabled
			end
		end,
		Tooltip = 'Spin your character'
	})
	SpinSpeed = SpinCharacter:CreateSlider({Name = 'Speed', Min = 1, Max = 50, Default = 10, Decimal = 10})

	Ragdoll = larp.Categories.Utility:CreateModule({
		Name = 'Ragdoll',
		Function = function(callback)
			if callback then
				local hum = getLocalHumanoid()
				if hum then
					hum:ChangeState(Enum.HumanoidStateType.Ragdoll)
				end
			end
		end,
		Tooltip = 'Ragdoll yourself'
	})

	FakeRagdoll = larp.Categories.Utility:CreateModule({
		Name = 'Fake Ragdoll',
		Function = function(callback)
			if callback then
				local root = getLocalRoot()
				if root then
					root.Anchored = true
				end
				task.delay(1, function()
					if root then root.Anchored = false end
				end)
			end
		end,
		Tooltip = 'Fake ragdoll (anchored for a moment)'
	})

	TinyCharacter = larp.Categories.Utility:CreateModule({
		Name = 'Tiny Character',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					local char = entitylib.isAlive and entitylib.character.Character or nil
					if char then
						local scale = char:FindFirstChild('HumanoidRootPart') and char.HumanoidRootPart.Size.Y * TinyScale.Value or 1
						char.HumanoidRootPart.Size = char.HumanoidRootPart.Size * TinyScale.Value
					end
				until not TinyCharacter.Enabled
			end
		end,
		Tooltip = 'Make your character tiny'
	})
	TinyScale = TinyCharacter:CreateSlider({Name = 'Scale', Min = 0.1, Max = 1, Default = 0.5, Decimal = 100})

	BigHead = larp.Categories.Utility:CreateModule({
		Name = 'Big Head',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					local char = entitylib.isAlive and entitylib.character.Character or nil
					if char and char:FindFirstChild('Head') then
						char.Head.Size = char.Head.Size * HeadScale.Value
					end
				until not BigHead.Enabled
			end
		end,
		Tooltip = 'Make your head big'
	})
	HeadScale = BigHead:CreateSlider({Name = 'Head Scale', Min = 1, Max = 5, Default = 2, Decimal = 10})

	CharacterTrails = larp.Categories.Utility:CreateModule({
		Name = 'Character Trails',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.2)
					local char = entitylib.isAlive and entitylib.character.Character or nil
					if char and char:FindFirstChild('HumanoidRootPart') then
						local trail = char:FindFirstChild('Trail') or Instance.new('Trail')
						trail.Parent = char
					end
				until not CharacterTrails.Enabled
			end
		end,
		Tooltip = 'Add a trail to your character'
	})

	ParticleAura = larp.Categories.Utility:CreateModule({
		Name = 'Particle Aura',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.2)
					local char = entitylib.isAlive and entitylib.character.Character or nil
					if char and char:FindFirstChild('HumanoidRootPart') and not char.HumanoidRootPart:FindFirstChild('Aura') then
						local p = Instance.new('ParticleEmitter')
						p.Name = 'Aura'
						p.Texture = 'rbxasset://textures/particles/sparkles_main.dds'
						p.Parent = char.HumanoidRootPart
					end
				until not ParticleAura.Enabled
			end
		end,
		Tooltip = 'Particle aura around you'
	})

	RainbowCharacter = larp.Categories.Utility:CreateModule({
		Name = 'Rainbow Character',
		Function = function(callback)
			if callback then
				local hue = 0
				repeat
					runService.RenderStepped:Wait()
					hue = (hue + 0.01) % 1
					local color = Color3.fromHSV(hue, 1, 1)
					local char = entitylib.isAlive and entitylib.character.Character or nil
					if char then
						for _, part in char:GetDescendants() do
							if part:IsA('BasePart') then
								part.Color = color
							end
						end
					end
				until not RainbowCharacter.Enabled
			end
		end,
		Tooltip = 'Rainbow colored character'
	})

	LowGravity = larp.Categories.Utility:CreateModule({
		Name = 'Low Gravity',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					workspace.Gravity = 30
				until not LowGravity.Enabled
			else
				workspace.Gravity = 196.2
			end
		end,
		Tooltip = 'Low gravity'
	})

	MoonJump = larp.Categories.Utility:CreateModule({
		Name = 'Moon Jump',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					workspace.Gravity = 5
					local hum = getLocalHumanoid()
					if hum then hum.JumpPower = 100 end
				until not MoonJump.Enabled
			else
				workspace.Gravity = 196.2
			end
		end,
		Tooltip = 'Moon gravity + high jump'
	})

	NoFog = larp.Categories.Utility:CreateModule({
		Name = 'No Fog',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					lighting.FogEnd = 99999
				until not NoFog.Enabled
			else
				lighting.FogEnd = 500
			end
		end,
		Tooltip = 'Remove fog'
	})

	CustomLighting = larp.Categories.Utility:CreateModule({
		Name = 'Custom Lighting',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					lighting.Brightness = LightBrightness.Value
				until not CustomLighting.Enabled
			end
		end,
		Tooltip = 'Custom lighting brightness'
	})
	LightBrightness = CustomLighting:CreateSlider({Name = 'Brightness', Min = 0, Max = 5, Default = 1, Decimal = 10})
end)
local function createESPFrame(name, size, position, parent)
	local frame = Instance.new('Frame')
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

run(function()
	local ESP
	local ESPTargets
	local NameTags
	local TagColor
	local BoxESP
	local BoxColor
	local SkeletonESP
	local SkeletonColor
	local HealthBar
	local HealthText
	local DistanceText
	local Tracers
	local TracerColor
	local Chams
	local ChamColor
	local HeadESP
	local HeadColor
	local OffScreenArrows
	local ArrowColor
	local TargetHighlight
	local TargetIndicator
	local FOVCircle
	local FOVCircleColor
	local Snaplines
	local LookDirection
	local PlayerGlow
	local GlowColor
	local BoundingCircle
	local DroppedItemESP
	local CashESP
	local GunESP
	local ATMESP
	local LocationESP
	local Crosshair
	local CrosshairColor
	local Hitmarker
	local HitmarkerColor
	local HitEffect
	local KillEffect
	local BulletTracers
	local DamageIndicator
	local entities = {}
	local holder
	local hitmarkerGui

	local function createTag(ent)
		if entities[ent] then return entities[ent] end
		local gui = Instance.new('BillboardGui')
		gui.Name = 'ESP_'..(ent.Player and ent.Player.Name or 'NPC')
		gui.Size = UDim2.fromScale(6, 2.5)
		gui.StudsOffset = Vector3.new(0, 3, 0)
		gui.AlwaysOnTop = true
		gui.LightInfluence = 1
		gui.Adornee = ent.Head or ent.RootPart
		gui.Parent = ent.Character
		local main = createESPFrame('Main', UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), gui)
		main.AnchorPoint = Vector2.new(0.5, 0.5)
		entities[ent] = {gui = gui, main = main, parts = {}}
		return entities[ent]
	end

	local function setVisible(ent, name, visible)
		local data = entities[ent]
		if not data then return end
		local part = data.parts[name]
		if part then
			part.Visible = visible
		end
	end

	local function setupBox(data, ent)
		if data.parts.Box then return end
		local box = Instance.new('Frame')
		box.Name = 'Box'
		box.Size = UDim2.fromScale(1, 1)
		box.BackgroundTransparency = 1
		box.BorderSizePixel = 1
		box.BorderColor3 = BoxColor.Value
		box.Parent = data.main
		data.parts.Box = box
	end

	local function setupNameTag(data, ent)
		if data.parts.Name then return end
		local label = Instance.new('TextLabel')
		label.Name = 'Name'
		label.Size = UDim2.fromScale(1, 0.2)
		label.Position = UDim2.fromScale(0, -0.25)
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = TagColor.Value
		label.Parent = data.main
		data.parts.Name = label
	end

	local function setupHealth(data, ent)
		if data.parts.Health then return end
		local bg = Instance.new('Frame')
		bg.Name = 'HealthBG'
		bg.Size = UDim2.fromScale(1, 0.06)
		bg.Position = UDim2.fromScale(0, 1.02)
		bg.BackgroundColor3 = Color3.new(0, 0, 0)
		bg.BackgroundTransparency = 0.5
		bg.BorderSizePixel = 0
		bg.Parent = data.main
		local fill = Instance.new('Frame')
		fill.Name = 'Fill'
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		fill.BorderSizePixel = 0
		fill.Parent = bg
		data.parts.HealthBG = bg
		data.parts.Health = fill
	end

	local function setupHealthText(data)
		if data.parts.HealthText then return end
		local label = Instance.new('TextLabel')
		label.Name = 'HealthText'
		label.Size = UDim2.fromScale(1, 0.15)
		label.Position = UDim2.fromScale(0, 1.1)
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Font = Enum.Font.Gotham
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = data.main
		data.parts.HealthText = label
	end

	local function setupDistance(data)
		if data.parts.Distance then return end
		local label = Instance.new('TextLabel')
		label.Name = 'Distance'
		label.Size = UDim2.fromScale(1, 0.15)
		label.Position = UDim2.fromScale(0, -0.45)
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Font = Enum.Font.Gotham
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = data.main
		data.parts.Distance = label
	end

	local function setupHead(data, ent)
		if data.parts.Head then return end
		local frame = Instance.new('Frame')
		frame.Name = 'Head'
		frame.Size = UDim2.fromScale(0.3, 0.15)
		frame.Position = UDim2.fromScale(0.35, 0)
		frame.BackgroundTransparency = 0.5
		frame.BackgroundColor3 = HeadColor.Value
		frame.BorderSizePixel = 0
		frame.Parent = data.main
		data.parts.Head = frame
	end

	local function setupSkeleton(data)
		if data.parts.Skeleton then return end
		local holder2 = Instance.new('Frame')
		holder2.Name = 'Skeleton'
		holder2.Size = UDim2.fromScale(1, 1)
		holder2.BackgroundTransparency = 1
		holder2.Parent = data.main
		data.parts.Skeleton = holder2
	end

	local function setupTracer(data)
		if data.parts.Tracer then return end
		local label = Instance.new('Frame')
		label.Name = 'Tracer'
		label.Size = UDim2.fromScale(0.02, 0.5)
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.BackgroundColor3 = TracerColor.Value
		label.BorderSizePixel = 0
		label.Parent = data.main
		data.parts.Tracer = label
	end

	ESP = larp.Categories.Render:CreateModule({
		Name = 'ESP',
		Function = function(callback)
			if callback then
				holder = Instance.new('ScreenGui')
				holder.Name = 'DaHoodESP'
				holder.ResetOnSpawn = false
				holder.Parent = lplr:WaitForChild('PlayerGui')
				hitmarkerGui = Instance.new('ScreenGui')
				hitmarkerGui.Name = 'DaHoodHitmarker'
				hitmarkerGui.ResetOnSpawn = false
				hitmarkerGui.Parent = lplr:WaitForChild('PlayerGui')
				local conns = {}
				local function addEnt(ent)
					if ent == entitylib.character then return end
					local data = createTag(ent)
					if BoxESP.Enabled then setupBox(data, ent) end
					if NameTags.Enabled then setupNameTag(data, ent) end
					if HealthBar.Enabled then setupHealth(data, ent) end
					if HealthText.Enabled then setupHealthText(data) end
					if DistanceText.Enabled then setupDistance(data) end
					if HeadESP.Enabled then setupHead(data, ent) end
					if SkeletonESP.Enabled then setupSkeleton(data) end
					if Tracers.Enabled then setupTracer(data) end
					table.insert(conns, entitylib.Events.EntityRemoved:Connect(function(removed)
						if removed == ent and entities[ent] then
							pcall(function() entities[ent].gui:Destroy() end)
							entities[ent] = nil
						end
					end))
				end
				for _, ent in entitylib.List do
					addEnt(ent)
				end
				table.insert(conns, entitylib.Events.EntityAdded:Connect(addEnt))
				repeat
					runService.RenderStepped:Wait()
					local origin = entitylib.isAlive and entitylib.character.RootPart.Position or Vector3.zero
					for ent, data in entities do
						if not ent or not ent.Character or not ent.Character.Parent then
							pcall(function() data.gui:Destroy() end)
							entities[ent] = nil
							continue
						end
						local visible = isVulnerable(ent)
						data.gui.Enabled = visible
						if not visible then continue end
						local name = ent.Player and ent.Player.Name or 'NPC'
						if data.parts.Name then
							data.parts.Name.Text = name
							data.parts.Name.TextColor3 = TagColor.Value
						end
						if data.parts.Health and ent.Humanoid then
							local ratio = math.clamp(ent.Humanoid.Health / ent.Humanoid.MaxHealth, 0, 1)
							data.parts.Health.Size = UDim2.fromScale(ratio, 1)
							data.parts.Health.BackgroundColor3 = ratio > 0.5 and Color3.fromRGB(0, 255, 0) or (ratio > 0.25 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0))
						end
						if data.parts.HealthText and ent.Humanoid then
							data.parts.HealthText.Text = tostring(math.floor(ent.Humanoid.Health))..' / '..tostring(math.floor(ent.Humanoid.MaxHealth))
						end
						if data.parts.Distance then
							data.parts.Distance.Text = tostring(math.floor((ent.RootPart.Position - origin).Magnitude))..' studs'
						end
						if data.parts.Head then
							data.parts.Head.Visible = HeadESP.Enabled
						end
						if data.parts.Box then
							data.parts.Box.Visible = BoxESP.Enabled
							data.parts.Box.BorderColor3 = BoxColor.Value
						end
						if data.parts.Tracer then
							data.parts.Tracer.Visible = Tracers.Enabled
							data.parts.Tracer.BackgroundColor3 = TracerColor.Value
						end
						if data.parts.Skeleton then
							data.parts.Skeleton.Visible = SkeletonESP.Enabled
						end
						if data.parts.HealthBG then data.parts.HealthBG.Visible = HealthBar.Enabled end
						if data.parts.HealthText then data.parts.HealthText.Visible = HealthText.Enabled end
						if data.parts.Distance then data.parts.Distance.Visible = DistanceText.Enabled end
						if data.parts.Name then data.parts.Name.Visible = NameTags.Enabled end
					end
				until not ESP.Enabled
				for _, c in conns do c:Disconnect() end
				for _, data in entities do
					pcall(function() data.gui:Destroy() end)
				end
				table.clear(entities)
				if holder then pcall(function() holder:Destroy() end) end
				if hitmarkerGui then pcall(function() hitmarkerGui:Destroy() end) end
			end
		end,
		Tooltip = 'ESP overlays'
	})
	ESPTargets = ESP:CreateTargets({Players = true, NPCs = true})
	NameTags = ESP:CreateToggle({Name = 'Name Tags', Default = true})
	TagColor = ESP:CreateColorSlider({Name = 'Tag Color', Default = Color3.fromRGB(255, 255, 255)})
	BoxESP = ESP:CreateToggle({Name = 'Box ESP', Default = true})
	BoxColor = ESP:CreateColorSlider({Name = 'Box Color', Default = Color3.fromRGB(0, 255, 255)})
	SkeletonESP = ESP:CreateToggle({Name = 'Skeleton ESP', Default = true})
	SkeletonColor = ESP:CreateColorSlider({Name = 'Skeleton Color', Default = Color3.fromRGB(255, 255, 255)})
	HealthBar = ESP:CreateToggle({Name = 'Health Bar', Default = true})
	HealthText = ESP:CreateToggle({Name = 'Health Text', Default = true})
	DistanceText = ESP:CreateToggle({Name = 'Distance', Default = true})
	Tracers = ESP:CreateToggle({Name = 'Tracers', Default = true})
	TracerColor = ESP:CreateColorSlider({Name = 'Tracer Color', Default = Color3.fromRGB(255, 0, 0)})
	Chams = ESP:CreateToggle({Name = 'Chams', Default = false})
	ChamColor = ESP:CreateColorSlider({Name = 'Cham Color', Default = Color3.fromRGB(0, 255, 0)})
	HeadESP = ESP:CreateToggle({Name = 'Head ESP', Default = true})
	HeadColor = ESP:CreateColorSlider({Name = 'Head Color', Default = Color3.fromRGB(255, 255, 0)})
	OffScreenArrows = ESP:CreateToggle({Name = 'Off-Screen Arrows', Default = true})
	ArrowColor = ESP:CreateColorSlider({Name = 'Arrow Color', Default = Color3.fromRGB(255, 0, 0)})
	TargetHighlight = ESP:CreateToggle({Name = 'Target Highlight', Default = false})
	TargetIndicator = ESP:CreateToggle({Name = 'Target Indicator', Default = true})
	FOVCircle = ESP:CreateToggle({Name = 'FOV Circle', Default = true})
	FOVCircleColor = ESP:CreateColorSlider({Name = 'FOV Circle Color', Default = Color3.fromRGB(255, 255, 255)})
	Snaplines = ESP:CreateToggle({Name = 'Snaplines', Default = false})
	LookDirection = ESP:CreateToggle({Name = 'Look Direction', Default = false})
	PlayerGlow = ESP:CreateToggle({Name = 'Player Glow', Default = false})
	GlowColor = ESP:CreateColorSlider({Name = 'Glow Color', Default = Color3.fromRGB(0, 255, 255)})
	BoundingCircle = ESP:CreateToggle({Name = 'Bounding Circle', Default = false})
	DroppedItemESP = ESP:CreateToggle({Name = 'Dropped Item ESP', Default = false})
	CashESP = ESP:CreateToggle({Name = 'Cash ESP', Default = false})
	GunESP = ESP:CreateToggle({Name = 'Gun ESP', Default = false})
	ATMESP = ESP:CreateToggle({Name = 'ATM ESP', Default = false})
	LocationESP = ESP:CreateToggle({Name = 'Location ESP', Default = false})
	Crosshair = ESP:CreateToggle({Name = 'Crosshair', Default = true})
	CrosshairColor = ESP:CreateColorSlider({Name = 'Crosshair Color', Default = Color3.fromRGB(0, 255, 0)})
	Hitmarker = ESP:CreateToggle({Name = 'Hitmarker', Default = true})
	HitmarkerColor = ESP:CreateColorSlider({Name = 'Hitmarker Color', Default = Color3.fromRGB(255, 255, 255)})
	HitEffect = ESP:CreateToggle({Name = 'Hit Effect', Default = false})
	KillEffect = ESP:CreateToggle({Name = 'Kill Effect', Default = false})
	BulletTracers = ESP:CreateToggle({Name = 'Bullet Tracers', Default = false})
	DamageIndicator = ESP:CreateToggle({Name = 'Damage Indicator', Default = true})
end)
run(function()
	local Overlays
	local FOVCircle
	local FOVSize
	local FOVColor
	local Crosshair
	local CrosshairColor
	local CrosshairSize
	local Hitmarker
	local HitmarkerColor
	local HitmarkerTime
	local HitEffect
	local KillEffect
	local DamageIndicator
	local screenGui
	local fovFrame
	local crosshairGui
	local damageConn
	local lastHealth = 100
	local damageQueue = {}

	local function makeFrame(parent, color, size, pos)
		local f = Instance.new('Frame')
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.Size = size
		f.Position = pos
		f.Parent = parent
		return f
	end

	local function showHitmarker()
		if not Hitmarker.Enabled then return end
		local pos = getMousePosition()
		local lines = {}
		local offset = 8
		for _, dir in {{-1, -1}, {1, -1}, {-1, 1}, {1, 1}} do
			local l = makeFrame(crosshairGui, HitmarkerColor.Value, UDim2.fromOffset(2, 6), UDim2.fromOffset(pos.X + dir[1] * offset - 1, pos.Y + dir[2] * offset - 3))
			table.insert(lines, l)
		end
		task.delay(HitmarkerTime.Value, function()
			for _, l in lines do
				pcall(function() l:Destroy() end)
			end
		end)
	end

	local function spawnDamageIndicator(amount, position)
		if not DamageIndicator.Enabled then return end
		local pos, vis = gameCamera:WorldToViewportPoint(position)
		if not vis then return end
		local label = Instance.new('TextLabel')
		label.Text = '-'..tostring(math.floor(amount))
		label.TextColor3 = Color3.fromRGB(255, 80, 80)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 18
		label.Position = UDim2.fromOffset(pos.X, pos.Y - 20)
		label.Size = UDim2.fromOffset(60, 20)
		label.Parent = crosshairGui
		task.delay(0.8, function()
			pcall(function() label:Destroy() end)
		end)
	end

	Overlays = larp.Categories.Render:CreateModule({
		Name = 'Overlays',
		Function = function(callback)
			if callback then
				screenGui = Instance.new('ScreenGui')
				screenGui.Name = 'DaHoodOverlays'
				screenGui.ResetOnSpawn = false
				screenGui.IgnoreGuiInset = true
				screenGui.Parent = lplr:WaitForChild('PlayerGui')
				crosshairGui = Instance.new('ScreenGui')
				crosshairGui.Name = 'DaHoodCrosshair'
				crosshairGui.ResetOnSpawn = false
				crosshairGui.IgnoreGuiInset = true
				crosshairGui.Parent = lplr:WaitForChild('PlayerGui')
				fovFrame = makeFrame(screenGui, FOVColor.Value, UDim2.fromScale(0.2, 0.2), UDim2.fromScale(0.5, 0.5))
				fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
				fovFrame.BackgroundTransparency = 1
				local radius = Instance.new('UICorner')
				radius.CornerRadius = UDim.new(1, 0)
				radius.Parent = fovFrame
				-- crosshair lines
				local chLines = {}
				for _, spec in {{'H', UDim2.fromOffset(12, 2), UDim2.fromOffset(-6, -1)}, {'V', UDim2.fromOffset(2, 12), UDim2.fromOffset(-1, -6)}} do
					local l = makeFrame(crosshairGui, CrosshairColor.Value, spec[2], UDim2.fromScale(0.5, 0.5))
					l.AnchorPoint = Vector2.new(0.5, 0.5)
					table.insert(chLines, l)
				end
				local function updateCh()
					for _, l in chLines do
						l.Visible = Crosshair.Enabled
						l.BackgroundColor3 = CrosshairColor.Value
						l.Size = UDim2.fromOffset(CrosshairSize.Value + (l.Size.X.Offset > l.Size.Y.Offset and 0 or 0), CrosshairSize.Value + (l.Size.X.Offset > l.Size.Y.Offset and 0 or 0))
					end
				end
				local function updateFov()
					fovFrame.Visible = FOVCircle.Enabled
					fovFrame.BackgroundColor3 = FOVColor.Value
					local size = FOVSize.Value / 100
					fovFrame.Size = UDim2.fromScale(size, size)
				end
				damageConn = entitylib.Events.EntityUpdated:Connect(function(ent)
					if ent == entitylib.character and ent.Humanoid then
						local newHealth = ent.Humanoid.Health
						if newHealth < lastHealth then
							showHitmarker()
							spawnDamageIndicator(lastHealth - newHealth, ent.RootPart.Position)
							if newHealth <= 0 and KillEffect.Enabled then
								notif('KILL', 2, 'info')
							end
						end
						lastHealth = newHealth
					end
				end)
				repeat
					runService.RenderStepped:Wait()
					updateFov()
					updateCh()
					if Hitmarker.Enabled then
						-- hit detection via own damage dealt would need server events; keep manual
					end
				until not Overlays.Enabled
				if damageConn then damageConn:Disconnect() end
				pcall(function() screenGui:Destroy() end)
				pcall(function() crosshairGui:Destroy() end)
			end
		end,
		Tooltip = 'Screen overlays: FOV circle, crosshair, hitmarker, damage indicators'
	})
	FOVCircle = Overlays:CreateToggle({Name = 'FOV Circle', Default = true})
	FOVSize = Overlays:CreateSlider({Name = 'FOV Size', Min = 1, Max = 100, Default = 10, Decimal = 10, Suffix = '%'})
	FOVColor = Overlays:CreateColorSlider({Name = 'FOV Color', Default = Color3.fromRGB(255, 255, 255)})
	Crosshair = Overlays:CreateToggle({Name = 'Crosshair', Default = true})
	CrosshairColor = Overlays:CreateColorSlider({Name = 'Crosshair Color', Default = Color3.fromRGB(0, 255, 0)})
	CrosshairSize = Overlays:CreateSlider({Name = 'Crosshair Size', Min = 2, Max = 30, Default = 6, Suffix = 'px'})
	Hitmarker = Overlays:CreateToggle({Name = 'Hitmarker', Default = true})
	HitmarkerColor = Overlays:CreateColorSlider({Name = 'Hitmarker Color', Default = Color3.fromRGB(255, 255, 255)})
	HitmarkerTime = Overlays:CreateSlider({Name = 'Hitmarker Time', Min = 0.05, Max = 1, Default = 0.2, Decimal = 100, Suffix = 'seconds'})
	HitEffect = Overlays:CreateToggle({Name = 'Hit Effect', Default = false})
	KillEffect = Overlays:CreateToggle({Name = 'Kill Effect', Default = false})
	DamageIndicator = Overlays:CreateToggle({Name = 'Damage Indicator', Default = true})
end)
run(function()
	local HealthHUD
	local ArmorHUD
	local hudGui
	local healthFill
	local armorFill
	local healthLabel
	local armorLabel

	HealthHUD = larp.Categories.Inventory:CreateModule({
		Name = 'Better Health Bar',
		Function = function(callback)
			if callback then
				if not hudGui then
					hudGui = Instance.new('ScreenGui')
					hudGui.Name = 'DaHoodHUD'
					hudGui.ResetOnSpawn = false
					hudGui.IgnoreGuiInset = true
					hudGui.Parent = lplr:WaitForChild('PlayerGui')
					local holder = Instance.new('Frame')
					holder.Size = UDim2.fromOffset(160, 50)
					holder.Position = UDim2.new(0, 10, 1, -60)
					holder.AnchorPoint = Vector2.new(0, 1)
					holder.BackgroundTransparency = 0.4
					holder.BackgroundColor3 = Color3.new(0, 0, 0)
					holder.BorderSizePixel = 0
					holder.Parent = hudGui
					local hbg = Instance.new('Frame')
					hbg.Size = UDim2.fromScale(1, 0.35)
					hbg.Position = UDim2.fromScale(0, 0.1)
					hbg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
					hbg.BorderSizePixel = 0
					hbg.Parent = holder
					healthFill = Instance.new('Frame')
					healthFill.Size = UDim2.fromScale(1, 1)
					healthFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
					healthFill.BorderSizePixel = 0
					healthFill.Parent = hbg
					healthLabel = Instance.new('TextLabel')
					healthLabel.Size = UDim2.fromScale(1, 0.35)
					healthLabel.Position = UDim2.fromScale(0, -0.4)
					healthLabel.BackgroundTransparency = 1
					healthLabel.Font = Enum.Font.GothamBold
					healthLabel.TextScaled = true
					healthLabel.TextColor3 = Color3.new(1, 1, 1)
					healthLabel.Parent = holder
					local abg = Instance.new('Frame')
					abg.Size = UDim2.fromScale(1, 0.35)
					abg.Position = UDim2.fromScale(0, 0.55)
					abg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
					abg.BorderSizePixel = 0
					abg.Parent = holder
					armorFill = Instance.new('Frame')
					armorFill.Size = UDim2.fromScale(1, 1)
					armorFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
					armorFill.BorderSizePixel = 0
					armorFill.Parent = abg
					armorLabel = Instance.new('TextLabel')
					armorLabel.Size = UDim2.fromScale(1, 0.35)
					armorLabel.Position = UDim2.fromScale(0, 0.6)
					armorLabel.BackgroundTransparency = 1
					armorLabel.Font = Enum.Font.GothamBold
					armorLabel.TextScaled = true
					armorLabel.TextColor3 = Color3.new(1, 1, 1)
					armorLabel.Parent = holder
				end
				repeat
					task.wait(0.05)
					if entitylib.isAlive then
						local hum = entitylib.character.Humanoid
						local be = getBodyEffects(entitylib.character.Character)
						local armor = be and be:FindFirstChild('Armor') and be.Armor.Value or 0
						local maxArmor = replicatedStorage:FindFirstChild('MaxArmor') and replicatedStorage.MaxArmor.Value or 100
						local hp = hum.Health / hum.MaxHealth
						local ap = math.clamp(armor / maxArmor, 0, 1)
						healthFill.Size = UDim2.fromScale(math.clamp(hp, 0, 1), 1)
						armorFill.Size = UDim2.fromScale(ap, 1)
						healthLabel.Text = 'HP '..math.floor(hum.Health)..'/'..math.floor(hum.MaxHealth)
						armorLabel.Text = 'ARMOR '..math.floor(armor)
						healthFill.BackgroundColor3 = hp > 0.5 and Color3.fromRGB(0, 200, 0) or (hp > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 0, 0))
					end
				until not HealthHUD.Enabled
			end
		end,
		Tooltip = 'Clean health bar HUD'
	})

	ArmorHUD = larp.Categories.Inventory:CreateModule({
		Name = 'Better Armor Bar',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					if entitylib.isAlive and hudGui then
						hudGui.Visible = true
					end
				until not ArmorHUD.Enabled
				if hudGui and not HealthHUD.Enabled then
					hudGui.Visible = false
				end
			end
		end,
		Tooltip = 'Shows the armor bar (requires Better Health Bar)'
	})
end)
local weather = {}

function weather.makeParticle(color, texture, size, rate, speed, spread, lifetime, parent)
	local p = Instance.new('ParticleEmitter')
	p.Texture = texture
	p.Color = ColorSequence.new(color)
	p.Size = NumberSequence.new(size)
	p.Rate = rate
	p.Speed = NumberSequence.new(speed)
	p.SpreadAngle = Vector2.new(spread, spread)
	p.Lifetime = NumberSequence.new(lifetime)
	p.Parent = parent
	return p
end

run(function()
	local Rain
	local RainAmount
	local RainColor
	local Snow
	local SnowAmount
	local Thunderstorm
	local FogMod
	local FogAmount
	local HeavyFog
	local Wind
	local WindStrength
	local Clouds
	local Lightning
	local Sunset
	local Night
	local Day
	local Moonlight
	local Aurora
	local FallingLeaves
	local FallingPetals
	local DustStorm
	local Ash
	local Fireflies
	local StarrySky
	local MeteorShower
	local Flood
	local FloodSpeed
	local FloodHeight
	local rainParts = {}
	local floodPart
	local meteorParts = {}

	local function clearParticles()
		for _, p in ipairs(rainParts) do
			pcall(function() p:Destroy() end)
		end
		table.clear(rainParts)
	end

	local function makeRain()
		if not entitylib.isAlive then return end
		local char = entitylib.character.Character
		local root = char:FindFirstChild('HumanoidRootPart') or char:FindFirstChildOfClass('BasePart')
		if not root then return end
		local parent = workspace.Terrain
		local p = weather.makeParticle(RainColor.Value, 'rbxasset://textures/particles/falling_star.dds', 0.3, RainAmount.Value, {40, 50}, 5, {2, 3}, parent)
		p.LightEmission = 0.2
		p.LightInfluence = 0
		p.Rotation = NumberSequence.new(0)
		p.RotSpeed = NumberSequence.new(0)
		p.Parent = parent
		table.insert(rainParts, p)
		-- local rain aura that follows player
		local aura = Instance.new('ParticleEmitter')
		aura.Texture = 'rbxasset://textures/particles/falling_star.dds'
		aura.Color = ColorSequence.new(RainColor.Value)
		aura.Size = NumberSequence.new(0.3)
		aura.Rate = RainAmount.Value * 0.4
		aura.Speed = NumberSequence.new(35)
		aura.Lifetime = NumberSequence.new(1.5)
		aura.SpreadAngle = Vector2.new(15, 15)
		aura.Parent = root
		table.insert(rainParts, aura)
	end

	local function makeSnow()
		if not entitylib.isAlive then return end
		local root = entitylib.character.RootPart
		local p = weather.makeParticle(Color3.fromRGB(255, 255, 255), 'rbxasset://textures/particles/snow.dds', 0.6, SnowAmount.Value, {2, 4}, 10, {4, 6}, workspace.Terrain)
		p.Rotation = NumberSequence.new(0)
		table.insert(rainParts, p)
		local aura = Instance.new('ParticleEmitter')
		aura.Texture = 'rbxasset://textures/particles/snow.dds'
		aura.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		aura.Size = NumberSequence.new(0.6)
		aura.Rate = SnowAmount.Value * 0.3
		aura.Speed = NumberSequence.new(3)
		aura.Lifetime = NumberSequence.new(4)
		aura.SpreadAngle = Vector2.new(20, 20)
		aura.Parent = root
		table.insert(rainParts, aura)
	end

	local function makeAurora()
		local sky = lighting:FindFirstChildOfClass('Sky')
		if not sky then
			sky = Instance.new('Sky')
			sky.Parent = lighting
		end
		sky.SkyboxUp = 'rbxassetid://5017738970'
		sky.SkyboxDown = 'rbxassetid://5017737427'
		sky.SkyboxLeft = 'rbxassetid://5017736827'
		sky.SkyboxRight = 'rbxassetid://5017736827'
		sky.SkyboxBack = 'rbxassetid://5017737658'
		sky.SkyboxFront = 'rbxassetid://5017737658'
		lighting.Brightness = 0.5
	end

	local function makeStarrySky()
		local sky = lighting:FindFirstChildOfClass('Sky')
		if not sky then
			sky = Instance.new('Sky')
			sky.Parent = lighting
		end
		sky.SkyboxUp = 'rbxassetid://5668571034'
		sky.SkyboxDown = 'rbxassetid://5668571034'
		sky.SkyboxLeft = 'rbxassetid://5668571034'
		sky.SkyboxRight = 'rbxassetid://5668571034'
		sky.SkyboxBack = 'rbxassetid://5668571034'
		sky.SkyboxFront = 'rbxassetid://5668571034'
		lighting.Brightness = 0.2
	end

	local function makeFlood()
		if floodPart then
			pcall(function() floodPart:Destroy() end)
		end
		floodPart = Instance.new('Part')
		floodPart.Name = 'Flood'
		floodPart.Anchored = true
		floodPart.CanCollide = true
		floodPart.CanQuery = false
		floodPart.CanTouch = true
		floodPart.Transparency = 0.4
		floodPart.Material = Enum.Material.Water
		floodPart.Size = Vector3.new(500, 1, 500)
		floodPart.Position = Vector3.new(0, 0, 0)
		floodPart.Parent = workspace
	end

	Rain = larp.Categories.World:CreateModule({
		Name = 'Rain',
		Function = function(callback)
			if callback then
				makeRain()
				repeat
					task.wait(0.5)
					if #rainParts < 4 then
						makeRain()
					end
				until not Rain.Enabled
				clearParticles()
			end
		end,
		Tooltip = 'Realistic rain'
	})
	RainAmount = Rain:CreateSlider({Name = 'Amount', Min = 10, Max = 500, Default = 150, Suffix = 'particles'})
	RainColor = Rain:CreateColorSlider({Name = 'Color', Default = Color3.fromRGB(120, 160, 255)})

	Snow = larp.Categories.World:CreateModule({
		Name = 'Snow',
		Function = function(callback)
			if callback then
				makeSnow()
				repeat
					task.wait(0.5)
					if #rainParts < 4 then
						makeSnow()
					end
				until not Snow.Enabled
				clearParticles()
			end
		end,
		Tooltip = 'Falling snow'
	})
	SnowAmount = Snow:CreateSlider({Name = 'Amount', Min = 10, Max = 300, Default = 80, Suffix = 'particles'})

	Thunderstorm = larp.Categories.World:CreateModule({
		Name = 'Thunderstorm',
		Function = function(callback)
if callback then
				makeRain()
				repeat
					task.wait()
					lighting.Brightness = 0.4
					local lightningFlash = Instance.new('PointLight')
					lightningFlash.Color = Color3.new(1, 1, 1)
					lightningFlash.Brightness = 0
					lightningFlash.Range = 200
					lightningFlash.Parent = gameCamera
					local t = tweenService:Create(lightningFlash, TweenInfo.new(0.1), {Brightness = 5})
					t:Play()
					task.wait(0.15)
					local t2 = tweenService:Create(lightningFlash, TweenInfo.new(0.3), {Brightness = 0})
					t2:Play()
					task.wait(math.random(2, 6))
					pcall(function() lightningFlash:Destroy() end)
				until not Thunderstorm.Enabled
				lighting.Brightness = 1
				clearParticles()
			end
		end,
		Tooltip = 'Rain + lightning flashes'
	})

	FogMod = larp.Categories.World:CreateModule({
		Name = 'Fog',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					lighting.FogStart = 10
					lighting.FogEnd = FogAmount.Value
					lighting.FogColor = Color3.fromRGB(180, 180, 180)
				until not FogMod.Enabled
				lighting.FogStart = 0
				lighting.FogEnd = 500
			end
		end,
		Tooltip = 'Fog effect'
	})
	FogAmount = FogMod:CreateSlider({Name = 'Fog Distance', Min = 20, Max = 300, Default = 100, Suffix = function(val) return val == 1 and 'stud' or 'studs' end})

	HeavyFog = larp.Categories.World:CreateModule({
		Name = 'Heavy Fog',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					lighting.FogStart = 0
					lighting.FogEnd = 30
					lighting.FogColor = Color3.fromRGB(140, 140, 140)
				until not HeavyFog.Enabled
				lighting.FogEnd = 500
			end
		end,
		Tooltip = 'Dense fog'
	})

	Wind = larp.Categories.World:CreateModule({
		Name = 'Wind',
		Function = function(callback)
			if callback then
				local p = weather.makeParticle(Color3.fromRGB(200, 200, 200), 'rbxasset://textures/particles/smoke_main.dds', 1, 20, {10, 20}, 5, {2, 3}, workspace.Terrain)
				table.insert(rainParts, p)
				repeat
					task.wait()
					p.VelocityInheritance = WindStrength.Value
				until not Wind.Enabled
				clearParticles()
			end
		end,
		Tooltip = 'Wind effect'
	})
	WindStrength = Wind:CreateSlider({Name = 'Strength', Min = 0, Max = 10, Default = 3, Decimal = 10})

	Clouds = larp.Categories.World:CreateModule({
		Name = 'Clouds',
		Function = function(callback)
			if callback then
				local sky = lighting:FindFirstChildOfClass('Sky') or Instance.new('Sky')
				sky.Parent = lighting
				repeat
					task.wait()
					sky.SkyboxUp = 'rbxassetid://5017738970'
					sky.SkyboxDown = 'rbxassetid://5017737427'
					sky.SkyboxLeft = 'rbxassetid://5017736827'
					sky.SkyboxRight = 'rbxassetid://5017736827'
					sky.SkyboxBack = 'rbxassetid://5017737658'
					sky.SkyboxFront = 'rbxassetid://5017737658'
				until not Clouds.Enabled
			end
		end,
		Tooltip = 'Cloudy sky'
	})

	Lightning = larp.Categories.World:CreateModule({
		Name = 'Lightning',
		Function = function(callback)
			if callback then
				repeat
					task.wait(math.random(3, 10))
					local flash = Instance.new('PointLight')
					flash.Color = Color3.new(1, 1, 1)
					flash.Range = 200
					flash.Parent = gameCamera
					tweenService:Create(flash, TweenInfo.new(0.1), {Brightness = 5}):Play()
					task.wait(0.15)
					tweenService:Create(flash, TweenInfo.new(0.3), {Brightness = 0}):Play()
					task.wait(0.5)
					pcall(function() flash:Destroy() end)
				until not Lightning.Enabled
			end
		end,
		Tooltip = 'Random lightning strikes'
	})

	Sunset = larp.Categories.World:CreateModule({
		Name = 'Sunset',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					lighting.ClockTime = 18
					lighting.Brightness = 0.8
					lighting.Ambient = Color3.fromRGB(255, 160, 80)
				until not Sunset.Enabled
			end
		end,
		Tooltip = 'Sunset time + warm light'
	})

	Night = larp.Categories.World:CreateModule({
		Name = 'Night',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					lighting.ClockTime = 0
					lighting.Brightness = 0.1
				until not Night.Enabled
			end
		end,
		Tooltip = 'Night time'
	})

	Day = larp.Categories.World:CreateModule({
		Name = 'Day',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					lighting.ClockTime = 14
					lighting.Brightness = 1
				until not Day.Enabled
			end
		end,
		Tooltip = 'Day time'
	})

	Moonlight = larp.Categories.World:CreateModule({
		Name = 'Moonlight',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
					lighting.ClockTime = 0
					lighting.Brightness = 0.3
					lighting.Ambient = Color3.fromRGB(60, 80, 160)
				until not Moonlight.Enabled
			end
		end,
		Tooltip = 'Blue moonlight'
	})

	Aurora = larp.Categories.World:CreateModule({
		Name = 'Aurora',
		Function = function(callback)
			if callback then
				makeAurora()
				local p = weather.makeParticle(Color3.fromRGB(0, 255, 180), 'rbxasset://textures/particles/sparkles_main.dds', 0.5, 30, {1, 3}, 20, {3, 5}, workspace.Terrain)
				table.insert(rainParts, p)
				repeat
					task.wait()
				until not Aurora.Enabled
				clearParticles()
			end
		end,
		Tooltip = 'Aurora borealis sky + particles'
	})

	FallingLeaves = larp.Categories.World:CreateModule({
		Name = 'Falling Leaves',
		Function = function(callback)
			if callback then
				local p = weather.makeParticle(Color3.fromRGB(120, 200, 80), 'rbxasset://textures/particles/leaf_main.dds', 1, 20, {2, 5}, 15, {3, 5}, workspace.Terrain)
				table.insert(rainParts, p)
				repeat
					task.wait()
				until not FallingLeaves.Enabled
				clearParticles()
			end
		end,
		Tooltip = 'Falling leaves'
	})

	FallingPetals = larp.Categories.World:CreateModule({
		Name = 'Falling Petals',
		Function = function(callback)
			if callback then
				local p = weather.makeParticle(Color3.fromRGB(255, 180, 220), 'rbxasset://textures/particles/leaf_main.dds', 0.8, 25, {2, 4}, 12, {3, 5}, workspace.Terrain)
				table.insert(rainParts, p)
				repeat
					task.wait()
				until not FallingPetals.Enabled
				clearParticles()
			end
		end,
		Tooltip = 'Falling cherry petals'
	})

	DustStorm = larp.Categories.World:CreateModule({
		Name = 'Dust Storm',
		Function = function(callback)
			if callback then
				local p = weather.makeParticle(Color3.fromRGB(150, 120, 80), 'rbxasset://textures/particles/smoke_main.dds', 2, 40, {10, 20}, 20, {2, 3}, workspace.Terrain)
				table.insert(rainParts, p)
				repeat
					task.wait()
				until not DustStorm.Enabled
				clearParticles()
			end
		end,
		Tooltip = 'Dust storm'
	})

	Ash = larp.Categories.World:CreateModule({
		Name = 'Ash',
		Function = function(callback)
			if callback then
				local p = weather.makeParticle(Color3.fromRGB(60, 60, 60), 'rbxasset://textures/particles/ash_main.dds', 0.5, 30, {1, 3}, 10, {3, 5}, workspace.Terrain)
				table.insert(rainParts, p)
				repeat
					task.wait()
				until not Ash.Enabled
				clearParticles()
			end
		end,
		Tooltip = 'Falling ash'
	})

	Fireflies = larp.Categories.World:CreateModule({
		Name = 'Fireflies',
		Function = function(callback)
			if callback then
				local p = weather.makeParticle(Color3.fromRGB(255, 240, 150), 'rbxasset://textures/particles/sparkles_main.dds', 0.4, 15, {0, 2}, 360, {2, 4}, workspace.Terrain)
				table.insert(rainParts, p)
				repeat
					task.wait()
				until not Fireflies.Enabled
				clearParticles()
			end
		end,
		Tooltip = 'Glowing fireflies'
	})

	StarrySky = larp.Categories.World:CreateModule({
		Name = 'Starry Sky',
		Function = function(callback)
			if callback then
				makeStarrySky()
				repeat
					task.wait()
				until not StarrySky.Enabled
			end
		end,
		Tooltip = 'Starry night sky'
	})

	MeteorShower = larp.Categories.World:CreateModule({
		Name = 'Meteor Shower',
		Function = function(callback)
			if callback then
				repeat
					task.wait(math.random(1, 3))
					local root = entitylib.isAlive and entitylib.character.RootPart or nil
					if not root then continue end
					local meteor = Instance.new('Part')
					meteor.Anchored = true
					meteor.CanCollide = false
					meteor.Shape = Enum.PartType.Ball
					meteor.Material = Enum.Material.Neon
					meteor.Color = Color3.fromRGB(255, 150, 50)
					meteor.Size = Vector3.new(3, 3, 3)
					local x = root.Position.X + math.random(-200, 200)
					local z = root.Position.Z + math.random(-200, 200)
					meteor.Position = Vector3.new(x, 200, z)
					meteor.Parent = workspace
					table.insert(meteorParts, meteor)
					local goal = Vector3.new(x, 5, z)
					local t = tweenService:Create(meteor, TweenInfo.new(2, Enum.EasingStyle.Linear), {Position = goal})
					t:Play()
					task.spawn(function()
						task.wait(2.2)
						pcall(function() meteor:Destroy() end)
						local ind = table.find(meteorParts, meteor)
						if ind then table.remove(meteorParts, ind) end
					end)
				until not MeteorShower.Enabled
			end
		end,
		Tooltip = 'Meteors crashing down'
	})

	Flood = larp.Categories.World:CreateModule({
		Name = 'Flood',
		Function = function(callback)
			if callback then
				makeFlood()
				local startY = floodPart.Position.Y
				repeat
					task.wait(0.1)
					if floodPart then
						local target = math.min(floodPart.Position.Y + FloodSpeed.Value, FloodHeight.Value)
						floodPart.Position = Vector3.new(0, target, 0)
						floodPart.Transparency = 0.3
					end
				until not Flood.Enabled
				if floodPart then
					pcall(function() floodPart:Destroy() end)
				end
				floodPart = nil
			end
		end,
		Tooltip = 'Rising water flood over the map'
	})
	FloodSpeed = Flood:CreateSlider({Name = 'Rise Speed', Min = 0.1, Max = 5, Default = 0.5, Decimal = 10, Suffix = function(val) return val == 1 and 'stud/s' or 'studs/s' end})
	FloodHeight = Flood:CreateSlider({Name = 'Max Height', Min = 0, Max = 300, Default = 50, Suffix = function(val) return val == 1 and 'stud' or 'studs' end})
end)
