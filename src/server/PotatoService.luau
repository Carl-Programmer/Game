local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local PotatoService = {}

local SpudMassService =
	require(
		script.Parent:WaitForChild(
			"SpudMassService"
		)
	)

--==================================================
-- CONFIG
--==================================================

local STAGE_1_TIME = 4
local STAGE_2_TIME = 5
local STAGE_3_TIME = 5

local REGROW_TIME = 6

local HARVESTS_PER_BIT = 3

local MIN_YIELD = 2
local MAX_YIELD = 5

--==================================================
-- SERVICES PASSED FROM INIT
--==================================================

local DataService

local world
local farmsFolder

--==================================================
-- INVENTORY ATTRIBUTES
--==================================================

local INVENTORY_ATTRIBUTES = {

	Trash =
		"TrashPotatoes",

	Normal =
		"NormalPotatoes",

	AboveNormal =
		"AboveNormalPotatoes",

	Huge =
		"HugePotatoes",

	UltraHuge =
		"UltraHugePotatoes",

	SuperHuge =
		"SuperHugePotatoes",

	Godly =
		"GodlyPotatoes",
}

--==================================================
-- TASK TOKENS
--==================================================

local pointTokens = {}

local seedGenerator =
	Random.new()

local function newToken(
	point
)

	local token =
		(pointTokens[
			point
		] or 0)
		+ 1

	pointTokens[
		point
	] =
		token

	return token
end

local function tokenValid(
	point,
	token
)

	return
		point.Parent ~= nil
		and
		pointTokens[
			point
		] == token
end

--==================================================
-- EQUIPPED TOOL
--==================================================

local function hasEquippedTool(
	player,
	toolType
)

	local character =
		player.Character

	if not character then
		return false
	end

	for _, object in ipairs(
		character:GetChildren()
	) do

		if
			object:IsA("Tool")
			and
			object:GetAttribute(
				"FarmingToolType"
			) == toolType
		then

			return true

		end
	end

	return false
end

--==================================================
-- TWEEN
--==================================================

local function tweenPart(
	part,
	duration,
	properties,
	style
)

	if not part
		or
		not part.Parent
	then

		return
	end

	local tween =
		TweenService:Create(
			part,

			TweenInfo.new(
				duration,
				style
					or
					Enum.EasingStyle.Quad,

				Enum.EasingDirection.Out
			),

			properties
		)

	tween:Play()

	return tween
end

--==================================================
-- CREATE PART
--==================================================

local function createPart(
	parent,
	name,
	size,
	position,
	color,
	material
)

	local part =
		Instance.new("Part")

	part.Name =
		name

	part.Size =
		size

	part.Position =
		position

	part.Anchored =
		true

	part.CanCollide =
		false

	part.CanTouch =
		false

	part.CanQuery =
		true

	part.TopSurface =
		Enum.SurfaceType.Smooth

	part.BottomSurface =
		Enum.SurfaceType.Smooth

	part.Color =
		color

	part.Material =
		material
		or Enum.Material.SmoothPlastic

	part.Parent =
		parent

	return part
end

--==================================================
-- POINT KEY
--==================================================

local function getPointKey(
	point
)

	local plot =
		point.Parent

	if not plot then
		return nil
	end

	return
		plot.Name
		.. "/"
		.. point.Name
end

--==================================================
-- FIND POINT FROM SAVED KEY
--==================================================

local function findPointFromKey(
	farm,
	key
)

	local plotName,
		pointName =
			string.match(
				key,
				"^([^/]+)/(.+)$"
			)

	if not plotName
		or
		not pointName
	then

		return nil
	end

	local plots =
		farm:FindFirstChild(
			"PlantingPlots"
		)

	if not plots then
		return nil
	end

	local plot =
		plots:FindFirstChild(
			plotName
		)

	if not plot then
		return nil
	end

	return
		plot:FindFirstChild(
			pointName
		)
end

--==================================================
-- FIND FARM
--==================================================

