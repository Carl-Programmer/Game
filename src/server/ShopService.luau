local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)

local ShopService = {}

local DataService =
	require(
		script.Parent:WaitForChild(
			"DataService"
		)
	)

--==================================================
-- POTATO SELL PRICE PER KG
--
-- FINAL PRICE:
--
-- PricePerKg × SpudMass
--
-- Example:
-- Huge = $25/kg
-- Mass = 4.20 kg
-- Value = $105
--==================================================

local POTATO_PRICE_PER_KG = {

	Trash = 1,

	Normal = 5,

	AboveNormal = 10,

	Huge = 25,

	UltraHuge = 50,

	SuperHuge = 100,

	Godly = 500,
}

--==================================================
-- POTATO BIT PRICES
--==================================================

local BIT_PRICES = {

	Normal = 20,

	Red = 60,

	Purple = 150,

	Golden = 400,
}

--==================================================
-- REMOTE
--==================================================

local function getRemote(
	name
)

	local existing =
		ReplicatedStorage:FindFirstChild(
			name
		)

	if existing then
		return existing
	end

	local remote =
		Instance.new(
			"RemoteEvent"
		)

	remote.Name =
		name

	remote.Parent =
		ReplicatedStorage

	return remote
end

local openShopEvent =
	getRemote(
		"OpenPotatoBitShop"
	)

local buyBitEvent =
	getRemote(
		"BuyPotatoBit"
	)

--==================================================
-- BIT ATTRIBUTE
--==================================================

local function getBitAttribute(
	bitType
)

	if bitType == "Normal" then
		return "PotatoBits"
	end

	if bitType == "Red" then
		return "RedBits"
	end

	if bitType == "Purple" then
		return "PurpleBits"
	end

	if bitType == "Golden" then
		return "GoldenBits"
	end

	return nil
end

--==================================================
-- BUY BITS
--==================================================

buyBitEvent.OnServerEvent:Connect(
	function(
		player,
		bitType,
		buyAll
	)

		if player:GetAttribute(
			"DataLoaded"
		) ~= true then

			return
		end

		local price =
			BIT_PRICES[
				bitType
			]

		if not price then
			return
		end

		local attribute =
			getBitAttribute(
				bitType
			)

		if not attribute then
			return
		end

		local cash =
			player:GetAttribute(
				"Cash"
			)
			or 0

		local amount =
			1

		if buyAll == true then

			amount =
				math.floor(
					cash
					/
					price
				)

		end

		if amount <= 0 then
			return
		end

		local totalPrice =
			amount
			*
			price

		if cash < totalPrice then
			return
		end

		player:SetAttribute(
			"Cash",
			cash - totalPrice
		)

		player:SetAttribute(
			attribute,

			(
				player:GetAttribute(
					attribute
				)
				or 0
			)
			+
			amount
		)

		print(
			"🌱 "
				.. player.Name
				.. " bought "
				.. amount
				.. " "
				.. bitType
				.. " Potato Bits"
		)
	end
)

--==================================================
-- CLEAR FARM POTATO COUNTERS
--==================================================

local function clearPotatoCounters(
	player
)

	player:SetAttribute(
		"TrashPotatoes",
		0
	)

	player:SetAttribute(
		"NormalPotatoes",
		0
	)

	player:SetAttribute(
		"AboveNormalPotatoes",
		0
	)

	player:SetAttribute(
		"HugePotatoes",
		0
	)

	player:SetAttribute(
		"UltraHugePotatoes",
		0
	)

	player:SetAttribute(
		"SuperHugePotatoes",
		0
	)

	player:SetAttribute(
		"GodlyPotatoes",
		0
	)

end

--==================================================
-- CALCULATE ONE POTATO VALUE
--==================================================

local function calculatePotatoValue(
	record
)

	local tier =
		record.SizeTier
		or "Normal"

	local mass =
		tonumber(
			record.SpudMass
		)
		or 0

	local pricePerKg =
		POTATO_PRICE_PER_KG[
			tier
		]
		or 1

	local value =
		mass
		*
		pricePerKg

	return value

end

--==================================================
-- SELL ALL INDIVIDUAL FARM POTATOES
--==================================================

