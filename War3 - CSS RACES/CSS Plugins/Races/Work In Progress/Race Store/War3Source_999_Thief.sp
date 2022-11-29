#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Thief",
	author = "M.A.C.A.B.R.A",
	description = "Thief race for War3Source.",
	version = "1.0.3",
	url = "http://strefagier.com.pl/"
};


// War3Source stuff
new thisRaceID;


new Float:RobeInvis[] = {100.0,75.0,50.0,25.0,0.01}; 
new Float:RobeTime[] = {0.0,2.0,4.0,6.0,8.0};
new bool:bIsInvis[MAXPLAYERS];

new Float:TrickRange[] = {0.0,200.0,400.0,600.0,800.0};

new Float:corpselocation[3][MAXPLAYERS][20];
new dietimes[MAXPLAYERS];
new corpsehealth[MAXPLAYERS][20];
new bool:corpseplayed[MAXPLAYERS][20];
new bool:corpsedied[MAXPLAYERS][20];
new TheftTime[] = {0, 5, 10, 15, 20};
new Float:TheftBeamTime[] = {0.0, 0.5, 1.0, 1.5, 2.0};

#define MAXWARDS 64*4
#define WARDRADIUS 95
#define WARDXP 1
#define WARDBELOW -2.0
#define WARDABOVE 140.0

new WardStartingArr[] = { 0, 1, 2, 3, 4};
new Float:WardLocation[MAXWARDS][3];
new CurrentWardCount[MAXPLAYERS];
new Float:LastWardRing[MAXWARDS];
new Float:LastWardClap[MAXWARDS];
new WardOwner[MAXWARDS];

//Sounds
new String:RobeOnSnd[]="npc/scanner/scanner_nearmiss1.wav";
new String:RobeOffSnd[]="npc/scanner/scanner_nearmiss2.wav";
new String:TheftSnd[]="war3source/thief/theft.mp3";
new String:TrapSnd[]="war3source/thief/trap.mp3";
new String:TrickASnd[]="war3source/thief/hahah.mp3";
new String:TrickVSnd[]="war3source/thief/aua.mp3";


new LightningSprite, HaloSprite, PurpleGlowSprite, BeamSprite;

new SKILL_ROBE, SKILL_THEFT, SKILL_WARD, ULT_TRICK;

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Thief", "thief" );
	
	SKILL_ROBE = War3_AddRaceSkill( thisRaceID, "Robe of Invisibility", "Invisibility for a short period of time while using knife.", false, 4 ); //[X]
	SKILL_THEFT = War3_AddRaceSkill( thisRaceID, "Theft", "Steals gold from your enemy's corpses.", false, 4 );	// [X]
	SKILL_WARD = War3_AddRaceSkill( thisRaceID, "Thievish Trap", "Steals experience from enemies who passes through your trap.(+ability)", false, 4 ); // [X]
	ULT_TRICK = War3_AddRaceSkill( thisRaceID, "Wicked Trick", "Turns the amount of HP with your enemy.(+ultimate)", true, 4 ); // [X]
	
	War3_CreateRaceEnd( thisRaceID );
}

public OnPluginStart()
{
	CreateTimer( 0.2, CalcWards, _, TIMER_REPEAT );
	CreateTimer( 0.1, CalcRobe, _, TIMER_REPEAT );	
	CreateTimer(0.5,Steal,_,TIMER_REPEAT);
}

public OnMapStart()
{
	//Sounds
	War3_PrecacheSound(RobeOnSnd);
	War3_PrecacheSound(RobeOffSnd);
	War3_PrecacheSound(TheftSnd);
	War3_PrecacheSound(TrapSnd);
	War3_PrecacheSound(TrickASnd);
	War3_PrecacheSound(TrickVSnd);
	LightningSprite = PrecacheModel( "sprites/lgtning.vmt" );
	HaloSprite = PrecacheModel( "sprites/halo01.vmt" );
	PurpleGlowSprite = PrecacheModel( "sprites/purpleglow1.vmt" );
	BeamSprite = PrecacheModel("materials/sprites/lgtning.vmt");
}


