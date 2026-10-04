--==================================================
-- POTATIUM LEADERBOARD SERVICE
-- Path:
-- src/server/LeaderboardService.luau
--
-- IMPORTANT:
-- This is a MODULESCRIPT.
-- Do NOT use .server.luau for this file.
--
-- It uses the physical boards that are already inside:
-- Workspace > PotatoWorld > CustomLeaderboards
--
-- Expected models:
--   KillLeaderboard   > BoardPart
--   RobuxLeaderboard  > BoardPart
--   WealthLeaderboard > BoardPart
--==================================================

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local LeaderboardService = {}

local TOP_COUNT = 10
local REFRESH_SECONDS = 120
local GLOBAL_RANK_REFRESH_SECONDS = 30
local RANK_PAGE_SIZE = 100
local MAX_RANK_PAGES = 100

local function getStoreName(name)
	if RunService:IsStudio() then
		return name .. "_DEV_v1"
	end

	return name .. "_LIVE_v1"
end

local killsStore = DataStoreService:GetOrderedDataStore(
	getStoreName("PotatoKillsLeaderboard")
)

local robuxStore = DataStoreService:GetOrderedDataStore(
	getStoreName("PotatoRobuxLeaderboard")
)

local wealthStore = DataStoreService:GetOrderedDataStore(
	getStoreName("PotatoCashLeaderboard")
)

local killsDataStore = DataStoreService:GetDataStore(
	getStoreName("PotatoKillsStats")
)

local robuxDataStore = DataStoreService:GetDataStore(
	getStoreName("PotatoRobuxStats")
)

local BOARD_DEFS = {
	KillLeaderboard = {
		title = "⚔  TOP KILLERS",
		label = "KILLS",
		prefix = "",
		accent = Color3.fromRGB(235, 91, 72),
		background = Color3.fromRGB(31, 21, 22),
		titleBackground = Color3.fromRGB(67, 31, 31),
		rowA = Color3.fromRGB(48, 30, 29),
		rowB = Color3.fromRGB(42, 27, 28),
		valueColor = Color3.fromRGB(255, 126, 98),
	},

	RobuxLeaderboard = {
		title = "💎  TOP ROBUX SPENDERS",
		label = "SPENT",
		prefix = "R$ ",
		accent = Color3.fromRGB(102, 205, 255),
		background = Color3.fromRGB(20, 24, 37),
		titleBackground = Color3.fromRGB(36, 49, 78),
		rowA = Color3.fromRGB(31, 40, 61),
		rowB = Color3.fromRGB(27, 34, 53),
		valueColor = Color3.fromRGB(120, 222, 255),
	},

	WealthLeaderboard = {
		title = "💰  WEALTH LEADERBOARD",
		label = "WEALTH",
		prefix = "$",
		accent = Color3.fromRGB(99, 214, 143),
		background = Color3.fromRGB(21, 30, 24),
		titleBackground = Color3.fromRGB(36, 70, 48),
		rowA = Color3.fromRGB(31, 52, 38),
		rowB = Color3.fromRGB(27, 44, 33),
		valueColor = Color3.fromRGB(102, 232, 150),
	},
}

local activeBoards = {}
local started = false
local globalRankRefreshRunning = false

local function formatCompact(value)
	value = tonumber(value) or 0
	local absolute = math.abs(value)

	if absolute >= 1e12 then
		return string.format("%.2fT", value / 1e12)
	elseif absolute >= 1e9 then
		return string.format("%.2fB", value / 1e9)
	elseif absolute >= 1e6 then
		return string.format("%.2fM", value / 1e6)
	elseif absolute >= 1e3 then
		return string.format("%.2fK", value / 1e3)
	end

	return tostring(math.floor(value))
end

local function getNumberAttribute(player, attributeName)
	return math.max(
		0,
		math.floor(
			type(player.GetAttribute) == "function"
			and (tonumber(player:GetAttribute(attributeName)) or 0)
			or 0
		)
	)
end

local function getUsername(userId)
	local online = Players:GetPlayerByUserId(tonumber(userId) or 0)

	if online then
		return online.Name
	end

	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(tonumber(userId))
	end)

	if success then
		return name
	end

	return "User " .. tostring(userId)
end

