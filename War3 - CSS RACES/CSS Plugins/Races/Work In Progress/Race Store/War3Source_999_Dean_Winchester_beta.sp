/**
* File: War3Source_Dean_Winchester.sp
* Description: The Dean Winchester race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
* Modified: Remy Lebeau
*           * Fixed a number of bugs relating to multiple dean's playing at once and the dueling checks getting mixed up
*           * Made it much more robust, can now deal with players leaving mid duel, etc.
*/

#pragma semicolon 1
#include <sourcemod>

#include <sdktools>

#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions"
#include <smlib>



// War3Source stuff
new thisRaceID, SKILL_COLT, SKILL_WATER, SKILL_RESP, SKILL_EVADE, ULT_DUEL;


// Chance/Data Arrays
// skill 1
new Float:DamageMultiplier[6] = { 0.0, 0.5, 1.0, 1.5, 2.0, 2.5 };
new PhysRingSprite;

// skill 2
new Float:WaterChance[6] = { 0.0, 0.1, 0.15, 0.2, 0.25, 0.3 };
new String:WaterSound[] = "ambient/wind/wind_snippet2.wav";
new FunnelSprite;

// skill 3
new Float:SpawnChance[6] = { 0.0, 0.15, 0.20, 0.25, 0.30, 0.35 };
new Float:death_pos[MAXPLAYERS][3];

// skill 4
new Float:EvadeChance[6] = { 0.0, 0.11, 0.15, 0.22, 0.26, 0.30 };
new PupilSprite;

// skill 5
new bool:bClientInDuel[MAXPLAYERS];
new ClientTarget[MAXPLAYERS];
new bool:bDuelActivated[MAXPLAYERS];
new BeamSprite,HaloSprite;
new Handle:hDuelTimer[MAXPLAYERS];


// Other
new m_iFOV;

public Plugin:myinfo = 
{
    name = "War3Source Race - Dean Winchester",
    author = "xDr.HaaaaaaaXx & Remy Lebeau",
    description = "The Dean Winchester race for War3Source.",
    version = "1.2",
    url = ""
};

public OnPluginStart()
{
    HookEvent( "player_death", PlayerDeathEvent );
    HookEvent( "round_end", RoundEndEvent );
    HookEvent("player_disconnect",PlayerDisconnectEvent);
    
    HookEvent( "bomb_beginplant", Event_BeginPlant, EventHookMode_Pre );
    HookEvent( "bomb_begindefuse", Event_BombBeginDefuse, EventHookMode_Pre );
    
    
    m_iFOV = FindSendPropInfo( "CBasePlayer", "m_iFOV" );
    CreateTimer(1.0, far_sight,_,TIMER_REPEAT);
    
}

public OnMapStart()
{
    PhysRingSprite = PrecacheModel( "sprites/physring1.vmt" );
    PupilSprite = PrecacheModel( "models/alyx/pupil_r.vmt" );
    FunnelSprite = PrecacheModel( "models/effects/portalfunnel.mdl" );
    War3_PrecacheSound( WaterSound );
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace( "Dean Winchester [SSG-DONATOR]", "winchesterd" );
    
    SKILL_COLT = War3_AddRaceSkill( thisRaceID, "Colt", "More Damage", false, 5 );
    SKILL_WATER = War3_AddRaceSkill( thisRaceID, "Holy Water", "Shake Demon", false, 5 );
    SKILL_RESP = War3_AddRaceSkill( thisRaceID, "Contract With a Demon", "Respawn chance on death", false, 5 );
    SKILL_EVADE = War3_AddRaceSkill( thisRaceID, "Rabbit Foot", "Get Lucky and Evade Bullets", false, 5 );
    ULT_DUEL = War3_AddRaceSkill( thisRaceID, "Demon Trap", "Trap a Demon and Duel Him (winner gets 2 bonus gold)", true, 1 );
    
    W3SkillCooldownOnSpawn( thisRaceID, ULT_DUEL, 15.0, _);
    
    War3_CreateRaceEnd( thisRaceID );
}

