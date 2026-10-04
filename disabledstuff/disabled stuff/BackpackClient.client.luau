--==================================================
-- POTATIUM - CLEAN CUSTOM INVENTORY + HOTBAR V3
--
-- ✅ B = open / close
-- ✅ Detects current potato tools even if old attributes differ
-- ✅ Current Meadow potato names only
-- ✅ No old rarity text
-- ✅ Cleaner favorite heart design
-- ✅ Favorite syncs with Potato Trader sell protection
-- ✅ Search + categories + favorite filter
-- ✅ Drag cards into the 1-0 hotbar
-- ✅ Cleaner compact UI
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local backpack = player:WaitForChild("Backpack")

local hotbarRemotes = ReplicatedStorage:WaitForChild("PotatiumHotbarRemotes", 15)
local getHotbar = hotbarRemotes and hotbarRemotes:FindFirstChild("GetHotbar")
local setHotbar = hotbarRemotes and hotbarRemotes:FindFirstChild("SetHotbar")

-- Server-side saved inventory snapshot.
-- This prevents the custom backpack from depending only on
-- Roblox Tool replication.
local inventoryRemotes = ReplicatedStorage:WaitForChild("PotatiumInventoryRemotes", 10)
local getPotatoSnapshot = inventoryRemotes and inventoryRemotes:FindFirstChild("GetPotatoSnapshot")

local mirrorFolder = script:FindFirstChild("PotatoInventoryMirror")
if not mirrorFolder then
	mirrorFolder = Instance.new("Folder")
	mirrorFolder.Name = "PotatoInventoryMirror"
	mirrorFolder.Parent = script
end


-- Saved crate / hoe snapshot.
-- This is intentionally separate from potato inventory because
-- crates and hoes are stored inside DataService.Equipment.
local crateRemotes =
	ReplicatedStorage:WaitForChild(
		"PotatiumCrateRemotes",
		10
	)

local getEquipmentSnapshot =
	crateRemotes
	and
	crateRemotes:FindFirstChild(
		"GetEquipmentSnapshot"
	)

local equipmentMirrorFolder =
	script:FindFirstChild(
		"EquipmentInventoryMirror"
	)

if not equipmentMirrorFolder then
	equipmentMirrorFolder =
		Instance.new("Folder")

	equipmentMirrorFolder.Name =
		"EquipmentInventoryMirror"

	equipmentMirrorFolder.Parent =
		script
end

--==================================================
-- SETTINGS
--==================================================

local OPEN_KEY = Enum.KeyCode.B

local selectedCategory = "All"
local favoritesOnly = false
local searchText = ""
local backpackOpen = false
local refreshQueued = false

-- Favorite state is hydrated from the server snapshots.
-- Potato key: Potato_<PotatoId>
-- Hoe key:    Hoe_<HoeId>
local favorites = {}

--==================================================
-- GUI ROOT
--
-- Create the ScreenGui BEFORE the custom hotbar so the
-- hotbar has a real parent and remains visible while the
-- backpack is open.
--==================================================

--==================================================
-- REMOVE ANY PREVIOUS BACKPACK GUI INSTANCE
-- IMPORTANT: do this BEFORE creating the new GUI.
--==================================================

local previousGui = playerGui:FindFirstChild("PotatoBackpackGui")
if previousGui then
	previousGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "PotatoBackpackGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 40
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = playerGui

--==================================================
-- CUSTOM 1-9 HOTBAR
--==================================================

local HOTBAR_SLOT_COUNT = 10
local hotbarSlots = table.create(HOTBAR_SLOT_COUNT)
local hotbarSlotButtons = {}
local selectedHotbarIndex = nil
local dragState = nil
local dragGhost = nil
local suppressNextClickUntil = 0
local lastPointerPosition = Vector2.zero
local refreshHotbar
local hideBackpackForDrag
local restoreBackpackAfterDrag
local overlay
local main

--==================================================
-- POTATO TRADER FAVORITE REMOTE
--==================================================

local setPotatoFavorite = nil
local setHoeFavorite = nil

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("PotatoTraderRemotes", 10)
	if remotes then
		setPotatoFavorite = remotes:FindFirstChild("SetFavorite")
		setHoeFavorite = remotes:FindFirstChild("SetHoeFavorite")
	end
end)

--==================================================
-- COLORS
--==================================================

local COLORS = {
	Overlay = Color3.fromRGB(0, 0, 0),
	Window = Color3.fromRGB(18, 20, 24),
	Panel = Color3.fromRGB(24, 27, 32),
	Panel2 = Color3.fromRGB(32, 35, 41),
	Card = Color3.fromRGB(29, 32, 37),
	CardHover = Color3.fromRGB(39, 43, 50),
	CardEquipped = Color3.fromRGB(35, 51, 40),
	Text = Color3.fromRGB(242, 244, 247),
	SubText = Color3.fromRGB(166, 173, 183),
	Accent = Color3.fromRGB(235, 235, 235),
	AccentBright = Color3.fromRGB(255, 255, 255),
	Line = Color3.fromRGB(78, 84, 94),
	Danger = Color3.fromRGB(238, 82, 82),
	White = Color3.fromRGB(255, 255, 255),
	Cream = Color3.fromRGB(35, 38, 44),
	Peach = Color3.fromRGB(27, 30, 35),
	PeachSoft = Color3.fromRGB(23, 26, 31),
	DarkText = Color3.fromRGB(242, 244, 247),
	MutedDark = Color3.fromRGB(160, 168, 180),
	Black = Color3.fromRGB(8, 9, 11),

	BandBlue = Color3.fromRGB(59, 133, 224),
	BandRed = Color3.fromRGB(214, 71, 71),
	BandPurple = Color3.fromRGB(156, 89, 218),
	BandYellow = Color3.fromRGB(235, 190, 53),
	BandDefault = Color3.fromRGB(123, 117, 109),
}

--==================================================
-- CURRENT MEADOW POTATO DISPLAY BANDS
-- Visual drop bands only. This does NOT restore old rarity.
--==================================================

local POTATO_BANDS = {
	["Normal Potato"] = {Color = COLORS.BandBlue, Label = "MEADOW"},
	["Tiny Potato"] = {Color = COLORS.BandBlue, Label = "MEADOW"},
	["Grass Potato"] = {Color = COLORS.BandBlue, Label = "MEADOW"},
	["Sweet Potato"] = {Color = COLORS.BandBlue, Label = "MEADOW"},
	["Feather Potato"] = {Color = COLORS.BandBlue, Label = "MEADOW"},

	["Butter Potato"] = {Color = COLORS.BandRed, Label = "MEADOW"},
	["Lucky Potato"] = {Color = COLORS.BandRed, Label = "MEADOW"},

	["Big Potato"] = {Color = COLORS.BandPurple, Label = "MEADOW"},
	["Clover Potato"] = {Color = COLORS.BandPurple, Label = "MEADOW"},

	["Sun-Kissed Potato"] = {Color = COLORS.BandYellow, Label = "MEADOW"},
}

--==================================================
-- UI HELPERS
--==================================================

local function corner(object, radius)
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, radius)
	ui.Parent = object
	return ui
end

local function stroke(object, color, thickness, transparency)
	local ui = Instance.new("UIStroke")
	ui.Color = color
	ui.Thickness = thickness or 1
	ui.Transparency = transparency or 0
	ui.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ui.Parent = object
	return ui
end

local function padding(object, left, right, top, bottom)
	local ui = Instance.new("UIPadding")
	ui.PaddingLeft = UDim.new(0, left or 0)
	ui.PaddingRight = UDim.new(0, right or 0)
	ui.PaddingTop = UDim.new(0, top or 0)
	ui.PaddingBottom = UDim.new(0, bottom or 0)
	ui.Parent = object
	return ui
end

