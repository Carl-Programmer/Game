--==================================================
-- POTATIUM CUSTOM HOTBAR V1
--
-- Uses the SAME real Roblox Tools created by the
-- server inventory/equipment services.
--
-- Slots:
--   1-8
--
-- The hotbar does NOT create fake tools and does NOT
-- create a second inventory.
--
-- It only remembers stable item keys and equips the
-- matching real Tool from Backpack/Character.
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")

local SLOT_COUNT = 8

--==================================================
-- HIDE ROBLOX DEFAULT HOTBAR
--==================================================

pcall(function()
	StarterGui:SetCoreGuiEnabled(
		Enum.CoreGuiType.Backpack,
		false
	)
end)

--==================================================
-- COLORS
--==================================================

local COLORS = {
	Background = Color3.fromRGB(18, 24, 34),
	Slot = Color3.fromRGB(31, 39, 53),
	SlotHover = Color3.fromRGB(43, 53, 70),
	Selected = Color3.fromRGB(67, 139, 255),
	SelectedBorder = Color3.fromRGB(145, 194, 255),
	Text = Color3.fromRGB(245, 248, 252),
	SubText = Color3.fromRGB(170, 184, 202),
	Empty = Color3.fromRGB(25, 31, 42),
}

--==================================================
-- HOTBAR STATE
--==================================================

-- Each slot stores a stable key, NOT a Tool instance.
--
-- Example:
--   Potato_123
--   Hoe_H1
--   Crate_Wooden
--   Item_PotatoBits
--
-- This is important because the server may destroy
-- and recreate a Tool when inventory data changes.
--==================================================

local hotbarSlots = table.create(SLOT_COUNT)
local selectedSlot = nil

local gui
local bar
local slotButtons = {}

--==================================================
-- TOOL HELPERS
--==================================================

local function getToolType(tool)
	if not tool or not tool:IsA("Tool") then
		return nil
	end

	if tool:GetAttribute("PotatoInventoryTool") == true then
		return "Potato"
	end

	if tool:GetAttribute("FarmingToolType") == "Hoe"
		or tool:GetAttribute("HoeId") ~= nil
	then
		return "Hoe"
	end

	if tool:GetAttribute("PotatoBitTool") == true
		or tool:GetAttribute("FarmingToolType") == "PotatoBits"
	then
		return "Item"
	end

	if tool:GetAttribute("CrateTool") == true
		or tool:GetAttribute("CrateType") ~= nil
	then
		return "Crate"
	end

	return "Item"
end

local function getToolKey(tool)
	if not tool or not tool:IsA("Tool") then
		return nil
	end

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

	if tool:GetAttribute("PotatoBitTool") == true then
		return "Item_PotatoBits"
	end

	local itemId = tool:GetAttribute("ItemId")
	if itemId ~= nil then
		return "Item_" .. tostring(itemId)
	end

	return "Item_" .. tool.Name
end

local function isUsableTool(tool)
	if not tool or not tool:IsA("Tool") then
		return false
	end

	-- Ignore any future mirror/display tools.
	if tool:GetAttribute("InventoryMirror") == true then
		return false
	end

	return getToolKey(tool) ~= nil
end

--==================================================
-- FIND REAL TOOL
--==================================================

local function getContainers()
	local containers = {}

	local currentBackpack =
		player:FindFirstChild("Backpack")

	if currentBackpack then
		table.insert(containers, currentBackpack)
	end

	local character = player.Character

	if character then
		table.insert(containers, character)
	end

	return containers
end

local function findRealTool(key)
	if not key then
		return nil
	end

	for _, container in ipairs(getContainers()) do
		for _, object in ipairs(container:GetChildren()) do
			if
				object:IsA("Tool")
				and object:GetAttribute("InventoryMirror") ~= true
				and getToolKey(object) == key
			then
				return object
			end
		end
	end

	return nil
end

local function collectTools()
	local result = {}
	local seen = {}

	for _, container in ipairs(getContainers()) do
		for _, object in ipairs(container:GetChildren()) do
			if isUsableTool(object) then
				local key = getToolKey(object)

				if key and not seen[key] then
					seen[key] = true

					table.insert(result, {
						Tool = object,
						Key = key,
						Type = getToolType(object),
					})
				end
			end
		end
	end

	return result
end

