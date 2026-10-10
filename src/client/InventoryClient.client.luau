--==================================================
-- POTATIUM DRAGGABLE BACKPACK + HOTBAR
--
-- Client UI only. Uses the real server-created Roblox
-- Tools in Backpack/Character. Does not create or save
-- inventory items and does not change server services.
--
-- Controls:
--   B       Open/close backpack
--   1-8     Equip/unequip hotbar slot
--   Click   Equip an inventory item / use a hotbar slot
--   Drag    Inventory item -> hotbar slot to assign
--   Drag    Hotbar slot -> another slot to move/swap
--   Drag    Hotbar slot -> backpack panel to unassign
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local backpack = player:WaitForChild("Backpack")

local HOTBAR_COUNT = 8
local OPEN_KEY = Enum.KeyCode.B

local COLORS = {
	Background = Color3.fromRGB(16, 21, 30),
	Panel = Color3.fromRGB(24, 31, 43),
	Panel2 = Color3.fromRGB(31, 40, 54),
	Slot = Color3.fromRGB(35, 45, 61),
	SlotHover = Color3.fromRGB(48, 62, 82),
	Accent = Color3.fromRGB(80, 158, 255),
	AccentSoft = Color3.fromRGB(39, 76, 120),
	Text = Color3.fromRGB(244, 247, 252),
	Muted = Color3.fromRGB(163, 176, 195),
	Stroke = Color3.fromRGB(61, 76, 98),
	Empty = Color3.fromRGB(25, 32, 44),
	Red = Color3.fromRGB(255, 116, 116),
}

local slotKeys = table.create(HOTBAR_COUNT)
local slotButtons = {}
local itemButtons = {}
local currentTools = {}
local selectedCategory = "All"
local searchText = ""
local dragState = nil
local dragGhost = nil
local gui, inventoryPanel, itemGrid, itemScroll, searchBox, statusLabel, hotbarFrame

