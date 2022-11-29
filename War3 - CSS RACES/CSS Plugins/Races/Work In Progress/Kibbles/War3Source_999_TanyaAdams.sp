#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo = 
{
    name = "War3Source Race - Tanya Adams",
    author = "Camdog (coded by Kibbles)",
    description = "Tanya Adams race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new thisRaceID;
new SKILL_HEALTH, SKILL_DAMAGE, SKILL_BOMB, ULT_RAGE;

//skill_health
new iHealthIncrease[] = {0, 20, 30, 40, 50};

//skill_damage
new Float:fDamageIncrease[] = {0.0, 0.05, 0.1, 0.15, 0.2};

//skill_bomb
new Float:fBombDamage = 60.0;//40 originally
new Float:fBombRadius = 262.0;//10m diameter
new Float:fBombPrimeTime = 5.0;
new Float:fBombCooldown[] = {0.0, 60.0, 50.0, 40.0, 30.0};
new BombEntities[MAXPLAYERS] = {-1, ...};
new Float:BombPrimeTimes[MAXPLAYERS];
new Handle:hBombPrimeTimeTimers[MAXPLAYERS];

//ult_rage
new Float:fEvasion[] = {0.0, 0.05, 0.1, 0.15, 0.2};
new Float:fSpeedIncrease[] = {1.0, 1.05, 1.1, 1.15, 1.2};
new Float:fRageDuration = 5.0;
new Float:fRageCooldown = 30.0;
new Handle:hRageTimers[MAXPLAYERS] = {INVALID_HANDLE, ...};

//sounds
new String:BombPlantSound[256];// = "sound/war3source/tanyaadams/laugh1.wav";
new String:OnRageSound[256];// = "sound/war3source/tanyaadams/tuffguy1.wav";
new String:OnSpawnSound[256];// = "sound/war3source/tanyaadams/rokroll1.wav";
new String:OnKillSound[256];// = "sound/war3source/tanyaadams/bombit1.wav";


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Tanya Adams [PRIVATE]", "tanyaadams");
    
    SKILL_HEALTH = War3_AddRaceSkill(thisRaceID, "That all you got? (passive)", "Tanya is tougher than the average soldier\nGain (20/30/40/50) max health", false, 4);
    SKILL_DAMAGE = War3_AddRaceSkill(thisRaceID, "Shake it Baby (passive)", "Tanya's skill with firearms are uncanny\nGain (5/10/15/20%) extra damage", false, 4);
    SKILL_BOMB = War3_AddRaceSkill(thisRaceID, "Bomb (+ability)", "Tanya plants a bomb\n5 second priming time, press again to detonate (60/50/40/30 second cooldown)", false, 4);
    ULT_RAGE = War3_AddRaceSkill(thisRaceID, "Chew on this! (+ultimate)", "Tanya flies into a rage\nGain (5/10/15/20%) and speed for 5 seconds (30 second cooldown)", true, 4);
    
    War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
    HookEvent("round_end",Round_End_Bomb, EventHookMode_Pre);
    HookEvent("round_end",Round_End_Rage, EventHookMode_Pre);//Less efficient to have two hooks, but makes the code easier to organize
}


public OnMapStart()
{
    AddFileToDownloadsTable("sound/war3source/tanyaadams/laugh1.wav");
    AddFileToDownloadsTable("sound/war3source/tanyaadams/tuffguy1.wav");
    AddFileToDownloadsTable("sound/war3source/tanyaadams/rokroll1.wav");
    AddFileToDownloadsTable("sound/war3source/tanyaadams/bombit1.wav");
    /*if (!IsSoundPrecached(BombPlantSound))
    {
        PrecacheSound(BombPlantSound);
    }
    if (!IsSoundPrecached(OnRageSound))
    {
        PrecacheSound(OnRageSound);
    }
    if (!IsSoundPrecached(OnSpawnSound))
    {
        PrecacheSound(OnSpawnSound);
    }
    if (!IsSoundPrecached(OnKillSound))
    {
        PrecacheSound(OnKillSound);
    }*/
    War3_AddSoundFolder(BombPlantSound, sizeof(BombPlantSound), "tanyaadams/laugh1.wav");
    War3_AddSoundFolder(OnRageSound, sizeof(OnRageSound), "tanyaadams/tuffguy1.wav");
    War3_AddSoundFolder(OnSpawnSound, sizeof(OnSpawnSound), "tanyaadams/rokroll1.wav");
    War3_AddSoundFolder(OnKillSound, sizeof(OnKillSound), "tanyaadams/bombit1.wav");

    War3_AddCustomSound(BombPlantSound);
    War3_AddCustomSound(OnRageSound);
    War3_AddCustomSound(OnSpawnSound);
    War3_AddCustomSound(OnKillSound);
}


