#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - FU P90TWO",
	author = "ABGar",
	description = "The FU P90TWO race for War3Source.",
	version = "1.0",
	// Little Napa's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5229-fu-p90two/page-2?hl=napa#entry64858
}

new thisRaceID;

new SKILL_FAST, SKILL_TWO, SKILL_SLAP, ULT_TELE;

// SKILL_FAST
new Float:RunFast[]={1.0,1.15,1.2,1.25,1.3};

// SKILL_TWO
new DoubleHealth[]={0,7,15,30,60};

// SKILL_SLAP
new CurrentSlaps[MAXPLAYERSCUSTOM];
new bool:Slapped[MAXPLAYERSCUSTOM];

// ULT_TELE
new Float:TeleRD[]={0.0,600.0,700.0,850.0,1000.0};
new Float:teleCD[]={0.0,15.0,12.0,9.0,6.0};
new bool:inteleportcheck[MAXPLAYERSCUSTOM];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERSCUSTOM][3];
new Float:teleportpos[MAXPLAYERSCUSTOM][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:teleport_sound[]="war3source/blinkarrival.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("FU P90TWO [PRIVATE]","fup902");
	SKILL_FAST = War3_AddRaceSkill(thisRaceID,"|F|ast","Speed (passive)",false,4);
	ULT_TELE = War3_AddRaceSkill(thisRaceID,"|U|ltimate Teleport","Teleport (+ultimate)",true,4);
	SKILL_SLAP = War3_AddRaceSkill(thisRaceID,"|P90| Slaps","Slaps anyone holding a P90 (+ability)",false,4);
	SKILL_TWO=War3_AddRaceSkill(thisRaceID,"|TWO| Doubles Health","Bonus Health (+ultimate)",false,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_FAST,fMaxSpeed,RunFast);
	War3_AddSkillBuff(thisRaceID,SKILL_TWO,iAdditionalMaxHealth,DoubleHealth);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		if (ValidPlayer(client,true))
        {
			InitPassiveSkills(client);
		}
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	CurrentSlaps[client]=1;
	Slapped[client]=false;
}

public OnMapStart()
{
	War3_PrecacheSound(teleport_sound);
}

public OnPluginStart()
{
	CreateTimer(25.0, AddSlap,_,TIMER_REPEAT);
}

/* *************************************** (SKILL_SLAP) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new SlapLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SLAP);
		if(SlapLevel>0)
		{
			if(CurrentSlaps[client]>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_SLAP,false,true,true))
				{
					StartSlap(client);
					War3_CooldownMGR(client,1.0,thisRaceID,SKILL_SLAP,true,false);
				}
			}
			else
				PrintHintText(client,"You don't have anymore slaps left yet");
		}
		else
			PrintHintText(client,"Level your Slap first");
	}
}


public StartSlap(client)
{
	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
	{
		for (new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				if(Client_HasWeapon(i,"weapon_p90"))
				{
					new SlapDamage = (GetClientTeam(i)==GetClientTeam(client)) ? 5 : 10;
					SlapPlayer(i, SlapDamage, true);
					PrintHintText(i,"%N:  Slap my Bitch up",client);
					Slapped[client]=true;
				}
			}
		}
		if(Slapped[client])
		{
			CurrentSlaps[client]--;
			PrintHintText(client,"You have %i slaps left",CurrentSlaps[client]);
			Slapped[client]=false;
		}
		else
		{
			PrintHintText(client,"No one is holding a P90.  You still have %i slaps left",CurrentSlaps[client]);
		}
	}
}

public Action:AddSlap(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i,true) && War3_GetRace(i)==thisRaceID)
        {
			new SlapLevel=War3_GetSkillLevel(i,thisRaceID,SKILL_SLAP);
			if(SlapLevel>0)
			{
				if(CurrentSlaps[i]<SlapLevel)
				{
					CurrentSlaps[i]++;
					PrintHintText(i,"YAY you get another slap.  You now have %i slaps",CurrentSlaps[i]);
				}
			}
        }
    }     
}

/* *************************************** (ULT_TELE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
        if(SkillAvailable(client,thisRaceID,ULT_TELE,true,true,true))
        {
            new ult_teleport=War3_GetSkillLevel(client,thisRaceID,ULT_TELE);
            if(ult_teleport>0)
                TeleportPlayerView(client,TeleRD[ult_teleport]);
            else
                W3MsgUltNotLeveled(client);
        }
    }
}
 
bool:TeleportPlayerView(client,Float:distance)
{
    if(client>0)
    {
        if(IsPlayerAlive(client))
        {
            new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_TELE);
            War3_CooldownMGR(client,teleCD[ult_level],thisRaceID,ULT_TELE,_,_);
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
           
            if(enemyImmunityInRange(client,endpos))
            {
                W3MsgEnemyHasImmunity(client);
                War3_CooldownReset(client,thisRaceID,ULT_TELE);
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
            if(GetVectorLength(emptypos)<1.0)
            {
                new String:buffer[100];
                Format(buffer, sizeof(buffer), "", "NoEmptyLocation", client);
                PrintHintText(client,buffer);
                War3_CooldownReset(client,thisRaceID,ULT_TELE);
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
 
public Action:checkTeleport(Handle:h,any:client)
{
    inteleportcheck[client]=false;
    new Float:pos[3];  
    GetClientAbsOrigin(client,pos);
   
    if(GetVectorDistance(teleportpos[client],pos)<0.001)
    {
        TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
        War3_CooldownReset(client,thisRaceID,ULT_TELE);
    }
}
 
public bool:AimTargetFilter(entity,mask)
{
    return !(entity==ClientTracer);
}
 
public bool:getEmptyLocationHull(client,Float:originalpos[3])
{
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
    if(entityhit == data )
    {
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
 
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
        {
            GetClientAbsOrigin(i,otherVec);
            if(GetVectorDistance(playerVec,otherVec)<300){
                return true;
            }
        }
    }
    return false;
}
