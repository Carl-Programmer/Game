--!strict
-- HoeDigAnimation.client.lua
-- Standalone hoe swing animation for Potatium.
--
-- Install through Rojo under StarterPlayerScripts.
-- It listens to the existing ForagingRemotes, so the digging
-- controller does not need to be edited.
--
-- Uses the same four hit points as ForagingDigClient V8.
-- The server remains authoritative for whether digging succeeds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local ANIMATION_ID = "rbxassetid://121303700659683"
local SWING_POINTS = { 0.12, 0.36, 0.61, 0.84 }

--==================================================
-- HOE POSITION / ANGLE SETTINGS
-- Edit ONLY these values to adjust how the hoe sits
-- in the character's hand. Position is in studs;
-- rotation is in degrees.
--
-- Start with 180 on X to flip the tool orientation.
-- If that points the head the wrong way, try 180 on Y
-- or Z instead. Use small position changes like 0.1.
--==================================================
local HOE_GRIP_POSITION = Vector3.new(0, 0, 0)
local HOE_GRIP_ROTATION_DEGREES = Vector3.new(180, 0, 0)

local function getHoeGripOffset(): CFrame
	return CFrame.new(HOE_GRIP_POSITION)
		* CFrame.Angles(
			math.rad(HOE_GRIP_ROTATION_DEGREES.X),
			math.rad(HOE_GRIP_ROTATION_DEGREES.Y),
			math.rad(HOE_GRIP_ROTATION_DEGREES.Z)
		)
end

local originalHoeGrip: CFrame? = nil
local gripAdjustedHoe: Tool? = nil

local function applyHoeGrip(hoe: Tool?)
	if not hoe then
		return
	end

	if gripAdjustedHoe ~= hoe then
		if gripAdjustedHoe and originalHoeGrip then
			gripAdjustedHoe.Grip = originalHoeGrip
		end
		gripAdjustedHoe = hoe
		originalHoeGrip = hoe.Grip
	end

	if originalHoeGrip then
		hoe.Grip = originalHoeGrip * getHoeGripOffset()
	end
end

local function restoreHoeGrip()
	if gripAdjustedHoe and originalHoeGrip then
		gripAdjustedHoe.Grip = originalHoeGrip
	end
	gripAdjustedHoe = nil
	originalHoeGrip = nil
end

-- Animation playback is fitted to the time between swings.
-- Increase MIN_PLAYBACK_SPEED / MAX_PLAYBACK_SPEED only if needed.
local MIN_PLAYBACK_SPEED = 0.65
local MAX_PLAYBACK_SPEED = 3.5
local ANIMATION_TIME_PER_DIG_RATIO = 0.22

local remotes = ReplicatedStorage:WaitForChild("ForagingRemotes")
local digStarted = remotes:WaitForChild("DigStarted") :: RemoteEvent
local digCancelled = remotes:WaitForChild("DigCancelled") :: RemoteEvent
local digFinished = remotes:WaitForChild("DigFinished") :: RemoteEvent

local activeDigId: any = nil
local activeDigTime: number = 0
local activeEndServerTime: number = 0
local nextSwingIndex: number = 1
local renderConnection: RBXScriptConnection? = nil

local animation = Instance.new("Animation")
animation.Name = "PotatiumHoeDigAnimation"
animation.AnimationId = ANIMATION_ID

local animationTrack: AnimationTrack? = nil
local loadedHumanoid: Humanoid? = nil

local function getEquippedHoe(): Tool?
	local character: Model? = player.Character
	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			local toolType = child:GetAttribute("FarmingToolType")
			local lowerName = string.lower(child.Name)

			if toolType == "Hoe" or string.find(lowerName, "hoe", 1, true) then
				return child
			end
		end
	end

	return nil
end

local function stopAnimation()
	if animationTrack and animationTrack.IsPlaying then
		animationTrack:Stop(0.08)
	end
end

