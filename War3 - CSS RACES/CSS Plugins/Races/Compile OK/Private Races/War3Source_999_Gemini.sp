/**
* File: War3Source_999_Gemini.sp
* Description: Gemini no Kanon Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new ULT_TELEPORT, SKILL_ARMOUR, SKILL_INVIS, ULT_LIGHTNING;

#define WEAPON_RESTRICT "weapon_knife"
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Gemini no Kanon",
    author = "Remy Lebeau",
    description = "kanon's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fDmgLevel[] = { 0.0, 0.85, 0.8, 0.75, 0.7 };

new Float:g_fInvisDuration[] = { 0.0, 2.0, 3.0, 3.5, 4.0 };
new Float:g_fInvisCooldown[] = { 0.0, 35.0, 30.0, 25.0, 20.0 };


// TELEPORT VARIABLES

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

// LIGHTNING VARIABLES
new Float:ChainDistance[5]={0.0,150.0,200.0,250.0,300.0};
new String:lightningSound[256]; //="war3source/lightningbolt.mp3";
new BeamSprite,HaloSprite,BloodSpray,BloodDrop;
new bool:bBeenHit[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; // [caster][victim] been hit this chain lightning?
new Float:g_fUltCooldown = 20.0;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Gemini no Kanon [PRIVATE]","gemini");
    
    SKILL_ARMOUR=War3_AddRaceSkill(thisRaceID,"Gold Saint","Damage Reduction",false,4);
    ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Another Dimension","Teleport(+ability)",false,4);
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Seventh Sense","Go invisible and fast (+ability1)",false,4);
    ULT_LIGHTNING=War3_AddRaceSkill(thisRaceID,"Galaxy Explosion","Fires an energy ball at your opponents (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{
    War3_AddCustomSound(teleport_sound);
    
    War3_AddSoundFolder(lightningSound, sizeof(lightningSound), "lightningbolt.mp3");

    BeamSprite=War3_PrecacheBeamSprite(); 
    HaloSprite=War3_PrecacheHaloSprite(); 
    
    
    BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
    if(GAMECSGO) {
        BloodDrop = PrecacheModel("decals/blood1.vmt");
    }
    else {
        BloodDrop = PrecacheModel("sprites/blood.vmt");
    }

    War3_AddCustomSound(lightningSound);
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
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        InitPassiveSkills( client );
    }
}




public OnSkillLevelChanged(client,race,skill,newskilllevel )
{
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
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


public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            if(ability==0 && pressed)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TELEPORT,true))
                {
                    new skill_tp=War3_GetSkillLevel(client,thisRaceID,ULT_TELEPORT);
                    if(skill_tp>0)
                    {      
                        new bool:success = Teleport(client,TeleportDistance[skill_tp]);
                        if(success)
                        {
                            TPFailCDResetToRace[client]=thisRaceID;
                            TPFailCDResetToSkill[client]=ULT_TELEPORT;
                            
                            War3_CooldownMGR(client,UltiCooldown,thisRaceID,ULT_TELEPORT,_,_);
                        }
                    }
                    else
                    {
                        PrintHintText(client, "Level Teleport first");
                    }
                }
            }
            if(ability==1 && pressed)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_INVIS,true))
                {
                    new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS);
                    if(skill_level>0)
                    {      
                        PrintHintText(client,"Disappear!");
                        W3FlashScreen(client,RGBA_COLOR_BLUE,1.0);
                        
                        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0  );
                        War3_SetBuff( client, bDoNotInvisWeapon, thisRaceID, false);
                        War3_SetBuff( client, bDisarm, thisRaceID, true);
                        War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.35);
                        
                        
                        
                        CreateTimer(g_fInvisDuration[skill_level],RemoveInvis,client);
                        War3_CooldownMGR( client, g_fInvisCooldown[skill_level], thisRaceID, SKILL_INVIS);
                    }
                    else
                    {
                        PrintHintText(client, "Level Teleport first");
                    }
                }
            }
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
        }
    }
}



public DoChain(client,Float:distance,dmg,bool:first_call,last_target)
{
    new target=0;
    new Float:target_dist=distance+1.0; // just an easy way to do this
    new caster_team=GetClientTeam(client);
    new Float:start_pos[3];
    if(last_target<=0)
        GetClientAbsOrigin(client,start_pos);
    else
        GetClientAbsOrigin(last_target,start_pos);
    for(new x=1;x<=MaxClients;x++)
    {
        if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Skills))
        {
            new Float:this_pos[3];
            GetClientAbsOrigin(x,this_pos);
            new Float:dist_check=GetVectorDistance(start_pos,this_pos);
            if(dist_check<=target_dist)
            {
                // found a candidate, whom is currently the closest
                target=x;
                target_dist=dist_check;
            }
        }
    }
    if(target<=0)
    {
    //DP("no target");
        // no target, if first call dont do cooldown
        if(first_call)
        {
            W3MsgNoTargetFound(client,distance);
        }
        else
        {
            War3_CooldownMGR(client,g_fUltCooldown,thisRaceID,ULT_LIGHTNING,_,_);
        }
    }
    else
    {
        // found someone
        bBeenHit[client][target]=true; // don't let them get hit twice
        War3_DealDamage(target,dmg,client,DMG_ENERGYBEAM,"chainlightning");
        PrintHintText(target,"Hit by Chain Lightning - %d HP",War3_GetWar3DamageDealt());
        PrintToConsole(client,"Damage Dealt by Chain Lightning - %d HP",War3_GetWar3DamageDealt());
        start_pos[2]+=30.0; // offset for effect
        decl Float:target_pos[3],Float:vecAngles[3];
        GetClientAbsOrigin(target,target_pos);
        target_pos[2]+=30.0;
        TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,HaloSprite,0,35,1.0,25.0,25.0,0,10.0,{255,100,255,255},40);
        TE_SendToAll();
        GetClientEyeAngles(target,vecAngles);
        TE_SetupBloodSprite(target_pos, vecAngles, {200, 20, 20, 255}, 28, BloodSpray, BloodDrop);
        TE_SendToAll();
        EmitSoundToAll( lightningSound , target,_,SNDLEVEL_TRAIN);
        new new_dmg=RoundFloat(float(dmg)*0.66);
        
        DoChain(client,distance,new_dmg,false,target);
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && IsPlayerAlive(client))
    {
        new skill=War3_GetSkillLevel(client,race,ULT_LIGHTNING);
        if(skill>0)
        {
            
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_LIGHTNING,true)&&!Silenced(client))
            {
                    
                for(new x=1;x<=MaxClients;x++)
                    bBeenHit[client][x]=false;
                
                new Float:distance=ChainDistance[skill];
                
                DoChain(client,distance,60,true,0);
            }
        }
        else
        { 
            W3MsgUltNotLeveled(client);
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



public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam)
        {
            new race_victim=War3_GetRace(victim);
            if(race_victim==thisRaceID )
            {
                new skill_armour = War3_GetSkillLevel(victim, thisRaceID, SKILL_ARMOUR);
                if (skill_armour>0)
                {
                    
                    War3_DamageModPercent(g_fDmgLevel[skill_armour]);
                    new Float:amount = (1-g_fDmgLevel[skill_armour]) * 100; 
                    PrintToConsole(attacker, "Damage Reduced by |%.2f| (percent) against Gemini no Kanon", amount);
                    PrintToConsole(victim, "Damage Reduced by |%.2f| (percent) by Gemini no Kanon", amount);
                }
            }
        }
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
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}



public Action:RemoveInvis(Handle:t,any:client)
{
    if(ValidPlayer(client))
    {
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0  );
        War3_SetBuff( client, bDoNotInvisWeapon, thisRaceID,false);
        War3_SetBuff( client, bDisarm, thisRaceID, false);
        War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0);
        PrintHintText(client,"Reappear.");
        W3FlashScreen(client,RGBA_COLOR_GREEN, 1.0);
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
        if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Skills))
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

    