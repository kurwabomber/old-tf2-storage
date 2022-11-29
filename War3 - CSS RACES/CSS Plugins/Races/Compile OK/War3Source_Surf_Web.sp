/**
* File: War3Source_surf_Web.sp
* Description: Race for war3surf
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL1, SKILL2, SKILL3, ULT;

#define WEAPON_RESTRICT "weapon_knife,weapon_deagle"
#define WEAPON_GIVE "weapon_deagle"

public Plugin:myinfo = 
{
    name = "War3Source Race - Spiderman (Surf)",
    author = "Remy Lebeau",
    description = "Web race for War3Surf",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};



// Ult
new m_vecBaseVelocity;
new  FreezeSprite1;
new String:ult_sound[] = "weapons/357/357_spin1.wav";
new Float:PushForce[] = { 0.0, 1.0, 1.1, 1.2, 1.25, 1.28 };
new String:g_sPlayerModel[] = "models/player/slow/jamis/venom_wos/slow_v2.mdl";

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Spiderman [SURF - DONATOR]","surf_web");
    
    SKILL1=War3_AddRaceSkill(thisRaceID,"Web","Shoot a web (+ultimate)",false,5);
    SKILL2=War3_AddRaceSkill(thisRaceID,"Pointless","Just here to make up levels...",false,5);
    SKILL3=War3_AddRaceSkill(thisRaceID,"Pointless2","Just here to make up levels...",false,5);
    ULT=War3_AddRaceSkill(thisRaceID,"Pointless3","Just here to make up levels...",false,5);
    
    War3_CreateRaceEnd(thisRaceID);
    

    
}


public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );

}


public OnMapStart()
{
    FreezeSprite1 = PrecacheModel( "materials/effects/combineshield/comshieldwall.vmt" );
    
    
    PrecacheModel(g_sPlayerModel, true);
    
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_1.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_1.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_1_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_2.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_2.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_2_bump.vtf");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.dx80.vtx");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.dx90.vtx");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.mdl");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.phy");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.sw.vtx");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.vvd");
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

 
    SetEntityModel(client, g_sPlayerModel);
    
    if (GetClientTeam(client) == TEAM_T)
    {
        W3SetPlayerColor(client,thisRaceID,255,51,0,20,GLOW_SKILL);  
    }
    else
    {
        W3SetPlayerColor(client,thisRaceID,0,204,255,20,GLOW_SKILL);
    }
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

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, SKILL1 );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, SKILL1, true ) )
			{
				TeleportPlayer( client );
				EmitSoundToAll( ult_sound, client );
				War3_CooldownMGR( client, 2.0, thisRaceID, SKILL1 );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}


stock TeleportPlayer( client )
{
	if( client > 0 && IsPlayerAlive( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, thisRaceID, SKILL1 );
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
