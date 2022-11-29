#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - TF2 Engineer",
	author = "ABGar",
	description = "The TF2 Engineer race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_SENTRY, SKILL_TELEPORTER, SKILL_REPAIR, ULT_UPGRADE;

// SKILL_SENTRY
new HaloSprite, BeamSprite,g_iExplosionModel,g_iSmokeModel;
new iSentry[MAXPLAYERSCUSTOM];
new SentryExplodeDamage=50;
new SentryHealth[]={0,200,350,500,700};
new SentryDamage[]={0,8,11,14,18};
new Float:Output;
new Float:SavedEntityAngle[3];
new Float:SavedEntityPos[3];
new String:g_BeamModel;
new String:SentryModel[]="models/combine_turrets/floor_turret.mdl";
new String:PlantSound[]="npc/roller/mine/rmine_tossed1.wav";
new String:ExplodeSound[]="weapons/explode5.wav";

// SKILL_TELEPORTER
new TelSpriteI, TelSpriteO, TelHSprite;
new TotalTickCount=20;
new RequiredTickCount;
new DeciTickCounter[MAXPLAYERSCUSTOM];
new bool:bTeleOutputPlaced;
new bool:bTeleInputPlaced;
new Float:TeleOutputLocation[3];
new Float:TeleInputLocation[3];
new String:TeleportSound[]="war3source/archmage/teleport.wav";

// SKILL_REPAIR
new RepairDamage[]={0,30,25,20,15};
new Float:RepairCD=20.0;
new String:RepairSound[]="player/pl_fallpain3.wav";


// ULT_UPGRADE
new bool:bInUpgrade[MAXPLAYERSCUSTOM];
new Float:UpgradeCD[]={0.0,35.0,32.0,28.0,25.0};
new Float:UpgradeDuration[]={0.0,4.0,6.0,8.0,10.0};
new String:UpgradeOnSound[]="weapons/physcannon/physcannon_charge.wav";
new String:UpgradeOffSound[]="weapons/physcannon/physcannon_claws_close.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("TF2 Engineer","tf2engineer");
	SKILL_SENTRY = War3_AddRaceSkill(thisRaceID,"Building a Sentry!","Builds an upgradeable sentry gun (+ability)",false,4);
	SKILL_TELEPORTER = War3_AddRaceSkill(thisRaceID,"Building a Teleporter!","Places an exit teleporter on first cast, second cast places an entry teleporter (+ability1)",false,4);
	SKILL_REPAIR = War3_AddRaceSkill(thisRaceID,"Repairing!","At the cost of health you heal your turret (+ability2)",false,4);
	ULT_UPGRADE=War3_AddRaceSkill(thisRaceID,"Upgrading turret!","Turret becomes stronger for a short period (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_UPGRADE,15.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_SENTRY,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_TELEPORTER,7.0,_);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		iSentry[client]=-1;
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle,weapon_m3,weapon_knife");
	GivePlayerItem(client,"weapon_m3");
	iSentry[client]=-1;
	bTeleOutputPlaced=false;
	bTeleInputPlaced=false;
}

public OnMapStart()
{
	War3_PrecacheSound(PlantSound);
	War3_PrecacheSound(ExplodeSound);
	War3_PrecacheSound(RepairSound);
	War3_PrecacheSound(TeleportSound);
	War3_PrecacheSound(UpgradeOnSound);
	War3_PrecacheSound(UpgradeOffSound);
	
	
	PrecacheModel(SentryModel);
	g_BeamModel = PrecacheModel("materials/sprites/bluelaser1.vmt");
	g_iSmokeModel = PrecacheModel("materials/effects/fire_cloud2.vmt");
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");

	HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	TelSpriteI = PrecacheModel("sprites/strider_blackball.vmt");
	TelSpriteO = PrecacheModel("sprites/combineball_glow_black_1.vmt");
	TelHSprite = PrecacheModel("materials/sprites/lgtning.vmt");
}

public OnPluginStart()
{
	CreateTimer(1.0,TelePortEffects,_,TIMER_REPEAT);
	CreateTimer(0.1,StartTeleport,_,TIMER_REPEAT);
	HookEvent("round_end", OnRoundEnd);	
}

