if _G.Loaded == true then 
    if shared.config['Console'] == true then
        print("✅> Updated config") 
    end
    shared._configUpdated = true
    return
end
_G.Loaded = true
if shared.config['Console'] == true then
    print("ℹ️> Loading") 
end
loadstring([[function LPH_NO_VIRTUALIZE(f) return f end;]])();
local camlockPaused = false
local cameraTarget = nil
local Players      = game:GetService("Players")
local UserInput    = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local RunService   = game:GetService("RunService")
local Camera       = Workspace.CurrentCamera
local LocalPlayer  = Players.LocalPlayer
local Mouse        = LocalPlayer:GetMouse()
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
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "bwq2"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")

local targetLabel = Instance.new("TextLabel")
targetLabel.Name = "zxcxwa2"
targetLabel.Size = UDim2.new(0, 200, 0, 20)
targetLabel.Position = UDim2.new(0, shared.config.Info.Position.X, 0, shared.config.Info.Position.Y)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "target: None"
targetLabel.TextColor3 = Color3.new(1, 1, 1)
targetLabel.TextStrokeTransparency = 0.8
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextSize = 14
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.RichText = true
targetLabel.Parent = screenGui

local function updateDebugGUI()
    if shared._configUpdated then
        shared._configUpdated = false
    end

    local info = shared.config.Info or {}
    local enabled = info.Enabled ~= false
    screenGui.Enabled = enabled
    if not enabled then return end

    local pos = info.Position or {X=200, Y=100}
    targetLabel.Position = UDim2.new(0, pos.X, 0, pos.Y)

    if lockedPlayer and lockedPlayer.Character then
        local name = lockedPlayer.DisplayName or lockedPlayer.Name
        targetLabel.Text = "target: " .. name
        targetLabel.TextColor3 = Color3.new(1, 1, 1)
    else
        targetLabel.Text = "target: None"
        targetLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7) -- Red color
    end
end

local ShotgunNames = { 
    ["Double-Barrel SG"] = true, 
    ["TacticalShotgun"] = true, 
    ["Shotgun"] = true, 
    ["DrumShotgun"] = true 
}

local PistolNames = { 
    ["Revolver"] = true, 
    ["Silencer"] = true, 
    ["Glock"] = true 
}

local function isSameCrew(player)
    if not player then 
        return false 
    end

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

local getMousePosition = function()
    return Mouse.X, Mouse.Y
end

local getCurrentWeaponFOV = LPH_NO_VIRTUALIZE(function()
    local silent = shared.config['Silent Aim']
    local fovMain = silent.FOV
    if not fovMain.Enabled then
        return Vector3.new(9999, 9999, 9999)
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
end)

local isVisible = LPH_NO_VIRTUALIZE(function(rootPart)
    local direction = rootPart.Position - Camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.IgnoreWater = true
    local result = workspace:Raycast(Camera.CFrame.Position, direction, params)
    return result == nil or result.Instance:IsDescendantOf(rootPart.Parent)
end)

local isTargetVisible = LPH_NO_VIRTUALIZE(function(targetCharacter)
    if not targetCharacter or not targetCharacter:FindFirstChild("Head") then
        return false
    end

    local head = targetCharacter.Head
    local origin = Camera.CFrame.Position
    local direction = (head.Position - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, raycastParams)
    
    return result == nil or result.Instance:IsDescendantOf(targetCharacter)
end)

