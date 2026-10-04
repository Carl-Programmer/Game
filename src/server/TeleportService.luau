local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeleportService = {}

--==================================================
-- SETTINGS
--==================================================

local TELEPORT_DELAY = 0.5
local TELEPORT_COOLDOWN = 0.5

local started = false

--==================================================
-- STATE
--==================================================

local world = nil
local farmsFolder = nil
local centralTown = nil
local foragingZone = nil

local lastTeleportTimes = {}
local teleportingPlayers = {}

--==================================================
-- REMOTES
--==================================================

local remotes =
	ReplicatedStorage:FindFirstChild(
		"PotatoTeleportRemotes"
	)

if not remotes then

	remotes =
		Instance.new("Folder")

	remotes.Name =
		"PotatoTeleportRemotes"

	remotes.Parent =
		ReplicatedStorage

end

local RequestTeleport =
	remotes:FindFirstChild(
		"RequestTeleport"
	)

if not RequestTeleport then

	RequestTeleport =
		Instance.new("RemoteEvent")

	RequestTeleport.Name =
		"RequestTeleport"

	RequestTeleport.Parent =
		remotes

end

local TeleportStatus =
	remotes:FindFirstChild(
		"TeleportStatus"
	)

if not TeleportStatus then

	TeleportStatus =
		Instance.new("RemoteEvent")

	TeleportStatus.Name =
		"TeleportStatus"

	TeleportStatus.Parent =
		remotes

end

--==================================================
-- CHARACTER
--==================================================

local function getCharacter(player)

	return player.Character

end

local function getRoot(player)

	local character =
		getCharacter(player)

	if not character then
		return nil
	end

	return character:FindFirstChild(
		"HumanoidRootPart"
	)

end

--==================================================
-- CHECK IF POSITION IS INSIDE GROUND
--==================================================

local function pointInsideGround(
	ground,
	position
)

	if
		not ground
		or
		not ground:IsA("BasePart")
	then

		return false

	end

	local localPosition =
		ground.CFrame
			:PointToObjectSpace(
				position
			)

	local half =
		ground.Size / 2

	return

		math.abs(
			localPosition.X
		)
		<=
		half.X

		and

		math.abs(
			localPosition.Z
		)
		<=
		half.Z

		and

		localPosition.Y >= -10

		and

		localPosition.Y <= 18

end

--==================================================
-- PLAYER INSIDE FORAGING AREA
--==================================================

local function isPlayerInForagingZone(
	player
)

	if not foragingZone then
		return false
	end

	local root =
		getRoot(player)

	if not root then
		return false
	end

	--==================================================
	-- Check every numbered foraging zone.
	--==================================================

	for _, object in ipairs(
		foragingZone:GetChildren()
	) do

		if object:IsA("Model") then

			local zoneNumber =
				object:GetAttribute(
					"ZoneNumber"
				)

			if zoneNumber then

				local ground =
					object:FindFirstChild(
						"Ground"
					)

				if
					ground
					and
					pointInsideGround(
						ground,
						root.Position
					)
				then

					return true

				end

			end

		end

	end

	return false

end

--==================================================
-- TELEPORT CHARACTER
--==================================================

local function moveCharacter(
	player,
	targetCFrame
)

	local character =
		getCharacter(player)

	if not character then
		return false
	end

	if not character.PrimaryPart then

		local root =
			getRoot(player)

		if not root then
			return false
		end

		character.PrimaryPart =
			root

	end

	-- Slight height so player does not spawn
	-- inside the floor.

	character:PivotTo(
		targetCFrame
		*
		CFrame.new(
			0,
			3,
			0
		)
	)

	return true

end

--==================================================
-- FIND PLAYER FARM
--==================================================

local function getPlayerFarm(
	player
)

	if not farmsFolder then
		return nil
	end

	for _, farm in ipairs(
		farmsFolder:GetChildren()
	) do

		if farm:IsA("Model") then

			if
				farm:GetAttribute(
					"OwnerUserId"
				)
				==
				player.UserId
			then

				return farm

			end

		end

	end

	return nil

end

--==================================================
-- HOME TARGET
--==================================================

local function getHomeTarget(
	player
)

	local farm =
		getPlayerFarm(player)

	if not farm then
		return nil
	end

	--==================================================
	-- Preferred exact SpawnPoint
	--==================================================

	local spawnPoint =
		farm:FindFirstChild(
			"SpawnPoint",
			true
		)

	if
		spawnPoint
		and
		spawnPoint:IsA("BasePart")
	then

		return spawnPoint.CFrame

	end

	--==================================================
	-- Backup model pivot
	--==================================================

	return farm:GetPivot()

end

--==================================================
-- TOWN TARGET
--==================================================

local function getTownTarget()

	if not centralTown then
		return nil
	end

	--==================================================
	-- Try dedicated teleport points first.
	--==================================================

	local possibleNames = {
		"TownSpawn",
		"TownTeleport",
		"TeleportPoint",
		"SpawnPoint",
	}

	for _, name in ipairs(
		possibleNames
	) do

		local point =
			centralTown:FindFirstChild(
				name,
				true
			)

		if
			point
			and
			point:IsA("BasePart")
		then

			return point.CFrame

		end

	end

	--==================================================
	-- TownPlaza fallback
	--==================================================

	local plaza =
		centralTown:FindFirstChild(
			"TownPlaza"
		)

	if
		plaza
		and
		plaza:IsA("BasePart")
	then

		return plaza.CFrame

	end

	if
		plaza
		and
		plaza:IsA("Model")
	then

		return plaza:GetPivot()

	end

	return centralTown:GetPivot()

