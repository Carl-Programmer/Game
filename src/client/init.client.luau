local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- POTATIUM LEVEL HUD - FRAMES V2
--
-- Small, clean top-left HUD.
--
-- Row 1:
-- [peach potato]  PLAYERNAME   [#GLOBAL]
--
-- Row 2:
-- [LV.1]  [ BLUE XP BAR ]  11 / 100 XP    [$5.61M]
--
-- Global rank is read from the player's GlobalRank
-- attribute when the server provides it.
--==================================================

local old = playerGui:FindFirstChild("PotatoHUD")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "PotatoHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

--==================================================
-- COLORS
--==================================================

local PANEL_COLOR = Color3.fromRGB(20, 27, 38)
local PANEL_BORDER = Color3.fromRGB(55, 69, 88)
local PEACH = Color3.fromRGB(255, 188, 145)
local PEACH_DARK = Color3.fromRGB(226, 143, 101)
local BLUE = Color3.fromRGB(60, 155, 255)
local BLUE_DARK = Color3.fromRGB(30, 52, 78)
local WHITE = Color3.fromRGB(245, 248, 252)
local MUTED = Color3.fromRGB(174, 187, 203)
local MONEY_GREEN = Color3.fromRGB(115, 224, 145)
local RANK_GOLD = Color3.fromRGB(255, 213, 120)

--==================================================
-- MAIN PANEL
--==================================================

local panel = Instance.new("Frame")
panel.Name = "LevelPanel"
panel.Size = UDim2.new(0, 370, 0, 78)
panel.Position = UDim2.new(0, 16, 0, 16)
panel.BackgroundColor3 = PANEL_COLOR
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = PANEL_BORDER
panelStroke.Thickness = 1.2
panelStroke.Transparency = 0.2
panelStroke.Parent = panel

--==================================================
-- PEACH ICON FRAME
--==================================================

local iconFrame = Instance.new("Frame")
iconFrame.Name = "PotatoIcon"
iconFrame.Size = UDim2.new(0, 42, 0, 42)
iconFrame.Position = UDim2.new(0, 9, 0, 8)
iconFrame.BackgroundColor3 = PEACH
iconFrame.BorderSizePixel = 0
iconFrame.Parent = panel

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 11)
iconCorner.Parent = iconFrame

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = PEACH_DARK
iconStroke.Thickness = 1
iconStroke.Parent = iconFrame

local icon = Instance.new("TextLabel")
icon.Name = "Potato"
icon.Size = UDim2.fromScale(1, 1)
icon.BackgroundTransparency = 1
icon.Text = "🥔"
icon.TextSize = 24
icon.Font = Enum.Font.GothamBold
icon.TextColor3 = Color3.fromRGB(255, 255, 255)
icon.TextXAlignment = Enum.TextXAlignment.Center
icon.TextYAlignment = Enum.TextYAlignment.Center
icon.Parent = iconFrame

--==================================================
-- PLAYER NAME
--==================================================

local playerName = Instance.new("TextLabel")
playerName.Name = "PlayerName"
playerName.Size = UDim2.new(0, 175, 0, 25)
playerName.Position = UDim2.new(0, 60, 0, 8)
playerName.BackgroundTransparency = 1
playerName.TextColor3 = WHITE
playerName.Font = Enum.Font.GothamBold
playerName.TextSize = 17
playerName.TextXAlignment = Enum.TextXAlignment.Left
playerName.TextYAlignment = Enum.TextYAlignment.Center
playerName.TextTruncate = Enum.TextTruncate.AtEnd
playerName.Parent = panel

--==================================================
-- GLOBAL RANK PILL
--==================================================

local rankPill = Instance.new("Frame")
rankPill.Name = "GlobalRank"
rankPill.Size = UDim2.new(0, 114, 0, 24)
rankPill.Position = UDim2.new(1, -123, 0, 8)
rankPill.BackgroundColor3 = Color3.fromRGB(38, 43, 51)
rankPill.BackgroundTransparency = 0.05
rankPill.BorderSizePixel = 0
rankPill.Parent = panel

