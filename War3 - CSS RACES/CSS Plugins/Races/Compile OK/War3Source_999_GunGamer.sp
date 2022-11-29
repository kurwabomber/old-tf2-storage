/**
* File: War3Source_999_GunGamer.sp
* Description: GunGamer Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_GG, SKILL_SPEED, SKILL_INVIS, SKILL_HEALTH;



public Plugin:myinfo = 
{
    name = "War3Source Race - GunGamer",
    author = "Remy Lebeau",
    description = "GunGamer race for War3Source",
    version = "1.1",
    url = "http://sevensinsgaming.com"
};

#define SPRITE_CSS      "sprites/orangeglow1.vmt"

new String:g_sWeaponList[24][] = {"weapon_awp", "weapon_scout", "weapon_m249", 
"weapon_aug", "weapon_m4a1", "weapon_sg552", 
"weapon_ak47", "weapon_famas", "weapon_galil", 
"weapon_p90", "weapon_ump45", "weapon_mp5navy", 
"weapon_mac10", "weapon_tmp", "weapon_xm1014", 
"weapon_m3", "weapon_elite", "weapon_fiveseven", 
"weapon_deagle", "weapon_p228", "weapon_usp", 
"weapon_glock", "weapon_hegrenade", "weapon_knife"};

new Float:g_fSpeed[] = { 0.0, 0.01, 0.02, 0.03, 0.03, 0.05  };
new Float:g_fInvis[] = { 0.0, 0.01, 0.02, 0.03, 0.04, 0.05 };
new g_iHealth[]={ 0, 1, 2, 3, 4, 5 };
new g_GlowSprite            = -1;
new bool:g_bReverseOrder[MAXPLAYERS];
new g_iClientLevel[MAXPLAYERS];


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("GunGamer","gungamer");
    
    SKILL_GG=War3_AddRaceSkill(thisRaceID,"Gun Game","Each kill gets you a new weapon.",false,1);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","Each kill makes you go faster.",false,5);
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Visibility","Each kill makes you a little more invisible.",false,5);
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Health","Each kill gets you more health.",false,5);
    
    War3_CreateRaceEnd(thisRaceID);
    

}


public OnPluginStart()
{

}



public OnMapStart()
{
    g_GlowSprite = PrecacheModel(SPRITE_CSS);
}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public InitWeapons(client)
{
    if (ValidPlayer(client, true))
    {
        new skill_gg = War3_GetSkillLevel( client, thisRaceID, SKILL_GG );
        if (skill_gg == 1)
        {
            War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
            if (g_iClientLevel[client]<23)
            {
                new String:temp[64] = "weapon_knife,";
                StrCat(temp, 64, g_sWeaponList[g_iClientLevel[client]]);
                War3_WeaponRestrictTo( client,thisRaceID, temp);
                CreateTimer(0.2,giveWeapon,client);    
            }    
            CPrintToChat(client,"{red}GunGame {default} You are level %i.", g_iClientLevel[client]);
        }
        else
        {
            CPrintToChat(client,"{red}GunGame {default} Put a level into the GG skill to begin your GG adventure!");
        }
    }

}


public InitPassiveSkills( client )
{
    if (ValidPlayer(client, true))
    {
        new skill_gg = War3_GetSkillLevel( client, thisRaceID, SKILL_GG );
        new skill_speed = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
        new skill_invis = War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS );
        new skill_health = War3_GetSkillLevel( client, thisRaceID, SKILL_HEALTH );
        
        if (skill_gg == 1)
        {
            War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, RoundToFloor(g_iHealth[skill_health] * (g_iClientLevel[client]/2.0)) );
            War3_SetBuff( client, fMaxSpeed, thisRaceID, (1 + (g_fSpeed[skill_speed] * (g_iClientLevel[client]/2)))  );
            War3_SetBuff( client, fInvisibilitySkill, thisRaceID, (1 - g_fInvis[skill_invis] * (g_iClientLevel[client]/2))  );
        }
    }
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer(client))
    {
        g_iClientLevel[client] = 0;
        g_bReverseOrder[client]=false;
        if(ValidPlayer( client, true ))
        {
            InitPassiveSkills( client );
            InitWeapons(client);
        }
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
        if(!g_bReverseOrder[client])
        {
            InitPassiveSkills( client );
        }
        InitWeapons(client);

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


public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim) && attacker!=victim)
    {
        new race = War3_GetRace(attacker);
        if(race==thisRaceID)
        {
            if(!g_bReverseOrder[attacker])
            {
                if (g_iClientLevel[attacker] == 23)
                {
                    g_bReverseOrder[attacker] = true;
                    CPrintToChat(attacker,"{red}GunGame {default} You WON GunGame!  As a reward, you get to reverse it.");
                    g_iClientLevel[attacker]--;
                    InitWeapons(attacker);
                }
                else if (g_iClientLevel[attacker] < 23)
                {
                    Client_RemoveWeapon(attacker, g_sWeaponList[g_iClientLevel[attacker]]);
                    g_iClientLevel[attacker]++;
                    InitPassiveSkills( attacker );
                    InitWeapons(attacker);
                    new Float:vec[3];
                    GetClientAbsOrigin(attacker, vec);
                    vec[2] += 40;
                    
                    TE_SetupGlowSprite(vec, g_GlowSprite, 0.5, 4.0, 70);
                    TE_SendToAll();
                    //CreateTimer(0.2,giveWeapon,attacker);
                    //Client_PrintToChat(attacker,false,"{R}GunGame {default} You are level %i.", g_iClientLevel[attacker]);
                }
                else if (g_iClientLevel[attacker] > 23)
                {
                    // SOMETHING WENT WRONG!  PUT LEVEL BACK DOWN TO 23 AND LOG AN ERROR
                }
            }
            else
            {
                if (g_iClientLevel[attacker] == 0)
                {
                    War3_WeaponRestrictTo(attacker,thisRaceID,"");
                    CPrintToChat(attacker,"{red}GunGame {default} You REALLY WON GunGame!  As a reward, weapons restrictions are removed.");
                    g_iClientLevel[attacker]--;
                    
                }
                else if (g_iClientLevel[attacker] > 0)
                {
                    Client_RemoveWeapon(attacker, g_sWeaponList[g_iClientLevel[attacker]]);
                    g_iClientLevel[attacker]--;
                    InitWeapons(attacker);
                    new Float:vec[3];
                    GetClientAbsOrigin(attacker, vec);
                    vec[2] += 40;
                    
                    TE_SetupGlowSprite(vec, g_GlowSprite, 0.5, 4.0, 70);
                    TE_SendToAll();

                }
                else if (g_iClientLevel[attacker] < 0)
                {
                    // DO NOTHING
                }
            }
        }

    }
}


public OnWeaponFired(client)
{	
	if (War3_GetRace(client) == thisRaceID && ValidPlayer(client, true))
	{
		new String:weapon[128];//weapon Char Array
		GetClientWeapon(client, weapon, 128);
		if(StrEqual(weapon,"weapon_hegrenade"))
		{
			CreateTimer(1.5, UseGrenade, client);
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

public Action:giveWeapon(Handle:timer,any:client)
{
    if (ValidPlayer(client, true))
    {
        GivePlayerItem( client, g_sWeaponList[g_iClientLevel[client]]);
    }
}


public Action:UseGrenade(Handle:timer, any:client)
{
	if (ValidPlayer(client, true))
	{
		if (War3_GetRace(client) == thisRaceID)
		{
			new skill_gg = War3_GetSkillLevel( client, thisRaceID, SKILL_GG );
			if (skill_gg == 1)
			{
				
				GivePlayerItem(client, "weapon_hegrenade");
				FakeClientCommand(client, "use weapon_hegrenade");
			}
		}
	}
}
