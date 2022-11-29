/**
* File: War3Source_SpiritWalker.sp
* Description: Spirit Walker race of warcraft.
* Author: Lucky 
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

new thisRaceID;
new BeamSprite,HaloSprite;

//Spirit Link
new Float:LinkRad[]={0.0,310.0,315.0,320.0,325.0,330.0,335.0,340.0,345.0,350.0};
new bool:bInRange[MAXPLAYERS];
new LinkAmount[MAXPLAYERS];
// new String:link_sound[]="war3source/spiritwalker/link.wav";

//Disenchant
new Float:DisenchRad[]={0.0,350.0,360.0,370.0,380.0,390.0,400.0,410.0,420.0,430.0};
new bool:bIsHit[MAXPLAYERS];
new Float:DisenchDuration = 3.0;
new Float:DisenchCooldown[] = {0.0,18.0,17.0,16.0,15.0,14.0,13.0,12.0,11.0,10.0};
// new String:disenchant_sound[]="war3source/spiritwalker/disenchant.wav";

//Ancestral Spirit
// new String:ancestral_sound[]="war3source/spiritwalker/ancestral.wav";
new g_offsCollisionGroup;

//Resistant Skin

//Ethreal Form
new bool:bIsActive[MAXPLAYERS];
new Float:EthrealCD[10]={0.0,36.0,34.0,32.0,30.0,28.0,26.0,24.0,22.0,20.0};
// new String:ethreal_sound[]="war3source/spiritwalker/ethereal.wav";

//Skills & Ultimate
new SKILL_SPIRIT, SKILL_DISENCHANT, SKILL_ANCESTRAL, SKILL_RESISTANT, ULT_ETHREAL;

public Plugin:myinfo = 
{
    name = "War3Source Race - Spirit Walker",
    author = "Lucky",
    description = "Spirit Walker race of warcraft",
    version = "1.0.9.2",
    url = ""
}
new m_vecBaseVelocity;
public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
    g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");    
    CreateTimer(1.0,Heal,_,TIMER_REPEAT);
}

public OnMapStart()
{
    // War3_PrecacheSound(link_sound);
    // War3_PrecacheSound(disenchant_sound);
    // War3_PrecacheSound(ancestral_sound);
    // War3_PrecacheSound(ethreal_sound);
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==010){
        thisRaceID=War3_CreateNewRace("SpiritWalker", "spiritwalker");
        SKILL_SPIRIT=War3_AddRaceSkill(thisRaceID,"Spirit Link(Auto-Cast)", "Share your damage with nearby allies",false,9);
        SKILL_DISENCHANT=War3_AddRaceSkill(thisRaceID,"Disenchant(attacker)","Remove buffs of victims that get too close",false,9);
        SKILL_ANCESTRAL=War3_AddRaceSkill(thisRaceID,"Ancestral Spirit(ability)","Raise a dead ally",false,1);
        SKILL_RESISTANT=War3_AddRaceSkill(thisRaceID,"Resistant Skin(passive)","Spell immunity",false,1);
        ULT_ETHREAL=War3_AddRaceSkill(thisRaceID,"Ethreal Form","Become immune to physical damage",true,9);
        War3_CreateRaceEnd(thisRaceID);
    }
}

public OnRaceChanged ( client,oldrace,newrace )
{
    if(newrace != thisRaceID){
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3ResetAllBuffRace(client,thisRaceID);
    }
    
    if(newrace == thisRaceID){
        new skill_resistant=War3_GetSkillLevel(client,thisRaceID,SKILL_RESISTANT);
        
        if(skill_resistant==1){
            War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
        }
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_mac10");
        if(ValidPlayer(client,true)){
            GivePlayerItem(client, "weapon_mac10");
        }
    }
    
    
}

public OnWar3EventSpawn(client)
{    
    War3_SetBuff(client,bBuffDenyAll,thisRaceID,false);
    bIsHit[client]=false;
    bInRange[client]=false;
    if(War3_GetRace(client)==thisRaceID){
        new skill_resistant=War3_GetSkillLevel(client,thisRaceID,SKILL_RESISTANT);
        
        bIsActive[client]=false;
        if(skill_resistant==1){
            War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
        }
        LinkAmount[client]=0;
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
        War3_SetBuff(client,fSlow,thisRaceID,1.0);
        //War3_SetBuff(client,bDisarm,thisRaceID,false);
        GivePlayerItem(client, "weapon_mac10");
        W3ResetPlayerColor(client,thisRaceID);
    }
    
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(!Silenced(client)){
        new skill_ancestral=War3_GetSkillLevel(client,thisRaceID,SKILL_ANCESTRAL);
        
        if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
            if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ANCESTRAL,true)){
                if(skill_ancestral==1){
                    new Float:position111[3];
                    War3_CachedPosition(client,position111);
                    position111[2]+=5.0;
                    new targets[MAXPLAYERS];
                    new foundtargets;
                    for(new ally=1;ally<=MaxClients;ally++){
                        if(ValidPlayer(ally)){
                            new ally_team=GetClientTeam(ally);
                            new client_team=GetClientTeam(client);
                            if(War3_GetRace(ally)!=thisRaceID && !IsPlayerAlive(ally) && ally_team==client_team){
                                targets[foundtargets]=ally;
                                foundtargets++;
                            }
                        }
                    }
                    new target;
                    if(foundtargets>0){
                        target=targets[GetRandomInt(0, foundtargets-1)];
                        if(target>0){
                            new Float:ang[3];
                            new Float:pos[3];
                            War3_SpawnPlayer(target);
                            GetClientEyeAngles(client,ang);
                            GetClientAbsOrigin(client,pos);
                            TeleportEntity(target,pos,ang,NULL_VECTOR);
                            SetEntData(target, g_offsCollisionGroup, 2, 4, true);
                            SetEntData(client, g_offsCollisionGroup, 2, 4, true);
                            // EmitSoundToAll(ancestral_sound,client);
                            // CreateTimer(3.0, Stop, client);
                            War3_CooldownMGR(client,30.0,thisRaceID,SKILL_ANCESTRAL);
                        }
                    }
                    else
                    {
                        PrintHintText(client,"There are no allies you can revive");
                    }
                }
                else
                {
                    PrintHintText(client, "Level Ancestral Spirit first");
                }
            
            }
        }
        
    }
    else
    {
        PrintHintText(client,"Silenced: Can not cast");
    }
    
}

/*public Action:Stop(Handle:timer,any:client)
{
    // StopSound(client,SNDCHAN_AUTO,ancestral_sound);
}*/

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam){
            new race_attacker=War3_GetRace(attacker);
            //new race_victim=War3_GetRace(victim);
            
            if(race_attacker==thisRaceID &&!bIsHit[victim] && War3_SkillNotInCooldown(victim,thisRaceID,SKILL_DISENCHANT,false)){
                new skill_disenchant=War3_GetSkillLevel(attacker,thisRaceID,SKILL_DISENCHANT);
                new Float:attackerPos[3];
                new Float:victimPos[3];
                GetClientAbsOrigin(victim,victimPos);
                GetClientAbsOrigin(attacker,attackerPos);
                if(GetVectorDistance(victimPos,attackerPos)<DisenchRad[skill_disenchant]){
                    War3_CooldownMGR(attacker,DisenchCooldown[skill_disenchant],thisRaceID,SKILL_DISENCHANT);
                    bIsHit[victim]=true;
                    War3_SetBuff(victim,bBuffDenyAll,thisRaceID,true);
                    CreateTimer(DisenchDuration, StopDisenchant, victim);
                    War3_DealDamage(victim,25,attacker,DMG_BULLET,"Disenchant");
                    PrintHintText(victim, "Your buffs have been destroyed for %f seconds", DisenchDuration);
                    PrintHintText(attacker, "You've disenchanted your enemy for %f seconds", DisenchDuration);
                    // EmitSoundToAll(disenchant_sound,victim);
                }
            }
        }
    }
}


