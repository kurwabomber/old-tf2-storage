#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

//
//
// - 2 second menu
//
//


public Plugin:myinfo = 
{
    name = "War3Source Race - Medic",
    author = "Siegfried (coded by Kibbles)",
    description = "Medic race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new thisRaceID;
new SKILL_HEALWAVE, SKILL_HEALLINE, SKILL_OVERCHARGE, ULT_HOSPITAL;

new Float:fHealwaveMaxDistance[] = {0.0, 100.0, 150.0, 200.0, 250.0};
new Float:fHeallineMaxDistance[] = {0.0, 500.0, 750.0, 1000.0, 1250.0};
new Float:fOverchargeMaxDistance[] = {0.0, 250.0, 500.0, 750.0, 1000.0};
new Float:fOverchargeSeparationFactor = 1.5;
new Float:fHospitalMaxDistance[] = {0.0, 100.0, 150.0, 200.0, 250.0};

//new Float:fHealwaveCooldown[] = {0.0, 12.0, 10.0, 8.0, 6.0};
new Float:fHeallineCooldown[] = {0.0, 10.0, 10.0, 10.0, 10.0};
new Float:fOverchargeCooldown[] = {0.0, 20.0, 20.0, 20.0, 20.0};
new Float:fHospitalCooldown[] = {0.0, 40.0, 30.0, 20.0, 10.0};

//Healwave
new iHealwaveMaxWaves[] = {0, 4, 4, 4, 4};
//new iHealwaveHealHP[] = {0, 5, 10, 15, 20};
new iHealwaveHealHP[] = {0, 1, 2, 3, 4};
new Float:fHealwaveTimerRepeat = 1.0;

//Healline
new iHeallineHealHP[] = {0, 25, 30, 35, 40};
new Float:fMarkTimerRepeat = 0.25;

//Overcharge
new Float:fOverchargeDuration[] = {0.0, 10.0, 10.0, 10.0, 10.0};
new Float:fOverchargeDamageMod[] = {0.0, 0.05, 0.1, 0.15, 0.2};
new MedicInOvercharge[MAXPLAYERS+1] = {-1, ...};
new AllyInOvercharge[MAXPLAYERS+1] = {-1, ...};
new Float:fOverchargeTimerRepeat = 0.1;

//Hospital
new iHospitalMaxHealHP = 150;
new Float:fSpawnLocationT[3];
new Float:fSpawnLocationCT[3];
new bool:bTLocationSet;
new bool:bCTLocationSet;
new iHospitalTeleMenuLife = 5;

new ClientTracer, HealSprite, BeamSprite, HaloSprite;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Medic","medic");
    
    SKILL_HEALWAVE = War3_AddRaceSkill(thisRaceID, "Healing Wave (passive)", "Heal up to 3 nearby allies for 1/2/3/4 hp every second.", false, 4);
    SKILL_HEALLINE = War3_AddRaceSkill(thisRaceID, "Bandages (ability)", "Heal a nearby visible ally for 25/30/35/40 hp.", false, 4);
    SKILL_OVERCHARGE = War3_AddRaceSkill(thisRaceID, "Overcharge (ability1)", "Increase a nearby ally's damage by 5/10/15/20% for 10 seconds, and run as fast as them.", false, 4);
    ULT_HOSPITAL = War3_AddRaceSkill(thisRaceID, "Hospital (ultimate)", "Heal an ally up to 150hp and offer to send them home.", true, 4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    W3SkillCooldownOnSpawn(thisRaceID, SKILL_HEALWAVE, 15.0, true);
    W3SkillCooldownOnSpawn(thisRaceID, SKILL_HEALLINE, 15.0, true);
    W3SkillCooldownOnSpawn(thisRaceID, SKILL_OVERCHARGE, 5.0, true);
    W3SkillCooldownOnSpawn(thisRaceID, ULT_HOSPITAL, 15.0, true);
}


public OnPluginStart()
{
    CreateTimer(fOverchargeTimerRepeat, OverchargeTimer, _, TIMER_REPEAT);
    CreateTimer(fMarkTimerRepeat, HealMarkTimer, _, TIMER_REPEAT);
    HookEvent("round_start", Round_Start, EventHookMode_Pre);
}


public OnMapStart()
{
    HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
    BeamSprite = PrecacheModel("materials/sprites/lgtning.vmt");
    HealSprite = PrecacheModel("materials/sprites/hydraspinalcord.vmt");
    
    CreateTimer(fHealwaveTimerRepeat, HealwaveTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


public OnRaceChanged(client, oldrace, newrace)
{
    if(newrace == thisRaceID && ValidPlayer(client))
    {
        InitRound(client);
    }
    else if (oldrace == thisRaceID && ValidPlayer(client))
    {
        //Reset buffs/restrictions if player is changing from this race.
        W3ResetAllBuffRace(client, thisRaceID);
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}


public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
    //Do something
}


public Round_Start(Handle:event,const String:name[],bool:dontBroadcast)
{
    bTLocationSet = false;
    bCTLocationSet = false;
}


public OnWar3EventSpawn(client)
{
    new race = War3_GetRace(client);
    if( race == thisRaceID && ValidPlayer(client, true))
    {
        InitRound(client);
    }
}


public OnWar3EventDeath(victim, attacker)
{
    if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim) && attacker!=victim)
    {
        //Do something if attacker is the client.
    }
    
    if (ValidPlayer(attacker) && ValidPlayer(victim) && War3_GetRace(victim) == thisRaceID)
    {
        //Do something if victim is the client.
    }
}


//
// Skill Events
//

public OnAbilityCommand(client, ability, bool:pressed)
{
    if(ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID && pressed && !Silenced(client))
    {
        /*if(ability == 0 && War3_SkillNotInCooldown(client,thisRaceID,SKILL_HEALWAVE,true))
        {
            new skill_healwave = War3_GetSkillLevel(client, thisRaceID, SKILL_HEALWAVE);
            if (skill_healwave > 0)
            {
                new bool:foundTarget = DoWave(client, fHealwaveMaxDistance[skill_healwave], iHealwaveMaxWaves[skill_healwave]);
                if (foundTarget)
                {
                    War3_CooldownMGR(client, fHealwaveCooldown[skill_healwave], thisRaceID, SKILL_HEALWAVE, true, true);
                }
            }
        }*/
        if (ability == 0 && War3_SkillNotInCooldown(client,thisRaceID,SKILL_HEALLINE,true))
        {
            new skill_healline = War3_GetSkillLevel(client, thisRaceID, SKILL_HEALLINE);
            if (skill_healline > 0)
            {
                new bool:foundTarget = DoLine(client, fHeallineMaxDistance[skill_healline]);
                if (foundTarget)
                {
                    War3_CooldownMGR(client, fHeallineCooldown[skill_healline], thisRaceID, SKILL_HEALLINE, true, true);
                }
            }
        }
        else if (ability == 1 && War3_SkillNotInCooldown(client,thisRaceID,SKILL_OVERCHARGE,true))
        {
            new skill_overcharge = War3_GetSkillLevel(client, thisRaceID, SKILL_OVERCHARGE);
            if (skill_overcharge > 0)
            {
                new bool:foundTarget = DoOvercharge(client, fOverchargeMaxDistance[skill_overcharge]);
                if (foundTarget)
                {
                    War3_CooldownMGR(client, fOverchargeCooldown[skill_overcharge], thisRaceID, SKILL_OVERCHARGE, true, true);
                }
            }
        }
        else
        {
            //
        }
    }
}


public OnUltimateCommand(client, race, bool:pressed)
{
    if(ValidPlayer(client, true) && race == thisRaceID && pressed && !Silenced(client))
    {
        new ult_hospital = War3_GetSkillLevel(client, race, ULT_HOSPITAL);
        if (ult_hospital > 0 && War3_SkillNotInCooldown(client,thisRaceID,ULT_HOSPITAL,true))
        {
            new bool:foundTarget = DoHospital(client, fHospitalMaxDistance[ult_hospital]);
            if (foundTarget)
            {
                War3_CooldownMGR(client, fHospitalCooldown[ult_hospital], race, ULT_HOSPITAL, true, true);
            }
        }
    }
}


//
// Skill functions
//

public bool:DoHospital(any:client, Float:maxDistance)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        new ult_hospital = War3_GetSkillLevel(client, thisRaceID, ULT_HOSPITAL);
        if (ult_hospital > 0)
        {
            new target = GetAllyInCrosshair(client, maxDistance);
            
            if (ValidPlayer(target, true) && !IsUltImmune(target) && GetClientTeam(client) == GetClientTeam(target))// && ValidHospitalHealth(target))
            {
                /*new Float:teleportLocation[3];
                if (GetClientTeam(target) == TEAM_T)
                {
                    AddVectors(NULL_VECTOR,fSpawnLocationT,teleportLocation);
                }
                else if (GetClientTeam(target) == TEAM_CT)
                {
                    AddVectors(NULL_VECTOR,fSpawnLocationCT,teleportLocation);
                }
                else
                {
                    //
                }
                
                TeleportEntity(target,teleportLocation,NULL_VECTOR,NULL_VECTOR);*/
                
                DoHospitalMenu(target);
                
                new targetHP = GetClientHealth(target);
                new targetHealHP = iHospitalMaxHealHP;
                if (targetHP <= targetHealHP)
                {
                    targetHealHP -= targetHP;
                }
                else if (targetHP > targetHealHP)
                {
                    targetHealHP = 0;
                }
                War3_HealToMaxHP(target,targetHealHP);
                
                new Float:HealerPos[3];
                new Float:TargetPos[3];
                
                GetClientAbsOrigin(client, HealerPos);
                HealerPos[2] += 40.0;
                GetClientAbsOrigin(target, TargetPos);
                TargetPos[2] += 40.0;
                    
                TE_SetupBeamPoints(HealerPos, TargetPos, HealSprite, HaloSprite, 0, 0, 0.5, 10.0, 10.0, 0, 0.0, {255, 255, 255, 200}, 0);
                TE_SendToAll();
                
                W3FlashScreen(target, RGBA_COLOR_WHITE);

                PrintHintText(client, "Trying to send %N to Hospital", target);
                return true;
            }
        }
    }
    
    return false;
}

