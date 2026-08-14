--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local larp = shared.larp or getgenv().larp or _G.larp
local entitylib = larp.Libraries.entity
local sessioninfo = larp.Libraries.sessioninfo
local bedwars = {}

local function notif(...)
	return larp:CreateNotification(...)
end

run(function()
	local function dumpRemote(tab)
		local ind = table.find(tab, 'Client')
		return ind and tab[ind + 1] or ''
	end

	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function() return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9) end)
		if KnitInit then break end
		task.wait()
	until KnitInit
	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end
	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client

	bedwars = setmetatable({
		Client = Client,
		CrateItemMeta = debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3),
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	larp:Clean(function()
		table.clear(bedwars)
	end)
end)

for _, v in larp.Modules do
	if v.Category == 'Combat' or v.Category == 'Minigames' then
		larp:Remove(i)
	end
end

run(function()
	local Sprint
	local old
	
	Sprint = larp.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					bedwars.SprintController:startSprinting()
					return call
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() bedwars.SprintController:stopSprinting() end))
				bedwars.SprintController:stopSprinting()
			else
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.'
	})
end)

run(function()
	local AutoGamble
	
	AutoGamble = larp.Categories.Minigames:CreateModule({
		Name = 'AutoGamble',
		Function = function(callback)
			if callback then
				AutoGamble:Clean(bedwars.Client:GetNamespace('RewardCrate'):Get('CrateOpened'):Connect(function(data)
					if data.openingPlayer == lplr then
						local tab = bedwars.CrateItemMeta[data.reward.itemType] or {displayName = data.reward.itemType or 'unknown'}
						notif('AutoGamble', 'Won '..tab.displayName, 5)
					end
				end))
	
				repeat
					if not bedwars.CrateAltarController.activeCrates[1] then
						for _, v in bedwars.Store:getState().Consumable.inventory do
							if v.consumable:find('crate') then
								bedwars.CrateAltarController:pickCrate(v.consumable, 1)
								task.wait(1.2)
								if bedwars.CrateAltarController.activeCrates[1] and bedwars.CrateAltarController.activeCrates[1][2] then
									bedwars.Client:GetNamespace('RewardCrate'):Get('OpenRewardCrate'):SendToServer({
										crateId = bedwars.CrateAltarController.activeCrates[1][2].attributes.crateId
									})
								end
								break
							end
						end
					end
					task.wait(1)
				until not AutoGamble.Enabled
			end
		end,
		Tooltip = 'Automatically opens lucky crates, piston inspired!'
	})
end)

