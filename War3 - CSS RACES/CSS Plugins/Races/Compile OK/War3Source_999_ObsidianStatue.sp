/**
* File: War3Source_ObsidianStatue.sp
* Description: Obsidian Statue/Destroyer.
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
new MoneyOffsetCS;

new g_iExplosionModel;
new BeamSprite,HaloSprite;
new String:steal_sound[]="war3source/spellbreaker/spellsteal.wav";
/*new String:absorb[]="obsidian/Absorb.wav";
new String:devour[]="obsidian/DevourMagic.wav";
new String:morph[]="obsidian/Morph.wav";
new String:spawn[]="obsidian/Spawn.wav";
new String:spirittouch[]="obsidian/SpiritTouch.wav";
new String:spiritdrain[]="obsidian/SpiritDrain.wav";
new String:orb[]="obsidian/Missile.wav";
*/

//Holy Protection
new Float:DamageReducer[6]={0.0,0.70,0.60,0.55,0.50,0.40};

//Essence of Blight
new Heal[5]={0,1,2,3,4};

//Spirit Touch
new SpiritTouch[6]={0,5,10,15,20,25};
new Float:SpiritRadius = 1200.0;

//Mana Drain
new DrainArea[6]={0,40,80,120,160,200};
new DrainAttack[6]={0,80,160,240,320,400};

//Orb of Annihilation
new OrbDamage[7]={0,5,10,15,20,25};

//Devour Magic
new Float:StealCD[]={0.0,30.0,28.0,26.0,24.0,22.0,20.0};

//Morph
new MorphTime[4]={0,600,450,300};
new MorphHeal[4]={0,15,30,50};
new bool:bStatue[MAXPLAYERS];

//Skills & Ultimate
new SKILL_BLIGHT, SKILL_SPIRIT, SKILL_HOLY, SKILL_ABSORB,SKILL_DEVOUR,SKILL_ORB,ULT_MORPH;
 
public Plugin:myinfo = 
{
    name = "War3Source Race - Obsidian Statue",
    author = "Lucky",
    description = "Obsidian Statue/Destroyer",
    version = "1.1.0.2",
    url = "http://warcraft-source.net/forum/index.php?topic=369.0"
}

public OnPluginStart()
{
    CreateTimer(1.0,mana,_,TIMER_REPEAT);
    CreateTimer(1.0,essence,_,TIMER_REPEAT);
    CreateTimer(1.0,manadrain,_,TIMER_REPEAT);
    MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
}

public OnMapStart()
{
BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
g_iExplosionModel=PrecacheModel("materials/effects/fire_cloud1.vmt");
War3_AddCustomSound(steal_sound);
/*War3_PrecacheSound(absorb);
War3_PrecacheSound(devour);
War3_PrecacheSound(morph);
War3_PrecacheSound(spawn);
War3_PrecacheSound(spirittouch);
War3_PrecacheSound(spiritdrain);
War3_PrecacheSound(orb);*/
}

public OnWar3PluginReady()
{
    
        thisRaceID=War3_CreateNewRace("Obsidian Statue", "obsidian");
        SKILL_BLIGHT=War3_AddRaceSkill(thisRaceID,"Essence of Blight", "Allies close to you are healed",false,4);
        SKILL_SPIRIT=War3_AddRaceSkill(thisRaceID,"Spirit Touch (+Ability)","Give your allies more health by draining yours (Statue)",false,5);
        SKILL_HOLY=War3_AddRaceSkill(thisRaceID,"Holy Protection","You can absorb more damage (Statue)",false,5);
        SKILL_ABSORB=War3_AddRaceSkill(thisRaceID,"Absorb Mana","Steal mana off enemies you attack and those who are close to you",false,5);
        SKILL_DEVOUR=War3_AddRaceSkill(thisRaceID,"Devour magic","Gain your enemy's power yourself (Kill)",false,5);
        SKILL_ORB=War3_AddRaceSkill(thisRaceID,"Orb of Annihilation","Add damage and give your attack an AoE",false,6);
        ULT_MORPH=War3_AddRaceSkill(thisRaceID,"Morph into Destroyer (+Ultimate)","If you have enough mana change into the destroyer",true,3);
        War3_CreateRaceEnd(thisRaceID);
    
}

