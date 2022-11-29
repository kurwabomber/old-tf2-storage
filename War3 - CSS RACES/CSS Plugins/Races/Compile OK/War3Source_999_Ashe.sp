/**
* File: War3Source_999_Ashe.sp
* Description: Ashe Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_CRIT, SKILL_FROST, SKILL_VOLLEY, SKILL_CASH, ULT_ATTACK;

#define WEAPON_RESTRICT "weapon_knife,weapon_scout"
#define WEAPON_GIVE "weapon_scout"


public Plugin:myinfo = 
{
    name = "War3Source Race - Ashe",
    author = "Remy Lebeau",
    description = "Ashe race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

new bool:g_bUltiVolley[MAXPLAYERS]; // TRUE FOR ULTI, FALSE FOR VOLLEY - Used for team checks in AOE freeze.

// CRIT
new Float:g_fCritDamage[] = {0.0, 0.1, 0.15, 0.2, 0.25};
new Float:g_fCritChance = 0.45;

// FROST
new Float:FrostArrow[]={0.00,0.80,0.60,0.40,0.20};
new g_iFrostCost[] = {0, 500, 1000, 1500, 2000 };
new bool:g_bFrostToggle[MAXPLAYERS];

// VOLLEY
new g_iVolleyCost[] = {0, 1000, 2000, 3000, 4000 };
new Float:ElectricTideOrigin[MAXPLAYERSCUSTOM][3];
new Float:distractiontime[] = {0.0, 0.5, 0.7, 1.0, 1.3};
new Float:ElectricTideRadius[]={0.0, 150.0, 250.0, 300.0, 375.0};
new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];
new HaloSprite, BeamSprite;
new g_iVolleyDamage[] = {0,10,20,30,40};


// HAWKEYE
new g_iKillMoney[] = {0,500,1000,1500,2000};
new MoneyOffsetCS;

// ULTIMATE
new bool:g_bUltiToggle[MAXPLAYERS];
new g_iUltiCost[] = {0, 1000, 2000, 3000, 4000 };
new g_iUltiDamage[] = {0,20,30,40,50};
new g_iAshe[MAXPLAYERS];

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Ashe [LeviathaN]","ashe");
    
    SKILL_CRIT=War3_AddRaceSkill(thisRaceID,"Focus","Chance to do crit damage",false,4);
    SKILL_FROST=War3_AddRaceSkill(thisRaceID,"Frost Shot","Slow effect on hit - toggle on/off, costs $$ (+ability)",false,4);
    SKILL_VOLLEY=War3_AddRaceSkill(thisRaceID,"Volley","AoE - Damage + slow, costs $$ (+ability1)",false,4);
    SKILL_CASH=War3_AddRaceSkill(thisRaceID,"Hawkshot","Gain more $$ on kill",false,4);
    ULT_ATTACK=War3_AddRaceSkill(thisRaceID,"Enchanted Crystal","Deal DAMAGE + slow to nearby enemies - toggle on/off, costs $$ (+ultimate)",true,4);
    
    War3_CreateRaceEnd(thisRaceID);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
}



public OnMapStart()
{
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
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
    g_bFrostToggle[client] = false;
    g_bUltiToggle[client] = false;
    /*
    if (GetMoney(client)>4000)
    {
        SetMoney(client, 4000);
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



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID, ULT_ATTACK );
        if(skill_level>0)
        {  
            new money=GetMoney(client);
            if(money>=g_iUltiCost[skill_level])
            {            
                if(g_bUltiToggle[client] == false)
                {
                    g_bUltiToggle[client] = true;
                    PrintHintText(client, "ENCHANTED CRYSTAL: TOGGLED - ON -");
                    
                }
                else
                {
                    g_bUltiToggle[client] = false;
                    PrintHintText(client, "ENCHANTED CRYSTAL: TOGGLED - OFF -");
                }
            }
            else
            {
                PrintHintText(client, "You don't have enough mana for Enchanted Crystal");
            }
        }
        else
        {
            PrintHintText(client, "Level Enchanted Crystal first");
        }
    }
}


public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            new money=GetMoney(client);
            if(ability==0 && pressed)
            {
                new skill_frost=War3_GetSkillLevel(client,thisRaceID,SKILL_FROST);
                if(skill_frost>0)
                {
                    if(money>=g_iFrostCost[skill_frost])
                    {            
                        if(g_bFrostToggle[client] == false)
                        {
                            g_bFrostToggle[client] = true;
                            PrintHintText(client, "FROST SHOT: TOGGLED - ON -");
                            
                        }
                        else
                        {
                            g_bFrostToggle[client] = false;
                            PrintHintText(client, "FROST SHOT: TOGGLED - OFF -");
                        }
                    }
                    else
                    {
                        PrintHintText(client, "You don't have enough mana for Frost Shot");
                    }
                }
                else
                {
                    PrintHintText(client, "Level Frost Shot first");
                }
            }
            
            if(ability==1 && pressed)
            {
                new skill_volley=War3_GetSkillLevel(client,thisRaceID,SKILL_VOLLEY);
                if(skill_volley>0)
                {
                    if(money>=g_iVolleyCost[skill_volley])
                    {
                        new new_money = money - g_iVolleyCost[skill_volley];
                        SetMoney(client, new_money);
                        
                        GetClientAbsOrigin(client,ElectricTideOrigin[client]);
                        ElectricTideOrigin[client][2]+=15.0;
                        
                        for(new i=1;i<=MaxClients;i++){
                            HitOnBackwardTide[i][client]=false;
                            HitOnForwardTide[i][client]=false;
                        }
                        //50 IS THE CLOSE CHECK
                        TE_SetupBeamRingPoint(ElectricTideOrigin[client], 20.0, ElectricTideRadius[skill_volley]+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {0,0,255,133}, 60, 0);
                        TE_SendToAll();
                        g_bUltiVolley[client] = false;
                        
                        CreateTimer(0.1, StunLoop,client);
                                        
                        CreateTimer(0.5, SecondRing,client);

                        
                        PrintHintText(client,"Volley!");    
                        
                    }
                    else
                    {
                        PrintHintText(client, "You don't have enough mana for Volley");
                    }
                    
                }
                else
                {
                    PrintHintText(client, "Level your forked lightning first");
                }
                
            
            
            }
            
            
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
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

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(ValidPlayer(victim, true)&&ValidPlayer(attacker,true)&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_attacker=War3_GetRace(attacker);
            new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROST);
            // Frost Arrow
            if(race_attacker==thisRaceID && skill_level>0 && !Silenced(attacker) )
            {
                new old_money = GetMoney(attacker);
                if( g_bFrostToggle[attacker] == true && !W3HasImmunity(victim,Immunity_Skills))
                {

                    if(old_money >= g_iFrostCost[skill_level])
                    {
//                        PrintToChat(attacker, "Frost Shot Fired");
                        new new_money = old_money - g_iFrostCost[skill_level];
                        SetMoney(attacker, new_money);
                        War3_SetBuff(victim,fSlow,thisRaceID,FrostArrow[skill_level]);
                        War3_SetBuff(victim,fAttackSpeed,thisRaceID,FrostArrow[skill_level]);
                        W3FlashScreen(victim,RGBA_COLOR_BLUE);
                        CreateTimer(1.5,unfrost,victim);
                        PrintHintText(attacker,"Frost Shot!");
                        PrintHintText(victim,"You have been hit by a Frost Shot");
                        
                    }
                    else
                    {
                        PrintHintText(attacker, "You have insufficient mana for Frost Shot");
                        g_bFrostToggle[attacker] = false;
                    }
                }
                skill_level=War3_GetSkillLevel(attacker,thisRaceID,ULT_ATTACK);
                if( g_bUltiToggle[attacker] == true && !W3HasImmunity(victim,Immunity_Ultimates))
                {
                    if(old_money >= g_iUltiCost[skill_level])
                    {
                        new new_money = old_money - g_iUltiCost[skill_level];
                        SetMoney(attacker, new_money);

                        W3FlashScreen(victim,RGBA_COLOR_RED);
                        
                        // DEAL DAMAGE
                        new ulti_level=War3_GetSkillLevel(attacker,thisRaceID,ULT_ATTACK);
                        new dealdamage = g_iUltiDamage[ulti_level];
//                        PrintToChat(attacker, "Enchanted Crystal Shot Fired");
                        War3_DealDamage( victim, dealdamage, attacker, DMG_BULLET, "crystal_damage" );
                        
                        // VOLLEY
                        new skill_volley=War3_GetSkillLevel(attacker,thisRaceID,SKILL_VOLLEY);
                        if(skill_volley>0)
                        {
//                            PrintToChat(attacker, "Enchanted Crystal Shot Fired - volley");
                            g_iAshe[victim] = attacker;
                            g_bUltiVolley[victim] = true;
                            GetClientAbsOrigin(victim,ElectricTideOrigin[victim]);
                            ElectricTideOrigin[victim][2]+=15.0;
                            
                            for(new i=1;i<=MaxClients;i++){
                                HitOnBackwardTide[i][victim]=false;
                                HitOnForwardTide[i][victim]=false;
                            }
                            //50 IS THE CLOSE CHECK
                            TE_SetupBeamRingPoint(ElectricTideOrigin[victim], 20.0, ElectricTideRadius[skill_volley]+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {0,0,255,133}, 60, 0);
                            TE_SendToAll();
                            
                            CreateTimer(0.1, StunLoop,victim);
                                            
                            CreateTimer(0.5, SecondRing,victim);
    
                        }
                        else
                        {
                        PrintHintText(attacker, "Put levels into Volley to produce a slow effect at your target");
                        }    
                        
                        
                    }
                    else
                    {
                        PrintHintText(attacker, "You have insufficient mana for Enchanted Crystal");
                        g_bUltiToggle[attacker] = false;
                    }
                }
            }
        }
    }
}



public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_damage = War3_GetSkillLevel( attacker, thisRaceID, SKILL_CRIT );
            if( !Hexed( attacker, true ) && skill_damage > 0 && !W3HasImmunity(victim, Immunity_Skills) )
            {
                if(GetRandomFloat(0.0,1.0)<=g_fCritChance)
                {
                    new dealdamage = RoundToFloor( damage * g_fCritDamage[skill_damage] );
                    War3_DealDamage( victim, dealdamage, attacker, DMG_BULLET, "focus_damage" );
                    W3FlashScreen( victim, RGBA_COLOR_RED );
                    PrintHintText(attacker, "Crit: %d", dealdamage);
                    
                }
            }
        }
    }
}

public OnWar3EventDeath( victim, attacker )
{
    if (War3_GetRace( attacker ) == thisRaceID && ValidPlayer(attacker, true))
    {
        new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_CASH);
        if(skill_level > 0)
        {
            new old_money = GetMoney(attacker);
            new new_money = old_money + g_iKillMoney[skill_level];
            SetMoney(attacker, new_money);
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
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}

    

public Action:unfrost(Handle:timer,any:client)
{
    War3_SetBuff(client,fSlow,thisRaceID,1.0);
    War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
}


public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, WEAPON_GIVE );
    }
}

stock GetMoney(player)
{
    return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
    SetEntData(player,MoneyOffsetCS,money);
}



public Action:SecondRing(Handle:timer,any:client)
{
    new skill_volley;
    if(g_bUltiVolley[client]==true)
    {    
        skill_volley=War3_GetSkillLevel(g_iAshe[client],thisRaceID,SKILL_VOLLEY);
    }
    else
    {
        skill_volley=War3_GetSkillLevel(client,thisRaceID,SKILL_VOLLEY);
    }
    TE_SetupBeamRingPoint(ElectricTideOrigin[client], ElectricTideRadius[skill_volley]+50,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {0,0,255,133}, 60, 0);
    TE_SendToAll();
}

public Action:StunLoop(Handle:timer,any:attacker)
{

    if(ValidPlayer(attacker) )
    {
        new team = GetClientTeam(attacker);
        new skill_volley;
        if(g_bUltiVolley[attacker]==true)
        {    
            skill_volley=War3_GetSkillLevel(g_iAshe[attacker],thisRaceID,SKILL_VOLLEY);
        }
        else
        {
            skill_volley=War3_GetSkillLevel(attacker,thisRaceID,SKILL_VOLLEY);
        }
        
        
        new Float:otherVec[3];
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true)&&!W3HasImmunity(i,Immunity_Skills))
            {        
                if((GetClientTeam(i)!=team && g_bUltiVolley[attacker]==false) || (GetClientTeam(i)==team && g_bUltiVolley[attacker]==true))
                {
                    GetClientAbsOrigin(i,otherVec);
                    otherVec[2]+=30.0;
                    new Float:victimdistance=GetVectorDistance(ElectricTideOrigin[attacker],otherVec);
                    if(victimdistance<ElectricTideRadius[skill_volley])
                    {
                        new Float:entangle_time=distractiontime[skill_volley];
                        
                        War3_SetBuff(i,fSlow,thisRaceID,0.4);
                        War3_SetBuff(i,fAttackSpeed,thisRaceID,0.4);
                        W3SetPlayerColor(i,thisRaceID,0,0,255,_,GLOW_SKILL); 
    
                        if(g_bUltiVolley[attacker]==false)
                            War3_DealDamage( i, g_iVolleyDamage[skill_volley], attacker, DMG_BULLET, "volley damage" );
                        
                        CreateTimer(entangle_time,stopStun,i);
                        
                        
                    }
                }
            }
        }
    }
    
}
public Action:stopStun(Handle:timer,any:i)
{
    War3_SetBuff(i,fSlow,thisRaceID,1.0);
    War3_SetBuff(i,fAttackSpeed,thisRaceID,1.0);
    W3ResetPlayerColor(i,thisRaceID);
} 
