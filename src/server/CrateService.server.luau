--========================================================
-- POTATIUM - CRATE SERVICE V2.3 - HOE FAVORITES
--
-- ✅ Wooden Crates persist
-- ✅ Wooden / Stone / Iron hoe rewards persist
-- ✅ Each crate hoe has its own HoeId
-- ✅ Each crate hoe saves remaining durability
-- ✅ Uses your designed hoe models when available
--
-- DESIGNED MODELS:
--   WoodenHoe_2
--   stonehoe
--   ironhoe
--
-- Recommended Studio location:
--   ReplicatedStorage
--   └── HoeModels
--       ├── WoodenHoe_2   (optional - existing system can keep it)
--       ├── stonehoe
--       └── ironhoe
--
-- The source can be either a Tool or Model.
-- No custom animation is required yet.
--========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataService =
	require(
		script.Parent:WaitForChild(
			"DataService"
		)
	)

local WoodenCrate =
	require(
		script.Parent
			:WaitForChild("Crates")
			:WaitForChild("WoodenCrate")
	)

local HoeConfig =
	require(
		script.Parent
			:WaitForChild("Hoes")
			:WaitForChild("HoeConfig")
	)

--========================================================
-- REMOTES
--========================================================

local remotes =
	ReplicatedStorage:FindFirstChild(
		"PotatiumCrateRemotes"
	)

if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "PotatiumCrateRemotes"
	remotes.Parent = ReplicatedStorage
end

local requestOpen =
	remotes:FindFirstChild(
		"RequestOpenCrate"
	)

if not requestOpen then
	requestOpen = Instance.new("RemoteEvent")
	requestOpen.Name = "RequestOpenCrate"
	requestOpen.Parent = remotes
end

local openResult =
	remotes:FindFirstChild(
		"CrateOpenResult"
	)

if not openResult then
	openResult = Instance.new("RemoteEvent")
	openResult.Name = "CrateOpenResult"
	openResult.Parent = remotes
end

local messageRemote =
	remotes:FindFirstChild(
		"CrateMessage"
	)

if not messageRemote then
	messageRemote = Instance.new("RemoteEvent")
	messageRemote.Name = "CrateMessage"
	messageRemote.Parent = remotes
end


local getEquipmentSnapshot =
	remotes:FindFirstChild(
		"GetEquipmentSnapshot"
	)

if not getEquipmentSnapshot then
	getEquipmentSnapshot =
		Instance.new(
			"RemoteFunction"
		)

	getEquipmentSnapshot.Name =
		"GetEquipmentSnapshot"

	getEquipmentSnapshot.Parent =
		remotes
end

--========================================================
-- SETTINGS
--========================================================

local OPEN_LOCK_TIME = 4.6
local rng = Random.new()
local openingPlayers = {}

--========================================================
-- COMMON HELPERS
--========================================================

local function normalizeName(value)
	return
		string.lower(
			tostring(
				value
				or
				""
			)
		)
		:gsub(
			"[^%w]",
			""
		)
end

local function bumpRevision(
	player,
	attributeName
)
	player:SetAttribute(
		attributeName,
		(
			player:GetAttribute(
				attributeName
			)
			or
			0
		)
		+
		1
	)
end

local function getToolPlaces(player)
	local places = {}

	local backpack =
		player:FindFirstChild(
			"Backpack"
		)

	if backpack then
		table.insert(
			places,
			backpack
		)
	end

	if player.Character then
		table.insert(
			places,
			player.Character
		)
	end

	return places
end

--========================================================
-- EQUIPMENT DATA
--
-- V2 format:
--
-- Equipment = {
--     Crates = {
--         Wooden = 2
--     },
--
--     HoeInventory = {
--         {
--             Id = "H1",
--             Tier = "Stone",
--             Durability = 31,
--             MaxDurability = 40,
--         }
--     },
--
--     NextHoeId = 2,
-- }
--
-- The old V1 Hoes = {Wooden=, Stone=, Iron=} counts
-- are automatically migrated once.
--========================================================

