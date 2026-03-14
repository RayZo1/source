-- Configuration Validator and Event Poller
if _G.SessionStarted == true then 
    if shared.config.General and shared.config.General.Console == true then
        print(" [+] Synchronized")
    end
    shared._configUpdated = true
    return
end
_G.SessionStarted = true
if shared.config.General and shared.config.General.Console == true then
    print(" [+] Initializing")
end

local function executeSafely(delegate) return delegate end;

if not checkcaller then checkcaller = function() return false end end

-- Core Providers
local PlayerService = game:GetService("Players")
local InputProvider = game:GetService("UserInputService")
local WorldSpace = game:GetService("Workspace")
local ExecutionLoop = game:GetService("RunService")
local ActiveCamera = WorldSpace.CurrentCamera
local LocalClient = PlayerService.LocalPlayer
local PrimaryController = LocalClient:GetMouse()

-- Cache Nodes
local DataStructs = shared.config
local MainConfig = DataStructs.General
local ModuleB = DataStructs['Silent Aim']
local ModuleC = DataStructs['Camera Aimbot']
local ModuleD = DataStructs['Trigger Bot']
local ModulePanic = MainConfig['Panic']
local ModuleRaid = DataStructs['Raid Awareness']
local ModuleMod = DataStructs['Player Modification']
local FilterA = DataStructs.Conditions["Whilst a player is selected"]
local FilterB = DataStructs.Conditions["Whilst selecting a player"]

-- Execution State
local GlobalInterface = nil
local TrackingInterface = nil
local ActivationTimestamp = 0
local SignalActive = false
local SignalToggled = false
local OriginalIndexHandler
local ZoneA = nil
local ZoneA_Visible = true
local ZoneCamera = nil
local ZoneTrigger = nil
local RaidTargets = {}
local RaidDrawings = {}
local IsPanicking = false

-- UI Registry
local UserLayer = Instance.new("ScreenGui")
UserLayer.Name = "UserLayer_Runtime"
UserLayer.ResetOnSpawn = false
UserLayer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UserLayer.Parent = game:GetService("CoreGui")

local OutputDisplay = Instance.new("TextLabel")
OutputDisplay.Name = "OutputDisplay_Runtime"
OutputDisplay.Size = UDim2.new(0, 200, 0, 20)
OutputDisplay.Position = UDim2.new(0, MainConfig.Info.Position.X, 0, MainConfig.Info.Position.Y)
OutputDisplay.BackgroundTransparency = 1
OutputDisplay.Text = ""
OutputDisplay.TextColor3 = Color3.new(1, 1, 1)
OutputDisplay.TextStrokeTransparency = 0.8
OutputDisplay.Font = Enum.Font.Gotham
OutputDisplay.TextSize = 14
OutputDisplay.TextXAlignment = Enum.TextXAlignment.Left
OutputDisplay.RichText = true
OutputDisplay.Parent = UserLayer

-- Cached Math/Physics Parameters
local GlobalRayParams = RaycastParams.new()
GlobalRayParams.FilterType = Enum.RaycastFilterType.Blacklist
GlobalRayParams.IgnoreWater = true

-- Pre-compiled Lookups
local TypeClassA = { ["Double-Barrel SG"] = true, ["TacticalShotgun"] = true, ["Shotgun"] = true, ["DrumShotgun"] = true }
local TypeClassB = { ["Revolver"] = true, ["Silencer"] = true, ["Glock"] = true }

local function ResetVisualNodes()
    if ZoneA then ZoneA:Destroy(); ZoneA = nil end
    if ZoneCamera then ZoneCamera:Destroy(); ZoneCamera = nil end
    if ZoneTrigger then ZoneTrigger:Destroy(); ZoneTrigger = nil end
end

