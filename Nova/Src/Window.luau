--[[
	Main Window Logic for Nova
	All UI elements are created and managed here.
]]

local AnticheatData = require(script.Parent.Utils.Anticheats.Main)
local LuaEncode = require(script.Parent.Utils.Serializer.LuaEncode)

local Utils = script.Parent.Utils

local Pagination = require(Utils.Pagination)
local CodeGen = require(Utils.CodeGen.Generator)
local SessionExporter = require(Utils.CodeGen.SessionExporter)

local UIUtils = script.Parent.Utils.UI

local SyntaxHighlighter = require(UIUtils.Highlighter)
local ImageFetcher = require(UIUtils.ImageFetch)
local Icons = require(UIUtils.Icons)
local Interface = require(UIUtils.Interface)
local Helper = require(UIUtils.Helper)
local Resize = require(UIUtils.Resize)
local Drag = require(UIUtils.Drag)

-- Pagination Setup
local PaginationHelper = Pagination.new({
	ItemsPerPage = wax.shared.SaveManager:GetState("MaxItemPerPages", 20),
	TotalItems = 0,
})

local Tabs = {}
local CurrentPage = {}
local CurrentInfo, CurrentTab, CurrentLog
local LogsList

-- Theme Colors
local Theme = {
	Background = Color3.fromRGB(15, 15, 15),
	Surface = Color3.fromRGB(20, 20, 20),
	SurfaceHover = Color3.fromRGB(28, 28, 28),
	Border = Color3.fromRGB(40, 40, 40),
	BorderLight = Color3.fromRGB(55, 55, 55),
	Text = Color3.fromRGB(220, 220, 220),
	TextMuted = Color3.fromRGB(140, 140, 140),
	Accent = Color3.fromRGB(88, 101, 242),
	AccentHover = Color3.fromRGB(98, 111, 252),
	Success = Color3.fromRGB(63, 185, 80),
	Warning = Color3.fromRGB(210, 153, 34),
	Error = Color3.fromRGB(248, 81, 73),
	Incoming = Color3.fromRGB(63, 185, 80),
	Outgoing = Color3.fromRGB(247, 129, 102),
}

-- Remote type images
local Images = {
	RemoteEvent = ImageFetcher.GetRemoteImage("RemoteEvent"),
	RemoteFunction = ImageFetcher.GetRemoteImage("RemoteFunction"),
	UnreliableRemoteEvent = ImageFetcher.GetRemoteImage("UnreliableRemoteEvent"),
	BindableEvent = ImageFetcher.GetRemoteImage("BindableEvent"),
	BindableFunction = ImageFetcher.GetRemoteImage("BindableFunction"),
}

-- Default tween info
local DefaultTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- DPI Scale
local function GetDPIScale()
	local ScaleString = wax.shared.SaveManager:GetState("WindowDPIScale", "100%")
	local ScaleNumber = tonumber(string.match(ScaleString, "%d+"))
	return (ScaleNumber or 100) / 100
end

-- ============================================================
-- SCREEN GUI
-- ============================================================

local ScreenGui = Interface.CreateScreenGui("Nova")
wax.shared.ScreenGui = ScreenGui

local ScreenDPIScale = Interface.New("UIScale", {
	Scale = GetDPIScale(),
	Parent = ScreenGui,
})

-- Initialize Sonner
wax.shared.Sonner.Initialize(ScreenGui)

-- ============================================================
-- MAIN FRAME
-- ============================================================

local MainFrame = Interface.New("Frame", {
	BackgroundColor3 = Theme.Background,
	Size = UDim2.fromOffset(900, 550),
	Position = UDim2.new(0.5, -450, 0.5, -275),
	BorderSizePixel = 0,
	Parent = ScreenGui,

	["UICorner"] = { CornerRadius = UDim.new(0, 8) },
	["UIStroke"] = {
		Color = Theme.Border,
		Thickness = 1,
	},
})

-- Drag handle
local TitleBar = Interface.New("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 0, 36),
	BorderSizePixel = 0,
	Parent = MainFrame,

	["UICorner"] = { CornerRadius = UDim.new(0, 8) },
})

-- Cover bottom corners of title bar
Interface.New("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 0, 10),
	Position = UDim2.new(0, 0, 1, -10),
	BorderSizePixel = 0,
	Parent = TitleBar,
})

Drag.new(MainFrame, TitleBar)

