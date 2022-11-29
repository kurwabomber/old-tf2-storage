/**
* File: War3Source_999_Ghost.sp
* Description: Ghost Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_SIGHT, SKILL_RETURN, ULT_STEAL;


#define WEAPON_RESTRICT ""
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Ghost",
    author = "Remy Lebeau / ABGar",
    description = "ABGar's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


// Speed
new Float:GhostSpeed[6]={1.0,1.1,1.2,1.3,1.4};
 
// Sight
new Float:SightDistance[] = {0.0, 600.0, 700.0, 800.0, 1000.0};
new Float:SightDuration[] = {0.0, 3.0, 4.0, 5.0, 6.0};
new BeamSprite, HaloSprite;
new String:sightsound[]="war3source/apparition/vortexhit.wav";
 
// Return
new Float:ReturnSavedPos[MAXPLAYERS][3];
new bool:ReturnAnyPosSaved[MAXPLAYERS];
new Float:ReturnTeleportCooldown[6]={0.0,35.0,30.0,25.0,20.0};
new String:TeleportSound[] = "ambient/machines/teleport4.wav";
 
// Steal
new Float:StealRange[6] = {0.0,300.0,400.0,600.0,800.0};
new nHealthOffset, BurnSprite;
new String:UltSound[] = "war3source/apparition/touch.wav";
 
/* **************** OnWar3PluginReady **************** */
public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Ghost","ghost");

    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Ghostly Speed","Ghosts run faster when not weighed down by burdens of life (passive)",false,4);
    SKILL_SIGHT=War3_AddRaceSkill(thisRaceID,"Ghostly Sight","Nothing can hide from a ghost (+ability)",false,4);
    SKILL_RETURN=War3_AddRaceSkill(thisRaceID,"Past life","Return to the place you remembered most in life (+ability1)",false,4);
    ULT_STEAL=War3_AddRaceSkill(thisRaceID,"Steal from the living","Commune with the living... and steal their HP (+ultimate)",true,4);

    W3SkillCooldownOnSpawn( thisRaceID, SKILL_RETURN, 5.0, _ );

    War3_CreateRaceEnd(thisRaceID);
}
 
 public OnPluginStart()
{
    CreateTimer( 0.1, CalcSpeed, _, TIMER_REPEAT );
    CreateTimer(1.0, TelePortEffect,_,TIMER_REPEAT);
    nHealthOffset = FindSendPropOffs( "CBasePlayer", "m_iHealth" );
}



 
public OnMapStart()
{
BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
BeamSprite=PrecacheModel("sprites/strider_blackball.vmt");
HaloSprite=PrecacheModel("materials/sprites/lgtning.vmt");
//HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
War3_AddCustomSound(sightsound);
War3_PrecacheSound(TeleportSound);
War3_AddCustomSound(UltSound);


}
 
 
public OnWar3EventSpawn(client)
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer(client, true))
    {
        ReturnAnyPosSaved[client] = false;
            
    }
}
 
public OnRaceChanged(client,oldrace,newrace)
{
    if( newrace != thisRaceID )
    {
        War3_WeaponRestrictTo( client, thisRaceID, "" );
        W3ResetAllBuffRace( client, thisRaceID );
        ReturnAnyPosSaved[client] = false;
    }
    else
    {
        if( ValidPlayer(client, true) )
            ReturnAnyPosSaved[client] = false;
    }
}
 
 
 
 
/* *************************************** Speed *************************************** */

 
 
public Action:CalcSpeed( Handle:timer, any:userid )
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i, true))
        {
            if( War3_GetRace( i ) == thisRaceID )
            {
                new skill_speed = War3_GetSkillLevel( i, thisRaceID, SKILL_SPEED );
                if( skill_speed > 0)
                {
                    decl String:weapon[64];
                    GetClientWeapon(i, weapon, sizeof(weapon));
                    if(StrEqual(weapon, "weapon_knife"))
                    {
                        War3_SetBuff(i,fMaxSpeed,thisRaceID,GhostSpeed[skill_speed]);
                    }
                    else
                    {
                        War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
                    }
                }
            }              
        }
    }      
}
 
 
/* *************************************** Return *************************************** */   
 
