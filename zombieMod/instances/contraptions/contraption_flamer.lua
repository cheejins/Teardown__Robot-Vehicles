function init()

    nozzleShapes = FindShapes('nozzle')
    base = FindShape('base')

    playerDamageAmt = 0.02

    timer = {
        time = 0,
        rpm = 400,
    }

    loops = {
        nozzle = LoadLoop("tools/blowtorch-loop")
    }


end

function tick()
    runNozzles()
end

function runNozzles()
    for i = 1, #nozzleShapes do

        -- Nozzle shape properties.
        local nShape = nozzleShapes[i]
        local nTr = GetShapeWorldTransform(nShape)

        -- Player properties.
        local playerNearNozzle = VecDist(GetPlayerTransform().pos, nTr.pos) < 1.5

        -- Center of nozzle shape.
        local nMin, nMax = GetShapeBounds(nShape)
        nTr.pos = VecLerp(nMin, nMax, 0.5)


        -- Raycast. Timed for performance.
        local rcTr = nil
        local hit, hitpos, hitShape = nil, nil, nil
        if timer.time <= 0 then
            timer.time = 60/timer.rpm

            rcTr = Transform(nTr.pos, QuatLookAt(nTr.pos, TransformToParentPoint(nTr, Vec(0,0,1))))
            QueryRejectShape(nShape)
            QueryRejectShape(base)
            hit, hitpos, hitShape = raycastFromTransform(rcTr, 1, 1)
        else
            timer.time = timer.time - GetTimeStep()
        end


        -- Manage nozzle shooting.
        if (hit or playerNearNozzle) and rcTr ~= nil then

            -- Raycast hit.
            if hit then
                local hitShapeTr = GetShapeWorldTransform(hitShape)
                SpawnFire(hitShapeTr.pos)
                -- DebugLine(rcTr.pos, hitShapeTr.pos, 1, 0, 0, 1)
            end

            -- Player hit by fire.
            if playerNearNozzle then
                local playerHealthHit = GetPlayerHealth() - playerDamageAmt
                SetPlayerHealth(playerHealthHit)
            end

            -- Spawn fire particle.
            SpawnParticle("fire", rcTr.pos, Vec(0,1,0), 2, 2, 2)
            PlayLoop(loops.nozzle, rcTr.pos, 2)
        end

    end
end



-- [[UTILITY]]
function raycastFromTransform(tr, distance, rad, rejectBody)
    local plyTransform = tr
    local fwdPos = TransformToParentPoint(plyTransform, Vec(0, 0, -distance or -300))
    local direction = VecSub(fwdPos, plyTransform.pos)
    local dist = VecLength(direction)
    direction = VecNormalize(direction)
    QueryRejectBody(rejectBody)
    local hit, dist, norm, shape = QueryRaycast(tr.pos, direction, dist, rad or 0)
    if hit then
        local hitPos = TransformToParentPoint(plyTransform, Vec(0, 0, dist * -1))
        return hit, hitPos, shape
    end
    return nil
end
function VecDist(vec1, vec2) return VecLength(VecSub(vec1, vec2)) end