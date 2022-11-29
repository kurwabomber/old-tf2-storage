#include <tf2>
#include <sourcemod>
#include <functions>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <tf2itemsinfo>
#include <keyvalues>
#include <tf2_isPlayerInSpawn>
#pragma tabsize 0
////
//
#define UU_VERSION "razor's uberupgrades"


#define RED 0
#define BLUE 1

#define NB_B_WEAPONS 1

#define NB_SLOTS_UED 9

#define MAX_ATTRIBUTES 3000

#define MAX_ATTRIBUTES_ITEM 65

#define _NUMBER_DEFINELISTS 630

#define _NUMBER_DEFINELISTS_CAT 9

#define WCNAMELISTSIZE 700

#define _NB_SP_TWEAKS 60
#define MAXLEVEL_D 0
new Handle:up_menus[MAXPLAYERS + 1]
new Handle:menuBuy
new Handle:BuyNWmenu
new BuyNWmenu_enabled;
new Handle:cvar_uu_version
new Handle:cvar_StartMoney
new StartMoney
new Handle:cvar_TimerMoneyGive_BlueTeam
new TimerMoneyGive_BlueTeam
new Handle:cvar_TimerMoneyGive_RedTeam
new TimerMoneyGive_RedTeam
new Handle:cvar_MoneyBonusKill
new MoneyBonusKill
//new Handle:cvar_MoneyForTeamRatioRed
new Handle:cvar_AutoMoneyForTeamRatio
new Float:MoneyForTeamRatio[2]
new Float:MoneyTotalFlow[2]
new Handle:Timers_[2]
new moneyLevels[MAXLEVEL_D + 1]
new given_upgrd_list_nb[_NUMBER_DEFINELISTS]
new given_upgrd_list[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][128]
new String:given_upgrd_classnames[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][128]
new given_upgrd_classnames_tweak_idx[_NUMBER_DEFINELISTS]
new given_upgrd_classnames_tweak_nb[_NUMBER_DEFINELISTS]
new String:wcnamelist[WCNAMELISTSIZE][128]
new wcname_l_idx[WCNAMELISTSIZE]
new current_w_list_id[MAXPLAYERS + 1]
new current_w_c_list_id[MAXPLAYERS + 1]
new _:current_class[MAXPLAYERS + 1]
new String:current_slot_name[10][128]
new current_slot_used[MAXPLAYERS + 1]
new currentupgrades_idx[MAXPLAYERS + 1][10][MAX_ATTRIBUTES_ITEM]
new Float:currentupgrades_val[MAXPLAYERS + 1][10][MAX_ATTRIBUTES_ITEM]
//new currentupgrades_special_ratio[MAXPLAYERS + 1][10][MAX_ATTRIBUTES_ITEM]
new currentupgrades_number[MAXPLAYERS + 1][10]
new currentitem_level[MAXPLAYERS + 1][10]
new currentitem_idx[MAXPLAYERS + 1][10]
new currentitem_ent_idx[MAXPLAYERS + 1][10] 
new currentitem_catidx[MAXPLAYERS + 1][10]
new String:currentitem_classname[MAXPLAYERS + 1][10][128]
new upgrades_ref_to_idx[MAXPLAYERS + 1][10][MAX_ATTRIBUTES]
new currentupgrades_idx_mvm_chkp[MAXPLAYERS + 1][10][MAX_ATTRIBUTES_ITEM]
new Float:currentupgrades_val_mvm_chkp[MAXPLAYERS + 1][10][MAX_ATTRIBUTES_ITEM]
new currentupgrades_number_mvm_chkp[MAXPLAYERS + 1][10]
new _u_id;
new client_spent_money[MAXPLAYERS + 1][10]
new client_new_weapon_ent_id[MAXPLAYERS + 1]
new client_spent_money_mvm_chkp[MAXPLAYERS + 1][10]
new client_last_up_slot[MAXPLAYERS + 1]
new client_last_up_idx[MAXPLAYERS + 1]
new client_iCash[MAXPLAYERS + 1];			
new client_respawn_handled[MAXPLAYERS + 1]
new client_respawn_checkpoint[MAXPLAYERS + 1]
new client_no_showhelp[MAXPLAYERS + 1]
new client_no_d_team_upgrade[MAXPLAYERS + 1]
new client_no_d_menubuy_respawn[MAXPLAYERS + 1]
new Handle:_upg_names
new Handle:_weaponlist_names
new Handle:_spetweaks_names
new String:upgradesNames[MAX_ATTRIBUTES][128]
new String:upgradesWorkNames[MAX_ATTRIBUTES][96]
new upgrades_to_a_id[MAX_ATTRIBUTES]
new upgrades_costs[MAX_ATTRIBUTES]
new Float:upgrades_ratio[MAX_ATTRIBUTES]
new Float:upgrades_i_val[MAX_ATTRIBUTES]
new Float:upgrades_m_val[MAX_ATTRIBUTES]
new Float:upgrades_costs_inc_ratio[MAX_ATTRIBUTES]
new String:upgrades_tweaks[_NB_SP_TWEAKS][128]
new upgrades_tweaks_nb_att[_NB_SP_TWEAKS]
new upgrades_tweaks_att_idx[_NB_SP_TWEAKS][10]
new Float:upgrades_tweaks_att_ratio[_NB_SP_TWEAKS][10]
new gamemode
#define MVM_GAMEMODE 0
#define CP_GAMEMODE 1
new newweaponidx[64];
new String:newweaponcn[32][64];
new String:newweaponmenudesc[32][64];
new additionalstartmoney;
new	Float:mvmadditional;

public void TF2_OnConditionAdded(client, TFCond:cond)
{
	new Address:attribute2 = TF2Attrib_GetByName(client, "absorb damage while cloaked");
	new Address:attribute3 = TF2Attrib_GetByName(client, "always_transmit_so");
	new Address:attribute1 = TF2Attrib_GetByName(client, "obsolete ammo penalty");
	new Address:attribute4 = TF2Attrib_GetByName(client, "jarate description");
	new Address:attribute5 = TF2Attrib_GetByName(client, "overheal bonus");
	if (IsValidClient(client))
	{
		if (attribute2 != Address_Null) 
		{
			new chance = GetRandomInt(1, 100);
			if(cond == TFCond_OnFire)
			{
				if(chance <= 70) //50% chance
				{
					TF2_RemoveCondition(client, TFCond_OnFire)
					TF2_RemoveCondition(client, TFCond_HealingDebuff)
				}
			}
		}
		if (attribute3 != Address_Null) 
		{
			new chance1 = GetRandomInt(1, 100);
			if(cond == TFCond_Bleeding)
			{
				if(chance1 <= 50) //30% chance
				{
					TF2_RemoveCondition(client, TFCond_Bleeding)
				}
			}
		}
		if (attribute1 != Address_Null) 
		{
			TF2_RemoveCondition(client, TFCond_Slowed);
			TF2_RemoveCondition(client, TFCond_TeleportedGlow);
			TF2_RemoveCondition(client, TFCond_Dazed);
			TF2_RemoveCondition(client, TFCond_OnFire);
			TF2_RemoveCondition(client, TFCond_Jarated);
			TF2_RemoveCondition(client, TFCond_Bleeding);
			TF2_RemoveCondition(client, TFCond_Milked);
			TF2_RemoveCondition(client, TFCond_MarkedForDeath);
			TF2_RemoveCondition(client, TFCond_FreezeInput);
			TF2_RemoveCondition(client, TFCond_HealingDebuff);
			TF2_RemoveCondition(client, TFCond_Gas);
			TF2_RemoveCondition(client, TFCond_Plague);
			TF2_RemoveCondition(client, TFCond_TeleportedGlow);
		}
		if (attribute4 != Address_Null) 
		{
			TF2_RemoveCondition(client, TFCond_Slowed);
			TF2_RemoveCondition(client, TFCond_Dazed);
			TF2_RemoveCondition(client, TFCond_TeleportedGlow);
		} 
		if(cond == TFCond_OnFire)
		{
			TF2_AddCondition(client, TFCond_HealingDebuff, 2.0);
		}
		if (current_class[client] == _:TFClass_Pyro)
		{
			if(cond == TFCond_OnFire)
			{
				TF2_RemoveCondition(client, TFCond_OnFire);
				TF2_RemoveCondition(client, TFCond_HealingDebuff);
			}
		}
		if (attribute5 != Address_Null) 
		{
			if(cond == TFCond_Bonked)
			{
				TF2_AddCondition(client, TFCond_SpeedBuffAlly, 9.5);
				TF2_AddCondition(client, TFCond_HalloweenQuickHeal, 8.0);
				TF2_AddCondition(client, TFCond_RuneAgility, 7.3);
			}
			if(cond == TFCond_CritCola)
			{
				TF2_AddCondition(client, TFCond_RegenBuffed, 6.5);
				TF2_AddCondition(client, TFCond_CritCanteen, 16.0);
				TF2_AddCondition(client, TFCond_HalloweenSpeedBoost, 16.0);
			}
		}
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
	}

}
stock bool:IsMvM(bool:forceRecalc = false)
{
	static bool:found = false;
	static bool:ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}
//uu stuffs
public Action:Timer_WaitForTF2II(Handle:timer)
{
	new i = 0
	if (TF2II_IsValidAttribID(1))
	{
		for (i = 1; i < 3000; i++)
		{
			if (TF2II_IsValidAttribID(i))
			{
				TF2II_GetAttributeNameByID( i, upgradesWorkNames[i], 96 );
			//	PrintToServer("%s\n", upgradesWorkNames[i]);
			}
			else
			{
			//	PrintToServer("unvalid attrib %d\n", i);
			}
		}
		for (i = 0; i < MAX_ATTRIBUTES; i++)
		{
			upgrades_ratio[i] = 0.0
			upgrades_i_val[i] = 0.0
			upgrades_costs[i] = 0
			upgrades_costs_inc_ratio[i] = 0.20
			upgrades_m_val[i] = 0.0
		}
		for (i = 1; i < _NUMBER_DEFINELISTS; i++)
		{
			given_upgrd_classnames_tweak_idx[i] = -1
			given_upgrd_list_nb[i] = 0
		}
		_load_cfg_files()
		KillTimer(timer)
	}
	
}

public UberShopDefineUpgradeTabs()
{
	new i = 0
	while (i < MAXPLAYERS + 1)
	{
		client_respawn_handled[i] = 0
		client_respawn_checkpoint[i] = 0
		up_menus[i] = INVALID_HANDLE
		new j = 0
		while (j < NB_SLOTS_UED)
		{
			currentupgrades_number[i][j] = 0
			currentitem_level[i][j] = 0
			currentitem_idx[i][j] = 20000
			client_spent_money[i][j] = 0
			new k = 0
			while (k < MAX_ATTRIBUTES)
			{
				upgrades_ref_to_idx[i][j][k] = 20000
				k++
			}
			j++
		}	
		i++
	
	}
	
	current_slot_name[0] = "Primary Weapon"
	current_slot_name[1] = "Secondary Weapon"
	current_slot_name[2] = "Melee Weapon"
	current_slot_name[3] = "Special Weapon"
	current_slot_name[4] = "Body"
	upgradesNames[0] = ""
	CreateTimer(0.3, Timer_WaitForTF2II, _);
}


public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{

	if (IsValidClient(client) && !TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		if (itemDefinitionIndex == 199
		|| itemDefinitionIndex == 1153
		|| itemDefinitionIndex == 15003
		|| itemDefinitionIndex == 15016
		|| itemDefinitionIndex == 15044
		|| itemDefinitionIndex == 15047
		|| itemDefinitionIndex == 15085
		|| itemDefinitionIndex == 15109
		|| itemDefinitionIndex == 15132
		|| itemDefinitionIndex == 15133
		|| itemDefinitionIndex == 15152)
		{
			new ent = EntIndexToEntRef(entityIndex);
			if (ent <= MaxClients) return; 
			AcceptEntityInput(ent, "Kill"); 
		}
		if (itemDefinitionIndex == 1101)
		{
			new ent = EntIndexToEntRef(entityIndex);
			if (ent <= MaxClients) return; 
			AcceptEntityInput(ent, "Kill"); 
		}
		if (itemLevel == 242)
		{
			new slot = 3
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 20000
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)

			GiveNewUpgradedWeapon_(client, slot)
			PrintToServer("OGiveItem slot %d: [%s] #%d CAT[%d] qual%d", slot, classname, itemDefinitionIndex, currentitem_catidx[client][slot], itemLevel)
		}
		else
		{
			new slot = _:TF2II_GetItemSlot(itemDefinitionIndex)	
			//PrintToChatAll("OGiveItem slot %d: [%s] #%d CAT[%d] qual%d", slot, classname, itemDefinitionIndex, currentitem_catidx[client][slot], itemLevel)
			if (current_class[client] == _:TFClass_Spy)
			{
				if (!strcmp(classname, "tf_weapon_pda_spy"))
				{
					currentitem_classname[client][slot] = "tf_weapon_pda_spy"
					currentitem_ent_idx[client][0] = 735
					current_class[client] = _:TF2_GetPlayerClass(client)
					DefineAttributesTab(client, 735, 0)
					currentitem_catidx[client][0] = GetUpgrade_CatList("l")
					GiveNewUpgradedWeapon_(client, 0)
				}
			}
			if (slot < 3)
			{
				GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
				currentitem_ent_idx[client][slot] = entityIndex
				current_class[client] = _:TF2_GetPlayerClass(client)
				//currentitem_idx[client][slot] = itemDefinitionIndex
				DefineAttributesTab(client, itemDefinitionIndex, slot)
				//if (current_class[client] == )
				if (current_class[client] == _:TFClass_DemoMan)
				{
					if (!strcmp(classname, "tf_wearable"))
					{
						if (itemDefinitionIndex == 405
						|| itemDefinitionIndex == 608)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_wear_alishoes")
						}
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
					if (!strcmp(classname, "tf_weapon_parachute"))
					{
						if (itemDefinitionIndex == 1101)
						{
							currentitem_classname[client][0] = "tf_weapon_parachute"
							GiveNewUpgradedWeapon_(client, 0)
							currentitem_ent_idx[client][0] = 1101
							currentitem_catidx[client][0] = GetUpgrade_CatList("tf_weapon_parachute")
						}
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}					
				}
				else if (!strcmp(classname, "tf_weapon_grapplinghook"))
				{
					if (itemDefinitionIndex == 1152)
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_grapplinghook")
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				else if (current_class[client] == _:TFClass_Soldier)
				{
					if (!strcmp(classname, "tf_weapon_shotgun"))
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_shotgun_soldier")
					}				
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}					
				}
				else if (current_class[client] == _:TFClass_Pyro)
				{
					if (!strcmp(classname, "tf_weapon_flaregun"))
					{
						if (itemDefinitionIndex == 351)
						currentitem_catidx[client][slot] = GetUpgrade_CatList("detonator")
					}
					if (!strcmp(classname, "tf_weapon_flaregun"))
					{
						if (itemDefinitionIndex == 39
						|| itemDefinitionIndex == 1081)
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_flaregun")
					}
					if (!strcmp(classname, "tf_weapon_shotgun") || !strcmp(classname, "tf_weapon_shotgun_pyro"))
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_shotgun_pyro")
					}	
					if (!strcmp(classname, "tf_weapon_flaregun"))
					{
						if (itemDefinitionIndex == 740)
						currentitem_catidx[client][slot] = GetUpgrade_CatList("scorchshot")
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				else if (current_class[client] == _:TFClass_Heavy)
				{
					if (!strcmp(classname, "tf_weapon_shotgun"))
					{
						currentitem_catidx[client][1] = GetUpgrade_CatList("tf_weapon_shotgun_hwg")
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}	
				}
				else if (current_class[client] == _:TFClass_Sniper)
				{
					if (!strcmp(classname, "tf_wearable"))
					{
						if (itemDefinitionIndex == 231)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_w_darws")
						}
					}
					if (!strcmp(classname, "tf_weapon_crossbow") || !strcmp(classname, "tf_weapon_grenadelauncher"))
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("autofirebow")
					}
					if (itemDefinitionIndex == 752){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_sniperrifle_hitman")
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
					
				}
				else if (current_class[client] == _:TFClass_Medic)
				{
					if (!strcmp(classname, "tf_weapon_medigun"))
					{
						if (itemDefinitionIndex == 998)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("vacc")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					if (!strcmp(classname, "tf_weapon_syringegun_medic"))
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("syringe")
					}
					if (!strcmp(classname, "tf_weapon_crossbow"))
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("crusaders")
					}
					if (!strcmp(classname, "tf_weapon_bonesaw"))
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_bonesaw")
					}
				}
				else if (current_class[client] == _:TFClass_Spy)
				{
					if (!strcmp(classname, "tf_weapon_knife"))
					{
						currentitem_catidx[client][2] = GetUpgrade_CatList("tf_weapon_knife")
					}
					if (!strcmp(classname, "tf_weapon_revolver"))
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_revolver")
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				else if (current_class[client] == _:TFClass_Engineer)
				{
					if (!strcmp(classname, "tf_weapon_shotgun"))
					{
						currentitem_catidx[client][0] = GetUpgrade_CatList("tf_weapon_shotgun_primary")
					}
					if (!strcmp(classname, "tf_weapon_shotgun_primary"))
					{
						if (itemDefinitionIndex == 527)
						currentitem_catidx[client][0] = GetUpgrade_CatList("tf_weapon_shotgun_primary_")
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				else if (current_class[client] == _:TFClass_Scout)
				{
					if (!strcmp(classname, "tf_weapon_scattergun"))
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_scattergun_")
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				else
				{
					currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
				}
				GiveNewUpgradedWeapon_(client, slot)
			}
			//PrintToChatAll("OGiveItem slot %d: [%s] #%d CAT[%d] qual%d", slot, classname, itemDefinitionIndex, currentitem_catidx[client][slot], itemLevel)
		}
	}
}


public Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client))
	{
		current_class[client] = _:TF2_GetPlayerClass(client)
		ResetClientUpgrades(client)
		RespawnEffect(client);
		ChangeClassEffect(client);
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
		}
		FakeClientCommand(client, "menuselect 0");
		SetEntProp(client, Prop_Send, "m_nCurrency", (StartMoney + additionalstartmoney));
	}
}
public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && IsValidClient(client)){
		FakeClientCommand(client, "menuselect 0");
		TF2Attrib_ClearCache(client);
	}
	RespawnEffect(client);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 3.0);
	current_class[client] = _:TF2_GetPlayerClass(client)
//	new team = GetClientOfUserId(GetEventInt(event, "team"));
	client_respawn_handled[client] = 1;
		//PrintToChat(client, "TEAM #%d", team)

	if (client_respawn_checkpoint[client])
	{
		//PrintToChatAll("cash readjust")
		CreateTimer(0.1, mvm_CheckPointAdjustCash, GetClientUserId(client));
	}
	else
	{
		CreateTimer(0.05, WeaponReGiveUpgrades, GetClientUserId(client));
	}
}

	
public Action:Timer_GetConVars(Handle:timer)//Reload con_vars into vars
{
	//
	//CostIncrease_ratio_default  = GetConVarFloat(cvar_CostIncrease_ratio_default)
	MoneyBonusKill = GetConVarInt(cvar_MoneyBonusKill)
	//MoneyForTeamRatio[RED]  = GetConVarFloat(cvar_MoneyForTeamRatioRed)
	//MoneyForTeamRatio[BLUE]  = GetConVarFloat(cvar_MoneyForTeamRatioBlue)
	TimerMoneyGive_BlueTeam = GetConVarInt(cvar_TimerMoneyGive_BlueTeam)
	TimerMoneyGive_RedTeam = GetConVarInt(cvar_TimerMoneyGive_RedTeam)
	StartMoney = GetConVarInt(cvar_StartMoney)
	
	//if (CostIncrease_ratio_default) //quick compile warning bypass // TODO INCLUDE CostIncrease_ratio_default
	//{
	//}
}

public Action:Timer_GiveSomeMoney(Handle:timer)//GIVE MONEY EVRY 20s
{
	new iCashtmp;
	
	MoneyTotalFlow[RED] = 0.00
	MoneyTotalFlow[BLUE] = 0.00
	for (new client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
	{
		if (IsValidClient(client_id) && (GetClientTeam(client_id) > 1))
		{
			iCashtmp = GetEntProp(client_id, Prop_Send, "m_nCurrency", iCashtmp);
			//iCashtmp = 0
			iCashtmp += client_spent_money[client_id][0]
						   +client_spent_money[client_id][1]
						   +client_spent_money[client_id][2]
						   +client_spent_money[client_id][3];
			if (GetClientTeam(client_id) == 3)
			{
				MoneyTotalFlow[BLUE] += iCashtmp
			}
			else
			{
				MoneyTotalFlow[RED] += iCashtmp
			}
				
		}
	}

	if (MoneyTotalFlow[RED])
	{
		MoneyForTeamRatio[RED] = MoneyTotalFlow[BLUE] / MoneyTotalFlow[RED]
	}
	if (MoneyTotalFlow[BLUE])
	{
		MoneyForTeamRatio[BLUE] = MoneyTotalFlow[RED] / MoneyTotalFlow[BLUE]
	}
	if (MoneyForTeamRatio[RED] > 3.0)
	{
		MoneyForTeamRatio[RED] = 3.0
	}
	if (MoneyForTeamRatio[BLUE] > 3.0)
	{
		MoneyForTeamRatio[BLUE] = 3.0
	}
	MoneyForTeamRatio[BLUE] *= MoneyForTeamRatio[BLUE]
	MoneyForTeamRatio[RED] *= MoneyForTeamRatio[RED]
	for (new client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
	{
		if (IsValidClient(client_id))
		{
			iCashtmp = GetEntProp(client_id, Prop_Send, "m_nCurrency", iCashtmp);
			if (GetClientTeam(client_id) == 3)//BLUE TEAM
			{
				if (GetConVarInt(cvar_AutoMoneyForTeamRatio))
				{
					SetEntProp(client_id, Prop_Send, "m_nCurrency",
								iCashtmp + RoundToNearest(TimerMoneyGive_BlueTeam * MoneyForTeamRatio[BLUE]));
				}
				else
				{
					SetEntProp(client_id, Prop_Send, "m_nCurrency",
								iCashtmp + TimerMoneyGive_BlueTeam);
				}
			}
			else if (GetClientTeam(client_id) == 2)//RED TEAM
			{
				if (GetConVarInt(cvar_AutoMoneyForTeamRatio))
				{
					SetEntProp(client_id, Prop_Send, "m_nCurrency",
								iCashtmp + RoundToNearest(TimerMoneyGive_RedTeam * MoneyForTeamRatio[RED]));
				}
				else
				{
					SetEntProp(client_id, Prop_Send, "m_nCurrency",
								iCashtmp + TimerMoneyGive_RedTeam);
				}
			}
		}
	}
	TimerMoneyGive_BlueTeam = GetConVarInt(cvar_TimerMoneyGive_BlueTeam)
	TimerMoneyGive_RedTeam = GetConVarInt(cvar_TimerMoneyGive_RedTeam)

}
public Action:Timer_Resetupgrades(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		for (new slot = 0; slot < NB_SLOTS_UED; slot++)
		{
			client_spent_money[client][slot] = 0
			client_spent_money_mvm_chkp[client][slot] = 0
		}
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.1, ClChangeClassTimer, GetClientUserId(client));
		}
	}
}


public Action:ClChangeClassTimer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		client_respawn_checkpoint[client] = 0;
		if (!client_no_d_menubuy_respawn[client])
		{
			Menu_BuyUpgrade(client, 0);
		}
	}
}

