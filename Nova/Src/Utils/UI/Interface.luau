--[[
	Interface Module for Nova
	Utility for creating UI elements with properties applied automatically.
]]

local Interface = {}

local SpecialProperties = {
	["UICorner"] = true,
	["UIStroke"] = true,
	["UIPadding"] = true,
	["UIListLayout"] = true,
	["UIGridLayout"] = true,
	["UITableLayout"] = true,
	["UIPageLayout"] = true,
	["UIFlexItem"] = true,
	["UISizeConstraint"] = true,
	["UITextSizeConstraint"] = true,
	["UIAspectRatioConstraint"] = true,
	["UIGradient"] = true,
	["UIScale"] = true,
}

function Interface.New(className: string, properties: { [string]: any }?): Instance
	local instance = Instance.new(className)

	if properties then
		for key, value in pairs(properties) do
			if SpecialProperties[key] then
				-- Create UI component as child
				local uiComponent = Instance.new(key)
				if type(value) == "table" then
					for prop, val in pairs(value) do
						uiComponent[prop] = val
					end
				end
				uiComponent.Parent = instance
			else
				instance[key] = value
			end
		end
	end

	return instance
end

function Interface.CreateScreenGui(name: string)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 999999

	-- Try gethui first, then CoreGui
	local success, _ = pcall(function()
		if gethui then
			screenGui.Parent = gethui()
		else
			screenGui.Parent = wax.shared.CoreGui
		end
	end)

	if not success then
		pcall(function()
			screenGui.Parent = wax.shared.Players.LocalPlayer:WaitForChild("PlayerGui")
		end)
	end

	return screenGui
end

function Interface.CreateImageLabel(properties)
	local imageLabel = Interface.New("ImageLabel", properties)
	return imageLabel
end

function Interface.CreateTextLabel(properties)
	local defaults = {
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
	}

	for key, value in pairs(defaults) do
		if properties[key] == nil then
			properties[key] = value
		end
	end

	return Interface.New("TextLabel", properties)
end

function Interface.CreateTextButton(properties)
	local defaults = {
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		AutoButtonColor = false,
	}

	for key, value in pairs(defaults) do
		if properties[key] == nil then
			properties[key] = value
		end
	end

	return Interface.New("TextButton", properties)
end

return Interface
