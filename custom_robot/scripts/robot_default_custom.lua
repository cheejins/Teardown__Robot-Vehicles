--================================================================
--= Robot Vehicles
--= By: Cheejins
--================================================================
--= This script is only used for the built in robots.
--================================================================

--> SCRIPT
function initCustom()

	CAMERA = {}
	CAMERA.xy = {UiCenter(), UiMiddle()}
	missileSound = LoadSound("../snd/launchSound.ogg")
	SetTag(Eyes.body, 'interact')
	SetDescription(Eyes.body, 'Drive Robot')
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

	for key, floor in pairs(FindBodies('robotFloor', true)) do
		Delete(floor)
	end

end
function tickCustom(dt)

	--+ Global robot variables.
	bodyTr = GetBodyTransform(robot.body)
	headTr = GetBodyTransform(Eyes.body)
	camTr = GetCameraTransform()
	crosshairPos = getOuterCrosshairWorldPos()

	--+ Constant functions.
	manageRobotHealth()
	runTimers()
	-- manageProjs()
	-- manageActiveProjectiles()
	-- aimsUpdateCustom()

	--+ Check and set player robot vehicle.
	playerCheckRobot()

	--+ Drive robot.
	if player.isDrivingRobot then
		local playerPos = TransformToParentPoint(bodyTr, Vec(math.random() - 0.5,0, math.random() - 0.5))
		-- DrawDot(playerPos)
		playerDriveRobot(dt, playerPos)
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
			UiAlign('center middle')

			do UiPush()
				UiAlign('right top')
				UiTranslate(UiWidth(), 0)
				UiText('v' .. GetModVersion())
			UiPop() end

			-- do UiPush()
			-- 	UiTranslate(UiCenter(), UiMiddle() + 50)
			-- 	-- UiAlign('right middle')
			-- 	-- UiText('WEAPON: ')

			-- 	if weaponStatus == "Idle" then
			-- 		UiColor(0,1,0, 0.5)
			-- 	elseif weaponStatus == "Charging" then
			-- 		UiColor(1,1,0, 0.5)
			-- 	elseif weaponStatus == "Firing" then
			-- 		UiColor(1,0,0, 0.5)
			-- 	end

			-- 	UiAlign('center middle')
			-- 	UiText(weaponStatus)

			-- UiPop() end

		UiPop() end



		uiManageGameOptions()

		CAMERA.xy = {UiCenter(), UiMiddle()}

		-- Crosshair
		do UiPush()

			if weaponStatus == "Idle" then
				UiColor(0,1,0, 1)
			elseif weaponStatus == "Charging" then
				UiColor(1,1,0, 1)
			elseif weaponStatus == "Firing" then
				UiColor(1,0,0, 1)
			end

			-- local crosshairSize = 50*robot.crosshairScale
			UiAlign('center middle')
			UiTranslate(UiCenter(), UiMiddle())
			UiImageBox("MOD/custom_robot/img/crosshair_default.png", 50, 50, 0,0)

			UiColor(1,1,1, 1)
			UiImageBox("ui/hud/location-dot.png", 6, 6, 0,0)


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

	isShooting = InputDown('lmb')

end
function processWeapons_mech_aeon()

	-- Draw dots at shooting positions.
	-- for key, weap in pairs(robot.weaponObjects) do
	-- 	for key, obj in pairs(weap) do
	-- 		local pos = GetLightTransform(obj.light).pos
	-- 		DrawDot(pos, 0.1,0.1, 1,1,1, 1, false)
	-- 	end
	-- end

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
			if GetPlayerInteractBody() == Eyes.body then
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
