#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Barrel Hider 3",
	author = "ABGar",
	description = "The Barrel Hider 3 race for War3Source.",
	version = "1.0",
	// SeaLion's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5459-the-2nd-sequel-of-barrel-hider/
}

new thisRaceID;

new SKILL_SPEED, SKILL_DAMAGE, SKILL_WARD, ULT_HIDE;

// SKILL_SPEED
new Float:RunSpeed[]={1.0,1.05,1.15,1.25,1.3};

// SKILL_DAMAGE
new HaloSprite, BeamSprite, LargeBeam;
new gShotNumber;
new HiderDamage[]={0,10,15,20,25};
new Float:DamageChance=0.20;
new Float:DamageSlowTime[]={0.0,0.5,0.7,0.9,1.1};
new Float:AttackSlow[]={1.0,0.9,0.88,0.82,0.78};
new Float:SpeedSlow[]={1.0,0.9,0.8,0.75,0.70};
new String:DamageSound[]="weapons/mortar/mortar_explode2.wav";

// SKILL_WARD
#define MAXWARDS 64*1
#define WARDRADIUS 200
#define WARDDAMAGE 3
#define WARDBELOW -2.0 
#define WARDABOVE 160.0
#define WARDNUMBER 64*1
new CurrentWardCount[MAXPLAYERSCUSTOM];
new WardOwner[MAXWARDS];
new WardDamage[]={0,2,3,4,5};
new WardStartingArr[]={0,1,2,3,4}; 
new Float:WardLocation[MAXWARDS][3]; 
new Float:LastThunderClap[MAXPLAYERSCUSTOM];
new Float:WardDistance[]={0.0,125.0,150.0,175.0,200.0};
new String:wardDamageSound[]="ambient/misc/wood1.wav";

// ULT_HIDE
new String:gModel[MAXPLAYERSCUSTOM];
new bHiding[MAXPLAYERSCUSTOM];
new Float:HideCooldown=2.0;
new String:bPreModel[MAXPLAYERSCUSTOM];
new String:TreeModel[]="models/props_foliage/tree_deciduous_01a-lod.mdl";
new String:HostageModel[]="models/characters/hostage_01.mdl";
new String:ShrubModel[]="models/props/pi_fern.mdl";
new String:CarModel[]="models/props_vehicles/car004b.mdl";
new String:RockModel[]="models/props/cs_militia/militiarock05.mdl";
new String:LampModel[]="models/props_c17/lamppost03a_off.mdl";
new String:BarrelModel[]="models/props_c17/oildrum001.mdl";
new String:HideSound[]="ambient/water_splash2.wav";
new bActiveForm[MAXPLAYERSCUSTOM];

new XPMin=5;
new XPMax=20;

new bool:bInSpeed[MAXPLAYERSCUSTOM];
new Float:SpeedIncrease=1.1;

new ThornsMin=15;
new ThornsMax=25;

new Float:RockDamageReduce=0.5;
new Float:HPRegenAmount=3.0;

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Barrel Hider 3 [PRIVATE]","hider3");
	SKILL_SPEED = War3_AddRaceSkill(thisRaceID,"Try me, B*tch","Extra spped (passive)",false,4);
	SKILL_DAMAGE = War3_AddRaceSkill(thisRaceID,"Be one with the Barrel Hider","Extra damage and shake when attacking enemies (passive)",false,4);
	SKILL_WARD = War3_AddRaceSkill(thisRaceID,"Bruch, which one am I?","Create a random prop ward (+ability)",false,4);
	ULT_HIDE=War3_AddRaceSkill(thisRaceID,"Master Barrel Hider","Turn into a Sneaky F*ucker (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_HIDE,10.0,_);
	War3_AddSkillBuff(thisRaceID,SKILL_SPEED,fMaxSpeed,RunSpeed);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		RemoveWards(client);
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
	RemoveWards(client);
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_m3,weapon_p228,weapon_knife");
	CreateTimer(0.5,GiveWep,client);
	bActiveForm[client]=0;
}

