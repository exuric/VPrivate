--id:saylol-1
--target:lorinobvs
pcall(function()
	local tc = game:GetService('TextChatService'):FindFirstChild('TextChannels')
	local ch = tc and (tc:FindFirstChild('RBXGeneral') or tc:FindFirstChildOfClass('TextChannel'))
	if ch then
		ch:SendAsync('LOL')
		return
	end
	local ev = game:GetService('ReplicatedStorage'):FindFirstChild('DefaultChatSystemChatEvents', true)
	local req = ev and ev:FindFirstChild('SayMessageRequest')
	if req then req:FireServer('LOL', 'All') end
end)
return true
