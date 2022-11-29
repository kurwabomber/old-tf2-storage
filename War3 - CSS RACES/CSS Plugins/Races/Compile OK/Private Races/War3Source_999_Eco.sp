/**
* File: War3Source_999_Eco.sp
* Description: Eco Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include <smlib>
#include "W3SIncs/haaaxfunctions"


new thisRaceID;
new SKILL_LEAP, SKILL_DAMAGE, SKILL_SPEED, ULT_STEAL;

public Plugin:myinfo = 
{
    name = "War3Source Race - Eco",
    author = "Remy Lebeau",
    description = "Rimey's private race for War3Source",
    version = "0.9",
    url = "http://sevensinsgaming.com"
};


//leap
new Float:leapPower[5]={0.0,350.0,400.0,450.0,500.0};
new Float:g_fLeapCooldown[] = {0.0, 35.0,30.0,25.0,20.0};
new bool:g_bLeapActive[MAXPLAYERS];
new bool:g_bInAir[MAXPLAYERS];
new String:leapsnd[256]; //="war3source/chronos/timeleap.mp3";
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity; //offsets

// speed
new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new Float:g_fSpeedDuration = 5.0;
new Handle:g_hSpeed[MAXPLAYERS];

//damage
new Float:g_fDamageBoost[] = { 0.0, 0.05, 0.10, 0.15, 0.2 };

//general
new String:g_sPistolList[6][] = {"weapon_glock", "weapon_usp", "weapon_p228", "weapon_deagle", "weapon_elite", "weapon_fiveseven"};
new String:g_sGunList[11][] = {"weapon_m3", "weapon_xm1014", "weapon_galil", "weapon_scout","weapon_famas", "weapon_aug", "weapon_sg550", "weapon_mac10", "weapon_tmp", "weapon_mp5navy", "weapon_ump45"};

//ultimate
new Float:g_fUltCooldown[] = {0.0, 50.0, 45.0, 40.0, 30.0};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Eco [PRIVATE]","eco");
    
    SKILL_LEAP=War3_AddRaceSkill(thisRaceID,"Daring Dive","Dive forward becoming untargetable (+ability&jump)",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Manly Bullets","Deal 5/10/15/20% bonus damage",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"No Time To Bleed","Gain temporary increased speed upon being hit.",false,4);
    ULT_STEAL=War3_AddRaceSkill(thisRaceID,"Swipe","Copy currently equipped weapon from the closest enemy (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_STEAL,30.0,_);
    
    War3_CreateRaceEnd(thisRaceID);

    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamageBoost);
}



public OnPluginStart()
{
    m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");

    HookEvent("player_jump",PlayerJumpEvent);
    CreateTimer(0.3, SetAmmo,_,TIMER_REPEAT);
}



public OnMapStart()
{
//    HookEvent( "weapon_reload", WeaponReloadEvent, EventHookMode_Pre );
    HookEvent("round_end",RoundOverEvent);
    
    War3_AddSoundFolder(leapsnd, sizeof(leapsnd), "chronos/timeleap.mp3");
    War3_AddCustomSound(leapsnd);
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
        g_hSpeed[client] = INVALID_HANDLE;
        g_bLeapActive[client] = false;
        g_bInAir[client] = false;
        
        // Random Weapons
        Client_RemoveAllWeapons(client,"weapon_c4");
        Client_GiveWeapon(client,"weapon_knife", false);
        GivePlayerItem( client, g_sPistolList[GetRandomInt(0,5)]);
        GivePlayerItem( client, g_sGunList[GetRandomInt(0,10)]);
        
        
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
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_LEAP);
        if(skill_level>0 && War3_SkillNotInCooldown(client,thisRaceID,SKILL_LEAP,true))
        {
            if(!g_bLeapActive[client])
            {
                g_bLeapActive[client] = true;
                W3Hint(client,HINT_LOWEST,3.0,"Daring Dive Active");
            }
            else
            {
                g_bLeapActive[client] = false;
                W3Hint(client,HINT_LOWEST,3.0,"Daring Dive Inactive"); 
            }
        }
    }
}             


public OnUltimateCommand( client, race, bool:pressed )
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_STEAL );
        if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_STEAL,true))
        {
            new target = 0;
            if( GetClientTeam( client ) == TEAM_T )
                target = War3_GetRandomPlayer( client, "#ct", true, true, false, false, true );
            if( GetClientTeam( client ) == TEAM_CT )
                target = War3_GetRandomPlayer( client, "#t", true, true, false, false, true );

            if( target == 0 )
            {
                PrintHintText( client, "No players found to target" );
            }
            else
            {
                new String:PlayerName[256];
                GetClientName(target,PlayerName,sizeof(PlayerName));
                PrintToChat(client,"Stealing from |%s|", PlayerName);
                
                Client_RemoveAllWeapons(client,"weapon_c4");
                Client_GiveWeapon(client,"weapon_knife", false);
                
                new tempent;
                
                new String:primWeaponName[256];
                new String:secWeaponName[256];
                
                tempent = Client_GetWeaponBySlot(target, 1);
                if (tempent != -1)
                {
                    Entity_GetClassName(tempent, secWeaponName, sizeof(secWeaponName));
                    Client_GiveWeapon(client, secWeaponName, true);
                }
                
                tempent = Client_GetWeaponBySlot(target, 0);
                if (tempent != -1)
                {
                    Entity_GetClassName(tempent, primWeaponName, sizeof(primWeaponName));
                    Client_GiveWeapon(client, primWeaponName, true);
                }

                War3_CooldownMGR(client,g_fUltCooldown[ult_level],thisRaceID,ULT_STEAL,_,_);
            }
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
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( victim ) == thisRaceID )
        {
            new skill_level = War3_GetSkillLevel( victim, thisRaceID, SKILL_SPEED );
            if( !Hexed( victim, false ) && skill_level > 0 && g_hSpeed[victim] == INVALID_HANDLE )
            {
                War3_SetBuff( victim, fMaxSpeed, thisRaceID, g_fSpeed[skill_level] );
                PrintHintText(victim, "No Time To Bleed!");
                g_hSpeed[victim] = CreateTimer( g_fSpeedDuration, StopSpeed, GetClientUserId(victim) );
            }
        } 
    }
}
 


public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0) //block self inflicted damage
    {
        if(g_bInAir[victim]&&attacker==victim){
            War3_DamageModPercent(0.0);
            return;
        }
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        
        if(vteam!=ateam)
        {
            if(g_bInAir[victim])
            {
                if(!W3HasImmunity(attacker,Immunity_Ultimates))
                {
                    War3_DamageModPercent(0.0);
                }
                else
                {
                    W3MsgEnemyHasImmunity(victim,true);
                }
            }
        }
    }
    return;
}



public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid"));

    if(ValidPlayer(client,true)){
        new race=War3_GetRace(client);
        if (race==thisRaceID)
        {
            new sl=War3_GetSkillLevel(client,race,SKILL_LEAP);
            
            if(!Hexed(client)&&sl>0&&g_bLeapActive[client])
            { 
                new Float:velocity[3]={0.0,0.0,0.0};
                velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
                velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
                new Float:len=GetVectorLength(velocity);
                if(len>3.0){
                    //PrintToChatAll("pre  vec %f %f %f",velocity[0],velocity[1],velocity[2]);
                    ScaleVector(velocity,leapPower[sl]/len);
                    
                    //PrintToChatAll("post vec %f %f %f",velocity[0],velocity[1],velocity[2]);
                    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
                    W3EmitSoundToAll(leapsnd,client);
                    W3EmitSoundToAll(leapsnd,client);
                    War3_CooldownMGR(client,g_fLeapCooldown[sl],thisRaceID,SKILL_LEAP,_,_);
                    g_bInAir[client] = true;
                    g_bLeapActive[client] = false;
                    CreateTimer(1.5,EndVoodoo,client);
                    W3SetPlayerColor(client,thisRaceID,255,200,0,_,GLOW_ULTIMATE); //255,200,0);
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
public Action:SetAmmo(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID )
		{
        
            new String:primWeaponName[256];
            new String:secWeaponName[256];
            
            new tempent = Client_GetWeaponBySlot(i, 0);
            if (tempent != -1)
                Entity_GetClassName(tempent, primWeaponName, sizeof(primWeaponName));
                
            tempent = Client_GetWeaponBySlot(i, 1);
            if (tempent != -1)
                Entity_GetClassName(tempent, secWeaponName, sizeof(secWeaponName));
           
            Client_SetWeaponPlayerAmmo(i, primWeaponName, 0,0);
            Client_SetWeaponPlayerAmmo(i, secWeaponName, 0,0);
        }
        
    }
        
}


public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) && g_hSpeed[i] != INVALID_HANDLE)
        {
            W3ResetAllBuffRace( i, thisRaceID );
            KillTimer(g_hSpeed[i]);
            g_hSpeed[i] = INVALID_HANDLE;
        }
    }
}


public Action:EndVoodoo(Handle:timer,any:client)
{
    g_bInAir[client]=false;
    W3ResetPlayerColor(client,thisRaceID);

}

    
public Action:StopSpeed( Handle:timer, any:user)
{
    new client = GetClientOfUserId(user);
    if( ValidPlayer( client ) )
    {
        War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
    }
    g_hSpeed[client] = INVALID_HANDLE;
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
    if(ValidPlayer(client,true ) && (War3_GetRace( client ) == thisRaceID))
    {
        return Plugin_Handled; // Do not allow any purchases
    }
    return Plugin_Continue;
}
