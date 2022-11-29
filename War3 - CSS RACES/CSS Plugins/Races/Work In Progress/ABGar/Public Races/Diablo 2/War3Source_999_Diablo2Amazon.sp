#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Diablo2 Amazon",
	author = "ABGar",
	description = "The Diablo2 Amazon race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_SIGHT, SKILL_EVADE, SKILL_ARROW, ULT_BOLT;

// SKILL_SIGHT
new GlowSprite;
new bool:bMarked[MAXPLAYERSCUSTOM]={false, ...};
new Float:SightDamage=1.5;
new Float:SightCD=25.0;
new Float:SightRange[]={0.0,150.0,175.0,200.0,225.0};
new Float:SightDuration[]={0.0,2.0,2.5,3.0,3.5};
new String:SightSound[]="war3source/d2amazon/innersight.wav";

// SKILL_EVADE
new Float:EvadeAmt[]={0.0,0.05,0.1,0.15,0.2};

// SKILL_ARROW
new ExlpSprite; 
new Float:ArrowRadius[]={0.0,75.0,100.0,125.0,150.0};
new Float:ArrowChance[]={0.0,0.05,0.1,0.15,0.2};
new Float:ArrowDamage[]={0.0,20.0,30.0,40.0,50.0};
new String:ArrowSound[]="war3source/d2amazon/explodearrow.wav";

// ULT_BOLT
new BeamSprite;
new BoltDamage[]={0,16,32,48,64};
new Float:BoltJumpRange=150.0;
new Float:BoltRange[]={0.0,500.0,600.0,700.0,800.0};
new Float:BoltCD[]={0.0,45.0,40.0,35.0,30.0};

new String:LightningSound[]="war3source/d2amazon/lightning.wav";

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Diablo2 Amazon","d2amazon");
	SKILL_SIGHT = War3_AddRaceSkill(thisRaceID,"Inner Sight","The Amazons have developed a technique whereby they can attune themselves to the life forces in the surrounding area and transfer these energies into a source of luminescence. \n Mark nearby enemies for a short period, and any attacks you deal to them will do increased damage (+ability)",false,4);
	SKILL_EVADE = War3_AddRaceSkill(thisRaceID,"Evade","Once an Amazon has sharpened her defensive concentration to this level, she will eventually be able to dodge blows and other attacks while moving. \n Chance to evade damage (passive)",false,4);
	SKILL_ARROW = War3_AddRaceSkill(thisRaceID,"Exploding Arrow","An Amazon warrior practiced in this skill can imbue the arrows that she fires with the ability to explode upon impact \n Chance to cause an explosion where your bullet hits, doing damage to nearby enemies (passive attack)",false,4);
	ULT_BOLT=War3_AddRaceSkill(thisRaceID,"Lightning Bolt","An Amazon that has proven themself worthy can call upon the goddess Zerae to embue them with a bolt of pure lightning. \n Lightning bolt to one target, which jumps to any other nearby target, with a quarter of the damage(+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_EVADE,fDodgeChance,EvadeAmt);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_SIGHT,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_BOLT,10.0,_);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("bullet_impact",Event_BulletImpact);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/war3source/d2amazon/innersight.wav");
	AddFileToDownloadsTable("sound/war3source/d2amazon/explodearrow.wav");
	AddFileToDownloadsTable("sound/war3source/d2amazon/lightning.wav");
	War3_PrecacheSound(SightSound);
	War3_PrecacheSound(ArrowSound);
	War3_PrecacheSound(LightningSound);
	ExlpSprite=PrecacheModel("materials/sprites/zerogxplode.vmt");
	GlowSprite=PrecacheModel("sprites/greenglow1.vmt");
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=1; i<MaxClients; i++)
    {
        bMarked[i]=false;
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

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout,weapon_knife");
	CreateTimer(0.5,GiveWep,client);
}

public Action:GiveWep(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(!Client_HasWeapon(client,"weapon_scout"))
			GivePlayerItem(client,"weapon_scout");
		if(!Client_HasWeapon(client,"weapon_knife"))
			GivePlayerItem(client,"weapon_knife");
	}
}

