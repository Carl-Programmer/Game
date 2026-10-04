--==================================================
-- POTATIUM SERVER STARTUP
-- src/server/init.server.luau
--==================================================

local Workspace = game:GetService("Workspace")

--==================================================
-- FIND POTATO WORLD
--==================================================

local potatoWorld = Workspace:FindFirstChild("PotatoWorld")

if not potatoWorld then
	warn("❌ PotatoWorld not found")
	return
end

print("========================================")
print("🥔 POTATIUM SERVER STARTING")
print("========================================")
print("✅ PotatoWorld found:", potatoWorld:GetFullName())

--==================================================
-- FIND MODULE
--==================================================

local function findModule(moduleName)
	-- Same Server folder
	local module = script.Parent:FindFirstChild(moduleName)

	if module then
		return module
	end

	-- Inside this Script
	module = script:FindFirstChild(moduleName)

	if module then
		return module
	end

	-- Explicit Server folder
	local serverFolder = script.Parent:FindFirstChild("Server")

	if serverFolder then
		module = serverFolder:FindFirstChild(moduleName)

		if module then
			return module
		end
	end

	return nil
end

--==================================================
-- START MODULE
--==================================================

local function startModule(moduleName, world)
	local module = findModule(moduleName)

	if not module then
		warn(
			"⚠ Could not find service: "
				.. moduleName
		)

		return false
	end

	-- ModuleScript
	if module:IsA("ModuleScript") then
		local success, result = pcall(function()
			return require(module)
		end)

		if not success then
			warn(
				"❌ Failed to require "
					.. moduleName
					.. ": "
					.. tostring(result)
			)

			return false
		end

		if type(result) == "table"
			and type(result.Start) == "function"
		then
			local started, startError = pcall(function()
				result.Start(world)
			end)

			if not started then
				warn(
					"❌ "
						.. moduleName
						.. ".Start failed: "
						.. tostring(startError)
				)

				return false
			end
		end

		print(
			"✅ "
				.. moduleName
				.. " STARTED"
		)

		return true
	end

	-- Normal Script
	if module:IsA("Script") then
		print(
			"✅ "
				.. moduleName
				.. " SCRIPT ACTIVE"
		)

		return true
	end

	warn(
		"⚠ "
			.. moduleName
			.. " is not a ModuleScript or Script"
	)

	return false
end

--==================================================
-- CORE SERVICES
--==================================================

startModule(
	"DataService",
	potatoWorld
)

startModule(
	"FarmService",
	potatoWorld
)

startModule(
	"PotatoService",
	potatoWorld
)

startModule(
	"InventoryService",
	potatoWorld
)

--==================================================
-- WORLD / MARKET
--==================================================

startModule(
	"MarketBuilder",
	potatoWorld
)

--==================================================
-- SHOP
--
-- ShopService can wait for PotatoMarket.
-- Run it separately so a missing PotatoMarket
-- NEVER blocks the services below it.
--==================================================

task.spawn(function()
	local success, result = pcall(function()
		return startModule(
			"ShopService",
			potatoWorld
		)
	end)

	if not success then
		warn(
			"❌ ShopService crashed: "
				.. tostring(result)
		)
	end
end)

--==================================================
-- OTHER MONEY / SHOP SERVICES
--==================================================

startModule(
	"FarmMoneyService",
	potatoWorld
)

startModule(
	"FarmTVService",
	potatoWorld
)

startModule(
	"PotatoTraderShop",
	potatoWorld
)

startModule(
	"UpgradeShop",
	potatoWorld
)

--==================================================
-- POTATO PLACEMENT / ROT
--==================================================

startModule(
	"PotatoPlacementService",
	potatoWorld
)

startModule(
	"PotatoRotBurstService",
	potatoWorld
)

--==================================================
-- HOES / CRATES
--==================================================

startModule(
	"WoodenHoeService",
	potatoWorld
)

startModule(
	"CrateService",
	potatoWorld
)

--==================================================
-- PLOT SYSTEM
--==================================================

startModule(
	"PlotUnlockService",
	potatoWorld
)

--==================================================
-- FORAGING
--==================================================

startModule(
	"ForagingService",
	potatoWorld
)

--==================================================
-- TELEPORT
--
-- IMPORTANT:
-- Start before the client tries to find
-- PotatoTeleportRemotes.
--==================================================

startModule(
	"TeleportService",
	potatoWorld
)

--==================================================
-- LEADERBOARDS
--
-- IMPORTANT:
-- Start after the physical boards exist.
--
-- LeaderboardService is a ModuleScript.
-- Do NOT rename it to .server.luau.
--==================================================

startModule(
	"LeaderboardService",
	potatoWorld
)

--==================================================
-- OPTIONAL SERVICES
--
-- These are loaded only when present.
-- They will not break startup if missing.
--==================================================

local optionalServices = {
	"RarityService",
	"PotatoVisuals",
	"SpudMassService",
	"MeadowDemoModels",
}

for _, serviceName in ipairs(optionalServices) do
	local module = findModule(serviceName)

	if module then
		if module:IsA("ModuleScript") then
			local success, result = pcall(function()
				return require(module)
			end)

			if success then
				if type(result) == "table"
					and type(result.Start) == "function"
				then
					local started, startError = pcall(function()
						result.Start(potatoWorld)
					end)

					if not started then
						warn(
							"⚠ Optional "
								.. serviceName
								.. ".Start failed: "
								.. tostring(startError)
						)
					else
						print(
							"✅ Optional "
								.. serviceName
								.. " STARTED"
						)
					end
				else
					print(
						"✅ Optional "
							.. serviceName
							.. " LOADED"
					)
				end
			else
				warn(
					"⚠ Optional "
						.. serviceName
						.. " failed to load: "
						.. tostring(result)
				)
			end
		else
			print(
				"✅ Optional "
					.. serviceName
					.. " SCRIPT ACTIVE"
			)
		end
	end
end

--==================================================
-- STARTUP COMPLETE
--==================================================

print("")
print("========================================")
print("🥔 POTATIUM SERVER STARTUP COMPLETE")
print("========================================")
print("✅ DataService")
print("✅ FarmService")
print("✅ PotatoService")
print("✅ InventoryService")
print("✅ MarketBuilder")
print("✅ ShopService running independently")
print("✅ FarmMoneyService")
print("✅ FarmTVService")
print("✅ PotatoTraderShop")
print("✅ UpgradeShop")
print("✅ PotatoPlacementService")
print("✅ PotatoRotBurstService")
print("✅ WoodenHoeService")
print("✅ CrateService")
print("✅ PlotUnlockService")
print("✅ ForagingService")
print("✅ TeleportService")
print("✅ LeaderboardService")
print("========================================")