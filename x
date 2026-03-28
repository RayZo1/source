if not LPH_OBFUSCATED then
    LPH_JIT_MAX = function(...) return ... end
    LPH_NO_VIRTUALIZE = function(...) return ... end
    LPH_ENCSTR = function(...) return ... end
    LPH_ENCFUNC = function(...) return ... end
    LPH_CRASH = function() end
end
if not game:IsLoaded() then
    game.Loaded:Wait()
end
local Players = game:GetService("Players")
local Workspace = game.Workspace
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Self = Players.LocalPlayer
local Mouse = Self:GetMouse()
local Camera = workspace.CurrentCamera
local GuiInsetOffsetY = game:GetService('GuiService'):GetGuiInset().Y
local snoozestuff = {
    RBXConnections = {},
    Locals = {
        GunScriptDisabled = true, -->: Boolean
        IsTriggerBotting = nil, -->: Boolean
        TriggerbotTarget = nil, -->: Player
        IsDoubleTapping = nil, -->: Boolean
        SilentAimTarget = nil, -->: Player
        AimAssistTarget = nil, -->: Player
        IsWalkSpeeding = nil, -->: Boolean
        IsJumpSpeeding = nil, -->: Boolean
        DoubleTapState = nil, -->: Boolean
        CurrentWeapon = nil, -->: String
        IsBoxFocused = nil, -->: Boolean
        TriggerState = nil, -->: Boolean
        HitPosition = nil, -->: Vector3
        HitTrigger = nil, --> Instance
        MoveVector = nil, -->: Vector3
        LastShot = 0, -->: Float
        IsAimed = nil, -->: Boolean
        HitPart = nil, -->: Instance
    },
    Visuals = {
        Triggerbot = nil, -->: Instance
        WalkSpeed = nil, -->: Instance
        DoubleTap = nil, -->: Instance
        BoxFOV = nil,
        AimbotFOV = nil,
        SilentFOV = nil
    }
}
local Modules = {
    Cache = {}
}
local Velocity_Data = {
    Tick = tick(),
    Sample = nil,
    State = Enum.HumanoidStateType.Running,
    Y = nil,
    Recorded = {
        Alpha = nil,
        B_0 = nil,
        V_T = nil,
        V_B = nil
    }
}
local Environment = {
    Priority = {},
    PriorityLines = {},
    PriorityTexts = {},
    PrioritySquares = {},
    PriorityLabels = {},
    PriorityTools = {},
    PrioritySquaresOutlines = {}
}
local State = {
	Connections = {},
	ToolConnections = {},
	Tracked = {},
	Previous = {},
	Current = nil,
	Tick = tick()
}
local Overlay = {}
local Binds = {}
local KeybindHandler = {}
local WeaponInfo = {
    Weapons = {
        Shotguns = {
            "[TacticalShotgun]",
            "[Shotgun]",
            "[Double-Barrel SG]",
        },
        AutoShotguns = {
            "[Drum-Shotgun]"
        },
        Pistols = {
            "[Revolver]",
            "[Silencer]",
            "[Glock]"
        },
        Rifles = {
            "[AR]",
            "[SilencerAR]",
            "[AK47]",
            "[LMG]",
            "[DrumGun]"
        },
        Bursts = {
            "[AUG]",
        },
        SMG = {
            "[SMG]",
            "[P90]"
        },
        Snipers = {
            "[Rifle]"
        }
    },
    Offsets = {
        ["[Double-Barrel SG]"] = CFrame.new(0, 0.35, -2.2),
        ["[TacticalShotgun]"] = CFrame.new(0, 0.25, -2.5),
        ["[Drum-Shotgun]"] = CFrame.new(-0.1, 0.5, -2.5),
        ["[Shotgun]"] = CFrame.new(0, 0.25, -2.5),
        ["[Revolver]"] = CFrame.new(-1, 0.4, 0),
        ["[Silencer]"] = CFrame.new(0, 0.4, 1.3),
        ["[Glock]"] = CFrame.new(0.6, 0.25, 0),
        ["[Rifle]"] = CFrame.new(0, 0.25, 2.5),
        ["[AUG]"] = CFrame.new(-0.1, 0.4, 1.8),
        ["[AR]"] = CFrame.new(2, 0.35, 0),
        ["[SMG]"] = CFrame.new(0, 1, 0.5),
        ["[LMG]"] = CFrame.new(0, 0.7, -3.8),
        ["[P90]"] = CFrame.new(0, 0.2, -1.7),
        ["[AK47]"] = CFrame.new(-0.1, 0.5, -2.5),
        ["[SilencerAR]"] = CFrame.new(2.5, 0.35, 0),
        ["[DrumGun]"] = CFrame.new(0, 0.4, 2.4),
    },
    Delays = {
        ["[Double-Barrel SG]"] = 0.0095 + 0.05,   -- Double-Barrel
        ["[TacticalShotgun]"] = 0.0095,           -- Tactical-Shotgun
        ["[Drum-Shotgun]"] = 0.415,               -- Drum-Shotgun
        ["[Shotgun]"] = 1.2,                      -- Shotgun
        ["[Revolver]"] = 0.0095,                  -- Revolver: 0.0095
        ["[Silencer]"] = 0.0095,                  -- Silencer
        ["[Glock]"] = 0.0095,                     -- Glock
        ["[Rifle]"] = 1.3095,                     -- Rifle
        ["[AUG]"] = 0.0095,                          -- AUG (N/A)
        ["[AR]"] = 0.15,                          -- AR
        ["[SMG]"] = 0.6,                          -- SMG
        ["[LMG]"] = 0.62,                         -- LMG
        ["[P90]"] = 0.6,                          -- P90
        ["[AK47]"] = 0.15,                        -- AK47
        ["[SilencerAR]"] = 0.02                  -- SilencerAR
    }
}

local Games = {
    [1008451066] = {
        Name = 'Da Hood',
        Updater = 'UpdateMousePosI2',
        HoodGame = true,
        Functions = {
            KnockedFunction = function(Player)
                if (Player) and Player.Character:FindFirstChild('BodyEffects') then
                    return Player.Character.BodyEffects['K.O'].Value
                end
                --
                return false
            end,
            GrabbedFunction = function(Player)
                if Player and Player.Character then
                    if Player.Character:FindFirstChild('GRABBING_CONSTRAINT') ~= nil then
                        return true
                    else
                        return false
                    end
                else
                    return false
                end
            end,			
            RemotePath = function()
                return nil
            end
        }
    },
    [7542645964] = {
        Name = 'Dee Hood', 
        Updater = nil,
        HoodGame = true,
        Functions = {
            KnockedFunction = function(Player)
                if (Player) and Player.Character:FindFirstChild('BodyEffects') then
                    return Player.Character.BodyEffects['K.O'].Value
                end
                --
                return false
            end,
            GrabbedFunction = function(Player)
                if Player and Player.Character then
                    if Player.Character:FindFirstChild('GRABBING_CONSTRAINT') ~= nil then
                        return true
                    else
                        return false
                    end
                else
                    return false
                end
            end,			
            RemotePath = function()
                return game.ReplicatedStorage.MainEvent
            end
        }
    },
    [7542644140] = {
        Name = 'Der Hood', 
        Updater = "D3RHooDMSOUEPoS233^+",
        HoodGame = true,
        Functions = {
            KnockedFunction = function(Player)
                if (Player) and Player.Character:FindFirstChild('BodyEffects') then
                    return Player.Character.BodyEffects['K.O'].Value
                end
                --
                return false
            end,
            GrabbedFunction = function(Player)
                if Player and Player.Character then
                    if Player.Character:FindFirstChild('GRABBING_CONSTRAINT') ~= nil then
                        return true
                    else
                        return false
                    end
                else
                    return false
                end
            end,			
            RemotePath = function()
                return game.ReplicatedStorage.MainRemotes.MainRemoteEvent
            end
        }
    },
    [7478341102] = {
        Name = 'Dea Hood', 
        Updater = "MOUSEPOSUPDATEI12",
        HoodGame = true,
        Functions = {
            KnockedFunction = function(Player)
                if (Player) and Player.Character:FindFirstChild('BodyEffects') then
                    return Player.Character.BodyEffects['K.O'].Value
                end
                --
                return false
            end,
            GrabbedFunction = function(Player)
                if Player and Player.Character then
                    if Player.Character:FindFirstChild('GRABBING_CONSTRAINT') ~= nil then
                        return true
                    else
                        return false
                    end
                else
                    return false
                end
            end,			
            RemotePath = function()
                return game.ReplicatedStorage.MainRemotes.MainRemoteEvent
            end
        }
    },
    [7544400433] = {
        Name = 'Dei Hood', 
        Updater = "D3RHooDMSOUEPoS233^+",
        HoodGame = true,
        Functions = {
            KnockedFunction = function(Player)
                if (Player) and Player.Character:FindFirstChild('BodyEffects') then
                    return Player.Character.BodyEffects['K.O'].Value
                end
                --
                return false
            end,
            GrabbedFunction = function(Player)
                if Player and Player.Character then
                    if Player.Character:FindFirstChild('GRABBING_CONSTRAINT') ~= nil then
                        return true
                    else
                        return false
                    end
                else
                    return false
                end
            end,			
            RemotePath = function()
                return game.ReplicatedStorage.MainRemotes.MainRemoteEvent
            end
        }
    },
    ["Universal"] = {
        Name = 'Universal', 
        Updater = 'UpdateMousePos',
        HoodGame = true,
        Functions = {
            KnockedFunction = function(Player)
                if (Player) and Player.Character:FindFirstChild('BodyEffects') then
                    return Player.Character.BodyEffects['K.O'].Value
                end
                --
                return false
            end,
            GrabbedFunction = function(Player)
                if Player and Player.Character then
                    if Player.Character:FindFirstChild('GRABBING_CONSTRAINT') ~= nil then
                        return true
                    else
                        return false
                    end
                else
                    return false
                end
            end,			
            RemotePath = function()
                return nil
            end
        }
    }
}

local CurrentGame 
if Games[game.GameId] then
    CurrentGame = Games[game.GameId]
else
    CurrentGame = Games["Universal"]
end

