local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ForagingService = {}

local DataService = require(script.Parent:WaitForChild("DataService"))
local MeadowPool = require(
	script.Parent
		:WaitForChild("ForagingPools")
		:WaitForChild("MeadowPool")
)

local SpudMassService = require(
	script.Parent:WaitForChild("SpudMassService")
)

local HoeConfig = require(
	script.Parent
		:WaitForChild("Hoes")
		:WaitForChild("HoeConfig")
)

--==================================================
-- FORAGING SERVICE V10 - HOE STATS + PLAYER LEVEL / XP
--
-- ZONE 1 - MEADOW
--
-- Keeps the working V9 digging flow/remotes.
-- Adds:
--   Wooden: 25 durability, normal speed
--   Stone:  40 durability, +10% speed, 5% extra potato
--   Iron:   60 durability, +15% speed, 8% better reroll
--
-- Durability is consumed once per SUCCESSFUL completed dig.
--==================================================

local DIG_TIME = 6
local DIG_COOLDOWN = 0.5
local MAX_MOVE_RADIUS = 6
local MAX_START_SPOT_DISTANCE = 12

local random = Random.new()

--==================================================
-- PLAYER LEVEL / XP
--
-- Every successful completed dig gives 2-4 XP.
-- Level 2 requires 100 XP.
-- Each next level requires 12% more XP than the
-- previous level.
--
-- XP is awarded exactly once per successful dig,
-- regardless of Stone Hoe extra-potato rolls.
--==================================================

local XP_MIN_PER_DIG = 2
local XP_MAX_PER_DIG = 4
local BASE_XP_TO_NEXT_LEVEL = 100
local XP_GROWTH = 1.12

local function getXPRequiredForLevel(level)
	level = math.max(1, math.floor(tonumber(level) or 1))

	return math.max(
		1,
		math.floor(
			BASE_XP_TO_NEXT_LEVEL
			*
			(XP_GROWTH ^ (level - 1))
		)
	)
end

local function awardDigXP(player)
	local currentLevel = math.max(
		1,
		math.floor(
			tonumber(
				player:GetAttribute("Level")
			)
			or
			1
		)
	)

	local currentXP = math.max(
		0,
		math.floor(
			tonumber(
				player:GetAttribute("XP")
			)
			or
			0
		)
	)

	local gainedXP = random:NextInteger(
		XP_MIN_PER_DIG,
		XP_MAX_PER_DIG
	)

	currentXP += gainedXP

	local levelUps = 0

	while true do
		local required = getXPRequiredForLevel(currentLevel)

		if currentXP < required then
			break
		end

		currentXP -= required
		currentLevel += 1
		levelUps += 1
	end

	player:SetAttribute("Level", currentLevel)
	player:SetAttribute("XP", currentXP)

	if levelUps > 0 then
		print(
			"🎉 "
			.. player.Name
			.. " reached Level "
			.. tostring(currentLevel)
		)
	end

	print(
		"✨ "
		.. player.Name
		.. " gained "
		.. tostring(gainedXP)
		.. " XP | LV."
		.. tostring(currentLevel)
		.. " | "
		.. tostring(currentXP)
		.. "/"
		.. tostring(getXPRequiredForLevel(currentLevel))
	)

	return gainedXP, currentLevel, currentXP
end

local world = nil
local foragingZone = nil
local activeDigs = {}
local lastDigTimes = {}
local nextDigId = 0
local started = false

--==================================================
-- REMOTES
--==================================================

local remoteFolder = ReplicatedStorage:FindFirstChild("ForagingRemotes")

if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "ForagingRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local function getRemote(name)
	local remote = remoteFolder:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteFolder
	end

	return remote
end

local RequestDig = getRemote("RequestDig")
local CancelDig = getRemote("CancelDig")
local DigStarted = getRemote("DigStarted")
local DigCancelled = getRemote("DigCancelled")
local DigFinished = getRemote("DigFinished")

--==================================================
-- CHARACTER
--==================================================

local function getCharacter(player)
	return player.Character
end

