/**
* File: War3Source_999_Swat.sp
* Description: Swat Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions"

new thisRaceID;
new SKILL_SPEED, SKILL_REGEN, SKILL_AWP, ULT_SUMMON;

#define WEAPON_RESTRICT "weapon_knife,weapon_m4a1,weapon_awp,weapon_p228,weapon_hegrenade,weapon_flashbang,weapon_smokegrenade"
#define WEAPON_GIVE_M4 "weapon_m4a1"
#define WEAPON_GIVE_AWP "weapon_awp"

public Plugin:myinfo = 
{
    name = "War3Source Race - Swat",
    author = "Remy Lebeau",
    description = "ioutrankyou's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


//SPRINT
new bool:g_bSprintToggle[MAXPLAYERS];
new MoneyOffsetCS;
new Float:g_fSprintSpeed[]={1.0, 1.07, 1.14, 1.2, 1.3};

//Stand Still REGEN
//new Float:g_fRegenCooldown = 30.0;
new Float:g_fRegenAmount[] = {0.0, 1.0, 2.0, 3.0, 4.0};
new InvisTime[]={ 0, 30, 25, 20, 10 };
new m_vecVelocity = -1;
new Float:canspeedtime[MAXPLAYERS+1];
new AcceleratorDelayer[MAXPLAYERS];
new bool:g_bRegenTrue[MAXPLAYERS];

// AWP SWITCH
new Float:g_fAwpCooldown[] = {0.0, 25.0, 20.0, 15.0, 10.0};
new bool:g_bAwpToggle[MAXPLAYERS];

// SUMMON
new Float:g_fUltCooldown[] = {0.0, 90.0, 80.0, 70.0, 60.0};
new bool:bSummoned[MAXPLAYERS];
new PlayerOldRace[MAXPLAYERS];
new g_SupportCount[MAXPLAYERS];
new bool:b_gRoundOver;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Swat [PRIVATE]","swat");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Swat Training","Your athletic abilities are great - Sprint mode (+ability)",false,4);
    SKILL_REGEN=War3_AddRaceSkill(thisRaceID,"SWAT hostage","You are told to remain silent and calm until called upon\nStanding Still you regain your composure HP regen",false,4);
    SKILL_AWP=War3_AddRaceSkill(thisRaceID,"SWAT Guns","switch between Machine Gun(m4a1) and Sniper Rifle(awp) (+ability1)",false,4);
    ULT_SUMMON=War3_AddRaceSkill(thisRaceID,"Call on a raid","Respawn up to 2 teammates and 2 flashbangs (teammates are Changed to Crazy Eight) (+ultimate)",true,4);
    
    War3_CreateRaceEnd(thisRaceID);

}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    CreateTimer(1.0,mana,_,TIMER_REPEAT);
    CreateTimer(0.1, CalcSpeed,_,TIMER_REPEAT);
    m_vecVelocity = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
}



public OnMapStart()
{

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
    g_bSprintToggle[client] = false;
    g_SupportCount[client] = 0;
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    GivePlayerItem(client, "weapon_p228"); 
    
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
    b_gRoundOver = true;
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        W3ResetAllBuffRace( client, thisRaceID );
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
    if( !Silenced( client )  )
    {
        if( War3_GetRace( client ) == thisRaceID && ability == 1 && pressed && IsPlayerAlive( client ) )
        {
            new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_AWP );
            if( skill_level > 0 )
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
                PrintHintText(client, "Level up your ability first");
            }
        }
        if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
        {    
            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
            if(skill_level>0)
            {
                if(g_bSprintToggle[client]==true)
                {
                    PrintHintText(client,"Sprint: Slow down");
                    g_bSprintToggle[client]=false;
                    War3_SetBuff(client, fMaxSpeed, thisRaceID, 1.0  );
                }
                else
                {
                    PrintHintText(client,"Sprint: GO GO GO!");
                    g_bSprintToggle[client]=true;
                    War3_SetBuff(client, fMaxSpeed, thisRaceID, g_fSprintSpeed[skill_level]  );
                }
            }
        }
        
    }        
    else
    {
        PrintHintText(client, "Silenced, cannot use ability");
    }

}


public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && ValidPlayer( client,true ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_SUMMON );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_SUMMON, true ))
            {
                if(b_gRoundOver)
                {
                    CallForBackup( client);
                    PrintHintText(client, "Backup Summoned!");
                    War3_CooldownMGR( client, g_fUltCooldown[ult_level], thisRaceID, ULT_SUMMON, _, _ );
                }
                else
                {
                    PrintHintText(client, "May not summon after round end.");
                }
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}

stock CallForBackup( client )
{
    new bestTarget;
    
    if( GetClientTeam( client ) == TEAM_T )
        bestTarget = War3_GetRandomPlayer(client, "#t");
    if( GetClientTeam( client ) == TEAM_CT )
        bestTarget = War3_GetRandomPlayer(client, "#ct");

    if( bestTarget == 0 )
    {
        PrintHintText( client, "No More Support Available" );
    }
    else
    {
        new Float:ang[3];
        new Float:pos[3];
        GetClientEyeAngles(client,ang);
        GetClientAbsOrigin(client,pos);
        new crazyeight=War3_GetRaceIDByShortname("crazyeight");
        if (crazyeight==0)
        {
            PrintToChat(client, "SUMMON FAIL: CrazyEight Race not found, unable to continue");
        }
        else
        {
            PlayerOldRace[bestTarget]=War3_GetRace(bestTarget);
            W3SetPlayerProp(bestTarget,RaceChosenTime,GetGameTime());
            W3SetPlayerProp(bestTarget,RaceSetByAdmin,true);
            War3_SetRace(bestTarget,crazyeight);              
            bSummoned[bestTarget]=true;    
            War3_SpawnPlayer(bestTarget);
            TeleportEntity(bestTarget,pos,ang,NULL_VECTOR);
            PrintCenterText(bestTarget, "Swat needs backup! GO GO GO!");
        
        }
    }
    g_SupportCount[client]++;
    if(g_SupportCount[client] < 2)
    {
        CallForBackup( client );
    }
    else
    {
        g_SupportCount[client] = 0;
    }
    
}
        
    
    
/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnWar3EventDeath(victim,attacker)
{
    new race=War3_GetRace(victim);
    if(race==thisRaceID)
    {
        SetMoney(victim,0);
    }
    
    if(ValidPlayer(victim) && bSummoned[victim])
    {
        bSummoned[victim] = false;
        W3SetPlayerProp(victim,RaceChosenTime,GetGameTime());
        W3SetPlayerProp(victim,RaceSetByAdmin,true);
        War3_SetRace(victim,PlayerOldRace[victim]);   
    }
}



public Action:CalcSpeed(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID)
        {
            new skill_speed = War3_GetSkillLevel(i,thisRaceID,SKILL_REGEN);
            if(canspeedtime[i] < GetGameTime() && skill_speed > 0 )
            {
                // PrintToChat(i, "Standing still, invis in |%d|",AcceleratorDelayer[i]);
                AcceleratorDelayer[i]++;
                if(AcceleratorDelayer[i] > InvisTime[skill_speed] )
                {
                    if (g_bRegenTrue[i] == false)
                    {
                        War3_SetBuff( i, fHPRegen, thisRaceID, g_fRegenAmount[skill_speed]  );
                        W3Hint(i,HINT_LOWEST,1.0,"Resting!");
                        AcceleratorDelayer[i] = 0;
                        g_bRegenTrue[i] = true;
                    }
                }
                
            }
            else
            {
                if(g_bRegenTrue[i] == true)
                {
                    W3Hint(i,HINT_LOWEST,1.0,"Back in action!");
                    War3_SetBuff( i, fHPRegen, thisRaceID, 0.0 );
                    g_bRegenTrue[i] = false;
                }
                AcceleratorDelayer[i] = 0;
            
            }
            decl Float:velocity[3];
            GetEntDataVector(i,m_vecVelocity,velocity);
            if(skill_speed > 0 && GetVectorLength(velocity) > 0)
            {
                canspeedtime[i] = GetGameTime() + 1.0;
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

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    b_gRoundOver = false;
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
            SetMoney(i,0);
        }
        if(ValidPlayer(i))
        {
            if(bSummoned[i])
            {
                bSummoned[i] = false;
                W3SetPlayerProp(i,RaceChosenTime,GetGameTime());
                W3SetPlayerProp(i,RaceSetByAdmin,true);
                War3_SetRace(i,PlayerOldRace[i]);   
            }
        }
    }
}



    
stock GetMoney(player)
{
    return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
    SetEntData(player,MoneyOffsetCS,money);
}


public Action:mana(Handle:timer,any:client)
{
    if(thisRaceID>0)
    {
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true))
            {
                if(War3_GetRace(i)==thisRaceID)
                {
                    if(!g_bSprintToggle[i])
                    {
                        new money=GetMoney(i);
                        if(money<16000)
                        {
                            SetMoney(i,money+200);
                        }
                    }
                    if(g_bSprintToggle[i])
                    {
                        new money=GetMoney(i);
                        if(money>100)
                        {
                            SetMoney(i,money-400);
                        }
                        else
                        {
                            g_bSprintToggle[i]=false;
                            PrintHintText(i,"Sprint: Out of puff!  Time to Rest");
                            War3_SetBuff(i, fMaxSpeed, thisRaceID, 1.0  );
                        }
                    }
                }
            }
        }
    }
}

public Action:GiveM4( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_RemoveWeapon(client, "weapon_awp");
        Client_RemoveWeapon(client, "weapon_m4a1");
        GivePlayerItem(client, WEAPON_GIVE_M4); 
    }
}



public Action:GiveAWP( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {

        Client_RemoveWeapon(client, "weapon_awp");
        Client_RemoveWeapon(client, "weapon_m4a1");
        GivePlayerItem(client, WEAPON_GIVE_AWP); 
    }
}
