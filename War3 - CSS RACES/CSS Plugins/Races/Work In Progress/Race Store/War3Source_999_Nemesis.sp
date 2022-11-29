/**
* File: War3Source_CustomRace_Nemesis.sp
* Description: Nemz Requested Race.
* Author(s): Fallen (aka; Fallen Shadow65).
*Last Editeded:15/09/2011.
*Last Edited by: Fallen.
*Version:0.2
*/
#pragma semicolon 1
#include <sourcemod> 
#include <sdktools_functions>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
// Chance/Data Arrays
new Float:Chance[5]={0.00,0.20,0.25,0.28,0.30};
new Float:RadiusStorm[5]={0.00,0.20,0.25,0.28,0.30};
new HealtAura[5]={0,15,25,35,45};
new Float:DamageDivider[5] = { 0.0, 6.75, 6.25, 5.75, 5.25 };
new Float:UltTime[5] = { 0.0, 3.00, 4.00, 5.00, 6.00 };
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new bool:bTransformed[64];
//for flames
#define MAXWARDS 64*4
#define WARDRADIUS 80
#define WARDBELOW -2.0
#define WARDABOVE 160.0
#define WARDDAMAGE 6
new Float:WardLocation[MAXWARDS][3]; 
new DamageStorm[5]={10,15,18,24,29};
new MaximumDamage[5]={15,18,24,29,30};
/*new DamageFire1[5]={30,40,49,52,60};
new DamageFire2[5]={35,46,52,60,72};*/
new bool:bIsTarget[MAXPLAYERS];
new FlameOwner[MAXWARDS];
new Float:LastThunderClap[MAXPLAYERS];
new CurrentFlameCount[MAXPLAYERS];
new Handle:SFXCvar;

new SKILL_FIRESTORM, SKILL_HEALTAURA, SKILL_CHEATDEATH, ULT_RAPTURE;
//fx
new String:burnsnd[]="ambient/explosions/explode_4.wav";
new String:ignitesnd[]="ambient/fire/gascan_ignite1.wav";
new String:catchsnd[]="npc/strider/fire.wav";
new BeamSprite, HaloSprite, FireSprite, Explosion, SimpleFire;

public Plugin:myinfo =
{
        name = "War3Source Race [PRIVATE ] - Nemesis",
        author = "Fallen",
        description = "Nemz Requested Race",
        version = "1.0.2",
        url = "www.SevenSinGgaming.com",
};
public OnPluginStart()
{
HookEvent("round_end",RoundEvent);
CreateTimer(0.25,Flame,_,TIMER_REPEAT);
SFXCvar=CreateConVar("war3_azgalor_hugefx_enable","1","Enable/Disable distracting and revealing sfx");
}
public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Nemesis [privite]","Nemz");
	SKILL_FIRESTORM=War3_AddRaceSkill(thisRaceID,"Fire Storm(passive)","Call down waves of fire",false);
	SKILL_HEALTAURA=War3_AddRaceSkill(thisRaceID,"UnspokeN strength(passive)","increases maximum health by 15 / 25/ 35 / 45",false);
	SKILL_CHEATDEATH=War3_AddRaceSkill(thisRaceID,"Cheat Death(passive)","You have a chance of getting dmg back as HP",false);
	ULT_RAPTURE=War3_AddRaceSkill(thisRaceID,"Ultimate: Nemception","Gain more speed, lower grav and longer jumps",false); 
	
	War3_CreateRaceEnd(thisRaceID);
}

public OnRaceChanged(client, oldrace, newrace )
{
	if( newrace != thisRaceID)
	{
		W3ResetAllBuffRace( client, thisRaceID );
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		RemoveFlames(client);
	}
	if( newrace == thisRaceID )
	{
		new String:SteamID[64];
		GetClientAuthString( client, SteamID, 64 );
		if( !StrEqual( "STEAM_0:1:12118879", SteamID ) )
		{
			if( !StrEqual( "STEAM_0:0:14461408", SteamID ) )
			{
				CreateTimer( 0.5, ForceChangeRace, client );
			}
		}
	}

}

