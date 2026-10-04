local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local BIND_NAME = "PotatoGameMenuMouseUnlock"

--==================================================
-- DEFAULT ATTRIBUTE
--==================================================

if player:GetAttribute("MenuMouseFree") == nil then
	player:SetAttribute(
		"MenuMouseFree",
		false
	)
end

--==================================================
-- STOP FORCING MOUSE
--==================================================

local function stopMouseUnlock()

	RunService:UnbindFromRenderStep(
		BIND_NAME
	)

	-- IMPORTANT:
	-- We do NOT set MouseBehavior here.
	--
	-- Roblox's normal camera system now takes control
	-- again automatically.
end

--==================================================
-- FREE MOUSE WHILE MENU IS OPEN
--==================================================

local function startMouseUnlock()

	RunService:UnbindFromRenderStep(
		BIND_NAME
	)

	RunService:BindToRenderStep(
		BIND_NAME,

		Enum.RenderPriority.Camera.Value + 10,

		function()

			UserInputService.MouseBehavior =
				Enum.MouseBehavior.Default

			UserInputService.MouseIconEnabled =
				true
		end
	)
end

--==================================================
-- UPDATE
--==================================================

local function update()

	local menuOpen =
		player:GetAttribute(
			"MenuMouseFree"
		)

	if menuOpen then

		startMouseUnlock()

	else

		stopMouseUnlock()

	end
end

--==================================================
-- LISTEN
--==================================================

player:GetAttributeChangedSignal(
	"MenuMouseFree"
):Connect(
	update
)

--==================================================
-- RESPAWN
--==================================================

player.CharacterAdded:Connect(
	function()

		player:SetAttribute(
			"MenuMouseFree",
			false
		)

		stopMouseUnlock()

	end
)

update()

print(
	"🖱 Menu mouse controller ready"
)