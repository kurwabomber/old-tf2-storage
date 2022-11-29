/*
 * ZERO STOCKS FUNCTIONS v1.0.0
 * AWSOME STOCKS THAT DO SHIT RIGHT!
 * www.IBISGaming.com
 */

#if defined _zerostocks_functions_included
  #endinput
#endif
#define _zerostocks_functions_included

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <cstrike>
#include <smlib>


/*
 * ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
 * 
 * @param client		Player to check from.
 * @return				True if no immunity in range.
 */
stock bool:enemyImmunityNotInRange(client)
{
	new Float:otherVec[3];
	new team = GetClientTeam(client);
	new Float:startpos[3];
	GetClientAbsOrigin( client, startpos );

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(startpos,otherVec)<300)
			{
				return false;
			}
		}
	}
	return true;
}

/*
 * CHECK THAT DMG TRIGGER IS VALID
 * 
 * @param client		Player to check from.
 * @return				True if all clinets are valid for targeting.
 */
 stock bool:ValidHurt(any:victim,any:attacker)
{
	if(victim>0&&attacker>0&&victim!=attacker)
	{
		return true;
	}
	
	return false;
}

/*
 * REMOVE PRIMARY WEAPON
 * 
 * @param client		Player to remove weapon from.
 * @return				True on success, false otherwise.
 */
 stock bool:RemovePrimary(any:client)
{
	new wep1 = GetPlayerWeaponSlot( client, CS_SLOT_PRIMARY );
	if(Weapon_IsValid(wep1))
	{
		if (Client_GetActiveWeapon(client) == wep1) 
		{
			new wep2 = GetPlayerWeaponSlot( client, CS_SLOT_SECONDARY );
			if(Weapon_IsValid(wep2))
			{
				Client_SetActiveWeapon(client, wep2);
			}
			else
			{
				wep2 = GetPlayerWeaponSlot( client, 2 );
				if(Weapon_IsValid(wep2))
				{
					Client_SetActiveWeapon(client, wep2);
				}
			}
		}
		
		if (RemovePlayerItem(client, wep1)) {
			if(AcceptEntityInput(wep1, "kill"))
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			return false;
		}
	}
	return false;
}

/*
 * REMOVE SECONDARY WEAPON
 * 
 * @param client		Player to remove weapon from.
 * @return				True on success, false otherwise.
 */
 stock bool:RemoveSecondary(any:client)
{
	new wep1 = GetPlayerWeaponSlot( client, CS_SLOT_SECONDARY );
	if(Weapon_IsValid(wep1))
	{
		if (Client_GetActiveWeapon(client) == wep1) 
		{
			new wep2 = GetPlayerWeaponSlot( client, 2 );
			if(Weapon_IsValid(wep2))
			{
				Client_SetActiveWeapon(client, wep2);
			}
		}
		
		if (RemovePlayerItem(client, wep1)) {
			if(AcceptEntityInput(wep1, "kill"))
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			return false;
		}
	}
	return false;
}

/*
 * REMOVE NADES
 * 
 * @param client		Player to remove nades from.
 */
 stock RemoveNades(any:client)
{
	new wep1 = GetPlayerWeaponSlot( client, CS_SLOT_GRENADE );
	while(Weapon_IsValid(wep1))
	{
		if(Client_GetActiveWeapon(client) == wep1) 
		{
			new wep2 = GetPlayerWeaponSlot( client, 2 );
			if(Weapon_IsValid(wep2))
			{
				Client_SetActiveWeapon(client, wep2);
			}
		}
		
		if(RemovePlayerItem(client, wep1)) 
		{
			if(!AcceptEntityInput(wep1, "kill"))
			{
				break;
			}
		}
		else
		{
			break;
		}
		
		wep1 = GetPlayerWeaponSlot( client, CS_SLOT_GRENADE );
	}
}

/*
 * KNIFE ONLY
 * 
 * @param client		Player to remove nades from.
 */
 stock KnifeOnly(any:client)
{
	RemovePrimary(client);
	RemoveSecondary(client);
	RemoveNades(client);
}

/*
 * REMOVE KNIFE
 * 
 * @param client		Player to remove weapon from.
 * @return				True on success, false otherwise.
 */
 stock bool:RemoveKnife(any:client)
{
	new wep1 = GetPlayerWeaponSlot( client, 2 );
	if(Weapon_IsValid(wep1))
	{		
		if (RemovePlayerItem(client, wep1)) {
			if(AcceptEntityInput(wep1, "kill"))
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			return false;
		}
	}
	return false;
}