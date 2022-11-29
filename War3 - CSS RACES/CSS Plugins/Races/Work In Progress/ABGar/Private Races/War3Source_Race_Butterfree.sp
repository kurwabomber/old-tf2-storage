#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Butterfree",
	author = "ABGar",
	description = "The Butterfree race for War3Source.",
	version = "1.0",
	// Squirtle's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5251-butterfree/?hl=squirtle
}

new thisRaceID;

new SKILL_STRING, SKILL_SONIC, SKILL_POWDER, ULT_SOAR;

// SKILL_STRING
new BeamSprite,HaloSprite;
new bool:bStrung[MAXPLAYERSCUSTOM];
new Float:StringSlow[]={1.0,0.9,0.8,0.7,0.6};

// SKILL_SONIC

// SKILL_POWDER
new bool:bGassed[MAXPLAYERSCUSTOM];
new Float:GasLoc[MAXPLAYERSCUSTOM][3];
new GasDmg[]={0,1,2,3,4};

// ULT_SOAR

new Float:FlyDuration[]={0.0,4.0,6.0,8.0,10.0};
new bool:bIsFlying[MAXPLAYERSCUSTOM];
new Handle:FlyEndTimer[MAXPLAYERSCUSTOM];



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Butterfree [PRIVATE]","butterfree");
	SKILL_STRING = War3_AddRaceSkill(thisRaceID,"String Shot","Binds the foe with string, to reduce their speed (+ability)",false,4);
	SKILL_SONIC = War3_AddRaceSkill(thisRaceID,"Supersonic","Emits bizarre sound waves that may confuse the foe (+ability1)",false,4);
	SKILL_POWDER = War3_AddRaceSkill(thisRaceID,"Poison Powder","Scatters a toxic powder that will poison your enemies (+ability2)",false,4);
	ULT_SOAR=War3_AddRaceSkill(thisRaceID,"Soar","The user will fly for a limited time (+ultimate)",false,4);
	War3_CreateRaceEnd(thisRaceID);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		if (ValidPlayer(client,true))
        {
			InitPassiveSkills(client);
		}
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{

}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnPluginStart()
{
	HookEvent("smokegrenade_detonate", smokegrenade_detonate);
}

/* *************************************** (SKILL_STRING) *************************************** */
public Action:StartString(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bStrung[client])
	{
		new Float:StringPos[3];
		GetClientAbsOrigin(client,StringPos);
		StringPos[2]+=15.0;
		TE_SetupBeamRingPoint(StringPos,45.0,44.0,BeamSprite,HaloSprite,0,15,0.1,5.0,50.0,{255,255,255,255},0,0);
		TE_SendToAll();
		StringPos[2]+=15.0;
		TE_SetupBeamRingPoint(StringPos,45.0,44.0,BeamSprite,HaloSprite,0,15,0.1,5.0,50.0,{255,255,255,255},0,0);
		TE_SendToAll();
		StringPos[2]+=15.0;
		TE_SetupBeamRingPoint(StringPos,45.0,44.0,BeamSprite,HaloSprite,0,15,0.1,5.0,50.0,{255,255,255,255},0,0);
		TE_SendToAll();
		CreateTimer(0.1,StartString,client);
	}
}

public Action:EndString(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bStrung[client])
	{
		bStrung[client]=false;
		War3_SetBuff(client,fSlow,thisRaceID,1.0);
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new StringLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_STRING);
		if(StringLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_STRING,true,true,true))
			{
				new target = War3_GetTargetInViewCone(client,500.0,false,23.0);
				if(target>0)
				{
					if(SkillFilter(target))
					{
						new Float:ClientPos[3], Float:TargetPos[3];
						GetClientAbsOrigin(client,ClientPos);
						GetClientAbsOrigin(target,TargetPos);
						ClientPos[2]+=30.0;
						TargetPos[2]+=30.0;
						War3_SetBuff(target,fSlow,thisRaceID,StringSlow[StringLevel]);
						bStrung[target]=true;
						TE_SetupBeamPoints(ClientPos,TargetPos,BeamSprite,HaloSprite,0,15,0.5,5.0,5.0,0,50.0,{255,255,255,255},20);
						//TE_SetupBeamPoints(ClientPos,TargetPos,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{255,000,255,50},20);
						TE_SendToAll();
						CreateTimer(0.1,StartString,target);
						CreateTimer(4.0,EndString,target);
						War3_CooldownMGR(client,20.0,thisRaceID,SKILL_STRING,true,true);
					}
				}
				else
					W3MsgNoTargetFound(client);
			}
		}
		else
			PrintHintText(client,"Level your String Shot first");
	}
/* *************************************** (SKILL_SONIC) *************************************** */
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && ValidPlayer(client,true))
	{
		new SonicLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SONIC);
		if(SonicLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_SONIC,true,true,true))
			{
				new target = War3_GetTargetInViewCone(client,600.0,false,23.0);
				if(target>0)
				{
					if(SkillFilter(target))
					{
						new Float:angs[3];
						GetClientEyeAngles(target, angs);
						angs[1] += 180;
						angs[0] -= 90;
						TeleportEntity(target, NULL_VECTOR, angs, NULL_VECTOR);
					}
				}
				else
					W3MsgNoTargetFound(client);
			}
		}
		else
			PrintHintText(client,"Level your SuperSonic first");
	}
