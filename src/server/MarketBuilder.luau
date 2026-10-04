local MarketBuilder = {}

--==================================================
-- COLORS
--==================================================

local COLORS = {
	Platform = Color3.fromRGB(74, 75, 73),
	PlatformEdge = Color3.fromRGB(14, 14, 14),

	Wood = Color3.fromRGB(92, 61, 40),
	DarkWood = Color3.fromRGB(47, 33, 24),
	Brick = Color3.fromRGB(117, 79, 56),

	RoofDark = Color3.fromRGB(28, 31, 36),
	Cream = Color3.fromRGB(244, 232, 198),
	Black = Color3.fromRGB(6, 6, 6),
	WhiteCloth = Color3.fromRGB(235, 235, 235),

	BitAccent = Color3.fromRGB(100, 165, 76),
	SellAccent = Color3.fromRGB(198, 154, 75),
	EquipmentAccent = Color3.fromRGB(81, 125, 167),
	UpgradeAccent = Color3.fromRGB(151, 108, 193),
}

--==================================================
-- HELPERS
--==================================================

local function makePart(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = true
	p.CanTouch = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function makeDisplayPart(parent, name, size, cframe, color, material)
	local p = makePart(parent, name, size, cframe, color, material)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end

local function addSurfaceText(part, face, text)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = face
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.PixelsPerStud = 150
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.Text = text
	label.TextColor3 = COLORS.Cream
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.2
	stroke.Parent = label
end

local function createSignBoard(parent, name, size, cframe, text)
	local board = makePart(
		parent,
		name,
		size,
		cframe,
		COLORS.Black,
		Enum.Material.SmoothPlastic
	)

	addSurfaceText(board, Enum.NormalId.Front, text)
	return board
end

--==================================================
-- SHOP DECOR
--==================================================

local function createBitBag(parent, cframe)
	makeDisplayPart(
		parent,
		"BitBag",
		Vector3.new(2.1, 1.8, 1.3),
		cframe,
		Color3.fromRGB(164, 157, 118),
		Enum.Material.Fabric
	)

	makeDisplayPart(
		parent,
		"Stem",
		Vector3.new(0.14, 0.65, 0.14),
		cframe * CFrame.new(0, 0.45, -0.62),
		Color3.fromRGB(92, 181, 62)
	)

	makeDisplayPart(
		parent,
		"LeafL",
		Vector3.new(0.5, 0.15, 0.28),
		cframe * CFrame.new(-0.2, 0.7, -0.62) * CFrame.Angles(0, 0, math.rad(-25)),
		Color3.fromRGB(108, 197, 68)
	)

	makeDisplayPart(
		parent,
		"LeafR",
		Vector3.new(0.5, 0.15, 0.28),
		cframe * CFrame.new(0.2, 0.8, -0.62) * CFrame.Angles(0, 0, math.rad(25)),
		Color3.fromRGB(108, 197, 68)
	)
end

local function createPotatoDisplay(parent, cframe, size)
	local potato = makeDisplayPart(
		parent,
		"DisplayPotato",
		size,
		cframe,
		Color3.fromRGB(181, 140, 88),
		Enum.Material.SmoothPlastic
	)
	potato.Shape = Enum.PartType.Ball
end

--==================================================
-- CORNER SHOP
-- Open on local -Z and local -X
--==================================================

local function buildCornerShop(market, name, displayName, rootCF, accentColor, shopType)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = market

	-- floor
	makePart(
		model,
		"Floor",
		Vector3.new(17, 0.6, 17),
		rootCF * CFrame.new(0, 0.3, 0),
		COLORS.DarkWood,
		Enum.Material.WoodPlanks
	)

	-- low base trim
	makePart(
		model,
		"BaseTrimFront",
		Vector3.new(16.8, 0.35, 0.5),
		rootCF * CFrame.new(0, 0.18, -8.0),
		COLORS.Black
	)

	makePart(
		model,
		"BaseTrimSide",
		Vector3.new(0.5, 0.35, 16.8),
		rootCF * CFrame.new(-8.0, 0.18, 0),
		COLORS.Black
	)

	-- posts
	local postOffsets = {
		Vector3.new(-7.7, 5.2, -7.7),
		Vector3.new( 7.7, 5.2, -7.7),
		Vector3.new(-7.7, 5.2,  7.7),
		Vector3.new( 7.7, 5.2,  7.7),
	}

	for i, off in ipairs(postOffsets) do
		makePart(
			model,
			"Post_" .. i,
			Vector3.new(0.8, 10, 0.8),
			rootCF * CFrame.new(off.X, off.Y, off.Z),
			COLORS.Wood,
			Enum.Material.Wood
		)
	end

	-- roof
	makePart(
		model,
		"Roof",
		Vector3.new(18, 0.75, 18),
		rootCF * CFrame.new(0, 10.6, 0),
		COLORS.RoofDark,
		Enum.Material.Slate
	)

	-- accent strip on roof edge
	makePart(
		model,
		"RoofAccent",
		Vector3.new(18.25, 0.22, 18.25),
		rootCF * CFrame.new(0, 10.18, 0),
		accentColor,
		Enum.Material.SmoothPlastic
	)

	-- white awning cloth strips (front and left)
	makePart(
		model,
		"AwningFront",
		Vector3.new(14.5, 0.23, 1.35),
		rootCF * CFrame.new(0, 7.2, -7.95),
		COLORS.WhiteCloth,
		Enum.Material.Fabric
	)

	makePart(
		model,
		"AwningSide",
		Vector3.new(1.35, 0.23, 14.5),
		rootCF * CFrame.new(-7.95, 7.2, 0),
		COLORS.WhiteCloth,
		Enum.Material.Fabric
	)

	-- black sign boards like earlier
	createSignBoard(
		model,
		"FrontSign",
		Vector3.new(13.8, 2.1, 0.35),
		rootCF * CFrame.new(0, 8.45, -7.2),
		displayName
	)

	createSignBoard(
		model,
		"SideSign",
		Vector3.new(13.8, 2.1, 0.35),
		rootCF * CFrame.new(-7.2, 8.45, 0) * CFrame.Angles(0, math.rad(90), 0),
		displayName
	)

	-- closed walls
	makePart(
		model,
		"BackWall",
		Vector3.new(14.8, 6.8, 0.65),
		rootCF * CFrame.new(0, 4, 7.7),
		COLORS.DarkWood,
		Enum.Material.WoodPlanks
	)

	makePart(
		model,
		"RightWall",
		Vector3.new(0.65, 6.8, 14.8),
		rootCF * CFrame.new(7.7, 4, 0),
		COLORS.DarkWood,
		Enum.Material.WoodPlanks
	)

	-- counters / half walls
	makePart(
		model,
		"FrontCounter",
		Vector3.new(14, 3.0, 1.3),
		rootCF * CFrame.new(0, 1.8, -7.2),
		COLORS.Brick,
		Enum.Material.Brick
	)

	makePart(
		model,
		"SideCounter",
		Vector3.new(1.3, 3.0, 14),
		rootCF * CFrame.new(-7.2, 1.8, 0),
		COLORS.Brick,
		Enum.Material.Brick
	)

	-- thin top shelf trims on counters
	makePart(
		model,
		"FrontShelfTrim",
		Vector3.new(14.2, 0.22, 1.45),
		rootCF * CFrame.new(0, 3.35, -7.2),
		Color3.fromRGB(167, 126, 82),
		Enum.Material.WoodPlanks
	)

	makePart(
		model,
		"SideShelfTrim",
		Vector3.new(1.45, 0.22, 14.2),
		rootCF * CFrame.new(-7.2, 3.35, 0),
		Color3.fromRGB(167, 126, 82),
		Enum.Material.WoodPlanks
	)

	-- interaction part
	local interaction = makePart(
		model,
		"InteractionPart",
		Vector3.new(10, 6, 10),
		rootCF * CFrame.new(-2.5, 3, -2.5),
		Color3.new(1, 1, 1)
	)
	interaction.Transparency = 1
	interaction.CanCollide = false
	interaction.CanTouch = false
	interaction.CanQuery = false

	-- decorations
	if shopType == "Bits" then
		createBitBag(model, rootCF * CFrame.new(-4.5, 4.35, -6.7))
		createBitBag(model, rootCF * CFrame.new(0, 4.35, -6.7))
		createBitBag(model, rootCF * CFrame.new(4.5, 4.35, -6.7))

		createBitBag(model, rootCF * CFrame.new(-6.7, 4.35, -3.9) * CFrame.Angles(0, math.rad(90), 0))
		createBitBag(model, rootCF * CFrame.new(-6.7, 4.35, 1.0) * CFrame.Angles(0, math.rad(90), 0))
	end

	if shopType == "Sell" then
		createPotatoDisplay(model, rootCF * CFrame.new(-4.5, 4.45, -6.7), Vector3.new(1.2, 1.0, 1.35))
		createPotatoDisplay(model, rootCF * CFrame.new(0, 4.55, -6.7), Vector3.new(1.7, 1.35, 1.85))
		createPotatoDisplay(model, rootCF * CFrame.new(4.3, 4.45, -6.7), Vector3.new(1.3, 1.0, 1.45))

		createPotatoDisplay(model, rootCF * CFrame.new(-6.7, 4.5, -2.8), Vector3.new(1.55, 1.2, 1.7))
		createPotatoDisplay(model, rootCF * CFrame.new(-6.7, 4.45, 2.0), Vector3.new(1.2, 0.95, 1.35))
	end

	return model
end

--==================================================
-- OVERALL LEADERBOARD
--==================================================

local function buildLeaderboard(centralTown, platformCF)
	local old = centralTown:FindFirstChild("OverallLeaderboard")
	if old then
		old:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "OverallLeaderboard"
	model.Parent = centralTown

	local root = platformCF * CFrame.new(0, 0, 27.5)

	for _, x in ipairs({-8.5, 8.5}) do
		makePart(
			model,
			"Support",
			Vector3.new(0.9, 7, 0.9),
			root * CFrame.new(x, 3.5, 0),
			COLORS.DarkWood,
			Enum.Material.Wood
		)
	end

	makePart(
		model,
		"BoardFrame",
		Vector3.new(23, 14, 1.3),
		root * CFrame.new(0, 10, 0),
		COLORS.Black
	)

	local board = makePart(
		model,
		"BoardPart",
		Vector3.new(21.5, 12.5, 0.7),
		root * CFrame.new(0, 10, -0.7),
		Color3.fromRGB(35, 29, 24)
	)
	board.CanCollide = false
end

--==================================================
-- BUILD
--==================================================

function MarketBuilder.Build(centralTown, plaza)
	local removeNames = {
		"PotatoMarket",
		"MarketPlatform",
		"MarketBorderNorth",
		"MarketBorderSouth",
		"MarketBorderWest",
		"MarketBorderEast",
		"OverallLeaderboard",
		"PurpleTeleportPad",
	}

	for _, itemName in ipairs(removeNames) do
		local obj = centralTown:FindFirstChild(itemName)
		if obj then
			obj:Destroy()
		end
	end

	-- bigger inner market platform
	local y = plaza.Size.Y / 2 + 0.55

	local platform = makePart(
		centralTown,
		"MarketPlatform",
		Vector3.new(88, 1, 62),
		plaza.CFrame * CFrame.new(0, y, 0),
		COLORS.Platform,
		Enum.Material.Slate
	)

	local topCF = platform.CFrame * CFrame.new(0, platform.Size.Y / 2, 0)

	local halfX = platform.Size.X / 2
	local halfZ = platform.Size.Z / 2

	makePart(
		centralTown,
		"MarketBorderNorth",
		Vector3.new(89, 0.65, 0.9),
		topCF * CFrame.new(0, 0.32, -halfZ),
		COLORS.PlatformEdge
	)

	makePart(
		centralTown,
		"MarketBorderSouth",
		Vector3.new(89, 0.65, 0.9),
		topCF * CFrame.new(0, 0.32, halfZ),
		COLORS.PlatformEdge
	)

	makePart(
		centralTown,
		"MarketBorderWest",
		Vector3.new(0.9, 0.65, 62),
		topCF * CFrame.new(-halfX, 0.32, 0),
		COLORS.PlatformEdge
	)

	makePart(
		centralTown,
		"MarketBorderEast",
		Vector3.new(0.9, 0.65, 62),
		topCF * CFrame.new(halfX, 0.32, 0),
		COLORS.PlatformEdge
	)

	local market = Instance.new("Model")
	market.Name = "PotatoMarket"
	market.Parent = centralTown

	-- shops touch border
	local shopX = 35.5
	local shopZ = 22.5

	-- top-right
	buildCornerShop(
		market,
		"PotatoBitShop",
		"POTATO BIT SHOP",
		topCF * CFrame.new(shopX, 0, -shopZ) * CFrame.Angles(0, math.rad(90), 0),
		COLORS.BitAccent,
		"Bits"
	)

	-- top-left
	buildCornerShop(
		market,
		"PotatoSellShop",
		"SELL POTATOES",
		topCF * CFrame.new(-shopX, 0, -shopZ) * CFrame.Angles(0, math.rad(180), 0),
		COLORS.SellAccent,
		"Sell"
	)

	-- bottom-left
	buildCornerShop(
		market,
		"EquipmentShop",
		"EQUIPMENT SHOP",
		topCF * CFrame.new(-shopX, 0, shopZ) * CFrame.Angles(0, math.rad(-90), 0),
		COLORS.EquipmentAccent,
		"Equipment"
	)

	-- bottom-right
	buildCornerShop(
		market,
		"UpgradeShop",
		"UPGRADE SHOP",
		topCF * CFrame.new(shopX, 0, shopZ),
		COLORS.UpgradeAccent,
		"Upgrade"
	)

	buildLeaderboard(centralTown, topCF)

	print("🏘 Central Town rebuilt")
	print("🏪 Shops now use striped awning style")
	print("🪧 Signs restored")
	print("🌱 Bit bags restored")
	print("🥔 Sell potatoes display restored")
end

return MarketBuilder