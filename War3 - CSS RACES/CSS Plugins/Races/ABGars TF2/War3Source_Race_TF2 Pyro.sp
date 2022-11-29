#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - TF2 Pyro",
	author = "ABGar",
	description = "The TF2 Pyro race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_FLAME, SKILL_FLARE, SKILL_AXE, ULT_PYRO;

// SKILL_FLAME
new Float:FlameCD=20.0;
new Float:FlameDuration[]={0.0,1.0,2.0,3.0,4.0};
new DeciTimerDamage[]={0,1,2,3,4};
new bool:bFlameInUse[MAXPLAYERSCUSTOM];
new bool:bOnFire[MAXPLAYERSCUSTOM];

// SKILL_FLARE
new BeamSprite, HaloSprite;
new Float:FlareCD[]={0.0,35.0,30.0,25.0,20.0};
new Float:PushForce[]={0.0,700.0,900.0,1200.0,1500.0};
new FlareDamage[]={0,20,23,26,29,32};

// SKILL_AXE
new Float:AxeDamage[]={1.0,1.2,1.3,1.4,1.5};
new Float:AxeSpeed[]={1.0,1.05,1.1,1.15,1.2};

// ULT_PYRO
new Float:PyroDistance=600.0;
new Float:PyroDuration[]={0.0,4.0,6.0,8.0,10.0};



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("TF2 Pyro","tf2pyro");
	SKILL_FLAME = War3_AddRaceSkill(thisRaceID,"Flame Thrower","Start your flamethrower, and deal damage to enemies in range (+ability)",false,4);
	SKILL_FLARE = War3_AddRaceSkill(thisRaceID,"Flare gun","Shoots a flare, dealing damage and setting the target aflame, with knockback (+ability1)",false,4);
	SKILL_AXE = War3_AddRaceSkill(thisRaceID,"Fire axe","You run faster with an axe and deal more damage to targets on fire (passive)",false,4);
	ULT_PYRO=War3_AddRaceSkill(thisRaceID,"Pyro Vison","Enemy’s in a radius have their view filled with fire (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_AXE,fMaxSpeed,AxeSpeed);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_PYRO,15.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_FLAME,15.0,_);
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

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
	
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	bFlameInUse[client]=false;
	if(GetClientTeam(client)==3)
	{
		SetEntityModel(client, "models/player/ct_urban.mdl");
	}
	if(GetClientTeam(client)==2)
	{
		SetEntityModel(client, "models/player/t_leet.mdl");
	}
}

