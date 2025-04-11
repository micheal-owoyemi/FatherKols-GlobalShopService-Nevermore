--[=[
	@class SyncedTimeService
]=]

-- Nevermore Dependencies
local require = require(script.Parent.loader).load(script)
local Maid = require("Maid")
local Signal = require("Signal")

-- Roblox Services
local HTTPService = game:GetService("HttpService")

-- Constants
local monthStrMap = {
	Jan = 1,
	Feb = 2,
	Mar = 3,
	Apr = 4,
	May = 5,
	Jun = 6,
	Jul = 7,
	Aug = 8,
	Sep = 9,
	Oct = 10,
	Nov = 11,
	Dec = 12
}

-- Configuration: Set offset in hours from UTC (5 for CST)  
local HOUR_OFFSET = 5 -- CST  
local OFFSET_SECONDS = HOUR_OFFSET * 3600
-- For testing, fire cycle change every 30 seconds (instead of 12 hours)
local CYCLE_LENGTH = 30

-- Service Functions
local SyncTimeService = {}
SyncTimeService.ServiceName = "SyncTimeService"

function SyncTimeService:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._maid = Maid.new()

	-- Internal
	self._serviceBag:GetService(require("SyncTimeServiceTranslator"))

	-- Time variables
	self._originTime = nil
	self._responseTime = nil
	self._responseDelay = nil
	self._currentTime = nil
	self._currentCycle = nil
	self._active = false

	-- Signals
	self.CycleChanged = Signal.new()
	self._maid:GiveTask(self.CycleChanged)

	-- Initialize the current time
	self:_computeCurrentTimeAsync(function(currentTime)
		print("Time:", currentTime)
	end)
end

function SyncTimeService:Start()
	print("Starting SyncTimeService")

	self._active = true

	-- Asynchronous loop: checks every 1 second for cycle changes.
	task.spawn(function()
		while self._active do
			-- If currentTime isn't set yet, wait and try again.
			if not self._currentTime then
				task.wait(1)
				continue
			end

			self:_computeCurrentTimeAsync(function(currentTime)end)
			local currentCycle = self:_computeCurrentCycle()

			if currentCycle ~= self._currentCycle then
				self._currentCycle = currentCycle
				self.CycleChanged:Fire(currentCycle)
				print("[SyncTimeService] Cycle changed to:", currentCycle)
			end
			task.wait(1)
		end
	end)
end

-- Returns the current “cycle” value as an integer.
function SyncTimeService:GetCurrentCycle()
	return self._currentCycle
end

-- Internal: Computes the cycle value, taking into account the offset.
function SyncTimeService:_computeCurrentCycle()
	if not self._currentTime then return end
	return math.floor((self._currentTime + OFFSET_SECONDS) / CYCLE_LENGTH)
end

-- Grabs the current time from google.com and sets the current time to the server time
function SyncTimeService:_computeCurrentTimeAsync(callback)
	local wrapped = coroutine.wrap(function()
		local success = pcall(function()
			local requestTime = tick()
			local response = HTTPService:RequestAsync({ Url = "http://google.com" })
			local dateStr = response.Headers.date

			self._originTime = self:DateStringToUnixTimestamp(dateStr)
			self._responseTime = tick()
			self._responseDelay = (self._responseTime - requestTime) / 2
		end)

		if not success then
			warn("Cannot get time from google.com. Make sure that HTTP requests are enabled!")
			self._originTime = os.time()
			self._responseTime = tick()
			self._responseDelay = 0
		end

		-- Set the current time using the origin, tick, and response delay.
		self._currentTime = self._originTime + tick() - self._responseTime - self._responseDelay

		if callback then
			callback(self._currentTime)
		end
	end)
	wrapped()
end

-- Converts a date string from google.com to a unix timestamp
function SyncTimeService:DateStringToUnixTimestamp(dateStr : string)
	if not dateStr then return end
	local day, monthStr, year, hour, min, sec = dateStr:match(".*, (.*) (.*) (.*) (.*):(.*):(.*) .*")
	local month = monthStrMap[monthStr]
	local date = {
		day = day,
		month = month,
		year = year,
		hour = hour,
		min = min,
		sec = sec
	}
	return os.time(date)
end

function SyncTimeService:Destroy()
	self._active = false
	self._maid:DoCleaning()
end

return SyncTimeService