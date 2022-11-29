#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - FU P90THR33",
	author = "ABGar",
	description = "The FU P90THR33 race for War3Source.",
	version = "1.0",
	// Little Napa's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5261-fu-p90thr33-private/?hl=napa
}

new thisRaceID;

new SKILL_FAST, SKILL_STUN, SKILL_THREE, ULT_TELE;

// SKILL_FAST
new Float:RunFast[]={1.0,1.15,1.2,1.25,1.3};

// SKILL_STUN
new Float:StunTime[]={0.0,2.0,3.0,4.0};
new Float:StunCD[]={0.0,30.0,25.0,20.0};

// SKILL_THREE
new Float:Vampire[]={0.0,0.8,0.11,0.14,0.17,0.2};
new ThreeAmmo[]={1,2,3,6,9,12};
new Clip1Offset;
new CurrentClipAmount[MAXPLAYERSCUSTOM];
new NewClipAmount[MAXPLAYERSCUSTOM];
new CurrentAmmo[MAXPLAYERSCUSTOM];

// ULT_TELE
new m_vecBaseVelocity;
new Float:PushForce[]={0.0,0.7,1.1,1.3,1.7};
new Float:TeleDuration[]={0.0,4.0,6.0,8.0,10.0};
new Float:TeleDamage[]={1.0,1.25,1.5,1.75,2.0};
new bool:FinishedInvis[MAXPLAYERSCUSTOM];
new bool:bIsInvis[MAXPLAYERSCUSTOM];
new Handle:InvisEndTimer[MAXPLAYERSCUSTOM];
new String:StartTele[] = "weapons/physcannon/physcannon_claws_close.wav";
new String:EndTele[] = "weapons/physcannon/physcannon_claws_open.wav";



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("FU P90 THR33 [PRIVATE]","fup903");
	SKILL_FAST = War3_AddRaceSkill(thisRaceID,"|F|ast","Speed (passive)",false,4);
	ULT_TELE = War3_AddRaceSkill(thisRaceID,"|U|ltimate","Teleport and invis (+ultimate)",true,4);
	SKILL_STUN = War3_AddRaceSkill(thisRaceID,"|P90| Stun","Stun anyone carrying a P90 (+ability)",false,3);
	SKILL_THREE=War3_AddRaceSkill(thisRaceID,"|THREE| Triple Health Return","Vampire and bonus bullets in clip (+ultimate)",false,5);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_FAST,fMaxSpeed,RunFast);
	War3_AddSkillBuff(thisRaceID,SKILL_THREE,fVampirePercent,Vampire);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		if (ValidPlayer(client,true))
        {
			InitPassiveSkills(client);
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

public InitPassiveSkills(client)
{
	DropSecWeapon(client);
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle,weapon_knife");
	GivePlayerItem(client,"weapon_deagle");
	CreateTimer(0.1,FirstAmmo,client);
}

public OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("weapon_reload", Event_WeaponReload);
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	Clip1Offset = FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" );
}

public OnMapStart()
{
	War3_PrecacheSound(StartTele);
	War3_PrecacheSound(EndTele);
}

public DropSecWeapon(client)
{
	new iWeapon = GetPlayerWeaponSlot(client, 1);
	if(IsValidEntity(iWeapon))
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}

/* *************************************** (SKILL_STUN) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new StunLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_STUN);
		if(StunLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_STUN,true,true,true))
			{
				for (new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true))
					{
						if(Client_HasWeapon(i,"weapon_p90"))
						{
							War3_SetBuff(i,bStunned,thisRaceID,true);
							CreateTimer(StunTime[StunLevel],StopStun,i);
							PrintHintText(i,"With <3 from %N... for using a P90",client);
							War3_CooldownMGR(client,StunCD[StunLevel],thisRaceID,SKILL_STUN,true,true);
						}
					}
				}
			}
		}
		else
			PrintHintText(client,"Level your skill first");
	}
}

public Action:StopStun(Handle:h, any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bStunned,thisRaceID,false);
	}
}

/* *************************************** (SKILL_THREE) *************************************** */
public Event_WeaponReload( Handle:event, const String:name[], bool:dontBroadcast )
{
	for(new client=1;client<=MaxClients;client++)
	{
		if( War3_GetRace(client) == thisRaceID )
		{
			new String:weapon[32]; 
			GetClientWeapon( client, weapon, 32 );
			if( StrEqual( weapon, "weapon_deagle" ) )
			{
				new ThreeLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_THREE);
				if(ThreeLevel>0)
				{
					new weapontype = GetPlayerWeaponSlot(client, 1);
					new ammoType = GetEntProp(weapontype, Prop_Send, "m_iPrimaryAmmoType");
					new wep_ent = W3GetCurrentWeaponEnt(client);
					
					CurrentClipAmount[client]=GetEntData(wep_ent,Clip1Offset,4);
					NewClipAmount[client]=ThreeAmmo[ThreeLevel];
					CurrentAmmo[client]=GetEntProp(client,Prop_Send,"m_iAmmo",_,ammoType);
					if(CurrentAmmo[client]!=0)
						CreateTimer( 2.2, SetNewAmmo, client );
				}
			}
		}
	}
}

