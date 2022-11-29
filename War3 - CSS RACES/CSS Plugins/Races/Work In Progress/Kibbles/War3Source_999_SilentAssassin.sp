#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo = 
{
    name = "War3Source Race - Silent Assassin",
    author = "CptStealth (coded by Kibbles)",
    description = "Silent Assassin race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new thisRaceID;
new SKILL_SPEED, SKILL_SILENTSTEPS, SKILL_SMOKE, ULT_TELEPORT;

//skill_speed
new Float:fSwiftnessSpeed[] = {1.0, 1.05, 1.1, 1.15, 1.2};

//skill_silentsteps
new Float:fSilentChance[] = {0.0, 0.4, 0.5, 0.6, 0.7};
new bool:bSilent[MAXPLAYERS];
new bool:bChecked[MAXPLAYERS] = {false, ...};

//skill_smoke
new Float:fSmokeDuration[] = {0.1, 2.0, 3.0, 4.0, 5.0};//0.1 is the lowest possible timer
new Float:fSmokeCooldown = 15.0;

//ult_teleport
new Float:fTeleportCooldown = 30.0;
new Float:fTeleportDistance = 800.0;
new Float:fTeleportEndDelay = 3.0;
new Handle:hTeleportEndTimers[MAXPLAYERS] = {INVALID_HANDLE, ...};
new Float:fTeleportEndTimes[MAXPLAYERS] = {0.0, ...};
new Float:fTeleportDuration[] = {0.0, 2.0, 3.0, 4.0, 5.0};

new String:teleportSound[256];
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Silent Assassin [PRIVATE]", "silentassassin");
    
    SKILL_SPEED = War3_AddRaceSkill(thisRaceID, "Swiftness", "Your prey will never see you coming", false, 4);
    SKILL_SILENTSTEPS = War3_AddRaceSkill(thisRaceID, "Silent Tread", "Become a master of stealth", false, 4);
    SKILL_SMOKE = War3_AddRaceSkill(thisRaceID, "Distraction (+ability)", "Hide your true face", false, 4);
    ULT_TELEPORT = War3_AddRaceSkill(thisRaceID, "A Master of Shadows (+ultimate)", "Fade into the shadows", true, 4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID,SKILL_SPEED,fMaxSpeed,fSwiftnessSpeed);
}


public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent, EventHookMode_Pre);
}


public OnRaceChanged(client, oldrace, newrace)
{
    if(newrace == thisRaceID)
    {
        if(ValidPlayer(client, true))
        {
            InitRace(client);
        }
    }
    else
    {
        W3ResetAllBuffRace(client, thisRaceID);
        War3_WeaponRestrictTo(client, thisRaceID, "");
    }
}


public OnWar3EventSpawn(client)
{
    if(ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        InitRace(client);
    }
}


public OnWar3EventDeath(victim,attacker)
{
	if(ValidPlayer(victim, true) && War3_GetRace(victim))
	{
		if (hTeleportEndTimers[victim] != INVALID_HANDLE)
        {
            TriggerTimer(hTeleportEndTimers[victim]);
            hTeleportEndTimers[victim] = INVALID_HANDLE;
        }
	}
}


public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if (hTeleportEndTimers[i] != INVALID_HANDLE)
        {
            TriggerTimer(hTeleportEndTimers[i]);
            hTeleportEndTimers[i] = INVALID_HANDLE;
        }
        bSilent[i] = false;
        bChecked[i] = false;
        if (ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID)
        {
            InitRace(i);
        }
    }
}


static InitRace(client)
{
    War3_SetBuff(client, fInvisibilitySkill, thisRaceID, 1.0);
    War3_SetBuff(client, bDisarm, thisRaceID, false);
    if (!bChecked[client])
    {
        bChecked[client] = true;
        new skill_silentsteps = War3_GetSkillLevel(client, thisRaceID, SKILL_SILENTSTEPS);
        if (skill_silentsteps > 0 && W3Chance(fSilentChance[skill_silentsteps]))
        {
            bSilent[client] = true;
            Client_PrintToChat(client, false, "{R}[SilentAssassin]{N} Your footsteps are silenced");
        }
        else
        {
            bSilent[client] = false;
            Client_PrintToChat(client, false, "{R}[SilentAssassin]{N} Your footsteps will be heard");
        }
    }
}


