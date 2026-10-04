--========================================================
-- POTATIUM - UPGRADE SHOP V2
--
-- ✅ Existing Interaction part opens GUI
-- ✅ Wooden Crate row is bought through GUI
-- ✅ BUY 1 / BUY 10
-- ✅ Server validates cash + amount
-- ✅ Purchased crates persist in DataService.Equipment
-- ✅ CrateService receives CrateInventoryRevision
--========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverFolder = script.Parent.Parent

local DataService =
	require(
		serverFolder:WaitForChild(
			"DataService"
		)
	)

local WoodenCrate =
	require(
		serverFolder
			:WaitForChild("Crates")
			:WaitForChild("WoodenCrate")
	)

local PRICE = tonumber(WoodenCrate.Price) or 500

--========================================================
-- REMOTES
--========================================================

local remotes =
	ReplicatedStorage:FindFirstChild(
		"PotatiumUpgradeShopRemotes"
	)

if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "PotatiumUpgradeShopRemotes"
	remotes.Parent = ReplicatedStorage
end

local openShop =
	remotes:FindFirstChild(
		"OpenShop"
	)

if not openShop then
	openShop = Instance.new("RemoteEvent")
	openShop.Name = "OpenShop"
	openShop.Parent = remotes
end

local buyCrates =
	remotes:FindFirstChild(
		"BuyCrates"
	)

if not buyCrates then
	buyCrates = Instance.new("RemoteEvent")
	buyCrates.Name = "BuyCrates"
	buyCrates.Parent = remotes
end

local purchaseResult =
	remotes:FindFirstChild(
		"PurchaseResult"
	)

if not purchaseResult then
	purchaseResult = Instance.new("RemoteEvent")
	purchaseResult.Name = "PurchaseResult"
	purchaseResult.Parent = remotes
end

--========================================================
-- HELPERS
--========================================================

local function normalizedName(value)
	return
		string.lower(
			tostring(
				value
				or
				""
			)
		)
		:gsub(
			"[%s_%-%p]",
			""
		)
end

local function isUpgradeShopContainer(object)
	if
		not object:IsA("Model")
		and
		not object:IsA("Folder")
	then
		return false
	end

	local name =
		normalizedName(
			object.Name
		)

	return
		string.find(
			name,
			"upgrade",
			1,
			true
		)
		~=
		nil
		and
		(
			string.find(
				name,
				"shop",
				1,
				true
			)
			~=
			nil
			or
			string.find(
				name,
				"store",
				1,
				true
			)
			~=
			nil
		)
end

local function findInteractionPart()
	-- Preferred: Interaction inside a model/folder containing
	-- "upgrade" + "shop/store".
	for _, object in ipairs(
		Workspace:GetDescendants()
	) do
		if
			isUpgradeShopContainer(
				object
			)
		then
			local interaction =
				object:FindFirstChild(
					"Interaction",
					true
				)

			if
				interaction
				and
				interaction:IsA(
					"BasePart"
				)
			then
				return interaction
			end
		end
	end

	-- Fallback: any Interaction with an ancestor containing "upgrade".
	for _, object in ipairs(
		Workspace:GetDescendants()
	) do
		if
			object:IsA("BasePart")
			and
			object.Name
			==
			"Interaction"
		then
			local ancestor =
				object.Parent

			while
				ancestor
				and
				ancestor
				~=
				Workspace
			do
				if
					string.find(
						normalizedName(
							ancestor.Name
						),
						"upgrade",
						1,
						true
					)
				then
					return object
				end

				ancestor =
					ancestor.Parent
			end
		end
	end

	return nil
end

local function getEquipment(player)
	local equipment =
		DataService.GetEquipment(
			player
		)

	if type(equipment) ~= "table" then
		equipment = {}
	end

	if type(equipment.Crates) ~= "table" then
		equipment.Crates = {}
	end

	if type(equipment.Hoes) ~= "table" then
		equipment.Hoes = {}
	end

	return equipment
end

local function bumpCrateRevision(player)
	player:SetAttribute(
		"CrateInventoryRevision",
		(
			player:GetAttribute(
				"CrateInventoryRevision"
			)
			or
			0
		)
		+
		1
	)
end

local function getShopPayload()
	local drops = {}

	for _, drop in ipairs(
		WoodenCrate.Drops
		or
		{}
	) do
		table.insert(
			drops,
			{
				Name = tostring(
					drop.Name
					or
					"Unknown"
				),

				Chance = tonumber(
					drop.Chance
				)
				or
				0,
			}
		)
	end

	return {
		CrateType = "Wooden",
		Name = WoodenCrate.Name or "Wooden Crate",
		Price = PRICE,
		Drops = drops,
	}
