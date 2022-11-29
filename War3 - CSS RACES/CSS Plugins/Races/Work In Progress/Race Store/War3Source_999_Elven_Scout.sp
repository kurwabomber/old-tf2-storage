#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>
#include <cstrike>

public Plugin:myinfo = 
{
	name = "War3Source Race - Elven Scout",
	author = "M.A.C.A.B.R.A",
	description = "The Elven Scout race for War3Source.",
	version = "1.0.1",
	url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_SENSE, SKILL_ACCURACY, SKILL_CUTLER,  ULT_RETURN;

// Sense
new Float:SenseRange[]={0.0, 1000.0, 1500.0, 2000.0, 2500.0};
new bool:WeaponZoomed[MAXPLAYERS+1];
new g_iScope[MAXPLAYERS + 1];
new THISammo[MAXPLAYERS +1];
new GlowSprite,GlowSprite2;
new BeamSprite,HaloSprite;

// Accuracy Buffs
new Float:AccuracyDmg[]={1.0,1.2,1.3,1.4,1.5};

// Cutler Buffs
new Float:CutlerSpeed[]={1.0,1.4,1.5,1.6,1.7};

// Return
new Float:ReturnSavedPos[MAXPLAYERS][3];
new bool:ReturnAnyPosSaved[MAXPLAYERS];
new Float:ReturnTeleportCooldown[]={0.0,40.0,30.0,20.0,10.0};



/* *********************** OnWar3PluginReady *********************** */
public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Elven Scout","elvenscout");
	
	SKILL_SENSE=War3_AddRaceSkill(thisRaceID,"Eagle Eye","You have an eagle sight while scoping.",false,4); // [X]
	SKILL_ACCURACY=War3_AddRaceSkill(thisRaceID,"Accuracy","You deal more damage if weapon not scoped.",false,4); // [X]
	SKILL_CUTLER=War3_AddRaceSkill(thisRaceID,"Cutler","Faster if using knife.",false,4); // [X]
	ULT_RETURN=War3_AddRaceSkill(thisRaceID,"Return (Ultimate)","Marks location and comes back to it later.",true,4); // [X]
		
	War3_CreateRaceEnd(thisRaceID);
}

/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{
	CreateTimer( 0.1, CalcSense, _, TIMER_REPEAT );
	CreateTimer( 0.1, CalcCutler, _, TIMER_REPEAT );
	
	HookEvent("weapon_zoom", OnPlayerZoom, EventHookMode_Post);
	HookEvent("weapon_reload", OnPlayerReload, EventHookMode_Post);
	HookEvent("weapon_fire", OnPlayerFire, EventHookMode_Post);
	
}

/* *********************** OnMapStart *********************** */
public OnMapStart()
{
	GlowSprite=PrecacheModel("effects/redflare.vmt");
	GlowSprite2=PrecacheModel("materials/effects/fluttercore.vmt");
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

/* *********************** OnWar3EventSpawn *********************** */
public OnWar3EventSpawn(client)
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		ReturnAnyPosSaved[client] = false;
		WeaponZoomed[client] = false;
		g_iScope[client] = 0;
		THISammo[client] = 10;
		
		InitPassiveSkills(client);
		GivePlayerItem( client, "weapon_scout" );

		new skill_return = War3_GetSkillLevel( client, thisRaceID, ULT_RETURN );
		W3SkillCooldownOnSpawn( thisRaceID, ULT_RETURN, ReturnTeleportCooldown[skill_return], _ );
	}
}

public OnWar3EventDeath(client)
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		ReturnAnyPosSaved[client] = false;
		WeaponZoomed[client] = false;
		g_iScope[client] = 0;
	}
}

/* *********************** OnSkillLevelChanged *********************** */
public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}

/* *********************** InitPassiveSkills *********************** */
public InitPassiveSkills(client)
{	
}

/* *********************** OnRaceChanged *********************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace( client, thisRaceID );
		g_iScope[client] = 0;
		ReturnAnyPosSaved[client] = false;
		WeaponZoomed[client] = false;
	}
	else
	{
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_scout" );
		if( IsPlayerAlive( client ) )
		{
			GivePlayerItem( client, "weapon_scout" );
			InitPassiveSkills( client );
			g_iScope[client] = 0;
			ReturnAnyPosSaved[client] = false;
			WeaponZoomed[client] = false;
		}
	}
}



/* *************************************** CalcSense *************************************** */
public Action:CalcSense( Handle:timer, any:userid )
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			if( War3_GetRace( i ) == thisRaceID )
			{
				Sense(i);
			}		
		}
	}
	
}
	
