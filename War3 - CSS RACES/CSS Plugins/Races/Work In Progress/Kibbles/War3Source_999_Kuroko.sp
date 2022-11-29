#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo = 
{
    name = "War3Source Race - Kuroko",
    author = "Darkbasil (coded by Kibbles)",
    description = "Kuroko race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new thisRaceID;
new SKILL_TRAINING, SKILL_MISDIRECTION, SKILL_MISDOVER, ULT_VANDRIVE;

//skill_training
new Float:fTrainingSpeed[] = {0.0, 1.05, 1.1, 1.15, 1.2};

//skill_misdirection
new Float:fMisdirectionEvade[] = {0.0, 0.04, 0.06, 0.08, 0.1};

//skill_misdover
new Float:fMisDoverThreshold[] = {0.0, 0.8, 0.7, 0.6, 0.5};
new Float:fMisDoverRange[] = {0.0, 500.0, 550.0, 600.0, 650.0};
new Float:fMisDoverDuration = 20.0;
new bool:bMisDoverUsed[MAXPLAYERSCUSTOM] = {false, ...};
#define MAXMISDOVERTARGETS 5
new iMisDoverTargets[MAXPLAYERSCUSTOM][MAXMISDOVERTARGETS];
new bool:bInMisDover[MAXPLAYERSCUSTOM];

//ult_vandrive
new Float:fVanDriveCooldown[] = {0.0, 45.0, 30.0, 25.0, 20.0};
new Float:fVanDriveDistance[] = {0.0, 500.0, 600.0, 700.0, 800.0};
new Float:fVanDriveInvis[] = {0.0, 0.8, 0.75, 0.6, 0.5};
new Float:fVanDriveInvisDuration = 2.0;
new Handle:hVanDriveInvisTimers[MAXPLAYERSCUSTOM] = {INVALID_HANDLE};

new String:teleport_sound[]="war3source/archmage/teleport.wav";
new String:InvisOff[]="npc/scanner/scanner_nearmiss2.wav";
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};




public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Kuroko [PRIVATE]", "kuroko");
    
    SKILL_TRAINING = War3_AddRaceSkill(thisRaceID, "Training", "Kuroko goes through training to run faster\n(1.05, 1.10, 1.15, 1.2) runspeed", false, 4);
    SKILL_MISDIRECTION = War3_AddRaceSkill(thisRaceID, "Misdirection", "Kuroko can divert attention away from himself\n(0.04, 0.06, 0.08, 0.10) evade", false, 4);
    SKILL_MISDOVER = War3_AddRaceSkill(thisRaceID, "Misdirection Overflow (+ability)", "Kuroko allows others to vanish by utilizing his misdirection\n(0.8, 0.6, 0.4, 0.3) invis AOE, 20 second duration, once per round", false, 4);
    ULT_VANDRIVE = War3_AddRaceSkill(thisRaceID, "Vanishing Drive (+ultimate)", "Kuroko vanishes from sight to slip past people\n(45s, 30s, 25s, 20s) cooldown, (0.8, 0.75, 0.6, 0.5) 2 second invis after teleport", true, 4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_TRAINING, fMaxSpeed, fTrainingSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_MISDIRECTION, fDodgeChance, fMisdirectionEvade);
}


public OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
}


public OnMapStart()
{
    War3_PrecacheSound(teleport_sound);
	War3_PrecacheSound(InvisOff);
    CreateTimer(0.5, MisDoverAuraLoop, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


public OnRaceChanged(client, oldrace, newrace)
{
    if(newrace != thisRaceID)
    {
        W3ResetAllBuffRace(client, thisRaceID);
        War3_WeaponRestrictTo(client, thisRaceID, "");
    }
}


public OnWar3EventSpawn(client)
{
    if(ValidPlayer(client))
    {
        bInMisDover[client] = false;
        W3ResetBuffRace(client, fInvisibilitySkill, thisRaceID);
        if (IsPlayerAlive(client) && War3_GetRace(client) == thisRaceID)
        {
            InitRace(client);
        }
    }
}
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i<MaxClients; i++)
	{
		if (ValidPlayer(i))
		{
            for (new n=0; n<MAXMISDOVERTARGETS; n++)
            {
                iMisDoverTargets[i][n] = -1;
            }
            bInMisDover[i] = false;
            W3ResetBuffRace(i, fInvisibilitySkill, thisRaceID);
            bMisDoverUsed[i] = false;
		}
	}
}
static InitRace(client)
{
    if (hVanDriveInvisTimers[client] != INVALID_HANDLE)
    {
        CloseHandle(hVanDriveInvisTimers[client]);
        hVanDriveInvisTimers[client] = INVALID_HANDLE;
    }
}


