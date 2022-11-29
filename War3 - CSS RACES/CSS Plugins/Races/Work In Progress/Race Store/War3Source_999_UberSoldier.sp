/*
* War3Source Race - UberSoldier
* 
* File: War3Source_UberSoldier.sp
* Description: The UberSoldier race for War3Source.
* Author: M.A.C.A.B.R.A 
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - UberSoldier",
	author = "M.A.C.A.B.R.A",
	description = "The UberSoldier race for War3Source.",
	version = "1.2.0",
	url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_INJURY, SKILL_BOMB, SKILL_FORCE, ULT_PROBE;

//Injury
new Float:InjuryChance[] = {0.0, 0.1, 0.2, 0.3, 0.4};
new String:InjurySnd[]="war3source/ubersoldier/injury.wav";

//Bomber
new Bomb[MAXPLAYERS][5];
new BombNumber[MAXPLAYERS];
new bool:bIsPlanted[MAXPLAYERS];
new ActiveBombs[MAXPLAYERS];
new bool:bIsBombAlive[MAXPLAYERS][5];
new Float:BombPos1[MAXPLAYERS][3];
new Float:BombPos2[MAXPLAYERS][3];
new Float:BombPos3[MAXPLAYERS][3];
new Float:BombPos4[MAXPLAYERS][3];
new Float:BombRadius[] = {0.0, 100.0, 125.0, 150.0, 175.0};
new BombDamage[] = {0, 40, 60, 80, 100};
new String:BomberSnd[]="war3source/ubersoldier/bomber.wav";
new String:ExplosionSnd[]="war3source/ubersoldier/explosion.wav";
new Explosion1, Explosion2;

// Force Field
new Float:NadeDistance[] = {0.0, 100.0, 175.0, 250.0, 350.0};
new NadeNumber; 
new HeNade[1024]; 
new HeNadeNumber;  
new FlashNade[1024]; 
new FlashNadeNumber;  
new bool:NadeType[1024]; 
new Float:HeNadePos[1024][3];
new Float:FlashNadePos[1024][3];
new Float:NadePushForce = 1.5;
new m_vecBaseVelocity;
new BeamSprite,HaloSprite;
new String:ForceFieldSnd[]="war3source/ubersoldier/forcefield.mp3";

// Remote Probe
new bool:bProbeArmed[MAXPLAYERS]; 
new bool:bIsProbe[MAXPLAYERS]; 
new Probe[MAXPLAYERS+1];
new Float:ProbeCooldown[] = {0.0, 35.0, 30.0, 25.0, 20.0};
new String:ProbeSnd[]="war3source/ubersoldier/probe.wav"; 
new String:ArmedSnd[]="war3source/ubersoldier/armed.wav";

/* *********************** OnWar3PluginReady *********************** */
public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "UberSoldier", "ubersoldier" );
	
	SKILL_INJURY = War3_AddRaceSkill( thisRaceID, "Injury", "Hurts enemy into arm with the result that he cannot maintain his weapon.", false, 4 );
	SKILL_BOMB = War3_AddRaceSkill( thisRaceID, "Bomber", "Plants explosives (+ability) and detonates them remotely (+ability1).", false, 4 );
	SKILL_FORCE = War3_AddRaceSkill( thisRaceID, "Force Field", "Allows you to deflect grenades.", false, 4 );
	ULT_PROBE = War3_AddRaceSkill( thisRaceID, "Remote Probe", "Allows you to preview your surroundings. (+ultimate)", true, 4 );
	
	War3_CreateRaceEnd( thisRaceID );
}

/* *********************** OnMapStart *********************** */
public OnMapStart()
{
	AddFileToDownloadsTable("materials/effects/war3source/ubersoldier/fire_cloud1_ubersoldier.vmt");
	AddFileToDownloadsTable("materials/effects/war3source/ubersoldier/fire_cloud2_ubersoldier.vmt");
	AddFileToDownloadsTable("materials/effects/war3source/ubersoldier/fire_cloud1_ubersoldier.vtf");
	AddFileToDownloadsTable("materials/effects/war3source/ubersoldier/fire_cloud2_ubersoldier.vtf");
	
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	Explosion1=PrecacheModel("materials/effects/war3source/ubersoldier/fire_cloud1_ubersoldier.vmt");
	Explosion2=PrecacheModel("materials/effects/war3source/ubersoldier/fire_cloud2_ubersoldier.vmt");
	
	War3_PrecacheSound(InjurySnd);
	War3_PrecacheSound(BomberSnd);
	War3_PrecacheSound(ExplosionSnd);
	War3_PrecacheSound(ForceFieldSnd);
	War3_PrecacheSound(ProbeSnd);
	War3_PrecacheSound(ArmedSnd);
}

