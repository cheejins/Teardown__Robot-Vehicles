local menu = {
    isShowing = false,
}

function drawInfoUi()

    if InputPressed('i') then
        menu.isShowing = not menu.isShowing
    end

    if menu.isShowing then

        UiMakeInteractive()

        UiTranslate(UiCenter(), UiMiddle())
        UiAlign("center middle")
        UiImageBox('MOD/img/info.png', 1449, 877, 1, 1)
    end

end