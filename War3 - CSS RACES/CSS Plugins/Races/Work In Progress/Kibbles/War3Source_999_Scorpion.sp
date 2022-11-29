#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Scorpion",
	author = "ABGar & Kibbles",
	description = "The Scorpion race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
};

new thisRaceID;

new SKILL_RUNFAST, SKILL_SPEAR, SKILL_SWORDS, ULT_TOASTY;

// SKILL_RUNFAST
new Float:ScorpSpeed[]={1.0,1.1,1.2,1.3,1.4};

// SKILL_SPEAR
new Float:SpearRange[]={0.0,600.0,750.0,900.0,1050.0};//Use variables wherever possible. This makes the race easier to maintain :)
new SpearDamage = 5;
new Float:SpearCD[]={0.0,30.0,25.0,20.0,15.0};
new Float:PullForce[]={0.0,1500.0,2000.0,2500.0,3000.0};
new String:SpearSound[]="war3source/scorpion/getoverhere.mp3";

// SKILL_SWORDS
new Float:SwordDamage[]={1.0,1.25,1.5,1.75,2.0};
new Float:SwordBurnTime[]={0.0,1.0,2.0,3.0,4.0};
new Float:SwordDamageThreshold = 0.5;//Must be <= than Burn Threshold
new Float:SwordBurnThreshold = 1.0;//Must be >= than Damage Threshold
new String:SwordDamageSound[]="npc/roller/mine/rmine_blades_out2.wav";
new String:SwordBurnSound[]="war3source/roguewizard/fire.wav";
 
// ULT_TOASTY
new BeamSprite,HaloSprite,BurnSprite;
new ToastyDamagePerTick=10;
new Float:ToastyRange[]={0.0,150.0,200.0,250.0,300.0};
new FireTicks[]={0,2,3,4,5};//Track DoT by counters, not by time. Timing is finnicky on computers!
new Float:ToastyCD[]={0.0,35.0,35.0,35.0,35.0}; 
new String:ToastySound[]="war3source/scorpion/finishhim.mp3";
new bToasty[MAXPLAYERS];
new bToastyOwner[MAXPLAYERS];
new ToastyTicks[MAXPLAYERS];


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Scorpion [PRIVATE]","scorpion");
	SKILL_RUNFAST = War3_AddRaceSkill(thisRaceID,"Speed","Scorpion moves swiftly through the Nether-realms (passive)",false,4);
	SKILL_SPEAR = War3_AddRaceSkill(thisRaceID,"Spear","Get over here... (+ability)",false,4);
	SKILL_SWORDS = War3_AddRaceSkill(thisRaceID,"Swords","Scorpion carries true ninja swords (passive)",false,4);
	ULT_TOASTY=War3_AddRaceSkill(thisRaceID,"Toasty","Scorpion removes his mask to show his flaming skull \nand spews fire on his opponent dealing critical damage (+ultimate)",true,4);//be very careful with making abilities skill or ultimates :)
	War3_CreateRaceEnd(thisRaceID);
    
	War3_AddSkillBuff(thisRaceID, SKILL_RUNFAST, fMaxSpeed, ScorpSpeed);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo(client, thisRaceID, "");
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	}
}

public OnWar3EventSpawn(client)
{
    StopToasty(client);
	if(War3_GetRace(client)==thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	}
}


public OnMapStart()
{
	AddFileToDownloadsTable("sound/war3source/scorpion/getoverhere.mp3");
	AddFileToDownloadsTable("sound/war3source/scorpion/finishhim.mp3");
	War3_PrecacheSound(SpearSound);
	War3_PrecacheSound(ToastySound);	
    War3_PrecacheSound(SwordDamageSound);
    War3_PrecacheSound(SwordBurnSound);
	
	BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

/* *************************************** (SKILL_SPEAR) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client, true))//Use ValidPlayer!
	{
		new spear_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEAR);
		if(spear_level>0)
        {
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SPEAR,true))
			{
				if(!Silenced(client))
				{
					new target = War3_GetTargetInViewCone(client,SpearRange[spear_level],false,30.0);//You want it to target enemies, not allies!
					if(ValidPlayer(target, true) && GetClientTeam(client)!=GetClientTeam(target))//Use ValidPlayer!
					{
						if(!W3HasImmunity(target,Immunity_Skills))
						{
                            War3_CooldownMGR(client,SpearCD[spear_level],thisRaceID,SKILL_SPEAR,_,_);//Put cooldowns first unless the ability specifically requires it to be set after processing. Otherwise players can sometimes spam the ability for multiple procs.
                            
							new Float:startpos[3];
							new Float:endpos[3];
							new Float:vector[3];
							
							GetClientAbsOrigin( client, endpos);
							GetClientAbsOrigin( target, startpos );
							
							W3EmitSoundToAll(SpearSound,client);
                            W3EmitSoundToAll(SpearSound,target);//Emit from the victim as well, so they know what's happening without having to read
							MakeVectorFromPoints(startpos, endpos, vector);
                            new Float:ratio = PullForce[spear_level]/SpearRange[spear_level];
                            new Float:pullForce = GetVectorLength(vector)*ratio;
                            pullForce = (pullForce < PullForce[1]) ? PullForce[1] : pullForce;
							NormalizeVector(vector, vector);
							ScaleVector(vector, pullForce);
							TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vector);
                            endpos[2]+=40.0;
                            startpos[2]+=40.0;
							TE_SetupBeamPoints(startpos,endpos,BeamSprite,HaloSprite,0,35,1.0,10.0,20.0,0,1.0,{255,69,0,255},20);
							TE_SendToAll();
							War3_DealDamage(target,SpearDamage,client,DMG_CRUSH,"scorpion spear",_,W3DMGTYPE_MAGIC);
							PrintHintText(target,"Get Over Here !!!!!!!!!!");
						}
						else
							W3MsgEnemyHasImmunity(client,false);
					}
					else
					{
						W3MsgNoTargetFound(client, SpearRange[spear_level]);
					}
				}
			}
			else
			{
				PrintHintText(client,"Scorpion Spear is not ready yet");
			}
		}
		else
		{
			PrintHintText(client,"Level your Scorpion Spear first");
		}
	}
}
/* *************************************** (SKILL_SWORDS) *************************************** */
public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker,true)&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
        new race_attacker=War3_GetRace(attacker);
		if(vteam!=ateam&&race_attacker==thisRaceID)
		{
			new skill_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_SWORDS);
			if(skill_attacker>0 && !Hexed(attacker,false))
			{
				if(!W3HasImmunity(victim,Immunity_Skills))
				{
					if (W3GetDamageType() & DMG_BULLET)
					{
						new Float:SwordChance = GetRandomFloat(0.0,1.0);
						if (SwordChance<=SwordDamageThreshold)
						{
							War3_DamageModPercent(SwordDamage[skill_attacker]);
                            EmitSoundToAll(SwordDamageSound,attacker);
						}
						else if (SwordChance>SwordDamageThreshold && SwordChance<=SwordBurnThreshold)
						{
							IgniteEntity(victim,SwordBurnTime[skill_attacker]);
                            EmitSoundToAll(SwordBurnSound,attacker);
						}
					}
				}
			}
		}
	}
}


