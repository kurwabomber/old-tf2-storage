/**
* File: War3Source_999_GoldenEye.sp
* Description: Golden Eye Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_HEALTH, SKILL_RESPAWN, SKILL_MINES, ULT_INVIS;



public Plugin:myinfo = 
{
    name = "War3Source Race - Golden Eye",
    author = "Remy Lebeau",
    description = "Mufasa's private race for War3Source",
    version = "0.9.1",
    url = "http://sevensinsgaming.com"
};



new g_iHealth[] = {0, 50, 75, 100, 150 };

new g_iPlayerKills[MAXPLAYERS];
new Float:g_fRespawnChance[] = {0.0, 0.25, 0.50, 0.75, 1.0 };

//Stand Still INVIS
new bool:g_bInvisTrue[MAXPLAYERS];
new Float:g_fUltCooldown[] = {0.0, 25.0, 20.0, 15.0, 10.0};

new g_iTripMines[] = {0,1,2,3,5};


/***************************************************************************
*
*
*                TRIPMINE VARIABLES
*
*
***************************************************************************/

#define TRACE_START 24.0
#define TRACE_END 64.0

#define MDL_LASER "sprites/laser.vmt"

#define SND_MINEPUT "npc/roller/blade_cut.wav"
#define SND_MINEACT "npc/roller/mine/rmine_blades_in2.wav"

#define TEAM_T 2
#define TEAM_CT 3

#define COLOR_T "255 0 0"
#define COLOR_CT "0 0 255"
#define COLOR_DEF "0 255 255"

#define MAX_LINE_LEN 256

// globals
new gRemaining[MAXPLAYERS+1];    // how many tripmines player has this spawn
new gCount = 1;
new String:mdlMine[256];

new Handle:cvActTime = INVALID_HANDLE;
new Handle:cvModel = INVALID_HANDLE;

/***************************************************************************/




public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Golden Eye [PRIVATE]","goldeneye");
    
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"00-Agent","Increased health",false,4);
    SKILL_RESPAWN=War3_AddRaceSkill(thisRaceID,"You Only Live Twice","Get a kill before you die for a chance to respawn",false,4);
    SKILL_MINES=War3_AddRaceSkill(thisRaceID,"Proximity Mines","Deploy proximity mines (+ability)",false,4);
    ULT_INVIS=War3_AddRaceSkill(thisRaceID,"Stealth","Go fully invis - deactivates on move (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_INVIS,15.0,_);
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_RESPAWN,15.0,false);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, g_iHealth);

}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    
      // events
    HookEvent("player_death", PlayerDeath);
  
    // convars
    cvActTime = CreateConVar("war3_tripmines_activate_time", "2.0");
    cvModel = CreateConVar("war3_tripmines_model", "models/props_lab/tpplug.mdl");
    
}



public OnMapStart()
{
// set model based on cvar
  GetConVarString(cvModel, mdlMine, sizeof(mdlMine));
  
  // precache models
  PrecacheModel(mdlMine, true);
  PrecacheModel(MDL_LASER, true);
  
  // precache sounds
  PrecacheSound(SND_MINEPUT, true);
  PrecacheSound(SND_MINEACT, true);
  
}
  

public OnEventShutdown(){
    UnhookEvent("player_death", PlayerDeath);
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
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_p228");
        CreateTimer( 1.0, GiveWep, client );
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
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_p228");
        CreateTimer( 1.0, GiveWep, client );
        g_iPlayerKills[client] = 0;
        g_bInvisTrue[client] = false;
        gRemaining[client] = g_iTripMines[War3_GetSkillLevel(client,thisRaceID,SKILL_MINES)];
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
        new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_INVIS );
        if(ult_level>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_INVIS,true)) 
                {
                    PrintHintText(client, "You are now invisible until you move");
                    W3FlashScreen(client,RGBA_COLOR_BLUE, 0.5, 0.4, FFADE_OUT);
                    g_bInvisTrue[client] = true;
                    War3_SetBuff( client, bDisarm, thisRaceID, true  );
                    War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0  );
                    War3_SetBuff( client,bDoNotInvisWeapon,thisRaceID,false);
                }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
}