public Action:WeaponReGiveUpgrades(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
	//	if (current_class[client] == _:TFClass_Spy)
	//	{
	//			PrintToChat(client, "shpiee");
	//	}
		client_respawn_handled[client] = 1
		for (new slot = 0; slot < NB_SLOTS_UED; slot++)
		{
			//PrintToChat(client, "money spent on slot  %d -- %d$", slot, client_spent_money[client][slot]);
			if (client_spent_money[client][slot] > 0)
			{
				if (slot == 3 && client_new_weapon_ent_id[client])
				{
					GiveNewWeapon(client, 3)
				}
				GiveNewUpgradedWeapon_(client, slot)
			//	PrintToChat(client, "player's upgrad!!");
			}
		}
	}
	client_respawn_handled[client] = 0
	if(IsFakeClient(client) || MoneyBonusKill == 5000)
	{
		new secondary = (GetPlayerWeaponSlot(client,1));
		new primary = (GetPlayerWeaponSlot(client,0));
		new pda = (GetPlayerWeaponSlot(client,3));
		if(!IsValidClient(client) && (!IsMvM()))
		{
			TF2Attrib_ClearCache(client);
		}
		if(!IsMvM()){
		TF2Attrib_SetByName(client,"rage giving scale",(500.0/(additionalstartmoney+StartMoney)));//Rage gave from being hit
		if((additionalstartmoney+StartMoney) >= 500000)
		{
			TF2Attrib_SetByName(client,"damage bonus HIDDEN",(2.0));//Overall Damage Bonus
			TF2Attrib_SetByName(client,"mult_dmgtaken_active",(0.5));//Overall Damage Taken Decreased
		}
		if((additionalstartmoney+StartMoney) >= 1500000)
		{
			TF2Attrib_SetByName(client,"damage bonus HIDDEN",(3.0));//Overall Damage Bonus
			TF2Attrib_SetByName(client,"mult_dmgtaken_active",(0.33));//Overall Damage Taken Decreased
		}
		if((additionalstartmoney+StartMoney) <= 80000)
		{
			TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(additionalstartmoney+StartMoney)));//Firerate
		}
		else
		{
			TF2Attrib_SetByName(client,"fire rate bonus",(0.25));//Firerate
		}
		if((additionalstartmoney+StartMoney) <= 750000)
		{
			TF2Attrib_SetByName(client,"dmg taken increased",(11000.0/(additionalstartmoney+StartMoney)));//Damage Taken Increased(decreased)
		}
		else
		{
			TF2Attrib_SetByName(client,"dmg taken increased",(6500.0/(additionalstartmoney+StartMoney)));//Damage Taken Increased(decreased)
		}
		if((additionalstartmoney+StartMoney) <= 1000000){
		TF2Attrib_SetByName(client,"damage penalty",((additionalstartmoney+StartMoney)/17000.0));//Damage Bonus
		TF2Attrib_SetByName(client,"dmg penalty vs players",((additionalstartmoney+StartMoney)/22000.0));//Damage penalty vs players(ap)
		}else{
		TF2Attrib_SetByName(client,"damage penalty",((additionalstartmoney+StartMoney)/23000.0));//Damage Bonus
		TF2Attrib_SetByName(client,"dmg penalty vs players",((additionalstartmoney+StartMoney)/25000.0));//Damage penalty vs players(ap)		
		}
		TF2Attrib_SetByName(client,"maxammo primary increased",((additionalstartmoney+StartMoney)/5000.0));//Primary Ammo Bonus
		TF2Attrib_SetByName(client,"maxammo secondary increased",((additionalstartmoney+StartMoney)/5000.0));//Secondary Ammo Bonus
		TF2Attrib_SetByName(client,"ammo regen", 1.0);//Secondary Ammo Bonus
		TF2Attrib_SetByName(client,"faster reload rate",(17500.0/(additionalstartmoney+StartMoney)));//Reload Rate Bonus
		if((additionalstartmoney+StartMoney) <= 60000)
		{
			TF2Attrib_SetByName(client,"move speed bonus",((additionalstartmoney+StartMoney)/16000.0));//Movespeed Bonus
		}
		else
		{
			TF2Attrib_SetByName(client,"move speed bonus",(3.00));//Movespeed Bonus
		}
		if (current_class[client] == _:TFClass_Scout)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/200.0));//Health Bonus
			TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/12500.0));//Clip Size
			TF2Attrib_SetByName(client,"health regen",((additionalstartmoney+StartMoney)/1000.0));//Health Regen
			TF2Attrib_SetByName(secondary,"fire rate bonus",3.0);//Firerate
			if((additionalstartmoney+StartMoney) <= 75000){
			TF2Attrib_SetByName(primary,"bullets per shot bonus",((additionalstartmoney+StartMoney)/15000.0));//Bullets Per shot
			}else{
			TF2Attrib_SetByName(primary,"bullets per shot bonus",(5.0));//Bullets per shot
			}
			if((additionalstartmoney+StartMoney) <= 400000)
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(additionalstartmoney+StartMoney)));//Firerate
			}
			else
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(0.05));//Firerate
			}
			
		}
		else if (current_class[client] == _:TFClass_Soldier)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/130.5));//Health Bonus
			TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/11000.0));//Clip Size
			TF2Attrib_SetByName(client,"health regen",((additionalstartmoney+StartMoney)/750.0));//Health Regen
			if((additionalstartmoney+StartMoney) <= 75000)
			{
				TF2Attrib_SetByName(client,"Blast radius increased",((additionalstartmoney+StartMoney)/18000.0));//Blast Radius
				TF2Attrib_SetByName(client,"Projectile speed increased",((additionalstartmoney+StartMoney)/20000.0));//Projectile Speed
			}
			else
			{
				TF2Attrib_SetByName(client,"Blast radius increased",(4.0));//Blast Radius
				TF2Attrib_SetByName(client,"Projectile speed increased",(3.5));//Projectile Speed
			}
			if((additionalstartmoney+StartMoney) <= 200000)
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(additionalstartmoney+StartMoney)));//Firerate
			}
			else
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(0.1));//Firerate
			}
		}
		else if (current_class[client] == _:TFClass_Pyro)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/152.25));//Health Bonus
			TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/12500.0));//Clip Size
			TF2Attrib_SetByName(client,"health regen",((additionalstartmoney+StartMoney)/850.0));//Health Regen
			TF2Attrib_SetByName(client,"weapon burn dmg increased",((additionalstartmoney+StartMoney)/17000.0));//Afterburn Damage
			TF2Attrib_SetByName(client,"weapon burn time increased",((additionalstartmoney+StartMoney)/9000.0));//Afterburn Damage
			if((additionalstartmoney+StartMoney) <= 72000)
			{
				TF2Attrib_SetByName(secondary,"Blast radius increased",((additionalstartmoney+StartMoney)/18000.0));//Blast Radius
			}
			else
			{
				TF2Attrib_SetByName(secondary,"Blast radius increased",(4.0));//Blast Radius
			}
			if((additionalstartmoney+StartMoney) <= 120000)
			{
			TF2Attrib_SetByName(client,"flame_speed",((additionalstartmoney+StartMoney)/10.0));//FlameSpeed
			}
			else
			{
			TF2Attrib_SetByName(client,"flame_speed",(12000.0));//FlameSpeed
			}
		}
		else if (current_class[client] == _:TFClass_DemoMan)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/152.25));//Health Bonus
			TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/11000.0));//Clip Size
			TF2Attrib_SetByName(client,"health regen",((additionalstartmoney+StartMoney)/850.0));//Health Regen
			if((additionalstartmoney+StartMoney) <= 75000)
			{
				TF2Attrib_SetByName(client,"Blast radius increased",((additionalstartmoney+StartMoney)/18000.0));//Blast Radius
			}
			else
			{
				TF2Attrib_SetByName(client,"Blast radius increased",(4.0));//Blast Radius
			}
		}
		else if (current_class[client] == _:TFClass_Heavy)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/108.75));//Health Bonus
			TF2Attrib_SetByName(client,"health regen",((additionalstartmoney+StartMoney)/1000.0));//Health Regen
			TF2Attrib_SetByName(client,"dmg taken increased",(6250.0/(additionalstartmoney+StartMoney)));//Damage Taken Increased(decreased)
			if((additionalstartmoney+StartMoney) <= 40000)
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(additionalstartmoney+StartMoney)));//Firerate
			}
			else
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(0.50));//Firerate
			}
		}
		else if (current_class[client] == _:TFClass_Sniper)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/195.75));//Health Bonus
			TF2Attrib_SetByName(client,"health regen",((additionalstartmoney+StartMoney)/1200.0));//Health Regen
			TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/11000.0));//Clip Size
			if((additionalstartmoney+StartMoney) <= 80000){
			TF2Attrib_SetByName(client,"bullets per shot bonus",((additionalstartmoney+StartMoney)/20000.0));//Bullets Per shot
			}else{
			TF2Attrib_SetByName(client,"bullets per shot bonus",(4.0));//Bullets per shot
			}
			if((additionalstartmoney+StartMoney) <= 200000)
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(additionalstartmoney+StartMoney)));//Firerate
			}
			else
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(0.10));//Firerate
			}
			TF2Attrib_SetByName(client,"faster reload rate",(0.4));//Reload Rate Bonus
		}
		else if (current_class[client] == _:TFClass_Spy)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/348.0));//Health Bonus
			TF2Attrib_SetByName(client,"health regen",((additionalstartmoney+StartMoney)/100.0));//Health Regen
			TF2Attrib_SetByName(client,"mult decloak rate",(20000.0/(additionalstartmoney+StartMoney)));//Decloak Rate
			TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/11000.0));//Clip Size
			if((additionalstartmoney+StartMoney) >= 500000)
			{
				TF2Attrib_SetByName(primary,"fire rate bonus",(75000.0/(additionalstartmoney+StartMoney)));//Firerate
			}
		}
		else if (current_class[client] == _:TFClass_Medic)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/174.0));//Health Bonus
			TF2Attrib_SetByName(client,"health regen",((additionalstartmoney+StartMoney)/750.0));//Health Regen
			TF2Attrib_SetByName(client,"heal rate bonus",((additionalstartmoney+StartMoney)/11000.0));//Heal Rate
			if((additionalstartmoney+StartMoney) >= 50000){
			TF2Attrib_SetByName(client,"override projectile type",(1.0));//Projectile Override
			}
			if((additionalstartmoney+StartMoney) <= 200000)
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(additionalstartmoney+StartMoney)));//Firerate
			}
			else
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(0.10));//Firerate
			}
		}
		}
		else{
		TF2Attrib_SetByName(client,"rage giving scale",(500.0/(mvmadditional*12000)));//Rage gave from being hit
		if((mvmadditional*12000) >= 500000)
		{
			TF2Attrib_SetByName(client,"damage bonus HIDDEN",(1.5));//Overall Damage Bonus
		}
		if((mvmadditional*12000) >= 1500000)
		{
			TF2Attrib_SetByName(client,"damage bonus HIDDEN",(2.3));//Overall Damage Bonus
		}
		if((mvmadditional*12000) <= 80000)
		{
			TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(mvmadditional*12000)));//Firerate
		}
		else
		{
			TF2Attrib_SetByName(client,"fire rate bonus",(0.25));//Firerate
		}
		if((mvmadditional*12000) <= 750000)
		{
			TF2Attrib_SetByName(client,"dmg taken increased",(12000.0/(mvmadditional*12000)));//Damage Taken Increased(decreased)
		}
		else
		{
			TF2Attrib_SetByName(client,"dmg taken increased",(7000.0/(mvmadditional*12000)));//Damage Taken Increased(decreased)
		}
		if((mvmadditional*12000) <= 1000000){
		TF2Attrib_SetByName(client,"damage penalty",((mvmadditional*12000)/17000.0));//Damage Bonus
		TF2Attrib_SetByName(client,"dmg penalty vs players",((mvmadditional*12000)/22000.0));//Damage penalty vs players(ap)
		}else{
		TF2Attrib_SetByName(client,"damage penalty",((mvmadditional*12000)/23000.0));//Damage Bonus
		TF2Attrib_SetByName(client,"dmg penalty vs players",((mvmadditional*12000)/25000.0));//Damage penalty vs players(ap)		
		}
		TF2Attrib_SetByName(client,"maxammo primary increased",((mvmadditional*12000)/5000.0));//Primary Ammo Bonus
		TF2Attrib_SetByName(client,"maxammo secondary increased",((mvmadditional*12000)/5000.0));//Secondary Ammo Bonus
		TF2Attrib_SetByName(client,"ammo regen", 1.0);//Secondary Ammo Bonus
		TF2Attrib_SetByName(client,"faster reload rate",(17500.0/(mvmadditional*12000)));//Reload Rate Bonus
		if((mvmadditional*12000) <= 60000)
		{
			TF2Attrib_SetByName(client,"move speed bonus",((mvmadditional*12000)/16000.0));//Movespeed Bonus
		}
		else
		{
			TF2Attrib_SetByName(client,"move speed bonus",(3.00));//Movespeed Bonus
		}
		if (current_class[client] == _:TFClass_Scout)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((mvmadditional*12000)/230.0));//Health Bonus
			TF2Attrib_SetByName(client,"clip size bonus",((mvmadditional*12000)/12500.0));//Clip Size
			TF2Attrib_SetByName(client,"health regen",((mvmadditional*12000)/1000.0));//Health Regen
			TF2Attrib_SetByName(secondary,"fire rate bonus",3.0);//Firerate
			if((mvmadditional*12000) <= 75000){
			TF2Attrib_SetByName(primary,"bullets per shot bonus",((mvmadditional*12000)/15000.0));//Bullets Per shot
			}else{
			TF2Attrib_SetByName(primary,"bullets per shot bonus",(5.0));//Bullets per shot
			}
			if((mvmadditional*12000) <= 400000)
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(mvmadditional*12000)));//Firerate
			}
			else
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(0.05));//Firerate
			}
			
		}
		else if (current_class[client] == _:TFClass_Soldier)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((mvmadditional*12000)/150.0));//Health Bonus
			TF2Attrib_SetByName(client,"clip size bonus",((mvmadditional*12000)/11000.0));//Clip Size
			TF2Attrib_SetByName(client,"health regen",((mvmadditional*12000)/750.0));//Health Regen
			if((mvmadditional*12000) <= 75000)
			{
				TF2Attrib_SetByName(client,"Blast radius increased",((mvmadditional*12000)/18000.0));//Blast Radius
				TF2Attrib_SetByName(client,"Projectile speed increased",((mvmadditional*12000)/20000.0));//Projectile Speed
			}
			else
			{
				TF2Attrib_SetByName(client,"Blast radius increased",(4.0));//Blast Radius
				TF2Attrib_SetByName(client,"Projectile speed increased",(3.5));//Projectile Speed
			}
			if((mvmadditional*12000) <= 200000)
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(mvmadditional*12000)));//Firerate
			}
			else
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(0.1));//Firerate
			}
		}
		else if (current_class[client] == _:TFClass_Pyro)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((mvmadditional*12000)/175.0));//Health Bonus
			TF2Attrib_SetByName(client,"clip size bonus",((mvmadditional*12000)/12500.0));//Clip Size
			TF2Attrib_SetByName(client,"health regen",((mvmadditional*12000)/850.0));//Health Regen
			TF2Attrib_SetByName(client,"weapon burn dmg increased",((mvmadditional*12000)/17000.0));//Afterburn Damage
			TF2Attrib_SetByName(client,"weapon burn time increased",((mvmadditional*12000)/9000.0));//Afterburn Damage
			if((mvmadditional*12000) <= 72000)
			{
				TF2Attrib_SetByName(secondary,"Blast radius increased",((mvmadditional*12000)/18000.0));//Blast Radius
			}
			else
			{
				TF2Attrib_SetByName(secondary,"Blast radius increased",(4.0));//Blast Radius
			}
			if((mvmadditional*12000) <= 120000)
			{
			TF2Attrib_SetByName(client,"flame_speed",((mvmadditional*12000)/10.0));//FlameSpeed
			}
			else
			{
			TF2Attrib_SetByName(client,"flame_speed",(12000.0));//FlameSpeed
			}
		}
		else if (current_class[client] == _:TFClass_DemoMan)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((mvmadditional*12000)/175.0));//Health Bonus
			TF2Attrib_SetByName(client,"clip size bonus",((mvmadditional*12000)/11000.0));//Clip Size
			TF2Attrib_SetByName(client,"health regen",((mvmadditional*12000)/850.0));//Health Regen
			if((mvmadditional*12000) <= 75000)
			{
				TF2Attrib_SetByName(client,"Blast radius increased",((mvmadditional*12000)/18000.0));//Blast Radius
			}
			else
			{
				TF2Attrib_SetByName(client,"Blast radius increased",(4.0));//Blast Radius
			}
		}
		else if (current_class[client] == _:TFClass_Engineer)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((mvmadditional*12000)/200.0));//Health Bonus
			TF2Attrib_SetByName(client,"clip size bonus",((mvmadditional*12000)/15000.0));//Clip Size
			TF2Attrib_SetByName(client,"health regen",((mvmadditional*12000)/1000.0));//Health Regen
			TF2Attrib_SetByName(client,"engy sentry damage bonus",((mvmadditional*12000)/10000.0));//Sentry Damage
			TF2Attrib_SetByName(client,"engy sentry fire rate increased",(15000.0/(mvmadditional*12000)));//sentry firerate
			TF2Attrib_SetByName(client,"engy building health bonus",(0.00035*(mvmadditional*12000)));//Building Health
			TF2Attrib_SetByName(client,"engy sentry radius increased",(1.4));//Sentry Radius
			TF2Attrib_SetByName(client,"engy dispenser radius increased",(50.0));//Dispencer Radius
			TF2Attrib_SetByName(client,"metal regen",(500.0));//Metal Regen
			TF2Attrib_SetByName(client,"maxammo metal increased",(3.5));//Metal Regen
			if((mvmadditional*12000) <= 60000)
			{
				TF2Attrib_SetByName(pda,"mod wrench builds minisentry",(1.00));//MiniSentry
			}
			else if((mvmadditional*12000) >= 100000)
			{
				TF2Attrib_SetByName(client,"engy building health bonus",(0.0025*(mvmadditional*12000)));//Building Health
				TF2Attrib_SetByName(client,"engy sentry damage bonus",((mvmadditional*12000)/6000.0));//Sentry Damage
				TF2Attrib_SetByName(pda,"engy sentry damage bonus",((mvmadditional*12000)/35000.0));//Sentry Damage
			}
			else if((mvmadditional*12000) >= 500000)
			{
				TF2Attrib_SetByName(client,"engy building health bonus",(0.005*(mvmadditional*12000)));//Building Health
				TF2Attrib_SetByName(client,"engy sentry damage bonus",((mvmadditional*12000)/5500.0));//Sentry Damage
				TF2Attrib_SetByName(pda,"engy sentry damage bonus",((mvmadditional*12000)/30000.0));//Sentry Damage
			}
			if((mvmadditional*12000) <= 75000){
			TF2Attrib_SetByName(client,"bullets per shot bonus",((mvmadditional*12000)/15000.0));//Bullets Per shot
			}else{
			TF2Attrib_SetByName(client,"bullets per shot bonus",(5.0));//Bullets per shot
			}
		}
		else if (current_class[client] == _:TFClass_Heavy)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((mvmadditional*12000)/200.0));//Health Bonus
			TF2Attrib_SetByName(client,"health regen",((mvmadditional*12000)/1000.0));//Health Regen
			TF2Attrib_SetByName(client,"dmg taken increased",(7000.0/(mvmadditional*12000)));//Damage Taken Increased(decreased)
			if((mvmadditional*12000) <= 40000)
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(mvmadditional*12000)));//Firerate
			}
			else
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(0.50));//Firerate
			}
		}
		else if (current_class[client] == _:TFClass_Sniper)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((mvmadditional*12000)/225.0));//Health Bonus
			TF2Attrib_SetByName(client,"health regen",((mvmadditional*12000)/1200.0));//Health Regen
			TF2Attrib_SetByName(client,"clip size bonus",((mvmadditional*12000)/11000.0));//Clip Size
			if((mvmadditional*12000) <= 80000){
			TF2Attrib_SetByName(client,"bullets per shot bonus",((mvmadditional*12000)/20000.0));//Bullets Per shot
			}else{
			TF2Attrib_SetByName(client,"bullets per shot bonus",(4.0));//Bullets per shot
			}
			if((mvmadditional*12000) <= 200000)
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(mvmadditional*12000)));//Firerate
			}
			else
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(0.10));//Firerate
			}
			TF2Attrib_SetByName(client,"faster reload rate",(0.4));//Reload Rate Bonus
		}
		else if (current_class[client] == _:TFClass_Spy)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((mvmadditional*12000)/400.0));//Health Bonus
			TF2Attrib_SetByName(client,"health regen",((mvmadditional*12000)/100.0));//Health Regen
			TF2Attrib_SetByName(client,"mult decloak rate",(20000.0/(mvmadditional*12000)));//Decloak Rate
			TF2Attrib_SetByName(client,"clip size bonus",((mvmadditional*12000)/11000.0));//Clip Size
			if((mvmadditional*12000) >= 500000)
			{
				TF2Attrib_SetByName(primary,"fire rate bonus",(75000.0/(mvmadditional*12000)));//Firerate
			}
		}
		else if (current_class[client] == _:TFClass_Medic)
		{
			TF2Attrib_SetByName(client,"max health additive bonus",((mvmadditional*12000)/200.0));//Health Bonus
			TF2Attrib_SetByName(client,"health regen",((mvmadditional*12000)/750.0));//Health Regen
			TF2Attrib_SetByName(client,"heal rate bonus",((mvmadditional*12000)/11000.0));//Heal Rate
			if((mvmadditional*12000) >= 50000){
			TF2Attrib_SetByName(client,"override projectile type",(1.0));//Projectile Override
			}
			if((mvmadditional*12000) <= 200000)
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(20000.0/(mvmadditional*12000)));//Firerate
			}
			else
			{
				TF2Attrib_SetByName(client,"fire rate bonus",(0.10));//Firerate
			}
		}
	}
}
}

public OnClientDisconnect(client)
{
	PrintToServer("Client #%d Left the Server.", client);
	//if (IsClientInGame(client))
	//{
	//}
}

