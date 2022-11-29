/**
* File: War3Source_999_ABGar.sp
* Description: ABGar Private Race for War3Source
* Author(s): Remy Lebeau & ABGar
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
//#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_INVIS, SKILL_LEECH, ULT_JUMP;

#define WEAPON_RESTRICT "weapon_knife,weapon_deagle,weapon_hegrenade,weapon_flashbang"
#define WEAPON_GIVE "weapon_deagle"

public Plugin:myinfo = 
{
    name = "War3Source Race - ABGar",
    author = "Remy Lebeau / ABGar",
    description = "ABGar's private race for War3Source",
    version = "0.9",
    url = "http://sevensinsgaming.com"
};

// BUFFS
new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4};
new Float:g_fLeech[] = {0.0, 0.05, 0.08, 0.12, 0.15};

// ABILITY
new Float:InvisDuration[]={0.0, 2.0, 3.0, 4.0, 5.0};
new Handle:InvisEndTimer[MAXPLAYERS];
new bool:InInvis[MAXPLAYERS];
new String:ww_on[]="npc/scanner/scanner_nearmiss1.wav";
new String:ww_off[]="npc/scanner/scanner_nearmiss2.wav";

//ULTIMATE
new JumpCounter[MAXPLAYERS];
new JumpLimit[] = {0, 1, 2, 3, 4};
new Float:JumpHeight[] = {0.0, 300.0, 400.0, 500.0, 600.0};
new m_vecBaseVelocity;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("ABGar [PRIVATE]","abgar");
   
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Run Fast","More Speed (passive)",false,4);
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Hide","Go Invisible for a short period (+ability)",false,4);
    SKILL_LEECH=War3_AddRaceSkill(thisRaceID,"Steal Health","Steal Health when you attack others (passive)",false,4);
    ULT_JUMP=War3_AddRaceSkill(thisRaceID,"Jump High","Allows you to do multi-jumps in the air (+ultimate)",false,4);

    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, g_fLeech);
}



public OnPluginStart()
{
    //HookEvent("round_end",RoundOverEvent);
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");     
 
}



public OnMapStart()
{
	War3_PrecacheSound(ww_on);
	War3_PrecacheSound(ww_off);
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
    InInvis[client]=false;
    War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
    War3_SetBuff(client,bDisarm,thisRaceID,false);
    new skill_speed=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
    War3_SetBuff(client,fMaxSpeed,thisRaceID,g_fSpeed[skill_speed]);
    JumpCounter[client] = 0;
    InvisEndTimer[client] = INVALID_HANDLE;
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
                new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS);
                if(skill>0)
                {      
                    if(InInvis[client])
                    {
                        if(InvisEndTimer[client] != INVALID_HANDLE)
                        {
                            PrintHintText(client, "Invis off!");
                            TriggerTimer(InvisEndTimer[client]);
                            InvisEndTimer[client] = INVALID_HANDLE;        
                            EmitSoundToAll(ww_off,client); 
                        }
                    }
                    else if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_INVIS,true))
                    {         
                        PrintHintText(client, "Invis on!");     
                        EmitSoundToAll(ww_on,client);                            
                        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
                        War3_SetBuff(client,fMaxSpeed,thisRaceID,1);
                        War3_SetBuff(client,bDisarm,thisRaceID,true);
                        InvisEndTimer[client]=CreateTimer(InvisDuration[skill],EndInvis,client);
                        InInvis[client]=true;
                        War3_CooldownMGR(client,25.0,thisRaceID,SKILL_INVIS, _, _);
                    } 
                }
                else
                {
                    PrintHintText(client, "Level Invis first");
                }
                
            }
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed && ValidPlayer( client, true ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_JUMP );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_JUMP, true ) )
            {
                if ((GetEntityFlags(client) & FL_ONGROUND))
                {
                    //PrintToChat(client, "In entityflags - should be on ground");
                    JumpCounter[client] = 0;
                }
                if(JumpCounter[client] <= JumpLimit[ult_level])
                {
                    //PrintToChat(client, "JumpCounter[client] = |%d|", JumpCounter[client]);
                    new Float:velocity[3];                         
                    velocity[2] += JumpHeight[ult_level];                          
                    SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
                    JumpCounter[client]++;
                    if(JumpCounter[client] == ult_level)
                    {
                        War3_CooldownMGR(client,1.0,thisRaceID,ULT_JUMP,_,_);
                        JumpCounter[client] = 0;
                    }
                }
                else
                {
                    JumpCounter[client] = 0;
                    War3_CooldownMGR(client,1.0,thisRaceID,ULT_JUMP,_,_);                                  
                }
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




/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer (client, true) && (War3_GetRace( client ) == thisRaceID))
    {
        if(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT))
        {
            if (GetEntityFlags(client) & FL_ONGROUND)
            {
                JumpCounter[client] = 0;
            }
        }
    }
    return Plugin_Continue;
}

public Action:EndInvis(Handle:timer,any:client)
{
    if (InvisEndTimer[client] != INVALID_HANDLE && ValidPlayer(client,true))
    {
        InitPassiveSkills(client);
        InvisEndTimer[client] = INVALID_HANDLE;
        EmitSoundToAll(ww_off,client); 
        PrintHintText(client, "Invis off!");
    }
}


public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            if (InvisEndTimer[i] != INVALID_HANDLE)
            {
                KillTimer(InvisEndTimer[i]);
                InitPassiveSkills(i);
                InvisEndTimer[i] = INVALID_HANDLE;
            }
        }
    }
}

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, "weapon_deagle" ); 
    }
}