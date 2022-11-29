/**
* File: War3Source_999_BarrelHider.sp
* Description: Barrel Hider Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_DAMAGE, SKILL_ATTACK, ULT_BARREL;

#define WEAPON_RESTRICT "weapon_knife"
#define WEAPON_GIVE "weapon_knife"

public Plugin:myinfo = 
{
    name = "War3Source Race - Barrel Hider",
    author = "Remy Lebeau",
    description = "SeaLion's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.15, 1.2, 1.25 };
new Float:g_fDamageBoost[] = { 0.0, 0.20, 0.30, 0.4, 0.50 };
new Float:ShockChance[] = { 0.0, 0.3, 0.4, 0.5, 0.6 };
new bool:g_bUltToggle[MAXPLAYERS], bool:g_bUltEnable[MAXPLAYERS];
new Float:g_fUltCooldown[] = {0.0, 25.0, 20.0, 15.0, 10.0};
new String:g_sPlayerModel[MAXPLAYERS][129];
new m_vecBaseVelocity;
new HaloSprite, AttackSprite1, AttackSprite2;
new String:water[]="ambient/water_splash2.wav";


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Barrel Hider [PRIVATE]","barrelhider");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Rolling Barrel","Speed Increase",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Damage Of A Barrel","Damage Increase",false,4);
    SKILL_ATTACK=War3_AddRaceSkill(thisRaceID,"Bounce Of A Barrel","Chance to throw enemy in air",false,4);
    ULT_BARREL=War3_AddRaceSkill(thisRaceID,"Hide Like A Barrel","Turn into a barrel drop knife & freeze (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_BARREL,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamageBoost);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
}



public OnMapStart()
{
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    AttackSprite1 = PrecacheModel( "materials/effects/strider_pinch_dudv_dx60.vmt" );
    AttackSprite2 = PrecacheModel( "models/props_lab/airlock_laser.vmt" );
    War3_PrecacheSound( water );
    PrecacheModel("models/props_c17/woodbarrel001.mdl", true);
    PrecacheModel("models/props/de_prodigy/spoolwire.mdl", true);
    PrecacheModel("models/props_c17/metalladder001.mdl", true);
    PrecacheModel("models/props/cs_militia/militiarock05.mdl", true);
    PrecacheModel("models/props/de_dust/grainbasket01a.mdl", true);
    PrecacheModel("models/props/cs_militia/table_kitchen.mdl", true);
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
    g_bUltToggle[client] = false;
    g_bUltEnable[client] = true;
    War3_SetBuff(client,bDoNotInvisWeapon,thisRaceID,false);
    //War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);

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
    
    
    AddMenuItem(PropMenu,"models/props/de_prodigy/spoolwire.mdl","Roll of Cable",ITEMDRAW_DEFAULT);
    AddMenuItem(PropMenu,"models/props_c17/metalladder001.mdl","Ladder",ITEMDRAW_DEFAULT);
    AddMenuItem(PropMenu,"models/props_c17/woodbarrel001.mdl","Barrell",ITEMDRAW_DEFAULT);
    AddMenuItem(PropMenu,"models/props/cs_militia/militiarock05.mdl","Rock",ITEMDRAW_DEFAULT);
    AddMenuItem(PropMenu,"models/props/de_dust/grainbasket01a.mdl","Basket",ITEMDRAW_DEFAULT);
    AddMenuItem(PropMenu,"models/props/cs_militia/table_kitchen.mdl","Table",ITEMDRAW_DEFAULT);
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


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_ATTACK );
            if( skill_level > 0 && !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= ShockChance[skill_level] && !W3HasImmunity( victim, Immunity_Skills ) )
            {
                new Float:velocity[3];
                
                velocity[0] += 0;
                velocity[1] += 0;
                velocity[2] += 300.0;
                
                SetEntDataVector( victim, m_vecBaseVelocity, velocity, true );
                
                War3_ShakeScreen( victim, 3.0, 50.0, 40.0 );
                
                W3FlashScreen( victim, RGBA_COLOR_RED );
                
                new Float:start_pos[3];
                new Float:target_pos[3];
                
                GetClientAbsOrigin( attacker, start_pos );
                GetClientAbsOrigin( victim, target_pos );
                
                start_pos[2] += 20;
                target_pos[2] += 20;
                
                TE_SetupBeamPoints( start_pos, target_pos, AttackSprite1, HaloSprite, 0, 0, 1.0, 10.0, 5.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
                TE_SendToAll();
                
                TE_SetupBeamPoints( start_pos, target_pos, AttackSprite2, HaloSprite, 0, 0, 1.0, 15.0, 25.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
                TE_SendToAll( 2.0 );
            }
        }
    }
}

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

public TogglePropMode(client, bool:prop)
{
    if (ValidPlayer(client))
    {
        if(prop)
        {
            War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
            //SetThirdPersonView(client, true);
            g_bUltToggle[client] = true;
            Client_RemoveWeapon(client, "weapon_knife");
            War3_WeaponRestrictTo(client,thisRaceID,"PROP_MODE");
        }
        else
        {
            //SetThirdPersonView(client, false);
            War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
            SetEntityModel(client, g_sPlayerModel[client]);
            War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
            if (ValidPlayer(client, true))
                Client_GiveWeapon(client, WEAPON_GIVE, true); 
            g_bUltToggle[client] = false;
            
        }
    }
}

/* *********************** SetThirdPersonView *********************** */
/*public SetThirdPersonView(any:client, bool:third)
{
    if(third)
    {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
        SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
        SetEntProp(client, Prop_Send, "m_iFOV", 120);
    }
    else
    {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
        SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
        SetEntProp(client, Prop_Send, "m_iFOV", 90);
    }
}*/