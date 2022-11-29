#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"
#include "revantools"
new thisRaceID;
new S_1, S_2, S_3, S_4, S_5, U_1;
new BeamSprite, HaloSprite, TracerSprite, HealthSprite;

new String:SND_SCREAM[]="npc/fast_zombie/fz_scream1.wav";
new String:SND_FLESH1[]="physics/flesh/flesh_squishy_impact_hard1.wav";
new String:SND_FLESH2[]="physics/flesh/flesh_squishy_impact_hard2.wav";
new String:SND_MORTAL[]="ambient/voices/m_scream1.wav";
new String:SND_CRITIC[]="ambient/machines/machine1_hit1.wav";
new String:SND_THUNDR[]="war3source/thunder_clap.wav";

/*
Original Ideas by Oac
Warrior.

Battleshout (ability) - Du und die Teammitglieder in deinem Radius erhalten einen Schadenbonus von 8%
Befehlsruf (ability1) - Du und die Teammitglieder in deinem Radius erhalten einen Healthbonus von 50 health.
Kniesehne (passiv) - Du hast eine chance von 15% deinen Gegner um 50% zu verlangsamen.
Mortal Strike (passiv) - Wenn deine Health unter 35% fallen fügen deine Schüsse dem Gegner 15% mehr Schaden zu
Donnerknall (ultimate) - Du fügst Gegner im Umkreis von x Metern (maximal 40) Schaden zu und verlangsamt ihre Schussgeschwindigkeit um 20%
Critical hit (passiv) - Du hast eine chance von 20% deinem Gegner einen kritischen Treffer zuzufügen.


[Rasse hat 24 Levels.]*/

public Plugin:myinfo = 
{
	name = "War3Source Race - Warrior",
	author = "Revan",
	description = "Warrior Race for War3Source",
	version = "1.0",
	url = "www.wcs-lagerhaus.de"
};

