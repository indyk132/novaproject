--[[
	Helper Module for Nova
	Various UI utility functions.
]]

local Helper = {}

function Helper.Ripple(button: TextButton | ImageButton, color: Color3?)
	color = color or Color3.fromRGB(255, 255, 255)

	button.ClipsDescendants = true

	button.MouseButton1Click:Connect(function()
		local mouse = game:GetService("UserInputService"):GetMouseLocation()
		local absolutePos = button.AbsolutePosition
		local relativeX = mouse.X - absolutePos.X
		local relativeY = mouse.Y - absolutePos.Y

		local circle = Instance.new("Frame")
		circle.BackgroundColor3 = color
		circle.BackgroundTransparency = 0.7
		circle.Position = UDim2.fromOffset(relativeX, relativeY)
		circle.AnchorPoint = Vector2.new(0.5, 0.5)
		circle.Size = UDim2.fromOffset(0, 0)

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = circle

		circle.Parent = button

		local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
		local tween = wax.shared.TweenService:Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
		})

		tween:Play()
		tween.Completed:Connect(function()
			circle:Destroy()
		end)
	end)
end

function Helper.HoverEffect(button: GuiObject, hoverColor: Color3?, normalColor: Color3?)
	normalColor = normalColor or button.BackgroundColor3
	hoverColor = hoverColor or Color3.fromRGB(
		math.min(normalColor.R * 255 + 20, 255) / 255,
		math.min(normalColor.G * 255 + 20, 255) / 255,
		math.min(normalColor.B * 255 + 20, 255) / 255
	)

	button.MouseEnter:Connect(function()
		wax.shared.TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = hoverColor,
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		wax.shared.TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = normalColor,
		}):Play()
	end)
end

function Helper.Truncate(text: string, maxLength: number): string
	if #text <= maxLength then
		return text
	end
	return string.sub(text, 1, maxLength - 3) .. "..."
end

function Helper.FormatNumber(num: number): string
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	end
	return tostring(num)
end

function Helper.QuickSerializeArgument(value): string
	local t = typeof(value)
	if t == "string" then
		local display = value
		-- Detect GUID pattern
		if string.match(display, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then
			return "GUID"
		end
		if #display > 50 then
			display = string.sub(display, 1, 47) .. "..."
		end
		-- Escape control characters for display
		display = string.gsub(display, "[%c]", ".")
		return `"{display}"`
	elseif t == "Instance" then
		local ok, fullName = pcall(function() return value:GetFullName() end)
		if ok then
			return fullName
		end
		return `[Instance] {tostring(value)}`
	elseif t == "boolean" then
		return tostring(value)
	elseif t == "number" then
		if value ~= value then
			return "nan"
		elseif value == math.huge then
			return "math.huge"
		elseif value == -math.huge then
			return "-math.huge"
		elseif value == math.floor(value) and math.abs(value) > 1e9 then
			-- Likely a timestamp
			return `{value} (timestamp?)`
		end
		return tostring(value)
	elseif t == "nil" then
		return "nil"
	elseif t == "EnumItem" then
		return tostring(value)
	elseif t == "Vector3" then
		return `Vector3({string.format("%.2f, %.2f, %.2f", value.X, value.Y, value.Z)})`
	elseif t == "Vector2" then
		return `Vector2({string.format("%.2f, %.2f", value.X, value.Y)})`
	elseif t == "CFrame" then
		local pos = value.Position
		return `CFrame({string.format("%.1f, %.1f, %.1f, ...", pos.X, pos.Y, pos.Z)})`
	elseif t == "UDim2" then
		return `UDim2({value.X.Scale}, {value.X.Offset}, {value.Y.Scale}, {value.Y.Offset})`
	elseif t == "UDim" then
		return `UDim({value.Scale}, {value.Offset})`
	elseif t == "Color3" then
		return `Color3({string.format("%.2f, %.2f, %.2f", value.R, value.G, value.B)})`
	elseif t == "BrickColor" then
		return `BrickColor("{tostring(value)}")`
	elseif t == "table" then
		local len = 0
		local isArray = true
		local preview = {}
		for k, v in pairs(value) do
			len += 1
			if len <= 3 then
				if type(k) ~= "number" or k ~= len then
					isArray = false
				end
				local vStr = Helper.QuickSerializeArgument(v)
				if #vStr > 20 then
					vStr = string.sub(vStr, 1, 17) .. "..."
				end
				if isArray then
					table.insert(preview, vStr)
				else
					table.insert(preview, `{tostring(k)} = {vStr}`)
				end
			end
			if len > 10 then break end
		end
		local suffix = len > 3 and `, ... +{len - 3}` or ""
		if len == 0 then
			return "{}"
		end
		return `\{{table.concat(preview, ", ")}{suffix}}`
	elseif t == "function" then
		local info = debug and debug.info and pcall(debug.info, value, "n")
		if info then
			local ok, name = pcall(debug.info, value, "n")
			if ok and name and name ~= "" then
				return `function {name}()`
			end
		end
		return "function()"
	elseif t == "buffer" then
		local size = buffer.len(value)
		if size <= 8 then
			local bytes = {}
			for i = 0, size - 1 do
				table.insert(bytes, string.format("%02X", buffer.readu8(value, i)))
			end
			return `buffer[{table.concat(bytes, " ")}]`
		end
		return `buffer({size} bytes)`
	elseif t == "thread" then
		return `thread({tostring(value)})`
	elseif t == "Ray" then
		return `Ray({string.format("%.1f, %.1f, %.1f", value.Origin.X, value.Origin.Y, value.Origin.Z)})`
	elseif t == "NumberRange" then
		return `NumberRange({value.Min}, {value.Max})`
	elseif t == "NumberSequence" then
		return `NumberSequence({#value.Keypoints} keypoints)`
	elseif t == "ColorSequence" then
		return `ColorSequence({#value.Keypoints} keypoints)`
	elseif t == "Rect" then
		return `Rect({value.Min.X}, {value.Min.Y}, {value.Max.X}, {value.Max.Y})`
	else
		return tostring(value)
	end
end

function Helper.FormatTimestamp(timestamp: number): string
	local seconds = math.floor(timestamp) % 60
	local minutes = math.floor(timestamp / 60) % 60
	local hours = math.floor(timestamp / 3600) % 24
	return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

return Helper
