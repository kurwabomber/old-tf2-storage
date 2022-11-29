/**
* File: War3Source_CustomRace_TF2Heavy.sp
* Description: The Heavy form TF2 War3source Race .
* Author(s): Fallen (aka; Fallen Shadow65),Scruffy (aka; Corrupted ).
*Last Editeded:18/09/2011
*Last Edited by: Fallen
*Version:1.0
*/
#pragma semicolon 1
#include <sourcemod> 
#include "W3SIncs/War3Source_Interface"


new thisRaceID;

new Float:f_Grav[5] = { 1.0, 0.80, 0.75, 0.7, 0.6 };
new m_Health[5] = { 100, 50, 100, 150, 200};
new Float:f_ArmorMult[5] = { 1.0, 0.1, 0.2, 0.3, 0.4 };
new m_Armor[5] = { 0, 25, 50, 75, 100};
new m_EatHP [5] = { 0, 100, 150, 200, 250};
new Float:f_Speed [5] = {0.95, 0.95, 0.9 ,0.85 ,0.8 };

new SKILL_LOWGRAV, SKILL_HEALTH, SKILL_ARMOR, ULT_EAT;

public Plugin:myinfo =
{
        name = "War3Source Race -TF2 Heavy",
        author = "Fallen",
        description = "TF2 Heavy",
        version = "1.0.1",
        url = "www.SevenSinsGaming.com",
};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("TF2 Heavy","Heavy");
    SKILL_LOWGRAV=War3_AddRaceSkill(thisRaceID,"Low Grav(passive)","Grants you Low Grav",false);
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Health (passive)","Grants more HP but you lose speed",false);
    SKILL_ARMOR=War3_AddRaceSkill(thisRaceID,"Tank (passive)","Grants and steals Armor",false);
    ULT_EAT=War3_AddRaceSkill(thisRaceID,"Ultimate: Eat","Eats some food to heal",false); 
    War3_CreateRaceEnd(thisRaceID);
}

public OnRaceChanged( client, oldrace, newrace )
{
    if( newrace != thisRaceID)
    {
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3ResetAllBuffRace( client, thisRaceID );
    }
    else
    {
        if(ValidPlayer(client, true))
        {
            InitPassiveSkills(client);
        }
    }
}

public InitPassiveSkills ( client )
{

    War3_SetBuff( client, fSlow, thisRaceID,f_Speed[War3_GetSkillLevel(client,thisRaceID,SKILL_HEALTH)]);
    War3_SetBuff( client, fLowGravitySkill, thisRaceID, f_Grav[War3_GetSkillLevel( client, thisRaceID, SKILL_LOWGRAV )] );
    new skill_health=War3_GetSkillLevel(client, thisRaceID, SKILL_HEALTH);
    GivePlayerItem(client, "weapon_m249");//GiveMG
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_m249");
    
    if(skill_health >0)
    {
        War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,m_Health [skill_health]);        

    }
    new skill_armor=War3_GetSkillLevel(client, thisRaceID, SKILL_ARMOR);
    if(skill_armor >0)
    {
        War3_SetCSArmor(client, m_Armor[skill_armor]);
    }
}

public OnWar3EventSpawn(client)
{
    if(ValidPlayer(client, true))
    {
        if(War3_GetRace(client)==thisRaceID)
        {
            InitPassiveSkills(client);

        }
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(W3GetDamageIsBullet()&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
        new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_ARMOR);
        if(skill_level>0&&!Hexed(victim,false))
        {
            if(!W3HasImmunity(attacker,Immunity_Skills))
            {
                new armor=War3_GetCSArmor(victim);
                new armor_add=RoundToFloor(damage*f_ArmorMult[skill_level]);
                if(armor_add>20)
                {
                    armor_add=20;
                    War3_SetCSArmor(victim,armor+armor_add);
                }
            }
        }
        
    }
}

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_EAT );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_EAT, true ) )
            {
                War3_HealToBuffHP( client, m_EatHP[ult_level] );
                War3_CooldownMGR( client, 60.0, thisRaceID, ULT_EAT);
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}