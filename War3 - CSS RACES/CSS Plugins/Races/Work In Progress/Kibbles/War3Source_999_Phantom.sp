#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/remyfunctions"


public Plugin:myinfo = 
{
    name = "War3Source Race - Phantom",
    author = "Arrow (coded by Kibbles)",
    description = "Phantom race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new thisRaceID;
new SKILL_SPOOK, SKILL_VANISH, SKILL_PHASE;

//SKILL_SPOOK
new Float:fSpookCooldown = 4.0;
new String:shadowstrikestr[256]; //="war3source/shadowstrikebirth.mp3";

//SKILL_VANISH
new Float:fVanishExtraSpeed = 1.3;
new Float:fVanishVisibility = 0.0;
new Float:fVanishDuration = 4.0;
new Float:fVanishAdditionalDisarmDuration = 0.5;
new Float:fVanishCooldown[] = {0.0, 12.0, 10.0, 10.0, 8.0};
new bool:bVanished[MAXPLAYERS] = {false, ...};
new String:ww_on[]="npc/scanner/scanner_nearmiss1.wav";
new String:ww_off[]="npc/scanner/scanner_nearmiss2.wav";

//SKILL_PHASE
new Float:fPhaseVisibility = 0.0;
new Float:fPhaseDuration[] = {0.0, 5.0, 10.0, 15.0, 20.0};
new Float:fPhaseCooldown = 20.0;
new bool:bPhased[MAXPLAYERS] = {false, ...};
new Float:fPhasePosition[MAXPLAYERS][3];
new Skydome;
new Handle:ultCircleEnable=INVALID_HANDLE;

//General
new Float:fBaseSpeed = 1.3;
new String:hostageHurt1[] = "hostage/hpain/hpain1.wav";
new String:hostageHurt2[] = "hostage/hpain/hpain2.wav";
new String:hostageHurt3[] = "hostage/hpain/hpain3.wav";
new String:hostageHurt4[] = "hostage/hpain/hpain4.wav";
new String:hostageHurt5[] = "hostage/hpain/hpain5.wav";
new String:hostageHurt6[] = "hostage/hpain/hpain6.wav";
new bool:allowHostageSound[MAXPLAYERS] = {true, ...};


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Phantom [PRIVATE]","phantom");
    
    SKILL_SPOOK = War3_AddRaceSkill(thisRaceID, "Spooked!", "Your presence spooks enemies, causing them to drop their weapon (Left click knife drops current weapon)", false, 1);
    SKILL_VANISH = War3_AddRaceSkill(thisRaceID, "Vanish", "Disappear, leaving your enemies shooting thin air (+ability gives speed, invis and smoke)", false, 4);
    SKILL_PHASE = War3_AddRaceSkill(thisRaceID, "Phase (+ultimate)", "Phase through all the objects in the real dimension (+ultimate gives noclip)", false, 4);
    
    War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
    ultCircleEnable=CreateConVar("war3_phantom_ultimate_circle","1","Enable the big Circle Effect for the ultimate");
}


public OnMapStart()
{
    if (!IsModelPrecached("models/characters/hostage_01.mdl"))
        PrecacheModel("models/characters/hostage_01.mdl");
    if (!IsModelPrecached("models/characters/hostage_02.mdl"))
        PrecacheModel("models/characters/hostage_02.mdl");
    if (!IsModelPrecached("models/characters/hostage_03.mdl"))
        PrecacheModel("models/characters/hostage_03.mdl");
    if (!IsModelPrecached("models/characters/hostage_04.mdl"))
        PrecacheModel("models/characters/hostage_04.mdl");
        
    if (!IsModelPrecached("sprites/tp_beam001.vmt"))
        PrecacheModel("sprites/tp_beam001.vmt");
    if (!IsSoundPrecached("ambient/atmosphere/city_skypass1.wav"))
        PrecacheSound("ambient/atmosphere/city_skypass1.wav");
        
    Skydome=PrecacheModel("models/props_combine/portalskydome.mdl");
    
    War3_AddSoundFolder(shadowstrikestr, sizeof(shadowstrikestr), "shadowstrikebirth.mp3");
    War3_AddCustomSound(shadowstrikestr);
    
    War3_PrecacheSound(ww_on);
    War3_PrecacheSound(ww_off);
    
    War3_PrecacheSound(hostageHurt1);
    War3_PrecacheSound(hostageHurt2);
    War3_PrecacheSound(hostageHurt3);
    War3_PrecacheSound(hostageHurt4);
    War3_PrecacheSound(hostageHurt5);
    War3_PrecacheSound(hostageHurt6);
    for (new i=0; i<MAXPLAYERS; i++)
    {
        allowHostageSound[i] = true;
    }
}


