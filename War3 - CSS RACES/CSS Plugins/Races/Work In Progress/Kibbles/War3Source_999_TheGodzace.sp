#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source Race - The Godzace",
    author = "Kibbles",
    description = "The Godzace race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new thisRaceID;
new SKILL_HEALTH, SKILL_DROP, SKILL_BLIND, ULT_SPEEDGRAV;

//skill_health
new iAdditionalHealth[] = {0, 15, 20, 30, 40};

//skill_drop
new Float:fDropChance[] = {0.0, 0.15, 0.2, 0.25, 0.3};
new Float:fDropCooldown[] = {0.0, 15.0, 13.0, 10.0, 7.0};
new Float:fDropDuration = 1.0;

//skill_blind
new Float:fInnateBlindSelfChance = 0.5;                     //0<=selfblind
new Float:fBlindEnemyChance[] = {0.0, 0.5, 0.5, 0.5, 0.5}; //1>=blindenemy>selfblind
new Float:fBlindCooldown[] = {14.0, 14.0, 12.0, 11.0, 10.0};
new Float:fBlindDuration[] = {0.8, 0.8, 0.9, 1.0, 1.3};

//ult_speedgrav
new Float:UltTime[5] = { 0.0, 4.25, 4.85, 5.35, 6.0 };
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new bool:bTransformed[64];


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("The Godzace [PRIVATE]", "thegodzace");
    
    SKILL_HEALTH = War3_AddRaceSkill(thisRaceID, "Too strong for you", "More health! 115-140 max hp", false, 4);
    SKILL_DROP = War3_AddRaceSkill(thisRaceID, "Drop it please", "15-30% chance to disarm your enemy, 15-7 second cooldown", false, 4);
    SKILL_BLIND = War3_AddRaceSkill(thisRaceID, "Let's do this", "40-70% chance to blind your enemy for 0.8-1.3 seconds (otherwise blind yourself), 10-6 second cooldown", false, 4);
    ULT_SPEEDGRAV = War3_AddRaceSkill(thisRaceID, "Catch me :^) (+ultimate)", "Speed, gravity, what's not to love?", true, 4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_SPEEDGRAV,10.0,true);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, iAdditionalHealth);
}


public OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
	m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
	HookEvent( "player_jump", PlayerJumpEvent );
}


public OnRaceChanged(client, oldrace, newrace)
{
    if (newrace == thisRaceID)
    {
        if (ValidPlayer(client, true))
        {
            InitRace(client);
        }
    }
    else
    {
        War3_WeaponRestrictTo(client, thisRaceID, "");
		W3ResetAllBuffRace(client, thisRaceID);
    }
}
public OnWar3EventSpawn(client)
{
    War3_SetBuff( client, bDisarm, thisRaceID, false );
    if(ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        InitRace(client);
    }
}
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=0; i<MaxClients; i++)
    {
        if (ValidPlayer(i, true) && War3_GetRace(i)==thisRaceID)
        {
            InitRace(i);
        }
    }
}
static InitRace(client)
{
    War3_WeaponRestrictTo(client, thisRaceID, "weapon_awp,weapon_deagle,weapon_knife");
    if (!Client_HasWeapon(client, "weapon_awp"))
    {
        Client_GiveWeapon(client, "weapon_awp", false);
    }
    if (!Client_HasWeapon(client, "weapon_deagle"))
    {
        Client_GiveWeapon(client, "weapon_deagle", false);
    }
    bTransformed[client] = false;
    War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
    War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
}


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer(victim, true) && ValidPlayer(attacker, true) && GetClientTeam(victim) != GetClientTeam(attacker ))
	{
		if(War3_GetRace(attacker) == thisRaceID)
		{
			new skill_drop = War3_GetSkillLevel(attacker, thisRaceID, SKILL_DROP);
			if(skill_drop > 0 && !Hexed(attacker, false) && GetRandomFloat(0.0, 1.0) <= fDropChance[skill_drop])
			{
				if(!W3HasImmunity(victim, Immunity_Skills))
				{
                    War3_CooldownMGR(attacker, fDropCooldown[skill_drop], thisRaceID, SKILL_DROP, _, _);
					War3_SetBuff( victim, bDisarm, thisRaceID, true );
                    CreateTimer( fDropDuration, StopDisarm, victim);
				}
			}
            new skill_blind = War3_GetSkillLevel(attacker, thisRaceID, SKILL_BLIND);
            if (!Hexed(attacker, true) && War3_SkillNotInCooldown(attacker, thisRaceID, SKILL_BLIND, true))
            {
                War3_CooldownMGR(attacker, fBlindCooldown[skill_blind], thisRaceID, SKILL_BLIND, _, _);
                new Float:chance = GetRandomFloat(0.0, 1.0);
                if (chance <= fInnateBlindSelfChance)
                {
                    DoBlind(attacker, fBlindDuration[skill_blind]);
                }
                else if (skill_blind > 0 && chance <= (fInnateBlindSelfChance+fBlindEnemyChance[skill_drop]))
                {
                    DoBlind(victim, fBlindDuration[skill_blind]);
                }
            }
		}
	}
}
static DoBlind(client, Float:duration)
{
    W3FlashScreen(client,{0,0,0,255},duration*2.0,_,FFADE_OUT);
    W3Hint(client,HINT_COOLDOWN_NOTREADY,duration,"You've been blinded by The Godzace");
}
public Action:StopDisarm(Handle:timer, any:client)
{
    War3_SetBuff( client, bDisarm, thisRaceID, false );
}


//ult code taken from Sniper Class
public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_SPEEDGRAV );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_SPEEDGRAV, true ) )
			{
				StartTransform( client );
				War3_CooldownMGR( client, UltTime[ult_level] + 20.0, thisRaceID, ULT_SPEEDGRAV, _, _ );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}
stock StartTransform( client )
{
	new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_SPEEDGRAV );
	CreateTimer( UltTime[ult_level], EndTransform, client );
	War3_SetBuff( client, fLowGravitySkill, thisRaceID, 0.30 );
	War3_SetBuff( client, fMaxSpeed, thisRaceID, 2.0 );
	bTransformed[client] = true;
}
public Action:EndTransform( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) && bTransformed[client] )
	{
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		bTransformed[client] = false;
	}
}
public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new ult = War3_GetSkillLevel( client, race, ULT_SPEEDGRAV );
		if( ult > 0 && bTransformed[client] )
		{
			new Float:velocity[3] = { 0.0, 0.0, 0.0 };
			velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
			velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
			velocity[0] *= 1.6;
			velocity[1] *= 1.6;
			SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
		}
	}
}
public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
	bTransformed[victim] = false;
}