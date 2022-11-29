/**
* File: War3Source_999_Kurama.sp
* Description: Kurama Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new  SKILL_SPEED, SKILL_DMG, SKILL_HP, ULT_NADE;

#define WEAPON_RESTRICT "weapon_knife,weapon_usp"
#define WEAPON_RESTRICT_NADE "weapon_knife,weapon_usp,weapon_hegrenade"
#define WEAPON_GIVE "weapon_usp"

public Plugin:myinfo = 
{
    name = "War3Source Race - Kurama",
    author = "Remy Lebeau",
    description = "Kurama's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new g_iHealth[]={0,20,30,40,50};
new Float:LurkerDamageMultiplier[5] = { 0.0, 1.6, 1.9, 2.1, 2.4 };
new Float:CriticalGrenadePercent[5]={0.0,0.5,1.0,1.5,2.0};
new Float:g_fBoomRadius=300.0;
new m_vecBaseVelocity;
new Float:GravForce = 2.5;
new Float:g_fUltCooldown = 50.0;
new BeamSprite;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Kurama [PRIVATE]","kurama");
    
    SKILL_HP=War3_AddRaceSkill(thisRaceID,"Chakra","Nine Tail is Chakra is out of this world giving it unbelieveable health",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Fox Agility","there is not another beast out there that can match Nine Tails agility",false,4);
    SKILL_DMG=War3_AddRaceSkill(thisRaceID,"Nine Tailed Strength","Nine Tails natural strength in bullet form",false,4);
    ULT_NADE=War3_AddRaceSkill(thisRaceID,"Nine Tails Beast Ball","AOE attack that obliterates all who calls this beast enemy",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_NADE,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_HP, iAdditionalMaxHealth, g_iHealth);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    HookEvent("hegrenade_detonate",GrenadeExplode);
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
}




public OnMapStart()
{
    BeamSprite=War3_PrecacheBeamSprite(); 
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

    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    CreateTimer( 1.5, GiveWep, client );

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

public OnUltimateCommand(client, race, bool:pressed)
{
    if (ValidPlayer(client, true) && race == thisRaceID && pressed)
    {
        new skill=War3_GetSkillLevel(client,race,ULT_NADE);
        if(skill>0)
        {
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_NADE,true)&&!Silenced(client))
            {
                PrintHintText(client, "Nine Tails Beast Ball Loaded");
                War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT_NADE);
                GivePlayerItem(client, "weapon_hegrenade");
                FakeClientCommand(client, "use weapon_hegrenade");
                War3_CooldownMGR(client, g_fUltCooldown, thisRaceID, ULT_NADE, true, true);
            }
        }
        else
        { 
            W3MsgUltNotLeveled(client);
        }
    }
}



/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(victim>0&&attacker>0&&victim!=attacker)
    {
        new race_attacker=War3_GetRace(attacker);
        if( race_attacker == thisRaceID )
		{
            if( ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ))
            {
                
                new String:wpnstr[32];
                GetClientWeapon( attacker, wpnstr, 32 );
                if( StrEqual( wpnstr, "weapon_usp" ) && StrEqual( weapon, "player" ) )
                {
                    new skill_level_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
                    if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.20 && skill_level_dmg > 0 )
                    {
                        if( !W3HasImmunity( victim, Immunity_Skills ) )
                        {
                            War3_DealDamage( victim, RoundToFloor( damage * LurkerDamageMultiplier[War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG )] / 2 ), attacker, DMG_BULLET, "kurama_crit" );
                            W3FlashScreen( victim, RGBA_COLOR_RED );

                            W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
                        }
                    }
                }
                
                if( StrEqual( weapon, "hegrenade_projectile" ) )
                {
                    new skill_level = War3_GetSkillLevel( attacker, thisRaceID, ULT_NADE );
                    if( !Hexed( attacker, false ) && skill_level > 0 )
                    {
                        new Float:percent=CriticalGrenadePercent[skill_level];
                        new originaldamage=RoundToFloor(damage);
                        new health_take=RoundFloat((damage*percent));
                        
                        new onehp=false;
                        ///you cannot die from crit nade unless the usual nade damage kills you
                        if(GetClientHealth(victim)>originaldamage&&health_take>GetClientHealth(victim)){
                                health_take=GetClientHealth(victim) -1;
                                onehp=true;
                        }

                        if(War3_DealDamage(victim,health_take,attacker,_,"criticalnade",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG))
                        {
                            W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),ULT_NADE);
                            W3FlashScreen(victim,RGBA_COLOR_RED);
                            if(onehp){
                                SetEntityHealth(victim,1); 
                            }
                            decl Float:fPos[3];
                            GetClientAbsOrigin(victim,fPos);
                            new Float:fx_delay = 0.35;
                            for(new i=0;i<4;i++)
                            {
                                TE_SetupExplosion(fPos, BeamSprite, 4.5, 1, 4, 0, TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_ROTATE);
                                TE_SendToAll(fx_delay);
                                fx_delay += GetRandomFloat(0.30,0.50);
                            }
                        }
                    }
                }
            }
        }
    }
}

public GrenadeExplode(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client_userid = GetEventInt(event, "userid");    
    new client = GetClientOfUserId(client_userid);
    new client_team = GetClientTeam(client);
    new Float:pos1[3];
    pos1[0] = GetEventFloat(event,"x");
    pos1[1] = GetEventFloat(event,"y");
    pos1[2] = GetEventFloat(event,"z");
    new String:wpnstr[32];
    GetClientWeapon( client, wpnstr, 32 );
    if ((War3_GetRace( client ) == thisRaceID) && ValidPlayer(client))
    {
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true) && GetClientTeam( i ) != client_team)
            {

                new Float:pos2[3];

                GetClientAbsOrigin( i, pos2 );
                pos2[2]+=30.0;
                new Float:victimdistance=GetVectorDistance(pos1,pos2);
                if(victimdistance<g_fBoomRadius)
                {
                    new Float:velocity[3];

                    MakeVectorFromPoints(pos1, pos2, velocity);
                    NormalizeVector(velocity, velocity);
                    ScaleVector(velocity, 100.0 * GravForce);
                    velocity[2] += 300.0;

                    SetEntDataVector( i, m_vecBaseVelocity, velocity, true );
                }
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

public OnWeaponFired(client)
{	
	if (War3_GetRace(client) == thisRaceID)
	{
		new String:weapon[128];//weapon Char Array
		GetClientWeapon(client, weapon, 128);
		if(StrEqual(weapon,"weapon_hegrenade"))
		{
			CreateTimer(1.5, NadeRestrict, GetClientUserId(client));
		}
	}
}

public Action:NadeRestrict( Handle:timer, any:userid )
{
    new client = GetClientOfUserId(userid);
    if(ValidPlayer(client,true))
    {
        War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    }
}


public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}
   

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
		GivePlayerItem(client, "weapon_usp");
	
    }
}