local Workspace =
	game:GetService("Workspace")

--==================================================
-- PLAYER BASE TEST TEMPLATE V5
--==================================================

local MODEL_NAME =
	"PlayerBase_TEST"

local BASE_POSITION =
	Vector3.new(
		0,
		12,
		220
	)

--==================================================
-- ROOM SIZE
--==================================================

local ROOM_WIDTH =
	66

local ROOM_DEPTH =
	80

local FLOOR_THICKNESS =
	1

local WALL_HEIGHT =
	18

local WALL_THICKNESS =
	1

--==================================================
-- WALL SECTIONS
--==================================================

local LOWER_HEIGHT =
	6

local WINDOW_HEIGHT =
	6

local UPPER_HEIGHT =
	WALL_HEIGHT
	-
	LOWER_HEIGHT
	-
	WINDOW_HEIGHT

--==================================================
-- COLORS
--==================================================

local FLOOR_COLOR =
	Color3.fromRGB(
		232,
		216,
		194
	)

-- Dark lower wall
local LOWER_WALL_COLOR =
	Color3.fromRGB(
		187,
		127,
		85
	)

-- Light upper wall
local UPPER_WALL_COLOR =
	Color3.fromRGB(
		235,
		184,
		137
	)

-- Dark wooden structural logs
local LOG_COLOR =
	Color3.fromRGB(
		112,
		73,
		45
	)

local WINDOW_COLOR =
	Color3.fromRGB(
		178,
		225,
		235
	)

local WINDOW_FRAME_COLOR =
	Color3.fromRGB(
		134,
		91,
		57
	)

local STAND_BASE_COLOR =
	Color3.fromRGB(
		50,
		54,
		55
	)

local STAND_COLOR =
	Color3.fromRGB(
		104,
		69,
		43
	)

local STAND_TOP_COLOR =
	Color3.fromRGB(
		145,
		101,
		63
	)

local COLLECTOR_COLOR =
	Color3.fromRGB(
		40,
		255,
		65
	)

--==================================================
-- CREATE PART
--==================================================

local function createPart(
	parent,
	name,
	size,
	position,
	color,
	material
)

	local part =
		Instance.new("Part")

	part.Name =
		name

	part.Size =
		size

	part.Position =
		position

	part.Anchored =
		true

	part.TopSurface =
		Enum.SurfaceType.Smooth

	part.BottomSurface =
		Enum.SurfaceType.Smooth

	part.Color =
		color

	part.Material =
		material
		or
		Enum.Material.SmoothPlastic

	part.Parent =
		parent

	return part
end

--==================================================
-- GLASS
--==================================================

local function createGlass(
	parent,
	name,
	size,
	position
)

	local glass =
		createPart(
			parent,
			name,
			size,
			position,
			WINDOW_COLOR,
			Enum.Material.Glass
		)

	glass.Transparency =
		0.35

	glass.CanCollide =
		false

	glass.CanTouch =
		false

	return glass
end

--==================================================
-- REMOVE OLD TEST BASE ONLY
--==================================================

local old =
	Workspace:FindFirstChild(
		MODEL_NAME
	)

if old then
	old:Destroy()
end

--==================================================
-- BASE
--==================================================

local base =
	Instance.new("Model")

base.Name =
	MODEL_NAME

base:SetAttribute(
	"BaseNumber",
	1
)

base:SetAttribute(
	"OwnerUserId",
	0
)

base:SetAttribute(
	"StoredCash",
	0
)

base.Parent =
	Workspace

--==================================================
-- FOLDERS
--==================================================

local walls =
	Instance.new("Folder")

walls.Name =
	"Walls"

walls.Parent =
	base

local windows =
	Instance.new("Folder")

windows.Name =
	"Windows"

windows.Parent =
	base

local structure =
	Instance.new("Folder")

structure.Name =
	"StructuralLogs"

structure.Parent =
	base

--==================================================
-- FLOOR
--==================================================

