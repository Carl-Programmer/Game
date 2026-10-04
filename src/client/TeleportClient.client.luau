local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

--==================================================
-- WORLD
--==================================================

local world =
	workspace:WaitForChild("PotatoWorld")

local foragingZone =
	world:WaitForChild("ForagingZone")

--==================================================
-- REMOTES
--==================================================

local remotes =
	ReplicatedStorage:WaitForChild(
		"PotatoTeleportRemotes"
	)

local RequestTeleport =
	remotes:WaitForChild(
		"RequestTeleport"
	)

local TeleportStatus =
	remotes:WaitForChild(
		"TeleportStatus"
	)

--==================================================
-- SETTINGS
--==================================================

local BUTTON_COOLDOWN = 0.5

-- If the server says STARTED but for some reason
-- FINISHED / FAILED never reaches the client,
-- unlock the buttons after this many seconds.
local BUSY_FAILSAFE = 2

--==================================================
-- STATE
--==================================================

local teleportBusy = false
local localCooldown = false
local insideForaging = false

local activeDestination = nil
local busyGeneration = 0

--==================================================
-- CHARACTER
--==================================================

local function getRoot()

	local character =
		player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild(
		"HumanoidRootPart"
	)

end

--==================================================
-- INSIDE PART
--==================================================

local function pointInsideGround(
	ground,
	position
)

	if
		not ground
		or
		not ground:IsA("BasePart")
	then

		return false
	end

	local localPosition =
		ground.CFrame
			:PointToObjectSpace(
				position
			)

	local half =
		ground.Size / 2

	return

		math.abs(localPosition.X)
		<=
		half.X

		and

		math.abs(localPosition.Z)
		<=
		half.Z

		and

		localPosition.Y >= -10

		and

		localPosition.Y <= 18

end

--==================================================
-- INSIDE ANY FORAGING ZONE
--==================================================

local function isInsideForagingZone()

	local root =
		getRoot()

	if not root then
		return false
	end

	for _, zone in ipairs(
		foragingZone:GetChildren()
	) do

		if
			zone:IsA("Model")
			and
			zone:GetAttribute(
				"ZoneNumber"
			)
		then

			local ground =
				zone:FindFirstChild(
					"Ground"
				)

			if
				ground
				and
				pointInsideGround(
					ground,
					root.Position
				)
			then

				return true
			end

		end

	end

	return false

end

--==================================================
-- GUI
--==================================================

local playerGui =
	player:WaitForChild(
		"PlayerGui"
	)

local oldGui =
	playerGui:FindFirstChild(
		"PotatoTravelGui"
	)

if oldGui then
	oldGui:Destroy()
end

local gui =
	Instance.new("ScreenGui")

gui.Name =
	"PotatoTravelGui"

gui.ResetOnSpawn =
	false

--==================================================
-- ROBLOX TOP BAR FIX
--
-- Respect the Roblox top bar so CoreGui
-- does not steal the button clicks.
--==================================================

gui.IgnoreGuiInset =
	false

gui.DisplayOrder =
	10

gui.Parent =
	playerGui

--==================================================
-- CONTAINER
--==================================================

local container =
	Instance.new("Frame")

container.Name =
	"TravelTabs"

container.AnchorPoint =
	Vector2.new(
		0.5,
		0
	)

container.Position =
	UDim2.new(
		0.5,
		0,
		0,
		2
	)

container.Size =
	UDim2.new(
		0,
		470,
		0,
		44
	)

container.BackgroundTransparency =
	1

container.Parent =
	gui

--==================================================
-- LAYOUT
--==================================================

local layout =
	Instance.new("UIListLayout")

layout.FillDirection =
	Enum.FillDirection.Horizontal

layout.HorizontalAlignment =
	Enum.HorizontalAlignment.Center

layout.VerticalAlignment =
	Enum.VerticalAlignment.Center

layout.Padding =
	UDim.new(
		0,
		9
	)

layout.Parent =
	container

--==================================================
-- CREATE BUTTON
--==================================================

