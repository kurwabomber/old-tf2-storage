#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"
//#include <sdktools>

new thisRaceID;

new SKILL_KNIFES; 
new g_iMaxDaggers[] = {0,2,4,6,8,10,12 };
new SKILL_STEADY; 
new g_iSteadyDamage[] = {40,50,60,70,80,90,100};
new g_iSteadyHsDamage[] = {90,100,110,120,130,140,150};

new SKILL_THROW; 
new Float:g_flThrowVelocity[] = {1600.0,1800.0,2000.0,2200.0,2400.0,2600.0,2800.0};

new SKILL_LIGHTWEIGHT;
new Float:g_flLightWeightSpeed[] = {1.0,1.1,1.2,1.3,1.4,1.5,1.6};

new SKILL_SHADOW; 
new Float:g_flShadowTimer[] = {0.0,5.0,4.0,3.0,2.0,1.0};
new Float:caninvistime[MAXPLAYERS+1];

new ULT_RESTORE; 
new g_iRestoreCount[] = {0,2,4,6};
new Float:g_flRestoreCooldown[] = {0.0,20.0,15.0,10.0};

// Throwing knifes
new g_iCurrentKnifes[MAXPLAYERS+1];
//new Float:g_fKnifesVelocity = 2250.0;
new Handle:g_hLethalArray;


new g_iKnifeMI,g_iTrailMI;
#define KNIFE_MDL "models/weapons/w_knife_ct.mdl"
#define KNIFEHIT_SOUND "weapons/knife/knife_hit3.wav"
#define TRAIL_MDL "materials/sprites/lgtning.vmt"
#define TRAIL_COLOR {177, 177, 177, 117}
#define ADD_OUTPUT "OnUser1 !self:Kill::1.7:1"
new const Float:g_fSpin[3] = {1877.4, 0.0, 0.0};
new const Float:g_fMinS[3] = {-16.0, -16.0, -16.0};
new const Float:g_fMaxS[3] = {16.0, 16.0, 16.0};
new g_iPointHurt;
new g_iEnvBlood;
new m_vecVelocity = -1;
new Float:g_flAttackSpeed = 0.6;

public Plugin:myinfo = {

	name = "War3Source Race - Ghost Sentinel",
	author = "Namolem",
	version = "1.0.0.1",
	description = "The Ghost Sentinel race for War3Source.",
	url = "http://arsenall.net"
};

public OnMapStart() {
	g_iKnifeMI = PrecacheModel(KNIFE_MDL);
	g_iTrailMI = PrecacheModel(TRAIL_MDL);
	PrecacheSound(KNIFEHIT_SOUND);
}
public OnPluginStart()
{
	LoadTranslations("w3s.race.ghostsent.phrases");
	HookEvent("weapon_fire", EventWeaponFire);
	HookEvent("round_start",EventRoundStart);
	g_hLethalArray = CreateArray();

	AddNormalSoundHook(NormalSHook:SoundsHook);
	CreateTimer(0.1,CalcVis,_,TIMER_REPEAT);
	m_vecVelocity = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
}
public Action:CalcVis(Handle:timer)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&War3_GetRace(i)==thisRaceID)
		{
			new shadow_level = War3_GetSkillLevel(i,thisRaceID,SKILL_SHADOW);
			if(caninvistime[i]<GetGameTime() && shadow_level>0)
			{
				War3_SetBuff(i,fInvisibilitySkill,thisRaceID,0.0);
			}
			else
			{
				War3_SetBuff(i,fInvisibilitySkill,thisRaceID,1.0);
			}
			decl Float:velocity[3];
			GetEntDataVector(i,m_vecVelocity,velocity);
			if(shadow_level>0&&GetVectorLength(velocity) > 0)
			{
				caninvistime[i]=GetGameTime() + g_flShadowTimer[shadow_level];
			}
		}
	}	
}
public OnWar3PluginReady()
{
	
	
		
		thisRaceID         = War3_CreateNewRaceT("ghostsent");
		SKILL_KNIFES       = War3_AddRaceSkillT(thisRaceID,"knifes",false,6);
		SKILL_STEADY       = War3_AddRaceSkillT(thisRaceID,"steady",false,6);
		SKILL_THROW        = War3_AddRaceSkillT(thisRaceID,"throw",false,6);
		SKILL_LIGHTWEIGHT  = War3_AddRaceSkillT(thisRaceID,"lightweight",false,6);
		SKILL_SHADOW       = War3_AddRaceSkillT(thisRaceID,"shadow",false,5);
		ULT_RESTORE        = War3_AddRaceSkillT(thisRaceID,"restore",true,3);
		War3_CreateRaceEnd(thisRaceID);
	
}