/* *************************************** (ULT_TOASTY) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_TOASTY);
        if(ult_level>0)
        {
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TOASTY,true))
			{
				if(!Silenced(client))
				{
					//new target = War3_GetTargetInViewCone(client,ToastyRange[ult_level],false,35.0);//Don't target allies!
                    
                    new Float:origin[3];
                    GetClientAbsOrigin(client,origin);
                    new Float:targetpos[3];
                    new target = -1;
                    new Float:closestDistance = ToastyRange[ult_level];
                    new Float:tmpDistance;
                    for (new i=1; i<=MaxClients; i++)//Similar targetting to chain lightning, as requested
                    {
                        if (ValidPlayer(i, true) && i!=client && GetClientTeam(i)!=GetClientTeam(client) && !W3HasImmunity(i,Immunity_Ultimates))
                        {
                            GetClientAbsOrigin(i,targetpos);
                            tmpDistance = GetVectorDistance(origin, targetpos);
                            if (tmpDistance <= closestDistance)
                            {
                                closestDistance = tmpDistance;
                                target = i;
                            }
                        }
                    }
                    
					if(ValidPlayer(target))//Use ValidPlayer!
					{
                        War3_CooldownMGR(client,ToastyCD[ult_level],thisRaceID,ULT_TOASTY,_,_);//cooldown goes here :)
                        origin[2]+=40.0;
                        targetpos[2]+=40.0;
                        TE_SetupBeamPoints(origin, targetpos, BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
                        TE_SendToAll();
                        //GetClientAbsOrigin(target,targetpos);
                        targetpos[2]+=10;
                        TE_SetupGlowSprite(targetpos,BurnSprite,1.0,1.9,255);
                        TE_SendToAll();//special effects take time to process. Careful where you place them!
                        bToasty[target]=true;
                        bToastyOwner[target]=client;
                        ToastyTicks[target]=FireTicks[ult_level];
                        EmitSoundToAll(ToastySound,client);//both sounds go here
                        EmitSoundToAll(ToastySound,target);
                        CreateTimer(1.0,ToastyLoop,target);//no need for userids in standard play. If a client disconnects this should stop affecting them anyway!
                        War3_DealDamage(target,ToastyDamagePerTick,client,DMG_CRUSH,"Toasty!",_,W3DMGTYPE_MAGIC);
					}
					else
					{
                        W3MsgNoTargetFound(client, ToastyRange[ult_level]);
					}
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Toasty first");
		}
	}
}

public Action:ToastyLoop(Handle:timer, any:client)
{
	if(ValidPlayer(client,true))//alive check!
	{
        new attacker=bToastyOwner[client];
        if (ValidPlayer(attacker) && War3_GetRace(attacker) == thisRaceID && bToasty[client] && ToastyTicks[client] > 0 && !W3HasImmunity(client,Immunity_Ultimates))
        {
            new Float:targetpos[3];
            GetClientAbsOrigin(client,targetpos);
            targetpos[2]+=50;
            TE_SetupGlowSprite(targetpos,BurnSprite,1.0,1.9,255);
            TE_SendToAll();
            
            ToastyTicks[client]--;
            
            CreateTimer(1.0,ToastyLoop,client);
            War3_DealDamage(client,ToastyDamagePerTick,attacker,DMG_CRUSH,"Toasty!",_,W3DMGTYPE_MAGIC);
        }
        else
        {
            StopToasty(client);
        }
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(bToasty[victim])
	{
		if(ValidPlayer(victim) && ValidPlayer(attacker) && War3_GetRace(attacker)==thisRaceID && attacker == bToastyOwner[victim])//You don't need the extra checks!
		{
            PrintHintText(attacker,"F A T A L I T Y");//Tell the attacker, too!
			PrintCenterText(victim,"F A T A L I T Y");
			StopToasty(victim);
		}
	}
}

static StopToasty(client)//better organization, and easier to maintain
{
    bToasty[client] = false;
    bToastyOwner[client] = -1;
    ToastyTicks[client] = 0;
}