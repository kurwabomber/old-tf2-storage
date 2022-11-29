////
//Huge thanks go to Remy Lebeau for letting my use his GunGamer and GamblingMan races as a scaffold.
////

////////////
// 
// To-do list:
// 
// - Shopmenu item restrictions.
// 
/////////////



#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_WEAPON, SKILL_DAMAGE, SKILL_GRENADE;


public Plugin:myinfo = 
{
    name = "War3Source Race - One Shot",
    author = "Kibbles",
    description = "One Shot race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


new String:sWeaponList[21][] = { "weapon_glock","weapon_usp","weapon_p228","weapon_fiveseven","weapon_elite",
"weapon_m249",
"weapon_mac10","weapon_tmp",
"weapon_mp5navy","weapon_ump45","weapon_p90",
"weapon_famas","weapon_galil",
"weapon_aug","weapon_sg552",
"weapon_ak47","weapon_m4a1","weapon_deagle",
"weapon_scout","weapon_awp","weapon_sg550"};


new iWeaponSets[] = {4,5,7,10,12,14,17,20};

new Float:fDamageMod[] = {1.5, 2.0, 2.5, 3.0};
new iSelfDamage[] = {2, 3, 4, 5};

new Float:fGrenadeChance[] = {0.025,0.05,0.075,0.1};
new iGrenadeHealthThreshold = 10;
new bool:bGiveGrenade = false;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("One Shot","oneshot");
    
    SKILL_WEAPON = War3_AddRaceSkill(thisRaceID, "One Shot", "You get one shot. Kill for a new weapon, miss for a knife.", false, 8);
    SKILL_DAMAGE = War3_AddRaceSkill(thisRaceID, "One Kill", "Get (1.5,2,2.5,3) times damage for each hit, but take (2,3,4,5) damage per attack.",false,4);
    SKILL_GRENADE = War3_AddRaceSkill(thisRaceID,"Last Stand", "(2.5,5,7.5,10% chance to get a HE grenade when you drop to 10 health or less.",true,4);
    
    War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
    //Do nothing
}


//
// Weapon functions
//
public GiveWeapon(client)
{
    if (ValidPlayer(client, true))
    {
        new skill_weapon = War3_GetSkillLevel( client, thisRaceID, SKILL_WEAPON );
        if (skill_weapon > 0)
        {
            new weaponSetMax = iWeaponSets[skill_weapon - 1];
            new weaponChoiceIndex = GetRandomInt(0,weaponSetMax);
            
            new String:weaponChoice[128] = "";
            StrCat(weaponChoice, 128, sWeaponList[weaponChoiceIndex]);
            
            new Handle:pack;
            CreateDataTimer(0.4,giveWeapon,pack);
            WritePackCell(pack,client);
            if (!bGiveGrenade)
            {
                WritePackString(pack,weaponChoice);
            }
            else
            {
                WritePackString(pack,"weapon_hegrenade");
                bGiveGrenade = false;
            }
        }
        else
        {
            CPrintToChat(client,"{red}Put a level in to One Shot to get weapons!");
        }
    }
}


//
// Buff functions
//
public InitPassiveSkills( client )
{
    if (ValidPlayer(client, true))
    {        
        new skill_weapon = War3_GetSkillLevel(client, thisRaceID, SKILL_WEAPON);
        new skill_damage = War3_GetSkillLevel(client, thisRaceID, SKILL_DAMAGE);
        //new skill_grenade = War3_GetSkillLevel(client, thisRaceID, SKILL_GRENADE);
        
        if (skill_weapon > 0 && skill_damage > 0)
        {
            War3_SetBuff(client, fDamageModifier, thisRaceID, Float:fDamageMod[skill_damage-1]);
        }
        else
        {
            CPrintToChat(client, "{red}Put a level in One Shot to activate your damage buff!");
        }
    }
}


//
// Event handling
//
public OnRaceChanged( client, oldrace, newrace )
{
    if( newrace == thisRaceID && ValidPlayer(client))
    {
        if(ValidPlayer( client, true ))
        {
            InitPassiveSkills(client);
            GiveWeapon(client);
        }
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}


public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    if (skill == SKILL_DAMAGE || skill == SKILL_WEAPON)
    {
        InitPassiveSkills(client);
    }
}


public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");//Just in case something goes wrong after this.
        Client_RemoveAllWeapons(client, "weapon_c4", true);
        GiveWeapon(client);
        InitPassiveSkills(client);
    }
}


