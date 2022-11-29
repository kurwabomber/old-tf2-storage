/*
RACE NAME: John McClane
Steam name: SILLY OL KABLAMO
Steam ID: STEAM_0:1:158507
weapon restricted race spawns with knife and p228
skill 1: veteran officer = increased damage with p228 (15% at max ?)
skill 2: Good guys never reload = clip increased on p228 (4 bullets per lvl)
skill 3: No shoes no matter = increased speed (1.3 at max, or 1.4)
ultimate: Yippee-ki-yay = spawn a mp5 navy (weapon lasts 20secs at max, the mp5 doesn't get any bonus's like the pistol, its just normal)
Kablamo's Race - http://www.sevensinsgaming.com/forum/index.php?/topic/4315-new-race-john-mcclane/
*/



#pragma semicolon 1
 
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"


new thisRaceID;
new SKILL_DAMAGE, SKILL_CLIP, SKILL_SPEED, ULT_WEAPON;

#define WEAPON_RESTRICT "weapon_p228,weapon_knife"
#define WEAPON_GIVE "weapon_p228"


public Plugin:myinfo = 
{
	name = "War3Source Race - John McClane",
	author = "ABGar | Remy Lebeau",
	description = "Kablamo's private race for War3Source.",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
}

// VETERAN
new Float:VetDamage[]={1.0,1.05,1.1,1.15,1.2};

// GOODGUY
new GGAmmo[]={13,17,21,25,29};

// SHOES
new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4 };

// YIPPEE
new Float:YippeeDuration[]={0.0,5.0,10.0,15.0,20.0};
new Float:YippeeCD[]={0.0,60.0,55.0,50.0,45.0};

new ClipAmmoCur[MAXPLAYERS];
new Clip1Offset;




public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("John McClane [PRIVATE]","jmcclane");
	
	SKILL_DAMAGE = War3_AddRaceSkill(thisRaceID,"Veteran Officer","Increased damage with your P228 (passive)",false,4);
	SKILL_CLIP = War3_AddRaceSkill(thisRaceID,"Good guys never reload","Clip size increased with your P228 (passive)",false,4);
	SKILL_SPEED = War3_AddRaceSkill(thisRaceID,"No Shoes, No Matter","Increased Speed (passive)",false,4);
	ULT_WEAPON=War3_AddRaceSkill(thisRaceID,"Yippee-Ki-Yay","Spawn a sub-machine gun (+ultimate)",true,4);
	
	War3_CreateRaceEnd(thisRaceID);
	
	War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
}


public OnPluginStart()
{
	HookEvent( "weapon_reload", WeaponReloadEvent );
	Clip1Offset = FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" );
}

public InitPassiveSkills( client )
{
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    CreateTimer( 1.0, GiveWep, client );

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




/* *************************************** (GOODGUY) ***************************************/



public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, WEAPON_GIVE );
        CreateTimer( 0.1, SetWepAmmo, client );
    }
}

public Action:SetWepAmmo( Handle:timer, any:client )
{
	if(War3_GetRace(client)==thisRaceID && ValidPlayer(client,true))
	{
		new skill_lvl=War3_GetSkillLevel(client,thisRaceID,SKILL_CLIP);
		if(skill_lvl>0)
        {
			new ammo = GGAmmo[skill_lvl];
			Client_SetWeaponAmmo(client,"weapon_p228",51,0,ammo,0);
		}
	}
}

public WeaponReloadEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	for(new client=1;client<=MaxClients;client++)
	{
		if( War3_GetRace(client) == thisRaceID )
		{
			new String:weapon[32]; 
			GetClientWeapon( client, weapon, 32 );
			if( StrEqual( weapon, "weapon_p228" ) )
			{
				CreateTimer( 2.9, SetAmmoReload, client );
				CreateTimer( 2.5, SetClipAmmount, client );
			}
		}
	}
}

public Action:SetClipAmmount( Handle:timer, any:client )
{
	if(War3_GetRace(client)==thisRaceID && IsPlayerAlive(client))
	{
		new String:weapon[32]; 
		GetClientWeapon( client, weapon, 32 );
		if( StrEqual( weapon, "weapon_p228" ) )
		{
			new wep_ent = W3GetCurrentWeaponEnt( client );
			ClipAmmoCur[client] = GetEntData( wep_ent, Clip1Offset, 4 );
		}
	}
}

public Action:SetAmmoReload( Handle:timer, any:client )
{
	if(War3_GetRace(client)==thisRaceID && IsPlayerAlive(client))
	{
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_CLIP);
		if(skilllvl > 0)
		{
			new clipammo = GGAmmo[skilllvl];  // How much ammo we WANT to be in the clip (based on skill level)
			new weapontype = GetPlayerWeaponSlot(client, 1);
			if (IsValidEntity(weapontype))
			{
				new ammoType = GetEntProp(weapontype, Prop_Send, "m_iPrimaryAmmoType");
				if (ammoType != -1) // Just to make sure it is a gun
				{
					new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
					new tempammo = clipammo - ClipAmmoCur[client]; // tempammo is a temporary number (how much we WANT in the clip minus how much is CURRENTLY in the clip prior to reload)
					new newammo = ammo-tempammo; // Make sure we move the correct amount of ammo from Spare to Clip - (Set the Spare Ammo to be CURRENT AMMO(ammo) - the difference between what we WANT in the clip and how much is CURRENTLY in the clip)
					if(newammo<0)
					{
						newammo=0;
					}
					if((ClipAmmoCur[client]+ammo)<clipammo) // if TOTAL ammo (clip+spare) is less than what we WANT in the clip...
					{
						clipammo=(ClipAmmoCur[client]+ammo); // Set the 'new' Clipammo (what we WANT in the clip) to equal the TOTAL ammo
					}
					Client_SetWeaponAmmo(client,"weapon_p228",(newammo),0,(clipammo),0); // actually set the ammo amounts in game
				}
			}
		}
	}
}

/* *************************************** (VETERAN) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_DAMAGE);
			if(race_attacker==thisRaceID && skill_attacker>0 && !Hexed(attacker,false))
			{
				new String:weapon[32]; 
				GetClientWeapon( attacker, weapon, 32 );
				if( StrEqual( weapon, "weapon_p228" ) )
				{
					War3_DamageModPercent(VetDamage[skill_attacker]);
				}
			}
		}
	}
}

/* *************************************** (Ultimate) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
		if(War3_SkillNotInCooldown(client,thisRaceID,ULT_WEAPON,true))
		{
			new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_WEAPON);
			if(ult_level>0)
			{
				War3_WeaponRestrictTo(client, thisRaceID, "weapon_mp5navy,weapon_p228,weapon_knife");
				GivePlayerItem(client,"weapon_mp5navy");
				CreateTimer(YippeeDuration[ult_level],stopYippee,client);
				War3_CooldownMGR( client, YippeeCD[ult_level], thisRaceID, ULT_WEAPON, _, _ );
			}
			else
			{
				PrintHintText(client, "Level your Ultimate first");
			}
		}
	}
}
		
		
public Action:stopYippee(Handle:timer,any:client)
{
    if(ValidPlayer(client,true))
    {
        Client_RemoveWeapon(client, "weapon_mp5navy");
        War3_WeaponRestrictTo(client, thisRaceID, "weapon_p228,weapon_knife");
    }
}	
