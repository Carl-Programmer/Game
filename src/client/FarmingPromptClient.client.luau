local Players =
	game:GetService(
		"Players"
	)

local player =
	Players.LocalPlayer

local world =
	workspace:WaitForChild(
		"PotatoWorld"
	)

local hookedPrompts = {}

--==================================================
-- EQUIPPED TOOL
--==================================================

local function getEquippedToolType()

	local character =
		player.Character

	if not character then
		return nil
	end

	for _, item in ipairs(
		character:GetChildren()
	) do

		if item:IsA(
			"Tool"
		) then

			local toolType =
				item:GetAttribute(
					"FarmingToolType"
				)

			if toolType then

				return toolType

			end
		end
	end

	return nil
end

--==================================================
-- UPDATE PROMPT
--==================================================

local function updatePrompt(
	prompt
)

	if not prompt:IsA(
		"ProximityPrompt"
	) then

		return
	end

	local toolType =
		getEquippedToolType()

	--==================================================
	-- PLANT
	--==================================================

	if prompt.Name ==
		"PlantPrompt"
	then

		local bits =
			player:GetAttribute(
				"PotatoBits"
			) or 0

		prompt.Enabled =
			toolType
				== "PotatoBits"
			and
			bits > 0

		return
	end

	--==================================================
	-- HARVEST
	--==================================================

	if prompt.Name ==
		"HarvestPrompt"
	then

		prompt.Enabled =
			toolType
				== "Hoe"

		return
	end

	--==================================================
	-- FORAGING DIG
	--==================================================

	if prompt.Name ==
		"DigPrompt"
	then

		local spot =
			prompt.Parent

		local busy =
			false

		if spot then

			busy =
				spot:GetAttribute(
					"Busy"
				)
				== true

		end

		prompt.Enabled =
			toolType
				== "Hoe"
			and
			not busy

		return
	end
end

--==================================================
-- HOOK PROMPT
--==================================================

local function hookPrompt(
	prompt
)

	if hookedPrompts[
		prompt
	] then

		return
	end

	hookedPrompts[
		prompt
	] =
		true

	updatePrompt(
		prompt
	)

	if
		prompt.Name
			== "DigPrompt"
		and
		prompt.Parent
	then

		local spot =
			prompt.Parent

		spot:GetAttributeChangedSignal(
			"Busy"
		):Connect(
			function()

				if prompt.Parent then

					updatePrompt(
						prompt
					)

				end
			end
		)
	end

	prompt.AncestryChanged:Connect(
		function(
			_,
			parent
		)

			if not parent then

				hookedPrompts[
					prompt
				] =
					nil

			end
		end
	)
end

--==================================================
-- UPDATE ALL
--==================================================

local function updateAllPrompts()

	for _, object in ipairs(
		world:GetDescendants()
	) do

		if
			object:IsA(
				"ProximityPrompt"
			)
			and
			(
				object.Name
					== "PlantPrompt"

				or
				object.Name
					== "HarvestPrompt"

				or
				object.Name
					== "DigPrompt"
			)
		then

			hookPrompt(
				object
			)

			updatePrompt(
				object
			)
		end
	end
end

--==================================================
-- NEW PROMPTS
--==================================================

world.DescendantAdded:Connect(
	function(object)

		if
			object:IsA(
				"ProximityPrompt"
			)
			and
			(
				object.Name
					== "PlantPrompt"

				or
				object.Name
					== "HarvestPrompt"

				or
				object.Name
					== "DigPrompt"
			)
		then

			task.defer(
				function()

					hookPrompt(
						object
					)

				end
			)
		end
	end
)

--==================================================
-- CHARACTER
--==================================================

local function setupCharacter(
	character
)

	character.ChildAdded:Connect(
		function(object)

			if object:IsA(
				"Tool"
			) then

				task.defer(
					updateAllPrompts
				)

			end
		end
	)

	character.ChildRemoved:Connect(
		function(object)

			if object:IsA(
				"Tool"
			) then

				task.defer(
					updateAllPrompts
				)

			end
		end
	)

	task.defer(
		updateAllPrompts
	)
end

if player.Character then

	setupCharacter(
		player.Character
	)

end

player.CharacterAdded:Connect(
	setupCharacter
)

player:GetAttributeChangedSignal(
	"PotatoBits"
):Connect(
	updateAllPrompts
)

task.defer(
	updateAllPrompts
)

print(
	"🌱⛏ Farming + foraging prompts ready"
)