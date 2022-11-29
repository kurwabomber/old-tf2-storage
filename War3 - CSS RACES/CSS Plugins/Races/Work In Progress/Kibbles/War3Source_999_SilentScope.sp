#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source Race - Silent Scope",
    author = "Zeretal (coded by Kibbles)",
    description = "Silent Scope race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new thisRaceID;
new SKILL_SPEEDSTEPS, SKILL_STEALTH, SKILL_DAMAGE, ULT_NETARROW;

//skill_speedsteps
new Float:fExtraSpeed[] = {1.0, 1.04, 1.08, 1.12, 1.15};
new Float:fSilentChance[] = {0.0, 0.125, 0.25, 0.375, 0.5};
new bool:bSilent[MAXPLAYERS];
new bool:bChecked[MAXPLAYERS] = {false, ...};

//skill_stealth
new Float:fVisibility[] = {1.0, 0.9, 0.8, 0.65, 0.5};

//skill_damage
new Float:fExtraDamage[] = {0.0, 0.1, 0.2, 0.3, 0.4};

//ult_netarrow
new Float:fArrowMaxRange = 1200.0;
new Float:fArrowEffectRadius = 200.0;
new Float:fArrowEntangleTime = 2.0;
new bool:bEntangled[MAXPLAYERS];
new Float:fArrowActiveDuration = 10.0;
new bool:bArrowActive[MAXPLAYERS];
new Handle:hArrowDisableTimers[MAXPLAYERS];
new Float:fArrowCooldown[] = {0.0, 40.0, 30.0, 25.0, 20.0};
new BeamSprite, HaloSprite;
new String:entangleSound[256];


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Silent Scope [PRIVATE]", "silentscope");
    
    SKILL_SPEEDSTEPS = War3_AddRaceSkill(thisRaceID, "Tread Lightly", "Silent Speed - More Speed (1.04/1.08/1.12/1.15) and chance of Silent footsteps (12.5%/25%/37.5%/50%)", false, 4);
    SKILL_STEALTH = War3_AddRaceSkill(thisRaceID, "Unseen", "Stealth - Invisibility (.9/.8/.65/.5)", false, 4);
    SKILL_DAMAGE = War3_AddRaceSkill(thisRaceID, "Deadly", "Damage - Extra damage (1.1/1.2/1.3/1.4) Guns only", false, 4);
    ULT_NETARROW = War3_AddRaceSkill(thisRaceID, "Net Arrow", "Bullet shoots out entangling roots - 1200 units max range, entangles within 200 units of bullet for 2 seconds", true, 4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEEDSTEPS, fMaxSpeed, fExtraSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_STEALTH, fInvisibilitySkill, fVisibility);
    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, fExtraDamage);
}


public OnPluginStart()
{
    HookEvent("weapon_fire", Weapon_Fired);
}


public OnMapStart()
{
    War3_AddSoundFolder(entangleSound, sizeof(entangleSound), "entanglingrootsdecay1.mp3");

    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();

    War3_AddCustomSound(entangleSound);
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
        //Reset buffs/restrictions if player is changing from this race.
        W3ResetAllBuffRace(client, thisRaceID);
        War3_WeaponRestrictTo(client, thisRaceID, "");
    }
}


public OnWar3EventSpawn(client)
{
    War3_SetBuff(client, bNoMoveMode, thisRaceID, false);//remove entangle
    bEntangled[client] = false;
    bSilent[client] = false;
    bArrowActive[client] = false;
    if(ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        bChecked[client] = false;
        InitRace(client);
        if (!Client_HasWeapon(client, "weapon_scout"))
        {
            Client_GiveWeapon(client, "weapon_scout", true);
        }
        if (!Client_HasWeapon(client, "weapon_usp"))
        {
            Client_GiveWeapon(client, "weapon_usp", false);
        }
        if (!Client_HasWeapon(client, "weapon_knife"))
        {
            Client_GiveWeapon(client, "weapon_knife", false);
        }
    }
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer(client, true))
    {
        if(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP) && bSilent[client])
        {
            SetEntProp(client, Prop_Send, "m_fFlags", 4);
        }
    }
    return Plugin_Continue;
}