-- Title
local TitleIcon = Interface.New("ImageLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(18, 18),
	Position = UDim2.new(0, 12, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	ImageColor3 = Theme.Accent,
	Parent = TitleBar,
})
Icons.ApplyIcon(TitleIcon, "radar")

Interface.New("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 200, 1, 0),
	Position = UDim2.new(0, 36, 0, 0),
	Text = "Nova",
	TextColor3 = Theme.Text,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = TitleBar,
})

-- Version badge
Interface.New("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 60, 0, 18),
	Position = UDim2.new(0, 72, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	Text = "v1.0.0",
	TextColor3 = Theme.TextMuted,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = TitleBar,
})

-- Close, Minimize buttons
local WindowButtons = Interface.New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 70, 1, 0),
	Position = UDim2.new(1, -70, 0, 0),
	Parent = TitleBar,

	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
	},
	["UIPadding"] = {
		PaddingRight = UDim.new(0, 8),
	},
})

local function CreateWindowButton(iconName, callback)
	local btn = Interface.New("TextButton", {
		Text = "",
		BackgroundColor3 = Theme.SurfaceHover,
		BackgroundTransparency = 0.5,
		Size = UDim2.fromOffset(28, 28),
		Parent = WindowButtons,
		AutoButtonColor = false,

		["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	})

	local icon = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ImageColor3 = Theme.TextMuted,
		Parent = btn,
	})
	Icons.ApplyIcon(icon, iconName)

	Helper.HoverEffect(btn, Theme.SurfaceHover, Theme.Surface)

	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- Minimize
CreateWindowButton("minus", function()
	MainFrame.Visible = not MainFrame.Visible
end)

-- Close / Unload
CreateWindowButton("x", function()
	if wax.shared.Unload then
		wax.shared.Unload()
	end
end)

-- ============================================================
-- TAB BAR (Outgoing / Incoming / Settings)
-- ============================================================

local TabBar = Interface.New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 240, 1, -36),
	Position = UDim2.new(0, 0, 0, 36),
	Parent = MainFrame,
})

-- Tabs sidebar
local TabsList = Interface.New("ScrollingFrame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 1, -44),
	Position = UDim2.new(0, 0, 0, 0),
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Theme.Border,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromScale(0, 0),
	Parent = TabBar,

	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 1),
	},
	["UIPadding"] = {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
	},
})

-- Tab navigation buttons at top
local TabNavigation = Interface.New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 36),
	Position = UDim2.new(0, 0, 1, -44),
	Parent = TabBar,

	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 2),
	},
	["UIPadding"] = {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
	},
})

local ActiveTab = "Outgoing"
local TabButtons = {}

local function CreateTabButton(name, iconName)
	local btn = Interface.New("TextButton", {
		Text = "",
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(0.33, -2, 1, 0),
		AutoButtonColor = false,
		Parent = TabNavigation,

		["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	})

	local icon = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0.5, -24, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ImageColor3 = Theme.TextMuted,
		Parent = btn,
	})
	Icons.ApplyIcon(icon, iconName)

	local label = Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0.5, -20, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		Text = name,
		TextColor3 = Theme.TextMuted,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = btn,
	})

	TabButtons[name] = {
		Button = btn,
		Icon = icon,
		Label = label,
	}

	return btn
end

local OutgoingTabBtn = CreateTabButton("Outgoing", "arrow-up-right")
local IncomingTabBtn = CreateTabButton("Incoming", "arrow-down-left")
local SettingsTabBtn = CreateTabButton("Settings", "settings")

-- ============================================================
-- REMOTE LOGS PANEL
-- ============================================================

local LogsWrapper = Interface.New("Frame", {
	AnchorPoint = Vector2.one,
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(1, 1),
	Size = UDim2.new(1, -242, 1, -36),
	Parent = MainFrame,

	["UIPadding"] = {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 6),
	},
})

LogsList = Interface.New("ScrollingFrame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, -38),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromScale(0, 0),
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Theme.Border,
	BorderSizePixel = 0,
	Parent = LogsWrapper,

	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 2),
	},
})

-- Pagination bar
local PaginationBar = Interface.New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 32),
	Position = UDim2.new(0, 0, 1, -32),
	Parent = LogsWrapper,

	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
	},
})

local PageLabel = Interface.New("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 120, 0, 24),
	Text = "Page 1 / 1",
	TextColor3 = Theme.TextMuted,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	Parent = PaginationBar,
})

