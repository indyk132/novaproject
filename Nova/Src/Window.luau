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

-- Forward declarations
local SwitchTab, ShowCallDetails, ShowLog, CloseSearch, UpdateRemoteList

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

Drag.new(MainFrame, TitleBar, GetDPIScale)

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

-- Close, Minimize, Search buttons
local WindowButtons = Interface.New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 110, 1, 0),
	Position = UDim2.new(1, -110, 0, 0),
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

-- Search button
local SearchButton = CreateWindowButton("search", function()
	-- Will be connected after search modal creation
end)

-- Separator dot
Interface.New("Frame", {
	BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	Size = UDim2.fromOffset(4, 4),
	Parent = WindowButtons,
	["UICorner"] = { CornerRadius = UDim.new(1, 0) },
})

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

	-- Right-click context menu
	entry.MouseButton2Click:Connect(function()
		local mouse = wax.shared.UserInputService:GetMouseLocation()
		ShowContextMenu(logEntry, mouse)
	end)

	-- Update function
	logEntry:SetButton(entry, nameLabel, countBadge)

	return entry
end

-- ============================================================
-- SEARCH MODAL
-- ============================================================

local ModalBackground = Interface.New("TextButton", {
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.5,
	Size = UDim2.fromScale(1, 1),
	Text = "",
	Visible = false,
	ZIndex = 60,
	AutoButtonColor = false,
	Parent = MainFrame,
	["UICorner"] = { CornerRadius = UDim.new(0, 8) },
})

local SearchFrame = Interface.New("Frame", {
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	Size = UDim2.new(0.55, 0, 0.75, 0),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Visible = false,
	ZIndex = 61,
	Parent = MainFrame,
	["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	["UIStroke"] = {
		Color = Color3.fromRGB(25, 25, 25),
		Thickness = 1,
	},
})

-- Search box
local SearchBox = Interface.New("TextBox", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -40, 0, 36),
	Position = UDim2.new(0, 8, 0, 0),
	Text = "",
	PlaceholderText = "Search for remotes...",
	PlaceholderColor3 = Color3.fromRGB(128, 128, 128),
	TextColor3 = Theme.Text,
	TextSize = 15,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	ZIndex = 62,
	Parent = SearchFrame,
	["UIPadding"] = {
		PaddingLeft = UDim.new(0, 6),
	},
})

local searchIcon = Interface.New("ImageLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(16, 16),
	Position = UDim2.new(1, -28, 0, 10),
	ImageColor3 = Theme.TextMuted,
	ZIndex = 62,
	Parent = SearchFrame,
})
Icons.ApplyIcon(searchIcon, "search")

-- Separator
Interface.New("Frame", {
	BackgroundColor3 = Color3.fromRGB(25, 25, 25),
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 0, 36),
	ZIndex = 62,
	Parent = SearchFrame,
})

-- Class filter bar
local FilterBar = Interface.New("ScrollingFrame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 32),
	Position = UDim2.new(0, 0, 0, 37),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	CanvasSize = UDim2.fromScale(0, 0),
	ScrollBarThickness = 0,
	ZIndex = 62,
	Parent = SearchFrame,
	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
	},
	["UIPadding"] = {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	},
})

local SearchClassFilter = "All"
local FilterButtons = {}

local ClassFilters = { "All", "RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent", "BindableEvent", "BindableFunction" }

for _, className in ipairs(ClassFilters) do
	local isActive = (className == SearchClassFilter)
	local fbtn = Interface.New("TextButton", {
		Text = className == "UnreliableRemoteEvent" and "Unreliable" or className,
		TextColor3 = Theme.Text,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		BackgroundColor3 = isActive and Color3.fromRGB(25, 25, 25) or Color3.fromRGB(15, 15, 15),
		Size = UDim2.new(0, 0, 0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		AutoButtonColor = false,
		ZIndex = 63,
		Parent = FilterBar,
		["UICorner"] = { CornerRadius = UDim.new(0, 4) },
		["UIPadding"] = {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		},
	})
	FilterButtons[className] = fbtn
end

-- Separator
Interface.New("Frame", {
	BackgroundColor3 = Color3.fromRGB(25, 25, 25),
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 0, 69),
	ZIndex = 62,
	Parent = SearchFrame,
})

-- Search results
local SearchResults = Interface.New("ScrollingFrame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, -70),
	Position = UDim2.new(0, 0, 0, 70),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromScale(0, 0),
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Theme.Border,
	ZIndex = 62,
	Parent = SearchFrame,
	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 2),
	},
	["UIPadding"] = {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 4),
	},
})

local function RefreshSearch()
	for _, child in ipairs(SearchResults:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	local query = string.lower(SearchBox.Text)

	for _, eventType in ipairs({"Outgoing", "Incoming"}) do
		local logs = wax.shared.Logs[eventType]
		if not logs then continue end

		for remote, log in pairs(logs) do
			local name = remote.Name
			local className = remote.ClassName

			-- Filter by class
			if SearchClassFilter ~= "All" and className ~= SearchClassFilter then
				continue
			end

			-- Filter by text
			if query ~= "" and not string.find(string.lower(name), query, 1, true) then
				continue
			end

			local resultBtn = Interface.New("TextButton", {
				Text = "",
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				AutoButtonColor = false,
				ZIndex = 63,
				Parent = SearchResults,
				["UICorner"] = { CornerRadius = UDim.new(0, 6) },
			})

			local rIcon = Interface.New("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.new(0, 8, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Image = Images[className] or Images.RemoteEvent,
				ZIndex = 64,
				Parent = resultBtn,
			})

			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -90, 1, 0),
				Position = UDim2.new(0, 30, 0, 0),
				Text = name,
				TextColor3 = Theme.Text,
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 64,
				Parent = resultBtn,
			})

			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 60, 1, 0),
				Position = UDim2.new(1, -68, 0, 0),
				Text = eventType,
				TextColor3 = eventType == "Incoming" and Theme.Incoming or Theme.Outgoing,
				TextTransparency = 0.5,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 64,
				Parent = resultBtn,
			})

			resultBtn.MouseEnter:Connect(function()
				resultBtn.BackgroundTransparency = 0
			end)
			resultBtn.MouseLeave:Connect(function()
				resultBtn.BackgroundTransparency = 1
			end)

			resultBtn.MouseButton1Click:Connect(function()
				-- Switch to the correct tab and show this log
				CloseSearch()
				SwitchTab(eventType)
				CurrentLog = log
				ShowLog(log)
			end)
		end
	end
end

local function UpdateFilterButtons()
	for className, fbtn in pairs(FilterButtons) do
		fbtn.BackgroundColor3 = (className == SearchClassFilter) and Color3.fromRGB(25, 25, 25) or Color3.fromRGB(15, 15, 15)
	end
end

for className, fbtn in pairs(FilterButtons) do
	fbtn.MouseButton1Click:Connect(function()
		SearchClassFilter = className
		UpdateFilterButtons()
		RefreshSearch()
	end)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(RefreshSearch)

local function OpenSearch()
	ModalBackground.Visible = true
	SearchFrame.Visible = true
	SearchBox.Text = ""
	SearchBox:CaptureFocus()
	RefreshSearch()
