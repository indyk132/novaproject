--[[
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
