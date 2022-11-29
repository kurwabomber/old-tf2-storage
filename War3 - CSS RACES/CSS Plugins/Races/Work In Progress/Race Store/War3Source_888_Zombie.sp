/**
 * 
 * File: War3Source_Zombie.sp
 * Description: The Zombie for War3Source.
 * Author(s): <-->
 */

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
new thisRaceID;
/*
Along with these abilities, increased damage, 1.0 attack speed and the ability to track players were given to zombies and infected players 
*/

new SKILL_MANGLE,SKILL_RETCH,SKILL_GROAN,SKILL_LURCH, ULT_EXPLOSION;

//new bool:bInfected[66];
new Float:MangleChance[]={0.0, 0.2,0.24,0.28,0.32};
new bool:bZombied[66];
new bool:bInfected[66];
#define MAXWARDS 64*4 //on map LOL
#define WARDRADIUS 60
#define WARDDAMAGE 3
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0
new CurrentWardCount[MAXPLAYERS];
new WardStartingArr[]={0,1,2,2,3}; 
new Float:WardLocation[MAXWARDS][3]; 
new WardOwner[MAXWARDS];
new Float:LastThunderClap[MAXPLAYERS];
new String:wardDamageSound[]="war3source/thunder_clap.wav";

new Float:LurchTime[]={0.0, 7.0, 8.0, 9.0, 10.0};

new groanhealth[]= {0, 10, 12, 14, 16};

new g_iHealth, g_Armor, g_offsCollisionGroup;

new String:groan[]= "ambient/machines/wall_move5.wav";
new String:groan2[]= "ambient/machines/wall_ambient1.wav";
new String:groan3[]= "ambient/machines/wall_move3.wav";

new Float:RadArr[]={0.0, 220.0, 260.0, 300.0};
new ExplosionModel;
new Float:ExplosionLocation[MAXPLAYERS][3];
new BeamSprite;
new HaloSprite;
new Laser;
new bool:TeamZombie[MAXPLAYERS];

new const PoisonInitialDamage=10;
new const PoisonTrailingDamage=5;
new BeingPoisonedBy[MAXPLAYERS];

public OnWar3LoadRaceOrItemOrdered2(num)
{
    if(num==111)
    {
    thisRaceID=War3_CreateNewRace("Zombie", "zombie");
    SKILL_MANGLE=War3_AddRaceSkill(thisRaceID,"Mangle(attacker)", "More damage faster infection. Infected enemies may raise as zombies",false,4);
    SKILL_LURCH=War3_AddRaceSkill(thisRaceID,"Lurch(ability)", "Increases your speed to normal speed",false,4);
    SKILL_RETCH=War3_AddRaceSkill(thisRaceID,"Retch(+ability1)", "Cloud that heals you and infects your enemy",false,4);
    SKILL_GROAN=War3_AddRaceSkill(thisRaceID,"Groan(+ability2)", "Call other zombies to your side",false,4);
    ULT_EXPLOSION=War3_AddRaceSkill(thisRaceID,"Explosion", "Focus and explode infecting the enemy",true,3);
    War3_CreateRaceEnd(thisRaceID);
    }
}

public Plugin:myinfo = 
{
    name = "War3Source Race - Zombie",
    author = "<-->",
    description = "Zombie race for War3Source.",
    version = "1.0.7.6",
    url = "http://warcraft-source.net/"
};

public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
    HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);
    HookEvent("round_end",RoundEndEvent);
    g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
    g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
    if (g_iHealth == -1)
    {
    SetFailState("[Zombie Race] Error - Unable to get offset for CSSPlayer::m_iHealth");
    }

    g_Armor = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
    if (g_Armor == -1)
    {
    SetFailState("[Zombie Race] Error - Unable to get offset for CSSPlayer::m_ArmorValue");
    }
    CreateTimer(1.0,Trails,_,TIMER_REPEAT);
    CreateTimer(0.8,CalcWards,_,TIMER_REPEAT);
}

