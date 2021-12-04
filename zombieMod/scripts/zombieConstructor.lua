-- ====================================================================================================
-- Basic Ai Zombies - by: Cheejins
-- ====================================================================================================

-- ----------------------------------------------------------------------------------------------------
-- This script handles the creation of a zombie instance.
-- ----------------------------------------------------------------------------------------------------


--[[ZOMBIE CONSTRUCTION]]
function createZombie(body, id) -- Create zombie.

    local zombie = {}

    zombie.id = id
    zombie.body = body
    zombie.shapes = GetBodyShapes(zombie.body)

    --[[LIMBS]]
    zombie.limbs = {
        brain = nil,
        head = nil,
        neck = nil,
        body = nil,
        arms = {
            left = nil,
            right = nil,
        },
        legs = nil,
    }
    for i = 1, #zombie.shapes do
        local shape = zombie.shapes[i]
        if HasTag(shape,"z_head") then
            zombie.limbs.head = shape
        elseif HasTag(shape,"z_brain") then
            zombie.limbs.brain = shape
        elseif HasTag(shape,"z_neck") then
            zombie.limbs.neck = shape
        elseif HasTag(shape,"z_body") then
            zombie.limbs.body = shape
        elseif HasTag(shape,"z_arm_left") then
            zombie.limbs.arms.left = shape
        elseif HasTag(shape,"z_arm_right") then
            zombie.limbs.arms.right = shape
        elseif HasTag(shape,"z_legs") then
            zombie.limbs.legs = shape
        end
    end


    --[[AI]]
    zombie.health = 100
    zombie.ai = {
        isActive = true,
        targetPos = nil,
        state = "idle",
        states = {
            dead = "dead",
            still = "still",
            idle = "idle",
            alert = "alert",
            seeking = "seeking",
            chasing = "chasing",
            attacking = "attacking",
        },
        detection = {
            distances = {
                idle = math.huge,
                seeking = 150,
                chasing = 50,
                attacking = 4,
            },
        },
        attacking = {
            damage = 0.18,
            timer = 0,
            rpm = 30,
            distance = 1,
        },
        pathing = {
            shapes = {
                closeShapes = {},
                prevCloseShapes = {},
            },
            boids = {
                nearbyZombieBodies = {}
            },
            positions = {
                jump = Vec(0,1,0), -- Add height to zombie tr to detect jump height.
                center = Vec(0,1,0), -- Add height to zombie tr to detect walk forward height.
            },
            isGroundClear = false,
            dir = nil, -- Ultimate zombie velocity.
            status = nil,
        },
    }


    local randomSpeed = rdm(3,5)
    if randomSpeed < 2 then
        randomSpeed = 2
    end


    --[[Physics]]
    zombie.movement = {
        isOnGround = false,
        speed = 7,
        speeds = {
            walk = 2.5,
            run = 5,
            attacking = 4,
            random = randomSpeed,
        },
        hop = 1.8, -- Hop = y velocity.
        jump = 6,
        jumpSpeed = 2,
        lookRate = 0.03, -- The rate at which the zombie turns towards its target.
        upright = {
            raycastDist = 0.6,
            raycastVec = Vec(0,0.4,0),
            raycastVecOffset = Vec(0,0,0),
            rate = 0.95, -- Rate to rotate to upright.
        },
        velocityLimits = { -- Total velocity < limit = zombie can move.
            move = 6,
            keepUpright = 6,
        },
    }
    zombie.mass = {
        start = GetBodyMass(zombie.body),
        previous = GetBodyMass(zombie.body),
        deathPercentage = 0.82,
        deathVal = nil,
    }
    zombie.mass.deathVal = zombie.mass.start * zombie.mass.deathPercentage


    --[[Misc]]
    zombie.outlineColor = colors.white
    zombie.timers = {
        jump = {
            timer = 0,
            rpm = 30,
        },
        attack = {
            chargeUp = {
                default = 0.6,
                timer = 0.6,
                rpm = 60,
            },
            hit = {
                timer = 0,
                rpm = 50,
            },
        },
        sfx = {
            growl = {
                timer = 0,
                rpm = rdm(0.5, 1),
            },
            damage = { -- When zombie takes damage.
                timer = 0,
                rpm = rdm(0.5,1),
            },
        },
    }
    zombie.runTimers = function()
        zombie.timers.sfx.damage.timer = zombie.timers.sfx.damage.timer - GetTimeStep()
        zombie.timers.sfx.growl.timer = zombie.timers.sfx.growl.timer - GetTimeStep()
        zombie.timers.sfx.growl.timer = zombie.timers.sfx.growl.timer - GetTimeStep()
    end

    zombie.sounds = {
        chargeUpPlayed = true,
    }

    zombie = addZombieAccessors(zombie)
    zombie = addZombieFunctions(zombie)

    if SCRIPTED_MAP then zombie.ai.isActive = false end -- Scripted maps use trigger zones to activate zombies.
    setmetatable(zombie, zombieMetatable)

    return zombie
