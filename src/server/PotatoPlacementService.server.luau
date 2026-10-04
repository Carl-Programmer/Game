local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--==================================================
-- POTATO PLACEMENT SERVICE V4
--
-- ✅ Place potato with existing E system
-- ✅ Saves placement
-- ✅ Restores after rejoin
-- ✅ [R] Remove Potato
-- ✅ Removes OLD already-placed potatoes
-- ✅ Same PotatoId returns to inventory
-- ✅ Rot pauses when removed
-- ✅ Rot NEVER resets
-- ✅ Re-place resumes rot timer
-- ✅ Super has NO ROT
-- ✅ Rainbow has NO ROT
-- ✅ Old unsupported rarities can still be removed
--==================================================

local DataService =
	require(
		script.Parent:WaitForChild(
			"DataService"
		)
	)

local PotatoVisuals =
	require(
		script.Parent:WaitForChild(
			"PotatoVisuals"
		)
	)

--==================================================
-- WORLD
--==================================================

local world =
	Workspace:WaitForChild(
		"PotatoWorld"
	)

local farmsFolder =
	world:WaitForChild(
		"Farms"
	)

--==================================================
-- SETTINGS
--==================================================

local ACTION_COOLDOWN = 0.25

local REMOVE_DISTANCE = 10

local REMOVE_PROMPT_NAME =
	"RemovePotatoPrompt"

--==================================================
-- REMOTES
--==================================================

local remoteFolder =
	ReplicatedStorage:FindFirstChild(
		"PotatoPlacementRemotes"
	)

if not remoteFolder then

	remoteFolder =
		Instance.new(
			"Folder"
		)

	remoteFolder.Name =
		"PotatoPlacementRemotes"

	remoteFolder.Parent =
		ReplicatedStorage

end

local PlacePotato =
	remoteFolder:FindFirstChild(
		"PlacePotato"
	)

if not PlacePotato then

	PlacePotato =
		Instance.new(
			"RemoteEvent"
		)

	PlacePotato.Name =
		"PlacePotato"

	PlacePotato.Parent =
		remoteFolder

end

--==================================================
-- STATE
--==================================================

local busyPlayers = {}

local restoringPlayers = {}

-- Stores farm name already restored.
local restoredFarm =
	{}

--==================================================
-- FORWARD DECLARATION
--==================================================

local removePotato

--==================================================
-- OLD RARITY VISUAL COMPATIBILITY
--
-- These are only for showing OLD saved potatoes.
-- They do NOT create new Uncommon/Mythic potatoes.
--==================================================

local OLD_VISUAL_RARITY = {

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

}

local function getVisualRarity(
	rarity
)

	rarity =
		tostring(
			rarity
				or
				"Common"
		)

	return
		OLD_VISUAL_RARITY[
			rarity
		]
		or
		rarity

end

--==================================================
-- GET OWNED FARM
--==================================================

local function getOwnedFarm(
	player
)

	for _, farm in ipairs(
		farmsFolder:GetChildren()
	) do

		if
			farm:IsA("Model")
			and
			farm:GetAttribute(
				"OwnerUserId"
			)
			==
			player.UserId
		then

			return farm

		end

	end

	return nil

end

--==================================================
-- GET EQUIPPED POTATO
--==================================================

local function getEquippedPotato(
	player
)

	local character =
		player.Character

	if not character then

		return nil

	end

	for _, object in ipairs(
		character:GetChildren()
	) do

		if
			object:IsA("Tool")
			and
			object:GetAttribute(
				"PotatoInventoryTool"
			)
			==
			true
		then

			return object

		end

	end

	return nil

end

--==================================================
-- GET PLAYER ROOT
--==================================================

local function getRoot(
	player
)

	local character =
		player.Character

	if not character then

		return nil

	end

	return
		character:FindFirstChild(
			"HumanoidRootPart"
		)

end

--==================================================
-- GET FARM LANDS
--==================================================

local function getFarmLandsFolder(
	farm
)

	if not farm then

		return nil

	end

	return
		farm:FindFirstChild(
			"FarmLands"
		)

end

--==================================================
-- GET PLANT POINT
--==================================================

local function getPlantPoint(
	farmLand
)

	if not farmLand then

		return nil

	end

	local point =
		farmLand:FindFirstChild(
			"PlantPoint",
			true
		)

	if
		point
		and
		point:IsA(
			"BasePart"
		)
	then

		return point

	end

	return nil

