#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_CLOAK, SKILL_BLINK, SKILL_SHIELD, ULT_VOID;

new BaseKnifeDamage = 65;

//SKILL_CLOAK
new Float:fCloakBase = 0.05;
new Float:fCloakMoveBase[] = {1.0,0.8,0.6,0.4,0.2};
new CloakHealthLoss[] = {0,-10,-20,-35,-50};

//SKILL_BLINK
new Float:fBlinkCooldown[] = {0.0,5.0,4.0,3.0,2.0};
new Float:fBlinkDistance=400.0;

new String:teleportSound[256];
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};

//SKILL_SHIELD
new ShieldCost[] = {0,4,3,2,1};
new MaxShieldCapacity = 250;
new ShieldRegenRate = 5;

//ULT_VOID
new GlowSprite;
new Float:fVoidDuration[] = {0.0,1.0,1.5,2.0,2.5};
new Float:fVoidCooldown[] = {0.0,30.0,25.0,20.0,15.0};
new Float:fVoidMaxDistance = 1000.0;


public Plugin:myinfo = 
{
    name = "War3Source Race - Zeratul",
    author = "Kibbles",
    description = "Zeratul race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Zeratul","zeratul");
    
    SKILL_CLOAK = War3_AddRaceSkill(thisRaceID, "Permanent Cloaking", "Become 5% visible whilst standing still, and 80-20% visible whilst moving (knife still shows), but lose 10/20/35/50 max health.", false, 4);
    SKILL_BLINK = War3_AddRaceSkill(thisRaceID, "Blink", "Teleport up to 400 units away every 5-2 seconds.", false, 4);
    SKILL_SHIELD = War3_AddRaceSkill(thisRaceID, "Protoss Shield", "Protoss Shield: Every 4/3/2/1 points of armour will absorb 1 damage.", false, 4);
    ULT_VOID = War3_AddRaceSkill(thisRaceID, "Void Prison", "Stun an enemy up to 1000 units away for 2,5-4 seconds, 30-15 second cooldown).", true, 4);
    
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_BLINK,10.0,_);
    W3SkillCooldownOnSpawn(thisRaceID,ULT_VOID,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
    CreateTimer(0.1,SetInvisTimer,_,TIMER_REPEAT);
    CreateTimer(1.0,ShieldRegenTimer,_,TIMER_REPEAT);
}


public OnMapStart()
{
    strcopy(teleportSound,sizeof(teleportSound),"war3source/blinkarrival.mp3");
    War3_PrecacheSound(teleportSound);
    GlowSprite = PrecacheModel( "materials/sprites/blueglow1.vmt" );
}


//
// Event handling
//

public OnRaceChanged( client, oldrace, newrace )
{
    if( newrace == thisRaceID && ValidPlayer(client))
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
        
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
        InitPassiveSkills( client );
    }
}


public OnAbilityCommand(client,ability,bool:pressed)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID && pressed && ability==0)
    {
        new skill_blink = War3_GetSkillLevel(client, thisRaceID, SKILL_BLINK);
        if (skill_blink>0 && War3_SkillNotInCooldown(client, thisRaceID, SKILL_BLINK, true) && !Silenced(client, false))
        {
            TeleportPlayerView(client, fBlinkDistance);
        }
    }
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if (ValidPlayer(client, true) && race == thisRaceID && pressed)
    {
        new ult_void = War3_GetSkillLevel(client,race,ULT_VOID);
        if (ult_void>0 && War3_SkillNotInCooldown(client,race,ULT_VOID,true) && !Silenced(client, false))
        {
            new target = War3_GetTargetInViewCone(client, fVoidMaxDistance, false, 23.0, CanHitThis);
            if (ValidPlayer(target, true) && !IsUltImmune(target))
            {
                War3_CooldownMGR(client,fVoidCooldown[ult_void],thisRaceID,ULT_VOID);
                War3_SetBuff(target, bBashed, race, true);
                new Float:targetPos[3];
                GetClientAbsOrigin(target, targetPos);
                targetPos[2]+=40.0;
                TE_SetupGlowSprite(targetPos, GlowSprite, fVoidCooldown[ult_void]/10, 5.0, 255);
                TE_SendToAll();
                CreateTimer(fVoidDuration[ult_void],UnStun,target);
                PrintHintText(client, "Void Prison Active");
                PrintHintText(target, "Caught in Void Prison");
            }
            else
            {
                PrintHintText(client, "Invalid/Immune Target");
            }
        }
    }
}
public Action:UnStun(Handle:timer,any:client)
{
    if(ValidPlayer(client)){
        War3_SetBuff(client, bBashed, thisRaceID, false);
    }
}


