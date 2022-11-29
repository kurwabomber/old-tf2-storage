#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/RemyFunctions"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Avatar the Airbender",
	author = "ABGar",
	description = "The Avatar the Airbender race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_SPEED, SKILL_POWER, SKILL_SWITCH, ULT_RANDOM;

// SKILL_SPEED
new Float:ScooterSpeed[]={1.0,1.1,1.2,1.2,1.3};

// SKILL_POWER
new BeamSprite, HaloSprite, BurnSprite;
new Float:PowerCoolDown=25.0;

new RazorTicks=4;
new RazorDamage[]={0,5,10,15,20};
new RazorCount[MAXPLAYERSCUSTOM]={0, ...};
new RazorOwner[MAXPLAYERSCUSTOM]={-1, ...};
new Float:RazorDistance=300.0;

new WaterDamage[]={0,10,20,30,40};
new Float:WaterTime[]={0.0,2.0,3.0,4.0,5.0};
new Float:WaterDistance[]={0.0,50.0,200.0,350.0,500.0};

new Float:EarthTime[]={0.0,4.0,6.0,8.0,10.0};

new FireDamage[]={0,30,30,50,60};
new Float:FireTime[]={0.0,0.5,1.0,1.5,2.0};

new String:WindSound[]="ambient/wind/wind_snippet4.wav";
new String:WaterSound[]="ambient/water/water_splash1.wav";
new String:EarthSound[]="npc/vort/foot_hit.wav";
new String:FireSound[]="war3source/brewmaster/breath.wav";

// SKILL_SWITCH
new ClientElement[MAXPLAYERSCUSTOM]={0, ...};
new Float:SwitchCoolDown[]={0.0,25.0,20.0,15.0,10.0};

// ULT_RANDOM
new Float:UltCoolDown[]={0.0,40.0,35.0,30.0,25.0};


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("The Last Airbender [PRIVATE]","airbender");
	SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Air scooter","After mastering the thirty-sii tiers of airbending Aang invented a new airbending technique, the 'air scooter'",false,4);
	SKILL_POWER=War3_AddRaceSkill(thisRaceID,"Master of the elements","The avatar shows of his mastery of the elements using this attack (+ability)",false,4);
	SKILL_SWITCH=War3_AddRaceSkill(thisRaceID,"Elemental master","Choose which element you shall master (+ability1)",false,4);
	ULT_RANDOM=War3_AddRaceSkill(thisRaceID,"Avatar spirit","Aang is able to recall spells used by his ancestors through the avarat spirit (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_POWER,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_RANDOM,15.0,_);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");

	War3_PrecacheSound(WindSound);
	War3_PrecacheSound(WaterSound);
	War3_PrecacheSound(EarthSound);
	War3_PrecacheSound(FireSound);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			RazorCount[i]=0;
			W3ResetAllBuffRace(i,thisRaceID);
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		CS_UpdateClientModel(client);
		HUD_Add(client, "");
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
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	ClientElement[client]=GetRandomInt(1,4);
	Buffs(client,ClientElement[client]);
}

/* *************************************** (Buffs) *************************************** */
Buffs(client,ElementNumber)
{
	W3ResetAllBuffRace(client,thisRaceID);
	new SpeedLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,ScooterSpeed[SpeedLevel]);
	switch(ElementNumber)
	{
		case 1: // air
		{
			HUD_Add(GetClientUserId(client), "\nElement : Air");
			PrintToChat(client,"Air Element");
		}
		case 2: // water
		{
			War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, 25);
			HUD_Add(GetClientUserId(client), "\nElement : Water");
			PrintToChat(client,"Water Element");
		}
		case 3: // earth
		{
			new Float:speedtemp = ScooterSpeed[SpeedLevel] - 0.3;
			War3_SetBuff(client,fMaxSpeed,thisRaceID,speedtemp);
			SetEntProp(client,Prop_Send,"m_ArmorValue",100,1);
			HUD_Add(GetClientUserId(client), "\nElement : Earth");
			PrintToChat(client,"Earth Element");
		}
		case 4: // fire
		{
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,-20);
			HUD_Add(GetClientUserId(client), "\nElement : Fire");
			PrintToChat(client,"Fire Element");
		}
	}
}

