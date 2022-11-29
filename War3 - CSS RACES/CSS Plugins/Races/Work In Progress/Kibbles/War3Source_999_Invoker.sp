#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/KibblesFunctions"
#include "W3SIncs/RemyFunctions"

////
//
// - Might need to do a 1 unit trace, filtered for players to check for valid tornado locations (otherwise it might go through walls)
// - Need to check every skill to be sure they obey skill immunities, and sets cooldowns, and checks the skill is leveled (except for invoke, which has a high initial cooldown)
// - War3_GetRaceSkillCount(raceID)-1
// - Cancel ghostwalk on attack or cast
// - Use Remy's HUD to display invoked spells
//
////

new thisRaceID;
new SKILL_COLDSNAP, SKILL_GHOSTWALK, SKILL_ICEWALL, SKILL_TORNADO, SKILL_DEAFENINGBLAST, SKILL_SUNSTRIKE, ULT_INVOKE;

new String:frost[]="war3source/roguewizard/frost.wav";

//Cold Snap
new Float:fColdSnapCooldown[] = {0.0, 20.0, 20.0, 20.0, 20.0};
new Float:fColdSnapBashCooldown[] = {0.0, 1.5, 1.25, 1.0, 0.75};
new Float:fColdSnapDuration[] = {0.0, 8.0, 8.0, 8.0, 8.0};
new Float:fBashDur = 0.5;
//new bool:bColdSnapActive[MAXPLAYERS+1] = {false, ...};
new bool:bColdSnapBashOnHit[MAXPLAYERS+1] = {false, ...};

//Ghost Walk
new Float:fGhostWalkCooldown[] = {0.0, 15.0, 15.0, 15.0, 15.0};
new Float:fGhostWalkVisibility[] = {0.0, 0.5, 0.4, 0.3, 0.2};
new Float:fGhostWalkDamageModifier[] = {1.0, 0.5, 0.4, 0.3, 0.2};
new Float:fGhostWalkSlow[] = {0.0, 0.8, 0.8, 0.8, 0.8};
new bool:bGhostWalkActive[MAXPLAYERS+1] = {false, ...};

//Ice Wall
#define ICEWALL_NAME "w3s_wall"
#define ICEWALL_MDL1 "models/props_lab/blastdoor001c.mdl"
#define LASER_SPRITE "materials/sprites/laserbeam.vmt"
#define EF_NODRAW 0x020
new String:crystallize[] = "physics/concrete/boulder_impact_hard1.wav";
new Float:fIceWallCooldown[] = {0.0, 30.0, 30.0, 30.0, 30.0};
new Float:fIceWallDuration[] = {0.0, 2.0, 4.0, 6.0, 8.0};
new iIceWallStrength = 600;
new Float:fIceWallMaxDistance = 500.0;

//Tornado
new String:tornado[]="war3source/roguewizard/tornado.wav";
new BeamSprite, HaloSprite;
new Float:fTornadoCooldown[] = {0.0, 25.0, 25.0, 25.0, 25.0};
new Float:fTornadoRange[] = {0.0, 50.0, 75.0, 100.0, 125.0};
new Float:fTornadoBaseThrow = 800.0;
new Float:fTornadoJumpLength[] = {0.0, 25.0, 40.0, 55.0, 70.0};
new iTornadoMaxJumps[] = {0, 5, 10, 15, 20};

//Deafening Blast
new Float:fDeafeningBlastCooldown[] = {0.0, 15.0, 15.0, 15.0, 15.0};
new Float:fDeafeningBlastRange[] = {0.0, 100.0, 200.0, 300.0, 400.0};
new Float:fDeafeningBlastBaseThrow = 250.0;
new Float:fDeafeningBlastDisarmDuration[] = {0.0, 1.0, 1.0, 1.0, 1.0};

//Sunstrike
new String:fire[]="war3source/roguewizard/fire.wav";
new BurnSprite;
new Float:fSunstrikeCooldown[] = {0.0, 25.0, 25.0, 25.0, 25.0};
new Float:fSunstrikeHitChance[] = {0.0, 0.5, 0.6, 0.7, 0.8};
new iSunstrikeDamage[] = {0, 50, 50, 50, 50};
new Float:fSunstrikeBurnTime[] = {0.0, 2.0, 2.0, 2.0, 2.0};

//Invoke
/*Keep CastInvocation updated, it's located near the end of the file.
Up to 8 skills can be used, as menu pagination is disabled*/
new Float:fInvokeCooldown[] = {60.0, 20.0, 15.0, 10.0, 5.0};
new iInvocations[MAXPLAYERS][2];


