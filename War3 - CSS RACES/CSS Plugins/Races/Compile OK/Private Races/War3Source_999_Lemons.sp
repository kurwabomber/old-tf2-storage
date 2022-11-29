/**
* File: War3Source_999_Lemons.sp
* Description: Lemon's Private Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new  SKILL_SPEED, SKILL_THORNS, SKILL_DAMAGE, ULT_EXPLODE;

public Plugin:myinfo = 
{
    name = "War3Source Race - Lemons",
    author = "Remy Lebeau",
    description = "Lemon's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};

// Skill 1
new Float:g_fSpeed[] = { 1.0, 1.05, 1.1, 1.15, 1.2 };


// Skill 2
new Float:ThornsReturnDamage[5] = {0.0, 0.05, 0.1, 0.15, 0.2};

// Skill 3
new g_iDamageAmount = 5;
new Float:g_fDamageTime[] = { 0.0, 1.0, 2.0, 3.0, 4.0 };
new bool:g_bDamageToggle[MAXPLAYERS];
new BeingStrikedByLemons[MAXPLAYERS];
new Float:ShadowStrikeChanceArr[]={0.0,0.45,0.50,0.55,0.6};

// Ultimate
new Float:SuicideBomberRadius[5] = {0.0, 250.0, 290.0, 310.0, 333.0}; 
new Float:SuicideBomberDamage[5] = {0.0, 66.0, 100.0, 133.0, 166.0};
new String:explosionSound1[]="war3source/particle_suck1.wav";
new ExplosionModel;
new BeamSprite;
new HaloSprite;
new bool:g_bReviving[MAXPLAYERS];
new iMyWeaponsOffset;



public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Lemons [PRIVATE]","lemons");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Squeeze! ","As Your juices flow out, you become lighter!",false,4);
    SKILL_THORNS=War3_AddRaceSkill(thisRaceID,"Leaky Lemons!","Your juices squirts onto your enemies!",false,4);
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Lemon Tipped Bullets!","Add Lemon to your bullets!",false,4);
    ULT_EXPLODE=War3_AddRaceSkill(thisRaceID,"EXPLERRRRRRD!!!","As your body fails, your juices live on!",true,4);

    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);

}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    CreateTimer(1.0,CalcDOT,_,TIMER_REPEAT);
    iMyWeaponsOffset = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
}



public OnMapStart()
{
    if(War3_GetGame()==Game_TF)
    {
        ExplosionModel=PrecacheModel("materials/particles/explosion/explosionfiresmoke.vmt",false);
        PrecacheSound("weapons/explode1.wav",false);
    }
    else
    {
        ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
        PrecacheSound("weapons/explode5.wav",false);
    }
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    PrecacheSound(explosionSound1,false);
    
    
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
        InitPassiveSkills( client );
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
        InitPassiveSkills( client );
    }
    g_bDamageToggle[client] = false;
    BeingStrikedByLemons[client]=0;
    g_bReviving[client] = false;
}




public OnSkillLevelChanged(client,race,skill,newskilllevel )
{
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
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


public OnUltimateCommand(client, race, bool:pressed)
{
    if(pressed && War3_GetRace(client) == thisRaceID && IsPlayerAlive(client) && !Silenced(client))
    {
        new ult_level = War3_GetSkillLevel(client, race, ULT_EXPLODE);
        ult_level > 0 ? ForcePlayerSuicide(client) : W3MsgUltNotLeveled(client);
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
    if(!isWarcraft && ValidPlayer(victim) && victim != attacker && War3_GetRace(victim) == thisRaceID)
    {
        new iThornsLevel = War3_GetSkillLevel(victim, thisRaceID, SKILL_THORNS);
        if(iThornsLevel > 0 && !Hexed(victim, false))
        {
            // Don't return friendly fire damage
            if(ValidPlayer(attacker) && GetClientTeam(victim) == GetClientTeam(attacker))
            {
                return;
            }
            
            if(!W3HasImmunity(attacker, Immunity_Skills))
            {
                new iDamage = RoundToFloor(damage * ThornsReturnDamage[iThornsLevel]);
                if(iDamage > 0)
                {
                    if(iDamage > 40)
                    {
                        iDamage = 40;
                    }

                    if (GAMECSANY)
                    {
                        // Since this is delayed we don't know if the damage actually went through
                        // and just have to assume... Stupid!
                        War3_DealDamageDelayed(attacker, victim, iDamage, "thorns", 0.1, true, SKILL_THORNS);
                        War3_EffectReturnDamage(victim, attacker, iDamage, SKILL_THORNS);
                    }
                    else
                    {
                        if(War3_DealDamage(attacker, iDamage, victim, _, "thorns", _, W3DMGTYPE_PHYSICAL))
                        {
                            War3_EffectReturnDamage(victim, attacker, War3_GetWar3DamageDealt(), SKILL_THORNS);
                        }
                    }
                }
            }
        }
    }

}



public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim)&&GetClientTeam(victim)!=GetClientTeam(attacker))
        {
            //ATTACKER IS Lemons
            if(War3_GetRace(attacker)==thisRaceID)
            {
                // DOT
                new Float:chance_mod=W3ChanceModifier(attacker);
                /// CHANCE MOD BY VICTIM
                new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_DAMAGE);
                if(skill_level>0 && !Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*ShadowStrikeChanceArr[skill_level])
                {
                    if(W3HasImmunity(victim,Immunity_Skills))
                    {
                        W3MsgSkillBlocked(victim,attacker,"Lemon Tipped Bullets");
                    }
                    else
                    {
                        W3MsgAttackedBy(victim,"Lemon Tipped Bullets");
                        W3MsgActivated(attacker,"Lemon Tipped Bullets");
                        
                        BeingStrikedByLemons[victim]=attacker;
                        W3FlashScreen(victim,RGBA_COLOR_YELLOW);
                        g_bDamageToggle[victim] = true;
                        W3SetPlayerColor(victim,thisRaceID,255,255,0,_,GLOW_ULTIMATE);
                        CreateTimer(g_fDamageTime[skill_level],StopLemonsBullets,GetClientUserId(victim));
                    }
                }
            }
        }
    }
}


public OnWar3EventDeath(victim, attacker)
{
    new race = W3GetVar(DeathRace);
    new skill_level = War3_GetSkillLevel(victim, thisRaceID, ULT_EXPLODE);
    if(race == thisRaceID && skill_level > 0 && !Hexed(victim))
    {
        decl Float:client_location[3];
        GetClientAbsOrigin(victim, client_location);
        new Float:radius=SuicideBomberRadius[skill_level];
        new our_team=GetClientTeam(victim); 

        
        TE_SetupExplosion(client_location,ExplosionModel,10.0,1,0,RoundToFloor(radius),160);
        TE_SendToAll();
        
        if(War3_GetGame()==Game_TF){
            client_location[2]+=30.0;
        }
        else{
            client_location[2]-=40.0;
        }
        
        new beamcolor[]={255,255,0,255}; 
        TE_SetupBeamRingPoint(client_location, 10.0, radius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
        TE_SendToAll();
        


        TE_SetupBeamRingPoint(client_location, 20.0, radius+10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
        TE_SendToAll();

        if(War3_GetGame()==Game_TF){
            client_location[2]-=30.0;
        }
        else{
            client_location[2]+=40.0;
        }
        
        EmitSoundToAll(explosionSound1,victim);
        
        if(War3_GetGame()==Game_TF){
            EmitSoundToAll("weapons/explode1.wav",victim);
        }
        else{
            EmitSoundToAll("weapons/explode5.wav",victim);
        }
        

        new Float:location_check[3];
        for(new x=1;x<=MaxClients;x++)
        {
            if(ValidPlayer(x,true)&&victim!=x)
            {
                new team=GetClientTeam(x);
                if(team==our_team)
                    continue;
                    
                GetClientAbsOrigin(x,location_check);
                new Float:distance=GetVectorDistance(client_location,location_check);
                if(distance>radius)
                    continue;
                
                if(!W3HasImmunity(x,Immunity_Ultimates))
                {
                    new Float:factor=(radius-distance)/radius;
                    new damage;

                    damage=RoundFloat(SuicideBomberDamage[skill_level]*factor);

                    //PrintToChatAll("damage suppose to be %d/%.1f max. distance %.1f",damage,SuicideBomberDamage[skill_level],distance);
                    
                    War3_DealDamage(x,damage,victim,_,"suicidebomber",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);
                    PrintToConsole(victim,"[W3S] Suicide bomber damage: %d to %d at distance %f",War3_GetWar3DamageDealt(),x,distance);
                    PrintHintText (x, "You've been juiced!");
                    
                    War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
                    W3FlashScreen(x,RGBA_COLOR_YELLOW);
                }
                else
                {
                    PrintToConsole(victim,"[W3S] Could not damage player %d due to immunity",x);
                }
                
            }
        }

    } 
    
    race = War3_GetRace( attacker );
    skill_level = War3_GetSkillLevel(attacker, thisRaceID, ULT_EXPLODE);
    if(race == thisRaceID && skill_level > 0)
    {
        if (!IsPlayerAlive(attacker)) 
        {
            if(attacker!=victim && !g_bReviving[attacker])
            {
                g_bReviving[attacker] = true;
                W3Hint(attacker,HINT_SKILL_STATUS,5.0,"PREPARE FOR RESPAWN!");
                PrintCenterText(attacker,"PREPARE FOR RESPAWN!");
                War3_ChatMessage(attacker,"PREPARE FOR RESPAWN!");

                CreateTimer(2.0,DoRevival,GetClientUserId(attacker));
            }
        }
    }
}

public Action:DoRevival(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    
    if(ValidPlayer(client))
    {
        War3_SpawnPlayer(client);
        GivePlayerCachedDeathWPNFull(INVALID_HANDLE, client);
        g_bReviving[client] = false;
    }
}
    
    

/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}


public Action:CalcDOT(Handle:timer,any:userid)
{
    for(new i=0;i<MaxClients;i++)
    {
        if(ValidPlayer(i,true) && g_bDamageToggle[i])
        {
            W3FlashScreen(i,RGBA_COLOR_YELLOW);
            War3_DealDamage(i,g_iDamageAmount,BeingStrikedByLemons[i],_,"Lemon Tiped Bullets",_,W3DMGTYPE_MAGIC);
        }
    }
}
    
    
public Action:StopLemonsBullets(Handle:timer,any:userid)
{
    new victim = GetClientOfUserId(userid);
    if(ValidPlayer(victim))
    {
        g_bDamageToggle[victim] = false;
        W3ResetPlayerColor(victim,thisRaceID);
        BeingStrikedByLemons[victim]=0;
    }
}

public Action:GivePlayerCachedDeathWPNFull(Handle:h,any:client)
{
    if(ValidPlayer(client, true))
    {
        for(new s=0; s < 10; s++)
        {
            new ent = GetEntDataEnt2(client, iMyWeaponsOffset + (s * 4));
            if(ent > 0 && IsValidEdict(ent))
            {
                new String:ename[64];
                GetEdictClassname(ent, ename, sizeof(ename));
                if(StrEqual(ename, "weapon_c4") || StrEqual(ename, "weapon_knife"))
                {
                    continue;
                }
                W3DropWeapon(client, ent);
                UTIL_Remove(ent);
            }
        }

        // give them their weapons
        for(new s=0; s < 10; s++)
        {
            new String:sWeaponName[64];
            War3_CachedDeadWeaponName(client, s, sWeaponName, sizeof(sWeaponName));
            if(!StrEqual(sWeaponName,"") && !StrEqual(sWeaponName,"",false) && 
               !StrEqual(sWeaponName,"weapon_c4") && 
               !StrEqual(sWeaponName,"weapon_knife"))
            {
                GivePlayerItem(client, sWeaponName);
            }
        }
        
        if( GAMECSANY )
        {
            War3_RestoreCachedCSArmor(client);
        }
    }
}
