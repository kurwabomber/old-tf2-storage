/**
* File: War3Source_999_Rambo.sp
* Description: Rambo Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_AMMO, SKILL_INVIS, SKILL_HEALTH, ULT_BAZOOKA;



public Plugin:myinfo = 
{
    name = "War3Source Race - Rambo",
    author = "Remy Lebeau",
    description = "Rambo race for War3Source",
    version = "1.1",
    url = "http://sevensinsgaming.com"
};


new g_iHealthBase=1000;
//new String:RamboModel[] = "models/player/bz/ghost/bzghost.mdl";
new g_iDeagleAmmo[MAXPLAYERS];

/*
// Invis 
new InvisTime=20;
new m_vecVelocity = -1;
new Float:canspeedtime[MAXPLAYERS+1];
new AcceleratorDelayer[MAXPLAYERS];
new bool:InvisTrue[MAXPLAYERS];
*/

new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new bool:bTransformed[64];
new Float:UltTime = 10.0;

new g_iExplosionModel; 
new g_iExplosionRadius=120; 

new Float:g_fExplosionDamage=70.0;

new g_iBulletCounter; 
new bool:g_bHitByExplosion;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Rambo [RAMBO]","rambo");
    
    SKILL_AMMO=War3_AddRaceSkill(thisRaceID,"Hollywood Bullets","Rambo has a LOT of ammo",false,10);
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Pects of steal","Can take a LOT of damage",false,10);
    ULT_BAZOOKA=War3_AddRaceSkill(thisRaceID,"Bazooka","HEAVY firepower (1 shot / 8 players)",false,10);
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Camouflage","Face painting to the MAX(+ultimate)",false,10);
    
    
    War3_CreateRaceEnd(thisRaceID);
    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    //m_vecVelocity = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    
//    CreateTimer(0.1, CalcSpeed,_,TIMER_REPEAT);
    HookEvent("bullet_impact",BulletImpact);
    
    // SNIPER ULTIMATE
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
    m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
    HookEvent( "player_jump", PlayerJumpEvent );
}



public OnMapStart()
{
//    PrecacheModel(RamboModel, true);
    g_iExplosionModel = PrecacheModel( "materials/sprites/zerogxplode.vmt", false );
}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


InitPassiveSkills( client )
{
    g_iDeagleAmmo[client] = RoundToFloor(GetClientCount()/6.0);
    if(g_iDeagleAmmo[client] > 0)
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_ak47,weapon_knife,weapon_deagle,weapon_hegrenade,weapon_flashbang,weapon_smokegrenade");
        CPrintToChat(client, "{red}RAMBO: {default} You first |%d| deagle bullets are explosve", g_iDeagleAmmo[client]);
    }
    else
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_ak47,weapon_knife,weapon_hegrenade,weapon_flashbang,weapon_smokegrenade");
    }    
    
    if (SKILL_AMMO && SKILL_INVIS && SKILL_HEALTH && ULT_BAZOOKA)
    {
        // DO NOTHING, THIS IS JUST TO AVOID WARNINGS
    }
