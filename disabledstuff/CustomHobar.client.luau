--==================================================
-- POTATIUM CUSTOM HOTBAR
-- 8 FIXED SLOTS
--
-- 1 = Hoe
-- 2-3 = Items / Bits / Crates
-- 4-8 = Potatoes
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local backpack = player:WaitForChild("Backpack")

local SLOT_COUNT = 8

local HOE_SLOT = 1

local ITEM_START_SLOT = 2
local ITEM_END_SLOT = 3

local POTATO_START_SLOT = 4
local POTATO_END_SLOT = 8

--==================================================
-- HIDE ROBLOX DEFAULT HOTBAR
--==================================================

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

--==================================================
-- HOTBAR DATA
--==================================================

-- IMPORTANT:
-- We store a KEY, not the Tool instance.
-- This means the Tool can move between Backpack
-- and Character without breaking the slot.

local hotbarSlots = table.create(SLOT_COUNT)

local selectedSlot = nil

--==================================================
-- TOOL TYPE
--==================================================

local function getToolType(tool)
	if not tool or not tool:IsA("Tool") then
		return nil
	end

	-- HOE
	if tool:GetAttribute("FarmingToolType") == "Hoe" then
		return "Hoe"
	end

	if tool:GetAttribute("HoeId") ~= nil then
		return "Hoe"
	end

	-- POTATO
	if tool:GetAttribute("PotatoId") ~= nil then
		return "Potato"
	end

	if tool:GetAttribute("PotatoInventoryTool") == true then
		return "Potato"
	end

	if tool:GetAttribute("PotatoType") ~= nil then
		return "Potato"
	end

	-- FALLBACK NAME CHECK
	local lowerName = string.lower(tool.Name)

	if string.find(lowerName, "potato") then
		return "Potato"
	end

	if string.find(lowerName, "hoe") then
		return "Hoe"
	end

	-- EVERYTHING ELSE
	return "Item"
end

--==================================================
-- GET STABLE TOOL KEY
--==================================================

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

	local itemId = tool:GetAttribute("ItemId")

	if itemId ~= nil then
		return "Item_" .. tostring(itemId)
	end

	-- fallback
	return "Tool_" .. tool.Name
end

--==================================================
-- FIND REAL TOOL
--==================================================

local function findRealTool(key)
	if not key then
		return nil
	end

	local character = player.Character

	-- Backpack
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			if tool:GetAttribute("InventoryMirror") ~= true then
				if getToolKey(tool) == key then
					return tool
				end
			end
		end
	end

	-- Character
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") then
				if tool:GetAttribute("InventoryMirror") ~= true then
					if getToolKey(tool) == key then
						return tool
					end
				end
			end
		end
	end

	return nil
end

--==================================================
-- CHECK IF TOOL CAN GO IN SLOT
--==================================================

local function canUseSlot(slot, tool)
	local toolType = getToolType(tool)

	if slot == HOE_SLOT then
		return toolType == "Hoe"
	end

	if slot >= ITEM_START_SLOT and slot <= ITEM_END_SLOT then
		return toolType == "Item"
	end

	if slot >= POTATO_START_SLOT and slot <= POTATO_END_SLOT then
		return toolType == "Potato"
	end

	return false
end

--==================================================
-- CHECK IF KEY ALREADY EXISTS
--==================================================

local function isAlreadyAssigned(key)
	for slot = 1, SLOT_COUNT do
		if hotbarSlots[slot] == key then
			return true
		end
	end

	return false
end

--==================================================
-- ADD NEW TOOLS
--==================================================

local function addMissingTools()
	local tools = {}

	-- Backpack
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("InventoryMirror") ~= true then
			table.insert(tools, tool)
		end
	end

	-- Character
	local character = player.Character

	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("InventoryMirror") ~= true then
				table.insert(tools, tool)
			end
		end
	end

	for _, tool in ipairs(tools) do
		local key = getToolKey(tool)

		if key and not isAlreadyAssigned(key) then
			local toolType = getToolType(tool)

			-- HOE
			if toolType == "Hoe" then
				if not hotbarSlots[HOE_SLOT] then
					hotbarSlots[HOE_SLOT] = key
				end

			-- ITEM
			elseif toolType == "Item" then
				for slot = ITEM_START_SLOT, ITEM_END_SLOT do
					if not hotbarSlots[slot] then
						hotbarSlots[slot] = key
						break
					end
				end

			-- POTATO
			elseif toolType == "Potato" then
				for slot = POTATO_START_SLOT, POTATO_END_SLOT do
					if not hotbarSlots[slot] then
						hotbarSlots[slot] = key
						break
					end
				end
			end
		end
	end
end

--==================================================
-- GUI
--==================================================

local oldGui = playerGui:FindFirstChild("PotatiumCustomHotbar")

if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")

gui.Name = "PotatiumCustomHotbar"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100

gui.Parent = playerGui

--==================================================
-- HOTBAR FRAME
--==================================================

local hotbar = Instance.new("Frame")

hotbar.Name = "Hotbar"

hotbar.AnchorPoint = Vector2.new(0.5, 1)

hotbar.Position = UDim2.new(0.5, 0, 1, -30)

hotbar.Size = UDim2.fromOffset(470, 66)

hotbar.BackgroundTransparency = 1

hotbar.Parent = gui

local layout = Instance.new("UIListLayout")

layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 5)

layout.Parent = hotbar

--==================================================
-- SLOT BUTTONS
--==================================================

local slotButtons = {}