end

CloseSearch = function()
	ModalBackground.Visible = false
	SearchFrame.Visible = false
end

ModalBackground.MouseButton1Click:Connect(CloseSearch)

-- Connect search button
SearchButton.MouseButton1Click:Connect(OpenSearch)

-- ============================================================
-- RESIZABLE SIDEBAR DIVIDER
-- ============================================================

local SidebarDivider = Interface.New("Frame", {
	BackgroundColor3 = Color3.fromRGB(25, 25, 25),
	Size = UDim2.new(0, 2, 1, -36),
	Position = UDim2.new(0, 240, 0, 36),
	ZIndex = 5,
	Parent = MainFrame,
})

local DividerHandle = Interface.New("TextButton", {
	Text = "",
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 8, 1, 0),
	Position = UDim2.new(0.5, 0, 0, 0),
	AnchorPoint = Vector2.new(0.5, 0),
	AutoButtonColor = false,
	ZIndex = 6,
	Parent = SidebarDivider,
})

local isDraggingDivider = false
local dividerDragStart = nil
local dividerStartWidth = 240

DividerHandle.MouseEnter:Connect(function()
	SidebarDivider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end)
DividerHandle.MouseLeave:Connect(function()
	if not isDraggingDivider then
		SidebarDivider.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	end
end)

DividerHandle.MouseButton1Down:Connect(function()
	isDraggingDivider = true
	dividerDragStart = wax.shared.UserInputService:GetMouseLocation().X
	dividerStartWidth = TabBar.Size.X.Offset
end)

wax.shared.Connect(wax.shared.UserInputService.InputChanged:Connect(function(input)
	if isDraggingDivider and input.UserInputType == Enum.UserInputType.MouseMovement then
		local scale = GetDPIScale()
		local delta = (input.Position.X - dividerDragStart) / scale
		local newWidth = math.clamp(dividerStartWidth + delta, 140, math.floor(MainFrame.AbsoluteSize.X / 2))

		TabBar.Size = UDim2.new(0, newWidth, 1, -36)
		SidebarDivider.Position = UDim2.new(0, newWidth, 0, 36)
		LogsWrapper.Size = UDim2.new(1, -(newWidth + 2), 1, -36)
	end
end))

wax.shared.Connect(wax.shared.UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDraggingDivider = false
		SidebarDivider.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	end
end))

-- ============================================================
-- LOG DISPLAY
-- ============================================================

-- Call-level context menu
local CallContextMenu = Interface.New("Frame", {
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	Size = UDim2.fromOffset(170, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Visible = false,
	ZIndex = 200,
	Parent = ScreenGui,

	["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	["UIStroke"] = {
		Color = Theme.Border,
		Thickness = 1,
	},
	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 0),
	},
	["UIPadding"] = {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	},
})

local CallContextTarget = nil -- { logEntry, callInfo, callIndex }

local function CreateCallContextMenuItem(text, iconName, callback)
	local item = Interface.New("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		AutoButtonColor = false,
		ZIndex = 201,
		Parent = CallContextMenu,
		["UIPadding"] = {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		},
	})

	local itemInner = Interface.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 201,
		Parent = item,
		["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	})

	local ico = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 6, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Theme.TextMuted,
		ZIndex = 202,
		Parent = itemInner,
	})
	Icons.ApplyIcon(ico, iconName)

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 26, 0, 0),
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 202,
		Parent = itemInner,
	})

	item.MouseEnter:Connect(function()
		itemInner.BackgroundTransparency = 0
		itemInner.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	end)
	item.MouseLeave:Connect(function()
		itemInner.BackgroundTransparency = 1
	end)

	item.MouseButton1Click:Connect(function()
		CallContextMenu.Visible = false
		if CallContextTarget then
			callback(CallContextTarget.logEntry, CallContextTarget.callInfo, CallContextTarget.callIndex)
		end
	end)
end

CreateCallContextMenuItem("Copy Calling Code", "forward", function(logEntry, callInfo)
	local code = CodeGen.GenerateCode(logEntry, callInfo)
	local success = pcall(setclipboard, code)
	if success then
		wax.shared.Sonner.success("Copied calling code")
	end
end)

CreateCallContextMenuItem("Copy Intercept Code", "shield-alert", function(logEntry)
	local code = CodeGen.GenerateInterceptCode(logEntry)
	local success = pcall(setclipboard, code)
	if success then
		wax.shared.Sonner.success("Copied intercept code")
	end
end)

CreateCallContextMenuItem("Copy Script Path", "clipboard-copy", function(logEntry)
	local path = CodeGen.GetFullPath(logEntry.Instance, { VariableName = "Remote" })
	local success = pcall(setclipboard, path)
	if success then
		wax.shared.Sonner.success("Copied remote path")
	end
end)

CreateCallContextMenuItem("Replay", "play", function(logEntry, callInfo)
	if logEntry.Type == "Outgoing" then
		wax.shared.Sonner.promise(function()
			wax.shared.ReplayCallInfo(callInfo, logEntry.Type)
		end, {
			loadingText = "Replaying...",
			successText = "Replayed!",
			errorText = "Failed to replay",
		})
	else
		wax.shared.Sonner.info("Can only replay outgoing events")
	end
end)

-- Close call context menu on click
wax.shared.Connect(wax.shared.UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
		task.defer(function()
			if CallContextMenu.Visible then
				CallContextMenu.Visible = false
			end
		end)
	end
end))

-- Close info dropdown on click outside
wax.shared.Connect(wax.shared.UserInputService.InputBegan:Connect(function(input)
	if not CurrentInfoDropdown then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end

	local pos = input.Position
	local function isOver(frame)
		local ap, as = frame.AbsolutePosition, frame.AbsoluteSize
		return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
	end

	if isOver(InfoDropdownFrame) or isOver(CurrentInfoDropdown.Parent) then
		return
	end

	task.defer(function()
		if CurrentInfoDropdown then
			CurrentInfoDropdown:Close()
		end
	end)
end))

