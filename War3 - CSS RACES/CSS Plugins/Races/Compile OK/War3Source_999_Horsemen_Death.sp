/**
* File: War3Source_999_Horsemen_Death.sp
* Description: Death Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL1, SKILL2, SKILL3, SKILL4;

#define WEAPON_RESTRICT "weapon_knife,weapon_deagle"
#define WEAPON_GIVE "weapon_deagle"

public Plugin:myinfo = 
{
    name = "War3Source Race - Death [HORSEMEN]",
    author = "Remy Lebeau",
    description = "Death race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new Float:g_fDamage[] = { 0.0, 0.10, 0.15, 0.20, 0.25 };

//latch
new bool:bRound[66];
new BeingLatchedBy[66];
// Target getting killed
new LatchKilled[66];
new Float:LatchChanceArr[]={0.0,0.14,0.16,0.18,0.20};
new Float:LatchonDamageMin[]={0.0,3.0,4.0,5.0,6.0};
new Float:LatchonDamageMax[]={0.0,7.0,8.0,9.0,10.0};
new String:Fangsstr[]="npc/roller/mine/rmine_blades_out2.wav";

new Float:AuraDistance[]={0.0, 50.0, 100.0, 150.0, 200.0};
new AuraID;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Death - Black Horseman","horseman_death");
    
    SKILL1=War3_AddRaceSkill(thisRaceID,"Death's Weapon","Death carries a black sword.",false,4);
    SKILL2=War3_AddRaceSkill(thisRaceID,"Death's Speed","Death's horse - silent & fast.",false,4);
    SKILL3=War3_AddRaceSkill(thisRaceID,"Death's Knocking","Kill your attacker and respawn in their place.",false,4);
    SKILL4=War3_AddRaceSkill(thisRaceID,"Death's Presence","Blind aura",true,4);

    
    War3_CreateRaceEnd(thisRaceID);
    
    AuraID=W3RegisterChangingDistanceAura("death_blindwave", true);
    
    War3_AddSkillBuff(thisRaceID, SKILL2, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL1, fDamageModifier, g_fDamage);
    
}



public OnPluginStart()
{

    HookEvent("round_start",RoundStartEvent);
    
    
}


public OnMapStart()
{
    War3_PrecacheSound(Fangsstr);
    PrecacheModel("models/player/elis/gr/grimreaper.mdl");
    AddFileToDownloadsTable("materials/models/player/elis/gr/gr.vmt");
    AddFileToDownloadsTable("materials/models/player/elis/gr/gr.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/gr/gr_head.vmt");
    AddFileToDownloadsTable("materials/models/player/elis/gr/gr_head.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/gr/gr_head_NORMAL.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/gr/gr_NORMAL.vtf");
    AddFileToDownloadsTable("models/player/elis/gr/grimreaper.dx80.vtx");
    AddFileToDownloadsTable("models/player/elis/gr/grimreaper.dx90.vtx");
    AddFileToDownloadsTable("models/player/elis/gr/grimreaper.mdl");
    AddFileToDownloadsTable("models/player/elis/gr/grimreaper.phy");
    AddFileToDownloadsTable("models/player/elis/gr/grimreaper.sw.vtx");
    AddFileToDownloadsTable("models/player/elis/gr/grimreaper.vvd");

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
    CreateTimer( 1.0, GiveWep, client );
    SetEntityModel(client, "models/player/elis/gr/grimreaper.mdl");
    if (GetClientTeam(client) == TEAM_CT)
    {
        W3SetPlayerColor(client,thisRaceID,0,204,255,20,GLOW_SKILL);    
    }
    else
    {
        W3SetPlayerColor(client,thisRaceID,255,51,0,20,GLOW_SKILL);    
    }
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID )
    {
        if(ValidPlayer( client, true))
        {
            InitPassiveSkills( client );
        }
        new level=War3_GetSkillLevel(client,thisRaceID,SKILL4);
        if(level>0)
        {
            W3SetPlayerAura(AuraID,client,AuraDistance[level],level);
        }
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3RemovePlayerAura(AuraID,client);
        W3ResetPlayerColor(client,thisRaceID);
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



public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    
    if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
    {
        if(skill==SKILL4)
        {
            W3RemovePlayerAura(AuraID,client);
            if(newskilllevel>0)
            {
                W3SetPlayerAura(AuraID,client,AuraDistance[newskilllevel],newskilllevel);
            }
        }
    }
}


public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(aura==AuraID && ValidPlayer(client))
    {

        if(inAura)
        {

            if(!W3HasImmunity(client,Immunity_Ultimates) && ValidPlayer(client, true))
            {

                W3FlashScreen(client,{0,0,0,255},0.4,_,FFADE_STAYOUT);
            }
            else
            {

                W3FlashScreen(client,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));

            }
        }
        else
        {
            
            W3FlashScreen(client,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));
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

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i))
        {
            bRound[i]=false;
        }
    }
}


public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim)&&ValidPlayer(attacker))
    {
        W3FlashScreen(victim,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));
        new race = War3_GetRace(victim);
        decl skilllevel;
        if(race==thisRaceID)
        {
            skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL3);
            if(skilllevel>0&&GetRandomFloat(0.0,1.0)<=LatchChanceArr[skilllevel]&&!W3HasImmunity(attacker,Immunity_Skills)&&!Silenced(victim))
            {
                BeingLatchedBy[attacker]=victim;
                PrintHintText(attacker,"Death stalks you!");
                PrintHintText(victim,"Stalking your killer!");
                EmitSoundToAll(Fangsstr,attacker);
                EmitSoundToAll(Fangsstr,victim);
                CreateTimer(2.0,LatchDamageLoop,attacker);
                bRound[attacker]=true;
            }
        }
        new headcrabperson=BeingLatchedBy[victim];
        if(ValidPlayer( headcrabperson ))
        {
            if(War3_GetRace(headcrabperson)==thisRaceID && !IsPlayerAlive(headcrabperson)&&bRound[victim])
            {
                War3_ChatMessage( headcrabperson , "Your killer died, you get to respawn");
                LatchKilled[headcrabperson]=victim;
                CreateTimer(0.2,RespawnPlayer,headcrabperson);
            }
            BeingLatchedBy[victim]=0;
        }
    }
    
}


public Action:LatchDamageLoop(Handle:timer,any:client)
{
    if(ValidPlayer(client,true)&&ValidPlayer(BeingLatchedBy[client])&&!W3HasImmunity(client,Immunity_Skills)&&bRound[client])
    {
        decl skill;
        skill=War3_GetSkillLevel(BeingLatchedBy[client],thisRaceID,SKILL3);
        War3_DealDamage(client,RoundFloat(GetRandomFloat(LatchonDamageMin[skill],LatchonDamageMax[skill])),BeingLatchedBy[client],_,"LatchOn",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_TRUEDMG);
        W3FlashScreen(client,RGBA_COLOR_RED, 0.5,0.5);
        PrintToConsole(client,"Recieved -%d Latchon dmg",War3_GetWar3DamageDealt());
        PrintToConsole(BeingLatchedBy[client],"Dealt -%d Latchon dmg",War3_GetWar3DamageDealt());
        CreateTimer(1.0,LatchDamageLoop,client);
    }
    else
    {
        BeingLatchedBy[client] = 0;
        bRound[client] = false;
    }
}


public Action:RespawnPlayer(Handle:timer,any:client)
{
    if(client>0&&!IsPlayerAlive(client)&&ValidPlayer(LatchKilled[client]))
    {
        War3_SpawnPlayer(client);
        new Float:pos[3];
        new Float:ang[3];
        War3_CachedAngle(LatchKilled[client],ang);
        War3_CachedPosition(LatchKilled[client],pos);
        TeleportEntity(client,pos,ang,NULL_VECTOR);
    }
}


/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/


public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, WEAPON_GIVE );
    }
}