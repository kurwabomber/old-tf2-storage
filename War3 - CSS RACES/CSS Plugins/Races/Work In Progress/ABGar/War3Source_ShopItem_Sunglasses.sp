#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

new shopItem;
new g_iFlashAlpha = -1;
new g_FlashOwner = -1;

public Plugin:myinfo = 
{
	name = "War3Source Shop Item - Sunglasses",
	author = "ABGar",
	description = "The Sunglasses Shop Menu item War3Source.",
	version = "1.0",
}

public OnPluginStart() 
{
	g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	HookEvent("player_blind",Event_Flashed);
	HookEvent("flashbang_detonate", Event_Flashbang_detonate);
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==99)
	{
		if(War3_GetGame()==Game_CS)
			shopItem=War3_CreateShopItem("Sunglasses","glasses","Protects from Flashbang",2,true);
	}
}

public Action:Event_Flashbang_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if(ValidPlayer(client))
		g_FlashOwner = client;
	else
		g_FlashOwner = -1;
		
	return Plugin_Continue;
}

public Action:Event_Flashed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (ValidPlayer(client) && g_iFlashAlpha != -1)
	{
		if(War3_GetOwnsItem(client,shopItem))
		{
			if(g_FlashOwner != client)
				SetEntDataFloat(client,g_iFlashAlpha,0.5);
		}
	}
}

public OnWar3EventDeath(client)
{
	if(War3_GetOwnsItem(client,shopItem))
		War3_SetOwnsItem(client,shopItem,false);
}