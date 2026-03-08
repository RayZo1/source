if _G.Loaded == true then 
    if shared.config.General and shared.config.General.Console == true then
        print(" [+] Updated config")
    end
    shared._configUpdated = true
    return
end
_G.Loaded = true
if shared.config.General and shared.config.General.Console == true then
    print(" [+] Loading")
end

loadstring([[function LPH_NO_VIRTUALIZE(f) return f end;]])();

-- safety
if not checkcaller then checkcaller = function() return false end end

-- services
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- config cache
local cfg = shared.config
local general = cfg.General
local silentCfg = cfg['Silent Aim']
local camCfg = cfg['Camera Aimbot']
local triggerCfg = cfg['Trigger Bot']
local espCfg = cfg['ESP']
local condSelected = cfg.Conditions["Whilst a player is selected"]
local condSelecting = cfg.Conditions["Whilst selecting a player"]

-- state
local camlockPaused = false
local cameraTarget = nil
local triggerBox = nil
local lastActivationTime = 0
local triggerKeyDown = false
local triggerToggled = false
local lockedPlayer = nil
local originalIndex
local box = nil
local BOX_VISIBLE = true
local targetKnocked = false
local selfKnocked = false
local camBox = nil
local espLabels = {}

-- gui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "bwq2"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")

local targetLabel = Instance.new("TextLabel")
targetLabel.Name = "zxcxwa2"
targetLabel.Size = UDim2.new(0, 200, 0, 20)
targetLabel.Position = UDim2.new(0, general.Info.Position.X, 0, general.Info.Position.Y)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "target: None"
targetLabel.TextColor3 = Color3.new(1, 1, 1)
targetLabel.TextStrokeTransparency = 0.8
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextSize = 14
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.RichText = true
targetLabel.Parent = screenGui

-- reusable raycast params
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true

-- fov cache
local fovCache = {
    silent = { base = Vector3.new(4,6,2), shotguns = Vector3.new(6,8,3), pistols = Vector3.new(4,5,2) },
    cam = { base = Vector3.new(4,6,2), shotguns = Vector3.new(15,9,15), pistols = Vector3.new(15,8,15) }
}
local lastWeaponFOV = nil
local lastWeaponName = nil

-- weapon type tables
local ShotgunNames = { ["Double-Barrel SG"] = true, ["TacticalShotgun"] = true, ["Shotgun"] = true, ["DrumShotgun"] = true }
local PistolNames = { ["Revolver"] = true, ["Silencer"] = true, ["Glock"] = true }

-- helper: clear all boxes
local function clearBoxes()
    if box then box:Destroy(); box = nil end
    if camBox then camBox:Destroy(); camBox = nil end
    if triggerBox then triggerBox:Destroy(); triggerBox = nil end
end

local function updateDebugGUI()
    if shared._configUpdated then shared._configUpdated = false end
    local info = general.Info
    screenGui.Enabled = info.Enabled
    if not info.Enabled then return end
    targetLabel.Position = UDim2.new(0, info.Position.X, 0, info.Position.Y)
    if lockedPlayer and lockedPlayer.Character then
        local name = lockedPlayer.DisplayName or lockedPlayer.Name
        targetLabel.Text = "target: " .. name
        targetLabel.TextColor3 = Color3.new(1,1,1)
    else
        targetLabel.Text = "target: None"
        targetLabel.TextColor3 = Color3.new(0.7,0.7,0.7)
    end
end

-- ESP
local function addESPToPlayer(player)
    if player == LocalPlayer then return end
    local esp = {
        player = player,
        nameTag = Drawing.new("Text"),
    }
    esp.nameTag.Size = 14
    esp.nameTag.Center = true
    esp.nameTag.Outline = true
    esp.nameTag.OutlineColor = Color3.fromRGB(0,0,0)
    esp.nameTag.Color = espCfg.Color
    esp.nameTag.Font = Drawing.Fonts.Plex
    esp.nameTag.Visible = false
    esp.nameTag.ZIndex = 1000
    espLabels[player.UserId] = esp
end

local function removeESPFromPlayer(player)
    local esp = espLabels[player.UserId]
    if esp then
        esp.nameTag:Remove()
        espLabels[player.UserId] = nil
    end
end