public Action:Trails(Handle:timer,any:userid)
{
    for(new x=0;x<MaxClients;x++)
    {
        if(ValidPlayer(x,true)&&War3_GetRace(x)==thisRaceID)
        {
            for(new y=0;y<MaxClients;y++)
            {
                if(ValidPlayer(y,true) && GetClientTeam(y)!=GetClientTeam(x))
                {
                    TE_SetupBeamFollow(y,Laser,0,1.0,2.0,7.0,1,{0,255,0,255});
                    TE_SendToClient(x,0.1);
                }
            }
        }
    }
}

public OnMapStart()
{
    War3_PrecacheSound(groan);
    War3_PrecacheSound(groan2);
    War3_PrecacheSound(groan3);    
    War3_PrecacheSound(wardDamageSound);
    ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    Laser=PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnWar3PlayerAuthed(client)
{
    LastThunderClap[client]=0.0;
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i))
        {            
            if(War3_GetRace(i)==thisRaceID)
            {
                CurrentWardCount[i]=0;
                bZombied[i]=true;
            }
            else
            {
                if(War3_GetRace(i)!=thisRaceID && bZombied[i] && TeamZombie[i])
                {
                    War3_WeaponRestrictTo(i,thisRaceID,"");
                    if(GetClientTeam(i) == 3)
                    {
                        CS_SwitchTeam(i, 2);
                        TeamZombie[i] = false;
                        bZombied[i]=false;
                    }
                    else
                    {
                        CS_SwitchTeam(i, 3);
                        TeamZombie[i] = false;
                        bZombied[i]=false;
                    }
                }    
            }
            bZombied[i]=false;
            bInfected[i]=false;
        }
    }
}
public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i))
        {
            if(War3_GetRace(i)!=thisRaceID && bZombied[i] && TeamZombie[i])
            {
                War3_WeaponRestrictTo(i,thisRaceID,"");
                if(GetClientTeam(i) == 3)
                {
                    CS_SwitchTeam(i, 2);
                    TeamZombie[i] = false;
                    bZombied[i]=false;
                }
                else
                {
                    CS_SwitchTeam(i, 3);
                    TeamZombie[i] = false;
                    bZombied[i]=false;
                }
            }
        }
    }
}

public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim)&&ValidPlayer(attacker))
    {
        if(bInfected[victim] && GetRandomFloat(0.0,1.0)<=0.5)
        {
            CreateTimer(1.0,spawnzomb,victim);
        }
        if(bZombied[victim] && GetRandomFloat(0.0,1.0)<=0.5 && War3_GetRace(victim) != thisRaceID)
        {
            GetClientAbsOrigin(victim,ExplosionLocation[victim]);
            Zombie2Bomber(victim,2);
        }
        new race = War3_GetRace(attacker);
        if(race==thisRaceID)
        {
            if(bZombied[attacker] && GetRandomFloat(0.0,1.0)<=0.5)
            {
                //if(GetClientTeam(victim) == 3)
                //{
                //ChangeClientTeam(victim, 2);
                //}
                //else
                //{
                //    ChangeClientTeam(victim, 3);
                //}
                BeingPoisonedBy[victim]=attacker;
                CreateTimer(1.0,spawnzomb,victim);
            }
        }
        new race2 = War3_GetRace(victim);
        if(race2==thisRaceID)
        {
            GetClientAbsOrigin(victim,ExplosionLocation[victim]);
            ZombieBomber(victim,War3_GetSkillLevel(victim,thisRaceID,ULT_EXPLOSION));
        }
    }
    if(TeamZombie[victim])
    {
        if(GetClientTeam(victim) == 3)
        {
            CS_SwitchTeam(victim, 2);
            TeamZombie[victim] = false;
        }
        else
        {
            CS_SwitchTeam(victim, 3);
            TeamZombie[victim] = false;
        }     
    }    
}

