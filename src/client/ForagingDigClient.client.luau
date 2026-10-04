local Players =
	game:GetService("Players")

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

local UserInputService =
	game:GetService("UserInputService")

local RunService =
	game:GetService("RunService")

local TweenService =
	game:GetService("TweenService")

local Debris =
	game:GetService("Debris")

local Workspace =
	game:GetService("Workspace")

--==================================================
-- FORAGING DIG CLIENT V8
--
-- 🖱 HOLD LEFT CLICK = DIG
-- 🖱 RELEASE = CANCEL
--
-- NEW:
--
-- ✅ Realistic impact instead of chime
-- ✅ Different tone every Hoe hit
-- ✅ Dirt ~20% more visible
-- ✅ 4 Hoe swings
-- ✅ Final dirt burst
-- ✅ Wind-up
-- ✅ TRUE vertical TOP -> CENTER -> BOTTOM potato roulette V6
--
-- ❌ No timing bonus
-- ❌ No vibration
--==================================================

local player =
	Players.LocalPlayer

local playerGui =
	player:WaitForChild(
		"PlayerGui"
	)

local camera =
	Workspace.CurrentCamera

--==================================================
-- WORLD
--==================================================

local world =
	Workspace:WaitForChild(
		"PotatoWorld"
	)

local foragingZone =
	world:WaitForChild(
		"ForagingZone"
	)

local zone1 =
	nil

for _, object in ipairs(
	foragingZone:GetChildren()
) do

	if
		object:IsA(
			"Model"
		)
		and
		object:GetAttribute(
			"ZoneNumber"
		)
		==
		1
	then

		zone1 =
			object

		break

	end

end

if not zone1 then

	zone1 =
		foragingZone:WaitForChild(
			"Zone_1_MEADOW"
		)

end

local ground =
	zone1:WaitForChild(
		"Ground"
	)

--==================================================
-- REMOTES
--==================================================

local remotes =
	ReplicatedStorage:WaitForChild(
		"ForagingRemotes"
	)

local RequestDig =
	remotes:WaitForChild(
		"RequestDig"
	)

local CancelDig =
	remotes:WaitForChild(
		"CancelDig"
	)

local DigStarted =
	remotes:WaitForChild(
		"DigStarted"
	)

local DigCancelled =
	remotes:WaitForChild(
		"DigCancelled"
	)

local DigFinished =
	remotes:WaitForChild(
		"DigFinished"
	)

--==================================================
-- SETTINGS
--==================================================

local MAX_PLAYER_RADIUS =
	6

local LOOK_AWAY_RADIUS =
	5

local REQUEST_TIMEOUT =
	2

local SWING_POINTS = {

	0.12,
	0.36,
	0.61,
	0.84,

}

local WINDUP_POINT =
	0.94

--==================================================
-- REALISTIC HIT SOUND
--
-- Built-in generic Roblox impact.
--==================================================

local HOE_IMPACT_SOUND =
	"rbxasset://sounds/impact_generic.mp3"

-- We intentionally no longer use the old chime.

--==================================================
-- DIRT VISIBILITY
--
-- Previous = 1.00
-- New = 1.20
--==================================================

local DIRT_VISIBILITY =
	1.20

local DIRT_PARTICLE_MULTIPLIER =
	1.20

--==================================================
-- HIT VARIATIONS
--
-- Same physical impact sound, slightly different
-- pitch/volume each strike so it doesn't repeat
-- identically.
--==================================================

local HIT_SETTINGS = {

	[1] = {

		Volume = 0.55,
		Speed = 0.82,
		Dirt = 10,

	},

	[2] = {

		Volume = 0.62,
		Speed = 0.89,
		Dirt = 12,

	},

	[3] = {

		Volume = 0.68,
		Speed = 0.95,
		Dirt = 14,

	},

	[4] = {

		Volume = 0.76,
		Speed = 0.86,
		Dirt = 18,

	},

}

--==================================================
-- MEADOW POTATO ROLL
--
-- Server decides the REAL potato.
-- This data is only for the rolling reveal animation.
--==================================================

local MEADOW_POTATO_NAMES = {
	"Basic Potato",
	"Big Potato",
	"Butter Potato",
	"Feather Potato",
	"Flower Potato",
	"Golden Potato",
	"Grass Potato",
	"Lucky Potato",
	"Prism Potato",
	"Star Potato",
	"Sunkissed Potato",
}

local POTATO_COLORS = {
	["Basic Potato"] = Color3.fromRGB(169, 117, 73),
	["Big Potato"] = Color3.fromRGB(151, 94, 56),
	["Butter Potato"] = Color3.fromRGB(255, 215, 91),
	["Feather Potato"] = Color3.fromRGB(235, 230, 210),
	["Flower Potato"] = Color3.fromRGB(235, 145, 195),
	["Golden Potato"] = Color3.fromRGB(255, 215, 70),
	["Grass Potato"] = Color3.fromRGB(88, 178, 82),
	["Lucky Potato"] = Color3.fromRGB(91, 210, 111),
	["Prism Potato"] = Color3.fromRGB(185, 110, 255),
	["Star Potato"] = Color3.fromRGB(255, 235, 90),
	["Sunkissed Potato"] = Color3.fromRGB(255, 179, 54),
}

local ROLL_TICK_SOUND =
	"rbxasset://sounds/electronicpingshort.wav"

local ROLL_STEPS = 18

-- Slightly slower than the previous roll.
local ROLL_START_DELAY = 0.065
local ROLL_END_DELAY = 0.30

-- Hold the landed potato on screen before hiding.
-- Previous = 1.9 seconds. New = 2.4 seconds.
local FINAL_RESULT_HOLD_TIME = 2.4
--==================================================
-- STATE
--==================================================

local mouseHeld =
	false

local requestPending =
	false

local digging =
	false

local currentDigId =
	nil

local currentDigSpot =
	nil

local currentDigTime =
	0

local currentEndServerTime =
	0

local currentStartPosition =
	nil

local requestSerial =
	0

local targetSpot =
	nil

local swingDone = {

	false,
	false,
	false,
	false,

}

