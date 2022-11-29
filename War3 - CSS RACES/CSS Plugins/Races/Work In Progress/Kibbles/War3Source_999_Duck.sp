#pragma semicolon 1
 
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Duck",
	author = "ABGar (edits by Kibbles)",
	description = "The Duck race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_FEATHERS, SKILL_QUACK, SKILL_CYCLONE, SKILL_IMADUCK;//SKILL_NAME convention

// SKILL_FEATHERS
new Float:FeathersChance[]={0.0,0.25,0.5,0.75,1.0};

// SKILL_QUACK
new Float:QuackSpeed[]={1.0,1.05,1.1,1.15,1.2};

// SKILL_CYCLONE
new m_vecBaseVelocity;
new Float:CycloneChance[]={0.0,0.2,0.25,0.3,0.35,0.4,0.45,0.5};
new ShieldSprite,TornadoSprite;
new String:Tornado[]="HL1/ambience/des_wind2.wav";
new Float:CycloneVec[]={0.0,390.0,400.0,410.0,420.0,430.0,440.0,450.0};

// SKILL_IMADUCK
new String:crow[]="npc/crow/alert3.wav";
new bool:bFlying[MAXPLAYERSCUSTOM];


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Duck [PRIVATE]","duck");
	SKILL_FEATHERS = War3_AddRaceSkill(thisRaceID,"Feathers Of Steel","Being a duck makes you stronger (passive)\n25,50,75,100% chance for Skill Immunity",false,4);
	SKILL_QUACK = War3_AddRaceSkill(thisRaceID,"Quacktastic","Duck Feet (passive)\n+5,10,15,20% speed",false,4);
	SKILL_CYCLONE = War3_AddRaceSkill(thisRaceID,"Cyclone","Duck Cry (attack)\nLift your enemy in a tornado (20,30,40,50% chance)",false,7);
	SKILL_IMADUCK=War3_AddRaceSkill(thisRaceID,"Ima Duck","The Duck shall be feared (+ultimate)\nYou transform into a Duck",false,1);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID, SKILL_QUACK, fMaxSpeed, QuackSpeed);
}


public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");//You forgot this!
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
        bFlying[client]=false;//Reset all flags on race change
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
    War3_SetBuff(client,bBashed,thisRaceID,false);//Best to plan for the worst cases (i.e. unbash timer not triggering)
    War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    if (!Client_HasWeapon(client, "weapon_knife"))//just in case :)
    {
        Client_GiveWeapon(client, "weapon_knife", false);
    }
	bFlying[client]=false;
	War3_SetBuff(client,bFlyMode,thisRaceID,false);
	new FeathersLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_FEATHERS);
	if(FeathersLevel>0)
	{
		if(W3Chance(FeathersChance[FeathersLevel]))
		{
			War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
			PrintToChat(client,"\x04 SKILL_FEATHERS OF STEEL:\x03 You have Skill Immunity this round");
		}
	}
	
}

public OnMapStart()
{
	ShieldSprite=PrecacheModel("sprites/strider_blackball.vmt");
	TornadoSprite=PrecacheModel("sprites/lgtning.vmt");
	PrecacheModel("models/crow.mdl", true);
	War3_PrecacheSound(Tornado);
	War3_PrecacheSound(crow);
}

