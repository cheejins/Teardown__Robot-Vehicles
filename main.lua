#include "ROBOT_VEHICLE_PREFAB/scripts/robot.lua"


function init()

    -- Check if map has has an existing robot.
    local robotBodies = FindBodies('robotVehicle', true)
    if #robotBodies >= 1 then
        SetBool('level.robotExists', true)
        dbp('Map includes existing robot.')
    end

end

function tick()
    manageRobotSpawning()
end

function manageRobotSpawning()

    -- Spawn mech-basic
    if InputPressed(regGetString('options.keys.spawnMenu')) then
        local hit, pos = RaycastFromTransform(GetCameraTransform())
        Spawn('MOD/ROBOT_VEHICLE_PREFAB/robot/mech-aeon.xml', Transform(pos))
        SetBool('level.robotExists', true)
    end

    -- Spawn mech-aeon
    if InputPressed(regGetString('options.keys.quickSpawn')) then
        local hit, pos = RaycastFromTransform(GetCameraTransform())
        Spawn('MOD/ROBOT_VEHICLE_PREFAB/instance_robotVehicle.xml', Transform(pos))
        SetBool('level.robotExists', true)
    end

end