local function CreatePaginationButton(text, callback)
	local btn = Interface.New("TextButton", {
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.fromOffset(28, 24),
		AutoButtonColor = false,
		Parent = PaginationBar,

		["UICorner"] = { CornerRadius = UDim.new(0, 4) },
	})

	Helper.HoverEffect(btn, Theme.SurfaceHover, Theme.Surface)
	btn.MouseButton1Click:Connect(callback)
	return btn
end

CreatePaginationButton("<", function()
	PaginationHelper:PreviousPage()
	if CurrentLog then
		CurrentPage[CurrentLog] = PaginationHelper.CurrentPage
		ShowLog(CurrentLog)
	end
end)

CreatePaginationButton(">", function()
	PaginationHelper:NextPage()
	if CurrentLog then
		CurrentPage[CurrentLog] = PaginationHelper.CurrentPage
		ShowLog(CurrentLog)
	end
end)

-- ============================================================
-- REMOTE ENTRY CREATION
-- ============================================================

local function CreateRemoteEntry(logEntry)
	local instance = logEntry.Instance
	local className = instance.ClassName
	local eventType = logEntry.Type
	local typeColor = eventType == "Incoming" and Theme.Incoming or Theme.Outgoing

	local entry = Interface.New("TextButton", {
		Text = "",
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 38),
		AutoButtonColor = false,
		ClipsDescendants = true,

		["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	})

	-- Type indicator line
	Interface.New("Frame", {
		BackgroundColor3 = typeColor,
		Size = UDim2.new(0, 3, 1, -8),
		Position = UDim2.new(0, 0, 0, 4),
		BorderSizePixel = 0,
		Parent = entry,

		["UICorner"] = { CornerRadius = UDim.new(0, 2) },
	})

	-- Remote icon
	local icon = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Image = Images[className] or Images.RemoteEvent,
		Parent = entry,
	})

	-- Remote name
	local nameLabel = Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -110, 0, 16),
		Position = UDim2.new(0, 36, 0.5, -1),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = Helper.Truncate(instance.Name, 30),
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = entry,
	})

	-- Call count badge
	local countBadge = Interface.New("TextLabel", {
		BackgroundColor3 = Theme.SurfaceHover,
		Size = UDim2.fromOffset(40, 20),
		Position = UDim2.new(1, -48, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "0",
		TextColor3 = Theme.TextMuted,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		Parent = entry,

		["UICorner"] = { CornerRadius = UDim.new(0, 4) },
	})

	-- Ignored/Blocked indicator
	local statusIcon = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(1, -58, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ImageColor3 = Theme.TextMuted,
		Visible = false,
		Parent = entry,
	})

	Helper.HoverEffect(entry, Theme.SurfaceHover, Theme.Surface)

	-- Click to select
	entry.MouseButton1Click:Connect(function()
		CurrentLog = logEntry
		ShowLog(logEntry)
	end)

	-- Update function
	logEntry:SetButton(entry, nameLabel, countBadge)

	return entry
end

-- ============================================================
-- LOG DISPLAY
-- ============================================================

