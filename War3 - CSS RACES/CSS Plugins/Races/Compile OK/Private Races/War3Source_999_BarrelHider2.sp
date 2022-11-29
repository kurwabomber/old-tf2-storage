/**
* File: War3Source_999_BarrelHider2.sp
* Description: Barrel Hider Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_DAMAGE, SKILL_HEALTH, ULT_BARREL;

#define WEAPON_RESTRICT "weapon_deagle,weapon_knife"
#define WEAPON_GIVE "weapon_deagle"
#define KNIFE_GIVE "weapon_knife"

public Plugin:myinfo = 
{
    name = "War3Source Race - Barrel Hider",
    author = "Remy Lebeau",
    description = "SeaLion's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4};
new g_iHealth[]={0,10,20,30,40};
new Float:g_fDamageBoost[] = { 0.0, 0.05, 0.1, 0.15, 0.2 };
new String:water[]="ambient/water_splash2.wav";
new String:g_sOildrum[]="models/props_c17/oildrum001.mdl";
new String:g_sPotPlant[]="models/props/cs_office/plant01.mdl";
new String:g_sChair[]="models/props/cs_office/Chair_office.mdl";
new String:g_sLampPost[]="models/props_c17/lamppost03a_off.mdl";
new String:g_sTree[]="models/props_foliage/tree_deciduous_01a-lod.mdl";

new bool:g_bUltToggle[MAXPLAYERS], bool:g_bUltEnable[MAXPLAYERS];
new Float:g_fUltCooldown[] = {0.0, 25.0, 20.0, 15.0, 10.0};
new String:g_sPlayerModel[MAXPLAYERS][129];

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Barrel Hider 2 [PRIVATE]","barrelhider2");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed Like No Other Barrel","Speed Increase",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Damage Like No Other Barrel","Damage Increase",false,4);
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Health Like No Other Barrel","Extra Health",false,4);
    ULT_BARREL=War3_AddRaceSkill(thisRaceID,"Lets Play Hide & Seek","Transform Into Prop (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_BARREL,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, g_iHealth);
    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamageBoost);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{
    War3_PrecacheSound( water );
    PrecacheModel(g_sOildrum, true);
    PrecacheModel(g_sPotPlant, true);
    PrecacheModel(g_sChair, true);
    PrecacheModel(g_sLampPost, true);
    PrecacheModel(g_sTree, true);
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
    CreateTimer( 1.0, GiveWep, client );
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    g_bUltToggle[client] = false;
    g_bUltEnable[client] = true;
    War3_SetBuff(client,bDoNotInvisWeapon,thisRaceID,false);

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
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_BARREL );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_BARREL, true ) && g_bUltEnable[client])
            {
                if(g_bUltToggle[client])
                {
                    // RETURN TO HUMAN
                    TogglePropMode(client, false);
                    War3_CooldownMGR( client, g_fUltCooldown[ult_level], thisRaceID, ULT_BARREL, _, _ );

                }
                else
                {
                    // MAKE BARREL
                    
                    DoPropMenu(client);
                    

                }
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}




public DoPropMenu(client)
{
    new Handle:PropMenu=CreateMenu(War3Source_PropMenu_Selected);
    SetMenuPagination(PropMenu,MENU_NO_PAGINATION);
    SetMenuTitle(PropMenu,"==SELECT YOUR PROP==");
    SetMenuExitButton(PropMenu,true);
    
    
    AddMenuItem(PropMenu,g_sOildrum,"Oil Drum",ITEMDRAW_DEFAULT);
    AddMenuItem(PropMenu,g_sPotPlant,"Pot Plant",ITEMDRAW_DEFAULT);
    AddMenuItem(PropMenu,g_sChair,"Chair",ITEMDRAW_DEFAULT);
    AddMenuItem(PropMenu,g_sLampPost,"Lamp Post",ITEMDRAW_DEFAULT);
    AddMenuItem(PropMenu,g_sTree,"Tree",ITEMDRAW_DEFAULT);
    DisplayMenu(PropMenu,client,MENU_TIME_FOREVER);
}



public War3Source_PropMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
        {
            decl String:propName[64];
            decl String:SelectionDispText[256];
            new SelectionStyle;
            
            GetMenuItem(menu,selection,propName,sizeof(propName),SelectionStyle,SelectionDispText,sizeof(SelectionDispText));
           
            decl String:modelName[128];
            GetClientModel(client, modelName, sizeof(modelName));
            strcopy(g_sPlayerModel[client], sizeof(modelName), modelName);
            EmitSoundToAll(water,client);
            
            SetEntityModel(client, propName); // PROP NAME
            
            TogglePropMode(client, true);

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


public OnWar3EventDeath( victim, attacker )
{
    if(ValidPlayer(victim) && (War3_GetRace( victim ) == thisRaceID) )
    {
        //SetThirdPersonView(victim, false);
        War3_SetBuff( victim, bNoMoveMode, thisRaceID, false );
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
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            g_bUltEnable[i] = false;
            TogglePropMode(i, false);
        }
    }
}

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem(client, WEAPON_GIVE);
        GivePlayerItem(client, KNIFE_GIVE);
    }
}


public TogglePropMode(client, bool:prop)
{
    if (ValidPlayer(client))
    {
        if(prop)
        {
            War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
			//SetThirdPersonView(client, true);
            g_bUltToggle[client] = true;
            Client_RemoveWeapon(client, "weapon_deagle");
            Client_RemoveWeapon(client, "weapon_knife");
            War3_WeaponRestrictTo(client,thisRaceID,"PROP_MODE");
        }
        else
        {
            //SetThirdPersonView(client, false);
            War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
            CreateTimer( 0.5, EnableShoot, client );
            SetEntityModel(client, g_sPlayerModel[client]);
            g_bUltToggle[client] = false;
            
        }
    }
}

public Action:EnableShoot( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client ) && race == thisRaceID )
    {
        War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
        if (ValidPlayer(client, true))
            GivePlayerItem(client, WEAPON_GIVE); 
    }
}

/* *********************** SetThirdPersonView *********************** */
// public SetThirdPersonView(any:client, bool:third)
// {
    // if(third)
    // {
        // SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
        // SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
        // SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
        // SetEntProp(client, Prop_Send, "m_iFOV", 120);
    // }
    // else
    // {
        // SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
        // SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
        // SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
        // SetEntProp(client, Prop_Send, "m_iFOV", 90);
    // }
// }