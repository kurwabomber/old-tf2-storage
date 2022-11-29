/**
* File: War3Source_999_SilentRunner.sp
* Description: Silent Runner Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions"
#include <smlib>

new thisRaceID;
new SKILL_LATCH, SKILL_JUMP, SKILL_AMMO, ULT_TRADE;



public Plugin:myinfo = 
{
    name = "War3Source Race - Silent Runner",
    author = "Remy Lebeau",
    description = "Hunter's private race for War3Source",
    version = "1.0.2",
    url = "http://sevensinsgaming.com"
};


new Float:ElectricGravity[] = { 1.0, 0.92, 0.84, 0.80, 0.76};
new Float:JumpMultiplier[] = { 1.0, 3.0, 3.1, 3.2, 3.3};
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;

new Float:g_fAmmoChance[] = { 0.0, 0.4, 0.6, 0.8, 1.01};
new Float:g_fHealthAmount[] = {0.0, 0.5, 0.6, 0.7, 0.8};
new Clip1Offset;
new g_iReloadCount[MAXPLAYERS];


new Float:UltDelay[] = { 0.0, 60.0, 50.0, 40.0, 30.0 };
new String:Sound[] =  "ambient/atmosphere/cave_hit5.wav" ;
new HaloSprite, Ult_BeamSprite1, Ult_BeamSprite2;
new Float:Ult_ClientPos[64][3];
new Float:Ult_EnemyPos[64][3];
new Ult_BestTarget[64];

//latch
new bool:bRound[66];
new BeingLatchedBy[66];
// Target getting killed
new Float:LatchChanceArr[]={0.0,0.60,0.70,0.80,1.1};
new Float:LatchonDamageMin[]={0.0,1.0,2.0,3.0,4.0};
new Float:LatchonDamageMax[]={0.0,3.0,4.0,6.0,7.0};

new String:Fangsstr[]="npc/roller/mine/rmine_blades_out2.wav";



public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Silent Runner [PRIVATE]","silentrunner");
    
    SKILL_LATCH=War3_AddRaceSkill(thisRaceID,"Dark Art","Whoever kills me will be poisoned till death. The only cure is to kill another player.",false,4);
    SKILL_JUMP=War3_AddRaceSkill(thisRaceID,"Sky Walker","Bounce around the map",false,4);
    SKILL_AMMO=War3_AddRaceSkill(thisRaceID,"No reload"," When reloading a weapon chance of getting 400 primary ammo (press reload then quickswitch)",false,4);
    ULT_TRADE=War3_AddRaceSkill(thisRaceID,"Wanna Swap?","Swaps your place with a random enemy in the server (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TRADE,20.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_JUMP, fLowGravitySkill, ElectricGravity);
}



public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
    m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
    HookEvent( "player_jump", PlayerJumpEvent );
    HookEvent("round_end",RoundOverEvent);
    HookEvent( "weapon_reload", WeaponReloadEvent );
    Clip1Offset = FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" );
}



public OnMapStart()
{
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    Ult_BeamSprite1 = PrecacheModel( "materials/effects/ar2_altfire1.vmt" );
    Ult_BeamSprite2 = PrecacheModel( "models/alyx/pupil_r.vmt" );
    War3_PrecacheSound( Sound );
    War3_PrecacheSound( Fangsstr );
    
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
        g_iReloadCount[client] = 0;
        W3ResetAllBuffRace( client, thisRaceID ); 
        
    }
    else
    {
        bRound[client]=false;
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


public OnUltimateCommand( client, race, bool:pressed )
{
    if( ValidPlayer( client, true ) )
    {
        if( race == thisRaceID && pressed && IsPlayerAlive( client ) )
        {
            new ult_level = War3_GetSkillLevel( client, race, ULT_TRADE );
            if( ult_level > 0 )
            {
                if( War3_SkillNotInCooldown( client, thisRaceID, ULT_TRADE, true ) )
                {
                    Trade( client );
                    War3_CooldownMGR( client, UltDelay[ult_level], thisRaceID, ULT_TRADE);
                }
            }
            else
            {
                W3MsgUltNotLeveled( client );
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

public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim)&&ValidPlayer(attacker, true))
    {
        if(ValidPlayer( attacker,true ) && bRound[attacker]==true)
        {
            Client_PrintToChat(attacker,false,"{G}The blood of your foe provides an antidote to your poison.");
            bRound[attacker]=false;
            BeingLatchedBy[attacker]=0;    
        }
        new race = War3_GetRace(victim);
        if(race==thisRaceID)
        {
            new skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_LATCH);
            if(skilllevel>0&&GetRandomFloat(0.0,1.0)<=LatchChanceArr[skilllevel]&&!W3HasImmunity(attacker,Immunity_Skills)&&!Silenced(victim))
            {
                BeingLatchedBy[attacker]=victim;
                Client_PrintToChat(attacker,false,"{R}You are being poisoned by Silent Runner - To survive you must get a kill!");
                PrintToChat(victim,"You have poisoned your killer");
                EmitSoundToAll(Fangsstr,attacker);
                EmitSoundToAll(Fangsstr,victim);
                CreateTimer(2.0,LatchDamageLoop,attacker);
                bRound[attacker]=true;
            }
        }

    }
}



public Action:LatchDamageLoop(Handle:timer,any:client)
{
    if(ValidPlayer(client,true)&&ValidPlayer(BeingLatchedBy[client])&&bRound[client])
    {
        
        decl skill;
        skill=War3_GetSkillLevel(BeingLatchedBy[client],thisRaceID,SKILL_LATCH);
        War3_DealDamage(client,RoundFloat(GetRandomFloat(LatchonDamageMin[skill],LatchonDamageMax[skill])),BeingLatchedBy[client],_,"LatchOn",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG);
        W3FlashScreen(client,RGBA_COLOR_RED, 0.5,0.5);
        //PrintToConsole(client,"Recieved -%d Latchon dmg",War3_GetWar3DamageDealt());
        //PrintToConsole(BeingLatchedBy[client],"Dealt -%d Latchon dmg",War3_GetWar3DamageDealt());
        CreateTimer(1.0,LatchDamageLoop,client);
    }
}



public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        new skill_long = War3_GetSkillLevel( client, race, SKILL_JUMP );
        if( skill_long > 0 )
        {
            new Float:velocity[3] = { 0.0, 0.0, 0.0 };
            velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
            velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
            velocity[0] *= JumpMultiplier[skill_long] * 0.25;
            velocity[1] *= JumpMultiplier[skill_long] * 0.25;
            SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
        }
    }
}


    

public WeaponReloadEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        new skill_ammo = War3_GetSkillLevel( client, race, SKILL_AMMO );
        if( skill_ammo > 0 && GetRandomFloat( 0.0, 1.0 ) < g_fAmmoChance[skill_ammo] )
        {
            new String:weapon[32]; 
            GetClientWeapon( client, weapon, 32 );
            if( StrEqual( weapon, "weapon_p90" ) || StrEqual( weapon, "weapon_g3sg1" ) || StrEqual( weapon, "weapon_sg550" ))
            {
                PrintToChat(client,"Extra ammo is unavailable for P90 & autosniper");
            }
            else
            {
                g_iReloadCount[client] += 1;
                PrintToChat (client, "You sacrifice part of your life for extra ammunition");
                CreateTimer( 3.5, SetWepAmmo, client );
                new Float:buff1= 100 - (100 * g_fHealthAmount[skill_ammo]);
                new buff2=RoundToCeil(g_iReloadCount[client] * buff1);
                if (buff2 > 99)
                {
                    buff2 = 99;
                }
                War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,-buff2);
//                PrintToChat(client, "Buff1 = |%f|, Buff2 = |%i|", buff1, buff2);
                W3FlashScreen(client,RGBA_COLOR_RED, 1.0, 1.0, FFADE_OUT);
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

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i))
        {
            bRound[i]=false;
        }
    }
}



public Action:SetWepAmmo( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        new wep_ent = W3GetCurrentWeaponEnt( client );
        SetEntData( wep_ent, Clip1Offset, 400, 4 );
    }
}


stock Trade( client )
{
    if( GetClientTeam( client ) == TEAM_T )
        Ult_BestTarget[client] = War3_GetRandomPlayer( client, "#ct", true, true );
    if( GetClientTeam( client ) == TEAM_CT )
        Ult_BestTarget[client] = War3_GetRandomPlayer( client, "#t", true, true );

    if( Ult_BestTarget[client] == 0 )
    {
        PrintHintText( client, "No Target Found" );
    }
    else
    {
        GetClientAbsOrigin( Ult_BestTarget[client], Ult_EnemyPos[client] );
        GetClientAbsOrigin( client, Ult_ClientPos[client] );
        
        new String:Name[64];
        GetClientName( Ult_BestTarget[client], Name, 64 );
    
        EmitSoundToAll( Sound, client );
        EmitSoundToAll( Sound, Ult_BestTarget[client] );
        
        PrintToChat( client, "\x05: \x03You will trade places with \x04%s \x03in three seconds!", Name );
        
        CreateTimer( 3.0, TradeDelay, client );
        
        new Float:BeamPos[3];
        BeamPos[0] = Ult_ClientPos[client][0];
        BeamPos[1] = Ult_ClientPos[client][1];
        BeamPos[2] = Ult_ClientPos[client][2] + 40.0;
        
        TE_SetupBeamRingPoint( BeamPos, 950.0, 190.0, Ult_BeamSprite1, HaloSprite, 0, 0, 3.0, 150.0, 0.0, { 115, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
        TE_SendToAll();

        TE_SetupBeamRingPoint( BeamPos, 950.0, 190.0, Ult_BeamSprite2, HaloSprite, 0, 0, 3.0, 150.0, 0.0, { 115, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
        TE_SendToAll();
    }
}


public Action:TradeDelay( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) && Ult_BestTarget[client] )
    {
        TeleportEntity( Ult_BestTarget[client], Ult_ClientPos[client], NULL_VECTOR, NULL_VECTOR );
        TeleportEntity( client, Ult_EnemyPos[client], NULL_VECTOR, NULL_VECTOR );
    }
}