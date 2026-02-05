--[[
	Pagination Module
	Handles pagination logic for log entries.
]]

local Pagination = {}
Pagination.__index = Pagination

function Pagination.new(Options: {
	TotalItems: number,
	ItemsPerPage: number,
	CurrentPage: number?,
	SiblingCount: number?,
})
	return setmetatable({
		TotalItems = Options.TotalItems,
		ItemsPerPage = Options.ItemsPerPage,
		CurrentPage = Options.CurrentPage or 1,
		SiblingCount = Options.SiblingCount or 2,
	}, Pagination)
end

function Pagination:GetInfo()
	local TotalPages = math.ceil(self.TotalItems / self.ItemsPerPage)

	return {
		TotalItems = self.TotalItems,
		ItemsPerPage = self.ItemsPerPage,
		CurrentPage = self.CurrentPage,
		TotalPages = TotalPages,
	}
end

function Pagination:SetItemsPerPage(max: number)
	self.ItemsPerPage = max
end

function Pagination:GetIndexRanges(Page: number?)
	Page = Page or self.CurrentPage

	local TotalPages = math.ceil(self.TotalItems / self.ItemsPerPage)
	if TotalPages == 0 then
		return 1, 0
	end

	assert(Page >= 1 and Page <= TotalPages, `Page {Page} is out of range (1 - {TotalPages})`)

	local StartIndex = (Page - 1) * self.ItemsPerPage + 1
	local EndIndex = math.min(StartIndex + self.ItemsPerPage - 1, self.TotalItems)

	return StartIndex, EndIndex
end

function Pagination:GetPages()
	local TotalPages = math.ceil(self.TotalItems / self.ItemsPerPage)
	local CurrentPage = self.CurrentPage
	local SiblingCount = self.SiblingCount

	local Pages = {}

	local LeftSibling = math.max(CurrentPage - SiblingCount, 1)
	local RightSibling = math.min(CurrentPage + SiblingCount, TotalPages)

	local ShowLeftDots = LeftSibling > 2
	local ShowRightDots = RightSibling < TotalPages - 1

	if not ShowLeftDots and ShowRightDots then
		local LeftCount = 3 + 2 * SiblingCount
		for i = 1, math.min(LeftCount, TotalPages) do
			table.insert(Pages, i)
		end
		table.insert(Pages, "...")
		table.insert(Pages, TotalPages)
	elseif ShowLeftDots and not ShowRightDots then
		table.insert(Pages, 1)
		table.insert(Pages, "...")
		local RightCount = 3 + 2 * SiblingCount
		for i = math.max(TotalPages - RightCount + 1, 1), TotalPages do
			table.insert(Pages, i)
		end
	elseif ShowLeftDots and ShowRightDots then
		table.insert(Pages, 1)
		table.insert(Pages, "...")
		for i = LeftSibling, RightSibling do
			table.insert(Pages, i)
		end
		table.insert(Pages, "...")
		table.insert(Pages, TotalPages)
	else
		for i = 1, TotalPages do
			table.insert(Pages, i)
		end
	end

	return Pages
end

function Pagination:Update(totalItems: number)
	self.TotalItems = totalItems
end

function Pagination:SetPage(page: number)
	local TotalPages = math.ceil(self.TotalItems / self.ItemsPerPage)
	self.CurrentPage = math.clamp(page, 1, math.max(TotalPages, 1))
end

function Pagination:NextPage()
	local TotalPages = math.ceil(self.TotalItems / self.ItemsPerPage)
	self:SetPage(math.min(self.CurrentPage + 1, TotalPages))
end

function Pagination:PreviousPage()
	self:SetPage(math.max(self.CurrentPage - 1, 1))
end

return Pagination
