--[[VECTORS]]
function CalcDist(vec1, vec2)
    return VecLength(VecSub(vec1, vec2))
end
function VecDiv(v, n)
    n = n or 1
    return Vec(v[1] / n, v[2] / n, v[3] / n)
end
function VecAddAll(vectorsTable)
    local v = Vec(0,0,0)
    for i = 1, #vectorsTable do
        VecAdd(v, vectorsTable[i])
    end
    return v
end
--- return number if not = 0, else return 0.00000001
function rdmVec(min, max)
    return Vec(rdm(min, max),rdm(min, max),rdm(min, max))
end
--- Prints quats or vectors. dec = decimal places. dec default = 3. title is optional.
function printVec(vec, dec, title)
    DebugPrint(
        (title or "") .. 
        "  " .. sfn(vec[1], dec or 2) ..
        "  " .. sfn(vec[2], dec or 2) ..
        "  " .. sfn(vec[3], dec or 2)
    )
end
--- Fully prints quats or vectors will all decimals. title is optional.
function printVecf(vec, title)
    DebugPrint(
        (title or "") .. 
        "  " .. sfn(vec[1]) ..
        "  " .. sfn(vec[2]) ..
        "  " .. sfn(vec[3])
    )
end
function particleLine(vec1, vec2, particle, density, thickness)
    local maxLength = 500 -- prevents infinite particle line crashing your game.
    local transform = Transform(vec1, QuatLookAt(vec1,vec2))
    for i=1, VecLength(VecSub(vec1, vec2))*(density or 1) do
        if i < maxLength then
            local fwdpos = TransformToParentPoint(transform, Vec(0,0,-i/(density or 1)))
            SpawnParticle(particle or "darksmoke", fwdpos, 1, 1 or thickness, 0.2, 0, 0)
        end
    end
end



--[[QUAT]]
function QuatLookDown(pos)
    return QuatLookAt(pos, VecAdd(pos, Vec(0, -1, 0)))
end



--[[AABB]]
function drawAabb(v1, v2, r, g, b, a)
    r = r or 1
    g = g or 1
    b = b or 1
    a = a or 1
    local x1 = v1[1]
    local y1 = v1[2]
    local z1 = v1[3]
    local x2 = v2[1]
    local y2 = v2[2]
    local z2 = v2[3]
    -- x lines top
    DebugLine(Vec(x1,y1,z1), Vec(x2,y1,z1), r, g, b, a)
    DebugLine(Vec(x1,y1,z2), Vec(x2,y1,z2), r, g, b, a)
    -- x lines bottom
    DebugLine(Vec(x1,y2,z1), Vec(x2,y2,z1), r, g, b, a)
    DebugLine(Vec(x1,y2,z2), Vec(x2,y2,z2), r, g, b, a)
    -- y lines
    DebugLine(Vec(x1,y1,z1), Vec(x1,y2,z1), r, g, b, a)
    DebugLine(Vec(x2,y1,z1), Vec(x2,y2,z1), r, g, b, a)
    DebugLine(Vec(x1,y1,z2), Vec(x1,y2,z2), r, g, b, a)
    DebugLine(Vec(x2,y1,z2), Vec(x2,y2,z2), r, g, b, a)
    -- z lines top
    DebugLine(Vec(x2,y1,z1), Vec(x2,y1,z2), r, g, b, a)
    DebugLine(Vec(x2,y2,z1), Vec(x2,y2,z2), r, g, b, a)
    -- z lines bottom
    DebugLine(Vec(x1,y1,z2), Vec(x1,y1,z1), r, g, b, a)
    DebugLine(Vec(x1,y2,z2), Vec(x1,y2,z1), r, g, b, a)
end
function checkAabbOverlap(aMin, aMax, bMin, bMax)
    return 
    (aMin[1] <= bMax[1] and aMax[1] >= bMin[1]) and
    (aMin[2] <= bMax[2] and aMax[2] >= bMin[2]) and
    (aMin[3] <= bMax[3] and aMax[3] >= bMin[3])
end
function aabbClosestEdge(pos, shape)

    local shapeAabbMin, shapeAabbMax = GetShapeBounds(shape)
    local bCenterY = VecLerp(shapeAabbMin, shapeAabbMax, 0.5)[2]
    local edges = {}
    edges[1] = Vec(shapeAabbMin[1], bCenterY, shapeAabbMin[3]) -- a
    edges[2] = Vec(shapeAabbMax[1], bCenterY, shapeAabbMin[3]) -- b
    edges[3] = Vec(shapeAabbMin[1], bCenterY, shapeAabbMax[3]) -- c
    edges[4] = Vec(shapeAabbMax[1], bCenterY, shapeAabbMax[3]) -- d

    local closestEdge = edges[1] -- find closest edge
    local index = 1
    for i = 1, #edges do
        local edge = edges[i]

        local edgeDist = CalcDist(pos, edge)
        local closesEdgeDist = CalcDist(pos, closestEdge)

        if edgeDist < closesEdgeDist then
            closestEdge = edge
            index = i
        end
    end
    return closestEdge, index
