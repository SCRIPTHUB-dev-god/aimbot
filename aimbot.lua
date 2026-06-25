local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local PathfindingService = game:GetService("PathfindingService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlaceId = game.PlaceId
local Platform = UserInputService.TouchEnabled and "Mobile" or "PC"

local function CopyToClipboard(text)
    if setclipboard then
        setclipboard(tostring(text))
    elseif toclipboard then
        toclipboard(tostring(text))
    end
end

local function doServerHop()
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    
    if success and result and result.data then
        local servers = {}
        for _, s in ipairs(result.data) do
            if type(s) == "table" and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.id ~= game.JobId then
                table.insert(servers, s.id)
            end
        end
        
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)
        else
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end
    else
        TeleportService:Teleport(PlaceId, LocalPlayer)
    end
end

local function doRejoin()
    TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, LocalPlayer)
end

local Window = Library:CreateWindow({
    Title = "Aimbot pro",
    Footer = "version: 1.2.0",
    AutoShow = false,
    Icon = "snowflake",
    NotifySide = "Right",
})

local Tab = Window:AddTab("support", "info")
local infoGroupBox = Tab:AddLeftGroupbox("info", "info")
local gameid = Tab:AddRightGroupbox("game id", "info")

local MainTab = Window:AddTab("Main", "laptop")
local PlayerTab = Window:AddTab("Player", "user") 

local ESP = MainTab:AddLeftTabbox("ESP")
local Aimbot = MainTab:AddRightTabbox("Aimbot")

local EspMainTab = ESP:AddTab("Main", "laptop")
local EspSettingsTab = ESP:AddTab("Settings", "settings")

local AimbotMainTab = Aimbot:AddTab("Main", "laptop")
local AimbotSettingsTab = Aimbot:AddTab("Settings", "settings")

local PlayerTabbox = PlayerTab:AddLeftTabbox("Player Modifications")
local PlayerModTab = PlayerTabbox:AddTab("Player", "user")     
local PlayerSettingTab = PlayerTabbox:AddTab("Setting", "settings") 

local BotsTabbox = PlayerTab:AddRightTabbox("Bots Configuration")
local BotsMainTab = BotsTabbox:AddTab("Bots", "laptop")
local BotsSettingTab = BotsTabbox:AddTab("Setting", "settings")

local SettingTab = Window:AddTab("Setting", "settings")
local setGroupBox = SettingTab:AddLeftGroupbox("Setting", "settings")
local seGroupBox = SettingTab:AddRightGroupbox("credits", "clipboard")

local Options = Library.Options
local Toggles = Library.Toggles

local Crosshair = Drawing.new("Circle")
Crosshair.Radius = 6
Crosshair.Color = Color3.fromRGB(255, 0, 0)
Crosshair.Thickness = 1.5
Crosshair.Filled = false
Crosshair.Visible = false

local TargetInfoText = Drawing.new("Text")
TargetInfoText.Size = 18
TargetInfoText.Color = Color3.fromRGB(255, 255, 255)
TargetInfoText.Outline = true
TargetInfoText.Center = true
TargetInfoText.Visible = false

local ESP_Cache = {}
local Backup_Cache = {}
local CurrentTarget = nil
local PlayerRerolls = {}
local ChosenParts = {}
local lastPathComputed = 0
local currentWaypoints = {}
local currentWaypointIndex = 1

local BackupGui = CoreGui:FindFirstChild("ESP_Backup_Sys") or Instance.new("ScreenGui")
BackupGui.Name = "ESP_Backup_Sys"
BackupGui.ResetOnSpawn = false
if not BackupGui.Parent then BackupGui.Parent = CoreGui end

local Label = infoGroupBox:AddLabel("support my discord")
infoGroupBox:AddButton({Text = "Copy Discord", Func = function() local link = "https://discord.gg/mjhqEMRr" CopyToClipboard(link) end})
    
gameid:AddLabel("Place ID : " .. tostring(PlaceId))
gameid:AddLabel("Platform : " .. Platform)
gameid:AddButton({Text="Copy Place ID", Func=function() CopyToClipboard(PlaceId) end})

