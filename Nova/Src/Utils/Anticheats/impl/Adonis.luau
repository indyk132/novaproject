--[[
	Adonis Anticheat Bypass for Nova
]]

local function BypassAdonis()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local AdonisFolder = ReplicatedStorage:FindFirstChild("_Adonis")
	if not AdonisFolder then
		return false
	end

	-- Find and disable detection remotes
	local function DisableDetectionFunctions(parent)
		for _, child in pairs(parent:GetDescendants()) do
			if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
				local name = child.Name:lower()
				if name:find("detect") or name:find("kick") or name:find("ban") or name:find("exploit") then
					-- Hook the remote to prevent it from doing anything
					if child:IsA("RemoteFunction") and child.OnClientInvoke then
						local DetectionFunc = child.OnClientInvoke
						if typeof(DetectionFunc) == "function" then
							wax.shared.Hooks[DetectionFunc] = wax.shared.Hooking.HookFunction(
								DetectionFunc,
								function(action, info, nocrash)
									coroutine.yield(coroutine.running())
									return task.wait(9e9)
								end
							)
						end
					end
				end
			end
		end
	end

	pcall(DisableDetectionFunctions, AdonisFolder)

	-- Hook getconnections to hide our connections
	if getconnections then
		for _, connection in pairs(getconnections(game:GetService("Players").LocalPlayer.Idled)) do
			-- Keep connections alive but hidden
		end
	end

	return true
end

return BypassAdonis