local oldRandom
oldRandom = hookfunction(math.random, LPH_NO_VIRTUALIZE(function(...)
    local args = { ... }
    if checkcaller() then
        return oldRandom(...)
    end
    local multiplier = 1
    if shared.config['Weapon Modifications'] and shared.config['Weapon Modifications'].Enabled then
        local character = LocalPlayer.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                local weaponName = tool.Name:gsub("[%[%]]", "")
                local weaponMods = shared.config['Weapon Modifications']
                
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

local updateKnockChecks = LPH_NO_VIRTUALIZE(function()
    local targetChar = lockedPlayer and lockedPlayer.Character
    local selfChar = LocalPlayer.Character
    
    if selfChar and shared.config.Conditions['Whilst a player is selected']['Self Knocked'] then
        local selfBodyEffects = selfChar:FindFirstChild("BodyEffects")
        selfKnocked = selfBodyEffects and selfBodyEffects:FindFirstChild("K.O") and selfBodyEffects["K.O"].Value
    else
        selfKnocked = false
    end
    if targetChar and shared.config.Conditions['Whilst a player is selected']['Knock Check'] then
        local targetBodyEffects = targetChar:FindFirstChild("BodyEffects")
        targetKnocked = targetBodyEffects and targetBodyEffects:FindFirstChild("K.O") and targetBodyEffects["K.O"].Value
    else
        targetKnocked = false
    end
end)

local getCamlockFOV = LPH_NO_VIRTUALIZE(function()
    local cam = shared.config['Camera Aimbot']
    local fovMain = cam.FOV

    if not fovMain.Enabled then
        return Vector3.new(9999, 9999, 9999)
    end

    local wc = fovMain['Weapon Configuration']
    if not wc.Enabled then
        local base = fovMain.Size
        return Vector3.new(base.X or 0, base.Y or 0, base.Z or 0)
    end

    local character = LocalPlayer.Character
    if not character then return Vector3.new(4, 6, 2) end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return Vector3.new(wc.Others.X or 4, wc.Others.Y or 6, wc.Others.Z or 2) end

    local weaponName = tool.Name:gsub("[%[%]]", "")
    local config = wc.Others
    
    if ShotgunNames[weaponName] then config = wc.Shotguns
    elseif PistolNames[weaponName] then config = wc.Pistols end
    
    return Vector3.new(config.X or 4, config.Y or 6, config.Z or 2)
end)

local getTriggerbotFOV = LPH_NO_VIRTUALIZE(function()
    local tb = shared.config['Trigger Bot']
    local fov = tb.FOV
    return Vector3.new(fov.X or 0, fov.Y or 0, fov.Z or 0)
end)

local isMouseInCamBox = LPH_NO_VIRTUALIZE(function()
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
    local tNear = math.max(t1.X, math.max(t1.Y, t1.Z))
    local tFar  = math.min(t2.X, math.min(t2.Y, t2.Z))
    return tNear <= tFar and tFar >= 0
end)

local isMouseInTriggerBox = LPH_NO_VIRTUALIZE(function()
    if not lockedPlayer or not lockedPlayer.Character then return false end
    local root = lockedPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local fov = shared.config['Trigger Bot'].FOV
    local half = Vector3.new(fov.X or 0, fov.Y or 0, fov.Z or 0) / 2
    local min = root.Position - half
    local max = root.Position + half
    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)

    local tMin = (min - ray.Origin) / ray.Direction
    local tMax = (max - ray.Origin) / ray.Direction
    local t1 = Vector3.new(math.min(tMin.X, tMax.X), math.min(tMin.Y, tMax.Y), math.min(tMin.Z, tMax.Z))
    local t2 = Vector3.new(math.max(tMin.X, tMax.X), math.max(tMin.Y, tMax.Y), math.max(tMin.Z, tMax.Z))
    local tNear = math.max(t1.X, math.max(t1.Y, t1.Z))
    local tFar  = math.min(t2.X, math.min(t2.Y, t2.Z))

    return tNear <= tFar and tFar >= 0
end)

local getClosestPlayerToMouse = LPH_NO_VIRTUALIZE(function()
    local closest = nil
    local bestDist = math.huge
    
    local mx, my = getMousePosition()
    local mousePos = Vector2.new(mx, my)

    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local bodyEffects = player.Character:FindFirstChild("BodyEffects")
            local knocked = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value

            if root and not knocked then
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
    
    return closest
end)

local GetClosestPointAdvanced = LPH_NO_VIRTUALIZE(function(Part, Scale)
    local cf = Part.CFrame
    local size = Part.Size * (Scale / 2)

    local ray = Mouse.UnitRay
    local rel = cf:PointToObjectSpace(ray.Origin + ray.Direction * ray.Direction:Dot(cf.Position - ray.Origin))

    return cf * Vector3.new(
        math.clamp(rel.X, -size.X, size.X),
        math.clamp(rel.Y, -size.Y, size.Y),
        math.clamp(rel.Z, -size.Z, size.Z)
    )
end)

local GetClosestPointBasic = LPH_NO_VIRTUALIZE(function(Part)
    if not Part then return Part.Position end
    local ray = Mouse.UnitRay
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {Part}
    params.FilterType = Enum.RaycastFilterType.Whitelist
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    return result and result.Position or Part.Position
end)

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

local getClosestPart = LPH_NO_VIRTUALIZE(function(char)
    return GetClosestPartToCursor(char)
end)

local applyPrediction = LPH_NO_VIRTUALIZE(function(partOrNil, basePos)
    if not partOrNil then return basePos end
    
    local silent = shared.config['Silent Aim']
    local pred = silent.Prediction
    local vel = partOrNil.Velocity or Vector3.new(0,0,0)
    local offset = Vector3.new(
        vel.X * (pred.X or 0),
        vel.Y * (pred.Y or 0), 
        vel.Z * (pred.Z or 0)
    )
    return basePos + offset
end)

local resolveHit = LPH_NO_VIRTUALIZE(function(targetChar)
    local silent = shared.config['Silent Aim']
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
end)

local function canTargetPlayer(player)
    if not player or not player.Character then return false end
    
    local selectCond = shared.config.Conditions["Whilst selecting a player"]
    
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
    box.Parent  = targetPlayer.Character
    if not BOX_VISIBLE then box.Transparency = 1 end
end

local function createTriggerBox(targetPlayer)
    if triggerBox then triggerBox:Destroy() end
    local fov = shared.config['Trigger Bot'].FOV
    local boxSize = Vector3.new(fov.X or 0, fov.Y or 0, fov.Z or 0)
    
    triggerBox = Instance.new("BoxHandleAdornment")
    triggerBox.Size = boxSize
    triggerBox.Color3 = Color3.fromRGB(0, 150, 255)
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

local isMouseInBox = LPH_NO_VIRTUALIZE(function()
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

    local tNear = math.max(t1.X, math.max(t1.Y, t1.Z))
    local tFar  = math.min(t2.X, math.min(t2.Y, t2.Z))

    return tNear <= tFar and tFar >= 0
end)

local function getToggleKey()
    local toggleChar = shared.config.Toggle
    return Enum.KeyCode[toggleChar]
end

UserInput.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(inp, gp)
   if gp then return end

    if inp.KeyCode == getToggleKey() then
        if lockedPlayer then
            lockedPlayer = nil
            cameraTarget = nil
            if box then box:Destroy() box = nil end
            if camBox then camBox:Destroy() camBox = nil end
            if triggerBox then triggerBox:Destroy() triggerBox = nil end
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

    local bind = shared.config['Trigger Bot']['Activation']['Activation Bind']
    if inp.KeyCode == Enum.KeyCode[bind] then
        local mode = shared.config['Trigger Bot']['Activation']['Activation Mode']
        if mode == "Toggle" then
            triggerToggled = not triggerToggled
        elseif mode == "Hold" then
            triggerKeyDown = true
        end
    end
end))

