/**
* File: War3Source_999_ModelTestRace.sp
* Description: Model Test Race for War3Source
* Author(s): Remy Lebeau
* Can set self or other's custom models
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_GOD;


public Plugin:myinfo = 
{
    name = "War3Source Race - Model Tester",
    author = "Remy Lebeau",
    description = "Model Test race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Model Tester [DEV-ONLY]","modeltester");
    
    SKILL_GOD=War3_AddRaceSkill(thisRaceID,"GOD MODE","Turns the player into God.  Unless you have a cross & nails, good luck killing him.",false,4);

    
    War3_CreateRaceEnd(thisRaceID);

    
}



public OnPluginStart()
{
 
}



public OnMapStart()
{
 
    
    PrecacheModel("models/player/techknow/spiderman/spiderman3.mdl", true);
    AddFileToDownloadsTable("materials/models/player/techknow/spiderman/body.vmt");
    AddFileToDownloadsTable("materials/models/player/techknow/spiderman/body.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/spiderman/body_n.vtf");
    AddFileToDownloadsTable("models/player/techknow/spiderman/spiderman3.dx80.vtx");
    AddFileToDownloadsTable("models/player/techknow/spiderman/spiderman3.dx90.vtx");
    AddFileToDownloadsTable("models/player/techknow/spiderman/spiderman3.mdl");
    AddFileToDownloadsTable("models/player/techknow/spiderman/spiderman3.phy");
    AddFileToDownloadsTable("models/player/techknow/spiderman/spiderman3.sw.vtx");
    AddFileToDownloadsTable("models/player/techknow/spiderman/spiderman3.vvd");

    
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
    new skill_god=War3_GetSkillLevel(client,thisRaceID,SKILL_GOD);
    if(skill_god)
    {
    	War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
    	War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
    	War3_SetBuff(client,bImmunityWards,thisRaceID,true);
    	War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,5000);
    	War3_SetBuff(client,fMaxSpeed,thisRaceID,2.4);
    	
    }
    SetEntityModel(client, "models/player/techknow/spiderman/spiderman3.mdl");

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
    SetEntityModel(client, "models/player/techknow/spiderman/spiderman3.mdl");
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








/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnW3TakeDmgAllPre( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		new vteam = GetClientTeam( victim );
		new ateam = GetClientTeam( attacker );
		if( vteam != ateam )
		{
			new race_victim = War3_GetRace( victim );
			new ult_level = War3_GetSkillLevel( victim, thisRaceID, SKILL_GOD );
			if( race_victim == thisRaceID && ult_level > 0 )
			{
				
                War3_DamageModPercent( 0.0 );
				
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