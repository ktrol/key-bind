local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local HeroData = require(ReplicatedStorage.Shared.HeroData)
local State = require(script.Parent.HeroSelectState)
local Fusion = require(ReplicatedStorage.Packages.fusion)

local KEYBINDS = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
}

local cooldowns = { -- Tracks when each ability was used
	0,
	0,
	0,
	0,
}

local function getHeroData(heroName)
	for _, hero in ipairs(HeroData) do
		if hero.name == heroName then
			return hero
		end
	end
	return nil
end
local scope = State.scope

scope:Observer(State.confirmedHero):onChange(function()
    for i = 1, 4 do
		
        cooldowns[i] = 0
        State.abilityCooldowns[i]:set(0)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local abilityIndex = KEYBINDS[input.KeyCode]
	if not abilityIndex then
		return
	end

	local heroName = Fusion.peek(State.confirmedHero)
	if not heroName then
		warn("No hero confirmed yet")
		return
	end

	local heroData = getHeroData(heroName)
	if not heroData then
		warn("Hero data not found:", heroName)
		return
	end

	local ability = heroData.abilities[abilityIndex]
	if not ability then
		return
	end

	local cooldown = ability.Cooldown or 0
	local now = tick()

	if now - cooldowns[abilityIndex] < cooldown then
		local remaining = cooldown - (now - cooldowns[abilityIndex])
		print(("Ability %d on cooldown: %.1fs remaining"):format(abilityIndex, remaining))
		return
	end

	cooldowns[abilityIndex] = now

	print("Used ability:", ability.name)

	ReplicatedStorage.RemoteEvents.UseAbility:FireServer(abilityIndex, heroName)
	

	cooldowns[abilityIndex] = now
	print("Used ability:", ability.name)
	ReplicatedStorage.RemoteEvents.UseAbility:FireServer(abilityIndex, heroName)

	-- start cooldown countdown
	local duration = ability.Cooldown
	task.spawn(function()
		while true do
			local elapsed = tick() - cooldowns[abilityIndex]
			local remaining = duration - elapsed

			if remaining <= 0 then
				State.abilityCooldowns[abilityIndex]:set(0)
				break
			end

			State.abilityCooldowns[abilityIndex]:set(remaining)
			task.wait(0.1)
		end
	end)
end)