public Action:ReturnTeleport(Handle:timer,any:client)
{
    new skill_return = War3_GetSkillLevel(client,thisRaceID,SKILL_RETURN);
    if(skill_return > 0)
    {
    
        new Float:origin[3];
        GetClientAbsOrigin(client,origin);
        TE_SetupBeamPoints(origin, ReturnSavedPos[client], BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {35,128,35,255}, 70);  
        TE_SendToAll();
        PrintHintText( client, "Returned to marked location" );
        War3_CooldownMGR(client,ReturnTeleportCooldown[skill_return],thisRaceID,SKILL_RETURN,false,true);
        TeleportEntity(client, ReturnSavedPos[client], NULL_VECTOR, NULL_VECTOR);
        ReturnAnyPosSaved[client] = false;
        EmitSoundToAll(TeleportSound,client,SNDCHAN_AUTO);
        War3_ShakeScreen(client);
    }      
}

public Action:TelePortEffect(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i, true))
        {
            if( War3_GetRace( i ) == thisRaceID && ReturnAnyPosSaved[i] )
            {
                TE_SetupBeamRingPoint(ReturnSavedPos[i],25.0,75.0,BeamSprite,HaloSprite,0,15,6.0,20.0,3.0,{100,100,150,255},20,0);
                TE_SendToClient(i);                
            }              
        }
    }     
}
 
public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true))
    {
        if(ability==1)      // TELEPORT
        {
            new skill_return = War3_GetSkillLevel(client,thisRaceID,SKILL_RETURN);
            if(skill_return > 0)
            {
                if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_RETURN,true ))
                {
                    if(ReturnAnyPosSaved[client] == false)
                    {
                        PrintHintText( client, "Location Marked" );
                        War3_CooldownMGR(client,10.0,thisRaceID,SKILL_RETURN,false,true);
                        GetClientAbsOrigin( client, ReturnSavedPos[client] );
                        ReturnAnyPosSaved[client] = true;
                    }
                    else
                    {
                        CreateTimer( 2.0, ReturnTeleport, client );
                        PrintHintText( client, "Teleporting in 2 seconds" );
                    }
                }
            }
            else
            {
                PrintHintText(client, "Level your Return first");
            }
        }
                
        if(ability==0 ) // GHOSTLY SIGHT
        {
            if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SIGHT,true))
            {
                new sight=War3_GetSkillLevel(client,thisRaceID,SKILL_SIGHT);
                if(sight>0)
                {
                    War3_CooldownMGR(client,20.0,thisRaceID,SKILL_SIGHT);
                    new Float:distance=SightDistance[sight];
                    new targetList[64];
                    new our_team=GetClientTeam(client);
                    new Float:our_pos[3];
                    GetClientAbsOrigin(client,our_pos);
                    new curIter=0;
                    for(new x=1;x<=MAXPLAYERS;x++)
                    {
                        if(ValidPlayer(x,true)&&client!=x&&GetClientTeam(x)!=our_team)
                        {
                            new Float:x_pos[3];
                            GetClientAbsOrigin(x,x_pos);
                            if(GetVectorDistance(our_pos,x_pos)<=distance )
                            {           
                                if (ClientViews(client, x, distance, 0.6))      
                                {
                                    targetList[curIter]=x;
                                    ++curIter;
                                }
                            }
                        }
                    }
                    for(new x=0;x<MAXPLAYERS;x++)
                    {
                        if(targetList[x]==0)
                            break;
                        War3_SetBuff(targetList[x],bInvisibilityDenyAll,thisRaceID,true);
                        {            
                            CreateTimer(SightDuration[sight],StopSight,GetClientUserId(targetList[x]));
                            PrintHintText(client,"No-one can hide from the Ghost!!!");
                            PrintHintText(targetList[x],"No-one can hide from the Ghost!!!");
                        }
                    }
                    new Float:origin[3];
                    new Float:targetpos[3];
                    
                    War3_GetAimEndPoint(client,targetpos);
                    GetClientAbsOrigin(client,origin);
                    TE_SetupBeamPoints(origin, targetpos, BeamSprite, HaloSprite, 0, 5, 1.0, 5.0, 15.0, 2, 5.0, {35,35,255,255}, 70);  
                    TE_SendToAll();
                    EmitSoundToAll(sightsound,client);
                }
                else
                {
                    PrintHintText(client, "Level your skill first");
                }
            }
        }
    }
}
 
 
 
