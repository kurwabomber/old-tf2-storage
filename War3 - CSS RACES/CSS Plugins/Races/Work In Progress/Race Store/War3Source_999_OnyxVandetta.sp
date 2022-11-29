/**
* File: War3Source_OnyxVendetta.sp
* Description: The Onyx Vendetta race for War3Source.
* Author(s): (Don)Revan
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED,SKILL_OVEND,SKILL_BLOOD,SKILL_THON,SKILL_JUMP,ULT_REAL;
new BeamSprite,OneBlood,HaloSprite;
//skillstuff
new Float:onyxspeed[5]={1.05,1.10,1.15,1.18,1.22};
new Float:VampirePercent[5]={0.0,0.07,0.12,0.15,0.18};
new Float:CriticalStrikePercent[5]={0.0,0.10,0.15,0.20,0.26};
new DevotionHealth[5]={20,25,35,40,45};
new Float:LevitationGravity[5]={1.0,0.92,0.733,0.5466,0.36};
new Float:KnifeDamageMultiplier[5] = { 0.0, 0.80, 1.10, 1.25, 1.35 };
new String:Sound[] = {"ambient/atmosphere/garage_tone.wav"};

public Plugin:myinfo = 
{
	name = "War3Source Race - Onyx Vendetta",
	author = "DonRevan",
	description = "The old creature for War3Source.",
	version = "1.0.5.0",
	url = "www.wcs-lagerhaus.de"
};

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/effects/ar2_altfire1.vmt");
	OneBlood=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	War3_PrecacheSound(Sound);
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Onyx Vendetta", "onyx" );
	
	SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","Run 5-22% Faster",false,4);
	SKILL_OVEND=War3_AddRaceSkill(thisRaceID,"Onyx Vendetta","Steal 7-30% of enemyes health",false,4);
	SKILL_BLOOD=War3_AddRaceSkill(thisRaceID,"One Blood","Strike enemy to deal extra damage",false,4); 
	SKILL_THON=War3_AddRaceSkill(thisRaceID,"The Onyx","Gain 20-45 addintional Health",false,4); 
	SKILL_JUMP=War3_AddRaceSkill(thisRaceID,"Like Onyx","You jumps gain 10-60% more power!",false,4); 
	ULT_REAL=War3_AddRaceSkill(thisRaceID,"Real Vendetta","Deal more Knife damage",true,4); 

	War3_CreateRaceEnd( thisRaceID );
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

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID && !W3HasImmunity(victim,Immunity_Skills))
		{
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_OVEND);
			if(skill_level>0)
			{	
				new Float:percent_health=VampirePercent[skill_level];
				new leechhealth=RoundToFloor(damage*percent_health);
				if(leechhealth>40) leechhealth=40;
				if(leechhealth)
				{
					W3FlashScreen(victim,RGBA_COLOR_GREEN);
					W3FlashScreen(attacker,RGBA_COLOR_GREEN);
					War3_HealToBuffHP(attacker,leechhealth);
					new Float:iVec[ 3 ];
					GetClientAbsOrigin( victim, Float:iVec );
					TE_SetupDynamicLight(iVec,255,80,80,6,120.0,1.5,3.2);
					TE_SendToAll();
					iVec[2]+=40;
					TE_SetupBeamRingPoint(iVec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.5,15.0,0.0,{100,80,80,255},10,0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(iVec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.5,15.0,0.0,{100,80,80,255},10,0);
					TE_SendToAll(0.40);
					TE_SetupBeamRingPoint(iVec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.5,15.0,0.0,{100,80,80,255},10,0);
					TE_SendToAll(0.80);
				}
			}
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, ULT_REAL );
			if( !Hexed( attacker, false ) && skill_dmg > 0)
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( StrEqual( wpnstr, "wep_knife" ) )
				{
					War3_DealDamage( victim, RoundToFloor( damage * KnifeDamageMultiplier[skill_dmg] ), attacker, DMG_SLASH, "weapon_knife" );
					PrintHintText(attacker,"REAL VENDETTA!!!");
					
					new Float:start_pos[3];
					new Float:target_pos[3];
					GetClientAbsOrigin(attacker,start_pos);
					GetClientAbsOrigin(victim,target_pos);
					target_pos[2]+=40.0;
					start_pos[2]+=300.0;
					TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,HaloSprite,0,250,1.5,18.0,20.0,0,22.0,{255,200,200,255},90);
					TE_SendToAll();
					
					EmitSoundToAll(Sound,victim);
				}
				else
				PrintToConsole(attacker,"[debug] this is for debugging normal players should ignore this - %s",wpnstr);
			}
			new skill_cs_attacker=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOOD);
			if(skill_cs_attacker>0)
			{
				if( GetRandomFloat( 0.0, 1.0 ) <= 0.25 )
				{
					new Float:percent=CriticalStrikePercent[skill_cs_attacker];
					new health_take=RoundFloat(damage*percent);
					//PrintHintText(attacker,"OneBlood causes +%d Dmg",health_take);
					//PrintHintText(victim,"-%d Dmg",health_take);
					PrintCenterText(attacker,"OneBlood causes +%d Damage",health_take);
					War3_DealDamage( victim, RoundToFloor( damage * CriticalStrikePercent[skill_cs_attacker] ), attacker, DMG_BULLET, "oneblood" );
					W3FlashScreen(victim,RGBA_COLOR_RED);
					new Float:victim_pos2[3];
					GetClientAbsOrigin( victim, victim_pos2 );
					new Float:start_pos2[3];
					GetClientAbsOrigin( attacker, start_pos2 );
					victim_pos2[2]+=35;
					start_pos2[2]+=35;
					TE_SetupBeamRingPoint(victim_pos2,10.0,120.0,OneBlood,HaloSprite,0,6,3.0,15.0,0.0,{250,255,255,255},1,0);
					TE_SendToAll();
					TE_SetupBeamPoints(start_pos2,victim_pos2,OneBlood,HaloSprite,0,0,1.5,15.0,16.0,0,0.0,{250,250,250,255},20);
					TE_SendToAll();
					victim_pos2[2]+=10;
					TE_SetupBeamRingPoint(victim_pos2,10.0,100.0,OneBlood,HaloSprite,0,3,3.0,15.0,0.0,{255,0,0,255},1,0);
					TE_SendToAll();
					TE_SetupBeamPoints(start_pos2,victim_pos2,OneBlood,HaloSprite,0,0,1.5,15.0,16.0,0,0.0,{250,20,20,255},20);
					TE_SendToAll();
				}
			}
		}
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public OnRaceChangred(client,oldrace,newrace)
{
    if(newrace!=thisRaceID)
    {
        War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
        War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	//W3ResetAllBuffRace(client,thisRaceID);
    }
    else
    {
       InitPassiveSkills(client);
    }
}


public InitPassiveSkills(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel_speedy=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
		if(skilllevel_speedy)
		{
			new Float:speed=onyxspeed[skilllevel_speedy];
			War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
			PrintToChat(client,"\x04[War3Source]\x01 A speed buff affected you!");
			new Float:iVect[ 3 ];
			GetClientAbsOrigin( client, Float:iVect );
			iVect[2]+=20;
			TE_SetupBeamRingPoint(iVect,10.0,40.0,BeamSprite,HaloSprite,0,15,2.0,15.0,0.0,{100,80,80,255},10,0);
			TE_SendToAll();
		}
		new skilllevel_levi=War3_GetSkillLevel(client,thisRaceID,SKILL_JUMP);
		if(skilllevel_levi)
		{
			new Float:iVect[ 3 ];
			GetClientAbsOrigin( client, Float:iVect );
			new Float:gravity=LevitationGravity[skilllevel_levi];
			War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
			PrintToChat(client,"\x04[War3Source]\x01 A gravity buff affected you!");
			new Float:iVec[ 3 ];
			GetClientAbsOrigin( client, Float:iVec );
			iVec[2]+=40;
			TE_SetupBeamRingPoint(iVec,10.0,40.0,BeamSprite,HaloSprite,0,15,2.0,15.0,0.0,{100,80,80,255},10,0);
			TE_SendToAll();
		}
		new skill_devo=War3_GetSkillLevel(client,thisRaceID,SKILL_THON);
		if(skill_devo)
		{
			new hpadd=DevotionHealth[skill_devo];
			new Float:vec[3];
			GetClientAbsOrigin(client,vec);
			vec[2]+=30.0;
			new ringColor[4]={0,0,0,0};
			new team=GetClientTeam(client);
			if(team==2)
			{
				ringColor={255,0,0,255};
			}
			else if(team==3)
			{
				ringColor={0,0,255,255};
			}
			TE_SetupBeamRingPoint(vec,50.0,52.0,BeamSprite,HaloSprite,0,15,4.6,15.0,0.0,ringColor,10,0);
			TE_SendToAll();
			new maxhp = GetClientHealth(client)+hpadd;
			SetEntityHealth(client,maxhp);
			War3_SetMaxHP(client,maxhp);
			/*decl String: str[32];
			Format(str, 32, "\x03[The Onyx]\x01 You gained %i addintional Health", hpadd);
			new Handle:hBf;
			hBf = StartMessageOne("SayText2", client);
			if (hBf != INVALID_HANDLE)
			{
				BfWriteByte(hBf, client); 
				BfWriteByte(hBf, 0); 
				BfWriteString(hBf, str);
				EndMessage();
			}*/
			PrintToChat(client,"\x04[War3Source]\x01 You gained %i addintional Health",hpadd);
		}
	}
}
//just for notice
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed)
	{
		new skill=War3_GetSkillLevel(client,race,ULT_REAL);
		if(skill>0)
		PrintHintText(client,"This is a Passive Ultimate!");
		else
		W3MsgUltNotLeveled(client);
	}
}