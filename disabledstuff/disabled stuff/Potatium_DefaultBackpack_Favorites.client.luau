--==================================================
-- POTATIUM - DEFAULT ROBLOX HOTBAR + B INVENTORY TABS
--
-- Keeps Roblox's REAL hotbar and REAL Tools enabled.
-- B opens a simple inventory panel above the hotbar.
--
-- Tabs:
--   ALL        = every real Tool the player owns
--   FAVORITES  = only favorite Tools
--
-- This script does NOT create a hotbar and does NOT create
-- fake inventory Tools.
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local OPEN_KEY = Enum.KeyCode.B

local inventoryOpen = false
local favoritesOnly = false
local refreshQueued = false

local favorites = {}

--==================================================
-- KEEP ROBLOX HOTBAR ENABLED
--==================================================

local function keepRobloxBackpackEnabled()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
end

keepRobloxBackpackEnabled()

--==================================================
-- REMOVE ONLY THE OLD POTATIUM BACKPACK GUI
--
-- IMPORTANT: this does not disable Roblox's real hotbar.
--==================================================

local oldGui = playerGui:FindFirstChild("PotatoBackpackGui")
if oldGui then
	oldGui:Destroy()
end

local oldTabs = playerGui:FindFirstChild("PotatiumDefaultBackpackTabs")
if oldTabs then
	oldTabs:Destroy()
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "PotatiumInventoryTabs"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 40
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Soft dark area like the reference image.
local panel = Instance.new("Frame")
panel.Name = "InventoryPanel"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -86)
panel.Size = UDim2.new(0.82, 0, 0, 350)
panel.BackgroundColor3 = Color3.fromRGB(27, 31, 34)
panel.BackgroundTransparency = 0.22
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 3)
panelCorner.Parent = panel

-- Item area.
local itemArea = Instance.new("ScrollingFrame")
itemArea.Name = "Items"
itemArea.Position = UDim2.fromOffset(12, 12)
itemArea.Size = UDim2.new(1, -24, 1, -64)
itemArea.BackgroundTransparency = 1
itemArea.BorderSizePixel = 0
itemArea.ScrollBarThickness = 4
itemArea.ScrollBarImageTransparency = 0.35
itemArea.CanvasSize = UDim2.new()
itemArea.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(94, 66)
grid.CellPadding = UDim2.fromOffset(5, 5)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = itemArea

grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	itemArea.CanvasSize = UDim2.fromOffset(0, grid.AbsoluteContentSize.Y + 6)
end)

-- Tabs sit at the bottom of the panel, just like the reference.
local tabs = Instance.new("Frame")
tabs.Name = "Tabs"
tabs.AnchorPoint = Vector2.new(0.5, 1)
tabs.Position = UDim2.new(0.5, 0, 1, -8)
tabs.Size = UDim2.fromOffset(225, 36)
tabs.BackgroundTransparency = 1
tabs.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabs

