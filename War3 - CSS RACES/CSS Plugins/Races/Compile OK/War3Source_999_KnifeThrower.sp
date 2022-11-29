/**
* File: War3Source_999_knifet.sp
* Author(s): ??
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <smlib>
#include "W3SIncs/RemyFunctions"

new thisRaceID, SKILL_FASTFEET, SKILL_AMMO, SKILL_THROW, ULT_ROPE;

#define KNIFE_MDL "models/weapons/w_knife_ct.mdl"
#define KNIFEHIT_SOUND "weapons/knife/knife_hit3.wav"
#define ROPEHIT_SOUND "weapons/crossbow/hit1.wav"
#define ROPEFIRE_SOUND "weapons/crossbow/fire1.wav"
#define TRAIL_MDL "materials/sprites/lgtning.vmt"
#define TRAIL_COLOR_T {255, 0, 0, 100}
#define TRAIL_COLOR_CT {0, 0, 255, 100}
#define ADD_OUTPUT "OnUser1 !self:Kill::1.7:1"

new Handle:g_hLethalArray;
new Float:g_fVelocity;
new bool:g_bNoBlock;
new Handle:g_CVarFF;
new const Float:g_fSpin[3] = {1877.4, 0.0, 0.0};
new const Float:g_fMinS[3] = {-16.0, -16.0, -16.0};
new const Float:g_fMaxS[3] = {16.0, 16.0, 16.0};
new g_iKnives[MAXPLAYERSCUSTOM];
new g_iKnifeMI;
new g_iPointHurt;
new g_iEnvBlood;
new g_iTrailMI;

//skill(1)
new Float:FeetSpeed[8]={1.0, 1.05, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35};
//skill()
new KnifesDamage[8]={0, 50, 55, 60, 65, 70, 75, 80};

//ability
//+knifes
new knfammo[8]={0,2,4,5,6,7,8,9};
//+health
new hpammo[8]={0,4,5,6,7,8,9,10};


// ULT_TELEPORT VARIABLES
new Float:TeleRD=1000.0;
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new Float:g_fTeleportCooldown[] =  {0.0, 25.0,20.0, 17.0, 15.0, 12.0, 10.0, 7.0};


public Plugin:myinfo = {

    name = "War3Source Race - Knife Thrower",
    author = "nvN, Remy Lebeau",
    version = "2.0",
    description = "Knife Throwing race for War3Source",
    url = "War3Source.ru"
};


public OnMapStart()
{
    g_iKnifeMI = PrecacheModel(KNIFE_MDL);
    g_iTrailMI = PrecacheModel(TRAIL_MDL);
    War3_PrecacheSound(KNIFEHIT_SOUND);
    War3_PrecacheSound(ROPEFIRE_SOUND);
    War3_PrecacheSound(ROPEHIT_SOUND);
    CreateTimer(1.0, HudInfo_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    /*
    AddFileToDownloadsTable("materials/models/player/slow/jamis/moon_knight/slow_body.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/moon_knight/slow_body.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/moon_knight/slow_body_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/moon_knight/slow_cape.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/moon_knight/slow_cape.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jamis/moon_knight/slow_cape_bump.vtf");
    AddFileToDownloadsTable("models/player/slow/jamis/moon_knight/slow_v2.dx80.vtx");
    AddFileToDownloadsTable("models/player/slow/jamis/moon_knight/slow_v2.dx90.vtx");
    AddFileToDownloadsTable("models/player/slow/jamis/moon_knight/slow_v2.phy");
    AddFileToDownloadsTable("models/player/slow/jamis/moon_knight/slow_v2.sw.vtx");
    AddFileToDownloadsTable("models/player/slow/jamis/moon_knight/slow_v2.vvd");
    AddFileToDownloadsTable("models/player/slow/jamis/moon_knight/slow_v2.mdl");
    PrecacheModel("models/player/slow/jamis/moon_knight/slow_v2.mdl",true);*/
}

public OnPluginStart()
{
    g_CVarFF = FindConVar("mp_friendlyfire");

    g_fVelocity = (1000.0 + (350.0 * 5));
    

    g_hLethalArray = CreateArray();

    AddNormalSoundHook(NormalSHook:SoundsHook);
    HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
    HookEvent("weapon_fire", EventWeaponFire);

}

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Knife Thrower [SSG-DONATOR]","knifet");
    SKILL_THROW=War3_AddRaceSkill(thisRaceID,"Throwing Knives","You are  able to throw knifes (mouse1)\nAlso u gain 10 knives on spawn.",false,7);    
    SKILL_FASTFEET=War3_AddRaceSkill(thisRaceID,"Fast Feet","You gain up to 30% more speed",false,7);
    SKILL_AMMO=War3_AddRaceSkill(thisRaceID,"BackUp","You get extra knifes and health (+ability)",false,7);    
    ULT_ROPE=War3_AddRaceSkill(thisRaceID,"Hook","Grapple yourself onto walls (+ultimate)",true,7);
    
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_AMMO,10.0,false);
    W3SkillCooldownOnSpawn(thisRaceID,ULT_ROPE,5.0,false);

    War3_CreateRaceEnd(thisRaceID);
}


