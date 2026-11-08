local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local State = require(script.Parent.HeroSelectState)

local scope = State.scope
local Children = Fusion.Children

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- map boundaries
local MAP_MIN = Vector2.new(-500, -500)
local MAP_MAX = Vector2.new(500, 500)
local MINIMAP_SIZE = 200 -- pixel size of minimap

local function worldToMinimap(worldPos: Vector3): UDim2
	local x = (worldPos.X - MAP_MIN.X) / (MAP_MAX.X - MAP_MIN.X)
	local z = (worldPos.Z - MAP_MIN.Y) / (MAP_MAX.Y - MAP_MIN.Y)
	x = math.clamp(x, 0, 1)
	z = math.clamp(z, 0, 1)
	return UDim2.new(x, -4, z, -4) -- offset by half dot size to center it
end

local function MiniMap()
	-- player dots container
	local dotsContainer = scope:New("Frame")({
		Name = "Dots",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 3,
	})

	-- track all player dots
	local playerDots: { [Player]: Frame } = {}

	local function createDot(targetPlayer: Player): Frame
		local isLocalPlayer = targetPlayer == player
		return scope:New("Frame")({
			Name = targetPlayer.Name,
			Size = UDim2.fromOffset(8, 8),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = isLocalPlayer and Color3.fromRGB(255, 255, 255) -- blue for local player
				or Color3.fromRGB(255, 80, 80), -- red for enemies
			ZIndex = 4,
			Parent = dotsContainer,

			[Children] = {
				scope:New("UICorner")({
					CornerRadius = UDim.new(1, 0),
				}),
				scope:New("UIStroke")({
					Color = Color3.fromRGB(0, 0, 0),
					Thickness = 1,
				}),
			},
		})
	end

	-- add dots for existing players
	for _, p in Players:GetPlayers() do
		playerDots[p] = createDot(p)
	end

	-- add dot when new player joins
	Players.PlayerAdded:Connect(function(p)
		playerDots[p] = createDot(p)
	end)

	-- remove dot when player leaves
	Players.PlayerRemoving:Connect(function(p)
		if playerDots[p] then
			playerDots[p]:Destroy()
			playerDots[p] = nil
		end
	end)

	-- update dot positions every frame
	RunService.Heartbeat:Connect(function()
		for p, dot in playerDots do
			local character = p.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					dot.Position = worldToMinimap(rootPart.Position)
				end
			end
		end
	end)

	return scope:New("ScreenGui")({
		Name = "MiniMap",
		ResetOnSpawn = false,
		Parent = playerGui,
		IgnoreGuiInset = true,

		[Children] = {
			scope:New("Frame")({
				Name = "Container",
				Size = UDim2.fromOffset(MINIMAP_SIZE, MINIMAP_SIZE),
				Position = UDim2.new(1, -220, 0, 20),
				BackgroundColor3 = Color3.fromRGB(15, 15, 20),
				BorderSizePixel = 0,
				ClipsDescendants = true,

				[Children] = {
					scope:New("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),

					scope:New("UIStroke")({
						Color = Color3.fromRGB(0, 0, 0),
						Thickness = 2,
					}),

					-- map background placeholder
					scope:New("ImageLabel")({
						Name = "MapBackground",
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Color3.fromRGB(30, 40, 30),
						Image = "", -- swap with real map image later
						ZIndex = 1,
						[Children] = {
							scope:New("UICorner")({
								CornerRadius = UDim.new(1, 0),
							}),
						},
					}),

					-- grid lines for placeholder
					scope:New("Frame")({
						Name = "GridH",
						Size = UDim2.fromScale(1, 0.01),
						Position = UDim2.fromScale(0, 0.5),
						BackgroundColor3 = Color3.fromRGB(50, 60, 50),
						ZIndex = 2,
					}),

					scope:New("Frame")({
						Name = "GridV",
						Size = UDim2.fromScale(0.01, 1),
						Position = UDim2.fromScale(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(50, 60, 50),
						ZIndex = 2,
					}),

					dotsContainer,
				},
			}),
		},
	})
end

return MiniMap
