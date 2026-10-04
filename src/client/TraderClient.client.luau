--========================================================
-- POTATIUM - TRADER CLIENT V4
--
-- ✅ No colored side bars
-- ✅ No overlapping text
-- ✅ Clean row-by-row layout
-- ✅ Potato-themed warm market design
-- ✅ Large SELL buttons
-- ✅ Slightly above screen center
--========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("PotatoTraderRemotes")
local OpenTrader = remotes:WaitForChild("OpenTrader")
local SellPotatoes = remotes:WaitForChild("SellPotatoes")
local SellHoes = remotes:WaitForChild("SellHoes")
local SaleResult = remotes:WaitForChild("SaleResult")

--========================================================
-- STATE
--========================================================

local isOpen = false
local busy = false

local previousBackpackEnabled = true
local previousMouseIcon = true
local openedFromFirstPerson = false

--========================================================
-- COLORS
--========================================================

local COLORS = {
	Overlay = Color3.fromRGB(8, 7, 6),

	Main = Color3.fromRGB(27, 20, 16),
	Header = Color3.fromRGB(39, 28, 21),

	Row = Color3.fromRGB(49, 36, 28),
	RowHover = Color3.fromRGB(58, 42, 32),

	IconPotato = Color3.fromRGB(94, 60, 31),
	IconHoe = Color3.fromRGB(53, 80, 57),

	Cream = Color3.fromRGB(247, 233, 211),
	SoftCream = Color3.fromRGB(218, 201, 178),
	Muted = Color3.fromRGB(165, 149, 132),

	Line = Color3.fromRGB(113, 84, 61),
	SoftLine = Color3.fromRGB(83, 63, 48),

	Orange = Color3.fromRGB(216, 144, 60),
	OrangeDark = Color3.fromRGB(157, 95, 35),

	Green = Color3.fromRGB(103, 159, 108),
	GreenDark = Color3.fromRGB(63, 105, 68),

	Blue = Color3.fromRGB(99, 155, 184),

	Success = Color3.fromRGB(116, 202, 128),
	Warning = Color3.fromRGB(237, 191, 103),
}

--========================================================
-- HELPERS
--========================================================

local function corner(object, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = object
	return c
end

local function stroke(object, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = object
	return s
end

local function gradient(object, first, second, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, first),
		ColorSequenceKeypoint.new(1, second),
	})
	g.Rotation = rotation or 90
	g.Parent = object
	return g
end

local function label(parent, text, size, font, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextSize = size or 14
	l.Font = font or Enum.Font.Gotham
	l.TextColor3 = color or COLORS.Cream
	l.TextWrapped = false
	l.Parent = parent
	return l
end

local function tween(object, duration, properties)
	local t = TweenService:Create(
		object,
		TweenInfo.new(
			duration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		properties
	)

	t:Play()
	return t
end

local function getBackpackEnabled()
	local enabled = true

	pcall(function()
		enabled = StarterGui:GetCoreGuiEnabled(
			Enum.CoreGuiType.Backpack
		)
	end)

	return enabled
end

local function setBackpackEnabled(enabled)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(
			Enum.CoreGuiType.Backpack,
			enabled
		)
	end)
end

local function cameraIsFirstPerson()
	local camera = Workspace.CurrentCamera

	if not camera then
		return false
	end

	return
		(
			camera.Focus.Position
			-
			camera.CFrame.Position
		).Magnitude
		<
		1.1
end

--========================================================
-- REMOVE OLD GUI
--========================================================

local oldGui = playerGui:FindFirstChild("TraderGui")

if oldGui then
	oldGui:Destroy()
end

--========================================================
-- ROOT
--========================================================

local gui = Instance.new("ScreenGui")
gui.Name = "TraderGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 92
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = COLORS.Overlay
overlay.BackgroundTransparency = 0.34
overlay.BorderSizePixel = 0
overlay.Parent = gui

local shadow = Instance.new("Frame")
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 7, 0.45, 9)
shadow.Size = UDim2.fromOffset(930, 410)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.52
shadow.BorderSizePixel = 0
shadow.Parent = overlay
corner(shadow, 20)

local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.45)
main.Size = UDim2.fromOffset(900, 380)
main.BackgroundColor3 = COLORS.Main
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = overlay

corner(main, 20)
stroke(main, COLORS.Line, 1.4, 0.08)

--========================================================
-- HEADER
--========================================================

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 82)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = main

gradient(
	header,
	Color3.fromRGB(45, 32, 24),
	Color3.fromRGB(34, 24, 19),
	90
)

