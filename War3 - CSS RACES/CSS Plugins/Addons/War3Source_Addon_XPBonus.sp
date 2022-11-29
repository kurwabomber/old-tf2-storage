#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="War3Source Addons for XP Bonus at night",
	author="Namolem - Fixed by Glider",
	description="War3Source Addon Plugins",
	version="1.0",
	url="http://arsenall.net/"
};

new Float:XP_Bonus;
new bool:XP_Bonus_Manual;
new Handle:Cvar_XP_Bonus = INVALID_HANDLE;
new Handle:Cvar_XP_Bonus_Manual = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("round_start",RoundStartEvent);
	Cvar_XP_Bonus = CreateConVar("war3_xp_bonus", "1.5", "XP Multiplyer from 2:00 till 11:00 or always, if war3_xp_bonus_manual set to 1",  FCVAR_PLUGIN|FCVAR_NOTIFY);
	Cvar_XP_Bonus_Manual = CreateConVar(
							"war3_xp_bonus_manual", 
							"0", 
							"XP Multiplyer from 1:00 till 11:00 GMT+3",  
							FCVAR_PLUGIN|FCVAR_NOTIFY,
							true, 0.0,
							true, 1.0);
	HookConVarChange(Cvar_XP_Bonus, XP_Bonus_Changed);
	HookConVarChange(Cvar_XP_Bonus_Manual,XP_Bonus_Changed);
}
public XP_Bonus_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	XP_Bonus = GetConVarFloat(Cvar_XP_Bonus);
	XP_Bonus_Manual = GetConVarBool(Cvar_XP_Bonus_Manual);
}
public OnWar3Event(W3EVENT:event,client)
{
	if (event == OnPreGiveXPGold && XP_Bonus != 1.0)
	{
		W3SetVar(EventArg2,RoundToNearest( float(W3GetVar(EventArg2)) * XP_Bonus ));
	}
}
public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (XP_Bonus_Manual == true)
	{
		XP_Bonus = GetConVarFloat(Cvar_XP_Bonus);
		return;
	}
	decl String:hours[10];
	FormatTime(hours,10,"%H",GetTime());
	new iHours = StringToInt(hours);
	if (iHours >= 2 && iHours <= 11)
	{
		XP_Bonus = GetConVarFloat(Cvar_XP_Bonus);
	}
	else
	{
		XP_Bonus = 1.0;
	}
}