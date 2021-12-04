#include "scripts/boids.lua"
#include "scripts/utility.lua"
#include "scripts/zombieController.lua"
#include "scripts/zombieConstructor.lua"


-- ====================================================================================================
-- Zombie AI - by: Cheejins
-- ====================================================================================================

-- ----------------------------------------------------------------------------------------------------
-- This script handles the movement, actions and AI of the zombie.
-- ----------------------------------------------------------------------------------------------------

zombiesTable = {}


function initZombies()
    local zombieBodies = FindBodies("ai_zombie", true)
    for i = 1, #zombieBodies do -- Store body references.
        local body = zombieBodies[i]
        local zombie = createZombie(body, i)
        table.insert(zombiesTable, zombie)
    end
    zombieMetatable = createZombie()
end


function manageZombies()
    for i = 1, #zombiesTable do
        local zombie = zombiesTable[i]
        manageZombie(zombie)
    end
    processBoids()
    navigationTimer.runTimerConst()
end


function manageZombie(zombie)
    if zombie.ai.isActive then
        if zombie:isAlive() then
            zombieProcessAi(zombie)
            diminishBodyAngVel(zombie.body, 0.8)
        else
            zombie.ai.isActive = false -- Disable dead zombie's ai.
            zombieDie(zombie)
        end
    end
end


--[[AI BEHAVIOR]]
function zombieProcessAi(zombie)

    -- Setting zombie target based on player vel.
    if not zombieController.isActive then
        zombie.ai.targetPos = zombie.getTargetPlayer()
    end
    zombie.ai.targetPos[2] = zombie.getPos()[2]

    zombieProcessState(zombie)

    -- Attack charge-up timer. 
    if zombie.ai.state ~= zombie.ai.states.attacking then
        zombie.timers.attack.chargeUp.time = zombie.timers.attack.chargeUp.deafult
        zombie.sounds.chargeUpPlayed = false
        -- DebugPrint('reset chargeup')
    end

    zombie.manageHealth()
    zombie.runTimers()

    if GetBool('savegame.mod.options.outline') then
        zombie.drawOutline()
    end

end

function zombieProcessState(zombie)

    local distZombieToPlayer = CalcDist(zombie.getTr().pos, zombie.ai.targetPos)
    if not zombie.isAlive() then -- zombie dead?
        zombie.setState(zombie.ai.states.dead)

    elseif distZombieToPlayer < zombie.ai.detection.distances.attacking then -- Close enough to attack.

        zombie.setState(zombie.ai.states.attacking)
        stateFunctions.attacking(zombie)

    elseif distZombieToPlayer < zombie.ai.detection.distances.chasing then -- Close enough to chase.

        zombie.setState(zombie.ai.states.chasing)
        stateFunctions.chasing(zombie)

    elseif distZombieToPlayer < zombie.ai.detection.distances.seeking then -- Close enough to seek.

        zombie.setState(zombie.ai.states.seeking)
        stateFunctions.seeking(zombie)

    else -- Too far, so stay still.

        zombie.setState(zombie.ai.states.still)
        stateFunctions.still(zombie)
    end

end

stateFunctions = {

    still = function(zombie)
        zombie.outlineColor = colors.black

        local speed = 0
        -- zombieChaseTarget(zombie, speed)
        if isZombieOnGround(zombie) and zombie.isVelLow() then
            zombieMoveWalk(zombie, 0, 1.5) -- hop in place
            zombieKeepUpright(zombie)
        end

    end,

    -- idle = function(zombie) end,
    -- alert = function(zombie) end,

    seeking = function(zombie)
        zombie.outlineColor = colors.white

        local speed = zombie.movement.speeds.random
        zombieChaseTarget(zombie, speed)
    end,


    chasing = function(zombie)
        zombie.outlineColor = colors.yellow

        local speed = zombie.movement.speeds.run
        zombieChaseTarget(zombie, speed)
    end,


    attacking = function(zombie)
        zombie.outlineColor = colors.red

        local speed = zombie.movement.speeds.attacking
        zombieChaseTarget(zombie, speed)
        zombieAttackPlayer(zombie)
    end,

}


--[[ZOMBIE MOVEMENT]]
function isZombieOnGround(zombie)

    local zTr = zombie.getTr()

    local rcTr = Transform(VecAdd(zTr.pos, Vec(0,0.5,0)), QuatLookDown(zTr.pos))
    local hit, hitPos, hitShape = raycastFromTransform(rcTr, 0.5, 0.5, zombie.body)

    local isRcBodyZombie = HasTag(GetShapeBody(hitShape), "ai_zombie")
    if hit and not isRcBodyZombie or IsPointInWater(zombie.getTr().pos) then
        return true
    end
    return false