public OnMapStart()
{
	PrecacheSound("weapons/rpg/rocketfire1.wav", true);
	PrecacheSound("weapons/ar2/ar2_empty.wav", true);
	
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

/* *************************************** (SKILL_FLAME) *************************************** */
public CreateFlame(client)
{
	new FlameLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_FLAME);
	
	new Float:vAngles[3];
	new Float:vOrigin[3];
	new Float:aOrigin[3];
	new Float:EndPoint[3];
	new Float:AnglesVec[3];
	new Float:pos[3];
	new Float:TargetPos[3];
	new String:tName[128];
	
	new Float:distance = 600.0;
	
	GetClientEyePosition(client, vOrigin);
	GetClientAbsOrigin(client, aOrigin);
	GetClientEyeAngles(client, vAngles);
	
	// A little routine developed by Sollie and Crimson to find the endpoint of a traceray
	// Very useful!
	GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);
	
	EndPoint[0] = vOrigin[0] + (AnglesVec[0]*distance);
	EndPoint[1] = vOrigin[1] + (AnglesVec[1]*distance);
	EndPoint[2] = vOrigin[2] + (AnglesVec[2]*distance);
							
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilterPlayer, client)	;
	
	// Ident the player
	Format(tName, sizeof(tName), "target%i", client);
	DispatchKeyValue(client, "targetname", tName);
	
	W3EmitSoundToAll("weapons/rpg/rocketfire1.wav",client);
	
	// Create the Flame
	new String:flame_name[128];
	Format(flame_name, sizeof(flame_name), "Flame%i", client);
	new flame = CreateEntityByName("env_steam");
	DispatchKeyValue(flame,"targetname", flame_name);
	DispatchKeyValue(flame, "parentname", tName);
	DispatchKeyValue(flame,"SpawnFlags", "1");
	DispatchKeyValue(flame,"Type", "0");
	DispatchKeyValue(flame,"InitialState", "1");
	DispatchKeyValue(flame,"Spreadspeed", "10");
	DispatchKeyValue(flame,"Speed", "800");
	DispatchKeyValue(flame,"Startsize", "10");
	DispatchKeyValue(flame,"EndSize", "250");
	DispatchKeyValue(flame,"Rate", "15");
	DispatchKeyValue(flame,"JetLength", "400");
	DispatchKeyValue(flame,"RenderColor", "180 71 8");
	DispatchKeyValue(flame,"RenderAmt", "180");
	DispatchSpawn(flame);
	TeleportEntity(flame, aOrigin, AnglesVec, NULL_VECTOR);
	SetVariantString(tName);
	AcceptEntityInput(flame, "SetParent", flame, flame, 0);
	SetVariantString("forward");
	
	AcceptEntityInput(flame, "SetParentAttachment", flame, flame, 0);
	AcceptEntityInput(flame, "TurnOn");
	
	// Create the Heat Plasma
	new String:flame_name2[128];
	Format(flame_name2, sizeof(flame_name2), "Flame2%i", client);
	new flame2 = CreateEntityByName("env_steam");
	DispatchKeyValue(flame2,"targetname", flame_name2);
	DispatchKeyValue(flame2, "parentname", tName);
	DispatchKeyValue(flame2,"SpawnFlags", "1");
	DispatchKeyValue(flame2,"Type", "1");
	DispatchKeyValue(flame2,"InitialState", "1");
	DispatchKeyValue(flame2,"Spreadspeed", "10");
	DispatchKeyValue(flame2,"Speed", "600");
	DispatchKeyValue(flame2,"Startsize", "50");
	DispatchKeyValue(flame2,"EndSize", "400");
	DispatchKeyValue(flame2,"Rate", "10");
	DispatchKeyValue(flame2,"JetLength", "500");
	DispatchSpawn(flame2);
	TeleportEntity(flame2, aOrigin, AnglesVec, NULL_VECTOR);
	SetVariantString(tName);
	AcceptEntityInput(flame2, "SetParent", flame2, flame2, 0);
	SetVariantString("forward");
	
	AcceptEntityInput(flame2, "SetParentAttachment", flame2, flame2, 0);
	AcceptEntityInput(flame2, "TurnOn");
	
	new Handle:flamedata = CreateDataPack();
	
	CreateTimer(FlameDuration[FlameLevel], KillFlame, flamedata);
	CreateTimer(FlameDuration[FlameLevel], StopFlame, client);
			
	WritePackCell(flamedata, flame);
	WritePackCell(flamedata, flame2);
			
	if(TR_DidHit(trace))
	{							
		TR_GetEndPosition(pos, trace);
	}
	CloseHandle(trace);
	
	CreateTimer(0.1,FireLoop,client);
	bFlameInUse[client]=true;
	
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client))
		{
			GetClientAbsOrigin(i, TargetPos);
			if(GetVectorDistance(TargetPos,pos)<100)
			{
				War3_DealDamage(i,DeciTimerDamage[FlameLevel],client,DMG_CRUSH,"flamethrower",_,W3DMGTYPE_MAGIC);
				IgniteEntity(i,2.0,false);
				bOnFire[i]=true;
				CreateTimer(2.0,StopIgnite,i);
			}
		}
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)
{
	return data != entity;
} 

public Action:StopFlame(Handle:timer, Handle:client)
{
	if(bFlameInUse[client])
		bFlameInUse[client]=false;
}

public Action:StopIgnite(Handle:timer, Handle:client)
{
	bOnFire[client]=false;
}

