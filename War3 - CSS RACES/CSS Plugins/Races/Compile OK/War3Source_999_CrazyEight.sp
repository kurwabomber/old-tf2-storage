/**
* File: War3Source_999_CrazyEight.sp
* Description: CrazyEight Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <smlib>

new thisRaceID;
new SKILL_HEALTH, SKILL_AUTO, SKILL_TROPHY, ULT_ZOOM;

public Plugin:myinfo = 
{
    name = "War3Source Race - Crazy Eight",
    author = "Remy Lebeau",
    description = "Crazy Eight race for War3Source",
    version = "1.2",
    url = "http://sevensinsgaming.com"
};

// skill 1
new g_iHealth[] = {0, 5, 10, 15, 20};

// skill 2
// new Float:BashChance[5]={0.0,0.02,0.05,0.07,0.1};
// new Float:g_fBashDuration = 3.0;
new Float:g_fTrophyMultiplier[] = {0.0, 0.0125,0.015, 0.0175,  0.02};
new KillCounter[MAXPLAYERS+1];

// skill 3
new Float:g_fWeaponDuration[] = {0.0, 5.0, 7.5, 10.0, 12.5};
new Handle:WeaponTimer[MAXPLAYERS+1];


// skill 4
new String:zoom[] = "weapons/zoom.wav";
new String:on[] = "items/nvg_on.wav";
new String:off[] = "items/nvg_off.wav";
new Zoom[5] = { 0, 44, 33, 22, 11 };
new bool:Zoomed[64];
new FOV;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Crazy Eight","crazyeight");
    
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Hunting Dog","Get health back from each kill.",false,4);
    SKILL_TROPHY=War3_AddRaceSkill(thisRaceID,"Trophy Wall","The more trophies you get, the bigger your e-penis (and hence your speed)",false,4);
//    SKILL_BASH=War3_AddRaceSkill(thisRaceID,"Bash","Snare your enemies temporarily (chance on shot)",false,4);
    SKILL_AUTO=War3_AddRaceSkill(thisRaceID,"Artillery","Increase your firepower!  Temporarily pull out the auto-shottie (+ability)",false,4);
    ULT_ZOOM=War3_AddRaceSkill(thisRaceID,"Binoculars","Even shotguns can have scopes! (+ultimate)",true,4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    //War3_AddSkillBuff(thisRaceID, SKILL_BASH, fBashChance, BashChance);
}



public OnPluginStart()
{
    FOV = FindSendPropInfo( "CBasePlayer", "m_iFOV" );
	HookEvent("round_end", RoundOverEvent);  
}


public OnMapStart()
{
    War3_PrecacheSound( zoom );
    War3_PrecacheSound( on );
    War3_PrecacheSound( off );
    
    for (new i=0; i<(MAXPLAYERS+1); i++)
    {
        KillCounter[i] = 0;
    }
}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        //War3_WeaponRestrictTo( client,thisRaceID, GameCSGO() ? "weapon_smokegrenade,weapon_m3" : "weapon_smokegrenade,weapon_nova");
        //War3_SetBuff( client, fBashDuration, thisRaceID, g_fBashDuration  );
		CreateTimer(0.1,GiveWep,client);
        KillCounter[client] = 0;
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
        if (ValidPlayer(client, true) && !Client_HasWeapon(client, "weapon_knife"))
        {
            Client_GiveWeapon(client, "weapon_knife", false);
        }
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        CreateTimer(0.1,GiveWep,client);
		/*if(GameCSGO())
        {
            if(Client_HasWeapon(client, "weapon_nova"))
            {
                Client_RemoveWeapon(client, "weapon_nova");
                Client_RemoveWeapon(client, "weapon_smokegrenade");
            }
        }
        else
        {
            if(Client_HasWeapon(client, "weapon_m3"))
            {
                Client_RemoveWeapon(client, "weapon_m3");
                Client_RemoveWeapon(client, "weapon_smokegrenade");
            }
        }
		*/
        W3ResetAllBuffRace( client, thisRaceID );
        //War3_WeaponRestrictTo( client,thisRaceID, GameCSGO() ? "weapon_smokegrenade,weapon_m3" : "weapon_smokegrenade,weapon_nova");
        //CreateTimer( 2.0, GiveM3, client );
        //CreateTimer( 1.9, GiveSmoke, client );
        //War3_SetBuff( client, fBashDuration, thisRaceID, g_fBashDuration  );
        new skill_level = War3_GetSkillLevel( client, race, SKILL_TROPHY );
        new Float:speedbuff = 1 + (g_fTrophyMultiplier[skill_level] * KillCounter[client]);
        War3_SetBuff(client, fMaxSpeed, thisRaceID, speedbuff  );
        
        
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
    if( ValidPlayer( client, true ) )
    {
        if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
        {
            new ult_level = War3_GetSkillLevel( client, race, ULT_ZOOM );
            if( ult_level > 0 )
            {
                if( War3_SkillNotInCooldown( client, thisRaceID, ULT_ZOOM, true ) )
                {
                    ToggleZoom( client );
                }
            }
            else
            {
                W3MsgUltNotLeveled( client );
            }
        }
    }
}