local function makeLabel(parent, text, size, font, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextSize = size or 14
	label.Font = font or Enum.Font.Gotham
	label.TextColor3 = color or COLORS.Text
	label.Parent = parent
	return label
end

local function makeButton(parent, text)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.Text = text or ""
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = COLORS.Text
	button.BackgroundColor3 = COLORS.Panel2
	button.BorderSizePixel = 0
	button.Parent = parent
	corner(button, 8)
	return button
end

--==================================================
-- POTATO / TOOL HELPERS
--==================================================

local function endsWithPotato(text)
	text = tostring(text or "")
	return string.lower(string.sub(text, -6)) == "potato"
end

local function normalizePotatoName(raw)
	local value = tostring(raw or "")
	value = value:gsub("^%s+", ""):gsub("%s+$", "")

	if value == "" or value == "Potato" then
		return "Normal Potato"
	end

	if endsWithPotato(value) then
		return value
	end

	return value .. " Potato"
end

local function isPotatoTool(tool)
	if not tool or not tool:IsA("Tool") then
		return false
	end

	-- Current / preferred marker.
	if tool:GetAttribute("PotatoInventoryTool") == true then
		return true
	end

	-- Robust compatibility with current/new tool versions.
	if tool:GetAttribute("PotatoId") ~= nil then
		return true
	end

	if tool:GetAttribute("PotatoType") ~= nil then
		return true
	end

	local lowerName = string.lower(tool.Name)
	if string.find(lowerName, "potato", 1, true) then
		return true
	end

	return false
end

local function getPotatoName(tool)
	local potatoType = tool:GetAttribute("PotatoType")

	if potatoType ~= nil then
		local raw = tostring(potatoType)
		if raw == "Potato" then
			raw = "Normal"
		end
		return normalizePotatoName(raw)
	end

	-- Fallback to actual tool name if attribute is missing.
	local toolName = tostring(tool.Name)

	-- Remove old stack suffixes such as " x4" if any remain.
	toolName = toolName:gsub("%s+x%d+$", "")

	if string.find(string.lower(toolName), "potato", 1, true) then
		return toolName
	end

	return "Potato"
end

local function getToolCategory(tool)
	if isPotatoTool(tool) then
		return "Potatoes"
	end

	-- Crates get their own category instead of falling into Materials.
	-- Name fallback keeps older crate Tools compatible too.
	local lowerName =
		string.lower(
			tostring(
				tool.Name
			)
		)

	if
		tool:GetAttribute("CrateTool")
		==
		true
		or
		tool:GetAttribute("CrateType")
		~=
		nil
		or
		string.find(
			lowerName,
			"crate",
			1,
			true
		)
		~=
		nil
	then
		return "Crates"
	end

	if tool:GetAttribute("FarmingToolType") == "Hoe" then
		return "Hoe"
	end

	if string.find(lowerName, "hoe", 1, true)
		or string.find(lowerName, "shovel", 1, true)
	then
		return "Hoe"
	end

	local itemCategory = tool:GetAttribute("ItemCategory")
	if itemCategory == "Weapons" or tool:GetAttribute("WeaponTool") == true then
		return "Weapons"
	end

	if string.find(lowerName, "sword", 1, true)
		or string.find(lowerName, "blaster", 1, true)
		or string.find(lowerName, "gun", 1, true)
	then
		return "Weapons"
	end

	return "Materials"
end

local function getDisplayName(tool)
	if isPotatoTool(tool) then
		return getPotatoName(tool)
	end
	return tool.Name
end

local function getPotatoWeightText(tool)
	if not isPotatoTool(tool) then
		return ""
	end

	local mass = tonumber(tool:GetAttribute("SpudMass"))
	if not mass then
		return ""
	end

	return string.format("%.2f kg", mass)
end

local function getFavoriteKey(tool)
	local potatoId = tool:GetAttribute("PotatoId")
	if potatoId ~= nil then
		return "Potato_" .. tostring(potatoId)
	end

	local hoeId = tool:GetAttribute("HoeId")
	if hoeId ~= nil then
		return "Hoe_" .. tostring(hoeId)
	end

	return "Tool_" .. tool.Name
end

local function findRealPotatoToolById(potatoId)
	if potatoId == nil then
		return nil
	end

	for _, container in ipairs({backpack, player.Character}) do
		if container then
			for _, object in ipairs(container:GetDescendants()) do
				if object:IsA("Tool") and tostring(object:GetAttribute("PotatoId") or "") == tostring(potatoId) then
					return object
				end
			end
		end
	end

	return nil
end

local function rebuildPotatoMirror(records)
	for _, child in ipairs(mirrorFolder:GetChildren()) do
		child:Destroy()
	end

	if type(records) ~= "table" then
		return
	end

	for _, record in ipairs(records) do
		if type(record) == "table" and record.Id ~= nil then
			local favoriteKey =
				"Potato_"
				..
				tostring(
					record.Id
				)

			favorites[favoriteKey] =
				record.Favorite
				==
				true

			local realTool =
				findRealPotatoToolById(
					record.Id
				)

			if realTool then
				realTool:SetAttribute("SpudMass", tonumber(record.SpudMass) or 1)
				realTool:SetAttribute("SizeTier", tostring(record.SizeTier or "Normal"))
				realTool:SetAttribute(
					"LocalFavorite",
					record.Favorite
					==
					true
				)

				realTool:SetAttribute(
					"Favorite",
					record.Favorite
					==
					true
				)
			end

			if not realTool then
				local tool = Instance.new("Tool")
				local potatoType = tostring(record.PotatoType or "Normal")
				if potatoType == "Potato" or potatoType == "" then
					potatoType = "Normal"
				end
				potatoType = potatoType:gsub("%s+Potato$", "")
				local displayName = potatoType .. " Potato"

				tool.Name = displayName
				tool.RequiresHandle = false
				tool.CanBeDropped = false
				tool:SetAttribute("InventoryMirror", true)
				tool:SetAttribute("PotatoInventoryTool", true)
				tool:SetAttribute("PotatoId", record.Id)
				tool:SetAttribute("PotatoType", potatoType)
				tool:SetAttribute("DisplayName", displayName)
				tool:SetAttribute("Rarity", record.Rarity or "Common")
				tool:SetAttribute("SpudMass", tonumber(record.SpudMass) or 1)
				tool:SetAttribute("SizeTier", tostring(record.SizeTier or "Normal"))
				tool:SetAttribute("MoneyPerSecond", tonumber(record.MoneyPerSecond) or 0)
				tool:SetAttribute("TargetHeight", tonumber(record.TargetHeight) or 2.5)
				tool:SetAttribute("Mutation", record.Mutation or "None")
				tool:SetAttribute("Favorite", record.Favorite == true)
				tool:SetAttribute("LocalFavorite", record.Favorite == true)
				tool.Parent = mirrorFolder
			end
		end
	end
end

local function syncServerPotatoSnapshot()
	if not getPotatoSnapshot then
		return
	end

	local success, records = pcall(function()
		return getPotatoSnapshot:InvokeServer()
	end)

	if success and type(records) == "table" then
		rebuildPotatoMirror(records)
	end
end

--==================================================
-- EQUIPMENT SNAPSHOT MIRROR
--
-- The custom backpack must not depend only on physical
-- Roblox Tools. A crate/hoe can be saved on the server
-- before its Tool has replicated to this client.
--==================================================

local function findRealHoeToolById(
	hoeId
)
	if hoeId == nil then
		return nil
	end

	for _, container in ipairs({
		backpack,
		player.Character,
	}) do
		if container then
			for _, object in ipairs(
				container:GetDescendants()
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
	end

	return nil
end

local function findRealCrateTool(
	crateType
)
	local wanted =
		tostring(
			crateType
			or
			"Wooden"
		)

	for _, container in ipairs({
		backpack,
		player.Character,
	}) do
		if container then
			for _, object in ipairs(
				container:GetDescendants()
			) do
				if object:IsA("Tool") then
					local objectType =
						object:GetAttribute(
							"CrateType"
						)

					if
						tostring(
							objectType
							or
							""
						)
						==
						wanted
					then
						return object
					end

					-- Old crate Tool fallback.
					if
						wanted
						==
						"Wooden"
						and
						string.find(
							string.lower(
								object.Name
							),
							"wooden crate",
							1,
							true
						)
						~=
						nil
					then
						return object
					end
				end
			end
		end
	end

	return nil
end

local function rebuildEquipmentMirror(
	snapshot
)
	for _, child in ipairs(
		equipmentMirrorFolder:GetChildren()
	) do
		child:Destroy()
	end

	if type(snapshot) ~= "table" then
		return
	end

	-- Crates
	local crates =
		type(snapshot.Crates) == "table"
		and
		snapshot.Crates
		or
		{}

	local woodenCount =
		math.max(
			0,
			math.floor(
				tonumber(
					crates.Wooden
				)
				or
				0
			)
		)

	if
		woodenCount > 0
		and
		not findRealCrateTool(
			"Wooden"
		)
	then
		local tool =
			Instance.new("Tool")

		tool.Name =
			woodenCount > 1
			and
			(
				"Wooden Crate x"
				..
				tostring(
					woodenCount
				)
			)
			or
			"Wooden Crate"

		tool.RequiresHandle =
			false

		tool.CanBeDropped =
			false

		tool:SetAttribute(
			"InventoryMirror",
			true
		)

		tool:SetAttribute(
			"EquipmentMirror",
			true
		)

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
			woodenCount
		)

		tool.Parent =
			equipmentMirrorFolder
	end

	-- Individual saved hoes
	local hoes =
		type(snapshot.HoeInventory) == "table"
		and
		snapshot.HoeInventory
		or
		{}

	for _, record in ipairs(
		hoes
	) do
		if
			type(record)
			==
			"table"
			and
			record.Id ~= nil
		then
			local favoriteKey =
				"Hoe_"
				..
				tostring(
					record.Id
				)

			favorites[favoriteKey] =
				record.Favorite
				==
				true

			local realHoe =
				findRealHoeToolById(
					record.Id
				)

			if realHoe then
				realHoe:SetAttribute(
					"LocalFavorite",
					record.Favorite
					==
					true
				)

				realHoe:SetAttribute(
					"Favorite",
					record.Favorite
					==
					true
				)
			end

			if not realHoe then
			local tier =
				tostring(
					record.Tier
					or
					"Wooden"
				)

			local tool =
				Instance.new("Tool")

			tool.Name =
				tier
				..
				" Hoe"

			tool.RequiresHandle =
				false

			tool.CanBeDropped =
				false

			tool:SetAttribute(
				"InventoryMirror",
				true
			)

			tool:SetAttribute(
				"EquipmentMirror",
				true
			)

			tool:SetAttribute(
				"FarmingToolType",
				"Hoe"
			)

			tool:SetAttribute(
				"HoeId",
				record.Id
			)

			tool:SetAttribute(
				"HoeTier",
				tier
			)

			tool:SetAttribute(
				"Durability",
				tonumber(
					record.Durability
				)
				or
				0
			)

			tool:SetAttribute(
				"MaxDurability",
				tonumber(
					record.MaxDurability
				)
				or
				0
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

				tool.Parent =
					equipmentMirrorFolder
			end
		end
	end
end

local function syncServerEquipmentSnapshot()
	if not getEquipmentSnapshot then
		return
	end

	local success,
		snapshot =
			pcall(
				function()
					return
						getEquipmentSnapshot:InvokeServer()
				end
			)

	if
		success
		and
		type(snapshot)
		==
		"table"
	then
		rebuildEquipmentMirror(
			snapshot
		)
	end
end

local function getAllTools()
	local result = {}
	local addedObjects = {}
	local addedPotatoIds = {}

	local function addTool(tool)
		if not tool or not tool:IsA("Tool") or addedObjects[tool] then
			return
		end

		local potatoId = tool:GetAttribute("PotatoId")
		if potatoId ~= nil and addedPotatoIds[potatoId] then
			return
		end

		addedObjects[tool] = true
		if potatoId ~= nil then
			addedPotatoIds[potatoId] = true
		end
		table.insert(result, tool)
	end

	-- Prefer real Roblox tools first.
	for _, object in ipairs(backpack:GetDescendants()) do
		if object:IsA("Tool") then
			addTool(object)
		end
	end

	local character = player.Character
	if character then
		for _, object in ipairs(character:GetDescendants()) do
			if object:IsA("Tool") then
				addTool(object)
			end
		end
	end

	-- Add saved potatoes that are missing as replicated Tools.
	for _, object in ipairs(mirrorFolder:GetChildren()) do
		if object:IsA("Tool") then
			addTool(object)
		end
	end

	-- Add saved crates / hoes that are missing as replicated Tools.
	for _, object in ipairs(
		equipmentMirrorFolder:GetChildren()
	) do
		if object:IsA("Tool") then
			addTool(object)
		end
	end

	table.sort(result, function(a, b)
		local categoryA = getToolCategory(a)
		local categoryB = getToolCategory(b)

		if categoryA ~= categoryB then
			local priority = {
				Potatoes = 1,
				Crates = 2,
				Hoe = 3,
				Materials = 4,
				Weapons = 5,
			}

			return
				(priority[categoryA] or 99)
				<
				(priority[categoryB] or 99)
		end

		return string.lower(getDisplayName(a)) < string.lower(getDisplayName(b))
	end)

	return result
end

local function resolveRealTool(tool)
	if not tool then
		return nil
	end

	if
		tool:GetAttribute(
			"EquipmentMirror"
		)
		==
		true
	then
		local hoeId =
			tool:GetAttribute(
				"HoeId"
			)

		if hoeId ~= nil then
			return
				findRealHoeToolById(
					hoeId
				)
		end

		local crateType =
			tool:GetAttribute(
				"CrateType"
			)

		if crateType ~= nil then
			return
				findRealCrateTool(
					crateType
				)
		end

		return nil
	end

	if
		tool:GetAttribute(
			"InventoryMirror"
		)
		==
		true
	then
		return
			findRealPotatoToolById(
				tool:GetAttribute(
					"PotatoId"
				)
			)
	end

	return tool
end

local function isEquipped(tool)
	local character = player.Character
	local realTool = resolveRealTool(tool)
	return character ~= nil and realTool ~= nil and realTool.Parent == character
end

local function findPhysicalTool(tool)
	if not tool then
		return nil
	end

	local potatoId = tool:GetAttribute("PotatoId")
	if potatoId ~= nil then
		return findRealPotatoToolById(potatoId)
	end

	local hoeId = tool:GetAttribute("HoeId")
	if hoeId ~= nil then
		return findRealHoeToolById(hoeId)
	end

	local crateType = tool:GetAttribute("CrateType")
	if crateType ~= nil then
		return findRealCrateTool(crateType)
	end

	if tool:IsA("Tool") and tool:GetAttribute("InventoryMirror") ~= true then
		return tool
	end

	return nil
end

local function waitForPhysicalTool(tool, timeout)
	local deadline = os.clock() + (timeout or 0.75)
	local realTool = findPhysicalTool(tool)

	while not realTool and os.clock() < deadline do
		task.wait(0.05)
		realTool = findPhysicalTool(tool)
	end

	return realTool
end

local function toggleEquip(tool)
	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	-- IMPORTANT:
	-- Never equip the custom inventory mirror. The mirror only represents
	-- the saved item in the UI. We always wait for the REAL Roblox Tool
	-- created by InventoryService / the existing equipment system.
	local realTool = waitForPhysicalTool(tool, 0.75)
	if not realTool then
		warn("[Potatium] Real Tool not replicated yet:", tostring(tool.Name))
		return false
	end

	local currentBackpack = player:FindFirstChild("Backpack")
	if not currentBackpack then
		return false
	end

	-- Already equipped: normal Roblox hotbar behaviour = put it away.
	if realTool.Parent == character then
		humanoid:UnequipTools()
		return true
	end

	-- The server-created potato/hoe/crate Tool already contains the real
	-- Handle and visual. Do not create or modify a replacement Tool here.
	if realTool.Parent ~= currentBackpack then
		return false
	end

	if realTool.RequiresHandle and not realTool:FindFirstChild("Handle") then
		-- Give replication one short window to finish the existing Handle.
		local deadline = os.clock() + 0.5
		while not realTool:FindFirstChild("Handle") and os.clock() < deadline do
			task.wait(0.05)
		end
	end

	if realTool.RequiresHandle and not realTool:FindFirstChild("Handle") then
		warn("[Potatium] Real Tool has no Handle:", realTool.Name)
		return false
	end

	-- Use Roblox's normal equipment pipeline.
	humanoid:UnequipTools()
	task.wait()

	local ok, err = pcall(function()
		humanoid:EquipTool(realTool)
	end)

	if not ok then
		warn("[Potatium] EquipTool failed:", realTool.Name, err)
		return false
	end

	-- EquipTool is asynchronous. Wait briefly for Roblox to move the
	-- existing Tool into Character. Do NOT directly parent it ourselves.
	local deadline = os.clock() + 0.75
	while realTool.Parent ~= character and os.clock() < deadline do
		task.wait(0.03)
	end

	if realTool.Parent ~= character then
		warn("[Potatium] Tool did not enter Character:", realTool.Name)
		return false
	end

	return true
end

--====================--==================================================
-- CUSTOM DRAG HOTBAR
--==================================================

local function getHotbarKey(tool)
	if not tool then return nil end

	local potatoId = tool:GetAttribute("PotatoId")
	if potatoId ~= nil then
		return "Potato_" .. tostring(potatoId)
	end

	local hoeId = tool:GetAttribute("HoeId")
	if hoeId ~= nil then
		return "Hoe_" .. tostring(hoeId)
	end

	local crateType = tool:GetAttribute("CrateType")
	if crateType ~= nil then
		return "Crate_" .. tostring(crateType)
	end

	return "Tool_" .. getToolCategory(tool) .. "_" .. tostring(tool.Name)
end

-- Find the EXISTING physical Roblox Tool.
-- The custom UI must never create a replacement Tool.
local function findPhysicalToolForHotbarKey(key)
	if not key or key == "" then
		return nil
	end

	local prefix, value = key:match("^(%w+_)(.+)$")
	if not prefix then
		return nil
	end

	local character = player.Character
	local containers = {backpack, character}

	for _, container in ipairs(containers) do
		if container then
			for _, object in ipairs(container:GetDescendants()) do
				if object:IsA("Tool") then
					if prefix == "Potato_" then
						if tostring(object:GetAttribute("PotatoId") or "") == tostring(value) then
							return object
						end
					elseif prefix == "Hoe_" then
						if tostring(object:GetAttribute("HoeId") or "") == tostring(value) then
							return object
						end
					elseif prefix == "Crate_" then
						if tostring(object:GetAttribute("CrateType") or "") == tostring(value) then
							return object
						end
					else
						if key == getHotbarKey(object) then
							return object
						end
					end
				end
			end
		end
	end

	return nil
end

local function findHotbarToolByKey(key)
	if not key or key == "" then
		return nil
	end

	local prefix, value = key:match("^(%w+)_(.+)$")
	if not prefix then
		return nil
	end

	-- Physical Tools first. Never return a UI mirror from this function.
	for _, container in ipairs({backpack, player.Character}) do
		if container then
			for _, object in ipairs(container:GetChildren()) do
				if object:IsA("Tool") and object:GetAttribute("InventoryMirror") ~= true then
					if prefix == "Potato" and tostring(object:GetAttribute("PotatoId")) == value then
						return object
					elseif prefix == "Hoe" and tostring(object:GetAttribute("HoeId")) == value then
						return object
					elseif prefix == "Crate" and tostring(object:GetAttribute("CrateType")) == value then
						return object
					elseif prefix == "Tool" and getHotbarKey(object) == key then
						return object
					end
				end
			end
		end
	end

	return nil
end

local function getHotbarDisplayToolByKey(key)
	if not key then return nil end
	for _, tool in ipairs(getAllTools()) do
		if getHotbarKey(tool) == key then return tool end
	end
	return nil
end

local function hotbarFallbackName(key)
	if not key or key == "" then
		return "EMPTY"
	end

	local prefix, value = key:match("^(%w+_) (.+)$")
	if not prefix then
		prefix, value = key:match("^(%w+_)(.+)$")
	end

	if prefix == "Potato_" then
		return "POTATO"
	elseif prefix == "Hoe_" then
		return "HOE"
	elseif prefix == "Crate_" then
		return tostring(value or "CRATE")
	elseif prefix == "Tool_" then
		return tostring(value or "ITEM")
	end

	return "ITEM"
end

local function copyHotbarSlots()
	local copy = table.create(HOTBAR_SLOT_COUNT)
	for index = 1, HOTBAR_SLOT_COUNT do
		copy[index] = hotbarSlots[index] or ""
	end
	return copy
end

local function saveHotbarSlots()
	if setHotbar then
		setHotbar:FireServer(copyHotbarSlots())
	end
end

local function loadSavedHotbar()
	if not getHotbar then
		return false
	end

	local success, slots = pcall(function()
		return getHotbar:InvokeServer()
	end)

	if not success or type(slots) ~= "table" then
		warn("⚠ Could not load saved Potatium hotbar: " .. tostring(slots))
		return false
	end

	for index = 1, HOTBAR_SLOT_COUNT do
		local key = slots[index]
		hotbarSlots[index] = type(key) == "string" and key ~= "" and key or nil
	end

	if refreshHotbar then
		refreshHotbar()
	end

	local parts = table.create(HOTBAR_SLOT_COUNT)
	for index = 1, HOTBAR_SLOT_COUNT do
		parts[index] = (index == 10 and "0" or tostring(index)) .. "=" .. (hotbarSlots[index] or "EMPTY")
	end
	print("📥 HOTBAR LOADED CLIENT: " .. table.concat(parts, " | "))
	return true
end

local hotbarGui = Instance.new("Frame")
hotbarGui.Name = "CustomHotbar"
hotbarGui.AnchorPoint = Vector2.new(0.5, 1)
hotbarGui.Position = UDim2.new(0.5, 0, 1, -10)
hotbarGui.Size = UDim2.fromOffset(HOTBAR_SLOT_COUNT * 56 + (HOTBAR_SLOT_COUNT - 1) * 5 + 10, 62)
hotbarGui.BackgroundColor3 = Color3.fromRGB(34, 39, 47)
hotbarGui.BackgroundTransparency = 0.18
hotbarGui.BorderSizePixel = 0
hotbarGui.ZIndex = 200
hotbarGui.Visible = true
hotbarGui.Active = false
hotbarGui.Parent = gui
corner(hotbarGui, 8)
stroke(hotbarGui, Color3.fromRGB(92, 98, 108), 1, 0.35)
padding(hotbarGui, 7, 7, 7, 7)

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hotbarLayout.Padding = UDim.new(0, 6)
hotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
hotbarLayout.Parent = hotbarGui

local function hotbarIconForTool(tool)
	if not tool then return "" end
	local category = getToolCategory(tool)
	if category == "Potatoes" then return "🥔" end
	if category == "Hoe" then return "⛏" end
	if category == "Crates" then return "□" end
	if category == "Weapons" then return "⚔" end
	return "•"
end

local function getGuiMousePosition()
	-- GetMouseLocation() is in screen coordinates, while our ScreenGui
	-- uses IgnoreGuiInset=true. Convert the mouse position into the same
	-- coordinate space used by AbsolutePosition so drop detection lines up.
	local mouse = UserInputService:GetMouseLocation()
	local inset = GuiService:GetGuiInset()
	return Vector2.new(
		mouse.X - inset.X,
		mouse.Y - inset.Y
	)
end

local function getHotbarSlotAtPosition(position)
	-- Give each slot a small invisible drop margin so releasing near
	-- the slot still counts as dropping onto it.
	local DROP_MARGIN = 10

	for index, slot in ipairs(hotbarSlotButtons) do
		if slot and slot.Visible then
			local topLeft = slot.AbsolutePosition
			local size = slot.AbsoluteSize

			if
				position.X >= topLeft.X - DROP_MARGIN
				and position.X <= topLeft.X + size.X + DROP_MARGIN
				and position.Y >= topLeft.Y - DROP_MARGIN
				and position.Y <= topLeft.Y + size.Y + DROP_MARGIN
			then
				return index
			end
		end
	end

	return nil
end

local function clearHotbarHighlight()
	for _, slot in ipairs(hotbarSlotButtons) do
		local slotStroke = slot:FindFirstChild("SlotStroke")
		if slotStroke then
			slotStroke.Color = COLORS.Line
			slotStroke.Thickness = 1
		end
	end
end

local function highlightHotbarSlot(index)
	clearHotbarHighlight()
	if not index then return end
	local slot = hotbarSlotButtons[index]
	if not slot then return end
	local slotStroke = slot:FindFirstChild("SlotStroke")
	if slotStroke then
		slotStroke.Color = COLORS.AccentBright
		slotStroke.Thickness = 2
	end
end

local function updateSelectedHotbarVisual()
	for index, slot in ipairs(hotbarSlotButtons) do
		local slotStroke = slot:FindFirstChild("SlotStroke")
		if slotStroke then
			if index == selectedHotbarIndex then
				slotStroke.Color = COLORS.AccentBright
				slotStroke.Thickness = 2
			else
				slotStroke.Color = COLORS.Line
				slotStroke.Thickness = 1
			end
		end
	end
end

local function destroyDragGhost()
	if dragGhost then
		dragGhost:Destroy()
		dragGhost = nil
	end
end

local function createDragGhost(name, icon)
	destroyDragGhost()

	dragGhost = Instance.new("Frame")
	dragGhost.Name = "HotbarDragGhost"
	dragGhost.Size = UDim2.fromOffset(140, 48)
	dragGhost.BackgroundColor3 = COLORS.Panel2
	dragGhost.BackgroundTransparency = 0.05
	dragGhost.BorderSizePixel = 0
	dragGhost.ZIndex = 250
	dragGhost.Parent = gui
	corner(dragGhost, 10)
	stroke(dragGhost, COLORS.AccentBright, 2, 0)

	local iconLabel = makeLabel(dragGhost, icon, 24, Enum.Font.GothamBold, COLORS.Text)
	iconLabel.Size = UDim2.fromOffset(38, 48)
	iconLabel.Position = UDim2.fromOffset(4, 0)
	iconLabel.TextXAlignment = Enum.TextXAlignment.Center
	iconLabel.TextYAlignment = Enum.TextYAlignment.Center
	iconLabel.ZIndex = 251

	local nameLabel = makeLabel(dragGhost, name, 11, Enum.Font.GothamBold, COLORS.Text)
	nameLabel.Position = UDim2.fromOffset(42, 0)
	nameLabel.Size = UDim2.new(1, -48, 1, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 251
end

local function updateDragGhost(position)
	if not dragGhost then return end
	dragGhost.Position = UDim2.fromOffset(position.X + 14, position.Y + 14)
	highlightHotbarSlot(getHotbarSlotAtPosition(position))
end

local function removeHotbarKeyFromOtherSlots(key, exceptIndex)
	if not key then return end
	for index = 1, HOTBAR_SLOT_COUNT do
		if index ~= exceptIndex and hotbarSlots[index] == key then
			hotbarSlots[index] = nil
		end
	end
end

local function finishHotbarDrag()
	if not dragState then return end

	local state = dragState
	dragState = nil
	clearHotbarHighlight()
	updateSelectedHotbarVisual()
	destroyDragGhost()

	if not state.dragging then return end

	local mousePosition = lastPointerPosition
	if mousePosition == Vector2.zero then
		mousePosition = getGuiMousePosition()
	end
	local targetIndex = getHotbarSlotAtPosition(mousePosition)

	if state.source == "Card" then
		if targetIndex and state.key then
			removeHotbarKeyFromOtherSlots(state.key, targetIndex)
			hotbarSlots[targetIndex] = state.key
			saveHotbarSlots()
		end
	elseif state.source == "Slot" then
		local sourceIndex = state.slotIndex
		local sourceKey = hotbarSlots[sourceIndex]

		if targetIndex then
			if targetIndex ~= sourceIndex then
				local targetKey = hotbarSlots[targetIndex]
				hotbarSlots[targetIndex] = sourceKey
				hotbarSlots[sourceIndex] = targetKey
				saveHotbarSlots()
			end
		else
			hotbarSlots[sourceIndex] = nil
			saveHotbarSlots()
		end
	end

	if refreshHotbar then
		refreshHotbar()
	end

	-- Re-open the backpack automatically after an inventory drag,
	-- whether the item was successfully placed or the drag missed.
	if state.source == "Card" and restoreBackpackAfterDrag then
		task.defer(restoreBackpackAfterDrag)
	end
end

local function startHotbarDrag(state)
	if state.dragging then return end

	state.dragging = true
	suppressNextClickUntil = os.clock() + 0.25

	-- Big-game style: once the player actually starts dragging
	-- an inventory item, hide the bag so the hotbar is unobstructed.
	if state.source == "Card" and hideBackpackForDrag then
		hideBackpackForDrag()
	end

	local displayTool = getHotbarDisplayToolByKey(state.key)
	createDragGhost(
		displayTool and getDisplayName(displayTool) or "Item",
		hotbarIconForTool(displayTool)
	)

	updateDragGhost(getGuiMousePosition())
end

local function beginHotbarDrag(source, key, slotIndex)
	if not key then return end

	dragState = {
		source = source,
		key = key,
		slotIndex = slotIndex,
		startPosition = getGuiMousePosition(),
		dragging = false,
	}
end

local function selectHotbarSlot(index)
	if index < 1 or index > HOTBAR_SLOT_COUNT then return end

	local key = hotbarSlots[index]
	if not key or key == "" then
		return
	end

	-- Selection visual is independent from the equip result. This means
	-- the chosen slot immediately gets the Roblox-style white border.
	local tool = findHotbarToolByKey(key)

	local wasSelectedAndEquipped = tool and selectedHotbarIndex == index and isEquipped(tool)

	selectedHotbarIndex = index
	updateSelectedHotbarVisual()

	if not tool then
		return
	end

	-- Equip the corresponding REAL Tool so the item appears in the hand.
	local equippedNow = toggleEquip(tool)

	-- Clicking the already-equipped slot puts it away, like Roblox's hotbar.
	if wasSelectedAndEquipped then
		selectedHotbarIndex = nil
	elseif equippedNow then
		selectedHotbarIndex = index
	end

	task.delay(0.05, function()
		updateSelectedHotbarVisual()
		queueRefresh()
	end)
end

local function createHotbarSlot(index)
	local slot = Instance.new("TextButton")
	slot.Name = "Slot_" .. tostring(index)
	slot.LayoutOrder = index
	slot.Size = UDim2.fromOffset(56, 64)
	slot.Text = ""
	slot.AutoButtonColor = false
	slot.Active = true
	slot.BackgroundColor3 = Color3.fromRGB(28, 31, 36)
	slot.BackgroundTransparency = 0.18
	slot.BorderSizePixel = 0
	slot.ZIndex = 201
	slot.Parent = hotbarGui
	corner(slot, 6)

	local slotStroke = stroke(slot, Color3.fromRGB(105, 111, 122), 1, 0.35)
	slotStroke.Name = "SlotStroke"
	slotStroke.ZIndex = 202

	local numberLabel = makeLabel(slot, index == 10 and "0" or tostring(index), 11, Enum.Font.GothamBold, COLORS.SubText)
	numberLabel.Name = "Number"
	numberLabel.Position = UDim2.fromOffset(5, 3)
	numberLabel.Size = UDim2.fromOffset(14, 14)
	numberLabel.TextXAlignment = Enum.TextXAlignment.Left
	numberLabel.ZIndex = 202

	local iconLabel = makeLabel(slot, "", 23, Enum.Font.GothamBold, COLORS.Text)
	iconLabel.Name = "Icon"
	iconLabel.Position = UDim2.fromOffset(15, 5)
	iconLabel.Size = UDim2.fromOffset(26, 25)
	iconLabel.TextXAlignment = Enum.TextXAlignment.Center
	iconLabel.TextYAlignment = Enum.TextYAlignment.Center
	iconLabel.ZIndex = 202

	local nameLabel = makeLabel(slot, "EMPTY", 8, Enum.Font.GothamBold, COLORS.SubText)
	nameLabel.Name = "ItemName"
	nameLabel.Position = UDim2.fromOffset(3, 32)
	nameLabel.Size = UDim2.new(1, -6, 0, 13)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 202

	local weightLabel = makeLabel(slot, "", 8, Enum.Font.GothamMedium, COLORS.SubText)
	weightLabel.Name = "Weight"
	weightLabel.Position = UDim2.fromOffset(3, 46)
	weightLabel.Size = UDim2.new(1, -6, 0, 12)
	weightLabel.TextXAlignment = Enum.TextXAlignment.Center
	weightLabel.TextTruncate = Enum.TextTruncate.AtEnd
	weightLabel.ZIndex = 202

	slot.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginHotbarDrag("Slot", hotbarSlots[index], index)
		end
	end)

	return slot
end

for index = 1, HOTBAR_SLOT_COUNT do
	hotbarSlotButtons[index] = createHotbarSlot(index)
end

refreshHotbar = function()
	for index = 1, HOTBAR_SLOT_COUNT do
		local slot = hotbarSlotButtons[index]
		local key = hotbarSlots[index]
		local tool = key and getHotbarDisplayToolByKey(key) or nil

		local numberLabel = slot:FindFirstChild("Number")
		local iconLabel = slot:FindFirstChild("Icon")
		local nameLabel = slot:FindFirstChild("ItemName")
		local weightLabel = slot:FindFirstChild("Weight")

		numberLabel.Text = index == 10 and "0" or tostring(index)

		if tool then
			iconLabel.Text = hotbarIconForTool(tool)
			nameLabel.Text = getDisplayName(tool)
			nameLabel.TextColor3 = isEquipped(tool) and COLORS.AccentBright or COLORS.Text
			weightLabel.Text = getPotatoWeightText(tool)
			slot.BackgroundColor3 = isEquipped(tool) and COLORS.CardEquipped or COLORS.Panel2
		elseif key then
			iconLabel.Text = key:sub(1, 1) == "P" and "🥔" or (key:sub(1, 1) == "H" and "⛏" or "•")
			nameLabel.Text = hotbarFallbackName(key)
			nameLabel.TextColor3 = COLORS.AccentBright
			weightLabel.Text = ""
			slot.BackgroundColor3 = COLORS.Panel2
		else
			iconLabel.Text = ""
			nameLabel.Text = "EMPTY"
			nameLabel.TextColor3 = COLORS.SubText
			weightLabel.Text = ""
			slot.BackgroundColor3 = COLORS.Panel2
		end
	end
	updateSelectedHotbarVisual()
end

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local position = getGuiMousePosition()
	lastPointerPosition = position

	if not dragState then
		return
	end

	if not dragState.dragging then
		if (position - dragState.startPosition).Magnitude < 8 then
			return
		end

		startHotbarDrag(dragState)
	end

	if dragState and dragState.dragging then
		updateDragGhost(position)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	if not dragState then
		return
	end

	-- InputEnded can arrive without a final MouseMovement event.
	-- Capture the actual mouse position in the same GUI coordinate space.
	lastPointerPosition = getGuiMousePosition()

	-- IMPORTANT: a normal click is also a hotbar selection. The drag
	-- controller owns MouseButton1, so handle the click here before
	-- finishing the drag state. If the pointer moved far enough,
	-- state.dragging is true and this block is skipped.
	local clickState = dragState
	if clickState and not clickState.dragging and clickState.source == "Slot" then
		if os.clock() >= suppressNextClickUntil then
			selectHotbarSlot(clickState.slotIndex)
		end
	end

	finishHotbarDrag()
end)

--==============================
-- LIVE INVENTORY SIGNATURE
--
-- The old client only refreshed when an event arrived.
-- Server-side potato tool rebuilds can happen between
-- those events, so the UI could stay at "0 items".
--
-- This signature lets the backpack detect the REAL
-- current tool state while it is open.
--==================================================

local function getInventorySignature()

	local parts = {}

	for _, tool in ipairs(
		getAllTools()
	) do

		table.insert(
			parts,
			table.concat(
				{
					tostring(tool),
					tostring(tool.Name),
					tostring(tool.Parent),
					tostring(tool:GetAttribute("PotatoId")),
					tostring(tool:GetAttribute("PotatoType")),
					tostring(tool:GetAttribute("PotatoInventoryTool")),
					tostring(tool:GetAttribute("LocalFavorite")),
					tostring(tool:GetAttribute("HoeId")),
					tostring(tool:GetAttribute("HoeTier")),
					tostring(tool:GetAttribute("Durability")),
					tostring(tool:GetAttribute("MaxDurability")),
					tostring(tool:GetAttribute("DigSpeedBonus")),
					tostring(tool:GetAttribute("CrateTool")),
					tostring(tool:GetAttribute("CrateType")),
					tostring(tool:GetAttribute("CrateCount")),
				},
				"|"
			)
		)

	end

	table.sort(parts)

	return
		table.concat(
			parts,
			";"
		)

end

local lastInventorySignature =
	""

overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.BackgroundColor3 = COLORS.Overlay
-- Transparent click-catcher: the world stays fully visible.
overlay.BackgroundTransparency = 1
overlay.Size = UDim2.fromScale(1, 1)
overlay.ZIndex = 10
overlay.Visible = false
overlay.Parent = gui

main = Instance.new("Frame")
main.Name = "BackpackWindow"
main.AnchorPoint = Vector2.new(0.5, 0)
main.Position = UDim2.new(0.5, 0, 0.16, 0)
main.Size = UDim2.fromOffset(900, 350)
main.BackgroundColor3 = COLORS.Window
main.BorderSizePixel = 0
main.ZIndex = 20
main.Visible = false
main.Parent = gui
corner(main, 10)
stroke(main, COLORS.Line, 1, 0.15)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(620, 320)
sizeConstraint.MaxSize = Vector2.new(820, 430)
sizeConstraint.Parent = main

--==================================================
-- HEADER
--==================================================

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = COLORS.Peach
header.BorderSizePixel = 0
header.Parent = main
corner(header, 10)

-- Square off lower header corners visually.
local headerFill = Instance.new("Frame")
headerFill.BackgroundColor3 = COLORS.Peach
headerFill.BorderSizePixel = 0
headerFill.Position = UDim2.new(0, 0, 1, -14)
headerFill.Size = UDim2.new(1, 0, 0, 14)
headerFill.Parent = header

local title = makeLabel(header, "POTATIUM PACK", 20, Enum.Font.GothamBold, COLORS.DarkText)
title.Position = UDim2.fromOffset(16, 7)
title.Size = UDim2.fromOffset(210, 26)
title.TextXAlignment = Enum.TextXAlignment.Left

local subtitle = makeLabel(header, "B  •  inventory", 11, Enum.Font.GothamMedium, COLORS.MutedDark)
subtitle.Position = UDim2.fromOffset(17, 29)
subtitle.Size = UDim2.fromOffset(180, 18)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local searchHolder = Instance.new("Frame")
searchHolder.AnchorPoint = Vector2.new(0.5, 0.5)
searchHolder.Position = UDim2.new(0.62, 0, 0.5, 0)
searchHolder.Size = UDim2.fromOffset(250, 34)
searchHolder.BackgroundColor3 = COLORS.Cream
searchHolder.BorderSizePixel = 0
searchHolder.Parent = header
corner(searchHolder, 9)
stroke(searchHolder, COLORS.Line, 1, 0)

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.BackgroundTransparency = 1
searchBox.Position = UDim2.fromOffset(14, 0)
searchBox.Size = UDim2.new(1, -28, 1, 0)
searchBox.ClearTextOnFocus = false
searchBox.PlaceholderText = "Search items..."
searchBox.PlaceholderColor3 = COLORS.MutedDark
searchBox.Text = ""
searchBox.TextColor3 = COLORS.DarkText
searchBox.TextSize = 13
searchBox.Font = Enum.Font.Gotham
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = searchHolder

local favoriteFilter = makeButton(header, "♥")
favoriteFilter.Name = "FavoriteFilter"
favoriteFilter.AnchorPoint = Vector2.new(1, 0.5)
favoriteFilter.Position = UDim2.new(1, -60, 0.5, 0)
favoriteFilter.Size = UDim2.fromOffset(36, 34)
favoriteFilter.TextSize = 22
favoriteFilter.TextColor3 = COLORS.Danger
stroke(favoriteFilter, COLORS.Line, 1, 0)

local closeButton = makeButton(header, "×")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -12, 0.5, 0)
closeButton.Size = UDim2.fromOffset(32, 34)
closeButton.BackgroundTransparency = 1
closeButton.TextSize = 30
closeButton.TextColor3 = COLORS.DarkText