public OnClientPutInServer(client)
{
	new iCashtmp;
	new maxCashtmp = 0;

	
	decl String:clname[255]
	GetClientName(client, clname, sizeof(clname))
	//PrintToChatAll("putinserver #%d", client);
	PrintToServer("Client #%d Joined the Server.", client);
	//current_class[client] = TF2_GetPlayerClass(client)
	client_no_d_team_upgrade[client] = 1
	client_no_showhelp[client] = 1
	current_class[client] = _:TF2_GetPlayerClass(client)
	//PrintToChat(client, "client changeclass");
	if (!client_respawn_handled[client])
	{
		CreateTimer(0.0, ClChangeClassTimer, GetClientUserId(client));
	}
	if (gamemode == MVM_GAMEMODE)
	{
		iCashtmp = 0
		maxCashtmp = 0
		for (new client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
		{
			if ((client_id != client) && IsValidClient(client_id) && IsPlayerAlive(client_id))
			{
					iCashtmp = client_spent_money[client_id][0]
							   +client_spent_money[client_id][1]
							   +client_spent_money[client_id][2]
							   +client_spent_money[client_id][3];
					if (iCashtmp > maxCashtmp)
					{
						maxCashtmp = iCashtmp
					}
					
			}
		}
		//iCashtmp = GetEntProp(client, Prop_Send, "m_nCurrency", iCashtmp);
		SetEntProp(client, Prop_Send, "m_nCurrency", (maxCashtmp));
	}
	if ((!IsMvM()))
	{
		iCashtmp = 0
		maxCashtmp = 0
		for (new client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
		{
			if ((client_id != client) && IsValidClient(client_id) && IsPlayerAlive(client_id))
			{
					iCashtmp = client_spent_money[client_id][0]
							   +client_spent_money[client_id][1]
							   +client_spent_money[client_id][2]
							   +client_spent_money[client_id][3];
					if (iCashtmp > maxCashtmp)
					{
						maxCashtmp = iCashtmp
					}
					
			}
		}
		//iCashtmp = GetEntProp(client, Prop_Send, "m_nCurrency", iCashtmp);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_SCORE) && (buttons & IN_RELOAD))
	{
		Menu_BuyUpgrade(client, 0);
	}
	new clientcash = GetEntProp(client, Prop_Send, "m_nCurrency", clientcash);
	if(clientcash >= 2147483647 || clientcash < 0){
		SetEntProp(client, Prop_Send, "m_nCurrency", 2147483646);
	}
	if (IsValidClient(client))
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
		if(!IsMvM())
		{
			decl String:Buffer[12]
			Format(Buffer, sizeof(Buffer), "%d$", clientcash); 
			SetHudTextParams(0.9, 0.8, 1.0, 255,0,0,255);
			ShowHudText(client, -1, Buffer);
		}
	}
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//if (isValidVIP(client))
	//{
	//	PrintToChat(client, "AhhhA Vip death client#%d", client)
	//	GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerpos);
//		TF2_RespawnPlayer(client);
	//	CreateTimer(6.5, Resspawnn, client);
	//	CreateTimer(4.0, Resspawnn, GetClientUserId(client));
		
	//}
	FakeClientCommand(client, "menuselect 0");
	new attack = GetClientOfUserId(GetEventInt(event, "attacker"));
	if ((!IsMvM()))
	{
		//PrintToChat(client, "client death start(nomvm)_: %d %d %d", client, attack, assist);
		
		//PrintToChatAll("DEBUG death event: cl_dead%d cl_attack%d cl_assist%d", client, attack, assist)
		if (IsValidClient(attack, false) && IsValidClient(client) && attack != client)
		{
			for (new i = 1; i <= MaxClients; i++) 
			{ 
				if (IsClientInGame(i) && IsValidClient(i)) 
				{
					new clientmoney = GetEntProp(i, Prop_Send, "m_nCurrency", clientmoney);
					SetEntProp(i, Prop_Send, "m_nCurrency", (clientmoney + MoneyBonusKill + ((additionalstartmoney + StartMoney) /400)))
					PrintToChat(i, "+%d$",  (MoneyBonusKill + ((additionalstartmoney + StartMoney)/400)))
				} 
			}  
			additionalstartmoney += (MoneyBonusKill + (StartMoney/400) + (additionalstartmoney/400));
		}
		if(!IsValidClient(client) && attack != client)
		{
			for (new i = 1; i <= MaxClients; i++) 
			{ 
				if (IsClientInGame(i) && IsValidClient(i)) 
				{
					new currentcash = GetEntProp(i, Prop_Send, "m_nCurrency", currentcash);
					SetEntProp(i, Prop_Send, "m_nCurrency", (MoneyBonusKill + currentcash + ((StartMoney+additionalstartmoney)/1200)));
					PrintToChat(i, "+%d$", (MoneyBonusKill + ((StartMoney+additionalstartmoney)/1200)));
				} 
			}  
			additionalstartmoney += (MoneyBonusKill + (StartMoney/1200)+ (additionalstartmoney/1200));		
		}
	}
	else if(attack != client && IsMvM())
	{
		for (new i = 1; i <= MaxClients; i++) 
		{ 
			if (IsClientInGame(i) && IsValidClient(i)) 
			{
				new currentcash = GetEntProp(i, Prop_Send, "m_nCurrency", currentcash);
				new verynice = RoundToNearest((MoneyBonusKill*(mvmadditional/2) + currentcash))
				SetEntProp(i, Prop_Send, "m_nCurrency", verynice)
			} 
		} 
		new nice = RoundToNearest(MoneyBonusKill*(mvmadditional/2))
		additionalstartmoney += nice;		
	}
	if(IsFakeClient(client) || MoneyBonusKill == 5000)//
	{
		new secondary = (GetPlayerWeaponSlot(client,1));
		new primary = (GetPlayerWeaponSlot(client,0));
		TF2Attrib_RemoveAll(client)
		TF2Attrib_RemoveAll(secondary)
		TF2Attrib_RemoveAll(primary)
	}
}//


public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("Round start!")
	//new full_reset = GetEventInt(event, "full_reset");
	MoneyForTeamRatio[RED] = 1.0
	MoneyForTeamRatio[BLUE] = 1.0
	//if (gamemode != MVM_GAMEMODE &&  full_reset)
	//{
	//	for (new client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
	//	{
	//		if (IsValidClient(client_id, false))
	//		{
	//			CreateTimer(0.3, Timer_Resetupgrades, GetClientUserId(client_id));
	//		}
	//	}
		
	//}

}
public Event_teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast)
{
	new slot, i
	new team = GetEventInt(event, "team");
	if (gamemode == MVM_GAMEMODE && team == 3)
	{
		//PrintToChatAll("bot TEAM wins!")
		for (new client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
		{
			if (IsValidClient(client_id))
			{
				
				client_respawn_checkpoint[client_id] = 1
				client_spent_money[client_id] = client_spent_money_mvm_chkp[client_id]
				for (slot = 0; slot < 5; slot++)
				{
					for (i = 0; i < currentupgrades_number[client_id][slot]; i++)
					{
						upgrades_ref_to_idx[client_id][slot][currentupgrades_idx[client_id][slot][i]] = 20000
					}			
					currentupgrades_idx[client_id][slot] = currentupgrades_idx_mvm_chkp[client_id][slot]
					currentupgrades_val[client_id][slot] = currentupgrades_val_mvm_chkp[client_id][slot]
					currentupgrades_number[client_id][slot] = currentupgrades_number_mvm_chkp[client_id][slot]
					for (i = 0; i < currentupgrades_number[client_id][slot]; i++)
					{
						upgrades_ref_to_idx[client_id][slot][currentupgrades_idx[client_id][slot][i]] = i
					}
				}
			}
		}
	}
	else
	{
		//PrintToChatAll("hmuan TEAM wins!")
	}
}
  
public Event_mvm_begin_wave(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_id
	//new i
	//PrintToChatAll("EVENT MVM BEGIN WAVE")
	gamemode = MVM_GAMEMODE
	for (client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
	{
		if (IsValidClient(client_id))
		{
			
	
			//client_spent_money_mvm_chkp[client_id] = client_spent_money[client_id]
			//PrintToChat(client_id, "Current checkpoint money: %d", client_spent_money_mvm_chkp[client_id])
		}
	}
}


public Event_mvm_wave_complete(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_id, slot
	PrintToServer("EVENT MVM WAVE COMPLETE")
	mvmadditional *= 1.25
	mvmadditional += 0.5
	for (client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
	{
		if (IsValidClient(client_id))
		{
		
			client_spent_money_mvm_chkp[client_id] = client_spent_money[client_id]
			for (slot = 0; slot < 5; slot++)
			{
				currentupgrades_number_mvm_chkp[client_id][slot] = currentupgrades_number[client_id][slot]
				currentupgrades_idx_mvm_chkp[client_id][slot] = currentupgrades_idx[client_id][slot]
				currentupgrades_val_mvm_chkp[client_id][slot] = currentupgrades_val[client_id][slot]
			}
			//PrintToChat(client_id, "Current checkpoint money: %d", client_spent_money_mvm_chkp[client_id])
		}
	}
}//Event_tankdown
public Event_tankdown(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++) 
	{ 
		if (IsClientInGame(i) && IsValidClient(i)) 
		{
			new currentcash = GetEntProp(i, Prop_Send, "m_nCurrency", currentcash);
			SetEntProp(i, Prop_Send, "m_nCurrency", ((MoneyBonusKill*mvmadditional*12 + ((additionalstartmoney+StartMoney)/300) + currentcash)));
			PrintToChat(i, "+%d$ - Boss Killed", (MoneyBonusKill*mvmadditional*12)+ ((additionalstartmoney+StartMoney)/300))
		} 
	}  
	additionalstartmoney += (MoneyBonusKill*mvmadditional*12 + ((additionalstartmoney+StartMoney)/300));		
}
public Event_mvm_mission_update(Handle:event, const String:name[], bool:dontBroadcast)
{
	mvmadditional = 1.0;
	for (new client = 0; client < MAXPLAYERS + 1; client++)
	{
		if (IsValidClient(client))
		{
			SetEntProp(client, Prop_Send, "m_nCurrency", (StartMoney + additionalstartmoney));
		}	
	}
	additionalstartmoney = 0;
}
public Event_mvm_wave_failed(Handle:event, const String:name[], bool:dontBroadcast)
{
	mvmadditional = 1.0;
	additionalstartmoney = 0;
	for (new client = 0; client < MAXPLAYERS + 1; client++)
	{
		if (IsValidClient(client))
		{
			ResetClientUpgrades(client)
			SetEntProp(client, Prop_Send, "m_nCurrency", (StartMoney + additionalstartmoney));
			if (!client_respawn_handled[client])
			{
				CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
			}
		}	
	}
}

public Action:mvm_CheckPointAdjustCash(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	//PrintToChatAll("ckpoint adjust")
	
	if (IsValidClient(client) && client_respawn_checkpoint[client])
	{
		new iCash = GetEntProp(client, Prop_Send, "m_nCurrency", iCash);
		SetEntProp(client, Prop_Send, "m_nCurrency", iCash -
				(client_spent_money_mvm_chkp[client][0] 
				+ client_spent_money_mvm_chkp[client][1] 
				+ client_spent_money_mvm_chkp[client][2] 
				+ client_spent_money_mvm_chkp[client][3]) );
		client_respawn_checkpoint[client] = 0
		CreateTimer(0.05, WeaponReGiveUpgrades, GetClientUserId(client));
	}
}


 public Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client))
	{
		//current_class[client] = TF2_GetPlayerClass(client)
		//PrintToChat(client, "client changeteam");
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
		}
		FakeClientCommand(client, "menuselect 0");
	}
}

public Action:jointeam_callback(client, const String:command[], argc) //protection from spectators
{
	decl String:arg[3];
	arg[0] = '\0';
	PrintToServer("jointeam callback #%d", client);
	GetCmdArg(1, arg, sizeof(arg));
	if(StrEqual(arg, "") || StringToInt(arg) == 0)
	{
		//current_class[client] = TF2_GetPlayerClass(client)
		//PrintToChat(client, "client changeteam");
    }
	FakeClientCommand(client, "menuselect 0");
} 

  

public Action:Disp_Help(client, args)
{
	PrintToChat(client, "!uuhelp : display help");
	PrintToChat(client, "!nohelp : stop displaying the repetitive help message");
	PrintToChat(client, "!buy : display buy menu");
	PrintToChat(client, "<showscore> + <reload>: display buy menu (by default ");
	PrintToChat(client, "To get your money/all your money back, change loadout or class.");
}
public Action:ResetPlayers(client, args)
{
	for (new i = 1; i <= MaxClients; i++) 
	{ 
		if (IsClientInGame(i)) 
		{ 
			// Only trigger for client indexes actually in the game 
			ResetClientUpgrades(i);
		} 
	}
	additionalstartmoney = 0;
}

//!uusteamup -> toggle shows team upgrades in chat for a client

public Action:StopDisp_chatHelp(client, args)
{
	client_no_showhelp[client] = 1
}


public Action:ShowSpentMoney(client, args)
{
	for(new i = 0; i < MAXPLAYERS + 1; i++)
	{
		if (IsValidClient(i))
		{
			decl String:cstr[255]
			GetClientName(i, cstr, 255)
			PrintToChat(client, "**%s**\n**", cstr)
			for (new s = 0; s < 5; s++)
			{
				PrintToChat(client, "%s : %d$ of upgrades", current_slot_name[s], client_spent_money[i][s])
			}
		}
	}
}

public Action:ShowTeamMoneyRatio(admid, args)
{
	for(new i = 0; i < MAXPLAYERS + 1; i++)
	{
		if (IsValidClient(i))
		{
			decl String:cstr[255]
			GetClientName(i, cstr, 255)
			PrintToChat(admid, "**%s**\n**", cstr)
			for (new s = 0; s < 5; s++)
			{
				PrintToChat(admid, "%s : %d$ of upgrades", current_slot_name[s], client_spent_money[i][s])
			}
		}
	}
}

public Action:ReloadCfgFiles(client, args)
{
	_load_cfg_files()	   
	for (new cl = 0; cl < MAXPLAYERS + 1; cl++)
	{
		if (IsValidClient(cl))
		{
			ResetClientUpgrades(cl)
			current_class[cl] = _:TF2_GetPlayerClass(client)
			//PrintToChat(cl, "client changeclass");
			if (!client_respawn_handled[cl])
			{
				CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(cl));
			}
		}	
	}
}


//admin cmd: enable/disable menu "buy an additional weapon"
public Action:EnableBuyNewWeapon(client, args)
{
	new String:arg1[8];
	new arg;
	
	BuyNWmenu_enabled = 0
	if (GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToInt(arg1);
		if (arg == 1)
		{
			BuyNWmenu_enabled = 1
		}
	}
}

public Action:Menu_QuickBuyUpgrade(mclient, args)
{
	new String:arg1[128];
	new arg1_ = -1;
	new String:arg2[128];
	new arg2_ = -1;
	new String:arg3[128];
	new arg3_ = -1;
	new String:arg4[128];
	new arg4_ = 0;
	new	bool:flag = false
	if (IsValidClient(mclient) && IsPlayerAlive(mclient))
	{
		if (GetCmdArg(1, arg1, sizeof(arg1)))
		{
			arg1_ = -1
			arg2_ = -1
			arg3_ = -1
			arg1_ = StringToInt(arg1);//SLOT USED
			if (arg1_ > -1 && arg1_ < 5 && GetCmdArg(2, arg2, sizeof(arg2)))
			{
				new w_id = currentitem_catidx[mclient][arg1_]
				arg2_ = StringToInt(arg2);
				if (GetCmdArg(3, arg3, sizeof(arg3)))
				{
					arg3_ = StringToInt(arg3);
					arg4_ = 1
					if (GetCmdArg(4, arg4, sizeof(arg4)))
					{
						arg4_ = StringToInt(arg4);
						if (arg4_ >= 1000)
						{
							arg4_ = 1000
						}
						if (arg4_ < 1)
						{
							arg4_ = 1
						}
					}
					if (arg2_ > -1 && arg2_ < given_upgrd_list_nb[w_id]
					&& given_upgrd_list[w_id][arg2_][arg3_])
					{
						new iCash = GetEntProp(mclient, Prop_Send, "m_nCurrency", iCash);
						new upgrade_choice = given_upgrd_list[w_id][arg2_][arg3_]
						new inum = upgrades_ref_to_idx[mclient][arg1_][upgrade_choice]
						if (inum == 20000)
						{
							inum = currentupgrades_number[mclient][arg1_]
							currentupgrades_number[mclient][arg1_]++
							upgrades_ref_to_idx[mclient][arg1_][upgrade_choice] = inum;
							currentupgrades_idx[mclient][arg1_][inum] = upgrade_choice 
							currentupgrades_val[mclient][arg1_][inum] = upgrades_i_val[upgrade_choice];
						}
						new idx_currentupgrades_val = RoundToNearest((currentupgrades_val[mclient][arg1_][inum] - upgrades_i_val[upgrade_choice])
																 / upgrades_ratio[upgrade_choice])
						new Float:upgrades_val = currentupgrades_val[mclient][arg1_][inum]
						new up_cost = upgrades_costs[upgrade_choice]
						up_cost /= 2
						if (arg1_ == 1)
						{
							up_cost = RoundToNearest((up_cost * 1.0) * 0.9)
						}
						if (inum != 20000 && upgrades_ratio[upgrade_choice])
						{
							new t_up_cost = 0
							for (new idx = 0; idx < arg4_; idx++)
							{
								t_up_cost += up_cost + RoundToNearest(up_cost * (
															idx_currentupgrades_val
																* upgrades_costs_inc_ratio[upgrade_choice]))
								idx_currentupgrades_val++		
								upgrades_val += upgrades_ratio[upgrade_choice]
							}
												
							if (t_up_cost < 0.0)
							{
								t_up_cost *= -1;
								if (t_up_cost < (upgrades_costs[upgrade_choice] / 2))
								{
									t_up_cost = upgrades_costs[upgrade_choice] / 2
								}
							}
							if (iCash < t_up_cost)
							{
								new String:buffer[128]
								Format(buffer, sizeof(buffer), "%T", "You have not enough money!!", mclient);
								PrintToChat(mclient, buffer);
							}
							else
							{
								if ((upgrades_ratio[upgrade_choice] > 0.0 && upgrades_val >= upgrades_m_val[upgrade_choice])
								|| (upgrades_ratio[upgrade_choice] < 0.0 && upgrades_val <= upgrades_m_val[upgrade_choice]))
								{
									PrintToChat(mclient, "Maximum upgrade value reached for this category.");
								}
								else
								{
									flag = true
									client_iCash[mclient] = iCash - t_up_cost
									SetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
									currentupgrades_val[mclient][arg1_][inum] = upgrades_val
									client_spent_money[mclient][arg1_] += t_up_cost
									new totalmoney = 0
								
									for (new s = 0; s < 5; s++)
									{
										totalmoney += client_spent_money[mclient][s]
									}
									GiveNewUpgradedWeapon_(mclient, arg1_)
									PrintToChat(mclient, "yep");
								}
							}
						}
					}
				}
			}
		}
		if (!flag)
		{
			PrintToChat(mclient, "Usage: /qbuy [slot] [upgrade catagory - 1] [upgrade # - 1] [# of buys]");
			PrintToChat(mclient, "slot : 0 primary 1 secondary 2 melee 3 special 4 body");
			PrintToChat(mclient, "ex./qbuy 4 0 1 10, hp regen add = 12 x 10");
		}
	}
	else
	{
		PrintToChat(mclient, "You cannot quick-buy while dead.");
	}
	return Plugin_Continue; 
}
GetWeaponsCatKVSize(Handle:kv)
{
	new siz = 0
	do
	{
		if (!KvGotoFirstSubKey(kv, false))
		{
			// Current key is a regular key, or an empty section.
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				siz++
			}
		}
	}
	while (KvGotoNextKey(kv, false));
	return siz
}

