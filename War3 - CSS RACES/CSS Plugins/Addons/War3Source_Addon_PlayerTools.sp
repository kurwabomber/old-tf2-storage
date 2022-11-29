//  This Plugin does 2 things:
//  1. The bomb carrier will automatically drop the bomb after 15 seconds of roundtime if they haven't moved that round (in case they're AFK)
//  2. If a player gets stuck in a wall, they can type !stuck in chat, and then they'll be 'unstuck' by being bumped outside of the wall.


#pragma semicolon 1

#include <sdktools>
#include <cstrike>
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo =
{
	name = "Player Tool",
	author = "ABGar",
	description = "Force drop the bomb if the carrier is AFK, and allows players to become 'unstuck' by typing !stuck into chat",
	version = "1.0"
};


new g_iAccount;
new Float: g_Location[MAXPLAYERS][3];
new g_Money[MAXPLAYERS];


public OnPluginStart()
{
	HookEvent( "round_start", Event_RoundStart );
	g_iAccount = FindSendPropOffs( "CCSPlayer", "m_iAccount" );
	RegConsoleCmd("stuck", StuckCmd, "Usage: Type !stuck when stuck.");
}

//=======================================================================================
//                                 		AFK BOMB DROP
//=======================================================================================

public Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	for (new i = MaxClients; i >= 1; --i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetPlayerWeaponSlot(i,4) != -1)
		{
			new Float:PauseTime = GetConVarFloat(FindConVar("mp_freezetime"));
			GetClientAbsOrigin(i, g_Location[i]);
			g_Money[i]= GetEntData(i,g_iAccount);
			CreateTimer(15.0+PauseTime,CheckAgain,GetClientUserId(i));
		}
	}
}

public Action:CheckAgain(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetPlayerWeaponSlot(client,4) != -1)
	{
		new Float: NowLoc[3];
		new NowMoney = GetEntData(client,g_iAccount);
		GetClientAbsOrigin(client, NowLoc);
		if(NowMoney <= g_Money[client])
		{
			if(NowLoc[0] == g_Location[client][0] && NowLoc[1] == g_Location[client][1])
			{
				CS_DropWeapon(client, GetPlayerWeaponSlot(client,4),true,true);
			}
		}
	}
}

//=======================================================================================
//                                 		ANTI STUCK
//=======================================================================================

public Action:StuckCmd(client, Args)
{
	if(IsPlayerAlive(client))
	{
		if(AreYouStuck(client))
		{
			ReallyStuck(client, 0, 500.0, 0.0, 0.0);
		}
		else
			PrintToChat(client, "[SSG] You're not actually stuck");
	}
	else
		PrintToChat(client, "[SSG] You're not alive");
}

stock bool:AreYouStuck(client)
{
	decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
	GetClientAbsOrigin(client, vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterSolid);
	return TR_DidHit();
}

public bool:TraceEntityFilterSolid(entity, contentsMask) 
{
	return entity > 1;
}


stock ReallyStuck(client, testID, Float:X=0.0, Float:Y=0.0, Float:Z=0.0)
{
	decl Float:vecVelocity[3];
	decl Float:vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	
	vecVelocity[0] = X;
	vecVelocity[1] = Y;
	vecVelocity[2] = Z;
	
	SetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", vecVelocity);
	
	new Handle:data;
	CreateDataTimer(0.1, TimerWait, data); 
	WritePackCell(data, client);
	WritePackCell(data, testID);
	WritePackFloat(data, vecOrigin[0]);
	WritePackFloat(data, vecOrigin[1]);
	WritePackFloat(data, vecOrigin[2]);
}

public Action:TimerWait(Handle:timer, Handle:data)
{	
	decl Float:vecOrigin[3];
	decl Float:vecOriginAfter[3];
	
	ResetPack(data, false);
	new client = ReadPackCell(data);
	new testID = ReadPackCell(data);
	vecOrigin[0] = ReadPackFloat(data);
	vecOrigin[1] = ReadPackFloat(data);
	vecOrigin[2] = ReadPackFloat(data);
	
	GetClientAbsOrigin(client, vecOriginAfter);
	if(GetVectorDistance(vecOrigin, vecOriginAfter) < 10.0)
	{
		if(testID == 0)
			ReallyStuck(client, 1, 0.0, 0.0, -500.0);
		else if(testID == 1)
			ReallyStuck(client, 2, -500.0, 0.0, 0.0);
		else if(testID == 2)
			ReallyStuck(client, 3, 0.0, 500.0, 0.0);
		else if(testID == 3)
			ReallyStuck(client, 4, 0.0, -500.0, 0.0);
		else if(testID == 4)
			ReallyStuck(client, 5, 0.0, 0.0, 300.0);
		else if(!FixPlayerPosition(client))
			PrintToChat(client,"[SSG] Sorry, we can't fix your position");
		else
		{
			PrintToChat(client, "[SSG] You're not stuck anymore");
		}
	}
	else
		PrintToChat(client, "[SSG] You're not actually stuck");
}


bool:FixPlayerPosition(client)
{
	new Float:pos_Z = 0.1;
	
	while(pos_Z <= 200 && !TryFixPosition(client, 10.0, pos_Z))
	{	
		pos_Z = -pos_Z;
		if(pos_Z > 0.0)
			pos_Z += 20;
	}
	
	return !AreYouStuck(client);
}

bool:TryFixPosition(client, Float:Radius, Float:pos_Z)
{
	new Float:pixels = FLOAT_PI*2*Radius;
	decl Float:compteur;
	decl Float:vecPosition[3];
	decl Float:vecOrigin[3];
	decl Float:vecAngle[3];
	new coups = 0;
	
	GetClientAbsOrigin(client, vecOrigin);
	GetClientEyeAngles(client, vecAngle);
	vecPosition[2] = vecOrigin[2] + pos_Z;

	while(coups < pixels)
	{
		vecPosition[0] = vecOrigin[0] + Radius * Cosine(compteur * FLOAT_PI / 180);
		vecPosition[1] = vecOrigin[1] + Radius * Sine(compteur * FLOAT_PI / 180);

		TeleportEntity(client, vecPosition, vecAngle, NULL_VECTOR);
		if(!AreYouStuck(client))
			return true;
		
		compteur += 360/pixels;
		coups++;
	}
	
	TeleportEntity(client, vecOrigin, vecAngle, NULL_VECTOR);
	if(Radius <= 200)
		return TryFixPosition(client, Radius + 20, pos_Z);
	
	return false;
}