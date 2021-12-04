#include "scripts/utility.lua"
#include "scripts/zombie.lua"

-- ====================================================================================================
-- Basic Ai Zombies - by: Cheejins
-- ====================================================================================================

-- ----------------------------------------------------------------------------------------------------
-- This script handles the creation of a zombie instance.
-- ----------------------------------------------------------------------------------------------------


function initZombieController()
    zombieController = {active = false, pos = Vec(0,0,0),}

    RegisterTool('zombieController','Zombie Controller', 'MOD/vox/zombieController.vox')
    SetBool('game.tool.zombieController.enabled', true)
end


function runZombieController()

    if GetString('game.player.tool') == "zombieController" then -- using controller..

        if InputDown('rmb') then -- release target..

            -- DebugWatch('zombie controller','target reset')

            zombieController.isActive = false
            for i = 1, #zombiesTable do
                zombiesTable[i].ai.targetPos = game.ppos
            end

        elseif InputDown('lmb') or zombieController.isActive then -- setting target..

            -- DebugWatch('zombie controller','target active')

            zombieController.isActive = true

            if InputDown('lmb') then
                local camTr = GetCameraTransform()
                local hit, pos = raycastFromTransform(camTr)
                if hit then
                    for i = 1, #zombiesTable do
                        zombiesTable[i].ai.targetPos = pos
                        zombieController.pos = pos
                    end
                end
                -- DebugWatch('zombie controller','target set')
            end

        else
            for i = 1, #zombiesTable do
                zombiesTable[i].ai.targetPos = nil
            end
        end

    elseif zombieController.isActive == false then -- not using controller..
        for i = 1, #zombiesTable do
            zombiesTable[i].ai.targetPos = game.ppos
        end
    end

    zcLight()

end

function zcLight()
    if zombieController.isActive then -- Point light only when controller target active.
        PointLight(VecAdd(zombieController.pos, Vec(0,1,0)), 0, 1, 0, 3)
        DebugLine((zombieController.pos), VecAdd(zombieController.pos, Vec(0,10,0)), 0.5, 1, 0.5)
    end
end