end

--==================================================
-- VALIDATE FARM LAND
--==================================================

local function validateFarmLand(
	player,
	farmLand
)

	if
		typeof(
			farmLand
		)
		~=
		"Instance"
	then

		return false, nil, nil

	end

	if not farmLand:IsA(
		"Model"
	) then

		return false, nil, nil

	end

	local farm =
		getOwnedFarm(
			player
		)

	if not farm then

		return false, nil, nil

	end

	local farmLands =
		getFarmLandsFolder(
			farm
		)

	if not farmLands then

		return false, nil, nil

	end

	if
		farmLand.Parent
		~=
		farmLands
	then

		return false, nil, nil

	end

	local plantPoint =
		getPlantPoint(
			farmLand
		)

	if not plantPoint then

		return false, nil, nil

	end

	return true,
		plantPoint,
		farm

end

--==================================================
-- BUSY
--==================================================

local function beginAction(
	player
)

	if busyPlayers[
		player
	] then

		return false

	end

	busyPlayers[
		player
	] =
		true

	task.delay(
		ACTION_COOLDOWN,

		function()

			busyPlayers[
				player
			] =
				nil

		end
	)

	return true

end

--==================================================
-- DELETE REMOVE PROMPTS
--
-- Also cleans prompts left from the OLD separate
-- PotatoRemovalService.
--==================================================

local function clearRemovePrompts(
	farmLand
)

	for _, object in ipairs(
		farmLand:GetDescendants()
	) do

		if
			object:IsA(
				"ProximityPrompt"
			)
			and
			object.Name
			==
			REMOVE_PROMPT_NAME
		then

			object:Destroy()

		end

	end

end

--==================================================
-- DELETE OLD PLACED VISUAL
--==================================================

local function clearPlacedVisual(
	farmLand
)

	clearRemovePrompts(
		farmLand
	)

	local old =
		farmLand:FindFirstChild(
			"PlacedPotato"
		)

	if old then

		old:Destroy()

	end

end

--==================================================
-- ROT ATTRIBUTES
--==================================================

local function updateRotAttributes(
	player,
	farmLand,
	potatoId
)

	if
		type(
			DataService.GetPotatoRotState
		)
		~=
		"function"
	then

		return

	end

	local state =
		DataService.GetPotatoRotState(
			player,
			potatoId
		)

	if not state then

		return

	end

	farmLand:SetAttribute(
		"RotRemaining",
		tonumber(
			state.RotRemaining
		)
		or
		0
	)

	farmLand:SetAttribute(
		"RotAt",
		tonumber(
			state.RotAt
		)
		or
		0
	)

	farmLand:SetAttribute(
		"IsRotten",
		state.IsRotten
			==
			true
	)

	farmLand:SetAttribute(
		"RotImmune",
		state.IsRotImmune
			==
			true
	)

	farmLand:SetAttribute(
		"RotSpeedMultiplier",
		tonumber(
			state.RotSpeedMultiplier
		)
		or
		1
	)

	farmLand:SetAttribute(
		"RotProtectionPercent",
		tonumber(
			state.RotProtectionPercent
		)
		or
		0
	)

end

--==================================================
-- CREATE REMOVE PROMPT
--
-- IMPORTANT:
--
-- Prompt is attached to the potato visual itself,
-- NOT PlantPoint.
--
-- This prevents your old placement-client prompt
-- system from interfering with it.
--==================================================

local function createRemovePrompt(
	visual,
	farmLand,
	record
)

	if not visual then

		return

	end

	clearRemovePrompts(
		farmLand
	)

	local promptPart =
		visual.PrimaryPart

	if not promptPart then

		promptPart =
			visual:FindFirstChild(
				"Handle",
				true
			)

	end

	if
		not promptPart
		or
		not promptPart:IsA(
			"BasePart"
		)
	then

		for _, object in ipairs(
			visual:GetDescendants()
		) do

			if object:IsA(
				"BasePart"
			) then

				promptPart =
					object

				break

			end

		end

	end

	if not promptPart then

		warn(
			"❌ No part available for Remove prompt: "
				..
				farmLand.Name
		)

		return

	end

	local prompt =
		Instance.new(
			"ProximityPrompt"
		)

	prompt.Name =
		REMOVE_PROMPT_NAME

	prompt.ActionText =
		"Remove Potato"

	prompt.ObjectText =
		tostring(
			record.DisplayName
			or
			record.PotatoType
			or
			"Basic Potato"
		)

	prompt.KeyboardKeyCode =
		Enum.KeyCode.R

	prompt.HoldDuration =
		0.15

	prompt.MaxActivationDistance =
		REMOVE_DISTANCE

	prompt.RequiresLineOfSight =
		false

	prompt.Exclusivity =
		Enum.ProximityPromptExclusivity.AlwaysShow

	prompt.Parent =
		promptPart

	prompt.Triggered:Connect(
		function(
			player
		)

			removePotato(
				player,
				farmLand
			)

		end
	)