public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace != thisRaceID )
    {
        War3_WeaponRestrictTo( client, thisRaceID, "" );
        W3ResetAllBuffRace( client, thisRaceID );
    }
    else
    {
        War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_deagle" );
        if( ValidPlayer( client,true ) )
        {
            Client_RemoveWeapon(client, "weapon_deagle");
            GivePlayerItem( client, "weapon_deagle" );
            GivePlayerItem( client, "weapon_knife" );
        }
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        War3_WeaponRestrictTo( client, thisRaceID, "weapon_deagle,weapon_knife" );
        //StripWeaponFromClient( client );
        Client_RemoveWeapon(client, "weapon_deagle");
        GivePlayerItem( client, "weapon_deagle" );
    }
    else
    {
        War3_WeaponRestrictTo( client, thisRaceID, "" );
        W3ResetAllBuffRace( client, thisRaceID );
    }
    bClientInDuel[client] = false;
    W3SetPlayerColor( client, thisRaceID, 255, 255, 255, _, GLOW_DEFAULT );
}

public OnWar3EventDeath( victim, attacker )
{
    
    W3ResetAllBuffRace( victim, thisRaceID );
    new bool:DuelEnd = false;
    if( bClientInDuel[victim] )
    {
        if( bDuelActivated[victim])
        {
            if (bClientInDuel[attacker])
            {
                if (War3_GetRace( victim ) == thisRaceID)    
                {
                    War3_WeaponRestrictTo( victim, thisRaceID, "weapon_deagle,weapon_knife" );
                    War3_WeaponRestrictTo( attacker, thisRaceID, "");
                    DuelEnd = true;
                    bDuelActivated[victim] = false;
                    if (hDuelTimer[victim] != INVALID_HANDLE)
                    {
                        CloseHandle(hDuelTimer[victim]);
                        hDuelTimer[victim] = INVALID_HANDLE;
                    }
                }
                else
                {
                    // SOMETHING HAS GONE WRONG! THIS SHOULD NOT HAPPEN
                    // the boolean bDuelActivated should only be true for the initiator of the duel, yet this victim is not a dean!
                    new String:shortname[SHORTNAMELEN];
                    War3_GetRaceShortname(victim, shortname, sizeof(shortname));

                    LogError("Something went wrong with Dean - ERROR 1 - Victim = |%s| race", shortname);
                }        
            }
            else
            {
                // SOMETHING HAS GONE WRONG! THIS SHOULD NOT HAPPEN
                // Somehow this dean was killed by someone who was not in a duel!
                new String:shortname[SHORTNAMELEN];
                War3_GetRaceShortname(attacker, shortname, sizeof(shortname));
                LogError("Something went wrong with Dean - ERROR 2 - Attacker = |%s| race", shortname);
            }
        }
        else if (bDuelActivated[ClientTarget[victim]])
        {
            War3_WeaponRestrictTo( attacker, thisRaceID, "weapon_deagle,weapon_knife" );
            War3_WeaponRestrictTo( victim, thisRaceID, "");
            DuelEnd = true;
            bDuelActivated[ClientTarget[victim]] = false;
            War3_CooldownMGR( ClientTarget[victim], 25.0, thisRaceID, ULT_DUEL);
            if (hDuelTimer[ClientTarget[victim]] != INVALID_HANDLE)
            {
                CloseHandle(hDuelTimer[ClientTarget[victim]]);
                hDuelTimer[ClientTarget[victim]] = INVALID_HANDLE;
            }
        }
        else
        {
            // SOMETHING HAS GONE WRONG! THIS SHOULD NOT HAPPEN
            // The victim was "in duel" - but neither the victim nor the attacker where the activating dean
            new String:shortname[SHORTNAMELEN];
            new String:shortname2[SHORTNAMELEN];
            War3_GetRaceShortname(attacker, shortname, sizeof(shortname));
            War3_GetRaceShortname(victim, shortname2, sizeof(shortname2));
            LogError("Something went wrong with Dean - ERROR 3 - Attacker = |%s|, Victim = |%s|", shortname, shortname2);
        }
        
        if (DuelEnd)
        {
        
            W3SetPlayerColor( ClientTarget[victim], thisRaceID, 255, 255, 255, _, GLOW_DEFAULT );
            W3SetPlayerColor( victim, thisRaceID, 255, 255, 255, _, GLOW_DEFAULT );
            
            bClientInDuel[ClientTarget[victim]] = false;
            bClientInDuel[victim] = false;
            
            ClientTarget[ClientTarget[victim]] = 0;
            ClientTarget[victim] = 0;
            
            new String:ClientName[32];
            
            GetClientName( attacker, ClientName, 32 );
            
            PrintCenterTextAll( "!.:%s WiN:.!", ClientName );
            
            W3GiveXPGold(attacker,XPAwardByWin,0,2,"winning your duel!");
            
            
            //ServerCommand( "sm_beacon #%d", GetClientUserId( attacker ) );
            
        }
        else
        {
            // SOMETHING HAS GONE WRONG! THIS SHOULD NOT HAPPEN
            // The victim was in a duel, but something else happened so the duel didn't finish properly
            LogError("Something went wrong with Dean - ERROR 4 - See other errors");
        }
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_colt = War3_GetSkillLevel( attacker, thisRaceID, SKILL_COLT );
            if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.15 )
            {
                if( !W3HasImmunity( victim, Immunity_Skills ) )
                {
                    War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_colt] ), attacker, DMG_BULLET, "weapon_colt" );
                
                    W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_COLT );
                    
                    new Float:pos[3];
                    
                    GetClientAbsOrigin( victim, pos );
                    
                    pos[2] += 15;
                    
                    TE_SetupGlowSprite( pos, PhysRingSprite, 3.0, 2.0, 255 );
                    TE_SendToAll();
                }
            }
        }
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_water = War3_GetSkillLevel( attacker, thisRaceID, SKILL_WATER );
            if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= WaterChance[skill_water] )
            {
                if( !W3HasImmunity( victim, Immunity_Skills ) )
                {
                    new Float:pos[3];
                    
                    GetClientAbsOrigin( victim, pos );
                    
                    TE_SetupGlowSprite( pos, FunnelSprite, 3.0, 5.0, 255 );
                    TE_SendToAll();
                    
                    W3FlashScreen( victim, { 215, 25, 251, 75 }, 0.3, 0.3 );
                    
                    EmitSoundToAll( WaterSound, attacker );
                    EmitSoundToAll( WaterSound, victim );
                    
                    SetEntData( victim, m_iFOV, 500 );
                    CreateTimer( 0.1, StopFov, victim );
                }
            }
        }
    }
}