public OnMapStart()
{
	LargeBeam=PrecacheModel("effects/blueblacklargebeam.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	PrecacheModel(TreeModel);
	PrecacheModel(HostageModel);
	PrecacheModel(ShrubModel);
	PrecacheModel(CarModel);
	PrecacheModel(RockModel);
	PrecacheModel(LampModel);
	PrecacheModel(BarrelModel);
	War3_PrecacheSound(DamageSound);
	War3_PrecacheSound(HideSound);
	War3_PrecacheSound(wardDamageSound);
}

public OnPluginStart()
{
	CreateTimer(0.5,CalcWards,_,TIMER_REPEAT);
	CreateTimer(1.0,CalcHPRegen,_,TIMER_REPEAT);
	HookEvent("weapon_fire",Event_WeaponFire);
}

/* *************************************** (SKILL_WARD) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_WARD);
		if(skill_level>0)
		{
			if(CurrentWardCount[client]<WardStartingArr[1])
			{
				CreateWard(client);
				CurrentWardCount[client]++;
				new Float:playerpos[3];		GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerpos);

				new entindex = CreateEntityByName("prop_dynamic");
				if (entindex != -1)
				{
					DispatchKeyValue(entindex, "targetname", "loltest");
					new Dice=GetRandomInt(1,7);
					{
						if(Dice==1)
						{
							DispatchKeyValue(entindex, "model", TreeModel);
							PrintToConsole(client,"TreeModel");
						}	
						else if(Dice==2)
						{
							DispatchKeyValue(entindex, "model", HostageModel);
							PrintToConsole(client,"HostageModel");
						}
						else if(Dice==3)
						{
							DispatchKeyValue(entindex, "model", ShrubModel);
							PrintToConsole(client,"ShrubModel");
						}
						else if(Dice==4)
						{
							DispatchKeyValue(entindex, "model", CarModel);
							PrintToConsole(client,"CarModel");
						}
						else if(Dice==5)
						{
							DispatchKeyValue(entindex, "model", RockModel);
							PrintToConsole(client,"RockModel");
						}
						else if(Dice==6)
						{
							DispatchKeyValue(entindex, "model", LampModel);
							PrintToConsole(client,"LampModel");
						}
						else if(Dice==7)
						{
							DispatchKeyValue(entindex, "model", BarrelModel);
							PrintToConsole(client,"BarrelModel");
						}
					}
				}
				DispatchSpawn(entindex);
				ActivateEntity(entindex);
				TeleportEntity(entindex, playerpos, NULL_VECTOR, NULL_VECTOR);
			}
			else
				PrintHintText(client,"You can't place another Ward");
		}
    }
}

public CreateWard(client)
{
    for(new i=0;i<MAXWARDS;i++)
    {
        if(WardOwner[i]==0)
        {
            WardOwner[i]=client;
            GetClientAbsOrigin(client,WardLocation[i]);
            break;
        }
    }
}

public RemoveWards(client)
{
    for(new i=0;i<MAXWARDS;i++)
    {
        if(WardOwner[i]==client)
        {
            WardOwner[i]=0;
        }
    }
    CurrentWardCount[client]=0;
}

public Action:CalcWards(Handle:timer,any:userid)
{
    new client;
    for(new i=0;i<MAXWARDS;i++)
    {
        if(WardOwner[i]!=0)
        {
            client=WardOwner[i];
            if(!ValidPlayer(client,true))
            {
                WardOwner[i]=0; 
                --CurrentWardCount[client];
            }
            else
            {
                WardEffectAndDamage(client,i); 
            }
        }
    }
}

public WardEffectAndDamage(owner,wardindex)
{
    new ownerteam=GetClientTeam(owner);
    new Float:start_pos[3];
    new Float:end_pos[3];
    
    new Float:tempVec1[]={0.0,0.0,WARDBELOW};
    new Float:tempVec2[]={0.0,0.0,WARDABOVE};
    AddVectors(WardLocation[wardindex],tempVec1,start_pos);
    AddVectors(WardLocation[wardindex],tempVec2,end_pos);
    new Float:BeamXY[3];
    for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
    new Float:BeamZ= BeamXY[2];
    BeamXY[2]=0.0;
    new wardradiusskill=War3_GetSkillLevel(owner,thisRaceID,SKILL_WARD);
    
    new Float:VictimPos[3];
    new Float:tempZ;
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam )
        {
            GetClientAbsOrigin(i,VictimPos);
            tempZ=VictimPos[2];
            VictimPos[2]=0.0; //no Z
                  
            if(GetVectorDistance(BeamXY,VictimPos) < WardDistance[wardradiusskill] ) ////ward RADIUS
            {
                // now compare z
				
                if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
                {
					if(W3HasImmunity(i,Immunity_Wards))
						W3MsgSkillBlocked(i,_,"Wards");
					else
					{
						new DamageScreen[4];
						DamageScreen[0]=0;
						DamageScreen[1]=250;
						DamageScreen[2]=50;
						DamageScreen[3]=30;
						
						W3FlashScreen(i,DamageScreen);
						War3_DealDamage(i,WardDamage[wardradiusskill],owner,DMG_ENERGYBEAM,"wards",_,W3DMGTYPE_MAGIC);
						
						if(LastThunderClap[i]<GetGameTime()-2)
						{
							new Float:postionplayer[3];
							postionplayer[0]=start_pos[0];
							postionplayer[1]=start_pos[1];
							postionplayer[2]=start_pos[2]+20.0;
							EmitSoundToAll(wardDamageSound,i,SNDCHAN_WEAPON);
							LastThunderClap[i]=GetGameTime();
							new DamageScreen2[4];
							
							if(GetClientTeam(owner)==2)
								DamageScreen2={255,40,40,50};
							if(GetClientTeam(owner)==3)
								DamageScreen2={40,40,250,50};
								
							TE_SetupBeamRingPoint(postionplayer,150.0,WardDistance[wardradiusskill],BeamSprite,HaloSprite,0,15,2.0,5.0,0.0,DamageScreen2,10,0);
							TE_SendToAll(); 
						}	
					}
                }
            }
        }
    }
}

/* *************************************** (SKILL_DAMAGE) *************************************** */
ImpalerFX(attacker,victim) 
{
	new Float:apos[3];			GetClientAbsOrigin(attacker,apos);		apos[2]+=80;
	new Float:vpos[3];			GetClientAbsOrigin(victim,vpos);		vpos[2]+=35;
	new Float:vpos2[3];			GetClientAbsOrigin(victim,vpos2);		vpos2[2]+=35;
	
	TE_SetupBeamRingPoint(apos,20.0,15.0,BeamSprite,BeamSprite,0,28,5.0,52.0,1.0,{128,60,128,255},6,0);
	TE_SendToAll();
	TE_SetupBeamPoints(apos,vpos,LargeBeam,LargeBeam,0,100,3.0,35.0,10.0,0,2.0,{255,255,255,220},20);
	TE_SendToAll();
	new axis = GetRandomInt(0,1);
	vpos[axis] += 150;
	vpos2[axis] += 150;
	for(new i=0;i<30;i++)
	{
		TE_SetupBeamRingPoint(vpos,200.0,100.0,BeamSprite,BeamSprite,0,28,0.1,25.0,1.0,{128,60,128,255},6,0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vpos2,200.0,100.0,BeamSprite,BeamSprite,0,28,0.1,25.0,1.0,{128,60,128,255},6,0);
		TE_SendToAll();
		vpos[axis]-=5.0;
		vpos2[axis]-=5.0;
	}
	TE_SetupExplosion(vpos, BeamSprite, 2.0, 1, 4, 0, 0);
	TE_SendToAll(5.1); 
	EmitSoundToAll(DamageSound,victim);
}

public Action:StopSlow(Handle:timer, any:i)
{
	if(ValidPlayer(i)) 
	{
		W3ResetPlayerColor(i,thisRaceID);
		W3ResetBuffRace(i,fSlow,thisRaceID);
		W3ResetBuffRace(i,fAttackSpeed,thisRaceID);
	}
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(War3_GetRace(client)==thisRaceID)
	{
		gShotNumber=0;
    }
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new DamageLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_DAMAGE);
			if(DamageLevel>0 && SkillFilter(victim))
			{
				if(gShotNumber==0)
				{
					if(W3Chance(DamageChance))
					{
						W3FlashScreen(victim,{128,60,128,120},0.6,0.1);
						W3SetPlayerColor(victim,thisRaceID,128,60,128,_,GLOW_DEFAULT);
						War3_DealDamage(victim,HiderDamage[DamageLevel],attacker,DMG_BULLET,"impaled");
						War3_SetBuff(victim,fAttackSpeed,thisRaceID,AttackSlow[DamageLevel]);
						War3_SetBuff(victim,fSlow,thisRaceID,SpeedSlow[DamageLevel]);
						CreateTimer(DamageSlowTime[DamageLevel], StopSlow, victim);
						ImpalerFX(attacker,victim);
					}
				}
				gShotNumber++;
			}
		}
