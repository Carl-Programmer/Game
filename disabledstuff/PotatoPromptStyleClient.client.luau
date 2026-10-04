--==================================================
-- 🥔 POTATIUM CUSTOM POTATO PROMPTS V1
--
-- Custom UI for:
-- E = Place Potato
-- R = Remove Potato
--
-- Also handles local sound effects.
--
-- PLACE SOUND:
-- rbxassetid://125360182283760
--
-- REMOVE SOUND:
-- rbxassetid://76905474546464
--==================================================

local Players =
	game:GetService("Players")

local ProximityPromptService =
	game:GetService("ProximityPromptService")

local TweenService =
	game:GetService("TweenService")

local SoundService =
	game:GetService("SoundService")

local Workspace =
	game:GetService("Workspace")

local player =
	Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local PLACE_PROMPT_NAME =
	"PotatoPlacePrompt"

local REMOVE_PROMPT_NAME =
	"RemovePotatoPrompt"

local PLACE_SOUND_ID =
	"rbxassetid://125360182283760"

local REMOVE_SOUND_ID =
	"rbxassetid://76905474546464"

local PLACE_VOLUME =
	0.8

local REMOVE_VOLUME =
	0.8

--==================================================
-- COLORS
--==================================================

local BACKGROUND_COLOR =
	Color3.fromRGB(
		34,
		27,
		20
	)

local INNER_COLOR =
	Color3.fromRGB(
		49,
		38,
		27
	)

local PLACE_COLOR =
	Color3.fromRGB(
		104,
		220,
		82
	)

local REMOVE_COLOR =
	Color3.fromRGB(
		255,
		171,
		64
	)

local WHITE =
	Color3.fromRGB(
		245,
		241,
		230
	)

local MUTED =
	Color3.fromRGB(
		185,
		177,
		158
	)

--==================================================
-- ACTIVE UI
--==================================================

local activePrompts = {}

--==================================================
-- SOUNDS
--==================================================

local placeSound =
	Instance.new("Sound")

placeSound.Name =
	"PotatoPlaceSound"

placeSound.SoundId =
	PLACE_SOUND_ID

placeSound.Volume =
	PLACE_VOLUME

placeSound.PlaybackSpeed =
	1

placeSound.Parent =
	SoundService


local removeSound =
	Instance.new("Sound")

removeSound.Name =
	"PotatoRemoveSound"

removeSound.SoundId =
	REMOVE_SOUND_ID

removeSound.Volume =
	REMOVE_VOLUME

removeSound.PlaybackSpeed =
	1

removeSound.Parent =
	SoundService

--==================================================
-- CHECK POTATO PROMPT
--==================================================

local function getPromptType(
	prompt
)

	if not prompt then
		return nil
	end

	if
		prompt.Name
		==
		PLACE_PROMPT_NAME
	then

		return "PLACE"

	end

	if
		prompt.Name
		==
		REMOVE_PROMPT_NAME
	then

		return "REMOVE"

	end

	return nil

end

--==================================================
-- FORCE CUSTOM ROBLOX STYLE
--==================================================

local function stylePrompt(
	prompt
)

	if
		not prompt:IsA(
			"ProximityPrompt"
		)
	then

		return

	end

	local promptType =
		getPromptType(
			prompt
		)

	if not promptType then
		return
	end

	prompt.Style =
		Enum.ProximityPromptStyle.Custom

end

--==================================================
-- GET ADORNEE
--==================================================

local function getAdornee(
	prompt
)

	local parent =
		prompt.Parent

	if not parent then
		return nil
	end

	if
		parent:IsA(
			"BasePart"
		)
	then

		return parent

	end

	if
		parent:IsA(
			"Attachment"
		)
	then

		return parent

	end

	return
		parent:FindFirstAncestorWhichIsA(
			"BasePart"
		)

end

--==================================================
-- GET KEY TEXT
--==================================================

local function getKeyText(
	prompt,
	inputType
)

	if
		inputType
		==
		Enum.ProximityPromptInputType.Touch
	then

		return "TAP"

	end

	if
		inputType
		==
		Enum.ProximityPromptInputType.Gamepad
	then

		local key =
			prompt.GamepadKeyCode

		return
			key.Name

	end

	local key =
		prompt.KeyboardKeyCode

	if key then

		return
			key.Name

	end

	return "E"

