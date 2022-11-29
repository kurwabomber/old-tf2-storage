/**
* File: War3Source_999_Cops.sp
* Description: Cops Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <smlib>

new thisRaceID;
new SKILL_SPEED, SKILL_IMMUNITY, SKILL_INVIS, ULT_GUN;



public Plugin:myinfo = 
{
    name = "War3Source Race - Cops",
    author = "Remy Lebeau",
    description = "spraynpray's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeedBonus[] = {1.0, 1.1, 1.2, 1.25, 1.3, 1.4};
new Float:g_fImmunityChance[] = {0.0, 0.2, 0.3, 0.4, 0.5, 0.6};

//Stand Still INVIS
new InvisTime[]={ 0, 50, 40, 30, 25, 20 };
new m_vecVelocity = -1;
new Float:canspeedtime[MAXPLAYERS+1];
new AcceleratorDelayer[MAXPLAYERS];
new bool:InvisTrue[MAXPLAYERS];

// ult
new bool:g_bUltFired[MAXPLAYERS];

new g_iExplosionModel; 


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Cops [PRIVATE]","cops");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"No fast food","Cutting out the doughnuts allows you to run faster.",false,5);
    SKILL_IMMUNITY=War3_AddRaceSkill(thisRaceID,"Take Cover","Chance of skill immunity on spawn (up to 60%)",false,5);
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Stakeout","Full invisibility when standing still",false,5);
    ULT_GUN=War3_AddRaceSkill(thisRaceID,"Need backup!","Deploy your bazooka (+ultimate)",true,1);
    
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeedBonus);
}



public OnPluginStart()
{
    m_vecVelocity = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    HookEvent("bullet_impact",BulletImpact);
    CreateTimer(0.1, CalcSpeed,_,TIMER_REPEAT);
}



public OnMapStart()
{
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
    new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_IMMUNITY );
    if (GetRandomFloat(0.0,1.0) < g_fImmunityChance[skill_level])
    {    
        War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
        War3_SetBuff(client,bImmunityWards,thisRaceID,true);
        CPrintToChat(client, "{red}Cops: {default}-- Skill immunity activated");
    }
    InvisTrue[client] = false;
    g_bUltFired[client] = false;
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_tmp,weapon_p228");
        CreateTimer( 1.5, forceGiveWep, client );
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
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_tmp,weapon_p228");            
        CreateTimer( 1.5, forceGiveWep, client );
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



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID, ULT_GUN );
        if(skill_level>0)
        {
            if (g_bUltFired[client]==false)
            {
                CPrintToChat(client, "{red}Cops: {default}-- Cannon loaded.");
                GivePlayerItem( client, "weapon_p228" );
                Client_SetWeaponAmmo(client, "weapon_p228", 0,120,1,0);
                g_bUltFired[client] = true; 
            }
            else
            {
                PrintHintText(client, "You may only use your ultimate once per round.");
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


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
 
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, ULT_GUN );
            if( skill_level > 0 && g_bUltFired[attacker] == true && !W3HasImmunity( victim, Immunity_Ultimates  ) )
            {
                new String:wpnstr[32];
                GetClientWeapon( attacker, wpnstr, 32 );
                if( StrEqual( wpnstr, "weapon_p228" ) )
                {
                    War3_DealDamage(victim,10000,attacker,DMG_BULLET,"cannon",_,W3DMGTYPE_MAGIC);
                    W3FlashScreen( victim, RGBA_COLOR_RED );
                }
            }
        }
    }
}


public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client_userid = GetEventInt(event, "userid");    
    new client = GetClientOfUserId(client_userid);
    if(ValidPlayer(client, true) && (War3_GetRace( client ) == thisRaceID) )
    {
        new skill_level = War3_GetSkillLevel(client, thisRaceID, ULT_GUN );
        if( skill_level > 0 && g_bUltFired[client] == true)
        {
            new String:wpnstr[32];
            GetClientWeapon( client, wpnstr, 32 );
            if( StrEqual( wpnstr, "weapon_p228" ) )
            {
                War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_tmp");
                
                new Float:Origin[3];
                Origin[0] = GetEventFloat(event,"x");
                Origin[1] = GetEventFloat(event,"y");
                Origin[2] = GetEventFloat(event,"z");
                    
                TE_SetupExplosion(Origin, g_iExplosionModel,10.0,1,0,120,160);
                TE_SendToAll();
                        
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


public Action:forceGiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {

        GivePlayerItem( client, "weapon_tmp" );
    }
}


public Action:CalcSpeed(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID)
        {
            new skill_speed = War3_GetSkillLevel(i,thisRaceID,SKILL_INVIS);
            if(canspeedtime[i] < GetGameTime() && skill_speed > 0 )
            {
                // PrintToChat(i, "Standing still, invis in |%d|",AcceleratorDelayer[i]);
                AcceleratorDelayer[i]++;
                if(AcceleratorDelayer[i] == InvisTime[skill_speed])
                {
                    if (InvisTrue[i] == false)
                    {
                        War3_SetBuff( i, bDisarm, thisRaceID, true  );
                        War3_SetBuff( i, fInvisibilitySkill, thisRaceID, 0.0  );
                        War3_SetBuff( i,bDoNotInvisWeapon,thisRaceID,false);
                        W3Hint(i,HINT_LOWEST,1.0,"Hidding! (Can't shoot)");
                        AcceleratorDelayer[i] = 0;
                        InvisTrue[i] = true;
                    }
                }
                
            }
            else
            {
                if(InvisTrue[i] == true)
                {
                    W3Hint(i,HINT_LOWEST,1.0,"No longer hidden");
                    War3_SetBuff( i, bDisarm, thisRaceID, false  );
                    War3_SetBuff( i, fInvisibilitySkill, thisRaceID, 1.0  );
                    War3_SetBuff( i,bDoNotInvisWeapon,thisRaceID,true);
                    InvisTrue[i] = false;
                }
                AcceleratorDelayer[i] = 0;
            
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


public Action:RemoveSpeed(Handle:t,any:client)
{
    if(ValidPlayer(client))
    {
        War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
        War3_SetBuff( client, bDisarm, thisRaceID, false  );
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0  );
        War3_SetBuff( client,bDoNotInvisWeapon,thisRaceID,true);

    }
}