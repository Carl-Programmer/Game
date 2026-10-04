local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = {}

--==================================================
-- INVENTORY SERVICE V4
--
-- Uses:
-- DataService
-- RarityService
-- PotatoVisuals
--
-- ✅ 9 rarities
-- ✅ Friend's BasicPotato model
-- ✅ Two random shades
-- ✅ Rainbow animation
-- ✅ Super shiny gold
-- ✅ Placed potatoes don't return to Backpack
-- ✅ Hoe preserved
-- ✅ Potato Bits preserved
--==================================================

local DataService =
	require(
		script.Parent:WaitForChild(
			"DataService"
		)
	)

local RarityService =
	require(
		script.Parent:WaitForChild(
			"RarityService"
		)
	)

local PotatoVisuals =
	require(
		script.Parent:WaitForChild(
			"PotatoVisuals"
		)
	)

--==================================================
-- CLIENT INVENTORY SNAPSHOT REMOTE
--
-- The custom backpack uses this as the source of truth.
-- This means the UI can show every saved unplaced potato
-- even if Roblox Tool replication is a little late.
--==================================================

local inventoryRemotes =
	ReplicatedStorage:FindFirstChild(
		"PotatiumInventoryRemotes"
	)

if not inventoryRemotes then
	inventoryRemotes = Instance.new("Folder")
	inventoryRemotes.Name = "PotatiumInventoryRemotes"
	inventoryRemotes.Parent = ReplicatedStorage
end

local getPotatoSnapshot =
	inventoryRemotes:FindFirstChild(
		"GetPotatoSnapshot"
	)

if not getPotatoSnapshot then
	getPotatoSnapshot = Instance.new("RemoteFunction")
	getPotatoSnapshot.Name = "GetPotatoSnapshot"
	getPotatoSnapshot.Parent = inventoryRemotes
end

getPotatoSnapshot.OnServerInvoke = function(player)
	if not player or player:GetAttribute("DataLoaded") ~= true then
		return {}
	end

	local result = {}
	local records = DataService.GetPotatoInventory(player)

	for _, record in ipairs(records) do
		local placed =
			type(record.PlacedSlot) == "string"
			and record.PlacedSlot ~= ""

		if not placed and record.Id ~= nil then
			table.insert(result, {
				Id = record.Id,
				PotatoType = record.PotatoType,
				DisplayName = record.DisplayName,
				Rarity = record.Rarity,
				MoneyPerSecond = record.MoneyPerSecond,
				TargetHeight = record.TargetHeight,
				Mutation = record.Mutation,
				Favorite = record.Favorite == true,
			})
		end
	end

	return result
end

--==================================================
-- FIND TOOL USING ATTRIBUTE
--==================================================

local function findTool(
	player,
	attributeName,
	attributeValue
)

	local backpack =
		player:FindFirstChild(
			"Backpack"
		)

	if backpack then

		for _, object in ipairs(
			backpack:GetChildren()
		) do

			if
				object:IsA("Tool")
				and
				object:GetAttribute(
					attributeName
				)
				==
				attributeValue
			then

				return object

			end

		end

	end

	local character =
		player.Character

	if character then

		for _, object in ipairs(
			character:GetChildren()
		) do

			if
				object:IsA("Tool")
				and
				object:GetAttribute(
					attributeName
				)
				==
				attributeValue
			then

				return object

			end

		end

	end

	return nil

end

--==================================================
-- GET ALL POTATO TOOLS
--==================================================