local function getFarmFromPoint(
	point
)

	local current =
		point

	while current do

		if
			current:IsA("Model")
			and
			current:GetAttribute(
				"FarmNumber"
			) ~= nil
		then

			return current
		end

		current =
			current.Parent
	end

	return nil
end

--==================================================
-- OWNERSHIP
--==================================================

local function playerOwnsPoint(
	player,
	point
)

	local farm =
		getFarmFromPoint(
			point
		)

	if not farm then
		return false
	end

	return
		farm:GetAttribute(
			"OwnerUserId"
		)
		== player.UserId
end

--==================================================
-- CREATE PLANT POINTS
--==================================================

local function createPlantPoints(
	plot
)

	if plot:FindFirstChild(
		"PlantPoint_1"
	) then

		return
	end

	local offsets = {

		Vector3.new(
			-3.2,
			0.65,
			-4
		),

		Vector3.new(
			3.2,
			0.65,
			-4
		),

		Vector3.new(
			-3.2,
			0.65,
			4
		),

		Vector3.new(
			3.2,
			0.65,
			4
		),
	}

	for number, offset in ipairs(
		offsets
	) do

		local point =
			Instance.new("Part")

		point.Name =
			"PlantPoint_"
			.. number

		point.Size =
			Vector3.new(
				1.5,
				0.25,
				1.5
			)

		point.Transparency =
			1

		point.Anchored =
			true

		point.CanCollide =
			false

		point.CanTouch =
			false

		point.CanQuery =
			true

		point.CFrame =
			plot.CFrame
			* CFrame.new(
				offset.X,
				offset.Y,
				offset.Z
			)

		point.Parent =
			plot
	end
end

--==================================================
-- PLANT BASE
--==================================================

local function getPlantBase(
	point
)

	return
		point.Position
		+ Vector3.new(
			0,
			-0.28,
			0
		)
end

--==================================================
-- COLORS
--==================================================

local function getPalette(
	point
)

	local remaining =
		point:GetAttribute(
			"HarvestsRemaining"
		) or 3

	if remaining >= 3 then

		return {

			stem =
				Color3.fromRGB(
					55,
					125,
					48
				),

			leaf =
				Color3.fromRGB(
					70,
					154,
					61
				),

			potato =
				Color3.fromRGB(
					181,
					138,
					87
				),

			flower =
				Color3.fromRGB(
					255,
					236,
					255
				),
		}
	end

	if remaining == 2 then

		return {

			stem =
				Color3.fromRGB(
					100,
					137,
					76
				),

			leaf =
				Color3.fromRGB(
					134,
					174,
					108
				),

			potato =
				Color3.fromRGB(
					186,
					143,
					90
				),

			flower =
				Color3.fromRGB(
					255,
					229,
					245
				),
		}
	end

	return {

		stem =
			Color3.fromRGB(
				105,
				78,
				44
			),

		leaf =
			Color3.fromRGB(
				126,
				105,
				61
			),

		potato =
			Color3.fromRGB(
				169,
				123,
				73
			),

		flower =
			Color3.fromRGB(
				255,
				215,
				220
			),
	}
end

--==================================================
-- BATCH COUNTS
--==================================================

local function resetBatchCounts(
	point
)

	for tier in pairs(
		INVENTORY_ATTRIBUTES
	) do

		point:SetAttribute(
			"Batch_" .. tier,
			0
		)

	end
end

local function addBatchPotato(
	point,
	tier
)

	local attribute =
		"Batch_" .. tier

	point:SetAttribute(
		attribute,

		(point:GetAttribute(
			attribute
		) or 0)
		+ 1
	)
end

--==================================================
-- SPUD-MASS RNG
--==================================================

local function rollSpudMass(
	random
)

	return
		SpudMassService.Roll(
			random
		)

end

--==================================================
-- CLEAR PROMPTS
--==================================================

