/**
* File: War3Source_Enigma.sp
* Description: The Enigma(DotA Hero) for War3Source.
* Author(s): Revan
*/
//Credits to Pimpin & Ownz
//--> www.war3source.com

//recommend restrictions : orb of frost and much more cO

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
new thisRaceID
new S_1, S_2, S_3, ULT;
new BeamSprite, DarkSprite, CoreSprite, HoleSprite, NeutralSprite, ShockSprite, Sharpes;
new String:midnight[]="ambient/atmosphere/hole_hit2.wav";
new String:malefice[]="ambient/alarms/citadel_alert_loop2.wav";
new String:blowup[]="ambient/levels/citadel/weapon_disintegrate2.wav";
new String:shock[]="npc/scanner/scanner_electric1.wav";
new String:hit0[]="physics/flesh/flesh_strider_impact_bullet1.wav";
new String:hit1[]="physics/flesh/flesh_strider_impact_bullet2.wav";
new String:hit2[]="physics/flesh/flesh_strider_impact_bullet3.wav";
new String:hole[]="ambient/explosions/explode_6.wav";
new String:anthurt0[]="npc/antlion/pain1.wav";
new String:anthurt1[]="npc/antlion/pain2.wav";
new bool:bMaleficed[MAXPLAYERS];
new bool:bStun[MAXPLAYERS];
new bool:bStillBlackhole[MAXPLAYERS];
new bool:Midnight64[MAXPLAYERS];
new Float:SavedLocation[MAXPLAYERS][3];
new Male[MAXPLAYERS];
new Float:MaleficeTime[5]={0.0,2.0,4.0,6.0,8.0};
new MaleficeDamage[5]={0,3,5,6,8};
new Float:MaleficeChance[5]={0.0,0.10,0.23,0.28,0.36};
new Float:MaleficeStunTime[5]={1.0,1.1,1.2,1.3,1.4};

new MinMidnight[5]={0,1,2,4,5}; //midnight pulse min dmg
new MaxMidnight[5]={0,3,4,6,7}; //midnight pulse max dmg
new Float:MidnightPulse[5]={0.0,6.0,7.0,8.0,10.0};

new Float:Hole[5]={0.0,2.0,4.0,5.0,6.0};
new Float:HoleRadius[5]={0.0,60.0,60.0,80.0,90.0}; //if player is in radius he will get damage
new Float:HoleRange[5]={0.0,250.0,300.0,350.0,420.0}; //radius to pull

//new MinHole[5]={0,4,8,10,14};
//new MaxHole[5]={0,8,10,14,18};
new MinHole[5]={0,15,20,30,40};
new MaxHole[5]={0,20,30,40,49};

new Handle:eidolonHealth;
new Handle:eidolonExplosion;
new Handle:eidolonRandomSkin;
new Handle:abilityCooldown;
new Handle:ultCooldown;
new Handle:ultCooldown_spawn;
new Handle:refireCooldown;
new Handle:cvarHolePower;
new Handle:ability2Cooldown;
new Handle:pulseCooldown_spawn;
new Handle:conCooldown_spawn;
new Handle:ultMove;
#define MAXWARDS 64*4
#define EIDOLONRADIUS 320
#define WARDBELOW -2.0
#define WARDABOVE 45.0
#define WARDDELAY 1.35
#define MAXENTS 2048
new Eidolondmg0[5]={0,2,5,7,10};
new Eidolondmg1[5]={0,5,7,10,15};
//new Float:CreepChance[5]={0.0,60.0,70.0,80.0,90.0};
new Float:LastHitConversion[MAXPLAYERS];
new Float:EidolonLocation[MAXWARDS][3];
new Float:HoleLocation[MAXWARDS][3];
new CurrentCount[MAXPLAYERS];
new CreepOwner[MAXWARDS];
new CreepIndex[MAXWARDS][MAXPLAYERS];
new entwardindex[MAXENTS];
new String:CreepColor[4][16] = { "255 255 255",
	"80 255 255",
	"120 80 80",
	"80 80 255"
};
new m_vecBaseVelocity;

public Plugin:myinfo = 
{
	name = "War3Source Race - The Enigma",
	author = "Revan",
	description = "Darchrow is one of the most dangerous beings in existence",
	version = "1.0.2",
	url = "www.wcs-lagerhaus.de"
}

