local Players =
	game:GetService("Players")

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

--==================================================
-- WOODEN HOE SERVICE V4
--
-- Uses the ORIGINAL orientation of WoodenHoe_2.
-- No automatic rotation/alignment.
--
-- The animation controls how the player uses the hoe.
--==================================================

local TEMPLATE_NAME =
	"WoodenHoe_2"

local TOOL_NAME =
	"Wooden Hoe"

--==================================================
-- SIZE
--==================================================

local MODEL_SCALE =
	0.55

--==================================================
-- GRIP POSITION
--
-- Adjust these only if the hand is in the wrong place.
--==================================================

local TOOL_GRIP_POSITION =
	Vector3.new(
		0,
		-0.1,
		-0.15
	)

--==================================================
-- GRIP ROTATION
--
-- Since the animation already has the correct hoe
-- orientation, start with NO extra rotation.
--==================================================

local TOOL_GRIP_ROTATION =
	Vector3.new(
		0,
		0,
		0
	)

--==================================================
-- HOW FAR FROM TOP OF SHAFT PLAYER HOLDS
--==================================================

local GRIP_FROM_TOP =
	0.10

--==================================================
-- HOE STATS
--==================================================

local DIG_TIME =
	6

local LUCK =
	0

--==================================================
-- TEMPLATE
--==================================================

local template =
	ReplicatedStorage:WaitForChild(
		TEMPLATE_NAME
	)

local busyPlayers = {}

--==================================================
-- GET PARTS FROM TEMPLATE
--==================================================

local function getTemplateParts()

	local parts = {}

	if template:IsA(
		"BasePart"
		) then

		table.insert(
			parts,
			template
		)

		return parts

	end

	for _, object in ipairs(
		template:GetDescendants()
		) do

		if object:IsA(
			"BasePart"
			) then

			table.insert(
				parts,
				object
			)

		end

	end

	return parts

end

--==================================================
-- LONGEST DIMENSION
--==================================================

local function getLongestAxis(
	part
)

	local size =
		part.Size

	if
		size.X >= size.Y
		and
		size.X >= size.Z
	then

		return
			"X",
			size.X,
			Vector3.new(
				1,
				0,
				0
			)

	end

	if
		size.Y >= size.X
		and
		size.Y >= size.Z
	then

		return
			"Y",
			size.Y,
			Vector3.new(
				0,
				1,
				0
			)

	end

	return
		"Z",
		size.Z,
		Vector3.new(
			0,
			0,
			1
		)

end

--==================================================
-- FIND SHAFT
--
-- Prefer Handle.
-- Otherwise use longest part.
--==================================================

local function findShaft()

	if not template:IsA(
		"BasePart"
		) then

		local exact =
			template:FindFirstChild(
				"Handle",
				true
			)

		if
			exact
			and
			exact:IsA(
				"BasePart"
			)
		then

			return exact

		end

	end

	local bestPart =
		nil

	local bestLength =
		0

	for _, part in ipairs(
		getTemplateParts()
		) do

		local _,
			length =
			getLongestAxis(
				part
			)

		if length > bestLength then

			bestLength =
				length

			bestPart =
				part

		end

	end

	if bestPart then

		warn(
			"⚠ WoodenHoe_2 has no part named Handle."
		)

		warn(
			"⚠ Using longest part as shaft: "
				..
				bestPart.Name
		)

	end

	return bestPart

end

--==================================================
-- CLEAN CLONE
--==================================================

local function cleanClone(
	part
)

	for _, object in ipairs(
		part:GetDescendants()
		) do

		if
			object:IsA(
				"Script"
			)
				or
				object:IsA(
					"LocalScript"
				)
				or
				object:IsA(
					"ModuleScript"
				)
				or
				object:IsA(
					"Weld"
				)
				or
				object:IsA(
					"WeldConstraint"
				)
				or
				object:IsA(
					"Motor6D"
				)
				or
				object:IsA(
					"Snap"
				)
		then

			object:Destroy()

		end

	end

	part.Anchored =
		false

	part.CanCollide =
		false

	part.CanTouch =
		false

	part.CanQuery =
		false

	part.Massless =
		true

end

