/**
* File: War3Source_999_DemonLord.sp
* Description: Demon Lord Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions"

new thisRaceID;
new SKILL_SPEED, SKILL_GRAVITY, SKILL_IMMUNITY, SKILL_SUMMON, ULT_STRIKE;



public Plugin:myinfo = 
{
    name = "War3Source Race - Demon Lord",
    author = "Remy Lebeau",
    description = "Sincro's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.16, 1.20, 1.24, 1.28 };
new Float:g_fGrav[] = { 1.0, 0.68, 0.60, 0.52, 0.44 };
new Float:g_fImmuneChance[] = {0.0, 0.25, 0.5, 0.75, 1.0};


new Float:g_fSummonCD[]={0.0,60.0,50.0,40.0,35.0};
new String:summon_sound[]="war3source/archmage/summon.wav";


new Float:g_fUltCooldown = 20.0;
new g_iStrikeDamage[] = { 0, 10, 15, 20, 25 };
new HaloSprite, BeamSprite;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Demon Lord [PRIVATE]","demonlord");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Demonic Haste","Increases the Demon Lord's movement speed",false,4);
    SKILL_GRAVITY=War3_AddRaceSkill(thisRaceID,"Demonic Leap","Increases the Demon Lord's jump height",false,4);
    SKILL_IMMUNITY=War3_AddRaceSkill(thisRaceID,"Demonic Skin","The Demon Lord can not be affected by ultimates",false,4);
    SKILL_SUMMON=War3_AddRaceSkill(thisRaceID,"Spawn Demon","Spawns a demon from Hell (+ability)",false,4);
    ULT_STRIKE=War3_AddRaceSkill(thisRaceID,"Soul Steal","The Demon Lord steals health from a random enemy player (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn( thisRaceID, ULT_STRIKE, 5.0, _);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_GRAVITY, fLowGravitySkill, g_fGrav);
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
}



public OnPluginStart()
{

}



public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
	War3_AddCustomSound(summon_sound);
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
    new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_IMMUNITY);
    if( GetRandomFloat(0.0,1.0)<=g_fImmuneChance[skill_level])
    {
        War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
        PrintHintText(client, "Skin is immune to ultimates");
    }   
    
    War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, 100);
    //W3SetPlayerColor( client, thisRaceID, 254, 0, 0, 100, GLOW_SKILL );

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
    //    W3ResetPlayerColor( client, thisRaceID );

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
	if(!Silenced(client)){
		new skill_summon=War3_GetSkillLevel(client,thisRaceID,SKILL_SUMMON);
		
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client, true)){
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SUMMON,true)){
				if(skill_summon>0){
					new Float:position111[3];
					War3_CachedPosition(client,position111);
					position111[2]+=5.0;
					new targets[MAXPLAYERS];
					new foundtargets;
					for(new ally=1;ally<=MaxClients;ally++){
						if(ValidPlayer(ally)){
							new ally_team=GetClientTeam(ally);
							new client_team=GetClientTeam(client);
							if(War3_GetRace(ally)!=thisRaceID && !IsPlayerAlive(ally) && ally_team==client_team){
								targets[foundtargets]=ally;
								foundtargets++;
							}
						}
					}
					new target;
					if(foundtargets>0){
						target=targets[GetRandomInt(0, foundtargets-1)];
						if(target>0){
							War3_CooldownMGR(client,g_fSummonCD[skill_summon],thisRaceID,SKILL_SUMMON);
							new Float:ang[3];
							new Float:pos[3];
							War3_SpawnPlayer(target);
							GetClientEyeAngles(client,ang);
							GetClientAbsOrigin(client,pos);
							TeleportEntity(target,pos,ang,NULL_VECTOR);
							CreateTimer(3.0,normal,target);
							CreateTimer(3.0,normal,client);
							EmitSoundToAll(summon_sound,client);
							CreateTimer(3.0, Stop, client);
						}
					}
					else
					{
						PrintHintText(client,"There are no allies you can rez");
					}
				}
				else
				{
					PrintHintText(client, "Level your Summon first");
				}
			}
		}
		
	}
	else
	{
		PrintHintText(client,"Silenced: Can not cast");
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
		War3_DealDamage( bestTarget, g_iStrikeDamage[ult_level], client, DMG_BULLET, "Soul Steal" );
		War3_HealToMaxHP( client, g_iStrikeDamage[ult_level] );
		
		W3PrintSkillDmgHintConsole( bestTarget, client, War3_GetWar3DamageDealt(), ULT_STRIKE );
		W3FlashScreen( bestTarget, RGBA_COLOR_RED );
		
		War3_CooldownMGR( client, g_fUltCooldown, thisRaceID, ULT_STRIKE, _, _ );
		
		new Float:pos[3];
		
		GetClientAbsOrigin( client, pos );
		
		pos[2] += 40;
		
		TE_SetupBeamRingPoint( pos, 20.0, 50.0, BeamSprite, HaloSprite, 0, 0, 3.0, 60.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
		TE_SendToAll();
	}
}


public Action:normal(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new Float:end_dist=50.0;
		new Float:end_pos[3];
		GetClientAbsOrigin(client,end_pos);
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&i!=client)
			{
				new Float:pos[3];
				GetClientAbsOrigin(i,pos);
				new Float:dist=GetVectorDistance(end_pos,pos);
				if(dist<=end_dist)
				{
					CreateTimer(1.0,normal,client);
					break;
				}
			}
		}
	}
}

public Action:Stop(Handle:timer,any:client)
{
	StopSound(client,SNDCHAN_AUTO,summon_sound);
}