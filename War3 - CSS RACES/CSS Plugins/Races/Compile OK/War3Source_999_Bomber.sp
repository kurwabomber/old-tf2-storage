////
//
// To-do list:
//
// - Optimise ring positions for 3/4/5/6/7 grenades, but keep math functions for others.
// - Make land mine drop a semi-transparent grenade which blows up if someone comes nearby.
//
// - Additional 5 second "global" cooldown for line/ring
// - Remove tele cooldown reset on line/ring use
//
////

#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/RemyFunctions"

#define PI 3.14159265359
#define TAU 6.28318530718


public Plugin:myinfo = 
{
    name = "War3Source Race - Bomber",
    author = "Custang (coded by Kibbles)",
    description = "Bomber race for War3Source",
    version = "1.1",
    url = "http://sevensinsgaming.com"
};


new thisRaceID;
new SKILL_REGEN, SKILL_DAMAGE, SKILL_STUN, SKILL_LINE, SKILL_JUMP, ULT_RING;

//SKILL_REGEN variables
new Float:fRegen[] = {2.0,3.0,4.0,5.0,6.0};

//SKILL_DAMAGE variables
new Float:fDamageMod[] = {0.3,0.35,0.4,0.45,0.5};

//SKILL_STUN variables
new Float:fStunChance[] = {0.2,0.3,0.4,0.5,0.6};
new Float:fStunDuration = 0.5;

//Total grenades per skill
new iLineNades[] = {2,4,6,8,10};
new iRingNades[] = {3,4,5,6,7};

//Grenade delays per skill
new iLineGrenadeDelay[] = {1,1,1,1,1};
new iJumpGrenadeDelay[] = {0,0,0,0,0};
new iRingGrenadeDelay[] = {1,1,2,2,2};

//Cooldowns per skill
new Float:fLineCooldown[] = {6.0,7.0,8.0,9.0,10.0};
new Float:fTeleportCooldown[] = {20.0,17.5,15.0,12.5,10.0};
new Float:fRingCooldown[] = {15.0,17.5,20.0,22.5,25.0};
new Float:fLineRingDualCooldown = 5.0;

//Max distance per skill
new Float:fLineNadesMaxDistance = 1000.0;
new Float:TeleportDistance=500.0;
new Float:fRingNadesMaxDistance[] = {50.0,75.0,100.0,125.0,150.0};

//Base damage per skill
new Float:fGrenadeThrowBaseDamage = 65.0;
new Float:fGrenadeLineBaseDamage = 20.0;
new Float:fGrenadeJumpBaseDamage = 50.0;
new Float:fGrenadeRingBaseDamage = 20.0;

//Extra SKILL_LINE variables
new Float:fGrenadeSpread = 100.0;

//Extra SKILL_JUMP variables
new String:teleportSound[256];
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};

//Extra ULT_RING variables
new Float:fRingNadeWaves = 3.0;
new Float:fRingTimeBetweenWaves = 1.0;
new Float:fRingWaveCounter[MAXPLAYERS+1];//Using datapacks to pass on (client,wave) would be neater, but they don't seem to work inside of Action functions.

//Extra misc variables
new bool:bSwitchToGivenGrenade[MAXPLAYERS+1];
new Float:fGrenadeRespawnTime = 2.0;//Respawn time if grenade is thrown.
new Float:fGrenadeDelayTime = 1.0;//Respawn time per point of GrenadeDelay.
new Float:fGrenadeDetonateDelay = 1.5;
new iClientGrenadeDelay[MAXPLAYERS+1];
new bool:bGrenadeHasBeenThrown[MAXPLAYERS+1];
new bool:bRoundStartTriggered[MAXPLAYERS+1];

//HUD style
new bool:bUseRemyHud[MAXPLAYERS+1];


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Bomber","bomber");
    
    SKILL_REGEN = War3_AddRaceSkill(thisRaceID, "Regeneration", "Regenerate health during combat.", false, 5);
    SKILL_DAMAGE = War3_AddRaceSkill(thisRaceID, "Explosive Expert", "Your grenades do extra damage.", false, 5);
    SKILL_STUN = War3_AddRaceSkill(thisRaceID, "Landmine", "Your grenades have a chance to stun.", false, 5);
    SKILL_LINE = War3_AddRaceSkill(thisRaceID, "Nade Hacks (ability)", "Drop a line of grenades in front of you (requires grenade).", false, 5);
    SKILL_JUMP = War3_AddRaceSkill(thisRaceID, "Tactical Jump (ability1)", "Drop a nade and teleport elsewhere.", false, 5);
    ULT_RING = War3_AddRaceSkill(thisRaceID, "Raining Nades (ultimate)", "Drop a cluster of grenades around you (requires grenade).", true, 5);
    
    W3SkillCooldownOnSpawn(thisRaceID, SKILL_LINE, 10.0, true);
    W3SkillCooldownOnSpawn(thisRaceID, SKILL_JUMP, 10.0, true);
    W3SkillCooldownOnSpawn(thisRaceID, ULT_RING, 10.0, true);
    
    War3_CreateRaceEnd(thisRaceID);
}


