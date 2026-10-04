--========================================================
-- 🔒 POTATIUM PLOT UNLOCK SERVICE V1
--
-- Plot 1 = FREE
-- Plot 2 = FREE
-- Plot 3 = FREE
-- Plot 4 = FREE / ICE
--
-- Plot 5 = $5,000
-- Plot 6 = $50,000
-- Plot 7 = $500,000
-- Plot 8 = $5,000,000
--
-- ✅ Owner only
-- ✅ Uses Cash
-- ✅ Saves permanently
-- ✅ Smooth lock decoration fade
-- ✅ Purchase sound
-- ✅ Restores unlocks after rejoin
-- ✅ Does NOT move your decorations
--========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local DataService =
	require(
		script.Parent:WaitForChild(
			"DataService"
		)
	)

--========================================================
-- CONFIG
--========================================================

local PLOTS = {

	[5] = {
		Cost = 5_000,
		DecorName = "Plot5Locked",
	},

	[6] = {
		Cost = 50_000,
		DecorName = "Plot6Locked",
	},

	[7] = {
		Cost = 500_000,
		DecorName = "Plot7Locked",
	},

	[8] = {
		Cost = 5_000_000,
		DecorName = "Plot8Locked",
	},

}

local FADE_TIME = 0.65

-- Built-in Roblox ping.
-- We can replace this later with a better coin/cash sound.
local BUY_SOUND_ID =
	"rbxassetid://133292918309565"

local world =
	Workspace:WaitForChild(
		"PotatoWorld"
	)

local farmsFolder =
	world:WaitForChild(
		"Farms"
	)

local connectedPrompts = {}
local busyPlayers = {}

--========================================================
-- MONEY FORMAT
--========================================================

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

		text = newText

		if count == 0 then
			break
		end

	end

	return "$" .. text

end

--========================================================
-- GET FARM LANDS
--========================================================

local function getFarmLands(farm)

	if not farm then
		return nil
	end

	return
		farm:FindFirstChild(
			"FarmLands"
		)

end

--========================================================
-- GET FARM OWNER
--========================================================

local function getFarmOwner(farm)

	if not farm then
		return nil
	end

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

--========================================================
-- GET FARM LAND
--========================================================

local function getFarmLand(
	farm,
	plotNumber
)

	local farmLands =
		getFarmLands(
			farm
		)

	if not farmLands then
		return nil
	end

	local name =
		string.format(
			"FarmLand_%02d",
			plotNumber
		)

	local farmLand =
		farmLands:FindFirstChild(
			name
		)

	if
		farmLand
		and
		farmLand:IsA("Model")
	then

		return farmLand

	end

	return nil

end

--========================================================
-- GET DECORATION
--========================================================

local function getDecoration(
	farm,
	plotNumber
)

	local config =
		PLOTS[
			plotNumber
		]

	if not config then
		return nil
	end

	local farmLands =
		getFarmLands(
			farm
		)

	if not farmLands then
		return nil
	end

	-- Preferred clean folder.
	local decorFolder =
		farmLands:FindFirstChild(
			"LockedPlotDecorations"
		)

	if decorFolder then

		local decor =
			decorFolder:FindFirstChild(
				config.DecorName
			)

		if decor then
			return decor
		end

	end

	-- Fallback:
	-- also supports your old structure if the model
	-- is still directly under FarmLands.
	return
		farmLands:FindFirstChild(
			config.DecorName
		)

end

--========================================================
-- REMEMBER ORIGINAL APPEARANCE
--========================================================

