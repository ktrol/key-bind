

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataTemplate = require(ServerScriptService.Server.ProfileLib.DataTemplate)
local ProfileService = require(ReplicatedStorage.Packages.profileservice)

local ConfirmHero = ReplicatedStorage.RemoteEvents.ConfirmHero
local HeroData = require(ReplicatedStorage.Shared.HeroData)

local DATASTORE_NAME = "PlayerData"

local ProfileStore = ProfileService.GetProfileStore(
	DATASTORE_NAME,
	DataTemplate
)

local Profiles = {}

local ProfileManager = {}

--// Internal function to load a player's profile
local function LoadProfile(player)
	local profile = ProfileStore:LoadProfileAsync(
		`Player_{player.UserId}`,
		"ForceLoad"
	)

	if not profile then
		player:Kick("Failed to load your data.")
		return
	end

	-- GDPR compliance
	profile:AddUserId(player.UserId)

	-- Fill in missing values from DataTemplate
	profile:Reconcile()

	-- Handle profile being loaded elsewhere
	profile:ListenToRelease(function()
		Profiles[player] = nil

		if player.Parent == Players then
			player:Kick("Your data was loaded on another server.")
		end
	end)

	-- Player left while loading
	if player.Parent ~= Players then
		profile:Release()
		return
	end

	Profiles[player] = profile
end

--// Internal function to unload a player's profile
local function UnloadProfile(player)
	local profile = Profiles[player]

	if profile then
		profile:Release()
		Profiles[player] = nil
	end
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function ProfileManager:GetProfile(player)
	return Profiles[player]
end

function ProfileManager:GetData(player)
	local profile = Profiles[player]

	if profile then
		return profile.Data
	end

	return nil
end

function ProfileManager:IsLoaded(player)
	return Profiles[player] ~= nil
end

function ProfileManager:WaitForProfile(player)
	while player.Parent and not Profiles[player] do
		task.wait(0.1)
	end

	return Profiles[player]
end

----------------------------------------------------------------
-- Player connections
----------------------------------------------------------------

for _, player in Players:GetPlayers() do
	task.spawn(LoadProfile, player)
end

Players.PlayerAdded:Connect(function(player)
    task.spawn(LoadProfile, player)
end)


game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		UnloadProfile(player)
	end
end)

-- save confirmed hero when client fires
ConfirmHero.OnServerEvent:Connect(function(player, heroName)
	
    -- validate hero name is real
    local validHero = false
    for _, hero in HeroData do
        if hero.name == heroName then
            validHero = true
            break
        end
    end
	
    if not validHero then
        warn(player.Name .. " sent invalid hero name: " .. tostring(heroName))
        return
    end
	
    -- wait for profile to load instead of just getting it
    local profile = ProfileManager:WaitForProfile(player)
    if not profile then
        warn("Profile never loaded for " .. player.Name)
        return
    end
	
    profile.Data.CurrentCharacter = heroName
    print(player.Name .. " saved hero: " .. heroName)
end)

-- send saved hero back to client on load
Players.PlayerAdded:Connect(function(player)
    local profile = ProfileManager:WaitForProfile(player)
    if profile and profile.Data.CurrentCharacter ~= "" then
        ConfirmHero:FireClient(player, profile.Data.CurrentCharacter)
    end
end)

Players.PlayerRemoving:Connect(UnloadProfile)

return ProfileManager