//
// Event handling
//

public OnPluginStart()
{
    RegConsoleCmd("sm_bomber_equip", Command_ToggleEquip, "Toggles grenade auto-equip on/off.");
    RegConsoleCmd("sm_bomber_hud", Command_ToggleHud, "Toggles grenade HUDinfo on/off.");
    
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
}


public OnMapStart()
{
    strcopy(teleportSound,sizeof(teleportSound),"war3source/blinkarrival.mp3");
    
    War3_AddCustomSound(teleportSound);
    
    for (new i=0;i<=MAXPLAYERS;i++)
    {
        resetGrenadeDelay(i);
        bSwitchToGivenGrenade[i] = true;
        bGrenadeHasBeenThrown[i] = false;
        bRoundStartTriggered[i] = false;
        bUseRemyHud[i] = true;
    }
    
    CreateTimer(1.0, HudInfo_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


public OnRaceChanged(client, oldrace, newrace)
{
    if(newrace == thisRaceID && ValidPlayer(client))
    {
        W3ResetAllBuffRace(client, thisRaceID);
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_hegrenade,weapon_c4");
        
        InitBuffs(client);
        resetGrenadeDelay(client);
        StartGiveSkillGrenadeTimer(client);
        
        CPrintToChat(client, "Type {green}!bomber_equip {default}to toggle auto-equip on/off for grenades.");
        CPrintToChat(client, "Type {green}!bomber_hud {default}to toggle info on/off for Remy's HUD.");
    }
    else if (oldrace == thisRaceID && ValidPlayer(client))
    {
        resetAllCooldowns(client);
        W3ResetAllBuffRace(client, thisRaceID);
        War3_WeaponRestrictTo(client,thisRaceID,"");
        HUD_Add(GetClientUserId(client), "");
    }
}


public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    if (race == thisRaceID && ValidPlayer(client, true))
    {
        InitBuffs(client);
    }
}


public OnWar3EventSpawn(client)
{
    new race = War3_GetRace(client);
    if(race == thisRaceID && ValidPlayer(client, true))
    {
        InitBuffs(client);
        resetAllCooldowns(client);
        resetGrenadeDelay(client);
        
        if (bRoundStartTriggered[client] == true)
        {
            StartGiveSkillGrenadeTimer(client);
        }
    }
}


public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=0; i<=MAXPLAYERS; i++)
    {
        if (ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID)
        {
            resetAllCooldowns(i);
            resetGrenadeDelay(i);
            
            StartGiveSkillGrenadeTimer(i);
            CreateTimer(0.5, roundStartTriggeredTimer, i);
        }
    }
}

public Action:roundStartTriggeredTimer(Handle:timer, any:client)
{
    bRoundStartTriggered[client] = true;
}


public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=0; i<=MAXPLAYERS; i++)
    {
        bRoundStartTriggered[i] = false;
    }
}


public OnWar3EventDeath(victim, attacker, deathrace)
{
    if (deathrace == thisRaceID && ValidPlayer(victim, true))
    {
        resetAllCooldowns(victim);
        resetGrenadeDelay(victim);
    }
}


public OnW3TakeDmgAllPre(victim, attacker, Float:damage)
{
    if (victim == attacker && War3_GetRace(victim) == thisRaceID && ValidPlayer(victim, true))
    {
        //Stop self-inflicted grenade damage.
        War3_DamageModPercent(0.0);
    }
}


