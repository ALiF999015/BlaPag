--[[
    Protect a Garden - Rey_Script Hub
    Created by Rey_Script
    Version: 3.0 - Using Fluent UI
]]

print("🌿 Loading Rey_Script Hub v3.0...")

-- Wait for game
repeat task.wait() until game:IsLoaded()

-- Load Fluent UI Library (more reliable than Rayfield)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local Config = {
    itemName = "",
    toolName = "",
    killAuraRadius = 20,
    hitboxSize = 20,
    moneyDistance = 50,
    moneyMode = "No TP"
}

local State = {
    killAura = false,
    hitbox = false,
    autoMoney = false,
    autoKill = false
}

local Connections = {}
local Data = {
    originalSizes = {},
    collectedMoney = {},
    currentTarget = nil
}

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "🌿 Protect a Garden - Rey_Script Hub",
    SubTitle = "by Rey_Script",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "🏠 Main", Icon = "" }),
    Farm = Window:AddTab({ Title = "💰 Farm", Icon = "" }),
    Combat = Window:AddTab({ Title = "⚔️ Combat", Icon = "" }),
    AutoKill = Window:AddTab({ Title = "🎯 Auto Kill", Icon = "" }),
    Visual = Window:AddTab({ Title = "👁️ Visual", Icon = "" }),
    Settings = Window:AddTab({ Title = "⚙️ Settings", Icon = "" })
}

-- Utility Functions
local function Notify(title, content)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = 3
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
            local mainPart = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
            
            if mainPart and mainPart:IsA("BasePart") then
                if not Data.originalSizes[mainPart] then
                    Data.originalSizes[mainPart] = {
                        Size = mainPart.Size,
                        Transparency = mainPart.Transparency,
                        CanCollide = mainPart.CanCollide,
                        Material = mainPart.Material,
                        Massless = mainPart.Massless or false
                    }
                end
                
                mainPart.Size = Vector3.new(size, size, size)
                mainPart.Transparency = 0.7
                mainPart.CanCollide = false
                mainPart.Massless = true
                
                if mainPart.Transparency < 1 then
                    mainPart.Material = Enum.Material.ForceField
                end
                
                count = count + 1
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

local function AutoGetMoney()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character.HumanoidRootPart
    
    if Config.moneyMode == "TP Money" then
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Name == "Money" and not Data.collectedMoney[part] and part.Parent then
                pcall(function()
                    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.2)
                    
                    if firetouchinterest then
                        firetouchinterest(hrp, part, 0)
                        task.wait(0.1)
                        firetouchinterest(hrp, part, 1)
                        task.wait(0.1)
                    end
                    
                    local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and fireproximityprompt then
                        fireproximityprompt(prompt)
                        task.wait(0.1)
                    end
                    
                    local clickDetector = part:FindFirstChildOfClass("ClickDetector")
                    if clickDetector and fireclickdetector then
                        fireclickdetector(clickDetector)
                        task.wait(0.1)
                    end
                    
                    Data.collectedMoney[part] = true
                end)
                task.wait(0.05)
            end
        end
    else
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Name == "Money" and not Data.collectedMoney[part] and part.Parent then
                local distance = (part.Position - hrp.Position).Magnitude
                
                if distance <= Config.moneyDistance then
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
        end
    end
    
    for part, _ in pairs(Data.collectedMoney) do
        if not part or not part.Parent then
            Data.collectedMoney[part] = nil
        end
    end
end

-- Main Tab
Tabs.Main:AddParagraph({
    Title = "📦 Item Pickup",
    Content = "Enter item name and execute pickup"
})

local ItemInput = Tabs.Main:AddInput("ItemInput", {
    Title = "Item Name",
    Default = "",
    Placeholder = "Enter item name...",
    Numeric = false,
    Finished = false,
    Callback = function(value)
        Config.itemName = value
    end
})

