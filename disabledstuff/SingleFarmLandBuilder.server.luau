local Players =
	game:GetService("Players")

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

local player =
	Players.LocalPlayer

--==================================================
-- FARM POTATO PLACEMENT CLIENT V2
--
-- Does NOT wait for server remote.
-- Therefore prompts can appear before
-- PotatoPlacementService is installed.
--==================================================

local world =
	workspace:WaitForChild(
		"PotatoWorld"
	)

local farmsFolder =
	world:WaitForChild(
		"Farms"
	)

--==================================================
-- SETTINGS
--==================================================

local PROMPT_DISTANCE =
	10

local UPDATE_DELAY =
	0.15

--==================================================
-- STATE
--==================================================

local currentFarm =
	nil

local currentFarmLands =
	nil

local promptData =
	{}

--==================================================
-- EQUIPPED POTATO
--==================================================

local function getEquippedPotato()

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
-- FIND OWNED FARM
--==================================================

local function getOwnedFarm()

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
-- CLEAR PROMPTS
--==================================================

local function clearPrompts()

	for _, info in ipairs(
		promptData
	) do

		if
			info.Prompt
			and
			info.Prompt.Parent
		then

			info.Prompt:Destroy()

		end

	end

	table.clear(
		promptData
	)

	currentFarm =
		nil

	currentFarmLands =
		nil

end

--==================================================
-- CREATE ONE PROMPT
--==================================================

local function createPrompt(
	farmLand,
	plantPoint
)

	local oldPrompt =
		plantPoint:FindFirstChild(
			"PotatoPlacePrompt"
		)

	if oldPrompt then
		oldPrompt:Destroy()
	end

	local prompt =
		Instance.new(
			"ProximityPrompt"
		)

	prompt.Name =
		"PotatoPlacePrompt"

	prompt.ActionText =
		"Place Potato"

	prompt.ObjectText =
		farmLand.Name

	prompt.KeyboardKeyCode =
		Enum.KeyCode.E

	prompt.HoldDuration =
		0

	prompt.MaxActivationDistance =
		PROMPT_DISTANCE

	prompt.RequiresLineOfSight =
		false

	prompt.Enabled =
		false

	prompt.Parent =
		plantPoint

	--==================================================
	-- E PRESSED
	--==================================================

	prompt.Triggered:Connect(
		function()

			local potato =
				getEquippedPotato()

			if not potato then

				print(
					"⚠ No potato equipped"
				)

				return

			end

			if
				farmLand:GetAttribute(
					"Occupied"
				)
				==
				true
			then

				print(
					"⚠ FarmLand already occupied"
				)

				return

			end

			--==================================================
			-- REMOTE CHECK
			--
			-- IMPORTANT:
			-- FindFirstChild, NOT WaitForChild.
			--==================================================

			local remotes =
				ReplicatedStorage:FindFirstChild(
					"PotatoPlacementRemotes"
				)

			if not remotes then

				warn(
					"⚠ E PROMPT WORKS! Placement server is next."
				)

				return

			end

			local placeRemote =
				remotes:FindFirstChild(
					"PlacePotato"
				)

			if
				not placeRemote
				or
				not placeRemote:IsA(
					"RemoteEvent"
				)
			then

				warn(
					"⚠ PlacePotato RemoteEvent missing"
				)

				return

			end

			print(
				"🥔 PLACE REQUEST:",
				farmLand.Name,
				potato.Name
			)

			placeRemote:FireServer(
				farmLand
			)

		end
	)

	table.insert(
		promptData,
		{
			Prompt = prompt,
			FarmLand = farmLand,
		}
	)

end

--==================================================
-- SETUP FARM
--==================================================

local function setupFarm(
	farm
)

	clearPrompts()

	currentFarm =
		farm

	local farmLands =
		farm:FindFirstChild(
			"FarmLands"
		)

	if not farmLands then

		warn(
			"❌ FarmLands missing inside "
				..
				farm.Name
		)

		return

	end

	currentFarmLands =
		farmLands

	local created =
		0

	--==================================================
	-- FARM LAND 01 - 08
	--==================================================

	for _, farmLand in ipairs(
		farmLands:GetChildren()
	) do

		if farmLand:IsA("Model") then

			local plantPoint =
				farmLand:FindFirstChild(
					"PlantPoint",
					true
				)

			if
				plantPoint
				and
				plantPoint:IsA("BasePart")
			then

				createPrompt(
					farmLand,
					plantPoint
				)

				created +=
					1

			else

				warn(
					"❌ PlantPoint missing: "
						..
						farmLand.Name
				)

			end

		end

	end

	print(
		"✅ Placement farm found:",
		farm.Name
	)

	print(
		"✅ Placement prompts created:",
		created
	)

end

--==================================================
-- UPDATE
--==================================================

local function update()

	local farm =
		getOwnedFarm()

	--==================================================
	-- FARM NOT ASSIGNED YET
	--==================================================

	if not farm then

		if currentFarm then
			clearPrompts()
		end

		return

	end

	--==================================================
	-- NEW FARM
	--==================================================

	if
		farm
		~=
		currentFarm
	then

		setupFarm(
			farm
		)

	end

	local potato =
		getEquippedPotato()

	--==================================================
	-- ENABLE / DISABLE
	--==================================================

	for _, info in ipairs(
		promptData
	) do

		local prompt =
			info.Prompt

		local farmLand =
			info.FarmLand

		if
			prompt
			and
			prompt.Parent
			and
			farmLand
			and
			farmLand.Parent
		then

			local occupied =
				farmLand:GetAttribute(
					"Occupied"
				)
				==
				true

			prompt.Enabled =
				potato
				~=
				nil
				and
				not occupied

		end

	end

end

--==================================================
-- RESPAWN
--==================================================

player.CharacterAdded:Connect(
	function()

		task.wait(
			1
		)

		update()

	end
)

--==================================================
-- LOOP
--==================================================

task.spawn(
	function()

		while true do

			update()

			task.wait(
				UPDATE_DELAY
			)

		end

	end
)

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("🥔 FARM PLACEMENT CLIENT V2 READY")
print("========================================")
print("✅ No RemoteEvent infinite wait")
print("✅ Farm_01 ownership detection")
print("✅ FarmLand_01 - FarmLand_08")
print("✅ One PlantPoint per land")
print("✅ E appears only with potato equipped")
print("========================================")
print("")