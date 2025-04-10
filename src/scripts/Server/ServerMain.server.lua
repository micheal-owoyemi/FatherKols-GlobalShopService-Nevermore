--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.FatherKolsGlobalShopServiceNevermore:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.FatherKolsGlobalShopServiceNevermore)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("FatherKolsGlobalShopServiceNevermoreService"))
serviceBag:Init()
serviceBag:Start()