--==================================================
-- SLOT ORDER
--
-- Keep useful tools toward the left:
--
-- 1. Hoe
-- 2. Potato Bits
-- 3. Crates
-- 4. Other items
-- 5. Potatoes
--==================================================

local function getTypePriority(toolType)
	if toolType == "Hoe" then
		return 1
	end

	if toolType == "Item" then
		return 2
	end

	if toolType == "Crate" then
		return 3
	end

	if toolType == "Potato" then
		return 4
	end

	return 5
end

--==================================================
-- CHECK WHETHER KEY IS ALREADY IN A SLOT
--==================================================

local function isAssigned(key)
	if not key then
		return false
	end

	for slot = 1, SLOT_COUNT do
		if hotbarSlots[slot] == key then
			return true
		end
	end

	return false
end

--==================================================
-- CLEAN INVALID SLOTS
--==================================================

local function cleanSlots()
	for slot = 1, SLOT_COUNT do
		local key = hotbarSlots[slot]

		if key and not findRealTool(key) then
			-- Leave the key temporarily if the Tool may
			-- be recreated by the server.
			--
			-- We do not immediately erase it. This lets
			-- a recreated potato/hoe return to the same
			-- hotbar slot.
		end
	end
end

--==================================================
-- ADD NEW TOOLS
--==================================================

local function addMissingTools(tools)
	-- First keep every existing assignment.
	for _, entry in ipairs(tools) do
		if isAssigned(entry.Key) then
			continue
		end
	end

	-- Sort new tools into a predictable order.
	table.sort(
		tools,
		function(a, b)
			local priorityA = getTypePriority(a.Type)
			local priorityB = getTypePriority(b.Type)

			if priorityA ~= priorityB then
				return priorityA < priorityB
			end

			return a.Key < b.Key
		end
	)

	for _, entry in ipairs(tools) do
		if isAssigned(entry.Key) then
			continue
		end

		for slot = 1, SLOT_COUNT do
			if hotbarSlots[slot] == nil then
				hotbarSlots[slot] = entry.Key
				break
			end
		end
	end
end

--==================================================
-- DISPLAY
--==================================================

local function getToolIcon(tool)
	local toolType = getToolType(tool)

	if toolType == "Potato" then
		return "🥔"
	end

	if toolType == "Hoe" then
		return "⛏"
	end

	if toolType == "Crate" then
		return "📦"
	end

	if tool:GetAttribute("PotatoBitTool") == true then
		return "🌱"
	end

	return "◆"
end

local function getToolDisplayName(tool)
	if not tool then
		return ""
	end

	local displayName =
		tool:GetAttribute("DisplayName")

	if displayName ~= nil then
		return tostring(displayName)
	end

	return tool.Name
end

local function updateSlot(slot)
	local button = slotButtons[slot]

	if not button then
		return
	end

	local key = hotbarSlots[slot]
	local tool = key and findRealTool(key)

	local icon =
		button:FindFirstChild("Icon")

	local nameLabel =
		button:FindFirstChild("Name")

	local numberLabel =
		button:FindFirstChild("Number")

	if numberLabel then
		numberLabel.Text = tostring(slot)
	end

	if not tool then
		button.BackgroundColor3 = COLORS.Empty

		if icon then
			icon.Text = ""
		end

		if nameLabel then
			nameLabel.Text = ""
		end
	else
		button.BackgroundColor3 =
			selectedSlot == slot
			and COLORS.Selected
			or COLORS.Slot

		if icon then
			icon.Text = getToolIcon(tool)
		end

		if nameLabel then
			nameLabel.Text =
				getToolDisplayName(tool)
		end
	end

	local stroke =
		button:FindFirstChild("Stroke")

	if stroke then
		stroke.Color =
			selectedSlot == slot
			and COLORS.SelectedBorder
			or Color3.fromRGB(65, 76, 94)

		stroke.Thickness =
			selectedSlot == slot
			and 2
			or 1
	end
end

local function refreshUI()
	for slot = 1, SLOT_COUNT do
		updateSlot(slot)
	end
end

--==================================================
-- EQUIP / UNEQUIP
--==================================================

local function useSlot(slot)
	local key = hotbarSlots[slot]

	if not key then
		return
	end

	local tool = findRealTool(key)

	if not tool then
		refreshUI()
		return
	end

	local character = player.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	-- Clicking the currently equipped slot toggles it off.
	if tool.Parent == character then
		humanoid:UnequipTools()
		selectedSlot = nil
	else
		humanoid:EquipTool(tool)
		selectedSlot = slot
	end

	refreshUI()