end


function zombieKeepUpright(zombie, rotRate)
    local zTr = zombie.getTr()
    zTr.rot[1] = zTr.rot[1] * 0.9999
    zTr.rot[3] = zTr.rot[3] * 0.9999
    zombie.setTr(zTr)
end


function zombieLookAt(zombie, targetPos, rate)
    local zTr = zombie.getTr()
    local zTrNew = TransformCopy(zTr)

    local lookRot = QuatLookAt(zTr.pos, targetPos)
    local zTrRot = QuatSlerp(zTr.rot, lookRot, rate or 0.4)  -- Look left and right only.
    zTr.rot[1] = 0
    zTr.rot[3] = 0
    zTrNew.rot = zTrRot

    zombie.setTr(zTrNew)
end


function zombieMoveWalk(zombie, speed, hopAmt, sideAmt, velDir)
    if velDir == nil then
        local zTr = zombie.getTr()
        local zVel = GetBodyVelocity(zombie.body)
        local zFwdPos = TransformToParentPoint(zTr, Vec(sideAmt or 0, -hopAmt or -1, speed or 3))
        local zPos = zTr.pos
        local velSub = VecSub(zPos, zFwdPos)
        SetBodyVelocity(zombie.body, velSub)
    else
        SetBodyVelocity(zombie.body, velDir)
    end
end


function zombieMoveJump(zombie, jumpForce)
    if jumpForce == nil then
        jumpForce = 5
    end
    local zTr = zombie.getTr()
    local jumpVel = TransformToParentPoint(zTr, Vec(0, jumpForce, -jumpForce * 0.8))
    local jumpDir = VecSub(jumpVel, zTr.pos)
    SetBodyVelocity(zombie.body, jumpDir)
end


function zombieAttackPlayer(zombie)

    -- Charge up hit.
    if zombie.timers.attack.chargeUp.timer <= 0 then -- charge up timer.

        -- DebugPrint('Charging'..sfnTime())

        -- Hit player
        if zombie.timers.attack.hit.timer <= 0 then -- attack timer.
            zombie.timers.attack.hit.timer = 60/zombie.timers.attack.hit.rpm

            local playerPos = game.ppos
            -- zombieLookAt(zombie, playerPos, 0.1)

            -- Hit values
            local zTr = zombie.getTr()
            local zFwdPos = Vec(0,1,-2)
            local attackPos = TransformToParentPoint(zTr, zFwdPos)
            local zombieToPlayerDist = CalcDist(attackPos, playerPos)
            DebugLine(attackPos, playerPos)

            -- Hit player
            if zombieToPlayerDist < zombie.ai.attacking.distance then
                SetPlayerHealth(GetPlayerHealth() - zombie.ai.attacking.damage) -- Decrease player health.
                -- DebugPrint('hit'..sfnTime())
                sounds.play.hit(zombie)
            end

        else
            -- countdown until next hit.
            zombie.timers.attack.hit.timer = zombie.timers.attack.hit.timer - GetTimeStep() 
        end

    else
        -- countdown until next chargeup.
        zombie.timers.attack.chargeUp.timer = zombie.timers.attack.chargeUp.timer - GetTimeStep()

    end

    -- Play sounds once per chargeup.
    if zombie.sounds.chargeUpPlayed == false then
        zombie.sounds.chargeUpPlayed = true
        sounds.play.growl(zombie)
    end

end

function zombieChaseTarget(zombie, speed)

    if zombie.isVelLow() then

        -- Keep zombie stable
        zombieLookAt(zombie, zombie.ai.targetPos, 0.3)
        zombieKeepUpright(zombie)

        if isZombieOnGround(zombie) then
            local zVel = GetBodyVelocity(zombie.body)

            zombie.movement.speed = speed
            zombie.raycastNavigate()

            -- if boidsData.timer.time <= 0 then -- Timed for performance.
            --     boidsData.timer.time = 60/boidsData.timer.rpm
                zombie.boidsNavigate()
            -- end

            local zVelRaycast = GetBodyVelocity(zombie.body)
            local zVelLerp = VecLerp(zVel, zVelRaycast, 0.5)
            SetBodyVelocity(zombie.body, zVelLerp)
        end

    end

end


-- [[ZOMBIE MISC]]
function zombieDie(zombie)
    zombie.ai.isActive = false -- Disable dead zombie's ai.
    if zombie:isAlive() == false then
        sounds.play.death(zombie) -- Death sound.
        zombie.ai.isAlive = false
    end
end

-- Times when to process zombie navigation for better performance.
navigationTimer = { time = 0, rpm = 5000,}
navigationTimer.runTimerConst = function() navigationTimer.time = navigationTimer.time - GetTimeStep() end