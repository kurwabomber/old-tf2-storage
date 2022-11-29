/**
* File: War3Source_999_ZombieHoard.sp
* Description: Zombie Hoard Race for War3Source
* Author(s): Remy Lebeau
*   TO DO: Effects?
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>

#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions.inc"

new thisRaceID;
new SKILL_HEALTH, SKILL_SPEED, SKILL_SLOWIMMUNE, SKILL_DAMAGE;



public Plugin:myinfo = 
{
    name = "War3Source Race - Zombie Hoard",
    author = "Remy Lebeau",
    description = "Leviathan's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


// ZOMBIE CREATION

new bool:g_bZombie[MAXPLAYERS];
new g_iHoardCount[MAXPLAYERS];
new g_iMasterOfZombie[MAXPLAYERS];


// ZOMBIE HOARD BUFFS
new Float:g_fSpeed[] = { 1.0, 1.1 };
new Float:g_fSlow[] = {0.7, 0.75, 0.8, 0.85, 0.9};
new Float:g_fImmuneChance[] = { 0.0, 0.25, 0.40, 0.55, 0.70, 0.85, 1.0};
new Float:g_fDamage[] = { 0.0, 0.15, 0.20, 0.25, 0.30, 0.40, 0.5};
new g_iHealth[]={0,150,300,450,600,750,900};


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Zombie Hoard [PRIVATE]","zombiehoard");
    
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Health","The hoard never dies.",false,6);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","The hoard moves faster.",false,6);
    SKILL_SLOWIMMUNE=War3_AddRaceSkill(thisRaceID,"Slow Immune","Chance of the hoard becoming immune to slow",false,6);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Damage","Arm the hoard with machetes",true,6);
    
    War3_CreateRaceEnd(thisRaceID);
    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{
    PrecacheModel( "models/Zombie/Poison.mdl", true );
    PrecacheModel( "models/Zombie/Fast.mdl", true );
}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/




public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
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
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
        g_iHoardCount[client] = 0;
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

public OnWar3EventDeath(victim,attacker)
{

    new race = War3_GetRace( attacker );
    
    if( race == thisRaceID || g_bZombie[attacker] == true)
    {
        
        if (ValidPlayer( attacker, true ) && ValidPlayer( victim) && attacker != victim)
        {
            if( race == thisRaceID)
            {

                MakeZombie(victim, attacker);
            }
            else if (g_bZombie[attacker] == true)
            {
                MakeZombie(victim, attacker);
                W3GiveXPGold(g_iMasterOfZombie[attacker],XPAwardByGeneric,50,2,"Your hoard got a kill!");
            }
  
        }
    }
    if (g_bZombie[victim] == true)
    {
        g_bZombie[victim] = false;
        
        W3ResetAllBuffRace( victim, thisRaceID );
        War3_WeaponRestrictTo(victim,thisRaceID,"");
        g_iHoardCount[g_iMasterOfZombie[victim]]--;
        PrintCenterText( g_iMasterOfZombie[victim], "Hoard has decreased - you have %d zombies", g_iHoardCount[g_iMasterOfZombie[victim]]);
    }
}

static MakeZombie(victim, attacker)
{
    new zombie;
    if( GetClientTeam( attacker ) == TEAM_T )
        zombie = War3_GetRandomPlayer( attacker, "#t" );
    if( GetClientTeam( attacker ) == TEAM_CT )
        zombie = War3_GetRandomPlayer( attacker, "#ct" );

    if( zombie == 0 )
    {
        PrintHintText( attacker, "No dead teammates to turn into zombies." );
    }
    else
    {
                
        War3_SpawnPlayer(zombie);        
        if (g_bZombie[attacker] == true)
        {
            g_iMasterOfZombie[zombie] = g_iMasterOfZombie[attacker];
            g_iHoardCount[g_iMasterOfZombie[zombie]]++;
            PrintCenterText( g_iMasterOfZombie[attacker], "Hoard has increased - you have %d zombies", g_iHoardCount[g_iMasterOfZombie[zombie]]);
            InitZombieSkills(zombie, g_iMasterOfZombie[attacker]);
        }
        else
        {
            g_iMasterOfZombie[zombie] = attacker;
            g_iHoardCount[attacker]++;
            PrintCenterText( attacker, "Hoard has increased - you have %d zombies", g_iHoardCount[attacker]);
            InitZombieSkills(zombie, attacker);
        }

        new Float:pos[3];
        new Float:ang[3];
        War3_CachedAngle(victim,ang);
        War3_CachedPosition(victim,pos);
        
        g_bZombie[zombie] = true;
        
        
        PrintHintText(zombie, "ZOMBIE HOARD HAS BEGUN!");

        
        
        TeleportEntity(zombie,pos,ang,NULL_VECTOR);
        
        

    }
 
}




public InitZombieSkills( client, master )
{

    if( GetClientTeam( client ) == TEAM_T )
        SetEntityModel( client, "models/Zombie/Fast.mdl" );
    if( GetClientTeam( client ) == TEAM_CT )
        SetEntityModel( client, "models/Zombie/Poison.mdl" );

    
    
    new nonzombieraceID = War3_GetRace( client );
    W3ResetAllBuffRace( client, nonzombieraceID );
    
    War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
    GivePlayerItem( client, "weapon_knife");
    

    new skill_health = War3_GetSkillLevel( master, thisRaceID, SKILL_HEALTH );
    War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, g_iHealth[skill_health]  );
    
    new skill_speed = War3_GetSkillLevel( master, thisRaceID, SKILL_SPEED );
    if (skill_speed < 5)
    {
        War3_SetBuff( client, fSlow, thisRaceID, g_fSlow[skill_speed]  );   
    }
    else
    {    
        new index = skill_speed - 5;
        War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fSpeed[index]  );
    }
    
    new skill_immune = War3_GetSkillLevel( master, thisRaceID, SKILL_SLOWIMMUNE );
    if (GetRandomFloat( 0.0, 1.0 ) <= g_fImmuneChance[skill_immune]) 
        War3_SetBuff(client,bSlowImmunity,thisRaceID,true);
    
    new skill_damage = War3_GetSkillLevel( master, thisRaceID, SKILL_DAMAGE );
    War3_SetBuff( client, fDamageModifier, thisRaceID, g_fDamage[skill_damage]  );
    
}




/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        if (!IsValidEntity(weapon)) return Plugin_Continue;
        new String:weaponclassname[20];
        GetEntityClassname(weapon, weaponclassname, sizeof(weaponclassname));
        if (buttons & IN_ATTACK2 && StrEqual(weaponclassname, "weapon_knife"))
        {
            buttons |= IN_ATTACK;
            return Plugin_Changed;
        }
        return Plugin_Continue;
    }
    return Plugin_Continue;
}

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && g_bZombie[i] == true)
        {
            g_bZombie[i] = false;
            W3ResetAllBuffRace( i, thisRaceID );
            War3_WeaponRestrictTo(i,thisRaceID,"");
            
            g_iMasterOfZombie[i] = -1;
        }
    }
}


