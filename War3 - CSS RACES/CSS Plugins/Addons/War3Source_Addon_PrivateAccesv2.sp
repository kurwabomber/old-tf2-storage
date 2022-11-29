/**
* File: War3Source_Addon_PrivateAccess.sp
* Description: Controls the access to private races
* Author(s): Remy Lebeau
* Current functions:     Allows / Disallows access by specific people to private races
*                        Creates a brief effect over private races when they spawn
*                         Requires - config/war3souce_privateaccess.cfg
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo = 
{
    name = "War3Source Addon - Private Access",
    author = "Remy Lebeau",
    description = "Controls access to private races",
    version = "2.1.1",
    url = "sevensinsgaming.com"
};


new HaloSprite, BeamSprite;



new bool:isprivate[MAXPLAYERS] = false;

public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);

}

public OnMapStart()
{
    
    HaloSprite=War3_PrecacheHaloSprite();
    BeamSprite=War3_PrecacheBeamSprite();
    
}
    
    

/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnW3Denyable(W3DENY:event, client)
{
    if(event==DN_CanSelectRace)
    {
        new race_selected=W3GetVar(EventArg1);
        
        new String:rcvar[64];
        W3GetCvar(W3GetRaceCell(race_selected,RaceCategorieCvar),rcvar,sizeof(rcvar));
        if(strcmp("Private", rcvar, false)==0)
        {
           // decl String:raceshortname[32];
            //War3_GetRaceShortname(race_selected,raceshortname,sizeof(raceshortname));

           // PrintToChatAll("Entered into Private Check for race |%s|", raceshortname);
            isprivate[client] = false;

            new String:sFile[PLATFORM_MAX_PATH];
            BuildPath(Path_SM, sFile, sizeof(sFile), "configs/war3source_privateraces.cfg");
        
        
            if (FileExists(sFile)) 
            {
                new Handle:haccesslist = CreateKeyValues("MyFile");
                FileToKeyValues(haccesslist, sFile);
                KvGotoFirstSubKey(haccesslist);
        
                decl String:sClientSteamID[64];
                //GetClientAuthString(client, sClientSteamID, sizeof(sClientSteamID));
                GetClientAuthId(client, AuthId_Steam2, sClientSteamID, sizeof(sClientSteamID));
                
                do 
                {
                    decl String:sRaceName[64];
                    KvGetSectionName(haccesslist, sRaceName, sizeof(sRaceName));
                    
                    new raceID = War3_GetRaceIDByShortname(sRaceName);
                    if (race_selected == raceID)
                    {    
                        decl String:sSteamID[64];
                        KvGetString(haccesslist, sClientSteamID, sSteamID, sizeof(sSteamID));
                        
                        if ( sSteamID[0] != EOS )
                        {
                            //CPrintToChat( client, "{green}Access: - GRANTED - {default}Welcome back." );    
                            isprivate[client] = true;
                            break;
                        }
                        else
                        {
                            CPrintToChat( client, "{red}Access: - DENIED - {default}Get your own private race at sevensinsgaming.com!" );    
                            W3Deny();
                        }
                    }
        
                } while (KvGotoNextKey(haccesslist));
                CloseHandle(haccesslist);
            }
            else
            {
                PrintToChat (client, "failed to load private race config file");
            }
        }
    }
}



public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i,true)&& (isprivate[i] == true))
        {
            War3_HighlightPrivate (i);    
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





/***************************************************************************
*
*
*                BEAM HIGHLIGHT FOR CUSTOM/PRIVATE RACES
*
*
***************************************************************************/


stock War3_HighlightPrivate( client )
{
    CreateTimer(0.1, TopBeam, client);
    CreateTimer(0.3, MidBeam, client);
    CreateTimer(0.6, BottomBeam, client);
    CreateTimer(0.9, TopBeam, client);
    CreateTimer(1.2, MidBeam, client);
    CreateTimer(1.5, BottomBeam, client);
    CreateTimer(1.8, TopBeam, client);
    CreateTimer(2.1, MidBeam, client);
    CreateTimer(2.4, BottomBeam, client);
}

public Action:BottomBeam( Handle:timer, any:client )
{
    if(ValidPlayer(client,true))
    {
        new Float:effect_vec[3];
        GetClientAbsOrigin(client,effect_vec);
        effect_vec[2] +=15.0;
        TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,0.3,5.0,0.0,{3,255,242,255},10,0);
        TE_SendToAll();
    }    
}


public Action:MidBeam( Handle:timer, any:client )
{
    if(ValidPlayer(client,true))
    {
        new Float:effect_vec[3];
        GetClientAbsOrigin(client,effect_vec);
        effect_vec[2] +=30.0;
        TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,0.3,5.0,0.0,{3,255,242,255},10,0);
        TE_SendToAll();
    }    
}

public Action:TopBeam( Handle:timer, any:client )
{    
    if(ValidPlayer(client,true))
    {
        new Float:effect_vec[3];
        GetClientAbsOrigin(client,effect_vec);
        effect_vec[2] += 45.0;
        TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,0.3,5.0,0.0,{3,255,242,255},10,0);
        TE_SendToAll();
    }    
}    




