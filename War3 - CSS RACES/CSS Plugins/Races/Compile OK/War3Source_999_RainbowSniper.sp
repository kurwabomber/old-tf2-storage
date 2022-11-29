/*
* File: War3Source_RainbowSniper.sp
* Description: New race for Seven Sins Gaming use ONLY.
* Author(s): Corrupted/Scruffy The Janitor
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

new SKILL_ARMOURY, SKILL_DISGUISE, SKILL_CAMOUFLAGE, ULT_AMMUNITION;

//new Float:VampPercent[5] = {0.0,0.05,0.1,0.15,0.2};
new Float:AmmoChance[5] = {0.0,0.25,0.5,0.75,1.0};
new Float:FreezeTime[5] = {0.0,0.5,1.0,1.5,2.0};
new Float:DisguiseChance[5] = {0.0,0.1,0.2,0.3,0.4};
new Float:SniperInvis[5] = {1.0,0.9,0.8,0.7,0.6};
new Float:g_DrugAngles[20] = { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };
new Float:DotDuration[5]={0.0,4.0,6.0,8.0,10.0};
new Float:DotUntil[MAXPLAYERS];
new bool:bSniperDot[MAXPLAYERS];
new DotBy[MAXPLAYERS];
new UserMsg:g_FadeUserMsgId;
new GoldGain[5] = {0,1,2,3,4};
new XPGain[5] = {0,10,20,30,40};
new BeamSprite;

public Plugin:myinfo =
{
	name = "War3Source Race - Rainbow Sniper",
	author = "Corrupted/Scruffy The Janitor",
	description = "Sniper race for Seven Sins Gaming use ONLY.",
	version = "1.0.0.1",
	url = "sevensinsgaming.com",
};

public OnWar3PluginReady()
{
		thisRaceID=War3_CreateNewRace("Rainbow Sniper [SSG-DONATOR]","RS");
		SKILL_ARMOURY=War3_AddRaceSkill(thisRaceID,"Armoury","Gives you a sniper spawning menu",false);
		SKILL_DISGUISE=War3_AddRaceSkill(thisRaceID,"Disguise","You have a chance to appear as the enemy team",false);
		SKILL_CAMOUFLAGE=War3_AddRaceSkill(thisRaceID,"Camouflage","When you take damage, you have a chance to become invisible",false);
		ULT_AMMUNITION=War3_AddRaceSkill(thisRaceID,"Rainbow Ammunition","Has a chance of using a random coloured ammunition",false); 
		War3_CreateRaceEnd(thisRaceID);
}

public OnMapStart()
{
	BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
}

public OnPluginStart()
{
	CreateTimer(0.5,SniperDoTLoop,_,TIMER_REPEAT);
}

public OnRaceChanged ( client,oldrce,newrace )
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		InitPassiveSkills( client );
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife, weapon_deagle");
	}
}

public OnWar3EventSpawn( client )
{
	bSniperDot[client]=false;
	new race = War3_GetRace(client);
	if(race==thisRaceID)
	{
		new skill_armoury = War3_GetSkillLevel( client, thisRaceID, SKILL_ARMOURY );
		if( skill_armoury > 0)
		{
			DoArmouryMenu(client);
		}
		else
		{
			GivePlayerItem( client, "weapon_deagle" );
			War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife, weapon_deagle");
		}
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_DISGUISE ) > 0 && GetRandomFloat( 0.0, 1.0 ) <= DisguiseChance[War3_GetSkillLevel( client, thisRaceID, SKILL_DISGUISE )] )
		{
			if( GetClientTeam( client ) == TEAM_T )
			{
				SetEntityModel( client, "models/player/ct_urban.mdl" );
			}
			if( GetClientTeam( client ) == TEAM_CT )
			{
				SetEntityModel( client, "models/player/t_leet.mdl" );
			}
			PrintHintText( client, "You appear as the enemy team,\n use this to your advantage" );
		}
	}
}

public DoArmouryMenu(client)
{
	new Handle:ArmouryMenu=CreateMenu(War3Source_ArmouryMenu_Selected);
	SetMenuPagination(ArmouryMenu,MENU_NO_PAGINATION);
	SetMenuTitle(ArmouryMenu,"==SELECT YOUR WEAPON==");
	SetMenuExitButton(ArmouryMenu,true);
	
	new skill_armoury = War3_GetSkillLevel(client,thisRaceID,SKILL_ARMOURY);
	
	AddMenuItem(ArmouryMenu,"weapon_scout","Scout",(skill_armoury>0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(ArmouryMenu,"weapon_g3sg1","Auto Sniper gsg31",(skill_armoury>1)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(ArmouryMenu,"weapon_sg550","Auto Sniper sg550",(skill_armoury>2)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(ArmouryMenu,"weapon_awp","Awp",(skill_armoury>3)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	DisplayMenu(ArmouryMenu,client,MENU_TIME_FOREVER);
}

public War3Source_ArmouryMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
		{
			decl String:newRestrict[64];
			decl String:weaponName[32];
			decl String:SelectionDispText[256];
			new SelectionStyle;
			
			GetMenuItem(menu,selection,weaponName,sizeof(weaponName),SelectionStyle,SelectionDispText,sizeof(SelectionDispText));
			Format(newRestrict,64,"weapon_knife,%s",weaponName);
			
			War3_WeaponRestrictTo(client,thisRaceID,newRestrict,2);
			GivePlayerItem(client,weaponName);
		}
	}
	if(action==MenuAction_Cancel)
	{
		if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
		{
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_deagle");
			GivePlayerItem(client,"weapon_deagle");
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public OnWar3EventDeath( victim, attacker )
{
	War3_SetBuff( victim, bNoMoveMode, thisRaceID, false );	
}

public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
	if( ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID && !W3HasImmunity(victim,Immunity_Skills))
		{
			new ult_ammunition = War3_GetSkillLevel( attacker, thisRaceID, ULT_AMMUNITION );
			if( GetRandomFloat( 0.0, 1.0 ) <= AmmoChance[ult_ammunition] )
			{
				new DICE = (GetRandomInt(1,7));
				if(DICE == 1)
				{
					PrintHintText ( attacker, "Red laser broken, sorry!" );
				}
				if(DICE == 2)
				{
					IgniteEntity( victim, 4.0 );
					PrintHintText(attacker,"Enemy Ignited");
				
					new Float:attacker_pos[3];
					new Float:victim_pos[3];
				
					GetClientAbsOrigin( attacker, attacker_pos );
					GetClientAbsOrigin( victim, victim_pos );
				
					attacker_pos[2] += 40;
					victim_pos[2] += 40;
				
					TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, BeamSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 230, 165, 30, 255 }, 0 );
					TE_SendToAll();
				}
				if(DICE == 3)
				{
					new oldgold=War3_GetGold(attacker);
					new addgold=GoldGain[ult_ammunition];
					new newgold=oldgold+addgold;
					War3_SetGold(attacker,newgold);
					PrintHintText(attacker,"You gain some extra gold");
				
					new Float:attacker_pos[3];
					new Float:victim_pos[3];
				
					GetClientAbsOrigin( attacker, attacker_pos );
					GetClientAbsOrigin( victim, victim_pos );
				
					attacker_pos[2] += 40;
					victim_pos[2] += 40;
				
					TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, BeamSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 255, 255, 0, 255 }, 0 );
					TE_SendToAll();
				}
				if(DICE == 4)
				{
					War3_SetXP( attacker, thisRaceID, War3_GetXP( attacker, thisRaceID ) + XPGain[ult_ammunition] );
					PrintHintText(attacker,"You gain some extra xp");
				
					new Float:attacker_pos[3];
					new Float:victim_pos[3];
				
					GetClientAbsOrigin( attacker, attacker_pos );
					GetClientAbsOrigin( victim, victim_pos );
				
					attacker_pos[2] += 40;
					victim_pos[2] += 40;
				
					TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, BeamSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 0, 255, 0, 255 }, 0 );
					TE_SendToAll();
				}
				if(DICE == 5)
				{
					War3_SetBuff( victim, bNoMoveMode, thisRaceID, true );
					CreateTimer( FreezeTime[ult_ammunition], StopFreeze, victim );
					PrintHintText(attacker,"You froze your enemy");
				
					new Float:attacker_pos[3];
					new Float:victim_pos[3];
				
					GetClientAbsOrigin( attacker, attacker_pos );
					GetClientAbsOrigin( victim, victim_pos );
				
					attacker_pos[2] += 40;
					victim_pos[2] += 40;
				
					TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, BeamSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 0, 0, 255, 255 }, 0 );
					TE_SendToAll();
				}
				if(DICE == 6)
				{
					Drug( victim, 1 );
					CreateTimer( 1.0, Drug1, victim );
					CreateTimer( 2.0, Drug1, victim );
					CreateTimer( 3.0, Drug2, victim );
					PrintHintText(attacker,"You drugged your enemy");
				
					new Float:attacker_pos[3];
					new Float:victim_pos[3];
				
					GetClientAbsOrigin( attacker, attacker_pos );
					GetClientAbsOrigin( victim, victim_pos );
				
					attacker_pos[2] += 40;
					victim_pos[2] += 40;
				
					TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, BeamSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 111, 0, 255, 255 }, 0 );
					TE_SendToAll();
				}
				if(DICE == 7)
				{
					bSniperDot[victim]=true;
					DotBy[victim]=attacker;
					DotUntil[victim]=GetGameTime()+DotDuration[ult_ammunition];
					PrintHintText(attacker,"You poisoned your enemy");
				
					new Float:attacker_pos[3];
					new Float:victim_pos[3];
				
					GetClientAbsOrigin( attacker, attacker_pos );
					GetClientAbsOrigin( victim, victim_pos );
				
					attacker_pos[2] += 40;
					victim_pos[2] += 40;
				
					TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, BeamSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 55, 0, 255, 255 }, 0 );
					TE_SendToAll();
				}
			}
		}
	}
}

public Action:StopFreeze( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
	}
}

public Action:Drug1( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		Drug( client, 1 );
	}
}

public Action:Drug2( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		Drug( client, 0 );
	}
}

stock Drug( client, mode )
{
	if( mode == 1 )
	{
		new Float:pos[3];
		GetClientAbsOrigin( client, pos );

		new Float:angs[3];
		GetClientEyeAngles( client, angs );

		angs[2] = g_DrugAngles[GetRandomInt( 0, 100 ) % 20];

		TeleportEntity( client, pos, angs, NULL_VECTOR );

		new clients[2];
		clients[0] = client;

		new Handle:message = StartMessageEx( g_FadeUserMsgId, clients, 1 );
		BfWriteShort( message, 255 );
		BfWriteShort( message, 255 );
		BfWriteShort( message, ( 0x0002 ) );
		BfWriteByte( message, GetRandomInt( 0, 255 ) );
		BfWriteByte( message, GetRandomInt( 0, 255 ) );
		BfWriteByte( message, GetRandomInt( 0, 255 ) );
		BfWriteByte( message, 128 );

		EndMessage();
	}
	
	if( mode == 0 )
	{
		new Float:pos[3];
		GetClientAbsOrigin( client, pos );

		new Float:angs[3];
		GetClientEyeAngles( client, angs );

		angs[2] = 0.0;

		TeleportEntity( client, pos, angs, NULL_VECTOR );	

		new clients[2];
		clients[0] = client;	

		new Handle:message = StartMessageEx( g_FadeUserMsgId, clients, 1 );
		BfWriteShort( message, 1536 );
		BfWriteShort( message, 1536 );
		BfWriteShort( message, ( 0x0001 | 0x0010 ) );
		BfWriteByte( message, 0 );
		BfWriteByte( message, 0 );
		BfWriteByte( message, 0 );
		BfWriteByte( message, 0 );

		EndMessage();
	}
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{			
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, SniperInvis[War3_GetSkillLevel( client, thisRaceID, SKILL_CAMOUFLAGE )] );
	}
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	InitPassiveSkills( client );
}

public Action:SniperDoTLoop(Handle:h,any:data)
{
	new attacker;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			if(bSniperDot[i])
			{
				attacker=DotBy[i];
				if(ValidPlayer(attacker))
				{
					if(GetClientHealth(i)>1)
					{
						War3_DecreaseHP(i,1);
					}
					else
					{
						War3_DealDamage(i,1,attacker,_,"bloodcrazy");						   
					}
				}
			}
			if(GetGameTime()>DotUntil[i])
			{
				bSniperDot[i]=false;
			}
		}
	}
}