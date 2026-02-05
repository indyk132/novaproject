--[[
	Drag Module for Nova
	Enables drag functionality on UI frames.
]]

local Drag = {}

local UserInputService = game:GetService("UserInputService")

function Drag.new(frame: Frame, handle: Frame?)
	handle = handle or frame

	local dragging = false
	local dragStart = nil
	local startPos = nil

	handle.InputBegan:Connect(function(input)
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
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			local newPosition = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
			frame.Position = newPosition
		end
	end)

	return {
		Frame = frame,
		Handle = handle,
	}
end

return Drag