local function ProcessUIUpdate()
    if shared._configUpdated then shared._configUpdated = false end
    local configParams = MainConfig.Info
    UserLayer.Enabled = configParams.Enabled
    if not configParams.Enabled then return end
    OutputDisplay.Position = UDim2.new(0, configParams.Position.X, 0, configParams.Position.Y)
    
    if GlobalInterface and GlobalInterface.Character then
        local displayString = GlobalInterface.DisplayName or GlobalInterface.Name
        OutputDisplay.Text = "target: " .. displayString
        OutputDisplay.TextColor3 = Color3.new(1, 1, 1)
    else
        OutputDisplay.Text = "target: Idle"
        OutputDisplay.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    end
end

local function AddRaidTarget(player)
    if player == LocalClient or RaidTargets[player.UserId] then return end
    RaidTargets[player.UserId] = player
    
    local drawings = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        healthBg = Drawing.new("Line"),
        healthFg = Drawing.new("Line")
    }
    
    drawings.box.Thickness = 1
    drawings.box.Filled = false
    drawings.box.Transparency = 1
    
    drawings.name.Size = 14
    drawings.name.Center = true
    drawings.name.Outline = true
    drawings.name.OutlineColor = Color3.new(0,0,0)
    
    drawings.healthBg.Thickness = 2
    drawings.healthBg.Color = Color3.new(0,0,0)
    
    drawings.healthFg.Thickness = 2
    
    RaidDrawings[player.UserId] = drawings
end

local function RemoveRaidTarget(player)
    RaidTargets[player.UserId] = nil
    if RaidDrawings[player.UserId] then
        for _, d in pairs(RaidDrawings[player.UserId]) do
            d:Remove()
        end
        RaidDrawings[player.UserId] = nil
    end
end

local function DispatchEntityRenders()
    if not ModuleRaid.Enabled or IsPanicking then
        for _, dObjs in pairs(RaidDrawings) do
            for _, d in pairs(dObjs) do d.Visible = false end
        end
        return
    end
    
    for uid, player in pairs(RaidTargets) do
        local d = RaidDrawings[uid]
        if not player or not player.Parent or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            if d then for _, x in pairs(d) do x.Visible = false end end
            continue
        end
        
        local char = player.Character
        local head = char:FindFirstChild("Head")
        local root = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if not head or not root or not hum or hum.Health <= 0 then
            if d then for _, x in pairs(d) do x.Visible = false end end
            continue
        end
        
        local dist = (ActiveCamera.CFrame.Position - root.Position).Magnitude
        if dist > (ModuleRaid['Max Render Distance'] or 250) then
            if d then for _, x in pairs(d) do x.Visible = false end end
            continue
        end
        
        local rootPos, onScreen = ActiveCamera:WorldToViewportPoint(root.Position)
        local headPos, _ = ActiveCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos, _ = ActiveCamera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        
        if onScreen and rootPos.Z > 0 then
            local height = math.abs(headPos.Y - legPos.Y)
            local width = height * 0.6
            
            if ModuleRaid.Box.Enabled then
                d.box.Size = Vector2.new(width, height)
                d.box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
                d.box.Color = ModuleRaid.Box.Color
                d.box.Visible = true
            else
                d.box.Visible = false
            end
            
            if ModuleRaid.Name.Enabled then
                d.name.Position = Vector2.new(rootPos.X, headPos.Y - 16)
                d.name.Text = (ModuleRaid.Name.Type == 'Display' and player.DisplayName) or player.Name
                d.name.Color = ModuleRaid.Name.Color
                d.name.Visible = true
            else
                d.name.Visible = false
            end
            
            if ModuleRaid.Health.Enabled then
                local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local barStartX = rootPos.X - width/2 - 6
                
                d.healthBg.From = Vector2.new(barStartX, headPos.Y + height)
                d.healthBg.To = Vector2.new(barStartX, headPos.Y)
                d.healthBg.Visible = true
                
                d.healthFg.From = Vector2.new(barStartX, headPos.Y + height)
                d.healthFg.To = Vector2.new(barStartX, headPos.Y + height - (height * healthPct))
                d.healthFg.Color = ModuleRaid.Health['Missing Health Color']:Lerp(ModuleRaid.Health['High Health Color'], healthPct)
                d.healthFg.Visible = true
            else
                d.healthBg.Visible = false
                d.healthFg.Visible = false
            end
        else
            if d then for _, x in pairs(d) do x.Visible = false end end
        end
    end