end

--==================================================
-- GET PLACE SUBTITLE
--==================================================

local function getPlaceSubtitle(
	prompt
)

	local objectText =
		prompt.ObjectText

	if
		objectText
		and
		objectText ~= ""
	then

		local number =
			string.match(
				objectText,
				"FarmLand_(%d+)"
			)

		if number then

			return
				"PLOT "
				..
				tostring(
					tonumber(number)
						or
						number
				)

		end

		return
			string.upper(
				objectText
			)

	end

	return "FARM PLOT"

end

--==================================================
-- GET REMOVE SUBTITLE
--==================================================

local function getRemoveSubtitle(
	prompt
)

	local objectText =
		prompt.ObjectText

	if
		objectText
		and
		objectText ~= ""
	then

		return objectText

	end

	return "Potato"

end

--==================================================
-- PLAY ACTION SOUND
--==================================================

local function playActionSound(
	prompt
)

	local promptType =
		getPromptType(
			prompt
		)

	if
		promptType
		==
		"PLACE"
	then

		placeSound:Stop()

		placeSound.TimePosition =
			0

		placeSound:Play()

	elseif
		promptType
		==
		"REMOVE"
	then

		removeSound:Stop()

		removeSound.TimePosition =
			0

		removeSound:Play()

	end

end

--==================================================
-- CREATE TEXT
--==================================================

local function createTextLabel(
	parent,
	name,
	text,
	font,
	size,
	color
)

	local label =
		Instance.new(
			"TextLabel"
		)

	label.Name =
		name

	label.BackgroundTransparency =
		1

	label.Text =
		text

	label.TextColor3 =
		color

	label.TextSize =
		size

	label.Font =
		font

	label.TextXAlignment =
		Enum.TextXAlignment.Left

	label.TextYAlignment =
		Enum.TextYAlignment.Center

	label.Parent =
		parent

	return label

end

--==================================================
-- CREATE CUSTOM PROMPT
--==================================================

