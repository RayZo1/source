-- v1.x
if _G.SessionStarted then
    if shared.config.General.Console then
        print(" [+] klient.fun -> Synced")
    end
    shared._configUpdated = true
    return
end
_G.SessionStarted = true

if shared.config.General.Console then
    print(" [+] klient.fun -> Initializing")
end

-- Services & globals
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local State = {
    Target = nil,
    TrackingTarget = nil,
    WeaponCategory = "Others",      -- "Shotguns", "Pistols", "Others"
    WeaponName = nil,
    SilentFOV = Vector3.new(9999,9999,9999),
    CameraFOV = Vector3.new(9999,9999,9999),
    TriggerFOV = Vector3.new(0,0,0),
    TriggerActive = false,
    TriggerToggled = false,
    LastTriggerTime = 0,
    ESPEnabled = false,
    UIEnabled = true,
    UIPos = { X = 500, Y = 600 },
    ValidPlayers = {},
    ESPLabels = {},
}

local Settings = shared.config
local General, Silent, CameraAim, Trigger, ESPcfg, Conditions, FilterSelected, FilterSelecting

local function refreshSettings()
    Settings = shared.config
    General = Settings.General
    Silent = Settings['Silent Aim']
    CameraAim = Settings['Camera Aimbot']
    Trigger = Settings['Trigger Bot']
    ESPcfg = Settings['ESP']
    Conditions = Settings.Conditions
    FilterSelected = Conditions["Whilst a player is selected"]
    FilterSelecting = Conditions["Whilst selecting a player"]

    State.ESPEnabled = ESPcfg.Enabled
    State.UIEnabled = General.Info.Enabled
    State.UIPos = General.Info.Position

    updateWeaponCategory()
end
refreshSettings()

local ShotgunTypes = {
    ['[Double-Barrel SG]'] = true,
    ['[TacticalShotgun]'] = true,
    ['[Shotgun]'] = true,
    ['[DrumShotgun]'] = true
}
local PistolTypes = {
    ['[Revolver]'] = true,
    ['[Silencer]'] = true,
    ['[Glock]'] = true
}

local function isKnocked(plr)
    local char = plr.Character
    if not char then return false end
    local effects = char:FindFirstChild("BodyEffects")
    return effects and effects:FindFirstChild("K.O") and effects["K.O"].Value
end

local function refreshValidPlayers()
    local new = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(new, plr)
            end
        end
    end
    State.ValidPlayers = new
end

local function getFOVSize(module)
    if not module.FOV.Enabled then return Vector3.new(9999,9999,9999) end
    local wcfg = module.FOV['Weapon Configuration']
    if wcfg and wcfg.Enabled then
        local sz = wcfg[State.WeaponCategory]
        if sz then return Vector3.new(sz.X, sz.Y, sz.Z) end
    end
    local sz = module.FOV.Size
    return Vector3.new(sz.X, sz.Y, sz.Z)
end

local function updateWeaponCategory()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        if ShotgunTypes[tool.Name] then
            State.WeaponCategory = "Shotguns"
        elseif PistolTypes[tool.Name] then
            State.WeaponCategory = "Pistols"
        else
            State.WeaponCategory = "Others"
        end
        State.WeaponName = tool.Name
    else
        State.WeaponCategory = "Others"
        State.WeaponName = nil
    end

    State.SilentFOV = getFOVSize(Silent)
    State.CameraFOV = getFOVSize(CameraAim)
    State.TriggerFOV = Vector3.new(Trigger.FOV.X, Trigger.FOV.Y, Trigger.FOV.Z)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UserLayer_Runtime"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local OutputLabel = Instance.new("TextLabel")
OutputLabel.Name = "OutputDisplay_Runtime"
OutputLabel.Size = UDim2.new(0, 200, 0, 20)
OutputLabel.BackgroundTransparency = 1
OutputLabel.Text = ""
OutputLabel.TextColor3 = Color3.new(1,1,1)
OutputLabel.TextStrokeTransparency = 0.8
OutputLabel.Font = Enum.Font.Gotham
OutputLabel.TextSize = 14
OutputLabel.TextXAlignment = Enum.TextXAlignment.Left
OutputLabel.RichText = true
OutputLabel.Parent = ScreenGui