public Action:HealMarkTimer(Handle:timer)
{
    new Float:targetPos[3];
    new Float:medicPos[3];
    
    for (new i=1; i<=MAXPLAYERS; i++)
    {
        if (ValidPlayer(i, true) && GetClientHealth(i) < War3_GetMaxHP(i))
        {
            GetClientAbsOrigin(i, targetPos);
            
            for (new j=1; j<=MAXPLAYERS; j++)
            {
                if (i != j && ValidPlayer(j, true) && War3_GetRace(j) == thisRaceID)
                {
                    if (GetClientTeam(i) == GetClientTeam(j))
                    {
                        GetClientAbsOrigin(j, medicPos);
                        new skill_healline = War3_GetSkillLevel(j, thisRaceID, SKILL_HEALLINE);
                        
                        if (GetVectorDistance(targetPos, medicPos) <= fHeallineMaxDistance[skill_healline])
                        {
                            //TE_SetupBeamRing(i,j,BeamSprite,HaloSprite,0,15,fMarkTimerRepeat,20.0,3.0,{50, 255, 50, 255},20,0);
                            TE_SetupBeamFollow(i, BeamSprite, HaloSprite, (fMarkTimerRepeat+0.1), 4.0, 1.0, RoundToFloor(fMarkTimerRepeat), {50, 255, 50, 255});
                            TE_SendToClient(j);
                            W3Hint(j, _, fMarkTimerRepeat, "Heal people with a Green trail!");
                        }
                    }
                }
            }
        }
    }
}


