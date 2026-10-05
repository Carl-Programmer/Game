--==================================================
-- POTATIUM SIMPLE INVENTORY V2
--
-- Uses:
-- 1. Real Roblox Tools
-- 2. Existing Potato Snapshot
-- 3. Existing Equipment Snapshot
--
-- This means items do NOT need to be in the
-- 10-slot Roblox hotbar to appear here.
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local backpack = player:WaitForChild("Backpack")

--==================================================
-- SETTINGS
--==================================================

local OPEN_KEY = Enum.KeyCode.B

local CATEGORY_ALL = "All"
local CATEGORY_POTATOES = "Potatoes"
local CATEGORY_HOES = "Hoes"
local CATEGORY_CRATES = "Crates"
local CATEGORY_ITEMS = "Items"

local selectedCategory = CATEGORY_ALL
local favoritesOnly = false
local searchText = ""

--==================================================
-- EXISTING POTATIUM INVENTORY REMOTES
--==================================================

local inventoryRemotes =
	ReplicatedStorage:WaitForChild(
		"PotatiumInventoryRemotes",
		10
	)

local getPotatoSnapshot =
	inventoryRemotes
	and inventoryRemotes:FindFirstChild(
		"GetPotatoSnapshot"
	)

--==================================================
-- EXISTING POTATIUM EQUIPMENT REMOTES
--==================================================

local crateRemotes =
	ReplicatedStorage:WaitForChild(
		"PotatiumCrateRemotes",
		10
	)

local getEquipmentSnapshot =
	crateRemotes
	and crateRemotes:FindFirstChild(
		"GetEquipmentSnapshot"
	)

--==================================================
-- OUR FAVORITE REMOTES
--==================================================

local favoriteRemotes =
	ReplicatedStorage:WaitForChild(
		"PotatiumInventoryRemotes",
		10
	)

local getFavorites =
	favoriteRemotes
	and favoriteRemotes:FindFirstChild(
		"GetFavorites"
	)

local setFavorite =
	favoriteRemotes
	and favoriteRemotes:FindFirstChild(
		"SetFavorite"
	)

--==================================================
-- FAVORITES
--==================================================

local favorites = {}

if getFavorites then

	local success, data =
		pcall(function()

			return getFavorites:InvokeServer()

		end)

	if success and type(data) == "table" then

		favorites = data

	end

end

--==================================================
-- MIRROR FOLDERS
--
-- These are ONLY display representations.
-- They are NOT placed in Backpack.
--==================================================

local potatoMirror =
	script:FindFirstChild(
		"PotatoInventoryMirror"
	)

if not potatoMirror then

	potatoMirror =
		Instance.new("Folder")

	potatoMirror.Name =
		"PotatoInventoryMirror"

	potatoMirror.Parent =
		script

end

local equipmentMirror =
	script:FindFirstChild(
		"EquipmentInventoryMirror"
	)

if not equipmentMirror then

	equipmentMirror =
		Instance.new("Folder")

	equipmentMirror.Name =
		"EquipmentInventoryMirror"

	equipmentMirror.Parent =
		script

end

--==================================================
-- COLORS
--==================================================

local COLORS = {

	Background =
		Color3.fromRGB(
			18,
			20,
			24
		),

	Panel =
		Color3.fromRGB(
			25,
			28,
			34
		),

	PanelLight =
		Color3.fromRGB(
			32,
			36,
			43
		),

	Card =
		Color3.fromRGB(
			31,
			35,
			41
		),

	CardHover =
		Color3.fromRGB(
			42,
			47,
			55
		),

	Text =
		Color3.fromRGB(
			245,
			245,
			245
		),

	SubText =
		Color3.fromRGB(
			165,
			170,
			180
		),

	Line =
		Color3.fromRGB(
			65,
			70,
			80
		),

	Heart =
		Color3.fromRGB(
			235,
			75,
			90
		),

	HeartOff =
		Color3.fromRGB(
			120,
			125,
			135
		),

}

--==================================================
-- GUI
--==================================================

local oldGui =
	playerGui:FindFirstChild(
		"PotatiumInventoryGui"
	)

if oldGui then
	oldGui:Destroy()
end

local gui =
	Instance.new("ScreenGui")

