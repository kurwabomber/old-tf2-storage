#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Diablo2 Assassin",
	author = "ABGar",
	description = "The Diablo2 Assassin race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_VENOM, SKILL_DRAGON, SKILL_SENTRY, ULT_CLOAK;

// SKILL_VENOM
new iPoisonCount;
new VenomDealer[MAXPLAYERSCUSTOM]={-1, ...};
new Float:VenomCD=10.0;
new Float:VenomChance[]={0.0,0.1,0.15,0.2,0.25};
new String:VenomSound[]="war3source/d2assassin/venom.wav";

// SKILL_DRAGON
new DragonDamage[]={0,5,10,15,20};
new Float:DragonCD=30.0;
new Float:DragonRange=800.0;
new String:DragonSound[]="war3source/d2assassin/dragonflight.wav";

// SKILL_SENTRY
new SentrySprite, BeamSprite, HaloSprite;
new SentryDamage=5;
new bool:bSentryPlanted[MAXPLAYERSCUSTOM]={false, ...};
new Float:SentryPos[3];
new Float:SentryCD=30.0;
new Float:SentryRadius[]={0.0,100.0,140.0,180.0,220.0};
new Float:SentryDuration[]={0.0,10.0,12.0,14.0,16.0};
new String:SentrySound[]="war3source/d2assassin/sentry.wav";
new String:SentryZapSound[]="war3source/cd/overloadzap.mp3";

// ULT_CLOAK
new bool:bInCloak[MAXPLAYERSCUSTOM]={false, ...};
new Handle:hCloakTimer[MAXPLAYERSCUSTOM]={INVALID_HANDLE, ...};
new Float:CloakCD=20.0;
new Float:CloakDuration[]={0.0,3.0,5.0,7.0,9.0};
new String:InvisOn[]="npc/scanner/scanner_nearmiss1.wav";
new String:InvisOff[]="npc/scanner/scanner_nearmiss2.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Diablo2 Assassin","d2assassin");
	SKILL_VENOM = War3_AddRaceSkill(thisRaceID,"Venom","An Assassin who has mastered this skill secretly coats her weapons with vile toxins (passive) \n Chance to poison enemy on hit",false,4);
	SKILL_DRAGON = War3_AddRaceSkill(thisRaceID,"Dragon Flight","After years of disciplined physical conditioning, an Assassin can develop the ability to move faster than the eye can follow in one quick burst (+ability) \n Teleport you to enemy dealing damage, but stunning and disarming you for 2 seconds",false,4);
	SKILL_SENTRY = War3_AddRaceSkill(thisRaceID,"Lightning Sentry","This device discharges great bolts of electricity, frying assailants when they come near. (+ability1) \n Lay down a small ward that shocks enemies in range",false,4);
	ULT_CLOAK=War3_AddRaceSkill(thisRaceID,"Cloak of Shadows","Moving through the darkness, unseen by her foes, the enshrouded Assassin can ambush her unsuspecting victims with devastating attacks. (+ultimate) \n Turn invisible.  Only attacking or casting a spell will end the invis early",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_DRAGON,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_SENTRY,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_CLOAK,10.0,_);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/war3source/d2assassin/venom.wav");
	AddFileToDownloadsTable("sound/war3source/d2assassin/dragonflight.wav");
	AddFileToDownloadsTable("sound/war3source/d2assassin/sentry.wav");
	War3_PrecacheSound(VenomSound);
	War3_PrecacheSound(DragonSound);
	War3_PrecacheSound(SentrySound);
	War3_PrecacheSound(SentryZapSound);
	War3_PrecacheSound(InvisOn);
	War3_PrecacheSound(InvisOff);
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	SentrySprite=PrecacheModel("models/effects/combineball.mdl");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=1; i<MaxClients; i++)
    {
        if (hCloakTimer[i] != INVALID_HANDLE)
        {
            TriggerTimer(hCloakTimer[i]);
            hCloakTimer[i] = INVALID_HANDLE;
        }
    }
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		if (ValidPlayer(client,true))
        {
			InitPassiveSkills(client);
		}
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
	
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	bSentryPlanted[client]=false;
}

public OnWar3EventDeath(victim,attacker)
{
	if(ValidPlayer(victim, true) && War3_GetRace(victim))
	{
		if (hCloakTimer[victim] != INVALID_HANDLE)
        {
            TriggerTimer(hCloakTimer[victim]);
            hCloakTimer[victim] = INVALID_HANDLE;
        }
		if(bSentryPlanted[victim])
			bSentryPlanted[victim]=false;
	}
}

/* *************************************** (SKILL_VENOM) *************************************** */
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID && SkillAvailable(attacker,thisRaceID,SKILL_VENOM,true,true,true))
		{
			if(bInCloak[attacker])
				TriggerTimer(hCloakTimer[attacker]);
			
			new VenomLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_VENOM);
			if(VenomLevel>0 && SkillFilter(victim))
			{
				if(W3Chance(VenomChance[VenomLevel]))
				{
					War3_CooldownMGR(attacker,VenomCD,thisRaceID,SKILL_VENOM,true,true);
					iPoisonCount=1;
					VenomDealer[victim]=attacker;
					CreateTimer(1.0,VenomCount,victim);
					War3_DealDamage(victim,1,attacker,DMG_CRUSH,"assassin's venom",_,W3DMGTYPE_MAGIC);
					W3FlashScreen(victim,RGBA_COLOR_GREEN);
					W3EmitSoundToAll(VenomSound,victim);
					CPrintToChat(victim,"{RED} You've been poisoned by Assassin's Venom for 10 seconds");
				}
			}
		}
	}
}

