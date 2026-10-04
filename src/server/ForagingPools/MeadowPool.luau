--========================================================
-- POTATIUM - MEADOW FORAGING POOL FINAL
--
-- Zone 1 / Meadow economy.
--
-- OneIn is the requested rarity weight source.
-- Weight = 1 / OneIn and the pool is normalized to
-- select exactly one potato per successful dig.
--
-- The model names match ReplicatedStorage.newpotatoes.
--========================================================

local MeadowPool = {}

MeadowPool.ZoneName = "Meadow"
MeadowPool.ZoneNumber = 1

MeadowPool.Potatoes = {
	{
		Id = 1,
		Name = "Basic Potato",
		OneIn = 3,
		Rarity = "Common",
		Category = "Meadow",
		GoldPerSecond = 0.50,
		MoneyPerSecond = 0.50,
		SellValue = 50,
		BaseSellPrice = 50,
		RotDays = 2,
		NoRot = false,
		ModelName = "basic_potato",
	},
	{
		Id = 2,
		Name = "Big Potato",
		OneIn = 4,
		Rarity = "Rare",
		Category = "Meadow",
		GoldPerSecond = 0.75,
		MoneyPerSecond = 0.75,
		SellValue = 80,
		BaseSellPrice = 80,
		RotDays = 2.5,
		NoRot = false,
		ModelName = "big_potato",
	},
	{
		Id = 3,
		Name = "Butter Potato",
		OneIn = 5,
		Rarity = "Rare",
		Category = "Meadow",
		GoldPerSecond = 1.10,
		MoneyPerSecond = 1.10,
		SellValue = 120,
		BaseSellPrice = 120,
		RotDays = 3,
		NoRot = false,
		ModelName = "butter_potato",
	},
	{
		Id = 4,
		Name = "Feather Potato",
		OneIn = 13,
		Rarity = "Epic",
		Category = "Meadow",
		GoldPerSecond = 2.00,
		MoneyPerSecond = 2.00,
		SellValue = 250,
		BaseSellPrice = 250,
		RotDays = 3,
		NoRot = false,
		ModelName = "feather_potato",
	},
	{
		Id = 5,
		Name = "Flower Potato",
		OneIn = 15,
		Rarity = "Epic",
		Category = "Meadow",
		GoldPerSecond = 3.00,
		MoneyPerSecond = 3.00,
		SellValue = 400,
		BaseSellPrice = 400,
		RotDays = 3.5,
		NoRot = false,
		ModelName = "flower_potato",
	},
	{
		Id = 6,
		Name = "Golden Potato",
		OneIn = 20,
		Rarity = "Exotic",
		Category = "Meadow",
		GoldPerSecond = 4.50,
		MoneyPerSecond = 4.50,
		SellValue = 650,
		BaseSellPrice = 650,
		RotDays = 4,
		NoRot = false,
		ModelName = "golden_potato",
	},
	{
		Id = 7,
		Name = "Grass Potato",
		OneIn = 30,
		Rarity = "Exotic",
		Category = "Meadow",
		GoldPerSecond = 6.50,
		MoneyPerSecond = 6.50,
		SellValue = 900,
		BaseSellPrice = 900,
		RotDays = 4.5,
		NoRot = false,
		ModelName = "grass_potato",
	},
	{
		Id = 8,
		Name = "Lucky Potato",
		OneIn = 83,
		Rarity = "Legendary",
		Category = "Meadow",
		GoldPerSecond = 10,
		MoneyPerSecond = 10,
		SellValue = 1500,
		BaseSellPrice = 1500,
		RotDays = 5,
		NoRot = false,
		ModelName = "lucky_potato",
	},
	{
		Id = 9,
		Name = "Prism Potato",
		OneIn = 450,
		Rarity = "Super",
		Category = "Transcendent",
		GoldPerSecond = 16,
		MoneyPerSecond = 16,
		SellValue = 60000,
		BaseSellPrice = 60000,
		RotDays = 0,
		NoRot = true,
		ModelName = "prism_potato",
	},
	{
		Id = 10,
		Name = "Star Potato",
		OneIn = 750,
		Rarity = "Rainbow",
		Category = "Transcendent",
		GoldPerSecond = 23,
		MoneyPerSecond = 23,
		SellValue = 100000,
		BaseSellPrice = 100000,
		RotDays = 0,
		NoRot = true,
		ModelName = "star_potato",
	},
	{
		Id = 11,
		Name = "Sunkissed Potato",
		OneIn = 1500,
		Rarity = "Rainbow",
		Category = "Transcendent",
		GoldPerSecond = 32,
		MoneyPerSecond = 32,
		SellValue = 175000,
		BaseSellPrice = 175000,
		RotDays = 0,
		NoRot = true,
		ModelName = "sunkissed_potato",
	},
}

function MeadowPool.GetByName(name)
	for _, potato in ipairs(MeadowPool.Potatoes) do
		if potato.Name == name then
			return potato
		end
	end
	return nil
end

function MeadowPool.Roll(randomObject)
	local rng = randomObject or Random.new()
	local totalWeight = 0

	for _, potato in ipairs(MeadowPool.Potatoes) do
		local oneIn = math.max(1, tonumber(potato.OneIn) or 1)
		totalWeight += 1 / oneIn
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = rng:NextNumber(0, totalWeight)
	local current = 0

	for _, potato in ipairs(MeadowPool.Potatoes) do
		local oneIn = math.max(1, tonumber(potato.OneIn) or 1)
		current += 1 / oneIn

		if roll <= current then
			return potato
		end
	end

	return MeadowPool.Potatoes[1]
end

return MeadowPool
