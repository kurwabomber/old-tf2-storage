#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/RemyFunctions"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Thief",
	author = "ABGar (edited by Kibbles)",
	description = "The Thief race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_BULLET, SKILL_KICKS, SKILL_UNIFORM, ULT_SOUL;

// SKILL_BULLET
new MyWeaponsOffset,AmmoOffset;//,Clip1Offset;
new Float:BulletCooldown[]={0.0,0.35,0.3,0.25,0.2};

// SKILL_KICKS
new Float:KicksSpeed[]={1.0,1.1,1.15,1.2,1.25};

// SKILL_UNIFORM
new Float:UniformChance[]={0.0,0.2,0.4,0.6,0.8};

// ULT_SOUL
new Float:SoulCooldown=20.0;
new Handle:ultMaxCvar;
new SoulUsedTimes[MAXPLAYERSCUSTOM];
new SoulCSStartHP[]={0,40,50,60,70}; 
new String:ultimateSound[256]; //="war3source/MiniSpiritPissed1.mp3";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Thief [PRIVATE]","thief");
	SKILL_BULLET = War3_AddRaceSkill(thisRaceID,"Steal Bullets","Each hit steals a bullet from the enemy clip and puts it in yours (attack)",false,4);
	SKILL_KICKS = War3_AddRaceSkill(thisRaceID,"Steal Some Good Kicks","Increased Speed (passive)",false,4);
	SKILL_UNIFORM = War3_AddRaceSkill(thisRaceID,"Steal Uniform","Chance on spawn to look like the enemy (passive)",false,4);
	ULT_SOUL=War3_AddRaceSkill(thisRaceID,"Steal Your Soul Back","Respawn on death (passive ultimate)",false,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_KICKS,fMaxSpeed,KicksSpeed);
}

public OnPluginStart()
{
    MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
    //Clip1Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
    AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
    
    if(GAMECSANY){
        HookEvent("player_death",PlayerDeathEvent);
        HookEvent("round_start",RoundStartEvent);
        ultMaxCvar=CreateConVar("war3_thief_respawn_max","0","Max number of revivals from vengence per round (CS only), 0 for unlimited");
    }
}

public OnMapStart()
{
    War3_AddCustomSound(ultimateSound);
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

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        SoulUsedTimes[i]=0;
        War3_CooldownReset(i,thisRaceID,ULT_SOUL);
    }
}

public InitPassiveSkills(client)
{
	new UniformLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_UNIFORM);
	if(W3Chance(UniformChance[UniformLevel]))
	{
		War3_ChangeModel(client,true);
		PrintToChat(client,"\x04[THIEF] \x03You look like the enemy this round...");
	}
}

/* *************************************** (SKILL_BULLET) *************************************** */
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true) && ValidPlayer(attacker,true) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new BulletLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_BULLET);
			if(BulletLevel>0)
			{
				if(SkillAvailable(attacker,thisRaceID,SKILL_BULLET,false,true,true))
				{
					new String:weapon[32];
					new String:Aweapon[32];
					GetClientWeapon(victim,weapon,32);
					GetClientWeapon(attacker,Aweapon,32);
					if(!StrEqual(weapon,"weapon_knife") && !StrEqual(weapon,"weapon_hegrenade") && !StrEqual(weapon,"weapon_flashbang") && !StrEqual(weapon,"weapon_smokegrenade") && !StrEqual(weapon,"weapon_c4"))
					{
						new AttackerWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
						new VictimWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
						if (IsValidEntity(VictimWeapon) && IsValidEntity(AttackerWeapon))
						{
							new AttackerAmmoType = GetEntProp(AttackerWeapon, Prop_Send, "m_iPrimaryAmmoType");
							new VictimAmmoType = GetEntProp(VictimWeapon, Prop_Send, "m_iPrimaryAmmoType");
							if(VictimAmmoType != -1 && AttackerAmmoType != -1)
							{
								new VictimAmmo = Weapon_GetPrimaryClip(VictimWeapon);
								new AttackerAmmo = Weapon_GetPrimaryClip(AttackerWeapon);
                                if (AttackerAmmo > 0)
                                {
                                    Client_SetWeaponAmmo(victim,weapon,-1,-1,(VictimAmmo-1),-1);
                                    Client_SetWeaponAmmo(attacker,Aweapon,-1,-1,(AttackerAmmo+1),-1);
                                    War3_CooldownMGR(attacker,BulletCooldown[BulletLevel],thisRaceID,SKILL_BULLET,true,false);
                                }
							}
						} 
					}
				}
			}
		}
	}
}