public Action:StopFov( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        SetEntData( client, m_iFOV, 0 );
    }
}

public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    if( War3_GetRace( client ) == thisRaceID && client != 0 )
    {
        new skill_spawn = War3_GetSkillLevel( client, thisRaceID, SKILL_RESP );
        if( skill_spawn > 0 && GetRandomFloat( 0.0, 1.0 ) <= SpawnChance[skill_spawn] )
        {
            new Float:pos[3];
            
            GetClientAbsOrigin( client, death_pos[client] );
            GetClientAbsOrigin( client, pos );
            
            CreateTimer( 2.0, Spawn, client );
            CreateTimer( 2.1, Teleport, client );
        }
    }
}

public RoundEndEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new bool:PrintMessageOnce = false;
    for(new i=1;i<=MaxClients;i++)
    {
        if (bClientInDuel[i] == true)
        {
            bDuelActivated[i] = false;
            bClientInDuel[i] = false;
            ClientTarget[i] = 0;
            W3SetPlayerColor( i, thisRaceID, 255, 255, 255, _, GLOW_DEFAULT );
            if(War3_GetRace( i ) != thisRaceID)
            {
                War3_WeaponRestrictTo( i, thisRaceID, "");
            }
            if (hDuelTimer[i] != INVALID_HANDLE)
            {
                CloseHandle(hDuelTimer[i]);
                hDuelTimer[i] = INVALID_HANDLE;
            }
            if (PrintMessageOnce == false)
            {
                PrintCenterTextAll( "!REMAINING DUELS: DRAW!");
                PrintMessageOnce = true;
            }
        }
    }
    
}


public Action:Spawn( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        War3_SpawnPlayer( client );
        PrintToChat( client, "\x05: \x03You have ecaped from \x04Hell!" );
    }
}