end

--==================================================
-- CREATE MEADOW POTATO MODEL
--==================================================

local function findMeadowPotatoAsset(record)
	local folder =
		ReplicatedStorage:FindFirstChild(
			"newpotatoes"
		)

	if not folder then
		return nil
	end

	local modelName =
		tostring(
			record.ModelName
			or
			""
		)

	if modelName ~= "" then
		local exact =
			folder:FindFirstChild(
				modelName
			)

		if exact and exact:IsA("Model") then
			return exact
		end
	end

	local potatoType =
		tostring(
			record.PotatoType
			or
			"Basic"
		)

	local aliases = {
		Basic = "basic_potato",
		Big = "big_potato",
		Butter = "butter_potato",
		Feather = "feather_potato",
		Flower = "flower_potato",
		Golden = "golden_potato",
		Grass = "grass_potato",
		Lucky = "lucky_potato",
		Prism = "prism_potato",
		Star = "star_potato",
		Sunkissed = "sunkissed_potato",
	}

	local wanted =
		aliases[
			potatoType
		]

	if not wanted then
		wanted =
			string.lower(
				potatoType
			)
			:gsub(
				"[%s%-]+",
				"_"
			)
			..
			"_potato"
	end

	local asset =
		folder:FindFirstChild(
			wanted
		)

	if asset and asset:IsA("Model") then
		return asset
	end

	local fallback =
		folder:FindFirstChild(
			"basic_potato"
		)

	if fallback and fallback:IsA("Model") then
		return fallback
	end

	return nil
end

local function preparePlacedPotatoVisual(
	visual,
	record
)
	local scale =
		math.max(
			0.01,
			tonumber(
				record.VisualScale
			)
				or
				1
		)

	pcall(
		function()
			visual:ScaleTo(
				scale
			)
		end
	)

	for _, object in ipairs(
		visual:GetDescendants()
	) do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = true
			object.Massless = true
		end
	end
end

--==================================================
-- CREATE PLACED POTATO
--==================================================