/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	HookEvent("weapon_fire", Event_Fire, EventHookMode_Post);
	HookEvent("hegrenade_detonate", Event_Detonate, EventHookMode_Pre);
	HookEvent("flashbang_detonate", Event_FlashDetonate, EventHookMode_Pre);
	CreateTimer(0.1,FindSoldier,_,TIMER_REPEAT);
}

/* **************** RoundStartEvent **************** */
public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	NadeNumber = 0;
	HeNadeNumber = 0;
	FlashNadeNumber = 0;
	
	for(new i = 0; i < 1024; i++)
	{
		HeNade[i] = -1;
		FlashNade[i] = -1;
		NadeType[i] = false;
	}
		
	for(new i=1;i<=MaxClients;i++)
	{
		if(War3_GetRace(i)==thisRaceID)
		{
			bIsProbe[i] = false;
			bProbeArmed[i] = false;
			Probe[i] = -1;
			BombNumber[i] = 0;
			bIsPlanted[i] = false;
			ActiveBombs[i] = 0;
			
			for(new j =0; j <5;j++)
			{
				Bomb[i][j] = -1;
				bIsBombAlive[i][j] = false;
			}
		}
	}
}

/* *********************** OnWar3EventSpawn *********************** */
public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		bIsProbe[client] = false;
		bProbeArmed[client] = false;
		Probe[client] = -1;
		BombNumber[client] = 0;
		bIsPlanted[client] = false;
		ActiveBombs[client] =0;
		
		for(new j =0; j <4;j++)
		{
			Bomb[client][j] = -1;
			bIsBombAlive[client][j] = false;
		}
	}
}

/* *********************** OnRaceChanged *********************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		W3ResetAllBuffRace( client, thisRaceID );
	}
}

/* *************************************** Injury *************************************** */
/* *********************** OnClientPutInServer *********************** */
public OnClientPutInServer(client){
	SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}
/* *********************** OnClientDisconnect *********************** */
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack); 
}

/* *********************** SDK_Forwarded_TraceAttack *********************** */
public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(hitgroup== 4 || hitgroup == 5)
	{
		if(IS_PLAYER(victim) && IS_PLAYER(attacker) && victim > 0 && attacker > 0 && attacker != victim)
		{
			if(GetClientTeam(victim) != GetClientTeam(attacker))
			{
				if(War3_GetRace(attacker) == thisRaceID)
				{
					if(!Hexed(attacker))
					{
						new skill_lvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_INJURY);
						if(skill_lvl > 0)
						{
							if(!W3HasImmunity(victim,Immunity_Skills))
							{
								if(GetRandomFloat(0.0,1.0) <= InjuryChance[skill_lvl])
								{
									PrintHintText(attacker, "You've injured your enemy into arm. He can't maintain his weapon.");
									PrintHintText(victim, "You've been injured into arm. You can't maintain your weapon.");
									EmitSoundToAll(InjurySnd,attacker);
									EmitSoundToAll(InjurySnd,victim); 			
									FakeClientCommand(victim, "drop");
								}
							}
							else
							{
								W3MsgEnemyHasImmunity( attacker, true );
							}								
						}
					}
				}
			}
		}		
	}
	return Plugin_Changed;
}

/* *************************************** Force Field & Remote Probe *************************************** */
/* *********************** Event_Fire *********************** */
public Event_Fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientId);
	
	new String:weapon[30];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(StrEqual(weapon,"hegrenade"))
	{
		NadeNumber++;
		HeNadeNumber++;
		NadeType[NadeNumber] = true;
	}
	else if(StrEqual(weapon,"flashbang"))
	{
		NadeNumber++;
		FlashNadeNumber++;
		NadeType[NadeNumber] = false;
	}

	CreateTimer(0.1, FindNade, client);
}