local function getRoot(player)
	local character = getCharacter(player)

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- EQUIPPED HOE / HOE STATS
--==================================================

local function getEquippedHoe(player)
	local character = getCharacter(player)

	if not character then
		return nil
	end

	for _, object in ipairs(character:GetChildren()) do
		if object:IsA("Tool") then
			local tier =
				HoeConfig.InferTier(
					object
				)

			if
				object:GetAttribute(
					"FarmingToolType"
				)
				==
				"Hoe"
				or
				tier
			then
				if tier then
					HoeConfig.ApplyAttributes(
						object,
						tier
					)
				end

				return object
			end
		end
	end

	return nil
end

local function getHoeTier(
	hoe
)
	return
		HoeConfig.InferTier(
			hoe
		)
		or
		"Wooden"
end

local function getHoeStats(
	hoe
)
	if not hoe then
		return nil, nil
	end

	local tier =
		getHoeTier(
			hoe
		)

	local stats =
		HoeConfig.Get(
			tier
		)

	if stats then
		HoeConfig.ApplyAttributes(
			hoe,
			tier
		)
	end

	return tier, stats
end

local function getHoeDigTime(
	hoe
)
	local _, stats =
		getHoeStats(
			hoe
		)

	local speedBonus =
		stats
		and
		tonumber(
			stats.DigSpeedBonus
		)
		or
		0

	speedBonus =
		math.clamp(
			speedBonus,
			0,
			0.80
		)

	-- +10% speed = 10% less waiting time.
	return
		math.max(
			0.75,
			DIG_TIME
			*
			(
				1
				-
				speedBonus
			)
		)
end

local function bumpHoeRevision(
	player
)
	player:SetAttribute(
		"HoeInventoryRevision",
		(
			player:GetAttribute(
				"HoeInventoryRevision"
			)
			or
			0
		)
		+
		1
	)
end

local function updateSavedHoeDurability(
	player,
	hoeId,
	newDurability
)
	if hoeId == nil then
		return false
	end

	local equipment =
		DataService.GetEquipment(
			player
		)

	if type(equipment) ~= "table" then
		return false
	end

	if
		type(
			equipment.HoeInventory
		)
		~=
		"table"
	then
		return false
	end

	local wantedId =
		tostring(
			hoeId
		)

	local found =
		false

	for index =
		#equipment.HoeInventory,
		1,
		-1
	do
		local record =
			equipment.HoeInventory[
				index
			]

		if
			type(record)
			==
			"table"
			and
			tostring(
				record.Id
				or
				""
			)
			==
			wantedId
		then
			found =
				true

			if
				newDurability
				<=
				0
			then
				table.remove(
					equipment.HoeInventory,
					index
				)
			else
				record.Durability =
					newDurability
			end

			break
		end
	end

	if found then
		DataService.SetEquipment(
			player,
			equipment
		)

		bumpHoeRevision(
			player
		)
	end

	return found
end

local function consumeHoeDurability(
	player,
	hoe
)
	if
		not hoe
		or
		not hoe.Parent
	then
		return nil, false
	end

	local tier, stats =
		getHoeStats(
			hoe
		)

	if not stats then
		return nil, false
	end

	local maxDurability =
		tonumber(
			stats.MaxDurability
		)
		or
		1

	local current =
		tonumber(
			hoe:GetAttribute(
				"Durability"
			)
		)
		or
		maxDurability

	local remaining =
		math.max(
			0,
			math.floor(
				current
			)
			-
			1
		)

	hoe:SetAttribute(
		"Durability",
		remaining
	)

	hoe:SetAttribute(
		"MaxDurability",
		maxDurability
	)

	local hoeId =
		hoe:GetAttribute(
			"HoeId"
		)

	if hoeId ~= nil then
		updateSavedHoeDurability(
			player,
			hoeId,
			remaining
		)
	end

	local broke =
		remaining
		<=
		0

	if broke then
		print(
			"💥 "
			..
			player.Name
			..
			"'s "
			..
			tier
			..
			" Hoe broke"
		)

		task.defer(
			function()
				if
					hoe
					and
					hoe.Parent
				then
					hoe:Destroy()
				end
			end
		)
	end

	return remaining, broke