local function createPromptGui(
	prompt,
	inputType
)

	local promptType =
		getPromptType(
			prompt
		)

	if not promptType then
		return nil
	end

	local adornee =
		getAdornee(
			prompt
		)

	if not adornee then
		return nil
	end

	local isPlace =
		promptType == "PLACE"

	local accentColor

	local titleText

	local subtitleText

	local iconText

	if isPlace then

		accentColor =
			PLACE_COLOR

		titleText =
			"PLANT POTATO"

		subtitleText =
			getPlaceSubtitle(
				prompt
			)

		iconText =
			"🥔"

	else

		accentColor =
			REMOVE_COLOR

		titleText =
			"PICK UP POTATO"

		subtitleText =
			getRemoveSubtitle(
				prompt
			)

		iconText =
			"↩"

	end

	--==================================================
	-- BILLBOARD
	--==================================================

	local gui =
		Instance.new(
			"BillboardGui"
		)

	gui.Name =
		"PotatiumPotatoPrompt"

	gui.Adornee =
		adornee

	gui.AlwaysOnTop =
		true

	gui.LightInfluence =
		0

	gui.Size =
		UDim2.fromOffset(
			282,
			88
		)

	gui.StudsOffsetWorldSpace =
		Vector3.new(
			0,
			3.2,
			0
		)

	gui.ResetOnSpawn =
		false

	gui.Parent =
		player:WaitForChild(
			"PlayerGui"
		)

	--==================================================
	-- MAIN CARD
	--==================================================

	local main =
		Instance.new(
			"Frame"
		)

	main.Name =
		"Main"

	main.Size =
		UDim2.fromScale(
			1,
			1
		)

	main.BackgroundColor3 =
		BACKGROUND_COLOR

	main.BackgroundTransparency =
		0.06

	main.BorderSizePixel =
		0

	main.Parent =
		gui

	local mainCorner =
		Instance.new(
			"UICorner"
		)

	mainCorner.CornerRadius =
		UDim.new(
			0,
			16
		)

	mainCorner.Parent =
		main

	local mainStroke =
		Instance.new(
			"UIStroke"
		)

	mainStroke.Color =
		accentColor

	mainStroke.Transparency =
		0.25

	mainStroke.Thickness =
		1.5

	mainStroke.Parent =
		main

	--==================================================
	-- SHADOW
	--==================================================

	local shadow =
		Instance.new(
			"Frame"
		)

	shadow.Name =
		"Shadow"

	shadow.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	shadow.Position =
		UDim2.new(
			0.5,
			0,
			0.5,
			4
		)

	shadow.Size =
		UDim2.new(
			1,
			8,
			1,
			8
		)

	shadow.BackgroundColor3 =
		Color3.new(
			0,
			0,
			0
		)

	shadow.BackgroundTransparency =
		0.55

	shadow.BorderSizePixel =
		0

	shadow.ZIndex =
		-1

	shadow.Parent =
		main

	local shadowCorner =
		Instance.new(
			"UICorner"
		)

	shadowCorner.CornerRadius =
		UDim.new(
			0,
			18
		)

	shadowCorner.Parent =
		shadow

	--==================================================
	-- LEFT ACCENT
	--==================================================

	local accent =
		Instance.new(
			"Frame"
		)

	accent.Name =
		"Accent"

	accent.Position =
		UDim2.fromOffset(
			0,
			11
		)

	accent.Size =
		UDim2.new(
			0,
			5,
			1,
			-22
		)

	accent.BackgroundColor3 =
		accentColor

	accent.BorderSizePixel =
		0

	accent.Parent =
		main

	local accentCorner =
		Instance.new(
			"UICorner"
		)

	accentCorner.CornerRadius =
		UDim.new(
			1,
			0
		)

	accentCorner.Parent =
		accent

	--==================================================
	-- ICON CIRCLE
	--==================================================

	local iconFrame =
		Instance.new(
			"Frame"
		)

	iconFrame.Name =
		"IconFrame"

	iconFrame.Position =
		UDim2.fromOffset(
			18,
			16
		)

	iconFrame.Size =
		UDim2.fromOffset(
			56,
			56
		)

	iconFrame.BackgroundColor3 =
		INNER_COLOR

	iconFrame.BorderSizePixel =
		0

	iconFrame.Parent =
		main

	local iconCorner =
		Instance.new(
			"UICorner"
		)

	iconCorner.CornerRadius =
		UDim.new(
			1,
			0
		)

	iconCorner.Parent =
		iconFrame

	local iconStroke =
		Instance.new(
			"UIStroke"
		)

	iconStroke.Color =
		accentColor

	iconStroke.Transparency =
		0.2

	iconStroke.Thickness =
		2

	iconStroke.Parent =
		iconFrame

	local icon =
		Instance.new(
			"TextLabel"
		)

	icon.Name =
		"Icon"

	icon.Size =
		UDim2.fromScale(
			1,
			1
		)

	icon.BackgroundTransparency =
		1

	icon.Text =
		iconText

	icon.TextSize =
		28

	icon.Font =
		Enum.Font.GothamBold

	icon.TextColor3 =
		WHITE

	icon.Parent =
		iconFrame

	--==================================================
	-- SMALL HEADER
	--==================================================

	local header =
		createTextLabel(
			main,
			"Header",
			"POTATIUM  •  FARM ACTION",
			Enum.Font.GothamMedium,
			10,
			accentColor
		)

	header.Position =
		UDim2.fromOffset(
			87,
			11
		)

	header.Size =
		UDim2.new(
			1,
			-150,
			0,
			16
		)

	--==================================================
	-- TITLE
	--==================================================

	local title =
		createTextLabel(
			main,
			"Title",
			titleText,
			Enum.Font.GothamBold,
			18,
			WHITE
		)

	title.Position =
		UDim2.fromOffset(
			87,
			27
		)

	title.Size =
		UDim2.new(
			1,
			-152,
			0,
			25
		)

	--==================================================
	-- SUBTITLE
	--==================================================

	local subtitle =
		createTextLabel(
			main,
			"Subtitle",
			subtitleText,
			Enum.Font.GothamMedium,
			12,
			MUTED
		)

	subtitle.Position =
		UDim2.fromOffset(
			87,
			52
		)

	subtitle.Size =
		UDim2.new(
			1,
			-155,
			0,
			20
		)

	subtitle.TextTruncate =
		Enum.TextTruncate.AtEnd

	--==================================================
	-- KEY BUTTON
	--==================================================

	local keyFrame =
		Instance.new(
			"Frame"
		)

	keyFrame.Name =
		"Key"

	keyFrame.AnchorPoint =
		Vector2.new(
			1,
			0.5
		)

	keyFrame.Position =
		UDim2.new(
			1,
			-14,
			0.5,
			0
		)

	keyFrame.Size =
		UDim2.fromOffset(
			48,
			48
		)

	keyFrame.BackgroundColor3 =
		accentColor

	keyFrame.BorderSizePixel =
		0

	keyFrame.Parent =
		main

	local keyCorner =
		Instance.new(
			"UICorner"
		)

	keyCorner.CornerRadius =
		UDim.new(
			0,
			12
		)

	keyCorner.Parent =
		keyFrame

	local keyStroke =
		Instance.new(
			"UIStroke"
		)

	keyStroke.Color =
		Color3.fromRGB(
			255,
			255,
			255
		)

	keyStroke.Transparency =
		0.65

	keyStroke.Thickness =
		1.5

	keyStroke.Parent =
		keyFrame

	local keyText =
		Instance.new(
			"TextLabel"
		)

	keyText.Name =
		"KeyText"

	keyText.Size =
		UDim2.fromScale(
			1,
			1
		)

	keyText.BackgroundTransparency =
		1

	keyText.Text =
		getKeyText(
			prompt,
			inputType
		)

	keyText.TextColor3 =
		Color3.fromRGB(
			28,
			24,
			18
		)

	keyText.TextSize =
		17

	keyText.Font =
		Enum.Font.GothamBold

	keyText.Parent =
		keyFrame

	--==================================================
	-- HOLD PROGRESS BACKGROUND
	--==================================================

	local progressBackground =
		Instance.new(
			"Frame"
		)

	progressBackground.Name =
		"ProgressBackground"

	progressBackground.AnchorPoint =
		Vector2.new(
			0,
			1
		)

	progressBackground.Position =
		UDim2.new(
			0,
			13,
			1,
			-5
		)

	progressBackground.Size =
		UDim2.new(
			1,
			-26,
			0,
			3
		)

	progressBackground.BackgroundColor3 =
		Color3.fromRGB(
			78,
			67,
			54
		)

	progressBackground.BackgroundTransparency =
		0.25

	progressBackground.BorderSizePixel =
		0

	progressBackground.Visible =
		prompt.HoldDuration > 0

	progressBackground.Parent =
		main

	local progressBackgroundCorner =
		Instance.new(
			"UICorner"
		)

	progressBackgroundCorner.CornerRadius =
		UDim.new(
			1,
			0
		)

	progressBackgroundCorner.Parent =
		progressBackground

	--==================================================
	-- HOLD PROGRESS
	--==================================================

	local progress =
		Instance.new(
			"Frame"
		)

	progress.Name =
		"Progress"

	progress.Size =
		UDim2.fromScale(
			0,
			1
		)

	progress.BackgroundColor3 =
		accentColor

	progress.BorderSizePixel =
		0

	progress.Parent =
		progressBackground

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
	-- OPEN ANIMATION
	--==================================================

	main.Size =
		UDim2.new(
			0.92,
			0,
			0.92,
			0
		)

	main.Position =
		UDim2.new(
			0.04,
			0,
			0.04,
			0
		)

	main.BackgroundTransparency =
		1

	TweenService:Create(
		main,
		TweenInfo.new(
			0.14,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Size =
				UDim2.fromScale(
					1,
					1
				),

			Position =
				UDim2.fromScale(
					0,
					0
				),

			BackgroundTransparency =
				0.06,
		}
	):Play()

	activePrompts[
		prompt
	] =
	{
		Gui = gui,
		Main = main,
		Progress = progress,
		ProgressTween = nil,
	}

	return gui

