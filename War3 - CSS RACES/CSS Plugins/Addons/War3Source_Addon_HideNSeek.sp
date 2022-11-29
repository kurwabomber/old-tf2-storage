/**
* File: War3Source_Addon_HideNSeek.sp
* Description: Enables or Disables HideNSeek mode for war3 CSS
* Author(s): Remy Lebeau
* Current functions:     Changes all T players to wisp race (requires the race to be installed)
*                        Changes all CT players to undead race (requires the race to be installed)
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include <smlib>


public Plugin:myinfo = 
{
    name = "War3Source Addon - Hide n Seek",
    author = "Remy Lebeau",
    description = "Toggles Hide n Seek Game Mode",
    version = "1.1",
    url = "sevensinsgaming.com"
};

//#define WEAPON_LIST "weapon_knife,weapon_glock,weapon_usp,weapon_p228,weapon_deagle,weapon_elite,weapon_fiveseven,weapon_m3,weapon_xm1014,weapon_galil,weapon_ak47,weapon_scout,weapon_sg552,weapon_awp,weapon_g3sg1,weapon_famas,weapon_m4a1,weapon_aug,weapon_sg550,weapon_mac10,weapon_tmp,weapon_mp5navy,weapon_ump45"


new bool:g_bHideEnabled = false;
new Handle:g_hRestartGame = INVALID_HANDLE;
new Handle:freezetimecvar;
new wispID, undeadID;
new Float:g_fLastDeath;


public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
    HookEvent( "bomb_beginplant", Event_BeginPlant, EventHookMode_Pre );
    HookEvent( "bomb_begindefuse", Event_BombBeginDefuse, EventHookMode_Pre );
    RegAdminCmd("sm_hidenseek_toggle",Command_Hidenseek, ADMFLAG_SLAY,"Toggles Hide and Seek Mode");
    g_hRestartGame  = FindConVar("mp_restartgame");
    freezetimecvar = FindConVar("mp_freezetime");
    wispID = War3_GetRaceIDByShortname("wisp");
    undeadID = War3_GetRaceIDByShortname("undead");


}



public Action:DeathCheck(Handle:timer,any:userid)
{
    if(g_bHideEnabled )
    {
        if(g_fLastDeath + 30.0 < GetGameTime())
        {
            ServerCommand( "sm_slay @ct");
            Client_PrintToChatAll(false, "{G}.: WISPS have successfully hidden for 30 seconds :.");
            g_fLastDeath = GetGameTime();
        }
        if(RoundToFloor(g_fLastDeath + 30.0) == RoundToFloor(GetGameTime() + 5.0))
        {
            Client_PrintToChatAll(false, "CTs must kill a T within {R}5 SECONDS.");
        }
        if(RoundToFloor(g_fLastDeath + 30.0) == RoundToFloor(GetGameTime() + 4.0))
        {
            Client_PrintToChatAll(false, "CTs must kill a T within {R}4 SECONDS.");
        }
        if(RoundToFloor(g_fLastDeath + 30.0) == RoundToFloor(GetGameTime() + 3.0))
        {
            Client_PrintToChatAll(false, "CTs must kill a T within {R}3 SECONDS.");
        }
        if(RoundToFloor(g_fLastDeath + 30.0) == RoundToFloor(GetGameTime() + 2.0))
        {
            Client_PrintToChatAll(false, "CTs must kill a T within {R}2 SECONDS.");
        }
        if(RoundToFloor(g_fLastDeath + 30.0) == RoundToFloor(GetGameTime() + 1.0))
        {
            Client_PrintToChatAll(false, "CTs must kill a T within {R}1 SECONDS.");
        }
    
    }

}




public OnMapStart()
{
    g_bHideEnabled = false;
}



public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim)&&ValidPlayer(attacker))
    {
        new race=War3_GetRace(victim);
        if(race==wispID)
        {
            g_fLastDeath = GetGameTime();        
        }
    }
}


public OnRaceChanged(client,oldrace,newrace)
{
     if(g_bHideEnabled && ValidPlayer(client))
    {
        wispID = War3_GetRaceIDByShortname("wisp");
        undeadID = War3_GetRaceIDByShortname("undead");
        if(oldrace==wispID){
            War3_WeaponRestrictTo(client,wispID,"");
            W3ResetAllBuffRace(client,wispID);
        }
        if(oldrace==undeadID){
            War3_WeaponRestrictTo(client,undeadID,"");
            W3ResetAllBuffRace(client,undeadID);
        }
    }
}

public OnClientPutInServer(client){
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}
public OnClientDisconnect(client){
    SDKUnhook(client,SDKHook_WeaponCanUse,OnWeaponCanUse); 
}

public Action:OnWeaponCanUse(client, weaponent)
{
    if(g_bHideEnabled)
    {

        if(CheckCanUseWeapon(client, weaponent))
        {
            return Plugin_Continue; //ALLOW
        }
        return Plugin_Handled;
        
    }
    
    return Plugin_Continue;
}



bool:CheckCanUseWeapon(client, weaponent){
    decl String:WeaponName[32];
    GetEdictClassname(weaponent, WeaponName, sizeof(WeaponName));
    
    if(StrContains(WeaponName,"c4")>-1){ //disallow c4
        return false;
    }
    if(StrContains(WeaponName,"p90")>-1){ //disallow p90
        PrintToChat(client, "P90 is not allowed in hide and seek");
        return false;
    }
    if(StrContains(WeaponName,"m249")>-1){ //disallow para
        PrintToChat(client, "Para is not allowed in hide and seek");
        return false;
    }

    return true; //allow
}

public OnWar3EventSpawn( client )
{
    if(g_bHideEnabled && ValidPlayer(client,true))
    {
        if (GetClientTeam(client) == TEAM_T)
        {
            wispID = War3_GetRaceIDByShortname("wisp");
            undeadID = War3_GetRaceIDByShortname("undead");
            
            W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
            W3SetPlayerProp(client,RaceSetByAdmin,true);
            
            War3_SetRace(client,wispID);
            
            new Float:freezetime = GetConVarFloat(freezetimecvar) + 10.0;
            
            War3_SetBuff( client, bDisarm, undeadID, true);
            CreateTimer(freezetime, StopDisarm, GetClientUserId(client));
            
            
        }
        else
        {
            undeadID = War3_GetRaceIDByShortname("undead");
            //War3_WeaponRestrictTo(client,undeadID,WEAPON_LIST);
            W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
            W3SetPlayerProp(client,RaceSetByAdmin,true);
            
            War3_SetRace(client,undeadID);
            new Float:freezetime = GetConVarFloat(freezetimecvar) + 10.0;
            
            War3_SetBuff( client, bBashed, undeadID, true);
            CreateTimer(freezetime, StopBash, GetClientUserId(client));
        }
    }
}    

public Action:StopBash(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if(ValidPlayer(client))
    {
        War3_SetBuff( client, bBashed, undeadID, false);
        PrintToChat(client, "GO! GO! GO! - Hide and Seek is on!");
    }
}

public Action:StopDisarm(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if(ValidPlayer(client))
    {
        War3_SetBuff( client, bDisarm, undeadID, false);
        PrintToChat(client, "GO! GO! GO! - Hide and Seek is on!");
    }
}

public Action:Command_Hidenseek(client, args) 
{
    if(g_bHideEnabled)
    {
        g_bHideEnabled = false;
        undeadID = War3_GetRaceIDByShortname("undead");
        wispID = War3_GetRaceIDByShortname("wisp");
        Client_PrintToChatAll(false, "{R}.: HIDENSEEK MODE IS OFF :.");
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i))
            {
                W3ResetAllBuffRace( client, undeadID );
                W3ResetAllBuffRace( client, wispID );
                War3_WeaponRestrictTo(client,undeadID,"");
                War3_WeaponRestrictTo(client,wispID,"");
                War3_SetRace(i,undeadID);
            }
        }
        ServerCommand( "sm_slay @all");
        
    }
    else
    {
        g_bHideEnabled = true;
        Client_PrintToChatAll(false, "{G}.: HIDE N SEEK MODE IS ON :.");
        ServerCommand( "sm_slay @all");
        SetConVarInt(g_hRestartGame, 3);
        g_fLastDeath = GetGameTime();
        CreateTimer(1.0,DeathCheck,_,TIMER_REPEAT);
        //CreateTimer(1.0,p90timer,_,TIMER_REPEAT);

        
    }
    return Plugin_Handled;
}

/*
public Action:p90timer(Handle:timer)
{
    if(g_bHideEnabled)
    {
        for(new target=0;target<=MaxClients;target++)
        {
            new primweapon = Client_GetWeaponBySlot(target, 0);

            if (primweapon > -1)
            {
                new String:temp[128];
                GetEntityClassname(primweapon, temp, sizeof(temp));
                if(strcmp(temp,"weapon_p90",false) == 0 || strcmp(temp,"weapon_m249",false) == 0 )
                {
                    Client_RemoveWeapon(target, temp);
                    PrintHintText(target, "You may not use P90 or Para in hide and seek."); 
                }
            }
        }
    }
}
*/