public OnWar3EventSpawn(client)
{
    if(!TeamZombie[client])
    {
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
    bInfected[client]=false;
    new race = War3_GetRace(client);
    if (race == thisRaceID)
    {  
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
        CurrentWardCount[client]=0;
        War3_SetBuff(client,bSilenced,thisRaceID,false);
        bZombied[client]=true;
        War3_SetBuff(client,fSlow,thisRaceID,0.7);
        EmitSoundToAll(groan2,client);
        if(GetClientTeam(client) == 3)
        {
        //    SetEntityModel(client, "models/player/techknow/zp/z2.mdl");
        }
        else
        {
        //    SetEntityModel(client, "models/player/slow/l4d/hot_ass_zombie/slow_v2.mdl");
        }
    }
    else
    {        
        War3_SetBuff(client,bSilenced,thisRaceID,false);
        War3_SetBuff(client,fSlow,thisRaceID,1.0);
        
    }
}
public Action:knifer(Handle:h,any:client){
    if(ValidPlayer(client)&&IsPlayerAlive(client))
    {
        GivePlayerItem(client, "weapon_knife");
    }
}
public Action:spawnzomb(Handle:h,any:client)
{
    if(ValidPlayer(client) && War3_GetRace(client) != thisRaceID)
    {
        War3_SpawnPlayer(client);
        bInfected[client]=false;
        bZombied[client]=true;
        //SetEntityModel(client, "models/player/slow/classic_zombie/classic_zombie.mdl");
        W3ResetAllBuffRace(client,thisRaceID);
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
        War3_SetBuff(client,bSilenced,thisRaceID,true);
        if(GetClientTeam(client) == 3)
        {
            CS_SwitchTeam(client, 2);
            TeamZombie[client] = true;
        }
        else
        {
            CS_SwitchTeam(client, 3);
            TeamZombie[client] = true;
        }
        new Float:ang[3];
        new Float:pos[3];
        GetClientEyeAngles(BeingPoisonedBy[client],ang);
        GetClientAbsOrigin(BeingPoisonedBy[client],pos);
        TeleportEntity(client,pos,ang,NULL_VECTOR);
        SetEntData(BeingPoisonedBy[client], g_offsCollisionGroup, 2, 4, true);
        SetEntData(client, g_offsCollisionGroup, 2, 4, true);
        EmitSoundToAll(groan,client);
        CreateTimer(1.0,knifer,client);
        W3ResetPlayerColor(client, thisRaceID);
        CreateTimer(3.0,normal,BeingPoisonedBy[client]);
        CreateTimer(3.0,normal,client);
    }
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace != thisRaceID)
    {
        bZombied[client]=false;
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3ResetAllBuffRace( client, thisRaceID );

    }
    if(newrace == thisRaceID)
    {
        bZombied[client]=true;
        War3_SetBuff(client,fSlow,thisRaceID,0.7);
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
        if(ValidPlayer(client,true))
        {
            EmitSoundToAll(groan2,client);
            if(GetClientTeam(client) == 3)
            {
            //    SetEntityModel(client, "models/player/techknow/zp/z2.mdl");
            }
            else
            {
            //    SetEntityModel(client, "models/player/slow/l4d/hot_ass_zombie/slow_v2.mdl");
            }
        }
    }
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_EXPLOSION);
        if(ult_level>0)        
        {        
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_EXPLOSION,true))
            {
                War3_CooldownMGR(client,5.0,thisRaceID,ULT_EXPLOSION,false,true);    
                GetClientAbsOrigin(client,ExplosionLocation[client]);
                CreateTimer(0.1,Groaner,client);
                CreateTimer(0.8,Groaner,client);
                CreateTimer(1.6,Groaner,client);
                CreateTimer(3.0,DelayedBomber,client);
            }
        }    
        else
        {
            PrintHintText(client,"Level Your Ultimate First");
        }
    }
}

public Action:Groaner(Handle:h,any:client){
    if(ValidPlayer(client)&&IsPlayerAlive(client))
    {
        EmitSoundToAll(groan3,client);
    }
}

public Action:DelayedBomber(Handle:h,any:client){
    if(ValidPlayer(client))
    {
        ForcePlayerSuicide(client);
        ZombieBomber(client,War3_GetSkillLevel(client,thisRaceID,ULT_EXPLOSION));
    }
}

