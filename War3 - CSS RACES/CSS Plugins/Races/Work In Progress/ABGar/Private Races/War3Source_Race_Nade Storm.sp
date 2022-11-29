#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Nade Storm",
	author = "ABGar",
	description = "The Nade Storm race for War3Source.",
	version = "1.0",
	// Bleakpie's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/4640-nade-storm
}

new thisRaceID;

new SKILL_BARRAGE, SKILL_MEDICINAL, SKILL_FRIEND, SKILL_MORPHINE, ULT_ARTILLERY;

new g_iOffsetAmmo = -1;
new g_iAmountOfGrenades = 150;

// SKILL_BARRAGE
new g_iExplosionModel;
new Float:BarrageChance[]={0.0,0.1,0.2,0.3,0.4};
new Float:BarrageCD[]={0.0,5.0,10.0,15.0,20.0};

// SKILL_MEDICINAL
new MedicinalHeal[]={0,1,2,3,4};
new bool:bMedicinal[MAXPLAYERS];
new bool:bMedicinalActive[MAXPLAYERS];
new Float:GasLoc[MAXPLAYERS][3];

// SKILL_FRIEND
new Float:FriendSpeed[]={1.0,1.1,1.15,1.2,1.25};

// SKILL_MORPHINE
new Float:MorphinePassive[]={0.0,0.5,1.0,1.5,2.0};
new bool:MorphineActive[MAXPLAYERS];

// ULT_ARTILLERY
new ClientTracer;
new Float:ArtilleryDamage[]={0.0,5.0,10.0,15.0,20.0};
new Float:ArtilleryCD[]={0.0,55.0,50.0,45.0,40.0};

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Nade Storm [PRIVATE]","nadestorm");
	SKILL_BARRAGE = War3_AddRaceSkill(thisRaceID,"Nade Barrage!","He shot me! Blow him up! (passive)",false,4);
	SKILL_MEDICINAL = War3_AddRaceSkill(thisRaceID,"Medicinal Nades","Nades that heal. What more could you want? (+ability)",false,4);
	SKILL_FRIEND = War3_AddRaceSkill(thisRaceID,"Speed is my Friend","Gotta go fast to get away from those explosions (passive)",false,4);
	SKILL_MORPHINE = War3_AddRaceSkill(thisRaceID,"Morphine","Not feeling pain is a good thing with explosions (passive / +ability1)",false,4);
	ULT_ARTILLERY=War3_AddRaceSkill(thisRaceID,"Artillery Bombardment","Open fire! (+ultimate)",false,4);
	
	W3SkillCooldownOnSpawn(thisRaceID, ULT_ARTILLERY, 10.0, true);
	W3SkillCooldownOnSpawn(thisRaceID, SKILL_MEDICINAL, 10.0, true);
	
	War3_CreateRaceEnd(thisRaceID);
	
	War3_AddSkillBuff(thisRaceID, SKILL_FRIEND, fMaxSpeed, FriendSpeed);
	War3_AddSkillBuff(thisRaceID, SKILL_MORPHINE, fHPRegen, MorphinePassive);
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

public OnMapStart()
{
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
}

public OnPluginStart()
{
	g_iOffsetAmmo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	HookEvent("smokegrenade_detonate", smokegrenade_detonate);
	HookEvent("weapon_fire", Event_WeaponFire);
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife,weapon_hegrenade,weapon_flashbang,weapon_smokegrenade");
	new iWeapon = GivePlayerItem(client, "weapon_hegrenade");
	if ((iWeapon != -1) && IsValidEntity(iWeapon))
	{
		SetEntData(client, g_iOffsetAmmo + 44, g_iAmountOfGrenades);
		FakeClientCommand(client, "use weapon_hegrenade");
	}
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (War3_GetRace(client) == thisRaceID)
	{
		decl String:weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		if (StrContains(weapon, "hegrenade", false) != -1)
		{
			CreateTimer(0.8, UseGrenade, client);
		}
	}
}

public Action:UseGrenade(Handle:timer, any:client)
{
	if (ValidPlayer(client, true))
	{
		if (War3_GetRace(client) == thisRaceID)
		{
			new ammo = GetEntData(client, g_iOffsetAmmo + 44);
			if (ammo > 0)
			{
				FakeClientCommand(client, "use weapon_hegrenade");
			}
		}
	}
}


/* *************************************** (SKILL_BARRAGE) *************************************** */
public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			new vteam=GetClientTeam(victim);
			new ateam=GetClientTeam(attacker);
			if(vteam!=ateam)  
			{
				new BarrageLevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_BARRAGE);
				if(BarrageLevel>0)
				{
					if(!Silenced(victim)&&!W3HasImmunity(attacker,Immunity_Skills))
					{
						if(War3_SkillNotInCooldown(victim,thisRaceID,SKILL_BARRAGE,true))
						{
							if(W3Chance(BarrageChance[BarrageLevel]))
							{
								new Float:AttackerPos[3];
								GetClientAbsOrigin(attacker,AttackerPos);
								TE_SetupExplosion(AttackerPos, g_iExplosionModel, 50.0, 10, TE_EXPLFLAG_NONE, 200, 255);
								TE_SendToAll();
								TE_SetupSmoke(AttackerPos, g_iExplosionModel, 25.0, 2);
								TE_SendToAll();
								War3_DealDamage(attacker,15,victim,DMG_BLAST,"nade barrage",_,W3DMGTYPE_MAGIC);
								War3_CooldownMGR(victim,BarrageCD[BarrageLevel],thisRaceID,SKILL_BARRAGE, _, _);
								PrintHintText(victim,"Nade Barrage");
							}
						}
					}
				}
			}
		}
	}
}

