local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local State = require(script.Parent.HeroSelectState)

local scope = State.scope
local Children = Fusion.Children

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TabNames = {
	"Cursor",
	"Display",
	
}

local function TabButton(name: string)
	local hovered = scope:Value(false)

	return scope:New("TextButton")({
		Name = name,
		Size = UDim2.fromScale(0.1,0.5),
		BackgroundTransparency = 1,
		Text = name,
		TextScaled = true,
		Font = Enum.Font.GothamBold,

		TextColor3 = scope:Tween(
			scope:Computed(function(use)
				if use(State.settingsTab) == name then
					return Color3.fromRGB(253, 228, 0)
				elseif use(hovered) then
					return Color3.fromRGB(200, 200, 200)
				else
					return Color3.fromRGB(140, 140, 140)
				end
			end),
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		),

		[Fusion.OnEvent("MouseEnter")] = function()
			hovered:set(true)
		end,

		[Fusion.OnEvent("MouseLeave")] = function()
			hovered:set(false)
		end,

		[Fusion.OnEvent("MouseButton1Click")] = function()
			State.settingsTab:set(name)
		end,

		[Children] = {
			scope:New("UIStroke")({
				Color = Color3.fromRGB(80, 80, 100),
				Thickness = 1,
				Transparency = scope:Tween(
					scope:Computed(function(use)
						return use(State.settingsTab) == name and 0 or 0.7
					end),
					TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				),
			}),
		},
	})
end

local function TabContent(name: string)
	return scope:New("Frame")({
		Name = name .. "Content",
		Size = UDim2.fromScale(1, 0.9),
		Position = UDim2.fromScale(0, 0.1),
		BackgroundTransparency = 1,
		Visible = scope:Computed(function(use)
			return use(State.settingsTab) == name
		end),

		[Children] = {
			scope:New("TextLabel")({
				Size = UDim2.fromScale(1, 0.2),
				BackgroundTransparency = 1,
				Text = name .. " settings go here",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Font = Enum.Font.Gotham,
			}),
		},
	})
end

local function Settings()
	return scope:New("ScreenGui")({
		Name = "Settings",
		ResetOnSpawn = false,
		Parent = playerGui,
		IgnoreGuiInset = true,

		[Children] = {
			scope:New("Frame")({
				Name = "SettingsFrame",
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0, 0),
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				BorderSizePixel = 0,

				[Children] = {
					scope:New("Frame")({
						Name = "Header",
						Size = UDim2.fromScale(1, 0.1),
						BackgroundTransparency = 1,

						[Children] = {
							scope:New("UIListLayout")({
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Padding = UDim.new(0, 5),
							}),

							table.unpack((function()
								local buttons = {}
								for _, name in TabNames do
									table.insert(buttons, TabButton(name))
								end
								return buttons
							end)()),
						},
					}),

					table.unpack((function()
						local contents = {}
						for _, name in TabNames do
							table.insert(contents, TabContent(name))
						end
						return contents
					end)()),
				},
			}),
		},
	})
end

return Settings