public Action:Teleport( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        TeleportEntity( client, death_pos[client], NULL_VECTOR, NULL_VECTOR );
    }
}

public OnW3TakeDmgBulletPre( victim, attacker, Float:damage )
{
    if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
    {
        new vteam = GetClientTeam( victim );
        new ateam = GetClientTeam( attacker );
        if( vteam != ateam )
        {
            new race_victim = War3_GetRace( victim );
            new skill_level = War3_GetSkillLevel( victim, thisRaceID, SKILL_EVADE );
            if( race_victim == thisRaceID && skill_level > 0 && GetRandomFloat( 0.0, 1.0 ) <= EvadeChance[skill_level] )
            {
                if( !W3HasImmunity( attacker, Immunity_Skills ) )
                {
                    War3_DamageModPercent( 0.0 );
                    W3Hint(victim, HINT_SKILL_STATUS, 1.0, "%T", "You Evaded a Shot", victim);
                    W3Hint(attacker, HINT_SKILL_STATUS, 1.0, "%T", "Enemy Evaded", attacker);
                    
                    new Float:pos[3];
                    
                    GetClientAbsOrigin( victim, pos );
                    
                    pos[2] += 15;
                    
                    TE_SetupGlowSprite( pos, PupilSprite, 3.0, 3.0, 255 );
                    TE_SendToAll();
                }
                else
                {
                    W3MsgEnemyHasImmunity( victim, true );
                }
            }
        }
    }
}

public OnW3TakeDmgAllPre( victim, attacker, Float:damage )
{
    if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
    {
        new vteam = GetClientTeam( victim );
        new ateam = GetClientTeam( attacker );
        if( vteam != ateam )
        {
            if( bClientInDuel[victim] || bClientInDuel[attacker] )
            {
                if (ClientTarget[victim] != attacker)
                {
                    War3_DamageModPercent( 0.0 );
                }
            }
        }
    }
}

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_DUEL );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_DUEL, true ) )
            {
                if( !bDuelActivated[client] )
                {
                    Duel( client );
                }
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}

stock Duel( Dean_Player )
{
    ClientTarget[Dean_Player] = 0;
    
    if( GetClientTeam( Dean_Player ) == TEAM_T )
        ClientTarget[Dean_Player] = War3_GetRandomPlayer( Dean_Player, "#ct", true, false );
    if( GetClientTeam( Dean_Player ) == TEAM_CT )
        ClientTarget[Dean_Player] = War3_GetRandomPlayer( Dean_Player,  "#t", true, false );
        
    new String:temp[200];
    War3_GetWeaponRestriction ( ClientTarget[Dean_Player], War3_GetRace( ClientTarget[Dean_Player] ), temp, 200);
    
    if( ClientTarget[Dean_Player] == 0 )
    {
        PrintHintText( Dean_Player, "No Target Found" );
    }
    else if (strcmp(temp, "", false))
    {
        new String:name[64];
        GetClientName(ClientTarget[Dean_Player],name,64);
        PrintHintText( Dean_Player, "Target (%s) has |%s| weapons restrictions - can't duel.", name, temp );
    }
    else if (W3HasImmunity(ClientTarget[Dean_Player],Immunity_Ultimates))
    {
        new String:name[64];
        GetClientName(ClientTarget[Dean_Player],name,64);
        PrintHintText( Dean_Player, "Target (%s) has ultimate immunity - can't duel.", name );
    }
    
    else
    {
        bDuelActivated[Dean_Player] = true;
        new target = ClientTarget[Dean_Player];
        ClientTarget[target] = Dean_Player;
        bClientInDuel[target] = true;
        bClientInDuel[Dean_Player] = true;
        
        new String:ClientTargetName[32];
        new String:ClientName[32];
        
        GetClientName( target, ClientTargetName, 32 );
        GetClientName( Dean_Player, ClientName, 32 );
        
        // SetEntityHealth( target, 100 );
        // SetEntityHealth( client, 100 );
        
        PrintToChat( target, "\x05: \x04%s \x03has challenged you to a duel \x04Fight in 3 seconds", ClientName );
        PrintToChat( Dean_Player, "\x05: \x03You have Challenged \x04%s \x03to a Duel", ClientTargetName );
        
        //StripWeaponFromClient( target );
        //StripWeaponFromClient( client );
        
        War3_WeaponRestrictTo( target, thisRaceID, "weapon_knife", 2 );
        War3_WeaponRestrictTo( Dean_Player, thisRaceID, "weapon_knife", 2 );
        
        PrintCenterTextAll( "!%s .:vs:. %s!", ClientName, ClientTargetName );
        
        W3SetPlayerColor( target, thisRaceID, 0, 0, 0, _, GLOW_DEFAULT);
        W3SetPlayerColor( Dean_Player, thisRaceID, 0, 0, 0, _, GLOW_DEFAULT );
        
        CreateTimer( 3.0, Print3, Dean_Player );
        CreateTimer( 4.0, Print2, Dean_Player );
        CreateTimer( 5.0, Print1, Dean_Player );
        CreateTimer( 6.0, GiveDeagle, Dean_Player );
        //ServerCommand( "sm_beacon #%d", GetClientUserId( client ) );
        //ServerCommand( "sm_beacon #%d", GetClientUserId( target ) );
        
        hDuelTimer[Dean_Player] = CreateTimer( 45.0, DrawDuel, Dean_Player );
        
        
    }
}

