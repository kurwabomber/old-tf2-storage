// Not all Sticky nades stick to walls - only the first one - not sure how to fix

#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - TF2 DemoMan",
	author = "ABGar",
	description = "The TF2 DemoMan race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_STICKY, SKILL_SUIT, SKILL_CABER, ULT_DETONATE;

// SKILL_STICKY
ArrayList GrenArray;
new iActiveGrenades;
new TotalGrenades[]={0,4,5,6,7,8};
new Float:GrenadeDamage=80.0;
new Float:GrenadeSpeed = 2000.0;
new bool:StickyNade[MAXPLAYERSCUSTOM];

// SKILL_SUIT
new Float:ExplosiveDamagedReduc[]={1.0,0.8,0.65,0.5,0.35,0.2};

// SKILL_CABER
new g_iExplosionModel;
new CaberDamage[]={0,5,9,13,17,20};
new Float:CaberDamageRadius=75.0;
new String:CaberSound[]={"weapons/ar2/ar2_altfire.wav"};

// ULT_DETONATE



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("TF2 DemoMan","tf2demoman");
	SKILL_STICKY = War3_AddRaceSkill(thisRaceID,"Stickybomb launcher","Place up to 4/5/6/7/8 Stickybombs (+ability)",false,5);
	SKILL_SUIT = War3_AddRaceSkill(thisRaceID,"Bomb suit","Take less DMG from explosives (passive)",false,5);
	SKILL_CABER = War3_AddRaceSkill(thisRaceID,"Ullapool Caber"," A sober man would throw the grenade - Knifes deals explosive DMG (passive)",false,5);
	ULT_DETONATE=War3_AddRaceSkill(thisRaceID,"Detonate","Your Stickybombs get stronger. Manually detonate your Stickybombs (+ultimate)",true,1);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_STICKY,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_DETONATE,10.0,_);
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
	GrenArray.Clear();
	iActiveGrenades=0;
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_hegrenade");
	GivePlayerItem(client,"weapon_hegrenade");
}

public OnClientPutInServer(client) 
{ 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
} 

public OnMapStart()
{
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
	War3_PrecacheSound(CaberSound);
}

public OnPluginStart()
{
	GrenArray = new ArrayList();
}


/* *************************************** (SKILL_SUIT) *************************************** */
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype) 
{ 
	if(War3_GetRace(client)==thisRaceID)
	{
		if (damagetype & DMG_BLAST) 
		{
			new SuitLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_SUIT);
			if(SuitLevel > 0)
			{
				damage *= ExplosiveDamagedReduc[SuitLevel];
				return Plugin_Changed; 
			}
		}
	}
	return Plugin_Continue; 
}