gui.Name =
	"PotatiumInventoryGui"

gui.ResetOnSpawn =
	false

gui.IgnoreGuiInset =
	true

gui.DisplayOrder =
	50

gui.Parent =
	playerGui

--==================================================
-- MAIN
--==================================================

local main =
	Instance.new("Frame")

main.Name =
	"Inventory"

main.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)

main.Position =
	UDim2.fromScale(
		0.5,
		0.5
	)

main.Size =
	UDim2.fromOffset(
		850,
		560
	)

main.BackgroundColor3 =
	COLORS.Background

main.BorderSizePixel =
	0

main.Visible =
	false

main.Parent =
	gui

local mainCorner =
	Instance.new("UICorner")

mainCorner.CornerRadius =
	UDim.new(
		0,
		12
	)

mainCorner.Parent =
	main

local mainStroke =
	Instance.new("UIStroke")

mainStroke.Color =
	COLORS.Line

mainStroke.Thickness =
	1

mainStroke.Parent =
	main

--==================================================
-- HEADER
--==================================================

local header =
	Instance.new("Frame")

header.Size =
	UDim2.new(
		1,
		0,
		0,
		65
	)

header.BackgroundColor3 =
	COLORS.Panel

header.BorderSizePixel =
	0

header.Parent =
	main

local title =
	Instance.new("TextLabel")

title.BackgroundTransparency =
	1

title.Position =
	UDim2.fromOffset(
		22,
		10
	)

title.Size =
	UDim2.fromOffset(
		250,
		28
	)

title.Text =
	"INVENTORY"

title.TextColor3 =
	COLORS.Text

title.TextSize =
	22

title.Font =
	Enum.Font.GothamBold

title.TextXAlignment =
	Enum.TextXAlignment.Left

title.Parent =
	header

local subtitle =
	Instance.new("TextLabel")

subtitle.BackgroundTransparency =
	1

subtitle.Position =
	UDim2.fromOffset(
		23,
		36
	)

subtitle.Size =
	UDim2.fromOffset(
		250,
		20
	)

subtitle.Text =
	"Your Potatium items"

subtitle.TextColor3 =
	COLORS.SubText

subtitle.TextSize =
	12

subtitle.Font =
	Enum.Font.Gotham

subtitle.TextXAlignment =
	Enum.TextXAlignment.Left

subtitle.Parent =
	header

--==================================================
-- SEARCH
--==================================================

local searchBox =
	Instance.new("TextBox")

searchBox.Position =
	UDim2.new(
		1,
		-310,
		0,
		15
	)

searchBox.Size =
	UDim2.fromOffset(
		220,
		35
	)

searchBox.BackgroundColor3 =
	COLORS.PanelLight

searchBox.BorderSizePixel =
	0

searchBox.Text =
	""

searchBox.PlaceholderText =
	"Search..."

searchBox.PlaceholderColor3 =
	COLORS.SubText

searchBox.TextColor3 =
	COLORS.Text

searchBox.TextSize =
	13

searchBox.Font =
	Enum.Font.Gotham

searchBox.ClearTextOnFocus =
	false

searchBox.Parent =
	header

local searchCorner =
	Instance.new("UICorner")

searchCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

searchCorner.Parent =
	searchBox

--==================================================
-- CLOSE
--==================================================

local closeButton =
	Instance.new("TextButton")

closeButton.Size =
	UDim2.fromOffset(
		35,
		35
	)

closeButton.Position =
	UDim2.new(
		1,
		-48,
		0,
		15
	)

closeButton.BackgroundTransparency =
	1

closeButton.Text =
	"×"

closeButton.TextColor3 =
	COLORS.Text

closeButton.TextSize =
	28

closeButton.Font =
	Enum.Font.Gotham

closeButton.Parent =
	header

--==================================================
-- SIDEBAR
--==================================================

local sidebar =
	Instance.new("Frame")

sidebar.Position =
	UDim2.fromOffset(
		0,
		65
	)

sidebar.Size =
	UDim2.new(
		0,
		150,
		1,
		-65
	)

sidebar.BackgroundColor3 =
	COLORS.Panel

sidebar.BorderSizePixel =
	0

sidebar.Parent =
	main

