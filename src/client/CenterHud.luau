local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local State = require(script.Parent.HeroSelectState)

local Remotes = ReplicatedStorage.RemoteEvents
local UseDash = Remotes.UseDash
local StaminaUpdate = Remotes.StaminaUpdate

local scope = State.scope
local Children = Fusion.Children

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Crosshair shape
local LINE_WIDTH = 1
local LINE_HEIGHT = 10
local LINE_GAP = 6
local LINE_OPACITY = 0.1
local LINE_BORDER = 1
local LINE_BORDER_GAP = 1
local DOT_SIZE = 3
local DOT_OPACITY = 0.1
local DOT_BORDER = 1

-- Colors
local FILL_RED, FILL_GREEN, FILL_BLUE = 255, 255, 255
local BORDER_RED, BORDER_GREEN, BORDER_BLUE = 0, 0, 0

local FILL_COLOR = Color3.fromRGB(FILL_RED, FILL_GREEN, FILL_BLUE)
local BORDER_COLOR = Color3.fromRGB(BORDER_RED, BORDER_GREEN, BORDER_BLUE)

-- Stamina bar layout
local SEGMENT_WIDTH = 20
local SEGMENT_HEIGHT = 5
local SEGMENT_GAP = 3
local RECHARGE_TIME = 4 -- seconds per charge

----------------------------------------------------------------
-- Dash
----------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then -- your dash key
		UseDash:FireServer()
	end
end)

StaminaUpdate.OnClientEvent:Connect(function(charges, regenProgress)
	State.staminaCharges:set(charges)
	State.staminaRegenProgress:set(regenProgress)
end)

----------------------------------------------------------------
-- Crosshair
----------------------------------------------------------------

local function CrosshairLine(direction: "Top" | "Bottom" | "Left" | "Right")
	local size, anchorPoint, position

	if direction == "Top" then
		size = UDim2.fromOffset(LINE_WIDTH, LINE_HEIGHT)
		anchorPoint = Vector2.new(0.5, 1)
		position = UDim2.new(0.5, 0, 0.5, -LINE_GAP)
	elseif direction == "Bottom" then
		size = UDim2.fromOffset(LINE_WIDTH, LINE_HEIGHT)
		anchorPoint = Vector2.new(0.5, 0)
		position = UDim2.new(0.5, 0, 0.5, LINE_GAP)
	elseif direction == "Left" then
		size = UDim2.fromOffset(LINE_HEIGHT, LINE_WIDTH)
		anchorPoint = Vector2.new(1, 0.5)
		position = UDim2.new(0.5, -LINE_GAP, 0.5, 0)
	elseif direction == "Right" then
		size = UDim2.fromOffset(LINE_HEIGHT, LINE_WIDTH)
		anchorPoint = Vector2.new(0, 0.5)
		position = UDim2.new(0.5, LINE_GAP, 0.5, 0)
	end

	return scope:New("Frame")({
		Name = "Line" .. direction,
		Size = size,
		AnchorPoint = anchorPoint,
		Position = position,
		BackgroundColor3 = FILL_COLOR,
		BackgroundTransparency = LINE_OPACITY,
		BorderSizePixel = 0,

		[Children] = {
			scope:New("UIStroke")({
				Color = BORDER_COLOR,
				Thickness = LINE_BORDER,
				Transparency = LINE_BORDER_GAP == 0 and 0 or 0.2,
			}),
		},
	})
end

local function Crosshair()
	return scope:New("Frame")({
		Name = "Crosshair",
		Size = UDim2.fromOffset(0, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 10,

		[Children] = {
			scope:New("Frame")({
				Name = "Dot",
				Size = UDim2.fromOffset(DOT_SIZE, DOT_SIZE),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = FILL_COLOR,
				BackgroundTransparency = DOT_OPACITY,
				BorderSizePixel = 0,

				[Children] = {
					scope:New("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),
					scope:New("UIStroke")({
						Color = BORDER_COLOR,
						Thickness = DOT_BORDER,
					}),
				},
			}),

			CrosshairLine("Top"),
			CrosshairLine("Bottom"),
			CrosshairLine("Left"),
			CrosshairLine("Right"),
		},
	})
end

local reloadTimeLeft = scope:Value(0)

RunService.Heartbeat:Connect(function()
	if Fusion.peek(State.Reloading) then
		local elapsed = Workspace:GetServerTimeNow() - Fusion.peek(State.ReloadStartTime)
		local remaining = math.max(0, Fusion.peek(State.ReloadingTime) - elapsed)
		reloadTimeLeft:set(remaining)
	end
end)

local function Counter()
	return scope:New("TextLabel")({
		Name = "Counter",
		Size = UDim2.fromOffset(80, 30),
		Position = UDim2.fromScale(0.5, 0.6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 10,
		TextColor3 = Color3.fromRGB(255, 0, 0),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		

		Text = scope:Computed(function(use)
			return string.format("%.1f", use(reloadTimeLeft))
		end),

		Visible = scope:Computed(function(use)
			return use(State.Reloading)
		end),
	})
end

----------------------------------------------------------------
-- Stamina (segmented charges)
----------------------------------------------------------------

local function StaminaSegment(index: number)
	return scope:New("Frame")({
		Name = "Segment" .. index,
		Size = UDim2.fromOffset(SEGMENT_WIDTH, SEGMENT_HEIGHT),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,

		[Children] = {
			scope:New("UICorner")({
				CornerRadius = UDim.new(0, 3),
			}),

			-- fully charged fill
			scope:New("Frame")({
				Name = "Fill",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(255, 200, 60),
				BorderSizePixel = 0,
				Visible = scope:Computed(function(use)
					return use(State.staminaCharges) >= index
				end),

				[Children] = {
					scope:New("UICorner")({
						CornerRadius = UDim.new(0, 3),
					}),
				},
			}),

			-- partial regen fill for the next charging segment
			scope:New("Frame")({
				Name = "RegenFill",
				Position = UDim2.fromScale(0, 0),
				Size = scope:Computed(function(use)
					local charges = use(State.staminaCharges)
					if index == math.floor(charges) + 1 then
						return UDim2.fromScale(use(State.staminaRegenProgress), 1)
					end
					return UDim2.fromScale(0, 1)
				end),
				BackgroundColor3 = Color3.fromRGB(255, 200, 60),
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,

				[Children] = {
					scope:New("UICorner")({
						CornerRadius = UDim.new(0, 3),
					}),
				},
			}),
		},
	})
end

local function StaminaBar()
	return scope:New("Frame")({
		Name = "Stamina",
		Size = UDim2.fromOffset((SEGMENT_WIDTH * 3) + (SEGMENT_GAP * 2), SEGMENT_HEIGHT),
		Position = UDim2.new(0.5, 0, 1, -390),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,

		[Children] = {
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, SEGMENT_GAP),
			}),

			table.unpack((function()
				local segments = {}
				for i = 1, 3 do
					table.insert(segments, StaminaSegment(i))
				end
				return segments
			end)()),
		},
	})
