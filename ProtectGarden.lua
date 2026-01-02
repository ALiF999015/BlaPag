--[[
    Protect a Garden - Rey_Script Hub
    Created by Rey_Script
    Version: 2.1
]]

print("Loading Rey_Script Hub...")

-- Wait for game to fully load
repeat task.wait() until game:IsLoaded()

-- Load Rayfield UI Library with error handling
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield", true))()
end)

if not success or not Rayfield then
    error("Failed to load Rayfield UI Library. Please check your internet connection.")
    return
end

print("Rayfield loaded successfully!")

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local Config = {
    itemName = "",
    toolName = "",
    killAuraRadius = 20,
    hitboxSize = 20,
    moneyDistance = 50,
    moneyMode = "No TP"
}

local State = {
    killAuraEnabled = false,
    hitboxEnabled = false,
    autoMoneyEnabled = false,
    autoKillEnabled = false
}

local Connections = {
    killAura = nil,
    hitbox = nil,
    autoMoney = nil,
    autoKill = nil
}

local Data = {
    originalSizes = {},
    collectedMoney = {},
    currentTarget = nil
}

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "🌿 Protect a Garden - Rey_Script Hub",
    LoadingTitle = "Rey_Script Hub",
    LoadingSubtitle = "by Rey_Script",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- Utility Functions
local function Notify(title, content)
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = 3,
        Image = 4483362458
    })
end

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
    
    local tool = character:FindFirstChild(Config.toolName)
    if not tool then return false end
    
    local attacked = false
    
    local toolActive = tool:FindFirstChild("ToolActive")
    if toolActive and toolActive:IsA("RemoteEvent") then
        toolActive:FireServer()
        attacked = true
    end
    
    if not attacked then
        local remoteEvent = tool:FindFirstChildOfClass("RemoteEvent")
        if remoteEvent then
            remoteEvent:FireServer()
            attacked = true
        end
    end
    
    return attacked
end

local function ExpandHitbox(size)
    local count = 0
    local enemyFolder = workspace:FindFirstChild("Enemy")
    
    if not enemyFolder then return count end
    
    for _, enemy in pairs(enemyFolder:GetChildren()) do
        if enemy:IsA("Model") then
            for _, part in pairs(enemy:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name == "HumanoidRootPart" or part.Name == "Torso" or part.Name == "Head") then
                    if not Data.originalSizes[part] then
                        Data.originalSizes[part] = {
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
                    break
                end
            end
        end
    end
    return count
end

local function RestoreHitbox()
    for part, data in pairs(Data.originalSizes) do
        if part and part.Parent then
            part.Size = data.Size
            part.Transparency = data.Transparency
            part.CanCollide = data.CanCollide
            part.Material = data.Material
            part.Massless = data.Massless
        end
    end
    Data.originalSizes = {}
end

local function GetMoneyInRange(distance)
    local moneyParts = {}
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return moneyParts
    end
    
    local playerPos = character.HumanoidRootPart.Position
    
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "Money" and not Data.collectedMoney[part] then
            local dist = (part.Position - playerPos).Magnitude
            if dist <= distance then
                table.insert(moneyParts, part)
            end
        end
    end
    return moneyParts
end

local function AutoGetMoney()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character.HumanoidRootPart
    
    if Config.moneyMode == "TP Money" then
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Name == "Money" and not Data.collectedMoney[part] then
                pcall(function()
                    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.1)
                    
                    if firetouchinterest then
                        firetouchinterest(hrp, part, 0)
                        task.wait(0.05)
                        firetouchinterest(hrp, part, 1)
                    end
                    
                    Data.collectedMoney[part] = true
                end)
            end
        end
    else
        local moneyParts = GetMoneyInRange(Config.moneyDistance)
        for _, part in pairs(moneyParts) do
            pcall(function()
                if firetouchinterest then
                    firetouchinterest(hrp, part, 0)
                    task.wait(0.05)
                    firetouchinterest(hrp, part, 1)
                end
                
                local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                if prompt and fireproximityprompt then
                    fireproximityprompt(prompt)
                end
                
                local clickDetector = part:FindFirstChildOfClass("ClickDetector")
                if clickDetector and fireclickdetector then
                    fireclickdetector(clickDetector)
                end
                
                Data.collectedMoney[part] = true
            end)
        end
    end
    
    for part, _ in pairs(Data.collectedMoney) do
        if not part or not part.Parent then
            Data.collectedMoney[part] = nil
        end
    end
end

-- Create Tabs
local MainTab = Window:CreateTab("🏠 Main", 4483362458)
local FarmTab = Window:CreateTab("💰 Farm", 4483362458)
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)
local AutoKillTab = Window:CreateTab("🎯 Auto Kill", 4483362458)
local VisualTab = Window:CreateTab("👁️ Visual", 4483362458)
local CreditsTab = Window:CreateTab("📜 Credits", 4483362458)

-- Main Tab
MainTab:CreateSection("📦 Item Pickup")

MainTab:CreateInput({
    Name = "Item Name",
    PlaceholderText = "Enter item name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        Config.itemName = text
    end
})

MainTab:CreateButton({
    Name = "Execute Item Pickup",
    Callback = function()
        if Config.itemName == "" then
            Notify("Error", "Enter item name!")
            return
        end
        
        pcall(function()
            local args = { workspace:WaitForChild(Config.itemName) }
            ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("PickupItem"):FireServer(unpack(args))
            Notify("Success", "Item pickup executed!")
        end)
    end
})

-- Farm Tab
FarmTab:CreateSection("💰 Auto Get Money")