local function makeTab(name, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(108, 32)
	button.BackgroundColor3 = Color3.fromRGB(42, 46, 49)
	button.BackgroundTransparency = 0.04
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(225, 225, 225)
	button.TextSize = 13
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = tabs

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button

	return button
end

local allButton = makeTab("All", "ALL")
local favoritesButton = makeTab("Favorites", "⭐ FAVORITES")

--==================================================
-- TOOL HELPERS
--==================================================

local function isFakeMirror(tool)
	return tool:GetAttribute("InventoryMirror") == true
		or tool:GetAttribute("EquipmentMirror") == true
end

local function isPotato(tool)
	return tool:GetAttribute("PotatoId") ~= nil
		or tool:GetAttribute("PotatoInventoryTool") == true
		or tool:GetAttribute("PotatoType") ~= nil
end

local function getDisplayName(tool)
	if isPotato(tool) then
		local potatoType = tool:GetAttribute("PotatoType")
		if potatoType ~= nil then
			local value = tostring(potatoType)
			if value == "Potato" then
				value = "Normal"
			end
			return value .. " Potato"
		end
	end

	return tostring(tool.Name)
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

	return "Tool_" .. tostring(tool.Name)
end

local function isFavorite(tool)
	local key = getFavoriteKey(tool)
	return favorites[key] == true
		or tool:GetAttribute("Favorite") == true
		or tool:GetAttribute("LocalFavorite") == true
end

local function getRealTools()
	local result = {}
	local seen = {}

	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character

	local function collect(container)
		if not container then
			return
		end

		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and not isFakeMirror(child) and not seen[child] then
				seen[child] = true
				table.insert(result, child)
			end
		end
	end

	collect(backpack)
	collect(character)

	table.sort(result, function(a, b)
		return string.lower(getDisplayName(a)) < string.lower(getDisplayName(b))
	end)

	return result
end

--==================================================
-- FAVORITE DATA SYNC
--
-- Uses the project's existing snapshot remotes only to read
-- favorite status. No DataStore or server system is changed.
--==================================================

local function applyPotatoFavorites()
	local remotes = ReplicatedStorage:FindFirstChild("PotatiumInventoryRemotes")
	local remote = remotes and remotes:FindFirstChild("GetPotatoSnapshot")
	if not remote then
		return
	end

	local ok, records = pcall(function()
		return remote:InvokeServer()
	end)

	if not ok or type(records) ~= "table" then
		return
	end

	for _, record in ipairs(records) do
		if type(record) == "table" and record.Id ~= nil then
			local key = "Potato_" .. tostring(record.Id)
			favorites[key] = record.Favorite == true

			for _, tool in ipairs(getRealTools()) do
				if tool:GetAttribute("PotatoId") == record.Id then
					tool:SetAttribute("Favorite", record.Favorite == true)
					tool:SetAttribute("LocalFavorite", record.Favorite == true)
				end
			end
		end
	end
end

local function applyEquipmentFavorites()
	local remotes = ReplicatedStorage:FindFirstChild("PotatiumCrateRemotes")
	local remote = remotes and remotes:FindFirstChild("GetEquipmentSnapshot")
	if not remote then
		return
	end

	local ok, snapshot = pcall(function()
		return remote:InvokeServer()
	end)

	if not ok or type(snapshot) ~= "table" then
		return
	end

	local hoes = snapshot.HoeInventory
	if type(hoes) == "table" then
		for _, record in ipairs(hoes) do
			if type(record) == "table" and record.Id ~= nil then
				local key = "Hoe_" .. tostring(record.Id)
				favorites[key] = record.Favorite == true

				for _, tool in ipairs(getRealTools()) do
					if tostring(tool:GetAttribute("HoeId") or "") == tostring(record.Id) then
						tool:SetAttribute("Favorite", record.Favorite == true)
						tool:SetAttribute("LocalFavorite", record.Favorite == true)
					end
				end
			end
		end
	end
end

local function syncFavorites()
	task.spawn(applyPotatoFavorites)
	task.spawn(applyEquipmentFavorites)
end

--==================================================
-- EQUIP REAL TOOL
--==================================================

local function equipRealTool(tool)
	if not tool or not tool:IsA("Tool") or isFakeMirror(tool) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if tool.Parent == character then
		humanoid:UnequipTools()
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack or tool.Parent ~= backpack then
		return
	end

	-- This is the same real Tool Roblox's default hotbar uses.
	pcall(function()
		humanoid:EquipTool(tool)
	end)
end

--==================================================
-- DRAG FROM INVENTORY -> ROBLOX DEFAULT HOTBAR
--
-- Roblox does not expose a public API for directly assigning a
-- CoreGui hotbar slot. The default backpack orders its tools from
-- the player's Backpack, so this script detects the CoreGui slot
-- under the mouse and reorders the REAL Tool objects to match.
--==================================================

local dragState = nil
local dragGhost = nil
local dragMoved = false
local DRAG_THRESHOLD = 8

local function getPointerPosition()
	local mouse = UserInputService:GetMouseLocation()
	return Vector2.new(mouse.X, mouse.Y)
end

local function makeDragGhost(tool)
	if dragGhost then
		dragGhost:Destroy()
	end

	dragGhost = Instance.new("TextLabel")
	dragGhost.Name = "DragGhost"
	dragGhost.AnchorPoint = Vector2.new(0.5, 0.5)
	dragGhost.Size = UDim2.fromOffset(94, 66)
	dragGhost.BackgroundColor3 = Color3.fromRGB(58, 63, 67)
	dragGhost.BackgroundTransparency = 0.08
	dragGhost.BorderSizePixel = 0
	dragGhost.Text = getDisplayName(tool)
	dragGhost.TextColor3 = Color3.fromRGB(255, 255, 255)
	dragGhost.TextSize = 12
	dragGhost.Font = Enum.Font.GothamBold
	dragGhost.TextWrapped = true
	dragGhost.ZIndex = 200
	dragGhost.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = dragGhost
end

local function getNumericSlotFromObject(object)
	if not object or not object:IsA("GuiObject") then
		return nil
	end

	local name = tostring(object.Name)
	local text = object:IsA("TextButton") or object:IsA("TextLabel")
		and tostring(object.Text)
		or ""

	local function parse(value)
		if value == "0" then
			return 10
		end
		local n = tonumber(value)
		if n and n >= 1 and n <= 10 and tostring(n) == value then
			return n
		end
		return nil
	end

	local direct = parse(name) or parse(text)
	if direct then
		return direct
	end

	local lower = string.lower(name)
	local n = lower:match("slot[_%-]?(%d+)$")
	if n then
		n = tonumber(n)
		if n and n >= 1 and n <= 10 then
			return n
		end
	end

	return nil
end

local function getDefaultHotbarSlotAt(position)
	-- Do not depend on Roblox's internal BackpackGui hierarchy. Instead,
	-- ask CoreGui what GUI objects are actually underneath points along the
	-- bottom-center hotbar and use their real screen positions.
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end

	local viewport = camera.ViewportSize
	local ok, hitObjects = pcall(function()
		return CoreGui:GetGuiObjectsAtPosition(position.X, position.Y)
	end)

	if not ok or type(hitObjects) ~= "table" then
		return nil
	end

	-- First try the actual objects at the release point and their parents.
	for _, object in ipairs(hitObjects) do
		local current = object
		for _ = 1, 8 do
			if not current then
				break
			end

			local slot = getNumericSlotFromObject(current)
			if slot then
				return slot
			end

			current = current.Parent
		end
	end

	-- Roblox's CoreGui hierarchy/names are internal and can change.
	-- Find visible hotbar slot rectangles by sampling the bottom area
	-- with GetGuiObjectsAtPosition. This avoids GetDescendants entirely.
	local candidates = {}
	local candidateKeys = {}

	local scanTop = math.max(0, viewport.Y - 115)
	local scanBottom = viewport.Y - 5
	local stepX = 6
	local stepY = 6

	for y = scanTop, scanBottom, stepY do
		for x = 0, viewport.X, stepX do
			local sampleOk, objects = pcall(function()
				return CoreGui:GetGuiObjectsAtPosition(x, y)
			end)

			if sampleOk and type(objects) == "table" then
				for _, object in ipairs(objects) do
					if object and object:IsA("GuiButton") and object.Visible then
						local objectPosition = object.AbsolutePosition
						local objectSize = object.AbsoluteSize

						if objectSize.X >= 35
							and objectSize.X <= 90
							and objectSize.Y >= 35
							and objectSize.Y <= 90
							and objectPosition.Y >= viewport.Y - 125
							and objectPosition.Y + objectSize.Y <= viewport.Y
						then
							local key = tostring(object)
							if not candidateKeys[key] then
								candidateKeys[key] = true
								table.insert(candidates, object)
							end
						end
					end
				end
			end
		end
	end

	table.sort(candidates, function(a, b)
		return a.AbsolutePosition.X < b.AbsolutePosition.X
	end)

	local slots = {}
	for _, button in ipairs(candidates) do
		local p = button.AbsolutePosition
		local size = button.AbsoluteSize
		local centerX = p.X + size.X * 0.5
		local centerY = p.Y + size.Y * 0.5
		local duplicate = false

		for _, existing in ipairs(slots) do
			local ep = existing.AbsolutePosition
			local es = existing.AbsoluteSize
			local eCenterX = ep.X + es.X * 0.5
			local eCenterY = ep.Y + es.Y * 0.5
			if math.abs(centerX - eCenterX) < 5 and math.abs(centerY - eCenterY) < 5 then
				duplicate = true
				break
			end
		end

		if not duplicate then
			table.insert(slots, button)
		end
	end

	if #slots < 2 then
		return nil
	end

	table.sort(slots, function(a, b)
		return a.AbsolutePosition.X < b.AbsolutePosition.X
	end)

	for index, button in ipairs(slots) do
		local p = button.AbsolutePosition
		local size = button.AbsoluteSize
		if position.X >= p.X
			and position.X <= p.X + size.X
			and position.Y >= p.Y
			and position.Y <= p.Y + size.Y
		then
			if index <= 10 then
				return index
			end
		end
	end

	return nil
end
local function getBackpackToolsInOrder()
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return {}
	end

	local tools = {}
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") and not isFakeMirror(child) then
			table.insert(tools, child)
		end
	end
	return tools
end

local function reorderBackpackForHotbar(tool, targetSlot)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack or not tool or tool.Parent ~= backpack then
		return false
	end

	local tools = getBackpackToolsInOrder()
	local currentIndex
	for i, candidate in ipairs(tools) do
		if candidate == tool then
			currentIndex = i
			break
		end
	end
	if not currentIndex then
		return false
	end

	table.remove(tools, currentIndex)
	targetSlot = math.clamp(targetSlot, 1, #tools + 1)
	table.insert(tools, targetSlot, tool)

	-- Re-parent through a temporary local folder. This changes the
	-- client-side Backpack child order without destroying any Tool.
	local tempFolder = Instance.new("Folder")
	tempFolder.Name = "PotatiumHotbarReorder"
	tempFolder.Parent = backpack

	for _, candidate in ipairs(tools) do
		candidate.Parent = tempFolder
	end

	for _, candidate in ipairs(tools) do
		candidate.Parent = backpack
	end

	tempFolder:Destroy()
	return true
end

local beginInventoryDrag

local function finishInventoryDrag()
	if not dragState then
		return
	end

	local state = dragState
	dragState = nil

	if dragGhost then
		dragGhost:Destroy()
		dragGhost = nil
	end

	if not dragMoved then
		equipRealTool(state.tool)
		return
	end

	local position = getPointerPosition()
	local targetSlot = getDefaultHotbarSlotAt(position)

	if targetSlot then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if state.tool.Parent == character and humanoid then
			humanoid:UnequipTools()
			task.wait()
		end

		if state.tool.Parent == player:FindFirstChildOfClass("Backpack") then
			reorderBackpackForHotbar(state.tool, targetSlot)
		end
	end
end

beginInventoryDrag = function(button, tool)
	if dragState then
		return
	end

	dragState = {
		button = button,
		tool = tool,
		start = getPointerPosition(),
	}
	dragMoved = false

	makeDragGhost(tool)
	if dragGhost then
		dragGhost.Position = UDim2.fromOffset(dragState.start.X, dragState.start.Y)
	end
end

UserInputService.InputChanged:Connect(function(input)
	if not dragState then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local position = getPointerPosition()
	local delta = position - dragState.start

	if not dragMoved and delta.Magnitude >= DRAG_THRESHOLD then
		dragMoved = true
	end

	if dragMoved and dragGhost then
		dragGhost.Position = UDim2.fromOffset(position.X, position.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		finishInventoryDrag()
	end
end)

--==================================================
-- ITEM BUTTONS
--==================================================

local function clearItems()
	for _, child in ipairs(itemArea:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end


local function createItemButton(tool, order)
	local button = Instance.new("TextButton")
	button.Name = "Item_" .. tostring(order)
	button.LayoutOrder = order
	button.BackgroundColor3 = Color3.fromRGB(47, 52, 55)
	button.BackgroundTransparency = 0.04
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = true
	button.Parent = itemArea

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 85, 88)
	stroke.Thickness = 1
	stroke.Transparency = 0.45
	stroke.Parent = button

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(5, 5)
	nameLabel.Size = UDim2.new(1, -10, 1, -10)
	nameLabel.Text = getDisplayName(tool)
	nameLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.Parent = button

	if isFavorite(tool) then
		local heart = Instance.new("TextLabel")
		heart.BackgroundTransparency = 1
		heart.Position = UDim2.fromOffset(4, 2)
		heart.Size = UDim2.fromOffset(18, 18)
		heart.Text = "★"
		heart.TextColor3 = Color3.fromRGB(255, 205, 70)
		heart.TextSize = 12
		heart.Font = Enum.Font.GothamBold
		heart.Parent = button
	end

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginInventoryDrag(button, tool)
		end
	end)
end

--==================================================
-- REFRESH
--==================================================

local function refreshInventory()
	if not inventoryOpen then
		return
	end

	clearItems()

	local shown = 0

	for _, tool in ipairs(getRealTools()) do
		if not favoritesOnly or isFavorite(tool) then
			shown += 1
			createItemButton(tool, shown)
		end
	end

	if shown == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "Empty"
		empty.Size = UDim2.new(1, -10, 0, 50)
		empty.BackgroundTransparency = 1
		empty.Text = favoritesOnly and "No favorite items" or "No items"
		empty.TextColor3 = Color3.fromRGB(170, 175, 178)
		empty.TextSize = 14
		empty.Font = Enum.Font.Gotham
		empty.Parent = itemArea
	end
end

--==================================================
-- TAB VISUALS
--==================================================

local function updateTabs()
	if favoritesOnly then
		allButton.BackgroundColor3 = Color3.fromRGB(42, 46, 49)
		favoritesButton.BackgroundColor3 = Color3.fromRGB(72, 76, 80)
	else
		allButton.BackgroundColor3 = Color3.fromRGB(72, 76, 80)
		favoritesButton.BackgroundColor3 = Color3.fromRGB(42, 46, 49)
	end
end

allButton.Activated:Connect(function()
	favoritesOnly = false
	updateTabs()
	refreshInventory()
end)

favoritesButton.Activated:Connect(function()
	favoritesOnly = true
	updateTabs()
	syncFavorites()
	refreshInventory()
end)

--==================================================
-- OPEN / CLOSE
--==================================================

local function openInventory()
	inventoryOpen = true
	panel.Visible = true
	keepRobloxBackpackEnabled()
	syncFavorites()
	refreshInventory()
end

local function closeInventory()
	inventoryOpen = false
	panel.Visible = false
	keepRobloxBackpackEnabled()
end

local function toggleInventory()
	if inventoryOpen then
		closeInventory()
	else
		openInventory()
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode ~= OPEN_KEY then
		return
	end

	-- B is intentionally handled even if another UI reports input processed.
	toggleInventory()
end)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Escape and inventoryOpen then
		closeInventory()
	end
end)

--==================================================
-- LIVE TOOL CHANGES
--==================================================

local function queueInventoryRefresh()
	if refreshQueued then
		return
	end

	refreshQueued = true
	task.defer(function()
		refreshQueued = false
		if inventoryOpen then
			refreshInventory()
		end
	end)
end

local function hookContainer(container)
	if not container then
		return
	end

	container.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			queueInventoryRefresh()
		end
	end)

	container.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			queueInventoryRefresh()
		end
	end)
end

hookContainer(player:FindFirstChildOfClass("Backpack"))

player.CharacterAdded:Connect(function(character)
	hookContainer(character)
	task.delay(1, function()
		if inventoryOpen then
			syncFavorites()
			refreshInventory()
		end
	end)
end)

-- Keep the real Roblox hotbar enabled. This script never replaces it.
task.spawn(function()
	while gui.Parent do
		task.wait(3)
		keepRobloxBackpackEnabled()
	end
end)

updateTabs()

print("[Potatium] Default Roblox hotbar + B inventory tabs loaded")
