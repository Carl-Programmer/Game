--========================================================
-- POTATIUM - CRATE OPENING CLIENT V2
--
-- SAME PANEL SIZE AS V1: 650 x 205
--
-- ✅ Completely polished roulette GUI
-- ✅ Spins LEFT -> RIGHT visually
-- ✅ Reward still picked by SERVER first
-- ✅ Winning reward stops exactly in CENTER
-- ✅ Common / Rare / Epic visual grades
-- ✅ Clearer wording
-- ✅ Spam-safe
--
-- IMPORTANT:
-- Common/Rare/Epic below are ONLY visual hoe grades.
-- This does NOT bring back old potato rarity RNG.
--========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player =
	Players.LocalPlayer

local playerGui =
	player:WaitForChild(
		"PlayerGui"
	)

local backpack =
	player:WaitForChild(
		"Backpack"
	)

local remotes =
	ReplicatedStorage:WaitForChild(
		"PotatiumCrateRemotes"
	)

local requestOpen =
	remotes:WaitForChild(
		"RequestOpenCrate"
	)

local openResult =
	remotes:WaitForChild(
		"CrateOpenResult"
	)

local messageRemote =
	remotes:WaitForChild(
		"CrateMessage"
	)

--========================================================
-- SETTINGS
--========================================================

local REWARD_NAMES = {
	"Wooden Hoe",
	"Stone Hoe",
	"Iron Hoe",
}

local REWARD_INFO = {
	["Wooden Hoe"] = {
		Grade = "COMMON",
		Accent = Color3.fromRGB(224, 154, 76),
		Fill = Color3.fromRGB(72, 51, 34),
	},

	["Stone Hoe"] = {
		Grade = "RARE",
		Accent = Color3.fromRGB(126, 166, 201),
		Fill = Color3.fromRGB(39, 52, 65),
	},

	["Iron Hoe"] = {
		Grade = "EPIC",
		Accent = Color3.fromRGB(183, 142, 222),
		Fill = Color3.fromRGB(52, 42, 66),
	},
}

local ROLL_STEPS = 25
local START_TIME = 0.045
local END_TIME = 0.27
local FINAL_HOLD = 2.0

local opening = false
local requestToken = 0
local connectedTools = {}

--========================================================
-- SOUND
--========================================================

local rollSound =
	Instance.new("Sound")

rollSound.Name =
	"CrateRollTick"

rollSound.SoundId =
	"rbxasset://sounds/electronicpingshort.wav"

rollSound.Volume =
	0.28

rollSound.Parent =
	playerGui

local function playTick(
	pitch,
	volume
)
	rollSound.PlaybackSpeed =
		pitch
		or
		1

	rollSound.Volume =
		volume
		or
		0.28

	rollSound.TimePosition =
		0

	rollSound:Play()
end

--========================================================
-- UI HELPERS
--========================================================

local function addCorner(
	object,
	radius
)
	local corner =
		Instance.new(
			"UICorner"
		)

	corner.CornerRadius =
		UDim.new(
			0,
			radius
		)

	corner.Parent =
		object

	return corner
end

local function addStroke(
	object,
	color,
	thickness,
	transparency
)
	local stroke =
		Instance.new(
			"UIStroke"
		)

	stroke.Color =
		color

	stroke.Thickness =
		thickness
		or
		1

	stroke.Transparency =
		transparency
		or
		0

	stroke.ApplyStrokeMode =
		Enum.ApplyStrokeMode.Border

	stroke.Parent =
		object

	return stroke
end

local function addGradient(
	object,
	first,
	second,
	rotation
)
	local gradient =
		Instance.new(
			"UIGradient"
		)

	gradient.Color =
		ColorSequence.new({
			ColorSequenceKeypoint.new(
				0,
				first
			),

			ColorSequenceKeypoint.new(
				1,
				second
			),
		})

	gradient.Rotation =
		rotation
		or
		90

	gradient.Parent =
		object

	return gradient
end

