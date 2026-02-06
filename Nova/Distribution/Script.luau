--[[
    Nova
    A runtime developer tool to monitor and intercept network traffic
    coming from the roblox game engine.
    
    This script is NOT intended to be modified.
    To view the source code, see the 'Src' folder on the official GitHub repository!

    Authors: Nova Team
    Powered by Wax Bundler
--]]
-- ++++++++ WAX BUNDLED DATA BELOW ++++++++ --

-- Will be used later for getting flattened globals
local ImportGlobals

-- Holds direct closure data (defining this before the DOM tree for line debugging etc)
local ClosureBindings = {
    [10] = function()local wax,script,require=ImportGlobals(10)local ImportGlobals return (function(...)--[[
	Nova - Outgoing Remote Hooks
	Hooks FireServer, InvokeServer, Fire, Invoke via __namecall and function hooks.
]]

local Log = require(script.Parent.Parent.Parent.Parent.Utils.Log)

local IgnorePlayerModule = wax.shared.SaveManager:GetState("IgnorePlayerModule", true)
local IgnoredRemotesDropdown = wax.shared.SaveManager:GetState("IgnoredRemotesDropdown", {
	["BindableEvent"] = true,
	["BindableFunction"] = true,
})

local UseAlternativeHooks = wax.shared.SaveManager:GetState("UseAlternativeHooks", false)

local MethodToClass = {
	FireServer = { "RemoteEvent", "UnreliableRemoteEvent" },
	InvokeServer = { "RemoteFunction" },
	Fire = { "BindableEvent" },
	Invoke = { "BindableFunction" },
}

local ClassToMethod = {
	RemoteEvent = "FireServer",
	RemoteFunction = "InvokeServer",
	UnreliableRemoteEvent = "FireServer",
	BindableEvent = "Fire",
	BindableFunction = "Invoke",
}

local function ShouldIgnore(instance)
	-- Ignore Nova's own communication
	if instance == wax.shared.Communicator then
		return true
	end

	-- Ignore by class
	if IgnoredRemotesDropdown[instance.ClassName] then
		return true
	end

	-- Ignore PlayerModule if setting enabled
	if IgnorePlayerModule then
		local fullName = instance:GetFullName()
		if string.find(fullName, "PlayerModule") or string.find(fullName, "PlayerScripts") then
			return true
		end
	end

	return false
end

local function GetCallingScript()
	if not getcallingscript then
		return nil
	end

	local success, result = pcall(getcallingscript)
	return success and result or nil
end

local function ProcessOutgoingCall(instance, method, args)
	if ShouldIgnore(instance) then
		return
	end

	local ClassName = instance.ClassName
	local IsExecutor = checkcaller and checkcaller() or false

	-- Get or create log entry
	local LogEntry = wax.shared.Logs.Outgoing[instance]
	if not LogEntry then
		LogEntry = Log.new(instance, "Outgoing", method, nil, GetCallingScript())
		wax.shared.Logs.Outgoing[instance] = LogEntry
	end

	-- Record the call
	local CallInfo = {
		Args = args,
		Method = method,
		Traceback = debug.traceback(),
		IsExecutor = IsExecutor,
		Origin = GetCallingScript(),
		Instance = instance,
	}

	LogEntry:Call(CallInfo)
end

-- Hook __namecall
wax.shared.Hooking.SetNamecallHook(newcclosure(function(...)
	local method = getnamecallmethod()
	local self = (...)

	if typeof(self) == "Instance" then
		local className = self.ClassName
		local validClasses = MethodToClass[method]

		if validClasses and table.find(validClasses, className) then
			local args = { select(2, ...) }
			ProcessOutgoingCall(self, method, args)

			-- Handle blocked remotes
			local LogEntry = wax.shared.Logs.Outgoing[self]
			if LogEntry and LogEntry.Blocked then
				if className == "RemoteFunction" or className == "BindableFunction" then
					return nil
				end
				return
			end
		end
	end

	return wax.shared.NamecallHook(...)
end))

-- Alternative: Hook individual functions
if UseAlternativeHooks then
	local FunctionsToHook
	do
		local BindableFunction = Instance.new("BindableFunction")
		local BindableEvent = Instance.new("BindableEvent")
		local RemoteFunction = Instance.new("RemoteFunction")
		local RemoteEvent = Instance.new("RemoteEvent")
		local UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")

		FunctionsToHook = {
			{ Func = BindableFunction.Invoke, Method = "Invoke" },
			{ Func = BindableEvent.Fire, Method = "Fire" },
			{ Func = RemoteFunction.InvokeServer, Method = "InvokeServer" },
			{ Func = RemoteEvent.FireServer, Method = "FireServer" },
			{ Func = UnreliableRemoteEvent.FireServer, Method = "FireServer" },
		}

		BindableFunction:Destroy()
		BindableEvent:Destroy()
		RemoteFunction:Destroy()
		RemoteEvent:Destroy()
		UnreliableRemoteEvent:Destroy()
	end

	for _, FuncData in next, FunctionsToHook do
		local OriginalFunction = FuncData.Func
		local Method = FuncData.Method

		wax.shared.Hooks[OriginalFunction] = wax.shared.Hooking.HookFunction(
			OriginalFunction,
			newcclosure(function(self, ...)
				if typeof(self) == "Instance" then
					local args = { ... }
					ProcessOutgoingCall(self, Method, args)

					local LogEntry = wax.shared.Logs.Outgoing[self]
					if LogEntry and LogEntry.Blocked then
						if self.ClassName == "RemoteFunction" or self.ClassName == "BindableFunction" then
							return nil
						end
						return
					end
				end

				return wax.shared.Hooking.GetOriginal(OriginalFunction)(self, ...)
			end)
		)
	end
end

-- Hook __index for OnClientEvent access detection
if not UseAlternativeHooks then
	local OldIndex = wax.shared.Hooking.HookMetamethod(game, "__index", newcclosure(function(self, key)
		if typeof(self) == "Instance" and not checkcaller() then
			local className = self.ClassName
			if key == "OnClientEvent" and (className == "RemoteEvent" or className == "UnreliableRemoteEvent") then
				-- Track __index access
			elseif key == "OnClientInvoke" and className == "RemoteFunction" then
				-- Track __index access
			end
		end

		return OldIndex(self, key)
	end))

	wax.shared.IndexHook = OldIndex
end

return {}

end)() end,
    [34] = function()local wax,script,require=ImportGlobals(34)local ImportGlobals return (function(...)--[[
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

end)() end,
    [21] = function()local wax,script,require=ImportGlobals(21)local ImportGlobals return (function(...)-- Logger
-- File logging utility for Nova

--[=[
    A simple logging utility that writes messages to a file. Supports different log levels
    and can be configured to overwrite or append to the log file.

    Log Format:  2024-12-04T15:28:31.131Z,0.131060,MyThread,Warning [FLog::NovaLogger] Message
                 <timestamp>,<elapsed_time>,<thread_id>,<level> <message>
]=]

local Logger = {}
Logger.__index = Logger

Logger.LOG_LEVELS = {
	ERROR = 1,
	WARNING = 2,
	INFO = 3,
	DEBUG = 4,
}

local LOG_LEVEL_STRINGS = {
	[Logger.LOG_LEVELS.ERROR] = "ERROR",
	[Logger.LOG_LEVELS.WARNING] = "WARNING",
	[Logger.LOG_LEVELS.INFO] = "INFO",
	[Logger.LOG_LEVELS.DEBUG] = "DEBUG",
}

local startTime = tick()

local function createDirectoryRecursive(path)
	local currentPath = ""
	for segment in string.gmatch(path, "[^/]+") do
		currentPath = currentPath .. (currentPath == "" and "" or "/") .. segment
		if not isfolder(currentPath) then
			pcall(makefolder, currentPath)
		end
	end
end

function Logger.new(filePath: string, logLevel: number?, overwrite: boolean?)
	logLevel = logLevel or Logger.LOG_LEVELS.INFO
	overwrite = if overwrite == nil then false else overwrite

	-- Ensure directory exists
	local dir = string.match(filePath, "(.+)/[^/]+$")
	if dir then
		createDirectoryRecursive(dir)
	end

	-- Initialize or overwrite
	if overwrite or not isfile(filePath) then
		writefile(filePath, "")
	end

	local self = setmetatable({
		FilePath = filePath,
		LogLevel = logLevel,
		Buffer = {},
		BufferSize = 0,
		MaxBufferSize = 10,
		LastFlush = tick(),
		FlushInterval = 2,
	}, Logger)

	-- Auto-flush periodically
	task.spawn(function()
		while not wax.shared.Unloaded do
			task.wait(self.FlushInterval)
			if self.BufferSize > 0 then
				self:Flush()
			end
		end
		-- Final flush on unload
		if self.BufferSize > 0 then
			self:Flush()
		end
	end)

	return self
end

function Logger:Flush()
	if self.BufferSize == 0 then
		return
	end

	local content = table.concat(self.Buffer, "\n") .. "\n"
	pcall(function()
		appendfile(self.FilePath, content)
	end)

	self.Buffer = {}
	self.BufferSize = 0
	self.LastFlush = tick()
end

function Logger:Log(level: number, message: string)
	if level > self.LogLevel then
		return
	end

	local elapsed = string.format("%.6f", tick() - startTime)
	local timestamp = DateTime.now():ToIsoDate()
	local levelStr = LOG_LEVEL_STRINGS[level] or "UNKNOWN"

	local entry = `{timestamp},{elapsed},{levelStr} {message}`

	self.BufferSize += 1
	self.Buffer[self.BufferSize] = entry

	if self.BufferSize >= self.MaxBufferSize then
		self:Flush()
	end
end

function Logger:Info(message: string)
	self:Log(Logger.LOG_LEVELS.INFO, message)
end

function Logger:Warning(message: string)
	self:Log(Logger.LOG_LEVELS.WARNING, message)
end

function Logger:Error(message: string)
	self:Log(Logger.LOG_LEVELS.ERROR, message)
end

function Logger:Debug(message: string)
	self:Log(Logger.LOG_LEVELS.DEBUG, message)
end

return Logger

end)() end,
    [20] = function()local wax,script,require=ImportGlobals(20)local ImportGlobals return (function(...)wax.shared.Connections = {}

wax.shared.Connect = function(Connection)
	table.insert(wax.shared.Connections, Connection)
	return Connection
end

wax.shared.Disconnect = function(Connection)
	Connection:Disconnect()

	local Index = table.find(wax.shared.Connections, Connection)
	if Index then
		table.remove(wax.shared.Connections, Index)
	end

	return true
end

return {}

end)() end,
    [36] = function()local wax,script,require=ImportGlobals(36)local ImportGlobals return (function(...)--[[
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

end)() end,
    [4] = function()local wax,script,require=ImportGlobals(4)local ImportGlobals return (function(...)--[[
	Nova Spy Initialization
	Sets up all hooks for monitoring remote events.
]]

local LuaEncode = require(script.Parent.Parent.Utils.Serializer.LuaEncode)
local CodeGen = require(script.Parent.Parent.Utils.CodeGen.Generator)

local Hooks = script.Parent.Hooks

-- Main Thread Hooks
for _, Hook in Hooks.Default:GetChildren() do
	task.spawn(require, Hook)
end

getgenv().NovaInitialized = true

-- Actor support
local ActorsUtils = script.Parent.Actors

wax.shared.ActorsEnabled = (
	wax.shared.ExecutorSupport["run_on_actor"].IsWorking
	and wax.shared.ExecutorSupport["getactors"].IsWorking
	and wax.shared.ExecutorSupport["create_comm_channel"].IsWorking
)

if wax.shared.ActorsEnabled then
	local ActorEnvironmentCode = ActorsUtils.Environment.Value

	local IgnorePlayerModule = wax.shared.SaveManager:GetState("IgnorePlayerModule", true)
	local IgnoredRemotesDropdown = wax.shared.SaveManager:GetState("IgnoredRemotesDropdown", {
		["BindableEvent"] = true,
		["BindableFunction"] = true,
	})

	local AlternativeEnabled = wax.shared.SaveManager:GetState("UseAlternativeHooks", false)

	local CommunicationChannelID, Channel = create_comm_channel()
	wax.shared.ActorCommunicator = Channel

	local ActorData = LuaEncode({
		Token = wax.shared.NovaVerificationToken,
		IgnorePlayerModule = IgnorePlayerModule,
		IgnoredRemotesDropdown = IgnoredRemotesDropdown,
		UseAlternativeHooks = AlternativeEnabled,
		ExecutorSupport = wax.shared.ExecutorSupport,
	})

	ActorEnvironmentCode = ActorEnvironmentCode:gsub("NOVA_ACTOR_DATA", ActorData)

	-- Actor Logs Sync Layer
	local function ReconstructTable(Info, CyclicRefs)
		local Reconstructed = {}

		for Key, Value in Info do
			if type(Value) == "table" then
				if Value["__Function"] and Value["Validation"] == wax.shared.NovaVerificationToken then
					local FunctionData = table.clone(Value)
					FunctionData["__Function"] = nil
					FunctionData["Validation"] = nil

					Reconstructed[Key] = FunctionData
				else
					Reconstructed[Key] = ReconstructTable(Value, CyclicRefs)
				end
			else
				Reconstructed[Key] = Value
			end
		end

		return Reconstructed
	end

	-- Listen for actor events
	Channel:Listen("ActorLog", function(RemoteInstance, EventType, CallInfo)
		if not RemoteInstance or not EventType then
			return
		end

		local Log = wax.shared.Logs[EventType][RemoteInstance]
		if not Log then
			Log = wax.shared.Log and wax.shared.Log.new(RemoteInstance, EventType, CallInfo.Method, nil, nil)
			if Log then
				wax.shared.Logs[EventType][RemoteInstance] = Log
			end
		end

		if Log then
			local ReconstructedInfo = ReconstructTable(CallInfo, {})
			Log:Call(ReconstructedInfo)
		end
	end)

	-- Run on all actors
	for _, Actor in getactors() do
		pcall(function()
			run_on_actor(Actor, ActorEnvironmentCode, CommunicationChannelID)
		end)
	end
end

return {}

end)() end,
    [32] = function()local wax,script,require=ImportGlobals(32)local ImportGlobals return (function(...)--[[
	Icons Module for Nova
	Fetches and manages Lucide icons for the UI.
]]

local Icons = {}

type Icon = {
	Url: string,
	Id: number,
	IconName: string,
	ImageRectOffset: Vector2,
	ImageRectSize: Vector2,
}

local Success, IconsModule = pcall(function()
	local IconFetchSuccess, IconModuleSource = pcall(request, {
		Url = "https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua",
		Method = "GET",
	})

	assert(
		IconFetchSuccess and IconModuleSource.Success or IconModuleSource.StatusCode >= 200 and IconModuleSource.StatusCode < 300,
		"Failed to fetch lucide icons direct module source"
	)
	return (loadstring(IconModuleSource.Body) :: () -> { Icons: { string }, GetAsset: (Name: string) -> Icon? })()
end)

function Icons.GetIcon(iconName: string): Icon?
	if not Success then
		return
	end

	local Success, Icon = pcall(IconsModule.GetAsset, iconName)
	if not Success then
		return
	end

	return Icon
end

function Icons.ApplyIcon(imageLabel: ImageLabel, iconName: string)
	local icon = Icons.GetIcon(iconName)
	if not icon then
		return false
	end

	imageLabel.Image = icon.Url
	imageLabel.ImageRectOffset = icon.ImageRectOffset
	imageLabel.ImageRectSize = icon.ImageRectSize
	return true
end

return Icons

end)() end,
    [2] = function()local wax,script,require=ImportGlobals(2)local ImportGlobals return (function(...)wax.shared.NovaStartTime = tick()

local FileLogger = require(script.Utils.FileLog)

-- Environment Services
for _, Service in pairs({
	"ContentProvider",
	"CoreGui",
	"TweenService",
	"Players",
	"RunService",
	"HttpService",
	"UserInputService",
	"TextService",
	"StarterGui",
}) do
	wax.shared[Service] = cloneref(game:GetService(Service))
end

wax.shared.NovaVerificationToken = wax.shared.HttpService:GenerateGUID()
wax.shared.SaveManager = require(script.Utils.SaveManager)
wax.shared.Settings = {}

wax.shared.Hooks = {}

-- Executor Support
wax.shared.ExecutorName = identifyexecutor()
wax.shared.ExecutorSupport = require(script.ExecutorSupport)

-- Utils
require(script.Utils.Connect)
wax.shared.Hooking = require(script.Utils.Hooking)

-- UI
wax.shared.Sonner = require(script.Utils.UI.Sonner)

-- Code Generation
local LuaEncode = require(script.Utils.Serializer.LuaEncode)
wax.shared.LuaEncode = LuaEncode

wax.shared.CodeGen = require(script.Utils.CodeGen.Generator)

-- Init Logs Table
wax.shared.Logs = {
	Incoming = {},
	Outgoing = {},
}

-- Replay Support
function wax.shared.ReplayCallInfo(CallInfo, TabType)
	if not CallInfo or not CallInfo.Instance then
		return
	end

	local Instance = CallInfo.Instance
	local ClassName = Instance.ClassName
	local Args = CallInfo.Args

	if TabType == "Outgoing" then
		if ClassName == "RemoteEvent" or ClassName == "UnreliableRemoteEvent" then
			Instance:FireServer(table.unpack(Args))
		elseif ClassName == "RemoteFunction" then
			Instance:InvokeServer(table.unpack(Args))
		elseif ClassName == "BindableEvent" then
			Instance:Fire(table.unpack(Args))
		elseif ClassName == "BindableFunction" then
			Instance:Invoke(table.unpack(Args))
		end
	end
end

-- Unload Function
function wax.shared.Unload()
	-- Disconnect all connections
	for _, Connection in pairs(wax.shared.Connections or {}) do
		pcall(function()
			Connection:Disconnect()
		end)
	end

	-- Restore hooks
	for Original, Hook in pairs(wax.shared.Hooks) do
		pcall(function()
			wax.shared.Hooking.RestoreFunction(Original)
		end)
	end

	-- Restore namecall hook
	if wax.shared.NamecallHook then
		pcall(function()
			wax.shared.Hooking.RestoreNamecall()
		end)
	end

	if wax.shared.ActorCommunicator then
		pcall(function()
			wax.shared.ActorCommunicator:Fire("Unload")
		end)
	end

	getgenv().NovaInitialized = false

	wax.shared.Communicator:Destroy()
	wax.shared.ScreenGui:Destroy()

	wax.shared.Unloaded = true
end

local AnticheatData = require(script.Utils.Anticheats.Main)

-- Communicator
wax.shared.Communicator = Instance.new("BindableEvent")

-- Setup logging connection
wax.shared.SetupLoggingConnection = function()
	if wax.shared.LogConnection then
		wax.shared.LogConnection:Disconnect()
	end

	wax.shared.LogFileName = `Nova/Logs/{DateTime.now():ToIsoDate():gsub(":", "_")}.log`
	local FileLog = FileLogger.new(wax.shared.LogFileName, FileLogger.LOG_LEVELS.INFO, true)

	return function(RemoteInstance, Type, CallOrderInLog)
		local LogEntry = wax.shared.Logs[Type][RemoteInstance]
		if not LogEntry then
			return
		end

		local Call = LogEntry.Calls[CallOrderInLog]
		if not Call then
			return
		end

		local ArgsString = ""
		local Success, Encoded = pcall(LuaEncode, Call.Args, {
			Prettify = false,
			FunctionsReturnRaw = true,
		})

		if Success then
			ArgsString = Encoded
		end

		FileLog:Log(FileLogger.LOG_LEVELS.INFO, `[{Type}] {RemoteInstance:GetFullName()} | Args: {ArgsString}`)
	end
end

-- Execute on Teleport
if wax.shared.SaveManager:GetState("ExecuteOnTeleport", false) then
	pcall(function()
		local QueueScript = `loadstring(game:HttpGet("NOVA_LOADSTRING_URL"))()`
		local Success = pcall(queue_on_teleport, QueueScript)
		if not Success then
			pcall(queueonteleport, QueueScript)
		end
	end)
end

-- Anticheat Bypass
if wax.shared.SaveManager:GetState("AnticheatBypass", true) and AnticheatData.Bypass then
	local Success, Error = pcall(AnticheatData.Bypass)
	if not Success then
		warn("[Nova] Failed to apply anticheat bypass:", Error)
	end
end

-- Initialize Window
require(script.Window)

-- Start Spy
require(script.Spy.Init)

-- Done
local LoadTime = string.format("%.2f", tick() - wax.shared.NovaStartTime)
wax.shared.Sonner.success(`Nova loaded in {LoadTime}s`)

end)() end,
    [35] = function()local wax,script,require=ImportGlobals(35)local ImportGlobals return (function(...)--[[
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

end)() end,
    [33] = function()local wax,script,require=ImportGlobals(33)local ImportGlobals return (function(...)--[[
	Image Fetcher for Nova
	Handles fetching and caching images for UI elements.
]]

local ImageFetch = {}

local Cache = {}

local RemoteImages = {
	RemoteEvent = "rbxassetid://4229806545",
	RemoteFunction = "rbxassetid://4229806870",
	UnreliableRemoteEvent = "rbxassetid://4229806545",
	BindableEvent = "rbxassetid://4229806545",
	BindableFunction = "rbxassetid://4229806870",
}

function ImageFetch.GetRemoteImage(className: string): string
	return RemoteImages[className] or "rbxassetid://4229806545"
end

function ImageFetch.Preload(imageIds: { string })
	if wax.shared.ContentProvider then
		local instances = {}
		for _, id in ipairs(imageIds) do
			if not Cache[id] then
				local img = Instance.new("ImageLabel")
				img.Image = id
				table.insert(instances, img)
				Cache[id] = true
			end
		end

		if #instances > 0 then
			pcall(function()
				wax.shared.ContentProvider:PreloadAsync(instances)
			end)
		end

		for _, img in ipairs(instances) do
			img:Destroy()
		end
	end
end

return ImageFetch

end)() end,
    [22] = function()local wax,script,require=ImportGlobals(22)local ImportGlobals return (function(...)--[[
	Hooking Utility Module for Nova
	Provides function hooking, namecall hooking and restoration.
]]

local Hooking = {}

local OriginalFunctions = {}
local OriginalNamecall = nil

function Hooking.HookFunction(original, hook)
	if not hookfunction then
		return nil
	end

	local oldFunc = hookfunction(original, hook)
	OriginalFunctions[original] = oldFunc
	return oldFunc
end

function Hooking.RestoreFunction(original)
	local oldFunc = OriginalFunctions[original]
	if oldFunc and hookfunction then
		hookfunction(original, oldFunc)
		OriginalFunctions[original] = nil
	end
end

function Hooking.HookMetamethod(object, metamethod, hook)
	if not hookmetamethod then
		return nil
	end

	local oldMethod = hookmetamethod(object, metamethod, hook)
	return oldMethod
end

function Hooking.SetNamecallHook(hook)
	if not hookmetamethod then
		return nil
	end

	local oldNamecall = hookmetamethod(game, "__namecall", hook)
	OriginalNamecall = oldNamecall
	wax.shared.NamecallHook = oldNamecall
	return oldNamecall
end

function Hooking.RestoreNamecall()
	if OriginalNamecall and hookmetamethod then
		hookmetamethod(game, "__namecall", OriginalNamecall)
		OriginalNamecall = nil
		wax.shared.NamecallHook = nil
	end
end

function Hooking.GetOriginal(original)
	return OriginalFunctions[original]
end

return Hooking

end)() end,
    [3] = function()local wax,script,require=ImportGlobals(3)local ImportGlobals return (function(...)--[[
	Lightweight checks for various executor functions.
	Reports whether they are working or not.
]]

local ExecutorSupport = {
	FailedChecks = {
		Essential = {},
		NonEssential = {},
	},
}

local BrokenFeatures = {
	["Volcano"] = { "oth", "run_on_actor" },
	["Seliware"] = { "run_on_actor" },
}

local function CheckFFlagValue(Name: string, Value: any)
	local Success, Result = pcall(getfflag, Name)
	if not Success then
		return false
	end

	if typeof(Result) == "boolean" then
		return Result
	end

	if typeof(Result) == "string" then
		return Result == tostring(Value)
	end

	return false
end

local function test(name, Callback, CheckType, Essential)
	local TestFunction = not CheckType and Callback or function()
		assert(typeof(Callback) == "function", string.format("%s is not a function.", name))
		return "Passed nil check."
	end

	if Essential == nil then
		Essential = true
	end

	local Success, Result
	if BrokenFeatures[wax.shared.ExecutorName] and table.find(BrokenFeatures[wax.shared.ExecutorName], name) then
		Success = false
		Result = "This function/library is broken or can crash your game on this executor."
	else
		Success, Result = pcall(TestFunction)
	end

	ExecutorSupport[name] = {
		IsWorking = Success,
		Details = Result,
		Essential = Essential,
	}

	if not Success then
		if Essential then
			table.insert(ExecutorSupport.FailedChecks.Essential, name)
		else
			table.insert(ExecutorSupport.FailedChecks.NonEssential, name)
		end
	end
end

-- FFlag Library
test("getfflag", getfflag, true)
test("setfflag", setfflag, true)

-- Actor Library
test("getactors", getactors, true)
test("run_on_actor", run_on_actor, true)
test("create_comm_channel", create_comm_channel, true)

-- Closure Library
test("hookfunction", hookfunction, true)
test("hookmetamethod", hookmetamethod, true)
test("newcclosure", newcclosure, true)
test("iscclosure", iscclosure, true)
test("clonefunction", clonefunction, true)
test("getnamecallmethod", getnamecallmethod, true)

-- Instance Library
test("gethui", gethui, true, false)
test("cloneref", cloneref, true)
test("getinstances", getinstances, true, false)
test("getnilinstances", getnilinstances, true, false)
test("getconnections", getconnections, true, false)

-- Script Library
test("getscripts", getscripts, true, false)
test("getcallingscript", getcallingscript, true, false)

-- Thread / Debug
test("checkcaller", checkcaller, true)
test("getinfo", function()
	return debug.info(1, "slnaf")
end, false)

-- Misc
test("setclipboard", setclipboard, true)
test("request", request, true, false)
test("queue_on_teleport", queue_on_teleport, true, false)

-- Other Tools
test("decompile", decompile, true, false)
test("oth", function()
	return true
end, false, false)

-- Additional utility checks
test("getgenv", getgenv, true)
test("getrenv", getrenv, true, false)
test("getrawmetatable", getrawmetatable, true)

-- Parallel Luau fix detection
task.defer(function()
	if not ExecutorSupport["setfflag"].IsWorking and not ExecutorSupport["run_on_actor"].IsWorking then
		return
	end

	local GameUsesActors = false
	local CategoryToSearch = {}

	if ExecutorSupport["getinstances"].IsWorking then
		table.insert(CategoryToSearch, getinstances())
	end

	if ExecutorSupport["getnilinstances"].IsWorking then
		table.insert(CategoryToSearch, getnilinstances())
	end

	for _, Category in CategoryToSearch do
		if GameUsesActors then
			break
		end

		for _, Instance in Category do
			if not Instance:IsA("Actor") then
				continue
			end

			GameUsesActors = true
			break
		end
	end

	if not GameUsesActors then
		return
	end

	local bindable = Instance.new("BindableFunction")

	function bindable.OnInvoke(response)
		if response == "Enable Fix" then
			setfflag("DebugRunParallelLuaOnMainThread", "true")
			wax.shared.StarterGui:SetCore("SendNotification", {
				Title = "Nova",
				Text = "Please rejoin for the fix to take effect!",
				Duration = math.huge,
			})
		end

		bindable:Destroy()
	end

	wax.shared.StarterGui:SetCore("SendNotification", {
		Title = "Nova",
		Text = "This game may use remotes in a way that your executor can't intercept. You can enable the fix and rejoin to detect them.",
		Duration = math.huge,
		Callback = bindable,
		Button1 = "Enable Fix",
		Button2 = "Dismiss",
	})
end)

return ExecutorSupport

end)() end,
    [29] = function()local wax,script,require=ImportGlobals(29)local ImportGlobals return (function(...)--[[
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

end)() end,
    [24] = function()local wax,script,require=ImportGlobals(24)local ImportGlobals return (function(...)--[[
	Pagination Module
	Handles pagination logic for log entries.
]]

local Pagination = {}
Pagination.__index = Pagination

function Pagination.new(Options: {
	TotalItems: number,
	ItemsPerPage: number,
	CurrentPage: number?,
	SiblingCount: number?,
})
	return setmetatable({
		TotalItems = Options.TotalItems,
		ItemsPerPage = Options.ItemsPerPage,
		CurrentPage = Options.CurrentPage or 1,
		SiblingCount = Options.SiblingCount or 2,
	}, Pagination)
end

function Pagination:GetInfo()
	local TotalPages = math.ceil(self.TotalItems / self.ItemsPerPage)

	return {
		TotalItems = self.TotalItems,
		ItemsPerPage = self.ItemsPerPage,
		CurrentPage = self.CurrentPage,
		TotalPages = TotalPages,
	}
end

function Pagination:SetItemsPerPage(max: number)
	self.ItemsPerPage = max
end

function Pagination:GetIndexRanges(Page: number?)
	Page = Page or self.CurrentPage

	local TotalPages = math.ceil(self.TotalItems / self.ItemsPerPage)
	if TotalPages == 0 then
		return 1, 0
	end

	assert(Page >= 1 and Page <= TotalPages, `Page {Page} is out of range (1 - {TotalPages})`)

	local StartIndex = (Page - 1) * self.ItemsPerPage + 1
	local EndIndex = math.min(StartIndex + self.ItemsPerPage - 1, self.TotalItems)

	return StartIndex, EndIndex
end

function Pagination:GetPages()
	local TotalPages = math.ceil(self.TotalItems / self.ItemsPerPage)
	local CurrentPage = self.CurrentPage
	local SiblingCount = self.SiblingCount

	local Pages = {}

	local LeftSibling = math.max(CurrentPage - SiblingCount, 1)
	local RightSibling = math.min(CurrentPage + SiblingCount, TotalPages)

	local ShowLeftDots = LeftSibling > 2
	local ShowRightDots = RightSibling < TotalPages - 1

	if not ShowLeftDots and ShowRightDots then
		local LeftCount = 3 + 2 * SiblingCount
		for i = 1, math.min(LeftCount, TotalPages) do
			table.insert(Pages, i)
		end
		table.insert(Pages, "...")
		table.insert(Pages, TotalPages)
	elseif ShowLeftDots and not ShowRightDots then
		table.insert(Pages, 1)
		table.insert(Pages, "...")
		local RightCount = 3 + 2 * SiblingCount
		for i = math.max(TotalPages - RightCount + 1, 1), TotalPages do
			table.insert(Pages, i)
		end
	elseif ShowLeftDots and ShowRightDots then
		table.insert(Pages, 1)
		table.insert(Pages, "...")
		for i = LeftSibling, RightSibling do
			table.insert(Pages, i)
		end
		table.insert(Pages, "...")
		table.insert(Pages, TotalPages)
	else
		for i = 1, TotalPages do
			table.insert(Pages, i)
		end
	end

	return Pages
end

function Pagination:Update(totalItems: number)
	self.TotalItems = totalItems
end

function Pagination:SetPage(page: number)
	local TotalPages = math.ceil(self.TotalItems / self.ItemsPerPage)
	self.CurrentPage = math.clamp(page, 1, math.max(TotalPages, 1))
end

function Pagination:NextPage()
	local TotalPages = math.ceil(self.TotalItems / self.ItemsPerPage)
	self:SetPage(math.min(self.CurrentPage + 1, TotalPages))
end

function Pagination:PreviousPage()
	self:SetPage(math.max(self.CurrentPage - 1, 1))
end

return Pagination

end)() end,
    [9] = function()local wax,script,require=ImportGlobals(9)local ImportGlobals return (function(...)--[[
	Nova - Incoming Remote Hooks
	Hooks OnClientEvent connections to monitor incoming remote calls.
]]

local Log = require(script.Parent.Parent.Parent.Parent.Utils.Log)

local IgnorePlayerModule = wax.shared.SaveManager:GetState("IgnorePlayerModule", true)
local IgnoredRemotesDropdown = wax.shared.SaveManager:GetState("IgnoredRemotesDropdown", {
	["BindableEvent"] = true,
	["BindableFunction"] = true,
})

local ClassToConnection = {
	RemoteEvent = "OnClientEvent",
	UnreliableRemoteEvent = "OnClientEvent",
	RemoteFunction = "OnClientInvoke",
	BindableEvent = "Event",
	BindableFunction = "OnInvoke",
}

local function ShouldIgnore(instance)
	if instance == wax.shared.Communicator then
		return true
	end

	if IgnoredRemotesDropdown[instance.ClassName] then
		return true
	end

	if IgnorePlayerModule then
		local fullName = instance:GetFullName()
		if string.find(fullName, "PlayerModule") or string.find(fullName, "PlayerScripts") then
			return true
		end
	end

	return false
end

local function GetCallingScript()
	if not getcallingscript then
		return nil
	end

	local success, result = pcall(getcallingscript)
	return success and result or nil
end

local function ProcessIncomingCall(instance, method, args)
	if ShouldIgnore(instance) then
		return
	end

	local LogEntry = wax.shared.Logs.Incoming[instance]
	if not LogEntry then
		LogEntry = Log.new(instance, "Incoming", method, nil, GetCallingScript())
		wax.shared.Logs.Incoming[instance] = LogEntry
	end

	local CallInfo = {
		Args = args,
		Method = method,
		IsExecutor = false,
		Instance = instance,
		Origin = GetCallingScript(),
	}

	LogEntry:Call(CallInfo)
end

-- Hook remote events for incoming signals
local function HookRemote(remote)
	if ShouldIgnore(remote) then
		return
	end

	local className = remote.ClassName
	local connectionName = ClassToConnection[className]

	if not connectionName then
		return
	end

	-- For RemoteEvent/UnreliableRemoteEvent - monitor OnClientEvent
	if className == "RemoteEvent" or className == "UnreliableRemoteEvent" then
		wax.shared.Connect(remote[connectionName]:Connect(function(...)
			local args = { ... }
			ProcessIncomingCall(remote, connectionName, args)
		end))
	end

	-- For RemoteFunction - wrap OnClientInvoke
	if className == "RemoteFunction" then
		local originalInvoke = remote.OnClientInvoke
		if originalInvoke then
			remote.OnClientInvoke = function(...)
				local args = { ... }
				ProcessIncomingCall(remote, "OnClientInvoke", args)
				return originalInvoke(...)
			end
		end
	end
end

-- Hook existing remotes
local function ScanAndHookRemotes()
	local services = {
		game:GetService("ReplicatedStorage"),
		game:GetService("Workspace"),
	}

	-- Also check nil instances if available
	if getnilinstances then
		local success, nilInstances = pcall(getnilinstances)
		if success and nilInstances then
			for _, inst in pairs(nilInstances) do
				if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") or inst:IsA("UnreliableRemoteEvent") then
					pcall(HookRemote, inst)
				end
			end
		end
	end

	for _, service in pairs(services) do
		for _, descendant in pairs(service:GetDescendants()) do
			if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") or descendant:IsA("UnreliableRemoteEvent") then
				pcall(HookRemote, descendant)
			end
		end

		-- Watch for new remotes
		wax.shared.Connect(service.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") or descendant:IsA("UnreliableRemoteEvent") then
				task.defer(HookRemote, descendant)
			end
		end))
	end
end

task.spawn(ScanAndHookRemotes)

return {}

end)() end,
    [11] = function()local wax,script,require=ImportGlobals(11)local ImportGlobals return (function(...)--[[
	Nova Spy Initialization
	Sets up all hooks for monitoring remote events.
]]

local LuaEncode = require(script.Parent.Parent.Utils.Serializer.LuaEncode)
local CodeGen = require(script.Parent.Parent.Utils.CodeGen.Generator)

local Hooks = script.Parent.Hooks

-- Main Thread Hooks
for _, Hook in Hooks.Default:GetChildren() do
	task.spawn(require, Hook)
end

getgenv().NovaInitialized = true

-- Actor support
local ActorsUtils = script.Parent.Actors

wax.shared.ActorsEnabled = (
	wax.shared.ExecutorSupport["run_on_actor"].IsWorking
	and wax.shared.ExecutorSupport["getactors"].IsWorking
	and wax.shared.ExecutorSupport["create_comm_channel"].IsWorking
)

if wax.shared.ActorsEnabled then
	local ActorEnvironmentCode = ActorsUtils.Environment.Value

	local IgnorePlayerModule = wax.shared.SaveManager:GetState("IgnorePlayerModule", true)
	local IgnoredRemotesDropdown = wax.shared.SaveManager:GetState("IgnoredRemotesDropdown", {
		["BindableEvent"] = true,
		["BindableFunction"] = true,
	})

	local AlternativeEnabled = wax.shared.SaveManager:GetState("UseAlternativeHooks", false)

	local CommunicationChannelID, Channel = create_comm_channel()
	wax.shared.ActorCommunicator = Channel

	local ActorData = LuaEncode({
		Token = wax.shared.NovaVerificationToken,
		IgnorePlayerModule = IgnorePlayerModule,
		IgnoredRemotesDropdown = IgnoredRemotesDropdown,
		UseAlternativeHooks = AlternativeEnabled,
		ExecutorSupport = wax.shared.ExecutorSupport,
	})

	ActorEnvironmentCode = ActorEnvironmentCode:gsub("NOVA_ACTOR_DATA", ActorData)

	-- Actor Logs Sync Layer
	local function ReconstructTable(Info, CyclicRefs)
		local Reconstructed = {}

		for Key, Value in Info do
			if type(Value) == "table" then
				if Value["__Function"] and Value["Validation"] == wax.shared.NovaVerificationToken then
					local FunctionData = table.clone(Value)
					FunctionData["__Function"] = nil
					FunctionData["Validation"] = nil

					Reconstructed[Key] = FunctionData
				else
					Reconstructed[Key] = ReconstructTable(Value, CyclicRefs)
				end
			else
				Reconstructed[Key] = Value
			end
		end

		return Reconstructed
	end

	-- Listen for actor events
	Channel:Listen("ActorLog", function(RemoteInstance, EventType, CallInfo)
		if not RemoteInstance or not EventType then
			return
		end

		local Log = wax.shared.Logs[EventType][RemoteInstance]
		if not Log then
			Log = wax.shared.Log and wax.shared.Log.new(RemoteInstance, EventType, CallInfo.Method, nil, nil)
			if Log then
				wax.shared.Logs[EventType][RemoteInstance] = Log
			end
		end

		if Log then
			local ReconstructedInfo = ReconstructTable(CallInfo, {})
			Log:Call(ReconstructedInfo)
		end
	end)

	-- Run on all actors
	for _, Actor in getactors() do
		pcall(function()
			run_on_actor(Actor, ActorEnvironmentCode, CommunicationChannelID)
		end)
	end
end

return {}

end)() end,
    [37] = function()local wax,script,require=ImportGlobals(37)local ImportGlobals return (function(...)--[[
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
		local delta = input.Position.X - dividerDragStart
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

		-- Cobalt-style CallFrame: auto-sizing, with inline args
		local callEntry = Interface.New("TextButton", {
			Text = "",
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			AutoButtonColor = false,
			LayoutOrder = i,
			ClipsDescendants = true,
			Parent = LogsList,

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

Drag.new(InfoFrame)
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

-- Active bottom dropdown state
local ActiveBottomDropdown = nil

local function CloseBottomDropdown()
	if ActiveBottomDropdown then
		ActiveBottomDropdown.Visible = false
		ActiveBottomDropdown = nil
	end
end

local function CreateBottomDropdownButton(text, iconName, optionsBuilder)
	local btn = Interface.New("TextButton", {
		Text = "",
		BackgroundColor3 = Theme.SurfaceHover,
		Size = UDim2.new(0, 0, 0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		AutoButtonColor = false,
		ZIndex = 53,
		Parent = BottomBar,
		["UICorner"] = { CornerRadius = UDim.new(0, 5) },
		["UIPadding"] = {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 10),
		},
	})

	local ico = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Theme.TextMuted,
		ZIndex = 54,
		Parent = btn,
	})
	Icons.ApplyIcon(ico, iconName)

	Interface.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0, 16, 0, 0),
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		ZIndex = 54,
		Parent = btn,
	})

	-- Chevron indicator
	local chevron = Interface.New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.new(1, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Theme.TextMuted,
		ZIndex = 54,
		Parent = btn,
	})
	Icons.ApplyIcon(chevron, "chevron-up")

	-- Dropdown menu
	local dropdownMenu = Interface.New("Frame", {
		BackgroundColor3 = Theme.Surface,
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

	local function RebuildOptions()
		-- Clear old items
		for _, child in ipairs(dropdownMenu:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local options = optionsBuilder()
		for _, opt in ipairs(options) do
			-- Skip if condition fails
			if opt.Condition and not opt.Condition() then
				continue
			end

			local item = Interface.New("TextButton", {
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 28),
				AutoButtonColor = false,
				ZIndex = 201,
				Parent = dropdownMenu,
			})

			local optIco = Interface.New("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				ImageColor3 = Theme.TextMuted,
				ZIndex = 202,
				Parent = item,
			})
			Icons.ApplyIcon(optIco, opt.Icon)

			Interface.New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -34, 1, 0),
				Position = UDim2.new(0, 30, 0, 0),
				Text = opt.Text,
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
				CloseBottomDropdown()
				if opt.Callback then
					opt.Callback()
				end
			end)
		end
	end

	Helper.HoverEffect(btn, Theme.Border, Theme.SurfaceHover)
	btn.MouseButton1Click:Connect(function()
		if ActiveBottomDropdown == dropdownMenu then
			CloseBottomDropdown()
			return
		end
		CloseBottomDropdown()

		RebuildOptions()

		-- Position above the button
		local absPos = btn.AbsolutePosition
		local absSize = btn.AbsoluteSize
		local scale = GetDPIScale()
		dropdownMenu.Position = UDim2.fromOffset(absPos.X / scale, (absPos.Y - 4) / scale)
		dropdownMenu.AnchorPoint = Vector2.new(0, 1)
		dropdownMenu.Visible = true
		ActiveBottomDropdown = dropdownMenu
	end)

	return btn, dropdownMenu
end

-- Close dropdown on click elsewhere
wax.shared.Connect(wax.shared.UserInputService.InputBegan:Connect(function(input)
	if ActiveBottomDropdown and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2) then
		task.defer(function()
			CloseBottomDropdown()
		end)
	end
end))

-- ===== CODE dropdown =====
CreateBottomDropdownButton("Code", "code", function()
	return {
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
	}
end)

-- ===== ORIGIN dropdown =====
CreateBottomDropdownButton("Origin", "file-text", function()
	return {
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
	}
end)

-- ===== EVENT dropdown =====
CreateBottomDropdownButton("Event", "git-branch", function()
	return {
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
			Text = "Ignore",
			Icon = "eye-off",
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
			Text = "Block",
			Icon = "lock",
			Condition = function()
				return CurrentDetailLogEntry ~= nil
			end,
			Callback = function()
				if not CurrentDetailLogEntry then return end
				CurrentDetailLogEntry:Block()
				wax.shared.Sonner.success(`{CurrentDetailLogEntry.Blocked and "Blocking" or "Unblocked"} {CurrentDetailLogEntry.Instance.Name}`)
			end,
		},
	}
end)

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

end)() end,
    [19] = function()local wax,script,require=ImportGlobals(19)local ImportGlobals return (function(...)--[[
	Session Exporter for Nova
	Exports logged session data to an HTML file.
]]

local SessionExporter = {}

function SessionExporter:ProcessCalls(AllCalls, SessionData, UpdateProgress)
	local Events = {}
	local StringMap = {}
	local StringIndex = 0

	local function InternString(str)
		if not StringMap[str] then
			StringMap[str] = StringIndex
			StringIndex += 1
		end
		return StringMap[str]
	end

	local Total = #AllCalls
	for i, CallData in ipairs(AllCalls) do
		if UpdateProgress then
			UpdateProgress(i / Total)
		end

		local event = {
			Type = InternString(CallData.Type or "Unknown"),
			Remote = InternString(CallData.RemoteName or "Unknown"),
			ClassName = InternString(CallData.ClassName or "Unknown"),
			Time = CallData.Time or 0,
			ArgCount = CallData.ArgCount or 0,
		}

		table.insert(Events, event)
	end

	return Events, StringMap
end

function SessionExporter:ExportSessionToHTML(Events, StringMap, SessionData)
	local ReverseStringMap = {}
	for str, idx in pairs(StringMap) do
		ReverseStringMap[idx] = str
	end

	local eventsJson = wax.shared.HttpService:JSONEncode(Events)
	local stringMapJson = wax.shared.HttpService:JSONEncode(ReverseStringMap)

	local SessionId = SessionData.SessionId or wax.shared.HttpService:GenerateGUID(false)
	local StartTime = SessionData.StartTime or 0
	local EndTime = SessionData.EndTime or tick()
	local PlaceId = SessionData.PlaceId or game.PlaceId
	local Duration = string.format("%.1f", EndTime - StartTime)

	local HTML = [[<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nova - Session Viewer</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, monospace;
            background: #0d1117;
            color: #c9d1d9;
        }
        .header {
            background: #161b22;
            border-bottom: 1px solid #30363d;
            padding: 12px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .brand {
            font-weight: 700;
            font-size: 16px;
            color: #58a6ff;
        }
        .session-info {
            font-size: 12px;
            color: #8b949e;
        }
        .content {
            padding: 20px;
            max-width: 1200px;
            margin: 0 auto;
        }
        .stats {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 16px;
            flex: 1;
        }
        .stat-label {
            font-size: 11px;
            color: #8b949e;
            text-transform: uppercase;
            margin-bottom: 4px;
        }
        .stat-value {
            font-size: 24px;
            font-weight: 700;
            color: #f0f6fc;
        }
        .event-table {
            width: 100%;
            border-collapse: collapse;
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 6px;
            overflow: hidden;
        }
        .event-table th {
            background: #21262d;
            padding: 8px 12px;
            text-align: left;
            font-size: 12px;
            color: #8b949e;
            font-weight: 600;
        }
        .event-table td {
            padding: 6px 12px;
            border-top: 1px solid #21262d;
            font-size: 13px;
        }
        .type-incoming { color: #3fb950; }
        .type-outgoing { color: #f78166; }
        .footer {
            padding: 12px 20px;
            text-align: center;
            color: #484f58;
            font-size: 11px;
            border-top: 1px solid #30363d;
            margin-top: 40px;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="brand">Nova - Session Viewer</div>
        <div class="session-info">Session / ]] .. SessionId .. [[</div>
    </div>
    <div class="content">
        <div class="stats">
            <div class="stat-card">
                <div class="stat-label">Total Events</div>
                <div class="stat-value">]] .. tostring(#Events) .. [[</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Duration</div>
                <div class="stat-value">]] .. Duration .. [[s</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Place ID</div>
                <div class="stat-value">]] .. tostring(PlaceId) .. [[</div>
            </div>
        </div>
        <table class="event-table">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Type</th>
                    <th>Remote</th>
                    <th>Class</th>
                    <th>Time</th>
                    <th>Args</th>
                </tr>
            </thead>
            <tbody id="eventBody"></tbody>
        </table>
    </div>
    <div class="footer">Generated by Nova Remote Spy</div>
    <script>
        const events = ]] .. eventsJson .. [[;
        const stringMap = ]] .. stringMapJson .. [[;
        const body = document.getElementById('eventBody');
        events.forEach((e, i) => {
            const type = stringMap[e.Type] || 'Unknown';
            const typeClass = type === 'Incoming' ? 'type-incoming' : 'type-outgoing';
            body.innerHTML += `<tr>
                <td>${i + 1}</td>
                <td class="${typeClass}">${type}</td>
                <td>${stringMap[e.Remote] || 'Unknown'}</td>
                <td>${stringMap[e.ClassName] || 'Unknown'}</td>
                <td>${e.Time.toFixed(3)}s</td>
                <td>${e.ArgCount}</td>
            </tr>`;
        });
    </script>
</body>
</html>]]

	return HTML
end

return SessionExporter

end)() end,
    [18] = function()local wax,script,require=ImportGlobals(18)local ImportGlobals return (function(...)--[[
	Code Generation Module for Nova
	Generates Lua code snippets for remote calls.
]]

local CodeGen = {}

CodeGen.CleanTable = {}

local MethodMap = {
	Incoming = {
		RemoteEvent = "OnClientEvent",
		RemoteFunction = "OnClientInvoke",
		UnreliableRemoteEvent = "OnClientEvent",
		BindableEvent = "Event",
		BindableFunction = "OnInvoke",
	},

	Outgoing = {
		RemoteEvent = "FireServer",
		RemoteFunction = "InvokeServer",
		UnreliableRemoteEvent = "FireServer",
		BindableEvent = "Fire",
		BindableFunction = "Invoke",
	},
}

local GetNilCode = [[local function GetNil(Name, DebugId)
	for _, Object in getnilinstances() do
		if Object.Name == Name and Object:GetDebugId() == DebugId then
			return Object
		end
	end
end]]

-- Clean string characters
for i = 0, 31 do
	CodeGen.CleanTable[string.char(i)] = "\\" .. string.format("%03d", i)
end
for i = 127, 255 do
	CodeGen.CleanTable[string.char(i)] = "\\" .. string.format("%03d", i)
end

function CodeGen.FormatLuaString(str)
	local cleaned = string.gsub(str, ".", function(c)
		return CodeGen.CleanTable[c] or c
	end)
	cleaned = string.gsub(cleaned, '"', '\\"')
	return `"{cleaned}"`
end

function CodeGen.GetFullPath(instance, options)
	options = options or {}
	local VariableName = options.VariableName or "Remote"
	local DisableNilParentHandler = options.DisableNilParentHandler or false
	local UseMethod = wax.shared.SaveManager:GetState("PathMethod", "Index")

	if not instance then
		return `local {VariableName} = nil -- Instance not found`
	end

	local path = {}
	local current = instance
	local nilParent = false

	while current and current ~= game do
		table.insert(path, 1, current)
		if current.Parent == nil then
			nilParent = true
			break
		end
		current = current.Parent
	end

	if nilParent and not DisableNilParentHandler then
		local debugId = pcall(function() return instance:GetDebugId() end) and instance:GetDebugId() or "unknown"
		return `{GetNilCode}\n\nlocal {VariableName} = GetNil("{instance.Name}", "{debugId}")`
	end

	local code = ""
	local service = path[1]

	if service and service.Parent == game then
		code = `game:GetService("{service.ClassName}")`

		for i = 2, #path do
			local child = path[i]
			local name = child.Name

			if UseMethod == "FindFirstChild" then
				code ..= `:FindFirstChild("{name}")`
			elseif UseMethod == "WaitForChild" then
				code ..= `:WaitForChild("{name}")`
			else
				-- Index method
				if string.match(name, "^[%a_][%w_]*$") then
					code ..= `.{name}`
				else
					code ..= `["{name}"]`
				end
			end
		end
	else
		code = `workspace -- Could not resolve path for {instance.Name}`
	end

	return `local {VariableName} = {code}`
end

function CodeGen.GenerateCode(logEntry, callInfo, options)
	options = options or {}
	local ShowWatermark = wax.shared.SaveManager:GetState("ShowWatermark", true)
	local PreferBuffer = wax.shared.SaveManager:GetState("PreferBufferFromString", false)

	local instance = logEntry.Instance
	local eventType = logEntry.Type
	local className = instance.ClassName

	local method = MethodMap[eventType] and MethodMap[eventType][className]
	if not method then
		return "-- Unknown remote type"
	end

	local lines = {}

	-- Watermark
	if ShowWatermark then
		table.insert(lines, "-- Generated by Nova Remote Spy")
		table.insert(lines, "")
	end

	-- Path
	table.insert(lines, CodeGen.GetFullPath(instance, { VariableName = "Remote" }))
	table.insert(lines, "")

	-- Args
	if callInfo and callInfo.Args then
		local args = callInfo.Args
		if #args > 0 then
			local Success, Encoded = pcall(wax.shared.LuaEncode, args, {
				Prettify = true,
				FunctionsReturnRaw = true,
				UseInstancePaths = true,
			})

			if Success then
				table.insert(lines, `local Args = {Encoded}`)
				table.insert(lines, "")
				table.insert(lines, `Remote:{method}(unpack(Args))`)
			else
				table.insert(lines, `-- Failed to serialize args: {tostring(Encoded)}`)
				table.insert(lines, `Remote:{method}()`)
			end
		else
			table.insert(lines, `Remote:{method}()`)
		end
	else
		table.insert(lines, `Remote:{method}()`)
	end

	return table.concat(lines, "\n")
end

function CodeGen.GenerateInterceptCode(logEntry, options)
	options = options or {}
	local ShowWatermark = wax.shared.SaveManager:GetState("ShowWatermark", true)

	local instance = logEntry.Instance
	local eventType = logEntry.Type
	local className = instance.ClassName

	local lines = {}

	if ShowWatermark then
		table.insert(lines, "-- Generated by Nova Remote Spy (Intercept)")
		table.insert(lines, "")
	end

	table.insert(lines, CodeGen.GetFullPath(instance, { VariableName = "Remote" }))
	table.insert(lines, "")

	if eventType == "Outgoing" then
		if className == "RemoteEvent" or className == "UnreliableRemoteEvent" then
			table.insert(lines, [[local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
	if not checkcaller() and getnamecallmethod() == "FireServer" and self == Remote then
		-- Modify args here
		return OldNamecall(self, ...)
	end
	return OldNamecall(self, ...)
end))]])
		elseif className == "RemoteFunction" then
			table.insert(lines, [[local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
	if not checkcaller() and getnamecallmethod() == "InvokeServer" and self == Remote then
		-- Modify args or return value here
		return OldNamecall(self, ...)
	end
	return OldNamecall(self, ...)
end))]])
		end
	elseif eventType == "Incoming" then
		local connectionName = MethodMap.Incoming[className]
		if connectionName then
			table.insert(lines, `Remote.{connectionName}:Connect(function(...)`)
			table.insert(lines, `	print("Intercepted:", ...)`)
			table.insert(lines, `end)`)
		end
	end

	return table.concat(lines, "\n")
end

return CodeGen

end)() end,
    [30] = function()local wax,script,require=ImportGlobals(30)local ImportGlobals return (function(...)--[[
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
		if #display > 50 then
			display = string.sub(display, 1, 47) .. "..."
		end
		return `"{display}"`
	elseif t == "Instance" then
		return value:GetFullName()
	elseif t == "boolean" then
		return tostring(value)
	elseif t == "number" then
		return tostring(value)
	elseif t == "nil" then
		return "nil"
	elseif t == "EnumItem" then
		return tostring(value)
	elseif t == "Vector3" or t == "Vector2" or t == "CFrame" or t == "UDim2" or t == "UDim" or t == "Color3" or t == "BrickColor" then
		return tostring(value)
	elseif t == "table" then
		local len = 0
		for _ in pairs(value) do
			len += 1
			if len > 3 then break end
		end
		return `\{...} ({len}+ entries)`
	elseif t == "function" then
		return "function()"
	elseif t == "buffer" then
		return `buffer({buffer.len(value)} bytes)`
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

end)() end,
    [23] = function()local wax,script,require=ImportGlobals(23)local ImportGlobals return (function(...)local Log = {}
Log.__index = Log

--// Auto Ignore Constants \\--
local SpamCallCountThreshold = 15
local SpamTimeWindowSeconds = 1

function Log.new(Instance, Type, Method, Index, CallingScript)
	local NewLog = setmetatable({
		Instance = Instance,
		Type = Type,
		Method = Method,
		Index = Index,
		Calls = {},
		GameCalls = {},
		SpamHistory = {},
		Ignored = false,
		Blocked = false,
		Button = nil,
	}, Log)

	return NewLog
end

function DeepClone(orig, copies)
	copies = copies or {}

	if typeof(orig) == "Instance" then
		return cloneref(orig)
	elseif typeof(orig) == "userdata" then
		if getmetatable(orig) then
			return newproxy(true)
		else
			return newproxy()
		end
	elseif typeof(orig) == "function" then
		if clonefunction then
			return clonefunction(orig)
		end
		return orig
	elseif type(orig) ~= "table" then
		return orig
	elseif copies[orig] then
		return copies[orig]
	end

	local copy = {}
	copies[orig] = copy

	for key, value in pairs(orig) do
		copy[DeepClone(key, copies)] = DeepClone(value, copies)
	end

	return setmetatable(copy, DeepClone(getmetatable(orig), copies))
end

function Log:IsOverSpamThreshold()
	local Now = tick()
	table.insert(self.SpamHistory, Now)

	-- Remove old entries
	local Cutoff = Now - SpamTimeWindowSeconds
	while #self.SpamHistory > 0 and self.SpamHistory[1] < Cutoff do
		table.remove(self.SpamHistory, 1)
	end

	if #self.SpamHistory >= SpamCallCountThreshold then
		if not self.Ignored then
			self:Ignore()
			wax.shared.Sonner.warning(`Auto-ignored {self.Instance.Name} (spam detected)`)
		end
		return true
	end

	return false
end

function Log:Call(RawInfo)
	if self.Ignored or self.Blocked then
		return
	end

	local Success, Data = pcall(function()
		return self:IsOverSpamThreshold()
	end)

	if Success and Data then
		return
	end

	local Info = DeepClone(RawInfo)
	Info.CreationTime = tick()

	local Index = #self.Calls + 1
	self.Calls[Index] = Info
	if not Info.IsExecutor then
		table.insert(self.GameCalls, Index)
	end

	if wax.shared.Communicator then
		wax.shared.Communicator.Fire(wax.shared.Communicator, self.Instance, self.Type, #self.Calls)
	end
end

function Log:Ignore()
	if wax.shared.ActorCommunicator then
		pcall(function()
			wax.shared.ActorCommunicator:Fire("MainIgnore", self.Instance, self.Type)
		end)
	end

	self.Ignored = not self.Ignored

	local IgnoredRemoteList = wax.shared.Settings["IgnoredRemotes"]
	if IgnoredRemoteList then
		if self.Ignored then
			IgnoredRemoteList:AddToList(self)
		else
			IgnoredRemoteList:RemoveFromList(self)
		end
	end
end

local ClassesConnectionsToggle = {
	RemoteEvent = "OnClientEvent",
	UnreliableRemoteEvent = "OnClientEvent",
	BindableEvent = "Event",
}

function Log:SetConnectionsEnabled(enabled: boolean)
	if not self.Instance or not ClassesConnectionsToggle[self.Instance.ClassName] then
		return
	end

	local ConnectionName = ClassesConnectionsToggle[self.Instance.ClassName]
	if self.Type ~= "Incoming" or not ConnectionName then
		return
	end

	for _, Connection in pairs(getconnections(self.Instance[ConnectionName])) do
		if enabled then
			Connection:Enable()
		else
			Connection:Disable()
		end
	end
end

function Log:Block()
	if wax.shared.ActorCommunicator then
		pcall(function()
			wax.shared.ActorCommunicator:Fire("MainBlock", self.Instance, self.Type)
		end)
	end

	self.Blocked = not self.Blocked
	Log:SetConnectionsEnabled(not self.Blocked)
end

function Log:SetButton(Instance, Name, Calls)
	self.Button = {
		Instance = Instance,
		Name = Name,
		Calls = Calls,
	}
end

function Log:GetLatestCall()
	return self.Calls[#self.Calls]
end

function Log:GetCallCount()
	return #self.Calls
end

function Log:GetGameCallCount()
	return #self.GameCalls
end

return Log

end)() end,
    [25] = function()local wax,script,require=ImportGlobals(25)local ImportGlobals return (function(...)if not isfolder("Nova") then
	makefolder("Nova")
end

if not isfile("Nova/Settings.json") then
	writefile("Nova/Settings.json", "{}")
end

local SaveManager = {
	State = {},
}

local Success, Error = pcall(function()
	SaveManager.State = wax.shared.HttpService:JSONDecode(readfile("Nova/Settings.json"))
end)

if not Success then
	warn("[Nova] Failed to load settings: " .. Error)
end

function SaveManager:SetState(Idx, Value)
	SaveManager.State[Idx] = Value
	pcall(writefile, "Nova/Settings.json", wax.shared.HttpService:JSONEncode(SaveManager.State))
end

function SaveManager:GetState(Idx, Default)
	if SaveManager.State[Idx] ~= nil then
		return SaveManager.State[Idx]
	end

	return Default
end

return SaveManager

end)() end,
    [31] = function()local wax,script,require=ImportGlobals(31)local ImportGlobals return (function(...)--[[
	Syntax Highlighter for Nova
	Simple Luau syntax highlighter for code display.
]]

local Highlighter = {}

local Keywords = {
	["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
	["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
	["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
	["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
	["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
	["while"] = true, ["continue"] = true, ["type"] = true, ["export"] = true,
}

local Globals = {
	["game"] = true, ["workspace"] = true, ["script"] = true, ["math"] = true,
	["string"] = true, ["table"] = true, ["task"] = true, ["coroutine"] = true,
	["Instance"] = true, ["Vector3"] = true, ["Vector2"] = true, ["CFrame"] = true,
	["Color3"] = true, ["BrickColor"] = true, ["UDim2"] = true, ["UDim"] = true,
	["Enum"] = true, ["pairs"] = true, ["ipairs"] = true, ["next"] = true,
	["pcall"] = true, ["xpcall"] = true, ["require"] = true, ["select"] = true,
	["unpack"] = true, ["type"] = true, ["typeof"] = true, ["tostring"] = true,
	["tonumber"] = true, ["print"] = true, ["warn"] = true, ["error"] = true,
	["assert"] = true, ["rawget"] = true, ["rawset"] = true, ["setmetatable"] = true,
	["getmetatable"] = true, ["newproxy"] = true, ["tick"] = true, ["wait"] = true,
	["spawn"] = true, ["delay"] = true,
}

local Colors = {
	Keyword = Color3.fromRGB(198, 120, 221),
	String = Color3.fromRGB(152, 195, 121),
	Number = Color3.fromRGB(209, 154, 102),
	Comment = Color3.fromRGB(92, 99, 112),
	Global = Color3.fromRGB(97, 175, 239),
	Method = Color3.fromRGB(86, 182, 194),
	Default = Color3.fromRGB(171, 178, 191),
	Operator = Color3.fromRGB(86, 182, 194),
}

function Highlighter.Highlight(code: string): string
	-- Simple rich text syntax highlighting
	local result = code

	-- Escape rich text characters first
	result = result:gsub("&", "&amp;")
	result = result:gsub("<", "&lt;")
	result = result:gsub(">", "&gt;")

	-- Comments (single line)
	result = result:gsub("(%-%-[^\n]*)", function(match)
		return `<font color="#{Colors.Comment:ToHex()}">{match}</font>`
	end)

	-- Strings (double quoted)
	result = result:gsub('(".-")', function(match)
		return `<font color="#{Colors.String:ToHex()}">{match}</font>`
	end)

	-- Strings (single quoted)
	result = result:gsub("('.-')", function(match)
		return `<font color="#{Colors.String:ToHex()}">{match}</font>`
	end)

	-- Numbers
	result = result:gsub("(%d+%.?%d*)", function(match)
		return `<font color="#{Colors.Number:ToHex()}">{match}</font>`
	end)

	-- Keywords
	for keyword in pairs(Keywords) do
		result = result:gsub("(%f[%w_])" .. keyword .. "(%f[^%w_])", function(pre, post)
			return `{pre}<font color="#{Colors.Keyword:ToHex()}">{keyword}</font>{post}`
		end)
	end

	return result
end

-- Get argument value color based on type (matching Cobalt's syntax scheme)
function Highlighter.GetArgumentColor(value): Color3
	local t = typeof(value)
	if t == "string" then
		return Colors.String
	elseif t == "number" or t == "boolean" then
		return Colors.Number
	elseif t == "nil" then
		return Colors.Number
	elseif t == "EnumItem" or t == "Enum" then
		return Colors.Method
	elseif t == "Instance" then
		return Colors.Global
	elseif t == "Vector3" or t == "Vector2" or t == "CFrame" or t == "UDim2" or t == "UDim" or t == "Color3" or t == "BrickColor" then
		return Colors.Number
	elseif t == "function" then
		return Colors.Keyword
	else
		return Colors.Default
	end
end

Highlighter.Colors = Colors

return Highlighter

end)() end,
    [27] = function()local wax,script,require=ImportGlobals(27)local ImportGlobals return (function(...)-- LuaEncode - Optimal Table Serialization for Native Luau/Lua 5.1+
-- Copyright (c) 2022-2023 Reggie <reggie@latte.to> | MIT License
-- https://github.com/regginator/LuaEncode
-- Adapted for Nova Remote Spy

--!nocheck
--!optimize 2

local table, ipairs, string, next, pcall, game, workspace, tostring, tonumber, getmetatable = table, ipairs, string, next, pcall, game, workspace, tostring, tonumber, getmetatable

local string_format = string.format
local string_char = string.char
local string_gsub = string.gsub
local string_match = string.match
local string_rep = string.rep
local string_sub = string.sub
local string_gmatch = string.gmatch

local table_find = table.find
local table_concat = table.concat
local table_insert = table.insert

local Type = typeof or type

local function CheckType(value, argName, ...)
	local AllowedTypes = { ... }
	local ValueType = Type(value)

	if not table_find(AllowedTypes, ValueType) then
		error(string_format("invalid argument '%s' (%s expected, got %s)", argName, table_concat(AllowedTypes, " or "), ValueType), 3)
	end
end

local SerializerVersion = "1.0.0-nova"

local function LuaEncode(inputTable, options)
	options = options or {}

	CheckType(inputTable, "inputTable", "table")
	CheckType(options, "options", "table")

	local Prettify = (options.Prettify or options.PrettyPrinting) or false
	local IndentCount = options.IndentCount or (Prettify and 4 or 0)
	local InsertCycles = options.InsertCycles or false
	local OutputWarnings = (options.OutputWarnings == nil and true) or options.OutputWarnings
	local FunctionsReturnRaw = options.FunctionsReturnRaw or false
	local UseInstancePaths = (options.UseInstancePaths == nil and true) or options.UseInstancePaths
	local SerializeMathHuge = (options.SerializeMathHuge == nil and true) or options.SerializeMathHuge
	local DisableNilParentHandler = options.DisableNilParentHandler or false
	local IsArray = options.IsArray or false

	local StackLevel = options._StackLevel or 1
	local VisitedTables = options._VisitedTables or {}

	local PositiveInf = (SerializeMathHuge and "math.huge") or "1/0"
	local NegativeInf = (SerializeMathHuge and "-math.huge") or "-1/0"
	local NewEntryString = (Prettify and "\n") or ""
	local ValueSeperator = (Prettify and ", ") or ","

	local IndentString = string_rep(" ", IndentCount)
	local CurrentIndent = string_rep(IndentString, StackLevel)
	local PreviousIndent = string_rep(IndentString, StackLevel - 1)

	local function SerializeString(str)
		return string_format("%q", str)
	end

	local function SerializeNumber(num)
		if num ~= num then
			return "0/0" -- NaN
		elseif num == math.huge then
			return PositiveInf
		elseif num == -math.huge then
			return NegativeInf
		end
		return tostring(num)
	end

	local function SerializeInstance(inst)
		if not UseInstancePaths then
			return `"Instance<{inst.ClassName}>"`
		end

		local path = {}
		local current = inst
		while current and current ~= game do
			table_insert(path, 1, current.Name)
			current = current.Parent
		end

		if #path == 0 then
			return `"Instance<{inst.Name} (nil parent)>"`
		end

		local service = inst
		local temp = inst
		while temp.Parent and temp.Parent ~= game do
			temp = temp.Parent
		end
		if temp.Parent == game then
			service = temp
		end

		local result = `game:GetService("{service.ClassName}")`
		local parts = {}
		local c = inst
		while c and c ~= service do
			table_insert(parts, 1, c.Name)
			c = c.Parent
		end

		for _, name in ipairs(parts) do
			if string_match(name, "^[%a_][%w_]*$") then
				result ..= `.{name}`
			else
				result ..= `[{SerializeString(name)}]`
			end
		end

		return result
	end

	local Output = {}

	if VisitedTables[inputTable] then
		return `"<Cyclic Reference>"`
	end
	VisitedTables[inputTable] = true

	-- Check if array
	local isArray = IsArray
	if not isArray then
		local maxIndex = 0
		local count = 0
		for k, _ in pairs(inputTable) do
			if type(k) == "number" and k > 0 and math.floor(k) == k then
				maxIndex = math.max(maxIndex, k)
			end
			count += 1
		end
		isArray = (count > 0 and maxIndex == count)
	end

	table_insert(Output, "{" .. NewEntryString)

	local isFirst = true

	if isArray then
		for i, value in ipairs(inputTable) do
			if not isFirst then
				table_insert(Output, "," .. NewEntryString)
			end
			isFirst = false

			table_insert(Output, CurrentIndent)

			local valueType = Type(value)
			if valueType == "table" then
				table_insert(Output, LuaEncode(value, {
					Prettify = Prettify,
					IndentCount = IndentCount,
					FunctionsReturnRaw = FunctionsReturnRaw,
					UseInstancePaths = UseInstancePaths,
					SerializeMathHuge = SerializeMathHuge,
					_StackLevel = StackLevel + 1,
					_VisitedTables = VisitedTables,
				}))
			elseif valueType == "string" then
				table_insert(Output, SerializeString(value))
			elseif valueType == "number" then
				table_insert(Output, SerializeNumber(value))
			elseif valueType == "boolean" then
				table_insert(Output, tostring(value))
			elseif valueType == "Instance" then
				table_insert(Output, SerializeInstance(value))
			elseif valueType == "function" then
				if FunctionsReturnRaw then
					local info = debug.info(value, "n")
					table_insert(Output, `"<Function: {info or "anonymous"}>"`)
				else
					table_insert(Output, `"<Function>"`)
				end
			elseif valueType == "nil" then
				table_insert(Output, "nil")
			elseif valueType == "Vector3" then
				table_insert(Output, `Vector3.new({value.X}{ValueSeperator}{value.Y}{ValueSeperator}{value.Z})`)
			elseif valueType == "Vector2" then
				table_insert(Output, `Vector2.new({value.X}{ValueSeperator}{value.Y})`)
			elseif valueType == "CFrame" then
				local components = { value:GetComponents() }
				table_insert(Output, `CFrame.new({table_concat(components, ValueSeperator)})`)
			elseif valueType == "Color3" then
				table_insert(Output, `Color3.new({value.R}{ValueSeperator}{value.G}{ValueSeperator}{value.B})`)
			elseif valueType == "BrickColor" then
				table_insert(Output, `BrickColor.new("{tostring(value)}")`)
			elseif valueType == "EnumItem" then
				table_insert(Output, tostring(value))
			elseif valueType == "UDim" then
				table_insert(Output, `UDim.new({value.Scale}{ValueSeperator}{value.Offset})`)
			elseif valueType == "UDim2" then
				table_insert(Output, `UDim2.new({value.X.Scale}{ValueSeperator}{value.X.Offset}{ValueSeperator}{value.Y.Scale}{ValueSeperator}{value.Y.Offset})`)
			elseif valueType == "Ray" then
				table_insert(Output, `Ray.new(Vector3.new({value.Origin.X}{ValueSeperator}{value.Origin.Y}{ValueSeperator}{value.Origin.Z}){ValueSeperator}Vector3.new({value.Direction.X}{ValueSeperator}{value.Direction.Y}{ValueSeperator}{value.Direction.Z}))`)
			elseif valueType == "NumberRange" then
				table_insert(Output, `NumberRange.new({value.Min}{ValueSeperator}{value.Max})`)
			elseif valueType == "buffer" then
				local bufStr = buffer.tostring(value)
				table_insert(Output, `buffer.fromstring({SerializeString(bufStr)})`)
			else
				table_insert(Output, `"<{valueType}>"`)
			end
		end
	else
		for key, value in pairs(inputTable) do
			if not isFirst then
				table_insert(Output, "," .. NewEntryString)
			end
			isFirst = false

			table_insert(Output, CurrentIndent)

			-- Key
			local keyType = Type(key)
			if keyType == "string" then
				if string_match(key, "^[%a_][%w_]*$") then
					table_insert(Output, key .. " = ")
				else
					table_insert(Output, `[{SerializeString(key)}] = `)
				end
			elseif keyType == "number" then
				table_insert(Output, `[{SerializeNumber(key)}] = `)
			else
				table_insert(Output, `[{SerializeString(tostring(key))}] = `)
			end

			-- Value
			local valueType = Type(value)
			if valueType == "table" then
				table_insert(Output, LuaEncode(value, {
					Prettify = Prettify,
					IndentCount = IndentCount,
					FunctionsReturnRaw = FunctionsReturnRaw,
					UseInstancePaths = UseInstancePaths,
					SerializeMathHuge = SerializeMathHuge,
					_StackLevel = StackLevel + 1,
					_VisitedTables = VisitedTables,
				}))
			elseif valueType == "string" then
				table_insert(Output, SerializeString(value))
			elseif valueType == "number" then
				table_insert(Output, SerializeNumber(value))
			elseif valueType == "boolean" then
				table_insert(Output, tostring(value))
			elseif valueType == "Instance" then
				table_insert(Output, SerializeInstance(value))
			elseif valueType == "function" then
				if FunctionsReturnRaw then
					local info = debug.info(value, "n")
					table_insert(Output, `"<Function: {info or "anonymous"}>"`)
				else
					table_insert(Output, `"<Function>"`)
				end
			elseif valueType == "nil" then
				table_insert(Output, "nil")
			elseif valueType == "Vector3" then
				table_insert(Output, `Vector3.new({value.X}{ValueSeperator}{value.Y}{ValueSeperator}{value.Z})`)
			elseif valueType == "Vector2" then
				table_insert(Output, `Vector2.new({value.X}{ValueSeperator}{value.Y})`)
			elseif valueType == "CFrame" then
				local components = { value:GetComponents() }
				table_insert(Output, `CFrame.new({table_concat(components, ValueSeperator)})`)
			elseif valueType == "Color3" then
				table_insert(Output, `Color3.new({value.R}{ValueSeperator}{value.G}{ValueSeperator}{value.B})`)
			elseif valueType == "BrickColor" then
				table_insert(Output, `BrickColor.new("{tostring(value)}")`)
			elseif valueType == "EnumItem" then
				table_insert(Output, tostring(value))
			elseif valueType == "UDim" then
				table_insert(Output, `UDim.new({value.Scale}{ValueSeperator}{value.Offset})`)
			elseif valueType == "UDim2" then
				table_insert(Output, `UDim2.new({value.X.Scale}{ValueSeperator}{value.X.Offset}{ValueSeperator}{value.Y.Scale}{ValueSeperator}{value.Y.Offset})`)
			elseif valueType == "buffer" then
				local bufStr = buffer.tostring(value)
				table_insert(Output, `buffer.fromstring({SerializeString(bufStr)})`)
			else
				table_insert(Output, `"<{valueType}>"`)
			end
		end
	end

	table_insert(Output, NewEntryString .. PreviousIndent .. "}")

	return table_concat(Output)
end

return LuaEncode

end)() end,
    [14] = function()local wax,script,require=ImportGlobals(14)local ImportGlobals return (function(...)--[[
	Anticheat Detection & Bypass Module for Nova
]]

local AnticheatMain = {
	Name = nil,
	Detected = false,
	Disabled = false,
	Bypass = nil,
}

-- Try to detect known anticheats
local function DetectAnticheats()
	-- Adonis detection
	local adonisSuccess, adonisResult = pcall(function()
		local adonisFolder = game:GetService("ReplicatedStorage"):FindFirstChild("_Adonis")
			or game:GetService("ServerScriptService"):FindFirstChild("Adonis_Loader")
		return adonisFolder ~= nil
	end)

	if adonisSuccess and adonisResult then
		AnticheatMain.Name = "Adonis"
		AnticheatMain.Detected = true
		AnticheatMain.Bypass = require(script.impl.Adonis)
		return
	end

	-- Generic detection for common anticheat patterns
	local genericSuccess, genericResult = pcall(function()
		local antiExploit = game:GetService("ReplicatedStorage"):FindFirstChild("AntiExploit")
			or game:GetService("ReplicatedStorage"):FindFirstChild("Anti-Exploit")
			or game:GetService("ReplicatedStorage"):FindFirstChild("AntiCheat")
		return antiExploit ~= nil
	end)

	if genericSuccess and genericResult then
		AnticheatMain.Name = "Generic AntiExploit"
		AnticheatMain.Detected = true
		return
	end
end

pcall(DetectAnticheats)

return AnticheatMain

end)() end,
    [16] = function()local wax,script,require=ImportGlobals(16)local ImportGlobals return (function(...)--[[
	Adonis Anticheat Bypass for Nova
]]

local function BypassAdonis()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local AdonisFolder = ReplicatedStorage:FindFirstChild("_Adonis")
	if not AdonisFolder then
		return false
	end

	-- Find and disable detection remotes
	local function DisableDetectionFunctions(parent)
		for _, child in pairs(parent:GetDescendants()) do
			if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
				local name = child.Name:lower()
				if name:find("detect") or name:find("kick") or name:find("ban") or name:find("exploit") then
					-- Hook the remote to prevent it from doing anything
					if child:IsA("RemoteFunction") and child.OnClientInvoke then
						local DetectionFunc = child.OnClientInvoke
						if typeof(DetectionFunc) == "function" then
							wax.shared.Hooks[DetectionFunc] = wax.shared.Hooking.HookFunction(
								DetectionFunc,
								function(action, info, nocrash)
									coroutine.yield(coroutine.running())
									return task.wait(9e9)
								end
							)
						end
					end
				end
			end
		end
	end

	pcall(DisableDetectionFunctions, AdonisFolder)

	-- Hook getconnections to hide our connections
	if getconnections then
		for _, connection in pairs(getconnections(game:GetService("Players").LocalPlayer.Idled)) do
			-- Keep connections alive but hidden
		end
	end

	return true
end

return BypassAdonis

end)() end
} -- [RefId] = Closure

-- Holds the actual DOM data
local ObjectTree = {
    {
        1,
        1,
        {
            "Nova"
        },
        {
            {
                2,
                4,
                {
                    "Src"
                },
                {
                    {
                        37,
                        2,
                        {
                            "Window"
                        }
                    },
                    {
                        4,
                        2,
                        {
                            "Spy"
                        },
                        {
                            {
                                11,
                                2,
                                {
                                    "Init"
                                }
                            },
                            {
                                7,
                                1,
                                {
                                    "Hooks"
                                },
                                {
                                    {
                                        8,
                                        1,
                                        {
                                            "Default"
                                        },
                                        {
                                            {
                                                10,
                                                2,
                                                {
                                                    "Outgoing"
                                                }
                                            },
                                            {
                                                9,
                                                2,
                                                {
                                                    "Incoming"
                                                }
                                            }
                                        }
                                    }
                                }
                            },
                            {
                                5,
                                1,
                                {
                                    "Actors"
                                },
                                {
                                    {
                                        6,
                                        5,
                                        {
                                            "Environment",
                                            Value = "-- Actor Environment Template for Nova\r\n-- This code runs inside each Actor's Lua VM to intercept remotes there.\r\n-- NOVA_ACTOR_DATA is replaced at runtime with serialized configuration.\r\n\r\nlocal ActorData = NOVA_ACTOR_DATA\r\n\r\nlocal Token = ActorData.Token\r\nlocal IgnorePlayerModule = ActorData.IgnorePlayerModule\r\nlocal IgnoredRemotesDropdown = ActorData.IgnoredRemotesDropdown\r\nlocal UseAlternativeHooks = ActorData.UseAlternativeHooks\r\nlocal ExecutorSupport = ActorData.ExecutorSupport\r\n\r\nlocal ChannelID, RelayChannel = create_comm_channel()\r\n\r\nlocal MethodToClass = {\r\n\tFireServer = { \"RemoteEvent\", \"UnreliableRemoteEvent\" },\r\n\tInvokeServer = { \"RemoteFunction\" },\r\n\tFire = { \"BindableEvent\" },\r\n\tInvoke = { \"BindableFunction\" },\r\n}\r\n\r\nlocal function ShouldIgnore(instance)\r\n\tif IgnoredRemotesDropdown[instance.ClassName] then\r\n\t\treturn true\r\n\tend\r\n\r\n\tif IgnorePlayerModule then\r\n\t\tlocal fullName = instance:GetFullName()\r\n\t\tif string.find(fullName, \"PlayerModule\") or string.find(fullName, \"PlayerScripts\") then\r\n\t\t\treturn true\r\n\t\tend\r\n\tend\r\n\r\n\treturn false\r\nend\r\n\r\n-- Hook __namecall in Actor VM\r\nlocal OldNamecall\r\nOldNamecall = hookmetamethod(game, \"__namecall\", newcclosure(function(...)\r\n\tlocal method = getnamecallmethod()\r\n\tlocal self = (...)\r\n\r\n\tif typeof(self) == \"Instance\" then\r\n\t\tlocal className = self.ClassName\r\n\t\tlocal validClasses = MethodToClass[method]\r\n\r\n\t\tif validClasses and table.find(validClasses, className) then\r\n\t\t\tif not ShouldIgnore(self) and not checkcaller() then\r\n\t\t\t\tlocal args = { select(2, ...) }\r\n\r\n\t\t\t\tRelayChannel:Fire(\"ActorLog\", self, \"Outgoing\", {\r\n\t\t\t\t\tArgs = args,\r\n\t\t\t\t\tMethod = method,\r\n\t\t\t\t\tIsExecutor = false,\r\n\t\t\t\t\tInstance = self,\r\n\t\t\t\t})\r\n\t\t\tend\r\n\t\tend\r\n\tend\r\n\r\n\treturn OldNamecall(...)\r\nend))\r\n\r\n-- Listen for commands from main thread\r\nRelayChannel:Listen(\"Unload\", function()\r\n\thookmetamethod(game, \"__namecall\", OldNamecall)\r\nend)\r\n\r\nRelayChannel:Listen(\"MainBlock\", function(Instance, EventType)\r\n\t-- Handle block sync from main thread\r\nend)\r\n\r\nRelayChannel:Listen(\"MainIgnore\", function(Instance, EventType)\r\n\t-- Handle ignore sync from main thread\r\nend)\r\n\r\nRelayChannel:Listen(\"MainSettingsSync\", function(Setting, Value)\r\n\t-- Handle settings sync from main thread\r\nend)\r\n"
                                        }
                                    }
                                }
                            }
                        }
                    },
                    {
                        12,
                        1,
                        {
                            "Utils"
                        },
                        {
                            {
                                24,
                                2,
                                {
                                    "Pagination"
                                }
                            },
                            {
                                13,
                                1,
                                {
                                    "Anticheats"
                                },
                                {
                                    {
                                        14,
                                        2,
                                        {
                                            "Main"
                                        }
                                    },
                                    {
                                        15,
                                        1,
                                        {
                                            "impl"
                                        },
                                        {
                                            {
                                                16,
                                                2,
                                                {
                                                    "Adonis"
                                                }
                                            }
                                        }
                                    }
                                }
                            },
                            {
                                22,
                                2,
                                {
                                    "Hooking"
                                }
                            },
                            {
                                26,
                                1,
                                {
                                    "Serializer"
                                },
                                {
                                    {
                                        27,
                                        2,
                                        {
                                            "LuaEncode"
                                        }
                                    }
                                }
                            },
                            {
                                28,
                                1,
                                {
                                    "UI"
                                },
                                {
                                    {
                                        31,
                                        2,
                                        {
                                            "Highlighter"
                                        }
                                    },
                                    {
                                        36,
                                        2,
                                        {
                                            "Sonner"
                                        }
                                    },
                                    {
                                        35,
                                        2,
                                        {
                                            "Resize"
                                        }
                                    },
                                    {
                                        34,
                                        2,
                                        {
                                            "Interface"
                                        }
                                    },
                                    {
                                        30,
                                        2,
                                        {
                                            "Helper"
                                        }
                                    },
                                    {
                                        33,
                                        2,
                                        {
                                            "ImageFetch"
                                        }
                                    },
                                    {
                                        29,
                                        2,
                                        {
                                            "Drag"
                                        }
                                    },
                                    {
                                        32,
                                        2,
                                        {
                                            "Icons"
                                        }
                                    }
                                }
                            },
                            {
                                25,
                                2,
                                {
                                    "SaveManager"
                                }
                            },
                            {
                                17,
                                1,
                                {
                                    "CodeGen"
                                },
                                {
                                    {
                                        18,
                                        2,
                                        {
                                            "Generator"
                                        }
                                    },
                                    {
                                        19,
                                        2,
                                        {
                                            "SessionExporter"
                                        }
                                    }
                                }
                            },
                            {
                                23,
                                2,
                                {
                                    "Log"
                                }
                            },
                            {
                                20,
                                2,
                                {
                                    "Connect"
                                }
                            },
                            {
                                21,
                                2,
                                {
                                    "FileLog"
                                }
                            }
                        }
                    },
                    {
                        3,
                        2,
                        {
                            "ExecutorSupport"
                        }
                    }
                }
            }
        }
    }
}

-- Line offsets for debugging (only included when minifyTables is false)
local LineOffsets = {
    [2] = 816,
    [3] = 1199,
    [4] = 656,
    [10] = 20,
    [34] = 208,
    [21] = 323,
    [20] = 458,
    [36] = 479,
    [32] = 760,
    [35] = 993,
    [33] = 1088,
    [22] = 1136,
    [29] = 1380,
    [24] = 1432,
    [16] = 6252,
    [11] = 1695,
    [37] = 1799,
    [14] = 6205,
    [19] = 5032,
    [31] = 5800,
    [23] = 5582,
    [25] = 5764,
    [18] = 5239,
    [9] = 1550,
    [30] = 5455,
    [27] = 5907
}

-- Misc AOT variable imports
local WaxVersion = "0.4.2"
local EnvName = "WaxRuntime"

-- ++++++++ RUNTIME IMPL BELOW ++++++++ --

-- Localizing certain libraries and built-ins for runtime efficiency
local string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, tostring, tonumber, _VERSION =
      string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, tostring, tonumber, _VERSION

local table_insert = table.insert
local table_remove = table.remove
local table_freeze = table.freeze or function(t) return t end -- lol

local coroutine_wrap = coroutine.wrap

local string_sub = string.sub
local string_match = string.match
local string_gmatch = string.gmatch

-- The Lune runtime has its own `task` impl, but it must be imported by its builtin
-- module path, "@lune/task"
if _VERSION and string_sub(_VERSION, 1, 4) == "Lune" then
    local RequireSuccess, LuneTaskLib = pcall(require, "@lune/task")
    if RequireSuccess and LuneTaskLib then
        task = LuneTaskLib
    end
end

local task_defer = task and task.defer

-- If we're not running on the Roblox engine, we won't have a `task` global
local Defer = task_defer or function(f, ...)
    coroutine_wrap(f)(...)
end

-- ClassName "IDs"
local ClassNameIdBindings = {
    [1] = "Folder",
    [2] = "ModuleScript",
    [3] = "Script",
    [4] = "LocalScript",
    [5] = "StringValue",
}

local RefBindings = {} -- [RefId] = RealObject

local ScriptClosures = {}
local ScriptClosureRefIds = {} -- [ScriptClosure] = RefId
local StoredModuleValues = {}
local ScriptsToRun = {}

-- wax.shared __index/__newindex
local SharedEnvironment = {}

-- We're creating 'fake' instance refs soley for traversal of the DOM for require() compatibility
-- It's meant to be as lazy as possible
local RefChildren = {} -- [Ref] = {ChildrenRef, ...}

-- Implemented instance methods
local InstanceMethods = {
    GetFullName = { {}, function(self)
        local Path = self.Name
        local ObjectPointer = self.Parent

        while ObjectPointer do
            Path = ObjectPointer.Name .. "." .. Path

            -- Move up the DOM (parent will be nil at the end, and this while loop will stop)
            ObjectPointer = ObjectPointer.Parent
        end

        return Path
    end},

    GetChildren = { {}, function(self)
        local ReturnArray = {}

        for Child in next, RefChildren[self] do
            table_insert(ReturnArray, Child)
        end

        return ReturnArray
    end},

    GetDescendants = { {}, function(self)
        local ReturnArray = {}

        for Child in next, RefChildren[self] do
            table_insert(ReturnArray, Child)

            for _, Descendant in next, Child:GetDescendants() do
                table_insert(ReturnArray, Descendant)
            end
        end

        return ReturnArray
    end},

    FindFirstChild = { {"string", "boolean?"}, function(self, name, recursive)
        local Children = RefChildren[self]

        for Child in next, Children do
            if Child.Name == name then
                return Child
            end
        end

        if recursive then
            for Child in next, Children do
                -- Yeah, Roblox follows this behavior- instead of searching the entire base of a
                -- ref first, the engine uses a direct recursive call
                return Child:FindFirstChild(name, true)
            end
        end
    end},

    FindFirstAncestor = { {"string"}, function(self, name)
        local RefPointer = self.Parent
        while RefPointer do
            if RefPointer.Name == name then
                return RefPointer
            end

            RefPointer = RefPointer.Parent
        end
    end},

    -- Just to implement for traversal usage
    WaitForChild = { {"string", "number?"}, function(self, name)
        return self:FindFirstChild(name)
    end},
}

-- "Proxies" to instance methods, with err checks etc
local InstanceMethodProxies = {}
for MethodName, MethodObject in next, InstanceMethods do
    local Types = MethodObject[1]
    local Method = MethodObject[2]

    local EvaluatedTypeInfo = {}
    for ArgIndex, TypeInfo in next, Types do
        local ExpectedType, IsOptional = string_match(TypeInfo, "^([^%?]+)(%??)")
        EvaluatedTypeInfo[ArgIndex] = {ExpectedType, IsOptional}
    end

    InstanceMethodProxies[MethodName] = function(self, ...)
        if not RefChildren[self] then
            error("Expected ':' not '.' calling member function " .. MethodName, 2)
        end

        local Args = {...}
        for ArgIndex, TypeInfo in next, EvaluatedTypeInfo do
            local RealArg = Args[ArgIndex]
            local RealArgType = type(RealArg)
            local ExpectedType, IsOptional = TypeInfo[1], TypeInfo[2]

            if RealArg == nil and not IsOptional then
                error("Argument " .. RealArg .. " missing or nil", 3)
            end

            if ExpectedType ~= "any" and RealArgType ~= ExpectedType and not (RealArgType == "nil" and IsOptional) then
                error("Argument " .. ArgIndex .. " expects type \"" .. ExpectedType .. "\", got \"" .. RealArgType .. "\"", 2)
            end
        end

        return Method(self, ...)
    end
end

local function CreateRef(className, name, parent)
    -- `name` and `parent` can also be set later by the init script if they're absent

    -- Extras
    local StringValue_Value

    -- Will be set to RefChildren later aswell
    local Children = setmetatable({}, {__mode = "k"})

    -- Err funcs
    local function InvalidMember(member)
        error(member .. " is not a valid (virtual) member of " .. className .. " \"" .. name .. "\"", 3)
    end
    local function ReadOnlyProperty(property)
        error("Unable to assign (virtual) property " .. property .. ". Property is read only", 3)
    end

    local Ref = {}
    local RefMetatable = {}

    RefMetatable.__metatable = false

    RefMetatable.__index = function(_, index)
        if index == "ClassName" then -- First check "properties"
            return className
        elseif index == "Name" then
            return name
        elseif index == "Parent" then
            return parent
        elseif className == "StringValue" and index == "Value" then
            -- Supporting StringValue.Value for Rojo .txt file conv
            return StringValue_Value
        else -- Lastly, check "methods"
            local InstanceMethod = InstanceMethodProxies[index]

            if InstanceMethod then
                return InstanceMethod
            end
        end

        -- Next we'll look thru child refs
        for Child in next, Children do
            if Child.Name == index then
                return Child
            end
        end

        -- At this point, no member was found; this is the same err format as Roblox
        InvalidMember(index)
    end

    RefMetatable.__newindex = function(_, index, value)
        -- __newindex is only for props fyi
        if index == "ClassName" then
            ReadOnlyProperty(index)
        elseif index == "Name" then
            name = value
        elseif index == "Parent" then
            -- We'll just ignore the process if it's trying to set itself
            if value == Ref then
                return
            end

            if parent ~= nil then
                -- Remove this ref from the CURRENT parent
                RefChildren[parent][Ref] = nil
            end

            parent = value

            if value ~= nil then
                -- And NOW we're setting the new parent
                RefChildren[value][Ref] = true
            end
        elseif className == "StringValue" and index == "Value" then
            -- Supporting StringValue.Value for Rojo .txt file conv
            StringValue_Value = value
        else
            -- Same err as __index when no member is found
            InvalidMember(index)
        end
    end

    RefMetatable.__tostring = function()
        return name
    end

    setmetatable(Ref, RefMetatable)

    RefChildren[Ref] = Children

    if parent ~= nil then
        RefChildren[parent][Ref] = true
    end

    return Ref
end

-- Create real ref DOM from object tree
local function CreateRefFromObject(object, parent)
    local RefId = object[1]
    local ClassNameId = object[2]
    local Properties = object[3] -- Optional
    local Children = object[4] -- Optional

    local ClassName = ClassNameIdBindings[ClassNameId]

    local Name = Properties and table_remove(Properties, 1) or ClassName

    local Ref = CreateRef(ClassName, Name, parent) -- 3rd arg may be nil if this is from root
    RefBindings[RefId] = Ref

    if Properties then
        for PropertyName, PropertyValue in next, Properties do
            Ref[PropertyName] = PropertyValue
        end
    end

    if Children then
        for _, ChildObject in next, Children do
            CreateRefFromObject(ChildObject, Ref)
        end
    end

    return Ref
end

local RealObjectRoot = CreateRef("Folder", "[" .. EnvName .. "]")
for _, Object in next, ObjectTree do
    CreateRefFromObject(Object, RealObjectRoot)
end

-- Now we'll set script closure refs and check if they should be ran as a BaseScript
for RefId, Closure in next, ClosureBindings do
    local Ref = RefBindings[RefId]

    ScriptClosures[Ref] = Closure
    ScriptClosureRefIds[Ref] = RefId

    local ClassName = Ref.ClassName
    if ClassName == "LocalScript" or ClassName == "Script" then
        table_insert(ScriptsToRun, Ref)
    end
end

local function LoadScript(scriptRef)
    local ScriptClassName = scriptRef.ClassName

    -- First we'll check for a cached module value (packed into a tbl)
    local StoredModuleValue = StoredModuleValues[scriptRef]
    if StoredModuleValue and ScriptClassName == "ModuleScript" then
        return unpack(StoredModuleValue)
    end

    local Closure = ScriptClosures[scriptRef]

    local function FormatError(originalErrorMessage)
        originalErrorMessage = tostring(originalErrorMessage)

        local VirtualFullName = scriptRef:GetFullName()

        -- Check for vanilla/Roblox format
        local OriginalErrorLine, BaseErrorMessage = string_match(originalErrorMessage, "[^:]+:(%d+): (.+)")

        if not OriginalErrorLine or not LineOffsets then
            return VirtualFullName .. ":*: " .. (BaseErrorMessage or originalErrorMessage)
        end

        OriginalErrorLine = tonumber(OriginalErrorLine)

        local RefId = ScriptClosureRefIds[scriptRef]
        local LineOffset = LineOffsets[RefId]

        local RealErrorLine = OriginalErrorLine - LineOffset + 1
        if RealErrorLine < 0 then
            RealErrorLine = "?"
        end

        return VirtualFullName .. ":" .. RealErrorLine .. ": " .. BaseErrorMessage
    end

    -- If it's a BaseScript, we'll just run it directly!
    if ScriptClassName == "LocalScript" or ScriptClassName == "Script" then
        local RunSuccess, ErrorMessage = pcall(Closure)
        if not RunSuccess then
            error(FormatError(ErrorMessage), 0)
        end
    else
        local PCallReturn = {pcall(Closure)}

        local RunSuccess = table_remove(PCallReturn, 1)
        if not RunSuccess then
            local ErrorMessage = table_remove(PCallReturn, 1)
            error(FormatError(ErrorMessage), 0)
        end

        StoredModuleValues[scriptRef] = PCallReturn
        return unpack(PCallReturn)
    end
end

-- We'll assign the actual func from the top of this output for flattening user globals at runtime
-- Returns (in a tuple order): wax, script, require
function ImportGlobals(refId)
    local ScriptRef = RefBindings[refId]

    local function RealCall(f, ...)
        local PCallReturn = {pcall(f, ...)}

        local CallSuccess = table_remove(PCallReturn, 1)
        if not CallSuccess then
            error(PCallReturn[1], 3)
        end

        return unpack(PCallReturn)
    end

    -- `wax.shared` index
    local WaxShared = table_freeze(setmetatable({}, {
        __index = SharedEnvironment,
        __newindex = function(_, index, value)
            SharedEnvironment[index] = value
        end,
        __len = function()
            return #SharedEnvironment
        end,
        __iter = function()
            return next, SharedEnvironment
        end,
    }))

    local Global_wax = table_freeze({
        -- From AOT variable imports
        version = WaxVersion,
        envname = EnvName,

        shared = WaxShared,

        -- "Real" globals instead of the env set ones
        script = script,
        require = require,
    })

    local Global_script = ScriptRef

    local function Global_require(module, ...)
        local ModuleArgType = type(module)

        local ErrorNonModuleScript = "Attempted to call require with a non-ModuleScript"
        local ErrorSelfRequire = "Attempted to call require with self"

        if ModuleArgType == "table" and RefChildren[module]  then
            if module.ClassName ~= "ModuleScript" then
                error(ErrorNonModuleScript, 2)
            elseif module == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(module)
        elseif ModuleArgType == "string" and string_sub(module, 1, 1) ~= "@" then
            -- The control flow on this SUCKS

            if #module == 0 then
                error("Attempted to call require with empty string", 2)
            end

            local CurrentRefPointer = ScriptRef

            if string_sub(module, 1, 1) == "/" then
                CurrentRefPointer = RealObjectRoot
            elseif string_sub(module, 1, 2) == "./" then
                module = string_sub(module, 3)
            end

            local PreviousPathMatch
            for PathMatch in string_gmatch(module, "([^/]*)/?") do
                local RealIndex = PathMatch
                if PathMatch == ".." then
                    RealIndex = "Parent"
                end

                -- Don't advance dir if it's just another "/" either
                if RealIndex ~= "" then
                    local ResultRef = CurrentRefPointer:FindFirstChild(RealIndex)
                    if not ResultRef then
                        local CurrentRefParent = CurrentRefPointer.Parent
                        if CurrentRefParent then
                            ResultRef = CurrentRefParent:FindFirstChild(RealIndex)
                        end
                    end

                    if ResultRef then
                        CurrentRefPointer = ResultRef
                    elseif PathMatch ~= PreviousPathMatch and PathMatch ~= "init" and PathMatch ~= "init.server" and PathMatch ~= "init.client" then
                        error("Virtual script path \"" .. module .. "\" not found", 2)
                    end
                end

                -- For possible checks next cycle
                PreviousPathMatch = PathMatch
            end

            if CurrentRefPointer.ClassName ~= "ModuleScript" then
                error(ErrorNonModuleScript, 2)
            elseif CurrentRefPointer == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(CurrentRefPointer)
        end

        return RealCall(require, module, ...)
    end

    -- Now, return flattened globals ready for direct runtime exec
    return Global_wax, Global_script, Global_require
end

for _, ScriptRef in next, ScriptsToRun do
    Defer(LoadScript, ScriptRef)
end