function ShowLog(logEntry)
	-- Clear current logs list
	for _, child in ipairs(LogsList:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	if not logEntry then
		return
	end

	local calls = logEntry.Calls
	PaginationHelper:Update(#calls)

	local page = CurrentPage[logEntry] or 1
	PaginationHelper:SetPage(page)

	local info = PaginationHelper:GetInfo()
	PageLabel.Text = `Page {info.CurrentPage} / {math.max(info.TotalPages, 1)}`

	if #calls == 0 then
		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			Text = "No calls recorded yet",
			TextColor3 = Theme.TextMuted,
			TextSize = 13,
			Font = Enum.Font.GothamMedium,
			Parent = LogsList,
		})
		return
	end

	local startIdx, endIdx = PaginationHelper:GetIndexRanges()

	for i = startIdx, endIdx do
		local callInfo = calls[i]
		if not callInfo then
			continue
		end

		local callEntry = Interface.New("TextButton", {
			Text = "",
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 32),
			AutoButtonColor = false,

			["UICorner"] = { CornerRadius = UDim.new(0, 4) },
		})

		-- Call number
		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 40, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			Text = `#{i}`,
			TextColor3 = Theme.TextMuted,
			TextSize = 11,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = callEntry,
		})

		-- Method
		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 100, 1, 0),
			Position = UDim2.new(0, 50, 0, 0),
			Text = callInfo.Method or "Unknown",
			TextColor3 = Theme.Accent,
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = callEntry,
		})

		-- Args count
		local argsCount = callInfo.Args and #callInfo.Args or 0
		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 80, 1, 0),
			Position = UDim2.new(0, 160, 0, 0),
			Text = `{argsCount} arg{argsCount ~= 1 and "s" or ""}`,
			TextColor3 = Theme.TextMuted,
			TextSize = 11,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = callEntry,
		})

		-- Executor badge
		if callInfo.IsExecutor then
			Interface.New("TextLabel", {
				BackgroundColor3 = Theme.Warning,
				BackgroundTransparency = 0.8,
				Size = UDim2.fromOffset(50, 16),
				Position = UDim2.new(1, -60, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Text = "Executor",
				TextColor3 = Theme.Warning,
				TextSize = 9,
				Font = Enum.Font.GothamBold,
				Parent = callEntry,

				["UICorner"] = { CornerRadius = UDim.new(0, 3) },
			})
		end

		Helper.HoverEffect(callEntry, Theme.SurfaceHover, Theme.Surface)

		-- Click to view details
		callEntry.MouseButton1Click:Connect(function()
			CurrentInfo = callInfo
			ShowCallDetails(logEntry, callInfo, i)
		end)

		callEntry.Parent = LogsList
	end
end

-- ============================================================
-- CALL DETAILS PANEL
-- ============================================================

local InfoFrame = Interface.New("Frame", {
	BackgroundColor3 = Theme.Background,
	Size = UDim2.new(0.45, 0, 0.75, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Visible = false,
	ZIndex = 50,
	Parent = ScreenGui,

	["UICorner"] = { CornerRadius = UDim.new(0, 8) },
	["UIStroke"] = {
		Color = Theme.Border,
		Thickness = 1,
	},
})

Drag.new(InfoFrame)
Resize.new({
	MainFrame = InfoFrame,
	MinimumSize = UDim2.fromOffset(400, 300),
})

local InfoTitleBar = Interface.New("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 0, 36),
	BorderSizePixel = 0,
	ZIndex = 51,
	Parent = InfoFrame,

	["UICorner"] = { CornerRadius = UDim.new(0, 8) },
})

local InfoTitle = Interface.New("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -80, 1, 0),
	Position = UDim2.new(0, 12, 0, 0),
	Text = "Call Details",
	TextColor3 = Theme.Text,
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 52,
	Parent = InfoTitleBar,
})

-- Close details button
local CloseInfoBtn = Interface.New("TextButton", {
	Text = "",
	BackgroundColor3 = Theme.SurfaceHover,
	BackgroundTransparency = 0.5,
	Size = UDim2.fromOffset(28, 28),
	Position = UDim2.new(1, -34, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	AutoButtonColor = false,
	ZIndex = 52,
	Parent = InfoTitleBar,

	["UICorner"] = { CornerRadius = UDim.new(0, 6) },
})

local closeIcon = Interface.New("ImageLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(12, 12),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	ImageColor3 = Theme.TextMuted,
	ZIndex = 53,
	Parent = CloseInfoBtn,
})
Icons.ApplyIcon(closeIcon, "x")

CloseInfoBtn.MouseButton1Click:Connect(function()
	InfoFrame.Visible = false
end)

-- Info content area
local InfoContent = Interface.New("ScrollingFrame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -16, 1, -44),
	Position = UDim2.new(0, 8, 0, 40),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromScale(0, 0),
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Theme.Border,
	BorderSizePixel = 0,
	ZIndex = 51,
	Parent = InfoFrame,

	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
	},
})