public Action:FirstAmmo(Handle:timer,any:client)
{
	if(War3_GetRace(client)==thisRaceID && IsPlayerAlive(client))
	{
		new ThreeLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_THREE);
		if(ThreeLevel > 0)
		{
			new Clip = ThreeAmmo[ThreeLevel];
			Client_SetWeaponAmmo(client,"weapon_deagle",-1,-1,Clip,-1);
		}
	}
}

public Action:SetNewAmmo(Handle:timer,any:client)
{
	if(War3_GetRace(client)==thisRaceID && IsPlayerAlive(client))
	{
		new ThreeLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_THREE);
		if(ThreeLevel > 0)
		{
			new NewSpareAmmo = CurrentAmmo[client] - (NewClipAmount[client]-CurrentClipAmount[client]);
			
			if(NewSpareAmmo<1)
			{
				NewClipAmount[client]=CurrentClipAmount[client]+CurrentAmmo[client];
				NewSpareAmmo=0;
			}
			Client_SetWeaponAmmo(client,"weapon_deagle",NewSpareAmmo,0,(NewClipAmount[client]),0);
		}
	}
}

/* *************************************** (ULT_TELE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new TeleLevel=War3_GetSkillLevel(client,thisRaceID,ULT_TELE);
		if(TeleLevel>0)
		{
			if(bIsInvis[client])
				TriggerTimer(InvisEndTimer[client]);
			else if(SkillAvailable(client,thisRaceID,ULT_TELE,true,true,true))
			{
				TeleportPlayer(client);
				CreateTimer(1.0,StopMovement,client);
				InvisEndTimer[client]=CreateTimer(TeleDuration[TeleLevel],EndInvis,client);
				War3_CooldownMGR(client,20.0,thisRaceID,ULT_TELE, _, _);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public TeleportPlayer(client)
{
	if(client>0 && IsPlayerAlive(client))
	{
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,0.3);
		EmitSoundToAll(StartTele,client);
		new ult_level = War3_GetSkillLevel(client,thisRaceID,ULT_TELE);
		new Float:startpos[3];
		new Float:endpos[3];
		new Float:localvector[3];
		new Float:velocity[3];
		
		GetClientAbsOrigin(client,startpos);
		War3_GetAimEndPoint(client,endpos);
		
		localvector[0] = endpos[0] - startpos[0];
		localvector[1] = endpos[1] - startpos[1];
		localvector[2] = endpos[2] - startpos[2];
		
		velocity[0] = localvector[0] * PushForce[ult_level];
		velocity[1] = localvector[1] * PushForce[ult_level];
		velocity[2] = localvector[2] * PushForce[ult_level];
		
		SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
	}
}



public Action:StopMovement(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		War3_SetBuff(client,bNoMoveMode,thisRaceID,true);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
		bIsInvis[client]=true;
	}
}


public Action:EndInvis(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
		bIsInvis[client]=false;
		EmitSoundToAll(EndTele,client);
		CreateTimer(4.0,EndGrav,client);
	}
}

public Action:EndGrav(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		W3ResetBuffRace(client,fLowGravitySkill,thisRaceID);
	}
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(War3_GetRace(client)==thisRaceID && bIsInvis[client])
	{
		TriggerTimer(InvisEndTimer[client]); 
		FinishedInvis[client]=true;
    }
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID && FinishedInvis[attacker])
		{
			new TeleLevel=War3_GetSkillLevel(attacker,thisRaceID,ULT_TELE);
			if(TeleLevel>0)
			{
				War3_DamageModPercent(TeleDamage[TeleLevel]);
				FinishedInvis[attacker]=false;
			}
		}
	}
}