end

--==================================================
-- DESTROY PROMPT GUI
--==================================================

local function destroyPromptGui(
	prompt
)

	local data =
		activePrompts[
			prompt
		]

	if not data then
		return
	end

	if data.ProgressTween then

		data.ProgressTween:Cancel()

	end

	local gui =
		data.Gui

	local main =
		data.Main

	activePrompts[
		prompt
	] =
		nil

	if
		not gui
		or
		not gui.Parent
	then

		return

	end

	if
		main
		and
		main.Parent
	then

		local tween =
			TweenService:Create(
				main,
				TweenInfo.new(
					0.1,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.In
				),
				{
					Size =
						UDim2.new(
							0.9,
							0,
							0.9,
							0
						),

					Position =
						UDim2.new(
							0.05,
							0,
							0.05,
							0
						),

					BackgroundTransparency =
						1,
				}
			)

		tween:Play()

		task.delay(
			0.11,
			function()

				if gui then

					gui:Destroy()

				end

			end
		)

	else

		gui:Destroy()

	end

end

--==================================================
-- PROMPT SHOWN
--==================================================

ProximityPromptService.PromptShown:Connect(
	function(
		prompt,
		inputType
	)

		local promptType =
			getPromptType(
				prompt
			)

		if not promptType then
			return
		end

		stylePrompt(
			prompt
		)

		destroyPromptGui(
			prompt
		)

		createPromptGui(
			prompt,
			inputType
		)

	end
)

