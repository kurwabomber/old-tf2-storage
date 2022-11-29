/**
* File: War3Source_Addon_VIPBenefits.sp
* Description: VIP Addon for War3Source.
* Controlled by access flags - you need to specify which flag receives the donator benefits using <INSERT CVAR HERE>
* Author(s): Remy Lebeau
*/


#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
    
public Plugin:myinfo = 
{
    name = "War3Source Addon - VIP Benefits",
    author = "Remy Lebeau",
    description = "VIP Benefits Addon for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};
/*
new Handle:g_hCvarVIPFlag = INVALID_HANDLE;
new Handle:g_hCvarVIPXPBonus = INVALID_HANDLE;
new Handle:g_hCvarVIPGoldBonus = INVALID_HANDLE;
new bool:g_bCustomModel = false;
new Float:g_fXPBonus;
new g_iGoldBonus;
new String:g_sVIPFlag[32];;

new AdminFlag:g_flagVIPFlag;
*/

public OnMapStart()
{
/*
    g_hCvarCustomModel = CreateConVar("war3_lara_custom_model", "0", "Enable/Disable custom model for Lara Croft War3Source race");
	HookConVarChange(g_hCvarCustomModel, OnConVarChange);
    FindFlagByChar(g_sVIPFlag[0], g_flagVIPFlag);
*/
}

/*
public OnConVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetConVars();
}

public OnConfigsExecuted()
{
	GetConVars();
}

public GetConVars()
{
	g_bCustomModel = GetConVarBool(g_hCvarCustomModel);	
}
*/

public OnWar3Event(W3EVENT:event,client)
{
    if(event==OnPreGiveXPGold)
    {
        new AdminId:admin = GetUserAdmin(client);
        if(admin == INVALID_ADMIN_ID)
        {
        }
        else
        {
            new AdminFlag:flag;
            if (!FindFlagByChar('o', flag))
            {
                LogError("ERROR on donator flag check");
            }
            else
            {
                if (GetAdminFlag(admin, flag))
                {
                    
                    LogMessage("Normal XP |%d|",W3GetVar(EventArg2));
                    LogMessage("Normal Gold |%d|",W3GetVar(EventArg3));
                    W3SetVar(EventArg2,RoundToFloor(W3GetVar(EventArg2)*1.05));
                    W3SetVar(EventArg3,RoundToFloor(W3GetVar(EventArg3)*1.5));
                    LogMessage("Bonus XP |%d|",W3GetVar(EventArg2));
                    LogMessage("Bonus Gold |%d|",W3GetVar(EventArg3));
                                    
                }
            }
        }
    }
}