local function migrateOldHoeCounts(
	equipment
)
	if
		equipment.HoeInventoryMigrated
		==
		true
	then
		return false
	end

	if
		type(
			equipment.HoeInventory
		)
		~=
		"table"
	then
		equipment.HoeInventory = {}
	end

	equipment.NextHoeId =
		math.max(
			1,
			math.floor(
				tonumber(
					equipment.NextHoeId
				)
				or
				1
			)
		)

	-- Only migrate counts when no V2 records exist.
	if
		#equipment.HoeInventory
		==
		0
		and
		type(
			equipment.Hoes
		)
		==
		"table"
	then
		for _, tier in ipairs(
			HoeConfig.Order
		) do
			local count =
				math.max(
					0,
					math.floor(
						tonumber(
							equipment.Hoes[
								tier
							]
						)
						or
						0
					)
				)

			local stats =
				HoeConfig.Get(
					tier
				)

			for _ = 1, count do
				local id =
					"H"
					..
					tostring(
						equipment.NextHoeId
					)

				equipment.NextHoeId += 1

				table.insert(
					equipment.HoeInventory,
					{
						Id = id,
						Tier = tier,
						Durability =
							stats.MaxDurability,
						MaxDurability =
							stats.MaxDurability,
						Favorite = false,
					}
				)
			end
		end
	end

	-- Old counts are no longer authoritative.
	equipment.Hoes = {
		Wooden = 0,
		Stone = 0,
		Iron = 0,
	}

	equipment.HoeInventoryMigrated =
		true

	return true
end

local function sanitizeHoeRecords(
	equipment
)
	local changed =
		false

	if
		type(
			equipment.HoeInventory
		)
		~=
		"table"
	then
		equipment.HoeInventory = {}
		changed = true
	end

	local cleaned = {}

	for _, record in ipairs(
		equipment.HoeInventory
	) do
		if
			type(record)
			==
			"table"
		then
			local tier =
				tostring(
					record.Tier
					or
					""
				)

			local stats =
				HoeConfig.Get(
					tier
				)

			if stats then
				local id =
					tostring(
						record.Id
						or
						""
					)

				if id ~= "" then
					local maxDurability =
						stats.MaxDurability

					local durability =
						math.clamp(
							math.floor(
								tonumber(
									record.Durability
								)
								or
								maxDurability
							),
							0,
							maxDurability
						)

					if durability > 0 then
						table.insert(
							cleaned,
							{
								Id = id,
								Tier = tier,
								Durability =
									durability,
								MaxDurability =
									maxDurability,
								Favorite =
									record.Favorite
									==
									true,
							}
						)
					else
						changed = true
					end
				else
					changed = true
				end
			else
				changed = true
			end
		else
			changed = true
		end
	end

	if
		#cleaned
		~=
		#equipment.HoeInventory
	then
		changed = true
	end

	equipment.HoeInventory =
		cleaned

	return changed
end

local function getEquipment(player)
	local equipment =
		DataService.GetEquipment(
			player
		)

	if type(equipment) ~= "table" then
		equipment = {}
	end

	if type(equipment.Crates) ~= "table" then
		equipment.Crates = {}
	end

	equipment.Crates.Wooden =
		math.max(
			0,
			math.floor(
				tonumber(
					equipment.Crates.Wooden
				)
				or
				0
			)
		)

	equipment.NextHoeId =
		math.max(
			1,
			math.floor(
				tonumber(
					equipment.NextHoeId
				)
				or
				1
			)
		)

	local changed =
		migrateOldHoeCounts(
			equipment
		)

	if
		sanitizeHoeRecords(
			equipment
		)
	then
		changed = true
	end

	if changed then
		DataService.SetEquipment(
			player,
			equipment
		)
	end

	return equipment
end

