#pragma semicolon 1 //default
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
public Plugin:myinfo =
{
name = "HaleCraft - Pyro",
author = "Cone",
description = "Pyro"
}
new thisRaceID;
new SKILL_MOVE, SKILL_HEALTH, SKILL_DAMAGE, ULTIMATE_BREAK;
new Float:MovementSpeed[5] = {1.0, 1.04, 1.06, 1.08, 1.10};
new Float:HealthBonus[5] = {0.0, 15.0, 30.0, 45.0, 60.0};
new Float:DamageOPT[5] = {1.0, 1.10, 1.15, 1.20, 1.25};
new Float:LifeBreakV[]={0.0, 0.02, 0.04, 0.06, 0.08}; //victim
new Float:LifeBreakC[]={0.0, 0.40, 0.50, 0.60, 0.70}; //user
new Handle:ultCooldownCvar;
new Float:ultMaxDistance = 300.0;
public LoadCheck()
{
return GameTF();
}
public OnPluginStart()
{
LoadTranslations("w3s.race.pyro.phrases");
ultCooldownCvar=CreateConVar("war3_pyro_ult_cooldown", "180", "Cooldown time for ultimate.");
}
public OnWar3LoadRaceOrItemOrdered(num)
{
if(num==30)
{
  thisRaceID=War3_CreateNewRace("Pyro","pyro");
  SKILL_MOVE=War3_AddRaceSkillT(thisRaceID,"Movement Speed",false,4);
  SKILL_HEALTH=War3_AddRaceSkillT(thisRaceID,"Health Bonus",false,4);
  SKILL_DAMAGE=War3_AddRaceSkillT(thisRaceID,"Damage OPT",false,4);
  ULTIMATE_BREAK=War3_AddRaceSkillT(thisRaceID,"Life Break",true,4);

  W3SkillCooldownOnSpawn(thisRaceID,ULTIMATE_BREAK,10.0,_);

  War3_CreateRaceEnd(thisRaceID);

  War3_AddSkillBuff(thisRaceID,SKILL_MOVE, fMaxSpeed, MovementSpeed);
  War3_AddSkillBuff(thisRaceID,SKILL_HEALTH, iAdditionalMaxHealth, HealthBonus);
}
}
public OnWar3EventSpawn(client)
{
CheckSkills(client);
}
public OnRaceChanged(client,oldrace,newrace)
{
CheckSkills(client);
}
public CheckSkills(client) //check pass? should I use public?
{
if (War3_GetRace(client)!=thisRaceID)
{
  War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,1.0);
  War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
  War3_SetBuff(client,iDamageBonus,thisRaceID,1.0);
  return;
}

return;
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
if(attacker != victim)
{
  if(ValidPlayer(attacker) && War3_GetRace(attacker) == thisRaceID)
  {
   if(ValidPlayer(victim) && GetClientTeam(victim) == GetClientTeam(attacker))
   {
        return;
   }
  }

  new iDamageLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_DAMAGE);
  if iDamageLevel > 0 && !Hexed(attacker,false) && !W3HasImmunity(victim,Immunity_Skills)
  *then
  {
   War3_DamageModPercent(DamageOPT[iDamageLevel]);
   W3FlashScreen(victim, RGBA_COLOR_RED);
  }
}
}
public OnUltimateCommand(client,race,bool:pressed) //i used victimCurHP, hale's current health
{
if(race==thisRaceID && pressed && ValidPlayer(client,true) &&!Silenced(client) )
{
  new ult_level=War3_GetSkillLevel(client,race,ULTIMATE_BREAK);
  if (ult_level>0)
  {
   new Float: AttackerMaxHP = float(GetClientHealth(client));
   new AttackerCurHP = GetClientHealth(client);
   new SelfDamage = RoundToCeil(AttackerMaxHP * LifeBreakC[ult_level]);
   new bool:bUltPossible = SelfDamage < AttackerCurHP;
   if (!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_BREAK,true))
   {
        if(!bUltPossible)
        {
         PrintHintText(client,"%T","You do NOT have enough HP to cast your ultimate",client);
        }
        else
        {
         new target = War3_GetTargetInViewCone(client,ultMaxDistance,false,23.0,ConeTargetFilter);
         if(target>0)
         {
          new Float:VCurHP = float(GetClientHealth(client));
          new Damage = RoundToFloor(LifeBreakV[ult_level] * VCurHP);
        
          if(War3_DealDamage(target,Damage,client,DMG_BULLET|DMG_PREVENT_PHYSICS_FORCE,"LifeBreak"))
          //damaging nearest enemy
          {
           W3PrintSkillDmgHintConsole(target,client,War3_GetWar3DamageDealt(),ULTIMATE_BREAK);
           //prints damage opt
           W3FlashScreen(target,RGBA_COLOR_RED);
           //notify victim
           W3FlashScreen(client,RGBA_COLOR_RED);
           //notify user
          
           //sounds enabled? get sound EmitSoundToAll(ultimateSound,client);
           War3_DealDamage(client,SelfDamage,client,DMG_BULLET|DMG_PREVENT_PHYSICS_FORCE,"LifeBreak");
           //do damage to attacker
           War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULTIMATE_BREAK);
           //call cooldown
          
           PrintHintText(client,"%T","LifeBreak",client);
          }
         }
         else
         {
          W3MsgNoTargetFound(client,ultMaxDistance);
         }
        }
   }
   else
   {
        W3MsgUltNotLeveled(client);
   }
  }
}
}
public bool:ConeTargetFilter(client)
{
return (!W3HasImmunity(client,Immunity_Ultimates));
}