run(function()
	local runService = cloneref(game:GetService('RunService'))
	local tweenService = cloneref(game:GetService('TweenService'))
	local anim
	local asset
	local trackingConnection
	local lastPosition
	local NightmareEmote
	local cachedRootPart
	local cachedHumanoid
	local lastValidationCheck = 0

	local function findNightmareAsset()
		for i = 1, 50 do
			local assets = replicatedStorage:FindFirstChild('Assets')
			local effects = assets and assets:FindFirstChild('Effects')
			local target = effects and effects:FindFirstChild('NightmareEmote')
			if target then
				return target
			end
			task.wait(0.1)
		end
		return nil
	end

	NightmareEmote = larp.Categories.World:CreateModule({
		Name = 'NightmareEmote',
		Function = function(call)
			if call then
				local ok, GameQueryUtil = pcall(function()
					return require(game:GetService('ReplicatedStorage'):WaitForChild('rbxts_include'):WaitForChild('node_modules'):WaitForChild('@easy-games'):WaitForChild('game-core').out).GameQueryUtil
				end)
				if not ok or not GameQueryUtil then
					local backup = {}
					function backup:setQueryIgnored() end
					GameQueryUtil = backup
				end

				local player = playersService.LocalPlayer
				local character = player.Character

				if not character then
					NightmareEmote:Toggle()
					return
				end

				local humanoid = character:WaitForChild('Humanoid')
				local rootPart = character.PrimaryPart or character:FindFirstChild('HumanoidRootPart')

				if not rootPart then
					NightmareEmote:Toggle()
					return
				end

				local source = findNightmareAsset()
				if not source then
					notif('Larp V4', 'NightmareEmote effect not found', 4, 'warning')
					NightmareEmote:Toggle()
					return
				end

				cachedRootPart = rootPart
				cachedHumanoid = humanoid
				lastPosition = rootPart.Position
				lastValidationCheck = 0

				local cloned = source:Clone()
				asset = cloned
				cloned.Parent = workspace

				local descendants = cloned:GetDescendants()
				for _, part in ipairs(descendants) do
					if part:IsA('BasePart') then
						GameQueryUtil:setQueryIgnored(part, true)
						part.CanCollide = false
						part.Anchored = true
					end
				end

				local outer = cloned:FindFirstChild('Outer')
				if outer then
					tweenService:Create(outer, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = outer.Orientation + Vector3.new(0, 360, 0)
					}):Play()
				end

				local middle = cloned:FindFirstChild('Middle')
				if middle then
					tweenService:Create(middle, TweenInfo.new(12.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = middle.Orientation + Vector3.new(0, -360, 0)
					}):Play()
				end

				anim = Instance.new('Animation')
				anim.AnimationId = 'rbxassetid://9191822700'
				anim = humanoid:LoadAnimation(anim)
				anim:Play()

				local movementThresholdSq = 0.1 * 0.1

				trackingConnection = runService.RenderStepped:Connect(function()
					if not asset or not asset.Parent then
						if trackingConnection then
							trackingConnection:Disconnect()
						end
						return
					end

					local currentTime = tick()

					if (currentTime - lastValidationCheck) > 0.5 then
						if not character or not character.Parent then
							asset:Destroy()
							asset = nil
							if trackingConnection then
								trackingConnection:Disconnect()
							end
							NightmareEmote:Toggle()
							return
						end

						if not cachedRootPart or not cachedRootPart.Parent then
							cachedRootPart = character.PrimaryPart or character:FindFirstChild('HumanoidRootPart')
						end

						if not cachedHumanoid or not cachedHumanoid.Parent then
							cachedHumanoid = character:FindFirstChildOfClass('Humanoid')
						end

						if not cachedRootPart or not cachedHumanoid or cachedHumanoid.Health <= 0 then
							asset:Destroy()
							asset = nil
							if trackingConnection then
								trackingConnection:Disconnect()
							end
							NightmareEmote:Toggle()
							return
						end

						lastValidationCheck = currentTime
					end

					if lastPosition and cachedRootPart then
						local currentPosition = cachedRootPart.Position
						local dx = currentPosition.X - lastPosition.X
						local dy = currentPosition.Y - lastPosition.Y
						local dz = currentPosition.Z - lastPosition.Z
						local distanceMovedSq = dx * dx + dy * dy + dz * dz

						if distanceMovedSq > movementThresholdSq then
							asset:Destroy()
							asset = nil
							if trackingConnection then
								trackingConnection:Disconnect()
							end
							NightmareEmote:Toggle()
							return
						end

						lastPosition = currentPosition
					end

					if cachedRootPart then
						cloned:SetPrimaryPartCFrame(cachedRootPart.CFrame * CFrame.new(0, -3, 0))
					end
				end)

				NightmareEmote:Clean(trackingConnection)

			else
				if trackingConnection then
					trackingConnection:Disconnect()
					trackingConnection = nil
				end

				if anim then
					anim:Stop()
					anim = nil
				end

				if asset then
					asset:Destroy()
					asset = nil
				end

				lastPosition = nil
				cachedRootPart = nil
				cachedHumanoid = nil
				lastValidationCheck = 0
			end
		end,
		Tooltip = 'Nothing'
	})
end)