public Action:KillFlame(Handle:timer, Handle:flamedata)
{
	ResetPack(flamedata);
	new ent1 = ReadPackCell(flamedata);
	new ent2 = ReadPackCell(flamedata);
	CloseHandle(flamedata);
	
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


public Action:FireLoop(Handle:timer,any:client)
{
	if(bFlameInUse[client])
	{
		CreateTimer(0.1,FireLoop,client);

		new FlameLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_FLAME);
		new Float:pos[3];
		new Float:TargetPos[3];
		new Float:EndPoint[3];
		new Float:vOrigin[3];
		new Float:vAngles[3];
		new Float:AnglesVec[3];
		new Float:distance = 600.0;
		
		GetClientEyePosition(client, vOrigin);
		GetClientEyeAngles(client, vAngles);
		
		GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);

		EndPoint[0] = vOrigin[0] + (AnglesVec[0]*distance);
		EndPoint[1] = vOrigin[1] + (AnglesVec[1]*distance);
		EndPoint[2] = vOrigin[2] + (AnglesVec[2]*distance);
		
		new Handle:trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilterPlayer, client)	;
		
		if(TR_DidHit(trace))
		{							
			TR_GetEndPosition(pos, trace);
		}
		CloseHandle(trace);
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client))
			{
				GetClientAbsOrigin(i, TargetPos);
				if(GetVectorDistance(TargetPos,pos)<100)
				{
					War3_DealDamage(i,DeciTimerDamage[FlameLevel],client,DMG_CRUSH,"flamethrower",_,W3DMGTYPE_MAGIC);
					if(!bOnFire[i])
					{
						IgniteEntity(i,2.0,false);
						bOnFire[i]=true;
						CreateTimer(2.0,StopIgnite,i);
					}
				}
			}
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true))
	{
		if(ability==0)
		{
			new ult_teleport=War3_GetSkillLevel(client,thisRaceID,SKILL_FLAME);
			if(ult_teleport>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_FLAME,true,true,true))
				{
					CreateFlame(client);
					War3_CooldownMGR(client,FlameCD,thisRaceID,SKILL_FLAME,true,true);
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
/* *************************************** (SKILL_FLARE) *************************************** */
		if(ability==1)
		{
			new FlareLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_FLARE);
			if(FlareLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_FLARE,true,true,true))
				{
					new target = War3_GetTargetInViewCone(client,500.0,false,23.0);
					if(target>0)
					{
						War3_CooldownMGR(client,FlareCD[FlareLevel],thisRaceID,SKILL_FLARE,_,_);
						War3_DealDamage(target,FlareDamage[FlareLevel],client,DMG_CRUSH,"flare gun",_,W3DMGTYPE_MAGIC);
						IgniteEntity(target,2.0,false);
						new Float:startpos[3];
						new Float:endpos[3];
						new Float:vector[3];
					   
						GetClientAbsOrigin(client,startpos);
						GetClientAbsOrigin(target,endpos);
						
						endpos[2]+=20.0;
						startpos[2]+=20.0;
						TE_SetupBeamPoints(startpos,endpos,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{180,71,7,180},20);
						TE_SendToAll();
						endpos[2]-=20.0;
						startpos[2]-=20.0;
						
						MakeVectorFromPoints(startpos,endpos,vector);
						NormalizeVector(vector,vector);
						ScaleVector(vector,PushForce[FlareLevel]);
						TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vector);
					}
					else
						W3MsgNoTargetFound(client);
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
	}
}
/* *************************************** (SKILL_AXE) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new AxeLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_AXE);
			if(AxeLevel>0)
			{
				new String:weapon[32]; 
				GetClientWeapon(attacker,weapon,32);
				if(StrEqual(weapon,"weapon_knife"))
				{
					if(bOnFire[victim])
						War3_DamageModPercent(AxeDamage[AxeLevel]+0.5);	
					else
						War3_DamageModPercent(AxeDamage[AxeLevel]);	
				}
			}
		}
	}
}


/* *************************************** (ULT_PYRO) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new PyroLevel=War3_GetSkillLevel(client,thisRaceID,ULT_PYRO);
		if(PyroLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_PYRO,true,true,true))
			{
				War3_CooldownMGR(client,20.0,thisRaceID,ULT_PYRO,true,true);
				new Float:clientPos[3];
				new Float:iPos[3];
				GetClientAbsOrigin(client,clientPos);
				new Float:duration=PyroDuration[PyroLevel];
				
				for(new i=1;i<=MAXPLAYERS;i++)
                {
					if(ValidPlayer(i,true) && GetClientTeam(client) != GetClientTeam(i))
					{
						GetClientAbsOrigin(i,iPos);
						if(GetVectorDistance(clientPos,iPos) <= PyroDistance)
						{
							if(ClientViews(client,i,PyroDistance,0.6))
							{
								War3_DealDamage(i,30,client,DMG_CRUSH,"pyro vision",_,W3DMGTYPE_MAGIC);
								PyroFlame(i,duration);
								bOnFire[i]=true;
								CreateTimer(PyroDuration[PyroLevel],StopIgnite,i);
							}
						}
					}
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public PyroFlame(client,Float:duration)
{
	if(ValidPlayer(client,true))
    {
		new Float:pos[3];
		GetClientAbsOrigin(client,pos);
		new fire = CreateEntityByName("env_fire");
		SetEntPropEnt(fire, Prop_Send, "m_hOwnerEntity", client);
		DispatchKeyValue(fire, "firesize", "150");
		DispatchKeyValue(fire, "health", "5");
		DispatchKeyValue(fire, "firetype", "Normal");
		DispatchKeyValue(fire, "damagescale", "0.0");
		DispatchKeyValue(fire, "spawnflags", "256");
		SetVariantString("WaterSurfaceExplosion");
		AcceptEntityInput(fire, "DispatchEffect"); 
		DispatchSpawn(fire);
		TeleportEntity(fire, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(fire, "StartFire");
		SetVariantString("!activator");
		AcceptEntityInput(fire, "SetParent", client);
		DispatchKeyValue(fire, "extinguish", "5.0");  // SET THE DURATION HERE
	}
}





stock bool:ClientViews(Viewer, Target, Float:fMaxDistance=0.0, Float:fThreshold=0.73)
{
    decl Float:fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    decl Float:fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    decl Float:fViewDir[3];
    decl Float:fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
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