local function createPlacedVisual(
	farmLand,
	plantPoint,
	record,
	playerUserId
)

	clearPlacedVisual(
		farmLand
	)

	local asset =
		findMeadowPotatoAsset(
			record
		)

	if not asset then
		warn(
			"❌ Meadow potato model missing: "
				..
				tostring(
					record.ModelName
					or
					record.PotatoType
					or
					"Basic"
				)
		)

		return nil
	end

	local visual =
		asset:Clone()

	visual.Name =
		"PlacedPotato"

	preparePlacedPotatoVisual(
		visual,
		record
	)

	visual:SetAttribute(
		"PotatoId",
		record.Id
	)

	visual:SetAttribute(
		"PotatoType",
		record.PotatoType
	)

	visual:SetAttribute(
		"ModelName",
		record.ModelName
			or
			asset.Name
	)

	visual:SetAttribute(
		"SpudMass",
		record.SpudMass
	)

	visual:SetAttribute(
		"SizeTier",
		record.SizeTier
	)

	visual:SetAttribute(
		"VisualScale",
		record.VisualScale
	)

	visual:SetAttribute(
		"BaseSellPrice",
		record.BaseSellPrice
	)

	visual:SetAttribute(
		"SellPrice",
		record.SellPrice
	)

	visual:SetAttribute(
		"Rarity",
		record.Rarity
	)

	visual:SetAttribute(
		"IsTranscendent",
		record.IsRotImmune == true
	)

	visual:SetAttribute(
		"PlacedByUserId",
		playerUserId
	)

	visual:SetAttribute(
		"TargetHeight",
		record.TargetHeight
			or
			2.5
	)

	visual.Parent =
		farmLand

	local _,
		size =
			visual:GetBoundingBox()

	visual:PivotTo(
		plantPoint.CFrame
		*
		CFrame.new(
			0,
			(size.Y / 2)
				+
				0.05,
			0
		)
	)

	--==================================================
	-- FARM LAND ATTRIBUTES
	--==================================================

	farmLand:SetAttribute(
		"Occupied",
		true
	)

	farmLand:SetAttribute(
		"PotatoId",
		record.Id
	)

	farmLand:SetAttribute(
		"PlacedByUserId",
		playerUserId
	)

	farmLand:SetAttribute(
		"PlacedPotatoName",
		record.DisplayName
			or
			(
				tostring(
					record.PotatoType
					or
					"Basic"
				)
				..
				" Potato"
			)
	)

	farmLand:SetAttribute(
		"PotatoType",
		record.PotatoType
	)

	farmLand:SetAttribute(
		"ModelName",
		record.ModelName
			or
			asset.Name
	)

	farmLand:SetAttribute(
		"SpudMass",
		record.SpudMass
	)

	farmLand:SetAttribute(
		"VisualScale",
		record.VisualScale
	)

	farmLand:SetAttribute(
		"MoneyPerSecond",
		record.MoneyPerSecond
			or
			0
	)

	farmLand:SetAttribute(
		"Rarity",
		record.Rarity
	)

	farmLand:SetAttribute(
		"RotImmune",
		record.IsRotImmune == true
	)

	--==================================================
	-- REMOVE PROMPT
	--==================================================

	createRemovePrompt(
		visual,
		farmLand,
		record
	)

	return visual

end

--==================================================
-- CLEAR FARM LAND RUNTIME
--==================================================

local function clearFarmLandRuntime(
	farmLand
)

	clearPlacedVisual(
		farmLand
	)

	farmLand:SetAttribute(
		"Occupied",
		false
	)

	farmLand:SetAttribute(
		"PotatoId",
		nil
	)

	farmLand:SetAttribute(
		"PlacedByUserId",
		nil
	)

	farmLand:SetAttribute(
		"PlacedPotatoName",
		nil
	)

	farmLand:SetAttribute(
		"Rarity",
		nil
	)

	farmLand:SetAttribute(
		"MoneyPerSecond",
		0
	)

	farmLand:SetAttribute(
		"RotRemaining",
		0
	)

	farmLand:SetAttribute(
		"RotAt",
		0
	)

	farmLand:SetAttribute(
		"IsRotten",
		false
	)

	farmLand:SetAttribute(
		"RotImmune",
		false
	)

	farmLand:SetAttribute(
		"RotSpeedMultiplier",
		1
	)

	farmLand:SetAttribute(
		"RotProtectionPercent",
		0
	)

end

--==================================================
-- CLEAR WHOLE FARM RUNTIME
--==================================================

local function clearFarmRuntime(
	farm
)

	local farmLands =
		getFarmLandsFolder(
			farm
		)

	if not farmLands then

		return

	end

	for _, farmLand in ipairs(
		farmLands:GetChildren()
	) do

		if farmLand:IsA(
			"Model"
		) then

			clearFarmLandRuntime(
				farmLand
			)

		end

	end

end

--==================================================
-- FIND RECORD FOR FARM LAND
--
-- This allows OLD placements to be removed even if
-- their runtime attributes are missing.
--==================================================

local function findPlacedRecord(
	player,
	farmLand
)

	local runtimeId =
		farmLand:GetAttribute(
			"PotatoId"
		)

	if runtimeId ~= nil then

		local record =
			DataService.GetPotatoRecord(
				player,
				runtimeId
			)

		if record then

			return record

		end

	end

	--==================================================
	-- FALLBACK:
	-- SEARCH SAVED PLACED SLOT
	--==================================================

	local records =
		DataService.GetPotatoInventory(
			player
		)

	for _, record in ipairs(
		records
	) do

		if
			tostring(
				record.PlacedSlot
					or
					""
			)
			==
			farmLand.Name
		then

			return record

		end

	end

	return nil

end

--==================================================
-- REMOVE POTATO
--==================================================

