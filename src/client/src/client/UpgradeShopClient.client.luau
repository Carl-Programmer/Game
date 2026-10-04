--========================================================
-- POTATIUM - UPGRADE SHOP CLIENT V3
--
-- SAME WINDOW SIZE AS V2: 680 x 345
--
-- ✅ Polished human-made layout
-- ✅ Clear typography / spacing
-- ✅ Navy + cream + cyan + copper palette
-- ✅ Subtle pattern details
-- ✅ BUY 1 / BUY 10 unchanged
-- ✅ Cash updates live
-- ✅ Hotbar hidden while shop is open
-- ✅ Third-person mouse restores correctly
--========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes =
	ReplicatedStorage:WaitForChild(
		"PotatiumUpgradeShopRemotes"
	)

local openShop =
	remotes:WaitForChild(
		"OpenShop"
	)

local buyCrates =
	remotes:WaitForChild(
		"BuyCrates"
	)

local purchaseResult =
	remotes:WaitForChild(
		"PurchaseResult"
	)

--========================================================
-- STATE
--========================================================

local currentPrice = 500
local shopOpen = false
local purchaseBusy = false

local openedFromFirstPerson = false
local previousMouseIconEnabled = true
local previousBackpackCoreGuiEnabled = true

--========================================================
-- COLOURS
--========================================================

local COLORS = {
	Overlay = Color3.fromRGB(6, 9, 14),

	Window = Color3.fromRGB(15, 22, 31),
	Header = Color3.fromRGB(20, 31, 43),
	Header2 = Color3.fromRGB(13, 21, 30),

	Card = Color3.fromRGB(22, 32, 43),
	Card2 = Color3.fromRGB(18, 27, 37),
	Inner = Color3.fromRGB(13, 20, 28),

	Text = Color3.fromRGB(244, 247, 250),
	SubText = Color3.fromRGB(172, 188, 201),
	Muted = Color3.fromRGB(112, 132, 148),

	Cyan = Color3.fromRGB(87, 183, 210),
	CyanSoft = Color3.fromRGB(55, 113, 136),

	Copper = Color3.fromRGB(205, 133, 65),
	CopperBright = Color3.fromRGB(243, 174, 93),
	Cream = Color3.fromRGB(244, 232, 209),

	Wood = Color3.fromRGB(173, 112, 56),
	Stone = Color3.fromRGB(128, 140, 151),
	Iron = Color3.fromRGB(192, 202, 211),

	Green = Color3.fromRGB(91, 190, 131),
	Red = Color3.fromRGB(228, 88, 84),

	Button = Color3.fromRGB(31, 48, 62),
	ButtonHover = Color3.fromRGB(42, 65, 82),
	Button10 = Color3.fromRGB(154, 93, 48),
	Button10Hover = Color3.fromRGB(180, 108, 54),
}

--========================================================
-- HELPERS
--========================================================

local function addCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
	return corner
end

local function addStroke(object, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = object
	return stroke
end

local function addGradient(object, first, second, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, first),
		ColorSequenceKeypoint.new(1, second),
	})
	gradient.Rotation = rotation or 90
	gradient.Parent = object
	return gradient
end

local function makeLabel(
	parent,
	text,
	textSize,
	font,
	color
)
	local label = Instance.new("TextLabel")

	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextSize = textSize or 14
	label.Font = font or Enum.Font.Gotham
	label.TextColor3 = color or COLORS.Text
	label.TextWrapped = false
	label.Parent = parent

	return label
end

local function makeButton(
	parent,
	text,
	background
)
	local button = Instance.new("TextButton")

	button.AutoButtonColor = false
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.TextColor3 = COLORS.Text
	button.BackgroundColor3 =
		background
		or
		COLORS.Button
	button.BorderSizePixel = 0
	button.Parent = parent

	addCorner(
		button,
		8
	)

	return button
end

local function formatMoney(amount)
	amount =
		math.floor(
			tonumber(amount)
			or
			0
		)

	local text =
		tostring(amount)

	while true do
		local newText,
			count =
				string.gsub(
					text,
					"^(-?%d+)(%d%d%d)",
					"%1,%2"
				)

		text = newText

		if count == 0 then
			break
		end
	end

	return "$" .. text
end

local function cameraIsFirstPerson()
	local camera =
		Workspace.CurrentCamera

	if not camera then
		return false
	end

	local distance =
		(
			camera.Focus.Position
			-
			camera.CFrame.Position
		).Magnitude

	return distance < 1.1
end