public OnRaceChanged(client, oldrace, newrace)
{
    if(newrace == thisRaceID && ValidPlayer(client, true))
    {
        InitRace(client);
        GiveWeapon(client);
    }
    else
    {
        //Reset buffs/restrictions if player is changing from this race.
        W3ResetAllBuffRace(client, thisRaceID);
        War3_WeaponRestrictTo(client, thisRaceID, "");
    }
}


public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
    if (War3_GetRace(client) == thisRaceID)
    {
        InitRace(client);
    }
}


public OnWar3EventSpawn(client)
{
    if(War3_GetRace(client) == thisRaceID && ValidPlayer(client, true))
    {
        InitRace(client);
        GiveWeapon(client);
        EmitSoundToAll(OnSpawnSound, client);
    }
}


public OnAbilityCommand(client, ability, bool:pressed)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID && ability == 0 && pressed)
	{
        new skill_bomb = War3_GetSkillLevel(client, thisRaceID, SKILL_BOMB);
        if (skill_bomb > 0 && !Silenced(client, true))
        {
            if (IsValidEntity(BombEntities[client]))
            {
                if (GetGameTime() > BombPrimeTimes[client])
                {
                    DetonateGrenade(BombEntities[client]);
                    BombEntities[client] = -1;
                }
                else
                {
                    PrintHintText(client, "Bomb will be primed in %.1f seconds", (BombPrimeTimes[client] - GetGameTime()));
                }
            }
            else
            {
                if (War3_SkillNotInCooldown(client, thisRaceID, SKILL_BOMB, true))
                {
                    new Float:clientPos[3];
                    GetClientAbsOrigin(client, clientPos);
                    clientPos[2]+=5.0;//raise it off the ground
                    
                    BombEntities[client] = DropGrenade(client, clientPos, fBombDamage, fBombRadius);
                    BombPrimeTimes[client] = GetGameTime() + fBombPrimeTime;
                    
                    if (IsValidEntity(BombEntities[client]))
                    {
                        War3_CooldownMGR(client, fBombCooldown[skill_bomb], thisRaceID, SKILL_BOMB, true, true);
                        hBombPrimeTimeTimers[client] = CreateTimer(fBombPrimeTime, BombPrimedMessage, client);
                        EmitSoundToAll(BombPlantSound, client);
                        PrintHintText(client, "Bomb has been planted");
                    }
                    else
                    {
                        PrintHintText(client, "Bomb could not be planted");
                    }
                }
            }
        }
    }
}
public Round_End_Bomb(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=0; i<MAXPLAYERS; i++)
    {
        if (IsValidEntity(BombEntities[i]))
        {
            DetonateGrenade(BombEntities[i]);
            BombEntities[i] = -1;
        }
        if (hBombPrimeTimeTimers[i] != INVALID_HANDLE)
        {
            KillTimer(hBombPrimeTimeTimers[i]);
            hBombPrimeTimeTimers[i] = INVALID_HANDLE;
        }
    }
}
public DropGrenade(any:client, Float:pos[3], Float:damage, Float:radius)
{
    //Code taken and adapted from AlliedMods posts by BrianGriffin and thetwistedpanda.
    new grenadeEnt = CreateEntityByName("hegrenade_projectile");
    
    if (IsValidEntity(grenadeEnt) && !arrayCompare3(pos, NULL_VECTOR))
    {
        // Thrower
        SetEntPropEnt(grenadeEnt, Prop_Send, "m_hOwnerEntity", client);
        SetEntPropEnt(grenadeEnt, Prop_Send, "m_hThrower", client);
        SetEntProp(grenadeEnt, Prop_Send, "m_iTeamNum", GetClientTeam(client));
        
        // Pull the pin!
        /*SetEntProp(grenadeEnt, Prop_Send, "m_bIsLive", true);
        SetEntProp(grenadeEnt, Prop_Send, "m_flDetonateTime", 0.1);*/
        
        //Set damage/AoE/elasticity
        SetEntPropFloat(grenadeEnt, Prop_Send, "m_flDamage", damage);
        SetEntPropFloat(grenadeEnt, Prop_Send, "m_DmgRadius", radius);
        SetEntPropFloat(grenadeEnt, Prop_Send, "m_flElasticity", 0.0);
        
        //Noblock
        SetEntProp(grenadeEnt, Prop_Send, "m_CollisionGroup", 2);
        
        DispatchSpawn(grenadeEnt);
        TeleportEntity(grenadeEnt, pos, NULL_VECTOR, NULL_VECTOR);
        
        //Stop the clock.
        SetEntProp(grenadeEnt, Prop_Data, "m_nNextThinkTick", -1);
    }
    
    return IsValidEntity(grenadeEnt) ? grenadeEnt : -1;
}
public DetonateGrenade(any:grenadeEnt)
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
public Action:BombPrimedMessage(Handle:timer, any:client)
{
    if (ValidPlayer(client))
    {
        PrintHintText(client, "Bomb has been primed");
    }
}


