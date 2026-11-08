local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.fusion)
local ConfirmHero = ReplicatedStorage.RemoteEvents.ConfirmHero


local scope = Fusion:scoped()
local State = {}

--HeroSelect
State.scope = scope
State.heroes = require(ReplicatedStorage.Shared.HeroData)
State.hoveredHero = scope:Value(nil)
State.selectedHero = scope:Value(nil)
State.confirmedHero = scope:Value(nil)
State.currentAmmo = scope:Value(0)
State.Reloading = scope:Value(false)
State.ReloadStartTime = scope:Value(0)
State.ReloadingTime = scope:Value(0)
State.maxAmmo = scope:Value(0)
State.maxStaminaCharges = scope:Value(3)
State.staminaCharges = scope:Value(3)      -- how many full charges available
State.staminaRegenProgress = scope:Value(1) -- 0-1 progress of the NEXT charge refilling

-- Settings tabs
State.settingsTab = scope:Value("Cursor")

State.abilityCooldowns = {
    scope:Value(0), -- ability 1 cooldown remaining
    scope:Value(0), -- ability 2
    scope:Value(0), -- ability 3
    scope:Value(0), -- ability 4
}

--Hud
State.hoverHud = scope:Value(nil)


State.hasConfirmed = scope:Computed(function(use)
    return use(State.confirmedHero) ~= nil
end)

State.selectedHeroData = scope:Computed(function(use)
    local name = use(State.selectedHero)
    if name == nil then return nil end

    for _, hero in State.heroes do
        if hero.name == name then
            return hero
        end
    end

    return nil
end)


State.selectedAbilities = scope:Computed(function(use)
    local heroData = use(State.selectedHeroData)
    if heroData == nil then return {} end
    return heroData.abilities
end)

-- listen for saved hero from server on join
ConfirmHero.OnClientEvent:Connect(function(heroName)
    State.confirmedHero:set(heroName)
    State.selectedHero:set(heroName)
    print("Loaded saved hero: " .. heroName)
end)

return State