local function rememberAppearance(
	decoration
)

	if not decoration then
		return
	end

	for _, object in ipairs(
		decoration:GetDescendants()
	) do

		if object:IsA("BasePart") then

			if
				object:GetAttribute(
					"UnlockOriginalTransparency"
				)
				==
				nil
			then

				object:SetAttribute(
					"UnlockOriginalTransparency",
					object.Transparency
				)

				object:SetAttribute(
					"UnlockOriginalCanCollide",
					object.CanCollide
				)

				object:SetAttribute(
					"UnlockOriginalCanTouch",
					object.CanTouch
				)

				object:SetAttribute(
					"UnlockOriginalCanQuery",
					object.CanQuery
				)

			end

		elseif
			object:IsA("TextLabel")
			or
			object:IsA("TextButton")
			or
			object:IsA("TextBox")
		then

			if
				object:GetAttribute(
					"UnlockOriginalTextTransparency"
				)
				==
				nil
			then

				object:SetAttribute(
					"UnlockOriginalTextTransparency",
					object.TextTransparency
				)

				object:SetAttribute(
					"UnlockOriginalStrokeTransparency",
					object.TextStrokeTransparency
				)

				object:SetAttribute(
					"UnlockOriginalBackgroundTransparency",
					object.BackgroundTransparency
				)

			end

		elseif
			object:IsA("ImageLabel")
			or
			object:IsA("ImageButton")
		then

			if
				object:GetAttribute(
					"UnlockOriginalImageTransparency"
				)
				==
				nil
			then

				object:SetAttribute(
					"UnlockOriginalImageTransparency",
					object.ImageTransparency
				)

				object:SetAttribute(
					"UnlockOriginalBackgroundTransparency",
					object.BackgroundTransparency
				)

			end

		elseif
			object:IsA("Decal")
			or
			object:IsA("Texture")
		then

			if
				object:GetAttribute(
					"UnlockOriginalTextureTransparency"
				)
				==
				nil
			then

				object:SetAttribute(
					"UnlockOriginalTextureTransparency",
					object.Transparency
				)

			end

		elseif object:IsA("UIStroke") then

			if
				object:GetAttribute(
					"UnlockOriginalStrokeTransparency"
				)
				==
				nil
			then

				object:SetAttribute(
					"UnlockOriginalStrokeTransparency",
					object.Transparency
				)

			end

		end

	end

end

--========================================================
-- SHOW DECORATION
--========================================================

local function showDecoration(
	decoration
)

	if not decoration then
		return
	end

	rememberAppearance(
		decoration
	)

	for _, object in ipairs(
		decoration:GetDescendants()
	) do

		if object:IsA("BasePart") then

			object.Transparency =
				object:GetAttribute(
					"UnlockOriginalTransparency"
				)
				or
				0

			local collide =
				object:GetAttribute(
					"UnlockOriginalCanCollide"
				)

			if collide ~= nil then
				object.CanCollide = collide
			end

			local touch =
				object:GetAttribute(
					"UnlockOriginalCanTouch"
				)

			if touch ~= nil then
				object.CanTouch = touch
			end

			local query =
				object:GetAttribute(
					"UnlockOriginalCanQuery"
				)

			if query ~= nil then
				object.CanQuery = query
			end

		elseif
			object:IsA("TextLabel")
			or
			object:IsA("TextButton")
			or
			object:IsA("TextBox")
		then

			object.TextTransparency =
				object:GetAttribute(
					"UnlockOriginalTextTransparency"
				)
				or
				0

			object.TextStrokeTransparency =
				object:GetAttribute(
					"UnlockOriginalStrokeTransparency"
				)
				or
				0

			object.BackgroundTransparency =
				object:GetAttribute(
					"UnlockOriginalBackgroundTransparency"
				)
				or
				0

		elseif
			object:IsA("ImageLabel")
			or
			object:IsA("ImageButton")
		then

			object.ImageTransparency =
				object:GetAttribute(
					"UnlockOriginalImageTransparency"
				)
				or
				0

			object.BackgroundTransparency =
				object:GetAttribute(
					"UnlockOriginalBackgroundTransparency"
				)
				or
				0

		elseif
			object:IsA("Decal")
			or
			object:IsA("Texture")
		then

			object.Transparency =
				object:GetAttribute(
					"UnlockOriginalTextureTransparency"
				)
				or
				0

		elseif object:IsA("UIStroke") then

			object.Transparency =
				object:GetAttribute(
					"UnlockOriginalStrokeTransparency"
				)
				or
				0

		end

	end

end

--========================================================
-- HIDE DECORATION INSTANTLY
--
-- Used when player rejoins and already owns plot.
--========================================================

