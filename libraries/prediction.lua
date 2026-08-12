--This watermark is used to delete the file if its cached, remove it to make the file persist after larp updates.
-- LarpV4 prediction library - self written projectile solver.
local prediction = {
	Custom = {
		Enabled = false,
		Velocity = 1,
		Drop = 1
	},
	Compensation = {
		Enabled = true,
		MaxError = 6,
		Gain = 0.3
	}
}

local playersService = cloneref and cloneref(game:GetService('Players')) or game:GetService('Players')
local workspace = workspace
local down = Vector3.new(0, -1, 0)

prediction.Raycast = function(origin, direction, params)
	return workspace:Raycast(origin, direction, params)
end

local tracked = {}
local corrections = {}
local records = {}
local purgeAt = 0

local function sample()
	local now = tick()
	for _, player in playersService:GetPlayers() do
		local char = player.Character
		local root = char and char.PrimaryPart
		if root and root.Parent then
			local cur = root.AssemblyLinearVelocity
			if cur then
				local key = root
				local entry = tracked[key]
				if entry then
					entry.v = entry.v:Lerp(cur, 0.5)
					table.insert(entry.hist, {v = cur, t = now})
					while entry.hist[1] and now - entry.hist[1].t > 0.25 do
						table.remove(entry.hist, 1)
					end
				else
					tracked[key] = {v = cur, hist = {{v = cur, t = now}}}
				end
			end
		end
	end
	if purgeAt < now then
		purgeAt = now + 3
		for key, entry in tracked do
			if not key or not key.Parent then
				tracked[key] = nil
			end
		end
		for key, correction in corrections do
			if not key or not key.Parent then
				corrections[key] = nil
			end
		end
		for key in records do
			if not key or not key.Parent then
				records[key] = nil
			end
		end
	end
end

local function getVelocity(root, instant)
	local entry = root and tracked[root]
	if not entry then
		return instant
	end
	local now = tick()
	local past
	for i = #entry.hist, 1, -1 do
		if now - entry.hist[i].t >= 0.12 then
			past = entry.hist[i].v
			break
		end
	end
	if past and (past.X * instant.X + past.Z * instant.Z) < 0 then
		return instant
	end
	return Vector3.new(entry.v.X, instant.Y, entry.v.Z)
end

local function measureMiss()
	local now = tick()
	for key, rec in records do
		if rec.t + rec.T <= now then
			local part = rec.part
			if part and part.Parent then
				local miss = part.Position - rec.aim
				if rec.offset and rec.offset >= 0.5 then
					miss = Vector3.new(miss.X, 0, miss.Z)
				end
				if miss.Magnitude <= prediction.Compensation.MaxError then
					local old = corrections[key] or Vector3.zero
					corrections[key] = (old + miss * prediction.Compensation.Gain)
					if corrections[key].Magnitude > prediction.Compensation.MaxError then
						corrections[key] = corrections[key].Unit * prediction.Compensation.MaxError
					end
				else
					corrections[key] = nil
				end
			end
			records[key] = nil
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.05)
		sample()
		measureMiss()
	end
end)