public Action:ForceChangeRace( Handle:timer, any:client )
{
	War3_SetRace( client, War3_GetRaceIDByShortname( "undead" ) );
	PrintHintText( client, "Race is restricted to NemZ" );
}

public OnMapStart()
{
	War3_PrecacheSound(ignitesnd);
	War3_PrecacheSound(burnsnd);
	BeamSprite=PrecacheModel("sprites/orangelight1.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	FireSprite=PrecacheModel("effects/fire_cloud2.vmt");
	SimpleFire=PrecacheModel("sprites/flatflame.vmt");
	Explosion=PrecacheModel("sprites/floorfire4_.vmt");
}

public OnWar3EventSpawn(client)
{

	new user_race = War3_GetRace(client);
	if(user_race==thisRaceID)
	{
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.2 );
		bTransformed[client] = false;
		RemoveFlames(client);
		InitPassiveSkills(client);
		bTransformed[client] = false;
		new Float:iVec[3];
		GetClientAbsOrigin(client, Float:iVec);
		new Float:iVec2[3];
		GetClientAbsOrigin(client, Float:iVec2);
		iVec[2]+=100;
		iVec2[2]+=100;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(0.3);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(0.6);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(0.9);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(1.2);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(1.5);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(1.8);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,120.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(2.1);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,120.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(2.1);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,120.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(2.4);
		TE_SetupGlowSprite(iVec,SimpleFire,3.0,1.00,212);
		TE_SendToAll();
		TE_SetupDynamicLight(iVec,255,0,0,12,80.0,2.8,1.0);
		TE_SendToAll(2.4);
	}
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
	bTransformed[victim] = false;
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_cheatdeath = War3_GetSkillLevel( attacker, thisRaceID, SKILL_CHEATDEATH );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.70 && skill_cheatdeath > 0 )
			{	
				War3_HealToBuffHP( attacker, RoundToFloor( damage / DamageDivider[skill_cheatdeath] ) );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
		}
	}
}



public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_healthaura=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALTAURA);
		if(skill_healthaura)
		{
			new hpadd=HealtAura[skill_healthaura];
			War3_SetBuff(client,iAdditionalMaxHealth, thisRaceID, hpadd);
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_RAPTURE );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_RAPTURE, true ) )
			{
				StartTransform( client );
				War3_CooldownMGR( client, UltTime[ult_level] + 13.0, thisRaceID, ULT_RAPTURE, false);
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public Action:EndTransform( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.2 );
		bTransformed[client] = false;
	}
}

stock StartTransform( client )
{
	new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_RAPTURE );
	CreateTimer( UltTime[ult_level], EndTransform, client );
	War3_SetBuff( client, fLowGravitySkill, thisRaceID, 0.60 );
	War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.70 );
	bTransformed[client] = true;
}



public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new ult = War3_GetSkillLevel( client, race, ULT_RAPTURE );
		if( ult > 0 && bTransformed[client] )
		{
			new Float:velocity[3] = { 0.0, 0.0, 0.0 };
			velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
			velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
			velocity[0] *= 3.0;
			velocity[1] *= 3.0;
			SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
		}
	}
}

//Flame
public CreateFlame(client,target)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(FlameOwner[i]==0)
		{
			FlameOwner[i]=client;
			GetClientAbsOrigin(target,WardLocation[i]);
			break;
		}
	}
}

public RemoveFlames(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(FlameOwner[i]==client)
		{
			FlameOwner[i]=0;
		}
	}
	CurrentFlameCount[client]=0;
}

public Action:Flame(Handle:timer,any:userid)
{
	new client;
	for(new i=0;i<MAXWARDS;i++)
	{
		if(FlameOwner[i]!=0)
		{
			client=FlameOwner[i];
			if(!ValidPlayer(client,true))
			{
				FlameOwner[i]=0;
				--CurrentFlameCount[client];
			}
			else
			{
				FlameLoop(client,i);
			}
		}
	}
}