local function clearPrompts(
	point
)

	for _, name in ipairs({

		"PlantPrompt",
		"HarvestPrompt",

	}) do

		local prompt =
			point:FindFirstChild(
				name
			)

		if prompt then
			prompt:Destroy()
		end
	end
end

--==================================================
-- DESTROY PLANT
--==================================================

local function destroyWholePlant(
	point
)

	local plant =
		point:FindFirstChild(
			"PotatoPlant"
		)

	if plant then
		plant:Destroy()
	end
end

--==================================================
-- CLEAR HARVEST VISUALS
--==================================================

local function clearHarvestVisuals(
	point
)

	local plant =
		point:FindFirstChild(
			"PotatoPlant"
		)

	if not plant then
		return
	end

	local visuals =
		plant:FindFirstChild(
			"HarvestVisuals"
		)

	if not visuals then
		return
	end

	for _, object in ipairs(
		visuals:GetChildren()
	) do

		if object:IsA(
			"BasePart"
		) then

			tweenPart(
				object,
				0.2,

				{
					Transparency =
						1,

					Size =
						Vector3.new(
							0.05,
							0.05,
							0.05
						)
				}
			)

		end
	end

	task.delay(
		0.22,

		function()

			if visuals.Parent then
				visuals:Destroy()
			end

		end
	)
end

--==================================================
-- CREATE PERMANENT PLANT
--==================================================

local function createPermanentPlant(
	point
)

	local existing =
		point:FindFirstChild(
			"PotatoPlant"
		)

	if existing then
		return existing
	end

	local plant =
		Instance.new("Model")

	plant.Name =
		"PotatoPlant"

	plant.Parent =
		point

	local base =
		getPlantBase(
			point
		)

	createPart(
		plant,
		"Stem",

		Vector3.new(
			0.2,
			0.15,
			0.2
		),

		base
			+ Vector3.new(
				0,
				0.075,
				0
			),

		Color3.fromRGB(
			55,
			125,
			48
		)
	)

	local leaves = {

		{
			Vector3.new(
				0.7,
				0.95,
				0
			),

			Vector3.new(
				0,
				10,
				-18
			)
		},

		{
			Vector3.new(
				-0.7,
				1.18,
				0
			),

			Vector3.new(
				0,
				-20,
				18
			)
		},

		{
			Vector3.new(
				0,
				1.45,
				0.65
			),

			Vector3.new(
				15,
				55,
				0
			)
		},

		{
			Vector3.new(
				0,
				1.7,
				-0.65
			),

			Vector3.new(
				-10,
				110,
				0
			)
		},

		{
			Vector3.new(
				0.55,
				2,
				0.3
			),

			Vector3.new(
				0,
				160,
				-15
			)
		},

		{
			Vector3.new(
				-0.5,
				2.15,
				-0.25
			),

			Vector3.new(
				0,
				220,
				15
			)
		},
	}

	for index, info in ipairs(
		leaves
	) do

		local leaf =
			createPart(
				plant,

				"Leaf_"
					.. index,

				Vector3.new(
					0.1,
					0.05,
					0.1
				),

				base
					+ info[1],

				Color3.fromRGB(
					70,
					154,
					61
				)
			)

		leaf.Orientation =
			info[2]

		leaf.Transparency =
			1
	end

	return plant
end

--==================================================
-- GROW LEAF
--==================================================

local function growLeaf(
	leaf,
	color
)

	if not leaf then
		return
	end

	leaf.Transparency =
		0

	tweenPart(
		leaf,
		0.4,

		{
			Size =
				Vector3.new(
					1.1,
					0.22,
					0.75
				),

			Color =
				color
		},

		Enum.EasingStyle.Back
	)
end

--==================================================
-- APPLY GROWTH STAGE
--==================================================