createPart(
	base,

	"BaseFloor",

	Vector3.new(
		ROOM_WIDTH,
		FLOOR_THICKNESS,
		ROOM_DEPTH
	),

	BASE_POSITION,

	FLOOR_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- IMPORTANT POSITIONS
--==================================================

local LEFT_X =
	BASE_POSITION.X
	-
	ROOM_WIDTH / 2

local RIGHT_X =
	BASE_POSITION.X
	+
	ROOM_WIDTH / 2

local BACK_Z =
	BASE_POSITION.Z
	-
	ROOM_DEPTH / 2

local FRONT_Z =
	BASE_POSITION.Z
	+
	ROOM_DEPTH / 2

local WINDOW_Y =
	BASE_POSITION.Y
	+
	LOWER_HEIGHT
	+
	WINDOW_HEIGHT / 2

local UPPER_Y =
	BASE_POSITION.Y
	+
	LOWER_HEIGHT
	+
	WINDOW_HEIGHT
	+
	UPPER_HEIGHT / 2

--==================================================
-- BACK WALL - DARK LOWER
--==================================================

createPart(
	walls,

	"BackWallLower",

	Vector3.new(
		ROOM_WIDTH,
		LOWER_HEIGHT,
		WALL_THICKNESS
	),

	Vector3.new(
		BASE_POSITION.X,

		BASE_POSITION.Y
			+
			LOWER_HEIGHT / 2,

		BACK_Z
	),

	LOWER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- BACK WALL - LIGHT UPPER
--==================================================

createPart(
	walls,

	"BackWallUpper",

	Vector3.new(
		ROOM_WIDTH,
		UPPER_HEIGHT,
		WALL_THICKNESS
	),

	Vector3.new(
		BASE_POSITION.X,
		UPPER_Y,
		BACK_Z
	),

	UPPER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- BACK LONG WINDOW
--==================================================

createGlass(
	windows,

	"BackWindow",

	Vector3.new(
		50,
		WINDOW_HEIGHT,
		0.35
	),

	Vector3.new(
		BASE_POSITION.X,
		WINDOW_Y,
		BACK_Z + 0.05
	)
)

--==================================================
-- BACK WINDOW SIDE FILL
--==================================================

createPart(
	walls,

	"BackWindowLeftFill",

	Vector3.new(
		8,
		WINDOW_HEIGHT,
		WALL_THICKNESS
	),

	Vector3.new(
		BASE_POSITION.X - 29,
		WINDOW_Y,
		BACK_Z
	),

	LOWER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

createPart(
	walls,

	"BackWindowRightFill",

	Vector3.new(
		8,
		WINDOW_HEIGHT,
		WALL_THICKNESS
	),

	Vector3.new(
		BASE_POSITION.X + 29,
		WINDOW_Y,
		BACK_Z
	),

	LOWER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- LEFT WALL LOWER
--==================================================

createPart(
	walls,

	"LeftWallLower",

	Vector3.new(
		WALL_THICKNESS,
		LOWER_HEIGHT,
		ROOM_DEPTH
	),

	Vector3.new(
		LEFT_X,

		BASE_POSITION.Y
			+
			LOWER_HEIGHT / 2,

		BASE_POSITION.Z
	),

	LOWER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- LEFT WALL UPPER
--==================================================

createPart(
	walls,

	"LeftWallUpper",

	Vector3.new(
		WALL_THICKNESS,
		UPPER_HEIGHT,
		ROOM_DEPTH
	),

	Vector3.new(
		LEFT_X,
		UPPER_Y,
		BASE_POSITION.Z
	),

	UPPER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- LEFT LONG WINDOW
--==================================================

createGlass(
	windows,

	"LeftWindow",

	Vector3.new(
		0.35,
		WINDOW_HEIGHT,
		64
	),

	Vector3.new(
		LEFT_X + 0.05,
		WINDOW_Y,
		BASE_POSITION.Z
	)
)

--==================================================
-- RIGHT WALL LOWER
--==================================================

createPart(
	walls,

	"RightWallLower",

	Vector3.new(
		WALL_THICKNESS,
		LOWER_HEIGHT,
		ROOM_DEPTH
	),

	Vector3.new(
		RIGHT_X,

		BASE_POSITION.Y
			+
			LOWER_HEIGHT / 2,

		BASE_POSITION.Z
	),

	LOWER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- RIGHT WALL UPPER
--==================================================

createPart(
	walls,

	"RightWallUpper",

	Vector3.new(
		WALL_THICKNESS,
		UPPER_HEIGHT,
		ROOM_DEPTH
	),

	Vector3.new(
		RIGHT_X,
		UPPER_Y,
		BASE_POSITION.Z
	),

	UPPER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- RIGHT LONG WINDOW
--==================================================

createGlass(
	windows,

	"RightWindow",

	Vector3.new(
		0.35,
		WINDOW_HEIGHT,
		64
	),

	Vector3.new(
		RIGHT_X - 0.05,
		WINDOW_Y,
		BASE_POSITION.Z
	)
)

--==================================================
-- WINDOW FRAMES
--==================================================

createPart(
	structure,

	"BackWindowBottomFrame",

	Vector3.new(
		52,
		0.55,
		0.6
	),

	Vector3.new(
		BASE_POSITION.X,
		BASE_POSITION.Y + LOWER_HEIGHT,
		BACK_Z - 0.05
	),

	WINDOW_FRAME_COLOR,

	Enum.Material.WoodPlanks
)

createPart(
	structure,

	"BackWindowTopFrame",

	Vector3.new(
		52,
		0.55,
		0.6
	),

	Vector3.new(
		BASE_POSITION.X,
		BASE_POSITION.Y
			+
			LOWER_HEIGHT
			+
			WINDOW_HEIGHT,
		BACK_Z - 0.05
	),

	WINDOW_FRAME_COLOR,

	Enum.Material.WoodPlanks
)

--==================================================
-- STRUCTURAL CORNER LOG FUNCTION
--==================================================

local function createLog(
	name,
	x,
	z
)

	createPart(
		structure,

		name,

		Vector3.new(
			2.5,
			WALL_HEIGHT + 1,
			2.5
		),

		Vector3.new(
			x,

			BASE_POSITION.Y
				+
				WALL_HEIGHT / 2,

			z
		),

		LOG_COLOR,

		Enum.Material.WoodPlanks
	)

end

--==================================================
-- FOUR CORNER LOGS
--==================================================

createLog(
	"BackLeftCornerLog",
	LEFT_X,
	BACK_Z
)

createLog(
	"BackRightCornerLog",
	RIGHT_X,
	BACK_Z
)

createLog(
	"FrontLeftCornerLog",
	LEFT_X,
	FRONT_Z
)

createLog(
	"FrontRightCornerLog",
	RIGHT_X,
	FRONT_Z
)

--==================================================
-- FRONT SECTION
--==================================================

local ENTRANCE_WIDTH =
	16

local SIDE_WIDTH =
	(
		ROOM_WIDTH
		-
		ENTRANCE_WIDTH
	)
	/
	2

local FRONT_LEFT_CENTER =
	BASE_POSITION.X
	-
	(
		ENTRANCE_WIDTH / 2
		+
		SIDE_WIDTH / 2
	)

local FRONT_RIGHT_CENTER =
	BASE_POSITION.X
	+
	(
		ENTRANCE_WIDTH / 2
		+
		SIDE_WIDTH / 2
	)

--==================================================
-- FRONT LOWER DARK SECTIONS
--==================================================

createPart(
	walls,

	"FrontLeftLower",

	Vector3.new(
		SIDE_WIDTH,
		LOWER_HEIGHT,
		WALL_THICKNESS
	),

	Vector3.new(
		FRONT_LEFT_CENTER,

		BASE_POSITION.Y
			+
			LOWER_HEIGHT / 2,

		FRONT_Z
	),

	LOWER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

createPart(
	walls,

	"FrontRightLower",

	Vector3.new(
		SIDE_WIDTH,
		LOWER_HEIGHT,
		WALL_THICKNESS
	),

	Vector3.new(
		FRONT_RIGHT_CENTER,

		BASE_POSITION.Y
			+
			LOWER_HEIGHT / 2,

		FRONT_Z
	),

	LOWER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- FRONT UPPER LIGHT SECTIONS
--==================================================

createPart(
	walls,

	"FrontLeftUpper",

	Vector3.new(
		SIDE_WIDTH,
		UPPER_HEIGHT,
		WALL_THICKNESS
	),

	Vector3.new(
		FRONT_LEFT_CENTER,
		UPPER_Y,
		FRONT_Z
	),

	UPPER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

createPart(
	walls,

	"FrontRightUpper",

	Vector3.new(
		SIDE_WIDTH,
		UPPER_HEIGHT,
		WALL_THICKNESS
	),

	Vector3.new(
		FRONT_RIGHT_CENTER,
		UPPER_Y,
		FRONT_Z
	),

	UPPER_WALL_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- FRONT WINDOWS
--==================================================

createGlass(
	windows,

	"FrontLeftWindow",

	Vector3.new(
		17,
		WINDOW_HEIGHT,
		0.35
	),

	Vector3.new(
		FRONT_LEFT_CENTER,
		WINDOW_Y,
		FRONT_Z - 0.05
	)
)

createGlass(
	windows,

	"FrontRightWindow",

	Vector3.new(
		17,
		WINDOW_HEIGHT,
		0.35
	),

	Vector3.new(
		FRONT_RIGHT_CENTER,
		WINDOW_Y,
		FRONT_Z - 0.05
	)
)

--==================================================
-- ENTRANCE LOGS
--==================================================

createLog(
	"EntranceLeftLog",

	BASE_POSITION.X
	-
	ENTRANCE_WIDTH / 2,

	FRONT_Z
)

createLog(
	"EntranceRightLog",

	BASE_POSITION.X
	+
	ENTRANCE_WIDTH / 2,

	FRONT_Z
)

--==================================================
-- TOP BEAMS
--==================================================

createPart(
	structure,

	"BackTopBeam",

	Vector3.new(
		ROOM_WIDTH + 2,
		1.4,
		1.4
	),

	Vector3.new(
		BASE_POSITION.X,
		BASE_POSITION.Y + WALL_HEIGHT,
		BACK_Z
	),

	LOG_COLOR,

	Enum.Material.WoodPlanks
)

createPart(
	structure,

	"LeftTopBeam",

	Vector3.new(
		1.4,
		1.4,
		ROOM_DEPTH
	),

	Vector3.new(
		LEFT_X,
		BASE_POSITION.Y + WALL_HEIGHT,
		BASE_POSITION.Z
	),

	LOG_COLOR,

	Enum.Material.WoodPlanks
)

createPart(
	structure,

	"RightTopBeam",

	Vector3.new(
		1.4,
		1.4,
		ROOM_DEPTH
	),

	Vector3.new(
		RIGHT_X,
		BASE_POSITION.Y + WALL_HEIGHT,
		BASE_POSITION.Z
	),

	LOG_COLOR,

	Enum.Material.WoodPlanks
)

--==================================================
-- FRONT BEAMS
--==================================================

createPart(
	structure,

	"FrontLeftBeam",

	Vector3.new(
		SIDE_WIDTH,
		1.4,
		1.4
	),

	Vector3.new(
		FRONT_LEFT_CENTER,
		BASE_POSITION.Y + WALL_HEIGHT,
		FRONT_Z
	),

	LOG_COLOR,

	Enum.Material.WoodPlanks
)

createPart(
	structure,

	"FrontRightBeam",

	Vector3.new(
		SIDE_WIDTH,
		1.4,
		1.4
	),

	Vector3.new(
		FRONT_RIGHT_CENTER,
		BASE_POSITION.Y + WALL_HEIGHT,
		FRONT_Z
	),

	LOG_COLOR,

	Enum.Material.WoodPlanks
)

--==================================================
-- ENTRANCE FLOOR
--==================================================

createPart(
	base,

	"EntranceFloor",

	Vector3.new(
		14,
		0.6,
		10
	),

	Vector3.new(
		BASE_POSITION.X,
		BASE_POSITION.Y + 0.05,
		FRONT_Z + 4.5
	),

	FLOOR_COLOR,

	Enum.Material.SmoothPlastic
)

--==================================================
-- POTATO SLOTS
--==================================================

local slotsFolder =
	Instance.new("Folder")

slotsFolder.Name =
	"PotatoSlots"

slotsFolder.Parent =
	base

local SLOT_LEFT_X =
	-21

local SLOT_RIGHT_X =
	21

local SLOT_START_Z =
	-24

local SLOT_SPACING =
	10

--==================================================
-- CREATE SLOT
--==================================================

local function createPotatoStand(
	slotNumber,
	xOffset,
	zOffset
)

	local slot =
		Instance.new("Model")

	slot.Name =
		string.format(
			"Slot_%02d",
			slotNumber
		)

	slot:SetAttribute(
		"SlotNumber",
		slotNumber
	)

	slot:SetAttribute(
		"Occupied",
		false
	)

	slot:SetAttribute(
		"PotatoId",
		0
	)

	slot.Parent =
		slotsFolder

	-- DARK BASE

	local standBase =
		createPart(
			slot,

			"StandBase",

			Vector3.new(
				9.5,
				0.7,
				6
			),

			BASE_POSITION
				+
				Vector3.new(
					xOffset,
					0.85,
					zOffset
				),

			STAND_BASE_COLOR,

			Enum.Material.Metal
		)

	-- WOOD

	local stand =
		createPart(
			slot,

			"Stand",

			Vector3.new(
				8.5,
				1.3,
				5
			),

			standBase.Position
				+
				Vector3.new(
					0,
					0.85,
					0
				),

			STAND_COLOR,

			Enum.Material.WoodPlanks
		)

	-- LIGHTER TOP

	local standTop =
		createPart(
			slot,

			"StandTop",

			Vector3.new(
				8,
				0.25,
				4.5
			),

			stand.Position
				+
				Vector3.new(
					0,
					0.75,
					0
				),

			STAND_TOP_COLOR,

			Enum.Material.WoodPlanks
		)

	-- INVISIBLE POTATO POINT

	local point =
		createPart(
			slot,

			"PotatoPoint",

			Vector3.new(
				1,
				0.2,
				1
			),

			standTop.Position
				+
				Vector3.new(
					0,
					0.35,
					0
				),

			Color3.new(
				1,
				1,
				1
			),

			Enum.Material.SmoothPlastic
		)

	point.Transparency =
		1

	point.CanCollide =
		false

	point.CanTouch =
		false

	point.CanQuery =
		false
end

--==================================================
-- CREATE 12 EQUALLY SPACED
--==================================================

for index = 1, 6 do

	local z =
		SLOT_START_Z
		+
		(
			(index - 1)
			*
			SLOT_SPACING
		)

	createPotatoStand(
		index,
		SLOT_LEFT_X,
		z
	)

	createPotatoStand(
		index + 6,
		SLOT_RIGHT_X,
		z
	)

end

--==================================================
-- MONEY COLLECTOR
--==================================================

local collectorBase =
	createPart(
	base,

	"MoneyCollectorBase",

	Vector3.new(
		9,
		0.8,
		7
	),

	BASE_POSITION
		+
		Vector3.new(
			0,
			0.9,
			-31
		),

	STAND_BASE_COLOR,

	Enum.Material.Metal
	)

local collector =
	createPart(
	base,

	"MoneyCollector",

	Vector3.new(
		7,
		0.5,
		5
	),

	collectorBase.Position
		+
		Vector3.new(
			0,
			0.65,
			0
		),

	COLLECTOR_COLOR,

	Enum.Material.Neon
	)

collector:SetAttribute(
	"CollectorType",
	"BaseCash"
)

collector:SetAttribute(
	"StoredCash",
	0
)

--==================================================
-- MONEY GUI
--==================================================

local gui =
	Instance.new(
		"BillboardGui"
	)

gui.Name =
	"MoneyGui"

gui.Size =
	UDim2.fromOffset(
		170,
		52
	)

gui.StudsOffset =
	Vector3.new(
		0,
		3,
		0
	)

gui.AlwaysOnTop =
	true

gui.MaxDistance =
	80

gui.Parent =
	collector

local label =
	Instance.new(
		"TextLabel"
	)

label.Name =
	"MoneyText"

label.Size =
	UDim2.fromScale(
		1,
		1
	)

label.BackgroundTransparency =
	1

label.Text =
	"💰 $0\nCOLLECT"

label.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

label.TextStrokeTransparency =
	0.25

label.TextSize =
	16

label.Font =
	Enum.Font.GothamBold

label.Parent =
	gui

--==================================================
-- ENTRANCE MARKER
--==================================================

local entrance =
	createPart(
	base,

	"Entrance",

	Vector3.new(
		14,
		1,
		4
	),

	Vector3.new(
		BASE_POSITION.X,
		BASE_POSITION.Y + 0.8,
		FRONT_Z
	),

	Color3.new(
		1,
		1,
		1
	),

	Enum.Material.SmoothPlastic
	)

entrance.Transparency =
	1

entrance.CanCollide =
	false

entrance.CanTouch =
	false

entrance.CanQuery =
	false

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("🏠 PLAYER BASE TEST TEMPLATE V5")
print("========================================")
print("🟤 Dark lower wall")
print("🍑 Light peach upper wall")
print("🪵 Wooden corner logs added")
print("🪵 Entrance logs added")
print("🪵 Top structural beams added")
print("🪟 Long transparent windows")
print("🥔 12 equally spaced displays")
print("💰 Back money collector")
print("========================================")
print("")