--==================================================
-- SIDEBAR
--==================================================

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Position = UDim2.fromOffset(0, 52)
sidebar.Size = UDim2.new(0, 120, 1, -52)
sidebar.BackgroundColor3 = COLORS.PeachSoft
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local divider = Instance.new("Frame")
divider.AnchorPoint = Vector2.new(1, 0)
divider.Position = UDim2.new(1, 0, 0, 0)
divider.Size = UDim2.new(0, 1, 1, 0)
divider.BackgroundColor3 = COLORS.Line
divider.BorderSizePixel = 0
divider.Parent = sidebar

local categoryContainer = Instance.new("Frame")
categoryContainer.BackgroundTransparency = 1
categoryContainer.Position = UDim2.fromOffset(10, 14)
categoryContainer.Size = UDim2.new(1, -20, 1, -28)
categoryContainer.Parent = sidebar

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 7)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = categoryContainer

local categoryButtons = {}
local categories = {
	{Name = "Potatoes", Text = "Potatoes"},
	{Name = "Crates", Text = "Crates"},
	{Name = "Materials", Text = "Materials"},
	{Name = "Hoe", Text = "Hoes"},
	{Name = "Weapons", Text = "Weapons"},
	{Name = "All", Text = "All Items"},
}

for index, data in ipairs(categories) do
	local button = makeButton(categoryContainer, data.Text)
	button.Name = data.Name .. "Button"
	button.LayoutOrder = index
	button.Size = UDim2.new(1, 0, 0, 38)
	button.TextSize = 13
	button.TextXAlignment = Enum.TextXAlignment.Left
	padding(button, 16, 8, 0, 0)
	categoryButtons[data.Name] = button