local function applyGrowthStage(
	point,
	stage
)

	local plant =
		createPermanentPlant(
			point
		)

	local palette =
		getPalette(
			point
		)

	local base =
		getPlantBase(
			point
		)

	local stem =
		plant:FindFirstChild(
			"Stem"
		)

	if not stem then
		return
	end

	if stage == 1 then

		tweenPart(
			stem,
			0.5,

			{
				Size =
					Vector3.new(
						0.3,
						0.9,
						0.3
					),

				Position =
					base
					+ Vector3.new(
						0,
						0.45,
						0
					),

				Color =
					palette.stem
			}
		)

		for i = 1, 2 do

			growLeaf(
				plant:FindFirstChild(
					"Leaf_" .. i
				),

				palette.leaf
			)

		end

	elseif stage == 2 then

		tweenPart(
			stem,
			0.5,

			{
				Size =
					Vector3.new(
						0.42,
						1.7,
						0.42
					),

				Position =
					base
					+ Vector3.new(
						0,
						0.85,
						0
					),

				Color =
					palette.stem
			}
		)

		for i = 1, 4 do

			growLeaf(
				plant:FindFirstChild(
					"Leaf_" .. i
				),

				palette.leaf
			)

		end

	else

		tweenPart(
			stem,
			0.5,

			{
				Size =
					Vector3.new(
						0.5,
						2.55,
						0.5
					),

				Position =
					base
					+ Vector3.new(
						0,
						1.275,
						0
					),

				Color =
					palette.stem
			}
		)

		for i = 1, 6 do

			growLeaf(
				plant:FindFirstChild(
					"Leaf_" .. i
				),

				palette.leaf
			)

		end
	end
end

--==================================================
-- CREATE MATURE BATCH
--==================================================

local function createMatureBatch(
	point,
	seed
)

	clearHarvestVisuals(
		point
	)

	resetBatchCounts(
		point
	)

	local plant =
		createPermanentPlant(
			point
		)

	local visuals =
		Instance.new("Folder")

	visuals.Name =
		"HarvestVisuals"

	visuals.Parent =
		plant

	local random =
		Random.new(
			seed
		)

	local base =
		getPlantBase(
			point
		)

	local palette =
		getPalette(
			point
		)

	local yieldCount =
		random:NextInteger(
			MIN_YIELD,
			MAX_YIELD
		)

	point:SetAttribute(
		"CurrentYield",
		yieldCount
	)

	for index = 1, yieldCount do

		local massRoll =
			rollSpudMass(
				random
			)

		local tier =
			massRoll.SizeTier

		local finalSize =
			massRoll.VisualSize

		addBatchPotato(
			point,
			tier
		)

		local angle =
			(
				(index - 1)
				/
				yieldCount
			)
			* math.pi
			* 2

		angle +=
			random:NextNumber(
				-0.35,
				0.35
			)

		local radius =
			math.max(
				0.7,

				0.45
					+
					math.max(
						finalSize.X,
						finalSize.Z
					)
					* 0.43
			)

		local finalPosition =
			base
			+ Vector3.new(

				math.cos(angle)
					* radius,

				finalSize.Y
					* 0.32,

				math.sin(angle)
					* radius
			)

		local potato =
			createPart(
				visuals,

				"Potato_"
					.. index,

				Vector3.new(
					0.05,
					0.05,
					0.05
				),

				finalPosition,

				palette.potato
			)

		potato.Shape =
			Enum.PartType.Ball

		potato:SetAttribute(
			"PotatoType",
			"Normal"
		)

		potato:SetAttribute(
			"SpudMass",
			massRoll.SpudMass
		)

		potato:SetAttribute(
			"SizeTier",
			tier
		)

		potato:SetAttribute(
			"VisualScale",
			massRoll.VisualScale
		)

		potato:SetAttribute(
			"Mutation",
			"None"
		)

		potato.Orientation =
			Vector3.new(

				random:NextNumber(
					-25,
					25
				),

				random:NextNumber(
					0,
					180
				),

				random:NextNumber(
					-25,
					25
				)
			)

		tweenPart(
			potato,
			0.55,

			{
				Size =
					finalSize
			},

			Enum.EasingStyle.Back
		)
	end

	local flowerSize =
		random:NextNumber(
			0.55,
			0.8
		)

	local flower =
		createPart(
			visuals,

			"Flower",

			Vector3.new(
				0.05,
				0.05,
				0.05
			),

			base
				+ Vector3.new(
					0,
					2.85,
					0
				),

			palette.flower,

			Enum.Material.Neon
		)

	flower.Shape =
		Enum.PartType.Ball

	tweenPart(
		flower,
		0.5,

		{
			Size =
				Vector3.new(
					flowerSize,
					flowerSize,
					flowerSize
				)
		},

		Enum.EasingStyle.Back
	)
