/**
* File: War3Source_999_SmokeM.sp
* Description: Deceit Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SMOKE, SKILL_SPEED, SKILL_ATTACK, ULT_ILLUSION;



public Plugin:myinfo = 
{
    name = "War3Source Race - Smoke and Mirrors",
    author = "Remy Lebeau",
    description = "charlie94's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Smoke & Mirrors [PRIVATE]","smokem");
    
    SKILL_SMOKE=War3_AddRaceSkill(thisRaceID,"Now you see me, Now you don't","Causes an immediate smoke field around you (+ability)",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Catch me if you can","Silent footsteps and increased speed",false,4);
    SKILL_ATTACK=War3_AddRaceSkill(thisRaceID,"Slight of hand","Chance of disarming enemy and doing double damage",false,4);
    ULT_ILLUSION=War3_AddRaceSkill(thisRaceID,"Master of Illusions","Full invisibility for 3 seconds and spawn 1/2/3/4 dummies around you (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_ILLUSION,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
}


new bool:footstepssmoke[MAXPLAYERS];
new Float:g_fSmokeCooldown[] = {0.0, 16.0, 12.0, 8.0, 4.0};
new Float:g_fUltCooldown[] = {0.0, 20.0, 19.0, 18.0, 15.0};

new Float:g_fSpeed[] = { 1.0, 1.2, 1.3, 1.4, 1.5};
new Float:DropChance[5] = { 0.0, 0.18, 0.23, 0.27, 0.50 };

new String:Bladestr[]="npc/roller/mine/rmine_blades_out2.wav";

new GlowSprite, GlowSprite2;


public OnPluginStart()
{

}



public OnMapStart()
{
    War3_PrecacheSound(Bladestr);
    GlowSprite=PrecacheModel("models/player/t_leet.mdl");
    GlowSprite2=PrecacheModel("models/player/ct_urban.mdl");
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

    new skill_footsteps = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
    if (skill_footsteps > 0)
    {    
        footstepssmoke[client] = true; 
        War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fSpeed[skill_footsteps]  );
        
    }
    else
    {
        footstepssmoke[client] = false; 
        War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0  );
    }

    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");


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
        footstepssmoke[client] = false;
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
    else
    {
        footstepssmoke[client] = false;
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


public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client) )
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SMOKE);
        if(skill_level>0)
        {
            if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_SMOKE,true))
            {
                new Float:this_pos[3];
                GetClientAbsOrigin(client,this_pos);
                new Float:fadestart = 3.0; 
                new Float:fadeend = 4.0; 
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
                
                War3_CooldownMGR( client, g_fSmokeCooldown[skill_level], thisRaceID, SKILL_SMOKE);
            }
        }
        else
        {
            PrintHintText(client, "Level up your ability first.");
        }
    
    }
}



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new ult_illusion = War3_GetSkillLevel( client, thisRaceID, ULT_ILLUSION );
        if(ult_illusion>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_ILLUSION,true))
                {
                    PrintHintText(client,"Disappear!");
                    W3FlashScreen(client,RGBA_COLOR_BLUE,1.0);
                    
                    War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0  );
                    War3_SetBuff( client, bDoNotInvisWeapon, thisRaceID, true);
                    CreateTimer(4.0,RemoveInvis,client);
                    
                    new tteam=GetClientTeam(client);
                    new Float:this_pos[3];
                    new Float:this_pos1[3];
                        
                    GetClientAbsOrigin(client,this_pos);
                    GetClientAbsOrigin(client,this_pos1);
                    for( new i = 1; i <= ult_illusion; i++ )
                    if(tteam==2)
                    {
                        TE_SetupGlowSprite(this_pos1,GlowSprite,4.0,1.0,250);
                        TE_SendToAll();
                        this_pos1[0] = this_pos[0] + GetRandomFloat(-100.0, 100.0);
                        this_pos1[1] = this_pos[1] + GetRandomFloat(-100.0, 100.0);
                    }
                    else
                    {
                        TE_SetupGlowSprite(this_pos1,GlowSprite2,4.0,1.0,250);
                        TE_SendToAll();
                        this_pos1[0] = this_pos[0] + GetRandomFloat(-100.0, 100.0);
                        this_pos1[1] = this_pos[1] + GetRandomFloat(-100.0, 100.0);
                    }
                        
                    
                
                    War3_CooldownMGR( client, g_fUltCooldown[ult_illusion], thisRaceID, ULT_ILLUSION);
                }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
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


public OnW3TakeDmgBulletPre( victim, attacker, Float:damage )
{
    if( ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_drop = War3_GetSkillLevel( attacker, thisRaceID, SKILL_ATTACK );
            if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) < DropChance[skill_drop])
            {
                if( !W3HasImmunity( victim, Immunity_Skills ) )
                {
                    FakeClientCommand( victim, "drop" );
                }
            }
            
            
            if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) < DropChance[skill_drop] )
            {
                if( !W3HasImmunity( victim, Immunity_Skills ))
                {
                    EmitSoundToAll(Bladestr,attacker);
                    EmitSoundToAll(Bladestr,victim);
                    W3FlashScreen(victim,RGBA_COLOR_RED);
                    War3_DamageModPercent( 2.0 );
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



public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer (client, true))
    {
        if(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP) && footstepssmoke[client] == true)
        {
            SetEntProp(client, Prop_Send, "m_fFlags", 4);
        }
    }
    return Plugin_Continue;
}

public Action:RemoveInvis(Handle:t,any:client)
{
    if(ValidPlayer(client))
    {
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0  );
        War3_SetBuff( client, bDoNotInvisWeapon, thisRaceID,true);
        PrintHintText(client,"Reappear.");
        W3FlashScreen(client,RGBA_COLOR_GREEN, 1.0);
    }
}