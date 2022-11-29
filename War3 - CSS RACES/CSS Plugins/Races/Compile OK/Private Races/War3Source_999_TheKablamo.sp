/**
* File: War3Source_999_TheKablamo.sp
* Description: The Kablamo for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_AWP, SKILL_SPEED, SKILL_AURA, ULT_WEB;

#define WEAPON_RESTRICT_M4 "weapon_knife,weapon_m4a1,weapon_glock,weapon_usp,weapon_p228,weapon_deagle,weapon_elite,weapon_fiveseven"
#define WEAPON_RESTRICT_AWP "weapon_knife,weapon_awp,weapon_glock,weapon_usp,weapon_p228,weapon_deagle,weapon_elite,weapon_fiveseven"
#define WEAPON_GIVE_M4 "weapon_m4a1"
#define WEAPON_GIVE_AWP "weapon_awp"

 
public Plugin:myinfo = 
{
    name = "War3Source Race - Jason Voorhees",
    author = "Remy Lebeau",
    description = "Kablamo's private race for War3Source",
    version = "0.9",
    url = "http://sevensinsgaming.com"
};

// ZOOMZOOM
new Float:UnholySpeed[5] = {1.0, 1.05, 1.10, 1.15, 1.20};
new Float:LevitationGravity[5] = {1.0, 0.85, 0.7, 0.6, 0.5};

//AOE HEAL
new HealAmount[]={0,1,2,3,4};
new Float:HealRD[]={0.0,125.0,175.0,225.0,250.0};
new HaloSprite, HealSprite;

// AWP SWITCH
new Float:g_fAwpCooldown[] = {0.0, 25.0, 20.0, 15.0, 10.0};
new bool:g_bAwpToggle[MAXPLAYERS];

// ULT
new String:ult_sound[] = "weapons/357/357_spin1.wav";
new Float:PushForce[5] = { 0.0, 1.0, 1.1, 1.2, 1.25 };
new Float:g_fUltCooldown[] = {0.0, 35.0, 30.0, 25.0, 20.0};
new m_vecBaseVelocity, FreezeSprite1;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("The Kablamo [PRIVATE]","kablamo");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"ZoomZoom","more speed and low grav",false,4);
    SKILL_AURA=War3_AddRaceSkill(thisRaceID,"Dr K-Man","aoe healing",false,4);
    SKILL_AWP=War3_AddRaceSkill(thisRaceID,"Armoury","Spawn a Magnum sniper rifle (+ability)",false,4);
    ULT_WEB=War3_AddRaceSkill(thisRaceID,"Sling shot madness","Hookshot ",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_WEB,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, UnholySpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fLowGravitySkill, LevitationGravity);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    CreateTimer(2.0,Aura,_,TIMER_REPEAT);    
}

public OnMapStart()
{
    War3_PrecacheSound( ult_sound );
    FreezeSprite1 = PrecacheModel( "materials/effects/combineshield/comshieldwall.vmt" );
    HealSprite = PrecacheModel( "materials/sprites/hydraspinalcord.vmt" );
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
    CreateTimer( 1.0, GiveM4, client );
    g_bAwpToggle[client] = false;

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


public OnAbilityCommand( client, ability, bool:pressed )
{
    if( War3_GetRace( client ) == thisRaceID && ability == 0 && pressed && IsPlayerAlive( client ) )
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_AWP );
        if( skill_level > 0 )
        {
            if( !Silenced( client )  )
            {
                if (!g_bAwpToggle[client])
                {
                    if (War3_SkillNotInCooldown(client,thisRaceID,SKILL_AWP,true))
                    {
                        CreateTimer( 0.1, GiveAWP, client );
                        g_bAwpToggle[client] = true;
                    }
                }
                else
                {
                    CreateTimer( 0.1, GiveM4, client );
                    War3_CooldownMGR(client,g_fAwpCooldown[skill_level],thisRaceID,SKILL_AWP,true);
                    g_bAwpToggle[client] = false;
                }
            }
            else
            {
                PrintHintText(client, "Silenced, cannot use ability");
            }
        }
        else
        {
            PrintHintText(client, "Level up your ability first");
        }
    }
}

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_WEB );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_WEB, true ) )
            {
                TeleportPlayer( client );
                EmitSoundToAll( ult_sound, client );
                War3_CooldownMGR( client, g_fUltCooldown[ult_level], thisRaceID, ULT_WEB );
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}

stock TeleportPlayer( client )
{
    if( client > 0 && IsPlayerAlive( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_WEB );
        new Float:startpos[3];
        new Float:endpos[3];
        new Float:localvector[3];
        new Float:velocity[3];
        
        GetClientAbsOrigin( client, startpos );
        War3_GetAimTraceMaxLen(client, endpos, 2500.0);
        
        localvector[0] = endpos[0] - startpos[0];
        localvector[1] = endpos[1] - startpos[1];
        localvector[2] = endpos[2] - startpos[2];
        
        velocity[0] = localvector[0] * PushForce[ult_level];
        velocity[1] = localvector[1] * PushForce[ult_level];
        velocity[2] = localvector[2] * PushForce[ult_level];
        
        SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
        
        TE_SetupBeamPoints( startpos, endpos, FreezeSprite1, FreezeSprite1, 0, 0, 1.0, 1.0, 1.0, 0, 0.0, { 255, 14, 41, 255 }, 0 );
        TE_SendToAll();
        
        TE_SetupBeamRingPoint( endpos, 11.0, 9.0, FreezeSprite1, FreezeSprite1, 0, 0, 2.0, 13.0, 0.0, { 255, 100, 100, 255 }, 0, FBEAM_ISACTIVE );
        TE_SendToAll();
    }
}


/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/


public Action:Aura(Handle:timer,any:userid)
{
    for(new client=1;client<=MaxClients;client++){
        if(ValidPlayer(client,true)){
            if(War3_GetRace(client)==thisRaceID){
                new skill_aura=War3_GetSkillLevel(client,thisRaceID,SKILL_AURA);
                new ownerteam=GetClientTeam(client);
                new Float:allyPos[3];
                new Float:clientPos[3];
                GetClientAbsOrigin(client,clientPos);
                if(skill_aura>0){
                    if(GetClientHealth( client ) < War3_GetMaxHP( client ))
                    {
                        War3_HealToMaxHP(client,HealAmount[skill_aura]);
                        W3FlashScreen( client, RGBA_COLOR_GREEN );
                    }
                    for (new ally=1;ally<=MaxClients;ally++){
                        if(ValidPlayer(ally,true)&& GetClientTeam(ally)==ownerteam&&ally!=client){
                            GetClientAbsOrigin(ally,allyPos);
                            allyPos[2] += 40.0;
                            if(GetVectorDistance(clientPos,allyPos)<HealRD[skill_aura] && GetClientHealth( ally ) < War3_GetMaxHP( ally )){
                                War3_HealToMaxHP(ally,HealAmount[skill_aura]);
                                
                                TE_SetupBeamPoints( clientPos, allyPos, HealSprite, HaloSprite, 0, 0, 0.5, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
                                TE_SendToAll();
                                
                                W3FlashScreen( ally, RGBA_COLOR_GREEN );
                            }
                        }
                    }
                }
            }
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

    

public Action:GiveM4( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT_M4);
        Client_RemoveWeapon(client, "weapon_awp");
        Client_RemoveWeapon(client, "weapon_m4a1");
        CreateTimer(0.1, GiveM4_2, client);
    }
}
public Action:GiveM4_2( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem(client, WEAPON_GIVE_M4); 
    }
}



public Action:GiveAWP( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT_AWP);
        Client_RemoveWeapon(client, "weapon_awp");
        Client_RemoveWeapon(client, "weapon_m4a1");
        CreateTimer(0.1, GiveAWP_2, client);
    }
}
public Action:GiveAWP_2( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem(client, WEAPON_GIVE_AWP); 
    }
}
