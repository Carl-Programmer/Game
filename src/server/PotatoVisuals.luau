local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

local PotatoVisuals = {}

--==================================================
-- POTATO VISUALS V8 - MEADOW MODEL COMPATIBILITY
--
-- ✅ Rainbow animation fixed
-- ✅ Waits until potato is actually parented
-- ✅ Rainbow works when held
-- ✅ Rainbow works when placed
-- ✅ Super shiny gold
-- ✅ 25% bigger
-- ✅ Basic_Potato1 / Basic_Potato2
-- ✅ Fresh coordinates
-- ✅ Prevents old teleport / drag bug
--==================================================

local RNG =
	Random.new()

--==================================================
-- SIZE
--==================================================

local SIZE_MULTIPLIER =
	1.25

--==================================================
-- SOURCE
--==================================================

local potatoModels =
	ReplicatedStorage:WaitForChild(
		"PotatoModels"
	)

local basicPotato =
	potatoModels:WaitForChild(
		"BasicPotato"
	)

local variant1 =
	basicPotato:WaitForChild(
		"Basic_Potato1"
	)

local variant2 =
	basicPotato:WaitForChild(
		"Basic_Potato2"
	)

--==================================================
-- NEW MEADOW POTATO MODELS
--
-- ReplicatedStorage
-- └── newpotatoes
--     ├── basic_potato
--     ├── big_potato
--     ├── butter_potato
--     ├── feather_potato
--     ├── flower_potato
--     ├── golden_potato
--     ├── grass_potato
--     ├── lucky_potato
--     ├── prism_potato
--     ├── star_potato
--     └── sunkissed_potato
--
-- These models keep their own appearance.
--==================================================

local newPotatoes =
	ReplicatedStorage:WaitForChild(
		"newpotatoes"
	)

local NEW_MEADOW_MODELS = {
	Basic = "basic_potato",
	Big = "big_potato",
	Butter = "butter_potato",
	Feather = "feather_potato",
	Flower = "flower_potato",
	Golden = "golden_potato",
	Grass = "grass_potato",
	Lucky = "lucky_potato",
	Prism = "prism_potato",
	Star = "star_potato",
	Sunkissed = "sunkissed_potato",
}

local function normalizeMeadowType(value)
	if value == nil then
		return nil
	end

	local name =
		tostring(value)

	name =
		string.lower(name)

	name =
		string.gsub(
			name,
			"[%s%-]+",
			"_"
		)

	name =
		string.gsub(
			name,
			"_+",
			"_"
		)

	if
		string.sub(name, -7)
		==
		"_potato"
	then
		name =
			string.sub(
				name,
				1,
				-8
			)
	end

	for meadowType, modelName in pairs(
		NEW_MEADOW_MODELS
	) do
		local normalizedModel =
			string.lower(
				string.gsub(
					modelName,
					"_potato",
					""
				)
			)

		if
			name
			==
			normalizedModel
			or
			name
			==
			string.lower(meadowType)
			or
			name
			==
			string.lower(
				string.gsub(
					modelName,
					"_",
					""
				)
			)
		then
			return meadowType
		end
	end

	return nil
end

local function getMeadowSource(
	meadowType
)
	local modelName =
		NEW_MEADOW_MODELS[
			meadowType
		]

	if not modelName then
		return nil
	end

	local source =
		newPotatoes:FindFirstChild(
			modelName
		)

	if
		not source
	then
		warn(
			"❌ Missing Meadow potato model: "
				..
				modelName
		)
		return nil
	end

	if
		not source:IsA("Model")
	then
		warn(
			"❌ Meadow potato is not a Model: "
				..
				modelName
		)
		return nil
	end

	return source
end

--==================================================
-- COLORS
--==================================================