removePotato =
	function(
		player,
		farmLand
	)

		if not beginAction(
			player
		) then

			return

		end

		--==================================================
		-- DATA
		--==================================================

		if
			player:GetAttribute(
				"DataLoaded"
			)
			~=
			true
		then

			return

		end

		--==================================================
		-- VALIDATE
		--==================================================

		local valid,
			plantPoint,
			farm =
				validateFarmLand(
					player,
					farmLand
				)

		if not valid then

			warn(
				"❌ REMOVE rejected: invalid FarmLand"
			)

			return

		end

		--==================================================
		-- DISTANCE
		--==================================================

		local root =
			getRoot(
				player
			)

		if not root then

			return

		end

		if
			(
				root.Position
				-
				plantPoint.Position
			).Magnitude
			>
			REMOVE_DISTANCE
			+
			2
		then

			warn(
				"❌ REMOVE rejected: player too far"
			)

			return

		end

		--==================================================
		-- FIND EXACT SAVED POTATO
		--==================================================

		local record =
			findPlacedRecord(
				player,
				farmLand
			)

		if not record then

			warn(
				"❌ REMOVE failed: no placed record in "
					..
					farmLand.Name
			)

			return

		end

		local potatoId =
			record.Id

		if potatoId == nil then

			warn(
				"❌ REMOVE failed: potato has no ID"
			)

			return

		end

		--==================================================
		-- VERIFY THIS POTATO REALLY BELONGS HERE
		--==================================================

		if
			tostring(
				record.PlacedSlot
					or
					""
			)
			~=
			farmLand.Name
		then

			warn(
				"❌ REMOVE failed: slot mismatch"
			)

			return

		end

		--==================================================
		-- CLEAR SAVED PLACEMENT
		--
		-- DataService V4.1:
		--
		-- 1. pauses rot
		-- 2. saves remaining time
		-- 3. clears PlacedFarm
		-- 4. clears PlacedSlot
		--
		-- It does NOT reset the timer.
		--==================================================

		local success =
			DataService.ClearPotatoPlaced(
				player,
				potatoId
			)

		if not success then

			warn(
				"❌ REMOVE failed to update DataService"
			)

			return

		end

		--==================================================
		-- GET PAUSED TIMER
		--==================================================

		local rotState

		if
			type(
				DataService.GetPotatoRotState
			)
			==
			"function"
		then

			rotState =
				DataService.GetPotatoRotState(
					player,
					potatoId
				)

		end

		--==================================================
		-- REMOVE VISUAL / OPEN LAND
		--==================================================

		clearFarmLandRuntime(
			farmLand
		)

		--==================================================
		-- INVENTORY
		--
		-- DataService bumps PotatoInventoryRevision.
		-- InventoryService sees that and recreates the
		-- SAME PotatoId in the backpack.
		--==================================================

		if rotState then

			if
				rotState.IsRotImmune
				==
				true
			then

				print(
					"🥔 REMOVED: "
						..
						player.Name
						..
						" | "
						..
						tostring(
							record.Rarity
						)
						..
						" | NO ROT ♾"
				)

			elseif
				rotState.IsRotten
				==
				true
			then

				print(
					"🥔 REMOVED: "
						..
						player.Name
						..
						" | "
						..
						tostring(
							record.Rarity
						)
						..
						" | ROTTEN"
				)

			else

				print(
					"🥔 REMOVED: "
						..
						player.Name
						..
						" | "
						..
						tostring(
							record.Rarity
						)
						..
						" | Rot paused at "
						..
						tostring(
							math.ceil(
								rotState.RotRemaining
									or
									0
							)
						)
						..
						" sec"
				)

			end

		else

			print(
				"🥔 REMOVED: "
					..
					player.Name
					..
					" | PotatoId "
					..
					tostring(
						potatoId
					)
			)

		end

	end

--==================================================
-- RESTORE PLAYER PLACEMENTS
--==================================================