-- Creates a single call entry GUI element for the logs list
local function CreateCallEntry(logEntry, callInfo, i, parent)
	-- Cobalt-style CallFrame: auto-sizing, with inline args
	local callEntry = Interface.New("TextButton", {
		Text = "",
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AutoButtonColor = false,
		LayoutOrder = i,
		ClipsDescendants = true,
		Parent = parent,

		["UICorner"] = { CornerRadius = UDim.new(0, 6) },
		["UIListLayout"] = {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 4),
		},
		["UIPadding"] = {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		},
	})

	-- Hover highlight stroke
	local highlightStroke = Interface.New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.fromRGB(75, 75, 75),
		Transparency = 1,
		Parent = callEntry,
	})

	callEntry.MouseEnter:Connect(function()
		wax.shared.TweenService:Create(highlightStroke, TweenInfo.new(0.15), {
			Transparency = 0,
		}):Play()
	end)
	callEntry.MouseLeave:Connect(function()
		wax.shared.TweenService:Create(highlightStroke, TweenInfo.new(0.15), {
			Transparency = 1,
		}):Play()
	end)

	-- Top header: call number + method in one line
	local headerRow = Interface.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = callEntry,
	})

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 30, 1, 0),
		Text = `#{i}`,
		TextColor3 = Theme.TextMuted,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = headerRow,
	})

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 120, 1, 0),
		Position = UDim2.new(0, 32, 0, 0),
		Text = callInfo.Method or "Unknown",
		TextColor3 = Theme.Accent,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = headerRow,
	})

	-- Executor badge (right-aligned)
	if callInfo.IsExecutor then
		Interface.New("TextLabel", {
			BackgroundColor3 = Theme.Warning,
			BackgroundTransparency = 0.85,
			Size = UDim2.fromOffset(56, 16),
			Position = UDim2.new(1, -56, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Text = "Executor",
			TextColor3 = Theme.Warning,
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			Parent = headerRow,
			["UICorner"] = { CornerRadius = UDim.new(0, 4) },
		})
	end

	-- Inline arguments frame
	local argsCount = callInfo.Args and #callInfo.Args or 0
	if argsCount > 0 then
		local argsFrame = Interface.New("Frame", {
			BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = callEntry,

			["UICorner"] = { CornerRadius = UDim.new(0, 6) },
			["UIListLayout"] = {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 2),
			},
			["UIPadding"] = {
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			},
		})

		local maxArgs = math.min(argsCount, 8) -- cap at 8 inline for perf
		for argIdx = 1, maxArgs do
			local arg = callInfo.Args[argIdx]
			local argColor = SyntaxHighlighter.GetArgumentColor(arg)
			local argText = Helper.QuickSerializeArgument(arg)

			local argHolder = Interface.New("Frame", {
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = argIdx,
				Parent = argsFrame,
				["UICorner"] = { CornerRadius = UDim.new(0, 4) },
				["UIPadding"] = {
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
				},
			})

			-- Index
			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 16, 1, 0),
				Text = tostring(argIdx),
				TextColor3 = Theme.TextMuted,
				TextTransparency = 0.5,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = argHolder,
			})

			-- Value (color-coded)
			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -70, 1, 0),
				Position = UDim2.new(0, 18, 0, 0),
				Text = argText,
				TextColor3 = argColor,
				TextSize = 12,
				Font = Enum.Font.Code,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = argHolder,
			})

			-- Type (right-aligned, muted)
			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 50, 1, 0),
				Position = UDim2.new(1, -50, 0, 0),
				Text = typeof(arg),
				TextColor3 = Theme.TextMuted,
				TextTransparency = 0.5,
				TextSize = 10,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = argHolder,
			})
		end

		if argsCount > maxArgs then
			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Text = `... and {argsCount - maxArgs} more`,
				TextColor3 = Theme.TextMuted,
				TextTransparency = 0.5,
				TextSize = 11,
				Font = Enum.Font.GothamMedium,
				Parent = argsFrame,
			})
		end
	end

	-- Bottom info row: origin + timestamp
	local bottomRow = Interface.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = callEntry,
	})

	-- Origin icon
	local originIconName = callInfo.IsExecutor and "terminal" or "gamepad-2"
	local originIcon = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Theme.TextMuted,
		ImageTransparency = 0.5,
		Parent = bottomRow,
	})
	Icons.ApplyIcon(originIcon, originIconName)

	-- Origin name
	local originText = "Unknown"
	if callInfo.Origin and typeof(callInfo.Origin) == "Instance" then
		originText = callInfo.Origin.Name
	end
	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.6, -20, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		Text = originText,
		TextColor3 = Theme.TextMuted,
		TextTransparency = 0.5,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = bottomRow,
	})

	-- Timestamp
	local timeText = ""
	if callInfo.CreationTime then
		timeText = `Time: {Helper.FormatTimestamp(callInfo.CreationTime - (wax.shared.NovaStartTime or 0))}`
	end
	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.4, 0, 1, 0),
		Position = UDim2.new(0.6, 0, 0, 0),
		Text = timeText,
		TextColor3 = Theme.TextMuted,
		TextTransparency = 0.5,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = bottomRow,
	})

	-- Left-click to view details
	callEntry.MouseButton1Click:Connect(function()
		CurrentInfo = callInfo
		ShowCallDetails(logEntry, callInfo, i)
	end)

	-- Right-click for call context menu
	callEntry.MouseButton2Click:Connect(function()
		local mouse = wax.shared.UserInputService:GetMouseLocation()
		CallContextTarget = { logEntry = logEntry, callInfo = callInfo, callIndex = i }
		CallContextMenu.Position = UDim2.fromOffset(mouse.X, mouse.Y)
		CallContextMenu.Visible = true
	end)

	return callEntry
end

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
		CreateCallEntry(logEntry, callInfo, i, LogsList)
	end
end

-- ============================================================
-- CALL DETAILS PANEL (Tabbed)
-- ============================================================

local InfoFrame = Interface.New("Frame", {
	BackgroundColor3 = Theme.Background,
	Size = UDim2.fromOffset(400, 340),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Visible = false,
	ZIndex = 50,
	ClipsDescendants = true,
	Parent = ScreenGui,

	["UICorner"] = { CornerRadius = UDim.new(0, 8) },
	["UIStroke"] = {
		Color = Theme.Border,
		Thickness = 1,
	},
})

Drag.new(InfoFrame, nil, GetDPIScale)
Resize.new({
	MainFrame = InfoFrame,
	MinimumSize = UDim2.fromOffset(320, 240),
})

-- Title bar
local InfoTitleBar = Interface.New("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 0, 30),
	BorderSizePixel = 0,
	ZIndex = 51,
	Parent = InfoFrame,
	["UICorner"] = { CornerRadius = UDim.new(0, 8) },
})

local InfoTitle = Interface.New("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -36, 1, 0),
	Position = UDim2.new(0, 10, 0, 0),
	Text = "Call Details",
	TextColor3 = Theme.Text,
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 52,
	Parent = InfoTitleBar,
})

local CloseInfoBtn = Interface.New("TextButton", {
	Text = "",
	BackgroundColor3 = Theme.SurfaceHover,
	BackgroundTransparency = 0.5,
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.new(1, -28, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	AutoButtonColor = false,
	ZIndex = 52,
	Parent = InfoTitleBar,
	["UICorner"] = { CornerRadius = UDim.new(0, 6) },
})

local closeIcon = Interface.New("ImageLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(10, 10),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	ImageColor3 = Theme.TextMuted,
	ZIndex = 53,
	Parent = CloseInfoBtn,
})
Icons.ApplyIcon(closeIcon, "x")
CloseInfoBtn.MouseButton1Click:Connect(function()
	InfoFrame.Visible = false
	if CurrentInfoDropdown then
		CurrentInfoDropdown:Close()
	end
end)

-- Top tabs bar (Arguments / Code / Function Info)
local InfoTabBar = Interface.New("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 0, 28),
	Position = UDim2.new(0, 0, 0, 30),
	BorderSizePixel = 0,
	ZIndex = 51,
	Parent = InfoFrame,
})

