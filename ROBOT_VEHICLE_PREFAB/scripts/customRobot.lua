--================================
--= Robot Vehicles
--= By: Cheejins
--================================


--> SCRIPT
do

	function initCustom()

		CAMERA = {}
		CAMERA.xy = {UiCenter(), UiMiddle()}
		missileSound = LoadSound("../snd/launchSound.ogg")
		SetTag(head.body, 'interact')
		SetDescription(head.body, 'Drive Robot')

		robot.followPlayer = regGetBool('robot.followPlayer')

		initPlayerDrivingRobot()
		setRobotUnbreakable(false)

		initSounds()
		initRobotPreset()
		initCamera()
		initDebug()
		initProjectiles()
		initWeapons()
		initTimers()
		initUi()

	end
	function tickCustom(dt)

		--+ Global robot variables.
		bodyTr = GetBodyTransform(robot.body)
		headTr = GetBodyTransform(head.body)
		camTr = GetCameraTransform()
		crosshairPos = getOuterCrosshairWorldPos()

		--+ Constant functions.
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

			uiManageGameOptions()

			CAMERA.xy = {UiCenter(), UiMiddle()}

			-- Crosshair
			do UiPush()
				local crosshairSize = 50*robot.crosshairScale
				UiAlign('center middle')
				UiTranslate(UiCenter(), UiMiddle())
				UiImageBox(robot.crosshair, crosshairSize, crosshairSize, 1,1)
			UiPop() end

			-- if headShootTr then
			-- 	local cx, cy = UiWorldToPixel(headShootTr.pos)
			-- 	do UiPush()
			-- 		UiTranslate(cx, cy)
			-- 		UiAlign('center middle')
			-- 		UiImageBox(robot.crosshair, 40,40, 1,1)
			-- 	UiPop() end
			-- end

			-- Bottom info
			do UiPush()
				UiTranslate(UiCenter(), UiHeight() - 90)
				UiFont('bold.ttf', 24)
				UiColor(0.75,0.75,0.75)
				UiAlign('center top')

				UiText('Mod Version: '..GetModVersion())
				UiTranslate(0, 30)

				UiText('Press "o" to show the options menu.')
				UiTranslate(0, 30)

				UiText('Press "i" to show the welcome screen.')

			UiPop() end

			-- if not GetBool('LEVEL.welcome') then
			-- 	do UiPush()

			-- 		UiTranslate(UiCenter(), UiMiddle())
			-- 		UiAlign('center middle')
			-- 		UiImageBox('../img/welcome.png', UiWidth()*0.7, UiHeight()*0.7, 1, 1)

			-- 		if InputPressed('any') then
			-- 			SetBool('LEVEL.welcome', not GetBool('LEVEL.welcome'))
			-- 		end

			-- 	UiPop() end
			-- end

			-- if InputPressed('i') then
			-- 	SetBool('LEVEL.welcome', not GetBool('LEVEL.welcome'))
			-- end

		end

	end

end



--> MOVEMENT
processMovement = function ()

	-- navigationClear()

	--+ WASD
	if InputDown('up') then
		robotWalk(crosshairPos)
		dbl(bodyTr.pos, crosshairPos, 1,1,0, 1)
	end
	if InputDown('left') then
		local lookTr = Transform(bodyTr.pos, camTr.rot)
		local moveDir = TransformToParentPoint(lookTr, Vec(-1,0,0))
		robotWalk(moveDir)
	end
	if InputDown('right') then
		local lookTr = Transform(bodyTr.pos, camTr.rot)
		local moveDir = TransformToParentPoint(lookTr, Vec(1,0,0))
		robotWalk(moveDir)
	end
	if InputDown('down') then
		local lookTr = Transform(bodyTr.pos, camTr.rot)
		local moveDir = TransformToParentPoint(lookTr, Vec(0,0,1))
		robotWalk(moveDir)
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
		DebugPrint('Teabag initiated ' .. sfnTime())
	end

end
robotWalk = function (pos, dir)
	robot.dir = dir or VecCopy(VecNormalize(VecSub(pos, robot.transform.pos)))
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

			PlayRandomSound(Sounds.weap_secondary.shoot, bodyTr.pos, 2)

			for key, weap in pairs(robot.weaponObjects.secondary) do

				local weapTr = GetLightTransform(weap.light)
				local weapBodyTr = GetBodyTransform(weap.body)


				-- Aim adjust. The shoot location is slightly higher than the weapon body.
				-- Moves the aim pos just above where the crosshair (weapon body aligned) hits the world.
				local shootTr = TransformCopy(weapTr)
				local pos_weapRelBody TransformToLocalPoint(weapBodyTr, weapTr.pos)
				pos_trueAim = VecAdd(crosshairPos, VecScale(pos_weapRelBody, -1))
				rot_trueAim = QuatLookAt(shootTr.pos, pos_trueAim)
				shootTr.rot = rot_trueAim

				-- Shoot.
				createProjectile(shootTr, Projectiles, ProjectilePresets.aeon_secondary, robot.allBodies)

				-- Exhaust particles.
				local exhaustTr = TransformCopy(weapTr)
				exhaustTr.pos = TransformToParentPoint(weapTr, Vec(0,0,1.5))
				exhaustTr.rot = QuatTrLookBack(weapTr)
				SpawnParticle("smoke", exhaustTr.pos, VecScale(QuatToDir(exhaustTr.rot), 3), 1,1,1,1)
				SpawnParticle("smoke", exhaustTr.pos, VecScale(QuatToDir(exhaustTr.rot), 1), 1,1,1,1)

			end

		end

	end

	if InputDown('rmb') then

		if timers.aeon.special.time <= 0 then
			TimerResetTime(timers.aeon.special)

			PlayRandomSound(Sounds.weap_special.shoot, bodyTr.pos)
			PlayRandomSound(Sounds.weap_special.hit, bodyTr.pos, 0.5)

			createProjectile(GetLightTransform(robot.weaponObjects.special[math.random(1, #robot.weaponObjects.special)].light), Projectiles, ProjectilePresets.aeon_special, robot.allBodies)

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

	manageCamera(UI_OPTIONS)

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