public OnRaceChanged(client, oldrace, newrace)
{
    if (newrace == thisRaceID && ValidPlayer(client))
    {
        InitSkills(client);
    }
    else if (oldrace == thisRaceID && ValidPlayer(client))
    {
        //Reset buffs/restrictions if player is changing from this race.
        W3ResetAllBuffRace(client, thisRaceID);
        War3_WeaponRestrictTo(client, thisRaceID, "");
    }
}


public OnWar3EventSpawn(client)
{
    W3ResetAllBuffRace(client, thisRaceID);

    if (War3_GetRace(client) == thisRaceID && ValidPlayer(client, true))
    {
        InitSkills(client);
    }
}


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if (ValidPlayer(victim, true) && ValidPlayer(attacker, true) && GetClientTeam(victim) != GetClientTeam(attacker))
	{
        if (War3_GetRace(victim) == thisRaceID)
        {
            if (allowHostageSound[victim])
            {
                allowHostageSound[victim] = false;
                CreateTimer(1.0, AllowHostageSound, victim);
                switch(GetRandomInt(1,6))
                {
                    case 1:
                    {
                        EmitSoundToAll(hostageHurt1, victim);
                    }
                    case 2:
                    {
                        EmitSoundToAll(hostageHurt2, victim);
                    }
                    case 3:
                    {
                        EmitSoundToAll(hostageHurt3, victim);
                    }
                    case 4:
                    {
                        EmitSoundToAll(hostageHurt4, victim);
                    }
                    case 5:
                    {
                        EmitSoundToAll(hostageHurt5, victim);
                    }
                    case 6:
                    {
                        EmitSoundToAll(hostageHurt6, victim);
                    }
                }
            }
        }
        
        if (War3_GetRace(attacker) == thisRaceID)
        {
            new skill_spook = War3_GetSkillLevel(attacker, thisRaceID, SKILL_SPOOK);
            if(skill_spook > 0 && War3_SkillNotInCooldown(attacker, thisRaceID, SKILL_SPOOK, false) && !Hexed(attacker, true) && (GetClientButtons(attacker) & (IN_ATTACK | IN_ATTACK2)))
            {
                if (W3HasImmunity(victim, Immunity_Skills))
                {
                    W3MsgEnemyHasImmunity(attacker, false);
                }
                else
                {
                    War3_CooldownMGR(attacker, fSpookCooldown, thisRaceID, SKILL_SPOOK, true, true);
                    FakeClientCommand(victim, "drop");
                    W3EmitSoundToAll(shadowstrikestr, attacker);
                    W3EmitSoundToAll(shadowstrikestr, attacker);
                }
            }
        }
	}
}
public Action:AllowHostageSound(Handle:timer, any:client)
{
    if (ValidPlayer(client))
    {
        allowHostageSound[client] = true;
    }
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if (ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID && ability == 0 && pressed && !bPhased[client])
	{
        new skill_vanish=War3_GetSkillLevel(client, thisRaceID, SKILL_VANISH);
        if(skill_vanish > 0 && War3_SkillNotInCooldown(client, thisRaceID, SKILL_VANISH, true) && !Silenced(client, true))
        {
            bVanished[client] = true;
            War3_CooldownMGR(client, fVanishCooldown[skill_vanish], thisRaceID, SKILL_VANISH, true, true);
        
            new Float:this_pos[3];
            GetClientAbsOrigin(client, this_pos);
            new SmokeIndex = CreateEntityByName("env_particlesmokegrenade"); 
            if (SmokeIndex != -1) 
            { 
                SetEntProp(SmokeIndex, Prop_Send, "m_CurrentStage", 1); 
                SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeStartTime", fVanishDuration * 0.75); 
                SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeEndTime", fVanishDuration); 
                DispatchSpawn(SmokeIndex); 
                ActivateEntity(SmokeIndex);
                TeleportEntity(SmokeIndex, this_pos, NULL_VECTOR, NULL_VECTOR); 
            }  
            
            War3_SetBuff(client, bDisarm, thisRaceID, true);
            War3_SetBuff(client, fMaxSpeed2, thisRaceID, fVanishExtraSpeed);
            War3_SetBuff(client, fInvisibilitySkill, thisRaceID, fVanishVisibility);
            War3_SetBuff(client, bDoNotInvisWeapon, thisRaceID, false);
            
            EmitSoundToAll(ww_on, client);
            PrintHintText(client, "You vanish!");
            
            CreateTimer(fVanishDuration, RemoveVanishBuffs, client);
            CreateTimer(fVanishDuration + fVanishAdditionalDisarmDuration, RemoveVanishDisarm, client);
        }
    }
}
public Action:RemoveVanishBuffs(Handle:timer, any:client)
{
	if (ValidPlayer(client))
	{
		War3_SetBuff(client, fMaxSpeed2, thisRaceID, 1.0);
		War3_SetBuff(client, fInvisibilitySkill, thisRaceID, 1.0);
		War3_SetBuff(client, bDoNotInvisWeapon, thisRaceID, true);
        
        EmitSoundToAll(ww_off,client);
        PrintHintText(client, "You reappear!");
	}
}
public Action:RemoveVanishDisarm(Handle:timer, any:client)
{
	if (ValidPlayer(client))
	{
        bVanished[client] = false;
        War3_SetBuff(client, bDisarm, thisRaceID, false);
	}
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if (ValidPlayer(client, true) && race == thisRaceID && pressed && !bVanished[client])
    {
        if (bPhased[client])
        {
            EndPhase(INVALID_HANDLE, client);
        }
        else
        {
            new skill_phase=War3_GetSkillLevel(client, thisRaceID, SKILL_PHASE);
            if(skill_phase > 0 && War3_SkillNotInCooldown(client, thisRaceID, SKILL_PHASE, true) && !Silenced(client, true))
            {
                bPhased[client] = true;
                GetClientAbsOrigin(client, fPhasePosition[client]);
                
                War3_SetBuff(client, bNoClipMode, thisRaceID, true);
                War3_SetBuff(client, bDisarm, thisRaceID, true);
                War3_SetBuff(client, fInvisibilitySkill, thisRaceID, fPhaseVisibility);
                War3_SetBuff(client, bDoNotInvisWeapon, thisRaceID, false);
                War3_SetBuff(client, bImmunityUltimates, thisRaceID, true);
                
                PhaseEffect(client);
                PrintHintText(client,"You phase out of existence!");
                
                CreateTimer(fPhaseDuration[skill_phase], EndPhase, client);
            }
        }
    }
}
public Action:EndPhase(Handle:timer, any:client)
{
	if (ValidPlayer(client) && bPhased[client])
	{
        bPhased[client] = false;
        War3_CooldownMGR(client, fPhaseCooldown, thisRaceID, SKILL_PHASE, true, true);
    
		War3_SetBuff(client, bNoClipMode, thisRaceID, false);
        War3_SetBuff(client, bDisarm, thisRaceID, false);
        War3_SetBuff(client, fInvisibilitySkill, thisRaceID, 1.0);
        War3_SetBuff(client, bDoNotInvisWeapon, thisRaceID, true);
        War3_SetBuff(client, bImmunityUltimates, thisRaceID, false);
        
        TeleportEntity(client, fPhasePosition[client], NULL_VECTOR, NULL_VECTOR);
        PhaseEffect(client);
        PrintHintText(client, "You phase back in to existence!");
	}
}
static PhaseEffect(client)
{
    W3FlashScreen(client,RGBA_COLOR_RED,1.2,_,FFADE_IN);
    new Float:fVec[3] = {0.0,0.0,900.0};
    new skill_phase=War3_GetSkillLevel(client, thisRaceID, SKILL_PHASE);
    TE_SetupGlowSprite(fVec,Skydome,fPhaseDuration[skill_phase],1.0,255);
    TE_SendToClient(client);
    CreateTesla(client,1.0,1.5,10.0,60.0,3.0,4.0,600.0,"160","200","25 255 25","ambient/atmosphere/city_skypass1.wav","sprites/tp_beam001.vmt",true);
    new Float:fAngles[3]={90.0,90.0,90.0};
    if(GetConVarBool(ultCircleEnable))
        CreateParticles(client,false,1.5,fAngles,65.0,40.0,20.0,10.0,"sprites/tp_beam001.vmt","140 255 140","45","28","150","450");
}
/*public OnW3TakeDmgAllPre(victim, attacker, Float:damage)
{
    if (ValidPlayer(victim, true) && War3_GetRace(victim) == thisRaceID && bPhased[victim])
    {
        War3_DamageModPercent(0.0);
    }
}*/
public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
    if(War3_GetRace(victim) == thisRaceID && bPhased[victim]){
        damage = 0.0;
    }
    return Plugin_Changed;
}

//
// Helper functions
//
static InitSkills(any:client)
{
    bVanished[client] = false;
    bPhased[client] = false;
    War3_ChangeModelToHostage(client);
    allowHostageSound[client] = true;
    War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife");
    War3_SetBuff(client, fMaxSpeed, thisRaceID, fBaseSpeed);
}