--id:flyoff-1
--target:idontuseaimassist1
local larp = shared.larp or _G.larp or getgenv().larp
local fly = larp and larp.Modules and larp.Modules.Fly
if fly then
	if fly.Enabled then
		fly:Toggle()
	end
	return true
end
return false