UserInput.InputEnded:Connect(LPH_NO_VIRTUALIZE(function(inp, gp)
    if gp then return end
    local bind = shared.config['Trigger Bot']['Activation']['Activation Bind']
    if inp.KeyCode == Enum.KeyCode[bind] then
        triggerKeyDown = false
    end
end))

originalIndex = hookmetamethod(game, "__index", LPH_NO_VIRTUALIZE(function(self, key)
    if self == Mouse and (key == "Hit" or key == "Target") and lockedPlayer then
        if (not shared.config.Conditions["Whilst a player is selected"]["Visible"] or isTargetVisible(lockedPlayer.Character)) and isMouseInBox() then
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

        ChinaArgs[2] = _G.FetchPosition()
        return self.FireServer(self, unpack(ChinaArgs))
    end

    return ChinaHook(self, ...)
end))

RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
    local selectedCond = shared.config.Conditions["Whilst a player is selected"]

    if shared.config['Mode'] == 'Target' and lockedPlayer then
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

        if selectedCond["Visible"] and not isTargetVisible(targetChar) then
        end

        if shouldUnlock then
            lockedPlayer = nil
            cameraTarget = nil
            if box then box:Destroy() box = nil end
            if camBox then camBox:Destroy() camBox = nil end
            if triggerBox then triggerBox:Destroy() triggerBox = nil end
            return
        end
    end

    if shared.config['Mode'] == 'Auto' then
    local closestToMouse = getClosestPlayerToMouse()
    
    if closestToMouse and closestToMouse.Character and canTargetPlayer(closestToMouse) then
       
        lockedPlayer = closestToMouse
        cameraTarget = closestToMouse
        

        if not box then createSilentBox(closestToMouse) end
        if not camBox then createCamBox(closestToMouse) end
        if not triggerBox then createTriggerBox(closestToMouse) end
    else

        lockedPlayer = nil
        cameraTarget = nil
        if box then box:Destroy() box = nil end
        if camBox then camBox:Destroy() camBox = nil end
        if triggerBox then triggerBox:Destroy() triggerBox = nil end
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
        local fov = shared.config['Trigger Bot'].FOV
        triggerBox.Size = Vector3.new(fov.X or 0, fov.Y or 0, fov.Z or 0)
        triggerBox.Adornee = lockedPlayer.Character
    end

    if lockedPlayer and shared.config['Trigger Bot'].Enabled and (not shared.config.Conditions["Whilst a player is selected"]["Visible"] or isTargetVisible(lockedPlayer.Character)) then
        local tb = shared.config['Trigger Bot']
        local mode = tb['Activation']['Activation Mode']
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
    and shared.config['Camera Aimbot'].Enabled 
    and (not shared.config.Conditions["Whilst a player is selected"]["Visible"] or isTargetVisible(cameraTarget.Character))
    and (not shared.config.Conditions["Whilst a player is selected"]["Crew Check"] or not isSameCrew(cameraTarget))
    and isMouseInCamBox() 
then
    local camConfig = shared.config['Camera Aimbot']
    local checks = camConfig['Camera Aimbot Checks']
    local zoomDist = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude
    local isFirstPerson = zoomDist < 1
    local isThirdPerson = zoomDist >= 1
    local rightClickHeld = UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    local fpAllowed = checks['First Person'] and isFirstPerson
    local tpAllowed = checks['Third Person'] and isThirdPerson
    local rcAllowed = not checks['Right Click'] or rightClickHeld
    local selectedCond = shared.config.Conditions["Whilst a player is selected"]
    local targetVisible = true

    if selectedCond["Visible"] then
        local head = cameraTarget.Character:FindFirstChild("Head")
        if head then
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character, cameraTarget.Character}
            rayParams.IgnoreWater = true
            local result = Workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position), rayParams)
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
end))
if shared.config['Console'] == true then
    print("✅> Loaded") 
end