public bool:DoOvercharge(any:client, Float:maxDistance)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        new skill_overcharge = War3_GetSkillLevel(client, thisRaceID, SKILL_OVERCHARGE);
        if (skill_overcharge > 0)
        {
            //Check to see if an ally is close enough.
            new target = GetAllyInCrosshair(client, maxDistance);
            
            //If no ally detected or ally has skill immunity, return false.
            if (!ValidPlayer(target, true) || IsSkillImmune(target) || GetClientTeam(client) != GetClientTeam(target))
            {
                return false;
            }
            
            AllyInOvercharge[client] = target;
            MedicInOvercharge[target] = client;
            CreateTimer(fOverchargeDuration[skill_overcharge], StopOvercharge, client);
            PrintHintText(client, "Overcharging %N", target);
            PrintHintText(target, "Being overcharged by %N", client);
        }
        
        return true;
    }
    
    return false;
}

public Action:StopOvercharge(Handle:timer, any:client)
{
    if (ValidPlayer(AllyInOvercharge[client]))
    {
        W3ResetBuffRace(AllyInOvercharge[client], fDamageModifier, thisRaceID);
        W3ResetBuffRace(client, fMaxSpeed2, thisRaceID);
                        
        MedicInOvercharge[AllyInOvercharge[client]] = -1;
        AllyInOvercharge[client] = -1;
    }
}