public FlameLoop(owner,wardindex)
{
	new ownerteam=GetClientTeam(owner);
	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	new Float:tempVec2[]={0.0,0.0,WARDABOVE};
	AddVectors(WardLocation[wardindex],tempVec1,start_pos);
	AddVectors(WardLocation[wardindex],tempVec2,end_pos);
	//TE_SetupGlowSprite(start_pos,SimpleFire,0.26,1.00,212);
	//TE_SendToAll();
	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x];
	new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;
	
	
	new Float:VictimPos[3];
	new Float:tempZ;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam )
		{
			GetClientAbsOrigin(i,VictimPos);
			tempZ=VictimPos[2];
			VictimPos[2]=0.0;
			      
			if(GetVectorDistance(BeamXY,VictimPos) < WARDRADIUS)
			{
				if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
				{
					if(W3HasImmunity(i,Immunity_Skills))
					{
						W3MsgSkillBlocked(i,_,"Expulsion");
					}
					else
					{
						W3FlashScreen(i,{0,0,0,255});
						if(War3_DealDamage(i,WARDDAMAGE,owner,DMG_BULLET,"flame",_,W3DMGTYPE_MAGIC))
						{
							if(LastThunderClap[i]<GetGameTime()-2){
								EmitSoundToAll(ignitesnd,i,SNDCHAN_WEAPON);
								LastThunderClap[i]=GetGameTime();
							}
						}
					}
				}
			}
		}
	}
}

public RoundEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new x=1;x<=64;x++)
	{
		new race = War3_GetRace(x);
		if (race == thisRaceID)
		{
			RemoveFlames(x);
			bIsTarget[x]=true;
		}
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FIRESTORM);
			if(race_attacker==thisRaceID && skill_level>0 )
			{
				if(GetRandomFloat(0.0,1.0)<=Chance[skill_level] && !W3HasImmunity(victim,Immunity_Skills))
				{
					new Float:spos[3];
					new Float:epos[3];
					GetClientAbsOrigin(victim,epos);
					GetClientAbsOrigin(attacker,spos);
					epos[2]+=35;
					spos[2]+=100;
					if(GetConVarBool(SFXCvar))
					{
						TE_SetupBeamPoints(spos, epos, BeamSprite, BeamSprite, 0, 35, 1.0, 10.0, 10.0, 0, 10.0, {255,25,25,255}, 30);
						TE_SendToAll();
					}
					new damage1=DamageStorm[skill_level];
					new damage2=MaximumDamage[skill_level];
					new Float:radius=RadiusStorm[skill_level];
					DoFire(attacker,victim,radius,damage1,damage2,true);
					
					W3FlashScreen(victim,RGBA_COLOR_RED);
				
					//bIsTarget[victim]=true;
					CreateTimer( 0.10, Timer_DeSelect, victim );

					EmitSoundToAll(burnsnd,victim);
					//PrintHintText(attacker,"Fire Storm");
				}
			}
		}
	}
}

stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
    TE_Start("Dynamic Light");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("r",r);
    TE_WriteNum("g",g);
    TE_WriteNum("b",b);
    TE_WriteNum("exponent",iExponent);
    TE_WriteFloat("m_fRadius",fRadius);
    TE_WriteFloat("m_fTime",fTime);
    TE_WriteFloat("m_fDecay",fDecay);
}