local function refreshESP()
    if not espCfg.Enabled then
        for _, esp in pairs(espLabels) do
            esp.nameTag.Visible = false
        end
        return
    end
    for userId, esp in pairs(espLabels) do
        local player = esp.player
        if not player or not player.Parent then
            esp.nameTag.Visible = false
            esp.nameTag:Remove()
            espLabels[userId] = nil
            continue
        end
        if player.Character and player.Character.Parent and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                esp.nameTag.Visible = false
                continue
            end
            local head = player.Character.Head
            local rootPart = player.Character.HumanoidRootPart
            local espPosition, onScreen
            if espCfg['Name Above'] then
                espPosition, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,1.5,0))
            else
                espPosition, onScreen = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0,2.8,0))
            end
            if onScreen and espPosition.Z > 0 then
                esp.nameTag.Position = Vector2.new(espPosition.X, espPosition.Y)
                if espCfg['Use Display Name'] then
                    esp.nameTag.Text = player.DisplayName
                else
                    esp.nameTag.Text = player.Name
                end
                if lockedPlayer == player then
                    esp.nameTag.Color = espCfg['Target Color']
                else
                    esp.nameTag.Color = espCfg.Color
                end
                esp.nameTag.Visible = true
            else
                esp.nameTag.Visible = false
            end
        else
            esp.nameTag.Visible = false
        end
    end
end