public OnRaceChanged(client,oldrace,newrace)
{
	if (newrace == thisRaceID)
	{
		new lightweight = War3_GetSkillLevel(client,thisRaceID,SKILL_LIGHTWEIGHT);
		if (lightweight > 0)
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,g_flLightWeightSpeed[lightweight]);
		}
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	}
	else
	{
		W3ResetAllBuffRace(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID,"");
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if (race == thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level = War3_GetSkillLevel(client,thisRaceID,ULT_RESTORE);
		if (ult_level > 0)
		{
			if (War3_SkillNotInCooldown(client,thisRaceID,ULT_RESTORE,true))
			{
				new knifes_level = War3_GetSkillLevel(client,thisRaceID,SKILL_KNIFES);
				new restore_max_count = g_iMaxDaggers[knifes_level] - g_iCurrentKnifes[client]; 
				new restore_count = (g_iRestoreCount[ult_level] > restore_max_count) ? restore_max_count : g_iRestoreCount[ult_level] ;
				if (restore_max_count > 0)
				{
					g_iCurrentKnifes[client] += restore_count;
					PrintHintText(client,"%t", "Throwing Knives : {1}", g_iCurrentKnifes[client]);
					War3_CooldownMGR(client,g_flRestoreCooldown[ult_level],thisRaceID,ULT_RESTORE);
				}
				else
				{
					PrintHintText(client,"%t","You already have too much knifes");
				}
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if (ValidPlayer(victim) && War3_GetRace(victim) == thisRaceID)
	{
		g_iCurrentKnifes[victim] = 0;
	}
}


public OnWar3EventSpawn(client)
{
	if (ValidPlayer(client) && War3_GetRace(client) == thisRaceID)
	{
		g_iCurrentKnifes[client] = g_iMaxDaggers[War3_GetSkillLevel(client,thisRaceID,SKILL_KNIFES)];
		new lightweight = War3_GetSkillLevel(client,thisRaceID,SKILL_LIGHTWEIGHT);
		if (lightweight > 0)
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,g_flLightWeightSpeed[lightweight]);
		}
		PrintHintText(client,"%t", "Throwing Knives : {1}", g_iCurrentKnifes[client]);
		War3_SetBuff(client,fAttackSpeed,thisRaceID,g_flAttackSpeed);
	}
}
ThrowKnife(client) {
	if (War3_GetRace(client) == thisRaceID)
	{
		new Float:flKnifeVelocity = g_flThrowVelocity[War3_GetSkillLevel(client,thisRaceID,SKILL_THROW)];
		static Float:fPos[3], Float:fAng[3], Float:fVel[3];
		GetClientEyePosition(client, fPos);
		/* simple noblock fix. prevent throw if it will spawn inside another client */
		/* create & spawn entity. set model & owner. set to kill itself OnUser1 */
		new entity = CreateEntityByName("flashbang_projectile");
		if ((entity != -1) && DispatchSpawn(entity)) {
			SetEntityModel(entity, KNIFE_MDL);
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetVariantString(ADD_OUTPUT);
			AcceptEntityInput(entity, "AddOutput");
			/* calc & set spawn position, angle, velocity & spin */
			GetClientEyeAngles(client, fAng);
			GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(fVel, flKnifeVelocity);
			SetEntPropVector(entity, Prop_Data, "m_vecAngVelocity", g_fSpin);
			SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.2);
			/* add to lethal knife array then teleport... */
			PushArrayCell(g_hLethalArray, entity);
			TeleportEntity(entity, fPos, fAng, fVel);
			--g_iCurrentKnifes[client];
			PrintHintText(client,"%t", "Throwing Knives : {1}", g_iCurrentKnifes[client]);
			TE_SetupBeamFollow(entity, g_iTrailMI, 0, 0.7, 7.7, 7.7, 3, TRAIL_COLOR);
			TE_SendToAll();
		}
	}
}

public EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ValidPlayer(client,true) && War3_GetRace(client) == thisRaceID) 
	{
		static String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		if (StrEqual(sWeapon, "knife") && (g_iCurrentKnifes[client] > 0))
			ThrowKnife(client);
		new shadow_level = War3_GetSkillLevel(client,thisRaceID,SKILL_SHADOW);
		if(shadow_level>0)
		{
			caninvistime[client]=GetGameTime() + g_flShadowTimer[shadow_level];
		}
	}
}

public EventRoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	ClearArray(g_hLethalArray);
	CreateEnts();
}


public Action:SoundsHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) {

	if (StrEqual(sample, "weapons/flashbang/grenade_hit1.wav", false)) {
		new index = FindValueInArray(g_hLethalArray, entity);
		if (index != -1) {
			volume = 0.2;
			RemoveFromArray(g_hLethalArray, index); /* delethalize on first "hit" */
			new attacker = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if (War3_GetRace(attacker) == thisRaceID)
			{
				static Float:fKnifePos[3], Float:fAttPos[3], Float:fVicEyePos[3];
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fKnifePos);
				new victim = GetTraceHullEntityIndex(fKnifePos, attacker);
				if (IsClientIndex(victim) && IsClientInGame(attacker)) {
					RemoveEdict(entity);
					if (GetClientTeam(victim) != GetClientTeam(attacker)) {
						GetClientAbsOrigin(attacker, fAttPos);
						GetClientEyePosition(victim, fVicEyePos);
						EmitAmbientSound(KNIFEHIT_SOUND, fKnifePos, victim, SNDLEVEL_NORMAL, _, 0.7);
						new steady_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_STEADY);
						decl String:damage[8];
						if ((FloatAbs(fKnifePos[2] - fVicEyePos[2]) < 4.7))
						{
							Format(damage,sizeof(damage),"%d",g_iSteadyHsDamage[steady_level]);
						}
						else
						{
							Format(damage,sizeof(damage),"%d",g_iSteadyDamage[steady_level]);
						}
						
						Hurt(victim, attacker, fAttPos,  damage);
						Bleed(victim);
					}
				}
				else /* didn't hit a player, kill itself in a few moments */
					AcceptEntityInput(entity, "FireUser1");
				return Plugin_Changed;
			}
		}
		else if (GetEntProp(entity, Prop_Send, "m_nModelIndex") == g_iKnifeMI) {
			volume = 0.2;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
public bool:THFilter(entity, contentsMask, any:data) {

	return IsClientIndex(entity) && (entity != data);
}
Bleed(client) {

	if (IsValidEntity(g_iEnvBlood))
		AcceptEntityInput(g_iEnvBlood, "EmitBlood", client);
}
GetTraceHullEntityIndex(Float:pos[3], xindex) {

	TR_TraceHullFilter(pos, pos, g_fMinS, g_fMaxS, MASK_SHOT, THFilter, xindex);
	return TR_GetEntityIndex();
}
bool:IsClientIndex(index) {

	return (index > 0) && (index <= MaxClients);
}
CreateEnts() {

	if (((g_iPointHurt = CreateEntityByName("point_hurt")) != -1) && DispatchSpawn(g_iPointHurt)) {
		DispatchKeyValue(g_iPointHurt, "DamageTarget", "hurt");
		DispatchKeyValue(g_iPointHurt, "DamageType", "0");
	}
	if (((g_iEnvBlood = CreateEntityByName("env_blood")) != -1) && DispatchSpawn(g_iEnvBlood)) {
		DispatchKeyValue(g_iEnvBlood, "spawnflags", "13");
		DispatchKeyValue(g_iEnvBlood, "amount", "1000");
	}
}

Hurt(victim, attacker, Float:attackerPos[3], String:damage[]) {

	if (IsValidEntity(g_iPointHurt)) {
		DispatchKeyValue(victim, "targetname", "hurt");
		DispatchKeyValue(g_iPointHurt, "Damage", damage);
		DispatchKeyValue(g_iPointHurt, "classname", "weapon_knife");
		TeleportEntity(g_iPointHurt, attackerPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(g_iPointHurt, "Hurt", attacker);
		DispatchKeyValue(g_iPointHurt, "classname", "point_hurt");
		DispatchKeyValue(victim, "targetname", "nohurt");
	}
}