--========================================================
-- CLIENT EQUIPMENT SNAPSHOT
--
-- BackpackClient uses this only for DISPLAY/synchronization.
-- The client still cannot create/save rewards itself.
--========================================================

getEquipmentSnapshot.OnServerInvoke =
	function(player)
		if
			player:GetAttribute(
				"DataLoaded"
			)
			~=
			true
		then
			return {
				Crates = {
					Wooden = 0,
				},

				HoeInventory = {},
			}
		end

		local equipment =
			getEquipment(
				player
			)

		local response = {
			Crates = {
				Wooden =
					math.max(
						0,
						math.floor(
							tonumber(
								equipment.Crates
								and
								equipment.Crates.Wooden
							)
							or
							0
						)
					),
			},

			HoeInventory = {},
		}

		for _, record in ipairs(
			equipment.HoeInventory
			or
			{}
		) do
			if
				type(record)
				==
				"table"
				and
				record.Id ~= nil
			then
				table.insert(
					response.HoeInventory,
					{
						Id =
							record.Id,

						Tier =
							tostring(
								record.Tier
								or
								"Wooden"
							),

						Durability =
							tonumber(
								record.Durability
							)
							or
							0,

						MaxDurability =
							tonumber(
								record.MaxDurability
							)
							or
							0,

						Favorite =
							record.Favorite
							==
							true,
					}
				)
			end
		end

		return response
	end

local function saveEquipment(
	player,
	equipment
)
	DataService.SetEquipment(
		player,
		equipment
	)
end

local function addHoeRecord(
	equipment,
	tier
)
	local stats =
		HoeConfig.Get(
			tier
		)

	if not stats then
		return nil
	end

	equipment.NextHoeId =
		math.max(
			1,
			math.floor(
				tonumber(
					equipment.NextHoeId
				)
				or
				1
			)
		)

	local id =
		"H"
		..
		tostring(
			equipment.NextHoeId
		)

	equipment.NextHoeId += 1

	local record = {
		Id = id,
		Tier = tier,
		Durability =
			stats.MaxDurability,
		MaxDurability =
			stats.MaxDurability,
		Favorite = false,
	}

	table.insert(
		equipment.HoeInventory,
		record
	)

	return record
end

--========================================================
-- WOODEN CRATE TOOL
--========================================================

local function addWeld(
	part0,
	part1
)
	local weld =
		Instance.new(
			"WeldConstraint"
		)

	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part1
end

local function addCrateSlat(
	handle,
	size,
	offset
)
	local slat =
		Instance.new("Part")

	slat.Name = "CrateSlat"
	slat.Size = size
	slat.Color =
		Color3.fromRGB(
			90,
			54,
			29
		)
	slat.Material =
		Enum.Material.WoodPlanks
	slat.Anchored = false
	slat.CanCollide = false
	slat.CanTouch = false
	slat.CanQuery = false
	slat.Massless = true
	slat.CFrame =
		handle.CFrame
		*
		CFrame.new(
			offset.X,
			offset.Y,
			offset.Z
		)
	slat.Parent = handle.Parent

	addWeld(
		handle,
		slat
	)
end