-- ESP connections
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        addESPToPlayer(player)
    end
    player.CharacterAdded:Connect(function(char)
        removeESPFromPlayer(player)
        char:WaitForChild("HumanoidRootPart")
        task.wait(0.1)
        addESPToPlayer(player)
    end)
    player.CharacterRemoving:Connect(function()
        removeESPFromPlayer(player)
    end)
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(char)
            removeESPFromPlayer(player)
            char:WaitForChild("HumanoidRootPart")
            task.wait(0.1)
            addESPToPlayer(player)
        end)
        player.CharacterRemoving:Connect(function()
            removeESPFromPlayer(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(removeESPFromPlayer)

-- crew check
local function isSameCrew(player)
    if not player then return false end
    local client = LocalPlayer
    local clientCrew = client:FindFirstChild("DataFolder")
        and client.DataFolder:FindFirstChild("Information")
        and client.DataFolder.Information:FindFirstChild("Crew")
        and tonumber(client.DataFolder.Information.Crew.Value)
    local playerCrew = player:FindFirstChild("DataFolder")
        and player.DataFolder:FindFirstChild("Information")
        and player.DataFolder.Information:FindFirstChild("Crew")
        and tonumber(player.DataFolder.Information.Crew.Value)
    if clientCrew and playerCrew and clientCrew > 0 and playerCrew > 0 then
        return clientCrew == playerCrew
    end
    return false
end

-- fov getters
local function getCurrentWeaponFOV()
    local silent = silentCfg
    local fovMain = silent.FOV
    if not fovMain.Enabled then
        return Vector3.new(9999,9999,9999)
    end
    local wc = fovMain['Weapon Configuration']
    local useWeaponConfig = wc and wc.Enabled
    if not useWeaponConfig then
        local base = fovMain.Size
        return Vector3.new(base.X or 0, base.Y or 0, base.Z or 0)
    end
    local character = LocalPlayer.Character
    if not character then
        local others = wc.Others
        return Vector3.new(others.X or 4, others.Y or 6, others.Z or 2)
    end
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then
        local others = wc.Others
        return Vector3.new(others.X or 4, others.Y or 6, others.Z or 2)
    end
    local weaponName = tool.Name:gsub("[%[%]]", "")
    local config
    if ShotgunNames[weaponName] then
        config = wc.Shotguns
    elseif PistolNames[weaponName] then
        config = wc.Pistols
    else
        config = wc.Others
    end
    return Vector3.new(config.X or 4, config.Y or 6, config.Z or 2)
end

local function isVisible(rootPart)
    local direction = rootPart.Position - Camera.CFrame.Position
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(Camera.CFrame.Position, direction, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(rootPart.Parent)
end

local function isTargetVisible(targetCharacter)
    if not targetCharacter or not targetCharacter:FindFirstChild("Head") then
        return false
    end
    local head = targetCharacter.Head
    local origin = Camera.CFrame.Position
    local direction = head.Position - origin
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(targetCharacter)
end

local function getCamlockFOV()
    local cam = camCfg
    local fovMain = cam.FOV
    if not fovMain.Enabled then
        return Vector3.new(9999,9999,9999)
    end
    local wc = fovMain['Weapon Configuration']
    if not wc.Enabled then
        local base = fovMain.Size
        return Vector3.new(base.X or 0, base.Y or 0, base.Z or 0)
    end
    local character = LocalPlayer.Character
    if not character then return Vector3.new(4,6,2) end
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return Vector3.new(wc.Others.X or 4, wc.Others.Y or 6, wc.Others.Z or 2) end
    local weaponName = tool.Name:gsub("[%[%]]", "")
    local config = wc.Others
    if ShotgunNames[weaponName] then
        config = wc.Shotguns
    elseif PistolNames[weaponName] then
        config = wc.Pistols
    end
    return Vector3.new(config.X or 4, config.Y or 6, config.Z or 2)
end

local function getTriggerbotFOV()
    local tb = triggerCfg
    local fov = tb.FOV
    return Vector3.new(fov.X or 0, fov.Y or 0, fov.Z or 0)
end

-- mouse in box checks
local function isMouseInCamBox()
    if not (cameraTarget and cameraTarget.Character) then return false end
    local root = cameraTarget.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local boxSize = getCamlockFOV()
    local half = Vector3.new(boxSize.X/2, boxSize.Y/2, boxSize.Z/2)
    local bMin = root.Position - half
    local bMax = root.Position + half
    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local o, d = ray.Origin, ray.Direction
    local tMin = (bMin - o) / d
    local tMax = (bMax - o) / d
    local t1 = Vector3.new(math.min(tMin.X,tMax.X), math.min(tMin.Y,tMax.Y), math.min(tMin.Z,tMax.Z))
    local t2 = Vector3.new(math.max(tMin.X,tMax.X), math.max(tMin.Y,tMax.Y), math.max(tMin.Z,tMax.Z))
    local tNear = math.max(t1.X, t1.Y, t1.Z)
    local tFar  = math.min(t2.X, t2.Y, t2.Z)
    return tNear <= tFar and tFar >= 0
end

local function isMouseInTriggerBox()
    if not lockedPlayer or not lockedPlayer.Character then return false end
    local root = lockedPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local fov = triggerCfg.FOV
    local half = Vector3.new(fov.X or 0, fov.Y or 0, fov.Z or 0) / 2
    local min = root.Position - half
    local max = root.Position + half
    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local tMin = (min - ray.Origin) / ray.Direction
    local tMax = (max - ray.Origin) / ray.Direction
    local t1 = Vector3.new(math.min(tMin.X,tMax.X), math.min(tMin.Y,tMax.Y), math.min(tMin.Z,tMax.Z))
    local t2 = Vector3.new(math.max(tMin.X,tMax.X), math.max(tMin.Y,tMax.Y), math.max(tMin.Z,tMax.Z))
    local tNear = math.max(t1.X, t1.Y, t1.Z)
    local tFar  = math.min(t2.X, t2.Y, t2.Z)
    return tNear <= tFar and tFar >= 0
end

local function getClosestPlayerToMouse()
    local renderDist = silentCfg.Distance
    local closest = nil
    local bestDist = math.huge
    local mx, my = Mouse.X, Mouse.Y
    local mousePos = Vector2.new(mx, my)
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if (root.Position - myRoot.Position).Magnitude <= renderDist then
                    local screenPos = Camera:WorldToViewportPoint(root.Position)
                    if screenPos.Z > 0 and isVisible(root) then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            closest = player
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function GetClosestPointAdvanced(Part, Scale)
    local cf = Part.CFrame
    local size = Part.Size * (Scale / 2)
    local ray = Mouse.UnitRay
    local rel = cf:PointToObjectSpace(ray.Origin + ray.Direction * ray.Direction:Dot(cf.Position - ray.Origin))
    return cf * Vector3.new(
        math.clamp(rel.X, -size.X, size.X),
        math.clamp(rel.Y, -size.Y, size.Y),
        math.clamp(rel.Z, -size.Z, size.Z)
    )
end

local function GetClosestPointBasic(Part)
    if not Part then return Part.Position end
    local ray = Mouse.UnitRay
    raycastParams.FilterDescendantsInstances = {Part}
    raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    return result and result.Position or Part.Position
end

local function GetClosestPartToCursor(Character)
    local bestPart = nil
    local bestDist = math.huge
    local mousePos = UserInput:GetMouseLocation()
    for _, part in ipairs(Character:GetChildren()) do
        if part:IsA("BasePart") then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestPart = part
                end
            end
        end
    end
    return bestPart or Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Head")
end

local getClosestPart = function(char)
    return GetClosestPartToCursor(char)
end

local function applyPrediction(partOrNil, basePos)
    if not partOrNil then return basePos end
    local pred = silentCfg.Prediction
    local vel = partOrNil.Velocity or Vector3.new(0,0,0)
    local offset = Vector3.new(
        vel.X * (pred.X or 0),
        vel.Y * (pred.Y or 0),
        vel.Z * (pred.Z or 0)
    )
    return basePos + offset
end

local function resolveHit(targetChar)
    local silent = silentCfg
    local mode = silent['Hit Part']
    local result = nil
    local sourcePart = nil
    if mode == "Closest Point" then
        sourcePart = getClosestPart(targetChar)
        if sourcePart then
            local cp = silent['Closest Point']
            local point = (cp.Type == "Advanced") and
                GetClosestPointAdvanced(sourcePart, cp.Scale or 0.6) or
                GetClosestPointBasic(sourcePart)
            result = point
        end
    elseif mode == "Closest Part" then
        sourcePart = getClosestPart(targetChar)
        if sourcePart then
            result = sourcePart.Position
        end
    elseif mode == "Head" then
        local head = targetChar:FindFirstChild("Head")
        if head then
            sourcePart = head
            result = head.Position
        end
    else
        local specific = targetChar:FindFirstChild(mode)
        if specific and specific:IsA("BasePart") then
            sourcePart = specific
            result = specific.Position
        end
    end
    if result and sourcePart then
        result = applyPrediction(sourcePart, result)
    end
    return result, sourcePart
end

local function canTargetPlayer(player)
    if not player or not player.Character then return false end
    local selectCond = condSelecting
    if selectCond["Self Knocked"] then
        local be = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("BodyEffects")
        if be and be:FindFirstChild("K.O") and be["K.O"].Value then
            return false
        end
    end
    if selectCond["Crew Check"] then
        if isSameCrew(player) then
            return false
        end
    end
    if selectCond["Knock Check"] then
        local be = player.Character:FindFirstChild("BodyEffects")
        if be and be:FindFirstChild("K.O") and be["K.O"].Value then
            return false
        end
    end
    if selectCond["Visible"] and not isTargetVisible(player.Character) then
        return false
    end
    return true
end

local function createSilentBox(targetPlayer)
    if box then box:Destroy() end
    local boxSize = getCurrentWeaponFOV()
    box = Instance.new("BoxHandleAdornment")
    box.Size = boxSize
    box.Color3 = Color3.fromRGB(255,0,0)
    box.Transparency = 1
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Adornee = targetPlayer.Character
    box.Parent = targetPlayer.Character
    if not BOX_VISIBLE then box.Transparency = 1 end
end

local function createTriggerBox(targetPlayer)
    if triggerBox then triggerBox:Destroy() end
    local fov = triggerCfg.FOV
    local boxSize = Vector3.new(fov.X or 0, fov.Y or 0, fov.Z or 0)
    triggerBox = Instance.new("BoxHandleAdornment")
    triggerBox.Size = boxSize
    triggerBox.Color3 = Color3.fromRGB(0,150,255)
    triggerBox.Transparency = 1
    triggerBox.AlwaysOnTop = true
    triggerBox.ZIndex = 12
    triggerBox.Adornee = targetPlayer.Character
    triggerBox.Parent = targetPlayer.Character
end

local function createCamBox(targetPlayer)
    if camBox then camBox:Destroy() end
    local boxSize = getCamlockFOV()
    camBox = Instance.new("BoxHandleAdornment")
    camBox.Size = boxSize
    camBox.Color3 = Color3.fromRGB(0,255,0)
    camBox.Transparency = 1
    camBox.AlwaysOnTop = true
    camBox.ZIndex = 11
    camBox.Adornee = targetPlayer.Character
    camBox.Parent = targetPlayer.Character
end

local function isMouseInBox()
    if not (lockedPlayer and lockedPlayer.Character) then return false end
    local root = lockedPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local boxSize = getCurrentWeaponFOV()
    local half = Vector3.new(boxSize.X/2, boxSize.Y/2, boxSize.Z/2)
    local bMin = root.Position - half
    local bMax = root.Position + half
    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local o, d = ray.Origin, ray.Direction
    local tMin = (bMin - o) / d
    local tMax = (bMax - o) / d
    local t1 = Vector3.new(math.min(tMin.X,tMax.X), math.min(tMin.Y,tMax.Y), math.min(tMin.Z,tMax.Z))
    local t2 = Vector3.new(math.max(tMin.X,tMax.X), math.max(tMin.Y,tMax.Y), math.max(tMin.Z,tMax.Z))
    local tNear = math.max(t1.X, t1.Y, t1.Z)
    local tFar  = math.min(t2.X, t2.Y, t2.Z)
    return tNear <= tFar and tFar >= 0
end

local function getToggleKey()
    return Enum.KeyCode[general.Toggle]
end

-- input
UserInput.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(inp, gp)
    if gp then return end
    if inp.KeyCode == getToggleKey() then
        if lockedPlayer then
            lockedPlayer = nil
            cameraTarget = nil
            clearBoxes()
        else
            local closest = getClosestPlayerToMouse()
            if closest and canTargetPlayer(closest) then
                lockedPlayer = closest
                cameraTarget = closest
                createSilentBox(closest)
                createCamBox(closest)
                createTriggerBox(closest)
            end
        end
    end
    if inp.KeyCode == Enum.KeyCode[espCfg.Activation['Activation Bind']] then
        local mode = espCfg.Activation['Activation Mode']
        if mode == "Toggle" then
            espCfg.Enabled = not espCfg.Enabled
        elseif mode == "Hold" then
            espCfg.Enabled = true
        end
    end
    local bind = Enum.KeyCode[triggerCfg.Activation['Activation Bind']]
    if inp.KeyCode == bind then
        local mode = triggerCfg.Activation['Activation Mode']
        if mode == "Toggle" then
            triggerToggled = not triggerToggled
        elseif mode == "Hold" then
            triggerKeyDown = true
        end
    end
end))

UserInput.InputEnded:Connect(LPH_NO_VIRTUALIZE(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode[espCfg.Activation['Activation Bind']] then
        local mode = espCfg.Activation['Activation Mode']
        if mode == "Hold" then
            espCfg.Enabled = false
        end
    end
    local bind = Enum.KeyCode[triggerCfg.Activation['Activation Bind']]
    if inp.KeyCode == bind then
        triggerKeyDown = false
    end
end))

-- mouse index hook
originalIndex = hookmetamethod(game, "__index", LPH_NO_VIRTUALIZE(function(self, key)
    if self == Mouse and (key == "Hit" or key == "Target") and lockedPlayer then
        if (not condSelected.Visible or isTargetVisible(lockedPlayer.Character)) and isMouseInBox() then
            local pos, part = resolveHit(lockedPlayer.Character)
            if pos and part then
                if key == "Hit" then
                    return CFrame.new(pos)
                else
                    return part
                end
            end
        end
    end
    return originalIndex(self, key)
end))

-- China stuff (untouched)
local DeepFakePosition = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nosssa/NossLock/main/GetRealMousePosition"))() 
task.wait()

local China = setmetatable({}, {
    __index = LPH_NO_VIRTUALIZE(function(Company, Price)
        return game:GetService(Price)
    end)
})
   
local ChinaWorld = China.Workspace
local Society = China.Players
local ChineseDeporation = China.ReplicatedStorage
local ChinaInputService = China.UserInputService

local ChingChong = Society.LocalPlayer
local Cat =  "meow!!" and ChingChong:GetMouse()

local ChineseEvent = ChineseDeporation:FindFirstChild("MainEvent") or nil
local Payment = "Hello Da Hoodian!" and nil

local RandomChinese = function(RandomCredit)
   return type(RandomCredit) == "number" and math.random(-RandomCredit, RandomCredit) or 0
end

local ChinaAlive = function(ChinesePlayer)
   return ChinesePlayer and ChinesePlayer.Character and ChinesePlayer.Character:FindFirstChild("Humanoid") and ChinesePlayer.Character:FindFirstChild("Head") or false
end

local GameArgs = {
    [9196894486] = "UpdateMousePos",
}

local DEFAULT_ARG = "UpdateMousePos"
local ChinaHook
ChinaHook = hookmetamethod(game, "__namecall", LPH_NO_VIRTUALIZE(function(self, ...)
    local ChinaArgs       = {...}
    local DeportationMethod = getnamecallmethod()
    local targetArg = GameArgs[game.PlaceId] or DEFAULT_ARG
    if not checkcaller()
    and DeportationMethod == "FireServer"
    and self.Name == "MainEvent"
    and ChinaArgs[1] == targetArg then
        return self.FireServer(self, unpack(ChinaArgs))
    end
    return ChinaHook(self, ...)
end))

-- math.random hook (unchanged)
local oldRandom
oldRandom = hookfunction(math.random, LPH_NO_VIRTUALIZE(function(...)
    local args = { ... }
    if checkcaller() then
        return oldRandom(...)
    end
    local multiplier = 1
    if cfg['Weapon Modifications'] and cfg['Weapon Modifications'].Enabled then
        local character = LocalPlayer.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                local weaponName = tool.Name:gsub("[%[%]]", "")
                local weaponMods = cfg['Weapon Modifications']
                if weaponMods['[Double-Barrel SG]'] and weaponName == "Double-Barrel SG" then
                    multiplier = weaponMods['[Double-Barrel SG]'].Multiplier or 1
                elseif weaponMods['[TacticalShotgun]'] and weaponName == "TacticalShotgun" then
                    multiplier = weaponMods['[TacticalShotgun]'].Multiplier or 1
                elseif weaponMods['[Shotgun]'] and weaponName == "Shotgun" then
                    multiplier = weaponMods['[Shotgun]'].Multiplier or 1
                elseif weaponMods['[DrumShotgun]'] and weaponName == "DrumShotgun" then
                    multiplier = weaponMods['[DrumShotgun]'].Multiplier or 1
                end
            end
        end
    end
    if
        (#args == 0)
        or (args[1] == -0.05 and args[2] == 0.05)
        or (args[1] == -0.1)
        or (args[1] == -0.05)
    then
        if multiplier ~= 1 then
            return oldRandom(...) * multiplier
        end
    end
    return oldRandom(...)
end))

-- render loop
RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
    local selectedCond = condSelected

    if general.Mode == 'Target' and lockedPlayer then
        local selfChar = LocalPlayer.Character
        local targetChar = lockedPlayer.Character
        local shouldUnlock = false
        if selectedCond["Self Knocked"] then
            local be = selfChar and selfChar:FindFirstChild("BodyEffects")
            if be and be:FindFirstChild("K.O") and be["K.O"].Value then
                shouldUnlock = true
            end
        end
        if selectedCond["Knock Check"] then
            local be = targetChar and targetChar:FindFirstChild("BodyEffects")
            if be and be:FindFirstChild("K.O") and be["K.O"].Value then
                shouldUnlock = true
            end
        end
        if shouldUnlock then
            lockedPlayer = nil
            cameraTarget = nil
            clearBoxes()
            return
        end
    end

    if general.Mode == 'Auto' then
        local closestToMouse = getClosestPlayerToMouse()
        if closestToMouse and closestToMouse.Character and canTargetPlayer(closestToMouse) then
            if lockedPlayer ~= closestToMouse then
                lockedPlayer = closestToMouse
                cameraTarget = closestToMouse
                clearBoxes()
                createSilentBox(closestToMouse)
                createCamBox(closestToMouse)
                createTriggerBox(closestToMouse)
            end
        else
            if lockedPlayer then
                lockedPlayer = nil
                cameraTarget = nil
                clearBoxes()
            end
        end
    end

    if box and lockedPlayer and lockedPlayer.Character then
        box.Size = getCurrentWeaponFOV()
        box.Adornee = lockedPlayer.Character
    end
    if camBox and cameraTarget and cameraTarget.Character then
        camBox.Size = getCamlockFOV()
        camBox.Adornee = cameraTarget.Character
    end
    if triggerBox and lockedPlayer and lockedPlayer.Character then
        local fov = triggerCfg.FOV
        triggerBox.Size = Vector3.new(fov.X or 0, fov.Y or 0, fov.Z or 0)
        triggerBox.Adornee = lockedPlayer.Character
    end

    if lockedPlayer and triggerCfg.Enabled and (not selectedCond.Visible or isTargetVisible(lockedPlayer.Character)) then
        local tb = triggerCfg
        local mode = tb.Activation['Activation Mode']
        local cooldown = tb['Click Cooldown']
        local char = LocalPlayer.Character
        local hasKnife = char and (char:FindFirstChild("[Knife]") or char:FindFirstChild("Knife"))
        if not hasKnife then
            local inBox = isMouseInTriggerBox()
            local active = false
            if mode == "Always" then
                active = true
            elseif mode == "Hold" then
                active = triggerKeyDown
            elseif mode == "Toggle" then
                active = triggerToggled
            end
            if inBox and active then
                local now = tick()
                if now - lastActivationTime >= cooldown then
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                        lastActivationTime = now
                    end
                end
            end
        end
    end

    if cameraTarget 
        and cameraTarget.Character 
        and camCfg.Enabled 
        and (not selectedCond.Visible or isTargetVisible(cameraTarget.Character))
        and (not selectedCond["Crew Check"] or not isSameCrew(cameraTarget))
        and isMouseInCamBox() 
    then
        local camConfig = camCfg
        local checks = camConfig['Camera Aimbot Checks']
        local zoomDist = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude
        local isFirstPerson = zoomDist < 1
        local isThirdPerson = zoomDist >= 1
        local rightClickHeld = UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        local fpAllowed = checks['First Person'] and isFirstPerson
        local tpAllowed = checks['Third Person'] and isThirdPerson
        local rcAllowed = not checks['Right Click'] or rightClickHeld
        local targetVisible = true
        if selectedCond["Visible"] then
            local head = cameraTarget.Character:FindFirstChild("Head")
            if head then
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, cameraTarget.Character}
                local result = Workspace:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, raycastParams)
                targetVisible = result == nil or result.Instance:IsDescendantOf(cameraTarget.Character)
            end
        end
        if (fpAllowed or tpAllowed) and rcAllowed and targetVisible 
            and (not selectedCond["Crew Check"] or not isSameCrew(cameraTarget))
        then
            local hitPartName = camConfig['Hit Part']
            local targetPart
            if hitPartName == "Closest Part" then
                targetPart = getClosestPart(cameraTarget.Character)
            else
                targetPart = cameraTarget.Character:FindFirstChild(hitPartName)
                if not targetPart then
                    targetPart = cameraTarget.Character:FindFirstChild("Head")
                end
            end
            if targetPart then
                local pred = camConfig.Prediction
                local vel = targetPart.Velocity
                local predictedPos = targetPart.Position + Vector3.new(
                    vel.X * pred.X,
                    vel.Y * pred.Y,
                    vel.Z * pred.Z
                )
                local function cubicInOut(t)
                    if t < 0.5 then
                        return 4 * t * t * t
                    else
                        return 1 - math.pow(-2 * t + 2, 3) / 2
                    end
                end
                local baseSnappiness = camConfig.Snappiness or 0.1
                local direction = (predictedPos - Camera.CFrame.Position).Unit
                local currentLook = Camera.CFrame.LookVector
                local dot = math.clamp(currentLook:Dot(direction), -1, 1)
                local progress = (dot + 1) / 2
                local eased = cubicInOut(1 - progress)
                local dynamicSnappiness = baseSnappiness * (0.4 + eased * 1.6)
                dynamicSnappiness = math.clamp(dynamicSnappiness, 0, 1)
                local newLook = currentLook:lerp(direction, dynamicSnappiness)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newLook)
            end
        end
    end

    updateDebugGUI()
    refreshESP()
end))

if general and general.Console then print(" [+] Loaded") end
if general and general.FpsUnlocker then setfpscap(999) end