BrowseWeaponsCatKV(Handle:kv)
{
	new u_id = 0
	new t_idx = 0
	SetTrieValue(_weaponlist_names, "body_scout" , t_idx++, true);
	SetTrieValue(_weaponlist_names, "body_sniper" , t_idx++, true);
	SetTrieValue(_weaponlist_names, "body_soldier" , t_idx++, true);
	SetTrieValue(_weaponlist_names, "body_demoman" , t_idx++, true);
	SetTrieValue(_weaponlist_names, "body_medic" , t_idx++, true);
	SetTrieValue(_weaponlist_names, "body_heavy" , t_idx++, true);
	SetTrieValue(_weaponlist_names, "body_pyro" , t_idx++, true);
	SetTrieValue(_weaponlist_names, "body_spy" , t_idx++, true);
	SetTrieValue(_weaponlist_names, "body_engie" , t_idx++, true);
	decl String:Buf[128];
	do
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			BrowseWeaponsCatKV(kv);
			KvGoBack(kv);
		}
		else
		{
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				KvGetSectionName(kv, Buf, sizeof(Buf));
				wcnamelist[u_id] = Buf
				KvGetString(kv, "", Buf, 64);
				if (SetTrieValue(_weaponlist_names, Buf, t_idx, false))
				{
					t_idx++
				}
				GetTrieValue(_weaponlist_names, Buf, wcname_l_idx[u_id])
				//PrintToServer("weapon list %d: %s - %s(%d)", u_id,wcnamelist[u_id], Buf, wcname_l_idx[u_id])
				u_id++;
				//PrintToServer("%s linked : %s->%d",  wcnamelist[u_id], Buf,wcname_l_idx[u_id])
				//PrintToServer("value:%s", Buf)
			}
		}
	}
	while (KvGotoNextKey(kv, false));
}

BrowseAttributesKV(Handle:kv)
{
	decl String:Buf[128];
	do
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			//PrintToServer("\nAttribute #%d", _u_id)
			BrowseAttributesKV(kv);
			KvGoBack(kv);
		}
		else
		{
			// Current key is a regular key, or an empty section.
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				KvGetSectionName(kv, Buf, sizeof(Buf));
				if (!strcmp(Buf,"ref"))
				{
					KvGetString(kv, "", Buf, 64);
					upgradesNames[_u_id] = Buf
					SetTrieValue(_upg_names, Buf, _u_id, true);
				//	PrintToServer("ref:%s --uid:%d", Buf, _u_id)
				}
				if (!strcmp(Buf,"name"))
				{
					KvGetString(kv, "", Buf, 64);
					if (strcmp(Buf,""))
					{
						//PrintToServer("Name:%s-", Buf)
						//new _:att_id = TF2II_GetAttributeIDByName(Buf)
						for (new i_ = 1; i_ < MAX_ATTRIBUTES; i_++)
						{
							if (!strcmp(upgradesWorkNames[i_], Buf))
							{
								upgrades_to_a_id[_u_id] = i_
							//	PrintToServer("up_ref/id[%d]:%s/%d", _u_id, Buf, upgrades_to_a_id[_u_id])
								break;
							}
						}
					}
				}
				if (!strcmp(Buf,"cost"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_costs[_u_id] = StringToInt(Buf)
					//PrintToServer("cost:%d", upgrades_costs[_u_id])
				}
				if (!strcmp(Buf,"increase_ratio"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_costs_inc_ratio[_u_id] = StringToFloat(Buf)
					//PrintToServer("increase rate:%f", upgrades_costs_inc_ratio[_u_id])
				}
				if (!strcmp(Buf,"value"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_ratio[_u_id] = StringToFloat(Buf)
					//PrintToServer("val:%f", upgrades_ratio[_u_id])
				}
				if (!strcmp(Buf,"init"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_i_val[_u_id] = StringToFloat(Buf)
					//PrintToServer("init:%f", upgrades_i_val[_u_id])
				}
				if (!strcmp(Buf,"max"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_m_val[_u_id] = StringToFloat(Buf)
					//PrintToServer("max:%f", upgrades_m_val[_u_id])
					_u_id++
				}
			}
		}
	}
	while (KvGotoNextKey(kv, false));
	return (_u_id)
}


BrowseAttListKV(Handle:kv, &w_id = -1, &w_sub_id = -1, w_sub_att_idx = -1, level = 0)
{
	decl String:Buf[128];
	do
	{
		KvGetSectionName(kv, Buf, sizeof(Buf));
		if (level == 1)
		{
			if (!GetTrieValue(_weaponlist_names, Buf, w_id))
			{
				PrintToServer("[uu_lists] Malformated uu_lists | uu_weapon.txt file?: %s was not found", Buf)
			}
			w_sub_id = -1;
			given_upgrd_classnames_tweak_nb[w_id] = 0
		}
		if (level == 2)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf))
			if (!strcmp(Buf, "special_tweaks_listid"))
			{

				KvGetString(kv, "", Buf, 64);
				//PrintToServer("  ->Sublist/#%s -- #%d", Buf, w_id)
				given_upgrd_classnames_tweak_idx[w_id] = StringToInt(Buf)
			}
			else
			{
				w_sub_id++
			//	PrintToServer("section #%s", Buf)
				given_upgrd_classnames[w_id][w_sub_id] = Buf
				given_upgrd_list_nb[w_id]++
				w_sub_att_idx = 0
			}
		}
		if (KvGotoFirstSubKey(kv, false))
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			BrowseAttListKV(kv, w_id, w_sub_id, w_sub_att_idx, level + 1);
			KvGoBack(kv);
		}
		else
		{
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				new attr_id
				KvGetSectionName(kv, Buf, sizeof(Buf));
			//	PrintToServer("section:%s", Buf)
				if (strcmp(Buf, "special_tweaks_listid"))
				{
					KvGetString(kv, "", Buf, 64);
					if (w_sub_id == given_upgrd_classnames_tweak_idx[w_id])
					{
						given_upgrd_classnames_tweak_nb[w_id]++
						if (!GetTrieValue(_spetweaks_names, Buf, attr_id))
						{
							PrintToServer("[uu_lists] Malformated uu_lists | uu_specialtweaks.txt file?: %s was not found", Buf)
						}
					}
					else
					{
						if (!GetTrieValue(_upg_names, Buf, attr_id))
						{
							PrintToServer("[uu_lists] Malformated uu_lists | uu_attributes.txt file?: %s was not found", Buf)
						}
					}
			//		PrintToServer("             **list%d sublist%d %d :%s(%d)", w_sub_att_idx, w_id, w_sub_id, Buf, attr_id)
					given_upgrd_list[w_id][w_sub_id][w_sub_att_idx] = attr_id
					w_sub_att_idx++
				}
			}
		}
	}
	while (KvGotoNextKey(kv, false));
}
BrowseSpeTweaksKV(Handle:kv, &u_id = -1, att_id = -1, level = 0)
{
	decl String:Buf[128];
	new attr_ref
	do
	{
		if (level == 2)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			u_id++
			SetTrieValue(_spetweaks_names, Buf, u_id)
			upgrades_tweaks[u_id] = Buf
			upgrades_tweaks_nb_att[u_id] = 0
			att_id = 0
		}
		if (level == 3)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			if (!GetTrieValue(_upg_names, Buf, attr_ref))
			{
				PrintToServer("[spetw_lists] Malformated uu_specialtweaks | uu_attribute.txt file?: %s was not found", Buf)
			}
		//	PrintToServer("Adding Special tweak [%s] attribute %s(%d)", upgrades_tweaks[u_id], Buf, attr_ref)
			upgrades_tweaks_att_idx[u_id][att_id] = attr_ref
			KvGetString(kv, "", Buf, 64);
			upgrades_tweaks_att_ratio[u_id][att_id] = StringToFloat(Buf)
		//	PrintToServer("               ratio => %f)", upgrades_tweaks_att_ratio[u_id][att_id])
			upgrades_tweaks_nb_att[u_id]++
			att_id++
		}
		if (KvGotoFirstSubKey(kv, false))
		{
			BrowseSpeTweaksKV(kv, u_id, att_id, level + 1);
			KvGoBack(kv);
		}
	}
	while (KvGotoNextKey(kv, false));
	return (u_id)
}

public _load_cfg_files()
{
	

	_upg_names = CreateTrie();
	_weaponlist_names = CreateTrie();
	_spetweaks_names = CreateTrie();

	new Handle:kv = CreateKeyValues("uu_weapons");
	kv = CreateKeyValues("weapons");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_weapons.txt");
	if (!KvGotoFirstSubKey(kv))
	{
		return false;
	}
	new siz = GetWeaponsCatKVSize(kv)
	PrintToServer("[UberUpgrades] %d weapons loaded", siz)
	KvRewind(kv);
	BrowseWeaponsCatKV(kv)
	CloseHandle(kv);


	kv = CreateKeyValues("attribs");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_attributes.txt");
	_u_id = 1
	PrintToServer("browsin uu attribs (kvh:%d)", kv)
	BrowseAttributesKV(kv)
	PrintToServer("[UberUpgrades] %d attributes loaded", _u_id)
	CloseHandle(kv);



	new static_uid = 1
	kv = CreateKeyValues("special_tweaks");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_specialtweaks.txt");
	BrowseSpeTweaksKV(kv, static_uid)
	PrintToServer("[UberUpgrades] %d special tweaks loaded", static_uid)
	CloseHandle(kv);

	static_uid = 1
	kv = CreateKeyValues("lists");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_lists.txt");
	BrowseAttListKV(kv, static_uid)
	PrintToServer("[UberUpgrades] %d lists loaded", static_uid)
	CloseHandle(kv);
	
	// new Handle:fi = OpenFile("yepyep2.txt", "w");
	// new Handle:_tmptmptmp = CreateTrie();
	// for (new i = 0; i < siz; i++)
	// {
		// for (j = 0; j < given_upgrd_list_nb[i]; j++)
		// {
			// new _:k
			// if (GetTrieValue(_tmptmptmp, given_upgrd_classnames[i][j], k) == false)
			// {
				// SetTrieValue(_tmptmptmp, given_upgrd_classnames[i][j], 1)
				// new String:tmp[256]
				// Format(tmp, sizeof(tmp), "\t\"%s\"",given_upgrd_classnames[i][j])
				// WriteFileLine(fi, tmp)
				// WriteFileLine(fi,"\t{")
				// Format(tmp, sizeof(tmp), "\t\t\"en\"\t\t\"%s\"",given_upgrd_classnames[i][j])
				// WriteFileLine(fi,tmp)
				// WriteFileLine(fi,"\t}")
			// }
		// }
	// }
	// ClearTrie(_tmptmptmp)
	// CloseHandle(fi)
	//TODO -> buyweapons.cfg
	{
	newweaponidx[0] = 1152;
	newweaponcn[0] = "tf_weapon_grapplinghook";
	newweaponmenudesc[0] = "Grappling Hook";
	}
	CreateBuyNewWeaponMenu()
	return true
}
stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
}

//Initialize New Weapon menu
public CreateBuyNewWeaponMenu()
{
	BuyNWmenu = CreateMenu(MenuHandler_BuyNewWeapon);
	
	SetMenuTitle(BuyNWmenu, "Buy Action Slot for 7500$:");
	
	for (new i=0; i < NB_B_WEAPONS; i++)
	{
		AddMenuItem(BuyNWmenu, "tweak", newweaponmenudesc[i]);
	}
	SetMenuExitButton(BuyNWmenu, true);
}

//Initialize menus , CVARs, con cmds and timers handlers on plugin load
public UberShopinitMenusHandlers()
{
	LoadTranslations("tf2items_uu.phrases.txt");
	gamemode = -1
	BuyNWmenu_enabled = true
	
	cvar_uu_version = CreateConVar("uberupgrades_version", UU_VERSION, "The Plugin Version. Don't change.", FCVAR_NOTIFY);
	//cvar_CostIncrease_ratio_default = 	CreateConVar("sm_uu_costincrease_ratio_defaut", "0.5", "Each time an upgrade is bought, next one will be increased by this ratio if not defined in uu_attributes.txt(Not yet implemented): default 0.5");
	cvar_MoneyBonusKill = 				CreateConVar("sm_uu_moneybonuskill", "25", "Sets the money bonus a client gets for killing: default 100");
	cvar_AutoMoneyForTeamRatio = 			CreateConVar("sm_uu_automoneyforteam_ratio", "1", "If set to 1, the plugin will manage money balancing");
	////cvar_MoneyForTeamRatioRed = 			CreateConVar("sm_uu_moneyforteam_ratio", "1.00", "Sets the ratio of (money + money spent on upgrades) from a client that the team gets when killing him: default 0.05");
	//cvar_MoneyForTeamRatioBlue = 			CreateConVar("sm_uu_moneyforteam_ratio", "1.00", "Sets the ratio of (money + money spent on upgrades) from a client that the team gets when killing him: default 0.05");
	cvar_StartMoney = 					CreateConVar("sm_uu_startmoney", "20000", "Sets the starting money: default 20000");
	cvar_TimerMoneyGive_BlueTeam = 		CreateConVar("sm_uu_timermoneygive_blueteam", "0", "Sets the money blue team get every timermoney event: default 100");
	cvar_TimerMoneyGive_RedTeam =  		CreateConVar("sm_uu_timermoneygive_redteam", "0", "Sets the money blue team get every timermoney event: default 100");
	if (cvar_uu_version) //Compile warning fast bypass
	{
	}
	//CostIncrease_ratio_default  = GetConVarFloat(cvar_CostIncrease_ratio_default)
	MoneyBonusKill = GetConVarInt(cvar_MoneyBonusKill)
	MoneyForTeamRatio[RED]  = 1.0
	MoneyForTeamRatio[BLUE]  = 1.0
	TimerMoneyGive_BlueTeam = GetConVarInt(cvar_TimerMoneyGive_BlueTeam)
	TimerMoneyGive_RedTeam = GetConVarInt(cvar_TimerMoneyGive_RedTeam)
	StartMoney = GetConVarInt(cvar_StartMoney)
	
	RegConsoleCmd("uuhelp", Disp_Help)
	RegAdminCmd("us_enable_buy_new_weapon", EnableBuyNewWeapon, ADMFLAG_GENERIC, "dont change this")
	RegAdminCmd("uu_enable_buy_new_weapon", EnableBuyNewWeapon, ADMFLAG_GENERIC, "dont change this")
	RegAdminCmd("sm_uuspentmoney", ShowSpentMoney, ADMFLAG_GENERIC, "Shows everyones upgrades")
	RegAdminCmd("reload_cfg", ReloadCfgFiles, ADMFLAG_GENERIC, "Reloads All CFG files for Uberupgrades")
	RegConsoleCmd("uu", Disp_Help)
	RegConsoleCmd("nohelp", StopDisp_chatHelp)
	//RegAdminCmd("sm_attr", DisplayCurrentUps, 0, "Show what upgrades you have")//DisplayCurrentUps
	RegConsoleCmd("sm_uuaide", Disp_Help)
	RegConsoleCmd("sm_aide", Disp_Help)
	RegAdminCmd("sm_buy", Menu_BuyUpgrade, 0, "Buy Menu")
	RegAdminCmd("sm_qbuy", Menu_QuickBuyUpgrade, 0, "Buy upgrades in a large quantity")
	RegAdminCmd("buy", Menu_BuyUpgrade, 0, "Buy Menu")
	RegAdminCmd("qbuy", Menu_QuickBuyUpgrade, 0, "Buy upgrades in a large quantity")//ToggleKillMessage
	RegAdminCmd("qb", Menu_QuickBuyUpgrade, 0, "Buy upgrades in a large quantity")
	RegAdminCmd("sm_resetallplayers", ResetPlayers, ADMFLAG_ROOT, "Remove Everyones Upgrades")
	//RegConsoleCmd("sp_buy", Menu_SpecialBuyUpgrade)
	RegConsoleCmd("byu", Menu_BuyUpgrade)
	RegConsoleCmd("BUY", Menu_BuyUpgrade)
	HookEventEx("player_hurt", Event_Playerhurt, EventHookMode_Pre)
	HookEvent("player_spawn", Event_PlayerreSpawn)
	HookEvent("post_inventory_application", Event_PlayerreSpawn)
	HookEvent("mvm_wave_failed", Event_mvm_wave_failed)
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre)
	HookEvent("player_changeclass", Event_PlayerChangeClass)
	HookEvent("player_class", Event_PlayerChangeClass)
	HookEvent("player_team", Event_PlayerChangeTeam)
	AddCommandListener(jointeam_callback, "jointeam");
	//HookEvent("item_up", Event_PlayerreSpawn)
	//HookEvent("mm_lobby_member_join", Event_OnClientPutInServer
	
	
	HookEvent("mvm_begin_wave", Event_mvm_begin_wave)
	HookEvent("teamplay_round_win", Event_teamplay_round_win)
	HookEvent("mvm_mission_update", Event_mvm_mission_update);//mvm_tank_destroyed_by_players
	HookEvent("mvm_wave_complete", Event_mvm_wave_complete);
	//HookEvent("mvm_tank_destroyed_by_players", Event_tankdown);
	HookEvent("eyeball_boss_killed", Event_tankdown);
	HookEvent("merasmus_killed", Event_tankdown);
	HookEvent("pumpkin_lord_killed", Event_tankdown);
	
	Timers_[0] = CreateTimer(20.0, Timer_GetConVars, _, TIMER_REPEAT);
	Timers_[1] = CreateTimer(20.0, Timer_GiveSomeMoney, _, TIMER_REPEAT);
	
	moneyLevels[0] = 125;
	for (new level = 1; level < MAXLEVEL_D; level++)
	{
		moneyLevels[level] = (125 + ((level + 1) * 50)) + moneyLevels[level - 1];
	}
}

