-- Connected Discord-GitHub
--!strict
--[[
	Server side combat for Key Bind: shooting, reloading and dash stamina.
	The client only tells us what it wants to do (aim point, dash, reload). Ammo, fire rate,
	damage and stamina are all decided here so nobody can fake them with an exploit.
	Maid by Quenty (https://github.com/Quenty/NevermoreEngine) is used for cleanup when a player leaves.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Maid has no type annotations so anything holding one is typed as any
local Maid = require(ReplicatedStorage.Packages.maid)
local Remotes = ReplicatedStorage.RemoteEvents
local FireGun = Remotes.FireGun :: RemoteEvent
local ReloadGun = Remotes.ReloadGun :: RemoteEvent
local UseDash = Remotes.UseDash :: RemoteEvent
local StaminaUpdate = Remotes.StaminaUpdate :: RemoteEvent

-- all the numbers I tweak while balancing, kept up here
local MAX_CHARGES = 3
local RECHARGE_TIME = 4 -- seconds to get one charge back
local DASH_SPEED = 80 -- studs per second
local DASH_MIN_INTERVAL = 0.35 -- so mashing shift cant burn all 3 charges at once
local REPLICATION_STEP = 0.05 -- how much the bar has to move before we send it to the client again
local HEADSHOT_MULTIPLIER = 2
local DEFAULT_FIRE_RATE = 0.1
local DEFAULT_RANGE = 50

-- one Random object reused for every shot instead of math.random each time
local rng = Random.new()

-- Stamina class (metatable based)

type StaminaData = {
	owner: Player,
	charges: number,
	progress: number, -- 0 to 1, how far along the next charge is
	lastSent: number, -- progress we last sent, used to throttle the remote
	lastSpend: number, -- os.clock of the last dash
}

local Stamina = {}
Stamina.__index = Stamina -- lets instances find the methods below through the metatable
export type Stamina = typeof(setmetatable({} :: StaminaData, Stamina))

function Stamina.new(owner: Player): Stamina
	local self = setmetatable({
		owner = owner,
		charges = MAX_CHARGES,
		progress = 0,
		lastSent = 0,
		lastSpend = 0,
	}, Stamina)
	self:Replicate()
	return self
end

-- sends the real values to the client so their hud matches
function Stamina.Replicate(self: Stamina)
	self.lastSent = self.progress
	StaminaUpdate:FireClient(self.owner, self.charges, self.progress)
end

-- true if a charge was spent, caller only dashes when this is true
function Stamina.TrySpend(self: Stamina): boolean
	local now = os.clock()
	if self.charges < 1 or now - self.lastSpend < DASH_MIN_INTERVAL then
		return false
	end
	self.lastSpend = now
	self.charges -= 1
	self:Replicate()
	return true
end

-- runs every heartbeat, using dt so regen speed doesnt depend on fps
function Stamina.Tick(self: Stamina, dt: number)
	if self.charges >= MAX_CHARGES then
		return -- already full, nothing to do
	end
	self.progress += dt / RECHARGE_TIME
	if self.progress >= 1 then
		self.charges += 1
		self.progress = 0
		self:Replicate() -- a finished charge is always sent right away
	elseif self.progress - self.lastSent >= REPLICATION_STEP then
		self:Replicate() -- partial progress only gets sent every so often (about 20 times per charge)
	end
end

-- per player state

type PlayerCombat = {
	stamina: Stamina,
	maid: any,
}

local combats: {[Player]: PlayerCombat} = {}

-- GunManager.Equip puts the stats on the gun as attributes, so the gun itself holds the state
local function getGun(player: Player): Instance?
	local character = player.Character
	return character and character:FindFirstChild("EquippedGun")
end

-- gives back character, root and humanoid only if the player is alive, shooting and dashing both need them
local function getLivingCharacter(player: Player): (Model?, BasePart?, Humanoid?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if character and root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return character, root, humanoid
	end
	return nil, nil, nil
end

-- weapons

local function startReload(gun: Instance)
	local magSize = gun:GetAttribute("MagSize")
	local reloadTime = gun:GetAttribute("ReloadTime")
	-- skip if already reloading, mag is full, or the gun has no stats
	if gun:GetAttribute("Reloading") or typeof(magSize) ~= "number" or typeof(reloadTime) ~= "number" then
		return
	end
	if gun:GetAttribute("Ammo") == magSize then
		return
	end
	gun:SetAttribute("Reloading", true)
	gun:SetAttribute("ReloadStartTime", Workspace:GetServerTimeNow()) -- the client reload bar uses this

	task.delay(reloadTime, function()
		-- gun gets destroyed if they died or switched hero while reloading
		if gun.Parent then
			gun:SetAttribute("Ammo", magSize)
			gun:SetAttribute("Reloading", false)
		end
	end)
end

-- lookAt gives the aim rotation, then Angles nudges it by a random amount for spread
local function applySpread(origin: Vector3, target: Vector3, spreadDegrees: number): Vector3
	local aim = CFrame.lookAt(origin, target)
	local yaw = math.rad(rng:NextNumber(-spreadDegrees, spreadDegrees))
	local pitch = math.rad(rng:NextNumber(-spreadDegrees, spreadDegrees))
	return (aim * CFrame.Angles(pitch, yaw, 0)).LookVector
end

-- damages whatever the ray hit, returns true if it was a humanoid
local function dealDamage(hit: BasePart, shooter: Model, baseDamage: number): boolean
	local victim = hit:FindFirstAncestorOfClass("Model")
	local humanoid = victim and victim:FindFirstChildOfClass("Humanoid")
	if not humanoid or victim == shooter or humanoid.Health <= 0 then
		return false
	end
	-- headshot is decided by the part the ray hit, the client never says it
	local multiplier = if hit.Name == "Head" then HEADSHOT_MULTIPLIER else 1
	humanoid:TakeDamage(baseDamage * multiplier)
	return true
end

-- GetAttribute returns unknown, this makes sure we get a number back
local function getNumber(instance: Instance, name: string, default: number): number
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

-- checks if the shot is allowed, takes the ammo, and gives back the gun stats
type ShotStats = {range: number, spread: number, damage: number}

local function consumeShot(gun: Instance): ShotStats?
	local now = os.clock()
	local fireRate = getNumber(gun, "FireRate", DEFAULT_FIRE_RATE)
	local ammo = gun:GetAttribute("Ammo")
	-- fire rate is checked here too since the client cooldown can be bypassed
	if typeof(ammo) ~= "number" or ammo <= 0 or gun:GetAttribute("Reloading") then
		return nil
	end
	if now - getNumber(gun, "LastShotTime", 0) < fireRate then
		return nil
	end
	gun:SetAttribute("LastShotTime", now)
	gun:SetAttribute("Ammo", ammo - 1)
	if ammo - 1 <= 0 then
		startReload(gun) -- reload automatically when empty
	end
	return {
		range = getNumber(gun, "Range", DEFAULT_RANGE),
		spread = getNumber(gun, "Spread", 0),
		damage = getNumber(gun, "DamagePerShot", 0),
	}
end

local function onFire(player: Player, targetPoint: unknown)
	-- a point that isnt equal to itself is NaN, which would break the CFrame math
	if typeof(targetPoint) ~= "Vector3" or targetPoint ~= targetPoint then
		return
	end
	local character, root = getLivingCharacter(player)
	local gun = getGun(player)
	if not (character and root and gun) then
		return
	end

	local stats = consumeShot(gun)
	if not stats then
		return
	end

	local origin = root.Position
	local direction = applySpread(origin, targetPoint, stats.spread) * stats.range

	-- ignore the shooters own character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}

	local result = Workspace:Raycast(origin, direction, params)
	if result then
		dealDamage(result.Instance, character, stats.damage)
	end

	-- tell everyone else to draw the tracer, the shooter already drew theirs locally
	local endPoint = if result then result.Position else origin + direction
	for _, other in Players:GetPlayers() do
		if other ~= player then
			FireGun:FireClient(other, player, origin, endPoint)
		end
	end
end

-- dash

local function onDash(player: Player)
	local combat = combats[player]
	local _, root, humanoid = getLivingCharacter(player)
	-- check the character before spending so dead players dont lose charges
	if not (combat and root and humanoid) then
		return
	end
	if not combat.stamina:TrySpend() then
		return
	end

	-- dash the way they are moving, or the way they face if standing still
	local look = root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z).Unit
	local direction = if humanoid.MoveDirection.Magnitude > 0.1 then humanoid.MoveDirection else flatLook

	-- keep the old vertical velocity so dashing in the air doesnt cancel the jump
	local vertical = root.AssemblyLinearVelocity.Y
	root.AssemblyLinearVelocity = direction * DASH_SPEED + Vector3.yAxis * vertical
end

-- player join / leave

local function onPlayerAdded(player: Player)
	local maid = Maid.new()
	combats[player] = {stamina = Stamina.new(player), maid = maid}
	-- everything the player owns goes in the maid, DoCleaning on leave removes it all
	maid:GiveTask(function()
		combats[player] = nil
	end)
end

local function onPlayerRemoving(player: Player)
	local combat = combats[player]
	if combat then
		combat.maid:DoCleaning()
	end
end

-- one heartbeat loop for everyone is cheaper than a thread per player
RunService.Heartbeat:Connect(function(dt: number)
	for _, combat in combats do
		combat.stamina:Tick(dt)
	end
end)

FireGun.OnServerEvent:Connect(onFire)
UseDash.OnServerEvent:Connect(onDash)
ReloadGun.OnServerEvent:Connect(function(player: Player)
	local gun = getGun(player)
	if gun then
		startReload(gun)
	end
end)

-- catch players that joined before this script ran (happens in studio)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