public OnUltimateCommand(client, race, bool:pressed)
{
    if (ValidPlayer(client, true) && race == thisRaceID && pressed)
    {
        new ult_rage = War3_GetSkillLevel(client, thisRaceID, ULT_RAGE);
        if (ult_rage > 0 && War3_SkillNotInCooldown(client, thisRaceID, ULT_RAGE, true) && !Silenced(client, true))
        {
            War3_CooldownMGR(client, fRageCooldown, thisRaceID, ULT_RAGE, true, true);
            
            War3_SetBuff(client, fDodgeChance, thisRaceID, fEvasion[ult_rage]);
            War3_SetBuff(client, bDodgeMode, thisRaceID, 0);
            War3_SetBuff(client, fMaxSpeed, thisRaceID, fSpeedIncrease[ult_rage]);
            
            EmitSoundToAll(OnRageSound, client);
            PrintHintText(client, "You fly in to a rage!");
            CreateTimer(fRageDuration, StopRage, client);
        }
    }
}
public Action:StopRage(Handle:timer, any:client)
{
    War3_SetBuff(client, fDodgeChance, thisRaceID, 0.0);
    War3_SetBuff(client, fMaxSpeed, thisRaceID, 1.0);
    
    PrintHintText(client, "Your rage ends");
}
public Round_End_Rage(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new i=0; i<MAXPLAYERS; i++)
    {
        if (hRageTimers[i] != INVALID_HANDLE)
        {
            TriggerTimer(hRageTimers[i]);
            hRageTimers[i] = INVALID_HANDLE;
        }
    }
}
public OnWar3EventDeath(victim, attacker)
{
    if (ValidPlayer(victim) && War3_GetRace(victim) == thisRaceID)
    {
        if (hRageTimers[victim] != INVALID_HANDLE)
        {
            TriggerTimer(hRageTimers[victim]);
            hRageTimers[victim] = INVALID_HANDLE;
        }
        
        if (hBombPrimeTimeTimers[victim] != INVALID_HANDLE)
        {
            KillTimer(hBombPrimeTimeTimers[victim]);
            hBombPrimeTimeTimers[victim] = INVALID_HANDLE;
        }
    }
    if (ValidPlayer(attacker, true) && War3_GetRace(attacker) == thisRaceID)
    {
        EmitSoundToAll(OnKillSound, attacker);
    }
}


//
// Helper functions
//
static InitRace(client)
{
    War3_WeaponRestrictTo(client, thisRaceID, "weapon_elite,weapon_knife,weapon_hegrenade,weapon_flashbang,weapon_smokegrenade");
    
    new skill_health = War3_GetSkillLevel(client, thisRaceID, SKILL_HEALTH);
    War3_SetBuff(client, iAdditionalMaxHealth, thisRaceID, iHealthIncrease[skill_health]);
    
    new skill_damage = War3_GetSkillLevel(client, thisRaceID, SKILL_DAMAGE);
    War3_SetBuff(client, fDamageModifier, thisRaceID, fDamageIncrease[skill_damage]);
    War3_SetBuff(client, iDamageMode, thisRaceID, 1);//guns only
}


static GiveWeapon(client)
{
    if (!Client_HasWeapon(client, "weapon_elite"))
    {
        Client_GiveWeapon(client, "weapon_elite", true);
    }
}


static bool:arrayCompare3(any:arr1[3], any:arr2[3])
{
    new bool:returnVal = true;
    for (new i=0; i<3; i++)//Should I be using < or <= ??? Can test by checking for overflow if using <=
    {
        if (arr1[i] != arr2[i])
        {
            returnVal = false;
        }
    }
    return returnVal;
}