local function createButton(
	name,
	dotColor
)

	local button =
		Instance.new("TextButton")

	button.Name =
		name .. "Button"

	button.Size =
		UDim2.new(
			0,
			150,
			0,
			40
		)

	button.BackgroundColor3 =
		Color3.fromRGB(
			121,
			82,
			46
		)

	button.BorderSizePixel =
		0

	button.AutoButtonColor =
		true

	button.Text =
		""

	button.Active =
		true

	button.Selectable =
		true

	button.ZIndex =
		10

	button.Parent =
		container

	--==================================================
	-- CORNER
	--==================================================

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(
			0,
			10
		)

	corner.Parent =
		button

	--==================================================
	-- OUTLINE
	--==================================================

	local stroke =
		Instance.new("UIStroke")

	stroke.Color =
		Color3.fromRGB(
			75,
			50,
			27
		)

	stroke.Thickness =
		3

	stroke.Parent =
		button

	--==================================================
	-- DOT
	--==================================================

	local dot =
		Instance.new("Frame")

	dot.AnchorPoint =
		Vector2.new(
			0,
			0.5
		)

	dot.Position =
		UDim2.new(
			0,
			14,
			0.5,
			0
		)

	dot.Size =
		UDim2.new(
			0,
			15,
			0,
			15
		)

	dot.BackgroundColor3 =
		dotColor

	dot.BorderSizePixel =
		0

	dot.ZIndex =
		11

	dot.Parent =
		button

	local dotCorner =
		Instance.new("UICorner")

	dotCorner.CornerRadius =
		UDim.new(
			1,
			0
		)

	dotCorner.Parent =
		dot

	local dotStroke =
		Instance.new("UIStroke")

	dotStroke.Color =
		Color3.fromRGB(
			27,
			24,
			19
		)

	dotStroke.Thickness =
		2

	dotStroke.Parent =
		dot

	--==================================================
	-- LABEL
	--==================================================

	local label =
		Instance.new("TextLabel")

	label.Position =
		UDim2.new(
			0,
			38,
			0,
			0
		)

	label.Size =
		UDim2.new(
			1,
			-43,
			1,
			0
		)

	label.BackgroundTransparency =
		1

	label.Text =
		name

	label.TextColor3 =
		Color3.fromRGB(
			248,
			236,
			208
		)

	label.Font =
		Enum.Font.GothamMedium

	label.TextSize =
		18

	label.TextXAlignment =
		Enum.TextXAlignment.Center

	label.ZIndex =
		11

	-- Allows clicks to pass through
	-- the label into the actual button.
	label.Active =
		false

	label.Parent =
		button

	return button

end

--==================================================
-- BUTTONS
--==================================================

local homeButton =
	createButton(
		"HOME",
		Color3.fromRGB(
			128,
			232,
			79
		)
	)

local huntButton =
	createButton(
		"HUNT",
		Color3.fromRGB(
			213,
			151,
			70
		)
	)

local townButton =
	createButton(
		"TOWN",
		Color3.fromRGB(
			255,
			205,
			100
		)
	)

--==================================================
-- UPDATE BUTTONS
--==================================================

local function updateButtons()

	local enabled =
		not teleportBusy
		and
		not localCooldown
		and
		not insideForaging

	homeButton.Active =
		enabled

	huntButton.Active =
		enabled

	townButton.Active =
		enabled

	container.Visible =
		not insideForaging

end

--==================================================
-- RESET BUSY
--==================================================

local function resetTeleportBusy()

	teleportBusy =
		false

	activeDestination =
		nil

	busyGeneration +=
		1

	updateButtons()

end

--==================================================
-- START BUSY FAILSAFE
--==================================================

local function startBusyFailsafe()

	busyGeneration +=
		1

	local thisGeneration =
		busyGeneration

	task.delay(
		BUSY_FAILSAFE,

		function()

			if
				teleportBusy
				and
				busyGeneration
				==
				thisGeneration
			then

				warn(
					"⚠ Teleport busy failsafe reset:",
					activeDestination
				)

				teleportBusy =
					false

				activeDestination =
					nil

				updateButtons()

			end

		end
	)