local windupDone =
	false

local animatedHoe =
	nil

local baseGrip =
	nil

local gripTween =
	nil

--==================================================
-- CHARACTER
--==================================================

local function getCharacter()

	return
		player.Character

end

local function getRoot()

	local character =
		getCharacter()

	if not character then

		return nil

	end

	return
		character:FindFirstChild(
			"HumanoidRootPart"
		)

end

--==================================================
-- HOE
--==================================================

local function getEquippedHoe()

	local character =
		getCharacter()

	if not character then

		return nil

	end

	for _, object in ipairs(
		character:GetChildren()
	) do

		if
			object:IsA(
				"Tool"
			)
			and
			(
				object:GetAttribute(
					"FarmingToolType"
				)
				==
				"Hoe"
				or
				string.find(
					string.lower(
						object.Name
					),
					"hoe"
				)
			)
		then

			return object

		end

	end

	return nil

end

--==================================================
-- GUI
--==================================================

local oldGui =
	playerGui:FindFirstChild(
		"ForagingDigGui"
	)

if oldGui then

	oldGui:Destroy()

end

local gui =
	Instance.new(
		"ScreenGui"
	)

gui.Name =
	"ForagingDigGui"

gui.ResetOnSpawn =
	false

gui.DisplayOrder =
	15

gui.Parent =
	playerGui

--==================================================
-- DIG PANEL
--==================================================

local digPanel =
	Instance.new(
		"Frame"
	)

digPanel.AnchorPoint =
	Vector2.new(
		0.5,
		1
	)

digPanel.Position =
	UDim2.new(
		0.5,
		0,
		1,
		-80
	)

digPanel.Size =
	UDim2.fromOffset(
		325,
		88
	)

digPanel.BackgroundColor3 =
	Color3.fromRGB(
		48,
		33,
		22
	)

digPanel.BorderSizePixel =
	0

digPanel.Visible =
	false

digPanel.Parent =
	gui

local corner =
	Instance.new(
		"UICorner"
	)

corner.CornerRadius =
	UDim.new(
		0,
		13
	)

corner.Parent =
	digPanel

local stroke =
	Instance.new(
		"UIStroke"
	)

stroke.Color =
	Color3.fromRGB(
		10,
		8,
		6
	)

stroke.Thickness =
	4

stroke.Parent =
	digPanel

--==================================================
-- DIG TEXT
--==================================================

local digText =
	Instance.new(
		"TextLabel"
	)

digText.BackgroundTransparency =
	1

digText.Position =
	UDim2.new(
		0,
		10,
		0,
		7
	)

digText.Size =
	UDim2.new(
		1,
		-20,
		0,
		35
	)

digText.Text =
	"HOLD CLICK • DIGGING"

digText.TextColor3 =
	Color3.fromRGB(
		255,
		239,
		202
	)

digText.Font =
	Enum.Font.GothamBold

digText.TextSize =
	13

digText.Parent =
	digPanel

--==================================================
-- PROGRESS
--==================================================

local progressBack =
	Instance.new(
		"Frame"
	)

progressBack.Position =
	UDim2.new(
		0,
		18,
		0,
		54
	)

progressBack.Size =
	UDim2.new(
		1,
		-36,
		0,
		15
	)

progressBack.BackgroundColor3 =
	Color3.fromRGB(
		24,
		18,
		13
	)

progressBack.BorderSizePixel =
	0

progressBack.Parent =
	digPanel

local backCorner =
	Instance.new(
		"UICorner"
	)

backCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

backCorner.Parent =
	progressBack

local progress =
	Instance.new(
		"Frame"
	)

progress.Size =
	UDim2.fromScale(
		0,
		1
	)

progress.BackgroundColor3 =
	Color3.fromRGB(
		106,
		169,
		75
	)

progress.BorderSizePixel =
	0

progress.Parent =
	progressBack

local progressCorner =
	Instance.new(
		"UICorner"
	)

progressCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

progressCorner.Parent =
	progress

--==================================================
-- RESULT / TOP-TO-BOTTOM POTATO ROLL UI
--==================================================

-- Simple result label used only for messages such as
-- CANCELLED or NOTHING HERE.

local result =
	Instance.new(
		"TextLabel"
	)

result.AnchorPoint =
	Vector2.new(
		0.5,
		1
	)

result.Position =
	UDim2.new(
		0.5,
		0,
		1,
		-180
	)

result.Size =
	UDim2.fromOffset(
		330,
		65
	)

result.BackgroundColor3 =
	Color3.fromRGB(
		42,
		30,
		20
	)

result.BackgroundTransparency =
	0.08

result.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

result.TextSize =
	16

result.Font =
	Enum.Font.GothamBold

result.Visible =
	false

result.Parent =
	gui

local resultCorner =
	Instance.new(
		"UICorner"
	)

resultCorner.CornerRadius =
	UDim.new(
		0,
		12
	)

resultCorner.Parent =
	result

--==================================================
-- TOP-TO-BOTTOM ROLL PANEL
--
-- Names only. No potato images and no lower text.
-- Only THREE names are visible: one above, selected center, one below.
-- The reel moves FROM TOP TO BOTTOM.
--==================================================

local rollPanel =
	Instance.new(
		"Frame"
	)

rollPanel.AnchorPoint =
	Vector2.new(
		0.5,
		1
	)

rollPanel.Position =
	UDim2.new(
		0.5,
		0,
		1,
		-145
	)

rollPanel.Size =
	UDim2.fromOffset(
		350,
		210
	)

rollPanel.BackgroundColor3 =
	Color3.fromRGB(
		24,
		20,
		16
	)

rollPanel.BackgroundTransparency =
	0.04

rollPanel.BorderSizePixel =
	0

rollPanel.Visible =
	false

rollPanel.ClipsDescendants =
	true

rollPanel.Parent =
	gui

local rollCorner =
	Instance.new(
		"UICorner"
	)

rollCorner.CornerRadius =
	UDim.new(
		0,
		14
	)

rollCorner.Parent =
	rollPanel

local rollStroke =
	Instance.new(
		"UIStroke"
	)

