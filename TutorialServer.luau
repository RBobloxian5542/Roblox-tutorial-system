local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local startTutorialEvent = Remotes:WaitForChild("StartTutorial")

-- Adjust to your path
if not player.Data.TutorialCompleted then
	startTutorialEvent:FireClient(playerClass.Player)
end

startTutorialEvent.OnServerEvent:Connect(function(player)
	player.Data.TutorialCompleted = true
end)
