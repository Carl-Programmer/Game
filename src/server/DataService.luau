local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataService = {}

--==================================================
-- DATA SERVICE V4.3 - PERSISTENT FAVORITES
--
-- ✅ POTATO TYPES
-- Normal
-- Sweet
--
-- ✅ ROT TIMER + PAUSE / RESUME
-- ✅ SUPER + RAINBOW NEVER ROT
-- ✅ OLD SAVE COMPATIBILITY
-- ✅ PLACEMENT SAVING
-- ✅ COLLECTOR / UPGRADES PRESERVED
--==================================================

local AUTOSAVE_TIME = 60
local MAX_RETRIES = 3

local DATA_VERSION = 4
local POTATO_HEIGHT = 2.5
local STUDIO_ROT_DURATION = 180
local LIVE_ROT_DURATION = 3 * 24 * 60 * 60

local DEFAULT_ROT_DURATION

if RunService:IsStudio() then

	DEFAULT_ROT_DURATION =
		STUDIO_ROT_DURATION

else

	DEFAULT_ROT_DURATION =
		LIVE_ROT_DURATION

end

--==================================================
-- SPECIAL ROT-PROTECTION PLOT
--
-- FarmLand_01 is free and holds one potato through
-- the existing placement system.
--
-- 20% protection means rot runs at 80% speed.
-- 3 days / 0.80 = 3.75 days.
--
-- Later the Upgrade Shop can save a higher value in:
-- profile.Upgrades.RotProtectionPercent
--==================================================

local ROT_PROTECTION_PLOT_NAME =
	"FarmLand_01"

local BASE_ROT_PROTECTION_PERCENT =
	20

local MAX_ROT_PROTECTION_PERCENT =
	80

--==================================================
-- NO-ROT RARITIES
--==================================================

local NO_ROT_RARITIES = {
	Super = true,
	Rainbow = true,
}

--==================================================
-- DATA STORE
--
-- DO NOT CHANGE.
--==================================================

local STORE_NAME

if RunService:IsStudio() then

	STORE_NAME =
		"PotatoGame_DEV_v1"

else

	STORE_NAME =
		"PotatoGame_LIVE_v1"

end

local store =
	DataStoreService:GetDataStore(
		STORE_NAME
	)

--==================================================
-- RARITIES
--
-- Uncommon / Mythic remain here ONLY so old saved
-- potatoes don't get destroyed.
--
-- New foraging will only generate your final 7:
--
-- Common
-- Rare
-- Epic
-- Exotic
-- Legendary
-- Super
-- Rainbow
--==================================================

local VALID_RARITIES = {

	Common = true,

	-- Legacy
	Uncommon = true,

	Rare = true,
	Epic = true,
	Exotic = true,
	Legendary = true,

	-- Legacy
	Mythic = true,

	Super = true,
	Rainbow = true,

}

--==================================================
-- OLD SPUD-MASS → RARITY
--==================================================

local OLD_TIER_TO_RARITY = {

	Trash = "Common",

	Normal = "Common",

	AboveNormal = "Uncommon",

	Huge = "Rare",

	UltraHuge = "Epic",

	SuperHuge = "Exotic",

	Godly = "Legendary",

}

--==================================================
-- OLD SIX-RARITY SYSTEM
--==================================================

local OLD_RARITY_TO_NEW_RARITY = {

	Common = "Common",

	Uncommon = "Uncommon",

	Rare = "Rare",

	Silver = "Epic",

	Gold = "Exotic",

	Diamond = "Legendary",

}

--==================================================
-- TEMP OLD SHOP COMPATIBILITY
--
-- REMOVE LATER when the new shop is finished.
--==================================================

local RARITY_TO_OLD_TIER = {

	Common = "Normal",

	Uncommon = "AboveNormal",

	Rare = "Huge",

	Epic = "UltraHuge",

	Exotic = "SuperHuge",

	Legendary = "Godly",

	Mythic = "Godly",

	Super = "Godly",

	Rainbow = "Godly",

}

--==================================================
-- DEFAULT DATA
--==================================================

local DEFAULT_DATA = {

	Version = DATA_VERSION,

	--==================================================
	-- MONEY
	--==================================================

	Cash = 0,

	--==================================================
	-- OLD MATERIALS
	--
	-- Kept temporarily so old saves don't break.
	-- Foraging will no longer give Potato Bits.
	--==================================================

	PotatoBits = 5,

	RedBits = 0,

	PurpleBits = 0,

	GoldenBits = 0,

	--==================================================
	-- POTATO COUNT
	--==================================================

	Potatoes = 0,

	--==================================================
	-- POTATO INVENTORY
	--
	-- {
	--
	--     Id = 1,
	--
	--     PotatoType = "Normal",
	--
	--     Rarity = "Epic",
	--
	--     DisplayName = "Epic Potato",
	--
	--     Mutation = "None",
	--
	--     Source = "Foraging",
	--
	--     PlacedFarm = "",
	--
	--     PlacedSlot = "",
	--
	--     MoneyPerSecond = 0,
	--
	--     GeneratedMoney = 0,
	--
	--     RotRemaining = 180,
	--
	--     RotAt = 0,
	--
	--     IsRotten = false,
	--
	--     ActiveRotSpeedMultiplier = 1,
	--
	--     CreatedAt = 0,
	--
	-- }
	--==================================================

	PotatoInventory = {},

	NextPotatoId = 1,

	--==================================================
	-- FORAGING COUNTERS
	--==================================================

	ForagedPotatoes = 0,

	ForagedCommonPotatoes = 0,

	ForagedUncommonPotatoes = 0,

	ForagedRarePotatoes = 0,

	ForagedEpicPotatoes = 0,

	ForagedExoticPotatoes = 0,

	ForagedLegendaryPotatoes = 0,

	ForagedMythicPotatoes = 0,

	ForagedSuperPotatoes = 0,

	ForagedRainbowPotatoes = 0,

	--==================================================
	-- FARM STATES
	--==================================================

	PlantStates = {},

	--==================================================
	-- EQUIPMENT
	--==================================================

	Equipment = {},

	--==================================================
	-- UPGRADES
	--==================================================

	Upgrades = {},

	LastSavedAt = 0,

}

--==================================================
-- SAVED PLAYER ATTRIBUTES
--==================================================

local SAVED_ATTRIBUTES = {

	"Cash",

	"PotatoBits",

	"RedBits",

	"PurpleBits",

	"GoldenBits",

	"Potatoes",

	"ForagedPotatoes",

	"ForagedCommonPotatoes",

	"ForagedUncommonPotatoes",

	"ForagedRarePotatoes",

	"ForagedEpicPotatoes",

	"ForagedExoticPotatoes",

	"ForagedLegendaryPotatoes",

	"ForagedMythicPotatoes",

	"ForagedSuperPotatoes",

	"ForagedRainbowPotatoes",

}

