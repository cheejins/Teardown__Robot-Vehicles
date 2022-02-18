function modReset()

    regSetString('version'                           , GetModVersion())

    regSetFloat('robot.weapon.bullet.rpm'           , 800)
    regSetFloat('robot.weapon.bullet.holeSize'      , 0.5)

    regSetFloat('robot.weapon.rocket.rpm'           , 160)
    regSetFloat('robot.weapon.rocket.explosionSize' , 1.5)

    regSetFloat('robot.move.speed'                  , 1)

    -- regSetBool('robot.followPlayer'                 , false)
end

function checkRegInitialized()
    local regInit = regSetBool('regInit')
    if regInit == false or GetModVersion() ~= regGetString('version') then

        local version = GetModVersion()
        local regVersion = regGetString('version')

        if version ~= regVersion then
            print('> Mod updated from ' .. regGetString('version') .. ' to ' .. GetModVersion())
            regSetString('version', GetModVersion())
        end

        regSetBool('regInit', true)
        modReset()
        print('> Mod options reset ')

    end
end

function regGetFloat(path)
    local p = 'savegame.mod.' .. path
    return GetFloat(p)
end
function regSetFloat(path, value)
    local p = 'savegame.mod.' .. path
    SetFloat(p, value)
end
function regGetBool(path)
    local p = 'savegame.mod.' .. path
    return GetBool(p)
end
function regSetBool(path, value)
    local p = 'savegame.mod.' .. path
    SetBool(p, value)
end
function regGetString(path)
    local p = 'savegame.mod.' .. path
    return GetString(p)
end
function regSetString(path, value)
    local p = 'savegame.mod.' .. path
    SetString(p, value)
end