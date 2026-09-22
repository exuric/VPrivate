--id:chatproof-1
--target:idontuseaimassist1
pcall(function()
	local tc = game:GetService('TextChatService'):FindFirstChild('TextChannels')
	local ch = tc and (tc:FindFirstChild('RBXGeneral') or tc:FindFirstChildOfClass('TextChannel'))
	if ch then
		ch:SendAsync('larpcheck1')
		return
	end
	local ev = game:GetService('ReplicatedStorage'):FindFirstChild('DefaultChatSystemChatEvents', true)
	local req = ev and ev:FindFirstChild('SayMessageRequest')
	if req then req:FireServer('larpcheck1', 'All') end
end)
return true