public OnWeaponFired(client)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        new String:weapon[64];
        GetClientWeapon(client, weapon, sizeof(weapon));
        
        if (StrEqual(weapon,"weapon_hegrenade"))
        {
            bGrenadeHasBeenThrown[client] = true;
            CreateTimer((fGrenadeRespawnTime*0.99),resetGrenadeHasBeenThrownBool,client);
            
            StartGiveThrowGrenadeTimer(client);
            CreateTimer(0.2,setThrownGrenadeDamage,client);
        }
    }
}


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if (ValidPlayer(victim, true) && War3_GetRace(attacker) == thisRaceID && victim != attacker && GetClientTeam(attacker) != GetClientTeam(victim))
    {
        new bool:damageIsFromGrenade = (StrEqual(weapon,"weapon_hegrenade") || StrEqual(weapon,"hegrenade_projectile"));//I think damage only comes from hegrenade_projectile.
    
        //Additional grenade damage.
        new skill_damage = War3_GetSkillLevel(attacker, thisRaceID, SKILL_DAMAGE);
        if (skill_damage > 0 && damageIsFromGrenade)
        {
            new modifiedDamage = RoundToFloor(damage * fDamageMod[skill_damage-1]);
            War3_DealDamage(victim,modifiedDamage,attacker,DMG_GENERIC,"bombergrenade",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG);
        }
        
        new skill_stun = War3_GetSkillLevel(attacker, thisRaceID, SKILL_STUN);
        if (skill_stun > 0 && damageIsFromGrenade && !W3HasImmunity(attacker,Immunity_Skills))
        {
            //Only stun if damage is from a grenade.
            if (GetRandomFloat(0.0,1.0) <= fStunChance[skill_stun-1])
            {
                War3_SetBuff(victim, bBashed, thisRaceID, true);
                CreateTimer(fStunDuration,disableStun,victim);
            }
        }
    }
}


public OnAbilityCommand(client, ability, bool:pressed)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID && pressed)
    {
        if (ability == 0)
        {
            DoGrenadeAbility(client,SKILL_LINE);
        }
        else if (ability == 1)
        {
            DoGrenadeAbility(client, SKILL_JUMP);
        }
    }
}


public OnUltimateCommand(client, race, bool:pressed)
{
    if (ValidPlayer(client, true) && race == thisRaceID && pressed)
    {
        DoGrenadeAbility(client, ULT_RING);
    }
}


public Action:Command_ToggleEquip(client, args)
{
    if (War3_GetRace(client) == thisRaceID)
        {
        if (bSwitchToGivenGrenade[client])
        {
            bSwitchToGivenGrenade[client] = false;
            PrintHintText(client, "Auto-equip has been disabled.");
        }
        else
        {
            bSwitchToGivenGrenade[client] = true;
            PrintHintText(client, "Auto-equip has been enabled.");
        }
    }
    
    return Plugin_Handled;
}


public Action:Command_ToggleHud(client, args)
{
    if (War3_GetRace(client) == thisRaceID)
        if (bUseRemyHud[client])
        {
            bUseRemyHud[client] = false;
            PrintHintText(client, "HUD information has been disabled.");
            HUD_Add(GetClientUserId(client), "");
        }
        else
        {
            bUseRemyHud[client] = true;
            PrintHintText(client, "HUD information has been enabled.");
        }
    
    return Plugin_Handled;
}


//
// Buff/Cooldown functions
//

public InitBuffs(client)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        W3ResetAllBuffRace( client, thisRaceID );
    
        new skill_regen = War3_GetSkillLevel(client, thisRaceID, SKILL_REGEN);
        if (skill_regen > 0)
        {
            War3_SetBuff(client, fHPRegen, thisRaceID, fRegen[skill_regen-1]);
        }
        
        /*new skill_stun = War3_GetSkillLevel(client, thisRaceID, SKILL_STUN);
        if (skill_stun > 0)
        {
            War3_SetBuff(client, fBashChance, thisRaceID, fStunChance[skill_stun-1]);
            War3_SetBuff(client, fBashDuration, thisRaceID, fStunDuration);
        }*///Bash is now handled in PostHurt to avoid knife bashing.
    }
}


public Action:disableStun(Handle:timer,any:client)
{
    War3_SetBuff(client, bBashed, thisRaceID, false);
}


public resetAllCooldowns(any:client)
{
    new race = War3_GetRace(client);
    if (race == thisRaceID)
    {
        War3_CooldownReset(client, race, SKILL_JUMP);
        War3_CooldownReset(client, race, SKILL_LINE);
        War3_CooldownReset(client, race, ULT_RING);
    }
}


//
// Grenade functions
//

