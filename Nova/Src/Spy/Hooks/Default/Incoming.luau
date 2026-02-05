--[[
	Nova - Incoming Remote Hooks
	Hooks OnClientEvent connections to monitor incoming remote calls.
]]

local Log = require(script.Parent.Parent.Parent.Utils.Log)

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
