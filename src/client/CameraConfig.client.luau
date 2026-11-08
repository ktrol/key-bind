local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- tune these to taste
local SHOULDER_OFFSET = Vector3.new(2.2, 1.8, 0) -- right, up, (forward unused here)
local CAMERA_DISTANCE = 8 -- how far behind the character
local MIN_PITCH = -70
local MAX_PITCH = 80

local yaw = 0
local pitch = 0

camera.CameraType = Enum.CameraType.Scriptable

UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
UserInputService.MouseIconEnabled = false -- you already hide this for your crosshair

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	-- don't spin the camera while the mouse is free (menu open)
	if gameProcessed or UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local sensitivity = 0.2
		yaw -= input.Delta.X * sensitivity
		pitch = math.clamp(pitch - input.Delta.Y * sensitivity, MIN_PITCH, MAX_PITCH)
	end
end)

RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	-- build look rotation from yaw/pitch
	local lookCFrame = CFrame.new(rootPart.Position)
		* CFrame.Angles(0, math.rad(yaw), 0)
		* CFrame.Angles(math.rad(pitch), 0, 0)

	-- shoulder offset applied in the camera's local space (not world space)
	-- so it stays "to the right" no matter which way you're facing
	local offsetCFrame = lookCFrame * CFrame.new(SHOULDER_OFFSET.X, SHOULDER_OFFSET.Y, CAMERA_DISTANCE)

	camera.CFrame = offsetCFrame

	-- rotate the character to face camera yaw (so aiming feels correct)
	rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(yaw), 0)
end)