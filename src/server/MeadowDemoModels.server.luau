--========================================================
-- 🥔 POTATIUM - MEADOW DEMO POTATO MODELS V1
--
-- TEMPORARY MODELS ONLY.
--
-- These let us build/test the Meadow system before
-- the final potato designs are finished.
--
-- Later we can replace these models without changing
-- MeadowPool or the RNG system.
--========================================================

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

--========================================================
-- FOLDERS
--========================================================

local potatoModels =
	ReplicatedStorage:FindFirstChild(
		"PotatoModels"
	)

if not potatoModels then

	potatoModels =
		Instance.new("Folder")

	potatoModels.Name =
		"PotatoModels"

	potatoModels.Parent =
		ReplicatedStorage
end

local meadowFolder =
	potatoModels:FindFirstChild(
		"Meadow"
	)

if not meadowFolder then

	meadowFolder =
		Instance.new("Folder")

	meadowFolder.Name =
		"Meadow"

	meadowFolder.Parent =
		potatoModels
end

--========================================================
-- COLORS
--========================================================

local BROWN =
	Color3.fromRGB(
		150,
		99,
		57
	)

local DARK_BROWN =
	Color3.fromRGB(
		91,
		56,
		31
	)

local LIGHT_BROWN =
	Color3.fromRGB(
		190,
		139,
		80
	)

local SWEET_ORANGE =
	Color3.fromRGB(
		190,
		82,
		40
	)

local GREEN =
	Color3.fromRGB(
		84,
		148,
		60
	)

local LIGHT_GREEN =
	Color3.fromRGB(
		105,
		190,
		70
	)

local CREAM =
	Color3.fromRGB(
		222,
		190,
		132
	)

local WHITE =
	Color3.fromRGB(
		240,
		240,
		235
	)

local BUTTER =
	Color3.fromRGB(
		255,
		215,
		91
	)

local SUN =
	Color3.fromRGB(
		255,
		174,
		38
	)

--========================================================
-- BASIC PART
--========================================================

local function makePart(
	parent,
	name,
	size,
	cframe,
	color,
	material
)

	local part =
		Instance.new("Part")

	part.Name =
		name

	part.Size =
		size

	part.CFrame =
		cframe

	part.Color =
		color

	part.Material =
		material
		or
		Enum.Material.SmoothPlastic

	part.Anchored =
		true

	part.CanCollide =
		false

	part.CanTouch =
		false

	part.CanQuery =
		false

	part.TopSurface =
		Enum.SurfaceType.Smooth

	part.BottomSurface =
		Enum.SurfaceType.Smooth

	part.Parent =
		parent

	return part
end

--========================================================
-- OVAL POTATO BODY
--========================================================

local function makePotatoBody(
	model,
	color,
	scale
)

	scale =
		scale
		or
		Vector3.new(
			1,
			1,
			1
		)

	local body =
		makePart(
			model,

			"Root",

			Vector3.new(
				2,
				2,
				2
			),

			CFrame.new(),

			color,

			Enum.Material.SmoothPlastic
		)

	local mesh =
		Instance.new("SpecialMesh")

	mesh.MeshType =
		Enum.MeshType.Sphere

	mesh.Scale =
		Vector3.new(
			2.5 * scale.X,
			1.8 * scale.Y,
			1.9 * scale.Z
		)

	mesh.Parent =
		body

	model.PrimaryPart =
		body

	return body
end

--========================================================
-- SMALL POTATO EYE
--========================================================

local function makeEye(
	model,
	position,
	size
)

	return makePart(
		model,

		"PotatoEye",

		size
		or
		Vector3.new(
			0.25,
			0.18,
			0.2
		),

		CFrame.new(
			position
		),

		DARK_BROWN,

		Enum.Material.SmoothPlastic
	)
end

--========================================================
-- MODEL CREATOR
--========================================================

local function createModel(
	name
)

	local old =
		meadowFolder:FindFirstChild(
			name
		)

	-- only destroy our old temporary model
	if
		old
		and
		old:GetAttribute("DemoModel") == true
	then

		old:Destroy()

	elseif old then

		-- A real model already exists.
		-- DO NOT overwrite it.
		return nil
	end

	local model =
		Instance.new("Model")

	model.Name =
		name

	model:SetAttribute(
		"DemoModel",
		true
	)

	model:SetAttribute(
		"PotatoName",
		name
	)

	model.Parent =
		meadowFolder

	return model
end

--========================================================
-- NORMAL POTATO
--========================================================

do

	local model =
		createModel(
			"Normal Potato"
		)

	if model then

		makePotatoBody(
			model,
			BROWN
		)

		makeEye(
			model,
			Vector3.new(
				0.6,
				0.55,
				-0.8
			)
		)

		makeEye(
			model,
			Vector3.new(
				-0.7,
				0.3,
				-0.85
			)
		)

		makeEye(
			model,
			Vector3.new(
				0,
				-0.5,
				-0.95
			)
		)
	end
