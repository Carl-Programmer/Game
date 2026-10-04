local Players =
	game:GetService("Players")

local TweenService =
	game:GetService("TweenService")

local Workspace =
	game:GetService("Workspace")

local DataService =
	require(
		script.Parent:WaitForChild(
			"DataService"
		)
	)

--==================================================
-- POTATO ROT BURST SERVICE V1
--
-- Normal potato:
--
-- 00:02
-- 00:01
-- 00:00
--   ↓
-- BURST
--   ↓
-- smooth fade
--   ↓
-- permanently disappears
--
-- ✅ Removes potato from save
-- ✅ Clears FarmLand
-- ✅ Stops money immediately
-- ✅ Old placed potatoes supported
-- ✅ Removed potatoes are ignored
-- ✅ Super NEVER bursts
-- ✅ Rainbow NEVER bursts
--==================================================

local CHECK_INTERVAL =
	0.10

local BURST_TIME =
	0.45

local BURST_DISTANCE =
	2.4

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
-- STATE
--==================================================

local bursting =
	{}

--==================================================
-- GET OWNER
--==================================================

local function getFarmOwner(
	farm
)

	local ownerUserId =
		tonumber(
			farm:GetAttribute(
				"OwnerUserId"
			)
		)
		or
		0

	if ownerUserId <= 0 then

		return nil

	end

	return
		Players:GetPlayerByUserId(
			ownerUserId
		)

end

--==================================================
-- GET FARM LANDS
--==================================================

local function getFarmLands(
	farm
)

	return
		farm:FindFirstChild(
			"FarmLands"
		)

end

--==================================================
-- REMOVE R PROMPT
--==================================================