Tabs.Main:AddButton({
    Title = "Execute Item Pickup",
    Description = "Pickup the specified item",
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
Tabs.Farm:AddParagraph({
    Title = "💰 Auto Get Money",
    Content = "Automatically collect money parts"
})

local MoneyDropdown = Tabs.Farm:AddDropdown("MoneyMode", {
    Title = "Collection Mode",
    Values = {"No TP", "TP Money"},
    Multi = false,
    Default = 1,
})

MoneyDropdown:OnChanged(function(value)
    Config.moneyMode = value
end)

local DistanceSlider = Tabs.Farm:AddSlider("MoneyDistance", {
    Title = "No TP Distance",
    Description = "Interaction range for No TP mode",
    Default = 50,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        Config.moneyDistance = value
    end
})

local AutoMoneyToggle = Tabs.Farm:AddToggle("AutoMoney", {
    Title = "Enable Auto Money",
    Default = false
})

AutoMoneyToggle:OnChanged(function()
    State.autoMoney = AutoMoneyToggle.Value
    
    if State.autoMoney then
        Data.collectedMoney = {}
        Notify("Enabled", "Auto Money: " .. Config.moneyMode)
        
        Connections.autoMoney = RunService.Heartbeat:Connect(function()
            pcall(AutoGetMoney)
        end)
    else
        if Connections.autoMoney then
            Connections.autoMoney:Disconnect()
        end
        Notify("Disabled", "Auto Money OFF")
    end
end)

Tabs.Farm:AddButton({
    Title = "Reset Money Cache",
    Description = "Clear collected money list",
    Callback = function()
        Data.collectedMoney = {}
        Notify("Reset", "Cache cleared!")
    end
})

-- Combat Tab
Tabs.Combat:AddParagraph({
    Title = "⚔️ Kill Aura",
    Content = "Attack enemies within radius"
})

local ToolInput = Tabs.Combat:AddInput("ToolInput", {
    Title = "Tool Name",
    Default = "",
    Placeholder = "Enter tool name...",
    Numeric = false,
    Finished = false,
    Callback = function(value)
        Config.toolName = value
    end
})

local RadiusSlider = Tabs.Combat:AddSlider("KillRadius", {
    Title = "Kill Aura Radius",
    Description = "Attack range in studs",
    Default = 20,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Config.killAuraRadius = value
    end
})

local KillAuraToggle = Tabs.Combat:AddToggle("KillAura", {
    Title = "Enable Kill Aura",
    Default = false
})

KillAuraToggle:OnChanged(function()
    State.killAura = KillAuraToggle.Value
    
    if State.killAura then
        if Config.toolName == "" then
            Notify("Error", "Enter tool name!")
            KillAuraToggle:SetValue(false)
            return
        end
        
        Notify("Enabled", "Kill Aura: " .. Config.killAuraRadius .. " studs")
        
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
end)

-- Auto Kill Tab
Tabs.AutoKill:AddParagraph({
    Title = "🎯 Auto Kill Enemy",
    Content = "Teleport to enemies and kill them"
})

local AutoKillToolInput = Tabs.AutoKill:AddInput("AutoKillTool", {
    Title = "Tool Name",
    Default = "",
    Placeholder = "Enter tool name...",
    Numeric = false,
    Finished = false,
    Callback = function(value)
        Config.toolName = value
    end
})

local AutoKillToggle = Tabs.AutoKill:AddToggle("AutoKill", {
    Title = "Enable Auto Kill",
    Default = false
})

AutoKillToggle:OnChanged(function()
    State.autoKill = AutoKillToggle.Value
    
    if State.autoKill then
        if Config.toolName == "" then
            Notify("Error", "Enter tool name!")
            AutoKillToggle:SetValue(false)
            return
        end
        
        Notify("Enabled", "Auto Kill hunting...")
        
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
end)

-- Visual Tab
Tabs.Visual:AddParagraph({
    Title = "🎯 Hitbox Expander",
    Content = "Expand enemy hitboxes"
})

local HitboxSlider = Tabs.Visual:AddSlider("HitboxSize", {
    Title = "Hitbox Size",
    Description = "Size in studs",
    Default = 20,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Config.hitboxSize = value
        if State.hitbox then
            RestoreHitbox()
            ExpandHitbox(value)
        end
    end
})

local HitboxToggle = Tabs.Visual:AddToggle("Hitbox", {
    Title = "Enable Hitbox Expander",
    Default = false
})

HitboxToggle:OnChanged(function()
    State.hitbox = HitboxToggle.Value
    
    if State.hitbox then
        local count = ExpandHitbox(Config.hitboxSize)
        Notify("Enabled", "Hitbox: " .. count .. " enemies")
        
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
end)

-- Settings Tab
Tabs.Settings:AddParagraph({
    Title = "🌿 Protect a Garden Hub",
    Content = "Version: 3.0\nMade by Rey_Script\n\nFeatures:\n• Item Pickup\n• Auto Money (2 Modes)\n• Kill Aura\n• Auto Kill Enemy\n• Hitbox Expander"
})

print("✅ Rey_Script Hub v3.0 loaded successfully!")
