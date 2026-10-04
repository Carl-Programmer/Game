local RarityService = {}

--==================================================
-- RARITY SERVICE V3
--
-- FINAL 7 RARITIES
--
-- Common
-- Rare
-- Epic
-- Exotic
-- Legendary
-- Super
-- Rainbow
--
-- ✅ Final chances
-- ✅ Final $/sec values
-- ✅ Super supported
-- ✅ Rainbow supported
-- ✅ Old saved rarity compatibility
--==================================================

local RNG =
	Random.new()

--==================================================
-- RARITIES
--==================================================

local RARITIES = {

	{
		Name = "Common",
		Chance = 50,
		Income = 1,

		PrimaryColor =
			Color3.fromRGB(
				190,
				150,
				92
			),

		SecondaryColor =
			Color3.fromRGB(
				150,
				108,
				62
			),

		Material =
			Enum.Material.SmoothPlastic,
	},

	{
		Name = "Rare",
		Chance = 25,
		Income = 4,

		PrimaryColor =
			Color3.fromRGB(
				72,
				194,
				84
			),

		SecondaryColor =
			Color3.fromRGB(
				39,
				128,
				50
			),

		Material =
			Enum.Material.SmoothPlastic,
	},

	{
		Name = "Epic",
		Chance = 12,
		Income = 8,

		PrimaryColor =
			Color3.fromRGB(
				68,
				142,
				238
			),

		SecondaryColor =
			Color3.fromRGB(
				39,
				88,
				174
			),

		Material =
			Enum.Material.SmoothPlastic,
	},

	{
		Name = "Exotic",
		Chance = 7.98,
		Income = 15,

		PrimaryColor =
			Color3.fromRGB(
				168,
				77,
				224
			),

		SecondaryColor =
			Color3.fromRGB(
				107,
				40,
				160
			),

		Material =
			Enum.Material.SmoothPlastic,
	},

	{
		Name = "Legendary",
		Chance = 5,
		Income = 25,

		PrimaryColor =
			Color3.fromRGB(
				255,
				220,
				54
			),

		SecondaryColor =
			Color3.fromRGB(
				202,
				149,
				21
			),

		Material =
			Enum.Material.SmoothPlastic,
	},

	{
		Name = "Super",
		Chance = 0.01,
		Income = 80,

		PrimaryColor =
			Color3.fromRGB(
				255,
				205,
				35
			),

		SecondaryColor =
			Color3.fromRGB(
				255,
				244,
				134
			),

		Material =
			Enum.Material.Metal,
	},

	{
		Name = "Rainbow",
		Chance = 0.01,
		Income = 100,

		PrimaryColor =
			Color3.fromRGB(
				255,
				255,
				255
			),

		SecondaryColor =
			Color3.fromRGB(
				255,
				255,
				255
			),

		Material =
			Enum.Material.Neon,
	},

}

--==================================================
-- LOOKUP
--==================================================

local LOOKUP =
	{}

for _, info in ipairs(
	RARITIES
) do

	LOOKUP[
		info.Name
	] =
		info

end

--==================================================
-- OLD SAVES
--
-- These rarities are NOT generated anymore.
--
-- They only exist so old potatoes don't break.
--==================================================

local LEGACY_MAP = {

	Uncommon =
		"Rare",

	Mythic =
		"Legendary",

	Silver =
		"Epic",

	Gold =
		"Exotic",

	Diamond =
		"Legendary",

	Trash =
		"Common",

	Normal =
		"Common",

	AboveNormal =
		"Rare",

	Huge =
		"Rare",

	UltraHuge =
		"Epic",

	SuperHuge =
		"Exotic",

	Godly =
		"Legendary",

}

--==================================================
-- NORMALIZE RARITY
--==================================================

