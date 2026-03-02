--[[
	Hooking Utility Module for Nova
	Provides function hooking, namecall hooking and restoration.
	Includes safe closure wrapping to match C/Lua closure types.
]]

local Hooking = {}

local OriginalFunctions = {}
local OriginalNamecall = nil
local HookedMetamethods = {}

-- Check if a function is a C closure
local function IsCClosure(func)
	if typeof(iscclosure) == "function" then
		local ok, result = pcall(iscclosure, func)
		return ok and result
	end
	return false
end

-- Wrap a hook to match the closure type of the original function
local function WrapClosure(hook)
	if typeof(newcclosure) == "function" then
		local ok, wrapped = pcall(newcclosure, hook)
		if ok then
			return wrapped
		end
	end
	return hook
end

function Hooking.HookFunction(original, hook)
	if not hookfunction then
		return nil
	end

	-- Match closure type: if original is C closure, wrap hook as C closure
	local wrappedHook = hook
	if IsCClosure(original) then
		wrappedHook = WrapClosure(hook)
	end

	local ok, oldFunc = pcall(hookfunction, original, wrappedHook)
	if ok then
		OriginalFunctions[original] = oldFunc
		return oldFunc
	end
	return nil
end

function Hooking.RestoreFunction(original)
	local oldFunc = OriginalFunctions[original]
	if oldFunc and hookfunction then
		pcall(hookfunction, original, oldFunc)
		OriginalFunctions[original] = nil
	end
end

function Hooking.HookMetamethod(object, metamethod, hook)
	if not hookmetamethod then
		return nil
	end

	local wrappedHook = WrapClosure(hook)
	local ok, oldMethod = pcall(hookmetamethod, object, metamethod, wrappedHook)
	if ok then
		local key = tostring(object) .. metamethod
		HookedMetamethods[key] = { Object = object, Metamethod = metamethod, Original = oldMethod }
		return oldMethod
	end
	return nil
end

function Hooking.RestoreMetamethod(object, metamethod)
	local key = tostring(object) .. metamethod
	local data = HookedMetamethods[key]
	if data and data.Original and hookmetamethod then
		pcall(hookmetamethod, object, metamethod, data.Original)
		HookedMetamethods[key] = nil
	end
end

function Hooking.SetNamecallHook(hook)
	if not hookmetamethod then
		return nil
	end

	local wrappedHook = WrapClosure(hook)
	local ok, oldNamecall = pcall(hookmetamethod, game, "__namecall", wrappedHook)
	if ok then
		OriginalNamecall = oldNamecall
		wax.shared.NamecallHook = oldNamecall
		return oldNamecall
	end
	return nil
end

function Hooking.RestoreNamecall()
	if OriginalNamecall and hookmetamethod then
		pcall(hookmetamethod, game, "__namecall", OriginalNamecall)
		OriginalNamecall = nil
		wax.shared.NamecallHook = nil
	end
end

function Hooking.RestoreAll()
	-- Restore all function hooks
	for original, oldFunc in pairs(OriginalFunctions) do
		if hookfunction then
			pcall(hookfunction, original, oldFunc)
		end
	end
	table.clear(OriginalFunctions)

	-- Restore all metamethod hooks
	for key, data in pairs(HookedMetamethods) do
		if hookmetamethod and data.Original then
			pcall(hookmetamethod, data.Object, data.Metamethod, data.Original)
		end
	end
	table.clear(HookedMetamethods)

	-- Restore namecall
	Hooking.RestoreNamecall()
end

function Hooking.GetOriginal(original)
	return OriginalFunctions[original]
end

function Hooking.GetHookCount()
	local count = 0
	for _ in pairs(OriginalFunctions) do count += 1 end
	for _ in pairs(HookedMetamethods) do count += 1 end
	if OriginalNamecall then count += 1 end
	return count
end

return Hooking