EspMainTab:AddToggle("Tracers", { Text = "Tracers", Default = false })
EspMainTab:AddToggle("TwoDBox", { Text = "2D Box", Default = false })
EspMainTab:AddToggle("ThreeDBox", { Text = "3D Box", Default = false })
EspMainTab:AddToggle("Name", { Text = "Name", Default = false })
EspMainTab:AddToggle("HealthNumber", { Text = "Health Number", Default = false })
EspMainTab:AddToggle("Distance", { Text = "Distance", Default = false })
EspMainTab:AddToggle("Highlight", { Text = "Highlight", Default = false })

EspSettingsTab:AddToggle("RainbowESP", { Text = "Rainbow ESP", Default = false })
EspSettingsTab:AddSlider("RainbowSpeed", { Text = "Rainbow Speed", Default = 2, Min = 1, Max = 10, Rounding = 0, Suffix = "" })
EspSettingsTab:AddSlider("ESPThickness", { Text = "ESP Thickness", Default = 1, Min = 1, Max = 5, Rounding = 0, Suffix = "px" })
EspSettingsTab:AddSlider("MaxEspDistance", { Text = "Max Distance", Default = 500, Min = 50, Max = 2000, Rounding = 0, Suffix = " studs" })
EspSettingsTab:AddToggle("UseBackupUI", { Text = "Force Backup ScreenUI", Default = false })

AimbotMainTab:AddToggle("AimbotToggle", { Text = "Enable Aimbot", Default = false })
AimbotMainTab:AddDropdown("AutoLookPart", { Text = "Look Target", Values = { "Head", "Body", "Full Body", "Random" }, Default = 1 })
AimbotMainTab:AddDivider() 
AimbotMainTab:AddToggle("SuperRadarAim", { Text = "360° Aimbot", Default = false })

AimbotSettingsTab:AddSlider("AimbotSmoothness", { Text = "Aimbot Smoothness", Default = 0, Min = 0, Max = 20, Rounding = 0, Suffix = "" })
AimbotSettingsTab:AddToggle("DisableCrosshair", { Text = "Disable Crosshair", Default = false })
AimbotSettingsTab:AddToggle("ShowTargetUI", { Text = "Show Target Info UI", Default = false })

PlayerModTab:AddToggle("EnableWalkSpeed", { Text = "Enable WalkSpeed", Default = false })
PlayerModTab:AddToggle("EnableJumpPower", { Text = "Enable Jump Power", Default = false })
PlayerModTab:AddDivider() 
PlayerModTab:AddToggle("BhopToggle", { Text = "Bunny Hop Loop Jump", Default = false })

PlayerSettingTab:AddSlider("WalkSpeedPower", { Text = "WalkSpeed Power", Default = 16, Min = 16, Max = 250, Rounding = 0, Suffix = " studs" })
PlayerSettingTab:AddDivider() 
PlayerSettingTab:AddSlider("JumpPowerPower", { Text = "Jump Power", Default = 50, Min = 50, Max = 500, Rounding = 0, Suffix = " power" })

BotsMainTab:AddToggle("AutoWalkToClosest", { Text = "Auto Walk To Closest Player", Default = false })

BotsSettingTab:AddDropdown("BotMovementStyle", { Text = "Movement Style", Values = { "Analyse", "Junius" }, Default = 1 })

setGroupBox:AddLabel("setting ui")
setGroupBox:AddButton({Text = "restart ui", Func = function() if Library then Library:Unload() end task.spawn(function() task.wait() loadstring(game:HttpGet("https://raw.githubusercontent.com/SCRIPTHUB-dev-god/king-icarus/refs/heads/script/main/game.lua",true))() end) end})
setGroupBox:AddButton({Text = "delete ui", Func = function() Library:Unload() end})
setGroupBox:AddDivider()
setGroupBox:AddButton({Text = "Server Hop", Func = doServerHop})
setGroupBox:AddButton({Text = "Rejoin", Func = doRejoin})