public Plugin:myinfo = 
{
    name = "War3Source Race - Invoker",
    author = "Siegfried (coded by Kibbles)",
    description = "Invoker race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Invoker","invoker");
    
    SKILL_COLDSNAP = War3_AddRaceSkill(thisRaceID, "Cold Snap", "Attacks freeze your target for the next 8 seconds\n0.5 second bash every 1.5/1.25/1/0.75 seconds per target", false, 4);
    SKILL_GHOSTWALK = War3_AddRaceSkill(thisRaceID, "Ghost Walk", "Fade away until your next strike\n50/40/30/20% visibility, 0.8 movement speed\n and 80% damage reducction until next attack/cast", false, 4);
    SKILL_ICEWALL = War3_AddRaceSkill(thisRaceID, "Ice Wall", "Create a wall of ice for 2/4/6/8 seconds", false, 4);
    SKILL_TORNADO = War3_AddRaceSkill(thisRaceID, "Tornado", "Throw enemies ahead of you into the air\nLeveling increases throw distance", false, 4);
    SKILL_DEAFENINGBLAST = War3_AddRaceSkill(thisRaceID, "Deafening Blast", "Disarm nearby enemies and throw them from their weapons\nLeveling increases throw distance", false, 4);
    SKILL_SUNSTRIKE = War3_AddRaceSkill(thisRaceID, "Sunstrike", "Burn a distant enemy for 50 damage\n50/40/30/20% chance to miscast", false, 4);
    ULT_INVOKE = War3_AddRaceSkill(thisRaceID, "Invoke Spell (ultimate)", "Invoke a spell.\nFirst cast binds +ability\nFurther casts bind +ability1\n20/15/10/5 second cooldown, only one ability if unleveled", true, 4);
    
    War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
    for (new i=1; i<=MaxClients; i++)
    {
        ResetInvocations(i);
    }
}


