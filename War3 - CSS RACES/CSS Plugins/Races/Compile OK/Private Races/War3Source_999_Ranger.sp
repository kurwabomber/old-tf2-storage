/**
* File: War3Source_999_Ranger.sp
* Description: Eco Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_FROSTARROW, SKILL_INVIS, ULT_AID;

#define WEAPON_RESTRICT "weapon_knife,weapon_elite,weapon_scout"
#define WEAPON_GIVE "weapon_knife"

public Plugin:myinfo = 
{
    name = "War3Source Race - Ranger",
    author = "Remy Lebeau",
    description = "Arrow's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

new Float:g_fSpeed[5] = {1.0, 1.05, 1.10, 1.15, 1.20};
new Float:g_fGravity[5] = {1.0, 0.85, 0.7, 0.6, 0.5};
new Float:InvisibilityAlphaCS[5]={1.0,0.8,0.7,0.6,0.5};

//skill 2
new Float:FrostArrow[]={0.00,0.70,0.60,0.50,0.40};
new bool:g_bFrostFire[MAXPLAYERS];

new HP[] = { 0, 15, 19, 22, 25 };
new bsmaximumHP = 50; // buff amount, 100 + bsmaximumHP
new Float:UltCooldown = 15.0;
new GlowSprite, HaloSprite;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Ranger [PRIVATE]","ranger");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Agility","Gain increased movement speed and gravity",false,4);
    SKILL_FROSTARROW=War3_AddRaceSkill(thisRaceID,"Frost Arrows","Shoot frozen arrows at your enemy",false,4);
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Blend","Camouflage with your surroundings",false,4);
    ULT_AID=War3_AddRaceSkill(thisRaceID,"MediKit","Heal your self occasionally",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_AID,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fLowGravitySkill, g_fGravity);
    War3_AddSkillBuff(thisRaceID, SKILL_INVIS, fInvisibilitySkill, InvisibilityAlphaCS);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    HookEvent("bullet_impact",BulletImpact);
}



public OnMapStart()
{
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    GlowSprite = PrecacheModel( "materials/sprites/purpleglow1.vmt" );
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
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    CreateTimer( 1.0, GiveWep, client );

    War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, bsmaximumHP);
    g_bFrostFire[client] = false;
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills( client );
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
        InitPassiveSkills( client );
    }
}





/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_AID );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_AID, true ) )
            {
                War3_HealToMaxHP(client, HP[ult_level]);
                new Float:pos[3];
                
                GetClientAbsOrigin( client, pos );
                
                pos[2] += 50;
                
                TE_SetupGlowSprite( pos, GlowSprite, 4.0, 2.0, 255 );
                TE_SendToAll();
                
                War3_CooldownMGR( client, UltCooldown, thisRaceID, ULT_AID);
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
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


public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_attacker=War3_GetRace(attacker);
            new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTARROW);
            // Frost Arrow
            if(race_attacker==thisRaceID && skill_level>0 && !Silenced(attacker))
            {
                if(g_bFrostFire[attacker] && !W3HasImmunity(victim,Immunity_Skills))
                {
                    new String:wpnstr[32];
                    GetClientWeapon( attacker, wpnstr, 32 );
                    if( StrEqual( wpnstr, "weapon_scout" ) )
                    {
                        War3_SetBuff(victim,fSlow,thisRaceID,FrostArrow[skill_level]);
                        War3_SetBuff(victim,fAttackSpeed,thisRaceID,FrostArrow[skill_level]);
                        W3FlashScreen(victim,RGBA_COLOR_BLUE);
                        CreateTimer(1.5,unfrost,victim);
                        PrintHintText(attacker,"Frost Arrow!");
                        PrintHintText(victim,"You have been hit by a Frost Arrow");
                    }
                }
            }
        }
    }
}

public Action:FrostFalse(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
        g_bFrostFire[client] = false;
    }
}

public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client_userid = GetEventInt(event, "userid");    
    new client = GetClientOfUserId(client_userid);
    new Float:start_pos[3];
    GetClientAbsOrigin( client, start_pos );
    if(ValidPlayer(client, true) && (War3_GetRace( client ) == thisRaceID))
    {
        new String:wpnstr[32];
        GetClientWeapon( client, wpnstr, 32 );
        if( StrEqual( wpnstr, "weapon_scout" ) )
        {
            new skill_level = War3_GetSkillLevel(client, thisRaceID, SKILL_FROSTARROW);
            if (skill_level > 0)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_FROSTARROW))
                {   
                    g_bFrostFire[client] = true;
                    War3_CooldownMGR(client,5.0,thisRaceID,SKILL_FROSTARROW);
                    CreateTimer(0.5,FrostFalse,client);

                    new Float:Origin[3];
                    Origin[0] = GetEventFloat(event,"x");
                    Origin[1] = GetEventFloat(event,"y");
                    Origin[2] = GetEventFloat(event,"z");
                        
                    start_pos[2] += 40;
                    
                    
                    TE_SetupBeamPoints( start_pos, Origin, HaloSprite, HaloSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 20, 20, 200, 255 }, 40 );
                    TE_SendToAll();
                }
            }
        }
    }
}


public Action:unfrost(Handle:timer,any:client)
{
    War3_SetBuff(client,fSlow,thisRaceID,1.0);
    War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
}

/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}

    

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_GiveWeaponAndAmmo(client, "weapon_elite", false);
        Client_GiveWeaponAndAmmo(client, "weapon_scout", true);
    }
}