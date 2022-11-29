#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#include <cstrike>

public Plugin:myinfo = 
{
	name = "War3Source Race - Spy",
	author = "M.A.C.A.B.R.A",
	description = "The Spy race for War3Source.",
	version = "1.1.2",
	url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_SONAR, SKILL_CAMOUFLAGE, SKILL_DISARM,  ULT_DOUBLEAGENT;


// Sonar
new SonarRange[] = {2500, 2000, 1500, 1000, 500, 150};
new Float:SonarDistance;
//Sonar_sounds
new String:sonar1[]="war3source/spy/sonar1.mp3";
new String:sonar2[]="war3source/spy/sonar2.mp3";
new String:sonar3[]="war3source/spy/sonar3.mp3";
new String:sonar4[]="war3source/spy/sonar4.mp3";
new String:sonar5[]="war3source/spy/sonar5.mp3";
new String:sonar6[]="war3source/spy/sonar6.mp3";


// Camouflage Buffs
new CamouflageMin = 1;
new CamouflageMax[] = { 0, 30, 20, 15, 10 };

// Disarm
new Float:DisarmRange[]={0.0,200.0,400.0,600.0,800.0};
new bool:bIsDisarmed[MAXPLAYERS];
new Handle:DisarmCooldown; 
new String:DisarmSnd[]="war3source/spy/DisarmSnd.mp3";

// DoubleAgent
new DoubleAgentTarget[MAXPLAYERS];
new bool:bSwitched[MAXPLAYERS];
new bool:bDoubleAgentDisabled[MAXPLAYERS];
new bool:DoubleAgentActivated[MAXPLAYERS];
new Float:DoubleAgentCooldown[]={0.0,90.0,70.0,50.0,30.0};
new VictimsT[MAXPLAYERS];
new String:DoubleAgentSnd[]="war3source/spy/DoubleAgentSnd.mp3";


public OnWar3PluginReady(){
	thisRaceID=War3_CreateNewRace("Spy","spy");
	
	SKILL_SONAR=War3_AddRaceSkill(thisRaceID,"Sonar","Use your senses to find victim.",false,4);
	SKILL_CAMOUFLAGE=War3_AddRaceSkill(thisRaceID,"Camouflage","You need to blend into the crowd.",false,4);
	SKILL_DISARM=War3_AddRaceSkill(thisRaceID,"Disarm (Ability)","Take away enemy's weapons.",false,4);
	ULT_DOUBLEAGENT=War3_AddRaceSkill(thisRaceID,"Double Agent (Ultimate)","Try the other side of the conflict.",true,4);
	
	War3_CreateRaceEnd(thisRaceID);
}

public OnPluginStart()
{
	DisarmCooldown=CreateConVar("war3_spy_disarm_cooldown","15","Cooldown timer.");
	CreateTimer( 2.0, CalcSonar, _, TIMER_REPEAT );
	
	HookEvent("round_end",RoundOverEvent);
}

public OnMapStart()
{
	//Sounds
	War3_PrecacheSound(DisarmSnd);
	War3_PrecacheSound(DoubleAgentSnd);
	War3_PrecacheSound(sonar1);
	War3_PrecacheSound(sonar2);
	War3_PrecacheSound(sonar3);
	War3_PrecacheSound(sonar4);
	War3_PrecacheSound(sonar5);
	War3_PrecacheSound(sonar6);
}

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		bDoubleAgentDisabled[i] = true;
		if(ValidPlayer(i) && bSwitched[i])
		{
			new PlayerTeam = GetClientTeam(i);
			if(PlayerTeam == 2)
			{
				bSwitched[i]=false;
				CS_SwitchTeam(i, 3);
			}
			if(PlayerTeam == 3)
			{
				bSwitched[i]=false;
				CS_SwitchTeam(i, 2);
			}
		}
	}
}

public OnWar3EventSpawn(client)
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		
		InitPassiveSkills(client);
		W3ResetPlayerColor(client, thisRaceID);
		bSwitched[client]=false;
		DoubleAgentActivated[client] = false;
		bDoubleAgentDisabled[client] = false;
		SonarDistance = 99999.9;
		new skill_double = War3_GetSkillLevel( client, thisRaceID, ULT_DOUBLEAGENT );
		W3SkillCooldownOnSpawn( thisRaceID, ULT_DOUBLEAGENT, DoubleAgentCooldown[skill_double], _ );
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
	new skill_camo = War3_GetSkillLevel( client, thisRaceID, SKILL_CAMOUFLAGE );

	if(War3_GetRace(client) == thisRaceID && skill_camo > 0 && GetRandomInt( CamouflageMin, CamouflageMax[skill_camo] ) <= 10 )
	{
		if( GetClientTeam( client ) == TEAM_T )
		{
			SetEntityModel( client, "models/player/ct_urban.mdl" );
		}
		if( GetClientTeam( client ) == TEAM_CT )
		{
			SetEntityModel( client, "models/player/t_leet.mdl" );
		}
		PrintHintText(client, "You blend into the crowd");
	}	
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
}

public Action:CalcSonar( Handle:timer, any:userid )
{
	if( thisRaceID > 0 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) )
			{
				if( War3_GetRace( i ) == thisRaceID )
				{
					Sonar( i );
				}
			}
		}
	}
}