seGroupBox:AddLabel("credits by")
seGroupBox:AddLabel("• ICARUS hub")
seGroupBox:AddLabel("• mspaint")
seGroupBox:AddLabel("• others")
seGroupBox:AddDivider()
seGroupBox:AddLabel("logs update")
seGroupBox:AddLabel("• fixed icon gag2")
seGroupBox:AddLabel("• add button delete ui")
seGroupBox:AddLabel("• new icon ui loading and main ui")

local function GetESPColor()
    if Toggles.RainbowESP.Value then
        return Color3.fromHSV((tick() * (Options.RainbowSpeed.Value / 10)) % 1, 1, 1)
    end
    return Color3.fromRGB(255, 255, 255)
end

local function CreateDrawingESP(player)
    if ESP_Cache[player] then return end
    ESP_Cache[player] = {
        Tracer = Drawing.new("Line"), Box = Drawing.new("Square"), Name = Drawing.new("Text"), Health = Drawing.new("Text"), Distance = Drawing.new("Text")
    }
    local d = ESP_Cache[player]
    d.Name.Center = true; d.Name.Outline = true; d.Name.Size = 14
    d.Health.Outline = true; d.Health.Size = 14
    d.Distance.Center = true; d.Distance.Outline = true; d.Distance.Size = 12
end

local function CreateBackupESP(player)
    if Backup_Cache[player] then return end
    local char = player.Character
    if not char then return end
    
    local bGui = Instance.new("BillboardGui")
    bGui.Name = player.Name .. "_BGui"; bGui.AlwaysOnTop = true; bGui.Size = UDim2.new(4, 0, 5.5, 0)
    bGui.Adornee = char:FindFirstChild("HumanoidRootPart"); bGui.Parent = BackupGui
    
    local boxFrame = Instance.new("Frame")
    boxFrame.Name = "BoxFrame"; boxFrame.BackgroundTransparency = 1; boxFrame.Size = UDim2.new(1, 0, 1, 0); boxFrame.BorderSizePixel = 1; boxFrame.Parent = bGui
    
    local infoList = Instance.new("Frame")
    infoList.Size = UDim2.new(1, 0, 1, 0); infoList.BackgroundTransparency = 1; infoList.Parent = bGui
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Position = UDim2.new(0, 0, -0.3, 0); nameLabel.Size = UDim2.new(1, 0, 0.2, 0); nameLabel.BackgroundTransparency = 1; nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255); nameLabel.TextStrokeTransparency = 0; nameLabel.Parent = infoList
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Position = UDim2.new(-0.4, 0, 0, 0); healthLabel.Size = UDim2.new(0.3, 0, 1, 0); healthLabel.BackgroundTransparency = 1; healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0); healthLabel.TextStrokeTransparency = 0; healthLabel.Parent = infoList

    local distLabel = Instance.new("TextLabel")
    distLabel.Position = UDim2.new(0, 0, 1, 0); distLabel.Size = UDim2.new(1, 0, 0.2, 0); distLabel.BackgroundTransparency = 1; distLabel.TextColor3 = Color3.fromRGB(255, 255, 255); distLabel.TextStrokeTransparency = 0; distLabel.Parent = infoList

    local sBox = Instance.new("SelectionBox")
    sBox.Adornee = char; sBox.Color3 = Color3.fromRGB(255, 255, 255); sBox.Parent = BackupGui

    local hl = Instance.new("Highlight")
    hl.Adornee = char; hl.FillTransparency = 0.5; hl.Parent = BackupGui

    Backup_Cache[player] = {
        Gui = bGui, Box = boxFrame, Name = nameLabel, Health = healthLabel, Distance = distLabel, Box3D = sBox, Highlight = hl
    }
end

local function RemoveESP(player)
    if ESP_Cache[player] then
        for _, obj in pairs(ESP_Cache[player]) do obj:Remove() end
        ESP_Cache[player] = nil
    end
    if Backup_Cache[player] then
        if Backup_Cache[player].Gui then Backup_Cache[player].Gui:Destroy() end
        if Backup_Cache[player].Box3D then Backup_Cache[player].Box3D:Destroy() end
        if Backup_Cache[player].Highlight then Backup_Cache[player].Highlight:Destroy() end
        Backup_Cache[player] = nil
    end
