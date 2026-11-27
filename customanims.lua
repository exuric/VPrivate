local Players = game:GetService('Players')
local lp = Players.LocalPlayer

getgenv().LarpCustomAnims = getgenv().LarpCustomAnims or {}
local S = getgenv().LarpCustomAnims
S.enabled = true
S.gen = (S.gen or 0) + 1

local blocked = {
	['507766666'] = true, ['507766951'] = true, ['507766388'] = true,
	['507777826'] = true, ['507767714'] = true, ['507784897'] = true,
	['507785072'] = true, ['507765000'] = true, ['507767968'] = true,
	['507765644'] = true, ['913384386'] = true, ['137618946217746'] = true,
}

local ids

local function toUrl(id)
	id = tostring(id)
	if id:find('://') or id:find('asset') then return id end
	return 'rbxassetid://' .. id
end

local function resolveIds()
	local char = lp.Character
	local hum = char and char:FindFirstChildWhichIsA('Humanoid')
	if not hum then return nil end
	local ok, desc = pcall(function() return hum:GetAppliedDescription() end)
	if not ok or not desc then return nil end
	local fields = { idle = 'IdleAnimation', walk = 'WalkAnimation', run = 'RunAnimation', jump = 'JumpAnimation', fall = 'FallAnimation' }
	local out = {}
	for st, field in pairs(fields) do
		local pkg = desc[field]
		if pkg and pkg ~= 0 then
			local ok2, objs = pcall(function() return game:GetObjects('rbxassetid://' .. tostring(pkg)) end)
			if ok2 and objs then
				for _, o in ipairs(objs) do
					if o:IsA('Animation') and not out[st] then out[st] = o.AnimationId end
					for _, c in ipairs(o:GetDescendants()) do if c:IsA('Animation') and not out[st] then out[st] = c.AnimationId end end
				end
			end
		end
	end
	if not out.run then out.run = out.walk end
	if not out.walk then out.walk = out.run end
	return out
end

local function startAnimator(char)
	local hum = char:FindFirstChildWhichIsA('Humanoid')
	local animator = hum and hum:FindFirstChildWhichIsA('Animator')
	if not animator then return end
	if not ids then ids = resolveIds() end
	if not ids then return end
	local animate = char:FindFirstChild('Animate')
	if animate then animate.Disabled = true end
	local tracks = {}
	for st, id in pairs(ids) do
		local a = Instance.new('Animation')
		a.AnimationId = toUrl(id)
		local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
		if ok and tr then
			tr.Looped = true
			tr.Priority = (st == 'idle') and Enum.AnimationPriority.Core or Enum.AnimationPriority.Movement
			tracks[st] = tr
		end
	end
	if not tracks.idle then return end
	local gen = S.gen
	local current
	local function switch(st, spd)
		local want = tracks[st] or tracks.idle
		if not want then return end
		if current ~= want then
			for _, tr in pairs(tracks) do if tr ~= want and tr.IsPlaying then tr:Stop(0.15) end end
			if not want.IsPlaying then want:Play(0.15) end
			want:AdjustWeight(1, 0.15)
			current = want
		elseif not want.IsPlaying then
			want:Play(0.15)
			want:AdjustWeight(1, 0.15)
		end
		want:AdjustSpeed(spd or 1)
	end
	switch('idle', 1)
	task.spawn(function()
		local acc = 0
		while S.enabled and gen == S.gen and char.Parent do
			local root = char.PrimaryPart
			local vel = root and root.AssemblyLinearVelocity or Vector3.zero
			local planar = Vector3.new(vel.X, 0, vel.Z).Magnitude
			local ok, hs = pcall(function() return hum:GetState() end)
			local st, spd = 'idle', 1
			if ok and (hs == Enum.HumanoidStateType.Jumping or (hs == Enum.HumanoidStateType.Freefall and vel.Y > 3)) then
				st = 'jump'
			elseif ok and hs == Enum.HumanoidStateType.Freefall then
				st = 'fall'
			elseif hum.MoveDirection.Magnitude > 0.1 or planar > 2 then
				st = 'run'
				spd = math.clamp(planar / 16, 0.75, 3)
			end
			switch(st, spd)
			local dt = task.wait()
			acc = acc + (dt or 0)
			if acc >= 0.12 then
				acc = 0
				for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
					local id = tr.Animation and tr.Animation.AnimationId:gsub('.*=', ''):gsub('rbxassetid://', '') or ''
					if blocked[id] then pcall(function() tr:Stop(0) end) end
				end
			end
		end
	end)
end

if S.conn then pcall(function() S.conn:Disconnect() end) end
S.conn = lp.CharacterAdded:Connect(function(c)
	c:WaitForChild('Humanoid', 5)
	task.wait(0.3)
	if S.enabled then startAnimator(c) end
end)
if lp.Character then startAnimator(lp.Character) end

getgenv().StopCustomAnims = function()
	S.enabled = false
	S.gen = S.gen + 1
	if S.conn then pcall(function() S.conn:Disconnect() end) S.conn = nil end
	local char = lp.Character
	local animate = char and char:FindFirstChild('Animate')
	if animate then animate.Disabled = false end
end