/* *************************************** (SKILL_SIGHT) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && ability==0 && pressed)
	{
		new SightLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SIGHT);
		if(SightLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_SIGHT,true,true,true))
			{
				War3_CooldownMGR(client,SightCD,thisRaceID,SKILL_SIGHT,true,true);
				EmitSoundToAll(SightSound,client);
				new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
				for (new i=1;i<=MaxClients;i++)
				{
					new Float:iPos[3];		GetClientAbsOrigin(i,iPos);
					new Float:distance=GetVectorDistance(clientPos,iPos);
					if(ValidPlayer(i,true) && GetClientTeam(client)!=GetClientTeam(i) && distance<=SightRange[SightLevel])
					{
						if(SkillFilter(i))
						{
							bMarked[i]=true;
							CreateTimer(SightDuration[SightLevel],StopSight,i);
						}
						else
						{
							if(W3Chance(0.25))
							{
								bMarked[i]=true;
								CreateTimer(SightDuration[SightLevel],StopSight,i);
							}
						}
					}
				}
			}
		}
		else
			PrintHintText(client,"Level your Inner Sight first");
	}
}

public Action:StopSight(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bMarked[client])
	{
		bMarked[client]=false;
	}
}

public OnGameFrame()
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && bMarked[i])
		{
			new Float:iPos[3];	GetClientAbsOrigin(i,iPos);
			iPos[2]+=20;
			TE_SetupGlowSprite(iPos,GlowSprite,0.1,1.0,110);
			TE_SendToAll();
		}
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new SightLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SIGHT);
			if(SightLevel>0 && bMarked[victim])
			{
				War3_DamageModPercent(SightDamage);
				bMarked[victim]=false;
				PrintToChat(attacker,"Damage increased due to InnerSight");
			}
		}
	}
}

/* *************************************** (SKILL_ARROW) *************************************** */
public Event_BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new Float:Origin[3];
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	Origin[0] = GetEventFloat(event,"x");
	Origin[1] = GetEventFloat(event,"y");
	Origin[2] = GetEventFloat(event,"z");
	new ArrowLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_ARROW);
	if(ArrowLevel>0)
	{
		if(W3Chance(ArrowChance[ArrowLevel]))
		{
			EmitSoundToAll(ArrowSound,client);
			TE_SetupExplosion(Origin, ExlpSprite, 10.0, 10, TE_EXPLFLAG_NONE, 60, 160);
			TE_SendToAll();
			for (new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client))
				{
					new Float:VictimPos[3];		GetClientAbsOrigin(i,VictimPos);
					new Float:Distance=GetVectorDistance(Origin,VictimPos);
					new Float:Radius = ArrowRadius[ArrowLevel];
					if(Distance<=Radius)
					{
						new Float:Factor=(Radius-Distance)/Radius;
						new DamageAmt=RoundFloat(ArrowDamage[ArrowLevel]*Factor);
						War3_DealDamage(i,DamageAmt,client,DMG_BLAST,"exploding arrow",_,W3DMGTYPE_MAGIC);
						War3_ShakeScreen(i,2.0*Factor,250.0*Factor,30.0);
						W3FlashScreen(i,RGBA_COLOR_RED);
					}
				}
			}
		}
	}
}

/* *************************************** (ULT_BOLT) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new BoltLevel=War3_GetSkillLevel(client,thisRaceID,ULT_BOLT);
		if(BoltLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_BOLT,true,true,true))
			{
				new target = War3_GetTargetInViewCone(client,BoltRange[BoltLevel],false,25.0);
				if(target>0 && UltFilter(target))
				{
					War3_CooldownMGR(client,BoltCD[BoltLevel],thisRaceID,ULT_BOLT,true,true);
					new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);		clientPos[2]+=20.0;
					new Float:target1Pos[3];	GetClientAbsOrigin(target,target1Pos);		target1Pos[2]+=20.0;
					new Float:target2Pos[3];
					W3EmitSoundToAll(LightningSound,target);
					W3EmitSoundToAll(LightningSound,client);
					TE_SetupBeamPoints(clientPos,target1Pos,BeamSprite,BeamSprite,0,35,1.0,20.0,20.0,0,40.0,{255,255,255,255},40);
					TE_SendToAll();
					War3_DealDamage(target,BoltDamage[BoltLevel],client,DMG_CRUSH,"lightning bolt",_,W3DMGTYPE_MAGIC);
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true) && GetClientTeam(i)==GetClientTeam(target) && UltFilter(i) && i!=target)
						{
							GetClientAbsOrigin(i,target2Pos);
							target2Pos[2]+=20.0;
							if(GetVectorDistance(target1Pos,target2Pos)<=BoltJumpRange)
							{
								TE_SetupBeamPoints(target1Pos,target2Pos,BeamSprite,BeamSprite,0,35,1.0,20.0,20.0,0,40.0,{255,255,255,255},40);
								TE_SendToAll();
								W3EmitSoundToAll(LightningSound,i);
								War3_DealDamage(i,BoltDamage[BoltLevel]/4,client,DMG_CRUSH,"lightning bolt",_,W3DMGTYPE_MAGIC);
							}
						}
					}
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}
