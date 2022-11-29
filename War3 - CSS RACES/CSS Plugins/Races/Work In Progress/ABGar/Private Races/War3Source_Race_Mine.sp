#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include "W3SIncs/KibblesFunctions"

public Plugin:myinfo = 
{
	name = "War3Source Race - Mine",
	author = "ABGar",
	description = "The Mine race for War3Source.",
	version = "1.0",
	// Fubzy's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5489-mine-akame-ga-kill/
}

new thisRaceID;

new SKILL_PUMPKIN, SKILL_AMMO, SKILL_PRECISE, ULT_OVERLOAD;

// SKILL_PUMPKIN
new Clip1Offset;
new bool:bInPumpkin[MAXPLAYERSCUSTOM]={false, ...};
new Float:PumpkinCD[]={0.0,30.0,25.0,20.0,15.0};

// SKILL_AMMO
new AmmoAmount[]={0,8,6,4,2};

// SKILL_PRECISE
new ExlpSprite; 
new Float:CanExplodeTime[MAXPLAYERSCUSTOM];
new Float:PreciseCD[]={0.0,6.0,5.0,4.0,3.0,2.0};
new Float:ExplodeRadius[]={0.0,75.0,100.0,125.0,150.0};
new Float:ExplodeDamage[]={0.0,20.0,30.0,40.0,50.0};
new String:ExplodeSound[]="weapons/explode3.wav";

// ULT_OVERLOAD
new Counter;
new OverLoadDamage[]={0,10,15,20,25};
new Float:SlowAmount[]={0.0,0.95,0.9,0.85,0.8};
new Float:SlowDuration[]={0.0,1.0,2.0,3.0,4.0};
new Float:SmokeRange=150.0;
new Float:OverloadCD=30.0;
new Float:EndPos[10][3];
new bool:bHitByOverload[MAXPLAYERSCUSTOM]={false, ...};


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Mine [PRIVATE]","mine");
	SKILL_PUMPKIN = War3_AddRaceSkill(thisRaceID,"Pumpkin","The Imperial Arms Pumpkin can transform on the go! (+ability)",false,4);
	SKILL_AMMO = War3_AddRaceSkill(thisRaceID,"Emotional Ammo","The more danger Mine is in the more powerful Pumpkin becomes! (passive)",false,4);
	SKILL_PRECISE = War3_AddRaceSkill(thisRaceID,"Precise Spirit Energy","Pumpkin doesn't shoot regular bullets!",false,4);
	ULT_OVERLOAD=War3_AddRaceSkill(thisRaceID,"OVERLOAD","Pumpkin senses Mine's rage.. Fire one massive powerful blast of concentrated spirit energy!  (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_OVERLOAD,15.0,_);
}

public OnPluginStart()
{
	Clip1Offset = FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
	HookEvent("weapon_fire",Event_WeaponFire);
	HookEvent("bullet_impact",Event_BulletImpact);
	HookEvent("round_start", Event_RoundStart);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=0; i<MaxClients; i++)
	{
		if (ValidPlayer(i))
		{
			W3ResetAllBuffRace(i,thisRaceID);
			bHitByOverload[i]=false;
		}
	}
}

public OnMapStart()
{
	ExlpSprite=PrecacheModel("materials/sprites/zerogxplode.vmt");
	War3_PrecacheSound(ExplodeSound);
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
	DropWeapons(client);
	if(GetClientTeam(client)==TEAM_T)
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle,weapon_knife,weapon_ak47");
	else if(GetClientTeam(client)==TEAM_CT)
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle,weapon_knife,weapon_m4a1");
	CreateTimer(0.5,GivePrimary,client);
	CanExplodeTime[client]=GetGameTime()+1.0;	
}

public Action:GivePrimary(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		GivePlayerItem(client,"weapon_knife");
		GivePlayerItem(client,"weapon_deagle");
		
		if(GetClientTeam(client)==TEAM_T)
			GivePlayerItem(client,"weapon_ak47");
		else if(GetClientTeam(client)==TEAM_CT)
			GivePlayerItem(client,"weapon_m4a1");
	}
}

public DropWeapons(client)
{
	for(new iSlot=0;iSlot<=3;iSlot++)
	{
		new iWeapon = GetPlayerWeaponSlot(client, iSlot);  
		if(IsValidEntity(iWeapon))
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "kill");
		}
	}
}

