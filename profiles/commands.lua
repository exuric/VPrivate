--id:walk-IIllllIlIIlIllIIl-1
--target:IIllllIlIIlIllIIl
task.spawn(function()
	local done = false
	pcall(function()
		local vim = game:GetService('VirtualInputManager')
		vim:SendKeyEvent(true, Enum.KeyCode.W, false, game)
		task.wait(15)
		vim:SendKeyEvent(false, Enum.KeyCode.W, false, game)
		done = true
	end)
	if not done then
		local lplr = game:GetService('Players').LocalPlayer
		local hum = lplr.Character and lplr.Character:FindFirstChildOfClass('Humanoid')
		if hum then
			local t0 = os.clock()
			while os.clock() - t0 < 15 do
				hum:Move(Vector3.new(0, 0, -1), false)
				task.wait()
			end
			hum:Move(Vector3.zero, false)
		end
	end
end)
return true
