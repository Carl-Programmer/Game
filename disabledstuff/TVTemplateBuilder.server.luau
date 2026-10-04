local Workspace = game:GetService("Workspace")

--==================================================
-- POTATO TV TEMPLATE BUILDER V1
--
-- Creates:
--
-- Workspace
-- └── PotatoTVTemplates
--     ├── BigMoneyTV
--     └── SmallPotatoTV
--
-- These are only MODEL TEMPLATES.
-- You will position/copy them yourself.
--
-- Later FarmTVService will connect to:
--
-- BigMoneyTV:
--   MoneyText
--
-- SmallPotatoTV:
--   RateText
--   RotText
--==================================================

local oldFolder =
	Workspace:FindFirstChild(
		"PotatoTVTemplates"
	)

if oldFolder then
	oldFolder:Destroy()
end

local templates =
	Instance.new("Folder")

templates.Name =
	"PotatoTVTemplates"

templates.Parent =
	Workspace

--==================================================
-- CREATE PART
--==================================================

local function createPart(
	parent,
	name,
	size,
	cframe,
	color,
	material
)

	local part =
		Instance.new("Part")

	part.Name =
		name

	part.Size =
		size

	part.CFrame =
		cframe

	part.Color =
		color

	part.Material =
		material
		or
		Enum.Material.SmoothPlastic

	part.Anchored =
		true

	part.CanCollide =
		false

	part.CanTouch =
		false

	part.CanQuery =
		false

	part.TopSurface =
		Enum.SurfaceType.Smooth

	part.BottomSurface =
		Enum.SurfaceType.Smooth

	part.Parent =
		parent

	return part

end

--==================================================
-- CREATE TEXT
--==================================================

local function createText(
	parent,
	name,
	position,
	size,
	text,
	textSize,
	color
)

	local label =
		Instance.new(
			"TextLabel"
		)

	label.Name =
		name

	label.Position =
		position

	label.Size =
		size

	label.BackgroundTransparency =
		1

	label.Text =
		text

	label.TextColor3 =
		color
		or
		Color3.fromRGB(
			235,
			235,
			235
		)

	label.TextStrokeTransparency =
		0.8

	label.Font =
		Enum.Font.GothamBold

	label.TextScaled =
		false

	label.TextSize =
		textSize

	label.TextXAlignment =
		Enum.TextXAlignment.Center

	label.TextYAlignment =
		Enum.TextYAlignment.Center

	label.Parent =
		parent

	return label

end

--==================================================
-- BIG MONEY TV
--==================================================

local function createBigTV()

	local model =
		Instance.new("Model")

	model.Name =
		"BigMoneyTV"

	model:SetAttribute(
		"TVType",
		"BigMoney"
	)

	model.Parent =
		templates

	local origin =
		CFrame.new(
			0,
			8,
			0
		)

	--==================================================
	-- MAIN WOOD FRAME
	--==================================================

	local frame =
		createPart(
			model,
			"Frame",

			Vector3.new(
				9,
				3.6,
				0.55
			),

			origin,

			Color3.fromRGB(
				139,
				93,
				51
			),

			Enum.Material.Wood
		)

	--==================================================
	-- SCREEN
	--==================================================

	local screen =
		createPart(
			model,
			"Screen",

			Vector3.new(
				8.2,
				2.8,
				0.2
			),

			origin
			*
			CFrame.new(
				0,
				0,
				-0.38
			),

			Color3.fromRGB(
				11,
				18,
				14
			),

			Enum.Material.SmoothPlastic
		)

	--==================================================
	-- LEFT POST
	--==================================================

	createPart(
		model,
		"LeftPost",

		Vector3.new(
			0.45,
			4,
			0.45
		),

		origin
		*
		CFrame.new(
			-3.8,
			-3.2,
			0
		),

		Color3.fromRGB(
			112,
			73,
			39
		),

		Enum.Material.Wood
	)

	--==================================================
	-- RIGHT POST
	--==================================================

	createPart(
		model,
		"RightPost",

		Vector3.new(
			0.45,
			4,
			0.45
		),

		origin
		*
		CFrame.new(
			3.8,
			-3.2,
			0
		),

		Color3.fromRGB(
			112,
			73,
			39
		),

		Enum.Material.Wood
	)

	--==================================================
	-- SURFACE GUI
	--==================================================

	local gui =
		Instance.new(
			"SurfaceGui"
		)

	gui.Name =
		"TVGui"

	gui.Face =
		Enum.NormalId.Front

	gui.LightInfluence =
		0

	gui.AlwaysOnTop =
		false

	gui.SizingMode =
		Enum.SurfaceGuiSizingMode.PixelsPerStud

	gui.PixelsPerStud =
		50

	gui.Parent =
		screen

	--==================================================
	-- TITLE
	--==================================================

	createText(
		gui,
		"TitleText",

		UDim2.fromScale(
			0,
			0.04
		),

		UDim2.fromScale(
			1,
			0.25
		),

		"TOTAL GENERATED",

		28,

		Color3.fromRGB(
			235,
			220,
			170
		)
	)

	--==================================================
	-- MONEY
	--==================================================

	createText(
		gui,
		"MoneyText",

		UDim2.fromScale(
			0,
			0.28
		),

		UDim2.fromScale(
			1,
			0.48
		),

		"$0",

		52,

		Color3.fromRGB(
			105,
			255,
			110
		)
	)

	--==================================================
	-- BOTTOM TEXT
	--==================================================

	createText(
		gui,
		"UpdateText",

		UDim2.fromScale(
			0,
			0.78
		),

		UDim2.fromScale(
			1,
			0.15
		),

		"UPDATES EVERY 5 SEC",

		16,

		Color3.fromRGB(
			170,
			180,
			170
		)
	)

	model.PrimaryPart =
		frame