public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client, true))
    {
        new skill_smoke = War3_GetSkillLevel(client, thisRaceID, SKILL_SMOKE);
        if (skill_smoke > 0 && SkillAvailable(client, thisRaceID, SKILL_SMOKE, true, true, true))
        {
            War3_CooldownMGR(client, fSmokeCooldown, thisRaceID, SKILL_SMOKE, true, true);
        
            new Float:this_pos[3];
            GetClientAbsOrigin(client,this_pos);
            new Float:fadestart = fSmokeDuration[skill_smoke]*0.8; 
            new Float:fadeend = fSmokeDuration[skill_smoke];
            new SmokeIndex = CreateEntityByName("env_particlesmokegrenade"); 
            if (SmokeIndex != -1) 
            { 
                SetEntProp(SmokeIndex, Prop_Send, "m_CurrentStage", 1); 
                SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeStartTime", fadestart); 
                SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeEndTime", fadeend); 
                DispatchSpawn(SmokeIndex); 
                ActivateEntity(SmokeIndex); 
                TeleportEntity(SmokeIndex, this_pos, NULL_VECTOR, NULL_VECTOR); 
            }  
        }
    }
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer(client, true) && bSilent[client])
    {
        if(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP))
        {
            SetEntProp(client, Prop_Send, "m_fFlags", 4);
        }
    }
    return Plugin_Continue;
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if(ValidPlayer(client, true) && race == thisRaceID && pressed)
    {
        new ult_teleport = War3_GetSkillLevel(client, thisRaceID, ULT_TELEPORT);
        if (ult_teleport > 0)
        {
            if (hTeleportEndTimers[client] == INVALID_HANDLE)
            {
                if (SkillAvailable(client, thisRaceID, ULT_TELEPORT, true, true, true))
                {
                    War3_CooldownMGR(client,fTeleportCooldown,thisRaceID,ULT_TELEPORT);
                    AddTeleportBuffs(client);
                    fTeleportEndTimes[client] = GetGameTime() + fTeleportEndDelay;
                    hTeleportEndTimers[client] = CreateTimer(fTeleportDuration[ult_teleport], RemoveTeleportBuffs, client);
                    TeleportPlayerView(client, fTeleportDistance);
                }
            }
            else
            {
                if (GetGameTime() > fTeleportEndTimes[client])
                {
                    TriggerTimer(hTeleportEndTimers[client]);
                }
                else
                {
                    PrintHintText(client, "Too early to leave the shadows");
                }
            }
        }
    }
}
static AddTeleportBuffs(client)
{
    War3_SetBuff(client, fInvisibilitySkill, thisRaceID, 0.0);
    War3_SetBuff(client, bDisarm, thisRaceID, true);
    //War3_SetBuff(client, bBashed, thisRaceID, true);//Bash application has been moved to after the "has moved" teleport check, line 331
    PrintHintText(client, "You fade into the shadows");
}
public Action:RemoveTeleportBuffs(Handle:timer, any:client)
{
    if (ValidPlayer(client) && War3_GetRace(client) == thisRaceID)
    {
        War3_SetBuff(client, fInvisibilitySkill, thisRaceID, 1.0);
        War3_SetBuff(client, bDisarm, thisRaceID, false);
        War3_SetBuff(client, bBashed, thisRaceID, false);
        PrintHintText(client, "You leave the shadows");
        hTeleportEndTimers[client] = INVALID_HANDLE;
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
                War3_CooldownReset(client,thisRaceID,ULT_TELEPORT);
                TriggerTimer(hTeleportEndTimers[client]);
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
                War3_CooldownReset(client,thisRaceID,ULT_TELEPORT);
                TriggerTimer(hTeleportEndTimers[client]);
                return false;
            }
            TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
            EmitSoundToAll(teleportSound,client);    
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
        War3_CooldownReset(client,thisRaceID,ULT_TELEPORT);
        TriggerTimer(hTeleportEndTimers[client]);
    }
    else
    {    
        //Cooldown setter moved to top of teleport function
        //new skill_teleport = War3_GetSkillLevel(client, thisRaceID, ULT_TELEPORT);
        //War3_CooldownMGR(client,fTeleportCooldown[skill_teleport],thisRaceID,ULT_TELEPORT);
        War3_SetBuff(client, bBashed, thisRaceID, true);
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