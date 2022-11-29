#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - G³odzilla",
	author = "M.A.C.A.B.R.A",
	description = "The G³odzilla race for War3Source. Especially for Masterczu³ek :D",
	version = "1.0.2",
	url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_GLODNY, SKILL_NAJEDZONA, SKILL_GLODOMORRA, SKILL_OGON, ULT_CZEKOLADA;

// G³odny Potwór
new Float:GlodnySpeed[]={0.0,1.1,1.2,1.3,1.4,1.5};

// Najedzona!
new NajedzonaHP[]={100,120,140,160,180,200};

// G³odomorra
new Float:GlodomorraRange[]={0.0,40.0,80.0,120.0,160.0,200.0};
new GlodomorraDamage[] = {0,1,2,3,4,5};
new GlodomorraMaxHP;

// Ogonowy Cios
new OgonDamage[] = {0,5,10,15,20,25};
new Handle:OgonCooldownTime;
new Float:OgonRange[]={0.0,60.0,120.0,180.0,240.0,300.0};

// Czekolaaaaaada
new CzekoladaDamage[] = {0,20,25,30,35,40};
new Handle:CzekoladaCooldownTime;
new Float:CzekoladaRange[]={0.0,80.0,160.0,240.0,320.0,400.0};

// Soundy
new String:CzekoladaSnd[]="war3source/glodzilla/czekolada.mp3";
new String:OgonSnd[]="war3source/glodzilla/ogon.mp3";
new String:SpawnSnd[]="war3source/glodzilla/spawn.mp3";
new String:DeadSnd[]="war3source/glodzilla/dead.mp3";


/* *********************** OnWar3PluginReady *********************** */
public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "G³odzilla", "glodzilla" );
	
	SKILL_GLODNY = War3_AddRaceSkill( thisRaceID, "Glodny Potwor", "Glodzilla biega szybciej.", false, 5 );
	SKILL_NAJEDZONA = War3_AddRaceSkill( thisRaceID, "Najedzona!", "Glodzilla jest silniejsza.", false, 5 );
	SKILL_GLODOMORRA = War3_AddRaceSkill( thisRaceID, "Glodomorra", "Glodzilla pozera wrogow znajdujacych siê blisko niej i staje siê silniejsza.", false, 5 );
	SKILL_OGON = War3_AddRaceSkill( thisRaceID, "Ogonowy Cios", "Glodzilla wymachuje ogonem i rani wrogow. (+ability)", false, 5 );
	ULT_CZEKOLADA = War3_AddRaceSkill( thisRaceID, "Czekolaaaaaada", "Topi przeciwnikow w fali czekolady.(+ultimate)", true, 5 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_CZEKOLADA, 20.0, true );
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_OGON, 10.0, true);
	
	War3_CreateRaceEnd( thisRaceID );
}

/* *********************** OnMapStart *********************** */
public OnMapStart()
{
	//Soundy
	War3_PrecacheSound(CzekoladaSnd);
	War3_PrecacheSound(OgonSnd);
	War3_PrecacheSound(SpawnSnd);
	War3_PrecacheSound(DeadSnd);
	
}

/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{
	OgonCooldownTime=CreateConVar("war3_glodzilla_ogon_cooldown","20","Cooldown timer.");
	CzekoladaCooldownTime=CreateConVar("war3_glodzilla_czekolada_cooldown","40","Cooldown timer.");
	
	CreateTimer( 1.0, CalcGlodomorra, _, TIMER_REPEAT );	
}

/* *********************** OnWar3EventSpawn *********************** */
public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		W3ResetAllBuffRace( client, thisRaceID );
		GlodomorraMaxHP = 100;
		InitPassiveSkills(client);
		GivePlayerItem( client, "weapon_elite" );
		EmitSoundToAll(SpawnSnd,client);
	}
}

/* *********************** InitPassiveSkills *********************** */
public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_lvl = War3_GetSkillLevel(client,thisRaceID,SKILL_GLODNY);	
		if(skill_lvl > 0)
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,GlodnySpeed[skill_lvl]);
		}
		
		new skill_lvl2 = War3_GetSkillLevel(client,thisRaceID,SKILL_NAJEDZONA);	
		if(skill_lvl2 > 0)
		{
			War3_SetMaxHP_INTERNAL(client,NajedzonaHP[skill_lvl2]);
			SetEntityHealth(client,NajedzonaHP[skill_lvl2]);
			War3_SetCSArmor(client,100);
			War3_SetCSArmorHasHelmet(client,true);
			GlodomorraMaxHP = NajedzonaHP[skill_lvl2];
		}
	}
}