public Zombie2Bomber(client,level)
{
    new Float:radius2=200.0;
    if(level<=0)
        return; // just a safety check
    new Float:client_location[3];
    new our_team=GetClientTeam(client);
    for(new i=0;i<3;i++){
        client_location[i]=ExplosionLocation[client][i];
    }
    TE_SetupExplosion(client_location,ExplosionModel,10.0,1,0,RoundToFloor(radius2),160);
    TE_SendToAll();
    client_location[2]-=40.0;
    TE_SetupBeamRingPoint(client_location, 10.0, radius2, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {200,255,200,33}, 120, 0);
    TE_SendToAll();
    
    new beamcolor[]={0,255,0,255}; 
    TE_SetupBeamRingPoint(client_location, 20.0, radius2+10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
    TE_SendToAll();
    client_location[2]+=40.0;
    
    new Float:location_check[3];
    for(new x=1;x<=MaxClients;x++)
    {
        if(ValidPlayer(x,true)&&client!=x)
        {
            new team=GetClientTeam(x);
            if(team==our_team)
                continue;
            GetClientAbsOrigin(x,location_check);
            new Float:distance=GetVectorDistance(client_location,location_check);
            if(distance>radius2)
                continue;
            
            if(!W3HasImmunity(x,Immunity_Ultimates))
            {
                W3FlashScreen(x,RGBA_COLOR_GREEN);
                BeingPoisonedBy[x]=client;
                War3_DealDamage(x,PoisonInitialDamage,client,DMG_BULLET,"zombieexplosion");
                bInfected[x]=true;
                CreateTimer(1.0,FastI,x);
                W3MsgAttackedBy(x,"Zombie Explosion");
                W3MsgActivated(client,"Zombie Explosion");
            }
            else
            {
                PrintToConsole(client,"[W3S] Could not damage player %d due to immunity",x);
            }
            
        }
    }
}

public ZombieBomber(client,level)
{
    new ult_skill=War3_GetSkillLevel(client,thisRaceID,ULT_EXPLOSION);
    new Float:radius1=RadArr[ult_skill];
    if(level<=0)
        return; // just a safety check
    new Float:client_location[3];
    new our_team=GetClientTeam(client);
    for(new i=0;i<3;i++){
        client_location[i]=ExplosionLocation[client][i];
    }
    TE_SetupExplosion(client_location,ExplosionModel,10.0,1,0,RoundToFloor(radius1),160);
    TE_SendToAll();
    client_location[2]-=40.0;
    TE_SetupBeamRingPoint(client_location, 10.0, radius1, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {200,255,200,33}, 120, 0);
    TE_SendToAll();
    
    new beamcolor[]={0,255,0,255}; 
    TE_SetupBeamRingPoint(client_location, 20.0, radius1+10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
    TE_SendToAll();
    client_location[2]+=40.0;
    
    new Float:location_check[3];
    for(new x=1;x<=MaxClients;x++)
    {
        if(ValidPlayer(x,true)&&client!=x)
        {
            new team=GetClientTeam(x);
            if(team==our_team)
                continue;
            GetClientAbsOrigin(x,location_check);
            new Float:distance=GetVectorDistance(client_location,location_check);
            if(distance>radius1)
                continue;
            
            if(!W3HasImmunity(x,Immunity_Ultimates))
            {
                W3FlashScreen(x,RGBA_COLOR_GREEN);
                BeingPoisonedBy[x]=client;
                War3_DealDamage(x,PoisonInitialDamage,client,DMG_BULLET,"zombieexplosion");
                bInfected[x]=true;
                CreateTimer(1.0,FastI,x);
                W3MsgAttackedBy(x,"Zombie Explosion");
                W3MsgActivated(client,"Zombie Explosion");
            }
            else
            {
                PrintToConsole(client,"[W3S] Could not damage player %d due to immunity",x);
            }
            
        }
    }
}

public Action:FastI(Handle:timer,any:client)
{
    if(ValidPlayer(BeingPoisonedBy[client]) && ValidPlayer(client,true) && bInfected[client])
    {
        War3_DealDamage(client,PoisonTrailingDamage,BeingPoisonedBy[client],DMG_BULLET,"zombieexplosion");
        W3FlashScreen(client,RGBA_COLOR_RED);
        CreateTimer(1.0,FastI,client);
    }
}

public Action:MedI(Handle:timer,any:client)
{
    if(ValidPlayer(BeingPoisonedBy[client]) && ValidPlayer(client,true) && bInfected[client])
    {
        War3_DealDamage(client,PoisonTrailingDamage,BeingPoisonedBy[client],DMG_BULLET,"zombieexplosion");
        W3FlashScreen(client,RGBA_COLOR_RED);
        CreateTimer(2.0,MedI,client);
    }
}

public Action:SlowI(Handle:timer,any:client)
{
    if(ValidPlayer(BeingPoisonedBy[client]) && ValidPlayer(client,true) && bInfected[client])
    {
        War3_DealDamage(client,PoisonTrailingDamage,BeingPoisonedBy[client],DMG_BULLET,"zombieexplosion");
        W3FlashScreen(client,RGBA_COLOR_RED);
        CreateTimer(3.0,SlowI,client);
    }
}

public Action:EventPlayerHurt(Handle:event, const String:name[],bool:dontBroadcast)
{
    new hitgroup = GetEventInt(event, "hitgroup");
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new dhealth = GetEventInt(event, "dmg_health");
    new darmor = GetEventInt(event, "dmg_armor");
    new health = GetEventInt(event, "health");
    new armor = GetEventInt(event, "armor");
    new String:weapon[32];
    GetEventString(event,"weapon",weapon,32);
    if(!StrEqual( weapon, "knife", false) && !StrEqual( weapon, "hegrenade", false))
    {
        if(bZombied[victim]==true)
        {
            if(hitgroup==1)
            {
                return Plugin_Continue;
            }
            else if (attacker != victim && victim != 0)
            {
                if (dhealth > 0)
                {
                    SetEntData(victim, g_iHealth, (health + dhealth), 4, true);
                }
                if (darmor > 0)
                {
                    SetEntData(victim, g_Armor, (armor + darmor), 4, true);
                }
            }
        }
    }
    else
    {
        return Plugin_Continue;
    }
    return Plugin_Continue;
}
    
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            //Infect
            if(bZombied[attacker]==true)
            {
                new leechhealth=RoundToFloor(damage*0.03);
                PrintToConsole(attacker,"Leeched +%d HP!",leechhealth);
                W3FlashScreen(victim,RGBA_COLOR_RED);
                W3FlashScreen(attacker,RGBA_COLOR_GREEN);    
                SetEntityHealth(attacker,GetClientHealth(attacker)+leechhealth);
                if(GetRandomFloat(0.0,1.0)<0.3)
                {
                    BeingPoisonedBy[victim]=attacker;
                    CreateTimer(0.5,SlowI,victim);
                    bInfected[victim]=true;
                    EmitSoundToAll(groan3,attacker);
                }
            }
        }
    }
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            //Infect
            if(bZombied[attacker]==true)
            {
                new mangle=War3_GetSkillLevel(victim,thisRaceID,SKILL_MANGLE);
                if(mangle>0)
                {    
                    if(GetRandomFloat(0.0,1.0)<=MangleChance[mangle] && !W3HasImmunity(attacker,Immunity_Skills))
                    {
                        War3_DamageModPercent(1.3);
                        BeingPoisonedBy[victim]=attacker;
                        bInfected[victim]=true;
                        CreateTimer(0.5,MedI,victim);
                        EmitSoundToAll(groan3,attacker);
                    }
                }
            }
        }
    }
}                
            
            
public OnAbilityCommand(client,ability,bool:pressed)
{
    if(!Silenced(client))
    {
        if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
        {
            new lurch=War3_GetSkillLevel(client,thisRaceID,SKILL_LURCH);
            if(lurch>0)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_LURCH,true))
                {
                    War3_CooldownMGR(client,12.0,thisRaceID,SKILL_LURCH,false,true);
                    War3_SetBuff(client,fSlow,thisRaceID,1.0);
                    CreateTimer(LurchTime[lurch],slowdown,client);
                    EmitSoundToAll(groan2,client);
                }
            }
        }
        if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
        {
            new retch=War3_GetSkillLevel(client,thisRaceID,SKILL_RETCH);
            if(retch>0)
            {
                if(CurrentWardCount[client]<WardStartingArr[retch])
                {
                    new iTeam=GetClientTeam(client);
                    new bool:conf_found=false;
                    if(War3_GetGame()==Game_TF)
                    {
                        new Handle:hCheckEntities=War3_NearBuilding(client);
                        new size_arr=0;
                        if(hCheckEntities!=INVALID_HANDLE)
                            size_arr=GetArraySize(hCheckEntities);
                        for(new x=0;x<size_arr;x++)
                        {
                            new ent=GetArrayCell(hCheckEntities,x);
                            if(!IsValidEdict(ent)) continue;
                            new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
                            if(builder>0 && ValidPlayer(builder) && GetClientTeam(builder)!=iTeam)
                            {
                                conf_found=true;
                                break;
                            }
                        }
                        if(size_arr>0)
                            CloseHandle(hCheckEntities);
                    }
                    if(conf_found)
                    {
                        W3MsgWardLocationDeny(client);
                    }
                    else
                    {
                        if(War3_IsCloaked(client))
                        {
                            W3MsgNoWardWhenInvis(client);
                            return;
                        }
                        CreateWard(client);
                        CurrentWardCount[client]++;
                        CreateTimer(10.0,Remove,client);
                    }
                }
                else
                {
                    W3MsgNoWardsLeft(client);
                }    
            }
        }
        if(War3_GetRace(client)==thisRaceID && ability==2 && pressed && IsPlayerAlive(client))
        {
            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_GROAN);
            if(skill_level>0)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_GROAN,true))
                {
                    War3_CooldownMGR(client,10.0,thisRaceID,SKILL_GROAN,false,true);
                    EmitSoundToAll(groan,client);
                    SetEntityHealth(client,GetClientHealth(client)+groanhealth[skill_level]);
                    new zombierace=War3_GetRaceIDByShortname("zombie");
                    new possibletargets[MAXPLAYERS];
                    new possibletargetsfound;
                    for(new i=1;i<=MaxClients;i++)
                    {
                        if(ValidPlayer(i))
                        {
                            //new onetarget=0;
                            new summonteam=GetClientTeam(i);
                            new summonerteam=GetClientTeam(client);
                            if(War3_GetRace(i)==zombierace && IsPlayerAlive(i)==true && summonteam==summonerteam && i != client)
                            {
                                possibletargets[possibletargetsfound]=i;
                                possibletargetsfound++;
                            }
                        }
                    }
                    new onetarget;
                    if(possibletargetsfound>0)
                    {
                        onetarget=possibletargets[GetRandomInt(0, possibletargetsfound-1)]; //i hope random 0 0 works to zero
                        if(onetarget>0)
                        {
                            new Float:ang[3];
                            new Float:pos[3];
                            //War3_SpawnPlayer(onetarget);
                            GetClientEyeAngles(client,ang);
                            GetClientAbsOrigin(client,pos);
                            TeleportEntity(onetarget,pos,ang,NULL_VECTOR);
                            SetEntData(onetarget, g_offsCollisionGroup, 2, 4, true);
                            SetEntData(client, g_offsCollisionGroup, 2, 4, true);
                            EmitSoundToAll(groan,onetarget);
                            CreateTimer(3.0,normal,onetarget);
                            CreateTimer(3.0,normal,client);
                            SetEntityHealth(onetarget,GetClientHealth(onetarget)+groanhealth[skill_level]);
                        }
                    }
                }
            }
        }
    }
    else
    {
        PrintHintText(client,"Silenced: Can not cast");
    }
}