public Action:OverchargeTimer(Handle:timer)
{
    new ally;
    new Float:allyMaxSpeed;
    new Float:medicMaxSpeed;
    new Float:maxSpeedDifference;
    
    new Float:allyPos[3];
    new Float:medicPos[3];
    
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i))
        {
            if (War3_GetRace(i) == thisRaceID)
            {
                new skill_overcharge = War3_GetSkillLevel(i, thisRaceID, SKILL_OVERCHARGE);
                if (skill_overcharge > 0 && ValidPlayer(AllyInOvercharge[i]))
                {
                    ally = AllyInOvercharge[i];
                    
                    GetClientAbsOrigin(i, medicPos);
                    GetClientAbsOrigin(ally, allyPos);
                    
                    medicMaxSpeed = W3GetBuffMaxFloat(i, fMaxSpeed) + W3GetBuffMaxFloat(i, fMaxSpeed2);
                    allyMaxSpeed = W3GetBuffMaxFloat(ally, fMaxSpeed) + W3GetBuffMaxFloat(ally, fMaxSpeed2);

                    if (ValidPlayer(i, true) && ValidPlayer(ally, true) && GetVectorDistance(medicPos, allyPos) <= fOverchargeMaxDistance[skill_overcharge]*fOverchargeSeparationFactor)
                    {
                        War3_SetBuff(ally, fDamageModifier, thisRaceID, fOverchargeDamageMod[skill_overcharge]);
                        
                        if (medicMaxSpeed < allyMaxSpeed)
                        {
                            maxSpeedDifference = 1.0 + (allyMaxSpeed - medicMaxSpeed);
                            War3_SetBuff(i, fMaxSpeed2, thisRaceID, maxSpeedDifference);
                        }
                        
                        medicPos[2] += 40.0;
                        allyPos[2] += 40.0;
                            
                        TE_SetupBeamPoints(medicPos, allyPos, HealSprite, HaloSprite, 0, 0, fOverchargeTimerRepeat, 2.0, 6.0, 0, 0.0, {255, 55, 55, 200}, 0);
                        TE_SendToAll();
                    }
                    else
                    {
                        W3ResetBuffRace(ally, fDamageModifier, thisRaceID);
                        W3ResetBuffRace(i, fMaxSpeed2, thisRaceID);
                        
                        MedicInOvercharge[ally] = -1;
                        AllyInOvercharge[i] = -1;
                    }
                }
            }
        }
    }
}

public OnWar3Event(W3EVENT:event,client)
{
    //Need to test this with a TimeWaster. Using OnPost should be fine, but must be tested to be sure!
    if(event==OnPostGiveXPGold && ValidPlayer(MedicInOvercharge[client], true))
    {
        if (W3GetVar(EventArg1) == XPAwardByKill)
        {
            new String:awardString[] = "your overcharged ally getting a kill";
            W3GiveXPGold(MedicInOvercharge[client], XPAwardByKill, W3GetVar(EventArg2), _, awardString);
        }
    }
}


public bool:DoLine(any:client, Float:maxDistance)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        new skill_line = War3_GetSkillLevel(client, thisRaceID, SKILL_HEALLINE);
        if (skill_line > 0)
        {
            //Check to see if an ally is close enough.
            new target = GetAllyInCrosshair(client, maxDistance);
            
            //If invalid players, return false.
            
            if (!ValidPlayer(target, true))
            {
                return false;
            }
            
            new targetHP = GetClientHealth(target);
            
            //If no ally detected or ally is skill immune, return false.
            if (IsSkillImmune(target) || GetClientTeam(client) != GetClientTeam(target) || targetHP >= War3_GetMaxHP(target))
            {
                return false;
            }
            
            new Float:HealerPos[3];
            new Float:TargetPos[3];
            
            GetClientAbsOrigin(client, HealerPos);
            HealerPos[2] += 40.0;
            GetClientAbsOrigin(target, TargetPos);
            TargetPos[2] += 40.0;
            
            War3_HealToMaxHP(target, iHeallineHealHP[skill_line]);
                
            TE_SetupBeamPoints(HealerPos, TargetPos, HealSprite, HaloSprite, 0, 0, 0.5, 3.0, 6.0, 0, 0.0, {100, 255, 55, 255}, 0);
            TE_SendToAll();
            
            W3FlashScreen(target, RGBA_COLOR_GREEN);
        }
        
        return true;
    }
    
    return false;//Client was not the right race, or alive.
}