local function round(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = instance
	return corner
end

local function stroke(instance, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.Stroke
	s.Thickness = thickness or 1
	s.Parent = instance
	return s
end

local function getToolType(tool)
	if not tool or not tool:IsA("Tool") then return "Item" end
	if tool:GetAttribute("PotatoInventoryTool") == true then return "Potato" end
	if tool:GetAttribute("FarmingToolType") == "Hoe" or tool:GetAttribute("HoeId") ~= nil then return "Hoe" end
	if tool:GetAttribute("PotatoBitTool") == true or tool:GetAttribute("FarmingToolType") == "PotatoBits" then return "Seeds" end
	if tool:GetAttribute("CrateTool") == true or tool:GetAttribute("CrateType") ~= nil then return "Crate" end
	local name = string.lower(tool.Name)
	if string.find(name, "potato", 1, true) then return "Potato" end
	if string.find(name, "hoe", 1, true) then return "Hoe" end
	if string.find(name, "crate", 1, true) then return "Crate" end
	return "Item"
end

local function getToolKey(tool)
	if not tool or not tool:IsA("Tool") then return nil end
	local potatoId = tool:GetAttribute("PotatoId")
	if potatoId ~= nil then return "Potato_" .. tostring(potatoId) end
	local hoeId = tool:GetAttribute("HoeId")
	if hoeId ~= nil then return "Hoe_" .. tostring(hoeId) end
	local crateType = tool:GetAttribute("CrateType")
	if crateType ~= nil then return "Crate_" .. tostring(crateType) end
	if tool:GetAttribute("PotatoBitTool") == true then return "Item_PotatoBits" end
	local itemId = tool:GetAttribute("ItemId")
	if itemId ~= nil then return "Item_" .. tostring(itemId) end
	-- Permanent wooden hoe and other singleton tools have no ID.
	return "Tool_" .. tool.Name
end

local function getToolName(tool)
	local displayName = tool:GetAttribute("DisplayName")
	if displayName ~= nil then return tostring(displayName) end
	return tool.Name
end

local function getToolIcon(tool)
	local kind = getToolType(tool)
	if kind == "Potato" then return "🥔" end
	if kind == "Hoe" then return "⛏" end
	if kind == "Seeds" then return "🌱" end
	if kind == "Crate" then return "📦" end
	return "◆"
end

local function getToolDetails(tool)
	local kind = getToolType(tool)
	if kind == "Potato" then
		local rarity = tool:GetAttribute("Rarity")
		local potatoType = tool:GetAttribute("PotatoType")
		if rarity and potatoType then return tostring(rarity) .. " • " .. tostring(potatoType) end
		if rarity then return tostring(rarity) end
		return "Potato"
	elseif kind == "Hoe" then
		local durability = tool:GetAttribute("Durability")
		local maxDurability = tool:GetAttribute("MaxDurability")
		if durability and maxDurability then
			return "Durability " .. tostring(durability) .. "/" .. tostring(maxDurability)
		end
		return "Farming tool"
	elseif kind == "Seeds" then
		return "Amount: " .. tostring(tool:GetAttribute("Amount") or player:GetAttribute("PotatoBits") or 0)
	elseif kind == "Crate" then
		return "Count: " .. tostring(tool:GetAttribute("CrateCount") or 1)
	end
	return tool.ToolTip ~= "" and tool.ToolTip or kind
end

local function getContainers()
	local result = {}
	local currentBackpack = player:FindFirstChildOfClass("Backpack")
	if currentBackpack then table.insert(result, currentBackpack) end
	if player.Character then table.insert(result, player.Character) end
	return result
end

local function scanTools()
	local found, seen = {}, {}
	for _, container in ipairs(getContainers()) do
		for _, object in ipairs(container:GetChildren()) do
			if object:IsA("Tool") and object:GetAttribute("InventoryMirror") ~= true then
				local key = getToolKey(object)
				if key and not seen[key] then
					seen[key] = true
					table.insert(found, {Key = key, Tool = object, Type = getToolType(object)})
				end
			end
		end
	end
	table.sort(found, function(a, b)
		local order = {Hoe = 1, Seeds = 2, Crate = 3, Item = 4, Potato = 5}
		local pa, pb = order[a.Type] or 6, order[b.Type] or 6
		if pa ~= pb then return pa < pb end
		return getToolName(a.Tool) < getToolName(b.Tool)
	end)
	return found
end

local function findTool(key)
	if not key then return nil end
	for _, entry in ipairs(currentTools) do
		if entry.Key == key then return entry.Tool end
	end
	return nil
end

local function isAssigned(key)
	for i = 1, HOTBAR_COUNT do
		if slotKeys[i] == key then return true end
	end
	return false
end

local function assignUnslottedTools()
	for _, entry in ipairs(currentTools) do
		if not isAssigned(entry.Key) then
			for i = 1, HOTBAR_COUNT do
				if not slotKeys[i] then
					slotKeys[i] = entry.Key
					break
				end
			end
		end
	end
end

local function isInside(guiObject, point)
	if not guiObject or not guiObject.Visible then return false end
	local pos, size = guiObject.AbsolutePosition, guiObject.AbsoluteSize
	return point.X >= pos.X and point.X <= pos.X + size.X
		and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function equippedTool()
	local character = player.Character
	if not character then return nil end
	for _, object in ipairs(character:GetChildren()) do
		if object:IsA("Tool") then return object end
	end
	return nil
end

local function equipTool(tool)
	if not tool then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if tool.Parent == character then
		humanoid:UnequipTools()
	else
		humanoid:EquipTool(tool)
	end
end

local function useSlot(slot)
	local tool = findTool(slotKeys[slot])
	if tool then equipTool(tool) end
	task.defer(function()
		if gui then
			for i = 1, HOTBAR_COUNT do
				local button = slotButtons[i]
				local equipped = equippedTool()
				local active = equipped ~= nil and getToolKey(equipped) == slotKeys[i]
				if button then
					button.BackgroundColor3 = active and COLORS.AccentSoft or (slotKeys[i] and COLORS.Slot or COLORS.Empty)
					local st = button:FindFirstChild("SlotStroke")
					if st then st.Color = active and COLORS.Accent or COLORS.Stroke end
				end
			end
		end
	end)
end

local function beginDrag(source, key, sourceSlot, input)
	dragState = {
		Source = source,
		Key = key,
		SourceSlot = sourceSlot,
		Start = Vector2.new(input.Position.X, input.Position.Y),
		Input = input,
		Moved = false,
	}
end

local function makeDragGhost(entry)
	if dragGhost then dragGhost:Destroy() end
	dragGhost = Instance.new("TextLabel")
	dragGhost.Name = "DragGhost"
	dragGhost.Size = UDim2.fromOffset(142, 48)
	dragGhost.BackgroundColor3 = COLORS.Panel2
	dragGhost.BackgroundTransparency = 0.05
	dragGhost.TextColor3 = COLORS.Text
	dragGhost.TextSize = 13
	dragGhost.Font = Enum.Font.GothamSemibold
	dragGhost.Text = getToolIcon(entry.Tool) .. "  " .. getToolName(entry.Tool)
	dragGhost.ZIndex = 100
	dragGhost.Parent = gui
	round(dragGhost, 9)
	stroke(dragGhost, COLORS.Accent, 2)
end

local function finishDrag(point)
	if not dragState then return end
	local state = dragState
	dragState = nil
	if dragGhost then dragGhost:Destroy(); dragGhost = nil end
	if not state.Moved then
		if state.Source == "Inventory" then
			local tool = findTool(state.Key)
			if tool then
				if not isAssigned(state.Key) then
					for i = 1, HOTBAR_COUNT do
						if not slotKeys[i] then slotKeys[i] = state.Key; break end
					end
				end
				equipTool(tool)
			end
		elseif state.Source == "Hotbar" and state.SourceSlot then
			useSlot(state.SourceSlot)
		end
		refreshAll()
		return
	end

	local targetSlot
	for i = 1, HOTBAR_COUNT do
		if isInside(slotButtons[i], point) then targetSlot = i; break end
	end

	if state.Source == "Inventory" and targetSlot then
		local existingSlot
		for i = 1, HOTBAR_COUNT do
			if slotKeys[i] == state.Key then existingSlot = i; break end
		end
		if existingSlot and existingSlot ~= targetSlot then
			slotKeys[existingSlot] = slotKeys[targetSlot]
		end
		slotKeys[targetSlot] = state.Key
	elseif state.Source == "Hotbar" and state.SourceSlot then
		local fromSlot = state.SourceSlot
		if targetSlot and targetSlot ~= fromSlot then
			slotKeys[fromSlot], slotKeys[targetSlot] = slotKeys[targetSlot], slotKeys[fromSlot]
		elseif not targetSlot and inventoryPanel and isInside(inventoryPanel, point) then
			slotKeys[fromSlot] = nil
		end
	end
	refreshAll()
end

local function makeTextButton(parent, name, text, size, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color or COLORS.Panel2
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.TextSize = 13
	button.Font = Enum.Font.GothamSemibold
	button.AutoButtonColor = true
	button.Parent = parent
	round(button, 8)
	return button
end

local function clearItems()
	for _, child in ipairs(itemScroll:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
	end
	table.clear(itemButtons)
end

local function makeItemCard(entry, index)
	local tool = entry.Tool
	local card = Instance.new("TextButton")
	card.Name = "Item_" .. tostring(index)
	card.Size = UDim2.fromOffset(126, 112)
	card.BackgroundColor3 = COLORS.Slot
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.Text = ""
	card.Parent = itemScroll
	round(card, 10)
	stroke(card, COLORS.Stroke, 1)

	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromOffset(8, 7)
	icon.Size = UDim2.new(1, -16, 0, 45)
	icon.Text = getToolIcon(tool)
	icon.TextSize = 30
	icon.Font = Enum.Font.GothamBold
	icon.Parent = card

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(5, 53)
	name.Size = UDim2.new(1, -10, 0, 27)
	name.Text = getToolName(tool)
	name.TextColor3 = COLORS.Text
	name.TextSize = 11
	name.Font = Enum.Font.GothamSemibold
	name.TextWrapped = true
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = card

	local detail = Instance.new("TextLabel")
	detail.BackgroundTransparency = 1
	detail.Position = UDim2.fromOffset(4, 83)
	detail.Size = UDim2.new(1, -8, 0, 20)
	detail.Text = getToolDetails(tool)
	detail.TextColor3 = COLORS.Muted
	detail.TextSize = 9
	detail.Font = Enum.Font.Gotham
	detail.TextTruncate = Enum.TextTruncate.AtEnd
	detail.Parent = card

	card.MouseEnter:Connect(function() if not dragState then card.BackgroundColor3 = COLORS.SlotHover end end)
	card.MouseLeave:Connect(function() card.BackgroundColor3 = COLORS.Slot end)
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag("Inventory", entry.Key, nil, input)
		end
	end)
	card.MouseButton1Click:Connect(function()
		if not dragState then return end
		-- The global InputEnded handler handles both click and drag.
	end)
	table.insert(itemButtons, card)
end

local function renderItems()
	clearItems()
	local shown = 0
	local filtered = {}
	for _, entry in ipairs(currentTools) do
		local category = selectedCategory
		local matchesCategory = category == "All" or
			(category == "Potatoes" and entry.Type == "Potato") or
			(category == "Hoes" and entry.Type == "Hoe") or
			(category == "Seeds" and entry.Type == "Seeds") or
			(category == "Crates" and entry.Type == "Crate") or
			(category == "Items" and entry.Type == "Item")
		local name = string.lower(getToolName(entry.Tool))
		if matchesCategory and (searchText == "" or string.find(name, string.lower(searchText), 1, true)) then
			table.insert(filtered, entry)
		end
	end
	for index, entry in ipairs(filtered) do
		shown += 1
		makeItemCard(entry, index)
	end
	statusLabel.Text = tostring(shown) .. " item" .. (shown == 1 and "" or "s") .. "  •  Drag items to the hotbar"
end

local function renderHotbar()
	for slot = 1, HOTBAR_COUNT do
		local button = slotButtons[slot]
		if button then
			local key = slotKeys[slot]
			local tool = findTool(key)
			local icon = button:FindFirstChild("Icon")
			local name = button:FindFirstChild("Name")
			local number = button:FindFirstChild("Number")
			if number then number.Text = tostring(slot) end
			if icon then icon.Text = tool and getToolIcon(tool) or "" end
			if name then name.Text = tool and getToolName(tool) or (key and "..." or "Empty") end
			local active = tool ~= nil and equippedTool() == tool
			button.BackgroundColor3 = active and COLORS.AccentSoft or (key and COLORS.Slot or COLORS.Empty)
			local st = button:FindFirstChild("SlotStroke")
			if st then st.Color = active and COLORS.Accent or COLORS.Stroke end
		end
	end
end

function refreshAll()
	if not gui then return end
	currentTools = scanTools()
	assignUnslottedTools()
	renderHotbar()
	if inventoryPanel.Visible then renderItems() end
end

--==================================================
-- BUILD GUI
--==================================================

local oldGui = playerGui:FindFirstChild("PotatiumInventoryGui")
if oldGui then oldGui:Destroy() end
local oldHotbar = playerGui:FindFirstChild("PotatiumCustomHotbar")
if oldHotbar then oldHotbar:Destroy() end

gui = Instance.new("ScreenGui")
gui.Name = "PotatiumInventoryGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 60
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

inventoryPanel = Instance.new("Frame")
inventoryPanel.Name = "InventoryPanel"
inventoryPanel.Size = UDim2.fromOffset(690, 490)
inventoryPanel.Position = UDim2.new(0.5, -345, 0.5, -270)
inventoryPanel.BackgroundColor3 = COLORS.Background
inventoryPanel.BorderSizePixel = 0
inventoryPanel.Visible = false
inventoryPanel.Parent = gui
round(inventoryPanel, 14)
stroke(inventoryPanel, COLORS.Stroke, 1.5)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 58)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Parent = inventoryPanel
round(header, 14)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 8)
title.Size = UDim2.new(0, 260, 0, 24)
title.Text = "BACKPACK"
title.TextColor3 = COLORS.Text
title.TextSize = 19
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(19, 32)
subtitle.Size = UDim2.new(0, 340, 0, 16)
subtitle.Text = "Drag items onto your hotbar to arrange your loadout"
subtitle.TextColor3 = COLORS.Muted
subtitle.TextSize = 10
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local close = makeTextButton(header, "Close", "✕", UDim2.fromOffset(34, 34), UDim2.new(1, -46, 0, 12), COLORS.Slot)
close.TextSize = 16
close.MouseButton1Click:Connect(function() inventoryPanel.Visible = false end)

searchBox = Instance.new("TextBox")
searchBox.Name = "Search"
searchBox.Size = UDim2.new(1, -32, 0, 34)
searchBox.Position = UDim2.fromOffset(16, 70)
searchBox.BackgroundColor3 = COLORS.Panel2
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "Search items..."
searchBox.PlaceholderColor3 = COLORS.Muted
searchBox.Text = ""
searchBox.TextColor3 = COLORS.Text
searchBox.TextSize = 13
searchBox.Font = Enum.Font.Gotham
searchBox.ClearTextOnFocus = false
searchBox.Parent = inventoryPanel
round(searchBox, 8)
stroke(searchBox, COLORS.Stroke)
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchText = searchBox.Text
	renderItems()
end)

