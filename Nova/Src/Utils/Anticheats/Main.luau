--[[
	Anticheat Detection & Bypass Module for Nova
]]

local AnticheatMain = {
	Name = nil,
	Detected = false,
	Disabled = false,
	Bypass = nil,
}

-- Try to detect known anticheats
local function DetectAnticheats()
	-- Adonis detection
	local adonisSuccess, adonisResult = pcall(function()
		local adonisFolder = game:GetService("ReplicatedStorage"):FindFirstChild("_Adonis")
			or game:GetService("ServerScriptService"):FindFirstChild("Adonis_Loader")
		return adonisFolder ~= nil
	end)

	if adonisSuccess and adonisResult then
		AnticheatMain.Name = "Adonis"
		AnticheatMain.Detected = true
		AnticheatMain.Bypass = require(script.impl.Adonis)
		return
	end

	-- Generic detection for common anticheat patterns
	local genericSuccess, genericResult = pcall(function()
		local antiExploit = game:GetService("ReplicatedStorage"):FindFirstChild("AntiExploit")
			or game:GetService("ReplicatedStorage"):FindFirstChild("Anti-Exploit")
			or game:GetService("ReplicatedStorage"):FindFirstChild("AntiCheat")
		return antiExploit ~= nil
	end)

	if genericSuccess and genericResult then
		AnticheatMain.Name = "Generic AntiExploit"
		AnticheatMain.Detected = true
		return
	end
end

pcall(DetectAnticheats)

return AnticheatMain
