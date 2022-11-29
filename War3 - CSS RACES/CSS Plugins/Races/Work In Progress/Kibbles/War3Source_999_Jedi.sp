#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Jedi",
	author = "ABGar",
	description = "The Jedi race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_JUMP, SKILL_WEAPON, SKILL_PULL, ULT_MIND;

new String:JediSound[]="war3source/jedi.mp3";
new Float:SoundAvailableTime[MAXPLAYERSCUSTOM];
new Float:SoundCooldown = 1.0;
new Float:JediBaseSpeed = 1.2;

// SKILL_JUMP
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
new Float:ForceJump[]={0.0,0.25,0.375,0.5,0.625};
new Float:JumpGravity[]={0.0,0.9,0.9,0.9,0.9};//as requested after quoting

// SKILL_PULL
new BeamSprite, HaloSprite;
new Float:PullCD[]={0.0,30.0,25.0,20.0,15.0};
new Float:PullForce[]={0.0,1500.0,2000.0,2500.0,3000.0};
new Float:PullRange[]={0.0,200.0,400.0,600.0,800.0};

// SKILL_WEAPON
new WeaponDamage[]={0,12,24,36,48};
new Float:WeaponChance=0.7;
new Float:WeaponCooldown=5.0;

// ULT_MIND
new Float:ControlRange=600.0;
new MindTime[]={0,6,5,4,3};
new ControlTime[MAXPLAYERS];
new bool:bControlling[MAXPLAYERS][MAXPLAYERS];
new bool:bChanged[MAXPLAYERS];
new bool:bChannel[MAXPLAYERS];


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Jedi [PRIVATE]","jedi");
	SKILL_JUMP = War3_AddRaceSkill(thisRaceID,"Force Jump","Using the Force, you jump great distances (passive)",false,4);
	SKILL_PULL = War3_AddRaceSkill(thisRaceID,"Force Pull","Using the Force, you pull your foes towards you (+ability)",false,4);
	SKILL_WEAPON = War3_AddRaceSkill(thisRaceID,"Jedi's Weapon","Your skill with a lightsabre increases (passive)",false,4);
	ULT_MIND=War3_AddRaceSkill(thisRaceID,"Jedi Mind Tricks","The Force can influence the weak minded, and convert them to your cause (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_JUMP, fLowGravitySkill, JumpGravity);
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    SetSoundCooldown(client, 0.0);
    War3_SetBuff(client,fMaxSpeed,thisRaceID,JediBaseSpeed);
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	AddFileToDownloadsTable("sound/war3source/jedi.mp3");
	War3_PrecacheSound(JediSound);
}

public OnPluginStart()
{
	HookEvent("round_end", OnRoundEnd);	
	HookEvent("player_jump",PlayerJumpEvent);
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	CreateTimer(1.0,ControlLoop,_,TIMER_REPEAT);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
	{
		if(buttons & IN_ATTACK2 && IsSoundAvailable(client))
		{
			EmitSoundToAll(JediSound,client);
			SetSoundCooldown(client,SoundCooldown);
		}
	}
	return Plugin_Continue;
}
static SetSoundCooldown(client, Float:cooldown)
{
    SoundAvailableTime[client]=GetGameTime()+cooldown;
}
static bool:IsSoundAvailable(client)
{
    return (GetGameTime()>=SoundAvailableTime[client]) ? true : false;
}

/* *************************************** (SKILL_JUMP) *************************************** */
public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid"));
    if(War3_GetRace(client)==thisRaceID)
    {
        new JumpLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_JUMP);
        if(JumpLevel>0)
        {
            new Float:velocity[3]={0.0,0.0,0.0};
            velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
            velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
            velocity[0]*=ForceJump[JumpLevel];
            velocity[1]*=ForceJump[JumpLevel];
            SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
        }
    }
}

