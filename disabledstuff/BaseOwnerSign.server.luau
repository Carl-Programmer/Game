local Players =
	game:GetService("Players")

local Workspace =
	game:GetService("Workspace")

--==================================================
-- MULTI BASE OWNER + SPAWN SYSTEM V4
--
-- NEW STRUCTURE:
--
-- Workspace
-- └── PotatoWorld
--     └── mpa2
--         └── Bases
--             ├── Base_01
--             ├── Base_02
--             └── ...
--==================================================

--==================================================
-- MAP
--==================================================

local potatoWorld =
	Workspace:WaitForChild(
		"PotatoWorld"
	)

local map =
	potatoWorld:WaitForChild(
		"mpa2"
	)

local basesFolder =
	map:WaitForChild(
		"Bases"
	)

--==================================================
-- SPAWN SETTINGS
--==================================================

local SPAWN_HEIGHT =
	4

local SPAWN_INSIDE_DISTANCE =
	8

--==================================================
-- SIGN SETTINGS
--==================================================

local SIGN_HEIGHT =
	29

local SIGN_MAX_DISTANCE =
	85

local SIGN_WIDTH =
	300

local SIGN_HEIGHT_PIXELS =
	90

--==================================================
-- COLORS
--==================================================

local MAIN_COLOR =
	Color3.fromRGB(
		255,
		244,
		220
	)

local UNCLAIMED_COLOR =
	Color3.fromRGB(
		255,
		205,
		95
	)

local STROKE_COLOR =
	Color3.fromRGB(
		65,
		40,
		25
	)

--==================================================
-- PLAYER -> BASE
--==================================================

local playerBases =
	{}

--==================================================
-- GET BASES IN NUMBER ORDER
--==================================================

local function getBases()

	local bases =
		{}

	for _, object in ipairs(
		basesFolder:GetChildren()
	) do

		if object:IsA("Model") then

			table.insert(
				bases,
				object
			)

		end

	end

	table.sort(
		bases,

		function(a, b)

			local aNumber =
				a:GetAttribute(
					"BaseNumber"
				)
				or
				999

			local bNumber =
				b:GetAttribute(
					"BaseNumber"
				)
				or
				999

			return
				aNumber
				<
				bNumber

		end
	)

	return bases
end

--==================================================
-- CREATE OWNER SIGN
--==================================================

local function createBaseSign(
	base
)

	--==================================================
	-- REMOVE OLD SIGN
	--==================================================

	local old =
		base:FindFirstChild(
			"OwnerSignAnchor"
		)

	if old then

		old:Destroy()

	end

	--==================================================
	-- FIND ENTRANCE
	--==================================================

	local entrance =
		base:FindFirstChild(
			"Entrance",
			true
		)

	if
		not entrance
		or
		not entrance:IsA("BasePart")
	then

		warn(
			"❌ Entrance missing in "
				..
				base.Name
		)

		return

	end

	--==================================================
	-- SIGN ANCHOR
	--==================================================

	local anchor =
		Instance.new("Part")

	anchor.Name =
		"OwnerSignAnchor"

	anchor.Size =
		Vector3.new(
			1,
			1,
			1
		)

	anchor.Transparency =
		1

	anchor.Anchored =
		true

	anchor.CanCollide =
		false

	anchor.CanTouch =
		false

	anchor.CanQuery =
		false

	anchor.CFrame =
		entrance.CFrame
		*
		CFrame.new(
			0,
			SIGN_HEIGHT,
			0
		)

	anchor.Parent =
		base

	--==================================================
	-- BILLBOARD
	--==================================================

	local gui =
		Instance.new(
			"BillboardGui"
		)

	gui.Name =
		"OwnerBillboard"

	gui.Size =
		UDim2.fromOffset(
			SIGN_WIDTH,
			SIGN_HEIGHT_PIXELS
		)

	gui.MaxDistance =
		SIGN_MAX_DISTANCE

	-- Less intrusive than AlwaysOnTop.
	gui.AlwaysOnTop =
		false

	gui.LightInfluence =
		0

	gui.Parent =
		anchor

	--==================================================
	-- OWNER NAME
	--==================================================

	local title =
		Instance.new(
			"TextLabel"
		)

	title.Name =
		"Title"

	title.Size =
		UDim2.new(
			1,
			0,
			0.62,
			0
		)

	title.BackgroundTransparency =
		1

	title.Font =
		Enum.Font.GothamBold

	title.TextSize =
		25

	title.TextColor3 =
		MAIN_COLOR

	title.TextStrokeColor3 =
		STROKE_COLOR

	title.TextStrokeTransparency =
		0.05

	title.Parent =
		gui

	--==================================================
	-- BASE NUMBER / STATUS
	--==================================================

	local status =
		Instance.new(
			"TextLabel"
		)

	status.Name =
		"Status"

	status.Size =
		UDim2.new(
			1,
			0,
			0.38,
			0
		)

	status.Position =
		UDim2.new(
			0,
			0,
			0.62,
			0
		)

	status.BackgroundTransparency =
		1

	status.Font =
		Enum.Font.GothamBold

	status.TextSize =
		16

	status.TextStrokeColor3 =
		STROKE_COLOR

	status.TextStrokeTransparency =
		0.05

	status.Parent =
		gui

	--==================================================
	-- UPDATE SIGN
	--==================================================

	local function update()

		local baseNumber =
			base:GetAttribute(
				"BaseNumber"
			)
			or
			1

		local ownerId =
			base:GetAttribute(
				"OwnerUserId"
			)
			or
			0

		--==================================================
		-- UNCLAIMED
		--==================================================

		if ownerId == 0 then

			title.Text =
				"BASE #"
				..
				tostring(
					baseNumber
				)

			status.Text =
				"UNCLAIMED"

			status.TextColor3 =
				UNCLAIMED_COLOR

			return

		end

		--==================================================
		-- CLAIMED
		--==================================================

		local owner =
			Players:GetPlayerByUserId(
				ownerId
			)

		if owner then

			title.Text =
				owner.Name

		else

			title.Text =
				"PLAYER"

		end

		status.Text =
			"BASE #"
			..
			tostring(
				baseNumber
			)

		status.TextColor3 =
			MAIN_COLOR

	end

	update()

	base:GetAttributeChangedSignal(
		"OwnerUserId"
	):Connect(
		update
	)

	base:GetAttributeChangedSignal(
		"BaseNumber"
	):Connect(
		update
	)