local function getBoardPart(model)
	local boardPart = model:FindFirstChild("BoardPart", true)

	if boardPart and boardPart:IsA("BasePart") then
		return boardPart
	end

	return nil
end

local function discoverBoards(world)
	table.clear(activeBoards)

	local roots = {}

	if world then
		table.insert(roots, world)
	end

	for _, root in ipairs(roots) do
		for _, object in ipairs(root:GetDescendants()) do
			local definition = BOARD_DEFS[object.Name]

			if definition and object:IsA("Model") then
				local part = getBoardPart(object)

				if part then
					table.insert(activeBoards, {
						name = object.Name,
						model = object,
						part = part,
						definition = definition,
					})
				end
			end
		end
	end

	return #activeBoards
end

local function createLabel(parent, name, position, size, text, textColor, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor
	label.Font = font or Enum.Font.GothamBold
	label.TextScaled = true
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.45
	label.Parent = parent
	return label
end

local function buildBoardGui(board)
	local part = board.part
	local definition = board.definition

	local old = part:FindFirstChild("PotatiumLeaderboardGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "PotatiumLeaderboardGui"
	gui.Face = Enum.NormalId.Front
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(1000, 700)
	gui.Parent = part

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = definition.background
	background.BorderSizePixel = 0
	background.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 18)
	padding.PaddingLeft = UDim.new(0, 24)
	padding.PaddingRight = UDim.new(0, 24)
	padding.Parent = background

	local title = createLabel(
		background,
		"Title",
		UDim2.new(0, 0, 0, 0),
		UDim2.new(1, 0, 0, 70),
		definition.title,
		Color3.fromRGB(248, 244, 235),
		Enum.Font.GothamBold
	)

	title.BackgroundColor3 = definition.titleBackground
	title.BackgroundTransparency = 0

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 14)
	titleCorner.Parent = title

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = definition.accent
	titleStroke.Thickness = 2
	titleStroke.Transparency = 0.3
	titleStroke.Parent = title

	createLabel(
		background,
		"Header",
		UDim2.new(0, 0, 0, 88),
		UDim2.new(1, 0, 0, 28),
		"RANK          PLAYER                              " .. definition.label,
		Color3.fromRGB(155, 165, 175),
		Enum.Font.GothamBold
	).TextXAlignment = Enum.TextXAlignment.Left

	for rank = 1, TOP_COUNT do
		local row = Instance.new("Frame")
		row.Name = "Row_" .. rank
		row.Position = UDim2.new(0, 0, 0, 122 + ((rank - 1) * 49))
		row.Size = UDim2.new(1, 0, 0, 42)
		row.BackgroundColor3 = rank % 2 == 0 and definition.rowB or definition.rowA
		row.BorderSizePixel = 0
		row.Parent = background

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = row

		createLabel(
			row,
			"Rank",
			UDim2.new(0.02, 0, 0, 0),
			UDim2.new(0.10, 0, 1, 0),
			"#" .. rank,
			Color3.fromRGB(224, 210, 167),
			Enum.Font.GothamBold
		)

		local nameLabel = createLabel(
			row,
			"Username",
			UDim2.new(0.14, 0, 0, 0),
			UDim2.new(0.56, 0, 1, 0),
			"---",
			Color3.fromRGB(240, 240, 240),
			Enum.Font.GothamBold
		)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left

		local valueLabel = createLabel(
			row,
			"Value",
			UDim2.new(0.71, 0, 0, 0),
			UDim2.new(0.27, 0, 1, 0),
			definition.prefix .. "0",
			definition.valueColor,
			Enum.Font.GothamBold
		)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	end

	return gui
end

local function refreshBoard(board, entries)
	if not board.part.Parent then
		return
	end

	local gui = board.part:FindFirstChild("PotatiumLeaderboardGui")
	if not gui then
		gui = buildBoardGui(board)
	end

	local background = gui:FindFirstChild("Background")
	if not background then
		return
	end

	for rank = 1, TOP_COUNT do
		local row = background:FindFirstChild("Row_" .. rank)

		if row then
			local entry = entries[rank]
			local nameLabel = row:FindFirstChild("Username")
			local valueLabel = row:FindFirstChild("Value")

			if entry then
				local value = tonumber(entry.value) or 0
				local username = getUsername(entry.key)

				nameLabel.Text = username
				valueLabel.Text = board.definition.prefix .. formatCompact(value)
			else
				nameLabel.Text = "---"
				valueLabel.Text = board.definition.prefix .. "0"
			end
		end
	end