end

PlayerService.PlayerRemoving:Connect(RemoveRaidTarget)

-- Affinity Check
local function ValidateAffinity(entity)
    if not entity then return false end
    local localFolder = LocalClient:FindFirstChild("DataFolder")
    local remoteFolder = entity:FindFirstChild("DataFolder")
    
    if localFolder and remoteFolder then
        local localData = localFolder:FindFirstChild("Information")
        local remoteData = remoteFolder:FindFirstChild("Information")
        if localData and remoteData then
            local localVal = localData:FindFirstChild("Crew") and tonumber(localData.Crew.Value)
            local remoteVal = remoteData:FindFirstChild("Crew") and tonumber(remoteData.Crew.Value)
            if localVal and remoteVal and localVal > 0 and remoteVal > 0 then
                return localVal == remoteVal
            end
        end
    end
    return false
end

-- Efficient Tool Parsing
local cachedToolName = nil
local cachedToolClass = 0 -- 0: Other, 1: SG, 2: Pistol
local function updateCachedTool()
    local cModel = LocalClient.Character
    if cModel then
        local toolItem = cModel:FindFirstChildOfClass("Tool")
        if toolItem then
            cachedToolName = toolItem.Name:gsub("[%[%]]", "")
            if TypeClassA[cachedToolName] then
                cachedToolClass = 1
            elseif TypeClassB[cachedToolName] then
                cachedToolClass = 2
            else
                cachedToolClass = 0
            end
        else
            cachedToolName = nil
            cachedToolClass = 0
        end
    end
end

local function GetConfiguredDimensionA()
    if not ModuleB.FOV.Enabled then return Vector3.new(9999, 9999, 9999) end
    local params = ModuleB.FOV['Weapon Configuration']
    if not params or not params.Enabled then
        local bBox = ModuleB.FOV.Size
        return Vector3.new(bBox.X or 0, bBox.Y or 0, bBox.Z or 0)
    end
    
    updateCachedTool()
    local configSet = params.Others
    if cachedToolClass == 1 then configSet = params.Shotguns
    elseif cachedToolClass == 2 then configSet = params.Pistols end
    
    return Vector3.new(configSet.X or 4, configSet.Y or 6, configSet.Z or 2)
end

local function GetConfiguredDimensionB()
    if not ModuleC.FOV.Enabled then return Vector3.new(9999, 9999, 9999) end
    local params = ModuleC.FOV['Weapon Configuration']
    if not params.Enabled then
        local bBox = ModuleC.FOV.Size
        return Vector3.new(bBox.X or 0, bBox.Y or 0, bBox.Z or 0)
    end
    
    updateCachedTool()
    local configSet = params.Others
    if cachedToolClass == 1 then configSet = params.Shotguns
    elseif cachedToolClass == 2 then configSet = params.Pistols end
    
    return Vector3.new(configSet.X or 4, configSet.Y or 6, configSet.Z or 2)
end

local function CheckOcclusion(bNode)
    if not bNode then return false end
    local targetVec = bNode.Position - ActiveCamera.CFrame.Position
    GlobalRayParams.FilterDescendantsInstances = {LocalClient.Character}
    local castResult = WorldSpace:Raycast(ActiveCamera.CFrame.Position, targetVec, GlobalRayParams)
    return castResult == nil or castResult.Instance:IsDescendantOf(bNode.Parent)
end