rollStroke.Color =
	Color3.fromRGB(
		94,
		190,
		96
	)

rollStroke.Transparency =
	0.18

rollStroke.Thickness =
	2

rollStroke.Parent =
	rollPanel

local rollGradient =
	Instance.new(
		"UIGradient"
	)

rollGradient.Color =
	ColorSequence.new({
		ColorSequenceKeypoint.new(
			0,
			Color3.fromRGB(44, 31, 20)
		),
		ColorSequenceKeypoint.new(
			0.5,
			Color3.fromRGB(20, 26, 18)
		),
		ColorSequenceKeypoint.new(
			1,
			Color3.fromRGB(44, 31, 20)
		),
	})

rollGradient.Rotation =
	90

rollGradient.Parent =
	rollPanel

--==================================================
-- TOP TITLE BAR
--==================================================

local rollTitle =
	Instance.new(
		"TextLabel"
	)

rollTitle.BackgroundTransparency =
	1

rollTitle.Position =
	UDim2.fromOffset(
		18,
		7
	)

rollTitle.Size =
	UDim2.new(
		1,
		-36,
		0,
		24
	)

rollTitle.Text =
	"MEADOW ROLL"

rollTitle.TextColor3 =
	Color3.fromRGB(
		228,
		241,
		220
	)

rollTitle.TextTransparency =
	0.08

rollTitle.Font =
	Enum.Font.GothamBold

rollTitle.TextSize =
	14

rollTitle.ZIndex =
	8

rollTitle.Parent =
	rollPanel

local titleLine =
	Instance.new(
		"Frame"
	)

titleLine.Position =
	UDim2.new(
		0,
		18,
		0,
		34
	)

titleLine.Size =
	UDim2.new(
		1,
		-36,
		0,
		1
	)

titleLine.BackgroundColor3 =
	Color3.fromRGB(
		92,
		132,
		78
	)

titleLine.BackgroundTransparency =
	0.45

titleLine.BorderSizePixel =
	0

titleLine.ZIndex =
	8

titleLine.Parent =
	rollPanel

--==================================================
-- CENTER SELECTION SLOT
--==================================================

local centerSlot =
	Instance.new(
		"Frame"
	)

centerSlot.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)

centerSlot.Position =
	UDim2.new(
		0.5,
		0,
		0,
		120
	)

centerSlot.Size =
	UDim2.fromOffset(
		292,
		48
	)

centerSlot.BackgroundColor3 =
	Color3.fromRGB(
		70,
		150,
		72
	)

centerSlot.BackgroundTransparency =
	0.86

centerSlot.BorderSizePixel =
	0

centerSlot.ZIndex =
	2

centerSlot.Parent =
	rollPanel

local centerCorner =
	Instance.new(
		"UICorner"
	)

centerCorner.CornerRadius =
	UDim.new(
		0,
		10
	)

centerCorner.Parent =
	centerSlot

local centerStroke =
	Instance.new(
		"UIStroke"
	)

centerStroke.Color =
	Color3.fromRGB(
		105,
		255,
		116
	)

centerStroke.Transparency =
	0.26

centerStroke.Thickness =
	1.5

centerStroke.Parent =
	centerSlot

-- Top + bottom markers point at the center row.
local topMarker =
	Instance.new(
		"TextLabel"
	)

topMarker.AnchorPoint =
	Vector2.new(
		0.5,
		0
	)

topMarker.Position =
	UDim2.new(
		0.5,
		0,
		0,
		87
	)

topMarker.Size =
	UDim2.fromOffset(
		28,
		18
	)

topMarker.BackgroundTransparency =
	1

topMarker.Text =
	"▼"

topMarker.TextColor3 =
	Color3.fromRGB(
		121,
		255,
		126
	)

topMarker.Font =
	Enum.Font.GothamBold

topMarker.TextSize =
	14

topMarker.ZIndex =
	7

topMarker.Parent =
	rollPanel

local bottomMarker =
	topMarker:Clone()

bottomMarker.AnchorPoint =
	Vector2.new(
		0.5,
		1
	)

bottomMarker.Position =
	UDim2.new(
		0.5,
		0,
		0,
		153
	)

bottomMarker.Text =
	"▲"

bottomMarker.Parent =
	rollPanel

--==================================================
-- VERTICAL REEL VIEWPORT
--==================================================

local reelViewport =
	Instance.new(
		"Frame"
	)

reelViewport.AnchorPoint =
	Vector2.new(
		0.5,
		0
	)

reelViewport.Position =
	UDim2.new(
		0.5,
		0,
		0,
		45
	)

reelViewport.Size =
	UDim2.fromOffset(
		310,
		150
	)

reelViewport.BackgroundTransparency =
	1

reelViewport.ClipsDescendants =
	true

reelViewport.ZIndex =
	3

reelViewport.Parent =
	rollPanel

local reelStrip =
	Instance.new(
		"Frame"
	)

reelStrip.BackgroundTransparency =
	1

reelStrip.Size =
	UDim2.fromOffset(
		310,
		1
	)

reelStrip.Position =
	UDim2.fromOffset(
		0,
		0
	)

reelStrip.ZIndex =
	3

reelStrip.Parent =
	reelViewport

--==================================================
-- TOP / BOTTOM FADES
--==================================================

local topFade =
	Instance.new(
		"Frame"
	)

topFade.Position =
	UDim2.fromOffset(
		30,
		46
	)

topFade.Size =
	UDim2.new(
		1,
		-60,
		0,
		38
	)

topFade.BackgroundColor3 =
	Color3.fromRGB(
		17,
		14,
		11
	)

topFade.BackgroundTransparency =
	0.38

topFade.BorderSizePixel =
	0

topFade.ZIndex =
	7

topFade.Parent =
	rollPanel

topFade.Visible = false

local topFadeGradient =
	Instance.new(
		"UIGradient"
	)

topFadeGradient.Rotation =
	90

topFadeGradient.Transparency =
	NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})

topFadeGradient.Parent =
	topFade

local bottomFade =
	topFade:Clone()

bottomFade.AnchorPoint =
	Vector2.new(
		0,
		1
	)

