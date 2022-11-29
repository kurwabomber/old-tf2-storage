/**
* File: War3Source_999_SpeedDemon.sp
* Description: Speed Demon Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_WEAPON, ULT_LIGHTNING;

#define WEAPON_RESTRICT "weapon_knife,weapon_p228"
#define WEAPON_GIVE "weapon_p228"

public Plugin:myinfo = 
{
    name = "War3Source Race - Speed Demon",
    author = "Remy Lebeau",
    description = "Wookie Warlord's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.0, 1.0, 1.1, 1.2, 1.3, 1.35, 1.4, 1.45 };
new Float:g_fSlow[] = { 0.8, 0.9, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 };
new g_iHealth[]={100, 85, 70, 55, 45, 35, 25, 15, 0};

new Handle:freezetimecvar;
new g_iAmmo = 100;

new String:lightningSound[256]; //="war3source/lightningbolt.mp3";
new Float:ChainDistance[]={0.0,150.0,200.0,250.0,300.0, 325.0, 350.0, 400.0, 450.0};
new Float:UltCooldown = 20.0;
new bool:bBeenHit[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; // [caster][victim] been hit this chain lightning?
new BeamSprite,HaloSprite,BloodSpray,BloodDrop; 


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Speed Demon [PRIVATE]","speeddemon");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speedy Sacrifice","Lose health but gain speed",false,8);
    SKILL_WEAPON=War3_AddRaceSkill(thisRaceID,"Demonic Weapon","Spawn a compact with 1 50 bullet clip",false,1);
    ULT_LIGHTNING=War3_AddRaceSkill(thisRaceID,"Greased Lightning","Electrify your enemies",false,8);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_LIGHTNING,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fSlow, g_fSlow);
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, iAdditionalMaxHealth, g_iHealth);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    freezetimecvar = FindConVar("mp_freezetime");
}



public OnMapStart()
{
    War3_AddSoundFolder(lightningSound, sizeof(lightningSound), "lightningbolt.mp3");
    War3_AddCustomSound(lightningSound);
    BeamSprite=War3_PrecacheBeamSprite(); 
    HaloSprite=War3_PrecacheHaloSprite(); 

    BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
    if(GAMECSGO) {
        BloodDrop = PrecacheModel("decals/blood1.vmt");
    }
    else {
        BloodDrop = PrecacheModel("sprites/blood.vmt");
    }

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
    new level = War3_GetSkillLevel(client, thisRaceID, SKILL_WEAPON);
    if(level)
        CreateTimer( 0.1, GiveWep, client );

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



public DoChain(client,Float:distance,dmg,bool:first_call,last_target)
{
    new target=0;
    new Float:target_dist=distance+1.0; // just an easy way to do this
    new caster_team=GetClientTeam(client);
    new Float:start_pos[3];
    if(last_target<=0)
        GetClientAbsOrigin(client,start_pos);
    else
        GetClientAbsOrigin(last_target,start_pos);
    for(new x=1;x<=MaxClients;x++)
    {
        if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Ultimates))
        {
            new Float:this_pos[3];
            GetClientAbsOrigin(x,this_pos);
            new Float:dist_check=GetVectorDistance(start_pos,this_pos);
            if(dist_check<=target_dist)
            {
                // found a candidate, whom is currently the closest
                target=x;
                target_dist=dist_check;
            }
        }
    }
    if(target<=0)
    {
        if(first_call)
        {
            W3MsgNoTargetFound(client,distance);
        }
        else
        {
            War3_CooldownMGR(client,UltCooldown,thisRaceID,ULT_LIGHTNING,_,_);
        }
    }
    else
    {
        // found someone
        bBeenHit[client][target]=true; // don't let them get hit twice
        War3_DealDamage(target,dmg,client,DMG_ENERGYBEAM,"chainlightning");
        PrintHintText(target,"Hit by Chain Lightning -%d HP",War3_GetWar3DamageDealt());
        start_pos[2]+=30.0; // 
        decl Float:target_pos[3],Float:vecAngles[3];
        GetClientAbsOrigin(target,target_pos);
        target_pos[2]+=30.0;
        TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,HaloSprite,0,35,1.0,25.0,25.0,0,10.0,{255,100,255,255},40);
        TE_SendToAll();
        GetClientEyeAngles(target,vecAngles);
        TE_SetupBloodSprite(target_pos, vecAngles, {200, 20, 20, 255}, 28, BloodSpray, BloodDrop);
        TE_SendToAll();
        EmitSoundToAll( lightningSound , target,_,SNDLEVEL_TRAIN);
        new new_dmg=RoundFloat(float(dmg)*0.66);
        
        DoChain(client,distance,new_dmg,false,target);
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && IsPlayerAlive(client))
    {
        new skill=War3_GetSkillLevel(client,race,ULT_LIGHTNING);
        //DP("skill level %d",skill);
        if(skill>0)
        {
            
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_LIGHTNING,true)&&!Silenced(client))
            {
                    
                for(new x=1;x<=MaxClients;x++)
                    bBeenHit[client][x]=false;
                
                new Float:distance=ChainDistance[skill];
                
                DoChain(client,distance,60,true,0); // This function should also handle if there aren't targets
            }
        }
        else
        { 
            W3MsgUltNotLeveled(client);
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
        Client_GiveWeapon(client, WEAPON_GIVE, true);
        CreateTimer( GetConVarFloat(freezetimecvar), SetWepAmmo, client );
    }
}

public Action:SetWepAmmo( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_SetWeaponAmmo(client, WEAPON_GIVE, 0,0,g_iAmmo,0); 
    }
}