/* *************************************** Sense *************************************** */
public Sense(client)
{
	new skill_sense = War3_GetSkillLevel( client, thisRaceID, SKILL_SENSE );
	if( skill_sense > 0 && !Hexed( client, false ) )
	{
		new ElfTeam = GetClientTeam( client );
		new Float:ElfPos[3];
		new Float:VictimPos[3];
		
		GetClientAbsOrigin( client, ElfPos );
		
		ElfPos[2] += 50.0;
		
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam( i ) != ElfTeam && !W3HasImmunity( i, Immunity_Skills ) )
			{
				GetClientAbsOrigin( i, VictimPos );
				VictimPos[2] += 50.0;
				
				if(GetVectorDistance( ElfPos, VictimPos ) <= SenseRange[skill_sense])
				{
					decl String:weapon[64];
					GetClientWeapon(client, weapon, sizeof(weapon));
					if(StrEqual(weapon, "weapon_scout"))
					{
						new VictimTeam = GetClientTeam( i );
						if(WeaponZoomed[client] == true)
						{
							if(VictimTeam == 2) // TT
							{
								TE_SetupGlowSprite(VictimPos,GlowSprite,0.1,0.6,80);
								TE_SendToClient(client);
								TE_SetupBeamPoints(ElfPos, VictimPos, BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, {255,0,0,155}, 70); // czerwony
								TE_SendToClient(client);
							}
							else // CT
							{
								TE_SetupGlowSprite(VictimPos,GlowSprite2,0.1,0.1,150);
								TE_SendToClient(client);
								TE_SetupBeamPoints(ElfPos, VictimPos, BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, {30,144,255,155}, 70); // niebieski
								TE_SendToClient(client);
							}	
						}
					}
					else
					{
						g_iScope[client] = 0;
						WeaponZoomed[client] = false;						
					}						
				}
			}
		}
	}
}



/* *************************************** OnPlayerZoom *************************************** */
public Action:OnPlayerZoom(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    g_iScope[client]++;
    if(g_iScope[client] >= 3)
	{
		g_iScope[client] = 0;
	}
	decl String:weapon[64];
	GetClientWeapon(client, weapon, sizeof(weapon));
	if(StrEqual(weapon, "weapon_scout"))
	{
		if(g_iScope[client] == 2)
		{
			WeaponZoomed[client] = true;
		}
		else
		{
			WeaponZoomed[client] = false;
		}
	}
	else
	{
		g_iScope[client] = 0;
		WeaponZoomed[client] = false;
	}
}

/* *************************************** OnPlayerReload *************************************** */
public Action:OnPlayerReload(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iScope[client] = 0;
	WeaponZoomed[client] = false;
	THISammo[client] = 10;
}

/* *************************************** OnPlayerFire *************************************** */
public Action:OnPlayerFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapon[64];
	GetClientWeapon(client, weapon, sizeof(weapon));
	if(StrEqual(weapon, "weapon_scout"))
	{
		THISammo[client]--;
		if(THISammo[client] == 0)
		{
			g_iScope[client] = 0;
			WeaponZoomed[client] = false;
			THISammo[client] = 10;
		}
	}
}

/* *************************************** CalcCutler *************************************** */
public Action:CalcCutler( Handle:timer, any:userid )
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			if( War3_GetRace( i ) == thisRaceID )
			{
				Cutler(i);
			}		
		}
	}	
}

/* *************************************** Cutler *************************************** */
public Cutler(client)
{
	new skill_cutler = War3_GetSkillLevel( client, thisRaceID, SKILL_CUTLER );
	if( skill_cutler > 0)
	{
		decl String:weapon[64];
		GetClientWeapon(client, weapon, sizeof(weapon));
		if(StrEqual(weapon, "weapon_knife"))
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,CutlerSpeed[skill_cutler]);
		}
		else
		{
			W3ResetAllBuffRace( client, thisRaceID );
		}
		
	}
}



/* *************************************** OnW3TakeDmgBulletPre *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(g_iScope[attacker] == 0)
			{
				new skill_ult = War3_GetSkillLevel(attacker,thisRaceID,SKILL_ACCURACY);
				War3_DamageModPercent(AccuracyDmg[skill_ult]);
				damage *= AccuracyDmg[skill_ult];
			}			
		}
	}
}



/* *************************************** OnUltimateCommand *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_ult = War3_GetSkillLevel(client,thisRaceID,ULT_RETURN);
		if(skill_ult > 0)
		{
			if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_RETURN,true ))
			{
				if(ReturnAnyPosSaved[client] == false)
				{
					PrintHintText( client, "Location Marked" );
					War3_CooldownMGR(client,10.0,thisRaceID,ULT_RETURN,false,true);
					GetClientAbsOrigin( client, ReturnSavedPos[client] );
					ReturnAnyPosSaved[client] = true;
				}
				else
				{
					PrintHintText( client, "Returned to marked location" );
					War3_CooldownMGR(client,ReturnTeleportCooldown[skill_ult],thisRaceID,ULT_RETURN,false,true);
					TeleportEntity(client, ReturnSavedPos[client], NULL_VECTOR, NULL_VECTOR);
					ReturnAnyPosSaved[client] = false;
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Return first");
		}
	}
}