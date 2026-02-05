-- LuaEncode - Optimal Table Serialization for Native Luau/Lua 5.1+
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