local function setCoreBackpackEnabled(enabled)
	pcall(
		function()
			StarterGui:SetCoreGuiEnabled(
				Enum.CoreGuiType.Backpack,
				enabled
			)
		end
	)
end

local function getCoreBackpackEnabled()
	local enabled = true

	pcall(
		function()
			enabled =
				StarterGui:GetCoreGuiEnabled(
					Enum.CoreGuiType.Backpack
				)
		end
	)

	return enabled
end

local function addDiagonalPattern(
	parent,
	startX,
	endX
)
	for x = startX, endX, 22 do
		local line =
			Instance.new("Frame")

		line.Size =
			UDim2.fromOffset(
				36,
				2
			)

		line.Position =
			UDim2.fromOffset(
				x,
				15
			)

		line.Rotation =
			-24

		line.BackgroundColor3 =
			COLORS.Cyan

		line.BackgroundTransparency =
			0.90

		line.BorderSizePixel =
			0

		line.Parent =
			parent
	end
end

--========================================================
-- OLD COPY
--========================================================

local oldGui =
	playerGui:FindFirstChild(
		"UpgradeShopGui"
	)

if oldGui then
	oldGui:Destroy()
end

--========================================================
-- GUI ROOT
--========================================================

local gui = Instance.new("ScreenGui")
gui.Name = "UpgradeShopGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 90
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = COLORS.Overlay
overlay.BackgroundTransparency = 0.52
overlay.BorderSizePixel = 0
overlay.Parent = gui

--========================================================
-- MAIN WINDOW
-- SAME SIZE: 680 x 345
--========================================================

local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 7, 0.49, 8)
shadow.Size = UDim2.fromOffset(680, 345)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.46
shadow.BorderSizePixel = 0
shadow.Parent = overlay
addCorner(shadow, 13)

local window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.49)
window.Size = UDim2.fromOffset(680, 345)
window.BackgroundColor3 = COLORS.Window
window.BorderSizePixel = 0
window.ClipsDescendants = true
window.Parent = overlay

addCorner(window, 13)
addStroke(window, COLORS.Cyan, 1.4, 0.18)
addGradient(
	window,
	Color3.fromRGB(18, 29, 40),
	Color3.fromRGB(10, 16, 23),
	90
)

--========================================================
-- HEADER
--========================================================

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.ClipsDescendants = true
header.Parent = window

addGradient(
	header,
	COLORS.Header,
	COLORS.Header2,
	0
)

addDiagonalPattern(
	header,
	380,
	565
)

local titleAccent = Instance.new("Frame")
titleAccent.Position = UDim2.fromOffset(18, 16)
titleAccent.Size = UDim2.fromOffset(4, 29)
titleAccent.BackgroundColor3 = COLORS.CopperBright
titleAccent.BorderSizePixel = 0
titleAccent.Parent = header
addCorner(titleAccent, 2)

local title = makeLabel(
	header,
	"UPGRADE SHOP",
	20,
	Enum.Font.GothamBlack,
	COLORS.Text
)
title.Position = UDim2.fromOffset(32, 8)
title.Size = UDim2.fromOffset(240, 28)
title.TextXAlignment = Enum.TextXAlignment.Left

local subtitle = makeLabel(
	header,
	"CRATE MARKET  /  EQUIPMENT",
	9,
	Enum.Font.GothamBold,
	COLORS.Cyan
)
subtitle.Position = UDim2.fromOffset(33, 35)
subtitle.Size = UDim2.fromOffset(230, 16)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local cashPanel = Instance.new("Frame")
cashPanel.AnchorPoint = Vector2.new(1, 0.5)
cashPanel.Position = UDim2.new(1, -58, 0.5, 0)
cashPanel.Size = UDim2.fromOffset(175, 36)
cashPanel.BackgroundColor3 = Color3.fromRGB(10, 18, 25)
cashPanel.BorderSizePixel = 0
cashPanel.Parent = header
addCorner(cashPanel, 8)
addStroke(cashPanel, COLORS.CyanSoft, 1, 0.25)

local cashTiny = makeLabel(
	cashPanel,
	"CASH",
	8,
	Enum.Font.GothamBold,
	COLORS.Muted
)
cashTiny.Position = UDim2.fromOffset(12, 4)
cashTiny.Size = UDim2.fromOffset(48, 12)
cashTiny.TextXAlignment = Enum.TextXAlignment.Left