local function CheckIntersection(dimensionFunc, targetEntity)
    if not targetEntity or not targetEntity.Character then return false end
    local bNode = targetEntity.Character:FindFirstChild("HumanoidRootPart")
    if not bNode then return false end
    
    local dSize = dimensionFunc()
    local dHalf = dSize * 0.5
    local boundsMin = bNode.Position - dHalf
    local boundsMax = bNode.Position + dHalf
    
    local pointerRay = ActiveCamera:ScreenPointToRay(PrimaryController.X, PrimaryController.Y)
    local pOri, pDir = pointerRay.Origin, pointerRay.Direction
    
    local tMin = (boundsMin - pOri) / pDir
    local tMax = (boundsMax - pOri) / pDir
    
    local t1X = math.min(tMin.X, tMax.X); local t1Y = math.min(tMin.Y, tMax.Y); local t1Z = math.min(tMin.Z, tMax.Z)
    local t2X = math.max(tMin.X, tMax.X); local t2Y = math.max(tMin.Y, tMax.Y); local t2Z = math.max(tMin.Z, tMax.Z)
    
    local nVal = math.max(t1X, t1Y, t1Z)
    local fVal = math.min(t2X, t2Y, t2Z)
    
    return nVal <= fVal and fVal >= 0
end

local function GetOptimalCandidate()
    local optimalBound = ModuleB.Distance
    local candidateNode = nil
    local pX, pY = PrimaryController.X, PrimaryController.Y
    local referenceModel = LocalClient.Character and LocalClient.Character:FindFirstChild("HumanoidRootPart")
    
    if not referenceModel then return nil end
    
    local activeElements = PlayerService:GetPlayers()
    for i = 1, #activeElements do
        local elem = activeElements[i]
        if elem ~= LocalClient and elem.Character then
            local proxyNode = elem.Character:FindFirstChild("HumanoidRootPart")
            if proxyNode then
                local displacement = (proxyNode.Position - referenceModel.Position).Magnitude
                if displacement <= optimalBound then
                    local sCoords = ActiveCamera:WorldToViewportPoint(proxyNode.Position)
                    if sCoords.Z > 0 and CheckOcclusion(proxyNode) then
                        local scalarDist = math.sqrt((sCoords.X - pX)^2 + (sCoords.Y - pY)^2)
                        if scalarDist < optimalBound then
                            optimalBound = scalarDist
                            candidateNode = elem
                        end
                    end
                end
            end
        end
    end
    return candidateNode
end

local function ValidateEntity(entity)
    if not entity or not entity.Character then return false end
    local conditions = FilterB
    
    if conditions["Self Knocked"] then
        local stEffects = LocalClient.Character and LocalClient.Character:FindFirstChild("BodyEffects")
        if stEffects and stEffects:FindFirstChild("K.O") and stEffects["K.O"].Value then return false end
    end
    
    if conditions["Crew Check"] and ValidateAffinity(entity) then return false end
    
    if conditions["Knock Check"] then
        local tEffects = entity.Character:FindFirstChild("BodyEffects")
        if tEffects and tEffects:FindFirstChild("K.O") and tEffects["K.O"].Value then return false end
    end
    
    if conditions["Visible"] then
        local vNode = entity.Character:FindFirstChild("Head")
        if not vNode or not CheckOcclusion(vNode) then return false end
    end
    
    return true
end

local function BindZones(targetEntity)
    ResetVisualNodes()
    local fovC = GetConfiguredDimensionA()
    ZoneA = Instance.new("BoxHandleAdornment")
    ZoneA.Size = fovC
    ZoneA.Color3 = Color3.fromRGB(255, 0, 0)
    ZoneA.Transparency = ZoneA_Visible and 1 or 1
    ZoneA.AlwaysOnTop = true
    ZoneA.ZIndex = 10
    ZoneA.Adornee = targetEntity.Character
    ZoneA.Parent = targetEntity.Character

    local fovT = ModuleD.FOV
    ZoneTrigger = Instance.new("BoxHandleAdornment")
    ZoneTrigger.Size = Vector3.new(fovT.X or 0, fovT.Y or 0, fovT.Z or 0)
    ZoneTrigger.Color3 = Color3.fromRGB(0, 150, 255)
    ZoneTrigger.Transparency = 1
    ZoneTrigger.AlwaysOnTop = true
    ZoneTrigger.ZIndex = 12
    ZoneTrigger.Adornee = targetEntity.Character
    ZoneTrigger.Parent = targetEntity.Character

    local fovCam = GetConfiguredDimensionB()
    ZoneCamera = Instance.new("BoxHandleAdornment")
    ZoneCamera.Size = fovCam
    ZoneCamera.Color3 = Color3.fromRGB(0, 255, 0)
    ZoneCamera.Transparency = 1
    ZoneCamera.AlwaysOnTop = true
    ZoneCamera.ZIndex = 11
    ZoneCamera.Adornee = targetEntity.Character
    ZoneCamera.Parent = targetEntity.Character
