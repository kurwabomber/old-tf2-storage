/**
* File: War3Source_999_Venom.sp
* Description: Venom Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_INVIS, SKILL_DAMAGE, SKILL_HEALTH, ULT_WEB;

#define WEAPON_RESTRICT "weapon_knife,weapon_deagle"
#define WEAPON_GIVE "weapon_deagle"

public Plugin:myinfo = 
{
    name = "War3Source Race - Venom",
    author = "Remy Lebeau",
    description = "Venom race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new Float:g_fInvis[] = { 1.0, 0.8, 0.75, 0.7, 0.65 };
new Float:g_fDamage[] = { 0.0, 0.075, 0.10, 0.125, 0.15 };
new g_iMaxHealth = 50 ;

//Cannibalize
new String:Nom[]="war3source/nomnom.mp3";
new Float:corpselocation[3][MAXPLAYERS][20];
new dietimes[MAXPLAYERS];
new cannibal[]={0,3,4,5,6};
new corpsehealth[MAXPLAYERS][40];
new bool:corpsedied[MAXPLAYERS][40];
new BeamSprite,HaloSprite;


// Ult
new m_vecBaseVelocity;
new  FreezeSprite1;
new String:ult_sound[] = "weapons/357/357_spin1.wav";
new Float:PushForce[5] = { 0.0, 1.0, 1.1, 1.2, 1.25 };

//new String:g_sPlayerModel[] = "models/player/slow/jamis/venom_wos/slow_v2.mdl";

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Venom [SSG-DONATOR]","venom");
    
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Shape Shift","Gain camouflage (passive invis).",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Eddie Brock","Massive muscles means more damage.",false,4);
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Mac Gargan","Regain HP feasting on flesh",false,4);
    ULT_WEB=War3_AddRaceSkill(thisRaceID,"Web Sling","Catches bad guys my a** (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn( thisRaceID, ULT_WEB, 10.0 );
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamage);    
    War3_AddSkillBuff(thisRaceID, SKILL_INVIS, fInvisibilitySkill, g_fInvis);
    
}



public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    HookEvent("round_start",RoundStartEvent);
    CreateTimer(0.5,nomnomnom,_,TIMER_REPEAT);
}



public OnMapStart()
{
    War3_AddCustomSound(Nom);
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    War3_PrecacheSound( ult_sound );
    FreezeSprite1 = PrecacheModel( "materials/effects/combineshield/comshieldwall.vmt" );
    
    
/*    PrecacheModel(g_sPlayerModel, true);
    
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_1.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_1.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_1_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_2.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_2.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/venom_wos/slow_2_bump.vtf");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.dx80.vtx");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.dx90.vtx");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.mdl");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.phy");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.sw.vtx");
    AddFileToDownloadsTable("models/player/slow/jamis/venom_wos/slow_v2.vvd");*/
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

    War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, g_iMaxHealth );
/*    SetEntityModel(client, g_sPlayerModel);
    
    if (GetClientTeam(client) == TEAM_T)
    {
        W3SetPlayerColor(client,thisRaceID,255,51,0,20,GLOW_SKILL);  
    }
    else
    {
        W3SetPlayerColor(client,thisRaceID,0,204,255,20,GLOW_SKILL);
    }*/
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






/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/



public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_WEB );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_WEB, true ) )
			{
				TeleportPlayer( client );
				EmitSoundToAll( ult_sound, client );
				War3_CooldownMGR( client, 15.0, thisRaceID, ULT_WEB );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}


stock TeleportPlayer( client )
{
	if( client > 0 && IsPlayerAlive( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_WEB );
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



/***************************************************************************
*
*
*               Cannibalize Functions
*
*
***************************************************************************/

public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim))
    {
        new deaths=dietimes[victim];
        dietimes[victim]++;
        corpsedied[victim][deaths]=true;
        corpsehealth[victim][deaths]=60;
        new Float:pos[3];
        War3_CachedPosition(victim,pos);
        corpselocation[0][victim][deaths]=pos[0];
        corpselocation[1][victim][deaths]=pos[1];
        corpselocation[2][victim][deaths]=pos[2];
        for(new client=0;client<=MaxClients;client++){
            if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
                TE_SetupBeamRingPoint(pos,25.0,75.0,BeamSprite,HaloSprite,0,15,6.0,20.0,3.0,{100,100,150,255},20,0);
                TE_SendToClient(client);
            }
        }
    }
}

public Action:nomnomnom(Handle:timer)
{
    for(new client=0;client<=MaxClients;client++){
        if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALTH);
            if(skill_level>0){
                for(new corpse=0;corpse<=MaxClients;corpse++){
                    for(new deaths=0;deaths<=19;deaths++){
                        if(corpsedied[corpse][deaths]==true){
                            new Float:corpsepos[3];
                            new Float:clientpos[3];
                            GetClientAbsOrigin(client,clientpos);
                            corpsepos[0]=corpselocation[0][corpse][deaths];
                            corpsepos[1]=corpselocation[1][corpse][deaths];
                            corpsepos[2]=corpselocation[2][corpse][deaths];
                            
                            if(GetVectorDistance(clientpos,corpsepos)<50){
                                if(corpsehealth[corpse][deaths]>=0){
                                    EmitSoundToAll(Nom,client);
                                    W3FlashScreen(client,{155,0,0,40},0.1);
                                    corpsehealth[corpse][deaths]-=5;
                                    new addhp1=cannibal[skill_level];
                                    War3_HealToMaxHP(client,addhp1);
                                }
                            }
                            else
                            {
                                corpsehealth[corpse][deaths]-=5;
                            }
                        }
                    }
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



public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new client=0;client<=MaxClients;client++)
    {
        for(new deaths=0;deaths<=19;deaths++)
        {
            corpselocation[0][client][deaths]=0.0;
            corpselocation[1][client][deaths]=0.0;
            corpselocation[2][client][deaths]=0.0;
            dietimes[client]=0;
            corpsehealth[client][deaths]=0;
            corpsedied[client][deaths]=false;
        }
    }
}