local STYLES = {

	Common = {

		Main =
			Color3.fromRGB(
				190,
				150,
				92
			),

		Dark =
			Color3.fromRGB(
				150,
				108,
				62
			),

		Light =
			Color3.fromRGB(
				220,
				180,
				112
			),
	},

	Rare = {

		Main =
			Color3.fromRGB(
				72,
				194,
				84
			),

		Dark =
			Color3.fromRGB(
				39,
				128,
				50
			),

		Light =
			Color3.fromRGB(
				107,
				224,
				115
			),
	},

	Epic = {

		Main =
			Color3.fromRGB(
				68,
				142,
				238
			),

		Dark =
			Color3.fromRGB(
				39,
				88,
				174
			),

		Light =
			Color3.fromRGB(
				103,
				177,
				255
			),
	},

	Exotic = {

		Main =
			Color3.fromRGB(
				168,
				77,
				224
			),

		Dark =
			Color3.fromRGB(
				107,
				40,
				160
			),

		Light =
			Color3.fromRGB(
				201,
				113,
				248
			),
	},

	Legendary = {

		Main =
			Color3.fromRGB(
				255,
				220,
				54
			),

		Dark =
			Color3.fromRGB(
				202,
				149,
				21
			),

		Light =
			Color3.fromRGB(
				255,
				241,
				112
			),
	},

	Super = {

		Main =
			Color3.fromRGB(
				255,
				205,
				35
			),

		Dark =
			Color3.fromRGB(
				207,
				142,
				15
			),

		Light =
			Color3.fromRGB(
				255,
				244,
				134
			),

		Super =
			true,
	},

	Rainbow = {

		Rainbow =
			true,
	},

}

--==================================================
-- GET SOURCE PARTS
--==================================================

local function getSourceParts(
	model
)

	local parts = {}

	for _, object in ipairs(
		model:GetDescendants()
	) do

		if
			object:IsA(
				"BasePart"
			)
		then

			table.insert(
				parts,
				object
			)

		end

	end

	return parts

end

--==================================================
-- CLEAN OLD WELDS / SCRIPTS
--==================================================

local function cleanPart(
	part
)

	for _, object in ipairs(
		part:GetDescendants()
	) do

		if
			object:IsA(
				"WeldConstraint"
			)
			or
			object:IsA(
				"Weld"
			)
			or
			object:IsA(
				"Motor6D"
			)
			or
			object:IsA(
				"Script"
			)
			or
			object:IsA(
				"LocalScript"
			)
			or
			object:IsA(
				"ModuleScript"
			)
		then

			object:Destroy()

		end

	end

end

--==================================================
-- BUILD FRESH GEOMETRY
--==================================================

local function buildFreshGeometry(
	source,
	outputModel,
	extraScale
)

	local sourceCF =
		source:GetBoundingBox()

	local additionalScale =
		tonumber(extraScale)
		or
		1

	if additionalScale <= 0 then
		additionalScale = 1
	end

	local totalScale =
		SIZE_MULTIPLIER
		*
		additionalScale

	local sourceParts =
		getSourceParts(
			source
		)

	if #sourceParts == 0 then

		warn(
			"❌ No potato parts inside "
				..
				source.Name
		)

		return {}

	end

	local newParts = {}

	for _, sourcePart in ipairs(
		sourceParts
	) do

		local relativeCF =
			sourceCF:ToObjectSpace(
				sourcePart.CFrame
			)

		local rx,
			ry,
			rz =
				relativeCF:ToOrientation()

		local relativePosition =
			relativeCF.Position
			*
			totalScale

		local clone =
			sourcePart:Clone()

		cleanPart(
			clone
		)

		clone.Name =
			"PotatoPart"

		clone.Size =
			sourcePart.Size
			*
			totalScale

		clone.CFrame =
			CFrame.new(
				relativePosition
			)
			*
			CFrame.fromOrientation(
				rx,
				ry,
				rz
			)

		clone.Anchored =
			false

		clone.CanCollide =
			false

		clone.CanTouch =
			false

		clone.CanQuery =
			false

		clone.Massless =
			true

		clone.Parent =
			outputModel

		table.insert(
			newParts,
			clone
		)

	end

	return newParts

end

--==================================================
-- SHUFFLE
--==================================================

local function shuffle(
	array
)

	for i = #array, 2, -1 do

		local j =
			RNG:NextInteger(
				1,
				i
			)

		array[i],
			array[j] =
			array[j],
			array[i]

	end

end

--==================================================
-- NORMAL STYLE
--==================================================

local function applyNormalStyle(
	parts,
	style
)

	local shuffled = {}

	for _, part in ipairs(
		parts
	) do

		table.insert(
			shuffled,
			part
		)

	end

	shuffle(
		shuffled
	)

	for index, part in ipairs(
		shuffled
	) do

		local shade =
			(index - 1)
			%
			3

		if shade == 0 then

			part.Color =
				style.Main

		elseif shade == 1 then

			part.Color =
				style.Dark

		else

			part.Color =
				style.Light

		end

	end