end

--==================================================
-- CONTENT
--==================================================

local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(120, 52)
content.Size = UDim2.new(1, -120, 1, -52)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.Parent = main

local categoryTitle = makeLabel(content, "POTATOES", 18, Enum.Font.GothamBold, COLORS.Text)
categoryTitle.Position = UDim2.fromOffset(20, 14)
categoryTitle.Size = UDim2.new(1, -150, 0, 26)
categoryTitle.TextXAlignment = Enum.TextXAlignment.Left

local itemCount = makeLabel(content, "0 items", 12, Enum.Font.GothamMedium, COLORS.SubText)
itemCount.AnchorPoint = Vector2.new(1, 0)
itemCount.Position = UDim2.new(1, -24, 0, 17)
itemCount.Size = UDim2.fromOffset(110, 20)
itemCount.TextXAlignment = Enum.TextXAlignment.Right

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ItemScroll"
scroll.Position = UDim2.fromOffset(18, 58)
scroll.Size = UDim2.new(1, -30, 1, -70)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = COLORS.Accent
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.Parent = content

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(105, 105)
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.FillDirection = Enum.FillDirection.Horizontal
grid.FillDirectionMaxCells = 6
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

local emptyText = makeLabel(content, "No items here.", 14, Enum.Font.GothamMedium, COLORS.SubText)
emptyText.AnchorPoint = Vector2.new(0.5, 0.5)
emptyText.Position = UDim2.fromScale(0.5, 0.53)
emptyText.Size = UDim2.fromOffset(340, 70)
emptyText.Visible = false