public OnAbilityCommand(client,ability,bool:pressed)
{
    if(!Silenced(client))
    {
        if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
        {
            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_MINES);
            if(skill_level>0)
            {
                                    
                // call SetMine if any remain in client's inventory
                if (gRemaining[client]>0) 
                {
                    SetMine(client);
                }
                else 
                {
                    PrintHintText(client, "You do not have any tripmines.");
                }

            }
            else
            {
                PrintHintText(client,"Level up ability");
            }
        }
    }
    else
    {
        PrintHintText(client,"Silenced: Can not cast");
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
    new skill_level = War3_GetSkillLevel(victim,thisRaceID,SKILL_RESPAWN);
    new race = War3_GetRace( attacker );
    if( race == thisRaceID && ValidPlayer( attacker, true ))
    {
        g_iPlayerKills[attacker] += 1;
    }
    race = War3_GetRace( victim );
    new bool:should_vengence=false;
    
    if(victim>0 && attacker>0 && attacker!=victim)
    {
        if(race==thisRaceID && skill_level>0 && War3_SkillNotInCooldown(victim,thisRaceID,SKILL_RESPAWN,false) )
        {
            if(ValidPlayer(attacker,true)&& W3HasImmunity(attacker,Immunity_Ultimates))
            {
                W3MsgSkillBlocked(attacker,_,"Respawn");
                W3MsgVengenceWasBlocked(victim,"attacker immunity");
            }
            else if (GetRandomFloat( 0.0, 1.0 ) <= (g_iPlayerKills[victim]*g_fRespawnChance[skill_level]))
            {
                should_vengence=true;
            }
        }
    }
    else if(victim>0)
    {
        if(race==thisRaceID && skill_level>0)
        {
            if(War3_SkillNotInCooldown(victim,thisRaceID,SKILL_RESPAWN,false) && GetRandomFloat( 0.0, 1.0 ) <= (g_iPlayerKills[victim]*g_fRespawnChance[skill_level]) )
            {
                
                should_vengence=true;
            }
            else{
                W3MsgVengenceWasBlocked(victim,"cooldown");
            }
        }
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
            CreateTimer(0.2,VengenceRespawn,victim);
        }
        else{
            W3MsgVengenceWasBlocked(victim,"last one alive");
        }
    }
}



public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    new race = War3_GetRace( attacker );
    if(ValidPlayer(victim, true) && ValidPlayer(attacker, true) && race == thisRaceID )
    {
        new victimTeam=GetClientTeam(victim);
        new attackerTeam=GetClientTeam(attacker);
        if(victimTeam == attackerTeam )
        {    
            War3_DamageModPercent(0.0);
            return;
        }
    }
    return;
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
        GivePlayerItem( client, "weapon_p228" );
        
    }
}


public Action:VengenceRespawn(Handle:t,any:client)
{

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
                
                
                //War3_ChatMessage(client,"%T","Revived by Vengence",client);
                PrintHintText(client, "You got enough kills! Respawned");
                War3_CooldownMGR(client,15.0,thisRaceID,SKILL_RESPAWN,false,true);
            }
        }
    }
    
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer (client, true))
    {
        if(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP) && g_bInvisTrue[client] == true)
        {
            PrintHintText(client, "You are visible again");
            W3FlashScreen(client,RGBA_COLOR_BLUE, 0.5, 0.4, FFADE_OUT);
            new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_INVIS );
            War3_CooldownMGR(client,g_fUltCooldown[ult_level],thisRaceID,ULT_INVIS);
            g_bInvisTrue[client] = false;
            War3_SetBuff( client, bDisarm, thisRaceID, false  );
            War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0  );
            War3_SetBuff( client,bDoNotInvisWeapon,thisRaceID,true);
        }
    }
    return Plugin_Continue;
}



/***************************************************************************
*
*
*                TRIPMINE FUNCTIONS - call "SetMine" to place a mine - need to monitor quantity levels.
*
*
***************************************************************************/

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
    new client;
    client = GetClientOfUserId(GetEventInt(event, "userid"));
    gRemaining[client] = 0;
}