LPH_JIT_MAX(function()
    do --// Modules
        do --// Overlay
            local CustomLibIndex = 0
            local Clamp = math.clamp
            local UtilityUI = Instance.new('ScreenGui'); UtilityUI.Parent = game:GetService("CoreGui"); UtilityUI.IgnoreGuiInset = true
            local UserInputService = game:GetService("UserInputService")
            local MRandom = math.random
            local Floor = math.floor
            local Round = math.round
            local Clamp = math.clamp
            local Acos = math.acos
            local Atan2 = math.atan2
            local Huge = math.huge
            local Sqrt = math.sqrt
            local Ceil = math.ceil
            local Cos = math.cos
            local Abs = math.abs
            local Sin = math.sin
            local Rad = math.rad
            local Max = math.max
            local Min = math.min
            local Deg = math.deg
            local Pi = math.pi
            local LibraryMeta = setmetatable({
                Visible = true,
                ZIndex = 0,
                Transparency = 1,
                Color = Color3.new(),
                Remove = function(self)
                    setmetatable(self, nil)
                end,
                Destroy = function(self)
                    setmetatable(self, nil)
                end
            }, {
                __add = function(t1, t2)
                    local result = table.clone(t1)

                    for index, value in t2 do
                        result[index] = value
                    end
                    return result
                end
            })
            --
            local function ClampTransparency(number)
                return Clamp(1 - number, 0, 1)
            end
            --
            function Overlay.new(ClassType)
                CustomLibIndex += 1
                if ClassType == 'Line' then
                    local LineObject = ({
                        From = Vector2.zero,
                        To = Vector2.zero,
                        Thickness = 1
                    } + LibraryMeta)
                    --
                    local Line = Instance.new('Frame')
                    --
                    Line.Name = CustomLibIndex
                    Line.AnchorPoint = (Vector2.one * .5)
                    Line.BorderSizePixel = 0
                    Line.BackgroundColor3 = LineObject.Color
                    Line.Visible = LineObject.Visible
                    Line.ZIndex = LineObject.ZIndex
                    Line.BackgroundTransparency = ClampTransparency(LineObject.Transparency)
                    Line.Size = UDim2.new()
                    Line.Parent = UtilityUI
                    --
                    return setmetatable(table.create(0), {
                        __newindex = function(_, Property, Value)
                            if Property == 'From' then
                                local Direction = (LineObject.To - Value)
                                local Center = (LineObject.To + Value) / 2
                                local Magnitude = Direction.Magnitude
                                local Theta = Deg(Atan2(Direction.Y, Direction.X))
                                --
                                Line.Position = UDim2.fromOffset(Center.X, Center.Y)
                                Line.Rotation = Theta
                                Line.Size = UDim2.fromOffset(Magnitude, LineObject.Thickness)
                            elseif Property == 'To' then
                                local Direction = (Value - LineObject.From)
                                local Center = (Value + LineObject.From) / 2
                                local Magnitude = Direction.Magnitude
                                local Theta = Deg(Atan2(Direction.Y, Direction.X))
                                --
                                Line.Position = UDim2.fromOffset(Center.X, Center.Y)
                                Line.Rotation = Theta
                                Line.Size = UDim2.fromOffset(Magnitude, LineObject.Thickness)
                            elseif Property == 'Thickness' then
                                local Thickness = (LineObject.To - LineObject.From).Magnitude
                                Line.Size = UDim2.fromOffset(Thickness, Value)
                            elseif Property == 'Visible' then
                                Line.Visible = Value
                            elseif Property == 'ZIndex' then
                                Line.ZIndex = Value
                            elseif Property == 'Transparency' then
                                Line.BackgroundTransparency = ClampTransparency(Value)
                            elseif Property == 'Color' then
                                Line.BackgroundColor3 = Value
                            end
                            LineObject[Property] = Value
                        end,
                        __index = function(self, index)
                            if index == 'Remove' or index == 'Destroy' then
                                return function()
                                    Line:Destroy()
                                    LineObject.Remove(self)
                                    return LineObject:Remove()
                                end
                            end
                            return LineObject[index]
                        end,
                        __tostring = function() return 'CustomLib' end
                    })
                elseif ClassType == 'Circle' then
                    local circleObj = ({
                        Radius = 150,
                        Position = Vector2.zero,
                        Thickness = .7,
                        Filled = false
                    } + LibraryMeta)

                    local circleFrame, uiCorner, uiStroke = Instance.new('Frame'), Instance.new('UICorner'), Instance.new('UIStroke')
                    circleFrame.Name = CustomLibIndex
                    circleFrame.AnchorPoint = (Vector2.one * .5)
                    circleFrame.BorderSizePixel = 0

                    circleFrame.BackgroundTransparency = (circleObj.Filled and ClampTransparency(circleObj.Transparency) or 1)
                    circleFrame.BackgroundColor3 = circleObj.Color
                    circleFrame.Visible = circleObj.Visible
                    circleFrame.ZIndex = circleObj.ZIndex

                    uiCorner.CornerRadius = UDim.new(1, 0)
                    circleFrame.Size = UDim2.fromOffset(circleObj.Radius, circleObj.Radius)

                    uiStroke.Thickness = circleObj.Thickness
                    uiStroke.Enabled = not circleObj.Filled
                    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                    circleFrame.Parent, uiCorner.Parent, uiStroke.Parent = UtilityUI, circleFrame, circleFrame
                    return setmetatable(table.create(0), {
                        __newindex = function(_, index, value)
                            if typeof(circleObj[index]) == 'nil' then return end

                            if index == 'Radius' then
                                local radius = value * 2
                                circleFrame.Size = UDim2.fromOffset(radius, radius)
                            elseif index == 'Position' then
                                circleFrame.Position = UDim2.fromOffset(value.X, value.Y)
                            elseif index == 'Thickness' then
                                value = Clamp(value, .6, 0x7fffffff)
                                uiStroke.Thickness = value
                            elseif index == 'Filled' then
                                circleFrame.BackgroundTransparency = (circleObj.Filled and ClampTransparency(circleObj.Transparency) or 1)
                                uiStroke.Enabled = not value
                            elseif index == 'Visible' then
                                circleFrame.Visible = value
                            elseif index == 'ZIndex' then
                                circleFrame.ZIndex = value
                            elseif index == 'Transparency' then
                                local transparency = ClampTransparency(value)

                                circleFrame.BackgroundTransparency = (circleObj.Filled and transparency or 1)
                                uiStroke.Transparency = transparency
                            elseif index == 'Color' then
                                circleFrame.BackgroundColor3 = value
                                uiStroke.Color = value
                            end
                            circleObj[index] = value
                        end,
                        __index = function(self, index)
                            if index == 'Remove' or index == 'Destroy' then
                                return function()
                                    circleFrame:Destroy()
                                    circleObj.Remove(self)
                                    return circleObj:Remove()
                                end
                            end
                            return circleObj[index]
                        end,
                        __tostring = function() return 'CustomLib' end
                    })
                elseif ClassType == 'Square' then
                    local squareObj = ({
                        Size = Vector2.zero,
                        Position = Vector2.zero,
                        Thickness = .7,
                        Filled = false,
                        Drag = false,
                    } + LibraryMeta)

                    local squareFrame, uiStroke = Instance.new('Frame'), Instance.new('UIStroke')
                    squareFrame.Name = CustomLibIndex
                    squareFrame.BorderSizePixel = 0
                    local transparency
                    if squareObj.Filled then
                        transparency = ClampTransparency(squareObj.Transparency)
                    else
                        transparency = 1
                    end
                    squareFrame.BackgroundTransparency = transparency
                    squareFrame.ZIndex = squareObj.ZIndex
                    squareFrame.BackgroundColor3 = squareObj.Color
                    squareFrame.Visible = squareObj.Visible
                    uiStroke.Thickness = squareObj.Thickness
                    uiStroke.Enabled = not squareObj.Filled
                    uiStroke.LineJoinMode = Enum.LineJoinMode.Miter
                    squareFrame.Parent, uiStroke.Parent = UtilityUI, squareFrame

                    local dragging = false
                    local dragStart = nil
                    local startPos = nil

                    squareFrame.MouseEnter:Connect(function()
                        if squareObj.Drag then
                            local inputConnection
                            inputConnection = UserInputService.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    dragging = true
                                    dragStart = input.Position
                                    startPos = squareFrame.Position
                                end
                            end)

                            local leaveConnection
                            leaveConnection = squareFrame.MouseLeave:Connect(function()
                                inputConnection:Disconnect()
                                leaveConnection:Disconnect()
                            end)
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(input)
                        if squareObj.Drag then
                            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                local delta = input.Position - dragStart
                                local newX = startPos.X.Offset + delta.X
                                local newY = startPos.Y.Offset + delta.Y
                                squareFrame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
                            end
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(input)
                        if squareObj.Drag then
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = false
                            end
                        end
                    end)

                    return setmetatable(table.create(0), {
                        __newindex = function(_, index, value)
                            if typeof(squareObj[index]) == 'nil' then return end

                            if index == 'Size' then
                                squareFrame.Size = UDim2.fromOffset(value.X, value.Y)
                            elseif index == 'Position' then
                                squareFrame.Position = UDim2.fromOffset(value.X, value.Y)
                            elseif index == 'Thickness' then
                                value = Clamp(value, 0.6, 0x7fffffff)
                                uiStroke.Thickness = value
                            elseif index == 'Filled' then
                                squareFrame.BackgroundTransparency = 1
                                uiStroke.Enabled = not value
                            elseif index == 'Visible' then
                                squareFrame.Visible = value
                            elseif index == 'ZIndex' then
                                squareFrame.ZIndex = value
                            elseif index == 'Transparency' then
                                local transparency = ClampTransparency(value)

                                squareFrame.BackgroundTransparency = 1
                                uiStroke.Transparency = transparency
                            elseif index == 'Color' then
                                uiStroke.Color = value
                                squareFrame.BackgroundColor3 = value
                            end
                            squareObj[index] = value
                        end,
                        __index = function(self, index)
                            if index == 'Remove' or index == 'Destroy' then
                                return function()
                                    squareFrame:Destroy()
                                    squareObj.Remove(self)
                                    return squareObj:Remove()
                                end
                            end
                            return squareObj[index]
                        end,
                        __tostring = function() return 'CustomLib' end
                    })
                elseif ClassType == 'Text' then
                    local textObj = ({
                        Text = '',
                        Font = Enum.Font.SourceSansBold,
                        Size = 0,
                        Position = Vector2.zero,
                        Center = false,
                        Outline = false,
                        OutlineColor = Color3.new()
                    } + LibraryMeta)

                    local textLabel, uiStroke = Instance.new('TextLabel'), Instance.new('UIStroke')
                    textLabel.Name = CustomLibIndex
                    textLabel.AnchorPoint = (Vector2.one * .5)
                    textLabel.BorderSizePixel = 0
                    textLabel.BackgroundTransparency = 1
                    textLabel.RichText = true
                    textLabel.Visible = textObj.Visible
                    textLabel.TextColor3 = textObj.Color
                    textLabel.TextTransparency = ClampTransparency(textObj.Transparency)
                    textLabel.ZIndex = textObj.ZIndex

                    textLabel.Font = Enum.Font.SourceSansBold
                    textLabel.TextSize = textObj.Size

                    textLabel:GetPropertyChangedSignal('TextBounds'):Connect(function()
                        local textBounds = textLabel.TextBounds
                        local offset = textBounds / 2

                        local offsetX
                        if not textObj.Center then
                            offsetX = offset.X
                        else
                            offsetX = 0
                        end

                        textLabel.Position = UDim2.fromOffset(textObj.Position.X + offsetX, textObj.Position.Y + offset.Y)
                    end)

                    uiStroke.Thickness = 1
                    uiStroke.Enabled = textObj.Outline
                    uiStroke.Color = textObj.Color

                    textLabel.Parent, uiStroke.Parent = UtilityUI, textLabel
                    return setmetatable(table.create(0), {
                        __newindex = function(_, index, value)
                            if typeof(textObj[index]) == 'nil' then return end

                            if index == 'Text' then
                                textLabel.Text = value
                            elseif index == 'Font' then
                                value = Clamp(value, 0, 3)
                            elseif index == 'Size' then
                                textLabel.TextSize = value
                            elseif index == 'Position' then
                                local offset = textLabel.TextBounds / 2

                                local offsetX
                                if not textObj.Center then
                                    offsetX = offset.X
                                else
                                    offsetX = 0
                                end

                                textLabel.Position = UDim2.fromOffset(textObj.Position.X + offsetX, textObj.Position.Y + offset.Y)
                            elseif index == 'Center' then
                                local position
                                if value then
                                    position = workspace.CurrentCamera.ViewportSize / 2
                                else
                                    position = textObj.Position
                                end
                                textLabel.Position = UDim2.fromOffset(position.X, position.Y)
                            elseif index == 'Outline' then
                                uiStroke.Enabled = value
                            elseif index == 'OutlineColor' then
                                uiStroke.Color = value
                            elseif index == 'Visible' then
                                textLabel.Visible = value
                            elseif index == 'ZIndex' then
                                textLabel.ZIndex = value
                            elseif index == 'Transparency' then
                                local transparency = ClampTransparency(value)

                                textLabel.TextTransparency = transparency
                                uiStroke.Transparency = transparency
                            elseif index == 'Color' then
                                textLabel.TextColor3 = value
                            end
                            textObj[index] = value
                        end,
                        __index = function(self, index)
                            if index == 'Remove' or index == 'Destroy' then
                                return function()
                                    textLabel:Destroy()
                                    textObj.Remove(self)
                                    return textObj:Remove()
                                end
                            elseif index == 'TextBounds' then
                                return textLabel.TextBounds
                            end
                            return textObj[index]
                        end,
                        __tostring = function() return 'CustomLib' end
                    })
                elseif ClassType == 'Image' then
                    local imageObj = ({
                        Data = '',
                        DataURL = 'rbxassetid:/',
                        Size = Vector2.zero,
                        Position = Vector2.zero
                    } + LibraryMeta)

                    local imageFrame = Instance.new('ImageLabel')
                    imageFrame.Name = CustomLibIndex
                    imageFrame.BorderSizePixel = 0
                    imageFrame.ScaleType = Enum.ScaleType.Stretch
                    imageFrame.BackgroundTransparency = 1

                    imageFrame.Visible = imageObj.Visible
                    imageFrame.ZIndex = imageObj.ZIndex
                    imageFrame.ImageTransparency = ClampTransparency(imageObj.Transparency)
                    imageFrame.ImageColor3 = imageObj.Color

                    imageFrame.Parent = UtilityUI
                    return setmetatable(table.create(0), {
                        __newindex = function(_, index, value)
                            if typeof(imageObj[index]) == 'nil' then return end

                            if index == 'Data' then
                                -- later
                            elseif index == 'DataURL' then -- temporary property
                                imageFrame.Image = value
                            elseif index == 'Size' then
                                imageFrame.Size = UDim2.fromOffset(value.X, value.Y)
                            elseif index == 'Position' then
                                imageFrame.Position = UDim2.fromOffset(value.X, value.Y)
                            elseif index == 'Visible' then
                                imageFrame.Visible = value
                            elseif index == 'ZIndex' then
                                imageFrame.ZIndex = value
                            elseif index == 'Transparency' then
                                imageFrame.ImageTransparency = ClampTransparency(value)
                            elseif index == 'Color' then
                                imageFrame.ImageColor3 = value
                            end
                            imageObj[index] = value
                        end,
                        __index = function(self, index)
                            if index == 'Remove' or index == 'Destroy' then
                                return function()
                                    imageFrame:Destroy()
                                    imageObj.Remove(self)
                                    return imageObj:Remove()
                                end
                            elseif index == 'Data' then
                                return nil
                            end
                            return imageObj[index]
                        end,
                        __tostring = function() return 'CustomLib' end
                    })
                end
            end
            if not snoozestuff.Visuals.BoxFOV then
                snoozestuff.Visuals.BoxFOV = Overlay.new('Square')
            end
        end
        do --// Keybind Handler
            function KeybindHandler.GetBind(Id)
                if (not Id) then
                    return Binds
                end
        
        
                local FoundI = -1
                for i, Bind in ipairs(Binds) do
                    -- // Check if id matches
                    if (Bind.Id == Id) then
                        -- // Set
                        FoundI = i
                        break
                    end
                end
        
        
                if (FoundI == -1) then
                    return false
                end
        
        
                return Binds[FoundI], FoundI
            end
            --
            local ValidInputItems = {"KeyCode", "UserInputType"}
            function KeybindHandler.CreateBind(Data)
                -- // Make sure we gave a keybind
                local Keybind = typeof(Data.Keybind) == "function" and Data.Keybind() or Data.Keybind
                assert(typeof(Keybind) == "EnumItem" and table.find(ValidInputItems, tostring(Keybind.EnumType)), "Invalid keybind")
        
                -- // Add to binds
                local Id = game:GetService("HttpService"):GenerateGUID()
                table.insert(Binds, {
                    Id = Id,
                    Keybind = Data.Keybind,
                    Callback = Data.Callback or function(State, Bind) end,
                    ProcessedCheck = Data.ProcessedCheck or false,
                    Hold = Data.Hold or false,
                    State = Data.State or false
                })
        
                -- // Return the Id
                return Id
            end
            --
            function KeybindHandler.Update(Id, Property, NewValue)
                -- // Get the bind
                local Bind = KeybindHandler.Get(Id)
                if (not Bind) then
                    return false
                end
        
                -- // Set
                Bind[Property] = NewValue
                return true
            end
            --
            function KeybindHandler.UpdateKeybind(Id, NewKeybind)
                return KeybindHandler.Update(Id, "Keybind", NewKeybind)
            end
            --
            function KeybindHandler.UpdateCallback(Id, NewCallback)
                return KeybindHandler.Update(Id, "Callback", NewCallback)
            end
            --
            function KeybindHandler.RemoveBind(Id)
                -- // Get the bind
                local _, FoundI = KeybindHandler.Get(Id)
                if (not FoundI) then
                    return false
                end
        
                -- // Remove
                table.remove(Binds, FoundI)
                return true
            end
            --
            function KeybindHandler.CreateConnection()
                -- // Connects to whenever we make an input
                KeybindHandler.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input, gameProcessedEvent)
                    -- // Loop through all binds
                    for _, Bind in ipairs(Binds) do
                        -- // Check
                        local Keybind = Bind.Keybind
                        Keybind = typeof(Keybind) == "function" and Keybind() or Keybind
                        local Property = tostring(Keybind.EnumType)
                        if (Input[Property] ~= Keybind) or (Bind.ProcessedCheck and gameProcessedEvent) then
                            continue
                        end
        
                        -- // Fire
                        if (Bind.Hold) then
                            Bind.State = true
                        else
                            Bind.State = not Bind.State
                        end
        
                        Bind.Callback(Bind.State, Bind)
                    end
                end)
        
                -- // See whenever we lift up
                KeybindHandler.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input, gameProcessedEvent)
                    -- // Loop through all binds
                    for _, Bind in ipairs(Binds) do
                        -- // Make sure is a hold
                        if (not Bind.Hold) then
                            continue
                        end
        
                        -- // Check
                        local Keybind = Bind.Keybind
                        Keybind = typeof(Keybind) == "function" and Keybind() or Keybind
                        local Property = tostring(Keybind.EnumType)
                        if (Input[Property] ~= Keybind) or (Bind.ProcessedCheck and gameProcessedEvent) then
                            continue
                        end
        
                        -- // Fire
                        Bind.State = false
                        Bind.Callback(Bind.State, Bind)
                    end
                end)
            end
            --
            function KeybindHandler.Destroy(KeepConnection)
                -- // Destroy connection
                if (not KeepConnection) then
                    if (KeybindHandler.InputBeganConnection) then
                        KeybindHandler.InputBeganConnection:Disconnect()
                        KeybindHandler.InputBeganConnection = nil
                    end
        
                    if (KeybindHandler.InputEndedConnection) then
                        KeybindHandler.InputEndedConnection:Disconnect()
                        KeybindHandler.InputEndedConnection = nil
                    end
                end
        
                -- // Empty binds
                Binds = {}
            end
            --
            --KeybindHandler.TestMode = true
            KeybindHandler.CreateConnection()
            if (KeybindHandler.TestMode) then
                KeybindHandler.CreateBind({
                    Keybind = Enum.KeyCode.X,
                    ProcessedCheck = true,
                    Callback = function(State, Bind)
                        print(Bind.Keybind.Name .. " was pressed with state " .. tostring(State))
                    end
                })
                KeybindHandler.CreateBind({
                    Keybind = Enum.UserInputType.MouseButton2,
                    ProcessedCheck = true,
                    Callback = function(State, Bind)
                        print(Bind.Keybind.Name .. " was pressed with state " .. tostring(State))
                    end
                })
        
        
                KeybindHandler.CreateBind({
                    Keybind = Enum.UserInputType.MouseButton2,
                    ProcessedCheck = true,
                    Callback = function(State, Bind)
                        local Action = State and "pressed" or "released"
                        print(Bind.Keybind.Name .. " was " .. Action)
                
                        if State then
                            task.spawn(function() 
                                while State do
                                    print("Holding " .. Bind.Keybind.Name)
                                    task.wait(0.1) 
                                end
                            end)
                        end
                    end,
                    Hold = true
                })
                
            end
        end
        --
        function Modules.Get(Id)
            if not Modules.Cache[Id] then
                Modules.Cache[Id] = {
                    c = Modules[Id](),
                }
            end
        
            return Modules.Cache[Id].c
        end
        --
        function Modules.Utility()
            local function ThreadLoop(Wait, Function)
                task.spawn(function()
                    while true do
                        local Delta = task.wait(Wait)
                        local Success, Error = pcall(Function, Delta)
                        if not Success then
                            warn("thread error " .. Error)
                        elseif Error == "break" then
                            --print("thread stopped")
                            break
                        end
                    end
                end)
            end
    
            local function ThreadFunction(Func, Name, ...)
                local Func = Name and function()
                    local Passed, Statement = pcall(Func)
                    --
                    if not Passed then
                        warn('ThreadFunction Error:\n', '              ' .. Name .. ':', Statement)
                    end
                end or Func
                local Thread = coroutine.create(Func)
                --
                coroutine.resume(Thread, ...)
                return Thread
            end
    
            local function Connection(connectionType, connectionCallback)
                local connection = connectionType:Connect(connectionCallback)
                snoozestuff.RBXConnections[#snoozestuff.RBXConnections + 1] = connection
                return connection
            end
    
            return {
                ThreadFunction = ThreadFunction,
                ThreadLoop = ThreadLoop,
                Connection = Connection
            }
        end
        --
        function Modules.Engine()
            local function RayCast(Part, Origin, Ignore, Distance)
                local Ignore = Ignore or {}
                local Distance = Distance or 2000
                local Cast = Ray.new(Origin, (Part.Position - Origin).Unit * Distance)
                local Hit = Workspace:FindPartOnRayWithIgnoreList(Cast, Ignore)
                return (Hit and Hit:IsDescendantOf(Part.Parent)) == true, Hit
            end
    
            return {
                RayCast = RayCast
            }
        end
        --
        local Gui 
        function Modules.ScreenGui()
            
            local function Setup()
                if not Gui then
                    Gui = Instance.new("ScreenGui")
                    Gui.ResetOnSpawn = false    
                    Gui.Parent = game:GetService("CoreGui")
                end
            end
        
            local function GetParentInstance()
                return Gui
            end
        
            local function DrawText(Parent)
                Setup() 
                Parent = Parent or GetParentInstance()
                
                local Text = Instance.new("TextLabel", Parent)
                Text.Text = "Label"
                Text.BackgroundTransparency = 1
                Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Text.Font = Enum.Font.SourceSansBold 
                Text.TextSize = 42
                Text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                Text.TextStrokeTransparency = 0.85
                Text.Visible = false
                Text.TextXAlignment = Enum.TextXAlignment.Left
    
                task.wait()
                
                local Width = Text.TextBounds.X
                Text.Size = UDim2.new(0, Width + 10, 0, Text.TextSize) 
        
                return Text
            end
        
            local function UpdateDrawings()
                Setup() 
        
                if not snoozestuff.Visuals then
                    snoozestuff.Visuals = {}
                end
        
                if not snoozestuff.Visuals.Triggerbot then
                    snoozestuff.Visuals.Triggerbot = DrawText(Gui)
                end
    
                if not snoozestuff.Visuals.WalkSpeed then
                    snoozestuff.Visuals.WalkSpeed = DrawText(Gui)
                end
    
                if not snoozestuff.Visuals.DoubleTap then
                    snoozestuff.Visuals.DoubleTap = DrawText(Gui)
                end
    
                if shared["snoozesaved"].Universal.Indicators.Enabled and shared["snoozesaved"].Modifications['Double Tap'].Enabled and snoozestuff.Visuals.DoubleTap then
                    local viewportSize = Camera.ViewportSize
                    local centerX = viewportSize.X / 2
                    local centerY = viewportSize.Y / 2
        
                    snoozestuff.Visuals.DoubleTap.Position = UDim2.new(
                        0, centerX - (snoozestuff.Visuals.DoubleTap.Size.X.Offset / 2) - 900,  
                        0, centerY - (snoozestuff.Visuals.DoubleTap.Size.Y.Offset / 2) + 120 
                    )
                    
                    if snoozestuff.Locals.DoubleTapState then
                        snoozestuff.Visuals.DoubleTap.TextColor3 = Color3.fromRGB(255, 0, 0)
                    else
                        snoozestuff.Visuals.DoubleTap.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end
                    snoozestuff.Visuals.DoubleTap.Visible = shared["snoozesaved"].Modifications['Double Tap'].Enabled and snoozestuff.Locals.IsDoubleTapping
                    snoozestuff.Visuals.DoubleTap.Text = "DTap"
                end
    
                if shared["snoozesaved"].Universal.Indicators.Enabled and shared["snoozesaved"].Physics.Walking.Enabled and snoozestuff.Visuals.WalkSpeed then
                    local viewportSize = Camera.ViewportSize
                    local centerX = viewportSize.X / 2
                    local centerY = viewportSize.Y / 2
        
                    snoozestuff.Visuals.WalkSpeed.Position = UDim2.new(
                        0, centerX - (snoozestuff.Visuals.WalkSpeed.Size.X.Offset / 2) - 900,  
                        0, centerY - (snoozestuff.Visuals.WalkSpeed.Size.Y.Offset / 2) + 160 
                    )
                    
                    snoozestuff.Visuals.WalkSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
                    snoozestuff.Visuals.WalkSpeed.Visible = shared["snoozesaved"].Physics.Walking.Enabled and snoozestuff.Locals.IsWalkSpeeding
                    snoozestuff.Visuals.WalkSpeed.Text = "WSpeed"
                end
        
                if shared["snoozesaved"].Universal.Indicators.Enabled and shared["snoozesaved"].TriggerBot.Enabled and snoozestuff.Visuals.Triggerbot then
                    local viewportSize = Camera.ViewportSize
                    local centerX = viewportSize.X / 2
                    local centerY = viewportSize.Y / 2
        
                    snoozestuff.Visuals.Triggerbot.Position = UDim2.new(
                        0, centerX - (snoozestuff.Visuals.Triggerbot.Size.X.Offset / 2) - 900,  
                        0, centerY - (snoozestuff.Visuals.Triggerbot.Size.Y.Offset / 2) + 200 
                    )
                    
                    snoozestuff.Visuals.Triggerbot.TextColor3 = Color3.fromRGB(255, 255, 255)
                    snoozestuff.Visuals.Triggerbot.Visible = shared["snoozesaved"].TriggerBot.Enabled and snoozestuff.Locals.TriggerState
                    snoozestuff.Visuals.Triggerbot.Text = "Tbot"
                end
            end
        
            return {
                Setup = Setup,
                DrawText = DrawText,
                UpdateDrawings = UpdateDrawings
            }
        end
        --
        function Modules.Player()
            local Engine = Modules.Get("Engine")
    
            local function ValidateClient(Player)
                local Object = Player.Character
                local Humanoid = (Object and Object:FindFirstChild("Humanoid")) or false
                local RootPart = (Humanoid and Humanoid.RootPart) or false
                return Object, Humanoid, RootPart
            end
            
            local function IsDesynced(RootPart)
                local Velocity = RootPart.Velocity

                if Velocity.Magnitude >= 75 then
                    return true
                end

                if shared["snoozesaved"].Physics.Velocity['Always On'] then
                    return true
                end
             
                return false
			end
    
            local function GetOrigin(Origin)
                if Origin == 'Head' then
                    local Object, Humanoid, RootPart = ValidateClient(Self)
                    local Head = Object:FindFirstChild('Head')
            
                    if Head and Head:IsA('RootPart') then
                        return Head.CFrame.Position
                    end
                elseif Origin == 'Torso' then
                    local Object, Humanoid, RootPart = ValidateClient(Self)
                
                    if RootPart then
                        return RootPart.CFrame.Position
                    end
                end
                return Workspace.CurrentCamera.CFrame.Position
            end
    
            local function IsKnocked(Character)
                if (Character) and Character:FindFirstChild('BodyEffects') then
                    return Character:FindFirstChild("BodyEffects")['K.O'].Value
                end
                return false
            end
    
            local function IsGrabbed(Character)
                if Character then
                    if Character:FindFirstChild('GRABBING_CONSTRAINT') then
                        return true
                    else
                        return false
                    end
                else
                    return false
                end 
            end
    
            local function GetClosestPlayerToCursor()
                local CurrentCamera = workspace.CurrentCamera
                local MousePosition = UserInputService:GetMouseLocation()
                local Closest
                local Distance = 1/0
            
    
                for _, Player in ipairs(Players:GetPlayers()) do
                    if (Player == Self) then
                        continue
                    end
            
                    local Character = Player.Character
                    if (not Character) then
                        continue
                    end

                    if Player.Character then
                        
                        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                        if (not HumanoidRootPart) then
                            continue
                        end
        
                        if shared["snoozesaved"].Conditions.Wall then
                            if not Engine.RayCast(Player.Character.HumanoidRootPart, GetOrigin('Camera'), {Self.Character}) then
                                continue
                            end
                        end
                
                        if shared["snoozesaved"].Conditions.Forcefield then
                            if Character:FindFirstChild("ForceField") then
                                continue
                            end
                        end
        
                        if shared["snoozesaved"].Conditions.Knocked then
                            if IsKnocked(Character) then
                                continue
                            end
                        end
        
                        if shared["snoozesaved"].Conditions.Grabbed then
                            if IsGrabbed(Character) then
                                continue
                            end
                        end
                        
                        local Position, OnScreen = CurrentCamera:WorldToViewportPoint(HumanoidRootPart.Position)
        
                        if shared["snoozesaved"].Conditions.Visible then
                            if not OnScreen then
                                continue
                            end
                        end
                        
                        local Magnitude = (Vector2.new(Position.X, Position.Y) - MousePosition).Magnitude
                        if (Magnitude < Distance) then
                            Closest = Player
                            Distance = Magnitude
                        end
                    end
                end
                return Closest
            end
    
            local function GetClosestPartToCursor(Character)
                local CurrentCamera = Workspace.CurrentCamera
                local Closest
                local Distance = 1/0
                for _, Part in ipairs(Character:GetChildren()) do
                    if (not Part:IsA("BasePart")) then
                        continue
                    end
        
                    local Position = CurrentCamera:WorldToViewportPoint(Part.Position)
                    Position = Vector2.new(Position.X, Position.Y)
                    local Magnitude = (UserInputService:GetMouseLocation() - Position).Magnitude
        
                    if (Magnitude < Distance) then
                        Closest = Part
                        Distance = Magnitude
                    end
                end
        
                return Closest
            end
    
            local function GetClosestPartToCursorFilter(Character, PartsToCheck)
                local CurrentCamera = Workspace.CurrentCamera
                local Closest
                local Distance = 1/0
                
                for _, Part in ipairs(Character:GetChildren()) do
                    if not Part:IsA("BasePart") or (PartsToCheck and not table.find(PartsToCheck, Part.Name)) then
                        continue
                    end
            
                    local Position = CurrentCamera:WorldToViewportPoint(Part.Position)
                    Position = Vector2.new(Position.X, Position.Y)
                    local Magnitude = (UserInputService:GetMouseLocation() - Position).Magnitude
            
                    if Magnitude < Distance then
                        Closest = Part
                        Distance = Magnitude
                    end
                end
            
                return Closest
            end
            
            local function GetClosestPointOnPart(Part, Scale)
                local PartCFrame = Part.CFrame
                local PartSize = Part.Size
                local PartSizeTransformed = PartSize * (Scale / 2)
        
                local MousePosition = UserInputService:GetMouseLocation()
                local CurrentCamera = Workspace.CurrentCamera
        
                local MouseRay = CurrentCamera:ViewportPointToRay(MousePosition.X, MousePosition.Y)
                local Transformed = PartCFrame:PointToObjectSpace(MouseRay.Origin + (MouseRay.Direction * MouseRay.Direction:Dot(PartCFrame.Position - MouseRay.Origin)))
        
    
                
                if (Mouse.Target == Part) then
                    return Vector3.new(Mouse.Hit.X, Mouse.Hit.Y, Mouse.Hit.Z)
                end
    
                return PartCFrame * Vector3.new(
                    math.clamp(Transformed.X, -PartSizeTransformed.X, PartSizeTransformed.X),
                    math.clamp(Transformed.Y, -PartSizeTransformed.Y, PartSizeTransformed.Y),
                    math.clamp(Transformed.Z, -PartSizeTransformed.Z, PartSizeTransformed.Z)
                )
            end
    
            local function GetClosestPointOnPartBasic(Part)
                if Part then
                    local MouseRay = Mouse.UnitRay
                    MouseRay = MouseRay.Origin + (MouseRay.Direction * (Part.Position - MouseRay.Origin).Magnitude)
                    local Point = (MouseRay.Y >= (Part.Position - Part.Size / 2).Y and MouseRay.Y <= (Part.Position + Part.Size / 2).Y) and (Part.Position + Vector3.new(0, -Part.Position.Y + MouseRay.Y, 0)) or Part.Position
                    local Check = RaycastParams.new()
                    Check.FilterType = Enum.RaycastFilterType.Whitelist
                    Check.FilterDescendantsInstances = {Part}
                    local Ray = Workspace:Raycast(MouseRay, (Point - MouseRay), Check)
    
                    if Mouse.Target == Part then
                        return Mouse.Hit.Position
                    end
    
                    if Ray then
                        return Ray.Position
                    else
                        return Mouse.Hit.Position
                    end
                end 
            end
    
            local function SelfMods()
                if not Self.Character then return end
                if shared["snoozesaved"].Physics.Walking.Enabled and snoozestuff.Locals.IsWalkSpeeding then
                    local Object, Humanoid, RootPart = ValidateClient(Self)
                    if (Humanoid and RootPart) then

                        if not shared["snoozesaved"].Physics.Walking.Glide then
                            RootPart.CustomPhysicalProperties = PhysicalProperties.new(100, .3, .5)
                        else
                            RootPart.CustomPhysicalProperties = nil
                        end
                        Humanoid.WalkSpeed = shared["snoozesaved"].Physics.Walking.Amount * 100
                        --[[
                        local moveDirection = Humanoid.MoveDirection
                        snoozestuff.Locals.MoveVector = moveDirection * Humanoid.WalkSpeed * shared["snoozesaved"].Physics.Walking.Amount
                        RootPart.Velocity = Vector3.new(snoozestuff.Locals.MoveVector.X, RootPart.Velocity.Y, snoozestuff.Locals.MoveVector.Z)]]
                    end
                end
    
                if shared["snoozesaved"].Physics.Falling.Enabled then
                    if Self.Character.Humanoid.Health > 1 and  Self.Character.Humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
                        Self.Character.Humanoid:ChangeState("GettingUp")
                    end
                end

              
            end

            local function Resolve(RootPart)
                if not RootPart then return Vector3.new(0, 0, 0) end
                local Suppression = 1
                local Aggression = 1
                local Position = RootPart.Position
                local Tick = tick()
                --
                State.Tracked = State.Tracked or {}
                State.Previous = State.Previous or {}
                --
                table.insert(State.Tracked, Position)
                table.insert(State.Previous, Tick)
                --
                if #State.Tracked >= 3 then
                    local Indexes = #State.Tracked
                    --
                    local TimeData = State.Previous
                    local PositionEntries = State.Tracked
                    --
                    local IndexOne = PositionEntries[Indexes - 2]
                    local IndexTwo = PositionEntries[Indexes - 1]
                    local LastIndex = PositionEntries[Indexes]
                    local TimeOne = TimeData[Indexes - 2]
                    local TimeTwo = TimeData[Indexes - 1]
                    local LastTime = TimeData[Indexes]
                    --
                    if (TimeTwo - TimeOne) ~= 0 and (LastTime - TimeTwo) ~= 0 then
                        local StartVelocity = (IndexTwo - IndexOne) / (TimeTwo - TimeOne)
                        local EndVelocity = (LastIndex - IndexTwo) / (LastTime - TimeTwo)
                        --
                        local ResolvedVelocity = (Aggression - Suppression) * StartVelocity + Suppression * EndVelocity
                        --
                        return ResolvedVelocity
                    else
                        return RootPart.Velocity
                    end
                else    
                    return RootPart.Velocity
                end
            end

            local function GetBodySize(Character)
                local Part = GetClosestPartToCursor(Character)
                if (Part) then
                    local l = workspace.CurrentCamera:WorldToScreenPoint(Part.Position - Part.Size / 2)
                    local r = workspace.CurrentCamera:WorldToScreenPoint(Part.Position + Part.Size / 2)
                    local w = math.abs(l.X - r.X)
                    local h = math.abs(l.Y - r.Y)
                    --
                    return w, h
                end
                --
                return 0, 0 
            end
            
            local function get_quad(a, b, c)
                local s = b^2 - 4 * a * c
                if s < 0 then
                    return nil
                end
                local d = math.sqrt(s)
                local t1 = (-b + d) / (2 * a)
                local t2 = (-b - d) / (2 * a)
                --
                if t1 >= 0 and t2 >= 0 then
                    return math.min(t1, t2)
                elseif t1 >= 0 then
                    return t1
                elseif t2 >= 0 then
                    return t2
                end
                --
                return nil
            end
            --
            local function get_interception(A, B0, v_t, v_b)
                local function getCoefficients(A_comp, B_comp, v_t_comp)
                    local a = v_t_comp * v_t_comp - v_b^2
                    local b = 2 * (A_comp - B_comp) * v_t_comp
                    local c = (A_comp - B_comp) * (A_comp - B_comp)
                    return a, b, c
                end
            
                local function solveDimension(A_comp, B_comp, v_t_comp)
                    local a, b, c = getCoefficients(A_comp, B_comp, v_t_comp)
                    return get_quad(a, b, c)
                end
            
                local t_x, err_x = solveDimension(A.x, B0.x, v_t.x)
                local t_y, err_y = solveDimension(A.y, B0.y, v_t.y)
                local t_z, err_z = solveDimension(A.z, B0.z, v_t.z)
            
                if not t_x or not t_y or not t_z then
                    return nil, 'how did we end up here'
                end
            
                local t = math.max(t_x, t_y, t_z)
            
                local Bt = B0 + v_t * t
                return Bt, t_x, t_y, t_z
            end
            --
            local function get_ground(position)
                local ray = Ray.new(position, Vector3.new(0, -1000, 0))
                local hitPart, hitPosition = workspace:FindPartOnRay(ray)
                --
                if hitPart then
                    return hitPosition.Y
                else
                    return position.Y
                end
            end
            --
            local function backup_velocity(t, width, height)
                local average_size = (width + height) / 2
                local base_size = 100
                local size_factor = (average_size / base_size) - 1
                size_factor = math.clamp(size_factor, -1, 1)
                local min_adjustment = 0.05
                local max_adjustment = 0.145
                local adjustment_range = max_adjustment - min_adjustment
                local adjusted_t = min_adjustment + (size_factor ^ 2) * adjustment_range
                return adjusted_t
            end
            --
            local function get_velocity(t, width, height)
                local average_size = (width + height) / 2
                local base_size = 100
                local size_factor = (average_size / base_size) - 1
                size_factor = math.clamp(size_factor, -1, 1)
            
                local min_adjustment = 0.05
                local max_adjustment = 0.145
                local adjustment_range = max_adjustment - min_adjustment
            
                local adjustment = min_adjustment + (size_factor ^ 2) * adjustment_range
                return Vector3.new(adjustment, adjustment, adjustment) * t
            end
            
            local function m_wait()
                local t = tick()
                game.ReplicatedStorage.DefaultChatSystemChatEvents.MutePlayerRequest:InvokeServer()
                return (tick() - t) * 1000 / 0.5
            end
            
            local function AutomatedPrediction()
                local silentAimSettings = shared["snoozesaved"]
                local TargetPlayerData = snoozestuff.Locals.SilentAimTarget
            
                local silentAimTarget = TargetPlayerData
                local playerCharacter = Self.Character
            
                if silentAimTarget and silentAimTarget.Character and playerCharacter and silentAimSettings.Automated then
                    local tool = playerCharacter:FindFirstChildOfClass('Tool')
                    local handle = tool and tool:FindFirstChild('Handle')
                    local shootBBGUI = handle and handle:FindFirstChild('ShootBBGUI')
            
                    if not silentAimTarget.Character:FindFirstChild("Humanoid") then
                        return
                    end
                    if handle and shootBBGUI then
                        local humanoidRootPart = TargetPlayerData.Character.HumanoidRootPart
                        local Velocity = IsDesynced(humanoidRootPart) and Resolve(humanoidRootPart) or humanoidRootPart.Velocity
                        local handlePosition = handle.Position
                        local origin = handlePosition + handle.CFrame:VectorToWorldSpace(shootBBGUI.StudsOffsetWorldSpace)
            
                        Velocity_Data.Recorded = {
                            Alpha = origin,
                            B_0 = humanoidRootPart.Position,
                            V_T = Velocity,
                            V_B = m_wait() * silentAimSettings.Prediction.Stabilize
                        }
                        
                        local Bt, t_x, t_y, t_z = get_interception(
                            origin,
                            humanoidRootPart.Position,
                            Velocity,
                            Velocity_Data.Recorded.V_B
                        )
            
                        if Bt then
                            local predictionVector = Vector3.new(t_x, t_y, t_z)
                            local width, height = GetBodySize(silentAimTarget)
                            silentAimSettings.Prediction.X = backup_velocity(predictionVector.Magnitude, width, height)
                            silentAimSettings.Prediction.Y = backup_velocity(predictionVector.Magnitude, width, height)
            
                            local adjustedPrediction = get_velocity(predictionVector, width, height)
                            if adjustedPrediction then
                                local groundLevel = get_ground(Bt)
                                Bt = Vector3.new(Bt.X, math.max(Bt.Y, groundLevel), Bt.Z)
            
                                local heightAdjustment = math.max(0, Bt.Y - humanoidRootPart.Position.Y)
                                Velocity_Data.Y = adjustedPrediction.Y * (heightAdjustment / (Bt.Y - humanoidRootPart.Position.Y + 1))
                                Velocity_Data.State = TargetPlayerData.Character.Humanoid:GetState()
                            end
                        end
                    end
                end
            end
    
            local function GetHitPosition(Mode)
                if Mode == 'Assist' then
                    local NearestPart = GetClosestPartToCursor(snoozestuff.Locals.AimAssistTarget.Character)
                    local NearestPoint 
                    local Hit
    
                    if shared["snoozesaved"].AimAssist.Type == 'Advanced' then
                        NearestPoint = GetClosestPointOnPart(NearestPart, shared["snoozesaved"].SilentAim.Scale)
                    else
                        NearestPoint = GetClosestPointOnPartBasic(NearestPart)
                    end
        
                    local TargetPosition
                    if shared["snoozesaved"].AimAssist.Point == "Nearest Part" then
                        TargetPosition = NearestPart.Position
                    elseif shared["snoozesaved"].AimAssist.Point == "Nearest Point" then
                        TargetPosition = NearestPoint
                    else
                        TargetPosition = GetClosestPartToCursorFilter(snoozestuff.Locals.AimAssistTarget.Character, shared["snoozesaved"].AimAssist.Parts).Position
                    end
        
                    if shared["snoozesaved"].AimAssist.Prediction.Enabled then
                        local RootPart = snoozestuff.Locals.AimAssistTarget.Character.HumanoidRootPart
                        local Velocity = IsDesynced(RootPart) and Resolve(RootPart) or RootPart.Velocity
                        local PredictionVector = Vector3.new(shared["snoozesaved"].AimAssist.Prediction.Ground, shared["snoozesaved"].AimAssist.Prediction.Air, shared["snoozesaved"].AimAssist.Prediction.Ground)
                        Hit = TargetPosition + Velocity * PredictionVector
                    else
                        Hit = TargetPosition
                    end
    
                    return Hit
                end
                if Mode == 'Silent' then
                    if not snoozestuff.Locals.SilentAimTarget then return Vector3.new(0, 0 ,0) end
                    if not snoozestuff.Locals.SilentAimTarget.Character then return Vector3.new(0, 0 ,0) end
                    local Config = shared["snoozesaved"].SilentAim
                    local NearestPart = GetClosestPartToCursor(snoozestuff.Locals.SilentAimTarget.Character)
                    local NearestPoint 
                    local Humanoid = snoozestuff.Locals.SilentAimTarget.Character:FindFirstChild("Humanoid")
                    if Config.Type == 'Advanced' then
                        NearestPoint = GetClosestPointOnPart(NearestPart, Config.Scale)
                    else
                        NearestPoint = GetClosestPointOnPartBasic(NearestPart)
                    end
        
                    local TargetPosition
                    if Config.Point == "Nearest Part" then
                        TargetPosition = NearestPart.Position
                    elseif Config.Point == "Nearest Point" then
                        TargetPosition = NearestPoint
                    else
                        TargetPosition = GetClosestPartToCursorFilter(snoozestuff.Locals.SilentAimTarget.Character,Config.Parts).Position
                    end
        
                    if Config.Prediction.Enabled then
                        local RootPart = snoozestuff.Locals.SilentAimTarget.Character.HumanoidRootPart
                        local Velocity = IsDesynced(RootPart) and Resolve(RootPart) or RootPart.Velocity
                        
                        if Config.Prediction.Automated and Humanoid then
                            if Humanoid.FloorMaterial == Enum.Material.Air and Velocity_Data.State == Enum.HumanoidStateType.Jumping then
                                snoozestuff.Locals.HitPosition = TargetPosition + Velocity * Vector3.new(Config.Prediction.Ground, Velocity_Data.Y, Config.Prediction.Ground)
                            elseif Humanoid.FloorMaterial == Enum.Material.Air then
                                if Config.Prediction.YStabilize.Enabled then
                                    snoozestuff.Locals.HitPosition = TargetPosition + Velocity * Vector3.new(Config.Prediction.Ground, Config.Prediction.Air / Config.Prediction.YStabilize.Value, Config.Prediction.Ground)
                                else
                                    snoozestuff.Locals.HitPosition = TargetPosition + Velocity * Vector3.new(Config.Prediction.Ground, Config.Prediction.Air, Config.Prediction.Ground)
                                end
                            else
                                snoozestuff.Locals.HitPosition = TargetPosition + Velocity * Vector3.new(Config.Prediction.Ground, Config.Prediction.Air, Config.Prediction.Ground)
                            end
                        
                        else
                            local PredictionVector = Vector3.new(shared["snoozesaved"].SilentAim.Prediction.Ground, shared["snoozesaved"].SilentAim.Prediction.Air, shared["snoozesaved"].SilentAim.Prediction.Ground)
                        
                            snoozestuff.Locals.HitPosition = TargetPosition + Velocity * PredictionVector
                        end
                    else
                        snoozestuff.Locals.HitPosition = TargetPosition
                    end
                end
            end
    
            return {
                GetClosestPlayerToCursor = GetClosestPlayerToCursor,
                GetClosestPartToCursorFilter = GetClosestPartToCursorFilter,
                SelfMods = SelfMods,
                GetOrigin = GetOrigin,
                IsKnocked = IsKnocked,
                IsGrabbed = IsGrabbed,
                ValidateClient = ValidateClient,
                GetClosestPointOnPart = GetClosestPointOnPart,
                GetClosestPointOnPartBasic = GetClosestPointOnPartBasic,
                GetClosestPartToCursor = GetClosestPartToCursor,
                GetHitPosition = GetHitPosition,
                AutomatedPrediction = AutomatedPrediction
    
            }
        end
        --
        function Modules.DaHood()
            if CurrentGame.Name == "Da Hood" then
                local IsClient = RunService:IsClient()
                local PlaceIDCheck = game.PlaceId == 88976059384565
        
                local function CanShoot(Character)
                    if Character then
                        local Humanoid = Character:FindFirstChild("Humanoid")
                        if Humanoid and (Humanoid.Health > 0 and Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) then
                            local BodyEffects = Character:FindFirstChild("BodyEffects")
                            if BodyEffects then
                                local Tool = Character:FindFirstChildWhichIsA("Tool")
                                if Tool and (Tool:FindFirstChild("Handle") and Tool:FindFirstChild("Ammo")) then
                                    if not PlaceIDCheck and IsClient then
                                        if BodyEffects:FindFirstChild("Block") then
                                            shared.playerShot(Tool.Handle)
                                            Tool.Handle.NoAmmo:Play()
                                            return
                                        end
                                        if Tool.Ammo.Value == 0 then
                                            Tool.Handle.NoAmmo:Play()
                                            return
                                        end
                                    end
                                    if Character:FindFirstChild("FULLY_LOADED_CHAR") == nil then
                                        return
                                    elseif Character:FindFirstChild("FORCEFIELD") then
                                        return
                                    elseif Character:FindFirstChild("GRABBING_CONSTRAINT") then
                                        return
                                    elseif Character:FindFirstChild("Christmas_Sock") then
                                        return
                                    elseif BodyEffects.Cuff.Value == true then
                                        return
                                    elseif BodyEffects.Attacking.Value == true then
                                        return
                                    elseif BodyEffects["K.O"].Value == true then
                                        return
                                    elseif BodyEffects.Grabbed.Value then
                                        return
                                    elseif BodyEffects.Reload.Value == true then
                                        return
                                    elseif BodyEffects.Dead.Value == true then
                                        return
                                    elseif not Tool:GetAttribute("Cooldown") then
                                        local LastShot = Character:GetAttribute("LastGunShot")
                                        Character:SetAttribute("LastGunShot", Tool.Name)
                                        if not IsClient or (LastShot == Tool.Name or not Character:GetAttribute("ShotgunDebounce")) then
                                            if not IsClient and (not Character:GetAttribute("ShotgunDebounce") and (Tool.Name == "[Shotgun]" or (Tool.Name == "[Double-Barrel SG]" or (Tool.Name == "TacticalShotgun" or Tool.Name == "Drum-Shotgun")))) then
                                                
                                                Character:SetAttribute("ShotgunDebounce", true)
                                                task.delay(0.65, function()
                                                    Character:SetAttribute("ShotgunDebounce", nil)
                                                end)
                                                
                                                --Character:SetAttribute("ShotgunDebounce", nil)
                                            end
                                            return true
                                        end
                                    end
                                else
                                    return
                                end
                            else
                                return
                            end
                        else
                            return
                        end
                    else
                        return
                    end
                end
        
        
                local function ColorTransform(p14, p15)
                    if p15 == 0 then
                        return p14.Keypoints[1].Value
                    end
                    if p15 == 1 then
                        return p14.Keypoints[#p14.Keypoints].Value
                    end
                    for v16 = 1, #p14.Keypoints - 1 do
                        local v17 = p14.Keypoints[v16]
                        local v18 = p14.Keypoints[v16 + 1]
                        if v17.Time <= p15 and p15 < v18.Time then
                            local v19 = (p15 - v17.Time) / (v18.Time - v17.Time)
                            return Color3.new((v18.Value.R - v17.Value.R) * v19 + v17.Value.R, (v18.Value.G - v17.Value.G) * v19 + v17.Value.G, (v18.Value.B - v17.Value.B) * v19 + v17.Value.B)
                        end
                    end
                end
        
                local weaponNames = {
                    "[Shotgun]",
                    "[Drum-Shotgun]",
                    "[Rifle]",
                    "[TacticalShotgun]",
                    "[AR]",
                    "[AUG]",
                    "[AK47]",
                    "[LMG]",
                    "[SilencerAR]",
                }
                
                local replicatedStorage = game:GetService("ReplicatedStorage")
                local playersService = game:GetService("Players")
                local localPlayer = playersService.LocalPlayer
                local playerCharacter = Self.Character or Self.CharacterAdded:Wait()
                local shootAnimation = playerCharacter.Humanoid.Animator:LoadAnimation(
                    replicatedStorage:WaitForChild("Animations"):WaitForChild("GunCombat"):WaitForChild("Shoot")
                )
                local aimShootAnimation = playerCharacter.Humanoid.Animator:LoadAnimation(
                    replicatedStorage:WaitForChild("Animations"):WaitForChild("GunCombat"):WaitForChild("AimShoot")
                )
                
                local v_u_14 = {}
        
                local function changefunc()
                    local v_u_38 = {
                        ["functions"] = {},
                    }
        
                    function v_u_38.connect(_, p36)
                        local v37 = v_u_38.functions
                        table.insert(v37, p36)
                    end
                    local v_u_39 = nil
                    function v_u_38.updatechanges(_, p_u_40)
                        -- upvalues: (copy) v_u_38, (ref) v_u_39
                        for _, v_u_41 in pairs(v_u_38.functions) do
                            spawn(function()
                                -- upvalues: (copy) v_u_41, (copy) p_u_40, (ref) v_u_39
                                v_u_41(p_u_40.Press, p_u_40.Time, v_u_39)
                            end)
                        end
                        v_u_39 = p_u_40.Time
                    end
                    return v_u_38
                end
        
        
                setmetatable(v_u_14, {
                    ["__index"] = function(_, p42)
                        -- upvalues: (copy) v_u_14
                        local v43 = v_u_14
                        if getmetatable(v43)[p42] == nil then
                            v_u_14[p42] = {}
                        end
                        local v44 = v_u_14
                        return getmetatable(v44)[p42]
                    end,
                    ["__newindex"] = function(_, p45, p46)
                        -- upvalues: (copy) v_u_14
                        local v47 = v_u_14
                        if getmetatable(v47)[p45] == nil then
                            local v48 = v_u_14
                            getmetatable(v48)[p45] = {
                                ["val"] = p46,
                                ["changed"] = changefunc()
                            }
                        else
                            local v49 = v_u_14
                            getmetatable(v49)[p45].val = p46
                            local v50 = v_u_14
                            getmetatable(v50)[p45].changed:updatechanges(p46)
                        end
                    end
                })
        
                UserInputService.InputBegan:connect(function(p51, p52)
                    if not p52 or p51.UserInputType == Enum.UserInputType.Keyboard and p51.KeyCode == Enum.KeyCode.LeftShift or p51.UserInputType == Enum.UserInputType.Gamepad1 and p51.KeyCode == Enum.KeyCode.ButtonL2 then
                        if p51.UserInputType == Enum.UserInputType.Keyboard or p51.UserInputType == Enum.UserInputType.Gamepad1 then
                            v_u_14[p51.KeyCode.Name] = {
                                ["Press"] = true,
                                ["Time"] = tick()
                            }
                            return
                        end
                        if p51.UserInputType == Enum.UserInputType.MouseButton2 then
                            v_u_14[Enum.UserInputType.MouseButton2.Name] = {
                                ["Press"] = true,
                                ["Time"] = tick()
                            }
                        end
                    end
                end)
                UserInputService.InputEnded:connect(function(p53, p54)
                    if not p54 or p53.UserInputType == Enum.UserInputType.Keyboard and p53.KeyCode == Enum.KeyCode.LeftShift or p53.UserInputType == Enum.UserInputType.Gamepad1 and p53.KeyCode == Enum.KeyCode.ButtonL2 then
                        if p53.UserInputType == Enum.UserInputType.Keyboard or p53.UserInputType == Enum.UserInputType.Gamepad1 then
                            v_u_14[p53.KeyCode.Name] = {
                                ["Press"] = false,
                                ["Time"] = tick()
                            }
                            return
                        end
                        if p53.UserInputType == Enum.UserInputType.MouseButton2 then
                            v_u_14[Enum.UserInputType.MouseButton2.Name] = {
                                ["Press"] = false,
                                ["Time"] = tick()
                            }
                        end
                    end
                end)
        
        
        
                local v_u_70 = true
                v_u_14.MouseButton2.changed:connect(function(p71, _, _)
                    -- upvalues: (ref) v_u_70, (ref) v_u_20
                    if v_u_70 ~= false then
                        snoozestuff.Locals.IsAimed = p71
                        if snoozestuff.Locals.IsAimed == false then
                            v_u_70 = false
                            wait(0.1)
                            v_u_70 = true
                        end
                    end
                end)
        
                local function Animate(target)
                    playerCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                
                    if playerCharacter and playerCharacter:FindFirstChild("Humanoid") and playerCharacter.Humanoid:FindFirstChild("Animator") then
                        shootAnimation = playerCharacter.Humanoid.Animator:LoadAnimation(replicatedStorage.Animations.GunCombat.Shoot)
                        aimShootAnimation = playerCharacter.Humanoid.Animator:LoadAnimation(replicatedStorage.Animations.GunCombat.AimShoot)
                
                        if snoozestuff.Locals.IsAimed or table.find(weaponNames, target.Parent.Name) then
                            aimShootAnimation:Play()
                        else
                            shootAnimation:Play()
                        end
                    end
                end
                
        
            
                shared.playerShot = Animate
                local v3 = game:GetService("Players")
                local v_u_5 = game:GetService("TweenService")
                local v_u_7 = v3.LocalPlayer
                local v_u_9 = ReplicatedStorage.SkinAssets
                local v_u_13 = workspace:GetServerTimeNow()
                local _ = game.PlaceId == 88976059384565
                local SoundsPlaying = {}
        
                
                local function GetAim(Position)
            
                    if _G.MobileShiftLock then
                        return (Camera.CFrame.p + Camera.CFrame.LookVector * 60 - Position).unit
                    end
                    local v24
                    if Mouse.Target then
                        v24 = Mouse.Hit.p
                    else
                        local v25 = Camera.CFrame
                        local v26 = v25.p + v25.LookVector * 60
                        local v27 = v25.LookVector
                        local v28 = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
                        local v29 = v28.Direction
                        local v30 = v28.Origin
                        v24 = v30 + v29 * ((v26 - v30):Dot(v27) / v29:Dot(v27))
                    end
                    return (v24 - Position).Unit, (v24 - Position).Magnitude
                end
                
                local function ShootGun(p34)
                
                    local v35 = p34.Shooter
                    local v_u_36 = p34.Handle
                    local v37 = p34.AimPosition
                    local v38 = p34.BeamColor
                    local v39 = p34.isReflecting
                    local v40 = p34.Hit
                    local v41 = p34.Range or 200
                    local LegitPosition = p34.LegitPosition
                    local v_u_42
                    if v_u_36 then
                        v_u_42 = v_u_36:GetAttribute("SkinName")
                    else
                        v_u_42 = v_u_36
                    end
                    local _, v43 = GetAim(v_u_36.Position)
                    local v_u_44 = p34.ForcedOrigin or v_u_36.Muzzle.WorldPosition
                    local v45 = (v37 - v_u_44).Unit
                    local v46 = RaycastParams.new()
                    local v47 = {}
                    local function set_list(targetTable, index, values)
                        for i, v in ipairs(values) do
                            targetTable[index + i - 1] = v
                        end
                    end
                    
                    local v48 = { workspace:WaitForChild("Bush"), workspace:WaitForChild("Ignored") }
                    set_list(v47, 1, {v35, unpack(v48)})
                    
                    v46.FilterDescendantsInstances = v47
                    v46.FilterType = Enum.RaycastFilterType.Exclude
                    v46.IgnoreWater = true
                    local v_u_49, v_u_50, v_u_51
                    if v40 then
                        v_u_49 = p34.Hit
                        v_u_50 = p34.AimPosition
                        v_u_51 = p34.Normal
                    else
                        local v52 = workspace:Raycast(v_u_44, v45 * v41, v46)
                        if v52 then
                            v_u_49 = v52.Instance
                            v_u_50 = v52.Position
                            v_u_51 = v52.Normal
                        else
                            v_u_50 = v_u_44 + v45 * math.min(v43, v41)
                            v_u_51 = nil
                            v_u_49 = nil
                        end
                    end
                    
                    
                    local v_u_53 = Instance.new("Part")
                    v_u_53:SetAttribute("OwnerCharacter", v35.Name)
                    v_u_53.Name = "BULLET_RAYS"
                    v_u_53.Anchored = true
                    v_u_53.CanCollide = false
                    v_u_53.Size = Vector3.new(0, 0, 0)
                    v_u_53.Transparency = 1
                    game.Debris:AddItem(v_u_53, 1)
                    if shared["snoozesaved"].Modifications['Client Redirection'].Enabled then
                        v_u_53.CFrame = CFrame.new(v_u_44, LegitPosition)
                    else
                        v_u_53.CFrame = CFrame.new(v_u_44, v_u_50)
                    end
                    v_u_53.Material = Enum.Material.SmoothPlastic
                    v_u_53.Parent = workspace.Ignored.Siren.Radius
                    local v54 = Instance.new("Attachment")
                    v54.Position = Vector3.new(0, 0, 0)
                    v54.Parent = v_u_53
                    local v55 = Instance.new("Attachment")
                    local v56 = -(v_u_50 - v_u_44).magnitude
                    v55.Position = Vector3.new(0, 0, v56)
                    v55.Parent = v_u_53
                    local v_u_57 = false
                    local v_u_58 = nil
                    local v59
                    if v_u_36 then
                        local v60 = v_u_36.Parent.Name
                        if v_u_42 and v_u_42 ~= "" then
                            if v_u_9.GunSkinMuzzleParticle:FindFirstChild(v_u_42) then
                                if not v39 then
                                    if v_u_9.GunSkinMuzzleParticle[v_u_42]:FindFirstChild("Muzzle") then
                                        if v_u_36.Parent:FindFirstChild("Default") and (v_u_36.Parent.Default:FindFirstChild("Mesh") and v_u_36.Parent.Default.Mesh:FindFirstChild("Muzzle")) then
                                            local v61
                                            if v_u_9.GunSkinMuzzleParticle[v_u_42].Muzzle:FindFirstChild("Different_GunMuzzle") then
                                                v61 = v_u_9.GunSkinMuzzleParticle[v_u_42].Muzzle.Different_GunMuzzle[v60]
                                            else
                                                v61 = v_u_9.GunSkinMuzzleParticle[v_u_42].Muzzle
                                            end
                                            for _, v62 in pairs(v61:GetChildren()) do
                                                local v63 = v62:GetAttribute("EmitCount") or 1
                                                local v_u_64 = v62:Clone()
                                                v_u_64.Parent = v_u_36.Parent.Default.Mesh.Muzzle
                                                v_u_64:Emit(v63)
                                                task.delay(v_u_64.Lifetime.Max, function()
                                                    -- upvalues: (copy) v_u_64
                                                    v_u_64:Destroy()
                                                end)
                                            end
                                        end
                                    else
                                        local v65 = v_u_9.GunSkinMuzzleParticle[v_u_42]:GetChildren()
                                        local v66 = v65[math.random(#v65)]:Clone()
                                        v66.Parent = v54
                                        v66:Emit(v66.Rate)
                                    end
                                end
                                v_u_57 = true
                            end
                            if v_u_9.GunBeam:FindFirstChild(v_u_42) then
                                if v_u_9.GunBeam[v_u_42].GunBeam:IsA("BasePart") then
                                    v59 = {
                                        ["Parent"] = nil,
                                        ["Attachment0"] = nil,
                                        ["Attachment1"] = nil
                                    }
                                    if v_u_9.GunBeam[v_u_42].GunBeam:FindFirstChild("Different_GunBeam") then
                                        if v_u_9.GunBeam[v_u_42].GunBeam.Different_GunBeam[v60].GunBeam:IsA("BasePart") then
                                            v_u_58 = v_u_9.GunBeam[v_u_42].GunBeam.Different_GunBeam[v60].GunBeam:Clone()
                                        else
                                            v59 = v_u_9.GunBeam[v_u_42].GunBeam.Different_GunBeam[v60].GunBeam:Clone()
                                        end
                                    else
                                        v_u_58 = v_u_9.GunBeam[v_u_42].GunBeam:Clone()
                                    end
                                else
                                    v59 = v_u_9.GunBeam[v_u_42].GunBeam:Clone()
                                end
                            else
                                v59 = game.ReplicatedStorage.GunBeam:Clone()
                                v59.Color = v38 and ColorSequence.new(v38) or v59.Color
                            end
                        else
                            v59 = game.ReplicatedStorage.GunBeam:Clone()
                            v59.Color = v38 and ColorSequence.new(v38) or v59.Color
                        end
                    else
                        v59 = nil
                    end
                    task.spawn(function()
                        -- upvalues: (ref) v_u_58, (ref) v_u_50, (copy) v_u_44, (ref) v_u_21, (ref) v_u_49, (ref) v_u_51, (copy) v_u_42, (ref) v_u_9, (copy) v_u_53, (copy) v_u_36, (ref) v_u_57, (ref) v_u_5
                        if v_u_58 then
                            local v67 = (v_u_50 - v_u_44).magnitude
                            local v68 = v67 / 725
                            v_u_58.Anchored = true
                            v_u_58.CanCollide = false
                            v_u_58.CanQuery = false
                            v_u_58.CFrame = CFrame.new(v_u_44, v_u_50)
                            local v69 = v_u_58.CFrame * CFrame.new(0, 0, -v67)
                            v_u_58.Parent = workspace.Ignored.Siren.Radius
                            task.delay(v68 + 5, function()
                                -- upvalues: (ref) v_u_58
                                v_u_58:Destroy()
                                v_u_58 = nil
                            end)
                            if v_u_58:GetAttribute("SpecialEffects") then
                                for _, v70 in pairs(v_u_58:GetDescendants()) do
                                    if v70:IsA("Trail") and v70:GetAttribute("ColorRandom") then
                                        local v71 = v70:GetAttribute("ColorRandom")
                                        v70.Color = ColorSequence.new(ColorTransform(v71, math.random()))
                                    end
                                end
                            end
                            local v72 = game:GetService("TweenService"):Create(v_u_58, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {
                                ["CFrame"] = v_u_58.CFrame * CFrame.new(0, 0, -0.1)
                            })
                            v72:Play()
                            task.wait(0.05)
                            if v72.PlaybackState ~= Enum.PlaybackState.Completed then
                                v72:Pause()
                            end
                            local v73 = nil
                            if _G.Reduce_Lag and not v_u_58:GetAttribute("NoSlow") or v_u_58:GetAttribute("LOWGFX") then
                                v_u_58.CFrame = v69
                            else
                                v73 = game:GetService("TweenService"):Create(v_u_58, TweenInfo.new(v68, Enum.EasingStyle.Linear), {
                                    ["CFrame"] = v69
                                })
                                v73:Play()
                                task.wait(v68)
                            end
                            if v_u_58:FindFirstChild("Impact") and (v_u_49 and (v_u_51 and not v_u_49.Parent:FindFirstChild("Humanoid"))) then
                                if v73 and v73.PlaybackState ~= Enum.PlaybackState.Completed then
                                    task.wait(0.05)
                                end
                                if not v_u_58:FindFirstChild("NoNormal") then
                                    v_u_58.CFrame = CFrame.new(v_u_50, v_u_50 - v_u_51)
                                end
                                for _, v74 in pairs(v_u_58.Impact:GetChildren()) do
                                    if v74:IsA("ParticleEmitter") then
                                        v74:Emit(v74:GetAttribute("EmitCount") or 1)
                                    end
                                end
                            else
                                for _, v75 in pairs(v_u_58:GetChildren()) do
                                    if v75:IsA("BasePart") then
                                        v75.Transparency = 1
                                    end
                                end
                            end
                            if v_u_58 then
                                for _, v76 in pairs(v_u_58:GetDescendants()) do
                                    if v76:IsA("ParticleEmitter") then
                                        v76.Enabled = false
                                    end
                                end
                            end
                        elseif v_u_49 and (v_u_49:IsDescendantOf(workspace.MAP) and (v_u_42 and (v_u_9.GunBeam:FindFirstChild(v_u_42) and v_u_9.GunBeam[v_u_42]:FindFirstChild("Impact")))) then
                            local v_u_77 = v_u_9.GunBeam[v_u_42].Impact:Clone()
                            v_u_77.Parent = workspace.Ignored
                            v_u_77:PivotTo(CFrame.new(v_u_50, v_u_50 + v_u_51 * 5) * CFrame.Angles(-1.5707963267948966, 0, 0))
                            for _, v78 in pairs(v_u_77:GetDescendants()) do
                                if v78:IsA("ParticleEmitter") then
                                    v78:Emit(v78:GetAttribute("EmitCount") or 1)
                                end
                            end
                            task.delay(1.5, function()
                                -- upvalues: (ref) v_u_77
                                v_u_77:Destroy()
                                v_u_77 = nil
                            end)
                        end
                        local v79 = Instance.new("PointLight")
                        v79.Brightness = 0.5
                        v79.Range = 15
                        v79.Shadows = true
                        v79.Color = Color3.new(1, 1, 1)
                        v79.Parent = v_u_53
                        local v80 = v_u_36:FindFirstChild("ShootBBGUI")
                        local v81 = v80 and (not v_u_57 and v80:FindFirstChild("Shoot"))
                        if v81 then
                            v81.Size = UDim2.new(0, 0, 0, 0)
                            v81.ImageTransparency = 1
                            v81.Visible = true
                            v_u_5:Create(v81, TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.In, 0, false, 0), {
                                ["Size"] = UDim2.new(1, 0, 1, 0),
                                ["ImageTransparency"] = 0.4
                            }):Play()
                            v_u_5:Create(v79, TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.In, 0, false, 0), {
                                ["Range"] = 0
                            }):Play()
                            wait(0.4)
                            v_u_53:Destroy()
                            v_u_5:Create(v81, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.In, 0, false, 0), {
                                ["Size"] = UDim2.new(1, 0, 1, 0),
                                ["ImageTransparency"] = 1
                            }):Play()
                            wait(0.2)
                            v81.Visible = false
                        end
                    end)
                    v59.Attachment0 = v54
                    v59.Attachment1 = v55
                    v59.Name = "NewGunBeam"
                    v59.Parent = v_u_53
                    if v35 == v_u_7.Character and workspace:GetServerTimeNow() - v_u_13 > 0.95 then
                        Animate(v_u_36)
                    end
        
                    local playsound = function(p1, p2)
                        local v3 = p1.ShootSound:GetAttribute("SequenceSFX")
                        if v3 then
                            if p1.ShootSound:GetAttribute("CurrentSequence") == nil then
                                p1.ShootSound:SetAttribute("CurrentSequence", 1)
                            else
                                p1.ShootSound:SetAttribute("CurrentSequence", p1.ShootSound:GetAttribute("CurrentSequence") + 1)
                            end
                            local v4 = p1.ShootSound:GetAttribute("CurrentSequence")
                            local v5 = {}
                            for v6 in string.gmatch(v3, "%d+") do
                                table.insert(v5, v6)
                            end
                            p1.ShootSound.SoundId = "rbxassetid://" .. v5[v4 % #v5 + 1]
                        end
                        if p2 then
                            local v_u_7 = p1.ShootSound:Clone()
                            v_u_7.Name = "MG"
                            v_u_7.Parent = p1
                            v_u_7:Play()
                            delay(1, function()
                                -- upvalues: (copy) v_u_7
                                v_u_7:Destroy()
                            end)
                        else
                            p1.ShootSound:Play()
                        end
                    end    
        
                    if not SoundsPlaying[v_u_36] then
                        task.spawn(playsound, v_u_36, true)
                        SoundsPlaying[v_u_36] = true
                        task.delay(0.021, function()
                            -- upvalues: (ref) SoundsPlaying, (copy) v_u_36
                            SoundsPlaying[v_u_36] = nil
                        end)
                    end
                    if game.Lighting:GetAttribute("printhits") then
                        local v82 = print
                        local v83 = v_u_49
                        if v83 then
                            v83 = v_u_49:GetFullName()
                        end
                        v82(v83)
                    end
        
            
                    return v_u_50, v_u_49, v_u_51
                end
        
                
        
                return {
                    CanShoot = CanShoot,
                    Animate = Animate,
                    GetAim = GetAim,
                    ColorTransform = ColorTransform,
                    ShootGun = ShootGun,
                }
            else
                return {}
            end
        end
        --
        function Modules.Main()
            local Engine = Modules.Get("Engine")
            local Player = Modules.Get("Player")
            local DaHood = Modules.Get("DaHood")
            local Current_t = 0
        
            local function GetGunCategory()
                if Self and Self.Character then
                    local Tool = Self.Character:FindFirstChildWhichIsA("Tool")
                    if Tool then
                        if table.find(WeaponInfo.Weapons.Shotguns, Tool.Name) then
                            return "Shotgun"
                        end
            
                        if table.find(WeaponInfo.Weapons.Pistols, Tool.Name) then
                            return "Pistol"
                        end
    
                        if table.find(WeaponInfo.Weapons.Rifles, Tool.Name) then
                            return "Rifle"
                        end
    
                        if table.find(WeaponInfo.Weapons.Bursts, Tool.Name) then
                            return "Burst"
                        end
    
                        if table.find(WeaponInfo.Weapons.SMG, Tool.Name) then
                            return "SMG"
                        end
    
                        if table.find(WeaponInfo.Weapons.Snipers, Tool.Name) then
                            return "Sniper"
                        end
    
                        if table.find(WeaponInfo.Weapons.AutoShotguns, Tool.Name) then
                            return "Auto"
                        end
                    end
                end
                return nil
            end
    

            local function UpdateBox()
                if snoozestuff.Locals.SilentAimTarget and snoozestuff.Locals.SilentAimTarget.Character then
                    local Object, Humanoid, RootPart = Player.ValidateClient(snoozestuff.Locals.SilentAimTarget)
                    if (Object and Humanoid and RootPart) then		
                        local Pos
                        if shared["snoozesaved"].Fields.SilentAimBoxField.Sync then
                            Pos = snoozestuff.Locals.HitPosition
                        else
                            Pos = RootPart.Position
                        end
                        local Position, Visible = Camera:WorldToViewportPoint(Pos)
                        local Size = RootPart.Size.Y
                        local scaleFactor = (Size * Camera.ViewportSize.Y) / (Position.Z * 2) * 80 / workspace.CurrentCamera.FieldOfView
                        local w, h = shared["snoozesaved"].Fields.SilentAimBoxField.Width * scaleFactor, shared["snoozesaved"].Fields.SilentAimBoxField.Height * scaleFactor
                        
                        snoozestuff.Visuals.BoxFOV.Position = Vector2.new(Position.X - w / 2, Position.Y - h / 2)
                        snoozestuff.Visuals.BoxFOV.Size = Vector2.new(w, h)
                        snoozestuff.Visuals.BoxFOV.Visible = shared["snoozesaved"].Fields.SilentAimBoxField.Visible and Visible

                        local mouseLocation = UserInputService:GetMouseLocation()
                        local boxPos = snoozestuff.Visuals.BoxFOV.Position
                        local boxSize = snoozestuff.Visuals.BoxFOV.Size
                    
                        if mouseLocation.X >= boxPos.X and mouseLocation.X <= boxPos.X + boxSize.X and
                            mouseLocation.Y >= boxPos.Y and mouseLocation.Y <= boxPos.Y + boxSize.Y then
                            snoozestuff.Locals.IsBoxFocused = true
                            snoozestuff.Visuals.BoxFOV.Color = Color3.fromRGB(0, 255, 0)
                            else
                            snoozestuff.Locals.IsBoxFocused = false
                            snoozestuff.Visuals.BoxFOV.Color =Color3.fromRGB(255, 255, 255)
                        end
                    else
                        snoozestuff.Visuals.BoxFOV.Visible = false
                    end
                else
                    snoozestuff.Visuals.BoxFOV.Visible = false
                end
            end
    
            local Ticks = {}
            local SGTick = tick()
            local function SilentAim(Tool)
                if shared["snoozesaved"].SilentAim.Enabled and Tool:FindFirstChild("Ammo") then
                    if CurrentGame.Name == "Da Hood" then
                        if not Ticks[Tool.Name] then
                            Ticks[Tool.Name] = 0
                        end
                        local WeaponOffset = WeaponInfo.Offsets[Tool.Name]
                        local Gun = GetGunCategory()
                        local Check 
                        local ToolHandle = Tool:WaitForChild("Handle")
                        local LocalCharacter = Self.Character or Self.CharacterAdded:Wait()
                        local Cooldown
                        local NoClueWhatThisIs = game.PlaceId == 88976059384565 and {
                            ["Value"] = 5
                        } or Tool.Ammo
                        local Time = workspace:GetServerTimeNow()
                
                        local ToolEvent = Tool:WaitForChild("RemoteEvent", 2) or {
                            ["FireServer"] = function(_, _) end
                        }
        
        
                        local DoubleTap
                        if shared["snoozesaved"].Modifications['Double Tap'].Enabled and table.find(shared["snoozesaved"].Modifications['Double Tap'].Weapon, Tool.Name) then
                            if snoozestuff.Locals.IsDoubleTapping then
                                DoubleTap = true
                            else
                                DoubleTap = false
                            end
                        else
                            DoubleTap = false
                        end
        
                        if shared["snoozesaved"].Modifications['Cooldown Reduction'].Enabled then
                            if shared["snoozesaved"].Modifications['Cooldown Reduction'].Weapon[Tool.Name] and not snoozestuff.Locals.IsTriggerBotting then
                                Cooldown = shared["snoozesaved"].Modifications['Cooldown Reduction'].Weapon[Tool.Name]
                            else
                                Cooldown = Tool:WaitForChild("ShootingCooldown").Value
                            end
                        else
                            Cooldown = Tool:WaitForChild("ShootingCooldown").Value
                        end
        
                        if shared["snoozesaved"].Modifications['Delay Reduction'].Enabled then
                            if shared["snoozesaved"].Modifications['Delay Reduction'].Weapon[Tool.Name] and not snoozestuff.Locals.IsTriggerBotting then
                                WeaponInfo.Delays[Tool.Name] = shared["snoozesaved"].Modifications['Delay Reduction'].Weapon[Tool.Name]
                            end
                        
                            Check = tick() - Ticks[Tool.Name] >= Cooldown + WeaponInfo.Delays[Tool.Name]
                        else
                            Check = tick() - Ticks[Tool.Name] >= Cooldown + WeaponInfo.Delays[Tool.Name]
                        end
                        
        
        
                        local BeamCol 
                        if (shared["snoozesaved"].Modifications['Beam Color'].Enabled) then
                            BeamCol = shared["snoozesaved"].Modifications['Beam Color'].Color
                        else
                            BeamCol = Color3.new(1, 0.545098, 0.14902)
                        end
        
                        local function ShootFunc(GunType, SilentAim)
                            if GunType == "Shotgun" then
                                if Check and (NoClueWhatThisIs.Value >= 1 and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(Self.Character))) then
                                    Ticks[Tool.Name] = tick()
                                    ToolEvent:FireServer("Shoot")
                                    for _ = 1, 5 do
                                        local HitPosition = snoozestuff.Locals.HitPosition 
                                        local SpreadX 
                                        local SpreadY
                                        local SpreadZ
                    
                                        if shared["snoozesaved"].Modifications["Spread Reduction"].Enabled then
                                            local toolName = Tool.Name
                                            local spreadPercentage = shared["snoozesaved"].Modifications["Spread Reduction"].Weapon[toolName]
                                            local randomizer = shared["snoozesaved"].Modifications["Spread Reduction"].Randomizer
                                        
                                            if randomizer.Enabled then
                                                local spreadFactor = 1 - math.random() * randomizer.Value
                                                SpreadX = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                                SpreadY = math.random() > 0.5 and math.random() * 0.1 * spreadFactor or -math.random() * 0.1 * spreadFactor
                                                SpreadZ = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                            else
                                                if not spreadPercentage then
                                                    SpreadX = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                                    SpreadY = math.random() > 0.5 and math.random() * 0.1 or -math.random() * 0.1
                                                    SpreadZ = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                                else
                                                    local spreadFactor = 1 - spreadPercentage
                                                    SpreadX = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                                    SpreadY = math.random() > 0.5 and math.random() * 0.1 * spreadFactor or -math.random() * 0.1 * spreadFactor
                                                    SpreadZ = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                                end
                                            end
                                        else
                                            SpreadX = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                            SpreadY = math.random() > 0.5 and math.random() * 0.1 or -math.random() * 0.1
                                            SpreadZ = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                        end
                        
                                        local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or {
                                            ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position
                                        }
                        
                                        local TotalSpread = Vector3.new(SpreadX, SpreadY, SpreadZ)
                            
                                        local AimPosition
                                        local WeaponRange = Tool:FindFirstChild("Range")
                                        if SilentAim and (Self.Character.HumanoidRootPart.Position - snoozestuff.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < WeaponRange.Value then
                                            AimPosition = ForcedOrigin.WorldPosition + ((HitPosition - ForcedOrigin.WorldPosition).Unit + TotalSpread) * WeaponRange.Value
                                        else
                                            AimPosition = ForcedOrigin.WorldPosition + (DaHood.GetAim(ForcedOrigin.WorldPosition) + TotalSpread) * WeaponRange.Value
                                        end
        
                                        local Arg0, Arg1, Arg2 = DaHood.ShootGun({
                                            ["Shooter"] = LocalCharacter,
                                            ["Handle"] = ToolHandle,
                                            ["AimPosition"] = AimPosition,
                                            ["BeamColor"] = BeamCol,
                                            ["ForcedOrigin"] = ForcedOrigin.WorldPosition,
                                            ["LegitPosition"] = ForcedOrigin.WorldPosition + (DaHood.GetAim(ForcedOrigin.WorldPosition) + TotalSpread) * WeaponRange.Value,
                                            ["Range"] = WeaponRange.Value
                                        })
                                        ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, Arg0, Arg1, Arg2, Time)
                                    end
                                    ToolEvent:FireServer()
                                end
                            elseif Gun == "Pistol" then
                                if Check and (NoClueWhatThisIs.Value >= 1 and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(Self.Character))) then
                                    Ticks[Tool.Name] = tick()
                                    local HitPosition = snoozestuff.Locals.HitPosition 
                                    if DoubleTap then
                                        ToolEvent:FireServer("Shoot")
                                        snoozestuff.Locals.DoubleTapState = true
                                        local AimPosition
                                        local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or {
                                            ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position
                                        }
                        
                                        local WeaponRange = Tool:WaitForChild("Range")
                                        if SilentAim and (Self.Character.HumanoidRootPart.Position - snoozestuff.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < WeaponRange.Value then
                                            AimPosition = HitPosition
                                        else
                                            AimPosition = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200  
                                        end
                                        local Arg0, Arg1, Arg2 = DaHood.ShootGun({
                                            ["Shooter"] = LocalCharacter,
                                            ["Handle"] = ToolHandle,
                                            ["ForcedOrigin"] = ForcedOrigin.WorldPosition or (ToolHandle.CFrame * WeaponOffset).Position,
                                            ["AimPosition"] = AimPosition,
                                            ["BeamColor"] = BeamCol,
                                            ["LegitPosition"] = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200,
                                            ["Range"] = WeaponRange.Value
                                        })
                                        ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, Arg0, Arg1, Arg2)
                                        ToolEvent:FireServer()
                                        snoozestuff.Locals.DoubleTapState = false
                                    end
                                    ToolEvent:FireServer("Shoot")
        
                                    local AimPosition
                                    local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or {
                                        ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position
                                    }
                    
                                    local WeaponRange = Tool:WaitForChild("Range")
                                    if SilentAim and (Self.Character.HumanoidRootPart.Position - snoozestuff.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < WeaponRange.Value then
                                        AimPosition = HitPosition
                                    else
                                        AimPosition = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200  
                                    end
                                    local WeaponRange = Tool:WaitForChild("Range")
                                    local Arg0, Arg1, Arg2 = DaHood.ShootGun({
                                        ["Shooter"] = LocalCharacter,
                                        ["Handle"] = ToolHandle,
                                        ["ForcedOrigin"] = ForcedOrigin.WorldPosition or (ToolHandle.CFrame * WeaponOffset).Position,
                                        ["AimPosition"] = AimPosition,
                                        ["BeamColor"] = BeamCol,
                                        ["LegitPosition"] = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200,
                                        ["Range"] = WeaponRange.Value
                                    })
                                    ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, Arg0, Arg1, Arg2)
                                    ToolEvent:FireServer()
                                end
                            elseif Gun == "Auto" then
                                if Check and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(LocalCharacter)) then
                                    Ticks[Tool.Name] = tick()
                                    ToolEvent:FireServer("Shoot")
                                    local Flag = true
                                    task.spawn(function()
                                        while Flag and (Tool.Parent == LocalCharacter and (NoClueWhatThisIs.Value > 0 and DaHood.CanShoot(LocalCharacter))) do
                                            local HitPosition = snoozestuff.Locals.HitPosition 
                                            local CurrentTime = workspace:GetServerTimeNow()
                                            for _ = 1, 5 do
                                                local SpreadX 
                                                local SpreadY
                                                local SpreadZ
                            
                                                if shared["snoozesaved"].Modifications["Spread Reduction"].Enabled then
                                                    local toolName = Tool.Name
                                                    local spreadPercentage = shared["snoozesaved"].Modifications["Spread Reduction"].Weapon[toolName]
                                                    local randomizer = shared["snoozesaved"].Modifications["Spread Reduction"].Randomizer
                                                
                                                    if randomizer.Enabled then
                                                        local spreadFactor = 1 - math.random() * randomizer.Value
                                                        SpreadX = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                                        SpreadY = math.random() > 0.5 and math.random() * 0.1 * spreadFactor or -math.random() * 0.1 * spreadFactor
                                                        SpreadZ = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                                    else
                                                        if not spreadPercentage then
                                                            SpreadX = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                                            SpreadY = math.random() > 0.5 and math.random() * 0.1 or -math.random() * 0.1
                                                            SpreadZ = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                                        else
                                                            local spreadFactor = 1 - spreadPercentage
                                                            SpreadX = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                                            SpreadY = math.random() > 0.5 and math.random() * 0.1 * spreadFactor or -math.random() * 0.1 * spreadFactor
                                                            SpreadZ = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                                        end
                                                    end
                                                else
                                                    SpreadX = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                                    SpreadY = math.random() > 0.5 and math.random() * 0.1 or -math.random() * 0.1
                                                    SpreadZ = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                                end
                                                local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or {
                                                    ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position
                                                }
                                
                                                local TotalSpread = Vector3.new(SpreadX, SpreadY, SpreadZ)
                                                local AimPosition
                                                local WeaponRange = Tool:WaitForChild("Range")
                                                if SilentAim and (Self.Character.HumanoidRootPart.Position - snoozestuff.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < WeaponRange.Value then
                                                    AimPosition = ForcedOrigin.WorldPosition + ((HitPosition - ForcedOrigin.WorldPosition).Unit + TotalSpread) * WeaponRange.Value
                                                else
                                                    AimPosition = ForcedOrigin.WorldPosition + (DaHood.GetAim(ForcedOrigin.WorldPosition) + TotalSpread) * WeaponRange.Value
                                                end
                                
                                                local Arg0, Arg1, Arg2 = DaHood.ShootGun({
                                                    ["Shooter"] = LocalCharacter,
                                                    ["Handle"] = ToolHandle,
                                                    ["AimPosition"] = AimPosition,
                                                    ["BeamColor"] = BeamCol,
                                                    ["ForcedOrigin"] = ForcedOrigin.WorldPosition,
                                                    ["LegitPosition"] = ForcedOrigin.WorldPosition + (DaHood.GetAim(ForcedOrigin.WorldPosition) + TotalSpread) * WeaponRange.Value,
                                                    ["Range"] = WeaponRange.Value
                                                })
                                                ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, Arg0, Arg1, Arg2, CurrentTime)
                                            end
                                            task.wait(Cooldown + 0.0095)
                                            Ticks[Tool.Name] = tick()
                                        end
                                        ToolEvent:FireServer()
                                    end)
                                    Tool.Deactivated:Wait()
                                    Flag = false
                                end
                            elseif Gun == "Burst" then
                                local Tolerance = Tool:WaitForChild("ToleranceCooldown").Value
                                local ShootingCool = Tool:WaitForChild("ShootingCooldown").Value
                                if tick() - Ticks[Tool.Name] >= Tolerance and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(LocalCharacter)) then
                                    Ticks[Tool.Name] = tick()
                                    ToolEvent:FireServer("Shoot")
                                    workspace:GetServerTimeNow()
                                    task.spawn(function()
                                        for _ = 1, NoClueWhatThisIs.Value > 3 and 3 or NoClueWhatThisIs.Value do
                                            local HitPosition = snoozestuff.Locals.HitPosition 
                                            local v17
                                            local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or {
                                                ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position
                                            }
                            
                                            local WeaponRange = Tool:WaitForChild("Range")
                                            if SilentAim and (Self.Character.HumanoidRootPart.Position - snoozestuff.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < WeaponRange.Value then
                                                v17 = ForcedOrigin.WorldPosition + ((HitPosition - ForcedOrigin.WorldPosition).Unit) * 200
                                                --v17 = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200
                                            else
                                                v17 = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200
                                            end
                                            local v18, v19, v20 = DaHood.ShootGun({
                                                ["Shooter"] = LocalCharacter,
                                                ["Handle"] = ToolHandle,
                                                ["ForcedOrigin"] = ForcedOrigin.WorldPosition,
                                                ["AimPosition"] = v17,
                                                ["LegitPosition"] = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200,
                                                ["BeamColor"] = BeamCol,
                                                ["Range"] = WeaponRange.Value
                                            })
                                            ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, v18, v19, v20)
                                            task.wait(ShootingCool + 0.0095)
                                        end
                                        ToolEvent:FireServer()
                                    end)
                                end
                            elseif Gun == "Rifle" or GunType == "SMG" then
                                local ShootingCool = Tool:WaitForChild("ShootingCooldown").Value
                                if Check and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(LocalCharacter)) then
                                    Ticks[Tool.Name] = tick()
                                    ToolEvent:FireServer("Shoot")
                                    local Flag = true
                                    task.spawn(function()
                                        while task.wait(ShootingCool + 0.0095) and (Flag and (Tool.Parent == LocalCharacter and (NoClueWhatThisIs.Value > 0 and DaHood.CanShoot(LocalCharacter)))) do
                                            local HitPosition = snoozestuff.Locals.HitPosition 
                                            local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or {
                                                ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position
                                            }
                            
                                            local AimPosition
                                            local WeaponRange = Tool:WaitForChild("Range")
                                            if SilentAim and (Self.Character.HumanoidRootPart.Position - snoozestuff.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < WeaponRange.Value then
                                                AimPosition =  ForcedOrigin.WorldPosition + ((HitPosition - ForcedOrigin.WorldPosition).Unit) * 200
                                            else
                                                AimPosition = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200
                                            end
                                            local WeaponRange = Tool:WaitForChild("Range")
        
                                            local v18, v19, v20 = DaHood.ShootGun({
                                                ["Shooter"] = LocalCharacter,
                                                ["Handle"] = ToolHandle,
                                                ["ForcedOrigin"] = ForcedOrigin.WorldPosition,
                                                ["AimPosition"] = AimPosition,
                                                ["LegitPosition"] = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200,
                                                ["BeamColor"] = BeamCol,
                                                ["Range"] = WeaponRange.Value
                                            })
                                            ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, v18, v19, v20)
                                            Ticks[Tool.Name] = tick()
                                        end
                                        ToolEvent:FireServer()
                                    end)
                                    Tool.Deactivated:Wait()
                                    Flag = false
                                end
                            elseif Gun == "Sniper" then
                                if Check and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(LocalCharacter)) then
                                    Ticks[Tool.Name] = tick()
                                    ToolEvent:FireServer("Shoot")
                                    local HitPosition = snoozestuff.Locals.HitPosition 
                                    local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or {
                                        ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position
                                    }
                    
                                    local AimPosition
                                    local WeaponRange = Tool:WaitForChild("Range")
                                    if SilentAim and (Self.Character.HumanoidRootPart.Position - snoozestuff.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < WeaponRange.Value then
                                        AimPosition =  ForcedOrigin.WorldPosition + ((HitPosition - ForcedOrigin.WorldPosition).Unit) * 50
                                    else
                                        AimPosition = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 50
                                    end
            
                                    local v16, v17, v18 = DaHood.ShootGun({
                                        ["Shooter"] = LocalCharacter,
                                        ["Handle"] = ToolHandle,
                                        ["ForcedOrigin"] = ForcedOrigin.WorldPosition,
                                        ["AimPosition"] = AimPosition,
                                        ["LegitPosition"] = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 50,
                                        ["BeamColor"] = BeamCol,
                                        ["Range"] = WeaponRange.Value
                                    })
                                    ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, v16, v17, v18)
                                    ToolEvent:FireServer()
                                end
                            end
                        end

                        local function shouldShoot(target)
                            local allConditionsPassed = true
                            local conditions = shared["snoozesaved"].Conditions
                            
                            if conditions.Wall and not Engine.RayCast(target.HumanoidRootPart, Player.GetOrigin('Camera'), {Self.Character}) then
                                allConditionsPassed = false
                            end
                            
                            if conditions.Forcefield and target:FindFirstChild("ForceField") then
                                allConditionsPassed = false
                            end
                            
                            if conditions.Knocked and Player.IsKnocked(target) then
                                allConditionsPassed = false
                            end
        
                            if conditions.Alive and Player.IsKnocked(Self.Character) then
                                allConditionsPassed = false
                            end
                            
                            if conditions.Grabbed and Player.IsGrabbed(target) then
                                allConditionsPassed = false
                            end
                            
                            local screen, _ = Camera:WorldToViewportPoint(snoozestuff.Locals.HitPosition)
                            local fov = shared["snoozesaved"].Fields.SilentAimField.Size
        
                            local DistanceX = math.abs(screen.X - Mouse.X)
                            local DistanceY = math.abs(screen.Y - Mouse.Y)
                            local Box = Vector2.new(0, 0)
                            local RadiusX 
                            local RadiusY 
                            if snoozestuff.Locals.IsBoxFocused then
                                Box = Vector2.new(1000, 1000)
                            else
                                Box = Vector2.new(0, 0)
                            end
    
                            if shared["snoozesaved"].SilentAim.Field == 'Box' then
                                RadiusX = Box.X
                                RadiusY = Box.Y
                            else
                                RadiusX = fov
                                RadiusY = fov
                            end

        
                            if not (RadiusX > DistanceX and RadiusY > DistanceY and (DistanceX^2 + DistanceY^2) < (1/0)^2) then
                                allConditionsPassed = false
                            end
        
                            return allConditionsPassed
                        end
                        
                        if snoozestuff.Locals.SilentAimTarget and snoozestuff.Locals.SilentAimTarget.Character then
                            local target = snoozestuff.Locals.SilentAimTarget.Character
                            ShootFunc(Gun, shouldShoot(target))
                        else
                            ShootFunc(Gun, false)
                        end
                    else
                        local function shouldShoot(target)
                            local allConditionsPassed = true
                            local conditions = shared["snoozesaved"].Conditions
                            
                            if conditions.Wall and not Engine.RayCast(target.HumanoidRootPart, Player.GetOrigin('Camera'), {Self.Character}) then
                                allConditionsPassed = false
                            end
                            
                            if conditions.Forcefield and target:FindFirstChild("ForceField") then
                                allConditionsPassed = false
                            end
                            
                            if conditions.Knocked and Player.IsKnocked(target) then
                                allConditionsPassed = false
                            end
        
                            if conditions.Alive and Player.IsKnocked(Self.Character) then
                                allConditionsPassed = false
                            end
                            
                            if conditions.Grabbed and Player.IsGrabbed(target) then
                                allConditionsPassed = false
                            end
                            
                            if conditions.Moving and target.Humanoid.MoveDirection.Magnitude < 0.01 then
                                allConditionsPassed = false
                            end
                            
                            local screen, _ = Camera:WorldToViewportPoint(snoozestuff.Locals.HitPosition)
                            local fov = shared["snoozesaved"].Fields.SilentAimField.Size
        
                            local DistanceX = math.abs(screen.X - Mouse.X)
                            local DistanceY = math.abs(screen.Y - Mouse.Y)
                            local Box = Vector2.new(0, 0)
                            local RadiusX 
                            local RadiusY 
                            if snoozestuff.Locals.IsBoxFocused then
                                Box = Vector2.new(1000, 1000)
                            else
                                Box = Vector2.new(0, 0)
                            end
    
                            if shared["snoozesaved"].SilentAim.Field == 'Box' then
                                RadiusX = Box.X
                                RadiusY = Box.Y
                            else
                                RadiusX = fov
                                RadiusY = fov
                            end

                            if not (RadiusX > DistanceX and RadiusY > DistanceY and (DistanceX^2 + DistanceY^2) < (1/0)^2) then
                                allConditionsPassed = false
                            end
        
                            return allConditionsPassed
                        end

                        if snoozestuff.Locals.SilentAimTarget and snoozestuff.Locals.SilentAimTarget.Character then
                            local target = snoozestuff.Locals.SilentAimTarget.Character
                            local Updater = CurrentGame.Updater
                            local Remote = CurrentGame.Functions.RemotePath()
                            local Send = {}
                            if Updater and Remote then
                                if shouldShoot(target) then
                                    Send = {
                                        [1] = Updater,
                                        [2] = snoozestuff.Locals.HitPosition
                                    }
                                    Remote:FireServer(unpack(Send))
                                end
                            end
                            --ShootFunc(Gun, shouldShoot(target))
                        end

                    end
                end                    
            end
    
            local function ActivateTool()
                local Tool = Self.Character:FindFirstChildOfClass("Tool")
                if Tool ~= nil and Tool:IsDescendantOf(Self.Character) then 
                    Tool:Activate()
                end 
            end     
            
            local function CheckMagnitudeFromMouse(Position, HitScan)
                local Resume = true --GuiInsetOffsetY
                local MagnitudeY = (Vector2.new(0, Mouse.Y + 35)-Vector2.new(0, Position.Y)).Magnitude
                local MagnitudeX = (Vector2.new(Mouse.X, 0)-Vector2.new(Position.X, 0)).Magnitude
            
                if (MagnitudeX > HitScan.X or MagnitudeY > HitScan.Y) then 
                    Resume = false
                end 
            
                return Resume
            end
    
            local function TriggerBot()
                if shared["snoozesaved"].TriggerBot.Enabled and snoozestuff.Locals.TriggerState and snoozestuff.Locals.TriggerbotTarget and snoozestuff.Locals.TriggerbotTarget.Character and snoozestuff.Locals.HitTrigger then 
    
    
                    local Tool = Self.Character:FindFirstChildOfClass("Tool")
                    local Range
                    if CurrentGame.Name == "Da Hood" then
                        Range = 200
                    else
                        Range = 200
                    end
                    if not Tool or not Range then return end
                    
                    local TargetDistance = (Self.Character.HumanoidRootPart.Position - snoozestuff.Locals.TriggerbotTarget.Character.HumanoidRootPart.Position).Magnitude
                    if TargetDistance > Range then return end
                    
                    if not Tool:FindFirstChild("Ammo") then
                        return
                    end
    
                    if shared["snoozesaved"].TriggerBot.Field == 'Cursor' then

                        if shared["snoozesaved"].TriggerBot.Prediction.Enabled then
                            local target = Mouse.Target
                            local Check
                            if CurrentGame.Name == "Da Hood" then
                                Check = target and target.Parent and Players:GetPlayerFromCharacter(target.Parent)
                            else
                                Check = target and target.Parent and Players:GetPlayerFromCharacter(target.Parent)
                            end
                            if Check then
                                local Position, Velocity
                                if CurrentGame.Name == "Da Hood" then
                                    Position, Velocity = target.Parent.HumanoidRootPart.Position, target.Parent.HumanoidRootPart.AssemblyLinearVelocity
                                else
                                    Position, Velocity = target.Parent.HumanoidRootPart.Position, target.Parent.HumanoidRootPart.AssemblyLinearVelocity
                                end

                                if CurrentGame.Name == "Da Hood" then
                                    local targetPosition = Position
                                    local targetVelocity = Velocity
                        
                                    local prediction = Vector3.new(Vector3.new(shared["snoozesaved"]["TriggerBot"]['Prediction'].Ground, shared["snoozesaved"]["TriggerBot"]['Prediction'].Air, shared["snoozesaved"]["TriggerBot"]['Prediction'].Ground))
                                    local predictedPosition = targetPosition + targetVelocity * prediction
                        
                                    local cursorPosition = Mouse.Hit.p 
                                    local distance = (predictedPosition - cursorPosition).Magnitude
                        
                                    if distance < shared["snoozesaved"].TriggerBot.Prediction.Threshold then 
                                        local interval = shared["snoozesaved"]["TriggerBot"]['Interval'].Weapon[Tool.Name] or 0
                                        if shared["snoozesaved"]["TriggerBot"]['Interval']['Enabled'] then
                                            if DateTime.now().UnixTimestampMillis - snoozestuff.Locals.LastShot >= interval * 1000 then
                                                snoozestuff.Locals.LastShot = DateTime.now().UnixTimestampMillis
                                                snoozestuff.Locals.IsTriggerBotting = true
                                                ActivateTool()
                                                snoozestuff.Locals.IsTriggerBotting = false
                                            end
                                        else
                                            snoozestuff.Locals.IsTriggerBotting = true
                                            ActivateTool()
                                            snoozestuff.Locals.IsTriggerBotting = false
                                        end
                                    end
                                else
                                    local target = Mouse.Target
                                    local hitTrigger = snoozestuff.Locals.HitTrigger
                        
                                    if target and hitTrigger and target.Position and hitTrigger.Position then
                                        local point = Player.GetClosestPointOnPart(hitTrigger, 0.2)
                                        if (target.Position - point).Magnitude <= shared["snoozesaved"].Fields.TriggerBotField.Size then
                                            local interval = shared["snoozesaved"]["TriggerBot"]['Interval'].Weapon[Tool.Name] or 0
                                            if shared["snoozesaved"]["TriggerBot"]['Interval']['Enabled'] then
                                                if DateTime.now().UnixTimestampMillis - snoozestuff.Locals.LastShot >= interval * 1000 then
                                                    snoozestuff.Locals.LastShot = DateTime.now().UnixTimestampMillis
                                                    snoozestuff.Locals.IsTriggerBotting = true
                                                    ActivateTool()
                                                    snoozestuff.Locals.IsTriggerBotting = false
                                                end
                                            else
                                                snoozestuff.Locals.IsTriggerBotting = true
                                                ActivateTool()
                                                snoozestuff.Locals.IsTriggerBotting = false
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            local target = Mouse.Target
                            local Check
                            if CurrentGame.Name == "Da Hood" then
                                Check = target and target.Parent and Players:GetPlayerFromCharacter(target.Parent)
                            else
                                Check = target and target.Parent and Players:GetPlayerFromCharacter(target.Parent)
                            end
                            if CurrentGame.Name == "Da Hood" then
                                if Check then
                                    local interval = shared["snoozesaved"]["TriggerBot"]['Interval'].Weapon[Tool.Name] or 0
                                    if shared["snoozesaved"]["TriggerBot"]['Interval']['Enabled'] then
                                        if DateTime.now().UnixTimestampMillis - snoozestuff.Locals.LastShot >= interval * 1000 then
                                            snoozestuff.Locals.LastShot = DateTime.now().UnixTimestampMillis
                                            snoozestuff.Locals.IsTriggerBotting = true
                                            ActivateTool()
                                            snoozestuff.Locals.IsTriggerBotting = false
                                        end
                                    else
                                        snoozestuff.Locals.IsTriggerBotting = true
                                        ActivateTool()
                                        snoozestuff.Locals.IsTriggerBotting = false
                                    end
                                end
                            else
                                local target = Mouse.Target
                                local hitTrigger = snoozestuff.Locals.HitTrigger
                    
                                if target and hitTrigger and target.Position and hitTrigger.Position then
                                    local point = Player.GetClosestPointOnPart(hitTrigger, 0.2)
                                    if (target.Position - point).Magnitude <= shared["snoozesaved"].Fields.TriggerBotField.Size then
                                        local interval = shared["snoozesaved"]["TriggerBot"]['Interval'].Weapon[Tool.Name] or 0
                                        if shared["snoozesaved"]["TriggerBot"]['Interval']['Enabled'] then
                                            if DateTime.now().UnixTimestampMillis - snoozestuff.Locals.LastShot >= interval * 1000 then
                                                snoozestuff.Locals.LastShot = DateTime.now().UnixTimestampMillis
                                                snoozestuff.Locals.IsTriggerBotting = true
                                                ActivateTool()
                                                snoozestuff.Locals.IsTriggerBotting = false
                                            end
                                        else
                                            snoozestuff.Locals.IsTriggerBotting = true
                                            ActivateTool()
                                            snoozestuff.Locals.IsTriggerBotting = false
                                        end
                                    end
                                end
                            end
                           
                        end
                    end
                    
                    
                    if shared["snoozesaved"].TriggerBot.Field == 'Magnitude' then
                         
                        local Position, OnScreen
                        if shared["snoozesaved"]["TriggerBot"]["Prediction"]['Enabled'] then 
                            Position, OnScreen = Camera:WorldToViewportPoint(snoozestuff.Locals.HitTrigger.Position + snoozestuff.Locals.HitTrigger.Velocity * Vector3.new(shared["snoozesaved"]["TriggerBot"]['Prediction'].Ground, shared["snoozesaved"]["TriggerBot"]['Prediction'].Air, shared["snoozesaved"]["TriggerBot"]['Prediction'].Ground))
                        else 
                            Position, OnScreen = Camera:WorldToViewportPoint(snoozestuff.Locals.HitTrigger.Position)
                        end
                
                        local Resume = CheckMagnitudeFromMouse(Position, shared["snoozesaved"]["TriggerBot"]["Magnitude"].Weapon[Tool.Name] or {X = 0, Y = 0})
                        
                        local Test = false
                        if Test then --shared["snoozesaved"].Conditions.Moving and snoozestuff.Locals.TriggerbotTarget.Character.Humanoid.MoveDirection.Magnitude == 0 then 
                            return
                        elseif shared["snoozesaved"]["TriggerBot"]['Interval'].Weapon[Tool.Name] then
                            if Resume then 
                                if shared["snoozesaved"]["TriggerBot"]['Interval']['Enabled'] and DateTime.now().UnixTimestampMillis - snoozestuff.Locals.LastShot >= shared["snoozesaved"]["TriggerBot"]['Interval'].Weapon[Tool.Name] * 1000 then 
                                    snoozestuff.Locals.LastShot = DateTime.now().UnixTimestampMillis
                                    snoozestuff.Locals.IsTriggerBotting = true
                                    ActivateTool()
                                    snoozestuff.Locals.IsTriggerBotting = false
                                elseif not shared["snoozesaved"]["TriggerBot"]['Interval']['Enabled'] then 
                                    snoozestuff.Locals.IsTriggerBotting = true
                                    ActivateTool()
                                    snoozestuff.Locals.IsTriggerBotting = false
                                end 
                            end 
                        end
                    end
                end
            end
            
            local function AimAssist()
                if shared["snoozesaved"].AimAssist.Enabled then
                    if not shared["snoozesaved"].AimAssist.Sticky then
                        snoozestuff.Locals.AimAssistTarget = Player.GetClosestPlayerToCursor()
                    end
    
                    local Smoothness
                    local Conditions = shared["snoozesaved"].Conditions
                    local Target = snoozestuff.Locals.AimAssistTarget
                    if Target and Target.Character then
    
                        if Conditions.Wall and not Engine.RayCast(Target.Character.HumanoidRootPart, Player.GetOrigin('Camera'), {Self.Character}) then
                            return
                        end
    
                        local Position, Visible = Camera:WorldToViewportPoint(Target.Character.HumanoidRootPart.Position)
    
                        if Conditions.Visible and not Visible then
                            return
                        end
    
                        if Conditions.Forcefield and Target.Character:FindFirstChild("ForceField") then
                            return
                        end
    
                        if Conditions.Knocked and Player.IsKnocked(Target.Character) then
                            return
                        end
    
                        if Conditions.Alive and Player.IsKnocked(Self.Character) then
                            return
                        end
    
                        if Conditions.Grabbed and Player.IsGrabbed(Target.Character) then
                            return
                        end
    

    
                        local FOVSize = shared["snoozesaved"].Fields.AimAssistField.Size
                        local MousePosition = Vector2.new(Mouse.X, Mouse.Y)
                        local Magnitude = (Vector2.new(Position.X, Position.Y) - MousePosition).Magnitude
    
                        if Magnitude > FOVSize then
                            return 
                        end
    
                        local HitPosition = Player.GetHitPosition("Assist")
    
                        local Hit = CFrame.new(Camera.CFrame.p, HitPosition)
    
                        local State = Target.Character.Humanoid:GetState()
    
                        if not shared["snoozesaved"].AimAssist.Smoothing.Enabled then
                            Smoothness = 1
                        else
                            if State == Enum.HumanoidStateType.Jumping or State == Enum.HumanoidStateType.Freefall then
                                Smoothness = shared["snoozesaved"].AimAssist.Smoothing.Air
                            else
                                Smoothness = shared["snoozesaved"].AimAssist.Smoothing.Ground
                            end
                        end
    
                        Camera.CFrame = Camera.CFrame:Lerp(Hit, Smoothness)
                    end
                end
            end


            local function IsPriority(Player)
                for _, Client in ipairs(Environment.Priority) do
                    if Client == Player then
                        return true
                    end
                end
                return false
            end
            --
            local function AddPriority(Player)
                if not IsPriority(Player) then
                    table.insert(Environment.Priority, Player)
                end
            end
            --
            local function RemovePriority(Player)
                for i, p in ipairs(Environment.Priority) do
                    if p == Player then
                        table.remove(Environment.Priority, i)
                        return
                    end
                end
            end
            --
            local Players = game:GetService("Players")
            local Workspace = game:GetService("Workspace")
            local Camera = Workspace.CurrentCamera
            local LocalPlayer = Players.LocalPlayer
            local Mouse = LocalPlayer:GetMouse()
            
            local function SelectPriority()
                local ClosestPlayer = nil
                local ClosestDistance = math.huge
                local SelectionRadius = 100
            
                for _, PossiblePriority in pairs(Players:GetPlayers()) do
                    if PossiblePriority == LocalPlayer then continue end 
            
                    local Character = PossiblePriority.Character
                    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
            
                    if RootPart and Character:IsDescendantOf(Workspace) then


                        if shared["snoozesaved"].Conditions.Wall then
                            if not Engine.RayCast(RootPart, Player.GetOrigin('Camera'), {LocalPlayer.Character}) then
                                continue
                            end
                        end
                
                        -- Forcefield Check
                        if shared["snoozesaved"].Conditions.Forcefield then
                            if Character:FindFirstChild("ForceField") then
                                continue
                            end
                        end
                
                        -- Knocked Check
                        if shared["snoozesaved"].Conditions.Knocked then
                            if Player.IsKnocked(Character) then
                                continue
                            end
                        end
                
                        -- Grabbed Check
                        if shared["snoozesaved"].Conditions.Grabbed then
                            if Player.IsGrabbed(Character) then
                                continue
                            end
                        end

                        local WorldPos, onScreen = Camera:WorldToViewportPoint(RootPart.Position)
                        if onScreen then
                            local Distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(WorldPos.X, WorldPos.Y)).Magnitude
                            if Distance < ClosestDistance and Distance < SelectionRadius then
                                ClosestDistance = Distance
                                ClosestPlayer = PossiblePriority
                            end
                        end
                    end
                end
            
                if ClosestPlayer then
                    if IsPriority(ClosestPlayer) then
                        RemovePriority(ClosestPlayer)
                    else
                        AddPriority(ClosestPlayer)
                    end
                end
            end
                  
            --        
            local function ClearPriority()
                Environment.Priority = {}
            end

            local function Clean(tbl)
                for player, element in pairs(tbl) do
                    if not IsPriority(player) or not player.Parent then 
                        element:Remove()
                        tbl[player] = nil
                    end
                end
            end            

            local function IsFriendly(Player)
                if Player:IsFriendsWith(Self.UserId) then
                    return false
                else
                    return true
                end
            end

            local function RaidAwareness()
                local Script = shared["snoozesaved"]
                local RAID_Enabled = Script["Target ESP"].Enabled
                local Priority = Environment.Priority
            
                if RAID_Enabled then
                    Clean(Environment.PriorityLines)
                    Clean(Environment.PriorityTexts)
                    Clean(Environment.PrioritySquares)
                    Clean(Environment.PrioritySquaresOutlines)
                    Clean(Environment.PriorityLabels)
                    Clean(Environment.PriorityTools) -- Clean tool name labels
            
                    for _, Player in ipairs(Priority) do
                        if not table.find(Priority, Player) then
                            Environment.PriorityTexts[Player]:Remove()
                            Environment.PrioritySquares[Player]:Remove()
                            Environment.PriorityLabels[Player]:Remove()
                            Environment.PriorityTools[Player]:Remove() -- Remove tool label
                            Environment.PriorityTexts[Player] = nil
                            Environment.PrioritySquares[Player] = nil
                            Environment.PriorityLabels[Player] = nil
                            Environment.PriorityTools[Player] = nil -- Clear tool label reference
                            continue
                        end
            
                        local RootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                        if not RootPart then
                            if Environment.PriorityTexts[Player] then
                                Environment.PriorityTexts[Player].Visible = false
                            end
                            if Environment.PrioritySquares[Player] then
                                Environment.PrioritySquares[Player].Visible = false
                            end
                            if Environment.PriorityLabels[Player] then
                                Environment.PriorityLabels[Player].Visible = false
                            end
                            if Environment.PriorityTools[Player] then
                                Environment.PriorityTools[Player].Visible = false -- Hide tool label
                            end
                            return
                        end
            
                        local Position, Visible = Camera:WorldToViewportPoint(RootPart.Position)
                        local CharacterSize = (Camera:WorldToViewportPoint(RootPart.Position - Vector3.new(0, 3, 0)).Y -
                                               Camera:WorldToViewportPoint(RootPart.Position + Vector3.new(0, 2.6, 0)).Y) / 2
                        local Size = RootPart.Size.Y
                        local scaleFactor = (Size * Camera.ViewportSize.Y) / (Position.Z * 2) * 80 / workspace.CurrentCamera.FieldOfView
                        local w, h = 3 * scaleFactor, 4.5 * scaleFactor
                        local IsAlly = IsFriendly(Player)
                        local Color = IsAlly and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 255, 0)
 
                        if Script["Target ESP"]["Name"] then
                            local Text = Environment.PriorityTexts[Player]
                            if not Text then
                                Text = Overlay.new("Text")
                                Text.Size = 13
                                Text.Visible = Visible
                                Text.Outline = true
                                Text.Color = Color
                                Text.Center = true
                                Text.RichText = true
                                Environment.PriorityTexts[Player] = Text
                            end
            
                            local displayName = string.format('<font color="rgba(150, 0, 0, 0.47)">%s</font>', Player.DisplayName) -- Light Blue
                            local playerName = string.format('<font color="rgba(167, 1, 1, 1)">(%s)</font>', Player.Name) -- White
                            
                            Text.Text = displayName .. " " .. playerName
                            Text.Position = Vector2.new(Position.X, Position.Y - h / 2 - 16)
                            Text.Visible = Visible
                        end
            
                        if Script["Target ESP"]["Name"] then
                            local Label = Environment.PriorityLabels[Player]
                            if not Label then
                                Label = Overlay.new("Text")
                                Label.Size = 13
                                Label.Visible = Visible
                                Label.Outline = true
                                Label.Center = true
                                Label.RichText = true
                                Environment.PriorityLabels[Player] = Label
                            end
            
                            local statusText = not IsAlly and '<font color="rgba(255, 255, 255, 1)">Friendly</font>' or '<font color="rgb(255,0,0)">Enemy</font>'
                            Label.Text = statusText
                            Label.Position = Vector2.new(Position.X, Position.Y + h / 2 + 1)
                            Label.Visible = Visible
                        end
        

                        if Script["Target ESP"]["Box"] then
                            local Square = Environment.PrioritySquares[Player]
                            if not Square then
                                Square = Overlay.new("Square")
                                Square.Thickness = 1
                                Square.Color = Color
                                Environment.PrioritySquares[Player] = Square
                            end
                            
                            Square.Position = Vector2.new(Position.X - w / 2, Position.Y - h / 2)
                            Square.Size = Vector2.new(w, h)
                            Square.Visible = Visible
                        end
                    end
                else
                    for _, lines in pairs(Environment.PriorityTexts) do
                        for _, Line in ipairs(lines) do
                            Line:Remove()
                        end
                    end
                    for _, lines in pairs(Environment.PrioritySquares) do
                        for _, Line in ipairs(lines) do
                            Line:Remove()
                        end
                    end
                    for _, labels in pairs(Environment.PriorityLabels) do
                        for _, Label in ipairs(labels) do
                            Label:Remove()
                        end
                    end
                    for _, tools in pairs(Environment.PriorityTools) do
                        for _, ToolLabel in ipairs(tools) do
                            ToolLabel:Remove()
                        end
                    end
            
                    Clean(Environment.PriorityLines)
                    Clean(Environment.PriorityTexts)
                    Clean(Environment.PrioritySquares)
                    Clean(Environment.PrioritySquaresOutlines)
                    Clean(Environment.PriorityLabels)
                    Clean(Environment.PriorityTools) -- Clean tool storage
            
                    Environment.PriorityLines = {}
                    Environment.PrioritySquaresOutlines = {}
                    Environment.PriorityTexts = {}
                    Environment.PrioritySquares = {}
                    Environment.PriorityLabels = {}
                    Environment.PriorityTools = {} -- Store tool labels
                    Environment.Priority = {}
                end
            end
            
    
            return {
                AimAssist = AimAssist,
                UpdateBox = UpdateBox,
                SilentAim = SilentAim,
                TriggerBot = TriggerBot,
                GetGunCategory = GetGunCategory,
                SelectPriority = SelectPriority,
                RaidAwareness = RaidAwareness,
                ClearPriority = ClearPriority
            }
        end
    end
