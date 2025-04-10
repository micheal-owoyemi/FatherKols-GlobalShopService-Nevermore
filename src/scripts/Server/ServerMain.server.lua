--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.FatherKolsGlobalShopServiceNevermore:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.FatherKolsGlobalShopServiceNevermore)

local serviceBag = require("ServiceBag").new()

-- Get Services
serviceBag:GetService(require("GlobalShopService"))
serviceBag:GetService(require("SyncTimeService"))

serviceBag:Init()
serviceBag:Start()