local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local openShopEvent =
	ReplicatedStorage:WaitForChild(
		"OpenPotatoBitShop"
	)

local buyBitEvent =
	ReplicatedStorage:WaitForChild(
		"BuyPotatoBit"
	)

--==================================================
-- REMOVE OLD GUI
--==================================================

local oldGui =
	playerGui:FindFirstChild(
		"PotatoBitShopGui"
	)

if oldGui then
	oldGui:Destroy()
end

--==================================================
-- COLORS
--==================================================

local COLORS = {

	MainBrown =
		Color3.fromRGB(
			49,
			38,
			29
		),

	PanelBrown =
		Color3.fromRGB(
			64,
			49,
			37
		),

	CardBrown =
		Color3.fromRGB(
			73,
			57,
			43
		),

	DarkBrown =
		Color3.fromRGB(
			35,
			28,
			22
		),

	Green =
		Color3.fromRGB(
			83,
			128,
			67
		),

	LightGreen =
		Color3.fromRGB(
			126,
			166,
			102
		),

	DarkGreen =
		Color3.fromRGB(
			48,
			83,
			40
		),

	Cream =
		Color3.fromRGB(
			245,
			230,
			200
		),

	SoftCream =
		Color3.fromRGB(
			220,
			205,
			181
		),

	Gold =
		Color3.fromRGB(
			225,
			184,
			86
		),

	Red =
		Color3.fromRGB(
			157,
			77,
			68
		),

	Purple =
		Color3.fromRGB(
			112,
			83,
			138
		),

	GoldenBrown =
		Color3.fromRGB(
			151,
			117,
			54
		),
}

--==================================================
-- ITEMS
--==================================================

local ITEMS = {

	{
		Name = "Normal Bit",
		Type = "Normal",
		Price = 20,

		Color =
			COLORS.Green,
	},

	{
		Name = "Red Bit",
		Type = "Red",
		Price = 60,

		Color =
			COLORS.Red,
	},

	{
		Name = "Purple Bit",
		Type = "Purple",
		Price = 150,

		Color =
			COLORS.Purple,
	},

	{
		Name = "Golden Bit",
		Type = "Golden",
		Price = 400,

		Color =
			COLORS.GoldenBrown,
	},
}

--==================================================
-- GUI
--==================================================

local gui =
	Instance.new("ScreenGui")

gui.Name =
	"PotatoBitShopGui"

gui.ResetOnSpawn =
	false

gui.Enabled =
	false

gui.Parent =
	playerGui

--==================================================
-- MAIN WINDOW
--==================================================

local main =
	Instance.new("Frame")

main.Name =
	"Main"

main.Size =
	UDim2.new(
		0,
		620,
		0,
		500
	)

main.Position =
	UDim2.new(
		0.5,
		-310,
		0.5,
		-250
	)

main.BackgroundColor3 =
	COLORS.MainBrown

main.BorderSizePixel =
	0

main.Parent =
	gui

local mainCorner =
	Instance.new("UICorner")

mainCorner.CornerRadius =
	UDim.new(
		0,
		20
	)

mainCorner.Parent =
	main

local mainStroke =
	Instance.new("UIStroke")

mainStroke.Thickness =
	3

mainStroke.Color =
	COLORS.Green

mainStroke.Transparency =
	0.1

mainStroke.Parent =
	main

--==================================================
-- TITLE AREA
--==================================================

local header =
	Instance.new("Frame")

header.Name =
	"Header"

header.Size =
	UDim2.new(
		1,
		-24,
		0,
		82
	)

header.Position =
	UDim2.new(
		0,
		12,
		0,
		12
	)

header.BackgroundColor3 =
	COLORS.PanelBrown

header.BorderSizePixel =
	0

header.Parent =
	main

local headerCorner =
	Instance.new("UICorner")

headerCorner.CornerRadius =
	UDim.new(
		0,
		15
	)

headerCorner.Parent =
	header

local headerStroke =
	Instance.new("UIStroke")

headerStroke.Thickness =
	2

headerStroke.Color =
	COLORS.LightGreen

headerStroke.Transparency =
	0.25

headerStroke.Parent =
	header

--==================================================
-- TITLE
--==================================================

local title =
	Instance.new("TextLabel")

title.Name =
	"Title"

title.Size =
	UDim2.new(
		1,
		-95,
		0,
		36
	)

title.Position =
	UDim2.new(
		0,
		20,
		0,
		9
	)

title.BackgroundTransparency =
	1

title.Text =
	"POTATO BIT SHOP"

title.Font =
	Enum.Font.GothamBold

title.TextSize =
	25

title.TextColor3 =
	COLORS.Cream

title.TextXAlignment =
	Enum.TextXAlignment.Left

title.Parent =
	header

--==================================================
-- CASH
--==================================================

local cashLabel =
	Instance.new("TextLabel")

cashLabel.Name =
	"CashLabel"