local cashText = makeLabel(
	cashPanel,
	"$0",
	13,
	Enum.Font.GothamBold,
	COLORS.Text
)
cashText.Position = UDim2.fromOffset(12, 14)
cashText.Size = UDim2.new(1, -24, 0, 18)
cashText.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = makeButton(
	header,
	"X",
	Color3.fromRGB(46, 58, 68)
)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -13, 0.5, 0)
closeButton.Size = UDim2.fromOffset(32, 32)
closeButton.TextSize = 12

local headerLine = Instance.new("Frame")
headerLine.Position = UDim2.new(0, 18, 1, -2)
headerLine.Size = UDim2.new(1, -36, 0, 2)
headerLine.BackgroundColor3 = COLORS.Copper
headerLine.BorderSizePixel = 0
headerLine.Parent = header

--========================================================
-- CONTENT CARD
--========================================================

local card = Instance.new("Frame")
card.Name = "WoodenCrateCard"
card.Position = UDim2.fromOffset(18, 76)
card.Size = UDim2.new(1, -36, 0, 224)
card.BackgroundColor3 = COLORS.Card
card.BorderSizePixel = 0
card.Parent = window
addCorner(card, 11)
addStroke(card, Color3.fromRGB(66, 91, 108), 1, 0.22)
addGradient(
	card,
	Color3.fromRGB(25, 37, 49),
	Color3.fromRGB(17, 26, 35),
	90
)

-- top micro-line
local microLine = Instance.new("Frame")
microLine.Position = UDim2.fromOffset(16, 10)
microLine.Size = UDim2.new(1, -32, 0, 1)
microLine.BackgroundColor3 = COLORS.Cyan
microLine.BackgroundTransparency = 0.74
microLine.BorderSizePixel = 0
microLine.Parent = card

--========================================================
-- PREVIEW
--========================================================

local preview = Instance.new("Frame")
preview.Position = UDim2.fromOffset(18, 21)
preview.Size = UDim2.fromOffset(126, 128)
preview.BackgroundColor3 = COLORS.Inner
preview.BorderSizePixel = 0
preview.Parent = card
addCorner(preview, 9)
addStroke(preview, COLORS.Copper, 1.3, 0.12)

local previewTop = Instance.new("Frame")
previewTop.Size = UDim2.new(1, 0, 0, 25)
previewTop.BackgroundColor3 = Color3.fromRGB(28, 39, 48)
previewTop.BorderSizePixel = 0
previewTop.Parent = preview
addCorner(previewTop, 9)

local previewTopFill = Instance.new("Frame")
previewTopFill.Position = UDim2.new(0, 0, 1, -8)
previewTopFill.Size = UDim2.new(1, 0, 0, 8)
previewTopFill.BackgroundColor3 = Color3.fromRGB(28, 39, 48)
previewTopFill.BorderSizePixel = 0
previewTopFill.Parent = previewTop

local previewTag = makeLabel(
	previewTop,
	"ITEM PREVIEW",
	8,
	Enum.Font.GothamBold,
	COLORS.Cyan
)
previewTag.Size = UDim2.fromScale(1, 1)

local crateGlyph = makeLabel(
	preview,
	"WOODEN\nCRATE",
	15,
	Enum.Font.GothamBlack,
	COLORS.CopperBright
)
crateGlyph.Position = UDim2.fromOffset(8, 36)
crateGlyph.Size = UDim2.new(1, -16, 0, 62)
crateGlyph.TextWrapped = true

local artHint = makeLabel(
	preview,
	"ART SLOT",
	8,
	Enum.Font.GothamBold,
	COLORS.Muted
)
artHint.Position = UDim2.new(0, 0, 1, -23)
artHint.Size = UDim2.new(1, 0, 0, 15)

--========================================================
-- TEXT BLOCK
--========================================================

local crateName = makeLabel(
	card,
	"WOODEN CRATE",
	19,
	Enum.Font.GothamBlack,
	COLORS.Text
)
crateName.Position = UDim2.fromOffset(164, 18)
crateName.Size = UDim2.fromOffset(300, 27)
crateName.TextXAlignment = Enum.TextXAlignment.Left

local description = makeLabel(
	card,
	"Keep it in your Backpack. Open it whenever you want.",
	11,
	Enum.Font.GothamMedium,
	COLORS.SubText
)
description.Position = UDim2.fromOffset(164, 46)
description.Size = UDim2.fromOffset(362, 19)
description.TextXAlignment = Enum.TextXAlignment.Left