--==================================================
-- REFRESH FORWARD DECLARATION
--==================================================

local refreshInventory

local function queueRefresh(delayTime)
	if refreshQueued then return end
	refreshQueued = true

	task.delay(delayTime or 0.03, function()
		refreshQueued = false
		if refreshInventory then
			refreshInventory()
			lastInventorySignature =
				getInventorySignature()
		end
		if refreshHotbar then
			refreshHotbar()
		end
	end)
end

--==================================================
-- CARD CREATION
--==================================================

local function clearCards()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
end

local function createItemCard(tool, layoutOrder)
	local potato = isPotatoTool(tool)
	local displayName = getDisplayName(tool)
	local category = getToolCategory(tool)
	local equipped = isEquipped(tool)
	local favoriteKey = getFavoriteKey(tool)

	local band = nil
	if potato then
		band = POTATO_BANDS[displayName]
	end

	local accentColor = band and band.Color or COLORS.Accent

	local card = Instance.new("TextButton")
	card.Name = "ItemCard"
	card.LayoutOrder = layoutOrder
	card.Text = ""
	card.AutoButtonColor = false
	card.Active = true
	card.BackgroundColor3 = equipped and COLORS.CardEquipped or COLORS.Card
	card.BorderSizePixel = 0
	card.ZIndex = 22
	card.Parent = scroll
	corner(card, 10)
	local cardStroke = stroke(card, equipped and COLORS.AccentBright or COLORS.Line, equipped and 2 or 1, 0)

	-- No top color strip: item cards stay clean, square, and evenly spaced.

	-- Image area: intentionally blank for now.
	-- Later, set this ImageLabel's Image to each item's artwork.
	local itemImage = Instance.new("ImageLabel")
	itemImage.Name = "ItemImage"
	itemImage.AnchorPoint = Vector2.new(0.5, 0)
	itemImage.Position = UDim2.new(0.5, 0, 0, 9)
	itemImage.Size = UDim2.fromOffset(58, 58)
	itemImage.BackgroundColor3 = COLORS.Panel2
	itemImage.BackgroundTransparency = 0
	itemImage.BorderSizePixel = 0
	itemImage.Image = ""
	itemImage.ScaleType = Enum.ScaleType.Fit
	itemImage.ZIndex = 23
	itemImage.Parent = card
	corner(itemImage, 7)
	stroke(itemImage, accentColor, 1, 0.18)

	local name = makeLabel(card, displayName, 10, Enum.Font.GothamBold, COLORS.Text)
	name.Position = UDim2.fromOffset(4, 68)
	name.Size = UDim2.new(1, -8, 0, 18)
	name.TextWrapped = true
	name.TextXAlignment = Enum.TextXAlignment.Center
	name.TextYAlignment = Enum.TextYAlignment.Center

	local detail = makeLabel(card, "", 9, Enum.Font.GothamMedium, COLORS.SubText)
	detail.Position = UDim2.new(0, 5, 1, -17)
	detail.Size = UDim2.new(1, -10, 0, 12)
	detail.TextXAlignment = Enum.TextXAlignment.Center

	if potato then
		local weightText = getPotatoWeightText(tool)
		detail.Text = weightText ~= "" and weightText or (equipped and "EQUIPPED" or "POTATO")
		detail.TextColor3 = equipped and COLORS.AccentBright or accentColor
	elseif category == "Hoe" then
		local durability =
			tonumber(
				tool:GetAttribute(
					"Durability"
				)
			)

		local maxDurability =
			tonumber(
				tool:GetAttribute(
					"MaxDurability"
				)
			)

		if
			durability
			and
			maxDurability
		then
			detail.Text =
				(
					equipped
					and
					"EQUIPPED • "
					or
					"DUR "
				)
				..
				tostring(
					durability
				)
				..
				"/"
				..
				tostring(
					maxDurability
				)
		else
			detail.Text =
				equipped
				and
				"EQUIPPED"
				or
				"TOOL"
		end

		detail.TextColor3 =
			equipped
			and
			COLORS.AccentBright
			or
			COLORS.SubText
	elseif category == "Crates" then
		local crateCount =
			math.max(
				1,
				math.floor(
					tonumber(
						tool:GetAttribute(
							"CrateCount"
						)
					)
					or
					1
				)
			)

		detail.Text =
			"CRATE  •  x"
			..
			tostring(
				crateCount
			)

		detail.TextColor3 =
			COLORS.AccentBright

	elseif category == "Weapons" then
		detail.Text = equipped and "EQUIPPED" or "WEAPON"
	else
		detail.Text = equipped and "EQUIPPED" or "MATERIAL"
	end

	local allowFavorite =
		potato
		or
		category
		==
		"Hoe"

	if allowFavorite then
		local heart = Instance.new("TextButton")
		heart.Name = "Heart"
		heart.AnchorPoint = Vector2.new(1, 0)
		heart.Position = UDim2.new(1, -6, 0, 6)
		heart.Size = UDim2.fromOffset(24, 24)
		heart.BorderSizePixel = 0
		heart.AutoButtonColor = false
		heart.Active = true
		heart.Font = Enum.Font.GothamBold
		heart.TextSize = 13
		heart.ZIndex = 40
		heart.Parent = card
		corner(heart, 10)
		stroke(heart, COLORS.Danger, 1.2, 0.05)

		local function paintFavoriteHeart()
			local active = favorites[favoriteKey] == true
			heart.Text = active and "♥" or "♡"
			heart.BackgroundColor3 = active and COLORS.Danger or COLORS.Cream
			heart.TextColor3 = active and COLORS.White or COLORS.Danger
		end

		paintFavoriteHeart()

		tool:SetAttribute(
			"LocalFavorite",
			favorites[favoriteKey]
			==
			true
		)

		heart.MouseButton1Click:Connect(function()
			favorites[favoriteKey] =
				not
				favorites[favoriteKey]

			local isFavorite =
				favorites[favoriteKey]
				==
				true

			paintFavoriteHeart()

			tool:SetAttribute(
				"LocalFavorite",
				isFavorite
			)

			if potato then
				local potatoId =
					tool:GetAttribute(
						"PotatoId"
					)

				if
					potatoId ~= nil
					and
					setPotatoFavorite
				then
					setPotatoFavorite:FireServer(
						potatoId,
						isFavorite
					)
				end

			elseif category == "Hoe" then
				local hoeId =
					tool:GetAttribute(
						"HoeId"
					)

				if
					hoeId ~= nil
					and
					setHoeFavorite
				then
					setHoeFavorite:FireServer(
						hoeId,
						isFavorite
					)
				end
			end

			if favoritesOnly then
				queueRefresh()
			end
		end)
	end

	--==================================================
	-- CLICK TO EQUIP
	--==================================================

	card.Activated:Connect(function()
		if dragState and dragState.dragging then
			return
		end

		-- Favorites have their own button; this is the item body.
		local wasEquipped = isEquipped(tool)
		local equippedNow = toggleEquip(tool)
		if equippedNow or wasEquipped then
			queueRefresh(0.02)
		end
	end)

	--==================================================
	-- DRAG INTO HOTBAR
	--==================================================

	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginHotbarDrag("Card", getHotbarKey(tool), nil)
		end
	end)

	card.MouseEnter:Connect(function()
		if not isEquipped(tool) then
			TweenService:Create(
				card,
				TweenInfo.new(0.08),
				{BackgroundColor3 = COLORS.CardHover}
			):Play()
		end
	end)

	card.MouseLeave:Connect(function()
		local target = isEquipped(tool) and COLORS.CardEquipped or COLORS.Card
		TweenService:Create(
			card,
			TweenInfo.new(0.08),
			{BackgroundColor3 = target}
		):Play()
	end)

	-- Cards are created AFTER the initial ZIndex pass, so explicitly
	-- lift every card child above the dark overlay.
	for _, descendant in ipairs(card:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			descendant.ZIndex = 23
		end
	end
	card.ZIndex = 22
	local finalHeart = card:FindFirstChild("Heart")
	if finalHeart and finalHeart:IsA("GuiObject") then
		finalHeart.ZIndex = 24
	end

	return card, cardStroke
end

--==================================================
-- REFRESH INVENTORY
--==================================================

refreshInventory = function()
	if not backpackOpen then
		return
	end

	clearCards()

	local tools = getAllTools()
	local shown = 0
	local lowerSearch = string.lower(searchText)

	for _, tool in ipairs(tools) do
		local category = getToolCategory(tool)
		local displayName = getDisplayName(tool)
		local favoriteKey = getFavoriteKey(tool)

		local categoryMatches = selectedCategory == "All" or category == selectedCategory
		local searchMatches = lowerSearch == ""
			or string.find(string.lower(displayName), lowerSearch, 1, true) ~= nil
		local favoriteMatches = not favoritesOnly or favorites[favoriteKey] == true

		-- Once an item is assigned to the custom hotbar, remove it from
		-- the inventory list. It remains a real Tool and can still be
		-- equipped from the hotbar. If its hotbar slot is cleared, it
		-- automatically becomes visible in the inventory again.
		local hotbarAssigned = false
		local toolKey = getHotbarKey(tool)
		if toolKey then
			for hotbarIndex = 1, HOTBAR_SLOT_COUNT do
				if hotbarSlots[hotbarIndex] == toolKey then
					hotbarAssigned = true
					break
				end
			end
		end

		if categoryMatches and searchMatches and favoriteMatches and not hotbarAssigned then
			shown += 1
			createItemCard(tool, shown)
		end
	end

	itemCount.Text = tostring(shown) .. (shown == 1 and " item" or " items")
	if refreshHotbar then
		refreshHotbar()
	end
	emptyText.Visible = shown == 0

	if shown == 0 then
		if favoritesOnly then
			emptyText.Text = "No favorite items in this view."
		elseif searchText ~= "" then
			emptyText.Text = "No items match your search."
		elseif selectedCategory == "Potatoes" then
			emptyText.Text = "No potato tools detected."
		elseif selectedCategory == "Crates" then
			emptyText.Text = "No crates in your Backpack."
		elseif selectedCategory == "Hoe" then
			emptyText.Text = "No hoes in your Backpack."
		else
			emptyText.Text = "No items in this category."
		end
	end
end

--==================================================
-- CATEGORY VISUALS
--==================================================

local function updateCategoryButtons()
	for categoryName, button in pairs(categoryButtons) do
		local selected = categoryName == selectedCategory
		button.BackgroundColor3 = selected and COLORS.Accent or COLORS.Cream
		button.TextColor3 = selected and COLORS.Black or COLORS.DarkText
	end

	if selectedCategory == "All" then
		categoryTitle.Text = "ALL ITEMS"
	elseif selectedCategory == "Hoe" then
		categoryTitle.Text = "HOES"
	else
		categoryTitle.Text =
			string.upper(
				selectedCategory
			)
	end
end

for categoryName, button in pairs(categoryButtons) do
	button.MouseButton1Click:Connect(function()
		selectedCategory = categoryName
		updateCategoryButtons()
		refreshInventory()
	end)
end

--==================================================
-- FAVORITE FILTER
--==================================================

local function updateFavoriteFilterVisual()
	favoriteFilter.BackgroundColor3 = favoritesOnly and COLORS.Danger or COLORS.Cream
	favoriteFilter.TextColor3 = favoritesOnly and COLORS.White or COLORS.Danger
end

favoriteFilter.MouseButton1Click:Connect(function()
	favoritesOnly = not favoritesOnly
	updateFavoriteFilterVisual()
	refreshInventory()
end)

--==================================================
-- SEARCH
--==================================================

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchText = searchBox.Text
	queueRefresh()
end)

