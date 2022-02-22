--================================
--= Robot Vehicles
--= By: Cheejins
--================================


--> SCRIPT
function initCustom()

	CAMERA = {}
	CAMERA.xy = {UiCenter(), UiMiddle()}
	missileSound = LoadSound("../snd/launchSound.ogg")
	SetTag(head.body, 'interact')
	SetDescription(head.body, 'Drive Robot')
	-- robot.followPlayer = regGetBool('robot.followPlayer')

	initPlayerDrivingRobot()
	setRobotUnbreakable(false)

	robot.died = false
	robot.health = getRobotMass()

	initSounds()
	initRobotPreset()
	initCamera()
	initDebug()
	initProjectiles()
	initWeapons()
	initTimers()
	initUi()

	enterCount = 0

end
function tickCustom(dt)

	--+ Global robot variables.
	bodyTr = GetBodyTransform(robot.body)
	headTr = GetBodyTransform(head.body)
	camTr = GetCameraTransform()
	crosshairPos = getOuterCrosshairWorldPos()

	--+ Constant functions.
	manageRobotHealth()
	runTimers()
	manageProjs()
	manageActiveProjectiles()
	aimsUpdateCustom()

	--+ Check and set player robot vehicle.
	playerCheckRobot()

	--+ Drive robot.
	if player.isDrivingRobot then
		playerDriveRobot(dt, bodyTr.pos)
		debugRobot()
	end

end
function updateCustom(dt)
	robot.speedScale = regGetFloat('robot.move.speed')
	timers.gun.bullets.rpm = regGetFloat('robot.weapon.bullet.rpm')
	timers.gun.rockets.rpm = regGetFloat('robot.weapon.rocket.rpm')

	if player.isDrivingRobot then

		processMovement()

	-- elseif regGetBool('robot.followPlayer') then

	-- 	if VecDist(GetPlayerTransform().pos, robot.transform.pos) > 3 then
	-- 		robotFollowPlayer(dt)
	-- 	end

	end
end
function drawCustom()

	if player.isDrivingRobot and robot.enabled then

		do UiPush()
			UiFont('bold.ttf', 24)
			UiColor(0.75,0.75,0.75)
			UiAlign('right top')
			UiTranslate(UiWidth(), 0)
			UiText('v' .. GetModVersion())
		UiPop() end

		uiManageGameOptions()

		CAMERA.xy = {UiCenter(), UiMiddle()}

		-- Crosshair
		do UiPush()
			local crosshairSize = 50*robot.crosshairScale
			UiAlign('center middle')
			UiTranslate(UiCenter(), UiMiddle())
			UiImageBox(robot.crosshair, crosshairSize, crosshairSize, 1,1)
		UiPop() end

		-- Bottom info
		if robot.model == robot_models.basic then
			do UiPush()
				UiTranslate(UiCenter(), UiHeight() - 60)
				UiFont('bold.ttf', 24)
				UiColor(0.75,0.75,0.75)
				UiAlign('center top')

				local key_options = regGetString('options.keys.optionsScreen')

				UiText('Press "' .. key_options .. '" to show the options menu.')
				UiTranslate(0, 30)
			UiPop() end
		end

		if GetBool('LEVEL.demoMap') and player.isDrivingRobot and not GetBool('LEVEL.welcome') then
			do UiPush()

				UiTranslate(UiCenter(), UiMiddle())
				UiAlign('center middle')
				UiImageBox('../img/welcome.png', UiWidth()*0.7, UiHeight()*0.7, 1, 1)

				if InputPressed('any') then
					enterCount = enterCount + 1
					if enterCount > 1 then
						SetBool('LEVEL.welcome', true)
					end
				end

			UiPop() end
		end

	end

end



