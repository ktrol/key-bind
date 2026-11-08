local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")


local Remotes = ReplicatedStorage.RemoteEvents
local FireGun = Remotes:WaitForChild("FireGun")
local ReloadGun = Remotes:WaitForChild("ReloadGun")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local lastFireTime = 0

local function getEquippedGun()
	local character = player.Character
	return character and character:FindFirstChild("EquippedGun")
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local gun = getEquippedGun()
		if not gun then
			return
		end

		local fireRate = gun:GetAttribute("FireRate") or 0.1
		local now = os.clock()
		if now - lastFireTime < fireRate or gun:GetAttribute("Reloading") then
			return
		end
		lastFireTime = now

		FireGun:FireServer(mouse.Hit.Position)

	elseif input.KeyCode == Enum.KeyCode.R then
		ReloadGun:FireServer()
		
	end
end)

-- draw other players' shots
--FireGun.OnClientEvent:Connect(function(shooter, origin, endPoint)
	--local part = Instance.new("Part")
	--part.Anchored = true
	--part.CanCollide = false
	--part.Material = Enum.Material.Neon
    --part.Color = Color3.fromRGB(255, 240, 150)
    --part.Size = Vector3.new(0.1, 0.1, (endPoint - origin).Magnitude)
	--.CFrame = CFrame.new(origin, endPoint) * CFrame.new(0, 0, -part.Size.Z / 2)
	--part.Parent = Workspace
--	Debris:AddItem(part, 0.1)
--end)


