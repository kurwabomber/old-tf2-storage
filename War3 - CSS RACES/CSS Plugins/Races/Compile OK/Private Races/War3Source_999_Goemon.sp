/**
* File: War3Source_999_Goemon.sp
* Description: Avenga's Custom race for War3Source.
* Author(s): Remy Lebeau (modified from Cereal Killer's original Ninja)
*/

// War3Source stuff
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_INVIS, SKILL_LONGJUMP, SKILL_DODGE, ULT_TELEPORT;


new Float:InvisibilityAlpha[]={1.0,0.55,0.45,0.35,0.25,0.20};
new Float:SkillLongJump[]={0.0,2.5,3.0,4.5,5.0,5.5};
new Float:ImmuneChance[]={0.0, 0.04, 0.08, 0.12, 0.16, 0.21};
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
new Float:TeleportDistance[]={0.0, 500.0, 600.0, 700.0, 800.0, 850.0};


new TPFailCDResetToRace[MAXPLAYERSCUSTOM];
new TPFailCDResetToSkill[MAXPLAYERSCUSTOM];
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new Float:UltiCooldown = 30.0;

new String:teleportSound[256];



public Plugin:myinfo = 
{
	name = "War3Source Race - Goemon",
	author = "Remy Lebeau",
	description = "Avenga's custom race for War3Source",
	version = "1.0.2",
	url = "http://sevensinsgaming.com"
};

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Goemon [PRIVATE]","ninja2");
	
	SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Shinobi Shozoko","Ninja clothing helps you blend into the background",false,5);
	SKILL_LONGJUMP=War3_AddRaceSkill(thisRaceID,"Lunge","Jump further",false,5);
	SKILL_DODGE=War3_AddRaceSkill(thisRaceID,"Ninja Magic","Chance to gain ultimate immunity",false,5);
	ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Stealth jump","Teleport yourself",true,5);
	
	W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,5.0,_);
	
	War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
	HookEvent("round_end",RoundOverEvent);

	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	HookEvent("player_jump",PlayerJumpEvent);
}



public OnMapStart()
{
	strcopy(teleportSound,sizeof(teleportSound),"war3source/blinkarrival.mp3");
	War3_AddCustomSound(teleportSound);
}
	







/***************************************************************************
*
*
*				PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public InitPassiveSkills( client )
{

	new invis_level = War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS );
	War3_SetBuff(client,fInvisibilitySkill,thisRaceID,InvisibilityAlpha[invis_level]); 
	
	
	new dodge_level = War3_GetSkillLevel( client, thisRaceID, SKILL_DODGE );
	if (GetRandomFloat( 0.0, 1.0 ) < ImmuneChance[dodge_level])
	{
		War3_SetBuff( client, bImmunityUltimates, thisRaceID, true  );
		CPrintToChat (client, "{red}Immune to ultimates for this round!");
	}
	
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	
}


public OnRaceChanged( client,oldrace,newrace )
{
	if( newrace == thisRaceID && ValidPlayer( client, true ))
	{
		InitPassiveSkills(client);
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
		W3ResetAllBuffRace( client, thisRaceID );
		InitPassiveSkills(client);
	}
}




/***************************************************************************
*
*
*				ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/



public OnUltimateCommand(client,race,bool:pressed)
{
	if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
	{
		new skill_tp = War3_GetSkillLevel( client, thisRaceID, ULT_TELEPORT );
		if(skill_tp>0)
		{
				if(War3_SkillNotInCooldown(client,thisRaceID, ULT_TELEPORT,true)) //not in the 0.2 second delay when we check stuck via moving
				{
					new bool:success = Teleport(client,TeleportDistance[skill_tp]);
					if(success)
					{
						TPFailCDResetToRace[client]=thisRaceID;
						TPFailCDResetToSkill[client]=ULT_TELEPORT;
						
						War3_CooldownMGR(client,UltiCooldown,thisRaceID,ULT_TELEPORT,_,_);
					}
				}
		}
		else
		{
			PrintHintText(client, "Level your Ultimate first");
		}
	}
}






/***************************************************************************
*
*
*				EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new skill_long = War3_GetSkillLevel( client, race, SKILL_LONGJUMP );
		if( skill_long > 0 )
		{
			new Float:velocity[3] = { 0.0, 0.0, 0.0 };
			velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
			velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
			velocity[0] *= SkillLongJump[skill_long]*0.25;
			velocity[1] *= SkillLongJump[skill_long]*0.25;
			SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
		}
	}
}




/***************************************************************************
*
*
*				HELPER FUNCTIONS / TIMERS
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




bool:Teleport(client,Float:distance){
	if(!inteleportcheck[client])
	{
		
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
		
		new Float:distanceteleport=GetVectorDistance(startpos,endpos);
		if(distanceteleport<200.0){
			
			
			PrintHintText(client,"Distance too short.");
			return false;
		}
		GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);///get dir again
		ScaleVector(dir, distanceteleport-33.0);
		
		AddVectors(startpos,dir,endpos);
		emptypos[0]=0.0;
		emptypos[1]=0.0;
		emptypos[2]=0.0;
		
		endpos[2]-=30.0;
		getEmptyLocationHull(client,endpos);
		
		if(GetVectorLength(emptypos)<1.0){
			
			PrintHintText(client,"NoEmptyLocation");
			return false; //it returned 0 0 0
		}
		
		
		TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
		EmitSoundToAll(teleportSound,client);
		EmitSoundToAll(teleportSound,client);
		
		
		
		teleportpos[client][0]=emptypos[0];
		teleportpos[client][1]=emptypos[1];
		teleportpos[client][2]=emptypos[2];
		
		inteleportcheck[client]=true;
		CreateTimer(0.14,checkTeleport,client);
		
		
		
		
		
		
		return true;
	}

	return false;
}
public Action:checkTeleport(Handle:h,any:client){
	inteleportcheck[client]=false;
	new Float:pos[3];
	
	GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001)//he didnt move in this 0.1 second
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
		PrintHintText(client,"CantTeleportHere");
		War3_CooldownReset(client,TPFailCDResetToRace[client],TPFailCDResetToSkill[client]);
		
		
	}
	else{
		
		
		PrintHintText(client,"Teleported");
		
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
						//new ent;
						if(!TR_DidHit(_))
						{
							AddVectors(emptypos,pos,emptypos); ///set this gloval variable
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
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
	new Float:otherVec[3];
	new team = GetClientTeam(client);
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<350)
			{
				return true;
			}
		}
	}
	return false;
}             

	