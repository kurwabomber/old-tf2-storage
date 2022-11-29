#include <sourcemod>
#include <sdktools>
#include <sdktools_stocks>
#include <sdktools_functions>
#include "W3SIncs/War3Source_Interface"
//new cl_flags;

new thisRaceID
new S_1, S_2, S_3, S_4, U_1;
new BeamSprite, Plague, BlueCore, Smoke;
new m_vecBaseVelocity;
new Float:CrazyDuration[5]={0.0,6.0,8.0,9.0,10.0};
new Float:CrazyUntil[MAXPLAYERS];
new bool:bCrazyDot[MAXPLAYERS];
new bool:bIceEffect[MAXPLAYERS];
new bool:bNecro[MAXPLAYERS];
new bool:bFury[MAXPLAYERS];
new CrazyBy[MAXPLAYERS];
new Float:Reaper[5]={1.0,1.1,1.2,1.3,1.4};
new Float:HarvestChance[5]={0.0,0.10,0.23,0.28,0.36};
new Float:WinterRange[5]={0.0,250.0,300.0,350.0,400.0};
new Float:WinterTime[5]={0.0,3.0,3.5,4.0,4.5};
new Float:Range[5]={0.0,350.0,400.0,450.0,500.0};
new Damage[5]={0,35,45,50,60};
new bHasWindfury[MAXPLAYERS];
new String:reviveSound[]="war3source/reincarnation.wav";
new String:freezeSound[]="ambient/materials/metal4.wav";
new String:furySound[]="weapons/hegrenade/explode4.wav";

//new MyWeaponsOffset,AmmoOffset;

/*harvest soul
new Float:MaxRevivalChance[MAXPLAYERS]; //chance for first attempt at revival
new Float:CurrentRevivalChance[MAXPLAYERS]; //decays by half per revival attempt, will stay at minimum of 10% after decays
new Float:RevivalChancesArr[]={0.00,0.25,0.50,0.75,1.00};
new RevivedBy[MAXPLAYERS];
new bool:bRevived[MAXPLAYERS];
new Float:fLastRevive[MAXPLAYERS];*/

public Plugin:myinfo = 
{
	name = "War3Source Race - Lich King",
	author = "Revan",
	description = "Arthas - The Lich king race for war3source.",
	version = "1.0.1",
	url = "www.wcs-lagerhaus.de"
}

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	//m_vecVelocity = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[2]" );
	CreateTimer(2.0,NecroticPlague,_,TIMER_REPEAT);
	PrintToServer("[WAR3] Loaded : Lich King");
	//MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
	//AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
}
/*
Necrotic Plague (passiv) - Infiziert das Ziel mit einer tödlichen Seuche die 10 Sekunden lang alle 2 Sekunden 4 Schaden verursacht springt falls nach ablauf der 10 Sekunden noch andere Feinde in der Nähe sind auf eines dieser über. (Radius musst du festlegen)
Soul Reaper (passiv) - Der Waffenschaden wird um 8% erhöhrt und es besteht eine chance von 20% das für 5 Sekunden die Schussgeschwindigkeit um 100% erhöht wird.
Fury of Frostmourne (ultimate) - Fügt allen Feinden in einem bestimmten Umkries (musst du festlegen) 50 Schaden zu.
Harvest Soul (passiv) - Es besteht eine chance von 15%, das nach dem Tod eines gegnerischen Spielers einer aus dem eigenen team wiederbelebt wird.
Remorseless Winter (ability) - Erzeugt einen gewaltigen Schneesturm der alle Gegner die sich darin befinden zu Eis erstarren lässt. (Sie werden festgefrohren, ziehen automatisch das Messer und während des effektes sind sie unantastbar, erst nach erlischen sind sie wieder angreifbar) (ähnlich Chronos Ultimate). Hält ausgeskilled 5 Sekunden an. (1/2/3/4/5 Sekunden)
[Rasse hat 25 Levels.]
*/