function ShowCallDetails(logEntry, callInfo, callIndex)
	InfoFrame.Visible = true
	InfoTitle.Text = `Call #{callIndex} - {logEntry.Instance.Name}`

	-- Clear previous content
	for _, child in ipairs(InfoContent:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Remote Info Section
	local function CreateInfoRow(label, value, valueColor)
		local row = Interface.New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			ZIndex = 52,
			Parent = InfoContent,
		})

		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 120, 1, 0),
			Text = label,
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 52,
			Parent = row,
		})

		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -130, 1, 0),
			Position = UDim2.new(0, 130, 0, 0),
			Text = tostring(value),
			TextColor3 = valueColor or Theme.Text,
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 52,
			Parent = row,
		})
	end

	CreateInfoRow("Remote:", logEntry.Instance.Name)
	CreateInfoRow("Class:", logEntry.Instance.ClassName, Theme.Accent)
	CreateInfoRow("Type:", logEntry.Type, logEntry.Type == "Incoming" and Theme.Incoming or Theme.Outgoing)
	CreateInfoRow("Method:", callInfo.Method or "Unknown")
	CreateInfoRow("Is Executor:", tostring(callInfo.IsExecutor or false), callInfo.IsExecutor and Theme.Warning or Theme.TextMuted)

	if callInfo.Origin and typeof(callInfo.Origin) == "Instance" then
		CreateInfoRow("Origin:", callInfo.Origin:GetFullName())
	end

	-- Separator
	Interface.New("Frame", {
		BackgroundColor3 = Theme.Border,
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 52,
		Parent = InfoContent,
	})

	-- Args Section
	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Text = "Arguments",
		TextColor3 = Theme.Text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 52,
		Parent = InfoContent,
	})

	if callInfo.Args and #callInfo.Args > 0 then
		local Success, Encoded = pcall(LuaEncode, callInfo.Args, {
			Prettify = true,
			FunctionsReturnRaw = true,
			UseInstancePaths = true,
		})

		local codeFrame = Interface.New("Frame", {
			BackgroundColor3 = Color3.fromRGB(10, 10, 10),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 52,
			Parent = InfoContent,

			["UICorner"] = { CornerRadius = UDim.new(0, 6) },
			["UIPadding"] = {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			},
		})

		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = Success and Encoded or `Error: {tostring(Encoded)}`,
			TextColor3 = Theme.Text,
			TextSize = 12,
			Font = Enum.Font.Code,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			RichText = false,
			ZIndex = 53,
			Parent = codeFrame,
		})
	else
		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			Text = "No arguments",
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 52,
			Parent = InfoContent,
		})
	end

	-- Separator
	Interface.New("Frame", {
		BackgroundColor3 = Theme.Border,
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 52,
		Parent = InfoContent,
	})

	-- Action Buttons
	local ActionButtons = Interface.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 52,
		Parent = InfoContent,

		["UIListLayout"] = {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			WrapsEnabled = true,
		},
	})

	local function CreateActionButton(text, iconName, callback)
		local btn = Interface.New("TextButton", {
			Text = "",
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(0, 0, 0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			AutoButtonColor = false,
			ZIndex = 53,
			Parent = ActionButtons,

			["UICorner"] = { CornerRadius = UDim.new(0, 6) },
			["UIPadding"] = {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 10),
			},
		})

		local icon = Interface.New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(0, 2, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ImageColor3 = Theme.TextMuted,
			ZIndex = 54,
			Parent = btn,
		})
		Icons.ApplyIcon(icon, iconName)

		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(0, 18, 0, 0),
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 11,
			Font = Enum.Font.GothamMedium,
			ZIndex = 54,
			Parent = btn,
		})

		Helper.HoverEffect(btn, Theme.SurfaceHover, Theme.Surface)
		btn.MouseButton1Click:Connect(callback)

		return btn
	end

	-- Copy Code
	CreateActionButton("Copy Code", "copy", function()
		local code = CodeGen.GenerateCode(logEntry, callInfo)
		local success = pcall(setclipboard, code)
		if success then
			wax.shared.Sonner.success("Copied calling code to clipboard")
		else
			wax.shared.Sonner.error("Failed to copy to clipboard")
		end
	end)

	-- Copy Intercept Code
	CreateActionButton("Intercept", "shield", function()
		local code = CodeGen.GenerateInterceptCode(logEntry)
		local success = pcall(setclipboard, code)
		if success then
			wax.shared.Sonner.success("Copied intercept code to clipboard")
		else
			wax.shared.Sonner.error("Failed to copy to clipboard")
		end
	end)

	-- Copy Remote Path
	CreateActionButton("Copy Path", "link", function()
		local path = CodeGen.GetFullPath(logEntry.Instance, { VariableName = "Remote" })
		local success = pcall(setclipboard, path)
		if success then
			wax.shared.Sonner.success("Copied remote path to clipboard")
		else
			wax.shared.Sonner.error("Failed to copy to clipboard")
		end
	end)

	-- Replay
	if logEntry.Type == "Outgoing" then
		CreateActionButton("Replay", "play", function()
			wax.shared.Sonner.promise(function()
				wax.shared.ReplayCallInfo(callInfo, logEntry.Type)
			end, {
				loadingText = "Replaying event...",
				successText = "Replayed event successfully!",
				errorText = "Failed to replay event",
			})
		end)
	end

	-- Ignore
	CreateActionButton(logEntry.Ignored and "Unignore" or "Ignore", logEntry.Ignored and "eye" or "eye-off", function()
		logEntry:Ignore()
		wax.shared.Sonner.success(`{logEntry.Ignored and "Started" or "Stopped"} ignoring {logEntry.Instance.Name}`)
	end)

	-- Block
	CreateActionButton(logEntry.Blocked and "Unblock" or "Block", logEntry.Blocked and "unlock" or "lock", function()
		logEntry:Block()
		wax.shared.Sonner.success(`{logEntry.Blocked and "Started" or "Stopped"} blocking {logEntry.Instance.Name}`)
	end)

	-- Decompile Origin
	if callInfo.Origin and typeof(callInfo.Origin) == "Instance" and typeof(decompile) == "function" then
		CreateActionButton("Decompile", "file-code", function()
			local success, result = pcall(decompile, callInfo.Origin)
			if success then
				pcall(setclipboard, result)
				wax.shared.Sonner.success("Decompiled and copied to clipboard")
			else
				wax.shared.Sonner.error("Failed to decompile script")
			end
		end)
	end
