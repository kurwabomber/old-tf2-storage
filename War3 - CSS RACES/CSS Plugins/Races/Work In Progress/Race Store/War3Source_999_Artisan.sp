/*
* War3Source Race - Artisan
* 
* File: War3Source_Artisan.sp
* Description: The Artisan race for War3Source.
* Author: M.A.C.A.B.R.A 
* 
* Special thanks to Remzo for finding bugs and help with removing them :)
*/
#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Artisan",
	author = "M.A.C.A.B.R.A",
	description = "The Artisan race for War3Source.",
	version = "1.1.4",
	url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_ACCURACY, SKILL_INVENTION, SKILL_SCULPTOR,  ULT_AMORPHOUS;

// Pinpoint Accuracy
new Float:AccuracyDmg[]={1.0, 1.1, 1.15, 1.2, 1.25};

// Invention
new Float:InventionChance[] = {0.0, 0.5, 0.6, 0.7, 0.8};
new Float:InventionCoolDown[] = {0.0, 45.0, 40.0, 35.0, 30.0};
new String:InventionWeapons[][] = {"weapon_p228", "weapon_fiveseven", "weapon_m3", "weapon_ump45", "weapon_ak47", "weapon_m4a1", "weapon_awp", "weapon_g3sg1"};
// new String:InventionSnd[]="war3source/artisan/weapon.wav";

// Sculptor
new EntitiesHP[] = {0, 200, 300, 400, 500};
new ActiveEntity[MAXPLAYERS];
new SculptorEntitiesNum[MAXPLAYERS];
new SculptorEntities[MAXPLAYERS][100];
new bool:bIsEntityAlive[MAXPLAYERS][100];
new String:SculptorModelName[MAXPLAYERS][128];
new Float:SculptorCoolDown1[] = {0.0, 25.0, 20.0, 15.0, 10.0};
new Float:SculptorCoolDown2[] = {0.0, 30.0, 25.0, 20.0, 15.0};
// new String:SculptorSnd[]="war3source/artisan/sculptor.wav";

// Amorphous
new String:AmorphousModel[MAXPLAYERS][128];
new bool:AmorphousInUse[MAXPLAYERS];
new AmorphousTimeLeft[MAXPLAYERS];
new Float:AmorphousTime[] = {0.0, 15.0, 20.0, 25.0, 30.0}; 
new Float:AmorphousCoolDown[] = {0.0, 50.0, 45.0, 40.0, 35.0, 30.0};
// new String:AmorphousSnd[]="war3source/artisan/amorphous.mp3";


/* *********************** OnWar3PluginReady *********************** */
public OnWar3PluginReady(){
	thisRaceID=War3_CreateNewRace("Artisan [TESTING - ADMIN ONLY] ","artisan");
	
	SKILL_ACCURACY=War3_AddRaceSkill(thisRaceID,"Pinpoint Accuracy","Your shots are very precise. (attack)",false,4);
	SKILL_INVENTION=War3_AddRaceSkill(thisRaceID,"Invention","Allows you to assemble weapons. (+ability2)",false,4);
	SKILL_SCULPTOR=War3_AddRaceSkill(thisRaceID,"Sculptor","You are able to reconstruct remembered object. (+ability1 to remember object; +ability to create it)",false,4);
	ULT_AMORPHOUS=War3_AddRaceSkill(thisRaceID,"Amorphous","Allows you to take shape of any object. (+ultimate)",true,4);
	
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_SCULPTOR, 20.0, _ );
	W3SkillCooldownOnSpawn( thisRaceID, ULT_AMORPHOUS, 30.0, _ );
	War3_CreateRaceEnd(thisRaceID);
}

/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{
	HookEvent("round_end",RoundOverEvent);
}

/* *********************** OnMapStart *********************** */
public OnMapStart()
{
	/*
	//Sounds
	War3_PrecacheSound(InventionSnd);
	War3_PrecacheSound(SculptorSnd);
	War3_PrecacheSound(AmorphousSnd);*/
}

/* *********************** RoundOverEvent *********************** */
public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			if(War3_GetRace(i) == thisRaceID)
			{
				SetEntityModel(i, AmorphousModel[i]);
				AmorphousInUse[i] = false;
				AmorphousTimeLeft[i] = 0;
				for(new j = 1; j <= SculptorEntitiesNum[i]; j++)
				{
					if(IsValidEdict(SculptorEntities[i][j]))
					{
						AcceptEntityInput(SculptorEntities[i][j], "Kill");
						bIsEntityAlive[i][j] = false;
					}
				}
			}
		}
	}
}