bottomFade.Position =
	UDim2.new(
		0,
		30,
		0,
		212
	)

bottomFade.Parent =
	rollPanel

bottomFade.Visible = false

local bottomFadeGradient =
	bottomFade:FindFirstChildOfClass(
		"UIGradient"
	)

if bottomFadeGradient then

	bottomFadeGradient.Transparency =
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0.05),
		})

end

--==================================================
-- TARGET CIRCLE
--==================================================

local indicator =
	Instance.new(
		"Part"
	)

indicator.Shape =
	Enum.PartType.Cylinder

indicator.Size =
	Vector3.new(
		0.08,
		3.2,
		3.2
	)

indicator.Material =
	Enum.Material.Neon

indicator.Color =
	Color3.fromRGB(
		255,
		230,
		75
	)

indicator.Transparency =
	0.45

indicator.Anchored =
	true

indicator.CanCollide =
	false

indicator.CanTouch =
	false

indicator.CanQuery =
	false

indicator.CFrame =
	CFrame.new(
		0,
		-1000,
		0
	)

indicator.Parent =
	Workspace

local function setIndicator(
	position,
	active
)

	if not position then

		indicator.CFrame =
			CFrame.new(
				0,
				-1000,
				0
			)

		return

	end

	indicator.Color =
		if active
		then
			Color3.fromRGB(
				255,
				167,
				43
			)
		else
			Color3.fromRGB(
				255,
				231,
				73
			)

	indicator.CFrame =
		CFrame.new(
			position
			+
			Vector3.new(
				0,
				0.06,
				0
			)
		)
		*
		CFrame.Angles(
			0,
			0,
			math.rad(
				90
			)
		)

end

--==================================================
-- TARGET RAY
--==================================================

local rayParams =
	RaycastParams.new()

rayParams.FilterType =
	Enum.RaycastFilterType.Include

rayParams.FilterDescendantsInstances = {
	ground,
}

local function getMouseGround()

	camera =
		Workspace.CurrentCamera

	if not camera then

		return nil

	end

	local mouse =
		UserInputService:GetMouseLocation()

	local ray =
		camera:ViewportPointToRay(
			mouse.X,
			mouse.Y
		)

	local hit =
		Workspace:Raycast(
			ray.Origin,
			ray.Direction
				*
				1000,
			rayParams
		)

	if hit then

		return
			hit.Position

	end

	return nil

end

local function horizontalDistance(
	a,
	b
)

	return
		Vector3.new(
			a.X - b.X,
			0,
			a.Z - b.Z
		).Magnitude

end

local function getValidTarget()

	if not getEquippedHoe() then

		return nil

	end

	local root =
		getRoot()

	if not root then

		return nil

	end

	local position =
		getMouseGround()

	if not position then

		return nil

	end

	if
		horizontalDistance(
			root.Position,
			position
		)
		>
		MAX_PLAYER_RADIUS
	then

		return nil

	end

	return position

end

--==================================================
-- FX HOLDER
--==================================================

local function makeFXHolder(
	position
)

	local holder =
		Instance.new(
			"Part"
		)

	holder.Size =
		Vector3.new(
			0.1,
			0.1,
			0.1
		)

	holder.Transparency =
		1

	holder.Anchored =
		true

	holder.CanCollide =
		false

	holder.CanTouch =
		false

	holder.CanQuery =
		false

	holder.Position =
		position
		+
		Vector3.new(
			0,
			0.1,
			0
		)

	holder.Parent =
		Workspace

	Debris:AddItem(
		holder,
		2
	)

	return holder

end

--==================================================
-- REALISTIC IMPACT
--==================================================

local function playImpact(
	position,
	hitNumber
)

	local settings =
		HIT_SETTINGS[
			hitNumber
		]

	if
		not position
		or
		not settings
	then

		return

	end

	local holder =
		makeFXHolder(
			position
		)

	local sound =
		Instance.new(
			"Sound"
		)

	sound.SoundId =
		HOE_IMPACT_SOUND

	sound.Volume =
		settings.Volume

	-- Tiny random difference means the exact same
	-- sound doesn't repeat identically.

	sound.PlaybackSpeed =
		settings.Speed
		+
		math.random(
			-3,
			3
		)
		/
		100

	sound.RollOffMinDistance =
		3

	sound.RollOffMaxDistance =
		35

	sound.Parent =
		holder

	sound:Play()

end

--==================================================
-- DIRT
--
-- ~20% stronger than previous version.
--==================================================

local function emitDirt(
	position,
	baseAmount,
	big
)

	if not position then

		return

	end

	local amount =
		math.floor(
			baseAmount
			*
			DIRT_PARTICLE_MULTIPLIER
		)

	local holder =
		makeFXHolder(
			position
		)

	local emitter =
		Instance.new(
			"ParticleEmitter"
		)

	emitter.Texture =
		"rbxasset://textures/particles/smoke_main.dds"

	emitter.Rate =
		0

	emitter.Color =
		ColorSequence.new({

			ColorSequenceKeypoint.new(
				0,
				Color3.fromRGB(
					79,
					53,
					31
				)
			),

			ColorSequenceKeypoint.new(
				0.55,
				Color3.fromRGB(
					125,
					85,
					48
				)
			),

			ColorSequenceKeypoint.new(
				1,
				Color3.fromRGB(
					169,
					122,
					75
				)
			),

		})

	--==================================================
	-- 20% larger particle size
	--==================================================

	local startSize =
		(
			if big
			then
				0.7
			else
				0.46
		)
		*
		DIRT_VISIBILITY

	emitter.Size =
		NumberSequence.new({

			NumberSequenceKeypoint.new(
				0,
				startSize
			),

			NumberSequenceKeypoint.new(
				0.6,
				startSize
				*
				0.65
			),

			NumberSequenceKeypoint.new(
				1,
				0.05
			),

		})

	-- More opaque than before.

	emitter.Transparency =
		NumberSequence.new({

			NumberSequenceKeypoint.new(
				0,
				0.02
			),

			NumberSequenceKeypoint.new(
				0.6,
				0.30
			),

			NumberSequenceKeypoint.new(
				1,
				1
			),

		})

	emitter.Lifetime =
		if big
		then
			NumberRange.new(
				0.5,
				0.95
			)
		else
			NumberRange.new(
				0.35,
				0.7
			)

	emitter.Speed =
		if big
		then
			NumberRange.new(
				5,
				10
			)
		else
			NumberRange.new(
				3.5,
				7.5
			)

	emitter.Acceleration =
		Vector3.new(
			0,
			-15,
			0
		)

	emitter.Drag =
		2.5

	emitter.SpreadAngle =
		Vector2.new(
			85,
			85
		)

	emitter.Rotation =
		NumberRange.new(
			0,
			360
		)

	emitter.RotSpeed =
		NumberRange.new(
			-130,
			130
		)

	emitter.Parent =
		holder

	emitter:Emit(
		amount
	)

