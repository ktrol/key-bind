local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HeroData = require(ReplicatedStorage.Shared.HeroData)

local GunModels = ReplicatedStorage.Guns

local GunManager = {}

function GunManager.GetHeroData(heroName: string)
	for _, hero in HeroData do
		if hero.name == heroName then
			return hero
		end
	end
	return nil
end

-- clones + welds the correct gun onto a character, tags it with stats as attributes
function GunManager.Equip(player: Player, heroName: string)
	local character = player.Character
	if not character then
		return
	end

	local heroData = GunManager.GetHeroData(heroName)
	if not heroData then
		warn("GunManager.Equip: no hero data for " .. tostring(heroName))
		return
	end

	GunManager.Unequip(player)

	local template = GunModels:FindFirstChild(heroName) or GunModels:FindFirstChild("Ref")
	if not template then
		warn("GunManager.Equip: no gun model for " .. heroName .. " (and no Ref fallback)")
		return
	end

	local gun = template:Clone()
	gun.Name = "EquippedGun"

	local handle = gun:IsA("Model") and (gun.PrimaryPart or gun:FindFirstChild("Handle")) or gun
	if not handle then
		warn("GunManager.Equip: gun model has no Handle/PrimaryPart:", gun.Name)
		gun:Destroy()
		return
	end

	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not rightHand then
		warn("GunManager.Equip: character has no RightHand/Right Arm")
		gun:Destroy()
		return
	end

	if gun:IsA("Model") then
		gun.Parent = character
		local weld = Instance.new("Motor6D")
		weld.Name = "GunWeld"
		weld.Part0 = rightHand
		weld.Part1 = handle
		weld.C0 = CFrame.new(0, -0.2, -0.5) * CFrame.Angles(math.rad(-90), 0, 0) -- tune per gun model
		weld.Parent = rightHand
	else
		handle.Parent = character
		local weld = Instance.new("Weld")
		weld.Part0 = rightHand
		weld.Part1 = handle
		weld.C0 = CFrame.new(0, -0.2, -0.5) * CFrame.Angles(math.rad(-90), 0, 0)
		weld.Parent = rightHand
	end

	local gunConfig = heroData.Gun
	gun:SetAttribute("FireRate", gunConfig.fireRate)
	gun:SetAttribute("Spread", gunConfig.Spread)
	gun:SetAttribute("Range", gunConfig.Range)
	gun:SetAttribute("Recoil", gunConfig.Recoil)
	gun:SetAttribute("MagSize", gunConfig.MagSize)
	gun:SetAttribute("Ammo", gunConfig.MagSize)
	gun:SetAttribute("LastShotTime", 0)
	gun:SetAttribute("Reloading", false)
	gun:SetAttribute("DamagePerShot", gunConfig.DAMAGE_PER_SHOT)
	gun:SetAttribute("ReloadTime", gunConfig.RELOAD_TIME)

	return gun
end

function GunManager.Unequip(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild("EquippedGun")
	if old then
		old:Destroy()
	end
end

return GunManager