public Action:StopSight(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    if(ValidPlayer(client))
    {
        War3_SetBuff(client,bInvisibilityDenyAll,thisRaceID,false);
    }
}
 
 
stock bool:ClientViews(Viewer, Target, Float:fMaxDistance=0.0, Float:fThreshold=0.73)
{
    // Retrieve view and target eyes position
    decl Float:fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    decl Float:fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    decl Float:fViewDir[3];
    decl Float:fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
    decl Float:fTargetDir[3];
    decl Float:fDistance[3];
   
    // Calculate view direction
    fViewAng[0] = fViewAng[2] = 0.0;
    GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
   
    // Calculate distance to viewer to see if it can be seen.
    fDistance[0] = fTargetPos[0]-fViewPos[0];
    fDistance[1] = fTargetPos[1]-fViewPos[1];
    fDistance[2] = 0.0;
    if (fMaxDistance != 0.0)
    {
        if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
            return false;
    }
   
    // Check dot product. If it's negative, that means the viewer is facing
    // backwards to the target.
    NormalizeVector(fDistance, fTargetDir);
    if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
   
    // Now check if there are no obstacles in between through raycasting
    new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace)) { CloseHandle(hTrace); return false; }
    CloseHandle(hTrace);
   
    // Done, it's visible
    return true;
}
 
// ----------------------------------------------------------------------------
// ClientViewsFilter()
// ----------------------------------------------------------------------------
public bool:ClientViewsFilter(Entity, Mask, any:Junk)
{
    if (Entity >= 1 && Entity <= MaxClients) return false;
    return true;
}  
 
 
 
/* *************************************** Steal *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new skill = War3_GetSkillLevel(client,thisRaceID,ULT_STEAL);
        if(skill > 0)
        {                      
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_STEAL,true))
            {
                new target=War3_GetTargetInViewCone(client,StealRange[skill],false,7.5);
                if(ValidPlayer(target,true)&&!W3HasImmunity(target,Immunity_Ultimates))
                {
                    War3_CooldownMGR(client,30.0,thisRaceID,ULT_STEAL,_,_);
                   
                    new targetHP = GetClientHealth(target);
                    new clientHP = GetClientHealth(client);
                    
                    if (targetHP > 100)
                    {
                        targetHP = 100;
                    }                    
                    SetEntData( target, nHealthOffset, clientHP );
                    SetEntData( client, nHealthOffset, targetHP );
                    
                    W3FlashScreen( client, RGBA_COLOR_BLUE );
                    W3FlashScreen( target, RGBA_COLOR_BLUE );
                    
                    PrintHintText(client,"You've swapped health!");
                    PrintHintText(target,"A Ghost has swapped their health with yours.");
                    
                    EmitSoundToAll(UltSound,client);
                    
                    new Float:origin[3];
                    new Float:targetpos[3];
                    
                    GetClientAbsOrigin(target,targetpos);
                    GetClientAbsOrigin(client,origin);
                    TE_SetupBeamPoints(origin, targetpos, BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
                    TE_SendToAll();
                    GetClientAbsOrigin(target,targetpos);
                    targetpos[2]+=70;
                    TE_SetupGlowSprite(targetpos,BurnSprite,1.0,1.9,255);
                    TE_SendToAll();
                }
                else
                {
                    PrintHintText(client, "No Target Found");
                }
            }
        }
        else
        {
            PrintHintText(client, "Level your Steal first.");
        }
    }
}















