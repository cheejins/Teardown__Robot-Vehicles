--================================
--= Robot Vehicles
--= By: Cheejins
--================================


--> SCRIPT
do
	function initCustom()

		CAMERA = {}
		CAMERA.xy = {UiCenter(), UiMiddle()}

		SetTag(head.body, 'interact')
		SetDescription(head.body, 'Drive Robot')
		robot.playerInVehicle = true

		initCamera()
		initDebug()
		initWeapons()
		initTimers()

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
		checkPlayerCustomVehicle()

		--+ Drive robot.
		if player.drivingRobot then
			playerDriveRobot(dt, bodyTr.pos)
		end

	end
	function updateCustom(dt)
	end
	function drawCustom()

		do UiPush()
		UiPop() end

		CAMERA.xy = {UiCenter(), UiMiddle()}

		do UiPush()
			UiAlign('center middle')
			UiTranslate(UiCenter(), UiMiddle())
			UiImageBox('MOD/ROBOT_VEHICLE_PREFAB/img/crosshair.png', 40,40, 1,1)
		UiPop() end

		do UiPush()
			UiTranslate(UiCenter(), UiHeight() - 30)
			UiFont('bold.ttf', 24)
			UiColor(0.75,0.75,0.75)
			UiAlign('center top')
			UiText('Press "o" to show the welcome screen.')
		UiPop() end

		if not GetBool('LEVEL.welcome') then
			do UiPush()
				UiTranslate(UiCenter(), UiMiddle())
				UiAlign('center middle')
				UiImageBox('MOD/ROBOT_VEHICLE_PREFAB/img/welcome.png', UiWidth()*0.7, UiHeight()*0.7, 1, 1)

				if InputPressed('any') then
					SetBool('LEVEL.welcome', not GetBool('LEVEL.welcome'))
				end

			UiPop() end
		end

		if InputPressed('o') then
			SetBool('LEVEL.welcome', not GetBool('LEVEL.welcome'))
		end

	end
end

--> MOVEMENT
do
	processMovement = function ()

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
			robot.speedScale = 2
		else
			robot.speedScale = 1
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

		--. navigationClear()

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
	manageCamera = function()
		local mx, my = InputValue("mousedx"), InputValue("mousedy")
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

				PlaySound(rocketSound, bodyTr.pos, 3)

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
	player.drivingRobot = false

	function playerDriveRobot(dt, pos)

		manageCamera()

		--+ Override robot aim.
		headTurnTowards(crosshairPos)
		headUpdate(dt)

		--+ Override robot movement.
		processMovement()

		--+ Override robot weapons.
		processWeapons()

		--+ Update player values.
		SetPlayerTransform(Transform(pos))
		SetPlayerHealth(1)
		SetString("game.player.tool", 'sledge')

	end

	function checkPlayerCustomVehicle()

		if player.drivingRobot then

			--+ Exit robot.
			if InputPressed('interact') or InputPressed('e') then
				player.drivingRobot = false
				local playerExitTr = Transform(TransformToParentPoint(bodyTr, Vec(0,0,-2)))
				SetPlayerTransform(playerExitTr)
			end

		elseif InputPressed('interact') or InputPressed('e') then

			--+ Exit robot.
			if GetPlayerInteractBody() == head.body then
				player.drivingRobot = true
			end

		end

	end

end