//Initialize menus , CVARs, con cmds and timers handlers on plugin load
public UberShopUnhooks()
{

	UnhookEvent("player_spawn", Event_PlayerreSpawn)
	UnhookEvent("player_changeclass", Event_PlayerChangeClass)
	UnhookEvent("player_class", Event_PlayerChangeClass)
	UnhookEvent("player_team", Event_PlayerChangeTeam)
	
	UnhookEvent("post_inventory_application", Event_PlayerreSpawn)
	
	UnhookEvent("mvm_begin_wave", Event_mvm_begin_wave)
	UnhookEvent("mvm_wave_failed", Event_mvm_wave_failed)
	 
	KillTimer(Timers_[0]);
	KillTimer(Timers_[1]);
}

public GetUpgrade_CatList(String:WCName[])
{
	new i, wis, w_id
	
	wis = 0// wcname_idx_start[cl_class]
	//PrintToChatAll("Class: %d; WCname:%s", cl_class, WCName);
	for (i = wis, w_id = -1; i < WCNAMELISTSIZE; i++)
	{
		if (!strcmp(wcnamelist[i], WCName, false))
		{
			w_id = wcname_l_idx[i]
			//PrintToChatAll("wid found; %d", w_id)
			return w_id
		}
	}
	if (w_id < -1)
	{
		PrintToServer("UberUpgrade error: #%s# was not a valid weapon classname..", WCName)
	}
	return w_id
}

public void OnPluginStart()
{
	//TODO CVARS cvar_StartMoney = CreateConVar("sm_uu_moneystart", "300", "Sets the starting currency used for upgrades. Default: 500");
	//cvar_TimerMoneyGiven_BlueTeam = CreateConVar("sm_uu_timermoneygive_blueteam", "25", "Sets the currency you obtain on kill. Default: 25");
	//cvar_KillMoneyRatioForTeam = CreateConVar("sm_uu_moneyonkill", "", "Sets the currency you obtain on kill. Default: 25");
	UberShopinitMenusHandlers()
	LoadTranslations("tf2items_uu.phrases.txt");
	UberShopDefineUpgradeTabs()
	GameRules_SetProp("m_bPlayingMedieval", 0)
	mvmadditional = 1.0;
	for (new client = 0; client < MAXPLAYERS + 1; client++)
	{
		if (IsValidClient(client))
		{
			client_no_d_team_upgrade[client] = 1
			client_no_showhelp[client] = 0//
			ResetClientUpgrades(client)
			current_class[client] = _:TF2_GetPlayerClass(client)
			//PrintToChat(client, "client changeclass");
			if (!client_respawn_handled[client])
			{
				CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
			}
			SetEntProp(client, Prop_Send, "m_nCurrency", StartMoney+additionalstartmoney);
		}	
	}
	return
}

public OnPluginEnd()
{
	PrintToServer("Plugin ends.")
	UberShopUnhooks()
	PrintToServer("Plugin ends -- Unload complete.")
}
public bool:GiveNewWeapon(client, slot)
{
	new Handle:newItem = TF2Items_CreateItem(PRESERVE_ATTRIBUTES || FORCE_GENERATION);
	new Flags = 0;
	
	new itemDefinitionIndex = currentitem_idx[client][slot]
	TF2Items_SetItemIndex(newItem, itemDefinitionIndex);
	currentitem_level[client][slot] = 242
	
	TF2Items_SetLevel(newItem, 242);
	
	Flags = PRESERVE_ATTRIBUTES || FORCE_GENERATION;
	
	TF2Items_SetFlags(newItem, Flags);
	
	TF2Items_SetClassname(newItem, currentitem_classname[client][slot]);

	slot = 6
	new weaponIndextorem_ = GetPlayerWeaponSlot(client, slot);
	new weaponIndextorem = weaponIndextorem_;
	
	
	new entity = TF2Items_GiveNamedItem(client, newItem);
	if (IsValidEntity(entity))
	{
		while ((weaponIndextorem = GetPlayerWeaponSlot(client, slot)) != -1)
		{
			RemovePlayerItem(client, weaponIndextorem);
			RemoveEdict(weaponIndextorem);
		}
		client_new_weapon_ent_id[client] = entity
		EquipPlayerWeapon(client, entity);
		return true;
	}
	else
	{
		return false
	}
}

public GiveNewUpgrade(client, slot, uid, a)
{
	//new itemDefinitionIndex = currentitem_idx[client][slot]
		
//	PrintToChatAll("--Give new upgrade", slot);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
	new iEnt;//
	if (slot == 4 && IsValidEntity(client))
	{
		iEnt = client
	}
	else if (currentitem_level[client][slot] != 242)
	{
		iEnt = currentitem_ent_idx[client][slot]
	}
	else
	{
		slot = 3
		iEnt = client_new_weapon_ent_id[client]
	}
	if (IsValidEntity(iEnt) && strcmp(upgradesWorkNames[upgrades_to_a_id[uid]], ""))
	{
		//PrintToChatAll("trytoremov slot %d", slot);
		TF2Attrib_SetByName(iEnt, upgradesWorkNames[upgrades_to_a_id[uid]],
								  currentupgrades_val[client][slot][a]);									  
		TF2Attrib_ClearCache(iEnt)	
	}
}

public GiveNewUpgradedWeapon_(client, slot)
{
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
	new a, iNumAttributes;
	new iEnt;
	iNumAttributes = currentupgrades_number[client][slot]
	if(currentitem_ent_idx[client][0] == 1101)
	{
		iEnt = currentitem_ent_idx[client][0]
	}
	if (slot == 4 && IsValidEntity(client))
	{
		iEnt = client
	}
	else if (currentitem_level[client][slot] != 242)
	{
		iEnt = currentitem_ent_idx[client][slot]
	}
	else
	{
		slot = 3
		iEnt = client_new_weapon_ent_id[client]
	}
	if (IsValidEntity(iEnt))
	{
		//PrintToChatAll("trytoremov slot %d", slot);
		if( iNumAttributes > 0 )
		{
			for( a = 0; a < 42 && a < iNumAttributes ; a++ )
			{
				new uuid = upgrades_to_a_id[
										currentupgrades_idx[client][slot][a]]
				if (strcmp(upgradesWorkNames[uuid], ""))
				{
					TF2Attrib_SetByName(iEnt, upgradesWorkNames[uuid],
											  currentupgrades_val[client][slot][a]);
				}
			}
		}
	}
}



public	is_client_got_req(mclient, upgrade_choice, slot, inum)
{
	new iCash = GetEntProp(mclient, Prop_Send, "m_nCurrency", iCash);
	new up_cost = upgrades_costs[upgrade_choice]
	new max_ups = currentupgrades_number[mclient][slot]
	up_cost /= 2
	client_iCash[mclient] = iCash;
	if (slot == 1)
	{
		up_cost = RoundToNearest((up_cost * 1.0) * 0.9)
	}
	if (inum != 20000 && upgrades_ratio[upgrade_choice])
	{
		up_cost += RoundToNearest(up_cost * (
											(currentupgrades_val[mclient][slot][inum] - upgrades_i_val[upgrade_choice])
												/ upgrades_ratio[upgrade_choice]) 
											* upgrades_costs_inc_ratio[upgrade_choice])
		if (up_cost < 0.0)
		{
			up_cost *= -1;
			if (up_cost < (upgrades_costs[upgrade_choice] / 2))
			{
				up_cost = upgrades_costs[upgrade_choice] / 2
			}
		}
	}
	if (iCash < up_cost)
	{
		new String:buffer[128]
		Format(buffer, sizeof(buffer), "%T", "You have not enough money!!", mclient);
		PrintToChat(mclient, buffer);
		return 0
	}
	else
	{
		if (inum != 20000)
		{	
			if (currentupgrades_val[mclient][slot][inum] == upgrades_m_val[upgrade_choice])
			{
				PrintToChat(mclient, "You already have reached the maximum upgrade for this category.");
				return 0
			}
		}
		else
		{
			if (max_ups >= MAX_ATTRIBUTES_ITEM)
			{
				PrintToChat(mclient, "You have reached the maximum number of upgrade category for this item.");
				return 0
			}
		}
		// decl String:clname[255]
		// new String:strsn[128]
		// GetClientName(mclient, clname, sizeof(clname))
		// if (slot != 4)
		// {
			// strsn = current_slot_name[slot]
		// }
		// else
		// {
			// strsn = "Body Armor"
		// }
		// for (new i = 1; i < MAXPLAYERS + 1; i++)
		// {
			// if (IsValidClient(i) && !client_no_d_team_upgrade[i])
			// {
				// PrintToChat(i,"%s : [%s upgrade] - %s", 
				// clname, strsn, upgradesNames[upgrade_choice]);
			// }
		// }
		
		client_iCash[mclient] = iCash - up_cost
		SetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
		client_spent_money[mclient][slot] += up_cost
		new totalmoney = 0
		for (new s = 0; s < 5; s++)
		{
			totalmoney += client_spent_money[mclient][s]
		}
		return 1
	}
}

public	check_apply_maxvalue(mclient, slot, inum, upgrade_choice)
{
	if ((upgrades_ratio[upgrade_choice] > 0.0
		 && currentupgrades_val[mclient][slot][inum] > upgrades_m_val[upgrade_choice])
		|| (upgrades_ratio[upgrade_choice] < 0.0 
			&& currentupgrades_val[mclient][slot][inum] < upgrades_m_val[upgrade_choice]))
		{
			currentupgrades_val[mclient][slot][inum] = upgrades_m_val[upgrade_choice]
		}
}

public UpgradeItem(mclient, upgrade_choice, inum, Float:ratio)
{
	new slot = current_slot_used[mclient]
	//PrintToChat(mclient, "Entering #upprimary");
	
	
	if (inum == 20000)
	{
		inum = currentupgrades_number[mclient][slot]
		upgrades_ref_to_idx[mclient][slot][upgrade_choice] = inum;
		currentupgrades_idx[mclient][slot][inum] = upgrade_choice 
		currentupgrades_val[mclient][slot][inum] = upgrades_i_val[upgrade_choice];
		currentupgrades_number[mclient][slot] = currentupgrades_number[mclient][slot] + 1
		//PrintToChat(mclient, "#upprimary Adding New Upgrade uslot(%d) [%s]", inum, upgradesNames[upgrade_choice]);
		currentupgrades_val[mclient][slot][inum] += (upgrades_ratio[upgrade_choice] * ratio);
	}
	else
	{
	//	PrintToChat(mclient, "#upprimary existin attr: %d", inum)
	//	PrintToChat(mclient, "#upprimary ++ Existing Upgrade(%d) %d[%s]", inum, currentupgrades_idx[mclient][slot][inum], upgradesNames[upgrade_choice]);
		currentupgrades_val[mclient][slot][inum] += (upgrades_ratio[upgrade_choice] * ratio);
		check_apply_maxvalue(mclient, slot, inum, upgrade_choice)
	}
		//PrintToChat(mclient, "#upprimary Entering givenew to slot %d", slot);
	client_last_up_idx[mclient] = upgrade_choice
	client_last_up_slot[mclient] = slot
	//PrintToChat(mclient, "exit ...#upprimary");
}

public ResetClientUpgrade_slot(client, slot)
{
	new i
	new iNumAttributes = currentupgrades_number[client][slot]
	
	//PrintToChat(client, "#resetupgrade monweyspend-> %d", client_spent_money[client][slot]);
	if (client_spent_money[client][slot])
	{
		new iCash = GetEntProp(client, Prop_Send, "m_nCurrency", iCash);
		SetEntProp(client, Prop_Send, "m_nCurrency", iCash + client_spent_money[client][slot]);
	}
	currentitem_level[client][slot] = 0
	client_spent_money[client][slot] = 0
	client_spent_money_mvm_chkp[client][slot] = 0
	currentupgrades_number[client][slot] = 0
//	PrintToChat(client, "enter ...#resetupgradeslot %d, resetting values for %d attributes", slot, iNumAttributes);
	
	for (i = 0; i < iNumAttributes; i++)
	{
	//	PrintToChat(client, "enter ...#resetupgrade [%d][%d] -> ref(%d)[%s]", slot, i,
		//		upgrades_ref_to_idx[client][slot][currentupgrades_idx[client][slot][i]],
		//		upgradesNames[currentupgrades_idx[client][slot][i]])
		upgrades_ref_to_idx[client][slot][currentupgrades_idx[client][slot][i]] = 20000
		//currentupgrades_idx[client][slot][i] = 20000
	}

	if (slot != 4 && currentitem_idx[client][slot])
	{
		currentitem_idx[client][slot] = 20000
		GiveNewUpgradedWeapon_(client, slot)
		
		//
		//currentitem_ent_idx[client][slot] = -1
	}
	//client_last_up_idx[client] = -1
//	client_last_up_slot[client] = -1
	if (slot == 3 && client_new_weapon_ent_id[client])
	{
		currentitem_idx[client][3] = 20000
		currentitem_ent_idx[client][3] = -1
		GiveNewUpgradedWeapon_(client, slot)
		client_new_weapon_ent_id[client] = 0;
	}
	if (slot == 4)
	{
		GiveNewUpgradedWeapon_(client, slot)
	}
	new totalmoney = 0
	for (new s = 0; s < 5; s++)
	{
		totalmoney += client_spent_money[client][s]
	}
}

public ResetClientUpgrades(client)
{
	new slot
	
	client_respawn_handled[client] = 0
	for (slot = 0; slot < NB_SLOTS_UED; slot++)
	{
		ResetClientUpgrade_slot(client, slot)
		//PrintToChatAll("reste all upgrade slot %d", slot)
	}
}


