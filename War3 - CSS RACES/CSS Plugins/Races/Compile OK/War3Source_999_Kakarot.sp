/**
 * File: Kakarot War3Source
 * Description: Goku race for War3Source
 * Author(s): iNCRED and Remy LeBeau
 **/

#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

//War3Source
new thisRaceID;

//myinfo
public Plugin:myinfo =
{
    name = "War3Source Race - Kakarot",
    author = "iNCRED",
    description = "Kakarot race for War3Source",
    version = "1.5.2",
    url = "www.sevinsinsgaming.com"
}

new SKILL_HEAL, SKILL_SPEED, SKILL_IMAGE, ULT_TRANS;

//heal
new Float:g_fHealProcChance[]={0.0,0.03,0.06,0.09,0.12,0.15};
new g_iHealAmt[]={0,5,10,15,20,25};
new g_iHealDmgAmt[]={0,1,2,3,4,5};
new String:Bladestr[]="npc/roller/mine/rmine_blades_out2.wav";

//speed
new Float:g_fSpeed[]={1.0,1.08,1.16,1.24,1.32,1.40};

//image
new Float:g_fImageChance[]={0.0,0.3,0.40,0.50,0.55,0.65};
new Float:g_fImageTime[] = {0.0,0.5,1.0,1.5,2.0,2.5};
new Float:g_fImageCooldown = 15.0;
new GlowSprite, GlowSprite2;

//ult
new g_offsCollisionGroup;
new Float:g_fUltRadius[]={0.0,2400.0,3000.0,3600.0,4200.0,4800.0};
new Float:g_fUltCD[]={0.0,30.0,28.0,26.0,24.0,22.0};
new Float:position[3];
new String:ultimateSound[]="ambient/office/coinslot1.wav";

//war3ready
public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Kakarot","kakarot");
    SKILL_HEAL=War3_AddRaceSkill(thisRaceID,"Energy Absorption","Drain the enemy of their life, and get some in return.",false,5);
    SKILL_IMAGE=War3_AddRaceSkill(thisRaceID,"After Image","Move so swiftly that the world leaves an image of you in it's wake.",false,5);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Kaioken","Kaio-what?! (Speed)",false,5);
    ULT_TRANS=War3_AddRaceSkill(thisRaceID,"Transmission","Teleport behind a random target!",true,5);
    
    War3_AddSkillBuff(thisRaceID,SKILL_SPEED,fMaxSpeed,g_fSpeed);
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TRANS,15.0,true);
    
    War3_CreateRaceEnd(thisRaceID);
}
    

//on plugin
public OnPluginStart()
{
    g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
}

//on map start
public OnMapStart()
{
    GlowSprite=PrecacheModel("models/player/t_leet.mdl");
    GlowSprite2=PrecacheModel("models/player/ct_urban.mdl");
    War3_PrecacheSound(Bladestr);
    War3_PrecacheSound(ultimateSound);
}

//on spawn
public OnWar3EventSpawn(client)
{
    if(War3_GetRace(client)==thisRaceID)
    {
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    }
}
    
//on change
public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client,true ))
    {
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }    
}

//on death
public OnWar3EventDeath( victim, attacker )
{
    W3ResetAllBuffRace( victim, thisRaceID );
}

//ultimate
public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true) )
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_TRANS);
        if(ult_level>0)
        {    
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TRANS,true) && !Silenced(client))
            {
                new Float:posVec[3];
                GetClientAbsOrigin(client,posVec);
                new Float:otherVec[3];
                new Float:bestTargetDistance=g_fUltRadius[ult_level];
                new cteam = GetClientTeam(client);
                new bestTarget=0;
                for(new i=1;i<=MaxClients;i++)
                {
                    if(ValidPlayer(i,true) && GetClientTeam(i)!= cteam && !W3HasImmunity(i,Immunity_Ultimates))
                    {
                        GetClientAbsOrigin(i,otherVec);
                        new Float:dist=GetVectorDistance(posVec,otherVec);
                        if(dist<bestTargetDistance)
                        {
                            bestTarget=i;
                            bestTargetDistance=GetVectorDistance(posVec,otherVec);
                        }
                    }
                }
                if(bestTarget==0)
                {
                    PrintHintText(client,"No target was found");
                }
                else
                {
                    new tport=RoundFloat(float(War3_GetMaxHP(bestTarget))/2.0);
                    if(tport>0)
                    {
                        War3_CachedPosition(bestTarget,Float:position);
                        TeleportEntity(client,position,NULL_VECTOR,NULL_VECTOR);
                        SetEntData(bestTarget, g_offsCollisionGroup, 2, 4, true);
                        EmitSoundToAll(ultimateSound,client);
                        War3_CooldownMGR(client,g_fUltCD[ult_level],thisRaceID,ULT_TRANS);
                    }
                }
            }
        }
        else
        {
            PrintHintText(client,"Level Your Ultimate First");
        }
    }
}