end

local function sameHoe(
	a,
	b
)
	if a == b then
		return true
	end

	if
		not a
		or
		not b
	then
		return false
	end

	local aId =
		a:GetAttribute(
			"HoeId"
		)

	local bId =
		b:GetAttribute(
			"HoeId"
		)

	return
		aId ~= nil
		and
		bId ~= nil
		and
		tostring(aId)
		==
		tostring(bId)
end

--==================================================
-- ZONE HELPERS
--==================================================

local function findZone(zoneNumber)
	if not foragingZone then
		return nil
	end

	for _, object in ipairs(foragingZone:GetChildren()) do
		if object:IsA("Model") and object:GetAttribute("ZoneNumber") == zoneNumber then
			return object
		end
	end

	return nil
end

local function findGround(zoneNumber)
	local zone = findZone(zoneNumber)

	if not zone then
		return nil
	end

	local ground = zone:FindFirstChild("Ground")

	if ground and ground:IsA("BasePart") then
		return ground
	end

	return nil
end

local function pointInsideGround(ground, position)
	local localPosition = ground.CFrame:PointToObjectSpace(position)
	local half = ground.Size / 2

	return math.abs(localPosition.X) <= half.X
		and math.abs(localPosition.Z) <= half.Z
		and localPosition.Y >= -half.Y - 3
		and localPosition.Y <= half.Y + 5
end

local function isInZone1(player)
	local root = getRoot(player)

	if not root then
		return false
	end

	local ground = findGround(1)

	if not ground then
		return false
	end

	return pointInsideGround(ground, root.Position)
end

local function validateDigSpot(player, digSpot)
	if typeof(digSpot) ~= "Vector3" then
		return false
	end

	local root = getRoot(player)

	if not root then
		return false
	end

	local ground = findGround(1)

	if not ground then
		return false
	end

	if not pointInsideGround(ground, digSpot) then
		return false
	end

	local distance = (root.Position - digSpot).Magnitude

	if distance > MAX_START_SPOT_DISTANCE then
		return false
	end

	return true
end

--==================================================
-- PLAYER SETUP
--==================================================

local function setupPlayer(player)
	if player:GetAttribute("HoeLevel") == nil then
		player:SetAttribute("HoeLevel", 1)
	end

	if player:GetAttribute("Level") == nil then
		player:SetAttribute("Level", 1)
	end

	if player:GetAttribute("XP") == nil then
		player:SetAttribute("XP", 0)
	end

	if player:GetAttribute("HoeTier") == nil then
		player:SetAttribute("HoeTier", "Wooden")
	end

	if player:GetAttribute("ForagedPotatoes") == nil then
		player:SetAttribute("ForagedPotatoes", 0)
	end

	-- No Common/Rare/Epic/etc. foraging counters are created here anymore.
end

--==================================================
-- POTATO HELPERS
--==================================================

local MEADOW_MODEL_FOLDER =
	"newpotatoes"

local STUDIO_DAY_SECONDS =
	60

local LIVE_DAY_SECONDS =
	86400

local function getPotatoTypeId(
	potatoName
)
	local name =
		tostring(
			potatoName
			or
			"Basic Potato"
		)

	local result =
		string.gsub(
			name,
			"%s+Potato$",
			""
		)

	if
		result == ""
		or
		result == "Normal"
		or
		result == "NormalPotato"
		or
		result == "BasicPotato"
	then
		return "Basic"
	end

	if
		result == "Sun-Kissed"
		or
		result == "Sun-KissedPotato"
		or
		result == "SunKissedPotato"
	then
		return "Sunkissed"
	end

	return result
end

local function getMeadowModel(
	modelName
)
	local folder =
		ReplicatedStorage:FindFirstChild(
			MEADOW_MODEL_FOLDER
		)

	if not folder then
		return nil
	end

	local model =
		folder:FindFirstChild(
			tostring(
				modelName
				or
				""
			)
		)

	if
		model
		and
		model:IsA("Model")
	then
		return model
	end

	local fallback =
		folder:FindFirstChild(
			"basic_potato"
		)

	if
		fallback
		and
		fallback:IsA("Model")
	then
		return fallback
	end

	return nil
