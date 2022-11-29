/**
* File: War3Source_999_Timberwolf.sp
* Description: fourtet's custom race for War3source
* Author(s): Remy Lebeau
* Requested by fourtet.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/remyfunctions"

public Plugin:myinfo = 
{
	name = "War3Source Race - Minnesota Timberwolf",
	author = "Remy Lebeau",
	description = "fourtet's custom race for War3source",
	version = "1.0.2",
	url = "sevensinsgaming.com"
};



// War3Source stuff + Sprite/Sound Variable
new thisRaceID;
new SKILL_REGEN, SKILL_FREEZE, SKILL_CAMO, ULT_GEAR;

// SKILL_REGEN VARIABLEs
new Float:regenbonus[] = { 0.0, 0.5, 1.0, 1.5, 2.0 };

// SKILL_FREEZE VARIABLEs
new Float:FreezeChance[5] = { 0.0, 0.1, 0.2, 0.3, 0.4 };

// SKILL_CAMO VARIABLES

new Float:camochange[] = {0.0, 0.15, 0.35, 0.45, 0.60};

// ULT_GEAR VARIABLES




public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Minnesota Timberwolf [PRIVATE]", "timberwolf" );
	
	SKILL_REGEN = War3_AddRaceSkill( thisRaceID, "Regeneration", "Self heal (0.5/1/1.5/2 hp / sec)", false, 4 );	
	SKILL_FREEZE = War3_AddRaceSkill( thisRaceID, "Freeze", "Like a deer in headlights", false, 4 );	
	SKILL_CAMO = War3_AddRaceSkill( thisRaceID, "Camo", "You have a chance of dressing like your prey", false, 4 );	
	ULT_GEAR = War3_AddRaceSkill( thisRaceID, "Gear up", "Get an AK for a while", true, 4 );

	W3SkillCooldownOnSpawn( thisRaceID, ULT_CLAWS, 15.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );

}

public OnPluginStart()
{

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

	new regen_level = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
	War3_SetBuff( client, fHPRegen, thisRaceID, regenbonus[regen_level]  );
	
	new camo_level = War3_GetSkillLevel( client, thisRaceID, SKILL_STRENGTH );
	if (GetRandomFloat( 0.0, 1.0 ) < camochance[camo_level]
	{
		War3_ChangeModel( client, true);
		PrintHintText (attacker, "Camouflaged");
	}
	
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle,weapon_knife");
	CreateTimer( 1.0, GiveWep, client );
	
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
		InitPassiveSkills(client);
	}
}




/***************************************************************************
*
*
*				ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


public OnUltimateCommand( client, race, bool:pressed )
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_gear = War3_GetSkillLevel( client, thisRaceID, ULT_GEAR );
		if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_GEAR,true))
		{
			if(ult_gear > 0)
			{
				
				GetClientWeapon( client, wep[client], 64 );
				RemovePlayerItem( client, W3GetCurrentWeaponEnt( client ) );
				GivePlayerItem( client, "weapon_ak47" );
				CreateTimer( UltDuration[ult_level], GiveWeapon, client );
				War3_CooldownMGR( client, UltDuration[ult_level] + 5.0, thisRaceID, ULT_AWP, _, true );
			}
				
			else
			{
				PrintHintText(client, "Level your Ultimate first");
			}
		}
		
	}

}

/***************************************************************************
*
*
*				EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID && !W3HasImmunity( victim, Immunity_Skills ))
		{			
			new skill_freeze = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FREEZE );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) < FreezeChance[skill_freeze] && skill_freeze > 0 )
			{
				War3_SetBuff( victim, bStunned, thisRaceID, true );
				
				CreateTimer( 1.0, StopFreeze, victim );
				
				W3FlashScreen( victim, RGBA_COLOR_BLUE );
				
				PrintHintText( attacker, "Like a deer in the headlights!" );
			}
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

public Action:StopFreeze( Handle:timer, any:client )
{
	War3_SetBuff( client, bStunned, thisRaceID, false );
}


public Action:GiveWep( Handle:timer, any:client )
{
	new race = War3_GetRace( client );
	if( ValidPlayer( client, true ) && race == thisRaceID )
	{
		GivePlayerItem( client, "weapon_deagle" );
	}
}

