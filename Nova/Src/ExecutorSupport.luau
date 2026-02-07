--[[
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
