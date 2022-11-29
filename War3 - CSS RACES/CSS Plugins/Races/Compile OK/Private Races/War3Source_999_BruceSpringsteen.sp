#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_GUNS, SKILL_SPEED, SKILL_TORNADO, ULT_TELEPORT;

//Guns variables
new Float:fGunsChance = 0.5;
new Float:fGunsDamageModifier[] = {0.0, 0.05, 0.1, 0.15, 0.2};

//Speed variables
new Float:fRunSpeed[] = {1.0, 1.075, 1.15, 1.225, 1.3};

//Tornado variables
new m_vecBaseVelocity; //offsets
new TornadoSprite;
new String:TornadoSound[]="HL1/ambience/des_wind2.wav";
new Float:fTornadoCooldown[] = {0.0, 60.0, 45.0, 30.0, 25.0};
new TornadoDamage[] = {0, 5, 10, 15, 20};
new Float:fTornadoSelfChance = 0.15;
new Float:fTornadoJumpRange = 500.0;
new Float:fTornadoJumpDelay = 0.25;
new TornadoJumps = 2;
new Handle:TornadoDataPacks[MAXPLAYERS] = {INVALID_HANDLE, ...};

//Teleport variables
new Float:fTeleportCooldown[] = {0.0, 60.0, 45.0, 40.0, 30.0};
new Float:fTeleportDistance = 1200.0;
new Float:fDisarmTime = 1.0;

new String:teleportSound[256];
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};


public Plugin:myinfo = 
{
    name = "War3Source Race - Bruce Springsteen",
    author = "Valencianista (coded by Kibbles)",
    description = "Bruce Springsteen race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Bruce Springsteen [PRIVATE]","brucespr");
    
    SKILL_GUNS = War3_AddRaceSkill(thisRaceID, "I am The Boss", "Bruce needs one hand for his guitar\n50/50 chance to spawn with either a USP or Deagle. 4 levels with bonus damage. (5, 10, 15, 20% bonus with both Deagle and USP)", false, 4);
    SKILL_SPEED = War3_AddRaceSkill(thisRaceID, "Born to Run", "Tramps like us, baby we were born to run\nIncreased run speed (4 levels up to 1.3 speed)", false, 4);
    SKILL_TORNADO = War3_AddRaceSkill(thisRaceID, "The Promised Land (ability)", "I packed my bags and I'm heading straight into the storm (ability)\nHit up to 3 enemies with a tornado, but 15% chance to affect yourself (cooldown 6/45/30/25 seconds, damage 5/10/15/20)", false, 4);
    ULT_TELEPORT = War3_AddRaceSkill(thisRaceID, "Thunder Road (ultimate)", "It's a town full of losers; I'm pulling out of here to win\nTeleport up to 1200 units. After such a long journey Bruce has to take 1 second to catch his breathe before he can shoot again (unable to shoot for 1 second after teleport, 60/45/40/30 second cooldown)", true, 4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,5.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
}

public OnMapStart()
{
    TornadoSprite=PrecacheModel("sprites/lgtning.vmt");
    War3_PrecacheSound(TornadoSound);
    strcopy(teleportSound,sizeof(teleportSound),"war3source/blinkarrival.mp3");
    War3_PrecacheSound(teleportSound);
    
    for (new i=0; i<MAXPLAYERS; i++)
    {
        if (TornadoDataPacks[i] != INVALID_HANDLE)
        {
            CloseHandle(TornadoDataPacks[i]);
            TornadoDataPacks[i] = INVALID_HANDLE;
        }
    }
}


public OnRaceChanged(client, oldrace, newrace)
{
    if(newrace == thisRaceID && ValidPlayer(client))
    {
        if(ValidPlayer(client, true))
        {
            InitPassiveSkills(client);
        }
        else
        {
            //Do something if player has changed to this race and is dead
        }
    }
    else
    {
        //Reset buffs/restrictions if player is changing from this race.
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}


public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
    if (ValidPlayer(client, true) && race == thisRaceID)
    {
        InitPassiveSkills(client);
    }
}


public OnWar3EventSpawn(client)
{
    new race = War3_GetRace(client);
    if( race == thisRaceID && ValidPlayer(client, true))
    {
        InitPassiveSkills(client);
        
        GiveWeapon(client);
    }
}