/* *************************************** (SKILL_PUMPKIN) *************************************** */
public GiveGunMenu(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if(StrEqual(info,"para"))
		{
			DropWeapons(client);
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_m249");
			CreateTimer(0.5,GivePara,client);
			bInPumpkin[client]=true;
		}
		else if(StrEqual(info,"awp"))
		{
			DropWeapons(client);
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_awp");
			CreateTimer(0.5,GiveAwp,client);
			bInPumpkin[client]=true;
		}
	}
	else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Action:GivePara(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		if(!Client_HasWeapon(client,"weapon_m249"))
		{
			GivePlayerItem(client,"weapon_m249");
			Client_SetWeaponAmmo(client,"weapon_m249",0,0,100,0);
		}
	}
}

public Action:GiveAwp(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		if(!Client_HasWeapon(client,"weapon_awp"))
		{
			GivePlayerItem(client,"weapon_awp");
			Client_SetWeaponAmmo(client,"weapon_awp",0,0,10,0);
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && ability==0 && pressed)
	{
		new PumpkinLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_PUMPKIN);
		if(PumpkinLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_PUMPKIN,true,true,true))
			{
				if(bInPumpkin[client])
					PrintHintText(client,"You must use all the bullets in your pumpkin before you can create another one");
				else
				{
					new Handle:menu = CreateMenu(GiveGunMenu);
					SetMenuTitle(menu, "Select which pumpkin you want");
					AddMenuItem(menu, "para", "Para");
					AddMenuItem(menu, "awp", "Awp");
					SetMenuExitButton(menu, true);
					DisplayMenu(menu, client, 20);
				}
			}
		}
		else
			PrintHintText(client,"Level your skill first");
	}
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if (War3_GetRace(client)==thisRaceID)
	{
		if (bInPumpkin[client])
			return Plugin_Handled;	
	}
	return Plugin_Continue;
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(War3_GetRace(client)==thisRaceID && bInPumpkin[client])
	{
		new String:weapon[32]; 
		GetClientWeapon(client,weapon,32);
		if(StrEqual(weapon,"weapon_m249") || StrEqual(weapon,"weapon_awp"))
		{
			new wep_ent = W3GetCurrentWeaponEnt(client);
			if(GetEntData(wep_ent,Clip1Offset,4)==1)
			{
				new PumpkinLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_PUMPKIN);
				War3_CooldownMGR(client,PumpkinCD[PumpkinLevel],thisRaceID,SKILL_PUMPKIN,true,true);
				bInPumpkin[client]=false;
				DropWeapons(client);
				if(GetClientTeam(client)==TEAM_T)
					War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle,weapon_knife,weapon_ak47");
				else if(GetClientTeam(client)==TEAM_CT)
					War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle,weapon_knife,weapon_m4a1");
				CreateTimer(1.0,GivePrimary,client);
			}
		}
    }
}

/* *************************************** (SKILL_AMMO) *************************************** */
public OnGameFrame()
{
    for(new client=1; client<=MaxClients; client++)
    {
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			new AmmoLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_AMMO);
			if(AmmoLevel>0)
			{
				new iDmgAdjust = (100-GetClientHealth(client))/AmmoAmount[AmmoLevel];
				if(iDmgAdjust < 0) 
					iDmgAdjust = 0;
				new Float:fDmgAdjust = float(iDmgAdjust)*0.5 / 100; 
				War3_SetBuff(client,fDamageModifier,thisRaceID,fDmgAdjust);
			}
		}
    }
}

/* *************************************** (SKILL_PRECISE) *************************************** */
public Event_BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		new PreciseLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_PRECISE);
		if(PreciseLevel>0 && CanExplodeTime[client]<GetGameTime())
		{
			new Float:Origin[3];
			Origin[0] = GetEventFloat(event,"x");
			Origin[1] = GetEventFloat(event,"y");
			Origin[2] = GetEventFloat(event,"z");
			CanExplodeTime[client]=GetGameTime()+PreciseCD[PreciseLevel];
			EmitSoundToAll(ExplodeSound,client);
			TE_SetupExplosion(Origin, ExlpSprite, 10.0, 10, TE_EXPLFLAG_NONE, 60, 160);
			TE_SendToAll();
			for (new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client))
				{
					new Float:VictimPos[3];		GetClientAbsOrigin(i,VictimPos);
					new Float:Distance=GetVectorDistance(Origin,VictimPos);
					new Float:Radius = ExplodeRadius[PreciseLevel];
					if(Distance<=Radius)
					{
						new Float:Factor=(Radius-Distance)/Radius;
						new DamageAmt=RoundFloat(ExplodeDamage[PreciseLevel]*Factor);
						War3_DealDamage(i,DamageAmt,client,DMG_BLAST,"precise spirit energy",_,W3DMGTYPE_MAGIC);
						War3_ShakeScreen(i,2.0*Factor,250.0*Factor,30.0);
						W3FlashScreen(i,RGBA_COLOR_RED);
					}
				}
			}
		}
	}
}

