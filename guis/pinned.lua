return function(mainapi, color, uipallet, addCorner, getcustomasset)
	mainapi:CreateCategory({
		Name = 'Pinned',
		Icon = getcustomasset('VapePrivate/assets/new/pin.png'),
		Size = UDim2.fromOffset(16, 16)
	})
	local pinnedcategory = mainapi.Categories.Pinned
	local pinnedchildren = pinnedcategory.Object:FindFirstChild('Children')
	pinnedcategory.Button.Object.MouseButton1Click:Connect(function()
		if pinnedcategory.Object.Visible and not pinnedcategory.Expanded then
			pinnedcategory:Expand()
		end
	end)

	function mainapi:UpdatePinned()
		local pinnedcategory = self.Categories.Pinned
		if not pinnedcategory then return end
		local pinnedchildren = pinnedcategory.Object:FindFirstChild('Children')
		for _, moduleapi in pairs(self.Modules) do
			local pinopt = moduleapi.Options['Pin to top']
			local enabled = pinopt and pinopt.Enabled
			if enabled and not moduleapi.PinnedRow then
				local row = Instance.new('TextButton')
				row.Name = moduleapi.Name
				row.Size = UDim2.fromOffset(220, 40)
				row.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				row.BorderSizePixel = 0
				row.AutoButtonColor = false
				row.Text = moduleapi.Name
				row.TextXAlignment = Enum.TextXAlignment.Left
				row.TextColor3 = color.Dark(uipallet.Text, 0.16)
				row.TextSize = 14
				row.FontFace = uipallet.Font
				row.LayoutOrder = moduleapi.Index
				row.Parent = pinnedchildren
				addCorner(row, UDim.new(0, 6))
				local rowpin = Instance.new('ImageLabel')
				rowpin.Name = 'Pin'
				rowpin.Size = UDim2.fromOffset(16, 16)
				rowpin.Position = UDim2.new(1, -22, 0, 12)
				rowpin.BackgroundTransparency = 1
				rowpin.Image = getcustomasset('VapePrivate/assets/new/pin.png')
				rowpin.ImageColor3 = color.Dark(uipallet.Text, 0.16)
				rowpin.Parent = row
				row.MouseButton1Click:Connect(function()
					moduleapi:Toggle()
				end)
				moduleapi.PinnedRow = row
			end
			if enabled then
				local row = moduleapi.PinnedRow
				if row then
					local hue, sat, val = self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value
					local rainbow = self.GUIColor.Rainbow and self.RainbowMode.Value ~= 'Retro'
					if moduleapi.Enabled then
						row.BackgroundColor3 = rainbow and Color3.fromHSV(self:Color((hue - (moduleapi.Index * 0.025)) % 1)) or Color3.fromHSV(hue, sat, val)
						row.TextColor3 = rainbow and Color3.new(0.19, 0.19, 0.19) or self:TextColor(hue, sat, val)
					else
						row.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
						row.TextColor3 = color.Dark(uipallet.Text, 0.16)
					end
					row.Pin.ImageColor3 = row.TextColor3
				end
			elseif moduleapi.PinnedRow then
				moduleapi.PinnedRow:Destroy()
				moduleapi.PinnedRow = nil
			end
		end
	end
end