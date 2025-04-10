--[=[
	@class GlobalShopService
]=]

local require = require(script.Parent.loader).load(script)
local Maid = require("Maid")

local GlobalShopService = {}
GlobalShopService.ServiceName = "GlobalShopService"

function GlobalShopService:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrService"))

	-- Internal
	self._serviceBag:GetService(require("GlobalShopServiceTranslator"))
end

function GlobalShopService:Start()
	print("Starting GlobalShopService")
end

return GlobalShopService