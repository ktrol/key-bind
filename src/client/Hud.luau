local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local State = require(script.Parent.HeroSelectState)

local scope = State.scope
local Children = Fusion.Children

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function HUD()
	return scope:New("ScreenGui")({
		Name = "HUD",
		ResetOnSpawn = false,
		Parent = playerGui,
		IgnoreGuiInset = true,

		[Children] = {
			-- ability bar anchor frame
			scope:New("Frame")({
				Name = "AbilityBar",
				Size = UDim2.fromOffset(400, 100),
				Position = UDim2.new(0.5, 0, 1, -120),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,

				[Children] = {
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 10),
					}),

					table.unpack((function()
						local buttons = {}
						local keybinds = { "1", "2", "3", "4" }

						for i = 1, 4 do
							local isUltimate = i == 4
							local hovered = scope:Value(false)
							local AbilityHud = scope:New("Frame")({
								Name = "AbilityHud",
								Size = UDim2.fromOffset(180, 60),
								Position = UDim2.new(0.5, 0, 0, -70),
								AnchorPoint = Vector2.new(0.5, 0),
								BackgroundColor3 = Color3.fromRGB(20, 20, 30),
								BorderSizePixel = 0,
								Visible = scope:Computed(function(use)
									return use(hovered)
								end),
								ZIndex = 10,

								[Children] = {
									scope:New("UICorner")({
										CornerRadius = UDim.new(0, 6),
									}),
									scope:New("UIStroke")({
										Color = Color3.fromRGB(80, 80, 100),
										Thickness = 1,
									}),
									scope:New("TextLabel")({
										Size = UDim2.fromScale(1, 0.5),
										Position = UDim2.fromScale(0, 0),
										BackgroundTransparency = 1,
										Text = scope:Computed(function(use)
											local abilities = use(State.selectedAbilities)
											local ability = abilities[i]
											return ability and ability.name or "Invalid Character"
										end),
										TextColor3 = Color3.fromRGB(255, 255, 255),
										TextScaled = true,
										Font = Enum.Font.GothamBold,
									}),
									scope:New("TextLabel")({
										Size = UDim2.fromScale(1, 0.5),
										Position = UDim2.fromScale(0, 0.5),
										BackgroundTransparency = 1,
										Text = scope:Computed(function(use)
											local abilities = use(State.selectedAbilities)
											local ability = abilities[i]
											return ability and ability.description or "None"
										end),
										TextColor3 = Color3.fromRGB(180, 180, 180),
										TextScaled = true,
										Font = Enum.Font.Gotham,
									}),
								},
							})

							table.insert(
								buttons,
								scope:New("ImageButton")({

									Name = "Ability" .. i,

									BackgroundColor3 = isUltimate and Color3.fromRGB(60, 15, 15)
										or Color3.fromRGB(25, 25, 35),

									[Fusion.OnEvent("MouseEnter")] = function()
										hovered:set(true)
										State.hoverHud:set(i)
									end,

									[Fusion.OnEvent("MouseLeave")] = function()
										hovered:set(false)
										State.hoverHud:set(nil)
									end,

									Size = scope:Tween(
										scope:Computed(function(use)
											if use(State.hoverHud) == i then
												return UDim2.fromOffset(100, 100)
											else
												return UDim2.fromOffset(80, 80)
											end
										end),
										TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
									),

									[Children] = {
										scope:New("UICorner")({
											CornerRadius = UDim.new(0, 8),
										}),

										scope:New("UIStroke")({
											Color = isUltimate and Color3.fromRGB(200, 50, 50)
												or Color3.fromRGB(80, 80, 100),
											Thickness = 2,
										}),

										-- ability image
										scope:New("ImageLabel")({
											Name = "Icon",
											Size = UDim2.fromScale(1, 1),
											BackgroundTransparency = 1,
											Image = scope:Computed(function(use)
												local abilities = use(State.selectedAbilities)
												local ability = abilities[i]
												return ability and ability.image or ""
											end),
										}),

										-- keybind hint
										scope:New("TextLabel")({
											Name = "Keybind",
											Size = UDim2.fromOffset(20, 20),
											Position = UDim2.fromOffset(4, 4),
											BackgroundTransparency = 1,
											Text = keybinds[i],
											TextColor3 = Color3.fromRGB(180, 180, 180),
											TextScaled = true,
											Font = Enum.Font.GothamBold,
										}),
										scope:New("Frame")({
											Name = "CooldownOverlay",
											Size = scope:Computed(function(use)
												local remaining = use(State.abilityCooldowns[i])
												local abilities = use(State.selectedAbilities)
												local ability = abilities[i]
												local duration = ability and ability.Cooldown or 1
												local progress = math.clamp(remaining / duration, 0, 1)
												return UDim2.fromScale(1, progress)
											end),
											AnchorPoint = Vector2.new(0, 1), -- anchor to BOTTOM
											Position = UDim2.fromScale(0, 1), -- start from bottom
											BackgroundColor3 = Color3.fromRGB(0, 0, 0),
											BackgroundTransparency = 0.4,
											ZIndex = 2,
											[Children] = {
												scope:New("UICorner")({
													CornerRadius = UDim.new(0, 8),
												}),
											},
										}),

										scope:New("TextLabel")({
											Name = "Countdown",
											Size = UDim2.fromScale(.5,.5),
											BackgroundTransparency = 1,
											Text = scope:Computed(function(use)
												local remaining = use(State.abilityCooldowns[i])
												if remaining <= 0 then
													return ""
												end
												return string.format("%.1f", remaining)
											end),
											Position = UDim2.fromScale(0.25, 0.25),
											TextColor3 = Color3.fromRGB(255, 255, 255),
											TextScaled = true,
											Font = Enum.Font.GothamBold,
											ZIndex = 3,
											Visible = scope:Computed(function(use)
												return use(State.abilityCooldowns[i]) > 0
											end),
											[Children] = {
												scope:New("UIStroke")({
													ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
													Thickness = 2,
												})
											}
										}),
										AbilityHud,
									},
								})
							)
						end

						return buttons
					end)()),
				},
			}),
		},
	})
end

return HUD
