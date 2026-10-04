--========================================================
-- POTATIUM - HOE CONFIG V2
--
-- One place to edit all hoe stats.
--
-- MODEL NAMES:
-- Wooden = WoodenHoe_2
-- Stone  = stonehoe
-- Iron   = ironhoe
--========================================================

local HoeConfig = {}

HoeConfig.Order = {
	"Wooden",
	"Stone",
	"Iron",
}

HoeConfig.Stats = {
	Wooden = {
		DisplayName = "Wooden Hoe",
		ModelName = "WoodenHoe_2",

		MaxDurability = 25,

		-- 0.10 = 10% less dig time.
		DigSpeedBonus = 0,

		ExtraPotatoChance = 0,
		BetterRollChance = 0,
	},

	Stone = {
		DisplayName = "Stone Hoe",
		ModelName = "stonehoe",

		MaxDurability = 40,
		DigSpeedBonus = 0.10,

		-- 5% chance to receive one extra copy
		-- of the potato found on that dig.
		ExtraPotatoChance = 0.05,
		BetterRollChance = 0,
	},

	Iron = {
		DisplayName = "Iron Hoe",
		ModelName = "ironhoe",

		MaxDurability = 60,
		DigSpeedBonus = 0.15,

		ExtraPotatoChance = 0,

		-- 8% chance to make a second potato roll.
		-- ForagingService keeps whichever roll has
		-- the higher OneIn value.
		BetterRollChance = 0.08,
	},
}

function HoeConfig.Get(tier)
	return HoeConfig.Stats[tostring(tier or "")]
end

function HoeConfig.InferTier(tool)
	if not tool then
		return nil
	end

	local attributeTier = tool:GetAttribute("HoeTier")

	if HoeConfig.Stats[attributeTier] then
		return attributeTier
	end

	local compactName =
		string.lower(
			tostring(tool.Name or "")
		)
		:gsub("[^%w]", "")

	if
		string.find(
			compactName,
			"stonehoe",
			1,
			true
		)
	then
		return "Stone"
	end

	if
		string.find(
			compactName,
			"ironhoe",
			1,
			true
		)
	then
		return "Iron"
	end

	if
		string.find(
			compactName,
			"woodenhoe",
			1,
			true
		)
		or
		compactName == "hoe"
		or
		compactName == "shovel"
	then
		return "Wooden"
	end

	return nil
end

function HoeConfig.ApplyAttributes(
	tool,
	tier,
	durability
)
	local stats =
		HoeConfig.Get(tier)

	if
		not tool
		or
		not stats
	then
		return false
	end

	local maxDurability =
		tonumber(
			stats.MaxDurability
		)
		or
		1

	local currentDurability =
		tonumber(
			durability
		)

	if currentDurability == nil then
		currentDurability =
			tonumber(
				tool:GetAttribute(
					"Durability"
				)
			)
	end

	if currentDurability == nil then
		currentDurability =
			maxDurability
	end

	currentDurability =
		math.clamp(
			math.floor(
				currentDurability
			),
			0,
			maxDurability
		)

	tool:SetAttribute(
		"FarmingToolType",
		"Hoe"
	)

	tool:SetAttribute(
		"HoeTier",
		tier
	)

	tool:SetAttribute(
		"BuffsEnabled",
		true
	)

	tool:SetAttribute(
		"DigSpeedBonus",
		stats.DigSpeedBonus
		or
		0
	)

	tool:SetAttribute(
		"ExtraPotatoChance",
		stats.ExtraPotatoChance
		or
		0
	)

	tool:SetAttribute(
		"BetterRollChance",
		stats.BetterRollChance
		or
		0
	)

	tool:SetAttribute(
		"DurabilityEnabled",
		true
	)

	tool:SetAttribute(
		"MaxDurability",
		maxDurability
	)

	tool:SetAttribute(
		"Durability",
		currentDurability
	)

	return true
end

return HoeConfig