//mirror image
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)    
{
    if(ValidPlayer(victim,true) && ValidPlayer(attacker,true) && victim>0 && attacker>0 && attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            //new race_attacker=War3_GetRace(attacker);
            new race_victim=War3_GetRace(victim);
            // mirror image
            new skill_mimage=War3_GetSkillLevel(victim,race_victim,SKILL_IMAGE);
            if(race_victim==thisRaceID && skill_mimage>0)
            {
                if(War3_SkillNotInCooldown(victim,thisRaceID,SKILL_IMAGE,true))
                {
                    if(GetRandomFloat(0.0,1.0)<=g_fImageChance[skill_mimage] && !Silenced(victim))
                    {
                        new tteam=GetClientTeam(victim);
                        new Float:this_pos[3];
                        {
                            GetClientAbsOrigin(victim,this_pos);
                            if(tteam==2)
                            {
                                TE_SetupGlowSprite(this_pos,GlowSprite,2.0,1.0,250);
                                TE_SendToAll();
                            }
                            else
                            {
                                TE_SetupGlowSprite(this_pos,GlowSprite2,2.0,1.0,250);
                                TE_SendToAll();
                            }
                        }
                        War3_SetBuff(victim,fMaxSpeed,thisRaceID,1.6);
                        War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,0.01);
                        War3_SetBuff( victim,bDoNotInvisWeapon,thisRaceID,false);
                        War3_SetBuff( victim, bDisarm, thisRaceID, true  );
                        PrintHintText(victim,"Mirror Image");
                        CreateTimer(g_fImageTime[skill_mimage],RemoveSpeed,victim);
                        War3_CooldownMGR(victim,g_fImageCooldown,thisRaceID,SKILL_IMAGE);
                    }
                }
            }
        }
    }
}

//removespeed from mirror image
public Action:RemoveSpeed(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
        War3_SetBuff(client,fMaxSpeed,thisRaceID,g_fSpeed[skill_level]);
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);    
        War3_SetBuff( client, bDisarm, thisRaceID, false );
    }
}

//heal component
public OnWar3EventPostHurt(victim, attacker, Float:damage)
{
    if(ValidPlayer(victim,true) && ValidPlayer(attacker,true) && victim>0 && attacker>0 && attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_attacker=War3_GetRace(attacker);
            //new race_victim=War3_GetRace(victim);
            if(race_attacker == thisRaceID)
            {
                new skill_absorb=War3_GetSkillLevel(attacker,thisRaceID,SKILL_HEAL);
                if(skill_absorb>0)
                {
                    if(GetRandomFloat(0.0,1.0) <= g_fHealProcChance[skill_absorb] && !Silenced(victim))
                    {
                        War3_DealDamageDelayed(victim,attacker,g_iHealDmgAmt[skill_absorb],"Kakarot",1.0,false,1);
                        War3_DealDamageDelayed(victim,attacker,g_iHealDmgAmt[skill_absorb],"Kakarot",2.0,false,1);
                        War3_DealDamageDelayed(victim,attacker,g_iHealDmgAmt[skill_absorb],"Kakarot",3.0,false,1);
                        War3_DealDamageDelayed(victim,attacker,g_iHealDmgAmt[skill_absorb],"Kakarot",4.0,false,1);
                        War3_DealDamageDelayed(victim,attacker,g_iHealDmgAmt[skill_absorb],"Kakarot",5.0,false,1);
                        
                        W3FlashScreen(attacker,RGBA_COLOR_GREEN, 0.5,0.5);
                        
                        War3_HealToMaxHP(attacker,g_iHealAmt[skill_absorb]);
                        
                        EmitSoundToAll(Bladestr,attacker);
                        EmitSoundToAll(Bladestr,victim);
                    }
                }
            }
        }
    }
}