/* *********************** Event_Detonate *********************** */
public Event_Detonate(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new clientId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientId);
	
	if(bIsProbe[client] == true)
	{
		PrintHintText(client, "Your Remote Probe has self-destruct.");
		SetClientViewEntity(client, client);
		Probe[client] = -1;
		bIsProbe[client] = false;
		bProbeArmed[client] = false;
		War3_CooldownMGR(client,ProbeCooldown[War3_GetSkillLevel(client,War3_GetRace(client),ULT_PROBE)],thisRaceID,ULT_PROBE,_,_);
	}
	
	for(new i = 1; i <= HeNadeNumber; i++)
	{
		if(HeNade[i] != -1)
		{
			HeNade[i] = -1;
			break;
		}
	}
}

/* *********************** Event_FlashDetonate *********************** */
public Event_FlashDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{	
	for(new i = 1; i <= FlashNadeNumber; i++)
	{
		if(FlashNade[i] != -1)
		{
			FlashNade[i] = -1;
			break;
		}
	}
}


/* *********************** FindNade *********************** */
public Action:FindNade(Handle:timer, any:client)
{
	new num = NadeNumber;
	new ent = -1;
	new lastent;
	new owner;
	
	if(NadeType[num] == true)
	{
		ent = FindEntityByClassname(ent, "hegrenade_projectile");
		
		while(ent != -1)
		{
			owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
			
			if(IsValidEntity(ent) && owner == client)
				break;
			
			ent = FindEntityByClassname(ent, "hegrenade_projectile");
			
			if(ent == lastent)
			{
				ent = -1;
				break;
			}	
			lastent = ent;
		}
	}
	else if(NadeType[num] == false)
	{
		ent = FindEntityByClassname(ent, "flashbang_projectile");
		
		while(ent != -1)
		{
			owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
			
			if(IsValidEntity(ent) && owner == client)
				break;
			
			ent = FindEntityByClassname(ent, "flashbang_projectile");
			
			if(ent == lastent)
			{
				ent = -1;
				break;
			}	
			lastent = ent;
		}
	}
	
	if(ent != -1)
	{
		if(NadeType[num] == true)
		{
			HeNade[HeNadeNumber] = ent;
			if(bProbeArmed[client] == true)
			{
				PrintHintText(client, "Your have launched your Remote Probe.");
				EmitSoundToAll(ProbeSnd,client);
				SetClientViewEntity(client, ent);
				bIsProbe[client] = true;
				Probe[client] = ent;
				CreateTimer(4.0, givenade, client);
			}
		}
		else if(NadeType[num] == false)
		{
			FlashNade[FlashNadeNumber] = ent;
		}
	}
}

public Action:givenade( Handle:timer, any:userid )
{
	if (ValidPlayer(userid, true))
		GivePlayerItem( userid, "weapon_hegrenade");
}