public OnMapStart()
{
	War3_PrecacheSound(SND_SCREAM);
	War3_PrecacheSound(SND_FLESH1);
	War3_PrecacheSound(SND_FLESH2);
	War3_PrecacheSound(SND_MORTAL);	
	War3_PrecacheSound(SND_CRITIC);
	War3_PrecacheSound(SND_THUNDR);
	BeamSprite = PrecacheModel("materials/sprites/lgtning.vmt");
	TracerSprite = PrecacheModel("materials/sprites/tp_beam001.vmt");
	HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	HealthSprite = PrecacheModel("effects/ar2_altfire1b.vmt");
	PrecacheModel("particle/fire.vmt");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==202)
	{
		thisRaceID = War3_CreateNewRace( "Warrior", "warrior" );
		S_1 = War3_AddRaceSkill( thisRaceID, "Battleshout", "Teammates in your near and yourself will deal 4-8% more damage to enemyes(ability)", false, 4 );	
		S_2 = War3_AddRaceSkill( thisRaceID, "Warcry", "Teammates in your near and yourself will gain +35-50 health(ability1)", false, 4 );	
		S_3 = War3_AddRaceSkill( thisRaceID, "Hamstring", "10-15% Chance to slowdown your victim for 50%", false, 4 );
		S_4 = War3_AddRaceSkill( thisRaceID, "Mortal Strike", "If your health gets lower than 35% your damage will raise up to 15%", false, 4 )
		S_5 = War3_AddRaceSkill( thisRaceID, "Critical Hit", "10-20% Chance to cause critical damage to your victims!", true, 4 );
		U_1 = War3_AddRaceSkill( thisRaceID, "Thunderclap", "Damage enemyes within 50 feets and slow them for 15-20% down", false, 4 )
		War3_CreateRaceEnd( thisRaceID );
	}
}
new Float:BSPercent[5]={1.0,1.4,1.6,1.7,1.8};
new CMPercent[5]={0,35,40,45,50};
new Float:HasBattleshout[MAXPLAYERS];
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && IsPlayerAlive(client))
	{
		if(!Silenced(client))
		{
			if(ability==0)
			{
				new skill_level=War3_GetSkillLevel(client,thisRaceID,S_2);
				if(skill_level>0)
				{
					if(War3_SkillNotInCooldown(client,thisRaceID,S_2,true))
					{
						War3_CooldownMGR(client,30.0,thisRaceID,S_2,true,true);
						new ShouterTeam = GetClientTeam(client);
						new Float:dmgbonus = BSPercent[skill_level];
						new Float:ShouterPos[3];
						GetClientAbsOrigin(client,ShouterPos);
						for(new i=1;i<=MaxClients;i++)
						{
							if(ValidPlayer(i,true)){
								new Float:TargetPos[3];
								GetClientAbsOrigin(i,TargetPos);
								if(GetVectorDistance(ShouterPos,TargetPos)<=350.0)
								{
									if(GetClientTeam(i)==ShouterTeam)
									{
										HasBattleshout[i]=dmgbonus;
										ClientCommand(i, "r_screenoverlay effects/tp_eyefx/tpeye2");
										CreateTimer( 1.5, Timer_RemoveOverlay, i );
										new Float:dir[3]={0.0,0.0,90.0};
										TargetPos[2]+=45;
										TE_SetupMetalSparks(TargetPos, dir);
										TE_SendToAll();
										TE_SetupSparks(TargetPos, dir, 200, 200);
										TE_SendToAll();
										PrintToChat(i,"\x04[War3Source] \x01You are buffed with \x03Battleshout\x01, your attacks will cause %i % more damage",RoundFloat(dmgbonus));
									}
								}
							}
						}
						new Float:posVec[3];
						GetClientAbsOrigin(client,posVec);
						posVec[2]+=48;
						TE_SetupBeamRingPoint(posVec, 1.0, 350.0, BeamSprite, HaloSprite, 0, 15, 1.4, 5.0, 0.0, {255,120,120,222}, 10, 0);
						TE_SendToAll();
						EmitSoundToAll(SND_SCREAM, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL);
					}
				}
			}
			else
			{
				new skill_level=War3_GetSkillLevel(client,thisRaceID,S_1);
				if(skill_level>0)
				{
					if(War3_SkillNotInCooldown(client,thisRaceID,S_1,true))
					{
						War3_CooldownMGR(client,30.0,thisRaceID,S_1,true,true);
						new ShouterTeam = GetClientTeam(client);
						new hpbonus = CMPercent[skill_level];
						new Float:ShouterPos[3];
						GetClientAbsOrigin(client,ShouterPos);
						for(new i=1;i<=MaxClients;i++)
						{
							if(ValidPlayer(i,true)){
								new Float:TargetPos[3];
								GetClientAbsOrigin(i,TargetPos);
								if(GetVectorDistance(ShouterPos,TargetPos)<=200.0)
								{
									if(GetClientTeam(i)==ShouterTeam)
									{
										War3_HealToMaxHP(i, hpbonus);
										W3FlashScreen(i,RGBA_COLOR_GREEN, 0.8, 0.5);
										new Float:dir[3]={0.0,0.0,0.0};
										new particle = CreateParticleSystem(i, "mini_fireworks", true, "forward", dir);
										CreateTimer( 1.0, Timer_RemoveEntity, particle );
										PrintToChat(i,"\x04[War3Source] \x01You are buffed with \x03Warcry\x01, got healed for %i hp",hpbonus);
										TE_Start("Bubbles");
										TE_WriteVector("m_vecMins", TargetPos);
										TE_WriteVector("m_vecMaxs", TargetPos);
										TE_WriteFloat("m_fHeight", 310.0);
										TE_WriteNum("m_nModelIndex", HealthSprite);
										TE_WriteNum("m_nCount", 40);
										TE_WriteFloat("m_fSpeed", 1.0);
										TE_SendToAll();
									}
								}
							}
						}
						new Float:posVec[3];
						GetClientAbsOrigin(client,posVec);
						posVec[2]+=48;
						TE_SetupBeamRingPoint(posVec, 1.0, 200.0, BeamSprite, HaloSprite, 0, 15, 1.4, 5.0, 0.0, {120,255,120,222}, 10, 0);
						TE_SendToAll();
						EmitSoundToAll(SND_SCREAM, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL);
					}
				}
			}
		}
	}
}


