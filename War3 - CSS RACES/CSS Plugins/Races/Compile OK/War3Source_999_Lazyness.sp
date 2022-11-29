/**
* File: War3Source_999_Lazyness.sp
* Description: Lazyness race for War3Source.
* Author(s): Remy Lebeau
* RECOMMEND: Restricting buying periapt, tome and boots
* REQUIRED: Snapshot 882+ to compile/run
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"


// War3Source stuff + Sprite/Sound Variable
new thisRaceID;
new SKILL_HP, SKILL_SPEED, SKILL_EVADE, SKILL_SHOOT;
new String:LvlUpSound[] = "bot/i_am_dangerous.wav";

// Chance/Data Arrays
new HPBuff[] = {50, 40, 30, 20, 10, 0, -10, -20, -30};
new Float:SpeedPlusBuff[] = {1.25, 1.20, 1.15, 1.10, 1.05}; 
new Float:SpeedMinusBuff[] = {0.95, 0.90, 0.85, 0.80};
new Float:EvadeBuff[] = {0.0, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.25};
new Float:ShootBuff[] = {1.1, 1.07, 1.04, 1.01, 0.98, 0.95, 0.92, 0.89, 0.86, 0.83, 0.80};



public Plugin:myinfo = 
{
    name = "War3Source Race - Lazyness",
    author = "Remy Lebeau",
    description = "Lazyness race for War3Source.",
    version = "1.1.4",
    url = "sevensinsgaming.com"
};

public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace( "[1337] Lazyness", "lazyness" );
    
    SKILL_HP = War3_AddRaceSkill( thisRaceID, "Diseases", "As you get more diseased, your health fails (down to 70hp).", false, 8 );    
    SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Smokers Lung", "The more you smoke, the slower you run!", false, 8 );    
    SKILL_EVADE = War3_AddRaceSkill( thisRaceID, "Intoxicated", "Seeing where to shoot is quite hard through the foggy haze.", false, 8 );
    SKILL_SHOOT = War3_AddRaceSkill( thisRaceID, "Old Age", "You fire slower in your dotage.", false, 8 );
    
    
    War3_CreateRaceEnd( thisRaceID );
}


public OnMapStart()
{
    War3_PrecacheSound(LvlUpSound);
}

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/



public ResetPassiveSkills( client )
{    
    W3ResetAllBuffRace( client, thisRaceID );
    new skill_disease = War3_GetSkillLevel(client,thisRaceID,SKILL_HP);
    new skill_shoot = War3_GetSkillLevel(client,thisRaceID,SKILL_SHOOT);
    new skill_speed = War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
    
    War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,HPBuff[skill_disease]);    
    War3_SetBuff(client,fAttackSpeed,thisRaceID,ShootBuff[skill_shoot]);    
    
    if(skill_speed < 5)
    {
        War3_SetBuff(client,fMaxSpeed,thisRaceID,SpeedPlusBuff[skill_speed]);    
    
    }
    else if(skill_speed > 5)
    {
        War3_SetBuff(client,fSlow,thisRaceID,SpeedMinusBuff[skill_speed - 6]);    
    }
    

}

public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client ))
    {
        ResetPassiveSkills(client);
        W3EmitSoundToAll(LvlUpSound, client);
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client ))
    {
        W3EmitSoundToAll(LvlUpSound, client);
        ResetPassiveSkills(client);
        
        new skillcount = 0;
        skillcount += War3_GetSkillLevel(client, thisRaceID, SKILL_HP);
        skillcount += War3_GetSkillLevel(client, thisRaceID, SKILL_SPEED);
        skillcount += War3_GetSkillLevel(client, thisRaceID, SKILL_EVADE);
        skillcount += War3_GetSkillLevel(client, thisRaceID, SKILL_SHOOT);
        if (War3_GetLevel(client, thisRaceID) > (skillcount + 2))
        {
            new String:SteamID[64];
            new String:pName[256];
            GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
            GetClientName (client, pName, 256 );
            PrintToChat(client, "\x04You MUST place all available skills points into skills.");
            PrintToChat(client, "\x04Your STEAM ID has been logged, spend your skills or face the consequences.");
            LogMessage("Player |%s| with SteamID |%s| has |%d| skill levels but is total level |%d| on Lazyness Race", pName, SteamID, skillcount, War3_GetLevel(client, thisRaceID));
            CreateTimer( 15.0, LevelCheck, client );
        }
    }
}

public Action:LevelCheck( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client ))
    {
        new skillcount = 0;
        skillcount += War3_GetSkillLevel(client, thisRaceID, SKILL_HP);
        skillcount += War3_GetSkillLevel(client, thisRaceID, SKILL_SPEED);
        skillcount += War3_GetSkillLevel(client, thisRaceID, SKILL_EVADE);
        skillcount += War3_GetSkillLevel(client, thisRaceID, SKILL_SHOOT);
        if (War3_GetLevel(client, thisRaceID) > (skillcount + 2))
        {
            ForcePlayerSuicide(client);
            PrintToChat(client, "\x04Spend your skills.");
        }
    }    
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    if(race==thisRaceID)
    {
        ResetPassiveSkills(client);
    }
}

/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


public OnW3TakeDmgBulletPre(victim, attacker, Float:damage)
{
    if( ValidPlayer(attacker) && ValidPlayer (victim) && victim > 0 && attacker > 0 && attacker != victim )
    {
        new vteam = GetClientTeam( victim );
        new ateam = GetClientTeam( attacker );
        if(vteam!=ateam)
        {
            new race_attacker=War3_GetRace(attacker);
            new skill_evade = War3_GetSkillLevel(attacker,thisRaceID,SKILL_EVADE);
            
            // ******** REVERSE EVADE (OTHER PLAYERS EVADE YOUR SHOTS) *****************    
            
            if(race_attacker==thisRaceID && skill_evade > 0 && !Hexed(attacker,false))
            {
                if(!W3HasImmunity(victim,Immunity_Skills) && (GetRandomFloat(0.0, 1.0) < EvadeBuff[skill_evade]))
                {    
//                    PrintToChat(attacker, "Entered 5");
                    W3FlashScreen(attacker,RGBA_COLOR_BLUE);
                    War3_DamageModPercent(0.0); //NO DAMAMGE
                    PrintToChat(attacker, "Damn booze! You miss another shot.");
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

public OnW3Denyable(W3DENY:event, client)
{
    if( War3_GetRace( client ) == thisRaceID && ValidPlayer( client ))
    {
        if(event==DN_ShowLevelbank)
        {
            PrintToChat(client, "Levelbank Denied! This race is for LEET players only.  You have to work to level it up.");
            W3Deny();
        }
    }
}