local categories = {

	{
		Name = CATEGORY_ALL,
		Text = "All Items",
	},

	{
		Name = CATEGORY_POTATOES,
		Text = "🥔  Potatoes",
	},

	{
		Name = CATEGORY_HOES,
		Text = "⛏  Hoes",
	},

	{
		Name = CATEGORY_CRATES,
		Text = "📦  Crates",
	},

	{
		Name = CATEGORY_ITEMS,
		Text = "🎒  Items",
	},

}

--==================================================
-- CONTENT
--==================================================

local content =
	Instance.new("Frame")

content.Position =
	UDim2.fromOffset(
		150,
		65
	)

content.Size =
	UDim2.new(
		1,
		-150,
		1,
		-65
	)

content.BackgroundTransparency =
	1

content.Parent =
	main

--==================================================
-- CATEGORY TITLE
--==================================================

local categoryTitle =
	Instance.new("TextLabel")

categoryTitle.BackgroundTransparency =
	1

categoryTitle.Position =
	UDim2.fromOffset(
		20,
		15
	)

categoryTitle.Size =
	UDim2.fromOffset(
		300,
		30
	)

categoryTitle.Text =
	"ALL"

categoryTitle.TextColor3 =
	COLORS.Text

categoryTitle.TextSize =
	18

categoryTitle.Font =
	Enum.Font.GothamBold

categoryTitle.TextXAlignment =
	Enum.TextXAlignment.Left

categoryTitle.Parent =
	content

--==================================================
-- FAVORITES FILTER
--==================================================

local favoriteButton =
	Instance.new("TextButton")

favoriteButton.Size =
	UDim2.fromOffset(
		42,
		36
	)

favoriteButton.Position =
	UDim2.new(
		1,
		-62,
		0,
		12
	)

favoriteButton.BackgroundColor3 =
	COLORS.PanelLight

favoriteButton.BorderSizePixel =
	0

favoriteButton.Text =
	"♥"

favoriteButton.TextSize =
	21

favoriteButton.TextColor3 =
	COLORS.HeartOff

favoriteButton.Font =
	Enum.Font.GothamBold

favoriteButton.Parent =
	content

local favCorner =
	Instance.new("UICorner")

favCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

favCorner.Parent =
	favoriteButton

--==================================================
-- COUNT
--==================================================

local itemCount =
	Instance.new("TextLabel")

itemCount.BackgroundTransparency =
	1

itemCount.Position =
	UDim2.new(
		1,
		-180,
		0,
		20
	)

itemCount.Size =
	UDim2.fromOffset(
		100,
		20
	)

itemCount.Text =
	"0 items"

itemCount.TextColor3 =
	COLORS.SubText

itemCount.TextSize =
	12

itemCount.Font =
	Enum.Font.Gotham

itemCount.TextXAlignment =
	Enum.TextXAlignment.Right

itemCount.Parent =
	content

--==================================================
-- SCROLL
--==================================================

local scroll =
	Instance.new("ScrollingFrame")

scroll.Position =
	UDim2.fromOffset(
		20,
		58
	)

scroll.Size =
	UDim2.new(
		1,
		-40,
		1,
		-75
	)

scroll.BackgroundTransparency =
	1

scroll.BorderSizePixel =
	0

scroll.ScrollBarThickness =
	5

scroll.ScrollBarImageColor3 =
	COLORS.SubText

scroll.AutomaticCanvasSize =
	Enum.AutomaticSize.Y

scroll.CanvasSize =
	UDim2.fromOffset(
		0,
		0
	)

scroll.Parent =
	content

local grid =
	Instance.new("UIGridLayout")

grid.CellSize =
	UDim2.fromOffset(
		150,
		175
	)

grid.CellPadding =
	UDim2.fromOffset(
		10,
		10
	)

grid.SortOrder =
	Enum.SortOrder.LayoutOrder

grid.Parent =
	scroll

--==================================================
-- HELPERS
--==================================================

local function addCorner(
	object,
	radius
)

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(
			0,
			radius
		)

	corner.Parent =
		object

end

--==================================================
-- CATEGORY
--==================================================

