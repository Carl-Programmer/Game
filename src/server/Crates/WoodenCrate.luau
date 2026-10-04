--========================================================
-- POTATIUM - WOODEN CRATE V1
--
-- Easy-to-edit crate configuration.
--
-- V1:
--   Wooden Hoe = 75%
--   Stone Hoe  = 20%
--   Iron Hoe   = 5%
--
-- Buffs + durability are intentionally disabled until V2.
--========================================================

local WoodenCrate = {}

WoodenCrate.Id = "Wooden"
WoodenCrate.Name = "Wooden Crate"

-- CHANGE THIS whenever you decide the final shop price.
WoodenCrate.Price = 500

WoodenCrate.Drops = {
	{
		Name = "Wooden Hoe",
		Tier = "Wooden",
		Chance = 75,
	},
	{
		Name = "Stone Hoe",
		Tier = "Stone",
		Chance = 20,
	},
	{
		Name = "Iron Hoe",
		Tier = "Iron",
		Chance = 5,
	},
}

function WoodenCrate.Roll(randomObject)
	local rng = randomObject or Random.new()

	local totalChance = 0
	for _, drop in ipairs(WoodenCrate.Drops) do
		totalChance += tonumber(drop.Chance) or 0
	end

	if totalChance <= 0 then
		return WoodenCrate.Drops[1]
	end

	local roll = rng:NextNumber(0, totalChance)
	local current = 0

	for _, drop in ipairs(WoodenCrate.Drops) do
		current += tonumber(drop.Chance) or 0

		if roll <= current then
			return drop
		end
	end

	return WoodenCrate.Drops[#WoodenCrate.Drops]
end

function WoodenCrate.GetDropNames()
	local names = {}

	for _, drop in ipairs(WoodenCrate.Drops) do
		table.insert(names, drop.Name)
	end

	return names
end

return WoodenCrate
