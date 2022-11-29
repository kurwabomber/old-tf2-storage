#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>


new thisRaceID;

new SKILL_LUCK, SKILL_FORTUNE, SKILL_BLIND, ULT_JUMP;

// Lots of Luck
new LuckMin = 1;
new LuckMax[] = {0, 100, 80, 60, 40};

// Wheel of Fortune
new Float:CoinChance[]={0.0,0.2,0.4,0.6,0.8};
new CoinAmount[]={0,1,1,2,2};
new String:CoinSnd[]="war3source/leprechaun/coin.mp3";

// Blind Fate
new bool:bFateActived[MAXPLAYERS];
new Float:FateTime[] = {0.0, 5.0, 6.0, 7.0, 8.0};

// Joyful Jumper
new JumpCounter[MAXPLAYERS];
new JumpLimit[] = {0, 5, 10, 20, 30};
new Float:JumpHeight[] = {0.0, 300.0, 400.0, 500.0, 600.0};
new m_vecBaseVelocity;

public Plugin:myinfo = 
{
	name = "War3Source Race - Leprechaun",
	author = "M.A.C.A.B.R.A",
	description = "The Leprechaun race for War3Source.",
	version = "1.0.2",
	url = "http://strefagier.com.pl/"
}


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Leprechaun","leprechaun");
	
	SKILL_LUCK=War3_AddRaceSkill(thisRaceID,"Lots of Luck","Chance to evade bullets.",false,4); //[X]
	SKILL_FORTUNE=War3_AddRaceSkill(thisRaceID,"Wheel of Fortune","Chance to create gold coin after kill (Double amount when headshot).",false,4); // [X]
	SKILL_BLIND=War3_AddRaceSkill(thisRaceID,"Blind Fate","Invincibility after being blinded by a flashbang.",false,4); // [X]
	ULT_JUMP=War3_AddRaceSkill(thisRaceID,"Joyful Jumper","Allows you to do multi jump",true,4); // [X]
	
	War3_CreateRaceEnd(thisRaceID);
}

public OnMapStart()
{  
	//Sounds
	War3_PrecacheSound(CoinSnd);
}

public OnPluginStart()
{	
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");	
	HookEvent( "player_blind", PlayerBlindEvent );
	HookEvent( "player_death", PlayerDeathEvent );
}

public OnWar3EventSpawn(client)
{
	JumpCounter[client] = 0;
	bFateActived[client] = false;
	W3ResetPlayerColor( client, thisRaceID );
}


/* *************************************** OnW3TakeDmgBulletPre (Lots of Luck) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim) && IS_PLAYER(attacker) && victim > 0 && attacker > 0 && attacker != victim)
	{
		if(IsPlayerAlive(victim) && IsPlayerAlive(attacker))
		{
			new vteam = GetClientTeam(victim);
			new ateam = GetClientTeam(attacker);
			new race_victim = War3_GetRace(victim);
			if( vteam != ateam )
			{
				new skill_level = War3_GetSkillLevel( victim, thisRaceID, SKILL_LUCK );
				if( race_victim == thisRaceID && skill_level > 0 && !Hexed( victim, false ) && !W3HasImmunity( attacker, Immunity_Skills ))
				{
					if( GetRandomInt( LuckMin, LuckMax[skill_level] ) <= 10 )
					{
						W3FlashScreen( victim, RGBA_COLOR_GREEN );					
						War3_DamageModPercent( 0.0 );					
						W3MsgEvaded( victim, attacker );
					}
				}
			}
		}
	}
}

/* *************************************** OnWar3EventDeath (Wheel of Fortune) *************************************** */
public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	new bool:bIsHS = GetEventBool( event, "headshot" );
	
	if(War3_GetRace(client) == thisRaceID)
	{
		new skill_lvl = War3_GetSkillLevel(client,thisRaceID,SKILL_FORTUNE);
		if(skill_lvl > 0)
		{
			if(GetRandomFloat(0.0,1.0) <= CoinChance[skill_lvl])
			{
				new GoldGain = CoinAmount[skill_lvl];
				if(bIsHS == true)
				{
					GoldGain *= 2;
				}
				War3_SetGold(client,War3_GetGold(client) + GoldGain);
				PrintHintText(client,"You've created some coins.");	
				EmitSoundToAll(CoinSnd,client);
			}			
		}		
	}
}


/* *************************************** PlayerBlindEvent (Blind Fate) *************************************** */
public PlayerBlindEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new skill_level = War3_GetSkillLevel( client, race, SKILL_BLIND );
		if( skill_level > 0 )
		{
			bFateActived[client] = true;	
			PrintHintText( client, "You rely on the mercy of Blind Fate." );
			W3SetPlayerColor(client,thisRaceID, 0,255,0,255);
			CreateTimer( FateTime[skill_level], StopFate, client );	
			War3_CooldownMGR(client,15.0,thisRaceID,SKILL_BLIND,_,_);
		}
	}
}

public Action:StopFate( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		bFateActived[client] = false;		
		W3ResetPlayerColor( client, thisRaceID );
		PrintHintText( client, "Blind Fate has ended" );
	}
}

public OnW3TakeDmgAllPre( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{	
		new race_victim = War3_GetRace( victim );
		new skill_level = War3_GetSkillLevel( victim, thisRaceID, SKILL_BLIND );
			
		if( race_victim == thisRaceID && skill_level > 0 && bFateActived[victim] )
		{
			if( !W3HasImmunity( attacker, Immunity_Skills ) )
			{
				War3_DamageModPercent( 0.0 );
			}
			else
			{
				W3MsgEnemyHasImmunity( victim, true );
			}
		}
	}
}

/* *************************************** OnUltimateCommand (Joyful Jumper) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_JUMP );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_JUMP, true ) )
			{
				if ((GetEntityFlags(client) & FL_ONGROUND))
				{
					JumpCounter[client] = 0;
				}
				if(JumpCounter[client] <= JumpLimit[ult_level])
				{ 
					new Float:velocity[3];				
					velocity[2] += JumpHeight[ult_level];				
					SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
					JumpCounter[client]++;
					if(ult_level == 4)
					{
						JumpCounter[client] = 0;
					}
				}
				else
				{
					JumpCounter[client] = 0;
					War3_CooldownMGR(client,5.0,thisRaceID,ULT_JUMP,_,_);					
				}
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}