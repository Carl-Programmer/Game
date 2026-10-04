local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

--==================================================
-- FARM MONEY SERVICE V6 - CURRENT POTATO INCOME
-- + OFFLINE COLLECTION - DUPLICATE FIX
--
-- ✅ New potato MoneyPerSecond values supported
-- ✅ Legacy rarity income still supported
-- ✅ Rainbow = $100/sec
-- ✅ Super = $80/sec
-- ✅ Rainbow NEVER rotten
-- ✅ Super NEVER rotten
-- ✅ Rotten normal potatoes stop money
-- ✅ Collector persists
-- ✅ Walk onto pad to collect
-- ✅ Owner only
-- ✅ Offline income = 50%
-- ✅ Offline cap = 12 hours
-- ✅ Offline rot is respected
-- ✅ Lucky / Big / Clover never rot
--
-- IMPORTANT FIX:
-- ✅ Offline payout is locked immediately
-- ✅ Duplicate restore calls cannot pay twice
-- ✅ DataLoaded no longer resets the offline payout lock
--==================================================

local DataService =
	require(
		script.Parent:WaitForChild(
			"DataService"
		)
	)

local RarityService =
	require(
		script.Parent:WaitForChild(
			"RarityService"
		)
	)

--==================================================
-- SETTINGS
--==================================================

local MONEY_TICK_TIME = 1
local PAD_SCAN_TIME = 0.15

local OFFLINE_INCOME_MULTIPLIER = 0.50
local MAX_OFFLINE_SECONDS = 12 * 60 * 60

-- These Meadow potatoes never rot.
-- Sun-Kissed is intentionally NOT included yet.
local OFFLINE_NO_ROT_POTATO_TYPES = {
	["Lucky Potato"] = true,
	["Big Potato"] = true,
	["Clover Potato"] = true,
}

--==================================================
-- WORLD
--==================================================

local world =
	Workspace:WaitForChild(
		"PotatoWorld"
	)

local farmsFolder =
	world:WaitForChild(
		"Farms"
	)

--==================================================
-- PAD STATE
--==================================================

local playersOnPad = {}

--==================================================
-- FORMAT MONEY
--==================================================

local function formatMoney(amount)

	amount =
		math.floor(
			tonumber(amount)
				or
				0
		)

	local text =
		tostring(amount)

	while true do

		local newText,
			count =
				string.gsub(
					text,
					"^(-?%d+)(%d%d%d)",
					"%1,%2"
				)

		text =
			newText

		if count == 0 then
			break
		end

	end

	return "$" .. text

end

--==================================================
-- FARM OWNER
--==================================================

local function getFarmOwner(farm)

	local ownerUserId =
		farm:GetAttribute(
			"OwnerUserId"
		)

	if
		typeof(ownerUserId)
		~=
		"number"
	then

		return nil

	end

	if ownerUserId <= 0 then

		return nil

	end

	return
		Players:GetPlayerByUserId(
			ownerUserId
		)

end

--==================================================
-- FARM LANDS
--==================================================

local function getFarmLands(farm)

	return
		farm:FindFirstChild(
			"FarmLands"
		)

end

--==================================================
-- COLLECTOR
--==================================================

local function getCollector(farm)

	return
		farm:FindFirstChild(
			"MoneyCollector"
		)

end

--==================================================
-- COLLECTOR PAD
--==================================================

local function getCollectorPad(farm)

	local collector =
		getCollector(farm)

	if not collector then
		return nil
	end

	local pad =
		collector:FindFirstChild(
			"CollectorPad",
			true
		)

	if
		pad
		and
		pad:IsA("BasePart")
	then

		pad.CanQuery = true
		pad.CanTouch = true

		return pad

	end

	return nil

end

--==================================================
-- REMOVE OLD E PROMPT
--==================================================

local function removeOldPrompt(farm)

	local pad =
		getCollectorPad(farm)

	if not pad then
		return
	end

	local prompt =
		pad:FindFirstChild(
			"CollectMoneyPrompt"
		)

	if prompt then

		prompt:Destroy()

	end

end

--==================================================
-- STORED MONEY
--==================================================