end

--========================================================
-- PURCHASE
--========================================================

local purchaseDebounce = {}

local function sendPurchaseResult(
	player,
	success,
	message,
	amount
)
	purchaseResult:FireClient(
		player,
		success,
		message,
		amount or 0,
		PRICE
	)
end

buyCrates.OnServerEvent:Connect(
	function(
		player,
		crateType,
		amount
	)
		if
			purchaseDebounce[player]
		then
			return
		end

		if crateType ~= "Wooden" then
			return
		end

		amount =
			math.floor(
				tonumber(amount)
				or
				0
			)

		-- Only the two GUI buttons are valid.
		if
			amount ~= 1
			and
			amount ~= 10
		then
			return
		end

		purchaseDebounce[player] =
			true

		task.delay(
			0.25,
			function()
				purchaseDebounce[player] =
					nil
			end
		)

		if
			player:GetAttribute(
				"DataLoaded"
			)
			~=
			true
		then
			sendPurchaseResult(
				player,
				false,
				"Inventory is still loading."
			)
			return
		end

		local totalPrice =
			PRICE * amount

		local cash =
			math.max(
				0,
				tonumber(
					player:GetAttribute(
						"Cash"
					)
				)
				or
				0
			)

		if cash < totalPrice then
			sendPurchaseResult(
				player,
				false,
				"Not enough money."
			)
			return
		end

		local equipment =
			getEquipment(
				player
			)

		equipment.Crates.Wooden =
			math.max(
				0,
				math.floor(
					tonumber(
						equipment.Crates.Wooden
					)
					or
					0
				)
			)
			+
			amount

		-- Cash is already one of your saved player attributes.
		player:SetAttribute(
			"Cash",
			cash - totalPrice
		)

		-- Crates save inside the existing Equipment table.
		DataService.SetEquipment(
			player,
			equipment
		)

		-- CrateService listens to this and updates the real crate Tool.
		bumpCrateRevision(
			player
		)

		sendPurchaseResult(
			player,
			true,
			(
				"Bought "
				..
				tostring(amount)
				..
				(
					amount == 1
					and
					" Wooden Crate!"
					or
					" Wooden Crates!"
				)
			),
			amount
		)

		print(
			"📦 "
			..
			player.Name
			..
			" bought "
			..
			tostring(amount)
			..
			" Wooden Crate(s) for $"
			..
			tostring(totalPrice)
		)
	end
)

--========================================================
-- INTERACTION PROMPT
--========================================================

local prompt = nil

local function setupPrompt()
	if
		prompt
		and
		prompt.Parent
	then
		return true
	end

	local interaction =
		findInteractionPart()

	if not interaction then
		return false
	end

	-- Remove V1 direct-buy prompt if it exists.
	local oldPrompt =
		interaction:FindFirstChild(
			"BuyWoodenCratePrompt"
		)

	if
		oldPrompt
		and
		oldPrompt:IsA(
			"ProximityPrompt"
		)
	then
		oldPrompt:Destroy()
	end

	prompt =
		interaction:FindFirstChild(
			"OpenUpgradeShopPrompt"
		)

	if
		prompt
		and
		not prompt:IsA(
			"ProximityPrompt"
		)
	then
		prompt:Destroy()
		prompt = nil
	end

	if not prompt then
		prompt =
			Instance.new(
				"ProximityPrompt"
			)

		prompt.Name =
			"OpenUpgradeShopPrompt"

		prompt.Parent =
			interaction
	end

	prompt.ActionText =
		"Open Shop"

	prompt.ObjectText =
		"Upgrade Shop"

	prompt.KeyboardKeyCode =
		Enum.KeyCode.E

	prompt.HoldDuration =
		0.15

	prompt.MaxActivationDistance =
		10

	prompt.RequiresLineOfSight =
		false

	prompt.Triggered:Connect(
		function(player)
			openShop:FireClient(
				player,
				getShopPayload()
			)
		end
	)

	print(
		"✅ Upgrade Shop GUI prompt attached: "
		..
		interaction:GetFullName()
	)

	return true
end

task.spawn(
	function()
		while true do
			if setupPrompt() then
				break
			end

			task.wait(
				1
			)
		end
	end
)

Players.PlayerRemoving:Connect(
	function(player)
		purchaseDebounce[player] =
			nil
	end
)

print("")
print("========================================")
print("🏪 UPGRADE SHOP V2 - GUI")
print("========================================")
print("✅ E now opens shop GUI")
print("✅ Wooden Crate row")
print("✅ Buy 1")
print("✅ Buy 10")
print("✅ Server validates purchases")
print("✅ Wooden Crate price = $" .. tostring(PRICE))
print("========================================")
print("")