public DoGrenadeAbility(any:client, skill)
{
    new race = War3_GetRace(client);
    new hasGrenade = Client_HasWeapon(client, "weapon_hegrenade");
    new bool:isThrownNadeInAir = isThrownGrenadeInAir(client);
    
    if (ValidPlayer(client, true) && race == thisRaceID)
    {
        new skillLevel = War3_GetSkillLevel(client, race, skill);
        
        if (skillLevel > 0)
        {
            if (skill == SKILL_LINE && hasGrenade && !isThrownNadeInAir && War3_SkillNotInCooldown(client,race,SKILL_LINE,true))
            {
                //War3_CooldownReset(client, race, SKILL_JUMP);
                DropGrenadeLine(client);
            }
            else if (skill == SKILL_JUMP && War3_SkillNotInCooldown(client,race,SKILL_JUMP,true))
            {
                TeleportPlayerView(client, TeleportDistance);
            }
            else if (skill == ULT_RING && hasGrenade && !isThrownNadeInAir && War3_SkillNotInCooldown(client,race,ULT_RING,true))
            {
                War3_CooldownReset(client, race, SKILL_JUMP);
                DropGrenadeRing(client);
            }
            else
            {
                W3Hint(client, HINT_COOLDOWN_NOTREADY, 1.0, "You need a grenade to use this ability.");
            }
        }
    }
}


public StartGiveThrowGrenadeTimer(any:client)
{
    CreateTimer(fGrenadeRespawnTime,giveGrenade,client);
}


public StartGiveSkillGrenadeTimer(any:client)
{
    CreateTimer(fGrenadeDelayTime,giveGrenade,client);
}


public Action:resetGrenadeHasBeenThrownBool(Handle:timer,any:client)
{
    bGrenadeHasBeenThrown[client] = false;
}


public Action:giveGrenade(Handle:timer,any:client)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        if (getGrenadeDelay(client) > 0)
        {
            printGrenadeDelay(client);
            decrementGrenadeDelay(client);
            StartGiveSkillGrenadeTimer(client);
        }
        else
        {
            /*Use one of these methods. For some reason Client_GiveWeapon does not trigger an ItemPickup event.*/
            //GivePlayerItem(client, "weapon_hegrenade");
            if (!Client_HasWeapon(client, "weapon_hegrenade"))
            {
                Client_GiveWeapon(client, "weapon_hegrenade", bSwitchToGivenGrenade[client]);
            }
        }
    }
}


public removeGrenade(any:client)
{
    Client_ChangeWeapon(client, "weapon_knife");
    Client_RemoveWeapon(client, "weapon_hegrenade");
}


public Action:setThrownGrenadeDamage(Handle:timer, any:client)
{
    new ent = findThrownGrenadeEnt(client);
    
    if (ent != -1)
    {
        SetEntPropFloat(ent, Prop_Send, "m_flDamage", fGrenadeThrowBaseDamage);
    }
}


public bool:isThrownGrenadeInAir(any:client)
{
    new ent = findThrownGrenadeEnt(client);
    
    if (ent != -1 && bGrenadeHasBeenThrown[client])
    {
        return true;
    }
    
    return false;
}


public dropGrenade(any:client, Float:pos[3], Float:damage)
{
    //Code taken and adapted from AlliedMods posts by BrianGriffin and thetwistedpanda.
    new grenadeEnt = CreateEntityByName("hegrenade_projectile");
    
    if (IsValidEntity(grenadeEnt) && !arrayCompare3(pos,NULL_VECTOR))
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
        SetEntPropFloat(grenadeEnt, Prop_Send, "m_DmgRadius", 350.0);
        SetEntPropFloat(grenadeEnt, Prop_Send, "m_flElasticity", 0.0);
        
        //Noblock
        SetEntProp(grenadeEnt, Prop_Send, "m_CollisionGroup", 2);
        
        DispatchSpawn(grenadeEnt);
        TeleportEntity(grenadeEnt, pos, NULL_VECTOR, NULL_VECTOR);
        
        //Stop the clock.
        SetEntProp(grenadeEnt, Prop_Data, "m_nNextThinkTick", -1);
        
        //Detonate the grenade.
        CreateTimer(fGrenadeDetonateDelay,detonateGrenade,grenadeEnt);
    }
}


public Action:detonateGrenade(Handle:timer, any:grenadeEnt)
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


