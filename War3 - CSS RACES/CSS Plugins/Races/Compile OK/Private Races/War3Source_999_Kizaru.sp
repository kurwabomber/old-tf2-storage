/**
* File: War3Source_999_Kizaru.sp
* Description: Kizaru Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_INVIS, SKILL_SPEED, SKILL_REGEN, ULT_MENU;

#define WEAPON_RESTRICT ""
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Kizaru",
    author = "Remy Lebeau",
    description = "Sincro's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.15, 1.2, 1.25, 1.3 };
new Float:InvisibilityAlphaCS[]={1.0,0.9,0.8,0.7,0.6,0.5};
new Float:g_fRegen[] = {0.0, 1.0, 2.0, 3.0, 4.0};
new Float:g_fUltCooldown[] = {0.0, 10.0, 5.0};


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Kizaru [PRIVATE]","kizaru");
    
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Heavenly Illumination","Kizaru ate the 'Light' Devil Fruit, which makes him difficult to see.",false,5);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Eight Span Mirror","The fruit made Kizaru a Light-man. He can move at the speed of light.",false,5);
    SKILL_REGEN=War3_AddRaceSkill(thisRaceID,"Logia Regeneration","The Light fruit is a Logia-type. Logia fruit eaters regenerate quickly.",false,4);
    ULT_MENU=War3_AddRaceSkill(thisRaceID,"Gathering Clouds of Heaven","Kizaru is able to create 'Light' weapons.",true,2);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_INVIS, fInvisibilitySkill, InvisibilityAlphaCS);
    War3_AddSkillBuff(thisRaceID, SKILL_REGEN, fHPRegen, g_fRegen);

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
    
    
    AddMenuItem(ArmouryMenu,"weapon_m4a1","M4A1",ITEMDRAW_DEFAULT);
    AddMenuItem(ArmouryMenu,"weapon_ak47","AK - 47",ITEMDRAW_DEFAULT);
    AddMenuItem(ArmouryMenu,"weapon_awp","AWP",ITEMDRAW_DEFAULT);
    DisplayMenu(ArmouryMenu,client,MENU_TIME_FOREVER);
}

public War3Source_ArmouryMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
        {
            //decl String:newRestrict[64];
            decl String:weaponName[32];
            decl String:SelectionDispText[256];
            new SelectionStyle;
            
            GetMenuItem(menu,selection,weaponName,sizeof(weaponName),SelectionStyle,SelectionDispText,sizeof(SelectionDispText));
            //Format(newRestrict,64,"weapon_knife,%s",weaponName);
            
            //War3_WeaponRestrictTo(client,thisRaceID,newRestrict,2);
            
            new primweapon = Client_GetWeaponBySlot(client, 0);
            
            if (primweapon > -1)
            {
                new String:temp[128];
                GetEntityClassname(primweapon, temp, sizeof(temp));
                Client_RemoveWeapon(client, temp);
            }
            
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

