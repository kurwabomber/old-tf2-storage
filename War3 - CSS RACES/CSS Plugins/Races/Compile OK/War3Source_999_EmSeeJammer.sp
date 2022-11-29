#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_ARMOR, SKILL_STUNSLAP, SKILL_IMMUNE, ULT_DISARM;

//Armor variables
new Float:fDamageReductionMod[11] = {0.2, ...};
new iMaxHealthModifier[11] = {-10, ...};

//StunSlap variables
new Float:fStunSlapChance[11] = {0.8, ...};
new Float:fStunDuration = 0.1;
new Float:fStunCooldown = 0.1;
new SlapDamage = 0;

//Disarm variables
new Float:fDisarmChance[11] = {0.2, ...};
new Float:fDisarmDuration = 1.0;

//Misc variables
new iClipSize = 6;
new Float:fHeadshotDamage = 16.0;
//new iCachedHP[MAXPLAYERS+1] = {90, ...};

public Plugin:myinfo = 
{
    name = "War3Source Race - Em See Jammer",
    author = "Kibbles",
    description = "Em See Jammer race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace("Em See Jammer [REWARD]", "jammer");
    
    SKILL_ARMOR = War3_AddRaceSkill(thisRaceID, "Can't Touch This", "So, they can touch you, but it wont hurt... Much...\n80% damage reduction.", false, 10);
    SKILL_STUNSLAP = War3_AddRaceSkill(thisRaceID, "Stop, Hammer Time", "Stop your enemies, and give them a good whack!\n80% chance to stun enemies you hit for 0.1 seconds and slap them.", false, 10);
    SKILL_IMMUNE = War3_AddRaceSkill(thisRaceID, "Makin' 'Em Sweat", "What's that? You're ultimate didn't work? Too bad!", false, 10);
    ULT_DISARM = War3_AddRaceSkill(thisRaceID, "Break It Down", "You're taking these lyrics too seriously, mate...\n20% chance to jam the weapons of any enemy who hits you for the next second.", false, 10);
    
    War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
    /*HookEvent("item_pickup", ItemPickupEvent);
    HookEvent("weapon_reload", WeaponReloadEvent);*/
    //HookEvent("round_start",Round_Start);
}

public OnMapStart()
{
    CreateTimer(0.5, SetWepAmmo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    //CreateTimer(0.1, BlockHealing, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


public Action:SetWepAmmo(Handle:timer)
{
    for (new i=0; i<=MAXPLAYERS; i++)
    {
        if(ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID)
        {
            if (Client_HasWeapon(i, "weapon_glock"))
            {
                new weaponEnt = Client_GetWeapon(i, "weapon_glock");
                new primaryAmmo = Weapon_GetPrimaryClip(weaponEnt);
                
                if (primaryAmmo > iClipSize)
                {
                    Client_SetWeaponAmmo(i, "weapon_glock", iClipSize*3, iClipSize*3, iClipSize, iClipSize);
                }
            }
        }
    }
}


//
// Anti-heal
//
/*public Round_Start(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new i=0; i<=MAXPLAYERS; i++)
    {
        if(ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID)
        {
            iCachedHP[i] = War3_GetMaxHP(i);
        }
    }
}

public Action:BlockHealing(Handle:timer)
{
    for (new i=0; i<=MAXPLAYERS; i++)
    {
        if(ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID)
        {
            new currentHP = GetClientHealth(i);
            new previousHP = iCachedHP[i];
            if (previousHP <= 0)
            {
                previousHP = 1;
            }
            if (currentHP > previousHP)
            {
                SetEntityHealth(i, previousHP);
                W3Hint(i, _, 1.0, "Blocking healing.");
            }
        }
    }
}*/

//
// Anti-headshot
//
public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_TraceAttack, SDK_Forwarded_TraceAttack);
}
public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_TraceAttack, SDK_Forwarded_TraceAttack); 
}

public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
    if(hitgroup == 1 && War3_GetRace(attacker) == thisRaceID){
        damage = fHeadshotDamage;
        PrintToConsole(attacker, "Em See Jammer headshot damage reduced to %i.", RoundToFloor(damage));
    }
    return Plugin_Changed;
}