public DropGrenadeLine(client)
{
    if (War3_GetRace(client) == thisRaceID && ValidPlayer(client, true))
    {
        new Float:clientPos[3];
        GetClientAbsOrigin(client, clientPos);
    
        if(enemySkillImmunityInRange(client,clientPos))
        {
            W3MsgEnemyHasImmunity(client);
            return -1;
        }
    
        dropGrenadeLine(client);
        
        removeGrenade(client);
        incrementGrenadeDelay(client, SKILL_LINE);
        StartGiveSkillGrenadeTimer(client);
        
        new skill_line = War3_GetSkillLevel(client, thisRaceID, SKILL_LINE);
        War3_CooldownMGR(client,fLineCooldown[skill_line-1],thisRaceID,SKILL_LINE);
        if (War3_CooldownRemaining(client, thisRaceID, ULT_RING) < fLineRingDualCooldown)
        {
            War3_CooldownMGR(client,fLineRingDualCooldown,thisRaceID,ULT_RING);
        }
    }
    
    return 0;
}


public bool:dropGrenadeLine(client)
{
    if(ValidPlayer(client)){
        if(IsPlayerAlive(client)){
            new Float:angle[3];
            GetClientEyeAngles(client,angle);
            new Float:endpos[3];
            new Float:startpos[3];
            GetClientEyePosition(client,startpos);
            new Float:dir[3];
            GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
            //Addition for line nade code
            new Float:grenadeDir[3];
            grenadeDir[0] = dir[0];
            grenadeDir[1] = dir[1];
            grenadeDir[2] = dir[2];
            //End addition
            ScaleVector(dir, fLineNadesMaxDistance);
            AddVectors(startpos, dir, endpos);
            ClientTracer=client;
            TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetPlayerFilter);
            TR_GetEndPosition(endpos);
            
            //Line nade code
            new skill_line = War3_GetSkillLevel(client, thisRaceID, SKILL_LINE);
            
            new Float:totalDistance = GetVectorDistance(startpos,endpos);
            
            ScaleVector(grenadeDir, fGrenadeSpread);
            AddVectors(startpos, grenadeDir, endpos);
            
            new grenadeCount = 0;
            new Float:cumulativeDistance = fGrenadeSpread;
            
            while (cumulativeDistance <= totalDistance && grenadeCount < iLineNades[skill_line-1])
            {
                dropGrenade(client, endpos, fGrenadeLineBaseDamage);
                
                AddVectors(endpos, grenadeDir, endpos);
                
                cumulativeDistance += fGrenadeSpread;
                grenadeCount++;
            }
            
            if (cumulativeDistance < fLineNadesMaxDistance)
            {
                SubtractVectors(endpos, grenadeDir, endpos);
            
                /*The compiler will complain that this for loop has no effect. The compiler lies.*/
                /*for (grenadeCount; grenadeCount < iLineNades[skill_line-1]; grenadeCount++)
                {
                    //endpos[2] += 1.0;
                    dropGrenade(client, endpos, fGrenadeLineBaseDamage);
                }*/
                
                //The above is commented out because spawning all the extra grenades will lead to abuse (aim at the floor, spawn all 10 in one spot).
                dropGrenade(client, endpos, fGrenadeLineBaseDamage);
            }
            
            return true;
        }
    }
    return false;
}


public bool:AimTargetPlayerFilter(entity,mask)
{
    new bool:returnValue = true;
    
    for (new i=1;i<=MAXPLAYERS;i++)
    {
        if (ValidPlayer(entity, true) || entity == ClientTracer)
        {
            returnValue = false;
        }
    }
    
    return returnValue;
}


public DropGrenadeRing(any:client)
{
    if (War3_GetRace(client) == thisRaceID && ValidPlayer(client, true))
    {
        new Float:clientPos[3];
        GetClientAbsOrigin(client, clientPos);
    
        if(enemyUltImmunityInRange(client,clientPos))
        {
            W3MsgEnemyHasImmunity(client);
            return -1;
        }
    
        new Float:time = 0.1;
        fRingWaveCounter[client] = 0.0;

        for (new Float:i=0.0; i<fRingNadeWaves; i++)
        {
            CreateTimer(time,dropGrenadeRing,client);
            time += fRingTimeBetweenWaves;
        }
        
        removeGrenade(client);
        incrementGrenadeDelay(client, ULT_RING);
        StartGiveSkillGrenadeTimer(client);
        
        new ult_ring = War3_GetSkillLevel(client, thisRaceID, ULT_RING);
        War3_CooldownMGR(client,fRingCooldown[ult_ring-1],thisRaceID,ULT_RING);
        if (War3_CooldownRemaining(client, thisRaceID, SKILL_LINE) < fLineRingDualCooldown)
        {
        War3_CooldownMGR(client,fLineRingDualCooldown,thisRaceID,SKILL_LINE);
        }
    }
    
    return 0;
}


