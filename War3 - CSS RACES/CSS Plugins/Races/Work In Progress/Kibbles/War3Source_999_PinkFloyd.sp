#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Pink Floyd",
	author = "ABGar & Kibbles",
	description = "The Pink Floyd race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_RUN, SKILL_CIGAR, SKILL_WISH, ULT_ECLIPSE;//skillID variables should follow the SKILL_X/ULT_X naming convention

// SKILL_RUN
new Float:RunDuration[]={0.0,2.0,4.0,6.0,8.0};
new Float:RunCD[]={0.0,40.0,35.0,30.0,25.0};
new String:RunSound[]="ambient/explosions/explode_7.wav";
new bool:Running[MAXPLAYERS];

// SKILL_CIGAR
new Float:CigarGrav[]={1.0,0.9,0.8,0.7,0.6};//make sure the zeroth value for buffs is a neutral one
new Float:CigarSpeed[]={1.0,1.05,1.1,1.15,1.2};
new Float:CigarDur[]={0.0,1.0,2.0,3.0,4.0};
new Float:CigarCD[]={0.0,30.0,25.0,20.0,15.0};
new bool:CigarActive[MAXPLAYERS];

// SKILL_WISH
new Float:WishCD[]={0.0,50.0,40.0,30.0,20.0};
new String:summon_sound[]="war3source/archmage/summon.wav";
new g_offsCollisionGroup, iOriginOffset;
new bool:SmokeActive[MAXPLAYERS];

// ULT_ECLIPSE
new Float:EclipseRange[]={0.0,100.0,150.0,200.0,250.0};
new Float:EclipseCycleDuration = 2.0;//Try to keep things as variables so they're easy to modify



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Pink Floyd [PRIVATE]","pinkfloyd");//lowercase shortnames!
	SKILL_RUN = War3_AddRaceSkill(thisRaceID,"Run Like Hell","You better run all day and run all night \nand keep your dirty feelings deep inside (+ability)",false,4);
	SKILL_CIGAR = War3_AddRaceSkill(thisRaceID,"Have A Cigar","Come in here dear boy, have a cigar, you're gonna go far. \nYou're gonna fly high, you're never gonna die (passive on damage)",false,4);
	SKILL_WISH = War3_AddRaceSkill(thisRaceID,"Wish You Were Here","How I wish, how I wish you were here.  \nWe're just two lost souls, swimming in a fish bowl, year after year (abiltiy1)",false,4);
	ULT_ECLIPSE=War3_AddRaceSkill(thisRaceID,"Eclipse","And all that is now, and all that is gone, and all that's to come, \nand everything under the sun is in tune, but the sun is eclipsed by the moon (passive ultimate)",true,4);//Don't forget to mark ultimates as ultimates :)
	War3_CreateRaceEnd(thisRaceID);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		if (ValidPlayer(client,true))
        {
			SmokeActive[client]=true;
		}
	}
}

public OnWar3EventSpawn(client)
{
    if (War3_GetRace(client) == thisRaceID)
    {
        Running[client]=false;
        SmokeActive[client]=true;
        CigarActive[client]=false;
        W3ResetAllBuffRace(client,thisRaceID);
    }
    else
    {
        SmokeActive[client]=false;
    }
}

public OnPluginStart()
{
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	iOriginOffset = FindSendPropOffs("CBaseEntity", "m_vecOrigin");
	CreateTimer(EclipseCycleDuration,Aura,_,TIMER_REPEAT);
}

public OnMapStart()
{	
	War3_PrecacheSound(RunSound);
}