--==================================================
-- RUNTIME
--==================================================

local profiles = {}

local canSave = {}

local started = false

--==================================================
-- DEEP COPY
--==================================================

local function deepCopy(
	value
)

	if
		type(value)
		~=
		"table"
	then

		return value

	end

	local result = {}

	for key, child in pairs(
		value
	) do

		result[
			deepCopy(
				key
			)
		] =
			deepCopy(
				child
			)

	end

	return result

end

--==================================================
-- MERGE
--==================================================

local function mergeData(
	defaults,
	loaded
)

	local result =
		deepCopy(
			defaults
		)

	if
		type(loaded)
		~=
		"table"
	then

		return result

	end

	for key, value in pairs(
		loaded
	) do

		if
			type(value)
			==
			"table"
			and
			type(
				result[
					key
				]
			)
			==
			"table"
		then

			if
				next(
					result[
						key
					]
				)
				==
				nil
			then

				result[
					key
				] =
					deepCopy(
						value
					)

			else

				result[
					key
				] =
					mergeData(
						result[
							key
						],
						value
					)

			end

		else

			result[
				key
			] =
				value

		end

	end

	return result

end

--==================================================
-- DATASTORE RETRY
--==================================================

local function retryRequest(
	callback
)

	local lastError

	for attempt = 1, MAX_RETRIES do

		local success,
			result =
				pcall(
					callback
				)

		if success then

			return true,
				result

		end

		lastError =
			result

		warn(
			"💾 DataStore attempt "
			..
			attempt
			..
			" failed: "
			..
			tostring(
				result
			)
		)

		task.wait(
			attempt
			*
			1.5
		)

	end

	return false,
		lastError

end

--==================================================
-- KEY
--==================================================

local function getKey(
	player
)

	return
		"Player_"
		..
		player.UserId

end

--==================================================
-- NORMALIZE RARITY
--==================================================

local function normalizeRarity(
	rarityName
)

	if
		type(rarityName)
		==
		"string"
	then

		if
			VALID_RARITIES[
				rarityName
			]
		then

			return rarityName

		end

		if
			OLD_RARITY_TO_NEW_RARITY[
				rarityName
			]
		then

			return
				OLD_RARITY_TO_NEW_RARITY[
					rarityName
				]

		end

	end

	return "Common"

end

--==================================================
-- GET RARITY FROM OLD / NEW RECORD
--==================================================

local function getRecordRarity(
	record
)

	if
		type(
			record.Rarity
		)
		==
		"string"
	then

		if
			VALID_RARITIES[
				record.Rarity
			]
		then

			return
				record.Rarity

		end

		if
			OLD_RARITY_TO_NEW_RARITY[
				record.Rarity
			]
		then

			return
				OLD_RARITY_TO_NEW_RARITY[
					record.Rarity
				]

		end

	end

	local oldTier =
		record.SizeTier

	if
		type(oldTier)
		==
		"string"
		and
		OLD_TIER_TO_RARITY[
			oldTier
		]
	then

		return
			OLD_TIER_TO_RARITY[
				oldTier
			]

	end

	return "Common"

end

--==================================================
-- MEADOW POTATO COMPATIBILITY
--==================================================

local MEADOW_POTATO_TYPES = {
	Basic = true,
	Big = true,
	Butter = true,
	Feather = true,
	Flower = true,
	Golden = true,
	Grass = true,
	Lucky = true,
	Prism = true,
	Star = true,
	Sunkissed = true,
}

local function isMeadowPotatoType(potatoType)
	return MEADOW_POTATO_TYPES[tostring(potatoType or "")] == true
end

local function isNoRotRecord(record)
	if type(record) ~= "table" then
		return false
	end

	if record.IsRotImmune == true then
		return true
	end

	local duration = tonumber(record.RotDurationSeconds)
	if duration ~= nil and duration <= 0 then
		return true
	end

	return NO_ROT_RARITIES[record.Rarity] == true
end

--==================================================
-- POTATO TYPE
--
-- CURRENT:
--
-- Normal
-- Sweet
--
-- OLD:
--
-- Potato → Normal
-- NormalPotato → Normal
-- SweetPotato → Sweet
--==================================================

local function normalizePotatoType(
	value
)

	local potatoType =
		tostring(
			value
			or
			"Basic"
		)

	if potatoType == "" or potatoType == "Potato" or potatoType == "Normal" or potatoType == "NormalPotato" then
		return "Basic"
	end

	if potatoType == "Sun-Kissed" or potatoType == "Sun-KissedPotato" or potatoType == "SunKissedPotato" then
		return "Sunkissed"
	end

	if potatoType == "BasicPotato" then
		return "Basic"
	end

	if potatoType == "BigPotato" then return "Big" end
	if potatoType == "ButterPotato" then return "Butter" end
	if potatoType == "FeatherPotato" then return "Feather" end
	if potatoType == "FlowerPotato" then return "Flower" end
	if potatoType == "GoldenPotato" then return "Golden" end
	if potatoType == "GrassPotato" then return "Grass" end
	if potatoType == "LuckyPotato" then return "Lucky" end
	if potatoType == "PrismPotato" then return "Prism" end
	if potatoType == "StarPotato" then return "Star" end

	return potatoType

end

--==================================================
-- DISPLAY NAME
--==================================================

local function getPotatoDisplayName(
	rarity,
	potatoType
)

	rarity =
		tostring(
			rarity
			or
			"Common"
		)

	potatoType =
		normalizePotatoType(
			potatoType
		)

	if isMeadowPotatoType(potatoType) then
		return potatoType .. " Potato"
	end

	if potatoType == "Normal" then
		return rarity .. " Potato"
	end

	return rarity .. " " .. potatoType .. " Potato"

end

--==================================================
-- CLEAN POTATO RECORD
--==================================================

