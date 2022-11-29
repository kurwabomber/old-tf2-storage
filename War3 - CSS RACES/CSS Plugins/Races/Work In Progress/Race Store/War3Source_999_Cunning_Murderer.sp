/*
* War3Source Race - Cunning Murderer
* 
* File: War3Source_Cunning_Murderer.sp
* Description: The Cunning Murderer race for War3Source.
* Author: M.A.C.A.B.R.A 
* Modified by Remy Lebeau
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source Race - Cunning Murderer",
    author = "M.A.C.A.B.R.A",
    description = "The Cunning Murderer race for War3Source.",
    version = "1.1",
    url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_ROTATE, SKILL_REGENERATE, SKILL_ACCELERATOR, ULT_AVENGER;

// Rotate
new Float:RotateRange[]={0.0,100.0,150.0,200.0,250.0,300.0};
new RotateDelayer[MAXPLAYERS];
new RotateDelayerList[]= {30, 28, 25, 22, 19, 15};
 

// Regenerate
new bool:bDucking[MAXPLAYERS];
new RegenerateAmmount[]={0,1,2,3,4,5};
new Float:canregeneratetime[MAXPLAYERS+1];
new RegenerateDelayer[MAXPLAYERS];

//Accelerator
new Float:SpeedAmmount[]={1.0,1.2,1.4,1.6,1.8,2.0};
new Float:StandStillTime[MAXPLAYERS];
new bool:AcceleratorActivated[MAXPLAYERS];
new m_vecVelocity = -1;
new Float:canspeedtime[MAXPLAYERS+1];
new AcceleratorDelayer[MAXPLAYERS];

// Avenger
new VictimsTab[MAXPLAYERS];
new AvengerDmg[]={0,10,20,30,40,50};


/* *********************** OnWar3PluginReady *********************** */
public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace( "Cunning Murderer [SSG-DONATOR]", "cunning" );
    
    SKILL_ROTATE = War3_AddRaceSkill( thisRaceID, "Rotate", "Passively turns around your enemy", false, 5 );
    SKILL_REGENERATE = War3_AddRaceSkill( thisRaceID, "Regenerate", "HP recover if ducking.", false, 5 );
    SKILL_ACCELERATOR = War3_AddRaceSkill( thisRaceID, "Accelerator", "Charges your speed if not moving.", false, 5 );
    ULT_AVENGER = War3_AddRaceSkill( thisRaceID, "Avenger", "You avenge your teammates!", true, 5 );
    
    W3SkillCooldownOnSpawn( thisRaceID, ULT_AVENGER, 20.0, _ );
    
    War3_CreateRaceEnd( thisRaceID );
}

/* *********************** OnMapStart *********************** */
public OnMapStart()
{

}

/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{
    CreateTimer( 0.1, CalcRotation, _, TIMER_REPEAT );    
    CreateTimer(0.1, CalcRegenerate,_,TIMER_REPEAT);    
    CreateTimer(0.1, CalcSpeed,_,TIMER_REPEAT);
    m_vecVelocity = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
}

/* *********************** OnWar3EventSpawn *********************** */
public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        StandStillTime[client] = 0.0;
        AcceleratorActivated[client] = false;
        bDucking[client] = false;
        W3ResetAllBuffRace( client, thisRaceID );
        new skill_lvl = War3_GetSkillLevel(client,thisRaceID,ULT_AVENGER);
        RegenerateDelayer[client] = GetRandomInt(0,10);
        AcceleratorDelayer[client] = RegenerateDelayer[client];
        RotateDelayer[client] = GetRandomInt(0,RotateDelayerList[skill_lvl]);
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_tmp,weapon_usp");
        CreateTimer( 1.5, forceGiveWep, client );
    }
}


public Action:forceGiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, "weapon_usp" );
        GivePlayerItem( client, "weapon_tmp" );
    }
}



/* *********************** OnRaceChanged *********************** */
public OnRaceChanged(client,oldrace,newrace)
{
    if( newrace != thisRaceID )
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

/* *********************** OnWar3EventDeath *********************** */
public OnWar3EventDeath( victim, attacker )
{
    W3ResetAllBuffRace( victim, thisRaceID );
    new avenger = GetRandomPlayer( victim );
    new skill_lvl = War3_GetSkillLevel(avenger,thisRaceID,ULT_AVENGER);
    if(skill_lvl>0  && !W3HasImmunity( attacker, Immunity_Ultimates ))
    {
        if(ValidPlayer(avenger,true))
        {
            War3_CooldownMGR(avenger,33.0,thisRaceID,ULT_AVENGER,false,_);
            new Handle:DataPack;
            PrintHintText(avenger, "You have been chosen to avenge the death of your friend. - Teleporting in 3 seconds");
            War3_DealDamage(attacker,AvengerDmg[skill_lvl],victim,DMG_BURN,"Avenger",W3DMGORIGIN_SKILL);
            WritePackCell(DataPack, avenger);
            WritePackCell(DataPack, victim);
            WritePackCell(DataPack, attacker);
            CreateDataTimer(3.0, avengeTeam, DataPack);

        }
    }
    
}
public Action:avengeTeam(Handle:timer, Handle:DataPack)
{
    ResetPack(DataPack);    
    new avenger = ReadPackCell(DataPack);
    new victim = ReadPackCell(DataPack);
    new attacker = ReadPackCell(DataPack);
    new Float:VictimPos[3];
    GetClientAbsOrigin(victim,VictimPos);
    new Float:angs[3];
    GetClientEyeAngles(attacker, angs);
    angs[1] += 180;
    TeleportEntity(avenger, VictimPos, angs, NULL_VECTOR);    
    TeleportEntity(attacker, NULL_VECTOR, angs, NULL_VECTOR);    
    
}



/* *************************************** CalcRegenerate *************************************** */
public Action:CalcRegenerate(Handle:timer,any:userid)
{
    for(new i = 1; i < MaxClients; i++)
    {
        if(ValidPlayer(i) && War3_GetRace(i) == thisRaceID)
        {
            new skill_regen = War3_GetSkillLevel(i,thisRaceID,SKILL_REGENERATE);
            if(canregeneratetime[i] < GetGameTime() && skill_regen > 0)
            {
                RegenerateDelayer[i]++;
                if(RegenerateDelayer[i] == 10)
                {
                    War3_HealToBuffHP(i,RegenerateAmmount[skill_regen]);
                    RegenerateDelayer[i] = 0;
                }
            }
            else
            {
            }
            if(skill_regen> 0 && !bDucking[i])
            {
                canregeneratetime[i] = GetGameTime() + 1.0;
            }
        }
    }
}

/* *************************************** OnPlayerRunCmd *************************************** */
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer(client)&&War3_GetRace(client)==thisRaceID)
    {
        bDucking[client]=(buttons & IN_DUCK)?true:false;
    }
    return Plugin_Continue;
}