local function hideDecorationInstant(
	decoration
)

	if not decoration then
		return
	end

	rememberAppearance(
		decoration
	)

	for _, object in ipairs(
		decoration:GetDescendants()
	) do

		if object:IsA("BasePart") then

			object.Transparency = 1
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false

		elseif
			object:IsA("TextLabel")
			or
			object:IsA("TextButton")
			or
			object:IsA("TextBox")
		then

			object.TextTransparency = 1
			object.TextStrokeTransparency = 1
			object.BackgroundTransparency = 1

		elseif
			object:IsA("ImageLabel")
			or
			object:IsA("ImageButton")
		then

			object.ImageTransparency = 1
			object.BackgroundTransparency = 1

		elseif
			object:IsA("Decal")
			or
			object:IsA("Texture")
		then

			object.Transparency = 1

		elseif object:IsA("UIStroke") then

			object.Transparency = 1

		end

	end

end

--========================================================
-- SMOOTH FADE
--========================================================

local function fadeDecoration(
	decoration
)

	if not decoration then
		return
	end

	rememberAppearance(
		decoration
	)

	local tweenInfo =
		TweenInfo.new(
			FADE_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)

	for _, object in ipairs(
		decoration:GetDescendants()
	) do

		if object:IsA("BasePart") then

			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false

			TweenService:Create(
				object,
				tweenInfo,
				{
					Transparency = 1,
				}
			):Play()

		elseif
			object:IsA("TextLabel")
			or
			object:IsA("TextButton")
			or
			object:IsA("TextBox")
		then

			TweenService:Create(
				object,
				tweenInfo,
				{
					TextTransparency = 1,
					TextStrokeTransparency = 1,
					BackgroundTransparency = 1,
				}
			):Play()

		elseif
			object:IsA("ImageLabel")
			or
			object:IsA("ImageButton")
		then

			TweenService:Create(
				object,
				tweenInfo,
				{
					ImageTransparency = 1,
					BackgroundTransparency = 1,
				}
			):Play()

		elseif
			object:IsA("Decal")
			or
			object:IsA("Texture")
		then

			TweenService:Create(
				object,
				tweenInfo,
				{
					Transparency = 1,
				}
			):Play()

		elseif object:IsA("UIStroke") then

			TweenService:Create(
				object,
				tweenInfo,
				{
					Transparency = 1,
				}
			):Play()

		end

	end

	task.delay(
		FADE_TIME + 0.05,
		function()

			if decoration.Parent then

				hideDecorationInstant(
					decoration
				)

			end

		end
	)

end

--========================================================
-- GET PROMPT PART
--========================================================

local function getPromptHolder(
	decoration
)

	if not decoration then
		return nil
	end

	local lockBody =
		decoration:FindFirstChild(
			"LockBody",
			true
		)

	if
		lockBody
		and
		lockBody:IsA("BasePart")
	then

		return lockBody

	end

	if
		decoration:IsA("Model")
		and
		decoration.PrimaryPart
	then

		return decoration.PrimaryPart

	end

	return
		decoration:FindFirstChildWhichIsA(
			"BasePart",
			true
		)

end

--========================================================
-- PURCHASE SOUND
--========================================================

local function playPurchaseSound(
	decoration
)

	local holder =
		getPromptHolder(
			decoration
		)

	if not holder then
		return
	end

	local sound =
		Instance.new(
			"Sound"
		)

	sound.Name =
		"PlotPurchaseSound"

	sound.SoundId =
		BUY_SOUND_ID

	sound.Volume =
		0.8

	sound.PlaybackSpeed =
		1.15

	sound.RollOffMaxDistance =
		35

	sound.Parent =
		holder

	sound:Play()

	Debris:AddItem(
		sound,
		4
	)

end

--========================================================
-- UPDATE PRICE WRITTEN ON YOUR SIGN
--========================================================

local function updateDecorationText(
	decoration,
	plotNumber,
	cost
)

	if not decoration then
		return
	end

	for _, object in ipairs(
		decoration:GetDescendants()
	) do

		if
			object:IsA("TextLabel")
		then

			if object.Name == "Price" then

				object.Text =
					"UNLOCK "
					..
					formatMoney(
						cost
					)

			elseif object.Name == "Plot" then

				object.Text =
					"PLOT "
					..
					tostring(
						plotNumber
					)

			elseif object.Name == "Locked" then

				object.Text =
					"LOCKED"

			end

		end

	end

end

--========================================================
-- GET SAVED UNLOCK
--========================================================