local function makeLabel(
	parent,
	text,
	textSize,
	font,
	color
)
	local label =
		Instance.new(
			"TextLabel"
		)

	label.BackgroundTransparency =
		1

	label.Text =
		text
		or
		""

	label.TextSize =
		textSize
		or
		14

	label.Font =
		font
		or
		Enum.Font.Gotham

	label.TextColor3 =
		color
		or
		Color3.fromRGB(
			242,
			246,
			250
		)

	label.Parent =
		parent

	return label
end

--========================================================
-- GUI
--========================================================

local old =
	playerGui:FindFirstChild(
		"CrateOpeningGui"
	)

if old then
	old:Destroy()
end

local gui =
	Instance.new(
		"ScreenGui"
	)

gui.Name =
	"CrateOpeningGui"

gui.ResetOnSpawn =
	false

gui.IgnoreGuiInset =
	false

gui.DisplayOrder =
	95

gui.Parent =
	playerGui

--========================================================
-- PANEL
-- SAME SIZE: 650 x 205
--========================================================

local shadow =
	Instance.new(
		"Frame"
	)

shadow.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)

shadow.Position =
	UDim2.new(
		0.5,
		5,
		0.48,
		7
	)

shadow.Size =
	UDim2.fromOffset(
		650,
		205
	)

shadow.BackgroundColor3 =
	Color3.new(
		0,
		0,
		0
	)

shadow.BackgroundTransparency =
	0.50

shadow.BorderSizePixel =
	0

shadow.Visible =
	false

shadow.Parent =
	gui

addCorner(
	shadow,
	14
)

local panel =
	Instance.new(
		"Frame"
	)

panel.Name =
	"Panel"

panel.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)

panel.Position =
	UDim2.fromScale(
		0.5,
		0.48
	)

panel.Size =
	UDim2.fromOffset(
		650,
		205
	)

panel.BackgroundColor3 =
	Color3.fromRGB(
		14,
		20,
		28
	)

panel.BackgroundTransparency =
	0.01

panel.BorderSizePixel =
	0

panel.Visible =
	false

panel.ClipsDescendants =
	true

panel.Parent =
	gui

addCorner(
	panel,
	14
)

addStroke(
	panel,
	Color3.fromRGB(
		84,
		150,
		182
	),
	1.4,
	0.10
)

addGradient(
	panel,
	Color3.fromRGB(
		18,
		27,
		37
	),
	Color3.fromRGB(
		10,
		15,
		22
	),
	90
)

--========================================================
-- HEADER
--========================================================

local headerAccent =
	Instance.new(
		"Frame"
	)

headerAccent.Position =
	UDim2.fromOffset(
		18,
		14
	)

headerAccent.Size =
	UDim2.fromOffset(
		4,
		33
	)

headerAccent.BackgroundColor3 =
	Color3.fromRGB(
		224,
		154,
		76
	)

headerAccent.BorderSizePixel =
	0

headerAccent.Parent =
	panel

addCorner(
	headerAccent,
	2
)

local title =
	makeLabel(
		panel,
		"WOODEN CRATE",
		19,
		Enum.Font.GothamBlack,
		Color3.fromRGB(
			245,
			247,
			249
		)
	)

title.Position =
	UDim2.fromOffset(
		32,
		9
	)

title.Size =
	UDim2.fromOffset(
		260,
		27
	)

title.TextXAlignment =
	Enum.TextXAlignment.Left

local odds =
	makeLabel(
		panel,
		"75% WOODEN  •  20% STONE  •  5% IRON",
		9,
		Enum.Font.GothamBold,
		Color3.fromRGB(
			147,
			170,
			185
		)
	)

odds.Position =
	UDim2.fromOffset(
		33,
		34
	)

odds.Size =
	UDim2.fromOffset(
		310,
		16
	)

odds.TextXAlignment =
	Enum.TextXAlignment.Left