public Action:Print3( Handle:timer, any:client )
{
    PrintCenterTextAll( "3" );
}

public Action:Print2( Handle:timer, any:client )
{
    PrintCenterTextAll( "2" );
}

public Action:Print1( Handle:timer, any:client )
{
    PrintCenterTextAll( "1" );
}

public Action:GiveDeagle( Handle:timer, any:client )
{
    
    if( ValidPlayer( ClientTarget[client], true ) )
    {
        War3_WeaponRestrictTo( ClientTarget[client], thisRaceID, "weapon_deagle,weapon_knife", 2 );
        GivePlayerItem( ClientTarget[client], "weapon_deagle" );
        GivePlayerItem( ClientTarget[client], "weapon_knife" );
    }
    
    if( ValidPlayer( client, true ) )
    {
        War3_WeaponRestrictTo( client, thisRaceID, "weapon_deagle,weapon_knife", 2 );
        GivePlayerItem( client, "weapon_deagle" );
        GivePlayerItem( client, "weapon_knife" );
    }
    
    PrintCenterTextAll( ".:FighT:." );
}

public Action:DrawDuel( Handle:timer, any:Dean_Player )
{
    new String:ClientTargetName[32];
    new String:ClientName[32];
    
    GetClientName( ClientTarget[Dean_Player], ClientTargetName, 32 );
    GetClientName( Dean_Player, ClientName, 32 );

    PrintCenterTextAll( "!%s .:vs:. %s will end in: 5!", ClientName, ClientTargetName );
    hDuelTimer[Dean_Player] = CreateTimer( 5.0, DrawDuel2, Dean_Player );
}

public Action:DrawDuel2( Handle:timer, any:Dean_Player )
{
    if (ValidPlayer(Dean_Player, true) && ValidPlayer(ClientTarget[Dean_Player], true))
    {
        new target = ClientTarget[Dean_Player];
        new String:ClientTargetName[32];
        new String:ClientName[32];
        
        GetClientName( ClientTarget[Dean_Player], ClientTargetName, 32 );
        GetClientName( Dean_Player, ClientName, 32 );
    
        PrintCenterTextAll( "!%s .:vs:. %s : DRAW!", ClientName, ClientTargetName );    
    
        bDuelActivated[Dean_Player] = false;
    
        bClientInDuel[Dean_Player] = false;
        bClientInDuel[target] = false;
        ClientTarget[Dean_Player] = 0;
        ClientTarget[target] = 0;
        W3SetPlayerColor( Dean_Player, thisRaceID, 255, 255, 255, _, GLOW_DEFAULT );
        W3SetPlayerColor( target, thisRaceID, 255, 255, 255, _, GLOW_DEFAULT );
        
        War3_WeaponRestrictTo( target, thisRaceID, "");
        
        hDuelTimer[Dean_Player] = INVALID_HANDLE;
    }
    else
    {
        // SOMETHING HAS GONE WRONG! THIS SHOULD NOT HAPPEN
        // Draw has been called, but one of the players is no longer valid or alive!
        LogError("Something went wrong with Dean - ERROR DRAW INCORRET");
    }
}


public PlayerDisconnectEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    
    if(bClientInDuel[client])
    {
        new winner = ClientTarget[client];
        if(bDuelActivated[client])
        {
            bDuelActivated[client] = false;
            if (hDuelTimer[client] != INVALID_HANDLE)
            {
                CloseHandle(hDuelTimer[client]);
                hDuelTimer[client] = INVALID_HANDLE;
            }
        }
        else if (bDuelActivated[winner])
        {
            bDuelActivated[winner] = false;
            if (hDuelTimer[winner] != INVALID_HANDLE)
            {
                CloseHandle(hDuelTimer[winner]);
                hDuelTimer[winner] = INVALID_HANDLE;
            }
        }
        else
        {
            // SOMETHING HAS GONE WRONG! THIS SHOULD NOT HAPPEN
            // Client is in duel, but neither he not target activated it ...
            LogError("Something went wrong with Dean - ERROR ON PLAYER QUIT 1");
        }
    
        new String:ClientName[32];
        
        GetClientName( winner, ClientName, 32 );
        PrintCenterTextAll( "!.:%s WiN By DeFaUlT:.!", ClientName );
        bClientInDuel[client] = false;
        bClientInDuel[winner] = false;
        ClientTarget[client] = 0;
        ClientTarget[winner] = 0;
        
        W3GiveXPGold(winner,XPAwardByWin,0,2,"winning your duel!");
        
        W3SetPlayerColor( winner, thisRaceID, 255, 255, 255, _, GLOW_DEFAULT );
        if(War3_GetRace( winner ) != thisRaceID)
        {
            War3_WeaponRestrictTo( winner, thisRaceID, "");
        }
    }        
}

public Action:far_sight(Handle:timer,any:a) {
    for(new client=1;client<=MaxClients;client++){
        if(ValidPlayer(client,true)&& bClientInDuel[client]){
            for(new target=1;target<=MaxClients;target++){
                if(ValidPlayer(target,true)){
                    new clientteam=GetClientTeam(client);    
                    new targetteam=GetClientTeam(target);    
                    if(clientteam!=targetteam ){
                        if(ClientTarget[client] == target ){
                            new Float:pos[3]; 
                            GetClientAbsOrigin(client,pos);
                            pos[2]+=30;
                            new Float:targpos[3];
                            GetClientAbsOrigin(target,targpos);
                            if (targetteam==2){
                                TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 2.0, 5.0, 10.0, 10, 10.0, {255,0,0,155}, 70); 
                                TE_SendToClient(client);
                                //targpos[2]+=10;
                                //TE_SetupBeamRingPoint(targpos,0.0,500.0,BeamSprite,HaloSprite,0,15,1.0,20.0,3.0,{255,0,0,255},20,0);
                                //TE_SendToAll();
                            }
                            if (targetteam==3){
                                TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 2.0, 5.0, 10.0, 10, 10.0, {0,0,255,155}, 70); 
                                TE_SendToClient(client);
                                //targpos[2]+=10;
                                //TE_SetupBeamRingPoint(targpos,0.0,500.0,BeamSprite,HaloSprite,0,15,1.0,20.0,3.0,{0,0,255,255},20,0);
                                //TE_SendToAll();
                            }
                        }
                    }
                }
            }
        }
    }
}

public Action:Event_BeginPlant( Handle:event, const String:name[], bool:dontBroadcast )
{
/*    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(bClientInDuel[client])
    {
        
        PrintHintText(client, "You can not plant the bomb while in a duel");
        return Plugin_Handled;
    }*/
    return Plugin_Continue;
}


public Action:Event_BombBeginDefuse( Handle:event, const String:name[], bool:dontBroadcast )
{
/*    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(bClientInDuel[client])
    {
        PrintHintText(client, "You can not defuse while in a duel");
        return Plugin_Handled;
    }*/
    return Plugin_Continue;
}
