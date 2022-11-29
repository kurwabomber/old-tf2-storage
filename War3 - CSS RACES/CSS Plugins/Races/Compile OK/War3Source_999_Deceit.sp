/**
* File: War3Source_999_Deceit.sp
* Description: Deceit Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/remyfunctions"

new thisRaceID;
new SKILL_FOOTSTEPS, SKILL_DISGUISE, SKILL_INVIS, ULT_CLOAK;



public Plugin:myinfo = 
{
	name = "War3Source Race - Deceit",
	author = "Remy Lebeau",
	description = "Deceit race for War3Source",
	version = "0.9.1",
	url = "http://sevensinsgaming.com"
};

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Deceit [SSG-DONATOR]","deceit");
	
	SKILL_FOOTSTEPS=War3_AddRaceSkill(thisRaceID,"Ghostly","Chance of silent footsteps (25%-100)%",false,4);
	SKILL_DISGUISE=War3_AddRaceSkill(thisRaceID,"But I'm on your team!","Chance of disguising as opposite team (25%-100%)",false,4);
	SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"No one's here","No really, no one's here!  (Go invis when you stand still)",false,4);
	ULT_CLOAK=War3_AddRaceSkill(thisRaceID,"Cloak and dagger","Disappear in a cloud of smoke! (passive)",true,4);
	
	War3_CreateRaceEnd(thisRaceID);
}


/***************************************************************************
*
*
*				Abillity Variables
*
*
***************************************************************************/



new Float:DisguiseChance[] = {0.0, 0.25, 0.50, 0.75, 1.01};
new Float:FootstepsChance[] = {0.0, 0.25, 0.50, 0.75, 1.01};
new bool:footsteps[MAXPLAYERS];

//Stand Still INVIS
new InvisTime[]={ 0, 50, 40, 30, 20 };
new m_vecVelocity = -1;
new Float:canspeedtime[MAXPLAYERS+1];
new AcceleratorDelayer[MAXPLAYERS];
new bool:InvisTrue[MAXPLAYERS];

//Ultimate

new Float:MirrorImageChance[]={0.0,0.35,0.45,0.55, 0.65};



public OnPluginStart()
{
	
	
	m_vecVelocity = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	
	CreateTimer(0.1, CalcSpeed,_,TIMER_REPEAT);
}



public OnMapStart()
{
	

}
	

/***************************************************************************
*
*
*				PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public InitPassiveSkills( client )
{
	new skill_disguise = War3_GetSkillLevel( client, thisRaceID, SKILL_DISGUISE );
	if (GetRandomFloat(0.0,1.0) < DisguiseChance[skill_disguise])
	{
		War3_ChangeModel( client, true);
		CPrintToChat(client, "{red}Deceit: {default}-- Disguised as enemy team.");

	}

	new skill_footsteps = War3_GetSkillLevel( client, thisRaceID, SKILL_FOOTSTEPS );
	if (GetRandomFloat(0.0,1.0) < FootstepsChance[skill_footsteps])
	{	
		footsteps[client] = true; 
		CPrintToChat(client, "{red}Deceit: {default}-- Footsteps are muted");
	}
	else
		footsteps[client] = false; 


	
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_tmp");
	CreateTimer( 1.5, forceGiveWep, client );
	
	InvisTrue[client] = false;
			

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
		footsteps[client] = false; 
	}
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID && ValidPlayer( client, true ))
	{
		W3ResetAllBuffRace( client, thisRaceID );
		InitPassiveSkills(client);
	}
}




/***************************************************************************
*
*
*				ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/



/***************************************************************************
*
*
*				EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)	
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_victim=War3_GetRace(victim);
			// mirror image
			new skill_mimage=War3_GetSkillLevel(victim,race_victim,ULT_CLOAK);
			if(race_victim==thisRaceID)
			{
				if(GetRandomFloat(0.0,1.0)<=MirrorImageChance[skill_mimage] && !Silenced(victim))
				{				
					
					new Float:this_pos[3];
					GetClientAbsOrigin(victim,this_pos);
					new Float:fadestart = 2.0; 
					new Float:fadeend = 3.0; 
					new SmokeIndex = CreateEntityByName("env_particlesmokegrenade"); 
					if (SmokeIndex != -1) 
					{ 
						SetEntProp(SmokeIndex, Prop_Send, "m_CurrentStage", 1); 
						SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeStartTime", fadestart); 
						SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeEndTime", fadeend); 
						DispatchSpawn(SmokeIndex); 
						ActivateEntity(SmokeIndex); 
						TeleportEntity(SmokeIndex, this_pos, NULL_VECTOR, NULL_VECTOR); 
					}  
							
					War3_SetBuff(victim,fMaxSpeed,thisRaceID,1.6);
					PrintHintText(victim,"Disappear in a cloud of smoke!");
					
					War3_SetBuff( victim, bDisarm, thisRaceID, true  );
					War3_SetBuff( victim, fInvisibilitySkill, thisRaceID, 0.0  );
					War3_SetBuff( victim,bDoNotInvisWeapon,thisRaceID,false);
					CreateTimer(2.0,RemoveSpeed,victim);
				}
				
			}
		}
	}
}









/***************************************************************************
*
*
*				HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/




public Action:forceGiveWep( Handle:timer, any:client )
{
	new race = War3_GetRace( client );
	if( ValidPlayer( client, true ) && race == thisRaceID )
	{

		GivePlayerItem( client, "weapon_tmp" );
	}
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer (client, true))
    {
        if(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP) && footsteps[client] == true)
        {
            SetEntProp(client, Prop_Send, "m_fFlags", 4);
        }
    }
    return Plugin_Continue;
}


public Action:CalcSpeed(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID)
		{
			new skill_speed = War3_GetSkillLevel(i,thisRaceID,SKILL_INVIS);
			if(canspeedtime[i] < GetGameTime() && skill_speed > 0 )
			{
				// PrintToChat(i, "Standing still, invis in |%d|",AcceleratorDelayer[i]);
				AcceleratorDelayer[i]++;
				if(AcceleratorDelayer[i] == InvisTime[skill_speed])
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
			if(skill_speed > 0 && GetVectorLength(velocity) > 0)
			{
				canspeedtime[i] = GetGameTime() + 1.0;
			}
		}
	}	
}


public Action:RemoveSpeed(Handle:t,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff( client, bDisarm, thisRaceID, false  );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0  );
		War3_SetBuff( client,bDoNotInvisWeapon,thisRaceID,true);

	}
}