public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		RemoveWards( client );
		W3ResetAllBuffRace( client, thisRaceID );
	}
}

public OnWar3EventSpawn( client )
{
	War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
	bIsInvis[client] = false;
	
	RemoveWards( client );
	resetcorpses();
}

/* *************************************** CalcRobe *************************************** */
public Action:CalcRobe( Handle:timer, any:userid )
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			if( War3_GetRace( i ) == thisRaceID )
			{
				Robe(i);
			}		
		}
	}	
}

/* *************************************** Robe Stuff *************************************** */
public Robe(client)
{
	new skill_robe = War3_GetSkillLevel( client, thisRaceID, SKILL_ROBE );
	if( skill_robe > 0)
	{
		decl String:weapon[64];
		GetClientWeapon(client, weapon, sizeof(weapon));
		if(StrEqual(weapon, "weapon_knife"))
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ROBE,true) && bIsInvis[client] == false)
			{
				War3_CooldownMGR(client,15.0,thisRaceID,SKILL_ROBE,_,_);
				PrintHintText(client, "You set up your robe.");	
				EmitSoundToAll(RobeOnSnd,client);
				CreateTimer(RobeTime[skill_robe], Visible, client);
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,RobeInvis[skill_robe]);
				bIsInvis[client] = true;
			}
		}
		else
		{
			if(bIsInvis[client] == true)
			{
				W3ResetAllBuffRace( client, thisRaceID );
				bIsInvis[client] = false;
				EmitSoundToAll(RobeOffSnd,client);
				PrintHintText(client, "You removed your robe.");
			}
			else
			{
				W3ResetAllBuffRace( client, thisRaceID );
				bIsInvis[client] = false;
			}
		}
		
	}
}

public Action:Visible(Handle:timer,any:client)
{
	if (ValidPlayer(client,true))
	{
		if(bIsInvis[client] == true)
		{
			W3ResetAllBuffRace( client, thisRaceID );
			bIsInvis[client] = false;
			EmitSoundToAll(RobeOffSnd,client);
			PrintHintText(client, "You removed your robe.");
		}
		else
		{
			W3ResetAllBuffRace( client, thisRaceID );
			bIsInvis[client] = false;
		}
	}	
}



/* *************************************** Theft Stuff *************************************** */
public OnWar3EventDeath(victim,attacker)
{
	new deaths=dietimes[victim];
	dietimes[victim]++;
	corpsedied[victim][deaths]=true;
	new skill_theft = War3_GetSkillLevel( attacker, thisRaceID, SKILL_THEFT );
	if( skill_theft > 0)
	{
		corpsehealth[victim][deaths]=TheftTime[skill_theft];
		corpseplayed[victim][deaths] = false;
	}
	else
	{
		corpsehealth[victim][deaths]=0;
	}		
	new Float:pos[3];
	War3_CachedPosition(victim,pos);
	corpselocation[0][victim][deaths]=pos[0];
	corpselocation[1][victim][deaths]=pos[1];
	corpselocation[2][victim][deaths]=pos[2];
	for(new client=0;client<=MaxClients;client++){
		if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
			if( War3_GetRace(client)==thisRaceID && ValidPlayer(client,true) && skill_theft > 0)
			{
				TE_SetupBeamRingPoint(pos,25.0,75.0,BeamSprite,HaloSprite,0,15,TheftBeamTime[skill_theft],20.0,3.0,{255,150,70,255},20,0);
				TE_SendToClient(client);
			}
		}
	}
	
	W3ResetAllBuffRace( victim, thisRaceID );
}

