#include "camera.lua"
#include "robot_default_custom.lua"
#include "debug.lua"
#include "particles.lua"
#include "projectiles.lua"
#include "registry.lua"
#include "robotPreset.lua"
#include "script/common.lua"
#include "sounds.lua"
#include "timers.lua"
#include "ui.lua"
#include "ui_components.lua"
#include "umf.lua"
#include "utility.lua"
#include "version.lua"
#include "weapons.lua"


weaponStatus = "Idle"


--= MAIN
do
	--> Script
	do

		function init()
			configInit()
			robotInit()
			hoverInit()
			headInit()
			sensorInit()
			wheelsInit()
			feetInit()
			aimsInit()
			weaponsInit()
			navigationInit()
			hearingInit()
			stackInit()

			--> Sound
			patrolLocations = FindLocations("patrol")
			shootSound = LoadSound("tools/gun0.ogg", 8.0)
			rocketSound = LoadSound("tools/launcher0.ogg", 7.0)
			local nomDist = 7.0
			if config.stepSound == "s" then nomDist = 5.0 end
			if config.stepSound == "l" then nomDist = 9.0 end
			stepSound = LoadSound("robot/step-" .. config.stepSound .. "0.ogg", nomDist)
			headLoop = LoadLoop("robot/head-loop.ogg", 7.0)
			turnLoop = LoadLoop("robot/turn-loop.ogg", 7.0)
			walkLoop = LoadLoop("robot/walk-loop.ogg", 7.0)
			rollLoop = LoadLoop("robot/roll-loop.ogg", 7.0)
			chargeLoop = LoadLoop("robot/charge-loop.ogg", 8.0)
			alertSound = LoadSound("robot/alert.ogg", 9.0)
			huntSound = LoadSound("robot/hunt.ogg", 9.0)
			idleSound = LoadSound("robot/idle.ogg", 9.0)
			fireLoop = LoadLoop("tools/blowtorch-loop.ogg")
			disableSound = LoadSound("robot/disable0.ogg")

			initCustom() --!

		end

		function update(dt)
			if robot.deleted then
				return
			else
				if not IsHandleValid(robot.body) then
					for i=1, #robot.allBodies do
						Delete(robot.allBodies[i])
					end
					for i=1, #robot.allJoints do
						Delete(robot.allJoints[i])
					end
					robot.deleted = true
				end
			end

			if robot.activateTrigger ~= 0 then
				if IsPointInTrigger(robot.activateTrigger, GetPlayerCameraTransform().pos) then
					RemoveTag(robot.body, "inactive")
					robot.activateTrigger = 0
				end
			end

			if HasTag(robot.body, "inactive") then
				robot.inactive = true
				return
			else
				if robot.inactive then
					robot.inactive = false
					--Reset robot pose
					local sleep = HasTag(robot.body, "sleeping")
					for i=1, #robot.allBodies do
						SetBodyTransform(robot.allBodies[i], robot.initialBodyTransforms[i])
						SetBodyVelocity(robot.allBodies[i], Vec(0,0,0))
						SetBodyAngularVelocity(robot.allBodies[i], Vec(0,0,0))
						if sleep then
							--If robot is sleeping make sure to not wake it up
							SetBodyActive(robot.allBodies[i], false)
						end
					end
				end
			end

			if HasTag(robot.body, "sleeping") then
				if IsBodyActive(robot.body) then
					wakeUp = true
				end
				local vol, pos = GetLastSound()
				if vol > 0.2 then
					if robot.investigateTrigger == 0 or IsPointInTrigger(robot.investigateTrigger, pos) then
						wakeUp = true
					end
				end
				if wakeUp then
					RemoveTag(robot.body, "sleeping")
				end
				return
			end

			robotUpdate(dt)
			wheelsUpdate(dt)

			if not robot.enabled then
				return
			end

			feetUpdate(dt)

			if IsPointInWater(robot.bodyCenter) then
				PlaySound(disableSound, robot.bodyCenter)
				for i=1, #robot.allShapes do
					SetShapeEmissiveScale(robot.allShapes[i], 0)
				end
				SetTag(robot.body, "disabled")
				robot.enabled = false
			end

			robot.stunned = clamp(robot.stunned - dt, 0.0, 8.0)
			if robot.stunned > 0 then
				Eyes.seenTimer = 0
				weaponsReset()
				return
			end

			hoverUpdate(dt)

			if player.isDrivingRobot then
				sensorUpdate(dt)
				headUpdate(dt)
				aimsUpdate(dt)
				weaponsUpdate(dt)
				hearingUpdate(dt)
				stackUpdate(dt)
			end


			robot.speedScale = 1.5
			robot.speed = 0
			-- local state = stackTop()
			local state = "none"

			if state.id == "none" then
				-- if config.patrol then
				-- 	stackPush("patrol")
				-- else
				-- 	stackPush("roam")
				-- end
			end

			if state.id == "roam" then
				-- if not state.nextAction then
				-- 	state.nextAction = "move"
				-- elseif state.nextAction == "move" then
				-- 	local randomPos
				-- 	if robot.roamTrigger ~= 0 then
				-- 		randomPos = getRandomPosInTrigger(robot.roamTrigger)
				-- 		randomPos = truncateToGround(randomPos)
				-- 	else
				-- 		local rndAng = rnd(0, 2*math.pi)
				-- 		randomPos = VecAdd(robot.transform.pos, Vec(math.cos(rndAng)*6.0, 0, math.sin(rndAng)*6.0))
				-- 	end
				-- 	local s = stackPush("navigate")
				-- 	s.timeout = 1
				-- 	s.pos = randomPos
				-- 	state.nextAction = "search"
				-- elseif state.nextAction == "search" then
				-- 	stackPush("search")
				-- 	state.nextAction = "move"
				-- end
			end


			if state.id == "patrol" then
				-- if not state.nextAction then
				-- 	state.index = getClosestPatrolIndex()
				-- 	state.nextAction = "move"
				-- elseif state.nextAction == "move" then
				-- 	markPatrolLocationAsActive(state.index)
				-- 	local nav = stackPush("navigate")
				-- 	nav.pos = GetLocationTransform(patrolLocations[state.index]).pos
				-- 	state.nextAction = "search"
				-- elseif state.nextAction == "search" then
				-- 	stackPush("search")
				-- 	state.index = getNextPatrolIndex(state.index)
				-- 	state.nextAction = "move"
				-- end
			end


			if state.id == "search" then
				if state.activeTime > 2.5 then
					if not state.turn then
						robotSetDirAngle(robotGetDirAngle() + math.random(2, 4))
						state.turn = true
					end
					if state.activeTime > 6.0 then
						stackPop()
					end
				end
				if state.activeTime < 1.5 or state.activeTime > 3 and state.activeTime < 4.5 then
					Eyes.dir = TransformToParentVec(robot.transform, Vec(-5, 0, -1))
				else
					Eyes.dir = TransformToParentVec(robot.transform, Vec(5, 0, -1))
				end
			end


			if state.id == "investigate" then
				--! disable investigating.
				-- if not state.nextAction then
				-- 	local pos = state.pos
				-- 	robotTurnTowards(state.pos)
				-- 	headTurnTowards(state.pos)
				-- 	local nav = stackPush("navigate")
				-- 	nav.pos = state.pos
				-- 	nav.timeout = 5.0
				-- 	state.nextAction = "search"
				-- elseif state.nextAction == "search" then
				-- 	stackPush("search")
				-- 	state.nextAction = "done"
				-- elseif state.nextAction == "done" then
				-- 	PlaySound(idleSound, robot.bodyCenter)
				-- 	stackPop()
				-- end
			end

			if state.id == "move" then
				-- robotTurnTowards(state.pos)
				-- robot.speed = config.speed
				-- head.dir = VecCopy(robot.dir)
				-- local d = VecLength(VecSub(state.pos, robot.transform.pos))
				-- if d < 2 then
				-- 	robot.speed = 0
				-- 	stackPop()
				-- else
				-- 	if robot.blocked > 0.5 then
						-- stackPush("unblock")
				-- 	end
				-- end
			end

			if state.id == "unblock" then
				-- if not state.dir then
				-- 	if math.random(0, 10) < 5 then
				-- 		state.dir = TransformToParentVec(robot.transform, Vec(-1, 0, -1))
				-- 	else
				-- 		state.dir = TransformToParentVec(robot.transform, Vec(1, 0, -1))
				-- 	end
				-- 	state.dir = VecNormalize(state.dir)
				-- else
				-- 	robot.dir = state.dir
				-- 	robot.speed = -math.min(config.speed, 2.0)
				-- 	if state.activeTime > 1 then
				-- 		stackPop()
				-- 	end
				-- end
			end

			--Hunt player
			if state.id == "hunt" then
				if not state.init then
					navigationClear()
					state.init = true
					state.headAngle = 0
					state.headAngleTimer = 0
				end
				if robot.distToPlayer < 4.0 then
					robot.dir = VecCopy(robot.dirToPlayer)
					Eyes.dir = VecCopy(robot.dirToPlayer)
					robot.speed = 0
					navigationClear()
				else
					navigationSetTarget(Eyes.lastSeenPos, 1.0 + clamp(Eyes.timeSinceLastSeen, 0.0, 4.0))
					robot.speedScale = config.huntSpeedScale
					navigationUpdate(dt)
					if Eyes.canSeePlayer then
						Eyes.dir = VecCopy(robot.dirToPlayer)
						state.headAngle = 0
						state.headAngleTimer = 0
					else
						state.headAngleTimer = state.headAngleTimer + dt
						if state.headAngleTimer > 1.0 then
							if state.headAngle > 0.0 then
								state.headAngle = rnd(-1.0, -0.5)
							elseif state.headAngle < 0 then
								state.headAngle = rnd(0.5, 1.0)
							else
								state.headAngle = rnd(-1.0, 1.0)
							end
							state.headAngleTimer = 0
						end
						Eyes.dir = QuatRotateVec(QuatEuler(0, state.headAngle, 0), robot.dir)
					end
				end
				if navigation.state ~= "move" and Eyes.timeSinceLastSeen < 2 then
					--Turn towards player if not moving
					robot.dir = VecCopy(robot.dirToPlayer)
				end
				if navigation.state ~= "move" and Eyes.timeSinceLastSeen > 2 and state.activeTime > 3.0 and VecLength(GetBodyVelocity(robot.body)) < 1 then
					if VecDist(Eyes.lastSeenPos, robot.bodyCenter) > 3.0 then
						stackClear()
						local s = stackPush("investigate")
						s.pos = VecCopy(Eyes.lastSeenPos)
					else
						stackClear()
						stackPush("huntlost")
					end
				end
			end

			if state.id == "huntlost" then
				if not state.timer then
					state.timer = 6
					state.turnTimer = 1
				end
				state.timer = state.timer - dt
				Eyes.dir = VecCopy(robot.dir)
				if state.timer < 0 then
					PlaySound(idleSound, robot.bodyCenter)
					stackPop()
				else
					state.turnTimer = state.turnTimer - dt
					if state.turnTimer < 0 then
						robotSetDirAngle(robotGetDirAngle() + math.random(2, 4))
						state.turnTimer = rnd(0.5, 1.5)
					end
				end
			end

			--Avoid player
			if state.id == "avoid" then
				if not state.init then
					navigationClear()
					state.init = true
					state.headAngle = 0
					state.headAngleTimer = 0
				end

				local distantPatrolIndex = getDistantPatrolIndex(GetPlayerTransform().pos)
				local avoidTarget = GetLocationTransform(patrolLocations[distantPatrolIndex]).pos
				navigationSetTarget(avoidTarget, 1.0)
				robot.speedScale = config.huntSpeedScale
				navigationUpdate(dt)
				if Eyes.canSeePlayer then
					Eyes.dir = VecNormalize(VecSub(Eyes.lastSeenPos, robot.transform.pos))
					state.headAngle = 0
					state.headAngleTimer = 0
				else
					state.headAngleTimer = state.headAngleTimer + dt
					if state.headAngleTimer > 1.0 then
						if state.headAngle > 0.0 then
							state.headAngle = rnd(-1.0, -0.5)
						elseif state.headAngle < 0 then
							state.headAngle = rnd(0.5, 1.0)
						else
							state.headAngle = rnd(-1.0, 1.0)
						end
						state.headAngleTimer = 0
					end
					Eyes.dir = QuatRotateVec(QuatEuler(0, state.headAngle, 0), robot.dir)
				end

				if navigation.state ~= "move" and Eyes.timeSinceLastSeen > 2 and state.activeTime > 3.0 then
					stackClear()
				end
			end

			--Get up player
			if state.id == "getup" then
				if not state.time then
					state.time = 0
				end
				state.time = state.time + dt
				hover.timeSinceContact = 0
				if state.time > 1.0 then
					stackPop()
				else
					hoverGetUp()
				end
			end

			if state.id == "navigate" then
				--! disable navigation
				-- if not state.initialized then
				-- 	if not state.timeout then state.timeout = 30 end
				-- 	navigationClear()
				-- 	navigationSetTarget(state.pos, state.timeout)
				-- 	state.initialized = true
				-- else
				-- 	head.dir = VecCopy(robot.dir)
				-- 	navigationUpdate(dt)
				-- 	if navigation.state == "done" or navigation.state == "fail" then
						stackPop()
				-- 	end
				-- end
			end

			--React to sound
			if not stackHas("hunt") then
				if hearing.hasNewSound and hearing.timeSinceLastSound < 1.0 then
					stackClear()
					PlaySound(alertSound, robot.bodyCenter)
					local s = stackPush("investigate")
					s.pos = hearing.lastSoundPos
					hearingConsumeSound()
				end
			end

			--Seen player
			if config.huntPlayer and not stackHas("hunt") then
				if config.canSeePlayer and Eyes.canSeePlayer or robot.canSensePlayer then
					stackClear()
					PlaySound(huntSound, robot.bodyCenter)
					stackPush("hunt")
				end
			end

			--Seen player
			if config.avoidPlayer and not stackHas("avoid") then
				if config.canSeePlayer and Eyes.canSeePlayer or robot.distToPlayer < 2.0 then
					stackClear()
					stackPush("avoid")
				end
			end

			--Get up
			if hover.timeSinceContact > 3.0 and not stackHas("getup") then
				stackPush("getup")
			end

			if IsShapeBroken(GetLightShape(Eyes.eye)) then
				config.hasVision = false
				config.canSeePlayer = false
			end

			-- debugState()

			updateCustom(dt)
		end

		function tick(dt)
			if not robot.enabled then
				return
			end

			if HasTag(robot.body, "turnhostile") then
				RemoveTag(robot.body, "turnhostile")
				config.canHearPlayer = true
				config.canSeePlayer = true
				config.huntPlayer = true
				config.aggressive = true
				config.practice = false
			end

			--Outline
			local dist = VecDist(robot.bodyCenter, GetPlayerCameraTransform().pos)
			if dist < config.outline then
				local a = clamp((config.outline - dist) / 5.0, 0.0, 1.0)
				if canBeSeenByPlayer() then
					a = 0
				end
				robot.outlineAlpha = robot.outlineAlpha + clamp(a - robot.outlineAlpha, -0.1, 0.1)
				for i=1, #robot.allBodies do
					DrawBodyOutline(robot.allBodies[i], 1, 1, 1, robot.outlineAlpha*0.5)
				end
			end

			--Remove planks and wires after some time
			local tags = {"plank", "wire"}
			local removeTimeOut = 10
			for i=1, #robot.allShapes do
				local shape = robot.allShapes[i]
				local joints = GetShapeJoints(shape)
				for j=1, #joints do
					local joint = joints[j]
					for t=1, #tags do
						local tag = tags[t]
						if HasTag(joint, tag) then
							local t = tonumber(GetTagValue(joint, tag)) or 0
							t = t + dt
							if t > removeTimeOut then
								if GetJointType(joint) == "rope" then
									DetachJointFromShape(joint, shape)
								else
									Delete(joint)
								end
								break
							else
								SetTag(joint, tag, t)
							end
						end
					end
				end
			end

			tickCustom(dt)

		end

		function draw()
			drawCustom()
		end

	end

	--> Config
	do

		pType = GetStringParam("type", "")
		pSpeed = GetFloatParam("speed", 3.5)
		pTurnSpeed = GetFloatParam("turnspeed", pSpeed)

		config = {}
		config.hasVision = false
		config.viewDistance = 25
		config.viewFov = 150
		config.canHearPlayer = false
		config.canSeePlayer = false
		config.patrol = false
		config.sensorDist = 5.0
		config.speed = pSpeed
		config.turnSpeed = pTurnSpeed
		config.huntPlayer = false
		config.huntSpeedScale = 1.6
		config.avoidPlayer = false
		config.triggerAlarmWhenSeen = false
		config.visibilityTimer = 0.3 --Time player must be seen to be identified as enemy (ideal condition)
		config.lostVisibilityTimer = 5.0 --Time player is seen after losing visibility
		config.outline = 13
		config.aimTime = 5.0
		config.maxSoundDist = 100.0
		config.aggressive = false
		config.stepSound = "m"
		config.practice = false

		PATH_NODE_TOLERANCE = 0.8

		function configInit()
			local eye = FindLight("eye")
			local head = FindBody("head")
			config.patrol = FindLocation("patrol") ~= 0
			config.hasVision = eye ~= 0
			config.viewDistance = getTagParameter(eye, "viewdist", config.viewDistance)
			config.viewFov = getTagParameter(eye, "viewfov", config.viewFov)
			config.maxSoundDist = getTagParameter(head, "heardist", config.maxSoundDist)
			if hasWord(pType, "investigate") then
				config.canHearPlayer = true
				config.canSeePlayer = true
			end
			if hasWord(pType, "chase") then
				config.canHearPlayer = true
				config.canSeePlayer = true
				config.huntPlayer = true
			end
			if hasWord(pType, "avoid") and config.patrol then
				config.avoidPlayer = true
				config.canSeePlayer = true
			end
			if hasWord(pType, "alarm") then
				config.triggerAlarmWhenSeen = true
			end
			if hasWord(pType, "nooutline") then
				config.outline = 0
			end
			if hasWord(pType, "aggressive") then
				config.aggressive = true
			end
			-- if hasWord(pType, "practice") then
			-- 	config.canSeePlayer = true
			-- 	config.practice = true
			-- end
			local body = FindBody("body")
			if HasTag(body, "stepsound") then
				config.stepSound = GetTagValue(body, "stepsound")
			end
		end

	end

	--> Navigation
	do

		navigation = {}
		navigation.state = "done"
		navigation.path = {}
		navigation.target = Vec()
		navigation.hasNewTarget = false
		navigation.resultRetrieved = true
		navigation.deviation = 0		-- Distance to path
		navigation.blocked = 0
		navigation.unblockTimer = 0		-- Timer that ticks up when blocked. If reaching limit, unblock kicks in and timer resets
		navigation.unblock = 0			-- If more than zero, navigation is in unblock mode (reverse direction)
		navigation.vertical = 0
		navigation.thinkTime = 0
		navigation.timeout = 1
		navigation.lastQueryTime = 0
		navigation.timeSinceProgress = 0

		function navigationInit()
			if #wheels.bodies > 0 then
				navigation.pathType = "low"
			else
				navigation.pathType = "standard"
			end
		end

		--Prune path backwards so robot don't need to go backwards
		function navigationPrunePath()
			if #navigation.path > 0 then
				for i=#navigation.path, 1, -1 do
					local p = navigation.path[i]
					local dv = VecSub(p, robot.transform.pos)
					local d = VecLength(dv)
					if d < PATH_NODE_TOLERANCE then
						--Keep everything after this node and throw out the rest
						local newPath = {}
						for j=i, #navigation.path do
							newPath[#newPath+1] = navigation.path[j]
						end
						navigation.path = newPath
						return
					end
				end
			end
		end

		function navigationClear()
			AbortPath()
			navigation.state = "done"
			navigation.path = {}
			navigation.hasNewTarget = false
			navigation.resultRetrieved = true
			navigation.deviation = 0
			navigation.blocked = 0
			navigation.unblock = 0
			navigation.vertical = 0
			navigation.target = Vec(0, -100, 0)
			navigation.thinkTime = 0
			navigation.lastQueryTime = 0
			navigation.unblockTimer = 0
			navigation.timeSinceProgress = 0
		end

		function navigationSetTarget(pos, timeout)
			pos = truncateToGround(pos)
			if VecDist(navigation.target, pos) > 0 then
				navigation.target = VecCopy(pos)
				navigation.hasNewTarget = true
				navigation.state = "move"
			end
			navigation.timeout = timeout
			navigation.timeSinceProgress = 0
		end

		function navigationUpdate(dt)
			if GetPathState() == "busy" then
				navigation.timeSinceProgress = 0
				navigation.thinkTime = navigation.thinkTime + dt
				if navigation.thinkTime > navigation.timeout then
					AbortPath()
				end
			end

			if GetPathState() ~= "busy" then
				if GetPathState() == "done" or GetPathState() == "fail" then
					if not navigation.resultRetrieved then
						if GetPathLength() > 0.5 then
							for l=0.2, GetPathLength(), 0.2 do
								navigation.path[#navigation.path+1] = GetPathPoint(l)
							end
						end
						navigation.lastQueryTime = navigation.thinkTime
						navigation.resultRetrieved = true
						navigation.state = "move"
						navigationPrunePath()
					end
				end
				navigation.thinkTime = 0
			end

			if navigation.thinkTime == 0 and navigation.hasNewTarget then
				local startPos

				if #navigation.path > 0 and VecDist(navigation.path[1], robot.navigationCenter) < 2.0 then
					--Keep a little bit of the old path and use last point of that as start position
					--Use previous query's time as an estimate for the next
					local distToKeep = VecLength(GetBodyVelocity(robot.body))*navigation.lastQueryTime
					local nodesToKeep = math.clamp(math.ceil(distToKeep / 0.2), 1, 15)
					local newPath = {}
					for i=1, math.min(nodesToKeep, #navigation.path) do
						newPath[i] = navigation.path[i]
					end
					navigation.path = newPath
					startPos = navigation.path[#navigation.path]
				else
					startPos = truncateToGround(robot.transform.pos)
					navigation.path = {}
				end

				local targetRadius = 1.0
				if GetPlayerVehicle()~=0 then
					targetRadius = 4.0
				end

				local target = navigation.target
				-- if robot.limitTrigger ~= 0 then
				-- 	target = GetTriggerClosestPoint(robot.limitTrigger, target)
					target = truncateToGround(target)
				-- end

				QueryRequire("physical large")
				rejectAllBodies(robot.allBodies)
				QueryPath(startPos, target, 100, targetRadius, navigation.pathType)

				navigation.timeSinceProgress = 0
				navigation.hasNewTarget = false
				navigation.resultRetrieved = false
				navigation.state = "move"
			end

			navigationMove(dt)

			if GetPathState() ~= "busy" and #navigation.path == 0 and not navigation.hasNewTarget then
				if GetPathState() == "done" or GetPathState() == "idle" then
					navigation.state = "done"
				else
					navigation.state = "fail"
				end
			end
		end

		function navigationMove(dt)
			if #navigation.path > 0 then
				if navigation.resultRetrieved then
					--If we have a finished path and didn't progress along it for five seconds, recompute
					--Should probably only do this for a limited time until giving up
					navigation.timeSinceProgress = navigation.timeSinceProgress + dt
					if navigation.timeSinceProgress > 5.0 then
						navigation.hasNewTarget = true
						navigation.path = {}
					end
				end
				if navigation.unblock > 0 then
					robot.speed = -2
					navigation.unblock = navigation.unblock - dt
				else
					local target = navigation.path[1]
					local dv = VecSub(target, robot.navigationCenter)
					local distToFirstPathPoint = VecLength(dv)
					dv[2] = 0
					local d = VecLength(dv)
					if distToFirstPathPoint < 2.5 then
						if d < PATH_NODE_TOLERANCE then
							if #navigation.path > 1 then
								--Measure verticality which should decrease speed
								local diff = VecSub(navigation.path[2], navigation.path[1])
								navigation.vertical = diff[2] / (VecLength(diff)+0.001)
								--Remove the first one
								local newPath = {}
								for i=2, #navigation.path do
									newPath[#newPath+1] = navigation.path[i]
								end
								navigation.path = newPath
								navigation.timeSinceProgress = 0
							else
								--We're done
								navigation.path = {}
								robot.speed = 0
								return
							end
						else
							--Walk towards first point on path
							robot.dir = VecCopy(VecNormalize(VecSub(target, robot.transform.pos)))

							local dirDiff = VecDot(VecScale(robot.axes[3], -1), robot.dir)
							local speedScale = math.max(0.25, dirDiff)
							speedScale = speedScale * clamp(1.0 - navigation.vertical, 0.3, 1.0)
							robot.speed = config.speed * speedScale

						end
					else
						--Went off path, scrap everything and recompute
						navigation.hasNewTarget = true
						navigation.path = {}
					end

					--Check if stuck
					-- if robot.blocked > 0.2 then
					-- 	navigation.blocked = navigation.blocked + dt
					-- 	if navigation.blocked > 0.2 then
					-- 		robot.breakAllTimer = 0.1
					-- 		navigation.blocked = 0.0
					-- 	end
					-- 	navigation.unblockTimer = navigation.unblockTimer + dt
					-- 	if navigation.unblockTimer > 2.0 and navigation.unblock <= 0.0 then
					-- 		navigation.unblock = 1.0
					-- 		navigation.unblockTimer = 0
					-- 	end
					-- else
					-- 	navigation.blocked = 0
					-- 	navigation.unblockTimer = 0
					-- end
				end
			end
		end

	end

end



--= ROBOT
do
	--> Robot
	do

		robot = {}
		robot.body = 0
		robot.transform = Transform()
		robot.axes = {}
		robot.bodyCenter = Vec()
		robot.navigationCenter = Vec()
		robot.dir = Vec(0, 0, -1)
		robot.speed = 0
		robot.blocked = 0
		robot.mass = 0
		robot.allBodies = {}
		robot.allShapes = {}
		robot.allJoints = {}
		robot.initialBodyTransforms = {}
		robot.enabled = true
		robot.deleted = false
		robot.speedScale = 1
		robot.breakAll = false
		robot.breakAllTimer = 0
		robot.distToPlayer = 100
		robot.dirToPlayer = 0
		robot.roamTrigger = 0
		robot.limitTrigger = 0
		robot.investigateTrigger = 0
		robot.activateTrigger = 0
		robot.stunned = 0
		robot.outlineAlpha = 0
		robot.canSensePlayer = false
		robot.playerPos = Vec()


		function robotSetAxes()
			robot.transform = GetBodyTransform(robot.body)
			robot.axes[1] = TransformToParentVec(robot.transform, Vec(1, 0, 0))
			robot.axes[2] = TransformToParentVec(robot.transform, Vec(0, 1, 0))
			robot.axes[3] = TransformToParentVec(robot.transform, Vec(0, 0, 1))
		end


		function robotInit()
			robot.body = FindBody("body")
			robot.allBodies = FindBodies()
			robot.allShapes = FindShapes()
			robot.allJoints = FindJoints()
			robot.roamTrigger = FindTrigger("roam")
			robot.limitTrigger = FindTrigger("limit")
			robot.investigateTrigger = FindTrigger("investigate")
			robot.activateTrigger = FindTrigger("activate")
			if robot.activateTrigger ~= 0 then
				SetTag(robot.body, "inactive")
			end
			for i=1, #robot.allBodies do
				robot.initialBodyTransforms[i] = GetBodyTransform(robot.allBodies[i])
			end
			robotSetAxes()
		end


		function robotTurnTowards(pos)
			robot.dir = VecNormalize(VecSub(pos, robot.transform.pos))
		end


		function robotSetDirAngle(angle)
			robot.dir[1] = math.cos(angle)
			robot.dir[3] = math.sin(angle)
		end


		function robotGetDirAngle()
			return math.atan2(robot.dir[3], robot.dir[1])
		end


		function robotUpdate(dt)
			robotSetAxes()

			-- if config.practice then
			-- 	local overrideTarget = FindBody("practicetarget", true)
			-- 	if overrideTarget ~= 0 then
			-- 		robot.playerPos = GetBodyTransform(overrideTarget).pos
			-- 		if not stackHas("navigate") then
			-- 			robotTurnTowards(robot.playerPos)
			-- 		end
			-- 	else
			-- 		robot.playerPos = Vec(0, -100, 0)
			-- 	end
			-- else
				robot.playerPos = getOuterCrosshairWorldPos()
			-- end

			-- local vel = GetBodyVelocity(robot.body)
			-- local fwdSpeed = VecDot(vel, robot.dir)
			-- local blocked = 0
			-- if robot.speed > 0 and fwdSpeed > -0.1 then
			-- 	blocked = 1.0 - clamp(fwdSpeed/0.5, 0.0, 1.0)
			-- end
			-- robot.blocked = robot.blocked * 0.95 + blocked * 0.05

			--Always blocked if fall is detected
			-- if sensor.detectFall > 0 then
			-- 	robot.blocked = 1.0
			-- end

			--Evaluate mass every frame since robots can break
			robot.mass = 0
			local bodies = FindBodies()
			for i=1, #bodies do
				robot.mass = robot.mass + GetBodyMass(bodies[i])
			end

			robot.bodyCenter = TransformToParentPoint(robot.transform, GetBodyCenterOfMass(robot.body))
			robot.navigationCenter = TransformToParentPoint(robot.transform, Vec(0, -hover.distTarget, 0))

			--Handle break all
			robot.breakAllTimer = math.max(0.0, robot.breakAllTimer - dt)
			if not robot.breakAll and robot.breakAllTimer > 0.0 then
				for i=1, #robot.allShapes do
					SetTag(robot.allShapes[i], "breakall")
				end
				robot.breakAll = true
			end
			if robot.breakAll and robot.breakAllTimer <= 0.0 then
				for i=1, #robot.allShapes do
					RemoveTag(robot.allShapes[i], "breakall")
				end
				robot.breakAll = false
			end

			--Distance and direction to player
			local pp = VecAdd(GetPlayerTransform().pos, Vec(0, 1, 0))
			local d = VecSub(pp, robot.bodyCenter)
			robot.distToPlayer = VecLength(d)
			robot.dirToPlayer = VecScale(d, 1.0/robot.distToPlayer)


			--Sense player if player is close and there is nothing in between
			robot.canSensePlayer = false
			if robot.distToPlayer < 3.0 then
				rejectAllBodies(robot.allBodies)
				if not QueryRaycast(robot.bodyCenter, robot.dirToPlayer, robot.distToPlayer) then
					robot.canSensePlayer = true
				end
			end

			--Robot body sounds
			if robot.enabled and hover.contact > 0 then
				local vol
				vol = clamp(VecLength(GetBodyVelocity(robot.body)) * 0.4, 0.0, 1.0)
				if vol > 0 then
					PlayLoop(walkLoop, robot.transform.pos, vol)
				end

				vol = clamp(VecLength(GetBodyAngularVelocity(robot.body)) * 0.4, 0.0, 1.0)
				if vol > 0 then
					PlayLoop(turnLoop, robot.transform.pos, vol)
				end
			end
		end

	end

	--> Head
	do

		Eyes = {}
		Eyes.body = 0
		Eyes.eye = 0
		Eyes.dir = Vec(0,0,-1)
		Eyes.lookOffset = 0
		Eyes.lookOffsetTimer = 0
		Eyes.canSeePlayer = false
		Eyes.lastSeenPos = Vec(0,0,0)
		Eyes.timeSinceLastSeen = 999
		Eyes.seenTimer = 0
		Eyes.alarmTimer = 0
		Eyes.alarmTime = 2.0
		Eyes.aim = 0	-- 1.0 = perfect aim, 0.0 = will always miss player. This increases when robot sees player based on config.aimTime

		function headInit()
			Eyes.body = FindBody("head")
			Eyes.eye = FindLight("eye")
			Eyes.joint = FindJoint("head")
			Eyes.alarmTime = getTagParameter(Eyes.eye, "alarm", 2.0)
		end

		function headTurnTowards(pos)
			Eyes.dir = VecNormalize(VecSub(pos, GetBodyTransform(Eyes.body).pos))
		end

		function headUpdate(dt)
			local t = GetBodyTransform(Eyes.body)
			local fwd = TransformToParentVec(t, Vec(0, 0, -1))

			--Check if head can see player
			local et = GetLightTransform(Eyes.eye)
			local pp = VecCopy(robot.playerPos)
			local toPlayer = VecSub(pp, et.pos)
			local distToPlayer = VecLength(toPlayer)
			toPlayer = VecNormalize(toPlayer)

			--Determine player visibility
			local playerVisible = false
			if config.hasVision and config.canSeePlayer then
				if distToPlayer < config.viewDistance then	--Within view distance
					local limit = math.cos(config.viewFov * 0.5 * math.pi / 180)
					if VecDot(toPlayer, fwd) > limit then --In view frustum
						rejectAllBodies(robot.allBodies)
						QueryRejectVehicle(GetPlayerVehicle())
						if not QueryRaycast(et.pos, toPlayer, distToPlayer, 0, true) then --Not blocked
							playerVisible = true
						end
					end
				end
			end

			if config.aggressive then
				playerVisible = true
			end

			--If player is visible it takes some time before registered as seen
			--If player goes out of sight, head can still see for some time second (approximation of motion estimation)
			if playerVisible then
				local distanceScale = clamp(1.0 - distToPlayer/config.viewDistance, 0.5, 1.0)
				local angleScale = clamp(VecDot(toPlayer, fwd), 0.5, 1.0)
				local delta = (dt * distanceScale * angleScale) / (config.visibilityTimer / 0.5)
				Eyes.seenTimer = math.min(1.0, Eyes.seenTimer + delta)
			else
				Eyes.seenTimer = math.max(0.0, Eyes.seenTimer - dt / config.lostVisibilityTimer)
			end
			Eyes.canSeePlayer = (Eyes.seenTimer > 0.5)

			if Eyes.canSeePlayer then
				Eyes.lastSeenPos = pp
				Eyes.timeSinceLastSeen = 0
			else
				Eyes.timeSinceLastSeen = Eyes.timeSinceLastSeen + dt
			end

			if playerVisible and Eyes.canSeePlayer then
				Eyes.aim = math.min(1.0, Eyes.aim + dt / config.aimTime)
			else
				Eyes.aim = math.max(0.0, Eyes.aim - dt / config.aimTime)
			end

			if config.triggerAlarmWhenSeen then
				local red = false
				if GetBool("level.alarm") then
					red = math.mod(GetTime(), 0.5) > 0.25
				else
					if playerVisible and IsPointAffectedByLight(Eyes.eye, pp) then
						red = true
						Eyes.alarmTimer = Eyes.alarmTimer + dt
						PlayLoop(chargeLoop, robot.transform.pos)
						if Eyes.alarmTimer > Eyes.alarmTime and playerVisible then
							SetBool("level.alarm", true)
						end
					else
						Eyes.alarmTimer = math.max(0.0, Eyes.alarmTimer - dt)
					end
				end
				if red then
					SetLightColor(Eyes.eye, 1, 0, 0)
				else
					SetLightColor(Eyes.eye, 1, 1, 1)
				end
			end

			--Rotate head to head.dir
			local fwd = TransformToParentVec(t, Vec(0, 0, -1))
			if playerVisible then
				headTurnTowards(pp)
			end
			Eyes.dir = VecNormalize(Eyes.dir)
			--end
			local c = VecCross(fwd, Eyes.dir)
			local d = VecDot(c, robot.axes[2])
			local angVel = clamp(d*10, -3, 3)
			local f = 100
			mi, ma = GetJointLimits(Eyes.joint)
			local ang = GetJointMovement(Eyes.joint)
			if ang < mi+1 and angVel < 0 then
				angVel = 0
			end
			if ang > ma-1 and angVel > 0 then
				angVel = 0
			end

			ConstrainAngularVelocity(Eyes.body, robot.body, robot.axes[2], angVel, -f , f)

			local vol = clamp(math.abs(angVel)*0.3, 0.0, 1.0)
			if vol > 0 then
				PlayLoop(headLoop, robot.transform.pos, vol)
			end
		end

	end

	--> Feet
	do
		feet = {}

		function feetInit()
			local f = FindBodies("foot")
			for i=1, #f do
				local foot = {}
				foot.body = f[i]
				local t = GetBodyTransform(foot.body)
				local rayOrigin = TransformToParentPoint(t, Vec(0, 0.9, 0))
				local rayDir = TransformToParentVec(t, Vec(0, -1, 0))

				foot.lastTransform = TransformCopy(t)
				foot.targetTransform = TransformCopy(t)
				foot.candidateTransform = TransformCopy(t)
				foot.worldTransform = TransformCopy(t)
				foot.stepAge = 1
				foot.stepLifeTime = 1
				foot.localRestTransform = TransformToLocalTransform(robot.transform, t)
				foot.localTransform = TransformCopy(foot.localRestTransform)
				foot.rayOrigin = TransformToLocalPoint(robot.transform, rayOrigin)
				foot.rayDir = TransformToLocalVec(robot.transform, rayDir)
				foot.rayDist = hover.distTarget + hover.distPadding
				foot.contact = true
				local mass = GetBodyMass(foot.body)
				foot.linForce = 20 * mass
				foot.angForce = 1 * mass
				local linScale, angScale = getTagParameter2(foot.body, "force", 1.0)
				foot.linForce = foot.linForce * linScale
				foot.angForce = foot.angForce * angScale
				feet[i] = foot
			end
		end


		function feetCollideLegs(enabled)
			local mask = 0
			if enabled then
				mask = 253
			end
			local feet = FindBodies("foot")
			for i=1, #feet do
				local shapes = GetBodyShapes(feet[i])
				for j=1, #shapes do
					SetShapeCollisionFilter(shapes[j], 2, mask)
				end
			end
			local legs = FindBodies("leg")
			for i=1, #legs do
				local shapes = GetBodyShapes(legs[i])
				for j=1, #shapes do
					SetShapeCollisionFilter(shapes[j], 2, mask)
				end
			end
			for i=1, #wheels.bodies do
				local shapes = GetBodyShapes(wheels.bodies[i])
				for j=1, #shapes do
					SetShapeCollisionFilter(shapes[j], 2, mask)
				end
			end
		end


		function feetUpdate(dt)
			if robot.stunned > 0 then
				feetCollideLegs(true)
				return
			else
				feetCollideLegs(false)
			end

			local vel = GetBodyVelocity(robot.body)
			local velLength = VecLength(vel)
			local stepLength = clamp(velLength*1.5, 0.5, 1)
			local stepTime = math.min(stepLength / velLength * 0.5, 0.25)
			local stepHeight = stepLength * 0.5

			local inStep = false
			for i=1, #feet do

				local q = feet[i].stepAge/feet[i].stepLifeTime
				if feet[i].stepLifeTime > stepTime then
					feet[i].stepLifeTime = stepTime
				end
				if q < 0.8 then
					inStep = true
				end
			end

			for i=1, #feet do
				local foot = feet[i]

				if not inStep then
					--Find candidate footstep
					local tPredict = TransformCopy(robot.transform)
					tPredict.pos = VecAdd(tPredict.pos, VecScale(VecLerp(VecScale(robot.dir, robot.speed), vel, 0.5), stepTime*1.5))
					local rayOrigin = TransformToParentPoint(tPredict, foot.rayOrigin)
					local rayDir = TransformToParentVec(tPredict, foot.rayDir)
					QueryRequire("physical large")
					rejectAllBodies(robot.allBodies)
					local hit, dist, normal, shape = QueryRaycast(rayOrigin, rayDir, foot.rayDist)
					local targetTransform = TransformToParentTransform(robot.transform, foot.localRestTransform)
					if hit then
						targetTransform.pos = VecAdd(rayOrigin, VecScale(rayDir, dist))
					end
					foot.candidateTransform = targetTransform
				end

				--Animate foot
				if hover.contact > 0 then
					if foot.stepAge < foot.stepLifeTime then
						foot.stepAge = math.min(foot.stepAge + dt, foot.stepLifeTime)
						local q = foot.stepAge / foot.stepLifeTime
						q = q * q * (3.0 - 2.0 * q) -- smoothstep
						local p = VecLerp(foot.lastTransform.pos, foot.targetTransform.pos, q)
						p[2] = p[2] + math.sin(math.pi * q)*stepHeight
						local r = QuatSlerp(foot.lastTransform.rot, foot.targetTransform.rot, q)
						foot.worldTransform = Transform(p, r)
						foot.localTransform = TransformToLocalTransform(robot.transform, foot.worldTransform)
						if foot.stepAge == foot.stepLifeTime then
							PlaySound(stepSound, p, 0.5)
						end
					end
					ConstrainPosition(foot.body, robot.body, GetBodyTransform(foot.body).pos, foot.worldTransform.pos, 8, foot.linForce)
					ConstrainOrientation(foot.body, robot.body, GetBodyTransform(foot.body).rot, foot.worldTransform.rot, 16, foot.angForce)
				end

			end

			if not inStep then
				--Find best step candidate
				local bestFoot = 0
				local bestDist = 0
				for i=1, #feet do
					local foot = feet[i]
					local dist = VecLength(VecSub(foot.targetTransform.pos, foot.candidateTransform.pos))
					if dist > stepLength and dist > bestDist then
						bestDist = dist
						bestFoot = i
					end
				end
				--Initiate best footstep
				if bestFoot ~= 0 then
					local foot = feet[bestFoot]
					foot.lastTransform = TransformCopy(GetBodyTransform(foot.body))
					foot.targetTransform = TransformCopy(foot.candidateTransform)
					foot.stepAge = 0
					foot.stepLifeTime = stepTime
				end
			end
		end
	end

	--> Hover
	do

		hover = {}
		hover.hitBody = 0
		hover.contact = 0.0
		hover.distTarget = 0.3
		hover.distPadding = 0.3
		hover.timeSinceContact = 0.0


		function hoverInit()
			local bodyPos = robot.transform.pos
			local footMin, footMax = GetBodyBounds(FindBodies('foot')[1])
			local dist = bodyPos[2] - footMin[2]

			-- local maxDist = 2.0
			-- local hit, dist = QueryRaycast(robot.transform.pos, VecScale(robot.axes[2], -1), maxDist)
			-- if hit then
				hover.distTarget = dist
				hover.distPadding = math.min(0.3, dist*0.5)
			-- end
		end


		function hoverFloat()
			if hover.contact > 0 then
				local d = clamp(hover.distTarget - hover.currentDist, -0.2, 0.2)
				local v = d * 10
				local f = hover.contact * math.max(0, d*robot.mass*5.0) + robot.mass*0.2
				ConstrainVelocity(robot.body, hover.hitBody, robot.bodyCenter, Vec(0,1,0), v, 0 , f)
			end
		end


		UPRIGHT_STRENGTH = 1.0	-- Spring strength
		UPRIGHT_MAX = 0.5		-- Max spring force
		UPRIGHT_BASE = 0.1		-- Fraction of max spring force to always apply (less springy)
		function hoverUpright()
			local up = VecCross(robot.axes[2], VecAdd(Vec(0,1,0)))
			axes = {}
			axes[1] = Vec(1,0,0)
			axes[2] = Vec(0,1,0)
			axes[3] = Vec(0,0,1)
			for a = 1, 3, 2 do
				local d = VecDot(up, axes[a])
				local v = math.clamp(d * 15, -2, 2)
				local f = math.clamp(math.abs(d)*UPRIGHT_STRENGTH, -UPRIGHT_MAX, UPRIGHT_MAX)
				f = f + UPRIGHT_MAX * UPRIGHT_BASE
				f = f * robot.mass
				f = f * hover.contact
				--f = 10000
				ConstrainAngularVelocity(robot.body, hover.hitBody, axes[a], v, -f , f)
			end
		end


		function hoverGetUp()
			local up = VecCross(robot.axes[2], VecAdd(Vec(0,1,0)))
			axes = {}
			axes[1] = Vec(1,0,0)
			axes[2] = Vec(0,1,0)
			axes[3] = Vec(0,0,1)
			for a = 1, 3, 2 do
				local d = VecDot(up, axes[a])
				local v = math.clamp(d * 15, -2, 2)
				local f = math.clamp(math.abs(d)*UPRIGHT_STRENGTH, -UPRIGHT_MAX, UPRIGHT_MAX)
				f = f + UPRIGHT_MAX * UPRIGHT_BASE
				f = f * robot.mass
				ConstrainAngularVelocity(robot.body, hover.hitBody, axes[a], v, -f , f)
			end
		end


		function hoverTurn()
			local fwd = VecScale(robot.axes[3], -1)
			local c = VecCross(fwd, robot.dir)
			local d = VecDot(c, robot.axes[2])
			local angVel = clamp(d*10, -config.turnSpeed * robot.speedScale, config.turnSpeed * robot.speedScale)

			local curr = VecDot(robot.axes[2], GetBodyAngularVelocity(robot.body))
			angVel = curr + clamp(angVel - curr, -0.2*robot.speedScale, 0.2*robot.speedScale)

			-- local f = robot.mass*0.5 * hover.contact
			local f = robot.mass*0.5 * hover.contact
			ConstrainAngularVelocity(robot.body, hover.hitBody, robot.axes[2], angVel, -f , f)
		end


		function hoverMove()
			local desiredSpeed = robot.speed * robot.speedScale
			local fwd = VecScale(robot.axes[3], -1)
			fwd[2] = 0
			fwd = VecNormalize(fwd)
			local side = VecCross(Vec(0,1,0), fwd)
			local currSpeed = VecDot(fwd, GetBodyVelocityAtPos(robot.body, robot.bodyCenter))
			local speed = currSpeed + clamp(desiredSpeed - currSpeed/2, -0.05*robot.speedScale, 0.05*robot.speedScale)
			local f = robot.mass*0.2 * hover.contact

			ConstrainVelocity(robot.body, hover.hitBody, robot.bodyCenter, fwd, speed, -f , f)
			ConstrainVelocity(robot.body, hover.hitBody, robot.bodyCenter, robot.axes[1], 0, -f , f)
		end


		BALANCE_RADIUS = 0.4
		function hoverUpdate(dt)
			local dir = VecScale(robot.axes[2], -1)

			--Shoot rays from four locations downwards
			local hit = false
			local dist = 0
			local normal = Vec(0,0,0)
			local shape = 0
			local samples = {}
			samples[#samples+1] = Vec(-BALANCE_RADIUS,0,0)
			samples[#samples+1] = Vec(BALANCE_RADIUS,0,0)
			samples[#samples+1] = Vec(0,0,BALANCE_RADIUS)
			samples[#samples+1] = Vec(0,0,-BALANCE_RADIUS)
			local castRadius = 0.1
			local maxDist = hover.distTarget + hover.distPadding
			for i=1, #samples do
				QueryRequire("physical large")
				rejectAllBodies(robot.allBodies)
				local origin = TransformToParentPoint(robot.transform, samples[i])
				local rhit, rdist, rnormal, rshape = QueryRaycast(origin, dir, maxDist, castRadius)
				if rhit then
					hit = true
					dist = dist + rdist + castRadius
					if rdist == 0 then
						--Raycast origin in geometry, normal unsafe. Assume upright
						rnormal = Vec(0,1,0)
					end
					if shape == 0 then
						shape = rshape
					else
						local b = GetShapeBody(rshape)
						local bb = GetShapeBody(shape)
						--Prefer new hit if it's static or has more mass than old one
						if not IsBodyDynamic(b) or (IsBodyDynamic(bb) and GetBodyMass(b) > GetBodyMass(bb)) then
							shape = rshape
						end
					end
					normal = VecAdd(normal, rnormal)
				else
					dist = dist + maxDist
				end
			end

			--Use average of rays to determine contact and height
			if hit then
				dist = dist / #samples
				normal = VecNormalize(normal)
				hover.hitBody = GetShapeBody(shape)
				if IsBodyDynamic(hover.hitBody) and GetBodyMass(hover.hitBody) < 300 then
					--Hack alert! Treat small bodies as static to avoid sliding and glitching around on debris
					hover.hitBody = 0
				end
				hover.currentDist = dist
				hover.contact = clamp(1.0 - (dist - hover.distTarget) / hover.distPadding, 0.0, 1.0)
				hover.contact = hover.contact * math.max(0, normal[2])
			else
				hover.hitBody = 0
				hover.currentDist = maxDist
				hover.contact = 0
			end

			--Limit body angular velocity magnitude to 10 rad/s at max contact
			if hover.contact > 0 then
				local maxAngVel = 10.0 / hover.contact
				local angVel = GetBodyAngularVelocity(robot.body)
				local angVelLength = VecLength(angVel)
				if angVelLength > maxAngVel then
					SetBodyAngularVelocity(robot.body, VecScale(maxAngVel / angVelLength))
				end
			end

			if hover.contact > 0 then
				hover.timeSinceContact = 0
			else
				hover.timeSinceContact = hover.timeSinceContact + dt
			end

			hoverFloat()
			hoverUpright()
			hoverTurn()
			hoverMove()
		end

	end

	--> Wheels
	do

		wheels = {}
		wheels.bodies = {}
		wheels.transforms = {}
		wheels.radius = {}

		function wheelsInit()
			wheels.bodies = FindBodies("wheel")
			for i=1, #wheels.bodies do
				local t = GetBodyTransform(wheels.bodies[i])
				local shape = GetBodyShapes(wheels.bodies[i])[1]
				local sx, sy, sz = GetShapeSize(shape)
				wheels.transforms[i] = TransformToLocalTransform(robot.transform, t)
				wheels.radius[i] = math.max(sx, sz)*0.05
			end
		end

		function wheelsUpdate(dt)
			for i=1, #wheels.bodies do
				local v = GetBodyVelocityAtPos(robot.body, TransformToParentPoint(robot.transform, wheels.transforms[i].pos))
				local lv = VecDot(robot.axes[3], v)
				if hover.contact > 0 then
					local shapes = GetBodyShapes(wheels.bodies[i])
					if #shapes > 0 then
						local joints = GetShapeJoints(shapes[1])
						if #joints > 0 then
							local angVel = lv / wheels.radius[i]
							SetJointMotor(joints[1], angVel, 100)
						end
					end
					PlayLoop(rollLoop, robot.transform.pos, clamp(math.abs(lv)*0.5, 0.0, 1.0))
				end
			end
		end

	end

	--> Weapons
	do

		weapons = {}

		function weaponsInit()
			local locs = FindLocations("weapon")
			for i=1, #locs do
				local loc = locs[i]
				local t = GetLocationTransform(loc)
				QueryRequire("dynamic large")
				local hit, point, normal, shape = QueryClosestPoint(t.pos, 0.15)
				if hit then
					local weapon = {}
					weapon.type = GetTagValue(loc, "weapon")
					weapon.timeBetweenRounds = tonumber(GetTagValue(loc, "idle"))
					weapon.chargeTime = tonumber(GetTagValue(loc, "charge"))
					weapon.fireCooldown = tonumber(GetTagValue(loc, "cooldown"))
					weapon.shotsPerRound = tonumber(GetTagValue(loc, "count"))
					weapon.spread = tonumber(GetTagValue(loc, "spread"))
					weapon.strength = tonumber(GetTagValue(loc, "strength"))
					weapon.maxDist = tonumber(GetTagValue(loc, "maxdist"))
					if weapon.type == "" then weapon.type = "gun" end
					if not weapon.timeBetweenRounds then weapon.timeBetweenRounds = 1 end
					if not weapon.chargeTime then weapon.chargeTime = 1.2 end
					if not weapon.fireCooldown then weapon.fireCooldown = 0.15 end
					if not weapon.shotsPerRound then weapon.shotsPerRound = 8 end
					if not weapon.spread then weapon.spread = 0.01 end
					if not weapon.strength then weapon.strength = 1.0 end
					if not weapon.maxDist then weapon.maxDist = 100.0 end
					local b = GetShapeBody(shape)
					local bt = GetBodyTransform(b)
					weapon.localTransform = TransformToLocalTransform(bt, t)
					weapon.body = b
					weapon.state = "idle"
					weapon.idleTimer = 0
					weapon.chargeTimer = 0
					weapon.fireTimer = 0
					weapon.fireCount = 0
					weapons[i] = weapon
				end
			end
		end

		function getPerpendicular(dir)
			local perp = VecNormalize(Vec(rnd(-1, 1), rnd(-1, 1), rnd(-1, 1)))
			perp = VecNormalize(VecSub(perp, VecScale(dir, VecDot(dir, perp))))
			return perp
		end

		function weaponFire(weapon, pos, dir)
			local perp = getPerpendicular(dir)

			-- This is the default bullet spread
			local spread =  rnd(0.0, 1.0) / 9

			-- Add more spread up based on aim, so that the first bullets never (well, rarely) hit player
			local extraSpread = math.min(0.5, 2.0 / robot.distToPlayer)

			dir = VecNormalize(VecAdd(dir, VecScale(perp, spread)))

			--Start one voxel ahead to not hit robot itself
			pos = VecAdd(pos, VecScale(dir, 0.1))

			if weapon.type == "gun" then
				PlaySound(shootSound, pos)
				PointLight(pos, 1, 0.8, 0.6, 5)
				Shoot(pos, dir, 0, weapon.strength)
			elseif weapon.type == "rocket" then
				PlaySound(rocketSound, pos)
				Shoot(pos, dir, 1, weapon.strength)
			end
		end

		function weaponsReset()
			for i=1, #weapons do
				weapons[i].state = "idle"
				weapons[i].idleTimer = weapons[i].timeBetweenRounds
				weapons[i].fire = 0
			end
		end

		function weaponEmitFire(weapon, t, amount)
			local p = TransformToParentPoint(t, Vec(0, 0, -0.1))
			local d = TransformToParentVec(t, Vec(0, 0, -1))
			ParticleReset()
			ParticleTile(5)
			ParticleColor(1, 1, 0.5, 1, 0, 0)
			ParticleRadius(0.1*amount, 1*amount)
			ParticleEmissive(10, 0)
			ParticleDrag(0.1)
			ParticleGravity(math.random()*20)
			PointLight(p, 1, 0.8, 0.2, 2*amount)
			PlayLoop(fireLoop, t.pos, amount)
			SpawnParticle(p, VecScale(d, 12), 0.5 * amount)

			if amount > 0.5 then
				--Spawn fire
				if not spawnFireTimer then
					spawnFireTimer = 0
				end
				if spawnFireTimer > 0 then
					spawnFireTimer = math.max(spawnFireTimer-0.01667, 0)
				else
					rejectAllBodies(robot.allBodies)
					local hit, dist = QueryRaycast(p, d, 3)
					if hit then
						local wp = VecAdd(p, VecScale(d, dist))
						SpawnFire(wp)
						spawnFireTimer = 1
					end
				end

				--Hurt player
				local toPlayer = VecSub(GetPlayerCameraTransform().pos, t.pos)
				local distToPlayer = VecLength(toPlayer)
				local distScale = clamp(1.0 - distToPlayer / 5.0, 0.0, 1.0)
				if distScale > 0 then
					toPlayer = VecNormalize(toPlayer)
					if VecDot(d, toPlayer) > 0.8 or distToPlayer < 0.5 then
						rejectAllBodies(robot.allBodies)
						local hit = QueryRaycast(p, toPlayer, distToPlayer)
						if not hit or distToPlayer < 0.5 then
							SetPlayerHealth(GetPlayerHealth() - 0.015 * weapon.strength * amount * distScale)
						end
					end
				end
			end
		end

		function weaponsUpdate(dt)
			for i=1, #weapons do
				local weapon = weapons[i]
				local bt = GetBodyTransform(weapon.body)
				local t = TransformToParentTransform(bt, weapon.localTransform)
				local fwd = TransformToParentVec(t, Vec(0, 0, -2))
				t.pos = VecAdd(t.pos, VecScale(fwd, 0.2))
				local playerPos = VecCopy(robot.playerPos)
				local toPlayer = VecSub(playerPos, t.pos)
				local distToPlayer = VecLength(toPlayer)
				toPlayer = VecNormalize(toPlayer)
				local clearShot = false

				if weapon.type == "fire" then
					if not weapon.fire then
						weapon.fire = 0
						weaponStatus = "Idle"
					end
					if isShooting then
						weapon.fire = math.min(weapon.fire + 0.1, 1.0)
						weaponStatus = "Firing"
					else
						weapon.fire = math.max(weapon.fire - dt*0.5, 0.0)
					end
					if weapon.fire > 0 then
						weaponEmitFire(weapon, t, weapon.fire)
					else
						weaponEmitFire(weapon, t, math.max(weapon.fire, 0.1))
						weaponStatus = "Idle"
					end
				else
					--Need to point towards player and have clear line of sight to have clear shot
					local towardsPlayer = VecDot(fwd, toPlayer)
					local gotAim = towardsPlayer > 0.9
					-- if distToPlayer < 1.0 and towardsPlayer > 0.0 then
					if isShooting then
						gotAim = true
					end
					if isShooting then
						QueryRequire("physical large")
						rejectAllBodies(robot.allBodies)
						local hit = QueryRaycast(t.pos, fwd, distToPlayer, 0, true)
						if not hit then
							clearShot =  true
						end
					end

					--Handle states
					if weapon.state == "idle" then
						weaponStatus = "Idle"
						weapon.idleTimer = weapon.idleTimer - dt
						if weapon.idleTimer <= 0 and clearShot then
							weapon.state = "charge"
							weapon.fireDir = fwd
							weapon.chargeTimer = weapon.chargeTime
							weaponStatus = "Charging"
						end
					elseif weapon.state == "charge" or weapon.state == "chargesilent" then
						weapon.chargeTimer = weapon.chargeTimer - dt
						if weapon.state ~= "chargesilent" then
							PlayLoop(chargeLoop, t.pos)
						end
						if weapon.chargeTimer <= 0 then
							weapon.state = "fire"
							weapon.fireTimer = 0
							weapon.fireCount = weapon.shotsPerRound
						end
					elseif weapon.state == "fire" then
						weapon.fireTimer = weapon.fireTimer - dt
						if towardsPlayer > 0.3 or distToPlayer < 1.0 then
							if weapon.fireTimer <= 0 then

								weaponFire(weapon, t.pos, fwd)
								weaponStatus = "Firing"

								weapon.fireCount = weapon.fireCount - 1
								if weapon.fireCount <= 0 then
									if clearShot then
										weapon.state = "chargesilent"
										weapon.chargeTimer = weapon.chargeTime
									else
										weapon.state = "idle"
										weapon.idleTimer = weapon.timeBetweenRounds
									end
								else
									weapon.fireTimer = weapon.fireCooldown
								end
							end
						else
							--We are no longer pointing towards player, abort round
							weapon.state = "idle"
							weapon.idleTimer = weapon.timeBetweenRounds
						end
					end

				end
			end
		end

	end

	--> Aims
	do

		aims = {}
		aims_lights = {}

		function aimsInit()
			--! Added aims_lights
			local lights = FindLights('weap_secondary')
			local bodies = FindBodies("aim")
			for i=1, #bodies do
				local aim = {}
				aim.body = bodies[i]
				aims[i] = aim

				for key, light in pairs(lights) do
					local body = GetLightShape(light)
					if body == aim.body then
						aims_lights[i] = light
					end
				end

			end
		end

		function aimsUpdate(dt)
			for i=1, #aims do

				local aim = aims[i]
				local playerPos = getOuterCrosshairWorldPos()
				local toPlayer = VecNormalize(VecSub(playerPos, GetBodyTransform(aim.body).pos))
				local fwd = TransformToParentVec(GetBodyTransform(robot.body), Vec(0, 0, -1))

				if (Eyes.canSeePlayer and VecDot(fwd, toPlayer) > 0.5) or robot.distToPlayer < 4.0 then
					--Should aim
					local v = 2
					local f = 20
					local wt = GetBodyTransform(aim.body)
					local toPlayerOrientation = QuatLookAt(wt.pos, playerPos)
					ConstrainOrientation(aim.body, robot.body, wt.rot, toPlayerOrientation, v, f)
				else
					--Should not aim
					local rd = TransformToParentVec(GetBodyTransform(robot.body), Vec(0, 0, -1))
					local wd = TransformToParentVec(GetBodyTransform(aim.body), Vec(0, 0, -1))
					local angle = clamp(math.acos(VecDot(rd, wd)), 0, 1)
					local v = 2
					local f = math.abs(angle) * 10 + 3
					ConstrainOrientation(robot.body, aim.body, GetBodyTransform(robot.body).rot, GetBodyTransform(aim.body).rot, v, f)
				end

			end
		end

	end

	--> Sensor
	do
		sensor = {}
		sensor.blocked = 0
		sensor.blockedLeft = 0
		sensor.blockedRight = 0
		sensor.detectFall = 0

		function sensorInit()
		end

		function sensorGetBlocked(dir, maxDist)
			dir = VecNormalize(VecAdd(dir, rndVec(0.3)))
			local origin = TransformToParentPoint(robot.transform, Vec(0, 0.8, 0))
			QueryRequire("physical large")
			rejectAllBodies(robot.allBodies)
			local hit, dist = QueryRaycast(origin, dir, maxDist)
			return 1.0 - dist/maxDist
		end

		function sensorDetectFall()
			dir = Vec(0, -1, 0)
			local lookAheadDist = 0.6 + clamp(VecLength(GetBodyVelocity(robot.body))/6.0, 0.0, 0.6)
			local origin = TransformToParentPoint(robot.transform, Vec(0, 0.5, -lookAheadDist))
			QueryRequire("physical large")
			rejectAllBodies(robot.allBodies)
			local maxDist = hover.distTarget + 1.0
			local hit, dist = QueryRaycast(origin, dir, maxDist, 0.2)
			return not hit
		end

		function sensorUpdate(dt)
			local maxDist = config.sensorDist
			local blocked = sensorGetBlocked(TransformToParentVec(robot.transform, Vec(0, 0, -1)), maxDist)
			if sensorDetectFall() then
				sensor.detectFall = 1.0
			else
				sensor.detectFall = 0.0
			end
			sensor.blocked = sensor.blocked * 0.9 + blocked * 0.1

			local blockedLeft = sensorGetBlocked(TransformToParentVec(robot.transform, Vec(-0.5, 0, -1)), maxDist)
			sensor.blockedLeft = sensor.blockedLeft * 0.9 + blockedLeft * 0.1

			local blockedRight = sensorGetBlocked(TransformToParentVec(robot.transform, Vec(0.5, 0, -1)), maxDist)
			sensor.blockedRight = sensor.blockedRight * 0.9 + blockedRight * 0.1
		end

	end

	--> Hearing
	do

		hearing = {}
		hearing.lastSoundPos = Vec(0, -100, 0)
		hearing.lastSoundVolume = 0
		hearing.timeSinceLastSound = 0
		hearing.hasNewSound = false

		function hearingInit()
		end

		function hearingUpdate(dt)
			hearing.timeSinceLastSound = hearing.timeSinceLastSound + dt
			if config.canHearPlayer then
				local vol, pos = GetLastSound()
				local dist = VecDist(robot.transform.pos, pos)
				if vol > 0.1 and dist > 4.0 and dist < config.maxSoundDist then
					local valid = true
					--If there is an investigation trigger, the robot is in it and the sound is not, ignore sound
					if robot.investigateTrigger ~= 0 and IsPointInTrigger(robot.investigateTrigger, robot.bodyCenter) and not IsPointInTrigger(robot.investigateTrigger, pos) then
						valid = false
					end
					--React if time has passed since last sound or if it's substantially stronger
					if valid and (hearing.timeSinceLastSound > 2.0 or vol > hearing.lastSoundVolume*2.0) then
						local attenuation = 5.0 / math.max(5.0, dist)
						attenuation = attenuation * attenuation
						local heardVolume = vol * attenuation
						if heardVolume > 0.05 then
							hearing.lastSoundVolume = vol
							hearing.lastSoundPos = pos
							hearing.timeSinceLastSound = 0
							hearing.hasNewSound = true
						end
					end
				end
			end
		end

		function hearingConsumeSound()
			hearing.hasNewSound = false
		end

	end
end



--= OTHER
do
	--> Util
	do

		function truncateToGround(pos)
			rejectAllBodies(robot.allBodies)
			QueryRejectVehicle(GetPlayerVehicle())
			hit, dist = QueryRaycast(pos, Vec(0, -1, 0), 5, 0.2)
			if hit then
				pos = VecAdd(pos, Vec(0, -dist, 0))
			end
			return pos
		end

		function getRandomPosInTrigger(trigger)
			local mi, ma = GetTriggerBounds(trigger)
			local minDist = math.max(ma[1]-mi[1], ma[3]-mi[3])*0.25
			minDist = math.min(minDist, 5.0)

			for i=1, 100 do
				local probe = Vec()
				for j=1, 3 do
					probe[j] = mi[j] + (ma[j]-mi[j])*rnd(0,1)
				end
				if IsPointInTrigger(trigger, probe) then
					return probe
				end
			end
			return VecLerp(mi, ma, 0.5)
		end

		function handleCommand(cmd)
			words = splitString(cmd, " ")
			if #words == 5 then
				if words[1] == "explosion" then
					local strength = tonumber(words[2])
					local x = tonumber(words[3])
					local y = tonumber(words[4])
					local z = tonumber(words[5])
					hitByExplosion(strength/2, Vec(x,y,z))
				end
			end
			if #words == 8 then
				if words[1] == "shot" then
					local strength = tonumber(words[2])
					local x = tonumber(words[3])
					local y = tonumber(words[4])
					local z = tonumber(words[5])
					local dx = tonumber(words[6])
					local dy = tonumber(words[7])
					local dz = tonumber(words[8])
					hitByShot(strength/1.5, Vec(x,y,z), Vec(dx,dy,dz))
				end
			end
		end


		function getClosestPatrolIndex()
			local bestIndex = 1
			local bestDistance = 999
			for i=1, #patrolLocations do
				local pt = GetLocationTransform(patrolLocations[i]).pos
				local d = VecLength(VecSub(pt, robot.transform.pos))
				if d < bestDistance then
					bestDistance = d
					bestIndex = i
				end
			end
			return bestIndex
		end


		function getDistantPatrolIndex(currentPos)
			local bestIndex = 1
			local bestDistance = 0
			for i=1, #patrolLocations do
				local pt = GetLocationTransform(patrolLocations[i]).pos
				local d = VecLength(VecSub(pt, currentPos))
				if d > bestDistance then
					bestDistance = d
					bestIndex = i
				end
			end
			return bestIndex
		end


		function getNextPatrolIndex(current)
			local i = current + 1
			if i > #patrolLocations then
				i = 1
			end
			return i
		end


		function markPatrolLocationAsActive(index)
			for i=1, #patrolLocations do
				if i==index then
					SetTag(patrolLocations[i], "active")
				else
					RemoveTag(patrolLocations[i], "active")
				end
			end
		end


		function debugState()
			local state = stackTop()
			DebugWatch("state", state.id)
			DebugWatch("activeTime", state.activeTime)
			DebugWatch("totalTime", state.totalTime)
			DebugWatch("navigation.state", navigation.state)
			DebugWatch("#navigation.path", #navigation.path)
			DebugWatch("navigation.hasNewTarget", navigation.hasNewTarget)
			DebugWatch("robot.blocked", robot.blocked)
			DebugWatch("robot.speed", robot.speed)
			DebugWatch("navigation.blocked", navigation.blocked)
			DebugWatch("navigation.unblock", navigation.unblock)
			DebugWatch("navigation.unblockTimer", navigation.unblockTimer)
			DebugWatch("navigation.thinkTime", navigation.thinkTime)
			DebugWatch("GetPathState()", GetPathState())
		end


		function canBeSeenByPlayer()
			for i=1, #robot.allShapes do
				if IsShapeVisible(robot.allShapes[i], config.outline, true) then
					return true
				end
			end
			return false
		end

		function hitByExplosion(strength, pos)
			--Explosions smaller than 1.0 are ignored (with a bit of room for rounding errors)
			if strength > 0.99 then
				local d = VecDist(pos, robot.bodyCenter)
				local f = clamp((1.0 - d/10.0), 0.0, 1.0) * strength
				if f > 0.2 then
					robot.stunned = robot.stunned + f * 4.0
				end

				--Give robots an extra push if they are not already moving that much
				--Unphysical but more fun
				local maxVel = 7.0
				local strength = 3.0
				local dir = VecNormalize(VecSub(robot.bodyCenter, pos))
				--Tilt direction slightly upwards to make them fly more
				dir[2] = dir[2] + 0.2
				dir = VecNormalize(dir)
				for i=1, #robot.allBodies do
					local b = robot.allBodies[i]
					local v = GetBodyVelocity(b)
					local scale = clamp(1.0-VecLength(v)/maxVel, 0.0, 1.0)
					local velAdd = math.min(maxVel, f*scale*strength)
					if velAdd > 0 then
						v = VecAdd(v, VecScale(dir, velAdd))
						SetBodyVelocity(b, v)
					end
				end
			end
		end


		function hitByShot(strength, pos, dir)
			if VecDist(pos, robot.bodyCenter) < 3 then
				local hit, point, n, shape = QueryClosestPoint(pos, 0.1)
				if hit then
					for i=1, #robot.allShapes do
						if robot.allShapes[i] == shape then
							robot.stunned = robot.stunned + 0.2
							return
						end
					end
				end
			end
		end

	end

	--> Physics
	do

		function VecDist(a, b)
			return VecLength(VecSub(a, b))
		end

		function rndVec(length)
			local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
			return VecScale(v, length)
		end

		function rnd(mi, ma)
			local v = math.random(0,1000) / 1000
			return mi + (ma-mi)*v
		end

		function rejectAllBodies(bodies)
			for i=1, #bodies do
				QueryRejectBody(bodies[i])
			end
		end

		function getTagParameter(entity, name, default)
			local v = tonumber(GetTagValue(entity, name))
			if v then
				return v
			else
				return default
			end
		end

		function getTagParameter2(entity, name, default)
			local s = splitString(GetTagValue(entity, name), ",")
			if #s == 1 then
				local v = tonumber(s[1])
				if v then
					return v, v
				else
					return default, default
				end
			elseif #s == 2 then
				local v1 = tonumber(s[1])
				local v2 = tonumber(s[2])
				if v1 and v2 then
					return v1, v2
				else
					return default, default
				end
			else
				return default, default
			end
		end

	end

	--> Logic
	do
		stack = {}
		stack.list = {}

		function stackTop()
			return stack.list[#stack.list]
		end

		function stackPush(id)
			local index = #stack.list+1
			stack.list[index] = {}
			stack.list[index].id = id
			stack.list[index].totalTime = 0
			stack.list[index].activeTime = 0
			return stack.list[index]
		end

		function stackPop(id)
			if id then
				while stackHas(id) do
					stackPop()
				end
			else
				if #stack.list > 1 then
					stack.list[#stack.list] = nil
				end
			end
		end

		function stackHas(s)
			return stackGet(s) ~= nil
		end

		function stackGet(id)
			for i=1,#stack.list do
				if stack.list[i].id == id then
					return stack.list[i]
				end
			end
			return nil
		end

		function stackClear(s)
			stack.list = {}
			stackPush("none")
		end

		function stackInit()
			stackClear()
		end

		function stackUpdate(dt)
			if #stack.list > 0 then
				for i=1, #stack.list do
					stack.list[i].totalTime = stack.list[i].totalTime + dt
				end

				--Tick total time
				stack.list[#stack.list].activeTime = stack.list[#stack.list].activeTime + dt
			end
		end
	end
end