local function cleanPotatoRecord(
	record
)

	if
		type(record)
		~=
		"table"
	then

		return nil

	end

	local rarity =
		getRecordRarity(
			record
		)

	local cleaned = {}

	cleaned.Id =
		tonumber(
			record.Id
		)

	cleaned.PotatoType =
		normalizePotatoType(
			record.PotatoType
		)

	cleaned.Rarity =
		normalizeRarity(
			rarity
		)

	cleaned.DisplayName =
		getPotatoDisplayName(
			cleaned.Rarity,
			cleaned.PotatoType
		)

	cleaned.Category =
		tostring(
			record.Category
			or
			(
				isMeadowPotatoType(cleaned.PotatoType)
				and "Meadow"
				or "Unknown"
			)
		)

	cleaned.ModelName =
		tostring(
			record.ModelName
			or
			""
		)

	cleaned.TargetHeight =
		POTATO_HEIGHT

	cleaned.Mutation =
		tostring(
			record.Mutation
			or
			"None"
		)

	cleaned.Source =
		tostring(
			record.Source
			or
			"Foraging"
		)

	--==================================================
	-- FAVORITE
	--==================================================

	cleaned.Favorite =
		record.Favorite
		==
		true

	--==================================================
	-- PLACEMENT
	--==================================================

	cleaned.PlacedFarm =
		tostring(
			record.PlacedFarm
			or
			""
		)

	cleaned.PlacedSlot =
		tostring(
			record.PlacedSlot
			or
			record.PlacedFarmLand
			or
			""
		)

	--==================================================
	-- MONEY
	--==================================================

	cleaned.MoneyPerSecond =
		math.max(
			0,
			tonumber(
				record.MoneyPerSecond
			)
			or
			0
		)

	cleaned.GeneratedMoney =
		math.max(
			0,
			tonumber(
				record.GeneratedMoney
			)
			or
			0
		)

	cleaned.SpudMass =
		math.clamp(tonumber(record.SpudMass) or 1, 0.01, 100)

	cleaned.SizeTier =
		tostring(record.SizeTier or "1-10 kg")

	cleaned.VisualScale =
		math.max(0.01, tonumber(record.VisualScale) or 1)

	cleaned.BaseSellPrice =
		math.max(0, tonumber(record.BaseSellPrice) or 0)

	cleaned.SellPrice =
		math.max(0, tonumber(record.SellPrice) or cleaned.BaseSellPrice)

	cleaned.RotDurationSeconds =
		tonumber(record.RotDurationSeconds)

	cleaned.IsRotImmune =
		record.IsRotImmune == true

	--==================================================
	-- ROT
	--==================================================

	cleaned.RotRemaining =
		math.max(
			0,
			tonumber(record.RotRemaining)
				or
			tonumber(record.RotDurationSeconds)
				or
			DEFAULT_ROT_DURATION
		)

	cleaned.RotAt =
		math.max(
			0,
			math.floor(
				tonumber(
					record.RotAt
				)
				or
				0
			)
		)

	cleaned.IsRotten =
		record.IsRotten
		==
		true

	-- Rot speed used by the CURRENT active placement.
	--
	-- 1.00 = normal plot
	-- 0.80 = 20% slower rot
	--
	-- When the potato is paused in inventory this is
	-- reset to 1.

	cleaned.ActiveRotSpeedMultiplier =
		math.clamp(
			tonumber(
				record.ActiveRotSpeedMultiplier
			)
			or
			1,
			0.05,
			1
		)

	--==================================================
	-- SUPER / RAINBOW
	--==================================================

	if isNoRotRecord(cleaned) then

		cleaned.RotRemaining =
			0

		cleaned.RotAt =
			0

		cleaned.IsRotten =
			false

		cleaned.ActiveRotSpeedMultiplier =
			0

	else

		--==================================================
		-- PLACED POTATO
		--==================================================

		if
			cleaned.PlacedSlot
			~=
			""
			and
			not cleaned.IsRotten
		then

			if
				cleaned.RotRemaining
				<=
				0
			then

				cleaned.RotRemaining =
					0

				cleaned.RotAt =
					0

				cleaned.IsRotten =
					true

				cleaned.ActiveRotSpeedMultiplier =
					0

			elseif
				cleaned.RotAt
				>
				0
				and
				cleaned.RotAt
				<=
				os.time()
			then

				cleaned.RotRemaining =
					0

				cleaned.RotAt =
					0

				cleaned.IsRotten =
					true

				cleaned.ActiveRotSpeedMultiplier =
					0

			elseif
				cleaned.RotAt
				<=
				0
			then

				-- Let StartPotatoRot begin the timer after
				-- placement restoration. This is important
				-- because FarmLand_01 may use a slower rate.

				cleaned.RotAt =
					0

				cleaned.ActiveRotSpeedMultiplier =
					1

			end

		else

			-- Potato in inventory = rot paused.

			cleaned.RotAt =
				0

			cleaned.ActiveRotSpeedMultiplier =
				1

		end

	end

	cleaned.CreatedAt =
		tonumber(
			record.CreatedAt
		)
		or
		os.time()

	return cleaned

end

--==================================================
-- REMOVE OLD PROFILE KEYS
--==================================================

local function removeLegacyProfileKeys(
	profile
)

	profile.TrashPotatoes =
		nil

	profile.NormalPotatoes =
		nil

	profile.AboveNormalPotatoes =
		nil

	profile.HugePotatoes =
		nil

	profile.UltraHugePotatoes =
		nil

	profile.SuperHugePotatoes =
		nil

	profile.GodlyPotatoes =
		nil

	profile.ForagedSilverPotatoes =
		nil

	profile.ForagedGoldPotatoes =
		nil

	profile.ForagedDiamondPotatoes =
		nil

end

--==================================================
-- MIGRATE PROFILE
--==================================================

local function migrateProfile(
	profile
)

	if
		type(profile)
		~=
		"table"
	then

		return
			deepCopy(
				DEFAULT_DATA
			)

	end

	local oldVersion =
		tonumber(
			profile.Version
		)
		or
		1

	--==================================================
	-- OLD FORAGING COUNTERS
	--==================================================

	if oldVersion < 3 then

		profile.ForagedEpicPotatoes =
			(
				tonumber(
					profile.ForagedEpicPotatoes
				)
				or
				0
			)
			+
			(
				tonumber(
					profile.ForagedSilverPotatoes
				)
				or
				0
			)

		profile.ForagedExoticPotatoes =
			(
				tonumber(
					profile.ForagedExoticPotatoes
				)
				or
				0
			)
			+
			(
				tonumber(
					profile.ForagedGoldPotatoes
				)
				or
				0
			)

		profile.ForagedLegendaryPotatoes =
			(
				tonumber(
					profile.ForagedLegendaryPotatoes
				)
				or
				0
			)
			+
			(
				tonumber(
					profile.ForagedDiamondPotatoes
				)
				or
				0
			)

	end

	--==================================================
	-- POTATO INVENTORY MIGRATION
	--==================================================

	local oldInventory =
		profile.PotatoInventory
		or
		{}

	local newInventory = {}

	local highestId = 0

	for _, oldRecord in ipairs(
		oldInventory
	) do

		local newRecord =
			cleanPotatoRecord(
				oldRecord
			)

		if newRecord then

			local id =
				tonumber(
					newRecord.Id
				)

			if not id then

				id =
					highestId
					+
					1

				newRecord.Id =
					id

			end

			highestId =
				math.max(
					highestId,
					id
				)

			table.insert(
				newInventory,
				newRecord
			)

		end

	end

	profile.PotatoInventory =
		newInventory

	local savedNextId =
		tonumber(
			profile.NextPotatoId
		)
		or
		1

	profile.NextPotatoId =
		math.max(
			savedNextId,
			highestId
			+
			1
		)

	profile.Version =
		DATA_VERSION

	removeLegacyProfileKeys(
		profile
	)

	return profile