//
// Buff events
//
public OnRaceChanged(client, oldrace, newrace)
{
    if (newrace == thisRaceID && ValidPlayer(client, true))
    {
        //Setup buffs/restrictions is player is changing to this race.
        initBuffs(client);
        
        if (!Client_HasWeapon(client, "weapon_glock"))
            {
                GivePlayerItem(client, "weapon_glock");
            }
            
        //iCachedHP[client] = GetClientHealth(client);
    }
    else if (oldrace == thisRaceID && ValidPlayer(client))
    {
        //Reset buffs/restrictions if player is changing from this race.
        W3ResetAllBuffRace(client, thisRaceID);
        War3_WeaponRestrictTo(client, thisRaceID, "");
    }
}


public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
    if (race == thisRaceID)
    {
        initBuffs(client);
    }
}


public OnWar3EventSpawn(client)
{
    if (War3_GetRace(client) == thisRaceID && ValidPlayer(client, true))
    {
        initBuffs(client);
        
        if (!Client_HasWeapon(client, "weapon_glock"))
        {
            GivePlayerItem(client, "weapon_glock");
        }
        
        //iCachedHP[client] = War3_GetMaxHP(client);
    }
}


//
// Buff helpers
//
static initBuffs(client)
{
    War3_WeaponRestrictTo(client, thisRaceID, "weapon_glock,weapon_knife");
    
    War3_SetBuff(client, fHPRegenDeny, thisRaceID, true);
    War3_SetBuff(client, fMaxSpeed, thisRaceID, 1.11);
    War3_SetBuff(client, bImmunityUltimates, thisRaceID, true);
    
    new skill_armor = War3_GetSkillLevel(client, thisRaceID, SKILL_ARMOR);
    War3_SetBuff(client, iAdditionalMaxHealth, thisRaceID, iMaxHealthModifier[skill_armor]);
}


//
// Skill events
//
public OnW3TakeDmgAllPre(victim, attacker, Float:damage)
{
    if (War3_GetRace(victim) == thisRaceID && ValidPlayer(victim, true))
    {
        new Float:modifier;
        
        new skill_armor = War3_GetSkillLevel(victim, thisRaceID, SKILL_ARMOR);
        if (damage*fDamageReductionMod[skill_armor] > 89.0)
        {
            //This will stop devour and other instakill abilities from doing insane amounts of damage.
            modifier = 0.01;
        }
        else
        {
            modifier = fDamageReductionMod[skill_armor];
        }
        
        War3_DamageModPercent(modifier);
        //iCachedHP[victim] -= RoundToFloor(damage*modifier);
    }
}


public OnW3TakeDmgAll(victim, attacker, Float:damage)
{
    if (War3_GetRace(attacker) == thisRaceID && War3_GetRace(attacker) != War3_GetRace(victim) && ValidPlayer(attacker, true) && ValidPlayer(victim, true) && GetClientTeam(attacker) != GetClientTeam(victim))
    {
        new skill_stunslap = War3_GetSkillLevel(attacker, thisRaceID, SKILL_STUNSLAP);
        if (GetRandomFloat(0.0,1.0) <= fStunSlapChance[skill_stunslap] && !W3HasImmunity(victim, Immunity_Skills) && War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_STUNSLAP))
        {
            War3_SetBuff(victim, bBashed, thisRaceID, true);
            CreateTimer(fStunDuration, disableStun, victim);
            
            SlapPlayer(victim, SlapDamage, true);
            
            War3_CooldownMGR(attacker,fStunCooldown,thisRaceID,SKILL_STUNSLAP, true, false);
        }
    }
    
    if (War3_GetRace(victim) == thisRaceID && War3_GetRace(attacker) != War3_GetRace(victim) && ValidPlayer(attacker, true) && ValidPlayer(victim, true) && GetClientTeam(attacker) != GetClientTeam(victim))
    {
        new ult_disarm = War3_GetSkillLevel(victim, thisRaceID, ULT_DISARM);
        if (GetRandomFloat(0.0,1.0) <= fDisarmChance[ult_disarm] && !W3HasImmunity(attacker, Immunity_Ultimates))
        {
            War3_SetBuff(attacker, bDisarm, thisRaceID, true);
            CreateTimer(fDisarmDuration, disableDisarm, attacker);
        }
    }
}


//
// Skill helpers
//
public Action:disableStun(Handle:timer, any:client)
{
    War3_SetBuff(client, bBashed, thisRaceID, false);
}


public Action:disableDisarm(Handle:timer, any:client)
{
    War3_SetBuff(client, bDisarm, thisRaceID, false);
}