public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(g_bHideEnabled)
    {
        PrintCenterTextAll( ".: !HIDE'n'SEEK! :.\n.: !HIDE'n'SEEK! :.\n.: !HIDE'n'SEEK! :.");    
        g_fLastDeath = GetGameTime() + 10.0 + GetConVarFloat(freezetimecvar);        
    }
}



/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/



public Action:Event_BombBeginDefuse( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(g_bHideEnabled)
    {
        ServerCommand( "sm_slap #%d 1", GetClientUserId( client ) );
        ServerCommand( "sm_slap #%d 1", GetClientUserId( client ) );
        ServerCommand( "sm_slap #%d 1", GetClientUserId( client ) );
        ServerCommand( "sm_slap #%d 1", GetClientUserId( client ) );
        ServerCommand( "sm_slap #%d 1", GetClientUserId( client ) );
        ServerCommand( "sm_slap #%d 1", GetClientUserId( client ) );
        ServerCommand( "sm_slap #%d 1", GetClientUserId( client ) );
        ServerCommand( "sm_slap #%d 1", GetClientUserId( client ) );
        PrintHintText(client, "You can not defuse in hide and seek event");
    }
    return Plugin_Continue;
}

public Action:Event_BeginPlant( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(g_bHideEnabled)
    {
        PrintHintText(client, "You can not plant in hide and seek event");
        ServerCommand( "sm_slap #%d 1000", GetClientUserId( client ) );
    }
    return Plugin_Continue;
}