/* *********************** OnWar3EventSpawn *********************** */
public OnWar3EventSpawn(client)
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{	
		GetEntPropString(client, Prop_Data, "m_ModelName", AmorphousModel[client], 128);
		ActiveEntity[client] = -1;
		SculptorEntitiesNum[client] = 0;
		AmorphousInUse[client] = false;
		AmorphousTimeLeft[client] = 0;
		
		for(new i = 0; i < 100; i++)
		{
			SculptorEntities[client][i] = -1;
			bIsEntityAlive[client][i] = false;
		}
	}
}

/* *************************************** Pinpoint Accuracy *************************************** */
/* *********************** OnW3TakeDmgBulletPre *********************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new skill=War3_GetSkillLevel(attacker,thisRaceID,SKILL_ACCURACY);
			if(skill>0)
			{
				War3_DamageModPercent(AccuracyDmg[skill]);
				damage *= AccuracyDmg[skill];
			}	
		}
	}
}


/* *************************************** Sculptor & Invention *************************************** */
/* *********************** OnAbilityCommand *********************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	/* ********** Sculptor ********** */
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_SCULPTOR);
		if(skill>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_SCULPTOR,true))
			{
				new ent = GetClientAimTarget(client, false);
				ActiveEntity[client] = ent;
				if(ActiveEntity[client] != -1 && IsValidEdict(ActiveEntity[client]))
				{					
					new String:SculptorClassName[32];
					GetEntityClassname(ActiveEntity[client], SculptorClassName, 32);
					if(StrContains(SculptorClassName, "func") != -1) 
					{
						ActiveEntity[client] = -1;
						PrintHintText(client, "No object found");
					}
					else
					{
						PrintHintText(client, "You are trying to remember the shape of entity.");
						GetEntPropString(ActiveEntity[client], Prop_Data, "m_ModelName", SculptorModelName[client], 128);
						War3_CooldownMGR(client,SculptorCoolDown1[skill],thisRaceID,SKILL_SCULPTOR,_,_);
					}
				}
				else
				{
					PrintHintText(client, "No object found");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Sculptor first");
		}
	}
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_SCULPTOR);
		if(skill>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_SCULPTOR,true))
			{
				if(ActiveEntity[client] != -1 && IsValidEdict(ActiveEntity[client]))
				{
					new entity = CreateEntityByName("prop_physics_override");
					if(entity > 0 && IsValidEdict(entity))
					{
						decl String:entname[16];
						Format(entname, sizeof(entname), "Sculptor_Entity_%i",client);
						SetEntityModel(entity, SculptorModelName[client]);
						ActivateEntity(entity);
						DispatchKeyValue(entity, "StartDisabled", "false");
						DispatchKeyValue(entity, "targetname", entname);
						DispatchSpawn(entity);				
						DispatchKeyValue(entity, "disablereceiveshadows", "1");
						DispatchKeyValue(entity, "disableshadows", "1");																	
						SetEntProp(entity, Prop_Data, "m_nSolidType", 6);
						SetEntProp(entity, Prop_Data, "m_CollisionGroup", 2);
						SetEntProp(entity, Prop_Data, "m_usSolidFlags", 5);				
						SetEntityMoveType(entity, MOVETYPE_NONE);
						SetEntProp(entity, Prop_Data, "m_takedamage", 2);
						SetEntProp(entity, Prop_Data, "m_iHealth", EntitiesHP[skill]);
						SetEntityFlags(entity, 18);
						AcceptEntityInput(entity, "DisableMotion");
						
						new Float:EntitySpawnPos[3];
						War3_GetAimTraceMaxLen(client,EntitySpawnPos,200.0);
						TeleportEntity(entity, EntitySpawnPos, NULL_VECTOR, NULL_VECTOR);
						
						SculptorEntitiesNum[client]++;
						SculptorEntities[client][SculptorEntitiesNum[client]] = entity;
						
						bIsEntityAlive[client][SculptorEntitiesNum[client]] = true;
						PrintHintText(client, "You have reconstructed an object.");
						// EmitSoundToAll(SculptorSnd,client);
						War3_CooldownMGR(client,SculptorCoolDown2[skill],thisRaceID,SKILL_SCULPTOR,_,_);
						CreateTimer(2.0, FinalSpawn,entity);
						CreateTimer( 0.1, EntityCheck, client,TIMER_REPEAT);
					}
				}
				else
				{
					PrintHintText(client, "No object shape remembered.");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Sculptor first");
		}
	}
	/* ********** Invention ********** */
	if(War3_GetRace(client)==thisRaceID && ability==2 && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_INVENTION);
		if(skill>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_INVENTION,true))
			{
				if(GetRandomFloat(0.0,1.0) <= InventionChance[skill])
				{
					new weapon = GetRandomInt(0,((skill*2)-1));
					GivePlayerItem( client, InventionWeapons[weapon]);
					PrintHintText(client, "You have assembled a weapon.");
					// EmitSoundToAll(InventionSnd,client);
					War3_CooldownMGR(client,InventionCoolDown[skill],thisRaceID,SKILL_INVENTION,_,_);
				}
				else
				{
					PrintHintText(client, "You failed the assembling of this weapon.");
					War3_CooldownMGR(client,InventionCoolDown[skill],thisRaceID,SKILL_INVENTION,_,_);
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Invention first");
		}
	}
}