public OnPluginStart()
{
	CreateTimer( 0.45, CalcEidolons, _, TIMER_REPEAT );
	m_vecBaseVelocity=FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	HookEvent("round_start",RoundStartEvent);
	eidolonHealth=CreateConVar("war3_enigma_creeps_health","200","Health of Enigma's creeps");
	eidolonExplosion=CreateConVar("war3_enigma_creeps_explode","1","Should the creeps explode on death?");
	eidolonRandomSkin=CreateConVar("war3_enigma_creeps_randomskin","1","Should the creeps have a random skin?");
	abilityCooldown=CreateConVar("war3_enigma_ability1_cooldown","20.0","Enigmas ability1 cooldown");
	ability2Cooldown=CreateConVar("war3_enigma_ability2_cooldown","12.0","Enigmas ability2 cooldown");
	ultCooldown=CreateConVar("war3_enigma_ultimate_cooldown","25.0","Enigmas ultimate cooldown(on use)");
	ultMove=CreateConVar("war3_enigma_ultimate_usage","1.0","Enigmas ultimate allow moving and disable godmode or disable moving and enable godmode(1=disallow move/0=allow move");
	ultCooldown_spawn=CreateConVar("war3_enigma_ultimate_cooldown_spawn","20.0","Enigmas ultimate cooldown(on spawn)");
	conCooldown_spawn=CreateConVar("war3_enigma_ability2_cooldown_spawn","5.0","Enigmas conversion cooldown(on spawn)");
	pulseCooldown_spawn=CreateConVar("war3_enigma_ability1_cooldown_spawn","8.0","Enigmas midnight pulse cooldown(on spawn)");
	cvarHolePower=CreateConVar("war3_enigma_ultimate_power","0.8","Enigmas ultimate (pull)power");
	refireCooldown=CreateConVar("war3_enigma_ultimate_refire","0.1","Enigmas ultimate refire timer");
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	DarkSprite=PrecacheModel("materials/sprites/scanner.vmt");
	NeutralSprite=PrecacheModel("materials/sprites/smoke.vmt");
	ShockSprite=PrecacheModel("materials/sprites/physring1.vmt");
	Sharpes=PrecacheModel("models/effects/splodeglass.mdl");
	HoleSprite=PrecacheModel("materials/sprites/water_drop.vmt");
	CoreSprite=PrecacheModel("materials/sprites/physcannon_bluecore1b.vmt");
	PrecacheModel("models/antlion.mdl");
	PrecacheModel("particle/fire.vmt");
	PrecacheModel("effects/strider_pinch_dudv.vmt");
	War3_PrecacheSound(malefice);
	War3_PrecacheSound(blowup);
	War3_PrecacheSound(shock);
	War3_PrecacheSound(hit0);
	War3_PrecacheSound(hit1);
	War3_PrecacheSound(hit2);
	War3_PrecacheSound(midnight);
}