public Action:Steal(Handle:timer)
{
	for(new client=0;client<=MaxClients;client++)
	{
		if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true))
		{
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_THEFT);
			if(skill_level>0)
			{
				for(new corpse=0;corpse<=MaxClients;corpse++)
				{
					for(new deaths=0;deaths<=19;deaths++)
					{
						if(corpsedied[corpse][deaths]==true)
						{
							new Float:corpsepos[3];
							new Float:clientpos[3];
							GetClientAbsOrigin(client,clientpos);
							corpsepos[0]=corpselocation[0][corpse][deaths];
							corpsepos[1]=corpselocation[1][corpse][deaths];
							corpsepos[2]=corpselocation[2][corpse][deaths];
							
							if(GetVectorDistance(clientpos,corpsepos)<50)
							{
								if(corpsehealth[corpse][deaths]>=0)
								{
									W3FlashScreen(client,{155,0,0,40},0.1);
									corpsehealth[corpse][deaths]-=5;
									War3_SetGold(corpse,War3_GetGold(corpse) - 1);
									War3_SetGold(client,War3_GetGold(client) + 1);
									if(corpseplayed[corpse][deaths] == false)
									{
										corpseplayed[corpse][deaths] = true;
										EmitSoundToAll(TheftSnd,client);
										PrintHintText(client, "You have found some gold.");										
									}
								}
							}
							else
							{
								corpsehealth[corpse][deaths]-=5;
							}
						}
					}
				}
			}
		}
	}
}

public resetcorpses()
{
	for(new client=0;client<=MaxClients;client++){
		for(new deaths=0;deaths<=19;deaths++){
			corpselocation[0][client][deaths]=0.0;
			corpselocation[1][client][deaths]=0.0;
			corpselocation[2][client][deaths]=0.0;
			dietimes[client]=0;
			corpsehealth[client][deaths]=0;
			corpseplayed[client][deaths]=false;
			corpsedied[client][deaths]=false;
		}
	}
}


/* *************************************** Wards Stuff *************************************** */
public OnAbilityCommand( client, ability, bool:pressed )
{
	if( War3_GetRace( client ) == thisRaceID && ability == 0 && pressed && IsPlayerAlive( client ) )
	{
		new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_WARD );
		if( skill_level > 0 )
		{
			if( !Silenced( client ) && CurrentWardCount[client] < WardStartingArr[skill_level] )
			{
				CreateWard( client );
				CurrentWardCount[client]++;
				W3MsgCreatedWard( client, CurrentWardCount[client], WardStartingArr[skill_level] );
			}
			else
			{
				W3MsgNoWardsLeft( client );
			}
		}
	}
}

public CreateWard( client )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] == 0 )
		{
			WardOwner[i] = client;
			GetClientAbsOrigin( client, WardLocation[i] );
			break;
		}
	}
}

public RemoveWards( client )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] == client )
		{
			WardOwner[i] = 0;
			LastWardRing[i] = 0.0;
			LastWardClap[i] = 0.0;
		}
	}
	CurrentWardCount[client] = 0;
}

public Action:CalcWards( Handle:timer, any:userid )
{
	new client;
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] != 0 )
		{
			client = WardOwner[i];
			if( !ValidPlayer( client, true ) )
			{
				WardOwner[i] = 0;
				--CurrentWardCount[client];
			}
			else
			{
				WardEffectAndDamage( client, i );
			}
		}
	}
}

