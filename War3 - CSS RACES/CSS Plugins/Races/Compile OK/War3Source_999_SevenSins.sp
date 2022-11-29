/**
* File: War3Source_999_SevenSins.sp
* Description: Seven Sins Gaming's Admin's Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_EVASION, SKILL_HP, SKILL_DMG, SKILL_IMMUNITY, SKILL_AMMO;



public Plugin:myinfo = 
{
    name = "War3Source Race - Seven Sins Admins",
    author = "Remy Lebeau",
    description = "Seven Sins Admin's Race for War3Source",
    version = "1.0.3",
    url = "http://sevensinsgaming.com"
};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("SSG Admins","ssg-admins");
    
    SKILL_EVASION=War3_AddRaceSkill(thisRaceID,"Mev","Evasion (35%)",false,10);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Raven","Speed (1.7x)",false,10);
    SKILL_HP=War3_AddRaceSkill(thisRaceID,"Cone","Health (220)",false,10);
    SKILL_DMG=War3_AddRaceSkill(thisRaceID,"Sake00","Damage (55% bonus)",false,10);
    SKILL_IMMUNITY=War3_AddRaceSkill(thisRaceID,"Gamb!t","Spell Immunity (ability & ulti)",false,1);
    SKILL_AMMO=War3_AddRaceSkill(thisRaceID,"Remy Lebeau","Bonus Ammo (550)",false,10);
    
    War3_CreateRaceEnd(thisRaceID);
}


new Float:g_fSpeed[] = { 0.0, 1.1, 1.2, 1.25, 1.35, 1.40, 1.45, 1.50, 1.55, 1.60, 1.70 };
new Float:g_fEvasion[] = { 0.0, 0.035, 0.07, 0.105, 0.14, 0.175, 0.21, 0.245, 0.28, 0.315, 0.35 };
new Float:g_fDamage[] = { 0.0, 0.05, 0.1, 0.15, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55 };
new g_iHealth[] = { 0, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120 };
new g_iAmmo[] = { 0, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550 };

new bool:g_bSkillSet[MAXPLAYERS];

new g_iSkillList[MAXPLAYERS];

new Clip1Offset;
//new GlowSprite, HaloSprite;
new Handle:g_SkillMenu = INVALID_HANDLE;


public OnPluginStart()
{
    Clip1Offset = FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" );
    RegConsoleCmd("menu_changeskill", Command_ChangeSkill);
}



public OnMapStart()
{
    //GlowSprite = PrecacheModel( "materials/sprites/purpleglow1.vmt" );
    //HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    HookEvent( "weapon_reload", WeaponReloadEvent );
    g_SkillMenu = BuildSkillMenu();
    
}

public OnMapEnd()
{
    if (g_SkillMenu != INVALID_HANDLE)
    {
        CloseHandle(g_SkillMenu);
        g_SkillMenu = INVALID_HANDLE;
    }
}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


static InitPassiveSkills( client )
{
        W3ResetAllBuffRace( client, thisRaceID );

        if (g_iSkillList[client] == 0)
        {
            War3_SetBuff( client, fDodgeChance, thisRaceID, g_fEvasion[War3_GetSkillLevel( client, thisRaceID, SKILL_EVASION )] );
            War3_SetBuff( client, bDodgeMode, thisRaceID, 0 ) ;
        }
                
        if (g_iSkillList[client] == 1)
        {
            War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
        }

        if (g_iSkillList[client] == 2)
        {
            War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, g_iHealth[War3_GetSkillLevel( client, thisRaceID, SKILL_HP )]);
        }
        if (g_iSkillList[client] == 3)
        {
            War3_SetBuff( client, fDamageModifier, thisRaceID, g_fDamage[War3_GetSkillLevel( client, thisRaceID, SKILL_DMG )]);
        }
        
        if (g_iSkillList[client] == 4)
        {
            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_IMMUNITY);
            if(skill_level)
            {
                War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
                War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
            }
        }

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        
        InitPassiveSkills(client);
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
        
        if (g_bSkillSet[client] == false)
        {
            DisplayMenu(g_SkillMenu, client, MENU_TIME_FOREVER);
        }
        
        new skill_level = War3_GetSkillLevel( client, race, SKILL_AMMO );
        if((g_iSkillList[client] == 5) && (skill_level > 0))
            CreateTimer( 3.5, SetWepAmmo, client );
        
        PrintToChat(client, "\x01Say \x04Menu_ChangeSkill \x01in console to change which admin's skills you use.");
        
        InitPassiveSkills(client);
        switch (g_iSkillList[client])
        {
            case 0:
            {
                PrintToChat(client, "\x01Mev's Power: You have \x04EVASION");    
            }
            case 1:
            {
                PrintToChat(client, "\x01Raven's Power: You have \x04SPEED");    
            }
            case 2:
            {
                PrintToChat(client, "\x01Cone's Power: You have \x04HEALTH");    
            }
            case 3:
            {
                PrintToChat(client, "\x01Sake00's Power: You have \x04DAMAGE");    
            }
            case 4:
            {
                PrintToChat(client, "\x01Gamb!t's Power: You have \x04IMUNNITY");    
            }
            case 5:
            {
                PrintToChat(client, "\x01Remy's Power: You have \x04AMMO");    
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






/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public WeaponReloadEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID && (g_iSkillList[client] == 5))
    {
        new skill_level = War3_GetSkillLevel( client, race, SKILL_AMMO );
        if( skill_level > 0 )
        {
            CreateTimer( 3.5, SetWepAmmo, client );
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

public Action:SetWepAmmo( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        new skill_level = War3_GetSkillLevel( client, race, SKILL_AMMO );
        new wep_ent = W3GetCurrentWeaponEnt( client );
        SetEntData( wep_ent, Clip1Offset, g_iAmmo[skill_level], 4 );
        
    }
}


Handle:BuildSkillMenu()
{
    new Handle:menu = CreateMenu(Menu_ChangeSkill);

    AddMenuItem(menu, "mev", "Mev");
    AddMenuItem(menu, "raven", "Raven");
    AddMenuItem(menu, "cone", "Cone");
    AddMenuItem(menu, "sake", "Sake00");
    AddMenuItem(menu, "gambit", "Gamb!t");
    AddMenuItem(menu, "remy", "Remy Lebeau");

    SetMenuTitle(menu, "Select what admin's skill you want:");
 
    return menu;
}

public Menu_ChangeSkill(Handle:menu, MenuAction:action, client, selection)
{
    if (action == MenuAction_Select)
    {
        new String:info[32];
 
        /* Get item info */
        new bool:found = GetMenuItem(menu, selection, info, sizeof(info));
        PrintToConsole(client, "You selected item: %d (found? %d info: %s)", selection, found, info);
        
        g_iSkillList[client] = selection;
        if (g_bSkillSet[client] == false)
        {
            InitPassiveSkills(client);
        }
        g_bSkillSet[client] = true;
        
    }
}

public Action:Command_ChangeSkill(client, args)
{
    DisplayMenu(g_SkillMenu, client, MENU_TIME_FOREVER);
    
 
    return Plugin_Handled;
}