local rankCorner = Instance.new("UICorner")
rankCorner.CornerRadius = UDim.new(1, 0)
rankCorner.Parent = rankPill

local rankStroke = Instance.new("UIStroke")
rankStroke.Color = Color3.fromRGB(102, 91, 64)
rankStroke.Thickness = 1
rankStroke.Transparency = 0.25
rankStroke.Parent = rankPill

local rankText = Instance.new("TextLabel")
rankText.Name = "Text"
rankText.Size = UDim2.fromScale(1, 1)
rankText.BackgroundTransparency = 1
rankText.TextColor3 = RANK_GOLD
rankText.Font = Enum.Font.GothamBold
rankText.TextSize = 12
rankText.TextXAlignment = Enum.TextXAlignment.Center
rankText.TextYAlignment = Enum.TextYAlignment.Center
rankText.Parent = rankPill

--==================================================
-- LEVEL LABEL
--==================================================

local levelFrame = Instance.new("Frame")
levelFrame.Name = "LevelFrame"
levelFrame.Size = UDim2.new(0, 49, 0, 28)
levelFrame.Position = UDim2.new(0, 9, 0, 45)
levelFrame.BackgroundColor3 = Color3.fromRGB(34, 43, 56)
levelFrame.BorderSizePixel = 0
levelFrame.Parent = panel

local levelCorner = Instance.new("UICorner")
levelCorner.CornerRadius = UDim.new(0, 8)
levelCorner.Parent = levelFrame

local levelText = Instance.new("TextLabel")
levelText.Name = "Text"
levelText.Size = UDim2.fromScale(1, 1)
levelText.BackgroundTransparency = 1
levelText.TextColor3 = WHITE
levelText.Font = Enum.Font.GothamBold
levelText.TextSize = 13
levelText.TextXAlignment = Enum.TextXAlignment.Center
levelText.TextYAlignment = Enum.TextYAlignment.Center
levelText.Parent = levelFrame

--==================================================
-- XP BAR
--==================================================

local xpTrack = Instance.new("Frame")
xpTrack.Name = "XPTrack"
xpTrack.Size = UDim2.new(0, 145, 0, 12)
xpTrack.Position = UDim2.new(0, 64, 0, 53)
xpTrack.BackgroundColor3 = BLUE_DARK
xpTrack.BorderSizePixel = 0
xpTrack.ClipsDescendants = true
xpTrack.Parent = panel

local xpTrackCorner = Instance.new("UICorner")
xpTrackCorner.CornerRadius = UDim.new(1, 0)
xpTrackCorner.Parent = xpTrack

local xpFill = Instance.new("Frame")
xpFill.Name = "XPFill"
xpFill.Size = UDim2.new(0, 0, 1, 0)
xpFill.BackgroundColor3 = BLUE
xpFill.BorderSizePixel = 0
xpFill.Parent = xpTrack

local xpFillCorner = Instance.new("UICorner")
xpFillCorner.CornerRadius = UDim.new(1, 0)
xpFillCorner.Parent = xpFill

-- Subtle highlight over the blue bar.
local xpHighlight = Instance.new("Frame")
xpHighlight.Name = "Highlight"
xpHighlight.Size = UDim2.new(1, 0, 0, 2)
xpHighlight.Position = UDim2.new(0, 0, 0, 1)
xpHighlight.BackgroundColor3 = Color3.fromRGB(150, 215, 255)
xpHighlight.BackgroundTransparency = 0.45
xpHighlight.BorderSizePixel = 0
xpHighlight.Parent = xpFill

local xpCorner = Instance.new("UICorner")
xpCorner.CornerRadius = UDim.new(1, 0)
xpCorner.Parent = xpHighlight

--==================================================
-- XP TEXT
--==================================================

