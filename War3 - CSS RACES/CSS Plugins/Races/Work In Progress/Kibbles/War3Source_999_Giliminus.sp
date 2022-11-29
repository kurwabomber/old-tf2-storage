#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Giliminus",
	author = "ABGar",
	description = "The Giliminus race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_JUMP, SKILL_ATTACK, SKILL_DAMAGE;

new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
new Float:SkillLongJump[]={0.0,0.75};
new Float:GilimAttackSpeed[]={1.0,1.4};
new Float:GilimDamage[]={0.0,0.3};


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Giliminus [Summon]","giliminus");
	SKILL_JUMP = War3_AddRaceSkill(thisRaceID,"Giliminus Jump","Long Jump",false,1);
	SKILL_ATTACK = War3_AddRaceSkill(thisRaceID,"Giliminus Attack","Attack Speed",false,1);
	SKILL_DAMAGE = War3_AddRaceSkill(thisRaceID,"Giliminus Damage","Increased Damage",false,1);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_ATTACK,fAttackSpeed,GilimAttackSpeed);
	War3_AddSkillBuff(thisRaceID,SKILL_DAMAGE,fDamageModifier,GilimDamage);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.75);
}

public OnPluginStart()
{
    HookEvent("player_jump",PlayerJumpEvent);
    m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
}

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid"));
    if(War3_GetRace(client)==thisRaceID)
    {
        new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_JUMP);
        if(skilllevel>0)
        {
            new Float:velocity[3]={0.0,0.0,0.0};
            velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
            velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
            velocity[0]*=SkillLongJump[skilllevel];
            velocity[1]*=SkillLongJump[skilllevel];
            SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
        }
    }
}