/* *************************************** (SKILL_PULL) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client, true) && War3_GetRace(client)==thisRaceID && ability==0 && pressed)
	{
		new PullLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_PULL);
		if(PullLevel>0)
        {
			if(SkillAvailable(client,thisRaceID,SKILL_PULL,true,true,true))
			{
				new target = War3_GetTargetInViewCone(client,PullRange[PullLevel],false,30.0);
				if(target>0)
				{
					if(SkillFilter(target))//check target, not client!
					{
                        War3_CooldownMGR(client,PullCD[PullLevel],thisRaceID,SKILL_PULL,_,_);//cooldown up top, especially with a lot of vector processing
                        
						new Float:startpos[3];
						new Float:endpos[3];
						new Float:vector[3];
						
						GetClientAbsOrigin(client,endpos);
						GetClientAbsOrigin(target,startpos);

						MakeVectorFromPoints(startpos, endpos, vector);
                        //added extra processing from Scorpion to scale pull force based on closeness
                        new Float:ratio = PullForce[PullLevel]/PullRange[PullLevel];
                        new Float:pullForce = GetVectorLength(vector)*ratio;
                        pullForce = (pullForce < PullForce[1]) ? PullForce[1] : pullForce;
						NormalizeVector(vector, vector);
						ScaleVector(vector, pullForce);
						TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vector);
						TE_SetupBeamPoints(startpos,endpos,BeamSprite,HaloSprite,0,35,1.0,10.0,20.0,0,1.0,{255,255,255,255},20);
						TE_SendToAll();
					}
					else
						W3MsgEnemyHasImmunity(client,false);
				}
				else
				{
					W3MsgNoTargetFound(client);
				}
			}
		}
		else
			PrintHintText(client,"Level your Force Pull first");
	}
}
/* *************************************** (SKILL_WEAPON) *************************************** */
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(SkillAvailable(attacker,thisRaceID,SKILL_WEAPON,false,true,true))
			{
				new WeaponLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_WEAPON);
				if(WeaponLevel>0 && W3Chance(WeaponChance))
				{
					War3_CooldownMGR(attacker,WeaponCooldown,thisRaceID,SKILL_WEAPON,true,true);
					War3_DealDamage(victim,WeaponDamage[WeaponLevel],attacker,DMG_CRUSH,"lightsaber",_,W3DMGTYPE_MAGIC);
				}
			}
		}
	}
}



