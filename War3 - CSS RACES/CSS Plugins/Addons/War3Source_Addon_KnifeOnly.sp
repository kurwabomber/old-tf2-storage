 /**
* File: War3Source_Addon_KnifeOnly.sp
* Description: Restricts all players to knife only, limits certain races.
* Author(s): Remy Lebeau
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include <smlib>

public Plugin:myinfo = 
{
    name = "War3Source Addon - Knife Only",
    author = "Remy Lebeau",
    description = "Restricts all players to knife only, limits certain races",
    version = "1.2.1",
    url = "sevensinsgaming.com"
};

new Handle:g_hRaceMenu = INVALID_HANDLE;

new Handle:g_hRaceAccessLists = INVALID_HANDLE;
new bool:g_bKnifeOnlyEnabled;
new fakeRaceID;


public OnWar3PluginReady()
{
    fakeRaceID=War3_CreateNewRace("Fake Race[FAKE]","fakerace");

    War3_CreateRaceEnd(fakeRaceID);
    
}

public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
    RegAdminCmd("war3_ko_reload_restricted_races",Command_KO_Reload, ADMFLAG_SLAY,"Reloads the restricted race file");
    RegAdminCmd("war3_ko_toggle", Command_KO_Toggle, ADMFLAG_SLAY, "Toggles Knife Only on/off.");
    RegAdminCmd("war3_ko_race_menu",Command_KO_Menu, ADMFLAG_SLAY,"Shows a list of current restricted races\nSelect a race to remove it");
    RegAdminCmd("war3_ko_fix", Command_KO_Fix, ADMFLAG_SLAY, "Resets the weapon restrictions manually.");
    ReloadRaces();    

}
public OnAllPluginsLoaded()
{
   if (g_hRaceMenu != INVALID_HANDLE)
   {
        CloseHandle(g_hRaceMenu);
        g_hRaceMenu = INVALID_HANDLE;
   }
   g_hRaceMenu = CreateMenu(Menu_RestrictedRaces);
}

public OnMapStart()
{
    g_bKnifeOnlyEnabled = false;
    new String:temp[150];
    GetCurrentMap(temp, sizeof(temp));
    if( StrEqual( temp, "fy_iceworld_next",false ))
    {
        ReloadRaces();
        g_bKnifeOnlyEnabled = true;
        CreateTimer(3.0,dosetdisabledcategories);
    }
    if( StrEqual( temp, "aim_deagle8k",false ))
    {
        ReloadRaces();
        g_bKnifeOnlyEnabled = true;
        CreateTimer(3.0,dosetdisabledcategories);
    }
}
public Action:dosetdisabledcategories(Handle:timer,any:client)
{
    setdisabledcategories();
}
public OnMapEnd()
{
    g_bKnifeOnlyEnabled = false;
    for (new i=1; i<=MAXPLAYERS; i++)
    {
        if(ValidPlayer(i))
        {
            War3_WeaponRestrictTo( i, fakeRaceID, "" );
        }
    }
    
}   

/***************************************************************************
*
*
*                KNIFE RESTRICTION MANAGEMENT FUNCTIONS
*
*
***************************************************************************/


public Action:Command_KO_Toggle(client, args)
{
    if (g_bKnifeOnlyEnabled)
    {
        g_bKnifeOnlyEnabled = false;
        printPluginMessageAll("Knife Only has been disabled.");
        for (new i=1; i<=MAXPLAYERS; i++)
        {
            if(ValidPlayer(i))
            {
                War3_WeaponRestrictTo( client, fakeRaceID, "" );
            }
        }
        resetsetdisabledcategories();
    }
    else
    {
        g_bKnifeOnlyEnabled = true;
        printPluginMessageAll("Knife Only has been enabled, and will begin next round.");
        ReloadRaces();
        setdisabledcategories();
    }
    
    return Plugin_Handled;
}


public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (g_bKnifeOnlyEnabled)
    {
        printPluginMessageAll("Knife Only Mode Active - Restrictions are in place");
    }
}


public OnWar3EventSpawn( client )
{
    if (g_bKnifeOnlyEnabled)
    {
        new race_selected=War3_GetRace( client );

        if (GetArraySize(g_hRaceAccessLists) > 0 )
        {
            new index = FindValueInArray(g_hRaceAccessLists,race_selected);
            if(index != -1) 
            {
                new humanID = War3_GetRaceIDByShortname("human");
                War3_SetRace(client,humanID);
                printPluginMessage(client, "Can't access this race while in knife only mode");
            }
        }
        War3_WeaponRestrictTo( client, fakeRaceID, "weapon_knife" );
        
    }
    else
    {
        War3_WeaponRestrictTo( client, fakeRaceID, "" );
    }
}


public Action:Command_KO_Fix(client, args)
{
    for (new i=1; i<=MAXPLAYERS; i++)
    {
        if(ValidPlayer(i))
        {
            printPluginMessage(i, "Fixing weapon restrictions");
            War3_WeaponRestrictTo( i, fakeRaceID, "" );
        }
    }
}

/***************************************************************************
*
*
*                RESTRICTED RACE MANAGEMENT FUNCTIONS
*
*
***************************************************************************/