local directionLabel =
	makeLabel(
		panel,
		"ROLL  >>>",
		9,
		Enum.Font.GothamBold,
		Color3.fromRGB(
			99,
			184,
			211
		)
	)

directionLabel.AnchorPoint =
	Vector2.new(
		1,
		0
	)

directionLabel.Position =
	UDim2.new(
		1,
		-20,
		0,
		22
	)

directionLabel.Size =
	UDim2.fromOffset(
		95,
		16
	)

directionLabel.TextXAlignment =
	Enum.TextXAlignment.Right

local headerLine =
	Instance.new(
		"Frame"
	)

headerLine.Position =
	UDim2.fromOffset(
		18,
		55
	)

headerLine.Size =
	UDim2.new(
		1,
		-36,
		0,
		1
	)

headerLine.BackgroundColor3 =
	Color3.fromRGB(
		65,
		91,
		108
	)

headerLine.BackgroundTransparency =
	0.30

headerLine.BorderSizePixel =
	0

headerLine.Parent =
	panel

--========================================================
-- VIEWPORT
--========================================================

local viewport =
	Instance.new(
		"Frame"
	)

viewport.Name =
	"Viewport"

viewport.Position =
	UDim2.fromOffset(
		18,
		66
	)

viewport.Size =
	UDim2.fromOffset(
		614,
		94
	)

viewport.BackgroundColor3 =
	Color3.fromRGB(
		7,
		11,
		16
	)

viewport.BackgroundTransparency =
	0.03

viewport.BorderSizePixel =
	0

viewport.ClipsDescendants =
	true

viewport.Parent =
	panel

addCorner(
	viewport,
	10
)

addStroke(
	viewport,
	Color3.fromRGB(
		57,
		79,
		94
	),
	1,
	0.18
)

-- left/right edge masks help it look like a real reel
local leftFade =
	Instance.new(
		"Frame"
	)

leftFade.Position =
	UDim2.fromOffset(
		0,
		0
	)

leftFade.Size =
	UDim2.fromOffset(
		42,
		94
	)

leftFade.BackgroundColor3 =
	Color3.fromRGB(
		7,
		11,
		16
	)

leftFade.BackgroundTransparency =
	0.28

leftFade.BorderSizePixel =
	0

leftFade.ZIndex =
	20

leftFade.Parent =
	viewport

local rightFade =
	leftFade:Clone()

rightFade.AnchorPoint =
	Vector2.new(
		1,
		0
	)

rightFade.Position =
	UDim2.new(
		1,
		0,
		0,
		0
	)

rightFade.Parent =
	viewport

--========================================================
-- CENTER SELECTOR
--========================================================

local selector =
	Instance.new(
		"Frame"
	)

selector.Name =
	"CenterSelector"

selector.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)

selector.Position =
	UDim2.fromScale(
		0.5,
		0.5
	)

selector.Size =
	UDim2.fromOffset(
		116,
		84
	)

selector.BackgroundColor3 =
	Color3.fromRGB(
		224,
		154,
		76
	)

selector.BackgroundTransparency =
	0.91

selector.BorderSizePixel =
	0

selector.ZIndex =
	15

selector.Parent =
	viewport

addCorner(
	selector,
	9
)

local selectorStroke =
	addStroke(
		selector,
		Color3.fromRGB(
			244,
			179,
			99
		),
		2,
		0.02
	)

local topArrow =
	makeLabel(
		viewport,
		"▼",
		13,
		Enum.Font.GothamBlack,
		Color3.fromRGB(
			244,
			179,
			99
		)
	)

topArrow.AnchorPoint =
	Vector2.new(
		0.5,
		0
	)

topArrow.Position =
	UDim2.new(
		0.5,
		0,
		0,
		-2
	)

topArrow.Size =
	UDim2.fromOffset(
		22,
		15
	)

topArrow.ZIndex =
	18

local bottomArrow =
	makeLabel(
		viewport,
		"▲",
		13,
		Enum.Font.GothamBlack,
		Color3.fromRGB(
			244,
			179,
			99
		)
	)

