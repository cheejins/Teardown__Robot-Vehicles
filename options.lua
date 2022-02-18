#include "ROBOT_VEHICLE_PREFAB/scripts/registry.lua"
#include "ROBOT_VEHICLE_PREFAB/scripts/utility.lua"


function init()

    activeAssignment = false
    activePath = '.'
    lastKeyPressed = '.'

    font_size = 32

end

function tick()

    manageKeyAssignment()

    -- DebugWatch('reg val', regGetString('options.keys.spawnMenu'))
    -- DebugWatch('InputLastPressedKey', lastKeyPressed)
    -- DebugWatch('activeAssignment', activeAssignment)
    -- DebugWatch('activePath', activePath)
    -- DebugWatch('oscillate(GetTime())', oscillate(GetTime()))

end

function manageKeyAssignment()

    if activeAssignment and InputLastPressedKey() ~= '' then

        regSetString(activePath, string.lower(InputLastPressedKey()))
        activeAssignment = false
        activePath = ''

    end

end


function draw()

    UiColor(1,1,1,1)
    UiFont('regular.ttf', font_size)
    UiTranslate(UiCenter(), 0)

    do UiPush()

        UiTranslate(0, font_size)
        do UiPush()
            UiFont('regular.ttf', 64)
            UiAlign('center top')
            UiText('Robot Vehicles Options')
        UiPop() end

        UiTranslate(0, 200)

        do UiPush()

            local c = oscillate(2)/3 + 2/3
            UiColor(c,c,1,1)
            UiAlign('center middle')
            UiFont('regular.ttf', font_size*1.5)

            UiButtonImageBox("ui/common/box-outline-6.png", 10,10)
            UiButtonHoverColor(0.5,0.5,1,1)
            if UiTextButton('Start Demo Map', 350, font_size*2.5) then
                StartLevel('', 'demo.xml', '')
            end

        UiPop() end

        UiTranslate(0, 200)

        UiTranslate(0, font_size*2.5)
        Ui_Option_Keybind('Spawn Basic Robot', 'options.keys.spawnMenu')
        -- Ui_Option_Keybind('Open spawn menu', 'options.keys.spawnMenu')

        UiTranslate(0, font_size*2.5)
        Ui_Option_Keybind('Spawn Aeon Robot', 'options.keys.quickSpawn')
        -- Ui_Option_Keybind('Spawn robot', 'options.keys.quickSpawn')

    UiPop() end


    do UiPush()

        UiTranslate(0, -100)

        UiTranslate(0, UiHeight() - font_size*2.5)
        UiAlign('center middle')
        UiButtonImageBox("ui/common/box-outline-6.png", 10,10)
        UiButtonHoverColor(0.5,0.5,1,1)
        if UiTextButton('Reset Mod', 200, font_size*2) then
            modReset()
        end

        UiTranslate(0, font_size*2.5)
        UiAlign('center middle')
        UiButtonImageBox("ui/common/box-outline-6.png", 10,10)
        UiButtonHoverColor(0.5,0.5,1,1)
        if UiTextButton('Close', 150, font_size*2) then
            Menu()
        end

    UiPop() end

end


function Ui_Option_Keybind(label, regPath)

    do UiPush()

        -- Label
        UiFont('regular.ttf', font_size)
        UiAlign('right middle')
        UiTranslate(0, font_size)
        UiText(label)

        -- Bind button
        UiTranslate(font_size, 0)
        UiAlign('left middle')
        UiButtonImageBox("ui/common/box-outline-6.png", 10,10)
        UiButtonHoverColor(0.5,0.5,1,1)

        if UiTextButton(regGetString(regPath), font_size*6, font_size*2) then

            if not activeAssignment then
                regSetString(regPath, 'Press key...')
                activeAssignment = true
                activePath = regPath
            end

        end

    UiPop() end

end