end

local function getRotDurationSeconds(
	potato
)
	if
		potato.NoRot
		==
		true
	then
		return 0
	end

	local days =
		tonumber(
			potato.RotDays
		)
		or
		0

	if days <= 0 then
		return nil
	end

	local perDay =
		RunService:IsStudio()
		and
		STUDIO_DAY_SECONDS
		or
		LIVE_DAY_SECONDS

	return days * perDay
end

local function givePotato(
	player,
	potato
)
	if
		type(potato)
		~=
		"table"
	then
		return nil
	end

	local potatoName =
		tostring(
			potato.Name
			or
			"Basic Potato"
		)

	local potatoType =
		getPotatoTypeId(
			potatoName
		)

	local massRoll =
		SpudMassService.Roll(
			random
		)

	-- SpudMassService.Roll returns the size data directly.
	-- The older GetVisualScaleForModel helper no longer exists, which
	-- prevented DigFinished from being sent after a completed dig.
	local visualScale =
		tonumber(
			massRoll.VisualScale
		)
		or
		1

	local rotDurationSeconds =
		getRotDurationSeconds(
			potato
		)

	local mass =
		tonumber(
			massRoll.SpudMass
		)
		or
		1

	local baseSellPrice =
		math.max(
			0,
			tonumber(
				potato.SellValue
			)
			or
			0
		)

	local sellPrice =
		math.max(
			0,
			math.floor(
				(mass / 10)
				*
				baseSellPrice
				+
				0.5
			)
		)

	local record =
		DataService.AddPotatoRecord(
			player,
			{
				PotatoType =
					potatoType,

				Rarity =
					potato.Rarity
					or
					"Common",

				Category =
					potato.Category
					or
					(
						potato.NoRot
						and
						"Transcendent"
						or
						"Meadow"
					),

				ModelName =
					potato.ModelName,

				TargetHeight =
					2.5,

				Mutation =
					"None",

				Source =
					"Foraging",

				MoneyPerSecond =
					tonumber(
						potato.GoldPerSecond
					)
					or
					0,

				SpudMass =
					mass,

				SizeTier =
					massRoll.SizeTier,

				VisualScale =
					visualScale,

				BaseSellPrice =
					baseSellPrice,

				SellPrice =
					sellPrice,

				RotDurationSeconds =
					rotDurationSeconds,

				IsRotImmune =
					potato.NoRot
					==
					true,
			}
		)

	if not record then
		warn(
			"❌ Failed to add "
				..
				potatoName
				..
				" for "
				..
				player.Name
		)

		return nil
	end

	player:SetAttribute(
		"ForagedPotatoes",
		(
			player:GetAttribute(
				"ForagedPotatoes"
			)
			or
			0
		)
		+
		1
	)

	player:SetAttribute(
		"Potatoes",
		(
			player:GetAttribute(
				"Potatoes"
			)
			or
			0
		)
		+
		1
	)

	print(
		"🥔 "
		..
		player.Name
		..
		" found "
		..
		potatoName
		..
		" | "
		..
		SpudMassService.FormatMass(
			mass
		)
		..
		" | Sell $"
		..
		tostring(
			sellPrice
		)
	)

	return record
end

local function chooseBetterPotato(
	first,
	second
)
	if not first then
		return second
	end

	if not second then
		return first
	end

	local firstOneIn =
		tonumber(
			first.OneIn
		)
		or
		1

	local secondOneIn =
		tonumber(
			second.OneIn
		)
		or
		1

	if
		secondOneIn
		>
		firstOneIn
	then
		return second
	end

	return first
end

--==================================================
-- CANCEL DIG
--==================================================

