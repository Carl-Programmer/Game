--========================================================
-- 🏘 POTATIUM TOWN SHOPS BUILDER V11
--
-- ✅ Large shops
-- ✅ Large readable shop names
-- ✅ SIGNS DO NOT RENDER THROUGH OTHER BUILDINGS
-- ✅ Extended roofs
-- ✅ No NPC
-- ✅ Invisible InteractionBar
-- ✅ Potato Trader details
-- ✅ Equipment Shop details
-- ✅ Upgrade Shop details
-- ✅ Much more detailed Under Construction shop
-- ✅ Movable individual shop bases
--
-- VISUAL ONLY
--========================================================

local Workspace =
	game:GetService("Workspace")

--========================================================
-- SETTINGS
--========================================================

local BASE_FOLDER_NAME =
	"ShopBases"

local GENERATED_FOLDER_NAME =
	"PotatiumTownShops"

local SHOP_SCALE =
	1.6

local SHOP_NAME_TEXT_SIZE =
	190

--========================================================
-- COLORS
--========================================================

local COLORS = {

	StoneDark =
		Color3.fromRGB(
			39,
			42,
			47
		),

	Stone =
		Color3.fromRGB(
			63,
			66,
			71
		),

	StoneLight =
		Color3.fromRGB(
			84,
			87,
			92
		),

	WoodDark =
		Color3.fromRGB(
			62,
			38,
			24
		),

	Wood =
		Color3.fromRGB(
			108,
			67,
			39
		),

	WoodLight =
		Color3.fromRGB(
			154,
			100,
			55
		),

	Roof =
		Color3.fromRGB(
			46,
			72,
			58
		),

	RoofDark =
		Color3.fromRGB(
			34,
			54,
			44
		),

	Metal =
		Color3.fromRGB(
			68,
			72,
			76
		),

	Lantern =
		Color3.fromRGB(
			255,
			177,
			65
		),

	Potato =
		Color3.fromRGB(
			180,
			129,
			71
		),

	Sack =
		Color3.fromRGB(
			168,
			137,
			94
		),

	Leaf =
		Color3.fromRGB(
			72,
			132,
			65
		),

	LeafDark =
		Color3.fromRGB(
			52,
			103,
			50
		),

	Upgrade =
		Color3.fromRGB(
			108,
			213,
			80
		),

	Yellow =
		Color3.fromRGB(
			237,
			171,
			45
		),

	Orange =
		Color3.fromRGB(
			204,
			105,
			32
		),

	Black =
		Color3.fromRGB(
			25,
			25,
			25
		),
}

--========================================================
-- FIND SHOP BASES
--========================================================

local baseFolder =
	Workspace:FindFirstChild(
		BASE_FOLDER_NAME
	)

if not baseFolder then

	warn("")
	warn("======================================")
	warn("❌ SHOP BASES NOT FOUND")
	warn("======================================")
	warn("Workspace")
	warn("└── ShopBases")
	warn("    ├── PotatoTraderBase")
	warn("    ├── EquipmentShopBase")
	warn("    ├── UpgradeShopBase")
	warn("    └── ConstructionShopBase")
	warn("======================================")
	warn("")

	return
end

--========================================================
-- REMOVE OLD GENERATED SHOPS
--========================================================

local oldFolder =
	Workspace:FindFirstChild(
		GENERATED_FOLDER_NAME
	)

if oldFolder then
	oldFolder:Destroy()
end

local generatedFolder =
	Instance.new("Folder")

generatedFolder.Name =
	GENERATED_FOLDER_NAME

generatedFolder.Parent =
	Workspace

--========================================================
-- CFRAME HELPER
--========================================================

local function cf(
	origin,
	x,
	y,
	z,
	rx,
	ry,
	rz
)

	return
		origin
		*
		CFrame.new(
			x or 0,
			y or 0,
			z or 0
		)
		*
		CFrame.Angles(
			math.rad(rx or 0),
			math.rad(ry or 0),
			math.rad(rz or 0)
		)
end

--========================================================
-- CREATE PART
--========================================================

local function createPart(
	parent,
	name,
	size,
	cframe,
	color,
	material,
	canCollide
)

	local newPart =
		Instance.new("Part")

	newPart.Name =
		name

	newPart.Size =
		size

	newPart.CFrame =
		cframe

	newPart.Color =
		color

	newPart.Material =
		material
		or
		Enum.Material.SmoothPlastic

	newPart.Anchored =
		true

	newPart.CanCollide =
		canCollide ~= false

	newPart.TopSurface =
		Enum.SurfaceType.Smooth

	newPart.BottomSurface =
		Enum.SurfaceType.Smooth

	newPart.Parent =
		parent

	return newPart
end

--========================================================
-- BALL
--========================================================

local function createBall(
	parent,
	name,
	size,
	cframe,
	color
)

	local newPart =
		createPart(
			parent,
			name,
			size,
			cframe,
			color,
			Enum.Material.SmoothPlastic,
			true
		)

	newPart.Shape =
		Enum.PartType.Ball

	return newPart
end

--========================================================
-- CYLINDER
--========================================================

local function createCylinder(
	parent,
	name,
	size,
	cframe,
	color,
	material
)

	local newPart =
		createPart(
			parent,
			name,
			size,
			cframe,
			color,
			material
			or
			Enum.Material.Wood,
			true
		)

	newPart.Shape =
		Enum.PartType.Cylinder

	return newPart
end

--========================================================
-- PREPARE BASE
--========================================================

local function prepareBase(
	base
)

	base.Anchored =
		true

	base.Size =
		Vector3.new(
			36,
			1,
			28
		)

	base.Material =
		Enum.Material.Slate

	base.Color =
		COLORS.StoneDark

	return
		base.CFrame
		*
		CFrame.new(
			0,
			base.Size.Y / 2,
			0
		)