end

--==================================================
-- SUPER
--==================================================

local function applySuperStyle(
	parts,
	style
)

	applyNormalStyle(
		parts,
		style
	)

	for _, part in ipairs(
		parts
	) do

		part.Material =
			Enum.Material.Metal

		part.Reflectance =
			0.25

	end

end

--==================================================
-- RAINBOW
--
-- FIX:
-- Wait for Model.Parent before animation starts.
--==================================================

local function startRainbow(
	model,
	parts
)

	local startingOffset =
		RNG:NextNumber(
			0,
			1
		)

	task.spawn(
		function()

			--==================================================
			-- WAIT FOR POTATO TO ENTER TOOL / WORKSPACE
			--==================================================

			local waitTime =
				0

			while
				model
				and
				model.Parent
				==
				nil
				and
				waitTime
				<
				10
			do

				task.wait(
					0.05
				)

				waitTime +=
					0.05

			end

			-- If it was never parented, stop.

			if
				not model
				or
				model.Parent
				==
				nil
			then

				return

			end

			--==================================================
			-- PREPARE PARTS
			--==================================================

			for _, part in ipairs(
				parts
			) do

				if part.Parent then

					part.Material =
						Enum.Material.Neon

				end

			end

			--==================================================
			-- ANIMATE
			--==================================================

			while
				model
				and
				model.Parent
			do

				local baseHue =
					(
						os.clock()
						*
						0.20
						+
						startingOffset
					)
					%
					1

				for index, part in ipairs(
					parts
				) do

					if
						part
						and
						part.Parent
					then

						local hue =
							(
								baseHue
								+
								(index - 1)
								*
								0.10
							)
							%
							1

						part.Color =
							Color3.fromHSV(
								hue,
								0.95,
								1
							)

					end

				end

				task.wait(
					0.08
				)

			end

		end
	)

end

--==================================================
-- HANDLE
--==================================================

local function createHandle(
	model
)

	local boundingCF =
		model:GetBoundingBox()

	local handle =
		Instance.new(
			"Part"
		)

	handle.Name =
		"Handle"

	handle.Size =
		Vector3.new(
			0.2,
			0.2,
			0.2
		)

	handle.CFrame =
		boundingCF

	handle.Transparency =
		1

	handle.Anchored =
		false

	handle.CanCollide =
		false

	handle.CanTouch =
		false

	handle.CanQuery =
		false

	handle.Massless =
		true

	handle.Parent =
		model

	model.PrimaryPart =
		handle

	return handle

end

--==================================================
-- WELD
--==================================================

local function weldParts(
	parts,
	handle
)

	for _, part in ipairs(
		parts
	) do

		local weld =
			Instance.new(
				"WeldConstraint"
			)

		weld.Name =
			"PotatoWeld"

		weld.Part0 =
			handle

		weld.Part1 =
			part

		weld.Parent =
			part

	end

end

--==================================================
-- CREATE MODEL
--==================================================