end

--==================================================
-- CREATE UI
--==================================================

local function createUI()
	local playerGui =
		player:WaitForChild("PlayerGui")

	local old =
		playerGui:FindFirstChild(
			"PotatiumCustomHotbar"
		)

	if old then
		old:Destroy()
	end

	gui =
		Instance.new("ScreenGui")

	gui.Name =
		"PotatiumCustomHotbar"

	gui.ResetOnSpawn =
		false

	gui.IgnoreGuiInset =
		true

	gui.DisplayOrder =
		50

	gui.ZIndexBehavior =
		Enum.ZIndexBehavior.Sibling

	gui.Parent =
		playerGui

	bar =
		Instance.new("Frame")

	bar.Name =
		"Hotbar"

	bar.AnchorPoint =
		Vector2.new(0.5, 1)

	bar.Position =
		UDim2.new(
			0.5,
			0,
			1,
			-18
		)

	bar.Size =
		UDim2.new(
			0,
			8 * 78 + 7 * 8 + 24,
			0,
			94
		)

	bar.BackgroundColor3 =
		COLORS.Background

	bar.BackgroundTransparency =
		0.08

	bar.BorderSizePixel =
		0

	bar.Parent =
		gui

	local barCorner =
		Instance.new("UICorner")

	barCorner.CornerRadius =
		UDim.new(
			0,
			14
		)

	barCorner.Parent =
		bar

	local barStroke =
		Instance.new("UIStroke")

	barStroke.Color =
		Color3.fromRGB(
			57,
			69,
			88
		)

	barStroke.Thickness =
		1.2

	barStroke.Transparency =
		0.1

	barStroke.Parent =
		bar

	local layout =
		Instance.new("UIListLayout")

	layout.FillDirection =
		Enum.FillDirection.Horizontal

	layout.HorizontalAlignment =
		Enum.HorizontalAlignment.Center

	layout.VerticalAlignment =
		Enum.VerticalAlignment.Center

	layout.Padding =
		UDim.new(
			0,
			8
		)

	layout.Parent =
		bar

	local padding =
		Instance.new("UIPadding")

	padding.PaddingLeft =
		UDim.new(
			0,
			12
		)

	padding.PaddingRight =
		UDim.new(
			0,
			12
		)

	padding.Parent =
		bar

	for slot = 1, SLOT_COUNT do
		local button =
			Instance.new("TextButton")

		button.Name =
			"Slot" .. tostring(slot)

		button.Size =
			UDim2.fromOffset(
				78,
				70
			)

		button.BackgroundColor3 =
			COLORS.Slot

		button.BorderSizePixel =
			0

		button.AutoButtonColor =
			false

		button.Text =
			""

		button.Parent =
			bar

		local corner =
			Instance.new("UICorner")

		corner.CornerRadius =
			UDim.new(
				0,
				10
			)

		corner.Parent =
			button

		local stroke =
			Instance.new("UIStroke")

		stroke.Name =
			"Stroke"

		stroke.Color =
			Color3.fromRGB(
				65,
				76,
				94
			)

		stroke.Thickness =
			1

		stroke.Parent =
			button

		local numberLabel =
			Instance.new("TextLabel")

		numberLabel.Name =
			"Number"

		numberLabel.Size =
			UDim2.fromOffset(
				20,
				20
			)

		numberLabel.Position =
			UDim2.fromOffset(
				5,
				4
			)

		numberLabel.BackgroundTransparency =
			1

		numberLabel.Text =
			tostring(slot)

		numberLabel.TextColor3 =
			COLORS.SubText

		numberLabel.Font =
			Enum.Font.GothamBold

		numberLabel.TextSize =
			11

		numberLabel.TextXAlignment =
			Enum.TextXAlignment.Left

		numberLabel.Parent =
			button

		local icon =
			Instance.new("TextLabel")

		icon.Name =
			"Icon"

		icon.Size =
			UDim2.fromOffset(
				42,
				38
			)

		icon.Position =
			UDim2.new(
				0.5,
				-21,
				0,
				14
			)

		icon.BackgroundTransparency =
			1

		icon.Text =
			""

		icon.TextColor3 =
			COLORS.Text

		icon.Font =
			Enum.Font.GothamBold

		icon.TextSize =
			28

		icon.Parent =
			button

		local nameLabel =
			Instance.new("TextLabel")

		nameLabel.Name =
			"Name"

		nameLabel.Size =
			UDim2.new(
				1,
				-8,
				0,
				16
			)

		nameLabel.Position =
			UDim2.fromOffset(
				4,
				50
			)

		nameLabel.BackgroundTransparency =
			1

		nameLabel.Text =
			""

		nameLabel.TextColor3 =
			COLORS.Text

		nameLabel.Font =
			Enum.Font.GothamSemibold

		nameLabel.TextSize =
			9

		nameLabel.TextTruncate =
			Enum.TextTruncate.AtEnd

		nameLabel.Parent =
			button

		button.MouseEnter:Connect(
			function()
				if selectedSlot ~= slot then
					button.BackgroundColor3 =
						COLORS.SlotHover
				end
			end
		)

		button.MouseLeave:Connect(
			function()
				updateSlot(slot)
			end
		)

		button.MouseButton1Click:Connect(
			function()
				useSlot(slot)
			end
		)

		slotButtons[slot] =
			button
	end
