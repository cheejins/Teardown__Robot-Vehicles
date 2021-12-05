function init()

    menu = {

        isShowing = true,

        map = {
            campaign = false,
            sandbox = false,
        },

    }


    ui = {
        text = {
            size = {
                s = 12,
                m = 24,
                l = 48,
            },
        },
        container = {
            width = 1440,
            height = 240,
        },
        padding = 25,
        colors = {
            text = 1,
            fg = 0.3,
            bg = 0.12,
        },
        grid = {
            createNewRow = function ()
                UiTranslate(-580, 150)
            end,
            insertColPadding = function ()
                UiTranslate(20, 0)
            end,
        }
    }

end


function tick()
    UiMakeInteractive()

    if menu.map.campaign then
        StartLevel('', "MOD/testLevel.xml")
    elseif menu.map.sandbox then
        StartLevel('', "MOD/miniCity.xml")
    end
end


function draw()
    drawBackground()
    drawHeader()
    drawMenu()
end


function drawMenu()

    -- CAMPAIGN
    UiPush()

        local contW = 700
        local contH = 700

        UiPush() -- container bg
            local c = ui.colors.bg
            UiColor(c, c, c, 1)
            UiRect(contW, contH)
        UiPop()

        UiPush()
            UiTranslate(contW/2, 15)
            UiAlign('center top')
            UiFont("bold.ttf", ui.text.size.l)
            local c = ui.colors.text
            UiColor(c, c, c, 1)
            UiText('Test Level')
        UiPop()

        -- Image button
        UiColor(c, c, c, 1)
        UiTranslate(ui.padding, ui.padding + 50)
        menu.map.campaign = UiImageButton('MOD/menu/img/testLevel.png', contW, contH)

    UiPop()


    UiTranslate(740, 0)


    -- CAMPAIGN
    UiPush()

        local contW = 700
        local contH = 700

        UiPush() -- container bg
            local c = ui.colors.bg
            UiColor(c, c, c, 1)
            UiRect(contW, contH)
        UiPop()

        UiPush()
            UiTranslate(contW/2, 15)
            UiAlign('center top')
            UiFont("bold.ttf", ui.text.size.l)
            local c = ui.colors.text
            UiColor(c, c, c, 1)
            UiText('(another map)')
        UiPop()

        -- Image button
        UiColor(c, c, c, 1)
        UiTranslate(ui.padding, ui.padding + 50)
        menu.map.sandbox = UiImageButton('MOD/menu/img/sandbox.png', contW, contH)

    UiPop()

end


function drawBackground()
    UiColor(0,0,0,1)
    UiRect(UiWidth(),UiHeight())
end


function drawHeader()
    UiTranslate(240, 45)
    UiPush()
        UiColor(1, 1, 1)
        UiFont("bold.ttf", ui.text.size.l)

        UiPush()
            local c = ui.colors.bg
            UiColor(c,c,c,1)
            local bounds = {1440, 170}
            UiRect(bounds[1], bounds[2])
        UiPop()

        -- Image
        UiPush()
            UiTranslate(22.5, 22.5)
            UiImageBox("MOD/img/preview.png", 120, 120, 1, 1)
        UiPop()

        -- Title
        UiTranslate(160, 20)
        UiAlign("left top")
        UiFont("bold.ttf", ui.text.size.l * 2)
        UiText("Robot Vehicles (Early Beta)")

        -- Author
        UiTranslate(0, 80)
        UiFont("bold.ttf",  ui.text.size.l)
        UiText("By: Cheejins")
    UiPop()

    UiTranslate(0, 205)
end