public OnWar3EventSpawn( client )
{
	if( ValidPlayer( client, false ) )
	{
		HasBattleshout[client]=0.0;
	}
}
new Float:CriticalStrikePercent[5]={0.0,0.33,0.66,0.88,1.00};
new Float:CriticalStrikeChance[5]={0.0,0.10,0.14,0.17,0.20}; 
new Float:HamstringChance[5]={0.0,0.10,0.12,0.14,0.15}; 
new bool:bIsSlowed[MAXPLAYERS];
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
	new vteam=GetClientTeam(victim);
	new ateam=GetClientTeam(attacker);
	if(vteam!=ateam)
	{
	    if(HasBattleshout[attacker]>0.0) {
		War3_DamageModPercent(HasBattleshout[attacker]);
	    }
	}
    }
}
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new Float:chance_mod=W3ChanceModifier(attacker);
			if(race_attacker==thisRaceID)
			{
				if(!bIsSlowed[victim]) {
					new skill_attacker=War3_GetSkillLevel(attacker,race_attacker,S_3);
					if(skill_attacker>0&&!Hexed(attacker,false))
					{
						new Float:chance=HamstringChance[skill_attacker]*chance_mod;
						if( GetRandomFloat(0.0,1.0)<=chance && !W3HasImmunity(victim,Immunity_Skills))
						{
							new Float:dir[3]={0.0,0.0,0.0};	
							new Float:duration = GetRandomFloat(1.20,2.00);
							War3_SetBuff(victim,fSlow,thisRaceID,0.6);
							War3_SetBuff(victim,fAttackSpeed,thisRaceID,0.85);
							CreateTimer(duration,Timer_RemoveSlow,victim);
							PrintHintText(victim,"You've got slowed down by Hamstring for %f seconds",duration);
							W3FlashScreen(victim,RGBA_COLOR_RED);
							if(GetRandomInt(0,1)==1)
							EmitSoundToAll(SND_FLESH1, victim, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL);
							else
							EmitSoundToAll(SND_FLESH2, victim, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL);
							CreateParticles(victim,false,GetRandomFloat(0.8,2.3),dir,40.0,13.0,5.0,200.0,"particle/fire.vmt","25 75 255","60","19","90","250");
						}
					}
				}
				if( (GetClientHealth(attacker) / War3_GetMaxHP(attacker) * 100) <= 35)
				{
					new skill_attacker=War3_GetSkillLevel(attacker,race_attacker,S_4);
					if(skill_attacker>0&&!Hexed(attacker,false))
					{
						new Float:chance=0.15*chance_mod;
						if( GetRandomFloat(0.0,1.0)<=chance && !W3HasImmunity(victim,Immunity_Skills))
						{
							new bonusdamage=RoundFloat(damage*0.15);
							new String:classname[32]="mortar_strike";
							if(War3_GetGame()==Game_TF)
							classname="bleed_kill";
							if(War3_DealDamage(victim,bonusdamage,attacker,_,classname,W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL,true))
							{	
								W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),S_4);
								W3FlashScreen(victim,RGBA_COLOR_RED);
								new Float:dir[3]={0.0,0.0,0.0};	
								new particle = CreateParticleSystem(victim, "env_embers_medium_spread", false, "forward", dir);
								CreateTimer( 3.0, Timer_RemoveEntity, particle );
								new Float:spos[3];
								new Float:epos[3];
								GetClientAbsOrigin(attacker,epos);
								GetClientAbsOrigin(victim,spos);
								spos[2]+=65;
								epos[2]+=65;
								TE_SetupBeamPoints(epos,spos,TracerSprite,HaloSprite,0,80,1.8,10.0,35.0,1,8.5,{255,0,0,255},45);
								TE_SendToAll();
								EmitSoundToAll(SND_MORTAL, victim, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL);
							}
						}
					}
				}
				new skill_attacker=War3_GetSkillLevel(attacker,race_attacker,S_5);
				if(skill_attacker>0&&!Hexed(attacker,false))
				{
					new Float:chance=CriticalStrikeChance[skill_attacker]*chance_mod;
					if( GetRandomFloat(0.0,1.0)<=chance && !W3HasImmunity(victim,Immunity_Skills))
					{
						new Float:percent=CriticalStrikePercent[skill_attacker];
						new health_take=RoundFloat(damage*percent);
						if(War3_DealDamage(victim,health_take,attacker,_,"war3_crit",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL,true))
						{	
							W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),S_5);
							W3FlashScreen(victim,RGBA_COLOR_RED);								
							new Float:dir[3]={0.0,0.0,0.0};	
							new particle = CreateParticleSystem(victim, "water_splash_03", false, "grenade1", dir);
							CreateTimer( 1.0, Timer_RemoveEntity, particle );
							new Float:spos[3];
							new Float:epos[3];
							GetClientAbsOrigin(attacker,epos);
							GetClientAbsOrigin(victim,spos);
							spos[2]+=50;
							epos[2]+=60;
							TE_SetupBeamPoints(epos,spos,TracerSprite,HaloSprite,0,40,1.4,6.0,15.0,1,2.5,{255,60,60,255},45);
							TE_SendToAll();
							EmitSoundToAll(SND_CRITIC, victim, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL);
						}
					}
				}
			}
		}
	}
}