end

local function InterpretCoordinates(partNode, baseVal)
    if not partNode then return baseVal end
    local velocityDelta = partNode.Velocity or Vector3.new(0, 0, 0)
    local predictionScalars = ModuleB.Prediction
    return baseVal + Vector3.new(velocityDelta.X * (predictionScalars.X or 0), velocityDelta.Y * (predictionScalars.Y or 0), velocityDelta.Z * (predictionScalars.Z or 0))
end

local function CalculateProxyIntersection(entityChar)
    local method = ModuleB['Hit Part']
    local cPart = nil
    local pVal = nil
    
    if method == "Closest Point" or method == "Closest Part" then
        local mPos = InputProvider:GetMouseLocation()
        local minD = math.huge
        local parts = entityChar:GetChildren()
        
        for i = 1, #parts do
            local p = parts[i]
            if p:IsA("BasePart") then
                local sP, vP = ActiveCamera:WorldToViewportPoint(p.Position)
                if vP then
                    local d = math.sqrt((sP.X - mPos.X)^2 + (sP.Y - mPos.Y)^2)
                    if d < minD then
                        minD = d
                        cPart = p
                    end
                end
            end
        end
        cPart = cPart or entityChar:FindFirstChild("HumanoidRootPart") or entityChar:FindFirstChild("Head")
        
        if cPart and method == "Closest Point" then
            local pType = ModuleB['Closest Point']
            if pType.Type == "Advanced" then
                local scale = pType.Scale or 0.6
                local cf = cPart.CFrame
                local sX, sY, sZ = (cPart.Size.X * scale * 0.5), (cPart.Size.Y * scale * 0.5), (cPart.Size.Z * scale * 0.5)
                local mRay = PrimaryController.UnitRay
                local rel = cf:PointToObjectSpace(mRay.Origin + mRay.Direction * mRay.Direction:Dot(cf.Position - mRay.Origin))
                pVal = cf * Vector3.new(math.clamp(rel.X, -sX, sX), math.clamp(rel.Y, -sY, sY), math.clamp(rel.Z, -sZ, sZ))
            else
                local mRay = PrimaryController.UnitRay
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {cPart}
                params.FilterType = Enum.RaycastFilterType.Whitelist
                local rData = WorldSpace:Raycast(mRay.Origin, mRay.Direction * 1000, params)
                pVal = rData and rData.Position or cPart.Position
            end
        elseif cPart then
            pVal = cPart.Position
        end
    else
        cPart = entityChar:FindFirstChild(method) or entityChar:FindFirstChild("Head")
        if cPart then pVal = cPart.Position end
    end
    
    if pVal and cPart then
        pVal = InterpretCoordinates(cPart, pVal)
    end
    return pVal, cPart
end

