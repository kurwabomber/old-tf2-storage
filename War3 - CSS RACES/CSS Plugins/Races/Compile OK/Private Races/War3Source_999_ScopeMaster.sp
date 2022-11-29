/**
* File: War3Source_999_ScopeMaster.sp
* Description: Scope Master Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_WEAPON, SKILL_SPEED, SKILL_LOWGRAV, ULT_MENU;

#define WEAPON_RESTRICT "weapon_knife"
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Scope Master",
    author = "Remy Lebeau",
    description = "Kablamo's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.2, 1.25, 1.3, 1.35, 1.4 };
new Float:LevitationGravity[] = {1.0, 0.85, 0.7, 0.6, 0.5, 0.45};
new Float:g_fUltCooldown[] = {0.0, 10.0, 5.0};




public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Scope Master [PRIVATE]","scopemaster");
    
    SKILL_WEAPON=War3_AddRaceSkill(thisRaceID,"Better Scopes","Scout/Auto/Auto/AWP",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Mofo Speed","Speed Increase",false,5);
    SKILL_LOWGRAV=War3_AddRaceSkill(thisRaceID,"Feather Weight","Lower Gravity",false,5);
    ULT_MENU=War3_AddRaceSkill(thisRaceID,"Change Scope","Menu to spawn different gun (+ultimate)",true,2);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_LOWGRAV, fLowGravitySkill, LevitationGravity);

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
    new primweapon = Client_GetWeaponBySlot(client, 0);
    
    if (primweapon > -1)
    {
        new String:temp[128];
        GetEntityClassname(primweapon, temp, sizeof(temp));
        Client_RemoveWeapon(client, temp);
    }
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);

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
        DoArmouryMenu(client);
    }
}







/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && ValidPlayer( client,true ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_MENU );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_MENU, true ))
            {
                DoArmouryMenu(client);
                War3_CooldownMGR( client, g_fUltCooldown[ult_level], thisRaceID, ULT_MENU, _, _ );
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}





public DoArmouryMenu(client)
{
    new Handle:ArmouryMenu=CreateMenu(War3Source_ArmouryMenu_Selected);
    SetMenuPagination(ArmouryMenu,MENU_NO_PAGINATION);
    SetMenuTitle(ArmouryMenu,"==SELECT YOUR WEAPON==");
    SetMenuExitButton(ArmouryMenu,true);
    
    new skill_armoury = War3_GetSkillLevel(client,thisRaceID,SKILL_WEAPON);
    
    AddMenuItem(ArmouryMenu,"weapon_scout","Scout",(skill_armoury>0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    AddMenuItem(ArmouryMenu,"weapon_sg550","Auto Sniper sg550",(skill_armoury>1)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    AddMenuItem(ArmouryMenu,"weapon_g3sg1","Auto Sniper gsg31",(skill_armoury>2)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    AddMenuItem(ArmouryMenu,"weapon_awp","Awp",(skill_armoury>3)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    DisplayMenu(ArmouryMenu,client,MENU_TIME_FOREVER);
}

public War3Source_ArmouryMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
        {
            decl String:newRestrict[64];
            decl String:weaponName[32];
            decl String:SelectionDispText[256];
            new SelectionStyle;
            
            GetMenuItem(menu,selection,weaponName,sizeof(weaponName),SelectionStyle,SelectionDispText,sizeof(SelectionDispText));
            Format(newRestrict,64,"weapon_knife,%s",weaponName);

            new primweapon = Client_GetWeaponBySlot(client, 0);
            
            if (primweapon > -1)
            {
                new String:temp[128];
            
                GetEntityClassname(primweapon, temp, sizeof(temp));
            
                Client_RemoveWeapon(client, temp);
            }
            
            War3_WeaponRestrictTo(client,thisRaceID,newRestrict,2);
            
            GivePlayerItem(client,weaponName);
        }
    }

    if(action==MenuAction_End)
    {
        CloseHandle(menu);
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

