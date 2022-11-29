/**
* File: War3Source_999_Trebuchet.sp
* Description: Trebuchet Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_CRIT, SKILL_THORNS, SKILL_EXPLODE, ULT_UNPACK;

public Plugin:myinfo = 
{
    name = "War3Source Race - Trebuchet",
    author = "Remy Lebeau",
    description = "Trebuchet race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};

new Float:SuicideBomberRadius[5] = {0.0, 250.0, 290.0, 310.0, 333.0}; 
new Float:SuicideBomberDamage[5] = {0.0, 166.0, 200.0, 233.0, 266.0};
new Float:ThornsReturnDamage[5] = {0.0, 0.05, 0.10, 0.15, 0.20};
new Float:CriticalGrenadePercent[5]={0.0,0.1875,0.375,0.5625,0.75};
new Float:CriticalGrenadeChance[5]={0.0,0.35,0.4,0.45,0.5};
new bool:g_bUnpacked[MAXPLAYERS];
new Handle:g_hNadeTimer[MAXPLAYERS];
new Float:g_fUltCooldown[] = {0.0, 15.0, 10.0, 7.5, 5.0};
new BeamSprite;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Trebuchet [12 GAUGE]","trebuchet");
    
    SKILL_CRIT=War3_AddRaceSkill(thisRaceID,"Grenades","Get crit nades while -UNPACKED-, 35-50% chance.",false,4);
    SKILL_THORNS=War3_AddRaceSkill(thisRaceID,"Thorns Aura","Return a percentage of damage received.",false,4);
    SKILL_EXPLODE=War3_AddRaceSkill(thisRaceID,"Explode","Carrying all those crit nades makes for an explosive combination!",false,4);
    ULT_UNPACK=War3_AddRaceSkill(thisRaceID,"Unpacked","Cannot move & fully invis (+ultimate)",true,4);
    
    War3_CreateRaceEnd(thisRaceID);
    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{
    BeamSprite=War3_PrecacheBeamSprite(); 
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
    War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
    g_bUnpacked[client] = false;
    g_hNadeTimer[client] = INVALID_HANDLE;
    War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
    War3_SetBuff( client, bNoMoveMode, thisRaceID, false );

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


public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_UNPACK );
        if(ult_level>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_UNPACK,true))
                {
                    if(g_bUnpacked[client])
                    {
                        if(g_hNadeTimer[client]!= INVALID_HANDLE)
                        {
                            KillTimer(g_hNadeTimer[client]);
                            g_hNadeTimer[client] = INVALID_HANDLE;
                        }
                        g_bUnpacked[client] = false;
                        Client_RemoveWeapon(client, "weapon_hegrenade");
                        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
                        
                        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
                        War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
                        
                        War3_CooldownMGR(client,g_fUltCooldown[ult_level],thisRaceID,ULT_UNPACK,_,_);
                    }
                    else
                    {
                        g_bUnpacked[client] = true;
                        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_hegrenade");
                        Client_GiveWeapon(client, "weapon_hegrenade", true);
                        
                        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0 );
                        War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
                        
                        War3_CooldownMGR(client,g_fUltCooldown[ult_level],thisRaceID,ULT_UNPACK,_,_);
                    }
                    
                
                
                }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
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
    if(ValidPlayer(victim) && ValidPlayer(attacker))
    {
        if(W3GetDamageIsBullet() &&  victim != attacker && War3_GetRace(victim) == thisRaceID)
        {
            new iThornsLevel = War3_GetSkillLevel(victim, thisRaceID, SKILL_THORNS);
            if(iThornsLevel > 0 && !Hexed(victim, false))
            {
                // Don't return friendly fire damage
                if(ValidPlayer(attacker) && GetClientTeam(victim) == GetClientTeam(attacker))
                {
                    return;
                }
                
                if(!W3HasImmunity(attacker, Immunity_Skills))
                {
                    new iDamage = RoundToFloor(damage * ThornsReturnDamage[iThornsLevel]);
                    if(iDamage > 0)
                    {
                        if(iDamage > 50)
                        {
                            iDamage = 50;
                        }

                        if (GAMECSANY)
                        {
                            // Since this is delayed we don't know if the damage actually went through
                            // and just have to assume... Stupid!
                            War3_DealDamageDelayed(attacker, victim, iDamage, "thorns", 0.1, true, SKILL_THORNS);
                            War3_EffectReturnDamage(victim, attacker, iDamage, SKILL_THORNS);
                        }
                        else
                        {
                            if(War3_DealDamage(attacker, iDamage, victim, _, "thorns", _, W3DMGTYPE_PHYSICAL))
                            {
                                War3_EffectReturnDamage(victim, attacker, War3_GetWar3DamageDealt(), SKILL_THORNS);
                            }
                        }
                    }
                }
            }
        }
        if(victim>0&&attacker>0&&victim!=attacker && GetClientTeam(victim) != GetClientTeam(attacker) && g_bUnpacked[attacker])
        {
            new skill_cg_attacker=War3_GetSkillLevel(attacker,thisRaceID,SKILL_CRIT);
            if(War3_GetRace(attacker) == thisRaceID && skill_cg_attacker>0 && !Hexed(attacker,false) && GetRandomFloat(0.0,1.0) <= CriticalGrenadeChance[skill_cg_attacker])
            {
                if((StrContains(weapon,"hegrenade",false) != -1) && !W3HasImmunity(victim,Immunity_Skills))
                {
                    new Float:percent=CriticalGrenadePercent[skill_cg_attacker];
                    new originaldamage=RoundToFloor(damage);
                    new health_take=RoundFloat(damage*percent);
                    
                    new onehp=false;
                    ///you cannot die from orc nade unless the usual nade damage kills you
                    if(GetClientHealth(victim)>originaldamage&&health_take>GetClientHealth(victim)){
                            health_take=GetClientHealth(victim) -1;
                            onehp=true;
                    }
                    if(War3_DealDamage(victim,health_take,attacker,_,"criticalnade",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG))
                    {
                        W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_CRIT);
                        W3FlashScreen(victim,RGBA_COLOR_RED);
                        if(onehp){
                            SetEntityHealth(victim,1); 
                        }
                        decl Float:fPos[3];
                        GetClientAbsOrigin(victim,fPos);
                        new Float:fx_delay = 0.35;
                        for(new i=0;i<4;i++)
                        {
                            TE_SetupExplosion(fPos, BeamSprite, 4.5, 1, 4, 0, TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_ROTATE);
                            TE_SendToAll(fx_delay);
                            fx_delay += GetRandomFloat(0.30,0.50);
                        }
                    }
                }
            }
        }
    }
}


public OnWar3EventDeath(victim, attacker)
{
    new race = W3GetVar(DeathRace);
    new skill = War3_GetSkillLevel(victim, thisRaceID, SKILL_EXPLODE);
    if(race == thisRaceID && skill > 0 && !Hexed(victim))
    {
        decl Float:fVictimPos[3];
        GetClientAbsOrigin(victim, fVictimPos);
        
        War3_SuicideBomber(victim, fVictimPos, SuicideBomberDamage[skill], SKILL_EXPLODE, SuicideBomberRadius[skill]);        
    } 
}

public OnWeaponFired(client)
{    
    if (War3_GetRace(client) == thisRaceID)
    {
        new String:weapon[128];//weapon Char Array
        GetClientWeapon(client, weapon, 128);
        if(StrEqual(weapon,"weapon_hegrenade"))
        {
            g_hNadeTimer[client] = CreateTimer(5.0, UseGrenade, client);
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


public Action:UseGrenade(Handle:timer, any:client)
{
    if (ValidPlayer(client, true))
    {
        if (War3_GetRace(client) == thisRaceID)
        {
            Client_GiveWeapon(client, "weapon_hegrenade", true);
            g_hNadeTimer[client] = INVALID_HANDLE;
        }
    }
}

    

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_RemoveWeapon(client, "weapon_deagle");
        Client_RemoveWeapon(client, "weapon_ak47");
        
        
        Client_GiveWeaponAndAmmo(client, "weapon_ak47", true, 1000,_,_,_);
        Client_GiveWeaponAndAmmo(client, "weapon_deagle", false, 1000,_,_,_);
        Client_GiveWeapon(client, "weapon_hegrenade", false);
        Client_GiveWeapon(client, "weapon_flashbang", false);
        Client_GiveWeapon(client, "weapon_flashbang", false);
        Client_GiveWeapon(client, "weapon_smokegrenade", false);
    }
}