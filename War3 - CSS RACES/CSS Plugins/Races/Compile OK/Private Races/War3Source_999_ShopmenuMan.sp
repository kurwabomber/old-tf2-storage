/**
* File: War3Source_999_ShopmenuMan.sp
* Description: The Shopmenu Man Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL1, SKILL2, SKILL3, SKILL4;

#define WEAPON_RESTRICT ""
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - The Shopmenu Man",
    author = "Remy Lebeau",
    description = "AGENTKripsy's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};




public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("The Shopmenu Man [PRIVATE]","shopmenuman");
    
    SKILL1=War3_AddRaceSkill(thisRaceID,"One will get it done","Chance of shopmenu item",false,3);
    SKILL2=War3_AddRaceSkill(thisRaceID,"Two, better than Anduu","Chance of shopmenu item",false,5);
    SKILL3=War3_AddRaceSkill(thisRaceID,"Three will be a killing spree","Chance of shopmenu item",false,5);
    SKILL4=War3_AddRaceSkill(thisRaceID,"Four will wipe the floor","Chance of shopmenu item",false,5);

    War3_CreateRaceEnd(thisRaceID);
}

new String:ItemList[][] = {"ankh", "glove", "mole",
"boot", "claw", "cloak", 
"mask", "lace", "orb", 
"ring", "antiward", "health", 
"scroll","tome", "sock", 
"gboots", "shield", "helm", 
"feet"};
new Float:ItemChance[] = {0.067,0.107,0.112,
0.179,0.246,0.346,
0.396,0.496,0.562,
0.619,0.686,0.753,
0.763,0.783,0.883,
0.933,0.949,0.963,
1.000};

new Float:Skill1Chance[] = {0.0, 0.33, 0.66, 1.0};
new Float:SkillChance[] = {0.0, 0.2, 0.4, 0.6, 0.8, 1.0};
new ItemSet[MAXPLAYERS][4];
new bool:ankhcheck[MAXPLAYERS];

// write a check function for random numbers against existing ones in array



public OnPluginStart()
{
    //HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{

}

    
/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/

ResetItems(client)
{
    new ItemsLoaded = W3GetItemsLoaded();
    if (ValidPlayer(client))
    {
        PrintToConsole(client, "ITEMS RESET");
        for(new i2;i2<=ItemsLoaded;i2++)
        {
            if(War3_GetOwnsItem(client, i2))
            {
                W3SetVar(TheItemBoughtOrLost,i2);
                W3CreateEvent(DoForwardClientLostItem,client);
            }
        }
    }
}


public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim))
    {
        if( War3_GetRace( victim ) == thisRaceID && ankhcheck[victim])
        {
            new itemID = War3_GetItemIdByShortname("ankh");
            W3SetVar(TheItemBoughtOrLost,itemID);
            W3CreateEvent(DoForwardClientBoughtItem,victim);
        }
    }
}


InitPassiveSkills(client)
{
    ankhcheck[client] = false;

    new skill1_level = War3_GetSkillLevel(client, thisRaceID, SKILL1);
    new skill2_level = War3_GetSkillLevel(client, thisRaceID, SKILL2);
    new skill3_level = War3_GetSkillLevel(client, thisRaceID, SKILL3);
    new skill4_level = War3_GetSkillLevel(client, thisRaceID, SKILL4);
    
    for(new x;x<=3;x++)
    {
        ItemSet[client][x] = -1;
    }
    
    if(skill1_level > 0)
    {   
        // TEST FOR ITEM BASED ON SKILL LEVEL
        if(GetRandomFloat( 0.0, 1.0 ) <= Skill1Chance[skill1_level])
        {
            ItemSet[client][0] = GetItemByChance(client);
            
            new itemID = War3_GetItemIdByShortname(ItemList[ItemSet[client][0]]);
            PrintToConsole(client, "1 Gained item: |%s|",ItemList[ItemSet[client][0]]); 
            W3SetVar(TheItemBoughtOrLost,itemID);
            W3CreateEvent(DoForwardClientBoughtItem,client);
        }
    }
    
    if(skill2_level > 0)
    {   
        // TEST FOR ITEM BASED ON SKILL LEVEL
        if(GetRandomFloat( 0.0, 1.0 ) <= SkillChance[skill2_level])
        {
            ItemSet[client][1] = GetItemByChance(client);
            
            new itemID = War3_GetItemIdByShortname(ItemList[ItemSet[client][1]]);
            PrintToConsole(client, "2 Gained item: |%s|",ItemList[ItemSet[client][1]]);
            W3SetVar(TheItemBoughtOrLost,itemID);
            W3CreateEvent(DoForwardClientBoughtItem,client);
        }
    }
    
    if(skill3_level > 0)
    {   
        // TEST FOR ITEM BASED ON SKILL LEVEL
        if(GetRandomFloat( 0.0, 1.0 ) <= SkillChance[skill3_level])
        {
            ItemSet[client][2] = GetItemByChance(client);
            
            new itemID = War3_GetItemIdByShortname(ItemList[ItemSet[client][2]]);
            PrintToConsole(client, "3 Gained item: |%s|",ItemList[ItemSet[client][2]]);
            W3SetVar(TheItemBoughtOrLost,itemID);
            W3CreateEvent(DoForwardClientBoughtItem,client);
        }
    }
    
    if(skill4_level > 0)
    {   
        // TEST FOR ITEM BASED ON SKILL LEVEL
        if(GetRandomFloat( 0.0, 1.0 ) <= SkillChance[skill4_level])
        {
            ItemSet[client][3] = GetItemByChance(client);
            
            new itemID = War3_GetItemIdByShortname(ItemList[ItemSet[client][3]]);
            PrintToConsole(client, "4 Gained item: |%s|",ItemList[ItemSet[client][3]]);
            W3SetVar(TheItemBoughtOrLost,itemID);
            W3CreateEvent(DoForwardClientBoughtItem,client);
        }
    }

}

GetItemByChance(client)
{
    new Float:chance = GetRandomFloat( 0.0, 1.0 );
    new itemnumber = 0;
    for(new x;x<=18;x++)
    {
        if(ItemChance[x] > chance)
        {
            itemnumber = x;
            break;
        }
        else
        {
            itemnumber = x;
        }
    }
    for(new x;x<=3;x++)
    {
        if(ItemSet[client][x] == itemnumber)
        {
            itemnumber = GetItemByChance(client);
            break;
        }
        
    }
    if (itemnumber == 0)
    {
        ankhcheck[client] = true;
    }
    
    return itemnumber;
}

public OnRaceChanged( client,oldrace,newrace )
{
    if( ValidPlayer( client ))
    {
        if( newrace == thisRaceID && ValidPlayer( client, true ) )
        {
            ResetItems(client);
            InitPassiveSkills(client);
        }
        else if (oldrace == thisRaceID)
        {
            W3ResetAllBuffRace( client, thisRaceID );
            War3_WeaponRestrictTo(client,thisRaceID,"");
            ResetItems(client);
        }
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        ResetItems(client);
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
}

    */