public Action:Command_KO_Reload(client, args) 
{
    if(!ReloadRaces()) {
        ReplyToCommand(client, "Unable to reload race list! Please check the formatting.");
    } else {
        ReplyToCommand(client, "Knife Only restricted race list reloaded successfully!");
    }
    return Plugin_Handled;
}

bool:ReloadRaces() 
{
    new String:file[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, file, sizeof(file), "configs/war3source_knifeonly_restrictraces.cfg");
    
    if (FileExists(file))
    {
        new Handle:accesslist = CreateKeyValues("Races");
        FileToKeyValues(accesslist, file);
        ParseKeyValues(accesslist);
        CloseHandle(accesslist);
    } else {
        return false;
    }
    return true;
}




ParseKeyValues(Handle:accesslist) {


    if(g_hRaceAccessLists == INVALID_HANDLE) {
        g_hRaceAccessLists = CreateArray(4);
    } else {
        ClearArray(g_hRaceAccessLists);
    }
    KvRewind(accesslist);
    KvGotoFirstSubKey(accesslist);
        
    new String:sRaceShortName[16];


    if(KvGotoFirstSubKey(accesslist, false)) {
        do
        {
            KvGetSectionName(accesslist, sRaceShortName, sizeof(sRaceShortName));
            if(War3_GetRaceIDByShortname(sRaceShortName))
            {
                PushArrayCell(g_hRaceAccessLists, War3_GetRaceIDByShortname(sRaceShortName));
            }
        } while(KvGotoNextKey(accesslist, false));
    }
}


public OnW3Denyable(W3DENY:event, client)
{
    if(event==DN_CanSelectRace)
    {
        new race_selected=W3GetVar(EventArg1);
        if(fakeRaceID == race_selected)
        {
            W3Deny();
        }
        if(g_bKnifeOnlyEnabled)
        {

            decl String:rcvar[64];  
            W3GetCvar(W3GetRaceCell(race_selected,RaceCategorieCvar),rcvar,sizeof(rcvar));
            if(strcmp(rcvar, "Private", false) == 0)
            {
                W3Deny();
                printPluginMessage(client, "Can't access this race while in knife only mode");
            }
            
            new index = FindValueInArray(g_hRaceAccessLists,race_selected);
            if(index != -1) {
                    W3Deny();
                    printPluginMessage(client, "Can't access this race while in knife only mode");
            }
        }
        
    }
}

public Action:Command_KO_Menu(client, args) 
{
//    g_hRaceMenu = CreateMenu(Menu_RestrictedRaces);
    new temp;
    new String:buffer[16];
    SetMenuTitle(g_hRaceMenu, "KO Restricted Races");
    for(new i=0; i<GetArraySize(g_hRaceAccessLists); i++ )
    {
        temp = GetArrayCell(g_hRaceAccessLists, i);
        War3_GetRaceShortname(temp,buffer,sizeof(buffer));
        AddMenuItem(g_hRaceMenu, buffer, buffer);
    }

    DisplayMenu(g_hRaceMenu, client, MENU_TIME_FOREVER);
 
    return Plugin_Handled;
}

public Menu_RestrictedRaces(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        new String:info[16];
 
        /* Get item info */
        new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
        new race_selected = War3_GetRaceIDByShortname(info);
        new index = FindValueInArray(g_hRaceAccessLists,race_selected);
        RemoveFromArray(g_hRaceAccessLists, index);
        resetsetdisabledcategories();
        setdisabledcategories();
        
        /* Tell the client */
        PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
        new String:pluginString[100];
        Format(pluginString,sizeof(pluginString),"{red}%s {default}temporarily removed from restricted list", info);
        printPluginMessage(param1, pluginString);
        RemoveMenuItem(g_hRaceMenu, param2);
        
        DisplayMenuAtItem(g_hRaceMenu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
 
    }
    /* If the menu has ended, destroy it */
//    else if (action == MenuAction_End)
//    {
//        CloseHandle(menu);
 //   }
    
}



/***************************************************************************
*
*
*                AUTO ENABLE FOR SPECIFIC MAPS FUNCTIONS
*
*
***************************************************************************/

static setdisabledcategories()
{
    new String:buffer[16];
    new temp;
    for(new i=0; i<GetArraySize(g_hRaceAccessLists); i++ )
    {
        temp = GetArrayCell(g_hRaceAccessLists, i);
        War3_GetRaceShortname(temp,buffer,sizeof(buffer));
        ServerCommand("war3 %s_category Disabled", buffer);
    }
    ServerCommand("war3_reloadcats");
}

static resetsetdisabledcategories()
{
    ServerCommand("exec war3source.cfg");
}

static printPluginMessage(client, String:message[])
{
    new String:pluginString[512] = "{green}[Knife Only Plugin] {default}";
    StrCat(pluginString, sizeof(pluginString), message);
    CPrintToChat(client, pluginString);
}

static printPluginMessageAll(String:message[])
{
    new String:pluginString[512] = "{green}[Knife Only Plugin] {default}";
    StrCat(pluginString, sizeof(pluginString), message);
    CPrintToChatAll(pluginString);
}