local function getStoredMoney(farm)

	local collector =
		getCollector(farm)

	if not collector then
		return 0
	end

	local value =
		collector:GetAttribute(
			"StoredMoney"
		)

	if typeof(value) ~= "number" then

		return 0

	end

	return
		math.max(
			0,
			value
		)

end

local function setStoredMoney(
	farm,
	amount
)

	local collector =
		getCollector(farm)

	if not collector then
		return
	end

	amount =
		math.max(
			0,
			tonumber(amount)
				or
				0
		)

	collector:SetAttribute(
		"StoredMoney",
		amount
	)

end

--==================================================
-- SAVE COLLECTOR
--==================================================

local function saveCollectorMoney(
	player,
	farm
)

	if not player then
		return
	end

	if
		player:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	then

		return

	end

	local upgrades =
		DataService.GetUpgrades(
			player
		)

	upgrades.FarmEconomy =
		upgrades.FarmEconomy
		or
		{}

	upgrades.FarmEconomy.StoredMoney =
		getStoredMoney(
			farm
		)

	DataService.SetUpgrades(
		player,
		upgrades
	)

end

--==================================================
-- RESTORE COLLECTOR
--==================================================

local function restoreCollectorMoney(
	player,
	farm
)

	if not player then
		return
	end

	if
		player:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	then

		return

	end

	local upgrades =
		DataService.GetUpgrades(
			player
		)

	local storedMoney = 0

	if
		type(
			upgrades.FarmEconomy
		)
		==
		"table"
	then

		storedMoney =
			tonumber(
				upgrades
					.FarmEconomy
					.StoredMoney
			)
			or
			0

	end

	setStoredMoney(
		farm,
		storedMoney
	)

	print(
		"💰 Restored collector: "
			..
			player.Name
			..
			" | "
			..
			formatMoney(
				storedMoney
			)
	)

end

--==================================================
-- GET POTATO RARITY
--==================================================

local function getFarmLandRarity(
	farmLand
)

	local rarity =
		farmLand:GetAttribute(
			"Rarity"
		)

	if
		type(rarity)
		==
		"string"
	then

		return rarity

	end

	local placedPotato =
		farmLand:FindFirstChild(
			"PlacedPotato"
		)

	if placedPotato then

		local placedRarity =
			placedPotato:GetAttribute(
				"Rarity"
			)

		if
			type(placedRarity)
			==
			"string"
		then

			return placedRarity

		end

	end

	return "Common"

end

--==================================================
-- NO ROT CHECK
--
-- IMPORTANT:
-- Rainbow and Super can NEVER be rotten.
--==================================================

local function hasNoRot(
	farmLand
)

	-- New placement system attribute.

	if
		farmLand:GetAttribute(
			"RotImmune"
		)
		==
		true
	then

		return true

	end

	-- Fallback using rarity.

	local rarity =
		getFarmLandRarity(
			farmLand
		)

	if rarity == "Super" then

		return true

	end

	if rarity == "Rainbow" then

		return true

	end

	-- Use RarityService too if available.

	if
		type(
			RarityService.HasNoRot
		)
		==
		"function"
	then

		if
			RarityService.HasNoRot(
				rarity
			)
		then

			return true

		end

	end

	return false

end

--==================================================
-- ROTTEN CHECK
--==================================================

local function isRotten(
	farmLand
)

	--==================================================
	-- SUPER / RAINBOW
	--
	-- ALWAYS check this FIRST.
	--==================================================

	if hasNoRot(
		farmLand
	) then

		return false

	end

	--==================================================
	-- EXPLICIT ROTTEN STATE
	--==================================================

	if
		farmLand:GetAttribute(
			"IsRotten"
		)
		==
		true
	then

		return true

	end

	--==================================================
	-- ROT TIME
	--==================================================

	local rotAt =
		farmLand:GetAttribute(
			"RotAt"
		)

	if
		typeof(rotAt)
		~=
		"number"
	then

		return false

	end

	--==================================================
	-- VERY IMPORTANT
	--
	-- RotAt = 0 means NO ACTIVE TIMER.
	--
	-- Old code did:
	--
	-- os.time() >= 0
	--
	-- which is ALWAYS TRUE.
	--==================================================

	if rotAt <= 0 then

		return false

	end

	return
		os.time()
		>=
		rotAt

