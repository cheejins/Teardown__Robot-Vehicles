function initSounds()
    Sounds = {

        weap_secondary = {

            shoot = {
                LoadSound('MOD/custom_robot/sounds/aeon/weap_secondary1.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_secondary2.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_secondary3.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_secondary4.ogg'),
            },

            hit = {
                LoadSound('MOD/custom_robot/sounds/aeon/weap_secondary_hit1.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_secondary_hit2.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_secondary_hit3.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_secondary_hit4.ogg'),
            }
        },

        weap_special = {

            shoot = {
                LoadSound('MOD/custom_robot/sounds/aeon/weap_special1.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_special2.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_special3.ogg'),
            },

            hit = {
                LoadSound('MOD/custom_robot/sounds/aeon/weap_special_hit1.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_special_hit2.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_special_hit3.ogg'),
                LoadSound('MOD/custom_robot/sounds/aeon/weap_special_hit4.ogg'),
            }
        }

    }
end


function PlayRandomSound(soundTable, pos, vol, index_override)
    local p = index_override or soundTable[math.random(1, #soundTable)]
    PlaySound(p, pos, vol or 1)
end
