# Roblox Tutorial System

## Starting the Tutorial
Fire `StartTutorial` to the client after the player's data loads:
```lua
Remotes.StartTutorial:FireClient(player)
```

## Step Structure
```lua
[1] = {
    Message = "Your message here",
    Action = function()  -- optional
        setBeam(workspace.SomePart)
    end,
    Requirement = function()
        local conn
        conn = tutorialStepEvent.OnClientEvent:Connect(function(stepName)
            if stepName ~= "YourStepName" then return end
            conn:Disconnect()
            advance()
        end)
        table.insert(activeInstances, conn)
    end,
},

[2] = {
    Message = "See ya!",
    Requirement = true, -- auto-advance
},
```