end

-- ============================================================
-- SETTINGS PANEL
-- ============================================================

local SettingsFrame = Interface.New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -242, 1, -36),
	Position = UDim2.new(1, 0, 0, 36),
	AnchorPoint = Vector2.new(1, 0),
	Visible = false,
	Parent = MainFrame,

	["UIPadding"] = {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
	},
})

local SettingsScroll = Interface.New("ScrollingFrame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromScale(0, 0),
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Theme.Border,
	BorderSizePixel = 0,
	Parent = SettingsFrame,

	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 8),
	},
})

local function CreateSettingsSection(title)
	local section = Interface.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = SettingsScroll,

		["UIListLayout"] = {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 6),
		},
	})

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = section,
	})

	return section
end

local function CreateSettingsCheckbox(idx, options)
	local section = options.Section
	local Default = wax.shared.SaveManager:GetState(idx, options.Default)

	local Checkbox = {
		Value = Default,
		Default = options.Default,
	}

	local row = Interface.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		Parent = section,
	})

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -56, 1, 0),
		Text = options.Text,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local toggleTrack = Interface.New("TextButton", {
		Text = "",
		BackgroundColor3 = Checkbox.Value and Theme.Accent or Theme.SurfaceHover,
		Size = UDim2.fromOffset(40, 22),
		Position = UDim2.new(1, -44, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		AutoButtonColor = false,
		Parent = row,

		["UICorner"] = { CornerRadius = UDim.new(1, 0) },
	})

	local toggleKnob = Interface.New("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromOffset(16, 16),
		Position = Checkbox.Value and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = toggleTrack,

		["UICorner"] = { CornerRadius = UDim.new(1, 0) },
	})

	local function UpdateVisual()
		wax.shared.TweenService:Create(toggleTrack, DefaultTweenInfo, {
			BackgroundColor3 = Checkbox.Value and Theme.Accent or Theme.SurfaceHover,
		}):Play()

		wax.shared.TweenService:Create(toggleKnob, DefaultTweenInfo, {
			Position = Checkbox.Value and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		}):Play()
	end

	toggleTrack.MouseButton1Click:Connect(function()
		Checkbox.Value = not Checkbox.Value
		wax.shared.SaveManager:SetState(idx, Checkbox.Value)
		UpdateVisual()

		if options.Callback then
			options.Callback(Checkbox.Value)
		end
	end)

	wax.shared.Settings[idx] = Checkbox
end