for slot = 1, SLOT_COUNT do
	local button = Instance.new("TextButton")

	button.Name = "Slot" .. slot

	button.Size = UDim2.fromOffset(54, 58)

	button.BackgroundColor3 = Color3.fromRGB(20, 22, 27)

	button.BackgroundTransparency = 0.1

	button.BorderSizePixel = 0

	button.Text = ""

	button.AutoButtonColor = false

	button.Parent = hotbar

	local corner = Instance.new("UICorner")

	corner.CornerRadius = UDim.new(0, 7)

	corner.Parent = button

	local stroke = Instance.new("UIStroke")

	stroke.Name = "Border"

	stroke.Color = Color3.fromRGB(70, 75, 85)

	stroke.Thickness = 1

	stroke.Parent = button

	-- NUMBER

	local number = Instance.new("TextLabel")

	number.BackgroundTransparency = 1

	number.Position = UDim2.fromOffset(5, 3)

	number.Size = UDim2.fromOffset(18, 15)

	number.Text = tostring(slot)

	number.TextColor3 = Color3.fromRGB(170, 175, 185)

	number.TextSize = 11

	number.Font = Enum.Font.GothamBold

	number.TextXAlignment = Enum.TextXAlignment.Left

	number.Parent = button

	-- ICON

	local icon = Instance.new("TextLabel")

	icon.Name = "Icon"

	icon.BackgroundTransparency = 1

	icon.AnchorPoint = Vector2.new(0.5, 0.5)

	icon.Position = UDim2.new(0.5, 0, 0.48, 0)

	icon.Size = UDim2.fromOffset(38, 32)

	icon.Text = ""

	icon.TextSize = 25

	icon.Font = Enum.Font.Gotham

	icon.Parent = button

	-- NAME

	local nameLabel = Instance.new("TextLabel")

	nameLabel.Name = "Name"

	nameLabel.BackgroundTransparency = 1

	nameLabel.AnchorPoint = Vector2.new(0.5, 1)

	nameLabel.Position = UDim2.new(0.5, 0, 1, -3)

	nameLabel.Size = UDim2.fromOffset(48, 15)

	nameLabel.Text = ""

	nameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)

	nameLabel.TextSize = 9

	nameLabel.Font = Enum.Font.GothamMedium

	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

	nameLabel.Parent = button

	slotButtons[slot] = button

	-- CLICK

	button.MouseButton1Click:Connect(function()
		local key = hotbarSlots[slot]

		if not key then
			return
		end

		local tool = findRealTool(key)

		if not tool then
			warn("[Hotbar] Real Tool not found:", key)

			return
		end

		local character = player.Character

		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if not humanoid then
			return
		end

		-- Already equipped
		if tool.Parent == character then
			humanoid:UnequipTools()

			selectedSlot = nil
		else
			humanoid:EquipTool(tool)

			selectedSlot = slot
		end

		-- update UI
		for i = 1, SLOT_COUNT do
			local otherButton = slotButtons[i]

			local otherStroke = otherButton:FindFirstChild("Border")

			if i == selectedSlot then
				otherButton.BackgroundColor3 = Color3.fromRGB(48, 55, 66)

				otherStroke.Color = Color3.fromRGB(235, 235, 235)

				otherStroke.Thickness = 2
			else
				otherButton.BackgroundColor3 = Color3.fromRGB(20, 22, 27)

				otherStroke.Color = Color3.fromRGB(70, 75, 85)

				otherStroke.Thickness = 1
			end
		end
	end)
end

--==================================================
-- UPDATE UI
--==================================================

local function refreshHotbar()
	for slot = 1, SLOT_COUNT do
		local button = slotButtons[slot]

		local icon = button:FindFirstChild("Icon")

		local nameLabel = button:FindFirstChild("Name")

		local key = hotbarSlots[slot]

		if key then
			local tool = findRealTool(key)

			if tool then
				local toolType = getToolType(tool)

				-- ICON

				if toolType == "Potato" then
					icon.Text = "🥔"
				elseif toolType == "Hoe" then
					icon.Text = "⛏"
				elseif toolType == "Item" then
					icon.Text = "📦"
				end

				-- NAME

				nameLabel.Text = tool.Name

				button.BackgroundColor3 = Color3.fromRGB(28, 31, 37)
			else
				icon.Text = ""
				nameLabel.Text = ""
			end
		else
			icon.Text = ""
			nameLabel.Text = ""

			button.BackgroundColor3 = Color3.fromRGB(20, 22, 27)
		end
	end
end

--==================================================
-- KEYBOARD 1-8
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

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	local slot = keyToSlot[input.KeyCode]

	if not slot then
		return
	end

	local key = hotbarSlots[slot]

	if not key then
		return
	end

	local tool = findRealTool(key)

	if not tool then
		warn("[Hotbar] Tool not found:", key)

		return
	end

	local character = player.Character

	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	if tool.Parent == character then
		humanoid:UnequipTools()

		selectedSlot = nil
	else
		humanoid:EquipTool(tool)

		selectedSlot = slot
	end

	refreshHotbar()
end)

--==================================================
-- WATCH TOOLS
--==================================================

local function refresh()
	addMissingTools()

	refreshHotbar()
end

backpack.ChildAdded:Connect(function()
	task.wait()

	refresh()
end)

backpack.ChildRemoved:Connect(function()
	task.wait()

	refresh()
end)

player.CharacterAdded:Connect(function(character)
	character.ChildAdded:Connect(function()
		task.wait()

		refresh()
	end)

	character.ChildRemoved:Connect(function()
		task.wait()

		refresh()
	end)

	task.wait(1)

	refresh()
end)

--==================================================
-- INITIAL
--==================================================

task.wait(1)

refresh()

print("✅ Potatium Custom Hotbar loaded")
