local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local GunManager = require(ReplicatedStorage.Shared.GunManager)
local ProfileManager = require(ServerScriptService.Server.ProfileMain) -- adjust to your actual path

local GunRemote = ReplicatedStorage.RemoteEvents.GunRemote

-- fired when a player confirms a hero
GunRemote.OnServerEvent:Connect(function(player, heroName)
	if typeof(heroName) ~= "string" then
		return
	end
	if not GunManager.GetHeroData(heroName) then
		warn(player.Name .. " requested invalid hero gun: " .. tostring(heroName))
		return
	end
	GunManager.Equip(player, heroName)
end)

-- re-equip on every respawn using their saved hero
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local profile = ProfileManager:WaitForProfile(player)
		local heroName = profile and profile.Data.CurrentCharacter
		if heroName and heroName ~= "" then
			task.wait(0.5) -- let R15 parts finish loading
			GunManager.Equip(player, heroName)
		end
	end)
end)