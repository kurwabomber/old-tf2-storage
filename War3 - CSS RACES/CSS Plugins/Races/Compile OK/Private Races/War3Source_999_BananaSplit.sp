/**
* File: War3Source_999_BananaSplit.sp
* Description: BrotherBanana's Private Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_VAMPIRE, SKILL_INVIS, SKILL_DMG, ULT_HEAL;



public Plugin:myinfo = 
{
    name = "War3Source Race - Banana Split",
    author = "Remy Lebeau",
    description = "Banana Split race for War3Source",
    version = "0.9.1",
    url = "http://sevensinsgaming.com"
};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Banana Split [PRIVATE]","banana");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Slip'n on Peel","Slide around on banana peel to go faster!",false,4);
    SKILL_VAMPIRE=War3_AddRaceSkill(thisRaceID,"Potasium Boost","Steal HP from your victims.",false,4);
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Zip up","Hiding inside your banana skin no one can see you.",false,4);
    SKILL_DMG=War3_AddRaceSkill(thisRaceID,"Frozen Bananas","When fired from a scout, frozen bananas REALLY HURT",false,4);
    ULT_HEAL=War3_AddRaceSkill(thisRaceID,"Bananaman","Use the super healing power of BANANAS",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_HEAL,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
}


new Float:g_fSpeed[] = { 0.0, 1.1, 1.2, 1.25, 1.35 };
new Float:g_fInvis[] = { 1.0, 0.60, 0.55, 0.50, 0.40 };
new Float:g_fVampire[] = { 0.0, 0.05, 0.1, 0.15, 0.25 };
new Float:g_fDamageChance[] = { 0.0, 0.28, 0.44, 0.60, 0.69};
new g_iHealHP[] = { 0, 20, 30, 40, 50 };
new g_iMaximumHP = 50; 


new GlowSprite, HaloSprite;

public OnPluginStart()
{
}



public OnMapStart()
{
    GlowSprite = PrecacheModel( "materials/sprites/purpleglow1.vmt" );
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
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
if( War3_GetRace( client ) == thisRaceID )
    {                    
        War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, g_fInvis[War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS )] );
        War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, g_iMaximumHP);
        War3_SetBuff( client, fVampirePercent, thisRaceID, g_fVampire[War3_GetSkillLevel( client, thisRaceID, SKILL_VAMPIRE )]);
        
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout,weapon_elite,weapon_knife");
        CreateTimer( 1.0, GiveWep, client );
    }

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




/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID )
    {
        if(pressed  && ValidPlayer(client,true))
        {
            if (!Silenced(client))
            {
    
                new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_HEAL );
                if(ult_level>0)
                {
                    if(War3_SkillNotInCooldown(client,thisRaceID, ULT_HEAL, true))
                    {
                        War3_HealToMaxHP(client, g_iHealHP[ult_level]);
                        
                        new Float:pos[3];
                
                        GetClientAbsOrigin( client, pos );
                
                        pos[2] += 50;
                
                        TE_SetupGlowSprite( pos, GlowSprite, 4.0, 2.0, 255 );
                        TE_SendToAll();
                
                        War3_CooldownMGR( client, 20.0, thisRaceID, ULT_HEAL);
                    }
                }
                else
                {
                    PrintHintText(client, "Level your Ultimate first.");
                }
            }
            else
            {
                PrintHintText(client, "Cannot use Ultimate while silenced.");
            }
        }
    }
}





/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            if (strcmp(weapon,"scout",false)==0)
            {
                
                new skill_damage = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
                new min,max;
                min = 4 * skill_damage;
                max = 6 * skill_damage;
                new Damage = GetRandomInt( min, max );
                if( !Hexed( attacker, false ) && skill_damage > 0 && !W3HasImmunity( victim, Immunity_Skills ) && GetRandomFloat( 0.0, 1.0 ) < g_fDamageChance[skill_damage] )
                {

                    new Float:start_pos[3];
                    new Float:target_pos[3];
                    
                    GetClientAbsOrigin( attacker, start_pos );
                    GetClientAbsOrigin( victim, target_pos );
                    
                    start_pos[2] += 40;
                    target_pos[2] += 40;
                
                    TE_SetupBeamPoints( start_pos, target_pos, HaloSprite, HaloSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 200, 20, 20, 255 }, 40 );
                    TE_SendToAll();

                    War3_DealDamage( victim, Damage, attacker, DMG_BULLET, "banana_crit" );
                    W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
                    W3FlashScreen( victim, RGBA_COLOR_RED );
                }
            }
        }
    }
}





/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, "weapon_elite" );
        GivePlayerItem( client, "weapon_scout" );
    }
}

