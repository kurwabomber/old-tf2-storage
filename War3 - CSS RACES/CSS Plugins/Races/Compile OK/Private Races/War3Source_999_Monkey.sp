/**
* File: War3Source_999_Monkey.sp
* Description: Monkey D. Luffy Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_THORNS, SKILL_DAMAGE, ULT_BLIND;

public Plugin:myinfo = 
{
    name = "War3Source Race - Monkey D. Luffy",
    author = "Remy Lebeau",
    description = "Synch's private race for War3Source",
    version = "0.9",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.12, 1.19, 1.26, 1.35 };
new Float:ThornsReturnDamage[] = {0.0, 0.05, 0.10, 0.15, 0.20};
new Float:g_fDamageBoost[] = { 0.0, 0.05, 0.10, 0.15, 0.20};

// Ulti Variables
new Float:ElectricTideOrigin[MAXPLAYERSCUSTOM][3];
new blindtime[] = {0, 3, 2, 2, 1 };
new Float:ElectricTideRadius=375.0;
new Float:AbilityCooldownTime[]={0.0, 40.0, 35.0, 30.0, 25.0};
new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];
new HaloSprite, BeamSprite;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Monkey D. Luffy [PRIVATE]","monkey");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Gear Second","1.12,1.19,1.26,1.35 Speed boost",false,4);
    SKILL_THORNS=War3_AddRaceSkill(thisRaceID,"Gomu Gomu No Fuusen","Reflect 5/10/15/20% damage back to opponent",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Armament Haki","5/10/15/20% extra damage",false,4);
    ULT_BLIND=War3_AddRaceSkill(thisRaceID,"Conqeurors Haki","Blind surrounding enemies (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_BLIND,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamageBoost);
    
}



public OnPluginStart()
{

}



public OnMapStart()
{
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
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
        new ult_dist = War3_GetSkillLevel( client, thisRaceID, ULT_BLIND );
        if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_BLIND,true))
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
                TE_SetupBeamRingPoint(ElectricTideOrigin[client], 20.0, ElectricTideRadius+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, RGBA_COLOR_BLACK, 60, 0);
                TE_SendToAll();
                
                CreateTimer(0.1, StunLoop,GetClientUserId(client));
                                
                CreateTimer(0.5, SecondRing,GetClientUserId(client));
                
                War3_CooldownMGR(client,AbilityCooldownTime[ult_dist],thisRaceID,ULT_BLIND,_,_);

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
    TE_SetupBeamRingPoint(ElectricTideOrigin[client], ElectricTideRadius+50,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, RGBA_COLOR_BLACK, 60, 0);
    TE_SendToAll();
}

public Action:StunLoop(Handle:timer,any:userid)
{
    new attacker=GetClientOfUserId(userid);
    if(ValidPlayer(attacker) )
    {
        new team = GetClientTeam(attacker);
        
        new Float:otherVec[3];
        new victimcounter = 0;
        new victimlist[MAXPLAYERS];
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates))
            {        
                GetClientAbsOrigin(i,otherVec);
                otherVec[2]+=30.0;
                new Float:victimdistance=GetVectorDistance(ElectricTideOrigin[attacker],otherVec);

                if(victimdistance<ElectricTideRadius)
                {
                    victimlist[victimcounter] = i;
                    victimcounter++;
                }
                
            }
        }
        new blind_amount = victimcounter;
        if(blind_amount > 5)
            blind_amount = 5;
        for(new i=0;i<victimcounter;i++)
        {
            W3FlashScreen(victimlist[i],{0,0,0,255},0.4,_,FFADE_STAYOUT); 
            CreateTimer(float(blindtime[blind_amount]),Unbanish,GetClientUserId(victimlist[i]));
            W3SetPlayerColor(i,thisRaceID,0,0,0,_,GLOW_SKILL); 
        }
    }
}

public Action:Unbanish(Handle:timer,any:userid)
{
    // never EVER use client in a timer. userid is safe
    new client=GetClientOfUserId(userid);
    if(client>0)
    {
        W3FlashScreen(client,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));
        W3ResetPlayerColor(client,thisRaceID);
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
    if(W3GetDamageIsBullet() && ValidPlayer(victim) && victim != attacker && War3_GetRace(victim) == thisRaceID)
    {
        new iThornsLevel = War3_GetSkillLevel(victim, thisRaceID, SKILL_THORNS);
        if(iThornsLevel > 0 && !Hexed(victim, false))
        {
            // Don't return friendly fire damage
            if(ValidPlayer(attacker) && GetClientTeam(victim) == GetClientTeam(attacker))
            {
                return;
            }
            
            if(!W3HasImmunity(attacker, Immunity_Skills))
            {
                new iDamage = RoundToFloor(damage * ThornsReturnDamage[iThornsLevel]);
                if(iDamage > 0)
                {
                    if(iDamage > 50)
                    {
                        iDamage = 50;
                    }

                    if (GAMECSANY)
                    {
                        // Since this is delayed we don't know if the damage actually went through
                        // and just have to assume... Stupid!
                        War3_DealDamageDelayed(attacker, victim, iDamage, "thorns", 0.1, true, SKILL_THORNS);
                        War3_EffectReturnDamage(victim, attacker, iDamage, SKILL_THORNS);
                    }
                    else
                    {
                        if(War3_DealDamage(attacker, iDamage, victim, _, "thorns", _, W3DMGTYPE_PHYSICAL))
                        {
                            War3_EffectReturnDamage(victim, attacker, War3_GetWar3DamageDealt(), SKILL_THORNS);
                        }
                    }
                }
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