local priceChip = Instance.new("Frame")
priceChip.AnchorPoint = Vector2.new(1, 0)
priceChip.Position = UDim2.new(1, -19, 0, 18)
priceChip.Size = UDim2.fromOffset(112, 42)
priceChip.BackgroundColor3 = Color3.fromRGB(31, 28, 25)
priceChip.BorderSizePixel = 0
priceChip.Parent = card
addCorner(priceChip, 8)
addStroke(priceChip, COLORS.Copper, 1, 0.28)

local priceSmall = makeLabel(
	priceChip,
	"PRICE",
	8,
	Enum.Font.GothamBold,
	COLORS.Muted
)
priceSmall.Position = UDim2.fromOffset(8, 4)
priceSmall.Size = UDim2.new(1, -16, 0, 11)
priceSmall.TextXAlignment = Enum.TextXAlignment.Right

local basePriceText = makeLabel(
	priceChip,
	"$500 EACH",
	13,
	Enum.Font.GothamBold,
	COLORS.CopperBright
)
basePriceText.Position = UDim2.fromOffset(8, 16)
basePriceText.Size = UDim2.new(1, -16, 0, 18)
basePriceText.TextXAlignment = Enum.TextXAlignment.Right

local dropTitle = makeLabel(
	card,
	"DROP CHANCES",
	9,
	Enum.Font.GothamBold,
	COLORS.Cyan
)
dropTitle.Position = UDim2.fromOffset(164, 75)
dropTitle.Size = UDim2.fromOffset(120, 16)
dropTitle.TextXAlignment = Enum.TextXAlignment.Left

local dropLine = Instance.new("Frame")
dropLine.Position = UDim2.fromOffset(265, 83)
dropLine.Size = UDim2.new(1, -285, 0, 1)
dropLine.BackgroundColor3 = COLORS.CyanSoft
dropLine.BackgroundTransparency = 0.55
dropLine.BorderSizePixel = 0
dropLine.Parent = card

local function makeDropTile(
	x,
	titleText,
	gradeText,
	chanceText,
	accent
)
	local tile = Instance.new("Frame")
	tile.Position = UDim2.fromOffset(x, 98)
	tile.Size = UDim2.fromOffset(126, 54)
	tile.BackgroundColor3 = COLORS.Inner
	tile.BorderSizePixel = 0
	tile.Parent = card
	addCorner(tile, 8)
	addStroke(tile, accent, 1, 0.18)

	local marker = Instance.new("Frame")
	marker.Position = UDim2.fromOffset(7, 7)
	marker.Size = UDim2.fromOffset(3, 40)
	marker.BackgroundColor3 = accent
	marker.BorderSizePixel = 0
	marker.Parent = tile
	addCorner(marker, 2)

	local name = makeLabel(
		tile,
		titleText,
		9,
		Enum.Font.GothamBold,
		COLORS.Text
	)
	name.Position = UDim2.fromOffset(17, 6)
	name.Size = UDim2.new(1, -22, 0, 15)
	name.TextXAlignment = Enum.TextXAlignment.Left

	local grade = makeLabel(
		tile,
		gradeText,
		8,
		Enum.Font.GothamBold,
		COLORS.Muted
	)
	grade.Position = UDim2.fromOffset(17, 20)
	grade.Size = UDim2.fromOffset(60, 13)
	grade.TextXAlignment = Enum.TextXAlignment.Left

	local chance = makeLabel(
		tile,
		chanceText,
		13,
		Enum.Font.GothamBlack,
		accent
	)
	chance.Position = UDim2.fromOffset(17, 34)
	chance.Size = UDim2.new(1, -22, 0, 16)
	chance.TextXAlignment = Enum.TextXAlignment.Left

	return chance
end

local woodenRate = makeDropTile(
	164,
	"WOODEN HOE",
	"COMMON",
	"75%",
	COLORS.CopperBright
)

local stoneRate = makeDropTile(
	299,
	"STONE HOE",
	"RARE",
	"20%",
	COLORS.Stone
)

local ironRate = makeDropTile(
	434,
	"IRON HOE",
	"EPIC",
	"5%",
	COLORS.Iron
)

--========================================================
-- BUY BAR
--========================================================

local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(164, 164)
divider.Size = UDim2.new(1, -183, 0, 1)
divider.BackgroundColor3 = Color3.fromRGB(69, 91, 107)
divider.BackgroundTransparency = 0.35
divider.BorderSizePixel = 0
divider.Parent = card