end
--- Sort edges by closest to startPos and closest to endPos. Return sorted table.
function sortAabbEdges(startPos, endPos, edges)

    local s, startIndex = aabbClosestEdge(startPos, edges)
    local e, endIndex = aabbClosestEdge(endPos, edges)

    -- Swap first index with startPos and last index with endPos. Everything between stays same.
    edges = tableSwapIndex(edges, 1, startIndex)
    edges = tableSwapIndex(edges, #edges, endIndex)

    return edges
end



--[[TABLES]]
function tableSwapIndex(t, i1, i2)
    local temp = t[i1]
    t[i1] = t[i2]
    t[i2] = temp
    return t
end


function raycastFromTransform(tr, distance, rad, rejectBody)

    local distance = distance
    if distance == nil then
        distance = -300
    else
        distance = -distance
    end

    local plyTransform = tr
    local fwdPos = TransformToParentPoint(plyTransform, Vec(0, 0, distance))
    local direction = VecSub(fwdPos, plyTransform.pos)
    local dist = VecLength(direction)
    direction = VecNormalize(direction)
    QueryRejectBody(rejectBody)
    local h, d, n, s = QueryRaycast(tr.pos, direction, dist, rad)
    if h then
        local hitPos = TransformToParentPoint(plyTransform, Vec(0, 0, d * -1))
        return h, hitPos, s
    else
        return nil
    end
end
function diminishBodyAngVel(body, rate)
    local angVel = GetBodyAngularVelocity(body)
    local dRate = rate or 0.99
    local diminishedAngVel = Vec(angVel[1]*dRate, angVel[2]*dRate, angVel[3]*dRate)
    SetBodyAngularVelocity(body, diminishedAngVel)
end


--[[VFX]]
function getColors()
    local colors = {
        white = Vec(1,1,1),
        black = Vec(0,0,0),
        grey = Vec(0,0,0),
        red = Vec(1,0,0),
        blue = Vec(0,0,1),
        yellow = Vec(1,1,0),
        purple = Vec(1,0,1),
        green = Vec(0,1,0),
        orange = Vec(1,0.5),
    }
    return colors
end

function DrawDot(pos, r, g, b)
    local dot = LoadSprite("ui/hud/dot-small.png")
    local spriteRot = QuatLookAt(pos, GetCameraTransform().pos)
    local spriteTr = Transform(pos, spriteRot)
    DrawSprite(dot, spriteTr, 0.2, 0.2, r or 1, g or 1, b or 1, 1)
end



--[[SFX]]
local debugSounds = {
    beep = LoadSound("warning-beep"),
    buzz = LoadSound("light/spark0"),
    chime = LoadSound("elevator-chime"),}
function beep(vol) PlaySound(debugSounds.beep, GetPlayerPos(), vol or 0.3) end
function buzz(vol) PlaySound(debugSounds.buzz, GetPlayerPos(), vol or 0.3) end
function chime(vol) PlaySound(debugSounds.chime, GetPlayerPos(), vol or 0.3) end

-- ---comment
-- ---@param path string Path to the folder of sounds.
-- ---@param baseWord string String of the sound without numbers. Ex: for sounds hit1, hit2, hit3, the base word is hit.
-- ---@return table
-- function GetAllSoundsFromFolder(path, baseWord)
--     local sounds = {}
--     local i = 1
--     while path..baseWord..tostring(i) ~= nil do
--         sounds[i] = 
--         i = i+1
--     end
--     return sounds
-- end



--[[MATH]]
function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end
--- return number if > 0, else return 0.00000001
function gtZero(val)
    if val <= 0 then
        return 0.0000001
    end
    return val
end
--- return number if not = 0, else return 0.00000001
function nZero(val)
    if val == 0 then return 0.0000001 end
    return val
end
--- return number if not = 0, else return 0.00000001
function rdm(min, max)
    return math.random(min or 0, max or 1)
end


--[[FORMATTING]]
--- string format. default 2 decimals.
function sfn(numberToFormat, dec)
    local s = (tostring(dec or 2))
    return string.format("%."..s.."f", numberToFormat)
end
function sfnTime(dec)
    return sfn(' '..GetTime(), dec or 4)
end