end

--==================================================
-- REFRESH HOTBAR DATA
--==================================================

local refreshQueued = false

local function refresh()
	if refreshQueued then
		return
	end

	refreshQueued = true

	task.defer(
		function()
			refreshQueued = false

			cleanSlots()

			local tools =
				collectTools()

			addMissingTools(tools)

			-- If the equipped Tool changed without a click,
			-- update the highlighted slot.
			local character =
				player.Character

			local equippedKey = nil

			if character then
				for _, object in ipairs(character:GetChildren()) do
					if isUsableTool(object) then
						equippedKey =
							getToolKey(object)
						break
					end
				end
			end

			if equippedKey then
				for slot = 1, SLOT_COUNT do
					if hotbarSlots[slot] == equippedKey then
						selectedSlot = slot
						break
					end
				end
			else
				selectedSlot = nil
			end

			refreshUI()
		end
	)
end

--==================================================
-- INPUT
--==================================================

local keyToSlot = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
}

UserInputService.InputBegan:Connect(
	function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if
			UserInputService:GetFocusedTextBox()
			then
			return
		end

		local slot =
			keyToSlot[
				input.KeyCode
			]

		if slot then
			useSlot(slot)
		end
	end
)

--==================================================
-- WATCH BACKPACK / CHARACTER
--==================================================

local function connectContainer(container)
	if not container then
		return
	end

	container.ChildAdded:Connect(
		function(object)
			if object:IsA("Tool") then
				refresh()
			end
		end
	)

	container.ChildRemoved:Connect(
		function(object)
			if object:IsA("Tool") then
				refresh()
			end
		end
	)
end

connectContainer(backpack)

local function connectCharacter(character)
	connectContainer(character)

	character.ChildAdded:Connect(
		function(object)
			if object:IsA("Tool") then
				refresh()
			end
		end
	)

	character.ChildRemoved:Connect(
		function(object)
			if object:IsA("Tool") then
				task.defer(refresh)
			end
		end
	)

	task.defer(refresh)
end

player.CharacterAdded:Connect(
	connectCharacter
)

if player.Character then
	connectCharacter(
		player.Character
	)
end

--==================================================
-- SERVER INVENTORY REVISIONS
--
-- These are already fired by the existing services.
-- We only use them to refresh the UI.
--==================================================

local function watchAttribute(attributeName)
	player:GetAttributeChangedSignal(
		attributeName
	):Connect(
		function()
			refresh()
		end
	)
end

watchAttribute("PotatoInventoryRevision")
watchAttribute("HoeInventoryRevision")
watchAttribute("CrateInventoryRevision")
watchAttribute("PotatoBits")

--==================================================
-- START
--==================================================

createUI()
refresh()

print("")
print("========================================")
print("🎒 POTATIUM CUSTOM HOTBAR V1")
print("========================================")
print("✅ Uses real Roblox Tools")
print("✅ 8 slots")
print("✅ Keyboard 1-8")
print("✅ Click to equip")
print("✅ Click equipped slot to unequip")
print("✅ Potato / Hoe / Crate / Item support")
print("✅ Stable item keys")
print("✅ Respawn synchronization")
print("✅ Backpack synchronization")
print("🚫 Roblox default hotbar disabled")
print("========================================")