end

local function getTopEntries(store)
	local success, pages = pcall(function()
		return store:GetSortedAsync(false, TOP_COUNT)
	end)

	if not success then
		return {}
	end

	return pages:GetCurrentPage()
end

local function getTopEntriesFallback(attributeName)
	local players = Players:GetPlayers()

	table.sort(players, function(a, b)
		return getNumberAttribute(a, attributeName) > getNumberAttribute(b, attributeName)
	end)

	local entries = {}

	for index, player in ipairs(players) do
		if index > TOP_COUNT then
			break
		end

		table.insert(entries, {
			key = tostring(player.UserId),
			value = getNumberAttribute(player, attributeName),
		})
	end

	return entries
end

local function safeSetOrdered(store, player, value)
	pcall(function()
		store:SetAsync(
			tostring(player.UserId),
			math.max(0, math.floor(tonumber(value) or 0))
		)
	end)
end

local function savePersistentStat(store, player, attributeName)
	pcall(function()
		store:SetAsync(
			tostring(player.UserId),
			getNumberAttribute(player, attributeName)
		)
	end)
end

local function loadPersistentStat(dataStore, player, attributeName)
	local success, value = pcall(function()
		return dataStore:GetAsync(tostring(player.UserId))
	end)

	if success and player:GetAttribute(attributeName) == nil then
		player:SetAttribute(attributeName, math.max(0, math.floor(tonumber(value) or 0)))
	end
end

local function setupPlayer(player)
	if player:GetAttribute("Kills") == nil then
		player:SetAttribute("Kills", 0)
	end

	if player:GetAttribute("RobuxSpent") == nil then
		player:SetAttribute("RobuxSpent", 0)
	end

	task.spawn(function()
		while player.Parent and player:GetAttribute("DataLoaded") ~= true do
			task.wait(0.05)
		end

		if not player.Parent then
			return
		end

		loadPersistentStat(killsDataStore, player, "Kills")
		loadPersistentStat(robuxDataStore, player, "RobuxSpent")

		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player
		end

		local cash = leaderstats:FindFirstChild("Cash") or Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Parent = leaderstats

		local kills = leaderstats:FindFirstChild("Kills") or Instance.new("IntValue")
		kills.Name = "Kills"
		kills.Parent = leaderstats

		local robux = leaderstats:FindFirstChild("RobuxSpent") or Instance.new("IntValue")
		robux.Name = "RobuxSpent"
		robux.Parent = leaderstats

		local function updateStats()
			cash.Value = getNumberAttribute(player, "Cash")
			kills.Value = getNumberAttribute(player, "Kills")
			robux.Value = getNumberAttribute(player, "RobuxSpent")
		end

		player:GetAttributeChangedSignal("Cash"):Connect(updateStats)
		player:GetAttributeChangedSignal("Kills"):Connect(updateStats)
		player:GetAttributeChangedSignal("RobuxSpent"):Connect(updateStats)

		updateStats()
	end)
end

function LeaderboardService.AddKills(player, amount)
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	if not player or amount <= 0 then
		return false
	end

	local current = getNumberAttribute(player, "Kills")
	player:SetAttribute("Kills", current + amount)
	return true
end

function LeaderboardService.AddRobuxSpent(player, amount)
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	if not player or amount <= 0 then
		return false
	end

	local current = getNumberAttribute(player, "RobuxSpent")
	player:SetAttribute("RobuxSpent", current + amount)
	return true
end

function LeaderboardService.GetKills(player)
	return getNumberAttribute(player, "Kills")
end

function LeaderboardService.GetRobuxSpent(player)
	return getNumberAttribute(player, "RobuxSpent")
end