/* *************************************** (SKILL_POWDER) *************************************** */
	if(War3_GetRace(client)==thisRaceID && ability==2 && pressed && ValidPlayer(client,true))
	{
		new PowderLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_STRING);
		if(PowderLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_POWDER,true,true,true))
			{
				new iOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
				if (GetEntData(client, iOffset + 48) > 0)
				{
					FakeClientCommand(client,"use weapon_smokegrenade");
					bGassed[client]=true;
				}
				else
				{
					GivePlayerItem(client,"weapon_smokegrenade");
					FakeClientCommand(client,"use weapon_smokegrenade");
					bGassed[client]=true;
				}
				War3_CooldownMGR(client,40.0,thisRaceID,SKILL_POWDER,_,_);
			}
		}
		else
			PrintHintText(client,"Level your Poison Powder first");
	}	
}

public smokegrenade_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(War3_GetRace(client) == thisRaceID)
	{
		new skill = War3_GetSkillLevel(client, thisRaceID, SKILL_POWDER);
		if(skill > 0)
		{
			if(bGassed[client])
			{
				new Float:a[3], Float:b[3];
				a[0] = GetEventFloat(event, "x");
				a[1] = GetEventFloat(event, "y");
				a[2] = GetEventFloat(event, "z");
				GasLoc[client][0]=a[0];
				GasLoc[client][1]=a[1];
				GasLoc[client][2]=a[2];
				
				new checkok = 0;
				new ent = -1;
				while((ent = FindEntityByClassname(ent, "env_particlesmokegrenade")) != -1)
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", b);
					if(a[0] == b[0] && a[1] == b[1] && a[2] == b[2])
					{		
						checkok = 1;
						break;
					}
				}
				
				if (checkok == 1)
				{
					new iEntity = CreateEntityByName("light_dynamic");
					if (iEntity != -1)
					{
						
						new iRef = EntIndexToEntRef(iEntity);
						decl String:sBuffer[64];
						DispatchKeyValue(iEntity, "_light", "0 255 0");
						Format(sBuffer, sizeof(sBuffer), "smokelight_%d", iEntity);
						DispatchKeyValue(iEntity,"targetname", sBuffer);
						Format(sBuffer, sizeof(sBuffer), "%f %f %f", a[0], a[1], a[2]);
						DispatchKeyValue(iEntity, "origin", sBuffer);
						DispatchKeyValue(iEntity, "iEntity", "-90 0 0");
						DispatchKeyValue(iEntity, "pitch","-90");
						DispatchKeyValue(iEntity, "distance","256");
						DispatchKeyValue(iEntity, "spotlight_radius","96");
						DispatchKeyValue(iEntity, "brightness","3");
						DispatchKeyValue(iEntity, "style","6");
						DispatchKeyValue(iEntity, "spawnflags","1");
						DispatchSpawn(iEntity);
						AcceptEntityInput(iEntity, "DisableShadow");
						AcceptEntityInput(iEntity, "TurnOn");
						
						CreateTimer(1.0,GasDamage,client);
						CreateTimer(19.0,GasOff,client);
						CreateTimer(20.0, DeleteLight, iRef, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
}

public Action:DeleteLight(Handle:timer, any:iRef)
{
	new entity= EntRefToEntIndex(iRef);
	if (entity != INVALID_ENT_REFERENCE)
	{
		if (IsValidEdict(entity)) AcceptEntityInput(entity, "kill");
	}
}

public Action:GasDamage(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		if(bGassed[client])
		{
			new PowderLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_POWDER);
			for (new enemy=1;enemy<=MaxClients;enemy++)
			{
				if(ValidPlayer(enemy,true)&& GetClientTeam(enemy)!=GetClientTeam(client))
				{
					new Float:EnemyPos[3];
					GetClientAbsOrigin(enemy,EnemyPos);
					if(GetVectorDistance(EnemyPos,GasLoc[client])<=175.0)
					{
						War3_DealDamage(enemy,GasDmg[PowderLevel],client,DMG_BULLET,"posion powder");
					}
				}
			}
			CreateTimer(1.0,GasDamage,client);
		}
	}
}

public Action:GasOff(Handle:timer,any:client)
{
	bGassed[client]=false;
}


/* *************************************** (ULT_SOAR) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new SoarLevel=War3_GetSkillLevel(client,thisRaceID,ULT_SOAR);
		if(SoarLevel>0)
		{
			if(bIsFlying[client])
			{
                TriggerTimer(FlyEndTimer[client]); 
            }
			else
			{
				if(SkillAvailable(client,thisRaceID,ULT_SOAR,true,true,true))
				{
					bIsFlying[client]=true;
					War3_SetBuff(client,bFlyMode,thisRaceID,true);
					War3_SetBuff(client,fMaxSpeed,thisRaceID,1.6);
					FlyEndTimer[client]=CreateTimer(FlyDuration[SoarLevel],StopFly,client);
					CreateTimer(FlyDuration[SoarLevel]-3.0,Land3,client);
					CreateTimer(FlyDuration[SoarLevel]-2.0,Land2,client);
					CreateTimer(FlyDuration[SoarLevel]-1.0,Land1,client);
					new seconds=RoundToZero(FlyDuration[SoarLevel]);
					PrintHintText(client,"Soar for %i seconds",seconds);
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:StopFly(Handle:timer,any:client)
{
	if (bIsFlying[client])
	{
		PrintToChat(client, "\x03You've landed...");
		War3_CooldownMGR(client,20.0,thisRaceID,ULT_SOAR,_,_);
		bIsFlying[client]=false;
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
}

public Action:Land3(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bIsFlying[client])
		PrintToChat(client, "\x03You're going to land in \x043 \x03seconds!");
}

public Action:Land2(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bIsFlying[client])
		PrintToChat(client, "\x03You're going to land in \x042 \x03seconds!");
}

public Action:Land1(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bIsFlying[client])
		PrintToChat(client, "\x03You're going to land in \x041 \x03second!");
}