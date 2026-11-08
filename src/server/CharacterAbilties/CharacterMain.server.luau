--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Maid = require(ReplicatedStorage.Packages:WaitForChild("maid"))
local HeroData = require(ReplicatedStorage.Shared.HeroData)

local ModuleFolder = script.Parent.CharacterModules
local CharacterRemote = ReplicatedStorage.RemoteEvents.UseAbility

-- types
type AbilityFunction = (player: Player) -> ()

type HeroModule = {
    [number]: AbilityFunction,
}

type PlayerState = {
    heroName: string,
    cooldowns: {[number]: number}, -- ability index -> last used tick
    maid: any,
}

-- per player state
local playerStates: {[Player]: PlayerState} = {}

-- get cooldown duration from HeroData
local function getAbilityCooldown(heroName: string, abilityIndex: number): number
    for _, hero in HeroData do
        if hero.name == heroName then
            local ability = hero.abilities[abilityIndex]
            if ability then
                return ability.Cooldown or 0
            end
        end
    end
    return 0
end

-- validate hero name exists in HeroData
local function isValidHero(heroName: string): boolean
    for _, hero in HeroData do
        if hero.name == heroName then
            return true
        end
    end
    return false
end

-- setup player state on join
local function onPlayerAdded(player: Player)
    local maid = Maid.new()

    playerStates[player] = {
        heroName = "",
        cooldowns = {
            [1] = 0,
            [2] = 0,
            [3] = 0,
            [4] = 0,
        },
        maid = maid,
    }

    -- cleanup on leave
    maid:GiveTask(function()
        playerStates[player] = nil
    end)
end

local function onPlayerRemoving(player: Player)
    local state = playerStates[player]
    if state then
        state.maid:DoCleaning()
    end
end

-- handle ability use
CharacterRemote.OnServerEvent:Connect(function(player: Player, abilityIndex: unknown, heroName: unknown)
    -- type validation
    if typeof(abilityIndex) ~= "number" then
        warn(player.Name .. " sent invalid abilityIndex type: " .. typeof(abilityIndex))
        return
    end

    if typeof(heroName) ~= "string" then
        warn(player.Name .. " sent invalid heroName type: " .. typeof(heroName))
        return
    end

    -- range validation
    if abilityIndex < 1 or abilityIndex > 4 then
        warn(player.Name .. " sent out of range abilityIndex: " .. abilityIndex)
        return
    end

    -- hero validation
    if not isValidHero(heroName) then
        warn(player.Name .. " sent invalid heroName: " .. heroName)
        return
    end

    -- get player state
    local state = playerStates[player]
    if not state then
        warn("No state found for: " .. player.Name)
        return
    end

    -- cooldown check
    local now = tick()
    local cooldownDuration = getAbilityCooldown(heroName, abilityIndex)
    local lastUsed = state.cooldowns[abilityIndex] or 0

    if now - lastUsed < cooldownDuration then
        local remaining = cooldownDuration - (now - lastUsed)
        warn(player.Name .. " ability " .. abilityIndex .. " on cooldown: " .. string.format("%.1f", remaining) .. "s remaining")
        return
    end

    -- get hero module
    local heroModule = ModuleFolder:FindFirstChild(heroName)
    if not heroModule then
        warn("No module found for hero: " .. heroName)
        return
    end

    local HeroAbilities: HeroModule = require(heroModule) :: HeroModule

    -- get ability function
    local abilityFn = HeroAbilities[abilityIndex]
    if not abilityFn then
        warn("No ability at index " .. abilityIndex .. " for hero: " .. heroName)
        return
    end

    -- update cooldown and fire ability
    state.cooldowns[abilityIndex] = now
    state.heroName = heroName

    task.spawn(function()
        abilityFn(player)
    end)
end)

-- player connections
for _, player in Players:GetPlayers() do
    task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)