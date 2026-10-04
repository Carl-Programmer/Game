local SpudMassService = {}

--==================================================
-- BASE POTATO SIZE
--
-- Normal potato = about player's hand.
-- Every system will use THIS SAME base size.
--==================================================

local NORMAL_BASE_SIZE =
	Vector3.new(
		0.8,
		0.6,
		0.9
	)

--==================================================
-- SPUD-MASS TIERS
--
-- Chance total = 100%
--==================================================

local TIERS = {

	{
		Key = "Trash",
		DisplayName = "Trash",

		ChanceEnd = 10,

		MinMass = 0.10,
		MaxMass = 0.39,

		VisualScale = 0.55,
	},

	{
		Key = "Normal",
		DisplayName = "Normal",

		ChanceEnd = 70,

		MinMass = 0.40,
		MaxMass = 1.00,

		VisualScale = 1.00,
	},

	{
		Key = "AboveNormal",
		DisplayName = "Above Normal",

		ChanceEnd = 90,

		MinMass = 1.01,
		MaxMass = 2.50,

		-- 5% bigger than Normal
		VisualScale = 1.05,
	},

	{
		Key = "Huge",
		DisplayName = "Huge",

		ChanceEnd = 97.4,

		MinMass = 2.51,
		MaxMass = 5.00,

		-- 20% bigger than Normal
		VisualScale = 1.20,
	},

	{
		Key = "UltraHuge",
		DisplayName = "Ultra Huge",

		ChanceEnd = 99.49,

		MinMass = 5.01,
		MaxMass = 10.00,

		-- 5% bigger than Huge
		VisualScale = 1.26,
	},

	{
		Key = "SuperHuge",
		DisplayName = "Super Huge",

		ChanceEnd = 99.99,

		MinMass = 10.01,
		MaxMass = 50.00,

		-- 10% bigger than Ultra Huge
		VisualScale = 1.386,
	},

	{
		Key = "Godly",
		DisplayName = "Godly",

		ChanceEnd = 100,

		MinMass = 50.01,
		MaxMass = 100.00,

		-- 5% bigger than Super Huge
		VisualScale = 1.4553,
	},
}

--==================================================
-- COPY TABLE
--==================================================

local function copyTable(
	source
)

	local result = {}

	for key, value in pairs(
		source
	) do

		result[key] =
			value
	end

	return result
end

--==================================================
-- MASS TO INTEGER HUNDREDTHS
--
-- Example:
-- 0.40 kg = 40
-- 2.51 kg = 251
--
-- This guarantees exact 2 decimal values.
--==================================================

local function massToHundredths(
	mass
)

	return
		math.floor(
			mass * 100
			+ 0.5
		)
end

--==================================================
-- ROLL MASS INSIDE TIER
--==================================================

local function rollMass(
	random,
	tier
)

	local minimum =
		massToHundredths(
			tier.MinMass
		)

	local maximum =
		massToHundredths(
			tier.MaxMass
		)

	return
		random:NextInteger(
			minimum,
			maximum
		)
		/ 100
end

--==================================================
-- GET TIER FROM RNG
--==================================================

local function getTierFromRoll(
	roll
)

	for _, tier in ipairs(
		TIERS
	) do

		if roll < tier.ChanceEnd then

			return tier

		end
	end

	return
		TIERS[
			#TIERS
		]
end

--==================================================
-- ROLL SPUD-MASS
--
-- Every potato calls this independently.
--
-- Returns:
--
-- {
--     SpudMass = 3.76,
--     SizeTier = "Huge",
--     DisplayTier = "Huge",
--     VisualScale = 1.20,
--     VisualSize = Vector3,
-- }
--==================================================

function SpudMassService.Roll(
	random
)

	random =
		random
		or Random.new()

	local chanceRoll =
		random:NextNumber(
			0,
			100
		)

	local tier =
		getTierFromRoll(
			chanceRoll
		)

	local mass =
		rollMass(
			random,
			tier
		)

	local visualSize =
		NORMAL_BASE_SIZE
		* tier.VisualScale

	return {

		SpudMass =
			mass,

		SizeTier =
			tier.Key,

		DisplayTier =
			tier.DisplayName,

		VisualScale =
			tier.VisualScale,

		VisualSize =
			visualSize,
	}

end

--==================================================
-- GET VISUAL SIZE FROM SAVED SCALE
--
-- IMPORTANT:
-- Inventory uses the SAME saved VisualScale.
-- No reroll.
--==================================================

function SpudMassService.GetVisualSize(
	visualScale
)

	visualScale =
		tonumber(
			visualScale
		)
		or 1

	return
		NORMAL_BASE_SIZE
		* visualScale
end

--==================================================
-- GET BASE SIZE
--==================================================

function SpudMassService.GetBaseSize()

	return NORMAL_BASE_SIZE

end

--==================================================
-- GET TIER INFORMATION
--==================================================

function SpudMassService.GetTierInfo(
	tierKey
)

	for _, tier in ipairs(
		TIERS
	) do

		if tier.Key == tierKey then

			return
				copyTable(
					tier
				)

		end
	end

	return nil

end

--==================================================
-- GET DISPLAY NAME
--==================================================

function SpudMassService.GetDisplayTier(
	tierKey
)

	local info =
		SpudMassService.GetTierInfo(
			tierKey
		)

	if info then
		return info.DisplayName
	end

	return tostring(
		tierKey
	)

end

--==================================================
-- FORMAT MASS
--
-- Example:
-- 3.7 -> "3.70 kg"
--==================================================

function SpudMassService.FormatMass(
	mass
)

	mass =
		tonumber(
			mass
		)
		or 0

	return
		string.format(
			"%.2f kg",
			mass
		)

end

--==================================================
-- VALIDATE TIER
--==================================================

function SpudMassService.IsValidTier(
	tierKey
)

	return
		SpudMassService.GetTierInfo(
			tierKey
		)
		~= nil
end

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("🥔 SPUD-MASS SERVICE READY")
print("========================================")
print("Trash        = 10%")
print("Normal       = 60%")
print("Above Normal = 20%")
print("Huge         = 7.4%")
print("Ultra Huge   = 2.09%")
print("Super Huge   = 0.5%")
print("Godly        = 0.01%")
print("========================================")
print("Minimum mass = 0.10 kg")
print("Maximum mass = 100.00 kg")
print("========================================")
print("")

return SpudMassService