/* *************************************** (SKILL_SENTRY) *************************************** */
public bool:CreateSentry(client)
{
	if(ValidPlayer(client))
	{
		new SentryLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SENTRY);
		
		decl Float:normal[3];
		GetClientAbsOrigin(client,SavedEntityPos);
		GetClientAbsAngles(client,normal);
		GetClientAbsAngles(client,SavedEntityAngle);
		
		new sentry = CreateEntityByName("prop_physics_override");
		SetEntityModel(sentry, SentryModel);
		DispatchKeyValue(sentry, "StartDisabled", "false");
		DispatchSpawn(sentry);
		
		if(GetClientTeam(client) == TEAM_CT) 
			SetEntityRenderColor(sentry, 30, 100, 255, 155);
		else 
			SetEntityRenderColor(sentry, 255, 0, 0, 155);

		TeleportEntity(sentry, SavedEntityPos, normal, NULL_VECTOR);
		SetEntProp(sentry, Prop_Data, "m_usSolidFlags", 152);
		SetEntProp(sentry, Prop_Data, "m_CollisionGroup", 1);
		SetEntityMoveType(sentry, MOVETYPE_NONE);
		SetEntProp(sentry, Prop_Data, "m_MoveCollide", 0);
		SetEntProp(sentry, Prop_Data, "m_nSolidType", 6);
		SetEntPropEnt(sentry, Prop_Data, "m_hLastAttacker", client);
		
		SetEntProp(sentry, Prop_Data, "m_takedamage", 2);
		SetEntProp(sentry, Prop_Data, "m_iHealth", SentryHealth[SentryLevel]);
		HookSingleEntityOutput(sentry, "OnBreak", OnSentryDestroyed, true);
		
		AcceptEntityInput(sentry, "Enable");
		EmitSoundToAll(PlantSound,client);
		MakeBeams(sentry);
		iSentry[client]=sentry;
		CreateTimer(0.5,GetEnemyLoop,sentry);
	}
}


public Action:GetEnemyLoop(Handle:timer,any:sentry)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client) && War3_GetRace(client)==thisRaceID)
		{
			if(IsValidEdict(sentry))
			{
				new SentryLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SENTRY);
				CreateTimer(0.5,GetEnemyLoop,sentry);
				new team=GetClientTeam(client);
				new Float:minepos[3];
				new Float:enemypos[3];
				new BeamColour[4]={0,0,0,0};
				GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", minepos);
				minepos[2] += 59;
				
				if(team==TEAM_T)
					BeamColour={255,0,0,125};
				else if (team==TEAM_CT)
					BeamColour={0,0,255,125};
					
				for(new enemy=1;enemy<=MaxClients;enemy++)
				{
					if(ValidPlayer(enemy,true) && SkillFilter(enemy))
					{
						if(GetClientTeam(enemy)!=team)
						{
							GetClientAbsOrigin(enemy,enemypos);
							enemypos[2] += 40;
							if(GetVectorDistance(minepos,enemypos)<=500.0)
							{
								GetAngleBetweenVector(sentry,enemy);
								if(RadToDeg(Output)<23.0)
								{
									if(bInUpgrade[client])
									{
										if(UltFilter(enemy))
										{
											War3_DealDamage(enemy,(SentryDamage[SentryLevel]*2),client,DMG_BLAST,"sentry gun");
											TE_SetupBeamPoints(minepos, enemypos, BeamSprite, HaloSprite, 0, 0, 0.2, 20.0, 20.0, 0, 0.0, {0,155,0,125}, 40 );
											TE_SendToAll();
										}
										else
										{
											War3_DealDamage(enemy,SentryDamage[SentryLevel],client,DMG_BLAST,"sentry gun");
											TE_SetupBeamPoints( minepos, enemypos, BeamSprite, HaloSprite, 0, 0, 0.2, 10.0, 10.0, 0, 0.0, BeamColour, 40 );
											TE_SendToAll();
										}
									}
									else
									{
										War3_DealDamage(enemy,SentryDamage[SentryLevel],client,DMG_BLAST,"sentry gun");
										TE_SetupBeamPoints( minepos, enemypos, BeamSprite, HaloSprite, 0, 0, 0.2, 10.0, 10.0, 0, 0.0, BeamColour, 40 );
										TE_SendToAll();
									}
								}							
							}
						}
					}
				}
			}
		}
	}
}