public CreateWard(client)
{
    for(new i=0;i<MAXWARDS;i++)
    {
        if(WardOwner[i]==0)
        {
            WardOwner[i]=client;
            GetClientAbsOrigin(client,WardLocation[i]);
            break;
            ////CHECK BOMB HOSTAGES TO BE IMPLEMENTED
        }
    }
}

public Action:Remove(Handle:timer,any:client)
{
    RemoveWards(client);
}
public RemoveWards(client)
{
    for(new i=0;i<MAXWARDS;i++)
    {
        if(WardOwner[i]==client)
        {
            WardOwner[i]=0;
        }
    }
}

public Action:normal(Handle:timer,any:client)
{
    if(ValidPlayer(client,true))
    {
        new Float:end_dist=50.0;
        new Float:end_pos[3];
        GetClientAbsOrigin(client,end_pos);
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true)&&i!=client)
            {
                new Float:pos[3];
                GetClientAbsOrigin(i,pos);
                new Float:dist=GetVectorDistance(end_pos,pos);
                if(dist<=end_dist)
                {
                    CreateTimer(1.0,normal,client);
                    break;
                }
                else{
                    SetEntData(client, g_offsCollisionGroup, 5, 4, true);
                }
            }
        }
    }
}

public Action:slowdown(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
        War3_SetBuff(client,fSlow,thisRaceID,0.7);
    }
}

