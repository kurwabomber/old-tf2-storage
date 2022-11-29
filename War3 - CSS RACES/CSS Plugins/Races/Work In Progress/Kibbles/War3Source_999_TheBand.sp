#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - The Band",
	author = "ABGar (edited by Kibbles)",
	description = "The Band race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_WEIGHT, SKILL_CARNIVAL, SKILL_DRIFTWOOD, ULT_PINES;

// SKILL_WEIGHT
new Float:InvisDuration=5.0;
new Float:WeightCD=20.0;
new bool:InInvis[MAXPLAYERSCUSTOM];
new Handle:InvisEndTimer[MAXPLAYERSCUSTOM];
new Handle:DisarmEndTimer[MAXPLAYERSCUSTOM];
new String:InvisOn[]="npc/scanner/scanner_nearmiss1.wav";
new String:InvisOff[]="npc/scanner/scanner_nearmiss2.wav";


// SKILL_CARNIVAL
new Float:WindSpeed[]={1.0,1.1,1.15,1.2,1.25,1.3};

// SKILL_DRIFTWOOD
new BeamSprite, BlueSprite, SmokeSprite;
new Float:DriftwoodCD=20.0;
new Float:DriftwoodRange[]={0.0,70.0,140.0,245.0,315.0,420.0};
new Float:DriftwoodTime[]={0.0,0.6,0.7,0.8,0.9,1.0};
new bool:bIceEffect[MAXPLAYERSCUSTOM];
new String:freezeSound[]="ambient/misc/metal2.wav";


// ULT_PINES
new m_vecBaseVelocity, TornadoSprite;
new TornadoDmg[]={0,10,20,25,30,40};
new bBeenHit[MAXPLAYERSCUSTOM];
new NadoCount[MAXPLAYERSCUSTOM];
new Float:SavedPos[MAXPLAYERSCUSTOM][3];
new Float:TornadoCD[]={0.0,45.0,40.0,35.0,25.0,20.0};
new String:TornadoSnd[]="war3source/roguewizard/Tornado.wav";

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("The Band [PRIVATE]","theband");
	SKILL_WEIGHT = War3_AddRaceSkill(thisRaceID,"The Weight (+ability)","Crazy Chester followed me and he caught me in the fog",false,1);
	SKILL_CARNIVAL = War3_AddRaceSkill(thisRaceID,"Life Is a Carnival","You can walk on the water and drown in the sand, You can fly off a mountaintop if anybody can, \nRun away, run away; it's the restless age. Look away, look away; you can turn the page",false,5);
	SKILL_DRIFTWOOD = War3_AddRaceSkill(thisRaceID,"Acadian Driftwood (+ability1)","Acadian driftwood, Gypsy tail wind. They call my home the land of snow, \nCanadian cold front moving' in, What a way to ride oh what a way to go",false,5);
	ULT_PINES=War3_AddRaceSkill(thisRaceID,"Whispering Pines (+ultimate)","Standing by the well, wishing for the rains \nReaching to the clouds, for nothing else remains",true,5);
    
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_WEIGHT,10.0,true);
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_DRIFTWOOD,10.0,true);
    W3SkillCooldownOnSpawn(thisRaceID,ULT_PINES,10.0,true);
    
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID, SKILL_CARNIVAL, fMaxSpeed, WindSpeed);
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
		if (ValidPlayer(client,true))
        {
			InitPassiveSkills(client);
		}
	}
	
}

