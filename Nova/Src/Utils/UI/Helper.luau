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

return Helper