--==================================================
-- FINAL UI Z-ORDER
--==================================================
-- The overlay must stay behind the backpack window.
-- Otherwise it can visually cover the backpack while the
-- custom hotbar remains visible above it.

for _, object in ipairs(main:GetDescendants()) do
	if object:IsA("GuiObject") then
		object.ZIndex = 21
	end
end

--==================================================
-- DRAG VISIBILITY HELPERS
--==================================================

hideBackpackForDrag = function()
	if not backpackOpen then
		return
	end

	main.Visible = false
	overlay.Visible = false
	hotbarGui.Visible = true
end

restoreBackpackAfterDrag = function()
	if not backpackOpen then
		return
	end

	main.Visible = true
	overlay.Visible = true
	hotbarGui.Visible = true

	updateCategoryButtons()
	updateFavoriteFilterVisual()
	refreshInventory()
	lastInventorySignature = getInventorySignature()
end

--==================================================
-- OPEN / CLOSE
--==================================================

local function disableRobloxHotbar()
	for _ = 1, 5 do
		local success = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if success then
			return
		end
		task.wait(0.1)
	end
end

-- Potatium uses the custom 1-9 hotbar.
-- Roblox's default backpack/hotbar stays disabled permanently so
-- the two hotbars cannot overlap or steal mouse input.
disableRobloxHotbar()
task.delay(0.5, disableRobloxHotbar)
task.delay(1.5, disableRobloxHotbar)