local InfoTabLayout = Interface.New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Parent = InfoTabBar,
	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 0),
	},
})

local InfoActiveTab = "Arguments"
local InfoTabButtons = {}
local InfoTabPages = {}

local function CreateInfoTab(name, iconName)
	local btn = Interface.New("TextButton", {
		Text = "",
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.5,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		AutoButtonColor = false,
		ZIndex = 52,
		Parent = InfoTabLayout,
		["UIPadding"] = {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		},
	})

	local tabIcon = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Theme.TextMuted,
		ZIndex = 53,
		Parent = btn,
	})
	Icons.ApplyIcon(tabIcon, iconName)

	local tabLabel = Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0, 14, 0, 0),
		Text = name,
		TextColor3 = Theme.TextMuted,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		ZIndex = 53,
		Parent = btn,
	})

	-- Underline indicator
	local underline = Interface.New("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		Visible = false,
		ZIndex = 53,
		Parent = btn,
	})

	InfoTabButtons[name] = { Button = btn, Icon = tabIcon, Label = tabLabel, Underline = underline }
	return btn
end

CreateInfoTab("Arguments", "list")
CreateInfoTab("Code", "code")
CreateInfoTab("Function Info", "info")

-- Tab content area
local InfoContentArea = Interface.New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, -92),
	Position = UDim2.new(0, 0, 0, 58),
	ZIndex = 51,
	Parent = InfoFrame,
})

-- Create pages for each tab
for _, tabName in ipairs({"Arguments", "Code", "Function Info"}) do
	local page = Interface.New("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.new(0, 5, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Border,
		BorderSizePixel = 0,
		Visible = tabName == "Arguments",
		ZIndex = 51,
		Parent = InfoContentArea,
		["UIListLayout"] = {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 3),
		},
		["UIPadding"] = {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		},
	})
	InfoTabPages[tabName] = page
end

local function SwitchInfoTab(tabName)
	InfoActiveTab = tabName
	for name, data in pairs(InfoTabButtons) do
		local isActive = (name == tabName)
		data.Label.TextColor3 = isActive and Theme.Text or Theme.TextMuted
		data.Icon.ImageColor3 = isActive and Theme.Accent or Theme.TextMuted
		data.Underline.Visible = isActive
	end
	for name, page in pairs(InfoTabPages) do
		page.Visible = (name == tabName)
	end
end

for name, data in pairs(InfoTabButtons) do
	data.Button.MouseButton1Click:Connect(function()
		SwitchInfoTab(name)
	end)
end

-- Bottom action bar (Code / Origin / Event)
local BottomBar = Interface.New("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 0, 34),
	Position = UDim2.new(0, 0, 1, -34),
	BorderSizePixel = 0,
	ZIndex = 52,
	Parent = InfoFrame,
	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
	},
	["UIPadding"] = {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	},
})

local CurrentDetailLogEntry = nil
local CurrentDetailCallInfo = nil

