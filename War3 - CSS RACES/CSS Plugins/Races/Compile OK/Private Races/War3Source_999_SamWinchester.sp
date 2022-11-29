/**
* File: War3Source_999_SamWinchester.sp
* Description: Sam Winchester Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_DAMAGE, SKILL_SPEED, SKILL_CASH, ULT_TORNADO;



public Plugin:myinfo = 
{
    name = "War3Source Race - Sam Winchester",
    author = "Remy Lebeau",
    description = "Leviathan's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.2, 1.25, 1.35, 1.4 };
new Float:g_fDamageBoost[] = { 0.0, 0.05, 0.10, 0.15, 0.20, 0.25 };

//Cannibalize
new String:Nom[]="ui/ReceiveGold.mp3";
new Float:corpselocation[3][MAXPLAYERS][20];
new dietimes[MAXPLAYERS];
new cannibal[]={0,200,300,400,500};
new corpsehealth[MAXPLAYERS][40];
new bool:corpsedied[MAXPLAYERS][40];
new BeamSprite,HaloSprite;
new MoneyOffsetCS;


//Tornado
new TornadoCost[]={0,1500,2500,3500,5000};
new Float:TornadoTime[]={0.0,1.0,1.5,2.0,2.0};
new TornadoRange[]={0,450,550,650,750};
new Float:TornadoDamage=20.0;                    // Damage dealt per second of tornado time
new String:tornado[]="war3source/roguewizard/tornado.wav";
new m_vecBaseVelocity;
new Float:g_fUltCooldown = 20.0;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Sam Winchester [PRIVATE]","samwinchester");
    
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Taurus PT-92 9mm pistol","*Turns into a FN Five-Seven Pistol* & Get extra damage.",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","For a big guy, he knows how to run fast",false,4);
    SKILL_CASH=War3_AddRaceSkill(thisRaceID,"Demon Blood","Steal from a corpse!",false,4);
    ULT_TORNADO=War3_AddRaceSkill(thisRaceID,"Telekinesis ","Use your mind power to destroy your enemies (costs $$) (+ultimate)",true,4);

    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamageBoost);
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);

    
}



public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
    CreateTimer(0.5,CorpseSteal,_,TIMER_REPEAT);
    MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
}



public OnMapStart()
{
    War3_AddCustomSound(tornado);
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
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
    
    

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_fiveseven");
        CreateTimer( 1.0, giveWeapon, client );

    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{

    if(ValidPlayer( client, true ))
    {
        new race = War3_GetRace( client );
        if( race == thisRaceID )
        {
            War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_fiveseven");
            CreateTimer( 1.0, giveWeapon, client );
        }
        else
        {
            W3ResetAllBuffRace( client, thisRaceID );
            War3_SetBuff(client,bBashed,thisRaceID,false);
            War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
        }
    }
}




public OnSkillLevelChanged(client,race,skill,newskilllevel )
{
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
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
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_tornado = War3_GetSkillLevel( client, thisRaceID, ULT_TORNADO );
        if(skill_tornado>0)
        {
            new money=GetMoney(client);
            if(money>=TornadoCost[skill_tornado])
            {
                if( War3_SkillNotInCooldown( client, thisRaceID, ULT_TORNADO, true ) )
                {
                    War3_CooldownMGR(client, g_fUltCooldown, thisRaceID, ULT_TORNADO, true, true);
                    new Float:position[3];
                    EmitSoundToAll(tornado,client);
                    SetMoney(client,money-TornadoCost[skill_tornado]);
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
                                if(!W3HasImmunity(target,Immunity_Ultimates)){
                                    if(GetVectorDistance(targetPos,clientPos)<TornadoRange[skill_tornado]){
                                        new Float:velocity[3];
                                
                                        velocity[2]+=800.0;
                                        SetEntDataVector(target,m_vecBaseVelocity,velocity,true); 
                                        War3_SetBuff(target,fHPDecay,thisRaceID,TornadoDamage);  
                                        CreateTimer(0.1,Tornado1,GetClientUserId(target));
                                        CreateTimer(0.4,Tornado2,GetClientUserId(target));
                                        CreateTimer(1.0,Stun,GetClientUserId(target));
                                        CreateTimer(TornadoTime[skill_tornado],Unstunned,GetClientUserId(target));
                                    }
                                    
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






/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/



public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim))
    {
        new deaths=dietimes[victim];
        dietimes[victim]++;
        corpsedied[victim][deaths]=true;
        corpsehealth[victim][deaths]=60;
        new Float:pos[3];
        War3_CachedPosition(victim,pos);
        corpselocation[0][victim][deaths]=pos[0];
        corpselocation[1][victim][deaths]=pos[1];
        corpselocation[2][victim][deaths]=pos[2];
        for(new client=0;client<=MaxClients;client++){
            if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
                TE_SetupBeamRingPoint(pos,25.0,75.0,BeamSprite,HaloSprite,0,15,6.0,20.0,3.0,{100,100,150,255},20,0);
                TE_SendToClient(client);
            }
        }
    }
}


public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    resetcorpses();
    
}



/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/
public Action:giveWeapon(Handle:timer,any:client)
{
    if (ValidPlayer(client, true))
    {
        GivePlayerItem( client, "weapon_fiveseven");
    }
}


public resetcorpses()
{
    for(new client=0;client<=MaxClients;client++){
        for(new deaths=0;deaths<=19;deaths++){
            corpselocation[0][client][deaths]=0.0;
            corpselocation[1][client][deaths]=0.0;
            corpselocation[2][client][deaths]=0.0;
            dietimes[client]=0;
            corpsehealth[client][deaths]=0;
            corpsedied[client][deaths]=false;
        }
    }
}

    

public Action:CorpseSteal(Handle:timer)
{
    for(new client=0;client<=MaxClients;client++){
        if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_CASH);
            if(skill_level>0){
                for(new corpse=0;corpse<=MaxClients;corpse++){
                    for(new deaths=0;deaths<=19;deaths++){
                        if(corpsedied[corpse][deaths]==true){
                            new Float:corpsepos[3];
                            new Float:clientpos[3];
                            GetClientAbsOrigin(client,clientpos);
                            corpsepos[0]=corpselocation[0][corpse][deaths];
                            corpsepos[1]=corpselocation[1][corpse][deaths];
                            corpsepos[2]=corpselocation[2][corpse][deaths];
                            
                            if(GetVectorDistance(clientpos,corpsepos)<50){
                                if(corpsehealth[corpse][deaths]>=0){
                                    EmitSoundToAll(Nom,client);
                                    W3FlashScreen(client,{155,0,0,40},0.1);
                                    corpsehealth[corpse][deaths]-=5;
                                    new money=GetMoney(client);
                                    new addcash=cannibal[skill_level];
                                    SetMoney(client,money+addcash);
                                }
                            }
                            else
                            {
                                corpsehealth[corpse][deaths]-=5;
                            }
                        }
                    }
                }
            }
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


public Action:Tornado1(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    new Float:velocity[3];
    
    velocity[2]+=4.0;
    velocity[0]-=600.0;
    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:Tornado2(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    new Float:velocity[3];
    
    velocity[2]+=4.0;
    velocity[0]+=600.0;
    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:Stun(Handle:timer,any:userid)
{
    new victim = GetClientOfUserId(userid);
    War3_SetBuff(victim,bBashed,thisRaceID,true);
}

public Action:Unstunned(Handle:timer,any:userid)
{
    new victim = GetClientOfUserId(userid);
    War3_SetBuff(victim,bBashed,thisRaceID,false);
    War3_SetBuff(victim,fHPDecay,thisRaceID,0.0);
}
