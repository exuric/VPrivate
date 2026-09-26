--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local larp = shared.larp or getgenv().larp or _G.larp
local entitylib = larp.Libraries.entity

local AttackRemote = replicatedStorage:WaitForChild('Remotes'):WaitForChild('Attack')
getgenv().LarpSFP = {swings = 0, reachHooks = 0}

local function currentHitMod()
	local ok, mod = pcall(function()
		return require(lplr.PlayerGui:WaitForChild('InputHandling', 10).HitDetection)
	end)
	if ok and type(mod) == 'table' then return mod end
	return nil
end

local function validTarget(ent, targets, maxDist, selfpos)
	if not ent or not ent.RootPart then return false end
	if ent.Player == lplr then return false end
	local isP = ent.Player ~= nil
	if isP and not targets.Players.Enabled then return false end
	if ent.NPC and not targets.NPCs.Enabled then return false end
	if ent.Targetable == false then return false end
	if ent.Health and ent.MaxHealth and ent.Health <= 0 then return false end
	if entitylib.isVulnerable and not entitylib.isVulnerable(ent) then return false end
	if maxDist and selfpos then
		if (ent.RootPart.Position - selfpos).Magnitude > maxDist then return false end
	end
	return true
end

run(function()
	local KillAura
	local CPS
	local Range
	local Targets
	KillAura = larp.Categories.Combat:CreateModule({
		Name = 'KillAura',
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						if entitylib.isAlive then
							local char = entitylib.character
							local hrp = char and char.HumanoidRootPart
							local model = char and char.Character
							if hrp and model then
								local selfpos = hrp.Position
								local best, bestd = nil, Range.Value
								for _, ent in entitylib.List do
									if validTarget(ent, Targets, Range.Value, selfpos) then
										local d = (ent.RootPart.Position - selfpos).Magnitude
										if d < bestd then best, bestd = ent, d end
									end
								end
								if best then
									local tp = best.RootPart.Position
									local flat = Vector3.new(tp.X - selfpos.X, 0, tp.Z - selfpos.Z)
									if flat.Magnitude > 0.01 then
										local unit = flat.Unit
										local hm = currentHitMod()
										if hm then
											local okH, _, part = pcall(hm.GetHit, selfpos, unit, {model}, Range.Value)
											if okH and part then
												getgenv().LarpSFP.swings += 1
												pcall(function() AttackRemote:FireServer(unit, part) end)
											end
										end
									end
								end
							end
						end
						task.wait(1 / math.max(1, CPS.Value))
					until not KillAura.Enabled
				end)
			end
		end,
		Tooltip = 'Automatically attacks nearby enemies.'
	})
	CPS = KillAura:CreateSlider({
		Name = 'CPS',
		Min = 1,
		Max = 15,
		Default = 7,
		Tooltip = 'Attacks per second'
	})
	Range = KillAura:CreateSlider({
		Name = 'Range',
		Min = 4,
		Max = 15,
		Default = 7,
		Suffix = 'studs',
		Tooltip = 'How far away to attack from'
	})
	Targets = KillAura:CreateTargets({
		Players = true
	})
	larp:QueueSave()
end)

run(function()
	local Reach
	local Range
	local state = {mod = nil, orig = nil}
	local function wrapped(origin, unit, ignore, range)
		return state.orig(origin, unit, ignore, Reach.Enabled and Range.Value or range)
	end
	local function hookNow()
		local m = currentHitMod()
		if m and m.GetHit ~= wrapped then
			if state.mod and state.mod ~= m and state.orig then
				pcall(function() state.mod.GetHit = state.orig end)
			end
			state.mod, state.orig = m, m.GetHit
			m.GetHit = wrapped
			getgenv().LarpSFP.reachHooks += 1
		end
	end
	Reach = larp.Categories.Combat:CreateModule({
		Name = 'Reach',
		Function = function(callback)
			if callback then
				hookNow()
				Reach:Clean(lplr.CharacterAdded:Connect(function()
					if Reach.Enabled then hookNow() end
				end))
			else
				if state.mod and state.orig then
					pcall(function() state.mod.GetHit = state.orig end)
				end
				state.mod, state.orig = nil, nil
			end
		end,
		Tooltip = 'Extends your attack range.'
	})
	Range = Reach:CreateSlider({
		Name = 'Range',
		Min = 6,
		Max = 20,
		Default = 12,
		Suffix = 'studs',
		Tooltip = 'Attack range for your clicks'
	})
	larp:QueueSave()
end)

run(function()
	local AimAssist
	local FOV
	local Smooth
	local MaxRange
	local RequireMouse
	local Targets
	AimAssist = larp.Categories.Combat:CreateModule({
		Name = 'AimAssist',
		Function = function(callback)
			if callback then
				AimAssist:Clean(runService.RenderStepped:Connect(function()
					if not AimAssist.Enabled or not entitylib.isAlive then return end
					if RequireMouse.Enabled and not inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
					local char = entitylib.character
					local hrp = char and char.HumanoidRootPart
					if not hrp then return end
					local cam = workspace.CurrentCamera
					if not cam then return end
					local mloc = inputService:GetMouseLocation()
					local selfpos = hrp.Position
					local best, bestd = nil, FOV.Value
					for _, ent in entitylib.List do
						if validTarget(ent, Targets, MaxRange.Value, selfpos) then
							local hp = ent.RootPart.Position
							if typeof(ent.Head) == 'Instance' then hp = ent.Head.Position end
							local sp, vis = cam:WorldToViewportPoint(hp)
							if vis then
								local d = (Vector2.new(sp.X, sp.Y) - mloc).Magnitude
								if d < bestd then best, bestd = ent, d end
							end
						end
					end
					if best and best.RootPart then
						local tp = best.RootPart.Position
						if typeof(best.Head) == 'Instance' then tp = best.Head.Position end
						local cur = cam.CFrame
						cam.CFrame = cur:Lerp(CFrame.lookAt(cur.Position, tp), math.clamp(Smooth.Value / 100, 0, 1))
					end
				end))
			end
		end,
		Tooltip = 'Smoothly aims your camera at nearby enemies.'
	})
	FOV = AimAssist:CreateSlider({
		Name = 'FOV',
		Min = 20,
		Max = 300,
		Default = 120,
		Suffix = 'px',
		Tooltip = 'How close to your cursor a target must be'
	})
	Smooth = AimAssist:CreateSlider({
		Name = 'Smoothing',
		Min = 5,
		Max = 100,
		Default = 30,
		Suffix = '%',
		Darker = true,
		Tooltip = 'How strongly the camera pulls'
	})
	MaxRange = AimAssist:CreateSlider({
		Name = 'Range',
		Min = 10,
		Max = 150,
		Default = 60,
		Suffix = 'studs',
		Darker = true,
		Tooltip = 'Max target distance'
	})
	RequireMouse = AimAssist:CreateToggle({
		Name = 'Require Mouse Down',
		Default = true,
		Tooltip = 'Only assists while holding left mouse'
	})
	Targets = AimAssist:CreateTargets({
		Players = true
	})
	larp:QueueSave()
end)