end

--==================================================
-- SAVE POINT STATE
--==================================================

local function persistPoint(
	player,
	point
)

	if not point:GetAttribute(
		"Occupied"
	) then

		DataService.RemovePlantState(
			player,
			getPointKey(
				point
			)
		)

		return
	end

	DataService.SetPlantState(
		player,

		getPointKey(
			point
		),

		{
			HarvestsRemaining =
				point:GetAttribute(
					"HarvestsRemaining"
				) or 0,

			Phase =
				point:GetAttribute(
					"GrowthPhase"
				)
				or
				"Growing1",

			PhaseEndAt =
				point:GetAttribute(
					"PhaseEndAt"
				)
				or
				os.time(),

			BatchSeed =
				point:GetAttribute(
					"BatchSeed"
				)
				or
				0,
		}
	)
end

--==================================================
-- GIVE BATCH TO PLAYER
--==================================================

local function giveBatchToPlayer(
	player,
	point
)

	local totalAdded =
		0

	local plant =
		point:FindFirstChild(
			"PotatoPlant"
		)

	if plant then

		local visuals =
			plant:FindFirstChild(
				"HarvestVisuals"
			)

		if visuals then

			for _, object in ipairs(
				visuals:GetChildren()
			) do

				if
					object:IsA("BasePart")
					and
					string.match(
						object.Name,
						"^Potato_"
					)
				then

					DataService.AddPotatoRecord(
						player,

						{
							PotatoType =
								object:GetAttribute(
									"PotatoType"
								)
								or "Normal",

							SpudMass =
								object:GetAttribute(
									"SpudMass"
								)
								or 0.40,

							SizeTier =
								object:GetAttribute(
									"SizeTier"
								)
								or "Normal",

							VisualScale =
								object:GetAttribute(
									"VisualScale"
								)
								or 1,

							Mutation =
								object:GetAttribute(
									"Mutation"
								)
								or "None",

							Source =
								"Farm",
						}
					)

					totalAdded += 1

				end
			end

		end
	end

	for tier, inventoryAttribute in pairs(
		INVENTORY_ATTRIBUTES
	) do

		local amount =
			point:GetAttribute(
				"Batch_" .. tier
			)
			or 0

		if amount > 0 then

			player:SetAttribute(
				inventoryAttribute,

				(player:GetAttribute(
					inventoryAttribute
				) or 0)
				+ amount
			)

		end
	end

	if totalAdded <= 0 then

		totalAdded =
			point:GetAttribute(
				"CurrentYield"
			)
			or 0

	end

	player:SetAttribute(
		"Potatoes",

		(player:GetAttribute(
			"Potatoes"
		) or 0)
		+ totalAdded
	)
end

local createPlantPrompt
local createHarvestPrompt
local resumePlant

--==================================================
-- HARVEST PROMPT
--==================================================