InputProvider.InputBegan:Connect(executeSafely(function(evt, flag)
    if flag then return end
    if ModulePanic.Enabled and evt.KeyCode == Enum.KeyCode[ModulePanic.Keybind] then
        IsPanicking = not IsPanicking
        if IsPanicking then
            GlobalInterface = nil
            TrackingInterface = nil
            ResetVisualNodes()
            for _, dObjs in pairs(RaidDrawings) do
                for _, d in pairs(dObjs) do d.Visible = false end
            end
            if MainConfig.Console then print(" [+] Panic Enabled") end
        else
            if MainConfig.Console then print(" [-] Panic Disabled") end
        end
    end

    if IsPanicking then return end
    
    if evt.KeyCode == Enum.KeyCode[MainConfig.Toggle] then
        if GlobalInterface then
            GlobalInterface = nil
            TrackingInterface = nil
            ResetVisualNodes()
        else
            local targetEntity = GetOptimalCandidate()
            if targetEntity and ValidateEntity(targetEntity) then
                GlobalInterface = targetEntity
                TrackingInterface = targetEntity
                BindZones(targetEntity)
            end
        end
    end
    
    if ModuleRaid.Enabled then
        if evt.KeyCode == Enum.KeyCode[ModuleRaid.Binds['Add Target']] then
            local targetEntity = GetOptimalCandidate()
            if targetEntity then AddRaidTarget(targetEntity) end
        elseif evt.KeyCode == Enum.KeyCode[ModuleRaid.Binds['Remove Target']] then
            local targetEntity = GetOptimalCandidate()
            if targetEntity then RemoveRaidTarget(targetEntity) end
        end
    end
    
    if ModuleMod.InventorySorter.Enabled and evt.KeyCode == Enum.KeyCode[ModuleMod.InventorySorter.Keybind] then
        local bp = LocalClient:FindFirstChild("Backpack")
        local char = LocalClient.Character
        if bp and char then
            local order = ModuleMod.InventorySorter.Order
            local items = bp:GetChildren()
            local equipped = char:FindFirstChildOfClass("Tool")
            if equipped then table.insert(items, equipped) end
            
            table.sort(items, function(a, b)
                local idxA = 999
                local idxB = 999
                for i = 1, #order do
                    if a.Name:find(order[i]:gsub("[%[%]]", "")) then idxA = i end
                    if b.Name:find(order[i]:gsub("[%[%]]", "")) then idxB = i end
                end
                return idxA < idxB
            end)
            
            for _, item in ipairs(items) do
                item.Parent = char
                item.Parent = bp
            end
        end
    end
    
    if evt.KeyCode == Enum.KeyCode[ModuleD.Activation['Activation Bind']] then
        local modeSelect = ModuleD.Activation['Activation Mode']
        if modeSelect == "Toggle" then SignalToggled = not SignalToggled
        elseif modeSelect == "Hold" then SignalActive = true end
    end
end))

InputProvider.InputEnded:Connect(executeSafely(function(evt, flag)
    if flag then return end
    if evt.KeyCode == Enum.KeyCode[ModuleD.Activation['Activation Bind']] then
        SignalActive = false
    end
end))

OriginalIndexHandler = hookmetamethod(game, "__index", executeSafely(function(self, requestKey)
    if self == PrimaryController and (requestKey == "Hit" or requestKey == "Target") and GlobalInterface then
        local vNode = GlobalInterface.Character and GlobalInterface.Character:FindFirstChild("Head")
        local isVis = FilterA.Visible and CheckOcclusion(vNode) or not FilterA.Visible
        
        if isVis and CheckIntersection(GetConfiguredDimensionA, GlobalInterface) then
            local rCoords, rPart = CalculateProxyIntersection(GlobalInterface.Character)
            if rCoords and rPart then
                if requestKey == "Hit" then return CFrame.new(rCoords)
                else return rPart end
            end
        end
    end
    return OriginalIndexHandler(self, requestKey)
end))

-- Engine Overrides
local TargetDataStructure = game:HttpGet("https://raw.githubusercontent.com/Nosssa/NossLock/main/GetRealMousePosition")
if TargetDataStructure then loadstring(TargetDataStructure)() end
task.wait()

local NetworkInterceptor
NetworkInterceptor = hookmetamethod(game, "__namecall", executeSafely(function(self, ...)
    local payload = {...}
    local methodType = getnamecallmethod()
    local acceptedPayloads = {[9196894486] = "UpdateMousePos"}
    local rType = acceptedPayloads[game.PlaceId] or "UpdateMousePos"
    
    if not checkcaller() and methodType == "FireServer" and self.Name == "MainEvent" and payload[1] == rType then
        return self.FireServer(self, unpack(payload))
    end
    return NetworkInterceptor(self, ...)
end))

