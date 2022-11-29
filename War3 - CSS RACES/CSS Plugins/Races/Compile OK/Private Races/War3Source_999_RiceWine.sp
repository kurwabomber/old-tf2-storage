/**
* File: War3Source_999_RiceWine.sp
* Description: The Wolf of Rice Wine Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/remyfunctions"

new thisRaceID;
new SKILL_REGEN, SKILL_DRUG, SKILL_SPEED, ULT_MODEL;

#define WEAPON_RESTRICT "weapon_knife"
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - The Wolf of Rice Wine",
    author = "Remy Lebeau",
    description = "Skoll's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.15, 1.20, 1.35, 1.5 };
new Float:g_fRegen[] = { 1.0, 1.0, 2.0, 4.0, 6.0 };

// Drug
new Float:g_DrugAngles[20] = { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };
new UserMsg:g_FadeUserMsgId;
new bool:g_bClientDrugged[MAXPLAYERS];
new Float:g_fAbilityTimer[] = {0.0, 2.0,3.0,4.0,5.0};


// Model Variables


//new Float:g_fOriginalModel[]={0.0, 1.0,1.0,1.0,1.0};
new Float:g_fHostageModel[]={0.0,0.15,0.4,0.75,0.9};
new Float:g_fEnemyModel[]={0.0,0.05,0.175,0.25,0.25};


// Skill_Drug Variables
new Float:ElectricTideOrigin[MAXPLAYERSCUSTOM][3];
new Float:ElectricTideRadius=600.0;
new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];
new HaloSprite, BeamSprite;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Wolf of Rice Wine [PRIVATE]","ricewine");
    
    SKILL_REGEN=War3_AddRaceSkill(thisRaceID,"Mutant Healing Factor","Function over form - Regenerate.",false,4);
    SKILL_DRUG=War3_AddRaceSkill(thisRaceID,"S-M-R-T! - Mental deterioration","Drug players around you (+ability), you are always drugged.",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Training Montage!","Push it to the limit!",false,4);
    ULT_MODEL=War3_AddRaceSkill(thisRaceID,"Image Inducer","Chance of model change to opposite team or hostage.",true,4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_REGEN, fHPRegen, g_fRegen);
    
}



public OnPluginStart()
{
    CreateTimer(1.0,Drugs,_,TIMER_REPEAT);    
    HookEvent("round_end",RoundOverEvent);
    g_FadeUserMsgId = GetUserMessageId( "Fade" );
}



public OnMapStart()
{
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    if(!IsModelPrecached("models/characters/hostage_01.mdl"))
        PrecacheModel("models/characters/hostage_01.mdl");
    if(!IsModelPrecached("models/characters/hostage_02.mdl"))
        PrecacheModel("models/characters/hostage_02.mdl");
    if(!IsModelPrecached("models/characters/hostage_03.mdl"))
        PrecacheModel("models/characters/hostage_03.mdl");
    if(!IsModelPrecached("models/characters/hostage_04.mdl"))
        PrecacheModel("models/characters/hostage_04.mdl");

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
    War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,-25);           

    new skill_level = War3_GetSkillLevel( client, thisRaceID,ULT_MODEL );   

    if(skill_level>0)
    {
        new Float:chance = GetRandomFloat(0.0,1.0);
        if(chance<g_fEnemyModel[skill_level])
        {
            War3_ChangeModel( client, true);
            new String:buffer[500];
            Format(buffer,sizeof(buffer),"\nModel: Enemy");
            HUD_Add(GetClientUserId(client), buffer);
            
        }
        else if(chance<g_fHostageModel[skill_level])
        {
            War3_ChangeModelToHostage(client);
            new String:buffer[500];
            Format(buffer,sizeof(buffer),"\nModel: Hostage");
            HUD_Add(GetClientUserId(client), buffer);
        }
        else
        {
            War3_ChangeModel( client );
            new String:buffer[500];
            Format(buffer,sizeof(buffer),"\nModel: Team");
            HUD_Add(GetClientUserId(client), buffer);
        }
        
    }

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
        HUD_Add(GetClientUserId(client), "");
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if(ValidPlayer( client, true ))
    {
        if( race == thisRaceID )
        {    
            InitPassiveSkills( client );
            g_bClientDrugged[client] = true;
        }
        else
        {
            g_bClientDrugged[client] = false;
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


public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true) && ability==0)
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID,SKILL_DRUG );
        if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_DRUG,true))
        {
            if(skill_level > 0)
            {
                GetClientAbsOrigin(client,ElectricTideOrigin[client]);
                ElectricTideOrigin[client][2]+=15.0;
                
                for(new i=1;i<=MaxClients;i++){
                    HitOnBackwardTide[i][client]=false;
                    HitOnForwardTide[i][client]=false;
                }
                //50 IS THE CLOSE CHECK
                TE_SetupBeamRingPoint(ElectricTideOrigin[client], 20.0, ElectricTideRadius+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,0,133}, 60, 0);
                TE_SendToAll();
                
                CreateTimer(0.1, StunLoop,GetClientUserId(client));
                                
                CreateTimer(0.5, SecondRing,GetClientUserId(client));
                
                War3_CooldownMGR(client,20.0,thisRaceID,SKILL_DRUG,_,_);

            }
                
            else
            {
                PrintHintText(client, "Level Infestation first");
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
    if(ValidPlayer(victim))
    {
        if (g_bClientDrugged[victim] == true)
        {
             g_bClientDrugged[victim] = false;
             Drug( victim, 0 );
        }
        if (War3_GetRace(victim) == thisRaceID)
        {
            HUD_Add(GetClientUserId(victim), "");
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


public Action:SecondRing(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    TE_SetupBeamRingPoint(ElectricTideOrigin[client], ElectricTideRadius+50,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,0,133}, 60, 0);
    TE_SendToAll();
}

public Action:StunLoop(Handle:timer,any:userid)
{
    new attacker=GetClientOfUserId(userid);
    if(ValidPlayer(attacker) )
    {
        new team = GetClientTeam(attacker);
        new skill_level = War3_GetSkillLevel( attacker, thisRaceID,SKILL_DRUG );
        new Float:otherVec[3];
        new victimcounter = 0;
        new victimlist[MAXPLAYERS];
        for(new i=1;i<=MaxClients;i++)
        {

            if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Skills))
            {        
                
                GetClientAbsOrigin(i,otherVec);
                otherVec[2]+=30.0;
                new Float:victimdistance=GetVectorDistance(ElectricTideOrigin[attacker],otherVec);

                if(victimdistance<ElectricTideRadius)
                {
                    
                    victimlist[victimcounter] = i;
                    victimcounter++;
                }
                
            }
        }

        for(new i=0;i<victimcounter;i++)
        {
            new temp = victimlist[i];
            if(ValidPlayer(temp))
            {
                
                g_bClientDrugged[temp] = true;
                Drug( temp, 1 );
                CreateTimer(g_fAbilityTimer[skill_level], StopDrugs, temp);
            }
        }
    }
}

public Action:StopDrugs(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
         g_bClientDrugged[client] = false;
         Drug( client, 0 );
    }
}



public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i))
        {
            W3ResetAllBuffRace( i, thisRaceID );
            g_bClientDrugged[i] = false;
        }
    }
}

public Action:Drugs(Handle:timer,any:userid)
{
    for(new client=1;client<=MaxClients;client++)
    {
        if(ValidPlayer(client,true))
        {
            if(g_bClientDrugged[client] == true)
            {
                Drug( client, 1 );
            }
        }
    }
}

stock Drug( client, mode )
{
    if( mode == 1 )
    {
        new Float:pos[3];
        GetClientAbsOrigin( client, pos );

        new Float:angs[3];
        GetClientEyeAngles( client, angs );

        angs[2] = g_DrugAngles[GetRandomInt( 0, 100 ) % 20];

        TeleportEntity( client, pos, angs, NULL_VECTOR );

        new clients[2];
        clients[0] = client;

        new Handle:message = StartMessageEx( g_FadeUserMsgId, clients, 1 );
        BfWriteShort( message, 255 );
        BfWriteShort( message, 255 );
        BfWriteShort( message, ( 0x0002 ) );
        BfWriteByte( message, GetRandomInt( 0, 255 ) );
        BfWriteByte( message, GetRandomInt( 0, 255 ) );
        BfWriteByte( message, GetRandomInt( 0, 255 ) );
        BfWriteByte( message, 128 );

        EndMessage();
    }
    
    if( mode == 0 )
    {
        new Float:pos[3];
        GetClientAbsOrigin( client, pos );

        new Float:angs[3];
        GetClientEyeAngles( client, angs );

        angs[2] = 0.0;

        TeleportEntity( client, pos, angs, NULL_VECTOR );    

        new clients[2];
        clients[0] = client;    

        new Handle:message = StartMessageEx( g_FadeUserMsgId, clients, 1 );
        BfWriteShort( message, 1536 );
        BfWriteShort( message, 1536 );
        BfWriteShort( message, ( 0x0001 | 0x0010 ) );
        BfWriteByte( message, 0 );
        BfWriteByte( message, 0 );
        BfWriteByte( message, 0 );
        BfWriteByte( message, 0 );

        EndMessage();
    }
}
    