public Sonar( client )
{
	new skill = War3_GetSkillLevel( client, thisRaceID, SKILL_SONAR );
	if( skill > 0 && !Hexed( client, false ) )
	{
		new AttackerTeam = GetClientTeam( client );
		new Float:AttackerPos[3];
		new Float:VictimPos[3];
		
		GetClientAbsOrigin( client, AttackerPos );
		
		AttackerPos[2] += 40.0;
		
		SonarDistance = 99999.9;
		
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam( i ) != AttackerTeam && !W3HasImmunity( i, Immunity_Skills ) )
			{
				GetClientAbsOrigin( i, VictimPos );
				VictimPos[2] += 40.0;
				
				if(GetVectorDistance( AttackerPos, VictimPos ) < SonarDistance)
				{
					SonarDistance = GetVectorDistance( AttackerPos, VictimPos );
				}
			}
		}
							
		if( SonarDistance <= SonarRange[0] && SonarDistance > SonarRange[1])
		{
			PrintHintText(client, "You sense an enemy");
			EmitSoundToClient(client,sonar1);					
		}
		if( SonarDistance <= SonarRange[1] && SonarDistance > SonarRange[2])
		{
			EmitSoundToClient(client,sonar2);					
		}
		if( SonarDistance <= SonarRange[2] && SonarDistance > SonarRange[3])
		{
			EmitSoundToClient(client,sonar3);					
		}
		if( SonarDistance <= SonarRange[3] && SonarDistance > SonarRange[4])
		{
			EmitSoundToClient(client,sonar4);					
		}
		if(skill >= 3)
		{
			if( SonarDistance <= SonarRange[4] && SonarDistance > SonarRange[5])
			{
				EmitSoundToClient(client,sonar5);					
			}
			if(skill == 4)
			{
				if( SonarDistance <= SonarRange[5])
				{
					PrintHintText(client, "Your enemy is very close to you");
					EmitSoundToClient(client,sonar6);					
				}
			}
		}		
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{		
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_DISARM);
		if(skill>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_DISARM,true))
			{
				new target=War3_GetTargetInViewCone(client,DisarmRange[skill],false);
				if(ValidPlayer(target,true)&&!W3HasImmunity(target,Immunity_Skills))
				{
					PrintHintText(client, "You disarmed your enemy");
					PrintHintText(target, "You've been disarmed");
					EmitSoundToAll(DisarmSnd,client);
					EmitSoundToAll(DisarmSnd,target); 
					War3_CooldownMGR(client,GetConVarFloat(DisarmCooldown),thisRaceID,SKILL_DISARM,false,true);
					bIsDisarmed[target] = true;				
					FakeClientCommand( target, "drop" ); // drop 1st weapon
					FakeClientCommand( target, "drop" ); // drop 2nd weapon
				}
				else
				{
					PrintHintText(client, "No Target Found");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Disarm first");
		}
	}
}

public GetRandomPlayer( client )
{
	new victims = 0;
	new spyTeam = GetClientTeam( client );
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) && GetClientTeam( i ) != spyTeam && !W3HasImmunity( i, Immunity_Ultimates ))
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && bSwitched[i] == false)
			{
				VictimsT[victims] = i;
				victims++;
			}
		}
	}
	
	if(victims == 0)
	{
		return 0;
	}
	else
	{
		new target = GetRandomInt(0,(victims-1));
		return VictimsT[target];		
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_ult = War3_GetSkillLevel(client,thisRaceID,ULT_DOUBLEAGENT);
		if(skill_ult > 0)
		{
			if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_DOUBLEAGENT,true ))
			{
				new enemy = GetRandomPlayer(client);
				DoubleAgentTarget[client] = enemy;
				if( enemy > 0 && !W3HasImmunity(enemy,Immunity_Ultimates))
				{
					new enemysTeamPlayers;
					new enemyTeam = GetClientTeam(enemy);
					for(new i = 1; i <= MaxClients; i++)
					{
						if(i != enemy && ValidPlayer(i,true) && GetClientTeam(i) == enemyTeam)
						{
							enemysTeamPlayers++;
						}
					}
					
					if(DoubleAgentActivated[client] == false && bDoubleAgentDisabled[client] == false)
					{
						if(enemysTeamPlayers > 0)
						{
							PrintHintText(client, "You switched your side");
							PrintHintText(enemy, "You switched your side");
							EmitSoundToAll(DoubleAgentSnd,client);
							EmitSoundToAll(DoubleAgentSnd,enemy); 
						
							DoubleAgentActivated[client] = true;
							bDoubleAgentDisabled[client] = true;
							bSwitched[client]=true;
							bSwitched[enemy]=true;
						
						
							if(GetClientTeam( enemy ) == 2)
							{
								CS_SwitchTeam(enemy, 3);
								CS_SwitchTeam(client, 2);
							}
							else if(GetClientTeam( enemy ) == 3)
							{							
								CS_SwitchTeam(enemy, 2);
								CS_SwitchTeam(client, 3);
							}
						
							InitPassiveSkills(client);
						}
						else
						{
							PrintHintText( client, "Target is last enemy alive, cannot be switched" );
						}
					}
					else
					{
						PrintHintText( client, "You've been called traitor and can't switch sides back" );
					}						
				}	
				else
				{
					PrintHintText( client, "No Target Found" );
				}				
			}
		}
		else
		{
			PrintHintText(client, "Level your Double Agent first");
		}
	}
}