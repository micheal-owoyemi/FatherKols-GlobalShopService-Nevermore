--[[
	@class ClientMain
]]
local loader = game:GetService("ReplicatedStorage"):WaitForChild("FatherKolsGlobalShopServiceNevermore"):WaitForChild("loader")
local require = require(loader).bootstrapGame(loader.Parent)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("FatherKolsGlobalShopServiceNevermoreServiceClient"))
serviceBag:Init()
serviceBag:Start()