public bool:DoWave(any:client, Float:maxDistance, any:numWaves)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        new skill_wave = War3_GetSkillLevel(client, thisRaceID, SKILL_HEALWAVE);
        if (skill_wave > 0 && numWaves > 0)
        {
            new HealerTeam = GetClientTeam(client);
            
            new Float:HealerPos[3];
            new Float:TargetPos[3];
            new Float:tempPos[3];
            
            new currentTarget;
            new Float:currentDistance;
            new Float:tempDistance;
            
            new bool:bHasBeenHealedByWave[MAXPLAYERS+1];
            for (new i=0; i<=MAXPLAYERS; i++)
            {
                bHasBeenHealedByWave[i] = false;
            }
            
            //Check to see if an ally is close enough.
            ClientTracer = client;
            new target = client;
            /*new target = War3_GetTargetInViewCone(client, maxDistance, true, 45.0, AimTargetFriendlyFilter);
            
            //If no ally detected or ally is skill immune, return false.
            if (!ValidPlayer(target, true) || IsSkillImmune(target))
            {
                return false;
            }*/
            
            GetClientAbsOrigin(client, HealerPos);
            GetClientAbsOrigin(target, TargetPos);
            
            if(GetClientHealth(target) < War3_GetMaxHP(target))
            {
                War3_HealToMaxHP(target, iHealwaveHealHP[skill_wave]);
            }
                
            /*TE_SetupBeamPoints(HealerPos, TargetPos, HealSprite, HaloSprite, 0, 0, 0.5, 3.0, 6.0, 0, 0.0, {100, 255, 55, 255}, 0);
            TE_SendToAll();
            
            W3FlashScreen(target, RGBA_COLOR_GREEN);*/
            
            bHasBeenHealedByWave[target] = true;
            
            numWaves--;
            
            while (numWaves > 0)
            {
                currentTarget = -1;
                currentDistance = maxDistance;
                
                AddVectors(NULL_VECTOR, TargetPos, HealerPos);
                
                for(new i=1; i<=MaxClients; i++)
                {
                    if(ValidPlayer(i, true) && GetClientTeam(i) == HealerTeam  && !IsSkillImmune(target))
                    {
                        GetClientAbsOrigin(i, tempPos);
                        tempDistance = GetVectorDistance(HealerPos, tempPos);
                        
                        if (tempDistance < currentDistance && !bHasBeenHealedByWave[i])
                        {
                            currentTarget = i;
                            currentDistance = tempDistance;
                            AddVectors(NULL_VECTOR, tempPos, TargetPos);
                        }
                    }
                }
                
                if (ValidPlayer(currentTarget))
                {
                    HealerPos[2] += 40.0;
                    TargetPos[2] += 40.0;
                    
                    if (GetClientHealth(currentTarget) < War3_GetMaxHP(currentTarget))
                    {
                        War3_HealToMaxHP(currentTarget, iHealwaveHealHP[skill_wave]);
                    }
                        
                    TE_SetupBeamPoints(HealerPos, TargetPos, HealSprite, HaloSprite, 0, 0, 0.5, 3.0, 6.0, 0, 0.0, {100, 255, 55, 255}, 0);
                    TE_SendToAll();
                    
                    W3FlashScreen(currentTarget, RGBA_COLOR_GREEN);
                    
                    bHasBeenHealedByWave[currentTarget] = true;
                    TargetPos[2] -= 40.0;
                }
                
                numWaves--;
            }
        }
        
        return true;
    }
    
    return false;//Client was not the right race, or alive.
}