local function registerESP(plr)
    if State.ESPLabels[plr.UserId] then return end
    local label = Drawing.new("Text")
    label.Size = 14
    label.Center = true
    label.Outline = true
    label.OutlineColor = Color3.fromRGB(0,0,0)
    label.Color = ESPcfg.Color
    label.Font = Drawing.Fonts.Plex
    label.Visible = false
    label.ZIndex = 1000
    State.ESPLabels[plr.UserId] = { node = plr, label = label }
end

local function unregisterESP(plr)
    local entry = State.ESPLabels[plr.UserId]
    if entry then
        entry.label:Remove()
        State.ESPLabels[plr.UserId] = nil
    end
end

local function updateESP()
    if not State.ESPEnabled then
        for _, entry in pairs(State.ESPLabels) do
            entry.label.Visible = false
        end
        return
    end
    for _, entry in pairs(State.ESPLabels) do
        local plr = entry.node
        local char = plr.Character
        if not char or not char.Parent then
            entry.label.Visible = false
            continue
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not head or not hum or hum.Health <= 0 then
            entry.label.Visible = false
            continue
        end
        local pos = head.Position + Vector3.new(0, 1.5, 0)
        local screen, onScreen = Camera:WorldToViewportPoint(pos)
        if onScreen and screen.Z > 0 then
            entry.label.Position = Vector2.new(screen.X, screen.Y)
            entry.label.Text = ESPcfg['Use Display Name'] and plr.DisplayName or plr.Name
            entry.label.Color = (plr == State.Target) and ESPcfg['Target Color'] or ESPcfg.Color
            entry.label.Visible = true
        else
            entry.label.Visible = false
        end
    end
end

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Blacklist
RayParams.IgnoreWater = true

local function hasLineOfSight(part)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    RayParams.FilterDescendantsInstances = { LocalPlayer.Character }
    local result = Workspace:Raycast(origin, dir, RayParams)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function isMouseInBox(char, boxSize)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local half = boxSize * 0.5
    local min = root.Position - half
    local max = root.Position + half
    local ray = Mouse.UnitRay
    local o, d = ray.Origin, ray.Direction
    local tmin = (min - o) / d
    local tmax = (max - o) / d
    local t1x, t1y, t1z = math.min(tmin.X, tmax.X), math.min(tmin.Y, tmax.Y), math.min(tmin.Z, tmax.Z)
    local t2x, t2y, t2z = math.max(tmin.X, tmax.X), math.max(tmin.Y, tmax.Y), math.max(tmin.Z, tmax.Z)
    local tnear = math.max(t1x, t1y, t1z)
    local tfar = math.min(t2x, t2y, t2z)
    return tnear <= tfar and tfar >= 0
end

local function getBestTarget(conditions)
    local best, bestDist = nil, math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    for _, plr in ipairs(State.ValidPlayers) do
        if not conditions["Knock Check"] or not isKnocked(plr) then
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local screen, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = (Vector2.new(screen.X, screen.Y) - mousePos).Magnitude
                    if dist < bestDist and (not conditions.Visible or hasLineOfSight(root)) then
                        best = plr
                        bestDist = dist
                    end
                end
            end
        end
    end
    return best
end