/* *************************************** (Abilities) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==1)
		{
			new SwitchLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SWITCH);
			if(SwitchLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_SWITCH,true,true,true))
				{
					War3_CooldownMGR(client,SwitchCoolDown[SwitchLevel],thisRaceID,SKILL_SWITCH,_,_);
					new RandElement;
					while ((RandElement = GetRandomInt(1,4)) == ClientElement[client]){}
					ClientElement[client]=RandElement;
					Buffs(client,ClientElement[client]);
				}
			}
		}
		
		if(ability==0)
		{
			new PowerLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_POWER);
			if(PowerLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_POWER,true,true,true))
				{
					War3_CooldownMGR(client,PowerCoolDown,thisRaceID,SKILL_POWER,_,_);
					switch(ClientElement[client])
					{
						case 1:
						{
							RazorWind(client,PowerLevel,Immunity_Skills);
						}
						case 2:
						{
							TidalWave(client,PowerLevel,Immunity_Skills);
						}
						case 3:
						{
							EarthWall(client,PowerLevel);
						}
						case 4:
						{
							FireBall(client,PowerLevel,Immunity_Skills);
						}
					}
				}
			}
			else
				PrintHintText(client,"Master your Elements first");
		}
	}
}

/* *************************************** (RazorWind) *************************************** */
RazorWind(client,SkillLevel,War3Immunity:CheckImmune=Immunity_Skills)
{
	new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);		clientPos[2]+=30.0;
	TE_SetupBeamRingPoint(clientPos,20.0,RazorDistance+50,BeamSprite,HaloSprite,0,5,0.5,10.0,1.0,{42,232,232,255},60,0);
	TE_SendToAll();
	EmitSoundToAll(WindSound,client);
	CPrintToChat(client,"{red} Razor Wind!"); 
	for (new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client) && !W3HasImmunity(i,CheckImmune))
		{
			if(GetPlayerDistance(client,i)<RazorDistance)
			{
				RazorOwner[i]=client;
				RazorCount[i]=RazorTicks;
				War3_DealDamage(i,RazorDamage[SkillLevel],client,DMG_CRUSH,"razor wind",_,W3DMGTYPE_MAGIC);
				CreateTimer(1.0,RazorDamageTimer,i);
			}
		}
	}
}

public Action:RazorDamageTimer(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && RazorCount[client]>0)
	{
		new Aang = RazorOwner[client];
		new PowerLevel=War3_GetSkillLevel(Aang,thisRaceID,SKILL_POWER);
		War3_DealDamage(client,RazorDamage[PowerLevel],Aang,DMG_CRUSH,"razor wind",_,W3DMGTYPE_MAGIC);
		RazorCount[client]--;
		CreateTimer(1.0,RazorDamageTimer,client);
	}
}

/* *************************************** (TidalWave) *************************************** */
TidalWave(client,SkillLevel,War3Immunity:CheckImmune=Immunity_Skills)
{
	EmitSoundToAll(WaterSound,client);
	CPrintToChat(client,"{red} Tidal Wave!");
	new curIter=0;
	new targetList[64];
	new Float:distance=WaterDistance[SkillLevel];
	new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
	
	for(new i=0;i<=MAXPLAYERS;i++)
	{
		if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client) && !W3HasImmunity(i,CheckImmune))
		{
			new Float:iPos[3];		GetClientAbsOrigin(i,iPos);
			if(GetVectorDistance(clientPos,iPos)<=distance )
			{
				if (ClientViews(client,i,distance,0.6))
				{
					targetList[curIter]=i;
					++curIter;
				}
			}
		}
	}
	
	clientPos[2]+=40.0;
	for(new j=0;j<MAXPLAYERS;j++)
	{
		if(targetList[j]==0)
			break;
			
		if(ValidPlayer(targetList[j],true))
		{
			new Float:jPos[3];		GetClientAbsOrigin(targetList[j],jPos);		jPos[2]+=40.0;
			
			War3_DealDamage(targetList[j],WaterDamage[SkillLevel],client,DMG_BULLET,"razor wind",_,W3DMGTYPE_MAGIC);
			War3_SetBuff(targetList[j],fSlow,thisRaceID,0.7);		
			W3SetPlayerColor(targetList[j],thisRaceID,0,0,255,_,GLOW_SKILL);
			W3FlashScreen(targetList[j],RGBA_COLOR_BLUE,0.3,0.4,FFADE_OUT);
			War3_ChatMessage(targetList[j],"You have been hosed");
			EmitSoundToAll(WaterSound,targetList[j]);	
			CreateTimer(WaterTime[SkillLevel],StopSlow,targetList[j]);
			TE_SetupBeamPoints(clientPos,jPos,BeamSprite,BeamSprite,0,5,0.5,10.0,12.0,2,2.0,{10,10,240,255},70);  
			TE_SendToAll();
		}
	}
}

