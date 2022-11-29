/*    X@IDER 16.12.2008
    My first plugin. Just implements Live On Three sequence
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
    name = "Live On 3",
    author = "X@IDER",
    description = "3 restart system",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
};

#define TEAM_CT 3
#define TEAM_T 2

// Restart values
new Handle:sm_lo3_r1_value = INVALID_HANDLE;
new Handle:sm_lo3_r2_value = INVALID_HANDLE;
new Handle:sm_lo3_r3_value = INVALID_HANDLE;

// Restart messages
new Handle:sm_lo3_r1_message = INVALID_HANDLE;
new Handle:sm_lo3_r2_message = INVALID_HANDLE;
new Handle:sm_lo3_r3_message = INVALID_HANDLE;

// Loops of text write
new Handle:sm_lo3_loops = INVALID_HANDLE;

// Message on match begins
new Handle:sm_lo3_match_message = INVALID_HANDLE;

new bool:lo3 = false;
new MoneyOffsetCS;

new String:modelCT[4][128];
new String:modelT[4][128];

public OnPluginStart()
{
    sm_lo3_r1_value = CreateConVar("sm_lo3_r1_value", "3", "First restart time", 0, true, 1.0);
    sm_lo3_r2_value = CreateConVar("sm_lo3_r2_value", "3", "Second restart time", 0, true, 1.0);
    sm_lo3_r3_value = CreateConVar("sm_lo3_r3_value", "3", "Third restart time", 0, true, 1.0);
    sm_lo3_r1_message = CreateConVar("sm_lo3_r1_message", "Match will be live after 3 restarts", "First restart message", 0);
    sm_lo3_r2_message = CreateConVar("sm_lo3_r2_message", "Match will be live after 2 restarts", "Second restart message", 0);
    sm_lo3_r3_message = CreateConVar("sm_lo3_r3_message", "Match will be live after next restart", "Third restart message", 0);
    sm_lo3_match_message = CreateConVar("sm_lo3_match_message", "MATCH IS LIVE!!! GO GO GO!!!", "Match message", 0);
    sm_lo3_loops = CreateConVar("sm_lo3_loops", "5", "Loops of repeating text", 0, true, 1.0);
    RegAdminCmd("sm_lo3", Rest1, ADMFLAG_KICK);
    RegAdminCmd("sm_lo3_off", WarOff, ADMFLAG_KICK);
    HookEventEx("round_start", Event_RoundStart);
    HookEventEx("round_end", Event_RoundEnd);
    MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
}

public OnMapStart()
{
    lo3 = false;
    PrecacheModel("models/player/ct_gign.mdl",true);
    PrecacheModel("models/player/ct_gsg9.mdl",true);
    PrecacheModel("models/player/ct_sas.mdl",true);
    PrecacheModel("models/player/ct_urban.mdl",true);

    PrecacheModel("models/player/t_arctic.mdl",true);
    PrecacheModel("models/player/t_guerilla.mdl",true);
    PrecacheModel("models/player/t_leet.mdl",true);
    PrecacheModel("models/player/t_phoenix.mdl",true);

    modelCT[0] = "models/player/ct_gign.mdl";
    modelCT[1] = "models/player/ct_gsg9.mdl";
    modelCT[2] = "models/player/ct_sas.mdl";
    modelCT[3] = "models/player/ct_urban.mdl";

    modelT[0] = "models/player/t_arctic.mdl";
    modelT[1] = "models/player/t_guerilla.mdl";
    modelT[2] = "models/player/t_leet.mdl";
    modelT[3] = "models/player/t_phoenix.mdl";

}

// HANDLE THE MID MATCH SWITCHING & WARNING

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    if(lo3) 
    {
        new RoundsCount = GetTeamScore(TEAM_CT) + GetTeamScore(TEAM_T);
        if (RoundsCount == 4)
        {
            PrintToChatAll("\x04TEAMS WILL SWAP AFTER THIS ROUND");
            PrintToChatAll("\x04MONEY WILL BE RESET");
            PrintToChatAll("\x04TEAMS WILL SWAP AFTER THIS ROUND");
            PrintToChatAll("\x04MONEY WILL BE RESET");            
            PrintToChatAll("\x04TEAMS WILL SWAP AFTER THIS ROUND");
            PrintToChatAll("\x04MONEY WILL BE RESET");
        }
        if (RoundsCount == 5)
        {
            for(new client = 1; client <= MaxClients; client++)
            {
                if(IsValidClient(client) || IsBot(client))
                {
                    ResetWeapon(client);
                    ResetCash(client);
                    new scoreCT = GetTeamScore(CS_TEAM_CT);
                    new scoreT = GetTeamScore(CS_TEAM_T);
                    

                    ShowMsg(sm_lo3_match_message);
                }
            }
            SetScoreTeam(CS_TEAM_CT, scoreT);
            SetScoreTeam(CS_TEAM_T, scoreCT);
        }
    }
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
    if(lo3) 
    {
        new RoundsCount = GetTeamScore(TEAM_CT) + GetTeamScore(TEAM_T);
        if (RoundsCount == 5)
        {
        
            CreateTimer(0.3,AutoSwap);
        }
    }
}

public Action:AutoSwap(Handle:timer)
{
    for(new client = 1; client <= MaxClients; client++)
    {
        if(IsValidClient(client) || IsBot(client))
        {
            SwapClient(client);
        }
    }
    



}



SwapClient(client)
{
    new team = GetClientTeam(client);

    if(team == CS_TEAM_CT)
    {
        CS_SwitchTeam(client,CS_TEAM_T);
        SetEntityModel(client,modelT[GetRandomInt(0,3)]);
    }
    else if(team == CS_TEAM_T)
    {
        CS_SwitchTeam(client,CS_TEAM_CT);
        SetEntityModel(client,modelCT[GetRandomInt(0,3)]);
    }
}


ResetWeapon(client)
{
    new team = GetClientTeam(client);

    new weaponentity;
    new grenade;

    // SLOTS
    // 0 - PRIMARY ARMOR
    // 1 - SECUNDARY ARMOR
    // 2 - KNIFE
    // 3 - GRENADES - flashbang, hegrenade, smokegrenade 
    // 4 - C4

    for(new slotweapon = 0; slotweapon <= 3; slotweapon++)
    {
        weaponentity = GetPlayerWeaponSlot(client,slotweapon);

        if(IsValidEntity(weaponentity))
        {
            if (slotweapon != 2) 
            {
                RemovePlayerItem(client,weaponentity);

                if(slotweapon == 3)
                {
                    grenade = GetPlayerWeaponSlot(client,slotweapon);

                    while(IsValidEntity(grenade))
                    {
                        RemovePlayerItem(client,grenade);
                        grenade = GetPlayerWeaponSlot(client,slotweapon);
                    }
                }
            }
        }
    }


    if(team == CS_TEAM_CT)
    {
        GivePlayerItem(client,"weapon_usp");
    }
    else if(team == CS_TEAM_T)
    {
        GivePlayerItem(client,"weapon_glock");
    }
}


ResetCash(client)
{
    new startMoney = GetConVarInt(FindConVar("mp_startmoney"));

    SetEntData(client,MoneyOffsetCS,startMoney,4,true);
}



bool:IsValidClient(client)
{
    if (IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client))
    {
        return true;
    }
    else
    {
        return false;
    }
}


bool:IsBot(client)
{
    if (IsClientInGame(client) && IsFakeClient(client))
    {
        return true;
    }
    else
    {
        return false;
    }
}


bool:SetScoreTeam(index, score)
{
    new edict = GetEdictTeam(index);

    if (edict == -1)
    {
        return false;
    }

    SetEntProp(edict, Prop_Send, "m_iScore", score);
    ChangeEdictState(edict, GetEntSendPropOffs(edict, "m_iScore"));

    return true;
}


GetEdictTeam(index)
{
	new team_manager = -1;

	while ((team_manager = FindEntityByClassname(team_manager, "cs_team_manager")) != -1)
	{
		if (EdictGetNumTeam(team_manager) == index)
		{
			return team_manager;
		}
	}

	return -1;
}

EdictGetNumTeam(edict)
{
	return GetEntProp(edict, Prop_Send, "m_iTeamNum");
}






// HANDLE THE LO3 STUFF
public Float:DoRest(Handle:val)
{
    new Float:rv = GetConVarFloat(val);
    ServerCommand("mp_restartgame %f",rv);
    return rv;
}

public ShowMsg(Handle:msg)
{
    new loops = GetConVarInt(sm_lo3_loops);
    new String:rm[64];
    GetConVarString(msg,rm,sizeof(rm));
    for (new i = 0; i < loops; i++)
    PrintToChatAll("\x04%s",rm);
    PrintCenterTextAll(rm);
}

public Action:Rest1(client, args)
{
    ServerCommand("exec war.cfg");
    ShowMsg(sm_lo3_r1_message);
    new Float:rv = DoRest(sm_lo3_r1_value);
    CreateTimer(rv,Rest2);
    lo3 = true;
}

public Action:WarOff(client, args)
{
    ServerCommand("exec server.cfg");
    PrintToChatAll("\x04WAR MODE OFF");
    PrintToChatAll("\x04WAR MODE OFF");
    PrintToChatAll("\x04WAR MODE OFF");
    PrintToChatAll("\x04WAR MODE OFF");
    PrintCenterTextAll("WAR MODE OFF"); 
    //ServerCommand("mp_restartgame 5");  
    lo3 = false;
}

public Action:Rest2(Handle:timer)
{
    ShowMsg(sm_lo3_r2_message);
    new Float:rv = DoRest(sm_lo3_r2_value);
    CreateTimer(rv,Rest3);    
}

public Action:Rest3(Handle:timer)
{
    ShowMsg(sm_lo3_r3_message);
    new Float:rv = DoRest(sm_lo3_r3_value);
    CreateTimer(rv,Match);    
}

public Action:Match(Handle:timer)
{
    ShowMsg(sm_lo3_match_message);
}