-- Shared dropdown menu frame (Cobalt-style: single shared frame repositioned per button)
local CurrentInfoDropdown = nil -- tracks which dropdown data is active
local InfoDropdownFrame = Interface.New("Frame", {
	Size = UDim2.fromOffset(170, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = Theme.Surface,
	ZIndex = 10000,
	Visible = false,
	ClipsDescendants = false,
	Parent = ScreenGui,
	["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = UDim.new(0, 0),
	},
	["UIPadding"] = {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	},
	["UIStroke"] = {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Theme.Border,
		Thickness = 1,
	},
})

local function CreateInfoDropdownButton(iconName, title, options)
	local DropdownData = {
		Parent = nil,
		Options = {},
	}

	local function BuildDropdownItems()
		for obj, _ in pairs(DropdownData.Options) do
			obj:Destroy()
		end
		DropdownData.Options = {}

		for order, data in ipairs(options) do
			-- Skip items with failed conditions
			if data.Condition and not data.Condition() then
				continue
			end

			local itemBtn = Interface.New("TextButton", {
				BackgroundColor3 = Theme.SurfaceHover,
				BackgroundTransparency = 1,
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 30),
				Text = "",
				ZIndex = 10001,
				["UICorner"] = { CornerRadius = UDim.new(0, 6) },
				["UIPadding"] = {
					PaddingBottom = UDim.new(0, 6),
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
					PaddingTop = UDim.new(0, 6),
				},
			})

			local itemIcon = Interface.New("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				ImageColor3 = Theme.TextMuted,
				ZIndex = 10002,
				Parent = itemBtn,
			})
			local iconName = typeof(data.Icon) == "function" and data.Icon() or data.Icon
			Icons.ApplyIcon(itemIcon, iconName)

			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(20, 0),
				Size = UDim2.new(1, -20, 1, 0),
				Text = typeof(data.Text) == "function" and data.Text() or data.Text,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 10002,
				Parent = itemBtn,
			})

			itemBtn.MouseEnter:Connect(function()
				wax.shared.TweenService:Create(itemBtn, TweenInfo.new(0.1), {
					BackgroundTransparency = 0,
				}):Play()
			end)
			itemBtn.MouseLeave:Connect(function()
				wax.shared.TweenService:Create(itemBtn, TweenInfo.new(0.1), {
					BackgroundTransparency = 1,
				}):Play()
			end)
			itemBtn.MouseButton1Click:Connect(function()
				itemBtn.BackgroundTransparency = 1
				if data.Callback then
					data.Callback()
				end
				DropdownData:Close()
			end)

			DropdownData.Options[itemBtn] = data
		end
	end

	function DropdownData:Open()
		if CurrentInfoDropdown == DropdownData then
			return
		end

		if CurrentInfoDropdown then
			CurrentInfoDropdown:Close()
		end

		CurrentInfoDropdown = DropdownData

		-- Build items
		BuildDropdownItems()

		-- Parent items into the shared frame
		for obj, _ in pairs(DropdownData.Options) do
			obj.Parent = InfoDropdownFrame
		end

		-- Position: above the button
		local scale = GetDPIScale()
		InfoDropdownFrame.Position = UDim2.fromOffset(
			DropdownData.Parent.AbsolutePosition.X / scale,
			(DropdownData.Parent.AbsolutePosition.Y + DropdownData.Parent.AbsoluteSize.Y) / scale
		)
		InfoDropdownFrame.Visible = true
	end

	function DropdownData:Toggle()
		if CurrentInfoDropdown == DropdownData then
			DropdownData:Close()
			return
		end
		DropdownData:Open()
	end

	function DropdownData:Close()
		if CurrentInfoDropdown ~= DropdownData then
			return
		end

		InfoDropdownFrame.Visible = false
		for obj, _ in pairs(DropdownData.Options) do
			obj.Parent = nil
		end
		CurrentInfoDropdown = nil
	end

	-- Create the button
	local btn = Interface.New("TextButton", {
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.SurfaceHover,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 26),
		Text = "",
		ZIndex = 53,
		Parent = BottomBar,
		["UICorner"] = { CornerRadius = UDim.new(0, 6) },
		["UIPadding"] = {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		},
		["UIStroke"] = {
			Color = Theme.Border,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		},
	})

	DropdownData.Parent = btn

	local btnIcon = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Theme.TextMuted,
		ZIndex = 54,
		Parent = btn,
	})
	Icons.ApplyIcon(btnIcon, iconName)

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0, 1),
		Position = UDim2.fromOffset(18, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		ZIndex = 54,
		Parent = btn,
	})

	btn.MouseEnter:Connect(function()
		wax.shared.TweenService:Create(btn, TweenInfo.new(0.1), {
			BackgroundTransparency = 0,
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		wax.shared.TweenService:Create(btn, TweenInfo.new(0.1), {
			BackgroundTransparency = 1,
		}):Play()
	end)
	btn.MouseButton1Click:Connect(DropdownData.Toggle)

	return DropdownData
end

-- ===== CODE dropdown =====
CreateInfoDropdownButton("code", "Code", {
	{
		Text = "Calling Code",
		Icon = "forward",
		Callback = function()
			if not (CurrentDetailLogEntry and CurrentDetailCallInfo) then
				wax.shared.Sonner.info("No call details available")
				return
			end
			local code = CodeGen.GenerateCode(CurrentDetailLogEntry, CurrentDetailCallInfo)
			local success = pcall(setclipboard, code)
			if success then
				wax.shared.Sonner.success("Copied calling code")
			end
		end,
	},
	{
		Text = "Intercept Code",
		Icon = "shield-alert",
		Callback = function()
			if not CurrentDetailLogEntry then
				wax.shared.Sonner.info("No call details available")
				return
			end
			local code = CodeGen.GenerateInterceptCode(CurrentDetailLogEntry)
			local success = pcall(setclipboard, code)
			if success then
				wax.shared.Sonner.success("Copied intercept code")
			end
		end,
	},
})

-- ===== ORIGIN dropdown =====
CreateInfoDropdownButton("file-text", "Origin", {
	{
		Text = "Remote Path",
		Icon = "package-search",
		Callback = function()
			if not CurrentDetailLogEntry then
				wax.shared.Sonner.info("No call details available")
				return
			end
			local path = CodeGen.GetFullPath(CurrentDetailLogEntry.Instance, { VariableName = "Remote" })
			local success = pcall(setclipboard, path)
			if success then
				wax.shared.Sonner.success("Copied remote path")
			end
		end,
	},
	{
		Text = "Script Path",
		Icon = "file-search",
		Condition = function()
			return CurrentDetailCallInfo and CurrentDetailCallInfo.Origin and typeof(CurrentDetailCallInfo.Origin) == "Instance"
		end,
		Callback = function()
			if not (CurrentDetailCallInfo and CurrentDetailCallInfo.Origin and typeof(CurrentDetailCallInfo.Origin) == "Instance") then
				return
			end
			local success = pcall(setclipboard, CurrentDetailCallInfo.Origin:GetFullName())
			if success then
				wax.shared.Sonner.success("Copied script path")
			end
		end,
	},
	{
		Text = "Decompile Script",
		Icon = "file-code",
		Condition = function()
			return CurrentDetailCallInfo
				and CurrentDetailCallInfo.Origin
				and typeof(CurrentDetailCallInfo.Origin) == "Instance"
				and typeof(decompile) == "function"
		end,
		Callback = function()
			if not (CurrentDetailCallInfo and CurrentDetailCallInfo.Origin and typeof(CurrentDetailCallInfo.Origin) == "Instance") then
				return
			end
			local ok, result = pcall(decompile, CurrentDetailCallInfo.Origin)
			if ok then
				pcall(setclipboard, result)
				wax.shared.Sonner.success("Decompiled and copied")
			else
				wax.shared.Sonner.error("Failed to decompile")
			end
		end,
	},
})

-- ===== EVENT dropdown =====
CreateInfoDropdownButton("git-branch", "Event", {
	{
		Text = "Copy Event Path",
		Icon = "copy",
		Callback = function()
			if not CurrentDetailLogEntry then
				wax.shared.Sonner.info("No call details available")
				return
			end
			local path = CodeGen.GetFullPath(CurrentDetailLogEntry.Instance, { VariableName = "Remote" })
			local success = pcall(setclipboard, path)
			if success then
				wax.shared.Sonner.success("Copied event path")
			end
		end,
	},
	{
		Text = "Replay",
		Icon = "play",
		Condition = function()
			return CurrentDetailLogEntry and CurrentDetailLogEntry.Type == "Outgoing" and CurrentDetailCallInfo
		end,
		Callback = function()
			if not (CurrentDetailLogEntry and CurrentDetailCallInfo) then
				return
			end
			wax.shared.Sonner.promise(function()
				wax.shared.ReplayCallInfo(CurrentDetailCallInfo, CurrentDetailLogEntry.Type)
			end, {
				loadingText = "Replaying...",
				successText = "Replayed!",
				errorText = "Failed to replay",
			})
		end,
	},
	{
		Text = function()
			if CurrentDetailLogEntry and CurrentDetailLogEntry.Ignored then
				return "Unignore"
			end
			return "Ignore"
		end,
		Icon = function()
			if CurrentDetailLogEntry and CurrentDetailLogEntry.Ignored then
				return "eye"
			end
			return "eye-off"
		end,
		Condition = function()
			return CurrentDetailLogEntry ~= nil
		end,
		Callback = function()
			if not CurrentDetailLogEntry then return end
			CurrentDetailLogEntry:Ignore()
			wax.shared.Sonner.success(`{CurrentDetailLogEntry.Ignored and "Ignoring" or "Unignored"} {CurrentDetailLogEntry.Instance.Name}`)
		end,
	},
	{
		Text = function()
			if CurrentDetailLogEntry and CurrentDetailLogEntry.Blocked then
				return "Unblock"
			end
			return "Block"
		end,
		Icon = function()
			if CurrentDetailLogEntry and CurrentDetailLogEntry.Blocked then
				return "lock"
			end
			return "lock-open"
		end,
		Condition = function()
			return CurrentDetailLogEntry ~= nil
		end,
		Callback = function()
			if not CurrentDetailLogEntry then return end
			CurrentDetailLogEntry:Block()
			wax.shared.Sonner.success(`{CurrentDetailLogEntry.Blocked and "Blocking" or "Unblocked"} {CurrentDetailLogEntry.Instance.Name}`)
		end,
	},
})

-- ============================================================
-- RIGHT-CLICK CONTEXT MENU
-- ============================================================

local ContextMenu = Interface.New("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.fromOffset(140, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Visible = false,
	ZIndex = 200,
	Parent = ScreenGui,

	["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	["UIStroke"] = {
		Color = Theme.Border,
		Thickness = 1,
	},
	["UIListLayout"] = {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 0),
	},
	["UIPadding"] = {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	},
})

local ContextMenuTarget = nil