local function createWoodenCrateTool(
	player,
	count
)
	local backpack =
		player:WaitForChild(
			"Backpack"
		)

	local tool =
		Instance.new("Tool")

	tool.Name =
		count > 1
		and
		(
			"Wooden Crate x"
			..
			count
		)
		or
		"Wooden Crate"

	tool.ToolTip =
		"Equip and click to open\nWooden 75% | Stone 20% | Iron 5%"

	tool.RequiresHandle = true
	tool.CanBeDropped = false

	tool:SetAttribute(
		"CrateTool",
		true
	)
	tool:SetAttribute(
		"CrateType",
		"Wooden"
	)
	tool:SetAttribute(
		"CrateCount",
		count
	)
	tool:SetAttribute(
		"ItemCategory",
		"Materials"
	)

	local handle =
		Instance.new("Part")

	handle.Name = "Handle"
	handle.Size =
		Vector3.new(
			1.55,
			1.55,
			1.55
		)
	handle.Color =
		Color3.fromRGB(
			154,
			99,
			50
		)
	handle.Material =
		Enum.Material.WoodPlanks
	handle.Anchored = false
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Parent = tool

	addCrateSlat(
		handle,
		Vector3.new(
			1.68,
			0.18,
			1.68
		),
		Vector3.new(
			0,
			0.54,
			0
		)
	)

	addCrateSlat(
		handle,
		Vector3.new(
			1.68,
			0.18,
			1.68
		),
		Vector3.new(
			0,
			-0.54,
			0
		)
	)

	tool.Grip =
		CFrame.new(
			0,
			-0.1,
			-0.8
		)

	tool.Parent =
		backpack

	return tool
end

local function getCrateTools(
	player
)
	local result = {}

	for _, place in ipairs(
		getToolPlaces(
			player
		)
	) do
		for _, object in ipairs(
			place:GetChildren()
		) do
			if
				object:IsA("Tool")
				and
				object:GetAttribute(
					"CrateType"
				)
				==
				"Wooden"
			then
				table.insert(
					result,
					object
				)
			end
		end
	end

	return result
end

local function syncCrateTool(
	player
)
	if
		player:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	then
		return
	end

	local equipment =
		getEquipment(
			player
		)

	local count =
		equipment.Crates.Wooden
		or
		0

	local tools =
		getCrateTools(
			player
		)

	if count <= 0 then
		for _, tool in ipairs(
			tools
		) do
			tool:Destroy()
		end

		return
	end

	local keep =
		tools[1]

	if not keep then
		keep =
			createWoodenCrateTool(
				player,
				count
			)
	else
		keep.Name =
			count > 1
			and
			(
				"Wooden Crate x"
				..
				count
			)
			or
			"Wooden Crate"

		keep:SetAttribute(
			"CrateCount",
			count
		)
	end

	for index = 2, #tools do
		tools[index]:Destroy()
	end
end

--========================================================
-- DESIGNED HOE MODEL SUPPORT
--========================================================

local function findNamedDescendant(
	rootObject,
	wantedName
)
	if not rootObject then
		return nil
	end

	local normalizedWanted =
		normalizeName(
			wantedName
		)

	for _, object in ipairs(
		rootObject:GetDescendants()
	) do
		if
			(
				object:IsA("Tool")
				or
				object:IsA("Model")
			)
			and
			normalizeName(
				object.Name
			)
			==
			normalizedWanted
		then
			return object
		end
	end

	return nil
end

local function findHoeAsset(
	tier
)
	local stats =
		HoeConfig.Get(
			tier
		)

	if not stats then
		return nil
	end

	local modelName =
		stats.ModelName

	local replicatedFolder =
		ReplicatedStorage:FindFirstChild(
			"HoeModels"
		)

	local serverFolder =
		ServerStorage:FindFirstChild(
			"HoeModels"
		)

	for _, searchRoot in ipairs({
		replicatedFolder,
		serverFolder,
		ReplicatedStorage,
		ServerStorage,
	}) do
		local found =
			findNamedDescendant(
				searchRoot,
				modelName
			)

		if found then
			return found
		end
	end

	return nil
end

local function preparePart(
	part
)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
end

local function ensureDirectHandle(
	tool
)
	local directHandle =
		tool:FindFirstChild(
			"Handle"
		)

	if
		directHandle
		and
		directHandle:IsA(
			"BasePart"
		)
	then
		preparePart(
			directHandle
		)

		return directHandle
	end

	local visualParts = {}

	for _, object in ipairs(
		tool:GetDescendants()
	) do
		if object:IsA("BasePart") then
			table.insert(
				visualParts,
				object
			)
		end
	end

	local handle =
		Instance.new("Part")

	handle.Name = "Handle"
	handle.Size =
		Vector3.new(
			0.2,
			0.2,
			0.2
		)
	handle.Transparency = 1
	handle.Anchored = false
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true

	if visualParts[1] then
		handle.CFrame =
			visualParts[1].CFrame
	end

	handle.Parent =
		tool

	for _, part in ipairs(
		visualParts
	) do
		preparePart(
			part
		)

		addWeld(
			handle,
			part
		)
	end

	return handle