--==================================================
-- BUILD HOE
--==================================================

local function buildHoe()

	local shaft =
		findShaft()

	if not shaft then

		warn(
			"❌ WoodenHoe_2 contains no BaseParts"
		)

		return nil

	end

	local parts =
		getTemplateParts()

	if #parts == 0 then

		return nil

	end

	--==================================================
	-- SHAFT LENGTH
	--==================================================

	local _,
		shaftLength =
		getLongestAxis(
			shaft
		)

	shaftLength *=
		MODEL_SCALE

	--==================================================
	-- GRIP POINT
	--
	-- We still calculate where the hand should hold
	-- the shaft, but DO NOT rotate the model.
	--==================================================

	local gripPointY =
		(
			shaftLength
			/
			2
		)
	-
		(
			shaftLength
			*
			GRIP_FROM_TOP
		)

	local geometryOffset =
		CFrame.new(
			0,
			-gripPointY,
			0
		)

	--==================================================
	-- TOOL
	--==================================================

	local tool =
		Instance.new(
			"Tool"
		)

	tool.Name =
		TOOL_NAME

	tool.ToolTip =
		"Wooden Hoe"

	tool.RequiresHandle =
		true

	tool.CanBeDropped =
		false

	tool.Enabled =
		true

	--==================================================
	-- ANIMATION
	--==================================================

	local animationFolder =
		game.ServerStorage:WaitForChild(
			"HoeAnimation"
		)

	local animationScript =
		animationFolder:WaitForChild(
			"HoeAnimation"
		):Clone()

	animationScript.Parent =
		tool

	--==================================================
	-- ATTRIBUTES
	--==================================================

	tool:SetAttribute(
		"FarmingToolType",
		"Hoe"
	)

	tool:SetAttribute(
		"ItemCategory",
		"Hoe"
	)

	tool:SetAttribute(
		"HoeRarity",
		"Wooden"
	)

	tool:SetAttribute(
		"HoeModelName",
		TEMPLATE_NAME
	)

	tool:SetAttribute(
		"HoeServiceVersion",
		4
	)

	tool:SetAttribute(
		"DigTime",
		DIG_TIME
	)

	tool:SetAttribute(
		"Luck",
		LUCK
	)

	tool:SetAttribute(
		"PermanentTool",
		true
	)

	--==================================================
	-- INVISIBLE TOOL HANDLE
	--==================================================

	local handle =
		Instance.new(
			"Part"
		)

	handle.Name =
		"Handle"

	handle.Size =
		Vector3.new(
			0.35,
			0.65,
			0.35
		)

	handle.Transparency =
		1

	handle.Anchored =
		false

	handle.CanCollide =
		false

	handle.CanTouch =
		false

	handle.CanQuery =
		false

	handle.Massless =
		true

	handle.Parent =
		tool

	--==================================================
	-- TOOL GRIP
	--
	-- No automatic model rotation.
	--==================================================

	tool.Grip =
		CFrame.new(
			TOOL_GRIP_POSITION
		)
		*
		CFrame.Angles(
			math.rad(
				TOOL_GRIP_ROTATION.X
			),
			math.rad(
				TOOL_GRIP_ROTATION.Y
			),
			math.rad(
				TOOL_GRIP_ROTATION.Z
			)
		)

	--==================================================
	-- CLONE VISUAL PARTS
	--
	-- IMPORTANT:
	-- Original model orientation is preserved.
	--==================================================

	for _, sourcePart in ipairs(
		parts
		) do

		local clone =
			sourcePart:Clone()

		cleanClone(
			clone
		)

		clone.Name =
			"HoeVisual_"
			..
			sourcePart.Name

		clone.Size =
			sourcePart.Size
			*
			MODEL_SCALE

		-- Preserve the original model orientation.
		local relative =
			shaft.CFrame
			:ToObjectSpace(
				sourcePart.CFrame
			)

		local scaledRelative =
			CFrame.new(
				relative.Position
				*
				MODEL_SCALE
			)
			*
			relative.Rotation

		local hoeRotation =
			CFrame.Angles(
				0,
				0,
				math.rad(90)
			)
			*
			CFrame.Angles(
				math.rad(90),
				0,
				0
			)

		local finalRelative =
			geometryOffset
			*
			hoeRotation
			*
			scaledRelative

		clone.CFrame =
			handle.CFrame
			*
			finalRelative

		clone.Parent =
			tool

		local weld =
			Instance.new(
				"WeldConstraint"
			)

		weld.Name =
			"HoeVisualWeld"

		weld.Part0 =
			handle

		weld.Part1 =
			clone

		weld.Parent =
			clone

	end

	return tool

