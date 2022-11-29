/**
* File: War3Source_RogueWizard.sp
* Description: Wizard race of warcraft.
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
new m_vecBaseVelocity;

//Frost
new FrostCost[]={0,250,500,750,1000,1250,1500,1750,2000,2250,2500};
new FrostDamage[]={0,5,7,9,11,13,15,17,19,21,23};
new bool:bOrb[MAXPLAYERS];

//Fire
new FireCost[]={0,750,1500,2250,3000,3750,4500,5250,6000,6750,7500};
new FireDamage[]={0,30,35,40,45,50,55,60,65,70,75};
new Float:FireTime[]={0.0,0.5,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0};

//Lightning
new LightningCost[]={0,1000,2000,3000,4000,4500,5000,6000,6500,7000,8000};
new LightningDamage[]={0,10,15,18,20,25,28,30,35,38,40};
new Float:LightningDistance[]={0.0,400.0,450.0,500.0,550.0,600.0,650.0,700.0,750.0,800.0,850.0};
new bool:bBeenHit[MAXPLAYERS][MAXPLAYERS];

//Tornado
new TornadoCost[]={0,500,1000,1500,2000,2500,3000,3500,4000,4500,5000};
new Float:TornadoTime[]={0.0,0.5,0.7,0.9,1.1,1.3,1.5,1.7,1.9,2.2,2.5};
new TornadoRange[]={0,300,350,400,450,500,550,600,650,700,750};

//Training
new Float:Cooldown[]={15.0,14.0,13.0,12.0,11.0,10.0,9.0,8.0,7.0,6.0,5.0};
new MoneyGain[]={100,150,200,250,300,350,400,450,500,550,600};
new MoneyMax[]={16000,20000,25000,30000,35000,40000,45000,50000,55000,60000,65000};

//Mana Shield
new Float:ShieldChance[]={0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0};
new DamageDeplete[]={0,200,195,190,185,180,175,170,165,160,150};
new Float:DamageReducer[]={0.0,0.95,0.90,0.85,0.80,0.75,0.70,0.65,0.60,0.55,0.50};

//Magical Pressure
new bool:bIsPressure[MAXPLAYERS];
new bool:bWasPressure[MAXPLAYERS];
new Float:PressureTime[]={0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0};

new BurnSprite, ShieldSprite;
new BeamSprite,HaloSprite;
new String:frost[]="war3source/roguewizard/frost.wav";
new String:fire[]="war3source/roguewizard/fire.wav";
new String:shield[]="war3source/roguewizard/shield.wav";
new String:tornado[]="war3source/roguewizard/tornado.wav";
new String:lightning[]="war3source/roguewizard/lightning.wav";
new String:pressure[]="war3source/roguewizard/avatar.wav";

//Skills & Ultimate
new SKILL_TRAINING, SKILL_SHIELD, SKILL_FROST, SKILL_LIGHTNING,SKILL_TORNADO,SKILL_FIREBALL,ULT_PRESSURE;
 
public Plugin:myinfo = 
{
    name = "War3Source Race - Rogue Wizard",
    author = "Lucky",
    description = "Wizard race of warcraft",
    version = "1.0.0.2",
    url = "http://warcraft-source.net/forum/index.php?topic=371.0"
}

public OnPluginStart()
{
    CreateTimer(1.0,mana,_,TIMER_REPEAT);
    CreateTimer(1.0,ultimate,_,TIMER_REPEAT);
    MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
}

public OnMapStart()
{
BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
ShieldSprite=PrecacheModel("sprites/strider_blackball.vmt");
BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
War3_AddCustomSound(frost);
War3_AddCustomSound(fire);
War3_AddCustomSound(shield);
War3_AddCustomSound(tornado);
War3_AddCustomSound(lightning);
War3_AddCustomSound(pressure);
}


public OnWar3PluginReady()
{
    
        thisRaceID=War3_CreateNewRace("RogueWizard", "rw");
        SKILL_TRAINING=War3_AddRaceSkill(thisRaceID,"Adept Training (Passive)", "Become a better wizard",false,10);
        SKILL_SHIELD=War3_AddRaceSkill(thisRaceID,"Mana Shield (Auto-Cast)","Sacrifice mana to protect yourself from damage",false,10);
        SKILL_FIREBALL=War3_AddRaceSkill(thisRaceID,"Fireball (Ability)","Create a fire ball and throw it at your enemy",false,10);
        SKILL_LIGHTNING=War3_AddRaceSkill(thisRaceID,"Forked Lightning (Ability1)","Shock your enemies",false,10);
        SKILL_FROST=War3_AddRaceSkill(thisRaceID,"Orb of Frost (Ability2)","Create a ball of pure ice and attack your enemy",false,10);
        SKILL_TORNADO=War3_AddRaceSkill(thisRaceID,"Tornado (Ability3)","Summon a tornado to stun people who are close to you",false,10);
        ULT_PRESSURE=War3_AddRaceSkill(thisRaceID,"Magical Pressure (Ultimate)","Damage your health for a short time to increase mana generation",true,10);
        War3_CreateRaceEnd(thisRaceID);
    
}

public OnRaceChanged(client, oldrace, newrace)
{
    if(newrace != thisRaceID){
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3ResetAllBuffRace(client,thisRaceID);
    }
    
    if(newrace == thisRaceID){
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
        if(ValidPlayer(client,true)){
            GivePlayerItem(client, "weapon_knife");
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
    if(War3_GetRace(client)==thisRaceID){
        bOrb[client]=false;
        SetMoney(client,0);
        bIsPressure[client]=false;
        bWasPressure[client]=false;
    }
    
}

public OnWar3EventDeath(victim,attacker)
{
    new race_victim=War3_GetRace(victim);
    
    if(race_victim==thisRaceID){
        SetMoney(victim,0);
    }
    
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam){
            new race_attacker=War3_GetRace(attacker);
            new skill_frost=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROST);
            // Orb of frost
            if(race_attacker==thisRaceID && skill_frost>0 && bOrb[attacker]){
                if(!W3HasImmunity(victim,Immunity_Skills)){
                    War3_DealDamage(victim,FrostDamage[skill_frost],attacker,DMG_BULLET,"Orb of Frost");
                    War3_SetBuff(victim,fAttackSpeed,thisRaceID,0.6);
                    War3_SetBuff(victim,fSlow,thisRaceID,0.6);
                    EmitSoundToAll(frost,attacker);
                    EmitSoundToAll(frost,victim);
                    CreateTimer(5.0,Orb,victim);
                }
                
            }
            
        }
        
    }
    
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
//public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam){
            new race_victim=War3_GetRace(victim);
            new skill_shield=War3_GetSkillLevel(victim,thisRaceID,SKILL_SHIELD);
            
            if(race_victim==thisRaceID && skill_shield>0){
                if(War3_SkillNotInCooldown(victim,thisRaceID,SKILL_SHIELD,true) && !W3HasImmunity( attacker, Immunity_Skills )){
                    if(GetRandomFloat(0.0,1.0)<=ShieldChance[skill_shield]){
                        new Float:pos[3];
                        new money=GetMoney(victim);
                        new ddamage=RoundFloat(damage*DamageDeplete[skill_shield]);
                    
                        GetClientAbsOrigin(victim,pos);
                        pos[2]+=35;
                        TE_SetupGlowSprite(pos, ShieldSprite, 0.1, 1.0, 130);
                        TE_SendToAll();
                        EmitSoundToAll(shield,attacker);
                        EmitSoundToAll(shield,victim);
                        if(money>=ddamage){
                            new new_money;
                            War3_DamageModPercent(0.0);            
                            // War3_DealDamage( victim, 0, attacker, DMG_BULLET, "Mana Shield" );
                            new_money=money-ddamage;
                            SetMoney(victim,new_money);
                            PrintToConsole(attacker, "Damage Reduced against Rogue Wizard");
                            PrintToConsole(victim, "Damage blocked by Rogue Wizard.  Original damage |%.2f|, money spent to save you |%d|", damage, ddamage);
                        }
                        else
                        {
                            War3_CooldownMGR(victim,5.0,thisRaceID,SKILL_SHIELD);
                            SetMoney(victim,0);
                            new temp = RoundFloat(damage*DamageReducer[skill_shield]);
                            War3_DamageModPercent(DamageReducer[skill_shield]);
                            PrintHintText(victim,"Mana Shield: Depleted!");
                            PrintToConsole(attacker, "Damage Reduced against Mana Shield Rogue Wizard");
                            PrintToConsole(victim, "Damage reduced by Rogue Wizard.  Original damage |%.2f|, modified damage |%d|", damage, temp);
                        }
                    
                    }
                }
            }
            
        }
        
    }
    
}

public Action:mana(Handle:timer,any:client)
{
    for(new user=1;user<=MaxClients;user++){
        if(ValidPlayer(user,true)){
            if(War3_GetRace(user)==thisRaceID){
                new skill_training=War3_GetSkillLevel(user,thisRaceID,SKILL_TRAINING);
                new money=GetMoney(user);
                if(money<MoneyMax[skill_training]){
                    if(bWasPressure[user]){
                        SetMoney(user,money+MoneyGain[skill_training]/2);
                    }
                    else
                    {
                        if(!bIsPressure[user]){
                            SetMoney(user,money+MoneyGain[skill_training]);
                        }
                        else
                        {
                            SetMoney(user,money+MoneyGain[skill_training]*2);
                        }
                    }
                }
                else
                {
                    if(bIsPressure[user]){
                    SetMoney(user,money+MoneyGain[skill_training]*2);
                    }
                }    
            }        
        }
    }
}

public Action:ultimate(Handle:timer,any:client)
{
    for(new user=1;user<=MaxClients;user++){
        if(ValidPlayer(user,true)){
            if(War3_GetRace(user)==thisRaceID){
                if(bWasPressure[user]){
                    War3_HealToMaxHP(user,5);
                }
                else
                {
                    if(bIsPressure[user]){
                        War3_DealDamage(user,5,user,DMG_BULLET,"Magical Pressure");
                    }    
                }    
            }    
        }
    }    
}

public Action:Restrict(Handle:timer,any:client)
{
    bOrb[client]=false;
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
}

public Action:Orb(Handle:timer,any:victim)
{
    War3_SetBuff(victim,fSlow,thisRaceID,1.0);
    War3_SetBuff(victim,fAttackSpeed,thisRaceID,1.0);
}

public Action:Stop(Handle:timer,any:client)
{
    StopSound(client,SNDCHAN_AUTO,lightning);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID){
        if(!Silenced(client) &&  ValidPlayer(client, true)){
            new money=GetMoney(client);
            new skill_training=War3_GetSkillLevel(client,thisRaceID,SKILL_TRAINING);
            
            if(ability==0 && pressed && IsPlayerAlive(client)){
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_FIREBALL,true)){
                    new target = War3_GetTargetInViewCone(client,9000.0,false,20.0);
                    new skill_fire=War3_GetSkillLevel(client,thisRaceID,SKILL_FIREBALL);
                        
                    if(skill_fire>0){
                        if(money>=FireCost[skill_fire]){            
                            EmitSoundToAll(fire,client);
                            SetMoney(client,money-FireCost[skill_fire]);
                            War3_CooldownMGR(client,Cooldown[skill_training],thisRaceID,SKILL_FIREBALL);
                            if(target>0 && !W3HasImmunity(target,Immunity_Skills)){
                                new Float:origin[3];
                                new Float:targetpos[3];
                                
                                GetClientAbsOrigin(target,targetpos);
                                GetClientAbsOrigin(client,origin);
                                TE_SetupBeamPoints(origin, targetpos, BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
                                TE_SendToAll();
                                GetClientAbsOrigin(target,targetpos);
                                targetpos[2]+=70;
                                TE_SetupGlowSprite(targetpos,BurnSprite,1.0,1.9,255);
                                TE_SendToAll();
                                EmitSoundToAll(fire,target);
                                War3_DealDamage(target,FireDamage[skill_fire],client,DMG_BULLET,"Fireball");
                                IgniteEntity(target, FireTime[skill_fire]);
                            }
                            else
                            {
                                new Float:origin[3];
                                new Float:targetpos[3];
                                
                                War3_GetAimEndPoint(client,targetpos);
                                GetClientAbsOrigin(client,origin);
                                TE_SetupBeamPoints(origin, targetpos, BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
                                TE_SendToAll();
                                War3_GetAimEndPoint(client,targetpos);
                                targetpos[2]+=70;
                                TE_SetupGlowSprite(targetpos,BurnSprite,1.0,1.9,255);
                                TE_SendToAll();
                            }
                            
                        }
                        else
                        {
                        PrintHintText(client, "You don't have enough mana");
                        }
                        
                    }
                    else
                    {
                        PrintHintText(client, "Level your fireball first");
                    }
                    
                }
                
            }
            
            if(ability==1 && pressed && IsPlayerAlive(client)){
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_LIGHTNING,true)){
                    new skill_lightning=War3_GetSkillLevel(client,thisRaceID,SKILL_LIGHTNING);
                    
                    if(skill_lightning>0){
                        if(money>=LightningCost[skill_lightning]){
                            for(new target=0;target<MAXPLAYERS;target++)
                                bBeenHit[client][target]=false;
                                
                            new target = War3_GetTargetInViewCone(client,LightningDistance[skill_lightning],false,20.0);
                            
                            if(target>0 && !W3HasImmunity(target,Immunity_Skills)){
                                new Float:distance=LightningDistance[skill_lightning];
                                new Float:target_pos[3];
                                new Float:start_pos[3];
                                
                                GetClientAbsOrigin(target,target_pos);                        
                                GetClientAbsOrigin(client,start_pos);
                                TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,BeamSprite,0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
                                TE_SendToAll();
                                EmitSoundToAll(lightning,client,SNDCHAN_AUTO);
                                CreateTimer(2.0, Stop, client);
                                DoChain(client,distance,LightningDamage[skill_lightning],true,0);                            
                                War3_CooldownMGR(client,Cooldown[skill_training],thisRaceID,SKILL_LIGHTNING);
                            }
                            else
                            {
                                PrintHintText(client, "Not Close enough");
                            }
                            
                        }
                        else
                        {
                            PrintHintText(client, "You don't have enough mana");
                        }
                        
                    }
                    else
                    {
                        PrintHintText(client, "Level your forked lightning first");
                    }
                    
                }
                
            }
            
            if(ability==2 && pressed && IsPlayerAlive(client)){
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_FROST,true)){
                    new skill_frost=War3_GetSkillLevel(client,thisRaceID,SKILL_FROST);
                        
                    if(skill_frost>0){
                        if(money>=FrostCost[skill_frost]){
                            SetMoney(client,money-FrostCost[skill_frost]);
                            War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_hegrenade");
                            GivePlayerItem(client,"weapon_hegrenade");
                            bOrb[client]=true;
                            CreateTimer(5.0,Restrict,client);
                            War3_CooldownMGR(client,Cooldown[skill_training],thisRaceID,SKILL_FROST);
                        }
                        else
                        {
                            PrintHintText(client, "You don't have enough mana");
                        }
                        
                    }
                    else
                    {
                        PrintHintText(client, "Level your orb of Frost first");
                    }
                    
                }
                
            }
            
            if(ability==3 && pressed && IsPlayerAlive(client)){
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_TORNADO,true)){
                    new skill_tornado=War3_GetSkillLevel(client,thisRaceID,SKILL_TORNADO);
                    
                    if(skill_tornado>0){
                        if(money>=TornadoCost[skill_tornado]){
                            new Float:position[3];
                            
                            EmitSoundToAll(tornado,client);
                            SetMoney(client,money-TornadoCost[skill_tornado]);
                            War3_CooldownMGR(client,Cooldown[skill_training],thisRaceID,SKILL_TORNADO);
                            GetClientAbsOrigin(client, position);
                            position[2]+=10;
                            TE_SetupBeamRingPoint(position,0.0,TornadoRange[skill_tornado]*2.0,BeamSprite,HaloSprite,0,15,0.3,20.0,3.0,{100,100,150,255},20,0);
                            TE_SendToAll();
                            GetClientAbsOrigin(client,position);
                            TE_SetupBeamRingPoint(position, 20.0, 80.0,BeamSprite,BeamSprite, 0, 5, 2.6, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
                            TE_SendToAll();
                            position[2]+=20.0;
                            TE_SetupBeamRingPoint(position, 40.0, 100.0,BeamSprite,BeamSprite, 0, 5, 2.4, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
                            TE_SendToAll();
                            position[2]+=20.0;
                            TE_SetupBeamRingPoint(position, 60.0, 120.0,BeamSprite,BeamSprite, 0, 5, 2.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                            TE_SendToAll();
                            position[2]+=20.0;
                            TE_SetupBeamRingPoint(position, 80.0, 140.0,BeamSprite,BeamSprite, 0, 5, 2.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                            TE_SendToAll();    
                            position[2]+=20.0;
                            TE_SetupBeamRingPoint(position, 100.0, 160.0,BeamSprite,BeamSprite, 0, 5, 1.8, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                            TE_SendToAll();    
                            position[2]+=20.0;
                            TE_SetupBeamRingPoint(position, 120.0, 180.0,BeamSprite,BeamSprite, 0, 5, 1.6, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                            TE_SendToAll();    
                            position[2]+=20.0;
                            TE_SetupBeamRingPoint(position, 140.0, 200.0,BeamSprite,BeamSprite, 0, 5, 1.4, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                            TE_SendToAll();    
                            position[2]+=20.0;
                            TE_SetupBeamRingPoint(position, 160.0, 220.0,BeamSprite,BeamSprite, 0, 5, 1.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                            TE_SendToAll();    
                            position[2]+=20.0;
                            TE_SetupBeamRingPoint(position, 180.0, 240.0,BeamSprite,BeamSprite, 0, 5, 1.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                            TE_SendToAll();
                            for(new target=0;target<=MaxClients;target++){
                                if(ValidPlayer(target,true)){
                                    new client_team=GetClientTeam(client);
                                    new target_team=GetClientTeam(target);
                        
                                    if(target_team!=client_team){
                                        new Float:targetPos[3];
                                        new Float:clientPos[3];
                                    
                                        GetClientAbsOrigin(target, targetPos);
                                        GetClientAbsOrigin(client, clientPos);
                                        if(!W3HasImmunity(target,Immunity_Skills)){
                                            if(GetVectorDistance(targetPos,clientPos)<TornadoRange[skill_tornado]){
                                                new Float:velocity[3];
                                        
                                                velocity[2]+=800.0;
                                                SetEntDataVector(target,m_vecBaseVelocity,velocity,true);                                    
                                                CreateTimer(0.1,Tornado1,target);
                                                CreateTimer(0.4,Tornado2,target);
                                                CreateTimer(1.0,Stun,target);
                                                CreateTimer(TornadoTime[skill_tornado]+2.0,Unstunned,target);
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        else
                        {
                            PrintHintText(client, "You don't have enough mana");
                        }
                        
                    }
                    else
                    {
                        PrintHintText(client, "Level your tornado first");
                    }
                    
                }
                
            }
            
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
        }
    }
}

public DoChain(client,Float:distance,dmg,bool:first_call,last_target)
{
    new target=0;
    new Float:target_dist=distance+1.0;
    new caster_team=GetClientTeam(client);
    new Float:start_pos[3];
    new skill_lightning=War3_GetSkillLevel(client,thisRaceID,SKILL_LIGHTNING);
    
    if(last_target<=0)
        GetClientAbsOrigin(client,start_pos);
    else
        GetClientAbsOrigin(last_target,start_pos);
        
    for(new x=1;x<=MaxClients;x++){
        if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Skills)){
            new Float:this_pos[3];
            
            GetClientAbsOrigin(x,this_pos);
            new Float:dist_check=GetVectorDistance(start_pos,this_pos);
            
            if(dist_check<=target_dist){
                target=x;
                target_dist=dist_check;
            }
            
        }
        
    }
    
    if(target>0){
        bBeenHit[client][target]=true;
        War3_DealDamage(target,LightningDamage[skill_lightning],client,DMG_ENERGYBEAM,"Forked Lightning");
        start_pos[2]+=30.0;
        new Float:target_pos[3];
        GetClientAbsOrigin(target,target_pos);
        target_pos[2]+=30.0;
        TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,BeamSprite,0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
        TE_SendToAll();
        EmitSoundToAll(lightning,target,SNDCHAN_AUTO);
        CreateTimer(2.0, Stop, target);
        new new_dmg=RoundFloat(float(dmg)*0.66);
        DoChain(client,distance,new_dmg,false,target);    
    }
    
}

public Action:Tornado1(Handle:timer,any:client)
{
    new Float:velocity[3];
    
    velocity[2]+=4.0;
    velocity[0]-=600.0;
    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:Tornado2(Handle:timer,any:client)
{
    new Float:velocity[3];
    
    velocity[2]+=4.0;
    velocity[0]+=600.0;
    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:Stun(Handle:timer,any:victim)
{
    War3_SetBuff(victim,bBashed,thisRaceID,true);
}

public Action:Unstunned(Handle:timer,any:victim)
{
    War3_SetBuff(victim,bBashed,thisRaceID,false);
}

public Action:Pressure(Handle:timer,any:client)
{
    new ult_pressure=War3_GetSkillLevel(client,thisRaceID,ULT_PRESSURE);
        
    bIsPressure[client]=false;
    bWasPressure[client]=true;
    CreateTimer(PressureTime[ult_pressure],Healing,client);
}

public Action:Healing(Handle:timer,any:client)
{
    bWasPressure[client]=false;    
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(!Silenced(client)){
        if(race==thisRaceID && pressed && IsPlayerAlive(client)){
            new ult_pressure=War3_GetSkillLevel(client,thisRaceID,ULT_PRESSURE);
        
            if(ult_pressure>0){
                if(War3_SkillNotInCooldown(client,thisRaceID,ULT_PRESSURE,true)){ 
                    EmitSoundToAll(pressure,client);
                    bIsPressure[client]=true;
                    CreateTimer(PressureTime[ult_pressure],Pressure,client);
                    War3_CooldownMGR(client,40.0,thisRaceID,ULT_PRESSURE,true,true);
                }
            }
            else
            {
                PrintHintText(client, "Level your ultimate first");
            }
        }
    }
    else
    {
        PrintHintText(client, "Silenced can not cast");
    }
}