public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    InitPassiveSkills(client);
}

public InitPassiveSkills(client){
    if(War3_GetRace(client)==thisRaceID)
    {
        new FastFeetLvl=War3_GetSkillLevel(client,thisRaceID,SKILL_FASTFEET);
        War3_SetBuff(client,fMaxSpeed,thisRaceID,FeetSpeed[FastFeetLvl]);
        
        new ThrowLvl=War3_GetSkillLevel(client,thisRaceID,SKILL_THROW);
        g_iKnives[client]=knfammo[ThrowLvl];
        //PrintToChat(client,"Throwing Knives : %i",g_iKnives[client]);
        War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
    }
}


public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace!=thisRaceID){
        War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3ResetPlayerColor(client,thisRaceID);
        g_iKnives[client]=0;
        HUD_Add(GetClientUserId(client), "");
        War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
    }
    else{
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
        //SetModel(client);
        if(IsPlayerAlive(client)){
            InitPassiveSkills(client);
        }
    }
}

public OnAbilityCommand(client,ability,bool:pressed){
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    {
        new ult_level=War3_GetSkillLevel(client,thisRaceID,SKILL_AMMO);
        if(ult_level>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_AMMO,true))
            {
                g_iKnives[client]=g_iKnives[client]+knfammo[ult_level];
                War3_HealToMaxHP(client,hpammo[ult_level]);                
                War3_CooldownMGR(client,15.0,thisRaceID,SKILL_AMMO);
            }
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID&& IsPlayerAlive(client))
    {
        if(!Silenced(client)){
            new skill=War3_GetSkillLevel(client,race,ULT_ROPE);
            if(skill>0)
            {
                if (!pressed)
                {
                    War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
                }
                else if(pressed&&War3_SkillNotInCooldown(client,thisRaceID,ULT_ROPE,true))
                {
                    War3_CooldownMGR(client,g_fTeleportCooldown[skill],thisRaceID,ULT_ROPE);
                    TeleportPlayerView(client,TeleRD);
                    
                }
            }
        }
    }
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {

    g_iEnvBlood = -1;
    ClearArray(g_hLethalArray);
    CreateEnts();
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    InitPassiveSkills(client);
}

public OnWar3EventSpawn(client) {
    
    InitPassiveSkills(client);
    if (War3_GetRace(client) == thisRaceID)
    {
        //SetModel(client);
        
    }
}

public EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast) { /* only fires for primary attack */

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(War3_GetRace(client)==thisRaceID)
    {
        static String:sWeapon[32];
        GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
        if (!IsFakeClient(client) && StrEqual(sWeapon, "knife") && g_iKnives[client]>=1) {
            ThrowKnife(client);
        }
    }
}

ThrowKnife(client) {
    
    static Float:fPos[3], Float:fAng[3], Float:fVel[3];
    GetClientEyePosition(client, fPos);
    
    /* simple noblock fix. prevent throw if it will spawn inside another client */
    if (g_bNoBlock && IsClientIndex(GetTraceHullEntityIndex(fPos, client)))
        return;
    
    /* create & spawn entity. set model & owner. set to kill itself OnUser1 */
    new entity = CreateEntityByName("flashbang_projectile");
    if ((entity != -1) && DispatchSpawn(entity)) {
        SetEntityModel(entity, KNIFE_MDL);
        SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
        SetVariantString(ADD_OUTPUT);
        AcceptEntityInput(entity, "AddOutput");
        
        /* calc & set spawn position, angle, velocity & spin */
        GetClientEyeAngles(client, fAng);
        GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(fVel, g_fVelocity);
        SetEntPropVector(entity, Prop_Data, "m_vecAngVelocity", g_fSpin);
        SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.2);
        
        /* add to lethal knife array then teleport... */
        PushArrayCell(g_hLethalArray, entity);
        TeleportEntity(entity, fPos, fAng, fVel);
        --g_iKnives[client];

        if(GetClientTeam(client)==2){
            TE_SetupBeamFollow(entity, g_iTrailMI, 0, 0.7, 7.7, 7.7, 3, TRAIL_COLOR_T);
        }
        else{
            TE_SetupBeamFollow(entity, g_iTrailMI, 0, 0.7, 7.7, 7.7, 3, TRAIL_COLOR_CT);
        }
        TE_SendToAll();
    }
}

