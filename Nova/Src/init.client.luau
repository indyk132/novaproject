wax.shared.NovaStartTime = tick()

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