public Action:CalcWards(Handle:timer,any:userid)
{
    new client;
    for(new i=0;i<MAXWARDS;i++)
    {
        if(WardOwner[i]!=0)
        {
            client=WardOwner[i];
            if(!ValidPlayer(client,true))
            {
                WardOwner[i]=0; //he's dead, so no more wards for him
                --CurrentWardCount[client];
            }
            else
            {
                WardEffectAndDamage(client,i);
            }
        }
    }
}
public WardEffectAndDamage(owner,wardindex)
{
    new ownerteam=GetClientTeam(owner);
    new beamcolor[]={0,255,0,255};
    
    new Float:start_pos[3];
    new Float:end_pos[3];
    
    new Float:tempVec1[]={0.0,0.0,WARDBELOW};
    new Float:tempVec2[]={0.0,0.0,WARDABOVE};
    AddVectors(WardLocation[wardindex],tempVec1,start_pos);
    AddVectors(WardLocation[wardindex],tempVec2,end_pos);
 
    TE_SetupBeamPoints(start_pos,end_pos,BeamSprite,HaloSprite,0,GetRandomInt(30,100),0.17,float(WARDRADIUS),float(WARDRADIUS),0,0.0,beamcolor,10);
    TE_SendToAll();
    
    new Float:BeamXY[3];
    for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
    new Float:BeamZ= BeamXY[2];
    BeamXY[2]=0.0;
    
    
    new Float:VictimPos[3];
    new Float:tempZ;
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam )
        {
            GetClientAbsOrigin(i,VictimPos);
            tempZ=VictimPos[2];
            VictimPos[2]=0.0; //no Z
                  
            if(GetVectorDistance(BeamXY,VictimPos) < WARDRADIUS) ////ward RADIUS
            {
                // now compare z
                if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
                {
                    if(W3HasImmunity(i,Immunity_Skills))
                    {
                        W3MsgSkillBlocked(i,_,"Wards");
                    }
                    else
                    {
                        //Boom!
                        new DamageScreen[4];
                        DamageScreen[0]=beamcolor[0];
                        DamageScreen[1]=beamcolor[1];
                        DamageScreen[2]=beamcolor[2];
                        DamageScreen[3]=50; //alpha
                        W3FlashScreen(i,DamageScreen);
                        if(War3_DealDamage(i,WARDDAMAGE,owner,DMG_ENERGYBEAM,"wards",_,W3DMGTYPE_MAGIC))
                        {
                            BeingPoisonedBy[i]=owner;
                            bInfected[i]=true;
                            CreateTimer(0.1,SlowI,i);
                            if(LastThunderClap[i]<GetGameTime()-2)
                            {
                                EmitSoundToAll(wardDamageSound,i,SNDCHAN_WEAPON);
                                LastThunderClap[i]=GetGameTime();
                            }
                        }
                    }
                }
            }
        }
        if(ValidPlayer(i,true)&& War3_GetRace(i)==War3_GetRaceIDByShortname("zombie"))
        {
            GetClientAbsOrigin(i,VictimPos);
            tempZ=VictimPos[2];
            VictimPos[2]=0.0; //no Z
                  
            if(GetVectorDistance(BeamXY,VictimPos) < WARDRADIUS) ////ward RADIUS
            {
                // now compare z
                if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
                {
                    SetEntityHealth(i,GetClientHealth(i)+2);
                }
            }
        }
    }
}