/* *************************************** (SKILL_CABER) *************************************** */
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new CaberLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CABER);
			if(CaberLevel>0)
			{
				new String:weapon[32]; 
				GetClientWeapon(attacker,weapon,32);
				if(StrEqual(weapon,"weapon_knife"))
				{
					new Float:Origin[3];
					GetClientAbsOrigin(victim,Origin);
					TE_SetupExplosion(Origin, g_iExplosionModel, 50.0, 10, TE_EXPLFLAG_NONE, 100, 125);
					TE_SendToAll();
					EmitSoundToAll(CaberSound,attacker);
					for (new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true))
						{
							if(GetClientTeam(i)!= GetClientTeam(attacker) || i==attacker)
							{
								new Float:VictimPos[3];
								GetClientAbsOrigin(i,VictimPos);
								VictimPos[2]+=25.0;
								if(GetVectorDistance(Origin,VictimPos)<CaberDamageRadius)
								{
									if(SkillFilter(i))
									{
										War3_DealDamage(i,CaberDamage[CaberLevel],attacker,DMG_BLAST,"ullapool caber",_,W3DMGTYPE_MAGIC);
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

/* *************************************** (SKILL_STICKY) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new StickyLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_STICKY);
		if(StickyLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_STICKY,true,true,true))
			{
				if(iActiveGrenades<TotalGrenades[StickyLevel])
				{
					War3_CooldownMGR(client,5.0,thisRaceID,SKILL_STICKY,true,true);
					StickyNade[client]=true;
					LaunchGrenade(client);
					iActiveGrenades++;
					StickyNade[client]=false;
				}
				else
					PrintHintText(client,"You have already used all of your %i sticky bombs",TotalGrenades[StickyLevel]);
			}
		}
		else
			PrintHintText(client,"Level your Sticky Bomb Launcher first");
	}
	if(War3_GetRace(client)==thisRaceID && ability==3 && pressed && ValidPlayer(client,true))
	{
		PrintHintText(client,"You have %i sticky bombs planted",iActiveGrenades);
	}
}

public LaunchGrenade(client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		new Float:clienteyeangle[3];			GetClientEyeAngles(client, clienteyeangle);
		new Float:clienteyeposition[3];			GetClientEyePosition(client, clienteyeposition);
		new Float:anglevector[3];
		new Float:resultposition[3];
		new Float:playerspeed[3];

		GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(anglevector, anglevector);
		AddVectors(clienteyeposition, anglevector, resultposition);
		NormalizeVector(anglevector, anglevector);
		ScaleVector(anglevector, GrenadeSpeed);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
		AddVectors(anglevector, playerspeed, anglevector);
		
		new grenadeEnt = CreateEntityByName("hegrenade_projectile");
		if (IsValidEntity(grenadeEnt))
		{
			SetEntPropEnt(grenadeEnt, Prop_Send, "m_hThrower", client);
			SetEntProp(grenadeEnt, Prop_Send, "m_iTeamNum", GetClientTeam(client));
			SetEntPropFloat(grenadeEnt, Prop_Send, "m_flDamage", GrenadeDamage);
			SetEntPropFloat(grenadeEnt, Prop_Send, "m_DmgRadius", 350.0);
			SetEntPropFloat(grenadeEnt, Prop_Send, "m_flElasticity", 0.0);
			SetEntProp(grenadeEnt, Prop_Send, "m_CollisionGroup", 2);
			DispatchSpawn(grenadeEnt);
			SetEntProp(grenadeEnt, Prop_Data, "m_nNextThinkTick", -1);
			HookEvent("grenade_bounce", Event_GrenadeBounce);
			SetEntProp(grenadeEnt, Prop_Data, "m_takedamage", 2);
			SetEntProp(grenadeEnt, Prop_Data, "m_iHealth", 5);
			SetEntityRenderColor(grenadeEnt, 255, 0, 0, 155);
			TeleportEntity(grenadeEnt, resultposition, clienteyeangle, anglevector);
			GrenArray.Push(EntIndexToEntRef(grenadeEnt));
		}
	}
}

public Event_GrenadeBounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient  = GetClientOfUserId(GetEventInt(event, "userid")),
	iGrenade = GetGrenade(iClient);
	if(!iGrenade)
		return;
	
	decl String:sClass[32];
	GetEdictClassname(iGrenade, sClass, sizeof(sClass));
	if(StrEqual(sClass, "hegrenade_projectile") && War3_GetRace(iClient)==thisRaceID && StickyNade[iClient])
	{
		StickGrenade(iClient, iGrenade);
		if(GetEntityMoveType(iGrenade) != MOVETYPE_NONE)
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);
	}
}

public GetGrenade(iClient)
{
	decl String:sClass[32] = { "hegrenade_projectile"};
	for(new i = 0, iGrenade = -1; i < sizeof(sClass); i++)
	{
		while((iGrenade = FindEntityByClassname(iGrenade, sClass[i])) != -1)
		{
			if(GetEntPropEnt(iGrenade, Prop_Send, "m_hThrower") == iClient && StickyNade[iClient])
				return iGrenade;
		}
	}
	return 0;
}

public StickGrenade(iClient, iGrenade)
{
	decl Float:flClientOrigin[3], Float:flDistance, Float:flOrigin[3];
	GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", flOrigin);
	
	new iNear = 0, Float:flMaxRadius = 20.0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", flClientOrigin);
		flDistance = GetVectorDistance(flClientOrigin, flOrigin);
		if(flDistance <= flMaxRadius)
		{
			flMaxRadius = flDistance;
			iNear       = i;
		}
	}
	if(!iNear)
		return;
	
	decl String:sClass[32];
	GetEdictClassname(iGrenade, sClass, sizeof(sClass));
	if(StrEqual(sClass, "hegrenade_projectile"))
	{
		if((iClient == iNear) || iClient != iNear)
		{
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);
			SetVariantString("!activator");
			AcceptEntityInput(iGrenade, "SetParent", iNear);
			SetVariantString("idle");
			AcceptEntityInput(iGrenade, "SetAnimation");
			SetEntProp(iGrenade,       Prop_Data, "m_nSolidType",  0);
			SetEntPropVector(iGrenade, Prop_Send, "m_angRotation", Float:{0.0, 0.0, 0.0});
		}
	}
}
/* *************************************** (ULT_DETONATE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new DetonateLevel=War3_GetSkillLevel(client,thisRaceID,ULT_DETONATE);
		if(DetonateLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_DETONATE,true,true,true))
			{
				ExplodeNades(client);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(War3_GetRace(victim)==thisRaceID)
	{
		new DetonateLevel=War3_GetSkillLevel(victim,thisRaceID,ULT_DETONATE);
		if(DetonateLevel>0)
		{
			ExplodeNades(victim);
		}
	}
}

public ExplodeNades(client)
{
	if(ValidPlayer(client))
	{
		for(int i = GrenArray.Length-1; i >= 0; i--)
		{
			int grenadeEnt = GrenArray.Get(i);
			if(IsValidEntity(grenadeEnt)) 
			{
				SetEntPropFloat(grenadeEnt, Prop_Send, "m_flDamage", GrenadeDamage*2);
				DetonateGrenade(grenadeEnt);
				GrenArray.Erase(i);
				iActiveGrenades=0;
			}
		}
	}
}

public DetonateGrenade(grenadeEnt)
{
	if (IsValidEntity(grenadeEnt))
	{
		SetEntProp(grenadeEnt, Prop_Send, "m_CollisionGroup", 5);
		SetEntProp(grenadeEnt, Prop_Data, "m_takedamage", 2);
		SetEntProp(grenadeEnt, Prop_Data, "m_iHealth", 1);
		SetEntProp(grenadeEnt, Prop_Data, "m_nNextThinkTick", 1);
		Entity_Hurt(grenadeEnt, 1, grenadeEnt);
	}
}