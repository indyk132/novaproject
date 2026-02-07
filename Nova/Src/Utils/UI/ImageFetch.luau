--[[
	Image Fetcher for Nova
	Handles fetching and caching images for UI elements.
]]

local ImageFetch = {}

local Cache = {}

local RemoteImages = {
	RemoteEvent = "rbxassetid://4229806545",
	RemoteFunction = "rbxassetid://4229806870",
	UnreliableRemoteEvent = "rbxassetid://4229806545",
	BindableEvent = "rbxassetid://4229806545",
	BindableFunction = "rbxassetid://4229806870",
}

function ImageFetch.GetRemoteImage(className: string): string
	return RemoteImages[className] or "rbxassetid://4229806545"
end

function ImageFetch.Preload(imageIds: { string })
	if wax.shared.ContentProvider then
		local instances = {}
		for _, id in ipairs(imageIds) do
			if not Cache[id] then
				local img = Instance.new("ImageLabel")
				img.Image = id
				table.insert(instances, img)
				Cache[id] = true
			end
		end

		if #instances > 0 then
			pcall(function()
				wax.shared.ContentProvider:PreloadAsync(instances)
			end)
		end

		for _, img in ipairs(instances) do
			img:Destroy()
		end
	end
end

return ImageFetch