local function sellAllPotatoes(
	player
)

	if player:GetAttribute(
		"DataLoaded"
	) ~= true then

		return
	end

	--==================================================
	-- GET EXACT INDIVIDUAL POTATOES
	--==================================================

	local potatoRecords =
		DataService.GetPotatoInventory(
			player
		)

	if #potatoRecords <= 0 then

		print(
			"🥔 "
				.. player.Name
				.. " has no individual potatoes to sell"
		)

		return
	end

	--==================================================
	-- CALCULATE TOTAL VALUE
	--==================================================

	local earned =
		0

	local soldCount =
		0

	for _, record in ipairs(
		potatoRecords
	) do

		local value =
			calculatePotatoValue(
				record
			)

		earned +=
			value

		soldCount +=
			1

		--==================================================
		-- DEBUG
		--
		-- Example:
		-- Huge | 4.20 kg | $105
		--==================================================

		print(
			"🥔 SOLD | "
				.. tostring(
					record.SizeTier
					or "Normal"
				)
				.. " | "
				.. string.format(
					"%.2f kg",
					tonumber(
						record.SpudMass
					)
					or 0
				)
				.. " | $"
				.. string.format(
					"%.2f",
					value
				)
		)

	end

	--==================================================
	-- CASH IS CURRENTLY WHOLE NUMBERS
	--
	-- Round final total.
	--==================================================

	earned =
		math.floor(
			earned
			+ 0.5
		)

	--==================================================
	-- REMOVE INDIVIDUAL RECORDS
	--
	-- InventoryService sees the revision change
	-- and removes the potato Tools.
	--==================================================

	DataService.ClearPotatoInventory(
		player
	)

	--==================================================
	-- CLEAR FARM TIER COUNTS
	--==================================================

	clearPotatoCounters(
		player
	)

	--==================================================
	-- REMOVE SOLD POTATOES FROM TOTAL
	--
	-- We subtract instead of setting Potatoes = 0
	-- because Potatoes may also contain potatoes
	-- earned from other systems such as foraging.
	--==================================================

	local currentPotatoes =
		player:GetAttribute(
			"Potatoes"
		)
		or 0

	player:SetAttribute(
		"Potatoes",

		math.max(
			0,
			currentPotatoes
				-
				soldCount
		)
	)

	--==================================================
	-- PAY PLAYER
	--==================================================

	local cash =
		player:GetAttribute(
			"Cash"
		)
		or 0

	player:SetAttribute(
		"Cash",
		cash + earned
	)

	--==================================================
	-- OUTPUT
	--==================================================

	print(
		"========================================"
	)

	print(
		"💰 POTATO SALE"
	)

	print(
		"Player: "
			.. player.Name
	)

	print(
		"Potatoes sold: "
			.. soldCount
	)

	print(
		"Money earned: $"
			.. earned
	)

	print(
		"========================================"
	)

end

--==================================================
-- SELL SHOP
--==================================================

local function setupSellShop(
	shop
)

	local interaction =
		shop:WaitForChild(
			"InteractionPart"
		)

	local old =
		interaction:FindFirstChild(
			"SellPrompt"
		)

	if old then
		old:Destroy()
	end

	local prompt =
		Instance.new(
			"ProximityPrompt"
		)

	prompt.Name =
		"SellPrompt"

	prompt.ActionText =
		"Sell All Potatoes"

	prompt.ObjectText =
		"Potato Shop"

	prompt.KeyboardKeyCode =
		Enum.KeyCode.E

	prompt.HoldDuration =
		0.2

	prompt.MaxActivationDistance =
		10

	prompt.RequiresLineOfSight =
		false

	prompt.ClickablePrompt =
		false

	prompt.Parent =
		interaction

	prompt.Triggered:Connect(
		function(player)

			sellAllPotatoes(
				player
			)

		end
	)

end

--==================================================
-- BIT SHOP
--==================================================

local function setupBitShop(
	shop
)

	local interaction =
		shop:WaitForChild(
			"InteractionPart"
		)

	local old =
		interaction:FindFirstChild(
			"BuyPrompt"
		)

	if old then
		old:Destroy()
	end

	local prompt =
		Instance.new(
			"ProximityPrompt"
		)

	prompt.Name =
		"BuyPrompt"

	prompt.ActionText =
		"Open Shop"

	prompt.ObjectText =
		"Potato Bit Shop"

	prompt.KeyboardKeyCode =
		Enum.KeyCode.E

	prompt.HoldDuration =
		0.2

	prompt.MaxActivationDistance =
		10

	prompt.RequiresLineOfSight =
		false

	prompt.ClickablePrompt =
		false

	prompt.Parent =
		interaction

	prompt.Triggered:Connect(
		function(player)

			openShopEvent:FireClient(
				player
			)

		end
	)

end

--==================================================
-- START
--==================================================

function ShopService.Start(
	world
)

	local centralTown =
		world:WaitForChild(
			"CentralTown"
		)

	local market =
		centralTown:WaitForChild(
			"PotatoMarket"
		)

	setupSellShop(
		market:WaitForChild(
			"PotatoSellShop"
		)
	)

	setupBitShop(
		market:WaitForChild(
			"PotatoBitShop"
		)
	)

	print(
		"💰 ShopService ready"
	)

	print(
		"⚖ Spud-Mass selling enabled"
	)

	print(
		"Trash        = $1/kg"
	)

	print(
		"Normal       = $5/kg"
	)

	print(
		"Above Normal = $10/kg"
	)

	print(
		"Huge         = $25/kg"
	)

	print(
		"Ultra Huge   = $50/kg"
	)

	print(
		"Super Huge   = $100/kg"
	)

	print(
		"Godly        = $500/kg"
	)

end

return ShopService