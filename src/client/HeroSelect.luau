local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local State = require(script.Parent.HeroSelectState)

local ConfirmHero = ReplicatedStorage.RemoteEvents.ConfirmHero
local GunRemote = ReplicatedStorage.RemoteEvents.GunRemote

local scope = State.scope
local Children = Fusion.Children

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local abilityCircles = {}
local activeTweens = {}
local animGeneration = 0
local lastClickTime = {}
local DOUBLE_CLICK_THRESHOLD = 0.4 -- seconds

local function animateCircles(circles, listLayout)
	for _, tween in activeTweens do
		tween:Cancel()
	end
	table.clear(activeTweens)

	animGeneration += 1
	local myGeneration = animGeneration

	listLayout.Padding = UDim.new(0, 105)

	for i, circle in circles do
		task.spawn(function()
			circle.BackgroundTransparency = 1
			task.wait(i * 0.05)

			if animGeneration ~= myGeneration then
				return
			end

			local bgTween = TweenService:Create(
				circle,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 0 }
			)

			local listTween = TweenService:Create(
				listLayout,
				TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Padding = UDim.new(0, 15) }
			)

			activeTweens["bg" .. i] = bgTween
			activeTweens["list" .. i] = listTween

			bgTween:Play()
			listTween:Play()
		end)
	end
end

local function updateViewport(viewportFrame: ViewportFrame, heroName: string?)
	for _, child in viewportFrame:GetChildren() do
		child:Destroy()
	end

	if heroName == nil then
		return
	end

	local model = ReplicatedStorage.Characters:FindFirstChild(heroName)
	if not model then
		warn("No model found for: " .. heroName)
		local ref = ReplicatedStorage.Characters.Ref:Clone()
		ref.Parent = viewportFrame

		local camera = Instance.new("Camera")
		camera.Parent = viewportFrame
		viewportFrame.CurrentCamera = camera

		local cf, size = ref:GetBoundingBox()
		local center = cf.Position
		local distance = size.Magnitude * 0.6
		camera.CFrame = CFrame.new(center + Vector3.new(0, 2.5, distance), center + Vector3.new(0, 2.5, 0))
		return
	end

	local clone = model:Clone()
	clone.Parent = viewportFrame

	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	local cf, size = clone:GetBoundingBox()
	local center = cf.Position
	local distance = size.Magnitude * 0.6
	camera.CFrame = CFrame.new(center + Vector3.new(0, 2.5, distance), center + Vector3.new(0, 2.5, 0))
end