public OnWar3PluginReady()
{
	
		thisRaceID = War3_CreateNewRace( "Darchrow - The Enigma", "darchrow" );
		S_1 = War3_AddRaceSkill( thisRaceID, "Malefice", "Focuses Darchow's hatred on a target, causing it to take damage over time and may become repeatedly stunned", false, 4 );	
		S_2 = War3_AddRaceSkill( thisRaceID, "Conversion", "Spawns a Eidolon that fight on your side, they will remain till the round ends or they get killed(ability1)", false, 4 );	
		S_3 = War3_AddRaceSkill( thisRaceID, "Midnight Pulse", "Steeps an area in dark magic, causing all opponents who dare enter to take damage(ability)", false, 4 );
		ULT = War3_AddRaceSkill( thisRaceID, "Black Hole", "Summons the powers from the darkest abyss, creating a vortex that sucks all nearby enemies closer, dealing damage", true, 4 );
		War3_CreateRaceEnd( thisRaceID );
		W3SkillCooldownOnSpawn( thisRaceID, S_2, GetConVarFloat(conCooldown_spawn) );
		W3SkillCooldownOnSpawn( thisRaceID, S_3, GetConVarFloat(pulseCooldown_spawn));
		W3SkillCooldownOnSpawn( thisRaceID, ULT, GetConVarFloat(ultCooldown_spawn));
	
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client))
	{
		if(IsPlayerAlive(client))
		{
			if(War3_GetRace(client)==thisRaceID && pressed && ability == 0)
			{
				new skill_level=War3_GetSkillLevel(client,thisRaceID,S_3);
				if(skill_level>0)
				{
					if(War3_SkillNotInCooldown(client,thisRaceID,S_3,true))
					{
						new Float:origin[3];
						new Float:targetpos[3];
						War3_GetAimEndPoint(client,targetpos);
						//War3_GetAimEndPoint(client,SavedLocation[client]);
						GetClientAbsOrigin(client,origin);
						origin[2]+=30;
						TE_SetupBeamPoints(origin, targetpos, BeamSprite, BeamSprite, 0, 10, 3.2, 4.0, 10.0, 2, 2.0, {255,255,255,255}, 70);  
						TE_SendToAll();
						new Float:delay = MidnightPulse[skill_level];
						new Ambient = CreateEntityByName("env_fog_controller");
						if(Ambient)
						{
							DispatchKeyValue(Ambient,"fogcolor", "10 10 10");
							DispatchKeyValue(Ambient,"fogcolor2", "10 10 10");
							DispatchKeyValueFloat(Ambient,"fogstart", 300.0);
							DispatchKeyValueFloat(Ambient,"fogend", 50.0);
							DispatchKeyValueFloat(Ambient,"fogmaxdensity", 1.0);
							DispatchKeyValueFloat(Ambient,"foglerptime", 900.0);
							DispatchSpawn(Ambient);
							ActivateEntity(Ambient);
							TeleportEntity(Ambient, targetpos, NULL_VECTOR, NULL_VECTOR);
							SetVariantString( "!activator" );
							AcceptEntityInput( Ambient, "SetParent", client, Ambient, 0 );
							AcceptEntityInput( Ambient, "TurnOn");
							CreateTimer(delay,Timer_RemoveEntity,Ambient);
						}
						/*new DamageEntity = CreateEntityByName("point_hurt");
						if(DamageEntity)
						{
							decl String:damage[10];
							IntToString(GetRandomInt(MinMidnight[skill_level],MaxMidnight[skill_level]), damage, sizeof(damage)); //hm?
							DispatchKeyValueFloat(DamageEntity, "DamageRadius", 300.0);
							DispatchKeyValue(DamageEntity, "classname", "midnightpulse");
							DispatchKeyValue(DamageEntity, "Damage", damage);
							DispatchKeyValueFloat(DamageEntity, "DamageDelay", GetRandomFloat(0.1,0.8));
							//SetEntPropEnt(DamageEntity, Prop_Send, "m_hOwnerEntity", client);
							SetEntProp(DamageEntity, Prop_Send, "m_hOwnerEntity", client, 4);
							SetEntProp(DamageEntity, Prop_Send, "m_iTeamNum", GetClientTeam(client), 4);
							DispatchSpawn(DamageEntity);
							TeleportEntity(DamageEntity, targetpos, NULL_VECTOR, NULL_VECTOR);
							AcceptEntityInput(DamageEntity, "TurnOn");
							CreateTimer( delay, Timer_RemoveEntity, DamageEntity );
						}*/// new method respects immunity:
						SavedLocation[client]=targetpos;
						Midnight64[client]=true;
						CreateTimer( delay, Timer_MidnightFinished, client );
						CreateTimer( 0.1, Timer_MidnightLoop, client );
						new Enviorment = CreateEntityByName("env_smokestack");    
						if(Enviorment)
						{
							DispatchKeyValue( Enviorment, "SmokeMaterial", "particle/fire.vmt" );

							if(GetClientTeam(client)==3)
							DispatchKeyValue( Enviorment, "RenderColor", "100 100 255" );
							else
							DispatchKeyValue( Enviorment, "RenderColor", "255 115 115" );

							DispatchKeyValue( Enviorment, "SpreadSpeed", "300" );
							DispatchKeyValue( Enviorment, "RenderAmt", "100" );
							DispatchKeyValue( Enviorment, "JetLength", "400" );
							DispatchKeyValue( Enviorment, "RenderMode", "0" );
							DispatchKeyValue( Enviorment, "Initial", "0" );
							DispatchKeyValue( Enviorment, "Speed", "50" );
							DispatchKeyValue( Enviorment, "Rate", "150" );
							DispatchKeyValueFloat( Enviorment, "BaseSpread", 35.0 );
							DispatchKeyValueFloat( Enviorment, "StartSize", 20.0 );
							DispatchKeyValueFloat( Enviorment, "EndSize", 0.5 );
							DispatchKeyValueFloat( Enviorment, "Twist", 35.0 );
							DispatchSpawn(Enviorment);
							TeleportEntity(Enviorment, targetpos, NULL_VECTOR, NULL_VECTOR);
							AcceptEntityInput(Enviorment, "TurnOn");
							CreateTimer( delay, Timer_TurnOffEntity, Enviorment );
							CreateTimer( delay+2.0, Timer_RemoveEntity, Enviorment );
						}
						EmitSoundToAll(midnight,client);
						War3_CooldownMGR(client,GetConVarFloat(abilityCooldown),thisRaceID,S_3,_,_);
					}
				}
			}
			else if(War3_GetRace(client)==thisRaceID && pressed && ability == 1)
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,S_2,true))
				{
					if(CurrentCount[client]<4) {
						new Float:StartPos[3];
						GetClientAbsOrigin( client, StartPos );
						new Float:EndPos[3];
						GetClientAbsOrigin( client, EndPos );
						EndPos[2]+=150;
						//EndPos[1]+=GetRandomInt(-45,45);
						//EndPos[0]+=GetRandomInt(-45,45);
						//EidolonCount[client]++;
						CurrentCount[client]++;
						PrintHintText(client,"You spawned a Eidolon");
						CreateEidolon(client,StartPos);
						TE_Start("Bubbles");
						TE_WriteVector("m_vecMins", StartPos);
						TE_WriteVector("m_vecMaxs", EndPos);
						TE_WriteFloat("m_fHeight", 20.0);
						TE_WriteNum("m_nModelIndex", Sharpes);
						TE_WriteNum("m_nCount", 4);
						TE_WriteFloat("m_fSpeed", 0.1);
						TE_SendToAll();
						War3_CooldownMGR(client,GetConVarFloat(ability2Cooldown),thisRaceID,S_2,_,_);
					}
					else {
						PrintHintText(client,"Eidolon Maximum reached!");
					}
				}
			}
		}
	}
	else
	{
		PrintHintText(client,"You are Silenced!");
	}
}

public Action:Timer_MidnightFinished( Handle:timer, any:client )
{
	if (client > 0 && ValidPlayer(client,false))
	{
		Midnight64[client]=false;
		PrintHintText(client,"Midnight Pulse finished!");
	}
}

public Action:Timer_MidnightLoop( Handle:timer, any:client )
{
	if (client > 0 && ValidPlayer(client,false) && Midnight64[client])
	{
		new ult_level=War3_GetSkillLevel(client,thisRaceID,S_3);
		if(ult_level>0)
		{
			new Float:repeatdelay = GetRandomFloat(0.1,0.8);
			CreateTimer(repeatdelay, Timer_MidnightLoop, client );
			for(new t=1;t<=MaxClients;t++)
			{
				if(ValidPlayer(t,true))
				{
					new skill_level=War3_GetSkillLevel(client,thisRaceID,S_3);
					if(skill_level>0)
					{
						new Float:origin[3];
						origin[0] = SavedLocation[client][0];
						origin[1] = SavedLocation[client][1];
						origin[2] = SavedLocation[client][2];
						new Float:VictimPos[3];
						GetClientAbsOrigin(t,VictimPos);
						VictimPos[2]+5;
						origin[2]+5;
						if(GetVectorDistance(VictimPos,origin) < 300 && GetClientTeam(t) != GetClientTeam(client))
						{
							if(W3HasImmunity( t, Immunity_Ultimates ) && !Midnight64[t])
							{
								PrintCenterText(t,"You blocked a Skill!");
							}
							else
							{
								War3_DealDamage( t, GetRandomInt(MinMidnight[skill_level],MaxMidnight[skill_level]), client, DMG_BULLET, "midnight", _, W3DMGTYPE_MAGIC);
								TE_SetupBeamPoints(origin,VictimPos,HoleSprite,HoleSprite,0,20,repeatdelay+0.1,0.1,10.0,1,1.0,{255,120,120,220},20);
								TE_SendToAll();
							}
						}
					}
				}
			}
		}
	}
}