local function removePrompts(
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
			"RemovePotatoPrompt"
		then

			object.Enabled =
				false

			object:Destroy()

		end

	end

end

--==================================================
-- CLEAR FARM LAND
--==================================================

local function clearFarmLand(
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
		"RotBursting",
		false
	)

end

--==================================================
-- REMOVE WELDS
--
-- The potato model uses welds while placed.
--
-- We remove them ONLY when the potato bursts,
-- allowing each potato piece to separate smoothly.
--==================================================

local function removeVisualWelds(
	visual
)

	for _, object in ipairs(
		visual:GetDescendants()
	) do

		if
			object:IsA(
				"WeldConstraint"
			)
			or
			object:IsA(
				"Weld"
			)
			or
			object:IsA(
				"Motor6D"
			)
		then

			object:Destroy()

		end

	end

end

--==================================================
-- GET VISIBLE POTATO PARTS
--==================================================

local function getVisibleParts(
	visual
)

	local parts =
		{}

	for _, object in ipairs(
		visual:GetDescendants()
	) do

		if
			object:IsA(
				"BasePart"
			)
			and
			object.Transparency
			<
			0.95
		then

			table.insert(
				parts,
				object
			)

		end

	end

	return parts

end

--==================================================
-- BURST VISUAL
--==================================================

local function animateBurst(
	visual
)

	if not visual then

		return

	end

	if not visual.Parent then

		return

	end

	--==================================================
	-- CENTER
	--==================================================

	local centerCF =
		visual:GetBoundingBox()

	local center =
		centerCF.Position

	--==================================================
	-- FREE POTATO PIECES
	--==================================================

	removeVisualWelds(
		visual
	)

	local parts =
		getVisibleParts(
			visual
		)

	for index, part in ipairs(
		parts
	) do

		part.Anchored =
			true

		part.CanCollide =
			false

		part.CanTouch =
			false

		part.CanQuery =
			false

		--==================================================
		-- DIRECTION FROM POTATO CENTER
		--==================================================

		local direction =
			part.Position
			-
			center

		if direction.Magnitude < 0.05 then

			local angle =
				(
					index
					/
					math.max(
						1,
						#parts
					)
				)
				*
				math.pi
				*
				2

			direction =
				Vector3.new(
					math.cos(
						angle
					),
					0.6,
					math.sin(
						angle
					)
				)

		else

			direction =
				direction.Unit

		end

		--==================================================
		-- MAKE BURST SLIGHTLY UPWARD
		--==================================================

		direction =
			Vector3.new(
				direction.X,
				direction.Y
					+
					0.55,
				direction.Z
			)

		if direction.Magnitude > 0 then

			direction =
				direction.Unit

		end

		--==================================================
		-- KEEP ORIGINAL ROTATION
		--==================================================

		local rotation =
			part.CFrame
			-
			part.Position

		local targetPosition =
			part.Position
			+
			direction
			*
			BURST_DISTANCE

		local targetCF =
			CFrame.new(
				targetPosition
			)
			*
			rotation

		--==================================================
		-- SHRINK + FLY + FADE
		--==================================================

		local tween =
			TweenService:Create(
				part,

				TweenInfo.new(
					BURST_TIME,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),

				{
					CFrame =
						targetCF,

					Size =
						part.Size
						*
						0.30,

					Transparency =
						1,
				}
			)

		tween:Play()

	end

end

--==================================================
-- DESTROY ROTTEN POTATO
--==================================================

local function destroyRottenPotato(
	player,
	farmLand,
	potatoId
)

	if bursting[
		farmLand
	] then

		return

	end

	bursting[
		farmLand
	] =
		true

	farmLand:SetAttribute(
		"RotBursting",
		true
	)

	--==================================================
	-- RECHECK RECORD
	--
	-- Prevents a potato removed with R at the exact
	-- same moment from accidentally being destroyed.
	--==================================================

	local record =
		DataService.GetPotatoRecord(
			player,
			potatoId
		)

	if not record then

		bursting[
			farmLand
		] =
			nil

		return

	end

	if
		tostring(
			record.PlacedSlot
				or
				""
		)
		~=
		farmLand.Name
	then

		bursting[
			farmLand
		] =
			nil

		return

	end

	--==================================================
	-- MONEY STOPS NOW
	--==================================================

	farmLand:SetAttribute(
		"MoneyPerSecond",
		0
	)

	farmLand:SetAttribute(
		"IsRotten",
		true
	)

	farmLand:SetAttribute(
		"RotRemaining",
		0
	)

	farmLand:SetAttribute(
		"RotAt",
		0
	)

	--==================================================
	-- REMOVE R BUTTON
	--==================================================

	removePrompts(
		farmLand
	)

	--==================================================
	-- GET VISUAL
	--==================================================

	local visual =
		farmLand:FindFirstChild(
			"PlacedPotato"
		)

	--==================================================
	-- BURST
	--==================================================

	if visual then

		animateBurst(
			visual
		)

	end

	print(
		"💥 ROTTEN POTATO BURST: "
			..
			player.Name
			..
			" | "
			..
			tostring(
				record.Rarity
					or
					"Common"
			)
			..
			" | "
			..
			farmLand.Name
	)

	--==================================================
	-- WAIT FOR SMOOTH ANIMATION
	--==================================================

	task.wait(
		BURST_TIME
		+
		0.05
	)

	--==================================================
	-- DELETE VISUAL
	--==================================================

	if
		visual
		and
		visual.Parent
	then

		visual:Destroy()

	end

	--==================================================
	-- PERMANENTLY DELETE POTATO
	--
	-- This means:
	--
	-- ❌ not returned to backpack
	-- ❌ not restored after rejoin
	-- ❌ no longer in DataStore inventory
	--==================================================

	local removed =
		DataService.RemovePotatoRecord(
			player,
			potatoId
		)

	if removed then

		print(
			"🗑 Rotten potato permanently removed | ID "
				..
				tostring(
					potatoId
				)
		)

	else

		warn(
			"⚠ Could not remove rotten potato record | ID "
				..
				tostring(
					potatoId
				)
		)

	end

	--==================================================
	-- OPEN FARM LAND AGAIN
	--==================================================

	clearFarmLand(
		farmLand
	)

	bursting[
		farmLand
	] =
		nil

end

--==================================================
-- CHECK ONE FARM LAND
--==================================================

local function checkFarmLand(
	player,
	farmLand
)

	if
		not farmLand:GetAttribute(
			"Occupied"
		)
	then

		return

	end

	if farmLand:GetAttribute(
		"RotBursting"
	) then

		return

	end

	local potatoId =
		farmLand:GetAttribute(
			"PotatoId"
		)

	if potatoId == nil then

		return

	end

	--==================================================
	-- GET ROT STATE
	--==================================================

	local state =
		DataService.GetPotatoRotState(
			player,
			potatoId
		)

	if not state then

		return

	end

	--==================================================
	-- SUPER / RAINBOW
	--==================================================

	if
		state.IsRotImmune
		==
		true
	then

		return

	end

	--==================================================
	-- ROTTEN
	--==================================================

	if
		state.IsRotten
		==
		true
	then

		task.spawn(
			destroyRottenPotato,
			player,
			farmLand,
			potatoId
		)

	end

end

--==================================================
-- CHECK FARM
--==================================================

local function checkFarm(
	farm
)

	if not farm:IsA(
		"Model"
	) then

		return

	end

	local player =
		getFarmOwner(
			farm
		)

	if not player then

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

	local farmLands =
		getFarmLands(
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

			checkFarmLand(
				player,
				farmLand
			)

		end

	end

end

--==================================================
-- MAIN LOOP
--==================================================

task.spawn(
	function()

		while true do

			task.wait(
				CHECK_INTERVAL
			)

			for _, farm in ipairs(
				farmsFolder:GetChildren()
			) do

				checkFarm(
					farm
				)

			end

		end

	end
)

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("💥 POTATO ROT BURST SERVICE V1")
print("========================================")
print("✅ Rotten potato bursts")
print("✅ Pieces spread outward")
print("✅ Pieces shrink smoothly")
print("✅ Pieces fade smoothly")
print("✅ Potato permanently disappears")
print("✅ Plot becomes empty")
print("✅ Rotten potato removed from save")
print("✅ R-remove race protection")
print("♾ Super never bursts")
print("🌈 Rainbow never bursts")
print("========================================")
print("")