end

--==================================================
-- HOE ANIMATION
--==================================================

local function stopGripTween()

	if gripTween then

		pcall(
			function()

				gripTween:Cancel()

			end
		)

		gripTween =
			nil

	end

end

local function restoreHoe()

	stopGripTween()

	if
		animatedHoe
		and
		animatedHoe.Parent
		and
		baseGrip
	then

		gripTween =
			TweenService:Create(

				animatedHoe,

				TweenInfo.new(
					0.14,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),

				{
					Grip =
						baseGrip,
				}

			)

		gripTween:Play()

	end

end

local function swingHoe(
	index
)

	local hoe =
		getEquippedHoe()

	if not hoe then

		return

	end

	if animatedHoe ~= hoe then

		animatedHoe =
			hoe

		baseGrip =
			hoe.Grip

	end

	if not baseGrip then

		return

	end

	stopGripTween()

	local power =
		1
		+
		(
			index
			*
			0.05
		)

	local raised =
		baseGrip
		*
		CFrame.Angles(
			math.rad(
				-25
				*
				power
			),
			0,
			math.rad(
				-8
			)
		)

	local hit =
		baseGrip
		*
		CFrame.Angles(
			math.rad(
				33
				*
				power
			),
			0,
			math.rad(
				7
			)
		)

	local raiseTween =
		TweenService:Create(

			hoe,

			TweenInfo.new(
				0.13,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				Grip =
					raised,
			}

		)

	raiseTween:Play()

	raiseTween.Completed:Once(
		function()

			if
				not digging
				or
				not hoe.Parent
			then

				restoreHoe()

				return

			end

			gripTween =
				TweenService:Create(

					hoe,

					TweenInfo.new(
						0.10,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.In
					),

					{
						Grip =
							hit,
					}

				)

			gripTween:Play()

			gripTween.Completed:Once(
				restoreHoe
			)

		end
	)

end

--==================================================
-- HIT
--==================================================

local function doHoeHit(
	index
)

	if not currentDigSpot then

		return

	end

	swingHoe(
		index
	)

	playImpact(
		currentDigSpot,
		index
	)

	emitDirt(
		currentDigSpot,
		HIT_SETTINGS[
			index
		].Dirt,
		false
	)

end

--==================================================
-- RESULT DISPLAY
--==================================================

local resultId =
	0

local function clearReelLabels()

	for _, object in ipairs(
		reelViewport:GetChildren()
	) do

		if object:IsA("TextLabel") then
			object:Destroy()
		end

	end

end

local function showResult(
	text,
	color
)

	resultId +=
		1

	local id =
		resultId

	rollPanel.Visible =
		false

	result.Text =
		text

	result.TextColor3 =
		color
		or
		Color3.new(
			1,
			1,
			1
		)

	result.Visible =
		true

	task.delay(
		1.8,

		function()

			if id == resultId then

				result.Visible =
					false

			end

		end
	)

end

--==================================================
-- PICKUP MESSAGE
--
-- A short reward message stays above the hotbar so a
-- completed dig is visible even while the inventory is
-- closed.
--==================================================

local pickupToast =
	Instance.new(
		"TextLabel"
	)

pickupToast.Name =
	"PotatoPickupToast"

pickupToast.AnchorPoint =
	Vector2.new(
		0.5,
		1
	)

pickupToast.Position =
	UDim2.new(
		0.5,
		0,
		1,
		-150
	)

pickupToast.Size =
	UDim2.fromOffset(
		320,
		34
	)

pickupToast.BackgroundColor3 =
	Color3.fromRGB(
		20,
		25,
		20
	)

pickupToast.BackgroundTransparency =
	0.16

pickupToast.BorderSizePixel =
	0

pickupToast.Font =
	Enum.Font.GothamBold

pickupToast.TextSize =
	16

pickupToast.TextTransparency =
	0

pickupToast.Visible =
	false

pickupToast.Parent =
	gui

local pickupCorner =
	Instance.new(
		"UICorner"
	)

pickupCorner.CornerRadius =
	UDim.new(
		0,
		9
	)

pickupCorner.Parent =
	pickupToast

local pickupStroke =
	Instance.new(
		"UIStroke"
	)

pickupStroke.Thickness =
	1.5

pickupStroke.Parent =
	pickupToast

local PICKUP_RARITY_COLORS = {
	Common = Color3.fromRGB(190, 150, 92),
	Rare = Color3.fromRGB(72, 194, 84),
	Epic = Color3.fromRGB(68, 142, 238),
	Exotic = Color3.fromRGB(168, 77, 224),
	Legendary = Color3.fromRGB(255, 220, 54),
	Super = Color3.fromRGB(255, 205, 35),
	Rainbow = Color3.fromRGB(255, 255, 255),
}

local pickupId =
	0