public Action:dropGrenadeRing(Handle:timer, any:client)
{
    if(ValidPlayer(client))
    {
        if(IsPlayerAlive(client))
        {
            new ult_ring = War3_GetSkillLevel(client, thisRaceID, ULT_RING);
            new Float:maxDistance = fRingNadesMaxDistance[ult_ring-1];
            
            new Float:angle[3];
            GetClientEyeAngles(client,angle);
            new Float:endpos[3];
            new Float:startpos[3];
            GetClientEyePosition(client,startpos);
            new Float:dir[3];
            GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
            ScaleVector(dir, maxDistance);
            AddVectors(startpos, dir, endpos);
            
            //Ring nade code
            fRingWaveCounter[client]++;
            new totalGrenades = iRingNades[ult_ring-1];
            new Float:wave = fRingWaveCounter[client];
            
            //
            // RANDOM POSITIONS METHOD
            //
            /*for (new i=0; i<totalGrenades; i++)
            {
                new Float:vectorX = GetRandomFloat(-1.0,1.0);
                new Float:vectorY = GetRandomFloat(-1.0,1.0);
                
                new Float:vec[3];
                vec[0] = vectorX;
                vec[1] = vectorY;
                vec[2] = 0.0;
                NormalizeVector(vec, vec);
                
                ScaleVector(vec, fRingWaveCounter[client]*fRingNadesMaxDistance[ult_ring-1]);
                
                new Float:nadePos[3];
                AddVectors(startpos, vec, nadePos);
                
                ClientTracer=client;
                TR_TraceRayFilter(startpos,nadePos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
                TR_GetEndPosition(nadePos); 

                ScaleVector(nadePos,0.98);//This should stop grenades getting stuck in walls.
                
                dropGrenade(client, nadePos, fGrenadeRingBaseDamage);
            }*/
            
            //
            // DISTRIBUTED POSITIONS METHOD
            //
            new Float:baseAngle = 2.0*PI/totalGrenades;
            new Float:baseVector[3];
            baseVector[2] = 0.0;
            new Float:finalVector[3];
            
            AddVectors(dir,NULL_VECTOR,baseVector);
            
            for (new i=0; i<totalGrenades; i++)
            {
                new Float:currentAngle = sanitizeAngle(baseAngle*i);
                
                baseVector[0] = convertPolarToX(maxDistance*wave,currentAngle);
                baseVector[1] = convertPolarToY(maxDistance*wave,currentAngle);
                
                AddVectors(startpos,baseVector,finalVector);
                
                ClientTracer=client;
                TR_TraceRayFilter(startpos,finalVector,MASK_ALL,RayType_EndPoint,AimTargetFilter);
                TR_GetEndPosition(finalVector);
                
                ScaleVector(finalVector,0.98);//This should stop grenades getting stuck in walls.
                
                dropGrenade(client, finalVector, fGrenadeRingBaseDamage);
            }
        }
    }
}


public findThrownGrenadeEnt(any:client)
{
    //Code for finding grenade projectiles courtesy of pRED*'s SteerNades plugin.
    new ent = -1;
    new lastent;
    new owner;
    
    ent = FindEntityByClassname(ent, "hegrenade_projectile");
    
    while (ent != -1)
    {
        owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
        
        if (IsValidEntity(ent) && owner == client && War3_GetRace(client) == thisRaceID)
        {
            break;
        }
        
        ent = FindEntityByClassname(ent, "hegrenade_projectile");
        
        if (ent == lastent)
        {
            ent = -1;
            break;
        }
        
        lastent = ent;
    }
    
    return ent;
}


