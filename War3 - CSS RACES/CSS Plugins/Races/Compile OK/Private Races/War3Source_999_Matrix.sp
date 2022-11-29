/**
* File: War3Source_999_Matrix.sp
* Description: Neo and Agent Smith Races for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/remyfunctions"

new neoRaceID, smithRaceID;
new SKILL_NEO1, SKILL_NEO2, SKILL_NEO3, ULT_NEO;
new SKILL_SMITH1, SKILL_SMITH2, SKILL_SMITH3, ULT_SMITH;




public Plugin:myinfo = 
{
    name = "War3Source Races - Maxtrix - Neo & Smith",
    author = "Remy Lebeau",
    description = "2 Races in one that can swap between.  Kanon's races",
    version = "0.9",
    url = "http://sevensinsgaming.com"
};

new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4};
new Float:g_fEvade[] = { 0.0, 0.05, 0.10, 0.15, 0.20, 0.25 };
new Float:g_fDamageBoost[] = { 0.0, 0.10, 0.15, 0.175, 0.2 };


// Neo's Fly
new m_vecBaseVelocity;
new  FreezeSprite1;
new String:ult_sound[] = "weapons/357/357_spin1.wav";
new Float:PushForce[] = { 0.0, 1.0, 1.1, 1.2, 1.25 };

// Smith Transform
new Float:TransformDuration[5] = { 0.0, 5.0, 10.0, 15.0, 20.0 };
//new String:TransformSound[]="war3source/butcher/taunt_after.mp3";
new Handle:TransformTimer[MAXPLAYERS];

// Smith Respawn
new Float:respawn_cooldown = 20.0;
new MyWeaponsOffset,AmmoOffset;


public OnWar3PluginReady()
{
    neoRaceID=War3_CreateNewRace("Neo [PRIVATE]","matrix_neo");
    
    SKILL_NEO1=War3_AddRaceSkill(neoRaceID,"Evade","Neo knows how to dodge bullets",false,4);
    SKILL_NEO2=War3_AddRaceSkill(neoRaceID,"Speed","Neo travels at amazing speeds",false,4);
    SKILL_NEO3=War3_AddRaceSkill(neoRaceID,"Sling","Neo can fly at great speeds ",false,4);
    ULT_NEO=War3_AddRaceSkill(neoRaceID,"Transform into Agent Smith","You look surprised to see me, again, Mr. Anderson (+ultimate)",true,1);
 
    W3SkillCooldownOnSpawn( neoRaceID, SKILL_NEO3, 10.0 );
    W3SkillCooldownOnSpawn( neoRaceID, ULT_NEO, 10.0 );
    
    War3_CreateRaceEnd(neoRaceID);
    
    War3_AddSkillBuff(neoRaceID, SKILL_NEO1, fDodgeChance, g_fEvade);
    War3_AddSkillBuff(neoRaceID, SKILL_NEO2, fMaxSpeed, g_fSpeed);
  
    
    smithRaceID=War3_CreateNewRace("Agent Smith [PRIVATE]","matrix_smith");
    
    SKILL_SMITH1=War3_AddRaceSkill(smithRaceID,"Disguise","Smith possess the ability to take control over any human (+ability).",false,4);
    SKILL_SMITH2=War3_AddRaceSkill(smithRaceID,"Damage","Smith has strength beyond ordinary humans",false,4);
    SKILL_SMITH3=War3_AddRaceSkill(smithRaceID,"Me, me and me, me too","Chance of respawning after death",false,4);
    ULT_SMITH=War3_AddRaceSkill(smithRaceID,"Transform into Neo","But we control these machines; they don’t control us (+ultimate)",true,1);
   
    W3SkillCooldownOnSpawn( smithRaceID, SKILL_SMITH1, 10.0 );
    W3SkillCooldownOnSpawn( smithRaceID, ULT_SMITH, 10.0 );
   
    War3_CreateRaceEnd(smithRaceID);
    
    War3_AddSkillBuff(smithRaceID, SKILL_SMITH2, fDamageModifier, g_fDamageBoost);
    
}



public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
    AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
    
}



public OnMapStart()
{
    //War3_AddCustomSound( TransformSound );
    War3_PrecacheSound( ult_sound );
    FreezeSprite1 = PrecacheModel( "materials/effects/combineshield/comshieldwall.vmt" );
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
    if( newrace == neoRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
        W3ResetAllBuffRace( client, smithRaceID );
    }
    else if (newrace == smithRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
        W3ResetAllBuffRace( client, neoRaceID );
    }
    else
    {
        W3ResetAllBuffRace( client, neoRaceID );
        W3ResetAllBuffRace( client, smithRaceID );
    }
}

public OnWar3EventSpawn( client )
{

    //new race = War3_GetRace( client );
    if (ValidPlayer(client, true))
    {
       /* if( race == minotaurRaceID || race == sacredRaceID )
        {

        }*/
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
    if( race == neoRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_ = War3_GetSkillLevel( client, neoRaceID, ULT_NEO );
        if(skill_>0)
        {
            if(War3_SkillNotInCooldown(client,neoRaceID, ULT_NEO,true)) // USE SAME COOLDOWN FOR BOTH RACES.
            {
                if (TransformTimer[client] != INVALID_HANDLE)
                {
                    KillTimer(TransformTimer[client]);
                    TransformTimer[client] = INVALID_HANDLE;
                }
                War3_ChangeModel( client, false);
                W3FlashScreen( client, RGBA_COLOR_BLUE );
                War3_ShakeScreen(client);
                PrintHintText(client, "You're in the Matrix!  You are now SMITH.");
                W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
                W3SetPlayerProp(client,RaceSetByAdmin,true);
                War3_SetRace(client,smithRaceID);
                War3_SetBuff( client, bDisarm, neoRaceID,true);
                War3_CooldownMGR( client, 10.0, neoRaceID, ULT_NEO );
                
                CreateTimer(1.0,Fire,client);
            }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
    else if( race == smithRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_ = War3_GetSkillLevel( client, smithRaceID, ULT_SMITH );
        if(skill_>0)
        {
            if(War3_SkillNotInCooldown(client,neoRaceID, ULT_NEO,true)) // USE SAME COOLDOWN FOR BOTH RACES.
            {
                if (TransformTimer[client] != INVALID_HANDLE)
                {
                    KillTimer(TransformTimer[client]);
                    TransformTimer[client] = INVALID_HANDLE;
                }
                War3_ChangeModel( client, false);
                W3FlashScreen( client, RGBA_COLOR_BLUE );
                War3_ShakeScreen(client);
                PrintHintText(client, "You're out of the Matrix!  You are now NEO.");
                W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
                W3SetPlayerProp(client,RaceSetByAdmin,true);
                War3_SetRace(client,neoRaceID);
                War3_SetBuff( client, bDisarm, neoRaceID,true);
                War3_CooldownMGR( client, 10.0, neoRaceID, ULT_NEO );
                CreateTimer(1.0,Fire,client);
            }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
}


public Action:Fire(Handle:t,any:client)
{
    if(ValidPlayer(client))
    {
        War3_SetBuff( client, bDisarm, neoRaceID,false);
    }
}


public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==neoRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            if(ability==0 && pressed)
            {
                new skill=War3_GetSkillLevel(client,neoRaceID,SKILL_NEO3);
                if(skill>0)
                {      
                    if(War3_SkillNotInCooldown( client, neoRaceID, SKILL_NEO3, true ))
                    {
                        TeleportPlayer( client );
                        EmitSoundToAll( ult_sound, client );
                        War3_CooldownMGR( client, 10.0, neoRaceID, SKILL_NEO3 );
                    }
                }
                else
                {
                    PrintHintText(client, "Level Invis first");
                }
                
            }
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
        }
    }
    
    if (War3_GetRace(client)==smithRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            if(ability==0 && pressed)
            {
                new skill=War3_GetSkillLevel(client,smithRaceID,SKILL_SMITH1);
                if(skill>0)
                {      
                    if(War3_SkillNotInCooldown( client, neoRaceID, SKILL_SMITH1, true ))
                    {
                        War3_ChangeModel( client, true);
                        //EmitSoundToAll( TransformSound, client );
                        TransformTimer[client] = CreateTimer( TransformDuration[skill], StopTransform, client );
                        PrintHintText( client, "You take on the appearance of a human." );
                        War3_CooldownMGR( client, TransformDuration[skill]+20.0, neoRaceID, SKILL_SMITH1 );
                    }
                }
                else
                {
                    PrintHintText(client, "Level Invis first");
                }
                
            }
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
        }
    }
    
}