end

--==================================================
-- TEMP LEGACY SHOP COPY
--==================================================

local function makeLegacyShopCompatibleCopy(
	record
)

	local result =
		deepCopy(
			record
		)

	local rarity =
		normalizeRarity(
			result.Rarity
		)

	if result.SizeTier == nil then
		result.SizeTier =
			RARITY_TO_OLD_TIER[rarity]
			or
			"1-10 kg"
	end

	if result.SpudMass == nil then
		result.SpudMass = 1
	end

	if result.VisualScale == nil then
		result.VisualScale = 1
	end

	if result.BaseSellPrice == nil then
		result.BaseSellPrice = 0
	end

	if result.SellPrice == nil then
		result.SellPrice = result.BaseSellPrice
	end

	if result.RotDurationSeconds == nil then
		result.RotDurationSeconds = result.RotRemaining or DEFAULT_ROT_DURATION
	end

	if result.IsRotImmune == nil then
		result.IsRotImmune = false
	end

	return result

end

--==================================================
-- APPLY ATTRIBUTES
--==================================================

local function applyAttributes(
	player,
	profile
)

	for _, attributeName in ipairs(
		SAVED_ATTRIBUTES
	) do

		local value =
			profile[
				attributeName
			]

		if value == nil then

			value = 0

		end

		player:SetAttribute(
			attributeName,
			value
		)

	end

end

--==================================================
-- ATTRIBUTE SAVING
--==================================================

local function connectAttributeSaving(
	player
)

	for _, attributeName in ipairs(
		SAVED_ATTRIBUTES
	) do

		player:GetAttributeChangedSignal(
			attributeName
		):Connect(
			function()

				local profile =
					profiles[
						player
					]

				if not profile then

					return

				end

				profile[
					attributeName
				] =
					player:GetAttribute(
						attributeName
					)
					or
					0

			end
		)

	end

end

--==================================================
-- INVENTORY REVISION
--==================================================

local function bumpPotatoRevision(
	player
)

	local current =
		player:GetAttribute(
			"PotatoInventoryRevision"
		)
		or
		0

	player:SetAttribute(
		"PotatoInventoryRevision",
		current + 1
	)

end

--==================================================
-- LOAD
--==================================================

local function loadPlayer(
	player
)

	player:SetAttribute(
		"DataLoaded",
		false
	)

	player:SetAttribute(
		"DataCanSave",
		false
	)

	player:SetAttribute(
		"PotatoInventoryRevision",
		0
	)

	local success,
		savedData =
			retryRequest(
				function()

					return
						store:GetAsync(
							getKey(
								player
							)
						)

				end
			)

	local profile

	if success then

		profile =
			mergeData(
				DEFAULT_DATA,
				savedData
			)

		profile =
			migrateProfile(
				profile
			)

		canSave[
			player
		] =
			true

		if savedData then

			print(
				"💾 Existing save loaded for "
				..
				player.Name
			)

		else

			print(
				"💾 New player profile created for "
				..
				player.Name
			)

		end

	else

		profile =
			deepCopy(
				DEFAULT_DATA
			)

		canSave[
			player
		] =
			false

		warn(
			"⚠ Could not load "
			..
			player.Name
			..
			"'s data."
		)

		warn(
			"⚠ Saving disabled for this session."
		)

	end

	profiles[
		player
	] =
		profile

	applyAttributes(
		player,
		profile
	)

	connectAttributeSaving(
		player
	)

	player:SetAttribute(
		"DataCanSave",
		canSave[
			player
		]
	)

	player:SetAttribute(
		"DataLoaded",
		true
	)

	print(
		"✅ Player data ready: "
		..
		player.Name
	)

end

--==================================================
-- SAVE
--==================================================

function DataService.SavePlayer(
	player
)

	local profile =
		profiles[
			player
		]

	if not profile then

		warn(
			"No profile exists for "
			..
			player.Name
		)

		return false

	end

	if not canSave[
		player
	] then

		warn(
			"Skipping save for "
			..
			player.Name
			..
			" because data did not load correctly."
		)

		return false

	end

	for _, attributeName in ipairs(
		SAVED_ATTRIBUTES
	) do

		profile[
			attributeName
		] =
			player:GetAttribute(
				attributeName
			)
			or
			0

	end

	profile.Version =
		DATA_VERSION

	profile.LastSavedAt =
		os.time()

	removeLegacyProfileKeys(
		profile
	)

	local snapshot =
		deepCopy(
			profile
		)

	local success,
		errorMessage =
			retryRequest(
				function()

					store:UpdateAsync(
						getKey(
							player
						),

						function()

							return snapshot

						end
					)

				end
			)

	if success then

		print(
			"💾 Saved "
			..
			player.Name
		)

		return true

	end

	warn(
		"❌ Could not save "
		..
		player.Name
		..
		": "
		..
		tostring(
			errorMessage
		)
	)

	return false

end

--==================================================
-- GET PROFILE
--==================================================