/* *************************************** (ULT_SOUL) *************************************** */

//
// Kibbles' edit: using Warden's respawn as a basis
//
public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victim=GetClientOfUserId(GetEventInt(event,"userid"));
    new attacker=GetClientOfUserId(GetEventInt(event,"attacker"));
    new bool:should_vengence=false;
    
    if(victim>0 && attacker>0 && attacker!=victim)
    {
        if(W3GetVar(DeathRace)==thisRaceID && War3_GetSkillLevel(victim,thisRaceID,ULT_SOUL)>0 && War3_SkillNotInCooldown(victim,thisRaceID,ULT_SOUL,false) )
        {
            if(ValidPlayer(attacker,true)&&W3HasImmunity(attacker,Immunity_Ultimates))
            {
                W3MsgSkillBlocked(attacker,_,"Steal Soul");
                W3MsgEnemyHasImmunity(victim,false);
            }
            else
            {
                should_vengence=true;
            }
        }
    }
    else if(victim>0)
    {
        if(War3_GetRace(victim)==thisRaceID && War3_GetSkillLevel(victim,thisRaceID,ULT_SOUL)>0)
        {
            if(War3_SkillNotInCooldown(victim,thisRaceID,ULT_SOUL,true) )
            {
                should_vengence=true;
            }
        }
    }
    
    //did he use it too much?
    if(victim>0){
        if(SoulUsedTimes[victim]>=GetConVarInt(ultMaxCvar)&&GetConVarInt(ultMaxCvar)>0){
            should_vengence=false;
            PrintHintText(victim,"Can only Steal Soul %d times per round",GetConVarInt(ultMaxCvar));
        }
    }
    if(should_vengence)
    {
        new victimTeam=GetClientTeam(victim);
        new playersAliveSameTeam;
        for(new i=1;i<=MaxClients;i++)
        {
            if(i!=victim&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam)
            {
                playersAliveSameTeam++;
            }
        }
        if(playersAliveSameTeam>0)
        {
            // In SoulRespawn do we actually make cooldown
            CreateTimer(0.2,SoulRespawn,victim);
        }
        else{
            PrintHintText(victim,"Can not Steal Soul when last alive");
        }
    }
}

public GiveDeathWeapons(client)
{
    if(client>0)
    {
        // reincarnate with weapons
        // drop weapons beside c4 and knife
        for(new s=0;s<10;s++)
        {
            new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
            if(ent>0 && IsValidEdict(ent))
            {
                new String:ename[64];
                GetEdictClassname(ent,ename,64);
                if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
                {
                    continue; // don't think we need to delete these
                }
                W3DropWeapon(client,ent);
                UTIL_Remove(ent);
            }
        }
        // restore iAmmo
        for(new s=0;s<32;s++)
        {
            SetEntData(client,AmmoOffset+(s*4),War3_CachedDeadAmmo(client,s),4);
        }
        // give them their weapons
        for(new s=0;s<10;s++)
        {
            new String:wep_check[64];
            War3_CachedDeadWeaponName(client,s,wep_check,64);
            if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
            {
                new wep_ent=GivePlayerItem(client,wep_check);
                if(wep_ent>0)
                {
                        //dont lower ammo
                    //SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,s),4);
                }
            }
        }
    }
}

public Action:SoulRespawn(Handle:t,any:client)
{
    if(client>0 && War3_GetRace(client)==thisRaceID) //did he become alive?
    {
        if(IsPlayerAlive(client)){
            //
        }
        else{
        
            new alivecount;
            new team=GetClientTeam(client);
            for(new i=1;i<=MaxClients;i++){
                if(ValidPlayer(i,true)&&GetClientTeam(i)==team){
                    alivecount++;
                    break;
                }
            }
            if(alivecount==0){
                PrintHintText(client,"Can not Steal Soul when last alive or round over");
            }
            else
            {
                War3_SpawnPlayer(client);
                GiveDeathWeapons(client);
                
                PrintToChat(client,"\x04[THIEF] \x03Steal your soul back....");
                new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_SOUL);
                //if(GetClientHealth(client)<SoulCSStartHP[ult_level])
                //{
                SetEntityHealth(client,SoulCSStartHP[ult_level]);
                War3_SetCSArmor(client,100);
                War3_SetCSArmorHasHelmet(client,true);
                //}    
                SoulUsedTimes[client]++;
                War3_CooldownMGR(client,SoulCooldown,thisRaceID,ULT_SOUL,false,true);
            }
        }
    }
    
}