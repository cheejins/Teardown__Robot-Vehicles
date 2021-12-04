function init()
	unlimitedammo = GetBool("savegame.mod.unlimitedammo")
	if unlimitedammo == 0 then unlimitedammo = 0.15 end
end

function draw()
	UiTranslate(UiCenter(), 350)
	UiAlign("center middle")

	UiFont("bold.ttf", 48)
	UiText("P90")
	UiFont("regular.ttf", 26)
	UiTranslate(0, 70)
	UiPush()
		UiText("Unlimited Ammo")
		UiTranslate(15, 40)
		UiAlign("right")
		UiColor(0.5, 0.8, 1)
		if unlimitedammo then
			if UiTextButton("Yes", 20, 20) then
				unlimitedammo = false
				SetBool("savegame.mod.unlimitedammo", unlimitedammo)
			end
		else
			if UiTextButton("No", 20, 20) then
				unlimitedammo = true
				SetBool("savegame.mod.unlimitedammo", unlimitedammo)
			end
		end
	UiPop()

	UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)

	UiTranslate(0, 120)
	if UiTextButton("Close", 80, 40) then
		Menu()
	end
end

function optionsSlider(val, min, max)
	UiColor(0.2, 0.6, 1)
	UiPush()
		UiTranslate(0, -8)
		val = (val-min) / (max-min)
		local w = 195
		UiRect(w, 3)
		UiAlign("center middle")
		UiTranslate(-195, 1)
		val = UiSlider("ui/common/dot.png", "x", val*w, 0, w) / w
		val = round((val*(max-min)+min), 2)
	UiPop()
	return val
end

function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end