public OnSentryDestroyed(const String:output[], caller, activator, Float:delay)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client) && War3_GetRace(client)==thisRaceID)
		{
			if(IsValidEdict(caller))
			{
				new Float:minepos[3];
				new Float:enemypos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", minepos);
				TE_SetupExplosion(minepos, g_iExplosionModel, 20.0, 10, TE_EXPLFLAG_NONE, 300, 255);
				TE_SendToAll();
				TE_SetupSmoke(minepos, g_iExplosionModel, 100.0, 2);
				TE_SendToAll();
				TE_SetupSmoke(minepos, g_iSmokeModel, 100.0, 2);
				TE_SendToAll();
				AcceptEntityInput(caller, "Kill");
				EmitSoundToAll(ExplodeSound,client);
				iSentry[client]=-1;
				War3_CooldownMGR(client,5.0,thisRaceID,SKILL_SENTRY,_,_);
				
				for(new enemy=1;enemy<=MaxClients;enemy++)
				{
					if(ValidPlayer(enemy,true) && War3_GetRace(enemy)!=thisRaceID)
					{
						new team=GetClientTeam(client);
						if(GetClientTeam(enemy)!=team)
						{
							if(!W3HasImmunity(enemy,Immunity_Skills))
							{
								GetClientAbsOrigin(enemy,enemypos);
								if(GetVectorDistance(minepos,enemypos)<=150)
								{
									War3_DealDamage(enemy,SentryExplodeDamage,client,DMG_BLAST,"sentry explosion");
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:TimerLoop(Handle:timer,any:entity)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client) && War3_GetRace(client)==thisRaceID)
		{
			if(IsValidEdict(entity))
			{
				MakeBeams(entity);
			}
		}
	}
}

void MakeBeams(int entity)
{
	float origin[3], angles[3], right[3] = { 0.939692, 0.342020, 0.0 }, left[3] = { 0.939692, -0.342020, 0.0 }, v1[3], v2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);

	origin[2]+=5.0;

	RotatePoint(right, right, angles);
	RotatePoint(left, left, angles);

	v1 = origin;
	v2 = origin;
	ScaleVector(right, 20.0); // start position of right beam
	AddVectors(v1, right, v1);
	ScaleVector(right, 10.0); // Length of right beam (multiply V1 x 10)
	AddVectors(v2, right, v2);
 
	CreateBeam(v1, v2);

	v1 = origin;
	v2 = origin;
	ScaleVector(left, 20.0); // start position of left beam
	AddVectors(v1, left, v1);
	ScaleVector(left, 10.0); // Length of left beam (multiply V1 x 10)
	AddVectors(v2, left, v2);

	CreateBeam(v1, v2);

	CreateTimer(0.1,TimerLoop,entity);
}



RotatePoint(float out[3], const float p[3], const float angles[3])
{
    float sin[3], cos[3], temp[3];
    
    sin[0] = Sine(angles[0] * FLOAT_PI / 180.0);
    sin[1] = Sine(angles[1] * FLOAT_PI / 180.0);
    sin[2] = Sine(angles[2] * FLOAT_PI / 180.0);
    cos[0] = Cosine(angles[0] * FLOAT_PI / 180.0);
    cos[1] = Cosine(angles[1] * FLOAT_PI / 180.0);
    cos[2] = Cosine(angles[2] * FLOAT_PI / 180.0);
    
    temp[0] = cos[1] * cos[0] * p[0] + (cos[1] * sin[0] * sin[2] - sin[1] * cos[2]) * p[1] + (sin[1] * sin[2] + cos[1] * sin[0] * cos[2]) * p[2];
    temp[1] = sin[1] * cos[0] * p[0] + (cos[1] * cos[2] + sin[1] * sin[0] * sin[2]) * p[1] + (sin[1] * sin[0] * cos[2] - cos[1] * sin[2]) * p[2];
    temp[2] = cos[0] * sin[2] * p[1] + cos[0] * cos[2] * p[2] - sin[0] * p[0];
    
    out = temp;
}

stock CreateBeam(const Float:v1[3], const Float:v2[3])
{
    new color[4] =  { 255, 0, 0, 255 };
    TE_SetupBeamPoints(v1, v2, g_BeamModel, 0, 0, 0, 0.2, 3.0, 3.0, 1, 0.0, color, 0);
    TE_SendToAll();
}  

stock Float:GetAngleBetweenVector(client, enemy)
{
	decl Float:vec[3];
	decl Float:targetPos[3];
	decl Float:fwd[3];

	vec[0] = SavedEntityPos[0];
	vec[1] = SavedEntityPos[1];
	vec[2] = SavedEntityPos[2];

	GetClientAbsOrigin(enemy, targetPos);
	GetAngleVectors(SavedEntityAngle, fwd, NULL_VECTOR, NULL_VECTOR);
	vec[0] = targetPos[0] - vec[0];
	vec[1] = targetPos[1] - vec[1];
	vec[2] = 0.0;
	fwd[2] = 0.0;
	NormalizeVector(fwd, fwd);
	ScaleVector(vec, 1/SquareRoot(vec[0]*vec[0]+vec[1]*vec[1]+vec[2]*vec[2]));
	Output = ArcCosine(vec[0]*fwd[0]+vec[1]*fwd[1]+vec[2]*fwd[2]);
	return;
} 


public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		new SentryLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SENTRY);
		new TeleportLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_TELEPORTER);
		new RepairLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_REPAIR);
		
		if(ability==0)
		{
			if(SentryLevel>0)
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SENTRY,true))
				{
					if(!Silenced(client))
					{
						if(iSentry[client]>-1)
							PrintHintText(client,"You already have a Sentry Gun Planted");
						else
							CreateSentry(client);
					}
				}
			}
			else
				PrintHintText(client,"Level your Sentry Gun first");
		}