public OnWeaponFired(client)
{    
    new skill_weapon = War3_GetSkillLevel(client, thisRaceID, SKILL_WEAPON);
    new skill_damage = War3_GetSkillLevel(client, thisRaceID, SKILL_DAMAGE);
    
    if (War3_GetRace(client) == thisRaceID && ValidPlayer(client, true) && skill_weapon > 0 && skill_damage > 0)
    {
        new String:weapon[128];//weapon Char Array
        GetClientWeapon(client, weapon, 128);
        
        if (strcmp(weapon,"weapon_c4") != 0 && strcmp(weapon,"weapon_knife") != 0)//Knife attacks are handled in OnWar3EventPostHurt, so that both slashes and stabs deal self-damage.
        {
            damageSelf(client,weapon);
        }
        
        if (strcmp(weapon,"weapon_hegrenade") != 0 && strcmp(weapon,"weapon_knife") != 0 && strcmp(weapon,"weapon_c4") != 0)
        {
            Client_RemoveWeapon(client, weapon, true, true);
            
            if (strcmp(weapon,"weapon_scout") == 0 || strcmp(weapon,"weapon_awp") == 0 || strcmp(weapon,"weapon_sg550") == 0 || strcmp(weapon,"weapon_aug") == 0 || strcmp(weapon,"weapon_sg552") == 0)
            {
                //If zoomed, reset to normal FOV
                new FOV = FindSendPropInfo( "CBasePlayer", "m_iFOV" );
                SetEntData(client, FOV, 0);
            }
        }
        
        if (strcmp(weapon,"weapon_knife") != 0)
        {
            //Slight delay to avoid instaslashing with the new knife, and damaging self.
            new Float:timeToWait = 0.2;
            
            if (strcmp(weapon,"weapon_hegrenade") == 0 || strcmp(weapon,"weapon_c4") == 0)
            {
                //Longer delay to allow tossing the grenade.
                timeToWait = 1.0;
            }
            
            CreateTimer(timeToWait,giveKnife,client);
        }
    }
}


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if (ValidPlayer(victim, true) && War3_GetRace(victim) == thisRaceID && !Hexed(victim))
    {
        new currentHealth = GetClientHealth(victim);
        if (currentHealth <= iGrenadeHealthThreshold)
        {
            new skill_grenade = War3_GetSkillLevel( victim, thisRaceID, SKILL_GRENADE );
            new Float:randomFloat = GetRandomFloat(0.0,1.0);
            
            if (randomFloat <= fGrenadeChance[skill_grenade-1])
            {
                bGiveGrenade = true;
                GiveWeapon(victim);
                PrintHintText(victim, "You've got a grenade. Use it wisely!");
            }
        }
    }
    else if (ValidPlayer(attacker, true) && War3_GetRace(attacker) == thisRaceID)
    {
        if (strcmp(weapon, "weapon_knife"))
        {
            damageSelf(attacker, "weapon_knife");
        }
    }
}


public OnWar3EventDeath(victim,attacker)
{
    if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim) && attacker!=victim)
    {
        new race = War3_GetRace(attacker);
        if(race==thisRaceID)
        {
            GiveWeapon(attacker);
        }
    }
}


//
// Helpers
//
public Action:giveWeapon(Handle:timer, Handle:pack)
{
    new client;
    ResetPack(pack);
    client = ReadPackCell(pack);
    
    if (ValidPlayer(client, true))
    {
        new String:weapon[128];
        ReadPackString(pack, weapon, sizeof(weapon));
        
        restrictWeapon(client, weapon);
        
        Client_GiveWeapon(client, weapon);
    }
}


public Action:giveKnife(Handle:timer, any:client)
{
    if (ValidPlayer(client, true))
    {
        restrictWeapon(client, "weapon_knife");
        
        Client_GiveWeapon(client, "weapon_knife");
    }
}


public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID)
        {
            Client_RemoveAllWeapons(i, "weapon_c4", true);
        }
    }
}


public restrictWeapon(any:client,String:weapon[])
{
    new String:temp[128] = "weapon_c4,";
    StrCat(temp,128,weapon);
    
    War3_WeaponRestrictTo(client, thisRaceID, temp);
}


public damageSelf(any:client,String:weapon[])
{
    new skill_damage = War3_GetSkillLevel(client, thisRaceID, SKILL_DAMAGE);
    War3_DealDamage(client,iSelfDamage[skill_damage-1],0,DMG_GENERIC,weapon,W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG);
}