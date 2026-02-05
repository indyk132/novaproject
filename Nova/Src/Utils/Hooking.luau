--[[
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