function PotatoVisuals.CreateModel(
	rarityName,
	anchored,
	visualScale
)

	rarityName =
		rarityName
		or
		"Common"

	local meadowType =
		normalizeMeadowType(
			rarityName
		)

	local style = nil
	local source = nil
	local variantNumber = 0
	local isNewMeadowPotato =
		meadowType ~= nil

	if isNewMeadowPotato then

		--==================================================
		-- NEW MEADOW POTATO
		--
		-- Uses the exact model from ReplicatedStorage.newpotatoes.
		-- Its own colors/materials are preserved.
		--==================================================

		source =
			getMeadowSource(
				meadowType
			)

		if not source then
			return nil
		end

		rarityName =
			meadowType
			..
			" Potato"

	else

		--==================================================
		-- OLD RARITY SYSTEM
		--
		-- Kept intact for existing farm potatoes and
		-- compatibility with old saved records.
		--==================================================

		style =
			STYLES[
				rarityName
			]

		if not style then

			warn(
				"❌ Unknown potato rarity: "
					..
					tostring(
						rarityName
					)
			)

			rarityName =
				"Common"

			style =
				STYLES.Common

		end

		--==================================================
		-- RANDOM COMPLETE OLD VARIANT
		--==================================================

		variantNumber =
			RNG:NextInteger(
				1,
				2
			)

		if
			variantNumber
			==
			1
		then

			source =
				variant1

		else

			source =
				variant2

		end

	end

	--==================================================
	-- NEW MODEL
	--==================================================

	local model =
		Instance.new(
			"Model"
		)

	if isNewMeadowPotato then

		model.Name =
			rarityName
			..
			"Model"

	else

		model.Name =
			rarityName
			..
			"PotatoModel"

	end

	local parts =
		buildFreshGeometry(
			source,
			model,
			visualScale
		)

	if #parts == 0 then

		model:Destroy()

		return nil

	end

	--==================================================
	-- STYLE
	--==================================================

	if isNewMeadowPotato then

		-- New Meadow models already contain their intended
		-- appearance, so DO NOT recolor them with rarity styles.

	elseif style.Super then

		applySuperStyle(
			parts,
			style
		)

	elseif not style.Rainbow then

		applyNormalStyle(
			parts,
			style
		)

	end

	--==================================================
	-- HANDLE
	--==================================================

	local handle =
		createHandle(
			model
		)

	weldParts(
		parts,
		handle
	)

	--==================================================
	-- PLACED / HELD
	--==================================================

	if anchored == true then

		handle.Anchored =
			true

		for _, part in ipairs(
			parts
		) do

			part.Anchored =
				true

		end

	end

	--==================================================
	-- ATTRIBUTES
	--==================================================

	if isNewMeadowPotato then

		model:SetAttribute(
			"Rarity",
			nil
		)

		model:SetAttribute(
			"PotatoType",
			meadowType
		)

		model:SetAttribute(
			"MeadowModelName",
			NEW_MEADOW_MODELS[
				meadowType
			]
		)

		model:SetAttribute(
			"PotatoVariant",
			0
		)

	else

		model:SetAttribute(
			"Rarity",
			rarityName
		)

		model:SetAttribute(
			"PotatoVariant",
			variantNumber
		)

	end

	model:SetAttribute(
		"SizeMultiplier",
		SIZE_MULTIPLIER
		*
		(
			tonumber(
				visualScale
			)
			or
			1
		)
	)

	--==================================================
	-- RAINBOW
	--==================================================

	if
		style
		and
		style.Rainbow
	then

		startRainbow(
			model,
			parts
		)

	end

	return model

end

--==================================================
-- ATTACH TO TOOL
--==================================================

function PotatoVisuals.AttachToTool(
	tool,
	rarityName,
	visualScale
)

	local model =
		PotatoVisuals.CreateModel(
			rarityName,
			false,
			visualScale
		)

	if not model then

		return false

	end

	model.Name =
		"PotatoVisual"

	model.Parent =
		tool

	local handle =
		model:FindFirstChild(
			"Handle"
		)

	if
		not handle
		or
		not handle:IsA(
			"BasePart"
		)
	then

		model:Destroy()

		return false

	end

	handle.Parent =
		tool

	handle.Name =
		"Handle"

	handle.Transparency =
		1

	handle.Anchored =
		false

	handle.CanCollide =
		false

	handle.CanTouch =
		false

	handle.CanQuery =
		false

	handle.Massless =
		true

	tool.RequiresHandle =
		true

	tool.CanBeDropped =
		false

	tool.Grip =
		CFrame.new(
			0,
			-0.35,
			-0.45
		)
		*
		CFrame.Angles(
			math.rad(-15),
			math.rad(30),
			0
		)

	return true

end

--==================================================
-- READY
--==================================================

print("")
print("========================================")
print("🥔 POTATO VISUALS V8 READY")
print("========================================")
print("✅ Size = 125%")
print("✅ Legacy rarity visuals preserved")
print("✅ Super shiny gold preserved")
print("🌈 Rainbow animation FIXED")
print("🌈 Held Rainbow changes color")
print("🌈 Placed Rainbow changes color")
print("✅ Teleport / drag protection")
print("✅ New Meadow models connected")
print("✅ Basic / Big / Butter / Feather / Flower")
print("✅ Golden / Grass / Lucky / Prism / Star / Sunkissed")
print("✅ Meadow models keep their own appearance")
print("✅ Optional KG visual scaling supported")
print("========================================")
print("")

return PotatoVisuals