public OnMapStart()
{
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
    PrecacheModel(ICEWALL_MDL1);
    PrecacheModel(LASER_SPRITE);
    War3_PrecacheSound(crystallize);
    War3_PrecacheSound(tornado);
    War3_AddCustomSound(fire);
    War3_AddCustomSound(tornado);
    War3_AddCustomSound(frost);
    
    CreateTimer(1.0, HudInfo_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


public OnRaceChanged(client, oldrace, newrace)
{
    if(newrace == thisRaceID && ValidPlayer(client))
    {
        if(ValidPlayer(client))
        {
            InitializeRace(client);
        }
    }
    else if (oldrace == thisRaceID && ValidPlayer(client))
    {
        ResetInvocations(client);
        EndGhostWalk(client);
        W3ResetAllBuffRace(client, thisRaceID);
        War3_WeaponRestrictTo(client, thisRaceID, "");
        HUD_Add(GetClientUserId(client), "");
    }
}


public OnWar3EventSpawn(client)
{
    if(War3_GetRace(client) == thisRaceID && ValidPlayer(client, true))
    {
        InitializeRace(client);
    }
}


public OnW3TakeDmgBullet(victim, attacker, Float:damage)
{
    if (War3_GetRace(attacker) == thisRaceID && !SameTeam(attacker, victim) && bColdSnapBashOnHit[attacker] && !W3HasImmunity(victim,Immunity_Skills))
    {
        StartBashing(attacker, victim);
    }
}


public OnW3TakeDmgAllPre(victim, attacker, Float:damage)
{
    if (War3_GetRace(victim) == thisRaceID && bGhostWalkActive[victim] && !W3HasImmunity(attacker,Immunity_Skills))
    {
        new skill_ghostwalk = War3_GetSkillLevel(victim, thisRaceID, SKILL_GHOSTWALK);
        
        if (skill_ghostwalk > 0)
        {
            War3_DamageModPercent(fGhostWalkDamageModifier[skill_ghostwalk]);
            PrintToConsole(attacker, "Damage Reduced by Ghost Walk");
        }
    }
}


public Action:OnPlayerRunCmd (client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (ValidPlayer (client, true) && War3_GetRace(client) == thisRaceID && bGhostWalkActive[client])
    {
        if (buttons & (IN_ATTACK | IN_ATTACK2))
        {
            EndGhostWalk(client);
        }
    }
    return Plugin_Continue;
}


public OnAbilityCommand(client, ability, bool:pressed)
{
    if (ValidPlayer(client, true) && War3_GetRace(client)==thisRaceID && !Silenced(client) && pressed)
    {
        if (ability == 0)
        {
            CastInvocation(client, iInvocations[client][0]);
        }
        else if (ability == 1)
        {
            CastInvocation(client, iInvocations[client][1]);
        }
        
        if (bGhostWalkActive[client])
        {
            EndGhostWalk(client);
        }
    }
}


public OnUltimateCommand(client, race, bool:pressed)
{
    if (ValidPlayer(client, true) && War3_GetRace(client)==thisRaceID && !Silenced(client) && pressed)
    {
        Invoke(client);
        
        //Deprecated GhostWalk check. If you wish to re-activate this,
        //then remove the Menu GhostWalk check.
        /*if (bGhostWalkActive[client])
        {
            EndGhostWalk(client);
        }*/
    }
}


//
// Passive functions
//

InitializeRace(client)
{
    ResetInvocations(client);
    EndGhostWalk(client);
    //bColdSnapActive[client] = false;
    bColdSnapBashOnHit[client] = false;
    War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife");
}


//
// Skill functions
//

ColdSnap(client)
{
    if (W3IsSkillLeveled(client, thisRaceID, SKILL_COLDSNAP, true))
    {
        if (War3_SkillNotInCooldown(client, thisRaceID, SKILL_COLDSNAP, true))
        {
            bColdSnapBashOnHit[client] = true;
            PrintHintText(client, "Hit someone to activate Cold Snap");
        }
    }
}

StartBashing(client, target)
{
    new skill_coldsnap = War3_GetSkillLevel(client, thisRaceID, SKILL_COLDSNAP);
    War3_CooldownMGR(client, fColdSnapCooldown[skill_coldsnap], thisRaceID, SKILL_COLDSNAP);
    //bColdSnapActive[target] = true;
    bColdSnapBashOnHit[client] = false;
    EmitSoundToAll(frost,client);
    EmitSoundToAll(frost,target);
    PrintHintText(client, "Activated Cold Snap");
    PrintHintText(target, "Hit by Cold Snap");
    for (new Float:time=0.1; time<=fColdSnapDuration[skill_coldsnap]; time+=fColdSnapBashCooldown[skill_coldsnap])
    {
        CreateTimer(time, ActivateBash, target);
    }
    CreateTimer(fColdSnapDuration[skill_coldsnap], DeactivateColdSnap, client);
}

public Action:ActivateBash(Handle:timer, any:client)
{
    if (ValidPlayer(client, true) && !W3HasImmunity(client,Immunity_Skills))
    {
        War3_SetBuff(client, bBashed, thisRaceID, true);
        CreateTimer(fBashDur, DeactivateBash, client);
    }
}

public Action:DeactivateBash(Handle:timer, any:client)
{
    War3_SetBuff(client, bBashed, thisRaceID, false);
}

public Action:DeactivateColdSnap(Handle:timer, any:client)
{
    //bColdSnapActive[client] = false;
    PrintHintText(client, "Cold Snap deactivated");
}


GhostWalk(client)
{
    if (W3IsSkillLeveled(client, thisRaceID, SKILL_GHOSTWALK, true))
    {
        new skill_ghostwalk = War3_GetSkillLevel(client, thisRaceID, SKILL_GHOSTWALK);
        
        if (War3_SkillNotInCooldown(client, thisRaceID, SKILL_GHOSTWALK, true))
        {
            CreateTimer(0.1, ActivateGhostWalk, client);
            War3_SetBuff(client, fInvisibilitySkill, thisRaceID, fGhostWalkVisibility[skill_ghostwalk]);
            War3_SetBuff(client, fSlow, thisRaceID, fGhostWalkSlow[skill_ghostwalk]);
            PrintHintText(client, "Ghost Walk activated");
        }
    }
}

public Action:ActivateGhostWalk(Handle:timer, any:client)
{
    //This timer is required to stop EndGhostWalk from proccing in OnAbilityCommand
    bGhostWalkActive[client] = true;
}

EndGhostWalk(client)
{
    new skill_ghostwalk = War3_GetSkillLevel(client, thisRaceID, SKILL_GHOSTWALK);
    if (bGhostWalkActive[client])
    {
        War3_CooldownMGR(client, fGhostWalkCooldown[skill_ghostwalk], thisRaceID, SKILL_GHOSTWALK);
        bGhostWalkActive[client] = false;
        W3ResetBuffRace(client, fInvisibilitySkill, thisRaceID);
        W3ResetBuffRace(client, fSlow, thisRaceID);
        PrintHintText(client, "Ghost Walk deactivated");
    }
}


IceWall(client)
{
    if (W3IsSkillLeveled(client, thisRaceID, SKILL_ICEWALL, true))
    {
        new skill_icewall = War3_GetSkillLevel(client, thisRaceID, SKILL_ICEWALL);
        
        if (War3_SkillNotInCooldown(client, thisRaceID, SKILL_ICEWALL, true))
        {
            War3_CooldownMGR(client, fIceWallCooldown[skill_icewall], thisRaceID, SKILL_ICEWALL);
            W3_IceWall(client, skill_icewall, GetClientTeam(client));
        }
    }
}

stock W3_IceWall(client,skill,team){
    //Code adapted from Revan's Anivia race
    //return;
    decl Float:fClientAimPos1[3];
    decl Float:fClientAimPos2[3];
    decl Float:fAngles[3];
    GetClientEyeAngles(client, fAngles);
    new ax = 1;
    fAngles[0]=0.0,fAngles[2]=0.0;//we only need the 'theoretical' yaw value...
    if(fAngles[1]<150 && fAngles[1]>25) {
        ax = 0;
        fAngles[1]=90.0;
    }
    else if(fAngles[1]>-150 && fAngles[1]<-25) {
        ax = 0;
        fAngles[1]=90.0;
    }
    War3_GetAimEndPoint(client, fClientAimPos1);
    
    //Kibbles' addition
    new Float:clientPos[3];
    GetClientAbsOrigin(client, clientPos);
    if (GetVectorDistance(fClientAimPos1, clientPos) > fIceWallMaxDistance)
    {
        PrintHintText(client, "Too far away to place IceWall");
        War3_CooldownReset(client, thisRaceID, SKILL_ICEWALL);
        return;
    }
    //End addition
    
    fClientAimPos2[0]=fClientAimPos1[0],fClientAimPos2[1]=fClientAimPos1[1],fClientAimPos2[2]=fClientAimPos1[2];
    new Float:duration = fIceWallDuration[skill]; //max duration!
    new ent = SpawnFrozenProp(fClientAimPos1,fAngles,ICEWALL_MDL1,iIceWallStrength,team,duration,true);
    EmitSoundToAll(crystallize, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, fClientAimPos1, NULL_VECTOR, true, 0.0);
    //0=pitch/1=yaw/2=roll
    //my workaround to keep the walls in the right "direction"..    
    /*for(new i = 1; i <= skill; i++){
        new randomizer = GetRandomInt(80,110);
        fClientAimPos1[ax]+=randomizer;    
        fClientAimPos2[ax]-=randomizer;    
        SpawnFrozenProp(fClientAimPos1,fAngles,ICEWALL_MDL1,iIceWallStrength,team,duration,true);
        SpawnFrozenProp(fClientAimPos2,fAngles,ICEWALL_MDL1,iIceWallStrength,team,duration,true);
    }*/
    new randomizer = GetRandomInt(80,110);
    fClientAimPos1[ax]+=randomizer;    
    fClientAimPos2[ax]-=randomizer;    
    SpawnFrozenProp(fClientAimPos1,fAngles,ICEWALL_MDL1,iIceWallStrength,team,duration,true);
    SpawnFrozenProp(fClientAimPos2,fAngles,ICEWALL_MDL1,iIceWallStrength,team,duration,true);
    /*TE_SetupBeamPoints(fClientAimPos1, fClientAimPos2, BeamSprite, HaloSprite, 0, 35, duration, 
            120.0, 120.0, 0, 0.0, {100,100,255}, 10);
    TE_SendToAll();*/
    fClientAimPos1[2]+=35;
    fClientAimPos2[2]+=35;
    //fClientAimPos1[ax]+=40;
    //fClientAimPos2[ax]-=40;
    fClientAimPos1[ax]+=randomizer;
    fClientAimPos2[ax]-=randomizer;
    new beam_ent = CreateEntityByName("env_beam");
    if (beam_ent > 0 && IsValidEdict(beam_ent))
    {
        decl String:beamname[16];
        Format(beamname, sizeof(beamname), "w3s_beam_%d", client);
        DispatchKeyValueVector(beam_ent, "origin", fClientAimPos1);
        SetEntPropVector(beam_ent, Prop_Send, "m_vecEndPos", fClientAimPos2);
        
        SetEntityModel(beam_ent, LASER_SPRITE);
        SetEntPropFloat(beam_ent, Prop_Send, "m_fWidth", 100.0);
        SetEntPropFloat(beam_ent, Prop_Send, "m_fEndWidth", 100.0);

        DispatchKeyValue(beam_ent, "texture", LASER_SPRITE);
        DispatchKeyValue(beam_ent, "targetname", beamname);
        DispatchKeyValue(beam_ent, "LightningStart", beamname);
        DispatchKeyValue(beam_ent, "TouchType", "0");
        DispatchKeyValue(beam_ent, "BoltWidth", "12.0");
        DispatchKeyValue(beam_ent, "life", "0");
        DispatchKeyValue(beam_ent, "rendercolor", "0 0 0");
        DispatchKeyValue(beam_ent, "renderamt", "0");
        DispatchKeyValue(beam_ent, "HDRColorScale", "1.0");
        DispatchKeyValue(beam_ent, "decalname", "Bigshot");
        DispatchKeyValue(beam_ent, "StrikeTime", "0");
        DispatchKeyValue(beam_ent, "TextureScroll", "35");
        SetEntityRenderMode(beam_ent, RENDER_TRANSCOLOR);
        SetEntityRenderColor(beam_ent, 100, 100, 255);
        SetEntityRenderFx(beam_ent,RENDERFX_NO_DISSIPATION);
        AcceptEntityInput(beam_ent, "TurnOn");
        CreateTimer(duration, Timer_RemoveEntity, beam_ent);
    }
}

stock SpawnFrozenProp(const Float:Origin[3],const Float:fAngles[3],String:modelName[],iHealth,iTeamNum,Float:fLifetime,bool:bDrawInvisible=false) {
    new PhysicsProp = CreateEntityByName("prop_physics_override");
    SetEntityModel(PhysicsProp, modelName);
    DispatchKeyValue(PhysicsProp, "StartDisabled", "false");
    DispatchKeyValue(PhysicsProp, "classname", ICEWALL_NAME);
    DispatchKeyValue(PhysicsProp, "disableshadows", "1");
    SetEntProp(PhysicsProp, Prop_Data, "m_CollisionGroup", 6);
    //SetEntProp(PhysicsProp, Prop_Data, "m_usSolidFlags", 5);
    //SetEntProp(PhysicsProp, Prop_Data, "m_nSolidType", 6);
    DispatchSpawn(PhysicsProp);
    AcceptEntityInput(PhysicsProp, "DisableMotion");
    SetEntProp(PhysicsProp, Prop_Send, "m_iTeamNum", iTeamNum);
    TeleportEntity(PhysicsProp, Origin, fAngles, NULL_VECTOR);
    if(iHealth>0) {
        SetEntProp(PhysicsProp, Prop_Data, "m_iHealth", iHealth);
        SetEntProp(PhysicsProp, Prop_Data, "m_takedamage", 2);
    }
    if(bDrawInvisible) { //haaxxx them away!
        SetEntProp(PhysicsProp, Prop_Send, "m_fEffects", GetEntProp(PhysicsProp, Prop_Send, "m_fEffects") | EF_NODRAW);
    }
    ModifyEntityAddDeathTimer(PhysicsProp, fLifetime);
    return PhysicsProp;
}

public Action:Timer_RemoveEntity(Handle:timer,any:i)if(IsValidEdict(i))AcceptEntityInput(i,"Kill");


Tornado(client)
{
    //Code adapted from Lucky's RogueWizard race
    if (W3IsSkillLeveled(client, thisRaceID, SKILL_TORNADO, true))
    {
        new skill_tornado = War3_GetSkillLevel(client, thisRaceID, SKILL_TORNADO);
        
        if (War3_SkillNotInCooldown(client, thisRaceID, SKILL_TORNADO, true))
        {
            War3_CooldownMGR(client,fTornadoCooldown[skill_tornado],thisRaceID,SKILL_TORNADO);
            new Float:position[3];
            GetClientAbsOrigin(client, position);
            position[2] += 5.0;
            new Float:direction[3];
            GetDirVecFromEyes(client, direction, fTornadoJumpLength[skill_tornado]);
            TornadoGraphicAndThrow(client, position, direction, iTornadoMaxJumps[skill_tornado]);
        }
    }
}

stock TornadoGraphicAndThrow(client, Float:position[3], Float:direction[3], jumpsLeft)
{
    if (jumpsLeft > 0)
    {
        EmitSoundToAll(tornado,client);
        new skill_tornado = War3_GetSkillLevel(client, thisRaceID, SKILL_TORNADO);
        TE_SetupBeamRingPoint(position, 0.0, fTornadoRange[skill_tornado], BeamSprite, HaloSprite, 0, 15, 1.0, 20.0, 3.0, {100,100,150,255}, 20, 0);
        TE_SendToAll();
        new Float:width = 10.0;
        /*for (new i=0; i<10; i++)
        {
            TE_SetupBeamRingPoint(position, width, width, BeamSprite, BeamSprite, 0, 5, 1.0, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
            TE_SendToAll();
            position[2] += 5.0;
            width += 5.0;
        }*/
        TE_SetupBeamRingPoint(position, width, width, BeamSprite, BeamSprite, 0, 5, 1.0, 20.0, 1.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
        TE_SendToAll();
        
        for(new target=0;target<=MaxClients;target++){
            if(ValidPlayer(target,true) && !W3HasImmunity(target,Immunity_Skills)){
                new client_team=GetClientTeam(client);
                new target_team=GetClientTeam(target);

                if(target_team!=client_team){
                    new Float:targetPos[3];
                    new Float:clientPos[3];
                    AddVectors(NULL_VECTOR, position, clientPos);
                
                    GetClientAbsOrigin(target, targetPos);
                    //GetClientAbsOrigin(client, clientPos);
                    if(GetVectorDistance(targetPos,clientPos)<=fTornadoRange[skill_tornado]){
                        new Float:velocity[3];
                        new Float:xModifier = ((targetPos[0]-clientPos[0]) > 0.0) ? 1.0 : -1.0;
                        new Float:yModifier = ((targetPos[1]-clientPos[1]) > 0.0) ? 1.0 : -1.0;
                        velocity[0] = xModifier*(fTornadoRange[skill_tornado] - float((RoundFloat(targetPos[0]-clientPos[0])%RoundFloat(fTornadoRange[skill_tornado]))));
                        velocity[1] = yModifier*(fTornadoRange[skill_tornado] - float((RoundFloat(targetPos[1]-clientPos[1])%RoundFloat(fTornadoRange[skill_tornado]))));
                        velocity[2] = fTornadoBaseThrow;
                        Entity_SetBaseVelocity(target, velocity);
                    }
                }
            }
        }
        position[0] += direction[0];
        position[1] += direction[1];
        position[2] += direction[2];
        jumpsLeft -= 1;
        TornadoGraphicAndThrow(client, position, direction, jumpsLeft);
    }
}


DeafeningBlast(client)
{
    if (W3IsSkillLeveled(client, thisRaceID, SKILL_DEAFENINGBLAST, true))
    {
        new skill_deafeningblast = War3_GetSkillLevel(client, thisRaceID, SKILL_DEAFENINGBLAST);
        
        if (War3_SkillNotInCooldown(client, thisRaceID, SKILL_DEAFENINGBLAST, true))
        {
            War3_CooldownMGR(client,fDeafeningBlastCooldown[skill_deafeningblast],thisRaceID,SKILL_DEAFENINGBLAST);
            
            new Float:clientPos[3];
            GetClientAbsOrigin(client, clientPos);
            for (new i=1; i<=MaxClients; i++)
            {
                if (ValidPlayer(i, true))
                {
                    if (!SameTeam(client, i) && !W3HasImmunity(i,Immunity_Skills))
                    {
                        new Float:targetPos[3];
                        GetClientAbsOrigin(i, targetPos);
                        War3_SetBuff(i, bDisarm, thisRaceID, true);
                        CreateTimer(fDeafeningBlastDisarmDuration[skill_deafeningblast], DisableDisarm, i);
                        if (GetVectorDistance(clientPos, targetPos) <= fDeafeningBlastRange[skill_deafeningblast])
                        {
                            new Float:targetVelocity[3];
                            Entity_GetBaseVelocity(i, targetVelocity);
                            new Float:xModifier = ((targetPos[0]-clientPos[0]) > 0.0) ? 1.0 : -1.0;
                            new Float:yModifier = ((targetPos[1]-clientPos[1]) > 0.0) ? 1.0 : -1.0;
                            targetVelocity[0] = xModifier*(fDeafeningBlastRange[skill_deafeningblast] - float((RoundFloat(targetPos[0]-clientPos[0])%RoundFloat(fDeafeningBlastRange[skill_deafeningblast]))));
                            targetVelocity[1] = yModifier*(fDeafeningBlastRange[skill_deafeningblast] - float((RoundFloat(targetPos[1]-clientPos[1])%RoundFloat(fDeafeningBlastRange[skill_deafeningblast]))));
                            targetVelocity[2] = fDeafeningBlastBaseThrow;
                            
                            targetPos[2] += 40;
                            TE_SetupBeamPoints(clientPos, targetPos, BeamSprite, HaloSprite, 0, 0, 0.5, 5.0, 1.0, 0, 0.0, {255, 255, 255, 255}, 0);
                            TE_SendToAll();
                            TE_SetupBeamRingPoint(clientPos, 0.0, GetVectorDistance(clientPos, targetPos), BeamSprite, HaloSprite, 0, 0, 0.5, 5.0, 0.0, {255, 255, 255, 255}, 20, 0);
                            TE_SendToAll();
                            
                            FakeClientCommand(i, "drop");
                            Entity_SetBaseVelocity(i, targetVelocity);
                            PrintHintText(i, "Hit by Deafening Blast");
                        }
                    }
                }
            }
        }
    }
}

public Action:DisableDisarm(Handle:timer, any:client)
{
    War3_SetBuff(client, bDisarm, thisRaceID, false);
}


SunStrike(client)
{
    //Code adapted from Lucky's RogueWizard race
    new skill_sunstrike=War3_GetSkillLevel(client, thisRaceID, SKILL_SUNSTRIKE);
    
    if (W3IsSkillLeveled(client, thisRaceID, SKILL_SUNSTRIKE, true))
    {
        if (War3_SkillNotInCooldown(client, thisRaceID, SKILL_SUNSTRIKE, true))
        {
            new target = War3_GetTargetInViewCone(client,9000.0,false,10.0);
            if (ValidPlayer(target, true))
            {
                War3_CooldownMGR(client, fSunstrikeCooldown[skill_sunstrike], thisRaceID, SKILL_SUNSTRIKE);
                
                if (!W3HasImmunity(target, Immunity_Skills))
                {
                    EmitSoundToAll(fire,client);
                    
                    if(W3Chance(fSunstrikeHitChance[skill_sunstrike]))
                    {
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
                        EmitSoundToAll(fire,target);
                        War3_DealDamage(target,iSunstrikeDamage[skill_sunstrike],client,DMG_BULLET,"Sunstrike");
                        IgniteEntity(target, fSunstrikeBurnTime[skill_sunstrike]);
                    }
                    else
                    {
                        new Float:origin[3];
                        new Float:targetpos[3];
                        
                        War3_GetAimEndPoint(client,targetpos);
                        GetClientAbsOrigin(client,origin);
                        TE_SetupBeamPoints(origin, targetpos, BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
                        TE_SendToAll();
                        War3_GetAimEndPoint(client,targetpos);
                        targetpos[2]+=70;
                        TE_SetupGlowSprite(targetpos,BurnSprite,1.0,1.9,255);
                        TE_SendToAll();
                        
                        PrintHintText(client, "You miscast your Sunstrike");
                    }
                }
                else
                {
                    PrintHintText(client, "Target has immunity");
                }
            }
        }
    }
}


Invoke(client)
{
    if (War3_SkillNotInCooldown(client, thisRaceID, ULT_INVOKE, true))
    {
        OpenInvokeMenu(client);
    }
}

OpenInvokeMenu(client)
{
    new Handle:InvokeMenu=CreateMenu(War3Source_InvokeMenu_Selected);
    SetMenuPagination(InvokeMenu,MENU_NO_PAGINATION);
    SetMenuTitle(InvokeMenu,"==CHOOSE SKILL TO INVOKE==");
    SetMenuExitButton(InvokeMenu,true);
    
    new skillCount = War3_GetRaceSkillCount(thisRaceID)-1;
    new String:currentSkillIDString[128];
    new String:currentSkillName[128];
    new drawType;
    for (new i=1; i<=skillCount; i++)
    {
        IntToString(i, currentSkillIDString, sizeof(currentSkillIDString));
        W3GetRaceSkillName(thisRaceID, i, currentSkillName, sizeof(currentSkillName));
        drawType = ((iInvocations[client][0] == i || iInvocations[client][1] == i) || !W3IsSkillLeveled(client, thisRaceID, i)) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
        AddMenuItem(InvokeMenu, currentSkillIDString, currentSkillName, drawType);
    }
    
    DisplayMenu(InvokeMenu,client,MENU_TIME_FOREVER);
}

public War3Source_InvokeMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        if(ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
        {
            decl String:choice[128];
            decl String:SelectionDispText[128];
            new SelectionStyle;
            
            GetMenuItem(menu,selection,choice,sizeof(choice),SelectionStyle,SelectionDispText,sizeof(SelectionDispText));
            new skillID = StringToInt(choice);

            new skillCount = War3_GetRaceSkillCount(thisRaceID)-1;
            for (new i=1; i<=skillCount; i++)
            {
                if (skillID == i)
                {
                    SetInvocation(client, skillID);
                }
            }
        }
    }
    
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

SetInvocation(client, skillID)
{
    new skill_invoke=War3_GetSkillLevel(client, thisRaceID, ULT_INVOKE);
    War3_CooldownMGR(client, fInvokeCooldown[skill_invoke], thisRaceID, ULT_INVOKE);
    
    //If changing from coldsnap, deactivate it
    if (iInvocations[client][1] == SKILL_COLDSNAP)
    {
        bColdSnapBashOnHit[client] = false;
        PrintHintText(client, "Cold Snap deactivated");
    }
    
    //If changing from GhostWalk and skill is active, deactivate it
    if (iInvocations[client][1] == SKILL_GHOSTWALK && bGhostWalkActive[client])
    {
        EndGhostWalk(client);
    }

    //Set invocation
    if (iInvocations[client][0] == -1)
    {
        iInvocations[client][0] = skillID;
    }
    else
    {
        iInvocations[client][1] = skillID;
    }
}

ResetInvocations(client)
{
    iInvocations[client][0] = -1;
    iInvocations[client][1] = -1;
}

CastInvocation(client, skillID)
{
    if (skillID == SKILL_COLDSNAP)
    {
        ColdSnap(client);
    }
    else if (skillID == SKILL_GHOSTWALK)
    {
        GhostWalk(client);
    }
    else if (skillID == SKILL_ICEWALL)
    {
        IceWall(client);
    }
    else if (skillID == SKILL_TORNADO)
    {
        Tornado(client);
    }
    else if (skillID == SKILL_DEAFENINGBLAST)
    {
        DeafeningBlast(client);
    }
    else if (skillID == SKILL_SUNSTRIKE)
    {
        SunStrike(client);
    }
}


//
// HUD functions
//

public Action:HudInfo_Timer(Handle:timer, any:client)
{
    for( new i = 1; i <= MaxClients; i++ )
    {
        if(ValidPlayer(i,true) && !IsFakeClient(i))
        {
            if(War3_GetRace(i) == thisRaceID)  
            {
                new String:HUD_Buffer[200];
                new String:buffer[50];
                new String:spellNameBuffer[49];
                new String:shortNameBuffer[49];
                
                //Title
                StrCat(HUD_Buffer, sizeof(HUD_Buffer), "\n-SPELLS-");
                //Spell 1
                buffer = "\n";
                StrCat(buffer, sizeof(buffer), "1st: ");
                if (iInvocations[i][0] != -1)
                {
                    W3GetRaceSkillName(thisRaceID, iInvocations[i][0], spellNameBuffer, sizeof(spellNameBuffer));
                    SplitString(spellNameBuffer, " ", shortNameBuffer, sizeof(shortNameBuffer));
                    
                    if (strlen(shortNameBuffer) < strlen(spellNameBuffer) && StrContains(spellNameBuffer, " ") != -1)
                    {
                        StrCat(buffer, sizeof(buffer), shortNameBuffer);
                    }
                    else
                    {
                        StrCat(buffer, sizeof(buffer), spellNameBuffer);
                    }
                }
                StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
                //Spell 2
                buffer = "\n";
                StrCat(buffer, sizeof(buffer), "2nd: ");
                if (iInvocations[i][1] != -1)
                {
                    W3GetRaceSkillName(thisRaceID, iInvocations[i][1], spellNameBuffer, sizeof(spellNameBuffer));
                    SplitString(spellNameBuffer, " ", shortNameBuffer, sizeof(shortNameBuffer));
                    
                    if (strlen(shortNameBuffer) < strlen(spellNameBuffer) && StrContains(spellNameBuffer, " ") != -1)
                    {
                        StrCat(buffer, sizeof(buffer), shortNameBuffer);
                    }
                    else
                    {
                        StrCat(buffer, sizeof(buffer), spellNameBuffer);
                    }
                }
                StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
                
                HUD_Add(GetClientUserId(i), HUD_Buffer);
            }
        }
    }
}