local xpText = Instance.new("TextLabel")
xpText.Name = "XPText"
xpText.Size = UDim2.new(0, 76, 0, 24)
xpText.Position = UDim2.new(0, 216, 0, 47)
xpText.BackgroundTransparency = 1
xpText.TextColor3 = MUTED
xpText.Font = Enum.Font.GothamSemibold
xpText.TextSize = 11
xpText.TextXAlignment = Enum.TextXAlignment.Left
xpText.TextYAlignment = Enum.TextYAlignment.Center
xpText.Parent = panel

--==================================================
-- MONEY PILL
--==================================================

local moneyPill = Instance.new("Frame")
moneyPill.Name = "Money"
moneyPill.Size = UDim2.new(0, 91, 0, 28)
moneyPill.Position = UDim2.new(1, -100, 0, 45)
moneyPill.BackgroundColor3 = Color3.fromRGB(28, 55, 42)
moneyPill.BackgroundTransparency = 0.08
moneyPill.BorderSizePixel = 0
moneyPill.Parent = panel

local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 8)
moneyCorner.Parent = moneyPill

local moneyText = Instance.new("TextLabel")
moneyText.Name = "Text"
moneyText.Size = UDim2.new(1, -10, 1, 0)
moneyText.Position = UDim2.new(0, 5, 0, 0)
moneyText.BackgroundTransparency = 1
moneyText.TextColor3 = MONEY_GREEN
moneyText.Font = Enum.Font.GothamBold
moneyText.TextSize = 12
moneyText.TextXAlignment = Enum.TextXAlignment.Center
moneyText.TextYAlignment = Enum.TextYAlignment.Center
moneyText.Parent = moneyPill

--==================================================
-- HELPERS
--==================================================

local function formatMoney(value)
	value = tonumber(value) or 0
	local absolute = math.abs(value)

	if absolute >= 1e12 then
		return string.format("$%.2fT", value / 1e12)
	elseif absolute >= 1e9 then
		return string.format("$%.2fB", value / 1e9)
	elseif absolute >= 1e6 then
		return string.format("$%.2fM", value / 1e6)
	elseif absolute >= 1e3 then
		return string.format("$%.2fK", value / 1e3)
	else
		return string.format("$%.0f", value)
	end
end

local function formatGlobalRank(rank)
	rank = tonumber(rank)

	if not rank or rank <= 0 then
		return "GLOBAL"
	end

	return string.format("#%d GLOBAL", math.floor(rank))
end

local function getXPRequired(level)
	level = math.max(1, math.floor(tonumber(level) or 1))
	return math.max(1, math.floor(100 * (1.12 ^ (level - 1))))
end

local function update()
	local level = math.max(
		1,
		math.floor(tonumber(player:GetAttribute("Level")) or 1)
	)

	local xp = math.max(
		0,
		math.floor(tonumber(player:GetAttribute("XP")) or 0)
	)

	local cash = tonumber(player:GetAttribute("Cash")) or 0
	local rank = player:GetAttribute("GlobalRank")
	local requiredXP = getXPRequired(level)
	local ratio = math.clamp(xp / requiredXP, 0, 1)

	playerName.Text = string.upper(player.Name)
	rankText.Text = formatGlobalRank(rank)
	levelText.Text = "LV." .. tostring(level)
	xpText.Text = string.format("%d / %d XP", xp, requiredXP)
	moneyText.Text = formatMoney(cash)

	xpFill.Size = UDim2.new(ratio, 0, 1, 0)
end

player:GetAttributeChangedSignal("Level"):Connect(update)
player:GetAttributeChangedSignal("XP"):Connect(update)
player:GetAttributeChangedSignal("Cash"):Connect(update)
player:GetAttributeChangedSignal("GlobalRank"):Connect(update)

update()

print("🥔 POTATIUM LEVEL HUD V2 - FRAMED UI")
print("✅ Peach potato icon")
print("✅ Dark rounded background")
print("✅ Blue XP progress bar")
print("✅ Level pill")
print("✅ Global rank pill")
print("✅ Money pill")
print("✅ GlobalRank attribute support")
