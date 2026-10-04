--==================================================
-- POTATIUM - HOTBAR SERVICE V2
-- Persistent Roblox native 1-9,0 hotbar layout.
-- Exact slot order is saved and restored.
--==================================================

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MAX_SLOTS = 10
local MAX_RETRIES = 5
local RETRY_DELAY = 0.75

local storeName = RunService:IsStudio()
	and "PotatiumHotbar_DEV_v1"
	or "PotatiumHotbar_LIVE_v1"

local hotbarStore = DataStoreService:GetDataStore(storeName)

local remotes = ReplicatedStorage:FindFirstChild("PotatiumHotbarRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "PotatiumHotbarRemotes"
	remotes.Parent = ReplicatedStorage
end

local getHotbar = remotes:FindFirstChild("GetHotbar")
if not getHotbar then
	getHotbar = Instance.new("RemoteFunction")
	getHotbar.Name = "GetHotbar"
	getHotbar.Parent = remotes
end

local setHotbar = remotes:FindFirstChild("SetHotbar")
if not setHotbar then
	setHotbar = Instance.new("RemoteEvent")
	setHotbar.Name = "SetHotbar"
	setHotbar.Parent = remotes
end

-- player -> exact native 1-9,0 slot array
local playerSlots = {}
local loadedPlayers = {}
local dirtyPlayers = {}
local saveInProgress = {}
local changeVersions = {}

local function makeDefaultSlots()
	local slots = table.create(MAX_SLOTS)
	for index = 1, MAX_SLOTS do
		slots[index] = ""
	end
	return slots
end

local function copySlots(slots)
	local copy = table.create(MAX_SLOTS)
	for index = 1, MAX_SLOTS do
		copy[index] = (slots and slots[index]) or ""
	end
	return copy
end

local function slotsToText(slots)
	local parts = table.create(MAX_SLOTS)
	for index = 1, MAX_SLOTS do
		local value = slots[index]
		parts[index] = tostring(value == "" and "EMPTY" or value)
	end
	return table.concat(parts, " | ")
end

local function isValidHotbarKey(key)
	if key == "" then
		return true
	end

	if type(key) ~= "string" then
		return false
	end

	if #key > 180 then
		return false
	end

	return key:match("^(Potato_|Hoe_|Crate_|Tool_)") ~= nil
end

local function normalizeSlots(raw)
	local slots = makeDefaultSlots()

	if type(raw) ~= "table" then
		return slots
	end

	for index = 1, MAX_SLOTS do
		local key = raw[index]
		if isValidHotbarKey(key) then
			slots[index] = key
		end
	end

	return slots
end

local function applySlotAttributes(player, slots)
	for index = 1, MAX_SLOTS do
		player:SetAttribute(
			"HotbarSlot" .. tostring(index),
			slots[index] or ""
		)
	end
end

local function markDirty(player)
	dirtyPlayers[player] = true
end

local function savePlayer(player, reason, allowRemoving)
	if not player then
		return false
	end

	if not loadedPlayers[player] then
		warn("⚠ HOTBAR NOT SAVED: data was never successfully loaded for " .. player.Name)
		return false
	end

	if not allowRemoving and not player.Parent then
		return false
	end

	if saveInProgress[player] then
		return false
	end

	local slots = copySlots(playerSlots[player])
	local versionAtStart = changeVersions[player] or 0
	saveInProgress[player] = true

	local saved = false
	local lastError = nil

	for attempt = 1, MAX_RETRIES do
		local success, err = pcall(function()
			hotbarStore:SetAsync(
				tostring(player.UserId),
				slots
			)
		end)

		if success then
			saved = true
			break
		end

		lastError = err
		task.wait(RETRY_DELAY * attempt)
	end

	saveInProgress[player] = nil

	if saved then
		-- A second drag may have happened while this save was running.
		-- Keep the dirty flag in that case so the newest layout is saved too.
		if (changeVersions[player] or 0) == versionAtStart then
			dirtyPlayers[player] = nil
		else
			dirtyPlayers[player] = true
			task.spawn(function()
				savePlayer(player, "newer-change", false)
			end)
		end
		print(
			"💾 HOTBAR SAVED [" .. tostring(reason or "unknown") .. "] "
			.. player.Name
			.. " | "
			.. slotsToText(slots)
		)
		return true
	end

	warn(
		"❌ HOTBAR SAVE FAILED "
			.. player.Name
			.. " | "
			.. tostring(lastError)
	)
	return false
end

local function loadPlayer(player)
	loadedPlayers[player] = false
	player:SetAttribute("HotbarLoaded", false)
	player:SetAttribute("HotbarPersistenceAvailable", false)

	local loaded = false
	local data = nil
	local lastError = nil

	for attempt = 1, MAX_RETRIES do
		local success, result = pcall(function()
			return hotbarStore:GetAsync(tostring(player.UserId))
		end)

		if success then
			data = result
			loaded = true
			break
		end

		lastError = result
		warn(
			"⚠ HOTBAR LOAD ATTEMPT "
				.. tostring(attempt)
				.. "/"
				.. tostring(MAX_RETRIES)
				.. " failed for "
				.. player.Name
				.. ": "
				.. tostring(result)
		)
		task.wait(RETRY_DELAY * attempt)
	end

	local slots = normalizeSlots(data)
	playerSlots[player] = slots
	applySlotAttributes(player, slots)

	-- If DataStore access failed, allow the player to use the hotbar in
	-- this session, but NEVER save the default empty array over their
	-- previous data. Once DataStore works again, the next join will load it.
	loadedPlayers[player] = true
	player:SetAttribute("HotbarLoaded", true)
	player:SetAttribute("HotbarPersistenceAvailable", loaded)

	if loaded then
		print(
			"📥 HOTBAR LOADED "
			.. player.Name
			.. " | "
			.. slotsToText(slots)
		)
	else
		warn(
			"❌ HOTBAR DATASTORE UNAVAILABLE for "
			.. player.Name
			.. ". Session hotbar will work, but it will NOT overwrite saved data. Last error: "
			.. tostring(lastError)
		)
	end

	print("🔥 HOTBAR READY: " .. player.Name)
end

getHotbar.OnServerInvoke = function(player)
	local started = os.clock()

	while player.Parent and player:GetAttribute("HotbarLoaded") ~= true do
		if os.clock() - started > 15 then
			break
		end
		task.wait(0.05)
	end

	return copySlots(playerSlots[player] or makeDefaultSlots())
end

setHotbar.OnServerEvent:Connect(function(player, rawSlots)
	if player:GetAttribute("HotbarLoaded") ~= true then
		warn("⚠ Ignored hotbar update before load: " .. player.Name)
		return
	end

	local slots = normalizeSlots(rawSlots)
	playerSlots[player] = slots
	applySlotAttributes(player, slots)
	changeVersions[player] = (changeVersions[player] or 0) + 1
	markDirty(player)

	print(
		"📝 HOTBAR UPDATE "
		.. player.Name
		.. " | "
		.. slotsToText(slots)
	)

	-- Save immediately. There are only 10 strings, and exact persistence is
	-- more important here than batching multiple drag operations together.
	if player:GetAttribute("HotbarPersistenceAvailable") == true then
		task.spawn(function()
			savePlayer(player, "change", false)
		end)
	else
		warn(
			"⚠ Hotbar changed for "
			.. player.Name
			.. " but DataStore is unavailable; change is session-only."
		)
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		loadPlayer(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	if loadedPlayers[player] and player:GetAttribute("HotbarPersistenceAvailable") == true then
		-- PlayerRemoving is our final persistence point. Do not reject the
		-- save just because Roblox has started removing the Player instance.
		savePlayer(player, "leave", true)
	end

	playerSlots[player] = nil
	loadedPlayers[player] = nil
	dirtyPlayers[player] = nil
	saveInProgress[player] = nil
	changeVersions[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		loadPlayer(player)
	end)
end

game:BindToClose(function()
	local players = Players:GetPlayers()

	for _, player in ipairs(players) do
		if loadedPlayers[player] and player:GetAttribute("HotbarPersistenceAvailable") == true then
			task.spawn(function()
				savePlayer(player, "shutdown", true)
			end)
		end
	end

	task.wait(8)
end)

print("")
print("========================================")
print("🔥 POTATIUM HOTBAR SERVICE V2")
print("========================================")
print("Store: " .. storeName)
print("✅ Exact 1-9,0 native layout persistence")
print("✅ Immediate save after every change")
print("✅ Save again on leave/shutdown")
print("✅ Load retries")
print("✅ Failed loads never overwrite old data")
print("========================================")
