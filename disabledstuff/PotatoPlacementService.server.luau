local Workspace =
	game:GetService("Workspace")

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

--==================================================
-- POTATO PLACEMENT SERVICE V5
--
-- IMPORTANT:
-- Roblox ProximityPrompt handles the 10-stud range.
-- We do NOT do another server distance check.
--==================================================

local BASE_NAME =
	"PlayerBase_TEST"

local PROMPT_DISTANCE =
	10

local startedSlots =
	{}

--==================================================
-- REMOTES
--==================================================

local remotes =
	ReplicatedStorage:FindFirstChild(
		"PotatoPlacementRemotes"
	)

if not remotes then

	remotes =
		Instance.new("Folder")

	remotes.Name =
		"PotatoPlacementRemotes"

	remotes.Parent =
		ReplicatedStorage
end

local placeRemote =
	remotes:FindFirstChild(
		"PlacePotato"
	)

if not placeRemote then

	placeRemote =
		Instance.new("RemoteEvent")

	placeRemote.Name =
		"PlacePotato"

	placeRemote.Parent =
		remotes
end

--==================================================
-- GET EQUIPPED POTATO
--==================================================

local function getEquippedPotato(
	player
)

	local character =
		player.Character

	if not character then
		return nil
	end

	for _, object in ipairs(
		character:GetChildren()
	) do

		if
			object:IsA("Tool")
			and
			object:GetAttribute(
				"PotatoInventoryTool"
			) == true
		then

			return object
		end
	end

	return nil
end

--==================================================
-- GET POTATO VISUAL
--==================================================

local function getPotatoVisual(
	tool
)

	local visual =
		tool:FindFirstChild(
			"PotatoVisual",
			true
		)

	if
		visual
		and
		visual:IsA("BasePart")
	then

		return visual
	end

	--==================================================
	-- FALLBACK SEARCH
	--==================================================

	for _, object in ipairs(
		tool:GetDescendants()
	) do

		if
			object:IsA("BasePart")
			and
			object.Name ~= "Handle"
		then

			return object
		end
	end

	return nil
end

--==================================================
-- REMOVE OLD WELDS
--==================================================

local function removeJoints(
	part
)

	for _, object in ipairs(
		part:GetDescendants()
	) do

		if
			object:IsA("WeldConstraint")
			or
			object:IsA("Weld")
			or
			object:IsA("Motor6D")
		then

			object:Destroy()
		end
	end
end

--==================================================
-- FALLBACK POTATO VISUAL
--==================================================

local function createFallbackPotato(
	tool
)

	local potato =
		Instance.new("Part")

	potato.Name =
		"PlacedPotato"

	potato.Shape =
		Enum.PartType.Ball

	local scale =
		tool:GetAttribute(
			"VisualScale"
		)
		or
		1

	potato.Size =
		Vector3.new(
			0.8,
			0.6,
			0.9
		)
		*
		scale

	local potatoType =
		tool:GetAttribute(
			"PotatoType"
		)

	--==================================================
	-- SWEET POTATO
	--==================================================

	if potatoType == "Sweet" then

		potato.Color =
			Color3.fromRGB(
				184,
				99,
				74
			)

	else

		potato.Color =
			Color3.fromRGB(
				181,
				138,
				87
			)
	end

	potato.Material =
		Enum.Material.SmoothPlastic

	return potato
end

--==================================================
-- COPY POTATO ATTRIBUTES
--==================================================

local function copyAttributes(
	tool,
	potato
)

	local attributes = {

		"PotatoId",

		"PotatoType",

		"PotatoTier",

		"SizeTier",

		"SpudMass",

		"VisualScale",

		"Mutation",
	}

	for _, attributeName in ipairs(
		attributes
	) do

		local value =
			tool:GetAttribute(
				attributeName
			)

		if value ~= nil then

			potato:SetAttribute(
				attributeName,
				value
			)
		end
	end
end

--==================================================
-- CREATE PLACED POTATO
--==================================================

