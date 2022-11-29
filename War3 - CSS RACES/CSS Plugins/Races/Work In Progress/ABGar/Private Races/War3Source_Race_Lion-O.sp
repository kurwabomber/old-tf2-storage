#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Lion-O",
	author = "ABGar",
	description = "The Lion-O race for War3Source.",
	version = "1.0",
	// Kuram's Private Race Request - https://www.sevensinsgaming.com/forum/index.php?/topic/5423-lion-o/
}

new thisRaceID;

new SKILL_AGILITY, SKILL_SHIELD, SKILL_SWORD, ULT_SIGHT;

// SKILL_AGILITY
new Float:CatAgilityGrav[]={1.0,0.85,0.7,0.55,0.4};

// SKILL_SHIELD
new m_vecBaseVelocity, WebSprite;
new bool:bInShield[MAXPLAYERSCUSTOM]={false, ...};
new bool:HookInCooldown[MAXPLAYERSCUSTOM];
new Float:HookAvailableTime[MAXPLAYERSCUSTOM];
new Float:HookCD=15.0;
new Float:ShieldReduce=0.6;
new Float:ShieldDuration=5.0;
new Float:ShieldCD=25.0;
new Float:PushForce=0.75;
new String:ShieldSound[]="npc/vort/health_charge.wav";
new String:HookSound[]="weapons/357/357_spin1.wav";
new String:CDSound[]="war3source/ability_refresh.mp3";

// SKILL_SWORD
new Float:SwordCD=2.0;
new Float:SwordRange[]={0.0,45.0,90.0,135.0,180.0};

// ULT_SIGHT
new BeamSprite;
new Float:SightCD=25.0;
new Float:Location[MAXPLAYERSCUSTOM][3];
new Float:Eyes[MAXPLAYERSCUSTOM][3];
new bool:bInSight[MAXPLAYERSCUSTOM]={false, ...};


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Lion-O [PRIVATE]","liono");
	SKILL_AGILITY = War3_AddRaceSkill(thisRaceID,"Cat Agility","Low Gravity (passive)",false,4);
	SKILL_SHIELD = War3_AddRaceSkill(thisRaceID,"Claw Shield","Damage Reduction (+ability) and Grappling Hook (+ability1)",false,1);
	SKILL_SWORD = War3_AddRaceSkill(thisRaceID,"Sword of Omens","Knife range increases (left click only)",false,4);
	ULT_SIGHT=War3_AddRaceSkill(thisRaceID,"Sight beyond Sight","No clip mode (+ultimate)",true,1);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_SIGHT,10.0,_);
	War3_AddSkillBuff(thisRaceID,SKILL_AGILITY,fLowGravitySkill,CatAgilityGrav);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("weapon_fire", Event_WeaponFire);
	CreateTimer(0.1,HookCooldownTimer,_,TIMER_REPEAT);
}

public OnMapStart()
{
	War3_PrecacheSound(ShieldSound);
	War3_PrecacheSound(HookSound);
	War3_PrecacheSound(CDSound);
	WebSprite=PrecacheModel("materials/effects/combineshield/comshieldwall.vmt");
	BeamSprite=PrecacheModel("Models/MANHACK/Blur01.vmt");
	m_vecBaseVelocity=FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=1; i<MaxClients; i++)
    {
        if (ValidPlayer(i,true) && War3_GetRace(i)==thisRaceID)
        {
            InitPassiveSkills(i);
        }
    }
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		bInShield[client]=false;
		bInSight[client]=false;
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
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
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
	bInShield[client]=false;
	bInSight[client]=false;
	W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
	War3_SetBuff(client,bNoClipMode,thisRaceID,false);
	War3_SetBuff(client,bDisarm,thisRaceID,false);
}


/* *************************************** (SKILL_SHIELD) *************************************** */
static SetHookCooldown(client, Float:cooldown)
{
    HookAvailableTime[client]=GetGameTime()+cooldown;
    HookInCooldown[client]=(cooldown>0.0) ? true : false;
}

static Float:GetHookCooldownRemaining(client)
{
    return (HookAvailableTime[client]-GetGameTime());
}

static bool:IsGrapplingReady(client)
{
    return (GetGameTime()>=HookAvailableTime[client]) ? true : false;
}

public Action:HookCooldownTimer(Handle:timer)
{
    for (new i=0; i<=MaxClients; i++)
    {
        if (War3_GetRace(i)==thisRaceID && IsGrapplingReady(i) && HookInCooldown[i])
        {
            HookInCooldown[i]=false;
            PrintHintText(i,"Grappling Hook is ready");
            EmitSoundToAll(CDSound,i);
        }
    }
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		new ShieldLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SHIELD);
		if(ShieldLevel>0)
		{
			if(ability==0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_SHIELD,true,true,true))
				{
					War3_CooldownMGR(client,ShieldCD,thisRaceID,SKILL_SHIELD,true,true);
					bInShield[client]=true;
					CreateTimer(ShieldDuration,StopShield,client);
					EmitSoundToAll(ShieldSound,client);
				}
			}

			if(ability==1)
			{
				if(IsGrapplingReady(client))
				{
					TeleportPlayer(client);
					EmitSoundToAll(HookSound,client);
					SetHookCooldown(client,HookCD);
				}
				else
					W3Hint(client,HINT_LOWEST,1.0,"Grappling Hook Is Not Ready. %i seconds remaining",RoundToNearest(GetHookCooldownRemaining(client)));
			}
			
		}
		else
			PrintHintText(client,"Level your skill first");
	}
}