local function CreateContextMenuItem(text, iconName, callback)
	local item = Interface.New("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		AutoButtonColor = false,
		ZIndex = 201,
		Parent = ContextMenu,
	})

	local ico = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Theme.TextMuted,
		ZIndex = 202,
		Parent = item,
	})
	Icons.ApplyIcon(ico, iconName)

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -34, 1, 0),
		Position = UDim2.new(0, 30, 0, 0),
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 202,
		Parent = item,
	})

	item.MouseEnter:Connect(function()
		item.BackgroundTransparency = 0
		item.BackgroundColor3 = Theme.SurfaceHover
	end)
	item.MouseLeave:Connect(function()
		item.BackgroundTransparency = 1
	end)

	item.MouseButton1Click:Connect(function()
		ContextMenu.Visible = false
		if ContextMenuTarget then
			callback(ContextMenuTarget)
		end
	end)
end

CreateContextMenuItem("Event", "git-branch", function(logEntry)
	local path = CodeGen.GetFullPath(logEntry.Instance, { VariableName = "Remote" })
	local success = pcall(setclipboard, path)
	if success then
		wax.shared.Sonner.success("Copied event path")
	end
end)

CreateContextMenuItem("Replay", "play", function(logEntry)
	if logEntry.Type == "Outgoing" then
		local latestCall = logEntry:GetLatestCall()
		if latestCall then
			wax.shared.Sonner.promise(function()
				wax.shared.ReplayCallInfo(latestCall, logEntry.Type)
			end, {
				loadingText = "Replaying...",
				successText = "Replayed!",
				errorText = "Failed to replay",
			})
		end
	else
		wax.shared.Sonner.info("Can only replay outgoing events")
	end
end)

CreateContextMenuItem("Ignore", "eye-off", function(logEntry)
	logEntry:Ignore()
	wax.shared.Sonner.success(`{logEntry.Ignored and "Ignoring" or "Unignored"} {logEntry.Instance.Name}`)
end)

CreateContextMenuItem("Block", "lock", function(logEntry)
	logEntry:Block()
	wax.shared.Sonner.success(`{logEntry.Blocked and "Blocking" or "Unblocked"} {logEntry.Instance.Name}`)
end)

CreateContextMenuItem("Clear Logs", "trash-2", function(logEntry)
	logEntry.Calls = {}
	logEntry.GameCalls = {}
	if logEntry.Button then
		logEntry.Button.Calls.Text = "0"
	end
	if CurrentLog == logEntry then
		ShowLog(logEntry)
	end
	wax.shared.Sonner.success(`Cleared logs for {logEntry.Instance.Name}`)
end)

-- Close context menu on click elsewhere
wax.shared.Connect(wax.shared.UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
		task.defer(function()
			if ContextMenu.Visible then
				ContextMenu.Visible = false
			end
		end)
	end
end))

local function ShowContextMenu(logEntry, position)
	ContextMenuTarget = logEntry
	ContextMenu.Position = UDim2.fromOffset(position.X, position.Y)
	ContextMenu.Visible = true
end

-- ============================================================
-- SHOW CALL DETAILS (populates tabs)
-- ============================================================