local categories = {"All", "Potatoes", "Hoes", "Seeds", "Crates", "Items"}
local categoryRow = Instance.new("Frame")
categoryRow.BackgroundTransparency = 1
categoryRow.Position = UDim2.fromOffset(16, 113)
categoryRow.Size = UDim2.new(1, -32, 0, 32)
categoryRow.Parent = inventoryPanel

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.FillDirection = Enum.FillDirection.Horizontal
categoryLayout.Padding = UDim.new(0, 6)
categoryLayout.Parent = categoryRow

for _, category in ipairs(categories) do
	local button = makeTextButton(categoryRow, category, category, UDim2.fromOffset(category == "Potatoes" and 86 or 72, 30), UDim2.new(), COLORS.Panel2)
	button.MouseButton1Click:Connect(function()
		selectedCategory = category
		for _, child in ipairs(categoryRow:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = child.Name == category and COLORS.AccentSoft or COLORS.Panel2
			end
		end
		renderItems()
	end)
	if category == "All" then button.BackgroundColor3 = COLORS.AccentSoft end
end

itemScroll = Instance.new("ScrollingFrame")
itemScroll.Name = "Items"
itemScroll.Position = UDim2.fromOffset(16, 154)
itemScroll.Size = UDim2.new(1, -32, 1, -198)
itemScroll.BackgroundColor3 = COLORS.Panel
itemScroll.BorderSizePixel = 0
itemScroll.ScrollBarThickness = 6
itemScroll.ScrollBarImageColor3 = COLORS.Accent
itemScroll.CanvasSize = UDim2.new()
itemScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemScroll.Parent = inventoryPanel
round(itemScroll, 10)

itemGrid = Instance.new("UIGridLayout")
itemGrid.CellSize = UDim2.fromOffset(126, 112)
itemGrid.CellPadding = UDim2.fromOffset(10, 10)
itemGrid.SortOrder = Enum.SortOrder.LayoutOrder
itemGrid.Parent = itemScroll

statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 18, 1, -34)
statusLabel.Size = UDim2.new(1, -36, 0, 24)
statusLabel.TextColor3 = COLORS.Muted
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = inventoryPanel

