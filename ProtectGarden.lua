-- Protect a Garden - Rey_Script Hub
-- Created by Rey_Script
-- Using Rayfield UI Library

repeat task.wait() until game:IsLoaded()

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success then
    warn("Failed to load Rayfield UI Library")
    return
end

local Window = Rayfield:CreateWindow({
   Name = "🌿 Protect a Garden - Rey_Script Hub",
   LoadingTitle = "Rey_Script Hub Loading...",
   LoadingSubtitle = "by Rey_Script",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "ReyScriptHub"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = false,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})

-- Variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local itemName = ""
local toolName = ""
local killAuraRadius = 20
local hitboxSize = 20
local moneyDistance = 50
local killAuraEnabled = false
local hitboxEnabled = false
local autoMoneyEnabled = false
local autoKillEnabled = false
local moneyMode = "No TP"
local killAuraConnection = nil
local hitboxConnection = nil
local autoMoneyConnection = nil
local autoKillConnection = nil
local originalSizes = {}
local collectedMoney = {}
local currentTarget = nil

-- Functions
local function GetEnemiesInRadius(radius)
    local enemies = {}
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return enemies
    end
    
    local playerPos = character.HumanoidRootPart.Position
    local enemyFolder = workspace:FindFirstChild("Enemy")
    
    if enemyFolder then
        for _, enemy in pairs(enemyFolder:GetChildren()) do
            if enemy:IsA("Model") and enemy ~= character then
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso") or enemy:FindFirstChild("Head")
                local humanoid = enemy:FindFirstChild("Humanoid")
                if enemyRoot and humanoid and humanoid.Health > 0 then
                    local distance = (enemyRoot.Position - playerPos).Magnitude
                    if distance <= radius then
                        table.insert(enemies, enemy)
                    end
                end
            end
        end
    end
    
    return enemies
end

local function GetAllEnemies()
    local enemies = {}
    local enemyFolder = workspace:FindFirstChild("Enemy")
    
    if enemyFolder then
        for _, enemy in pairs(enemyFolder:GetChildren()) do
            if enemy:IsA("Model") then
                local humanoid = enemy:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    table.insert(enemies, enemy)
                end
            end
        end
    end
    
    return enemies
end

local function AttackEnemy()
    local character = LocalPlayer.Character
    if not character then return false end
    
    local tool = character:FindFirstChild(toolName)
    if not tool then return false end
    
    -- Try multiple attack methods
    local success = false
    
    -- Method 1: ToolActive RemoteEvent
    local toolActive = tool:FindFirstChild("ToolActive")
    if toolActive and toolActive:IsA("RemoteEvent") then
        toolActive:FireServer()
        success = true
    end
    
    -- Method 2: RemoteEvent directly in tool
    local remoteEvent = tool:FindFirstChildOfClass("RemoteEvent")
    if remoteEvent then
        remoteEvent:FireServer()
        success = true
    end
    
    -- Method 3: Attack function
    local attackFunc = tool:FindFirstChild("Attack")
    if attackFunc and attackFunc:IsA("RemoteFunction") then
        attackFunc:InvokeServer()
        success = true
    end
    
    return success
end

local function ExpandHitbox(size)
    local count = 0
    local enemyFolder = workspace:FindFirstChild("Enemy")
    
    if not enemyFolder then
        return count
    end
    
    for _, enemy in pairs(enemyFolder:GetChildren()) do
        if enemy:IsA("Model") then
            -- Try to find any body part to expand
            for _, part in pairs(enemy:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name == "HumanoidRootPart" or part.Name == "Torso" or part.Name == "Head") then
                    if not originalSizes[part] then
                        originalSizes[part] = {
                            Size = part.Size,
                            Transparency = part.Transparency,
                            CanCollide = part.CanCollide,
                            Material = part.Material,
                            Massless = part.Massless
                        }
                    end
                    part.Size = Vector3.new(size, size, size)
                    part.Transparency = 0.5
                    part.Material = Enum.Material.ForceField
                    part.CanCollide = false
                    part.Massless = true
                    count = count + 1
                    break -- Only expand one part per enemy
                end
            end
        end
    end
    return count
