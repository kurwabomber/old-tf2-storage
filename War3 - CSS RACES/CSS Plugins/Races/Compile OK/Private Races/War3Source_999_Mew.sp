/**
* File: War3Source_999_Mew.sp
* Description: Mew Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_HEAL, SKILL_INVIS, SKILL_DMG, ULT_RESPAWN;

#define WEAPON_RESTRICT "weapon_deagle,weapon_tmp"
#define WEAPON_GIVE1 "weapon_deagle"
#define WEAPON_GIVE2 "weapon_tmp"

public Plugin:myinfo = 
{
    name = "War3Source Race - Mew",
    author = "Remy Lebeau",
    description = "spraynpray's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};

new g_iHealAmount[]={0,10,15,20,30,40};
new Float:g_fHealCooldown = 15.0;
new Float:ElectricTideRadius=375.0;
new HaloSprite, BeamSprite;
new Float:ElectricTideOrigin[MAXPLAYERSCUSTOM][3];
new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];



new Float:g_fInvis[]={1.0,0.90,0.8,0.7,0.6};
new Float:g_fInvisDuration = 2.0;
new Float:g_fDamageBoost[] = { 0.0, 0.1, 0.2, 0.28, 0.35 };


new g_iUltCount[MAXPLAYERS];
new XBeamSprite, BlueSprite;
new String:ultsnd[256];


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Mew [PRIVATE]","mew");
    
    SKILL_HEAL=War3_AddRaceSkill(thisRaceID,"Heal" ,"Mew heals self and others (+ability)",false,5);
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Evasive","So rare that it is still said to be a mirage by many experts - invis until shot",false,4);
    SKILL_DMG=War3_AddRaceSkill(thisRaceID,"Ancient Power","Uses powers from centuries ago to increase passive damage",false,4);
    ULT_RESPAWN=War3_AddRaceSkill(thisRaceID,"Ultimate sacrifice","Sacrifices self - Once per round, Mew can sacrifice itself (+ultimate)",true,3);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_INVIS, fInvisibilitySkill, g_fInvis);
    War3_AddSkillBuff(thisRaceID, SKILL_DMG, fDamageModifier, g_fDamageBoost);
    
    
}



public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
}



public OnMapStart()
{
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
    BlueSprite = PrecacheModel( "materials/sprites/physcannon_bluelight1.vmt" );
    XBeamSprite = PrecacheModel( "materials/sprites/XBeam2.vmt" );
    
    War3_AddSoundFolder(ultsnd, sizeof(ultsnd), "centaur/hoof.wav");
    War3_AddCustomSound( ultsnd );
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
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        InitPassiveSkills( client );
        CreateTimer( 1.0, GiveWep, client );
    }
}





/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            if(ability==0 && pressed)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_HEAL,true))
                {
                    new skill_web=War3_GetSkillLevel(client,thisRaceID,SKILL_HEAL);
                    if(skill_web>0)
                    {      
                        GetClientAbsOrigin(client,ElectricTideOrigin[client]);
                        ElectricTideOrigin[client][2]+=15.0;
                        
                        for(new i=1;i<=MaxClients;i++){
                            HitOnBackwardTide[i][client]=false;
                            HitOnForwardTide[i][client]=false;
                        }
                        //50 IS THE CLOSE CHECK
                        TE_SetupBeamRingPoint(ElectricTideOrigin[client], 20.0, ElectricTideRadius+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {100,255,100,133}, 60, 0);
                        TE_SendToAll();
                        
                        CreateTimer(0.1, StunLoop,GetClientUserId(client));
                        
                        War3_CooldownMGR(client,g_fHealCooldown,thisRaceID,SKILL_HEAL,_,_);
                        
                    }
                    else
                    {
                        PrintHintText(client, "Level ability first");
                    }
                }
            }
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
        }
    }
}


public Action:StunLoop(Handle:timer,any:userid)
{
    new attacker=GetClientOfUserId(userid);
    if(ValidPlayer(attacker) )
    {
        new team = GetClientTeam(attacker);
        new ult_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_HEAL );
        
        new Float:otherVec[3];
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true)&&GetClientTeam(i)==team)
            {        
                GetClientAbsOrigin(i,otherVec);
                otherVec[2]+=30.0;
                new Float:victimdistance=GetVectorDistance(ElectricTideOrigin[attacker],otherVec);
                if(victimdistance<ElectricTideRadius)
                {
                    War3_HealToMaxHP(i, g_iHealAmount[ult_level]);
                    PrintHintText(i, "Healed by Mew");
                }
            }
        }
    }
    
}



public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && ValidPlayer( client,true ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_RESPAWN );
        if( ult_level > 0 )
        {
            if(g_iUltCount[client] > 0)
            {
                RespawnPlayers(GetClientUserId(client));
                g_iUltCount[client] -= 1;
                CreateTimer( 1.0, KillPlayer, GetClientUserId(client) );
                
            }
            else
            {
                ForcePlayerSuicide(client);
            }
        
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}



public RespawnPlayers(any:userid)
{
    new client=GetClientOfUserId(userid);
    new target1, target2, target3;
    if(ValidPlayer(client) )
    {
        if(g_iUltCount[client] > 0)
        {
            if( GetClientTeam( client ) == TEAM_T )
                target1 = War3_GetRandomPlayer( client, "#t", false, 0, 0 );
            if( GetClientTeam( client ) == TEAM_CT )
                target1 = War3_GetRandomPlayer( client, "#ct", false, 0, 0 );
        }
        g_iUltCount[client] -= 1;
        
        if(g_iUltCount[client] > 0)
        {
            if( GetClientTeam( client ) == TEAM_T )
                target2 = War3_GetRandomPlayer( client, "#t", false, target1, 0 );
            if( GetClientTeam( client ) == TEAM_CT )
                target2 = War3_GetRandomPlayer( client, "#ct", false, target1, 0 );  
        }
        g_iUltCount[client] -= 1;
            
        if(g_iUltCount[client] > 0)
        {
            if( GetClientTeam( client ) == TEAM_T )
                target3 = War3_GetRandomPlayer( client, "#t", false, target1, target2 );
            if( GetClientTeam( client ) == TEAM_CT )
                target3 = War3_GetRandomPlayer( client, "#ct", false, target1, target2 );   
         }
        g_iUltCount[client] -= 1;
        
        new String:clientName[64];
        GetClientName( client, clientName, 64 );
        new String:targetName[64];
 
        if(target1)
        {
            GetClientName( target1, targetName, 64 );
            PrintToChat( client, "\x05: \x03Your sacrifice respawned \x04%s", targetName );
            PrintToChat( target1, "\x05: \x03 %s sacrificed themselves for you!  You will be respawned in 5 seconds.", clientName );
            CreateTimer( 5.0, RespawnTimer, GetClientUserId(target1) );
        }
        if(target2)
        {
            GetClientName( target2, targetName, 64 );
            PrintToChat( client, "\x05: \x03Your sacrifice respawned \x04%s", targetName );
            PrintToChat( target2, "\x05: \x03 %s sacrificed themselves for you!  You will be respawned in 5 seconds.", clientName );
            CreateTimer( 5.0, RespawnTimer, GetClientUserId(target2) );
        }
        if(target3)
        {
            GetClientName( target3, targetName, 64 );
            PrintToChat( client, "\x05: \x03Your sacrifice respawned \x04%s", targetName );
            PrintToChat( target3, "\x05: \x03 %s sacrificed themselves for you!  You will be respawned in 5 seconds.", clientName );
            CreateTimer( 5.0, RespawnTimer, GetClientUserId(target3) );
        }

        
    }
}


public Action:RespawnTimer( Handle:timer, any:userid )
{
    new client=GetClientOfUserId(userid);
    if(ValidPlayer(client) && !IsPlayerAlive(client))
    {
        War3_SpawnPlayer(client);
        Client_GiveWeaponAndAmmo(client, "weapon_m4a1", true, 90);
    }
}




public Action:KillPlayer( Handle:timer, any:userid )
{
    new client=GetClientOfUserId(userid);
    if(ValidPlayer(client,true))
    {
        ForcePlayerSuicide(client);
        
        decl Float:start_pos[3];
        decl Float:target_pos[3];
        GetClientAbsOrigin(client,start_pos);
        GetClientAbsOrigin(client,target_pos);
        target_pos[2]+=60.0;
        start_pos[1]+=50.0;
        TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 1.0, 3.0, 0, 0.0, {255,0,255,255}, 10);
        TE_SendToAll();
        TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 3.0, 5.0, 0, 0.0, {128,0,255,255}, 30);
        TE_SendToAll(2.0);    
        TE_SetupBeamRingPoint(target_pos, 20.0, 90.0, XBeamSprite, HaloSprite, 0, 1, 1.0, 90.0, 0.0, {128,0,255,255}, 10, 0);
        TE_SendToAll(2.0);                
        TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 5.0, 7.0, 0, 0.0, {128,0,255,255}, 70);
        TE_SendToAll(4.0);
        TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 6.0, 8.0, 0, 0.0, {128,0,255,255}, 170);
        TE_SendToAll(9.0);
        
        TE_SetupBeamRingPoint(start_pos, 20.0, 410.0, XBeamSprite, HaloSprite, 0, 1, 1.0, 90.0, 0.0, {128,0,255,255}, 10, 0);
        TE_SendToAll(2.0);
        
        EmitSoundToAll(ultsnd, client);

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
        if( War3_GetRace( victim ) == thisRaceID )
        {
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_INVIS );
            if( skill_level > 0 )
            {

                War3_SetBuff( victim, fInvisibilitySkill, thisRaceID, 1.0 );
                PrintHintText(victim, "Spotted!  Temporarily Visible");
                CreateTimer(g_fInvisDuration, MakeInvis, GetClientUserId(victim));
                
            }
        }
    }
}


public Action:MakeInvis(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    if(ValidPlayer(client) )
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS );
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, g_fInvis[skill_level] );
    }
    
}


/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/


/**
 * Get random player.
 *
 * @param type                 Client id
 * @param type                  Team id. CT - #ct, T - #t, All - #a
 * @param check_alive         Check for alive or not
 * @param check_immunity    Check for ultimate immunity or not
 * @param check_weapon      Check for client weapon restrictions
 * @return                      client
 */
