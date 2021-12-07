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

		if not GetBool('level.playerIsDrivingRobot') then
			player.isDrivingRobot = true
			SetBool('level.playerIsDrivingRobot', true)
		end

		initCamera()
		initDebug()
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
		--. robot.playerPos = crosshairPos

		--+ Constant functions.
		runTimers()
		manageProjectiles()

		--+ Check and set player robot vehicle.
		playerCheckRobot()

		--+ Drive robot.
		if player.isDrivingRobot then
			playerDriveRobot(dt, bodyTr.pos)
		end

	end
	function updateCustom(dt)
		robot.speedScale = regGetFloat('robot.move.speed')
		timers.gun.bullets.rpm = regGetFloat('robot.weapon.bullet.rpm')
		timers.gun.rockets.rpm = regGetFloat('robot.weapon.rocket.rpm')
		processMovement()
	end
	function drawCustom()

		if player.isDrivingRobot and robot.enabled then

			uiManageGameOptions()

			CAMERA.xy = {UiCenter(), UiMiddle()}

			do UiPush()
				UiAlign('center middle')
				UiTranslate(UiCenter(), UiMiddle())
				UiImageBox('../img/crosshair.png', 40,40, 1,1)
			UiPop() end

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

			if not GetBool('LEVEL.welcome') then
				do UiPush()
					UiTranslate(UiCenter(), UiMiddle())
					UiAlign('center middle')
					UiImageBox('../img/welcome.png', UiWidth()*0.7, UiHeight()*0.7, 1, 1)

					if InputPressed('any') then
						SetBool('LEVEL.welcome', not GetBool('LEVEL.welcome'))
					end

				UiPop() end
			end

			if InputPressed('i') then
				SetBool('LEVEL.welcome', not GetBool('LEVEL.welcome'))
			end

		end

	end

end

--> MOVEMENT
do
	processMovement = function ()

		-- navigationClear()

		--+ WASD
		if InputDown('w') then
			robotWalk(crosshairPos)
			dbl(bodyTr.pos, crosshairPos, 1,1,0, 1)
		end
		if InputDown('a') then
			local lookTr = Transform(bodyTr.pos, camTr.rot)
			local moveDir = TransformToParentPoint(lookTr, Vec(-1,0,0))
			robotWalk(moveDir)
		end
		if InputDown('d') then
			local lookTr = Transform(bodyTr.pos, camTr.rot)
			local moveDir = TransformToParentPoint(lookTr, Vec(1,0,0))
			robotWalk(moveDir)
		end
		if InputDown('s') then
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

end

--> CAMERA
do
	initCamera = function()
		cameraX = 0
		cameraY = 0
		zoom = 2
	end
	manageCamera = function(disableRotation)
		local mx, my = InputValue("mousedx"), InputValue("mousedy")
		disableRotation = disableRotation or false
		if disableRotation then mx, my = 0,0 end
		cameraX = cameraX - mx / 10
		cameraY = cameraY - my / 10
		cameraY = clamp(cameraY, -75, 75)
		local cameraRot = QuatEuler(cameraY, cameraX, 0)
		local cameraT = Transform(VecAdd(GetBodyTransform(robot.body).pos, 5), cameraRot)
		zoom = zoom - InputValue("mousewheel") * 2.5
		zoom = clamp(zoom, 2, 20)
		local cameraPos = TransformToParentPoint(cameraT, Vec(0, 2, zoom))
		local camera = Transform(VecLerp(cameraPos, GetCameraTransform().pos, 0.5), cameraRot)
		SetCameraTransform(camera)
	end
	getOuterCrosshairWorldPos = function()

		local crosshairTr = getCrosshairTr()
		rejectAllBodies(robot.allBodies)
		local crosshairHit, crosshairHitPos = RaycastFromTransform(crosshairTr, 200)
		if crosshairHit then
			return crosshairHitPos
		else
			return nil
		end

	end
	getCrosshairTr = function(pos)

		pos = pos or GetCameraTransform()

		local crosshairDir = UiPixelToWorld(CAMERA.xy[1], CAMERA.xy[2])
		local crosshairQuat = DirToQuat(crosshairDir)
		local crosshairTr = Transform(GetCameraTransform().pos, crosshairQuat)

		return crosshairTr

	end
end

--> WEAPONS
do
	function processWeapons()

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
end

--> PLAYER
do

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

				--+ Exit robot.
				if GetPlayerInteractBody() == head.body then
					player.isDrivingRobot = true
				end

			end

		else

			player.isDrivingRobot = false

		end

	end


end