public DefineAttributesTab(client, itemidx, slot)
{	
	//PrintToChat(client, "Entering Def attr tab, ent id: %d", itemidx);
	//PrintToChat(client, "  #dattrtab item carried: %d - item_buff: %d", itemidx, currentitem_idx[client][slot]);
	if (currentitem_idx[client][slot] == 20000)
	{
		new a, a2, i, a_i
		
		currentitem_idx[client][slot] = itemidx
		new inumAttr = TF2II_GetItemNumAttributes( itemidx );
		for( a = 0, a2 = 0; a < inumAttr && a < 42; a++ )
		{
			decl String:Buf[128]
			a_i = TF2II_GetItemAttributeID( itemidx, a);
			TF2II_GetAttribName( a_i, Buf, 64);
		//	if (!GetTrieValue(_upg_names, Buf, i))
		//	{
		//		i = _u_id
		//		upgradesNames[i] = Buf
		//		upgrades_costs[i] = 1
		//		SetTrieValue(_upg_names, Buf, _u_id++)
		//		upgrades_to_a_id[i] = a_i
		//	}
			if (GetTrieValue(_upg_names, Buf, i))
			{
				currentupgrades_idx[client][slot][a2] = i
			
				upgrades_ref_to_idx[client][slot][i] = a2;
				currentupgrades_val[client][slot][a2] = TF2II_GetItemAttributeValue( itemidx, a );
				//PrintToChat(client, "init-attribute-[%s]%d [%d ; %f]", 
			//	upgradesNames[currentupgrades_idx[client][slot][a2]],
			//	itemidx, i, currentupgrades_val[client][slot][a]);
				a2++
			}
		}
		currentupgrades_number[client][slot] = a2
	}
	else
	{
		if (itemidx > 0 && itemidx != currentitem_idx[client][slot])
		{
			ResetClientUpgrade_slot(client, slot)
			new a, a2, i, a_i
		
			currentitem_idx[client][slot] = itemidx
			new inumAttr = TF2II_GetItemNumAttributes( itemidx );
			for( a = 0, a2 = 0; a < inumAttr && a < 42; a++ )
			{
				decl String:Buf[128]
				a_i = TF2II_GetItemAttributeID( itemidx, a);
				TF2II_GetAttribName( a_i, Buf, 64);
		//	if (!GetTrieValue(_upg_names, Buf, i))
		//	{
		//		i = _u_id
		//		upgradesNames[i] = Buf
		//		upgrades_costs[i] = 1
		//		SetTrieValue(_upg_names, Buf, _u_id++)
		//		upgrades_to_a_id[i] = a_i
		//	}
				if (GetTrieValue(_upg_names, Buf, i))
				{
					currentupgrades_idx[client][slot][a2] = i
				
					upgrades_ref_to_idx[client][slot][i] = a2;
					currentupgrades_val[client][slot][a2] = TF2II_GetItemAttributeValue( itemidx, a );
					//PrintToChat(client, "init-attribute-%d [%d ; %f]", itemidx, i, currentupgrades_val[client][slot][a]);
					a2++
				}
			}
			currentupgrades_number[client][slot] = a2
		}
	}
	//PrintToChat(client, "..finish #dattrtab ");
}

	
public	Menu_TweakUpgrades(mclient)
{
	new Handle:menu = CreateMenu(MenuHandler_AttributesTweak);
	new s
	
	SetMenuTitle(menu, "Display Upgrades/Remove downgrades");
	for (s = 0; s < 5; s++)
	{
			decl String:fstr[100]
		
			Format(fstr, sizeof(fstr), "%d$ of upgrades) Modify/Remove my %s attributes", client_spent_money[mclient][s], current_slot_name[s])
			AddMenuItem(menu, "tweak", fstr);
	}
	if (IsValidClient(mclient) && IsPlayerAlive(mclient))
	{
		DisplayMenu(menu, mclient, 20);
	}
	return;
}

public	Menu_TweakUpgrades_slot(mclient, arg)
{
	if (arg > -1 && arg < 5
	&& IsValidClient(mclient) 
	&& IsPlayerAlive(mclient))
	{
		new Handle:menu = CreateMenu(MenuHandler_AttributesTweak_action);
		new i, s
			
		s = arg;
		current_slot_used[mclient] = s;
		SetMenuTitle(menu, "%d$ ***%s - Choose attribute:", client_iCash[mclient], current_slot_name[s]);
		decl String:buf[128]
		decl String:fstr[255]
		for (i = 0; i < currentupgrades_number[mclient][s]; i++)
		{
			new u = currentupgrades_idx[mclient][s][i]
			Format(buf, sizeof(buf), "%T", upgradesNames[u], mclient)
			if (upgrades_costs[u] < -0.0001)
			{
				Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f\n%d", buf, currentupgrades_val[mclient][s][i], 
				RoundToNearest(upgrades_costs[u] * ((upgrades_i_val[u] - currentupgrades_val[mclient][s][i]) / upgrades_ratio[u]) * 3))
			}
			else
			{
				Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f", buf, currentupgrades_val[mclient][s][i])
			}
			AddMenuItem(menu, "yep", fstr);
		}
		if (IsValidClient(mclient) && IsPlayerAlive(mclient))
		{
			DisplayMenu(menu, mclient, 20);
		}
	}
	return;
}

public remove_attribute(client, inum)
{
	new slot = current_slot_used[client];
	//new nb = currentupgrades_number[client][slot]
	
	//new tmpswap1, Float:tmpswap2
	currentupgrades_val[client][slot][inum] = upgrades_i_val[currentupgrades_idx[client][slot][inum]];
	
	// if ((nb - 1) != inum)
	// {
		// tmpswap1 = currentupgrades_idx[client][slot][nb - 1]
		// currentupgrades_idx[client][slot][inum] = tmpswap1
		// tmpswap2 = currentupgrades_val[client][slot][nb - 1]
		// currentupgrades_val[client][slot][inum] = tmpswap2	
		// upgrades_ref_to_idx[client][slot][tmpswap1] = inum
	// }
	// currentupgrades_idx[client][slot][nb - 1] = 20000;
	// currentupgrades_val[client][slot][nb - 1] = 0.0;
	
	GiveNewUpgradedWeapon_(client, slot)
}



//menubuy 3- choose the upgrade
public Action:Menu_SpecialUpgradeChoice(client, cat_choice, String:TitleStr[100], selectidx)
{
	//PrintToChat(client, "Entering menu_upchose");
	new i, j

	
	new Handle:menu = CreateMenu(MenuHandler_SpecialUpgradeChoice);
	SetMenuPagination(menu, 2);
	//PrintToChat(client, "Entering menu_upchose [%d] wid%d", cat_choice, current_w_list_id[client]);
	if (cat_choice != -1)
	{
		decl String:desc_str[512]
		new w_id = current_w_list_id[client]
		new tmp_up_idx
		new tmp_spe_up_idx
		new tmp_ref_idx
		new Float:tmp_val
		new Float:tmp_ratio
		new slot
		decl String:plus_sign[1]
		new String:buft[128]
	
		current_w_c_list_id[client] = cat_choice
		slot = current_slot_used[client]
		for (i = 0; i < given_upgrd_classnames_tweak_nb[w_id]; i++)
		{
			tmp_spe_up_idx = given_upgrd_list[w_id][cat_choice][i]
			Format(buft, sizeof(buft), "%T",  upgrades_tweaks[tmp_spe_up_idx], client)
			//PrintToChat(client, "--->special ID", tmp_spe_up_idx);	
			desc_str = buft;
			for (j = 0; j < upgrades_tweaks_nb_att[tmp_spe_up_idx]; j++)
			{
				tmp_up_idx = upgrades_tweaks_att_idx[tmp_spe_up_idx][j]
				tmp_ref_idx = upgrades_ref_to_idx[client][slot][tmp_up_idx]
				if (tmp_ref_idx != 20000)
				{	
					tmp_val = currentupgrades_val[client][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx]
				}
				else
				{
					tmp_val = 0.0
				}
				tmp_ratio = upgrades_ratio[tmp_up_idx]
				if (tmp_ratio > 0.0)
				{
					plus_sign = "+"
				}
				else
				{
					tmp_ratio *= -1.0
					plus_sign = "-"
				}
				new String:buf[128]
				Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], client)
				if (tmp_ratio < 0.99)
				{
					tmp_ratio *= upgrades_tweaks_att_ratio[tmp_spe_up_idx][j]
					Format(desc_str, sizeof(desc_str), "%s\n%\t-%s\n\t\t\t%s%i%%\t(%i%%)",
						desc_str, buf,
						plus_sign, RoundToNearest(tmp_ratio * 100), RoundToNearest(tmp_val * 100))
				}
				else
				{
					tmp_ratio *= upgrades_tweaks_att_ratio[tmp_spe_up_idx][j]
					Format(desc_str, sizeof(desc_str), "%s\n\t-%s\n\t\t\t%s%3i\t(%i)",
						desc_str, buf,
						plus_sign, RoundToNearest(tmp_ratio), RoundToNearest(tmp_val))
				}
			}
			AddMenuItem(menu, "upgrade", desc_str);
		}
	}
	else{
	CloseHandle(menu);
	}
	SetMenuTitle(menu, TitleStr);
	SetMenuExitButton(menu, true);
	DisplayMenuAtItem(menu, client, selectidx, 30);

	return; 
}

	

public MenuHandler_SpecialUpgradeChoice(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		client_respawn_handled[mclient] = 0
		new String:fstr[100]
		new got_req = 1
		new slot = current_slot_used[mclient]
		new w_id = current_w_list_id[mclient]
		new cat_id = current_w_c_list_id[mclient]
		new spTweak = given_upgrd_list[w_id][cat_id][param2]
		for (new i = 0; i < upgrades_tweaks_nb_att[spTweak]; i++)
		{
			new upgrade_choice = upgrades_tweaks_att_idx[spTweak][i]
			new inum = upgrades_ref_to_idx[mclient][slot][upgrade_choice]
			if (inum != 20000)
				{
					if (currentupgrades_val[mclient][slot][inum] == upgrades_m_val[upgrade_choice])
					{
						PrintToChat(mclient, "You already have reached the maximum upgrade for this tweak.");
						got_req = 0
					}
				}
				else
				{
					if (currentupgrades_number[mclient][slot] + upgrades_tweaks_nb_att[spTweak] >= MAX_ATTRIBUTES_ITEM)
					{
						PrintToChat(mclient, "You have not enough upgrade category slots for this tweak.");
						got_req = 0
					}
				}
				
		
		}
		if (got_req)
		{
			decl String:clname[255]
			GetClientName(mclient, clname, sizeof(clname))
			for (new i = 1; i < MAXPLAYERS + 1; i++)
			{
				if (IsValidClient(i) && !client_no_d_team_upgrade[i])
				{
					PrintToChat(i,"%s : [%s tweak] - %s!", 
					clname, upgrades_tweaks[spTweak], current_slot_name[slot]);
				}
			}
			for (new i = 0; i < upgrades_tweaks_nb_att[spTweak]; i++)
			{
				new upgrade_choice = upgrades_tweaks_att_idx[spTweak][i]
				UpgradeItem(mclient, upgrade_choice, upgrades_ref_to_idx[mclient][slot][upgrade_choice], 
					upgrades_tweaks_att_ratio[spTweak][i])
			}
			GiveNewUpgradedWeapon_(mclient, slot)
		}
		new String:buf[128]
		Format(buf, sizeof(buf), "%T", current_slot_name[slot], mclient);
		Format(fstr, sizeof(fstr), "%d$ [%s] - %s", client_iCash[mclient], buf, 
				given_upgrd_classnames[w_id][cat_id])
		Menu_SpecialUpgradeChoice(mclient, cat_id, fstr, GetMenuSelectionPosition())
	}
}


public MenuHandler_AttributesTweak_action(Handle:menu, MenuAction:action, client, param2)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
	{
		new s;
		s = current_slot_used[client];
		if (s >= 0 && s < 4 && param2 < MAX_ATTRIBUTES_ITEM)
		{//
			if (param2 >= 0)
			{
				new u = currentupgrades_idx[client][s][param2]
				if (u != 20000)
				{
					if (upgrades_costs[u] < -0.0001)
					{
						new iCash = GetEntProp(client, Prop_Send, "m_nCurrency", iCash);
						new nb_time_upgraded = RoundToNearest((upgrades_i_val[u] - currentupgrades_val[client][s][param2]) / upgrades_ratio[u])
						new up_cost = upgrades_costs[u] * nb_time_upgraded * 3
						if (iCash >= up_cost)
						{
							remove_attribute(client, param2)
							SetEntProp(client, Prop_Send, "m_nCurrency", iCash - up_cost);
							client_iCash[client] = iCash;
							client_spent_money[client][s] += up_cost
						}
						else
						{
							new String:buffer[128]
							Format(buffer, sizeof(buffer), "%T", "You have not enough money!!", client);
							PrintToChat(client, buffer);
						}
					}
					else
					{
						PrintToChat(client,"Nope.")
					}
					new clientcash = GetEntProp(client, Prop_Send, "m_nCurrency", clientcash);
					new String:fstr[100]
					Format(fstr, sizeof(fstr),"%d$ ***%s - Choose attribute:", clientcash, current_slot_name[s]);
					SetMenuTitle(menu, fstr);
					DisplayMenuAtItem(menu,client,GetMenuSelectionPosition(), MENU_TIME_FOREVER);//
				}
			}
		}
	}
}

 
//menubuy 1-chose the item attribute to tweak
public MenuHandler_AttributesTweak(Handle:menu, MenuAction:action, client, param2)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
	{
		Menu_TweakUpgrades_slot(client, param2)
	}
	else if(action == MenuAction_End){
	CloseHandle(menu);
	}
	return; 
}
 
//cl command to display current item attributes tables
//public Action: DisplayCurrentUps(Handle:mclient)
//{
//	new i, s
//	PrintToChat(mclient, "***Current attributes:");
//	for (s = 0; s < 4; s++)
//	{
//		PrintToChat(mclient, "[%s]:", current_slot_name[s]);
//		for (i = 0; i < currentupgrades_number[mclient][s]; i++)
//		{
//			PrintToChat(mclient, "%s: %10.2f", upgradesNames[currentupgrades_idx[mclient][s][i]], currentupgrades_val[mclient][s][i]);
//		}
//	}
//}
	

public Menu_BuyNewWeapon(mclient)
{
	if (IsValidClient(mclient) && IsPlayerAlive(mclient))
	{
		DisplayMenu(BuyNWmenu, mclient, 20);
	}
}



//menubuy 2- choose the category of upgrades
public Action:Menu_ChooseCategory(client, String:TitleStr[128])
{
//	PrintToChat(client, "Entering menu_chscat");
	new i
	new w_id
	
	new Handle:menu = CreateMenu(MenuHandler_Choosecat);
	new slot = current_slot_used[client];
	if (slot != 4)
	{
		w_id = currentitem_catidx[client][slot];
	}
	else
	{
		w_id = current_class[client] - 1;
	}
	if (w_id >= 0)
	{
		current_w_list_id[client] = w_id
		new String:buf[128]
		for (i = 0; i < given_upgrd_list_nb[w_id]; i++)
		{
			Format(buf, sizeof(buf), "%T", given_upgrd_classnames[w_id][i], client)
			AddMenuItem(menu, "upgrade", buf);
		}
	}
	SetMenuTitle(menu, TitleStr);
	SetMenuExitButton(menu, true);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		DisplayMenu(menu, client, 20);
	}
}

public isValidVIP(client)
{
	new flags = GetUserFlagBits (client) 
	return (flags & ADMFLAG_CUSTOM1 )
}

//menubuy 3- choose the upgrade
public Action:Menu_UpgradeChoice(client, cat_choice, String:TitleStr[100])
{
	new i

	new Handle:menu = CreateMenu(MenuHandler_UpgradeChoice);
	if (cat_choice != -1)
	{
		new w_id = current_w_list_id[client]

		decl String:desc_str[255]
		new tmp_up_idx
		new tmp_ref_idx
		new up_cost
		new Float:tmp_val
		new Float:tmp_ratio
		new slot
		decl String:plus_sign[1]
		current_w_c_list_id[client] = cat_choice
		slot = current_slot_used[client]
		for (i = 0; (tmp_up_idx = given_upgrd_list[w_id][cat_choice][i]); i++)
		{
			up_cost = upgrades_costs[tmp_up_idx] / 2
			if (slot == 1)
			{
				up_cost = RoundToNearest((up_cost * 1.0) * 0.90)
			}
			tmp_ref_idx = upgrades_ref_to_idx[client][slot][tmp_up_idx]
			if (tmp_ref_idx != 20000)
			{	
			//	PrintToChat(client, "menuexisting att:%d", tmp_ref_idx)
				tmp_val = currentupgrades_val[client][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx]
			}
			else
			{
				tmp_val = 0.0
			}
			tmp_ratio = upgrades_ratio[tmp_up_idx]
			if (tmp_val && tmp_ratio)
			{
				up_cost += RoundToNearest(up_cost * (tmp_val / tmp_ratio) * upgrades_costs_inc_ratio[tmp_up_idx])
				if (up_cost < 0.0)
				{
					up_cost *= -1;
					if (up_cost < (upgrades_costs[tmp_up_idx] / 2))
					{
						up_cost = upgrades_costs[tmp_up_idx] / 2
					}
				}
			}
			if (tmp_ratio > 0.0)
			{
				plus_sign = "+"
			}
			else
			{
				tmp_ratio *= -1.0
				plus_sign = "-"
			}
			new String:buf[128]
			Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], client)
			if (tmp_ratio < 0.99)
			{
				Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%i%%\t(%i%%)",
					up_cost, buf,
					plus_sign, RoundToNearest(tmp_ratio * 100), ((RoundToNearest(tmp_val * 100) / 5) * 5))
			}
			else
			{
				Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%3i\t(%i)",
					up_cost, buf,
					plus_sign, RoundToNearest(tmp_ratio), RoundToNearest(tmp_val))
			}
			
			AddMenuItem(menu, "upgrade", desc_str);
		}
	}
	SetMenuTitle(menu, TitleStr);
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 20);
}