end

local function toolFromAsset(
	asset,
	tier
)
	if not asset then
		return nil
	end

	local stats =
		HoeConfig.Get(
			tier
		)

	if not stats then
		return nil
	end

	local tool

	if asset:IsA("Tool") then
		tool =
			asset:Clone()

		ensureDirectHandle(
			tool
		)
	else
		tool =
			Instance.new(
				"Tool"
			)

		local modelClone =
			asset:Clone()

		modelClone.Name =
			"Visual"

		modelClone.Parent =
			tool

		local visualParts = {}

		for _, object in ipairs(
			modelClone:GetDescendants()
		) do
			if object:IsA("BasePart") then
				preparePart(
					object
				)

				table.insert(
					visualParts,
					object
				)
			end
		end

		local handle =
			Instance.new("Part")

		handle.Name = "Handle"
		handle.Size =
			Vector3.new(
				0.2,
				0.2,
				0.2
			)
		handle.Transparency = 1
		handle.Anchored = false
		handle.CanCollide = false
		handle.CanTouch = false
		handle.CanQuery = false
		handle.Massless = true

		if
			modelClone:IsA("Model")
			and
			#visualParts > 0
		then
			handle.CFrame =
				modelClone:GetPivot()
		elseif visualParts[1] then
			handle.CFrame =
				visualParts[1].CFrame
		end

		handle.Parent =
			tool

		for _, part in ipairs(
			visualParts
		) do
			addWeld(
				handle,
				part
			)
		end
	end

	tool.Name =
		stats.DisplayName

	tool.RequiresHandle =
		true

	tool.CanBeDropped =
		false

	return tool
end

local function createFallbackHoe(
	tier
)
	local stats =
		HoeConfig.Get(
			tier
		)

	local tool =
		Instance.new("Tool")

	tool.Name =
		stats.DisplayName

	tool.RequiresHandle =
		true

	tool.CanBeDropped =
		false

	local handle =
		Instance.new("Part")

	handle.Name = "Handle"
	handle.Size =
		Vector3.new(
			0.28,
			3.2,
			0.28
		)
	handle.Color =
		Color3.fromRGB(
			105,
			72,
			45
		)
	handle.Material =
		Enum.Material.Wood
	handle.Anchored = false
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Parent =
		tool

	local head =
		Instance.new("Part")

	head.Name = "HoeHead"
	head.Size =
		Vector3.new(
			1.55,
			0.32,
			0.45
		)
	head.Anchored = false
	head.CanCollide = false
	head.CanTouch = false
	head.CanQuery = false
	head.Massless = true

	if tier == "Stone" then
		head.Color =
			Color3.fromRGB(
				120,
				122,
				126
			)
		head.Material =
			Enum.Material.Slate
	elseif tier == "Iron" then
		head.Color =
			Color3.fromRGB(
				173,
				178,
				184
			)
		head.Material =
			Enum.Material.Metal
	else
		head.Color =
			Color3.fromRGB(
				132,
				86,
				45
			)
		head.Material =
			Enum.Material.Wood
	end

	head.CFrame =
		handle.CFrame
		*
		CFrame.new(
			0.58,
			1.42,
			0
		)

	head.Parent =
		tool

	addWeld(
		handle,
		head
	)

	return tool
end