local title = label(
	header,
	"POTATO TRADER",
	27,
	Enum.Font.GothamBlack,
	COLORS.Cream
)

title.Position = UDim2.fromOffset(30, 14)
title.Size = UDim2.fromOffset(340, 30)
title.TextXAlignment = Enum.TextXAlignment.Left

local subtitle = label(
	header,
	"Sell the extras you don't need",
	11,
	Enum.Font.GothamMedium,
	COLORS.SoftCream
)

subtitle.Position = UDim2.fromOffset(32, 47)
subtitle.Size = UDim2.fromOffset(310, 18)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -22, 0.5, 0)
closeButton.Size = UDim2.fromOffset(42, 42)
closeButton.BackgroundColor3 = Color3.fromRGB(67, 48, 37)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.Cream
closeButton.TextSize = 17
closeButton.Font = Enum.Font.GothamBold
closeButton.AutoButtonColor = false
closeButton.Parent = header

corner(closeButton, 11)
stroke(closeButton, COLORS.SoftLine, 1, 0.12)

closeButton.MouseEnter:Connect(function()
	tween(
		closeButton,
		0.08,
		{
			BackgroundColor3 = Color3.fromRGB(82, 56, 43),
		}
	)
end)

closeButton.MouseLeave:Connect(function()
	tween(
		closeButton,
		0.08,
		{
			BackgroundColor3 = Color3.fromRGB(67, 48, 37),
		}
	)
end)

local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(28, 98)
divider.Size = UDim2.new(1, -56, 0, 1)
divider.BackgroundColor3 = COLORS.SoftLine
divider.BackgroundTransparency = 0.35
divider.BorderSizePixel = 0
divider.Parent = main

--========================================================
-- ROW HOLDER
--========================================================

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(28, 116)
content.Size = UDim2.new(1, -56, 0, 214)
content.BackgroundTransparency = 1
content.Parent = main

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 14)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

--========================================================
-- SAFE CHIP
--========================================================

local function makeChip(
	parent,
	text,
	accent,
	width
)
	local chip = Instance.new("Frame")

	chip.Size = UDim2.fromOffset(width, 28)
	chip.BackgroundColor3 = accent
	chip.BackgroundTransparency = 0.82
	chip.BorderSizePixel = 0
	chip.Parent = parent

	corner(chip, 8)
	stroke(chip, accent, 1, 0.28)

	local chipText = label(
		chip,
		text,
		9,
		Enum.Font.GothamBold,
		COLORS.Cream
	)

	chipText.Size = UDim2.fromScale(1, 1)

	return chip
end

--========================================================
-- TRADER ROW
--========================================================