--> MOVEMENT
processMovement = function ()

	-- navigationClear()

	local walk = false
	local walkDir = Vec()
	local lookTr = Transform(robot.transform.pos, camTr.rot)

	--+ WASD
	if InputDown('up') then
		local moveDir = TransformToParentVec(lookTr, Vec(0,0,-1))
		walkDir = VecAdd(walkDir, moveDir)
		walk = true
	elseif InputDown('down') then
		local moveDir = TransformToParentVec(lookTr, Vec(0,0,1))
		walkDir = VecAdd(walkDir, moveDir)
		walk = true
	end

	if InputDown('left') then
		local moveDir = TransformToParentVec(lookTr, Vec(-1,0,0))
		walkDir = VecAdd(walkDir, moveDir)
		walk = true
	end
	if InputDown('right') then
		local moveDir = TransformToParentVec(lookTr, Vec(1,0,0))
		walkDir = VecAdd(walkDir, moveDir)
		walk = true
	end

	if walk then
		walkDir = VecNormalize(walkDir)
		robotWalk(walkDir)
	end

	--+ Sprint
	if InputDown('shift') then
		robot.speedScale = regGetFloat('robot.move.speed') * 2
	else
		robot.speedScale = regGetFloat('robot.move.speed')
	end

	--+ Jump
	if InputPressed('space') then
		SetBodyVelocity(robot.body, VecAdd(GetBodyVelocity(robot.body), Vec(0,10,0)))
	end

	--+ Crouch
	if InputPressed('ctrl') then
		SetBodyVelocity(robot.body, VecAdd(GetBodyVelocity(robot.body), Vec(0,-5,0)))
		-- DebugPrint('Teabag initiated ' .. sfnTime())
	end

end
robotWalk = function (robotDir)
	robot.dir = robotDir
	local dirDiff = VecDot(VecScale(robot.axes[3], -1), robot.dir)
	local speedScale = math.max(0.25, dirDiff)
	speedScale = speedScale * clamp(1.0 - navigation.vertical, 0.3, 1.0)
	robot.speed = config.speed * speedScale
end
robotFollowPlayer = function(dt)
	navigationSetTarget(GetPlayerTransform().pos, 5)
	navigationMove(dt)
	navigationUpdate(dt)
end



--> WEAPONS
function processWeapons()

	if robot.model == robot_models.basic then
		processWeapons_mech_basic()
	elseif robot.model == robot_models.aeon then
		processWeapons_mech_aeon()
	end