public OnWar3EventSpawn( client )
{
	if( ValidPlayer( client, true ) )
	{
		ClientCommand(client, "r_screenoverlay 0"); 
	}
	bHasWindfury[client] = false;
	bCrazyDot[client]=false;
	bFury[client]=false;
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	Plague=PrecacheModel("materials/sprites/vortring1.vmt");
	BlueCore=PrecacheModel("materials/sprites/physcannon_bluecore2b.vmt");
	Smoke=PrecacheModel("materials/sprites/smoke.vmt");
	PrecacheModel("materials/particle/fire.vmt");
	War3_PrecacheSound(reviveSound);
	War3_PrecacheSound(freezeSound);
	War3_PrecacheSound(furySound);
}

public OnWar3PluginReady()
{
	
		thisRaceID = War3_CreateNewRace( "Arthas - The Lich King", "arthaslich" );
		S_1 = War3_AddRaceSkill( thisRaceID, "Necrotic Plague", "Infect your target with a deadly plague every 2 seconds your target will recvive 4 damage\nthis spell will remain for some seconds on your target\nafter this duration the plague will jump to a close player(if someone is in a valid range)", false, 4 );	
		S_2 = War3_AddRaceSkill( thisRaceID, "Soul Reaper", "Raises your Weapondamage and you have a 20% chance to raise your shooting speed for 5 seconds", false, 4 );	
		S_3 = War3_AddRaceSkill( thisRaceID, "Harvest Soul", "There is a chance of 10%->36% to ressurect a dead teammate if you kill an enemy player", false, 4 );
		S_4 = War3_AddRaceSkill( thisRaceID, "Remorseless Winter", "Creates Cold snow flakes surrounding you to turn target enemyes into ice for 1-5 seconds(ability)", false, 4 )
		U_1 = War3_AddRaceSkill( thisRaceID, "Fury of Frostmourne", "Hurls the Frostmourne into the ground, to deal damage to close enemyes!", true, 4 );
		War3_CreateRaceEnd( thisRaceID );
	
}

/*public OnWar3EventSpawn( client )
{
	if( ValidPlayer( client, true ) )
	{
		new race = War3_GetRace( client );
		if( race == thisRaceID )
		{
			War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
			oldGrav[client] = 1.0;
		}
		RemoveWards( client );
		bSavedPos[client] = false;
		bNecro[client] = false;
	}
}*/

public Action:NecroticPlague( Handle:timer, any:uid )
{
	new attacker;
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)){
			if(bCrazyDot[i]){
				attacker=CrazyBy[i];
				if(ValidPlayer(attacker)){
					War3_DealDamage(i,4,attacker,_,"Necrotic Plague");
				}
				/*if(GetGameTime()>CrazyUntil[i]){
					bCrazyDot[i]=false;
					new Float:VictimPos[3];
					GetClientAbsOrigin(i,VictimPos);
					VictimPos[2]+=36.0;
					TE_SetupBeamRingPoint(VictimPos,10.0,395.0,BeamSprite,BeamSprite,2,6,1.295,60.0,7.0,{120,255,120,255},40,0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(VictimPos,10.0,395.0,BeamSprite,BeamSprite,2,6,0.20,60.0,7.0,{120,255,120,255},40,0);
					TE_SendToAll(0.45);
					VictimPos[2]-=36.0;
					for(new t=1;t<=MaxClients;t++)
					{
						if(ValidPlayer(t,true))
						{
							new Float:OtherPos[3];
							GetClientAbsOrigin(t,OtherPos);
							if(GetVectorDistance(OtherPos,VictimPos) < 380&&GetClientTeam(t)==GetClientTeam(i)&&IsPlayerAlive(t)&&IsPlayerAlive(i))
							{
								new skilllevel=War3_GetSkillLevel(attacker,thisRaceID,S_1);
								if(skilllevel>0){
									bCrazyDot[t]=true;
									CrazyBy[t]=attacker;
									CrazyUntil[t]=GetGameTime()+CrazyDuration[skilllevel];
								OtherPos[2]+=50;
								TE_SetupGlowSprite(OtherPos, Plague, 1.28, 1.28, 255);
								TE_SendToAll();
								}
							}
						}
					}
				}*/
			}
		}
	}
}

public Action:Timer_Buff(Handle:timer,any:i)
{
	bCrazyDot[i]=false;
	PrintHintText(i,"Necrotic Plague disappears!");
}

