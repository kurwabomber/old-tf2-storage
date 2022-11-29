/**
* File: War3Source_999_Pikachu.sp
* Description: Pikachu Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions"

new thisRaceID;
new SKILL_DAMAGE, SKILL_EVADE, SKILL_LIGHTNING, ULT_STRIKE;



public Plugin:myinfo = 
{
    name = "War3Source Race - Pikachu",
    author = "Remy Lebeau",
    description = "spraynpray's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fEvade[] = { 0.0, 0.05, 0.10, 0.15, 0.20 };
new Float:DMG3Multiplier[6] = { 0.0, 0.80, 0.90, 1.1, 1.3 };
new BeamSprite,HaloSprite,BloodSpray,BloodDrop; 


new bool:bBeenHit[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; // [caster][victim] been hit this chain lightning?
new Float:ChainDistance[]={0.0,150.0,200.0,250.0,300.0};
new String:lightningSound[256]; //="war3source/lightningbolt.mp3";
new Float:g_fUltCooldown = 30.0;

new StrikeDamage[] = { 0, 10, 15, 20, 25 };
new Float:g_fStunTime[] = { 0.0, 2.0, 3.0, 4.0, 5.0 };

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Pikachu [PRIVATE]","pikachu");
    
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Thundershock","*Increases passive damage.",false,4);
    SKILL_EVADE=War3_AddRaceSkill(thisRaceID,"Double Team","Raises the user's Evasiveness.",false,4);
    SKILL_LIGHTNING=War3_AddRaceSkill(thisRaceID,"Thunderbolt","Lightning strike (+ability)",false,4);
    ULT_STRIKE=War3_AddRaceSkill(thisRaceID,"PIKACHU THUNDER NOW!","Damage and 30% chance of paralyzing the target for 6 seconds (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_STRIKE,15.0,_);
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_LIGHTNING,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_EVADE, fDodgeChance, g_fEvade);

    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    
}



public OnMapStart()
{
    BeamSprite=War3_PrecacheBeamSprite(); 
    HaloSprite=War3_PrecacheHaloSprite(); 
    BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
    if(GAMECSGO) {
        BloodDrop = PrecacheModel("decals/blood1.vmt");
    }
    else {
        BloodDrop = PrecacheModel("sprites/blood.vmt");
    }
    War3_AddSoundFolder(lightningSound, sizeof(lightningSound), "lightningbolt.mp3");
    War3_AddCustomSound(lightningSound);
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
    War3_SetBuff( client, bDodgeMode, thisRaceID, 0 );

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
    if( race == thisRaceID && pressed && ValidPlayer( client, true ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_STRIKE );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_STRIKE, true ) )
            {
                Strike( client );
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
    if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true) && ability==0)
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID,SKILL_LIGHTNING );
        if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_LIGHTNING,true))
        {
            if(skill_level > 0)
            {
              
                for(new x=1;x<=MaxClients;x++)
                    bBeenHit[client][x]=false;
                
                new Float:distance=ChainDistance[skill_level];
                
                DoChain(client,distance,60,true,0); // This function should also handle if there aren't targets


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


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_dmg3 = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DAMAGE );
            if( !Hexed( attacker, false ) && skill_dmg3 > 0 && GetRandomFloat( 0.0, 1.0 ) <= 0.30 )
            {
                War3_DealDamage( victim, RoundToFloor( damage * DMG3Multiplier[skill_dmg3] ), attacker, DMG_BULLET, "thundershock" );
                
                W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DAMAGE );
                
                new Float:attacker_pos[3];
                new Float:victim_pos[3];
                
                GetClientAbsOrigin( attacker, attacker_pos );
                GetClientAbsOrigin( victim, victim_pos );
                
                TE_SetupBeamPoints( attacker_pos, victim_pos, HaloSprite, HaloSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 50, 20, 255, 255 }, 0 );
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
        if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Skills))
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

            War3_CooldownMGR(client,g_fUltCooldown,thisRaceID,SKILL_LIGHTNING,_,_);
        }
    }
    else
    {
        // found someone
        bBeenHit[client][target]=true; // don't let them get hit twice
        War3_DealDamage(target,dmg,client,DMG_ENERGYBEAM,"chainlightning");
        PrintHintText(target,"Hit by Chain Lightning -%d HP",War3_GetWar3DamageDealt());
        start_pos[2]+=30.0; // offset for effect
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



stock Strike( client )
{
    new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_STRIKE );
    new bestTarget;
    
    if( GetClientTeam( client ) == TEAM_T )
        bestTarget = War3_GetRandomPlayer(client, "#ct", true, true );
    if( GetClientTeam( client ) == TEAM_CT )
        bestTarget = War3_GetRandomPlayer(client, "#t", true, true );

    if( bestTarget == 0 )
    {
        PrintHintText( client, "No Target Found" );
    }
    else
    {
        War3_DealDamage( bestTarget, StrikeDamage[ult_level], client, DMG_BULLET, "electric_strike" );
        
        if( GetRandomFloat( 0.0, 1.0 ) <= 0.30 )
        {
            
            War3_SetBuff(bestTarget,bNoMoveMode,thisRaceID,true);
            CreateTimer(g_fStunTime[ult_level], StopStun,GetClientUserId(bestTarget));
            
            
            War3_SetBuff(client,bNoMoveMode,thisRaceID,true);
            War3_SetBuff(client, bDisarm, thisRaceID, true  );
            W3FlashScreen( client, RGBA_COLOR_RED );
            CreateTimer(2.0, StopStun, GetClientUserId(client));
            PrintHintText(client, "Stunned an enemy - Pikachu must recharge!");
        
        }
        
        W3PrintSkillDmgHintConsole( bestTarget, client, War3_GetWar3DamageDealt(), ULT_STRIKE );
        W3FlashScreen( bestTarget, RGBA_COLOR_RED );
        
        War3_CooldownMGR( client, 20.0, thisRaceID, ULT_STRIKE, _, _ );
        
        new Float:pos[3];
        
        GetClientAbsOrigin( client, pos );
        
        pos[2] += 40;
        
        TE_SetupBeamRingPoint( pos, 20.0, 50.0, BeamSprite, HaloSprite, 0, 0, 3.0, 60.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
        TE_SendToAll();
    }
}


public Action:StopStun(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
    War3_SetBuff(client, bDisarm, thisRaceID, false  );
    
}