/* *************************************** (SKILL_TELEPORTER) *************************************** */
		if(ability==1)
		{
			if(TeleportLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_TELEPORTER,true,true,true))
				{
					if(!bTeleOutputPlaced)
					{
						GetClientAbsOrigin(client,TeleOutputLocation);
						bTeleOutputPlaced=true;
						PrintHintText(client,"Teleport End Portal placed");
					}
					else
					{
						if(!bTeleInputPlaced)
						{
							GetClientAbsOrigin(client,TeleInputLocation);
							bTeleInputPlaced=true;
							PrintHintText(client,"Teleport In Portal placed.  Stand on the portal for 2 seconds to teleport");
							CreateTimer(30.0,StopTele,client);
						}
						else
						{
							PrintHintText(client,"You already have an active Teleport");
						}
					}
				}
			}
			else
				PrintHintText(client,"Level your Teleport first");
		}
/* *************************************** (SKILL_REPAIR) *************************************** */
		if(ability==2)
		{
			if(RepairLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_REPAIR,true,true,true))
				{
					if(iSentry[client]>-1)
					{
						new sentry = iSentry[client];
						if(IsValidEdict(sentry))
						{					
							if(GetEntProp(sentry,Prop_Data,"m_iHealth")<SentryHealth[SentryLevel])
							{
								War3_CooldownMGR(client,RepairCD,thisRaceID,SKILL_REPAIR,true,true);
								SetEntProp(sentry, Prop_Data, "m_iHealth", SentryHealth[SentryLevel]);
								War3_DealDamage(client,RepairDamage[RepairLevel],client,DMG_BLAST,"sentry repair");
								PrintHintText(client,"You Sentry Gun is fully healed.  It cost you %i health",RepairDamage[RepairLevel]);
								EmitSoundToAll(RepairSound,client);
							}
							else
								PrintHintText(client,"Your Sentry Gun is already fully healed");
						}
					}
					else
						PrintHintText(client,"You don't have a Sentry Gun planted");
				}
			}
			else
				PrintHintText(client,"Level your Repair first");
		}
		if(ability==3)
		{
			if(iSentry[client]>-1)
			{
				new sentry = iSentry[client];
				if(IsValidEdict(sentry))
				{
					new health = GetEntProp(sentry,Prop_Data,"m_iHealth");
					PrintToChat(client,"Sentry health = %i",health);
				}
			}
		}
	}
}

