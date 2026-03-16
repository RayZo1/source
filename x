if _G.SessionStarted then
    if shared.config.General.Console then
        print(" [+] Synchronized")
    end
    shared._configUpdated = true
    return
end
_G.SessionStarted = true

if shared.config.General.Console then
    print(" [+] Initializing")
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

-- Configuration shortcuts
local Settings = shared.config
local General = Settings.General
local Silent = Settings['Silent Aim']
local CameraAim = Settings['Camera Aimbot']
local Trigger = Settings['Trigger Bot']
local ESPcfg = Settings['ESP']
local Conditions = Settings.Conditions
local FilterSelected = Conditions["Whilst a player is selected"]
local FilterSelecting = Conditions["Whilst selecting a player"]
local Redir = Silent.Redirection   -- new redirection config

-- Precomputed weapon tables
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

-- ============================================================================
-- State
-- ============================================================================
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
    ESPEnabled = ESPcfg.Enabled,
    UIEnabled = General.Info.Enabled,
    UIPos = General.Info.Position,
    ValidPlayers = {},              -- list of players with alive characters
    ESPLabels = {},                 -- userId -> {node=player, label=Drawing}
    OverwrittenTools = {},          -- track which tools we've already patched
}

-- Utility: check if player is knocked
local function isKnocked(plr)
    local char = plr.Character
    if not char then return false end
    local effects = char:FindFirstChild("BodyEffects")
    return effects and effects:FindFirstChild("K.O") and effects["K.O"].Value
end

-- Refresh list of valid players (alive, with HumanoidRootPart)
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

-- Update weapon category and FOVs
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

    -- Helper to get FOV size from a module
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

    State.SilentFOV = getFOVSize(Silent)
    State.CameraFOV = getFOVSize(CameraAim)
    State.TriggerFOV = Vector3.new(Trigger.FOV.X, Trigger.FOV.Y, Trigger.FOV.Z)
end

-- ============================================================================
-- ESP
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UserLayer_Runtime"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local OutputLabel = Instance.new("TextLabel")
OutputLabel.Name = "OutputDisplay_Runtime"
OutputLabel.Size = UDim2.new(0, 200, 0, 20)
OutputLabel.Position = UDim2.new(0, State.UIPos.X, 0, State.UIPos.Y)
OutputLabel.BackgroundTransparency = 1
OutputLabel.Text = ""
OutputLabel.TextColor3 = Color3.new(1,1,1)
OutputLabel.TextStrokeTransparency = 0.8
OutputLabel.Font = Enum.Font.Gotham
OutputLabel.TextSize = 14
OutputLabel.TextXAlignment = Enum.TextXAlignment.Left
OutputLabel.RichText = true
OutputLabel.Parent = ScreenGui
ScreenGui.Enabled = State.UIEnabled

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

-- ============================================================================
-- Helper Functions
-- ============================================================================
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

-- ============================================================================
-- Silent Aim Hook
-- ============================================================================
local __index
__index = hookmetamethod(game, "__index", function(self, key)
    if self == Mouse and (key == "Hit" or key == "Target") and State.Target then
        local char = State.Target.Character
        if char then
            local vis = not FilterSelected.Visible or hasLineOfSight(char:FindFirstChild("Head"))
            if vis and isMouseInBox(char, State.SilentFOV) then
                local hitPart = Silent['Hit Part']
                local targetPos
                if hitPart == "Closest Point" then
                    local head = char:FindFirstChild("Head")
                    if head then
                        local vel = head.Velocity or Vector3.new()
                        local pred = Silent.Prediction
                        targetPos = head.Position + Vector3.new(vel.X*pred.X, vel.Y*pred.Y, vel.Z*pred.Z)
                    end
                else
                    local part = char:FindFirstChild(hitPart) or char:FindFirstChild("Head")
                    if part then
                        local vel = part.Velocity or Vector3.new()
                        local pred = Silent.Prediction
                        targetPos = part.Position + Vector3.new(vel.X*pred.X, vel.Y*pred.Y, vel.Z*pred.Z)
                    end
                end
                if targetPos then
                    if key == "Hit" then
                        return CFrame.new(targetPos)
                    else
                        return char:FindFirstChild("Head")  -- fallback
                    end
                end
            end
        end
    end
    return __index(self, key)
end)