hotbarFrame = Instance.new("Frame")
hotbarFrame.Name = "Hotbar"
hotbarFrame.AnchorPoint = Vector2.new(0.5, 1)
hotbarFrame.Position = UDim2.new(0.5, 0, 1, -14)
hotbarFrame.Size = UDim2.fromOffset(8 * 72 + 7 * 7 + 24, 88)
hotbarFrame.BackgroundColor3 = COLORS.Background
hotbarFrame.BackgroundTransparency = 0.04
hotbarFrame.BorderSizePixel = 0
hotbarFrame.Parent = gui
round(hotbarFrame, 13)
stroke(hotbarFrame, COLORS.Stroke, 1.3)

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hotbarLayout.Padding = UDim.new(0, 7)
hotbarLayout.Parent = hotbarFrame

local hotbarPadding = Instance.new("UIPadding")
hotbarPadding.PaddingLeft = UDim.new(0, 12)
hotbarPadding.PaddingRight = UDim.new(0, 12)
hotbarPadding.Parent = hotbarFrame

for slot = 1, HOTBAR_COUNT do
	local button = Instance.new("TextButton")
	button.Name = "Slot" .. tostring(slot)
	button.Size = UDim2.fromOffset(72, 66)
	button.BackgroundColor3 = COLORS.Empty
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = hotbarFrame
	round(button, 9)
	local st = stroke(button, COLORS.Stroke, 1)
	st.Name = "SlotStroke"

	local number = Instance.new("TextLabel")
	number.Name = "Number"
	number.BackgroundTransparency = 1
	number.Position = UDim2.fromOffset(5, 3)
	number.Size = UDim2.fromOffset(16, 13)
	number.Text = tostring(slot)
	number.TextColor3 = COLORS.Muted
	number.TextSize = 10
	number.Font = Enum.Font.GothamBold
	number.Parent = button

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromOffset(0, 11)
	icon.Size = UDim2.new(1, 0, 0, 31)
	icon.Text = ""
	icon.TextColor3 = COLORS.Text
	icon.TextSize = 24
	icon.Font = Enum.Font.GothamBold
	icon.Parent = button

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(3, 43)
	name.Size = UDim2.new(1, -6, 0, 17)
	name.Text = "Empty"
	name.TextColor3 = COLORS.Text
	name.TextSize = 9
	name.Font = Enum.Font.GothamSemibold
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = button

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag("Hotbar", slotKeys[slot], slot, input)
		end
	end)
	button.MouseButton1Click:Connect(function()
		if not dragState then useSlot(slot) end
	end)
	slotButtons[slot] = button
