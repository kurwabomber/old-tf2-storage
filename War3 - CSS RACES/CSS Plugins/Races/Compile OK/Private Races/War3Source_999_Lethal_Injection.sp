/**
* File: War3Source_999_Lethal_Injection.sp
* Description: Ready's Private Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_REGENERATE, SKILL_LEFTCLICK, SKILL_RIGHTCLICK, ULT_TELEPORT;


// SKILL_REGENERATE VARIABLES
new Float:g_fRegenerate[]={0.0,1.0,2.0,3.0,4.0,5.0};

// SKILL_LEFTCLICK VARIABLES
// new Float:g_DrugAngles[] = { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };
// new UserMsg:g_FadeUserMsgId;
new Float:g_fBleed[] = { 0.0, 0.5, 1.0, 1.5, 2.0, 2.5 };
new bool:bFaerie[MAXPLAYERS];
new FaeriedBy[MAXPLAYERS];
new GlowSprite,GlowSprite2;
new Float:this_pos[3];
new Float:g_fLeftclickTimer=5.0;

// SKILL_RIGHTCLICK VARIABLES


// ULT_TELEPORT VARIABLES
new Float:TeleRD=750.0;
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:teleport_sound[]="war3source/archmage/teleport.wav";
new Float:g_fTeleportCooldown[]={0.0, 11.0, 10.0, 9.0, 8.0, 7.0, 6.0};
new Float:SpeedChance[6] = { 1.0, 1.25, 1.35, 1.45, 1.55, 1.65 };
new Float:InvisChance[6]={1.0, 0.55, 0.45, 0.35, 0.25, 0.15};
new Float:g_fBaseSpeed = 1.2;

new Handle:UltiTimer[MAXPLAYERS+1];


public Plugin:myinfo = 
{
    name = "War3Source Race - Lethal Injection",
    author = "Remy Lebeau",
    description = "Ready's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Lethal Injection [PRIVATE]","lethalinjection");
    
    SKILL_REGENERATE=War3_AddRaceSkill(thisRaceID,"Heal Thyself","You heal over time",false,5);
    SKILL_LEFTCLICK=War3_AddRaceSkill(thisRaceID,"Syringe","Make a target bleed, drugged and marked (Left Click)",false,5);
    SKILL_RIGHTCLICK=War3_AddRaceSkill(thisRaceID,"Compound Drugs","Do more damage if target is marked (Right Click)",false,5);
    ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"I need a doctor - STAT","Teleport + temporary speed and invis (+ultimate)",false,5);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{
    GlowSprite=PrecacheModel("effects/redflare.vmt");
    GlowSprite2=PrecacheModel("materials/effects/fluttercore.vmt");
    
    War3_AddCustomSound(teleport_sound);
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
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    
    new level_regenerate=War3_GetSkillLevel(client,thisRaceID,SKILL_REGENERATE);
    War3_SetBuff( client, fHPRegen, thisRaceID, g_fRegenerate[level_regenerate]  );
    
    War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fBaseSpeed );

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
    }
    else if (oldrace == thisRaceID)
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
                if(ult_teleport>0)
                {
                    if (UltiTimer[client] != INVALID_HANDLE)
                    {
            	        KillTimer(UltiTimer[client]);
            	        UltiTimer[client] = INVALID_HANDLE;
            	    }
                    TeleportPlayerView(client,TeleRD);
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





/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
    if( ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker) && victim != attacker )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new level_leftclick = War3_GetSkillLevel( attacker, thisRaceID, SKILL_LEFTCLICK );
            new level_rightclick = War3_GetSkillLevel( attacker, thisRaceID, SKILL_RIGHTCLICK );
            
            if(!W3HasImmunity(victim,Immunity_Skills) && !Silenced(attacker))
            {
            
                new buttons = GetClientButtons(attacker);
                if (!(buttons & IN_ATTACK2) && level_leftclick > 0 )
                {
                    
                    ServerCommand( "sm_drug #%d 1", GetClientUserId( victim ) );
                    
                    PrintHintText(attacker,"You injected your enemy (bleed/drug/mark)");
                    
                    War3_SetBuff( victim, fHPDecay, thisRaceID, g_fBleed[level_leftclick]  );
                    CreateTimer( g_fLeftclickTimer, StopBleed, victim );
                    
                    bFaerie[victim]=true;
                    FaeriedBy[victim]=attacker;
                    CreateTimer(g_fLeftclickTimer,faerieoff,victim);
                    

                }
                else if ((buttons & IN_ATTACK2) && level_rightclick > 0)
                {
                    if(bFaerie[victim]==true)
                    {
                        War3_DealDamage( victim, RoundToFloor( damage + (5 * level_rightclick) ), attacker, DMG_BULLET, "RichtClick" );
                        
                    }
                }
            }            
        }
    }        
}

public OnWar3EventDeath(victim,attacker)
{
    if(bFaerie[victim]==true)
    {
        bFaerie[victim]=false;
    }
    new race = War3_GetRace( attacker );
    if( race == thisRaceID && ValidPlayer( attacker, true ))
    {
        War3_CooldownMGR(attacker,0.0,thisRaceID,ULT_TELEPORT);
        PrintHintText(attacker, "Victim died, ultimate cooldown reset");
    }
}



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
        bFaerie[i]=false;
    }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        if (!IsValidEntity(weapon)) return Plugin_Continue;
        new String:weaponclassname[20];
        GetEntityClassname(weapon, weaponclassname, sizeof(weaponclassname));
        if (buttons & IN_ATTACK2 && StrEqual(weaponclassname, "weapon_knife"))
        {
            buttons |= IN_ATTACK;
            return Plugin_Changed;
        }
        return Plugin_Continue;
    }
    return Plugin_Continue;
}

public Action:faerieoff( Handle:timer, any:client )
{
    if(ValidPlayer(client))
    {
        bFaerie[client]=false;
    }
}

                    
public Action:StopBleed( Handle:timer, any:client )
{
    if( ValidPlayer( client ) )
    {
        War3_SetBuff( client, fHPDecay, thisRaceID, 0.0  );
        ServerCommand( "sm_drug #%d 0", GetClientUserId( client ) );
    }
}

public Action:StopInvis( Handle:timer, any:client )
{
    if( ValidPlayer( client ) )
    {
        UltiTimer[client] = INVALID_HANDLE;
        War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fBaseSpeed );
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
    }
}

public OnGameFrame()
{
    for(new i=1;i<=MaxClients;i++){
        if(ValidPlayer(i,true))
        {
            new tteam=GetClientTeam(i);
            if(bFaerie[i]==true)
            {
                GetClientAbsOrigin(i,this_pos);
                this_pos[2]+=20;//offset for effect
                if(tteam==2)
                {
                    TE_SetupGlowSprite(this_pos,GlowSprite,0.1,0.6,80);
                    TE_SendToAll();
                }
                else
                {
                    this_pos[2]+=20;
                    TE_SetupGlowSprite(this_pos,GlowSprite2,0.1,0.1,150);
                    TE_SendToAll();    
                }
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
        new ult_teleport=War3_GetSkillLevel(client,thisRaceID,ULT_TELEPORT);
        War3_CooldownMGR(client,g_fTeleportCooldown[ult_teleport],thisRaceID,ULT_TELEPORT);
        
        War3_SetBuff( client, fMaxSpeed, thisRaceID, SpeedChance[ult_teleport]  );
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, InvisChance[ult_teleport]);
        War3_SetBuff( client, bDoNotInvisWeapon,thisRaceID,true);
        
        UltiTimer[client] = CreateTimer( 4.0, StopInvis, client );
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
