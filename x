task.spawn(function()
	repeat task.wait()
	until workspace:FindFirstChild("Ignored")
		and workspace.Ignored:FindFirstChild("Siren")
		and workspace.Ignored.Siren:FindFirstChild("Radius")

	if shared.Loaded ~= nil then return end
	shared.Loaded = true

	local Settings = {}

	local RuntimeGlobal = {
		["Enabled"] = true,
		["Check"] = {
			["Whilst a player is selected"] = {
				["Knocked"]      = true,
				["Self-Knocked"] = true,
				["Visible"]      = false
			},
			["When selecting a player"] = {
				["Knocked"]      = true,
				["Self-Knocked"] = true,
				["Visible"]      = true
			}
		},
		["Keybind"] = "C" -- A, B, C, D ... Z
	}
	Settings["Global"] = RuntimeGlobal

	local RuntimeSilent = {
		["Enabled"]  = true,
		["Hit Part"] = "Head", -- "Head", "HumanoidRootPart", "Closest Part", "Closest Point"
		["Prediction"] = {
			["X"] = 0,
			["Y"] = 0,
			["Z"] = 0
		},
		["Closest Point"] = {
			["Mode"]        = "Advanced", -- "Normal", "Advanced"
			["Point Scale"] = 0.16
		},
		["Client Bullet Redirection"] = {
			["Enabled"] = false,
			["Prediction"] = {
				["X"] = 0.035,
				["Y"] = 0,
				["Z"] = 0.035
			},
			["Weapons"] = {
				"[Revolver]",
				"[Rifle]",
				"[Silencer]",
				"[Glock]"
			}
		},
		["FOV"] = {
			["Enabled"] = false,
			["Size"] = {
				["X"] = 5,
				["Y"] = 5,
				["Z"] = 5
			},
			["Weapon Configuration"] = {
				["Enabled"] = false,
				["Shotguns"] = {
					["X"] = 3.8,
					["Y"] = 4.8,
					["Z"] = 2
				},
				["Pistols"] = {
					["X"] = 3.7,
					["Y"] = 4.8,
					["Z"] = 2
				},
				["Others"] = {
					["X"] = 5,
					["Y"] = 5,
					["Z"] = 5
				}
			}
		}
	}
	Settings["Silent Aimbot"] = RuntimeSilent

	local RuntimeCamera = {
		["Enabled"]    = true,
		["Hit Part"]   = "Closest Part", -- "Head", "HumanoidRootPart", "Closest Part", "Closest Point"
		["Snappiness"] = 0.05,
		["Prediction"] = {
			["X"] = 0,
			["Y"] = 0,
			["Z"] = 0
		},
		["Camera Modes"] = {
			["Shift Locked"] = true,
			["Third Person"] = false,
			["First Person"] = true
		},
		["FOV"] = {
			["Enabled"] = true,
			["Size"] = {
				["X"] = 5,
				["Y"] = 5,
				["Z"] = 5
			},
			["Weapon Configuration"] = {
				["Enabled"] = true,
				["Shotguns"] = {
					["X"] = 13,
					["Y"] = 7,
					["Z"] = 13
				},
				["Pistols"] = {
					["X"] = 13,
					["Y"] = 7,
					["Z"] = 13
				},
				["Others"] = {
					["X"] = 5,
					["Y"] = 5,
					["Z"] = 5
				}
			}
		}
	}
	Settings["Camera Aimbot"] = RuntimeCamera

	local RuntimeTrigger = {
		["Enabled"]        = true,
		["Click Cooldown"] = 0.08,
		["Weapons"] = { "[Double-Barrel SG]", "[Revolver]", "[TacticalShotgun]" },
		["Prediction"] = {
			["X"] = 0,
			["Y"] = 0,
			["Z"] = 0
		},
		["Activation"] = {
			["Activation Mode"] = "Toggle", -- "Hold", "Toggle", "Always"
			["Activation Bind"] = "V"       -- A, B, C, D ... Z
		},
		["FOV"] = {
			["X"] = 2.8,
			["Y"] = 4.8,
			["Z"] = 1.9
		}
	}
	Settings["Trigger Bot"] = RuntimeTrigger

	Settings["Velocity Calculation"] = {
		["Enabled"]   = true,
		["Magnitude"] = 70
	}

	local RuntimeMovement = {}

	local RuntimeSlowdown = {
		["Enabled"] = true,
		["Weapons"] = {
			["[Double-Barrel SG]"] = { ["Multiplier"] = 0.6 },
			["[TacticalShotgun]"]  = { ["Multiplier"] = 0.6 },
			["[Revolver]"]         = { ["Multiplier"] = 0.6 },
			["[AUG]"]              = { ["Multiplier"] = 0.7 },
			["[Silencer]"]         = { ["Multiplier"] = 0.8 },
			["[Glock]"]            = { ["Multiplier"] = 0.8 }
		}
	}
	RuntimeMovement["Slowdown Modifications"] = RuntimeSlowdown

	local RuntimeSpeed = {
		["Enabled"]    = true,
		["Normal"]     = { ["Multiplier"] = 1.02 },
		["Shooting"]   = { ["Multiplier"] = 1.1  },
		["Reloading"]  = { ["Multiplier"] = 1.2  },
		["Low Health"] = { ["Multiplier"] = 1.1  }
	}
	RuntimeMovement["Speed Modifications"] = RuntimeSpeed
	Settings["Movement Modifications"]     = RuntimeMovement

	local UserInputService  = game:GetService("UserInputService")
	local Players           = game:GetService("Players")
	local RunService        = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LocalPlayer       = Players.LocalPlayer
	local Mouse             = LocalPlayer:GetMouse()
	local Connections       = {}
	local Camera            = workspace.CurrentCamera

	local State = {
		Target            = nil,
		Velocities        = {},
		Blacklisted       = {},
		Bypass_Blacklist  = {},
		Redirection       = { Tool = nil, Position = nil },
		Triggerbot        = { ["Key Toggled"] = false, ["Last Click"] = tick() },
		Overwritten       = {},
		CurrentCharacter  = nil,
		CurrentCharacter2 = nil,
		["Speed Modifications"] = { ["Current Multiplier"] = 1 }
	}

	local WeaponCooldowns = {
		["[Revolver]"]         = { ["Cooldown"] = 0.21 },
		["[Double-Barrel SG]"] = { ["Cooldown"] = 0.41 },
		["[TacticalShotgun]"]  = { ["Cooldown"] = 0.66 },
		["[AUG]"]              = { ["Cooldown"] = 0.51 },
		["[Rifle]"]            = { ["Cooldown"] = 1.31 },
		["[Shotgun]"]          = { ["Cooldown"] = 1.21 },
		["[Glock]"]            = { ["Cooldown"] = 0.61 },
		["[Silencer]"]         = { ["Cooldown"] = 0.44 }
	}
	State.Cooldowns = WeaponCooldowns

	local ShotgunConfig = {
		["[Double-Barrel SG]"] = { ["Bullets"] = 5, ["Offset"] = CFrame.new(0, 0.35, -2.2) },
		["[TacticalShotgun]"]  = { ["Bullets"] = 5, ["Offset"] = CFrame.new(0, 0.25, -2.5) },
		["[Shotgun]"]          = { ["Bullets"] = 5, ["Offset"] = CFrame.new(0, 0.25,  2.5) }
	}
	State.Shotguns = ShotgunConfig

	if table.find(State.Bypass_Blacklist, LocalPlayer.UserId) then
		State.Blacklisted = {}
	end

	local LastDamageTime = tick()

	local function worldToScreen(pos)
		local sp, onScreen = Camera:WorldToScreenPoint(pos)
		return Vector2.new(sp.X, sp.Y), onScreen
	end

	local function getMousePos()
		return Vector2.new(Mouse.X, Mouse.Y)
	end

	local function isKnocked(player)
		if player.Character then
			return player.Character:FindFirstChild("BodyEffects")["K.O"].Value
		end
		return false
	end

	local function hasLOS(targetPos, ignoreList)
		return #Camera:GetPartsObscuringTarget({ LocalPlayer.Character.Head.Position, targetPos }, ignoreList) == 0
	end

	local function getSilentPrediction()
		return Settings["Silent Aimbot"]["Prediction"]
	end

	local function getWeaponCategory(tool)
		local name = tool.Name
		if name == "[Double-Barrel SG]" or name == "[TacticalShotgun]" or name == "[Shotgun]" then
			return "Shotguns"
		elseif name == "[Revolver]" or name == "[Silencer]" or name == "[Glock]" then
			return "Pistols"
		else
			return "Others"
		end
	end

	local function isTargetValid(player, checks)
		if checks["Knocked"] == true and isKnocked(player) then
			return false
		elseif checks["Self-Knocked"] == true and isKnocked(LocalPlayer) then
			return false
		else
			return checks["Visible"] ~= true
				or hasLOS(player.Character.Head.Position, { player.Character, LocalPlayer.Character, Camera }) ~= false
		end
	end

	local function getClosestPlayer(checks)
		local closestDist   = math.huge
		local closestPlayer = nil
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer
				and player.Character
				and player.Character:FindFirstChild("HumanoidRootPart")
				and isTargetValid(player, checks) == true
			then
				local sp, onScreen = worldToScreen(player.Character.HumanoidRootPart.Position)
				if onScreen then
					local dist = (sp - getMousePos()).Magnitude
					if dist <= closestDist then
						closestPlayer = player
						closestDist   = dist
					end
				end
			end
		end
		return closestPlayer
	end

	local function closestPointToCursor(points)
		local closestDist  = math.huge
		local closestPoint = nil
		for _, pt in ipairs(points) do
			local sp, _ = Camera:WorldToScreenPoint(pt)
			local dist  = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(sp.X, sp.Y)).Magnitude
			if dist < closestDist then
				closestPoint = pt
				closestDist  = dist
			end
		end
		return closestPoint
	end

	local function getClosestSurfacePoint(parts, gridStep)
		local allPoints = {}
		for _, part in pairs(parts) do
			for x = 0, part.Size.X - gridStep, gridStep do
				for y = 0, part.Size.Y - gridStep, gridStep do
					for z = 0, part.Size.Z - gridStep, gridStep do
						local worldPt = (part.CFrame * CFrame.new(
							-part.Size / 2 + Vector3.new(gridStep/2, gridStep/2, gridStep/2) + Vector3.new(x, y, z)
						)).Position
						table.insert(allPoints, worldPt)
					end
				end
			end
		end
		return closestPointToCursor(allPoints) or parts[1].Position
	end

	local function getClosestPartAdvanced(character)
		if not character then return nil end
		local best, bestDist = nil, math.huge
		for _, child in pairs(character:GetChildren()) do
			if child:IsA("Part") or child:IsA("MeshPart") then
				local sp, _ = worldToScreen(child.Position)
				local dist  = (sp - getMousePos()).Magnitude
				if dist <= bestDist then
					best     = child
					bestDist = dist
				end
			end
		end
		if not best then return nil end

		local function tryPromote(part, promoteTo)
			if not part then return part end
			local parent = part.Parent
			if parent and parent:FindFirstChild("Humanoid") and parent:FindFirstChild(promoteTo) then
				local spA, _ = Camera:WorldToScreenPoint(parent[promoteTo].Position)
				local spB, _ = Camera:WorldToScreenPoint(part.Position)
				if math.abs(Mouse.Y - spA.Y) >= math.abs(Mouse.Y - spB.Y) then
					return part
				end
				return parent[promoteTo]
			end
			return part
		end

		best = tryPromote(best, "LeftUpperLeg")
		best = tryPromote(best, "RightUpperLeg")
		best = best and best.Name == "RightUpperArm" and tryPromote(best, "Head") or best
		best = best and best.Name == "LeftUpperArm"  and tryPromote(best, "Head") or best
		return best
	end

	local function getClosestPart(character, advanced)
		if advanced then
			return getClosestPartAdvanced(character)
		end
		if not character then return nil end
		local best, bestDist = nil, math.huge
		for _, child in pairs(character:GetChildren()) do
			if child:IsA("Part") or child:IsA("MeshPart") then
				local sp, _ = worldToScreen(child.Position)
				local dist  = (sp - getMousePos()).Magnitude
				if dist <= bestDist then
					best     = child
					bestDist = dist
				end
			end
		end
		return best
	end

	local function mergeTables(base, overrides)
		for k, v in pairs(overrides) do base[k] = v end
		return base
	end

	local function raycastThroughBox(originCF, boxSize)
		local tempPart = mergeTables(Instance.new("Part", workspace), {
			["CFrame"]       = originCF,
			["CanCollide"]   = false,
			["Anchored"]     = true,
			["Transparency"] = 1,
			["Size"]         = boxSize
		})
		local origin    = Camera.CFrame.Position
		local target    = Mouse.Hit.Position
		local rayParams = RaycastParams.new()
		rayParams.FilterType                 = Enum.RaycastFilterType.Whitelist
		rayParams.IgnoreWater                = true
		rayParams.FilterDescendantsInstances = { tempPart }
		local result = workspace:Raycast(origin, (target - origin).Unit * 1000, rayParams)
		tempPart:Destroy()
		return result ~= nil
	end

	local function getCameraMode()
		if (Camera.CFrame.Position - Camera.Focus.Position).Magnitude < 0.6 then
			return "First Person"
		elseif UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			return "Shift Locked"
		else
			return "Third Person"
		end
	end

	local function disconnect(name)
		if Connections[name] then
			Connections[name]:Disconnect()
			Connections[name] = nil
		end
	end

	local function measureVelocity(part, dt)
		local startPos = part.Position
		task.wait(dt)
		return (part.Position - startPos) / dt
	end

	local function getPlayerVelocity(player)
		if State.Velocities[player.Name] == nil then
			return player.Character.HumanoidRootPart.Velocity
		end
		return State.Velocities[player.Name]
	end

	RunService.RenderStepped:Connect(function()
		for _, player in pairs(Players:GetPlayers()) do
			pcall(function()
				if player.Character.HumanoidRootPart.Velocity.Magnitude < Settings["Velocity Calculation"]["Magnitude"] then
					if State.Velocities[player.Name] ~= nil then
						State.Velocities[player.Name] = nil
					end
				else
					State.Velocities[player.Name] = measureVelocity(player.Character.HumanoidRootPart, 0.1)
				end
			end)
		end
		if Settings["Velocity Calculation"]["Enabled"] == false then
			State.Velocities = {}
		end
	end)

	local function setupCharacter(character)
		task.wait()
		if State.CurrentCharacter2 == character then return end
		State.CurrentCharacter2 = character

		disconnect("Slowdown Modifications")

		task.spawn(function()
			local bodyEffects = character:WaitForChild("BodyEffects", 8999999488)
			local movement    = bodyEffects and bodyEffects:WaitForChild("Movement", 8999999488)

			if movement then
				Connections["Slowdown Modifications"] = movement.ChildAdded:Connect(function(child)
					task.wait(0.001)
					if child.Name == "ReduceWalk" then
						local tool     = character:FindFirstChildWhichIsA("Tool")
						local slowMods = Settings["Movement Modifications"]["Slowdown Modifications"]
						if tool and slowMods["Enabled"] and slowMods["Weapons"][tool.Name] then
							local multiplier       = slowMods["Weapons"][tool.Name].Multiplier
							local adjustedCooldown = State.Cooldowns[tool.Name].Cooldown * multiplier
							print("Slowed whilst firing " .. tool.Name .. " (Base: " .. State.Cooldowns[tool.Name].Cooldown .. ") (Adjusted: " .. adjustedCooldown .. ")")
							task.spawn(function()
								task.wait(adjustedCooldown)
								child.Parent = ReplicatedStorage
							end)
						end
					end
				end)
			end

			local humanoid     = character:WaitForChild("Humanoid", 8999999488)
			local speedBlocked = false
			if humanoid and Settings["Movement Modifications"]["Speed Modifications"]["Enabled"] then
				humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
					if speedBlocked == false then
						speedBlocked       = true
						humanoid.WalkSpeed = humanoid.WalkSpeed * State["Speed Modifications"]["Current Multiplier"]
						speedBlocked       = false
					end
				end)
			end
		end)
	end

	if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
	Connections["Character Added"] = LocalPlayer.CharacterAdded:Connect(setupCharacter)

	coroutine.resume(coroutine.create(function()
		if not Settings["Movement Modifications"]["Speed Modifications"]["Enabled"] then return end
		while task.wait(0.015) do
			pcall(function()
				local char    = LocalPlayer.Character
				local effects = char and char:FindFirstChild("BodyEffects")
				if not effects then return end
				local speedMods = Settings["Movement Modifications"]["Speed Modifications"]
				if effects.Reload.Value then
					State["Speed Modifications"]["Current Multiplier"] = speedMods["Reloading"].Multiplier
				elseif effects.Movement:FindFirstChild("ReduceWalk") then
					State["Speed Modifications"]["Current Multiplier"] = speedMods["Shooting"].Multiplier
				elseif char.Humanoid.Health < 55 then
					State["Speed Modifications"]["Current Multiplier"] = speedMods["Low Health"].Multiplier
				else
					State["Speed Modifications"]["Current Multiplier"] = speedMods["Normal"].Multiplier
				end
			end)
		end
	end))

	Connections["Input Began"] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed == false then
			local tb = Settings["Trigger Bot"]
			if tb["Enabled"]
				and tb["Activation"]["Activation Mode"] == "Toggle"
				and input.KeyCode == Enum.KeyCode[tb["Activation"]["Activation Bind"]]
			then
				State.Triggerbot["Key Toggled"] = not State.Triggerbot["Key Toggled"]
			end

			if input.KeyCode == Enum.KeyCode[Settings["Global"]["Keybind"]] then
				local candidate = getClosestPlayer(Settings["Global"]["Check"]["When selecting a player"])
				if State.Target ~= nil or not candidate then
					candidate = nil
				end
				State.Target = candidate

				if State.Target then
					local lastHealth = State.Target.Character.Humanoid.Health
					Connections["Health Changed"] = State.Target.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
						local hp = State.Target.Character.Humanoid.Health
						if hp < lastHealth then
							LastDamageTime = tick()
						end
						lastHealth = hp
					end)
					return
				end
				disconnect("Health Changed")
			end
		end
	end)

	Connections["Each Frame"] = RunService.RenderStepped:Connect(function()
		task.spawn(function()
			local camAB = Settings["Camera Aimbot"]
			if camAB["Enabled"] and State.Target and camAB["Camera Modes"][getCameraMode()] then
				if LocalPlayer.PlayerGui.Chat.Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.TextLabel.Visible == false then
					return
				end
				local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
				if tool == nil then return end

				local aimPart
				if camAB["Hit Part"] == "Closest Part" then
					aimPart = getClosestPart(State.Target.Character, false)
				else
					aimPart = State.Target.Character[camAB["Hit Part"]]
				end
				if not aimPart then return end

				local aimPos = aimPart.Position
				if aimPos == nil then return end

				local vel   = getPlayerVelocity(State.Target)
				local pred  = camAB["Prediction"]
				local aimed = Vector3.new(
					aimPos.X + vel.X * pred.X,
					aimPos.Y + vel.Y * pred.Y,
					aimPos.Z + vel.Z * pred.Z
				)

				local fovCfg  = camAB["FOV"]
				local fovSize = fovCfg["Size"]
				if fovCfg["Weapon Configuration"]["Enabled"] then
					local cat = getWeaponCategory(tool)
					if fovCfg["Weapon Configuration"][cat] then
						fovSize = fovCfg["Weapon Configuration"][cat]
					end
				end

				local fovVec     = Vector3.new(fovSize.X, fovSize.Y, fovSize.Z)
				local ignoreList = { State.Target.Character, LocalPlayer.Character, Camera }
				if hasLOS(aimPart.Position, ignoreList)
					and (fovCfg["Enabled"] == false or raycastThroughBox(State.Target.Character.HumanoidRootPart.CFrame, fovVec))
				then
					Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimed), camAB["Snappiness"])
				end
			end
		end)

		local AimProvider = {
			getAim = function(originPos)
				local destination = Mouse.Hit.Position

				local silAB = Settings["Silent Aimbot"]
				if silAB["Enabled"] and State.Target ~= nil and not table.find(State.Blacklisted, State.Target.UserId) then
					local tool    = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
					local char    = State.Target.Character
					local hitPart = silAB["Hit Part"]
					local aimPos  = nil

					if char then
						if hitPart == "Closest Part" then
							aimPos = getClosestPart(char, false).Position
						end
						if hitPart == "Closest Point" then
							local cpMode = silAB["Closest Point"]["Mode"]
							if cpMode == "Advanced" then
								local allParts = {}
								for _, desc in pairs(char:GetDescendants()) do
									if desc:IsA("BasePart") or desc:IsA("MeshPart") then
										allParts[#allParts + 1] = desc
									end
								end
								aimPos = getClosestSurfacePoint(allParts, silAB["Closest Point"]["Point Scale"])
							end
							if cpMode == "Normal" then
								aimPos = getClosestSurfacePoint({ getClosestPart(char, false) }, silAB["Closest Point"]["Point Scale"])
							end
						end
						if aimPos == nil then
							aimPos = char[hitPart].Position
						end

						if aimPos then
							local fovCfg  = silAB["FOV"]
							local fovSize = fovCfg["Size"]
							if fovCfg["Weapon Configuration"]["Enabled"] then
								local cat = getWeaponCategory(tool)
								if fovCfg["Weapon Configuration"][cat] then
									fovSize = fovCfg["Weapon Configuration"][cat]
								end
							end
							local fovVec = Vector3.new(fovSize.X, fovSize.Y, fovSize.Z)

							if fovCfg["Enabled"] == false or raycastThroughBox(char.HumanoidRootPart.CFrame, fovVec) then
								local vel  = getPlayerVelocity(State.Target)
								local pred = getSilentPrediction()
								destination = Vector3.new(
									aimPos.X + vel.X * pred.X,
									aimPos.Y + vel.Y * pred.Y,
									aimPos.Z + vel.Z * pred.Z
								)
								print("Updated destination: " .. tostring(destination))
							end
						end
					end
				end

				return (destination - originPos).Unit
			end
		}

		local function setupGun(character)
			if State.CurrentCharacter == character then return end
			print("Character has been added")
			State.CurrentCharacter = character

			character.ChildAdded:Connect(function(tool)
				print("ChildAdded: " .. tool.Name .. " | Class: " .. tool.ClassName)

				if State.Overwritten[tool] == nil then
					State.Overwritten[tool] = true

					if tool:FindFirstChild("GunClient") then
						print("Overwriting: " .. tool.Name .. " ( One Bullet )")
						tool.GunClient:Destroy()

						local handleOffset = CFrame.new(-1, 0.4, 0)
						local handle       = tool:WaitForChild("Handle")
						local shooterChar  = Players.LocalPlayer.Character
						local _            = tool.Handle.ShootSound
						local ammo         = tool.Ammo
						local rangeProp    = tool:WaitForChild("Range")
						local cooldown     = tool:WaitForChild("ShootingCooldown").Value
						local GunHandler   = require(ReplicatedStorage.Modules.GunHandler)
						local Maid         = require(ReplicatedStorage.Modules.Maid).new()
						local remoteEvent  = tool:WaitForChild("RemoteEvent", 2) or { ["FireServer"] = function(_, _) end }

						Maid:GiveTask(tool.AncestryChanged:Connect(function()
							if tool.Parent ~= shooterChar and tool.Parent ~= Players.LocalPlayer:FindFirstChildWhichIsA("Backpack") then
								print("Cleaning up connections :)")
								Maid:DoCleaning()
							end
						end))

						local lastShot = 0
						Maid:GiveTask(tool.Activated:Connect(function()
							if tick() - lastShot >= cooldown + 0.02
								and ammo.Value >= 1
								and not _G.GUN_COMBAT_TOGGLE
								and GunHandler.getCanShoot(shooterChar)
							then
								lastShot = tick()
								remoteEvent:FireServer("Shoot")

								local originPos = (handle.CFrame * handleOffset).Position
								local muzzle    = tool:FindFirstChild("Default")
									and tool.Default:FindFirstChild("Mesh")
									and tool.Default.Mesh:FindFirstChild("Muzzle")
								if not muzzle then
									muzzle = { ["WorldPosition"] = originPos }
								end

								local aimDest    = muzzle.WorldPosition + AimProvider.getAim(muzzle.WorldPosition) * 200
								local p1, p2, p3 = GunHandler.shoot({
									["Shooter"]      = shooterChar,
									["Handle"]       = handle,
									["ForcedOrigin"] = originPos,
									["AimPosition"]  = aimDest,
									["BeamColor"]    = Color3.new(1, 0.545098, 0.14902),
									["Range"]        = rangeProp.Value
								})
								ReplicatedStorage.MainEvent:FireServer("ShootGun", handle, muzzle.WorldPosition, p1, p2, p3)
								remoteEvent:FireServer()
							end
						end))
					end

					if tool:FindFirstChild("GunClientShotgun") then
						print("Overwriting: " .. tool.Name .. " ( Shotgun )")
						tool.GunClientShotgun:Destroy()

						local bulletCount  = State.Shotguns[tool.Name].Bullets
						local bulletOffset = State.Shotguns[tool.Name].Offset
						local handle       = tool:WaitForChild("Handle")
						local shooterChar  = Players.LocalPlayer.Character
						local _            = tool.Handle.ShootSound
						local ammo         = tool.Ammo
						local rangeProp    = tool:WaitForChild("Range")
						local cooldown     = tool:WaitForChild("ShootingCooldown").Value
						local GunHandler   = require(ReplicatedStorage.Modules.GunHandler)
						local Maid         = require(ReplicatedStorage.Modules.Maid).new()
						local remoteEvent  = tool:WaitForChild("RemoteEvent", 2) or { ["FireServer"] = function(_, _) end }

						Maid:GiveTask(tool.AncestryChanged:Connect(function()
							if tool.Parent ~= shooterChar and tool.Parent ~= Players.LocalPlayer:FindFirstChildWhichIsA("Backpack") then
								print("Cleaning up connections :)")
								Maid:DoCleaning()
							end
						end))

						local lastShot = 0
						Maid:GiveTask(tool.Activated:Connect(function()
							if tick() - lastShot >= cooldown + 0.0095 + 0.05
								and ammo.Value >= 1
								and not _G.GUN_COMBAT_TOGGLE
								and GunHandler.getCanShoot(shooterChar)
							then
								lastShot     = tick()
								remoteEvent:FireServer("Shoot")
								local serverTime = workspace:GetServerTimeNow()

								for _ = 1, bulletCount do
									local spread    = Vector3.new(
										math.random() > 0.5 and  math.random() * 0.05 or -math.random() * 0.05,
										math.random() > 0.5 and  math.random() * 0.1  or -math.random() * 0.1,
										math.random() > 0.5 and  math.random() * 0.05 or -math.random() * 0.05
									)
									local originPos  = (handle.CFrame * bulletOffset).Position
									local muzzle     = tool:FindFirstChild("Default")
										and tool.Default:FindFirstChild("Mesh")
										and tool.Default.Mesh:FindFirstChild("Muzzle")
										or { ["WorldPosition"] = originPos }
									local aimDest    = muzzle.WorldPosition + (AimProvider.getAim(muzzle.WorldPosition) + spread) * rangeProp.Value
									local p1, p2, p3 = GunHandler.shoot({
										["Shooter"]      = shooterChar,
										["Handle"]       = handle,
										["ForcedOrigin"] = originPos,
										["AimPosition"]  = aimDest,
										["BeamColor"]    = Color3.new(1, 0.545098, 0.14902),
										["Range"]        = rangeProp.Value
									})
									ReplicatedStorage.MainEvent:FireServer("ShootGun", handle, muzzle.WorldPosition, p1, p2, p3, serverTime)
								end
								remoteEvent:FireServer()
							end
						end))
					end
				end

				if tool:FindFirstChild("GunClientBurst") then
					print("Overwriting: " .. tool.Name .. " ( Burst )")
					tool.GunClientBurst:Destroy()

					local burstOffset   = CFrame.new(-0.1, 0.4, 1.8)
					local handle        = tool:WaitForChild("Handle")
					local shooterChar   = Players.LocalPlayer.Character
					local _             = tool.Handle.ShootSound
					local ammo          = tool.Ammo
					local rangeProp     = tool:WaitForChild("Range")
					local burstCooldown = tool:WaitForChild("ShootingCooldown").Value
					local toleranceCd   = tool:WaitForChild("ToleranceCooldown").Value
					local GunHandler    = require(ReplicatedStorage.Modules.GunHandler)
					local Maid          = require(ReplicatedStorage.Modules.Maid).new()
					local remoteEvent   = tool:WaitForChild("RemoteEvent", 2) or { ["FireServer"] = function(_, _) end }

					Maid:GiveTask(tool.AncestryChanged:Connect(function()
						if tool.Parent ~= shooterChar and tool.Parent ~= Players.LocalPlayer:FindFirstChildWhichIsA("Backpack") then
							print("Cleaning up connections :)")
							Maid:DoCleaning()
						end
					end))

					local lastShot = 0
					Maid:GiveTask(tool.Activated:Connect(function()
						if tick() - lastShot >= toleranceCd
							and not _G.GUN_COMBAT_TOGGLE
							and GunHandler.getCanShoot(shooterChar)
						then
							lastShot = tick()
							remoteEvent:FireServer("Shoot")
							local serverTime = workspace:GetServerTimeNow()

							task.spawn(function()
								for _ = 1, ammo.Value > 3 and 3 or ammo.Value do
									local originPos  = (handle.CFrame * burstOffset).Position
									local muzzle     = tool:FindFirstChild("Default")
										and tool.Default:FindFirstChild("Mesh")
										and tool.Default.Mesh:FindFirstChild("Muzzle")
										or { ["WorldPosition"] = originPos }
									local aimDest    = muzzle.WorldPosition + AimProvider.getAim(muzzle.WorldPosition) * 200
									local p1, p2, p3 = GunHandler.shoot({
										["Shooter"]      = shooterChar,
										["Handle"]       = handle,
										["ForcedOrigin"] = originPos,
										["AimPosition"]  = aimDest,
										["BeamColor"]    = Color3.new(1, 0.545098, 0.14902),
										["Range"]        = rangeProp.Value
									})
									ReplicatedStorage.MainEvent:FireServer("ShootGun", handle, muzzle.WorldPosition, p1, p2, p3, serverTime)
									task.wait(burstCooldown + 0.0095)
								end
								remoteEvent:FireServer()
							end)
							remoteEvent:FireServer()
						end
					end))
				end
			end)
		end

		if Players.LocalPlayer.Character then
			setupGun(Players.LocalPlayer.Character)
		end
		Players.LocalPlayer.CharacterAdded:Connect(setupGun)

		task.spawn(function()
			local tb             = Settings["Trigger Bot"]
			local activationMode = tb["Activation"]["Activation Mode"]
			local activationBind = tb["Activation"]["Activation Bind"]
			local isActive =
				(activationMode == "Hold"   and UserInputService:IsKeyDown(Enum.KeyCode[activationBind]))
				or activationMode == "Always"
				or (activationMode == "Toggle" and State.Triggerbot["Key Toggled"])

			if tb["Enabled"] and State.Target and isActive then
				local fov     = tb["FOV"]
				local fovVec  = Vector3.new(fov.X, fov.Y, fov.Z)
				local rootCF  = State.Target.Character.HumanoidRootPart.CFrame
				local vel     = getPlayerVelocity(State.Target)
				local pred    = tb["Prediction"]
				local predPos = Vector3.new(
					rootCF.X + vel.X * pred.X,
					rootCF.Y + vel.Y * pred.Y,
					rootCF.Z + vel.Z * pred.Z
				)

				if tick() - State.Triggerbot["Last Click"] >= tb["Click Cooldown"]
					and raycastThroughBox(CFrame.new(predPos), fovVec)
					and hasLOS(State.Target.Character.Head.Position, { State.Target.Character, LocalPlayer.Character, Camera })
				then
					local equippedTool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
					if equippedTool and table.find(tb["Weapons"], equippedTool.Name) then
						equippedTool:Activate()
						State.Triggerbot["Last Click"] = tick()
					end
				end
			end
		end)

		task.spawn(function()
			if State.Target
				and isTargetValid(State.Target, Settings["Global"]["Check"]["Whilst a player is selected"]) == false
			then
				State.Target = nil
				disconnect("Health Changed")
			end
		end)

		task.spawn(function()
			if shared.Saved and Settings ~= shared.Saved then
				Settings = shared.Saved
			end
		end)
	end)
end)
