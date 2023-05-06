g_WeaponKnockback = {
    m249 = {350.0,250.0,300.0,100.0,0.0},
    mag7 = {350.0,250.0,300.0,100.0,0.0},
    negev = {350.0,250.0,300.0,100.0,0.0},
    nova = {1800.0,480.0,900.0,600.0,0.0},
    sawedoff = {700.0,450.0,600.0,450.0,0.0},
    xm1014 = {700.0,450.0,600.0,450.0,0.0},

    hkp2000 = {85.0,100.0,100.0,80.0,0.0},
    usp_silencer = {85.0,100.0,100.0,80.0,0.0},
    glock = {85.0,100.0,100.0,80.0,0.0},
    p250 = {85.0,100.0,100.0,80.0,0.0},
    deagle = {350.0,250.0,350.0,100.0,0.0},
    fiveseven = {85.0,100.0,100.0,80.0,0.0},
    elite = {85.0,100.0,100.0,80.0,0.0},
    tec9 = {85.0,100.0,100.0,80.0,0.0},
    revolver = {350.0,250.0,350.0,100.0,0.0},

    ak47 = {350.0,250.0,200.0,100.0,0.0},
    aug = {350.0,250.0,300.0,100.0,0.0},
    awp = {5000.0,500.0,1200.0,800.0,0.0},
    famas = {350.0,250.0,300.0,100.0,0.0},
    g3sg1 = {400.0,400.0,400.0,200.0,0.0},
    galilar = {350.0,250.0,300.0,100.0,0.0},
    m4a1 = {350.0,250.0,300.0,100.0,0.0},
    m4a1_silencer = {350.0,250.0,300.0,100.0,0.0},
    scar20 = {450.0,400.0,400.0,200.0,0.0},
    sg556 = {350.0,250.0,300.0,100.0,0.0},
    ssg08 = {3000.0,500.0,1200.0,800.0,0.0},

    mp7 = {250.0,200.0,250.0,90.0,0.0},
    mp9 = {250.0,200.0,250.0,90.0,0.0},
    mac10 = {250.0,200.0,250.0,90.0,0.0},
    mp5sd = {250.0,200.0,250.0,90.0,0.0},
    ump45 = {250.0,200.0,250.0,90.0,0.0},
    bizon = {250.0,200.0,250.0,90.0,0.0},
    p90 = {250.0,200.0,250.0,90.0,0.7}
}

local cjson = require("cjson")

function Knockback_Init()
    local str = FS_LoadFileForMe("scripts/vscripts/config/KnockbackDesc.json")
    local j = cjson.decode(str)
    for _, data in ipairs(j[2].KnockbackDesc) do
        g_WeaponKnockback[data.m_szWeaponName] = { data.m_flGround, data.m_flAir, data.m_flFly, data.m_flDuck, data.m_flVelocityModifier }
        print(string.format("update knockback data for %s = {%s,%s,%s,%s}", data.m_szWeaponName, data.m_flGround, data.m_flAir, data.m_flFly, data.m_flDuck, data.m_flVelocityModifier))
    end
    return g_WeaponKnockback
end

--[[
function Knockback_Init()
    local config = require("config/KnockbackDesc")
    if config then
        for _, data in ipairs(config.KnockbackDesc) do
            g_WeaponKnockback[data.m_szWeaponName] = { data.m_flGround, data.m_flAir, data.m_flFly, data.m_flDuck, data.m_flVelocityModifier }
            print(string.format("update knockback data for %s = {%s,%s,%s,%s}", data.m_szWeaponName, data.m_flGround, data.m_flAir, data.m_flFly, data.m_flDuck, data.m_flVelocityModifier))
        end
    end
    return g_WeaponKnockback
end
]]
function Knockback_Apply(hHuman, hZombie, iDamage, sWeapon)
    local iScale = 1

    local knockback_config = g_WeaponKnockback[sWeapon]
    if knockback_config then
        local zombie_vel = hZombie:GetVelocity()

        if zombie_vel.z == 0 then
            if zombie_vel.x * zombie_vel.x + zombie_vel.y * zombie_vel.y > 140 then
                -- flying
                iScale = iScale * (knockback_config[3] or 0)
            else
                -- jumping
                iScale = iScale * (knockback_config[2] or 0)
            end
        else
            if bit.band(hZombie:Attribute_GetIntValue('buttons', -1), IN_DUCK)  then
                -- duck
                iScale = iScale * (knockback_config[4] or 0)
            else
                -- on ground
                iScale = iScale * (knockback_config[1] or 0)
            end
        end
    end

    local vecAttackerAngle = AnglesToVector(hHuman:EyeAngles())
    vecAttackerAngle = Vector(vecAttackerAngle.x, vecAttackerAngle.y, 0):Normalized()
    local vecKnockback = vecAttackerAngle * iScale
    hZombie:ApplyAbsVelocityImpulse(vecKnockback)
end

tRecordedGrenadePosition = {}
function Knockback_OnGrenadeDetonate(event)
    --__DumpScope(0, event)
    local hThrower = EHandleToHScript(event.userid_pawn)
    local vecDetonatePosition = Vector(event.x, event.y, event.z)
    tRecordedGrenadePosition[hThrower] = vecDetonatePosition
end

tRecordedMolotovPosition = {}
function Knockback_OnMolotovDetonate(event)
    --__DumpScope(0, event)
    local hThrower = EHandleToHScript(event.userid_pawn)
    local vecDetonatePosition = Vector(event.x, event.y, event.z)
    tRecordedMolotovPosition[hThrower] = vecDetonatePosition
end
