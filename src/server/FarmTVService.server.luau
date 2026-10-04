local Workspace =
	game:GetService("Workspace")

--==================================================
-- FARM TV SERVICE V2
--
-- ✅ Final 7 rarities
-- ✅ Live small TV income
-- ✅ Live rot countdown
-- ✅ Super = NO ROT
-- ✅ Rainbow = NO ROT
-- ✅ RotAt = 0 is NOT rotten
-- ✅ Big TV updates quickly
-- ✅ Empty plots show EMPTY
--==================================================

local RarityService =
	require(
		script.Parent:WaitForChild(
			"RarityService"
		)
	)

--==================================================
-- SETTINGS
--==================================================

local SMALL_REFRESH =
	0.25

local BIG_REFRESH =
	0.25

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
-- FORMAT MONEY
--==================================================

local function formatNumber(
	amount
)

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

	return text

end

local function formatMoney(
	amount
)

	return
		"$"
		..
		formatNumber(
			amount
		)

end

--==================================================
-- FIND GUI
--==================================================

local function getTVGui(
	tv
)

	if not tv then
		return nil
	end

	local screen =
		tv:FindFirstChild(
			"Screen",
			true
		)

	if not screen then
		return nil
	end

	local gui =
		screen:FindFirstChild(
			"TVGui"
		)

	if gui then
		return gui
	end

	-- Fallback

	for _, object in ipairs(
		screen:GetDescendants()
	) do

		if
			object:IsA(
				"SurfaceGui"
			)
			or
			object:IsA(
				"BillboardGui"
			)
		then

			return object

		end

	end

	return nil

end

--==================================================
-- SMALL TV TEXT
--==================================================

local function getSmallTexts(
	tv
)

	local gui =
		getTVGui(
			tv
		)

	if not gui then

		return nil,
			nil

	end

	local rateText =
		gui:FindFirstChild(
			"RateText",
			true
		)

	local rotText =
		gui:FindFirstChild(
			"RotText",
			true
		)

	return
		rateText,
		rotText

end

--==================================================
-- BIG TV TEXT
--==================================================

local function getBigTexts(
	tv
)

	local gui =
		getTVGui(
			tv
		)

	if not gui then

		return nil,
			nil,
			nil

	end

	local titleText =
		gui:FindFirstChild(
			"TitleText",
			true
		)

	local moneyText =
		gui:FindFirstChild(
			"MoneyText",
			true
		)

	local updateText =
		gui:FindFirstChild(
			"UpdateText",
			true
		)

	return
		titleText,
		moneyText,
		updateText

end

--==================================================
-- FARM LAND RARITY
--==================================================