/* *************************************** (ULT_HIDE) *************************************** */
		else if(War3_GetRace(victim)==thisRaceID)
		{
			if(bHiding[victim])
			{
				if(bActiveForm[victim]==3 && UltFilter(attacker))  // Shrub Form
				{
					new Thorns = GetRandomInt(ThornsMin,ThornsMax);
					new iDamage = RoundToFloor(damage * Thorns);
					if(iDamage>0)
					{
						if(iDamage>40)
							iDamage=40;
						War3_DealDamage(attacker,iDamage,victim,DMG_CRUSH,"thorns aura",_,W3DMGTYPE_MAGIC);
						War3_EffectReturnDamage(victim, attacker, iDamage, ULT_HIDE);
					}
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_HIDE);
		if(ult_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_HIDE,true))
			{
				if(!bHiding[client])
				{
					GetClientModel(client,bPreModel[client],256);
					new Handle:menu = CreateMenu(SelectProp);
					SetMenuTitle(menu, "Select which prop you want to become");
					AddMenuItem(menu, "tree", "Tree");
					AddMenuItem(menu, "hostage", "Hostage");
					AddMenuItem(menu, "shrub", "Shrub");
					AddMenuItem(menu, "car", "Broken Car");
					AddMenuItem(menu, "rock", "Rock");
					AddMenuItem(menu, "lamp", "Lamp");
					AddMenuItem(menu, "barrel", "Barrel");
					SetMenuExitButton(menu, true);
					DisplayMenu(menu, client, 20);
				}
				else
				{
					War3_CooldownMGR(client,HideCooldown,thisRaceID,ULT_HIDE,_,_);
					SetEntityModel(client, bPreModel[client]);
					War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
					War3_SetBuff(client,bDisarm,thisRaceID,false);
					CreateTimer(1.0,GiveWep,client);
					bHiding[client]=false;
					bActiveForm[client]=0;
				}
			}
		}
	}
}