local function refreshGlobalRanks()
	if globalRankRefreshRunning then
		return
	end

	globalRankRefreshRunning = true

	local remaining = {}
	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		remaining[tostring(player.UserId)] = player
		player:SetAttribute("GlobalRank", 0)
		count += 1
	end

	if count <= 0 then
		globalRankRefreshRunning = false
		return
	end

	local success, pages = pcall(function()
		return wealthStore:GetSortedAsync(false, RANK_PAGE_SIZE)
	end)

	if not success then
		globalRankRefreshRunning = false
		return
	end

	local rank = 0
	local pageNumber = 0

	while pageNumber < MAX_RANK_PAGES do
		pageNumber += 1

		for _, entry in ipairs(pages:GetCurrentPage()) do
			rank += 1

			local player = remaining[tostring(entry.key)]
			if player then
				player:SetAttribute("GlobalRank", rank)
				remaining[tostring(entry.key)] = nil
				count -= 1

				if count <= 0 then
					globalRankRefreshRunning = false
					return
				end
			end
		end

		if pages.IsFinished then
			break
		end

		local advanced = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)

		if not advanced then
			break
		end
	end

	globalRankRefreshRunning = false
end

local function refreshBoards()
	for _, player in ipairs(Players:GetPlayers()) do
		safeSetOrdered(killsStore, player, getNumberAttribute(player, "Kills"))
		safeSetOrdered(robuxStore, player, getNumberAttribute(player, "RobuxSpent"))
		safeSetOrdered(wealthStore, player, getNumberAttribute(player, "Cash"))
	end

	task.wait(0.25)

	local kills = getTopEntries(killsStore)
	local robux = getTopEntries(robuxStore)
	local wealth = getTopEntries(wealthStore)

	if #kills == 0 then
		kills = getTopEntriesFallback("Kills")
	end

	if #robux == 0 then
		robux = getTopEntriesFallback("RobuxSpent")
	end

	if #wealth == 0 then
		wealth = getTopEntriesFallback("Cash")
	end

	for _, board in ipairs(activeBoards) do
		if board.name == "KillLeaderboard" then
			refreshBoard(board, kills)
		elseif board.name == "RobuxLeaderboard" then
			refreshBoard(board, robux)
		elseif board.name == "WealthLeaderboard" then
			refreshBoard(board, wealth)
		end
	end

	refreshGlobalRanks()

	print("🏆 POTATIUM LEADERBOARDS REFRESHED")
end

function LeaderboardService.Start(world)
	if started then
		return
	end

	started = true

	if not world then
		warn("❌ LeaderboardService received no world")
		return
	end

	local count = discoverBoards(world)

	if count <= 0 then
		warn("⚠ No custom leaderboard boards found inside PotatoWorld")
	else
		print("🏆 Discovered " .. tostring(count) .. " Potatium leaderboard board(s)")
	end

	for _, board in ipairs(activeBoards) do
		buildBoardGui(board)
	end

	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		task.spawn(savePersistentStat, killsDataStore, player, "Kills")
		task.spawn(savePersistentStat, robuxDataStore, player, "RobuxSpent")
		task.spawn(safeSetOrdered, wealthStore, player, getNumberAttribute(player, "Cash"))
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(setupPlayer, player)
	end

	task.delay(3, function()
		if started then
			refreshBoards()
		end
	end)

	task.spawn(function()
		while started do
			task.wait(REFRESH_SECONDS)
			refreshBoards()
		end
	end)

	-- Global rank is based on the player's Cash in the global wealth OrderedDataStore.
	-- Keep this separate from the board refresh so the HUD rank updates more often.
	task.spawn(function()
		task.wait(5)
		while started do
			for _, player in ipairs(Players:GetPlayers()) do
				safeSetOrdered(wealthStore, player, getNumberAttribute(player, "Cash"))
			end

			refreshGlobalRanks()
			task.wait(GLOBAL_RANK_REFRESH_SECONDS)
		end
	end)

	print("========================================")
	print("🏆 POTATIUM CUSTOM LEADERBOARDS V3")
	print("========================================")
	print("⚔ KillLeaderboard")
	print("💎 RobuxLeaderboard")
	print("💰 WealthLeaderboard")
	print("✅ Existing physical boards used")
	print("✅ SurfaceGui display enabled")
	print("✅ 10 rows per board")
	print("✅ Wealth uses Cash")
	print("✅ GlobalRank attribute enabled")
	print("✅ DataStore + Studio fallback")
	print("========================================")
end

return LeaderboardService