local function HeroSelect()
	-- create these first so we can reference them
	local viewportFrame = scope:New("ViewportFrame")({
		Name = "CharacterPreview",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(-0.06, -0.25),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	local abilitiesLayout = scope:New("UIListLayout")({
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 15),
	})

	local abilitiesFrame = scope:New("Frame")({
		Name = "Abilities",
		Size = UDim2.fromScale(1, 0.2),
		Position = UDim2.fromScale(0, 0.78),
		BackgroundTransparency = 1,

		[Children] = {
			abilitiesLayout,

			table.unpack((function()
				local circles = {}
				for i = 1, 4 do
					local hovered = scope:Value(false)

					local tooltip = scope:New("Frame")({
						Name = "Tooltip",
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

					local circle = scope:New("ImageButton")({
						Name = "Ability" .. i,
						Size = UDim2.fromOffset(70, 70),
						BackgroundColor3 = scope:Computed(function(use)
							local abilities = use(State.selectedAbilities)
							local ability = abilities[i]
							if ability and ability.isUltimate then
								return Color3.fromRGB(80, 20, 20)
							else
								return Color3.fromRGB(30, 30, 40)
							end
						end),
						BackgroundTransparency = 0,
						Image = scope:Computed(function(use)
							local abilities = use(State.selectedAbilities)
							local ability = abilities[i]
							return ability and ability.image or ""
						end),

						[Fusion.OnEvent("MouseEnter")] = function()
							hovered:set(true)
						end,

						[Fusion.OnEvent("MouseLeave")] = function()
							hovered:set(false)
						end,

						[Children] = {
							scope:New("UICorner")({
								CornerRadius = UDim.new(1, 0),
							}),
							scope:New("UIStroke")({
								Color = scope:Computed(function(use)
									local abilities = use(State.selectedAbilities)
									local ability = abilities[i]
									if ability and ability.isUltimate then
										return Color3.fromRGB(200, 50, 50)
									else
										return Color3.fromRGB(80, 80, 100)
									end
								end),
								Thickness = 2,
							}),
							tooltip,
						},
					})

					abilityCircles[i] = circle
					table.insert(circles, circle)
				end
				return circles
			end)()),
		},
	})

	-- observers
	scope:Observer(State.selectedHero):onChange(function()
		updateViewport(viewportFrame, Fusion.peek(State.selectedHero))
		if Fusion.peek(State.selectedHero) ~= nil then
			animateCircles(abilityCircles, abilitiesLayout)
		end
	end)

	return scope:New("ScreenGui")({
		Name = "HeroSelect",
		ResetOnSpawn = false,
		Parent = playerGui,
		IgnoreGuiInset = true,

		[Children] = {
			scope:New("Frame")({
				Name = "Background",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(10, 10, 15),

				[Children] = {
					scope:New("TextLabel")({
						Name = "Title",
						Size = UDim2.fromScale(1, 0.08),
						Position = UDim2.fromScale(0, 0),
						BackgroundTransparency = 1,
						Text = "SELECT YOUR HERO",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.GothamBold,
					}),

					scope:New("ScrollingFrame")({
						Name = "HeroGrid",
						Size = UDim2.fromScale(0.40, 0.8),
						Position = UDim2.fromScale(0.01, 0.09),
						BackgroundTransparency = 1,
						ScrollBarThickness = 4,
						ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
						CanvasSize = UDim2.fromOffset(0, math.ceil(#State.heroes / 3) * 210),

						[Children] = {
							scope:New("UIPadding")({
								PaddingTop = UDim.new(0, 6),
								PaddingLeft = UDim.new(0, 6),
								PaddingRight = UDim.new(0, 6),
								PaddingBottom = UDim.new(0, 6),
							}),

							table.unpack((function()
								local cards = {}
								local cardWidth = 160
								local cardHeight = 200
								local padding = 10

								for i, hero in State.heroes do
									local col = (i - 1) % 3
									local row = math.floor((i - 1) / 3)

									table.insert(
										cards,
										scope:New("TextButton")({
											Name = hero.name,
											Text = "",
											AutoButtonColor = false,
											Position = UDim2.fromOffset(
												col * (cardWidth + padding) + cardWidth / 2,
												row * (cardHeight + padding) + cardHeight / 2
											),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Size = scope:Tween(
												scope:Computed(function(use)
													if use(State.hoveredHero) == hero.name then
														return UDim2.fromOffset(170, 210)
													else
														return UDim2.fromOffset(160, 200)
													end
												end),
												TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
											),
											BackgroundColor3 = scope:Tween(
												scope:Computed(function(use)
													if use(State.confirmedHero) == hero.name then
														return Color3.fromRGB(116, 255, 135) -- 0, 255, 34
													elseif use(State.selectedHero) == hero.name then
														return Color3.fromRGB(255, 226, 122)
													elseif use(State.hoveredHero) == hero.name then
														return Color3.fromRGB(50, 50, 70)
													else
														return Color3.fromRGB(30, 30, 40)
													end
												end),
												TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
											),

											[Fusion.OnEvent("MouseEnter")] = function()
												State.hoveredHero:set(hero.name)
											end,

											[Fusion.OnEvent("MouseLeave")] = function()
												State.hoveredHero:set(nil)
											end,

											[Fusion.OnEvent("MouseButton1Click")] = function()
												local now = tick()
												local last = lastClickTime[hero.name] or 0

												if
													Fusion.peek(State.selectedHero) == hero.name
													and (now - last) < DOUBLE_CLICK_THRESHOLD
												then
													State.confirmedHero:set(hero.name)
													ConfirmHero:FireServer(hero.name)
													GunRemote:FireServer(hero.name)
												else
													State.selectedHero:set(hero.name)
												end

												lastClickTime[hero.name] = now
											end,

											[Children] = {
												scope:New("TextLabel")({
													Size = UDim2.fromScale(1, 0.2),
													Position = UDim2.fromScale(0, 0.8),
													BackgroundTransparency = 0.5,
													BackgroundColor3 = Color3.fromRGB(0, 0, 0),
													Text = hero.name,
													TextColor3 = Color3.fromRGB(255, 255, 255),
													TextScaled = true,
													Font = Enum.Font.GothamBold,
												}),

												scope:New("TextLabel")({
													Size = UDim2.fromScale(1, 0.12),
													Position = UDim2.fromScale(0, 0.68),
													BackgroundTransparency = 1,
													Text = hero.role,
													TextColor3 = Color3.fromRGB(180, 180, 180),
													TextScaled = true,
													Font = Enum.Font.Gotham,
												}),

												scope:New("UIStroke")({
													ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
													Color = scope:Tween(
														scope:Computed(function(use)
															if use(State.confirmedHero) == hero.name then
																return Color3.fromRGB(0, 163, 0)
															elseif use(State.selectedHero) == hero.name then
																return Color3.fromRGB(255, 200, 0)
															elseif use(State.hoveredHero) == hero.name then
																return Color3.fromRGB(255, 255, 255)
															else
																return Color3.fromRGB(30, 30, 40)
															end
														end),
														TweenInfo.new(
															0.2,
															Enum.EasingStyle.Quad,
															Enum.EasingDirection.Out
														)
													),
													Thickness = scope:Tween(
														scope:Computed(function(use)
															if use(State.confirmedHero) == hero.name then
																return 2
															elseif use(State.selectedHero) == hero.name then
																return 2
															elseif use(State.hoveredHero) == hero.name then
																return 2
															else
																return 0
															end
														end),
														TweenInfo.new(
															0.2,
															Enum.EasingStyle.Quad,
															Enum.EasingDirection.Out
														)
													),
												}),
											},
										})
									)
								end
								return cards
							end)()),
						},
					}),

					scope:New("Frame")({
						Name = "HeroPanel",
						Size = UDim2.fromScale(0.55, 0.9),
						Position = UDim2.fromScale(0.43, 0.05),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,

						[Children] = {
							viewportFrame,

							scope:New("TextLabel")({
								Name = "HeroName",
								Size = UDim2.fromScale(1, 0.07),
								Position = UDim2.fromScale(0, 0.05),
								BackgroundTransparency = 1,
								Text = scope:Computed(function(use)
									local selected = use(State.selectedHero)
									return selected ~= nil and selected or "Select a hero"
								end),
								TextColor3 = Color3.fromRGB(255, 255, 255),
								TextScaled = true,
								Font = Enum.Font.GothamBold,
							}),

							scope:New("TextLabel")({
								Name = "Description",
								Size = UDim2.fromScale(1, 0.03),
								Position = UDim2.fromScale(0, 0.15),
								BackgroundTransparency = 1,
								Text = scope:Computed(function(use)
									local heroData = use(State.selectedHeroData)
									return heroData ~= nil and heroData.description or ""
								end),
								TextColor3 = Color3.fromRGB(255, 255, 255),
								TextScaled = true,
								Font = Enum.Font.GothamBold,
							}),

							abilitiesFrame,
						},
					}),
				},
			}),
		},
	})
end

return HeroSelect