end

local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if player.Character.Parent ~= Workspace then return false end
    return true
end

local function IsVisible(player, part)
    if not part then return false end
    local castPoints = {Camera.CFrame.Position, part.Position}
    local ignoreList = {LocalPlayer.Character, player.Character}
    local parts = Camera:GetPartsObscuringTarget(castPoints, ignoreList)
    return #parts == 0
end

local function GetBestPart(player, mode)
    if not IsAlive(player) then return nil end
    local char = player.Character
    
    if mode == "Head" then
        return char:FindFirstChild("Head")
    elseif mode == "Body" then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    elseif mode == "Full Body" then
        local parts = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
        for _, partName in pairs(parts) do
            local p = char:FindFirstChild(partName)
            if p and IsVisible(player, p) then return p end
        end
        return char:FindFirstChild("HumanoidRootPart")
    elseif mode == "Random" then
        if not PlayerRerolls[player.UserId] or ChosenParts[player.UserId] == nil then
            PlayerRerolls[player.UserId] = true
            if math.random(1, 100) <= 25 then
                ChosenParts[player.UserId] = char:FindFirstChild("Head")
            else
                ChosenParts[player.UserId] = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            end
        end
        return ChosenParts[player.UserId]
    end
    return nil
end

local function ValidateTarget(player)
    if not IsAlive(player) then return false end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local targetPart = GetBestPart(player, Options.AutoLookPart.Value)
    if not targetPart or not IsVisible(player, targetPart) then return false end
    
    if not Toggles.SuperRadarAim.Value then
        local _, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then return false end
    end
    return true
end

