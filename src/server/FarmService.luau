local Players = game:GetService("Players")

local FarmService = {}

local world
local farmsFolder

local playerFarms = {}

--==================================================
-- SORT FARMS
--==================================================

local function getSortedFarms()

	local farms = {}

	for _, farm in ipairs(
		farmsFolder:GetChildren()
	) do

		if
			farm:IsA("Model")
			and
			farm:GetAttribute(
				"FarmNumber"
			) ~= nil
		then

			table.insert(
				farms,
				farm
			)
		end
	end

	table.sort(
		farms,

		function(a, b)

			return
				(a:GetAttribute(
					"FarmNumber"
				) or 999)
				<
				(b:GetAttribute(
					"FarmNumber"
				) or 999)

		end
	)

	return farms
end

--==================================================
-- FARM SIGN
--==================================================

local function setFarmSign(
	farm,
	text
)

	local sign =
		farm:FindFirstChild(
			"FarmSign",
			true
		)

	if not sign then
		return
	end

	local label =
		sign:FindFirstChild(
			"OwnerLabel",
			true
		)

	if label
		and
		label:IsA(
			"TextLabel"
		)
	then

		label.Text =
			text

	end
end

--==================================================
-- FIND FREE FARM
--==================================================

local function findFreeFarm()

	for _, farm in ipairs(
		getSortedFarms()
	) do

		if
			(farm:GetAttribute(
				"OwnerUserId"
			) or 0)
			== 0
		then

			return farm

		end
	end

	return nil
end

--==================================================
-- TELEPORT TO FARM
--==================================================

local function teleportToFarm(
	player,
	character
)

	local farm =
		playerFarms[
			player
		]

	if not farm then
		return
	end

	local spawnPoint =
		farm:FindFirstChild(
			"SpawnPoint",
			true
		)

	if not spawnPoint
		or
		not spawnPoint:IsA(
			"BasePart"
		)
	then

		return
	end

	local root =
		character:WaitForChild(
			"HumanoidRootPart",
			10
		)

	if not root then
		return
	end

	task.wait(
		0.15
	)

	root.AssemblyLinearVelocity =
		Vector3.zero

	root.AssemblyAngularVelocity =
		Vector3.zero

	root.CFrame =
		spawnPoint.CFrame
		* CFrame.new(
			0,
			3,
			0
		)
end

--==================================================
-- ASSIGN FARM
--==================================================

local function assignFarm(
	player
)

	if playerFarms[player] then
		return
	end

	--==================================================
	-- WAIT FOR DATA
	--==================================================

	while
		player.Parent
		and
		player:GetAttribute(
			"DataLoaded"
		) ~= true
	do

		task.wait(
			0.05
		)

	end

	if not player.Parent then
		return
	end

	local farm =
		findFreeFarm()

	if not farm then

		warn(
			"No free farm for "
				.. player.Name
		)

		return
	end

	playerFarms[
		player
	] =
		farm

	farm:SetAttribute(
		"OwnerUserId",
		player.UserId
	)

	local number =
		farm:GetAttribute(
			"FarmNumber"
		) or 0

	player:SetAttribute(
		"AssignedFarmName",
		farm.Name
	)

	player:SetAttribute(
		"AssignedFarmNumber",
		number
	)

	setFarmSign(
		farm,

		player.DisplayName
			.. "'s FARM"
	)

	print(
		player.Name
			.. " owns "
			.. farm.Name
	)

	if player.Character then

		task.spawn(
			teleportToFarm,
			player,
			player.Character
		)

	end
end

--==================================================
-- RELEASE FARM
--==================================================

local function releaseFarm(
	player
)

	local farm =
		playerFarms[
			player
		]

	if not farm then
		return
	end

	farm:SetAttribute(
		"OwnerUserId",
		0
	)

	local number =
		farm:GetAttribute(
			"FarmNumber"
		) or "?"

	setFarmSign(
		farm,
		"FARM "
			.. tostring(
				number
			)
	)

	playerFarms[
		player
	] =
		nil

	-- We intentionally do NOT clear
	-- AssignedFarmName here.
	--
	-- PotatoService can still use it during
	-- PlayerRemoving cleanup.
end

--==================================================
-- PLAYER
--==================================================

local function setupPlayer(
	player
)

	task.spawn(
		assignFarm,
		player
	)

	player.CharacterAdded:Connect(
		function(character)

			while
				player.Parent
				and
				not playerFarms[player]
			do

				task.wait(
					0.05
				)

			end

			if playerFarms[player] then

				teleportToFarm(
					player,
					character
				)

			end
		end
	)
end

--==================================================
-- API
--==================================================

function FarmService.GetPlayerFarm(
	player
)

	return
		playerFarms[
			player
		]
end

--==================================================
-- START
--==================================================

function FarmService.Start(
	potatoWorld
)

	world =
		potatoWorld

	farmsFolder =
		world:WaitForChild(
			"Farms"
		)

	Players.PlayerAdded:Connect(
		setupPlayer
	)

	Players.PlayerRemoving:Connect(
		releaseFarm
	)

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		setupPlayer(
			player
		)

	end

	print(
		"🏡 FarmService ready"
	)
end

return FarmService