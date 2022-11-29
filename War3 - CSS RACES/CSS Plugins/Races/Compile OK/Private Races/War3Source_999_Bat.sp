/**
* File: War3Source_999_Bat.sp
* Description: Bat Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_LEECH, SKILL_FLY, SKILL_SPEED, ULT_DRUG;

#define WEAPON_RESTRICT ""
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Bat",
    author = "Remy Lebeau",
    description = "Valencianista's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.05, 1.15, 1.2, 1.25, 1.3 };
new Float:VampirePercent[] = {0.0, 0.05, 0.10, 0.15, 0.20, 0.25 };

new Float:g_fUltCooldown = 10.0;
new bool:g_bFlying[MAXPLAYERS];

new Float:g_fDrugDuration[] = {0.0, 1.0, 2.0, 4.0, 5.0, 6.0};
new Float:g_fDrugCooldown[] = {0.0, 35.0, 30.0, 25.0, 23.0, 20.0};
new Float:g_fDrugDistance[]={0.0,400.0,450.0,500.0,550.0,600.0};
new String:g_sDrugSound[]="war3source/tidehunter/anchorcast.wav";
new BeamSprite;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Bat [PRIVATE]","bat");
    
    SKILL_LEECH=War3_AddRaceSkill(thisRaceID,"I’m a vampire bat, not a fruit bat.","Vampire passive on hit",false,5);
    SKILL_FLY=War3_AddRaceSkill(thisRaceID,"Bats can fly","Fly around (+ability)",false,1);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Bats move a little faster","Passive speed increase",false,5);
    ULT_DRUG=War3_AddRaceSkill(thisRaceID,"A bats’ bite disorients","Drugs the person on hit (+ultimate)",true,5);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_DRUG,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, VampirePercent);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{
    War3_AddCustomSound(g_sDrugSound);
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
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
    CreateTimer( 1.0, GiveWep, client );

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
        g_bFlying[client] = false;
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
    new race = War3_GetRace( client );
    if (race == thisRaceID && ValidPlayer(client,true))
    {
        if (pressed && ability==0)
        {
            if (War3_GetSkillLevel(client, thisRaceID, SKILL_FLY) > 0)
            {
                if (War3_SkillNotInCooldown(client, thisRaceID, SKILL_FLY, false))
                {
                    if (!Silenced(client))
                    {
                    
                        if (g_bFlying[client])
                        {
                            g_bFlying[client] = false;
                            PrintHintText(client, "Time to roost!");
                            War3_CooldownMGR(client, g_fUltCooldown, thisRaceID, SKILL_FLY, _, true);
                            War3_SetBuff(client, bFlyMode, thisRaceID, false);
                            //War3_SetBuff( client, bDisarm, thisRaceID, false  );
                            
                        }
                        else
                        {
                            g_bFlying[client] = true;
                            War3_SetBuff(client, bFlyMode, thisRaceID, true);
                            PrintHintText(client, "Fly away little bat!");
                            //War3_SetBuff( client, bDisarm, thisRaceID, true  );
                            
                        }
                        
                    
                    }
                }
            }
        }
    }
}




public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && ValidPlayer( client,true ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_DRUG );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_DRUG, true ))
            {
                new target = War3_GetTargetInViewCone(client,g_fDrugDistance[ult_level],false,20.0);
                           
                if(target>0 && !W3HasImmunity(target,Immunity_Ultimates))
                {

                    ServerCommand( "sm_drug #%d 1", GetClientUserId( target ) );
                    
                    PrintHintText(client,"You drugged your enemy");
                    PrintHintText(target,"A bat bit you!  You're drugged.");
                    
                    CreateTimer( g_fDrugDuration[ult_level], StopBleed, target );
                    
                
                    new Float:target_pos[3];
                    new Float:start_pos[3];
                    
                    GetClientAbsOrigin(target,target_pos);                        
                    GetClientAbsOrigin(client,start_pos);
                    TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,BeamSprite,0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
                    TE_SendToAll();
                    EmitSoundToAll(g_sDrugSound,client);
                    War3_CooldownMGR(client,g_fDrugCooldown[ult_level],thisRaceID,ULT_DRUG);
                }
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}


                    
public Action:StopBleed( Handle:timer, any:client )
{
    if( ValidPlayer( client ) )
    {        
        ServerCommand( "sm_drug #%d 0", GetClientUserId( client ) );
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
    if(ValidPlayer(victim) && War3_GetRace( victim ) == thisRaceID)
    {
        if (g_bFlying[victim])
        {
            g_bFlying[victim] = false;
            War3_SetBuff(victim, bFlyMode, thisRaceID, false);
            
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
            g_bFlying[i] = false;
            War3_SetBuff(i, bFlyMode, thisRaceID, false);
        }
    }
}
    

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_GiveWeapon(client, WEAPON_GIVE, true); 
    }
}