public Action:StopTransform ( Handle:timer, any:client )
{
    if (ValidPlayer(client, true))
    {
        if(TransformTimer[client] != INVALID_HANDLE)
        {
            //EmitSoundToAll( TransformSound, client );
            War3_ChangeModel( client, false);
            PrintHintText( client, "You transform back to your normal form" );
            TransformTimer[client] = INVALID_HANDLE;
        }
    }    
}

stock TeleportPlayer( client )
{
    if( client > 0 && ValidPlayer( client,true ) )
    {
        new ult_level = War3_GetSkillLevel( client, neoRaceID, SKILL_NEO3 );
        new Float:startpos[3];
        new Float:endpos[3];
        new Float:localvector[3];
        new Float:velocity[3];
        
        GetClientAbsOrigin( client, startpos );
        War3_GetAimTraceMaxLen(client, endpos, 2500.0);
        
        localvector[0] = endpos[0] - startpos[0];
        localvector[1] = endpos[1] - startpos[1];
        localvector[2] = endpos[2] - startpos[2];
        
        velocity[0] = localvector[0] * PushForce[ult_level];
        velocity[1] = localvector[1] * PushForce[ult_level];
        velocity[2] = localvector[2] * PushForce[ult_level];
        
        SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
        
        TE_SetupBeamPoints( startpos, endpos, FreezeSprite1, FreezeSprite1, 0, 0, 1.0, 1.0, 1.0, 0, 0.0, { 255, 14, 41, 255 }, 0 );
        TE_SendToAll();
        
        TE_SetupBeamRingPoint( endpos, 11.0, 9.0, FreezeSprite1, FreezeSprite1, 0, 0, 2.0, 13.0, 0.0, { 255, 100, 100, 255 }, 0, FBEAM_ISACTIVE );
        TE_SendToAll();
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
    new bool:should_vengence=false;    
    
    if(victim>0 && attacker>0 && attacker!=victim)
    {
        if(W3GetVar(DeathRace)==smithRaceID && War3_GetSkillLevel(victim,smithRaceID,SKILL_SMITH3)>0 && War3_SkillNotInCooldown(victim,smithRaceID,SKILL_SMITH3,false) )
        {
            if(ValidPlayer(attacker,true)&&W3HasImmunity(attacker,Immunity_Ultimates))
            {
                W3MsgSkillBlocked(attacker,_,"Vengence");
                W3MsgVengenceWasBlocked(victim,"attacker immunity");
            }
            else
            {
                should_vengence=true;
            }
        }
    }
    else if(victim>0)
    {
        if(War3_GetRace(victim)==smithRaceID && War3_GetSkillLevel(victim,smithRaceID,SKILL_SMITH3)>0)
        {
            if(War3_SkillNotInCooldown(victim,smithRaceID,SKILL_SMITH3,false) )
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
            CreateTimer(0.2,VengenceRespawn,GetClientUserId(victim));
        }
        else{
            W3MsgVengenceWasBlocked(victim,"last one alive");
        }
    }
}


public Action:VengenceRespawn(Handle:t,any:userid)
{

    new client=GetClientOfUserId(userid);
    if(client>0 && War3_GetRace(client)==smithRaceID) //did he become alive?
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
                W3MsgVengenceWasBlocked(client,"last player dead or round end");
            }
            else
            {
                War3_SpawnPlayer(client);
                GiveDeathWeapons(client);
                War3_ShakeScreen(client);
                //new ult_level=War3_GetSkillLevel(client,smithRaceID,SKILL_SMITH3);
                War3_CooldownMGR(client,respawn_cooldown,smithRaceID,SKILL_SMITH3,false,true);
            }
        }
    }
    
}