end

--==================================================
-- GET SAVED POTATO INCOME
--
-- New Meadow potatoes already save their intended
-- MoneyPerSecond in DataService.
--==================================================

local function getSavedPotatoIncome(
	farmLand
)

	local potatoId =
		farmLand:GetAttribute(
			"PotatoId"
		)

	if potatoId == nil then
		return nil
	end

	local farmLands =
		farmLand.Parent

	local farm =
		farmLands
		and
		farmLands.Parent

	if
		not farm
		or
		not farm:IsA("Model")
	then

		return nil

	end

	local owner =
		getFarmOwner(
			farm
		)

	if not owner then
		return nil
	end

	local record =
		DataService.GetPotatoRecord(
			owner,
			potatoId
		)

	if not record then
		return nil
	end

	local savedIncome =
		tonumber(
			record.MoneyPerSecond
		)

	if
		savedIncome
		and
		savedIncome > 0
	then

		return savedIncome

	end

	return nil

end

--==================================================
-- GET ONE PLOT INCOME
--==================================================

local function getPlotIncome(
	farmLand
)

	--==================================================
	-- EMPTY
	--==================================================

	if
		farmLand:GetAttribute(
			"Occupied"
		)
		~=
		true
	then

		farmLand:SetAttribute(
			"MoneyPerSecond",
			0
		)

		return 0

	end

	--==================================================
	-- RARITY
	--==================================================

	local rarity =
		getFarmLandRarity(
			farmLand
		)

	--==================================================
	-- SUPER / RAINBOW
	--==================================================

	if hasNoRot(
		farmLand
	) then

		farmLand:SetAttribute(
			"RotImmune",
			true
		)

		farmLand:SetAttribute(
			"IsRotten",
			false
		)

	end

	--==================================================
	-- NORMAL ROTTEN POTATO
	--==================================================

	if
		isRotten(
			farmLand
		)
	then

		farmLand:SetAttribute(
			"MoneyPerSecond",
			0
		)

		return 0

	end

	--==================================================
	-- INCOME
	--==================================================

	-- New potato system:
	-- use the exact saved income first.
	--
	-- Legacy potatoes:
	-- fall back to the old rarity table.

	local income =
		getSavedPotatoIncome(
			farmLand
		)

	if income == nil then

		income =
			RarityService.GetIncomeMultiplier(
				rarity
			)

	end

	income =
		math.max(
			0,
			tonumber(
				income
			)
				or
				0
		)

	farmLand:SetAttribute(
		"MoneyPerSecond",
		income
	)

	return income

end

--==================================================
-- TOTAL FARM INCOME
--==================================================

local function getFarmIncome(
	farm
)

	local farmLands =
		getFarmLands(
			farm
		)

	if not farmLands then

		return 0

	end

	local totalIncome = 0

	for _, farmLand in ipairs(
		farmLands:GetChildren()
	) do

		if
			farmLand:IsA(
				"Model"
			)
		then

			totalIncome +=
				getPlotIncome(
					farmLand
				)

		end

	end

	return totalIncome

end

--==================================================
-- COLLECT MONEY
--==================================================

local function collectMoney(
	player,
	farm
)

	local owner =
		getFarmOwner(
			farm
		)

	if owner ~= player then

		return

	end

	if
		player:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	then

		return

	end

	local storedMoney =
		getStoredMoney(
			farm
		)

	if storedMoney <= 0 then

		return

	end

	local collectedAmount =
		math.floor(
			storedMoney
		)

	if collectedAmount <= 0 then

		return

	end

	local currentCash =
		player:GetAttribute(
			"Cash"
		)
		or
		0

	player:SetAttribute(
		"Cash",
		currentCash
			+
			collectedAmount
	)

	setStoredMoney(
		farm,
		0
	)

	saveCollectorMoney(
		player,
		farm
	)

	print(
		"💵 PAD COLLECTED: "
			..
			player.Name
			..
			" | "
			..
			formatMoney(
				collectedAmount
			)
	)