/* *********************** FindSoldier *********************** */
public Action:FindSoldier( Handle:timer, any:userid )
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && ValidPlayer( i, true ) )
		{
			if( War3_GetRace( i ) == thisRaceID )
			{
				new skill_lvl = War3_GetSkillLevel(i,thisRaceID,SKILL_FORCE);
				if(skill_lvl > 0 )
				{
					/* ********** HeGrenades ********** */
					for(new n = 1; n <= HeNadeNumber; n++)
					{
						if(IsValidEntity(HeNade[n]) && HeNade[n] != -1 && HeNade[n] != Probe[i])
						{
							new Float:SoldierPos[3];
							new Float:GrenadeVec[3];
							GetClientAbsOrigin(i,SoldierPos);
							GetEntPropVector(HeNade[n], Prop_Send, "m_vecOrigin", HeNadePos[n]);
							MakeVectorFromPoints(SoldierPos,HeNadePos[n],GrenadeVec);
							
							if(GetVectorLength(GrenadeVec,false) <= NadeDistance[skill_lvl])
							{
								new Float:EffectPos[3];
								EffectPos[0] = SoldierPos[0];
								EffectPos[1] = SoldierPos[1];
								EffectPos[2] = SoldierPos[2]+50.0;
								
								if(GetClientTeam(i) == 2)
								{
									TE_SetupBeamPoints( EffectPos, HeNadePos[n], BeamSprite, HaloSprite, 0, 8, 0.1, 1.5, 10.0, 10, 10.0, {255,0,0,155}, 70 ); // czerwony
									TE_SendToAll();
								}
								else
								{
									TE_SetupBeamPoints( EffectPos, HeNadePos[n], BeamSprite, HaloSprite, 0, 8, 0.1, 1.5, 10.0, 10, 10.0, {30,100,255,255}, 70); // niebieski
									TE_SendToAll();
								}
								
								new Float:velocity[3];
								velocity[0] = (HeNadePos[n][0]-SoldierPos[0]) * NadePushForce;
								velocity[1] = (HeNadePos[n][1]-SoldierPos[1]) * NadePushForce;
								velocity[2] = (HeNadePos[n][2]-SoldierPos[2]) * NadePushForce;
								SetEntDataVector(HeNade[n],m_vecBaseVelocity,velocity,true);
								EmitSoundToAll(ForceFieldSnd,i);
							}
						}
					}
					
					/* ********** FlashBangs ********** */
					for(new n = 1; n <= FlashNadeNumber; n++)
					{
						if(IsValidEntity(FlashNade[n]) && FlashNade[n] != -1)
						{
							new Float:SoldierPos[3];
							new Float:GrenadeVec[3];
							GetClientAbsOrigin(i,SoldierPos);
							GetEntPropVector(FlashNade[n], Prop_Send, "m_vecOrigin", FlashNadePos[n]);
							MakeVectorFromPoints(SoldierPos,FlashNadePos[n],GrenadeVec);
							
							if(GetVectorLength(GrenadeVec,false) <= NadeDistance[skill_lvl])
							{
								new Float:EffectPos[3];
								EffectPos[0] = SoldierPos[0];
								EffectPos[1] = SoldierPos[1];
								EffectPos[2] = SoldierPos[2]+50.0;
								
								if(GetClientTeam(i) == 2)
								{
									TE_SetupBeamPoints( EffectPos, FlashNadePos[n], BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, {255,0,0,155}, 70 ); // czerwony
									TE_SendToAll();
								}
								else
								{
									TE_SetupBeamPoints( EffectPos, FlashNadePos[n], BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, {30,100,255,255}, 70); // niebieski
									TE_SendToAll();
								}
								
								new Float:velocity[3];
								velocity[0] = (FlashNadePos[n][0]-SoldierPos[0]) * NadePushForce;
								velocity[1] = (FlashNadePos[n][1]-SoldierPos[1]) * NadePushForce;
								velocity[2] = (FlashNadePos[n][2]-SoldierPos[2]) * NadePushForce;
								SetEntDataVector(FlashNade[n],m_vecBaseVelocity,velocity,true);
								EmitSoundToAll(ForceFieldSnd,i);
							}
						}
					}
				}
			}
		}
	}
}

/* *********************** OnUltimateCommand *********************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_PROBE );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_PROBE, true ) )
			{
				if(bProbeArmed[client] == false)
				{
					PrintHintText(client, "Remote Probe Armed");
					EmitSoundToAll(ArmedSnd,client);
					bProbeArmed[client] = true;
				}
				else
				{
					PrintHintText(client, "Remote Probe Disarmed");
					EmitSoundToAll(ArmedSnd,client);
					bProbeArmed[client] = false;
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Remote Probe first.");
		}
	}
}

/* *********************** OnGameFrame *********************** */
public OnGameFrame()
{
	static Float:vec[3];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(Probe[i] > MaxClients && IsClientInGame(i) && IsPlayerAlive(i) && bIsProbe[i] == true)
		{
			GetEntPropVector(i, Prop_Send, "m_angRotation", vec);
			//PrintToServer("%f %f %f",vec[0],vec[1],vec[2]);
			SetEntPropVector(Probe[i], Prop_Send, "m_angRotation", vec);
		}
	}
}