local MathEngineGenerator
MathEngineGenerator = hookfunction(math.random, executeSafely(function(...)
    local argData = {...}
    if checkcaller() then return MathEngineGenerator(...) end
    
    local mult = 1
    if MainConfig['Weapon Modifications'] and MainConfig['Weapon Modifications'].Enabled then
        updateCachedTool()
        if cachedToolName then
            local modData = MainConfig['Weapon Modifications']["["..cachedToolName.."]"]
            if modData then mult = modData.Multiplier or 1 end
        end
    end
    
    local aCount = #argData
    if aCount == 0 or (aCount == 2 and argData[1] == -0.05 and argData[2] == 0.05) or (argData[1] == -0.1) or (argData[1] == -0.05) then
        if mult ~= 1 then return MathEngineGenerator(...) * mult end
    end
    return MathEngineGenerator(...)
end))

-- Core Runtime Thread
ExecutionLoop.RenderStepped:Connect(executeSafely(function()
    ActiveCamera = WorldSpace.CurrentCamera -- Cache refresh
    
    if not IsPanicking and ModuleMod.Movement.Enabled and LocalClient.Character then
        local hum = LocalClient.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if ModuleMod.Movement['Speed Modifications'].Enabled then
                if InputProvider:IsKeyDown(Enum.KeyCode[ModuleMod.Movement['Speed Modifications'].Keybind]) then
                    hum.WalkSpeed = 16 + ModuleMod.Movement['Speed Modifications'].Value
                else
                    hum.WalkSpeed = 16
                end
            end
            if ModuleMod.Movement['Jump Modifications'].Enabled then
                if InputProvider:IsKeyDown(Enum.KeyCode[ModuleMod.Movement['Jump Modifications'].Keybind]) then
                    hum.JumpPower = 50 + ModuleMod.Movement['Jump Modifications'].Value
                else
                    hum.JumpPower = 50
                end
            end
        end
    end
    
    if IsPanicking then 
        ProcessUIUpdate()
        DispatchEntityRenders()
        return 
    end
    
    if MainConfig.Mode == 'Target' and GlobalInterface then
        local sObj = LocalClient.Character
        local tObj = GlobalInterface.Character
        local purgeState = false
        
        if FilterA["Self Knocked"] then
            local st = sObj and sObj:FindFirstChild("BodyEffects")
            if st and st:FindFirstChild("K.O") and st["K.O"].Value then purgeState = true end
        end
        if FilterA["Knock Check"] then
            local tc = tObj and tObj:FindFirstChild("BodyEffects")
            if tc and tc:FindFirstChild("K.O") and tc["K.O"].Value then purgeState = true end
        end
        
        if purgeState then
            GlobalInterface = nil
            TrackingInterface = nil
            ResetVisualNodes()
            return
        end
    elseif MainConfig.Mode == 'Auto' then
        local cEntity = GetOptimalCandidate()
        if cEntity and ValidateEntity(cEntity) then
            if GlobalInterface ~= cEntity then
                GlobalInterface = cEntity
                TrackingInterface = cEntity
                BindZones(cEntity)
            end
        else
            if GlobalInterface then
                GlobalInterface = nil
                TrackingInterface = nil
                ResetVisualNodes()
            end
        end
    end

    if ZoneA and GlobalInterface and GlobalInterface.Character then
        ZoneA.Size = GetConfiguredDimensionA()
        ZoneA.Adornee = GlobalInterface.Character
    end
    if ZoneCamera and TrackingInterface and TrackingInterface.Character then
        ZoneCamera.Size = GetConfiguredDimensionB()
        ZoneCamera.Adornee = TrackingInterface.Character
    end
    if ZoneTrigger and GlobalInterface and GlobalInterface.Character then
        local vD = ModuleD.FOV
        ZoneTrigger.Size = Vector3.new(vD.X or 0, vD.Y or 0, vD.Z or 0)
        ZoneTrigger.Adornee = GlobalInterface.Character
    end

    if GlobalInterface and ModuleD.Enabled then
        local vNode = GlobalInterface.Character and GlobalInterface.Character:FindFirstChild("Head")
        if not FilterA.Visible or CheckOcclusion(vNode) then
            local mSelector = ModuleD.Activation['Activation Mode']
            local rDelay = ModuleD['Click Cooldown']
            local lChar = LocalClient.Character
            
            if lChar and not (lChar:FindFirstChild("[Knife]") or lChar:FindFirstChild("Knife")) then
                local isInBounds = CheckIntersection(function()
                    local tF = ModuleD.FOV
                    return Vector3.new(tF.X or 0, tF.Y or 0, tF.Z or 0)
                end, GlobalInterface)
                
                local isActive = (mSelector == "Always") or (mSelector == "Hold" and SignalActive) or (mSelector == "Toggle" and SignalToggled)
                
                if isInBounds and isActive then
                    local tCurrent = tick()
                    if tCurrent - ActivationTimestamp >= rDelay then
                        local lTool = lChar:FindFirstChildOfClass("Tool")
                        if lTool then
                            lTool:Activate()
                            ActivationTimestamp = tCurrent
                        end
                    end
                end
            end
        end
    end

    if TrackingInterface and TrackingInterface.Character and ModuleC.Enabled and CheckIntersection(GetConfiguredDimensionB, TrackingInterface) then
        local cTarget = TrackingInterface
        local vNode = cTarget.Character:FindFirstChild("Head")
        local isTargetVisibleLocally = not FilterA.Visible or CheckOcclusion(vNode)
        
        if isTargetVisibleLocally and (not FilterA["Crew Check"] or not ValidateAffinity(cTarget)) then
            local fData = ModuleC['Camera Aimbot Checks']
            local camMagnitude = (ActiveCamera.CFrame.Position - ActiveCamera.Focus.Position).Magnitude
            
            local fCond = fData['First Person'] and (camMagnitude < 1)
            local tCond = fData['Third Person'] and (camMagnitude >= 1)
            local rmCond = not fData['Right Click'] or InputProvider:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            
            if (fCond or tCond) and rmCond then
                local ptStr = ModuleC['Hit Part']
                local hPart = ptStr == "Closest Part" and (function()
                    local mp = InputProvider:GetMouseLocation()
                    local mD, cP = math.huge, nil
                    for _, p in ipairs(cTarget.Character:GetChildren()) do
                        if p:IsA("BasePart") then
                            local sp, vp = ActiveCamera:WorldToViewportPoint(p.Position)
                            if vp then
                                local md = math.sqrt((sp.X - mp.X)^2 + (sp.Y - mp.Y)^2)
                                if md < mD then mD = md; cP = p end
                            end
                        end
                    end
                    return cP or cTarget.Character:FindFirstChild("HumanoidRootPart")
                end)() or cTarget.Character:FindFirstChild(ptStr) or vNode
                
                if hPart then
                    local trP = hPart.Position + Vector3.new(
                        (hPart.Velocity.X * ModuleC.Prediction.X),
                        (hPart.Velocity.Y * ModuleC.Prediction.Y),
                        (hPart.Velocity.Z * ModuleC.Prediction.Z)
                    )
                    
                    local pDir = (trP - ActiveCamera.CFrame.Position).Unit
                    local cv = ActiveCamera.CFrame.LookVector
                    local interpVal = math.clamp(cv:Dot(pDir), -1, 1)
                    local prg = (interpVal + 1) * 0.5
                    local ease = prg < 0.5 and (4 * prg * prg * prg) or (1 - math.pow(-2 * prg + 2, 3) * 0.5)
                    
                    local factor = math.clamp((ModuleC.Snappiness or 0.1) * (0.4 + ease * 1.6), 0, 1)
                    ActiveCamera.CFrame = CFrame.new(ActiveCamera.CFrame.Position, ActiveCamera.CFrame.Position + cv:Lerp(pDir, factor))
                end
            end
        end
    end

    ProcessUIUpdate()
    DispatchEntityRenders()
end))

if MainConfig and MainConfig.Console then print(" [+] Active") end
if MainConfig and MainConfig.FpsUnlocker and setfpscap then setfpscap(999) end
