/**
* File: War3Source_999_Horsemen_Pestilence.sp
* Description: Pestilence Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>

#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions.inc"

new thisRaceID;
new SKILL1, SKILL2, SKILL3, SKILL4;

#define WEAPON_RESTRICT "weapon_knife,weapon_usp"
#define WEAPON_GIVE "weapon_usp"

public Plugin:myinfo = 
{
    name = "War3Source Race - Pestilence [HORSEMEN]",
    author = "Remy Lebeau",
    description = "Pestilence race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.10, 1.15, 1.20, 1.25 };
new Float:g_fDamage[] = { 0.0, 0.30, 0.35, 0.40, 0.45 };
new Float:g_fSpeedLevel[] = { 1.0, 0.9, 0.85, 0.8, 0.75 };


new Float:AuraDistance[]={0.0,250.0,300.0,350.0,400.0};
new AuraID;

// Skill3 Variables
new Float:ElectricTideOrigin[MAXPLAYERSCUSTOM][3];
new Float:g_fPlagueDamage[] = {0.0, 3.0, 6.0, 9.0, 12.0 };
new Float:g_fTimer = 4.0;
new Float:ElectricTideRadius=300.0;
new Float:AbilityCooldownTime[]={0.0, 35.0, 30.0, 25.0, 20.0};
new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];
new HaloSprite, BeamSprite;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Pestilence - Green Horseman","horseman_pest");
    

    
    SKILL1=War3_AddRaceSkill(thisRaceID,"Pestilence's Weapon","War carries a green sword.",false,4);
    SKILL2=War3_AddRaceSkill(thisRaceID,"Pestilence's Speed","Pestilence's horse - The slowest.",false,4);
    SKILL3=War3_AddRaceSkill(thisRaceID,"Pestilence's Infestation","Pestilence tends to come and go like...the PLAGUE. (+ability)",false,4);
    SKILL4=War3_AddRaceSkill(thisRaceID,"Pestilence's Presence","Everyone starts to feel a bit tired and slow.",true,4);

    
    War3_CreateRaceEnd(thisRaceID);
    
    
    AuraID=W3RegisterChangingDistanceAura("pestilence_slowwave",true);
    
    War3_AddSkillBuff(thisRaceID, SKILL1, fDamageModifier, g_fDamage);      
    War3_AddSkillBuff(thisRaceID, SKILL2, fMaxSpeed, g_fSpeed);
  
}



public OnPluginStart()
{
}



public OnMapStart()
{
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
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    CreateTimer( 1.0, GiveWep, client );

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID )
    {
        if(ValidPlayer( client, true))
        {
            InitPassiveSkills( client );
        }
        new level=War3_GetSkillLevel(client,thisRaceID,SKILL4);
        if(level>0)
        {
            W3SetPlayerAura(AuraID,client,AuraDistance[level],level);
        }
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3RemovePlayerAura(AuraID,client);
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



public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    
    if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
    {
        if(skill==SKILL4)
        {
            W3RemovePlayerAura(AuraID,client);
            if(newskilllevel>0)
            {
                W3SetPlayerAura(AuraID,client,AuraDistance[newskilllevel],newskilllevel);
            }
        }
    }
}


public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(aura==AuraID)
    {
        if(inAura)
        {
            if(!W3HasImmunity(client,Immunity_Ultimates))
            {
                 War3_SetBuff( client, fSlow, thisRaceID, g_fSpeedLevel[level]);
                 War3_SetBuff( client, fAttackSpeed, thisRaceID, g_fSpeedLevel[level] );
            }
            else
            {
                 War3_SetBuff( client, fSlow, thisRaceID, 1.0);
                 War3_SetBuff( client, fAttackSpeed, thisRaceID, 1.0 );

            }
        }
        else
        {
            War3_SetBuff( client, fSlow, thisRaceID, 1.0);
            War3_SetBuff( client, fAttackSpeed, thisRaceID, 1.0 );
        }
        
        
    }
}



/***************************************************************************
*
*
*               PLAGUE
*
*
***************************************************************************/


public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true) && ability==0)
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID,SKILL3 );
        if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,SKILL3,true))
        {
            if(skill_level > 0)
            {
                GetClientAbsOrigin(client,ElectricTideOrigin[client]);
                ElectricTideOrigin[client][2]+=15.0;
                
                for(new i=1;i<=MaxClients;i++){
                    HitOnBackwardTide[i][client]=false;
                    HitOnForwardTide[i][client]=false;
                }
                //50 IS THE CLOSE CHECK
                TE_SetupBeamRingPoint(ElectricTideOrigin[client], 20.0, ElectricTideRadius+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,0,133}, 60, 0);
                TE_SendToAll();
                
                CreateTimer(0.1, StunLoop,GetClientUserId(client));
                                
                CreateTimer(0.5, SecondRing,GetClientUserId(client));
                
                War3_CooldownMGR(client,AbilityCooldownTime[skill_level],thisRaceID,SKILL3,_,_);

            }
                
            else
            {
                PrintHintText(client, "Level Infestation first");
            }
        }
        
    }

}


public Action:SecondRing(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    TE_SetupBeamRingPoint(ElectricTideOrigin[client], ElectricTideRadius+50,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,0,133}, 60, 0);
    TE_SendToAll();
}

public Action:StunLoop(Handle:timer,any:userid)
{
    new attacker=GetClientOfUserId(userid);
    if(ValidPlayer(attacker) )
    {
        new team = GetClientTeam(attacker);
        new skill_level = War3_GetSkillLevel( attacker, thisRaceID,SKILL3 );
        new Float:otherVec[3];
        new victimcounter = 0;
        new victimlist[MAXPLAYERS];
        for(new i=1;i<=MaxClients;i++)
        {

            if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Skills))
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

        for(new i=0;i<victimcounter;i++)
        {
            new temp = victimlist[i];
            if(ValidPlayer(temp))
            {
                
                War3_SetBuff(temp,fHPDecay,thisRaceID,g_fPlagueDamage[skill_level]);
                W3SetPlayerColor(temp,thisRaceID,255,0,0,_,GLOW_SKILL); 
                CreateTimer(g_fTimer, StopDecay, temp);
            }
        }
    }
}

public Action:StopDecay(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
        W3ResetBuffRace(client,fHPDecay,thisRaceID);
        W3ResetPlayerColor(client,thisRaceID);
    }
}




/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/



public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, WEAPON_GIVE );
    }
}