local function loadAnimationForCharacter()
	stopAnimation()
	animationTrack = nil
	loadedHumanoid = nil

	local character: Model? = player.Character
	if not character then
		return
	end

	local humanoidInstance = character:FindFirstChildOfClass("Humanoid")
	if not humanoidInstance then
		humanoidInstance = character:WaitForChild("Humanoid", 5)
	end
	if not humanoidInstance or not humanoidInstance:IsA("Humanoid") then
		return
	end
	local humanoid: Humanoid = humanoidInstance

	local animatorInstance = humanoid:FindFirstChildOfClass("Animator")
	if not animatorInstance then
		animatorInstance = humanoid:WaitForChild("Animator", 5)
	end
	if not animatorInstance or not animatorInstance:IsA("Animator") then
		warn("[HoeDigAnimation] Animator not found.")
		return
	end
	local animator: Animator = animatorInstance

	local ok, result = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not ok then
		warn("[HoeDigAnimation] Failed to load animation:", result)
		return
	end

	animationTrack = result
	animationTrack.Name = "PotatiumHoeSwing"
	animationTrack.Priority = Enum.AnimationPriority.Action
	animationTrack.Looped = false
	loadedHumanoid = humanoid
end

local function playSwing()
	if not getEquippedHoe() then
		return
	end

	if not animationTrack or not loadedHumanoid or loadedHumanoid.Health <= 0 then
		loadAnimationForCharacter()
	end

	local track = animationTrack
	if not track then
		return
	end

	-- The hit points are 0.24-0.25 of the full dig apart.
	-- Fit each animation into that interval so faster hoes swing faster.
	local targetDuration = math.max(0.16, activeDigTime * ANIMATION_TIME_PER_DIG_RATIO)
	local length = track.Length
	local playbackSpeed = 1

	if length and length > 0 then
		playbackSpeed = math.clamp(length / targetDuration, MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)
	end

	if track.IsPlaying then
		track:Stop(0.03)
	end

	track.TimePosition = 0
	track:Play(0.04, 1, playbackSpeed)
end

local function stopDigAnimation()
	restoreHoeGrip()
	activeDigId = nil
	activeDigTime = 0
	activeEndServerTime = 0
	nextSwingIndex = 1

	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	stopAnimation()
end

digStarted.OnClientEvent:Connect(function(digTime, digId, _digSpot, endServerTime)
	stopDigAnimation()

	activeDigId = digId
	activeDigTime = math.max(tonumber(digTime) or 6, 0.1)
	activeEndServerTime = tonumber(endServerTime) or (workspace:GetServerTimeNow() + activeDigTime)
	nextSwingIndex = 1

	local equippedHoe = getEquippedHoe()
	if not equippedHoe then
		stopDigAnimation()
		return
	end
	applyHoeGrip(equippedHoe)

	if not animationTrack or not loadedHumanoid or loadedHumanoid.Parent ~= player.Character then
		loadAnimationForCharacter()
	end

	renderConnection = RunService.RenderStepped:Connect(function()
		if not activeDigId then
			return
		end

		local equippedHoe = getEquippedHoe()
		if not equippedHoe then
			stopDigAnimation()
			return
		end
		applyHoeGrip(equippedHoe)

		local remaining = activeEndServerTime - workspace:GetServerTimeNow()
		local progress = math.clamp(1 - (remaining / activeDigTime), 0, 1)

		while nextSwingIndex <= #SWING_POINTS and progress >= SWING_POINTS[nextSwingIndex] do
			nextSwingIndex += 1
			playSwing()
		end

		if remaining <= 0 then
			-- Keep the last swing's natural finish; only stop tracking the dig.
			if renderConnection then
				renderConnection:Disconnect()
				renderConnection = nil
			end
			activeDigId = nil
		end
	end)
end)

digCancelled.OnClientEvent:Connect(function(_reason, digId)
	if activeDigId and digId and activeDigId ~= digId then
		return
	end
	stopDigAnimation()
end)

digFinished.OnClientEvent:Connect(function(_data)
	stopDigAnimation()
end)

player.CharacterAdded:Connect(function()
	stopDigAnimation()
	task.defer(loadAnimationForCharacter)
end)

if player.Character then
	task.defer(loadAnimationForCharacter)
end

print("[HoeDigAnimation] Standalone hoe animation controller loaded.")