cashLabel.Size =
	UDim2.new(
		1,
		-95,
		0,
		26
	)

cashLabel.Position =
	UDim2.new(
		0,
		20,
		0,
		47
	)

cashLabel.BackgroundTransparency =
	1

cashLabel.Text =
	"Cash: $0"

cashLabel.Font =
	Enum.Font.GothamBold

cashLabel.TextSize =
	17

cashLabel.TextColor3 =
	COLORS.Gold

cashLabel.TextXAlignment =
	Enum.TextXAlignment.Left

cashLabel.Parent =
	header

--==================================================
-- CLOSE
--==================================================

local closeButton =
	Instance.new("TextButton")

closeButton.Name =
	"CloseButton"

closeButton.Size =
	UDim2.new(
		0,
		52,
		0,
		52
	)

closeButton.Position =
	UDim2.new(
		1,
		-66,
		0,
		15
	)

closeButton.BackgroundColor3 =
	Color3.fromRGB(
		106,
		61,
		48
	)

closeButton.Text =
	"X"

closeButton.Font =
	Enum.Font.GothamBold

closeButton.TextSize =
	21

closeButton.TextColor3 =
	COLORS.Cream

closeButton.BorderSizePixel =
	0

closeButton.Parent =
	header

local closeCorner =
	Instance.new("UICorner")

closeCorner.CornerRadius =
	UDim.new(
		0,
		11
	)

closeCorner.Parent =
	closeButton

--==================================================
-- SCROLL HOLDER
--==================================================

local holder =
	Instance.new("Frame")

holder.Name =
	"Holder"

holder.Size =
	UDim2.new(
		1,
		-24,
		1,
		-118
	)

holder.Position =
	UDim2.new(
		0,
		12,
		0,
		106
	)

holder.BackgroundColor3 =
	COLORS.DarkBrown

holder.BorderSizePixel =
	0

holder.Parent =
	main

local holderCorner =
	Instance.new("UICorner")

holderCorner.CornerRadius =
	UDim.new(
		0,
		15
	)

holderCorner.Parent =
	holder

--==================================================
-- SCROLL
--==================================================

local scroll =
	Instance.new("ScrollingFrame")

scroll.Name =
	"Items"

scroll.Size =
	UDim2.new(
		1,
		-14,
		1,
		-14
	)

scroll.Position =
	UDim2.new(
		0,
		7,
		0,
		7
	)

scroll.BackgroundTransparency =
	1

scroll.BorderSizePixel =
	0

scroll.ScrollBarThickness =
	7

scroll.ScrollBarImageColor3 =
	COLORS.LightGreen

scroll.CanvasSize =
	UDim2.new(
		0,
		0,
		0,
		0
	)

scroll.AutomaticCanvasSize =
	Enum.AutomaticSize.Y

scroll.Parent =
	holder

local layout =
	Instance.new("UIListLayout")

layout.Padding =
	UDim.new(
		0,
		10
	)

layout.SortOrder =
	Enum.SortOrder.LayoutOrder

layout.Parent =
	scroll

local padding =
	Instance.new("UIPadding")

padding.PaddingTop =
	UDim.new(
		0,
		4
	)

padding.PaddingBottom =
	UDim.new(
		0,
		4
	)

padding.PaddingLeft =
	UDim.new(
		0,
		4
	)

padding.PaddingRight =
	UDim.new(
		0,
		8
	)

padding.Parent =
	scroll

--==================================================
-- CREATE ITEM
--==================================================