local function CreateSettingsDropdown(idx, options)
	local section = options.Section
	local Default = wax.shared.SaveManager:GetState(idx, options.Default)

	local row = Interface.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		Parent = section,
	})

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 1, 0),
		Text = options.Text,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local currentIndex = table.find(options.Values, Default) or 1

	local valueLabel = Interface.New("TextButton", {
		Text = Default,
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(0.4, 0, 0, 26),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		AutoButtonColor = false,
		Parent = row,

		["UICorner"] = { CornerRadius = UDim.new(0, 4) },
		["UIStroke"] = {
			Color = Theme.Border,
			Thickness = 1,
		},
	})

	valueLabel.MouseButton1Click:Connect(function()
		currentIndex = (currentIndex % #options.Values) + 1
		local newValue = options.Values[currentIndex]
		valueLabel.Text = newValue
		wax.shared.SaveManager:SetState(idx, newValue)

		if options.Callback then
			options.Callback(newValue)
		end
	end)
end

-- Build Settings
local CodeGenSection = CreateSettingsSection("Code Generation")

CreateSettingsDropdown("PathMethod", {
	Text = "Instance Path Method",
	Values = { "Index", "WaitForChild", "FindFirstChild" },
	Default = "Index",
	Section = CodeGenSection,
})

CreateSettingsCheckbox("PreferBufferFromString", {
	Text = "Prefer buffer.fromstring",
	Default = false,
	Section = CodeGenSection,
})

CreateSettingsCheckbox("ShowWatermark", {
	Text = "Show Nova Watermark",
	Default = true,
	Section = CodeGenSection,
})

local MainSection = CreateSettingsSection("Main")

CreateSettingsDropdown("WindowDPIScale", {
	Text = "DPI Scale",
	Values = { "50%", "75%", "100%", "125%", "150%" },
	Default = "100%",
	Section = MainSection,
	Callback = function(value)
		ScreenDPIScale.Scale = GetDPIScale()
	end,
})

CreateSettingsCheckbox("IgnorePlayerModule", {
	Text = "Ignore PlayerModule",
	Default = true,
	Section = MainSection,
})

CreateSettingsCheckbox("ExecuteOnTeleport", {
	Text = "Execute On Teleport",
	Default = false,
	Section = MainSection,
})

CreateSettingsCheckbox("UseAlternativeHooks", {
	Text = "Use Alternative Metamethod Hook",
	Default = false,
	Section = MainSection,
})

CreateSettingsCheckbox("AnticheatBypass", {
	Text = "Built-in Anticheat Bypass",
	Default = true,
	Section = MainSection,
})

-- Anticheat info
if AnticheatData.Detected then
	Interface.New("TextLabel", {
		Text = `Anticheat Detected: <b>{AnticheatData.Name}</b>`,
		TextSize = 13,
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Warning,
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		RichText = true,
		Parent = MainSection,
	})
end

-- Session Export
local SessionSection = CreateSettingsSection("Session")

local ExportBtn = Interface.New("TextButton", {
	Text = "Export Session to HTML",
	TextColor3 = Theme.Text,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 0, 32),
	AutoButtonColor = false,
	Parent = SessionSection,

	["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	["UIStroke"] = {
		Color = Theme.Border,
		Thickness = 1,
	},
})

Helper.HoverEffect(ExportBtn, Theme.SurfaceHover, Theme.Surface)

ExportBtn.MouseButton1Click:Connect(function()
	wax.shared.Sonner.promise(function()
		local AllCalls = {}
		local SessionData = {
			SessionId = wax.shared.HttpService:GenerateGUID(false),
			StartTime = wax.shared.NovaStartTime,
			EndTime = tick(),
			PlaceId = game.PlaceId,
		}

		for eventType, logs in pairs(wax.shared.Logs) do
			for remote, log in pairs(logs) do
				for _, call in ipairs(log.Calls) do
					table.insert(AllCalls, {
						Type = eventType,
						RemoteName = remote.Name,
						ClassName = remote.ClassName,
						Time = (call.CreationTime or 0) - wax.shared.NovaStartTime,
						ArgCount = call.Args and #call.Args or 0,
					})
				end
			end
		end

		table.sort(AllCalls, function(a, b) return a.Time < b.Time end)

		local Events, StringMap = SessionExporter:ProcessCalls(AllCalls, SessionData)
		local FileName = `Nova_Session_{os.time()}.html`
		writefile(FileName, SessionExporter:ExportSessionToHTML(Events, StringMap, SessionData))
		return FileName
	end, {
		loadingText = "Exporting session...",
		successText = function(fileName) return `Exported to {fileName}` end,
		errorText = function(err) return `Export failed: {err}` end,
	})
end)

-- Unload button
local UnloadBtn = Interface.New("TextButton", {
	Text = "Unload Nova",
	TextColor3 = Theme.Error,
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 0, 32),
	AutoButtonColor = false,
	Parent = SessionSection,

	["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	["UIStroke"] = {
		Color = Theme.Error,
		Transparency = 0.7,
		Thickness = 1,
	},
})