public Action:SoundsHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) {

    if (StrEqual(sample, "weapons/flashbang/grenade_hit1.wav", false)) {
        new index = FindValueInArray(g_hLethalArray, entity);
        if (index != -1) {
            volume = 0.2;
            RemoveFromArray(g_hLethalArray, index); /* delethalize on first "hit" */
            new attacker = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
            static Float:fKnifePos[3], Float:fAttPos[3], Float:fVicEyePos[3];
            GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fKnifePos);
            new victim = GetTraceHullEntityIndex(fKnifePos, attacker);
            if (IsClientIndex(victim) && IsClientInGame(attacker)) {
                RemoveEdict(entity);
                if (GetConVarBool(g_CVarFF) || (GetClientTeam(victim) != GetClientTeam(attacker))) {
                    GetClientAbsOrigin(attacker, fAttPos);
                    GetClientEyePosition(victim, fVicEyePos);
                    EmitAmbientSound(KNIFEHIT_SOUND, fKnifePos, victim, SNDLEVEL_NORMAL, _, 0.7);
                    
                    new skilllevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_THROW);
                    new damage=KnifesDamage[skilllevel];
                    new damagehs=damage/2+damage;
                    War3_DealDamage(victim,(FloatAbs(fKnifePos[2] - fVicEyePos[2]) < 4.7) ? damagehs : damage,attacker,_,"Knife",_,_,false,false);
                    PrintHintText(attacker,"+%d",War3_GetWar3DamageDealt());
                    Bleed(victim);
                }
            }
            else /* didn't hit a player, kill itself in a few moments */
                AcceptEntityInput(entity, "FireUser1");
            return Plugin_Changed;
        }
        else if (GetEntProp(entity, Prop_Send, "m_nModelIndex") == g_iKnifeMI) {
            volume = 0.2;
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

GetTraceHullEntityIndex(Float:pos[3], xindex) {

    TR_TraceHullFilter(pos, pos, g_fMinS, g_fMaxS, MASK_SHOT, THFilter, xindex);
    return TR_GetEntityIndex();
}

public bool:THFilter(entity, contentsMask, any:data) {

    return IsClientIndex(entity) && (entity != data);
}

bool:IsClientIndex(index) {

    return (index > 0) && (index <= MaxClients);
}

CreateEnts() {

    if (((g_iPointHurt = CreateEntityByName("point_hurt")) != -1) && DispatchSpawn(g_iPointHurt)) {
        DispatchKeyValue(g_iPointHurt, "DamageTarget", "hurt");
        DispatchKeyValue(g_iPointHurt, "DamageType", "0");
    }
    if (((g_iEnvBlood = CreateEntityByName("env_blood")) != -1) && DispatchSpawn(g_iEnvBlood)) {
        DispatchKeyValue(g_iEnvBlood, "spawnflags", "13");
        DispatchKeyValue(g_iEnvBlood, "amount", "1000");
    }
}

Bleed(client) {

    if (IsValidEntity(g_iEnvBlood))
        AcceptEntityInput(g_iEnvBlood, "EmitBlood", client);
}

/******
 *Cmds*
 *******/

SetModel(client,normal=0)
{
    if(ValidPlayer(client,true))
    {
        new team = GetClientTeam(client);
        if(normal){
            W3SetPlayerColor(client,thisRaceID,255,255,255,_,0);
            switch (team){
                case 3:    {
                    SetEntityModel(client, "models/player/ct_urban.mdl");
                }
                case 2:    {
                    SetEntityModel(client, "models/player/t_leet.mdl");
                }
            }
        }
        else{
            SetEntityModel(client, "models/player/slow/jamis/moon_knight/slow_v2.mdl");
            if(team==3)    {
                W3SetPlayerColor(client,thisRaceID,116,176,236,255);
            }
            else
                W3SetPlayerColor(client,thisRaceID,236,176,116,255);
        }
    }
    
}


public Action:HudInfo_Timer(Handle:timer, any:client)
{
    for( new i = 1; i <= MaxClients; i++ )
    {
        if(ValidPlayer(i,true) && !IsFakeClient(i))
        {
            if(War3_GetRace(i) == thisRaceID)  
            {
                new String:buffer[500];
                Format(buffer,sizeof(buffer),"\nThrowing Knives : %i",g_iKnives[i]);
                HUD_Add(GetClientUserId(i), buffer);
            }
        }
    }  
}


/***************************************************************************
*
*
*                TELEPORT FUNCTIONS
*
*
***************************************************************************/



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
                War3_CooldownReset(client, thisRaceID, ULT_ROPE);
                return false;
            }
            EmitSoundToAll(ROPEFIRE_SOUND,client);
            TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
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
        War3_CooldownReset(client, thisRaceID, ULT_ROPE);

    }
    else
    {    
        EmitSoundToAll(ROPEHIT_SOUND,client);
        War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
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
