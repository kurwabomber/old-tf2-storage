/**
* File: War3Source_999_Tutankhamun.sp
* Description: Ready's Private race for war3source
* Author(s): Remy Lebeau (copied from Fallen's race)
*/

#pragma semicolon 1
#include <sourcemod> 
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
// Chance/Data Arrays
new Float:Chance[5]={0.00,0.20,0.25,0.28,0.30};
new Float:RadiusStorm[5]={0.00,0.20,0.25,0.28,0.30};
new HealtAura[5]={0,15,25,35,45};
new Float:DamageDivider[5] = { 0.0, 5.75, 5.25, 4.75, 4.25 };
new Float:UltTime[5] = { 0.0, 3.00, 5.00, 8.00, 10.00 };
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new bool:bTransformed[64];
//for flames
#define MAXWARDS 64*4
#define WARDRADIUS 80
#define WARDBELOW -2.0
#define WARDABOVE 160.0
#define WARDDAMAGE 6
new DamageStorm[5]={10,15,18,24,29};
new MaximumDamage[5]={15,18,24,29,30};
/*new DamageFire1[5]={30,40,49,52,60};
new DamageFire2[5]={35,46,52,60,72};*/
new bool:bIsTarget[MAXPLAYERS];
new FlameOwner[MAXWARDS];
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
        name = "War3Source Race - Tutankhamun",
        author = "Remy Lebeau (Fallen)",
        description = "Ready's private race",
        version = "1.1",
        url = "www.SevenSinGgaming.com",
};
public OnPluginStart()
{
HookEvent("round_end",RoundEvent);
SFXCvar=CreateConVar("war3_tutankhamun_hugefx_enable","1","Enable/Disable distracting and revealing sfx");
}

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Tutankhamun [PRIVATE]","tutankhamun");
	SKILL_FIRESTORM=War3_AddRaceSkill(thisRaceID,"Fire Storm","Call down the wrath of the God's upon your attackers (passive)",false);
	SKILL_HEALTAURA=War3_AddRaceSkill(thisRaceID,"Strength of the ages","Mummification has it's benefits - like extra health(passive)",false);
	SKILL_CHEATDEATH=War3_AddRaceSkill(thisRaceID,"Cheat Death","You have a chance of getting dmg back as HP (passive)",false);
	ULT_RAPTURE=War3_AddRaceSkill(thisRaceID,"Mummy is ANGRY","Gain more speed, lower grav and invisibility (+ultimate)",true); 
	
	War3_CreateRaceEnd(thisRaceID);
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



/***************************************************************************
*
*
*				PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnRaceChanged(client, oldrace, newrace )
{
	if( newrace != thisRaceID)
	{
		W3ResetAllBuffRace( client, thisRaceID );
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		RemoveFlames(client);
	}
	else
	{
		if (ValidPlayer (client, true))
		{
			InitPassiveSkills(client);
		}
	}

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



/***************************************************************************
*
*
*				ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


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




/***************************************************************************
*
*
*				EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
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
				W3FlashScreen( attacker, RGBA_COLOR_GREEN );
			}
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


public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
	bTransformed[victim] = false;
}



/***************************************************************************
*
*
*				HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/


public Action:EndTransform( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.2 );
		War3_SetBuff(client, fInvisibilitySkill, thisRaceID, 1.0);
		bTransformed[client] = false;
		W3FlashScreen( client, RGBA_COLOR_RED, 0.1 , 0.5, FFADE_OUT);
	}
}

stock StartTransform( client )
{
	W3FlashScreen( client, RGBA_COLOR_GREEN, 0.1 , 0.5, FFADE_OUT);              
	new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_RAPTURE );
	CreateTimer( UltTime[ult_level], EndTransform, client );
	War3_SetBuff( client, fLowGravitySkill, thisRaceID, 0.60 );
	War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.50 );
	War3_SetBuff(client, fInvisibilitySkill, thisRaceID, 0.5);
	bTransformed[client] = true;
	
}



//Flame

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

