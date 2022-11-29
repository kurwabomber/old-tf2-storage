/**
* File: War3Source_999_Star Wars.sp
* Description: Anakin and Darth Vader Races for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions"

#define WEAPON_RESTRICT "weapon_knife"

new anakinRaceID, darthRaceID;
new SKILL_ANAKIN1, SKILL_ANAKIN2, SKILL_ANAKIN3, ULT_ANAKIN;
new SKILL_DARTH1, SKILL_DARTH2, SKILL_DARTH3, ULT_DARTH;




public Plugin:myinfo = 
{
    name = "War3Source Races - Star Wars - Anakin & Darth Vader",
    author = "Remy Lebeau",
    description = "2 Races in one that can swap between.  spraynpray's races",
    version = "0.9",
    url = "http://sevensinsgaming.com"
};


new Float:g_fDamageMultiplier[] = { 0.0, 0.20, 0.30, 0.4, 0.5 };
new GlowSprite, HaloSprite, AttackSprite1, HealSprite, BeamSprite;
new m_vecBaseVelocity;
new Float:g_fAnakinPullCooldown[] = {0.0, 40.0, 30.0, 20.0, 15.0};
new Float:FlyDuration = 1.8;
new GravForce[] = { 0, 1, 1, 1, 2 };
new String:sound1[] = "weapons/physcannon/physcannon_pickup.wav";
new String:sound2[] = "weapons/physcannon/energy_bounce1.wav";
new Float:HealingDistance=500.0;
new g_iAnakinHealAmount[] = { 0, 10, 20, 30, 40 };
new Float:g_fAnakinHealCooldown[] = {0.0, 40.0, 35.0, 30.0, 25.0};

//Lightning
new LightningDamage[]={0,15,20,25,30};
new Float:LightningDistance[]={0.0,150.0,200.0,300.0,400.0};
new bool:bBeenHit[MAXPLAYERS][MAXPLAYERS];
new String:lightning[]="war3source/roguewizard/lightning.wav";
new Float:g_fDarthLightningCooldown[]={0.0, 35.0, 30.0, 25.0, 20.0};


new g_iDarthChokeDamage[]={0,10,15,20,25};
new Float:g_fDarthChokeCooldown[]={0.0, 35.0, 30.0, 25.0, 20.0};
new Float:g_fDarthChokeStunTime = 0.4;
new Float:g_fDarthChokeStunChance = 0.2;


//Control Magic
//new Float:ControlRange[]={0.0,250.0,300.0,350.0,400.0,450.0,500.0};
new ControlTime[MAXPLAYERS]; //Time till channeling is complete
new bool:bControlling[MAXPLAYERS][MAXPLAYERS]; //Client and Victim
new bool:bChanged[MAXPLAYERS]; //Person is now under control
new bool:bChannel[MAXPLAYERS]; //You are channeling



public OnWar3PluginReady()
{
    anakinRaceID=War3_CreateNewRace("Anakin [PRIVATE]","starwars_anakin");
    
    SKILL_ANAKIN1=War3_AddRaceSkill(anakinRaceID,"Force Blade","Anakin's lightsaber has a chance to deal 20/30/40/50% extra damage",false,4);
    SKILL_ANAKIN2=War3_AddRaceSkill(anakinRaceID,"Force Pull","Anakin's pull towards the dark side can pull other members towards him (+ability)",false,4);
    SKILL_ANAKIN3=War3_AddRaceSkill(anakinRaceID,"Force Heal","Anakin can heal himself and those around him (+ability1)",false,4);
    ULT_ANAKIN=War3_AddRaceSkill(anakinRaceID,"What have I done?","Anakin turns into Darth Vader (+ultimate)",true,1);
 
    W3SkillCooldownOnSpawn( anakinRaceID, SKILL_ANAKIN2, 10.0 );
    W3SkillCooldownOnSpawn( anakinRaceID, SKILL_ANAKIN3, 10.0 );
    W3SkillCooldownOnSpawn( anakinRaceID, ULT_ANAKIN, 10.0 );
    
    War3_CreateRaceEnd(anakinRaceID);

  
    
    darthRaceID=War3_CreateNewRace("Darth Vader [PRIVATE]","starwars_darth");
    
    SKILL_DARTH1=War3_AddRaceSkill(darthRaceID,"Force Lightning","Darth Vader uses lightning to hit up to 4 targets in a row (+ability).",false,4);
    SKILL_DARTH2=War3_AddRaceSkill(darthRaceID,"Force Choke","Darth Vader selects a member of the opposing faction and chokes the life out of them (+ability1)",false,4);
    SKILL_DARTH3=War3_AddRaceSkill(darthRaceID,"Force Convert","Darth Vader converts a member to the Dark Side (+ability2)",false,4);
    ULT_DARTH=War3_AddRaceSkill(darthRaceID,"NOOOOOOOOOOO!","Darth Vader becomes Anakin Skywalker (+ultimate)",true,1);
   
    W3SkillCooldownOnSpawn( darthRaceID, SKILL_DARTH1, 10.0 );
    W3SkillCooldownOnSpawn( darthRaceID, SKILL_DARTH2, 10.0 );
    W3SkillCooldownOnSpawn( darthRaceID, SKILL_DARTH3, 30.0 );
    W3SkillCooldownOnSpawn( darthRaceID, ULT_DARTH, 10.0 );
   
    War3_CreateRaceEnd(darthRaceID);
    
}



public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    CreateTimer(1.0,ControlLoop,_,TIMER_REPEAT);
    HookEvent("round_end",RoundOverEvent);    
}



public OnMapStart()
{
    GlowSprite = PrecacheModel( "materials/sprites/purpleglow1.vmt" );
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    AttackSprite1 = PrecacheModel( "materials/sprites/purplelaser1.vmt" );
    //AttackSprite2 = PrecacheModel( "materials/sprites/glow.vmt" );
    HealSprite = PrecacheModel( "materials/sprites/hydraspinalcord.vmt" );
    BeamSprite=War3_PrecacheBeamSprite(); 
    War3_AddCustomSound(lightning);
    War3_PrecacheSound( sound1 );
    War3_PrecacheSound( sound2 );

}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public InitPassiveSkills( client )
{
    W3ResetAllBuffRace( client, darthRaceID );
    W3ResetAllBuffRace( client, anakinRaceID );
    War3_WeaponRestrictTo(client,darthRaceID,WEAPON_RESTRICT);
    War3_WeaponRestrictTo(client,anakinRaceID,WEAPON_RESTRICT);
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == anakinRaceID && ValidPlayer( client ))
    {
        InitPassiveSkills(client);

    }
    else if (newrace == darthRaceID && ValidPlayer( client ))
    {
        InitPassiveSkills(client);
    }
    else
    {
        W3ResetAllBuffRace( client, anakinRaceID );
        W3ResetAllBuffRace( client, darthRaceID );
        War3_WeaponRestrictTo(client, darthRaceID,"");
        War3_WeaponRestrictTo(client, anakinRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{

    new race = War3_GetRace( client );
    if (ValidPlayer(client, true))
    {
        if( race == anakinRaceID || race == darthRaceID )
        {
            InitPassiveSkills(client);
        }
    }
}




/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == anakinRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_ = War3_GetSkillLevel( client, anakinRaceID, ULT_ANAKIN );
        if(skill_>0)
        {
            if(War3_SkillNotInCooldown(client,anakinRaceID, ULT_ANAKIN,true)) // USE SAME COOLDOWN FOR BOTH RACES.
            {

                W3FlashScreen( client, RGBA_COLOR_BLUE );
                War3_ShakeScreen(client);
                PrintHintText(client, "You have fallen to the dark side!  You are now DARTH VADER.");
                W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
                W3SetPlayerProp(client,RaceSetByAdmin,true);
                War3_SetRace(client,darthRaceID);
                War3_SetBuff( client, bDisarm, anakinRaceID,true);
                War3_CooldownMGR( client, 10.0, anakinRaceID, ULT_ANAKIN );
                
                CreateTimer(1.0,Fire,client);
            }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
    else if( race == darthRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_ = War3_GetSkillLevel( client, darthRaceID, ULT_DARTH );
        if(skill_>0)
        {
            if(War3_SkillNotInCooldown(client,anakinRaceID, ULT_ANAKIN,true)) // USE SAME COOLDOWN FOR BOTH RACES.
            {
                W3FlashScreen( client, RGBA_COLOR_BLUE );
                War3_ShakeScreen(client);
                PrintHintText(client, "You are free from the tyranny of the dark side!  You are now Anakin.");
                W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
                W3SetPlayerProp(client,RaceSetByAdmin,true);
                War3_SetRace(client,anakinRaceID);
                War3_SetBuff( client, bDisarm, anakinRaceID,true);
                War3_CooldownMGR( client, 10.0, anakinRaceID, ULT_ANAKIN );
                CreateTimer(1.0,Fire,client);
            }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
}


public Action:Fire(Handle:t,any:client)
{
    if(ValidPlayer(client))
    {
        War3_SetBuff( client, bDisarm, anakinRaceID,false);
    }
}


public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==anakinRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            if(ability==0 && pressed)
            {
                new skill_level=War3_GetSkillLevel(client,anakinRaceID,SKILL_ANAKIN2);
                if(skill_level>0)
                {      
                    if(War3_SkillNotInCooldown( client, anakinRaceID, SKILL_ANAKIN2, true ))
                    {
                        new target = War3_GetTargetInViewCone(client,3000.0,false,17.0);
                        if(target>0 && !W3HasImmunity(target,Immunity_Skills))
                        {
                            AnakinPull( client, target );
                            War3_CooldownMGR( client, g_fAnakinPullCooldown[skill_level], anakinRaceID, SKILL_ANAKIN2 );
                        
                        }
                        else
                        {
                            PrintHintText(client,"No valid target found");
                        }
                        
                    }
                }
                else
                {
                    PrintHintText(client, "Level Pull first");
                }
                
            }
            if(ability==1 && pressed)
            {
                new skill_level=War3_GetSkillLevel(client,anakinRaceID,SKILL_ANAKIN3);
                if(skill_level>0)
                {      
                    if(War3_SkillNotInCooldown( client, anakinRaceID, SKILL_ANAKIN3, true ))
                    {
                        new team = GetClientTeam(client);            
                        new Float:otherVec[3];
                        
                        new Float:HealOrigin[MAXPLAYERSCUSTOM][3];
                        GetClientAbsOrigin(client,HealOrigin[client]);
                        HealOrigin[client][2]+=30.0;
                        
                        for(new i=1;i<=MaxClients;i++)
                        {
                            if(ValidPlayer(i,true)&&GetClientTeam(i)==team)
                            {
                                GetClientAbsOrigin(i,otherVec);
                                otherVec[2]+=30.0;
                                new Float:victimdistance=GetVectorDistance(HealOrigin[client],otherVec);
                                if(victimdistance<HealingDistance)
                                {
                                    
                                    TE_SetupBeamPoints( HealOrigin[client], otherVec, HealSprite, HaloSprite, 0, 0, 0.5, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
                                    TE_SendToAll();                            
                                    War3_HealToMaxHP(i, g_iAnakinHealAmount[skill_level]);
                                }
                            }
                        }
                        War3_CooldownMGR( client, g_fAnakinHealCooldown[skill_level], anakinRaceID, SKILL_ANAKIN3);
                        
                    }
                }
                else
                {
                    PrintHintText(client, "Level Heal first");
                }
                
            }
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
        }
    }
    
    if (War3_GetRace(client)==darthRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            if(ability==0 && pressed)
            {
                new skill_level=War3_GetSkillLevel(client,darthRaceID,SKILL_DARTH1);
                if(skill_level>0)
                {      
                    if(War3_SkillNotInCooldown( client, darthRaceID, SKILL_DARTH1, true ))
                    {
                        for(new target=0;target<MAXPLAYERS;target++)
                        {
                            bBeenHit[client][target]=false;
                        }            
                        new target = War3_GetTargetInViewCone(client,LightningDistance[skill_level],false,20.0);
                        
                        if(target>0 && !W3HasImmunity(target,Immunity_Skills))
                        {
                            
                            War3_CooldownMGR(client,g_fDarthLightningCooldown[skill_level],darthRaceID,SKILL_DARTH1);
                            new Float:distance=LightningDistance[skill_level];
                            new Float:target_pos[3];
                            new Float:start_pos[3];
                            
                            GetClientAbsOrigin(target,target_pos);                        
                            GetClientAbsOrigin(client,start_pos);
                            TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,BeamSprite,0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
                            TE_SendToAll();
                            EmitSoundToAll(lightning,client,SNDCHAN_AUTO);
                            CreateTimer(2.0, Stop, client);
                            DoChain(client,distance,LightningDamage[skill_level],true,0);
                        }
                        else
                        {
                            PrintHintText(client, "No target in range");
                            
                        }
                        War3_CooldownMGR( client, g_fDarthLightningCooldown[skill_level], darthRaceID, SKILL_DARTH1 );
                    }
                }
                else
                {
                    PrintHintText(client, "Level Lightning first");
                }
                
            }
            if(ability==1 && pressed)
            {
                new skill_level=War3_GetSkillLevel(client,darthRaceID,SKILL_DARTH2);
                if(skill_level>0)
                {      
                    if(War3_SkillNotInCooldown( client, darthRaceID, SKILL_DARTH2, true ))
                    {
                        new target = War3_GetTargetInViewCone(client,3000.0,false,17.0);
                        if(target>0 && !W3HasImmunity(target,Immunity_Skills))
                        {
                        
                            
                            new Float:target_pos[3];
                            GetClientAbsOrigin(target,target_pos);                        
                            TE_SetupBeamRingPoint(target_pos, 20.0, 400.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,0,133}, 60, 0);
                            TE_SendToAll();
                            
                            War3_DealDamage( target, g_iDarthChokeDamage[skill_level] , client, DMG_BULLET, "darth_choke" );
                            
                            if(GetRandomFloat(0.0,1.0) < g_fDarthChokeStunChance)
                            {
                                CreateTimer(g_fDarthChokeStunTime, StopStun, target);
                                War3_SetBuff( target, bStunned, darthRaceID, true );
                            
                            }
                            War3_CooldownMGR( client, g_fDarthChokeCooldown[skill_level], darthRaceID, SKILL_DARTH2 );
                        
                        }
                        else
                        {
                            PrintHintText(client,"No valid target found");
                        }
                        
                    }
                }
                else
                {
                    PrintHintText(client, "Level Pull first");
                }
                
            }
            if(ability==2 && pressed)
            {
                new skill_level=War3_GetSkillLevel(client,darthRaceID,SKILL_DARTH3);
                if(skill_level>0)
                {      
                    if(War3_SkillNotInCooldown( client, darthRaceID, SKILL_DARTH3, true ))
                    {
                        new target = War3_GetRandomPlayer( client, "#other", true, true, true);
                        if(target>0 && !bChanged[target])
                        {
                            new victimTeam=GetClientTeam(target);
                            new playersAliveSameTeam;
                            for(new i=1;i<=MaxClients;i++)
                            {
                                if(i!=target&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam)
                                {
                                    playersAliveSameTeam++;
                                }
                            }
                            if(playersAliveSameTeam>0)
                            {
                                bChannel[client]=true;
                                War3_SetBuff(client,bStunned,darthRaceID,true);
                                War3_SetBuff(target,bStunned,darthRaceID,true);
                                ControlTime[client]=0;
                                new Float:pos[3];
                                GetClientAbsOrigin(client,pos);
                                pos[2]+=15;
                                new Float:tarpos[3];
                                GetClientAbsOrigin(target,tarpos);
                                tarpos[2]+=15;
                                TE_SetupBeamPoints(pos,tarpos,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{120,84,120,255},50);
                                TE_SendToAll();    
                                TE_SetupBeamRingPoint(tarpos, 1.0, 250.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
                                TE_SendToAll();
                                tarpos[2]+=15;
                                TE_SetupBeamRingPoint(tarpos, 250.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
                                TE_SendToAll();
                                tarpos[2]+=15;
                                TE_SetupBeamRingPoint(tarpos, 1.0, 125.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
                                TE_SendToAll();
                                tarpos[2]+=15;
                                TE_SetupBeamRingPoint(tarpos, 125.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
                                TE_SendToAll();
                                bControlling[client][target]=true;
                                PrintHintText(client, "You start channeling");
                                PrintHintText(target, "Darth Vader is attempting to convert you to the Dark Side!");
                            }
                            else
                            {
                                PrintHintText(client, "Target is last person alive, cannot be controlled");
                            }
                        }
                        else
                        {
                            PrintHintText(client,"No valid target found");
                        }
                        
                    }
                }
                else
                {
                    PrintHintText(client, "Level Force Change first");
                }
                
            }
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
        }
    }
    
}







/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == anakinRaceID )
        {
            new skill_level = War3_GetSkillLevel( attacker, anakinRaceID, SKILL_ANAKIN1 );
            if( !Hexed( attacker, false ) && skill_level > 0 && !W3HasImmunity( victim, Immunity_Skills ) && GetRandomFloat(0.0,1.0) < 0.5 )
            {
                War3_DealDamage( victim, RoundToFloor( damage * g_fDamageMultiplier[skill_level] ), attacker, DMG_BULLET, "anakin_saber" );
                
                new Float:pos[3];
                
                GetClientAbsOrigin( victim, pos );
                
                pos[2] += 50;
                
                TE_SetupGlowSprite( pos, GlowSprite, 2.0, 4.0, 255 );
                TE_SendToAll();

                W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_ANAKIN1 );
                W3FlashScreen( victim, RGBA_COLOR_RED );
            }
        }
    }
}


public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam){
            new race_victim=War3_GetRace(victim);
            
            if(race_victim==darthRaceID && bChannel[victim]){
                War3_SetBuff(victim,bStunned,darthRaceID,false);
                bChannel[victim]=false;
                War3_CooldownMGR(victim,30.0,darthRaceID,SKILL_DARTH3);
                for(new target=1;target<=MaxClients;target++){
                    if(ValidPlayer(target,true)&&bControlling[victim][target]){
                        bControlling[victim][target]=false;
                        War3_SetBuff(target,bStunned,darthRaceID,false);
                    }
            
                }
                PrintHintText(victim, "You've been interupted");
            }
        }
        
    }
}



public OnWar3EventDeath(victim,attacker)
{
    for(new client=1;client<=MaxClients;client++){
        if(bControlling[client][victim]){
            War3_SetBuff(client,bStunned,darthRaceID,false);
            War3_SetBuff(victim,bStunned,darthRaceID,false);
            bChannel[client]=false;
            bControlling[client][victim]=false;    
            War3_CooldownMGR(client,30.0,darthRaceID,SKILL_DARTH3);
        }
    }
}


/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/
public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i)&&bChanged[i])
        {
            new target_team=GetClientTeam(i);
            if(target_team==2){
                bChanged[i]=false;
                CS_SwitchTeam(i, 3);
            }
            if(target_team==3){
                bChanged[i]=false;
                CS_SwitchTeam(i, 2);
            }
        }
    }
}


Action:AnakinPull( client, besttarget )
{

    new Float:posVec[3];
    new skill_level = War3_GetSkillLevel( client, anakinRaceID, SKILL_ANAKIN2 );
    
    GetClientAbsOrigin( client, posVec );
    
    
    new Float:pos1[3];
    new Float:pos2[3];
    
    GetClientAbsOrigin( client, pos1 );
    GetClientAbsOrigin( besttarget, pos2 );
    
    new Float:localvector[3];
    
    localvector[0] = pos1[0] - pos2[0];
    localvector[1] = pos1[1] - pos2[1];
    localvector[2] = pos1[2] - pos2[2];

    new Float:velocity1[3];
    new Float:velocity2[3];
    
    velocity1[0] += 0;
    velocity1[1] += 0;
    velocity1[2] += 300;
    
    velocity2[0] = localvector[0] * ( 100 * GravForce[skill_level] );
    velocity2[1] = localvector[1] * ( 100 * GravForce[skill_level] );
    velocity2[2] = localvector[2] * ( 100 * GravForce[skill_level] );
    
    SetEntDataVector( besttarget, m_vecBaseVelocity, velocity1, true );
    SetEntDataVector( besttarget, m_vecBaseVelocity, velocity2, true );
    
    EmitSoundToAll( sound1, client );
    EmitSoundToAll( sound1, besttarget );
    
    EmitSoundToAll( sound2, client );
    EmitSoundToAll( sound2, besttarget );
    
    War3_SetBuff( besttarget, bFlyMode, anakinRaceID, true );
    CreateTimer( FlyDuration, StopFly, besttarget );
    
    new String:NameAttacker[64];
    GetClientName( client, NameAttacker, 64 );
    
    new String:NameVictim[64];
    GetClientName( besttarget, NameVictim, 64 );
    
    PrintToChat( client, ": You have pulled %s closer to you", NameVictim );
    PrintToChat( besttarget, ": You have been pulled torward %s", NameAttacker );
    
    new Float:startpos[3];
    new Float:endpos[3];
    GetClientAbsOrigin( client, startpos );
    GetClientAbsOrigin( besttarget, endpos );
    startpos[2]+=45;
    endpos[2]+=45;
    TE_SetupBeamPoints( startpos, endpos, AttackSprite1, HaloSprite, 0, 20, 1.5, 1.0, 20.0, 0, 8.5, { 200, 200, 200, 255 }, 0 );
    TE_SendToAll();

        
}

public Action:StopFly( Handle:timer, any:client )
{
    new Float:iVec[ 3 ];
    GetClientAbsOrigin( client, Float:iVec );
    for( new sfx = 1; sfx <= 10; sfx++ )
    {
        iVec[2]+=25.0;
        TE_SetupBeamRingPoint(iVec, 10.0, 200.0, HaloSprite, HaloSprite, 0, 15, 1.0, 5.0, 0.0, {120,120,255,255}, 10, 0);
        TE_SendToAll();
    }
    War3_SetBuff( client, bFlyMode, anakinRaceID, false );
}


public Action:StopStun( Handle:timer, any:client )
{
    if(ValidPlayer(client))
    {
        War3_SetBuff( client, bStunned, darthRaceID, false );
    }
}


public Action:ControlLoop(Handle:timer,any:userid)
{
    for(new client=1;client<=MaxClients;client++){
        if(ValidPlayer(client,true)){
            if(War3_GetRace(client)==darthRaceID){
                for(new target=1;target<=MaxClients;target++){
                    if(ValidPlayer(target,true)&&bControlling[client][target]){
                        if(ControlTime[client]<4){
                            new Float:pos[3];
                            GetClientAbsOrigin(client,pos);
                            pos[2]+=15;
                            new Float:tarpos[3];
                            GetClientAbsOrigin(target,tarpos);
                            tarpos[2]+=15;
                            TE_SetupBeamPoints(pos,tarpos,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{120,84,120,255},50);
                            TE_SendToAll();    
                            TE_SetupBeamRingPoint(tarpos, 1.0, 250.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
                            TE_SendToAll();
                            tarpos[2]+=15;
                            TE_SetupBeamRingPoint(tarpos, 250.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
                            TE_SendToAll();
                            tarpos[2]+=15;
                            TE_SetupBeamRingPoint(tarpos, 1.0, 125.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
                            TE_SendToAll();
                            tarpos[2]+=15;
                            TE_SetupBeamRingPoint(tarpos, 125.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
                            TE_SendToAll();
                            ControlTime[client]++;
                        }
                        else
                        {
                            War3_CooldownMGR(client,300.0,darthRaceID,SKILL_DARTH3,true);
                            War3_SetBuff(client,bStunned,darthRaceID,false);
                            War3_SetBuff(target,bStunned,darthRaceID,false);
                            bControlling[client][target]=false;
                            bChannel[client]=false;
                            new target_team=GetClientTeam(target);
                            PrintHintText(client, "Channeling complete");
                            PrintHintText(target, "You've been switched");
                            W3FlashScreen(target,{120,0,255,50});
                            if(target_team==2){
                                bChanged[target]=true;
                                CS_SwitchTeam(target, 3);
                            }
                            if(target_team==3){
                                bChanged[target]=true;
                                CS_SwitchTeam(target, 2);
                            }
                        }
                    }
                }
            }
        }
    }
}

public Action:Stop(Handle:timer,any:client)
{
    StopSound(client,SNDCHAN_AUTO,lightning);
}



public DoChain(client,Float:distance,dmg,bool:first_call,last_target)
{
    new target=0;
    new Float:target_dist=distance+1.0;
    new caster_team=GetClientTeam(client);
    new Float:start_pos[3];
    new skill_lightning=War3_GetSkillLevel(client,darthRaceID,SKILL_DARTH1);
    
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
