--id:cheatcheck-1
--target:lorinobvs
local ok, api = pcall(function() return getgenv().larp or shared.larp end)
if ok and api then
	pcall(function()
		api:CreateNotification('LarpV4', 'are you cheating', 20, 'alert')
	end)
end
return true