local function showPickupToast(
	potatoName,
	rarity
)

	pickupId +=
		1

	local id =
		pickupId

	local color =
		PICKUP_RARITY_COLORS[
			tostring(
				rarity
				or
				"Common"
			)
		]
		or
		PICKUP_RARITY_COLORS.Common

	pickupToast.Text =
		"+ "
		..
		tostring(
			potatoName
			or
			"Potato"
		)

	pickupToast.TextColor3 =
		color

	pickupStroke.Color =
		color

	pickupToast.BackgroundTransparency =
		0.16

	pickupToast.TextTransparency =
		0

	pickupStroke.Transparency =
		0.12

	pickupToast.Visible =
		true

	task.delay(
		2.2,

		function()

			if id ~= pickupId then

				return

			end

			local fade =
				TweenService:Create(
					pickupToast,
					TweenInfo.new(
						0.25
					),
					{
						BackgroundTransparency = 1,
						TextTransparency = 1,
					}
				)

			fade:Play()

			task.delay(
				0.3,

				function()

					if id == pickupId then

						pickupToast.Visible =
							false

					end

				end
			)

		end
	)

end

--==================================================
-- ROLL SOUND
--==================================================

local function playRollSound(
	playbackSpeed,
	volume
)

	local sound =
		Instance.new(
			"Sound"
		)

	sound.SoundId =
		ROLL_TICK_SOUND

	sound.Volume =
		volume
		or
		0.35

	sound.PlaybackSpeed =
		playbackSpeed
		or
		1

	sound.Parent =
		playerGui

	sound:Play()

	Debris:AddItem(
		sound,
		2
	)

end

--==================================================
-- MEADOW DROP BAND COLORS
--
-- These are NOT the old Common/Rare/Epic system.
-- They are only visual bands for the current 10
-- Meadow potato types.
--
-- Only Transcendent potatoes use the reel.
-- Normal Meadow potatoes are shown immediately.
--==================================================

local POTATO_BAND_COLORS = {
	["Prism Potato"] = Color3.fromRGB(185, 110, 255),
	["Star Potato"] = Color3.fromRGB(255, 235, 90),
	["Sunkissed Potato"] = Color3.fromRGB(255, 179, 54),
}

local function getBandColor(
	potatoName
)

	return
		POTATO_BAND_COLORS[
			potatoName
		]
		or
		Color3.fromRGB(
			90,
			120,
			90
		)

end

--==================================================
-- TOP-TO-BOTTOM POTATO ROLL
--
-- Server already chose the reward.
-- This only shows a vertical name reel.
-- Names enter from above and move downward.
--==================================================

local function showPotatoRoll(
	finalName
)

	finalName =
		tostring(
			finalName
			or
			"Basic Potato"
		)

	resultId += 1

	local id =
		resultId

	result.Visible =
		false

	clearReelLabels()

	rollPanel.Visible =
		true

	rollStroke.Transparency =
		0.18

	centerSlot.BackgroundTransparency =
		0.84

	centerStroke.Transparency =
		0.22

	--==================================================
	-- TRUE VERTICAL REEL
	--
	-- The WHOLE reel moves ONLY on the Y axis.
	-- As the roll advances, names travel DOWNWARD.
	-- The real reward stops exactly in the middle.
	-- Only one name remains visible above it and one
	-- previous name remains visible below it.
	--==================================================

	reelStrip.Visible =
		true

	local spinCount =
		ROLL_STEPS

	local finalIndex =
		spinCount + 1

	local extraAbove =
		1

	local totalItems =
		finalIndex + extraAbove

	local names = {}
	local previousName = nil

	for index = 1, totalItems do

		local name

		if index == finalIndex then

			name = finalName

		else

			repeat

				name =
					MEADOW_POTATO_NAMES[
						math.random(
							1,
							#MEADOW_POTATO_NAMES
						)
					]

			until
				name ~= previousName
				or
				#MEADOW_POTATO_NAMES <= 1

		end

		previousName = name
		names[index] = name

	end

	local viewportHeight =
		reelViewport.AbsoluteSize.Y

	if viewportHeight <= 0 then
		viewportHeight = 150
	end

	local viewportWidth =
		reelViewport.AbsoluteSize.X

	if viewportWidth <= 0 then
		viewportWidth = 310
	end

	local rowHeight =
		46

	local rowGap =
		2

	local rowStep =
		rowHeight + rowGap

	local labelWidth =
		286

	local fixedX =
		(viewportWidth - labelWidth) / 2

	local centerY =
		viewportHeight / 2

	-- Higher indexes are physically ABOVE lower indexes.
	-- Therefore moving to a higher index moves the strip DOWN.
	local function labelY(index)

		return
			(totalItems - index)
			*
			rowStep

	end

	reelStrip.Size =
		UDim2.fromOffset(
			viewportWidth,
			totalItems * rowStep
		)

	local labels = {}

	for index, potatoName in ipairs(names) do

		local bandColor =
			getBandColor(
				potatoName
			)

		local label =
			Instance.new(
				"TextLabel"
			)

		label.Name =
			"VerticalRollName_"
			..
			index

		label.Position =
			UDim2.fromOffset(
				fixedX,
				labelY(index)
			)

		label.Size =
			UDim2.fromOffset(
				labelWidth,
				rowHeight
			)

		label.BackgroundColor3 =
			bandColor

		label.BackgroundTransparency =
			0.88

		label.BorderSizePixel =
			0

		label.Text =
			string.upper(
				potatoName
			)

		label.TextColor3 =
			Color3.fromRGB(
				235,
				235,
				232
			)

		label.TextTransparency =
			0.40

		label.Font =
			Enum.Font.GothamBold

		label.TextSize =
			13

		label.TextWrapped =
			false

		label.ZIndex =
			5

		label.Parent =
			reelStrip

		local labelCorner =
			Instance.new(
				"UICorner"
			)

		labelCorner.CornerRadius =
			UDim.new(
				0,
				8
			)

		labelCorner.Parent =
			label

		labels[index] =
			label

	end

	local function styleRows(
		selectedIndex,
		isFinal
	)

		local selectedColor =
			getBandColor(
				names[selectedIndex]
			)

		centerSlot.BackgroundColor3 =
			selectedColor

		centerStroke.Color =
			selectedColor

		for labelIndex, label in ipairs(labels) do

			local distance =
				math.abs(
					labelIndex
					-
					selectedIndex
				)

			if labelIndex == selectedIndex then

				label.TextColor3 =
					Color3.fromRGB(
						255,
						255,
						255
					)

				label.TextTransparency =
					0

				label.TextSize =
					isFinal
					and 20
					or 17

				label.BackgroundTransparency =
					isFinal
					and 0.38
					or 0.62

			elseif distance == 1 then

				label.TextTransparency =
					0.25

				label.TextSize =
					14

				label.BackgroundTransparency =
					0.82

			elseif distance == 2 then

				label.TextTransparency =
					0.48

				label.TextSize =
					13

				label.BackgroundTransparency =
					0.90

			else

				label.TextTransparency =
					0.70

				label.TextSize =
					12

				label.BackgroundTransparency =
					0.94

			end

		end

	end

	-- Start with potato #1 in the exact middle.
	local function targetStripY(index)

		return
			centerY
			-
			labelY(index)
			-
			rowHeight / 2

	end

	reelStrip.Position =
		UDim2.fromOffset(
			0,
			targetStripY(1)
		)

	styleRows(
		1,
		false
	)

	playRollSound(
		1.45,
		0.24
	)

	--==================================================
	-- SPIN TOP -> BOTTOM
	--
	-- Only Position.Y changes below.
	-- Position.X is permanently 0.
	--==================================================

	for step = 2, finalIndex do

		if id ~= resultId then

			rollPanel.Visible =
				false

			return

		end

		local progressValue =
			(step - 2)
			/
			math.max(
				1,
				finalIndex - 2
			)

		local duration =
			ROLL_START_DELAY
			+
			(
				ROLL_END_DELAY
				-
				ROLL_START_DELAY
			)
			*
			(progressValue * progressValue)

		local isFinal =
			step == finalIndex

		local tween =
			TweenService:Create(
				reelStrip,
				TweenInfo.new(
					duration,
					isFinal
					and Enum.EasingStyle.Quart
					or Enum.EasingStyle.Linear,
					isFinal
					and Enum.EasingDirection.Out
					or Enum.EasingDirection.InOut
				),
				{
					Position =
						UDim2.fromOffset(
							0,
							targetStripY(step)
						),
				}
			)

		tween:Play()
		tween.Completed:Wait()

		if id ~= resultId then

			rollPanel.Visible =
				false

			return

		end

		styleRows(
			step,
			isFinal
		)

		if isFinal then

			playRollSound(
				0.78,
				0.72
			)

			centerSlot.BackgroundTransparency =
				0.58

			centerStroke.Transparency =
				0.02

			rollStroke.Transparency =
				0.04

		else

			playRollSound(
				1.15
				+
				(1 - progressValue) * 0.35,
				0.28
			)

		end

	end

	-- Final reward is now exactly in the MIDDLE.
	-- Final reward stays exactly in the middle, with one name above and one below.
	task.delay(
		FINAL_RESULT_HOLD_TIME,
		function()

			if id == resultId then

				rollPanel.Visible =
					false

			end

		end
	)

