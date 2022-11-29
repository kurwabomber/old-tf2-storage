/**
* File: War3source_Panda_PrivateRace
* Description: My first race.
* Author(s): Panda Dodger.
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdktools_sound>

new thisRaceID;
new SKILL_LOL, SKILL_FLASH;

new Float:DamageMultiplier[2] = { 0.0, 0.01 };
new Float:FlashSpeed[2] = { 1.0, 1.01 };

new HaloSprite, BeamSprite;

public Plugin:myinfo =
{
   name = "panda",
   author = "Panda Dodger",
   description = "A retard that is on fire.",
   version = "0.1",
   url = "www.sevensinsgaming.com",
};

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace == thisRaceID )
	{
		new String:SteamID[64];
		GetClientAuthString( client, SteamID, 64 );
		if( !StrEqual( "STEAM_0:1:36035345", SteamID ) )
		{
			CreateTimer( 0.5, ForceChangeRace, client );
		}
	}
}
public Action:ForceChangeRace( Handle:timer, any:client )
{
	War3_SetRace( client, War3_GetRaceIDByShortname( "panda" ) );
	PrintHintText( client, "Race is restricted to Panda & Co." );
}

public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
}

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Panda_alpha_test","panda");
	SKILL_LOL=War3_AddRaceSkill(thisRaceID,"LOL", "Makes you do 1% more damage.", false);
	SKILL_FLASH=War3_AddRaceSkill(thisRaceID,"FLASH", "Makes you run faster.", false);
	War3_CreateRaceEnd(thisRaceID);
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_LOL = War3_GetSkillLevel( attacker, thisRaceID, SKILL_LOL );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.15 )
			{
				if( !W3HasImmunity( victim, Immunity_Skills ) )
				{
					War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_LOL] ), attacker, DMG_BULLET, "weapon_colt" );
				
					W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), "Owned you noob" );
					
					new Float:attacker_pos[3];
					new Float:victim_pos[3];
				
					GetClientAbsOrigin( attacker, attacker_pos );
					GetClientAbsOrigin( victim, victim_pos );
				
					attacker_pos[2] += 40;
					victim_pos[2] += 40;
				
					TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 0, 0, 255, 255 }, 0 );
					TE_SendToAll();
				}
			}
		}
	}
}

new firefx = CreateParticleSystem(victim, "burning_character", true, "rfoot", _);

stock CreateParticleSystem(iClient, String:strParticle[], bool:bAttach = false, String:strAttachmentPoint[]="", Float:fOffset[3]={0.0, 0.0, 0.0})
{
    new iParticle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(iParticle))
    {
        decl Float:fPosition[3];
        decl Float:fAngles[3];
        decl Float:fForward[3];
        decl Float:fRight[3];
        decl Float:fUp[3];
        
        // Retrieve entity's position and angles
        GetClientAbsOrigin(iClient, fPosition);
        GetClientAbsAngles(iClient, fAngles);
        
        // Determine vectors and apply offset
        GetAngleVectors(fAngles, fForward, fRight, fUp);    // I assume 'x' is Right, 'y' is Forward and 'z' is Up
        fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
        fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
        fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];
        
        // Teleport and attach to client
        TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
        DispatchKeyValue(iParticle, "effect_name", strParticle);

        if (bAttach == true)
        {
            SetVariantString("!activator");
            AcceptEntityInput(iParticle, "SetParent", iClient, iParticle, 0);            
            
            if (StrEqual(strAttachmentPoint, "") == false)
            {
                SetVariantString(strAttachmentPoint);
                AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);                
            }
        }

        // Spawn and start
        DispatchSpawn(iParticle);
        ActivateEntity(iParticle);
        AcceptEntityInput(iParticle, "Start");
    }

    return iParticle;
}