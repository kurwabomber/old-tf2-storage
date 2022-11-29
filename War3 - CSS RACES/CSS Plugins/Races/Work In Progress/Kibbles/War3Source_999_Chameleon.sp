#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Chameleon",
	author = "ABGar (edited by Kibbles)",
	description = "The Chameleon race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_MOBIL, SKILL_IMMUN, SKILL_BLEND, ULT_BLINK;

// SKILL_MOBIL
new Float:ChameleonSpeed[]={1.0,1.1,1.2,1.3,1.4};
new Float:ChameleonGrav[]={1.0,0.7,0.6,0.5,0.4};

// SKILL_IMMUN
new Float:ImmuneChance[]={0.0,0.7,0.8,0.9,1.0};

// SKILL_BLEND
new bool:bMoving[MAXPLAYERS];
new Float:CanInvisTime[MAXPLAYERS];
new Float:ChameleonInvis[]={1.0,0.6,0.4,0.3,0.2};
new ChameleonHealth[]={0,-30,-40,-50,-70};

// ULT_BLINK
new Float:TeleportRange=500.0;
new Float:teleCD[]={0.0,5.0,4.0,3.0,2.0};
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:EffectPos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:teleport_sound[]="war3source/blinkarrival.mp3";
new SmokeSprite, LightningSprite, GlowSprite;

// Miscellaneous
new String:KillSound[]="war3source/dev/mmm.mp3";
new Float:MaxKnifeDamage=75.0;


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Chameleon [PRIVATE]","chameleon");
	SKILL_MOBIL = War3_AddRaceSkill(thisRaceID,"Mobility","Travel quickly and lightly (passive)",false,4);
	SKILL_IMMUN = War3_AddRaceSkill(thisRaceID,"Immunity","Chance for immunity to Ultimates, wards and slows (passive)",false,4);
	SKILL_BLEND = War3_AddRaceSkill(thisRaceID,"Blend","Blend with your surroundings easily (passive)",false,4);
	ULT_BLINK=War3_AddRaceSkill(thisRaceID,"Blink","Make quick and small leaps (+ultimate)",true,4);//Ultimate, not skill!
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_MOBIL,fMaxSpeed,ChameleonSpeed);
	War3_AddSkillBuff(thisRaceID,SKILL_MOBIL,fLowGravitySkill,ChameleonGrav);
	War3_AddSkillBuff(thisRaceID,SKILL_BLEND,fInvisibilitySkill,ChameleonInvis);
	War3_AddSkillBuff(thisRaceID,SKILL_BLEND,iAdditionalMaxHealth,ChameleonHealth);
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

public OnPluginStart()
{
	CreateTimer(0.1,CalcVis,_,TIMER_REPEAT);
}

public OnMapStart()
{
	War3_PrecacheSound(teleport_sound);
	War3_PrecacheSound(KillSound);
	PrecacheModel("sprites/orangelight1.vmt");
	PrecacheSound("ambient/atmosphere/city_skypass1.wav");
    SmokeSprite = PrecacheModel("sprites/smoke.vmt");
	LightningSprite = PrecacheModel("sprites/lgtning.vmt");
	GlowSprite = PrecacheModel("sprites/glow.vmt");
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	new ImmuneLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_IMMUN);
	if(W3Chance(ImmuneChance[ImmuneLevel]))
	{
		War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
		War3_SetBuff(client,bImmunityWards,thisRaceID,true);
		War3_SetBuff(client,bSlowImmunity,thisRaceID,true);
		PrintToChat(client,"\x04 %N \x03You are immune this round",client);
	}
    else
    {
        //Need to remove buffs that you give :)
        War3_SetBuff(client,bImmunityUltimates,thisRaceID,false);
		War3_SetBuff(client,bImmunityWards,thisRaceID,false);
		War3_SetBuff(client,bSlowImmunity,thisRaceID,false);
        PrintToChat(client,"\x04 %N \x03You are no longer immune",client);
    }
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if (ValidPlayer(victim, true) && ValidPlayer(attacker, true) && victim != attacker)
    {
        if (War3_GetRace(attacker) == thisRaceID && damage>MaxKnifeDamage)
        {
            new Float:modifier = MaxKnifeDamage/damage;
            War3_DamageModPercent(modifier);
        }
    }
}

/* *************************************** (SKILL_BLEND) *************************************** */
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client)&&War3_GetRace(client)==thisRaceID)
	{
		bMoving[client]=(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP))?true:false;//Jumping is movement too :)
        new CloakLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_BLEND);
        if(CloakLevel > 0 && bMoving[client])//Immediate visibility, otherwise they can move while out of sight
        {
            War3_SetBuff(client,fInvisibilitySkill,thisRaceID,ChameleonInvis[CloakLevel]);
            CanInvisTime[client]=GetGameTime() + 1.0;
        }
	}
	return Plugin_Continue;
}

public Action:CalcVis(Handle:timer,any:userid)
{
	for(new i=0;i<MaxClients;i++)
	{
		if(ValidPlayer(i) && War3_GetRace(i)==thisRaceID)
		{
			new CloakLevel = War3_GetSkillLevel(i,thisRaceID,SKILL_BLEND);
			if(CloakLevel>0)
			{
				if(!bMoving[i])
				{
					if(CanInvisTime[i]<GetGameTime())
					{
						War3_SetBuff(i,fInvisibilitySkill,thisRaceID,0.00);
					}
				}
			}
		}
	}
}

/* *************************************** (ULT_BLINK) *************************************** */

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true)){
        if(SkillAvailable(client,thisRaceID,ULT_BLINK,true,true,true))
        {
            new UltLevel=War3_GetSkillLevel(client,thisRaceID,ULT_BLINK);
            if(UltLevel>0)
			{
				GetClientAbsOrigin(client,EffectPos[client]);
				TeleportPlayerView(client,TeleportRange);
			}
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
            new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_BLINK);
            War3_CooldownMGR(client,teleCD[ult_level],thisRaceID,ULT_BLINK,_,false);
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
                War3_CooldownReset(client,thisRaceID,ULT_BLINK);
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
                War3_CooldownReset(client,thisRaceID,ULT_BLINK);
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
        War3_CooldownReset(client,thisRaceID,ULT_BLINK);
    }
    else
    {
        TeleportEffect(client);
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
public Action:TeleportEffect( client )
{
	new Float:client_pos[3];
	
	GetClientAbsOrigin( client, client_pos );
	
	TE_SetupBeamRingPoint( EffectPos[client], 10.0, 30.0, SmokeSprite, SmokeSprite, 0, 0, 0.75, 10.0, 0.0,{ 77, 77, 0, 50 }, 0, FBEAM_ISACTIVE );
	TE_SendToAll();
	
	/*TE_SetupBeamPoints( EffectPos[client], client_pos, LightningSprite, LightningSprite, 0, 0, 0.5, 7.5, 20.0, 0, 0.0, { 123, 123, 0, 50 }, 0 );
	TE_SendToAll();
	
	EffectPos[client][2] += 20;
	client_pos[2] += 20;
	
	TE_SetupBeamPoints( EffectPos[client], client_pos, GlowSprite, GlowSprite, 0, 0, 0.5, 7.5, 15.0, 0, 0.0, { 200, 200, 0, 50 }, 0 );
	TE_SendToAll();*/
}


public OnWar3EventDeath(victim,attacker)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			W3EmitSoundToAll(KillSound,attacker);
		}
	}
}