public Action:Timer_BlackHoleLoop( Handle:timer, any:client )
{
	if (client > 0 && ValidPlayer(client,true) && bStillBlackhole[client])
	{
		new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT);
		if(ult_level>0)
		{
			CreateTimer( GetConVarFloat(refireCooldown), Timer_BlackHoleLoop, client );
			for(new t=1;t<=MaxClients;t++)
			{
				if(ValidPlayer(t,false))
				{
					new Float:origin[3];
					origin=HoleLocation[client];
					//GetClientAbsOrigin(client,origin);
					new Float:VictimPos[3];
					GetClientAbsOrigin(t,VictimPos);
					VictimPos[2]+5;
					origin[2]+5;
					if(GetVectorDistance(VictimPos,origin) < HoleRange[ult_level]&&GetClientTeam(t)!=GetClientTeam(client))
					{
						if(W3HasImmunity( t, Immunity_Ultimates ) && !bStillBlackhole[t])
						{
							//War3_CooldownMGR(client,10.0,thisRaceID,ULTIMATE,_,_,_,"Black Hole");
							PrintCenterText(t,"You blocked a Ultimate!");
						}
						else
						{
							PushClientToVector(t, origin, GetConVarFloat(cvarHolePower));
							if(GetVectorDistance(VictimPos,origin) < HoleRadius[ult_level]&&GetClientTeam(t)!=GetClientTeam(client))
							//DMG_DISSOLVE has some dissolving effects on kill??? - may it was DMG_PLASMA or something else...
							War3_DealDamage( t, GetRandomInt(MinHole[ult_level],MaxHole[ult_level]), client, DMG_DISSOLVE, "blackhole", _, W3DMGTYPE_MAGIC);
						}
					}
				}
			}
		}
	}
}

public Action:PushClientToVector( victim, Float:pos1[3], Float:power )
{
	new Float:pos2[3], Float:main_origin[3], Float:velo1[3], Float:velo2[3];
	GetClientAbsOrigin( victim, pos2 );

	main_origin[0] = pos1[0] - pos2[0], main_origin[1] = pos1[1] - pos2[1], main_origin[2] = pos1[2] - pos2[2];
	velo1[0] += 0, velo1[1] += 0, velo1[2] += 300;
	
	velo2[0] = main_origin[0] * ( 100 * power );
	velo2[1] = main_origin[1] * ( 100 * power );
	velo2[2] = main_origin[2] * ( 100 * power );
	
	SetEntDataVector( victim, m_vecBaseVelocity, velo1, true );
	SetEntDataVector( victim, m_vecBaseVelocity, velo2, true );
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
for(new x=1;x<=64;x++)
if( ValidPlayer( x, false ) )
		KillEidolons(x);
		
/*public CreateBlackHole( client, Float:vector[3] )
{
	new BlackHole = CreateEntityByName("env_physexplosion");
	if(BlackHole && bStillBlackhole[client])
	{
		DispatchKeyValueFloat(BlackHole, "radius", 800.0);
		DispatchKeyValueFloat(BlackHole, "magnitude", -GetConVarFloat(cvarHolePower));
		DispatchKeyValue(BlackHole, "spawnflags", "2");
		SetEntPropEnt(BlackHole, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(BlackHole, Prop_Send, "m_iTeamNum", GetClientTeam(client), 4);
		DispatchSpawn(BlackHole);
		TeleportEntity(BlackHole, vector, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(BlackHole, "Explode");
		CreateTimer( 0.1, Timer_RefireHole, client );
		//AcceptEntityInput(BlackHole, "Kill");
		CreateTimer( 0.15, Timer_RemoveEntity, BlackHole );
		PrintCenterText(client,"B L A C K - H O L E");
	}
}*/

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT);
		if(ult_level>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT,true))
			{
				bStillBlackhole[client]=true;
				EmitSoundToAll( hole, client, SNDCHAN_AUTO );
				PrintToChat(client,"\x05Into the Void!");
				
				if(GetConVarBool(ultMove))
				War3_SetBuff(client,bBashed,thisRaceID,true);
				else
				War3_SetBuff(client,fSlow,thisRaceID,0.8);
				
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
				CreateTimer( Hole[ult_level], Timer_NoMoreBlackHole, client );
				GetClientAbsOrigin(client,HoleLocation[client]);
				CreateTimer( 0.1, Timer_BlackHoleLoop, client );
				TE_SetupGlowSprite(HoleLocation[client], CoreSprite, Hole[ult_level], 3.0, 255);
				TE_SendToAll();
				TE_SetupBeamRingPoint(HoleLocation[client],200.0,HoleRadius[ult_level],HoleSprite,HoleSprite,0,60,Hole[ult_level],350.0,0.0,{155,155,155,255},10,0);
				TE_SendToAll();
				ClientCommand(client, "r_screenoverlay debug/yuv");
				new Enviorment = CreateEntityByName("env_smokestack");    
				if(Enviorment)
				{
					DispatchKeyValue( Enviorment, "SmokeMaterial", "effects/strider_pinch_dudv.vmt" );
					DispatchKeyValue( Enviorment, "RenderColor", "110 255 110" );
					DispatchKeyValue( Enviorment, "SpreadSpeed", "1" );
					DispatchKeyValue( Enviorment, "RenderAmt", "250" );
					DispatchKeyValue( Enviorment, "JetLength", "100" );
					DispatchKeyValue( Enviorment, "RenderMode", "0" );
					DispatchKeyValue( Enviorment, "Initial", "0" );
					DispatchKeyValue( Enviorment, "Speed", "1" );
					DispatchKeyValue( Enviorment, "Rate", "25" );
					DispatchKeyValueFloat( Enviorment, "BaseSpread", 1.0 );
					DispatchKeyValueFloat( Enviorment, "StartSize", 50.0 );
					DispatchKeyValueFloat( Enviorment, "EndSize", 90.0 );
					DispatchKeyValueFloat( Enviorment, "Twist", 5.0 );
					DispatchSpawn(Enviorment);
					TeleportEntity(Enviorment, HoleLocation[client], NULL_VECTOR, NULL_VECTOR);
					AcceptEntityInput(Enviorment, "TurnOn");
					CreateTimer( Hole[ult_level], Timer_TurnOffEntity, Enviorment );
					CreateTimer( Hole[ult_level]+2.0, Timer_RemoveEntity, Enviorment );
				}
				War3_CooldownMGR(client,GetConVarFloat(ultCooldown),thisRaceID,ULT,_,_);
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public Action:Timer_NoMoreBlackHole( Handle:timer, any:client )
{
	if (client > 0 && ValidPlayer(client,false))
	{
		ClientCommand(client, "r_screenoverlay 0");
		bStillBlackhole[client]=false;

		if(GetConVarBool(ultMove))
		War3_SetBuff(client,bBashed,thisRaceID,false);
		else
		War3_SetBuff(client,fSlow,thisRaceID,1.0);

		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		StopSound(client, SNDCHAN_AUTO, hole);
	}
}

public War3Source_RoundOverEvent(Handle:event, client, bool:dontBroadcast)
{
	if (client == thisRaceID)
	{
		Timer_NoMoreBlackHole( event , client);
	}
}


public Action:Timer_TurnOffEntity( Handle:timer, any:edict )
{
	if (edict > 0 && IsValidEdict(edict))
	AcceptEntityInput( edict, "TurnOff" );
}

public Action:Timer_RemoveEntity( Handle:timer, any:edict )
{
	if (edict > 0 && IsValidEdict(edict))
	AcceptEntityInput( edict, "Kill" );
}

public CreateEidolon( client, Float:vector[3])
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( CreepOwner[i] == 0 )
		{
			CreepOwner[i] = client;
			EidolonLocation[i]=vector;
			W3FlashScreen(i,RGBA_COLOR_GREEN);
			DrawEidolon(EidolonLocation[i], client, i, GetRandomInt(0,3));
			break;
		}
	}
}

