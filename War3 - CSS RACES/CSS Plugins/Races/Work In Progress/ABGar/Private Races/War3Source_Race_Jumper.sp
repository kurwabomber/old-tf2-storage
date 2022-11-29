#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Jumper",
	author = "ABGar",
	description = "The Jumper race for War3Source.",
	version = "1.0",
	// Ragnar's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5233-jumper-private/
}

new thisRaceID;

new SKILL_JUMPZ, SKILL_STRENGTH, SKILL_FAZED, ULT_PUSH;

// SKILL_JUMPZ
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new Float:TeleRD[]={0.0,150.0,175.0,200.0,250.0};
new Float:teleCD[]={0.0,5.0,4.0,3.0,2.0};
new bool:inteleportcheck[MAXPLAYERS];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:TeleSound[]="war3source/blinkarrival.wav";

// SKILL_STRENGTH
new Strength[]={0,20,40,50,60};

// SKILL_FAZED
new Float:InvisDuration[5]={0.0,3.0,6.0,9.0,12.0};
new bool:InInvis[MAXPLAYERSCUSTOM];
new Handle:InvisEndTimer[MAXPLAYERSCUSTOM];
new String:InvisOn[]="npc/scanner/scanner_nearmiss1.wav";
new String:InvisOff[]="npc/scanner/scanner_nearmiss2.wav";

// ULT_PUSH
new Float:PushCD[]={0.0,60.0,40.0,20.0};
new bool:bPush[MAXPLAYERSCUSTOM];
new String:PushSound[]="npc/zombie/zombie_hit.wav";

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Jumper [PRIVATE]","jumper");
	SKILL_JUMPZ = War3_AddRaceSkill(thisRaceID,"Jumpz","Short range teleport (+ability)",false,4);
	SKILL_STRENGTH = War3_AddRaceSkill(thisRaceID,"Strength","Additional health (passive)",false,4);
	SKILL_FAZED = War3_AddRaceSkill(thisRaceID,"Fazed","Invisibility for a short time (+ability1)",false,4);
	ULT_PUSH=War3_AddRaceSkill(thisRaceID,"Push","Push the knife deep into your enemy with your stored power (+ultimate)",false,3);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_STRENGTH,iAdditionalMaxHealth,Strength);
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
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife");
}

public OnMapStart()
{
	War3_PrecacheSound(TeleSound);
	War3_PrecacheSound(InvisOn);
	War3_PrecacheSound(InvisOff);
	War3_PrecacheSound(PushSound);
}

/* *************************************** (SKILL_JUMPZ) *************************************** */
bool:TeleportPlayerView(client,Float:distance)
{
    if(client>0)
    {
        if(IsPlayerAlive(client))
        {
            new ult_level=War3_GetSkillLevel(client,thisRaceID,SKILL_JUMPZ);
            War3_CooldownMGR(client,teleCD[ult_level],thisRaceID,SKILL_JUMPZ,_,_);//Cooldown setting goes here, or people can use scrollwheel binds to cross the entire map. Resets are then placed at any failure state (normally you could just return false and reset if so outside the function, but teleports rely on timers.
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
                War3_CooldownReset(client,thisRaceID,SKILL_JUMPZ);
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
                War3_CooldownReset(client,thisRaceID,SKILL_JUMPZ);
                return false;
            }
            TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
            EmitSoundToAll(TeleSound,client); 
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
        War3_CooldownReset(client,thisRaceID,SKILL_JUMPZ);
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
        if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Skills))
        {
            GetClientAbsOrigin(i,otherVec);
            if(GetVectorDistance(playerVec,otherVec)<300){
                return true;
            }
        }
    }
    return false;
}
 
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new TeleLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_JUMPZ);
		if(TeleLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_JUMPZ,true,true,true))
			{
				TeleportPlayerView(client,TeleRD[TeleLevel]);
			}
		}
		else
			PrintHintText(client,"Level your skill first");
	}
/* *************************************** (SKILL_FAZED) *************************************** */
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && ValidPlayer(client,true))
	{
		new FazedLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_FAZED);
		if(FazedLevel > 0)
		{
			if(InInvis[client])
				TriggerTimer(InvisEndTimer[client]); 
			else if(SkillAvailable(client,thisRaceID,SKILL_FAZED,true,true,true))
			{             
				EmitSoundToAll(InvisOn,client);
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.00);
				War3_SetBuff(client,bDisarm,thisRaceID,true);
				InvisEndTimer[client]=CreateTimer(InvisDuration[FazedLevel],EndInvis,client);
				InInvis[client]=true;
			}
		}   
	}
}

public Action:EndInvis(Handle:timer,any:client)
{
	if(ValidPlayer(client) && InInvis[client])
	{
		InInvis[client]=false;
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_SetBuff(client,bDisarm,thisRaceID,false);
		EmitSoundToAll(InvisOff,client);
		War3_CooldownMGR(client,20.0,thisRaceID,SKILL_FAZED, _, _);
	}
}
/* *************************************** (ULT_PUSH) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new PushLevel=War3_GetSkillLevel(client,thisRaceID,ULT_PUSH);
		if(PushLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_PUSH,true,true,true))
			{
				if(!bPush[client])
				{		
					bPush[client]=true;
					PrintHintText(client,"You'll push the knife on your next attack");
				}
				else
				{
					PrintHintText(client,"Your ultimate is already activated - stab someone");
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID && bPush[attacker])
		{
			new PushLevel=War3_GetSkillLevel(attacker,thisRaceID,ULT_PUSH);
			if(PushLevel>0)
			{
				War3_DamageModPercent(2.0);
				PrintToConsole(victim,"A Jumper pushed his knife deep for double damage");
				PrintHintText(attacker,"Push it real good");
				W3EmitSoundToAll(PushSound,attacker);
				bPush[attacker]=false;
				War3_CooldownMGR(attacker,PushCD[PushLevel],thisRaceID,ULT_PUSH, _, _);
			}
		}
	}
}