end
function processWeapons_mech_aeon()

	-- Draw dots at shooting positions.
	-- for key, weap in pairs(robot.weaponObjects) do
	-- 	for key, obj in pairs(weap) do
	-- 		local pos = GetLightTransform(obj.light).pos
	-- 		DrawDot(pos, 0.1,0.1, 1,1,1, 1, false)
	-- 	end
	-- end

	if InputDown('lmb') then

		if timers.aeon.secondary.time <= 0 then

			TimerResetTime(timers.aeon.secondary)

			for key, weap in pairs(robot.weaponObjects.secondary) do

				local weapTr = GetLightTransform(weap.light)

				-- Aim adjust. The shoot location is slightly higher than the weapon body.
				-- Moves the aim pos just above where the crosshair (weapon body aligned) hits the world.
				local shootTr = TransformCopy(weapTr)
				local shootDir = QuatToDir(shootTr.rot)

				local trueAimRot = QuatLookAt(shootTr.pos, crosshairPos)
				local trueAimDir = QuatToDir(trueAimRot)
				local shootRotAligned =  DirToQuat(Vec(shootDir[1], trueAimDir[2], shootDir[3]))
				shootTr.rot = shootRotAligned

				-- Shoot projectile.
				createProjectile(shootTr, Projectiles, ProjectilePresets.aeon_secondary, robot.allBodies)


				-- Apply recoil,
				local vel_impulse = VecScale(QuatToDir(weapTr.rot), -4500)
				ApplyBodyImpulse(robot.body, AabbGetBodyCenterPos(robot.body), vel_impulse)

				-- Shoot particles,
				SpawnParticle_aeon_weap_secondary(shootTr)

				-- Exhaust particles.
				local exhaustTr = TransformCopy(weapTr)
				exhaustTr.pos = TransformToParentPoint(weapTr, Vec(0,0,1.5))
				exhaustTr.rot = QuatTrLookBack(weapTr)

				SpawnParticle_aeon_weap_secondary_exhaust(exhaustTr, 0)
				SpawnParticle_aeon_weap_secondary_exhaust(exhaustTr, 3)
				SpawnParticle_aeon_weap_secondary_exhaust(exhaustTr, 5)

			end

			local index = GetRandomIndex(Sounds.weap_secondary.shoot)
			PlayRandomSound(Sounds.weap_secondary.shoot, bodyTr.pos, 2, index)
			PlayRandomSound(Sounds.weap_secondary.shoot, GetCameraTransform().pos, 0.5, index)

		end

	end

	if InputDown('rmb') then

		if timers.aeon.special.time <= 0 then
			TimerResetTime(timers.aeon.special)

			PlayRandomSound(Sounds.weap_special.shoot, bodyTr.pos)
			PlayRandomSound(Sounds.weap_special.hit, bodyTr.pos, 0.5)

			createProjectile(
				GetLightTransform(robot.weaponObjects.special[math.random(1, #robot.weaponObjects.special)].light),
				Projectiles,
				ProjectilePresets.aeon_special,
				robot.allBodies)

		end

	end

end
function processWeapons_mech_basic()
	-- Bullets
	if InputDown('lmb') then

		PlayLoop(LoadLoop('../snd/bulletLoop.ogg'), bodyTr.pos, 0.5)

		if timers.gun.bullets.time <= 0 then

			TimerResetTime(timers.gun.bullets)

			local shootTr = Transform(TransformToParentPoint(headTr, (Vec(0,0.6,-1))), QuatLookAt(headTr.pos, TransformToParentPoint(headTr, (Vec(0,0,-5)))))

			local crosshairDist = VecDist(shootTr.pos, crosshairPos)
			local aimAssist = ternary(crosshairDist > 2 and crosshairDist < 10, 1/crosshairDist, 0)

			local spread = (math.random() * 2) + 3

			--TODO create function

			local leftTr = Transform(TransformToParentPoint(shootTr, Vec(-0.5, 0, 0)), shootTr.rot)
			leftTr = Transform(leftTr.pos, QuatLookAt(leftTr.pos, TransformToParentPoint(leftTr, Vec(0,0,-1))))

			-- Align y rot
			local leftDir = QuatToDir(leftTr.rot)
			local leftDirCopy = VecCopy(leftDir)

			-- Quat look crosshair
			local leftRotCrosshair = QuatLookAt(leftTr.pos, crosshairPos)
			local leftRotCrosshairDir = QuatToDir(leftRotCrosshair)
			local leftRotCrosshairDirY = leftRotCrosshairDir[2]

			-- dir look crosshair
			local leftRot = DirToQuat(Vec(leftDirCopy[1], leftRotCrosshairDirY, leftDirCopy[3]))
			leftTr.rot = leftRot
			leftTr.rot = QuatSlerp(leftTr.rot, QuatLookAt(leftTr.pos, crosshairPos), aimAssist)

			-- Spread
			leftTr.rot = QuatRotateQuat(leftTr.rot, QuatEuler((math.random()-0.5)*spread,(math.random()-0.5)*spread,(math.random()-0.5)*spread))
			rejectAllBodies(robot.allBodies)
			createBullet(leftTr, activeBullets, bulletPresets.mg.light, robot.allBodies)




			local rightTr = Transform(TransformToParentPoint(shootTr, Vec(0.5, 0, 0)), shootTr.rot)
			rightTr = Transform(rightTr.pos, QuatLookAt(rightTr.pos, TransformToParentPoint(rightTr, Vec(0,0,-1))))

			-- Align y rot
			local leftDir = QuatToDir(rightTr.rot)
			local leftDirCopy = VecCopy(leftDir)

			-- Slerp X and Z

			-- Quat look crosshair
			local leftRotCrosshair = QuatLookAt(rightTr.pos, crosshairPos)
			local leftRotCrosshairDir = QuatToDir(leftRotCrosshair)
			local leftRotCrosshairDirY = leftRotCrosshairDir[2]

			-- dir look crosshair
			local leftRot = DirToQuat(Vec(leftDirCopy[1], leftRotCrosshairDirY, leftDirCopy[3]))
			rightTr.rot = leftRot
			rightTr.rot = QuatSlerp(rightTr.rot, QuatLookAt(rightTr.pos, crosshairPos), aimAssist)

			-- Spread
			rightTr.rot = QuatRotateQuat(rightTr.rot, QuatEuler((math.random()-0.5)*spread,(math.random()-0.5)*spread,(math.random()-0.5)*spread))
			rejectAllBodies(robot.allBodies)
			createBullet(rightTr, activeBullets, bulletPresets.mg.light, robot.allBodies)

		end

	end

	-- Rockets
	if InputDown('rmb') then

		if timers.gun.rockets.time <= 0 then

			TimerResetTime(timers.gun.rockets)

			PlaySound(rocketSound, bodyTr.pos, 2)

			local spread = 1
			rejectAllBodies(robot.allBodies)

			local shootTr = Transform(TransformToParentPoint(headTr, (Vec(0,0.8,-1))), QuatLookAt(headTr.pos, TransformToParentPoint(headTr, (Vec(0,0,-5)))))

			local shootTr = Transform(TransformToParentPoint(shootTr, Vec(0, 0, 0)), shootTr.rot)
			shootTr = Transform(shootTr.pos, QuatLookAt(shootTr.pos, TransformToParentPoint(shootTr, Vec(0,0,-1))))

			-- Align y rot
			local leftDir = QuatToDir(shootTr.rot)
			local leftDirCopy = VecCopy(leftDir)

			-- Slerp X and Z

			-- Quat look crosshair
			local leftRotCrosshair = QuatLookAt(shootTr.pos, crosshairPos)
			local leftRotCrosshairDir = QuatToDir(leftRotCrosshair)
			local leftRotCrosshairDirY = leftRotCrosshairDir[2]

			-- dir look crosshair
			local leftRot = DirToQuat(Vec(leftDirCopy[1], leftRotCrosshairDirY, leftDirCopy[3]))
			shootTr.rot = leftRot

			-- Spread
			shootTr.rot = QuatRotateQuat(shootTr.rot, QuatEuler((math.random()-0.5)*spread,(math.random()-0.5)*spread,(math.random()-0.5)*spread))
			rejectAllBodies(robot.allBodies)
			createMissile(shootTr, activeMissiles, missilePresets.rocket, robot.allBodies)
		end

	end
end
function aimsUpdateCustom()
	for i=1, #aims do
		local aim = aims[i]
		local playerPos = getOuterCrosshairWorldPos()
		local toPlayer = VecNormalize(VecSub(playerPos, GetBodyTransform(aim.body).pos))
		local fwd = TransformToParentVec(GetBodyTransform(robot.body), Vec(0, 0, -1))
		if player.isDrivingRobot then
			local v = 2
			local f = 20
			local wt = GetBodyTransform(aim.body)
			local toPlayerOrientation = QuatLookAt(wt.pos, playerPos)
			ConstrainOrientation(aim.body, robot.body, wt.rot, toPlayerOrientation, v, f)
		else
			local v = 2
			local f = 20
			local wt = GetBodyTransform(aim.body)
			-- local fwdPos = TransformToParentPoint(GetBodyTransform(robot.body), Vec(0,0,-100))
			local toPlayerOrientation = QuatLookAt(wt.pos, QuatToDir(robot.dir))
			ConstrainOrientation(aim.body, robot.body, wt.rot, toPlayerOrientation, v, f)
		end
	end
end



--> PLAYER
player = {}
player.isDrivingRobot = false
function playerDriveRobot(dt, pos)

	--+ Update player values.
	SetPlayerTransform(Transform(pos))
	SetPlayerHealth(1)
	SetString("game.player.tool", 'sledge')
	SetPlayerVelocity(Vec())
	SetPlayerGroundVelocity(Vec())


	manageCamera(UI_OPTIONS, robot.cameraHeight)

	if not UI_OPTIONS then

		--+ Override robot aim.
		headTurnTowards(crosshairPos)
		headUpdate(dt)

		--+ Override robot movement.
		-- processMovement()

		--+ Override robot weapons.
		processWeapons()

	end

end
function playerCheckRobot()

	if robot.enabled then

		if player.isDrivingRobot then

			--+ Exit robot.
			if InputPressed('interact') or InputPressed('e') then
				player.isDrivingRobot = false
				local playerExitTr = Transform(TransformToParentPoint(bodyTr, Vec(0,0,-2)))
				SetPlayerTransform(playerExitTr)
			end

		elseif InputPressed('interact') or InputPressed('e') then

			--+ Enter robot.
			if GetPlayerInteractBody() == head.body then
				player.isDrivingRobot = true
			end

		else

			local headFwdPos = TransformToParentPoint(bodyTr, (Vec(0,0,-1)))
			headTurnTowards(headFwdPos)

		end

	else

		player.isDrivingRobot = false
		SetBool('level.playerIsDrivingRobot', false)

	end

end



--> OTHER
function debugRobot()
	dbw('model', robot.model)
end
function setRobotUnbreakable(setUnbreakable)

	local func_setter

	-- Set body.
	if setUnbreakable then
		func_setter = SetTag
	else
		func_setter = RemoveTag
	end

	local bodies = robot.allBodies
	for key, body in pairs(bodies) do

		-- Set body.
		func_setter(body, 'unbreakable')

		-- Set body shapes.
		local shapes = GetBodyShapes(body)
		for key, shape in pairs(shapes) do
			func_setter(shape, 'unbreakable')
		end

	end

end
function initPlayerDrivingRobot()

	-- if GetBool('level.robotExists') then

	-- 	if not GetBool('level.playerIsDrivingRobot') then
	-- 		-- player.isDrivingRobot = true
	-- 		SetBool('level.playerIsDrivingRobot', true)
	-- 	end

	-- end

end
function manageRobotHealth()

	-- if robot.enabled and getRobotMass() < robot.health*0.9 then

		-- print('robot died')

		-- local pos = AabbGetBodyCenterPos(robot.body)

		-- feetCollideLegs(false)

		-- robot.enabled = false

		-- Explosion(pos, 1)

		-- ParticleReset()
        -- ParticleType("smoke")
        -- ParticleColor(0.86,0.5,0.3, 0.9,0.1,0.1)
        -- ParticleRadius(5, 8, "linear")
        -- ParticleTile(5)
        -- ParticleGravity(0.5)
        -- ParticleEmissive(5.0, 1, "easein")
        -- ParticleRotation(rdm(), 0, "linear")
        -- ParticleStretch(5)
        -- ParticleCollide(0.5)

        -- SpawnParticle(pos, Vec(0, 0, 0), 5)
        -- SpawnParticle(pos, Vec(0, 0, 0), 5)
        -- SpawnParticle(pos, Vec(0, 0, 0), 5)
        -- SpawnParticle(pos, Vec(0, 0, 0), 5)

	-- end

end
function getRobotMass()
	local mass = 0
	for key, body in pairs(robot.allBodies) do
		mass = mass + GetBodyMass(body)
		-- DrawBodyOutline(body, 1,0,0, 1)
	end
	return mass
end
