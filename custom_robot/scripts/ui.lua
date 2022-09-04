------------------------------------------------------------------------------------------------
-- Please don't judge this code too heavily. It is a bit of a hack job but it works :)
------------------------------------------------------------------------------------------------

function initUi()
    UI_OPTIONS = false

    font_normal = 24
    font_heading = 42

    checkRegInitialized()
end

function uiDrawOptions()

    local w = UiWidth()
    local h = UiHeight()

    do UiPush()

        UiColor(1,1,1, 1)
        UiFont('bold.ttf', 24)
        UiAlign('center middle')

        marginYSize = 50
        local marginY = 0


        UiTranslate(UiCenter()/1.35, 50)

        do UiPush()

            ui.slider.create('Bullets RPM', 'robot.weapon.bullet.rpm', 'RPM', 300, 2400)
            UiTranslate(0, marginYSize)
            marginY = marginY + marginYSize

            ui.slider.create('Bullet Hole Size', 'robot.weapon.bullet.holeSize', 'meters', 0.1, 4)
            UiTranslate(0, marginYSize)
            marginY = marginY + marginYSize

            ui.slider.create('Rockets RPM', 'robot.weapon.rocket.rpm', 'RPM', 60, 800)
            UiTranslate(0, marginYSize)
            marginY = marginY + marginYSize

            ui.slider.create('Rocket Explosion Size', 'robot.weapon.rocket.explosionSize', 'meters', 0.5, 4)
            UiTranslate(0, marginYSize)
            marginY = marginY + marginYSize

            ui.slider.create('Robot Speed', 'robot.move.speed', '', 0.5, 10)
            UiTranslate(0, marginYSize)
            marginY = marginY + marginYSize

        UiPop() end

        do UiPush()

            UiTranslate(-200, 0)

            -- Bullet presets
            do
                UiText('Bullet Presets')
                UiTranslate(0, 48)

                UiImageBox("ui/common/box-outline-fill-6.png", 150, 50, 10, 10)
                if UiTextButton('Balanced') then
                    regSetFloat('robot.weapon.bullet.rpm', 800)
                    regSetFloat('robot.weapon.bullet.holeSize', 0.5)
                end
                UiTranslate(0, 64)

                UiImageBox("ui/common/box-outline-fill-6.png", 150, 50, 10, 10)
                if UiTextButton('Shredder') then
                    regSetFloat('robot.weapon.bullet.rpm', 2400)
                    regSetFloat('robot.weapon.bullet.holeSize', 0.75)
                end
                UiTranslate(0, 64)

                UiImageBox("ui/common/box-outline-fill-6.png", 150, 50, 10, 10)
                if UiTextButton('Dissolver') then
                    regSetFloat('robot.weapon.bullet.rpm', 400)
                    regSetFloat('robot.weapon.bullet.holeSize', 4)
                end
                UiTranslate(0, 64)

            end

            do
                -- ui.checkBox.create('Follow Player', 'robot.followPlayer')
            end

        UiPop() end


        do UiPush()

            UiTranslate(-UiCenter()/1.28, 0)

            local resetW = 200
            local closeW = 80
            local wAlign = (resetW + closeW) / 2

            UiTranslate(UiCenter()-wAlign/2, marginY + 150)

            UiAlign('center middle')
            UiImageBox("ui/common/box-outline-fill-6.png", closeW, 50, 10, 10)
            if UiTextButton('Close') then
                UI_OPTIONS = not UI_OPTIONS
            end

            UiTranslate(resetW/2 + closeW/2 + 10, 0)

            UiImageBox("ui/common/box-outline-fill-6.png", resetW, 50, 10, 10)
            if UiTextButton('Reset Robot Values') then
                modReset()
            end


        UiPop() end

    UiPop() end

end

--- Manage when to open and close the options menu.
function uiManageGameOptions()

    if player.isDrivingRobot and robot.model == robot_models.basic then

        if InputPressed('o') then UI_OPTIONS = not UI_OPTIONS end

        if UI_OPTIONS then
            UiMakeInteractive()
            uiDrawOptions()
        end

    end

end