end

local function RestoreHitbox()
    for part, data in pairs(originalSizes) do
        if part and part.Parent then
            part.Size = data.Size
            part.Transparency = data.Transparency
            part.CanCollide = data.CanCollide
            part.Material = data.Material
            part.Massless = data.Massless
        end
    end
    originalSizes = {}
end

local function FindMoneyParts()
    local moneyParts = {}
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "Money" and not collectedMoney[part] then
            table.insert(moneyParts, part)
        end
    end
    return moneyParts
end

local function GetMoneyInRange(distance)
    local moneyParts = {}
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return moneyParts
    end
    
    local playerPos = character.HumanoidRootPart.Position
    
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "Money" and not collectedMoney[part] then
            local dist = (part.Position - playerPos).Magnitude
            if dist <= distance then
                table.insert(moneyParts, part)
            end
        end
    end
    return moneyParts
end

local function AutoGetMoney(mode, distance)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local hrp = character.HumanoidRootPart
    
    if mode == "TP Money" then
        local moneyParts = FindMoneyParts()
        for _, moneyPart in pairs(moneyParts) do
            if moneyPart and moneyPart.Parent then
                pcall(function()
                    -- Teleport to money
                    hrp.CFrame = moneyPart.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.1)
                    
                    -- Try interaction methods
                    if firetouchinterest then
                        firetouchinterest(hrp, moneyPart, 0)
                        task.wait(0.05)
                        firetouchinterest(hrp, moneyPart, 1)
                    end
                    
                    local prompt = moneyPart:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        fireproximityprompt(prompt)
                    end
                    
                    local clickDetector = moneyPart:FindFirstChildOfClass("ClickDetector")
                    if clickDetector then
                        fireclickdetector(clickDetector)
                    end
                    
                    collectedMoney[moneyPart] = true
                end)
            end
        end
    else -- No TP mode with distance
        local moneyParts = GetMoneyInRange(distance)
        for _, moneyPart in pairs(moneyParts) do
            if moneyPart and moneyPart.Parent then
                pcall(function()
                    -- Try interaction without TP
                    if firetouchinterest then
                        firetouchinterest(hrp, moneyPart, 0)
                        task.wait(0.05)
                        firetouchinterest(hrp, moneyPart, 1)
                    end
                    
                    local prompt = moneyPart:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        fireproximityprompt(prompt)
                    end
                    
                    local clickDetector = moneyPart:FindFirstChildOfClass("ClickDetector")
                    if clickDetector then
                        fireclickdetector(clickDetector)
                    end
                    
                    -- Try remote events
                    local remoteEvent = moneyPart:FindFirstChildOfClass("RemoteEvent")
                    if remoteEvent then
                        remoteEvent:FireServer()
                    end
                    
                    if ReplicatedStorage:FindFirstChild("RemoteEvent") then
                        local remote = ReplicatedStorage.RemoteEvent:FindFirstChild("CollectMoney") or
                                      ReplicatedStorage.RemoteEvent:FindFirstChild("GetMoney") or
                                      ReplicatedStorage.RemoteEvent:FindFirstChild("PickupMoney")
                        if remote then
                            remote:FireServer(moneyPart)
                        end
                    end
                    
                    collectedMoney[moneyPart] = true
                end)
            end
        end
    end
    
    -- Clear collected money table
    for part, _ in pairs(collectedMoney) do
        if not part or not part.Parent then
            collectedMoney[part] = nil
        end
    end
end

-- Tabs
local MainTab = Window:CreateTab("🏠 Main", 4483362458)
local FarmTab = Window:CreateTab("💰 Farm", 4483362458)
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)
local AutoKillTab = Window:CreateTab("🎯 Auto Kill", 4483362458)
local VisualTab = Window:CreateTab("👁️ Visual", 4483362458)

-- Main Tab - Item Pickup Section
local ItemSection = MainTab:CreateSection("📦 Item Pickup")

local ItemInput = MainTab:CreateInput({
   Name = "Item Name",
   PlaceholderText = "Enter item name...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      itemName = Text
   end,
})

