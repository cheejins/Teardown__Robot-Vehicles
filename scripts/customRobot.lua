
--= ROBOT DRIVING
do

	--> SCRIPT
	function initCustom()
		CAMERA = {}
		CAMERA.xy = {UiCenter(), UiMiddle()}

		initCamera()
		initDebug()
		initWeapons()
		initTimers()
	end
	function tickCustom(dt)

		manageCamera()
		runTimers()
		manageWeapons()


		local bodyTr = GetBodyTransform(robot.body)
		local headTr = GetBodyTransform(head.body)
		local camTr = GetCameraTransform()
		local crosshairPos = getOuterCrosshairWorldPos()

		--+ Override robot aim.
		DrawDot(crosshairPos, 0.5,0.5, 1,0,0, 1, false)
		robot.playerPos = crosshairPos
		-- robotTurnTowards(crosshairPos)
		headTurnTowards(crosshairPos)
		headUpdate(dt)

		--+ Override robot movement.
		processMovement()

		--+ Weapons
		if InputDown('lmb') then

			PlayLoop(LoadLoop('../snd/bulletLoop.ogg'), bodyTr.pos, 3)

			if timers.gun.bullets.time <= 0 then

				TimerResetTime(timers.gun.bullets)

				local spread = (math.random() * 2) + 3

				local shootTr = Transform(TransformToParentPoint(headTr, (Vec(0,0,-3))), QuatLookAt(headTr.pos, crosshairPos))
				rejectAllBodies(robot.allBodies)

				local leftTr = Transform(TransformToParentPoint(shootTr, Vec(-1, 0, 0)), shootTr.rot)
				leftTr = Transform(leftTr.pos, QuatLookAt(leftTr.pos, crosshairPos))
				leftTr.rot = QuatRotateQuat(leftTr.rot, QuatEuler((math.random()-0.5)*spread,(math.random()-0.5)*spread,(math.random()-0.5)*spread))

				local rightTr = Transform(TransformToParentPoint(shootTr, Vec(1, 0, 0)), shootTr.rot)
				rightTr = Transform(rightTr.pos, QuatLookAt(rightTr.pos, crosshairPos))
				rightTr.rot = QuatRotateQuat(rightTr.rot, QuatEuler((math.random()-0.5)*spread,(math.random()-0.5)*spread,(math.random()-0.5)*spread))


				createBullet(leftTr, activeBullets, bulletPresets.mg.light, {})
				createBullet(rightTr, activeBullets, bulletPresets.mg.light, {})
			end

		end

		if InputDown('rmb') then

			if timers.gun.rockets.time <= 0 then

				TimerResetTime(timers.gun.rockets)

				PlaySound(rocketSound, bodyTr.pos, 3)

				local spread = 1
				rejectAllBodies(robot.allBodies)

				local shootTr = Transform(TransformToParentPoint(headTr, (Vec(0,0,-3))), QuatLookAt(headTr.pos, crosshairPos))
				shootTr.rot = QuatRotateQuat(shootTr.rot, QuatEuler((math.random()-0.5)*spread,(math.random()-0.5)*spread,(math.random()-0.5)*spread))
				createMissile(shootTr, activeMissiles, missilePresets.rocket, {})
			end

		end


		SetPlayerTransform(bodyTr)
		SetPlayerHealth(1)

	end
	function updateCustom(dt)

		-- if InputDown('w') then
			-- navigationUpdate(dt)
		-- end

	end
	function drawCustom()
		CAMERA.xy = {UiCenter(), UiMiddle()}
	end



	--> MOVEMENT
	processMovement = function ()

		local bodyTr = GetBodyTransform(robot.body)
		local camTr = GetCameraTransform()
		local crosshairPos = getOuterCrosshairWorldPos()


		if InputDown('w') then

			-- navigationSetTarget(crosshairPos, 0)
			robotWalk(crosshairPos)
			dbl(bodyTr.pos, crosshairPos, 1,1,0, 1)

		end

		if InputDown('a') then

			local lookTr = Transform(bodyTr.pos, camTr.rot)
			local moveDir = TransformToParentPoint(lookTr, Vec(-1,0,0))
			robotWalk(moveDir)
			dbl(bodyTr.pos, moveDir, 1,1,0, 1)

		end

		if InputDown('d') then

			local lookTr = Transform(bodyTr.pos, camTr.rot)
			local moveDir = TransformToParentPoint(lookTr, Vec(1,0,0))
			robotWalk(moveDir)
			dbl(bodyTr.pos, moveDir, 1,1,0, 1)

		end

		if InputDown('s') then

			local lookTr = Transform(bodyTr.pos, camTr.rot)
			local moveDir = TransformToParentPoint(lookTr, Vec(0,0,1))
			robotWalk(moveDir)
			dbl(bodyTr.pos, moveDir, 1,1,0, 1)

		else
			navigationClear()
		end

		--+ Jump
		if InputPressed('space') then
			SetBodyVelocity(robot.body, VecAdd(GetBodyVelocity(robot.body), Vec(0,10,0)))
		end

		--+ Crouch
		if InputPressed('ctrl') then
			SetBodyVelocity(robot.body, VecAdd(GetBodyVelocity(robot.body), Vec(0,-5,0)))
			DebugPrint('Teabag' .. sfnTime())
		end
	end
	robotWalk = function (pos, dir)
		robot.dir = dir or VecCopy(VecNormalize(VecSub(pos, robot.transform.pos)))
		local dirDiff = VecDot(VecScale(robot.axes[3], -1), robot.dir)
		local speedScale = math.max(0.25, dirDiff)
		speedScale = speedScale * clamp(1.0 - navigation.vertical, 0.3, 1.0)
		robot.speed = config.speed * speedScale
	end

	--> CAMERA
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
		local crosshairQuat = QuatDir(crosshairDir)
		local crosshairTr = Transform(GetCameraTransform().pos, crosshairQuat)

		return crosshairTr

	end

end