public Action:StopShield(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bInShield[client])
	{
		bInShield[client]=false;
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID && bInShield[victim] && SkillFilter(attacker))
		{
			War3_DamageModPercent(ShieldReduce);
		}
	}
}

public TeleportPlayer(client)
{
	if(client>0 && IsPlayerAlive(client))
	{
		new Float:startpos[3];			GetClientAbsOrigin(client,startpos);
		new Float:endpos[3];			War3_GetAimEndPoint(client,endpos);
		new Float:localvector[3];
		new Float:velocity[3];

		localvector[0] = endpos[0] - startpos[0];
		localvector[1] = endpos[1] - startpos[1];
		localvector[2] = endpos[2] - startpos[2];
		
		velocity[0] = localvector[0] * PushForce;
		velocity[1] = localvector[1] * PushForce;
		velocity[2] = localvector[2] * PushForce;
		
		SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
		TE_SetupBeamPoints(startpos,endpos,WebSprite,WebSprite,0,0,1.0,1.0,1.0,0,0.0,{255,14,41,255},0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(endpos,11.0,9.0,WebSprite,WebSprite,0,0,2.0,13.0,0.0,{255,100,100,255},0,FBEAM_ISACTIVE);
		TE_SendToAll();
	}
}

/* *************************************** (SKILL_SWORD) *************************************** */
public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		if(SkillAvailable(client,thisRaceID,SKILL_SWORD,false,true,true))
		{
			new SwordLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SWORD);
			if(SwordLevel>0)
			{
				new target = War3_GetTargetInViewCone(client,SwordRange[SwordLevel],false,15.0);
				if(target>0 && SkillFilter(target))
				{
					War3_CooldownMGR(client,SwordCD,thisRaceID,SKILL_SWORD,true,false);
					
					
					new damage;
					if(GetClientArmor(client)>5)
						damage=15;
					else
						damage=20;
						
					War3_DealDamage(target,damage,client,DMG_SLASH,"sword of omens",_,W3DMGTYPE_MAGIC);
					PrintToChat(client,"Damaged %N for %i damage",target,damage);
					
					new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
					new Float:targetPos[3];		GetClientAbsOrigin(target,targetPos);	
					TE_SetupBeamPoints(clientPos, targetPos, BeamSprite, BeamSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {255,255,255,255}, 50); 
					TE_SendToAll();
					targetPos[2]+=50;
					TE_SetupGlowSprite(targetPos,BeamSprite,0.5,0.4,255);
					TE_SendToAll();
				}
			}
		}
	}
}

/* *************************************** (ULT_SIGHT) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new SightLevel=War3_GetSkillLevel(client,thisRaceID,ULT_SIGHT);
		if(SightLevel>0)
		{
			if(bInSight[client])
			{
				War3_CooldownMGR(client,SightCD,thisRaceID,ULT_SIGHT,true,true);
				bInSight[client]=false;
				W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
				War3_SetBuff(client,bNoClipMode,thisRaceID,false);
				War3_SetBuff(client,bDisarm,thisRaceID,false);
				TeleportEntity(client,Location[client],Eyes[client],NULL_VECTOR);
			}
			else
			{
				if(SkillAvailable(client,thisRaceID,ULT_SIGHT,true,true,true))
				{
					bInSight[client]=true;
					W3FlashScreen(client,{40,40,40,220},6.0,1.0,FFADE_OUT);
					War3_SetBuff(client,bNoClipMode,thisRaceID,true);
					War3_SetBuff(client,bDisarm,thisRaceID,true);
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
					GetClientEyeAngles(client,Eyes[client]);
					GetClientAbsOrigin(client,Location[client]);
					for(new target=1;target<=MaxClients;target++)
					{
						if(ValidPlayer(target,true))
						{
							new team = GetClientTeam(target);
							new cteam = GetClientTeam(client);
							if(team != cteam)
							{
								new Float:pos[3];
								GetClientAbsOrigin(target,pos);
								TE_SetupDynamicLight(pos,255,2,2,500,80.0,0.5,9.5);
								TE_SendToClient(client, 0.1); 
								TE_SetupBubbles(pos, pos,BeamSprite,900.0, 25, 900.0);
								TE_SendToClient(client, 0.1); 
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

stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
	TE_Start("Dynamic Light");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("r",r);
	TE_WriteNum("g",g);
	TE_WriteNum("b",b);
	TE_WriteNum("exponent",iExponent);
	TE_WriteFloat("m_fRadius",fRadius);
	TE_WriteFloat("m_fTime",fTime);
	TE_WriteFloat("m_fDecay",fDecay);
}