bottomArrow.AnchorPoint =
	Vector2.new(
		0.5,
		1
	)

bottomArrow.Position =
	UDim2.new(
		0.5,
		0,
		1,
		2
	)

bottomArrow.Size =
	UDim2.fromOffset(
		22,
		15
	)

bottomArrow.ZIndex =
	18

--========================================================
-- STRIP
--========================================================

local strip =
	Instance.new(
		"Frame"
	)

strip.Name =
	"RollStrip"

strip.BackgroundTransparency =
	1

strip.Position =
	UDim2.fromOffset(
		0,
		0
	)

strip.Size =
	UDim2.fromOffset(
		614,
		94
	)

strip.ZIndex =
	5

strip.Parent =
	viewport

--========================================================
-- RESULT BAR
--========================================================

local resultBar =
	Instance.new(
		"Frame"
	)

resultBar.Position =
	UDim2.fromOffset(
		18,
		169
	)

resultBar.Size =
	UDim2.new(
		1,
		-36,
		0,
		25
	)

resultBar.BackgroundColor3 =
	Color3.fromRGB(
		18,
		27,
		36
	)

resultBar.BorderSizePixel =
	0

resultBar.Parent =
	panel

addCorner(
	resultBar,
	7
)

local resultText =
	makeLabel(
		resultBar,
		"ROLLING...",
		11,
		Enum.Font.GothamBold,
		Color3.fromRGB(
			187,
			200,
			210
		)
	)

resultText.Size =
	UDim2.fromScale(
		1,
		1
	)

--========================================================
-- ROULETTE HELPERS
--========================================================

local function clearStrip()
	for _, child in ipairs(
		strip:GetChildren()
	) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function randomRewardName(
	previous
)
	local name

	repeat
		name =
			REWARD_NAMES[
				math.random(
					1,
					#REWARD_NAMES
				)
			]
	until
		name ~= previous
		or
		#REWARD_NAMES <= 1

	return name
end

local function makeRewardCard(
	index,
	rewardName,
	x
)
	local info =
		REWARD_INFO[
			rewardName
		]
		or
		REWARD_INFO[
			"Wooden Hoe"
		]

	local card =
		Instance.new(
			"Frame"
		)

	card.Name =
		"Reward_"
		..
		tostring(index)

	card.Position =
		UDim2.fromOffset(
			x,
			7
		)

	card.Size =
		UDim2.fromOffset(
			108,
			80
		)

	card.BackgroundColor3 =
		info.Fill

	card.BackgroundTransparency =
		0.08

	card.BorderSizePixel =
		0

	card.ZIndex =
		6

	card.Parent =
		strip

	addCorner(
		card,
		8
	)

	local cardStroke =
		addStroke(
			card,
			info.Accent,
			1,
			0.28
		)

	local small =
		makeLabel(
			card,
			info.Grade,
			8,
			Enum.Font.GothamBold,
			info.Accent
		)

	small.Position =
		UDim2.fromOffset(
			8,
			7
		)

	small.Size =
		UDim2.new(
			1,
			-16,
			0,
			13
		)

	small.TextXAlignment =
		Enum.TextXAlignment.Left

	small.ZIndex =
		7

	local name =
		makeLabel(
			card,
			string.upper(
				rewardName
			),
			12,
			Enum.Font.GothamBlack,
			Color3.fromRGB(
				244,
				247,
				250
			)
		)

	name.Position =
		UDim2.fromOffset(
			8,
			24
		)

	name.Size =
		UDim2.new(
			1,
			-16,
			0,
			34
		)

	name.TextWrapped =
		true

	name.TextXAlignment =
		Enum.TextXAlignment.Center

	name.TextYAlignment =
		Enum.TextYAlignment.Center

	name.ZIndex =
		7

	local chance =
		makeLabel(
			card,
			rewardName == "Wooden Hoe"
				and
				"75%"
				or
				rewardName == "Stone Hoe"
				and
					"20%"
					or
					"5%",
			9,
			Enum.Font.GothamBold,
			Color3.fromRGB(
				170,
				185,
				195
			)
		)

	chance.Position =
		UDim2.new(
			0,
			8,
			1,
			-19
		)

	chance.Size =
		UDim2.new(
			1,
			-16,
			0,
			13
		)

	chance.ZIndex =
		7

	return {
		Frame = card,
		Stroke = cardStroke,
		Name = name,
		Grade = small,
		Info = info,
	}