//Teleport code taken from Remy Lebeau's GamblingMan race.
public bool:TeleportPlayerView(client,Float:distance)
{
    if(ValidPlayer(client)){
        if(IsPlayerAlive(client)){
            new Float:angle[3];
            GetClientEyeAngles(client,angle);
            new Float:endpos[3];
            new Float:startpos[3];
            GetClientEyePosition(client,startpos);
            new Float:dir[3];
            GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
            ScaleVector(dir, distance);
            AddVectors(startpos, dir, endpos);
            GetClientAbsOrigin(client,oldpos[client]);
            ClientTracer=client;
            TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
            TR_GetEndPosition(endpos);            
            
            if(enemySkillImmunityInRange(client,endpos)){
                W3MsgEnemyHasImmunity(client);
                return false;
            }
            
            new skill_jump = War3_GetSkillLevel(client, thisRaceID, SKILL_JUMP);
            War3_CooldownMGR(client,fTeleportCooldown[skill_jump-1],thisRaceID,SKILL_JUMP);
            
            distance=GetVectorDistance(startpos,endpos);
            GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
            ScaleVector(dir, distance-33.0);
            AddVectors(startpos,dir,endpos);
            emptypos[0]=0.0;
            emptypos[1]=0.0;
            emptypos[2]=0.0;
            endpos[2]-=30.0;
            getEmptyLocationHull(client,endpos);
            if(GetVectorLength(emptypos)<1.0){
                //new String:buffer[100];
                //Format(buffer, sizeof(buffer), "%T", "NoEmptyLocation", client);
                PrintHintText(client, "No Empty Location");
                return false;
            }
            TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
            EmitSoundToAll(teleportSound,client);    
            teleportpos[client][0]=emptypos[0];
            teleportpos[client][1]=emptypos[1];
            teleportpos[client][2]=emptypos[2];
            inteleportcheck[client]=true;
            CreateTimer(0.14,checkTeleport,client);
            
            return true;
        }
    }
    return false;
}

public Action:checkTeleport(Handle:h,any:client){
    inteleportcheck[client]=false;
    new Float:pos[3];    
    GetClientAbsOrigin(client,pos);
    
    if(GetVectorDistance(teleportpos[client],pos)<0.001){
        TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
        War3_CooldownReset(client, War3_GetRace(client), SKILL_JUMP);
    }
    else
    {    
        dropGrenade(client, oldpos[client], fGrenadeJumpBaseDamage);
        //removeGrenade(client);
        incrementGrenadeDelay(client, SKILL_JUMP);
        //StartGiveSkillGrenadeTimer(client);
    }
}

public bool:AimTargetFilter(entity,mask)
{
    return !(entity==ClientTracer);
}

public bool:getEmptyLocationHull(client,Float:originalpos[3]){
    new Float:mins[3];
    new Float:maxs[3];
    GetClientMins(client,mins);
    GetClientMaxs(client,maxs);
    new absincarraysize=sizeof(absincarray);
    new limit=5000;
    for(new x=0;x<absincarraysize;x++){
        if(limit>0){
            for(new y=0;y<=x;y++){
                if(limit>0){
                    for(new z=0;z<=y;z++){
                        new Float:pos[3]={0.0,0.0,0.0};
                        AddVectors(pos,originalpos,pos);
                        pos[0]+=float(absincarray[x]);
                        pos[1]+=float(absincarray[y]);
                        pos[2]+=float(absincarray[z]);
                        
                        TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
                        if(TR_DidHit(_)){
                        }
                        else
                        {
                            AddVectors(emptypos,pos,emptypos);
                            limit=-1;
                            break;
                        }
                    
                        if(limit--<0){
                            break;
                        }
                    }
                    
                    if(limit--<0){
                        break;
                    }
                }
            }
            
            if(limit--<0){
                break;
            }
            
        }
        
    }

} 

public bool:CanHitThis(entityhit, mask, any:data)
{
    if(entityhit == data ){
        return false;
    }
    if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
        return false;
    }
    return true;
}


public bool:enemySkillImmunityInRange(client,Float:playerVec[3])
{
    new Float:otherVec[3];
    new team = GetClientTeam(client);

    for(new i=1;i<=MaxClients;i++){
        if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Skills)){
            GetClientAbsOrigin(i,otherVec);
            if(GetVectorDistance(playerVec,otherVec)<300){
                return true;
            }
        }
    }
    return false;
}


public bool:enemyUltImmunityInRange(client,Float:playerVec[3])
{
    new Float:otherVec[3];
    new team = GetClientTeam(client);

    for(new i=1;i<=MaxClients;i++){
        if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates)){
            GetClientAbsOrigin(i,otherVec);
            if(GetVectorDistance(playerVec,otherVec)<300){
                return true;
            }
        }
    }
    return false;
}


//
// Helper functions
//

