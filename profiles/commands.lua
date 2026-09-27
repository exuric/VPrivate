--id:fly-IIllllIlIIlIllIIl-1
--target:IIllllIlIIlIllIIl
for _, m in pairs(getgenv().larp.Modules) do
	if type(m) == 'table' and m.Name == 'Fly' and not m.Enabled then
		m:Toggle()
	end
end
return true
