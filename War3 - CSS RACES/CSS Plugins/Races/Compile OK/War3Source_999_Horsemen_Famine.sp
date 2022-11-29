/**
* File: War3Source_999_Horsemen_Famine.sp
* Description: Famie Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL1, SKILL2, SKILL3, SKILL4;

#define WEAPON_RESTRICT "weapon_knife,weapon_glock"
#define WEAPON_GIVE "weapon_glock"

public Plugin:myinfo = 
{
    name = "War3Source Race - Famine [HORSEMEN]",
    author = "Remy Lebeau",
    description = "Famine race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.2, 1.25, 1.3, 1.35 };
new g_iMaxHealth[] = { 150, 150, 150, 150, 150 };
new Float:g_fDamage[] = { 0.0, 0.20, 0.25, 0.30, 0.35 };
new Float:g_fAuraSpeed[] = { 1.0, 1.2, 1.25, 1.3, 1.35 };



new Float:AuraDistance[]={0.0,250.0,300.0,350.0,400.0};
new AuraID;

//Cannibalize
new String:Nom[]="war3source/nomnom.mp3";
new Float:corpselocation[3][MAXPLAYERS][20];
new dietimes[MAXPLAYERS];
new cannibal[]={0,10,11,12,13};
new corpsehealth[MAXPLAYERS][40];
new bool:corpsedied[MAXPLAYERS][40];
new BeamSprite,HaloSprite;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Famine - White Horseman","horseman_famine");
    
    SKILL1=War3_AddRaceSkill(thisRaceID,"Famine's Weapon","Famine carries a white sword",false,4);
    SKILL2=War3_AddRaceSkill(thisRaceID,"Famine's Speed","Famine's horse - It's not as fast as war's.",false,4);
    SKILL3=War3_AddRaceSkill(thisRaceID,"Famine's Hunger","Famine is hungry! Regain health feasting on corpses",false,4);
    SKILL4=War3_AddRaceSkill(thisRaceID,"Famine's Presence","Speed aura",true,4);

    
    War3_CreateRaceEnd(thisRaceID);
    
    AuraID=W3RegisterChangingDistanceAura("famine_speedwave");
    
    War3_AddSkillBuff(thisRaceID, SKILL2, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL1, fDamageModifier, g_fDamage);
}



public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
    CreateTimer(0.5,nomnomnom,_,TIMER_REPEAT);

}



public OnMapStart()
{
    War3_AddCustomSound(Nom);
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
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

    new level=War3_GetSkillLevel(client,thisRaceID,SKILL1);
    War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, g_iMaxHealth[level] );

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
    if(aura==AuraID)
    {
        if(inAura)
        {
            War3_SetBuff( client, fAttackSpeed, thisRaceID, g_fAuraSpeed[level] );
            War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fAuraSpeed[level] );
            
        }
        else
        {
            War3_SetBuff( client, fAttackSpeed, thisRaceID, 1.0 );
            War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
        }
        
        
    }
}



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
            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL3);
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
                                    corpsehealth[corpse][deaths]-=cannibal[skill_level];
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



public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, WEAPON_GIVE );
    }
}