end

--========================================================
-- SCALE ENTIRE SHOP
--========================================================

local function scaleShop(
	model,
	origin
)

	for _, object in ipairs(
		model:GetDescendants()
	) do

		if object:IsA("BasePart") then

			local relative =
				origin:ToObjectSpace(
					object.CFrame
				)

			local position =
				relative.Position

			local rotation =
				relative.Rotation

			object.Size =
				object.Size
				*
				SHOP_SCALE

			object.CFrame =
				origin
				*
				CFrame.new(
					position
						*
						SHOP_SCALE
				)
				*
				rotation

		elseif object:IsA("PointLight") then

			object.Range =
				object.Range
				*
				SHOP_SCALE
		end
	end
end

--========================================================
-- FOUNDATION
--========================================================

local function createFoundation(
	model,
	origin
)

	createPart(
		model,
		"StoneFoundation",

		Vector3.new(
			21.5,
			0.4,
			16.5
		),

		cf(
			origin,
			0,
			0.2,
			0
		),

		COLORS.Stone,

		Enum.Material.Slate
	)

	createPart(
		model,
		"InnerFloor",

		Vector3.new(
			16.8,
			0.34,
			11.8
		),

		cf(
			origin,
			0,
			0.5,
			0.35
		),

		COLORS.WoodDark,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"StepBottom",

		Vector3.new(
			7.2,
			0.42,
			1.7
		),

		cf(
			origin,
			0,
			0.33,
			-7.25
		),

		COLORS.StoneLight,

		Enum.Material.Slate
	)

	createPart(
		model,
		"StepTop",

		Vector3.new(
			6.2,
			0.36,
			1.2
		),

		cf(
			origin,
			0,
			0.65,
			-6.55
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)
end

--========================================================
-- TIMBER POST
--========================================================

local function timberPost(
	model,
	origin,
	x,
	y,
	z,
	height
)

	createPart(
		model,
		"TimberPost",

		Vector3.new(
			0.75,
			height,
			0.75
		),

		cf(
			origin,
			x,
			y,
			z
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)
end

--========================================================
-- MAIN SHOP FRAME
--========================================================

local function createFrame(
	model,
	origin
)

	for _, x in ipairs({
		-6.8,
		6.8,
	}) do

		for _, z in ipairs({
			-4.8,
			4.4,
		}) do

			timberPost(
				model,
				origin,
				x,
				4.35,
				z,
				7.5
			)
		end
	end

	createPart(
		model,
		"FrontTopBeam",

		Vector3.new(
			14.4,
			0.72,
			0.72
		),

		cf(
			origin,
			0,
			7.75,
			-4.8
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"BackTopBeam",

		Vector3.new(
			14.4,
			0.72,
			0.72
		),

		cf(
			origin,
			0,
			7.75,
			4.4
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"BackWall",

		Vector3.new(
			12.9,
			6.4,
			0.45
		),

		cf(
			origin,
			0,
			4.1,
			4.15
		),

		COLORS.WoodDark,

		Enum.Material.WoodPlanks
	)

	for _, x in ipairs({
		-6.5,
		6.5,
	}) do

		createPart(
			model,
			"SideWall",

			Vector3.new(
				0.45,
				6.3,
				8.7
			),

			cf(
				origin,
				x,
				4.05,
				-0.15
			),

			COLORS.WoodDark,

			Enum.Material.WoodPlanks
		)
	end

	for _, x in ipairs({
		-6.85,
		6.85,
	}) do

		for _, y in ipairs({
			2.5,
			5.25,
		}) do

			createPart(
				model,
				"SideDecorBeam",

				Vector3.new(
					0.8,
					0.34,
					8.9
				),

				cf(
					origin,
					x,
					y,
					-0.15
				),

				COLORS.WoodLight,

				Enum.Material.WoodPlanks,

				false
			)
		end
	end
end

--========================================================
-- FRONT COUNTER
--========================================================

local function createCounter(
	model,
	origin
)

	createPart(
		model,
		"CounterFront",

		Vector3.new(
			11.5,
			2.5,
			0.5
		),

		cf(
			origin,
			0,
			2.05,
			-4.55
		),

		COLORS.WoodDark,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"CounterTop",

		Vector3.new(
			12,
			0.42,
			1.8
		),

		cf(
			origin,
			0,
			3.48,
			-4.25
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"CounterSupportLeft",

		Vector3.new(
			0.4,
			2.5,
			0.4
		),

		cf(
			origin,
			-5.35,
			2.1,
			-4.45
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"CounterSupportRight",

		Vector3.new(
			0.4,
			2.5,
			0.4
		),

		cf(
			origin,
			5.35,
			2.1,
			-4.45
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)
end

--========================================================
-- INVISIBLE INTERACTION BAR
--========================================================

local function createInteractionBar(
	model,
	origin,
	shopType
)

	local interaction =
		createPart(
			model,
			"InteractionBar",

			Vector3.new(
				10,
				2.5,
				1
			),

			cf(
				origin,
				0,
				3.5,
				-5
			),

			Color3.new(
				1,
				1,
				1
			),

			Enum.Material.SmoothPlastic,

			false
		)

	interaction.Transparency =
		1

	interaction.CanCollide =
		false

	interaction.CanTouch =
		false

	interaction.CanQuery =
		true

	interaction:SetAttribute(
		"ShopType",
		shopType
	)

	interaction:SetAttribute(
		"Interactive",
		true
	)
end

--========================================================
-- EXTENDED ROOF
--========================================================

local function createRoof(
	model,
	origin
)

	local EAVE_Y =
		7.75

	local RIDGE_Y =
		12

	local HALF_WIDTH =
		8.8

	local ROOF_DEPTH =
		16.4

	local rise =
		RIDGE_Y
		-
		EAVE_Y

	local roofLength =
		math.sqrt(
			HALF_WIDTH * HALF_WIDTH
				+
				rise * rise
		)

	local angle =
		math.deg(
			math.atan(
				rise / HALF_WIDTH
			)
		)

	local centerY =
		(EAVE_Y + RIDGE_Y)
		/
		2

	local centerX =
		HALF_WIDTH
		/
		2

	local front =
		-(ROOF_DEPTH / 2)

	local back =
		ROOF_DEPTH / 2

	createPart(
		model,
		"RoofLeft",

		Vector3.new(
			roofLength,
			0.55,
			ROOF_DEPTH
		),

		cf(
			origin,
			-centerX,
			centerY,
			0,
			0,
			0,
			angle
		),

		COLORS.Roof,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"RoofRight",

		Vector3.new(
			roofLength,
			0.55,
			ROOF_DEPTH
		),

		cf(
			origin,
			centerX,
			centerY,
			0,
			0,
			0,
			-angle
		),

		COLORS.Roof,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"RoofRidge",

		Vector3.new(
			0.72,
			0.72,
			ROOF_DEPTH + 0.35
		),

		cf(
			origin,
			0,
			RIDGE_Y + 0.08,
			0
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"FrontRoofTrimLeft",

		Vector3.new(
			roofLength,
			0.36,
			0.4
		),

		cf(
			origin,
			-centerX,
			centerY,
			front - 0.12,
			0,
			0,
			angle
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks,

		false
	)

	createPart(
		model,
		"FrontRoofTrimRight",

		Vector3.new(
			roofLength,
			0.36,
			0.4
		),

		cf(
			origin,
			centerX,
			centerY,
			front - 0.12,
			0,
			0,
			-angle
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks,

		false
	)

	createPart(
		model,
		"BackRoofTrimLeft",

		Vector3.new(
			roofLength,
			0.32,
			0.36
		),

		cf(
			origin,
			-centerX,
			centerY,
			back + 0.12,
			0,
			0,
			angle
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks,

		false
	)

	createPart(
		model,
		"BackRoofTrimRight",

		Vector3.new(
			roofLength,
			0.32,
			0.36
		),

		cf(
			origin,
			centerX,
			centerY,
			back + 0.12,
			0,
			0,
			-angle
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks,

		false
	)

	createPart(
		model,
		"LeftRoofFascia",

		Vector3.new(
			0.42,
			0.68,
			ROOF_DEPTH + 0.2
		),

		cf(
			origin,
			-HALF_WIDTH,
			EAVE_Y,
			0
		),

		COLORS.WoodDark,

		Enum.Material.WoodPlanks,

		false
	)

	createPart(
		model,
		"RightRoofFascia",

		Vector3.new(
			0.42,
			0.68,
			ROOF_DEPTH + 0.2
		),

		cf(
			origin,
			HALF_WIDTH,
			EAVE_Y,
			0
		),

		COLORS.WoodDark,

		Enum.Material.WoodPlanks,

		false
	)
end

--========================================================
-- MAIN SHOP SIGN
--
-- IMPORTANT:
--
-- AlwaysOnTop = FALSE
--
-- This stops ALL SHOP SIGNS from showing
-- through another building.
--========================================================

local function createMainSign(
	model,
	origin,
	text,
	textSize
)

	local board =
		createPart(
			model,
			"MainSign",

			Vector3.new(
				14.5,
				2.2,
				0.5
			),

			cf(
				origin,
				0,
				7.2,
				-8.55
			),

			COLORS.WoodLight,

			Enum.Material.WoodPlanks,

			false
		)

	createPart(
		model,
		"SignTopBorder",

		Vector3.new(
			14.8,
			0.18,
			0.58
		),

		cf(
			origin,
				0,
				8.25,
				-8.56
			),

		COLORS.WoodDark,

		Enum.Material.WoodPlanks,

		false
	)

	createPart(
		model,
		"SignBottomBorder",

		Vector3.new(
			14.8,
			0.18,
			0.58
		),

		cf(
			origin,
				0,
				6.15,
				-8.56
			),

		COLORS.WoodDark,

		Enum.Material.WoodPlanks,

		false
	)

	local gui =
		Instance.new("SurfaceGui")

	gui.Name =
		"ShopNameGui"

	gui.Face =
		Enum.NormalId.Front

	--====================================================
	-- CRITICAL FIX
	--====================================================

	gui.AlwaysOnTop =
		false

	gui.LightInfluence =
		0

	gui.CanvasSize =
		Vector2.new(
			1800,
			320
		)

	gui.Parent =
		board

	local label =
		Instance.new("TextLabel")

	label.Name =
		"ShopName"

	label.Size =
		UDim2.fromScale(
			1,
			1
		)

	label.BackgroundTransparency =
		1

	label.Text =
		text

	label.TextScaled =
		false

	label.TextSize =
		textSize
		or
		SHOP_NAME_TEXT_SIZE

	label.TextWrapped =
		false

	label.Font =
		Enum.Font.GothamBlack

	label.TextXAlignment =
		Enum.TextXAlignment.Center

	label.TextYAlignment =
		Enum.TextYAlignment.Center

	label.TextColor3 =
		Color3.fromRGB(
			255,
			239,
			196
		)

	label.TextStrokeColor3 =
		Color3.fromRGB(
			30,
			17,
			8
		)

	label.TextStrokeTransparency =
		0

	label.Parent =
		gui
end

--========================================================
-- LANTERN
--========================================================

local function createLantern(
	model,
	origin,
	x,
	y,
	z
)

	createPart(
		model,
		"LanternCase",

		Vector3.new(
			0.55,
			0.85,
			0.55
		),

		cf(
			origin,
			x,
			y,
			z
		),

		COLORS.Metal,

		Enum.Material.Metal,

		false
	)

	local glow =
		createPart(
			model,
			"LanternGlow",

			Vector3.new(
				0.3,
				0.5,
				0.3
			),

			cf(
				origin,
				x,
				y,
				z
			),

			COLORS.Lantern,

			Enum.Material.Neon,

			false
		)

	local light =
		Instance.new("PointLight")

	light.Color =
		Color3.fromRGB(
			255,
			198,
			116
		)

	light.Brightness =
		0.6

	light.Range =
		7

	light.Shadows =
		true

	light.Parent =
		glow
end

--========================================================
-- LANTERN POST
--========================================================

local function createLanternPost(
	model,
	origin,
	x,
	z
)

	createPart(
		model,
		"LanternPost",

		Vector3.new(
			0.35,
			3.5,
			0.35
		),

		cf(
			origin,
			x,
			2,
			z
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"LanternArm",

		Vector3.new(
			1.2,
			0.28,
			0.28
		),

		cf(
			origin,
			x + 0.45,
			3.55,
			z
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	createLantern(
		model,
		origin,
		x + 0.85,
		3.05,
		z
	)
end

--========================================================
-- CRATE
--========================================================

local function createCrate(
	model,
	origin,
	x,
	y,
	z,
	scale
)

	scale =
		scale or 1

	createPart(
		model,
		"Crate",

		Vector3.new(
			1.9 * scale,
			1.7 * scale,
			1.9 * scale
		),

		cf(
			origin,
			x,
			y,
			z
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)
end

--========================================================
-- BARREL
--========================================================

local function createBarrel(
	model,
	origin,
	x,
	y,
	z
)

	createCylinder(
		model,
		"Barrel",

		Vector3.new(
			2.25,
			1.7,
			1.7
		),

		cf(
			origin,
			x,
			y,
			z,
			0,
			0,
			90
		),

		COLORS.Wood,

		Enum.Material.Wood
	)
end

--========================================================
-- POTATO
--========================================================

local function createPotato(
	model,
	origin,
	x,
	y,
	z,
	scale
)

	scale =
		scale or 1

	createBall(
		model,
		"Potato",

		Vector3.new(
			0.65 * scale,
			0.5 * scale,
			0.62 * scale
		),

		cf(
			origin,
			x,
			y,
			z
		),

		COLORS.Potato
	)
end

--========================================================
-- POTATO SACK
--========================================================

local function createPotatoSack(
	model,
	origin,
	x,
	y,
	z
)

	createBall(
		model,
		"PotatoSack",

		Vector3.new(
			1.8,
			2.1,
			1.6
		),

		cf(
			origin,
			x,
			y,
			z
		),

		COLORS.Sack
	)

	for i = 1, 4 do

		createPotato(
			model,
			origin,

			x
				+
				(i - 2.5)
				*
				0.35,

			y + 1.05,

			z,

			0.8
		)
	end
end

--========================================================
-- PLANTER
--========================================================

local function createPlanter(
	model,
	origin,
	x,
	z
)

	createPart(
		model,
		"Planter",

		Vector3.new(
			3,
			0.8,
			1.4
		),

		cf(
			origin,
			x,
			0.9,
			z
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	for i = 1, 5 do

		createPart(
			model,
			"Plant",

			Vector3.new(
				0.22,
				1.1
					+
					(i % 2)
					*
					0.3,
				0.22
			),

			cf(
				origin,

				x
					-
					1
					+
					(i - 1)
					*
					0.5,

				1.6,

				z
			),

			i % 2 == 0
				and COLORS.Leaf
				or COLORS.LeafDark,

			Enum.Material.Grass,

			false
		)
	end
end

--========================================================
-- FENCE
--========================================================

local function createFence(
	model,
	origin,
	x,
	z,
	width
)

	width =
		width or 3

	for _, dx in ipairs({
		-width / 2,
		width / 2,
	}) do

		createPart(
			model,
			"FencePost",

			Vector3.new(
				0.35,
				1.5,
				0.35
			),

			cf(
				origin,
				x + dx,
				1,
				z
			),

			COLORS.Wood,

			Enum.Material.WoodPlanks
		)
	end

	for _, y in ipairs({
		0.8,
		1.35,
	}) do

		createPart(
			model,
			"FenceRail",

			Vector3.new(
				width,
				0.22,
				0.22
			),

			cf(
				origin,
				x,
				y,
				z
			),

			COLORS.WoodLight,

			Enum.Material.WoodPlanks
		)
	end
end

--========================================================
-- BENCH
--========================================================

local function createBench(
	model,
	origin,
	x,
	z
)

	createPart(
		model,
		"BenchSeat",

		Vector3.new(
			3,
			0.25,
			0.9
		),

		cf(
			origin,
			x,
			1.35,
			z
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"BenchBack",

		Vector3.new(
			3,
			1,
			0.2
		),

		cf(
			origin,
			x,
			1.85,
			z + 0.32
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	for _, dx in ipairs({
		-1,
		1,
	}) do

		createPart(
			model,
			"BenchLeg",

			Vector3.new(
				0.22,
				1,
				0.22
			),

			cf(
				origin,
				x + dx,
				0.85,
				z
			),

			COLORS.WoodDark,

			Enum.Material.WoodPlanks
		)
	end
end

--========================================================
-- MARKET STAND
--========================================================

local function createMarketStand(
	model,
	origin,
	x,
	z,
	width
)

	width =
		width or 4

	createPart(
		model,
		"MarketStandTop",

		Vector3.new(
			width,
			0.3,
			1.8
		),

		cf(
			origin,
			x,
			1.9,
			z
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks
	)

	for _, dx in ipairs({
		-width / 2 + 0.4,
		width / 2 - 0.4,
	}) do

		createPart(
			model,
			"MarketStandLeg",

			Vector3.new(
				0.32,
				1.7,
				0.32
			),

			cf(
				origin,
				x + dx,
				1,
				z
			),

			COLORS.Wood,

			Enum.Material.WoodPlanks
		)
	end
end

--========================================================
-- STANDARD SHOP
--========================================================

local function createStandardShop(
	name,
	base,
	title
)

	local model =
		Instance.new("Model")

	model.Name =
		name

	model.Parent =
		generatedFolder

	local origin =
		prepareBase(
			base
		)

	createFoundation(
		model,
		origin
	)

	createFrame(
		model,
		origin
	)

	createCounter(
		model,
		origin
	)

	createRoof(
		model,
		origin
	)

	createMainSign(
		model,
		origin,
		title
	)

	createInteractionBar(
		model,
		origin,
		name
	)

	createLantern(
		model,
		origin,
		-6.2,
		6.25,
		-5.2
	)

	createLantern(
		model,
		origin,
		6.2,
		6.25,
		-5.2
	)

	return model, origin
end

--========================================================
-- POTATO TRADER
--========================================================

local function buildPotatoTrader(
	base
)

	local model,
		origin =
		createStandardShop(
			"PotatoTrader",
			base,
			"POTATO TRADER"
		)

	createMarketStand(
		model,
		origin,
		-7.4,
		-5.5,
		4
	)

	for i = 1, 6 do

		createPotato(
			model,
			origin,

			-8.9
				+
				i
				*
				0.5,

			2.25,

			-5.5,

			0.8
		)
	end

	createPotatoSack(
		model,
		origin,
		6.3,
		1.7,
		-4.8
	)

	createPotatoSack(
		model,
		origin,
		8,
		1.7,
		-2.8
	)

	createCrate(
		model,
		origin,
		-7.2,
		1.25,
		-2.7,
		0.9
	)

	createBarrel(
		model,
		origin,
		7,
		1.45,
		-1.2
	)

	for i = 1, 6 do

		createPotato(
			model,
			origin,

			-2.5
				+
				i
				*
				0.72,

			3.8,

			-4.25,

			0.72
		)
	end

	createPlanter(
		model,
		origin,
		-7,
		3
	)

	createBench(
		model,
		origin,
		7,
		3.8
	)

	createFence(
		model,
		origin,
		-7,
		5,
		3.4
	)

	createLanternPost(
		model,
		origin,
		-9,
		-4.3
	)

	scaleShop(
		model,
		origin
	)
end

--========================================================
-- TOOL DISPLAY
--========================================================

local function createToolDisplay(
	model,
	origin,
	x,
	z
)

	createMarketStand(
		model,
		origin,
		x,
		z,
		4.2
	)

	for i = 1, 4 do

		local toolX =
			x
			-
			1.3
			+
			(i - 1)
			*
			0.85

		createPart(
			model,
			"ToolHandle",

			Vector3.new(
				0.18,
				2.6,
				0.18
			),

			cf(
				origin,
				toolX,
				3.25,
				z
			),

			COLORS.WoodLight,

			Enum.Material.Wood,

			false
		)

		createPart(
			model,
			"ToolHead",

			Vector3.new(
				0.85,
				0.28,
				0.35
			),

			cf(
				origin,
				toolX,
				4.55,
				z
			),

			COLORS.Metal,

			Enum.Material.Metal,

			false
		)
	end
end

--========================================================
-- EQUIPMENT SHOP
--========================================================

local function buildEquipmentShop(
	base
)

	local model,
		origin =
		createStandardShop(
			"EquipmentShop",
			base,
			"EQUIPMENT SHOP"
		)

	createToolDisplay(
		model,
		origin,
		-7.4,
		-5.5
	)

	createCrate(
		model,
		origin,
		6.8,
		1.3,
		-4.7,
		1
	)

	createBarrel(
		model,
		origin,
		7.5,
		1.45,
		-2.5
	)

	for i = 1, 4 do

		createPart(
			model,
			"CounterTool",

			Vector3.new(
				1.1,
				0.14,
				0.32
			),

			cf(
				origin,

				-2.2
					+
					i,

				3.85,

				-4.25,

				0,
				12 * i,
				0
			),

			COLORS.Metal,

			Enum.Material.Metal,

			false
		)
	end

	createPart(
		model,
		"ToolRack",

		Vector3.new(
			4,
			0.35,
			0.4
		),

		cf(
			origin,
			4.3,
			5.4,
			-4.75
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks,

		false
	)

	for i = 1, 3 do

		local x =
			3.5
			+
			(i - 1)
			*
			0.8

		createPart(
			model,
			"RackToolHandle",

			Vector3.new(
				0.18,
				2.1,
				0.18
			),

			cf(
				origin,
				x,
				4.2,
				-4.82
			),

			COLORS.WoodLight,

			Enum.Material.Wood,

			false
		)

		createPart(
			model,
			"RackToolHead",

			Vector3.new(
				0.82,
				0.25,
				0.32
			),

			cf(
				origin,
				x,
				5.25,
				-4.82
			),

			COLORS.Metal,

			Enum.Material.Metal,

			false
		)
	end

	createPlanter(
		model,
		origin,
		-7,
		3
	)

	createBench(
		model,
		origin,
		7,
		3.8
	)

	createFence(
		model,
		origin,
		7,
		5,
		3.5
	)

	createLanternPost(
		model,
		origin,
		-9,
		-4.3
	)

	scaleShop(
		model,
		origin
	)
end

--========================================================
-- GEAR
--========================================================

local function createGear(
	model,
	origin,
	x,
	y,
	z,
	scale
)

	scale =
		scale or 1

	createCylinder(
		model,
		"Gear",

		Vector3.new(
			0.4 * scale,
			2 * scale,
			2 * scale
		),

		cf(
			origin,
			x,
			y,
			z,
			0,
			90,
			0
		),

		COLORS.Metal,

		Enum.Material.Metal
	)
end

--========================================================
-- UPGRADE SHOP
--========================================================

local function buildUpgradeShop(
	base
)

	local model,
		origin =
		createStandardShop(
			"UpgradeShop",
			base,
			"UPGRADE SHOP"
		)

	createMarketStand(
		model,
		origin,
		-7.4,
		-5.5,
		4
	)

	for i = 1, 3 do

		local height =
			0.8
			+
			i
			*
			0.5

		createPart(
			model,
			"UpgradeDisplay",

			Vector3.new(
				0.45,
				height,
				0.45
			),

			cf(
				origin,

				-8.7
					+
					i
					*
					0.95,

				2.15
					+
					height / 2,

				-5.5
			),

			COLORS.Upgrade,

			Enum.Material.Neon,

			false
		)
	end

	createGear(
		model,
		origin,
		6,
		1.8,
		-4.8,
		0.8
	)

	createGear(
		model,
		origin,
		7,
		1.3,
		-3,
		0.55
	)

	createCrate(
		model,
		origin,
		6.3,
		1.2,
		-1.3,
		0.9
	)

	createPlanter(
		model,
		origin,
		-7,
		3
	)

	createBench(
		model,
		origin,
		7,
		3.8
	)

	createFence(
		model,
		origin,
		7,
		5,
		3.5
	)

	createLanternPost(
		model,
		origin,
		-9,
		-4.3
	)

	scaleShop(
		model,
		origin
	)
end

--========================================================
-- CONSTRUCTION LADDER
--========================================================

local function createConstructionLadder(
	model,
	origin,
	x,
	y,
	z,
	height,
	rotationY
)

	local railGap =
		0.9

	createPart(
		model,
		"LadderRail",

		Vector3.new(
			0.18,
			height,
			0.18
		),

		cf(
			origin,
			x - railGap,
			y,
			z,
			0,
			rotationY,
			-8
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"LadderRail",

		Vector3.new(
			0.18,
			height,
			0.18
		),

		cf(
			origin,
			x + railGap,
			y,
			z,
			0,
			rotationY,
			-8
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks
	)

	local steps =
		math.floor(
			height / 0.7
		)

	for i = 1, steps do

		createPart(
			model,
			"LadderStep",

			Vector3.new(
				2,
				0.16,
				0.16
			),

			cf(
				origin,
				x,
				y
					-
					height / 2
					+
					i * 0.7,
				z,
				0,
				rotationY,
				-8
			),

			COLORS.WoodLight,

			Enum.Material.WoodPlanks
		)
	end
end

--========================================================
-- SCAFFOLDING
--========================================================

local function createScaffolding(
	model,
	origin
)

	--====================================================
	-- FRONT-RIGHT SCAFFOLD POSTS
	--====================================================

	for _, x in ipairs({
		4.7,
		7.6,
	}) do

		for _, z in ipairs({
			-4.5,
			-1.3,
		}) do

			createPart(
				model,
				"ScaffoldPost",

				Vector3.new(
					0.28,
					5.8,
					0.28
				),

				cf(
					origin,
					x,
					3.4,
					z
				),

				COLORS.WoodLight,

				Enum.Material.WoodPlanks
			)
		end
	end

	--====================================================
	-- SCAFFOLD PLATFORMS
	--====================================================

	createPart(
		model,
		"ScaffoldPlatformLow",

		Vector3.new(
			3.5,
			0.3,
			4
		),

		cf(
			origin,
			6.15,
			2.2,
			-2.9
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"ScaffoldPlatformHigh",

		Vector3.new(
			3.5,
			0.3,
			4
		),

		cf(
			origin,
			6.15,
			5.2,
			-2.9
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks
	)

	--====================================================
	-- HORIZONTAL SCAFFOLD RAILS
	--====================================================

	for _, y in ipairs({
		2.5,
		4.2,
		5.9,
	}) do

		createPart(
			model,
			"ScaffoldRail",

			Vector3.new(
				3.2,
				0.2,
				0.2
			),

			cf(
				origin,
				6.15,
				y,
				-4.5
			),

			COLORS.WoodLight,

			Enum.Material.WoodPlanks
		)

		createPart(
			model,
			"ScaffoldRail",

			Vector3.new(
				3.2,
				0.2,
				0.2
			),

			cf(
				origin,
				6.15,
				y,
				-1.3
			),

			COLORS.WoodLight,

			Enum.Material.WoodPlanks
		)
	end

	--====================================================
	-- DIAGONAL SUPPORTS
	--====================================================

	createPart(
		model,
		"ScaffoldBrace",

		Vector3.new(
			0.22,
			5,
			0.22
		),

		cf(
			origin,
			4.9,
			3.5,
			-4.6,
			0,
			0,
			-28
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"ScaffoldBrace",

		Vector3.new(
			0.22,
			5,
			0.22
		),

		cf(
			origin,
			7.4,
			3.5,
			-1.2,
			0,
			0,
			28
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks
	)
end

--========================================================
-- CONSTRUCTION TOOL PILE
--========================================================

local function createConstructionTools(
	model,
	origin
)

	-- hammer handle

	createPart(
		model,
		"HammerHandle",

		Vector3.new(
			0.18,
			2.3,
			0.18
		),

		cf(
			origin,
			-5.8,
			1.7,
			-4.7,
			0,
			0,
			35
		),

		COLORS.WoodLight,

		Enum.Material.Wood,

		false
	)

	createPart(
		model,
		"HammerHead",

		Vector3.new(
			0.85,
			0.3,
			0.4
		),

		cf(
			origin,
			-5.15,
			2.55,
			-4.7,
			0,
			0,
			35
		),

		COLORS.Metal,

		Enum.Material.Metal,

		false
	)

	-- saw-ish tool

	createPart(
		model,
		"ConstructionSaw",

		Vector3.new(
			2,
			0.18,
			0.5
		),

		cf(
			origin,
			-3.8,
			1.1,
			-5.2,
			0,
			18,
			0
		),

		COLORS.Metal,

		Enum.Material.Metal,

		false
	)

	-- toolbox

	createPart(
		model,
		"ToolBox",

		Vector3.new(
			2.2,
			1,
			1.3
		),

		cf(
			origin,
			-3,
			1,
			-3.8
		),

		COLORS.WoodDark,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"ToolBoxHandle",

		Vector3.new(
			1.3,
			0.18,
			0.18
		),

		cf(
			origin,
			-3,
			1.65,
			-3.8
		),

		COLORS.Metal,

		Enum.Material.Metal,

		false
	)
end

--========================================================
-- UNDER CONSTRUCTION SHOP
--========================================================

local function buildConstructionShop(
	base
)

	local model =
		Instance.new("Model")

	model.Name =
		"UnderConstructionShop"

	model.Parent =
		generatedFolder

	local origin =
		prepareBase(
			base
		)

	createFoundation(
		model,
		origin
	)

	--====================================================
	-- MAIN POSTS
	--====================================================

	for _, x in ipairs({
		-6.8,
		6.8,
	}) do

		for _, z in ipairs({
			-4.8,
			4.4,
		}) do

			timberPost(
				model,
				origin,
				x,
				4.35,
				z,
				7.5
			)
		end
	end

	--====================================================
	-- FRONT + BACK BEAM
	--====================================================

	createPart(
		model,
		"ConstructionFrontBeam",

		Vector3.new(
			14.4,
			0.72,
			0.72
		),

		cf(
			origin,
			0,
			7.75,
			-4.8
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"ConstructionBackBeam",

		Vector3.new(
			14.4,
			0.72,
			0.72
		),

		cf(
			origin,
			0,
			7.75,
			4.4
		),

		COLORS.Wood,

		Enum.Material.WoodPlanks
	)

	--====================================================
	-- CROSS SUPPORTS
	--====================================================

	createPart(
		model,
		"ConstructionBraceLeft",

		Vector3.new(
			0.3,
			6,
			0.3
		),

		cf(
			origin,
			-4.8,
			4.1,
			-4.9,
			0,
			0,
			42
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"ConstructionBraceRight",

		Vector3.new(
			0.3,
			6,
			0.3
		),

		cf(
			origin,
			4.8,
			4.1,
			-4.9,
			0,
			0,
			-42
		),

		COLORS.WoodLight,

		Enum.Material.WoodPlanks
	)

	--====================================================
	-- RAFTERS
	--====================================================

	local EAVE_Y =
		7.75

	local RIDGE_Y =
		12

	local HALF_WIDTH =
		8.8

	local rise =
		RIDGE_Y
		-
		EAVE_Y

	local roofLength =
		math.sqrt(
			HALF_WIDTH * HALF_WIDTH
				+
				rise * rise
		)

	local roofAngle =
		math.deg(
			math.atan(
				rise / HALF_WIDTH
			)
		)

	local centerY =
		(EAVE_Y + RIDGE_Y)
		/
		2

	local centerX =
		HALF_WIDTH
		/
		2

	for _, z in ipairs({
		-7,
		-3.5,
		0,
		3.5,
		7,
	}) do

		createPart(
			model,
			"RafterLeft",

			Vector3.new(
				roofLength,
				0.32,
				0.38
			),

			cf(
				origin,
				-centerX,
				centerY,
				z,
				0,
				0,
				roofAngle
			),

			COLORS.Wood,

			Enum.Material.WoodPlanks
		)

		createPart(
			model,
			"RafterRight",

			Vector3.new(
				roofLength,
				0.32,
				0.38
			),

			cf(
				origin,
				centerX,
				centerY,
				z,
				0,
				0,
				-roofAngle
			),

			COLORS.Wood,

			Enum.Material.WoodPlanks
		)
	end

	--====================================================
	-- PARTIAL FINISHED ROOF
	--====================================================

	createPart(
		model,
		"PartialRoofLeft",

		Vector3.new(
			roofLength,
			0.42,
			5.3
		),

		cf(
			origin,
			-centerX,
			centerY + 0.1,
			2.8,
			0,
			0,
			roofAngle
		),

		COLORS.Roof,

		Enum.Material.WoodPlanks
	)

	createPart(
		model,
		"PartialRoofRight",

		Vector3.new(
			roofLength,
			0.42,
			3.2
		),

		cf(
			origin,
			centerX,
			centerY + 0.1,
			4,
			0,
			0,
			-roofAngle
		),

		COLORS.Roof,

		Enum.Material.WoodPlanks
	)

	--====================================================
	-- MAIN SIGN
	--
	-- Slightly smaller font only because this name is long.
	--====================================================

	createMainSign(
		model,
		origin,
		"UNDER CONSTRUCTION",
		150
	)

	--====================================================
	-- SCAFFOLDING
	--====================================================

	createScaffolding(
		model,
		origin
	)

	--====================================================
	-- LADDER 1
	--====================================================

	createConstructionLadder(
		model,
		origin,
		5.8,
		3.6,
		-5.8,
		6.2,
		0
	)

	--====================================================
	-- LADDER 2
	-- Leaning at the left side
	--====================================================

	createConstructionLadder(
		model,
		origin,
		-6.4,
		3.3,
		1.5,
		5.6,
		90
	)

	--====================================================
	-- LUMBER TABLE
	--====================================================

	createMarketStand(
		model,
		origin,
		-7.3,
		-5.3,
		4.3
	)

	for i = 1, 7 do

		createPart(
			model,
			"Lumber",

			Vector3.new(
				3.8,
				0.22,
				0.35
			),

			cf(
				origin,
				-7.3,
				2.15
					+
					i
					*
					0.17,
				-5.3
			),

			i % 2 == 0
				and COLORS.WoodLight
				or COLORS.Wood,

			Enum.Material.WoodPlanks
		)
	end

	--====================================================
	-- LONG PLANK PILE
	--====================================================

	for i = 1, 5 do

		createPart(
			model,
			"LongPlank",

			Vector3.new(
				6,
				0.25,
				0.45
			),

			cf(
				origin,
				-3,
				0.9
					+
					i
					*
					0.28,
				3.5,
				0,
				8,
				0
			),

			COLORS.WoodLight,

			Enum.Material.WoodPlanks
		)
	end

	--====================================================
	-- CRATES
	--====================================================

	createCrate(
		model,
		origin,
		6.7,
		1.3,
		-5.6,
		1
	)

	createCrate(
		model,
		origin,
		8,
		1,
		-3.8,
		0.75
	)

	createCrate(
		model,
		origin,
		-7,
		1.2,
		-1.8,
		0.85
	)

	--====================================================
	-- BARRELS
	--====================================================

	createBarrel(
		model,
		origin,
		7.5,
		1.45,
		1.5
	)

	createBarrel(
		model,
		origin,
		-7.4,
		1.45,
		2.5
	)

	--====================================================
	-- CONSTRUCTION TOOLS
	--====================================================

	createConstructionTools(
		model,
		origin
	)

	--====================================================
	-- FRONT CAUTION BARRIERS
	--====================================================

	for _, x in ipairs({
		-3.8,
		3.8,
	}) do

		createPart(
			model,
			"CautionBoard",

			Vector3.new(
				4.2,
				0.65,
				0.32
			),

			cf(
				origin,
					x,
					1.8,
					-6.3,
					0,
					0,
					x < 0
						and
						6
						or
						-6
			),

			COLORS.Yellow,

			Enum.Material.WoodPlanks
		)

		for _, dx in ipairs({
			-1.4,
			1.4,
		}) do

			createPart(
				model,
				"CautionLeg",

				Vector3.new(
					0.26,
					2,
					0.26
				),

				cf(
					origin,
						x + dx,
						1,
						-6.3
				),

				COLORS.WoodDark,

				Enum.Material.Wood
			)
		end
	end

	--====================================================
	-- ROPE / BEAM STYLE SIDE RAILS
	--====================================================

	for _, z in ipairs({
		-1,
		1.2,
		3.4,
	}) do

		createPart(
			model,
			"ConstructionSideRail",

			Vector3.new(
				4.4,
				0.22,
				0.22
			),

			cf(
				origin,
				-7.3,
				3.2,
				z,
				0,
				90,
				0
			),

			COLORS.WoodLight,

			Enum.Material.WoodPlanks
		)
	end

	--====================================================
	-- LANTERN
	--====================================================

	createLanternPost(
		model,
		origin,
		-9,
		-4.3
	)

	--====================================================
	-- BENCH / WORK TABLE
	--====================================================

	createBench(
		model,
		origin,
		-7,
		4.5
	)

	--====================================================
	-- SCALE CONSTRUCTION SHOP
	--====================================================

	scaleShop(
		model,
		origin
	)
end

--========================================================
-- GET BASE
--========================================================

local function getBase(
	name
)

	local base =
		baseFolder:FindFirstChild(
			name
		)

	if
		not base
		or
		not base:IsA("BasePart")
	then

		warn(
			"❌ Missing shop base: "
				..
				name
		)

		return nil
	end

	return base
end

--========================================================
-- BASE REFERENCES
--========================================================

local potatoTraderBase =
	getBase(
		"PotatoTraderBase"
	)

local equipmentShopBase =
	getBase(
		"EquipmentShopBase"
	)

local upgradeShopBase =
	getBase(
		"UpgradeShopBase"
	)

local constructionShopBase =
	getBase(
		"ConstructionShopBase"
	)

--========================================================
-- BUILD
--========================================================

if potatoTraderBase then

	buildPotatoTrader(
		potatoTraderBase
	)
end

if equipmentShopBase then

	buildEquipmentShop(
		equipmentShopBase
	)
end

if upgradeShopBase then

	buildUpgradeShop(
		upgradeShopBase
	)
end

if constructionShopBase then

	buildConstructionShop(
		constructionShopBase
	)
end

--========================================================
-- READY
--========================================================

print("")
print("========================================")
print("🏘 POTATIUM TOWN SHOPS V11 READY")
print("========================================")
print("Shop scale: " .. tostring(SHOP_SCALE))
print("Shop font: " .. tostring(SHOP_NAME_TEXT_SIZE))
print("✅ ALL shop sign overlap fixed")
print("✅ AlwaysOnTop OFF")
print("✅ Front-facing signs only")
print("✅ Large readable names")
print("✅ Extended roofs")
print("✅ Invisible interaction bars")
print("✅ No NPCs")
print("✅ Potato Trader")
print("✅ Equipment Shop")
print("✅ Upgrade Shop")
print("✅ Construction scaffolding")
print("✅ Construction ladders")
print("✅ Construction lumber")
print("✅ Construction tools")
print("✅ Construction barrels/crates")
print("✅ Construction caution barriers")
print("========================================")
print("")