function ShowCallDetails(logEntry, callInfo, callIndex)
	InfoFrame.Visible = true
	InfoTitle.Text = `#{callIndex} {logEntry.Instance.Name}`
	CurrentDetailLogEntry = logEntry
	CurrentDetailCallInfo = callInfo

	-- Clear all tab pages
	for _, page in pairs(InfoTabPages) do
		for _, child in ipairs(page:GetChildren()) do
			if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
				child:Destroy()
			end
		end
	end

	-- ========== ARGUMENTS TAB ==========
	local argsPage = InfoTabPages["Arguments"]

	if callInfo.Args and #callInfo.Args > 0 then
		for i, arg in ipairs(callInfo.Args) do
			local argRow = Interface.New("Frame", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, 24),
				ZIndex = 52,
				Parent = argsPage,
				["UICorner"] = { CornerRadius = UDim.new(0, 4) },
				["UIPadding"] = {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				},
			})

			-- Arg index
			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 20, 1, 0),
				Text = tostring(i),
				TextColor3 = Theme.TextMuted,
				TextSize = 11,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 53,
				Parent = argRow,
			})

			-- Value
			local valueStr = tostring(arg)
			if typeof(arg) == "Instance" then
				valueStr = arg:GetFullName()
			end
			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -80, 1, 0),
				Position = UDim2.new(0, 24, 0, 0),
				Text = `"{Helper.Truncate(valueStr, 40)}"`,
				TextColor3 = Theme.Success,
				TextSize = 11,
				Font = Enum.Font.Code,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 53,
				Parent = argRow,
			})

			-- Type
			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 50, 1, 0),
				Position = UDim2.new(1, -50, 0, 0),
				Text = typeof(arg),
				TextColor3 = Theme.TextMuted,
				TextSize = 10,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 53,
				Parent = argRow,
			})
		end
	else
		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			Text = "No arguments",
			TextColor3 = Theme.TextMuted,
			TextSize = 11,
			Font = Enum.Font.GothamMedium,
			ZIndex = 52,
			Parent = argsPage,
		})
	end

	-- ========== CODE TAB ==========
	local codePage = InfoTabPages["Code"]

	-- Calling Code - syntax highlighted
	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = "Calling Code",
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 52,
		Parent = codePage,
	})

	local callingCode = CodeGen.GenerateCode(logEntry, callInfo)
	local highlightedCalling = SyntaxHighlighter.Highlight(callingCode)

	local callingCodeFrame = Interface.New("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 52,
		Parent = codePage,
		["UICorner"] = { CornerRadius = UDim.new(0, 6) },
		["UIStroke"] = {
			Color = Color3.fromRGB(25, 25, 25),
			Thickness = 1,
		},
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
		Text = highlightedCalling,
		TextColor3 = SyntaxHighlighter.Colors.Default,
		TextSize = 12,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		RichText = true,
		ZIndex = 53,
		Parent = callingCodeFrame,
	})

	-- Copy Calling Code button
	local copyCallingBtn = Interface.New("TextButton", {
		Text = "",
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		Size = UDim2.new(1, 0, 0, 28),
		AutoButtonColor = false,
		ZIndex = 52,
		Parent = codePage,
		["UICorner"] = { CornerRadius = UDim.new(0, 5) },
	})

	local copyIco = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0.5, -46, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Theme.TextMuted,
		ZIndex = 53,
		Parent = copyCallingBtn,
	})
	Icons.ApplyIcon(copyIco, "copy")

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 80, 1, 0),
		Position = UDim2.new(0.5, -30, 0, 0),
		Text = "Copy Code",
		TextColor3 = Theme.Text,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		ZIndex = 53,
		Parent = copyCallingBtn,
	})

	Helper.HoverEffect(copyCallingBtn, Color3.fromRGB(35, 35, 35), Color3.fromRGB(25, 25, 25))
	copyCallingBtn.MouseButton1Click:Connect(function()
		local success = pcall(setclipboard, callingCode)
		if success then
			wax.shared.Sonner.success("Copied calling code")
		end
	end)

	-- Separator
	Interface.New("Frame", {
		BackgroundColor3 = Theme.Border,
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 52,
		Parent = codePage,
	})

	-- Intercept Code - syntax highlighted
	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = "Intercept Code",
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 52,
		Parent = codePage,
	})

	local interceptCode = CodeGen.GenerateInterceptCode(logEntry)
	local highlightedIntercept = SyntaxHighlighter.Highlight(interceptCode)

	local interceptCodeFrame = Interface.New("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 52,
		Parent = codePage,
		["UICorner"] = { CornerRadius = UDim.new(0, 6) },
		["UIStroke"] = {
			Color = Color3.fromRGB(25, 25, 25),
			Thickness = 1,
		},
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
		Text = highlightedIntercept,
		TextColor3 = SyntaxHighlighter.Colors.Default,
		TextSize = 12,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		RichText = true,
		ZIndex = 53,
		Parent = interceptCodeFrame,
	})

	-- Copy Intercept button
	local copyInterceptBtn = Interface.New("TextButton", {
		Text = "",
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		Size = UDim2.new(1, 0, 0, 28),
		AutoButtonColor = false,
		ZIndex = 52,
		Parent = codePage,
		["UICorner"] = { CornerRadius = UDim.new(0, 5) },
	})

	local copyIco2 = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0.5, -62, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Theme.TextMuted,
		ZIndex = 53,
		Parent = copyInterceptBtn,
	})
	Icons.ApplyIcon(copyIco2, "shield-alert")

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 110, 1, 0),
		Position = UDim2.new(0.5, -46, 0, 0),
		Text = "Copy Intercept",
		TextColor3 = Theme.Text,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		ZIndex = 53,
		Parent = copyInterceptBtn,
	})

	Helper.HoverEffect(copyInterceptBtn, Color3.fromRGB(35, 35, 35), Color3.fromRGB(25, 25, 25))
	copyInterceptBtn.MouseButton1Click:Connect(function()
		local success = pcall(setclipboard, interceptCode)
		if success then
			wax.shared.Sonner.success("Copied intercept code")
		end
	end)

	-- ========== FUNCTION INFO TAB ==========
	local infoPage = InfoTabPages["Function Info"]

	local function CreateInfoRow(label, value, valueColor)
		local row = Interface.New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			ZIndex = 52,
			Parent = infoPage,
		})

		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 80, 1, 0),
			Text = label,
			TextColor3 = Theme.TextMuted,
			TextSize = 11,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 52,
			Parent = row,
		})

		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -85, 1, 0),
			Position = UDim2.new(0, 85, 0, 0),
			Text = tostring(value),
			TextColor3 = valueColor or Theme.Text,
			TextSize = 11,
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
	CreateInfoRow("Executor:", tostring(callInfo.IsExecutor or false), callInfo.IsExecutor and Theme.Warning or Theme.TextMuted)

	if callInfo.Origin and typeof(callInfo.Origin) == "Instance" then
		CreateInfoRow("Origin:", callInfo.Origin:GetFullName())
	end

	if callInfo.Traceback then
		-- Separator
		Interface.New("Frame", {
			BackgroundColor3 = Theme.Border,
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 52,
			Parent = infoPage,
		})

		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Text = "Traceback",
			TextColor3 = Theme.Text,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 52,
			Parent = infoPage,
		})

		local traceFrame = Interface.New("Frame", {
			BackgroundColor3 = Color3.fromRGB(10, 10, 10),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 52,
			Parent = infoPage,
			["UICorner"] = { CornerRadius = UDim.new(0, 4) },
			["UIPadding"] = {
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			},
		})

		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = tostring(callInfo.Traceback),
			TextColor3 = Theme.TextMuted,
			TextSize = 9,
			Font = Enum.Font.Code,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			ZIndex = 53,
			Parent = traceFrame,
		})
	end

	-- Decompile button if available
	if callInfo.Origin and typeof(callInfo.Origin) == "Instance" and typeof(decompile) == "function" then
		local decompBtn = Interface.New("TextButton", {
			Text = "",
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 28),
			AutoButtonColor = false,
			ZIndex = 52,
			Parent = infoPage,
			["UICorner"] = { CornerRadius = UDim.new(0, 5) },
		})

		local decompIco = Interface.New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ImageColor3 = Theme.TextMuted,
			ZIndex = 53,
			Parent = decompBtn,
		})
		Icons.ApplyIcon(decompIco, "file-code")

		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -30, 1, 0),
			Position = UDim2.new(0, 28, 0, 0),
			Text = "Decompile Origin",
			TextColor3 = Theme.Text,
			TextSize = 11,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 53,
			Parent = decompBtn,
		})

		Helper.HoverEffect(decompBtn, Theme.SurfaceHover, Theme.Surface)
		decompBtn.MouseButton1Click:Connect(function()
			local success, result = pcall(decompile, callInfo.Origin)
			if success then
				pcall(setclipboard, result)
				wax.shared.Sonner.success("Decompiled and copied")
			else
				wax.shared.Sonner.error("Failed to decompile")
			end
		end)
	end

	-- Start on Arguments tab
	SwitchInfoTab("Arguments")
end

-- ============================================================
-- SETTINGS PANEL
-- ============================================================

local SettingsFrame = Interface.New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	Parent = LogsWrapper,

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

-- Discord
local DiscordSection = CreateSettingsSection("Links")

local DiscordBtn = Interface.New("TextButton", {
	Text = "Copy Discord Invite",
	TextColor3 = Theme.Text,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 0, 32),
	AutoButtonColor = false,
	Parent = DiscordSection,

	["UICorner"] = { CornerRadius = UDim.new(0, 4) },
	["UIStroke"] = {
		Color = Theme.Border,
		Thickness = 1,
	},
})

Helper.HoverEffect(DiscordBtn, Theme.SurfaceHover, Theme.Surface)

DiscordBtn.MouseButton1Click:Connect(function()
	local success = pcall(setclipboard, "https://discord.gg/cXEYE3RYck")
	if success then
		wax.shared.Sonner.success("Copied Discord invite link")
	else
		wax.shared.Sonner.error("Failed to copy to clipboard")
	end
end)

-- UNC / Executor Compatibility Check
local UNCSection = CreateSettingsSection("Executor Compatibility (UNC)")

-- Executor name
local executorName = wax.shared.ExecutorName or "Unknown"
Interface.New("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 22),
	Text = `Executor: <b>{executorName}</b>`,
	TextColor3 = Theme.Text,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	RichText = true,
	Parent = UNCSection,
})

-- Overall score
local totalChecks = 0
local passedChecks = 0
local essentialPassed = 0
local essentialTotal = 0

local UNCCategories = {
	{
		Name = "Hooking",
		Icon = "shield",
		Functions = { "hookfunction", "hookmetamethod", "newcclosure", "iscclosure", "clonefunction", "getnamecallmethod" },
	},
	{
		Name = "Instances",
		Icon = "box",
		Functions = { "cloneref", "gethui", "getinstances", "getnilinstances", "getconnections" },
	},
	{
		Name = "Closures",
		Icon = "code",
		Functions = { "checkcaller", "getcallingscript", "getscripts", "getgenv", "getrenv", "getrawmetatable" },
	},
	{
		Name = "Actors / Parallel Luau",
		Icon = "cpu",
		Functions = { "getactors", "run_on_actor", "create_comm_channel" },
	},
	{
		Name = "FFlags",
		Icon = "flag",
		Functions = { "getfflag", "setfflag" },
	},
	{
		Name = "Misc",
		Icon = "wrench",
		Functions = { "setclipboard", "request", "queue_on_teleport", "decompile" },
	},
}