public KillEidolons( client)
{
	for( new i = 0; i < MAXWARDS; i++ ) //loop trough every ward ("eidolon")
	{
		if( CreepOwner[i] == client )
		{
			CreepOwner[i] = 0;
			KillEidolon(i,client);
		}
	}
	CurrentCount[client] = 0;
}

public Action:CalcEidolons( Handle:timer )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( CreepOwner[i] != 0 )
		{
			new client = CreepOwner[i];
			if( !ValidPlayer( client, true ) )
			{
				//CreepOwner[i] = 0;
				//--CurrentCount[client];
				KillEidolons(client);
			}
			else
			{
				new skilllevel=War3_GetSkillLevel(client,thisRaceID,S_2);
				if(skilllevel)
				CallEidolon( client, i, Eidolondmg0[skilllevel], Eidolondmg1[skilllevel]);
			}
		}
	}
}

public CallEidolon( owner, wardindex, mindamage, maxdamage )
{
	new ownerteam = GetClientTeam( owner );
	new beamcolor[] = { 0, 0, 200, 255 };
	if( ownerteam == 2 )
	{
		beamcolor[0] = 200;
		beamcolor[2] = 0;
	}

	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[] = { 0.0, 0.0, WARDBELOW };
	new Float:tempVec2[] = { 0.0, 0.0, WARDABOVE };
	AddVectors( EidolonLocation[wardindex], tempVec1, start_pos );
	AddVectors( EidolonLocation[wardindex], tempVec2, end_pos );

	new Float:BeamXY[3];
	for( new x = 0; x < 3; x++ ) BeamXY[x] = start_pos[x];
	new Float:BeamZ = BeamXY[2];
	BeamXY[2] = 0.0;
	
	new Float:VictimPos[3];
	new Float:tempZ;
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) && GetClientTeam(i) != ownerteam )
		{
			GetClientAbsOrigin( i, VictimPos );
			tempZ = VictimPos[2];
			VictimPos[2] = 0.0;
			
			if( GetVectorDistance( BeamXY, VictimPos ) < EIDOLONRADIUS )
			{
				if( tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE )
				{
					if( !W3HasImmunity( i, Immunity_Skills ) )
					{
						if( LastHitConversion[i] < GetGameTime() - WARDDELAY )
						{
							new DamageScreen[4];
							new Float:pos[3];
							GetClientAbsOrigin( i, pos );
							DamageScreen[0] = beamcolor[0];
							DamageScreen[1] = beamcolor[1];
							DamageScreen[2] = beamcolor[2];
							DamageScreen[3] = 80;
							W3FlashScreen( i, DamageScreen);
							War3_DealDamage( i, GetRandomInt(mindamage,maxdamage), owner, DMG_BULLET, "conversion", _, W3DMGTYPE_TRUEDMG );

							pos[2] += 40;
							new randsound = GetRandomInt(0,2);

							if(randsound==0)
							EmitSoundToAll( hit0, i, SNDCHAN_WEAPON );
							else if(randsound==1)
							EmitSoundToAll( hit1, i, SNDCHAN_WEAPON );
							else
							EmitSoundToAll( hit2, i, SNDCHAN_WEAPON );

							LastHitConversion[i] = GetGameTime();
							PrintHintText(i,"You've been hit by a Eidolon!");

							if (IsValidEntity(CreepIndex[wardindex][owner]))
							{
								new String:Animation[128];
								Format(Animation, sizeof(Animation), "attack%i", GetRandomInt(1,6));
								SetVariantString(Animation);
								AcceptEntityInput(CreepIndex[wardindex][owner], "SetAnimation", -1, -1, 0);
								SetEntityAimToClient(CreepIndex[wardindex][owner],i);
								CreateTimer(WARDDELAY-0.1,Timer_IdleEntity,CreepIndex[wardindex][owner]);
							}
						}
					}
					else
						PrintCenterText(i,"Skill Blocked!");
				}
			}
		}
	}
}