end

--========================================================
-- TINY POTATO
--========================================================

do

	local model =
		createModel(
			"Tiny Potato"
		)

	if model then

		makePotatoBody(
			model,

			LIGHT_BROWN,

			Vector3.new(
				0.6,
				0.6,
				0.6
			)
		)

		makeEye(
			model,
			Vector3.new(
				0.25,
				0.2,
				-0.5
			),

			Vector3.new(
				0.15,
				0.12,
				0.12
			)
		)

		makeEye(
			model,
			Vector3.new(
				-0.3,
				-0.15,
				-0.5
			),

			Vector3.new(
				0.15,
				0.12,
				0.12
			)
		)
	end
end

--========================================================
-- GRASS POTATO
--========================================================

do

	local model =
		createModel(
			"Grass Potato"
		)

	if model then

		makePotatoBody(
			model,
			BROWN
		)

		makePart(
			model,

			"Grass1",

			Vector3.new(
				0.22,
				1.4,
				0.22
			),

			CFrame.new(
				-0.35,
				1.45,
				0
			)
			*
			CFrame.Angles(
				0,
				0,
				math.rad(-18)
			),

			GREEN,

			Enum.Material.Grass
		)

		makePart(
			model,

			"Grass2",

			Vector3.new(
				0.22,
				1.7,
				0.22
			),

			CFrame.new(
				0,
				1.6,
				0
			),

			LIGHT_GREEN,

			Enum.Material.Grass
		)

		makePart(
			model,

			"Grass3",

			Vector3.new(
				0.22,
				1.25,
				0.22
			),

			CFrame.new(
				0.38,
				1.35,
				0
			)
			*
			CFrame.Angles(
				0,
				0,
				math.rad(20)
			),

			GREEN,

			Enum.Material.Grass
		)
	end
end

--========================================================
-- SWEET POTATO
--========================================================

do

	local model =
		createModel(
			"Sweet Potato"
		)

	if model then

		makePotatoBody(
			model,

			SWEET_ORANGE,

			Vector3.new(
				1.25,
				0.85,
				0.85
			)
		)

		makeEye(
			model,
			Vector3.new(
				0.75,
				0.35,
				-0.85
			)
		)

		makeEye(
			model,
			Vector3.new(
				-0.8,
				0,
				-0.85
			)
		)

		makeEye(
			model,
			Vector3.new(
				0,
				-0.4,
				-0.9
			)
		)
	end
end

--========================================================
-- FEATHER POTATO
--========================================================

do

	local model =
		createModel(
			"Feather Potato"
		)

	if model then

		makePotatoBody(
			model,
			CREAM
		)

		local feather1 =
			Instance.new("WedgePart")

		feather1.Name =
			"Feather1"

		feather1.Size =
			Vector3.new(
				0.35,
				1.5,
				0.7
			)

		feather1.CFrame =
			CFrame.new(
				-0.75,
				1.4,
				0
			)
			*
			CFrame.Angles(
				0,
				0,
				math.rad(-25)
			)

		feather1.Color =
			WHITE

		feather1.Material =
			Enum.Material.SmoothPlastic

		feather1.Anchored =
			true

		feather1.CanCollide =
			false

		feather1.Parent =
			model

		local feather2 =
			feather1:Clone()

		feather2.Name =
			"Feather2"

		feather2.CFrame =
			CFrame.new(
				0.75,
				1.3,
				0
			)
			*
			CFrame.Angles(
				0,
				math.rad(180),
				math.rad(25)
			)

		feather2.Parent =
			model
	end
end

--========================================================
-- BUTTER POTATO
--========================================================

do

	local model =
		createModel(
			"Butter Potato"
		)

	if model then

		makePotatoBody(
			model,
			LIGHT_BROWN
		)

		makePart(
			model,

			"Butter",

			Vector3.new(
				1.15,
				0.35,
				0.85
			),

			CFrame.new(
				0,
				1.2,
				0
			),

			BUTTER,

			Enum.Material.SmoothPlastic
		)

		makePart(
			model,

			"ButterDrip",

			Vector3.new(
				0.28,
				0.65,
				0.28
			),

			CFrame.new(
				0.35,
				0.85,
				-0.65
			),

			BUTTER,

			Enum.Material.SmoothPlastic
		)
	end
end

--========================================================
-- LUCKY POTATO
--========================================================

