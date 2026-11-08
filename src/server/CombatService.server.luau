-- Connected Discord-GitHub
--!strict
--[[
	CombatService (server-authoritative combat for "Key Bind")
	Handles: gun firing (raycast + spread + headshots), reloading, and dash stamina.
	The client only ever sends *intent* (aim point, "dash", "reload"); every number that matters
	(ammo, fire rate, range, damage, stamina) is decided and validated here, so exploiters can't fake it.
	Credits: Maid by Quenty (https://github.com/Quenty/NevermoreEngine), used for per-player cleanup.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Maid is a third-party library; kept typed as `any` because the package ships without Luau types.
local Maid = require(ReplicatedStorage.Packages.maid)
local Remotes = ReplicatedStorage.RemoteEvents
local FireGun = Remotes.FireGun :: RemoteEvent
local ReloadGun = Remotes.ReloadGun :: RemoteEvent
local UseDash = Remotes.UseDash :: RemoteEvent
local StaminaUpdate = Remotes.StaminaUpdate :: RemoteEvent

-- Tuning values live in one place so balancing never means hunting through logic.
local MAX_CHARGES = 3
local RECHARGE_TIME = 4 -- seconds for one dash charge to refill
local DASH_SPEED = 80 -- studs/second applied along the dash direction
local DASH_MIN_INTERVAL = 0.35 -- stops one key mash from burning every charge in a few frames
local REPLICATION_STEP = 0.05 -- progress change needed before we bother the client again
local HEADSHOT_MULTIPLIER = 2
local DEFAULT_FIRE_RATE = 0.1
local DEFAULT_RANGE = 50

-- A single Random object is cheaper and better distributed than calling math.random per pellet.
local rng = Random.new()

---------------------------------------------------------------------------
-- Stamina: a small class built with metatables
---------------------------------------------------------------------------

type StaminaData = {
	owner: Player,
	charges: number,
	progress: number, -- 0..1 fraction of the next charge
	lastSent: number, -- progress value last replicated, used to throttle remotes
	lastSpend: number, -- os.clock() of the last dash
}

local Stamina = {}
Stamina.__index = Stamina -- missing keys on an instance fall back to the methods on this table
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

-- Pushes the current state to the owner so their HUD matches the server's truth.
function Stamina.Replicate(self: Stamina)
	self.lastSent = self.progress
	StaminaUpdate:FireClient(self.owner, self.charges, self.progress)
end

-- Returns whether a charge was spent; the caller must not dash when this is false.
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

-- Called every Heartbeat with the frame delta so regeneration is frame-rate independent.
function Stamina.Tick(self: Stamina, dt: number)
	if self.charges >= MAX_CHARGES then
		return -- full: nothing to regenerate, and no remote traffic either
	end
	self.progress += dt / RECHARGE_TIME
	if self.progress >= 1 then
		self.charges += 1
		self.progress = 0
		self:Replicate() -- completed charges always replicate immediately
	elseif self.progress - self.lastSent >= REPLICATION_STEP then
		self:Replicate() -- partial progress is throttled to ~20 updates per charge
	end
end

---------------------------------------------------------------------------
-- Per-player bookkeeping
---------------------------------------------------------------------------

type PlayerCombat = {
	stamina: Stamina,
	maid: any,
}

local combats: {[Player]: PlayerCombat} = {}

-- Gun stats are written onto the gun as Attributes by GunManager.Equip, so the gun Instance is the state.
local function getGun(player: Player): Instance?
	local character = player.Character
	return character and character:FindFirstChild("EquippedGun")
end

-- Returns the character and its root part only if the player is alive; every action needs both.
local function getLivingCharacter(player: Player): (Model?, BasePart?, Humanoid?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if character and root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return character, root, humanoid
	end
	return nil, nil, nil
end

---------------------------------------------------------------------------
-- Weapons
---------------------------------------------------------------------------

local function startReload(gun: Instance)
	local magSize = gun:GetAttribute("MagSize")
	local reloadTime = gun:GetAttribute("ReloadTime")
	-- Guard against double reloads, full mags, and guns that were never configured.
	if gun:GetAttribute("Reloading") or typeof(magSize) ~= "number" or typeof(reloadTime) ~= "number" then
		return
	end
	if gun:GetAttribute("Ammo") == magSize then
		return
	end
	gun:SetAttribute("Reloading", true)
	gun:SetAttribute("ReloadStartTime", Workspace:GetServerTimeNow()) -- clients animate the reload bar from this

	task.delay(reloadTime, function()
		-- The player may have died or switched hero mid-reload, which destroys the gun.
		if gun.Parent then
			gun:SetAttribute("Ammo", magSize)
			gun:SetAttribute("Reloading", false)
		end
	end)
end

-- Rotates the aim direction by a random cone angle. CFrame.lookAt builds the basis, Angles perturbs it.
local function applySpread(origin: Vector3, target: Vector3, spreadDegrees: number): Vector3
	local aim = CFrame.lookAt(origin, target)
	local yaw = math.rad(rng:NextNumber(-spreadDegrees, spreadDegrees))
	local pitch = math.rad(rng:NextNumber(-spreadDegrees, spreadDegrees))
	return (aim * CFrame.Angles(pitch, yaw, 0)).LookVector
end

-- Applies damage to whatever the ray hit and returns true if a humanoid was damaged.
local function dealDamage(hit: BasePart, shooter: Model, baseDamage: number): boolean
	local victim = hit:FindFirstAncestorOfClass("Model")
	local humanoid = victim and victim:FindFirstChildOfClass("Humanoid")
	if not humanoid or victim == shooter or humanoid.Health <= 0 then
		return false
	end
	-- Hitting the Head part is the only thing that makes a shot a headshot; the client can't claim one.
	local multiplier = if hit.Name == "Head" then HEADSHOT_MULTIPLIER else 1
	humanoid:TakeDamage(baseDamage * multiplier)
	return true
end

-- GetAttribute returns `unknown`, so this narrows it to a number once and falls back to a default.
local function getNumber(instance: Instance, name: string, default: number): number
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

-- Checks every rule that can reject a shot, then spends ammo. Returns the gun's stats if the shot is allowed.
type ShotStats = {range: number, spread: number, damage: number}

local function consumeShot(gun: Instance): ShotStats?
	local now = os.clock()
	local fireRate = getNumber(gun, "FireRate", DEFAULT_FIRE_RATE)
	local ammo = gun:GetAttribute("Ammo")
	-- Server-side fire rate check: the client's own cooldown is only a courtesy and can't be trusted.
	if typeof(ammo) ~= "number" or ammo <= 0 or gun:GetAttribute("Reloading") then
		return nil
	end
	if now - getNumber(gun, "LastShotTime", 0) < fireRate then
		return nil
	end
	gun:SetAttribute("LastShotTime", now)
	gun:SetAttribute("Ammo", ammo - 1)
	if ammo - 1 <= 0 then
		startReload(gun) -- auto-reload on an empty magazine
	end
	return {
		range = getNumber(gun, "Range", DEFAULT_RANGE),
		spread = getNumber(gun, "Spread", 0),
		damage = getNumber(gun, "DamagePerShot", 0),
	}
end

local function onFire(player: Player, targetPoint: unknown)
	-- `x == x` is false only for NaN, which would poison every CFrame calculation downstream.
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

	-- Exclude the shooter's own character so the ray can't hit their gun or body.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}

	local result = Workspace:Raycast(origin, direction, params)
	if result then
		dealDamage(result.Instance, character, stats.damage)
	end

	-- Everyone but the shooter gets the tracer; the shooter already drew their own locally (no latency).
	local endPoint = if result then result.Position else origin + direction
	for _, other in Players:GetPlayers() do
		if other ~= player then
			FireGun:FireClient(other, player, origin, endPoint)
		end
	end
end

---------------------------------------------------------------------------
-- Dash
---------------------------------------------------------------------------

local function onDash(player: Player)
	local combat = combats[player]
	local _, root, humanoid = getLivingCharacter(player)
	-- Validate the character first so a dead player never burns a charge.
	if not (combat and root and humanoid) then
		return
	end
	if not combat.stamina:TrySpend() then
		return
	end

	-- Dash where the player is steering; if they're standing still, dash where they're facing.
	local look = root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z).Unit
	local direction = if humanoid.MoveDirection.Magnitude > 0.1 then humanoid.MoveDirection else flatLook

	-- Overwrite only horizontal velocity so dashing mid-jump keeps the vertical arc intact.
	local vertical = root.AssemblyLinearVelocity.Y
	root.AssemblyLinearVelocity = direction * DASH_SPEED + Vector3.yAxis * vertical
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	local maid = Maid.new()
	combats[player] = {stamina = Stamina.new(player), maid = maid}
	-- Any resource a player owns gets registered with the maid; one DoCleaning on leave frees all of it.
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

-- One shared Heartbeat loop beats a thread per player: constant scheduler cost no matter the player count.
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

-- Players already in the server when this script starts (Studio playtests) would otherwise be missed.
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