end

--==================================================
-- RESET
--==================================================

local function resetSwingState()

	for index = 1, #swingDone do

		swingDone[
			index
		] =
			false

	end

	windupDone =
		false

end

local function resetDig()

	digging =
		false

	requestPending =
		false

	currentDigId =
		nil

	currentDigSpot =
		nil

	currentDigTime =
		0

	currentEndServerTime =
		0

	currentStartPosition =
		nil

	digPanel.Visible =
		false

	progress.Size =
		UDim2.fromScale(
			0,
			1
		)

	resetSwingState()

	restoreHoe()

end

--==================================================
-- CANCEL
--==================================================

local function cancelDig(
	reason
)

	if not digging then

		return

	end

	local oldSpot =
		currentDigSpot

	if currentDigId then

		CancelDig:FireServer(
			reason,
			currentDigId
		)

	end

	if oldSpot then

		emitDirt(
			oldSpot,
			4,
			false
		)

	end

	showResult(
		"CANCELLED • "
		..
		reason,
		Color3.fromRGB(
			215,
			150,
			90
		)
	)

	resetDig()

end

--==================================================
-- REQUEST
--==================================================

local function requestDig()

	if
		requestPending
		or
		digging
	then

		return

	end

	local position =
		getValidTarget()

	if not position then

		return

	end

	local root =
		getRoot()

	if not root then

		return

	end

	requestPending =
		true

	currentDigSpot =
		position

	currentStartPosition =
		root.Position

	requestSerial +=
		1

	local serial =
		requestSerial

	digPanel.Visible =
		true

	digText.Text =
		"STARTING DIG..."

	RequestDig:FireServer(
		position
	)

	task.delay(
		REQUEST_TIMEOUT,

		function()

			if
				requestPending
				and
				not digging
				and
				requestSerial
				==
				serial
			then

				requestPending =
					false

				digPanel.Visible =
					false

			end

		end
	)

end

--==================================================
-- SERVER START
--==================================================

DigStarted.OnClientEvent:Connect(
	function(
		digTime,
		digId,
		digSpot,
		endServerTime
	)

		if not mouseHeld then

			CancelDig:FireServer(
				"Released click",
				digId
			)

			requestPending =
				false

			digPanel.Visible =
				false

			return

		end

		requestPending =
			false

		digging =
			true

		currentDigId =
			digId

		currentDigTime =
			tonumber(
				digTime
			)
			or
			6

		currentDigSpot =
			digSpot

		currentEndServerTime =
			endServerTime

		local root =
			getRoot()

		if root then

			currentStartPosition =
				root.Position

		end

		resetSwingState()

		local hoe =
			getEquippedHoe()

		if hoe then

			animatedHoe =
				hoe

			baseGrip =
				hoe.Grip

		end

	end
)

--==================================================
-- SERVER CANCELLED
--==================================================

DigCancelled.OnClientEvent:Connect(
	function(
		reason,
		digId
	)

		if
			currentDigId
			and
			digId
			and
			currentDigId
			~=
			digId
		then

			return

		end

		showResult(
			"CANCELLED • "
			..
			tostring(
				reason
			),
			Color3.fromRGB(
				215,
				150,
				90
			)
		)

		resetDig()

	end
)

--==================================================
-- FINISH
--==================================================

