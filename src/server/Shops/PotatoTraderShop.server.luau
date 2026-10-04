local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--==================================================
-- POTATIUM - POTATO TRADER SHOP V2
--
-- Shop #1 of 4.
--
-- ✅ E prompt sells ALL UNFAVORITED potatoes
-- ✅ Favorited potatoes are protected
-- ✅ Placed potatoes are protected
-- ✅ Server calculates the money
-- ✅ Current MeadowPool BaseSellPrice is used
-- ✅ KG sell formula applied
-- ✅ Old ShopService can stay disabled
--==================================================

local serverFolder = script.Parent

-- If this script is inside Server/Shops, move up one level.
if serverFolder.Name == "Shops" then
	serverFolder = serverFolder.Parent
end

local DataService = require(serverFolder:WaitForChild("DataService"))
local MeadowPool = require(
	serverFolder
		:WaitForChild("ForagingPools")
		:WaitForChild("MeadowPool")
)

--==================================================
-- SETTINGS
--==================================================

local PROMPT_ACTION_TEXT = "Sell Unfavorited"
local PROMPT_OBJECT_TEXT = "Potato Trader"
local PROMPT_HOLD_DURATION = 0.6
local PROMPT_DISTANCE = 14
local SELL_COOLDOWN = 0.75

--==================================================
-- REMOTES
--
-- BackpackClient tells the server when a potato heart
-- is toggled. Favorites remain session-only for now.
--==================================================

local remotes = ReplicatedStorage:FindFirstChild("PotatoTraderRemotes")

if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "PotatoTraderRemotes"
	remotes.Parent = ReplicatedStorage
end

local function getRemote(name)
	local remote = remotes:FindFirstChild(name)

	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	if remote then
		remote:Destroy()
	end

	remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes

	return remote
end

local SetFavorite = getRemote("SetFavorite")

--==================================================
-- SESSION FAVORITES
--
-- [player] = {
--     ["123"] = true,
-- }
--==================================================

local favoritePotatoes = {}
local lastSellTime = {}

local function getFavoriteTable(player)
	local tableForPlayer = favoritePotatoes[player]

	if not tableForPlayer then
		tableForPlayer = {}
		favoritePotatoes[player] = tableForPlayer
	end

	return tableForPlayer
end

local function findRecordById(player, potatoId)
	local wantedId = tostring(potatoId)

	for _, record in ipairs(DataService.GetPotatoInventory(player)) do
		if tostring(record.Id) == wantedId then
			return record
		end
	end

	return nil
end

SetFavorite.OnServerEvent:Connect(function(player, potatoId, isFavorite)
	if player:GetAttribute("DataLoaded") ~= true then
		return
	end

	if potatoId == nil then
		return
	end

	-- Make sure the PotatoId actually belongs to this player.
	local record = findRecordById(player, potatoId)

	if not record then
		return
	end

	local favorites = getFavoriteTable(player)
	local key = tostring(record.Id)

	if isFavorite == true then
		favorites[key] = true
	else
		favorites[key] = nil
	end
end)

--==================================================
-- POTATO NAME / PRICE
--==================================================

local function getPoolName(record)
	local potatoType = tostring(record.PotatoType or "Normal")

	if string.lower(string.sub(potatoType, -6)) == "potato" then
		return potatoType
	end

	return potatoType .. " Potato"
end

local function getSellValue(record)
	local potatoName = getPoolName(record)
	local potatoData = MeadowPool.GetByName(potatoName)

	-- Do NOT destroy unknown / legacy potatoes.
	if not potatoData then
		return nil, potatoName
	end

	local baseValue = math.max(
		0,
		tonumber(
			potatoData.SellValue
		)
		or
		0
	)

	local savedBase = tonumber(record.BaseSellPrice)
	if savedBase and savedBase > 0 then
		baseValue = savedBase
	end

	local mass = tonumber(record.SpudMass)

	-- Meadow sell formula:
	-- Final Sell Price = (KG / 10) x Base Sell Price
	if mass and mass > 0 then
		local value = math.max(
			0,
			math.floor(
				(mass / 10) * baseValue
				+ 0.5
			)
		)

		return value, potatoName
	end

	-- Legacy fallback for records without KG.
	local multiplier = math.max(
		0,
		tonumber(
			potatoData.SellMultiplier
		)
		or
		1
	)

	local value = math.floor(
		baseValue * multiplier
		+ 0.5
	)

	return value, potatoName
end

--==================================================
-- SELL ALL UNFAVORITED
--==================================================

