--[=[
	@class SyncedTimeService
]=]

-- Nevermore Dependencies
local require = require(script.Parent.loader).load(script)
local Maid = require("Maid")
local Signal = require("Signal")

-- Roblox Services
local HTTPService = game:GetService("HttpService")

local SyncTimeService = {}
SyncTimeService.ServiceName = "SyncTimeService"

function SyncTimeService:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrService"))

	-- Internal
	self._serviceBag:GetService(require("SyncTimeServiceTranslator"))
end

function SyncTimeService:Start()
	print("Starting SyncTimeService")
end

return SyncTimeService