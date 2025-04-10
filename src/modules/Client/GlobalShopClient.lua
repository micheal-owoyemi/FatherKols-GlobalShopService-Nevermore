--[=[
	@class GlobalShopClient
]=]

local require = require(script.Parent.loader).load(script)
local Maid = require("Maid")
local ObservableList = require("ObservableList")

local GlobalShopClient = {}
GlobalShopClient.ServiceName = "GlobalShopClient"

function GlobalShopClient:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._maid = Maid.new()

	-- External
	self._serviceBag:GetService(require("CmdrServiceClient"))

	-- Internal
	self._serviceBag:GetService(require("GlobalShopServiceTranslator"))
end

function GlobalShopClient:Start()
	print("Starting GlobalShopClient")
end

return GlobalShopClient