/* *************************************** (SKILL_RUN) *************************************** */
public Action:SpeedStop( Handle:timer, any:client )
{
	if(ValidPlayer(client) && Running[client])//for buff removals don't rely on an is-alive check. Those will bug out if the ability activates the round before. I've added in a flag to counter that.
	{
        Running[client] = false;
		//War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
        W3ResetBuffRace(client, fMaxSpeed, thisRaceID);//both functions have the same effect, but ResetBuff is something to consider using for future races.
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client, true))//Use ValidPlayer, it's more condensed than IS_PLAYER and IsPlayerAlive, etc
	{
		new RunLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_RUN);
		if(RunLevel>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_RUN,true))
			{
				PrintToChat(client, "\x03 : Run like hell for \x04%f seconds.", RunDuration[RunLevel]);
                Running[client] = true;
				War3_SetBuff(client,fMaxSpeed,thisRaceID,1.5);
				CreateTimer(RunDuration[RunLevel],SpeedStop,client);
				War3_CooldownMGR(client,(RunDuration[RunLevel]+RunCD[RunLevel]),thisRaceID,SKILL_RUN, _, _);
				EmitSoundToAll(RunSound,client);
			}
		}
		else
		{
			PrintHintText(client,"Level your ability first");
		}
	}
/* *************************************** (SKILL_WISH) *************************************** */
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && ValidPlayer(client, true))
	{
		new WishLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_WISH);
		if(WishLevel>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_WISH,true))
			{
				new Float:MyPosition[3];
				War3_CachedPosition(client,MyPosition);
				//MyPosition[2]+=5.0;//why is the position being raised? That could trap people in the roof
				new targets[MAXPLAYERS];
				new foundtargets;
                new tmpTargetTeam = 0;
				for(new summon=1;summon<=MaxClients;summon++)
				{
					if(ValidPlayer(summon))
					{
                        tmpTargetTeam = GetClientTeam(summon);
						if(War3_GetRace(summon)!=thisRaceID && !IsPlayerAlive(summon) && (tmpTargetTeam == TEAM_T || tmpTargetTeam == TEAM_CT))//need to make sure they're not spectating or teamless
						{
							targets[foundtargets]=summon;
							foundtargets++;
						}
					}
				}
				new target;
				if(foundtargets>0)
				{
					target=targets[GetRandomInt(0, foundtargets-1)];
					if(target>0)
					{
						War3_CooldownMGR(client,WishCD[WishLevel],thisRaceID,SKILL_WISH,_,_);
						{
							new ally_team=GetClientTeam(target);
							new client_team=GetClientTeam(client);
							if(ally_team==client_team)
							{
								new Float:ang[3];
								new Float:pos[3];
								War3_SpawnPlayer(target);
								GetClientEyeAngles(client,ang);
								GetClientAbsOrigin(client,pos);
								TeleportEntity(target,pos,ang,NULL_VECTOR);
								//SetEntData(target, g_offsCollisionGroup, 2, 4, true);//on our server, don't bother with collision groups. That's handled by a separate plugin
								//SetEntData(client, g_offsCollisionGroup, 2, 4, true);
								//CreateTimer(3.0,normal,target);
								//CreateTimer(3.0,normal,client);
								EmitSoundToAll(summon_sound,client);
								CreateTimer(3.0, Stop, client);
								SmokeActive[target]=true;
								CreateTimer(5.0,RemoveSmoke,target);
							}
							else if(ally_team!=client_team)
							{
								War3_SpawnPlayer(target);
								new iEnemyTeam = (client_team == TEAM_T) ? TEAM_CT : TEAM_T;
                                new livingEnemy = W3GetRandomPlayer(iEnemyTeam,true,_);//Adding in a check for living enemies. If so, it will teleport to them to avoid spawn camping
                                if(ValidPlayer(livingEnemy,true))
                                {
                                    new Float:livingEnemyPos[3];
                                    GetClientAbsOrigin(livingEnemy, livingEnemyPos);
                                    TeleportEntity(target, livingEnemyPos, NULL_VECTOR, NULL_VECTOR);
                                }
                                else
                                {
                                    new Float:fEmptySpawnPoints[100][3];
                                    new iAvailableLocations=0;
                                    new Float:fPlayerPosition[3];
                                    new Float:fSpawnPosition[3];
                                    new ent = INVALID_ENT_REFERENCE;
                                    while((ent = FindEntityByClassname(ent, (iEnemyTeam == TEAM_T) ? "info_player_terrorist" : "info_player_counterterrorist")) != INVALID_ENT_REFERENCE)
                                    {
                                        if(!IsValidEdict(ent)) 
                                        {
                                            continue;
                                        }
                                        GetEntDataVector(ent, iOriginOffset, fSpawnPosition);
                                        new bool:bIsConflicting = false;
                                        for(new i=1; i <= MaxClients; i++)
                                        {
                                            if(ValidPlayer(i, true))
                                            {
                                                GetClientAbsOrigin(i, fPlayerPosition);
                                                if(GetVectorDistance(fSpawnPosition, fPlayerPosition) < 60.0)
                                                {
                                                    bIsConflicting = true;
                                                    break;
                                                }
                                            }
                                        }
                                        if(!bIsConflicting)
                                        {
                                            fEmptySpawnPoints[iAvailableLocations][0] = fSpawnPosition[0];
                                            fEmptySpawnPoints[iAvailableLocations][1] = fSpawnPosition[1];
                                            fEmptySpawnPoints[iAvailableLocations][2] = fSpawnPosition[2];
                                            iAvailableLocations++;
                                        }
                                    }
                                    TeleportEntity(target, fEmptySpawnPoints[GetRandomInt(0, iAvailableLocations - 1)], NULL_VECTOR, NULL_VECTOR);
                                }
								//CreateTimer(3.0,normal,target);
								//CreateTimer(3.0,normal,client);
								EmitSoundToAll(summon_sound,client);
								CreateTimer(3.0, Stop, client);
								SmokeActive[target]=true;
								CreateTimer(5.0,RemoveSmoke,target);
							}
						}
					}
				}
				else
					PrintHintText(client,"There is no one that you can respawn");
			}
		}
		else
			PrintHintText(client, "Level your Summon first");
	}
}		

