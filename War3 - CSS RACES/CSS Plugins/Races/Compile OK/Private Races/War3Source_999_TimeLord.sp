/**
* File: War3Source_999_TimeLord.sp
* Description: TimeLord Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/RemyFunctions"

new thisRaceID;
new SKILL_FREEZE, SKILL_SPEED, SKILL_RESPAWN, ULT_SUMMON;


public Plugin:myinfo = 
{
    name = "War3Source Race - Time Lord",
    author = "Remy Lebeau",
    description = "Elimist's private race for War3Source",
    version = "1.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fFreezeChance[] = { 0.0, 0.1, 0.15, 0.2, 0.25 };
new Float:g_fFreezeTime = 1.5;

new g_iKillCount[MAXPLAYERS];
new Float:g_fSpeedMultiplier[] = {0.0, 0.0025, 0.005, 0.0075, 0.01};
new Float:g_fSpeedCap = 0.6;
new Float:g_fDamageMultiplier[] = {0.0, 0.0025, 0.005, 0.0075, 0.01};
new Float:g_fDamageCap = 0.3;
new BeamSprite;

new Float:g_fRespawnChance[] = {0.0, 0.1, 0.15, 0.20, 0.25};
new Float:g_fRespawnCooldown = 20.0;
new MyWeaponsOffset,AmmoOffset;

new Float:g_fUltCooldown[] = {0.0, 60.0, 45.0, 30.0, 20.0};
new String:summon_sound[]="war3source/archmage/summon.wav";


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Time Lord [PRIVATE]","timelord");
    
    SKILL_FREEZE=War3_AddRaceSkill(thisRaceID,"Time Lock","Chance to freeze enemy on hit.",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"TimeLord's Wrath","Speed and attack damage increase per kill",false,4);
    SKILL_RESPAWN=War3_AddRaceSkill(thisRaceID,"Regenerate","Chance to respawn when you die",false,4);
    ULT_SUMMON=War3_AddRaceSkill(thisRaceID,"Summon Companion","Revive a fallen team-mate(+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_SUMMON,20.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
}



public OnPluginStart()
{
    MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
    AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
}



public OnMapStart()
{
    BeamSprite = War3_PrecacheBeamSprite(); 
    War3_AddCustomSound(summon_sound);
    CreateTimer(1.0, HudInfo_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
    if (ValidPlayer(client,true))
    {
        new skill_speed = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
        if (skill_speed > 0)
        {
            new Float:SpeedModifier = g_fSpeedMultiplier[skill_speed] * g_iKillCount[client];
            if(SpeedModifier > g_fSpeedCap)
            {
                SpeedModifier = g_fSpeedCap;
            }
            SpeedModifier = SpeedModifier + 1;
            War3_SetBuff(client,fMaxSpeed,thisRaceID,SpeedModifier);
        
            new Float:DamageModifier = g_fDamageMultiplier[skill_speed] * g_iKillCount[client];
            if(DamageModifier > g_fDamageCap)
            {
                DamageModifier = g_fDamageCap;
            }
            War3_SetBuff(client,fDamageModifier,thisRaceID,DamageModifier);    

        }

    }
}


public OnRaceChanged( client,oldrace,newrace )
{
    if(ValidPlayer(client))
    {
        if( newrace == thisRaceID)
        {
            if(ValidPlayer( client, true ))
            {
                InitPassiveSkills( client );
            }   
            g_iKillCount[client] = 0;
        }
        else
        {
            W3ResetAllBuffRace( client, thisRaceID );
            War3_WeaponRestrictTo(client,thisRaceID,"");
        }
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



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID, ULT_SUMMON );
        if(skill_level>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_SUMMON,true)) 
                {
                    new Float:position111[3];
                    War3_CachedPosition(client,position111);
                    position111[2]+=5.0;
                    new targets[MAXPLAYERS];
                    new foundtargets;
                    new client_team=GetClientTeam(client);
                    for(new ally=1;ally<=MaxClients;ally++){
                        if(ValidPlayer(ally)){
                            new ally_team=GetClientTeam(ally);
                            if(War3_GetRace(ally)!=thisRaceID && !IsPlayerAlive(ally) && ally_team==client_team){
                                targets[foundtargets]=ally;
                                foundtargets++;
                            }
                        }
                    }
                    new target;
                    if(foundtargets>0){
                        target=targets[GetRandomInt(0, foundtargets-1)];
                        if(target>0){
                            new Float:ang[3];
                            new Float:pos[3];
                            War3_SpawnPlayer(target);
                            GetClientEyeAngles(client,ang);
                            GetClientAbsOrigin(client,pos);
                            TeleportEntity(target,pos,ang,NULL_VECTOR);
                            CreateTimer(3.0,normal,target);
                            CreateTimer(3.0,normal,client);
                            EmitSoundToAll(summon_sound,client);
                            CreateTimer(3.0, Stop, client);
                        }
                    }
                    else
                    {
                        PrintHintText(client,"There are no allies you can rez");
                    }
                
                    War3_CooldownMGR(client,g_fUltCooldown[skill_level],thisRaceID,ULT_SUMMON,true,_);
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

public OnWar3EventDeath( victim, attacker )
{
    if(ValidPlayer(attacker) && ValidPlayer(victim) && GetClientTeam( victim ) != GetClientTeam( attacker ))
    {
        new race_attacker=War3_GetRace(attacker);
        if(race_attacker==thisRaceID)
        {
            g_iKillCount[attacker]++;
            InitPassiveSkills( attacker );
        }
        
        new race_victim=War3_GetRace(victim);
        if(race_victim==thisRaceID && War3_GetSkillLevel(victim,thisRaceID,SKILL_RESPAWN)>0 && GetRandomFloat(0.0,1.0) < g_fRespawnChance[War3_GetSkillLevel(victim,thisRaceID,SKILL_RESPAWN)])
        {
            new bool:should_vengence=false;
            if(ValidPlayer(attacker)&&W3HasImmunity(attacker,Immunity_Ultimates))
            {
                W3MsgSkillBlocked(attacker,_,"Vengence");
                W3MsgVengenceWasBlocked(victim,"Attacker Immunity");
            }
            else
            {
                should_vengence=true;
            }

            if(!War3_SkillNotInCooldown(victim,thisRaceID,SKILL_RESPAWN,false) )
            {
                    W3MsgVengenceWasBlocked(victim,"cooldown");
                    should_vengence=false;
            }
            
            if(should_vengence)
            {
                new victimTeam=GetClientTeam(victim);
                new playersAliveSameTeam;
                for(new i=1;i<=MaxClients;i++)
                {
                    if(i!=victim&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam)
                    {
                        playersAliveSameTeam++;
                    }
                }
                if(playersAliveSameTeam>0)
                {
                    // In vengencerespawn do we actually make cooldown
                    CreateTimer(0.2,VengenceRespawn,GetClientUserId(victim));
                }
                else{
                    W3MsgVengenceWasBlocked(victim,"last one alive");
                }
            }
        }
        
    }

}


public GiveDeathWeapons(client)
{
    if(client>0)
    {
        // reincarnate with weapons
        // drop weapons beside c4 and knife
        for(new s=0;s<10;s++)
        {
            new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
            if(ent>0 && IsValidEdict(ent))
            {
                new String:ename[64];
                GetEdictClassname(ent,ename,64);
                if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
                {
                    continue; // don't think we need to delete these
                }
                W3DropWeapon(client,ent);
                UTIL_Remove(ent);
            }
        }
        // restore iAmmo
        for(new s=0;s<32;s++)
        {
            SetEntData(client,AmmoOffset+(s*4),War3_CachedDeadAmmo(client,s),4);
        }
        // give them their weapons
        for(new s=0;s<10;s++)
        {
            new String:wep_check[64];
            War3_CachedDeadWeaponName(client,s,wep_check,64);
            if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
            {
                new wep_ent=GivePlayerItem(client,wep_check);
                if(wep_ent>0)
                {
                        //dont lower ammo
                    //SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,s),4);
                }
            }
        }
    }
}

public Action:VengenceRespawn(Handle:t,any:userid)
{
    new client=GetClientOfUserId(userid);
    if(client>0 && War3_GetRace(client)==thisRaceID) //did he become alive?
    {
        if(IsPlayerAlive(client)){
            W3MsgVengenceWasBlocked(client,"you are alive");
        }
        else{
        
            new alivecount;
            new team=GetClientTeam(client);
            for(new i=1;i<=MaxClients;i++){
                if(ValidPlayer(i,true)&&GetClientTeam(i)==team){
                    alivecount++;
                    break;
                }
            }
            if(alivecount==0){
                W3MsgVengenceWasBlocked(client,"last player death or round end");
            }
            else
            {
                War3_SpawnPlayer(client);
                GiveDeathWeapons(client);
                
                War3_ChatMessage(client,"Regenerated!");

                War3_CooldownMGR(client,g_fRespawnCooldown,thisRaceID,SKILL_RESPAWN,false,true);
            }
        }
    }
    
}



public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {

            new skill_freeze = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FREEZE );
            if( !Hexed( attacker, false ) && skill_freeze > 0 && GetRandomFloat( 0.0, 1.0 ) <= g_fFreezeChance[skill_freeze] && !W3HasImmunity( victim, Immunity_Skills  ) )
            {  
                PrintHintText(attacker, "Victim Locked in Time");
                new Float:target_pos[3];
                
                GetClientAbsOrigin( victim, target_pos );
                
                TE_SetupGlowSprite( target_pos, BeamSprite, 1.0, 2.0, 90 );
                TE_SendToAll();
                
                War3_SetBuff( victim, bNoMoveMode, thisRaceID, true );
                CreateTimer( g_fFreezeTime, StopFreeze, GetClientUserId(victim) );
                
                W3FlashScreen( victim, RGBA_COLOR_BLUE );
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
public Action:StopFreeze(Handle:t,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (ValidPlayer(client))
    {       
        War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
        W3FlashScreen( client, RGBA_COLOR_BLUE );
    }    
}



public Action:Stop(Handle:timer,any:client)
{
	StopSound(client,SNDCHAN_AUTO,summon_sound);
}

public Action:normal(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new Float:end_dist=50.0;
		new Float:end_pos[3];
		GetClientAbsOrigin(client,end_pos);
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&i!=client)
			{
				new Float:pos[3];
				GetClientAbsOrigin(i,pos);
				new Float:dist=GetVectorDistance(end_pos,pos);
				if(dist<=end_dist)
				{
					CreateTimer(1.0,normal,client);
					break;
				}
			}
		}
	}
}


public Action:HudInfo_Timer(Handle:timer, any:client)
{
    for( new i = 1; i <= MaxClients; i++ )
    {
        if(ValidPlayer(i,true) && !IsFakeClient(i))
        {
            if(War3_GetRace(i) == thisRaceID)  
            {
                new String:buffer[500];
                Format(buffer,sizeof(buffer),"\nTimeLordKills : %i",g_iKillCount[i]);
                HUD_Add(GetClientUserId(i), buffer);
            }
        }
    }  
}