local function isUnlocked(
	player,
	plotNumber
)

	if plotNumber <= 4 then
		return true
	end

	if not player then
		return false
	end

	if
		player:GetAttribute(
			"PlotUnlocked_"
			..
			tostring(
				plotNumber
			)
		)
		==
		true
	then

		return true

	end

	if
		player:GetAttribute(
			"DataLoaded"
		)
		~=
		true
	then

		return false

	end

	local upgrades =
		DataService.GetUpgrades(
			player
		)

	if type(upgrades) ~= "table" then
		return false
	end

	local unlocks =
		upgrades.PlotUnlocks

	if type(unlocks) ~= "table" then
		return false
	end

	return
		unlocks[
			tostring(
				plotNumber
			)
		]
		==
		true

end

--========================================================
-- SAVE UNLOCK
--========================================================

local function saveUnlock(
	player,
	plotNumber
)

	local upgrades =
		DataService.GetUpgrades(
			player
		)

	if type(upgrades) ~= "table" then
		upgrades = {}
	end

	if
		type(
			upgrades.PlotUnlocks
		)
		~=
		"table"
	then

		upgrades.PlotUnlocks = {}

	end

	upgrades.PlotUnlocks[
		tostring(
			plotNumber
		)
	] =
		true

	DataService.SetUpgrades(
		player,
		upgrades
	)

	player:SetAttribute(
		"PlotUnlocked_"
		..
		tostring(
			plotNumber
		),
		true
	)

end

--========================================================
-- SET FARM LAND STATE
--========================================================

local function setFarmLandUnlocked(
	farmLand,
	plotNumber,
	unlocked
)

	if not farmLand then
		return
	end

	local config =
		PLOTS[
			plotNumber
		]

	farmLand:SetAttribute(
		"PlotUnlocked",
		unlocked
			==
			true
	)

	farmLand:SetAttribute(
		"PlotLocked",
		unlocked
			~=
			true
	)

	if
		config
		and
		unlocked
		~=
		true
	then

		farmLand:SetAttribute(
			"UnlockCost",
			config.Cost
		)

	else

		farmLand:SetAttribute(
			"UnlockCost",
			0
		)

	end

end

--========================================================
-- FORWARD DECLARATION
--========================================================

local attemptPurchase

--========================================================
-- CREATE / UPDATE PURCHASE PROMPT
--========================================================

local function setupPrompt(
	farm,
	decoration,
	plotNumber,
	cost
)

	local holder =
		getPromptHolder(
			decoration
		)

	if not holder then

		warn(
			"❌ No prompt holder for Plot "
			..
			tostring(
				plotNumber
			)
		)

		return nil

	end

	local prompt =
		holder:FindFirstChild(
			"PlotUnlockPrompt"
		)

	if not prompt then

		prompt =
			Instance.new(
				"ProximityPrompt"
			)

		prompt.Name =
			"PlotUnlockPrompt"

		prompt.Parent =
			holder

	end

	prompt.KeyboardKeyCode =
		Enum.KeyCode.E

	prompt.ActionText =
		"Buy for "
		..
		formatMoney(
			cost
		)

	prompt.ObjectText =
		"Unlock Plot "
		..
		tostring(
			plotNumber
		)

	prompt.HoldDuration =
		0.35

	prompt.MaxActivationDistance =
		10

	prompt.RequiresLineOfSight =
		false

	prompt.Exclusivity =
		Enum.ProximityPromptExclusivity.AlwaysShow

	if
		not connectedPrompts[
			prompt
		]
	then

		connectedPrompts[
			prompt
		] =
			true

		prompt.Triggered:Connect(
			function(player)

				attemptPurchase(
					player,
					farm,
					plotNumber
				)

			end
		)

	end

	return prompt

end

--========================================================
-- PURCHASE
--========================================================