public Action:StopDisenchant(Handle:timer,any:client)
{
    War3_SetBuff(client,bBuffDenyAll,thisRaceID,false);
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam)
        {
            //new race_attacker=War3_GetRace(attacker);
            new race_victim=War3_GetRace(victim);
            if(race_victim==thisRaceID )
            {
                if(bIsActive[victim] && !W3HasImmunity(attacker,Immunity_Ultimates))
                {
                    War3_DamageModPercent(0.0);
                    PrintToConsole(attacker, "Damage Reduced against SpiritWalker - Ethreal");
                    PrintToConsole(victim, "Damage Reduced by SpiritWalker - Ethreal");
                }
                else if (War3_SkillNotInCooldown(victim,thisRaceID,SKILL_SPIRIT,false))
                {
                    War3_DamageModPercent(0.8);
                    PrintToConsole(attacker, "Damage Reduced by 20% against SpiritWalker");
                    PrintToConsole(victim, "Damage Reduced by 20% by SpiritWalker");
                }
            }
        }
    }
}

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        new skill_spirit=War3_GetSkillLevel(victim,thisRaceID,SKILL_SPIRIT);
        new ownerteam=GetClientTeam(victim);
        new Float:allyPos[3];
        new Float:clientPos[3];
        
        GetClientAbsOrigin(victim,clientPos);
        if(vteam!=ateam){
            new race_victim=War3_GetRace(victim);
            //new totaldamage=RoundFloat(damage);
            new players[MAXPLAYERS]=0;
            if(race_victim==thisRaceID&&!bIsActive[victim]){    
                if(skill_spirit>0){
                    if(War3_SkillNotInCooldown(victim,thisRaceID,SKILL_SPIRIT,true)){
                        for (new ally=1;ally<=MaxClients;ally++){
                            if(ValidPlayer(ally,true)&& GetClientTeam(ally)==ownerteam&&ally!=victim){
                                GetClientAbsOrigin(ally,allyPos);
                                if(GetVectorDistance(clientPos,allyPos)<LinkRad[skill_spirit]){
                                    if(War3_GetRace(ally)!=War3_GetRaceIDByShortname("wisp")&&War3_GetRace(ally)!=thisRaceID&&!IsSkillImmune(ally)){
                                        if(players[victim]<4){
                                            players[victim]++;
                                            bInRange[ally]=true;
                                        }    
                                        allyPos[2]+=35;
                                        TE_SetupBeamPoints(allyPos,clientPos,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{255,10,10,255},50);
                                        TE_SendToAll();    
                                    }
                                }
                            }
                        }
                        if(players[victim]>0){
                            //new newdamage=totaldamage/(players[victim]+1);
                            new newdamage=RoundFloat((damage/0.8 - damage)/(players[victim]+1));
                            if(newdamage<100){
                                War3_CooldownMGR(victim,1.0,thisRaceID,SKILL_SPIRIT);
                                for (new i=1;i<=MaxClients;i++){
                                    if(bInRange[i] && GetClientTeam(i)==ownerteam && i != victim && !IsSkillImmune(i)){
                                        War3_DealDamage(i,newdamage,attacker,DMG_BULLET,"Spirit Link");
                                        bInRange[i]=false;
                                        // EmitSoundToAll(link_sound,i);
                                
                                    }
                                }
                                PrintToConsole(attacker, "Damage Reduced against Spirit Link");
                                PrintToConsole(victim, "Damage Reduced by Spirit Link");
                            }
                        }
                        else {
                            new newdamage=RoundFloat((damage/0.8) - damage);
                            War3_DealDamage(victim,newdamage,attacker,DMG_BULLET,"Spirit Link");
                            PrintToConsole(victim, "Damage Not Reduced by Spirit Link");
                        }
                    }
                }
            
            }
        
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true)){
        if(!Silenced(client)){
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_ETHREAL,true)){
                new ult_ethreal=War3_GetSkillLevel(client,thisRaceID,ULT_ETHREAL);
                if(ult_ethreal>0){
                    if(War3_SkillNotInCooldown(client,thisRaceID,ULT_ETHREAL,true)){
                        War3_CooldownMGR(client,EthrealCD[ult_ethreal],thisRaceID,ULT_ETHREAL);
                        // EmitSoundToAll(ethreal_sound,client);
                        CreateTimer(3.0,StopEthreal, client);
                        bIsActive[client]=true;
                        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.9);
                        War3_SetBuff(client,fSlow,thisRaceID,0.75);
                        War3_SetBuff(client,fAttackSpeed,thisRaceID,0.75);
                //        War3_SetBuff(client,bDisarm,thisRaceID,true);
                        W3SetPlayerColor(client,thisRaceID,10,10,255,_,GLOW_ULTIMATE);
                        PrintHintText(client, "You're immune now");
                        W3FlashScreen(client,{0,120,255,50});
                    }
                
                }
                else
                {
                    PrintHintText(client, "Level your Ethreal Form first");
                }
            
            }
        }
        else
        {
            PrintHintText(client, "you are silenced");
        }
    }
}

