robot_models = {
    aeon = 'aeon',
    basic = 'basic',
}


function initRobotPreset()

    local robot_model = GetTagValue(robot.body, 'model')
    robotObject = createRobotObject(robot_model)
    setRobotCrosshairScale()

end


function createRobotObject(robot_model)


    robot.model = robot_model
    robot.crosshair = '../img/crosshair_' .. robot.model .. '.png'

    setWeaponLocations(robot)

end


function setWeaponLocations(robot)

    local lights_weap_primary = FindLights('weap_primary')
    local lights_weap_secondary = FindLights('weap_secondary')
    local lights_weap_special = FindLights('weap_special')


    local weaponObjects = {
        primary = {},
        secondary = {},
        special = {},
    }


    for key, light in pairs(lights_weap_primary) do

        local lightObj = getLightObject(light)
        lightObj.lightLocalPos = TransformToLocalPoint(GetBodyTransform(lightObj.body), lightObj.tr) -- Light pos rel to body.

        table.insert(weaponObjects.primary, lightObj)

    end

    for key, light in pairs(lights_weap_secondary) do

        local lightObj = getLightObject(light)
        lightObj.lightLocalPos = TransformToLocalPoint(GetBodyTransform(lightObj.body), lightObj.tr) -- Light pos rel to body.

        table.insert(weaponObjects.secondary, lightObj)

    end

    for key, light in pairs(lights_weap_special) do

        local lightObj = getLightObject(light)
        lightObj.lightLocalPos = TransformToLocalPoint(GetBodyTransform(lightObj.body), lightObj.tr) -- Light pos rel to body.

        table.insert(weaponObjects.special, lightObj)

    end


    robot.weaponObjects = weaponObjects

end

--- Returns the light, its shape and body.
function getLightObject(light)

    local l = {}

    l.light = light
    l.shape = GetLightShape(light)
    l.body = GetShapeBody(l.shape)
    l.tr = GetLightTransform(light)
    l.relPos = TransformToLocalPoint(GetBodyTransform(l.body), l.tr)

    return l

end


function setRobotCrosshairScale()

    if robot.model == robot_models.aeon then
        robot.crosshairScale = 1
    else
        robot.crosshairScale = 1
    end

end