local buyLabel = makeLabel(
	card,
	"PURCHASE",
	8,
	Enum.Font.GothamBold,
	COLORS.Muted
)
buyLabel.Position = UDim2.fromOffset(164, 173)
buyLabel.Size = UDim2.fromOffset(68, 13)
buyLabel.TextXAlignment = Enum.TextXAlignment.Left

local buy1Button = makeButton(
	card,
	"BUY 1",
	COLORS.Button
)
buy1Button.Position = UDim2.fromOffset(236, 171)
buy1Button.Size = UDim2.fromOffset(112, 37)

local buy1Price = makeLabel(
	card,
	"$500",
	12,
	Enum.Font.GothamBold,
	COLORS.CopperBright
)
buy1Price.Position = UDim2.fromOffset(357, 171)
buy1Price.Size = UDim2.fromOffset(70, 37)
buy1Price.TextXAlignment = Enum.TextXAlignment.Left

local buy10Button = makeButton(
	card,
	"BUY 10",
	COLORS.Button10
)
buy10Button.Position = UDim2.fromOffset(435, 171)
buy10Button.Size = UDim2.fromOffset(112, 37)

local buy10Price = makeLabel(
	card,
	"$5,000",
	12,
	Enum.Font.GothamBold,
	COLORS.CopperBright
)
buy10Price.Position = UDim2.fromOffset(556, 171)
buy10Price.Size = UDim2.fromOffset(70, 37)
buy10Price.TextXAlignment = Enum.TextXAlignment.Left

--========================================================
-- STATUS
--========================================================

local statusText = makeLabel(
	window,
	"",
	10,
	Enum.Font.GothamBold,
	COLORS.SubText
)
statusText.Position = UDim2.fromOffset(20, 307)
statusText.Size = UDim2.new(1, -40, 0, 24)
statusText.TextXAlignment = Enum.TextXAlignment.Center

--========================================================
-- HOVER
--========================================================

local function addHover(
	buttonObject,
	normalColor,
	hoverColor
)
	buttonObject.MouseEnter:Connect(
		function()
			if purchaseBusy then
				return
			end

			TweenService:Create(
				buttonObject,
				TweenInfo.new(0.08),
				{
					BackgroundColor3 =
						hoverColor
				}
			):Play()
		end
	)

	buttonObject.MouseLeave:Connect(
		function()
			TweenService:Create(
				buttonObject,
				TweenInfo.new(0.08),
				{
					BackgroundColor3 =
						normalColor
				}
			):Play()
		end
	)
end

addHover(
	buy1Button,
	COLORS.Button,
	COLORS.ButtonHover
)

addHover(
	buy10Button,
	COLORS.Button10,
	COLORS.Button10Hover
)

addHover(
	closeButton,
	Color3.fromRGB(46, 58, 68),
	Color3.fromRGB(82, 58, 58)
)

--========================================================
-- LIVE MONEY
--========================================================

local function getCash()
	return
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
end

local function updateMoneyDisplay()
	local cash =
		getCash()

	local onePrice =
		currentPrice

	local tenPrice =
		currentPrice * 10

	cashText.Text =
		formatMoney(
			cash
		)

	basePriceText.Text =
		formatMoney(
			currentPrice
		)
		..
		" EACH"

	buy1Price.Text =
		formatMoney(
			onePrice
		)

	buy10Price.Text =
		formatMoney(
			tenPrice
		)

	buy1Button.TextTransparency =
		cash >= onePrice
		and
		0
		or
		0.45

	buy10Button.TextTransparency =
		cash >= tenPrice
		and
		0
		or
		0.45
end

player:GetAttributeChangedSignal(
	"Cash"
):Connect(
	updateMoneyDisplay
)

--========================================================
-- MOUSE RESTORE
--========================================================

local function restoreGameplayMouse()
	local shouldLock =
		openedFromFirstPerson

	UserInputService.MouseBehavior =
		shouldLock
		and
		Enum.MouseBehavior.LockCenter
		or
		Enum.MouseBehavior.Default

	UserInputService.MouseIconEnabled =
		shouldLock
		and
		false
		or
		previousMouseIconEnabled

	task.delay(
		0.08,
		function()
			if shopOpen then
				return
			end

			UserInputService.MouseBehavior =
				shouldLock
				and
				Enum.MouseBehavior.LockCenter
				or
				Enum.MouseBehavior.Default

			UserInputService.MouseIconEnabled =
				shouldLock
				and
				false
				or
				previousMouseIconEnabled
		end
	)
end

--========================================================
-- OPEN / CLOSE
--========================================================