public OnUltimateCommand(client, race, bool:pressed)
{
    if(ValidPlayer(client, true) && race == thisRaceID && pressed)
    {
        if (bArrowActive[client])
        {
            PrintHintText(client, "Net Arrow is already active");
        }
        else
        {
            if (!Silenced(client, true))
            {
                new ult_netarrow = War3_GetSkillLevel(client, thisRaceID, ULT_NETARROW);
                if (ult_netarrow > 0 && War3_SkillNotInCooldown(client, thisRaceID, ULT_NETARROW, true))
                {
                    bArrowActive[client] = true;
                    hArrowDisableTimers[client] = CreateTimer(fArrowActiveDuration, DisableNetArrow, client);
                    PrintHintText(client, "Net Arrow has been activated, shoot within 10 seconds");
                }
            }
        }
    }
}
public Action:DisableNetArrow(Handle:timer, any:client)
{
    if (bArrowActive[client])
    {
        new ult_netarrow = War3_GetSkillLevel(client, thisRaceID, ULT_NETARROW);
        War3_CooldownMGR(client, fArrowCooldown[ult_netarrow], thisRaceID, ULT_NETARROW, true, true);
        bArrowActive[client] = false;
        if (hArrowDisableTimers[client] != INVALID_HANDLE)
        {
            hArrowDisableTimers[client] = INVALID_HANDLE;
        }
        PrintHintText(client, "Net Arrow has been disabled");
    }
}
public OnWar3EventDeath(victim, attacker)
{
    if (ValidPlayer(attacker) && War3_GetRace(attacker) == thisRaceID && hArrowDisableTimers[attacker] != INVALID_HANDLE)
    {
        TriggerTimer(hArrowDisableTimers[attacker]);
        hArrowDisableTimers[attacker] = INVALID_HANDLE;
    }
}
public Weapon_Fired(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID && bArrowActive[client])
    {
        new String:weapon[64];
        GetEventString(event, "weapon", weapon, 64);
        
        if (StrContains(weapon, "knife", false)==-1 && StrContains(weapon, "hegrenade", false)==-1 && StrContains(weapon, "flashbang", false)==-1 && StrContains(weapon, "smokegrenade", false))
        {
            new clientTeam = GetClientTeam(client);
            new Float:clientPos[3];
            GetClientAbsOrigin(client, clientPos);
            new Float:bulletPos[3];
            War3_GetAimTraceMaxLen(client, bulletPos, fArrowMaxRange);
            
            TE_SetupBeamPoints(clientPos, bulletPos, BeamSprite,
                               HaloSprite, 0, 50, 1.0, 2.0, 2.0, 0, 
                               12.0, {80, 255, 90, 127}, 40);
            TE_SendToClient(client);
            
            new Float:targetPos[3];
            new target = 0;
            for (new i=1; i<=MaxClients; i++)
            {
                if (i != client && ValidPlayer(i, true) && GetClientTeam(i) != clientTeam && !bEntangled[i])
                {
                    GetClientAbsOrigin(i, targetPos);
                    if (GetVectorDistance(bulletPos, targetPos) <= fArrowEffectRadius)
                    {
                        target = i;
                        break;
                    }
                }
            }
            
            if(ValidPlayer(target, true) && !IsUltImmune(target))
            {
                new ult_netarrow = War3_GetSkillLevel(client, thisRaceID, ULT_NETARROW);
                War3_CooldownMGR(client, fArrowCooldown[ult_netarrow], thisRaceID, ULT_NETARROW, true, true);
                bArrowActive[client] = false;
                if (hArrowDisableTimers[client] != INVALID_HANDLE)
                {
                    KillTimer(hArrowDisableTimers[client]);
                    hArrowDisableTimers[client] = INVALID_HANDLE;
                }
                
                bEntangled[target] = true;
                War3_SetBuff(target, bNoMoveMode, thisRaceID, true);
                CreateTimer(fArrowEntangleTime, StopEntangle, target);
                
                for (new i=0; i <= 3; i++)
                {
                    targetPos[2] += 15.0;
                    TE_SetupBeamRingPoint(targetPos, 45.0, 44.0, BeamSprite,
                                          HaloSprite, 0, 15, fArrowEntangleTime,
                                          5.0, 0.0, {0, 255, 0, 255}, 10, 0);
                    TE_SendToAll();
                }

                TE_SetupBeamPoints(bulletPos, targetPos, BeamSprite,
                                   HaloSprite, 0, 50, 4.0, 6.0, 25.0, 0, 
                                   12.0, {80, 255, 90, 255}, 40);
                TE_SendToAll();
                
                TE_SetupBeamPoints(clientPos, bulletPos, BeamSprite,
                                   HaloSprite, 0, 50, 4.0, 6.0, 25.0, 0, 
                                   12.0, {80, 255, 90, 255}, 40);
                TE_SendToAll();
                
                W3EmitSoundToAll(entangleSound, target);
                W3EmitSoundToAll(entangleSound, target);

                W3MsgEntangle(target, client);
            }
            else
            {
                W3MsgNoTargetFound(client, fArrowEffectRadius);
            }
        }
    }
}
public Action:StopEntangle(Handle:timer, any:client)
{
    if (bEntangled[client])
    {
        bEntangled[client] = false;
        War3_SetBuff(client, bNoMoveMode, thisRaceID, false);
    }
}


//
// Helper functions
//
public InitRace(client)
{
    War3_WeaponRestrictTo(client, thisRaceID, "weapon_scout,weapon_usp,weapon_knife,weapon_hegrenade,weapon_flashbang,weapon_smokegrenade");
    War3_SetBuff(client, iDamageMode, thisRaceID, 1);//bullets only
    bSilent[client] = false;
    bArrowActive[client] = false;
    if (hArrowDisableTimers[client] != INVALID_HANDLE)
    {
        KillTimer(hArrowDisableTimers[client]);
        hArrowDisableTimers[client] = INVALID_HANDLE;
    }
    if (!bChecked[client])
    {
        bChecked[client] = true;
        new skill_speedsteps = War3_GetSkillLevel(client, thisRaceID, SKILL_SPEEDSTEPS);
        if (skill_speedsteps > 0 && W3Chance(fSilentChance[skill_speedsteps]))
        {
            bSilent[client] = true;
            Client_PrintToChat(client, false, "{R}[SilentScope]{N} Your footsteps are silenced");
        }
        else
        {
            Client_PrintToChat(client, false, "{R}[SilentScope]{N} Your footsteps will be heard");
        }
    }
}