/**
* File: War3Source_999_UMPster.sp
* Description: UMPster Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"


new thisRaceID;
new SKILL_LEECH, SKILL_SPEED, SKILL_AMMO, ULT_TELEPORT;

#define WEAPON_RESTRICT "weapon_knife,weapon_ump45"
#define WEAPON_GIVE "weapon_ump45"

public Plugin:myinfo = 
{
    name = "War3Source Race - UMPster",
    author = "Remy Lebeau",
    description = "Kablamo's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new Float:g_fAttackSpeed[] = { 1.0, 1.05, 1.1, 1.15, 1.2 };
new Float:VampirePercent[] = {0.0, 0.05, 0.10, 0.15, 0.20};
new g_iAmmo[] = {25, 30, 35, 40, 45};


//Mass Teleport
new Float:TeleRD[]={0.0,800.0,825.0,850.0,875.0,900.0,925.0,950.0,975.0,1000.0};
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:teleport_sound[]="war3source/archmage/teleport.wav";

public OnWar3PluginReady()
{

    thisRaceID=War3_CreateNewRace("UMPster [PRIVATE]","umpster");
    
    SKILL_LEECH=War3_AddRaceSkill(thisRaceID,"Tend to own wounds","Vampiric Aura",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Fully Automatic","Increases attack speed",false,4);
    SKILL_AMMO=War3_AddRaceSkill(thisRaceID,"Extended Mag","Increases clip size by 5 bullets each level",false,4);

    ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Know when to retreat","Teleport (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, VampirePercent);
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fAttackSpeed, g_fAttackSpeed );
    
}


public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{
    HookEvent( "weapon_reload", WeaponReloadEvent );
    War3_AddCustomSound(teleport_sound);
    PrecacheSound(teleport_sound,false);
}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public InitPassiveSkills( client )
{
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    CreateTimer( 0.5, GiveWep, client );
    CreateTimer( 1.5, SetWepAmmo, client );

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills( client );
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        InitPassiveSkills( client );
    }
}




public OnSkillLevelChanged(client,race,skill,newskilllevel )
{
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
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




public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true)){
		if(!Silenced(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TELEPORT,true)){
				new ult_teleport=War3_GetSkillLevel(client,thisRaceID,ULT_TELEPORT);
				if(ult_teleport>0){
					TeleportPlayerView(client,TeleRD[ult_teleport]);
				}
				else
				{
					PrintHintText(client, "Level your Teleport first");
				}
			}
		}	
		else
		{
			PrintHintText(client, "You are silenced!");
		}
	}
}

bool:TeleportPlayerView(client,Float:distance)
{
	if(client>0){
		if(IsPlayerAlive(client)){
			new Float:angle[3];
			GetClientEyeAngles(client,angle);
			new Float:endpos[3];
			new Float:startpos[3];
			GetClientEyePosition(client,startpos);
			new Float:dir[3];
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(dir, distance);
			AddVectors(startpos, dir, endpos);
			GetClientAbsOrigin(client,oldpos[client]);
			ClientTracer=client;
			TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
			TR_GetEndPosition(endpos);			
			
			if(enemyImmunityInRange(client,endpos)){
				W3MsgEnemyHasImmunity(client);
				return false;
			}
			distance=GetVectorDistance(startpos,endpos);
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(dir, distance-33.0);
			AddVectors(startpos,dir,endpos);
			emptypos[0]=0.0;
			emptypos[1]=0.0;
			emptypos[2]=0.0;
			endpos[2]-=30.0;
			getEmptyLocationHull(client,endpos);
			if(GetVectorLength(emptypos)<1.0){
				//new String:buffer[100];
				//Format(buffer, sizeof(buffer), "%T", "NoEmptyLocation", client);
				PrintHintText(client, "No Empty Location");
				return false;
			}
			TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
			EmitSoundToAll(teleport_sound,client);	
			teleportpos[client][0]=emptypos[0];
			teleportpos[client][1]=emptypos[1];
			teleportpos[client][2]=emptypos[2];
			inteleportcheck[client]=true;
			CreateTimer(0.14,checkTeleport,client);			
			return true;
		}
	}
	return false;
}

public Action:checkTeleport(Handle:h,any:client){
	inteleportcheck[client]=false;
	new Float:pos[3];	
	GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001){
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
	}
	else
	{	
		War3_CooldownMGR(client,20.0,thisRaceID,ULT_TELEPORT);
	}
}
public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}

public bool:getEmptyLocationHull(client,Float:originalpos[3]){
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);
	new absincarraysize=sizeof(absincarray);
	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						new Float:pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);
						
						TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
						if(TR_DidHit(_)){
						}
						else
						{
							AddVectors(emptypos,pos,emptypos);
							limit=-1;
							break;
						}
					
						if(limit--<0){
							break;
						}
					}
					
					if(limit--<0){
						break;
					}
				}
			}
			
			if(limit--<0){
				break;
			}
			
		}
		
	}

} 

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data ){
		return false;
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false;
	}
	return true;
}


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	new Float:otherVec[3];
	new team = GetClientTeam(client);

	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates)){
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<300){
				return true;
			}
		}
	}
	return false;
}             

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

    

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_GiveWeapon(client, WEAPON_GIVE, true); 
    }
}


public Action:SetWepAmmo( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        new level = War3_GetSkillLevel(client, race, SKILL_AMMO);
        Client_SetWeaponAmmo(client, "weapon_ump45", 100,0,g_iAmmo[level],0);
    }
}


public WeaponReloadEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        new skill = War3_GetSkillLevel( client, race, SKILL_AMMO );
        if( skill > 0 )
        {
            CreateTimer( 3.5, SetWepAmmo, client );
        }
    }
}

