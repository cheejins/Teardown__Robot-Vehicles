
function manageAeonWeaponParticles(proj)

    local trAhead = Transform(TransformToParentPoint(proj.transform, Vec(0,0,-proj.speed/1 + math.random())), proj.transform.rot)

    if proj.effects.particle == 'aeon_special' then
        SpawnParticle_aeon_weap_special(proj.transform)
        SpawnParticle_aeon_weap_special(proj.transform)
        SpawnParticle_aeon_weap_special(trAhead)
        SpawnParticle_aeon_weap_special(trAhead)
    elseif proj.effects.particle == 'aeon_secondary' then
        SpawnParticle_aeon_weap_secondary(proj.transform)
        SpawnParticle_aeon_weap_secondary(trAhead)
    end

end


-- Aeon secondary
function SpawnParticle_aeon_weap_secondary(tr, rad)
    local radius = rad or 0.5
    local life = 1.2
    local vel = 10
    local drag = 0.1
    local gravity = -math.random()+1
    local emissive = 3
    local red = 0.2
    local green = 0.3 + math.random()/10
    local blue = 1 + math.random()/10
    local alpha = 0.5 + math.random()/10

    ParticleReset()
    ParticleType("smoke")
    ParticleTile(5)
    ParticleRadius(radius)
    ParticleAlpha(alpha, alpha, "constant", 0.1/life, 0.5)	-- Ramp up fast, ramp down after 50%
    ParticleGravity(gravity * rnd(0.5, 1.5))				-- Slightly randomized gravity looks better
    ParticleDrag(drag)
    ParticleColor(red, green, blue, 0.0+ math.random()/10, 0.2+ math.random()/10, 0.6+ math.random()/10)			-- Animating color towards white
    ParticleEmissive(emissive, emissive/3, 'smooth', 0, 2)


    local p = tr.pos
    local v = VecAdd(VecScale(QuatToDir(tr.rot), vel), VecRdm(1))
    v[2] = -2
    local l = rnd(life*0.5, life*1.5)

    SpawnParticle(p, v, l)
end

function SpawnParticle_aeon_weap_special(tr, rad)
    local radius = rad or 0.5
    local life = 0.1
    local vel = -1
    local drag = 0.5
    local gravity = -math.random()+1
    local emissive = 5
    local red = 0
    local green = 0
    local blue = 1
    local alpha = 1

    ParticleReset()
    ParticleType("none")
    ParticleTile(1)
    ParticleRadius(radius/10, radius, 'smooth', 0,0.5)
    ParticleAlpha(alpha, alpha, "constant", 0.1/life, 0.5)	-- Ramp up fast, ramp down after 50%
    ParticleGravity(gravity * rnd(0.5, 1.5))				-- Slightly randomized gravity looks better
    ParticleDrag(drag)
    ParticleColor(red, green, blue, 1,1,1)			-- Animating color towards white
    ParticleEmissive(emissive, emissive/2, 'smooth', 0, 1)


    local p = tr.pos
    local v = VecAdd(VecScale(QuatToDir(tr.rot), vel), VecRdm(1))
    local l = rnd(life*0.5, life*1.5)

    SpawnParticle(p, v, l)
end


function SpawnParticle_aeon_weap_secondary_exhaust(tr, vel)
    local radius = 0.2
    local life = 2.0
    local vel = vel or 8
    local drag = 0.3
    local gravity = 0.0
    local red = 0.6
    local green = 0.6
    local blue = 0.6
    local alpha = 0.8

    ParticleReset()
    ParticleType("smoke")
    ParticleRadius(radius, radius*3)
    ParticleAlpha(alpha, alpha, "constant", 0.1/life, 0.5)	-- Ramp up fast, ramp down after 50%
    ParticleGravity(gravity * rnd(0.5, 1.5))				-- Slightly randomized gravity looks better
    ParticleDrag(drag)
    ParticleColor(red, green, blue, 1, 1, 1)			-- Animating color towards white

    local p = tr.pos
    local v = VecAdd(VecScale(QuatToDir(tr.rot), vel), VecRdm(1))
    local l = rnd(life*0.5, life*1.5)

    SpawnParticle(p, v, l)
end