end

--==================================================
-- HUNT TARGET
--==================================================

local function getHuntTarget()

	if not foragingZone then
		return nil
	end

	--==================================================
	-- Preferred entrance
	--==================================================

	local entrance =
		foragingZone:FindFirstChild(
			"ForagingEntrance",
			true
		)

	if entrance then

		if entrance:IsA("BasePart") then

			return entrance.CFrame

		end

		if entrance:IsA("Model") then

			return entrance:GetPivot()

		end

	end

	--==================================================
	-- Try common entrance/spawn names.
	--==================================================

	local possibleNames = {
		"HuntSpawn",
		"ForagingSpawn",
		"EntranceSpawn",
		"TeleportPoint",
	}

	for _, name in ipairs(
		possibleNames
	) do

		local point =
			foragingZone:FindFirstChild(
				name,
				true
			)

		if
			point
			and
			point:IsA("BasePart")
		then

			return point.CFrame

		end

	end

	--==================================================
	-- Final fallback:
	-- Zone 1 Ground edge/center.
	--==================================================

	for _, object in ipairs(
		foragingZone:GetChildren()
	) do

		if
			object:IsA("Model")
			and
			object:GetAttribute(
				"ZoneNumber"
			)
			==
			1
		then

			local ground =
				object:FindFirstChild(
					"Ground"
				)

			if
				ground
				and
				ground:IsA("BasePart")
			then

				return ground.CFrame

			end

		end

	end

	return nil

end

--==================================================
-- DESTINATION
--==================================================

local function getDestination(
	player,
	destination
)

	if destination == "HOME" then

		return getHomeTarget(
			player
		)

	elseif destination == "TOWN" then

		return getTownTarget()

	elseif destination == "HUNT" then

		return getHuntTarget()

	end

	return nil

end

--==================================================
-- REQUEST
--==================================================

local function handleTeleport(
	player,
	destination
)

	--==================================================
	-- VALID DESTINATION
	--==================================================

	if
		destination ~= "HOME"
		and
		destination ~= "TOWN"
		and
		destination ~= "HUNT"
	then

		return

	end

	--==================================================
	-- BLOCK TELEPORTING FROM FORAGING ZONES
	--==================================================

	if
		isPlayerInForagingZone(
			player
		)
	then

		TeleportStatus:FireClient(
			player,
			"BLOCKED_FORAGING"
		)

		return

	end

	--==================================================
	-- ALREADY TELEPORTING
	--==================================================

	if teleportingPlayers[player] then
		return
	end

	--==================================================
	-- COOLDOWN
	--==================================================

	local now =
		os.clock()

	local previous =
		lastTeleportTimes[player]
		or
		0

	if
		now - previous
		<
		TELEPORT_COOLDOWN
	then

		return

	end

	--==================================================
	-- TARGET
	--==================================================

	local target =
		getDestination(
			player,
			destination
		)

	if not target then

		warn(
			"❌ No teleport target for "
			..
			destination
			..
			" | "
			..
			player.Name
		)

		TeleportStatus:FireClient(
			player,
			"FAILED"
		)

		return

	end

	--==================================================
	-- BEGIN 0.5 SECOND TELEPORT
	--==================================================

	teleportingPlayers[player] =
		true

	TeleportStatus:FireClient(
		player,
		"STARTED",
		destination,
		TELEPORT_DELAY
	)

	task.delay(
		TELEPORT_DELAY,

		function()

			-- Player may have entered a foraging zone
			-- during the 0.5 second delay.

			if
				destination ~= "HUNT"
				and
				isPlayerInForagingZone(
					player
				)
			then

				teleportingPlayers[player] =
					nil

				TeleportStatus:FireClient(
					player,
					"BLOCKED_FORAGING"
				)

				return

			end

			local success =
				moveCharacter(
					player,
					target
				)

			teleportingPlayers[player] =
				nil

			if success then

				lastTeleportTimes[player] =
					os.clock()

				TeleportStatus:FireClient(
					player,
					"FINISHED",
					destination
				)

				print(
					"🧭 "
					..
					player.Name
					..
					" teleported to "
					..
					destination
				)

			else

				TeleportStatus:FireClient(
					player,
					"FAILED"
				)

			end

		end
	)

end

--==================================================
-- START
--==================================================

function TeleportService.Start(
	potatoWorld
)

	if started then
		return
	end

	started =
		true

	world =
		potatoWorld

	farmsFolder =
		world:WaitForChild(
			"Farms"
		)

	centralTown =
		world:WaitForChild(
			"CentralTown"
		)

	foragingZone =
		world:WaitForChild(
			"ForagingZone"
		)

	RequestTeleport.OnServerEvent:Connect(
		function(
			player,
			destination
		)

			handleTeleport(
				player,
				destination
			)

		end
	)

	Players.PlayerRemoving:Connect(
		function(player)

			lastTeleportTimes[player] =
				nil

			teleportingPlayers[player] =
				nil

		end
	)

	print("")
	print("========================================")
	print("🚀 TELEPORT SERVICE READY")
	print("========================================")
	print("🏡 HOME ready")
	print("🏘 TOWN ready")
	print("⛏ HUNT ready")
	print("⏱ Teleport delay = 0.5 seconds")
	print("🚫 Teleports blocked inside foraging zones")
	print("========================================")
	print("")

end

return TeleportService