end

--========================================================
-- LEFT -> RIGHT ROULETTE
--
-- PHYSICAL ORDER IS REVERSED:
-- larger indexes live further LEFT.
-- Moving to a larger index increases Strip.Position.X.
--
-- Therefore the visible cards travel:
-- LEFT  ---------->  RIGHT
--========================================================

local function playRoulette(
	finalName
)
	requestToken += 1

	local token =
		requestToken

	clearStrip()

	panel.Visible =
		true

	shadow.Visible =
		true

	resultText.Text =
		""

	resultText.TextColor3 =
		Color3.fromRGB(
			165,
			186,
			199
		)

	selectorStroke.Thickness =
		2

	local finalIndex =
		ROLL_STEPS + 1

	local totalItems =
		finalIndex + 4

	local names = {}
	local previous = nil

	for index = 1, totalItems do
		local name

		if index == finalIndex then
			name =
				finalName
		else
			name =
				randomRewardName(
					previous
				)
		end

		names[index] =
			name

		previous =
			name
	end

	local slotWidth = 108
	local gap = 8

	local stepWidth =
		slotWidth
		+
		gap

	local viewportWidth =
		viewport.AbsoluteSize.X

	if viewportWidth <= 0 then
		viewportWidth = 614
	end

	local centerX =
		viewportWidth
		/
		2

	-- IMPORTANT:
	-- Index 1 starts furthest RIGHT.
	-- Higher indexes are further LEFT.
	-- As selected index increases, Strip.Position.X increases.
	-- That makes all cards move LEFT -> RIGHT.
	local function cardX(index)
		return
			(
				totalItems
				-
				index
			)
			*
			stepWidth
	end

	strip.Size =
		UDim2.fromOffset(
			totalItems
			*
			stepWidth,
			94
		)

	local cards = {}

	for index, rewardName in ipairs(
		names
	) do
		cards[index] =
			makeRewardCard(
				index,
				rewardName,
				cardX(index)
			)
	end

	local function targetStripX(index)
		return
			centerX
			-
			cardX(index)
			-
			slotWidth
			/
			2
	end

	local function styleSelection(
		selectedIndex,
		final
	)
		for index, data in ipairs(
			cards
		) do
			if
				index
				==
				selectedIndex
			then
				data.Frame.BackgroundTransparency =
					final
					and
					0
					or
					0.04

				data.Stroke.Transparency =
					0

				data.Stroke.Thickness =
					final
					and
					2
					or
					1.4

				data.Name.TextTransparency =
					0

				data.Grade.TextTransparency =
					0
			else
				data.Frame.BackgroundTransparency =
					0.27

				data.Stroke.Transparency =
					0.55

				data.Stroke.Thickness =
					1

				data.Name.TextTransparency =
					0.18

				data.Grade.TextTransparency =
					0.25
			end
		end
	end

	strip.Position =
		UDim2.fromOffset(
			targetStripX(1),
			0
		)

	styleSelection(
		1,
		false
	)

	playTick(
		1.38,
		0.20
	)

	for step = 2, finalIndex do
		if
			token
			~=
			requestToken
		then
			return
		end

		local progress =
			(step - 2)
			/
			math.max(
				1,
				finalIndex - 2
			)

		local duration =
			START_TIME
			+
			(
				END_TIME
				-
				START_TIME
			)
			*
			(
				progress
				*
				progress
			)

		local finalStep =
			step
			==
			finalIndex

		local tween =
			TweenService:Create(
				strip,
				TweenInfo.new(
					duration,
					finalStep
						and
						Enum.EasingStyle.Quart
						or
						Enum.EasingStyle.Linear,
					finalStep
						and
						Enum.EasingDirection.Out
						or
						Enum.EasingDirection.InOut
				),
				{
					Position =
						UDim2.fromOffset(
							targetStripX(
								step
							),
							0
						),
				}
			)

		tween:Play()
		tween.Completed:Wait()

		if
			token
			~=
			requestToken
		then
			return
		end

		styleSelection(
			step,
			finalStep
		)

		if finalStep then
			playTick(
				0.78,
				0.62
			)

			selectorStroke.Thickness =
				3

			local finalInfo =
				REWARD_INFO[
					finalName
				]
				or
				REWARD_INFO[
					"Wooden Hoe"
				]

			resultText.Text =
				"YOU GOT  •  "
				..
				string.upper(
					finalName
				)
				..
				"  /  "
				..
				finalInfo.Grade

			resultText.TextColor3 =
				finalInfo.Accent
		else
			playTick(
				1.05
				+
				(1 - progress)
				*
				0.30,
				0.23
			)
		end
	end

	task.wait(
		FINAL_HOLD
	)

	if
		token
		==
		requestToken
	then
		panel.Visible =
			false

		shadow.Visible =
			false
	end

	opening =
		false