-- ============================================================================
-- Bullet Redirection (GunClient override)
-- ============================================================================
local function setupBulletRedirection(char)
    if not Redir.Enabled then return end

    local function patchTool(tool)
        if State.OverwrittenTools[tool] then return end
        State.OverwrittenTools[tool] = true

        -- Check if weapon is in redirection list
        local weaponList = Redir.Weapons
        local shouldRedirect = false
        for _, w in ipairs(weaponList) do
            if tool.Name == w then
                shouldRedirect = true
                break
            end
        end
        if not shouldRedirect then return end

        -- Helper: get aim direction using redirection prediction
        local function getAimDirection(origin)
            if State.Target and State.Target.Character then
                local char = State.Target.Character
                local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if part then
                    local vel = part.Velocity or Vector3.new()
                    local pred = Redir.Prediction
                    local targetPos = part.Position + Vector3.new(vel.X*pred.X, vel.Y*pred.Y, vel.Z*pred.Z)
                    return (targetPos - origin).Unit
                end
            end
            -- Fallback to mouse
            return (Mouse.Hit.Position - origin).Unit
        end

        -- Single-shot weapons (GunClient)
        if tool:FindFirstChild("GunClient") then
            tool.GunClient:Destroy()
            local handle = tool:WaitForChild("Handle")
            local range = tool:FindFirstChild("Range") and tool.Range.Value or 200
            local remoteEvent = tool:WaitForChild("RemoteEvent") or { FireServer = function() end }
            local GunHandler = require(ReplicatedStorage.Modules.GunHandler)
            local Maid = require(ReplicatedStorage.Modules.Maid).new()

            Maid:GiveTask(tool.AncestryChanged:Connect(function()
                if tool.Parent ~= LocalPlayer.Character and tool.Parent ~= LocalPlayer:FindFirstChildWhichIsA("Backpack") then
                    Maid:DoCleaning()
                end
            end))

            local lastShot = 0
            local cooldown = tool:FindFirstChild("ShootingCooldown") and tool.ShootingCooldown.Value or 0.2
            Maid:GiveTask(tool.Activated:Connect(function()
                if tick() - lastShot >= cooldown then
                    lastShot = tick()
                    remoteEvent:FireServer("Shoot")

                    local origin = (handle.CFrame * CFrame.new(-1, 0.4, 0)).Position
                    local dir = getAimDirection(origin)
                    local aimPos = origin + dir * range

                    local p1,p2,p3 = GunHandler.shoot({
                        Shooter = LocalPlayer.Character,
                        Handle = handle,
                        ForcedOrigin = origin,
                        AimPosition = aimPos,
                        BeamColor = Color3.new(1,0.545,0.149),
                        Range = range
                    })
                    ReplicatedStorage.MainEvent:FireServer("ShootGun", handle, origin, p1, p2, p3)
                    remoteEvent:FireServer()
                end
            end))
        end

        -- Shotgun weapons (GunClientShotgun)
        if tool:FindFirstChild("GunClientShotgun") then
            tool.GunClientShotgun:Destroy()
            local handle = tool:WaitForChild("Handle")
            local range = tool:FindFirstChild("Range") and tool.Range.Value or 200
            local remoteEvent = tool:WaitForChild("RemoteEvent") or { FireServer = function() end }
            local GunHandler = require(ReplicatedStorage.Modules.GunHandler)
            local Maid = require(ReplicatedStorage.Modules.Maid).new()
            local bulletCount = 5  -- could be read from config

            Maid:GiveTask(tool.AncestryChanged:Connect(function()
                if tool.Parent ~= LocalPlayer.Character and tool.Parent ~= LocalPlayer:FindFirstChildWhichIsA("Backpack") then
                    Maid:DoCleaning()
                end
            end))

            local lastShot = 0
            local cooldown = tool:FindFirstChild("ShootingCooldown") and tool.ShootingCooldown.Value or 0.4
            Maid:GiveTask(tool.Activated:Connect(function()
                if tick() - lastShot >= cooldown then
                    lastShot = tick()
                    remoteEvent:FireServer("Shoot")
                    local serverTime = Workspace:GetServerTimeNow()

                    for i = 1, bulletCount do
                        local spread = Vector3.new(
                            (math.random()>0.5 and math.random()*0.05 or -math.random()*0.05),
                            (math.random()>0.5 and math.random()*0.1  or -math.random()*0.1),
                            (math.random()>0.5 and math.random()*0.05 or -math.random()*0.05)
                        )
                        local origin = (handle.CFrame * CFrame.new(-1, 0.4, 0)).Position
                        local dir = getAimDirection(origin) + spread
                        local aimPos = origin + dir * range

                        local p1,p2,p3 = GunHandler.shoot({
                            Shooter = LocalPlayer.Character,
                            Handle = handle,
                            ForcedOrigin = origin,
                            AimPosition = aimPos,
                            BeamColor = Color3.new(1,0.545,0.149),
                            Range = range
                        })
                        ReplicatedStorage.MainEvent:FireServer("ShootGun", handle, origin, p1, p2, p3, serverTime)
                    end
                    remoteEvent:FireServer()
                end
            end))
        end

        -- Burst weapons (GunClientBurst)
        if tool:FindFirstChild("GunClientBurst") then
            tool.GunClientBurst:Destroy()
            local handle = tool:WaitForChild("Handle")
            local range = tool:FindFirstChild("Range") and tool.Range.Value or 200
            local remoteEvent = tool:WaitForChild("RemoteEvent") or { FireServer = function() end }
            local GunHandler = require(ReplicatedStorage.Modules.GunHandler)
            local Maid = require(ReplicatedStorage.Modules.Maid).new()
            local burstCooldown = tool:FindFirstChild("ShootingCooldown") and tool.ShootingCooldown.Value or 0.1
            local toleranceCd = tool:FindFirstChild("ToleranceCooldown") and tool.ToleranceCooldown.Value or 0.3

            Maid:GiveTask(tool.AncestryChanged:Connect(function()
                if tool.Parent ~= LocalPlayer.Character and tool.Parent ~= LocalPlayer:FindFirstChildWhichIsA("Backpack") then
                    Maid:DoCleaning()
                end
            end))

            local lastShot = 0
            Maid:GiveTask(tool.Activated:Connect(function()
                if tick() - lastShot >= toleranceCd then
                    lastShot = tick()
                    remoteEvent:FireServer("Shoot")
                    local serverTime = Workspace:GetServerTimeNow()
                    local ammo = tool:FindFirstChild("Ammo") and tool.Ammo.Value or 30
                    local burstCount = math.min(ammo, 3)

                    task.spawn(function()
                        for i = 1, burstCount do
                            local origin = (handle.CFrame * CFrame.new(-1, 0.4, 0)).Position
                            local dir = getAimDirection(origin)
                            local aimPos = origin + dir * range

                            local p1,p2,p3 = GunHandler.shoot({
                                Shooter = LocalPlayer.Character,
                                Handle = handle,
                                ForcedOrigin = origin,
                                AimPosition = aimPos,
                                BeamColor = Color3.new(1,0.545,0.149),
                                Range = range
                            })
                            ReplicatedStorage.MainEvent:FireServer("ShootGun", handle, origin, p1, p2, p3, serverTime)
                            if i < burstCount then
                                task.wait(burstCooldown + 0.0095)
                            end
                        end
                        remoteEvent:FireServer()
                    end)
                end
            end))
        end
    end

    -- Connect to tool added
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait()  -- let tool initialize
            patchTool(child)
        end
    end)

    -- Patch existing tools
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            patchTool(tool)
        end
    end
