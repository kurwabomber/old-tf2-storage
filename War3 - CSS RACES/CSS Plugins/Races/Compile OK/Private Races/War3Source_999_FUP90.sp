/**
* File: War3Source_999_FUP90.sp
* Description: FU P90 Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_REGEN, SKILL_WEB, ULT_P90;

#define WEAPON_RESTRICT ""
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - FU P90",
    author = "Remy Lebeau",
    description = "Little_Napa's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.15, 1.2, 1.25 };
new Float:g_fRegen[] = { 0.0, 1.0, 2.0, 3.0, 4.0 };

// Web
new m_vecBaseVelocity;
new  FreezeSprite1;
new String:ult_sound[] = "weapons/357/357_spin1.wav";
new Float:PushForce[5] = { 0.0, 1.0, 1.1, 1.2, 1.25 };

// ULTI
new UltiRange[]={0,200,300,400,500};
new g_iExplosionModel; 
new g_iExplosionRadius=90;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("FU P90 [PRIVATE]","fup90");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"|F|ast","Increase speed to 1.1, 1.15, 1.2, 1.25",false,4);
    ULT_P90=War3_AddRaceSkill(thisRaceID," |U|ltimate"," P90's get F'd up. Knocked out of hand + Disintegrates",true,4);
    SKILL_WEB=War3_AddRaceSkill(thisRaceID,"|P|ull"," Web Slinger (+ability)",false,4);
    SKILL_REGEN=War3_AddRaceSkill(thisRaceID,"|90|","Regen 1, 2, 3, 4 HPS",false,4);
    
    W3SkillCooldownOnSpawn( thisRaceID, SKILL_WEB, 10.0 );
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_REGEN, fHPRegen, g_fRegen);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    CreateTimer(1.0,p90timer,_,TIMER_REPEAT);
}



public OnMapStart()
{
    War3_PrecacheSound( ult_sound );
    g_iExplosionModel = PrecacheModel( "materials/sprites/zerogxplode.vmt", false );
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
    War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,-10);    

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

public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            if(ability==0 && pressed)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_WEB,true))
                {
                    new skill_web=War3_GetSkillLevel(client,thisRaceID,SKILL_WEB);
                    if(skill_web>0)
                    {      
                        TeleportPlayer( client );
                        EmitSoundToAll( ult_sound, client );
                        War3_CooldownMGR( client, 20.0, thisRaceID, SKILL_WEB );
                    }
                    else
                    {
                        PrintHintText(client, "Level |P|ull first");
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




stock TeleportPlayer( client )
{
	if( client > 0 && IsPlayerAlive( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, thisRaceID, SKILL_WEB );
		new Float:startpos[3];
		new Float:endpos[3];
		new Float:localvector[3];
		new Float:velocity[3];
		
		GetClientAbsOrigin( client, startpos );
		War3_GetAimTraceMaxLen(client, endpos, 2500.0);
		
		localvector[0] = endpos[0] - startpos[0];
		localvector[1] = endpos[1] - startpos[1];
		localvector[2] = endpos[2] - startpos[2];
		
		velocity[0] = localvector[0] * PushForce[ult_level];
		velocity[1] = localvector[1] * PushForce[ult_level];
		velocity[2] = localvector[2] * PushForce[ult_level];
		
		SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
		
		TE_SetupBeamPoints( startpos, endpos, FreezeSprite1, FreezeSprite1, 0, 0, 1.0, 1.0, 1.0, 0, 0.0, { 255, 14, 41, 255 }, 0 );
		TE_SendToAll();
		
		TE_SetupBeamRingPoint( endpos, 11.0, 9.0, FreezeSprite1, FreezeSprite1, 0, 0, 2.0, 13.0, 0.0, { 255, 100, 100, 255 }, 0, FBEAM_ISACTIVE );
		TE_SendToAll();
	}
}

/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public Action:p90timer(Handle:timer)
{
    for(new client=0;client<=MaxClients;client++)
    {
        if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true))
        {
            new skill_level=War3_GetSkillLevel(client,thisRaceID,ULT_P90);
            if(skill_level>0)
            {
                new Float:clientPos[3];
                GetClientAbsOrigin(client, clientPos);
                clientPos[2]+=10;
                new client_team=GetClientTeam(client);
                for(new target=0;target<=MaxClients;target++)
                {
                    if(ValidPlayer(target,true))
                    {
                        new target_team=GetClientTeam(target);
                        if(target_team!=client_team)
                        {
                            new Float:targetPos[3];
                            GetClientAbsOrigin(target, targetPos);
                            if(!W3HasImmunity(target,Immunity_Ultimates))
                            {
                                if(GetVectorDistance(targetPos,clientPos)<UltiRange[skill_level])
                                {
                                    
                                    new primweapon = Client_GetWeaponBySlot(target, 0);
            
                                    if (primweapon > -1)
                                    {
                                        new String:temp[128];
                                        GetEntityClassname(primweapon, temp, sizeof(temp));
                                        if(strcmp(temp,"weapon_p90",false) == 0)
                                        {
                                        // DO BAD STUFF!
                                            Client_RemoveWeapon(target, temp);
                                            new String:tName[256];
                                            GetClientName (target, tName, 256 );
                                            PrintToConsole(client, "Found a P90!! Taking care of it.  |%s| Just lost their pew pew.",tName);
                                            PrintHintText(client, "Found a P90!! |%s| Just lost their pew pew.",tName);
                                            War3_DealDamage( target, 10, client, DMG_BULLET, "FU P90" );
                                            targetPos[2] += 40;
                                            TE_SetupExplosion(targetPos, g_iExplosionModel,10.0,1,0,g_iExplosionRadius,160);
                                            TE_SendToAll();
                                            
                                        }
                                        
                                        
                                        /*
                                        
                                        new String:cName[256];
                                        new String:tName[256];
                                        GetClientName (client, cName, 256 );
                                        GetClientName (target, tName, 256 );

                                        PrintToChatAll("Client |%s|, Target |%s, |Weapon name is |%s|", cName,tName, temp);*/
                                    }
                                }
                            }
                            
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

    