end

--==================================================
-- PLAYER FROM PART
--==================================================

local function getPlayerFromPart(
	part
)

	if not part then
		return nil
	end

	local character =
		part:FindFirstAncestorOfClass(
			"Model"
		)

	if not character then

		return nil

	end

	if
		not character:FindFirstChildOfClass(
			"Humanoid"
		)
	then

		return nil

	end

	return
		Players:GetPlayerFromCharacter(
			character
		)

end

--==================================================
-- PLAYERS ON PAD
--==================================================

local function getPlayersOnPad(
	pad
)

	local result = {}

	local touchingParts =
		Workspace:GetPartsInPart(
			pad
		)

	for _, part in ipairs(
		touchingParts
	) do

		local player =
			getPlayerFromPart(
				part
			)

		if player then

			result[
				player
			] =
				true

		end

	end

	return result

end

--==================================================
-- SCAN COLLECTOR
--==================================================

local function scanCollectorPad(
	farm
)

	local pad =
		getCollectorPad(
			farm
		)

	if not pad then
		return
	end

	playersOnPad[
		pad
	] =
		playersOnPad[
			pad
		]
		or
		{}

	local previous =
		playersOnPad[
			pad
		]

	local currentlyOnPad =
		getPlayersOnPad(
			pad
		)

	for player in pairs(
		currentlyOnPad
	) do

		if
			not previous[
				player
			]
		then

			collectMoney(
				player,
				farm
			)

		end

	end

	playersOnPad[
		pad
	] =
		currentlyOnPad

end

--==================================================
-- OFFLINE COLLECTION
--==================================================

local function getOfflinePotatoIncome(
	player,
	farm,
	lastLogoutAt,
	now
)

	if not player or not farm then
		return 0
	end

	lastLogoutAt =
		tonumber(
			lastLogoutAt
		)
		or
		0

	if lastLogoutAt <= 0 then
		return 0
	end

	now =
		tonumber(
			now
		)
		or
		os.time()

	local elapsed =
		math.clamp(
			now - lastLogoutAt,
			0,
			MAX_OFFLINE_SECONDS
		)

	if elapsed <= 0 then
		return 0
	end

	local inventory =
		DataService.GetPotatoInventory(
			player
		)

	local total = 0

	for _, record in ipairs(
		inventory
	) do

		if
			tostring(
				record.PlacedFarm
				or
				""
			)
			==
			farm.Name
		then

			if
				record.IsRotten
				~=
				true
			then

				local income =
					tonumber(
						record.MoneyPerSecond
					)
					or
					0

				if income <= 0 then

					income =
						RarityService.GetIncomeMultiplier(
							tostring(
								record.Rarity
								or
								"Common"
							)
						)
						or
						0

				end

				local potatoName =
					tostring(
						record.DisplayName
						or
						record.PotatoType
						or
						""
					)

				local earnSeconds =
					elapsed

				--==================================================
				-- NO ROT POTATO
				--==================================================

				if
					not OFFLINE_NO_ROT_POTATO_TYPES[
						potatoName
					]
				then

					local rotAt =
						tonumber(
							record.RotAt
						)
						or
						0

					if rotAt > 0 then

						earnSeconds =
							math.clamp(
								math.min(
									now,
									rotAt
								)
									-
									lastLogoutAt,
								0,
								elapsed
							)

					elseif
						record.IsRotten
						==
						true
					then

						earnSeconds = 0

					end

				end

				if
					income > 0
					and
					earnSeconds > 0
				then

					total +=
						income
						*
						earnSeconds

				end

			end

		end

	end

	return
		total
		*
		OFFLINE_INCOME_MULTIPLIER

end

--==================================================
-- APPLY OFFLINE INCOME
--==================================================

