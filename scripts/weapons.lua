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
    SpawnParticle(bullet.transform.pos, rdmVec(0,1), 0.2)

    if bullet.ignoreBodies ~= nil then -- TODO append different tags to table
        for i = 1, #bullet.ignoreBodies do
            QueryRejectBody(bullet.ignoreBodies[i])
        end
    end

    -- hit shape
    local pos = bullet.transform.pos
    local dir = VecSub(bullet.transform.pos, TransformToParentPoint(bullet.transform, Vec(0,0,-1)))
    local dist = bullet.speed
    local radius = 0.2
    local hit, dist, hitShape = QueryRaycast(pos, dir, dist, radius)
    if hit then

        local hitPos = TransformToParentPoint(bullet.transform, Vec(0,0,dist))

        ParticleReset()
        ParticleEmissive(2, 1, "easeout")
        ParticleGravity(0)
        ParticleRadius(0.1, 0.2, "smooth") 
        ParticleColor(0.5, 0.5, 0.5, 1, 1, 1)
        ParticleTile(3)
        -- ParticleDrag(0.5)
        -- ParticleCollide(0, 1, "easeout")

        SpawnParticle('smoke', rdmVec(0,1), 1)

        MakeHole(hitPos, 0.5, 0.5, 0.5, 0.5)

        ApplyBodyImpulse(GetShapeBody(hitShape), bullet.transform.pos, bullet.force)

        if bullet.explosive > 0 then
            Explosion(hitPos, bullet.explosive)
        end

        PointLight(hitPos, bullet.particleColor[1], bullet.particleColor[2], bullet.particleColor[3], 1)
        ApplyBodyImpulse(GetShapeBody(hitShape), GetBodyTransform(GetShapeBody(hitShape)).pos, VecScale(GetQuatEulerVec(GetQuatEulerVec(bullet.transform.rot)), 3))

        bullet.hit = true

    end

    -- hit water
    if IsPointInWater(bullet.transform.pos) then
        bullet.hit = true
        SpawnParticle("water", bullet.transform.pos, Vec(0,0,0), 3, 1)
    end

    if bullet.hit then
        bullet.isActive = false
    else
        bullet.isActive = true
    end

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
    SpawnParticle(missile.transform.pos, rdmVec(1,2), 1)

    -- raycast
    for i = 1, #missile.ignoreBodies do
        QueryRejectBody(missile.ignoreBodies[i])
    end

    local pos = missile.transform.pos
    local dir = VecSub(missile.transform.pos, TransformToParentPoint(missile.transform, Vec(0,0,-1)))
    local dist = missile.speed
    local radius = 1
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

        Explosion(missile.transform.pos, missile.explosionSize)
        SpawnParticle("fire", missile.transform.pos, Vec(0,0,0), 6, 1)
        missile.hit = true
    end

    -- hit water
    if IsPointInWater(missile.transform.pos) then
        missile.hit = true
        SpawnParticle("water", missile.transform.pos, Vec(0,0,0), 3, 1)
    end

    if missile.hit then
        missile.isActive = false
    else
        missile.isActive = true
    end

    missile.transform.pos = TransformToParentPoint(missile.transform, Vec(0,-0.01,-missile.speed))
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
                force = 1000,
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
            speed = 0.3,
            lifeLength = 10,
            -- sprite = sprites.bullet.mg,
            particleRadius = 0.1,
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
function manageWeapons()
    manageActiveBullets(activeBullets)
    manageActiveMissiles(activeMissiles)
end