local function closeGui()
	if not shopOpen then
		return
	end

	shopOpen = false
	purchaseBusy = false

	gui.Enabled = false

	setCoreBackpackEnabled(
		previousBackpackCoreGuiEnabled
	)

	restoreGameplayMouse()
end

local function openGui(payload)
	if type(payload) == "table" then
		currentPrice =
			tonumber(
				payload.Price
			)
			or
			currentPrice

		crateName.Text =
			string.upper(
				tostring(
					payload.Name
					or
					"Wooden Crate"
				)
			)

		if type(payload.Drops) == "table" then
			for _, drop in ipairs(
				payload.Drops
			) do
				local dropName =
					tostring(
						drop.Name
						or
						""
					)

				local chance =
					tostring(
						tonumber(
							drop.Chance
						)
						or
						0
					)
					..
					"%"

				if dropName == "Wooden Hoe" then
					woodenRate.Text = chance
				elseif dropName == "Stone Hoe" then
					stoneRate.Text = chance
				elseif dropName == "Iron Hoe" then
					ironRate.Text = chance
				end
			end
		end
	end

	openedFromFirstPerson =
		cameraIsFirstPerson()

	previousMouseIconEnabled =
		UserInputService.MouseIconEnabled

	previousBackpackCoreGuiEnabled =
		getCoreBackpackEnabled()

	shopOpen = true
	purchaseBusy = false

	statusText.Text = ""

	setCoreBackpackEnabled(false)

	gui.Enabled = true

	UserInputService.MouseBehavior =
		Enum.MouseBehavior.Default

	UserInputService.MouseIconEnabled =
		true

	updateMoneyDisplay()

	-- Same final size. Small entry tween only.
	window.Size =
		UDim2.fromOffset(
			660,
			335
		)

	window.BackgroundTransparency =
		0.06

	TweenService:Create(
		window,
		TweenInfo.new(
			0.12,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			Size =
				UDim2.fromOffset(
					680,
					345
				),

			BackgroundTransparency =
				0,
		}
	):Play()
end

closeButton.MouseButton1Click:Connect(
	closeGui
)

UserInputService.InputBegan:Connect(
	function(
		input,
		gameProcessed
	)
		if
			shopOpen
			and
			input.KeyCode
			==
			Enum.KeyCode.Escape
		then
			closeGui()
		end
	end
)

--========================================================
-- PURCHASE
--========================================================

local function requestBuy(amount)
	if purchaseBusy then
		return
	end

	purchaseBusy = true

	statusText.Text =
		"PROCESSING PURCHASE..."

	statusText.TextColor3 =
		COLORS.SubText

	buyCrates:FireServer(
		"Wooden",
		amount
	)

	task.delay(
		3,
		function()
			if purchaseBusy then
				purchaseBusy = false

				statusText.Text =
					"Purchase timed out. Try again."

				statusText.TextColor3 =
					COLORS.Red
			end
		end
	)
end

buy1Button.MouseButton1Click:Connect(
	function()
		requestBuy(1)
	end
)

buy10Button.MouseButton1Click:Connect(
	function()
		requestBuy(10)
	end
)

--========================================================
-- SERVER EVENTS
--========================================================

openShop.OnClientEvent:Connect(
	openGui
)

purchaseResult.OnClientEvent:Connect(
	function(
		success,
		message,
		amount,
		price
	)
		purchaseBusy = false

		if tonumber(price) then
			currentPrice =
				tonumber(price)
		end

		statusText.Text =
			tostring(
				message
				or
				""
			)

		statusText.TextColor3 =
			success
			and
			COLORS.Green
			or
			COLORS.Red

		updateMoneyDisplay()

		if success then
			local original =
				card.BackgroundColor3

			TweenService:Create(
				card,
				TweenInfo.new(0.08),
				{
					BackgroundColor3 =
						Color3.fromRGB(
							27,
							56,
							47
						)
				}
			):Play()

			task.delay(
				0.16,
				function()
					TweenService:Create(
						card,
						TweenInfo.new(0.18),
						{
							BackgroundColor3 =
								original
						}
					):Play()
				end
			)
		end
	end
)

updateMoneyDisplay()

print("")
print("========================================")
print("🏪 UPGRADE SHOP CLIENT V3 - POLISHED")
print("========================================")
print("✅ Same size: 680 x 345")
print("✅ Clearer typography")
print("✅ New navy/cyan/copper theme")
print("✅ Common / Rare / Epic visual grades")
print("✅ Third-person mouse restore preserved")
print("========================================")
print("")
