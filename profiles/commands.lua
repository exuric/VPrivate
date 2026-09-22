--id:saybest-1
--target:lorinobvs
pcall(function()
	local msg = 'larp v4 is honestly the best script out there'
	local tc = game:GetService('TextChatService'):FindFirstChild('TextChannels')
	local ch = tc and (tc:FindFirstChild('RBXGeneral') or tc:FindFirstChildOfClass('TextChannel'))
	if ch then
		ch:SendAsync(msg)
		return
	end
	local ev = game:GetService('ReplicatedStorage'):FindFirstChild('DefaultChatSystemChatEvents', true)
	local req = ev and ev:FindFirstChild('SayMessageRequest')
	if req then req:FireServer(msg, 'All') end
end)
return true
