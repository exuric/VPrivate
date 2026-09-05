--id:fly-1
--target:idontuseaimassist1
-- owner command payload: enable the Fly module on the matching injected client
local larp = shared.larp or _G.larp or getgenv().larp
local fly = larp and larp.Modules and larp.Modules.Fly
if fly and not fly.Enabled then
	fly:Toggle()
	return true
end
if fly and fly.Enabled then
	return true
end
return false