public OnWar3EventSpawn(client)
{
    if(DisarmEndTimer[client] != INVALID_HANDLE)
    {
        CloseHandle(DisarmEndTimer[client]);
        DisarmEndTimer[client] = INVALID_HANDLE;
    }
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
    
    HookEvent("round_start", Event_RoundStart);//If you're using flags, you need to reset them when the round starts, or call an init method which is set up to account for things like weapons already existing. I've added that in.
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	BlueSprite=PrecacheModel("materials/sprites/physcannon_bluecore2b.vmt");
	SmokeSprite=PrecacheModel("materials/sprites/smoke.vmt");
	TornadoSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	
	War3_PrecacheSound(InvisOn);
	War3_PrecacheSound(InvisOff);
	War3_PrecacheSound(TornadoSnd);
	War3_PrecacheSound(freezeSound);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=0; i<MaxClients; i++)
    {
        if (ValidPlayer(i, true) && War3_GetRace(i)==thisRaceID)
        {
            InitPassiveSkills(i);
        }
    }
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_deagle,weapon_knife,weapon_hegrenade,weapon_smokegrenade,weapon_flashbang");
    CreateTimer(1.0, EquipDeagle, client);//When restricting weapons and equipping them, use a short timer or the restiction code clashes with the equip.
	InInvis[client]=false;
	W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
	War3_SetBuff(client,bDisarm,thisRaceID,false);
}
public Action:EquipDeagle(Handle:timer,any:client)
{
    if (!Client_HasWeapon(client, "weapon_deagle"))//Always check if they have the weapon before giving
    {
        Client_GiveWeapon(client, "weapon_deagle", true);
    }
}


/* *************************************** (SKILL_WEIGHT) *************************************** */
public Action:EndInvis(Handle:timer,any:client)
{
	W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
    DisarmEndTimer[client]=CreateTimer(1.0,EndDisarm,client);
	EmitSoundToAll(InvisOff,client);
	InInvis[client]=false;
}
public Action:EndDisarm(Handle:timer,any:client)//1 second delay after ending invis was requested :)
{
    War3_SetBuff(client,bDisarm,thisRaceID,false);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new WeightLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_WEIGHT);
		if(WeightLevel>0)	
		{
			if(InInvis[client])
				TriggerTimer(InvisEndTimer[client]); 
			else if(SkillAvailable(client,thisRaceID,SKILL_WEIGHT,true,true,true))
			{
                War3_CooldownMGR(client,WeightCD,thisRaceID,SKILL_WEIGHT,_,_);
				EmitSoundToAll(InvisOn,client);
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
				War3_SetBuff(client,bDisarm,thisRaceID,true);
				InvisEndTimer[client]=CreateTimer(InvisDuration,EndInvis,client);
				InInvis[client]=true;
			}
		}
		else
			PrintHintText(client,"Level your Skill first");
	}
/* *************************************** (SKILL_DRIFTWOOD) *************************************** */
	if( War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
	{
		new skilllevel = War3_GetSkillLevel(client,thisRaceID, SKILL_DRIFTWOOD);
		if(skilllevel>0 && !InInvis[client])
		{
			if(SkillAvailable(client,thisRaceID,SKILL_DRIFTWOOD,true,true,true))
			{
				SnowStorm(client);
				War3_CooldownMGR(client,DriftwoodCD,thisRaceID,SKILL_DRIFTWOOD,_,_);
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true))
					{
						new Float:ClientPos[3];
						new Float:OtherPos[3];
						GetClientAbsOrigin(client,ClientPos);
						GetClientAbsOrigin(i,OtherPos);
						if(GetVectorDistance(OtherPos,ClientPos)<=DriftwoodRange[skilllevel] && GetClientTeam(i)!=GetClientTeam(client) && ValidPlayer(i,true) && SkillFilter(i))
						{
							ClientCommand(i, "r_screenoverlay effects/rollerglow");
							OtherPos[2]+=50;
							TE_SetupGlowSprite(OtherPos, BlueSprite, 1.0, 1.0, 255);
							TE_SendToAll();
							bIceEffect[i]=true;
							War3_SetBuff(i,bBashed,thisRaceID,true);
							W3SetPlayerColor(i,thisRaceID,120,120,255,180,0);
							W3FlashScreen(i,RGBA_COLOR_BLUE,0.34,_,FFADE_IN);
							CreateTimer(0.35,Loop_IceEffects,i);
							CreateTimer(DriftwoodTime[skilllevel],Timer_RemoveIceEffect,i);
						}
					}
				}
			}
		}
	}
}