public Action:Timer_ExecutePlagueBuff(Handle:timer,any:i)
{
	bCrazyDot[i]=false;
	for(new t=1;t<=MaxClients;t++)
	{
		if(ValidPlayer(t,true))
		{
			new Float:VictimPos[3];
			new Float:OtherPos[3];
			GetClientAbsOrigin(i,VictimPos);
			GetClientAbsOrigin(t,OtherPos);
			VictimPos[2]+=36.0;
			TE_SetupBeamRingPoint(VictimPos,10.0,395.0,BeamSprite,BeamSprite,2,6,1.295,60.0,7.0,{120,255,120,255},40,0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(VictimPos,10.0,395.0,BeamSprite,BeamSprite,2,6,0.20,60.0,7.0,{120,255,120,255},40,0);
			TE_SendToAll(0.45);
			VictimPos[2]-=36.0;
			new attacker=CrazyBy[i];
			if(bNecro[i]&&GetVectorDistance(OtherPos,VictimPos) < 380&&GetClientTeam(t)!=GetClientTeam(attacker)&&GetClientTeam(t)==GetClientTeam(i)&&IsPlayerAlive(t)&&IsPlayerAlive(i))
			{
				new skilllevel=War3_GetSkillLevel(attacker,thisRaceID,S_1);
				if(skilllevel>0){
					bCrazyDot[t]=true;
					CrazyBy[t]=attacker;
					CrazyUntil[t]=GetGameTime()+CrazyDuration[skilllevel];
					War3_ChatMessage(t,"You're infected with a Necrotic Plague!");
					CreateTimer(11.0,Timer_Buff,t);
					OtherPos[2]+=50;
					TE_SetupGlowSprite(OtherPos, Plague, 1.28, 1.28, 255);
					TE_SendToAll();
				}
			}
		}
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
	if(bIceEffect[victim]){
		new wpnent = W3GetCurrentWeaponEnt(attacker);
		if(wpnent>0&&IsValidEdict(wpnent)){
			decl String:WeaponName[32];
			GetEdictClassname(wpnent, WeaponName, 32);
			if(StrContains(WeaponName,"weapon_knife",false)<0&&!W3IsDamageFromMelee(WeaponName)){
				War3_DamageModPercent(0.0);
				PrintCenterText(attacker,"You can only damage your enemy with melee weapons!");
				new Float:OtherPos[3];
				GetClientAbsOrigin(victim,OtherPos);
				OtherPos[2]+=38;
				TE_SetupBeamRingPoint(OtherPos,10.0,9999.0,BeamSprite,BeamSprite,2,6,1.0,18.0,7.0,{120,255,120,255},40,0);
				TE_SendToAll();
			}
		}
	}
	if(ValidPlayer(victim)&&ValidPlayer(attacker)&&victim!=attacker&&GetClientTeam(victim)!=GetClientTeam(attacker)&&!W3HasImmunity(victim,Immunity_Skills)){
		if(War3_GetRace(attacker)==thisRaceID&&!Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=0.28){
			new skilllevel=War3_GetSkillLevel(attacker,thisRaceID,S_1);
			if(skilllevel>0){
				bCrazyDot[victim]=true;
				bNecro[victim]=true;
				CrazyBy[victim]=attacker;
				CrazyUntil[victim]=GetGameTime()+CrazyDuration[skilllevel];
				CreateTimer(CrazyDuration[skilllevel],Timer_ExecutePlagueBuff,victim);
				CreateTimer(11.0,Timer_Buff,victim);
				new Float:iVec[3];
				new Float:iVec2[3]
				GetClientAbsOrigin(attacker, Float:iVec); 
				GetClientAbsOrigin(victim, Float:iVec2);
				iVec[2]+=35.0, iVec2[2]+=40.0;
				TE_SetupBeamPoints(iVec, iVec2, Plague, Plague, 0, 200, 1.5, 28.0, 16.0, 0, 0.5, {20,255,15,255}, 30);
				TE_SendToAll();
			}
		}
	}
	if(War3_GetRace(attacker)==thisRaceID&&!Hexed(attacker,false)){
		new skilllevel2=War3_GetSkillLevel(attacker,thisRaceID,S_2);
		if(skilllevel2>0){
			War3_DamageModPercent(Reaper[skilllevel2]);
			new Float:spos[3];
			new Float:epos[3];
			GetClientAbsOrigin(victim,epos);
			GetClientAbsOrigin(attacker,spos);
			epos[2]+=35;
			spos[2]+=50;
			TE_SetupBeamPoints(spos, epos, BeamSprite, BeamSprite, 0, 35, 1.0, 10.0, 10.0, 0, 10.0, {210,210,255,255}, 30);
			TE_SendToAll();
			spos[2]-=25;
			epos[2]-=10;
			TE_SetupBeamPoints(spos, epos, BeamSprite, BeamSprite, 0, 35, 1.0, 10.0, 10.0, 0, 10.0, {210,210,255,255}, 30);
			TE_SendToAll();
			if( GetRandomFloat(0.0,1.0)<=0.20&&!bHasWindfury[attacker])
			{
				bHasWindfury[attacker]=true;
				War3_SetBuff(attacker,fAttackSpeed,thisRaceID,1.45);
				PrintHintText(attacker,"Soul Reaper : Raised attack speed for 5 Seconds");
				PrintToConsole(attacker,"[WAR3] Skill used : Soul Reaper");
				CreateTimer(5.0,Timer_RemoveSoulReaperBuff,attacker);
				spos[2]+=55;
				TE_SetupGlowSprite(spos, BeamSprite, 1.0, 3.5, 255);
				TE_SendToAll();
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker){
	if(ValidPlayer(attacker,false)){
	/*for(new i=1;i<=MaxClients;i++)
	{
		if(i!=attacker&&ValidPlayer(i,false)&&GetClientTeam(i)==GetClientTeam(attacker)&&War3_GetRace(attacker)==thisRaceID)
		{
			new skillevel=War3_GetSkillLevel(attacker,thisRaceID,S_3);
			if(skillevel>0&&!Hexed(attacker,false))
			{
				CurrentRevivalChance[attacker]/=2.0;
				if(CurrentRevivalChance[attacker]<0.025*skillevel){
					CurrentRevivalChance[attacker]=0.025*skillevel;
				}
				RevivedBy[i]=i;
				bRevived[i]=true;
				CreateTimer(0.25,DoRevival,i);
				break;
			}
		}
	}*/
	if(War3_GetRace(attacker)==thisRaceID){
		new skill=War3_GetSkillLevel(attacker,thisRaceID,S_3);
		if(skill>0&&!Hexed(attacker,false)){
			PrintToConsole(attacker,"[harvest soul]found target");
			new Float:chance=HarvestChance[skill];
			EmitSoundToAll(reviveSound,attacker);
			if( GetRandomFloat(0.0,1.0)<=chance )
			{
				for(new i=1;i<=MaxClients;i++)
				{
					if(i!=attacker&&GetClientTeam(i)==GetClientTeam(attacker))
					{
						PrintToConsole(attacker,"[harvest soul]found target");
						if(skill>0&&!IsPlayerAlive(i))
						{
							//PrintToConsole(attacker,"[Revan] revived for schleife ergebnis - %i\nrespawn executed?", i);
							War3_SpawnPlayer(i);
							EmitSoundToAll(reviveSound,i);
							PrintToChat(i,"Artha's Harvest Soul revived you!");
							new Float:spos[3];
							GetClientAbsOrigin(attacker,spos);
							spos[2]+=40;
							TE_SetupBeamRingPoint(spos, 10.0, 200.0, BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {255,255,255,120}, 60, 0);
							TE_SendToAll();
							spos[2]-=10;
							TE_SetupBeamRingPoint(spos, 10.0, 200.0, BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {255,255,255,120}, 60, 0);
							TE_SendToAll(0.35);
							spos[2]-=10;
							TE_SetupBeamRingPoint(spos, 10.0, 200.0, BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {255,255,255,120}, 60, 0);
							TE_SendToAll(0.65);
							spos[2]-=10;
							TE_SetupBeamRingPoint(spos, 10.0, 200.0, BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {255,255,255,120}, 60, 0);
							TE_SendToAll(0.95);
							break;
						}
					}
				}
			}
		}
	}
	}
}

public Action:Timer_RemoveSoulReaperBuff(Handle:timer,any:client)
{
	bHasWindfury[client]=false;
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
	new Float:OtherPos[3];
	GetClientAbsOrigin(client,OtherPos);
	OtherPos[2]+=38;
	TE_SetupBeamRingPoint(OtherPos,10.0,20.0,Smoke,Smoke,2,6,1.5,10.0,7.0,{120,120,255,255},40,0);
	TE_SendToAll();
}

public OnAbilityCommand( client, ability, bool:pressed )
{
	if( War3_GetRace( client ) == thisRaceID && pressed && IsPlayerAlive( client ) )
	{
		new skilllevel = War3_GetSkillLevel( client, thisRaceID, S_4 );
		if( skilllevel > 0 )
		{
			if( !Silenced( client ) && War3_SkillNotInCooldown(client,thisRaceID,S_4,true))
			{
				RemorselessWinter(client);
				War3_ChatMessage(client,"Remorseless Winter (%f feets range)",WinterRange[skilllevel]/10);
				War3_CooldownMGR(client,20.0,thisRaceID,S_4,_,_);
				for(new t=1;t<=MaxClients;t++)
				{
					if(ValidPlayer(t,true))
					{
						new Float:ClientPos[3];
						new Float:OtherPos[3];
						GetClientAbsOrigin(client,ClientPos);
						GetClientAbsOrigin(t,OtherPos);
						if(GetVectorDistance(OtherPos,ClientPos) < WinterRange[skilllevel]&&t!=client&&GetClientTeam(t)!=GetClientTeam(client)&&IsPlayerAlive(t) && !W3HasImmunity( t, Immunity_Ultimates ) && !W3HasImmunity( t, Immunity_Skills ))
						{
							ClientCommand(t, "r_screenoverlay effects/rollerglow");
							OtherPos[2]+=50;
							TE_SetupGlowSprite(OtherPos, BlueCore, 1.0, 1.0, 255);
							TE_SendToAll();
							bIceEffect[t]=true;
							War3_SetBuff(t,bBashed,thisRaceID,true);
							W3SetPlayerColor(t,thisRaceID,120,120,255,180,0);
							FakeClientCommand(t,"use weapon_knife");
							W3FlashScreen(t,RGBA_COLOR_BLUE,0.34,_,FFADE_IN);
							CreateTimer( 0.35, Loop_IceEffects, t );
							CreateTimer( WinterTime[skilllevel], Timer_RemoveIceEffect, t );
						}
					}
				}
			}
		}
	}
}

public Action:RemorselessWinter( const client)
{
	new particle = CreateEntityByName( "env_smokestack" );
	new skilllevel = War3_GetSkillLevel( client, thisRaceID, S_4 );
	if( IsValidEdict( particle ) && IsClientInGame( client ) && skilllevel > 0)
	{
		decl String:Name[32], Float:fPos[3], Float:fAng[3] = { 0.0, 0.0, 0.0 };
		Format( Name, sizeof( Name ), "Winter_%i", client );
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", fPos );
		fPos[2] += 30;

		//Set Key Values
		DispatchKeyValueVector( particle, "Origin", fPos );
		DispatchKeyValueVector( particle, "Angles", fAng );
		DispatchKeyValueFloat( particle, "BaseSpread", 450.0 );
		DispatchKeyValueFloat( particle, "StartSize", 21.0 );
		DispatchKeyValueFloat( particle, "EndSize", 11.0 );
		DispatchKeyValueFloat( particle, "Twist", 80.0 );
		
		DispatchKeyValue( particle, "Name", Name );
		DispatchKeyValue( particle, "SmokeMaterial", "particle/fire.vmt" );
		DispatchKeyValue( particle, "RenderColor", "100 100 220" );
		DispatchKeyValue( particle, "RenderAmt", "200" );
		DispatchKeyValue( particle, "SpreadSpeed", "600" );
		DispatchKeyValue( particle, "JetLength", "600" );
		DispatchKeyValue( particle, "Speed", "200" );
		DispatchKeyValue( particle, "Rate", "148" );
		DispatchSpawn( particle );
		SetVariantString( "!activator" );
		AcceptEntityInput( particle, "SetParent", client, particle, 0 );
		AcceptEntityInput( particle, "TurnOn" );
		new Float:OtherPos[3];
		GetClientAbsOrigin(client,OtherPos);
		OtherPos[2]+=40;
		TE_SetupBeamRingPoint(OtherPos, 10.0, 10+WinterRange[skilllevel], BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {100,100,255,120}, 60, 0);
		TE_SendToAll();
		EmitSoundToAll(freezeSound, client);
		CreateTimer( 5.0, Timer_StopTargetEntinty, particle );//dynamic turn off, so it not look like shit
		CreateTimer( 6.0, Timer_RemoveTargetEntinty, particle );
	}
	else
	{
		LogError( "[SM] Failed to create env_smokestack ent!" );
	}
}

public Action:Timer_RemoveTargetEntinty( Handle:timer, any:particle )
{
	AcceptEntityInput( particle, "Kill" );
}

public Action:Timer_StopTargetEntinty( Handle:timer, any:particle )
{
	AcceptEntityInput( particle, "TurnOff" );
}

public Action:Timer_RemoveIceEffect( Handle:timer, any:i)
{
	ClientCommand(i, "r_screenoverlay 0"); 
	bIceEffect[i]=false;
	new Float:OtherPos[3];
	GetClientAbsOrigin(i,OtherPos);
	OtherPos[2]+=38;
	TE_SetupBeamRingPoint(OtherPos,10.0,9999.0,BlueCore,BlueCore,2,6,1.5,100.0,7.0,{120,120,255,255},40,0);
	TE_SendToAll();
	War3_SetBuff(i,bBashed,thisRaceID,false);
	W3ResetPlayerColor(i,thisRaceID);
}

public Action:Loop_IceEffects( Handle:timer, any:i )
{
	if(ValidPlayer(i,true)){
		if(bIceEffect[i]&&IsPlayerAlive(i)){
			PrintCenterText(i,"You are turned into an Ice block!");
			FakeClientCommand(i,"use weapon_knife");
			new Float:OtherPos[3];
			GetClientAbsOrigin(i,OtherPos);
			OtherPos[2]+=38;
			TE_SetupBeamRingPoint(OtherPos,10.0,20.0,Smoke,Smoke,2,6,0.42,100.0,7.0,{100,100,255,160},40,0);
			TE_SendToAll();
			W3FlashScreen(i,RGBA_COLOR_BLUE);
			CreateTimer( 0.35, Loop_IceEffects, i );
		}
	}
}
/*
stock bool:IsPlayerOnGround( const i ) {
	return ( GetEntityFlags(i) & FL_ONGROUND );
}

public Action:Loop_Fury( Handle:timer, any:i )
{
	if(ValidPlayer(i,true)){
		if(bFury[i]&&IsPlayerAlive(i)){
			new skilllevel=War3_GetSkillLevel(i,War3_GetRace(i),U_1);
			if(skilllevel>0)
			{
				//if((GetEntityFlags(i) & FL_ONGROUND )){
				cl_flags = GetEntityFlags(i);
				if(cl_flags & FL_ONGROUND){
					for(new t=1;t<=MaxClients;t++)
					{
						if(ValidPlayer(t,true))
						{
							new Float:ClientPos[3];
							new Float:VictimPos[3];
							GetClientAbsOrigin(i,ClientPos);
							GetClientAbsOrigin(t,VictimPos);
							if(GetVectorDistance(VictimPos,ClientPos) < Range[skilllevel]&&t!=i&&GetClientTeam(t)!=GetClientTeam(i)&&IsPlayerAlive(t))
							{
								bFury[i]=false;
								VictimPos[2]+=35;
								TE_SetupBeamRingPoint(ClientPos,10.0,2000.0,Smoke,Smoke,2,6,1.2,5.0,7.0,{120,100,255,160},40,0);
								TE_SendToAll();
								TE_SetupBeamPoints(ClientPos, VictimPos, BlueCore, BlueCore, 0, 50, 1.0, 50.0, 16.0, 0, 1.5, {200,200,255,255}, 30);
								TE_SendToAll();
								EmitSoundToAll(furySound, i);
								War3_DealDamage( t, Damage[skilllevel], i, DMG_SLASH, "frostmourne", _, W3DMGTYPE_TRUEDMG );
							}
						}
					}
				}
				else
				{
					new Float:OtherPos[3];
					GetClientAbsOrigin(i,OtherPos);
					OtherPos[2]+=25;
					TE_SetupBeamRingPoint(OtherPos,10.0,200.0,Smoke,Smoke,2,6,0.42,5.0,7.0,{120,100,255,240},40,0);
					TE_SendToAll();
					CreateTimer( 0.15, Loop_Fury, i );
				}
			}
		}
	}
}*/
public Action:Timer_frostmourne( Handle:timer, any:i )
{
	if(ValidPlayer(i,true)){
		ClientCommand(i, "r_screenoverlay 0");
		if(bFury[i]&&IsPlayerAlive(i)){
			new skilllevel=War3_GetSkillLevel(i,War3_GetRace(i),U_1);
			if(skilllevel>0)
			{
				for(new t=1;t<=MaxClients;t++)
				{
					if(ValidPlayer(t,true)&&!W3HasImmunity( t, Immunity_Ultimates ))
					{
						new Float:ClientPos[3];
						new Float:VictimPos[3];
						GetClientAbsOrigin(i,ClientPos);
						GetClientAbsOrigin(t,VictimPos);
						if(GetVectorDistance(VictimPos,ClientPos) < Range[skilllevel]&&GetClientTeam(t)!=GetClientTeam(i)&&IsPlayerAlive(t)&&!bIceEffect[t])
						{
							bFury[i]=false;
							VictimPos[2]+=35;
							TE_SetupBeamRingPoint(ClientPos,10.0,2000.0,Smoke,Smoke,2,6,1.9,5.0,7.0,{120,100,255,160},40,0);
							TE_SendToAll();
							TE_SetupBeamPoints(ClientPos, VictimPos, BlueCore, BlueCore, 0, 50, 1.0, 50.0, 16.0, 0, 1.5, {200,200,255,255}, 30);
							TE_SendToAll();
							EmitSoundToAll(furySound, i);
							War3_DealDamage( t, GetRandomInt(1,6)+Damage[skilllevel], i, DMG_SLASH, "frostmourne", _, W3DMGTYPE_TRUEDMG );
							PrintToChat(i,"\x03FROSTMOURNE!");
							for(new sfx=1;sfx<=5;sfx++)
							{
								VictimPos[2]+=10;
								TE_SetupBeamRingPoint(VictimPos, 40.0, 100.0, BeamSprite, BeamSprite, 0, 15, 1.1, 10.0, 10.0, {200,200,255,255}, 120, 0);
								TE_SendToAll();
							}
						}
					}
				}
			}
		}
	}	
}

ForceClientJump( client )
{
	if( client > 0 && IsPlayerAlive( client ) )
	{
		new Float:startpos[3];
		new Float:endpos[3];
		new Float:localvector[3];
		new Float:velocity[3];
		
		GetClientAbsOrigin( client, startpos );
		GetClientAbsOrigin( client, endpos );
		endpos[2]+=180;

		localvector[2] = endpos[2] - startpos[2];
		
		velocity[0] = localvector[0];
		velocity[1] = localvector[1];
		velocity[2] = localvector[2] * 2.6;
		SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,U_1);
		if(ult_level>0)
		{
			/*if(War3_InFreezeTime())
			{
				W3MsgNoCastDuringFreezetime(client);
				W3FlashScreen(client,RGBA_COLOR_BLUE);
			}*/
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,U_1,true))
			{
				ClientCommand(client, "r_screenoverlay effects/tp_refract");
				War3_CooldownMGR(client,20.0,thisRaceID,U_1,_,_);
				new Float:client_location[3];
				GetClientAbsOrigin(client,client_location);
				client_location[2]+=20;
				TE_SetupBeamRingPoint(client_location, 620.0, 10.0, BeamSprite, BeamSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,255}, 120, 0);
				TE_SendToAll();
				TE_SetupBeamFollow(client,BeamSprite,0,0.65,10.0,20.0,20,{200,200,255,255});
				TE_SendToAll();
				ForceClientJump(client);
				bFury[client]=true;
				CreateTimer( 1.10, Timer_frostmourne, client );
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}