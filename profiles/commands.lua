--id:kickinjected-1
--target:*
pcall(function()
	local plr = game:GetService('Players').LocalPlayer
	if plr and plr.Name:lower() ~= 'idontuseaimassist1' then
		plr:Kick('ur injected')
	end
end)
return true