createHarvestPrompt =
	function(point)

		clearPrompts(
			point
		)

		local prompt =
			Instance.new(
				"ProximityPrompt"
			)

		prompt.Name =
			"HarvestPrompt"

		prompt.ActionText =
			"Harvest Potatoes"

		prompt.ObjectText =
			"Potato Plant"

		prompt.KeyboardKeyCode =
			Enum.KeyCode.E

		prompt.HoldDuration =
			0.25

		prompt.MaxActivationDistance =
			10

		prompt.RequiresLineOfSight =
			false

		prompt.ClickablePrompt =
			false

		prompt.Parent =
			point

		prompt.Triggered:Connect(
			function(player)

				if not hasEquippedTool(
					player,
					"Hoe"
				) then

					return
				end

				if not playerOwnsPoint(
					player,
					point
				) then

					return
				end

				if not point:GetAttribute(
					"ReadyToHarvest"
				) then

					return
				end

				point:SetAttribute(
					"ReadyToHarvest",
					false
				)

				prompt:Destroy()

				giveBatchToPlayer(
					player,
					point
				)

				clearHarvestVisuals(
					point
				)

				local remaining =
					point:GetAttribute(
						"HarvestsRemaining"
					) or 1

				remaining -= 1

				point:SetAttribute(
					"HarvestsRemaining",
					remaining
				)

				point:SetAttribute(
					"CurrentYield",
					0
				)

				resetBatchCounts(
					point
				)

				if remaining > 0 then

					point:SetAttribute(
						"GrowthPhase",
						"Regrowing"
					)

					point:SetAttribute(
						"PhaseEndAt",
						os.time()
							+
							REGROW_TIME
					)

					point:SetAttribute(
						"BatchSeed",
						0
					)

					persistPoint(
						player,
						point
					)

					resumePlant(
						player,
						point
					)

				else

					newToken(
						point
					)

					destroyWholePlant(
						point
					)

					point:SetAttribute(
						"Occupied",
						false
					)

					point:SetAttribute(
						"HarvestsRemaining",
						0
					)

					point:SetAttribute(
						"GrowthPhase",
						"Empty"
					)

					point:SetAttribute(
						"BatchSeed",
						0
					)

					DataService.RemovePlantState(
						player,
						getPointKey(
							point
						)
					)

					createPlantPrompt(
						point
					)
				end
			end
		)
	end

--==================================================
-- MAKE PLANT READY
--==================================================

local function makeReady(
	player,
	point
)

	local seed =
		point:GetAttribute(
			"BatchSeed"
		)
		or 0

	if seed == 0 then

		seed =
			seedGenerator:NextInteger(
				1,
				2000000000
			)

		point:SetAttribute(
			"BatchSeed",
			seed
		)

	end

	point:SetAttribute(
		"GrowthPhase",
		"Ready"
	)

	point:SetAttribute(
		"PhaseEndAt",
		0
	)

	applyGrowthStage(
		point,
		3
	)

	createMatureBatch(
		point,
		seed
	)

	point:SetAttribute(
		"ReadyToHarvest",
		true
	)

	persistPoint(
		player,
		point
	)

	createHarvestPrompt(
		point
	)
end

--==================================================
-- RESUME / OFFLINE GROWTH
--==================================================

resumePlant =
	function(
		player,
		point
	)

		local token =
			newToken(
				point
			)

		task.spawn(
			function()

				while
					tokenValid(
						point,
						token
					)
					and
					point:GetAttribute(
						"Occupied"
					)
				do

					local phase =
						point:GetAttribute(
							"GrowthPhase"
						)

					if phase == "Ready" then

						makeReady(
							player,
							point
						)

						return
					end

					if phase == "Growing1" then

						applyGrowthStage(
							point,
							1
						)

					elseif phase == "Growing2" then

						applyGrowthStage(
							point,
							2
						)

					else

						applyGrowthStage(
							point,
							3
						)

					end

					local endAt =
						point:GetAttribute(
							"PhaseEndAt"
						)
						or
						os.time()

					local remaining =
						endAt
						-
						os.time()

					if remaining > 0 then

						task.wait(
							remaining
						)

					end

					if not tokenValid(
						point,
						token
					) then

						return
					end

					phase =
						point:GetAttribute(
							"GrowthPhase"
						)

					endAt =
						point:GetAttribute(
							"PhaseEndAt"
						)
						or
						os.time()

					if phase == "Growing1" then

						point:SetAttribute(
							"GrowthPhase",
							"Growing2"
						)

						point:SetAttribute(
							"PhaseEndAt",
							endAt
								+
								STAGE_2_TIME
						)

						persistPoint(
							player,
							point
						)

					elseif phase == "Growing2" then

						point:SetAttribute(
							"GrowthPhase",
							"Growing3"
						)

						point:SetAttribute(
							"PhaseEndAt",
							endAt
								+
								STAGE_3_TIME
						)

						persistPoint(
							player,
							point
						)

					elseif
						phase == "Growing3"
						or
						phase == "Regrowing"
					then

						makeReady(
							player,
							point
						)

						return
					end
				end
			end
		)
	end