local function GetClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local targetPart = GetBestPart(player, Options.AutoLookPart.Value)
            
            if targetPart and IsVisible(player, targetPart) then
                local valid = false
                if Toggles.SuperRadarAim.Value then
                    valid = true
                else
                    local _, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then valid = true end
                end
                
                if valid then
                    local dist
                    if Toggles.SuperRadarAim.Value and myRoot then
                        dist = (root.Position - myRoot.Position).Magnitude
                    else
                        local screenPos, _ = Camera:WorldToViewportPoint(root.Position)
                        local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    end
                    
                    if dist < shortestDistance then
                        closest = player
                        shortestDistance = dist
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    Crosshair.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    Crosshair.Visible = Toggles.AimbotToggle.Value and not Toggles.DisableCrosshair.Value
    TargetInfoText.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 120)

    local color = GetESPColor()
    local thickness = Options.ESPThickness.Value
    local useBackup = Toggles.UseBackupUI.Value or (Drawing == nil)
    local maxDistance = Options.MaxEspDistance.Value
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    
    if myHum and myHum.Health > 0 and myRoot then
        if Toggles.EnableWalkSpeed.Value then
            myHum.WalkSpeed = Options.WalkSpeedPower.Value
        else
            myHum.WalkSpeed = 16
        end
        
        if Toggles.EnableJumpPower.Value then
            myHum.UseJumpPower = true
            myHum.JumpPower = Options.JumpPowerPower.Value
        else
            if myHum.JumpPower ~= 50 and Options.JumpPowerPower.Value ~= 50 then
                myHum.JumpPower = 50 
            end
        end
        
        if Toggles.BhopToggle.Value then
            if myHum.FloorMaterial ~= Enum.Material.Air then
                myHum.Jump = true
            end
        end

        if Toggles.AutoWalkToClosest.Value then
            local botTarget = nil
            local shortestBotDist = math.huge
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and IsAlive(player) and player.Character:FindFirstChild("HumanoidRootPart") then
                    local tRoot = player.Character.HumanoidRootPart
                    local currentDist = (tRoot.Position - myRoot.Position).Magnitude
                    if currentDist < shortestBotDist then
                        shortestBotDist = currentDist
                        botTarget = player
                    end
                end
            end
            
            if botTarget then
                local targetRoot = botTarget.Character.HumanoidRootPart
                local currentStyle = Options.BotMovementStyle.Value
                local finalTargetPos = targetRoot.Position
                
                if currentStyle == "Analyse" then
                    finalTargetPos = targetRoot.Position + Vector3.new(math.sin(tick() * 3) * 2, 0, math.cos(tick() * 2) * 2)
                end
                
                if tick() - lastPathComputed > 0.3 then
                    lastPathComputed = tick()
                    task.spawn(function()
                        local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
                        path:ComputeAsync(myRoot.Position, finalTargetPos)
                        if path.Status == Enum.PathStatus.Success then
                            currentWaypoints = path:GetWaypoints()
                            currentWaypointIndex = 2
                        end
                    end)
                end
                
                if #currentWaypoints > 0 and currentWaypointIndex <= #currentWaypoints then
                    local currentWaypoint = currentWaypoints[currentWaypointIndex]
                    local waypointPos = currentWaypoint.Position
                    local movePos = waypointPos
                    
                    if currentStyle == "Junius" then
                        local proStrafe = math.sin(tick() * 8) * 4
                        movePos = waypointPos + (myRoot.CFrame.RightVector * proStrafe)
                        if shortestBotDist < 30 and math.random(1, 100) <= 8 and myHum.FloorMaterial ~= Enum.Material.Air then
                            myHum.Jump = true
                        end
                    end
                    
                    myHum:MoveTo(movePos)
                    
                    if (myRoot.Position - waypointPos).Magnitude < 4 then
                        currentWaypointIndex = currentWaypointIndex + 1
                    end
                    
                    if currentWaypoint.Action == Enum.PathWaypointAction.Jump then
                        myHum.Jump = true
                    end
                else
                    myHum:MoveTo(finalTargetPos)
                end
                
                local lookDirection = (finalTargetPos - myRoot.Position).Unit
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {myChar}
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local rayOrigin = myRoot.Position - Vector3.new(0, 1, 0)
                local rayDirection = lookDirection * 4.5 
                local wallCheckResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                
                if wallCheckResult and wallCheckResult.Instance then
                    local hitPart = wallCheckResult.Instance
                    if hitPart.CanCollide and hitPart.Size.Y >= 1.5 then
                        myHum.Jump = true
                    end
                end
                
                local ladderCheckResult = Workspace:Raycast(myRoot.Position, lookDirection * 2.5, raycastParams)
                local isLadderPart = false
                
                if ladderCheckResult and ladderCheckResult.Instance then
                    local hitObj = ladderCheckResult.Instance
                    if hitObj:IsA("TrussPart") or string.find(string.lower(hitObj.Name), "ladder") or string.find(string.lower(hitObj.Name), "tangga") then
                        isLadderPart = true
                    end
                end
                
                if myHum:GetState() == Enum.HumanoidStateType.Climbing or isLadderPart then
                    myHum:ChangeState(Enum.HumanoidStateType.Climbing)
                    myHum:Move(Vector3.new(0, 1, 0.1), true)
                end
            end
        end
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if IsAlive(player) and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") then
                
                local root = player.Character.HumanoidRootPart
                local head = player.Character.Head
                local hum = player.Character.Humanoid
                local distance = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
                
                if distance <= maxDistance then
                    local topPos, topOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.6, 0))
                    local botPos, botOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                    local onScreen = topOn or botOn

                    if useBackup then
                        if ESP_Cache[player] then
                            for _, obj in pairs(ESP_Cache[player]) do obj.Visible = false end
                        end
                        
                        CreateBackupESP(player)
                        local b = Backup_Cache[player]
                        if b then
                            b.Gui.Enabled = onScreen; b.Gui.Adornee = root
                            b.Box.Visible = Toggles.TwoDBox.Value; b.Box.BorderColor3 = color; b.Box.BorderSizePixel = thickness
                            b.Name.Visible = Toggles.Name.Value; b.Name.Text = player.Name; b.Name.TextColor3 = color
                            b.Health.Visible = Toggles.HealthNumber.Value; b.Health.Text = "[" .. tostring(math.floor(hum.Health)) .. "]"
                            b.Distance.Visible = Toggles.Distance.Value; b.Distance.Text = tostring(distance) .. " studs"; b.Distance.TextColor3 = color
                            b.Box3D.Visible = Toggles.ThreeDBox.Value; b.Box3D.Adornee = player.Character; b.Box3D.Color3 = color; b.Box3D.LineThickness = thickness
                            b.Highlight.Enabled = Toggles.Highlight.Value; b.Highlight.Adornee = player.Character; b.Highlight.FillColor = color; b.Highlight.OutlineColor = color
                        end
                    else
                        if Backup_Cache[player] then
                            if Backup_Cache[player].Gui then Backup_Cache[player].Gui.Enabled = false end
                            if Backup_Cache[player].Box3D then Backup_Cache[player].Box3D.Visible = false end
                            if Backup_Cache[player].Highlight then Backup_Cache[player].Highlight.Enabled = false end
                        end
                        
                        CreateDrawingESP(player)
                        local d = ESP_Cache[player]
                        
                        if d and onScreen then
                            local height = math.abs(topPos.Y - botPos.Y)
                            local width = height * 0.55
                            local xPos = topPos.X - (width / 2)
                            local yPos = topPos.Y
                            
                            d.Box.Visible = Toggles.TwoDBox.Value; d.Box.Size = Vector2.new(width, height); d.Box.Position = Vector2.new(xPos, yPos); d.Box.Color = color; d.Box.Thickness = thickness
                            d.Tracer.Visible = Toggles.Tracers.Value; d.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); d.Tracer.To = Vector2.new(topPos.X, botPos.Y - (height/2)); d.Tracer.Color = color; d.Tracer.Thickness = thickness
                            d.Name.Visible = Toggles.Name.Value; d.Name.Text = player.Name; d.Name.Position = Vector2.new(topPos.X, yPos - 16); d.Name.Color = color
                            d.Health.Visible = Toggles.HealthNumber.Value; d.Health.Text = tostring(math.floor(hum.Health)); d.Health.Position = Vector2.new(xPos - 25, yPos + (height / 2) - 7); d.Health.Color = Color3.fromRGB(0, 255, 0)
                            d.Distance.Visible = Toggles.Distance.Value; d.Distance.Text = tostring(distance) .. " studs"; d.Distance.Position = Vector2.new(topPos.X, yPos + height + 4); d.Distance.Color = color
                            
                            CreateBackupESP(player)
                            if Backup_Cache[player] then
                                Backup_Cache[player].Highlight.Enabled = Toggles.Highlight.Value; Backup_Cache[player].Highlight.FillColor = color; Backup_Cache[player].Highlight.OutlineColor = color
                                Backup_Cache[player].Box3D.Visible = Toggles.ThreeDBox.Value; Backup_Cache[player].Box3D.Color3 = color
                            end
                        else
                            if d then
                                d.Box.Visible = false; d.Tracer.Visible = false; d.Name.Visible = false; d.Health.Visible = false; d.Distance.Visible = false
                            end
                        end
                    end
                else
                    RemoveESP(player)
                end
            else
                RemoveESP(player)
            end
        end
    end
    
    if Toggles.AimbotToggle.Value then
        CurrentTarget = GetClosestPlayer()
        
        if CurrentTarget and IsAlive(CurrentTarget) then
            local targetPart = GetBestPart(CurrentTarget, Options.AutoLookPart.Value)
            if targetPart and IsVisible(CurrentTarget, targetPart) then
                local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                local smoothness = Options.AimbotSmoothness.Value
                
                if smoothness > 0 then
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / (smoothness + 1))
                else
                    Camera.CFrame = targetCFrame
                end
                
                if Toggles.ShowTargetUI.Value then
                    local displayedPartName = (targetPart.Name == "HumanoidRootPart") and "Body" or targetPart.Name
                    TargetInfoText.Text = CurrentTarget.Name .. " | " .. displayedPartName
                    TargetInfoText.Visible = true
                else
                    TargetInfoText.Visible = false
                end
            else
                TargetInfoText.Visible = false
            end
        else
            TargetInfoText.Visible = false
        end
    else
        CurrentTarget = nil
        TargetInfoText.Visible = false
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
    PlayerRerolls[player.UserId] = nil
    ChosenParts[player.UserId] = nil
end)
