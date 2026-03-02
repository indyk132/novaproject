--[[
	Code Generation Module for Nova
	Generates Lua code snippets for remote calls.
	Features: smart value detection (GUID, timestamps, buffers), clean output.
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

-- Smart value serialization for code generation
function CodeGen.SmartSerializeValue(value, indent, visited)
	indent = indent or 1
	visited = visited or {}

	local t = typeof(value)

	if t == "nil" then
		return "nil"
	elseif t == "boolean" then
		return tostring(value)
	elseif t == "number" then
		if value ~= value then
			return "0/0 --[[NaN]]"
		elseif value == math.huge then
			return "math.huge"
		elseif value == -math.huge then
			return "-math.huge"
		end
		-- Detect tick() / os.time() / os.clock() patterns
		local now = tick()
		if value > 1e9 and value < 1e11 then
			-- Unix timestamp range - likely tick() or os.time()
			if math.abs(value - now) < 300 then
				return "tick()"
			elseif math.abs(value - os.time()) < 300 then
				return "os.time()"
			end
		elseif value > 0 and value < 1e6 and value == math.floor(value * 1000) / 1000 then
			-- Could be os.clock() range
			local clock = os.clock()
			if math.abs(value - clock) < 60 then
				return "os.clock()"
			end
		end
		return tostring(value)
	elseif t == "string" then
		-- Detect GUID pattern
		if string.match(value, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then
			return 'game:GetService("HttpService"):GenerateGUID(false)'
		end
		return CodeGen.FormatLuaString(value)
	elseif t == "Instance" then
		return CodeGen.GetFullPath(value, { VariableName = nil, Inline = true })
	elseif t == "Vector3" then
		return `Vector3.new({value.X}, {value.Y}, {value.Z})`
	elseif t == "Vector2" then
		return `Vector2.new({value.X}, {value.Y})`
	elseif t == "CFrame" then
		local components = { value:GetComponents() }
		local strs = {}
		for _, c in ipairs(components) do
			table.insert(strs, tostring(c))
		end
		return `CFrame.new({table.concat(strs, ", ")})`
	elseif t == "Color3" then
		return `Color3.new({value.R}, {value.G}, {value.B})`
	elseif t == "BrickColor" then
		return `BrickColor.new("{tostring(value)}")`
	elseif t == "UDim2" then
		return `UDim2.new({value.X.Scale}, {value.X.Offset}, {value.Y.Scale}, {value.Y.Offset})`
	elseif t == "UDim" then
		return `UDim.new({value.Scale}, {value.Offset})`
	elseif t == "EnumItem" then
		return tostring(value)
	elseif t == "Ray" then
		return `Ray.new(Vector3.new({value.Origin.X}, {value.Origin.Y}, {value.Origin.Z}), Vector3.new({value.Direction.X}, {value.Direction.Y}, {value.Direction.Z}))`
	elseif t == "NumberRange" then
		return `NumberRange.new({value.Min}, {value.Max})`
	elseif t == "Rect" then
		return `Rect.new({value.Min.X}, {value.Min.Y}, {value.Max.X}, {value.Max.Y})`
	elseif t == "buffer" then
		local size = buffer.len(value)
		if size == 0 then
			return 'buffer.create(0)'
		end
		-- For small buffers, serialize bytes
		if size <= 32 then
			local bytes = {}
			for i = 0, size - 1 do
				table.insert(bytes, string.format("\\x%02X", buffer.readu8(value, i)))
			end
			return `buffer.fromstring("{table.concat(bytes)}")`
		end
		return `buffer.create({size}) --[[{size} bytes]]`
	elseif t == "function" then
		return "function() end --[[function]]"
	elseif t == "table" then
		if visited[value] then
			return "{} --[[circular reference]]"
		end
		visited[value] = true

		local entries = {}
		local isArray = true
		local count = 0

		-- Check if it's a pure array
		for k in pairs(value) do
			count += 1
			if type(k) ~= "number" or k ~= count then
				isArray = false
			end
			if count > 200 then break end
		end

		local tabs = string.rep("\t", indent)
		local tabsInner = string.rep("\t", indent + 1)

		if count == 0 then
			return "{}"
		end

		if isArray and count <= 200 then
			for i = 1, count do
				table.insert(entries, `{tabsInner}{CodeGen.SmartSerializeValue(value[i], indent + 1, visited)}`)
			end
		else
			local idx = 0
			for k, v in pairs(value) do
				idx += 1
				if idx > 200 then
					table.insert(entries, `{tabsInner}-- ... {count - 200} more entries`)
					break
				end
				local keyStr
				if type(k) == "string" and string.match(k, "^[%a_][%w_]*$") then
					keyStr = k
				else
					keyStr = `[{CodeGen.SmartSerializeValue(k, indent + 1, visited)}]`
				end
				table.insert(entries, `{tabsInner}{keyStr} = {CodeGen.SmartSerializeValue(v, indent + 1, visited)}`)
			end
		end

		visited[value] = nil
		return `\{\n{table.concat(entries, ",\n")}\n{tabs}}`
	else
		return `nil --[[{t}: {tostring(value)}]]`
	end
end

function CodeGen.GetFullPath(instance, options)
	options = options or {}
	local VariableName = options.VariableName or "Remote"
	local DisableNilParentHandler = options.DisableNilParentHandler or false
	local Inline = options.Inline or false
	local UseMethod = wax.shared.SaveManager:GetState("PathMethod", "Index")

	if not instance then
		if Inline then
			return "nil --[[Instance not found]]"
		end
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
		if Inline then
			return `GetNil("{instance.Name}", "{debugId}")`
		end
		return `{GetNilCode}\n\nlocal {VariableName} = GetNil("{instance.Name}", "{debugId}")`
	end

	local code = ""
	local service = path[1]

	if service and service.Parent == game then
		code = `game:GetService("{service.ClassName}")`

		for i = 2, #path do
			local child = path[i]
			local name = child.Name

			-- Check for duplicate siblings with same name
			local hasDuplicate = false
			if child.Parent then
				local siblings = child.Parent:GetChildren()
				for _, sibling in ipairs(siblings) do
					if sibling ~= child and sibling.Name == name then
						hasDuplicate = true
						break
					end
				end
			end

			if UseMethod == "FindFirstChild" then
				if hasDuplicate then
					code ..= `:FindFirstChild("{name}", true)`
				else
					code ..= `:FindFirstChild("{name}")`
				end
			elseif UseMethod == "WaitForChild" then
				code ..= `:WaitForChild("{name}")`
			else
				-- Index method
				if string.match(name, "^[%a_][%w_]*$") and not hasDuplicate then
					code ..= `.{name}`
				else
					code ..= `["{name}"]`
				end
			end
		end
	else
		code = `workspace -- Could not resolve path for {instance.Name}`
	end

	if Inline then
		return code
	end
	return `local {VariableName} = {code}`
end

function CodeGen.GenerateCode(logEntry, callInfo, options)
	options = options or {}
	local ShowWatermark = wax.shared.SaveManager:GetState("ShowWatermark", true)
	local UseSmartSerializer = wax.shared.SaveManager:GetState("UseSmartSerializer", true)

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
			if UseSmartSerializer then
				-- Use our smart serializer
				local argEntries = {}
				for _, arg in ipairs(args) do
					table.insert(argEntries, `\t{CodeGen.SmartSerializeValue(arg, 1)}`)
				end
				local argsCode = `local Args = \{\n{table.concat(argEntries, ",\n")}\n}`
				table.insert(lines, argsCode)
				table.insert(lines, "")
				table.insert(lines, `Remote:{method}(unpack(Args))`)
			else
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
		elseif className == "BindableEvent" then
			table.insert(lines, [[local OldFire = Remote.Fire
Remote.Fire = function(self, ...)
	-- Modify args here
	return OldFire(self, ...)
end]])
		elseif className == "BindableFunction" then
			table.insert(lines, [[local OldInvoke = Remote.Invoke
Remote.Invoke = function(self, ...)
	-- Modify args or return value here
	return OldInvoke(self, ...)
end]])
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
