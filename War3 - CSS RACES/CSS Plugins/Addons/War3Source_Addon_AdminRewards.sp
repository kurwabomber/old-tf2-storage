/**
* File: War3Source_Addon_AdminRewards.sp
* Description: Gives random rewards to players who kill someone playing specific races
* Author(s): Remy Lebeau
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include <smlib>

public Plugin:myinfo = 
{
    name = "War3Source Addon - Kill Rewards",
    author = "Remy Lebeau",
    description = "Gives random rewards for kills on admins (playing certain races)",
    version = "0.9",
    url = "sevensinsgaming.com"
};

new iArrayWidth = 2;
new iArrayDepth = 32;
new String:g_sRaceShortNameList[2][32];
new bool:bIsRewardRace[MAXPLAYERS+1];
new bool:bVoodoo[MAXPLAYERS];




public OnPluginStart()
{
    for (new i=0; i<iArrayWidth; i++)
    {
        g_sRaceShortNameList[i] = "";
    }
    StrCat(g_sRaceShortNameList[0], iArrayDepth, "flash");
    StrCat(g_sRaceShortNameList[1], iArrayDepth, "jammer");
}
    

/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/
public OnWar3EventSpawn( client )
{
    if(ValidPlayer(client))
    {
        bVoodoo[client] = false;
        
        for (new i=0; i<iArrayWidth; i++)
        {
            new admin_race = War3_GetRaceIDByShortname(g_sRaceShortNameList[i]);

            if(War3_GetRace(client) == admin_race && admin_race > 0)
            {
                bIsRewardRace[client] = true;
                new String:pName[253];
                GetClientName(client, pName, 253);
                Client_PrintToChatAll(false ,"{G}|%s| is playing a reward race!  Kill them for a bonus.", pName);
            }
        }
    }
}

public OnRaceChanged(client, oldrace, newrace)
{
    if (ValidPlayer(client))
    {
        for (new i=0; i<iArrayWidth; i++)
        {
            new admin_race = War3_GetRaceIDByShortname(g_sRaceShortNameList[i]);

            if(newrace == admin_race && admin_race > 0)
            {
                bIsRewardRace[client] = true;
            }
            else
            {
                bIsRewardRace[client] = false;
            }
        }
    }
}

public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim) && attacker!=victim)
    {
        if(bIsRewardRace[victim])
        {
            GiveRewards(victim, attacker);
        }
    }
}





public GiveRewards( victim, attacker )
{
/*30% - 50 xp
20% - 100 xp
20% - 1 gold
10% - 500 xp
5% - 5 gold
5% - 1000 xp
5% - 1 levelbank level
4% - god mode for 15 seconds
1% - 5 levelbank levels
00344: W3GiveXPGold(attacker,XPAwardByKill,addxp,addgold,"Killing an admin reward race");
00525: native W3GetLevelBank(client);
00526: native W3SetLevelBank(client, newlevelbank);
*/

    new RewardChance = GetRandomInt(0,99);
    new String:pName[256];
    GetClientName (attacker, pName, 256 );
    if(RewardChance >=0 && RewardChance < 30)
    {
        W3GiveXPGold(attacker,XPAwardByKill,50,0,"Killing an admin reward race");
        Client_PrintToChatAll(false, "{G}|%s| gets rewarded!  Bonus: 50 XP.", pName);
    }
    else if(RewardChance >=30 && RewardChance < 50)
    {
        W3GiveXPGold(attacker,XPAwardByKill,100,0,"Killing an admin reward race");
        Client_PrintToChatAll(false, "{G}|%s| gets rewarded!  Bonus: 100 XP.", pName);
    }    
    else if(RewardChance >=50 && RewardChance < 70)
    {
        W3GiveXPGold(attacker,XPAwardByKill,0,1,"Killing an admin reward race");
        Client_PrintToChatAll(false, "{G}|%s| gets rewarded!  Bonus: 1 Gold.", pName);
    }
    else if(RewardChance >=70 && RewardChance < 80) 
    {
        W3GiveXPGold(attacker,XPAwardByKill,500,0,"Killing an admin reward race");
        Client_PrintToChatAll(false,  "{G}|%s| gets rewarded!  Bonus: 500 XP.", pName);
    }
    else if(RewardChance >=80 && RewardChance < 85) 
    {
        W3GiveXPGold(attacker,XPAwardByKill,0,5,"Killing an admin reward race");
        Client_PrintToChatAll(false,  "{G}|%s| gets rewarded!  Bonus: 5 Gold.", pName);
    }
    else if(RewardChance >=85 && RewardChance < 90) 
    {
        W3GiveXPGold(attacker,XPAwardByKill,1000,0,"Killing an admin reward race");
        Client_PrintToChatAll(false,  "{G}|%s| gets rewarded!  Bonus: 1000 XP.", pName);
    }
    else if(RewardChance >=90 && RewardChance < 95) 
    {
        new alevels = (W3GetLevelBank(attacker) + 1);
        W3SetLevelBank(attacker, alevels);
        Client_PrintToChatAll(false,  "{G}|%s| gets rewarded!  Bonus: +1 levelbank.", pName);
    }
    else if(RewardChance >=95 && RewardChance < 99) 
    {
        Client_PrintToChatAll(false,  "{G}|%s| gets rewarded!  Bonus: 15s of God Mode!", pName);
        bVoodoo[attacker] = true;
        CreateTimer(15.0,EndVoodoo,attacker);
        W3SetPlayerColor(attacker,-1,255,200,0,_,GLOW_ULTIMATE);
    }
    else if(RewardChance == 99)
    {
        new alevels = (W3GetLevelBank(attacker) + 5);
        W3SetLevelBank(attacker, alevels);
        Client_PrintToChatAll(false,  "{G}|%s| gets rewarded!  Bonus: +5 levelbank.", pName);
    }
}



public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0) //block self inflicted damage
    {
        if(bVoodoo[victim]&&attacker==victim){
            War3_DamageModPercent(0.0);
            return;
        }
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            if(bVoodoo[victim])
            {            
                War3_DamageModPercent(0.0);
            }
        }
    }
    return;
}


public Action:EndVoodoo(Handle:timer,any:client)
{
    bVoodoo[client]=false;
    W3ResetPlayerColor(client,-1);
}