public OnAbilityCommand( client, ability, bool:pressed )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && pressed && ValidPlayer( client, true )  && ability == 0 )
    {
        new skill_level = War3_GetSkillLevel( client, race, SKILL_AUTO );
        if( skill_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_AUTO, true ) )
            {
                Client_RemoveWeapon(client, "weapon_m3");
                
                CreateTimer( 0.1, GiveXM, client );
                WeaponTimer[client] = CreateTimer( g_fWeaponDuration[skill_level], GiveWeapon, client );
                War3_CooldownMGR( client, g_fWeaponDuration[skill_level] + 15.0, thisRaceID, SKILL_AUTO, _, true );
                    
            }
        }
        else
        {
            PrintHintText( client, "Level Your Ability First" );
        }
    }
}





/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnWar3EventDeath(victim,attacker)
{
    new race;    
    if(ValidPlayer(victim)&&ValidPlayer(attacker, true))
    {
        
        race = War3_GetRace(attacker);
        if(race==thisRaceID)
        {
            
            new skilllevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_HEALTH);
            if(skilllevel>0 && !Silenced(attacker))
            {
                
                PrintHintText(attacker,"Your hunting dog retrieves you some HP!");
                War3_HealToMaxHP(attacker, g_iHealth[skilllevel]);

            }
            
            skilllevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_TROPHY);
            if(skilllevel>0)
            {
                KillCounter[attacker]++;
            }
        }

    }
    race = War3_GetRace( victim );
    if( race == thisRaceID && ValidPlayer( victim ))
    {
        if (WeaponTimer[victim] != INVALID_HANDLE)
        {
            KillTimer(WeaponTimer[victim]);
            WeaponTimer[victim] = INVALID_HANDLE;
        }
    }
}




public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            
            if (WeaponTimer[i] != INVALID_HANDLE)
            {
                KillTimer(WeaponTimer[i]);
                WeaponTimer[i] = INVALID_HANDLE;
				Client_RemoveWeapon(i, "weapon_xm1014");
				CreateTimer( 0.1, GiveWep, i );
            }
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

stock ToggleZoom( client )
{
    if( Zoomed[client] )
    {
        StopZoom( client );
    }
    else
    {
        StartZoom( client );
    }
    EmitSoundToAll( zoom, client );
}

stock StopZoom( client )
{
    if( Zoomed[client] )
    {
        SetEntData( client, FOV, 0 );
        EmitSoundToAll( off, client );
        Zoomed[client] = false;
    }
}

stock StartZoom( client )
{
    if ( !Zoomed[client] )
    {
        new zoom_level = War3_GetSkillLevel( client, thisRaceID, ULT_ZOOM );
        SetEntData( client, FOV, Zoom[zoom_level] );
        EmitSoundToAll( on, client );
        Zoomed[client] = true;
    }
}

public Action:GiveWep( Handle:timer, any:client )
{
	new race = War3_GetRace( client );
	if( ValidPlayer( client, true ) && race == thisRaceID )
	{
		if(GameCSGO())
		{
			War3_WeaponRestrictTo( client,thisRaceID,"weapon_m3,weapon_nova");
			GivePlayerItem( client, "weapon_m3" );
			GivePlayerItem( client, "weapon_nova" );
		}
		else
		{
			War3_WeaponRestrictTo( client,thisRaceID,"weapon_m3,weapon_smokegrenade");
			GivePlayerItem( client, "weapon_m3" );
			GivePlayerItem( client, "weapon_smokegrenade" );
		}
	}
}
		
/*
public Action:GiveM3( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_RemoveWeapon(client, "weapon_xm1014");
        GivePlayerItem( client, "weapon_m3" );
    }
}


public Action:GiveSmoke( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, "weapon_smokegrenade" );
    }
}
*/

public Action:GiveXM( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_smokegrenade,weapon_xm1014");
        GivePlayerItem( client, "weapon_xm1014" );
    }
}


public Action:GiveWeapon( Handle:timer, any:client )
{
    if(ValidPlayer(client,true))
    {
        //War3_WeaponRestrictTo( client,thisRaceID, "weapon_smokegrenade,weapon_m3");
        Client_RemoveWeapon(client, "weapon_xm1014");
        CreateTimer( 0.1, GiveWep, client );
        WeaponTimer[client] = INVALID_HANDLE;
    }
}