local function getClosestPointOnCharacter(char)
    local closestPoint = nil
    local closestDist = math.huge

    local function processPart(part)
        if not part:IsA("BasePart") then return end
        local cf = part.CFrame
        local size = part.Size
        local scale = Silent['Closest Point'].Scale or 0.67
        local half = size * scale * 0.5

        local corners = {
            cf * Vector3.new(-half.X, -half.Y, -half.Z),
            cf * Vector3.new( half.X, -half.Y, -half.Z),
            cf * Vector3.new(-half.X,  half.Y, -half.Z),
            cf * Vector3.new( half.X,  half.Y, -half.Z),
            cf * Vector3.new(-half.X, -half.Y,  half.Z),
            cf * Vector3.new( half.X, -half.Y,  half.Z),
            cf * Vector3.new(-half.X,  half.Y,  half.Z),
            cf * Vector3.new( half.X,  half.Y,  half.Z),
        }

        for _, corner in ipairs(corners) do
            local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPoint = corner
                end
            end
        end
    end

    for _, obj in ipairs(char:GetDescendants()) do
        processPart(obj)
    end

    return closestPoint
end

local __index
__index = hookmetamethod(game, "__index", function(self, key)
    if not Silent then return __index(self, key) end
    if self == Mouse and (key == "Hit" or key == "Target") and State.Target then
        local char = State.Target.Character
        if char then
            local vis = not FilterSelected.Visible or hasLineOfSight(char:FindFirstChild("Head"))
            if vis and isMouseInBox(char, State.SilentFOV) then
                local hitPart = Silent['Hit Part']
                local targetPos

                if hitPart == "Closest Point" then
                    targetPos = getClosestPointOnCharacter(char)
                    if not targetPos then
                        local head = char:FindFirstChild("Head")
                        if head then
                            targetPos = head.Position
                        end
                    end
                else
                    local part = char:FindFirstChild(hitPart) or char:FindFirstChild("Head")
                    if part then
                        targetPos = part.Position
                    end
                end

                if targetPos then
                    local vel = (char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Velocity) or Vector3.new()
                    local pred = Silent.Prediction
                    targetPos = targetPos + Vector3.new(vel.X * pred.X, vel.Y * pred.Y, vel.Z * pred.Z)

                    if key == "Hit" then
                        return CFrame.new(targetPos)
                    else
                        return char:FindFirstChild("Head")
                    end
                end
            end
        end
    end
    return __index(self, key)
end)