--==================================================
-- PROMPT HIDDEN
--==================================================

ProximityPromptService.PromptHidden:Connect(
	function(
		prompt
	)

		if
			not getPromptType(
				prompt
			)
		then

			return

		end

		destroyPromptGui(
			prompt
		)

	end
)

--==================================================
-- HOLD START
--==================================================

ProximityPromptService.PromptButtonHoldBegan:Connect(
	function(
		prompt
	)

		local data =
			activePrompts[
				prompt
			]

		if not data then
			return
		end

		if
			prompt.HoldDuration
			<=
			0
		then

			return

		end

		if data.ProgressTween then

			data.ProgressTween:Cancel()

		end

		data.Progress.Size =
			UDim2.fromScale(
				0,
				1
			)

		local tween =
			TweenService:Create(
				data.Progress,
				TweenInfo.new(
					prompt.HoldDuration,
					Enum.EasingStyle.Linear
				),
				{
					Size =
						UDim2.fromScale(
							1,
							1
						),
				}
			)

		data.ProgressTween =
			tween

		tween:Play()

	end
)

--==================================================
-- HOLD CANCEL / END
--==================================================

ProximityPromptService.PromptButtonHoldEnded:Connect(
	function(
		prompt
	)

		local data =
			activePrompts[
				prompt
			]

		if not data then
			return
		end

		if data.ProgressTween then

			data.ProgressTween:Cancel()

			data.ProgressTween =
				nil

		end

		if
			data.Progress
			and
			data.Progress.Parent
		then

			data.Progress.Size =
				UDim2.fromScale(
					0,
					1
				)

		end

	end
)

--==================================================
-- ACTION COMPLETED
--==================================================

ProximityPromptService.PromptTriggered:Connect(
	function(
		prompt
	)

		if
			not getPromptType(
				prompt
			)
		then

			return

		end

		playActionSound(
			prompt
		)

	end
)

--==================================================
-- EXISTING PROMPTS
--==================================================

for _, object in ipairs(
	Workspace:GetDescendants()
) do

	if
		object:IsA(
			"ProximityPrompt"
		)
	then

		stylePrompt(
			object
		)

	end

end

--==================================================
-- NEW PROMPTS
--==================================================

Workspace.DescendantAdded:Connect(
	function(
		object
	)

		if
			not object:IsA(
				"ProximityPrompt"
			)
		then

			return

		end

		task.defer(
			function()

				if object.Parent then

					stylePrompt(
						object
					)

				end

			end
		)

	end
)

print("")
print("========================================")
print("🥔 POTATIUM POTATO PROMPTS READY")
print("========================================")
print("✅ Custom Place Potato prompt")
print("✅ Custom Remove Potato prompt")
print("✅ E / R key badge")
print("✅ Hold progress animation")
print("✅ Place sound loaded")
print("✅ Remove sound loaded")
print("========================================")
print("")