local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

--==================================================
-- POTATO PLACEMENT PROMPT CLIENT V3
-- AUTO-RESCAN VERSION
--==================================================

local world = workspace:WaitForChild("PotatoWorld")
local farmsFolder = world:WaitForChild("Farms")

local PROMPT_DISTANCE = 12
local UPDATE_DELAY = 0.25

local connectedPlots = {}

--==================================================
-- GET EQUIPPED POTATO
--==================================================

local function getEquippedPotato()

	local character = player.Character

	if not character then
		return nil
	end

	for _, object in ipairs(character:GetChildren()) do

		if object:IsA("Tool") then

			if object:GetAttribute("PotatoInventoryTool") == true then
				return object
			end

		end

	end

	return nil
end

--==================================================
-- FIND PLAYER'S FARM
--==================================================

local function getOwnedFarm()

	for _, farm in ipairs(farmsFolder:GetChildren()) do

		if farm:IsA("Model") then

			if farm:GetAttribute("OwnerUserId") == player.UserId then
				return farm
			end

		end

	end

	return nil
end

--==================================================
-- CREATE PROMPT
--==================================================

local function connectPlot(farmLand, plantPoint)

	if connectedPlots[farmLand] then
		return
	end

	local oldPrompt = plantPoint:FindFirstChild("PotatoPlacePrompt")

	if oldPrompt then
		oldPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")

	prompt.Name = "PotatoPlacePrompt"

	prompt.ActionText = "Place Potato"

	prompt.ObjectText = farmLand.Name

	prompt.KeyboardKeyCode = Enum.KeyCode.E

	prompt.HoldDuration = 0

	prompt.MaxActivationDistance = PROMPT_DISTANCE

	prompt.RequiresLineOfSight = false

	prompt.Enabled = false

	prompt.Parent = plantPoint

	connectedPlots[farmLand] = {
		Prompt = prompt,
		PlantPoint = plantPoint,
	}

	print(
		"✅ Placement prompt connected:",
		farmLand.Name
	)

	--==================================================
	-- E PRESSED
	--==================================================

	prompt.Triggered:Connect(function()

		local potato = getEquippedPotato()

		if not potato then
			return
		end

		if farmLand:GetAttribute("Occupied") == true then
			return
		end

		local remotes =
			ReplicatedStorage:FindFirstChild(
				"PotatoPlacementRemotes"
			)

		if not remotes then

			warn(
				"✅ E PROMPT WORKS - placement server not installed yet"
			)

			return
		end

		local placeRemote =
			remotes:FindFirstChild(
				"PlacePotato"
			)

		if not placeRemote then

			warn(
				"❌ PlacePotato RemoteEvent missing"
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

	end)
end

--==================================================
-- SCAN FARM
--==================================================

local function scanFarm()

	local farm = getOwnedFarm()

	if not farm then
		return
	end

	local farmLands =
		farm:FindFirstChild(
			"FarmLands"
		)

	if not farmLands then
		return
	end

	for _, farmLand in ipairs(farmLands:GetChildren()) do

		if farmLand:IsA("Model") then

			local plantPoint =
				farmLand:FindFirstChild(
					"PlantPoint",
					true
				)

			if plantPoint and plantPoint:IsA("BasePart") then

				connectPlot(
					farmLand,
					plantPoint
				)

			end

		end

	end
end

--==================================================
-- UPDATE PROMPT VISIBILITY
--==================================================

local function updatePrompts()

	local potato =
		getEquippedPotato()

	for farmLand, info in pairs(connectedPlots) do

		local prompt =
			info.Prompt

		if not farmLand.Parent then

			if prompt then
				prompt:Destroy()
			end

			connectedPlots[farmLand] =
				nil

			continue
		end

		if not prompt or not prompt.Parent then

			connectedPlots[farmLand] =
				nil

			continue
		end

		local occupied =
			farmLand:GetAttribute(
				"Occupied"
			)
			==
			true

		--==================================================
		-- 🔒 LOCKED PLOT CHECK
		--==================================================

		local plotNumber =
			tonumber(
				string.match(
					farmLand.Name,
					"(%d+)$"
				)
			)

		local unlocked =
			true

		if
			plotNumber
			and
			plotNumber >= 5
			and
			plotNumber <= 8
		then

			unlocked =
				farmLand:GetAttribute(
					"PlotUnlocked"
				)
				==
				true

		end

		--==================================================
		-- SHOW PLACE PROMPT ONLY IF:
		--
		-- potato equipped
		-- plot empty
		-- plot unlocked
		--==================================================

		prompt.Enabled =
			potato ~= nil
			and
			not occupied
			and
			unlocked

	end
end  
--==================================================
-- MAIN LOOP
--==================================================

task.spawn(function()

	while true do

		scanFarm()

		updatePrompts()

		task.wait(
			UPDATE_DELAY
		)

	end

end)

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("🥔 FARM PLACEMENT CLIENT V3 READY")
print("========================================")
print("✅ Continuously scans FarmLands")
print("✅ Detects late PlantPoints")
print("✅ One prompt per FarmLand")
print("✅ E only while potato is equipped")
print("========================================")
print("")