public SelectProp(Handle:menu, MenuAction:action, client, param2)
{
  if (action == MenuAction_Select)
    {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if(StrEqual(info,"tree"))
		{
			strcopy(gModel[client],128,TreeModel);
			bActiveForm[client]=1;
		}
		else if(StrEqual(info,"hostage"))
		{
			strcopy(gModel[client],128,HostageModel);
			bActiveForm[client]=2;
		}
		else if(StrEqual(info,"shrub"))
		{
			strcopy(gModel[client],128,ShrubModel);
			bActiveForm[client]=3;
		}
		else if(StrEqual(info,"car"))
		{
			strcopy(gModel[client],128,CarModel);
			bActiveForm[client]=4;
		}
		else if(StrEqual(info,"rock"))
		{
			strcopy(gModel[client],128,RockModel);
			bActiveForm[client]=5;
		}
		else if(StrEqual(info,"lamp"))
		{
			strcopy(gModel[client],128,LampModel);
			bActiveForm[client]=6;
		}
		else if(StrEqual(info,"barrel"))
		{
			strcopy(gModel[client],128,BarrelModel);
			bActiveForm[client]=7;
		}

		ChangeProp(client);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public ChangeProp(client)
{
	if(War3_GetRace(client)==thisRaceID && ValidPlayer(client,true))
	{
		SetEntityModel(client, gModel[client]);
		War3_SetBuff(client,bNoMoveMode,thisRaceID,true);
		War3_SetBuff(client,bDisarm,thisRaceID,true);
		EmitSoundToAll(HideSound,client);
		bHiding[client]=true;
		DropWeapon(client);
	}
}

public DropWeapon(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new m3 = GetPlayerWeaponSlot(client, 0);
		new p228 = GetPlayerWeaponSlot(client, 1);
		new knife = GetPlayerWeaponSlot(client, 2);
		if(IsValidEntity(m3))
        {
            RemovePlayerItem(client, m3);
            AcceptEntityInput(m3, "kill");
		}
		if(IsValidEntity(p228))
        {
            RemovePlayerItem(client, p228);
            AcceptEntityInput(p228, "kill");
		}
		if(IsValidEntity(knife))
        {
            RemovePlayerItem(client, knife);
            AcceptEntityInput(knife, "kill");
		}
	}
}

public Action:GiveWep(Handle:timer,any:client)
{
	if(War3_GetRace(client)==thisRaceID && ValidPlayer(client,true))
	{
		if(!Client_HasWeapon(client, "weapon_m3"))
			GivePlayerItem(client,"weapon_m3");
		if(!Client_HasWeapon(client, "weapon_p228"))
			GivePlayerItem(client,"weapon_p228");
		if(!Client_HasWeapon(client, "weapon_knife"))
			GivePlayerItem(client,"weapon_knife");
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			if(bHiding[victim])
			{
				if(bActiveForm[victim]==2) // Hostage Form
				{
					new xp = GetRandomInt(XPMin,XPMax);
					new race = War3_GetRace(attacker);
					War3_SetXP(attacker,race,War3_GetXP(attacker,race)+xp);
					War3_ChatMessage(attacker,"You received a bonux &i XP for killing a Barrel Hider",xp);
				}
				else if(bActiveForm[victim]==4) // Car Model
				{
					War3_SetBuff(attacker,fMaxSpeed,thisRaceID,SpeedIncrease);
					CreateTimer(15.0,StopSpeed,attacker);
					bInSpeed[attacker]=true;
				}
				else if(bActiveForm[victim]==6 && UltFilter(attacker))  // Lamp Model
				{
					W3FlashScreen(victim,RGBA_COLOR_WHITE,5.0,5.0);
				}
				else if(bActiveForm[victim]==7 && UltFilter(attacker))  // Barrel Model
				{
					decl Float:fVictimPos[3];		GetClientAbsOrigin(victim, fVictimPos);
					War3_SuicideBomber(victim, fVictimPos, 300.0, ULT_HIDE, 300.0);
				}
			}
		}
	}
}

public Action:StopSpeed(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bInSpeed[client])
	{
		W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID && bHiding[victim])
		{
			if(bActiveForm[victim]==5) // Rock Form
			{
				War3_DamageModPercent(RockDamageReduce);
			}
		}
	}
}

public Action:CalcHPRegen(Handle:timer,any:userid)
{
	for (new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			if(bHiding[client])
			{
				if(bActiveForm[client]==1)
					War3_SetBuff(client,fHPRegen,thisRaceID,HPRegenAmount);
				else
					War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
			}
			else
				War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
		}
	}
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && bInSpeed[i])
		{
			W3ResetBuffRace(i,fMaxSpeed,thisRaceID);
		}
	}
}