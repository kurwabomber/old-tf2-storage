/**
* File: War3Source_999_IronMan.sp
* Description: Iron MAn Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_HEALTH, SKILL_FLY, SKILL_CANNON, ULT_SENSE;

#define WEAPON_RESTRICT "weapon_knife,weapon_elite"
#define WEAPON_GIVE "weapon_elite"

public Plugin:myinfo = 
{
    name = "War3Source Race - Iron Man",
    author = "Remy Lebeau",
    description = "Iron Man race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new g_iHealth[]={0,12,25,50,75};

new g_iExplosionModel; 
new g_iExplosionRadius[]={0,30,40,50,60}; 
new Float:g_fExplosionDamage[]={0.0,20.0,30.0,40.0,50.0};
new g_iBulletCounter; 
new bool:g_bHitByExplosion;

new bool:bFlying[MAXPLAYERS];
new Float:g_fAbilityCooldownTime = 10.0;
new Float:g_fFlyTime[] = {0.0, 3.0, 5.0, 7.0, 9.0};



new Float:SenseOrigin[MAXPLAYERSCUSTOM][3];
new Float:SenseRadius=600.0;
new Float:SenseTime[] = {0.0,2.0,3.0,6.0,8.0};
new Float:this_pos[3];
new GlowSprite,GlowSprite2;
new bool:bFaerie[66];
new Float:UltimateCooldownTime=20.0;
new String:ScanSound[]="ambient/office/button1.wav";

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Iron Man","ironman");
    
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Iron Suit Armor","Bonus HP (12/25/50/75)",false,4);
    SKILL_FLY=War3_AddRaceSkill(thisRaceID,"Jet Boosters","Flight (3/6/9/12 seconds +ability)",false,4);
    SKILL_CANNON=War3_AddRaceSkill(thisRaceID,"Hand Cannon","20% of your bullets explode",false,4);
    ULT_SENSE=War3_AddRaceSkill(thisRaceID,"Iron Suit Sensors","Detect the players who are close (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_FLY,10.0,_);
    W3SkillCooldownOnSpawn(thisRaceID,ULT_SENSE,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, g_iHealth);
    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    HookEvent("bullet_impact",BulletImpact);
}



public OnMapStart()
{
    g_iExplosionModel = PrecacheModel( "materials/sprites/zerogxplode.vmt", false );
    GlowSprite=PrecacheModel("effects/redflare.vmt");
    GlowSprite2=PrecacheModel("materials/effects/fluttercore.vmt");
    War3_PrecacheSound(ScanSound);
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
    bFlying[client] = false;
    War3_SetBuff( client, bFlyMode, thisRaceID, false );
    War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );

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
        bFlying[client] = false;
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



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID, ULT_SENSE );
        if(skill_level>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_SENSE,true)) 
                {
                    new team = GetClientTeam(client);
                    new Float:otherVec[3];
                    new victimcounter = 0;
                    new victimlist[MAXPLAYERS];
                    GetClientAbsOrigin(client,SenseOrigin[client]);
                    SenseOrigin[client][2]+=15.0;
                    PrintHintText(client,"Scan activated");
                    for(new i=1;i<=MaxClients;i++)
                    {
                        if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates))
                        {        
                            GetClientAbsOrigin(i,otherVec);
                            otherVec[2]+=30.0;
                            new Float:victimdistance=GetVectorDistance(SenseOrigin[client],otherVec);

                            if(victimdistance<SenseRadius)
                            {
                                victimlist[victimcounter] = i;
                                victimcounter++;
                            }
                            
                        }
                    }

                    for(new i=0;i<victimcounter;i++)
                    {
                        new temp = victimlist[i];
                        if(ValidPlayer(temp,true))
                        {
                            PrintHintText(temp,"You are being tracked by Iron Man");
                            bFaerie[temp]=true;
                            CreateTimer(SenseTime[skill_level],faerieoff,temp);
                        }
                    }
                    W3EmitSoundToAll(ScanSound, client);
                    War3_CooldownMGR(client,UltimateCooldownTime,thisRaceID,ULT_SENSE,_,_);
                }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
}

public Action:faerieoff(Handle:h, any:client)
{
    if(IS_PLAYER(client))
    {
        bFaerie[client]=false;
    }
}



public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true) && ability==0)
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID,SKILL_FLY );
        if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_FLY,true))
        {
            if(skill_level > 0)
            {
              
                if( !bFlying[client] )
                {
                    bFlying[client] = true;
                    
                    War3_SetBuff( client, bFlyMode, thisRaceID, true );
                    War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.9 );
                    
                    PrintToChat( client, "\x05: \x03BOOST!" );
                    
                    CreateTimer( g_fFlyTime[skill_level], StopFly, client );
                    
                    CreateTimer( g_fFlyTime[skill_level] - 2.9, Land1, client );
                    CreateTimer( g_fFlyTime[skill_level] - 2.0, Land2, client );
                    CreateTimer( g_fFlyTime[skill_level] - 1.0, Land3, client );
                    
                    War3_CooldownMGR(client,g_fAbilityCooldownTime+g_fFlyTime[skill_level],thisRaceID,SKILL_FLY,_,_);
                }
                
                

            }
                
            else
            {
                PrintHintText(client, "Level Skill first");
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


public OnGameFrame()
{
    for(new i=1;i<=MaxClients;i++){
        if(ValidPlayer(i,true))
        {
            new tteam=GetClientTeam(i);
            if(bFaerie[i]==true)
            {
                GetClientAbsOrigin(i,this_pos);
                this_pos[2]+=20;//offset for effect
                if(tteam==2)
                {
                    TE_SetupGlowSprite(this_pos,GlowSprite,0.1,0.6,80);
                    TE_SendToAll();
                    //TE_SendToClient(client, Float:delay=0.0) 
                }
                else
                {
                    this_pos[2]+=20;
                    TE_SetupGlowSprite(this_pos,GlowSprite2,0.1,0.1,150);
                    TE_SendToAll();    
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
        new skill_cannon = War3_GetSkillLevel(client, thisRaceID, SKILL_CANNON);
        if (skill_cannon > 0 && GetRandomFloat(0.0,1.0) < 0.2 )
        {
            new our_team = GetClientTeam(client);
            new radius = g_iExplosionRadius[skill_cannon];
            
            new Float:Origin[3];
            Origin[0] = GetEventFloat(event,"x");
            Origin[1] = GetEventFloat(event,"y");
            Origin[2] = GetEventFloat(event,"z");
                
            TE_SetupExplosion(Origin, g_iExplosionModel,10.0,1,0,g_iExplosionRadius[skill_cannon],160);
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
                        damage=RoundFloat(g_fExplosionDamage[skill_cannon]*factor);
                        War3_DealDamage(x,damage,client,_,"tankexplosion",W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC);
                        War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
                        W3FlashScreen(x,RGBA_COLOR_RED);
                        W3PrintSkillDmgHintConsole(x, client, damage, SKILL_CANNON);
                        
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

public Action:Exploded(Handle:timer,any:client)
{

    g_bHitByExplosion = false;
    
}


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
        GivePlayerItem( client, WEAPON_GIVE );
    }
}


public Action:StopFly( Handle:timer, any:client )
{
    bFlying[client] = false;
    if( ValidPlayer( client, true ) )
    {
        War3_SetBuff( client, bFlyMode, thisRaceID, false );
        War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
    }
}

public Action:Land1( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        PrintToChat( client, "\x05: \x03Your going to land in \x043 \x03seconds!" );
    }
}

public Action:Land2( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        PrintToChat( client, "\x05: \x03Your going to land in \x042 \x03seconds!" );
    }
}

public Action:Land3( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        PrintToChat( client, "\x05: \x03Your going to land in \x041 \x03seconds!" );
    }
}