public Action:Timer_IdleEntity( Handle:timer, any:ent )
{
	if (IsValidEntity(ent))
	{
		SetVariantString("idle");
		AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);
	}
}

stock DrawEidolon(Float:vector[3], client, wardindex, skin)
{
	new eidolon_ent = CreateEntityByName("prop_dynamic_override");
	if (eidolon_ent > 0 && IsValidEdict(eidolon_ent))
	{
		decl String:entname[16];
		Format(entname, sizeof(entname), "%d_eidolon_num%i", client,CurrentCount[client]);
		new team = GetClientTeam(client);
		SetEntityModel(eidolon_ent, "models/antlion.mdl");

		//DispatchKeyValue(eidolon_ent, "spawnflags", "3");
		DispatchKeyValue(eidolon_ent, "StartDisabled", "false");
		if (CreepColor[team][0] != '\0')
		{
			decl String:color[4][4];
			if (ExplodeString(CreepColor[team], " ", color, sizeof(color), sizeof(color[])) <= 3)
			strcopy(color[3], sizeof(color[]), "255");
			
			SetEntityRenderMode(eidolon_ent, RENDER_TRANSCOLOR);
			SetEntityRenderColor(eidolon_ent, StringToInt(color[0]), StringToInt(color[1]),
			StringToInt(color[2]), StringToInt(color[3]));
		}
		if (DispatchSpawn(eidolon_ent))
		{
			SetEntProp(eidolon_ent, Prop_Data, "m_takedamage", 2);
			SetEntProp(eidolon_ent, Prop_Send, "m_usSolidFlags", 152);
			TeleportEntity(eidolon_ent, vector, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(eidolon_ent, "targetname", entname);
			DispatchKeyValue(eidolon_ent, "classname", "eidolon");
			
			SetEntProp(eidolon_ent, Prop_Data, "m_MoveCollide", 1);
			SetEntProp(eidolon_ent, Prop_Send, "m_iTeamNum", team, 4);
			SetEntProp(eidolon_ent, Prop_Send, "m_CollisionGroup", 5);
			
			SetEntPropEnt(eidolon_ent, Prop_Data, "m_hLastAttacker", client);
			SetEntPropEnt(eidolon_ent, Prop_Data, "m_hPhysicsAttacker", client);
			SetEntPropEnt(eidolon_ent, Prop_Send, "m_hOwnerEntity", client);
			if(GetConVarBool(eidolonExplosion))
			{
				DispatchKeyValue(eidolon_ent, "ExplodeRadius", "100");
				if(GetRandomInt(0,1)==1)
				DispatchKeyValue(eidolon_ent, "ExplodeDamage", "65");
				else
				DispatchKeyValue(eidolon_ent, "ExplodeDamage", "35");
			}

			if(GetConVarBool(eidolonRandomSkin))
			{
				if(skin==1)
				DispatchKeyValue(eidolon_ent, "Skin", "1");
				if(skin==2)
				DispatchKeyValue(eidolon_ent, "Skin", "2");
				if(skin==3)
				DispatchKeyValue(eidolon_ent, "Skin", "3");
			}
			
			SetVariantString("idle");
			AcceptEntityInput(eidolon_ent, "SetAnimation", -1, -1, 0);
			
			SetEntProp(eidolon_ent, Prop_Data, "m_iHealth", 0);
			//SetEntityHealth(eidolon_ent,GetConVarInt(eidolonHealth));
			//HookSingleEntityOutput(eidolon_ent, "OnTakeDamage", CreepDamaged, true);
			SDKHook(eidolon_ent, SDKHook_OnTakeDamage, CreepDamaged);
			//HookSingleEntityOutput(eidolon_ent, "OnBreak", CreepKilled, true);
			CreepIndex[wardindex][client]=eidolon_ent;
			entwardindex[eidolon_ent]=wardindex;
		}
	}
}

stock KillEidolon(wardindex,client)
{
	if (IsValidEntity(CreepIndex[wardindex][client]))
	{
		AcceptEntityInput(CreepIndex[wardindex][client], "Kill");
		CreepOwner[wardindex]=0;
		CurrentCount[client]--;
	}
}

public Action:CreepDamaged(caller, &attacker, &inflictor, &Float:damage, &damagetype)//CreepDamaged(const String:output[], caller, activator, Float:delay)
{
	if(attacker!=caller) {
		if( ValidPlayer( attacker, true ))
		{
			if(GetRandomInt(0,1)==1)
			EmitSoundToAll( anthurt0, caller, SNDCHAN_AUTO );
			else
			EmitSoundToAll( anthurt1, caller, SNDCHAN_AUTO );
			new health = GetEntProp(caller, Prop_Data, "m_iHealth");
			SetEntProp(caller, Prop_Data, "m_iHealth", health + RoundToNearest(damage));
			if(GetEntProp(caller, Prop_Data, "m_iHealth") >= GetConVarInt(eidolonHealth)){
				SDKUnhook(caller, SDKHook_OnTakeDamage, CreepDamaged);
				new owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
				if(ValidPlayer(owner,false)) {
					KillEidolon(entwardindex[caller],owner);
					PrintHintText(owner,"A Eidolon got killed!");
				}
				else
				AcceptEntityInput(caller, "Kill");
			}				
		}
	}
	return Plugin_Handled;
}

/*public CreepKilled(const String:output[], caller, activator, Float:delay)
{
	decl String:classname[32]; 
	GetEdictClassname(caller, classname, sizeof(classname));  
	if(StrEqual(classname, "eidolon")) 
	{ 
		new owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
		if(ValidPlayer(owner,false)) {
			KillEidolon(entwardindex[caller],owner);
			PrintHintText(owner,"A Eidolon got killed!");
		}
	} 
}*/

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
	if(ValidPlayer(victim)&&ValidPlayer(attacker)&&victim!=attacker&&GetClientTeam(victim)!=GetClientTeam(attacker)&&!W3HasImmunity(victim,Immunity_Skills)){
		if(!bMaleficed[victim]){
			if(War3_GetRace(attacker)==thisRaceID&&!Hexed(attacker,false)){
				new skilllevel=War3_GetSkillLevel(attacker,thisRaceID,S_1);
				new Float:chance=MaleficeChance[skilllevel];
				if( GetRandomFloat(0.0,1.0)<=chance && skilllevel>0){
					bMaleficed[victim]=true;
					Male[victim]=attacker;
					CreateTimer(2.0,Timer_MaleficeDmg,victim);
					CreateTimer(MaleficeTime[skilllevel],Timer_RemoveMalefice,victim);
					if(GetRandomInt(0,1)==1) //50 % chance to activate 'random' stun
					CreateTimer(MaleficeStunTime[skilllevel],Timer_MaleficeStun,victim);

					new Float:spos[3];
					GetClientAbsOrigin(victim,spos);
					new Float:epos[3];
					GetClientAbsOrigin(victim,epos);
					CreateEnv(attacker,spos,skilllevel);
					spos[2]+=280;
					for( new Float:fx_timer = 0.0 ; fx_timer <= MaleficeTime[skilllevel]; fx_timer+= 0.2)
					{
						spos[2]-=GetRandomFloat(5.0,8.0);
						TE_SetupBeamRingPoint(spos, 80.0, 120.0, DarkSprite, DarkSprite, 0, GetRandomInt(10,60), 0.21, 20.0, 1.0, {255,255,255,255}, 20, 0);
						TE_SendToAll(fx_timer);
						if(spos[2]<=epos[2]) //just for check
						{
							TE_SetupBeamRingPoint(spos, 120.0, 1000.0, DarkSprite, DarkSprite, 0, 20, 0.21, 20.0, 1.0, {255,255,255,255}, 20, 0);
							TE_SendToAll(fx_timer+0.18);
						}
					}
					EmitSoundToAll(malefice,victim,SNDCHAN_AUTO);
					PrintHintText(victim,"Malefice affects you!");
					PrintCenterText(attacker,"Malefice used on your victim!");
				}
			}
		}
		if(bStillBlackhole[victim])
		{
			new Float:origin[3];
			GetClientAbsOrigin(victim,origin);
			new Float:targetpos[3];
			GetClientAbsOrigin(attacker,targetpos);
			PushClientToVector(attacker, origin, GetRandomFloat(0.01,0.2));
			
			if(GetConVarBool(ultMove)==false)
			War3_DamageModPercent(0.0);
			
			TE_SetupBeamRingPoint(origin, 10.0, 160.0, DarkSprite, DarkSprite, 0, 20, 0.80, 20.0, 1.0, {255,255,255,255}, 20, 0);
			TE_SendToAll();
			TE_SetupBeamPoints(origin, targetpos, HoleSprite, HoleSprite, 0, 10, 0.95, 4.0, 10.0, 2, 2.0, {255,255,255,255}, 70);  
			TE_SendToAll();
		}
	}
}

