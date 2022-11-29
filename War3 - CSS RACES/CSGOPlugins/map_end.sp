/*
	end_sound.sp

	Description:
	Plays music/sound at the end of the map.

	Versions:
	1.3
	* Initial Release
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <emitsoundany>

#define PLUGIN_VERSION "1.2m"
#define MAX_FILE_LEN 255

public Plugin:myinfo = 
{
	name = "Map End Music/Sound",
	author = "TechKnow, meng, artful",
	description = "Plays Music/sound at the end of the map.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new String:g_sCurrSound[MAX_FILE_LEN];

public OnPluginStart()
{
	CreateConVar("sm_MapEnd_Sound_version", PLUGIN_VERSION, "MapEnd_Sound_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("cs_win_panel_match", OnMatchEnd);
}

public OnMapStart()
{
	if (DirExists("sound/mapend"))
	{
		new Handle:dir = OpenDirectory("sound/mapend");
		new Handle:soundsArray = CreateArray(MAX_FILE_LEN);
		new FileType:type;
		decl String:file[MAX_FILE_LEN];
		while (ReadDirEntry(dir, file, sizeof(file), type))
			if (type == FileType_File)
				PushArrayString(soundsArray, file);
		CloseHandle(dir);
		new arraySize = GetArraySize(soundsArray);
		if (arraySize)
		{
			GetArrayString(soundsArray, GetRandomInt(0, arraySize-1), file, sizeof(file));
			Format(g_sCurrSound, sizeof(g_sCurrSound), "sound/mapend/%s", file);
			AddFileToDownloadsTable(g_sCurrSound);
			Format(g_sCurrSound, sizeof(g_sCurrSound), "mapend/%s", file);
			PrecacheSoundAny(g_sCurrSound, true);
		}
		else
			LogError("No sound files found in sound/mapend.");
		CloseHandle(soundsArray);
	}
	else
		LogError("Directory sound/mapend does not exist.");
}

public OnMatchEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			EmitSoundToClientAny(i, g_sCurrSound);
}