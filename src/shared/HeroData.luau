export type Ability = {
	name: string,
	description: string,
	image: string,
	isUltimate: boolean?,
	Cooldown: number,
}

export type gunExport = {
	fireRate: number,
	Spread: number,
	Range: number,
	Recoil: number,
	MagSize : number,
	DAMAGE_PER_SHOT: number,
	RELOAD_TIME: number,
}

export type Hero = {
	name: string,
	role: string,
	description: string,
	abilities: {Ability},
	Gun: {gunExport}
}

local HeroData: {Hero} = {
	{
		name = "Whisper",
		role = "Assassin",
		description = "A silent, deadly hunter.",
		abilities = {
			{ name = "Unknown", description = "25s of invisibility on map. Footstep sounds and attacks are silenced.", image = "", isUltimate = false, Cooldown = 25 },
			{ name = "Pump Fake", description = "Deploy a decoy to confuse enemies.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Alert", description = "Spot and reveal an enemy's location.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Tunnel Vision", description = "See through objects and walls.", image = "", isUltimate = true, Cooldown = 40 },
		},
		Gun = {
			fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Blades",
		role = "Carry",
		description = "A swift melee duelist.",
		abilities = {
			{ name = "Ricochet", description = "Deflect incoming projectiles and abilities.", image = "", isUltimate = false, Cooldown = 12 },
			{ name = "Dance", description = "Enter a flow state slowing melee and abilities for 10-15s.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Mumba", description = "Hide in plain sight. Movement cancels the ability.", image = "", isUltimate = false, Cooldown = 18 },
			{ name = "Cut Throat", description = "Shoot a sphere of blades from your body in all directions.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
			fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Onyx",
		role = "Tank",
		description = "An unstoppable armored brawler.",
		abilities = {
			{ name = "Bully", description = "Swing a rock chain around in a circle for 10s.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Root", description = "Sprout a boulder platform from the terrain onto the enemy.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Pinch", description = "Spawn stone body armor for 10s.", image = "", isUltimate = false, Cooldown = 25 },
			{ name = "Bone Crush", description = "Enlarge hands and smack together causing a sonic boom wave of linear damage.", image = "", isUltimate = true, Cooldown = 50 },
		},
		Gun = {
			fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Domesk",
		role = "Tank",
		description = "A massive shield-bearing juggernaut.",
		abilities = {
			{ name = "No Weapons!", description = "Spawn military soldiers to fight for you for 8s.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Turtle", description = "Create a soul shield that can be thrown as a projectile for 10s.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Leap", description = "Jump and throw a spirit ball with splash damage.", image = "", isUltimate = false, Cooldown = 12 },
			{ name = "Charge", description = "Rush forward creating a radius that slows but does not damage.", image = "", isUltimate = true, Cooldown = 40 },
		},
		Gun = {
		fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Chopper",
		role = "Jungler",
		description = "A brutal close-range fighter.",
		abilities = {
			{ name = "Mag Dump", description = "25s of full auto with no direct reload.", image = "", isUltimate = false, Cooldown = 30 },
			{ name = "FMJ", description = "Instantly break any enemy applied shield.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Double Tap", description = "Boost damage 2x for 15s.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Aim Assist", description = "Free aim bullets that track to enemies for 25s.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
			fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Monger",
		role = "Support",
		description = "A cunning battlefield manipulator.",
		abilities = {
			{ name = "Slash", description = "Triple melee slash with a heavy effect. 1 minute cooldown.", image = "", isUltimate = false, Cooldown = 60 },
			{ name = "Hide & Sneak", description = "Two flashes, one through walls and one that doesn't. Silent footsteps.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Pick Pocket", description = "Land a melee that steals points from the enemy team.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Fair Play", description = "Flip the enemy team's map for 40s causing confusion. 4 minute cooldown.", image = "", isUltimate = true, Cooldown = 240 },
		},
		Gun = {
			fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Pierce",
		role = "Carry",
		description = "A long-range precision marksman.",
		abilities = {
			{ name = "Ability 1", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Ability 2", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Ability 3", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Ability 4", description = "Placeholder.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
		fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Juda",
		role = "Assassin",
		description = "A treacherous backstabbing rogue.",
		abilities = {
			{ name = "Ability 1", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Ability 2", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Ability 3", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Ability 4", description = "Placeholder.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
			fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Yuvid",
		role = "Support",
		description = "A mysterious arcane healer.",
		abilities = {
			{ name = "Ability 1", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Ability 2", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Ability 3", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Ability 4", description = "Placeholder.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
		fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Triyak",
		role = "Jungler",
		description = "A feral beast of the wilds.",
		abilities = {
			{ name = "Ability 1", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Ability 2", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Ability 3", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Ability 4", description = "Placeholder.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
		fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Grind",
		role = "Carry",
		description = "A relentless aggressive scrapper.",
		abilities = {
			{ name = "Ability 1", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Ability 2", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Ability 3", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Ability 4", description = "Placeholder.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
			fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Lepa",
		role = "Support",
		description = "A nimble evasive trickster.",
		abilities = {
			{ name = "Ability 1", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Ability 2", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Ability 3", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Ability 4", description = "Placeholder.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
			fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Terror",
		role = "Tank",
		description = "A fear-inducing powerhouse.",
		abilities = {
			{ name = "Ability 1", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Ability 2", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Ability 3", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Ability 4", description = "Placeholder.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
			fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Vermdom",
		role = "Jungler",
		description = "A venomous predator.",
		abilities = {
			{ name = "Ability 1", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Ability 2", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Ability 3", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Ability 4", description = "Placeholder.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
		fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
	{
		name = "Rider",
		role = "Carry",
		description = "A high-speed momentum fighter.",
		abilities = {
			{ name = "Ability 1", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 10 },
			{ name = "Ability 2", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 15 },
			{ name = "Ability 3", description = "Placeholder.", image = "", isUltimate = false, Cooldown = 20 },
			{ name = "Ability 4", description = "Placeholder.", image = "", isUltimate = true, Cooldown = 45 },
		},
		Gun = {
			fireRate = 0.02,
			Spread  = 1,
			Range = 50,
			Recoil = 1,
			MagSize = 35,
			DAMAGE_PER_SHOT = 5,
			RELOAD_TIME = 2
		},
	},
}

return HeroData