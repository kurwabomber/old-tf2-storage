/**
* File: War3Source_999_ScopeMaster.sp
* Description: The Famas Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_AMMO, SKILL_LEECH, SKILL_SUMMON, ULT_TELEPORT;

#define WEAPON_RESTRICT "weapon_famas,weapon_knife"
#define WEAPON_GIVE "weapon_famas"

public Plugin:myinfo = 
{
    name = "War3Source Race - The Famas",
    author = "Remy Lebeau",
    description = "Kablamo's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:VampirePercent[5] = {0.0, 0.05, 0.10, 0.15, 0.20};
new Clip1Offset;
new bool:bAmmo[MAXPLAYERS];
new g_iWeaponAmmo[] = {25, 30, 35, 40, 45};

//Respawn
new Float:SummonCD[]={0.0,40.0,39.0,37.0,36.0,34.0,33.0,32.0,31.0,30.0};
new String:summon_sound[]="war3source/archmage/summon.wav";


// ULT_TELEPORT VARIABLES

new Float:TeleportDistance[]={0.0, 500.0, 600.0, 700.0, 800.0};
new TPFailCDResetToRace[MAXPLAYERSCUSTOM];
new TPFailCDResetToSkill[MAXPLAYERSCUSTOM];
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new Float:UltiCooldown = 30.0;

new String:teleport_sound[]="war3source/archmage/teleport.wav";

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("The Famas [PRIVATE]","thefamas");
    
    SKILL_AMMO=War3_AddRaceSkill(thisRaceID,"Full Blown","Extra 5 bullets in clip per level",false,4);
    SKILL_LEECH=War3_AddRaceSkill(thisRaceID,"Red Cross","Leech HP from your victims",false,4);
    SKILL_SUMMON=War3_AddRaceSkill(thisRaceID,"Fallen heroes","Revive a team mate (+ability)",false,4);
    ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Telewhat","Teleport (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, VampirePercent);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    Clip1Offset = FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" );
}



public OnMapStart()
{
    War3_AddCustomSound(teleport_sound);
    War3_AddCustomSound(summon_sound);
    HookEvent( "weapon_reload", WeaponReloadEvent );
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
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills( client );
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{
    bAmmo[client] = false;
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        GivePlayerItem( client, "weapon_famas" );
        new skill1 = War3_GetSkillLevel( client, thisRaceID, SKILL_AMMO );
        if( skill1 > 0)
        {
            CreateTimer( 1.0, SetWepAmmo, client );
            bAmmo[client] = true;
        }
        InitPassiveSkills( client );
    }
}



/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


public OnAbilityCommand(client,ability,bool:pressed)
{
    if(!Silenced(client)){
        new skill_summon=War3_GetSkillLevel(client,thisRaceID,SKILL_SUMMON);
        
        if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
            if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SUMMON,true)){
                if(skill_summon>0){
                    new Float:position111[3];
                    War3_CachedPosition(client,position111);
                    position111[2]+=5.0;
                    new targets[MAXPLAYERS];
                    new foundtargets;
                    for(new ally=1;ally<=MaxClients;ally++){
                        if(ValidPlayer(ally)){
                            new ally_team=GetClientTeam(ally);
                            new client_team=GetClientTeam(client);
                            if(War3_GetRace(ally)!=thisRaceID && !IsPlayerAlive(ally) && ally_team==client_team){
                                targets[foundtargets]=ally;
                                foundtargets++;
                            }
                        }
                    }
                    new target;
                    if(foundtargets>0){
                        target=targets[GetRandomInt(0, foundtargets-1)];
                        if(target>0){
                            War3_CooldownMGR(client,SummonCD[skill_summon],thisRaceID,SKILL_SUMMON);
                            new Float:ang[3];
                            new Float:pos[3];
                            War3_SpawnPlayer(target);
                            GetClientEyeAngles(client,ang);
                            GetClientAbsOrigin(client,pos);
                            TeleportEntity(target,pos,ang,NULL_VECTOR);
                            CreateTimer(3.0,normal,target);
                            CreateTimer(3.0,normal,client);
                            EmitSoundToAll(summon_sound,client);
                            CreateTimer(3.0, Stop, client);
                        }
                    }
                    else
                    {
                        PrintHintText(client,"There are no allies you can rez");
                    }
                }
                else
                {
                    PrintHintText(client, "Level your Respawn first");
                }
            }
        }
        
    }
    else
    {
        PrintHintText(client,"Silenced: Can not cast");
    }
    
}


public Action:normal(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new Float:end_dist=50.0;
		new Float:end_pos[3];
		GetClientAbsOrigin(client,end_pos);
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&i!=client)
			{
				new Float:pos[3];
				GetClientAbsOrigin(i,pos);
				new Float:dist=GetVectorDistance(end_pos,pos);
				if(dist<=end_dist)
				{
					CreateTimer(1.0,normal,client);
					break;
				}
			}
		}
	}
}


public Action:Stop(Handle:timer,any:client)
{
    StopSound(client,SNDCHAN_AUTO,summon_sound);
}


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
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/




/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/


public WeaponReloadEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer(client))
    {
        new skill_m4a1 = War3_GetSkillLevel( client, race, SKILL_AMMO );
        if( skill_m4a1 > 0 && bAmmo[client] )
        {
            CreateTimer( 3.5, SetWepAmmo, client );
        }
    }
}



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

    
public Action:SetWepAmmo( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        new level = War3_GetSkillLevel( client, thisRaceID, SKILL_AMMO );
        new wep_ent = W3GetCurrentWeaponEnt( client );
        SetEntData( wep_ent, Clip1Offset, g_iWeaponAmmo[level], 4 );

    }
}    


/***************************************************************************
*
*
*                TELEPORT FUNCTIONS
*
*
***************************************************************************/




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
        EmitSoundToAll(teleport_sound,client);
        EmitSoundToAll(teleport_sound,client);
        
        
        
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

    
   