end

--==================================================
-- REQUEST TELEPORT
--==================================================

local function requestTeleport(
	destination
)

	if teleportBusy then

		print(
			"⚠ Teleport already busy"
		)

		return
	end

	if localCooldown then

		print(
			"⚠ Teleport cooldown"
		)

		return
	end

	if insideForaging then

		print(
			"⚠ Teleports blocked inside foraging"
		)

		return
	end

	print(
		"🖱 TELEPORT BUTTON CLICKED:",
		destination
	)

	--==================================================
	-- IMPORTANT FIX
	--
	-- DO NOT set teleportBusy = true here.
	--
	-- The server may reject a rapid request because
	-- its own cooldown is still active.
	--
	-- teleportBusy becomes true ONLY when the server
	-- replies with STARTED.
	--==================================================

	localCooldown =
		true

	activeDestination =
		destination

	updateButtons()

	RequestTeleport:FireServer(
		destination
	)

	--==================================================
	-- LOCAL CLICK COOLDOWN
	--==================================================

	task.delay(
		BUTTON_COOLDOWN,

		function()

			localCooldown =
				false

			updateButtons()

		end
	)

end

--==================================================
-- BUTTON CLICKS
--==================================================

homeButton.MouseButton1Click:Connect(
	function()

		requestTeleport(
			"HOME"
		)

	end
)

huntButton.MouseButton1Click:Connect(
	function()

		requestTeleport(
			"HUNT"
		)

	end
)

townButton.MouseButton1Click:Connect(
	function()

		requestTeleport(
			"TOWN"
		)

	end
)

--==================================================
-- SERVER RESPONSE
--==================================================

TeleportStatus.OnClientEvent:Connect(
	function(
		status,
		destination
	)

		print(
			"📨 TELEPORT SERVER STATUS:",
			status,
			destination
		)

		--==================================================
		-- SERVER ACCEPTED REQUEST
		--==================================================

		if status == "STARTED" then

			teleportBusy =
				true

			activeDestination =
				destination

			updateButtons()

			startBusyFailsafe()

		--==================================================
		-- SERVER FINISHED
		--==================================================

		elseif status == "FINISHED" then

			resetTeleportBusy()

		--==================================================
		-- SERVER FAILED
		--==================================================

		elseif status == "FAILED" then

			resetTeleportBusy()

		--==================================================
		-- BLOCKED INSIDE FORAGING
		--==================================================

		elseif
			status
			==
			"BLOCKED_FORAGING"
		then

			resetTeleportBusy()

		end

end
)

--==================================================
-- FORAGING DETECTION
--==================================================

local timer =
	0

RunService.Heartbeat:Connect(
	function(deltaTime)

		timer +=
			deltaTime

		if timer < 0.1 then
			return
		end

		timer =
			0

		local newState =
			isInsideForagingZone()

		if
			newState
			~=
			insideForaging
		then

			insideForaging =
				newState

			--==================================================
			-- If player entered a foraging zone,
			-- hide the teleport buttons.
			--==================================================

			updateButtons()

		end

	end
)

--==================================================
-- RESPAWN
--==================================================

player.CharacterAdded:Connect(
	function()

		teleportBusy =
			false

		localCooldown =
			false

		activeDestination =
			nil

		busyGeneration +=
			1

		insideForaging =
			false

		task.wait(
			0.5
		)

		insideForaging =
			isInsideForagingZone()

		updateButtons()

	end
)

--==================================================
-- READY
--==================================================

updateButtons()

print("")
print("========================================")
print("🧭 TELEPORT CLIENT READY - BUSY FIX")
print("========================================")
print("Buttons below Roblox CoreGui")
print("HOME / HUNT / TOWN")
print("Teleport delay = 0.5 sec")
print("Busy failsafe = 2 sec")
print("========================================")
print("")