attemptPurchase =
	function(
		player,
		farm,
		plotNumber
	)

		if
			busyPlayers[
				player
			]
		then

			return

		end

		busyPlayers[
			player
		] =
			true

		task.delay(
			1,
			function()

				busyPlayers[
					player
				] =
					nil

			end
		)

		if
			not player
			or
			not player.Parent
		then

			return

		end

		if
			not farm
			or
			not farm.Parent
		then

			return

		end

		--================================================
		-- OWNER ONLY
		--================================================

		if
			farm:GetAttribute(
				"OwnerUserId"
			)
			~=
			player.UserId
		then

			return

		end

		--================================================
		-- DATA READY
		--================================================

		if
			player:GetAttribute(
				"DataLoaded"
			)
			~=
			true
		then

			return

		end

		local config =
			PLOTS[
				plotNumber
			]

		if not config then
			return
		end

		local farmLand =
			getFarmLand(
				farm,
				plotNumber
			)

		local decoration =
			getDecoration(
				farm,
				plotNumber
			)

		if not farmLand then

			warn(
				"❌ Missing FarmLand for Plot "
				..
				tostring(
					plotNumber
				)
			)

			return

		end

		--================================================
		-- ALREADY BOUGHT
		--================================================

		if
			isUnlocked(
				player,
				plotNumber
			)
		then

			setFarmLandUnlocked(
				farmLand,
				plotNumber,
				true
			)

			if decoration then
				hideDecorationInstant(
					decoration
				)
			end

			return

		end

		--================================================
		-- CHECK CASH
		--================================================

		local cash =
			tonumber(
				player:GetAttribute(
					"Cash"
				)
			)
			or
			0

		if cash < config.Cost then

			print(
				"❌ "
				..
				player.Name
				..
				" needs "
				..
				formatMoney(
					config.Cost
				)
				..
				" for Plot "
				..
				tostring(
					plotNumber
				)
			)

			return

		end

		--================================================
		-- PAY
		--================================================

		player:SetAttribute(
			"Cash",
			cash
				-
				config.Cost
		)

		--================================================
		-- SAVE OWNERSHIP
		--================================================

		saveUnlock(
			player,
			plotNumber
		)

		--================================================
		-- UNLOCK ACTUAL FARM LAND
		--================================================

		setFarmLandUnlocked(
			farmLand,
			plotNumber,
			true
		)

		--================================================
		-- DISABLE BUY PROMPT
		--================================================

		if decoration then

			local holder =
				getPromptHolder(
					decoration
				)

			if holder then

				local prompt =
					holder:FindFirstChild(
						"PlotUnlockPrompt"
					)

				if prompt then
					prompt.Enabled = false
				end

			end

			--============================================
			-- SOUND + SMOOTH DISAPPEAR
			--============================================

			playPurchaseSound(
				decoration
			)

			fadeDecoration(
				decoration
			)

		end

		--================================================
		-- SAVE NOW
		--================================================

		task.spawn(
			function()

				local success,
					err =
						pcall(
							function()

								DataService.SavePlayer(
									player
								)

							end
						)

				if not success then

					warn(
						"⚠ Plot unlock save error: "
						..
						tostring(
							err
						)
					)

				end

			end
		)

		print(
			"🔓 "
				..
				player.Name
				..
				" bought Plot "
				..
				tostring(
					plotNumber
				)
				..
				" for "
				..
				formatMoney(
					config.Cost
				)
		)

	end

--========================================================
-- SETUP FARM
--========================================================