local function cancelDig(player, reason, expectedDigId)
	local dig = activeDigs[player]

	if not dig then
		return
	end

	if expectedDigId and dig.Id ~= expectedDigId then
		return
	end

	activeDigs[player] = nil

	DigCancelled:FireClient(
		player,
		reason or "Cancelled",
		dig.Id
	)

	print(
		"❌ DIG CANCELLED: "
			.. player.Name
			.. " | "
			.. tostring(reason)
			.. " | ID "
			.. tostring(dig.Id)
	)
end

--==================================================
-- COMPLETE DIG
--==================================================

local function completeDig(player, expectedDigId)
	local dig =
		activeDigs[
			player
		]

	if not dig then
		return
	end

	if
		dig.Id
		~=
		expectedDigId
	then
		return
	end

	local hoe =
		getEquippedHoe(
			player
		)

	if not hoe then
		cancelDig(
			player,
			"Hoe unequipped",
			expectedDigId
		)

		return
	end

	if
		not sameHoe(
			hoe,
			dig.Hoe
		)
	then
		cancelDig(
			player,
			"Hoe changed",
			expectedDigId
		)

		return
	end

	if not isInZone1(player) then
		cancelDig(
			player,
			"Left Zone 1",
			expectedDigId
		)

		return
	end

	local root =
		getRoot(
			player
		)

	if not root then
		cancelDig(
			player,
			"Character missing",
			expectedDigId
		)

		return
	end

	local moved =
		(
			root.Position
			-
			dig.StartPosition
		).Magnitude

	if moved > MAX_MOVE_RADIUS then
		cancelDig(
			player,
			"Too far",
			expectedDigId
		)

		return
	end

	local now =
		Workspace:GetServerTimeNow()

	if
		now
		<
		dig.EndServerTime
	then
		local remaining =
			dig.EndServerTime
			-
			now

		task.delay(
			remaining,
			function()
				completeDig(
					player,
					expectedDigId
				)
			end
		)

		return
	end

	activeDigs[player] =
		nil

	local hoeTier, hoeStats =
		getHoeStats(
			hoe
		)

	--==================================================
	-- PRIMARY MEADOW ROLL
	--==================================================

	local potato =
		MeadowPool.Roll(
			random
		)

	if not potato then
		warn(
			"❌ MeadowPool returned no potato"
		)

		DigFinished:FireClient(
			player,
			{
				Type = "Nothing",
				Zone = 1,
				DigId =
					expectedDigId,
			}
		)

		return
	end

	--==================================================
	-- IRON BUFF
	--
	-- 8% chance to roll again and keep the potato
	-- with the higher OneIn number.
	--==================================================

	local betterRollTriggered =
		false

	local betterRollChance =
		hoeStats
		and
		tonumber(
			hoeStats.BetterRollChance
		)
		or
		0

	if
		betterRollChance > 0
		and
		random:NextNumber()
		<
		betterRollChance
	then
		betterRollTriggered =
			true

		local secondRoll =
			MeadowPool.Roll(
				random
			)

		local originalName =
			potato.Name

		potato =
			chooseBetterPotato(
				potato,
				secondRoll
			)

		print(
			"✨ "
			..
			player.Name
			..
			" Iron better-roll: "
			..
			tostring(
				originalName
			)
			..
			" vs "
			..
			tostring(
				secondRoll
				and
				secondRoll.Name
				or
				"nil"
			)
			..
			" -> "
			..
			tostring(
				potato.Name
			)
		)
	end

	local record =
		givePotato(
			player,
			potato
		)

	if not record then
		DigFinished:FireClient(
			player,
			{
				Type = "Nothing",
				Zone = 1,
				DigId =
					expectedDigId,
			}
		)

		return
	end

	--==================================================
	-- DIG XP
	--
	-- One XP reward per successful completed dig.
	-- Extra Stone Hoe potatoes do not grant extra XP.
	--==================================================

	awardDigXP(player)

	--==================================================
	-- STONE BUFF
	--
	-- 5% chance to receive one EXTRA copy of the
	-- potato that was successfully found.
	--==================================================

	local extraPotato =
		false

	local extraChance =
		hoeStats
		and
		tonumber(
			hoeStats.ExtraPotatoChance
		)
		or
		0

	if
		extraChance > 0
		and
		random:NextNumber()
		<
		extraChance
	then
		local extraRecord =
			givePotato(
				player,
				potato
			)

		if extraRecord then
			extraPotato =
				true

			print(
				"🥔➕ "
				..
				player.Name
				..
				" got an EXTRA "
				..
				tostring(
					potato.Name
				)
			)
		end
	end

	-- One durability is consumed PER COMPLETED DIG,
	-- not per animation swing and not per potato.
	local hoeDurability,
		hoeBroke =
			consumeHoeDurability(
				player,
				hoe
			)

	DigFinished:FireClient(
		player,
		{
			Type = "Potato",
			PotatoType =
				getPotatoTypeId(
					potato.Name
				),
			DisplayName =
				potato.Name,
			Rarity =
				potato.Rarity
				or
				"Common",
			GoldPerSecond =
				potato.GoldPerSecond,
			SellValue =
				potato.SellValue,
			BaseSellPrice =
				record.BaseSellPrice,
			SellPrice =
				record.SellPrice,
			SpudMass =
				record.SpudMass,
			SizeTier =
				record.SizeTier,
			VisualScale =
				record.VisualScale,
			ModelName =
				record.ModelName,
			IsTranscendent =
				potato.NoRot == true,
			Category =
				potato.Category,
			TargetHeight =
				record.TargetHeight
				or
				2.5,
			Mutation =
				record.Mutation
				or
				"None",
			Zone = 1,
			DigId =
				expectedDigId,

			-- New V10 fields.
			HoeTier =
				hoeTier,
			HoeDurability =
				hoeDurability,
			HoeMaxDurability =
				hoeStats
				and
				hoeStats.MaxDurability
				or
				nil,
			HoeBroke =
				hoeBroke,
			ExtraPotato =
				extraPotato,
			BetterRollTriggered =
				betterRollTriggered,
		}
	)
