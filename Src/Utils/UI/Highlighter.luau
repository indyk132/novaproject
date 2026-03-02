--[[
	Syntax Highlighter for Nova
	Luau syntax highlighter for code display with RichText.
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
	-- Executor globals
	["hookfunction"] = true, ["hookmetamethod"] = true, ["newcclosure"] = true,
	["checkcaller"] = true, ["getnamecallmethod"] = true, ["getcallingscript"] = true,
	["setclipboard"] = true, ["decompile"] = true, ["cloneref"] = true,
	["getconnections"] = true, ["getnilinstances"] = true, ["buffer"] = true,
	["Ray"] = true, ["NumberRange"] = true, ["Rect"] = true, ["NumberSequence"] = true,
	["ColorSequence"] = true, ["self"] = true,
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
	Boolean = Color3.fromRGB(209, 154, 102),
	Nil = Color3.fromRGB(209, 154, 102),
}

function Highlighter.Highlight(code: string): string
	-- Simple rich text syntax highlighting
	local result = code

	-- Escape rich text characters first
	result = result:gsub("&", "&amp;")
	result = result:gsub("<", "&lt;")
	result = result:gsub(">", "&gt;")

	-- Block comments
	result = result:gsub("(%-%-%[%[.-%]%])", function(match)
		return `<font color="#{Colors.Comment:ToHex()}">{match}</font>`
	end)

	-- Comments (single line)
	result = result:gsub("(%-%-[^\n]*)", function(match)
		-- Don't re-highlight if already in a font tag
		if match:find("<font") then return match end
		return `<font color="#{Colors.Comment:ToHex()}">{match}</font>`
	end)

	-- Multi-line strings
	result = result:gsub("(%[%[.-%]%])", function(match)
		if match:find("<font") then return match end
		return `<font color="#{Colors.String:ToHex()}">{match}</font>`
	end)

	-- Strings (double quoted)
	result = result:gsub('(".-")', function(match)
		if match:find("<font") then return match end
		return `<font color="#{Colors.String:ToHex()}">{match}</font>`
	end)

	-- Strings (single quoted)
	result = result:gsub("('.-')", function(match)
		if match:find("<font") then return match end
		return `<font color="#{Colors.String:ToHex()}">{match}</font>`
	end)

	-- Numbers (including hex)
	result = result:gsub("(0x%x+)", function(match)
		return `<font color="#{Colors.Number:ToHex()}">{match}</font>`
	end)
	result = result:gsub("(%d+%.?%d*)", function(match)
		return `<font color="#{Colors.Number:ToHex()}">{match}</font>`
	end)

	-- Keywords
	for keyword in pairs(Keywords) do
		result = result:gsub("(%f[%w_])" .. keyword .. "(%f[^%w_])", function(pre, post)
			return `{pre}<font color="#{Colors.Keyword:ToHex()}">{keyword}</font>{post}`
		end)
	end

	-- Methods (after colon or dot)
	result = result:gsub("([%.:])(%w+)(%s*%()", function(sep, name, paren)
		return `{sep}<font color="#{Colors.Method:ToHex()}">{name}</font>{paren}`
	end)

	return result
end

-- Get argument value color based on type
function Highlighter.GetArgumentColor(value): Color3
	local t = typeof(value)
	if t == "string" then
		return Colors.String
	elseif t == "number" then
		return Colors.Number
	elseif t == "boolean" then
		return Colors.Boolean
	elseif t == "nil" then
		return Colors.Nil
	elseif t == "EnumItem" or t == "Enum" then
		return Colors.Method
	elseif t == "Instance" then
		return Colors.Global
	elseif t == "Vector3" or t == "Vector2" or t == "CFrame" or t == "UDim2" or t == "UDim" or t == "Color3" or t == "BrickColor" then
		return Colors.Number
	elseif t == "function" then
		return Colors.Keyword
	elseif t == "table" then
		return Colors.Default
	elseif t == "buffer" then
		return Colors.Method
	else
		return Colors.Default
	end
end

Highlighter.Colors = Colors

return Highlighter