stock bool:ClientViews(Viewer, Target, Float:fMaxDistance=0.0, Float:fThreshold=0.73)
{
	decl Float:fViewPos[3];   	GetClientEyePosition(Viewer, fViewPos);
	decl Float:fViewAng[3];   	GetClientEyeAngles(Viewer, fViewAng);
	decl Float:fTargetPos[3]; 	GetClientEyePosition(Target, fTargetPos);
	decl Float:fViewDir[3];
	decl Float:fTargetDir[3];
	decl Float:fDistance[3];

	fViewAng[0] = fViewAng[2] = 0.0;
	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);

	fDistance[0] = fTargetPos[0]-fViewPos[0];
	fDistance[1] = fTargetPos[1]-fViewPos[1];
	fDistance[2] = 0.0;
	if (fMaxDistance != 0.0)
	{
		if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
			return false;
	}

	NormalizeVector(fDistance, fTargetDir);
	if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;

	new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
	if (TR_DidHit(hTrace)) { CloseHandle(hTrace); return false; }
	CloseHandle(hTrace);

	return true;
}

public bool:ClientViewsFilter(Entity, Mask, any:Junk)
{
    if (Entity >= 1 && Entity <= MaxClients) return false;
    return true;
}  

public Action:StopSlow(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
        War3_SetBuff(client,fSlow,thisRaceID,1.0);
        W3ResetPlayerColor(client,thisRaceID);
    }
}

/* *************************************** (EarthWall) *************************************** */
EarthWall(client,SkillLevel)
{
	EmitSoundToAll(EarthSound,client);
	CreateTimer(EarthTime[SkillLevel],StopEarth,client);
	War3_SetBuff(client,bNoMoveMode,thisRaceID, true);
	War3_SetBuff(client,fDodgeChance,thisRaceID,1.0);
	War3_SetBuff(client,bDodgeMode,thisRaceID,0);
	W3SetPlayerColor(client,thisRaceID,255,0,0,_,GLOW_SKILL);
	CPrintToChat(client,"{red} Earth Wall");
}

public Action:StopEarth(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
        War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
        War3_SetBuff(client,fDodgeChance,thisRaceID,0.0);
        W3ResetPlayerColor(client,thisRaceID);
    }
}

/* *************************************** (FireBall) *************************************** */
FireBall(client,SkillLevel,War3Immunity:CheckImmune=Immunity_Skills)
{
	EmitSoundToAll(FireSound,client);
	new target = War3_GetTargetInViewCone(client,9000.0,false,20.0);
	CPrintToChat(client,"{red} FireBall");
	if(target>0 && !W3HasImmunity(target,CheckImmune))
	{
		new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
		new Float:targetPos[3];		GetClientAbsOrigin(target,targetPos);
		
		TE_SetupBeamPoints(clientPos,targetPos,BurnSprite,BurnSprite,0,5,1.0,4.0,5.0,2,2.0,{255,128,35,255},70);  
		TE_SendToAll();

		targetPos[2]+=70;
		TE_SetupGlowSprite(targetPos,BurnSprite,1.0,1.9,255);
		TE_SendToAll();

		EmitSoundToAll(FireSound,target);
		War3_DealDamage(target,FireDamage[SkillLevel],client,DMG_BULLET,"fireball");
		IgniteEntity(target,FireTime[SkillLevel]);
	}
	else
	{
		new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
		new Float:targetPos[3];		War3_GetAimEndPoint(client,targetPos);

		TE_SetupBeamPoints(clientPos,targetPos,BurnSprite,BurnSprite,0,5,1.0,4.0,5.0,2,2.0,{255,128,35,255},70);  
		TE_SendToAll();

		targetPos[2]+=70;
		TE_SetupGlowSprite(targetPos,BurnSprite,1.0,1.9,255);
		TE_SendToAll();
	}
}

/* *************************************** (Ultimate) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new UltLevel=War3_GetSkillLevel(client,thisRaceID,ULT_RANDOM);
		if(UltLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_RANDOM,true,true,true))
			{
				War3_CooldownMGR(client,UltCoolDown[UltLevel],thisRaceID,ULT_RANDOM,true,true);
				new RandElement=GetRandomInt(1,4);
				switch(RandElement)
				{
					case 1:
					{
						RazorWind(client,UltLevel,Immunity_Ultimates);
					}
					case 2:
					{
						TidalWave(client,UltLevel,Immunity_Ultimates);
					}
					case 3:
					{
						EarthWall(client,UltLevel);
					}
					case 4:
					{
						FireBall(client,UltLevel,Immunity_Ultimates);
					}
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

