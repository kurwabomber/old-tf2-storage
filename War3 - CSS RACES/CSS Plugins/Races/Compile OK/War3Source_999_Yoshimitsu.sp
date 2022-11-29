/**
* File: War3Source_999_Yoshimitsu.sp
* Description: Yoshimitsu Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new thisRaceID;
new SKILL_WINDMILL, SKILL_DAMAGE, SKILL_HARAKIRI, ULT_RESPAWN;

public Plugin:myinfo = 
{
    name = "War3Source Race - Yoshimitsu",
    author = "Remy Lebeau",
    description = "Yoshimitsu race for War3Source",
    version = "1.2.0",
    url = "http://sevensinsgaming.com"
};

new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new Float:ElectricGravity[5] = { 1.0, 0.92, 0.84, 0.76, 0.68 };
new Float:JumpMultiplier[5] = { 1.0, 3.1, 3.2, 3.3, 3.4 };
new g_iDamageBonus[] = { 0, 20, 30, 40, 55 };

new Float:ult_cooldown=15.0;
new playerkills[MAXPLAYERS];

new g_iHarakiriHealth[] = { 20, 10, 0, -10, -20 };
new Float:g_fHarakiriDamage[] = { 0.0, 0.15, 0.30, 0.45, 0.6 };

new Float:ult_delay[]={ 0.0 ,6.5 ,5.0 ,3.5 ,1.95 };

new bool:fireonce[MAXPLAYERS];

new BeamSprite, HaloSprite;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Yoshimitsu","yoshimitsu");
    
    SKILL_WINDMILL=War3_AddRaceSkill(thisRaceID,"Windmill","Use your mechanical arm to fly.",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Soul Edge","Blood awakens the demon within (gain power per kill)",false,4);
    SKILL_HARAKIRI=War3_AddRaceSkill(thisRaceID,"Harakiri","Add your own blood to the sword for extra power",false,4);
    ULT_RESPAWN=War3_AddRaceSkill(thisRaceID,"Manji Ninjitsu","Teleport yourself back to spawn fully healed (+ultimate)",true,4);
    

    W3SkillCooldownOnSpawn( thisRaceID, ULT_RESPAWN, ult_cooldown, false);
    
    War3_CreateRaceEnd(thisRaceID);
}






public OnPluginStart()
{
    
    HookEvent("round_end",RoundEndEvent);
    if(GAMECSANY)
    {
        m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
        m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
        m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
        HookEvent( "player_jump", PlayerJumpEvent );
    }
    
}



public OnMapStart()
{
    War3_PrecacheParticle("burning_gib_01_follower2");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    BeamSprite=PrecacheModel("sprites/orangelight1.vmt");

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
    if (!fireonce[client])
    {
        W3ResetAllBuffRace( client, thisRaceID );    
        
        fireonce[client] = true;
    }
    
    playerkills[client] = 0;
    War3_SetBuff( client, iDamageBonus, thisRaceID, 0  );
    
    new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_WINDMILL );
    War3_SetBuff( client, fLowGravitySkill, thisRaceID, ElectricGravity[skill_level]);
    
    
    new skill_harakiri = War3_GetSkillLevel( client, thisRaceID, SKILL_HARAKIRI );
    
    War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, g_iHarakiriHealth[skill_harakiri]  );
    War3_SetBuff( client, fDamageModifier, thisRaceID, g_fHarakiriDamage[skill_harakiri]  );
    PrintToConsole(client, "Harakiri damage bonus = |%f|",g_fHarakiriDamage[skill_harakiri]);
    
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    
    
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
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
        new skill_level = War3_GetSkillLevel( client, thisRaceID, ULT_RESPAWN );
        if(skill_level>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_RESPAWN,true)) 
                {
                
                    new Float:startpos[3];
                    new Float:targetpos[3];
                    GetClientAbsOrigin(client,startpos);
                    GetClientAbsOrigin(client,targetpos);
                    targetpos[2]+=850;
                    TE_SetupBeamPoints(startpos, targetpos, BeamSprite, BeamSprite, 0, 5, 10.0, 65.0, 5.5, 2, 0.2, {255,128,35,255}, 70);  
                    TE_SendToAll();
                    TE_SetupBeamPoints(startpos, targetpos, BeamSprite, BeamSprite, 0, 5, 8.0, 65.0, 5.5, 2, 0.2, {255,128,35,240}, 70);  //do it twice so it disappears more smoothly
                    TE_SendToAll();
                    CreateTimer(ult_delay[skill_level], Timer_Rift, client);
                    War3_ChatMessage(client,"Respawn in %f seconds.",ult_delay[skill_level]);
                    
                    
                    War3_CooldownMGR(client,ult_cooldown,thisRaceID,ULT_RESPAWN,_,_);
                
                
                    
                
                
                }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
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
    if( War3_GetRace( attacker ) == thisRaceID && !W3HasImmunity(victim,Immunity_Skills))
    {
        new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DAMAGE );
        if (skill_dmg > 0 && victim != attacker)
        {    
            playerkills[attacker] += 1;
            if (playerkills[attacker] > 4)
            {
                playerkills[attacker] = 4;
            }
            new temp = playerkills[attacker];
            new temp3 = playerkills[attacker] * g_iDamageBonus[temp];
            War3_SetBuff( attacker, iDamageBonus, thisRaceID, temp3  );
            W3FlashScreen( attacker, {255,0,0,100}, 0.5 );
            PrintToConsole(attacker, "Sword infused by blood! Damage bonus = |%f|",temp3);
            AttachThrowAwayParticle(attacker, "burning_gib_01_follower2", NULL_VECTOR, "muzzle_flash", 15.0);
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


public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            fireonce[i] = false;
        }
    }
}

    

public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        new skill_long = War3_GetSkillLevel( client, race, SKILL_WINDMILL );
        if( skill_long > 0 )
        {
            new Float:velocity[3] = { 0.0, 0.0, 0.0 };
            velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
            velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
            velocity[0] *= JumpMultiplier[skill_long] * 0.25;
            velocity[1] *= JumpMultiplier[skill_long] * 0.25;
            SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
            
            
        }
    }
}


public Action:Timer_Rift(Handle:timer, any:client)
{

        new Float:iVec[3];
        GetClientAbsOrigin(client,iVec);  
        fireonce[client] = false;
        War3_SpawnPlayer(client,true);
        TE_SetupGlowSprite( iVec, BeamSprite, 3.5 , 1.5 , 150);
        TE_SendToAll();
        TE_SetupBeamRingPoint( iVec,1.0,75.0,HaloSprite,HaloSprite,0,15,16.0,280.0,2.0,{255,0,0,255},0,0);
        TE_SendToAll();
        
        TE_SetupEnergySplash(iVec, iVec,false);
        TE_SendToAll();
        
        War3_HealToMaxHP(client, 200);
        PrintToChat(client,"\x03Manji Ninjitsu : \x02 You teleport back to spawn fully healed");
        
}

