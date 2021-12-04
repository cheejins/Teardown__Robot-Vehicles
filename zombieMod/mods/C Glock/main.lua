local damageStart = 0.175

local TOOL = {}

TOOL.printname = "Desert Eagle"
TOOL.order = 2
TOOL.base = "gun"

TOOL.suppress_default = true

local STATE_READY = 0
local STATE_RELOADING = 2

deagleprojectileHandler = {
	shellNum = 1,
	shells = {},
	defaultShell = {
		active = false,
		damage = damageStart,
		shootPos = nil,
	},
}


function initGlock18()

	RegisterTool("z-glock18", "Z-Glock 18", "MOD/mods/C Glock/vox/glock.vox")
	SetBool("game.tool.z-glock18.enabled", true)
	SetFloat("game.tool.z-glock18.ammo", 101)

	damage = damageStart
	gravity = Vec(0, 0, 0)
	velocity = 2.1
	reloadTime = 1.5
	shotDelay = 0.145
	ammo = 18
	mags = 50
	reloading = false
	unlimitedammo = GetBool("savegame.mod.unlimitedammo")
	maxDist = 25
	diminishDamage = 0.9995


	for i=1, ammo do
		deagleprojectileHandler.shells[i] = deepcopy(deagleprojectileHandler.defaultShell)
		deagleprojectileHandler.shells[i].shootPos = toolPos
	end

	shootTimer = 0
	reloadTimer = 0
	recoilTimer = 0
	lightTimer = 0

	gunsound = LoadSound("MOD/mods/C Glock/snd/deagle_shot.ogg")
	cocksound = LoadSound("MOD/mods/C Glock/snd/pistolcock.ogg")
	reloadsound = LoadSound("MOD/mods/C Glock/snd/deagle_reload.ogg")
	dryfiresound = LoadSound("MOD/mods/C Glock/snd/dryfire.ogg")
	refillsound = LoadSound("MOD/mods/C Glock/snd/refill.ogg")
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function GetAimPos()
	local ct = GetCameraTransform()
	local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -100))
    local direction = VecSub(forwardPos, ct.pos)
    local distance = VecLength(direction)
	local direction = VecNormalize(direction)
	local hit, hitDistance = QueryRaycast(ct.pos, direction, distance)
	if hit then
		forwardPos = TransformToParentPoint(ct, Vec(0, 0, -hitDistance))
		distance = hitDistance
	end
	return forwardPos, hit, distance
end

function Shoot()
	if shootTimer > 0 or ammo == 0 then
		return
	end

	aimpos, hit, distance = GetAimPos()
	local direction = VecSub(aimpos, toolPos)

	deagleprojectileHandler.shells[deagleprojectileHandler.shellNum] = deepcopy(deagleprojectileHandler.defaultShell)
	loadedShell = deagleprojectileHandler.shells[deagleprojectileHandler.shellNum] 
	loadedShell.active = true
	loadedShell.pos = toolPos
	loadedShell.predictedBulletVelocity = VecScale(direction, velocity*(100/distance))

	deagleprojectileHandler.shells[deagleprojectileHandler.shellNum].shootPos = toolPos
	deagleprojectileHandler.shellNum = (deagleprojectileHandler.shellNum%#deagleprojectileHandler.shells) +1

	SpawnParticle("fire", toolPos, Vec(0, 1.0+math.random(1,10)*0.1, 0), 0.5, 0.1)
	SpawnParticle("darksmoke", toolPos, Vec(0, 1.0+math.random(1,5)*0.1, 0), 0.4, 1.5)
	PlaySound(gunsound, GetPlayerTransform().pos, 0.9, false)
	if not unlimitedammo then
		ammo = ammo - 1
	end
	shootTimer = shotDelay
	recoilTimer = shotDelay
	lightTimer = shotDelay / 4
end

function ProjectileOperations(projectile)
	projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity, (VecScale(gravity, GetTimeStep())))
	local point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
	local dir = VecNormalize(VecSub(point2, projectile.pos))
	local hit, dist = QueryRaycast(projectile.pos, dir, VecLength(VecSub(point2, projectile.pos)))
	
	if hit then
		hitPos = VecAdd(projectile.pos, VecScale(VecNormalize(VecSub(point2, projectile.pos)), dist))
		projectile.active = false
		PlaySound(bouncesound, projectile.pos, 1, false)
		MakeHole(hitPos, projectile.damage, projectile.damage*0.6, projectile.damage*0.4)
		SpawnParticle("smoke", hitPos, Vec(0, 1.0+math.random(1,10)*0.1, 0), projectile.damage, 1)
	else
		DrawLine(projectile.pos, point2)
	end

    projectile.pos = point2
	projectile.damage = projectile.damage * diminishDamage

	if VecLength(VecSub(projectile.pos, projectile.shootPos)) > maxDist then
		projectile.active = false
	end

end

function Reload()
	if reloading then
		return
	end
	reloading = true
	PlaySound(reloadsound, GetPlayerTransform().pos, 0.6, false)
	reloadTimer = reloadTime
	mags = mags - 1
end

function tick(dt)
	runGlock18(dt)
end

function runGlock18(dt)
	if GetString("game.player.tool") == "z-glock18" and GetPlayerVehicle() == 0 then
		if InputPressed("lmb") then
			if not reloading then
				if mags == 0 or ammo == 0 then
					PlaySound(dryfiresound, GetPlayerTransform().pos, 1, false)
				else
					Shoot()
				end
			end
		end

		local b = GetToolBody()
		if b ~= 0 then
			local offset = Transform(Vec(0, 0.3, 0))
			SetToolTransform(offset)
			toolTrans = GetBodyTransform(b)
			toolPos = TransformToParentPoint(toolTrans, Vec(0.3, -0.45, -2.4))

			if recoilTimer > 0 then
				local t = Transform()
				t.pos = Vec(0.1, 0.1, recoilTimer*3)
				t.rot = QuatEuler(recoilTimer*100, 0, 0)
				SetToolTransform(t)

				recoilTimer = recoilTimer - dt
			end

			if lightTimer > 0 then
				PointLight(toolPos, 1, 1, 1, 0.5)

				lightTimer = lightTimer - dt
			end
		end

		if not unlimitedammo then
			if ammo < 18 and mags > 1 and InputPressed("R") then
				Reload()
			end
			
			if GetBool("ammobox.refill") then
				SetBool("ammobox.refill", false)
				mags = mags + 1
				PlaySound(refillsound, GetPlayerTransform().pos, 1, false)
			end

			if reloading then
				reloadTimer = reloadTimer - dt
				if reloadTimer < 0 then
					ammo = 18
					reloadTimer = 0
					PlaySound(cocksound)
					reloading = false
				end
			end
		end
	
		if shootTimer > 0 or ammo == 0 then
			shootTimer = shootTimer - dt
		end
	end
	
	for key, shell in ipairs(deagleprojectileHandler.shells) do
		if shell.active then
			ProjectileOperations(shell)
		end
	end
end

function draw()
	if GetString("game.player.tool") == "z-glock18" and GetPlayerVehicle() == 0 and not unlimitedammo then
		UiPush()
			UiTranslate(UiCenter(), (UiCenter()/2) + 300)
			UiAlign("center middle")
			local c = ammo / #deagleprojectileHandler.shells
			UiColor(1, c, c)
			UiFont("bold.ttf", 24)
			UiTextOutline(0,0,0,1,0.1)
			if reloading then
				UiText("Reloading")
			else
				UiText(ammo.."/"..18*math.max(0, mags-1))
			end
		UiPop()
	end
end