public Action:VenomCount(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && SkillFilter(client) && iPoisonCount<10)
	{
		new attacker = VenomDealer[client];
		iPoisonCount++;
		CreateTimer(1.0,VenomCount,client);
		War3_DealDamage(client,1,attacker,DMG_CRUSH,"assassin's venom",_,W3DMGTYPE_MAGIC);
		W3FlashScreen(client,RGBA_COLOR_GREEN);
	}
}

/* *************************************** (SKILL_DRAGON) *************************************** */
public Action:StopDisarm(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		War3_SetBuff(client,bSilenced,thisRaceID,false);
		War3_SetBuff(client,bDisarm,thisRaceID,false);
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new DragonLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_DRAGON);
			if(DragonLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_DRAGON,true,true,true))
				{
					new target = War3_GetTargetInViewCone(client,DragonRange,false,23.0);
					if(target>0 && SkillFilter(target))
					{
						War3_CooldownMGR(client,DragonCD,thisRaceID,SKILL_DRAGON,true,true);
						new Float:targetPos[3];		GetClientAbsOrigin(target,targetPos);
						TeleportEntity(client,targetPos,NULL_VECTOR,NULL_VECTOR);
						W3EmitSoundToAll(DragonSound,client);
						War3_DealDamage(target,DragonDamage[DragonLevel],client,DMG_CRUSH,"dragon flight",_,W3DMGTYPE_MAGIC);
						War3_SetBuff(client,bSilenced,thisRaceID,true);
						War3_SetBuff(client,bDisarm,thisRaceID,true);
						CreateTimer(2.0,StopDisarm,client);
						if(bInCloak[client])	
							TriggerTimer(hCloakTimer[client]);
					}
					else
						W3MsgNoTargetFound(client,DragonRange);
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
/* *************************************** (SKILL_SENTRY) *************************************** */
		if(ability==1)
		{
			new SentryLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SENTRY);
			if(SentryLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_SENTRY,true,true,true))
				{
					if(!bSentryPlanted[client])
					{
						War3_CooldownMGR(client,SentryCD,thisRaceID,SKILL_SENTRY,true,true);
						GetClientAbsOrigin(client,SentryPos);		SentryPos[2]+=40.0;
						TE_SetupGlowSprite(SentryPos,SentrySprite,SentryDuration[SentryLevel],1.5,255);
						TE_SendToAll();
						bSentryPlanted[client]=true;
						W3EmitSoundToAll(SentrySound,client);
						CreateTimer(SentryDuration[SentryLevel],StopSentry,client);
						CreateTimer(1.0,SentryDamageLoop,client);
						if(bInCloak[client])	
							TriggerTimer(hCloakTimer[client]);
					}
				}
			}
		}
	}
}

public Action:StopSentry(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bSentryPlanted[client])
	{
		bSentryPlanted[client]=false;
	}
}

public Action:SentryDamageLoop(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bSentryPlanted[client])
	{
		CreateTimer(1.0,SentryDamageLoop,client);
		new SentryLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SENTRY);
		for(new target=1;target<=MaxClients;target++)
		{
			if(ValidPlayer(target,true) && GetClientTeam(target)!=GetClientTeam(client) && SkillFilter(target))
			{
				new Float:TargetPos[3];		GetClientAbsOrigin(target,TargetPos);		TargetPos[2]+=40.0;
				if(GetVectorDistance(SentryPos,TargetPos)<SentryRadius[SentryLevel])
				{
					War3_DealDamage(target,SentryDamage,client,DMG_CRUSH,"lightning sentry");
					TE_SetupBeamPoints(SentryPos,TargetPos,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{255,255,255,255},20);
					TE_SendToAll();
					W3FlashScreen(target,{255,255,255,3});
					War3_ShakeScreen(target,1.0,50.0,40.0);
					EmitSoundToAll(SentryZapSound,target);
				}
			}
		}
	}
}

/* *************************************** (ULT_CLOAK) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new CloakLevel=War3_GetSkillLevel(client,thisRaceID,ULT_CLOAK);
		if(CloakLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_CLOAK,true,true,true))
			{
				if(!bInCloak[client])
				{
					bInCloak[client]=true;
					EmitSoundToAll(InvisOn,client);
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.00);
					hCloakTimer[client]=CreateTimer(CloakDuration[CloakLevel],EndInvis,client);
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:EndInvis(Handle:timer,any:client)
{
	if(War3_GetRace(client)==thisRaceID && bInCloak[client])
	{
		bInCloak[client]=false;
		W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
		EmitSoundToAll(InvisOff,client);
		War3_CooldownMGR(client,CloakCD,thisRaceID,ULT_CLOAK,true,true);
	}
}