player.CharacterAdded:Connect(function()
	task.delay(0.5, disableRobloxHotbar)
end)

local function openBackpack()
	if backpackOpen then return end
	backpackOpen = true

	main.Visible = true
	print("🎒 Backpack OPEN | main=" .. tostring(main.Visible) .. " | overlay=" .. tostring(overlay.Visible))
	overlay.Visible = true
	disableRobloxHotbar()

	main.Size = UDim2.fromOffset(880, 334)
	main.BackgroundTransparency = 0.08
	hotbarGui.Visible = true

	TweenService:Create(
		main,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.fromOffset(900, 350),
			BackgroundTransparency = 0,
		}
	):Play()

	updateCategoryButtons()
	updateFavoriteFilterVisual()

	-- Pull the REAL saved inventory immediately.
	task.spawn(function()
		syncServerPotatoSnapshot()
		syncServerEquipmentSnapshot()

		if backpackOpen then
			refreshInventory()

			lastInventorySignature =
				getInventorySignature()
		end
	end)

	refreshInventory()
	lastInventorySignature =
		getInventorySignature()

	-- Extra checks catch server inventory/tool replication
	-- that finishes just after the window opens.
	task.delay(0.10, queueRefresh)
	task.delay(0.25, queueRefresh)
	task.delay(0.50, queueRefresh)
end

local function closeBackpack()
	if not backpackOpen then return end
	backpackOpen = false
	hotbarGui.Visible = true
	print("🎒 Backpack CLOSE")
	searchBox:ReleaseFocus()
	disableRobloxHotbar()

	local tween = TweenService:Create(
		main,
		TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = UDim2.fromOffset(740, 372),
			BackgroundTransparency = 0.08,
		}
	)

	tween:Play()
	tween.Completed:Once(function()
		if not backpackOpen then
			main.Visible = false
			overlay.Visible = false
			main.BackgroundTransparency = 0
		end
	end)
end

local function toggleBackpack()
	if backpackOpen then
		closeBackpack()
	else
		openBackpack()
	end
end

closeButton.MouseButton1Click:Connect(
	closeBackpack
)