local function createHoeTool(
	player,
	record
)
	local tier =
		record.Tier

	local stats =
		HoeConfig.Get(
			tier
		)

	if not stats then
		return nil
	end

	local asset =
		findHoeAsset(
			tier
		)

	local tool =
		toolFromAsset(
			asset,
			tier
		)

	if not tool then
		warn(
			"⚠ "
			..
			stats.ModelName
			..
			" not found; using temporary fallback hoe."
		)

		tool =
			createFallbackHoe(
				tier
			)
	end

	tool:SetAttribute(
		"CrateHoe",
		true
	)

	tool:SetAttribute(
		"HoeId",
		record.Id
	)

	tool:SetAttribute(
		"Favorite",
		record.Favorite
		==
		true
	)

	tool:SetAttribute(
		"LocalFavorite",
		record.Favorite
		==
		true
	)

	HoeConfig.ApplyAttributes(
		tool,
		tier,
		record.Durability
	)

	tool.ToolTip =
		stats.DisplayName
		..
		"\nDurability "
		..
		tostring(
			record.Durability
		)
		..
		"/"
		..
		tostring(
			stats.MaxDurability
		)

	tool.Parent =
		player:WaitForChild(
			"Backpack"
		)

	return tool
end

local function findHoeToolById(
	player,
	hoeId
)
	for _, place in ipairs(
		getToolPlaces(
			player
		)
	) do
		for _, object in ipairs(
			place:GetChildren()
		) do
			if
				object:IsA("Tool")
				and
				tostring(
					object:GetAttribute(
						"HoeId"
					)
					or
					""
				)
				==
				tostring(
					hoeId
				)
			then
				return object
			end
		end
	end

	return nil
end

local function getCrateHoeTools(
	player
)
	local result = {}

	for _, place in ipairs(
		getToolPlaces(
			player
		)
	) do
		for _, object in ipairs(
			place:GetChildren()
		) do
			if
				object:IsA("Tool")
				and
				object:GetAttribute(
					"CrateHoe"
				)
				==
				true
			then
				table.insert(
					result,
					object
				)
			end
		end
	end

	return result
end

local function syncHoeTools(
	player
)
	if
		player:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	then
		return
	end

	local equipment =
		getEquipment(
			player
		)

	local wanted = {}

	for _, record in ipairs(
		equipment.HoeInventory
	) do
		wanted[
			tostring(
				record.Id
			)
		] =
			record
	end

	-- Remove only crate-reward hoes that no longer exist
	-- in the saved V2 inventory.
	for _, tool in ipairs(
		getCrateHoeTools(
			player
		)
	) do
		local id =
			tostring(
				tool:GetAttribute(
					"HoeId"
				)
				or
				""
			)

		if
			id == ""
			or
			not wanted[id]
		then
			tool:Destroy()
		end
	end

	-- Create missing tools / update existing durability.
	for id, record in pairs(
		wanted
	) do
		local tool =
			findHoeToolById(
				player,
				id
			)

		if not tool then
			createHoeTool(
				player,
				record
			)
		else
			local stats =
				HoeConfig.Get(
					record.Tier
				)

			if stats then
				tool.Name =
					stats.DisplayName

				HoeConfig.ApplyAttributes(
					tool,
					record.Tier,
					record.Durability
				)

				tool:SetAttribute(
					"Favorite",
					record.Favorite
					==
					true
				)

				tool:SetAttribute(
					"LocalFavorite",
					record.Favorite
					==
					true
				)

				tool.ToolTip =
					stats.DisplayName
					..
					"\nDurability "
					..
					tostring(
						record.Durability
					)
					..
					"/"
					..
					tostring(
						stats.MaxDurability
					)
			end
		end
	end
end

local function syncAll(
	player
)
	syncCrateTool(
		player
	)

	syncHoeTools(
		player
	)
end

--========================================================
-- OPEN CRATE
--========================================================

local function reject(
	player,
	text
)
	messageRemote:FireClient(
		player,
		text
	)
end