end)()
--
local Main = Modules.Get("Main")
local Player = Modules.Get("Player")
local Utility = Modules.Get("Utility")
local ScreenGui = Modules.Get("ScreenGui")
local SP = false
local SP2 = false
--// Connections
do
    ScreenGui.Setup()
    Utility.Connection(UserInputService.InputBegan, function(Input, Processed)
        if shared["snoozesaved"].Conditions.Typing and UserInputService:GetFocusedTextBox() then return end
        local WalkSpeed = Enum.KeyCode[shared["snoozesaved"].Physics.Walking.Toggle:upper()]
        local SilentAim = Enum.KeyCode[shared["snoozesaved"].SilentAim.Toggle:upper()]
        local AimAssist = Enum.KeyCode[shared["snoozesaved"].AimAssist.Toggle:upper()]
        local DoubleTap = Enum.KeyCode[shared["snoozesaved"].Modifications['Double Tap'].Toggle:upper()]
        local RaidAwareness = Enum.KeyCode[shared["snoozesaved"]["Target ESP"]['Select']:upper()]
        local RaidAwarenessHide = Enum.KeyCode[shared["snoozesaved"]["Target ESP"]['Clear']:upper()]

        if Input.KeyCode == WalkSpeed then
            snoozestuff.Locals.IsWalkSpeeding = not snoozestuff.Locals.IsWalkSpeeding
        end

        if Input.KeyCode == DoubleTap then
            snoozestuff.Locals.IsDoubleTapping = not snoozestuff.Locals.IsDoubleTapping
        end

        if (Input.KeyCode == RaidAwareness) then
            Main.SelectPriority()
        end

        if (Input.KeyCode == RaidAwarenessHide) then
            Main.ClearPriority()
        end


        if Input.KeyCode == AimAssist and shared["snoozesaved"].AimAssist.Sticky then
            SP2 = not SP2
            if SP2 then
                snoozestuff.Locals.AimAssistTarget = Player.GetClosestPlayerToCursor()
            else
                if snoozestuff.Locals.AimAssistTarget then
                    snoozestuff.Locals.AimAssistTarget = nil
                end
            end
        end

        if Input.KeyCode == SilentAim and shared["snoozesaved"].SilentAim.Mode == "Target" then
            SP = not SP
            if SP then
                snoozestuff.Locals.SilentAimTarget = Player.GetClosestPlayerToCursor()
            else
                if snoozestuff.Locals.SilentAimTarget then
                    snoozestuff.Locals.SilentAimTarget = nil
                end
            end
        end

        local triggerConfig = shared["snoozesaved"].TriggerBot
        local isMouseInput = triggerConfig.Input == 'Mouse'
        local isKeyboardInput = triggerConfig.Input == 'Keyboard'
        local toggleKey = triggerConfig.Toggle

        if isMouseInput and Input.UserInputType == Enum.UserInputType[toggleKey] then
            if triggerConfig.Type == "Toggle" then
                snoozestuff.Locals.TriggerState = not snoozestuff.Locals.TriggerState
            elseif triggerConfig.Type == "Hold" then
                snoozestuff.Locals.TriggerState = true
            end
        elseif isKeyboardInput and Input.KeyCode == Enum.KeyCode[toggleKey:upper()] then
            if triggerConfig.Type == "Toggle" then
                snoozestuff.Locals.TriggerState = not snoozestuff.Locals.TriggerState
            elseif triggerConfig.Type == "Hold" then
                snoozestuff.Locals.TriggerState = true
            end
        end
    end)
    Utility.Connection(UserInputService.InputEnded, function(Input, Processed)
        if shared["snoozesaved"].Conditions.Typing and UserInputService:GetFocusedTextBox() then return end
        local triggerConfig = shared["snoozesaved"].TriggerBot
        local isMouseInput = triggerConfig.Input == 'Mouse'
        local isKeyboardInput = triggerConfig.Input == 'Keyboard'
        local toggleKey = triggerConfig.Toggle

        if triggerConfig.Type == "Hold" then
            if isMouseInput and Input.UserInputType == Enum.UserInputType[toggleKey] then
                snoozestuff.Locals.TriggerState = false
            elseif isKeyboardInput and Input.KeyCode == Enum.KeyCode[toggleKey:upper()] then
                snoozestuff.Locals.TriggerState = false
            end
        end
    end)
    Utility.ThreadLoop(0, function()
        if shared["snoozesaved"].SilentAim.Mode == "Automatic" then
            snoozestuff.Locals.SilentAimTarget = Player.GetClosestPlayerToCursor()
        end
        snoozestuff.Locals.TriggerbotTarget = Player.GetClosestPlayerToCursor()
        if snoozestuff.Locals.TriggerbotTarget then
            if snoozestuff.Locals.TriggerbotTarget.Character then
                snoozestuff.Locals.HitTrigger = Player.GetClosestPartToCursor(snoozestuff.Locals.TriggerbotTarget.Character)
            end
        end
        ScreenGui.UpdateDrawings()
    end)
    Utility.Connection(RunService.PreRender, LPH_NO_VIRTUALIZE(function()
        if snoozestuff.Locals.SilentAimTarget and snoozestuff.Locals.SilentAimTarget.Character then
            Player.GetHitPosition("Silent")
        end
        Main.AimAssist()
        Main.TriggerBot()
        Player.AutomatedPrediction()
        Main.UpdateBox()
    end))
    Utility.Connection(RunService.PreRender, LPH_NO_VIRTUALIZE(function()
        Utility.ThreadFunction(Player.SelfMods)
        Utility.ThreadFunction(Main.RaidAwareness)
        if shared["snoozesaved"].SilentAim.Enabled and CurrentGame.Name == "Da Hood" then
            local GunType = Main.GetGunCategory()
            local Tool = Self.Character:FindFirstChildWhichIsA("Tool")
            if Tool then
                if GunType == "Pistol" or GunType == "Sniper" then
                    for I, v in pairs(Tool:GetChildren()) do
                        if v.Name == "GunClient" then
                            v:Destroy()
                            --v.Disabled = snoozestuff.Locals.GunScriptDisabled
                        end
                    end
                elseif GunType == "Shotgun" then
                    for I, v in pairs(Tool:GetChildren()) do
                        if v.Name == "GunClientShotgun" then
                            v:Destroy()
                            --v.Disabled = snoozestuff.Locals.GunScriptDisabled
                        end
                    end
                elseif GunType == "Auto" then
                    for I, v in pairs(Tool:GetChildren()) do
                        if v.Name == "GunClientAutomaticShotgun" then
                            v:Destroy()
                            --v.Disabled = snoozestuff.Locals.GunScriptDisabled
                        end
                    end
                elseif GunType == "Burst" then
                    for I, v in pairs(Tool:GetChildren()) do
                        if v.Name == "GunClientBurst" then
                            v:Destroy()
                            --v.Disabled = snoozestuff.Locals.GunScriptDisabled
                        end
                    end
                elseif GunType == "Rifle" or GunType == "SMG" then
                    for I, v in pairs(Tool:GetChildren()) do
                        if v.Name == "GunClientAutomatic" then
                            v:Destroy()
                            --v.Disabled = snoozestuff.Locals.GunScriptDisabled
                        end
                    end
                end    
            end
        end
    end))
    --[[if CurrentGame.Name == 'Dee Hood' and CurrentGame.Updater == nil then
        local function GetArgument() 
            for _, Player in next, game:GetService("Players"):GetPlayers() do
                if Player.Backpack:GetAttribute(string.upper("muv")) then
                    return Player.Backpack:GetAttribute(string.upper("muv"))
                end
            end
        
            return nil
        end
        
        local Argument = GetArgument()
        if Argument then
            CurrentGame.Updater = Argument
        end
    end]]
    if shared["snoozesaved"].Physics.Jumping.Enabled then
        local function disableJumpPower(character)
            character:WaitForChild("Humanoid").UseJumpPower = false
        end
        Self.CharacterAdded:Connect(disableJumpPower)
    
        if Self.Character then
            disableJumpPower(Self.Character)
        end
    end        
    if shared["snoozesaved"].SilentAim.Enabled then
        local Connections = {}
        local function connectTool(tool)
            if tool:IsA("Tool") and not Connections[tool] then
                Connections[tool] = tool.Activated:Connect(function()
                    Main.SilentAim(tool)
                end)
            end
        end
        
        for _, v in ipairs(Self.Backpack:GetChildren()) do
            connectTool(v)
        end
        
        for _, v in ipairs(Self.Character:GetChildren()) do
            connectTool(v)
        end
        
        Self.Character.ChildAdded:Connect(connectTool)
        
        Self.CharacterAdded:Connect(function(character)
            for tool, connection in pairs(Connections) do
                connection:Disconnect()
                Connections[tool] = nil
            end
            
            character.ChildAdded:Connect(connectTool)
        end)
    
    
        task.spawn(function()
            while task.wait() do
                local Tool = Self.Character:FindFirstChildWhichIsA("Tool")
                if Tool and CurrentGame.Name == "Da Hood" then
                    Tool:GetPropertyChangedSignal("Grip"):Connect(function()
                        game.ReplicatedStorage:WaitForChild("MainEvent"):FireServer("CHECKER_4")
                    end)
                end
            end
        end)
    end
end