end

--==================================================
-- FIND FREE BASE
--==================================================

local function findFreeBase()

	for _, base in ipairs(
		getBases()
	) do

		local ownerId =
			base:GetAttribute(
				"OwnerUserId"
			)
			or
			0

		if ownerId == 0 then

			return base

		end

	end

	return nil
end

--==================================================
-- CLAIM BASE
--==================================================

local function claimBase(
	player
)

	--==================================================
	-- ALREADY HAS BASE
	--==================================================

	if playerBases[player] then

		return
			playerBases[player]

	end

	--==================================================
	-- FIND FREE BASE
	--==================================================

	local base =
		findFreeBase()

	if not base then

		warn(
			"❌ No free base for "
				..
				player.Name
		)

		return nil

	end

	--==================================================
	-- CLAIM
	--==================================================

	base:SetAttribute(
		"OwnerUserId",
		player.UserId
	)

	playerBases[player] =
		base

	local baseNumber =
		base:GetAttribute(
			"BaseNumber"
		)
		or
		0

	player:SetAttribute(
		"BaseNumber",
		baseNumber
	)

	print(
		"🏠 "
			..
			player.Name
			..
			" claimed BASE #"
			..
			tostring(
				baseNumber
			)
	)

	return base
end

--==================================================
-- SPAWN PLAYER INSIDE BASE
--==================================================

local function spawnPlayerAtBase(
	player,
	character
)

	local base =
		playerBases[player]

	if not base then

		base =
			claimBase(
				player
			)

	end

	if not base then

		return

	end

	--==================================================
	-- FIND ENTRANCE
	--==================================================

	local entrance =
		base:FindFirstChild(
			"Entrance",
			true
		)

	if
		not entrance
		or
		not entrance:IsA("BasePart")
	then

		warn(
			"❌ Entrance missing in "
				..
				base.Name
		)

		return

	end

	--==================================================
	-- WAIT FOR PLAYER CHARACTER
	--==================================================

	local root =
		character:WaitForChild(
			"HumanoidRootPart",
			10
		)

	if not root then

		warn(
			"❌ HumanoidRootPart missing for "
				..
				player.Name
		)

		return

	end

	--==================================================
	-- WAIT UNTIL ROBLOX FINISHES NORMAL SPAWN
	--==================================================

	task.wait(
		0.5
	)

	if not character.Parent then

		return

	end

	--==================================================
	-- TARGET INSIDE BASE
	--
	-- -Z from Entrance = inside the building.
	--==================================================

	local target =
		entrance.CFrame
		*
		CFrame.new(
			0,
			SPAWN_HEIGHT,
			-SPAWN_INSIDE_DISTANCE
		)

	--==================================================
	-- TELEPORT CHARACTER
	--==================================================

	character:PivotTo(
		target
	)

	local number =
		base:GetAttribute(
			"BaseNumber"
		)
		or
		0

	print(
		"📍 "
			..
			player.Name
			..
			" spawned inside BASE #"
			..
			tostring(
				number
			)
	)

end

--==================================================
-- SETUP PLAYER
--==================================================

local function setupPlayer(
	player
)

	local base =
		claimBase(
			player
		)

	if not base then

		return

	end

	--==================================================
	-- FUTURE RESPAWNS
	--==================================================

	player.CharacterAdded:Connect(
		function(character)

			task.spawn(
				spawnPlayerAtBase,
				player,
				character
			)

		end
	)

	--==================================================
	-- CHARACTER MAY ALREADY EXIST
	--==================================================

	if player.Character then

		task.spawn(
			spawnPlayerAtBase,
			player,
			player.Character
		)

	end

end

--==================================================
-- RELEASE BASE
--==================================================

local function releaseBase(
	player
)

	local base =
		playerBases[player]

	if not base then

		return

	end

	if
		base:GetAttribute(
			"OwnerUserId"
		)
		==
		player.UserId
	then

		base:SetAttribute(
			"OwnerUserId",
			0
		)

	end

	playerBases[player] =
		nil

end

--==================================================
-- RESET ALL BASES FOR NEW SERVER
--==================================================

for _, base in ipairs(
	getBases()
) do

	base:SetAttribute(
		"OwnerUserId",
		0
	)

	createBaseSign(
		base
	)

end

--==================================================
-- PLAYER EVENTS
--==================================================

Players.PlayerAdded:Connect(
	setupPlayer
)

Players.PlayerRemoving:Connect(
	releaseBase
)

--==================================================
-- STUDIO / PLAY MODE SUPPORT
--==================================================

for _, player in ipairs(
	Players:GetPlayers()
) do

	task.spawn(
		setupPlayer,
		player
	)

end

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("🏠 MULTI BASE SYSTEM V4 READY")
print("========================================")
print("🌍 PotatoWorld found")
print("🗺 PotatoWorld.mpa2 found")
print("🏠 Bases folder found")
print("✅ Automatic base claiming")
print("✅ Player spawn inside owned base")
print("✅ Respawn returns to same base")
print("🏷 Owner signs enabled")
print("========================================")
print("")