requestOpen.OnServerEvent:Connect(
	function(
		player,
		crateType
	)
		if
			crateType
			~=
			"Wooden"
		then
			return
		end

		if
			openingPlayers[
				player
			]
		then
			return
		end

		if
			player:GetAttribute(
				"DataLoaded"
			)
			~=
			true
		then
			reject(
				player,
				"Inventory is still loading."
			)

			return
		end

		local equipment =
			getEquipment(
				player
			)

		local crateCount =
			equipment.Crates.Wooden
			or
			0

		if crateCount <= 0 then
			reject(
				player,
				"You do not have a Wooden Crate."
			)

			syncCrateTool(
				player
			)

			return
		end

		openingPlayers[
			player
		] =
			true

		equipment.Crates.Wooden =
			crateCount - 1

		-- Server decides the reward before animation.
		local reward =
			WoodenCrate.Roll(
				rng
			)

		local tier =
			tostring(
				reward.Tier
				or
				"Wooden"
			)

		local hoeRecord =
			addHoeRecord(
				equipment,
				tier
			)

		if not hoeRecord then
			openingPlayers[
				player
			] =
				nil

			reject(
				player,
				"Could not create hoe reward."
			)

			return
		end

		-- Save both consumed crate + new hoe before reveal.
		saveEquipment(
			player,
			equipment
		)

		bumpRevision(
			player,
			"CrateInventoryRevision"
		)

		syncCrateTool(
			player
		)

		openResult:FireClient(
			player,
			"Wooden",
			reward.Name,
			tier
		)

		print(
			"📦 "
			..
			player.Name
			..
			" opened Wooden Crate -> "
			..
			tostring(
				reward.Name
			)
			..
			" | "
			..
			hoeRecord.Id
		)

		-- Reveal the physical tool after roulette.
		task.delay(
			4.1,
			function()
				if player.Parent then
					syncHoeTools(
						player
					)

					-- Fire AFTER the physical hoe Tool exists.
					-- BackpackClient V2.6 listens to this and
					-- immediately shows the new hoe.
					bumpRevision(
						player,
						"HoeInventoryRevision"
					)
				end
			end
		)

		task.delay(
			OPEN_LOCK_TIME,
			function()
				openingPlayers[
					player
				] =
					nil
			end
		)
	end
)

--========================================================
-- PLAYER SETUP
--========================================================

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
				task.delay(
					0.15,
					function()
						if player.Parent then
							syncAll(
								player
							)
						end
					end
				)
			end
		end
	)

	player:GetAttributeChangedSignal(
		"CrateInventoryRevision"
	):Connect(
		function()
			task.defer(
				syncCrateTool,
				player
			)
		end
	)

	player:GetAttributeChangedSignal(
		"HoeInventoryRevision"
	):Connect(
		function()
			if
				not
				openingPlayers[
					player
				]
			then
				task.defer(
					syncHoeTools,
					player
				)
			end
		end
	)

	player.CharacterAdded:Connect(
		function()
			task.wait(
				0.8
			)

			if player.Parent then
				syncAll(
					player
				)
			end
		end
	)

	if
		player:GetAttribute(
			"DataLoaded"
		)
		==
		true
	then
		task.defer(
			syncAll,
			player
		)
	end
end

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

Players.PlayerRemoving:Connect(
	function(player)
		openingPlayers[
			player
		] =
			nil
	end
)

print("")
print("========================================")
print("📦 CRATE SERVICE V2.3 - HOE FAVORITES")
print("========================================")
print("✅ Wooden = 25 durability")
print("✅ Stone  = 40 durability")
print("✅ Iron   = 60 durability")
print("✅ Each crate hoe has unique HoeId")
print("✅ Durability persists")
print("✅ Designed model: stonehoe")
print("✅ Designed model: ironhoe")
print("✅ No custom animation required yet")
print("✅ HoeInventoryRevision fires after Tool creation")
print("✅ GetEquipmentSnapshot RemoteFunction ready")
print("❤️ Hoe favorite field preserved + replicated")
print("========================================")
print("")
