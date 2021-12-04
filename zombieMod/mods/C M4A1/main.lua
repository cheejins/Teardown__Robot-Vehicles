local damageStart = 0.25


m4a1projectileHandler = {
	shellNum = 1,
	shells = {},
	defaultShell = {
		active = false,
		damage = damageStart,
		shootPos = nil,
	},
}

function init()
	RegisterTool("z-m4a1", "Z-M4A1", "MOD/mods/C M4A1/vox/m4a1.vox")
	SetBool("game.tool.z-m4a1.enabled", true)
	SetFloat("game.tool.z-m4a1.ammo", 101)

	gravity = Vec(0, 0, 0)
	velocity = 4

	gunsound = LoadSound("MOD/mods/C M4A1/snd/m4.ogg")
	cocksound = LoadSound("MOD/mods/C M4A1/snd/guncock.ogg")
	reloadsound = LoadSound("MOD/mods/C M4A1/snd/reload.ogg")
	dryfiresound = LoadSound("MOD/mods/C M4A1/snd/dryfire.ogg")
	refillsound = LoadSound("MOD/mods/C M4A1/snd/refill.ogg")

	reloadTime = 2
	shotDelay = 0.13
	spreadTimer = 0
	ammo = 25
	mags = 50
	reloading = false
	ironsight = false
	unlimitedammo = GetBool("savegame.mod.unlimitedammo")
	maxDist = 50
	diminishDamage = 0.9999
	for i=1, ammo do
		m4a1projectileHandler.shells[i] = deepcopy(m4a1projectileHandler.defaultShell)
		m4a1projectileHandler.shells[i].shootPos = toolPos
	end

	shootTimer = 0
	reloadTimer = 0
	recoilTimer = 0
	lightTimer = 0

	magoutTimer = 0
	maginTimer = 0
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
	local plVel = VecLength(GetPlayerVelocity())
	local maxSpread = InputDown("ctrl") and 1.5 or 3 * ((plVel*4) + 1)
	if ironsight then maxSpread = maxSpread / 2 end
	local spread = math.min(spreadTimer, maxSpread) * distance/100
	dir[1] = dir[1] + (math.random()-0.5)*2*spread
	dir[2] = dir[2] + (math.random()-0.5)*2*spread
	dir[3] = dir[3] + (math.random()-0.5)*2*spread

	m4a1projectileHandler.shells[m4a1projectileHandler.shellNum] = deepcopy(m4a1projectileHandler.defaultShell)
	loadedShell = m4a1projectileHandler.shells[m4a1projectileHandler.shellNum] 
	loadedShell.active = true
	loadedShell.pos = toolPos
	loadedShell.predictedBulletVelocity = VecScale(dir, velocity*(100/distance))
	m4a1projectileHandler.shells[m4a1projectileHandler.shellNum].shootPos = toolPos
	m4a1projectileHandler.shellNum = (m4a1projectileHandler.shellNum%#m4a1projectileHandler.shells) + 1

	SpawnParticle("fire", toolPos, Vec(0, 1.0+math.random(1,10)*0.1, 0), 0.3, 0.1)
	PlaySound(gunsound, GetPlayerTransform().pos, 1, false)

	if not unlimitedammo then
		ammo = ammo - 1
	end
	shootTimer = shotDelay
	recoilTimer = shotDelay*0.8
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
	magoutTimer = 0.6
	mags = mags - 1
end

function tick(dt)
	if GetString("game.player.tool") == "z-m4a1" and GetPlayerVehicle() == 0 then
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
			SpawnParticle("darksmoke", gunpos, Vec(0, 1.0+math.random(1,10)*0.1, 0), 0.3, 0.5)
		end

		if InputPressed("rmb") then
			ironsight = not ironsight
		end

		local b = GetToolBody()
		if b ~= 0 then
			local heightOffset = InputDown("ctrl") and 0.25 or 0.2
			local magoffset = Vec(0, 0, 0)
			local magtimer = magoutTimer + maginTimer
			local offset = Transform(Vec(0, heightOffset, 0))
			local x, y, z, rot = 0, heightOffset, 0, 0
			if ironsight then
				x = 0.32
				y = 0.355
				z = 0.3
				rot = 2.5
				offset = Transform(Vec(-x, y, z), QuatEuler(-rot, 0, 0))
			end

			if magtimer > 0 then
				offset.rot = QuatEuler(10, 0, -10)
				offset.pos = VecAdd(offset.pos, Vec(0.2, 0.2, 0))
				magoffset = Vec(-0.6, -0.6, 0.6)
			end

			SetToolTransform(offset)
			toolTrans = GetBodyTransform(b)
			toolPos = TransformToParentPoint(toolTrans, Vec(0.35, -0.6, -2.35))

			if recoilTimer > 0 then
				local t = Transform()
				t.pos = Vec(-x, y, recoilTimer+z)
				ironrot = ironsight and rot or -recoilTimer*50-rot
				t.rot = QuatEuler(-ironrot, 0, 0)
				SetToolTransform(t)

				recoilTimer = recoilTimer - dt
			end

			if lightTimer > 0 then
				PointLight(toolPos, 1, 1, 1, 0.5)
				lightTimer = lightTimer - dt
			end
			
			if magoutTimer > 0 then
				magoffset = Vec(-0.3+magoutTimer/2, -0.6+magoutTimer, 0.9-magoutTimer*1.5)
				magoutTimer = magoutTimer - dt
				if magoutTimer < 0 then
					maginTimer = 0.6
				end
			end

			if maginTimer > 0 then
				magoffset = Vec(-maginTimer/2, -maginTimer, maginTimer*1.5)
				maginTimer = maginTimer - dt
			end
			
			if body ~= b then
				body = b
				local shapes = GetBodyShapes(b)
				mag = shapes[2]
				magTrans = GetShapeLocalTransform(mag)
			end

			mt = TransformCopy(magTrans)
			mt.pos = VecAdd(mt.pos, magoffset)
			mt.rot = QuatRotateQuat(mt.rot, QuatEuler(-magtimer*30, magtimer*30, 0))
			SetShapeLocalTransform(mag, mt)
		end

		if not unlimitedammo then
			if ammo < 30 and mags > 1 and InputPressed("R") then
				Reload()
			end
			
			if GetBool("ammobox.refill") then
				SetBool("ammobox.refill", false)
				mags = mags + 1
				PlaySound(refillsound, GetPlayerTransform().pos, 1, false)
			end

			if reloading then
				ironsight = false
				reloadTimer = reloadTimer - dt
				if reloadTimer < 0 then
					ammo = 30
					reloadTimer = 0
					PlaySound(cocksound)
					reloading = false
				end
			end
		end

		for key, shell in ipairs(m4a1projectileHandler.shells) do
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
	if GetString("game.player.tool") == "z-m4a1" and GetPlayerVehicle() == 0 and not unlimitedammo then
		UiPush()
			UiTranslate(UiCenter(), (UiCenter()/2) + 300)
			UiAlign("center middle")
			local c = ammo / #m4a1projectileHandler.shells
			UiColor(1, c, c)
			UiFont("bold.ttf", 24)
			UiTextOutline(0,0,0,1,0.1)
			if reloading then
				UiText("Reloading")
			else
				UiText(ammo.."/"..30*math.max(0, mags-1))
			end
		UiPop()
	end
end