public Action:HudInfo_Timer(Handle:timer, any:client)
{
    if (bUseRemyHud[client])
    {
        for( new i = 1; i <= MaxClients; i++ )
        {
            if(ValidPlayer(i,true) && !IsFakeClient(i))
            {
                if(War3_GetRace(i) == thisRaceID)  
                {
                    new String:HUD_Buffer[200];
                    new String:buffer[50];
                    
                    new lineCD = War3_CooldownRemaining(i,thisRaceID,SKILL_LINE);
                    new jumpCD = War3_CooldownRemaining(i,thisRaceID,SKILL_JUMP);
                    new ringCD = War3_CooldownRemaining(i,thisRaceID,ULT_RING);
                    
                    Format(buffer, sizeof(buffer), "\nNext Grenade : %i", getGrenadeDelay(i));
                    StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
                    
                    new skill_line = War3_GetSkillLevel(i,thisRaceID,SKILL_LINE);
                    if (skill_line > 0)
                    {
                        if (lineCD == 0)
                        {
                            Format(buffer, sizeof(buffer), "\nLine : Ready");
                        }
                        else
                        {
                            Format(buffer, sizeof(buffer), "\nLine : %i", lineCD);
                        }
                        StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
                    }
                    
                    new skill_jump = War3_GetSkillLevel(i,thisRaceID,SKILL_JUMP);
                    if (skill_jump > 0)
                    {
                        if (jumpCD == 0)
                        {
                            Format(buffer, sizeof(buffer), "\nTele : Ready");
                        }
                        else
                        {
                            Format(buffer, sizeof(buffer), "\nTele : %i", jumpCD);
                        }
                        StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
                    }
                    
                    new ult_ring = War3_GetSkillLevel(i,thisRaceID,ULT_RING);
                    if (ult_ring > 0)
                    {
                        if (ringCD == 0)
                        {
                            Format(buffer, sizeof(buffer), "\nRing : Ready");
                        }
                        else
                        {
                            Format(buffer, sizeof(buffer), "\nRing : %i", ringCD);
                        }
                        StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
                    }
                    
                    HUD_Add(GetClientUserId(i), HUD_Buffer);
                }
            }
        }
    }
}


public printGrenadeDelay(any:client)
{
    new grenadeDelay = RoundToFloor(iClientGrenadeDelay[client]*fGrenadeDelayTime);
    W3Hint(client, HINT_COOLDOWN_COUNTDOWN, 1.0, "%i seconds until next grenade.", grenadeDelay);
}


public getGrenadeDelay(any:client)
{
    return iClientGrenadeDelay[client];
}


public incrementGrenadeDelay(any:client,any:skill)
{
    new increment;
    
    new skillLevel = War3_GetSkillLevel(client, thisRaceID, skill);
    
    if (skill == SKILL_LINE)
    {
        increment = iLineGrenadeDelay[skillLevel-1];
    }
    else if (skill == SKILL_JUMP)
    {
        increment = iJumpGrenadeDelay[skillLevel-1];
    }
    else if (skill == ULT_RING)
    {
        increment = iRingGrenadeDelay[skillLevel-1];
    }
    
    iClientGrenadeDelay[client] += increment;
}


public decrementGrenadeDelay(any:client)
{
    iClientGrenadeDelay[client]--;
}


public resetGrenadeDelay(any:client)
{
    iClientGrenadeDelay[client] = 0;
}


public bool:arrayCompare3(any:arr1[3],any:arr2[3])
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


//
// Math functions
//

public Float:sanitizeAngle(Float:angle)
{
    new Float:returnValue = angle;
    
    while (returnValue > TAU)
    {
        //I know there's a modulo operator. It didn't work with floats when this was coded.
        returnValue -= TAU;
    }
    
    if (returnValue > PI)
    {
        returnValue = (TAU - angle)*-1;
    }
    
    return returnValue;
}


public Float:convertPolarToX(Float:radius,Float:angle)
{
    return radius*taylorCosine(angle);
}


public Float:convertPolarToY(Float:radius,Float:angle)
{
    return radius*taylorSine(angle);
}


public Float:taylorCosine(Float:angle)
{
    return (1.0 - Pow(angle,2.0)/2.0 + Pow(angle,4.0)/factorial(4.0) - Pow(angle,6.0)/factorial(6.0)) + Pow(angle,8.0)/factorial(8.0);
}


public Float:taylorSine(Float:angle)
{
    return (angle - Pow(angle,3.0)/factorial(3.0) + Pow(angle,5.0)/factorial(5.0) - Pow(angle,7.0)/factorial(7.0)) + Pow(angle,9.0)/factorial(9.0);
}


public Float:factorial(Float:n)
{
    if (n < 0.0)
    {
        return -1.0;
    }
    else if (n == 0.0)
    {
        return 1.0;
    }
    else
    {
        return n*factorial(n-1.0);
    }
}