end

--==================================================
-- HOE CHECK
--==================================================

local function isHoe(
	object
)

	if not object:IsA(
		"Tool"
		) then

		return false

	end

	if
		object:GetAttribute(
			"FarmingToolType"
		)
			==
			"Hoe"
	then

		return true

	end

	local name =
		string.lower(
			object.Name
		)

	return
		string.find(
			name,
			"hoe"
		)
		~=
		nil

end

--==================================================
-- CORRECT HOE CHECK
--==================================================

local function isCorrectHoe(
	tool
)

	return
		tool:IsA(
			"Tool"
		)
		and
		tool:GetAttribute(
			"HoeServiceVersion"
		)
		==
		4

end

--==================================================
-- GET CONTAINERS
--==================================================

local function getContainers(
	player
)

	local result = {}

	local backpack =
		player:FindFirstChild(
			"Backpack"
		)

	if backpack then

		table.insert(
			result,
			backpack
		)

	end

	if player.Character then

		table.insert(
			result,
			player.Character
		)

	end

	return result

end

--==================================================
-- REMOVE DUPLICATE / OLD HOES
--==================================================

local function removeOldHoes(
	player
)

	local correct =
		nil

	for _, container in ipairs(
		getContainers(
			player
		)
		) do

		for _, object in ipairs(
			container:GetChildren()
			) do

			if isHoe(
				object
				) then

				if isCorrectHoe(
					object
					) then

					if correct then

						object:Destroy()

					else

						correct =
							object

					end

				else

					object:Destroy()

				end

			end

		end

	end

	return correct

end

--==================================================
-- ENSURE HOE
--==================================================

local function ensureHoe(
	player
)

	if busyPlayers[
		player
		] then

		return

	end

	busyPlayers[
		player
	] =
		true

	local backpack =
		player:FindFirstChild(
			"Backpack"
		)

	if not backpack then

		busyPlayers[
			player
		] =
			nil

		return

	end

	local existing =
		removeOldHoes(
			player
		)

	if existing then

		busyPlayers[
			player
		] =
			nil

		return

	end

	local hoe =
		buildHoe()

	if hoe then

		hoe.Parent =
			backpack

		print(
			"⛏ WoodenHoe_2 V4 given to "
				..
				player.Name
		)

	end

	busyPlayers[
		player
	] =
		nil

end

--==================================================
-- PLAYER
--==================================================

local function setupPlayer(
	player
)

	player.CharacterAdded:Connect(
		function()

			task.wait(
				0.8
			)

			ensureHoe(
				player
			)

		end
	)

	task.delay(
		1,
		function()

			if player.Parent then

				ensureHoe(
					player
				)

			end

		end
	)

end

--==================================================
-- EXISTING PLAYERS
--==================================================

for _, player in ipairs(
	Players:GetPlayers()
	) do

	setupPlayer(
		player
	)

end

--==================================================
-- NEW PLAYERS
--==================================================

Players.PlayerAdded:Connect(
	setupPlayer
)

--==================================================
-- CLEANUP
--==================================================

Players.PlayerRemoving:Connect(
	function(
		player
	)

		busyPlayers[
			player
		] =
			nil

	end
)

--==================================================
-- STARTUP
--==================================================

print("")
print("========================================")
print("⛏ WOODEN HOE SERVICE V4")
print("========================================")
print("✅ Original hoe orientation preserved")
print("✅ No automatic head rotation")
print("✅ Grip near top of shaft")
print("✅ Invisible Roblox Tool Handle")
print("✅ Animation included")
print("Scale = " .. MODEL_SCALE)
print("DigTime = " .. DIG_TIME)
print("Luck = " .. LUCK)
print("========================================")
print("")