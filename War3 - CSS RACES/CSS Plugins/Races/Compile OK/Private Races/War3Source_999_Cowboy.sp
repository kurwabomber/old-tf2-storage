/**
* File: War3Source_999_Cowboy.sp
* Description: Deceit Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_JUMP, SKILL_DAMAGE, SKILL_HEALTH, SKILL_HEAL, ULT_MONEY;



public Plugin:myinfo = 
{
    name = "War3Source Race - Cowboy",
    author = "Remy Lebeau",
    description = "AGENTkrispy's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};

new g_iHealth[] = {0, 10, 20, 30, 40, 50};
new Float:ElectricGravity[] = { 1.0, 0.92, 0.84, 0.80, 0.76, 0.68 };
new Float:JumpMultiplier[] = { 1.0, 3.0, 3.1, 3.2, 3.3, 3.4 };
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;

new MoneyOffsetCS;
new g_iUltiMoney[] = {0,500,1000,1500,2000,2500};

new g_iDamageCost[] = {0, 5, 10, 15, 20, 25};
new Float:g_fDamageChance[] = {0.0, 0.2, 0.3, 0.4, 0.5, 0.6}; 
new g_iCostMultiplier = 15;
new Float:DamageMultiplier = 0.01;
new g_iDamageCounter[MAXPLAYERS];
new HaloSprite, BeamSprite;

new g_iHealCost[] = {0, 300, 600, 900, 1200, 1500};
new g_iHealAmount[] = {0, 5, 15, 25, 40, 60};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Cowboy [PRIVATE]","cowboy");
    
    SKILL_JUMP=War3_AddRaceSkill(thisRaceID,"Run like the Wind","Long jump",false,5);
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Top Notch","Increased health",false,5);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Precision","Buy damage upgrades for your shotgun (+ability)",false,5);
    SKILL_HEAL=War3_AddRaceSkill(thisRaceID,"Bandages","Buy restoratives from the canteen (+ability1)",false,5);
    ULT_MONEY=War3_AddRaceSkill(thisRaceID,"Rob the bank","Get yourself some cold, hard, cash (+ultimate)",true,5);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_MONEY,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, g_iHealth);
    War3_AddSkillBuff(thisRaceID, SKILL_JUMP, fLowGravitySkill, ElectricGravity);

}



public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
    m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
    HookEvent( "player_jump", PlayerJumpEvent );
    MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
}



public OnMapStart()
{
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    BeamSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
}
    

stock GetMoney(player)
{
    return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
    SetEntData(player,MoneyOffsetCS,money);
}

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public InitPassiveSkills( client )
{
    
    

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_m3,weapon_elite");
        CreateTimer( 1.0, GiveWep, client );
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        W3ResetAllBuffRace( client, thisRaceID );
        SetMoney(client,1000);
        g_iDamageCounter[client] = 0;
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_m3,weapon_elite");
        CreateTimer( 1.0, GiveWep, client );
    }
}






/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new ult_money = War3_GetSkillLevel( client, thisRaceID, ULT_MONEY );
        if(ult_money>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_MONEY,true))
                {
                    new money=GetMoney(client);
                    SetMoney(client,money+g_iUltiMoney[ult_money]);
                    W3FlashScreen( client, RGBA_COLOR_BLUE );
                    War3_CooldownMGR( client, 60.0, thisRaceID, ULT_MONEY, _, _ );
                }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
}



public OnAbilityCommand( client, ability, bool:pressed )
{
    if( War3_GetRace( client ) == thisRaceID && ValidPlayer( client, true ) )
    {
        if(ability == 0 && pressed)
        {
            new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_DAMAGE );
            if( skill_level > 0 )
            {
                new money=GetMoney(client);
                if (money < (g_iDamageCost[skill_level]*g_iCostMultiplier))
                {
                    PrintToChat(client, "Insufficient funds to buy more upgrades");
                }
                else
                {
                    SetMoney(client,money-(g_iDamageCost[skill_level]*g_iCostMultiplier));
                    g_iDamageCounter[client] += g_iDamageCost[skill_level];
                    PrintToChat(client, "Damage upgraded |%i|", g_iDamageCounter[client]);
                    
                }
            }
        }
        if(ability == 1 && pressed)
        {
            new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_HEAL );
            new skill_health = War3_GetSkillLevel( client, thisRaceID, SKILL_HEALTH );
            if( skill_level > 0 )
            {
                if(War3_SkillNotInCooldown(client,thisRaceID, SKILL_HEALTH, true))
                {

                    War3_CooldownMGR( client, 5.0, thisRaceID, SKILL_HEALTH, _, _ );
                    new pHealth = GetClientHealth(client);
                    if( pHealth < 100+g_iHealth[skill_health])
                    {
                        new money=GetMoney(client);
                        if (money < g_iHealCost[skill_level])
                        {
                            PrintToChat(client, "Insufficient funds for healing");
                        }
                        else
                        {
                            SetMoney(client,money-g_iHealCost[skill_level]);
                            PrintToChat(client, "Restorative purchased");
                            War3_HealToBuffHP( client, g_iHealAmount[skill_level] );
                            W3FlashScreen( client, RGBA_COLOR_GREEN );
                        }
                    }
                    else
                    {
                        PrintHintText(client, "No need for restorative!");
                    }
                }
            }    
        }     
    }
}




/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DAMAGE );
            if( !Hexed( attacker, false ) && skill_dmg > 0 && GetRandomFloat( 0.0, 1.0 ) < g_fDamageChance[skill_dmg] && !W3HasImmunity( victim, Immunity_Skills ) )
            {
                new String:wpnstr[32];
                GetClientWeapon( attacker, wpnstr, 32 );
                if( StrEqual( wpnstr, "weapon_m3" ) )
                {
                    new Float:start_pos[3];
                    new Float:target_pos[3];
                
                    GetClientAbsOrigin( attacker, start_pos );
                    GetClientAbsOrigin( victim, target_pos );
                
                    start_pos[2] += 40;
                    target_pos[2] += 40;
                
                    TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
                    TE_SendToAll();
                    
                    new String:pName[256];
                    GetClientName (victim, pName, 256 );
                    new tempdamage = RoundToFloor(damage * DamageMultiplier * g_iDamageCounter[attacker]);
                    //PrintToChat(attacker, "Damage dealt to |%s| - |%i| * |%.3f| * |%i| =  |%i|", pName, damage, DamageMultiplier, g_iDamageCounter[attacker], tempdamage);
                    
                    War3_DealDamage( victim,  tempdamage , attacker, DMG_BULLET, "cowboy_crit" );
                
                    W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DAMAGE );
                    W3FlashScreen( victim, RGBA_COLOR_RED );
                }
            }
        }
    }
}





public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        new skill_long = War3_GetSkillLevel( client, race, SKILL_JUMP );
        if( skill_long > 0 )
        {
            new Float:velocity[3] = { 0.0, 0.0, 0.0 };
            velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
            velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
            velocity[0] *= JumpMultiplier[skill_long] * 0.25;
            velocity[1] *= JumpMultiplier[skill_long] * 0.25;
            SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
        }
    }
}




/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/

    

    
public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, "weapon_m3" );
        GivePlayerItem( client, "weapon_elite" );
        
    }
}