local function getRarity(
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
		and
		rarity
		~=
		""
	then

		return rarity

	end

	local visual =
		farmLand:FindFirstChild(
			"PlacedPotato"
		)

	if visual then

		local visualRarity =
			visual:GetAttribute(
				"Rarity"
			)

		if
			type(visualRarity)
			==
			"string"
		then

			return visualRarity

		end

	end

	return "Common"

end

--==================================================
-- NO ROT
--
-- Super + Rainbow are ALWAYS immune.
--==================================================

local function hasNoRot(
	farmLand,
	rarity
)

	if
		farmLand:GetAttribute(
			"RotImmune"
		)
		==
		true
	then

		return true

	end

	if rarity == "Super" then

		return true

	end

	if rarity == "Rainbow" then

		return true

	end

	if
		type(
			RarityService.HasNoRot
		)
		==
		"function"
	then

		return
			RarityService.HasNoRot(
				rarity
			)

	end

	return false

end

--==================================================
-- GET INCOME
--==================================================

local function getIncome(
	farmLand,
	rarity
)

	-- Prefer value calculated by FarmMoneyService.

	local income =
		farmLand:GetAttribute(
			"MoneyPerSecond"
		)

	if
		typeof(income)
		==
		"number"
		and
		income
		>
		0
	then

		return income

	end

	-- Fallback directly from rarity.

	local rarityIncome =
		RarityService.GetIncomeMultiplier(
			rarity
		)

	return
		math.max(
			0,
			tonumber(
				rarityIncome
			)
			or
			0
		)

end

--==================================================
-- FORMAT ROT TIMER
--==================================================

local function formatTime(
	seconds
)

	seconds =
		math.max(
			0,
			math.ceil(
				tonumber(seconds)
				or
				0
			)
		)

	local days =
		math.floor(
			seconds
			/
			86400
		)

	if days > 0 then

		local hours =
			math.floor(
				(
					seconds
					%
					86400
				)
				/
				3600
			)

		return
			string.format(
				"%dd %02dh",
				days,
				hours
			)

	end

	local hours =
		math.floor(
			seconds
			/
			3600
		)

	if hours > 0 then

		local minutes =
			math.floor(
				(
					seconds
					%
					3600
				)
				/
				60
			)

		return
			string.format(
				"%dh %02dm",
				hours,
				minutes
			)

	end

	local minutes =
		math.floor(
			seconds
			/
			60
		)

	local remainingSeconds =
		seconds
		%
		60

	return
		string.format(
			"%02d:%02d",
			minutes,
			remainingSeconds
		)

end

--==================================================
-- GET ROT DISPLAY
--==================================================

local function getRotText(
	farmLand,
	rarity
)

	local protectionPercent =
		math.max(
			0,
			math.floor(
				tonumber(
					farmLand:GetAttribute(
						"RotProtectionPercent"
					)
				)
				or
				0
			)
		)

	local function makeRotText(
		remaining
	)

		local timeText =
			formatTime(
				remaining
			)

		if protectionPercent > 0 then

			return
				"ROT "
				..
				timeText
				..
				" (-"
				..
				tostring(
					protectionPercent
				)
				..
				"%)"

		end

		return
			"ROT "
			..
			timeText

	end

	--==================================================
	-- SUPER / RAINBOW
	--==================================================

	if
		hasNoRot(
			farmLand,
			rarity
		)
	then

		return "NO ROT"

	end

	--==================================================
	-- EXPLICIT ROTTEN
	--==================================================

	if
		farmLand:GetAttribute(
			"IsRotten"
		)
		==
		true
	then

		return "ROTTEN"

	end

	--==================================================
	-- ACTIVE ROT TIME
	--==================================================

	local rotAt =
		farmLand:GetAttribute(
			"RotAt"
		)

	-- IMPORTANT:
	--
	-- RotAt = 0 DOES NOT mean rotten.

	if
		typeof(rotAt)
		~=
		"number"
		or
		rotAt
		<=
		0
	then

		local remaining =
			farmLand:GetAttribute(
				"RotRemaining"
			)

		if
			typeof(remaining)
			==
			"number"
			and
			remaining
			>
			0
		then

			return
				makeRotText(
					remaining
				)

		end

		return "ROT --:--"

	end

	local remaining =
		rotAt
		-
		os.time()

	if remaining <= 0 then

		return "ROTTEN"

	end

	return
		makeRotText(
			remaining
		)

end

--==================================================
-- UPDATE SMALL TV
--==================================================

local function updateSmallTV(
	farmLand
)

	local tv =
		farmLand:FindFirstChild(
			"SmallPotatoTV"
		)

	if not tv then

		return

	end

	local rateText,
		rotText =
			getSmallTexts(
				tv
			)

	if
		not rateText
		or
		not rotText
	then

		return

	end

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

		rateText.Text =
			"$0/sec"

		rotText.Text =
			"EMPTY"

		return

	end

	--==================================================
	-- RARITY
	--==================================================

	local rarity =
		getRarity(
			farmLand
		)

	local income =
		getIncome(
			farmLand,
			rarity
		)

	--==================================================
	-- MONEY LINE
	--==================================================

	rateText.Text =
		"+$"
		..
		formatNumber(
			income
		)
		..
		"/sec"

	--==================================================
	-- ROT LINE
	--==================================================

	rotText.Text =
		getRotText(
			farmLand,
			rarity
		)

end

--==================================================
-- GET COLLECTOR
--==================================================

local function getCollector(
	farm
)

	return
		farm:FindFirstChild(
			"MoneyCollector"
		)

end

--==================================================
-- GET STORED MONEY
--==================================================

local function getStoredMoney(
	farm
)

	local collector =
		getCollector(
			farm
		)

	if not collector then

		return 0

	end

	local money =
		collector:GetAttribute(
			"StoredMoney"
		)

	return
		math.max(
			0,
			tonumber(money)
				or
				0
		)

end

--==================================================
-- UPDATE BIG TV
--==================================================

local function updateBigTV(
	farm
)

	local tv =
		farm:FindFirstChild(
			"BigMoneyTV"
		)

	if not tv then

		return

	end

	local titleText,
		moneyText,
		updateText =
			getBigTexts(
				tv
			)

	if titleText then

		titleText.Text =
			"TOTAL GENERATED"

	end

	if moneyText then

		moneyText.Text =
			formatMoney(
				getStoredMoney(
					farm
				)
			)

	end

	if updateText then

		updateText.Text =
			"UPDATES LIVE"

	end

end

--==================================================
-- UPDATE FARM
--==================================================

local function updateFarm(
	farm
)

	if not farm:IsA(
		"Model"
	) then

		return

	end

	local farmLands =
		farm:FindFirstChild(
			"FarmLands"
		)

	if farmLands then

		for _, farmLand in ipairs(
			farmLands:GetChildren()
		) do

			if
				farmLand:IsA(
					"Model"
				)
			then

				updateSmallTV(
					farmLand
				)

			end

		end

	end

	updateBigTV(
		farm
	)

end

--==================================================
-- SMALL TV LOOP
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

					local farmLands =
						farm:FindFirstChild(
							"FarmLands"
						)

					if farmLands then

						for _, farmLand in ipairs(
							farmLands:GetChildren()
						) do

							if
								farmLand:IsA(
									"Model"
								)
							then

								updateSmallTV(
									farmLand
								)

							end

						end

					end

				end

			end

			task.wait(
				SMALL_REFRESH
			)

		end

	end
)

--==================================================
-- BIG TV LOOP
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

					updateBigTV(
						farm
					)

				end

			end

			task.wait(
				BIG_REFRESH
			)

		end

	end
)

--==================================================
-- INITIAL UPDATE
--==================================================

for _, farm in ipairs(
	farmsFolder:GetChildren()
) do

	updateFarm(
		farm
	)

end

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("📺 FARM TV SERVICE V2")
print("========================================")
print("✅ Common    = $1/sec")
print("✅ Rare      = $4/sec")
print("✅ Epic      = $8/sec")
print("✅ Exotic    = $15/sec")
print("✅ Legendary = $25/sec")
print("⭐ Super     = $80/sec | NO ROT")
print("🌈 Rainbow   = $100/sec | NO ROT")
print("----------------------------------------")
print("✅ RotAt = 0 is NOT rotten")
print("✅ Normal rot timer updates live")
print("🛡 Protected plot shows slower-rot percentage")
print("✅ Day/hour timer formatting enabled")
print("✅ Super TV says NO ROT")
print("✅ Rainbow TV says NO ROT")
print("✅ Big collector TV updates live")
print("✅ Empty plot says EMPTY")
print("========================================")
print("")