public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if (ValidPlayer(victim, true) && ValidPlayer(attacker, true) && victim != attacker)
    {
        if (War3_GetRace(attacker) == thisRaceID && damage>BaseKnifeDamage)
        {
            new Float:modifier = BaseKnifeDamage/damage;
            War3_DamageModPercent(modifier);
        }
        else if (War3_GetRace(victim) == thisRaceID)
        {
            new skill_shield = War3_GetSkillLevel(victim, thisRaceID, SKILL_SHIELD);
            if (skill_shield > 0 && GetClientTeam(victim) != GetClientTeam(attacker))
            {
                new shieldDamage = RoundToFloor(damage);
                new currentShield = Client_GetArmor(victim);
                shieldDamage = (shieldDamage > currentShield) ? currentShield : shieldDamage;
                
                
                new damageReduction = CalculateDamageReduction(shieldDamage, ShieldCost[skill_shield]);
                new Float:modifier = ((damage - damageReduction)/damage);
                
                Client_SetArmor(victim, currentShield - shieldDamage);
                War3_DamageModPercent(modifier);
            }
        }
    }
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer (client, true) && War3_GetRace(client) == thisRaceID)
    {
        if(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP))
        {
            new skill_cloak = War3_GetSkillLevel(client, thisRaceID, SKILL_CLOAK);
            War3_SetBuff(client, fInvisibilitySkill, thisRaceID, fCloakMoveBase[skill_cloak]);
        }
        
        /*
        //Stop left clicks, but not right
        buttons &= ~IN_ATTACK;
        */
    }
    return Plugin_Continue;
}


//
// Skill code
//

public InitPassiveSkills(client)
{
    if (ValidPlayer(client, true))
    {
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
        new skill_shield = War3_GetSkillLevel(client, thisRaceID, SKILL_SHIELD);
        if (skill_shield > 0)
        {
            Client_SetArmor(client, MaxShieldCapacity);
        }
        new skill_cloak = War3_GetSkillLevel(client, thisRaceID, SKILL_CLOAK);
        War3_SetBuff(client, iAdditionalMaxHealth, thisRaceID, CloakHealthLoss[skill_cloak]);
        War3_SetBuff(client, bInvisWeaponOverride, thisRaceID, true);
        War3_SetBuff(client, iInvisWeaponOverrideAmount, thisRaceID, 127);
    }
}


//Teleport code taken from Remy Lebeau's GamblingMan race.
bool:TeleportPlayerView(client,Float:distance)
{
    if(client>0){
        if(IsPlayerAlive(client)){
            new skill_blink = War3_GetSkillLevel(client, thisRaceID, SKILL_BLINK);
            War3_CooldownMGR(client,fBlinkCooldown[skill_blink],thisRaceID,SKILL_BLINK);
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
                War3_CooldownReset(client,thisRaceID,SKILL_BLINK);
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
                War3_CooldownReset(client,thisRaceID,SKILL_BLINK);
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
        War3_CooldownReset(client,thisRaceID,SKILL_BLINK);
    }
    else
    {    
        //Cooldown setter moved to top of teleport function
        //new skill_blink = War3_GetSkillLevel(client, thisRaceID, SKILL_BLINK);
        //War3_CooldownMGR(client,fBlinkCooldown[skill_blink],thisRaceID,SKILL_BLINK);
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
        if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Skills)){
            GetClientAbsOrigin(i,otherVec);
            if(GetVectorDistance(playerVec,otherVec)<300){
                return true;
            }
        }
    }
    return false;
}


//
// Tiner functions
//

public Action:SetInvisTimer(Handle:timer)
{
    for (new client=0; client<MAXPLAYERS; client++)
    {
        if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
        {
            new skill_cloak = War3_GetSkillLevel(client, thisRaceID, SKILL_CLOAK);
            if (skill_cloak > 0)
            {
                new Float:absVelVec[3];
                Entity_GetAbsVelocity(client, absVelVec);
                new Float:absVel = GetVectorLength(absVelVec);
                if (absVel == 0.0)
                {
                    War3_SetBuff(client, fInvisibilitySkill, thisRaceID, fCloakBase);
                }
            }
        }
    }
}

public Action:ShieldRegenTimer(Handle:timer)
{
    for (new client=0; client<MAXPLAYERS; client++)
    {
        if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
        {
            new skill_shield = War3_GetSkillLevel(client, thisRaceID, SKILL_SHIELD);
            if (skill_shield > 0)
            {
                new nextArmor = Client_GetArmor(client) + ShieldRegenRate;
                nextArmor = (nextArmor > MaxShieldCapacity) ? MaxShieldCapacity : nextArmor;
                Client_SetArmor(client, nextArmor);
                PrintHintText(client, "Armor: %i", nextArmor);
            }
        }
    }
}

//
// Helper functions
//

static CalculateDamageReduction(armor, subtrahend, count=0)
{
    return ((armor-subtrahend)>0) ? CalculateDamageReduction((armor-subtrahend), subtrahend, (count+1)) : count;
}