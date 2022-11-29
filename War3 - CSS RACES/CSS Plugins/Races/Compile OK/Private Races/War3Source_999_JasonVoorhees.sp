/**
* File: War3Source_999_JasonVoorhees.sp
* Description: Jason Voorhees Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_DAMAGE, SKILL_SPEED, SKILL_HP, ULT_VENGENCE;

#define WEAPON_RESTRICT "weapon_knife"
#define WEAPON_GIVE "weapon_knife"

public Plugin:myinfo = 
{
    name = "War3Source Race - Jason Voorhees",
    author = "Remy Lebeau",
    description = "Kablamo's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new g_iHealth[]={0,20,30,40,50};
new Float:g_fDamageBoost[] = { 0.0, 0.25, 0.35, 0.5, 0.75 };

//ultimate
new Float:ultCooldown[] = {0.0, 35.0, 30.0, 25.0, 20.0};
#define IMMUNITYBLOCKDISTANCE 300.0


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Jason Voorhees [PRIVATE]","jasonvoorhees");
    
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Machete Power","Super knife",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Power Walking","Run faster",false,4);
    SKILL_HP=War3_AddRaceSkill(thisRaceID,"Jason's tough","More Hp",false,4);
    ULT_VENGENCE=War3_AddRaceSkill(thisRaceID,"Jason never dies","Respawn after death",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_VENGENCE,20.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_HP, iAdditionalMaxHealth, g_iHealth);
    //War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamageBoost);
}



public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
}



public OnMapStart()
{

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
    
    new skill_damage = War3_GetSkillLevel( client, thisRaceID, SKILL_DAMAGE );
    War3_SetBuff(client,fDamageModifier,thisRaceID,g_fDamageBoost[skill_damage]);

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
    // TODO: Increment UltimateUsed[client]
    if(race==thisRaceID && pressed && IsPlayerAlive(client))
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_VENGENCE);
        if(ult_level>0)
        {
            if(GAMECSANY){
                if(War3_SkillNotInCooldown(client,thisRaceID,ULT_VENGENCE,true)){   //prints
                    W3MsgUltimateNotActivatable(client);
                }

            }
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


public OnWar3EventDeath(victim, attacker, deathrace)
{
    new bool:should_vengence=false;
    
    if(victim>0 && attacker>0 && attacker!=victim)
    {
        if(deathrace==thisRaceID && War3_GetSkillLevel(victim,thisRaceID,ULT_VENGENCE)>0 && War3_SkillNotInCooldown(victim,thisRaceID,ULT_VENGENCE,false) )
        {
            if(ValidPlayer(attacker,true)&&W3HasImmunity(attacker,Immunity_Ultimates))
            {
                W3MsgSkillBlocked(attacker,_,"Respawn");
                W3MsgVengenceWasBlocked(victim,"attacker immunity");
            }
            else
            {
                should_vengence=true;
            }
        }
    }
    else if(victim>0)
    {
        if(War3_GetRace(victim)==thisRaceID && War3_GetSkillLevel(victim,thisRaceID,ULT_VENGENCE)>0)
        {
            if(War3_SkillNotInCooldown(victim,thisRaceID,ULT_VENGENCE,false) )
            {
                should_vengence=true;
            }
            else{
                W3MsgVengenceWasBlocked(victim,"cooldown");
            }
        }
    }
    if(should_vengence)
    {
        new victimTeam=GetClientTeam(victim);
        new playersAliveSameTeam;
        for(new i=1;i<=MaxClients;i++)
        {
            if(i!=victim&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam)
            {
                playersAliveSameTeam++;
            }
        }
        if(playersAliveSameTeam>0)
        {
            // In vengencerespawn do we actually make cooldown
            CreateTimer(0.2,VengenceRespawn,GetClientUserId(victim));
        }
        else{
            W3MsgVengenceWasBlocked(victim,"last one alive");
        }
    }
}

public Action:VengenceRespawn(Handle:t,any:userid)
{
    new client=GetClientOfUserId(userid);
    if(client>0 && War3_GetRace(client)==thisRaceID) //did he become alive?
    {
        if(IsPlayerAlive(client)){
            W3MsgVengenceWasBlocked(client,"you are alive");
        }
        else{
        
            new alivecount;
            new team=GetClientTeam(client);
            for(new i=1;i<=MaxClients;i++){
                if(ValidPlayer(i,true)&&GetClientTeam(i)==team){
                    alivecount++;
                    break;
                }
            }
            if(alivecount==0){
                W3MsgVengenceWasBlocked(client,"last player death or round end");
            }
            else
            {
                War3_SpawnPlayer(client);
                
                War3_ChatMessage(client,"Jason never dies.");
                War3_SetCSArmor(client,100);
                War3_SetCSArmorHasHelmet(client,true);
                War3_CooldownMGR(client,ultCooldown[War3_GetSkillLevel(client,thisRaceID,ULT_VENGENCE)],thisRaceID,ULT_VENGENCE,false,true);
            }
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

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        War3_CooldownReset(i,thisRaceID,ULT_VENGENCE);

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