local function createItem(
	info,
	order
)

	local card =
		Instance.new("Frame")

	card.Name =
		info.Type .. "Card"

	card.LayoutOrder =
		order

	card.Size =
		UDim2.new(
			1,
			-8,
			0,
			112
		)

	card.BackgroundColor3 =
		COLORS.CardBrown

	card.BorderSizePixel =
		0

	card.Parent =
		scroll

	local cardCorner =
		Instance.new("UICorner")

	cardCorner.CornerRadius =
		UDim.new(
			0,
			13
		)

	cardCorner.Parent =
		card

	--==================================================
	-- COLORED SIDE STRIP
	--==================================================

	local strip =
		Instance.new("Frame")

	strip.Size =
		UDim2.new(
			0,
			7,
			1,
			-16
		)

	strip.Position =
		UDim2.new(
			0,
			8,
			0,
			8
		)

	strip.BackgroundColor3 =
		info.Color

	strip.BorderSizePixel =
		0

	strip.Parent =
		card

	local stripCorner =
		Instance.new("UICorner")

	stripCorner.CornerRadius =
		UDim.new(
			1,
			0
		)

	stripCorner.Parent =
		strip

	--==================================================
	-- NAME
	--==================================================

	local itemName =
		Instance.new("TextLabel")

	itemName.Size =
		UDim2.new(
			0,
			270,
			0,
			30
		)

	itemName.Position =
		UDim2.new(
			0,
			28,
			0,
			10
		)

	itemName.BackgroundTransparency =
		1

	itemName.Text =
		info.Name

	itemName.Font =
		Enum.Font.GothamBold

	itemName.TextSize =
		19

	itemName.TextColor3 =
		COLORS.Cream

	itemName.TextXAlignment =
		Enum.TextXAlignment.Left

	itemName.Parent =
		card

	--==================================================
	-- PRICE
	--==================================================

	local price =
		Instance.new("TextLabel")

	price.Size =
		UDim2.new(
			0,
			150,
			0,
			30
		)

	price.Position =
		UDim2.new(
			1,
			-165,
			0,
			10
		)

	price.BackgroundTransparency =
		1

	price.Text =
		"$" .. info.Price

	price.Font =
		Enum.Font.GothamBold

	price.TextSize =
		19

	price.TextColor3 =
		COLORS.Gold

	price.TextXAlignment =
		Enum.TextXAlignment.Right

	price.Parent =
		card

	--==================================================
	-- DESCRIPTION
	--==================================================

	local description =
		Instance.new("TextLabel")

	description.Size =
		UDim2.new(
			0,
			250,
			0,
			22
		)

	description.Position =
		UDim2.new(
			0,
			28,
			0,
			41
		)

	description.BackgroundTransparency =
		1

	description.Text =
		"Potato bit for planting"

	description.Font =
		Enum.Font.Gotham

	description.TextSize =
		13

	description.TextColor3 =
		COLORS.SoftCream

	description.TextXAlignment =
		Enum.TextXAlignment.Left

	description.Parent =
		card

	--==================================================
	-- BUY ONE
	--==================================================

	local buyOne =
		Instance.new("TextButton")

	buyOne.Size =
		UDim2.new(
			0,
			190,
			0,
			38
		)

	buyOne.Position =
		UDim2.new(
			0,
			28,
			1,
			-46
		)

	buyOne.BackgroundColor3 =
		info.Color

	buyOne.Text =
		"BUY 1"

	buyOne.Font =
		Enum.Font.GothamBold

	buyOne.TextSize =
		15

	buyOne.TextColor3 =
		COLORS.Cream

	buyOne.BorderSizePixel =
		0

	buyOne.Parent =
		card

	local oneCorner =
		Instance.new("UICorner")

	oneCorner.CornerRadius =
		UDim.new(
			0,
			9
		)

	oneCorner.Parent =
		buyOne

	--==================================================
	-- BUY ALL
	--==================================================

	local buyAll =
		Instance.new("TextButton")

	buyAll.Size =
		UDim2.new(
			0,
			190,
			0,
			38
		)

	buyAll.Position =
		UDim2.new(
			1,
			-218,
			1,
			-46
		)

	buyAll.BackgroundColor3 =
		COLORS.DarkGreen

	buyAll.Text =
		"BUY ALL"

	buyAll.Font =
		Enum.Font.GothamBold

	buyAll.TextSize =
		15

	buyAll.TextColor3 =
		COLORS.Cream

	buyAll.BorderSizePixel =
		0

	buyAll.Parent =
		card

	local allCorner =
		Instance.new("UICorner")

	allCorner.CornerRadius =
		UDim.new(
			0,
			9
		)

	allCorner.Parent =
		buyAll

	--==================================================
	-- BUTTONS
	--==================================================

	buyOne.MouseButton1Click:Connect(
		function()

			buyBitEvent:FireServer(
				info.Type,
				false
			)

		end
	)

	buyAll.MouseButton1Click:Connect(
		function()

			buyBitEvent:FireServer(
				info.Type,
				true
			)

		end
	)
end

--==================================================
-- BUILD LIST
--==================================================

for index, info in ipairs(
	ITEMS
) do

	createItem(
		info,
		index
	)

end

--==================================================
-- UPDATE CASH
--==================================================

local function updateCash()

	local cash =
		player:GetAttribute(
			"Cash"
		) or 0

	cashLabel.Text =
		"Cash: $"
		.. cash
end

--==================================================
-- OPEN / CLOSE
--==================================================

local function openShop()

	updateCash()

	gui.Enabled =
		true

	player:SetAttribute(
		"MenuMouseFree",
		true
	)
end

local function closeShop()

	gui.Enabled =
		false

	player:SetAttribute(
		"MenuMouseFree",
		false
	)
end

closeButton.MouseButton1Click:Connect(
	closeShop
)

openShopEvent.OnClientEvent:Connect(
	openShop
)

player:GetAttributeChangedSignal(
	"Cash"
):Connect(
	updateCash
)

--==================================================
-- ESCAPE CLOSE
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
			gui.Enabled
			and
			input.KeyCode
				== Enum.KeyCode.Escape
		then

			closeShop()

		end
	end
)

--==================================================
-- RESPAWN SAFETY
--==================================================

player.CharacterAdded:Connect(
	function()

		gui.Enabled =
			false

		player:SetAttribute(
			"MenuMouseFree",
			false
		)

	end
)

updateCash()