end

----------------------------------------------------------------
-- Ammo
----------------------------------------------------------------

local function AmmoDisplay()
	return scope:New("Frame")({
		Name = "Ammo",
		Size = UDim2.fromOffset(140, 50),
		Position = UDim2.new(0.5, 0,1, -391),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,

		[Children] = {
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 0),
			}),

			scope:New("TextLabel")({
				Size = UDim2.fromOffset(40, 30),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					return tostring(use(State.currentAmmo))
				end),
				TextColor3 = FILL_COLOR,
				TextScaled = true,
				Font = Enum.Font.GothamBold,
			}),

			scope:New("TextLabel")({
				Size = UDim2.fromOffset(30, 20),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					return tostring(use(State.maxAmmo))
				end),
				TextColor3 = Color3.fromRGB(150, 150, 150),
				TextScaled = true,
				Font = Enum.Font.Gotham,
			}),
		},
	})
end

----------------------------------------------------------------
-- Data hookups
----------------------------------------------------------------

local gunConnections: {RBXScriptConnection} = {}

-- (re)binds the HUD to the current gun; called every time a new EquippedGun appears
local function bindGun(gun: Instance)
	for _, connection in gunConnections do
		connection:Disconnect()
	end
	table.clear(gunConnections)

	local function refresh()
		State.currentAmmo:set(gun:GetAttribute("Ammo") or 0)
		State.maxAmmo:set(gun:GetAttribute("MagSize") or 0)
		State.ReloadingTime:set(gun:GetAttribute("ReloadTime") or 0)
		local reloading = gun:GetAttribute("Reloading") or false
		State.Reloading:set(reloading)
		if reloading then
			State.ReloadStartTime:set(gun:GetAttribute("ReloadStartTime") or workspace:GetServerTimeNow())
		end
	end

	refresh()
	for _, attribute in { "Ammo", "MagSize", "Reloading", "ReloadStartTime", "ReloadTime" } do
		table.insert(gunConnections, gun:GetAttributeChangedSignal(attribute):Connect(refresh))
	end
end

-- watches a character for a gun being equipped at any time (respawn, hero change, late server equip)
local function watchCharacter(character: Model)
	local existing = character:FindFirstChild("EquippedGun")
	if existing then
		bindGun(existing)
	end
	character.ChildAdded:Connect(function(child)
		if child.Name == "EquippedGun" then
			bindGun(child)
		end
	end)
end

-- stamina regen loop, runs once for the whole client
RunService.Heartbeat:Connect(function(dt)
	local charges = Fusion.peek(State.staminaCharges)
	local max = Fusion.peek(State.maxStaminaCharges)

	if charges >= max then
		if Fusion.peek(State.staminaRegenProgress) ~= 0 then
			State.staminaRegenProgress:set(0)
		end
		return
	end

	local progress = Fusion.peek(State.staminaRegenProgress) + (dt / RECHARGE_TIME)
	if progress >= 1 then
		State.staminaCharges:set(charges + 1)
		State.staminaRegenProgress:set(0)
	else
		State.staminaRegenProgress:set(progress)
	end
end)

----------------------------------------------------------------
-- Root
----------------------------------------------------------------

----------------------------------------------------------------
-- Menu hint
----------------------------------------------------------------

local function MenuHint()
	return scope:New("TextLabel")({
		Name = "MenuHint",
		Size = UDim2.fromOffset(200, 24),
		Position = UDim2.new(1, -16, 1, -16), -- bottom right, 16px margin
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1, -- no background
		Text = "Press M for menu",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
end

local function CenterHud()
	player.CharacterAdded:Connect(function(character)
		UserInputService.MouseIconEnabled = false
		watchCharacter(character)
	end)
	if player.Character then
		watchCharacter(player.Character)
	end

	return scope:New("ScreenGui")({
		Name = "CenterHud",
		ResetOnSpawn = false,
		Parent = playerGui,
		IgnoreGuiInset = true,

		[Children] = {
			Crosshair(),
			
			StaminaBar(),
			AmmoDisplay(),
			Counter(),
			MenuHint(),
		},
	})
end

return CenterHud