end

--==================================================
-- SMALL POTATO TV
--==================================================

local function createSmallTV()

	local model =
		Instance.new("Model")

	model.Name =
		"SmallPotatoTV"

	model:SetAttribute(
		"TVType",
		"SmallPotato"
	)

	model.Parent =
		templates

	local origin =
		CFrame.new(
			12,
			4,
			0
		)

	--==================================================
	-- FRAME
	--==================================================

	local frame =
		createPart(
			model,
			"Frame",

			Vector3.new(
				3.6,
				2,
				0.4
			),

			origin,

			Color3.fromRGB(
				118,
				78,
				44
			),

			Enum.Material.Wood
		)

	--==================================================
	-- SCREEN
	--==================================================

	local screen =
		createPart(
			model,
			"Screen",

			Vector3.new(
				3.15,
				1.55,
				0.18
			),

			origin
			*
			CFrame.new(
				0,
				0,
				-0.29
			),

			Color3.fromRGB(
				10,
				18,
				13
			),

			Enum.Material.SmoothPlastic
		)

	--==================================================
	-- STAND
	--==================================================

	createPart(
		model,
		"Stand",

		Vector3.new(
			0.28,
			1.6,
			0.28
		),

		origin
		*
		CFrame.new(
			0,
			-1.65,
			0
		),

		Color3.fromRGB(
			70,
			72,
			70
		),

		Enum.Material.Metal
	)

	--==================================================
	-- BASE
	--==================================================

	createPart(
		model,
		"Base",

		Vector3.new(
			1.4,
			0.2,
			0.75
		),

		origin
		*
		CFrame.new(
			0,
			-2.35,
			0
		),

		Color3.fromRGB(
			65,
			66,
			65
		),

		Enum.Material.Metal
	)

	--==================================================
	-- GUI
	--==================================================

	local gui =
		Instance.new(
			"SurfaceGui"
		)

	gui.Name =
		"TVGui"

	gui.Face =
		Enum.NormalId.Front

	gui.LightInfluence =
		0

	gui.AlwaysOnTop =
		false

	gui.SizingMode =
		Enum.SurfaceGuiSizingMode.PixelsPerStud

	gui.PixelsPerStud =
		55

	gui.Parent =
		screen

	--==================================================
	-- MONEY / SEC
	--==================================================

	createText(
		gui,
		"RateText",

		UDim2.fromScale(
			0,
			0.08
		),

		UDim2.fromScale(
			1,
			0.40
		),

		"+$0/sec",

		26,

		Color3.fromRGB(
			105,
			255,
			110
		)
	)

	--==================================================
	-- ROTTING TIMER
	--==================================================

	createText(
		gui,
		"RotText",

		UDim2.fromScale(
			0,
			0.52
		),

		UDim2.fromScale(
			1,
			0.34
		),

		"EMPTY",

		21,

		Color3.fromRGB(
			255,
			205,
			90
		)
	)

	model.PrimaryPart =
		frame

end

--==================================================
-- BUILD
--==================================================

createBigTV()
createSmallTV()

print("")
print("========================================")
print("📺 POTATO TV TEMPLATE BUILDER READY")
print("========================================")
print("Created:")
print("✅ BigMoneyTV")
print("✅ SmallPotatoTV")
print("")
print("Workspace > PotatoTVTemplates")
print("----------------------------------------")
print("Big TV:")
print("MoneyText ready")
print("")
print("Small TV:")
print("RateText ready")
print("RotText ready")
print("========================================")
print("")