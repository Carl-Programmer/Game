--==================================================
-- 🧪 POTATIUM PLOT TEST TOOLS
--
-- STUDIO ONLY
-- Delete this before publishing.
--==================================================

local Players =
	game:GetService("Players")

local RunService =
	game:GetService("RunService")

local DataService =
	require(
		script.Parent:WaitForChild(
			"DataService"
		)
	)

--==================================================
-- SETTINGS
--==================================================

local GIVE_TEST_MONEY = false

-- Set this TRUE when you want Plots 5-8 locked again.
-- After one successful test, change it back to false.
local RESET_PAID_PLOTS = false

local TEST_CASH =
	10_000_000

--==================================================
-- NEVER RUN IN LIVE GAME
--==================================================

if not RunService:IsStudio() then
	return
end

--==================================================
-- SETUP PLAYER
--==================================================

local function setupPlayer(player)

	DataService.WaitForData(
		player
	)

	if not player.Parent then
		return
	end

	--==============================================
	-- GIVE TEST MONEY
	--==============================================

	if GIVE_TEST_MONEY then

		player:SetAttribute(
			"Cash",
			TEST_CASH
		)

		print(
			"🧪 TEST CASH GIVEN | "
				..
				player.Name
				..
				" | $"
				..
				tostring(TEST_CASH)
		)

	end

	--==============================================
	-- RESET PLOT UNLOCKS
	--==============================================

	if RESET_PAID_PLOTS then

		local upgrades =
			DataService.GetUpgrades(
				player
			)

		if type(upgrades) ~= "table" then
			upgrades = {}
		end

		upgrades.PlotUnlocks = {}

		DataService.SetUpgrades(
			player,
			upgrades
		)

		for plotNumber = 5, 8 do

			player:SetAttribute(
				"PlotUnlocked_"
					..
					tostring(plotNumber),
				false
			)

		end

		DataService.SavePlayer(
			player
		)

		print(
			"🔒 TEST RESET | Plots 5-8 locked again for "
				..
				player.Name
		)

	end

end

--==================================================
-- PLAYERS
--==================================================

Players.PlayerAdded:Connect(
	function(player)

		task.spawn(
			setupPlayer,
			player
		)

	end
)

for _, player in ipairs(
	Players:GetPlayers()
) do

	task.spawn(
		setupPlayer,
		player
	)

end

print("🧪 Plot Test Tools active - STUDIO ONLY")