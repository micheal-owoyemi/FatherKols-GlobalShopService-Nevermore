--[=[
	@class GlobalShopService
]=]

-- Nevermore Dependencies
local require = require(script.Parent.loader).load(script)
local Maid = require("Maid")
local ObservableList = require("ObservableList")
local ObservableMap = require("ObservableMap")
local Signal = require("Signal")

-- Roblox Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Constants
local ItemDataBase = {
	Emote = {
		Common = { "EmoteC1", "EmoteC2", "EmoteC3","EmoteC4", "EnoteC5"},
		Rare = { "EmoteR1", "EmoteR2", "EmoteR3", "EmoteR4"},
		Legendary = {"EmoteL1", "EmoteL2", "EmoteL3"},
	},
	Accessory = {
		Common = { "AccessoryC1", "AccessoryC2", "AccessoryC3","AccessoryC4", "AccessoryC5"},
		Rare = { "AccessoryR1", "AccessoryR2", "AccessoryR3", "AccessoryR4"},
		Legendary = { "AccessoryL1", "AccessoryL2", "AccessoryL3"},
	},
}

-- Pack prices for refunds
local ITEM_PRICES = {
    CommonPack    = 100,
    RarePack      = 300,
    LegendaryPack = 1000
}

-- Service Functions
local GlobalShopService = {}
GlobalShopService.ServiceName = "GlobalShopService"

function GlobalShopService:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._maid = Maid.new()

	-- External
	self._serviceBag:GetService(require("CmdrService"))
	self._serviceBag:GetService(require("SyncTimeService"))

	-- Internal
	self._serviceBag:GetService(require("GlobalShopServiceTranslator"))

	-- Signals
	self.ItemAdded = Signal.new()      -- Fired when a new item is added to a player's inventory
	self.ItemDuplicate = Signal.new()  -- Fired when a duplicate item is encountered

	self._maid:GiveTask(self.ItemAdded)
	self._maid:GiveTask(self.ItemDuplicate)

	-- Observable lists
	self._currentShopItems = ObservableList.new()
	self._maid:GiveTask(self._currentShopItems)

	-- DataStores
	self._shopDataStore = DataStoreService:GetDataStore("GlobalShopState")      -- stores current shop rotation (items + timestamp)
	self._playerDataStore = DataStoreService:GetDataStore("PlayerInventories")  -- stores each player's inventory (keyed by userId)
 
	-- Maps
	self._playerInventories = {}  -- map of Player -> ObservableList (their inventory)
	self._playerMaids = {}        -- map of Player -> Maid (for cleaning up that player's connections)
end

function GlobalShopService:Start()
	print("Starting GlobalShopService")


	local dailySeed1 = 1
	local dailySeed2 = 2
	local dailySeed3 = 3

	print(self:_generateDailyItems(dailySeed1)._map)
	print(self:_generateDailyItems(dailySeed2)._map)
	print(self:_generateDailyItems(dailySeed3)._map)
end

function GlobalShopService:_generateDailyItems(daySeed: number)
    -- Create a seeded random number generator so that every server using the same daySeed produces identical results.
    local rng = Random.new(daySeed)
    -- Create a new ObservableMap instance.

    local itemsMap = ObservableMap.new()
    
    -- List of available item types.
    local types = { "Emote", "Accessory" }
    
    -- Helper function: Given a type and rarity, pick a random item from ItemDataBase.
    local function chooseItem(itemType: string, rarity: string)
        local pool = ItemDataBase[itemType] and ItemDataBase[itemType][rarity]
        if pool and #pool > 0 then
            return pool[rng:NextInteger(1, #pool)]
        end
        return nil
    end
    
    local index = 1

    -- Generate 3 Common items
    for i = 1, 3 do
        local typeIndex = rng:NextInteger(1, #types)
        local chosenType = types[typeIndex]
        local chosenItem = chooseItem(chosenType, "Common")
        itemsMap:Set(index, { Type = chosenType, Rarity = "Common", Item = chosenItem })
        index = index + 1
    end

    -- Generate 2 Rare items
    for i = 1, 2 do
        local typeIndex = rng:NextInteger(1, #types)
        local chosenType = types[typeIndex]
        local chosenItem = chooseItem(chosenType, "Rare")
        itemsMap:Set(index, { Type = chosenType, Rarity = "Rare", Item = chosenItem })
        index = index + 1
    end

    -- Generate 1 item: Rare or Legendary (25%)
    local chance = rng:NextNumber(0, 1)
    local finalRarity = (chance <= 0.25) and "Legendary" or "Rare"
    local typeIndex = rng:NextInteger(1, #types)
    local chosenType = types[typeIndex]
    local chosenItem = chooseItem(chosenType, finalRarity)
    itemsMap:Set(index, { Type = chosenType, Rarity = finalRarity, Item = chosenItem })

    return itemsMap
end




return GlobalShopService