//menubuy 1-chose the item category of upgrade
public Action:Menu_BuyUpgrade(client, args)
{
	 if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client] )
	 {
			new String:buffer[128];
			menuBuy = CreateMenu(MenuHandler_BuyUpgrade);
			SetMenuTitle(menuBuy, "UberUpgrades Shop - /buy");
			Format(buffer, sizeof(buffer), "%T", "Body upgrade", client);
			AddMenuItem(menuBuy, "upgrade_player", buffer);
			
			Format(buffer, sizeof(buffer), "%T", "Upgrade my primary weapon", client);
			AddMenuItem(menuBuy, "upgrade_primary", buffer);
			
			Format(buffer, sizeof(buffer), "%T", "Upgrade my secondary weapon", client);
			AddMenuItem(menuBuy, "upgrade_secondary", buffer);
			
			Format(buffer, sizeof(buffer), "%T", "Upgrade my melee weapon", client);
			AddMenuItem(menuBuy, "upgrade_melee", buffer);
			
			//Format(buffer, sizeof(buffer), "%T", "Display Upgrades/Remove downgrades", client);
			AddMenuItem(menuBuy, "upgrade_dispcurrups", "Display Upgrades/Remove downgrades");
			if (!BuyNWmenu_enabled)
			{
				Format(buffer, sizeof(buffer), "%T", "Buy Action Slot", client);
				AddMenuItem(menuBuy, "upgrade_buyoneweap", buffer);
				if (currentitem_level[client][3] == 242)
				{
					Format(buffer, sizeof(buffer), "%T", "Upgrade Action Slot", client);
					AddMenuItem(menuBuy, "upgrade_buyoneweap", buffer);
				}
			}
			SetMenuExitButton(menuBuy, true);
			
			DisplayMenu(menuBuy, client, 20);
	}
}
 

//menubuy 3-Handler
public MenuHandler_BuyNewWeapon(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		new iCash = GetEntProp(mclient, Prop_Send, "m_nCurrency", iCash);
		if (iCash >= 7500 && client_spent_money[mclient][3] == 0)//if(GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex") == 1157)
		{
			TF2_RemoveWeaponSlot(mclient, 3)
			ResetClientUpgrade_slot(mclient, 3);
			currentitem_idx[mclient][3] = newweaponidx[param2];
			currentitem_classname[mclient][3] = newweaponcn[param2];
			SetEntProp(mclient, Prop_Send, "m_nCurrency", iCash - 7500);
			client_spent_money[mclient][3] = 7500;
			PrintToChat(mclient, "Action Slot Bought");
			CreateTimer(0.07, Timer_giveactionslot, GetClientSerial(mclient));
			
		}
		else
		{
			new String:buffer[128]
			Format(buffer, sizeof(buffer), "%T", "You don't have enough money or you already have it.", mclient);
			PrintToChat(mclient, buffer);
		}
	}
	return;
}
public Action:Timer_giveactionslot(Handle:timer, any serial)
{
	int client = GetClientFromSerial(serial);
	
	GiveNewWeapon(client, 3);
}
public Action:Toggl_DispMenuRespawn(client, args)
{
	new String:arg1[128];
	new arg;
	
	client_no_d_menubuy_respawn[client] = 0
	if (GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToInt(arg1);
		if (arg == 0)
		{
			client_no_d_menubuy_respawn[client] = 1
		}
	}
}

public MenuHandler_AccessDenied(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		PrintToChat(mclient, "This feature is donators/VIPs only")
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);

	}
}

//menubuy 3-Handler
public MenuHandler_UpgradeChoice(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		client_respawn_handled[mclient] = 0
		new slot = current_slot_used[mclient]
		new w_id = current_w_list_id[mclient]
		new cat_id = current_w_c_list_id[mclient]
		new upgrade_choice = given_upgrd_list[w_id][cat_id][param2]
		new inum = upgrades_ref_to_idx[mclient][slot][upgrade_choice]

		if (is_client_got_req(mclient, upgrade_choice, slot, inum))
		{
			UpgradeItem(mclient, upgrade_choice, inum, 1.0)
			GiveNewUpgradedWeapon_(mclient, slot)
		}
		decl String:fstr2[100]
		decl String:fstr[40]
		decl String:fstr3[20]
		if (slot != 4)
		{
			Format(fstr, sizeof(fstr), "%t", given_upgrd_classnames[w_id][cat_id], 
					mclient)
			Format(fstr3, sizeof(fstr3), "%t", current_slot_name[slot], mclient)
			Format(fstr2, sizeof(fstr2), "%d$ [%s] - %s", client_iCash[mclient], fstr3,
				fstr)
		}
		else
		{
			Format(fstr, sizeof(fstr), "%t", given_upgrd_classnames[current_class[mclient] - 1][cat_id], 
					mclient)
			Format(fstr3, sizeof(fstr3), "%t", "Body upgrade", mclient)
			Format(fstr2, sizeof(fstr2), "%d$ [%s] - %s", client_iCash[mclient], fstr3,
				fstr)
		}
		SetMenuTitle(menu, fstr2);
		decl String:desc_str[255]
		new tmp_up_idx
		new tmp_ref_idx
		new up_cost
		new Float:tmp_val
		new Float:tmp_ratio
		decl String:plus_sign[1]
		
		tmp_up_idx = given_upgrd_list[w_id][cat_id][param2]
		up_cost = upgrades_costs[tmp_up_idx] / 2
		if (slot == 1)
		{
			up_cost = RoundToNearest((up_cost * 1.0) * 0.9)
		}
		tmp_ref_idx = upgrades_ref_to_idx[mclient][slot][tmp_up_idx]
		if (tmp_ref_idx != 20000)
		{	
			tmp_val = currentupgrades_val[mclient][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx]
		}
		else
		{
			tmp_val = 0.0
		}
		tmp_ratio = upgrades_ratio[tmp_up_idx]
		if (tmp_val && tmp_ratio)
		{
			up_cost += RoundToNearest(up_cost * (tmp_val / tmp_ratio) * upgrades_costs_inc_ratio[tmp_up_idx])
			if (up_cost < 0.0)
			{
				up_cost *= -1;
				if (up_cost < (upgrades_costs[tmp_up_idx] / 2))
				{
					up_cost = upgrades_costs[tmp_up_idx] / 2
				}
			}
		}
		if (tmp_ratio > 0.0)
		{
			plus_sign = "+"
		}
		else
		{
			tmp_ratio *= -1.0
			plus_sign = "-"
		}
		new String:buf[128]
		Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], mclient)
		if (tmp_ratio < 0.99)
		{
			Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%i%%\t(%i%%)",
				up_cost, buf,
				plus_sign, RoundToNearest(tmp_ratio * 100), ((RoundToNearest(tmp_val * 100) / 5) * 5))
		}
		else
		{
			Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%3i\t(%i)",
				up_cost, buf,
				plus_sign, RoundToNearest(tmp_ratio), RoundToNearest(tmp_val))
		}
		
		
		InsertMenuItem(menu, param2, "upgrade", desc_str);
		RemoveMenuItem(menu, param2 + 1);
		DisplayMenuAtItem(menu, mclient, GetMenuSelectionPosition(), 20)
	}
	else if (action == MenuAction_Select)
	{
		CloseHandle(menu);
	}
}


//menubuy 2- Handler
public MenuHandler_BodyUpgrades(Handle:menu, MenuAction:action, mclient, param2)
{	
	if (action == MenuAction_Select)
	{
		decl String:fstr2[100]
		decl String:fstr[40]
		decl String:fstr3[20]
		
		Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[current_class[mclient] - 1][param2], 
					mclient)
		Format(fstr3, sizeof(fstr3), "%T", "Body upgrade", mclient)
		Format(fstr2, sizeof(fstr2), "%d$ [%s] - %s", client_iCash[mclient], fstr3,
				fstr)

		Menu_UpgradeChoice(mclient, param2, fstr2)
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);

	}
	return;
}

public MenuHandler_SpeMenubuy(Handle:menu, MenuAction:action, mclient, param2)
{
	CloseHandle(menu);
	return; 
}

public MenuHandler_Choosecat(Handle:menu, MenuAction:action, mclient, param2)
{
//	PrintToChatAll("exitbutton  %d", param2)
	new Handle:buymenusel = CreateMenu(MenuHandler_BuyUpgrade);
	if (action == MenuAction_Select)
	{
		decl String:fstr2[100]
		decl String:fstr[40]
		decl String:fstr3[20]
		new slot = current_slot_used[mclient]
		new cat_id = currentitem_catidx[mclient][slot]
		if (slot == 4)
		{
			Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[current_class[mclient] - 1][param2], 
					mclient)
			Format(fstr3, sizeof(fstr3), "%T", current_slot_name[slot], mclient)
			Format(fstr2, sizeof(fstr2), "%d$ [%s] - %s", client_iCash[mclient], fstr3,
				fstr)
			Menu_UpgradeChoice(mclient, param2, fstr2)
		}
		else
		{
			Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[cat_id][param2], mclient)
			Format(fstr3, sizeof(fstr3), "%T", "Body upgrade", mclient)
			Format(fstr2, sizeof(fstr2), "%d$ [%s] - %s", client_iCash[mclient], fstr3, 
					fstr)
			if (param2 == given_upgrd_classnames_tweak_idx[cat_id])
			{
				Menu_SpecialUpgradeChoice(mclient, param2, fstr2,0)
			}
			else
			{
				Menu_UpgradeChoice(mclient, param2, fstr2)
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	SetMenuExitBackButton(buymenusel, true);
	return; 
}


public MenuHandler_BuyUpgrade(Handle:menu, MenuAction:action, mclient, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
		{
			decl String:fstr[30]
			decl String:fstr2[128]
			current_slot_used[mclient] = 4;
			client_iCash[mclient] = GetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
			Format(fstr, sizeof(fstr), "%T", "Body upgrade", mclient)
			Format(fstr2, sizeof(fstr2), "%d$ [ - %s - ]", client_iCash[mclient], fstr)
			Menu_ChooseCategory(mclient, fstr2)
			//DisplayCurrentUps(mclient);
		}
		else if (param2 == 4)
		{
			Menu_TweakUpgrades(mclient);
			//DisplayCurrentUps(mclient);
		}
		else if (param2 == 5)
		{
			Menu_BuyNewWeapon(mclient);
			//DisplayCurrentUps(mclient);
		}
		else if (param2 == 6)
		{
			decl String:fstr[30]
			decl String:fstr2[128]
			current_slot_used[mclient] = 3
			
			Format(fstr, sizeof(fstr), "%T", "Body upgrade", mclient)
			client_iCash[mclient] = GetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
			Format(fstr2, sizeof(fstr2), "%d$ [ - Upgrade %s - ]", client_iCash[mclient]
															  ,fstr)
			Menu_ChooseCategory(mclient, fstr2)
		}
		else
		{
			decl String:fstr[30]
			decl String:fstr2[128]
			param2 -= 1
			current_slot_used[mclient] = param2
			Format(fstr, sizeof(fstr), "%T", current_slot_name[param2], mclient)
			client_iCash[mclient] = GetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
			Format(fstr2, sizeof(fstr2), "%d$ [ - Upgrade %s - ]", client_iCash[mclient]
															  ,fstr)
			Menu_ChooseCategory(mclient, fstr2)
		}
	}
}
 //yep

//custom attribute stuffs

//public void OnClientThink(int iClient, buttons)
//{
//	
//	new Address:attribute2 = TF2Attrib_GetByName(iClient, "fists have radial buff");
//	if (attribute2 != Address_Null)
//	{
//		new ent = GetEntDataEnt2(iClient, OffAW);
//		SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", 0.0);
//		SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", 0.0);
//		SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", 0.0);
//	}
//	return;
//}
//public Focusbuff(iClient)
//{
//	TF2_RemoveCondition(iClient, TFCond_FocusBuff)
//}
 
public Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Address:attribute1 = TF2Attrib_GetByName(client, "selfmade description");
	new Address:attribute2 = TF2Attrib_GetByName(client, "custom employee number");
	if (attribute1 != Address_Null)
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.15)
	}
	if (attribute2 != Address_Null)
	{
		TF2_AddCondition(client, TFCond_RadiusHealOnDamage, 0.75)
	}				
	return
}

public OnClientPostAdminCheck(client)
{
	SetEntProp(client, Prop_Send, "m_nCurrency", (StartMoney + additionalstartmoney));
	SDKHook(client, SDKHook_PreThink, OnClientThink);
	SDKHook(client, SDKHook_PreThinkPost, OnClientThink);
	SDKHook(client, SDKHook_PostThink, OnClientThink);
	SDKHook(client, SDKHook_PostThinkPost, OnClientThink)
} 
public void OnClientThink(client)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new hClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new Address:flinch = TF2Attrib_GetByName(hClientWeapon, "aiming no flinch");
		if(flinch != Address_Null)
		{
			SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", NULL_VECTOR);
			SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", NULL_VECTOR);
		}
	}
}//
public OnEntityCreated(entity, const char[] classname)
{
    if(StrEqual(classname, "item_currencypack_custom"))
    {
        if(IsValidEdict(entity)){
            RemoveEdict(entity)
		}
    }
    if(StrEqual(classname, "tank_boss"))
    {
        if(IsValidEdict(entity) && IsValidEntity(entity)){
			new Float:health = (StartMoney+additionalstartmoney*mvmadditional*2.5);
			new hp = RoundToNearest(health);
			new Float:spd = (75+mvmadditional+mvmadditional);
			new speed = RoundToNearest(spd);
			SetVariantInt(hp); 
			AcceptEntityInput(entity, "SetMaxHealth", -1);
			SetVariantInt(hp); 
			AcceptEntityInput(entity, "SetHealth", -1);
			SetVariantInt(speed); 
			AcceptEntityInput(entity, "SetSpeed", -1); 
			
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Tank); 
			if(!IsMvM())
			{
				new Float:tankArmor = (50000.0/(StartMoney+additionalstartmoney));
				new Float:tankRes = (1/tankArmor);
				PrintToChatAll("Tank Armor: %f ", tankRes);
			}
			else
			{
				new Float:tankArmor = (60000.0/(StartMoney+additionalstartmoney))/mvmadditional;
				new Float:tankRes = (1/tankArmor);
				PrintToChatAll("Tank Armor: %f ", tankRes); 
			}
		}
    }
}
public Action:OnTakeDamagePre_Tank(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) 
{
	if(!IsMvM())
	{
		new Float:tankArmor = 50000.0/(StartMoney+additionalstartmoney);
		damage *= tankArmor;
	}
	else
	{
		new Float:tankArmor = (60000.0/(StartMoney+additionalstartmoney))/mvmadditional;
		damage *= tankArmor;
	}
	return Plugin_Changed;
} 
public OnMapStart()
{
	IsMvM(true);
}
public TF2Spawn_EnterSpawn(int client, int spawn)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new melee = GetPlayerWeaponSlot(client,2);
		TF2Attrib_SetByName(melee,"airblast vulnerability multiplier hidden", 0.0);
		TF2Attrib_SetByName(melee,"damage force increase hidden", 0.0);
	}
}
public TF2Spawn_LeaveSpawn(int client, int spawn)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new melee = GetPlayerWeaponSlot(client,2);
		TF2Attrib_SetByName(melee,"airblast vulnerability multiplier hidden", 1.0);
		TF2Attrib_SetByName(melee,"damage force increase hidden", 1.0);
	}
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new hClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new Address:flinch = TF2Attrib_GetByName(hClientWeapon, "aiming no flinch");
		if(flinch != Address_Null)
		{
			SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", NULL_VECTOR);
			SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", NULL_VECTOR);
		}
	}
}
RespawnEffect(client)
{
	current_class[client] = _:TF2_GetPlayerClass(client)
	TF2Attrib_SetByName(client,"afterburn immunity", 1.0);//fix afterburn
	TF2Attrib_SetByName(client,"weapon burn time increased", 4.0);//fix afterburn
	if(current_class[client] == _:TFClass_Pyro)
	{
		TF2Attrib_SetByName(client,"airblast_pushback_no_viewpunch", 1.0);//airblast patch
		TF2Attrib_SetByName(client,"airblast_pushback_no_stun", 1.0);//airblast patch
		TF2Attrib_SetByName(client,"airblast_turn_projectile_to_ammo", 20.0);//airblast patch
	}
}
ChangeClassEffect(client)
{
	current_class[client] = _:TF2_GetPlayerClass(client)
	TF2_RemoveAllWeapons(client);
	if(IsPlayerAlive(client))
	{
		TF2_RespawnPlayer(client);
	}
	TF2Attrib_RemoveAll(client)
}

//nice.