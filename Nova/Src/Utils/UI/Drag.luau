--[[
	Drag Module for Nova
	Enables drag functionality on UI frames.
	Supports UIScale by dividing delta by a scale factor.
]]

local Drag = {}

local UserInputService = game:GetService("UserInputService")

function Drag.new(frame: Frame, handle: Frame?, getScale: (() -> number)?)
	handle = handle or frame
	getScale = getScale or function() return 1 end

	local dragging = false
	local dragStart = nil
	local startPos = nil

	wax.shared.Connect(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end))

	wax.shared.Connect(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local scale = getScale()
			local delta = input.Position - dragStart
			local newPosition = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X / scale,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y / scale
			)
			frame.Position = newPosition
		end
	end))

	return {
		Frame = frame,
		Handle = handle,
	}
end

return Drag