public OnRaceChanged(client, oldrace, newrace)
{
    if(newrace != thisRaceID){
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3ResetAllBuffRace(client,thisRaceID);
    }
    
    if(newrace == thisRaceID){
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_p228");
        if(ValidPlayer(client,true)){
            GivePlayerItem(client, "weapon_knife");
            GivePlayerItem(client, "weapon_p228");
            bStatue[client]=true;
            War3_SetBuff(client,fSlow,thisRaceID,0.7);
        }
        
    }
    
}

stock GetMoney(player)
{
    return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
    SetEntData(player,MoneyOffsetCS,money);
}

public OnWar3EventSpawn(client)
{
    W3ResetAllBuffRace(client,thisRaceID);
    War3_SetBuff(client,bPerplexed,thisRaceID,false);
    if(War3_GetRace(client)==thisRaceID){
        War3_SetBuff(client,fSlow,thisRaceID,0.7);
        // EmitSoundToAll(spawn,client);
        bStatue[client]=true;
        new money=GetMoney(client);
        SetMoney(client,money/2);
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_p228");
        CreateTimer(2.0, Gun, client);
    }
    
}

public Action:Gun(Handle:timer,any:client)
{
    if(ValidPlayer(client,true)==true){
        GivePlayerItem(client, "weapon_p228");
    }
    
}

public OnWar3EventDeath(victim,attacker)
{
    new race=War3_GetRace(victim);
    
    if(race==thisRaceID){
        new money=GetMoney(victim);
        bStatue[victim]=true;
        SetMoney(victim,money/2);
        War3_SetBuff(victim,fMaxSpeed,thisRaceID,1.0);
        War3_WeaponRestrictTo(victim,thisRaceID,"weapon_knife,weapon_p228");
    }
    
    if(War3_GetRace(attacker)==thisRaceID)
    {
        new skill_devour=War3_GetSkillLevel(attacker,thisRaceID,SKILL_DEVOUR);
        if(skill_devour>0)
        {
            if(War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_DEVOUR,true))
            {
                CheckBuffs(attacker, victim);
                new Float:start_pos[3];
                GetClientAbsOrigin(attacker,start_pos);
                start_pos[2]+=30.0;
                new Float:target_pos[3];
                GetClientAbsOrigin(victim,target_pos);
                target_pos[2]+=30.0;
                TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,HaloSprite,0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
                TE_SendToAll();
                EmitSoundToAll(steal_sound, attacker);
                EmitSoundToAll(steal_sound, victim);
                War3_CooldownMGR(attacker,StealCD[skill_devour],thisRaceID,SKILL_DEVOUR);
            }
        }
    }
}


