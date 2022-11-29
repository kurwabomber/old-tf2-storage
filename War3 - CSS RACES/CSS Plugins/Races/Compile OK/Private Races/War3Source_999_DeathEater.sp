/**
* File: War3Source_999_DeathEater.sp
* Description: Shadow Reaper Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_STUN, SKILL_FIREBALL, SKILL_DROP, ULT_CONTROL;

#define WEAPON_RESTRICT "weapon_knife"
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Death Eater",
    author = "Remy Lebeau",
    description = "No3 Player's private race for War3Source",
    version = "0.9",
    url = "http://sevensinsgaming.com"
};

//Stun
new Float:StunTime[]={0.0,0.5,1.0,1.5,2.0};
new Float:StunCooldown[] = {0.0, 35.0, 30.0, 25.0, 20.0};

//Fire
new FireDamage[]={0,10,20,30,40};
new Float:FireCooldown[] = {0.0, 35.0, 30.0, 25.0, 20.0};
new String:fire[]="war3source/roguewizard/fire.wav";

// Drop
new Float:DropChance[] = { 0.0, 0.18, 0.23, 0.27, 0.30 };

//Control Magic
new Float:ControlRange[]={0.0,250.0,300.0,350.0,400.0,450.0,500.0};
new ControlTime[MAXPLAYERS]; //Time till channeling is complete
new bool:bControlling[MAXPLAYERS][MAXPLAYERS]; //Client and Victim
new bool:bChanged[MAXPLAYERS]; //Person is now under control
new bool:bChannel[MAXPLAYERS]; //You are channeling
new BeamSprite,HaloSprite;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Death Eater [PRIVATE]","deatheater");
    
    SKILL_STUN=War3_AddRaceSkill(thisRaceID,"Confundo (Confundus Charm)","Causes the victim to become confused, befuddled (+ability)",false,4);
    SKILL_FIREBALL=War3_AddRaceSkill(thisRaceID,"Avada Kedavra (Killing Curse)","Causes instant, painless death to whomever the curse hits. (+ability1)",false,4);
    SKILL_DROP=War3_AddRaceSkill(thisRaceID,"Expelliarmus (Disarming Charm)","This spell is used to disarm another wizard",false,4);
    ULT_CONTROL=War3_AddRaceSkill(thisRaceID,"Imperio (Imperius Curse)","Causes the victim of the curse to obey the spoken/unspoken commands of the caster (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_CONTROL,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);

}



public OnPluginStart()
{
    CreateTimer(1.0,ControlLoop,_,TIMER_REPEAT);
    HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    War3_AddCustomSound(fire);
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
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    bChannel[client]=false;
    ControlTime[client]=0;

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills( client );
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{
    bChanged[client]=false;
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        InitPassiveSkills( client );
    }
}






/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID){
        if(!Silenced(client) &&  ValidPlayer(client, true)){
            

            if(ability==0 && pressed && IsPlayerAlive(client)){
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_STUN,true)){
                    new target = War3_GetTargetInViewCone(client,9000.0,false,10.0);
                    new skill_stun=War3_GetSkillLevel(client,thisRaceID,SKILL_STUN);
                    if(skill_stun>0){      
                        EmitSoundToAll(fire,client);
                        War3_CooldownMGR(client,StunCooldown[skill_stun],thisRaceID,SKILL_STUN);
                        if(target>0 && !W3HasImmunity(target,Immunity_Skills)){
                            new Float:origin[3];
                            new Float:targetpos[3];
                            origin[2] += 40.0;
                            targetpos[2] += 40.0;
                            
                            GetClientAbsOrigin(target,targetpos);
                            GetClientAbsOrigin(client,origin);
                            TE_SetupBeamPoints(origin, targetpos, BeamSprite, BeamSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {18,38,255,255}, 40);  
                            TE_SendToAll();
                            GetClientAbsOrigin(target,targetpos);
                            targetpos[2]+=30;
                            TE_SetupBeamRingPoint(targetpos,1.0,600.0,HaloSprite,HaloSprite,0,15,0.5,50.0,2.0,{18,38,255,255},0,0);
                            TE_SendToAll();
                            EmitSoundToAll(fire,target);
                            War3_SetBuff(target,bStunned,thisRaceID,true);
                            W3FlashScreen(target,RGBA_COLOR_BLUE, 0.3, 0.4, FFADE_OUT);
                            W3SetPlayerColor( target, thisRaceID, 0, 0, 255, _, GLOW_SKILL );
                            CreateTimer(StunTime[skill_stun],StopStun,target);
                            PrintHintText(target, "Confundus!  You are stunned!");
                        }
                        else
                        {
                            new Float:origin[3];
                            new Float:targetpos[3];
                            
                            War3_GetAimEndPoint(client,targetpos);
                            GetClientAbsOrigin(client,origin);
                            TE_SetupBeamPoints(origin, targetpos, BeamSprite, BeamSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {18,38,255,255}, 40);  
                            TE_SendToAll();
                            War3_GetAimEndPoint(client,targetpos);
                            targetpos[2]+=30;
                            TE_SetupBeamRingPoint(targetpos,1.0,600.0,HaloSprite,HaloSprite,0,15,0.5,50.0,2.0,{18,38,255,255},0,0);
                            TE_SendToAll();
                        }
                        
                    }
                    else
                    {
                        PrintHintText(client, "Level your Stun first");
                    }
                    
                }
                
            }
            
            if(ability==1 && pressed && IsPlayerAlive(client)){
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_FIREBALL,true)){
                    new target = War3_GetTargetInViewCone(client,9000.0,false,10.0);
                    new skill_fire=War3_GetSkillLevel(client,thisRaceID,SKILL_FIREBALL);
                    if(skill_fire>0){      
                        EmitSoundToAll(fire,client);
                        War3_CooldownMGR(client,FireCooldown[skill_fire],thisRaceID,SKILL_FIREBALL);
                        if(target>0 && !W3HasImmunity(target,Immunity_Skills)){
                            new Float:origin[3];
                            new Float:targetpos[3];
                            
                            GetClientAbsOrigin(target,targetpos);
                            GetClientAbsOrigin(client,origin);
                            TE_SetupBeamPoints(origin, targetpos, BeamSprite, BeamSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {18,255,26,255}, 40);  
                            TE_SendToAll();
                            GetClientAbsOrigin(target,targetpos);
                            targetpos[2]+=30;
                            TE_SetupBeamRingPoint(targetpos,1.0,600.0,HaloSprite,HaloSprite,0,15,0.5,50.0,2.0,{18,255,26,255},0,0);
                            TE_SendToAll();
                            EmitSoundToAll(fire,target);
                            War3_DealDamage(target,FireDamage[skill_fire],client,DMG_BULLET,"Avada Kevara");
                            PrintHintText(target, "Avada Kevara!");
                        }
                        else
                        {
                            new Float:origin[3];
                            new Float:targetpos[3];
                            
                            War3_GetAimEndPoint(client,targetpos);
                            GetClientAbsOrigin(client,origin);
                            TE_SetupBeamPoints(origin, targetpos, BeamSprite, BeamSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {18,255,26,255}, 40);  
                            TE_SendToAll();
                            War3_GetAimEndPoint(client,targetpos);
                            targetpos[2]+=30;
                            TE_SetupBeamRingPoint(targetpos,1.0,600.0,HaloSprite,HaloSprite,0,15,0.5,50.0,2.0,{18,255,26,255},0,0);
                            TE_SendToAll();
                        }
                        

                        
                    }
                    else
                    {
                        PrintHintText(client, "Level your fireball first");
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



public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true)){
        if(!Silenced(client)){
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_CONTROL,true)){
                new ult_control=War3_GetSkillLevel(client,thisRaceID,ULT_CONTROL);
                if(ult_control>0){
                    new target = War3_GetTargetInViewCone(client,ControlRange[ult_control],false,8.0);
                        
                    if(target>0 && !bChanged[target] && !W3HasImmunity(target,Immunity_Ultimates)){
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
                            War3_SetBuff(client,bStunned,thisRaceID,true);
                            War3_SetBuff(target,bStunned,thisRaceID,true);
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
                            PrintHintText(target, "You are being turned!");
                        }
                        else
                        {
                            PrintHintText(client, "Target is last person alive, cannot be controlled");
                        }
                    }
                    else
                    {
                        PrintHintText(client, "no target nearby");
                    }
                    
                }
                else
                {
                    PrintHintText(client, "Level your Control Magic first");
                }
            
            }
        }
        else
        {
            PrintHintText(client, "you are silenced");
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
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_drop = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DROP );
            if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DropChance[skill_drop] )
            {
                if( !W3HasImmunity( victim, Immunity_Skills ) )
                {
                    FakeClientCommand( victim, "drop" );
                    PrintHintText(victim, "Expelliarmus!");
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
        
        if(vteam!=ateam){
            new race_victim=War3_GetRace(victim);
            
            if(race_victim==thisRaceID && bChannel[victim]){
                War3_SetBuff(victim,bStunned,thisRaceID,false);
                bChannel[victim]=false;
                War3_CooldownMGR(victim,30.0,thisRaceID,ULT_CONTROL);
                for(new target=1;target<=MaxClients;target++){
                    if(ValidPlayer(target,true)&&bControlling[victim][target]){
                        bControlling[victim][target]=false;
                        War3_SetBuff(target,bStunned,thisRaceID,false);
                    }
            
                }
                PrintHintText(victim, "You've been interupted");
            }
        }
        
    }
}

public OnWar3EventDeath(victim,attacker)
{
    new race_victim=War3_GetRace(victim);
    
    if(race_victim==thisRaceID){
        for(new controlled=1;controlled<=MaxClients;controlled++)
        {
            if(ValidPlayer(controlled)&&bChanged[controlled])
            {
                PrintHintText(controlled, "You are free again!");
                W3FlashScreen(controlled,{120,0,255,50});
                new target_team=GetClientTeam(controlled);
                if(target_team==2){
                    bChanged[controlled]=false;
                    CS_SwitchTeam(controlled, 3);
                }
                if(target_team==3){
                    bChanged[controlled]=false;
                    CS_SwitchTeam(controlled, 2);
                }
            }
            
        }
    }
    
    for(new client=1;client<=MaxClients;client++){
        if(bControlling[client][victim]){
            War3_SetBuff(client,bStunned,thisRaceID,false);
            War3_SetBuff(victim,bStunned,thisRaceID,false);
            bChannel[client]=false;
            bControlling[client][victim]=false;    
            War3_CooldownMGR(client,30.0,thisRaceID,ULT_CONTROL);
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
public Action:StopStun(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
        PrintHintText(client, "Confundus ends");
        War3_SetBuff(client,bStunned,thisRaceID,false);
        W3ResetPlayerColor( client, thisRaceID );
    }
}

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

public Action:ControlLoop(Handle:timer,any:userid)
{
    for(new client=1;client<=MaxClients;client++){
        if(ValidPlayer(client,true)){
            if(War3_GetRace(client)==thisRaceID){
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
                            War3_CooldownMGR(client,60.0,thisRaceID,ULT_CONTROL);
                            War3_SetBuff(client,bStunned,thisRaceID,false);
                            War3_SetBuff(target,bStunned,thisRaceID,false);
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