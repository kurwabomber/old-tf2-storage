// Arctic Blast  - Aided by the will of the North Winds, the Druid conjures up a chilling torrent of frost that incapacitates all caught within the frozen blast.
// Heart of Wolverine (ability1 aura like Keepers' heal, but for damage) - This ability grants the Druid the knowledge needed to summon into being a spirit that increases his skill in battle, as well as that of his party. 
// Carrion Vine (every enemy killed in a round will give +2,3,4,5 HP) - The sentient plant summoned by this skill draws the corpses of your enemies into the ground, where it rapidly decomposes them, giving their life energies to the Druid.
// Werewolf - This ability allows an enlightened Druid to take on the form of a wolf, imparting to him quicker reflexes and heightened combat facilities. 

#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Diablo2 Druid",
	author = "ABGar",
	description = "The Diablo2 Druid race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_ARCTIC, SKILL_HEART, SKILL_VINE, ULT_WEREWOLF;

// SKILL_ARCTIC
new Float:Output;
new Float:ArcticRange=500.0;
new Float:ArcticDuration[]={0.0,0.5,1.0,1.5,2.0};
new Float:ArcticCD[]={0.0,35.0,30.0,25.0,20.0};
new String:ArcticSound[]="war3source/d2druid/arcticblast.wav";

// SKILL_HEART
new BeamSprite, HaloSprite;
new bool:bHeartUsed[MAXPLAYERSCUSTOM]={false, ...};
new Float:druidPos[3];
new Float:HeartRange=160.0;
new Float:HeartDuration=10.0;
new Float:HeartDamage[]={0.0,0.1,0.2,0.3,0.4};
new Float:HeartCD[]={0.0,35.0,30.0,25.0,20.0};
new String:HeartSound[]="war3source/d2druid/heart.wav";

// SKILL_VINE
new VineHealth[]={0,2,3,4,5};
new String:VineSound[]="war3source/d2druid/vine.wav";

// ULT_WEREWOLF
new bool:bInWereWolf[MAXPLAYERSCUSTOM]={false, ...};
new Float:WerewolfSpeed[]={1.0,1.1,1.2,1.3,1.4};
new Float:WerewolfGravity[]={1.0,0.9,0.8,0.7,0.6};
new Float:WerewolfDamageReduce[]={1.0,0.95,0.9,0.85,0.8};
new Float:WerewolfDuration[]={0.0,3.0,5.0,8.0,10.0};
new Float:WerewolfCD[]={0.0,60.0,50.0,45.0,40.0};
new String:WerewolfSound[]="war3source/d2druid/werewolf.wav";

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Diablo2 Druid","d2druid");
	SKILL_ARCTIC = War3_AddRaceSkill(thisRaceID,"Arctic Blast","Aided by the will of the North Winds, the Druid conjures up a \nchilling torrent of frost that incapacitates all caught within the frozen blast.\n+ability",false,4);
	SKILL_HEART = War3_AddRaceSkill(thisRaceID,"Heart of Wolverine","This ability grants the Druid the knowledge needed to summon into \nbeing a power that increases his skill in battle, as well as that of his party.\n+ability1",false,4);
	SKILL_VINE = War3_AddRaceSkill(thisRaceID,"Carrion Vine","The sentient plant summoned by this skill draws the corpses of your \nenemies into the ground, where it rapidly decomposes them, giving their life energies to the Druid.\npassive",false,4);
	ULT_WEREWOLF=War3_AddRaceSkill(thisRaceID,"Werewolf","This ability allows an enlightened Druid to take on the form of a wolf, \nimparting to him quicker reflexes and heightened combat facilities. \n+ultimate",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_ARCTIC,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_HEART,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_WEREWOLF,10.0,_);
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
	bHeartUsed[client]=false;
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/war3source/d2druid/heart.wav");
	AddFileToDownloadsTable("sound/war3source/d2druid/arcticblast.wav");
	AddFileToDownloadsTable("sound/war3source/d2druid/werewolf.wav");
	AddFileToDownloadsTable("sound/war3source/d2druid/vine.wav");
	War3_PrecacheSound(ArcticSound);
	War3_PrecacheSound(HeartSound);
	War3_PrecacheSound(VineSound);
	War3_PrecacheSound(WerewolfSound);
	
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnPluginStart()
{
	CreateTimer(1.0,CalcHeart,_,TIMER_REPEAT);
}
/* *************************************** (SKILL_ARCTIC) *************************************** */
public Action:StopStun(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bBashed,thisRaceID,false);
		W3ResetPlayerColor(client, thisRaceID);
	}
}