local function sellUnfavorited(player)
	if player:GetAttribute("DataLoaded") ~= true then
		return
	end

	local now = os.clock()
	local previous = lastSellTime[player] or 0

	if now - previous < SELL_COOLDOWN then
		return
	end

	lastSellTime[player] = now

	local records = DataService.GetPotatoInventory(player)
	local favorites = getFavoriteTable(player)

	local soldCount = 0
	local earned = 0
	local favoriteProtected = 0
	local placedProtected = 0
	local unknownProtected = 0

	for _, record in ipairs(records) do
		local id = record.Id
		local key = tostring(id)

		--==================================================
		-- PROTECT FAVORITES
		--==================================================

		if favorites[key] == true then
			favoriteProtected += 1
			continue
		end

		--==================================================
		-- PROTECT POTATOES CURRENTLY PLACED ON A FARM
		--==================================================

		local placedFarm = tostring(record.PlacedFarm or "")
		local placedSlot = tostring(record.PlacedSlot or "")

		if placedFarm ~= "" or placedSlot ~= "" then
			placedProtected += 1
			continue
		end

		--==================================================
		-- PRICE
		--==================================================

		local value, potatoName = getSellValue(record)

		if value == nil then
			unknownProtected += 1
			warn(
				"⚠ Potato Trader skipped unknown potato: "
					.. potatoName
					.. " | ID "
					.. key
			)
			continue
		end

		--==================================================
		-- REMOVE EXACT POTATO RECORD
		--==================================================

		local removed = DataService.RemovePotatoRecord(player, id)

		if removed then
			soldCount += 1
			earned += value

			-- No longer needs a favorite entry.
			favorites[key] = nil

			print(
				"💰 SOLD | "
					.. player.Name
					.. " | "
					.. potatoName
					.. " | $"
					.. tostring(value)
			)
		end
	end

	--==================================================
	-- UPDATE POTATO TOTAL
	--==================================================

	if soldCount > 0 then
		local currentPotatoes = player:GetAttribute("Potatoes") or 0

		player:SetAttribute(
			"Potatoes",
			math.max(0, currentPotatoes - soldCount)
		)

		--==================================================
		-- PAY PLAYER
		-- Cash is already watched/saved by DataService.
		--==================================================

		local cash = player:GetAttribute("Cash") or 0
		player:SetAttribute("Cash", cash + earned)
	end

	print("")
	print("========================================")
	print("💰 POTATO TRADER SALE")
	print("========================================")
	print("Player: " .. player.Name)
	print("Sold: " .. tostring(soldCount))
	print("Earned: $" .. tostring(earned))
	print("❤️ Favorites protected: " .. tostring(favoriteProtected))
	print("🌱 Placed protected: " .. tostring(placedProtected))
	print("🛡 Unknown/legacy protected: " .. tostring(unknownProtected))
	print("========================================")
	print("")
end

--==================================================
-- SELL PROMPT PART
--
-- IMPORTANT:
-- We no longer try to find the visual Potato Trader model.
-- The shop builder can rename/rebuild that model.
--
-- Instead, place ONE invisible BasePart anywhere in Workspace
-- and name it EXACTLY:
--
--     SellPromptPart
--
-- Recommended parent:
-- Workspace > PotatoWorld > SellPromptPart
--
-- This loop also survives the town being rebuilt at runtime.
--==================================================

local function findSellPromptPart()
	local found = Workspace:FindFirstChild("SellPromptPart", true)

	if found and found:IsA("BasePart") then
		return found
	end

	return nil
end

local function attachPrompt(promptPart)
	local prompt = promptPart:FindFirstChild("SellUnfavoritedPrompt")

	if prompt and not prompt:IsA("ProximityPrompt") then
		prompt:Destroy()
		prompt = nil
	end

	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "SellUnfavoritedPrompt"
		prompt.Parent = promptPart

		prompt.Triggered:Connect(sellUnfavorited)
	end

	prompt.ActionText = PROMPT_ACTION_TEXT
	prompt.ObjectText = PROMPT_OBJECT_TEXT
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = PROMPT_HOLD_DURATION
	prompt.MaxActivationDistance = PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.ClickablePrompt = true
	prompt.Style = Enum.ProximityPromptStyle.Default

	return prompt
end

local announcedPart = nil
local warnedMissing = false

task.spawn(function()
	while true do
		local promptPart = findSellPromptPart()

		if promptPart then
			warnedMissing = false
			attachPrompt(promptPart)

			if announcedPart ~= promptPart then
				announcedPart = promptPart

				print("")
				print("========================================")
				print("🥔 POTATO TRADER SHOP V2")
				print("========================================")
				print("✅ SellPromptPart found:", promptPart:GetFullName())
				print("✅ E = Sell all unfavorited potatoes")
				print("❤️ Favorited potatoes protected")
				print("🌱 Placed potatoes protected")
				print("💰 MeadowPool BaseSellPrice + KG formula connected")
				print("========================================")
				print("")
			end
		else
			announcedPart = nil

			if not warnedMissing then
				warnedMissing = true
				warn("⚠ PotatoTraderShop V2 waiting for a BasePart named SellPromptPart")
			end
		end

		task.wait(1)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	favoritePotatoes[player] = nil
	lastSellTime[player] = nil
end)