public WardEffectAndDamage( owner, wardindex )
{
	new ownerteam = GetClientTeam( owner );
	new beamcolor[] = { 0, 128, 0, 255 }; // CT
	if( ownerteam == 2 ) // TT
	{
		beamcolor[0] = 0;
		beamcolor[1] = 128;
		beamcolor[2] = 0;
		beamcolor[3] = 255;
	}
	
	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[] = { 0.0, 0.0, WARDBELOW };
	new Float:tempVec2[] = { 0.0, 0.0, WARDABOVE };
	
	AddVectors( WardLocation[wardindex], tempVec1, start_pos );
	AddVectors( WardLocation[wardindex], tempVec2, end_pos );

	TE_SetupBeamPoints( start_pos, end_pos, LightningSprite, LightningSprite, 0, GetRandomInt( 30, 100 ), 0.17, 20.0, 20.0, 0, 0.0, beamcolor, 0 );
	TE_SendToAll();
	
	if( LastWardRing[wardindex] < GetGameTime() - 0.25 )
	{
		LastWardRing[wardindex] = GetGameTime();
		if( ownerteam == 2 ) // TT
		{
			TE_SetupBeamRingPoint( start_pos, 20.0, float( WARDRADIUS * 2 ), LightningSprite, LightningSprite, 0, 15, 1.0, 20.0, 1.0, { 255, 0, 0, 255 }, 10, FBEAM_ISACTIVE );			
		}
		else // CT
		{
			TE_SetupBeamRingPoint( start_pos, 20.0, float( WARDRADIUS * 2 ), LightningSprite, LightningSprite, 0, 15, 1.0, 20.0, 1.0, { 0, 0, 200, 255 }, 10, FBEAM_ISACTIVE );
		}		
		TE_SendToAll();
	}
	
	TE_SetupGlowSprite( end_pos, PurpleGlowSprite, 1.0, 1.25, 50 );
	TE_SendToAll();
	
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
			
			if( GetVectorDistance( BeamXY, VictimPos ) < WARDRADIUS )
			{
				if( tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE )
				{
					if( !W3HasImmunity( i, Immunity_Skills ) && !W3HasImmunity( i, Immunity_Wards ))
					{
						if( LastWardClap[wardindex] < GetGameTime() - 1 )
						{
							new DamageScreen[4];
							new Float:pos[3];
							
							GetClientAbsOrigin( i, pos );
							
							DamageScreen[0] = beamcolor[0];
							DamageScreen[1] = beamcolor[1];
							DamageScreen[2] = beamcolor[2];
							DamageScreen[3] = 50;
							
							W3FlashScreen( i, DamageScreen );
							
							new victimRace = War3_GetRace(i);
							
							War3_SetXP( i, victimRace, War3_GetXP( i, victimRace ) - (WARDXP * War3_GetSkillLevel(owner, thisRaceID, SKILL_WARD)));         //  ***  K R A D Z I E ¯    XP  ***						
							War3_SetXP( owner, thisRaceID, War3_GetXP( owner, thisRaceID ) + (WARDXP * War3_GetSkillLevel(owner, thisRaceID, SKILL_WARD)));     //  ***  K R A D Z I E ¯    XP  ***
							
							EmitSoundToAll(TrapSnd,i);
							
							War3_SetBuff( i, fSlow, thisRaceID, 0.7 );
							
							CreateTimer( 2.0, StopSlow, i );
							
							pos[2] += 40;
							
							TE_SetupBeamPoints( start_pos, pos, LightningSprite, LightningSprite, 0, 0, 1.0, 10.0, 20.0, 0, 0.0, { 255, 150, 70, 255 }, 0 );
							TE_SendToAll();
							
							LastWardClap[i] = GetGameTime();
						}
					}
				}
			}
		}
	}
}

public Action:StopSlow( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
	}
}

/* *************************************** OnUltimateCommand *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill = War3_GetSkillLevel(client,thisRaceID,ULT_TRICK);
		if(skill > 0)
		{			
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_TRICK,true))
			{
				new target=War3_GetTargetInViewCone(client,TrickRange[skill],false);
				if(ValidPlayer(target,true)&&!W3HasImmunity(target,Immunity_Ultimates))
				{
					War3_CooldownMGR(client,30.0,thisRaceID,ULT_TRICK,_,_);
					
					new targetHP = GetClientHealth(target);
					new clientHP = GetClientHealth(client);
					
					new difference;
					
					if(targetHP > clientHP)
					{
						difference = targetHP - clientHP;
						War3_SetMaxHP_INTERNAL(target,clientHP);
						War3_DealDamage(target,difference,client,_,"wickedtrick");
						
						War3_SetMaxHP_INTERNAL(client,targetHP);
						War3_HealToBuffHP(client,difference);
						EmitSoundToAll(TrickASnd,client);
						EmitSoundToAll(TrickVSnd,target);
					}
					else
					{
						difference = clientHP - targetHP;
						War3_SetMaxHP_INTERNAL(target,clientHP);
						War3_HealToBuffHP(target,difference);
						
						War3_SetMaxHP_INTERNAL(client,targetHP);
						War3_DealDamage(client,difference,target,_,"wickedtrick");
						EmitSoundToAll(TrickASnd,target);
						EmitSoundToAll(TrickVSnd,client);
					}
				}
				else
				{
					PrintHintText(client, "No Target Found");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your tricks first.");
		}
	}
}