for _, category in ipairs(UNCCategories) do
	local catPassed = 0
	local catTotal = #category.Functions

	for _, funcName in ipairs(category.Functions) do
		totalChecks += 1
		local data = wax.shared.ExecutorSupport[funcName]
		if data and data.IsWorking then
			passedChecks += 1
			catPassed += 1
		end
		if data and data.Essential then
			essentialTotal += 1
			if data.IsWorking then
				essentialPassed += 1
			end
		end
	end

	-- Category row
	local catRow = Interface.New("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = UNCSection,

		["UICorner"] = { CornerRadius = UDim.new(0, 6) },
		["UIPadding"] = {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		},
		["UIListLayout"] = {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 4),
		},
	})

	-- Category header
	local catHeader = Interface.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = catRow,
	})

	local catIcon = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = catPassed == catTotal and Theme.Success or (catPassed > 0 and Theme.Warning or Theme.Error),
		Parent = catHeader,
	})
	Icons.ApplyIcon(catIcon, category.Icon)

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.6, -20, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		Text = category.Name,
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = catHeader,
	})

	local scoreColor = catPassed == catTotal and Theme.Success or (catPassed > 0 and Theme.Warning or Theme.Error)
	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.4, 0, 1, 0),
		Position = UDim2.new(0.6, 0, 0, 0),
		Text = `{catPassed}/{catTotal} passed`,
		TextColor3 = scoreColor,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = catHeader,
	})

	-- Individual function checks
	for _, funcName in ipairs(category.Functions) do
		local data = wax.shared.ExecutorSupport[funcName]
		local isWorking = data and data.IsWorking or false
		local isEssential = data and data.Essential or false

		local funcRow = Interface.New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Parent = catRow,
		})

		-- Status dot
		Interface.New("Frame", {
			BackgroundColor3 = isWorking and Theme.Success or Theme.Error,
			Size = UDim2.fromOffset(6, 6),
			Position = UDim2.new(0, 4, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = funcRow,

			["UICorner"] = { CornerRadius = UDim.new(1, 0) },
		})

		-- Function name
		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.6, -16, 1, 0),
			Position = UDim2.new(0, 16, 0, 0),
			Text = funcName,
			TextColor3 = Theme.TextMuted,
			TextSize = 11,
			Font = Enum.Font.Code,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = funcRow,
		})

		-- Status label
		local statusText = isWorking and "OK" or "MISSING"
		local essentialTag = isEssential and " [Essential]" or ""
		Interface.New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.4, 0, 1, 0),
			Position = UDim2.new(0.6, 0, 0, 0),
			Text = statusText .. essentialTag,
			TextColor3 = isWorking and Theme.Success or (isEssential and Theme.Error or Theme.Warning),
			TextSize = 10,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = funcRow,
		})
	end
end

-- Overall summary bar
local overallPercent = totalChecks > 0 and math.floor((passedChecks / totalChecks) * 100) or 0
local essentialAllOk = essentialPassed == essentialTotal

local summaryFrame = Interface.New("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(1, 0, 0, 52),
	Parent = UNCSection,

	["UICorner"] = { CornerRadius = UDim.new(0, 6) },
	["UIPadding"] = {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	},
})

-- Progress bar background
local progressBg = Interface.New("Frame", {
	BackgroundColor3 = Theme.SurfaceHover,
	Size = UDim2.new(1, 0, 0, 8),
	Position = UDim2.new(0, 0, 1, -8),
	Parent = summaryFrame,

	["UICorner"] = { CornerRadius = UDim.new(1, 0) },
})

-- Progress bar fill
local barColor = overallPercent >= 80 and Theme.Success or (overallPercent >= 50 and Theme.Warning or Theme.Error)
Interface.New("Frame", {
	BackgroundColor3 = barColor,
	Size = UDim2.new(overallPercent / 100, 0, 1, 0),
	Parent = progressBg,

	["UICorner"] = { CornerRadius = UDim.new(1, 0) },
})

-- Summary text
local verdictText, verdictColor
if essentialAllOk and overallPercent >= 80 then
	verdictText = `Full Compatibility ({overallPercent}%)`
	verdictColor = Theme.Success
elseif essentialAllOk then
	verdictText = `Partial Compatibility ({overallPercent}%) — some features limited`
	verdictColor = Theme.Warning
else
	local missingEssential = essentialTotal - essentialPassed
	verdictText = `Low Compatibility ({overallPercent}%) — {missingEssential} essential function{missingEssential ~= 1 and "s" or ""} missing`
	verdictColor = Theme.Error
end

Interface.New("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 16),
	Text = verdictText,
	TextColor3 = verdictColor,
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = summaryFrame,
})

Interface.New("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.new(0, 0, 0, 16),
	Text = `{passedChecks}/{totalChecks} checks passed  |  {essentialPassed}/{essentialTotal} essential`,
	TextColor3 = Theme.TextMuted,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = summaryFrame,
})

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

SwitchTab = function(tabName)
	ActiveTab = tabName

	-- Update button visuals
	for name, tabData in pairs(TabButtons) do
		local isActive = (name == tabName)
		tabData.Button.BackgroundColor3 = isActive and Theme.Accent or Theme.Surface
		tabData.Label.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Theme.TextMuted
		tabData.Icon.ImageColor3 = isActive and Color3.fromRGB(255, 255, 255) or Theme.TextMuted
	end

	-- Show/hide panels
	LogsList.Visible = (tabName ~= "Settings")
	PaginationBar.Visible = (tabName ~= "Settings")
	SettingsFrame.Visible = (tabName == "Settings")

	-- Update sidebar entries
	if tabName ~= "Settings" then
		UpdateRemoteList(tabName)
	end
end

UpdateRemoteList = function(eventType)
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

			-- If currently viewing this log, smooth incremental update
			if CurrentLog == log then
				local calls = log.Calls
				local totalCalls = #calls
				PaginationHelper:Update(totalCalls)

				local info = PaginationHelper:GetInfo()
				local totalPages = math.max(info.TotalPages, 1)
				local currentPage = info.CurrentPage

				-- Check if user is on the last page
				local isOnLastPage = currentPage >= totalPages or (currentPage == totalPages)

				if isOnLastPage then
					-- Calculate what the last page's range is
					local startIdx, endIdx = PaginationHelper:GetIndexRanges()
					local newCallIdx = totalCalls -- the newly added call
					local itemsOnPage = endIdx - startIdx + 1

					if newCallIdx >= startIdx and newCallIdx <= endIdx then
						-- New call fits on current page — just append it
						local newCall = calls[newCallIdx]
						if newCall then
							CreateCallEntry(log, newCall, newCallIdx, LogsList)
						end
					else
						-- Page is full, need to advance — full refresh to show new page
						CurrentPage[log] = totalPages
						ShowLog(log)
					end
				end

				-- Always update the page label
				PageLabel.Text = `Page {currentPage} / {totalPages}`
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