end

-- ============================================================================
-- Main Render Loop
-- ============================================================================
RunService.RenderStepped:Connect(function()
    -- Update camera reference
    Camera = Workspace.CurrentCamera

    -- Auto target mode
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

    -- Camera Aimbot
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

    -- Trigger Bot
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

    -- Update UI
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

    -- Update ESP
    updateESP()
end)

-- ============================================================================
-- Input Handling
-- ============================================================================
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Toggle target selection
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

    -- ESP toggle/hold
    if input.KeyCode == Enum.KeyCode[ESPcfg.Activation['Activation Bind']] then
        if ESPcfg.Activation['Activation Mode'] == "Toggle" then
            State.ESPEnabled = not State.ESPEnabled
        else
            State.ESPEnabled = true
        end
    end

    -- Trigger bot hold/toggle
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
    if input.KeyCode == Enum.KeyCode[ESPcfg.Activation['Activation Bind']] and ESPcfg.Activation['Activation Mode'] == "Hold" then
        State.ESPEnabled = false
    end
    if input.KeyCode == Enum.KeyCode[Trigger.Activation['Activation Bind']] and Trigger.Activation['Activation Mode'] == "Hold" then
        State.TriggerActive = false
    end
end)

-- ============================================================================
-- Player/Character Tracking
-- ============================================================================
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

-- Initial players
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

-- Local player character changes
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    updateWeaponCategory()
    setupBulletRedirection(char)   -- activate redirection on new character
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait()
            updateWeaponCategory()
        end
    end)
end)

if LocalPlayer.Character then
    updateWeaponCategory()
    setupBulletRedirection(LocalPlayer.Character)   -- initial redirection
end

-- Refresh valid players periodically or on events
refreshValidPlayers()
Players.PlayerAdded:Connect(refreshValidPlayers)
Players.PlayerRemoving:Connect(refreshValidPlayers)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr.Character then
        plr.Character.Humanoid.Died:Connect(refreshValidPlayers)
    end
end

-- ============================================================================
-- Weapon Modifications (math.random hook)
-- ============================================================================
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

-- ============================================================================
-- FPS Unlocker & Console
-- ============================================================================
if General.FpsUnlocker and setfpscap then
    setfpscap(999)
end
if General.Console then
    print(" [+] Active")
end

-- ============================================================================
-- Done
-- ============================================================================
