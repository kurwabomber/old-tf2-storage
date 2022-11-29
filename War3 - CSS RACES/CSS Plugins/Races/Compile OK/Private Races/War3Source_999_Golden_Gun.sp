/**
* File: War3Source_999_Golden_Gun.sp
* Description: Golden Gun Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <smlib>

new thisRaceID;
new SKILL_GUN, SKILL_INVIS, SKILL_SPEED;



public Plugin:myinfo = 
{
	name = "War3Source Race - Golden Gun",
	author = "Remy Lebeau",
	description = "Golden Gun race for War3Source",
	version = "0.9",
	url = "http://sevensinsgaming.com"
};



new InvisTime[]={ 0, 50, 40, 30, 20 };
new m_vecVelocity = -1;
new Float:canspeedtime[MAXPLAYERS+1];
new AcceleratorDelayer[MAXPLAYERS];
new bool:InvisTrue[MAXPLAYERS];
new Float:g_fSpeed[] = {1.0, 1.2, 1.3, 1.4, 1.6};

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Golden Gun [PRIVATE]","golden_gun");
	
	SKILL_GUN=War3_AddRaceSkill(thisRaceID,"Golden Gun","1 Gun, 1 Bullet, 1 Kill.",false,1);
	SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Bide your time","With only 1 bullet, you have to make it count!  (Go invis when you stand still)",false,4);
	SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","If you can't kill em, run the hell away!",false,4);
	
	War3_CreateRaceEnd(thisRaceID);
	
	
	War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
	
}







public OnPluginStart()
{
	m_vecVelocity = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	
	CreateTimer(0.1, CalcSpeed,_,TIMER_REPEAT);
}


public OnMapStart()
{

}
	

/***************************************************************************
*
*
*				PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public InitPassiveSkills( client )
{
    GivePlayerItem( client, "weapon_usp" );
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_usp");
    new skill_gun = War3_GetSkillLevel( client, thisRaceID, SKILL_GUN );
    if( skill_gun > 0 )
    {
        War3_SetBuff( client, fDamageModifier, thisRaceID, 1000.0 );
        War3_SetBuff( client, iDamageBonus, thisRaceID, 1000 );
        War3_SetBuff( client, iDamageMode, thisRaceID, 1 );
        CreateTimer( 1.0, SetWepAmmo, client );
        
    }
    InvisTrue[client] = false;
           
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
    if( race == thisRaceID )
    {
        W3ResetAllBuffRace( client, thisRaceID );
        InitPassiveSkills( client );
        
        new skill_gun = War3_GetSkillLevel( client, thisRaceID, SKILL_GUN );
        if( skill_gun > 0 )
        {

        }
    }
}




/***************************************************************************
*
*
*				ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/






/***************************************************************************
*
*
*				EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnWar3EventDeath(victim, attacker)
{
    if (War3_GetRace(attacker) == thisRaceID && ValidPlayer(attacker, true))
    {
        Client_SetWeaponAmmo(attacker, "weapon_usp", 0,0,1,0);

    } 
}



public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
    if(ValidPlayer(client,true,true)&& War3_GetRace(client)==thisRaceID)
    {
        new String:wepName[64];
        GetEntityClassname(weaponIndex, wepName, 64);
        if (StrEqual(wepName, "weapon_usp", false) )	
            {
            
    	        PrintToChat (client, "You may not drop your gun on this race");	
    	        ServerCommand( "sm_slay #%d", GetClientUserId( client ) );
    	    }
	}
}




/***************************************************************************
*
*
*				HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/


public Action:SetWepAmmo( Handle:timer, any:client )
{
    Client_SetWeaponAmmo(client, "weapon_usp", 0,0,1,0);
}


public Action:CalcSpeed(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID)
		{
			new skill_speed = War3_GetSkillLevel(i,thisRaceID,SKILL_INVIS);
			if(canspeedtime[i] < GetGameTime() && skill_speed > 0 )
			{
				// PrintToChat(i, "Standing still, invis in |%d|",AcceleratorDelayer[i]);
				AcceleratorDelayer[i]++;
				if(AcceleratorDelayer[i] == InvisTime[skill_speed])
				{
					if (InvisTrue[i] == false)
					{
						War3_SetBuff( i, bDisarm, thisRaceID, true  );
						War3_SetBuff( i, fInvisibilitySkill, thisRaceID, 0.0  );
						War3_SetBuff( i,bDoNotInvisWeapon,thisRaceID,false);
						W3Hint(i,HINT_LOWEST,1.0,"Hidding! (Can't shoot)");
						AcceleratorDelayer[i] = 0;
						InvisTrue[i] = true;
					}
				}
				
			}
			else
			{
				if(InvisTrue[i] == true)
				{
					W3Hint(i,HINT_LOWEST,1.0,"No longer hidden");
					War3_SetBuff( i, bDisarm, thisRaceID, false  );
					War3_SetBuff( i, fInvisibilitySkill, thisRaceID, 1.0  );
					War3_SetBuff( i,bDoNotInvisWeapon,thisRaceID,true);
					InvisTrue[i] = false;
				}
				AcceleratorDelayer[i] = 0;
			
			}
			decl Float:velocity[3];
			GetEntDataVector(i,m_vecVelocity,velocity);
			if(skill_speed > 0 && GetVectorLength(velocity) > 0)
			{
				canspeedtime[i] = GetGameTime() + 1.0;
			}
		}
	}	
}


public Action:RemoveSpeed(Handle:t,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client, fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff( client, bDisarm, thisRaceID, false  );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0  );
		War3_SetBuff( client, bDoNotInvisWeapon,thisRaceID,true);

	}
}