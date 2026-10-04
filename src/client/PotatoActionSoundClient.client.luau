--==================================================
-- 🥔 POTATIUM POTATO ACTION SOUNDS
--
-- PLACE  = 125360182283760
-- REMOVE = 76905474546464
--
-- Client-only.
-- Does NOT modify potato logic.
-- Does NOT modify foraging.
--==================================================

local SoundService =
	game:GetService("SoundService")

local Workspace =
	game:GetService("Workspace")

local ContentProvider =
	game:GetService("ContentProvider")

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
	1

local REMOVE_VOLUME =
	1

--==================================================
-- CREATE SOUNDS
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
-- PRELOAD
--==================================================

task.spawn(
	function()

		local success,
			errorMessage =
				pcall(
					function()

						ContentProvider:PreloadAsync(
							{
								placeSound,
								removeSound,
							}
						)

					end
				)

		if success then

			print(
				"🔊 Potato sounds preloaded"
			)

		else

			warn(
				"⚠ Potato sound preload failed: "
					..
					tostring(
						errorMessage
					)
			)

		end

	end
)

--==================================================
-- PLAY
--==================================================

local function playPlaceSound()

	placeSound:Stop()

	placeSound.TimePosition =
		0

	placeSound:Play()

	print(
		"🔊 PLACE SOUND"
	)

end


local function playRemoveSound()

	removeSound:Stop()

	removeSound.TimePosition =
		0

	removeSound:Play()

	print(
		"🔊 REMOVE SOUND"
	)

end

--==================================================
-- CONNECTED PROMPTS
--==================================================

local connected =
	{}

local function connectPrompt(
	object
)

	if
		not object:IsA(
			"ProximityPrompt"
		)
	then

		return

	end

	if connected[
		object
	] then

		return

	end

	--==================================================
	-- PLACE
	--==================================================

	if
		object.Name
		==
		PLACE_PROMPT_NAME
	then

		connected[
			object
		] =
			true

		object.Triggered:Connect(
			function()

				playPlaceSound()

			end
		)

		print(
			"🔊 Connected PLACE sound: "
				..
				object:GetFullName()
		)

		return

	end

	--==================================================
	-- REMOVE
	--==================================================

	if
		object.Name
		==
		REMOVE_PROMPT_NAME
	then

		connected[
			object
		] =
			true

		object.Triggered:Connect(
			function()

				playRemoveSound()

			end
		)

		print(
			"🔊 Connected REMOVE sound: "
				..
				object:GetFullName()
		)

	end

end

--==================================================
-- EXISTING PROMPTS
--==================================================

for _, object in ipairs(
	Workspace:GetDescendants()
) do

	connectPrompt(
		object
	)

end

--==================================================
-- FUTURE PROMPTS
--==================================================

Workspace.DescendantAdded:Connect(
	function(
		object
	)

		if
			object:IsA(
				"ProximityPrompt"
			)
		then

			task.defer(
				function()

					if object.Parent then

						connectPrompt(
							object
						)

					end

				end
			)

		end

	end
)

--==================================================
-- CLEANUP
--==================================================

Workspace.DescendantRemoving:Connect(
	function(
		object
	)

		if connected[
			object
		] then

			connected[
				object
			] =
				nil

		end

	end
)

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("🔊 POTATO ACTION SOUNDS READY")
print("========================================")
print("🥔 Place = 125360182283760")
print("↩ Remove = 76905474546464")
print("✅ Potato logic untouched")
print("✅ Foraging untouched")
print("========================================")
print("")