public GiveDeathWeapons(client)
{

    if(client>0)
    {

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


/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/
/*
public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}*/

/*
static bool:IsBrother(brother1, brother2, bool:CheckUlt=false)
{
    new searchRaceID;
    new UltBool = true;
    new clientRaceID = War3_GetRace( brother1 );
    
    if (clientRaceID == minotaurRaceID)
    {
        searchRaceID = sacredRaceID;
    }
    else if (clientRaceID == sacredRaceID)
    {
        searchRaceID = minotaurRaceID;
    }
    else
    {
        return false;
    }
    if (CheckUlt==true)
    {
        if (g_bUltActive[brother1] == true && g_bUltActive[brother2] == true)
        {
            UltBool = true;
        }
        else
        {
            UltBool = false;
        }
    }
    
    if (War3_GetRace( brother2 ) == searchRaceID && ValidPlayer(brother1, true) && ValidPlayer(brother2, true)&& GetClientTeam( brother1 ) != GetClientTeam( brother2 ) && UltBool)
    {
        
        return true;
    }
    else
    {
        return false;
    }
}

static TurnEverythingOff(client)
{
    if (ValidPlayer(client))
    {
        g_bUltActive[client] = false;
        g_bSkillActive[client] = false;
        W3ResetAllBuffRace( client, minotaurRaceID );
        W3ResetAllBuffRace( client, sacredRaceID );
    }    
}*/