local function applyOfflineIncome(
	player,
	farm
)

	if not player or not farm then
		return 0
	end

	--==================================================
	-- DUPLICATE FIX #1
	--
	-- If this player already received offline income
	-- for this farm, NEVER apply it again.
	--==================================================

	local appliedUserId =
		farm:GetAttribute(
			"OfflineIncomeAppliedUserId"
		)

	if
		typeof(appliedUserId)
		==
		"number"
		and
		appliedUserId
		==
		player.UserId
	then

		return 0

	end

	--==================================================
	-- DUPLICATE FIX #2
	--
	-- Lock BEFORE calculating the payout.
	--
	-- This protects against multiple restore paths
	-- trying to apply the same payout at the same time.
	--==================================================

	local applyingUserId =
		farm:GetAttribute(
			"OfflineIncomeApplyingUserId"
		)

	if
		typeof(applyingUserId)
		==
		"number"
		and
		applyingUserId
		==
		player.UserId
	then

		return 0

	end

	farm:SetAttribute(
		"OfflineIncomeApplyingUserId",
		player.UserId
	)

	--==================================================
	-- CALCULATE OFFLINE PAYOUT
	--==================================================

	local lastLogoutAt =
		DataService.GetLastLogoutAt(
			player
		)

	local now =
		os.time()

	local amount =
		getOfflinePotatoIncome(
			player,
			farm,
			lastLogoutAt,
			now
		)

	--==================================================
	-- ADD OFFLINE MONEY
	--==================================================

	if amount > 0 then

		setStoredMoney(
			farm,
			getStoredMoney(
				farm
			)
				+
				amount
		)

		print(
			"💤 OFFLINE COLLECTION: "
				..
				player.Name
				..
				" | "
				..
				formatMoney(
					amount
				)
				..
				" | 50% | cap 12h"
		)

	else

		print(
			"💤 OFFLINE COLLECTION: "
				..
				player.Name
				..
				" | $0"
		)

	end

	--==================================================
	-- SAVE
	--==================================================

	saveCollectorMoney(
		player,
		farm
	)

	--==================================================
	-- MARK AS APPLIED
	--
	-- This must happen BEFORE another restore path
	-- is allowed to reset anything.
	--==================================================

	farm:SetAttribute(
		"OfflineIncomeAppliedUserId",
		player.UserId
	)

	--==================================================
	-- CLEAR IN-PROGRESS LOCK
	--==================================================

	farm:SetAttribute(
		"OfflineIncomeApplyingUserId",
		0
	)

	return amount

end

--==================================================
-- RESTORE FARM
--==================================================

local function tryRestoreFarm(
	farm
)

	local owner =
		getFarmOwner(
			farm
		)

	if not owner then

		return

	end

	if
		owner:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	then

		return

	end

	--==================================================
	-- DUPLICATE PROTECTION
	--
	-- If this player's farm has already been restored,
	-- don't restore it again.
	--==================================================

	local restoredUserId =
		farm:GetAttribute(
			"MoneyRestoredUserId"
		)

	if
		typeof(restoredUserId)
		==
		"number"
		and
		restoredUserId
		==
		owner.UserId
	then

		return

	end

	--==================================================
	-- RESTORE SAVED COLLECTOR
	--==================================================

	restoreCollectorMoney(
		owner,
		farm
	)

	--==================================================
	-- APPLY OFFLINE INCOME
	--==================================================

	applyOfflineIncome(
		owner,
		farm
	)

	--==================================================
	-- MARK FARM RESTORED
	--==================================================

	farm:SetAttribute(
		"MoneyRestoredUserId",
		owner.UserId
	)

end

--==================================================
-- INITIAL CLEANUP
--==================================================

for _, farm in ipairs(
	farmsFolder:GetChildren()
) do

	if farm:IsA(
		"Model"
	) then

		removeOldPrompt(
			farm
		)

	end

end

--==================================================
-- MONEY GENERATION LOOP
--==================================================

task.spawn(
	function()

		while true do

			for _, farm in ipairs(
				farmsFolder:GetChildren()
			) do

				if farm:IsA(
					"Model"
				) then

					tryRestoreFarm(
						farm
					)

					local owner =
						getFarmOwner(
							farm
						)

					if
						owner
						and
						owner:GetAttribute(
							"DataLoaded"
						)
						==
						true
					then

						local income =
							getFarmIncome(
								farm
							)

						if income > 0 then

							local currentMoney =
								getStoredMoney(
									farm
								)

							setStoredMoney(
								farm,
								currentMoney
									+
									income
							)

						end

						saveCollectorMoney(
							owner,
							farm
						)

					end

				end

			end

			task.wait(
				MONEY_TICK_TIME
			)

		end

	end
)

