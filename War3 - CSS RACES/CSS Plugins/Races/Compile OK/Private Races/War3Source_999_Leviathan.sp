/**
* File: War3Source_999_Leviathan.sp
* Description: Leviathan's custom race for War3source
* Author(s): Remy Lebeau
* Requested by Leviathan.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/remyfunctions"

public Plugin:myinfo = 
{
	name = "War3Source Race - Leviathan",
	author = "Remy Lebeau",
	description = "Leviathan's custom race for War3source",
	version = "1.1",
	url = "sevensinsgaming.com"
};



// War3Source stuff + Sprite/Sound Variable
new thisRaceID;
new String:chompstr[256];
new String:ultimateSound[256];
new BloodSpray,BloodDrop;
new HaloSprite, HealSprite;
new SKILL_STRENGTH, SKILL_SPEED, SKILL_CHOMP, SKILL_SHAPE, SKILL_HEAL, ULT_MORPH;

// SKILL_STRENGTH VARIABLEs
new Float:damageboost[] = { 0.0, 0.05, 0.1, 0.15, 0.20};

// SKILL_SPEED VARIABLEs
new Float:speedboost[] = { 1.0, 1.1, 1.15, 1.2, 1.3, 1.4 };

// SKILL_CHOMP VARIABLES
new const ChompInitialDamage=20;
new const ChompTrailingDamage=2;
new Float:ChompChanceArr[]={0.0,0.05,0.1,0.15,0.20,0.25};
new ChompTimes[]={0,1,2,3,4,5};
new BeingChompedBy[MAXPLAYERS];
new ChompsRemaining[MAXPLAYERS];

// SKILL_SHAPE VARIABLES
new bool:shifted[MAXPLAYERS];


// SKILL_HEAL VARIABLES
new Float:HealingDistance=500.0;
new HP[6] = { 0, 10, 12, 15, 28, 20 };



// ULTIMATE Variables
new hpboost[]= {0, 10, 30, 40, 50 };
new Float:hptime[] = {0.0, 2.0, 3.0, 4.0, 5.0 };



public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Leviathan [PRIVATE]", "leviathan" );
	
	SKILL_STRENGTH = War3_AddRaceSkill( thisRaceID, "Super Strength", "Bonus Attack Damage", false, 4 );	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Endurance", "Increase Speed 10%-50%", false, 5 );	
	SKILL_CHOMP = War3_AddRaceSkill( thisRaceID, "Chomp", "Deal damage over time to your enemy. (5/10/15/25% chance of 2hp /sec damage)", false, 5 );	
	SKILL_SHAPE = War3_AddRaceSkill( thisRaceID, "Shapeshifting", "Steal your opponent's identity.", false, 1 );
	SKILL_HEAL = War3_AddRaceSkill( thisRaceID, "Recover", "Heal yourself and your nearby teammates (+ability)", false, 5 );
	ULT_MORPH = War3_AddRaceSkill( thisRaceID, "Metamorphosis ", "Turn into THE LEVIATHAN (HP Increase)", true, 4 );

	W3SkillCooldownOnSpawn( thisRaceID, ULT_MORPH, 20.0, _ );
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_HEAL, 15.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );

}

public OnPluginStart()
{

}

public OnMapStart()
{
	BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
	BloodDrop = PrecacheModel("sprites/blood.vmt");
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	HealSprite = PrecacheModel( "materials/sprites/hydraspinalcord.vmt" );
	



	strcopy(ultimateSound,sizeof(ultimateSound),"ambient/water_splash2.wav");
	strcopy(chompstr,sizeof(chompstr),"war3source/shadowstrikebirth.mp3");
	War3_AddCustomSound(chompstr);
	War3_PrecacheSound(ultimateSound);
	
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
	shifted[client] = false;
	ChompsRemaining[client] = 0;
	new speed_level = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
	new wep_level = War3_GetSkillLevel( client, thisRaceID, SKILL_STRENGTH );
	War3_SetBuff( client, fMaxSpeed, thisRaceID, speedboost[speed_level] );
	War3_SetBuff( client, fDamageModifier, thisRaceID, damageboost[wep_level] );
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout,weapon_deagle,weapon_knife");
	CreateTimer( 1.0, GiveWep, client );
	
}


public OnRaceChanged( client,oldrace,newrace )
{
	if( newrace == thisRaceID && ValidPlayer( client, true ) )
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
*				ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client) )
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_HEAL);
		if(skill_level>0)
		{
			if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_HEAL,true))
			{
				
				new team = GetClientTeam(client);			
				new Float:otherVec[3];
				
				new Float:HealOrigin[MAXPLAYERSCUSTOM][3];
				GetClientAbsOrigin(client,HealOrigin[client]);
				HealOrigin[client][2]+=30.0;
				
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)&&GetClientTeam(i)==team)
					{
						GetClientAbsOrigin(i,otherVec);
						otherVec[2]+=30.0;
						new Float:victimdistance=GetVectorDistance(HealOrigin[client],otherVec);
						if(victimdistance<HealingDistance)
						{
							
							TE_SetupBeamPoints( HealOrigin[client], otherVec, HealSprite, HaloSprite, 0, 0, 0.5, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
							TE_SendToAll();							
							War3_HealToMaxHP(i, HP[skill_level]);
							
						}
					}
				}
				War3_CooldownMGR( client, 25.0, thisRaceID, SKILL_HEAL);
			}
		}
		else
		{
			PrintHintText(client, "Level up your ability first.");
		}
	
	}
}


public OnUltimateCommand( client, race, bool:pressed )
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_morph = War3_GetSkillLevel( client, thisRaceID, ULT_MORPH );
		if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_MORPH,true))
		{
			if(ult_morph > 0)
			{
				W3EmitSoundToAll(ultimateSound,client);
				PrintHintText(client, "You transform into the LEVIATHAN!");
				War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, hpboost[ult_morph]  );
				War3_HealToMaxHP(client, 200);
				CreateTimer(hptime[ult_morph], UltiStop, client);
				War3_CooldownMGR( client, 30.0 + hptime[ult_morph], thisRaceID, ULT_MORPH);
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
*				EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	new race = War3_GetRace( attacker );
	if( race == thisRaceID )
	{
		new skill_shape = War3_GetSkillLevel( attacker, thisRaceID, SKILL_SHAPE );
		new skill_chomp = War3_GetSkillLevel( attacker, thisRaceID, SKILL_CHOMP );
		if(ValidPlayer(victim, true) && ValidPlayer(attacker, true) && victim > 0 && attacker > 0 && victim != attacker)
		{
			new vteam=GetClientTeam(victim);
			new ateam=GetClientTeam(attacker);
			if(vteam!=ateam)
			{
				if(!shifted[attacker] && (skill_shape > 0))
				{
					shifted[attacker] = true;
					War3_ChangeModel( attacker, true);
					PrintHintText (attacker, "SHAPESHIFT!");
				}
				new Float:chance_mod=W3ChanceModifier(attacker);
				if (skill_chomp > 0 && ChompsRemaining[victim]==0 && !Hexed(attacker,false) && GetRandomFloat(0.0,1.0)<=chance_mod*ChompChanceArr[skill_chomp])
				{
					if(W3HasImmunity(victim,Immunity_Skills))
					{
						W3MsgSkillBlocked(victim,attacker,"Chomp");
					}
					else
					{
						W3MsgAttackedBy(victim,"Chomp");
						W3MsgActivated(attacker,"Chomp");
						
						BeingChompedBy[victim]=attacker;
						ChompsRemaining[victim]=ChompTimes[skill_chomp];
						War3_DealDamage(victim,ChompInitialDamage,attacker,DMG_BULLET,"chomp");
						W3FlashScreen(victim,RGBA_COLOR_RED);
						
						W3EmitSoundToAll(chompstr,attacker);
						W3EmitSoundToAll(chompstr,attacker);
						CreateTimer(1.0,chompLoop,GetClientUserId(victim));
					}
				}		
			}
		}
	}
}



public OnWar3EventDeath(victim,attacker)
{
	if( War3_GetRace( attacker ) == thisRaceID )
	{		
		decl Float:vecAngles[3];
		GetClientEyeAngles(victim,vecAngles);
		decl Float:target_pos[3];
		GetClientAbsOrigin(victim,target_pos);
		//target_pos[2]+=45;
		TE_SetupBloodSprite(target_pos, vecAngles, {255, 255, 255, 255}, 35, BloodSpray, BloodDrop);
		TE_SendToAll();
	}
}




/***************************************************************************
*
*
*				HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/

public Action:UltiStop(Handle:timer,any:client)
{
	War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, 0 );
	PrintHintText(client, "Leviathan has washed away.");
}


public Action:GiveWep( Handle:timer, any:client )
{
	new race = War3_GetRace( client );
	if( ValidPlayer( client, true ) && race == thisRaceID )
	{
		GivePlayerItem( client, "weapon_deagle" );
		GivePlayerItem( client, "weapon_scout" );
	}
}

public Action:chompLoop(Handle:timer,any:userid)
{
	new victim = GetClientOfUserId(userid);
	if(ChompsRemaining[victim]>0 && ValidPlayer(BeingChompedBy[victim]) && ValidPlayer(victim,true))
	{
		War3_DealDamage(victim,ChompTrailingDamage,BeingChompedBy[victim],DMG_BULLET,"chomp");
		ChompsRemaining[victim]--;
		W3FlashScreen(victim,RGBA_COLOR_RED);
		CreateTimer(2.0,chompLoop,userid);
		decl Float:StartPos[3];
		GetClientAbsOrigin(victim,StartPos);
		TE_SetupDynamicLight(StartPos,255,255,100,100,100.0,0.3,3.0);
		TE_SendToAll();
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