local function getCategory(tool)

	if not tool:IsA("Tool") then
		return CATEGORY_ITEMS
	end

	if tool:GetAttribute(
		"PotatoId"
	) ~= nil then

		return CATEGORY_POTATOES

	end

	if tool:GetAttribute(
		"PotatoInventoryTool"
	) == true then

		return CATEGORY_POTATOES

	end

	if tool:GetAttribute(
		"FarmingToolType"
	) == "Hoe" then

		return CATEGORY_HOES

	end

	if tool:GetAttribute(
		"HoeId"
	) ~= nil then

		return CATEGORY_HOES

	end

	if tool:GetAttribute(
		"CrateTool"
	) == true then

		return CATEGORY_CRATES

	end

	if tool:GetAttribute(
		"CrateType"
	) ~= nil then

		return CATEGORY_CRATES

	end

	local lowerName =
		string.lower(
			tool.Name
		)

	if string.find(
		lowerName,
		"potato",
		1,
		true
	) then

		return CATEGORY_POTATOES

	end

	if string.find(
		lowerName,
		"hoe",
		1,
		true
	) then

		return CATEGORY_HOES

	end

	if string.find(
		lowerName,
		"crate",
		1,
		true
	) then

		return CATEGORY_CRATES

	end

	return CATEGORY_ITEMS

end

--==================================================
-- DISPLAY NAME
--==================================================

local function getDisplayName(tool)

	local display =
		tool:GetAttribute(
			"DisplayName"
		)

	if display then
		return tostring(display)
	end

	return tool.Name

end

--==================================================
-- FAVORITE KEY
--==================================================

local function getItemKey(tool)

	local potatoId =
		tool:GetAttribute(
			"PotatoId"
		)

	if potatoId ~= nil then

		return "Potato_"
			.. tostring(potatoId)

	end

	local hoeId =
		tool:GetAttribute(
			"HoeId"
		)

	if hoeId ~= nil then

		return "Hoe_"
			.. tostring(hoeId)

	end

	local crateType =
		tool:GetAttribute(
			"CrateType"
		)

	if crateType ~= nil then

		return "Crate_"
			.. tostring(crateType)

	end

	local itemId =
		tool:GetAttribute(
			"ItemId"
		)

	if itemId ~= nil then

		return "Item_"
			.. tostring(itemId)

	end

	return "Item_"
		.. tool.Name

end

--==================================================
-- FIND REAL TOOL
--==================================================