public Action:SnowStorm(const client)
{
	new particle = CreateEntityByName("env_smokestack");
	new skilllevel = War3_GetSkillLevel( client, thisRaceID, SKILL_DRIFTWOOD );
	if(IsValidEdict(particle) && IsClientInGame(client) && skilllevel>0)
	{
		decl String:Name[32], Float:fPos[3], Float:fAng[3] = {0.0,0.0,0.0};
		Format(Name,sizeof(Name),"Winter_%i",client);
		GetEntPropVector(client,Prop_Send,"m_vecOrigin",fPos);
		fPos[2] += 30;

		DispatchKeyValueVector(particle, "Origin", fPos);
		DispatchKeyValueVector(particle, "Angles", fAng);
		DispatchKeyValueFloat(particle, "BaseSpread", 450.0);
		DispatchKeyValueFloat(particle, "StartSize", 21.0);
		DispatchKeyValueFloat(particle, "EndSize", 11.0);
		DispatchKeyValueFloat(particle, "Twist", 80.0);
		
		DispatchKeyValue(particle, "Name", Name);
		DispatchKeyValue(particle, "SmokeMaterial", "particle/fire.vmt");
		DispatchKeyValue(particle, "RenderColor", "100 100 220");
		DispatchKeyValue(particle, "RenderAmt", "200");
		DispatchKeyValue(particle, "SpreadSpeed", "600");
		DispatchKeyValue(particle, "JetLength", "600");
		DispatchKeyValue(particle, "Speed", "200");
		DispatchKeyValue(particle, "Rate", "148");
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", client, particle, 0);
		AcceptEntityInput(particle, "TurnOn");
		new Float:OtherPos[3];
		GetClientAbsOrigin(client,OtherPos);
		OtherPos[2]+=40;
		TE_SetupBeamRingPoint(OtherPos, 10.0, 10+DriftwoodRange[skilllevel], BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {100,100,255,120}, 60, 0);
		TE_SendToAll();
		EmitSoundToAll(freezeSound, client);
		CreateTimer(5.0, Timer_StopTargetEntinty, particle);
		CreateTimer(6.0, Timer_RemoveTargetEntinty, particle);
	}
	else
	{
		LogError("[SM] Failed to create env_smokestack ent!");
	}
}

public Action:Timer_RemoveTargetEntinty(Handle:timer,any:ent)
{
	if(IsValidEdict(ent) && IsValidEntity(ent)) 
		AcceptEntityInput(ent, "Kill");
}

public Action:Timer_StopTargetEntinty( Handle:timer, any:ent )
{
	if(IsValidEdict(ent) && IsValidEntity(ent)) 
		AcceptEntityInput(ent,"TurnOff");
}

public Action:Timer_RemoveIceEffect(Handle:timer,any:i)
{
	if(ValidPlayer(i,false)) 
	{
		ClientCommand(i, "r_screenoverlay 0"); 
		bIceEffect[i]=false;
		new Float:OtherPos[3];
		GetClientAbsOrigin(i,OtherPos);
		OtherPos[2]+=38;
		TE_SetupBeamRingPoint(OtherPos,10.0,9999.0,BlueSprite,BlueSprite,2,6,1.5,100.0,7.0,{120,120,255,255},40,0);
		TE_SendToAll();
		War3_SetBuff(i,bBashed,thisRaceID,false);
		W3ResetPlayerColor(i,thisRaceID);
	}
}

public Action:Loop_IceEffects(Handle:timer,any:i)
{
	if(ValidPlayer(i,true))
	{
		if(bIceEffect[i]&&IsPlayerAlive(i))
		{
			PrintCenterText(i,"Acadian Driftwood has frozen you!");
			new Float:OtherPos[3];
			GetClientAbsOrigin(i,OtherPos);
			OtherPos[2]+=38;
			TE_SetupBeamRingPoint(OtherPos,10.0,20.0,SmokeSprite,SmokeSprite,2,6,0.42,100.0,7.0,{100,100,255,160},40,0);
			TE_SendToAll();
			W3FlashScreen(i,RGBA_COLOR_BLUE);
			CreateTimer( 0.35, Loop_IceEffects, i );
		}
	}
}