public War3_GetRandomPlayer( client, const String:type[], bool:check_alive, target1, target2)
{
    new targettable[MaxClients];
    new target = 0;
    new bool:all;
    new x = 0;
    new team;
    if( StrEqual( type, "#t" ) )
    {
        team = TEAM_T;
        all = false;
    }
    else if( StrEqual( type, "#ct" ) )
    {
        team = TEAM_CT;
        all = false;
    }
    else if( StrEqual( type, "#a" ) )
    {
        team = 0;
        all = true;
    }
    for( new i = 1; i <= MaxClients; i++ )
    {
        if( i > 0 && i <= MaxClients && ValidPlayer( i ) )
        {
            if(client == i)
            {
                continue;
            }
            if(target1 == i)
            {
                continue;
            }
            if(target2 == i)
            {
                continue;
            }
            if( check_alive )
            {
                if (!IsPlayerAlive( i ))
                    continue;
                
            }
            else
            {
                if (IsPlayerAlive( i ))
                    continue;
            }
            if( !all && GetClientTeam( i ) != team )
                continue;
            if( i == client)
                continue;
            targettable[x] = i;
            x++;
        }
    }
    
    for( new y = 0; y <= x; y++ )
    {
        if( target == 0 )
        {
            target = targettable[GetRandomInt( 0, x - 1 )];
            
        }
        else if( target != 0 && target > 0 )
        {
            return target;
        }
    }
    
    
    return 0;
}







public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            g_iUltCount[i] = War3_GetSkillLevel( i, thisRaceID, ULT_RESPAWN );
        }
    }
}

    

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_RemoveAllWeapons(client, "weapon_c4", true);

        Client_GiveWeaponAndAmmo(client, WEAPON_GIVE1, false, 35); 
        Client_GiveWeaponAndAmmo(client, WEAPON_GIVE2, true, 120); 
    }
}