local function getPotatoTools(
	player
)

	local tools = {}

	local backpack =
		player:FindFirstChild(
			"Backpack"
		)

	if backpack then

		for _, object in ipairs(
			backpack:GetChildren()
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

				table.insert(
					tools,
					object
				)

			end

		end

	end

	local character =
		player.Character

	if character then

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

				table.insert(
					tools,
					object
				)

			end

		end

	end

	return tools

end

--==================================================
-- WELD DECORATIVE PART
--==================================================

local function weldPart(
	handle,
	part
)

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

	local weld =
		Instance.new(
			"WeldConstraint"
		)

	weld.Part0 =
		handle

	weld.Part1 =
		part

	weld.Parent =
		part

end

--==================================================
-- CREATE HOE
--==================================================

local function createHoe(
	player
)

	if
		findTool(
			player,
			"FarmingToolType",
			"Hoe"
		)
	then

		return

	end

	local backpack =
		player:WaitForChild(
			"Backpack"
		)

	local tool =
		Instance.new(
			"Tool"
		)

	tool.Name =
		"Hoe"

	tool.ToolTip =
		"Equip to harvest potatoes"

	tool.RequiresHandle =
		true

	tool.CanBeDropped =
		false

	tool:SetAttribute(
		"FarmingToolType",
		"Hoe"
	)

	--==================================================
	-- WOOD HANDLE
	--==================================================

	local handle =
		Instance.new(
			"Part"
		)

	handle.Name =
		"Handle"

	handle.Size =
		Vector3.new(
			0.28,
			2.7,
			0.28
		)

	handle.Color =
		Color3.fromRGB(
			113,
			76,
			46
		)

	handle.Material =
		Enum.Material.Wood

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
	-- METAL HEAD
	--==================================================

	local head =
		Instance.new(
			"Part"
		)

	head.Name =
		"HoeHead"

	head.Size =
		Vector3.new(
			1.5,
			0.22,
			0.55
		)

	head.Color =
		Color3.fromRGB(
			96,
			100,
			102
		)

	head.Material =
		Enum.Material.Metal

	head.CFrame =
		handle.CFrame
		*
		CFrame.new(
			0,
			1.25,
			0
		)

	head.Parent =
		tool

	weldPart(
		handle,
		head
	)

	--==================================================
	-- DARK EDGE
	--==================================================

	local edge =
		Instance.new(
			"Part"
		)

	edge.Name =
		"HoeEdge"

	edge.Size =
		Vector3.new(
			1.55,
			0.12,
			0.16
		)

	edge.Color =
		Color3.fromRGB(
			60,
			64,
			66
		)

	edge.Material =
		Enum.Material.Metal

	edge.CFrame =
		handle.CFrame
		*
		CFrame.new(
			0,
			1.22,
			-0.31
		)

	edge.Parent =
		tool

	weldPart(
		handle,
		edge
	)

	tool.Parent =
		backpack

end

--==================================================
-- CREATE POTATO BIT TOOL
--==================================================

local function createPotatoBitTool(
	player
)

	local backpack =
		player:WaitForChild(
			"Backpack"
		)

	local tool =
		Instance.new(
			"Tool"
		)

	tool.Name =
		"Potato Bits"

	tool.ToolTip =
		"Equip to plant potatoes"

	tool.RequiresHandle =
		true

	tool.CanBeDropped =
		false

	tool:SetAttribute(
		"FarmingToolType",
		"PotatoBits"
	)

	tool:SetAttribute(
		"PotatoBitTool",
		true
	)

	--==================================================
	-- BAG
	--==================================================

	local handle =
		Instance.new(
			"Part"
		)

	handle.Name =
		"Handle"

	handle.Size =
		Vector3.new(
			1.25,
			1,
			0.75
		)

	handle.Color =
		Color3.fromRGB(
			171,
			165,
			126
		)

	handle.Material =
		Enum.Material.Fabric

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
	-- STEM
	--==================================================

	local stem =
		Instance.new(
			"Part"
		)

	stem.Name =
		"SproutStem"

	stem.Size =
		Vector3.new(
			0.11,
			0.55,
			0.11
		)

	stem.Color =
		Color3.fromRGB(
			102,
			184,
			60
		)

	stem.Material =
		Enum.Material.SmoothPlastic

	stem.CFrame =
		handle.CFrame
		*
		CFrame.new(
			0,
			0,
			-0.42
		)

	stem.Parent =
		tool

	weldPart(
		handle,
		stem
	)

	--==================================================
	-- LEFT LEAF
	--==================================================

	local leftLeaf =
		Instance.new(
			"Part"
		)

	leftLeaf.Name =
		"LeftLeaf"

	leftLeaf.Size =
		Vector3.new(
			0.42,
			0.15,
			0.25
		)

	leftLeaf.Color =
		Color3.fromRGB(
			113,
			200,
			65
		)

	leftLeaf.Material =
		Enum.Material.SmoothPlastic

	leftLeaf.CFrame =
		handle.CFrame
		*
		CFrame.new(
			-0.18,
			0.17,
			-0.43
		)
		*
		CFrame.Angles(
			0,
			0,
			math.rad(-25)
		)

	leftLeaf.Parent =
		tool

	weldPart(
		handle,
		leftLeaf
	)

	--==================================================
	-- RIGHT LEAF
	--==================================================

	local rightLeaf =
		Instance.new(
			"Part"
		)

	rightLeaf.Name =
		"RightLeaf"

	rightLeaf.Size =
		Vector3.new(
			0.42,
			0.15,
			0.25
		)

	rightLeaf.Color =
		Color3.fromRGB(
			113,
			200,
			65
		)

	rightLeaf.Material =
		Enum.Material.SmoothPlastic

	rightLeaf.CFrame =
		handle.CFrame
		*
		CFrame.new(
			0.18,
			0.28,
			-0.43
		)
		*
		CFrame.Angles(
			0,
			0,
			math.rad(25)
		)

	rightLeaf.Parent =
		tool

	weldPart(
		handle,
		rightLeaf
	)

	tool.Parent =
		backpack

	return tool

end

--==================================================
-- UPDATE POTATO BITS
--==================================================

local function updatePotatoBits(
	player
)

	local amount =
		player:GetAttribute(
			"PotatoBits"
		)
		or
		0

	local tool =
		findTool(
			player,
			"PotatoBitTool",
			true
		)

	if amount <= 0 then

		if tool then

			tool:Destroy()

		end

		return

	end

	if not tool then

		tool =
			createPotatoBitTool(
				player
			)

	end

	tool.Name =
		"Potato Bits x"
		..
		amount

	tool.ToolTip =
		"Potato Bits x"
		..
		amount

	tool:SetAttribute(
		"Amount",
		amount
	)

end

--==================================================
-- ATTACH MEADOW POTATO MODEL TO TOOL
--
-- IMPORTANT:
--
-- We KEEP PotatoVisual as a Model inside the Tool.
-- Only its Handle becomes a direct child of Tool.
--
-- This keeps the real Meadow model inside the Tool.
--==================================================

local function attachPotatoVisual(
	tool,
	potatoType,
	visualScale
)

	local potatoModel =
		PotatoVisuals.CreateModel(
			potatoType,
			false,
			visualScale
		)

	if not potatoModel then

		warn(
			"❌ Could not create potato visual: "
				..
				tostring(
					potatoType
				)
		)

		return false

	end

	potatoModel.Name =
		"PotatoVisual"

	potatoModel.Parent =
		tool

	--==================================================
	-- FIND HANDLE CREATED BY PotatoVisuals
	--==================================================

	local handle =
		potatoModel:FindFirstChild(
			"Handle",
			true
		)

	if
		not handle
		or
		not handle:IsA("BasePart")
	then

		warn(
			"❌ PotatoVisual has no Handle"
		)

		potatoModel:Destroy()

		return false

	end

	--==================================================
	-- HANDLE MUST BE DIRECT CHILD OF TOOL
	--==================================================

	handle.Parent =
		tool

	handle.Name =
		"Handle"

	handle.Transparency =
		1

	handle.CanCollide =
		false

	handle.CanTouch =
		false

	handle.CanQuery =
		false

	handle.Massless =
		true

	handle.Anchored =
		false

	--==================================================
	-- TOOL GRIP
	--
	-- Adjust these later if you want the potato
	-- slightly higher/lower in the hand.
	--==================================================

	tool.GripPos =
		Vector3.new(
			0,
			-0.7,
			-0.75
		)

	tool.GripForward =
		Vector3.new(
			0,
			-1,
			0
		)

	tool.GripRight =
		Vector3.new(
			1,
			0,
			0
		)

	tool.GripUp =
		Vector3.new(
			0,
			0,
			1
		)

	return true

end

--==================================================
-- CURRENT POTATO TYPE HELPERS
--
-- Keeps the existing V4 inventory system, but stops
-- collapsing every new Meadow potato into "Potato".
--==================================================

local function getCurrentPotatoType(record)

	local potatoType =
		tostring(
			record.PotatoType
			or
			"Normal"
		)

	potatoType =
		string.gsub(
			potatoType,
			"%s+Potato$",
			""
		)

	if
		potatoType == ""
		or
		potatoType == "Potato"
		or
		potatoType == "NormalPotato"
	then

		return "Normal"

	end

	if potatoType == "SweetPotato" then
		return "Sweet"
	end

	return potatoType

end

local function getCurrentPotatoDisplayName(record)

	local potatoType =
		getCurrentPotatoType(
			record
		)

	return
		potatoType
		..
		" Potato"

end

local function updatePotatoToolFromRecord(
	tool,
	record
)

	if
		not tool
		or
		not tool:IsA("Tool")
		or
		type(record) ~= "table"
	then

		return

	end

	local potatoType =
		getCurrentPotatoType(
			record
		)

	local displayName =
		getCurrentPotatoDisplayName(
			record
		)

	tool.Name =
		displayName

	tool.ToolTip =
		displayName

	tool:SetAttribute(
		"PotatoInventoryTool",
		true
	)

	tool:SetAttribute(
		"PotatoId",
		record.Id
	)

	tool:SetAttribute(
		"PotatoType",
		potatoType
	)

	tool:SetAttribute(
		"DisplayName",
		displayName
	)

	tool:SetAttribute(
		"Rarity",
		record.Rarity
			or
			"Common"
	)

	tool:SetAttribute(
		"SpudMass",
		tonumber(
			record.SpudMass
		)
		or
		1
	)

	tool:SetAttribute(
		"SizeTier",
		tostring(
			record.SizeTier
			or
			"Normal"
		)
	)

	tool:SetAttribute(
		"MoneyPerSecond",
		tonumber(
			record.MoneyPerSecond
		)
			or
			0
	)

	tool:SetAttribute(
		"TargetHeight",
		record.TargetHeight
			or
			2.5
	)

	tool:SetAttribute(
		"Mutation",
		record.Mutation
			or
			"None"
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

end

--==================================================
-- CREATE ONE POTATO TOOL
--==================================================

local function createPotatoTool(
	player,
	record
)

	if
		type(record)
		~=
		"table"
	then

		return nil

	end

	if record.Id == nil then

		return nil

	end

	--==================================================
	-- DO NOT GIVE PLACED POTATO TO BACKPACK
	--==================================================

	if
		type(
			record.PlacedSlot
		)
		==
		"string"
		and
		record.PlacedSlot
		~=
		""
	then

		return nil

	end

	local backpack =
		player:WaitForChild(
			"Backpack"
		)

	local rarity =
		record.Rarity
		or
		"Common"

	local potatoType =
		getCurrentPotatoType(
			record
		)

	local visualScale =
		tonumber(record.VisualScale)
			or
			1

	local displayName =
		getCurrentPotatoDisplayName(
			record
		)

	local tool =
		Instance.new(
			"Tool"
		)

	tool.Name =
		displayName

	tool.ToolTip =
		displayName

	tool.RequiresHandle =
		true

	tool.CanBeDropped =
		false

	--==================================================
	-- CURRENT POTATO ATTRIBUTES
	--==================================================

	updatePotatoToolFromRecord(
		tool,
		record
	)

	--==================================================
	-- EXISTING FRIEND POTATO VISUAL
	--
	-- Kept on the old rarity visual path for now so
	-- this live-inventory fix does not replace the
	-- friend's held-potato visual system.
	--==================================================

	local success =
		attachPotatoVisual(
			tool,
			potatoType,
			visualScale
		)

	if not success then

		tool:Destroy()

		return nil

	end

	tool.Parent =
		backpack

	return tool

end

--==================================================
-- CLEAR ALL POTATO TOOLS
--
-- DataService is source of truth.
--==================================================

local function clearPotatoTools(
	player
)

	for _, tool in ipairs(
		getPotatoTools(
			player
		)
	) do

		tool:Destroy()

	end

end

--==================================================
-- UPDATE POTATO INVENTORY
--==================================================

local function updatePotatoInventory(
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

	local records =
		DataService.GetPotatoInventory(
			player
		)

	--==================================================
	-- BUILD LOOKUP OF UNPLACED SAVED POTATOES
	--==================================================

	local wantedRecords = {}

	for _, record in ipairs(
		records
	) do

		local placed =
			type(
				record.PlacedSlot
			)
			==
			"string"
			and
			record.PlacedSlot
			~=
			""

		if
			not placed
			and
			record.Id ~= nil
		then

			wantedRecords[
				record.Id
			] =
				record

		end

	end

	--==================================================
	-- REMOVE ONLY POTATO TOOLS THAT SHOULD NO LONGER
	-- BE IN THE BACKPACK.
	--
	-- V4 deleted EVERY potato tool on each revision,
	-- briefly making the custom backpack look empty.
	--==================================================

	for _, tool in ipairs(
		getPotatoTools(
			player
		)
	) do

		local potatoId =
			tool:GetAttribute(
				"PotatoId"
			)

		if
			potatoId == nil
			or
			wantedRecords[
				potatoId
			] == nil
		then

			tool:Destroy()

		end

	end

	--==================================================
	-- CREATE MISSING TOOLS / UPDATE EXISTING TOOLS
	--==================================================

	for potatoId, record in pairs(
		wantedRecords
	) do

		local existing =
			findTool(
				player,
				"PotatoId",
				potatoId
			)

		if existing then

			updatePotatoToolFromRecord(
				existing,
				record
			)

		else

			createPotatoTool(
				player,
				record
			)

		end

	end

end

--==================================================
-- UPDATE EVERYTHING
--==================================================

local function updateAll(
	player
)

	createHoe(
		player
	)

	updatePotatoBits(
		player
	)

	updatePotatoInventory(
		player
	)

end

--==================================================
-- PLAYER SETUP
--==================================================

local function setupPlayer(
	player
)

	--==================================================
	-- POTATO BITS
	--==================================================

	player:GetAttributeChangedSignal(
		"PotatoBits"
	):Connect(
		function()

			updatePotatoBits(
				player
			)

		end
	)

	--==================================================
	-- POTATO INVENTORY
	--==================================================

	player:GetAttributeChangedSignal(
		"PotatoInventoryRevision"
	):Connect(
		function()

			updatePotatoInventory(
				player
			)

		end
	)

	--==================================================
	-- DATA LOADED
	--==================================================

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

				task.defer(
					updateAll,
					player
				)

			end

		end
	)

	--==================================================
	-- RESPAWN
	--==================================================

	player.CharacterAdded:Connect(
		function()

			task.wait(
				0.6
			)

			updateAll(
				player
			)

		end
	)

	task.defer(
		updateAll,
		player
	)

end

--==================================================
-- START
--==================================================

function InventoryService.Start()

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

	print("")
	print("========================================")
	print("🎒 INVENTORY SERVICE V5.1 - SNAPSHOT SYNC")
	print("========================================")
	print("✅ PotatoVisuals connected")
	print("✅ BasicPotato model equipped")
	print("✅ Basic_Potato1 shade")
	print("✅ Basic_Potato2 shade")
	print("----------------------------------------")
	print("✅ Common = potato brown")
	print("✅ Uncommon = orange")
	print("✅ Rare = green")
	print("✅ Epic = blue")
	print("✅ Exotic = purple")
	print("✅ Legendary = yellow")
	print("✅ Mythic = pink/red")
	print("✅ Super = shiny gold")
	print("✅ Rainbow = animated")
	print("----------------------------------------")
	print("✅ Placed potatoes excluded from Backpack")
	print("✅ New potatoes update live without clearing all tools")
	print("✅ Server inventory snapshot remote ready")
	print("✅ Current Meadow PotatoType names preserved")
	print("✅ Potato Bits preserved")
	print("✅ Hoe preserved")
	print("❌ No Spud-Mass")
	print("❌ No kg")
	print("========================================")
	print("")

end

return InventoryService