--==================================================
-- PLANT PROMPT
--==================================================

createPlantPrompt =
	function(point)

		clearPrompts(
			point
		)

		if point:GetAttribute(
			"Occupied"
		) then

			return
		end

		local prompt =
			Instance.new(
				"ProximityPrompt"
			)

		prompt.Name =
			"PlantPrompt"

		prompt.ActionText =
			"Plant Potato"

		prompt.ObjectText =
			"Empty Soil"

		prompt.KeyboardKeyCode =
			Enum.KeyCode.E

		prompt.HoldDuration =
			0.2

		prompt.MaxActivationDistance =
			10

		prompt.RequiresLineOfSight =
			false

		prompt.ClickablePrompt =
			false

		prompt.Parent =
			point

		prompt.Triggered:Connect(
			function(player)

				if not hasEquippedTool(
					player,
					"PotatoBits"
				) then

					return
				end

				if not playerOwnsPoint(
					player,
					point
				) then

					return
				end

				local bits =
					player:GetAttribute(
						"PotatoBits"
					)
					or 0

				if bits <= 0 then
					return
				end

				player:SetAttribute(
					"PotatoBits",
					bits - 1
				)

				point:SetAttribute(
					"Occupied",
					true
				)

				point:SetAttribute(
					"PlanterUserId",
					player.UserId
				)

				point:SetAttribute(
					"HarvestsRemaining",
					HARVESTS_PER_BIT
				)

				point:SetAttribute(
					"ReadyToHarvest",
					false
				)

				point:SetAttribute(
					"GrowthPhase",
					"Growing1"
				)

				point:SetAttribute(
					"PhaseEndAt",
					os.time()
						+
						STAGE_1_TIME
				)

				point:SetAttribute(
					"BatchSeed",
					0
				)

				clearPrompts(
					point
				)

				persistPoint(
					player,
					point
				)

				resumePlant(
					player,
					point
				)
			end
		)
	end

--==================================================
-- RESET ONE POINT
--==================================================

local function resetRuntimePoint(
	point
)

	newToken(
		point
	)

	destroyWholePlant(
		point
	)

	clearPrompts(
		point
	)

	point:SetAttribute(
		"Occupied",
		false
	)

	point:SetAttribute(
		"PlanterUserId",
		0
	)

	point:SetAttribute(
		"HarvestsRemaining",
		0
	)

	point:SetAttribute(
		"ReadyToHarvest",
		false
	)

	point:SetAttribute(
		"CurrentYield",
		0
	)

	point:SetAttribute(
		"GrowthPhase",
		"Empty"
	)

	point:SetAttribute(
		"PhaseEndAt",
		0
	)

	point:SetAttribute(
		"BatchSeed",
		0
	)

	resetBatchCounts(
		point
	)

	createPlantPrompt(
		point
	)
end

--==================================================
-- SETUP FARM POINTS
--==================================================

local function setupFarmPoints(
	farm
)

	local plots =
		farm:FindFirstChild(
			"PlantingPlots"
		)

	if not plots then
		return
	end

	for _, plot in ipairs(
		plots:GetChildren()
	) do

		if plot:IsA(
			"BasePart"
		) then

			createPlantPoints(
				plot
			)

			plot:SetAttribute(
				"OccupiedCount",
				0
			)

			for _, point in ipairs(
				plot:GetChildren()
			) do

				if
					point:IsA(
						"BasePart"
					)
					and
					string.match(
						point.Name,
						"PlantPoint_"
					)
				then

					resetRuntimePoint(
						point
					)

				end
			end
		end
	end