public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam){
            new race_attacker=War3_GetRace(attacker);
                        
            if(race_attacker==thisRaceID &&!bStatue[attacker]){
                new skill_absorb=War3_GetSkillLevel(attacker,thisRaceID,SKILL_ABSORB);
                if(skill_absorb>0&&!W3HasImmunity(victim,Immunity_Skills)){
                    new money_victim=GetMoney(victim);
                    new money_attacker=GetMoney(attacker);
                    new Float:pos[3]; 
                    GetClientAbsOrigin(attacker,pos);
                    pos[2]+=30;
                    new Float:targpos[3];
                    GetClientAbsOrigin(victim,targpos);
                    targpos[2]+=30;
                    if(money_victim>0){
                        TE_SetupBeamPoints(pos, targpos, HaloSprite, HaloSprite, 0, 8, 0.8, 2.0, 10.0, 10, 10.0, {0,120,255,100}, 70); 
                        TE_SendToAll();
        //                EmitSoundToAll(absorb,attacker);
        //                EmitSoundToAll(absorb,victim);
                        SetMoney(victim,money_victim-DrainAttack[skill_absorb]);
                        SetMoney(attacker,money_attacker+DrainAttack[skill_absorb]);
                    }
                }
                new skill_orb=War3_GetSkillLevel(attacker,thisRaceID,SKILL_ORB);
                if(skill_orb>0&&!W3HasImmunity(victim,Immunity_Skills)&&War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_ORB)){    
                        new Float:position[3];
                        new randomDamage=GetRandomInt(0,OrbDamage[skill_orb]);
                        GetClientAbsOrigin(victim,position);
                        position[2]+=50;
                        TE_SetupExplosion(position, g_iExplosionModel, 10.0, 10, TE_EXPLFLAG_NONE, 200, 255);
                        TE_SendToAll();
                        War3_DealDamage(victim,randomDamage,attacker,DMG_BULLET,"Orb of Annihilation");
                        CreateTimer(0.1,annihilation,victim);
        //                EmitSoundToAll(orb,attacker);
        //                EmitSoundToAll(orb,victim);
                        War3_CooldownMGR(attacker,10.0,thisRaceID,SKILL_ORB,_,_ );
                }
                
            }
            
        }
        
    }
    
}

public CheckBuffs(any: attacker, any:victim)
{
    new Float:victim_gravity=W3GetBuffMinFloat(victim,fLowGravitySkill);
    new Float:victim_speed=W3GetBuffMaxFloat(victim,fMaxSpeed);
    new Float:victim_attack=W3GetBuffStackedFloat(victim,fAttackSpeed);
    new Float:victim_invisibility = W3GetBuffMinFloat(victim,fInvisibilitySkill);
    new Float:attacker_gravity=W3GetBuffMinFloat(attacker,fLowGravitySkill);
    new Float:attacker_speed=W3GetBuffMaxFloat(attacker,fMaxSpeed);
    new Float:attacker_attack=W3GetBuffStackedFloat(attacker,fAttackSpeed);
    new Float:attacker_invisibility = W3GetBuffMinFloat(attacker,fInvisibilitySkill);
    
    if(victim_gravity<attacker_gravity){
        War3_SetBuff(attacker,fLowGravitySkill,thisRaceID,victim_gravity);
        PrintHintText(attacker, "You have stolen your opponent's gravity (%f)",victim_gravity);
    }
    if(victim_speed>attacker_speed){
        War3_SetBuff(attacker,fMaxSpeed,thisRaceID,victim_speed);
        PrintHintText(attacker, "You have stolen your opponent's speed (%f)",victim_speed);
    }
    
    if(victim_attack>attacker_attack){
        War3_SetBuff(attacker,fAttackSpeed,thisRaceID,victim_attack);
        PrintHintText(attacker, "You have stolen your opponent's attack speed (%f)",victim_attack);
    }
    
    if(victim_invisibility<attacker_invisibility){
        War3_SetBuff(attacker,fInvisibilitySkill,thisRaceID,victim_invisibility);
        PrintHintText(attacker, "You have stolen your opponent's invisibility (%f)",victim_invisibility);
    }
}

public Action:annihilation(Handle:timer,any:client) {
    for(new client1=1;client1<=MaxClients;client1++){
        if(ValidPlayer(client1,true)&&War3_GetRace(client1)==thisRaceID){
            for(new i=1;i<=MaxClients;i++){
                if(ValidPlayer(i,true)&&War3_GetRace(i)!=thisRaceID){    
                    new clientteam=GetClientTeam(client);
                    new iteam=GetClientTeam(i);
                    if(iteam==clientteam){
                        new Float:iPosition[3];
                        new Float:clientPosition[3];
                        GetClientAbsOrigin(i, iPosition);
                        GetClientAbsOrigin(client, clientPosition);
                        if(!W3HasImmunity(i,Immunity_Skills)){
                            if(GetVectorDistance(iPosition,clientPosition)<300){
                                new skill_orb=War3_GetSkillLevel(client1,thisRaceID,SKILL_ORB);
                                new randomDamage=GetRandomInt(0,OrbDamage[skill_orb]);
                                War3_DealDamage(i,randomDamage,client1,DMG_CRUSH,"Orb of Annihilation",_,W3DMGTYPE_MAGIC);
                            }
                        }
                    }
                }
            }
        }
    }
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam){
            new race_victim=War3_GetRace(victim);
            new skill_holy=War3_GetSkillLevel(victim,thisRaceID,SKILL_HOLY);
            
            if(race_victim==thisRaceID && skill_holy>0 && bStatue[victim]){    
                War3_DamageModPercent(DamageReducer[skill_holy]);
            }
            
        }
        
    }
    
}

