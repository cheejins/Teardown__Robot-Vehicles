activeMissiles = {}
activeBullets = {}


--[[BULLETS]]
function createBullet(transform, activeBullets, bulletPreset, ignoreBodies) --- Instantiates a bullet and adds it to the activeBullets table

    local bullet = TableClone(bulletPreset)
    bullet.transform = transform
    bullet.ignoreBodies = ignoreBodies

    table.insert(activeBullets, bullet)

end
function manageActiveBullets(activeBullets)
    if #activeBullets >= 1 then

        local bulletsToRemove = {} -- activeBullets iterations.
        for i = 1, #activeBullets do

            local bullet = activeBullets[i]
            if bullet.isActive and bullet.hit == false then

                propelBullet(bullet)

                bullet.lifeLength = bullet.lifeLength - GetTimeStep()
                if bullet.lifeLength <= 0 then
                    bullet.isActive = false
                    bullet.hit = true
                end

            elseif bullet.isActive == false or bullet.hit then -- if bullet is inactive.
                table.insert(bulletsToRemove, i)
                -- DebugPrint("Insert bullet " .. i)
            end
        end

        for i = 1, #bulletsToRemove do -- remove bullet from active bullets after activeBullets iterations.
            table.remove(activeBullets, bulletsToRemove[i]) -- remove active bullets
            -- DebugPrint("Removed bullet " .. i)
        end
    end

end
function propelBullet(bullet)

    if bullet.ignoreBodies ~= nil then -- TODO append different tags to table
        for i = 1, #bullet.ignoreBodies do
            QueryRejectBody(bullet.ignoreBodies[i])
        end
    end

    -- hit shape
    local pos = bullet.transform.pos
    local dir = VecNormalize(VecSub(bullet.transform.pos, TransformToParentPoint(bullet.transform, Vec(0,0,-1))))
    local dist = bullet.speed
    local radius = 0
    local hit, dist, norm, hitShape = QueryRaycast(pos, dir, dist, radius)
    if hit then

        local hitPos = TransformToParentPoint(bullet.transform, Vec(0,0,dist))

        ParticleReset()
		ParticleType("smoke")
		ParticleRadius(0.3, 0.1)
        ParticleEmissive(0.3, 0.1)
		ParticleAlpha(1, 0.5, "constant", 0.1/1, 0.5)	-- Ramp up fast, ramp down after 50%
		ParticleGravity(1 * rnd(0.5, 1.5))				-- Slightly randomized gravity looks better
		ParticleDrag(1)
		ParticleColor(0.5,0.5,0.5, 0.9, 0.9, 0.9)			-- Animating color towards white
        SpawnParticle(hitPos, VecRdm(0,1), 1)

        local holeSize = regGetFloat('robot.weapon.bullet.holeSize')
        MakeHole(hitPos, holeSize, holeSize, holeSize, holeSize)
        PointLight(hitPos, bullet.particleColor[1], bullet.particleColor[2], bullet.particleColor[3], 3)

        if bullet.explosive > 0 then
            Explosion(hitPos, bullet.explosive)
        end

        local hitBody = GetShapeBody(hitShape)

        -- Bullet kinetic force
        -- local totalVel = GetBodyVelocity(hitBody)
        if IsBodyDynamic(hitBody) and VecDist(GetBodyVelocity(hitBody)) < bullet.force then
            local hitBodyTr = GetBodyTransform(hitBody)
            ApplyBodyImpulse(hitBody, VecSub(hitBodyTr.pos, bullet.transform.pos), VecScale(QuatToDir(bullet.transform.rot), bullet.force * 1000/GetBodyMass(hitBody)))
            -- SetBodyVelocity(hitBody, VecAdd(totalVel, VecScale(QuatToDir(bullet.transform.rot), bullet.force * GetBodyMass(hitBody)/100)))
        end

        bullet.hit = true

    end

    -- hit water
    if IsPointInWater(bullet.transform.pos) then
        bullet.hit = true
        SpawnParticle("water", bullet.transform.pos, Vec(0,0,0))
    end

    if bullet.hit then
        bullet.isActive = false
    else
        bullet.isActive = true
    end

    PointLight(bullet.transform.pos, bullet.particleColor[1], bullet.particleColor[2], bullet.particleColor[3], 1)

    DrawSprite(LoadSprite('ui/common/dot.png'), Transform(bullet.transform.pos, QuatRotateQuat(bullet.transform.rot, QuatEuler(90,90,0))), 0.5, 0.15, bullet.particleColor[1], bullet.particleColor[2], bullet.particleColor[3], 1, true)
    DrawSprite(LoadSprite('ui/common/dot.png'), Transform(bullet.transform.pos, QuatRotateQuat(bullet.transform.rot, QuatEuler(0,90,0))), 0.5, 0.15, bullet.particleColor[1], bullet.particleColor[2], bullet.particleColor[3], 1, true)

    ParticleReset()
    ParticleEmissive(0.5, 0.2, "easein")
    ParticleGravity(0)
    ParticleRadius(0.1, 0.05, "smooth") 
    ParticleColor(bullet.particleColor[1], bullet.particleColor[2], bullet.particleColor[3], 1, 1, 1)
    ParticleTile(3)
    ParticleDrag(0.2)
    ParticleCollide(0, 1, "easeout")
    SpawnParticle(bullet.transform.pos, VecRdm(0,1), 0.2)


    bullet.transform.pos = TransformToParentPoint(bullet.transform, Vec(0,-0.01,-bullet.speed))

end


--[[MISSILES]]
function createMissile(transform, activeMissiles, missilePreset, ignoreBodies)
    --- Instantiates a missile and adds it to the activeMissiles table

    local missile = TableClone(missilePreset)
    missile.transform = transform
    missile.ignoreBodies = ignoreBodies

    table.insert(activeMissiles, missile)
