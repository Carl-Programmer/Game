--==================================================
-- POTATIUM POTATO PROMPT VISUALS V3
--
-- CLEAN TEXT VERSION
--
-- PLACE  = PotatoPlacePrompt
-- REMOVE = RemovePotatoPrompt
--
-- VISUAL ONLY
-- Does not change gameplay or sounds.
--==================================================

local Players =
	game:GetService("Players")

local ProximityPromptService =
	game:GetService("ProximityPromptService")

local TweenService =
	game:GetService("TweenService")

local Workspace =
	game:GetService("Workspace")


local player =
	Players.LocalPlayer

local playerGui =
	player:WaitForChild("PlayerGui")

--==================================================
-- PROMPT NAMES
--==================================================

local PLACE_PROMPT_NAME =
	"PotatoPlacePrompt"

local REMOVE_PROMPT_NAME =
	"RemovePotatoPrompt"

--==================================================
-- SIZE
--==================================================

local PROMPT_WIDTH =
	235

local PROMPT_HEIGHT =
	60

local WORLD_OFFSET =
	Vector3.new(
		0,
		2.65,
		0
	)

--==================================================
-- COLORS
--==================================================

local BACKGROUND =
	Color3.fromRGB(
		43,
		30,
		20
	)

local INNER_BACKGROUND =
	Color3.fromRGB(
		61,
		42,
		27
	)

local BORDER =
	Color3.fromRGB(
		121,
		79,
		39
	)

local PLACE_COLOR =
	Color3.fromRGB(
		91,
		220,
		92
	)

local REMOVE_COLOR =
	Color3.fromRGB(
		255,
		167,
		55
	)

local MAIN_TEXT =
	Color3.fromRGB(
		255,
		248,
		232
	)

local SECONDARY_TEXT =
	Color3.fromRGB(
		205,
		190,
		165
	)

local KEY_TEXT =
	Color3.fromRGB(
		34,
		27,
		19
	)

--==================================================
-- ACTIVE UI
--==================================================

local activePrompts =
	{}

--==================================================
-- PROMPT TYPE
--==================================================

local function getPromptType(
	prompt
)

	if
		not prompt
		or
		not prompt:IsA(
			"ProximityPrompt"
		)
	then

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
-- CUSTOM STYLE
--==================================================

local function applyCustomStyle(
	prompt
)

	if not getPromptType(
		prompt
	) then

		return

	end


	prompt.Style =
		Enum.ProximityPromptStyle.Custom

end