local function normalize(
	rarity
)

	rarity =
		tostring(
			rarity
				or
				"Common"
		)

	if LOOKUP[
		rarity
	] then

		return rarity

	end

	if LEGACY_MAP[
		rarity
	] then

		return
			LEGACY_MAP[
				rarity
			]

	end

	return "Common"

end

--==================================================
-- GET ALL
--==================================================

function RarityService.GetRarities()

	local result =
		{}

	for _, info in ipairs(
		RARITIES
	) do

		table.insert(
			result,
			{
				Name =
					info.Name,

				Chance =
					info.Chance,

				Income =
					info.Income,
			}
		)

	end

	return result

end

--==================================================
-- GET RARITY INFO
--==================================================

function RarityService.GetRarity(
	rarity
)

	local normalized =
		normalize(
			rarity
		)

	return
		LOOKUP[
			normalized
		]

end

--==================================================
-- RNG
--==================================================

function RarityService.Roll()

	local roll =
		RNG:NextNumber(
			0,
			100
		)

	local total =
		0

	for _, info in ipairs(
		RARITIES
	) do

		total +=
			info.Chance

		if roll <= total then

			return info.Name

		end

	end

	return "Common"

end

--==================================================
-- MONEY / SECOND
--==================================================

function RarityService.GetIncomeMultiplier(
	rarity
)

	local info =
		RarityService.GetRarity(
			rarity
		)

	if not info then

		return 0

	end

	return
		info.Income
		or
		0

end

--==================================================
-- POTATO NAME
--==================================================

function RarityService.GetPotatoName(
	rarity
)

	local normalized =
		normalize(
			rarity
		)

	return
		normalized
		..
		" Potato"

end

--==================================================
-- PRIMARY COLOR
--==================================================

function RarityService.GetPrimaryColor(
	rarity
)

	local info =
		RarityService.GetRarity(
			rarity
		)

	if not info then

		return
			Color3.fromRGB(
				190,
				150,
				92
			)

	end

	return
		info.PrimaryColor

end

--==================================================
-- SECONDARY COLOR
--==================================================

function RarityService.GetSecondaryColor(
	rarity
)

	local info =
		RarityService.GetRarity(
			rarity
		)

	if not info then

		return
			Color3.fromRGB(
				150,
				108,
				62
			)

	end

	return
		info.SecondaryColor

end

--==================================================
-- MATERIAL
--==================================================

function RarityService.GetMaterial(
	rarity
)

	local info =
		RarityService.GetRarity(
			rarity
		)

	if not info then

		return
			Enum.Material.SmoothPlastic

	end

	return
		info.Material
		or
		Enum.Material.SmoothPlastic

end

--==================================================
-- SUPER
--==================================================

function RarityService.IsSuper(
	rarity
)

	return
		normalize(
			rarity
		)
		==
		"Super"

end

--==================================================
-- RAINBOW
--==================================================

function RarityService.IsRainbow(
	rarity
)

	return
		normalize(
			rarity
		)
		==
		"Rainbow"

end

--==================================================
-- ROT IMMUNITY
--==================================================

function RarityService.HasNoRot(
	rarity
)

	local normalized =
		normalize(
			rarity
		)

	return
		normalized
		==
		"Super"
		or
		normalized
		==
		"Rainbow"

end

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("💎 RARITY SERVICE V3 - FINAL 7")
print("========================================")
print("Common    = 50%    | $1/sec")
print("Rare      = 25%    | $4/sec")
print("Epic      = 12%    | $8/sec")
print("Exotic    = 7.98%  | $15/sec")
print("Legendary = 5%     | $25/sec")
print("Super     = 0.01%  | $80/sec | NO ROT")
print("Rainbow   = 0.01%  | $100/sec | NO ROT")
print("----------------------------------------")
print("✅ Total chance = 100%")
print("✅ Super money supported")
print("✅ Rainbow money supported")
print("♾ Super = NO ROT")
print("🌈 Rainbow = NO ROT")
print("✅ Old rarity compatibility")
print("========================================")
print("")

return RarityService