SetMine(client)
{
  
    // setup unique target names for entities to be created with
    new String:beam[64];
    new String:beammdl[64];
    new String:tmp[128];
    Format(beam, sizeof(beam), "tmbeam%d", gCount);
    Format(beammdl, sizeof(beammdl), "tmbeammdl%d", gCount);
    gCount++;
    if (gCount>10000)
    {
    gCount = 1;
    }
    
    // trace client view to get position and angles for tripmine
    
    decl Float:start[3], Float:angle[3], Float:end[3], Float:normal[3], Float:beamend[3];
    GetClientEyePosition( client, start );
    GetClientEyeAngles( client, angle );
    GetAngleVectors(angle, end, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(end, end);
    
    start[0]=start[0]+end[0]*TRACE_START;
    start[1]=start[1]+end[1]*TRACE_START;
    start[2]=start[2]+end[2]*TRACE_START;
    
    end[0]=start[0]+end[0]*TRACE_END;
    end[1]=start[1]+end[1]*TRACE_END;
    end[2]=start[2]+end[2]*TRACE_END;
    
    TR_TraceRayFilter(start, end, CONTENTS_SOLID, RayType_EndPoint, FilterAll, 0);
    
    if (TR_DidHit(INVALID_HANDLE))
    {
        // update client's inventory
        gRemaining[client]-=1;
        
        // find angles for tripmine
        TR_GetEndPosition(end, INVALID_HANDLE);
        TR_GetPlaneNormal(INVALID_HANDLE, normal);
        GetVectorAngles(normal, normal);
        
        // trace laser beam
        TR_TraceRayFilter(end, normal, CONTENTS_SOLID, RayType_Infinite, FilterAll, 0);
        TR_GetEndPosition(beamend, INVALID_HANDLE);
        
        // create tripmine model
        new ent = CreateEntityByName("prop_physics_override");
        SetEntityModel(ent,mdlMine);
        DispatchKeyValue(ent, "StartDisabled", "false");
        DispatchSpawn(ent);
        TeleportEntity(ent, end, normal, NULL_VECTOR);
        SetEntProp(ent, Prop_Send, "m_usSolidFlags", 152);
        SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
        SetEntityMoveType(ent, MOVETYPE_NONE);
        //    SetEntProp(ent, Prop_Send, "m_MoveCollide", 0);
        SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
        SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
        DispatchKeyValue(ent, "targetname", beammdl);
        DispatchKeyValue(ent, "ExplodeRadius", "256");
        DispatchKeyValue(ent, "ExplodeDamage", "400");
        Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
        DispatchKeyValue(ent, "OnHealthChanged", tmp);
        Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", beam);
        DispatchKeyValue(ent, "OnBreak", tmp);
        SetEntProp(ent, Prop_Data, "m_takedamage", 2);
        AcceptEntityInput(ent, "Enable");
        HookSingleEntityOutput(ent, "OnBreak", mineBreak, true);
        
        
        // create laser beam
        ent = CreateEntityByName("env_beam");
        TeleportEntity(ent, beamend, NULL_VECTOR, NULL_VECTOR);
        SetEntityModel(ent, MDL_LASER);
        DispatchKeyValue(ent, "texture", MDL_LASER);
        DispatchKeyValue(ent, "targetname", beam);
        DispatchKeyValue(ent, "TouchType", "4");
        DispatchKeyValue(ent, "LightningStart", beam);
        DispatchKeyValue(ent, "BoltWidth", "4.0");
        DispatchKeyValue(ent, "life", "0");
        DispatchKeyValue(ent, "rendercolor", "0 0 0");
        DispatchKeyValue(ent, "renderamt", "0");
        DispatchKeyValue(ent, "HDRColorScale", "0.3");
        DispatchKeyValue(ent, "decalname", "Bigshot");
        DispatchKeyValue(ent, "StrikeTime", "0");
        DispatchKeyValue(ent, "TextureScroll", "35");
        Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
        DispatchKeyValue(ent, "OnTouchedByEntity", tmp);   
        SetEntPropVector(ent, Prop_Send, "m_vecEndPos", end);
        SetEntPropFloat(ent, Prop_Send, "m_fWidth", 4.0);
        AcceptEntityInput(ent, "TurnOff");
        
        new Handle:data = CreateDataPack();
        CreateTimer(GetConVarFloat(cvActTime), TurnBeamOn, data);
        WritePackCell(data, client);
        WritePackCell(data, ent);
        WritePackFloat(data, end[0]);
        WritePackFloat(data, end[1]);
        WritePackFloat(data, end[2]);
        
        // play sound
        EmitSoundToAll(SND_MINEPUT, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);
        
        // send message
        PrintHintText(client, "Tripmines remaining: %d", gRemaining[client]);
    }
    else
    {
        PrintHintText(client, "Invalid location for Tripmine");
    }
}

public Action:TurnBeamOn(Handle:timer, Handle:data)
{
    decl String:color[26];
    
    ResetPack(data);
    new client = ReadPackCell(data);
    new ent = ReadPackCell(data);
    
    if (IsValidEntity(ent))
    {
        new team = GetClientTeam(client);
        if(team == TEAM_T) color = COLOR_T;
        else if(team == TEAM_CT) color = COLOR_CT;
        else color = COLOR_DEF;
        
        DispatchKeyValue(ent, "rendercolor", color);
        AcceptEntityInput(ent, "TurnOn");
        
        new Float:end[3];
        end[0] = ReadPackFloat(data);
        end[1] = ReadPackFloat(data);
        end[2] = ReadPackFloat(data);
        
        EmitSoundToAll(SND_MINEACT, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);
    }

    CloseHandle(data);
}

public mineBreak (const String:output[], caller, activator, Float:delay)
{
    UnhookSingleEntityOutput(caller, "OnBreak", mineBreak);
    AcceptEntityInput(caller,"kill");
}

public bool:FilterAll (entity, contentsMask)
{
    return false;
}