//    SetEntityModel(client, RamboModel);
    new TotalHealth = g_iHealthBase;
    new PlayerMultiplier = GetClientCount();
    if (PlayerMultiplier < 11)
    {
        TotalHealth = g_iHealthBase + (PlayerMultiplier * 300);
    }
    else if (PlayerMultiplier >= 11 && PlayerMultiplier < 21)
    {
        TotalHealth = g_iHealthBase + (PlayerMultiplier * 350);
    }
    else if (PlayerMultiplier >= 21 && PlayerMultiplier < 31)
    {
        TotalHealth = g_iHealthBase + (PlayerMultiplier * 400);
    }
    else if (PlayerMultiplier >= 31)
    {
        TotalHealth = g_iHealthBase + (PlayerMultiplier * 500);
    }
    
    War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,TotalHealth);

    War3_SetBuff(client,bSlowImmunity,thisRaceID,true);
    War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
    War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
    War3_SetBuff(client,bImmunityWards,thisRaceID,true);
    War3_SetBuff(client,bImmunityItems,thisRaceID,true);
    War3_SetBuff(client,bImmunityAbilities,thisRaceID,true);
    bTransformed[client] = false;
    
    
    
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills( client );
        CreateTimer( 2.0, GiveWep, client );
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
        CreateTimer( 2.0, GiveWep, client );
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
        if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_INVIS, true ) )
        {
            StartTransform( client );
            War3_CooldownMGR( client, UltTime + 5.0, thisRaceID, SKILL_INVIS, _, _ );
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

public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client_userid = GetEventInt(event, "userid");    
    new client = GetClientOfUserId(client_userid);
    if(ValidPlayer(client, true) && (War3_GetRace( client ) == thisRaceID) )
    {
        new String:wpnstr[32];
        GetClientWeapon( client, wpnstr, 32 );
        if( StrEqual( wpnstr, "weapon_deagle" ) && g_iDeagleAmmo[client] > 0)
        {
            g_iDeagleAmmo[client]--;
            new our_team = GetClientTeam(client);
            new radius = g_iExplosionRadius;
            
            new Float:Origin[3];
            Origin[0] = GetEventFloat(event,"x");
            Origin[1] = GetEventFloat(event,"y");
            Origin[2] = GetEventFloat(event,"z");
                
            TE_SetupExplosion(Origin, g_iExplosionModel,10.0,1,0,g_iExplosionRadius,160);
            TE_SendToAll();
            
            
            new bool:friendlyfire = GetConVarBool(FindConVar("mp_friendlyfire"));
            new Float:location_check[3];
            
            g_iBulletCounter += 1;
            for(new x=1;x<=MaxClients;x++)
            {
                if(ValidPlayer(x,true)&&client!=x)
                {
                    new String:xName[256];
                    GetClientName(x, xName, sizeof(xName));
                    
    
                    
                    new team=GetClientTeam(x);
                    if(team==our_team&&!friendlyfire)
                        continue;
            
                    GetClientAbsOrigin(x,location_check);
                    new Float:distance=GetVectorDistance(Origin,location_check);
                    if(distance>radius)
                        continue;
            
                    if(!W3HasImmunity(x,Immunity_Skills) && g_bHitByExplosion == false)
                    {
                        g_bHitByExplosion = true;
                        CreateTimer(0.2,Exploded,x);
                        new Float:factor=(radius-distance)/radius;
                        new damage;
                        damage=RoundFloat(g_fExplosionDamage*factor);
                        War3_DealDamage(x,damage,client,_,"bzookaexplosion",W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC);
                        War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
                        W3FlashScreen(x,RGBA_COLOR_RED);
                        W3PrintSkillDmgHintConsole(x, client, damage, ULT_BAZOOKA);
                        
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

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_RemoveWeapon(client, "weapon_deagle");
        Client_RemoveWeapon(client, "weapon_ak47");
        
        
        Client_GiveWeaponAndAmmo(client, "weapon_ak47", true, 1000,_,1000,_);
        Client_GiveWeaponAndAmmo(client, "weapon_deagle", false, 1000,1000,_,_);
        Client_GiveWeapon(client, "weapon_hegrenade", false);
        Client_GiveWeapon(client, "weapon_flashbang", false);
        Client_GiveWeapon(client, "weapon_flashbang", false);
        Client_GiveWeapon(client, "weapon_smokegrenade", false);
    }
}
/*
public Action:CalcSpeed(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID)
        {
            if(canspeedtime[i] < GetGameTime() )
            {
                //PrintToChat(i, "Standing still, invis in |%d|",AcceleratorDelayer[i]);
                AcceleratorDelayer[i]++;
                if(AcceleratorDelayer[i] == InvisTime)
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
            if(GetVectorLength(velocity) > 0)
            {
                canspeedtime[i] = GetGameTime() + 1.0;
            }
        }
    }    
}
*/

public Action:Exploded(Handle:timer,any:client)
{

    g_bHitByExplosion = false;
    
}



stock StartTransform( client )
{
    CreateTimer( UltTime, EndTransform, client );
    War3_SetBuff( client, fLowGravitySkill, thisRaceID, 0.35 );
    War3_SetBuff( client, fMaxSpeed, thisRaceID, 2.2 );
    bTransformed[client] = true;
}

public Action:EndTransform( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
        War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
        bTransformed[client] = false;
    }
}

public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        if( bTransformed[client] )
        {
            new Float:velocity[3] = { 0.0, 0.0, 0.0 };
            velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
            velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
            velocity[0] *= 1.6;
            velocity[1] *= 1.6;
            SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
        }
    }
}