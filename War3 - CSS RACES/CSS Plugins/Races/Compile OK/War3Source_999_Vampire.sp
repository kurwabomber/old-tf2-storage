/**
* File: War3Source_999_Vampire.sp
* Description: Vampire Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_LEECH, SKILL_FANGS, SKILL_FLY, ULT_HEAL;



public Plugin:myinfo = 
{
    name = "War3Source Race - Vampire",
    author = "Remy Lebeau",
    description = "Vampire race for War3Source",
    version = "1.2.2",
    url = "http://sevensinsgaming.com"
};


// Skill 1
new bsmaximumHP = 300;
new Float:VampirePercent[] = {0.0, 0.05, 0.075, 0.10, 0.15, 0.20 };


//skill 2
new const ShadowStrikeInitialDamage=20;
new const ShadowStrikeTrailingDamage=5;
new Float:ShadowStrikeChanceArr[]={0.0,0.05,0.1,0.15,0.2,0.25};
new ShadowStrikeTimes[]={0,1,2,3,4,5};
new BeingStrikedBy[MAXPLAYERSCUSTOM];
new StrikesRemaining[MAXPLAYERSCUSTOM];
new String:shadowstrikestr[256]; //="war3source/shadowstrikebirth.mp3";

// skill 3
new Float:g_fUltCooldown = 10.0;
new bool:g_bFlying[MAXPLAYERS + 1];

// ultimate
new bool:g_bInUltimate[MAXPLAYERS];
new Float:g_fUltTimer[] = {0.0, 0.5, 1.0, 1.5, 2.0, 2.5};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Vampire [SSG-DONATOR]","vampire");
    
    SKILL_LEECH=War3_AddRaceSkill(thisRaceID,"Vampirism","Get some of the damage you deal back as health (max HP 400)",false,5);
    SKILL_FANGS=War3_AddRaceSkill(thisRaceID,"Fangs","Poison your enemy",false,5);
    SKILL_FLY=War3_AddRaceSkill(thisRaceID,"Bat","Fly like a bat (+ability)",false,1);
    ULT_HEAL=War3_AddRaceSkill(thisRaceID,"Arcane Powers","While active damage done to you will restore health (+ultimate)",true,5);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_HEAL,15.0,true);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, VampirePercent);
}



public OnPluginStart()
{
    HookEvent( "round_end", RoundEndEvent );
}



public OnMapStart()
{
    War3_AddSoundFolder(shadowstrikestr, sizeof(shadowstrikestr), "shadowstrikebirth.mp3");


    War3_AddCustomSound(shadowstrikestr);
}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/




public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
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
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
    }
}

public InitPassiveSkills(client)
{
    War3_WeaponRestrictTo(client,thisRaceID,"");
    War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, bsmaximumHP);
    g_bFlying[client] = false;
    g_bInUltimate[client] = false;
    War3_SetBuff(client, bFlyMode, thisRaceID, false);
    War3_SetBuff(client, bDisarm, thisRaceID, false);
}


/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/

public OnUltimateCommand(client, race, bool:pressed)
{
    if (race == thisRaceID && IsPlayerAlive(client))
    {
        if (pressed)
        {
            new ult_level = War3_GetSkillLevel(client, thisRaceID, ULT_HEAL);
            if ( ult_level > 0)
            {
                if (War3_SkillNotInCooldown(client, thisRaceID, ULT_HEAL, false))
                {
                    if (!Silenced(client))
                    {
                        g_bInUltimate[client] = true;
                        CreateTimer(g_fUltTimer[ult_level], HealOff, client);
                        W3SetPlayerColor(client,thisRaceID,255,0,0,_,GLOW_ULTIMATE); 
                        PrintHintText(client, "Ultimate Activated");
                        War3_CooldownMGR(client, 15.0, thisRaceID, ULT_HEAL, _, true);
                    }
                }
            }
            else
            {
                W3MsgUltNotLeveled(client);
            }
        }
    }
}



public OnAbilityCommand(client,ability,bool:pressed)
{
    new race = War3_GetRace( client );
    if (race == thisRaceID && IsPlayerAlive(client))
    {
        if (pressed && ability==0)
        {
            if (War3_GetSkillLevel(client, thisRaceID, SKILL_FLY) > 0)
            {
                if (War3_SkillNotInCooldown(client, thisRaceID, SKILL_FLY, false))
                {
                    if (!Silenced(client))
                    {
                    
                        if (g_bFlying[client])
                        {
                            g_bFlying[client] = false;
                            PrintHintText(client, "Back to vampire form!");
                            War3_CooldownMGR(client, g_fUltCooldown, thisRaceID, SKILL_FLY, _, true);
                            War3_SetBuff(client, bFlyMode, thisRaceID, false);
                            War3_SetBuff( client, bDisarm, thisRaceID, false  );
                            
                        }
                        else
                        {
                            g_bFlying[client] = true;
                            War3_SetBuff(client, bFlyMode, thisRaceID, true);
                            PrintHintText(client, "Transform into a bat and fly!");
                            War3_SetBuff( client, bDisarm, thisRaceID, true  );
                            
                        }
                        
                    
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


public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim)&&GetClientTeam(victim)!=GetClientTeam(attacker))
        {
            if(War3_GetRace(attacker)==thisRaceID)
            {
                new Float:chance_mod=W3ChanceModifier(attacker);
                /// CHANCE MOD BY VICTIM
                new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_FANGS);
                if(skill_level>0 && StrikesRemaining[victim]==0 && !Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*ShadowStrikeChanceArr[skill_level])
                {
                    if(W3HasImmunity(victim,Immunity_Skills))
                    {
                        W3MsgSkillBlocked(victim,attacker,"Fangs");
                    }
                    else
                    {
                        W3MsgAttackedBy(victim,"Fangs");
                        W3MsgActivated(attacker,"Fangs");
                        
                        BeingStrikedBy[victim]=attacker;
                        StrikesRemaining[victim]=ShadowStrikeTimes[skill_level];
                        War3_DealDamage(victim,ShadowStrikeInitialDamage,attacker,DMG_BULLET,"fangs");
                        W3FlashScreen(victim,RGBA_COLOR_RED);
                        
                        W3EmitSoundToAll(shadowstrikestr,attacker);
                        W3EmitSoundToAll(shadowstrikestr,attacker);
                        CreateTimer(1.0,ShadowStrikeLoop,GetClientUserId(victim));
                    }
                }
            }
        }
    }
}


public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_victim=War3_GetRace(victim);
            new skill_level=War3_GetSkillLevel(victim,thisRaceID,ULT_HEAL);
            if(race_victim==thisRaceID){
                if(skill_level>0 && g_bInUltimate[victim] == true)
                {
                    if(!W3HasImmunity(attacker,Immunity_Ultimates))
                    {
                        War3_DamageModPercent(0.0);
                        new healthamount = RoundToFloor(damage* VampirePercent[skill_level]);
                        War3HealToHP(victim, healthamount, bsmaximumHP);
                        
                        W3FlashScreen( victim, RGBA_COLOR_GREEN );
                        PrintHintText(attacker, "You victim is a vampire!\n He is taking blood and converting it into health.");
                        PrintHintText(victim, "Converted blood into health.");
                    }
                    else
                    {
                        PrintHintText(victim, "Arcane Powers blocked by lace.");
                    }
                    
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

public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            StrikesRemaining[i]=0;
            g_bFlying[i] = false;
            War3_SetBuff(i, bFlyMode, thisRaceID, false);
            War3_SetBuff( i, bDisarm, thisRaceID, false  );
        }
    }
}

    
public Action:ShadowStrikeLoop(Handle:timer,any:userid)
{
    new victim = GetClientOfUserId(userid);
    if(StrikesRemaining[victim]>0 && ValidPlayer(BeingStrikedBy[victim]) && ValidPlayer(victim,true))
    {
        War3_DealDamage(victim,ShadowStrikeTrailingDamage,BeingStrikedBy[victim],DMG_BULLET,"fangs");
        StrikesRemaining[victim]--;
        W3FlashScreen(victim,RGBA_COLOR_RED);
        CreateTimer(1.0,ShadowStrikeLoop,userid);
        decl Float:StartPos[3];
        GetClientAbsOrigin(victim,StartPos);
        TE_SetupDynamicLight(StartPos,255,255,100,100,100.0,0.3,2.0);
        TE_SendToAll();
    }
}


stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
    TE_Start("Dynamic Light");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("r",r);
    TE_WriteNum("g",g);
    TE_WriteNum("b",b);
    TE_WriteNum("exponent",iExponent);
    TE_WriteFloat("m_fRadius",fRadius);
    TE_WriteFloat("m_fTime",fTime);
    TE_WriteFloat("m_fDecay",fDecay);
}


public Action:HealOff(Handle:timer, any:client)
{
    if (ValidPlayer(client, true))
    {
        if (War3_GetRace(client) == thisRaceID)
        {
            g_bInUltimate[client] = false;
            PrintHintText(client, "Ultimate Deactivated");
            W3ResetPlayerColor(client,thisRaceID);
        }
    }
}