end
function manageActiveMissiles(activeMissiles)
    if #activeMissiles >= 1 then

        local missilesToRemove = {} -- activeMissiles iterations.
        for i = 1, #activeMissiles do

            local missile = activeMissiles[i]
            if missile.isActive and missile.hit == false then

                propelMissile(missile)

                missile.lifeLength = missile.lifeLength - GetTimeStep()
                if missile.lifeLength <= 0 then
                    missile.isActive = false
                    missile.hit = true
                end

            elseif missile.isActive == false or missile.hit then -- if missile is inactive.
                table.insert(missilesToRemove, i)
                -- DebugPrint("Insert missile " .. i)
            end
        end

        for i = 1, #missilesToRemove do -- remove missile from active missiles after activeMissiles iterations.
            table.remove(activeMissiles, missilesToRemove[i]) -- remove active missiles
        end

    end
end
function propelMissile(missile)

    missile.transform.pos = TransformToParentPoint(missile.transform, Vec(0,-missile.dropOff,-missile.speed))
    PointLight(missile.transform.pos, missile.particleColor[1], missile.particleColor[2], missile.particleColor[3], 3)

    ParticleReset()
    ParticleEmissive(0.4, 0.4, "easein")
    ParticleGravity(-1)
    ParticleRadius(missile.particleRadius, 0.0, "smooth")
    ParticleColor(missile.particleColor[1], missile.particleColor[2], missile.particleColor[3], 2, 2, 2)
    ParticleTile(4)
    ParticleDrag(0.5)
    ParticleCollide(0, 1, "easeout")
    SpawnParticle(missile.transform.pos, VecRdm(1,2), 1)

    -- raycast
    for i = 1, #missile.ignoreBodies do
        QueryRejectBody(missile.ignoreBodies[i])
    end

    local pos = missile.transform.pos
    local dir = VecNormalize(VecSub(missile.transform.pos, TransformToParentPoint(missile.transform, Vec(0,0,-1))))
    local dist = missile.speed
    local radius = 0.4
    local hit, dist, hitShape = QueryRaycast(pos, dir, dist, radius)
    if hit then

        if missile.ignoreBodies == nil then
            missile.hit = true
        else

            local isIgnoredBody = false
            if isIgnoredBody == false then
                for i = 1, #missile.ignoreBodies do

                    local ignoredBody = missile.ignoreBodies[i]
                    local hitBody = GetShapeBody(shape)

                    DebugLine(GetBodyTransform(hitBody).pos, Vec(0,0,0))

                    if ignoredBody == hitBody then
                        -- DebugPrint("Missile hit ignored" .. sfn(GetTime()))
                        isIgnoredBody = true -- exit for-loop. ignore hit.
                    else
                        missile.hit = true
                        -- DebugPrint("Missile hit " .. sfn(GetTime()))
                    end

                end
            end

        end

        -- Explosion(missile.transform.pos, missile.explosionSize)
        local explosionSize = regGetFloat('robot.weapon.rocket.explosionSize')
        Explosion(missile.transform.pos, explosionSize)
        SpawnParticle("fire", missile.transform.pos, Vec(0,0,0))
        missile.hit = true
    end

    -- hit water
    if IsPointInWater(missile.transform.pos) then
        missile.hit = true
        SpawnParticle("water", missile.transform.pos, Vec(0,0,0))
    end

    if missile.hit then
        missile.isActive = false
    else
        missile.isActive = true
    end

    missile.transform.pos = TransformToParentPoint(missile.transform, Vec(0,0,-missile.speed))
end


function initWeapons()

    --[[BULLET PRESETS]]
    bulletPresets = {

        mg = {
            light = {
                isActive = true, -- Active when firing, inactive after hit.
                speed = 2,
                lifeLength = 2,
                -- sprite = sprites.bullet.mg,
                sound = nil,
                particle = 'smoke',
                particleColor = Vec(1, 0.7, 0.22),
                explosive = 0,
                hit = false,
                force = 5,
            },
            medium = {
                isActive = true, -- Active when firing, inactive after hit.
                speed = 0.5,
                lifeLength = 3,
                -- sprite = sprites.bullet.mg,
                sound = nil,
                particle = 'smoke',
                particleColor = Vec(1, 0.3, 0),
                explosive = 1,
                hit = false,
                force = 1,
            },
        },

        plasma = {
            light = {
                isActive = true, -- Active when firing, inactive after hit.
                speed = 0.5,
                lifeLength = 2,
                -- sprite = sprites.bullet.mg,
                particle = 'smoke',
                particleColor = Vec(0.3, 0.3, 1),
                explosive = 0.5,
                hit = false,
                force = 1,
            },
        }

    }

    missilePresets = {

        rocket = {
            isActive = true, -- Active when firing, inactive after hit.
            speed = 0.2,
            lifeLength = 10,
            -- sprite = sprites.bullet.mg,
            particleRadius = 0.2,
            particleLife = 9,
            particleColor = Vec(0.8, 0.4, 0),
            explosionSize = 1.8,
            hit = false,
            dropOff = 0,
            force = 0,
        },

        fuelrod = {
            isActive = true, -- Active when firing, inactive after hit.
            speed = 0.4,
            lifeLength = 5,
            -- sprite = sprites.bullet.mg,
            particleRadius = 1,
            particleLife = 1,
            particleColor = Vec(0.3, 1, 0.3),
            explosionSize = 3.5,
            hit = false,
            dropOff = 0,
            force = 0,
        }

    }

end
function manageProjectiles()
    manageActiveBullets(activeBullets)
    manageActiveMissiles(activeMissiles)
end
