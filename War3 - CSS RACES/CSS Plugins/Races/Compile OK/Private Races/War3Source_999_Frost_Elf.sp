/**
* File: War3Source_999_Frost_Elf.sp
* Description: Deceit Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_DAMAGE, SKILL_INVIS, SKILL_STUN, ULT_TELEPORT;



public Plugin:myinfo = 
{
    name = "War3Source Race - Frost Elf",
    author = "Remy Lebeau",
    description = "Teky's private race for War3Source",
    version = "1.2.1",
    url = "http://sevensinsgaming.com"
};




new Float:g_fSpeed[] = { 1.0, 1.2, 1.3, 1.4, 1.5 };
new Float:g_fInvis[] = { 1.0, 0.9, 0.7, 0.5, 0.25 };

new String:missilesnd[]="weapons/mortar/mortar_explode2.wav";
new BeamSprite;
new Float:MissileMaxDistance[]={0.00,1000.0,2000.0,3000.0,4000.0};
new Float:g_fStunTime[] = {0.0, 0.5, 1.0, 1.5, 2.0};
new bool:g_bInv[MAXPLAYERS][MAXPLAYERS];
new Float:g_fAbilityCooldown = 15.0;
new String:entangleSound[256];


new Float:DamageMultiplier[5] = { 0.0, 0.10, 0.20, 0.30, 0.4 };

// ULT_TELEPORT VARIABLES
new Float:TeleRD=750.0;
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:teleport_sound[]="war3source/archmage/teleport.wav";
new Float:g_fTeleportCooldown[]={0.0, 35.0, 30.0, 23.0, 17.0};

new GlowSprite;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Frost Elf [PRIVATE]","frostelf");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Travel in the wind","Increased speed",false,4);
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Natures Camo","Invisibility",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Frost bite","20-60% chance to do 25dmg over 5 seconds",false,4);
    SKILL_STUN=War3_AddRaceSkill(thisRaceID,"Cold snap","Trap enemy in ice - while they are trapped they cannot damage the frost elf (+ability)",false,4);
    ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Ultimate Blink","Teleport (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_STUN,5.0,_);
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,15.0,_);
    
    
    War3_CreateRaceEnd(thisRaceID);

    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_INVIS, fInvisibilitySkill, g_fInvis);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{
    War3_AddSoundFolder(entangleSound, sizeof(entangleSound), "entanglingrootsdecay1.mp3");
    War3_PrecacheSound(missilesnd);
    BeamSprite=PrecacheModel("sprites/tp_beam001.vmt");
    War3_AddCustomSound(teleport_sound);
    GlowSprite = PrecacheModel( "materials/sprites/purpleglow1.vmt" );
    War3_AddCustomSound(entangleSound);
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
    
    

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
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
        
        for(new i = 1; i <= MaxClients; i++)
        {
            g_bInv[client][i] = false;
        }    
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
        
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
    if(!Silenced(client))
    {
        if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
        {
            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_STUN);
            if(skill_level>0)
            {
                
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_STUN,true))
                {
                    new Float:origin[3];
                    new Float:targetpos[3];
                    War3_GetAimEndPoint(client,targetpos);
                    GetClientAbsOrigin(client,origin);
                    origin[2]+=30;
                    origin[1]+=20;
                    TE_SetupBeamPoints(origin, targetpos, BeamSprite, BeamSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {42,232,232,255}, 70);  
                    TE_SendToAll();
                    origin[1]-=40;
                    TE_SetupBeamPoints(origin, targetpos, BeamSprite, BeamSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {42,232,232,255}, 70);  
                    TE_SendToAll();
                    EmitSoundToAll(missilesnd,client);
                    War3_CooldownMGR(client,g_fAbilityCooldown,thisRaceID,SKILL_STUN);
                    new target = War3_GetTargetInViewCone(client,MissileMaxDistance[skill_level],false,5.0);
                    if(target>0 && !W3HasImmunity(target,Immunity_Skills))
                    {
                        War3_SetBuff(target,bNoMoveMode,thisRaceID,true);
                        W3FlashScreen(target,RGBA_COLOR_BLUE, 0.3, 0.4, FFADE_OUT);
                        W3SetPlayerColor( target, thisRaceID, 0, 0, 255, _, GLOW_SKILL );
                        new Handle:pack;
                        CreateDataTimer(g_fStunTime[skill_level],UnfreezePlayer,pack);
                        WritePackCell(pack, client);
                        WritePackCell(pack, target);
                        g_bInv[client][target] = true;
                        PrintHintText(target, "Frozen! You cannot damage the frost elf");
                        W3EmitSoundToAll(entangleSound, target);
                        W3EmitSoundToAll(entangleSound, target);
                    }
                }
            }
            else
            {
                PrintHintText(client,"Level up ability");
            }
        }
    }
    else
    {
        PrintHintText(client,"Silenced: Can not cast");
    }
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true)){
        if(!Silenced(client)){
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TELEPORT,true)){
                new ult_teleport=War3_GetSkillLevel(client,thisRaceID,ULT_TELEPORT);
                if(ult_teleport>0){
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

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DAMAGE );
            if( !Hexed( attacker, false ) && skill_level > 0 && !W3HasImmunity( victim, Immunity_Skills ) )
            {
                new tempdamage = RoundToFloor( damage * DamageMultiplier[skill_level] );
                if(damage + tempdamage > 97)
                {
                    tempdamage = 97 - damage;
                }
                War3_DealDamage( victim, tempdamage, attacker, DMG_BULLET, "frost_elf_claws" );
                
                new Float:pos[3];
                
                GetClientAbsOrigin( victim, pos );
                
                pos[2] += 50;
                
                TE_SetupGlowSprite( pos, GlowSprite, 2.0, 4.0, 255 );
                TE_SendToAll();

                W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DAMAGE );
                W3FlashScreen( victim, RGBA_COLOR_RED );
            }
        }
    }
}



public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(ValidPlayer(victim, true) && ValidPlayer(attacker, true) && victim!=attacker)
    {
        if(g_bInv[victim][attacker] == true )
        {    
            War3_DamageModPercent(0.0);
            return;
        }
    }
    return;
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




public Action:UnfreezePlayer(Handle:timer,Handle:pack)
{
    

    new client, target;
    ResetPack(pack);
    client = ReadPackCell(pack);
    target = ReadPackCell(pack);
    if(ValidPlayer(client) && ValidPlayer(target))
    {
        PrintHintText(target, "Unfrozen");
        War3_SetBuff(target,bNoMoveMode,thisRaceID,false);
        g_bInv[client][target] = false;
        W3ResetPlayerColor( target, thisRaceID );
        W3EmitSoundToAll(entangleSound, target);
        W3EmitSoundToAll(entangleSound, target);
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