local function createPlacedPotato(
	tool,
	slot
)

	local point =
		slot:FindFirstChild(
			"PotatoPoint"
		)

	if
		not point
		or
		not point:IsA("BasePart")
	then

		warn(
			"❌ PotatoPoint missing in "
				..
				slot.Name
		)

		return nil
	end

	--==================================================
	-- REMOVE OLD VISUAL
	--==================================================

	local old =
		slot:FindFirstChild(
			"PlacedPotato"
		)

	if old then

		old:Destroy()
	end

	--==================================================
	-- FIND HELD VISUAL
	--==================================================

	local heldVisual =
		getPotatoVisual(
			tool
		)

	local placedPotato

	--==================================================
	-- CLONE ACTUAL POTATO
	--==================================================

	if heldVisual then

		placedPotato =
			heldVisual:Clone()

		placedPotato.Name =
			"PlacedPotato"

		removeJoints(
			placedPotato
		)

	else

		warn(
			"⚠ Held visual missing. Using fallback potato."
		)

		placedPotato =
			createFallbackPotato(
				tool
			)
	end

	--==================================================
	-- WORLD SETTINGS
	--==================================================

	placedPotato.Anchored =
		true

	placedPotato.CanCollide =
		false

	placedPotato.CanTouch =
		false

	placedPotato.CanQuery =
		true

	placedPotato.Massless =
		true

	--==================================================
	-- PUT POTATO ON TOP OF STAND
	--==================================================

	local potatoHeight =
		placedPotato.Size.Y / 2

	placedPotato.CFrame =
		point.CFrame
		*
		CFrame.new(
			0,
			potatoHeight + 0.2,
			0
		)
		*
		CFrame.Angles(
			math.rad(8),
			math.rad(25),
			math.rad(-6)
		)

	copyAttributes(
		tool,
		placedPotato
	)

	placedPotato.Parent =
		slot

	return placedPotato
end

--==================================================
-- BASE OWNERSHIP
--==================================================

local function canUseBase(
	player,
	base
)

	local ownerUserId =
		base:GetAttribute(
			"OwnerUserId"
		)
		or
		0

	--==================================================
	-- TEST BASE
	-- Anyone allowed while OwnerUserId = 0.
	--==================================================

	if ownerUserId == 0 then

		return true
	end

	return
		ownerUserId
		==
		player.UserId
end

--==================================================
-- PLACE POTATO
--==================================================

local function placePotato(
	player,
	slot
)

	print(
		"📨 PLACE REQUEST | "
			..
			player.Name
	)

	--==================================================
	-- FIND BASE
	--==================================================

	local base =
		Workspace:FindFirstChild(
			BASE_NAME
		)

	if not base then

		warn(
			"❌ PlayerBase_TEST missing"
		)

		return
	end

	--==================================================
	-- CHECK SLOT INSTANCE
	--==================================================

	if
		typeof(slot) ~= "Instance"
		or
		not slot:IsA("Model")
	then

		warn(
			"❌ Invalid slot received"
		)

		return
	end

	--==================================================
	-- MAKE SURE SLOT BELONGS TO THIS BASE
	--==================================================

	local slotsFolder =
		base:FindFirstChild(
			"PotatoSlots"
		)

	if not slotsFolder then

		warn(
			"❌ PotatoSlots folder missing"
		)

		return
	end

	if slot.Parent ~= slotsFolder then

		warn(
			"❌ Invalid slot parent"
		)

		return
	end

	print(
		"🟨 Slot = "
			..
			slot.Name
	)

	--==================================================
	-- ALREADY OCCUPIED?
	--==================================================

	if
		slot:GetAttribute(
			"Occupied"
		)
		==
		true
	then

		print(
			"❌ Slot already occupied"
		)

		return
	end

	--==================================================
	-- BASE OWNERSHIP
	--==================================================

	if not canUseBase(
		player,
		base
	) then

		print(
			"❌ This isn't your base"
		)

		return
	end

	--==================================================
	-- MUST CURRENTLY HOLD POTATO
	--==================================================

	local tool =
		getEquippedPotato(
			player
		)

	if not tool then

		print(
			"❌ No equipped potato found"
		)

		return
	end

	print(
		"✅ Equipped potato = "
			..
			tool.Name
	)

	--==================================================
	-- PREVENT DOUBLE PLACEMENT
	--==================================================

	if
		slot:GetAttribute(
			"Placing"
		)
		==
		true
	then

		print(
			"❌ Slot placement already running"
		)

		return
	end

	slot:SetAttribute(
		"Placing",
		true
	)

	--==================================================
	-- CREATE VISUAL
	--==================================================

	local potato =
		createPlacedPotato(
			tool,
			slot
		)

	if not potato then

		slot:SetAttribute(
			"Placing",
			false
		)

		warn(
			"❌ Could not create potato visual"
		)

		return
	end

	--==================================================
	-- POTATO ID
	--==================================================

	local potatoId =
		tool:GetAttribute(
			"PotatoId"
		)
		or
		0

	--==================================================
	-- MARK SLOT OCCUPIED
	--==================================================

	slot:SetAttribute(
		"Occupied",
		true
	)

	slot:SetAttribute(
		"PotatoId",
		potatoId
	)

	slot:SetAttribute(
		"PlacedByUserId",
		player.UserId
	)

	slot:SetAttribute(
		"Placing",
		false
	)

	--==================================================
	-- REMOVE POTATO FROM HAND
	--
	-- IMPORTANT:
	-- We are STILL not deleting permanent saved data.
	-- This is just the placement test.
	--==================================================

	tool:Destroy()

	--==================================================
	-- SUCCESS
	--==================================================

	print("")
	print("========================================")
	print("🥔 POTATO PLACED SUCCESSFULLY")
	print("========================================")
	print("Player: " .. player.Name)
	print("Slot: " .. slot.Name)
	print("Potato ID: " .. tostring(potatoId))
	print("========================================")
	print("")