public Action:mana(Handle:timer,any:client)
{
    if(thisRaceID>0){
        for(new i=1;i<=MaxClients;i++){
            if(ValidPlayer(i,true)){
                if(War3_GetRace(i)==thisRaceID){
                    new money=GetMoney(i);
                    
                    if(bStatue[i]){
                        if(money>=6000){
                        }
                        else
                        {
                            SetMoney(i,money+100);
                        }
                    
                    }
                    else
                    {
                        new ult_morph=War3_GetSkillLevel(i,thisRaceID,ULT_MORPH);
                        new money_after=money-MorphTime[ult_morph];
                        if(money_after<=0){
                            bStatue[i]=true;
                            War3_CooldownMGR(i,10.0,thisRaceID,ULT_MORPH,_,_ );
                            SetMoney(i,0);
                            War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
                            War3_SetBuff(i,fSlow,thisRaceID,0.7);
                            DropWeapon(i);
                            War3_WeaponRestrictTo(i,thisRaceID,"weapon_knife,weapon_p228");
                            GivePlayerItem(i, "weapon_p228");
        //                    EmitSoundToAll(morph,i);
                        }
                        else
                        {
                            SetMoney(i,money-MorphTime[ult_morph]);
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}

public Action:essence(Handle:timer)
{
    for(new client=1;client<=MaxClients;client++){
        if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID&&bStatue[client]){
            for(new target=1;target<=MaxClients;target++){
                if(ValidPlayer(target,true)){
                    new clientteam=GetClientTeam(client);    
                    new targetteam=GetClientTeam(target);    
                    if(clientteam==targetteam ){
                        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_BLIGHT);
                        if(skill_level>0){
                            new Float:pos[3]; 
                            GetClientAbsOrigin(client,pos);
                            pos[2]+=30;
                            new Float:targpos[3];
                            GetClientAbsOrigin(target,targpos);
                            targpos[2]+=30;
                            if(GetVectorDistance(pos,targpos)<600){
                                if(War3_GetRace(target)!=thisRaceID){
                                if(War3_GetMaxHP(target)>GetClientHealth(target)){    
                                    TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 0.8, 2.0, 10.0, 10, 10.0, {0,155,20,100}, 70); 
                                    TE_SendToAll();
                                    War3_HealToMaxHP(target,Heal[skill_level]);    
                                }
                                }
                            }

                        }
                    }
                }
            }
        }
    }
    
}

public Action:manadrain(Handle:timer)
{
    for(new client=1;client<=MaxClients;client++){
        if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID&&!bStatue[client]){
            for(new target=1;target<=MaxClients;target++){
                if(ValidPlayer(target,true)){
                    new clientteam=GetClientTeam(client);    
                    new targetteam=GetClientTeam(target);    
                    if(clientteam!=targetteam ){
                        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_ABSORB);
                        if(skill_level>0){
                            new Float:pos[3]; 
                            GetClientAbsOrigin(client,pos);
                            pos[2]+=30;
                            new Float:targpos[3];
                            GetClientAbsOrigin(target,targpos);
                            targpos[2]+=30;
                            if(GetVectorDistance(pos,targpos)<400){
                                new money_target=GetMoney(target);
                                new money_client=GetMoney(client);
                                if(money_target>0){
                                    TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 0.8, 2.0, 10.0, 10, 10.0, {0,120,255,100}, 70); 
                                    TE_SendToAll();
                                    SetMoney(target,money_target-DrainArea[skill_level]);
                                    SetMoney(client,money_client+DrainArea[skill_level]);
                                }
                                
                            }

                        }
                    }
                }
            }
        }
    }
    
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(!Silenced(client)){
        if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
            if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SPIRIT,true)){
                new skill_spirit=War3_GetSkillLevel(client,thisRaceID,SKILL_SPIRIT);
                    
                if(skill_spirit>0){        
                    if(bStatue[client]){
        //                EmitSoundToAll(spiritdrain,client);
                        War3_CooldownMGR(client,15.0,thisRaceID,SKILL_SPIRIT,_,_ );
                        new health=SpiritTouch[skill_spirit];
                        War3_DealDamage(client,health,client,DMG_BULLET,"Spirit Touch");
                        new money=GetMoney(client);
                        new gain=health*20;
                        SetMoney(client,money+gain);
                        new Float:iPos[3] = {0.0,0.0,0.0};
                        new Float:targetPos[3] = {0.0,0.0,0.0};
                        for(new i=1;i<=MaxClients;i++){
                            if(ValidPlayer(i,true)&&War3_GetRace(i)==thisRaceID){
                                GetClientAbsOrigin(i, iPos);
                                for(new target=1;target<=MaxClients;target++){
                                    if(ValidPlayer(target,true)){
                                        GetClientAbsOrigin(target, targetPos);
                                        new clientteam=GetClientTeam(i);    
                                        new targetteam=GetClientTeam(target);    
                                        
                                        if(clientteam==targetteam && GetVectorDistance(iPos,targetPos) <= SpiritRadius){
                                            if(War3_GetRace(target)!=thisRaceID){
                                                if(War3_GetRace(target)!=War3_GetRaceIDByShortname("wisp")){
                                                    SetEntityHealth(target,GetClientHealth(target)+SpiritTouch[skill_spirit]);
        //                                            EmitSoundToAll(spirittouch,target);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        PrintHintText(client, "Only the statue can use this ability");
                    }
                    
                }
                else
                {
                    PrintHintText(client, "Level your Spirit Touch first");
                }
                
            }
            
        }
        
    }
    else
    {
        PrintHintText(client,"Silenced: Can not cast");
    }
    
}

public OnUltimateCommand(client,race,bool:pressed)
{
    
    if(race==thisRaceID && pressed && ValidPlayer(client)){
        new ult_morph=War3_GetSkillLevel(client,thisRaceID,ULT_MORPH);
    
        
        if(ult_morph>0){
    
            if(!Silenced(client)){
                if(War3_SkillNotInCooldown(client,thisRaceID,ULT_MORPH,true)){ 
                    if(bStatue[client]){
                        new money=GetMoney(client);
                        
                        if(money>=6000){
        //                    EmitSoundToAll(morph,client);
                            bStatue[client]=false;
                            War3_SetBuff(client,fSlow,thisRaceID,1.0);
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
                            SetEntityHealth(client,GetClientHealth(client)+MorphHeal[ult_morph]);
                            DropWeapon(client);
                            War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_deagle");
                            GivePlayerItem(client, "weapon_deagle");
                        }
                        else
                        {
                            PrintHintText(client, "Not enough mana yet");
                        }
                        
                    }
                    else
                    {
                        PrintHintText(client, "You are already the destroyer");
                    }
                    
                }
                
            }
            else
            {
                PrintHintText(client, "Silenced can not cast");
            }
            
        }
        else
        {
            PrintHintText(client, "Level your ultimate first");
        }
        
    }
    
}



public DropWeapon(client)
{
	new iWeapon = GetPlayerWeaponSlot(client, 1);  
	if(IsValidEntity(iWeapon))
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}