local function createRow(config)
	local row = Instance.new("Frame")

	row.Size = UDim2.new(1, 0, 0, 100)
	row.BackgroundColor3 = COLORS.Row
	row.BorderSizePixel = 0
	row.LayoutOrder = config.Order
	row.Parent = content

	corner(row, 15)
	stroke(row, config.Accent, 1.2, 0.12)

	-- No decorative vertical bar.
	-- Keep the beginning of every row clean.

	local icon = Instance.new("Frame")
	icon.Position = UDim2.fromOffset(18, 18)
	icon.Size = UDim2.fromOffset(64, 64)
	icon.BackgroundColor3 = config.IconColor
	icon.BorderSizePixel = 0
	icon.Parent = row

	corner(icon, 14)
	stroke(icon, config.Accent, 1, 0.12)

	local iconLetter = label(
		icon,
		config.Icon,
		27,
		Enum.Font.GothamBlack,
		COLORS.Cream
	)

	iconLetter.Size = UDim2.fromScale(1, 1)

	local name = label(
		row,
		config.Name,
		20,
		Enum.Font.GothamBlack,
		COLORS.Cream
	)

	name.Position = UDim2.fromOffset(100, 15)
	name.Size = UDim2.fromOffset(290, 26)
	name.TextXAlignment = Enum.TextXAlignment.Left

	local line1 = label(
		row,
		config.Line1,
		11,
		Enum.Font.GothamMedium,
		COLORS.SoftCream
	)

	line1.Position = UDim2.fromOffset(101, 47)
	line1.Size = UDim2.fromOffset(315, 16)
	line1.TextXAlignment = Enum.TextXAlignment.Left

	local line2 = label(
		row,
		config.Line2,
		11,
		Enum.Font.GothamMedium,
		COLORS.Muted
	)

	line2.Position = UDim2.fromOffset(101, 65)
	line2.Size = UDim2.fromOffset(315, 16)
	line2.TextXAlignment = Enum.TextXAlignment.Left

	-- Fixed chip area.
	-- Ends before the SELL button starts, so nothing overlaps.
	local chipHolder = Instance.new("Frame")
	chipHolder.Position = UDim2.fromOffset(430, 35)
	chipHolder.Size = UDim2.fromOffset(218, 32)
	chipHolder.BackgroundTransparency = 1
	chipHolder.Parent = row

	local chipLayout = Instance.new("UIListLayout")
	chipLayout.FillDirection = Enum.FillDirection.Horizontal
	chipLayout.Padding = UDim.new(0, 8)
	chipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	chipLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	chipLayout.Parent = chipHolder

	makeChip(
		chipHolder,
		config.Chip1,
		config.Accent,
		102
	)

	makeChip(
		chipHolder,
		config.Chip2,
		config.Accent,
		102
	)

	local sellButton = Instance.new("TextButton")

	sellButton.AnchorPoint = Vector2.new(1, 0.5)
	sellButton.Position = UDim2.new(1, -18, 0.5, 0)
	sellButton.Size = UDim2.fromOffset(160, 56)
	sellButton.BackgroundColor3 = config.ButtonColor
	sellButton.BorderSizePixel = 0
	sellButton.Text = ""
	sellButton.AutoButtonColor = false
	sellButton.Parent = row

	corner(sellButton, 13)
	stroke(
		sellButton,
		config.Accent,
		1,
		0.15
	)

	gradient(
		sellButton,
		config.ButtonColor,
		config.ButtonColor2,
		90
	)

	local sellTitle = label(
		sellButton,
		"SELL",
		18,
		Enum.Font.GothamBlack,
		COLORS.Cream
	)

	sellTitle.Position = UDim2.fromOffset(0, 8)
	sellTitle.Size = UDim2.new(1, 0, 0, 22)

	local sellSub = label(
		sellButton,
		config.ButtonSub,
		9,
		Enum.Font.GothamMedium,
		COLORS.SoftCream
	)

	sellSub.Position = UDim2.fromOffset(0, 31)
	sellSub.Size = UDim2.new(1, 0, 0, 14)

	row.MouseEnter:Connect(function()
		if busy then
			return
		end

		tween(
			row,
			0.08,
			{
				BackgroundColor3 =
					COLORS.RowHover,
			}
		)
	end)

	row.MouseLeave:Connect(function()
		tween(
			row,
			0.08,
			{
				BackgroundColor3 =
					COLORS.Row,
			}
		)
	end)

	sellButton.MouseEnter:Connect(function()
		if busy then
			return
		end

		tween(
			sellButton,
			0.08,
			{
				Size =
					UDim2.fromOffset(
						164,
						58
					),
			}
		)
	end)

	sellButton.MouseLeave:Connect(function()
		tween(
			sellButton,
			0.08,
			{
				Size =
					UDim2.fromOffset(
						160,
						56
					),
			}
		)
	end)

	return sellButton
end

local potatoSellButton =
	createRow({
		Order = 1,

		Name = "POTATOES",
		Icon = "P",

		Line1 = "Sell all extra potatoes",
		Line2 = "Favorites and placed potatoes stay safe",

		Chip1 = "FAVORITE SAFE",
		Chip2 = "PLACED SAFE",

		IconColor = COLORS.IconPotato,

		Accent = COLORS.Orange,

		ButtonColor = COLORS.Orange,
		ButtonColor2 = COLORS.OrangeDark,

		ButtonSub = "Unfavorited only",
	})

local hoeSellButton =
	createRow({
		Order = 2,

		Name = "HOES",
		Icon = "H",

		Line1 = "Sell all extra crate hoes",
		Line2 = "Favorites and your equipped hoe stay safe",

		Chip1 = "FAVORITE SAFE",
		Chip2 = "EQUIPPED SAFE",

		IconColor = COLORS.IconHoe,

		Accent = COLORS.Green,

		ButtonColor = COLORS.Green,
		ButtonColor2 = COLORS.GreenDark,

		ButtonSub = "Extra hoes only",
	})

--========================================================
-- STATUS
--========================================================

local statusLine = Instance.new("Frame")
statusLine.Position = UDim2.new(0, 28, 1, -43)
statusLine.Size = UDim2.new(1, -56, 0, 1)
statusLine.BackgroundColor3 = COLORS.SoftLine
statusLine.BackgroundTransparency = 0.42
statusLine.BorderSizePixel = 0
statusLine.Parent = main