-- IMPORTANT:
-- The full-screen overlay can receive clicks that pass through
-- empty parts of the backpack window. Previously that meant
-- clicking sidebar gaps / empty peach space closed the backpack.
-- Now we close ONLY when the actual click is outside the window.
overlay.MouseButton1Click:Connect(
	function()
		local mousePosition =
			UserInputService:GetMouseLocation()

		local topLeft =
			main.AbsolutePosition

		local size =
			main.AbsoluteSize

		local insideMain =
			mousePosition.X
				>=
				topLeft.X
			and
			mousePosition.X
				<=
				topLeft.X
				+
				size.X
			and
			mousePosition.Y
				>=
				topLeft.Y
			and
			mousePosition.Y
				<=
				topLeft.Y
				+
				size.Y

		if not insideMain then
			closeBackpack()
		end
	end
)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- B must always open/close the custom backpack, even if Roblox
	-- marks the keyboard input as already processed.
	if input.KeyCode == OPEN_KEY then
		toggleBackpack()
		return
	end

	-- Number keys belong to the custom hotbar. Roblox/CoreGui may
	-- report them as gameProcessed because its normal hotbar also
	-- listens for 1-0. We intentionally still handle them here.
	local numberKeys = {
		[Enum.KeyCode.One] = 1,
		[Enum.KeyCode.Two] = 2,
		[Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four] = 4,
		[Enum.KeyCode.Five] = 5,
		[Enum.KeyCode.Six] = 6,
		[Enum.KeyCode.Seven] = 7,
		[Enum.KeyCode.Eight] = 8,
		[Enum.KeyCode.Nine] = 9,
		[Enum.KeyCode.Zero] = 10,
	}

	local hotbarIndex = numberKeys[input.KeyCode]
	if hotbarIndex then
		selectHotbarSlot(hotbarIndex)
		return
	end

	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Escape and backpackOpen then
		closeBackpack()
	end
end)

--==================================================
-- LIVE HOE / CRATE ATTRIBUTE WATCH
--
-- The normal Roblox ChildAdded event does not fire when
-- only durability/count changes. These direct watchers make
-- the custom backpack redraw immediately.
--==================================================

local liveWatchedTools = {}

local function shouldLiveWatchTool(tool)
	if
		not tool
		or
		not tool:IsA("Tool")
	then
		return false
	end

	return
		tool:GetAttribute("FarmingToolType") == "Hoe"
		or
		tool:GetAttribute("HoeTier") ~= nil
		or
		tool:GetAttribute("HoeId") ~= nil
		or
		tool:GetAttribute("CrateTool") == true
		or
		tool:GetAttribute("CrateType") ~= nil
end

local function watchLiveTool(tool)
	if
		not shouldLiveWatchTool(tool)
		or
		liveWatchedTools[tool]
	then
		return
	end

	local connections = {}
	liveWatchedTools[tool] = connections

	local function changed()
		queueRefresh(0)
	end

	for _, attributeName in ipairs({
		"Durability",
		"MaxDurability",
		"HoeTier",
		"HoeId",
		"FarmingToolType",
		"DigSpeedBonus",
		"ExtraPotatoChance",
		"BetterRollChance",
		"CrateTool",
		"CrateType",
		"CrateCount",
	}) do
		table.insert(
			connections,
			tool:GetAttributeChangedSignal(
				attributeName
			):Connect(
				changed
			)
		)
	end

	table.insert(
		connections,
		tool:GetPropertyChangedSignal(
			"Name"
		):Connect(
			changed
		)
	)

	table.insert(
		connections,
		tool.Destroying:Connect(
			function()
				local saved =
					liveWatchedTools[
						tool
					]

				if saved then
					for _, connection in ipairs(
						saved
					) do
						connection:Disconnect()
					end
				end

				liveWatchedTools[
					tool
				] =
					nil

				queueRefresh(0)
			end
		)
	)

	queueRefresh(0)
end

local function scanLiveTools()
	for _, tool in ipairs(
		getAllTools()
	) do
		watchLiveTool(
			tool
		)
	end
end

--==================================================
-- WATCH TOOL CHANGES
--==================================================

backpack.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		watchLiveTool(child)
		queueRefresh(0)
	end
end)

backpack.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") then
		queueRefresh(0)
	end
end)

local characterConnections = {}

local function disconnectCharacterConnections()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end
	table.clear(characterConnections)
end

local function watchCharacter(character)
	disconnectCharacterConnections()

	table.insert(characterConnections, character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			watchLiveTool(child)
			queueRefresh(0)
		end
	end))

	table.insert(characterConnections, character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			queueRefresh(0)
		end
	end))

	task.defer(
		scanLiveTools
	)
end

if player.Character then
	watchCharacter(player.Character)
end

player.CharacterAdded:Connect(function(character)
	watchCharacter(character)
	task.wait(0.5)
	queueRefresh()
end)

player:GetAttributeChangedSignal("PotatoInventoryRevision"):Connect(function()
	task.spawn(function()
		syncServerPotatoSnapshot()
		queueRefresh(0)
	end)

	-- InventoryService reacts to this on the server too.
	-- Refresh a few times so the client never gets stuck
	-- on the empty moment between remove/create replication.
	queueRefresh(0.02)
	task.delay(0.10, function()
		queueRefresh(0)
	end)
	task.delay(0.25, function()
		queueRefresh(0)
	end)
	task.delay(0.50, function()
		queueRefresh(0)
	end)
end)

--==================================================
-- HOE + CRATE SERVER REVISION EVENTS
--==================================================

player:GetAttributeChangedSignal(
	"HoeInventoryRevision"
):Connect(
	function()
		task.spawn(
			function()
				syncServerEquipmentSnapshot()
				scanLiveTools()
				queueRefresh(0)
			end
		)

		for _, delayTime in ipairs({
			0.05,
			0.15,
			0.35,
			0.75,
		}) do
			task.delay(
				delayTime,
				function()
					syncServerEquipmentSnapshot()
					scanLiveTools()
					queueRefresh(0)
				end
			)
		end
	end
)

player:GetAttributeChangedSignal(
	"CrateInventoryRevision"
):Connect(
	function()
		task.spawn(
			function()
				syncServerEquipmentSnapshot()
				scanLiveTools()
				queueRefresh(0)
			end
		)

		for _, delayTime in ipairs({
			0.05,
			0.15,
			0.35,
		}) do
			task.delay(
				delayTime,
				function()
					syncServerEquipmentSnapshot()
					scanLiveTools()
					queueRefresh(0)
				end
			)
		end
	end
)

player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
	if player:GetAttribute("DataLoaded") == true then
		task.delay(
			0.10,
			function()
				syncServerPotatoSnapshot()
				syncServerEquipmentSnapshot()
				scanLiveTools()
				loadSavedHotbar()
				queueRefresh(0)
			end
		)
	end
end)

--==================================================
-- PERIODIC SERVER SNAPSHOT WHILE OPEN
--==================================================

task.spawn(function()
	while true do
		task.wait(0.5)

		if backpackOpen then
			syncServerPotatoSnapshot()
			syncServerEquipmentSnapshot()
		end
	end
end)

--==================================================
-- LIVE OPEN-BACKPACK WATCH
--
-- This is the final fallback. While the pack is open,
-- compare the real Roblox Backpack/Character tool state.
-- The UI only rebuilds when something actually changed.
--==================================================

task.spawn(function()

	while true do

		task.wait(0.10)

		local signature =
			getInventorySignature()

		if
			signature
			~=
			lastInventorySignature
		then

			lastInventorySignature =
				signature

			if backpackOpen and refreshInventory then
				refreshInventory()
			end

			if refreshHotbar then
				refreshHotbar()
			end
		end

	end

end)

--==================================================
-- INITIAL
--==================================================

scanLiveTools()
updateCategoryButtons()
updateFavoriteFilterVisual()
disableRobloxHotbar()
task.spawn(function()
	-- Wait for the server-owned layout instead of treating an early
	-- empty response as the player's saved layout.
	for attempt = 1, 5 do
		if loadSavedHotbar() then
			break
		end
		task.wait(0.5)
	end
	if refreshHotbar then
		refreshHotbar()
	end
end)
if refreshHotbar then
	refreshHotbar()
end

print("✅ Roblox default hotbar DISABLED")
print("✅ Potatium custom 1-9 hotbar is the ONLY hotbar")
print("✅ Backpack hotkey B listener installed")
print("✅ Inventory starts on ALL ITEMS")
print("✅ Card drag hides bag and reopens after drop")
print("✅ Favorite heart uses filled/outlined design")
print("✅ Custom hotbar initialized")
print("✅ Drag release uses GUI-inset corrected mouse coordinates")
print("✅ Drag release places items into hotbar slots")
print("✅ Hotbar layout persists across rejoin")
print("✅ Missing tools do not erase hotbar assignments")

print("")
print("========================================")
print("🎒 POTATIUM BACKPACK V2.8 - PERSISTENT FAVORITES")
print("========================================")
print("✅ Current potato detection")
print("✅ PotatoId / PotatoType fallback")
print("✅ Current Meadow names")
print("✅ Favorite sync with Potato Trader")
print("✅ Cleaner compact UI")
print("✅ Glitched symbols removed")
print("✅ Custom 1-9 drag hotbar enabled")
print("✅ Hotbar stays visible while Backpack is open")
print("✅ Backpack moved to top and height reduced")
print("✅ Drag threshold lowered for easier card dragging")
print("✅ Live inventory watch = 0.15 sec")
print("✅ Server snapshot fills missing potato cards")
print("✅ PotatoInventoryRevision retry sync")
print("✅ Hoe durability updates live")
print("✅ New hoes appear automatically")
print("✅ New CRATES tab")
print("✅ Crate counts update automatically")
print("✅ Hoe + Crate revision events connected")
print("✅ Server equipment snapshot enabled")
print("✅ Crates/hoes display even during Tool replication delay")
print("✅ Sidebar gaps no longer close Backpack")
print("❤️ Potato favorites restore after rejoin")
print("❤️ Hoe favorites restore after rejoin")
print("✅ Drag items into hotbar slots")
print("✅ 1-9 equips hotbar slots")
print("✅ Drag hotbar slots to rearrange")
print("✅ B = open / close")
print("========================================")
print("")