local function solve(origin, speed, gravity, targetPos, targetVel, playerGravity, jumpHeight, airborne, floorY)
	local px, py, pz = targetPos - origin
	local vx, vy, vz = targetVel
	local g = playerGravity or workspace.Gravity
	local vY = math.abs(vy) > 2 and vy or (jumpHeight or 0)
	local floor = floorY or targetPos.Y
	if vY < -2 then
		floor = floor - 3
	end

	local function targetY(t)
		if not airborne then
			return targetPos.Y
		end
		local y = targetPos.Y + vY * t - 0.5 * g * t * t
		if y < floor then
			return floor + 0.05
		end
		return y
	end

	local function pointAt(t)
		local p = targetPos + targetVel * t
		if airborne then
			p = Vector3.new(p.X, targetY(t), p.Z)
		end
		return p
	end

	local function delta(t)
		local tx = px + vx * t
		local tz = pz + vz * t
		local ty = targetY(t) - origin.Y
		local drop = 0.5 * gravity * t * t
		local d2 = (tx * tx + tz * tz) + ((ty + drop) * (ty + drop))
		local s2 = (speed * t) * (speed * t)
		return d2 - s2
	end

	if speed <= 0 then
		return nil, nil, nil
	end

	local prev, prevF = 0.05, delta(0.05)
	if prevF < 0 then
		local a, b = 0.005, 0.05
		for _ = 1, 40 do
			local m = (a + b) / 2
			if delta(m) < 0 then b = m else a = m end
		end
		local T = (a + b) / 2
		local aim = pointAt(T) - down * (0.5 * gravity * T * T)
		return aim, aim, T
	end

	local bestT, bestF = 0.05, math.abs(prevF)
	for t = 0.1, 15, 0.05 do
		local f = delta(t)
		local af = math.abs(f)
		if af < bestF then
			bestF, bestT = af, t
		end
		if prevF < 0 and f >= 0 then
			local a, b = prev, t
			for _ = 1, 40 do
				local m = (a + b) / 2
				if delta(m) < 0 then a = m else b = m end
			end
			local T = (a + b) / 2
			local aim = pointAt(T) - down * (0.5 * gravity * T * T)
			return aim, aim, T
		end
		prev, prevF = t, f
	end
	if bestF < 4 then
		local aim = pointAt(bestT) - down * (0.5 * gravity * bestT * bestT)
		return aim, aim, bestT
	end
	return nil, nil, bestT
end

function prediction.SolveTrajectory(origin, speed, gravity, targetPos, targetVel, playerGravity, hipHeight, jumpHeight, rayCheck, airborne, ignorePos, ignorePart, _, _)
	if not origin or not speed or not targetPos or not targetVel then
		return nil, nil, nil
	end
	if prediction.Custom.Enabled then
		targetVel = targetVel * prediction.Custom.Velocity
		gravity = gravity * prediction.Custom.Drop
	end
	local root = ignorePart
	local vel = root and getVelocity(root, targetVel) or targetVel
	local correction = prediction.Compensation.Enabled and root and corrections[root] or nil
	local aimPos = correction and (targetPos + correction) or targetPos
	local headOffset = ignorePos and math.clamp(targetPos.Y - ignorePos.Y, 0, 5) or 0
	local floorY = ignorePos and (ignorePos.Y + headOffset) or nil
	local calc, _, T = solve(origin, speed, gravity, aimPos, vel, playerGravity, jumpHeight, airborne, floorY)
	if calc and T and T > 0.15 and root and root.Parent then
		records[root] = {part = root, aim = calc, offset = headOffset, T = T, t = tick()}
	end
	if calc and rayCheck and prediction.Raycast(origin, calc - origin, rayCheck) then
		return nil, nil, T
	end
	return calc, calc, T
end

function prediction.SpawnArcTracer(origin, velocityUnit, velocityMagnitude, gravity, travelTime, curve, opts)
	opts = opts or {}
	local count = math.clamp(math.floor(travelTime * 20), 4, 60)
	local lifetime = opts.Lifetime or 1
	for i = 0, count do
		local t = (i / count) * travelTime
		local p = origin + velocityUnit * (velocityMagnitude * t) - down * (0.5 * gravity * t * t)
		local swerve = math.sin(t * (curve * 8 + 4)) * curve * 1.5
		local tracer = Instance.new('Part')
		tracer.Name = 'LarpTracer'
		tracer.Size = Vector3.new(opts.Thick or 0.2, opts.Thick or 0.2, 0.4)
		tracer.Transparency = opts.Transparency or 0.5
		tracer.Color = opts.Color or Color3.fromHSV(0.44, 1, 1)
		tracer.Material = opts.Material or Enum.Material.SmoothPlastic
		tracer.MaterialVariant = 'None'
		tracer.Anchored = true
		tracer.CanCollide = false
		tracer.CanQuery = false
		tracer.CastShadow = false
		tracer.Position = p + (i % 2 == 0 and Vector3.new(0, 0, swerve) or Vector3.new(swerve, 0, 0))
		tracer.Parent = workspace
		task.delay(lifetime + 0.1, function()
			if tracer and tracer.Parent then
				tracer:Destroy()
			end
		end)
	end
end

function prediction.ResetCorrections()
	table.clear(corrections)
	table.clear(records)
end

return prediction