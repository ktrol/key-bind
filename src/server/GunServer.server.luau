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

-- equips the player's saved hero gun onto their current character
local function equipSavedHero(player: Player)
	local profile = ProfileManager:WaitForProfile(player)
	local heroName = profile and profile.Data.CurrentCharacter
	if heroName and heroName ~= "" and player.Character then
		task.wait(0.5) -- let R15 parts finish loading
		GunManager.Equip(player, heroName)
	end
end

-- re-equip on every respawn, and also for a character that spawned before this script connected
local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function()
		equipSavedHero(player)
	end)
	if player.Character then
		task.spawn(equipSavedHero, player)
	end
end

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)
