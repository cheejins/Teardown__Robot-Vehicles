function init()
    maceHeadJoint = FindJoint('maceHeadJoint')
    maceHeadShape = FindShape('maceHead')
    maceLoop = LoadLoop('MOD/instances/contraptions/sounds/maceLoop.ogg')
end

function tick()
    SetJointMotor(maceHeadJoint, 30, 1000000)
    PlayLoop(maceLoop, GetShapeWorldTransform(maceHeadShape).pos, 2)
end