public OnAbilityCommand(client,ability,bool:pressed)
{
    if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && ability==0 && pressed)
    {
        new skill_misdover = War3_GetSkillLevel(client, thisRaceID, SKILL_MISDOVER);
        if (skill_misdover > 0 && !Silenced(client, true) && !bMisDoverUsed[client])
        {
            War3_CooldownMGR(client, fMisDoverDuration, thisRaceID, SKILL_MISDOVER, true, false);//this is a bit of a hack, but stops us from needing to track an extra "in use" boolean
            bMisDoverUsed[client] = true;
            PrintHintText(client, "Misdirection Overflow is active");
        }
    }
}
public OnCooldownExpired(client, raceID, skillNum, bool:expiredByTime)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID && skillNum == SKILL_MISDOVER)
    {
        PrintHintText(client, "Misdirection Overflow is no longer active");
    }
}
public Action:MisDoverAuraLoop(Handle:timer)
{
    new tmpFurthestAlly;
    new Float:tmpFurthestDist;
    new Float:tmpClosestDist;
    new tmpClosestAlly[MAXMISDOVERTARGETS];
    new Float:tmpClosestDistance[MAXMISDOVERTARGETS];
    new i,j,n;
    new Float:clientPos[3];
    new Float:allyPos[3];
    new clientTeam;
    new bool:removeInvis;
    for (i=1; i<=MaxClients; i++)
    {
        if (ValidPlayer(i) && War3_GetRace(i) == thisRaceID)
        {
            new skill_misdover = War3_GetSkillLevel(i, thisRaceID, SKILL_MISDOVER);
            if (ValidPlayer(i, true) && skill_misdover > 0 && War3_CooldownRemaining(i, thisRaceID, SKILL_MISDOVER) > 0)//use skill being in cooldown to track activation
            {
                GetClientAbsOrigin(i, clientPos);
                clientTeam = GetClientTeam(i);
                
                for (n=0; n<MAXMISDOVERTARGETS; n++)
                {
                    tmpClosestAlly[n] = -1;
                    tmpClosestDistance[n] = 9999.0;
                }
                
                for (j=1; j<=MaxClients; j++)
                {
                    if (ValidPlayer(j, true) && GetClientTeam(j) == clientTeam)
                    {
                        GetClientAbsOrigin(j, allyPos);
                        tmpClosestDist = GetVectorDistance(clientPos, allyPos);
                        if (tmpClosestDist <= fMisDoverRange[skill_misdover])
                        {
                            for (n=0; n<MAXMISDOVERTARGETS; n++)//first test for untaken slots
                            {
                                if (!ValidPlayer(tmpClosestAlly[n], true))
                                {
                                    tmpClosestAlly[n] = j;
                                    tmpClosestDistance[n] = tmpClosestDist;
                                    break;
                                }
                            }
                            tmpFurthestAlly = -1;
                            tmpFurthestDist = -1.0;
                            for (n=0; n<MAXMISDOVERTARGETS; n++)//then test for furthest chosen ally
                            {
                                if (tmpClosestDistance[n] > tmpFurthestDist)
                                {
                                    tmpFurthestAlly = n;
                                    tmpFurthestDist = tmpClosestDistance[n];
                                }
                            }
                            if (tmpClosestDist < tmpFurthestDist)
                            {
                                tmpClosestAlly[tmpFurthestAlly] = j;
                                tmpClosestDistance[tmpFurthestAlly] = tmpClosestDist;
                            }
                        }
                    }
                }
                
                for (n=0; n<MAXMISDOVERTARGETS; n++)
                {
                    removeInvis = true;
                    for (j=0; j<MAXMISDOVERTARGETS; j++)
                    {
                        if (ValidPlayer(iMisDoverTargets[i][n]) && iMisDoverTargets[i][n] == tmpClosestAlly[j])
                        {
                            removeInvis = false;//only set to remove if old target not found in new targets
                            break;
                        }
                    }
                    if (removeInvis && ValidPlayer(iMisDoverTargets[i][n], true))
                    {
                        W3ResetBuffRace(iMisDoverTargets[i][n], fInvisibilitySkill, thisRaceID);
                        bInMisDover[iMisDoverTargets[i][n]] = false;
                    }
                }
                
                for (n=0; n<MAXMISDOVERTARGETS; n++)
                {
                    iMisDoverTargets[i][n] = tmpClosestAlly[n];
                    
                    if (ValidPlayer(iMisDoverTargets[i][n], true) && !bInMisDover[iMisDoverTargets[i][n]])
                    {
                        new Float:minSkillInvis = W3GetBuffMinFloat(iMisDoverTargets[i][n], fInvisibilitySkill);
                        new Float:minItemInvis = W3GetBuffMinFloat(iMisDoverTargets[i][n], fInvisibilityItem);
                        new Float:minInvis = (minSkillInvis < minItemInvis) ? minSkillInvis : minItemInvis;
                        if (minInvis > fMisDoverThreshold[skill_misdover])
                        {
                            War3_SetBuff(iMisDoverTargets[i][n], fInvisibilitySkill, thisRaceID, fMisDoverThreshold[skill_misdover]);
                            bInMisDover[iMisDoverTargets[i][n]] = true;
                        }
                    }
                }
            }
            else
            {
                for (n=0; n<MAXMISDOVERTARGETS; n++)
                {
                    if (ValidPlayer(iMisDoverTargets[i][n], true))
                    {
                        W3ResetBuffRace(iMisDoverTargets[i][n], fInvisibilitySkill, thisRaceID);
                        bInMisDover[iMisDoverTargets[i][n]] = false;
                        iMisDoverTargets[i][n] = -1;
                    }
                }
            }
        }
    }
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID && pressed)
    {
        new ult_vandrive = War3_GetSkillLevel(client, thisRaceID, ULT_VANDRIVE);
        if (ult_vandrive>0 && War3_SkillNotInCooldown(client, thisRaceID, ULT_VANDRIVE, true) && !Silenced(client, true))
        {
            TeleportPlayerView(client, fVanDriveDistance[ult_vandrive]);
        }
    }
}
public Action:RemoveInvis(Handle:timer, any:client)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        W3ResetBuffRace(client, fInvisibilitySkill, thisRaceID);
        EmitSoundToAll(InvisOff,client);
    }
}
static TriggerInvisTimer(client)
{
    if (hVanDriveInvisTimers[client] != INVALID_HANDLE)
    {
        TriggerTimer(hVanDriveInvisTimers[client]);
        hVanDriveInvisTimers[client] = INVALID_HANDLE;
    }
}
//Teleport code taken from Remy Lebeau's GamblingMan race.
bool:TeleportPlayerView(client,Float:distance)
{
    if(client>0){
        if(IsPlayerAlive(client)){
            new ult_vandrive = War3_GetSkillLevel(client, thisRaceID, ULT_VANDRIVE);
            War3_CooldownMGR(client,fVanDriveCooldown[ult_vandrive],thisRaceID,ULT_VANDRIVE);
            if (!bInMisDover[client])
            {
                War3_SetBuff(client, fInvisibilitySkill, thisRaceID, fVanDriveInvis[ult_vandrive]);
                hVanDriveInvisTimers[client] = CreateTimer(fVanDriveInvisDuration, RemoveInvis, client);
            }
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
                War3_CooldownReset(client,thisRaceID,ULT_VANDRIVE);
                TriggerInvisTimer(client);
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
                War3_CooldownReset(client,thisRaceID,ULT_VANDRIVE);
                TriggerInvisTimer(client);
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
        War3_CooldownReset(client,thisRaceID,ULT_VANDRIVE);
        TriggerInvisTimer(client);
    }
    else
    {    
        //Cooldown setter moved to top of teleport function
        //new ult_vandrive = War3_GetSkillLevel(client, thisRaceID, ULT_VANDRIVE);
        //War3_CooldownMGR(client,fVanDriveCooldown[ult_vandrive],thisRaceID,ULT_VANDRIVE);
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