end

function addZombieAccessors(zombie)
    zombie.getTr = function() return GetBodyTransform(zombie.body) end
    zombie.setTr = function(tr) return SetBodyTransform(zombie.body, tr) end
    zombie.getPos = function() return GetBodyTransform(zombie.body).pos end
    zombie.setState = function(state) zombie.ai.state = state end

    zombie.isAlive = function()
        if zombie.isBroken() then
            if IsShapeBroken(zombie.limbs.brain) or IsShapeBroken(zombie.limbs.neck) then
                return false
            elseif GetBodyMass(zombie.body) < zombie.mass.deathVal then
                return false
            else
                -- Check shape size of zombie body (sometimes small broken pieces become the zombie's shape)
                local x, y, z = GetShapeSize(zombie.limbs.body)
                local size = x+y+z
                if size < 20 then
                    return false
                end
            end
        end
        return true
    end

    zombie.isBroken = function() if GetBodyMass(zombie.body) < zombie.mass.start then return true end return false end
    zombie.wasHit = function () if GetBodyMass(zombie.body) < zombie.mass.previous then end end

    zombie.isVelLow = function()
        local zVel = VecLength(GetBodyVelocity(zombie.body))
        if zVel < zombie.movement.velocityLimits.keepUpright then return true end return false
    end

    return zombie
end

function addZombieFunctions(zombie)

    zombie.getTargetPlayer = function()

        local zTr = zombie.getTr()

        local playerPos = GetPlayerTransform().pos
        local distZombieToPlayerPos = CalcDist(zTr.pos, playerPos)
        local distZombieToPlayerPosScaled = distZombieToPlayerPos/20

        if distZombieToPlayerPosScaled > 10 and distZombieToPlayerPos < 30 then
            distZombieToPlayerPosScaled = 10
            local playerVel = GetPlayerVelocity()
            local playerVelScaled = VecScale(playerVel, distZombieToPlayerPosScaled)
            return VecAdd(playerPos, playerVelScaled)
        end

        return playerPos
    end

    zombie.manageHealth = function()
        if GetBodyMass(zombie.body) < zombie.mass.previous then
            sounds.play.damage(zombie)
        end
        zombie.mass.previous = GetBodyMass(zombie.body)
    end

    zombie.drawOutline = function()
        local c = VecCopy(zombie.outlineColor)
        local a = 4/CalcDist(zombie.getPos(), GetPlayerTransform().pos)
        DrawBodyOutline(zombie.body, c[1], c[2], c[3], a)
    end


    zombie.raycastNavigate = function ()

        local zTr = zombie.getTr()

        -- Move values.
        local speed = zombie.movement.speed
        local hop = zombie.movement.hop
        local jump = zombie.movement.jump
        local JumpSpeed = zombie.movement.jumpSpeed

        -- Raycast center fwd (walk fwd).
        local rc = {
            upper = { -- Raycast straight from zombie upper.
                dist = 2,
                rad = 1.5,
                tr = Transform(VecAdd(zTr.pos, Vec(0,2.5,0)), zTr.rot),
            },
            lower = { -- Raycast straight from zombie lower.
                dist = 2.5,
                rad = 0.2,
                tr = Transform(VecAdd(zTr.pos, Vec(0,0.5,0)), zTr.rot),
            },
            closest = {
                dist = 2,
                tr = Transform(VecAdd(zTr.pos, Vec(0,2,0)), zTr.rot),
            }
        }

        -- lower
        local hitLower, hitPosLower, hitShapeLower = raycastFromTransform(rc.lower.tr, rc.lower.dist, rc.lower.rad, zombie.body)
        if hitLower and not HasTag(GetShapeBody(hitShapeAround),'ai_zombie') then
            -- DebugLine(hitPosLower, TransformToParentPoint(rc.lower.tr, Vec(0,0,-rc.lower.dist)), 0, 1, 0)
        end


        local hitUpper, hitPosUpper, hitShapeUpper = nil,nil,nil
        if hitLower then
            -- upper
            hitUpper, hitPosUpper, hitShapeUpper = raycastFromTransform(rc.upper.tr, rc.upper.dist, rc.upper.rad, zombie.body)
            if hitUpper and not HasTag(GetShapeBody(hitShapeAround),'ai_zombie') then
                -- DebugLine(hitPosUpper, TransformToParentPoint(rc.upper.tr, Vec(0,0,-rc.upper.dist)), 1, 1, 0)
            end
        end

        local zombieBodyCollision = HasTag(GetShapeBody(hitShapeLower),'ai_zombie')
        local hitShapeVelLow = VecLength(GetBodyVelocity(GetShapeBody(hitShapeUpper or hitShapeLower))) < 10

        -- Obstacle decisions.
        local path = {
            walk = (not hitLower) and (not hitUpper) and isZombieOnGround(zombie),
            jump = (hitLower and not hitUpper) and (not zombieBodyCollision) and isZombieOnGround(zombie),
            blocked = ((hitLower and hitUpper) or hitUpper) and not zombieBodyCollision and hitShapeVelLow and GetShapeSize(hitShapeUpper) > 5,
        }

        -- Movement
        if path.jump then
            -- zombie.ai.pathing.status = "Jumping"

            if CalcDist(rc.lower.tr.pos, hitShapeLower) < JumpSpeed then
                zombieMoveWalk(zombie, -speed/2, jump) -- Back up
            else
                zombieMoveWalk(zombie, JumpSpeed, jump) -- Jump forward
            end

        elseif path.blocked then
            -- zombie.ai.pathing.status = "Blocked"

            -- Side movement based on center of shape.
            local sMin, sMax = GetShapeBounds(hitShapeUpper)
            local shapeCenter = VecLerp(sMin, sMax, 0.5)
            local sidePos = TransformToLocalPoint(zTr, shapeCenter)
            if sidePos[1] <= 0 then sidePos[1] = -1 else sidePos[1] = 1 end

            -- Smaller movement for zombies blocking zombies to prevent fast collisions.
            local isZombyBody = HasTag(GetShapeBody(hitShapeLower),'ai_zombie') or HasTag(GetShapeBody(hitShapeUpper),'ai_zombie')

            -- Move zombie.
            if isZombyBody then
                zombieMoveWalk(zombie, speed * 0.7, hop, sidePos[1])
            else
                zombieMoveWalk(zombie, -speed/5, hop/2, sidePos[1] * 2)
            end

        else
            -- Walk
            zombieMoveWalk(zombie, speed, hop)
            zombieLookAt(zombie, zombie.ai.targetPos, zombie.movement.lookRate)
        end

    end


    zombie.boidsNavigate = function ()

        local zTr = zombie.getTr()

        -- Surrounding Aabb.
        local aabbZX = 2.5
        local aabbFloor = 0
        local aabbHeight = 1
        local aabbStartPos = VecAdd(zTr.pos, Vec(-aabbZX,aabbFloor,-aabbZX))
        local aabbEndPos = VecAdd(zTr.pos, Vec(aabbZX,aabbHeight,aabbZX))
        -- drawAabb(aabbStartPos, aabbEndPos, 1, 1, 1, 1)

        -- Quuery surrounding AABBs.
        QueryRejectBody(zombie.body)
        local nearbyZombieBodiesList = QueryAabbBodies(aabbStartPos, aabbEndPos)
        for i = 1, #nearbyZombieBodiesList do
            if not HasTag(nearbyZombieBodiesList[i], 'ai_zombie') then
                nearbyZombieBodiesList[i] = nil -- Keep zombie bodies only
            else
                local nZAabbMin, nZAabbMax = GetBodyBounds(nearbyZombieBodiesList[i])
                -- drawAabb(nZAabbMin, nZAabbMax, 1, 0, 0, 1)
            end
        end

        -- Process boids.
        if zombie.ai.isActive then
            for i = 1, #nearbyZombieBodiesList do

                local boid = zombie.body
                local boidVel = GetBodyVelocity(boid)
                local boidVelScaled = VecScale(VecNormalize(boidVel), zombie.movement.speeds.run)

                -- Apply computations to vel.
                -- local align = computeAlignment(boid, zombiesTable)
                -- local obstacles = computeObstacles(boid)
                local separation = computeSeparation(boid, nearbyZombieBodiesList, zombie.ai.pathing.targetPos)

                local boidVelNew = VecCopy(boidVelScaled)
                boidVelNew = VecAdd(boidVelNew, separation)
                -- boidVelNew = VecAdd(boidVelNew, align)
                -- boidVelNew = VecAdd(boidVelNew, obstacles)
                boidVelNew[2] = boidVel[2]

                SetBodyVelocity(boid, boidVelNew)
            end
        end

    end


    return zombie
end
