/**
* File: War3Source_999_Russell.sp
* Description: Russell the scuttle race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_DAMAGE, SKILL_GRAVITY, SKILL_PUSH;



public Plugin:myinfo = 
{
    name = "War3Source Race - Russell The Scuttle",
    author = "Remy Lebeau",
    description = "Russell The Scuttle race for War3Source",
    version = "1.2",
    url = "http://sevensinsgaming.com"
};


new Float:g_fGravity[] = { 1.0, 0.9, 0.85, 0.8, 0.75};
new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new Float:g_fPushChance[] = { 0.0, 0.25, 0.50, 0.75, 1.01 };
new Float:g_fDmgRed[]={1.0, 0.8, 0.75, 0.70, 0.65};
new Float:g_fLongJump[] = {1.1, 1.15, 1.2, 1.25, 1.3};


new m_vecBaseVelocity;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Russell The Scuttle","russell");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Scuttle Faster","Increased speed",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Tougher Shell","Take less damage",false,4);
    SKILL_GRAVITY=War3_AddRaceSkill(thisRaceID,"Carelessness","When you're a crab who needs gravity?",false,4);
    SKILL_PUSH=War3_AddRaceSkill(thisRaceID,"AHH! It's a crab!","Force enemy to jump on the spot",true,4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_GRAVITY, fLowGravitySkill, g_fGravity);
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    
    
}



public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    HookEvent("player_jump", Event_PlayerJump);
}



public OnMapStart()
{
    PrecacheModel("models/headcrab.mdl", true);
    PrecacheModel("models/headcrabblack.mdl", true);
}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
                
        
        if(GetClientTeam(client) == 3)
        {
            SetEntityModel(client, "models/headcrab.mdl");
        }
        else
        {
            SetEntityModel(client, "models/headcrabblack.mdl");
        }
        
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
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
        if(GetClientTeam(client) == 3){
            SetEntityModel(client, "models/headcrab.mdl");
        }
        else{
            SetEntityModel(client, "models/headcrabblack.mdl");
        }
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


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
        
            new skill_push = War3_GetSkillLevel( attacker, thisRaceID, SKILL_PUSH );
            if( !Hexed( attacker, true ) && GetRandomFloat( 0.01, 1.0 ) <= g_fPushChance[skill_push] && !W3HasImmunity( victim, Immunity_Skills ) )
            {
                new Float:velocity[3];
                
                velocity[2] += 600.0;
                
                SetEntDataVector( victim, m_vecBaseVelocity, velocity, true );
                
                W3FlashScreen( victim, RGBA_COLOR_RED );
            }
        }
    }            
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_victim=War3_GetRace(victim);
			new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_DAMAGE);
			if(race_victim==thisRaceID){
				if(skill_level>0){
					War3_DamageModPercent(g_fDmgRed[skill_level]);
					PrintToConsole(attacker, "Damage Reduced against Russell");
					PrintToConsole(victim, "Damage Reduced by Russell");
				}
			}

		}
	}

}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(War3_GetRace(client) == thisRaceID && ValidPlayer(client, true)) 
    {
        if(buttons & IN_BACK) 
        {
           return Plugin_Handled;
        }
        if(buttons & IN_FORWARD) 
        {
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    if (ValidPlayer(client, true))
    {
        new race = War3_GetRace(client);
        if (race == thisRaceID)
        {
            new skill2_longjump = War3_GetSkillLevel(client, race, SKILL_GRAVITY);
            new Float:long_push = 1.00;
            long_push = g_fLongJump[skill2_longjump];

            if (skill2_longjump > 0)
            {
                new v_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
                new v_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
                new v_b = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
                new Float:finalvec[3];
                finalvec[0] = GetEntDataFloat(client, v_0) * long_push / 2.0;
                finalvec[1] = GetEntDataFloat(client, v_1) * long_push / 2.0;
                finalvec[2] = long_push * 50.0;
//                SetEntDataVector(client, v_b, finalvec, true);
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