end

--==================================================
-- RESTORE PLAYER FARM
--==================================================

local function restorePlayerFarm(
	player
)

	if player:GetAttribute(
		"DataLoaded"
	) ~= true then

		return
	end

	local farmName =
		player:GetAttribute(
			"AssignedFarmName"
		)

	if not farmName then
		return
	end

	local farm =
		farmsFolder:FindFirstChild(
			farmName
		)

	if not farm then
		return
	end

	setupFarmPoints(
		farm
	)

	local savedPlants =
		DataService.GetPlantStates(
			player
		)

	for key, state in pairs(
		savedPlants
	) do

		local point =
			findPointFromKey(
				farm,
				key
			)

		if
			point
			and
			point:IsA(
				"BasePart"
			)
		then

			clearPrompts(
				point
			)

			point:SetAttribute(
				"Occupied",
				true
			)

			point:SetAttribute(
				"PlanterUserId",
				player.UserId
			)

			point:SetAttribute(
				"HarvestsRemaining",
				state.HarvestsRemaining
					or
					HARVESTS_PER_BIT
			)

			point:SetAttribute(
				"ReadyToHarvest",
				false
			)

			point:SetAttribute(
				"GrowthPhase",
				state.Phase
					or
					"Growing1"
			)

			point:SetAttribute(
				"PhaseEndAt",
				state.PhaseEndAt
					or
					os.time()
			)

			point:SetAttribute(
				"BatchSeed",
				state.BatchSeed
					or
					0
			)

			local plot =
				point.Parent

			plot:SetAttribute(
				"OccupiedCount",

				(plot:GetAttribute(
					"OccupiedCount"
				) or 0)
				+ 1
			)

			resumePlant(
				player,
				point
			)
		end
	end

	print(
		"🌱 Restored farm plants for "
			.. player.Name
	)
end

--==================================================
-- PLAYER SETUP
--==================================================

local function setupPlayer(
	player
)

	player:GetAttributeChangedSignal(
		"AssignedFarmName"
	):Connect(
		function()

			task.defer(
				restorePlayerFarm,
				player
			)

		end
	)

	player:GetAttributeChangedSignal(
		"DataLoaded"
	):Connect(
		function()

			if player:GetAttribute(
				"DataLoaded"
			) then

				task.defer(
					restorePlayerFarm,
					player
				)

			end
		end
	)

	task.defer(
		restorePlayerFarm,
		player
	)
end

--==================================================
-- PLAYER LEAVING
--==================================================

local function playerLeaving(
	player
)

	local farmName =
		player:GetAttribute(
			"AssignedFarmName"
		)

	if not farmName then
		return
	end

	local farm =
		farmsFolder:FindFirstChild(
			farmName
		)

	if farm then

		setupFarmPoints(
			farm
		)

	end
end

--==================================================
-- START
--==================================================

function PotatoService.Start(
	potatoWorld,
	dataService
)

	world =
		potatoWorld

	DataService =
		dataService

	farmsFolder =
		world:WaitForChild(
			"Farms"
		)

	for _, farm in ipairs(
		farmsFolder:GetChildren()
	) do

		if farm:IsA("Model") then

			setupFarmPoints(
				farm
			)

		end
	end

	Players.PlayerAdded:Connect(
		setupPlayer
	)

	Players.PlayerRemoving:Connect(
		playerLeaving
	)

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		setupPlayer(
			player
		)

	end

	print(
		"🥔 PotatoService ready"
	)

	print(
		"⚖ Spud-Mass RNG connected"
	)

	print(
		"💾 Individual potato records enabled"
	)

	print(
		"💾 Plant persistence enabled"
	)

	print(
		"⏱ Offline crop growth enabled"
	)
end

return PotatoService