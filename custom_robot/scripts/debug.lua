function initDebug()
    db = false
    -- db = true
end

function dbw(str, value) if db then DebugWatch(str, value) end end
function dbp(str, newLine) if db then DebugPrint(str .. ternary(newLine, '\n', '')) print(str .. ternary(newLine, '\n', '')) end end
function dbl(p1, p2, c1, c2, c3, a) if db then DebugLine(p1, p2, c1, c2, c3, a) end end
function dbdd(pos,w,l,r,g,b,a,dt) DrawDot(pos,w,l,r,g,b,a,dt) end

--[[DEBUG 3D]]
function dbl(p1, p2, r,g,b,a, dt) if db then DebugLine(p1, p2, r,g,b,a, dt) end end -- DebugLine()
function dbdd(pos, w,l, r,g,b,a, dt) if db then DrawDot(pos,w,l,r,g,b,a,dt) end end -- Draw a dot sprite at the specified position.
function dbray(tr, dist, r,g,b,a) dbl(tr.pos, TransformToParentPoint(tr, Vec(0,0,-dist)), r, g, b, a) end -- Debug a ray segement from a transform.
function dbcr(pos, r,g,b, a) if db then DebugCross(pos, r or 1, g or 1, b or 1, a or 1) end end -- DebugCross() at a specified position.