/* *************************************** (SKILL_MEDICINAL) *************************************** */
public smokegrenade_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(War3_GetRace(client) == thisRaceID)
	{
		new skill = War3_GetSkillLevel(client, thisRaceID, SKILL_MEDICINAL);
		if(skill > 0)
		{
			if(bMedicinal[client])
			{
				bMedicinalActive[client]=true;
				new Float:a[3], Float:b[3];
				a[0] = GetEventFloat(event, "x");
				a[1] = GetEventFloat(event, "y");
				a[2] = GetEventFloat(event, "z");
				GasLoc[client][0]=a[0];
				GasLoc[client][1]=a[1];
				GasLoc[client][2]=a[2];
				
				new checkok = 0;
				new ent = -1;
				while((ent = FindEntityByClassname(ent, "env_particlesmokegrenade")) != -1)
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", b);
					if(a[0] == b[0] && a[1] == b[1] && a[2] == b[2])
					{		
						checkok = 1;
						break;
					}
				}
				
				if (checkok == 1)
				{
					new iEntity = CreateEntityByName("light_dynamic");
					if (iEntity != -1)
					{
						new iRef = EntIndexToEntRef(iEntity);
						decl String:sBuffer[64];
						DispatchKeyValue(iEntity, "_light", "0 0 255");
						Format(sBuffer, sizeof(sBuffer), "smokelight_%d", iEntity);
						DispatchKeyValue(iEntity,"targetname", sBuffer);
						Format(sBuffer, sizeof(sBuffer), "%f %f %f", a[0], a[1], a[2]);
						DispatchKeyValue(iEntity, "origin", sBuffer);
						DispatchKeyValue(iEntity, "iEntity", "-90 0 0");
						DispatchKeyValue(iEntity, "pitch","-90");
						DispatchKeyValue(iEntity, "distance","256");
						DispatchKeyValue(iEntity, "spotlight_radius","96");
						DispatchKeyValue(iEntity, "brightness","3");
						DispatchKeyValue(iEntity, "style","6");
						DispatchKeyValue(iEntity, "spawnflags","1");
						DispatchSpawn(iEntity);
						AcceptEntityInput(iEntity, "DisableShadow");
						AcceptEntityInput(iEntity, "TurnOn");

						CreateTimer(1.0,GasHeal,client);
						CreateTimer(20.0, DeleteLight, iRef, TIMER_FLAG_NO_MAPCHANGE);
						bMedicinal[client]=false;
					}
				}
			}
		}
	}
}

public Action:DeleteLight(Handle:timer, any:iRef)
{
	new entity= EntRefToEntIndex(iRef);
	if (entity != INVALID_ENT_REFERENCE)
	{
		if (IsValidEdict(entity)) AcceptEntityInput(entity, "kill");
	}
	for (new i=1;i<=MaxClients;i++)
	{
		if(War3_GetRace(i)==thisRaceID)
			bMedicinalActive[i]=false;
	}
}

public Action:GasHeal(Handle:timer,any:client)
{
	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID && bMedicinalActive[client])
	{
		CreateTimer(1.0,GasHeal,client);
		new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_MEDICINAL);
		for (new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true) && bMedicinalActive[client] && War3_GetRace(i)!=thisRaceID)
			{
				new Float:iPos[3];
				GetClientAbsOrigin(i,iPos);
				if(GetVectorDistance(iPos,GasLoc[client])<=175.0)
				{
					War3_HealToMaxHP(i, MedicinalHeal[skill]);
				}
			}
		}
	}
}

public Action:GasOff(Handle:timer,any:client)
{
	bMedicinal[client]=false;
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new MedicinalLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_MEDICINAL);
		if(MedicinalLevel>0)
        {
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_MEDICINAL,true))
			{
				GivePlayerItem(client,"weapon_smokegrenade");
				FakeClientCommand(client, "use weapon_smokegrenade");
				PrintHintText(client,"Medicinal Nade ready to use.  10 Seconds to use.");
				War3_CooldownMGR(client,90.0,thisRaceID,SKILL_MEDICINAL,_,_);
				bMedicinal[client]=true;
				CreateTimer(10.0,GasOff,client);
			}
		}
	}