local function restorePlayerPlacements(
	player
)

	if restoringPlayers[
		player
	] then

		return

	end

	if
		player:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	then

		return

	end

	local farm =
		getOwnedFarm(
			player
		)

	if not farm then

		return

	end

	if
		restoredFarm[
			player
		]
		==
		farm.Name
	then

		return

	end

	restoringPlayers[
		player
	] =
		true

	local farmLands =
		getFarmLandsFolder(
			farm
		)

	if not farmLands then

		restoringPlayers[
			player
		] =
			nil

		return

	end

	--==================================================
	-- CLEAN RUNTIME
	--==================================================

	clearFarmRuntime(
		farm
	)

	--==================================================
	-- SAVED RECORDS
	--==================================================

	local records =
		DataService.GetPotatoInventory(
			player
		)

	local restored =
		0

	for _, record in ipairs(
		records
	) do

		local slotName =
			record.PlacedSlot

		if
			type(
				slotName
			)
			==
			"string"
			and
			slotName
			~=
			""
		then

			local farmLand =
				farmLands:FindFirstChild(
					slotName
				)

			if
				farmLand
				and
				farmLand:IsA(
					"Model"
				)
			then

				local plantPoint =
					getPlantPoint(
						farmLand
					)

				if plantPoint then

					--==================================================
					-- START / CONTINUE ROT
					--
					-- Old placed potatoes that had no timer yet
					-- begin at 3:00.
					--
					-- Existing RotAt continues normally.
					--==================================================

					if
						type(
							DataService.StartPotatoRot
						)
						==
						"function"
					then

						DataService.StartPotatoRot(
							player,
							record.Id
						)

					end

					--==================================================
					-- REFRESH RECORD AFTER ROT START
					--==================================================

					local updated =
						DataService.GetPotatoRecord(
							player,
							record.Id
						)

					if updated then

						record =
							updated

					end

					--==================================================
					-- CREATE VISUAL
					--==================================================

					local visual =
						createPlacedVisual(
							farmLand,
							plantPoint,
							record,
							player.UserId
						)

					if visual then

						restored +=
							1

						updateRotAttributes(
							player,
							farmLand,
							record.Id
						)

					end

					--==================================================
					-- UPDATE FARM NAME IF NEEDED
					--==================================================

					if
						record.PlacedFarm
						~=
						farm.Name
					then

						DataService.SetPotatoPlaced(
							player,
							record.Id,
							farm.Name,
							farmLand.Name
						)

					end

				end

			else

				warn(
					"⚠ Saved FarmLand missing: "
						..
						tostring(
							slotName
						)
				)

			end

		end

	end

	restoringPlayers[
		player
	] =
		nil

	restoredFarm[
		player
	] =
		farm.Name

	print(
		"🥔 Restored "
			..
			restored
			..
			" placed potatoes for "
			..
			player.Name
	)

end

--==================================================
-- TRY RESTORE
--==================================================

local function tryRestore(
	player
)

	task.defer(
		function()

			for _ = 1, 40 do

				if not player.Parent then

					return

				end

				if
					player:GetAttribute(
						"DataLoaded"
					)
					==
					true
				then

					local farm =
						getOwnedFarm(
							player
						)

					if farm then

						restorePlayerPlacements(
							player
						)

						return

					end

				end

				task.wait(
					0.2
				)

			end

		end
	)

end

--==================================================
-- PLACE POTATO
--==================================================

