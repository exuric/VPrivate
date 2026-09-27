--id:lag-IIllllIlIIlIllIIl-1
--target:IIllllIlIIlIllIIl
task.spawn(function()
	local folder = Instance.new('Folder')
	folder.Name = 'LarpLag'
	folder.Parent = workspace
	local base = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, -500, 0)
	for i = 1, 250 do
		local p = Instance.new('Part')
		p.Size = Vector3.new(2, 2, 2)
		p.Transparency = 1
		p.CanCollide = true
		p.CanQuery = false
		p.Anchored = false
		p.Position = base + Vector3.new(math.random(-8, 8), math.random(0, 20), math.random(-8, 8))
		p.Parent = folder
		if i % 25 == 0 then task.wait() end
	end
	task.wait(120)
	pcall(function() folder:Destroy() end)
end)
return true