/* *********************** FinalSpawn *********************** */
public Action:FinalSpawn( Handle:timer, any:entity )
{
	if(IsValidEdict(entity))
	{
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 6);
	}	
}

/* *********************** EntityCheck *********************** */
public Action:EntityCheck( Handle:timer, any:client )
{
	new bool:bIsAnyEntityAlive = false;
	for(new i = 1; i <= SculptorEntitiesNum[client]; i++)
	{
		if(!IsValidEdict(SculptorEntities[client][i]))
		{
			bIsEntityAlive[client][i] = false;
		}
		
		if(IsClientInGame(client) && !IsPlayerAlive(client))
		{
			if(IsValidEdict(SculptorEntities[client][i]))
			{
				AcceptEntityInput(SculptorEntities[client][i], "Kill");
				bIsEntityAlive[client][i] = false;
			}
		}		
		if(bIsEntityAlive[client][i] == true)
		{
			bIsAnyEntityAlive = true;
		}
	}
	if(bIsAnyEntityAlive == false)
	{
		KillTimer(timer);
	}
}

/* *************************************** Amorphous *************************************** */
/* *********************** OnUltimateCommand *********************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_ult = War3_GetSkillLevel(client,thisRaceID,ULT_AMORPHOUS);
		if(skill_ult > 0)
		{
			if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_AMORPHOUS,true ))
			{
				if(AmorphousInUse[client] == false)
				{
					new entity = GetClientAimTarget(client, false);
					if(IsValidEdict(entity) && entity != -1 )
					{
						new String:AmorphousClassName[32];
						GetEntityClassname(entity, AmorphousClassName, 32);
						if(StrContains(AmorphousClassName, "func") != -1) // ¿eby nie zamieniaæ siê kurwa w drzwi/kratki/szyby, bo to nie s¹ propsy i wydupcaj¹ serwer !!!
						{
							entity = -1;
							PrintHintText(client, "No object found");
						}
						else
						{
							new String:modelname[128];
							GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
							AmorphousInUse[client] = true;
							SetEntityModel(client, modelname);
							AmorphousTimeLeft[client] = RoundToZero(AmorphousTime[skill_ult]);
							
							// EmitSoundToAll(AmorphousSnd,client);
							PrintHintText(client, "You have took shape of seen object");
							W3Hint(client,HINT_LOWEST,1.0,"Amorphous Form Time Left: %d",AmorphousTimeLeft[client]);
							
							SetThirdPersonView(client, true);
							CreateTimer(1.0,AmorphousTimer,client,TIMER_REPEAT);
							CreateTimer(1.0,ViewChange,client);
							CreateTimer(AmorphousTime[skill_ult],ModelChange,client);
						}
					}
					else
					{
						PrintHintText(client, "No object found");
					}
				}
				else
				{
					PrintHintText(client, "Amorphous have already changed your shape.");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Amorphous first");
		}
	}
}

/* *********************** ModelChange *********************** */
public Action:ModelChange( Handle:timer, any:client )
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(AmorphousInUse[client] == true)
		{
			PrintHintText(client, "You changed back your shape.");
			// EmitSoundToAll(AmorphousSnd,client);
			AmorphousInUse[client] = false;
			SetEntityModel(client, AmorphousModel[client]);
			SetThirdPersonView(client, true);
			War3_CooldownMGR(client,AmorphousCoolDown[War3_GetSkillLevel(client,thisRaceID,ULT_AMORPHOUS)],thisRaceID,ULT_AMORPHOUS,_,_);
			CreateTimer(1.0,ViewChange,client);	
		}
	}
}

/* *********************** AmorphousTimer *********************** */
public Action:AmorphousTimer( Handle:timer, any:client )
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(AmorphousInUse[client] == true)
		{
			AmorphousTimeLeft[client]--;
			W3Hint(client,HINT_LOWEST,1.0,"Amorphous Form Time Left: %d",AmorphousTimeLeft[client]);
		}
		else
		{
			KillTimer(timer);
		}
	}
	else
	{
		KillTimer(timer);
	}
}

/* *********************** ViewChange *********************** */
public Action:ViewChange( Handle:timer, any:client )
{
	SetThirdPersonView(client, false);
}

/* *********************** SetThirdPersonView *********************** */
public SetThirdPersonView(any:client, bool:third)
{
    if(third)
    {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
        SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
        SetEntProp(client, Prop_Send, "m_iFOV", 120);
    }
    else
    {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
        SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
        SetEntProp(client, Prop_Send, "m_iFOV", 90);
    }
}