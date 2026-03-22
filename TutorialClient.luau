local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local HRP = character:WaitForChild("HumanoidRootPart")
local playerGui = player:WaitForChild("PlayerGui")

-- GUI
local tutorialFrame = playerGui.Tutorial:WaitForChild("Frame")
local tutorialLabel = tutorialFrame:WaitForChild("TutorialLabel")
local progressLabel = tutorialFrame:WaitForChild("ProgressLabel")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local startTutorialEvent = Remotes:WaitForChild("StartTutorial")
local tutorialStepEvent = Remotes:WaitForChild("TutorialStep")

-- Typewriter SFX (Add a sound named "Typewriter" to SoundService)
local typewriterSFX = SoundService:WaitForChild("Typewriter")

local beam = nil
local activeInstances = {} -- clean up
local strokeHighlite = nil -- UIStroke highlight
local tutorialStep = 0
local advance -- forward declared below

--  Call setBeam(part) to point at something, setBeam(nil) to clear
local function setBeam(target)
	if beam then beam:Destroy() beam = nil end
	if not target then return end

	local rootAtt = HRP:WaitForChild("RootAttachment")
	local att = Instance.new("Attachment", target)

	beam = script.Beam:Clone()
	beam.Parent = target
	beam.Attachment0 = att
	beam.Attachment1 = rootAtt

	table.insert(activeInstances, beam)
	table.insert(activeInstances, att)
end

local function highliteButton(button)
	strokeHighlite = Instance.new("UIStroke")
	strokeHighlite.Color = Color3.fromRGB(255, 255, 0)
	strokeHighlite.Transparency = 0.2
	strokeHighlite.Parent = button

	local anim = TweenService:Create(
		strokeHighlite,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.8 }
	)
	table.insert(activeInstances, anim)
	table.insert(activeInstances, strokeHighlite)
	anim:Play()
end

--  Clean up
local function clearActive()
	for i = #activeInstances, 1, -1 do
		local inst = activeInstances[i]
		if typeof(inst) == "Instance" and inst:IsA("Tween") then
			inst:Cancel()
		elseif typeof(inst) == "RBXScriptConnection" then
			inst:Disconnect()
		elseif typeof(inst) == "Instance" then
			if inst:IsA("Highlight") or inst:IsA("Attachment") or inst:IsA("Beam") then
				inst:Destroy()
			elseif inst:IsA("UIStroke") then
				inst.Transparency = 0
				inst.Thickness = 3
				inst.Color = Color3.fromRGB(0, 0, 0)
			elseif inst:IsA("Frame") or inst:IsA("ImageLabel") then
				inst.Visible = false
			end
		end
	end
	table.clear(activeInstances)
end

local function playTypewriterSound()
	local char = string.sub(tutorialLabel.Text, #tutorialLabel.Text, #tutorialLabel.Text)
	if char == " " then return end

	local sfxClone = typewriterSFX:Clone()
	sfxClone.Parent = SoundService
	sfxClone.PlaybackSpeed = math.random(95, 110) / 100
	sfxClone.Volume = math.random(85, 100) / 100
	sfxClone:Play()
	game:GetService("Debris"):AddItem(sfxClone, sfxClone.TimeLength)
end

-- Supports platform-specific messages:
--   Message = "same for all"
--   Message = { PC = "...", Mobile = "...", Console = "..." }
local function resolveMessage(message)
	if type(message) == "table" then
		if UserInputService.GamepadEnabled then return message.Console
		elseif UserInputService.TouchEnabled then return message.Mobile
		else return message.PC end
	end
	return message
end

local function showMessage(message)
	tutorialLabel.Visible = true
	tutorialLabel.Text = ""
	for i = 1, #message do
		tutorialLabel.Text = string.sub(message, 1, i)
		if i % 2 == 0 then playTypewriterSound() end
		task.wait(0.032)
	end
end

local tutorialSteps = {
	[1] = {
		Message = "Welcome! Let me show you around.",
		Requirement = true,
	},
}

advance = function()
	clearActive()
	tutorialStep += 1
	local step = tutorialSteps[tutorialStep]

	-- No more steps — tutorial complete
	if not step then
		tutorialFrame.Visible = false
		setBeam(nil)
		startTutorialEvent:FireServer()
		script:Destroy()
		return
	end

	if step.Action then
		task.spawn(step.Action)
	end

	local message = resolveMessage(step.Message)
	if not message then warn("[Tutorial] Failed to resolve message for step " .. tutorialStep) return end
	showMessage(message)
	task.wait(0.75)

	if step.Requirement == true then
		advance()
	elseif typeof(step.Requirement) == "function" then
		step.Requirement()
	end
end

-- Entry point
startTutorialEvent.OnClientEvent:Connect(function()
	tutorialFrame.Visible = true
	advance()
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	HRP = newCharacter:WaitForChild("HumanoidRootPart")

	if beam then
		local target = beam.Parent
		beam:Destroy()
		beam = nil
		setBeam(target)
	end
end)