end

--==================================================
-- DRAG HANDLING
--==================================================

UserInputService.InputChanged:Connect(function(input)
	if not dragState then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input == dragState.Input then
		local point = Vector2.new(input.Position.X, input.Position.Y)
		if not dragState.Moved and (point - dragState.Start).Magnitude >= 8 then
			dragState.Moved = true
			local entry = findTool(dragState.Key)
			if entry then
				local fakeEntry = {Tool = entry}
				makeDragGhost(fakeEntry)
			end
		end
		if dragState.Moved and dragGhost then
			dragGhost.Position = UDim2.fromOffset(point.X + 12, point.Y + 12)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not dragState then return end
	local isMouseRelease = input.UserInputType == Enum.UserInputType.MouseButton1
	local isTouchRelease = input.UserInputType == Enum.UserInputType.Touch and input == dragState.Input
	if isMouseRelease or isTouchRelease then
		local point = UserInputService:GetMouseLocation()
		if input.UserInputType == Enum.UserInputType.Touch then
			point = Vector2.new(input.Position.X, input.Position.Y)
		end
		finishDrag(point)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == OPEN_KEY then
		inventoryPanel.Visible = not inventoryPanel.Visible
		if inventoryPanel.Visible then refreshAll() end
		return
	end
	local keyToSlot = {
		[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2,
		[Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
		[Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
		[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8,
	}
	local slot = keyToSlot[input.KeyCode]
	if slot and not UserInputService:GetFocusedTextBox() then
		useSlot(slot)
	end
end)

--==================================================
-- REFRESH / RESPAWN
--==================================================

local refreshQueued = false
function refreshAll()
	if not gui then return end
	if refreshQueued then return end
	refreshQueued = true
	task.delay(0.12, function()
		refreshQueued = false
		if not gui or not gui.Parent then return end
		currentTools = scanTools()
		assignUnslottedTools()
		renderHotbar()
		if inventoryPanel.Visible then renderItems() end
	end)
end

local function connectContainer(container)
	if not container then return end
	container.ChildAdded:Connect(function(object)
		if object:IsA("Tool") then refreshAll() end
	end)
	container.ChildRemoved:Connect(function(object)
		if object:IsA("Tool") then refreshAll() end
	end)
end

connectContainer(backpack)
player.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	connectContainer(character)
	refreshAll()
end)
if player.Character then connectContainer(player.Character) end

for _, attribute in ipairs({"PotatoInventoryRevision", "HoeInventoryRevision", "CrateInventoryRevision", "PotatoBits"}) do
	player:GetAttributeChangedSignal(attribute):Connect(refreshAll)
end

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

refreshAll()

print("🥔 POTATIUM DRAGGABLE BACKPACK + HOTBAR loaded")
print("B = backpack | drag items to hotbar | drag slots back to backpack to unassign")