local function setupFarm(
	farm
)

	if
		not farm
		or
		not farm.Parent
	then

		return

	end

	local farmLands =
		getFarmLands(
			farm
		)

	if not farmLands then
		return
	end

	--====================================================
	-- PLOTS 1-4 ALWAYS FREE
	--====================================================

	for plotNumber = 1, 4 do

		local farmLand =
			getFarmLand(
				farm,
				plotNumber
			)

		if farmLand then

			farmLand:SetAttribute(
				"PlotUnlocked",
				true
			)

			farmLand:SetAttribute(
				"PlotLocked",
				false
			)

			farmLand:SetAttribute(
				"UnlockCost",
				0
			)

		end

	end

	local owner =
		getFarmOwner(
			farm
		)

	--====================================================
	-- SETUP PAID PLOTS
	--====================================================

	for plotNumber, config in pairs(
		PLOTS
	) do

		local farmLand =
			getFarmLand(
				farm,
				plotNumber
			)

		local decoration =
			getDecoration(
				farm,
				plotNumber
			)

		if farmLand then

			updateDecorationText(
				decoration,
				plotNumber,
				config.Cost
			)

			--============================================
			-- NO OWNER
			--============================================

			if not owner then

				setFarmLandUnlocked(
					farmLand,
					plotNumber,
					false
				)

				if decoration then

					showDecoration(
						decoration
					)

					local holder =
						getPromptHolder(
							decoration
						)

					if holder then

						local prompt =
							holder:FindFirstChild(
								"PlotUnlockPrompt"
							)

						if prompt then
							prompt.Enabled = false
						end

					end

				end

			--============================================
			-- OWNER DATA NOT READY YET
			--============================================

			elseif
				owner:GetAttribute(
					"DataLoaded"
				)
				~=
				true
			then

				setFarmLandUnlocked(
					farmLand,
					plotNumber,
					false
				)

			--============================================
			-- ALREADY PURCHASED
			--============================================

			elseif
				isUnlocked(
					owner,
					plotNumber
				)
			then

				owner:SetAttribute(
					"PlotUnlocked_"
					..
					tostring(
						plotNumber
					),
					true
				)

				setFarmLandUnlocked(
					farmLand,
					plotNumber,
					true
				)

				if decoration then

					hideDecorationInstant(
						decoration
					)

					local holder =
						getPromptHolder(
							decoration
						)

					if holder then

						local prompt =
							holder:FindFirstChild(
								"PlotUnlockPrompt"
							)

						if prompt then
							prompt.Enabled = false
						end

					end

				end

			--============================================
			-- LOCKED
			--============================================

			else

				owner:SetAttribute(
					"PlotUnlocked_"
					..
					tostring(
						plotNumber
					),
					false
				)

				setFarmLandUnlocked(
					farmLand,
					plotNumber,
					false
				)

				if not decoration then

					warn(
						"❌ Missing "
							..
							config.DecorName
							..
							" in "
							..
							farm:GetFullName()
					)

				else

					showDecoration(
						decoration
					)

					local prompt =
						setupPrompt(
							farm,
							decoration,
							plotNumber,
							config.Cost
						)

					if prompt then
						prompt.Enabled = true
					end

				end

			end

		end

	end

end

--========================================================
-- WAIT FOR OWNER DATA THEN REFRESH
--========================================================

local function refreshFarmAfterData(
	farm
)

	task.spawn(
		function()

			setupFarm(
				farm
			)

			local owner =
				getFarmOwner(
					farm
				)

			if not owner then
				return
			end

			DataService.WaitForData(
				owner
			)

			if
				owner.Parent
				and
				farm.Parent
				and
				farm:GetAttribute(
					"OwnerUserId"
				)
				==
				owner.UserId
			then

				setupFarm(
					farm
				)

			end

		end
	)

end

--========================================================
-- WATCH FARM
--========================================================

local function watchFarm(
	farm
)

	if not farm:IsA("Model") then
		return
	end

	farm:GetAttributeChangedSignal(
		"OwnerUserId"
	):Connect(
		function()

			refreshFarmAfterData(
				farm
			)

		end
	)

	refreshFarmAfterData(
		farm
	)

end

--========================================================
-- EXISTING FARMS
--========================================================

for _, farm in ipairs(
	farmsFolder:GetChildren()
) do

	watchFarm(
		farm
	)

end

--========================================================
-- NEW FARMS
--========================================================

farmsFolder.ChildAdded:Connect(
	function(farm)

		task.wait(
			0.2
		)

		watchFarm(
			farm
		)

	end
)

--========================================================
-- PLAYER DATA FINISHED LOADING
--========================================================

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

				for _, farm in ipairs(
					farmsFolder:GetChildren()
				) do

					if
						farm:IsA("Model")
						and
						farm:GetAttribute(
							"OwnerUserId"
						)
						==
						player.UserId
					then

						setupFarm(
							farm
						)

					end

				end

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

print("")
print("========================================")
print("🔒 PLOT UNLOCK SERVICE V1")
print("========================================")
print("✅ Plot 1 = FREE")
print("✅ Plot 2 = FREE")
print("✅ Plot 3 = FREE")
print("🧊 Plot 4 = FREE / ICE")
print("----------------------------------------")
print("🔒 Plot 5 = $5,000")
print("🔒 Plot 6 = $50,000")
print("🔒 Plot 7 = $500,000")
print("🔒 Plot 8 = $5,000,000")
print("----------------------------------------")
print("✅ Owner-only buying")
print("✅ Unlocks permanently saved")
print("✅ Smooth decoration fade")
print("✅ Purchase sound")
print("✅ Manual decoration positions preserved")
print("========================================")
print("")