public Action:HealwaveTimer(Handle:timer)
{
    for (new i=1; i<=MAXPLAYERS; i++)
    {
        if (ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID)
        {
            new skill_healwave = War3_GetSkillLevel(i, thisRaceID, SKILL_HEALWAVE);
            if (skill_healwave > 0)
            {
                DoWave(i, fHealwaveMaxDistance[skill_healwave], iHealwaveMaxWaves[skill_healwave]);
            }
        }
    }
}


//
// Menu functions
//

public DoHospitalMenu(client)
{
    new Handle:HospitalMenu=CreateMenu(War3Source_HospitalMenu_Selected);
    SetMenuPagination(HospitalMenu,MENU_NO_PAGINATION);
    SetMenuTitle(HospitalMenu,"==TELEPORT TO SPAWN==");
    SetMenuExitButton(HospitalMenu,false);
    
    AddMenuItem(HospitalMenu,"yes","Yes",ITEMDRAW_DEFAULT);
    AddMenuItem(HospitalMenu,"no","No",ITEMDRAW_DEFAULT);
    DisplayMenu(HospitalMenu,client,iHospitalTeleMenuLife);
}

public War3Source_HospitalMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        if(ValidPlayer(client))
        {
            decl String:choice[16];
            decl String:SelectionDispText[256];
            new SelectionStyle;
            
            GetMenuItem(menu,selection,choice,sizeof(choice),SelectionStyle,SelectionDispText,sizeof(SelectionDispText));
            
            if (StrEqual(choice,"yes") && ValidPlayer(client, true))
            {
                TeleportToSpawn(client);
            }
        }
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}


//
// Helper functions
//

public InitRound(client)
{
    if( War3_GetRace(client) == thisRaceID && ValidPlayer(client, true))
    {
        War3_WeaponRestrictTo(client, thisRaceID, "weapon_deagle,weapon_knife");
        //War3_WeaponRestrictTo(client, thisRaceID, "weapon_tmp,weapon_deagle,weapon_knife");
    
        /*if (!Client_HasWeapon(client, "weapon_tmp"))
        {
            Client_GiveWeapon(client, "weapon_tmp", true);
        }*/
    
        if (!Client_HasWeapon(client, "weapon_deagle"))
        {
            Client_GiveWeapon(client, "weapon_deagle", true);
        }
        
        if (GetClientTeam(client) == TEAM_T && !bTLocationSet)
        {
            GetClientAbsOrigin(client, fSpawnLocationT);
            bTLocationSet = true;
        }
        else if (GetClientTeam(client) == TEAM_CT && !bCTLocationSet)
        {
            GetClientAbsOrigin(client, fSpawnLocationCT);
            bCTLocationSet = true;
        }
        else
        {
            //
        }
    }
}


public GetAllyInCrosshair(client, Float:maxDistance)
{
    new target;
    
    new Float:angle[3];
    GetClientEyeAngles(client,angle);
    new Float:endpos[3];
    new Float:startpos[3];
    GetClientEyePosition(client,startpos);
    new Float:dir[3];
    GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(dir, maxDistance);
    AddVectors(startpos, dir, endpos);
    
    ClientTracer = client;
    TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
    target = TR_GetEntityIndex(_);
    
    return target;
}


public bool:AimTargetFilter(entity,mask)
{
    return (entity != ClientTracer);
}


/*public bool:AimTargetFriendlyFilter(entity,mask)
{
    if (ValidPlayer(entity,true) && entity != ClientTracer)
    {
        if (GetClientTeam(entity) == GetClientTeam(ClientTracer))
        {
            return true;
        }
    }
    return false;
}*/


public bool:ValidHospitalHealth(any:target)
{
    new Float:targetHP = float(GetClientHealth(target));
    new Float:targetMaxHP = float(War3_GetMaxHP(target));
    if (targetHP/targetMaxHP < 0.5)
    {
        return true;
    }
    return false;
}


public TeleportToSpawn(any:target)
{
    new Float:teleportLocation[3];
    if (GetClientTeam(target) == TEAM_T)
    {
        AddVectors(NULL_VECTOR,fSpawnLocationT,teleportLocation);
    }
    else if (GetClientTeam(target) == TEAM_CT)
    {
        AddVectors(NULL_VECTOR,fSpawnLocationCT,teleportLocation);
    }
    else
    {
        //
    }
    
    TeleportEntity(target,teleportLocation,NULL_VECTOR,NULL_VECTOR);
}