public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim) && attacker!=victim)
    {
        //Do something if attacker is the client.
    }
    
    if (ValidPlayer(attacker) && ValidPlayer(victim) && War3_GetRace(victim) == thisRaceID)
    {
        //Do something if victim is the client.
    }
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    new race = War3_GetRace(client);
    if(race==thisRaceID && pressed && ability==0 && ValidPlayer(client,true))
    {
        new tornado_level=War3_GetSkillLevel(client,race,SKILL_TORNADO);
        if(tornado_level > 0) 
        {
            if(!Silenced(client))
            {
                if (War3_SkillNotInCooldown(client,thisRaceID,SKILL_TORNADO,true))
                {
                    new Float:pos[3];
                    new Float:lookpos[3];
                    War3_GetAimEndPoint(client,lookpos);
                    GetClientAbsOrigin(client,pos);
                    pos[1]+=60.0;
                    pos[2]+=60.0;
                    TE_SetupBeamPoints(pos, lookpos, TornadoSprite,TornadoSprite, 0, 5, 2.0,15.0,19.0, 2, 10.0, {54,66,120,100}, 60); 
                    TE_SendToAll();
                    pos[1]-=120.0;
                    TE_SetupBeamPoints(pos, lookpos, TornadoSprite,TornadoSprite, 0, 5, 2.0,15.0,19.0, 2, 10.0, {54,66,120,100}, 60);
                    TE_SendToAll();
                    new target = War3_GetTargetInViewCone(client,300.0,false,20.0);
                    if (ValidPlayer(target, true))
                    {
                        if (GetRandomFloat(0.0, 1.0) > fTornadoSelfChance)//Hit enemies, else hit self
                        {
                            War3_CooldownMGR(client,fTornadoCooldown[tornado_level],thisRaceID,SKILL_TORNADO);
                            TornadoEffect(client, target, TornadoJumps);
                        }
                        else
                        {
                            War3_CooldownMGR(client,fTornadoCooldown[tornado_level],thisRaceID,SKILL_TORNADO);
                            TornadoEffect(client, client, 0);
                        }
                    }
                }
            }
            else
            {
                PrintHintText(client,"Silenced: Can not cast");
            }
        }
        else
        {
            PrintHintText(client,"Level Tornado First");
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if (ValidPlayer(client, true) && race == thisRaceID && pressed)
    {
        new ult_teleport = War3_GetSkillLevel(client,race,ULT_TELEPORT);
        if (ult_teleport > 0 && War3_SkillNotInCooldown(client,race,ULT_TELEPORT,true) && !Silenced(client, false))
        {
            TeleportPlayerView(client, fTeleportDistance);
        }
    }
}

//
// Buff functions
//
static InitPassiveSkills(client)
{
    new race = War3_GetRace(client);
    
    new skill_guns = War3_GetSkillLevel(client, race, SKILL_GUNS);
    War3_SetBuff(client, iDamageMode, thisRaceID, 1);//Only bullets
    War3_SetBuff(client, fDamageModifier, thisRaceID, fGunsDamageModifier[skill_guns]);
    
    new skill_speed = War3_GetSkillLevel(client, race, SKILL_SPEED);
    War3_SetBuff(client, fMaxSpeed, thisRaceID, fRunSpeed[skill_speed]);
}

//
// GiveWeapon functions
//
static GiveWeapon(client)
{
    new String:weaponRestrictString[50];
    new String:weaponString[20];
    StrCat(weaponRestrictString, 50, "weapon_knife,weapon_hegrenade,");
    if (GetRandomFloat(0.0, 1.0) > fGunsChance)
    {
        StrCat(weaponRestrictString, 50, "weapon_usp");
        StrCat(weaponString, 20, "weapon_usp");
    }
    else
    {
        StrCat(weaponRestrictString, 50, "weapon_deagle");
        StrCat(weaponString, 20, "weapon_deagle");
    }
    War3_WeaponRestrictTo(client,thisRaceID,weaponRestrictString);
    if (!Client_HasWeapon(client, weaponString))
    {
        Client_GiveWeapon(client, weaponString, true);
    }
}

//
// Tornado functions
//
public Action:tornadoEffect(Handle:timer, any:client)
{
    ResetPack(TornadoDataPacks[client]);
    new target = ReadPackCell(TornadoDataPacks[client]);
    new nJumps = ReadPackCell(TornadoDataPacks[client]);
    CloseHandle(TornadoDataPacks[client]);
    TornadoDataPacks[client] = INVALID_HANDLE;
    if (ValidPlayer(client) && War3_GetRace(client) == thisRaceID)
    {
        TornadoEffect(client, target, nJumps);
    }
    return Plugin_Handled;
}

static TornadoEffect(client, target, nJumps)
{
    if(ValidPlayer(target, true) && War3_GetRace(client) == thisRaceID && !W3HasImmunity(target,Immunity_Skills))
    {
        new Float:targpos[3];
        GetClientAbsOrigin(target,targpos);
        TE_SetupBeamRingPoint(targpos, 20.0, 80.0,TornadoSprite,TornadoSprite, 0, 5, 2.6, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
        TE_SendToAll();
        targpos[2]+=20.0;
        TE_SetupBeamRingPoint(targpos, 40.0, 100.0,TornadoSprite,TornadoSprite, 0, 5, 2.4, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
        TE_SendToAll();
        targpos[2]+=20.0;
        TE_SetupBeamRingPoint(targpos, 60.0, 120.0,TornadoSprite,TornadoSprite, 0, 5, 2.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
        TE_SendToAll();
        targpos[2]+=20.0;
        TE_SetupBeamRingPoint(targpos, 80.0, 140.0,TornadoSprite,TornadoSprite, 0, 5, 2.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
        TE_SendToAll();    
        targpos[2]+=20.0;
        TE_SetupBeamRingPoint(targpos, 100.0, 160.0,TornadoSprite,TornadoSprite, 0, 5, 1.8, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
        TE_SendToAll();    
        targpos[2]+=20.0;
        TE_SetupBeamRingPoint(targpos, 120.0, 180.0,TornadoSprite,TornadoSprite, 0, 5, 1.6, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
        TE_SendToAll();    
        targpos[2]+=20.0;
        TE_SetupBeamRingPoint(targpos, 140.0, 200.0,TornadoSprite,TornadoSprite, 0, 5, 1.4, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
        TE_SendToAll();    
        targpos[2]+=20.0;
        TE_SetupBeamRingPoint(targpos, 160.0, 220.0,TornadoSprite,TornadoSprite, 0, 5, 1.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
        TE_SendToAll();    
        targpos[2]+=20.0;
        TE_SetupBeamRingPoint(targpos, 180.0, 240.0,TornadoSprite,TornadoSprite, 0, 5, 1.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
        TE_SendToAll();
        EmitSoundToAll(TornadoSound,client);
        EmitSoundToAll(TornadoSound,target);
        new Float:velocity[3];
        velocity[2]+=800.0;
        SetEntDataVector(target,m_vecBaseVelocity,velocity,true);
        CreateTimer(0.1,nado1,target);
        CreateTimer(0.4,nado2,target);
        CreateTimer(0.9,nado3,target);
        CreateTimer(1.4,nado4,target);
        new tornado_level=War3_GetSkillLevel(client,thisRaceID,SKILL_TORNADO);
        War3_DealDamage(target,TornadoDamage[tornado_level],client,DMG_GENERIC,"Tornado");
        
        if (nJumps > 0)
        {
            new Float:nextTargetPos[3];
            new Float:closestPos = fTornadoJumpRange+1.0;
            new closestPlayer = -1;
            for (new i=1; i<=MaxClients; i++)
            {
                if (ValidPlayer(i, true) && i != target && GetClientTeam(client) != GetClientTeam(i))
                {
                    GetClientAbsOrigin(i, nextTargetPos);
                    new Float:targetDistance = GetVectorDistance(nextTargetPos, targpos);
                    if (targetDistance <= fTornadoJumpRange)
                    {
                        if (targetDistance < closestPos)
                        {
                            closestPos = targetDistance;
                            closestPlayer = i;
                        }
                    }
                }
            }
            TornadoDataPacks[client] = CreateDataPack();
            WritePackCell(TornadoDataPacks[client], closestPlayer);
            WritePackCell(TornadoDataPacks[client], nJumps-1);
            CreateTimer(fTornadoJumpDelay, tornadoEffect, client);
        }
    }
    else
    {
        PrintHintText(client,"NO VALID TARGETS WITHIN %.1f FEET",30.0);
    }
}

public Action:nado1(Handle:timer,any:client)
{
    new Float:velocity[3];
    velocity[2]+=4.0;
    velocity[0]-=600.0;
    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}
public Action:nado2(Handle:timer,any:client)
{
    new Float:velocity[3];
    velocity[2]+=4.0;
    velocity[1]-=600.0;
    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:nado3(Handle:timer,any:client)
{
    new Float:velocity[3];
    velocity[2]+=4.0;
    velocity[0]+=600.0;
    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:nado4(Handle:timer,any:client)
{
    new Float:velocity[3];
    velocity[2]+=4.0;
    velocity[1]+=600.0;
    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

//
// Teleport functions
//
//Teleport code taken from Remy Lebeau's GamblingMan race.
bool:TeleportPlayerView(client,Float:distance)
{
    if(client>0){
        if(IsPlayerAlive(client)){
            new ult_teleport = War3_GetSkillLevel(client, thisRaceID, ULT_TELEPORT);
            War3_CooldownMGR(client,fTeleportCooldown[ult_teleport],thisRaceID,ULT_TELEPORT);
            War3_SetBuff(client, bDisarm, thisRaceID, true);
            CreateTimer(fDisarmTime, stopDisarm, client);
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
                CreateTimer(0.01, stopDisarm, client);
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
        CreateTimer(0.01, stopDisarm, client);
    }
    else
    {    
        //Cooldown setter moved to top of teleport function
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
public Action:stopDisarm(Handle:timer, any:client)
{
    War3_SetBuff(client, bDisarm, thisRaceID, false);
}