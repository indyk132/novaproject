-- Logger
-- File logging utility for Nova

--[=[
    A simple logging utility that writes messages to a file. Supports different log levels
    and can be configured to overwrite or append to the log file.

    Log Format:  2024-12-04T15:28:31.131Z,0.131060,MyThread,Warning [FLog::NovaLogger] Message
                 <timestamp>,<elapsed_time>,<thread_id>,<level> <message>
]=]

local Logger = {}
Logger.__index = Logger

Logger.LOG_LEVELS = {
	ERROR = 1,
	WARNING = 2,
	INFO = 3,
	DEBUG = 4,
}

local LOG_LEVEL_STRINGS = {
	[Logger.LOG_LEVELS.ERROR] = "ERROR",
	[Logger.LOG_LEVELS.WARNING] = "WARNING",
	[Logger.LOG_LEVELS.INFO] = "INFO",
	[Logger.LOG_LEVELS.DEBUG] = "DEBUG",
}

local startTime = tick()

local function createDirectoryRecursive(path)
	local currentPath = ""
	for segment in string.gmatch(path, "[^/]+") do
		currentPath = currentPath .. (currentPath == "" and "" or "/") .. segment
		if not isfolder(currentPath) then
			pcall(makefolder, currentPath)
		end
	end
end

function Logger.new(filePath: string, logLevel: number?, overwrite: boolean?)
	logLevel = logLevel or Logger.LOG_LEVELS.INFO
	overwrite = if overwrite == nil then false else overwrite

	-- Ensure directory exists
	local dir = string.match(filePath, "(.+)/[^/]+$")
	if dir then
		createDirectoryRecursive(dir)
	end

	-- Initialize or overwrite
	if overwrite or not isfile(filePath) then
		writefile(filePath, "")
	end

	local self = setmetatable({
		FilePath = filePath,
		LogLevel = logLevel,
		Buffer = {},
		BufferSize = 0,
		MaxBufferSize = 10,
		LastFlush = tick(),
		FlushInterval = 2,
	}, Logger)

	-- Auto-flush periodically
	task.spawn(function()
		while not wax.shared.Unloaded do
			task.wait(self.FlushInterval)
			if self.BufferSize > 0 then
				self:Flush()
			end
		end
		-- Final flush on unload
		if self.BufferSize > 0 then
			self:Flush()
		end
	end)

	return self
end

function Logger:Flush()
	if self.BufferSize == 0 then
		return
	end

	local content = table.concat(self.Buffer, "\n") .. "\n"
	pcall(function()
		appendfile(self.FilePath, content)
	end)

	self.Buffer = {}
	self.BufferSize = 0
	self.LastFlush = tick()
end

function Logger:Log(level: number, message: string)
	if level > self.LogLevel then
		return
	end

	local elapsed = string.format("%.6f", tick() - startTime)
	local timestamp = DateTime.now():ToIsoDate()
	local levelStr = LOG_LEVEL_STRINGS[level] or "UNKNOWN"

	local entry = `{timestamp},{elapsed},{levelStr} {message}`

	self.BufferSize += 1
	self.Buffer[self.BufferSize] = entry

	if self.BufferSize >= self.MaxBufferSize then
		self:Flush()
	end
end

function Logger:Info(message: string)
	self:Log(Logger.LOG_LEVELS.INFO, message)
end

function Logger:Warning(message: string)
	self:Log(Logger.LOG_LEVELS.WARNING, message)
end

function Logger:Error(message: string)
	self:Log(Logger.LOG_LEVELS.ERROR, message)
end

function Logger:Debug(message: string)
	self:Log(Logger.LOG_LEVELS.DEBUG, message)
end

return Logger
