local damageStart = 0.15

p90projectileHandler = {
	shellNum = 1,
	shells = {},
	defaultShell = {
		active = false,
		damage = damageStart,
		shootPos = nil,
	},
}

function init()
	RegisterTool("p90", "P90", "MOD/mods/C P90/vox/p90.vox")
	SetBool("game.tool.p90.enabled", true)
	SetFloat("game.tool.p90.ammo", 101)

	damage = damageStart
	gravity = Vec(0, 0, 0)
	velocity = 3

	gunsound = LoadSound("MOD/mods/C P90/snd/p90.ogg")
	cocksound = LoadSound("MOD/mods/C P90/snd/p90cock.ogg")
	reloadsound = LoadSound("MOD/mods/C P90/snd/p90reload.ogg")
	dryfiresound = LoadSound("MOD/mods/C P90/snd/dryfire.ogg")
	refillsound = LoadSound("MOD/mods/C P90/snd/refill.ogg")

	reloadTime = 2
	shotDelay = 0.06
	spreadTimer = 0
	ammo = 50
	mags = 50
	reloading = false
	unlimitedammo = GetBool("savegame.mod.unlimitedammo")
	maxDist = 50
	diminishDamage = 0.99

	for i=1, ammo do
		p90projectileHandler.shells[i] = deepcopy(p90projectileHandler.defaultShell)
		p90projectileHandler.shells[i].shootPos = toolPos
	end

	shootTimer = 0
	reloadTimer = 0
	recoilTimer = 0
	lightTimer = 0
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

	local p = toolPos
	local dir = VecSub(aimpos, p)
	local maxSpread = InputDown("ctrl") and 2 or 4
	local spread = math.min(spreadTimer, maxSpread) * distance/100
	dir[1] = dir[1] + (math.random()-0.5)*2*spread
	dir[2] = dir[2] + (math.random()-0.5)*2*spread
	dir[3] = dir[3] + (math.random()-0.5)*2*spread

	p90projectileHandler.shells[p90projectileHandler.shellNum] = deepcopy(p90projectileHandler.defaultShell)
	loadedShell = p90projectileHandler.shells[p90projectileHandler.shellNum]
	loadedShell.active = true
	loadedShell.pos = toolPos
	loadedShell.predictedBulletVelocity = VecScale(dir, velocity*(100/distance))
	p90projectileHandler.shells[p90projectileHandler.shellNum].shootPos = toolPos
	p90projectileHandler.shellNum = (p90projectileHandler.shellNum%#p90projectileHandler.shells) + 1

	SpawnParticle("fire", toolPos, Vec(0, 1.0+math.random(1,10)*0.1, 0), 0.3, 0.1)
	PlaySound(gunsound, GetPlayerTransform().pos, 1, false)

	if not unlimitedammo then
		ammo = ammo - 1
	end
	shootTimer = shotDelay
	recoilTimer = shotDelay
	lightTimer = shotDelay/2
	spreadTimer = spreadTimer + 1.25
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
		MakeHole(hitPos, projectile.damage, projectile.damage*0.85, projectile.damage*0.7)
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
	if GetString("game.player.tool") == "p90" and GetPlayerVehicle() == 0 then
		if InputDown("lmb") and ammo > 0 and not reloading then
			Shoot()
		end

		if InputPressed("lmb") and not reloading then
			spreadTimer = 0
			if ammo == 0 then
				PlaySound(dryfiresound, GetPlayerTransform().pos, 1, false)
			end
		end

		if InputReleased("lmb") and ammo > 0 then
			SpawnParticle("darksmoke", toolPos, Vec(0, 1.0+math.random(1,10)*0.1, 0), 0.3, 0.5)
		end

		local b = GetToolBody()
		if b ~= 0 then
			local heightOffset = InputDown("ctrl") and 0.3 or 0.2
			local offset = Transform(Vec(0, heightOffset, 0))
			SetToolTransform(offset)
			toolTrans = GetBodyTransform(b)
			toolPos = TransformToParentPoint(toolTrans, Vec(0.3, -0.5, -1.45))

			if recoilTimer > 0 then
				local t = Transform()
				t.pos = Vec(0, heightOffset, recoilTimer)
				t.rot = QuatEuler(recoilTimer*50, 0, 0)
				SetToolTransform(t)

				recoilTimer = recoilTimer - dt
			end

			if lightTimer > 0 then
				PointLight(toolPos, 1, 1, 1, 0.5)

				lightTimer = lightTimer - dt
			end
		end

		if not unlimitedammo then
			if ammo < 50 and mags > 1 and InputPressed("R") then
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
					ammo = 50
					reloadTimer = 0
					PlaySound(cocksound)
					reloading = false
				end
			end
		end

		for key, shell in ipairs(p90projectileHandler.shells) do
			if shell.active then
				ProjectileOperations(shell)
			end
		end
	
		if shootTimer > 0 or ammo == 0 then
			shootTimer = shootTimer - dt
		end
	end
end

function draw()
	if GetString("game.player.tool") == "p90" and GetPlayerVehicle() == 0 and not unlimitedammo then
		UiPush()
			UiTranslate(UiCenter(), (UiCenter()/2) + 300)
			UiAlign("center middle")
			local c = ammo / #p90projectileHandler.shells
			UiColor(1, c, c)
			UiFont("bold.ttf", 24)
			UiTextOutline(0,0,0,1,0.1)
			if reloading then
				UiText("Reloading")
			else
				UiText(ammo.."/"..50*math.max(0, mags-1))
			end
		UiPop()
	end
end