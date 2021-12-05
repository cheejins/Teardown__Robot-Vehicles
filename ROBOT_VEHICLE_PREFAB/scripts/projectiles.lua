projectiles = {}

function manageProjectiles()

    manageActiveProjs(projectiles)

end

--[[Projectiles]]
function createProjectile(transform, projectiles, projPreset, ignoreBodies) --- Instantiates a proj and adds it to the projectiles table.
    local proj = TableClone(projPreset)

    proj.transform = transform
    proj.ignoreBodies = ignoreBodies

    table.insert(projectiles, proj)
end

function manageActiveProjs(projectiles)

    local projsToRemove = {} -- projectiles iterations.
    for i = 1, #projectiles do

        local proj = projectiles[i]
        if proj.isActive and proj.hit == false then

            propelProjectile(proj)

            proj.lifeLength = proj.lifeLength - GetTimeStep()
            if proj.lifeLength <= 0 then
                proj.isActive = false
                proj.hit = true
            end

        elseif proj.isActive == false or proj.hit then -- if proj is inactive.
            table.insert(projsToRemove, i)
        end
    end

    for i = 1, #projsToRemove do -- remove proj from active projs after projectiles iterations.
        table.remove(projectiles, projsToRemove[i]) -- remove active projs
    end

end

function propelProjectile(proj)

    --+ Ignore bodies
    if proj.ignoreBodies ~= nil then
        for i = 1, #proj.ignoreBodies do
            QueryRejectBody(proj.ignoreBodies[i])
        end
    end

    --+ Raycast
    local pos = proj.transform.pos
    local dir = VecSub(proj.transform.pos, TransformToParentPoint(proj.transform, Vec(0,0,-1)))
    local dist = proj.speed
    local radius = 0.1
    local hit, dist, hitShape = QueryRaycast(pos, dir, dist, radius)
    if hit then

        local hitPos = TransformToParentPoint(proj.transform, Vec(0,0,dist))
        proj.hit = true

        Gas.drops.crud.spawn(hitPos)

    end

    --+ Proj hit water.
    if IsPointInWater(proj.transform.pos) then
        proj.hit = true
        SpawnParticle("water", proj.transform.pos, Vec(0,0,0), 3, 1)
    end

    --+ Proj life.
    if proj.hit then
        proj.isActive = false
    else
        proj.isActive = true
    end

    --+ Move proj forward.
    proj.transform.pos = TransformToParentPoint(proj.transform, Vec(0,0-proj.drop,-proj.speed))
    proj.drop = proj.drop + proj.dropIncrement

end

