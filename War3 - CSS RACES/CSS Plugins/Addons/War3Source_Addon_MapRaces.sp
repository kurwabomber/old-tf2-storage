#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#define TIMER_INTERVAL 3.0
new bool:IsRaceRestricted[MAXRACES];
public Plugin:myinfo = 
{
	name = "War3Source Addon - Race Map Restrictions",
	author = "DonRevan",
	description = "Restricts a race for a specific map",
	version = "1.0",
	url = "http://www.wcs-lagerhaus.de/"
};

public OnPluginStart() {
	RegAdminCmd("war3_reloadmapcfg", Command_ForceReload, ADMFLAG_RCON, "Forces a reload on the current race map config");
	CreateFolder("war3source/"); //asum. the cstrike/cfg. folder exists lol :S
	CreateFolder("war3source/maps/");

	new String:name[PLATFORM_MAX_PATH];
	new Handle:adtMaps = CreateArray(16, 0);
	new serial = -1;
	ReadMapList(adtMaps, serial, "allexistingmaps__", MAPLIST_FLAG_MAPSFOLDER|MAPLIST_FLAG_NO_DEFAULT);
	new mapcount = GetArraySize(adtMaps);
	if (mapcount > 0) for (new i = 0; i < mapcount; i++) {
		GetArrayString(adtMaps, i, name, sizeof(name));
		WriteConfigFile(name);
	}
}


public OnW3Denyable(W3DENY:event, client)
{
    if(event==DN_CanSelectRace)
    {
        new raceid=W3GetVar(EventArg1);
        if(IsRaceRestricted[raceid]==true) 
        {
            new String:racename[32];
            War3_GetRaceName(raceid,racename,sizeof(racename));
            PrintToChat(client,"\x04[War3Source] \x01Sorry, but \x03%s \x01is currently restricted on this map!",racename);
            W3Deny();
        }
	}        
       
}

public Action:Command_ForceReload(client, args)
{
	PrintToServer("[War3Source] Forcing a race map config reload...");
	ResetRestrictions();
	ExecMapCfgFile();
}

public OnConfigsExecuted() {
	ResetRestrictions();
	ExecMapCfgFile();
}

ResetRestrictions() {
	new racelist[MAXRACES];
	new raceactive=W3GetRaceList(racelist);
	for(new i=0;i<raceactive;i++) {
		IsRaceRestricted[i]=false;
	}
}

ExecMapCfgFile() {
	new String:W3_FileName[PLATFORM_MAX_PATH];
	new String:name[PLATFORM_MAX_PATH];
	GetCurrentMap(name, sizeof(name));
	PrintToServer("[War3Source] Loading race map config file...(%s.cfg)", name);
	Format(W3_FileName, sizeof(W3_FileName), "cfg/war3source/maps/%s.cfg",name); 
	if(!FileExists(W3_FileName))
	War3_LogError("Failed to load file race map config file!(%s.cfg)", name);
	else {
		new Handle:filehandle = INVALID_HANDLE;
		filehandle = OpenFile(W3_FileName, "r");
		if(filehandle != INVALID_HANDLE) {
			decl String:buffer[128];
			new line=0;
			while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle, buffer, sizeof(buffer)))
			{
				//PrintToServer("[War3Source] Found Line %i (%s)",line,buffer);
				TrimString(buffer);
				new raceid = War3_GetRaceIDByShortname(buffer);
				if(raceid>0) {
					IsRaceRestricted[raceid]=true;
					PrintToServer("[War3Source] Restricted %s for map %s",buffer,name);
				}
				else {
					if(strlen(buffer)>0 &&  (StrEqual(buffer[0],"/",false)&&StrEqual(buffer[1], "/", false))==false && line>0)
					War3_LogError("[War3Source] Error in file %s : found race(%s) but cannot resolve the raceid!",name,buffer);
				}
				line++;
			}
			CloseHandle(filehandle);
		}
		else
		War3_LogError("Failed to read file race map config file!(%s.cfg)", name);
	}
}

CreateFolder(const String:filename[]) {
	new String:dirname[PLATFORM_MAX_PATH];
	Format(dirname, sizeof(dirname), "cfg/%s", filename);
	CreateDirectory(
		dirname,  
		FPERM_U_READ + FPERM_U_WRITE + FPERM_U_EXEC + 
		FPERM_G_READ + FPERM_G_WRITE + FPERM_G_EXEC + 
		FPERM_O_READ + FPERM_O_WRITE + FPERM_O_EXEC
	);
}

WriteConfigFile(const String:filename[]) {
	new String:strcfgFileName[PLATFORM_MAX_PATH];
	new Handle:fileHandle = INVALID_HANDLE;
	//CalculateFileName(strcfgFileName, filename);
	Format(strcfgFileName, sizeof(strcfgFileName), "cfg/war3source/maps/%s.cfg",filename); 
	if (FileExists(strcfgFileName)) return;
	fileHandle = OpenFile(strcfgFileName, "w+");
	if (fileHandle != INVALID_HANDLE) {
		WriteFileLine(fileHandle, "// www.war3source.com - Race Map Restrictions :: config for: %s", filename);
		CloseHandle(fileHandle);
	}
}