/* *************************************** CalcSpeed *************************************** */
public Action:CalcSpeed(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID)
        {
            new skill_speed = War3_GetSkillLevel(i,thisRaceID,SKILL_ACCELERATOR);
            if(canspeedtime[i] < GetGameTime() && skill_speed > 0 )
            {
                if(AcceleratorActivated[i] == false)
                {
                    AcceleratorDelayer[i]++;
                    if(AcceleratorDelayer[i] == 10)
                    {
                        StandStillTime[i]++;
                        W3Hint(i,HINT_LOWEST,1.0,"Charging accelerate: %.0f",StandStillTime[i]);
                        AcceleratorDelayer[i] = 0;
                    }
                }
            }
            else
            {
                if(AcceleratorActivated[i] == false)
                {
                    if(StandStillTime[i] != 0.0)
                    {
                        PrintHintText(i, "You've been accelerated for %.0f seconds",StandStillTime[i]);
                        AcceleratorDelayer[i] = 0;
                        CreateTimer(StandStillTime[i], SlowDown, i);
                        StandStillTime[i] = 0.0;
                        War3_SetBuff(i,fMaxSpeed,thisRaceID,SpeedAmmount[skill_speed]);
                        AcceleratorActivated[i] = true;
                    }
                }
            }
            decl Float:velocity[3];
            GetEntDataVector(i,m_vecVelocity,velocity);
            if(skill_speed > 0 && GetVectorLength(velocity) > 0)
            {
                canspeedtime[i] = GetGameTime() + 1.0;
            }
        }
    }    
}

/* *************************************** SlowDown *************************************** */
public Action:SlowDown(Handle:timer,any:client)
{
    AcceleratorActivated[client] = false;
    if (ValidPlayer(client,true))
    {
        W3ResetAllBuffRace( client, thisRaceID );
        PrintHintText(client, "You slowed down.");
    }    
}



/* *************************************** CalcRotation *************************************** */
public Action:CalcRotation( Handle:timer, any:userid )
{
    if( thisRaceID > 0 )
    {
        for( new i = 1; i <= MaxClients; i++ )
        {
            if( ValidPlayer( i, true ) )
            {
                if( War3_GetRace( i ) == thisRaceID )
                {
                    Rotation( i );                    
                }
            }
        }
    }
}

/* *************************************** Rotation *************************************** */
public Rotation( client )
{
    new skill_rotate = War3_GetSkillLevel( client, thisRaceID, SKILL_ROTATE );
    if( skill_rotate > 0 && !Hexed( client, false ) )
    {
        new Float:distance = RotateRange[skill_rotate];
        new AttackerTeam = GetClientTeam( client );
        new Float:AttackerPos[3];
        new Float:VictimPos[3];
        
        GetClientAbsOrigin( client, AttackerPos );
        
        AttackerPos[2] += 40.0;

        for( new i = 1; i <= MaxClients; i++ )
        {
            if( ValidPlayer( i, true ) && GetClientTeam( i ) != AttackerTeam && !W3HasImmunity( i, Immunity_Skills ) )
            {
                GetClientAbsOrigin( i, VictimPos );
                VictimPos[2] += 40.0;
                
                if( GetVectorDistance( AttackerPos, VictimPos ) <= distance )
                {
                    RotateDelayer[i]++;
                    if(RotateDelayer[i] == 30)
                    {
                        new Float:angs[3];
                        GetClientEyeAngles(i, angs);
    
                        angs[1] += 180;
    
                        TeleportEntity(i, NULL_VECTOR, angs, NULL_VECTOR);
                        
                        RotateDelayer[i] = 0;
                    }
                }
            }
        }
    }
}



/* *************************************** GetRandomPlayer *************************************** */
public GetRandomPlayer( client )
{
    new victims = 0;
    new avengerTeam = GetClientTeam( client );
    for( new i = 1; i <= MaxClients; i++ )
    {
        if( ValidPlayer( i, true ) && GetClientTeam( i ) == avengerTeam)
        {
            if(IsClientInGame(i) && IsPlayerAlive(i))
            {
                new race = War3_GetRace( i );
                if(race == thisRaceID && War3_SkillNotInCooldown(i,thisRaceID,ULT_AVENGER,false))
                {
                    VictimsTab[victims] = i;
                    victims++;
                }
            }
        }
    }
    
    if(victims == 0)
    {
        return 0;
    }
    else
    {
        new target = GetRandomInt(0,(victims-1));
        return VictimsTab[target];        
    }
}