function DataService.GetProfile(
	player
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return nil

	end

	return
		deepCopy(
			profile
		)

end

--==================================================
-- GET POTATO INVENTORY
--==================================================

function DataService.GetPotatoInventory(
	player
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return {}

	end

	local result = {}

	for _, record in ipairs(
		profile.PotatoInventory
		or
		{}
	) do

		table.insert(
			result,
			makeLegacyShopCompatibleCopy(
				record
			)
		)

	end

	return result

end

--==================================================
-- GET POTATO
--==================================================

function DataService.GetPotatoRecord(
	player,
	potatoId
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return nil

	end

	for _, record in ipairs(
		profile.PotatoInventory
		or
		{}
	) do

		if
			record.Id
			==
			potatoId
		then

			return
				makeLegacyShopCompatibleCopy(
					record
				)

		end

	end

	return nil

end

--==================================================
-- ADD POTATO
--==================================================

function DataService.AddPotatoRecord(
	player,
	record
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return nil

	end

	if
		type(record)
		~=
		"table"
	then

		return nil

	end

	profile.PotatoInventory =
		profile.PotatoInventory
		or
		{}

	profile.NextPotatoId =
		tonumber(
			profile.NextPotatoId
		)
		or
		1

	local potatoId =
		profile.NextPotatoId

	profile.NextPotatoId +=
		1

	local rarity =
		getRecordRarity(
			record
		)

	local savedRecord = {

		Id =
			potatoId,

		PotatoType =
			normalizePotatoType(
				record.PotatoType
			),

		Rarity =
			normalizeRarity(
				rarity
			),

		Category =
			tostring(
				record.Category
				or
				(
					isMeadowPotatoType(
						normalizePotatoType(
							record.PotatoType
						)
					)
					and "Meadow"
					or "Unknown"
				)
			),

		ModelName =
			tostring(
				record.ModelName
				or
				""
			),

		TargetHeight =
			POTATO_HEIGHT,

		Mutation =
			tostring(
				record.Mutation
				or
				"None"
			),

		Source =
			tostring(
				record.Source
				or
				"Foraging"
			),

		Favorite =
			record.Favorite
			==
			true,

		PlacedFarm =
			tostring(
				record.PlacedFarm
				or
				""
			),

		PlacedSlot =
			tostring(
				record.PlacedSlot
				or
				""
			),

		MoneyPerSecond =
			math.max(
				0,
				tonumber(
					record.MoneyPerSecond
				)
				or
				0
			),

		GeneratedMoney =
			math.max(
				0,
				tonumber(
					record.GeneratedMoney
				)
				or
				0
			),

		SpudMass =
			math.clamp(tonumber(record.SpudMass) or 1, 0.01, 100),

		SizeTier =
			tostring(record.SizeTier or "1-10 kg"),

		VisualScale =
			math.max(0.01, tonumber(record.VisualScale) or 1),

		BaseSellPrice =
			math.max(0, tonumber(record.BaseSellPrice) or 0),

		SellPrice =
			math.max(0, tonumber(record.SellPrice) or tonumber(record.BaseSellPrice) or 0),

		RotDurationSeconds =
			tonumber(record.RotDurationSeconds),

		IsRotImmune =
			record.IsRotImmune == true,

		RotRemaining =
			math.max(
				0,
				tonumber(record.RotRemaining)
				or
				tonumber(record.RotDurationSeconds)
				or
				DEFAULT_ROT_DURATION
			),

		RotAt =
			math.max(
				0,
				math.floor(
					tonumber(
						record.RotAt
					)
					or
					0
				)
			),

		IsRotten =
			record.IsRotten
			==
			true,

		ActiveRotSpeedMultiplier =
			math.clamp(
				tonumber(
					record.ActiveRotSpeedMultiplier
				)
				or
				1,
				0.05,
				1
			),

		CreatedAt =
			tonumber(
				record.CreatedAt
			)
			or
			os.time(),

	}

	savedRecord.DisplayName =
		getPotatoDisplayName(
			savedRecord.Rarity,
			savedRecord.PotatoType
		)

	--==================================================
	-- SUPER / RAINBOW
	--==================================================

	if isNoRotRecord(savedRecord) then

		savedRecord.RotRemaining =
			0

		savedRecord.RotAt =
			0

		savedRecord.IsRotten =
			false

		savedRecord.ActiveRotSpeedMultiplier =
			0

	end

	table.insert(
		profile.PotatoInventory,
		savedRecord
	)

	bumpPotatoRevision(
		player
	)

	return
		deepCopy(
			savedRecord
		)

end

--==================================================
-- UPDATE POTATO
--==================================================

function DataService.UpdatePotatoRecord(
	player,
	potatoId,
	changes
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return false

	end

	if
		type(changes)
		~=
		"table"
	then

		return false

	end

	for _, record in ipairs(
		profile.PotatoInventory
		or
		{}
	) do

		if
			record.Id
			==
			potatoId
		then

			--==================================================
			-- RARITY
			--==================================================

			if changes.Rarity ~= nil then

				record.Rarity =
					normalizeRarity(
						changes.Rarity
					)

				record.DisplayName =
					getPotatoDisplayName(
						record.Rarity,
						record.PotatoType
					)

			end

			--==================================================
			-- POTATO TYPE
			--==================================================

			if changes.PotatoType ~= nil then

				record.PotatoType =
					normalizePotatoType(
						changes.PotatoType
					)

				record.DisplayName =
					getPotatoDisplayName(
						record.Rarity,
						record.PotatoType
					)

			end

			--==================================================
			-- PLACEMENT
			--==================================================

			if changes.PlacedFarm ~= nil then

				record.PlacedFarm =
					tostring(
						changes.PlacedFarm
					)

			end

			if changes.PlacedSlot ~= nil then

				record.PlacedSlot =
					tostring(
						changes.PlacedSlot
					)

			end

			--==================================================
			-- MONEY
			--==================================================

			if changes.MoneyPerSecond ~= nil then

				record.MoneyPerSecond =
					math.max(
						0,
						tonumber(
							changes.MoneyPerSecond
						)
						or
						0
					)

			end

			if changes.GeneratedMoney ~= nil then

				record.GeneratedMoney =
					math.max(
						0,
						tonumber(
							changes.GeneratedMoney
						)
						or
						0
					)

			end

			--==================================================
			-- MUTATION
			--==================================================

			if changes.Mutation ~= nil then

				record.Mutation =
					tostring(
						changes.Mutation
					)

			end

			--==================================================
			-- FAVORITE
			--==================================================

			if changes.Favorite ~= nil then

				record.Favorite =
					changes.Favorite
					==
					true

			end

			--==================================================
			-- MEADOW / KG
			--==================================================

			if changes.SpudMass ~= nil then
				record.SpudMass = math.clamp(tonumber(changes.SpudMass) or record.SpudMass or 1, 0.01, 100)
			end

			if changes.SizeTier ~= nil then
				record.SizeTier = tostring(changes.SizeTier)
			end

			if changes.VisualScale ~= nil then
				record.VisualScale = math.max(0.01, tonumber(changes.VisualScale) or record.VisualScale or 1)
			end

			if changes.BaseSellPrice ~= nil then
				record.BaseSellPrice = math.max(0, tonumber(changes.BaseSellPrice) or 0)
			end

			if changes.SellPrice ~= nil then
				record.SellPrice = math.max(0, tonumber(changes.SellPrice) or 0)
			end

			if changes.RotDurationSeconds ~= nil then
				record.RotDurationSeconds = math.max(0, tonumber(changes.RotDurationSeconds) or 0)
			end

			if changes.IsRotImmune ~= nil then
				record.IsRotImmune = changes.IsRotImmune == true
			end

			--==================================================
			-- ROT
			--==================================================

			if changes.RotRemaining ~= nil then

				record.RotRemaining =
					math.max(
						0,
						tonumber(
							changes.RotRemaining
						)
						or
						0
					)

			end

			if changes.RotAt ~= nil then

				record.RotAt =
					math.max(
						0,
						math.floor(
							tonumber(
								changes.RotAt
							)
							or
							0
						)
					)

			end

			if changes.IsRotten ~= nil then

				record.IsRotten =
					changes.IsRotten
					==
					true

			end

			if changes.ActiveRotSpeedMultiplier ~= nil then

				record.ActiveRotSpeedMultiplier =
					math.clamp(
						tonumber(
							changes.ActiveRotSpeedMultiplier
						)
						or
						1,
						0.05,
						1
					)

			end

			--==================================================
			-- SUPER / RAINBOW IMMUNITY
			--==================================================

			if isNoRotRecord(record) then

				record.RotRemaining =
					0

				record.RotAt =
					0

				record.IsRotten =
					false

				record.ActiveRotSpeedMultiplier =
					0

			end

			bumpPotatoRevision(
				player
			)

			return true

		end

	end

	return false

end

--==================================================
-- INTERNAL POTATO
--==================================================

local function findPotatoRecordInternal(
	player,
	potatoId
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return nil

	end

	for _, record in ipairs(
		profile.PotatoInventory
		or
		{}
	) do

		if
			record.Id
			==
			potatoId
		then

			return record

		end

	end

	return nil

end

--==================================================
-- ROT-PROTECTION HELPERS
--==================================================

local function getPlayerRotProtectionPercent(
	player
)

	local percent =
		BASE_ROT_PROTECTION_PERCENT

	local profile =
		profiles[
			player
		]

	if
		profile
		and
		type(
			profile.Upgrades
		)
		==
		"table"
	then

		local upgraded =
			tonumber(
				profile.Upgrades.RotProtectionPercent
			)

		if upgraded then

			percent =
				upgraded

		end

	end

	return
		math.clamp(
			percent,
			0,
			MAX_ROT_PROTECTION_PERCENT
		)

end

local function getPlacementRotSpeed(
	player,
	record
)

	if not record then

		return 1,
			0

	end

	if
		tostring(
			record.PlacedSlot
			or
			""
		)
		~=
		ROT_PROTECTION_PLOT_NAME
	then

		return 1,
			0

	end

	local percent =
		getPlayerRotProtectionPercent(
			player
		)

	local speed =
		1
		-
		(
			percent
			/
			100
		)

	return
		math.clamp(
			speed,
			0.05,
			1
		),
		percent

end

local function getAppliedProtectionPercent(
	speed
)

	speed =
		math.clamp(
			tonumber(speed)
			or
			1,
			0.05,
			1
		)

	return
		math.max(
			0,
			math.floor(
				(
					1
					-
					speed
				)
				*
				100
				+
				0.5
			)
		)

end

function DataService.GetRotProtectionPercent(
	player
)

	return
		getPlayerRotProtectionPercent(
			player
		)

end

function DataService.GetRotProtectionPlotName()

	return ROT_PROTECTION_PLOT_NAME

end

function DataService.GetDefaultRotDuration()

	return DEFAULT_ROT_DURATION

end

--==================================================
-- GET ROT STATE
--==================================================

function DataService.GetPotatoRotState(
	player,
	potatoId
)

	local record =
		findPotatoRecordInternal(
			player,
			potatoId
		)

	if not record then

		return nil

	end

	--==================================================
	-- NO ROT
	--==================================================

	if isNoRotRecord(record) then

		record.RotRemaining =
			0

		record.RotAt =
			0

		record.IsRotten =
			false

		record.ActiveRotSpeedMultiplier =
			0

		return {

			RotRemaining = 0,

			NormalEquivalentRemaining = 0,

			RotAt = 0,

			IsRotten = false,

			IsRotImmune = true,

			RotSpeedMultiplier = 0,

			RotProtectionPercent = 0,

		}

	end

	local isRotten =
		record.IsRotten
		==
		true

	local rotAt =
		math.max(
			0,
			math.floor(
				tonumber(
					record.RotAt
				)
				or
				0
			)
		)

	local normalRemaining =
		math.max(
			0,
			tonumber(
				record.RotRemaining
			)
			or
			DEFAULT_ROT_DURATION
		)

	local activeSpeed =
		math.clamp(
			tonumber(
				record.ActiveRotSpeedMultiplier
			)
			or
			1,
			0.05,
			1
		)

	local displayedRemaining =
		normalRemaining

	local protectionPercent =
		0

	if
		not isRotten
		and
		rotAt
		>
		0
	then

		displayedRemaining =
			math.max(
				0,
				rotAt
				-
				os.time()
			)

		normalRemaining =
			displayedRemaining
			*
			activeSpeed

		protectionPercent =
			getAppliedProtectionPercent(
				activeSpeed
			)

		if displayedRemaining <= 0 then

			displayedRemaining =
				0

			normalRemaining =
				0

			rotAt =
				0

			isRotten =
				true

			record.RotRemaining =
				0

			record.RotAt =
				0

			record.IsRotten =
				true

			record.ActiveRotSpeedMultiplier =
				0

		end

	end

	return {

		-- Real-world seconds before this potato rots.
		-- Farm TV uses this value.
		RotRemaining =
			displayedRemaining,

		-- Remaining life converted back to normal-speed
		-- seconds. Used when the potato is removed so
		-- the protected plot cannot duplicate time.
		NormalEquivalentRemaining =
			normalRemaining,

		RotAt =
			rotAt,

		IsRotten =
			isRotten,

		IsRotImmune =
			false,

		RotSpeedMultiplier =
			activeSpeed,

		RotProtectionPercent =
			protectionPercent,

	}

end

--==================================================
-- START / RESUME ROT
--==================================================

function DataService.StartPotatoRot(
	player,
	potatoId
)

	local record =
		findPotatoRecordInternal(
			player,
			potatoId
		)

	if not record then

		return nil

	end

	--==================================================
	-- SUPER / RAINBOW
	--==================================================

	if isNoRotRecord(record) then

		record.RotRemaining =
			0

		record.RotAt =
			0

		record.IsRotten =
			false

		record.ActiveRotSpeedMultiplier =
			0

		return {

			RotRemaining = 0,

			NormalEquivalentRemaining = 0,

			RotAt = 0,

			IsRotten = false,

			IsRotImmune = true,

			RotSpeedMultiplier = 0,

			RotProtectionPercent = 0,

		}

	end

	if
		record.IsRotten
		==
		true
	then

		record.RotRemaining =
			0

		record.RotAt =
			0

		record.ActiveRotSpeedMultiplier =
			0

		return {

			RotRemaining = 0,

			NormalEquivalentRemaining = 0,

			RotAt = 0,

			IsRotten = true,

			IsRotImmune = false,

			RotSpeedMultiplier = 0,

			RotProtectionPercent = 0,

		}

	end

	local currentRotAt =
		math.max(
			0,
			math.floor(
				tonumber(
					record.RotAt
				)
				or
				0
			)
		)

	-- Already counting. Never apply protection twice.

	if currentRotAt > 0 then

		return
			DataService.GetPotatoRotState(
				player,
				potatoId
			)

	end

	local remaining =
		math.max(
			0,
			tonumber(
				record.RotRemaining
			)
			or
			DEFAULT_ROT_DURATION
		)

	if remaining <= 0 then

		record.RotRemaining =
			0

		record.RotAt =
			0

		record.IsRotten =
			true

		record.ActiveRotSpeedMultiplier =
			0

		bumpPotatoRevision(
			player
		)

		return {

			RotRemaining = 0,

			NormalEquivalentRemaining = 0,

			RotAt = 0,

			IsRotten = true,

			IsRotImmune = false,

			RotSpeedMultiplier = 0,

			RotProtectionPercent = 0,

		}

	end

	--==================================================
	-- CURRENT PLOT SPEED
	--
	-- Normal plot: 1.00
	-- FarmLand_01 at 20% protection: 0.80
	--==================================================

	local rotSpeed,
		protectionPercent =
			getPlacementRotSpeed(
				player,
				record
			)

	local realDuration =
		remaining
		/
		rotSpeed

	record.RotRemaining =
		remaining

	record.RotAt =
		os.time()
		+
		math.ceil(
			realDuration
		)

	record.IsRotten =
		false

	record.ActiveRotSpeedMultiplier =
		rotSpeed

	bumpPotatoRevision(
		player
	)

	if protectionPercent > 0 then

		print(
			"🛡 ROT PROTECTION: "
			..
			player.Name
			..
			" | Potato #"
			..
			tostring(
				potatoId
			)
			..
			" | "
			..
			tostring(
				protectionPercent
			)
			..
			"% slower rot"
		)

	end

	return
		DataService.GetPotatoRotState(
			player,
			potatoId
		)

end

--==================================================
-- PAUSE ROT
--==================================================

function DataService.PausePotatoRot(
	player,
	potatoId
)

	local record =
		findPotatoRecordInternal(
			player,
			potatoId
		)

	if not record then

		return nil

	end

	--==================================================
	-- SUPER / RAINBOW
	--==================================================

	if isNoRotRecord(record) then

		record.RotRemaining =
			0

		record.RotAt =
			0

		record.IsRotten =
			false

		record.ActiveRotSpeedMultiplier =
			0

		return {

			RotRemaining = 0,

			NormalEquivalentRemaining = 0,

			RotAt = 0,

			IsRotten = false,

			IsRotImmune = true,

			RotSpeedMultiplier = 0,

			RotProtectionPercent = 0,

		}

	end

	if
		record.IsRotten
		==
		true
	then

		record.RotRemaining =
			0

		record.RotAt =
			0

		record.ActiveRotSpeedMultiplier =
			0

		return {

			RotRemaining = 0,

			NormalEquivalentRemaining = 0,

			RotAt = 0,

			IsRotten = true,

			IsRotImmune = false,

			RotSpeedMultiplier = 0,

			RotProtectionPercent = 0,

		}

	end

	local rotAt =
		math.max(
			0,
			math.floor(
				tonumber(
					record.RotAt
				)
				or
				0
			)
		)

	local remaining =
		math.max(
			0,
			tonumber(
				record.RotRemaining
			)
			or
			DEFAULT_ROT_DURATION
		)

	local activeSpeed =
		math.clamp(
			tonumber(
				record.ActiveRotSpeedMultiplier
			)
			or
			1,
			0.05,
			1
		)

	if rotAt > 0 then

		local realRemaining =
			math.max(
				0,
				rotAt
				-
				os.time()
			)

		-- Convert protected real time back to the
		-- equivalent normal-speed lifetime.
		--
		-- Example: 120 real sec at 0.8 speed becomes
		-- 96 normal sec when removed.

		remaining =
			realRemaining
			*
			activeSpeed

	end

	if remaining <= 0 then

		record.RotRemaining =
			0

		record.RotAt =
			0

		record.IsRotten =
			true

		record.ActiveRotSpeedMultiplier =
			0

	else

		record.RotRemaining =
			remaining

		record.RotAt =
			0

		record.IsRotten =
			false

		record.ActiveRotSpeedMultiplier =
			1

	end

	bumpPotatoRevision(
		player
	)

	return {

		RotRemaining =
			record.RotRemaining,

		NormalEquivalentRemaining =
			record.RotRemaining,

		RotAt =
			record.RotAt,

		IsRotten =
			record.IsRotten,

		IsRotImmune =
			false,

		RotSpeedMultiplier =
			1,

		RotProtectionPercent =
			0,

	}

end

--==================================================
-- SET PLACED
--==================================================

function DataService.SetPotatoPlaced(
	player,
	potatoId,
	farmName,
	farmLandName
)

	local success =
		DataService.UpdatePotatoRecord(
			player,
			potatoId,

			{

				PlacedFarm =
					farmName
					or
					"",

				PlacedSlot =
					farmLandName
					or
					"",

			}
		)

	if not success then

		return false

	end

	DataService.StartPotatoRot(
		player,
		potatoId
	)

	return true

end

--==================================================
-- CLEAR PLACEMENT
--
-- Pauses timer BEFORE clearing plot.
--==================================================

function DataService.ClearPotatoPlaced(
	player,
	potatoId
)

	DataService.PausePotatoRot(
		player,
		potatoId
	)

	return
		DataService.UpdatePotatoRecord(
			player,
			potatoId,

			{

				PlacedFarm = "",

				PlacedSlot = "",

				MoneyPerSecond = 0,

			}
		)

end

--==================================================
-- ADD GENERATED MONEY
--==================================================

function DataService.AddPotatoGeneratedMoney(
	player,
	potatoId,
	amount
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return nil

	end

	amount =
		math.max(
			0,
			tonumber(
				amount
			)
			or
			0
		)

	for _, record in ipairs(
		profile.PotatoInventory
		or
		{}
	) do

		if
			record.Id
			==
			potatoId
		then

			record.GeneratedMoney =
				(
					tonumber(
						record.GeneratedMoney
					)
					or
					0
				)
				+
				amount

			return
				record.GeneratedMoney

		end

	end

	return nil

end

--==================================================
-- REMOVE POTATO
--==================================================

function DataService.RemovePotatoRecord(
	player,
	potatoId
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return false

	end

	local inventory =
		profile.PotatoInventory
		or
		{}

	for index, record in ipairs(
		inventory
	) do

		if
			record.Id
			==
			potatoId
		then

			table.remove(
				inventory,
				index
			)

			bumpPotatoRevision(
				player
			)

			return true

		end

	end

	return false

end

--==================================================
-- OLD SHOP TIER → RARITY
--==================================================

local function tierArgumentToRarity(
	value
)

	if
		VALID_RARITIES[
			value
		]
	then

		return value

	end

	if
		OLD_RARITY_TO_NEW_RARITY[
			value
		]
	then

		return
			OLD_RARITY_TO_NEW_RARITY[
				value
			]

	end

	return
		OLD_TIER_TO_RARITY[
			value
		]

end

--==================================================
-- REMOVE BY RARITY / OLD TIER
--==================================================

function DataService.RemovePotatoRecordsByTier(
	player,
	tier,
	amount
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return 0

	end

	local rarity =
		tierArgumentToRarity(
			tier
		)

	if not rarity then

		return 0

	end

	amount =
		math.max(
			0,
			math.floor(
				tonumber(
					amount
				)
				or
				0
			)
		)

	if amount <= 0 then

		return 0

	end

	local inventory =
		profile.PotatoInventory
		or
		{}

	local removed = 0

	for index = #inventory, 1, -1 do

		if removed >= amount then

			break

		end

		local record =
			inventory[
				index
			]

		if
			record.Rarity
			==
			rarity
		then

			table.remove(
				inventory,
				index
			)

			removed +=
				1

		end

	end

	if removed > 0 then

		bumpPotatoRevision(
			player
		)

	end

	return removed

end

--==================================================
-- COUNT BY RARITY / OLD TIER
--==================================================

function DataService.CountPotatoRecordsByTier(
	player,
	tier
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return 0

	end

	local rarity =
		tierArgumentToRarity(
			tier
		)

	if not rarity then

		return 0

	end

	local count = 0

	for _, record in ipairs(
		profile.PotatoInventory
		or
		{}
	) do

		if
			record.Rarity
			==
			rarity
		then

			count +=
				1

		end

	end

	return count

end

--==================================================
-- COUNT BY RARITY
--==================================================

function DataService.CountPotatoRecordsByRarity(
	player,
	rarity
)

	return
		DataService.CountPotatoRecordsByTier(
			player,
			rarity
		)

end

--==================================================
-- CLEAR POTATO INVENTORY
--==================================================

function DataService.ClearPotatoInventory(
	player
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return

	end

	profile.PotatoInventory = {}

	bumpPotatoRevision(
		player
	)

end

--==================================================
-- PLANT STATES
--==================================================

function DataService.GetPlantStates(
	player
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return {}

	end

	return
		deepCopy(
			profile.PlantStates
			or
			{}
		)

end

function DataService.SetPlantState(
	player,
	pointKey,
	state
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return

	end

	profile.PlantStates =
		profile.PlantStates
		or
		{}

	profile.PlantStates[
		pointKey
	] =
		deepCopy(
			state
		)

end

function DataService.RemovePlantState(
	player,
	pointKey
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return

	end

	if not profile.PlantStates then

		return

	end

	profile.PlantStates[
		pointKey
	] =
		nil

end

--==================================================
-- EQUIPMENT
--==================================================

function DataService.GetEquipment(
	player
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return {}

	end

	return
		deepCopy(
			profile.Equipment
			or
			{}
		)

end

function DataService.SetEquipment(
	player,
	equipmentTable
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return

	end

	profile.Equipment =
		deepCopy(
			equipmentTable
		)

end

--==================================================
-- UPGRADES
--==================================================

function DataService.GetUpgrades(
	player
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return {}

	end

	return
		deepCopy(
			profile.Upgrades
			or
			{}
		)

end

function DataService.SetUpgrades(
	player,
	upgradeTable
)

	local profile =
		profiles[
			player
		]

	if not profile then

		return

	end

	profile.Upgrades =
		deepCopy(
			upgradeTable
		)

end

--==================================================
-- WAIT FOR DATA
--==================================================

function DataService.WaitForData(
	player
)

	while
		player.Parent
		and
		player:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	do

		task.wait(
			0.05
		)

	end

	return
		profiles[
			player
		]

end

--==================================================
-- LOADED?
--==================================================

function DataService.IsLoaded(
	player
)

	return
		player:GetAttribute(
			"DataLoaded"
		)
		==
		true

end

--==================================================
-- START SERVICE
--==================================================

function DataService.Start()

	if started then

		return

	end

	started = true

	--==================================================
	-- JOIN
	--==================================================

	Players.PlayerAdded:Connect(
		function(
			player
		)

			task.spawn(
				loadPlayer,
				player
			)

		end
	)

	--==================================================
	-- LEAVE
	--==================================================

	Players.PlayerRemoving:Connect(
		function(
			player
		)

			DataService.SavePlayer(
				player
			)

			profiles[
				player
			] =
				nil

			canSave[
				player
			] =
				nil

		end
	)

	--==================================================
	-- EXISTING PLAYERS
	--==================================================

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		task.spawn(
			loadPlayer,
			player
		)

	end

	--==================================================
	-- AUTOSAVE
	--==================================================

	task.spawn(
		function()

			while true do

				task.wait(
					AUTOSAVE_TIME
				)

				for _, player in ipairs(
					Players:GetPlayers()
				) do

					task.spawn(
						function()

							DataService.SavePlayer(
								player
							)

						end
					)

				end

			end

		end
	)

	--==================================================
	-- SHUTDOWN SAVE
	--==================================================

	game:BindToClose(
		function()

			print(
				"💾 Server shutting down..."
			)

			local remaining = 0

			for _, player in ipairs(
				Players:GetPlayers()
			) do

				remaining +=
					1

				task.spawn(
					function()

						DataService.SavePlayer(
							player
						)

						remaining -=
							1

					end
				)

			end

			local startTime =
				os.clock()

			while
				remaining > 0
				and
				os.clock()
				-
				startTime
				<
				10
			do

				task.wait(
					0.1
				)

			end

			print(
				"💾 Shutdown save finished."
			)

		end
	)

	--==================================================
	-- READY
	--==================================================

	print("")
	print("========================================")
	print("💾 DATA SERVICE V4.3 - PERSISTENT FAVORITES")
	print("========================================")
	print("Store: " .. STORE_NAME)
	print("Autosave: " .. AUTOSAVE_TIME .. " sec")
	print("----------------------------------------")
	print("🥔 Meadow potato types:")
	print("✅ Basic / Big / Butter / Feather / Flower")
	print("✅ Golden / Grass / Lucky / Prism / Star / Sunkissed")
	print("----------------------------------------")
	print("✅ Meadow PotatoType now saves correctly")
	print("✅ Legacy Normal/Potato → Basic")
	print("✅ Meadow DisplayName uses exact potato type")
	print("✅ KG / visual / sell / rot fields preserved")
	print("----------------------------------------")
	print("✅ Placement data preserved")
	print("✅ GeneratedMoney preserved")
	print("✅ Collector / Upgrades preserved")
	print("❤️ Potato Favorite now saves in each record")
	print("✅ Studio rot timer = " .. STUDIO_ROT_DURATION .. " sec")
	print("✅ Live rot timer = 3 days")
	print("🛡 " .. ROT_PROTECTION_PLOT_NAME .. " = " .. BASE_ROT_PROTECTION_PERCENT .. "% slower rot")
	print("✅ Remove pauses rot")
	print("✅ Re-place resumes rot")
	print("♾ Super = NO ROT")
	print("🌈 Rainbow = NO ROT")
	print("========================================")
	print("")

end

return DataService