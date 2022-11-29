/**
* File: War3Source_999_Geist.sp
* Description: Gesit Race for War3Source (fakewing's private race)
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo = 
{
    name = "War3Source Race - Geist",
    author = "Remy Lebeau",
    description = "fakewing's private race",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};

// War3Source stuff + Sprite/Sound Variables
new thisRaceID;
new AuraID;
new SKILL_INVIS, SKILL_DAMAGE, SKILL_AURA, SKILL_SPEED;



// SKILL_DAMAGE Variables
new Float:g_fDamageBoost[] = { 0.0, 0.025, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35 };

// SKILL_SPEED Variables
new Float:g_fSpeed[]={1.0,1.2,1.3,1.35,1.4,1.45,1.50,1.55,1.6};

// SKILL_AURA Variables
new Float:g_fDamageWaveDistance=50.0;
new Float:g_fDamageWaveAmountArr[]={0.0,4.0,6.0,8.0,10.0};


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Geist [PRIVATE]","geist");
    
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Mask","Grants permanent invisibility and immunity at the cost of your hit-points",false,1);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Menace","A slash can be deadly too!",false,8);
    SKILL_AURA=War3_AddRaceSkill(thisRaceID,"Dark Presence","Enemies die around you",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Float","Using your lack of weight you are able to reach great speeds",false,8);
    
    War3_CreateRaceEnd(thisRaceID);
    
    AuraID=W3RegisterAura("geist_damagewave", g_fDamageWaveDistance, true);
}

    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public InitPassiveSkills( client )
{
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    
    new level_aura=War3_GetSkillLevel(client,thisRaceID,SKILL_AURA);
    W3SetAuraFromPlayer(AuraID,client,level_aura>0?true:false,level_aura);

    new skill_speed=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
    War3_SetBuff(client,fMaxSpeed,thisRaceID,g_fSpeed[skill_speed]);
    
    
    new skill_invis=War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS);
    if(skill_invis)
    {
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.01);
        War3_SetBuff(client,bDoNotInvisWeapon,thisRaceID,true);
        War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,-99);            
        War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
        War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
        War3_SetBuff(client,bImmunityWards,thisRaceID,true);    
    }
    
    new skill_damage=War3_GetSkillLevel(client,thisRaceID,SKILL_DAMAGE);
    War3_SetBuff( client, fDamageModifier, thisRaceID, g_fDamageBoost[skill_damage] );
    
        
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3SetAuraFromPlayer(AuraID,client,false);
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        W3ResetAllBuffRace( client, thisRaceID );
        InitPassiveSkills(client);
    }
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    
    if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
    {
        if(skill==SKILL_AURA)
        {
            W3SetAuraFromPlayer(AuraID,client,newskilllevel>0?true:false,newskilllevel);
        }
        else
        {
            InitPassiveSkills(client);
        }
    }
}

    
public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(aura==AuraID)
    {
        War3_SetBuff(client,fHPDecay,thisRaceID,inAura?g_fDamageWaveAmountArr[level]:0.0);
    }
}
