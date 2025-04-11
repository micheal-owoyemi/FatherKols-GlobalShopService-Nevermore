--[=[
	@class GlobalShopService
]=]

-- Nevermore Dependencies
local require = require(script.Parent.loader).load(script)
local Maid = require("Maid")
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

-- Item Prices
local ITEM_PRICES = {
    Common = 100,
    Rare = 300,
    Legendary = 1000
}



-- Service Functions
local GlobalShopService = {}
GlobalShopService.ServiceName = "GlobalShopService"

function GlobalShopService:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._maid = Maid.new()

	-- External
	self._syncTimeService = self._serviceBag:GetService(require("SyncTimeService"))

	-- Internal
	self._serviceBag:GetService(require("GlobalShopServiceTranslator"))

	-- Signals
	self.ShopUpdated = Signal.new()      -- Fired when the shop is updated
	self._maid:GiveTask(self.ShopUpdated)

	-- DataStores
	self._shopDataStore = DataStoreService:GetDataStore("GlobalShopState")      -- stores current shop rotation (items + timestamp)
	self._playerDataStore = DataStoreService:GetDataStore("PlayerInventories")  -- stores each player's inventory (keyed by userId)

	-- Constants
	self._currentShopItems = {}

end

function GlobalShopService:Start()
    -- Run the cycle retrieval and refresh asynchronously
    task.spawn(function()
        local currentCycle = self._syncTimeService:GetCurrentCycle()
        local delayTime = 1
        local maxDelay = 16

        while currentCycle == nil do
            print("[GlobalShopService] Current cycle is nil, retrying in", delayTime, "seconds...")
            task.wait(delayTime)
            currentCycle = self._syncTimeService:GetCurrentCycle()
            delayTime = math.min(delayTime * 2, maxDelay)
        end

        -- Once we have a valid cycle, immediately refresh the shop
        self:_generateDailyItems(currentCycle)
		print("[GlobalShopService] Current cycle is", currentCycle)
		print(self._currentShopItems._map)
    end)

	-- Listen for cycle changes and refresh the shop accordingly (In this case, every 12 hours)
	self._maid:GiveTask(self._syncTimeService.CycleChanged:Connect(function(newCycle)
		self:_generateDailyItems(newCycle)
		print("[GlobalShopService] Cycle changed to", newCycle)
		print(self._currentShopItems._map)
	end))
end

function GlobalShopService:_generateDailyItems(cycleSeed: number) -- 6 item count hard-coded
    local rng = Random.new(cycleSeed)
    local itemsMap = ObservableMap.new()
    local types = { "Emote", "Accessory" }
    
    -- Helper Functions

	--Copy the pool and return a new list
    local function copyPool(pool)
        local copy = {}
        for i, item in (pool) do
            table.insert(copy, item)
        end
        return copy
    end

    --[[ Helper: Given a type and rarity, pick a random item from a temporary pool
	and remove it from that pool to prevent re-selection]]
	local function chooseItemFromPool(pool)
		if pool and #pool > 0 then
			local index = rng:NextInteger(1, #pool)
			local chosenItem = pool[index]
			table.remove(pool, index)  -- Remove the chosen item so it cannot be selected again.
			return chosenItem
		end
		return nil
	end
    
    local index = 1

    -- For each type, create temporary copies of the rarity pools.
    local commonPools = {}
    local rarePools = {}
    local legendaryPools = {}

    for _, itemType in (types) do
        commonPools[itemType] = copyPool(ItemDataBase[itemType].Common)
        rarePools[itemType] = copyPool(ItemDataBase[itemType].Rare)
        legendaryPools[itemType] = copyPool(ItemDataBase[itemType].Legendary)
    end

    -- Generate 3 Common items
    for i = 1, 3 do
        local typeIndex = rng:NextInteger(1, #types)
        local chosenType = types[typeIndex]
        local chosenItem = chooseItemFromPool(commonPools[chosenType])
        if chosenItem then
            itemsMap:Set(index, { Type = chosenType, Rarity = "Common", Item = chosenItem })
            index = index + 1
        end
    end

    -- Generate 2 Rare items
    for i = 1, 2 do
        local typeIndex = rng:NextInteger(1, #types)
        local chosenType = types[typeIndex]
        local chosenItem = chooseItemFromPool(rarePools[chosenType])
        if chosenItem then
            itemsMap:Set(index, { Type = chosenType, Rarity = "Rare", Item = chosenItem })
            index = index + 1
        end
    end

    -- Generate 1 item: Rare or Legendary(25%)
    local chance = rng:NextNumber(0, 1)
    local finalRarity = (chance <= 0.25) and "Legendary" or "Rare"
    local typeIndex = rng:NextInteger(1, #types)
    local chosenType = types[typeIndex]
    local chosenItem = nil

    if finalRarity == "Legendary" then
        chosenItem = chooseItemFromPool(legendaryPools[chosenType])
    else
        chosenItem = chooseItemFromPool(rarePools[chosenType])
    end
    if chosenItem then
        itemsMap:Set(index, { Type = chosenType, Rarity = finalRarity, Item = chosenItem })
    end

    self._currentShopItems = itemsMap
end


return GlobalShopService