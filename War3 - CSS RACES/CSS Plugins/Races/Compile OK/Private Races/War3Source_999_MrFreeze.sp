/**
* File: War3Source_999_MrFreeze.sp
* Description: Mr Freeze Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_INVIS, SKILL_FREEZE, SKILL_DAMAGE, ULT_AOE;

#define WEAPON_RESTRICT ""
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Mr Freeze",
    author = "Remy Lebeau",
    description = "Kanon's private race for War3Source",
    version = "0.9",
    url = "http://sevensinsgaming.com"
};


// BUFFS
new Float:g_fInvis[] = { 1.0, 0.7, 0.6, 0.5, 0.4 };
new Float:g_fDamageBoost[] = { 0.0, 0.05, 0.075, 0.10, 0.125 };
new Float:g_fFreezeChance[] = { 0.0, 0.1, 0.15, 0.2, 0.25 };
new HaloSprite, BeamSprite, TPBeamSprite;

// Ulti Variables
new Float:ElectricTideOrigin[MAXPLAYERSCUSTOM][3];
new Float:distractiontime[] = {0.0, 0.75, 1.0, 1.25, 1.5 };
new Float:ElectricTideRadius=175.0;
new Float:AbilityCooldownTime=20.0;
new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];
new g_iDamage[] = {0, 10, 20, 30, 40};
new String:entangleSound[256];

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Mr Freeze [PRIVATE]","mrfreeze");
    
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Invisibility","Mr Freeze is very hard to see but leaves an icy trail",false,4);
    SKILL_FREEZE=War3_AddRaceSkill(thisRaceID,"Freeze opponents","Chance of freezing victims",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Damage boost","Fire a large number of snowflakes with guns",false,4);
    ULT_AOE=War3_AddRaceSkill(thisRaceID,"Blazing frost","Ray of ice dealing great damage and freezing enemies for a short time in an AOE (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn( thisRaceID, ULT_AOE, 15.0, _ );
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_INVIS, fInvisibilitySkill, g_fInvis);
    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamageBoost);
    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    CreateTimer(3.0, CreateTrail,_,TIMER_REPEAT);
}



public OnMapStart()
{
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
    TPBeamSprite = PrecacheModel( "sprites/tp_beam001.vmt" );
    strcopy(entangleSound,sizeof(entangleSound),"war3source/entanglingrootsdecay1.mp3");
    War3_AddCustomSound(entangleSound);
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







/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/



public OnUltimateCommand( client, race, bool:pressed )
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new ult_dist = War3_GetSkillLevel( client, thisRaceID, ULT_AOE );
        if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_AOE,true))
        {
            if(ult_dist > 0)
            {
                GetClientAbsOrigin(client,ElectricTideOrigin[client]);
                ElectricTideOrigin[client][2]+=15.0;
                
                for(new i=1;i<=MaxClients;i++){
                    HitOnBackwardTide[i][client]=false;
                    HitOnForwardTide[i][client]=false;
                }
                //50 IS THE CLOSE CHECK
                TE_SetupBeamRingPoint(ElectricTideOrigin[client], 20.0, ElectricTideRadius+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {0,0,255,133}, 60, 0);
                TE_SendToAll();
                
                CreateTimer(0.1, StunLoop,GetClientUserId(client));
                                
                CreateTimer(0.5, SecondRing,GetClientUserId(client));
                
                War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,ULT_AOE,_,_);
                
                PrintHintText(client,"FREEZE!");    
            }
                
            else
            {
                PrintHintText(client, "Level your Ultimate first");
            }
        }
        
    }

}


public Action:SecondRing(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    TE_SetupBeamRingPoint(ElectricTideOrigin[client], ElectricTideRadius+50,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {0,0,255,133}, 60, 0);
    TE_SendToAll();
}

public Action:StunLoop(Handle:timer,any:userid)
{
    new attacker=GetClientOfUserId(userid);
    if(ValidPlayer(attacker) )
    {
        new team = GetClientTeam(attacker);
        new ult_aoe = War3_GetSkillLevel( attacker, thisRaceID, ULT_AOE );
        
        new Float:otherVec[3];
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates))
            {        
                GetClientAbsOrigin(i,otherVec);
                otherVec[2]+=30.0;
                new Float:victimdistance=GetVectorDistance(ElectricTideOrigin[attacker],otherVec);
                if(victimdistance<ElectricTideRadius)
                {
                    new Float:entangle_time=distractiontime[ult_aoe];
                    new Float:effect_vec[3];
                    GetClientAbsOrigin(i,effect_vec);
                    effect_vec[2]+=15.0;
                    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,0,255,133},10,0);
                    TE_SendToAll();
                    effect_vec[2]+=15.0;
                    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,0,255,133},10,0);
                    TE_SendToAll();
                    effect_vec[2]+=15.0;
                    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,0,255,133},10,0);
                    TE_SendToAll();
                    
                    War3_SetBuff(i,bStunned,thisRaceID,true);
                    War3_DealDamage(i,g_iDamage[ult_aoe],attacker,_,"Stun Ray",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);
                    
                    W3EmitSoundToAll(entangleSound,i);
                    W3EmitSoundToAll(entangleSound,i);
                    CreateTimer(entangle_time,stopStun,i);
                    
                    
                }
            }
        }
    }
    
}
public Action:stopStun(Handle:timer,any:userid)
{
    War3_SetBuff(userid, bStunned, thisRaceID, false);
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
        if( War3_GetRace( attacker ) == thisRaceID && !W3HasImmunity( victim, Immunity_Skills ))
        {
            
            new skill_freeze = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FREEZE );
            if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= g_fFreezeChance[skill_freeze] && skill_freeze > 0 )
            {
                War3_SetBuff( victim, bStunned, thisRaceID, true );
                
                CreateTimer( 0.4, StopFreeze, victim );
                
                W3FlashScreen( victim, RGBA_COLOR_BLUE );
                
                PrintHintText( attacker, "Your enemy is frozen!" );
                
                new Float:start_pos[3];
                new Float:target_pos[3];
                
                GetClientAbsOrigin( attacker, start_pos );
                GetClientAbsOrigin( victim, target_pos );
                
                start_pos[2] += 40;
                target_pos[2] += 40;
                
                TE_SetupBeamPoints( start_pos, target_pos, HaloSprite, HaloSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 0, 0, 255, 255 }, 40 );
                TE_SendToAll();
            }
        }
    }
}

public Action:StopFreeze( Handle:timer, any:client )
{
    if(ValidPlayer(client))
    {
        War3_SetBuff( client, bStunned, thisRaceID, false );
    }
}


/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/

public Action:CreateTrail(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID)
        {
            new skill_invis = War3_GetSkillLevel( i, thisRaceID, SKILL_INVIS );
            if(skill_invis)
            {
                TE_SetupBeamFollow( i, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 30, { 0, 0, 255, 255 } );
                TE_SendToAll();
            }
        }
    }    
}



public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i))
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}

    