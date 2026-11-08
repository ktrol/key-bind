local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local State = require(script.Parent.HeroSelectState)

local scope = State.scope
local Children = Fusion.Children

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hoveredStates = {} -- track all button hover states

local function EscMenu(UIManager)
	local isOpen = scope:Value(false)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.M then
			if UIManager.getCurrent() == "EscMenu" then
				UIManager.hide("EscMenu") -- resume, hide everything
				isOpen:set(false)
				UIManager.show("HUD")
			else
				UIManager.show("EscMenu") -- open menu from anywhere
				isOpen:set(true)
			end
		end
	end)
	scope:Observer(isOpen):onChange(function()
		if not Fusion.peek(isOpen) then
			for _, hovered in hoveredStates do
				hovered:set(false)
			end
		end
	end)

	local function MenuButton(config: {
		label: string,
		size: number?,
		color: Color3?,
		action: () -> (),
	})
		local hovered = scope:Value(false)
		table.insert(hoveredStates, hovered) -- register it
		local fontSize = config.size or 28
		local defaultColor = config.color or Color3.fromRGB(255, 255, 255)

		return scope:New("TextButton")({

			Name = config.label,
			Size = UDim2.fromOffset(400, fontSize + 20),
			BackgroundTransparency = 1,
			Text = config.label,
			TextColor3 = scope:Tween(
				scope:Computed(function(use)
					if use(hovered) then
						return Color3.fromRGB(26, 196, 11)
					else
						return defaultColor
					end
				end),
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			),
			TextSize = fontSize,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,

			[Fusion.OnEvent("MouseEnter")] = function()
				hovered:set(true)
			end,

			[Fusion.OnEvent("MouseLeave")] = function()
				hovered:set(false)
			end,

			[Fusion.OnEvent("MouseButton1Click")] = config.action,
		})
	end

	return scope:New("ScreenGui")({
		Name = "EscMenu",
		ResetOnSpawn = false,
		Parent = playerGui,
		IgnoreGuiInset = true,
		Enabled = scope:Computed(function(use)
			return use(isOpen)
		end),

		[Children] = {
			-- dark overlay
			scope:New("Frame")({
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.4,
				ZIndex = 1,
			}),

			-- left side menu
			scope:New("Frame")({
				Name = "MenuItems",
				Size = UDim2.fromScale(0.35, 1),
				Position = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				ZIndex = 2,

				[Children] = {
					scope:New("UIPadding")({
						PaddingLeft = UDim.new(0, 60),
						PaddingBottom = UDim.new(0, 40),
					}),

					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						VerticalAlignment = Enum.VerticalAlignment.Bottom,
						Padding = UDim.new(0, 8),
					}),

					-- main buttons
					MenuButton({
						label = "SWAP HERO",
						size = 42,
						action = function()
							isOpen:set(false)
							UIManager.show("HeroSelect")
						end,
					}),

					MenuButton({
						label = "SETTINGS",
						size = 24,
						action = function()
							-- settings later
							isOpen:set(false)
							UIManager.show("Settings")
						end,
					}),
					MenuButton({
						label = "RESUME",
						size = 24,
						action = function()
							isOpen:set(false)
							UIManager.hide("EscMenu")
							UIManager.show("HUD")
						end,
					}),

					-- spacer
					scope:New("Frame")({
						Size = UDim2.fromOffset(0, 20),
						BackgroundTransparency = 1,
					}),
				},
			}),

			-- bottom left ESC hint
			scope:New("TextLabel")({
				Name = "EscHint",
				Size = UDim2.fromOffset(200, 30),
				Position = UDim2.new(0, 20, 1, -35),
				BackgroundTransparency = 1,
				Text = "[M] RESUME",
				TextColor3 = Color3.fromRGB(180, 180, 180),
				TextSize = 14,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2,
			}),
		},
	})
end

return EscMenu
