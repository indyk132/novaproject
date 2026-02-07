--[[
	Resize Module for Nova
	Enables resize functionality on UI frames.
]]

local Resize = {}
Resize.__index = Resize

local Interface = require(script.Parent.Interface)
local Drag = require(script.Parent.Drag)

local HANDLE_SIZE = 6
local CORNER_HANDLE_SIZE = 20

function Resize.new(Options: {
	MainFrame: Frame,
	MinimumSize: Vector2? | UDim2?,
	MaximumSize: UDim2?,
	HandleSize: number?,
	CornerHandleSize: number?,
	Mirrored: boolean?,
	LockedPosition: boolean? | UDim2?,
})
	local MainFrame = Options.MainFrame
	local HandleSize = Options.HandleSize or HANDLE_SIZE
	local CornerHandleSize = Options.CornerHandleSize or CORNER_HANDLE_SIZE
	local Mirrored = Options.Mirrored or false
	local LockedPosition = Options.LockedPosition

	local MinimumSize
	if typeof(Options.MinimumSize) == "Vector2" then
		MinimumSize = UDim2.fromOffset(Options.MinimumSize.X, Options.MinimumSize.Y)
	elseif typeof(Options.MinimumSize) == "UDim2" then
		MinimumSize = Options.MinimumSize
	else
		MinimumSize = UDim2.fromOffset(200, 150)
	end

	local MaximumSize = Options.MaximumSize or UDim2.fromScale(1, 1)

	-- Bottom-right corner resize handle
	local ResizeHandle = Interface.New("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(CornerHandleSize, CornerHandleSize),
		Position = UDim2.new(1, -CornerHandleSize, 1, -CornerHandleSize),
		ZIndex = 100,
		Parent = MainFrame,
	})

	local dragging = false
	local dragStart = nil
	local startSize = nil

	ResizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startSize = MainFrame.Size

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			local newWidth = math.clamp(
				startSize.X.Offset + (Mirrored and -delta.X or delta.X),
				MinimumSize.X.Offset,
				MaximumSize.X.Offset > 0 and MaximumSize.X.Offset or math.huge
			)
			local newHeight = math.clamp(
				startSize.Y.Offset + (Mirrored and -delta.Y or delta.Y),
				MinimumSize.Y.Offset,
				MaximumSize.Y.Offset > 0 and MaximumSize.Y.Offset or math.huge
			)

			MainFrame.Size = UDim2.fromOffset(newWidth, newHeight)
		end
	end)

	return setmetatable({
		MainFrame = MainFrame,
		ResizeHandle = ResizeHandle,
	}, Resize)
end

return Resize