RunService.RenderStepped:Connect(function()
    if not General then return end
    Camera = Workspace.CurrentCamera

    if General.Mode == 'Auto' then
        local newTarget = getBestTarget(FilterSelected)
        if newTarget and newTarget ~= State.Target then
            State.Target = newTarget
            State.TrackingTarget = newTarget
        elseif not newTarget and State.Target then
            State.Target = nil
            State.TrackingTarget = nil
        end
    end

    if CameraAim.Enabled and State.TrackingTarget and State.TrackingTarget.Character then
        local char = State.TrackingTarget.Character
        local head = char:FindFirstChild("Head")
        if head and hasLineOfSight(head) and isMouseInBox(char, State.CameraFOV) then
            local mode = CameraAim['Camera Aimbot Checks']
            local camDist = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude
            local firstPerson = mode['First Person'] and camDist < 1
            local thirdPerson = mode['Third Person'] and camDist >= 1
            local shiftLock = mode['Shift Locked'] and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
            local rightClick = not mode['Right Click'] or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

            if (firstPerson or thirdPerson or shiftLock) and rightClick then
                local hitPart = char:FindFirstChild(CameraAim['Hit Part']) or head
                local vel = hitPart.Velocity or Vector3.new()
                local pred = CameraAim.Prediction
                local targetPos = hitPart.Position + Vector3.new(vel.X * pred.X, vel.Y * pred.Y, vel.Z * pred.Z)
                local direction = (targetPos - Camera.CFrame.Position).Unit
                local currentLook = Camera.CFrame.LookVector
                local factor = math.clamp(CameraAim.Snappiness or 0.1, 0, 1)
                local newLook = currentLook:Lerp(direction, factor)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newLook)
            end
        end
    end

    if Trigger.Enabled and State.Target and State.Target.Character then
        local mode = Trigger.Activation['Activation Mode']
        local active = mode == "Always"
            or (mode == "Hold" and State.TriggerActive)
            or (mode == "Toggle" and State.TriggerToggled)

        if active and isMouseInBox(State.Target.Character, State.TriggerFOV) then
            local now = tick()
            if now - State.LastTriggerTime >= Trigger['Click Cooldown'] then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                    State.LastTriggerTime = now
                end
            end
        end
    end

    if State.UIEnabled then
        OutputLabel.Position = UDim2.new(0, State.UIPos.X, 0, State.UIPos.Y)
        if State.Target then
            OutputLabel.Text = "target: " .. (State.Target.DisplayName or State.Target.Name)
            OutputLabel.TextColor3 = Color3.new(1,1,1)
        else
            OutputLabel.Text = "target: Idle"
            OutputLabel.TextColor3 = Color3.new(0.7,0.7,0.7)
        end
    end

    updateESP()
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not General or not ESPcfg or not Trigger then return end
    if input.KeyCode == Enum.KeyCode[General.Toggle] then
        if State.Target then
            State.Target = nil
            State.TrackingTarget = nil
        else
            local newTarget = getBestTarget(FilterSelecting)
            if newTarget then
                State.Target = newTarget
                State.TrackingTarget = newTarget
            end
        end
    end

    if input.KeyCode == Enum.KeyCode[ESPcfg.Activation['Activation Bind']] then
        if ESPcfg.Activation['Activation Mode'] == "Toggle" then
            State.ESPEnabled = not State.ESPEnabled
        else
            State.ESPEnabled = true
        end
    end

    if input.KeyCode == Enum.KeyCode[Trigger.Activation['Activation Bind']] then
        local mode = Trigger.Activation['Activation Mode']
        if mode == "Toggle" then
            State.TriggerToggled = not State.TriggerToggled
        elseif mode == "Hold" then
            State.TriggerActive = true
        end
    end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not General or not ESPcfg or not Trigger then return end
    if input.KeyCode == Enum.KeyCode[ESPcfg.Activation['Activation Bind']] and ESPcfg.Activation['Activation Mode'] == "Hold" then
        State.ESPEnabled = false
    end
    if input.KeyCode == Enum.KeyCode[Trigger.Activation['Activation Bind']] and Trigger.Activation['Activation Mode'] == "Hold" then
        State.TriggerActive = false
    end
end)

local function setupPlayer(plr)
    if plr == LocalPlayer then return end
    registerESP(plr)

    plr.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart")
        refreshValidPlayers()
        registerESP(plr)
    end)

    plr.CharacterRemoving:Connect(function()
        refreshValidPlayers()
        unregisterESP(plr)
        if State.Target == plr then
            State.Target = nil
            State.TrackingTarget = nil
        end
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    setupPlayer(plr)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(plr)
    refreshValidPlayers()
    unregisterESP(plr)
    if State.Target == plr then
        State.Target = nil
        State.TrackingTarget = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    updateWeaponCategory()
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait()
            updateWeaponCategory()
        end
    end)
end)

if LocalPlayer.Character then
    updateWeaponCategory()
end

refreshValidPlayers()
Players.PlayerAdded:Connect(refreshValidPlayers)
Players.PlayerRemoving:Connect(refreshValidPlayers)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr.Character then
        plr.Character.Humanoid.Died:Connect(refreshValidPlayers)
    end
end

task.spawn(function()
    while task.wait(3) do
        if shared._configUpdated then
            refreshSettings()
            shared._configUpdated = false
            if General and General.Console then
                print(" [+] klient.fun -> Synced config")
            end
        end
    end
end)

if General['Weapon Modifications'] and General['Weapon Modifications'].Enabled then
    local oldRandom = math.random
    math.random = function(l, u)
        if checkcaller and not checkcaller() and State.WeaponName then
            local mult = General['Weapon Modifications']["["..State.WeaponName.."]"]
            if mult and mult.Multiplier and l == -0.05 and u == 0.05 then
                return oldRandom(l, u) * mult.Multiplier
            end
        end
        return oldRandom(l, u)
    end
end

if General.FpsUnlocker and setfpscap then
    setfpscap(999)
end
if General.Console then
    print(" [+] klient.fun -> Active")
end