local status = label(
	main,
	"",
	11,
	Enum.Font.GothamBold,
	COLORS.SoftCream
)

status.AnchorPoint = Vector2.new(0.5, 1)
status.Position = UDim2.new(0.5, 0, 1, -12)
status.Size = UDim2.new(1, -60, 0, 23)
status.TextXAlignment = Enum.TextXAlignment.Center

--========================================================
-- OPEN / CLOSE
--========================================================

local function closeTrader()
	if not isOpen then
		return
	end

	isOpen = false
	busy = false

	gui.Enabled = false

	setBackpackEnabled(
		previousBackpackEnabled
	)

	local lockMouse =
		openedFromFirstPerson

	UserInputService.MouseBehavior =
		lockMouse
		and
		Enum.MouseBehavior.LockCenter
		or
		Enum.MouseBehavior.Default

	UserInputService.MouseIconEnabled =
		lockMouse
		and
		false
		or
		previousMouseIcon
end

local function openTrader()
	openedFromFirstPerson =
		cameraIsFirstPerson()

	previousBackpackEnabled =
		getBackpackEnabled()

	previousMouseIcon =
		UserInputService.MouseIconEnabled

	isOpen = true
	busy = false

	status.Text = ""

	setBackpackEnabled(false)

	gui.Enabled = true

	UserInputService.MouseBehavior =
		Enum.MouseBehavior.Default

	UserInputService.MouseIconEnabled =
		true

	main.Size =
		UDim2.fromOffset(
			865,
			360
		)

	shadow.Size =
		UDim2.fromOffset(
			895,
			390
		)

	tween(
		main,
		0.12,
		{
			Size =
				UDim2.fromOffset(
					900,
					380
				),
		}
	)

	tween(
		shadow,
		0.12,
		{
			Size =
				UDim2.fromOffset(
					930,
					410
				),
		}
	)
end

closeButton.MouseButton1Click:Connect(
	closeTrader
)

overlay.InputBegan:Connect(function(input)
	if
		input.UserInputType
		~=
		Enum.UserInputType.MouseButton1
	then
		return
	end

	local mousePosition =
		UserInputService:GetMouseLocation()

	local position =
		main.AbsolutePosition

	local size =
		main.AbsoluteSize

	local inside =
		mousePosition.X >= position.X
		and
		mousePosition.X <= position.X + size.X
		and
		mousePosition.Y >= position.Y
		and
		mousePosition.Y <= position.Y + size.Y

	if not inside then
		closeTrader()
	end
end)

UserInputService.InputBegan:Connect(function(
	input,
	gameProcessed
)
	if
		not isOpen
		or
		gameProcessed
	then
		return
	end

	if
		input.KeyCode
		==
		Enum.KeyCode.Escape
	then
		closeTrader()
	end
end)

--========================================================
-- SELL
--========================================================

local function startSale(
	remote,
	text
)
	if busy then
		return
	end

	busy = true

	status.Text =
		text

	status.TextColor3 =
		COLORS.Warning

	remote:FireServer()
end

potatoSellButton.MouseButton1Click:Connect(function()
	startSale(
		SellPotatoes,
		"Selling potatoes..."
	)
end)

hoeSellButton.MouseButton1Click:Connect(function()
	startSale(
		SellHoes,
		"Selling hoes..."
	)
end)

--========================================================
-- SERVER EVENTS
--========================================================

OpenTrader.OnClientEvent:Connect(
	openTrader
)

SaleResult.OnClientEvent:Connect(function(
	saleType,
	soldCount,
	earned,
	protectedInfo
)
	busy = false

	soldCount =
		tonumber(
			soldCount
		)
		or
		0

	earned =
		tonumber(
			earned
		)
		or
		0

	if soldCount <= 0 then
		status.Text =
			"Nothing sellable found"

		status.TextColor3 =
			COLORS.Warning

		return
	end

	status.Text =
		"Sold "
		..
		tostring(
			soldCount
		)
		..
		" "
		..
		string.lower(
			tostring(
				saleType
			)
		)
		..
		"  •  +$"
		..
		tostring(
			earned
		)

	status.TextColor3 =
		COLORS.Success
end)

print("")
print("========================================")
print("🥔 POTATO TRADER CLIENT V4")
print("========================================")
print("✅ Removed left decorative bars")
print("✅ No chip / SELL overlap")
print("✅ Cleaner spacing")
print("✅ Shorter clearer wording")
print("========================================")
print("")
