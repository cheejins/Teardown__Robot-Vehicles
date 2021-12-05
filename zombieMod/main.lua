#include "scripts/utility.lua"
#include "scripts/zombie.lua"
#include "scripts/zombieRadar.lua"
#include "scripts/info.lua"
#include "scripts/customWeapons.lua"
-- #include "mods/C Glock/main.lua"
-- #include 'mods/C M4A1/main.lua'
-- #include 'mods/C P90/main.lua'


-- ================================================================
-- Zombie AI - by: Cheejins
-- ================================================================

-- ----------------------------------------------------------------
-- This script ties together all of the other scripts.
-- ----------------------------------------------------------------



--[[INIT]]
function init()

    initOptionsMain()
    initGame()
    initMap()
    initBoids()

    initZombies() -- Init zombies last after all other values are set.
    initZombieController()

    -- initGlock18()
    -- initM4A1()
    -- initP90()


end



--[[TICK]]
function tick()

    -- Game..
    updateGameTable()

    -- Custom Weapons
    -- runGlock18()
    -- runM4A1()
    -- runP90()

    -- Zombies..
    manageZombies()
    manageMapTriggers()
    runZombieController()
    runZombieRadar()

    -- Map.
    -- disableTools()

    -- Debug.
    -- debugMod()

end

function draw()
    UiPush()
        runZombieRadar()
    UiPop()

    UiPush()
        drawInfoUi()
    UiPop()
end


--[[DEBUG]]
function debugMod()
    -- DebugWatch('#zombiesTable', #zombiesTable)
    for i = 1, #zombiesTable do
        local zombie = zombiesTable[i]
        -- DebugWatch("Zombie"..zombie.id.." state", zombie.ai.state)
    end
end
function debugZombie(zombie)
    local zTr = zombie:getTr()
    local fwdZ = Vec(0,0,-25)
    local revZ = Vec(0,0,25)
    local fwdPos = TransformToParentPoint(zTr, fwdZ)
    local revPos = TransformToParentPoint(zTr, revZ)
    -- DebugLine(zTr.pos, fwdPos, 1,1,0)
    -- DebugLine(zTr.pos, revPos, 1,1,0)
end



--[[GAME]]
function updateGameTable()
    game.ppos = VecAdd(GetPlayerPos(), Vec(0,1,0))
    game.playerAabb.min = VecAdd(game.ppos, Vec(game.playerAabb.minAdd))
    game.playerAabb.max = VecAdd(game.ppos, Vec(game.playerAabb.maxAdd))
end
function initGame()
    colors = getColors()

    game = {
        playerPos = GetPlayerPos(),
        playerAabb = {
            minAdd = Vec(-2,0,-2),
            maxAdd = Vec(2,2,2),
            min = Vec(-2,0,-2),
            max = Vec(2,2,2),
        },
    }

    sounds = {
        deaths = {
            LoadSound("MOD/zombieMod/snd/deaths/death1.ogg"),
        },

        hits = {
            LoadSound("MOD/zombieMod/snd/hits/hits1.ogg"),
            LoadSound("MOD/zombieMod/snd/hits/hits2.ogg"),
            LoadSound("MOD/zombieMod/snd/hits/hits3.ogg"),
            LoadSound("MOD/zombieMod/snd/hits/hits4.ogg"),
        },

        growls = {
            LoadSound("MOD/zombieMod/snd/growls/growl1.ogg"),
            LoadSound("MOD/zombieMod/snd/growls/growl2.ogg"),
            LoadSound("MOD/zombieMod/snd/growls/growl3.ogg"),
            LoadSound("MOD/zombieMod/snd/growls/growl4.ogg"),
        },

        damage = {
            LoadSound("MOD/zombieMod/snd/damage/damage1.ogg"),
            LoadSound("MOD/zombieMod/snd/damage/damage2.ogg"),
            LoadSound("MOD/zombieMod/snd/damage/damage3.ogg"),
        }
    }

    sounds.play = {
        damage = function (zombie, vol)
            sounds.playRandom(zombie, sounds.damage, vol or 2)
        end,

        death = function(zombie, vol)
            sounds.playRandom(zombie, sounds.deaths, vol or 1)
        end,

        growl = function (zombie, vol)
            sounds.playRandom(zombie, sounds.growls, vol or 2)
        end,

        hit = function(zombie, vol)
            sounds.playRandom(zombie, sounds.hits, vol or 1.5)
        end,
    }

    sounds.playRandom = function(zombie, soundsTable, vol)
        local p = math.floor(soundsTable[rdm(1, #soundsTable)])
        PlaySound(p, zombie.getPos(), vol or 1)
        -- DebugWatch('hit sound', p)
    end

end
function initOptionsMain()
    if GetBool('savegame.mod.options.init') == false then

        SetString('savegame.mod.zombieRadar.corner', 'tr')
        SetBool('savegame.mod.options.outline', true)
        -- SetBool('savegame.mod.options.customWeapons', true)

        SetBool('savegame.mod.options.init', true)
    end
end


--[[MAP]]
-- Zombies can be activated by triggers. Make sure the trigger has the tag trigger with a value of whatever you'd like. ex: trig=start, trig=forest
function initMap()
    SCRIPTED_MAP = false
    map = {
        triggers = {
            refs = {},
            names = {},
            activated = {},
        },
    }
    if FindLocation("ai_zombie_map", true) ~= 0 then
        SCRIPTED_MAP = true
        -- DebugPrint("Map is scripted ai zombie map...")
        initTriggers()
    end
end
function initTriggers()
    map.triggers.refs = FindTriggers("trig", true)
    for i = 1, #map.triggers.refs do

        local trigger = map.triggers.refs[i]
        local tagVal = GetTagValue(trigger, "trig")

        map.triggers.names[tagVal] = tagVal
        map.triggers.refs[tagVal] = trigger
        map.triggers.activated[i] = 0

        -- DebugPrint("activated: " .. map.triggers.activated[i])
        -- DebugPrint("trigger: " .. map.triggers.names[tagVal])
    end
end
function manageMapTriggers()
    for i = 1, #map.triggers.refs do
        if map.triggers.activated[i] == 0 then -- Activate trigger once only.
            for j = 1, #zombiesTable do
                if zombiesTable[j].ai.isActive == false then
                    if IsBodyInTrigger(map.triggers.refs[i], zombiesTable[j].body) 
                    and IsPointInTrigger(map.triggers.refs[i], game.ppos) then
                        zombiesTable[j].ai.isActive = true -- Activate ai in trigger zone.
                        map.triggers.activated[i] = 1 -- Activate trigger zone.
                    end
                end
            end
        end
    end
end
function disableTools(pickedUpTools)
    local toolNames = {sledge = 'sledge', spraycan = 'spraycan', extinguisher ='extinguisher', blowtorch = 'blowtorch'}
    local tools = ListKeys("game.tool")
    for i=1, #tools do
        if tools[i] == toolNames[tools[i]] then
            SetBool("game.tool."..tools[i]..".enabled", false)
        end
    end
end