do

	local model =
		createModel(
			"Lucky Potato"
		)

	if model then

		makePotatoBody(
			model,
			BROWN
		)

		local positions = {

			Vector3.new(
				0,
				0.45,
				-1.05
			),

			Vector3.new(
				0.38,
				0.1,
				-1.05
			),

			Vector3.new(
				0,
				-0.25,
				-1.05
			),

			Vector3.new(
				-0.38,
				0.1,
				-1.05
			),
		}

		for i, position in ipairs(
			positions
		) do

			local leaf =
				makePart(
					model,

					"LuckyLeaf"
						..
						i,

					Vector3.new(
						0.5,
						0.5,
						0.16
					),

					CFrame.new(
						position
					),

					LIGHT_GREEN,

					Enum.Material.SmoothPlastic
				)

			local mesh =
				Instance.new("SpecialMesh")

			mesh.MeshType =
				Enum.MeshType.Sphere

			mesh.Scale =
				Vector3.new(
					1,
					1,
					0.4
				)

			mesh.Parent =
				leaf
		end
	end
end

--========================================================
-- BIG POTATO
--========================================================

do

	local model =
		createModel(
			"Big Potato"
		)

	if model then

		makePotatoBody(
			model,

			BROWN,

			Vector3.new(
				1.55,
				1.45,
				1.45
			)
		)

		makeEye(
			model,
			Vector3.new(
				1,
				0.7,
				-1.25
			),

			Vector3.new(
				0.4,
				0.3,
				0.3
			)
		)

		makeEye(
			model,
			Vector3.new(
				-1,
				0.1,
				-1.3
			),

			Vector3.new(
				0.4,
				0.3,
				0.3
			)
		)

		makeEye(
			model,
			Vector3.new(
				0,
				-0.8,
				-1.35
			),

			Vector3.new(
				0.4,
				0.3,
				0.3
			)
		)
	end
end

--========================================================
-- CLOVER POTATO
--========================================================

do

	local model =
		createModel(
			"Clover Potato"
		)

	if model then

		makePotatoBody(
			model,
			BROWN
		)

		local positions = {

			Vector3.new(
				0,
				1.25,
				0
			),

			Vector3.new(
				0.55,
				1,
				0
			),

			Vector3.new(
				0,
				0.75,
				0
			),

			Vector3.new(
				-0.55,
				1,
				0
			),
		}

		for i, position in ipairs(
			positions
		) do

			local leaf =
				makePart(
					model,

					"CloverLeaf"
						..
						i,

					Vector3.new(
						0.65,
						0.65,
						0.25
					),

					CFrame.new(
						position
					),

					GREEN,

					Enum.Material.SmoothPlastic
				)

			local mesh =
				Instance.new("SpecialMesh")

			mesh.MeshType =
				Enum.MeshType.Sphere

			mesh.Scale =
				Vector3.new(
					1,
					1,
					0.5
				)

			mesh.Parent =
				leaf
		end
	end
end

--========================================================
-- SUN-KISSED POTATO
--========================================================

do

	local model =
		createModel(
			"Sun-Kissed Potato"
		)

	if model then

		local body =
			makePotatoBody(
				model,
				SUN
			)

		body.Material =
			Enum.Material.SmoothPlastic

		local sunCore =
			makePart(
				model,

				"SunCore",

				Vector3.new(
					0.55,
					0.55,
					0.18
				),

				CFrame.new(
					0,
					0.1,
					-1.05
				),

				Color3.fromRGB(
					255,
					220,
					70
				),

				Enum.Material.Neon
			)

		local coreMesh =
			Instance.new("SpecialMesh")

		coreMesh.MeshType =
			Enum.MeshType.Sphere

		coreMesh.Scale =
			Vector3.new(
				1,
				1,
				0.4
			)

		coreMesh.Parent =
			sunCore

		for i = 1, 3 do

			local angle =
				math.rad(
					(i - 1)
						*
						120
				)

			local x =
				math.cos(angle)
				*
				0.65

			local y =
				math.sin(angle)
				*
				0.65

			makePart(
				model,

				"SunRay"
					..
					i,

				Vector3.new(
					0.15,
					0.5,
					0.15
				),

				CFrame.new(
					x,
					y + 0.1,
					-1.12
				)
				*
				CFrame.Angles(
					0,
					0,
					-angle
				),

				Color3.fromRGB(
					255,
					225,
					80
				),

				Enum.Material.Neon
			)
		end
	end
end

--========================================================
-- DONE
--========================================================

print("")
print("======================================")
print("🌿 MEADOW DEMO POTATO MODELS READY")
print("======================================")
print("✅ Normal Potato")
print("✅ Tiny Potato")
print("✅ Grass Potato")
print("✅ Sweet Potato")
print("✅ Feather Potato")
print("✅ Butter Potato")
print("✅ Lucky Potato")
print("✅ Big Potato")
print("✅ Clover Potato")
print("✅ Sun-Kissed Potato")
print("======================================")
print("")