new ThunderclapMaxDamage[5]={0,20,30,35,40}; 
new Float:ThunderclapMaxRadius=500.0;
new ThunderclapLoop[66];
new bool:HitOnForwardTide[66][66];
new Float:ThunderclapOrigin[66][3];
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,U_1);
		if(ult_level>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,U_1,true))
			{
				for(new i=1;i<=MaxClients;i++)
					HitOnForwardTide[i][client]=false;

				new Float:iVec[3];
				GetClientAbsOrigin(client,iVec);
				TE_SetupGlowSprite(iVec, HaloSprite, 1.5, 1.2, 255);
				TE_SendToAll();
				CreateTimer(0.1,Timer_Thunderclap,client);
				GetClientAbsOrigin(client,ThunderclapOrigin[client]);
				ThunderclapOrigin[client][2]+=15.0;
				ThunderclapLoop[client]=20;
				TE_SetupBeamRingPoint(ThunderclapOrigin[client], 1.0, ThunderclapMaxRadius, TracerSprite, HaloSprite, 0, 5, 1.0, 60.0, 20.0, {84,84,255,250}, 80, 0);
				TE_SendToAll();
				War3_CooldownMGR(client,GetRandomFloat(15.0,20.0),thisRaceID,U_1,_,_);
				EmitSoundToAll(SND_THUNDR, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL);
			}			
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public Action:Timer_Thunderclap(Handle:timer,any:attacker)
{
	if(ValidPlayer(attacker) && ThunderclapLoop[attacker]>0)
	{
		new team = GetClientTeam(attacker);
		CreateTimer(0.1,Timer_Thunderclap,attacker);		
		new Float:damagingRadius=(1.0-FloatAbs(float(ThunderclapLoop[attacker])-10.0)/10.0)*ThunderclapMaxRadius;
		ThunderclapLoop[attacker]--;
		
		new Float:otherVec[3];
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Skills))
			{
				
				if(HitOnForwardTide[i][attacker]==true){
					continue;
				}				
				GetClientAbsOrigin(i,otherVec);
				otherVec[2]+=30.0;
				new Float:victimdistance=GetVectorDistance(ThunderclapOrigin[attacker],otherVec);
				if(victimdistance<ThunderclapMaxRadius&&FloatAbs(otherVec[2]-ThunderclapOrigin[attacker][2])<50)
				{
					if(FloatAbs(victimdistance-damagingRadius)<(ThunderclapMaxRadius/10.0))
					{
						new dmg = ThunderclapMaxDamage[War3_GetSkillLevel(attacker,thisRaceID,U_1)];
						HitOnForwardTide[i][attacker]=true;
						War3_DealDamage(i,GetRandomInt(dmg-5,dmg),attacker,DMG_ENERGYBEAM,"waterwave");
						War3_SetBuff(i,fSlow,thisRaceID,GetRandomFloat(0.66,0.80));
						War3_SetBuff(i,fAttackSpeed,thisRaceID,GetRandomFloat(0.7,0.8));
						CreateTimer(GetRandomFloat(1.1,1.5),Timer_RemoveSlow,i);
						PrintHintText(i,"You were hit by Thunderclap!");
						TE_SetupGlowSprite(otherVec, HaloSprite, 0.8, 1.0, 255);
						TE_SendToAll();						
					}
				}
			}
		}
	}
}

public Action:Timer_RemoveSlow(Handle:timer,any:client)
{
	if(ValidPlayer(client,false))
	{
		if(bIsSlowed[client])
		bIsSlowed[client]=false;

		War3_SetBuff(client,fSlow,thisRaceID,1.0);
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
	}
}

public Action:Timer_RemoveOverlay(Handle:timer, any:client)
{
	if(ValidPlayer(client,false))
	ClientCommand(client, "r_screenoverlay 0");
}

public Action:Timer_RemoveEntity( Handle:timer, any:particle )
{
	if( IsValidEdict( particle ))
	AcceptEntityInput( particle, "Kill" );
}

// ------------------------------------------------------------------------
// CreateParticleSystem()
// ------------------------------------------------------------------------
// >> Original code by J-Factor
// ------------------------------------------------------------------------
stock CreateParticleSystem(iClient, String:strParticle[], bool:bAttach = false, String:strAttachmentPoint[]="", Float:fOffset[3]={0.0, 0.0, 0.0})
{
    new iParticle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(iParticle))
    {
        decl Float:fPosition[3];
        decl Float:fAngles[3];
        decl Float:fForward[3];
        decl Float:fRight[3];
        decl Float:fUp[3];
        
        // Retrieve entity's position and angles
        GetClientAbsOrigin(iClient, fPosition);
        GetClientAbsAngles(iClient, fAngles);
        
        // Determine vectors and apply offset
        GetAngleVectors(fAngles, fForward, fRight, fUp);    // I assume 'x' is Right, 'y' is Forward and 'z' is Up
        fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
        fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
        fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];
        
        // Teleport and attach to client
        TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
        DispatchKeyValue(iParticle, "effect_name", strParticle);

        if (bAttach == true)
        {
            SetVariantString("!activator");
            AcceptEntityInput(iParticle, "SetParent", iClient, iParticle, 0);            
            
            if (StrEqual(strAttachmentPoint, "") == false)
            {
                SetVariantString(strAttachmentPoint);
                AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);                
            }
        }

        // Spawn and start
        DispatchSpawn(iParticle);
        ActivateEntity(iParticle);
        AcceptEntityInput(iParticle, "Start");
    }

    return iParticle;
}