public Action:StopEthreal(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
        bIsActive[client]=false;
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
        War3_SetBuff(client,fSlow,thisRaceID,1.0);
        War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
        //War3_SetBuff(client,bDisarm,thisRaceID,false);
        W3ResetPlayerColor(client,thisRaceID);
        PrintHintText(client, "You're not immune anymore");
        W3FlashScreen(client,{0,120,255,50});
        // EmitSoundToAll(ethreal_sound,client);
    }    
}

public Action:Heal(Handle:timer,any:userid)
{
    for(new client=1;client<=MaxClients;client++){
        if(ValidPlayer(client,true)){
            if(War3_GetRace(client)==thisRaceID){
                new Float:allyPos[3];
                new Float:clientPos[3];
                new ownerteam=GetClientTeam(client);
                new skill_spirit=War3_GetSkillLevel(client,thisRaceID,SKILL_SPIRIT);
                GetClientAbsOrigin(client,clientPos);
                for (new ally=1;ally<=MaxClients;ally++){
                    if(ValidPlayer(ally,true)&& GetClientTeam(ally)==ownerteam&&ally!=client){
                        GetClientAbsOrigin(ally,allyPos);
                        if(GetVectorDistance(clientPos,allyPos)<LinkRad[skill_spirit]){
                            War3_HealToMaxHP(ally,1);
                        }
                    }
                }
            }
        }
    }
}

public bomb_begindefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(bIsActive[client])
    {
        new Float:velocity[3];
        velocity[2]=200.0;
        SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
        PrintHintText(client, "You can not defuse in Ethreal form");
    }
}