/**
* File: War3Source_999_PhoenixOrder.sp
* Description: Order of the Phoenix Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_TORNADO, SKILL_CLUSTERROCKET, SKILL_DROP, ULT_HEAL;

#define WEAPON_RESTRICT "weapon_knife"
#define WEAPON_GIVE "weapon_knife"

public Plugin:myinfo = 
{
    name = "War3Source Race - Order of the Phoenix",
    author = "Remy Lebeau",
    description = "No3 Player's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

//Tornado
new Float:TornadoTime[]={0.0,1.0,2.0,3.0,4.0,};
new TornadoRange[]={0,350,450,550,650};
new Float:Cooldown[]={22.0,20.0,18.0,16.0,14.0};
new BeamSprite,HaloSprite;
new String:tornado[]="war3source/roguewizard/tornado.wav";
new m_vecBaseVelocity;

//skill 2
new String:missilesnd[]="weapons/mortar/mortar_explode2.wav";
new Float:MissileMaxDistance[9]={0.00,2000.0,3000.0,4000.0,5000.0};
new bool:bIsBashed[MAXPLAYERS];
new BeamSprite2;
new Float:g_fFreezeTime[] = {0.0,1.0,1.5,2.0, 2.5};

//skill3
new Float:DropChance[5] = { 0.0, 0.25, 0.50, 0.75, 1.0 };

// Ult
new HP[] = { 0, 15, 30, 45, 60 };
new GlowSprite;



public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Order of the Phoenix [PRIVATE]","phoenixorder");
    
    SKILL_TORNADO=War3_AddRaceSkill(thisRaceID,"Wingardium Leviosa","Throws enemies in air (+ability)",false,4);
    SKILL_CLUSTERROCKET=War3_AddRaceSkill(thisRaceID,"Petrificus Totalus","Turn them into stone - can't take damage while petrified (+ability1)",false,4);
    SKILL_DROP=War3_AddRaceSkill(thisRaceID,"Expelliarmus","Makes enemies drop their weapon and resort to wand (knife)",false,4);
    ULT_HEAL=War3_AddRaceSkill(thisRaceID,"Episkey","Restores health (+ultimate)",true,4);
    
    
    War3_CreateRaceEnd(thisRaceID);
    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
}



public OnMapStart()
{
    War3_AddCustomSound(tornado);
    War3_PrecacheSound(missilesnd);
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    BeamSprite2=PrecacheModel("sprites/tp_beam001.vmt");
    GlowSprite = PrecacheModel( "materials/sprites/purpleglow1.vmt" );
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
    War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, 50 );

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
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        InitPassiveSkills( client );
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
        new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_HEAL );
        if(ult_level>0)
        {
            if(War3_SkillNotInCooldown(client,thisRaceID, ULT_HEAL,true)) 
            {
                War3_HealToMaxHP( client, HP[ult_level] );
                new Float:pos[3];
                
                GetClientAbsOrigin( client, pos );
                
                pos[2] += 50;
                
                TE_SetupGlowSprite( pos, GlowSprite, 4.0, 2.0, 255 );
                TE_SendToAll();
                
                W3FlashScreen(client,RGBA_COLOR_GREEN, 0.3, 0.4, FFADE_OUT);
                
                War3_CooldownMGR( client, 10.0, thisRaceID, ULT_HEAL);                
            }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
}



public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID){
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            
            if(ability==0 && pressed && IsPlayerAlive(client))
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_TORNADO,true))
                {
                    new skill_tornado=War3_GetSkillLevel(client,thisRaceID,SKILL_TORNADO);
                    
                    if(skill_tornado>0)
                    {
                        new Float:position[3];
                        EmitSoundToAll(tornado,client);
                        War3_CooldownMGR(client,Cooldown[skill_tornado],thisRaceID,SKILL_TORNADO);
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
                        for(new target=0;target<=MaxClients;target++)
                        {
                            if(ValidPlayer(target,true))
                            {
                                new client_team=GetClientTeam(client);
                                new target_team=GetClientTeam(target);
                    
                                if(target_team!=client_team)
                                {
                                    new Float:targetPos[3];
                                    new Float:clientPos[3];
                                
                                    GetClientAbsOrigin(target, targetPos);
                                    GetClientAbsOrigin(client, clientPos);
                                    if(!W3HasImmunity(target,Immunity_Skills))
                                    {
                                        if(GetVectorDistance(targetPos,clientPos)<TornadoRange[skill_tornado])
                                        {
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
                        PrintHintText(client, "Level your tornado first");
                    }
                    
                }
                
            }
                        
            if(ability==1 && pressed && ValidPlayer(client,true))
            {
                new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_CLUSTERROCKET);
                if(skill_level>0)
                {
                    
                    if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_CLUSTERROCKET,true))
                    {
                        new Float:origin[3];
                        new Float:targetpos[3];
                        War3_GetAimEndPoint(client,targetpos);
                        GetClientAbsOrigin(client,origin);
                        origin[2]+=30;
                        origin[1]+=20;
                        TE_SetupBeamPoints(origin, targetpos, BeamSprite2, BeamSprite2, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {160,82,45,255}, 70);  
                        TE_SendToAll();
                        origin[1]-=40;
                        TE_SetupBeamPoints(origin, targetpos, BeamSprite2, BeamSprite2, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {160,82,45,255}, 70);  
                        TE_SendToAll();
                        EmitSoundToAll(missilesnd,client);
                        War3_CooldownMGR(client,Cooldown[skill_level],thisRaceID,SKILL_CLUSTERROCKET);
                        new target = War3_GetTargetInViewCone(client,MissileMaxDistance[skill_level],false,20.0);
                        if(target>0 && !W3HasImmunity(target,Immunity_Skills))
                        {
                            War3_SetBuff(target,bStunned,thisRaceID,true);
                            W3SetPlayerColor(target,thisRaceID,160,82,45,20,GLOW_SKILL);  
                            W3FlashScreen(target,RGBA_COLOR_RED, 0.3, 0.4, FFADE_OUT);
                            CreateTimer(g_fFreezeTime[skill_level],UnfreezePlayer,GetClientUserId(target));
                            bIsBashed[target]=true;
                            
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
                }
            }
        }
    }
}

public OnW3TakeDmgAllPre( victim, attacker, Float:damage )
{
    if( ValidPlayer( victim ) && ValidPlayer( attacker ) && attacker != victim )
    {
        new vteam = GetClientTeam( victim );
        new ateam = GetClientTeam( attacker );
        
        if( vteam != ateam && bIsBashed[victim]==true)
        {
            War3_DamageModPercent( 0.0 );
            PrintHintText(attacker, "Victim is petrified - cannot damage");
            PrintHintText(victim, "Petrified blocked damage");
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
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
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


public Action:UnfreezePlayer(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    if(client>0)
    {
        //PrintHintText(client,"NO LONGER BASHED");
        War3_SetBuff(client,bStunned,thisRaceID,false);
        bIsBashed[client]=false;
        W3ResetPlayerColor(client,thisRaceID);
    }
}