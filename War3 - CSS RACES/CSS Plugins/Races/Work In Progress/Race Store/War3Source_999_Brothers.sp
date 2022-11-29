/**
* File: War3Source_999_Matrix.sp
* Description: Neo and Agent Smith Races for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new neoRaceID, smithRaceID;
new SKILL_MIN1, SKILL_MIN2, SKILL_MIN3, ULT_MIN;
new SKILL_SAC1, SKILL_SAC2, SKILL_SAC3, ULT_SAC;


public Plugin:myinfo = 
{
    name = "War3Source Races - Brothers",
    author = "Remy Lebeau",
    description = "2 Races that act in unison for War3Source (Ready & Krispy's private race)",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};



public OnWar3PluginReady()
{
    neoRaceID=War3_CreateNewRace("Neo [PRIVATE]","neo");
    
    SKILL_MIN1=War3_AddRaceSkill(minotaurRaceID,"Quick Step","Brothers gain speed (+ability)",false,4);
    SKILL_MIN2=War3_AddRaceSkill(minotaurRaceID,"Quick Recovery","Brothers gain health (+ability1)",false,4);
    SKILL_MIN3=War3_AddRaceSkill(minotaurRaceID,"Sacred, I need you","Respawns Sacred (+ability2)",false,4);
    ULT_MIN=War3_AddRaceSkill(minotaurRaceID,"Teamwork","Must be activated for abilities to work (+ultimate)",true,1);
 
    War3_CreateRaceEnd(neoRaceID);
    
    
    smithRaceID=War3_CreateNewRace("Agent Smith [PRIVATE]","smith");
    
    SKILL_SAC1=War3_AddRaceSkill(sacredRaceID,"Levitation","Brothers' gravity decreases (+ability).",false,4);
    SKILL_SAC2=War3_AddRaceSkill(sacredRaceID,"Damage","Brothers' damage increases (+ability1)",false,4);
    SKILL_SAC3=War3_AddRaceSkill(sacredRaceID,"Minotaur, help!","Respawns Minotaur (+ability2)",false,4);
    ULT_SAC=War3_AddRaceSkill(sacredRaceID,"Teamwork","Must be activated for abilities to work (+ultimate)",true,1);
   
    War3_CreateRaceEnd(smithRaceID);
    
}

new bool:g_bUltActive[MAXPLAYERS];
new bool:g_bSkillActive[MAXPLAYERS];
new g_iBrotherOf[MAXPLAYERS];


public OnPluginStart()
{

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
    g_bUltActive[client] = false;
    g_bSkillActive[client] = false;
    

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == minotaurRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
    }
    else if (newrace == sacredRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
    }
    else
    {
        g_iBrotherOf[client] = 0;
        W3ResetAllBuffRace( client, minotaurRaceID );
        W3ResetAllBuffRace( client, sacredRaceID );
    }
}

public OnWar3EventSpawn( client )
{
    TurnEverythingOff(client);
    new race = War3_GetRace( client );
    if (ValidPlayer(client, true))
    {
        if( race == minotaurRaceID || race == sacredRaceID )
        {
            W3ResetAllBuffRace( client, minotaurRaceID );
            W3ResetAllBuffRace( client, sacredRaceID );
            InitPassiveSkills(client);
            for(new i=1;i<=MaxClients;i++)
            {
                if(IsBrother(client,i) == true)
                {
                    g_iBrotherOf[client] = i;
                    break;
                }
            }
        }
    }
}




/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/

/*

public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_tp = War3_GetSkillLevel( client, thisRaceID, ULT_TELEPORT );
        if(skill_tp>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_TELEPORT,true)) //not in the 0.2 second delay when we check stuck via moving
                {

                
                
                }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
}
*/





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
/*
public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}*/


static bool:IsBrother(brother1, brother2, bool:CheckUlt=false)
{
    new searchRaceID;
    new UltBool = true;
    new clientRaceID = War3_GetRace( brother1 );
    
    if (clientRaceID == minotaurRaceID)
    {
        searchRaceID = sacredRaceID;
    }
    else if (clientRaceID == sacredRaceID)
    {
        searchRaceID = minotaurRaceID;
    }
    else
    {
        return false;
    }
    if (CheckUlt==true)
    {
        if (g_bUltActive[brother1] == true && g_bUltActive[brother2] == true)
        {
            UltBool = true;
        }
        else
        {
            UltBool = false;
        }
    }
    
    if (War3_GetRace( brother2 ) == searchRaceID && ValidPlayer(brother1, true) && ValidPlayer(brother2, true)&& GetClientTeam( brother1 ) != GetClientTeam( brother2 ) && UltBool)
    {
        
        return true;
    }
    else
    {
        return false;
    }
}

static TurnEverythingOff(client)
{
    if (ValidPlayer(client))
    {
        g_bUltActive[client] = false;
        g_bSkillActive[client] = false;
        W3ResetAllBuffRace( client, minotaurRaceID );
        W3ResetAllBuffRace( client, sacredRaceID );
    }    
}