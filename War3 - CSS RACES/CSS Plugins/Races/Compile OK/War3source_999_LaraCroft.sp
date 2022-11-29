/**
* File: War3Source_999_LaraCroft.sp
* Description: Tomb Raider - Lara Croft Race for War3Source.
* Author(s): Remy Lebeau
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source Race - Lara Croft",
    author = "Remy Lebeau",
    description = "Lara Croft race for War3Source",
    version = "0.9.3",
    url = "sevensinsgaming.com"
};



// War3Source stuff + Sprite/Sound Variable
new thisRaceID;
new HaloSprite, BeamSprite;
new String:entangleSound[256];
new SKILL_ATHLETE, SKILL_ACROBAT, SKILL_WEP, SKILL_FLIP, ULT_DISTRACTION;

// Skill Variables
new Float:speedboost[] = { 1.0, 1.08, 1.14, 1.20, 1.25, 1.30 };
new Float:acrobatboost[] = { 1.0, 0.85, 0.75, 0.65, 0.55, 0.50 };
new Float:damageboost[] = { 0.0, 0.04, 0.08, 0.12, 0.16, 0.20 };
new Float:evadeboost[] = { 0.0, 0.03, 0.06, 0.09, 0.12, 0.15 };


// Ulti Variables
new Float:ElectricTideOrigin[MAXPLAYERSCUSTOM][3];
new Float:distractiontime[] = {0.0, 0.6, 0.7, 0.8, 0.9, 1.0 };
new Float:ElectricTideRadius=275.0;
new Float:AbilityCooldownTime=25.0;
new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];

// Race Model
new String:g_szRaceModel[PLATFORM_MAX_PATH] = "models/player/techknow/lara/laracroft.mdl";

new Handle:g_hCvarCustomModel = INVALID_HANDLE;
new bool:g_bCustomModel = false;



public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace( "Lara Croft (Tomb Raider)", "lara" );
    
    SKILL_ATHLETE = War3_AddRaceSkill( thisRaceID, "Athleticism", "Lara's speed is second to none", false, 5 );    
    SKILL_ACROBAT = War3_AddRaceSkill( thisRaceID, "Acrobatics", "Lara can jump as much as 3 times her own height", false, 5 );    
    
    if(War3_GetGame()!=Game_TF) 
        SKILL_WEP = War3_AddRaceSkill( thisRaceID, "Hollywood bullets", "These bullets REALLY pack a punch!", false, 5 );
    
    SKILL_FLIP = War3_AddRaceSkill( thisRaceID, "Flip", "Lara does crazy flips to avoid damage", false, 5 );
    ULT_DISTRACTION = War3_AddRaceSkill( thisRaceID, "Distraction", "That bountiful bosom is just SO mesmerizing ...", true, 5 );

    W3SkillCooldownOnSpawn( thisRaceID, ULT_DISTRACTION, 15.0, _ );
    
    War3_CreateRaceEnd( thisRaceID );
}

public OnPluginStart()
{

    g_hCvarCustomModel = CreateConVar("war3_lara_custom_model", "0", "Enable/Disable custom model for Lara Croft War3Source race");
    HookConVarChange(g_hCvarCustomModel, OnConVarChange);
}

public OnMapStart()
{
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
    strcopy(entangleSound,sizeof(entangleSound),"war3source/entanglingrootsdecay1.mp3");
    
    War3_AddCustomSound(entangleSound);
    
    
    if (g_bCustomModel && FileExists(g_szRaceModel))
    {
        AddFileToDownloadsTable(g_szRaceModel);
        PrecacheModel(g_szRaceModel, true);
    }
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
    new ath_level = War3_GetSkillLevel( client, thisRaceID, SKILL_ATHLETE );
    new acr_level = War3_GetSkillLevel( client, thisRaceID, SKILL_ACROBAT );
    new wep_level = War3_GetSkillLevel( client, thisRaceID, SKILL_WEP );
    new flip_level = War3_GetSkillLevel( client, thisRaceID, SKILL_FLIP );
    
    
    War3_SetBuff( client, fMaxSpeed, thisRaceID, speedboost[ath_level] );
    War3_SetBuff( client, fLowGravitySkill, thisRaceID, acrobatboost[acr_level] );
    War3_SetBuff( client, fDodgeChance, thisRaceID, evadeboost[flip_level] );
    War3_SetBuff( client, bDodgeMode, thisRaceID, 0 );
    
    War3_SetBuff( client, fDamageModifier, thisRaceID, damageboost[wep_level] );
    
    
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_elite");
    CreateTimer( 1.0, GiveWep, client );
    
    if (ValidPlayer(client, true))
        {
            if (g_bCustomModel && FileExists(g_szRaceModel))
            {
                SetEntityModel(client, g_szRaceModel);
            }
            
        }
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


public OnUltimateCommand( client, race, bool:pressed )
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new ult_dist = War3_GetSkillLevel( client, thisRaceID, ULT_DISTRACTION );
        if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_DISTRACTION,true))
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
                TE_SetupBeamRingPoint(ElectricTideOrigin[client], 20.0, ElectricTideRadius+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,255,133}, 60, 0);
                TE_SendToAll();
                
                CreateTimer(0.1, StunLoop,GetClientUserId(client));
                                
                CreateTimer(0.5, SecondRing,GetClientUserId(client));
                
                War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,ULT_DISTRACTION,_,_);
                
                PrintHintText(client,"Bouncy!");    
            }
                
            else
            {
                PrintHintText(client, "Level your Ultimate first");
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


public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, "weapon_elite" );
    }
}






public Action:SecondRing(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    TE_SetupBeamRingPoint(ElectricTideOrigin[client], ElectricTideRadius+50,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,255,133}, 60, 0);
    TE_SendToAll();
}

public Action:StunLoop(Handle:timer,any:userid)
{
    new attacker=GetClientOfUserId(userid);
    if(ValidPlayer(attacker) )
    {
        new team = GetClientTeam(attacker);
        new ult_dist1 = War3_GetSkillLevel( attacker, thisRaceID, ULT_DISTRACTION );
        
        new Float:otherVec[3];
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates))
            {        
                GetClientAbsOrigin(i,otherVec);
                otherVec[2]+=30.0;
                new Float:victimdistance=GetVectorDistance(ElectricTideOrigin[attacker],otherVec);
                if(victimdistance<ElectricTideRadius)
                {
                    new Float:entangle_time=distractiontime[ult_dist1];
                    new Float:effect_vec[3];
                    GetClientAbsOrigin(i,effect_vec);
                    effect_vec[2]+=15.0;
                    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{255,0,255,133},10,0);
                    TE_SendToAll();
                    effect_vec[2]+=15.0;
                    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{255,0,255,133},10,0);
                    TE_SendToAll();
                    effect_vec[2]+=15.0;
                    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{255,0,255,133},10,0);
                    TE_SendToAll();
                    
                    War3_SetBuff(i,bStunned,thisRaceID,true);
                    
                    W3EmitSoundToAll(entangleSound,i);
                    W3EmitSoundToAll(entangleSound,i);
                    CreateTimer(entangle_time,stopStun,i);
                    
                    
                }
            }
        }
    }
    
}
public Action:stopStun(Handle:timer,any:userid)
{
    War3_SetBuff(userid, bStunned, thisRaceID, false);
} 


public OnConVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
    GetConVars();
}

public OnConfigsExecuted()
{
    GetConVars();
}

GetConVars()
{
    g_bCustomModel = GetConVarBool(g_hCvarCustomModel);    
}