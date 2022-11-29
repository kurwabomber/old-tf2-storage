#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source Race - Toy Soldier",
    author = "Kibbles",
    description = "Toy Soldier race for War3Source.",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

new thisRaceID;

new SKILL_ARMOUR, SKILL_WEAPON, SKILL_EXPLODE, ULT_METAL;

//skill_armour
new iHealthIncrease[] = {0, 15, 30, 45, 60};
//new Float:fArmourDamageMod[] = {1.0, 0.85, 0.7, 0.55, 0.4};

//skill_weapon
new Float:fFullDamageChance[] = {0.0, 0.025, 0.05, 0.075, 0.1};

//skill_explode
new Float:SuicideBomberRadius[5] = {0.0, 250.0, 290.0, 310.0, 333.0}; 
new Float:SuicideBomberDamage[5] = {0.0, 50.0, 60.0, 70.0, 80.0};

//ult_metal
new Float:fMetalAttackSlow = 0.5;
new Float:fMetalMoveSlow = 0.85;
new Float:fMetalDamage = 1.5;
new Float:fMetalDuration = 5.0;
new Float:fMetalCooldown[] = {0.0, 30.0, 25.0, 20.0, 15.0};
new bool:bMetalActive[MAXPLAYERS] = {false, ...};
new Handle:hMetalTimers[MAXPLAYERS] = {INVALID_HANDLE, ...};

//General
new Float:fModelScale = 0.75;
new Float:fDamageMod = 0.5;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Toy Soldier [SSG-DONATOR]","toysoldier");
    SKILL_ARMOUR = War3_AddRaceSkill(thisRaceID,"Plastic Armour","Durable materials\n15/30/45/60 extra health",false,4);
    SKILL_WEAPON = War3_AddRaceSkill(thisRaceID,"Plastic Weapon","Is that a toothpick?\n2.5/5/7.5/10% chance to do full damage instead of 50%",false,4);
    SKILL_EXPLODE = War3_AddRaceSkill(thisRaceID,"Plastic Explosives","Toys don't last forever...\nExplode on death (50/60/70/80 damage)",false,4);
    ULT_METAL = War3_AddRaceSkill(thisRaceID,"Metal Upgrade","Who needs plastic anyway?\nLess movement speed and attack speed, but do 150% damage for 5 seconds (30/25/20/15 second cooldown)",false,4);
    War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
    HookEvent("round_end", Round_End_Metal, EventHookMode_Pre);
}


public OnRaceChanged(client, oldrace, newrace)
{
    if(newrace == thisRaceID)
    {
        if (ValidPlayer(client, true))
        {
            InitRace(client);
        }
    }
    else
    {
        if (ValidPlayer(client))
        {
            //Reset buffs/restrictions if player is changing from this race.
            War3_WeaponRestrictTo(client, thisRaceID, "");
            W3ResetAllBuffRace(client, thisRaceID);
            W3ResetPlayerColor(client, thisRaceID);
            SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
        }
    }
}


public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
    if (ValidPlayer(client, true) && race == thisRaceID)
    {
        InitRace(client);
    }
}


public OnWar3EventSpawn(client)
{
    if(ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        InitRace(client);
    }
}


public OnWar3EventDeath(victim, attacker)
{
    if(ValidPlayer(victim) && War3_GetRace(victim) == thisRaceID)
    {
        if (hMetalTimers[victim] != INVALID_HANDLE)
        {
            TriggerTimer(hMetalTimers[victim]);
            hMetalTimers[victim] = INVALID_HANDLE;
        }
        
        new skill_explode = War3_GetSkillLevel(victim, thisRaceID, SKILL_EXPLODE);
        if(skill_explode > 0 && !Hexed(victim))
        {
            decl Float:fVictimPos[3];
            GetClientAbsOrigin(victim, fVictimPos);
            
            War3_SuicideBomber(victim, fVictimPos, SuicideBomberDamage[skill_explode], SKILL_EXPLODE, SuicideBomberRadius[skill_explode]);
        }
    }
}


public OnW3TakeDmgAllPre(victim, attacker, Float:damage)
{
    if (ValidPlayer(victim, true) && War3_GetRace(victim) == thisRaceID)
    {
        new skill_armour = War3_GetSkillLevel(victim, thisRaceID, SKILL_ARMOUR);
        if (skill_armour > 0)
        {
            //War3_DamageModPercent(fArmourDamageMod[skill_armour]);
        }
    }
    else if (ValidPlayer(attacker, true) && War3_GetRace(attacker) == thisRaceID)
    {
        new skill_weapon = War3_GetSkillLevel(attacker, thisRaceID, SKILL_WEAPON);
        if (bMetalActive[attacker])
        {
            War3_DamageModPercent(fMetalDamage);
        }
        else if (skill_weapon > 0 && W3Chance(fFullDamageChance[skill_weapon]))
        {
            //
        }
        else
        {
            War3_DamageModPercent(fDamageMod);
        }
    }
}


public OnUltimateCommand(client, race, bool:pressed)
{
    if (ValidPlayer(client, true) && race == thisRaceID && pressed)
    {
        new ult_metal = War3_GetSkillLevel(client, thisRaceID, ULT_METAL);
        if (ult_metal > 0 && War3_SkillNotInCooldown(client, thisRaceID, ULT_METAL, true) && !Silenced(client, true))
        {
            War3_CooldownMGR(client, fMetalCooldown[ult_metal], thisRaceID, ULT_METAL, true, true);
            
            bMetalActive[client] = true;
            
            War3_SetBuff(client, fSlow, thisRaceID, fMetalMoveSlow);
            War3_SetBuff(client, fAttackSpeed, thisRaceID, fMetalAttackSlow);
            SetPlayerColour(client);
            
            PrintHintText(client, "You turn in to metal!");
            hMetalTimers[client] = CreateTimer(fMetalDuration, StopMetal, client);
        }
    }
}
public Action:StopMetal(Handle:timer, any:client)
{
    if (ValidPlayer(client))
    {
        bMetalActive[client] = false;
        
        W3ResetBuffRace(client, fSlow, thisRaceID);
        W3ResetBuffRace(client, fAttackSpeed, thisRaceID);
        SetPlayerColour(client);
        
        PrintHintText(client, "You turn back in to plastic");
    }
}
public Round_End_Metal(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new i=0; i<MAXPLAYERS; i++)
    {
        if (hMetalTimers[i] != INVALID_HANDLE)
        {
            TriggerTimer(hMetalTimers[i]);
            hMetalTimers[i] = INVALID_HANDLE;
        }
    }
}


static InitRace(client)
{
    SetEntPropFloat(client, Prop_Send, "m_flModelScale", fModelScale);
    SetPlayerColour(client);
    
    new skill_armour = War3_GetSkillLevel(client, thisRaceID, SKILL_ARMOUR);
    War3_SetBuff(client, iAdditionalMaxHealth, thisRaceID, iHealthIncrease[skill_armour]);
}


static SetPlayerColour(client)
{
    if (bMetalActive[client])
    {
        W3SetPlayerColor(client, thisRaceID, 115, 115, 115, _, GLOW_BASE);
    }
    else
    {
        W3ResetPlayerColor(client, thisRaceID);
        /*if (GetClientTeam(client) == TEAM_T)
        {
            W3SetPlayerColor(client, thisRaceID, 255, 0, 0, _, GLOW_BASE);
        }
        else if (GetClientTeam(client) == TEAM_CT)
        {
            W3SetPlayerColor(client, thisRaceID, 0, 0, 255, _, GLOW_BASE);
        }*/
    }
}