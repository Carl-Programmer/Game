--==================================================
-- POTATIUM INVENTORY FAVORITES
-- SERVER
--==================================================

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FavoriteStore = DataStoreService:GetDataStore("PotatiumInventoryFavorites_v1")

--==================================================
-- REMOTES
--==================================================

local Remotes = ReplicatedStorage:FindFirstChild("PotatiumInventoryRemotes")

if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "PotatiumInventoryRemotes"
	Remotes.Parent = ReplicatedStorage
end

local GetFavorites = Remotes:FindFirstChild("GetFavorites")

if not GetFavorites then
	GetFavorites = Instance.new("RemoteFunction")
	GetFavorites.Name = "GetFavorites"
	GetFavorites.Parent = Remotes
end

local SetFavorite = Remotes:FindFirstChild("SetFavorite")

if not SetFavorite then
	SetFavorite = Instance.new("RemoteEvent")
	SetFavorite.Name = "SetFavorite"
	SetFavorite.Parent = Remotes
end

--==================================================
-- CACHE
--==================================================

local favorites = {}

--==================================================
-- LOAD
--==================================================

local function loadFavorites(player)
	local key = "Player_" .. player.UserId

	local success, data = pcall(function()
		return FavoriteStore:GetAsync(key)
	end)

	if success and type(data) == "table" then
		favorites[player] = data
	else
		favorites[player] = {}
	end
end

--==================================================
-- SAVE
--==================================================

local function saveFavorites(player)
	local data = favorites[player]

	if not data then
		return
	end

	local key = "Player_" .. player.UserId

	local success, err = pcall(function()
		FavoriteStore:SetAsync(key, data)
	end)

	if not success then
		warn("[Inventory] Failed to save favorites:", err)
	end
end

--==================================================
-- PLAYER
--==================================================

Players.PlayerAdded:Connect(function(player)
	loadFavorites(player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveFavorites(player)

	favorites[player] = nil
end)

--==================================================
-- GET FAVORITES
--==================================================

GetFavorites.OnServerInvoke = function(player)
	if not favorites[player] then
		loadFavorites(player)
	end

	return favorites[player]
end

--==================================================
-- SET FAVORITE
--==================================================

SetFavorite.OnServerEvent:Connect(function(player, itemKey, value)
	if type(itemKey) ~= "string" then
		return
	end

	if type(value) ~= "boolean" then
		return
	end

	if not favorites[player] then
		favorites[player] = {}
	end

	if value then
		favorites[player][itemKey] = true
	else
		favorites[player][itemKey] = nil
	end
end)

--==================================================
-- AUTOSAVE
--==================================================

task.spawn(function()
	while true do
		task.wait(60)

		for _, player in ipairs(Players:GetPlayers()) do
			saveFavorites(player)
		end
	end
end)

--==================================================
-- SHUTDOWN
--==================================================

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveFavorites(player)
	end
end)