/* *************************************** (ULT_PINES) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client) && !InInvis[client])
	{
		new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_PINES);
		if(ult_level>0)
		{
			new Float:pos[3];
			new Float:lookpos[3];
			War3_GetAimEndPoint(client,lookpos);
			GetClientAbsOrigin(client,pos);
			pos[1]+=60.0;
			pos[2]+=60.0;
			TE_SetupBeamPoints(pos, lookpos, TornadoSprite,TornadoSprite, 0, 5, 0.5,15.0,19.0, 2, 10.0, {54,66,120,100}, 60); 
			TE_SendToAll();
			pos[1]-=120.0;
			TE_SetupBeamPoints(pos, lookpos, TornadoSprite,TornadoSprite, 0, 5, 0.5,15.0,19.0, 2, 10.0, {54,66,120,100}, 60);
			TE_SendToAll();
			new target = War3_GetTargetInViewCone(client,600.0,false,20.0);
			if(target>0 && UltFilter(target))
			{
				if(SkillAvailable(client,thisRaceID,ULT_PINES,true,true,true))
				{
					War3_CooldownMGR(client,TornadoCD[ult_level],thisRaceID,ULT_PINES,_,_);
					CreateTimer(0.1,nado0,target);
					EmitSoundToAll(TornadoSnd,client);
					EmitSoundToAll(TornadoSnd,target);
					War3_DealDamage(target,TornadoDmg[ult_level],client,DMG_GENERIC,"whispering pines");
					bBeenHit[target]=true;
					CreateTimer(0.25,newtarget,client);
					GetClientAbsOrigin(target,SavedPos[client]);
					NadoCount[client]=1;
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}


public Action:newtarget(Handle:timer,any:client)
{
	new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_PINES);
	if(NadoCount[client]<=2)
	{
		new Float:NewTargetPos[3];
		new Float:bestTargetDistance=1000.0; 
		new team = GetClientTeam(client);
		new bestTarget=0;

		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Skills)&&!bBeenHit[i])
			{
				GetClientAbsOrigin(i,NewTargetPos);
				new Float:dist=GetVectorDistance(SavedPos[client],NewTargetPos);
				if(dist<bestTargetDistance&&dist<300.0)
				{
					bestTarget=i;
					bestTargetDistance=dist;
				}
			}
		}
		if(bestTarget>0)
		{
			bBeenHit[bestTarget]=true;
			CreateTimer(0.1,nado0,bestTarget);
			GetClientAbsOrigin(bestTarget,SavedPos[client]);
			CreateTimer(0.25,newtarget,client);
			War3_DealDamage(bestTarget,TornadoDmg[ult_level],client,DMG_GENERIC,"whispering pines");
			new NewNadoCount = NadoCount[client]+1;
			NadoCount[client]=NewNadoCount;
		}
	}
}


public Action:nado0(Handle:timer,any:client)
{
	
	new Float:targpos[3];
	GetClientAbsOrigin(client,targpos);
	TE_SetupBeamRingPoint(targpos, 20.0, 80.0,TornadoSprite,TornadoSprite, 0, 5, 2.6, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
	TE_SendToAll();
	targpos[2]+=20.0;
	TE_SetupBeamRingPoint(targpos, 40.0, 100.0,TornadoSprite,TornadoSprite, 0, 5, 2.4, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
	TE_SendToAll();
	targpos[2]+=20.0;
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
	EmitSoundToAll(TornadoSnd,client);
	new Float:velocity[3];
	velocity[2]+=800.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
	CreateTimer(0.1,nado1,client);
	CreateTimer(0.4,nado2,client);
	CreateTimer(0.9,nado3,client);
	CreateTimer(1.4,nado4,client);
}

public Action:nado1(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[0]-=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}
public Action:nado2(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[1]-=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:nado3(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[0]+=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:nado4(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[1]+=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
	bBeenHit[client]=false;
}