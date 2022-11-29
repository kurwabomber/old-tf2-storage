/**
* File: War3Source_999_TheShepherd.sp
* Description: The Shepherd Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;

#define WEAPON_RESTRICT "weapon_knife,weapon_deagle"
#define WEAPON_GIVE "weapon_deagle"

public Plugin:myinfo = 
{
    name = "War3Source Race - The Shepherd",
    author = "Remy Lebeau",
    description = "Kanon's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};

new Clip1Offset;
new g_iWeaponAmmo[] = {6, 8, 10, 11, 13};
new bool:bAmmo[MAXPLAYERS];
new g_iHealth[]={0,20,40,60,80};

new ParDmg[]={0,2,8,14,20};
new Float:ParCooldown[]={0.0,8.0,7.0,6.0,5.0};

new Float:g_fBurnChance[] = {0.0, 0.05, 0.10, 0.20, 0.30};
new Float:g_fBurnDuration = 2.0;
new g_iBurnDamage = 3;
new bool:g_bBurnBool[MAXPLAYERS];
new g_iBurnedBy[MAXPLAYERS];
new BurnSprite;
new Float:g_fBonusDamage[5]={0.0,0.05,0.08,0.10,0.15};


new SKILL_HEALTH, SKILL_AMMO, SKILL_DAMAGE, ULT_BURN;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("The Shepherd [PRIVATE]","theshepherd");
    
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Additional health","Pretty healthy",false,4);
    SKILL_AMMO=War3_AddRaceSkill(thisRaceID,"Extra clip","Continuous pain",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Your bullets do extra damage","Gods bullets",false,4);
    ULT_BURN=War3_AddRaceSkill(thisRaceID,"Burn your attackers","Divine punishment",true,4);
    
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, g_iHealth);
    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fBonusDamage);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    Clip1Offset = FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" );
    CreateTimer(0.5,BurnTimer,_,TIMER_REPEAT);
}



public OnMapStart()
{
    HookEvent( "weapon_reload", WeaponReloadEvent );
    BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
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
    g_bBurnBool[client] = false;
    g_iBurnedBy[client] = -1;
    bAmmo[client] = false;
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        GivePlayerItem( client, "weapon_deagle" );
        new skill1 = War3_GetSkillLevel( client, thisRaceID, SKILL_AMMO );
        if( skill1 > 0)
        {
            CreateTimer( 2.0, SetWepAmmo, client );
            bAmmo[client] = true;
        }
        InitPassiveSkills( client );
    }
}




public OnSkillLevelChanged(client,race,skill,newskilllevel )
{
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
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




/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(ValidPlayer(victim) && ValidPlayer(attacker) && victim != attacker )
    {
        if(GetClientTeam(victim) == GetClientTeam(attacker))
        {
            return;
        }
        if (War3_GetRace(victim) == thisRaceID && ValidPlayer(attacker,true))
        {
            new skill_level = War3_GetSkillLevel(victim, thisRaceID, ULT_BURN);
            if(skill_level > 0 && !Hexed(victim, false) && !W3HasImmunity(attacker, Immunity_Skills))
            {
                if ( GetRandomFloat( 0.0, 1.0 ) <= g_fBurnChance[skill_level])
                {
                    g_bBurnBool[attacker] = true;
                    g_iBurnedBy[attacker] = victim;
                    CreateTimer(g_fBurnDuration, BurnOff, GetClientUserId(attacker));
                    PrintToConsole(victim, "Burned Attacker");
                }                   
            }
        }
    }
}

public Action:BurnOff(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if(ValidPlayer(client))
    {
        g_bBurnBool[client] = false;
    }
}
public Action:BurnTimer(Handle:timer,any:userid)
{
    for(new client=1;client<=MaxClients;client++)
    {
        if(ValidPlayer(client,true))
        {
            if(g_bBurnBool[client])
            {
                new Float:positioni[3];
                War3_CachedPosition(client,positioni);
                TE_SetupGlowSprite(positioni,BurnSprite,0.4,1.9,255);
                TE_SendToAll();
                War3_DealDamage(client,g_iBurnDamage,g_iBurnedBy[client],DMG_BULLET,"Divine Punishment");
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

public WeaponReloadEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer(client))
    {
        new skill_m4a1 = War3_GetSkillLevel( client, race, SKILL_AMMO );
        if( skill_m4a1 > 0 && bAmmo[client] )
        {
            CreateTimer( 3.5, SetWepAmmo, client );
        }
    }
}



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

    
public Action:SetWepAmmo( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        new level = War3_GetSkillLevel( client, thisRaceID, SKILL_AMMO );
        new wep_ent = W3GetCurrentWeaponEnt( client );
        SetEntData( wep_ent, Clip1Offset, g_iWeaponAmmo[level], 4 );

    }
}    