FarmTab:CreateDropdown({
    Name = "Collection Mode",
    Options = {"No TP", "TP Money"},
    CurrentOption = {"No TP"},
    MultipleOptions = false,
    Callback = function(option)
        Config.moneyMode = option[1]
    end
})

FarmTab:CreateInput({
    Name = "Interaction Distance",
    PlaceholderText = "Default: 50",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local dist = tonumber(text)
        if dist and dist > 0 then
            Config.moneyDistance = dist
            Notify("Updated", "Distance: " .. dist)
        end
    end
})

FarmTab:CreateToggle({
    Name = "Enable Auto Money",
    CurrentValue = false,
    Callback = function(value)
        State.autoMoneyEnabled = value
        
        if value then
            Data.collectedMoney = {}
            Notify("Enabled", "Auto Money ON")
            
            Connections.autoMoney = RunService.Heartbeat:Connect(function()
                pcall(AutoGetMoney)
            end)
        else
            if Connections.autoMoney then
                Connections.autoMoney:Disconnect()
            end
            Notify("Disabled", "Auto Money OFF")
        end
    end
})

FarmTab:CreateButton({
    Name = "Reset Cache",
    Callback = function()
        Data.collectedMoney = {}
        Notify("Reset", "Cache cleared!")
    end
})

-- Combat Tab
CombatTab:CreateSection("⚔️ Kill Aura")

CombatTab:CreateInput({
    Name = "Tool Name",
    PlaceholderText = "Enter tool name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        Config.toolName = text
    end
})

CombatTab:CreateSlider({
    Name = "Radius",
    Range = {5, 100},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 20,
    Callback = function(value)
        Config.killAuraRadius = value
    end
})

CombatTab:CreateToggle({
    Name = "Enable Kill Aura",
    CurrentValue = false,
    Callback = function(value)
        State.killAuraEnabled = value
        
        if value then
            if Config.toolName == "" then
                Notify("Error", "Enter tool name!")
                return
            end
            
            Notify("Enabled", "Kill Aura ON")
            
            Connections.killAura = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local enemies = GetEnemiesInRadius(Config.killAuraRadius)
                    if #enemies > 0 then
                        AttackEnemy()
                    end
                end)
            end)
        else
            if Connections.killAura then
                Connections.killAura:Disconnect()
            end
            Notify("Disabled", "Kill Aura OFF")
        end
    end
})

-- Auto Kill Tab
AutoKillTab:CreateSection("🎯 Auto Kill Enemy")

AutoKillTab:CreateInput({
    Name = "Tool Name",
    PlaceholderText = "Enter tool name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        Config.toolName = text
    end
})

AutoKillTab:CreateToggle({
    Name = "Enable Auto Kill",
    CurrentValue = false,
    Callback = function(value)
        State.autoKillEnabled = value
        
        if value then
            if Config.toolName == "" then
                Notify("Error", "Enter tool name!")
                return
            end
            
            Notify("Enabled", "Auto Kill ON")
            
            Connections.autoKill = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local character = LocalPlayer.Character
                    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
                    
                    local hrp = character.HumanoidRootPart
                    
                    if not Data.currentTarget or not Data.currentTarget.Parent then
                        local enemies = GetAllEnemies()
                        if #enemies > 0 then
                            Data.currentTarget = enemies[1]
                        else
                            return
                        end
                    end
                    
                    if Data.currentTarget then
                        local humanoid = Data.currentTarget:FindFirstChild("Humanoid")
                        if not humanoid or humanoid.Health <= 0 then
                            Data.currentTarget = nil
                            return
                        end
                        
                        local enemyRoot = Data.currentTarget:FindFirstChild("HumanoidRootPart") or 
                                        Data.currentTarget:FindFirstChild("Torso") or 
                                        Data.currentTarget:FindFirstChild("Head")
                        if enemyRoot then
                            hrp.CFrame = enemyRoot.CFrame + Vector3.new(0, 5, 0)
                            task.wait(0.05)
                            AttackEnemy()
                        end
                    end
                end)
            end)
        else
            Data.currentTarget = nil
            if Connections.autoKill then
                Connections.autoKill:Disconnect()
            end
            Notify("Disabled", "Auto Kill OFF")
        end
    end
})

-- Visual Tab
VisualTab:CreateSection("🎯 Hitbox Expander")

VisualTab:CreateSlider({
    Name = "Size",
    Range = {5, 100},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 20,
    Callback = function(value)
        Config.hitboxSize = value
        if State.hitboxEnabled then
            RestoreHitbox()
            ExpandHitbox(value)
        end
    end
})

VisualTab:CreateToggle({
    Name = "Enable Hitbox",
    CurrentValue = false,
    Callback = function(value)
        State.hitboxEnabled = value
        
        if value then
            local count = ExpandHitbox(Config.hitboxSize)
            Notify("Enabled", "Hitbox ON: " .. count)
            
            Connections.hitbox = RunService.Heartbeat:Connect(function()
                pcall(function()
                    ExpandHitbox(Config.hitboxSize)
                end)
            end)
        else
            RestoreHitbox()
            if Connections.hitbox then
                Connections.hitbox:Disconnect()
            end
            Notify("Disabled", "Hitbox OFF")
        end
    end
})

-- Credits
CreditsTab:CreateParagraph({
    Title = "🌿 Protect a Garden Hub",
    Content = "Made by Rey_Script\nVersion: 2.1\n\nFeatures:\n• Item Pickup\n• Auto Money\n• Kill Aura\n• Auto Kill\n• Hitbox Expander"
})

print("✅ Rey_Script Hub v2.1 loaded successfully!")
