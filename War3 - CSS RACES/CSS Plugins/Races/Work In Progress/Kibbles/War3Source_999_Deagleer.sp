#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Deagleer",
	author = "ABGar (edited by Kibbles)",
	description = "The Deagleer race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_AGILITY, SKILL_TIME, SKILL_RAMPAGE, SKILL_DEAGLEIT;

// AGILITY
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
new Float:AjilLongJump[]={0.0,0.5,0.55,0.6,0.65};
new Float:AgilJump[]={1.0,0.90,0.80,0.70,0.60};

// SKILL_TIME
new Float:DeagleChance[]={0.0,0.40,0.60,0.80,1.0};
new bool:bAmmo[MAXPLAYERSCUSTOM];
new bool:bReloading[MAXPLAYERSCUSTOM];
new DeagleAmmo=25;
new Clip1Offset;
new CurrentClipAmount[MAXPLAYERSCUSTOM];
new NewClipAmount[MAXPLAYERSCUSTOM];
new CurrentAmmo[MAXPLAYERSCUSTOM];

// SKILL_RAMPAGE
new Float:AtkSpeed[]={1.0,1.05,1.1,1.15,1.2};

// SKILL_DEAGLEIT
new Float:DeagleDamage[]={0.0,0.05,0.1,0.15,0.2};


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Deagleer [PRIVATE]","deagleer");
	SKILL_AGILITY = War3_AddRaceSkill(thisRaceID,"Agility with a Deagle","Long Jump and lower gravity",false,4);
	SKILL_TIME = War3_AddRaceSkill(thisRaceID,"Deagle Time","A chance to start with 25 ammo in your clip",false,4);
	SKILL_RAMPAGE = War3_AddRaceSkill(thisRaceID,"Deagle Rampage","Increased attack apeed",false,4);
	SKILL_DEAGLEIT=War3_AddRaceSkill(thisRaceID,"Deagle It","Increased damage with the Deagle",true,4);//ult, not skill
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID, SKILL_AGILITY, fLowGravitySkill, AgilJump);
	War3_AddSkillBuff(thisRaceID, SKILL_RAMPAGE, fAttackSpeed, AtkSpeed);
	War3_AddSkillBuff(thisRaceID, SKILL_DEAGLEIT, fDamageModifier, DeagleDamage);
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
	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)//check validity
	{
		InitPassiveSkills(client);
	}
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i = 1;i <= MaxClients;i++)
    {
        if(ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID)
        {
            if(bAmmo[i])
            {
                CreateTimer(1.0,FirstAmmo,i);   
            }
        }
    }
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_deagle,weapon_knife");
	CreateTimer(0.5, EquipDeagle, client);//When restricting weapons and equipping them, use a short timer or the restiction code clashes with the equip.
	
	new TimeLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_TIME);
	if(W3Chance(DeagleChance[TimeLevel]))
    {
        bAmmo[client]=true;
        bReloading[client]=false;
		CreateTimer(1.0,FirstAmmo,client);
    }
    else
    {
        bAmmo[client]=false;
    }
}
public Action:EquipDeagle(Handle:timer,any:client)
{
    if (!Client_HasWeapon(client, "weapon_deagle"))//Always check if they have the weapon before giving
    {
        Client_GiveWeapon(client, "weapon_deagle", true);
    }
}

public OnPluginStart()
{
	HookEvent("player_jump",PlayerJumpEvent);
	HookEvent("weapon_reload", Event_WeaponReload);
    HookEvent("round_start",RoundStartEvent);
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	Clip1Offset = FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" );
}

/* *************************************** (SKILL_AGILITY) *************************************** */
public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_AGILITY);
		if(skilllevel>0)
		{
			new Float:velocity[3]={0.0,0.0,0.0};
			velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
			velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
			velocity[0]*=AjilLongJump[skilllevel];
			velocity[1]*=AjilLongJump[skilllevel];
			SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
		}
	}
}

/* *************************************** (SKILL_TIME) *************************************** */
public Action:FirstAmmo(Handle:timer,any:client)
{
	if(ValidPlayer(client, true) && War3_GetRace(client)==thisRaceID)
	{
		if(bAmmo[client])
		{
			Client_SetWeaponAmmo(client,"weapon_deagle",-1,-1,DeagleAmmo,-1);
		}
	}
}

public OnMapStart()
{
    CreateTimer(0.1, SetWepAmmo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public Action:SetWepAmmo(Handle:timer)
{
    for (new i=1; i<=MaxClients; i++)
    {
        if(ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID && bAmmo[i] && !bReloading[i])
        {
            if (Client_HasWeapon(i, "weapon_deagle"))
            {
                new weapontype = GetPlayerWeaponSlot(i, 1);
                new ammoType = GetEntProp(weapontype, Prop_Send, "m_iPrimaryAmmoType");
                new wep_ent = Client_GetWeapon(i, "weapon_deagle");
                
                CurrentClipAmount[i]=GetEntData(wep_ent,Clip1Offset,4);
                NewClipAmount[i]=DeagleAmmo;
                CurrentAmmo[i]=GetEntProp(i,Prop_Send,"m_iAmmo",_,ammoType);
                
                if (CurrentClipAmount[i] == 0 && CurrentAmmo[i]>0)//player is reloading and not out of ammo
                {
                    bReloading[i] = true;
                    CreateTimer( 2.4, SetNewAmmo, i );
                }
            }
        }
    }
}

public Event_WeaponReload( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
    
    if( ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID && bAmmo[client] )
    {
        new String:weapon[32]; 
        GetClientWeapon( client, weapon, 32 );
        if( StrEqual( weapon, "weapon_deagle" ) )
        {
            new weapontype = GetPlayerWeaponSlot(client, 1);
            new ammoType = GetEntProp(weapontype, Prop_Send, "m_iPrimaryAmmoType");
            new wep_ent = W3GetCurrentWeaponEnt(client);
            
            CurrentClipAmount[client]=GetEntData(wep_ent,Clip1Offset,4);
            NewClipAmount[client]=DeagleAmmo;
            CurrentAmmo[client]=GetEntProp(client,Prop_Send,"m_iAmmo",_,ammoType);
            if(CurrentAmmo[client]!=0)
                CreateTimer( 2.4, SetNewAmmo, client );
        }
    }
}

public Action:SetNewAmmo(Handle:timer,any:client)
{
	if(ValidPlayer(client, true) && War3_GetRace(client)==thisRaceID && bAmmo[client])
	{
        new NewSpareAmmo = CurrentAmmo[client] - (NewClipAmount[client]-CurrentClipAmount[client]);
        if(NewSpareAmmo<1)
        {
            NewClipAmount[client]=CurrentClipAmount[client]+CurrentAmmo[client];
            NewSpareAmmo=0;
        }
        //Client_SetWeaponAmmo(client,"weapon_deagle",NewSpareAmmo,0,(NewClipAmount[client]),0);
        Client_SetWeaponAmmo(client,"weapon_deagle",-1,-1,DeagleAmmo,-1);
        bReloading[client]=false;
	}
}