/* *************************************** (SKILL_MORPHINE) *************************************** */
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
	{
		new MorphineLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_MORPHINE);
		if(MorphineLevel>0)
        {
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_MORPHINE,true))
			{
				if(!Silenced(client))
				{
					if(!MorphineActive[client])
					{
						War3_SetBuff(client,fSlow,thisRaceID,0.8);
						War3_SetBuff(client,fHPRegen,thisRaceID,(MorphinePassive[MorphineLevel]*2));
						PrintHintText(client,"Morphine activated.");
						War3_CooldownMGR(client,10.0,thisRaceID,SKILL_MORPHINE, _, _);
						MorphineActive[client]=true;
					}
					else
					{
						War3_SetBuff(client,fSlow,thisRaceID,1.0);
						War3_SetBuff(client,fHPRegen,thisRaceID,MorphinePassive[MorphineLevel]);
						PrintHintText(client,"Morphine de-activated.");
						War3_CooldownMGR(client,10.0,thisRaceID,SKILL_MORPHINE, _, _);
						MorphineActive[client]=false;
					}
				}
			}
		}
		else
			PrintHintText(client,"Level your Morphine first");
	}
}

/* *************************************** (ULT_ARTILLERY) *************************************** */
public OnUltimateCommand(client, race, bool:pressed)
{
    if (ValidPlayer(client,true) && race==thisRaceID && pressed)
    {
		new ArtilleryLevel=War3_GetSkillLevel(client,thisRaceID,ULT_ARTILLERY);
		if(ArtilleryLevel>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_ARTILLERY,true))
			{
				dropGrenadeLine(client);
				War3_CooldownMGR(client,ArtilleryCD[ArtilleryLevel],thisRaceID,ULT_ARTILLERY,_,_);
			}
		}
	}
}

public bool:dropGrenadeLine(client)
{
	if(ValidPlayer(client))
	{
		if(IsPlayerAlive(client))
		{
			new skill_line = War3_GetSkillLevel(client, thisRaceID, ULT_ARTILLERY);
			new Float:angle[3];
			new Float:endpos[3];
			new Float:startpos[3];
			new Float:dir[3];
			new Float:grenadeDir[3];

			GetClientAbsAngles(client,angle);
			GetClientEyePosition(client,startpos);
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);

			grenadeDir[0] = dir[0];
			grenadeDir[1] = dir[1];
			grenadeDir[2] = dir[2];

			ScaleVector(dir, 1000.0);
			AddVectors(startpos, dir, endpos);
			ClientTracer=client;
			TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetPlayerFilter);
			TR_GetEndPosition(endpos);

			ScaleVector(grenadeDir, 100.0);
			AddVectors(startpos, grenadeDir, endpos);

			new grenadeCount = 0;
			new Float:cumulativeDistance = 100.0;

			while (cumulativeDistance <= 1000.0 && grenadeCount < 5)
			{
				dropGrenade(client, endpos, ArtilleryDamage[skill_line]);
				AddVectors(endpos, grenadeDir, endpos);
				cumulativeDistance += 100.0;
				grenadeCount++;
			}           
			return true;
		}
	}
	return false;
}

public bool:AimTargetPlayerFilter(entity,mask)
{
    new bool:returnValue = true;
    for (new i=1;i<=MAXPLAYERS;i++)
    {
        if (ValidPlayer(entity, true) || entity == ClientTracer)
            returnValue = false;
    }
    return returnValue;
}

public dropGrenade(any:client, Float:pos[3], Float:damage)
{
    new grenadeEnt = CreateEntityByName("hegrenade_projectile");
    if (IsValidEntity(grenadeEnt))
    {
        SetEntPropEnt(grenadeEnt, Prop_Send, "m_hOwnerEntity", client);
        SetEntPropEnt(grenadeEnt, Prop_Send, "m_hThrower", client);
        SetEntProp(grenadeEnt, Prop_Send, "m_iTeamNum", GetClientTeam(client));

        SetEntPropFloat(grenadeEnt, Prop_Send, "m_flDamage", damage);
        SetEntPropFloat(grenadeEnt, Prop_Send, "m_DmgRadius", 350.0);
        SetEntPropFloat(grenadeEnt, Prop_Send, "m_flElasticity", 0.0);
        SetEntProp(grenadeEnt, Prop_Send, "m_CollisionGroup", 2);
        
        DispatchSpawn(grenadeEnt);
        TeleportEntity(grenadeEnt, pos, NULL_VECTOR, NULL_VECTOR);
        SetEntProp(grenadeEnt, Prop_Data, "m_nNextThinkTick", -1);
        CreateTimer(1.5,detonateGrenade,grenadeEnt);
    }
}

public Action:detonateGrenade(Handle:timer, any:grenadeEnt)
{
    if (IsValidEntity(grenadeEnt))
    {
        SetEntProp(grenadeEnt, Prop_Send, "m_CollisionGroup", 5);
        SetEntProp(grenadeEnt, Prop_Data, "m_takedamage", 2);
        SetEntProp(grenadeEnt, Prop_Data, "m_iHealth", 1);
        SetEntProp(grenadeEnt, Prop_Data, "m_nNextThinkTick", 1);
        Entity_Hurt(grenadeEnt, 1, grenadeEnt);
    }
}