public CreateEnv(attacker, Float:targetpos[3], skilllevel)
{
	new Enviorment = CreateEntityByName("env_Smokestack");    
	if(Enviorment)
	{
		decl Float:fAng[3] = { 90.0, 90.0, 90.0 };
		DispatchKeyValue( Enviorment, "SmokeMaterial", "sprites/scanner.vmt" );
		DispatchKeyValue( Enviorment, "RenderColor", "255 255 255" );
		DispatchKeyValue( Enviorment, "SpreadSpeed", "10" );
		DispatchKeyValue( Enviorment, "RenderAmt", "145" );
		DispatchKeyValue( Enviorment, "JetLength", "450" );
		DispatchKeyValue( Enviorment, "RenderMode", "0" );
		DispatchKeyValue( Enviorment, "Initial", "0" );
		DispatchKeyValue( Enviorment, "Speed", "35" );
		DispatchKeyValue( Enviorment, "Rate", "90" );
		DispatchKeyValueFloat( Enviorment, "BaseSpread", 5.0 );
		DispatchKeyValueFloat( Enviorment, "StartSize", 0.1 );
		DispatchKeyValueFloat( Enviorment, "EndSize", 6.0 );
		DispatchKeyValueFloat( Enviorment, "Twist", 260.0 );
		DispatchKeyValueVector( Enviorment, "Angles", fAng );
		DispatchSpawn(Enviorment);
		TeleportEntity(Enviorment, targetpos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(Enviorment, "TurnOn");
		new Float:duration=MaleficeTime[skilllevel]+5.0;

		//simple check...
		if(duration<1)
		duration=5.0;
		
		CreateTimer( duration, Timer_TurnOffEntity, Enviorment );
		CreateTimer( duration+2.0, Timer_RemoveEntity, Enviorment );
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	ClientCommand(client, "r_screenoverlay 0");
	if(newrace != thisRaceID)
	{
		War3_SetBuff(client,bStunned,thisRaceID,false);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		bMaleficed[client]=false;
		bStun[client]=false;
		StopSound(client, SNDCHAN_AUTO,malefice);
		StopSound(client, SNDCHAN_AUTO,hole);
	}
	else
	{
		PrintToChat(client,"\x04[BETA] use at own risk!");
	}
}

public OnWar3EventSpawn( client )
{
	if(GetConVarBool(ultMove)==false)
	War3_SetBuff(client,fSlow,thisRaceID,1.0);

	War3_SetBuff(client,bBashed,thisRaceID,false);
	bMaleficed[client]=false;
	bStun[client]=false;
	Midnight64[client]=false;
	StopSound(client, SNDCHAN_AUTO,malefice);
	StopSound(client, SNDCHAN_AUTO,hole);
	if(War3_GetRace(client)==thisRaceID){
		new Float:pos[3];
		GetClientAbsOrigin(client,pos);
		pos[2]+=40;
		TE_SetupBeamRingPoint(pos, 80.0, 90.0, DarkSprite, BeamSprite, 0, GetRandomInt(25,60), GetRandomFloat(2.0,4.0), 20.0, 1.0, {255,255,255,255}, 20, 0);
		TE_SendToAll(0.2); //emit afer a little delay
	}
}

public Action:Timer_RemoveMalefice(Handle:timer,any:client)
{
	if(ValidPlayer(client,false))
	{
		bMaleficed[client]=false;
		bStun[client]=false;
		PrintHintText(client,"Malefice disappears");
		StopSound(client, SNDCHAN_AUTO,malefice);
	}
}

public Action:Timer_MaleficeStun(Handle:timer,any:client)
{
	if(ValidPlayer(client,true)&&!bStun[client]&&bMaleficed[client])
	{
		bStun[client]=true;
		new Float:pos[3];
		GetClientAbsOrigin(client,pos);
		War3_SetBuff(client,bBashed,thisRaceID,true);
		CreateTimer(GetRandomFloat(0.2,0.6),Timer_UnfreezePlayer,client);
		W3FlashScreen(client,RGBA_COLOR_BLUE);
		EmitSoundToAll(shock, client, SNDCHAN_AUTO);
		pos[2]+=15;
		TE_SetupGlowSprite(pos, ShockSprite, GetRandomFloat(0.8,1.0), GetRandomFloat(0.8,1.2), GetRandomInt(180,255));
		TE_SendToAll();
	}
}

public Action:Timer_UnfreezePlayer(Handle:timer,any:client)
{
	War3_SetBuff(client,bBashed,thisRaceID,false);
	bStun[client]=false;
	PrintToConsole(client,"[W3S] stun disappears...");
}

public Action:Timer_MaleficeDmg(Handle:timer,any:client)
{
	new attacker=Male[client];
	if(ValidPlayer(attacker,true)&&ValidPlayer(client,true)&&bMaleficed[client])
	{
		new skilllevel=War3_GetSkillLevel(attacker,thisRaceID,S_1);
		if(skilllevel>0){
			new Float:spos[3];
			GetClientAbsOrigin(client,spos);
			spos[2]+=35;
			TE_SetupBeamRingPoint(spos, 80.0, 90.0, NeutralSprite, NeutralSprite, 0, 20, 1.20, 12.0, 1.0, {255,120,120,255}, 30, 0);
			TE_SendToAll();
			War3_DealDamage( client, MaleficeDamage[skilllevel], attacker, DMG_BULLET, "malefice", _, W3DMGTYPE_TRUEDMG );
			W3FlashScreen(client,RGBA_COLOR_RED);
			CreateTimer(2.0,Timer_MaleficeDmg,client);
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	bMaleficed[victim]=false;
	StopSound(victim, SNDCHAN_AUTO,malefice);

}


public SetEntityAimToClient( edict, target)
{
	new Float:spos[3],  Float:epos[3], Float:vecles[3], Float:angles[3];
	GetEntPropVector(edict, Prop_Send, "m_vecOrigin", spos);
	GetClientAbsOrigin( target, epos );
	SubtractVectors( epos, spos, vecles );
	GetVectorAngles( vecles, angles );
	angles[2] = 0.0;
	TeleportEntity( edict, NULL_VECTOR, angles, NULL_VECTOR );
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
		if(ValidPlayer(client,true)&&bStillBlackhole[client])
		{
			if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2) || (buttons & IN_USE) || (buttons & IN_RELOAD))
			{
				PrintHintText(client,"You're buffed with blackhole, action blocked!");
				return Plugin_Handled;
			}
		}
		return Plugin_Continue;
}