/**
* File: War3Source_FarSeer.sp
* Description: The Far Seer race for War3Source.
* Author(s): Cereal Killer 
*/
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>
new thisRaceID;
new Float:height=150.0;
new Float:life=10.0;
new Float:radius=200.0;
new color1[4]={216,175,14,255};
new color2[4]={50,50,0,255};
// new color3[4]={0,0,255,255};
new Float:wardlocation[MAXPLAYERS][20][3];
new wardnumber[MAXPLAYERS]=0;
new Float:angle12[MAXPLAYERS][20];
// new wardshouldbeon[MAXPLAYERS][20];
public Plugin:myinfo = 
{
	name = "War3Source Race - Ward Man",
	author = "Cereal Killer",
	description = "Far Seer for War3Source.",
	version = "1.0.6.4",
	url = "http://warcraft-source.net/"
};
new BeamSprite,HaloSprite;
// new StarSprite,TSprite,CTSprite,BurnSprite,g_iExplosionModel,g_iSmokeModel;
new WARDS;
new WARDSbeam;
public OnPluginStart(){
	CreateTimer(0.1, RadarWard,_,TIMER_REPEAT);
	HookEvent("round_start",RoundStartEvent);
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)){
			for(new j=1;j<20;j++){
				wardlocation[i][j][0]=0.0;
				wardlocation[i][j][1]=0.0;
				wardlocation[i][j][2]=0.0;
			}
		}
	}
}
public OnMapStart(){
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	//StarSprite=PrecacheModel("materials/effects/fluttercore.vmt");
	//TSprite=PrecacheModel("VGUI/gfx/VGUI/guerilla.vmt");
	//CTSprite=PrecacheModel("VGUI/gfx/VGUI/gign.vmt");
	//BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
	//g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
	//g_iSmokeModel     = PrecacheModel("materials/effects/fire_cloud2.vmt");
	WARDSbeam = PrecacheModel("materials/sprites/laser.vmt");
}
public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast){
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)){
			for(new j=1;j<20;j++){
				wardlocation[i][j][0]=0.0;
				wardlocation[i][j][1]=0.0;
				wardlocation[i][j][2]=0.0;
			}
		}
	}
}
public OnWar3PluginReady(){
	
		thisRaceID=War3_CreateNewRace("WardMan","wardman");
		WARDS=War3_AddRaceSkill(thisRaceID,"Place Wards EVERYWHERE(+ability)","place a ward",false,25);
		War3_CreateRaceEnd(thisRaceID);
	
}
public OnWar3EventSpawn(client){
}

public OnAbilityCommand(client,ability,bool:pressed){	
if (ability==0){
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
			new skill_level=War3_GetSkillLevel(client,thisRaceID,WARDS);
			if(skill_level>0){
				if(War3_SkillNotInCooldown(client,thisRaceID,WARDS,false)){
					if(wardnumber[client]<20){
						if(!Silenced(client)){
							War3_CooldownMGR(client,1.0,thisRaceID,WARDS,_,_);
							new Float:startpos[3];
							startpos[2]+=15.0;
							GetClientAbsOrigin(client,startpos);
							new Float:highpos[3];
							highpos=startpos;
							highpos[2]=startpos[2]+height;
							TE_SetupBeamPoints(startpos, highpos,WARDSbeam, HaloSprite , 0, 8, life, 10.0, 10.0, 5, 0.0, color1, 70); 
							TE_SendToAll();
							TE_SetupBeamRingPoint(startpos, radius*2,radius*2+1.0, BeamSprite,HaloSprite,0,15,life,5.0,0.0,color2,10,0);
							TE_SendToAll();
							wardlocation[client][wardnumber[client]][0]=startpos[0];
							wardlocation[client][wardnumber[client]][1]=startpos[1];
							wardlocation[client][wardnumber[client]][2]=startpos[2];
							PrintHintText(client, "ward number %d",wardnumber[client]);
							new wardnumbah=wardnumber[client];
							CreateTimer(life, warddisapear,wardnumbah);
							wardnumber[client]++;
						}
					}
				}
			}
		}
	}
}
public Action:warddisapear(Handle:timer, any:wardnumbah) {
	for(new client=1;client<=MaxClients;client++){
		if(War3_GetRace(client)==thisRaceID){
			if(ValidPlayer(client,true)){
				wardlocation[client][wardnumbah][0]=0.0;
			}
		}
	}
}
public Action:RadarWard(Handle:timer) {
	for(new number=0;number<20;number++){
		for(new client=1;client<=MaxClients;client++){
			if(War3_GetRace(client)==thisRaceID){
				if(ValidPlayer(client,true)){
					if(wardlocation[client][number][0]==0.0){
					}
					else {
						new Float:pos1[3];
						pos1[2]=wardlocation[client][number][2];
						pos1[0]=((Sine(angle12[client][number])*radius)+wardlocation[client][number][0]);
						pos1[1]=((Cosine(angle12[client][number])*radius)+wardlocation[client][number][1]);
						new Float:startpos[3];
						startpos[0]=wardlocation[client][number][0];
						startpos[1]=wardlocation[client][number][1];
						startpos[2]=wardlocation[client][number][2];
						if(GetClientTeam(client)==2){
							new color4[4]={255,0,0,255};
							TE_SetupBeamPoints(startpos, pos1,BeamSprite, HaloSprite , 0, 8, 0.15, 10.0, 10.0, 5, 0.0, color4, 70); 
							TE_SendToAll();
						}
						if(GetClientTeam(client)==3){
							new color4[4]={0,0,255,255};
							TE_SetupBeamPoints(startpos, pos1,BeamSprite, HaloSprite , 0, 8, 0.15, 10.0, 10.0, 5, 0.0, color4, 70); 
							TE_SendToAll();
						}
						angle12[client][number]+=15.0;
					}
				}
			}
		}
	}
}