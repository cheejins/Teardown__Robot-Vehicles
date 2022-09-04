#include "custom_robot/scripts/registry.lua"
#include "custom_robot/scripts/utility.lua"


function init()

    checkRegInitialized()

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

        -- Version warning.
        if HasVersion("0.9.3") then

            ui_createToggleSwitch('Enable keybind spawning.', 'spawningKeysEnabled', font_size)

            if regGetBool('spawningKeysEnabled') then

                UiTranslate(0, font_size*2.5)
                Ui_Option_Keybind('Spawn Basic Robot', 'options.keys.spawnMenu')

                UiTranslate(0, font_size*2.5)
                Ui_Option_Keybind('Spawn Aeon Robot', 'options.keys.quickSpawn')

            end


        else

            do UiPush()

                UiColor(1,0,0,1)
                UiAlign('center middle')
                UiFont('regular.ttf', font_size)
                UiTranslate(0, font_size*2)

                UiText('Spawning unavailable!')
                UiTranslate(0, font_size*1.5)

                UiText('Please switch to the Teardown experimental beta in Steam to enable spawning.')


            UiPop() end

        end


    UiPop() end


    do UiPush()

        UiTranslate(0, -100)

        UiTranslate(0, UiHeight() - font_size*2.5)
        UiAlign('center middle')
        UiButtonImageBox("ui/common/box-outline-6.png", 10,10)
        UiButtonHoverColor(0.5,0.5,1,1)
        if UiTextButton('Reset Options', 200, font_size*2) then
            optionsReset()
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


function ui_createToggleSwitch(title, registryPath, fontSize)

    do UiPush()

        local value = GetBool('savegame.mod.' .. registryPath)

        UiAlign('right middle')

        -- Text header
        UiColor(1,1,1, 1)
        UiFont('regular.ttf', fontSize)
        UiText(title)
        UiTranslate(font_size, -fontSize/2)


        -- Toggle BG
        UiAlign('left top')
        UiColor(0.4,0.4,0.4, 1)
        local tglW = 130
        local tglH = 40
        UiRect(tglW, tglH)

        -- Render toggle
        do UiPush()

            local toggleText = 'ON'

            if value then
                UiTranslate(tglW/2, 0)
                UiColor(0,0.8,0, 1)
            else
                toggleText = 'OFF'
                UiColor(0.8,0,0, 1)
            end

            UiRect(tglW/2, tglH)

            do UiPush()
                UiTranslate(tglW/4, tglH/2)
                UiColor(1,1,1, 1)
                UiFont('bold.ttf', fontSize)
                UiAlign('center middle')
                UiText(toggleText)
            UiPop() end

        UiPop() end

        UiButtonImageBox('ui/common/box-outline-6.png', 10,10, 0,0,0, a)
        if UiBlankButton(tglW, tglH) then
            SetBool('savegame.mod.' .. registryPath, not value)
            PlaySound(LoadSound('clickdown.ogg'), GetCameraTransform().pos, 1)
        end

    UiPop() end

end