/* *************************************** Bomber *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{		
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_BOMB);
		if(skill>0)
		{
			if(!Silenced(client))
			{
				if(BombNumber[client] < skill)
				{
					BombNumber[client]++;
					new Float: BomberPos[3];
					GetClientAbsOrigin(client,BomberPos);
					Bomb[client][BombNumber[client]] = CreateEntityByName("prop_physics_override");
					new newbomb = Bomb[client][BombNumber[client]];
					if (Bomb[client][BombNumber[client]] > 0 && IsValidEntity(Bomb[client][BombNumber[client]]))
					{
						decl String:entname[16];
						Format(entname, sizeof(entname), "bomb%i",client);
						SetEntityModel(newbomb, "models/weapons/w_c4_planted.mdl");
						ActivateEntity(newbomb);
						DispatchKeyValue(newbomb, "StartDisabled", "false");
						DispatchKeyValue(newbomb, "targetname", entname);
						DispatchSpawn(newbomb);				
						DispatchKeyValue(newbomb, "disablereceiveshadows", "1");
						DispatchKeyValue(newbomb, "disableshadows", "1");																	
						SetEntProp(newbomb, Prop_Send, "m_nSolidType", 6);
						SetEntProp(newbomb, Prop_Send, "m_CollisionGroup", 2);
						SetEntProp(newbomb, Prop_Send, "m_usSolidFlags", 5);				
						SetEntityMoveType(newbomb, MOVETYPE_NONE);
						//SetEntProp(newbomb, Prop_Send, "m_takedamage", 0);
						SetEntityFlags(newbomb, 18);
						
						if(GetClientTeam(client) == 3) 
						{
							SetEntityRenderColor(newbomb, 30, 100, 255, 155);
						}
						else 
						{
							SetEntityRenderColor(newbomb, 255, 0, 0, 155);
						}				
						AcceptEntityInput(newbomb, "DisableMotion");
						TeleportEntity(newbomb, BomberPos, NULL_VECTOR, NULL_VECTOR);
						
						switch(BombNumber[client])
						{
							case 1:
							{
								GetEntPropVector(newbomb, Prop_Send, "m_vecOrigin", BombPos1[client]);
							}
							case 2:
							{
								GetEntPropVector(newbomb, Prop_Send, "m_vecOrigin", BombPos2[client]);
							}
							case 3:
							{
								GetEntPropVector(newbomb, Prop_Send, "m_vecOrigin", BombPos3[client]);
							}
							case 4:
							{
								GetEntPropVector(newbomb, Prop_Send, "m_vecOrigin", BombPos4[client]);
							}
						}
						
						bIsPlanted[client] = true;
						ActiveBombs[client]++;
						bIsBombAlive[client][BombNumber[client]] = true;
						PrintHintText(client, "%d/%d Bombs Planted",BombNumber[client],skill);
						EmitSoundToAll(BomberSnd,client);
						CreateTimer(2.0, FinalPlant,newbomb);
						CreateTimer( 0.1, BombCheck, client,TIMER_REPEAT);
					}
				}
				else
				{
					PrintHintText(client, "You cannot plant more bombs");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Bomber first");
		}
	}
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
	{
		new skill_lvl = War3_GetSkillLevel(client,thisRaceID,SKILL_BOMB);
		if(skill_lvl > 0)
		{
			if(!Silenced(client))
			{
				if(ActiveBombs[client] > 0)
				{
					for(new i = 1; i <= BombNumber[client]; i++)
					{
						if(IsValidEdict(Bomb[client][i]))
						{
							if(bIsBombAlive[client][i])
							{
								Detonate(client,skill_lvl,i);
							}
						}
					}
					bIsPlanted[client] = false;
				}
				else
				{
					PrintHintText(client, "Plant some bombs first");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Bomber first");
		}
	}
}

/* *********************** Detonate *********************** */
public Detonate(any:client, any:skill_lvl, any:id)
{
	switch(id)
	{
		case 1:
		{
			TE_SetupGlowSprite(BombPos1[client],Explosion1,1.5,0.4,155);
			TE_SendToAll();				
			TE_SetupGlowSprite(BombPos1[client],Explosion2,1.5,0.4,155);
			TE_SendToAll();		
			EmitSoundToAll(ExplosionSnd,Bomb[client][1]);
			
			new Float:VictimPos[3];
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( ValidPlayer( i, true ) && !W3HasImmunity( i, Immunity_Skills ))
				{
					GetClientAbsOrigin( i, VictimPos );
					if(GetVectorDistance( BombPos1[client], VictimPos) <= BombRadius[skill_lvl])
					{
						War3_DealDamage(i,BombDamage[skill_lvl],client,_,"ubersoldierbomb",_,W3DMGTYPE_TRUEDMG);
					}
				}
			}
		}
		case 2:
		{
			TE_SetupGlowSprite(BombPos2[client],Explosion1,1.5,0.4,155);
			TE_SendToAll();				
			TE_SetupGlowSprite(BombPos2[client],Explosion2,1.5,0.4,155);
			TE_SendToAll();		
			EmitSoundToAll(ExplosionSnd,Bomb[client][2]);
			
			new Float:VictimPos[3];
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( ValidPlayer( i, true ) && !W3HasImmunity( i, Immunity_Skills ))
				{
					GetClientAbsOrigin( i, VictimPos );
					if(GetVectorDistance( BombPos2[client], VictimPos) <= BombRadius[skill_lvl])
					{
						War3_DealDamage(i,BombDamage[skill_lvl],client,_,"ubersoldierbomb",_,W3DMGTYPE_TRUEDMG);
					}
				}
			}
		}
		case 3:
		{
			TE_SetupGlowSprite(BombPos3[client],Explosion1,1.5,0.4,155);
			TE_SendToAll();				
			TE_SetupGlowSprite(BombPos3[client],Explosion2,1.5,0.4,155);
			TE_SendToAll();		
			EmitSoundToAll(ExplosionSnd,Bomb[client][3]);
			
			new Float:VictimPos[3];
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( ValidPlayer( i, true ) && !W3HasImmunity( i, Immunity_Skills ))
				{
					GetClientAbsOrigin( i, VictimPos );
					if(GetVectorDistance( BombPos3[client], VictimPos) <= BombRadius[skill_lvl])
					{
						War3_DealDamage(i,BombDamage[skill_lvl],client,_,"ubersoldierbomb",_,W3DMGTYPE_TRUEDMG);
					}
				}
			}
		}
		case 4:
		{
			TE_SetupGlowSprite(BombPos4[client],Explosion1,1.5,0.4,155);
			TE_SendToAll();				
			TE_SetupGlowSprite(BombPos4[client],Explosion2,1.5,0.4,155);
			TE_SendToAll();
			EmitSoundToAll(ExplosionSnd,Bomb[client][4]);
			
			new Float:VictimPos[3];
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( ValidPlayer( i, true ) && !W3HasImmunity( i, Immunity_Skills ))
				{
					GetClientAbsOrigin( i, VictimPos );
					if(GetVectorDistance( BombPos4[client], VictimPos) <= BombRadius[skill_lvl])
					{
						War3_DealDamage(i,BombDamage[skill_lvl],client,_,"ubersoldierbomb",_,W3DMGTYPE_TRUEDMG);
					}
				}
			}
		}
	}
	if(bIsBombAlive[client][id] == true)
	{
		AcceptEntityInput(Bomb[client][id], "Kill");
		bIsBombAlive[client][id] = false;
		ActiveBombs[client]--;
	}
}
	

/* *********************** FinalPlant *********************** */
public Action:FinalPlant( Handle:timer, any:entity )
{
	if(IsValidEdict(entity))
	{
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 6);
	}	
}

/* *********************** BombCheck *********************** */
public Action:BombCheck( Handle:timer, any:client )
{
	new bool:bIsAnyBombAlive = false;
	for(new i = 1; i <= BombNumber[client]; i++)
	{
		if(!IsValidEdict(Bomb[client][i]))
		{
			bIsBombAlive[client][i] = false;
		}
		
		if(IsClientInGame(client) && !IsPlayerAlive(client))
		{
			if(IsValidEdict(Bomb[client][i]))
			{
				AcceptEntityInput(Bomb[client][i], "Kill");
				ActiveBombs[client]--;
				bIsBombAlive[client][i] = false;
			}
		}
		
		if(bIsBombAlive[client][i] == true)
		{
			bIsAnyBombAlive = true;
		}
	}
	if(bIsAnyBombAlive == false)
	{
		bIsPlanted[client] = false;
		KillTimer(timer);
	}
}