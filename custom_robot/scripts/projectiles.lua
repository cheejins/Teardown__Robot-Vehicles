Projectiles = {}


function createProjectile(transform, projectiles, projPreset, ignoreBodies) --- Instantiates a proj and adds it to the projectiles table.

    local proj = DeepCopy(projPreset)
    proj.ignoreBodies = DeepCopy(ignoreBodies)

    proj.transform = transform
    local trDir = QuatToDir(proj.transform.rot)
    trDir = VecNormalize(VecAdd(trDir, VecRdm(proj.spread)))
    proj.transform.rot = DirToQuat(trDir)

    if proj.homing.max > 0 then
        local hit, pos = RaycastFromTransform(GetCameraTransform())
        local vecRdm = VecRdm(2)
        vecRdm[2] = 0
        proj.homing.targetPos = VecAdd(pos, vecRdm)
    end

    table.insert(projectiles, proj)

end

function manageActiveProjectiles()

    local projectilesToRemove = {} -- projectiles iterations.
    for i, proj in ipairs(Projectiles) do

        -- DrawDot(proj.homing.targetPos, 0.25,0.25, 1,0,0, 1, false)
        -- SpawnParticle("smoke", proj.transform.pos, QuatToDir(proj.transform.rot), 0.5,0.5,1,1)

        if proj.isActive and proj.hit == false then

            propelProjectile(proj)

        elseif proj.isActive == false or proj.hit then -- if proj is inactive.

            table.insert(projectilesToRemove, i)

        end

    end

    for i = 1, #projectilesToRemove do -- remove proj from active projs after projectiles iterations.
        table.remove(Projectiles, projectilesToRemove[i]) -- remove active projs
    end

end

function propelProjectile(proj)

    --+ Move proj forward.
    proj.transform.pos = TransformToParentPoint(proj.transform, Vec(0,0,-proj.speed))

    proj.lifeLength = proj.lifeLength - GetTimeStep()
    if proj.lifeLength <= 0 then
        proj.hit = true
    end

    --+ Ignore bodies
    if proj.ignoreBodies ~= nil then
        for i = 1, #proj.ignoreBodies do
            QueryRejectBody(proj.ignoreBodies[i])
        end
    end

    --+ Raycast
    local rcHit, hitPos, hitShape = RaycastFromTransform(proj.transform, proj.speed, proj.rcRad, proj.ignoreBodies, nil, true)
    if rcHit and not proj.hitInitial then

        SetInt('level.destructible-bot.hitCounter', GetInt('level.destructible-bot.hitCounter') + 1)
        SetInt('level.destructible-bot.hitShape',hitShape)
        SetString('level.destructible-bot.weapon',"robotname")
        SetFloat('level.destructible-bot.damage',damage)

        proj.hitInitial = true
        proj.hit = true

        --+ Hit Action
        ApplyBodyImpulse(GetShapeBody(hitShape), hitPos, VecScale(QuatToDir(proj.transform.rot), proj.force))

        if proj.explosionSize > 0 then
            Explosion(hitPos, proj.explosionSize)
        end

        --+ Sounds
        local index = proj.sounds.hit[math.random(1, #proj.sounds.hit)]
        PlayRandomSound(proj.sounds.hit, proj.transform.pos, 2, index)
        PlayRandomSound(proj.sounds.hit, GetCameraTransform().pos, 0.2 + math.random()/10, index)

    end

    if proj.penetrate then

        proj.hit = false

        if VecDist(robot.transform.pos, proj.transform.pos) > proj.holeSize * 2 then
            MakeHole(proj.transform.pos, proj.holeSize,proj.holeSize,proj.holeSize,proj.holeSize)
        end

    end

    --+ Proj hit water.
    if IsPointInWater(proj.transform.pos) then
        proj.hit = true
        SpawnParticle("water", proj.transform.pos, Vec(0,0,0))
    end

    --+ Proj life.
    if proj.hit then
        proj.isActive = false
    else
        proj.isActive = true
    end

    --+ Proj homing.
    proj.transform.rot = MakeQuaternion(proj.transform.rot)
    proj.transform.rot = proj.transform.rot:Approach(QuatLookAt(proj.transform.pos, proj.homing.targetPos), proj.homing.force)

    if proj.homing.force < proj.homing.max then
        proj.homing.force = proj.homing.force + proj.homing.gain
    end

    --+ Draw sprite
    if proj.effects.sprite_facePlayer then
        DrawSprite(LoadSprite(proj.effects.sprite), Transform(proj.transform.pos, QuatLookAt(proj.transform.pos, GetCameraTransform().pos)), proj.effects.sprite_dimensions[1], proj.effects.sprite_dimensions[2], 1, 1, 1, 1, true)
    else
        DrawSprite(LoadSprite(proj.effects.sprite), Transform(proj.transform.pos, QuatRotateQuat(proj.transform.rot, QuatEuler(90,-90,0))), proj.effects.sprite_dimensions[1], proj.effects.sprite_dimensions[2], 1, 1, 1, 1, true)
        DrawSprite(LoadSprite(proj.effects.sprite), Transform(proj.transform.pos, QuatRotateQuat(proj.transform.rot, QuatEuler(0,-90,0))), proj.effects.sprite_dimensions[1], proj.effects.sprite_dimensions[2], 1, 1, 1, 1, true)
    end

    --+ Particles
    manageAeonWeaponParticles(proj)

    local c = proj.effects.color
    PointLight(proj.transform.pos, c[1], c[2], c[3], 1)

end

function initProjectiles()

    ProjectilePresets = {

        aeon_secondary = {
            isActive = true, -- Active when firing, inactive after hit.
            hit = false,
            hitInitial = false,
            lifeLength = 3, --Seconds

            speed = 3.1,
            spread = 0,
            drop = 0,
            dropIncrement = 0,
            explosionSize = 1,
            rcRad = 0.3,
            force = 10000,
            penetrate = true,
            holeSize = 1.5,

            effects = {
                particle = 'aeon_secondary',
                color = Vec(00.5,0.5,0.9),
                sprite = '../img/weap/plasma_orb.png',
                sprite_dimensions = {2, 2},
                sprite_facePlayer = true,
            },

            sounds = {
                hit = Sounds.weap_secondary.hit,
                hit_vol = 5,
            },

            homing = {
                force = 0,
                gain = 0,
                max = 0,
                targetPos = Vec(),
                targetPosRadius = 6,
            }
        },

        aeon_special = {
            isActive = true, -- Active when firing, inactive after hit.
            hit = false,
            hitInitial = false,
            lifeLength = 5, --Seconds

            speed = 0.85,
            spread = 0.3,
            drop = 0.1,
            dropIncrement = 0,
            explosionSize = 1.1,
            rcRad = 0.3,
            force = 0,
            penetrate = false,
            holeSize = 0,

            effects = {
                particle = 'aeon_special',
                color = Vec(0.2,0.2,0.9),
                sprite = '../img/weap/plasma_bullet.png',
                sprite_dimensions = {1.6, 0.3},
                sprite_facePlayer = false,
            },

            sounds = {
                hit = Sounds.weap_special.hit,
                hit_vol = 5,
            },

            homing = {
                force = 0,
                gain = 0.01,
                max = 2,
                targetPos = Vec(),
                targetPosRadius = 0,
            },
        },

    }
end
