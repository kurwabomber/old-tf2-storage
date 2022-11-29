/**
* File: War3Source_999_TreasureHunter.sp
* Description: Treasure Hunter Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <smlib>

new thisRaceID;
new SKILL_DAMAGE, SKILL_SPEED, SKILL_HEALTH, ULT_INVIS;



public Plugin:myinfo = 
{
    name = "War3Source Race - Treasure Hunter",
    author = "Remy Lebeau",
    description = "Ready's private race for War3Source",
    version = "1.1",
    url = "http://sevensinsgaming.com"
};

new Float:g_fSpeed[5] = {1.0, 1.25, 1.3, 1.35, 1.4};
new Float:g_fDecay[] = {0.0, 7.0, 6.0, 5.0, 4.0};
new g_iHealth[]={0,25,50,75,100};
new Float:g_fDamageChance[] = {0.0, 0.1, 0.15, 0.2, 0.35};
//new Float:g_fUltDuration[] = { 0.0, 0.5, 1.0, 1.5, 2.0 };
new bool:g_bClientInvis[MAXPLAYERS];



public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Treasure Hunter [PRIVATE]","treasurehunter");
    
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Lethal Blow","Does MASSIVE damage.  Chance increases on HP drop.  Right click only.",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Quick Step","Increase speed.",false,4);
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Light Armour Mastery","Increase HP",false,4);
    ULT_INVIS=War3_AddRaceSkill(thisRaceID,"Dagger Mastery","Go temporarily fully invisible.  Cannot shoot for 1 sec out of invis (+ultimate)",true,4);

    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, g_iHealth);
}



public OnPluginStart()
{
 /*   HookEvent( "bomb_beginplant", Event_BeginPlant, EventHookMode_Pre );
    HookEvent( "bomb_begindefuse", Event_BombBeginDefuse, EventHookMode_Pre );
    HookEvent( "hostage_follows", Event_HostageFollows, EventHookMode_Pre );*/
}



public OnMapStart()
{

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
    War3_SetBuff( client, bDoNotInvisWeapon, thisRaceID, false);
    g_bClientInvis[client] = false;

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
        InitPassiveSkills(client);
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{
    g_bClientInvis[client] = false;
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        //W3ResetAllBuffRace( client, thisRaceID );
        //War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
        InitPassiveSkills(client);
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
        new ult_invis = War3_GetSkillLevel( client, thisRaceID, ULT_INVIS );
        
        if(ult_invis>0)
        {
        
                if(g_bClientInvis[client] == false )
                { 
                    g_bClientInvis[client] = true;
                    PrintHintText(client,"Dagger Mastery!");
                   // Client_ScreenFade(client, 1, FFADE_STAYOUT, , , , 110,,);
                    W3FlashScreen(client,{0,0,110,50},0.5,_,FFADE_STAYOUT);
                    
                    War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0  );
                    War3_SetBuff( client, bDisarm, thisRaceID, true  );
                    War3_SetBuff( client, fHPDecay, thisRaceID, g_fDecay[ult_invis]  );
                    

                }
                else
                {
                    War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0  );
                    War3_SetBuff( client, fHPDecay, thisRaceID, 0.0  );
                    CreateTimer(0.5,RemoveDisarm,client);
                    War3_CooldownMGR(client,0.5,thisRaceID,ULT_INVIS,true,true);

                    PrintHintText(client,"Reappear."); 
                    W3FlashScreen(client,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));
                    
                    g_bClientInvis[client] = false;
                }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
}


public Action:RemoveDisarm(Handle:t,any:client)
{
    if(ValidPlayer(client))
    {
        War3_SetBuff( client, bDisarm, thisRaceID, false  );
        W3FlashScreen(client,{0,255,0,30}, 1.0);
    }
}





/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*        
*
***************************************************************************/


/*

public Action:Event_BombBeginDefuse( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(g_bClientInvis[client])
    {
        ServerCommand( "sm_slap #%d 10", GetClientUserId( client ) );
        PrintHintText(client, "You can not defuse while invisible");
    }
    return Plugin_Continue;
}

public Action:Event_BeginPlant( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(g_bClientInvis[client])
    {
        ServerCommand( "sm_slap #%d 10", GetClientUserId( client ) );
        PrintHintText(client, "You can not plant while invisible");
    }
    return Plugin_Continue;
}

public Action:Event_HostageFollows( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(g_bClientInvis[client])
    {
        PrintHintText(client, "You may not rescue hostages while invis");
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

*/


public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
    if( ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker) && victim != attacker )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            if(!W3HasImmunity(victim,Immunity_Skills) && !Silenced(attacker))
            {
                new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DAMAGE );
                new buttons = GetClientButtons(attacker);
                if ((buttons & IN_ATTACK2) && skill_level > 0)
                {
                    ProcDamageChance(attacker, victim, skill_level);
                }
            }            
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





public ProcDamageChance(attacker, victim, skill_level)
{
    new hp = GetClientHealth(attacker);
    switch(skill_level)
    {
        case 0:
        {
            
        }
        case 1:
        {

            if(GetRandomFloat( 0.0, 1.0 ) <= g_fDamageChance[1])
            {

                War3_DealDamage(victim,1000,attacker,DMG_BULLET,"Lethal Blow");

            }
        }
        case 2:
        {

            if(hp < 100)
            {

                if(GetRandomFloat( 0.0, 1.0 ) <= g_fDamageChance[2])
                {

                    War3_DealDamage(victim,1000,attacker,DMG_BULLET,"Lethal Blow");

                }
            }
            else
            {

                if(GetRandomFloat( 0.0, 1.0 ) <= g_fDamageChance[1])
                {

                    War3_DealDamage(victim,1000,attacker,DMG_BULLET,"Lethal Blow");

                }

            }
        }
        case 3:
        {

            if(hp < 50)
            {
                if(GetRandomFloat( 0.0, 1.0 ) <= g_fDamageChance[3])
                {
                    War3_DealDamage(victim,1000,attacker,DMG_BULLET,"Lethal Blow");

                }

            }
            else if(hp < 100)
            {
                if(GetRandomFloat( 0.0, 1.0 ) <= g_fDamageChance[2])
                {
                    War3_DealDamage(victim,1000,attacker,DMG_BULLET,"Lethal Blow");

                }

            }
            else
            {
                if(GetRandomFloat( 0.0, 1.0 ) <= g_fDamageChance[1])
                {
                    War3_DealDamage(victim,1000,attacker,DMG_BULLET,"Lethal Blow");

                }

            }

        }
        case 4:
        {

            if(hp < 10)
            {

                if(GetRandomFloat( 0.0, 1.0 ) <= g_fDamageChance[4])
                {

                    War3_DealDamage(victim,1000,attacker,DMG_BULLET,"Lethal Blow");

                }

            }
            else if(hp < 50)
            {

                if(GetRandomFloat( 0.0, 1.0 ) <= g_fDamageChance[3])
                {

                    War3_DealDamage(victim,1000,attacker,DMG_BULLET,"Lethal Blow");

                }

            }
            else if(hp < 100)
            {
                if(GetRandomFloat( 0.0, 1.0 ) <= g_fDamageChance[2])
                {
                    War3_DealDamage(victim,1000,attacker,DMG_BULLET,"Lethal Blow");

                }

            }
            else
            {
                if(GetRandomFloat( 0.0, 1.0 ) <= g_fDamageChance[1])
                {
                    War3_DealDamage(victim,1000,attacker,DMG_BULLET,"Lethal Blow");

                }

            }
        }
    }
}