end

--==================================================
-- START DIG
--==================================================

local function startDig(player, digSpot)
	if activeDigs[player] then
		return
	end

	if
		player:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	then
		warn(
			"❌ DIG REJECTED: "
			..
			player.Name
			..
			" | Data not loaded"
		)

		return
	end

	local hoe =
		getEquippedHoe(
			player
		)

	if not hoe then
		warn(
			"❌ DIG REJECTED: "
			..
			player.Name
			..
			" | Hoe not equipped"
		)

		return
	end

	local hoeTier, hoeStats =
		getHoeStats(
			hoe
		)

	if not hoeStats then
		warn(
			"❌ DIG REJECTED: "
			..
			player.Name
			..
			" | Unknown hoe"
		)

		return
	end

	local currentDurability =
		tonumber(
			hoe:GetAttribute(
				"Durability"
			)
		)
		or
		hoeStats.MaxDurability

	if currentDurability <= 0 then
		warn(
			"❌ DIG REJECTED: "
			..
			player.Name
			..
			" | Hoe broken"
		)

		return
	end

	if not isInZone1(player) then
		warn(
			"❌ DIG REJECTED: "
			..
			player.Name
			..
			" | Not inside Zone 1"
		)

		return
	end

	if
		not validateDigSpot(
			player,
			digSpot
		)
	then
		warn(
			"❌ DIG REJECTED: "
			..
			player.Name
			..
			" | Invalid dig spot"
		)

		return
	end

	local root =
		getRoot(
			player
		)

	if not root then
		return
	end

	local now =
		os.clock()

	local previous =
		lastDigTimes[
			player
		]
		or
		0

	if
		now - previous
		<
		DIG_COOLDOWN
	then
		return
	end

	lastDigTimes[player] =
		now

	nextDigId += 1

	local digId =
		nextDigId

	local digTime =
		getHoeDigTime(
			hoe
		)

	local startServerTime =
		Workspace:GetServerTimeNow()

	local endServerTime =
		startServerTime
		+
		digTime

	activeDigs[player] = {
		Id = digId,
		StartPosition =
			root.Position,
		DigSpot =
			digSpot,
		StartServerTime =
			startServerTime,
		EndServerTime =
			endServerTime,
		DigTime =
			digTime,

		-- Lock this dig to the exact hoe used to start it.
		Hoe =
			hoe,
		HoeId =
			hoe:GetAttribute(
				"HoeId"
			),
		HoeTier =
			hoeTier,
	}

	print(
		"⛏ DIG STARTED: "
		..
		player.Name
		..
		" | "
		..
		hoeTier
		..
		" | "
		..
		string.format(
			"%.2fs",
			digTime
		)
		..
		" | DUR "
		..
		tostring(
			currentDurability
		)
		..
		"/"
		..
		tostring(
			hoeStats.MaxDurability
		)
		..
		" | ID "
		..
		tostring(
			digId
		)
	)

	DigStarted:FireClient(
		player,
		digTime,
		digId,
		digSpot,
		endServerTime
	)

	task.delay(
		digTime,
		function()
			completeDig(
				player,
				digId
			)
		end
	)