/* *************************************** (SKILL_CYCLONE) *************************************** */
public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			new skill_level_cyclone=War3_GetSkillLevel(attacker,thisRaceID,SKILL_CYCLONE);
			if(race_victim==thisRaceID&&bFlying[victim])
			{
				EmitSoundToAll(crow,victim);
			}
			if(race_attacker==thisRaceID && skill_level_cyclone>0)
			{
				if(W3Chance(CycloneChance[skill_level_cyclone]) && !W3HasImmunity(victim,Immunity_Skills)&&!Hexed(attacker))//use hex, not silence. Hex is for passives, silence is for activatables
				{
					new Float:targpos[3];
					GetClientAbsOrigin(victim,targpos);
					TE_SetupBeamRingPoint(targpos, 20.0, 80.0,TornadoSprite,TornadoSprite, 0, 5, 2.6, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
					TE_SendToAll();
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 40.0, 100.0,TornadoSprite,TornadoSprite, 0, 5, 2.4, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
					TE_SendToAll();
					targpos[2]+=20.0;
					TE_SetupGlowSprite(targpos, ShieldSprite, 1.0, 1.0, 130);
					TE_SendToAll(); 
					TE_SetupBeamRingPoint(targpos, 60.0, 120.0,TornadoSprite,TornadoSprite, 0, 5, 2.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 80.0, 140.0,TornadoSprite,TornadoSprite, 0, 5, 2.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();	
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 100.0, 160.0,TornadoSprite,TornadoSprite, 0, 5, 1.8, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();	
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 120.0, 180.0,TornadoSprite,TornadoSprite, 0, 5, 1.6, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();	
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 140.0, 200.0,TornadoSprite,TornadoSprite, 0, 5, 1.4, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();	
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 160.0, 220.0,TornadoSprite,TornadoSprite, 0, 5, 1.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();	
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 180.0, 240.0,TornadoSprite,TornadoSprite, 0, 5, 1.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();
					EmitSoundToAll(Tornado,attacker);

					new Float:velocity[3];
					velocity[2]=CycloneVec[skill_level_cyclone];
					SetEntDataVector(victim,m_vecBaseVelocity,velocity,true);
					PrintToConsole(attacker,"Cyclone");
					PrintToConsole(victim,"Cyclone");
					W3FlashScreen(victim,RGBA_COLOR_WHITE,1.0,1.0);
					War3_SetBuff(victim,bBashed,thisRaceID,true);
					CreateTimer(1.0,unbash,victim);
				}
			}
		}
	}
}

public Action:unbash(Handle:h, any:client)
{
    if (ValidPlayer(client))//Always check validity in timers. Something could bug out :)
    {
        War3_SetBuff(client,bBashed,thisRaceID,false);
    }
}

/* *************************************** (SKILL_IMADUCK) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,SKILL_IMADUCK);
		if(ult_level>0)		
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_IMADUCK,true)) 
			{
				if(!Silenced(client))
				{
					if(!bFlying[client])
					{
						bFlying[client]=true;
						War3_SetBuff(client,bFlyMode,thisRaceID,true);
						PrintHintText(client,"Im a Duck!");
						SetEntityModel(client, "models/crow.mdl");
						EmitSoundToAll(crow,client);
						new iWeapon = GetPlayerWeaponSlot(client, 2);  
						if(IsValidEntity(iWeapon))
						{
							RemovePlayerItem(client, iWeapon);
							AcceptEntityInput(iWeapon, "kill");
						}
						War3_WeaponRestrictTo(client,thisRaceID,"Im a Duck");
					}
					else
					{
						CreateTimer(0.1,returnform,client);
					}
					War3_CooldownMGR(client,1.5,thisRaceID,SKILL_IMADUCK,_,false);
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:returnform(Handle:h, any:client)
{
	if(ValidPlayer(client,true) && bFlying[client])//Don't forget to check if they're flying. If they're respawned as a different class right after dying this could bug out :)
	{
		bFlying[client]=false;
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		PrintHintText(client,"Normal Form!");
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
        if (!Client_HasWeapon(client, "weapon_knife"))//just in case :)
        {
            Client_GiveWeapon(client, "weapon_knife", false);
        }
		if(GetClientTeam(client)==TEAM_CT)//use defines when they're available
		{
			SetEntityModel(client, "models/player/ct_urban.mdl");
		}
		if(GetClientTeam(client)==TEAM_T)//use defines when they're available
		{
			SetEntityModel(client, "models/player/t_leet.mdl");
		}
	}
}