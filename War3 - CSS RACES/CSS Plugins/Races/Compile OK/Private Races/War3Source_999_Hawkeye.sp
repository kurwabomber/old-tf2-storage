/**
* File: War3Source_999_Hawkeye.sp
* Description: Hawkeye Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_EXPLOSIVE, SKILL_FROST, SKILL_DRUG, SKILL_GRAVITY, ULT_HOOK;


public Plugin:myinfo = 
{
    name = "War3Source Race - Hawkeye",
    author = "Remy Lebeau",
    description = "Ready's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Hawkeye [PRIVATE]","hawkeye");
    
    SKILL_EXPLOSIVE=War3_AddRaceSkill(thisRaceID,"Explosive Arrow","Shoots an explosive arrow and does aoe damage",false,5);
    SKILL_FROST=War3_AddRaceSkill(thisRaceID,"Frost Arrow","Shoots an arrow and slows down target",false,5);
    SKILL_DRUG=War3_AddRaceSkill(thisRaceID,"Poison Arrow","Shoots an arrow and drugs the target",false,5);
    SKILL_GRAVITY=War3_AddRaceSkill(thisRaceID,"Low gravity","Superheroes can jump higher, everyone knows that!",false,4);
    ULT_HOOK=War3_AddRaceSkill(thisRaceID,"Grappling hook","Shoots an arrow and pull yourself towards that direction(+ultimate)",true,1);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_HOOK,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
}

#define EXPLOSIVEARROW 0
#define FROSTARROW 1
#define DRUGARROW 2
#define NORMALARROW 3


// ABILITY ARROW COUNTERS
new g_iExplosiveArrow[MAXPLAYERS];
new g_iFrostArrow[MAXPLAYERS];
new g_iDrugArrow[MAXPLAYERS];
new g_iLoadedArrow[MAXPLAYERS];


// SKILL AMOUNTS
new Float:g_fGravity[5] = {1.0, 0.85, 0.7, 0.6, 0.5};
new Float:FrostArrow=0.35;
new g_iExplosionModel; 
new g_iExplosionRadius=90; 
new Float:g_fExplosionDamage=100.0;
new bool:g_bHitByExplosion;
new Float:PushForce = 1.2;


new String:ult_sound[] = "weapons/357/357_spin1.wav";
new FreezeSprite1, GlowSprite;
new m_vecBaseVelocity;



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    HookEvent("bullet_impact",BulletImpact);
    HookEvent("weapon_fire",WeaponFire);

    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );


}



public OnMapStart()
{
    War3_PrecacheSound( ult_sound );
    g_iExplosionModel = PrecacheModel( "materials/sprites/zerogxplode.vmt", false );
    FreezeSprite1 = PrecacheModel( "materials/effects/combineshield/comshieldwall.vmt" );
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
    War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.2  );
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout, weapon_smokegrenade");
    
    new skill_gravity = War3_GetSkillLevel( client, thisRaceID, SKILL_GRAVITY );
    War3_SetBuff( client, fLowGravitySkill, thisRaceID, g_fGravity[skill_gravity]  );
    
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
        W3ResetAllBuffRace( client, thisRaceID );
        InitPassiveSkills(client);
        
        // Set quiver amounts.
        new skill_explosive = War3_GetSkillLevel( client, thisRaceID, SKILL_EXPLOSIVE );
        new skill_frost = War3_GetSkillLevel( client, thisRaceID, SKILL_FROST );
        new skill_drug = War3_GetSkillLevel( client, thisRaceID, SKILL_DRUG );
    
        g_iExplosiveArrow[client] = skill_explosive;
        g_iFrostArrow[client] = skill_frost;
        g_iDrugArrow[client] = skill_drug;
        g_iLoadedArrow[client] = NORMALARROW;
        
        CreateTimer( 1.0, GiveWep, client );
        
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


public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_HOOK );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_HOOK, true ) )
            {
                TeleportPlayer( client );
                EmitSoundToAll( ult_sound, client );
                War3_CooldownMGR( client, 10.0, thisRaceID, ULT_HOOK );
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            if(ability==EXPLOSIVEARROW && pressed)
            {
                CheckExplosive(client);
            }
            if(ability==FROSTARROW && pressed)
            {
                CheckFrost(client);
            }
            if(ability==DRUGARROW && pressed)
            {
                CheckDrug(client);
            }
            if(ability==NORMALARROW && pressed)
            {
                g_iLoadedArrow[client] = NORMALARROW;
                PrintToChat(client, "NORMAL Arrows loaded.");
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



    
public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, "weapon_scout" );
        GivePlayerItem( client, "weapon_smokegrenade" );
    }
}
    
public Action:StopDrug( Handle:timer, any:client )
{
    if( ValidPlayer( client ) )
    {
        ServerCommand( "sm_drug #%d 0", GetClientUserId( client ) );
    }
}

public Action:unfrost(Handle:timer,any:client)
{
    War3_SetBuff(client,fSlow,thisRaceID,1.0);
    War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
}

public CheckExplosive(client)
{
    if (g_iExplosiveArrow[client] > 0)
    {
        if(g_iLoadedArrow[client] != EXPLOSIVEARROW)
        {
            PrintToChat(client, "EXPLOSIVE Arrows loaded. |%i| remaining", g_iExplosiveArrow[client]);
            g_iLoadedArrow[client] = EXPLOSIVEARROW;
        }
     
    }
    else
    {
        g_iLoadedArrow[client] = NORMALARROW;
        PrintToChat(client, "\x01You have no EXPLOSIVE arrows left.  \x03Normal Arrows loaded.");
    }
}

public CheckFrost(client)
{
    if (g_iFrostArrow[client] > 0)
    {
        if (g_iLoadedArrow[client] != FROSTARROW)
        {
            g_iLoadedArrow[client] = FROSTARROW;
            PrintToChat(client, "FROST Arrows loaded. |%i| remaining", g_iFrostArrow[client]);
        }
    }
    else
    {
        g_iLoadedArrow[client] = NORMALARROW;
        PrintToChat(client, "\x01You have no FROST arrows left.  \x03Normal Arrows loaded.");
    }
}

public CheckDrug(client)
{
    if (g_iDrugArrow[client] > 0)
    {
        if (g_iLoadedArrow[client] != DRUGARROW)
        {
            g_iLoadedArrow[client] = DRUGARROW;
            PrintToChat(client, "DRUG Arrows loaded. |%i| remaining", g_iDrugArrow[client]);
        }
    }
    else
    {
        g_iLoadedArrow[client] = NORMALARROW;
        PrintToChat(client, "\x01You have no DRUG arrows left.  \x03Normal Arrows loaded.");
    }
}


public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
    
    new client_userid = GetEventInt(event, "userid");    
    new attacker = GetClientOfUserId(client_userid);
    if(ValidPlayer(attacker, true) && (War3_GetRace( attacker ) == thisRaceID) )
    {
 
        new Float:Origin[3];
        Origin[0] = GetEventFloat(event,"x");
        Origin[1] = GetEventFloat(event,"y");
        Origin[2] = GetEventFloat(event,"z");
        
        new our_team = GetClientTeam(attacker);
        new radius = g_iExplosionRadius;
        new bool:friendlyfire = GetConVarBool(FindConVar("mp_friendlyfire"));
        new Float:location_check[3];
        
        if (g_iLoadedArrow[attacker] == EXPLOSIVEARROW && g_bHitByExplosion == false)
        {
            TE_SetupExplosion(Origin, g_iExplosionModel,10.0,1,0,g_iExplosionRadius,160);
            TE_SendToAll();
            
            g_bHitByExplosion = true;
            CreateTimer(0.2,Exploded,attacker);

            for(new x=1;x<=MaxClients;x++)
            {
                if(ValidPlayer(x,true)&&attacker!=x)
                {

                    new team=GetClientTeam(x);
                    if(team==our_team&&!friendlyfire)
                        continue;
            
                    GetClientAbsOrigin(x,location_check);
                    new Float:distance=GetVectorDistance(Origin,location_check);
                    if(distance>radius)
                        continue;
            
                    if(!W3HasImmunity(x,Immunity_Skills))
                    {

                        new Float:factor=(radius-distance)/radius;
                        new damage;
                        damage=RoundFloat(g_fExplosionDamage*factor);
                        War3_DealDamage(x,damage,attacker,_,"tankexplosion",W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC);
                        War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
                        W3FlashScreen(x,RGBA_COLOR_RED);
                        W3PrintSkillDmgHintConsole(x, attacker, damage, SKILL_EXPLOSIVE);
                        
                    }
                }            
            }

        }
        if (g_iLoadedArrow[attacker] == FROSTARROW && g_bHitByExplosion == false)
        {
            TE_SetupEnergySplash(Origin, Origin, false);
            TE_SendToAll();
            g_bHitByExplosion = true;
            CreateTimer(0.2,Exploded,attacker);
            
            for(new x=1;x<=MaxClients;x++)
            {
                if(ValidPlayer(x,true)&&attacker!=x)
                {

                    new team=GetClientTeam(x);
                    if(team==our_team&&!friendlyfire)
                        continue;
            
                    GetClientAbsOrigin(x,location_check);
                    new Float:distance=GetVectorDistance(Origin,location_check);
                    if(distance>radius)
                        continue;
            
                    if(!W3HasImmunity(x,Immunity_Skills) )
                    {

                        new Float:factor=(radius-distance)/radius;

                        War3_SetBuff(x,fSlow,thisRaceID,FrostArrow);
                        War3_SetBuff(x,fAttackSpeed,thisRaceID,FrostArrow);
                        W3FlashScreen(x,RGBA_COLOR_BLUE);
                        CreateTimer(6.0*factor,unfrost,x);
                        
                        PrintHintText(x,"You have been hit by a Frost Arrow");
                        War3_ShakeScreen(x,1.0*factor,250.0*factor,30.0);
                    }
                }            
            }
        }
        if (g_iLoadedArrow[attacker] == DRUGARROW && g_bHitByExplosion == false)
        {
            TE_SetupGlowSprite( Origin, GlowSprite, 4.0, 2.0, 255 );
            TE_SendToAll();
            g_bHitByExplosion = true;
            CreateTimer(0.2,Exploded,attacker);
            
            for(new x=1;x<=MaxClients;x++)
            {
                if(ValidPlayer(x,true)&&attacker!=x)
                {

                    new team=GetClientTeam(x);
                    if(team==our_team&&!friendlyfire)
                        continue;
            
                    GetClientAbsOrigin(x,location_check);
                    new Float:distance=GetVectorDistance(Origin,location_check);
                    if(distance>radius)
                        continue;
            
                    if(!W3HasImmunity(x,Immunity_Skills) )
                    {

                        new Float:factor=(radius-distance)/radius;

                        ServerCommand( "sm_drug #%d 1", GetClientUserId( x ) );
                        W3FlashScreen(x,RGBA_COLOR_YELLOW);
                        CreateTimer(6.0*factor,StopDrug,x);
                        
                        PrintHintText(x,"You have been hit by a Drug Arrow");
                        War3_ShakeScreen(x,1.0*factor,250.0*factor,30.0);
                        
                    }
                }            
            }
        }
    }
}



public WeaponFire(Handle:event,const String:name[],bool:dontBroadcast)
{
    
    new client_userid = GetEventInt(event, "userid");    
    new attacker = GetClientOfUserId(client_userid);
    if(ValidPlayer(attacker, true) && (War3_GetRace( attacker ) == thisRaceID) )
    {
        if (g_iLoadedArrow[attacker] == EXPLOSIVEARROW)
        {
            CreateTimer( 0.2, TimedExplosive, attacker );
        }
        if (g_iLoadedArrow[attacker] == FROSTARROW)
        {
            CreateTimer( 0.2, TimedFrost, attacker );
        }
        if (g_iLoadedArrow[attacker] == DRUGARROW)
        {
            CreateTimer( 0.2, TimedDrug, attacker );
        }
    }
}

public Action:TimedExplosive( Handle:timer, any:attacker )
{
    g_iExplosiveArrow[attacker]--;
    CheckExplosive(attacker);
}
public Action:TimedFrost( Handle:timer, any:attacker )
{
    g_iFrostArrow[attacker]--;
    CheckFrost(attacker);
}
public Action:TimedDrug( Handle:timer, any:attacker )
{
    g_iDrugArrow[attacker]--;
    CheckDrug(attacker);
}



public Action:Exploded(Handle:timer,any:client)
{
    g_bHitByExplosion = false;   
}



stock TeleportPlayer( client )
{
    if( client > 0 && IsPlayerAlive( client ) )
    {
        new Float:startpos[3];
        new Float:endpos[3];
        new Float:localvector[3];
        new Float:velocity[3];
        
        GetClientAbsOrigin( client, startpos );
        War3_GetAimTraceMaxLen(client, endpos, 2500.0);
        
        localvector[0] = endpos[0] - startpos[0];
        localvector[1] = endpos[1] - startpos[1];
        localvector[2] = endpos[2] - startpos[2];
        
        velocity[0] = localvector[0] * PushForce;
        velocity[1] = localvector[1] * PushForce;
        velocity[2] = localvector[2] * PushForce;
        
        SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
        
        TE_SetupBeamPoints( startpos, endpos, FreezeSprite1, FreezeSprite1, 0, 0, 1.0, 1.0, 1.0, 0, 0.0, { 255, 14, 41, 255 }, 0 );
        TE_SendToAll();
        
        TE_SetupBeamRingPoint( endpos, 11.0, 9.0, FreezeSprite1, FreezeSprite1, 0, 0, 2.0, 13.0, 0.0, { 255, 100, 100, 255 }, 0, FBEAM_ISACTIVE );
        TE_SendToAll();
    }
}