public Float:GetAngleBetweenVector(client, target)
{
	decl Float:clientPos[3];		GetClientAbsOrigin(client, clientPos);
	decl Float:clientVec[3];		GetClientAbsAngles(client, clientVec);
	decl Float:targetPos[3];		GetClientAbsOrigin(target, targetPos);
	decl Float:fwd[3];

	GetAngleVectors(clientVec, fwd, NULL_VECTOR, NULL_VECTOR);
	clientPos[0] = targetPos[0] - clientPos[0];
	clientPos[1] = targetPos[1] - clientPos[1];
	clientPos[2] = 0.0;
	fwd[2] = 0.0;
	NormalizeVector(fwd, fwd);
	ScaleVector(clientPos, 1/SquareRoot(clientPos[0]*clientPos[0]+clientPos[1]*clientPos[1]+clientPos[2]*clientPos[2]));
	Output = ArcCosine(clientPos[0]*fwd[0]+clientPos[1]*fwd[1]+clientPos[2]*fwd[2]);
	return;
}  

public IceEffect(client)
{
    new Float:vAngles[3];			GetClientEyeAngles(client, vAngles);
    new Float:aOrigin[3];			GetClientEyePosition(client, aOrigin);		aOrigin[2]-=40.0;
    new Float:AnglesVec[3];			GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);
    new String:tName[128];

    Format(tName, sizeof(tName), "target%i", client);
    DispatchKeyValue(client, "targetname", tName);
   
    new String:ice_name[128];
    Format(ice_name, sizeof(ice_name), "Ice%i", client);
    new ice = CreateEntityByName("env_steam");
    DispatchKeyValue(ice,"targetname", ice_name);
    DispatchKeyValue(ice, "parentname", tName);
    DispatchKeyValue(ice,"SpawnFlags", "1");
    DispatchKeyValue(ice,"Type", "0");
    DispatchKeyValue(ice,"InitialState", "1");
    DispatchKeyValue(ice,"Spreadspeed", "10");
    DispatchKeyValue(ice,"Speed", "800");
    DispatchKeyValue(ice,"Startsize", "1200");
    DispatchKeyValue(ice,"EndSize", "1200");
    DispatchKeyValue(ice,"Rate", "15");
    DispatchKeyValue(ice,"JetLength", "400");
    DispatchKeyValue(ice,"RenderColor", "0 0 255");
    DispatchKeyValue(ice,"RenderAmt", "200");
    DispatchSpawn(ice);
    TeleportEntity(ice, aOrigin, vAngles, NULL_VECTOR);
    SetVariantString(tName);

    AcceptEntityInput(ice, "TurnOn");
    
    new String:ice_name2[128];
    Format(ice_name2, sizeof(ice_name2), "Ice2%i", client);
    new ice2 = CreateEntityByName("env_steam");
    DispatchKeyValue(ice2,"targetname", ice_name2);
    DispatchKeyValue(ice2, "parentname", tName);
    DispatchKeyValue(ice2,"SpawnFlags", "1");
    DispatchKeyValue(ice2,"Type", "1");
    DispatchKeyValue(ice2,"InitialState", "1");
    DispatchKeyValue(ice2,"Spreadspeed", "10");
    DispatchKeyValue(ice2,"Speed", "600");
    DispatchKeyValue(ice2,"Startsize", "50");
    DispatchKeyValue(ice2,"EndSize", "400");
    DispatchKeyValue(ice2,"Rate", "10");
    DispatchKeyValue(ice2,"JetLength", "500");
    DispatchSpawn(ice2);
    TeleportEntity(ice2, aOrigin, vAngles, NULL_VECTOR);
    SetVariantString(tName);
    
    AcceptEntityInput(ice2, "TurnOn");
    
    new Handle:icedata = CreateDataPack();
    CreateTimer(3.0, KillIce, icedata);
    WritePackCell(icedata, ice);
    WritePackCell(icedata, ice2);
}

public Action:KillIce(Handle:timer, Handle:icedata)
{
	ResetPack(icedata);
	new ent1 = ReadPackCell(icedata);
	new ent2 = ReadPackCell(icedata);
	CloseHandle(icedata);
	new String:classname[256];
	
	if (IsValidEntity(ent1))
    {
		AcceptEntityInput(ent1, "TurnOff");
		GetEdictClassname(ent1, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
        {
            RemoveEdict(ent1);
        }
    }
	
	if (IsValidEntity(ent2))
    {
		AcceptEntityInput(ent2, "TurnOff");
		GetEdictClassname(ent2, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
        {
            RemoveEdict(ent2);
        }
    }
}

public Action:StopArcticSound(Handle:timer,any:client)
{
	StopSound(client,SNDCHAN_AUTO,ArcticSound);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new ArcticLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_ARCTIC);
			if(ArcticLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_ARCTIC,true,true,true))
				{
					War3_CooldownMGR(client,ArcticCD[ArcticLevel],thisRaceID,SKILL_ARCTIC,true,true);
					W3EmitSoundToAll(ArcticSound,client);
					CreateTimer(3.0,StopArcticSound,client);
					IceEffect(client);
					new Float:clientpos[3];		GetClientAbsOrigin(client,clientpos);
					for(new enemy=1;enemy<=MaxClients;enemy++)
					{
						if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=GetClientTeam(client) && SkillFilter(client))
						{
							new Float:enemypos[3];		GetClientAbsOrigin(enemy,enemypos);
							if(GetVectorDistance(clientpos,enemypos)<=ArcticRange)
							{
								GetAngleBetweenVector(client,enemy);
								if(RadToDeg(Output)<18.0)
								{
									War3_SetBuff(enemy,bBashed,thisRaceID,true);
									W3SetPlayerColor(enemy,thisRaceID,10,10,255,_,GLOW_ULTIMATE);
									CreateTimer(ArcticDuration[ArcticLevel],StopStun,enemy);
								}							
							}
						}
					}
					
				}
			}
			else
				PrintHintText(client,"Level your Arctic Blast first");
		}