/* *********************** OnRaceChanged *********************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_SetMaxHP_INTERNAL(client,100);
		War3_SetCSArmor(client,0);
		War3_SetCSArmorHasHelmet(client,false);
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife, weapon_elite" );
		if( IsPlayerAlive( client ) )
		{
			GivePlayerItem( client, "weapon_elite" );
			InitPassiveSkills( client );
		}
		EmitSoundToAll(SpawnSnd,client);
	}
}

/* *********************** OnWar3EventDeath *********************** */
public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
	
	if(War3_GetRace(victim) == thisRaceID)
	{
		EmitSoundToAll(DeadSnd,victim);	
	}
}


/* *************************************** CalcGlodomorra *************************************** */
public Action:CalcGlodomorra( Handle:timer, any:userid )
{
	if( thisRaceID > 0 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) )
			{
				if( War3_GetRace( i ) == thisRaceID )
				{
					Glodomorra( i );					
				}
			}
		}
	}
}

/* *************************************** Glodomorra *************************************** */
public Glodomorra( client )
{
	new skill_glodomora = War3_GetSkillLevel( client, thisRaceID, SKILL_GLODOMORRA );
	if( skill_glodomora > 0 && !Hexed( client, false ) )
	{
		new Float:distance = GlodomorraRange[skill_glodomora];
		new damage = GlodomorraDamage[skill_glodomora];
		
		new AttackerTeam = GetClientTeam( client );
		new Float:AttackerPos[3];
		new Float:VictimPos[3];
		
		GetClientAbsOrigin( client, AttackerPos );
		
		AttackerPos[2] += 40.0;

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam( i ) != AttackerTeam && !W3HasImmunity( i, Immunity_Skills ) )
			{
				
				GetClientAbsOrigin( i, VictimPos );
				VictimPos[2] += 40.0;
				
				if( GetVectorDistance( AttackerPos, VictimPos ) <= distance )
				{
					War3_DealDamage(i,damage,client,DMG_BURN,"glodomorra",W3DMGORIGIN_SKILL);
					
					GlodomorraMaxHP += damage;
					War3_SetMaxHP_INTERNAL(client,GlodomorraMaxHP);
					War3_HealToBuffHP(client,damage);	
				}
			}
		}
	}
}


/* *************************************** OnAbilityCommand *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_OGON);
		if(skill > 0)
		{			
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_OGON,true))
			{				
				new target=War3_GetTargetInViewCone(client,OgonRange[skill],false);
				if(ValidPlayer(target,true) && !W3HasImmunity(target,Immunity_Skills) && GetClientTeam(target)!= GetClientTeam(client))
				{
					new damage = OgonDamage[skill];
						
					War3_DealDamage(target,damage,client,DMG_BURN,"ogon",W3DMGORIGIN_SKILL);
					PrintHintText(target,"Zostales uderzony Ogonem Glodzilli");
					PrintHintText(client,"Uderzyles przeciwnika Ogonem Glodzilli");
					EmitSoundToAll(OgonSnd,client);
					War3_CooldownMGR(client,GetConVarFloat(OgonCooldownTime),thisRaceID,SKILL_OGON,false,true);
				}
				else
				{
					PrintHintText(client, "Zadnego celu w zasiegu ogona.");
				}
			}
		}
		else
		{
			PrintHintText(client, "Pocwicz najpierw swoj Ogoniasty Cios");
		}
	}
}


/* *************************************** OnUltimateCommand *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill = War3_GetSkillLevel(client,thisRaceID,ULT_CZEKOLADA);
		if(skill > 0)
		{
			
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_CZEKOLADA,true))
			{
				new damage = CzekoladaDamage[skill];
				new Float:AttackerPos[3];
				GetClientAbsOrigin(client,AttackerPos);
				new AttackerTeam = GetClientTeam(client);
				new Float:VictimPos[3];
				
				
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true) && !W3HasImmunity(i,Immunity_Ultimates))
					{
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(AttackerPos,VictimPos) < CzekoladaRange[skill])
						{
							if(GetClientTeam(i)!= AttackerTeam)
							{
								War3_DealDamage(i,damage,client,DMG_BURN,"czekolaada",W3DMGORIGIN_SKILL);
								PrintHintText(i,"Zostales zalany fala czekolady !");
								PrintHintText(client,"Zalales wrogow fala czekolady !");
							}
						}
					}
				}
				EmitSoundToAll(CzekoladaSnd,client);
				War3_CooldownMGR(client,GetConVarFloat(CzekoladaCooldownTime),thisRaceID,ULT_CZEKOLADA,false,true);
			}
		}
		else
		{
			PrintHintText(client, "Pocwicz najpierw Czeklaaaade");
		}
	}
}

