#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
 
public Plugin:myinfo =
{
    name = "War3Source - Race - Sacrificial Warrior",
    author = "Venia Mors",
    description = "The Sacrifical Warrior race for War3Source"
};
 
new thisRaceID;
 
new Float:VampirePercent[5] = {0.0, 0.08, 0.14, 0.20, 0.25};
new Float:SpeedIncrease[5] = {1.0, 1.05, 1.1, 1.15, 1.2};
new Float:Regeneration[5] = {0.0, 0.25, 0.5, 0.75, 1.0};
new Float:InvisibilityUltiDecay[5] = {0.0, 20.0, 15.0, 10.0, 5.0};
new Float:InvisibilitySkill[5] = {1.0, 0.0, 0.0, 0.0, 0.0};
 
new SKILL_LEECH, SKILL_SPEED, SKILL_REGEN, ULT_INVIS;
 
new bool:bInvisActivated[MAXPLAYERSCUSTOM];
 
public OnWar3LoadRaceOrItemOrdered2()
{
        thisRaceID = War3_CreateNewRaceT("sacrificial");
        SKILL_LEECH = War3_AddRaceSkillT(thisRaceID, "Vampirism", false, 4, "25%");
        SKILL_SPEED = War3_AddRaceSkillT(thisRaceID, "ThrillOfTheHunt", false, 4, "25%");
        SKILL_REGEN = War3_AddRaceSkillT(thisRaceID, "Regeneration", false, 4, "0.5");
        ULT_INVIS = War3_AddRaceSkillT(thisRaceID, "LieInWait", true, 4);
       
        War3_CreateRaceEnd(thisRaceID);

        War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, VampirePercent);
        War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, SpeedIncrease);
}
 

 
public OnWar3EventSpawn(client)
{
        SkillCheck(client);
       
        if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true))
   {
      War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
   }
}
 
public OnSkillLevelChanged(client,race,skill,newskilllevel){
    SkillCheck(client);
}
 
public OnRaceChanged(client, oldrace, newrace)
{
        SkillCheck(client);
       
        if(oldrace == thisRaceID)
        {
                War3_WeaponRestrictTo(client,thisRaceID,"");
        }
        if(newrace == thisRaceID)
        {
                War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
        }
}
 
SkillCheck(client)
{
        if(War3_GetRace(client)!=thisRaceID)
    {
        War3_SetBuff(client,fHPRegen,thisRaceID,0.0);-
        War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
        return;
    }
        else
        {
                new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_REGEN);
                War3_SetBuff(client,fHPRegen,thisRaceID,Regeneration[skill]);
        }
       
        if(bInvisActivated[client])
        {
                War3_AddSkillBuff(thisRaceID, ULT_INVIS, fInvisibilitySkill, InvisibilitySkill);
                War3_SetBuff(client,fHPRegen,thisRaceID,0.0);-
        War3_SetBuff(client,fHPDecay,thisRaceID,ULT_INVIS);
        }
       
}
 
public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && ValidPlayer(client, true) && pressed)
    {
        new skill_level=War3_GetSkillLevel(client,race,ULT_INVIS);
        if(skill_level>0)
        {
           
            if(!Silenced(client) && (client,thisRaceID,ULT_INVIS,true))
                        {
                                if(!bInvisActivated[client])
                                {
                                PrintHintText(client,"%T","Activated Invisibility",client);
                                bInvisActivated[client] = true;
                                SkillCheck(client);
                }
                                        else
                                        {
                                        PrintHintText(client,"%T","Deactivated Invisibility",client);
                                        bInvisActivated[client] = false;
                                        SkillCheck(client);
                                        }
            }
                        else
                        {
                                W3MsgUltNotLeveled(client);
                        }
                }
        }
}