end

--========================================================
-- CRATE TOOL ACTIVATION
--========================================================

local function connectCrateTool(
	tool
)
	if
		not tool:IsA(
			"Tool"
		)
		or
		tool:GetAttribute(
			"CrateTool"
		)
		~=
		true
	then
		return
	end

	if connectedTools[tool] then
		return
	end

	connectedTools[tool] =
		true

	tool.Destroying:Connect(
		function()
			connectedTools[
				tool
			] =
				nil
		end
	)

	tool.Activated:Connect(
		function()
			if opening then
				return
			end

			opening =
				true

			local crateType =
				tool:GetAttribute(
					"CrateType"
				)
				or
				"Wooden"

			requestOpen:FireServer(
				crateType
			)

			task.delay(
				7,
				function()
					if
						opening
						and
						not panel.Visible
					then
						opening =
							false
					end
				end
			)
		end
	)
end

local function scan(
	container
)
	for _, child in ipairs(
		container:GetChildren()
	) do
		connectCrateTool(
			child
		)
	end
end

backpack.ChildAdded:Connect(
	connectCrateTool
)

scan(
	backpack
)

local function watchCharacter(
	character
)
	character.ChildAdded:Connect(
		connectCrateTool
	)

	scan(
		character
	)
end

if player.Character then
	watchCharacter(
		player.Character
	)
end

player.CharacterAdded:Connect(
	watchCharacter
)

--========================================================
-- SERVER RESULT / MESSAGE
--========================================================

openResult.OnClientEvent:Connect(
	function(
		crateType,
		rewardName,
		rewardTier
	)
		if
			crateType
			~=
			"Wooden"
		then
			opening =
				false

			return
		end

		task.spawn(
			playRoulette,
			tostring(
				rewardName
			)
		)
	end
)

messageRemote.OnClientEvent:Connect(
	function(text)
		opening =
			false

		panel.Visible =
			false

		shadow.Visible =
			false

		pcall(
			function()
				StarterGui:SetCore(
					"SendNotification",
					{
						Title =
							"Potatium",
						Text =
							tostring(
								text
							),
						Duration =
							3,
					}
				)
			end
		)
	end
)

print("")
print("========================================")
print("📦 CRATE OPENING CLIENT V2.1 - NO ROLLING LINE")
print("========================================")
print("✅ Same size: 650 x 205")
print("✅ LEFT -> RIGHT visual movement")
print("✅ Rolling direction text removed")
print("✅ Center-selected reward")
print("✅ COMMON / RARE / EPIC visual grades")
print("✅ Server reward remains authoritative")
print("✅ Spam-safe")
print("========================================")
print("")