end

--==================================================
-- ACTIVE DIG CHECK
--==================================================

local function checkActiveDig(player, dig)
	if not dig then
		return
	end

	local root =
		getRoot(
			player
		)

	if not root then
		cancelDig(
			player,
			"Character missing",
			dig.Id
		)

		return
	end

	local hoe =
		getEquippedHoe(
			player
		)

	if not hoe then
		cancelDig(
			player,
			"Hoe unequipped",
			dig.Id
		)

		return
	end

	if
		not sameHoe(
			hoe,
			dig.Hoe
		)
	then
		cancelDig(
			player,
			"Hoe changed",
			dig.Id
		)

		return
	end

	if not isInZone1(player) then
		cancelDig(
			player,
			"Left Zone 1",
			dig.Id
		)

		return
	end

	local movementDistance =
		(
			root.Position
			-
			dig.StartPosition
		).Magnitude

	if
		movementDistance
		>
		MAX_MOVE_RADIUS
	then
		cancelDig(
			player,
			"Too far",
			dig.Id
		)
	end
end

--==================================================
-- START SERVICE
--==================================================

function ForagingService.Start(potatoWorld)
	if started then
		return
	end

	started = true
	world = potatoWorld
	foragingZone = world:FindFirstChild("ForagingZone")

	if not foragingZone then
		warn("❌ ForagingZone missing")
		return
	end

	local zone1 = findZone(1)
	local ground1 = findGround(1)

	if zone1 then
		print("✅ Zone 1 detected: " .. zone1:GetFullName())
	else
		warn("❌ Zone 1 missing")
	end

	if ground1 then
		print("✅ Zone 1 Ground detected: " .. ground1:GetFullName())
	else
		warn("❌ Zone 1 Ground missing")
	end

	Players.PlayerAdded:Connect(setupPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	RequestDig.OnServerEvent:Connect(function(player, digSpot)
		startDig(player, digSpot)
	end)

	CancelDig.OnServerEvent:Connect(function(player, reason, digId)
		cancelDig(player, reason, digId)
	end)

	RunService.Heartbeat:Connect(function()
		for player, dig in pairs(activeDigs) do
			checkActiveDig(player, dig)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		activeDigs[player] = nil
		lastDigTimes[player] = nil
	end)

	print("")
	print("========================================")
	print("⛏ FORAGING SERVICE V10 - HOE V2")
	print("========================================")
	print("🌿 ZONE 1 - MEADOW")
	print("----------------------------------------")
	print("✅ MeadowPool connected")
	print("✅ 11 Meadow potato types")
	print("❌ Old rarity roll removed")
	print("✅ Existing digging remotes preserved")
	print("✅ Multiplayer supported")
	print("✅ Wooden = 6.00 sec | 25 durability")
	print("✅ Stone  = 5.40 sec | 40 durability | 5% extra potato")
	print("✅ Iron   = 5.10 sec | 60 durability | 8% better reroll")
	print("✅ Durability consumed once per successful dig")
	print("✅ Dig XP = 2-4 per successful dig")
	print("✅ Level 2 = 100 XP")
	print("✅ XP curve = +12% per level")
	print("========================================")
	print("")
end

return ForagingService