/* *************************************** (SKILL_HEART) *************************************** */
		if(ability==1)
		{
			new HeartLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_HEART);
			if(HeartLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_HEART,true,true,true))
				{
					War3_CooldownMGR(client,HeartCD[HeartLevel]+HeartDuration,thisRaceID,SKILL_HEART,true,true);
					W3EmitSoundToAll(HeartSound,client);
					bHeartUsed[client]=true;
					GetClientAbsOrigin(client,druidPos);		
					new colors1[4]={25,199,49,155};
					new colors2[4]={25,134,38,155};
					TE_SetupBeamRingPoint(druidPos,0.0,75.0,BeamSprite,HaloSprite,0,15,HeartDuration,20.0,3.0,colors2,10,0);
					TE_SendToAll(); 
					TE_SetupBeamRingPoint(druidPos,45.0,90.0,BeamSprite,HaloSprite,0,15,HeartDuration,20.0,3.0,colors1,10,0);
					TE_SendToAll(); 
					TE_SetupBeamRingPoint(druidPos,90.0,135.0,BeamSprite,HaloSprite,0,15,HeartDuration,20.0,3.0,colors2,10,0);
					TE_SendToAll(); 
					TE_SetupBeamRingPoint(druidPos,135.0,180.0,BeamSprite,HaloSprite,0,15,HeartDuration,20.0,3.0,colors1,10,0);
					TE_SendToAll(); 	
					TE_SetupBeamRingPoint(druidPos,180.0,225.0,BeamSprite,HaloSprite,0,15,HeartDuration,20.0,3.0,colors2,10,0);
					TE_SendToAll(); 
					TE_SetupBeamRingPoint(druidPos,225.0,270.0,BeamSprite,HaloSprite,0,15,HeartDuration,20.0,3.0,colors1,10,0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(druidPos,270.0,315.0,BeamSprite,HaloSprite,0,15,HeartDuration,20.0,3.0,colors2,10,0);
					TE_SendToAll(); 
					CreateTimer(HeartDuration,EndHeart,client);
				}
			}
		}
	}
}

public Action:CalcHeart(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			new HeartLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_HEART);
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true) && GetClientTeam(client)==GetClientTeam(i))
				{
					if(bHeartUsed[client])
					{
						new Float:iPos[3];		GetClientAbsOrigin(i,iPos);
						if(GetVectorDistance(druidPos,iPos) <= HeartRange)
							War3_SetBuff(i,fDamageModifier,thisRaceID,HeartDamage[HeartLevel]);
						else
							W3ResetBuffRace(i,fDamageModifier,thisRaceID);
					}
					else
						W3ResetBuffRace(i,fDamageModifier,thisRaceID);
				}
			}
		}
	}
}

public Action:EndHeart(Handle:timer,any:client)
{
	bHeartUsed[client]=false;
}

/* *************************************** (SKILL_VINE) *************************************** */
public OnWar3EventDeath(victim,attacker)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			new VineLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_VINE);
			if(VineLevel>0)
			{
				War3_HealToMaxHP(client,VineHealth[VineLevel]);
				W3EmitSoundToAll(HeartSound,client);
				W3FlashScreen(client,RGBA_COLOR_RED);
			}
		}
	}
}

/* *************************************** (ULT_WEREWOLF) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new WerewolfLevel=War3_GetSkillLevel(client,thisRaceID,ULT_WEREWOLF);
		if(WerewolfLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_WEREWOLF,true,true,true))
			{
				War3_CooldownMGR(client,WerewolfCD[WerewolfLevel],thisRaceID,ULT_WEREWOLF,true,true);
				bInWereWolf[client]=true;
				W3EmitSoundToAll(WerewolfSound,client);
				W3SetPlayerColor(client,thisRaceID,10,10,10,_,GLOW_ULTIMATE);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,WerewolfSpeed[WerewolfLevel]);
				War3_SetBuff(client,fLowGravitySkill,thisRaceID,WerewolfGravity[WerewolfLevel]);
				CreateTimer(WerewolfDuration[WerewolfLevel],EndWerewolf,client);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:EndWerewolf(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bInWereWolf[client])
	{
		bInWereWolf[client]=false;
		W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
		W3ResetBuffRace(client,fLowGravitySkill,thisRaceID);
		W3ResetPlayerColor(client,thisRaceID);
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			new WerewolfLevel = War3_GetSkillLevel(victim,thisRaceID,ULT_WEREWOLF);
			if(WerewolfLevel>0)
			{
				War3_DamageModPercent(WerewolfDamageReduce[WerewolfLevel]);
			}
		}
	}
}