local function findRealPotato(
	potatoId
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

					if tostring(
						object:GetAttribute(
							"PotatoId"
						)
					)
					==
					tostring(potatoId) then

						return object

					end

				end

			end

		end

	end

	return nil

end

local function findRealHoe(
	hoeId
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

					if tostring(
						object:GetAttribute(
							"HoeId"
						)
					)
					==
					tostring(hoeId) then

						return object

					end

				end

			end

		end

	end

	return nil

end

local function findRealCrate(
	crateType
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

					if tostring(
						objectType
					)
					==
					tostring(
						crateType
					) then

						return object

					end

				end

			end

		end

	end

	return nil

end

--==================================================
-- RESOLVE REAL TOOL
--==================================================

local function resolveRealTool(
	tool
)

	if not tool then
		return nil
	end

	local potatoId =
		tool:GetAttribute(
			"PotatoId"
		)

	if potatoId ~= nil then

		return findRealPotato(
			potatoId
		)

	end

	local hoeId =
		tool:GetAttribute(
			"HoeId"
		)

	if hoeId ~= nil then

		return findRealHoe(
			hoeId
		)

	end

	local crateType =
		tool:GetAttribute(
			"CrateType"
		)

	if crateType ~= nil then

		return findRealCrate(
			crateType
		)

	end

	-- Already a real Tool

	if tool:GetAttribute(
		"InventoryMirror"
	) ~= true then

		return tool

	end

	return nil

end

--==================================================
-- SYNC POTATO SNAPSHOT
--==================================================

local function syncPotatoes()

	for _, child in ipairs(
		potatoMirror:GetChildren()
	) do

		child:Destroy()

	end

	if not getPotatoSnapshot then

		warn(
			"[Inventory] GetPotatoSnapshot not found"
		)

		return

	end

	local success, records =
		pcall(function()

			return getPotatoSnapshot:InvokeServer()

		end)

	if not success then

		warn(
			"[Inventory] Potato snapshot failed:",
			records
		)

		return

	end

	if type(records) ~= "table" then
		return
	end

	for _, record in ipairs(
		records
	) do

		if type(record) == "table"
			and record.Id ~= nil then

			local tool =
				Instance.new("Tool")

			local potatoType =
				tostring(
					record.PotatoType
					or
					"Normal"
				)

			potatoType =
				potatoType:gsub(
					"%s+Potato$",
					""
				)

			local displayName =
				potatoType
				.. " Potato"

			tool.Name =
				displayName

			tool.RequiresHandle =
				false

			tool.CanBeDropped =
				false

			tool:SetAttribute(
				"InventoryMirror",
				true
			)

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

			-- Future KG support

			if record.Weight ~= nil then

				tool:SetAttribute(
					"Weight",
					tonumber(
						record.Weight
					)
				)

			elseif record.KG ~= nil then

				tool:SetAttribute(
					"Weight",
					tonumber(
						record.KG
					)
				)

			end

			-- Future powerups

			if record.Powerups ~= nil then

				tool:SetAttribute(
					"Powerups",
					tostring(
						record.Powerups
					)
				)

			end

			-- Existing data

			if record.Rarity ~= nil then

				tool:SetAttribute(
					"Rarity",
					record.Rarity
				)

			end

			if record.Mutation ~= nil then

				tool:SetAttribute(
					"Mutation",
					record.Mutation
				)

			end

			local key =
				"Potato_"
				.. tostring(record.Id)

			if record.Favorite == true then

				favorites[key] = true

			end

			tool.Parent =
				potatoMirror

		end

	end

end

--==================================================
-- SYNC EQUIPMENT SNAPSHOT
--==================================================

local function syncEquipment()

	for _, child in ipairs(
		equipmentMirror:GetChildren()
	) do

		child:Destroy()

	end

	if not getEquipmentSnapshot then

		warn(
			"[Inventory] GetEquipmentSnapshot not found"
		)

		return

	end

	local success, snapshot =
		pcall(function()

			return getEquipmentSnapshot:InvokeServer()

		end)

	if not success then

		warn(
			"[Inventory] Equipment snapshot failed:",
			snapshot
		)

		return

	end

	if type(snapshot) ~= "table" then
		return
	end

	--==================================================
	-- CRATES
	--==================================================

	local crates =
		type(snapshot.Crates)
		== "table"
		and snapshot.Crates
		or {}

	local woodenCount =
		math.max(
			0,
			math.floor(
				tonumber(
					crates.Wooden
				)
				or 0
			)
		)

	if woodenCount > 0 then

		local tool =
			Instance.new("Tool")

		if woodenCount > 1 then

			tool.Name =
				"Wooden Crate x"
				.. tostring(
					woodenCount
				)

		else

			tool.Name =
				"Wooden Crate"

		end

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
			equipmentMirror

	end

	--==================================================
	-- HOES
	--==================================================

	local hoes =
		type(snapshot.HoeInventory)
		== "table"
		and snapshot.HoeInventory
		or {}

	for _, record in ipairs(
		hoes
	) do

		if type(record) == "table"
			and record.Id ~= nil then

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
				.. " Hoe"

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

			if record.Durability ~= nil then

				tool:SetAttribute(
					"Durability",
					tonumber(
						record.Durability
					)
				)

			end

			if record.MaxDurability ~= nil then

				tool:SetAttribute(
					"MaxDurability",
					tonumber(
						record.MaxDurability
					)
				)

			end

			local key =
				"Hoe_"
				.. tostring(record.Id)

			if record.Favorite == true then

				favorites[key] = true

			end

			tool.Parent =
				equipmentMirror

		end

	end

end

--==================================================
-- GET INVENTORY
--==================================================

local function getAllItems()

	local result = {}

	local seen =
		{}

	local seenPotatoes =
		{}

	local seenHoes =
		{}

	local function add(
		tool
	)

		if not tool
			or not tool:IsA("Tool") then

			return

		end

		if seen[tool] then
			return
		end

		-- Don't duplicate a potato if
		-- both the real Tool and mirror exist.

		local potatoId =
			tool:GetAttribute(
				"PotatoId"
			)

		if potatoId ~= nil then

			local key =
				tostring(potatoId)

			if seenPotatoes[key] then
				return
			end

			seenPotatoes[key] = true

		end

		local hoeId =
			tool:GetAttribute(
				"HoeId"
			)

		if hoeId ~= nil then

			local key =
				tostring(hoeId)

			if seenHoes[key] then
				return
			end

			seenHoes[key] = true

		end

		seen[tool] = true

		table.insert(
			result,
			tool
		)

	end

	--==================================================
	-- REAL TOOLS
	--==================================================

	for _, object in ipairs(
		backpack:GetDescendants()
	) do

		if object:IsA("Tool") then

			add(object)

		end

	end

	if player.Character then

		for _, object in ipairs(
			player.Character:GetDescendants()
		) do

			if object:IsA("Tool") then

				add(object)

			end

		end

	end

	--==================================================
	-- SNAPSHOT MIRRORS
	--==================================================

	for _, object in ipairs(
		potatoMirror:GetChildren()
	) do

		add(object)

	end

	for _, object in ipairs(
		equipmentMirror:GetChildren()
	) do

		add(object)

	end

	return result

end

--==================================================
-- REFRESH DECLARATION
--==================================================

local refresh

--==================================================
-- CARD
--==================================================

local function createCard(
	tool
)

	local category =
		getCategory(tool)

	-- CATEGORY

	if selectedCategory
		~= CATEGORY_ALL
		and category
		~= selectedCategory then

		return false

	end

	-- SEARCH

	local displayName =
		getDisplayName(tool)

	if searchText ~= "" then

		if not string.find(
			string.lower(
				displayName
			),
			string.lower(
				searchText
			),
			1,
			true
		) then

			return false

		end

	end

	-- FAVORITE

	local key =
		getItemKey(tool)

	local isFavorite =
		favorites[key] == true

	if favoritesOnly
		and not isFavorite then

		return false

	end

	--==================================================
	-- CARD
	--==================================================

	local card =
		Instance.new("Frame")

	card.Size =
		UDim2.fromOffset(
			150,
			175
		)

	card.BackgroundColor3 =
		COLORS.Card

	card.BorderSizePixel =
		0

	card.Parent =
		scroll

	addCorner(
		card,
		10
	)

	--==================================================
	-- ICON
	--==================================================

	local icon =
		Instance.new("TextLabel")

	icon.BackgroundTransparency =
		1

	icon.Position =
		UDim2.fromOffset(
			10,
			10
		)

	icon.Size =
		UDim2.new(
			1,
			-20,
			0,
			75
		)

	icon.TextSize =
		45

	icon.Font =
		Enum.Font.GothamBold

	icon.TextColor3 =
		COLORS.Text

	if category
		== CATEGORY_POTATOES then

		icon.Text =
			"🥔"

	elseif category
		== CATEGORY_HOES then

		icon.Text =
			"⛏"

	elseif category
		== CATEGORY_CRATES then

		icon.Text =
			"📦"

	else

		icon.Text =
			"◆"

	end

	icon.Parent =
		card

	--==================================================
	-- HEART
	--==================================================

	local heart =
		Instance.new("TextButton")

	heart.Size =
		UDim2.fromOffset(
			32,
			32
		)

	heart.Position =
		UDim2.new(
			1,
			-38,
			0,
			6
		)

	heart.BackgroundTransparency =
		1

	heart.Text =
		isFavorite
		and "♥"
		or "♡"

	heart.TextColor3 =
		isFavorite
		and COLORS.Heart
		or COLORS.HeartOff

	heart.TextSize =
		22

	heart.Font =
		Enum.Font.GothamBold

	heart.ZIndex =
		10

	heart.Parent =
		card

	heart.MouseButton1Click:Connect(
		function()

			local newValue =
				not (
					favorites[key]
					== true
				)

			favorites[key] =
				newValue

			if setFavorite then

				setFavorite:FireServer(
					key,
					newValue
				)

			end

			heart.Text =
				newValue
				and "♥"
				or "♡"

			heart.TextColor3 =
				newValue
				and COLORS.Heart
				or COLORS.HeartOff

			if favoritesOnly then

				task.defer(
					refresh
				)

			end

		end
	)

	--==================================================
	-- NAME
	--==================================================

	local nameLabel =
		Instance.new("TextLabel")

	nameLabel.BackgroundTransparency =
		1

	nameLabel.Position =
		UDim2.fromOffset(
			10,
			90
		)

	nameLabel.Size =
		UDim2.new(
			1,
			-20,
			0,
			25
		)

	nameLabel.Text =
		displayName

	nameLabel.TextColor3 =
		COLORS.Text

	nameLabel.TextSize =
		14

	nameLabel.Font =
		Enum.Font.GothamBold

	nameLabel.TextTruncate =
		Enum.TextTruncate.AtEnd

	nameLabel.Parent =
		card

	--==================================================
	-- DETAILS
	--==================================================

	local details =
		Instance.new("TextLabel")

	details.BackgroundTransparency =
		1

	details.Position =
		UDim2.fromOffset(
			10,
			118
		)

	details.Size =
		UDim2.new(
			1,
			-20,
			0,
			45
		)

	details.TextColor3 =
		COLORS.SubText

	details.TextSize =
		11

	details.Font =
		Enum.Font.Gotham

	details.TextWrapped =
		true

	details.TextXAlignment =
		Enum.TextXAlignment.Left

	details.TextYAlignment =
		Enum.TextYAlignment.Top

	local detailText = ""

	--==================================================
	-- POTATO DETAILS
	--==================================================

	if category
		== CATEGORY_POTATOES then

		local weight =
			tool:GetAttribute(
				"Weight"
			)

		local powerups =
			tool:GetAttribute(
				"Powerups"
			)

		if weight ~= nil then

			detailText =
				string.format(
					"%.2f KG",
					tonumber(weight)
					or 0
				)

		end

		if powerups
			and tostring(powerups)
				~= "" then

			if detailText
				~= "" then

				detailText =
					detailText
					.. "\n"

			end

			detailText =
				detailText
				.. "✦ "
				.. tostring(powerups)

		end

	end

	--==================================================
	-- HOE DETAILS
	--==================================================

	if category
		== CATEGORY_HOES then

		local durability =
			tool:GetAttribute(
				"Durability"
			)

		local maxDurability =
			tool:GetAttribute(
				"MaxDurability"
			)

		if durability ~= nil
			and maxDurability ~= nil then

			detailText =
				string.format(
					"Durability: %d / %d",
					tonumber(
						durability
					) or 0,
					tonumber(
						maxDurability
					) or 0
				)

		end

	end

	--==================================================
	-- CRATE DETAILS
	--==================================================

	if category
		== CATEGORY_CRATES then

		local count =
			tool:GetAttribute(
				"CrateCount"
			)

		if count then

			detailText =
				"x"
				.. tostring(count)

		end

	end

	details.Text =
		detailText

	details.Parent =
		card

	--==================================================
	-- CARD CLICK
	--==================================================

	local clickButton =
		Instance.new("TextButton")

	clickButton.BackgroundTransparency =
		1

	clickButton.Size =
		UDim2.fromScale(
			1,
			1
		)

	clickButton.Text =
		""

	clickButton.ZIndex =
		1

	clickButton.Parent =
		card

	icon.ZIndex =
		2

	nameLabel.ZIndex =
		2

	details.ZIndex =
		2

	clickButton.MouseButton1Click:Connect(
		function()

			local realTool =
				resolveRealTool(
					tool
				)

			if not realTool then

				-- Saved item exists but
				-- its physical Tool hasn't
				-- replicated yet.

				warn(
					"[Inventory] Physical Tool not available yet:",
					tool.Name
				)

				return

			end

			local character =
				player.Character

			if not character then
				return
			end

			local humanoid =
				character:FindFirstChildOfClass(
					"Humanoid"
				)

			if not humanoid then
				return
			end

			if realTool.Parent
				== character then

				humanoid:UnequipTools()

			else

				humanoid:EquipTool(
					realTool
				)

			end

		end
	)

	--==================================================
	-- HOVER
	--==================================================

	card.MouseEnter:Connect(
		function()

			card.BackgroundColor3 =
				COLORS.CardHover

		end
	)

	card.MouseLeave:Connect(
		function()

			card.BackgroundColor3 =
				COLORS.Card

		end
	)

	return true

end

--==================================================
-- REFRESH
--==================================================

refresh = function()

	-- VERY IMPORTANT:
	-- Get latest saved inventory before building cards.

	syncPotatoes()

	syncEquipment()

	-- Clear cards

	for _, child in ipairs(
		scroll:GetChildren()
	) do

		if child:IsA("Frame") then

			child:Destroy()

		end

	end

	local count = 0

	for _, tool in ipairs(
		getAllItems()
	) do

		if createCard(tool) then

			count += 1

		end

	end

	-- TITLE

	if favoritesOnly then

		categoryTitle.Text =
			"FAVORITES"

	else

		categoryTitle.Text =
			string.upper(
				selectedCategory
			)

	end

	itemCount.Text =
		tostring(count)
		.. (
			count == 1
			and " item"
			or " items"
		)

	-- FAVORITE FILTER

	if favoritesOnly then

		favoriteButton.TextColor3 =
			COLORS.Heart

		favoriteButton.BackgroundColor3 =
			Color3.fromRGB(
				55,
				35,
				40
			)

	else

		favoriteButton.TextColor3 =
			COLORS.HeartOff

		favoriteButton.BackgroundColor3 =
			COLORS.PanelLight

	end

end

--==================================================
-- CATEGORY BUTTONS
--==================================================

for index, data in ipairs(
	categories
) do

	local button =
		Instance.new("TextButton")

	button.Size =
		UDim2.new(
			1,
			-20,
			0,
			42
		)

	button.Position =
		UDim2.fromOffset(
			10,
			10
			+ (
				(index - 1)
				* 48
			)
		)

	button.BackgroundColor3 =
		COLORS.Panel

	button.BorderSizePixel =
		0

	button.Text =
		data.Text

	button.TextColor3 =
		COLORS.SubText

	button.TextSize =
		13

	button.Font =
		Enum.Font.GothamMedium

	button.TextXAlignment =
		Enum.TextXAlignment.Left

	button.Parent =
		sidebar

	addCorner(
		button,
		7
	)

	local padding =
		Instance.new(
			"UIPadding"
		)

	padding.PaddingLeft =
		UDim.new(
			0,
			12
		)

	padding.Parent =
		button

	button.MouseButton1Click:Connect(
		function()

			selectedCategory =
				data.Name

			favoritesOnly =
				false

			refresh()

		end
	)

end

--==================================================
-- FAVORITES FILTER
--==================================================

favoriteButton.MouseButton1Click:Connect(
	function()

		favoritesOnly =
			not favoritesOnly

		refresh()

	end
)

--==================================================
-- SEARCH
--==================================================

searchBox:GetPropertyChangedSignal(
	"Text"
):Connect(
	function()

		searchText =
			searchBox.Text

		refresh()

	end
)

--==================================================
-- CLOSE
--==================================================

closeButton.MouseButton1Click:Connect(
	function()

		main.Visible =
			false

	end
)

--==================================================
-- B TOGGLE
--==================================================

UserInputService.InputBegan:Connect(
	function(
		input,
		processed
	)

		if processed then
			return
		end

		if input.KeyCode
			== OPEN_KEY then

			main.Visible =
				not main.Visible

			if main.Visible then

				refresh()

			end

		end

	end
)

--==================================================
-- BACKPACK CHANGES
--==================================================

backpack.ChildAdded:Connect(
	function()

		if main.Visible then

			task.delay(
				0.15,
				refresh
			)

		end

	end
)

backpack.ChildRemoved:Connect(
	function()

		if main.Visible then

			task.delay(
				0.15,
				refresh
			)

		end

	end
)

--==================================================
-- CHARACTER
--==================================================

player.CharacterAdded:Connect(
	function(character)

		character.ChildAdded:Connect(
			function()

				if main.Visible then

					task.delay(
						0.15,
						refresh
					)

				end

			end
		)

		character.ChildRemoved:Connect(
			function()

				if main.Visible then

					task.delay(
						0.15,
						refresh
					)

				end

			end
		)

	end
)

--==================================================
-- INITIAL
--==================================================

refresh()