public Action:Stop(Handle:timer,any:client)
{
	StopSound(client,SNDCHAN_AUTO,summon_sound);
}

public Action:normal(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new Float:end_dist=50.0;
		new Float:end_pos[3];
		GetClientAbsOrigin(client,end_pos);
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&i!=client)
			{
				new Float:pos[3];
				GetClientAbsOrigin(i,pos);
				new Float:dist=GetVectorDistance(end_pos,pos);
				if(dist<=end_dist)
				{
					CreateTimer(1.0,normal,client);
					break;
				}
				else
				{
					SetEntData(client, g_offsCollisionGroup, 5, 4, true);
				}
			}
		}
	}
}

public Action:RemoveSmoke(Handle:timer,any:client)
{
	SmokeActive[client]=false;
}



public Action:StopSmoke(Handle:timer, any:SmokeEnt)//StopSmoke and StopSmokeAttack do the same thing, so keep it to one function. If you want to organize things better, put timers, procedural functions and event-control functions in different sections instead of organizing the code in to ability blocks
{
	if(IsValidEdict(SmokeEnt))
	{
		AcceptEntityInput(SmokeEnt, "Kill");
	}
}

/* *************************************** (SKILL_CIGAR) *************************************** */

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(ValidPlayer(attacker)&&ValidPlayer(victim)&&attacker!=victim&&GetClientTeam(attacker)!=GetClientTeam(victim)&&SmokeActive[victim])//team check, because the W3S damage functions are called even when allies attack allies
	{
        if(War3_GetRace(victim)==thisRaceID)
        {
            new CigarLevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_CIGAR);
            if(CigarLevel>0&&!CigarActive[victim])
            {
                CigarActive[victim]=true;
                War3_SetBuff(victim,fMaxSpeed2,thisRaceID,CigarSpeed[CigarLevel]);//When pairing speed buffs, use the second for easy addition. Otherwise one ability will override the other
                War3_SetBuff(victim,fLowGravitySkill,thisRaceID,CigarGrav[CigarLevel]);
                CreateTimer(CigarDur[CigarLevel],StopCigar,victim);
                CreateTimer((CigarCD[CigarLevel]+CigarDur[CigarLevel]),AddCigar,victim);
                War3_CooldownMGR(victim,(CigarCD[CigarLevel]+CigarDur[CigarLevel]),thisRaceID,SKILL_CIGAR,_,_);
                PrintHintText(victim,"Have a Cigar...");
                
                new SmokeEnt = CreateEntityByName("env_smokestack");
                new SmokeEntAttack = CreateEntityByName("env_smokestack");
                if(IsValidEdict(SmokeEnt) && IsClientInGame(victim))
                {
                    SetupSmoke(victim, SmokeEnt);
                    
                    CreateTimer(2.0,StopSmoke,SmokeEnt);
                    SmokeActive[victim]=false;
                }
                if(IsValidEdict(SmokeEntAttack) && IsClientInGame(attacker))
                {
                    SetupSmoke(attacker, SmokeEntAttack);
                    
                    CreateTimer(2.0,StopSmoke,SmokeEntAttack);
                    SmokeActive[attacker]=false;
                }
                
            }
        }
        else
        {
            new SmokeEnt = CreateEntityByName("env_smokestack");
            if(IsValidEdict(SmokeEnt) && IsClientInGame(victim))
            {
                SetupSmoke(victim, SmokeEnt);
                
                CreateTimer(2.0,StopSmoke,SmokeEnt);
                SmokeActive[victim]=false;
            }
        }
    }
}
static SetupSmoke(any:owner, any:ent)//functions are always nice when you're repeating blocks of code :)
{
    new Float:SmokeLoc[3];
    GetClientAbsOrigin(owner, SmokeLoc);
    
    new String:originData[64];
    Format(originData, sizeof(originData), "%f %f %f", SmokeLoc[0], SmokeLoc[1], SmokeLoc[2]);
    
    new String:SName[128];
    Format(SName, sizeof(SName), "Smoke%i", owner);
    DispatchKeyValue(ent,"targetname", SName);
    DispatchKeyValue(ent,"Origin", originData);
    DispatchKeyValue(ent,"BaseSpread", "50");
    DispatchKeyValue(ent,"SpreadSpeed", "70");
    DispatchKeyValue(ent,"Speed", "100");
    DispatchKeyValue(ent,"StartSize", "200");
    DispatchKeyValue(ent,"EndSize", "200");
    DispatchKeyValue(ent,"Rate", "30");
    DispatchKeyValue(ent,"JetLength", "200");
    DispatchKeyValue(ent,"Twist", "20"); 
    DispatchKeyValue(ent,"RenderColor", "200 200 200");
    DispatchKeyValue(ent,"RenderAmt", "255");
    DispatchKeyValue(ent,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
    
    DispatchSpawn(ent);
    AcceptEntityInput(ent, "TurnOn");
}

public Action:StopCigar(Handle:timer, any:client)
{
	if(CigarActive[client])//Same as before, track that it's active with a flag.
	{
		//W3ResetAllBuffRace(client,thisRaceID);//this would cancel any other ability buffs too
        CigarActive[client]=false;
        W3ResetBuffRace(client,fMaxSpeed2,thisRaceID);
        W3ResetBuffRace(client,fLowGravitySkill,thisRaceID);
	}
}

public Action:AddCigar(Handle:timer, any:client)
{
	if(ValidPlayer(client)&&War3_GetRace(client)==thisRaceID)//Need to check race as this timer can carry across rounds
	{
		SmokeActive[client]=true;
	}
}


public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	new CigarLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_CIGAR);
	if(CigarLevel>0)
	{
		if(!SmokeActive[client] && War3_SkillNotInCooldown(client,thisRaceID,SKILL_CIGAR,true))
		{
			SmokeActive[client]=true;
		}
	}
}

/* *************************************** (ULT_ECLIPSE) *************************************** */
public Action:Aura(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			if(War3_GetRace(client)==thisRaceID)
			{
				new EclipseLevel=War3_GetSkillLevel(client,thisRaceID,ULT_ECLIPSE);
				new ownerteam=GetClientTeam(client);
				new Float:enemyPos[3];
				new Float:clientPos[3];
	
				GetClientAbsOrigin(client,clientPos);
				if(EclipseLevel>0)
				{
					for (new enemy=1;enemy<=MaxClients;enemy++)
					{
						if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=ownerteam && !W3HasImmunity(enemy,Immunity_Ultimates))
						{
							GetClientAbsOrigin(enemy,enemyPos);
							if(GetVectorDistance(clientPos,enemyPos)<=EclipseRange[EclipseLevel])
							{
                                W3FlashScreen(enemy,{0,0,0,255},EclipseCycleDuration,_);			
							}
						}
					}
				}
			}
		}
	}
}