end

--==================================================
-- REMOTE REQUEST
--==================================================

placeRemote.OnServerEvent:Connect(
	function(
		player,
		slot
	)

		placePotato(
			player,
			slot
		)
	end
)

--==================================================
-- CREATE PROMPT
--==================================================

local function setupSlot(
	slot
)

	if startedSlots[slot] then

		return
	end

	startedSlots[slot] =
		true

	local standTop =
		slot:FindFirstChild(
			"StandTop"
		)

	if
		not standTop
		or
		not standTop:IsA("BasePart")
	then

		warn(
			"❌ StandTop missing in "
				..
				slot.Name
		)

		return
	end

	--==================================================
	-- REMOVE OLD PROMPT
	--==================================================

	local oldPrompt =
		standTop:FindFirstChild(
			"PlacePotatoPrompt"
		)

	if oldPrompt then

		oldPrompt:Destroy()
	end

	--==================================================
	-- NEW PROMPT
	--==================================================

	local prompt =
		Instance.new(
			"ProximityPrompt"
		)

	prompt.Name =
		"PlacePotatoPrompt"

	prompt.ActionText =
		"Place Potato"

	prompt.ObjectText =
		"Potato Stand"

	prompt.KeyboardKeyCode =
		Enum.KeyCode.E

	prompt.HoldDuration =
		0

	prompt.MaxActivationDistance =
		PROMPT_DISTANCE

	prompt.RequiresLineOfSight =
		false

	prompt:SetAttribute(
		"PotatoPlacementPrompt",
		true
	)

	prompt.Parent =
		standTop
end

--==================================================
-- START
--==================================================

task.spawn(
	function()

		local base =
			Workspace:WaitForChild(
				BASE_NAME
			)

		local slotsFolder =
			base:WaitForChild(
				"PotatoSlots"
			)

		for _, slot in ipairs(
			slotsFolder:GetChildren()
		) do

			if slot:IsA("Model") then

				setupSlot(
					slot
				)
			end
		end

		slotsFolder.ChildAdded:Connect(
			function(slot)

				task.wait()

				if slot:IsA("Model") then

					setupSlot(
						slot
					)
				end
			end
		)

		print("")
		print("========================================")
		print("🥔 POTATO PLACEMENT SERVICE V5 READY")
		print("========================================")
		print("✅ E prompt = 10 studs")
		print("✅ Remote placement")
		print("✅ Server slot validation")
		print("✅ Equipped potato validation")
		print("🚫 Broken extra distance check removed")
		print("========================================")
		print("")
	end
)