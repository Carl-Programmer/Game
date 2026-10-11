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

local ANIMATION_ID = "rbxassetid://PUT_YOUR_HOE_ANIMATION_ID_HERE"
local SWING_POINTS = { 0.12, 0.36, 0.61, 0.84 }

-- Animation playback is fitted to the time between swings.
-- Increase MIN_PLAYBACK_SPEED / MAX_PLAYBACK_SPEED only if needed.
local MIN_PLAYBACK_SPEED = 0.65
local MAX_PLAYBACK_SPEED = 3.5
local ANIMATION_TIME_PER_DIG_RATIO = 0.22

local remotes = ReplicatedStorage:WaitForChild("ForagingRemotes")
local digStarted = remotes:WaitForChild("DigStarted")
local digCancelled = remotes:WaitForChild("DigCancelled")
local digFinished = remotes:WaitForChild("DigFinished")

local activeDigId = nil
local activeDigTime = 0
local activeEndServerTime = 0
local nextSwingIndex = 1
local renderConnection = nil

local animation = Instance.new("Animation")
animation.Name = "PotatiumHoeDigAnimation"
animation.AnimationId = ANIMATION_ID

local animationTrack = nil
local loadedHumanoid = nil

local function getEquippedHoe()
	local character = player.Character
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

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 5)
	end
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = humanoid:WaitForChild("Animator", 5)
	end
	if not animator then
		warn("[HoeDigAnimation] Animator not found.")
		return
	end

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

	if not getEquippedHoe() then
		stopDigAnimation()
		return
	end

	if not animationTrack or not loadedHumanoid or loadedHumanoid.Parent ~= player.Character then
		loadAnimationForCharacter()
	end

	renderConnection = RunService.RenderStepped:Connect(function()
		if not activeDigId then
			return
		end

		if not getEquippedHoe() then
			stopDigAnimation()
			return
		end

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
