--[=[
	@class SyncedTimeService
]=]

-- Nevermore Dependencies
local require = require(script.Parent.loader).load(script)
local Maid = require("Maid")
local ObservableList = require("ObservableList")

-- Roblox Services
local HTTPService = game:GetService("HttpService")

local SyncedTimeService = {}
SyncedTimeService.ServiceName = "SyncedTimeService"

function SyncedTimeService:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrService"))

	-- Internal
	self._serviceBag:GetService(require("SyncedTimeServiceTranslator"))
end

function SyncedTimeService:Start()
	print("Starting SyncedTimeService")
end

return SyncedTimeService