/* *************************************** (ULT_MIND) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		if(SkillAvailable(client,thisRaceID,ULT_MIND,true,true,true))
		{
			new MindLevel=War3_GetSkillLevel(client,thisRaceID,ULT_MIND);
			if(MindLevel>0)
			{
				new target = War3_GetTargetInViewCone(client,ControlRange,false,25.0);
				if(target>0 && !bChanged[target] && UltFilter(target))
				{
					new clientTeam=GetClientTeam(target);
					new playersAliveSameTeam;
					for(new i=1;i<=MaxClients;i++)
					{
						if(i!=target && ValidPlayer(i,true) && GetClientTeam(i)==clientTeam)
						{
							playersAliveSameTeam++;
						}
					}
					if(playersAliveSameTeam>0)
					{
						bChannel[client]=true;
						War3_SetBuff(client,bStunned,thisRaceID,true);
						War3_SetBuff(target,bStunned,thisRaceID,true);
						ControlTime[client]=0;
						new Float:pos[3];
						GetClientAbsOrigin(client,pos);
						pos[2]+=15;
						new Float:tarpos[3];
						GetClientAbsOrigin(target,tarpos);
						tarpos[2]+=15;
						TE_SetupBeamPoints(pos,tarpos,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{120,84,120,255},50);
						TE_SendToAll();	
						TE_SetupBeamRingPoint(tarpos, 1.0, 250.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
						TE_SendToAll();
						tarpos[2]+=15;
						TE_SetupBeamRingPoint(tarpos, 250.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
						TE_SendToAll();
						tarpos[2]+=15;
						TE_SetupBeamRingPoint(tarpos, 1.0, 125.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
						TE_SendToAll();
						tarpos[2]+=15;
						TE_SetupBeamRingPoint(tarpos, 125.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
						TE_SendToAll();
						bControlling[client][target]=true;
						PrintHintText(client, "The Force is strong on the weak minded");
						PrintHintText(target, "The Force is strong on the weak minded");
					}
					else
						PrintHintText(client, "Target is last person alive, cannot be controlled");
				}
				else
					W3MsgNoTargetFound(client);
			}
			else
				W3MsgUltNotLeveled(client);
		}
	}
}

public Action:ControlLoop(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			if(War3_GetRace(client)==thisRaceID)
			{
				for(new target=1;target<=MaxClients;target++)
				{
					if(ValidPlayer(target,true)&&bControlling[client][target])
					{
						new MindLevel=War3_GetSkillLevel(client,thisRaceID,ULT_MIND);
						if(ControlTime[client]<MindTime[MindLevel])
						{
							new Float:pos[3];
							GetClientAbsOrigin(client,pos);
							pos[2]+=15;
							new Float:tarpos[3];
							GetClientAbsOrigin(target,tarpos);
							tarpos[2]+=15;
							TE_SetupBeamPoints(pos,tarpos,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{120,84,120,255},50);
							TE_SendToAll();	
							TE_SetupBeamRingPoint(tarpos, 1.0, 250.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(tarpos, 250.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(tarpos, 1.0, 125.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(tarpos, 125.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							ControlTime[client]++;
						}
						else
						{
							War3_CooldownMGR(client,60.0,thisRaceID,ULT_MIND,_,_);
							War3_SetBuff(client,bStunned,thisRaceID,false);
							War3_SetBuff(target,bStunned,thisRaceID,false);
							bControlling[client][target]=false;
							bChannel[client]=false;
							new target_team=GetClientTeam(target);
							PrintHintText(client, "You have a new Padawan");
							PrintHintText(target, "You've joined the Jedi");
							W3FlashScreen(target,{120,0,255,50});
							if(target_team==TEAM_CT)
							{
								bChanged[target]=true;
								CS_SwitchTeam(target, TEAM_T);
                                W3SetPlayerColor(target, thisRaceID, 255, 0, 0, _, GLOW_BASE);
							}
							if(target_team==TEAM_T)
							{
								bChanged[target]=true;
								CS_SwitchTeam(target, TEAM_CT);
                                W3SetPlayerColor(target, thisRaceID, 0, 0, 255, _, GLOW_BASE);
							}
						}
					}
				}
			}
		}
	}
}

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		if(vteam!=ateam){
			new race_victim=War3_GetRace(victim);
			
			if(race_victim==thisRaceID && bChannel[victim]){
				War3_SetBuff(victim,bStunned,thisRaceID,false);
				bChannel[victim]=false;
				War3_CooldownMGR(victim,30.0,thisRaceID,ULT_MIND);
				for(new target=1;target<=MaxClients;target++){
					if(ValidPlayer(target,true)&&bControlling[victim][target]){
						bControlling[victim][target]=false;
						War3_SetBuff(target,bStunned,thisRaceID,false);
					}
			
				}
				PrintHintText(victim, "You've been interupted");
			}
		}
		
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	if(ValidPlayer(i))
	{
		ResetClientTeam(i);
	}
}

public OnWar3EventDeath(victim,attacker)
{
    if (ValidPlayer(victim) && ValidPlayer(attacker))//added in Spellbreaker code to manage deaths
    {
        new race_victim=War3_GetRace(victim);
        
        if(race_victim==thisRaceID){
            for(new controlled=1;controlled<=MaxClients;controlled++)
            {
                if(ValidPlayer(controlled)&&bChanged[controlled])
                {
                    PrintHintText(controlled, "You are free again!");
                    W3FlashScreen(controlled,{120,0,255,50});
                    ResetClientTeam(victim);
                }
                
            }
        }
        
        for(new client=1;client<=MaxClients;client++){
            if(bControlling[client][victim]){
                War3_SetBuff(client,bStunned,thisRaceID,false);
                War3_SetBuff(victim,bStunned,thisRaceID,false);
                bChannel[client]=false;
                bControlling[client][victim]=false;	
                War3_CooldownMGR(client,30.0,thisRaceID,ULT_MIND);
            }
        }
    }
}

static ResetClientTeam(client)//generalise the reset function
{
    if(bChanged[client])
	{
		new target_team=GetClientTeam(client);
		if(target_team==TEAM_T)
		{
			bChanged[client]=false;
			CS_SwitchTeam(client, TEAM_CT);
		}
		else
		{
			bChanged[client]=false;
			CS_SwitchTeam(client, TEAM_T);
		}
        W3ResetPlayerColor(client, thisRaceID);
	}
}