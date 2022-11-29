/**
* File: War3Source_Addon_PrivateAccess.sp
* Description: Controls the access to private races
* Author(s): Necavi, Remy Lebeau
* Current functions: 	Allows / Disallows access by specific people to private races
*						Creates a brief effect over private races when they spawn
* 						Requires - config/war3souce_privateaccess.cfg
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo = 
{
	name = "War3Source Addon - Private Access TEST - DENY UNDEAD",
	author = "Necavi and Remy Lebeau",
	description = "Controls access to private races",
	version = "3.0.0",
	url = "http://necavi.org/"
};


public OnPluginStart()
{

}
public OnW3Denyable(W3DENY:event, client)
{
	if(event==DN_CanSelectRace)
	{
		PrintToChat(client, "EventArg1 = |%d|",W3GetVar(EventArg1));
		PrintToChat (client,"Here 1");
			
			
		
	}
	if(event==DN_CanBuyItem1)
	{
		PrintToChat(client, "EventArg1 (SHOP) = |%d|",W3GetVar(EventArg1));	
		new item = W3GetVar(EventArg1);
		decl String:itemname[64];
		W3GetItemShortname(item,itemname,sizeof(itemname));
		if(StrEqual(itemname, "lace", false))
		{
			PrintToChat(client, "You may not buy necklace this round.");
			W3Deny();
		}
		else if(StrEqual(itemname, "shield", false))
		{
			PrintToChat(client, "You may not buy shield this round.");
			W3Deny();
		}
	}
}


