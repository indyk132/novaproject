--[[
	Sonner Luau Port for Nova
	Toast notification system inspired by Emil Kowalski's Sonner.
]]

local Sonner = {
	Queue = {},
	TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential),
	Wrapper = nil,
	PendingQueue = {},
	Processing = false,
}

local Icons = require(script.Parent.Icons)
local Interface = require(script.Parent.Interface)

local function InternalCreateNotificationObject(zindex, image, text)
	local NotificationTemplate = Interface.New("CanvasGroup", {
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.new(1, 0, 0, 42),
		GroupTransparency = 1,
		ZIndex = zindex,
		Position = UDim2.new(0.5, 0, 1, 50),

		["UICorner"] = { CornerRadius = UDim.new(0, 8) },
		["UIStroke"] = {
			Color = Color3.fromRGB(40, 40, 40),
			Thickness = 1,
		},
	})

	-- Icon
	if image then
		local IconLabel = Interface.New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(0, 12, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ImageColor3 = Color3.fromRGB(200, 200, 200),
			Parent = NotificationTemplate,
		})

		Icons.ApplyIcon(IconLabel, image)
	end

	-- Text
	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -44, 1, 0),
		Position = UDim2.new(0, image and 36 or 12, 0, 0),
		Text = text,
		TextColor3 = Color3.fromRGB(220, 220, 220),
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = NotificationTemplate,
	})

	return NotificationTemplate
end

local function ProcessQueue()
	if Sonner.Processing then
		return
	end
	Sonner.Processing = true

	while #Sonner.PendingQueue > 0 do
		local entry = table.remove(Sonner.PendingQueue, 1)
		local notif = entry.notif
		local time = entry.time or 4.5
		local removeCallback = entry.removeCallback

		if Sonner.Wrapper then
			notif.Parent = Sonner.Wrapper

			-- Animate in
			wax.shared.TweenService:Create(notif, Sonner.TweenInfo, {
				Position = UDim2.new(0.5, 0, 1, -8),
				GroupTransparency = 0,
			}):Play()

			-- Auto dismiss
			task.delay(time, function()
				local tween = wax.shared.TweenService:Create(notif, Sonner.TweenInfo, {
					Position = UDim2.new(0.5, 0, 1, 50),
					GroupTransparency = 1,
				})
				tween:Play()
				tween.Completed:Connect(function()
					notif:Destroy()
				end)

				if removeCallback then
					removeCallback()
				end
			end)
		end
	end

	Sonner.Processing = false
end

local function toast(icon, text, internalTime, removeCallback)
	if not Sonner.Wrapper then
		return
	end

	local zindex = #Sonner.Queue + 1
	local notif = InternalCreateNotificationObject(zindex, icon, text)

	table.insert(Sonner.Queue, notif)
	table.insert(Sonner.PendingQueue, {
		notif = notif,
		time = internalTime or 4.5,
		removeCallback = removeCallback,
	})

	task.spawn(ProcessQueue)
end

function Sonner.Initialize(parent)
	Sonner.Wrapper = Interface.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 360, 0, 200),
		Position = UDim2.new(0.5, 0, 1, -20),
		AnchorPoint = Vector2.new(0.5, 1),
		ZIndex = 100000,
		Parent = parent,
	})
end

function Sonner.info(text, internalTime)
	toast("info", text, internalTime)
end

function Sonner.success(text, internalTime)
	toast("circle-check", text, internalTime)
end

function Sonner.warning(text, internalTime)
	toast("triangle-alert", text, internalTime)
end

function Sonner.error(text, internalTime)
	toast("circle-alert", text, internalTime)
end

function Sonner.toast(text, internalTime)
	toast(nil, text, internalTime)
end

function Sonner.promise(func, options)
	local loadingText = options.loadingText or "Loading..."
	local successText = options.successText or "Success!"
	local errorText = options.errorText or "Error!"
	local internalTime = options.time or 4.5

	toast("loader-circle", loadingText, internalTime, function(notif, time)
		local success, resultOrError = pcall(func)

		if success then
			local text = type(successText) == "function" and successText(resultOrError) or successText
			Sonner.success(text)
		else
			local text = type(errorText) == "function" and errorText(resultOrError) or errorText
			Sonner.error(text)
		end
	end)
end

return Sonner