local ItemButton = MainTab:CreateButton({
   Name = "Execute Item Pickup",
   Callback = function()
      if itemName == "" then
         Rayfield:Notify({
            Title = "Error",
            Content = "Please enter an item name!",
            Duration = 3,
            Image = 4483362458,
         })
         return
      end
      
      local success, err = pcall(function()
         local args = {
            workspace:WaitForChild(itemName)
         }
         ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("PickupItem"):FireServer(unpack(args))
      end)
      
      if success then
         Rayfield:Notify({
            Title = "Success",
            Content = "Item pickup executed!",
            Duration = 3,
            Image = 4483362458,
         })
      else
         Rayfield:Notify({
            Title = "Error",
            Content = "Failed to pickup item",
            Duration = 3,
            Image = 4483362458,
         })
      end
   end,
})

-- Farm Tab - Auto Get Money Section
local MoneySection = FarmTab:CreateSection("💰 Auto Get Money")

local MoneyModeDropdown = FarmTab:CreateDropdown({
   Name = "Money Collection Mode",
   Options = {"No TP", "TP Money"},
   CurrentOption = {"No TP"},
   MultipleOptions = false,
   Flag = "MoneyMode",
   Callback = function(Option)
      moneyMode = Option[1]
   end,
})

local MoneyDistanceInput = FarmTab:CreateInput({
   Name = "No TP Interaction Distance",
   PlaceholderText = "Enter distance (default: 50)...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local dist = tonumber(Text)
      if dist and dist > 0 then
         moneyDistance = dist
         Rayfield:Notify({
            Title = "Distance Updated",
            Content = "Interaction distance set to: " .. dist .. " studs",
            Duration = 2,
            Image = 4483362458,
         })
      end
   end,
})

local AutoMoneyToggle = FarmTab:CreateToggle({
   Name = "Enable Auto Get Money",
   CurrentValue = false,
   Flag = "AutoMoneyToggle",
   Callback = function(Value)
      autoMoneyEnabled = Value
      
      if autoMoneyEnabled then
         collectedMoney = {}
         
         Rayfield:Notify({
            Title = "Auto Money Activated",
            Content = "Mode: " .. moneyMode .. " | Distance: " .. moneyDistance,
            Duration = 3,
            Image = 4483362458,
         })
         
         autoMoneyConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
               AutoGetMoney(moneyMode, moneyDistance)
            end)
         end)
      else
         Rayfield:Notify({
            Title = "Auto Money Deactivated",
            Content = "Money collection disabled",
            Duration = 3,
            Image = 4483362458,
         })
         
         if autoMoneyConnection then
            autoMoneyConnection:Disconnect()
            autoMoneyConnection = nil
         end
      end
   end,
})