--==================================================
-- PAD LOOP
--==================================================

task.spawn(
	function()

		while true do

			for _, farm in ipairs(
				farmsFolder:GetChildren()
			) do

				if farm:IsA(
					"Model"
				) then

					scanCollectorPad(
						farm
					)

				end

			end

			task.wait(
				PAD_SCAN_TIME
			)

		end

	end
)

--==================================================
-- FARM OWNER CHANGE
--==================================================

for _, farm in ipairs(
	farmsFolder:GetChildren()
) do

	if farm:IsA(
		"Model"
	) then

		farm:GetAttributeChangedSignal(
			"OwnerUserId"
		):Connect(
			function()

				--==================================================
				-- NEW OWNER
				--
				-- These are intentionally reset here because
				-- this is a genuine ownership change.
				--==================================================

				farm:SetAttribute(
					"MoneyRestoredUserId",
					0
				)

				farm:SetAttribute(
					"OfflineIncomeAppliedUserId",
					0
				)

				farm:SetAttribute(
					"OfflineIncomeApplyingUserId",
					0
				)

				setStoredMoney(
					farm,
					0
				)

				local pad =
					getCollectorPad(
						farm
					)

				if pad then

					playersOnPad[
						pad
					] =
						{}

				end

				task.delay(
					0.5,
					function()

						tryRestoreFarm(
							farm
						)

					end
				)

			end
		)

	end

end

--==================================================
-- PLAYER DATA READY
--==================================================

local function setupPlayer(
	player
)

	player:GetAttributeChangedSignal(
		"DataLoaded"
	):Connect(
		function()

			if
				player:GetAttribute(
					"DataLoaded"
				)
				==
				true
			then

				task.delay(
					0.5,
					function()

						for _, farm in ipairs(
							farmsFolder:GetChildren()
						) do

							if
								farm:IsA(
									"Model"
								)
								and
								farm:GetAttribute(
									"OwnerUserId"
								)
								==
								player.UserId
							then

								--==================================================
								-- IMPORTANT FIX
								--
								-- DO NOT RESET:
								--
								-- OfflineIncomeAppliedUserId
								--
								-- Doing that here allowed a second offline payout
								-- after the first restore had already happened.
								--
								-- The OwnerUserId handler resets these when a
								-- genuinely new owner receives the farm.
								--==================================================

								tryRestoreFarm(
									farm
								)

							end

						end

					end
				)

			end

		end
	)

end

Players.PlayerAdded:Connect(
	setupPlayer
)

for _, player in ipairs(
	Players:GetPlayers()
) do

	setupPlayer(
		player
	)

end

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("💰 FARM MONEY SERVICE V6 - OFFLINE DUPLICATE FIX")
print("========================================")
print("✅ New Meadow potatoes use saved MoneyPerSecond")
print("✅ Legacy potatoes still use rarity income")
print("✅ Common    = $1/sec")
print("✅ Rare      = $4/sec")
print("✅ Epic      = $8/sec")
print("✅ Exotic    = $15/sec")
print("✅ Legendary = $25/sec")
print("⭐ Super     = $80/sec | NO ROT")
print("🌈 Rainbow   = $100/sec | NO ROT")
print("----------------------------------------")
print("💤 Offline income = 50% | Max = 12 hours")
print("🥔 Offline rot is respected")
print("🍀 Lucky / Big / Clover = NO ROT")
print("✅ RotAt = 0 is NOT rotten")
print("✅ Super cannot rot")
print("✅ Rainbow cannot rot")
print("✅ Rotten normal potatoes stop money")
print("✅ Walk onto CollectorPad to collect")
print("✅ Collector persists")
print("----------------------------------------")
print("🔒 Offline payout lock enabled")
print("🔒 Duplicate restore protection enabled")
print("🔒 DataLoaded no longer resets offline payout")
print("========================================")
print("")