public DoFire(attacker,victim,Float:radius,damage,maxdmg,bool:showmsg)
{
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,true))
	{
		if(War3_GetRace(attacker)==thisRaceID && War3_GetRace(victim)!=War3_GetRaceIDByShortname("azgalor"))
		{
			new Float:StartPos[3];
			new Float:EndPos[3];
			
			GetClientAbsOrigin( attacker, StartPos );
			GetClientAbsOrigin( victim, EndPos );

			StartPos[2]+=100;
			TE_SetupGlowSprite(StartPos,FireSprite,3.0,0.80,212);
			TE_SendToAll();
			TE_SetupBeamRingPoint(StartPos,74.0,76.0,HaloSprite,HaloSprite,0,15,3.45,280.0,2.0,{255,77,77,255},0,0);
			TE_SendToAll();
			TE_SetupDynamicLight(StartPos,255,80,80,10,radius,3.30,2.2);
			TE_SendToAll();
			W3FlashScreen(attacker,RGBA_COLOR_RED);
			EmitSoundToClient(attacker, catchsnd);				
			new waveammount = GetRandomInt(1,3);
			if(waveammount!=0)
			{
				DoExplosion(damage,maxdmg,attacker,victim);
			}
			if(waveammount==2)
			{
				DoExplosion(damage,maxdmg,attacker,victim);
			}
			if(waveammount==3)
			{
				DoExplosion(damage,maxdmg,attacker,victim);
			}
			if(showmsg)
			{
				PrintHintText(attacker,"Fire Storm:\nCasted %i waves of Fire",waveammount);
			}
		}
	}
}

public DoExplosion(magnitude,maxdmg,client,target)
{
	//Destination = Owner
	//Vec = Fireball
	//Origin = Victim
	new Float:Destination[3];
	GetClientAbsOrigin(client,Destination);
	new AttackerTeam = GetClientTeam(client);
	TE_SetupBeamRingPoint(Destination,1.0,9000.0,HaloSprite,HaloSprite,0,15,2.8,10.0,2.0,{255,120,120,255},0,0);
	TE_SendToAll();
	War3_DealDamage(target,3,client,DMG_BULLET,"firestorm");
	//schaden simlurieren und spieler schmokeln lassen
	for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true) && GetClientTeam(i)!=AttackerTeam && !bIsTarget[i])
			{
				bIsTarget[i]=true;
				CreateTimer( 0.10, Timer_DeSelect, i );
				new Float:Vec[3];
				GetClientAbsOrigin(target,Vec);
				new Float:Origin[3];
				GetClientAbsOrigin(i,Origin);
				Vec[0] += GetRandomFloat( -150.0, 150.0 );
				Vec[1] += GetRandomFloat( -150.0, 150.0 );
				Vec[2] += 10.0;
				if(GetConVarBool(SFXCvar))
				{
					TE_SetupExplosion(Vec, Explosion, 6.5, 1, 4, 0, 0);
					TE_SendToAll();
					TE_SetupExplosion(Vec, Explosion, 6.5, 1, 4, 0, 0);
					TE_SendToAll(0.18);
					Destination[2] += 100.0;
					TE_SetupBeamPoints( Vec, Destination, BeamSprite, HaloSprite, 0, 1, 0.61, 20.0, 2.0, 0, 1.0, { 255, 11, 11, 255 }, 1 );
					TE_SendToAll();
				}
				if(GetVectorDistance(Origin,Vec) < 100.0)
				{
					new magdmg = GetRandomInt(magnitude,maxdmg);
					PrintToConsole(client,"FireStorm hit a target and damaged him for %d damage",magdmg);
					IgniteEntity(i, 2.0);
					EmitSoundToClient(i, ignitesnd);
					W3FlashScreen(i,RGBA_COLOR_RED);
					War3_ShakeScreen(i);
					//TODO 1 - may add explosion sounds?
					War3_DealDamage(i,magdmg,client,DMG_BULLET,"firestorm");
					PrintToConsole(i,"hit by a firestorm");
					PrintCenterText(client,"Firestorm was successfully");
				}
			}
		}
}


public Action:Timer_DeSelect(Handle:timer, any:client)
{
	if(ValidPlayer(client,true))
	{
		bIsTarget[client]=false;
	}
}

public Action:Timer_Extinguish(Handle:timer, any:client)
{
	if(ValidPlayer(client,true))
	{
		RemoveFlames(client);
	}
}