/* *************************************** (ULT_UPGRADE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new UpgradeLevel=War3_GetSkillLevel(client,thisRaceID,ULT_UPGRADE);
		if(UpgradeLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_UPGRADE,true,true,true))
			{
				if(iSentry[client]>-1)
				{
					new sentry = iSentry[client];
					if(IsValidEdict(sentry))
					{
						War3_CooldownMGR(client,UpgradeCD[UpgradeLevel]+UpgradeDuration[UpgradeLevel],thisRaceID,ULT_UPGRADE,true,true);
						bInUpgrade[client]=true;
						CreateTimer(UpgradeDuration[UpgradeLevel],StopUpgrade,client);
						CreateTimer(1.0,DoBeacon,client);
						SetEntProp(sentry, Prop_Data, "m_iHealth", 1000);
						new duration = RoundToZero(UpgradeDuration[UpgradeLevel]);
						PrintHintText(client,"Sentry Upgrade Activated for %i seconds",duration);						
						EmitSoundToAll(UpgradeOnSound,client);
					}
				}
				else
					PrintHintText(client,"You don't have a Sentry Gun planted");
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:StopUpgrade(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bInUpgrade[client])
	{
		bInUpgrade[client]=false;
		if(iSentry[client]>-1)
		{
			new sentry = iSentry[client];
			if(IsValidEdict(sentry))
			{
				new SentryLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SENTRY);
				SetEntProp(sentry, Prop_Data, "m_iHealth", SentryHealth[SentryLevel]);
				PrintHintText(client,"Sentry Upgrade de-activated");
				EmitSoundToAll(UpgradeOffSound,client);
			}
		}
	}
}

public Action:DoBeacon(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bInUpgrade[client])
	{
		if(iSentry[client]>-1)
		{
			new sentry = iSentry[client];
			if(IsValidEdict(sentry))
			{
				new Float:SentryPos[3];
				GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", SentryPos);
				SentryPos[2] += 10;
				TE_SetupBeamRingPoint(SentryPos, 10.0, 100.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 0.0, {0,155,0,125}, 10, 0);
				TE_SendToAll();
				CreateTimer(1.0,DoBeacon,client);
			}
		}
	}
}

/* *************************************** (SKILL_TELEPORTER) *************************************** */
public Action:StopTele(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		bTeleInputPlaced=false;
		bTeleOutputPlaced=false;
		PrintHintText(client,"Your Teleporter has closed in on itself");
		War3_CooldownMGR(client,10.0,thisRaceID,SKILL_TELEPORTER,true,true);
	}
}


public Action:TelePortEffects(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i, true))
        {
            if(War3_GetRace(i)==thisRaceID)
			{
				if(bTeleOutputPlaced)
				{
					TE_SetupBeamRingPoint(TeleOutputLocation,25.0,75.0,TelSpriteO,TelHSprite,0,15,2.0,10.0,3.0,{255,0,0,120},20,0);
					TE_SendToAll();
				}
				if(bTeleInputPlaced)
				{
					TE_SetupBeamRingPoint(TeleInputLocation,25.0,75.0,TelSpriteI,TelHSprite,0,15,2.0,20.0,3.0,{100,100,150,255},20,0);
					TE_SendToAll();
				}
			}
        }
    }     
}

public Action:StartTeleport(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
		if(bTeleInputPlaced && bTeleOutputPlaced)
		{
			if(War3_GetRace(i)==thisRaceID)
				RequiredTickCount=TotalTickCount/2;
			else
				RequiredTickCount=TotalTickCount;
				
			if(DeciTickCounter[i] >= RequiredTickCount)
			{
				TeleportEntity(i, TeleOutputLocation, NULL_VECTOR, NULL_VECTOR);
				EmitSoundToAll(TeleportSound,i);
			}
			
			new Float:iPos[3];
			GetClientAbsOrigin(i,iPos);
			if(GetVectorDistance(iPos,TeleInputLocation)<60.0)
			{
				DeciTickCounter[i]++;
				PrintToChat(i,"Current ticks = %i",DeciTickCounter[i]);
			}
			else
				DeciTickCounter[i]=0;
		}
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	bTeleOutputPlaced=false;
	bTeleInputPlaced=false;
}