DigFinished.OnClientEvent:Connect(
	function(
		data
	)

		local spot =
			currentDigSpot

		if
			type(
				data
			)
			~=
			"table"
		then

			resetDig()

			return

		end

	if data.Type == "Nothing" then

		emitDirt(
			spot,
			15,
			true
		)

		showResult(
			"🕳 NOTHING HERE...",
			Color3.fromRGB(
				200,
				188,
				165
			)
		)

	elseif data.Type == "Potato" then

		local displayName =
			data.DisplayName
			or
			(
				tostring(
					data.PotatoType
					or
					"Basic"
				)
				..
				" Potato"
			)

		emitDirt(
			spot,
			24,
			true
		)

		showPickupToast(
			displayName,
			data.Rarity
		)

		-- Normal Meadow potatoes appear immediately.
		-- Only Transcendent potatoes keep the dramatic reel.

		resetDig()

		local isTranscendent =
			data.IsTranscendent == true
			or
			displayName == "Prism Potato"
			or
			displayName == "Star Potato"
			or
			displayName == "Sunkissed Potato"

		if isTranscendent then
			showPotatoRoll(
				displayName
			)
		else
			local massText = ""

			if data.SpudMass ~= nil then
				massText =
					" • "
					..
					string.format(
						"%.2f kg",
						tonumber(data.SpudMass) or 0
					)
			end

			showResult(
				string.upper(
					displayName
				)
				..
				massText,
				POTATO_COLORS[displayName]
			)
		end

		return

	end

		resetDig()

	end
)

--==================================================
-- HOLD LEFT CLICK
--==================================================

UserInputService.InputBegan:Connect(
	function(
		input,
		gameProcessed
	)

		if gameProcessed then

			return

		end

		if
			input.UserInputType
			~=
			Enum.UserInputType.MouseButton1
		then

			return

		end

		if
			UserInputService:GetFocusedTextBox()
		then

			return

		end

		if mouseHeld then

			return

		end

		mouseHeld =
			true

		requestDig()

	end
)

--==================================================
-- RELEASE LEFT CLICK
--==================================================

UserInputService.InputEnded:Connect(
	function(
		input
	)

		if
			input.UserInputType
			~=
			Enum.UserInputType.MouseButton1
		then

			return

		end

		mouseHeld =
			false

		if requestPending then

			requestPending =
				false

			requestSerial +=
				1

			digPanel.Visible =
				false

			return

		end

		if digging then

			local remaining =
				currentEndServerTime
				-
				Workspace:GetServerTimeNow()

			if remaining > 0.05 then

				cancelDig(
					"Released click"
				)

			end

		end

	end
)

--==================================================
-- UPDATE
--==================================================

RunService.RenderStepped:Connect(
	function()

		if
			not digging
			and
			not requestPending
		then

			targetSpot =
				getValidTarget()

			setIndicator(
				targetSpot,
				false
			)

			return

		end

		if requestPending then

			setIndicator(
				currentDigSpot,
				true
			)

			return

		end

		if not digging then

			return

		end

		setIndicator(
			currentDigSpot,
			true
		)

		--==================================================
		-- HOE STILL EQUIPPED
		--==================================================

		if not getEquippedHoe() then

			cancelDig(
				"Hoe unequipped"
			)

			return

		end

		--==================================================
		-- MOVEMENT
		--==================================================

		local root =
			getRoot()

		if
			root
			and
			currentStartPosition
			and
			horizontalDistance(
				root.Position,
				currentStartPosition
			)
			>
			MAX_PLAYER_RADIUS
		then

			cancelDig(
				"Moved too far"
			)

			return

		end

		--==================================================
		-- CURSOR
		--==================================================

		local mouseGround =
			getMouseGround()

		if
			not mouseGround
			or
			horizontalDistance(
				mouseGround,
				currentDigSpot
			)
			>
			LOOK_AWAY_RADIUS
		then

			cancelDig(
				"Looked away"
			)

			return

		end

		--==================================================
		-- PROGRESS
		--==================================================

		local remaining =
			math.max(
				0,
				currentEndServerTime
				-
				Workspace:GetServerTimeNow()
			)

		local percent =
			math.clamp(
				1
				-
				(
					remaining
					/
					math.max(
						currentDigTime,
						0.01
					)
				),
				0,
				1
			)

		progress.Size =
			UDim2.fromScale(
				percent,
				1
			)

		if remaining > 0 then

			digText.Text =
				"HOLD CLICK • DIGGING "
				..
				string.format(
					"%.1fs",
					remaining
				)

		else

			digText.Text =
				"SEARCHING..."

		end

		--==================================================
		-- HOE IMPACTS
		--==================================================

		for index, swingPoint in ipairs(
			SWING_POINTS
		) do

			if
				not swingDone[
					index
				]
				and
				percent
				>=
				swingPoint
			then

				swingDone[
					index
				] =
					true

				doHoeHit(
					index
				)

			end

		end

		--==================================================
		-- FINAL WIND-UP
		--==================================================

		if
			not windupDone
			and
			percent
			>=
			WINDUP_POINT
		then

			windupDone =
				true

			if
				animatedHoe
				and
				baseGrip
			then

				stopGripTween()

				gripTween =
					TweenService:Create(

						animatedHoe,

						TweenInfo.new(
							0.15
						),

						{
							Grip =
								baseGrip
								*
								CFrame.Angles(
									math.rad(
										-15
									),
									0,
									0
								),
						}

					)

				gripTween:Play()

			end

		end

	end
)

--==================================================
-- RESPAWN
--==================================================

player.CharacterAdded:Connect(
	function()

		mouseHeld =
			false

		requestSerial +=
			1

		resetDig()

	end
)

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("⛏ FORAGING DIG CLIENT V8")
print("========================================")
print("🖱 HOLD CLICK = DIG")
print("🔊 Generic block-like impact sound")
print("🔊 Slight pitch variation per hit")
print("💨 Dirt visibility +20%")
print("💨 Dirt particle count +20%")
print("⛏ 4 digging swings")
print("⬇ 3-ROW TOP-TO-BOTTOM POTATO ROULETTE V8")
print("❌ No timing bonus")
print("❌ No vibration")
print("========================================")
print("")