local function placePotato(
	player,
	farmLand
)

	if not beginAction(
		player
	) then

		return

	end

	--==================================================
	-- DATA
	--==================================================

	if
		player:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	then

		return

	end

	--==================================================
	-- VALIDATE LAND
	--==================================================

	local valid,
		plantPoint,
		farm =
			validateFarmLand(
				player,
				farmLand
			)

	if not valid then

		warn(
			"❌ Invalid FarmLand request from "
				..
				player.Name
		)

		return

	end

	--==================================================
	-- OCCUPIED
	--==================================================

	if
		farmLand:GetAttribute(
			"Occupied"
		)
		==
		true
	then

		return

	end

	--==================================================
	-- EQUIPPED POTATO
	--==================================================

	local tool =
		getEquippedPotato(
			player
		)

	if not tool then

		return

	end

	local potatoId =
		tool:GetAttribute(
			"PotatoId"
		)

	if potatoId == nil then

		warn(
			"❌ Equipped potato has no PotatoId"
		)

		return

	end

	--==================================================
	-- SAVED RECORD
	--==================================================

	local record =
		DataService.GetPotatoRecord(
			player,
			potatoId
		)

	if not record then

		warn(
			"❌ Potato record missing: "
				..
				tostring(
					potatoId
				)
		)

		return

	end

	--==================================================
	-- ALREADY PLACED
	--==================================================

	if
		record.PlacedSlot
		and
		record.PlacedSlot
		~=
		""
	then

		warn(
			"❌ Potato already placed: "
				..
				tostring(
					potatoId
				)
		)

		return

	end

	--==================================================
	-- SAVE PLACEMENT
	--
	-- DataService automatically STARTS or RESUMES rot.
	--==================================================

	local saved =
		DataService.SetPotatoPlaced(
			player,
			potatoId,
			farm.Name,
			farmLand.Name
		)

	if not saved then

		warn(
			"❌ Could not save potato placement"
		)

		return

	end

	--==================================================
	-- UPDATED RECORD
	--==================================================

	record =
		DataService.GetPotatoRecord(
			player,
			potatoId
		)

	if not record then

		warn(
			"❌ Updated potato record missing"
		)

		-- Undo placement save.

		DataService.ClearPotatoPlaced(
			player,
			potatoId
		)

		return

	end

	--==================================================
	-- CREATE VISUAL
	--==================================================

	local visual =
		createPlacedVisual(
			farmLand,
			plantPoint,
			record,
			player.UserId
		)

	if not visual then

		warn(
			"❌ Could not create placed potato visual"
		)

		-- Undo placement so potato isn't lost.

		DataService.ClearPotatoPlaced(
			player,
			potatoId
		)

		return

	end

	--==================================================
	-- ROT ATTRIBUTES
	--==================================================

	updateRotAttributes(
		player,
		farmLand,
		potatoId
	)

	--==================================================
	-- REMOVE TOOL
	--==================================================

	if
		tool
		and
		tool.Parent
	then

		tool:Destroy()

	end

	print(
		"🥔 POTATO PLACED + SAVED: "
			..
			player.Name
			..
			" | "
			..
			tostring(
				record.DisplayName
					or
					record.PotatoType
					or
					"Basic"
			)
			..
			" | "
			..
			farm.Name
			..
			" | "
			..
			farmLand.Name
	)

end

--==================================================
-- PLACE REMOTE
--==================================================

PlacePotato.OnServerEvent:Connect(
	function(
		player,
		farmLand
	)

		placePotato(
			player,
			farmLand
		)

	end
)

--==================================================
-- PLAYER SETUP
--==================================================

local function setupPlayer(
	player
)

	player:GetAttributeChangedSignal(
		"DataLoaded"
	):Connect(
		function()

			if
				player:GetAttribute(
					"DataLoaded"
				)
				==
				true
			then

				tryRestore(
					player
				)

			end

		end
	)

	player:GetAttributeChangedSignal(
		"AssignedFarmName"
	):Connect(
		function()

			local farm =
				getOwnedFarm(
					player
				)

			if
				not farm
				or
				restoredFarm[
					player
				]
				~=
				farm.Name
			then

				restoredFarm[
					player
				] =
					nil

			end

			tryRestore(
				player
			)

		end
	)

	tryRestore(
		player
	)

end

--==================================================
-- PLAYER LEAVING
--==================================================

Players.PlayerRemoving:Connect(
	function(
		player
	)

		local farm =
			getOwnedFarm(
				player
			)

		if farm then

			clearFarmRuntime(
				farm
			)

		end

		busyPlayers[
			player
		] =
			nil

		restoringPlayers[
			player
		] =
			nil

		restoredFarm[
			player
		] =
			nil

	end
)

--==================================================
-- PLAYERS
--==================================================

Players.PlayerAdded:Connect(
	setupPlayer
)

for _, player in ipairs(
	Players:GetPlayers()
) do

	setupPlayer(
		player
	)

end

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("🥔 POTATO PLACEMENT SERVICE V4")
print("========================================")
print("✅ E = Place Potato")
print("✅ R = Remove Potato")
print("✅ Remove prompt attached to potato")
print("✅ Old placed potatoes removable")
print("✅ Exact PotatoId returned")
print("✅ Placement persistence")
print("✅ Rot starts on first placement")
print("✅ Rot pauses on removal")
print("✅ Rot never resets")
print("✅ Re-place resumes timer")
print("♾ Super = NO ROT")
print("🌈 Rainbow = NO ROT")
print("----------------------------------------")
print("✅ Old Uncommon visual → Rare")
print("✅ Old Mythic visual → Legendary")
print("✅ Old Silver visual → Epic")
print("✅ Old Gold visual → Exotic")
print("✅ Old Diamond visual → Legendary")
print("✅ Duplicate restore reduced")
print("========================================")
print("")