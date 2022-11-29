/**
* File: War3Source_999_Assassin.sp
* Description: Legendary's custom race for War3source
* Author(s): Remy Lebeau
* Requested by Legendary.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/remyfunctions"

public Plugin:myinfo = 
{
	name = "War3Source Race - Assassin",
	author = "Remy Lebeau",
	description = "Legendary's custom race for War3source",
	version = "0.9.2",
	url = "sevensinsgaming.com"
};



// War3Source stuff + Sprite/Sound Variable
new thisRaceID;
new TeleBeam, HaloSprite;
new SKILL_HIDDEN, SKILL_SPEED, SKILL_GRAV, SKILL_MOLE, SKILL_PAYBACK;

// SKILL_HIDDEN VARIABLES
new Float:invis[] = { 1.0, 0.9, 0.8, 0.7, 0.6};

// SKILL_SPEED VARIABLES
new Float:speedboost[] = { 1.0, 1.05, 1.1, 1.15, 1.2, 1.25 };

// SKILL_GRAV VARIABLES
new Float:grav[]={1.0,0.85,0.7,0.6,0.5};

// SKILL_MOLE VARIABLES
new Float:MoleChance[5] = { 0.0, 0.05, 0.1, 0.15, 0.20 };
new OriginOffset;
new String:sOldModel[MAXPLAYERS][256];



// SKILL_PAYBACK VARIABLES
new Float:ReturnDamage[]={0.0, 0.025, 0.05, 0.075, 0.1, 0.125, 0.15,0.175, 0.20};


public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Legendary Assassin [PRIVATE]", "lassassin" );
	
	SKILL_HIDDEN = War3_AddRaceSkill( thisRaceID, "Hidden", "Assassin must never be seen.", false, 4 );	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Speed", "Move as fast as a gentle breeze", false, 5 );	
	SKILL_GRAV = War3_AddRaceSkill( thisRaceID, "Jump", "It's almost like gravity is being lowered!", false, 4 );	
	SKILL_MOLE = War3_AddRaceSkill( thisRaceID, "From Behind", "An assassin's favorite place to be", false, 4 );
	SKILL_PAYBACK = War3_AddRaceSkill( thisRaceID, "Payback", "You think you can get away with attacking an assassin?", false, 8 );
	
	War3_CreateRaceEnd( thisRaceID );

}

public OnPluginStart()
{
	HookEvent("round_start",RoundStartEvent);
	OriginOffset=FindSendPropOffs("CBaseEntity","m_vecOrigin");
}

public OnMapStart()
{
	TeleBeam=PrecacheModel("materials/sprites/tp_beam001.vmt");
	HaloSprite=War3_PrecacheHaloSprite();
	
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
	new speed_level = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
	new invis_level = War3_GetSkillLevel( client, thisRaceID, SKILL_HIDDEN );
	new gravity_level = War3_GetSkillLevel( client, thisRaceID, SKILL_GRAV );
	
	War3_SetBuff( client, fInvisibilitySkill, thisRaceID, invis[invis_level]  );
	War3_SetBuff( client, fMaxSpeed, thisRaceID, speedboost[speed_level] );
	War3_SetBuff( client, fLowGravitySkill, thisRaceID, grav[gravity_level]  );

	War3_WeaponRestrictTo(client,thisRaceID,"weapon_m4a1,weapon_deagle,weapon_knife");
	CreateTimer( 1.0, GiveWep, client );
	
}


public OnRaceChanged( client,oldrace,newrace )
{
	if( newrace == thisRaceID )
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
		InitPassiveSkills( client );
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


public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&War3_GetRace(i)==thisRaceID)
		{
			new skill_level=War3_GetSkillLevel(i,thisRaceID,SKILL_MOLE);
			if( GetRandomFloat( 0.0, 1.0 ) <= MoleChance[skill_level] )
			{
				StartMole(i);
			}
			
		}
	}
}



public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if(W3GetDamageIsBullet()&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		
		if(War3_GetRace(victim)==thisRaceID)
		{
			new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_PAYBACK);
			if(skill_level>0&&!Hexed(victim,false))
			{
				if(!W3HasImmunity(attacker,Immunity_Skills))
				{
					new damage_i=RoundToFloor(damage*ReturnDamage[skill_level]);
					if(damage_i>0)
					{
						if(damage_i>40) damage_i=40; // lets not be too unfair ;]
						{
							War3_DealDamageDelayed(attacker,victim,damage_i,"payback",0.1,true,SKILL_PAYBACK);
							decl Float:iVec[3];
							decl Float:iVec2[3];
							GetClientAbsOrigin(attacker, iVec);
							GetClientAbsOrigin(victim, iVec2);
							iVec[2]+=35.0, iVec2[2]+=40.0;
							TE_SetupBeamPoints(iVec, iVec2, TeleBeam, TeleBeam, 0, 45, 0.4, 10.0, 10.0, 0, 0.5, {255,35,15,255}, 30);
							TE_SendToAll();
							iVec2[0]=iVec[0];
							iVec2[1]=iVec[1];
							iVec2[2]=80+iVec[2];
							TE_SetupBubbles(iVec, iVec2, HaloSprite, 35.0,GetRandomInt(6,8),8.0);
							TE_SendToAll();
						}
					}
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



public Action:GiveWep( Handle:timer, any:client )
{
	new race = War3_GetRace( client );
	if( ValidPlayer( client, true ) && race == thisRaceID )
	{
		GivePlayerItem( client, "weapon_deagle" );
		GivePlayerItem( client, "weapon_m4a1" );
	}
}



stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
	TE_Start("Dynamic Light");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("r",r);
	TE_WriteNum("g",g);
	TE_WriteNum("b",b);
	TE_WriteNum("exponent",iExponent);
	TE_WriteFloat("m_fRadius",fRadius);
	TE_WriteFloat("m_fTime",fTime);
	TE_WriteFloat("m_fDecay",fDecay);
}



public StartMole(client)
{
	new Float:mole_time=5.0;
	W3MsgMoleIn(client,mole_time);
	CreateTimer(0.2+mole_time,DoMole,client);
}

public Action:DoMole(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new team=GetClientTeam(client);
		new searchteam=(team==2)?3:2;
		
		new Float:emptyspawnlist[100][3];
		new availablelocs=0;
		
		new Float:playerloc[3];
		new Float:spawnloc[3];
		new ent=-1;
		while((ent = FindEntityByClassname(ent,(searchteam==2)?"info_player_terrorist":"info_player_counterterrorist"))!=-1)
		{
			if(!IsValidEdict(ent)) continue;
			GetEntDataVector(ent,OriginOffset,spawnloc);
			
			new bool:is_conflict=false;
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)){
					GetClientAbsOrigin(i,playerloc);
					if(GetVectorDistance(spawnloc,playerloc)<60.0)
					{
						is_conflict=true;
						break;
					}				
				}
			}
			if(!is_conflict)
			{
				emptyspawnlist[availablelocs][0]=spawnloc[0];
				emptyspawnlist[availablelocs][1]=spawnloc[1];
				emptyspawnlist[availablelocs][2]=spawnloc[2];
				availablelocs++;
			}
		}
		if(availablelocs==0)
		{
			War3_ChatMessage(client,"%T","No suitable location found, can not mole!",client);
			return;
		}
		GetClientModel(client,sOldModel[client],256);
		if(War3_GetGame() == Game_CS) {
			SetEntityModel(client,(searchteam==2)?"models/player/t_leet.mdl":"models/player/ct_urban.mdl");
		}
		else {
			// TODO: probably needs a improvement(models) ?
			SetEntityModel(client,(searchteam==2)?"models/player/tm_leet_variantb.mdl":"models/player/ctm_gsg9.mdl");
		}
		TeleportEntity(client,emptyspawnlist[GetRandomInt(0,availablelocs-1)],NULL_VECTOR,NULL_VECTOR);
		W3MsgMoled(client);
		War3_ShakeScreen(client,1.0,20.0,12.0);
		CreateTimer(10.0,ResetModel,client);
	}
	return;
}
public Action:ResetModel(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		SetEntityModel(client,sOldModel[client]);
		W3MsgNoLongerDisguised(client);
	}
}