/* *************************************** (ULT_OVERLOAD) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new OverloadLevel=War3_GetSkillLevel(client,thisRaceID,ULT_OVERLOAD);
		if(OverloadLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_OVERLOAD,true,true,true))
			{
				War3_CooldownMGR(client,OverloadCD,thisRaceID,ULT_OVERLOAD,true,true);
				
				new Float:angle[3];				GetClientAbsAngles(client,angle);
				new Float:startpos[3];			GetClientEyePosition(client,startpos);
				new Float:endpos[3];
				new Float:MainDirection[3];		// Angle of the client on initial use of ultimate
				new Float:VertexGap=100.0;		// Distance in units between each env_smokestack that will be created
				GetAngleVectors(angle, MainDirection, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(MainDirection, VertexGap);
				AddVectors(startpos, MainDirection, endpos);
				
				for (new x=0;x<10;x++)
				{
					EndPos[x][0]=endpos[0];
					EndPos[x][1]=endpos[1];
					EndPos[x][2]=endpos[2];
					AddVectors(endpos, MainDirection, endpos);
				}
			
				Counter=1;
				CreateEnvSmokeStack(client,EndPos[1]);
			
				new Float:SmokeTimeDelay=0.2;
				for (new y=1;y<10;y++)
				{
					CreateTimer(SmokeTimeDelay,SmokeTimer,client);
					SmokeTimeDelay+=0.2;
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:SmokeTimer(Handle:timer,any:client)
{
	CreateEnvSmokeStack(client,EndPos[Counter]);
	Counter++;
}

CreateEnvSmokeStack(client,Float:SmokePos[3])
{
	new OverloadLevel=War3_GetSkillLevel(client,thisRaceID,ULT_OVERLOAD);
	new SmokeEnt = CreateEntityByName("env_smokestack");
	if(IsValidEdict(SmokeEnt) && IsClientInGame(client))
	{
		new String:originData[64];
		Format(originData, sizeof(originData), "%f %f %f", SmokePos[0], SmokePos[1], SmokePos[2]);
		new String:SName[128];
		Format(SName, sizeof(SName), "Smoke%i", Counter);
		DispatchKeyValue(SmokeEnt,"targetname", SName);
		DispatchKeyValue(SmokeEnt,"Origin", originData);
		DispatchKeyValue(SmokeEnt,"BaseSpread", "50");
		DispatchKeyValue(SmokeEnt,"SpreadSpeed", "50");
		DispatchKeyValue(SmokeEnt,"Speed", "50");
		DispatchKeyValue(SmokeEnt,"StartSize", "50");
		DispatchKeyValue(SmokeEnt,"EndSize", "50");
		DispatchKeyValue(SmokeEnt,"Rate", "30");
		DispatchKeyValue(SmokeEnt,"JetLength", "10");
		DispatchKeyValue(SmokeEnt,"Twist", "10"); 
		DispatchKeyValue(SmokeEnt,"RenderColor", "255 255 51");
		DispatchKeyValue(SmokeEnt,"RenderAmt", "255");
		DispatchKeyValue(SmokeEnt,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
		DispatchSpawn(SmokeEnt);
		AcceptEntityInput(SmokeEnt, "TurnOn");
		
		CreateTimer(0.3,StopSmoke,SmokeEnt);
		
		for (new enemy=1;enemy<=MaxClients;enemy++)
		{
			if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=GetClientTeam(client) && !bHitByOverload[enemy] && UltFilter(enemy))
			{
				new Float:enemyPos[3];		GetClientAbsOrigin(enemy,enemyPos);
				if(GetVectorDistance(SmokePos,enemyPos)<=SmokeRange)
				{
					War3_DealDamage(enemy,OverLoadDamage[OverloadLevel],client,DMG_CRUSH,"overload",_,W3DMGTYPE_MAGIC);
					War3_SetBuff(enemy,fSlow,thisRaceID,SlowAmount[OverloadLevel]);
					CreateTimer(SlowDuration[OverloadLevel],StopSlow,enemy);
					W3SetPlayerColor(enemy,thisRaceID,255,255,51,255);
					bHitByOverload[enemy]=true;
				}
			}
		}
	}
}

public Action:StopSmoke(Handle:timer, any:Entity)
{
	if(IsValidEdict(Entity))
	{
		AcceptEntityInput(Entity, "Kill");
	}
}

public Action:StopSlow(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bHitByOverload[client])
	{
		bHitByOverload[client]=false;
		W3ResetBuffRace(client,fSlow,thisRaceID);
		W3ResetPlayerColor(client,thisRaceID);
	}
}