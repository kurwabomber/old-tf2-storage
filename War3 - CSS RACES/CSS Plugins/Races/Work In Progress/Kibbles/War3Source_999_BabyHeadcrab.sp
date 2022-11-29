#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new thisRaceID;

new SKILL_LEGS,SKILL_CLAWS;

new Float:fModelScale = 0.65;
new Float:fMoveSpeed = 1.5;
new Float:fAtkSpeed = 1.8;
new iBaseHealthChange = -99;


public Plugin:myinfo = 
{
    name = "War3Source Race - Baby Headcrab",
    author = "Kibbles",
    description = "Baby Headcrab race for War3Source.",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Baby Headcrab [Summon]", "babyheadcrab");
    SKILL_LEGS=War3_AddRaceSkill(thisRaceID,"Fast Legs (passive)", "1.5 movement speed",false,1);
    SKILL_CLAWS=War3_AddRaceSkill(thisRaceID,"Rapid Claws (passive)", "1.8 attack speed",false,1);
    War3_CreateRaceEnd(thisRaceID);
    
}

public OnPluginReady()
{
    HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
}

public OnMapStart()
{
    PrecacheModel("models/headcrab.mdl", true);
    PrecacheModel("models/headcrabblack.mdl", true);
}

public OnWar3EventSpawn(client)
{
    W3ResetAllBuffRace(client, thisRaceID);
    new race = War3_GetRace(client);
    if (race == thisRaceID)
    {
        InitRace(client);
    }
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace != thisRaceID)
    {
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3ResetAllBuffRace( client, thisRaceID );
        SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
    }
    if(newrace == thisRaceID)
    {
        InitRace(client);
    }
}
public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ValidPlayer (client, true) && War3_GetRace(client) == thisRaceID)
    {
        if (GetClientButtons(client) & (IN_ATTACK2))
        {
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

static InitRace(client)
{
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    War3_SetBuff(client,bInvisWeaponOverride,thisRaceID,true);
    War3_SetBuff(client,iInvisWeaponOverrideAmount,thisRaceID,0);
    new skill_legs = War3_GetSkillLevel(client, thisRaceID, SKILL_LEGS);
    if (skill_legs > 0)
    {
        War3_SetBuff(client, fMaxSpeed, thisRaceID, fMoveSpeed);
    }
    new skill_claws = War3_GetSkillLevel(client, thisRaceID, SKILL_CLAWS);
    if (skill_claws > 0)
    {
        War3_SetBuff(client, fAttackSpeed, thisRaceID, fAtkSpeed);
    }
    War3_SetBuff(client, iAdditionalMaxHealth, thisRaceID, iBaseHealthChange);
    new clientTeam = GetClientTeam(client);
    if(clientTeam == TEAM_T)
    {
        SetEntityModel(client, "models/headcrab.mdl");
    }
    else if (clientTeam == TEAM_CT)
    {
        SetEntityModel(client, "models/headcrabblack.mdl");
    }
    SetEntPropFloat(client, Prop_Send, "m_flModelScale", fModelScale);
}