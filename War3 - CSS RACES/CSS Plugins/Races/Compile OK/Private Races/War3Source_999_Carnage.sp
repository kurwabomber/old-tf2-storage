/**
* File: War3Source_999_Carnage.sp
* Description: Carnage Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_HEALTH, SKILL_DAMAGE, SKILL_FOOTSTEPS, SKILL_SPEED;

#define WEAPON_RESTRICT "weapon_knife"
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Carnage",
    author = "Remy Lebeau",
    description = "Arrow's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new Float:g_fDamageBoost[] = { 0.0, 0.25, 0.35, 0.5, 0.75 };
new Float:FootstepsChance[] = {0.0, 0.25, 0.50, 0.75, 1.01};
new bool:footsteps[MAXPLAYERS];
new g_iMaxHealth = 50 ;

//Cannibalize
new String:Nom[]="war3source/nomnom.mp3";
new Float:corpselocation[3][MAXPLAYERS][20];
new dietimes[MAXPLAYERS];
new cannibal[]={0,8,10,12,14};
new corpsehealth[MAXPLAYERS][40];
new bool:corpsedied[MAXPLAYERS][40];
new BeamSprite,HaloSprite;




public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Carnage [PRIVATE]","carnage");
    
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Feed!","Feed on the dead.",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Morph!","Carnage is capable of creating powerful weapons.",false,4);
    SKILL_FOOTSTEPS=War3_AddRaceSkill(thisRaceID,"Agility!","Carnage moves silently.",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Sprint!","Carnage travels at great speed.",false,4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    //War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamageBoost);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
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
    War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, g_iMaxHealth );
    
    new skill_footsteps = War3_GetSkillLevel( client, thisRaceID, SKILL_FOOTSTEPS );
    if (GetRandomFloat(0.0,1.0) < FootstepsChance[skill_footsteps])
    {    
        footsteps[client] = true; 
        War3_SetBuff(client,bImmunityWards,thisRaceID,true);
        CPrintToChat(client, "{red}Carnage: {default}-- Footsteps are muted, immune to wards.");
    }
    else
    {
        footsteps[client] = false; 
        War3_SetBuff(client,bImmunityWards,thisRaceID,false);
    }

    new skill_damage = War3_GetSkillLevel( client, thisRaceID, SKILL_DAMAGE );
    War3_SetBuff(client,fDamageModifier,thisRaceID,g_fDamageBoost[skill_damage]);

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
        footsteps[client] = false; 
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    footsteps[client] = false; 
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
        for(new deaths=0;deaths<=19;deaths++)
        {
            corpselocation[0][i][deaths]=0.0;
            corpselocation[1][i][deaths]=0.0;
            corpselocation[2][i][deaths]=0.0;
            dietimes[i]=0;
            corpsehealth[i][deaths]=0;
            corpsedied[i][deaths]=false;
        }
    }
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer (client, true))
    {
        if(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP) && footsteps[client] == true)
        {
            SetEntProp(client, Prop_Send, "m_fFlags", 4);
        }
    }
    return Plugin_Continue;
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





    