local ResetMoneyButton = FarmTab:CreateButton({
   Name = "Reset Money Cache",
   Callback = function()
      collectedMoney = {}
      Rayfield:Notify({
         Title = "Cache Reset",
         Content = "Money cache cleared!",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

-- Combat Tab - Kill Aura Section
local CombatSection = CombatTab:CreateSection("⚔️ Kill Aura")

local ToolInput = CombatTab:CreateInput({
   Name = "Tool Name",
   PlaceholderText = "Enter tool name...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      toolName = Text
   end,
})

local RadiusSlider = CombatTab:CreateSlider({
   Name = "Kill Aura Radius",
   Range = {5, 100},
   Increment = 5,
   Suffix = " studs",
   CurrentValue = 20,
   Flag = "KillAuraRadius",
   Callback = function(Value)
      killAuraRadius = Value
   end,
})

local KillAuraToggle = CombatTab:CreateToggle({
   Name = "Enable Kill Aura",
   CurrentValue = false,
   Flag = "KillAuraToggle",
   Callback = function(Value)
      killAuraEnabled = Value
      
      if killAuraEnabled then
         if toolName == "" then
            Rayfield:Notify({
               Title = "Error",
               Content = "Please enter a tool name!",
               Duration = 3,
               Image = 4483362458,
            })
            killAuraEnabled = false
            KillAuraToggle:Set(false)
            return
         end
         
         Rayfield:Notify({
            Title = "Kill Aura Activated",
            Content = "Radius: " .. killAuraRadius .. " studs",
            Duration = 3,
            Image = 4483362458,
         })
         
         killAuraConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
               local enemies = GetEnemiesInRadius(killAuraRadius)
               if #enemies > 0 then
                  AttackEnemy()
               end
            end)
         end)
      else
         Rayfield:Notify({
            Title = "Kill Aura Deactivated",
            Content = "Kill Aura disabled",
            Duration = 3,
            Image = 4483362458,
         })
         
         if killAuraConnection then
            killAuraConnection:Disconnect()
            killAuraConnection = nil
         end
      end
   end,
})

-- Auto Kill Tab
local AutoKillSection = AutoKillTab:CreateSection("🎯 Auto Kill Enemy")

local AutoKillToolInput = AutoKillTab:CreateInput({
   Name = "Tool Name for Auto Kill",
   PlaceholderText = "Enter tool name...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      toolName = Text
   end,
})

local AutoKillToggle = AutoKillTab:CreateToggle({
   Name = "Enable Auto Kill Enemy",
   CurrentValue = false,
   Flag = "AutoKillToggle",
   Callback = function(Value)
      autoKillEnabled = Value
      
      if autoKillEnabled then
         if toolName == "" then
            Rayfield:Notify({
               Title = "Error",
               Content = "Please enter a tool name!",
               Duration = 3,
               Image = 4483362458,
            })
            autoKillEnabled = false
            AutoKillToggle:Set(false)
            return
         end
         
         Rayfield:Notify({
            Title = "Auto Kill Activated",
            Content = "Hunting enemies in workspace.Enemy...",
            Duration = 3,
            Image = 4483362458,
         })
         
         autoKillConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
               local character = LocalPlayer.Character
               if not character or not character:FindFirstChild("HumanoidRootPart") then
                  return
               end
               
               local hrp = character.HumanoidRootPart
               
               -- Find target if we don't have one
               if not currentTarget or not currentTarget.Parent or currentTarget:FindFirstChild("Humanoid").Health <= 0 then
                  local enemies = GetAllEnemies()
                  if #enemies > 0 then
                     currentTarget = enemies[1]
                  else
                     currentTarget = nil
                     return
                  end
               end
               
               -- Teleport to target and attack
               if currentTarget then
                  local enemyRoot = currentTarget:FindFirstChild("HumanoidRootPart") or currentTarget:FindFirstChild("Torso") or currentTarget:FindFirstChild("Head")
                  if enemyRoot then
                     -- Teleport above enemy
                     hrp.CFrame = enemyRoot.CFrame + Vector3.new(0, 5, 0)
                     task.wait(0.05)
                     
                     -- Attack
                     AttackEnemy()
                  end
               end
            end)
         end)
      else
         Rayfield:Notify({
            Title = "Auto Kill Deactivated",
            Content = "Auto kill disabled",
            Duration = 3,
            Image = 4483362458,
         })
         
         currentTarget = nil
         if autoKillConnection then
            autoKillConnection:Disconnect()
            autoKillConnection = nil
         end
      end
   end,
})

local AutoKillInfo = AutoKillTab:CreateParagraph({
   Title = "ℹ️ Auto Kill Info",
   Content = "Auto Kill will:\n• Detect enemies in workspace.Enemy\n• Teleport above enemy\n• Auto attack until enemy dies\n• Move to next enemy automatically"
})

-- Visual Tab - Hitbox Expander Section
local VisualSection = VisualTab:CreateSection("🎯 Hitbox Expander")

local HitboxSlider = VisualTab:CreateSlider({
   Name = "Hitbox Size",
   Range = {5, 100},
   Increment = 5,
   Suffix = " studs",
   CurrentValue = 20,
   Flag = "HitboxSize",
   Callback = function(Value)
      hitboxSize = Value
      
      if hitboxEnabled then
         RestoreHitbox()
         ExpandHitbox(hitboxSize)
      end
   end,
})

local HitboxToggle = VisualTab:CreateToggle({
   Name = "Enable Hitbo