Helper.HoverEffect(UnloadBtn, Color3.fromRGB(40, 15, 15), Theme.Surface)

UnloadBtn.MouseButton1Click:Connect(function()
	if wax.shared.Unload then
		wax.shared.Unload()
	end
end)

-- Credits
local CreditsSection = CreateSettingsSection("Credits")

local Credits = {
	{ Credit = "Nova Team", Description = "Nova Developer" },
	{ Credit = "shadcn", Description = "UI Design Inspiration" },
	{ Credit = "lucide", Description = "Consistent and clean icons" },
	{ Credit = "Emil Kowalski", Description = "Creator of Sonner component" },
}

for _, data in ipairs(Credits) do
	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = `<b>{data.Credit}</b> - {data.Description}`,
		TextColor3 = Theme.TextMuted,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		RichText = true,
		Parent = CreditsSection,
	})
end

-- ============================================================
-- TAB SWITCHING LOGIC
-- ============================================================

local function SwitchTab(tabName)
	ActiveTab = tabName

	-- Update button visuals
	for name, tabData in pairs(TabButtons) do
		local isActive = (name == tabName)
		tabData.Button.BackgroundColor3 = isActive and Theme.Accent or Theme.Surface
		tabData.Label.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Theme.TextMuted
		tabData.Icon.ImageColor3 = isActive and Color3.fromRGB(255, 255, 255) or Theme.TextMuted
	end

	-- Show/hide panels
	LogsWrapper.Visible = (tabName ~= "Settings")
	PaginationBar.Visible = (tabName ~= "Settings")
	SettingsFrame.Visible = (tabName == "Settings")

	-- Update sidebar entries
	if tabName ~= "Settings" then
		UpdateRemoteList(tabName)
	end
end

function UpdateRemoteList(eventType)
	-- Clear sidebar
	for _, child in ipairs(TabsList:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	local logs = wax.shared.Logs[eventType]
	if not logs then
		return
	end

	local sortedLogs = {}
	for remote, log in pairs(logs) do
		table.insert(sortedLogs, log)
	end

	-- Sort by most recent call
	table.sort(sortedLogs, function(a, b)
		local aLatest = a:GetLatestCall()
		local bLatest = b:GetLatestCall()
		local aTime = aLatest and aLatest.CreationTime or 0
		local bTime = bLatest and bLatest.CreationTime or 0
		return aTime > bTime
	end)

	for _, log in ipairs(sortedLogs) do
		local entry = CreateRemoteEntry(log)
		entry.Parent = TabsList

		-- Update call count
		if log.Button then
			log.Button.Calls.Text = Helper.FormatNumber(log:GetCallCount())
		end
	end
end

-- Connect tab buttons
OutgoingTabBtn.MouseButton1Click:Connect(function() SwitchTab("Outgoing") end)
IncomingTabBtn.MouseButton1Click:Connect(function() SwitchTab("Incoming") end)
SettingsTabBtn.MouseButton1Click:Connect(function() SwitchTab("Settings") end)

-- ============================================================
-- LIVE UPDATE LOOP
-- ============================================================

-- Listen for new remote calls
wax.shared.Connect(wax.shared.Communicator.Event:Connect(function(remoteInstance, eventType, callCount)
	if ActiveTab == eventType then
		-- Check if entry already exists in sidebar
		local log = wax.shared.Logs[eventType][remoteInstance]
		if log then
			-- Update count badge
			if log.Button then
				log.Button.Calls.Text = Helper.FormatNumber(log:GetCallCount())
			else
				-- New remote, add to list
				local entry = CreateRemoteEntry(log)
				entry.Parent = TabsList
			end

			-- If currently viewing this log, refresh
			if CurrentLog == log then
				ShowLog(log)
			end
		end
	end
end))

-- Setup logging
local LoggingFunction = wax.shared.SetupLoggingConnection()
if LoggingFunction then
	wax.shared.LogConnection = wax.shared.Connect(wax.shared.Communicator.Event:Connect(LoggingFunction))
end

-- Keybind to toggle visibility (Right Shift)
wax.shared.Connect(wax.shared.UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		MainFrame.Visible = not MainFrame.Visible
	end
end))

-- Initialize default tab
SwitchTab("Outgoing")

return {}
