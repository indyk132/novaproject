--[[
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