--==================================================
-- ADORNEE
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
			"Attachment"
		)
	then

		return parent

	end


	if
		parent:IsA(
			"BasePart"
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
-- KEY TEXT
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

		local text =
			prompt.GamepadKeyCode.Name


		text =
			string.gsub(
				text,
				"Button",
				""
			)


		return text

	end


	return
		prompt.KeyboardKeyCode.Name

end

--==================================================
-- SUBTITLE
--==================================================

local function getSubtitle(
	prompt,
	promptType
)

	local objectText =
		tostring(
			prompt.ObjectText
				or
				""
		)


	if
		promptType
		==
		"PLACE"
	then

		local plotNumber =
			string.match(
				objectText,
				"FarmLand_(%d+)"
			)


		if plotNumber then

			return
				"PLOT "
				..
				tostring(
					tonumber(
						plotNumber
					)
					or
					plotNumber
				)

		end


		if objectText ~= "" then

			return
				string.upper(
					objectText
				)

		end


		return "FARM PLOT"

	end


	if objectText ~= "" then

		return objectText

	end


	return "POTATO"

end

--==================================================
-- UI HELPERS
--==================================================

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


	stroke.Transparency =
		transparency


	stroke.Parent =
		object


	return stroke

end


local function createText(
	parent,
	name,
	text,
	textSize,
	font,
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


	label.BorderSizePixel =
		0


	label.Text =
		text


	label.TextSize =
		textSize


	label.Font =
		font


	label.TextColor3 =
		color


	label.TextXAlignment =
		Enum.TextXAlignment.Left


	label.TextYAlignment =
		Enum.TextYAlignment.Center


	label.TextWrapped =
		false


	label.AutoLocalize =
		false


	-- Slight shadow makes text much clearer.
	label.TextStrokeColor3 =
		Color3.fromRGB(
			20,
			14,
			9
		)


	label.TextStrokeTransparency =
		0.72


	label.Parent =
		parent


	return label

end

--==================================================
-- DESTROY UI
--==================================================

local function destroyPromptUI(
	prompt
)

	local information =
		activePrompts[
			prompt
		]


	if not information then

		return

	end


	activePrompts[
		prompt
	] =
		nil


	if information.ProgressTween then

		information.ProgressTween:Cancel()

	end


	if
		information.Gui
		and
		information.Gui.Parent
	then

		information.Gui:Destroy()

	end

end

--==================================================
-- CREATE UI
--==================================================

local function createPromptUI(
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


	destroyPromptUI(
		prompt
	)


	local adornee =
		getAdornee(
			prompt
		)


	if not adornee then

		return

	end


	local isPlace =
		promptType
		==
		"PLACE"


	local accentColor


	local title


	if isPlace then

		accentColor =
			PLACE_COLOR


		title =
			"PLACE POTATO"

	else

		accentColor =
			REMOVE_COLOR


		title =
			"REMOVE POTATO"

	end


	local subtitle =
		getSubtitle(
			prompt,
			promptType
		)


	local keyText =
		getKeyText(
			prompt,
			inputType
		)

	--==================================================
	-- BILLBOARD
	--==================================================

	local gui =
		Instance.new(
			"BillboardGui"
		)


	gui.Name =
		"PotatiumPrompt"


	gui.Adornee =
		adornee


	gui.Size =
		UDim2.fromOffset(
			PROMPT_WIDTH,
			PROMPT_HEIGHT
		)


	gui.StudsOffsetWorldSpace =
		WORLD_OFFSET


	gui.AlwaysOnTop =
		true


	gui.LightInfluence =
		0


	gui.ResetOnSpawn =
		false


	gui.ClipsDescendants =
		false


	gui.Parent =
		playerGui

	--==================================================
	-- SHADOW
	--==================================================

	local shadow =
		Instance.new(
			"Frame"
		)


	shadow.Name =
		"Shadow"


	shadow.Position =
		UDim2.fromOffset(
			2,
			3
		)


	shadow.Size =
		UDim2.fromScale(
			1,
			1
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
		1


	shadow.Parent =
		gui


	addCorner(
		shadow,
		12
	)

	--==================================================
	-- MAIN
	--==================================================

	local main =
		Instance.new(
			"Frame"
		)


	main.Name =
		"Main"


	main.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)


	main.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)


	main.Size =
		UDim2.fromScale(
			1,
			1
		)


	main.BackgroundColor3 =
		BACKGROUND


	main.BorderSizePixel =
		0


	main.ZIndex =
		2


	main.Parent =
		gui


	addCorner(
		main,
		12
	)


	addStroke(
		main,
		BORDER,
		2,
		0.05
	)

	--==================================================
	-- INNER CARD
	--==================================================

	local inner =
		Instance.new(
			"Frame"
		)


	inner.Name =
		"Inner"


	inner.Position =
		UDim2.fromOffset(
			4,
			4
		)


	inner.Size =
		UDim2.new(
			1,
			-8,
			1,
			-8
		)


	inner.BackgroundColor3 =
		INNER_BACKGROUND


	inner.BorderSizePixel =
		0


	inner.ZIndex =
		3


	inner.Parent =
		main


	addCorner(
		inner,
		9
	)

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
			5,
			8
		)


	accent.Size =
		UDim2.new(
			0,
			4,
			1,
			-16
		)


	accent.BackgroundColor3 =
		accentColor


	accent.BorderSizePixel =
		0


	accent.ZIndex =
		5


	accent.Parent =
		inner


	addCorner(
		accent,
		4
	)

	--==================================================
	-- BRAND
	--==================================================

	local brand =
		createText(
			inner,
			"Brand",
			"POTATIUM",
			9,
			Enum.Font.GothamBold,
			accentColor
		)


	brand.Position =
		UDim2.fromOffset(
			18,
			4
		)


	brand.Size =
		UDim2.new(
			1,
			-72,
			0,
			13
		)


	brand.ZIndex =
		5

	--==================================================
	-- MAIN TITLE
	--
	-- LOTS MORE WIDTH THAN BEFORE.
	--==================================================

	local titleLabel =
		createText(
			inner,
			"Title",
			title,
			16,
			Enum.Font.GothamBold,
			MAIN_TEXT
		)


	titleLabel.Position =
		UDim2.fromOffset(
			18,
			16
		)


	titleLabel.Size =
		UDim2.new(
			1,
			-72,
			0,
			20
		)


	titleLabel.TextTruncate =
		Enum.TextTruncate.AtEnd


	titleLabel.ZIndex =
		5

	--==================================================
	-- SUBTITLE
	--==================================================

	local subtitleLabel =
		createText(
			inner,
			"Subtitle",
			subtitle,
			11,
			Enum.Font.GothamMedium,
			SECONDARY_TEXT
		)


	subtitleLabel.Position =
		UDim2.fromOffset(
			18,
			35
		)


	subtitleLabel.Size =
		UDim2.new(
			1,
			-72,
			0,
			14
		)


	subtitleLabel.TextTruncate =
		Enum.TextTruncate.AtEnd


	subtitleLabel.ZIndex =
		5

	--==================================================
	-- KEY BUTTON
	--==================================================

	local key =
		Instance.new(
			"Frame"
		)


	key.Name =
		"Key"


	key.AnchorPoint =
		Vector2.new(
			1,
			0.5
		)


	key.Position =
		UDim2.new(
			1,
			-8,
			0.5,
			0
		)


	key.Size =
		UDim2.fromOffset(
			38,
			38
		)


	key.BackgroundColor3 =
		accentColor


	key.BorderSizePixel =
		0


	key.ZIndex =
		6


	key.Parent =
		inner


	addCorner(
		key,
		9
	)


	addStroke(
		key,
		Color3.fromRGB(
			255,
			255,
			255
		),
		1,
		0.55
	)

	--==================================================
	-- KEY LETTER
	--==================================================

	local keyLabel =
		Instance.new(
			"TextLabel"
		)


	keyLabel.Name =
		"KeyText"


	keyLabel.Size =
		UDim2.fromScale(
			1,
			1
		)


	keyLabel.BackgroundTransparency =
		1


	keyLabel.Text =
		keyText


	keyLabel.TextColor3 =
		KEY_TEXT


	keyLabel.TextSize =
		keyText == "TAP"
		and
		10
		or
		15


	keyLabel.Font =
		Enum.Font.GothamBold


	keyLabel.AutoLocalize =
		false


	keyLabel.ZIndex =
		7


	keyLabel.Parent =
		key

	--==================================================
	-- HOLD BAR BACKGROUND
	--==================================================

	local progressBack =
		Instance.new(
			"Frame"
		)


	progressBack.Name =
		"ProgressBack"


	progressBack.Position =
		UDim2.new(
			0,
			18,
			1,
			-4
		)


	progressBack.Size =
		UDim2.new(
			1,
			-72,
			0,
			2
		)


	progressBack.BackgroundColor3 =
		Color3.fromRGB(
			29,
			20,
			14
		)


	progressBack.BorderSizePixel =
		0


	progressBack.Visible =
		prompt.HoldDuration
		>
		0


	progressBack.ZIndex =
		8


	progressBack.Parent =
		inner


	addCorner(
		progressBack,
		2
	)

	--==================================================
	-- HOLD BAR
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


	progress.ZIndex =
		9


	progress.Parent =
		progressBack


	addCorner(
		progress,
		2
	)

	--==================================================
	-- OPEN ANIMATION
	--==================================================

	main.Size =
		UDim2.fromScale(
			0.94,
			0.94
		)


	main.BackgroundTransparency =
		0.4


	TweenService:Create(
		main,

		TweenInfo.new(
			0.12,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),

		{

			Size =
				UDim2.fromScale(
					1,
					1
				),

			BackgroundTransparency =
				0,

		}

	):Play()

	--==================================================
	-- STORE
	--==================================================

	activePrompts[
		prompt
	] = {

		Gui =
			gui,

		Progress =
			progress,

		ProgressTween =
			nil,

	}

end

--==================================================
-- HOLD START
--==================================================

local function startHold(
	prompt
)

	local information =
		activePrompts[
			prompt
		]


	if not information then

		return

	end


	if
		prompt.HoldDuration
		<=
		0
	then

		return

	end


	if information.ProgressTween then

		information.ProgressTween:Cancel()

	end


	information.Progress.Size =
		UDim2.fromScale(
			0,
			1
		)


	local tween =
		TweenService:Create(
			information.Progress,

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


	information.ProgressTween =
		tween


	tween:Play()

end

--==================================================
-- HOLD END
--==================================================

local function endHold(
	prompt
)

	local information =
		activePrompts[
			prompt
		]


	if not information then

		return

	end


	if information.ProgressTween then

		information.ProgressTween:Cancel()


		information.ProgressTween =
			nil

	end


	if
		information.Progress
		and
		information.Progress.Parent
	then

		information.Progress.Size =
			UDim2.fromScale(
				0,
				1
			)

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

		if not getPromptType(
			prompt
		) then

			return

		end


		applyCustomStyle(
			prompt
		)


		createPromptUI(
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

		if not getPromptType(
			prompt
		) then

			return

		end


		destroyPromptUI(
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

		if not getPromptType(
			prompt
		) then

			return

		end


		startHold(
			prompt
		)

	end
)

--==================================================
-- HOLD END
--==================================================

ProximityPromptService.PromptButtonHoldEnded:Connect(
	function(
		prompt
	)

		if not getPromptType(
			prompt
		) then

			return

		end


		endHold(
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

		applyCustomStyle(
			object
		)

	end

end

--==================================================
-- FUTURE PROMPTS
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


		applyCustomStyle(
			object
		)

	end
)

--==================================================
-- REMOVED PROMPTS
--==================================================

Workspace.DescendantRemoving:Connect(
	function(
		object
	)

		if
			activePrompts[
				object
			]
		then

			destroyPromptUI(
				object
			)

		end

	end
)

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("POTATIUM PROMPT VISUAL V3 READY")
print("========================================")
print("Place = PLACE POTATO")
print("Remove = REMOVE POTATO")
print("No icons / emojis")
print("Clearer text")
print("More title space")
print("Compact UI")
print("Sounds untouched")
print("Foraging untouched")
print("========================================")
print("")